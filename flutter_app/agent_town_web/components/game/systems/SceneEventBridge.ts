import { gameEvents } from "@/lib/events";
import type { WorkerManager } from "./WorkerManager";
import type { InteractionManager } from "./InteractionManager";

/**
 * Simplified SceneEventBridge for Flutter WebView integration.
 *
 * Only bridges seat-configs-updated (from flutter-bridge) into Phaser scene.
 * Task routing, bubbles, and gateway events are not needed — all handled by Flutter native.
 */
export function initSceneEventBridge(
  workerManager: WorkerManager,
  interactionManager: InteractionManager,
  _sessionBindings: Map<string, string>,
  _setTerminalOpen: (open: boolean) => void,
): () => void {
  const unsubs: Array<() => void> = [];

  // Sync worker sprites when seat configs change (driven by flutter-bridge)
  unsubs.push(
    gameEvents.on("seat-configs-updated", (seats) => {
      workerManager.syncWorkers(seats, (w) => interactionManager.clearIfNearest(w));
    }),
  );

  return () => {
    for (const unsub of unsubs) unsub();
  };
}
