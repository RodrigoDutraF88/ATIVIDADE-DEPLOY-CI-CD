#!/usr/bin/env bash
#
# verificar.sh - checagens da Trilha de Deploy & CI/CD da CJR.
# Uso: ./verificar.sh <numero-da-sessao>   (de 1 a 5)
#      ./verificar.sh 4 --incidente         (drill de rollback da Sessão 4)
#      ./verificar.sh --reset-nome | --reset
#
# Itens em vermelho (✗) são o que ainda falta fazer. Faça a tarefa e rode de novo.
#
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
NOME_FILE="$DIR/.verificar-nome"
URL_FILE="$DIR/.verificar-url"
INC_FILE="$DIR/.verificar-incidente"

verde=$'\033[32m'; verm=$'\033[31m'; amar=$'\033[33m'; neg=$'\033[1m'; z=$'\033[0m'
FALHOU=0

ok()    { printf "  ${verde}✓${z} %s\n" "$1"; }
falha() { printf "  ${verm}✗${z} %s\n" "$1"; FALHOU=1; }
dica()  { printf "      ${amar}↳${z} %s\n" "$1"; }
parabens() { printf "\n${verde}${neg}🎉 Parabéns, %s!${z} %s\n" "$NOME" "$1"; }
quase()    { printf "\n${verm}%s, quase lá.${z} Os itens com ${verm}✗${z} são o que falta, faça e rode de novo.\n" "$NOME"; }
fim()      { if [ "$FALHOU" -eq 0 ]; then parabens "$1"; else quase; fi; }
banner()   { printf "%sOlá, %s! Conferindo a Sessão %s: %s.%s\n\n" "$neg" "$NOME" "$1" "$2" "$z"; FALHOU=0; }

carregar_nome() {
  [ -n "${TRILHA_NOME:-}" ] && { printf '%s' "$TRILHA_NOME"; return; }
  [ -f "$NOME_FILE" ] && { cat "$NOME_FILE"; return; }
  local n="colega"
  if [ -t 0 ]; then
    printf 'Antes de começar, como você se chama? ' >&2
    read -r n; n="${n:-colega}"
  fi
  printf '%s' "$n" > "$NOME_FILE"
  printf '%s' "$n"
}

carregar_url() {
  [ -n "${AGENDA_URL:-}" ] && { printf '%s' "${AGENDA_URL%/}"; return; }
  [ -f "$URL_FILE" ] && { cat "$URL_FILE"; return; }
  local u=""
  if [ -t 0 ]; then
    printf 'Cole a URL de produção da sua Agenda na Vercel (ex: https://agenda.vercel.app): ' >&2
    read -r u; u="${u%/}"
  fi
  [ -n "$u" ] && printf '%s' "$u" > "$URL_FILE"
  printf '%s' "$u"
}

repo_slug() {
  local url; url="$(cd "$DIR" && git config --get remote.origin.url 2>/dev/null)"
  url="${url%.git}"
  printf '%s' "$url" | sed -E 's#(git@github.com:|https://github.com/)##'
}

http_status() { curl -s -o /dev/null -m 8 -w '%{http_code}' "$1" 2>/dev/null || printf '000'; }
json_get()     { sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p" <<<"$1"; }
check_grep()   { if grep -qE "$2" "$1" 2>/dev/null; then ok "$3"; else falha "$4"; fi; }

# O gh precisa estar instalado e logado para ler as regras do repositório no GitHub.
gh_pronto() {
  if ! command -v gh >/dev/null 2>&1; then
    falha "gh (GitHub CLI) não encontrado, não dá pra checar o GitHub"
    dica "instale o gh e rode 'gh auth login'"
    return 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    falha "o gh não está logado"
    dica "rode 'gh auth login' e tente de novo"
    return 1
  fi
}

checar_protecao() {
  gh_pronto || return
  local slug rs cl; slug="$(repo_slug)"
  # Rulesets (novo): regras efetivas aplicadas ao branch main
  rs="$(gh api "repos/${slug}/rules/branches/main" --jq '[.[] | select(.type=="required_status_checks") | .parameters.required_status_checks[] | select(.context=="testes")] | length' 2>/dev/null)"
  # Branch protection clássico
  cl="$(gh api "repos/${slug}/branches/main/protection" --jq '[(.required_status_checks.contexts // [])[] | select(. == "testes")] | length' 2>/dev/null)"
  case "$rs" in ''|*[!0-9]*) rs=0;; esac
  case "$cl" in ''|*[!0-9]*) cl=0;; esac
  if [ $(( rs + cl )) -gt 0 ]; then
    ok "o main exige o check testes para mergear"
  else
    falha "o main não exige o check testes para mergear"
    dica "na regra de proteção do main: ligue 'Require status checks' E adicione o check 'testes' na lista (ele aparece depois do CI rodar uma vez)"
  fi
}

