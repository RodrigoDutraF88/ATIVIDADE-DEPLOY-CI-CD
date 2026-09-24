import { sql } from "@/lib/db";
import * as db from "@/lib/db-store";
import * as memory from "@/lib/memory-store";
import type { AgendaEvent, EventInput } from "@/lib/events";

export function listEvents(): Promise<AgendaEvent[]> {
  return sql ? db.list() : Promise.resolve(memory.list());
}

export function getEvent(id: string): Promise<AgendaEvent | undefined> {
  return sql ? db.get(id) : Promise.resolve(memory.get(id));
}

export function createEvent(input: EventInput): Promise<AgendaEvent> {
  return sql ? db.create(input) : Promise.resolve(memory.create(input));
}

export function updateEvent(
  id: string,
  input: EventInput,
): Promise<AgendaEvent | undefined> {
  return sql ? db.update(id, input) : Promise.resolve(memory.update(id, input));
}

export function deleteEvent(id: string): Promise<boolean> {
  return sql ? db.remove(id) : Promise.resolve(memory.remove(id));
}
