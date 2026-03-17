/**
 * Flutter Bridge — replaces GatewayClient for Flutter WebView integration.
 *
 * Exposes window.flutterBridge.initAgents() and updateAgentStatus()
 * that map Flutter agent data → seat configs and emit gameEvents
 * to drive Phaser scene updates.
 */

import { gameEvents } from "./events";
import type { SeatState, SeatFacing } from "@/types/game";
import { WORKER_SPRITES } from "@/components/game/config/animations";
import type { SeatDef } from "@/components/game/utils/MapHelpers";

// ── Types for data coming from Flutter ──

export interface FlutterAgent {
  seatId: string;
  agentId: string;
  label: string;
  status: "running" | "idle" | "error" | "stopped" | "empty";
  taskSnippet?: string | null;
}

export interface FlutterStatusUpdate {
  status: "running" | "idle" | "error" | "stopped" | "empty";
  taskSnippet?: string | null;
}

// ── Internal seat store (mirrors what StudioProvider would hold) ──

let _seats: SeatState[] = [];
let _discoveredSeatDefs: SeatDef[] = [];
let _seatsReady = false;
let _pendingAgents: FlutterAgent[] | null = null;

/**
 * Called once after Phaser has discovered seat positions from the Tiled map.
 * If initAgents() was called before seats were discovered, we process
 * the pending agents now.
 */
function listenForSeatDiscovery() {
  gameEvents.on("seats-discovered", (discovered) => {
    _discoveredSeatDefs = discovered;
    _seatsReady = true;

    // Process any agents that arrived before map was ready
    if (_pendingAgents) {
      const agents = _pendingAgents;
      _pendingAgents = null;
      _seats = buildSeats(agents);
      gameEvents.emit("seat-configs-updated", _seats);
    }
  });
}

listenForSeatDiscovery();

/**
 * Build SeatState[] from Flutter agent data + ALL discovered map positions.
 * Agents fill the first N seats; remaining seats stay empty.
 */
function buildSeats(agents: FlutterAgent[]): SeatState[] {
  return _discoveredSeatDefs.map((mapSeat, index) => {
    const agent = agents[index]; // undefined if more seats than agents
    const sprite = WORKER_SPRITES[index];

    if (!agent) {
      // Empty seat — no agent assigned
      return {
        seatId: mapSeat.seatId || `seat-${index}`,
        label: sprite?.label ?? `Seat ${index + 1}`,
        seatType: "worker" as const,
        assigned: false,
        spriteKey: sprite?.key,
        spritePath: sprite?.path,
        spawnX: mapSeat.x,
        spawnY: mapSeat.y,
        spawnFacing: (mapSeat.facing ?? "down") as SeatFacing,
        status: "empty" as const,
      };
    }

    const seatStatus =
      agent.status === "running"
        ? "running"
        : agent.status === "error"
          ? "failed"
          : "empty";

    return {
      seatId: agent.seatId || mapSeat.seatId || `seat-${index}`,
      label: agent.label || `Agent ${index + 1}`,
      seatType: "worker" as const,
      roleTitle: "Worker",
      assigned: true,
      spriteKey: sprite?.key,
      spritePath: sprite?.path,
      spawnX: mapSeat.x,
      spawnY: mapSeat.y,
      spawnFacing: (mapSeat.facing ?? "down") as SeatFacing,
      status: seatStatus,
      runId: agent.status === "running" ? agent.agentId : undefined,
      taskSnippet: agent.taskSnippet ?? undefined,
      startedAt:
        agent.status === "running" ? new Date().toISOString() : undefined,
      agentConfig: {
        agentId: agent.agentId,
      },
    };
  });
}

/**
 * Initialize all agents from Flutter.
 * If the Phaser map hasn't finished loading yet (seats not discovered),
 * we queue the agents and apply them once seats-discovered fires.
 */
function initAgents(agents: FlutterAgent[]) {
  if (!_seatsReady) {
    // Map not ready yet — queue and wait for seats-discovered
    _pendingAgents = agents;
    return;
  }
  _seats = buildSeats(agents);
  // Emit seat-configs-updated to trigger WorkerManager.syncWorkers()
  gameEvents.emit("seat-configs-updated", _seats);
}

/**
 * Update a single agent's status from Flutter.
 */
function updateAgentStatus(seatId: string, update: FlutterStatusUpdate) {
  const idx = _seats.findIndex((s) => s.seatId === seatId);
  if (idx < 0) return;

  const seat = _seats[idx];
  const seatStatus =
    update.status === "running"
      ? "running"
      : update.status === "error"
        ? "failed"
        : "empty";

  _seats[idx] = {
    ...seat,
    status: seatStatus,
    taskSnippet: update.taskSnippet ?? undefined,
    runId: update.status === "running" ? seat.agentConfig?.agentId : undefined,
    startedAt:
      update.status === "running"
        ? seat.startedAt ?? new Date().toISOString()
        : undefined,
  };

  // Re-emit full seat list to trigger Phaser sync
  gameEvents.emit("seat-configs-updated", _seats);
}

/**
 * Get the agentId associated with a seatId (for interaction menu → Flutter navigation).
 */
function getAgentId(seatId: string): string | undefined {
  const seat = _seats.find((s) => s.seatId === seatId);
  return seat?.agentConfig?.agentId;
}

// ── Expose on window for Flutter JS injection ──

export interface FlutterBridge {
  initAgents: (agents: FlutterAgent[]) => void;
  updateAgentStatus: (seatId: string, update: FlutterStatusUpdate) => void;
  getAgentId: (seatId: string) => string | undefined;
}

if (typeof window !== "undefined") {
  (window as unknown as { flutterBridge: FlutterBridge }).flutterBridge = {
    initAgents,
    updateAgentStatus,
    getAgentId,
  };
}

export { initAgents, updateAgentStatus, getAgentId };
