import * as Phaser from "phaser";
import { InteractionMenu, type MenuOption } from "../entities/InteractionMenu";
import { FRAME_HEIGHT } from "../config/animations";
import { Worker } from "../entities/Worker";
import { Player } from "../entities/Player";
import { INTERACT_DISTANCE, PROMPT_Y_OFFSET } from "@/lib/constants";
import type { WorkerManager } from "./WorkerManager";
import type { CameraController } from "./CameraController";

/**
 * Notify Flutter of a user interaction via the FlutterChannel JS channel.
 */
function notifyFlutter(type: "chat" | "detail", agentId: string) {
  try {
    const msg = JSON.stringify({ type, agentId });
    console.log("[InteractionManager] notifyFlutter:", msg);
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const win = window as any;
    if (win.FlutterChannel?.postMessage) {
      win.FlutterChannel.postMessage(msg);
    } else if (win.webkit?.messageHandlers?.FlutterChannel?.postMessage) {
      // iOS WKWebView
      win.webkit.messageHandlers.FlutterChannel.postMessage(msg);
    } else {
      console.warn("[InteractionManager] No FlutterChannel available");
    }
  } catch (e) {
    console.error("[InteractionManager] notifyFlutter error:", e);
  }
}

export class InteractionManager {
  private scene: Phaser.Scene;
  private player: Player;
  private workerManager: WorkerManager;
  private cameraController: CameraController;

  interactionMenu!: InteractionMenu;
  nearestWorker: Worker | null = null;
  workerPromptSprite: Phaser.GameObjects.Sprite | null = null;
  menuOpen = false;

  constructor(
    scene: Phaser.Scene,
    player: Player,
    workerManager: WorkerManager,
    cameraController: CameraController,
  ) {
    this.scene = scene;
    this.player = player;
    this.workerManager = workerManager;
    this.cameraController = cameraController;
  }

  initInteractionUI() {
    // Animated pixel-art arrow sprite for worker proximity prompt
    if (!this.scene.anims.exists("worker-arrow-bounce")) {
      this.scene.anims.create({
        key: "worker-arrow-bounce",
        frames: this.scene.anims.generateFrameNumbers("boss-arrow", { start: 0, end: 5 }),
        frameRate: 6,
        repeat: -1,
      });
    }
    this.workerPromptSprite = this.scene.add
      .sprite(0, 0, "boss-arrow")
      .setOrigin(0.5, 1)
      .setDepth(25)
      .setScale(0.5)
      .setVisible(false);
    this.workerPromptSprite.play("worker-arrow-bounce");

    this.interactionMenu = new InteractionMenu(this.scene);
    this.interactionMenu.onClose = () => {
      this.menuOpen = false;
      this.cameraController.resumeCameraFollow();
    };
  }

  findNearestWorker(): Worker | null {
    let nearest: Worker | null = null;
    let minDist = Infinity;

    for (const worker of this.workerManager.workers) {
      if (!worker.canInteract()) continue;
      const dist = Phaser.Math.Distance.Between(
        this.player.sprite.x,
        this.player.sprite.y,
        worker.sprite.x,
        worker.sprite.y,
      );
      if (dist < INTERACT_DISTANCE && dist < minDist) {
        minDist = dist;
        nearest = worker;
      }
    }
    return nearest;
  }

  openWorkerMenu(worker: Worker) {
    this.menuOpen = true;

    // Resolve agentId from flutter-bridge
    let agentId: string | undefined;
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const bridge = (window as any).flutterBridge;
      agentId = bridge?.getAgentId?.(worker.seatId);
    } catch {
      // ignore
    }

    const options: MenuOption[] = [
      {
        label: "对话",
        enabled: !!agentId,
        action: () => {
          this.menuOpen = false;
          if (agentId) notifyFlutter("chat", agentId);
        },
      },
      {
        label: "详情",
        enabled: !!agentId,
        action: () => {
          this.menuOpen = false;
          if (agentId) notifyFlutter("detail", agentId);
        },
      },
      {
        label: "取消",
        enabled: true,
        action: () => {
          this.menuOpen = false;
        },
      },
    ];

    this.interactionMenu.show(worker.sprite.x, worker.sprite.y, options);
  }

  /** Run proximity detection and prompt display in the update loop. */
  updateProximity(eKey?: Phaser.Input.Keyboard.Key): boolean {
    const nearest = this.findNearestWorker();

    if (nearest !== this.nearestWorker) {
      if (this.nearestWorker) this.nearestWorker.resume();
      this.nearestWorker = nearest;
    }

    if (this.workerPromptSprite) {
      if (nearest) {
        nearest.pause();
        this.workerPromptSprite.setPosition(
          nearest.sprite.x,
          nearest.sprite.y - FRAME_HEIGHT * PROMPT_Y_OFFSET,
        );
        this.workerPromptSprite.setVisible(true);
      } else {
        this.workerPromptSprite.setVisible(false);
      }
    }

    // E key: worker menu takes priority (desktop keyboard)
    if (nearest && eKey && Phaser.Input.Keyboard.JustDown(eKey)) {
      this.openWorkerMenu(nearest);
      if (this.workerPromptSprite) this.workerPromptSprite.setVisible(false);
      return true;
    }

    return false;
  }

  /**
   * Find the nearest worker to a given world coordinate (used for tap detection).
   * Returns the worker if within tapRadius, null otherwise.
   */
  findWorkerAtPoint(worldX: number, worldY: number, tapRadius: number): Worker | null {
    let nearest: Worker | null = null;
    let minDist = Infinity;

    for (const worker of this.workerManager.workers) {
      if (!worker.canInteract()) continue;
      const dist = Phaser.Math.Distance.Between(worldX, worldY, worker.sprite.x, worker.sprite.y);
      if (dist < tapRadius && dist < minDist) {
        minDist = dist;
        nearest = worker;
      }
    }
    return nearest;
  }

  /** Clear nearest if it matches the given worker (used during sync cleanup). */
  clearIfNearest(worker: Worker) {
    if (this.nearestWorker === worker) this.nearestWorker = null;
  }

  destroy() {
    this.interactionMenu?.destroy();
    this.nearestWorker = null;
  }
}
