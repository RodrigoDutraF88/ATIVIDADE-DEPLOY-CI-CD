#!/usr/bin/env bash
#
# verificar.sh - checagens da Trilha de Deploy & CI/CD da CJR.
# Uso: ./verificar.sh <numero-da-sessao>   (de 1 a 7)
#      ./verificar.sh 6 --incidente         (drill de rollback do Modulo 6)
#      ./verificar.sh --reset-nome | --reset
#
# Itens em vermelho (X) sao o que ainda falta fazer. Faca a tarefa e rode de novo.
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
quase()    { printf "\n${verm}%s, quase lá.${z} Os itens com ${verm}✗${z} são o que falta — faça e rode de novo.\n" "$NOME"; }
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

# --- Sessão 1 --------------------------------------------------------------
sessao1() {
  banner 1 "testes no CI"
  local wf="$DIR/.github/workflows/ci.yml"
  if [ -f "$wf" ]; then ok "workflow .github/workflows/ci.yml encontrado"
  else falha "não encontrei .github/workflows/ci.yml"; dica "crie o workflow como está no Mão na massa da Sessão 1"; fi
  if [ -f "$wf" ] && grep -Eq 'npm (ci|test)' "$wf"; then ok "o workflow instala e roda os testes"
  else falha "o workflow não roda os testes"; dica "inclua os passos 'npm ci' e 'npm test' no job"; fi
  if ( cd "$DIR" && npm test >/tmp/agenda-test.log 2>&1 ); then ok "npm test passou na sua máquina"
  else falha "npm test falhou na sua máquina"; dica "rode 'npm test' para ver o erro"; fi
  fim "Seu CI prova cada push — ninguém mais vai esquecer de rodar os testes."
}

# --- Sessão 2 --------------------------------------------------------------
sessao2() {
  banner 2 "o portão: vermelho barra o merge"
  if ( cd "$DIR" && npm run lint >/tmp/agenda-lint.log 2>&1 ); then ok "npm run lint passou"
  else falha "npm run lint falhou"; dica "rode 'npm run lint' para ver os avisos"; fi
  if ! command -v gh >/dev/null 2>&1; then
    falha "gh (GitHub CLI) não encontrado — não dá pra checar a proteção do branch"
    dica "instale o gh e rode 'gh auth login', ou confira em Settings > Branches no GitHub"
  else
    local slug ctx; slug="$(repo_slug)"
    ctx="$(gh api "repos/${slug}/branches/main/protection" --jq '.required_status_checks.contexts | length' 2>/dev/null)"
    case "$ctx" in
      ''|*[!0-9]*) falha "o branch main não exige o check do CI para mergear"
                   dica "em Settings > Branches, proteja o main e marque 'Require status checks to pass'";;
      0)           falha "proteção existe, mas sem check obrigatório"
                   dica "marque o check 'testes' como obrigatório em Settings > Branches";;
      *)           ok "branch main protegido, exigindo ${ctx} check(s) obrigatório(s)";;
    esac
  fi
  fim "O portão está de pé: código vermelho não entra mais no main."
}

# --- Sessão 3 --------------------------------------------------------------
sessao3() {
  banner 3 "no ar: primeiro deploy na Vercel"
  local url; url="$(carregar_url)"
  if [ -z "$url" ]; then falha "não tenho a URL do seu deploy"; dica "rode de novo e cole a URL, ou defina AGENDA_URL"; fim "..."; return; fi
  ok "URL de produção: $url"
  local code; code="$(http_status "$url/api/health")"
  if [ "$code" = "200" ]; then ok "/api/health respondeu 200"
  else falha "/api/health respondeu ${code}"; dica "confira o deploy na aba Deployments da Vercel"; fi
  local remoto local_sha; remoto="$(json_get "$(curl -s -m 8 "$url/api/version" 2>/dev/null)" commit)"
  local_sha="$(cd "$DIR" && git rev-parse HEAD 2>/dev/null)"
  local match=0
  case "$local_sha" in "$remoto"*) [ -n "$remoto" ] && match=1;; esac
  case "$remoto" in "$local_sha"*) [ -n "$local_sha" ] && match=1;; esac
  if [ "$remoto" = "local" ] || [ -z "$remoto" ]; then match=0; fi
  if [ "$match" = "1" ]; then ok "produção está servindo o seu commit (${remoto:0:7})"
  else falha "o commit em produção não bate com o seu HEAD"; dica "push do main e espere a Vercel redeployar (prod=${remoto:-?}, local=${local_sha:0:7})"; fi
  fim "Sua Agenda está no ar servindo o seu commit!"
}

