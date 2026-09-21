#!/usr/bin/env bash
#
# verificar.sh - checagens da Trilha de Deploy & CI/CD da CJR.
# Uso: ./verificar.sh <numero-da-sessao>   (de 1 a 7)
#      ./verificar.sh --reset-nome
#
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
NOME_FILE="$DIR/.verificar-nome"

verde=$'\033[32m'; verm=$'\033[31m'; amar=$'\033[33m'; neg=$'\033[1m'; z=$'\033[0m'

carregar_nome() {
  [ -n "${TRILHA_NOME:-}" ] && { printf '%s' "$TRILHA_NOME"; return; }
  [ -f "$NOME_FILE" ] && { cat "$NOME_FILE"; return; }
  local n="colega"
  if [ -t 0 ]; then
    printf 'Antes de começar, como você se chama? ' >&2
    read -r n
    n="${n:-colega}"
  fi
  printf '%s' "$n" > "$NOME_FILE"
  printf '%s' "$n"
}

if [ "${1:-}" = "--reset-nome" ]; then
  rm -f "$NOME_FILE"
  echo "Pronto, esqueci seu nome. Da próxima vez eu pergunto de novo."
  exit 0
fi

NOME="$(carregar_nome)"
FALHOU=0

ok()    { printf "  ${verde}✓${z} %s\n" "$1"; }
falha() { printf "  ${verm}✗${z} %s\n" "$1"; FALHOU=1; }
dica()  { printf "      ${amar}↳${z} %s\n" "$1"; }

parabens() { printf "\n${verde}${neg}🎉 Parabéns, %s!${z} %s\n" "$NOME" "$1"; }
quase()    { printf "\n${verm}%s, quase lá.${z} Corrija os itens marcados com ${verm}✗${z} e rode de novo.\n" "$NOME"; }

# --- Sessão 1 -------------------------------------------------------------
sessao1() {
  printf "%sOlá, %s! Conferindo a Sessão 1: testes no CI.%s\n\n" "$neg" "$NOME" "$z"
  local wf="$DIR/.github/workflows/ci.yml"

  if [ -f "$wf" ]; then
    ok "workflow .github/workflows/ci.yml encontrado"
  else
    falha "não encontrei .github/workflows/ci.yml"
    dica "crie o workflow como está no Mão na massa da Sessão 1"
  fi

  if [ -f "$wf" ] && grep -Eq 'npm (ci|test)' "$wf"; then
    ok "o workflow instala e roda os testes"
  else
    falha "o workflow não roda os testes"
    dica "inclua os passos 'npm ci' e 'npm test' no job"
  fi

  if [ ! -f "$DIR/package.json" ] || ! grep -q '"test"' "$DIR/package.json"; then
    falha "não há script de teste no package.json"
    dica "confira se você está na raiz do fork da Agenda"
  elif ( cd "$DIR" && npm test >/tmp/agenda-test.log 2>&1 ); then
    ok "npm test passou na sua máquina"
  else
    falha "npm test falhou na sua máquina"
    dica "rode 'npm test' para ver o erro (log salvo em /tmp/agenda-test.log)"
  fi

  if [ "$FALHOU" -eq 0 ]; then
    parabens "Seu CI prova cada push — ninguém mais vai esquecer de rodar os testes."
  else
    quase
  fi
}

case "${1:-}" in
  1) sessao1;;
  2|3|4|5|6|7)
    echo "A verificação da Sessão ${1} ainda não foi publicada. Em breve."
    exit 0
    ;;
  ""|-h|--help)
    echo "Uso: ./verificar.sh <numero-da-sessao>   (de 1 a 7)"
    echo "     ./verificar.sh --reset-nome"
    exit 0
    ;;
  *)
    echo "Sessão inválida: ${1}. Use um número de 1 a 7."
    exit 1
    ;;
esac

exit "$FALHOU"
