#!/usr/bin/env bash
# test-gsd-run.sh — Suite dédiée de gsd-run.sh (issue #47), boîte noire, hermétique.
#
# Hermétisme : tout vit sous un `mktemp -d` détruit par trap ; HOME factice ; `env -i` à chaque
# appel (jamais d'héritage de GSD_TOOLS / CLAUDE_CONFIG_DIR de la machine de l'exécutant) ; le
# moteur est un FAUX gsd-tools.cjs qui journalise son argv (JSON) et sort avec $FAKE_RC. Aucun
# vrai moteur n'est touché, aucune écriture hors du tmp.
#
# Cas : (a) résolution scope projet + argv transmis à l'identique (dont un argument avec espace) ;
# (b) rien de résoluble OU node absent → 64 + message ; (c) précédence projet > user ; (d)
# GSD_TOOLS existant prime, GSD_TOOLS inexistant ignoré ; (e) sentinelle ADR-070 : un
# <lab>/gsd-core/bin/gsd-tools.cjs NU n'est JAMAIS exécuté ; (f) `gsd-tools` du PATH, en dernier
# (et après le scope user) ; (g) rc de l'outil propagé ; (h) bash -n.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/gsd-run.sh"
[ -n "${GSD_RUN_UNDER_TEST:-}" ] && SCRIPT="$GSD_RUN_UNDER_TEST"   # mutants (preuve de rouge)

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — attendu [$2] obtenu [$3]"; FAIL=$((FAIL+1)); }
eq() { if [ "$3" = "$2" ]; then ok "$1"; else ko "$1" "$2" "$3"; fi; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
BASH_BIN="$(command -v bash)"
NODE_BIN="$(command -v node || true)"
[ -n "$NODE_BIN" ] || { echo "  ✗ node absent de la machine d'exécution — suite non jouable"; exit 1; }

# Faux moteur (script node) : journalise l'argv + son propre chemin, sort avec $FAKE_RC.
mk_engine() { # <chemin gsd-tools.cjs> <étiquette>
  mkdir -p "$(dirname "$1")"
  {
    printf '%s\n' "const fs = require('fs');"
    printf '%s\n' "fs.appendFileSync(process.env.FAKE_LOG, JSON.stringify(['$2'].concat(process.argv.slice(2))) + '\n');"
    printf '%s\n' "process.exit(parseInt(process.env.FAKE_RC || '0', 10));"
  } > "$1"
}

# Dossier PATH ne contenant que node (lien).
ONLYNODE="$TMP/path-only-node"; mkdir -p "$ONLYNODE"; ln -s "$NODE_BIN" "$ONLYNODE/node"

new_lab() { # <nom> → crée <lab>/ et <home>/ vides ; imprime rien (variables LAB / HOME_T)
  LAB="$TMP/$1/lab"; HOME_T="$TMP/$1/home"; LOG="$TMP/$1/log"
  mkdir -p "$LAB" "$HOME_T"; : > "$LOG"
}

# run <path> [VAR=val ...] -- <args…> : exécute le script, cwd = $LAB, environnement vidé.
OUT=""; RC=0
run() {
  local p="$1"; shift
  local envs=()
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  [ "${1:-}" = "--" ] && shift
  OUT="$(cd "$LAB" && env -i HOME="$HOME_T" PATH="$p" FAKE_LOG="$LOG" ${envs[@]+"${envs[@]}"} \
    "$BASH_BIN" "$SCRIPT" "$@" 2>&1)"; RC=$?
}
last() { tail -n 1 "$LOG"; }
count() { wc -l < "$LOG" | tr -d ' '; }

echo "== test-gsd-run.sh =="

# (a) moteur en scope PROJET, argv transmis à l'identique
new_lab a; mk_engine "$LAB/.claude/gsd-core/bin/gsd-tools.cjs" proj
run "$ONLYNODE" -- config-set workflow.x "a b" --ws fiab
eq "a: rc 0 propagé"                  "0" "$RC"
eq "a: moteur PROJET résolu, argv identique (argument avec espace, --ws)" \
   '["proj","config-set","workflow.x","a b","--ws","fiab"]' "$(last)"

# (b) rien de résoluble → 64 + message ; node absent → 64
new_lab b
run "$ONLYNODE" -- config-get workflow.x
eq "b: aucun candidat → rc 64"        "64" "$RC"
case "$OUT" in *"gsd-tools.cjs"*"@opengsd/gsd-core"*) ok "b: message stderr nomme les candidats et la commande d'install";; *) ko "b: message" "candidats + npx @opengsd/gsd-core" "$OUT";; esac
new_lab b2; mk_engine "$LAB/.claude/gsd-core/bin/gsd-tools.cjs" proj
EMPTY="$TMP/path-empty"; mkdir -p "$EMPTY"
run "$EMPTY" -- config-get workflow.x
eq "b: node absent → rc 64 (moteur pourtant présent)" "64" "$RC"
eq "b: node absent → le moteur n'a pas tourné" "0" "$(count)"
case "$OUT" in *node*) ok "b: node absent → message nomme node";; *) ko "b: message node" "node" "$OUT";; esac

