"use client";

import { Users, Sparkles } from "lucide-react";
import type { ConnectionStatus, SessionMetrics, SeatState } from "@/types/game";

interface BottomBarProps {
  connection: ConnectionStatus;
  sessionMetrics: SessionMetrics;
  seats: SeatState[];
}

export default function BottomBar({ seats }: BottomBarProps) {
  const assignedSeats = seats.filter((s) => s.assigned).length;
  const workingCount = seats.filter(
    (s) => s.assigned && (s.status === "running" || s.status === "returning"),
  ).length;

  return (
    <div className="layout-bottombar">
      <div className="hud-pill hud-pill--connection">
        <span className="pixel-dot pixel-dot--green" />
        <span>Flutter Bridge</span>
      </div>
      <div className="hud-pill hud-pill--metric">
        <Users size={10} />
        <span>
          {assignedSeats} Agent{assignedSeats !== 1 ? "s" : ""}
        </span>
      </div>
      <div className="hud-pill hud-pill--metric">
        <Sparkles size={10} />
        <span>
          {workingCount} Busy
        </span>
      </div>
    </div>
  );
}
