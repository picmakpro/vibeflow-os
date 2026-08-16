#!/usr/bin/env bash
# test-manifest.sh — Suite du socle manifeste de pose (Phase 31, vague TRACER, MANI-01/D-31-01/02/03).
#
# Fixture : software-architecture (SKILL.md racine, Type 1 — le SEUL site câblé à ce stade).
# Aucun sous-processus de régime C dans cette fixture (pas d'AGENT.md, pas d'agents/, pas de
# scripts/seed-registres.sh ni scripts/ensure-design-deps.sh) — même fixture que 31-04 (MANI-02).
#
# T1 — après install software-architecture (scope project, lab neuf), le manifeste
#      .claude/scripts/.vibeflow-manifest-software-architecture existe et contient la ligne
#      EXACTE skills/software-architecture/SKILL.md (D-31-01). Égalité de ligne (awk), pas
#      sous-chaîne : ".claude/skills/software-architecture/SKILL.md" (chemin NON relativisé, la
#      mutation qui a fait tomber vf_rel_to_target) CONTIENT le chemin correct — un `grep -qF`
#      passerait à tort dessus (B-2, revue vague 1).
# T2 — aucune ligne du manifeste ne se termine par une barre oblique (grain fichier, D-31-02).
# T3 — aucune ligne du manifeste ne commence par une barre oblique (zéro chemin absolu, D-31-02).
#      Scope project SEULEMENT : TARGET_ROOT="./.claude" y est déjà relatif, donc un chemin non
#      relativisé n'y est jamais absolu — cette assertion ne peut PAS rougir sur ce scope seul.
# T3b — même garde en scope `user` (TARGET_ROOT="$HOME/.claude", absolu) : seul scope où une
#      régression de relativisation peut réellement produire une ligne "/…" (B-2, revue vague 1).
# T4 — le manifeste est trié LC_ALL=C et sans doublon (LC_ALL=C sort -u == fichier, D-31-02).
# T4b — même garantie au grain UNITÉ (D-31-12) : source les fonctions, vf_record plusieurs
#      chemins non triés + un doublon, vf_manifest_flush, assère l'ordre/dédup — sans attendre
#      qu'un manifeste multi-lignes existe de bout en bout (31-03). Un manifeste d'UNE ligne
#      rend le tri identitaire : T4 seul ne peut pas rougir sur une mutation qui casse le tri.
# T5 — le manifeste ne contient aucune entrée de la liste close d'exclusions D-31-03 (ni
#      scripts/vf-portable.sh, ni scripts/.vibeflow-installed, ni une ligne
#      scripts/.vibeflow-manifest-…).
# T5b — même liste au grain UNITÉ (D-31-12) : appelle vf_manifest_excluded directement sur les 5
#      motifs (doivent matcher) ET sur des chemins voisins (ne doivent PAS matcher, anti-sur-
#      blocage) — sans site de pose exerçant réellement la liste aujourd'hui, T5 seul est vacant
#      (aucun chemin observé n'atteint la liste, cf. mutation `return 1` restée verte en revue).
# T0 — anti-vert-à-vide (contrat F13) : la suite compte ses propres assertions exécutées et
#      échoue si le total (pass+fail) est 0.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), garde stricte mais jamais -e (la
# suite doit compter ses KO, pas avorter dessus), exit 1 si au moins un KO, exit 1 si
# pass+fail == 0. Calqué sur test-vibeflow-update.sh. T4b/T5b sourcent l'engine dans un
# sous-shell isolé ($(...)) : le sourcing hérite de `set -euo pipefail`, incompatible avec la
# convention "jamais -e" de cette suite — le sous-shell le confine, seul son verdict texte
# ("PASS"/"FAIL:…") en sort, jamais son `set -e`.

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

  # T1 — présence + contenu EXACT (B-2, revue vague 1) : égalité de ligne via awk, pas une
  # sous-chaîne via grep -qF — ".claude/skills/software-architecture/SKILL.md" (mutation qui
  # supprime la relativisation) CONTIENT "skills/software-architecture/SKILL.md" et passerait
  # à tort un test de sous-chaîne.
  if [ -f "$MANIFEST" ] && awk '$0=="skills/software-architecture/SKILL.md"{f=1} END{exit !f}' "$MANIFEST"; then
    ok "T1 : manifeste présent, contient (ligne exacte) skills/software-architecture/SKILL.md"
  else
    ko "T1 : manifeste absent ou ne contient pas la ligne EXACTE skills/software-architecture/SKILL.md ($MANIFEST)"
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
# T3b : scope `user` — TARGET_ROOT absolu ($HOME/.claude). Seul scope où une régression de
# relativisation (vf_rel_to_target cassée) peut réellement produire une ligne absolue dans le
# manifeste ; T3 seul (scope project, TARGET_ROOT="./.claude" déjà relatif) ne peut pas rougir.
# HOME isolé (fakehome) : une seule résolution de HOME à l'exécution (vérifié en revue) suffit.
# ---------------------------------------------------------------------------
LAB_USER="$(mktemp -d)"
FAKEHOME="$LAB_USER/fakehome"
CACHE_USER="$LAB_USER/cache"
mkdir -p "$FAKEHOME"
if prepare_module "$CACHE_USER" "software-architecture"; then
  (cd "$LAB_USER" && HOME="$FAKEHOME" VIBEFLOW_CACHE="$CACHE_USER" bash "$INSTALLER" --scope user install software-architecture >/dev/null 2>&1)
  MANIFEST_USER="$FAKEHOME/.claude/scripts/.vibeflow-manifest-software-architecture"
  if [ ! -f "$MANIFEST_USER" ]; then
    ko "T3b : manifeste absent (scope user), chemin absolu non vérifiable ($MANIFEST_USER)"
  elif "$GREP" -qE '^/' "$MANIFEST_USER"; then
    ko "T3b : au moins une ligne du manifeste (scope user) commence par une barre oblique (chemin absolu)"
  else
    ok "T3b : aucune ligne du manifeste (scope user, TARGET_ROOT absolu) ne commence par une barre oblique"
  fi
