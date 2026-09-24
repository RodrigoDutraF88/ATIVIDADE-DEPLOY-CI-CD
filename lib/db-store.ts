import { sql } from "@/lib/db";
import type { AgendaEvent, EventInput } from "@/lib/events";

type Row = {
  id: string;
  title: string;
  starts_at: string | Date;
  ends_at: string | Date | null;
  location: string | null;
  created_at: string | Date;
};

function client() {
  if (!sql) throw new Error("DATABASE_URL não configurada");
  return sql;
}

function toEvent(row: Row): AgendaEvent {
  return {
    id: row.id,
    title: row.title,
    start: new Date(row.starts_at).toISOString(),
    end: row.ends_at ? new Date(row.ends_at).toISOString() : null,
    location: row.location,
    createdAt: new Date(row.created_at).toISOString(),
  };
}

export async function list(): Promise<AgendaEvent[]> {
  const db = client();
  const rows = await db<Row[]>`select * from events order by starts_at`;
  return rows.map(toEvent);
}

export async function get(id: string): Promise<AgendaEvent | undefined> {
  const db = client();
  const [row] = await db<Row[]>`select * from events where id = ${id}`;
  return row ? toEvent(row) : undefined;
}

export async function create(input: EventInput): Promise<AgendaEvent> {
  const db = client();
  const [row] = await db<Row[]>`
    insert into events (title, starts_at, ends_at, location)
    values (${input.title}, ${input.start}, ${input.end}, ${input.location})
    returning *`;
  return toEvent(row);
}

export async function update(
  id: string,
  input: EventInput,
): Promise<AgendaEvent | undefined> {
  const db = client();
  const [row] = await db<Row[]>`
    update events
    set title = ${input.title},
        starts_at = ${input.start},
        ends_at = ${input.end},
        location = ${input.location}
    where id = ${id}
    returning *`;
  return row ? toEvent(row) : undefined;
}

export async function remove(id: string): Promise<boolean> {
  const db = client();
  const rows = await db<{ id: string }[]>`delete from events where id = ${id} returning id`;
  return rows.length > 0;
}
