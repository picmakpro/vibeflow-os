#!/usr/bin/env bash
# test-register-codex-agent-path-traversal.sh — Suite dédiée à la correction de sécurité
# critique de register-codex-agent.sh (Phase 38, audit + reproduction manager) : le champ
# `name:` du frontmatter était dérivé sans validation de charset et servait tel quel à
# construire ROLE_TOML="$AGENTS_DIR/${AGENT_NAME}.toml", en ÉCRITURE (pose) ET en SUPPRESSION
# (--remove). Un `name: ../../../victim/sentinel` écrasait puis supprimait un fichier hors
# périmètre — le chemin vient d'un CONTENU DE FICHIER, jamais d'un basename de listing.
#
# Couvre :
#   T1 — pose : le vecteur exact (../../../victim/sentinel) est REFUSÉ (rc != 0), la sentinelle
#        hors périmètre reste INTACTE (contenu inchangé).
#   T2 — --remove : même vecteur, REFUSÉ (rc != 0), la sentinelle reste INTACTE (pas supprimée).
#        C'est le geste le plus dangereux — celui qui supprime.
#   T3 — preuve par mutation (doctrine feedback_mutation-test-discriminating-cases.md) : sur
#        une copie du script dont le bloc de validation est retiré, le MÊME vecteur écrase puis
#        supprime la sentinelle — la suite ne rougirait pas sur un fixture mort, elle discrimine
#        vraiment la présence de la garde.
#   T4 — autres vecteurs : chemin absolu, ".." seul, nom vide après nettoyage, "/" interne,
#        majuscules, espaces internes, point initial — tous REFUSÉS.
#   T5 — témoin positif : un nom légitime (vf-reviewer) continue de POSER normalement (SKIP
#        propre si node absent du PATH).
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ADAPTER_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$ADAPTER_DIR/../../.." && pwd)"
REGISTER="$ADAPTER_DIR/register-codex-agent.sh"
FIXTURE_LEGIT_AGENT="$REPO/plugin/dev-orchestrator/agents/vf-reviewer.md"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-register-codex-agent-path-traversal (adapter: $ADAPTER_DIR) =="

if [ ! -x "$REGISTER" ]; then
  ko "register-codex-agent.sh introuvable ou non exécutable"
  echo "== résultat : $pass ok, $fail ko =="
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- Fixtures communes -------------------------------------------------------------------
SENTINEL_CONTENT="SENTINEL-DO-NOT-TOUCH-$$"
mk_sentinel() {
  mkdir -p "$WORK/victim"
  printf '%s\n' "$SENTINEL_CONTENT" > "$WORK/victim/sentinel.toml"
}
sentinel_intact() {
  [ -f "$WORK/victim/sentinel.toml" ] && [ "$(cat "$WORK/victim/sentinel.toml")" = "$SENTINEL_CONTENT" ]
}

mk_malicious_agent() {
  # AGENTS_DIR résolu = $CODEX_HOME/agents/vibeflow -> 3 niveaux jusqu'à $WORK.
  local dest="$1"
  cat > "$dest" <<'EOF'
---
name: ../../../victim/sentinel
description: fixture malveillante — traversée de chemin sur le champ name (test de sécurité)
tools: Read
model: sonnet
memory: project
vf-internal: true
---

# Agent : fixture malveillante

Corps minimal, non pertinent pour ce test.
EOF
  # name réécrit explicitement avec 3 remontées pour matcher AGENTS_DIR = codex-home/agents/vibeflow
  sed -i.bak "s#^name:.*#name: ../../../victim/sentinel#" "$dest" && rm -f "$dest.bak"
}

# --- T1 : pose refusée, sentinelle intacte -----------------------------------------------
CODEX_HOME_T1="$WORK/codex-home-t1"
mkdir -p "$CODEX_HOME_T1"
mk_sentinel
AGENT_T1="$WORK/malicious-t1.md"
mk_malicious_agent "$AGENT_T1"

"$REGISTER" "$AGENT_T1" --codex-home "$CODEX_HOME_T1" >"$WORK/t1.out" 2>&1
RC_T1=$?
if [ "$RC_T1" -ne 0 ]; then
  ok "T1.1 pose : rc != 0 sur le vecteur ../../../victim/sentinel ($RC_T1)"
else
  ko "T1.1 pose : rc=0 (devrait refuser) — sortie : $(cat "$WORK/t1.out")"
