import { randomUUID } from "node:crypto";
import type { AgendaEvent, EventInput } from "@/lib/events";

const store = new Map<string, AgendaEvent>();

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

if (store.size === 0) {
  for (const event of seed) {
    store.set(event.id, event);
  }
}

export function listEvents(): AgendaEvent[] {
  return [...store.values()].sort((a, b) => a.start.localeCompare(b.start));
}

export function getEvent(id: string): AgendaEvent | undefined {
  return store.get(id);
}

export function createEvent(input: EventInput): AgendaEvent {
  const event: AgendaEvent = {
    id: randomUUID(),
    title: input.title,
    start: input.start,
    end: input.end,
    location: input.location,
    createdAt: new Date().toISOString(),
  };
  store.set(event.id, event);
  return event;
}

export function updateEvent(id: string, input: EventInput): AgendaEvent | undefined {
  const current = store.get(id);
  if (!current) return undefined;

  const updated: AgendaEvent = {
    ...current,
    title: input.title,
    start: input.start,
    end: input.end,
    location: input.location,
  };
  store.set(id, updated);
  return updated;
}

export function deleteEvent(id: string): boolean {
  return store.delete(id);
}
