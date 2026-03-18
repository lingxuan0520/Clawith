"use client";

/**
 * Simplified StudioProvider for Flutter WebView integration.
 *
 * No gateway connection, no session management, no task routing.
 * State is driven entirely by flutter-bridge.ts injecting agent data.
 */

import {
  createContext,
  useContext,
  useReducer,
  useEffect,
  type Dispatch,
  type ReactNode,
} from "react";
import React from "react";
import type { SeatState } from "@/types/game";
import type { StudioSnapshot } from "@/types/game";
import { gameEvents } from "./events";
import { WORKER_SPRITES } from "@/components/game/config/animations";

// Import flutter-bridge to register window.flutterBridge
import "./flutter-bridge";

// ── Minimal reducer ──

type Action =
  | { type: "SYNC_SEATS"; seats: SeatState[] }
  | { type: "SET_SEAT_STATUS"; runId: string; status: SeatState["status"] }
  | {
      type: "PATCH_SEAT_RUNTIME";
      seatId: string;
      patch: Partial<Pick<SeatState, "status" | "taskSnippet" | "runId" | "startedAt">>;
    };

const initialState: StudioSnapshot = {
  connection: "connected", // Always "connected" in WebView mode
  seats: [],
  tasks: [],
  chatMessages: [],
  activeSessionKey: undefined,
  sessionMetrics: { fresh: false },
  sessions: [],
};

function reducer(state: StudioSnapshot, action: Action): StudioSnapshot {
  switch (action.type) {
    case "SYNC_SEATS":
      return { ...state, seats: action.seats };

    case "SET_SEAT_STATUS": {
      const seats: SeatState[] = state.seats.map((seat) => {
        if (seat.runId !== action.runId) return seat;
        if (action.status === "empty") {
          return {
            ...seat,
            status: "empty",
            runId: undefined,
            taskSnippet: undefined,
            startedAt: undefined,
          };
        }
        return { ...seat, status: action.status };
      });
      return { ...state, seats };
    }

    case "PATCH_SEAT_RUNTIME":
      return {
        ...state,
        seats: state.seats.map((seat) =>
          seat.seatId === action.seatId ? { ...seat, ...action.patch } : seat,
        ),
      };

    default:
      return state;
  }
}

// ── Context ──

interface StudioContextValue {
  state: StudioSnapshot;
}

const StudioContext = createContext<StudioContextValue | null>(null);

export function useStudio(): StudioContextValue {
  const ctx = useContext(StudioContext);
  if (!ctx) throw new Error("useStudio must be used within StudioProvider");
  return ctx;
}

// ── Provider ──

export function StudioProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, initialState);

  // Listen for seat-configs-updated from flutter-bridge
  useEffect(() => {
    const unsub = gameEvents.on("seat-configs-updated", (seats) => {
      dispatch({ type: "SYNC_SEATS", seats });
    });
    return unsub;
  }, []);

  return React.createElement(
    StudioContext.Provider,
    { value: { state } },
    children,
  );
}
