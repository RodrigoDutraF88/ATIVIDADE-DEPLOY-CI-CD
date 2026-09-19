import pkg from "@/package.json";

export const dynamic = "force-dynamic";

export async function GET() {
  return Response.json({
    version: pkg.version,
    commit: process.env.VERCEL_GIT_COMMIT_SHA ?? process.env.GITHUB_SHA ?? "local",
    environment: process.env.VERCEL_ENV ?? "development",
  });
}