# --- Sessão 4 --------------------------------------------------------------
sessao4() {
  banner 4 "persistência: banco no Supabase"
  local url; url="$(carregar_url)"
  if [ -z "$url" ]; then falha "sem a URL do deploy"; dica "faça a Sessão 3 antes"; fim "..."; return; fi
  local db; db="$(json_get "$(curl -s -m 8 "$url/api/health" 2>/dev/null)" database)"
  if [ "$db" = "up" ]; then ok "produção conectada ao banco (health: database=up)"
  else falha "produção ainda sem banco (health: database=${db:-?})"; dica "configure DATABASE_URL nas Environment Variables da Vercel e faça redeploy"; fi
  local marker="verificar-$(date +%s)" created id
  created="$(curl -s -m 8 -X POST "$url/api/events" -H 'Content-Type: application/json' -d "{\"title\":\"$marker\",\"start\":\"2027-01-01T10:00:00.000Z\"}" 2>/dev/null)"
  id="$(json_get "$created" id)"
  if [ -n "$id" ] && curl -s -m 8 "$url/api/events" 2>/dev/null | grep -q "$marker"; then
    ok "evento criado e lido de volta em produção (persistiu)"
    curl -s -m 8 -X DELETE "$url/api/events/$id" >/dev/null 2>&1
  else
    falha "não consegui criar/ler um evento em produção"
    dica "rode a migração (npm run db:migrate) e confira a tabela events no Supabase"
  fi
  if [ -f "$DIR/.env.local" ] && grep -q 'DATABASE_URL=..*' "$DIR/.env.local"; then ok ".env.local com DATABASE_URL (local)"
  else falha ".env.local sem DATABASE_URL"; dica "cp .env.example .env.local e cole a URL do Supabase"; fi
  if ( cd "$DIR" && git check-ignore -q .env.local ) 2>/dev/null; then ok ".env.local está ignorado pelo git (segredo fora do repo)"
  else falha ".env.local NÃO está sendo ignorado pelo git"; dica "garanta que '.env*.local' está no .gitignore"; fi
  fim "A Agenda agora persiste de verdade: banco no ar e segredo fora do git."
}

