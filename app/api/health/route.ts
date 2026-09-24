import { sql } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  if (sql) {
    try {
      await sql`select 1`;
    } catch {
      return Response.json(
        { status: "degraded", database: "down" },
        { status: 503 },
      );
    }
  }

  return Response.json({
    status: "ok",
    database: sql ? "up" : "memory",
    time: new Date().toISOString(),
  });
}
