#!/usr/bin/env bash
# test-planning-context-hardening.sh — Durcissement des hooks de contexte planning :
#   PLN-04 : planning-context.sh — argument sans valeur → erreur immédiate (plus de boucle infinie)
#   PLN-05 : planning-context.sh — troncature de l'INDEX signalée (comme le chemin mono STATE)
#   PLN-02 : planning-task-context.sh — globs BORNÉS (jamais ** récursif, compartiments aux 2 profondeurs)
#   PLN-03 : planning-task-context.sh — matching par frontière de mot, priorités, ambiguïté → silence
# Lancer avec BASH_BIN=/bin/bash pour valider la portabilité bash 3.2 macOS.
set -u

SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
BASH_BIN="${BASH_BIN:-bash}"
PC="$SCRIPTS/planning-context.sh"
PT="$SCRIPTS/planning-task-context.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
ok()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
ko()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
has()  { echo "$1" | grep -q "$2" && ok "$3" || ko "$3"; }
hasnt(){ echo "$1" | grep -q "$2" && ko "$3" || ok "$3"; }

# timeout portable : macOS n'a pas timeout(1) de base → repli perl (le timer alarm survit à exec).
with_timeout() { # <secondes> <cmd...>
  if command -v timeout >/dev/null 2>&1; then timeout "$@"; else perl -e 'alarm shift; exec @ARGV' "$@"; fi
}
ask() { # <prompt> — joue le hook UserPromptSubmit depuis le répertoire courant
  printf '{"prompt":"%s"}' "$1" | "$BASH_BIN" "$PT"
}

echo "=== planning-context.sh — arguments (PLN-04) ==="
# H1 : --path sans valeur → erreur IMMÉDIATE, pas de boucle (avant fix : gel jusqu'au timeout du hook)
with_timeout 5 "$BASH_BIN" "$PC" --path >/dev/null 2>&1; code=$?
if [ "$code" -ne 0 ] && [ "$code" -ne 124 ] && [ "$code" -ne 142 ]; then
  ok "H1 --path sans valeur → erreur immédiate (exit=$code)"
else
  ko "H1 --path sans valeur (exit=$code — 124/142 = boucle tuée par le timeout)"
fi
with_timeout 5 "$BASH_BIN" "$PC" --max-lines >/dev/null 2>&1; code=$?
if [ "$code" -ne 0 ] && [ "$code" -ne 124 ] && [ "$code" -ne 142 ]; then
  ok "H1b --max-lines sans valeur → erreur immédiate (exit=$code)"
else
  ko "H1b --max-lines sans valeur (exit=$code)"
fi
# H1c : les invocations légitimes restent intactes (avec valeur / sans argument)
D="$WORK/argok"; mkdir -p "$D/pl"
printf 'last_updated: 2026-07-16\n# S\n- ligne\n' > "$D/pl/STATE.md"
out=$( cd "$D" && "$BASH_BIN" "$PC" --path pl --max-lines 10 )
has "$out" "ligne" "H1c --path/--max-lines avec valeur → fonctionne comme avant"

echo "=== planning-context.sh — troncature INDEX (PLN-05) ==="
BIG="$WORK/big"; mkdir -p "$BIG/.planning"
{ echo "# INDEX"; i=1; while [ $i -le 120 ]; do echo "| comp$i | actif |"; i=$((i+1)); done; } > "$BIG/.planning/INDEX.md"
out=$( cd "$BIG" && "$BASH_BIN" "$PC" )
has   "$out" "tronqué"  "H2 INDEX 121 lignes → troncature signalée"
has   "$out" "INDEX.md" "H2b le signal pointe vers le fichier INDEX.md à lire"
hasnt "$out" "comp120"  "H2c le contenu au-delà de la borne n'est pas injecté"
SMALL="$WORK/small"; mkdir -p "$SMALL/.planning"
printf '# INDEX\n| a | actif |\n' > "$SMALL/.planning/INDEX.md"
out=$( cd "$SMALL" && "$BASH_BIN" "$PC" )
hasnt "$out" "tronqué" "H2d INDEX court → pas de faux signal de troncature"