# --- Sessão 1 --------------------------------------------------------------
sessao1() {
  banner 1 "CI e o portão do merge"
  local wf="$DIR/.github/workflows/ci.yml"
  if [ -f "$wf" ]; then
    ok "workflow .github/workflows/ci.yml encontrado"
    if grep -Eq '^[[:space:]]+testes:' "$wf"; then ok "o job se chama testes (é o nome do check que o portão exige)"
    else falha "não achei o job testes no ci.yml"; dica "o nome do job vira o nome do check: use 'testes:' embaixo de 'jobs:'"; fi
    if grep -q 'pull_request' "$wf"; then ok "o workflow roda em todo pull request"
    else falha "o workflow não roda em pull_request"; dica "em 'on:', coloque 'push:' e 'pull_request:'"; fi
    if grep -q 'npm run lint' "$wf" && grep -q 'npm test' "$wf"; then ok "o workflow roda o lint e os testes"
    else falha "o workflow não roda o lint e os testes"; dica "inclua os passos 'npm ci', 'npm run lint' e 'npm test' no job"; fi
  else
    falha "não encontrei .github/workflows/ci.yml"; dica "crie o workflow como está no Mão na massa da Sessão 1"
  fi
  if ( cd "$DIR" && npm test >/tmp/agenda-test.log 2>&1 ); then ok "npm test passou na sua máquina"
  else falha "npm test falhou na sua máquina"; dica "rode 'npm test' para ver o erro"; fi
  if ( cd "$DIR" && npm run lint >/tmp/agenda-lint.log 2>&1 ); then ok "npm run lint passou na sua máquina"
  else falha "npm run lint falhou"; dica "rode 'npm run lint' para ver os avisos"; fi
  checar_protecao
  fim "CI rodando e portão de pé: código vermelho não entra mais no main."
}

# --- Sessão 2 --------------------------------------------------------------
sessao2() {
  banner 2 "no ar na Vercel (Checkpoint)"
  local url; url="$(carregar_url)"
  if [ -z "$url" ]; then falha "não tenho a URL do seu deploy"; dica "rode de novo e cole a URL, ou defina AGENDA_URL"; fim "..."; return; fi
  ok "URL de produção: $url"
  local code; code="$(http_status "$url/api/health")"
  if [ "$code" = "200" ]; then ok "/api/health respondeu 200"
  elif [ "$code" = "401" ]; then falha "/api/health respondeu 401 (URL protegida)"; dica "essa é a URL de um deploy específico: cole o domínio de produção (Settings > Domains) com './verificar.sh --reset'"
  else falha "/api/health respondeu ${code}"; dica "confira o deploy na aba Deployments da Vercel"; fi
  local remoto local_sha; remoto="$(json_get "$(curl -s -m 8 "$url/api/version" 2>/dev/null)" commit)"
  local_sha="$(cd "$DIR" && git rev-parse HEAD 2>/dev/null)"
  local match=0
  case "$local_sha" in "$remoto"*) [ -n "$remoto" ] && match=1;; esac
  case "$remoto" in "$local_sha"*) [ -n "$local_sha" ] && match=1;; esac
  if [ "$remoto" = "local" ] || [ -z "$remoto" ]; then match=0; fi
  if [ "$match" = "1" ]; then ok "produção está servindo o seu commit (${remoto:0:7})"
  else falha "o commit em produção não bate com o seu HEAD"; dica "mergeie o PR, rode 'git checkout main && git pull' e espere a Vercel redeployar (prod=${remoto:-?}, local=${local_sha:0:7})"; fi
  if gh_pronto; then
    local prs; prs="$(gh pr list --repo "$(repo_slug)" --state merged --limit 1 --json number --jq length 2>/dev/null)"
    case "$prs" in ''|*[!0-9]*) prs=0;; esac
    if [ "$prs" -gt 0 ]; then ok "a mudança entrou no main por um pull request"
    else falha "nenhum pull request mergeado no seu fork"; dica "faça a mudança num branch, abra o PR para o main do SEU fork, confira o Preview e mergeie"; fi
  fi
  fim "Checkpoint! A Agenda está no ar e toda mudança passa pelo preview antes de virar produção."
}

