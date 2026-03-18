import * as Phaser from "phaser";
import { Player } from "../entities/Player";
import { resetWanderClock } from "../entities/Worker";
import { SPRITE_KEY, SPRITE_PATH, WORKER_SPRITES, MOVE_SPEED } from "../config/animations";
import { EMOTE_SHEET_KEY, EMOTE_SHEET_PATH, EMOTE_FRAME_SIZE } from "../config/emotes";
import { Pathfinder } from "../utils/Pathfinder";
import {
  buildSpriteFrames,
  parseSpawns,
  parsePOIs,
  buildCollisionRects,
  renderTileObjectLayer,
  type AnimatedProp,
} from "../utils/MapHelpers";
import { gameEvents } from "@/lib/events";
import { createLogger } from "@/lib/logger";
import {
  BOSS_INTERACT_DISTANCE,
  PF_PADDING,
  BOSS_PROMPT_OFFSET_X,
  BOSS_PROMPT_OFFSET_Y,
} from "@/lib/constants";

import { CameraController } from "../systems/CameraController";
import { WorkerManager } from "../systems/WorkerManager";
import { InteractionManager } from "../systems/InteractionManager";
import { DoorManager } from "../systems/DoorManager";
import { initSceneEventBridge } from "../systems/SceneEventBridge";

const log = createLogger("OfficeScene");

function isInputFocused(): boolean {
  const el = document.activeElement;
  if (!el) return false;
  const tag = el.tagName;
  return tag === "INPUT" || tag === "TEXTAREA" || (el as HTMLElement).isContentEditable;
}

export class OfficeScene extends Phaser.Scene {
  private player!: Player;
  private terminalZone: { x: number; y: number } | null = null;
  private promptSprite: Phaser.GameObjects.Sprite | null = null;
  private eKey: Phaser.Input.Keyboard.Key | null = null;
  private terminalOpen = false;

  /** sessionKey -> seatId: when a character executes a task, that session binds to the character */
  private sessionBindings = new Map<string, string>();

  private cameraController!: CameraController;
  private workerManager!: WorkerManager;
  private interactionManager!: InteractionManager;
  private doorManager!: DoorManager;
  private cleanupEventBridge: (() => void) | null = null;

  // Touch input state
  private _touchStart: { x: number; y: number; time: number } | null = null;
  private _isDragging = false;
  private _menuHandledThisTouch = false; // prevents double-fire after menu click
  private static readonly TOUCH_DEADZONE = 12;
  private static readonly TAP_MAX_MS = 300;
  private static readonly TAP_RADIUS = 60; // world-pixels for tap detection

  constructor() {
    super({ key: "OfficeScene" });
  }

  preload() {
    this.load.tilemapTiledJSON("office", "/maps/office2.json");

    this.load.once("filecomplete-tilemapJSON-office", () => {
      const cached = this.cache.tilemap.get("office");
      if (!cached?.data?.tilesets) return;
      for (const ts of cached.data.tilesets) {
        const basename = (ts.image as string).split("/").pop()!;
        this.load.image(ts.name, `/tilesets/${basename}`);
      }
    });

    this.load.image(SPRITE_KEY, SPRITE_PATH);

    for (const ws of WORKER_SPRITES) {
      this.load.image(ws.key, ws.path);
    }

    this.load.spritesheet(EMOTE_SHEET_KEY, EMOTE_SHEET_PATH, {
      frameWidth: EMOTE_FRAME_SIZE,
      frameHeight: EMOTE_FRAME_SIZE,
    });

    this.load.spritesheet("boss-arrow", "/sprites/arrow_down_48x48.png", {
      frameWidth: 48,
      frameHeight: 48,
    });

    this.load.spritesheet("anim-cauldron", "/sprites/animated_witch_cauldron_48x48.png", {
      frameWidth: 96,
      frameHeight: 96,
    });

    this.load.spritesheet("anim-door", "/sprites/animated_door_big_4_48x48.png", {
      frameWidth: 48,
      frameHeight: 144,
    });
  }

