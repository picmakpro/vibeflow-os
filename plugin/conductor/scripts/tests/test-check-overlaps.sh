#!/usr/bin/env bash
# test-check-overlaps.sh — Suite du détecteur de recouvrements avec les briques tierces (ADR-057).
#
# check-overlaps.sh :
#   T1  — gsd-debug local + superpowers:systematic-debugging installé → frontière affichée, exit 0
#   T2  — un seul côté présent (gsd-debug seul) → paire non affichée, exit 0
#   T3  — mobile-test + gsd-verify-work locaux → frontière affichée
#   T4  — gsd-code-review local → paire native /code-review (toujours présente) affichée
#   T5  — agent skill-creator + superpowers:writing-skills installé → frontière affichée
#   T6  — recouvrement inconnu (foo-debug + bar-debug) en défaut → advisory : ⚠ + exit 0
#   T7  — recouvrement inconnu en --strict → exit 1
#   T8  — --strict avec uniquement des paires connues → exit 0
#   T9  — F13 : --strict sur cible locale vide → exit 3 (INDÉTERMINÉ)
#   T10 — F13 : --strict --allow-empty sur cible vide → exit 0 (opt-in)
#   T11 — défaut sur cible vide → exit 0 (rien à inventorier)
#   T12 — compagnons d'un même module (skill-creator + skill-creator-workflow) → PAS un recouvrement
#   T13 — wrappers vf-* exclus de l'heuristique (vf-debug + gsd-debug → pas de ⚠)
#   T14 — paires intra-famille (gsd-code-review + gsd-review) → PAS un recouvrement tierce
#   T15 — les 3 frontières mempalace/gsd-next (ADR-057) : les deux côtés présents → affichées
#   T16 — un seul côté présent pour chaque paire mempalace/gsd-next → aucune frontière affichée

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
CHECK="$SCRIPTS_DIR/check-overlaps.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-check-overlaps (détecteur: $CHECK) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
SK="$WORK/skills"; AG="$WORK/agents"; USK="$WORK/user-skills"; PLUG="$WORK/plugins-cache"

skill() { # $1 = dossier du skill (sandbox projet)
  mkdir -p "$SK/$1"
  printf -- '---\nname: %s\ndescription: sandbox\n---\ncorps\n' "$1" > "$SK/$1/SKILL.md"
}
user_skill() { # $1 = dossier du skill (sandbox user — côté GSD, gsd-* installés globalement)
  mkdir -p "$USK/$1"
  printf -- '---\nname: %s\ndescription: sandbox\n---\ncorps\n' "$1" > "$USK/$1/SKILL.md"
}
agent() { # $1 = nom de l'agent (sandbox projet)
  printf -- '---\nname: %s\ndescription: sandbox\n---\ncorps\n' "$1" > "$AG/$1.md"
}
plugin_skill() { # $1 = plugin · $2 = skill
  mkdir -p "$PLUG/mkt/$1/1.0.0/skills/$2"
  printf -- '---\nname: %s\n---\ncorps\n' "$2" > "$PLUG/mkt/$1/1.0.0/skills/$2/SKILL.md"
}
run_check() {
  bash "$CHECK" --skills-dir="$SK" --agents-dir="$AG" --user-skills-dir="$USK" --plugins-dir="$PLUG" "$@"
}
reset_all() { rm -rf "$SK" "$AG" "$USK" "$PLUG"; mkdir -p "$SK" "$AG" "$USK" "$PLUG"; }

# T1 — les deux côtés présents → frontière affichée
reset_all
skill "gsd-debug"
plugin_skill "superpowers" "systematic-debugging"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "état de debug persistant cross-session"; then
  ok "T1 gsd-debug ↔ systematic-debugging présents → frontière affichée, exit 0"
else
  ko "T1 (rc=$RC) : $OUT"
fi

# T2 — un seul côté présent → paire non affichée
reset_all
skill "gsd-debug"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && ! echo "$OUT" | grep -q "systematic-debugging"; then
  ok "T2 un seul côté présent → paire non affichée"
else
  ko "T2 (rc=$RC) : $OUT"
fi

# T3 — mobile-test + gsd-verify-work locaux
reset_all
skill "mobile-test"
skill "gsd-verify-work"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "recette conversationnelle"; then
  ok "T3 mobile-test ↔ gsd-verify-work → frontière affichée"
else
  ko "T3 (rc=$RC) : $OUT"
fi

# T4 — paire native : /code-review est toujours présent côté tierce
reset_all
skill "gsd-code-review"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "/code-review natif"; then
  ok "T4 gsd-code-review ↔ /code-review natif (toujours présent) → frontière affichée"
else
  ko "T4 (rc=$RC) : $OUT"
fi

