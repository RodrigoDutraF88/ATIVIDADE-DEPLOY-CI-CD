# Atividade Deploy & CI/CD

Este repositório é a **Agenda**, uma API HTTP de compromissos em Next.js, usada como projeto/atividade da trilha de Deploy & CI/CD da CJR. O objetivo é aprender o caminho que leva o código até a produção: testes automáticos, proteção de branch, deploy na Vercel, banco de dados no Supabase, preview por PR e um pipeline de entrega. O código da Agenda já vem pronto; ao longo das sessões você escreve os workflows e configura as plataformas em volta dele.

O conteúdo de cada sessão está no Notion: [Trilha de Deploy & CI/CD](https://app.notion.com/p/Deploy-CI-CD-3f8f6c86fd08800e9435d6c9be971a36?source=copy_link)

## Pré-requisitos

- Node 20 ou superior e git
- Contas gratuitas no GitHub, na Vercel e no Supabase
- [GitHub CLI](https://cli.github.com) (`gh auth login`), usado na sessão 2
- [gitleaks](https://github.com/gitleaks/gitleaks), usado na sessão 5
- CLI da Vercel (`npm i -g vercel`), usada na sessão 6
- Um terminal com bash (no Windows, use WSL ou Git Bash)

## Como usar

Faça um fork pelo GitHub (botão Fork, no canto superior direito) e clone o SEU fork. No fork, abra a aba **Actions** e clique em *"I understand my workflows, go ahead and enable them"*, senão o CI não roda.

Trabalhe sempre na raiz. A cada sessão você cria um workflow ou configura uma plataforma e valida com o `verificar.sh`. O código em `app/`, `lib/` e `db/` só muda quando a sessão pedir uma alteração pontual (um texto na tela ou um teste quebrado de propósito).

Para rodar a Agenda na sua máquina:

```bash
npm install
npm run dev     # http://localhost:3000
npm test
```

## Sessões

| Sessão | Entrega |
|--------|---------|
| 1 | Workflow `ci.yml` rodando os testes a cada push e pull request |
| 2 | `main` protegido: merge só com o check `testes` verde, com lint no CI |
| 3 (checkpoint) | Agenda no ar na Vercel, com `/api/version` mostrando o commit do `main` |
| 4 | Banco Postgres no Supabase: eventos persistem e a `DATABASE_URL` fica fora do git |
| 5 | Cada pull request gera uma URL de preview e nenhum segredo é versionado |
| 6 (entrega) | `deploy.yml` testa, migra, builda e publica com health-gate; rollback treinado |
| 7 (opcional) | Badge de status no README, Analytics e Logs da Vercel |

As sessões 1 a 6 já cobrem o necessário para levar um projeto da CJR do commit até a produção com segurança. A sessão 7 é opcional: é para quem quer enxergar a produção e saber para onde seguir depois.

## Verificação

Rode as checagens da sessão atual:

```bash
./verificar.sh <numero-da-sessao>
```

O número vai de 1 a 7. Na primeira vez o script pergunta o seu nome. Cada checagem aparece em verde quando está certa e em vermelho quando ainda falta fazer, com uma linha do que ajustar. O script sai com código 0 se tudo passou e 1 caso contrário.

Comandos extras:

- `./verificar.sh 6 --incidente`: drill de rollback da sessão 6, que mede o seu tempo de recuperação
- `./verificar.sh --reset-nome`: esquece o nome salvo

## Entrega

Com o `./verificar.sh 6` passando, abra um pull request do seu fork para este repositório (base: `main`) a partir de um branch `entrega/seu-nome`. Alguém do núcleo revisa e comenta. PR aprovado fecha a trilha e emite o certificado.

## Gabarito

A pasta `gabarito/` tem versões de referência do `ci.yml` e do `deploy.yml`. Consulte só depois de tentar por conta própria.
