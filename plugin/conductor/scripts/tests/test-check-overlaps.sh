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
#   T17 — un agent posé sous un nom de fichier différent de son name: incarné (un module Type 3
#         pose son AGENT.md sous agents/<mod>.md, incarné sous un name: distinct, ex. name:
#         vibeflow-head sous agents/dev-orchestrator.md) doit être détecté par ce name:
#   T18 — garde-fou : un agent nommé « vibeflow-head-bis » (name: distinct, préfixe partagé) ne
#         doit PAS satisfaire la référence « vibeflow-head » — correspondance EXACTE requise
#   T19 — garde-fou : une ligne « name: vibeflow-head » dans le CORPS d'un agent (hors
#         frontmatter, sous le second « --- », frontmatter lui-même SANS ligne name:) ne doit
#         PAS compter — seule une valeur DANS le frontmatter fait foi
#   T20 — name: entre guillemets doubles (`name: "vibeflow-head"`), sous un autre nom de fichier
#         → détecté (le guillemet fait partie du YAML valide, pas de la valeur)
#   T21 — name: entre guillemets simples (`name: 'vibeflow-head'`), sous un autre nom de fichier
#         → détecté
#   T22 — fichier ouvert par un BOM UTF-8, sous un autre nom de fichier → détecté (le BOM ne fait
#         pas partie de la première ligne du frontmatter)
#   T23 — fichier en fins de ligne CRLF, sous un autre nom de fichier → détecté (le \r ne fait pas
#         partie de la valeur ni du marqueur ---)
#   T24 — garde de non-régression : un agent posé SOUS son nom de fichier canonique
#         (agents/vibeflow-head.md), name: entre guillemets → toujours détecté par le nom de
#         fichier, indépendamment de la lecture du name:
#   T25 — garde de non-régression : un agent posé SOUS son nom de fichier canonique, SANS aucune
#         ligne name: dans son frontmatter → toujours détecté par le seul nom de fichier

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
agent_named() { # $1 = nom de fichier · $2 = valeur de name: en frontmatter (mismatch possible
                # avec $1 — layout d'un module Type 3, AGENT.md → agents/<mod>.md)
  printf -- '---\nname: %s\ndescription: sandbox\n---\ncorps\n' "$2" > "$AG/$1.md"
}
agent_no_name_body() { # $1 = nom de fichier · $2 = valeur "name:" citée dans le CORPS (hors
                        # frontmatter, qui n'a lui-même AUCUNE ligne name:) — ne doit jamais
                        # compter : sans confinement, un lecteur qui continue après le
                        # frontmatter la trouverait
  printf -- '---\ndescription: sandbox\n---\ncorps\nname: %s\n' "$2" > "$AG/$1.md"
}
agent_named_quoted() { # $1 = nom de fichier · $2 = valeur de name: · $3 = caractère de guillemet
  printf -- '---\nname: %s%s%s\ndescription: sandbox\n---\ncorps\n' "$3" "$2" "$3" > "$AG/$1.md"
}
agent_named_bom() { # $1 = nom de fichier · $2 = valeur de name: — BOM UTF-8 en tête de fichier
  printf -- '\xef\xbb\xbf---\nname: %s\ndescription: sandbox\n---\ncorps\n' "$2" > "$AG/$1.md"
}
agent_named_crlf() { # $1 = nom de fichier · $2 = valeur de name: — fins de ligne CRLF
  printf -- '---\r\nname: %s\r\ndescription: sandbox\r\n---\r\ncorps\r\n' "$2" > "$AG/$1.md"
}
agent_no_name() { # $1 = nom de fichier — frontmatter sans aucune ligne name:
  printf -- '---\ndescription: sandbox\n---\ncorps\n' > "$AG/$1.md"
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
agent "vibeflow-head"
user_skill "gsd-mempalace-capture"
user_skill "gsd-mempalace-recall"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
c1=$(echo "$OUT" | grep -c "gsd-mempalace-capture")
c2=$(echo "$OUT" | grep -c "gsd-mempalace-recall")
c3=$(echo "$OUT" | grep -c "gsd-next")
if [ $RC -eq 0 ] && [ "$c1" -ge 1 ] && [ "$c2" -ge 1 ] && [ "$c3" -ge 1 ]; then
  ok "T15 consolidator/vibeflow-head ↔ mempalace/gsd-next (deux côtés présents) → 3 frontières affichées"
else
  ko "T15 (rc=$RC, capture=$c1, recall=$c2, next=$c3) : $OUT"
fi

# T16 — un seul côté présent pour chaque paire mempalace/gsd-next → aucune frontière affichée
reset_all
skill "consolidator"
agent "vibeflow-head"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && ! echo "$OUT" | grep -q "gsd-mempalace-capture" \
   && ! echo "$OUT" | grep -q "gsd-mempalace-recall" \
   && ! echo "$OUT" | grep -q "gsd-next"; then
  ok "T16 un seul côté présent (VibeFlow seul, GSD absent) → aucune des 3 frontières affichée"
else
  ko "T16 (rc=$RC) : $OUT"
fi

# T17 — agent posé sous un nom de fichier différent de son name: incarné → détecté par ce name:
reset_all
agent_named "dev-orchestrator" "vibeflow-head"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "↔ vibeflow-head ↔ gsd-next"; then
  ok "T17 agents/dev-orchestrator.md (name: vibeflow-head) ↔ gsd-next → frontière affichée"
else
  ko "T17 (rc=$RC) : $OUT"
fi

# T18 — garde-fou : correspondance EXACTE du name:, pas un préfixe partagé. Un agent
# « vibeflow-head-bis » ne doit jamais satisfaire la référence « vibeflow-head ».
reset_all
agent "vibeflow-head-bis"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && ! echo "$OUT" | grep -q "vibeflow-head ↔ gsd-next"; then
  ok "T18 vibeflow-head-bis ↔ gsd-next → pas de correspondance (name exact requis)"
else
  ko "T18 (rc=$RC) : $OUT"
fi

# T19 — garde-fou : une ligne "name:" dans le CORPS (hors frontmatter, qui n'a lui-même aucune
# ligne name:) ne doit jamais compter — seule une valeur DANS le frontmatter fait foi.
reset_all
agent_no_name_body "readme-agent" "vibeflow-head"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && ! echo "$OUT" | grep -q "vibeflow-head ↔ gsd-next"; then
  ok "T19 name: dans le corps (hors frontmatter) → ignoré, pas de correspondance"
else
  ko "T19 (rc=$RC) : $OUT"
fi

# T20 — name: entre guillemets doubles, sous un autre nom de fichier → détecté
reset_all
agent_named_quoted "dev-orchestrator-dq" "vibeflow-head" '"'
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "vibeflow-head ↔ gsd-next"; then
  ok "T20 name: \"vibeflow-head\" (guillemets doubles) ↔ gsd-next → frontière affichée"
else
  ko "T20 (rc=$RC) : $OUT"
fi

# T21 — name: entre guillemets simples, sous un autre nom de fichier → détecté
reset_all
agent_named_quoted "dev-orchestrator-sq" "vibeflow-head" "'"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "vibeflow-head ↔ gsd-next"; then
  ok "T21 name: 'vibeflow-head' (guillemets simples) ↔ gsd-next → frontière affichée"
else
  ko "T21 (rc=$RC) : $OUT"
fi

# T22 — fichier ouvert par un BOM UTF-8, sous un autre nom de fichier → détecté
reset_all
agent_named_bom "dev-orchestrator-bom" "vibeflow-head"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "vibeflow-head ↔ gsd-next"; then
  ok "T22 fichier ouvert par un BOM UTF-8 ↔ gsd-next → frontière affichée"
else
  ko "T22 (rc=$RC) : $OUT"
fi

# T23 — fichier en fins de ligne CRLF, sous un autre nom de fichier → détecté
reset_all
agent_named_crlf "dev-orchestrator-crlf" "vibeflow-head"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "vibeflow-head ↔ gsd-next"; then
  ok "T23 fichier en fins de ligne CRLF ↔ gsd-next → frontière affichée"
else
  ko "T23 (rc=$RC) : $OUT"
fi

# T24 — garde de non-régression : posé SOUS son nom de fichier canonique, name: entre guillemets
# → toujours détecté par le nom de fichier, indépendamment de la lecture du name:
reset_all
agent_named_quoted "vibeflow-head" "vibeflow-head" '"'
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "vibeflow-head ↔ gsd-next"; then
  ok "T24 agents/vibeflow-head.md (name: \"vibeflow-head\") ↔ gsd-next → frontière affichée"
else
  ko "T24 (rc=$RC) : $OUT"
fi

# T25 — garde de non-régression : posé SOUS son nom de fichier canonique, SANS aucune ligne
# name: → toujours détecté par le seul nom de fichier
reset_all
agent_no_name "vibeflow-head"
user_skill "gsd-next"
OUT="$(run_check 2>&1)"; RC=$?
if [ $RC -eq 0 ] && echo "$OUT" | grep -q "vibeflow-head ↔ gsd-next"; then
  ok "T25 agents/vibeflow-head.md (sans name:) ↔ gsd-next → frontière affichée"
else
  ko "T25 (rc=$RC) : $OUT"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