# T5 — brique VibeFlow détectée comme AGENT + plugin tiers
reset_all
printf -- '---\nname: skill-creator\ndescription: sandbox\n---\ncorps\n' > "$AG/skill-creator.md"
plugin_skill "superpowers" "writing-skills"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "doctrine d'écriture"; then
  ok "T5 agent skill-creator ↔ superpowers:writing-skills → frontière affichée"
else
  ko "T5 (rc=$RC) : $OUT"
fi

# T6 — recouvrement inconnu en défaut → advisory (⚠ + exit 0)
reset_all
skill "foo-debug"
skill "bar-debug"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "recouvrement NON documenté"; then
  ok "T6 recouvrement inconnu en défaut → ⚠ advisory, exit 0"
else
  ko "T6 (rc=$RC) : $OUT"
fi

# T7 — recouvrement inconnu en --strict → exit 1
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] && ok "T7 recouvrement inconnu en --strict → exit 1" || ko "T7 attendu 1, obtenu rc=$RC"

# T8 — --strict avec uniquement des paires connues → exit 0
reset_all
skill "gsd-debug"
plugin_skill "superpowers" "systematic-debugging"
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T8 --strict sur paires connues seulement → exit 0" || ko "T8 attendu 0, obtenu rc=$RC"

# T9 — F13 : --strict sur cible locale vide → exit 3
reset_all
RC=0; run_check --strict >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 3 ] && ok "T9 --strict + cible vide → exit 3 INDÉTERMINÉ (F13)" || ko "T9 attendu 3, obtenu rc=$RC"

# T10 — F13 : --strict --allow-empty → exit 0 (opt-in explicite)
RC=0; run_check --strict --allow-empty >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "T10 --strict --allow-empty + cible vide → exit 0 (opt-in)" || ko "T10 attendu 0, obtenu rc=$RC"

# T11 — défaut sur cible vide → exit 0
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "rien à inventorier"; then
  ok "T11 défaut + cible vide → exit 0 (rien à inventorier)"
else
  ko "T11 (rc=$RC) : $OUT"
fi

# T12 — compagnons d'un même module : pas un recouvrement (un nom contient l'autre)
reset_all
skill "skill-creator"
skill "skill-creator-workflow"
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ $RC -eq 0 ] && ! echo "$OUT" | grep -q "recouvrement NON documenté"; then
  ok "T12 skill-creator + skill-creator-workflow → pas un recouvrement"
else
  ko "T12 (rc=$RC) : $OUT"
fi

# T13 — wrappers vf-* exclus de l'heuristique
reset_all
skill "vf-debug"
skill "gsd-debug"
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ $RC -eq 0 ] && ! echo "$OUT" | grep -q "recouvrement NON documenté"; then
  ok "T13 vf-debug + gsd-debug → vf-* exclu de l'heuristique, exit 0"
else
  ko "T13 (rc=$RC) : $OUT"
fi

# T14 — intra-famille : deux gsd-* sur la même racine ne sont pas un recouvrement tierce
reset_all
skill "gsd-code-review"
skill "gsd-ui-review"
OUT="$(run_check --strict 2>&1)"; RC=$?
if [ $RC -eq 0 ] && ! echo "$OUT" | grep -q "recouvrement NON documenté"; then
  ok "T14 gsd-code-review + gsd-ui-review → intra-famille, pas un recouvrement tierce"
else
  ko "T14 (rc=$RC) : $OUT"
fi

# T15 — les 3 frontières mempalace/gsd-next (ADR-057) : les deux côtés présents → affichées
reset_all
skill "consolidator"
agent "vibeflow-dev"
user_skill "gsd-mempalace-capture"
user_skill "gsd-mempalace-recall"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
c1=$(echo "$OUT" | grep -c "gsd-mempalace-capture")
c2=$(echo "$OUT" | grep -c "gsd-mempalace-recall")
c3=$(echo "$OUT" | grep -c "gsd-next")
if [ $RC -eq 0 ] && [ "$c1" -ge 1 ] && [ "$c2" -ge 1 ] && [ "$c3" -ge 1 ]; then
  ok "T15 consolidator/vibeflow-dev ↔ mempalace/gsd-next (deux côtés présents) → 3 frontières affichées"
else
  ko "T15 (rc=$RC, capture=$c1, recall=$c2, next=$c3) : $OUT"
fi

# T16 — un seul côté présent pour chaque paire mempalace/gsd-next → aucune frontière affichée
reset_all
skill "consolidator"
agent "vibeflow-dev"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && ! echo "$OUT" | grep -q "gsd-mempalace-capture" \
   && ! echo "$OUT" | grep -q "gsd-mempalace-recall" \
   && ! echo "$OUT" | grep -q "gsd-next"; then
  ok "T16 un seul côté présent (VibeFlow seul, GSD absent) → aucune des 3 frontières affichée"
else
  ko "T16 (rc=$RC) : $OUT"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