# --- Sessão 3 --------------------------------------------------------------
sessao3() {
  banner 3 "persistência e segredos"
  local url; url="$(carregar_url)"
  if [ -z "$url" ]; then
    falha "sem a URL do deploy"; dica "faça a Sessão 2 antes, ou defina AGENDA_URL"
  else
    local db; db="$(json_get "$(curl -s -m 8 "$url/api/health" 2>/dev/null)" database)"
    if [ "$db" = "up" ]; then ok "produção conectada ao banco (health: database=up)"
    else falha "produção ainda sem banco (health: database=${db:-?})"; dica "configure DATABASE_URL nas Environment Variables da Vercel (Production) e faça Redeploy"; fi
    local marker="verificar-$(date +%s)" created id
    created="$(curl -s -m 8 -X POST "$url/api/events" -H 'Content-Type: application/json' -d "{\"title\":\"$marker\",\"start\":\"2027-01-01T10:00:00.000Z\"}" 2>/dev/null)"
    id="$(json_get "$created" id)"
    if [ -n "$id" ] && curl -s -m 8 "$url/api/events" 2>/dev/null | grep -q "$marker"; then
      ok "evento criado e lido de volta em produção (persistiu)"
      curl -s -m 8 -X DELETE "$url/api/events/$id" >/dev/null 2>&1
    else
      falha "não consegui criar/ler um evento em produção"
      dica "rode a migração (npm run db:migrate:local) e confira a tabela events no Supabase"
    fi
  fi
  if [ -f "$DIR/.env.local" ] && grep -q 'DATABASE_URL=..*' "$DIR/.env.local"; then ok ".env.local com DATABASE_URL (local)"
  else falha ".env.local sem DATABASE_URL"; dica "cp .env.example .env.local e cole a URL do Supabase"; fi
  if ( cd "$DIR" && git check-ignore -q .env.local ) 2>/dev/null; then ok ".env.local está ignorado pelo git (segredo fora do repo)"
  else falha ".env.local NÃO está sendo ignorado pelo git"; dica "garanta que '.env*.local' está no .gitignore"; fi
  if command -v gitleaks >/dev/null 2>&1; then
    if ( cd "$DIR" && gitleaks detect --no-banner >/tmp/agenda-gitleaks.log 2>&1 ); then ok "gitleaks não encontrou segredos no repositório"
    else falha "gitleaks encontrou possível segredo no repositório"; dica "veja /tmp/agenda-gitleaks.log, tire o segredo do git e troque a senha no Supabase"; fi
  else
    if ( cd "$DIR" && git grep -nIE 'postgres(ql)?://[^ ]*:[^ ]*@|sk_live_|ghp_[0-9A-Za-z]{20}' -- . ':!*.example' ':!verificar.sh' >/tmp/agenda-segredos.log 2>&1 ); then
      falha "encontrei algo com cara de segredo versionado"; dica "veja /tmp/agenda-segredos.log (instale o gitleaks para uma checagem melhor)"
    else ok "sem segredos óbvios versionados (instale o gitleaks para checagem completa)"; fi
  fi
  fim "A Agenda agora persiste de verdade: banco no ar e nenhum segredo no git."
}

