# Erros comuns

Problemas que já apareceram ao fazer a trilha, com a causa e o que fazer.

## Sessão 1

**O CI não roda no fork**
Os workflows de um fork vêm desligados. Abra a aba **Actions** e clique em *"I understand my workflows, go ahead and enable them"*.

**O check `testes` não aparece na lista da proteção do branch**
Ele só surge depois que o CI rodou pelo menos uma vez no fork. Dê um push qualquer, espere o workflow terminar na aba Actions e recarregue a página.

**`o main não exige o check testes para mergear`**
Marcar *Require status checks to pass* não basta: o check `testes` precisa estar selecionado na lista. Nos Rulesets, confira também se o alvo é o branch `main` e se o ruleset está *Active*.

**`não achei o job testes no ci.yml`**
O nome do job vira o nome do check. Se o job se chamar `build` ou `test`, o portão procura um check que não existe. Use `testes:` embaixo de `jobs:`.

**`o gh não está logado` / `gh (GitHub CLI) não encontrado`**
O `verificar.sh` lê a proteção do `main` pelo GitHub CLI. Instale o `gh` e rode `gh auth login`.

**O PR com o teste quebrado abriu no repositório da CJR**
Num fork, o GitHub sugere o repositório original como base do PR. Feche esse PR e abra de novo trocando o *base repository* para o seu fork. Pelo terminal, rode `gh repo set-default` e escolha o seu fork antes do `gh pr create`.

**O CI falha no `npm ci`**
O `package-lock.json` ficou desatualizado (instalou algo com `npm install` e não commitou o lock). Rode `npm install`, commite o `package-lock.json` e dê push.

## Sessão 2

**O push direto no `main` foi recusado (`GH006` ou `GH013`)**
O `main` está protegido desde a Sessão 1, então a mudança tem que entrar por PR. Crie um branch, dê push nele e abra o PR. Se o push direto passou com um aviso de *bypass*, foi porque você é admin do fork e a proteção clássica deixa admin passar; mesmo assim, faça pelo PR.

**A Vercel não comentou o link de Preview no PR**
Confira se o PR é para o `main` do seu fork (e não para o repositório da CJR) e se o projeto da Vercel importou o seu fork. O link também aparece na aba **Deployments** da Vercel, marcado como *Preview*.

**A URL de Preview pede login**
É o esperado: a Vercel protege previews por padrão (*Deployment Protection*). Entre com a mesma conta que criou o projeto.

**`/api/health respondeu 401 (URL protegida)`**
Você colou a URL de um deploy específico (a que tem um código no meio), que também fica atrás do login. Use o domínio de produção, que aparece em *Settings → Domains* do projeto. Rode `./verificar.sh --reset` e cole de novo.

**`o commit em produção não bate com o seu HEAD`**
O merge aconteceu no GitHub, mas a sua cópia local ainda está no branch da mudança ou num `main` antigo. Rode `git checkout main && git pull` e espere o deploy terminar na aba Deployments.

**`nenhum pull request mergeado no seu fork`**
A mudança do subtítulo precisa entrar pelo PR, não por push direto. Faça num branch, abra o PR para o `main` do seu fork, confira o Preview e mergeie.

## Sessão 3

**`npm run db:migrate:local` diz `DATABASE_URL não definida`**
O `.env.local` não existe ou está sem a variável. Rode `cp .env.example .env.local` e cole a connection string do Supabase depois do `DATABASE_URL=`, sem aspas e sem espaços.

**`node: .env.local: not found`**
O `npm run db:migrate:local` precisa do arquivo `.env.local` na raiz do repositório. Crie a partir do `.env.example`.

**`node: bad option: --env-file`**
O seu Node é anterior ao 20.6. Atualize o Node.

**`produção ainda sem banco (health: database=memory)`**
A `DATABASE_URL` não está nas Environment Variables da Vercel, ou foi cadastrada depois do último deploy. Variável nova só vale para deploy novo: em Deployments, abra o último deploy de produção e clique em *Redeploy*.

**`produção ainda sem banco (health: database=down)`**
A Vercel achou a variável, mas não conectou no banco. Confira se copiou a string do **Transaction pooler** (porta 6543) e se trocou o marcador de senha pela senha do banco.

**`não consegui criar/ler um evento em produção`**
A tabela `events` ainda não existe. Rode `npm run db:migrate:local` e confira a tabela no *Table Editor* do Supabase.

**Os eventos somem quando testo pela URL de Preview**
É o esperado: a `DATABASE_URL` foi cadastrada só em *Production*, então o preview usa a memória e nunca escreve no banco de produção.

**`gitleaks encontrou possível segredo no repositório`**
Tire o segredo do arquivo, mas saiba que ele continua no histórico do git. Se a senha do banco chegou a ser commitada (pior ainda, com push), troque a senha no Supabase (*Project Settings → Database → Reset database password*) e atualize o `.env.local` e a Vercel.

## Sessão 4

**`vercel pull` falha pedindo login ou dizendo que o projeto não existe**
Faltou algum secret, ou o nome está diferente. Cadastre `VERCEL_TOKEN`, `VERCEL_ORG_ID` e `VERCEL_PROJECT_ID` exatamente com esses nomes. Os dois IDs estão no `.vercel/project.json` (`orgId` e `projectId`) que o `vercel link` gera.

**O passo "Migrar o banco" falha com `DATABASE_URL não definida`**
O GitHub Actions não lê o `.env.local` nem as variáveis da Vercel. Cadastre `DATABASE_URL` também em *Settings → Secrets and variables → Actions*.

**O health-gate falhou com `/health = 000` em todas as tentativas**
A variável `AGENDA_URL` não foi cadastrada (aba *Variables*, ao lado de *Secrets*) e o curl ficou sem endereço. Cadastre com o domínio de produção, sem barra no final.

**O health-gate falhou com `/health = 401`**
O `AGENDA_URL` aponta para a URL de um deploy específico, que fica atrás do login da Vercel. Use o domínio de produção.

**Depois do merge, a Vercel e o pipeline publicaram ao mesmo tempo**
Faltou o `vercel.json` com `"main": false` em `git.deploymentEnabled`. Sem ele, a Vercel continua publicando o `main` sozinha e o seu pipeline vira um segundo deploy.

**Desliguei o Git inteiro da Vercel e os previews sumiram**
Desconectar o repositório em *Settings → Git* desliga também o preview por PR da Sessão 2. Reconecte e use o `vercel.json`, que desliga só o `main`.

**O drill `--incidente` diz que já voltou sem eu fazer nada**
O drill mede o tempo até a produção responder 200 de novo. Faça o *Promote to Production* do deploy anterior antes de rodar `./verificar.sh 4`, senão você mede só o tempo que levou pra digitar.

## Sessão 5

**`README sem badge de status do CI`**
O badge é a imagem que termina em `badge.svg`. Em *Actions → ci → ⋯ → Create status badge*, copie o Markdown e cole no topo do README.