# (b2) HOME ET CLAUDE_CONFIG_DIR absents (aucun HOME exporté) : 64, jamais le rc 1 de `set -u`
new_lab b3
OUT="$(cd "$LAB" && env -i PATH="$ONLYNODE" FAKE_LOG="$LOG" "$BASH_BIN" "$SCRIPT" config-get x 2>&1 </dev/null)"; RC=$?
eq "b: HOME et CLAUDE_CONFIG_DIR absents → rc 64 (pas le rc 1 de set -u)" "64" "$RC"
case "$OUT" in *"défaut d'outillage"*) ok "b: HOME absent → message défaut d'outillage";; *) ko "b: message HOME absent" "défaut d'outillage" "$OUT";; esac
case "$OUT" in *"scope user non résolu"*) ok "b: HOME absent → la note « scope user non résolu » est émise";; *) ko "b: note scope user" "scope user non résolu" "$OUT";; esac
case "$OUT" in *" /.claude/"*) ko "b: HOME absent" "aucun candidat /.claude/ à la racine dans la sortie" "$OUT";; *) ok "b: HOME absent → aucun candidat /.claude/ à la racine dans la sortie (le ./.claude/ du projet reste)";; esac
OUT="$(cd "$LAB" && env -i HOME= PATH="$ONLYNODE" FAKE_LOG="$LOG" "$BASH_BIN" "$SCRIPT" config-get x 2>&1 </dev/null)"; RC=$?
eq "b: HOME vide → rc 64, aucun candidat /.claude à la racine" "64" "$RC"
case "$OUT" in *"Candidats essayés : "*" /.claude/"*|*", /.claude/"*) ko "b: HOME vide" "pas de candidat /.claude/..." "$OUT";; *) ok "b: HOME vide → pas de candidat /.claude/...";; esac

# (c) précédence projet > user
new_lab c; mk_engine "$LAB/.claude/gsd-core/bin/gsd-tools.cjs" proj; mk_engine "$HOME_T/.claude/gsd-core/bin/gsd-tools.cjs" user
run "$ONLYNODE" -- ping
eq "c: projet ET user présents → le PROJET tourne" '["proj","ping"]' "$(last)"
new_lab c2; mk_engine "$HOME_T/.claude/gsd-core/bin/gsd-tools.cjs" user
run "$ONLYNODE" -- ping
eq "c: user seul → résolu via \$HOME/.claude"       '["user","ping"]' "$(last)"
new_lab c3; mk_engine "$TMP/c3/cfg/gsd-core/bin/gsd-tools.cjs" cfg; mk_engine "$HOME_T/.claude/gsd-core/bin/gsd-tools.cjs" user
run "$ONLYNODE" CLAUDE_CONFIG_DIR="$TMP/c3/cfg" -- ping
eq "c: CLAUDE_CONFIG_DIR prime sur \$HOME/.claude"  '["cfg","ping"]' "$(last)"