else
  skip "T3b : software-architecture non copiable dans le cache de test (scope user)"
fi
rm -rf "$LAB_USER"

# ---------------------------------------------------------------------------
# T4b : tri/dédup au grain UNITÉ (D-31-12) — source les fonctions et les appelle directement,
# sans attendre qu'un site de pose multi-fichiers (31-03) rende l'assertion de bout en bout
# significative. Sous-shell isolé : voir note de convention en tête de fichier.
# ---------------------------------------------------------------------------
T4B_LAB="$(mktemp -d)"
T4B_RESULT="$(
  cd "$T4B_LAB" 2>/dev/null || exit 1
  set -- sync
  # shellcheck disable=SC1090
  source "$INSTALLER" >/dev/null 2>&1
  vf_manifest_reset "unit-mod"
  vf_record "$TARGET_ROOT/skills/zzz/SKILL.md"
  vf_record "$TARGET_ROOT/skills/aaa/SKILL.md"
  vf_record "$TARGET_ROOT/skills/mmm/SKILL.md"
  vf_record "$TARGET_ROOT/skills/aaa/SKILL.md"   # doublon volontaire
  vf_manifest_flush
  manifest_t4b="$(vf_manifest_path "unit-mod")"
  expected="skills/aaa/SKILL.md
skills/mmm/SKILL.md
skills/zzz/SKILL.md"
  if [ -f "$manifest_t4b" ] && [ "$(cat "$manifest_t4b")" = "$expected" ]; then
    echo "PASS"
  else
    echo "FAIL:$(cat "$manifest_t4b" 2>/dev/null | tr '\n' '|')"
  fi
)"
rm -rf "$T4B_LAB"
case "$T4B_RESULT" in
  PASS) ok "T4b : vf_record/vf_manifest_flush trient LC_ALL=C et dédupliquent au grain unité" ;;
  *) ko "T4b : ordre/dédup incorrect au grain unité ($T4B_RESULT)" ;;
esac

# ---------------------------------------------------------------------------
# T5b : liste close D-31-03 au grain UNITÉ (D-31-12) — vf_manifest_excluded appelée directement
# sur les 5 motifs (doivent matcher) ET sur des chemins voisins (garde anti-sur-blocage, ne
# doivent PAS matcher). Aujourd'hui aucun chemin posé par le seul site câblé (SKILL.md racine)
# n'atteint cette liste : T5 seul est vacant (mutation `return 1` restée verte en revue).
# ---------------------------------------------------------------------------
T5B_LAB="$(mktemp -d)"
T5B_RESULT="$(
  cd "$T5B_LAB" 2>/dev/null || exit 1
  set -- sync
  # shellcheck disable=SC1090
  source "$INSTALLER" >/dev/null 2>&1
  fail_list=""
  check_excluded() {
    local path="$1" want="$2" got
    if vf_manifest_excluded "$path"; then got=0; else got=1; fi
    [ "$got" = "$want" ] || fail_list="$fail_list|$path(want=$want,got=$got)"
  }
  # Les 5 motifs D-31-03 : DOIVENT matcher (want=0, exclus du manifeste).
  check_excluded "scripts/vf-portable.sh" 0
  check_excluded "memory/foo.md" 0
  check_excluded "scripts/.vibeflow-installed" 0
  check_excluded "scripts/.vibeflow-manifest-conductor" 0
  check_excluded ".backups/conductor-20260101/skills/x" 0
  # Chemins voisins : ne doivent PAS matcher (want=1, anti-sur-blocage).
  check_excluded "scripts/vf-portable2.sh" 1
  check_excluded "skills/memory/SKILL.md" 1
  check_excluded "scripts/.vibeflow-installedx" 1
  check_excluded "scripts/vibeflow-manifest-conductor" 1
  check_excluded "notbackups/conductor/x" 1
  if [ -z "$fail_list" ]; then
    echo "PASS"
  else
    echo "FAIL:$fail_list"
  fi
)"
rm -rf "$T5B_LAB"
case "$T5B_RESULT" in
  PASS) ok "T5b : vf_manifest_excluded matche les 5 motifs D-31-03 et épargne les chemins voisins" ;;
  *) ko "T5b : $T5B_RESULT" ;;
esac

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
