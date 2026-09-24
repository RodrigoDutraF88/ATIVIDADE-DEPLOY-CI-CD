import { deleteEvent, getEvent, updateEvent } from "@/lib/store";
import { parseEventInput } from "@/lib/events";

export const dynamic = "force-dynamic";

type Context = { params: Promise<{ id: string }> };

export async function GET(_request: Request, { params }: Context) {
  const { id } = await params;
  const event = await getEvent(id);
  if (!event) {
    return Response.json({ error: "not found" }, { status: 404 });
  }
  return Response.json(event);
}

export async function PUT(request: Request, { params }: Context) {
  const { id } = await params;

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return Response.json({ error: "invalid json" }, { status: 400 });
  }

  const parsed = parseEventInput(body);
  if (!parsed.ok) {
    return Response.json({ error: parsed.error }, { status: 400 });
  }

  const event = await updateEvent(id, parsed.value);
  if (!event) {
    return Response.json({ error: "not found" }, { status: 404 });
  }
  return Response.json(event);
}

export async function DELETE(_request: Request, { params }: Context) {
  const { id } = await params;
  if (!(await deleteEvent(id))) {
    return Response.json({ error: "not found" }, { status: 404 });
  }
  return new Response(null, { status: 204 });
}