# --- Sessão 5 --------------------------------------------------------------
sessao5() {
  banner 5 "preview por PR"
  local achou=0 f
  for f in "$DIR"/.github/workflows/*.yml "$DIR"/.github/workflows/*.yaml; do
    [ -f "$f" ] && grep -qE 'pull_request' "$f" && achou=1
  done
  if [ "$achou" = "1" ]; then ok "há workflow rodando em pull_request (todo PR é checado)"
  else falha "nenhum workflow dispara em pull_request"; dica "garanta 'on: pull_request' no seu ci.yml"; fi
  if command -v gitleaks >/dev/null 2>&1; then
    if ( cd "$DIR" && gitleaks detect --no-banner >/tmp/agenda-gitleaks.log 2>&1 ); then ok "gitleaks não encontrou segredos no repositório"
    else falha "gitleaks encontrou possível segredo no repositório"; dica "veja /tmp/agenda-gitleaks.log e remova o segredo do git"; fi
  else
    if ( cd "$DIR" && git grep -nIE 'postgres(ql)?://[^ ]*:[^ ]*@|sk_live_|ghp_[0-9A-Za-z]{20}' -- . ':!*.example' ':!verificar.sh' >/tmp/agenda-segredos.log 2>&1 ); then
      falha "encontrei algo com cara de segredo versionado"; dica "veja /tmp/agenda-segredos.log (instale o gitleaks para uma checagem melhor)"
    else ok "sem segredos óbvios versionados (instale o gitleaks para checagem completa)"; fi
  fi
  if ( cd "$DIR" && git check-ignore -q .env.local ) 2>/dev/null; then ok ".env.local ignorado pelo git"
  else falha ".env.local não está ignorado"; dica "adicione '.env*.local' ao .gitignore"; fi
  fim "Preview por PR funcionando e nenhum segredo vazou pro git."
}

# --- Sessão 6 --------------------------------------------------------------
sessao6() {
  banner 6 "promoção segura: health-gate + rollback"
  local url; url="$(carregar_url)"
  if [ -f "$INC_FILE" ] && [ -n "$url" ] && [ "$(http_status "$url/api/health")" = "200" ]; then
    local ini agora mttr; ini="$(cat "$INC_FILE")"; agora="$(date +%s)"; mttr=$(( agora - ini ))
    rm -f "$INC_FILE"
    ok "produção voltou a responder /health 200"
    fim "Você puxou o prato em ${mttr}s. Rollback dominado."
    return
  fi
  if [ -z "$url" ]; then falha "sem a URL do deploy"; dica "faça a Sessão 3 antes"; fim "..."; return; fi
  local code; code="$(http_status "$url/api/health")"
  if [ "$code" = "200" ]; then ok "produção saudável agora (/health 200)"
  else falha "/health respondeu ${code} — produção não está saudável"; dica "na Vercel, promova o último deploy bom (rollback)"; fi
  printf "      ${amar}↳${z} treine o rollback com o drill: ./verificar.sh 6 --incidente\n"
  fim "Você sabe voltar atrás rápido — rollback é rede de segurança, não vergonha."
}

incidente() {
  NOME="$(carregar_nome)"
  local url; url="$(carregar_url)"
  if [ -z "$url" ]; then echo "Preciso da URL do deploy primeiro (faça a Sessão 3)."; return 1; fi
  date +%s > "$INC_FILE"
  printf "%s🚨 Simulação de incidente, %s.%s\n" "$neg" "$NOME" "$z"
  printf "Produção: %s\n" "$url"
  printf "Na Vercel: Deployments → pegue o deploy ANTERIOR (o que funcionava) → Promote to Production.\n"
  printf "Quando o /api/health voltar a 200, rode:  ./verificar.sh 6\n"
  printf "Estou cronometrando o seu MTTR...\n"
}

# --- Sessão 7 --------------------------------------------------------------
sessao7() {
  banner 7 "dono do pipeline: Actions + Vercel CLI"
  local wf="$DIR/.github/workflows/deploy.yml"
  if [ ! -f "$wf" ]; then falha "não encontrei .github/workflows/deploy.yml"; dica "crie o pipeline (veja gabarito/deploy.yml)"; fim "..."; return; fi
  ok "deploy.yml encontrado"
  check_grep "$wf" 'vercel build' "builda com a Vercel (vercel build)" "faltou 'vercel build' no pipeline"
  check_grep "$wf" 'deploy --prebuilt' "publica o build pronto (vercel deploy --prebuilt)" "faltou 'vercel deploy --prebuilt'"
  check_grep "$wf" 'npm test' "roda os testes antes de publicar" "o pipeline não roda 'npm test' antes do deploy"
  check_grep "$wf" 'db:migrate' "roda a migração do banco no deploy" "faltou 'npm run db:migrate' no pipeline"
  check_grep "$wf" 'secrets\.' "usa secrets (sem valor cru no arquivo)" "o pipeline não usa 'secrets.' — nada de token cru no YAML"
  check_grep "$wf" 'health' "confere /api/health depois de publicar (health-gate)" "faltou o smoke test de /health (health-gate) no pipeline"
  if ( cd "$DIR" && npm run build >/tmp/agenda-build.log 2>&1 ); then ok "npm run build passa localmente"
  else falha "npm run build falhou"; dica "rode 'npm run build' para ver o erro"; fi
  fim "Seu pipeline testa, migra, builda e publica sozinho. Fim da trilha! 🎓"
}

# --- entrada ---------------------------------------------------------------
case "${1:-}" in
  --reset-nome) rm -f "$NOME_FILE"; echo "Pronto, esqueci seu nome."; exit 0;;
  --reset)      rm -f "$NOME_FILE" "$URL_FILE" "$INC_FILE"; echo "Estado zerado (nome, URL e incidente)."; exit 0;;
esac

if [ "${1:-}" = "6" ] && [ "${2:-}" = "--incidente" ]; then
  incidente; exit 0
fi

NOME="$(carregar_nome)"

case "${1:-}" in
  1) sessao1;;
  2) sessao2;;
  3) sessao3;;
  4) sessao4;;
  5) sessao5;;
  6) sessao6;;
  7) sessao7;;
  ""|-h|--help)
    echo "Uso: ./verificar.sh <numero-da-sessao>   (de 1 a 7)"
    echo "     ./verificar.sh 6 --incidente         (drill de rollback)"
    echo "     ./verificar.sh --reset-nome | --reset"
    exit 0;;
  *) echo "Sessão inválida: ${1}. Use um número de 1 a 7."; exit 1;;
esac

exit "$FALHOU"