echo "=== planning-task-context.sh — frontière de mot (PLN-03) ==="
LAB="$WORK/lab"; mkdir -p "$LAB/.planning" "$LAB/projects/formation/.planning" "$LAB/projects/art/.planning"
cd "$LAB"
printf '# INDEX\n| formation | actif |\n| art | actif |\n' > .planning/INDEX.md
printf 'last_updated: 2026-07-16\n# formation\n- module M4\n' > projects/formation/.planning/STATE.md
printf 'last_updated: 2026-07-16\n# art\n- expo photo\n' > projects/art/.planning/STATE.md
out=$(ask "range les informations stp")
[ -z "$out" ] && ok "H3 « informations » ne matche plus « formation » (silence)" || ko "H3 faux positif sous-chaîne : $(echo "$out" | head -1)"
out=$(ask "avance la formation")
has "$out" "formation" "H3b « la formation » → bon compartiment détecté"
has "$out" "module M4" "H3c le STATE du compartiment est injecté"
out=$(ask "le partage des taches")
[ -z "$out" ] && ok "H4 « partage » ne matche plus « art » (frontière de mot + token min 4)" || ko "H4 faux positif : $(echo "$out" | head -1)"
out=$(ask "avance le projet art")
has "$out" "expo photo" "H4b « art » en mot entier → nom court légitime matché"

echo "=== planning-task-context.sh — ambiguïté et priorités (PLN-03) ==="
AMB="$WORK/amb"; mkdir -p "$AMB/.planning" "$AMB/projects/alpha-vente/.planning" "$AMB/projects/beta-vente/.planning"
cd "$AMB"
printf '# INDEX\n' > .planning/INDEX.md
printf '# alpha\n- ALPHA-SECRET\n' > projects/alpha-vente/.planning/STATE.md
printf '# beta\n- BETA-SECRET\n' > projects/beta-vente/.planning/STATE.md
out=$(ask "le process de vente")
[ -z "$out" ] && ok "H5 deux compartiments à égalité de score → silence (fail-open)" || ko "H5 injection arbitraire sur match ambigu : $(echo "$out" | head -1)"
PRI="$WORK/pri"; mkdir -p "$PRI/.planning" "$PRI/projects/formation/.planning" "$PRI/projects/formation-avancee/.planning"
cd "$PRI"
printf '# INDEX\n' > .planning/INDEX.md
printf '# f\n- SOCLE-COMMUN\n' > projects/formation/.planning/STATE.md
printf '# fa\n- NIVEAU-2\n' > projects/formation-avancee/.planning/STATE.md
out=$(ask "ou en est la formation")
has   "$out" "SOCLE-COMMUN" "H6 nom exact prime sur le token (formation ≠ formation-avancee)"
hasnt "$out" "NIVEAU-2"     "H6b le compartiment matché par simple token n'est pas injecté"
out=$(ask "ou en est la formation-avancee")
has "$out" "NIVEAU-2" "H6c nom composé exact → le plus long gagne (déterministe)"

echo "=== planning-task-context.sh — globs bornés (PLN-02) ==="
TOP="$WORK/top"; mkdir -p "$TOP/.planning" "$TOP/croissance/.planning"
cd "$TOP"
printf '# INDEX\n' > .planning/INDEX.md
printf '# c\n- OKR-Q3\n' > croissance/.planning/STATE.md
out=$(ask "plan croissance T3")
has "$out" "OKR-Q3" "H7 compartiment de premier niveau (glob */.planning) découvert"
PERF="$WORK/perf"; mkdir -p "$PERF/.planning" "$PERF/projects/venteperf/.planning"
cd "$PERF"
printf '# INDEX\n' > .planning/INDEX.md
printf '# v\n- pipeline\n' > projects/venteperf/.planning/STATE.md
# node_modules profond : le ** récursif d'avant marchait tout cet arbre À CHAQUE PROMPT
i=1; while [ $i -le 200 ]; do mkdir -p "node_modules/pkg$i/src/lib"; i=$((i+1)); done
out=$(printf '{"prompt":"etat du pipeline venteperf"}' | with_timeout 10 "$BASH_BIN" "$PT"); code=$?
if [ "$code" -eq 0 ]; then ok "H8 prompt traité sans gel malgré node_modules profond (exit=0)"; else ko "H8 exit=$code (124/142 = gel)"; fi
has "$out" "pipeline" "H8b le bon compartiment est toujours servi"
grep -q 'recursive=True' "$PT" && ko "H8c glob ** récursif réintroduit dans planning-task-context.sh" || ok "H8c aucun glob récursif (**) dans le script (tripwire statique)"

echo ""
echo "== résultat : $PASS passés, $FAIL échoués =="
[ "$FAIL" -eq 0 ]
