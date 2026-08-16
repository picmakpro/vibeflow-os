#!/usr/bin/env bash
# test-manifest.sh — Suite du socle manifeste de pose (Phase 31, vague TRACER, MANI-01/D-31-01/02/03).
#
# Fixture : software-architecture (SKILL.md racine, Type 1 — le SEUL site câblé à ce stade).
# Aucun sous-processus de régime C dans cette fixture (pas d'AGENT.md, pas d'agents/, pas de
# scripts/seed-registres.sh ni scripts/ensure-design-deps.sh) — même fixture que 31-04 (MANI-02).
#
# T1 — après install software-architecture (scope project, lab neuf), le manifeste
#      .claude/scripts/.vibeflow-manifest-software-architecture existe et contient au moins la
#      ligne skills/software-architecture/SKILL.md (D-31-01).
# T2 — aucune ligne du manifeste ne se termine par une barre oblique (grain fichier, D-31-02).
# T3 — aucune ligne du manifeste ne commence par une barre oblique (zéro chemin absolu, D-31-02).
# T4 — le manifeste est trié LC_ALL=C et sans doublon (LC_ALL=C sort -u == fichier, D-31-02).
# T5 — le manifeste ne contient aucune entrée de la liste close d'exclusions D-31-03 (ni
#      scripts/vf-portable.sh, ni scripts/.vibeflow-installed, ni une ligne
#      scripts/.vibeflow-manifest-…).
# T0 — anti-vert-à-vide (contrat F13) : la suite compte ses propres assertions exécutées et
#      échoue si le total (pass+fail) est 0.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), garde stricte mais jamais -e (la
# suite doit compter ses KO, pas avorter dessus), exit 1 si au moins un KO, exit 1 si
# pass+fail == 0. Calqué sur test-vibeflow-update.sh.

set -uo pipefail

# Racines (test sous _internal/tests/ → engine et modules sous _internal/.. = REPO).
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible à l'alias zsh (ugrep) : on force le binaire système.
GREP="$(command -v grep)"

echo "== test-manifest (engine: $INSTALLER) =="

# Helper : prépare un cache de test avec un module copié depuis le repo.
prepare_module() {
  local cache="$1" mod="$2"
  mkdir -p "$cache/$mod"
  cp -r "$REPO/$mod/." "$cache/$mod/" 2>/dev/null || return 1
  [ -f "$cache/$mod/VERSION" ] || return 1
  return 0
}

# ---------------------------------------------------------------------------
# T1-T5 : install software-architecture dans un lab neuf, un seul manifeste vérifié
# sous 5 angles distincts.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "software-architecture"; then
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install software-architecture >/dev/null 2>&1)
  MANIFEST="$LAB/.claude/scripts/.vibeflow-manifest-software-architecture"

  # T1 — présence + contenu minimal
  if [ -f "$MANIFEST" ] && "$GREP" -qF 'skills/software-architecture/SKILL.md' "$MANIFEST"; then
    ok "T1 : manifeste présent, contient skills/software-architecture/SKILL.md"
  else
    ko "T1 : manifeste absent ou ne contient pas skills/software-architecture/SKILL.md ($MANIFEST)"
  fi

  # T2 — aucune ligne de type répertoire (terminée par /)
  if [ ! -f "$MANIFEST" ]; then
    ko "T2 : manifeste absent, ligne répertoire non vérifiable"
  elif "$GREP" -qE '/$' "$MANIFEST"; then
    ko "T2 : au moins une ligne du manifeste se termine par une barre oblique (ligne répertoire)"
  else
    ok "T2 : aucune ligne du manifeste ne se termine par une barre oblique"
  fi

  # T3 — zéro chemin absolu
  if [ ! -f "$MANIFEST" ]; then
    ko "T3 : manifeste absent, chemin absolu non vérifiable"
  elif "$GREP" -qE '^/' "$MANIFEST"; then
    ko "T3 : au moins une ligne du manifeste commence par une barre oblique (chemin absolu)"
  else
    ok "T3 : aucune ligne du manifeste ne commence par une barre oblique"
  fi

  # T4 — trié LC_ALL=C, sans doublon
  if [ -f "$MANIFEST" ]; then
    SORTED="$(LC_ALL=C sort -u "$MANIFEST")"
    RAW="$(cat "$MANIFEST")"
    if [ "$SORTED" = "$RAW" ]; then
      ok "T4 : manifeste trié LC_ALL=C, sans doublon"
    else
      ko "T4 : manifeste NON trié ou avec doublon(s) — LC_ALL=C sort -u diverge du fichier"
    fi
  else
    ko "T4 : manifeste absent, tri non vérifiable"
  fi

  # T5 — aucune entrée de la liste close d'exclusions D-31-03
  if [ ! -f "$MANIFEST" ]; then
    ko "T5 : manifeste absent, exclusions D-31-03 non vérifiables"
  elif "$GREP" -qE '^(scripts/vf-portable\.sh|scripts/\.vibeflow-installed|scripts/\.vibeflow-manifest-)' "$MANIFEST"; then
    ko "T5 : le manifeste contient une entrée de la liste close d'exclusions D-31-03"
  else
    ok "T5 : aucune entrée de la liste close d'exclusions D-31-03 dans le manifeste"
  fi
else
  skip "T1-T5 : software-architecture non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T0 — anti-vert-à-vide (contrat F13) : la suite doit compter au moins une assertion.
# ---------------------------------------------------------------------------
if [ "$((pass + fail))" -eq 0 ]; then
  echo "== ANTI-VERT-À-VIDE : aucune assertion exécutée (pass+fail=0) =="
  exit 1
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