# --- Sessão 4 --------------------------------------------------------------
sessao4() {
  banner 4 "dono do pipeline + rollback (Entrega)"
  local url; url="$(carregar_url)"
  if [ -f "$INC_FILE" ] && [ -n "$url" ] && [ "$(http_status "$url/api/health")" = "200" ]; then
    local ini agora mttr; ini="$(cat "$INC_FILE")"; agora="$(date +%s)"; mttr=$(( agora - ini ))
    rm -f "$INC_FILE"
    ok "produção voltou a responder /health 200"
    fim "Você puxou o prato em ${mttr}s. Rollback dominado."
    return
  fi
  local wf="$DIR/.github/workflows/deploy.yml"
  if [ ! -f "$wf" ]; then falha "não encontrei .github/workflows/deploy.yml"; dica "crie o pipeline (veja gabarito/deploy.yml)"; fim "..."; return; fi
  ok "deploy.yml encontrado"
  check_grep "$wf" 'vercel build' "builda com a Vercel (vercel build)" "faltou 'vercel build' no pipeline"
  check_grep "$wf" 'deploy --prebuilt' "publica o build pronto (vercel deploy --prebuilt)" "faltou 'vercel deploy --prebuilt'"
  check_grep "$wf" 'npm test' "roda os testes antes de publicar" "o pipeline não roda 'npm test' antes do deploy"
  check_grep "$wf" 'db:migrate' "roda a migração do banco no deploy" "faltou 'npm run db:migrate' no pipeline"
  check_grep "$wf" 'secrets\.' "usa secrets (sem valor cru no arquivo)" "o pipeline não usa 'secrets.', nada de token cru no YAML"
  check_grep "$wf" 'health' "confere /api/health depois de publicar (health-gate)" "faltou o smoke test de /health (health-gate)"
  if [ -f "$DIR/vercel.json" ] && grep -Eq '"main"[[:space:]]*:[[:space:]]*false' "$DIR/vercel.json"; then
    ok "a Vercel não publica mais o main sozinha (só o seu pipeline publica)"
  else
    falha "a Vercel ainda publica o main sozinha"
    dica "crie o vercel.json com git.deploymentEnabled.main = false (veja gabarito/vercel.json)"
  fi
  if ( cd "$DIR" && npm run build >/tmp/agenda-build.log 2>&1 ); then ok "npm run build passa localmente"
  else falha "npm run build falhou"; dica "rode 'npm run build' para ver o erro"; fi
  printf "      ${amar}↳${z} treine o rollback com o drill: ./verificar.sh 4 --incidente\n"
  fim "Pipeline com health-gate e rollback no bolso. Entrega feita. Fim da parte essencial! 🎓"
}

incidente() {
  NOME="$(carregar_nome)"
  local url; url="$(carregar_url)"
  if [ -z "$url" ]; then echo "Preciso da URL do deploy primeiro (faça a Sessão 2)."; return 1; fi
  date +%s > "$INC_FILE"
  printf "%s🚨 Simulação de incidente, %s.%s\n" "$neg" "$NOME" "$z"
  printf "Produção: %s\n" "$url"
  printf "Na Vercel: Deployments → pegue o deploy ANTERIOR (o que funcionava) → Promote to Production.\n"
  printf "Quando o /api/health voltar a 200, rode:  ./verificar.sh 4\n"
  printf "Estou cronometrando o seu MTTR...\n"
}

# --- Sessão 5 --------------------------------------------------------------
sessao5() {
  banner 5 "observabilidade e próximos passos (opcional)"
  if [ -f "$DIR/README.md" ] && grep -q 'badge.svg' "$DIR/README.md"; then
    ok "README tem o badge de status do CI"
  else
    falha "README sem badge de status do CI"
    dica "no GitHub: Actions > ci > (...) > Create status badge, e cole no topo do README"
  fi
  local url; url="$(carregar_url)"
  if [ -n "$url" ]; then
    local code; code="$(http_status "$url/api/health")"
    if [ "$code" = "200" ]; then ok "produção no ar pra observar (/health 200)"
    else falha "/health respondeu ${code}"; fi
  fi
  printf "      ${amar}↳${z} bônus: ative o Vercel Analytics e explore os Logs no dashboard da Vercel\n"
  fim "Sessão bônus concluída. Agora é olhar o salão e escolher o próximo passo."
}

# --- entrada ---------------------------------------------------------------
case "${1:-}" in
  --reset-nome) rm -f "$NOME_FILE"; echo "Pronto, esqueci seu nome."; exit 0;;
  --reset)      rm -f "$NOME_FILE" "$URL_FILE" "$INC_FILE"; echo "Estado zerado (nome, URL e incidente)."; exit 0;;
esac

if [ "${1:-}" = "4" ] && [ "${2:-}" = "--incidente" ]; then
  incidente; exit 0
fi

NOME="$(carregar_nome)"

case "${1:-}" in
  1) sessao1;;
  2) sessao2;;
  3) sessao3;;
  4) sessao4;;
  5) sessao5;;
  ""|-h|--help)
    echo "Uso: ./verificar.sh <numero-da-sessao>   (de 1 a 5)"
    echo "     ./verificar.sh 4 --incidente         (drill de rollback)"
    echo "     ./verificar.sh --reset-nome | --reset"
    exit 0;;
  *) echo "Sessão inválida: ${1}. Use um número de 1 a 5."; exit 1;;
esac

exit "$FALHOU"