fi
if sentinel_intact; then
  ok "T1.2 pose : sentinelle hors périmètre INTACTE après tentative"
else
  ko "T1.2 pose : sentinelle ALTÉRÉE — contenu = $(cat "$WORK/victim/sentinel.toml" 2>&1)"
fi
if grep -qi "name invalide" "$WORK/t1.out"; then
  ok "T1.3 pose : message nomme la valeur fautive et la règle"
else
  ko "T1.3 pose : message de refus absent/muet — $(cat "$WORK/t1.out")"
fi

# --- T2 : --remove refusé, sentinelle intacte (le geste le plus dangereux) ---------------
CODEX_HOME_T2="$WORK/codex-home-t2"
# AGENTS_DIR doit PRÉEXISTER pour que la traversée "../../../victim/sentinel.toml" résolve
# depuis un répertoire réel (scénario réaliste : --remove suit toujours une pose antérieure
# qui a déjà créé $CODEX_HOME/agents/vibeflow via mkdir -p).
mkdir -p "$CODEX_HOME_T2/agents/vibeflow"
mk_sentinel
AGENT_T2="$WORK/malicious-t2.md"
mk_malicious_agent "$AGENT_T2"

"$REGISTER" "$AGENT_T2" --codex-home "$CODEX_HOME_T2" --remove >"$WORK/t2.out" 2>&1
RC_T2=$?
if [ "$RC_T2" -ne 0 ]; then
  ok "T2.1 --remove : rc != 0 sur le vecteur ../../../victim/sentinel ($RC_T2)"
else
  ko "T2.1 --remove : rc=0 (devrait refuser) — sortie : $(cat "$WORK/t2.out")"
fi
if sentinel_intact; then
  ok "T2.2 --remove : sentinelle hors périmètre INTACTE (pas supprimée)"
else
  ko "T2.2 --remove : sentinelle SUPPRIMÉE ou altérée"
fi

# --- T3 : preuve par mutation — le rouge vient bien de la traversée, pas d'un chemin mort -
# On construit une copie DU SCRIPT RÉEL, ampute UNIQUEMENT du bloc de validation de charset
# (repéré par ses bornes de commentaire), pour prouver que sans la garde, le MÊME vecteur
# écrase puis supprime la sentinelle. Si ce bloc n'existe plus / a été renommé, le sed ne
# retire rien et le mutant se comporte comme l'original : le test échouerait alors à prouver
# le rouge, ce qui est le signal voulu (mutant mort = suite qui alerte plutôt que de mentir).
# Le mutant doit vivre À CÔTÉ du script réel : register-codex-agent.sh calcule
# SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" et en dérive CONVERTER — une copie posée sous
# $WORK ne retrouverait pas agent-to-codex.mjs. Nettoyé par le trap général (fichier temporaire
# dans ADAPTER_DIR, jamais commité).
MUTANT="$ADAPTER_DIR/.register-codex-agent.MUTANT.$$.sh"
trap 'rm -rf "$WORK" "$MUTANT"' EXIT
awk '
  /^# Validation de charset AU POINT D.USAGE/ { skip=1 }
  skip && /^case "\$AGENT_NAME" in$/ { in_case=1 }
  in_case && /^esac$/ { in_case=0; skip=0; next }
  skip || in_case { next }
  { print }
' "$REGISTER" > "$MUTANT"
chmod +x "$MUTANT"

if grep -q 'name invalide' "$MUTANT"; then
  ko "T3.0 mutation : le bloc de validation est toujours présent dans le mutant — extraction sed/awk à revoir, mutation non prouvée"
