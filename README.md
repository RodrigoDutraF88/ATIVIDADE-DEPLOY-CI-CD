# Agenda

Agenda de compromissos em Next.js, feita para rodar na Vercel. É o app base da trilha de Deploy & CI/CD.

## Rodar localmente

```bash
npm install
npm run dev
```

App em http://localhost:3000.

## Endpoints

| Método | Rota | Descrição |
| --- | --- | --- |
| GET | `/api/health` | Estado da aplicação |
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

## Persistência

Os eventos ficam em memória e voltam ao estado inicial quando o processo reinicia. O banco de dados entra num módulo mais à frente da trilha.
