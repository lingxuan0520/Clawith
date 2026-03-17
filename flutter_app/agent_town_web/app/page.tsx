"use client";

import dynamic from "next/dynamic";
import { StudioProvider } from "@/lib/store";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import { GameErrorBoundary } from "@/components/game/GameErrorBoundary";
import GameHud from "@/components/hud/GameHud";

const PhaserGame = dynamic(() => import("@/components/game/PhaserGame"), {
  ssr: false,
});

export default function Page() {
  return (
    <ErrorBoundary>
      <StudioProvider>
        <main
          className="relative w-screen h-screen overflow-hidden"
          style={{ background: "var(--pixel-bg)" }}
        >
          {/* Game canvas — full screen background */}
          <div className="absolute inset-0">
            <GameErrorBoundary>
              <PhaserGame />
            </GameErrorBoundary>
          </div>
          {/* HUD overlay — floating UI on top */}
          <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 20 }}>
            <GameHud />
          </div>
        </main>
      </StudioProvider>
    </ErrorBoundary>
  );
}
