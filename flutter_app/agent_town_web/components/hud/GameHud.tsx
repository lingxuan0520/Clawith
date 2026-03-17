"use client";

import "./hud.css";

import { useMemo } from "react";
import { useStudio } from "@/lib/store";
import TopBar from "./TopBar";
import BottomBar from "./BottomBar";

/**
 * Simplified GameHud for Flutter WebView integration.
 *
 * Removed: ConnectionPanel, ChatPanel, TaskPanel, WorkerPanel,
 * SeatManagerModal, TerminalModal, OnboardingOverlay, MusicControls.
 *
 * Chat and task management are handled by Flutter native pages.
 */
export default function GameHud() {
  const { state } = useStudio();

  // Minimal toolbar — no panels needed in WebView mode
  const toolItems = useMemo(() => [], []);

  return (
    <div className="hud-overlay">
      {/* Top area: logo + agent pills */}
      <TopBar
        seats={state.seats}
        toolItems={toolItems}
        openPanel={null}
        onToggle={() => {}}
      />

      {/* Bottom area: status indicators */}
      <div className="layout-bottom">
        <BottomBar
          connection={state.connection}
          sessionMetrics={state.sessionMetrics}
          seats={state.seats}
        />
        <div style={{ flex: "1 1 auto" }} />
      </div>
    </div>
  );
}
