import { randomUUID } from "node:crypto";
import type { AgendaEvent, EventInput } from "@/lib/events";

const events = new Map<string, AgendaEvent>();

const seed: AgendaEvent[] = [
  {
    id: "seed-standup",
    title: "Daily standup",
    start: "2026-02-02T12:00:00.000Z",
    end: "2026-02-02T12:15:00.000Z",
    location: "Meet",
    createdAt: "2026-01-01T00:00:00.000Z",
  },
  {
    id: "seed-review",
    title: "Review da trilha",
    start: "2026-02-03T18:00:00.000Z",
    end: "2026-02-03T19:00:00.000Z",
    location: "Sala 1",
    createdAt: "2026-01-01T00:00:00.000Z",
  },
];

if (events.size === 0) {
  for (const event of seed) {
    events.set(event.id, event);
  }
}

export function list(): AgendaEvent[] {
  return [...events.values()].sort((a, b) => a.start.localeCompare(b.start));
}

export function get(id: string): AgendaEvent | undefined {
  return events.get(id);
}

export function create(input: EventInput): AgendaEvent {
  const event: AgendaEvent = {
    id: randomUUID(),
    title: input.title,
    start: input.start,
    end: input.end,
    location: input.location,
    createdAt: new Date().toISOString(),
  };
  events.set(event.id, event);
  return event;
}

export function update(id: string, input: EventInput): AgendaEvent | undefined {
  const current = events.get(id);
  if (!current) return undefined;

  const updated: AgendaEvent = {
    ...current,
    title: input.title,
    start: input.start,
    end: input.end,
    location: input.location,
  };
  events.set(id, updated);
  return updated;
}

export function remove(id: string): boolean {
  return events.delete(id);
}
