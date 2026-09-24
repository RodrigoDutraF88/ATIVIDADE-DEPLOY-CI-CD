# Agenda

Agenda de compromissos em Next.js, feita para rodar na Vercel. É o app base da trilha de Deploy & CI/CD da CJR.

## Rodar localmente

```bash
npm install
npm run dev
```

App em http://localhost:3000.

## Endpoints

| Método | Rota | Descrição |
| --- | --- | --- |
| GET | `/api/health` | Estado da aplicação e do banco |
| GET | `/api/version` | Versão, commit e ambiente do deploy |
| GET | `/api/events` | Lista os eventos |
| POST | `/api/events` | Cria um evento |
| GET | `/api/events/:id` | Busca um evento |
| PUT | `/api/events/:id` | Atualiza um evento |
| DELETE | `/api/events/:id` | Remove um evento |

Um evento tem `title` e `start` (data ISO) obrigatórios, e `end` e `location` opcionais.

```bash
curl -X POST http://localhost:3000/api/events \
  -H "Content-Type: application/json" \
  -d '{"title":"Mentoria","start":"2026-02-10T14:00:00.000Z"}'
```

## Banco de dados

Sem a variável `DATABASE_URL`, a Agenda guarda os eventos **em memória** (voltam ao estado inicial quando o processo reinicia). Com um Postgres configurado, ela persiste de verdade.

```bash
cp .env.example .env.local   # cole a sua DATABASE_URL (Supabase) no .env.local
npm run db:migrate           # cria a tabela events
npm run dev
```

O Módulo 4 da trilha cobre isso passo a passo.

## A trilha

Cada sessão tem uma atividade prática validada por `./verificar.sh <n>` (de 1 a 7). Comece pela Sessão 1 no Notion.
