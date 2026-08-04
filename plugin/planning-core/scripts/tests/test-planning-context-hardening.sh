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

echo "=== planning-context.sh — workstreams GSD (GSDA-14) ==="
# Fixture lab MONO partitionné : STATE.md à la racine ET dans workstreams/dev/, contenus disjoints.
WSM="$WORK/wsmono"; mkdir -p "$WSM/.planning/workstreams/dev"
printf 'last_updated: 2026-08-04\n# racine\n- RACINE-SENTINELLE\n' > "$WSM/.planning/STATE.md"
printf 'last_updated: 2026-08-04\n# dev\n- COMPARTIMENT-SENTINELLE\n' > "$WSM/.planning/workstreams/dev/STATE.md"

# W1 — NON-RÉGRESSION : lab mono sans workstream → sortie identique OCTET POUR OCTET à l'existant.
# Référence figée dans le test (pas capturée à chaud) : c'est ce que le script produisait avant
# l'ajout des workstreams, en-tête compris.
out_sans=$( cd "$WSM" && env -u GSD_WORKSTREAM -u VF_CONTEXT_WORKSTREAM "$BASH_BIN" "$PC" 2>/dev/null ); code=$?
printf '## 📍 Contexte planning (injecté — STATE.md, extrait borné)\n\nÉtat courant du lab (45 premières lignes sur 3 — lis le reste à la demande) :\n\n```\nlast_updated: 2026-08-04\n# racine\n- RACINE-SENTINELLE\n```\n' > "$WORK/w1.expected"
printf '%s\n' "$out_sans" > "$WORK/w1.actual"
if [ "$code" -eq 0 ] && cmp -s "$WORK/w1.expected" "$WORK/w1.actual"; then
  ok "W1 non-régression — lab mono sans workstream : sortie identique octet pour octet (exit 0)"
else
  ko "W1 non-régression lab mono (exit=$code) — sortie divergente de la référence figée"
fi

# W2 — GSD_WORKSTREAM posée → l'extrait vient du compartiment ET l'en-tête le NOMME.
out=$( cd "$WSM" && GSD_WORKSTREAM=dev "$BASH_BIN" "$PC" 2>/dev/null ); code=$?
has   "$out" "COMPARTIMENT-SENTINELLE" "W2 GSD_WORKSTREAM=dev → l'extrait vient du STATE.md du compartiment"
hasnt "$out" "RACINE-SENTINELLE"       "W2b l'extrait de la racine n'est PAS injecté à sa place"
has   "$out" "workstream .dev."        "W2c l'en-tête d'injection NOMME le workstream (pas d'injection muette)"
[ "$code" -eq 0 ] && ok "W2d fail-open intact sous workstream (exit 0)" || ko "W2d exit=$code sous workstream"

# W2e — DISCRIMINATION MACHINE : même fixture, seul l'environnement change.
if [ "$out" != "$out_sans" ]; then
  ok "W2e discrimination machine — même fixture, sortie(avec ws) != sortie(sans ws)"
else
  ko "W2e discrimination machine — la variable n'a rien changé"
fi

# W3 — Pointeur partagé in-repo → même résolution que la variable.
printf 'dev\n' > "$WSM/.planning/active-workstream"
out=$( cd "$WSM" && env -u GSD_WORKSTREAM -u VF_CONTEXT_WORKSTREAM "$BASH_BIN" "$PC" 2>/dev/null )
has "$out" "COMPARTIMENT-SENTINELLE" "W3 pointeur .planning/active-workstream → même résolution"
rm -f "$WSM/.planning/active-workstream"

# W4 — Workstream résolu SANS STATE.md → repli racine + ligne qui le NOMME, exit 0.
out=$( cd "$WSM" && GSD_WORKSTREAM=fantome "$BASH_BIN" "$PC" 2>/dev/null ); code=$?
has "$out" "RACINE-SENTINELLE" "W4 workstream sans STATE.md → repli sur l'extrait de la racine"
has "$out" "fantome"           "W4b la ligne de signalement NOMME le workstream non résolu"
[ "$code" -eq 0 ] && ok "W4c fail-open intact — repli signalé, exit 0" || ko "W4c exit=$code (fail-open rompu)"

