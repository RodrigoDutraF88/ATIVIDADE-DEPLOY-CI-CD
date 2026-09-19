export type AgendaEvent = {
  id: string;
  title: string;
  start: string;
  end: string | null;
  location: string | null;
  createdAt: string;
};

export type EventInput = {
  title: string;
  start: string;
  end: string | null;
  location: string | null;
};

export type ParseResult =
  | { ok: true; value: EventInput }
  | { ok: false; error: string };

export function parseEventInput(body: unknown): ParseResult {
  if (typeof body !== "object" || body === null) {
    return { ok: false, error: "body must be an object" };
  }

  const data = body as Record<string, unknown>;

  if (typeof data.title !== "string" || data.title.trim() === "") {
    return { ok: false, error: "title is required" };
  }

  if (typeof data.start !== "string" || Number.isNaN(Date.parse(data.start))) {
    return { ok: false, error: "start must be a valid date" };
  }

  let end: string | null = null;
  if (data.end !== undefined && data.end !== null) {
    if (typeof data.end !== "string" || Number.isNaN(Date.parse(data.end))) {
      return { ok: false, error: "end must be a valid date" };
    }
    if (Date.parse(data.end) < Date.parse(data.start)) {
      return { ok: false, error: "end must not be before start" };
    }
    end = data.end;
  }

  let location: string | null = null;
  if (data.location !== undefined && data.location !== null) {
    if (typeof data.location !== "string") {
      return { ok: false, error: "location must be a string" };
    }
    location = data.location.trim() || null;
  }

  return {
    ok: true,
    value: { title: data.title.trim(), start: data.start, end, location },
  };
}
