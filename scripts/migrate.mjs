import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import postgres from "postgres";

const url = process.env.DATABASE_URL;
if (!url) {
  console.error("DATABASE_URL não definida. Configure o banco antes de migrar.");
  process.exit(1);
}

const dir = join(dirname(fileURLToPath(import.meta.url)), "..", "db", "migrations");
const sql = postgres(url, { prepare: false });

try {
  const files = (await readdir(dir)).filter((f) => f.endsWith(".sql")).sort();
  for (const file of files) {
    const conteudo = await readFile(join(dir, file), "utf8");
    await sql.unsafe(conteudo);
    console.log("aplicada:", file);
  }
  console.log("migrações concluídas");
} finally {
  await sql.end();
}