# W5 — Nom hors politique : jamais concaténé. `../workstreams/dev` se résoudrait VRAIMENT vers le
# compartiment existant si la validation sautait — c'est le cas discriminant de T-24-04-01.
out=$( cd "$WSM" && GSD_WORKSTREAM='../workstreams/dev' "$BASH_BIN" "$PC" 2>/dev/null ); code=$?
hasnt "$out" "COMPARTIMENT-SENTINELLE" "W5 traversée résolvable rejetée — le compartiment n'est PAS atteint"
has   "$out" "RACINE-SENTINELLE"       "W5b repli sur la racine"
[ "$code" -eq 0 ] && ok "W5c fail-open intact sur nom invalide (exit 0)" || ko "W5c exit=$code sur nom invalide"

# W6 — Lab À COMPARTIMENTS : le régime INDEX est INCHANGÉ, workstream posé ou non (cmp -s).
WSI="$WORK/wsindex"; mkdir -p "$WSI/.planning/workstreams/dev"
printf '# INDEX\n| compartiment-a | actif |\n' > "$WSI/.planning/INDEX.md"
printf 'last_updated: 2026-08-04\n# racine\n- RACINE-SENTINELLE\n' > "$WSI/.planning/STATE.md"
printf 'last_updated: 2026-08-04\n# dev\n- COMPARTIMENT-SENTINELLE\n' > "$WSI/.planning/workstreams/dev/STATE.md"
( cd "$WSI" && env -u GSD_WORKSTREAM -u VF_CONTEXT_WORKSTREAM "$BASH_BIN" "$PC" 2>/dev/null ) > "$WORK/w6.sans"
( cd "$WSI" && GSD_WORKSTREAM=dev "$BASH_BIN" "$PC" 2>/dev/null ) > "$WORK/w6.avec"; code=$?
if cmp -s "$WORK/w6.sans" "$WORK/w6.avec" && grep -q 'compartiment-a' "$WORK/w6.avec" && ! grep -q 'COMPARTIMENT-SENTINELLE' "$WORK/w6.avec"; then
  ok "W6 lab à compartiments — régime INDEX identique avec et sans GSD_WORKSTREAM (cmp -s)"
else
  ko "W6 lab à compartiments — le régime INDEX a bougé sous GSD_WORKSTREAM"
fi
[ "$code" -eq 0 ] && ok "W6b régime INDEX sous workstream — exit 0" || ko "W6b exit=$code"

# W6c — ORDRE DU BLOC : la seule sortie que le régime INDEX pourrait laisser fuir est la LIGNE DE
# SIGNALEMENT (W6 ne l'exerce pas : son workstream se résout, donc rien n'est émis). Un workstream
# NON résolu dans un lab à compartiments doit rester sans effet — si le bloc de résolution remontait
# avant la branche INDEX, la note fuiterait dans l'injection d'INDEX. Cas discriminant de l'ordre.
( cd "$WSI" && GSD_WORKSTREAM=fantome "$BASH_BIN" "$PC" 2>/dev/null ) > "$WORK/w6c.avec"; code=$?
if cmp -s "$WORK/w6.sans" "$WORK/w6c.avec"; then
  ok "W6c régime INDEX — workstream NON résolu : aucune ligne de signalement ne fuit (cmp -s)"
else
  ko "W6c régime INDEX pollué par un workstream non résolu (bloc remonté avant la branche INDEX ?)"
fi
( cd "$WSI" && GSD_WORKSTREAM='../workstreams/dev' "$BASH_BIN" "$PC" 2>/dev/null ) > "$WORK/w6d.avec"
if cmp -s "$WORK/w6.sans" "$WORK/w6d.avec"; then
  ok "W6d régime INDEX — nom hors politique : aucune note ne fuit non plus (cmp -s)"
else
  ko "W6d régime INDEX pollué par un nom de workstream invalide"
fi
[ "$code" -eq 0 ] && ok "W6e régime INDEX, workstream non résolu — exit 0" || ko "W6e exit=$code"

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
