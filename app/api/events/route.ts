import { createEvent, listEvents } from "@/lib/store";
import { parseEventInput } from "@/lib/events";

export const dynamic = "force-dynamic";

export async function GET() {
  return Response.json(listEvents());
}

export async function POST(request: Request) {
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

  return Response.json(createEvent(parsed.value), { status: 201 });
}