  create() {
    buildSpriteFrames(this, SPRITE_KEY);
    for (const ws of WORKER_SPRITES) {
      buildSpriteFrames(this, ws.key);
    }

    const map = this.make.tilemap({ key: "office" });

    const allTilesets: Phaser.Tilemaps.Tileset[] = [];
    for (const ts of map.tilesets) {
      const added = map.addTilesetImage(ts.name, ts.name);
      if (added) allTilesets.push(added);
    }
    if (allTilesets.length === 0) {
      log.error("No tilesets loaded");
      return;
    }

    map.createLayer("floor", allTilesets);
    map.createLayer("walls", allTilesets);
    map.createLayer("ground", allTilesets);
    map.createLayer("furniture", allTilesets);
    map.createLayer("objects", allTilesets);

    const animatedProps: AnimatedProp[] = [
      {
        tilesetName: "11_Halloween_48x48",
        anchorLocalId: 130,
        skipLocalIds: new Set([130, 131, 146, 147]),
        spriteKey: "anim-cauldron",
        frameWidth: 96,
        frameHeight: 96,
        endFrame: 11,
        frameRate: 8,
      },
    ];
    renderTileObjectLayer(this, map, "props", allTilesets, 5, animatedProps);
    renderTileObjectLayer(this, map, "props-over", allTilesets, 11);

    const overheadLayer = map.createLayer("overhead", allTilesets);
    if (overheadLayer) overheadLayer.setDepth(10);

    const collisionGroup = this.physics.add.staticGroup();
    const collisionRects = buildCollisionRects(map, collisionGroup);

    const pathfinder = new Pathfinder(
      map.widthInPixels,
      map.heightInPixels,
      collisionRects,
      PF_PADDING,
    );

    const { bossSpawn, workerSpawns } = parseSpawns(map);
    const pois = parsePOIs(map);

    this.player = new Player(this, bossSpawn.x, bossSpawn.y, bossSpawn.facing);
    this.physics.add.collider(this.player.sprite, collisionGroup);

    this.physics.world.setBounds(0, 0, map.widthInPixels, map.heightInPixels);
    this.player.sprite.setCollideWorldBounds(true);

    this.input.keyboard?.disableGlobalCapture();

    // ── Systems ───────────────────────────────────────────
    this.cameraController = new CameraController(
      this,
      this.player.sprite,
      map.widthInPixels,
      map.heightInPixels,
    );
    this.cameraController.init();

    this.workerManager = new WorkerManager(this, workerSpawns, pois, pathfinder);

    this.interactionManager = new InteractionManager(
      this,
      this.player,
      this.workerManager,
      this.cameraController,
    );
    this.interactionManager.initInteractionUI();

    this.doorManager = new DoorManager(this, this.player, () => this.workerManager.workers);
    this.doorManager.initDoors();

    resetWanderClock();
    this.initBossSeat(bossSpawn);

    this.cleanupEventBridge = initSceneEventBridge(
      this.workerManager,
      this.interactionManager,
      this.sessionBindings,
      (open) => {
        this.terminalOpen = open;
      },
    );

    gameEvents.emit("seats-discovered", workerSpawns);

    // ── Touch input for mobile (virtual joystick + tap to interact) ──
    this.initTouchInput();

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.cleanup());
    this.events.once(Phaser.Scenes.Events.DESTROY, () => this.cleanup());
  }

  // ── Touch input ─────────────────────────────────────────

  private initTouchInput() {
    // ── Universal menu click handler (works for both mouse and touch) ──
    // Must be registered FIRST so it runs before camera drag or joystick handlers.
    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      if (this.interactionManager.interactionMenu.visible) {
        this._menuHandledThisTouch = true;
        this.interactionManager.interactionMenu.handlePointerAt(pointer.x, pointer.y);
      }
    });

    // ── Touch-specific: virtual joystick ──
    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      if (!pointer.wasTouch) return;
      if (this._menuHandledThisTouch) return; // menu already consumed this tap
      if (this.interactionManager.interactionMenu.visible) return;
      this._touchStart = { x: pointer.x, y: pointer.y, time: Date.now() };
      this._isDragging = false;
    });

    this.input.on("pointermove", (pointer: Phaser.Input.Pointer) => {
      if (!pointer.wasTouch || !pointer.isDown || !this._touchStart) return;
      if (this.interactionManager.interactionMenu.visible) return;

      const dx = pointer.x - this._touchStart.x;
      const dy = pointer.y - this._touchStart.y;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist > OfficeScene.TOUCH_DEADZONE) {
        this._isDragging = true;
        const nx = dx / dist;
        const ny = dy / dist;
        // Scale speed based on drag distance (capped at 1x MOVE_SPEED)
        const factor = Math.min(dist / 60, 1);
        this.player.setTouchVelocity(nx * MOVE_SPEED * factor, ny * MOVE_SPEED * factor);
      } else {
        this.player.setTouchVelocity(0, 0);
      }
    });

    this.input.on("pointerup", (pointer: Phaser.Input.Pointer) => {
      if (!pointer.wasTouch) return;
      this.player.setTouchVelocity(0, 0);

      // If this touch was consumed by menu handler, skip tap detection
      if (this._menuHandledThisTouch) {
        this._menuHandledThisTouch = false;
        this._touchStart = null;
        this._isDragging = false;
        return;
      }

      // Detect tap (short touch with little movement)
      if (!this._isDragging && this._touchStart) {
        const elapsed = Date.now() - this._touchStart.time;
        if (elapsed < OfficeScene.TAP_MAX_MS) {
          this.handleTap(pointer);
        }
      }

      this._touchStart = null;
      this._isDragging = false;
    });
  }

  private handleTap(pointer: Phaser.Input.Pointer) {
    if (this.interactionManager.menuOpen) return;

    // Convert screen coordinates to world coordinates
    const cam = this.cameras.main;
    const worldPoint = cam.getWorldPoint(pointer.x, pointer.y);

    // Check if tap hit a worker
    const worker = this.interactionManager.findWorkerAtPoint(
      worldPoint.x,
      worldPoint.y,
      OfficeScene.TAP_RADIUS,
    );
    if (worker) {
      this.interactionManager.openWorkerMenu(worker);
      return;
    }

    // Check boss terminal
    if (this.terminalZone) {
      const dist = Phaser.Math.Distance.Between(
        worldPoint.x,
        worldPoint.y,
        this.terminalZone.x,
        this.terminalZone.y,
      );
      if (dist < OfficeScene.TAP_RADIUS) {
        this.terminalOpen = true;
        if (this.promptSprite) this.promptSprite.setVisible(false);
        gameEvents.emit("open-terminal");
      }
    }
  }

  // ── Boss seat ──────────────────────────────────────────

  private initBossSeat(bossSpawn: { x: number; y: number }) {
    this.terminalZone = { x: bossSpawn.x, y: bossSpawn.y };

    // Animated pixel-art arrow sprite instead of emoji
    if (!this.anims.exists("boss-arrow-bounce")) {
      this.anims.create({
        key: "boss-arrow-bounce",
        frames: this.anims.generateFrameNumbers("boss-arrow", { start: 0, end: 5 }),
        frameRate: 6,
        repeat: -1,
      });
    }
    this.promptSprite = this.add
      .sprite(
        bossSpawn.x + BOSS_PROMPT_OFFSET_X,
        bossSpawn.y - BOSS_PROMPT_OFFSET_Y,
        "boss-arrow",
      )
      .setOrigin(0, 0)
      .setDepth(20)
      .setScale(0.5)
      .setVisible(false);
    this.promptSprite.play("boss-arrow-bounce");

    const kb = this.input.keyboard;
    if (!kb) return;
    this.eKey = kb.addKey(Phaser.Input.Keyboard.KeyCodes.E, false);
  }

  // ── Cleanup ────────────────────────────────────────────

  private cleanup() {
    this.cleanupEventBridge?.();
    this.cleanupEventBridge = null;

    this.workerManager?.destroyAll();
    this.interactionManager?.destroy();
  }

  // ── Update ─────────────────────────────────────────────

  update() {
    if (this.interactionManager.interactionMenu.visible) {
      this.interactionManager.interactionMenu.update();
      this.workerManager.updateAll();
      return;
    }

    if (this.terminalOpen || isInputFocused()) {
      this.workerManager.updateAll();
      this.doorManager.updateDoors();
      return;
    }

    this.player.update();
    if (!this.cameraController.cameraFollowing && this.player.isMoving()) {
      this.cameraController.resumeCameraFollow();
    }
    this.workerManager.updateAll();
    this.doorManager.updateDoors();

    // Worker proximity + E-key interaction (keyboard, desktop)
    if (this.interactionManager.updateProximity(this.eKey ?? undefined)) {
      return;
    }

    // Boss terminal interaction (only when no worker is nearby)
    if (!this.interactionManager.nearestWorker && this.terminalZone && this.promptSprite) {
      const dist = Phaser.Math.Distance.Between(
        this.player.sprite.x,
        this.player.sprite.y,
        this.terminalZone.x,
        this.terminalZone.y,
      );
      const near = dist < BOSS_INTERACT_DISTANCE;
      this.promptSprite.setVisible(near);

      if (near && this.eKey && Phaser.Input.Keyboard.JustDown(this.eKey)) {
        this.terminalOpen = true;
        this.promptSprite.setVisible(false);
        gameEvents.emit("open-terminal");
      }
    } else if (this.promptSprite) {
      this.promptSprite.setVisible(false);
    }
  }
}