# (d) GSD_TOOLS
new_lab d; mk_engine "$LAB/.claude/gsd-core/bin/gsd-tools.cjs" proj; mk_engine "$TMP/d/explicit.cjs" explicit
run "$ONLYNODE" GSD_TOOLS="$TMP/d/explicit.cjs" -- ping
eq "d: GSD_TOOLS existant prime sur le scope projet" '["explicit","ping"]' "$(last)"
run "$ONLYNODE" GSD_TOOLS="$TMP/d/inexistant.cjs" -- ping
eq "d: GSD_TOOLS inexistant ignoré → cascade (projet)" '["proj","ping"]' "$(last)"
run "$ONLYNODE" GSD_TOOLS="$TMP/d" -- ping
eq "d: GSD_TOOLS = répertoire (non régulier) ignoré"   '["proj","ping"]' "$(last)"
run "$ONLYNODE" GSD_TOOLS="" -- ping
eq "d: GSD_TOOLS vide ignoré"                          '["proj","ping"]' "$(last)"

# (e) sentinelle ADR-070 : racine NUE jamais exécutée
new_lab e; mk_engine "$LAB/gsd-core/bin/gsd-tools.cjs" nu
run "$ONLYNODE" -- ping
eq "e: <lab>/gsd-core nu seul → rc 64" "64" "$RC"
eq "e: <lab>/gsd-core nu jamais exécuté" "0" "$(count)"
new_lab e2; mk_engine "$LAB/gsd-core/bin/gsd-tools.cjs" nu; mk_engine "$HOME_T/.claude/gsd-core/bin/gsd-tools.cjs" user
run "$ONLYNODE" -- ping
eq "e: nu + user → le user tourne, jamais le nu" '["user","ping"]' "$(last)"
new_lab e3; mkdir -p "$LAB/sub"; mk_engine "$LAB/gsd-core/bin/gsd-tools.cjs" nu
( cd "$LAB/sub" && env -i HOME="$HOME_T" PATH="$ONLYNODE" FAKE_LOG="$LOG" "$BASH_BIN" "$SCRIPT" ping >/dev/null 2>&1 ); rc3=$?
eq "e: cwd en sous-dossier, racine nue au-dessus → 64, rien exécuté" "64:0" "$rc3:$(count)"

# (f) PATH en dernier, exécuté directement
new_lab f; PD="$TMP/f/pathdir"; mkdir -p "$PD"; ln -s "$NODE_BIN" "$PD/node"
printf '#!/bin/sh\nprintf "[\\"path\\"" >> "$FAKE_LOG"; for a; do printf ",\\"%%s\\"" "$a" >> "$FAKE_LOG"; done; printf "]\\n" >> "$FAKE_LOG"; exit "${FAKE_RC:-0}"\n' > "$PD/gsd-tools"
chmod +x "$PD/gsd-tools"
run "$PD" -- ping x
eq "f: seul un gsd-tools sur le PATH → exécuté directement" '["path","ping","x"]' "$(last)"
mk_engine "$HOME_T/.claude/gsd-core/bin/gsd-tools.cjs" user
run "$PD" -- ping
eq "f: user ET PATH → le payload installé (user) prime" '["user","ping"]' "$(last)"

new_lab f3; printf '#!/bin/sh\nprintf "[\\"cwd\\"]\\n" >> "$FAKE_LOG"\n' > "$LAB/gsd-tools"; chmod +x "$LAB/gsd-tools"
run ".:$ONLYNODE" -- ping
eq "f: entrée relative du PATH (gsd-tools dans le CWD) → refusée, rc 64, rien exécuté" "64:0" "$RC:$(count)"

# (g) rc propagé
new_lab g; mk_engine "$LAB/.claude/gsd-core/bin/gsd-tools.cjs" proj
run "$ONLYNODE" FAKE_RC=3 -- ping
eq "g: moteur qui sort 3 → rc 3" "3" "$RC"
run "$ONLYNODE" FAKE_RC=64 -- ping
eq "g: rc 64 du moteur propagé tel quel (le 64 outillage est l'affaire du manager)" "64" "$RC"

# (h) syntaxe
if bash -n "$SCRIPT" 2>/dev/null; then ok "h: bash -n"; else ko "h: bash -n" "ok" "erreur"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
