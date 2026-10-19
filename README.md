# Atividade Deploy & CI/CD

Este repositório é a **Agenda**, uma API HTTP de compromissos em Next.js, usada como projeto/atividade da trilha de Deploy & CI/CD da CJR. O objetivo é aprender o caminho que leva o código até a produção: testes automáticos, proteção de branch, deploy na Vercel com preview por PR, banco de dados no Supabase sem vazar segredo e um pipeline de entrega com rollback. O código da Agenda já vem pronto; ao longo das sessões você escreve os workflows e configura as plataformas em volta dele.

O conteúdo de cada sessão está no Notion: [Trilha de Deploy & CI/CD](https://app.notion.com/p/3def0d89941780539b12d8f0eef38d52)

## Pré-requisitos

- Node 20.6 ou superior e git
- Contas gratuitas no GitHub, na Vercel e no Supabase
- [GitHub CLI](https://cli.github.com) (`gh auth login`), usado desde a sessão 1
- [gitleaks](https://github.com/gitleaks/gitleaks), usado na sessão 3
- CLI da Vercel (`npm i -g vercel`), usada na sessão 4
- Um terminal com bash (no Windows, use WSL ou Git Bash)

## Como usar

Faça um fork pelo GitHub (botão Fork, no canto superior direito) e clone o SEU fork. No fork, abra a aba **Actions** e clique em *"I understand my workflows, go ahead and enable them"*, senão o CI não roda.

```bash
npm ci
npm run dev     # http://localhost:3000
npm test
```

Trabalhe sempre na raiz. A cada sessão você cria um workflow ou configura uma plataforma e valida com o `verificar.sh`. O código em `app/`, `lib/` e `db/` só muda quando a sessão pedir uma alteração pontual (um texto na tela ou um teste quebrado de propósito).

A partir da sessão 1 o `main` fica protegido: toda mudança entra por pull request. Ao abrir um PR no fork, confira se a base é o `main` do **seu** fork, e não o repositório da CJR.

## Rotas da Agenda

| Rota | O que faz |
|------|-----------|
| `GET /api/health` | Diz se a API está de pé e se o banco responde (`database`: `up`, `down` ou `memory`) |
| `GET /api/version` | Versão, commit e ambiente que estão rodando |
| `GET /api/events` | Lista os eventos |
| `POST /api/events` | Cria um evento |
| `GET /api/events/:id` | Mostra um evento |
| `PUT /api/events/:id` | Edita um evento |
| `DELETE /api/events/:id` | Apaga um evento |

Sem `DATABASE_URL`, a Agenda guarda os eventos em memória (somem a cada reinício). Com ela, usa o Postgres.

## Sessões

| Sessão | Entrega |
|--------|---------|
| 1 | `ci.yml` roda lint e testes em todo push e PR, e o `main` só aceita merge com o check `testes` verde |
| 2 (checkpoint) | Agenda no ar na Vercel: a mudança passa por um preview no PR e chega na produção pelo merge |
| 3 | Banco Postgres no Supabase: eventos persistem, a `DATABASE_URL` fica fora do git e o gitleaks não acha segredo |
| 4 (entrega) | `deploy.yml` testa, migra, builda e publica com health-gate; só ele publica produção; rollback treinado |
| 5 (opcional) | Badge de status no README, Analytics e Logs da Vercel |

As sessões 1 a 4 já cobrem o necessário para levar um projeto da CJR do commit até a produção com segurança. A sessão 5 é opcional: é para quem quer enxergar a produção e saber para onde seguir depois.

## Verificação

Rode as checagens da sessão atual:

```bash
./verificar.sh <numero-da-sessao>
```

O número vai de 1 a 5. Na primeira vez o script pergunta o seu nome (e, a partir da sessão 2, a URL de produção). Cada checagem aparece em verde quando está certa e em vermelho quando ainda falta fazer, com uma linha do que ajustar. O script sai com código 0 se tudo passou e 1 caso contrário.

Comandos extras:

- `./verificar.sh 4 --incidente`: drill de rollback da sessão 4, que mede o seu tempo de recuperação
- `./verificar.sh --reset-nome`: esquece o nome salvo
- `./verificar.sh --reset`: esquece nome, URL e incidente (use se colou a URL errada)

Scripts úteis:

- `npm run db:migrate:local`: roda a migração no banco da `DATABASE_URL` do seu `.env.local` (sessão 3)
- `npm run db:migrate`: roda a migração com a `DATABASE_URL` do ambiente, como o pipeline faz (sessão 4)

## Entrega

Com o `./verificar.sh 4` passando, abra um pull request do seu fork para este repositório (base: `main`) a partir de um branch `entrega/seu-nome`. O workflow `entrega` roda as checagens da sessão 4 no PR. Alguém do núcleo revisa e comenta. PR aprovado fecha a trilha e emite o certificado.

## Gabarito e erros comuns

A pasta `gabarito/` tem as versões de referência do `ci.yml`, do `deploy.yml` e do `vercel.json`. Consulte só depois de tentar por conta própria.

Travou? Veja o [ERROS.md](ERROS.md).