else
  ok "T3.0 mutation : bloc de validation effectivement retiré du mutant"

  CODEX_HOME_T3A="$WORK/codex-home-t3a"
  mkdir -p "$CODEX_HOME_T3A"
  mk_sentinel
  AGENT_T3A="$WORK/malicious-t3a.md"
  mk_malicious_agent "$AGENT_T3A"
  "$MUTANT" "$AGENT_T3A" --codex-home "$CODEX_HOME_T3A" >"$WORK/t3a.out" 2>&1 || true
  if sentinel_intact; then
    ko "T3.1 mutation/pose : sentinelle intacte MALGRÉ la garde retirée — le vecteur ne discrimine pas (fixture morte ?)"
  else
    ok "T3.1 mutation/pose : sans la garde, le vecteur écrase bien la sentinelle (rouge confirmé)"
  fi

  CODEX_HOME_T3B="$WORK/codex-home-t3b"
  # Même remarque que T2 : AGENTS_DIR doit préexister pour que la traversée résolve.
  mkdir -p "$CODEX_HOME_T3B/agents/vibeflow"
  mk_sentinel
  AGENT_T3B="$WORK/malicious-t3b.md"
  mk_malicious_agent "$AGENT_T3B"
  "$MUTANT" "$AGENT_T3B" --codex-home "$CODEX_HOME_T3B" --remove >"$WORK/t3b.out" 2>&1 || true
  if [ -f "$WORK/victim/sentinel.toml" ]; then
    ko "T3.2 mutation/remove : sentinelle toujours présente MALGRÉ la garde retirée — le vecteur ne discrimine pas"
  else
    ok "T3.2 mutation/remove : sans la garde, --remove supprime bien la sentinelle (rouge confirmé)"
  fi
fi

# --- T4 : autres vecteurs — tous refusés ---------------------------------------------------
mk_agent_with_name() {
  local dest="$1" name="$2"
  {
    echo "---"
    echo "name: $name"
    echo "description: fixture vecteur ($name) — test de sécurité charset"
    echo "tools: Read"
    echo "model: sonnet"
    echo "memory: project"
    echo "vf-internal: true"
    echo "---"
    echo ""
    echo "# corps minimal"
  } > "$dest"
}

check_vector_refused() {
  local label="$1" name="$2"
  local codex_home="$WORK/codex-home-vec-$(echo "$label" | tr -c 'a-zA-Z0-9' '_')"
  mkdir -p "$codex_home"
  local agent="$WORK/vec-$(echo "$label" | tr -c 'a-zA-Z0-9' '_').md"
  mk_agent_with_name "$agent" "$name"
  local out
  out="$("$REGISTER" "$agent" --codex-home "$codex_home" 2>&1)"
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    ok "T4 [$label] refusé (rc=$rc)"
  else
    ko "T4 [$label] accepté à tort (rc=0) — sortie : $out"
  fi
}

check_vector_refused "chemin absolu"      "/etc/x"
check_vector_refused "point-point seul"   ".."
check_vector_refused "vide apres nettoyage" "   "
check_vector_refused "slash interne"      "vf/reviewer"
check_vector_refused "majuscules"         "VF-Reviewer"
# Espace de largeur nulle (U+200B, \xe2\x80\x8b) : hors classe POSIX [:space:] de la
# dérivation amont (sed | tr -d '[:space:]', mesuré : \xc2\xa0 insécable EST strippé par ce
# tr sur ce poste) donc SURVIT au nettoyage — seul vecteur "séparateur interne" qui atteint
# réellement la validation de charset (un espace ASCII ordinaire serait déjà supprimé en
# amont, ne testerait donc rien).
check_vector_refused "separateur interne (zero-width space)" "$(printf 'vf\xe2\x80\x8breviewer')"
check_vector_refused "point initial"      ".vf-reviewer"

# --- T5 : témoin positif — un nom légitime continue de poser ------------------------------
if ! command -v node >/dev/null 2>&1; then
  skip "T5 témoin positif : node absent du PATH — pose réelle non exerçable"
elif [ ! -f "$FIXTURE_LEGIT_AGENT" ]; then
  skip "T5 témoin positif : fixture légitime introuvable ($FIXTURE_LEGIT_AGENT)"
else
  CODEX_HOME_T5="$WORK/codex-home-t5"
  mkdir -p "$CODEX_HOME_T5"
  OUT_T5="$("$REGISTER" "$FIXTURE_LEGIT_AGENT" --codex-home "$CODEX_HOME_T5" 2>&1)"
  RC_T5=$?
  if [ "$RC_T5" -eq 0 ] && [ -f "$CODEX_HOME_T5/agents/vibeflow/vf-reviewer.toml" ]; then
    ok "T5 témoin positif : vf-reviewer posé normalement (validation n'a pas cassé le cas légitime)"
  else
    ko "T5 témoin positif : pose légitime cassée (rc=$RC_T5) — sortie : $OUT_T5"
  fi
fi

echo "== résultat : $pass ok, $fail ko =="
[ "$fail" -eq 0 ]
