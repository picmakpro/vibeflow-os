#!/usr/bin/env bash
# test-cockpit-activite-gardes.sh — lentille « Gardes » du cockpit : la règle de citation de la CI relue en JavaScript (ACTV-07, P75-D-16, P75-D-17)
#   E1-E7 sept témoins d'équivalence contre scripts/ci-suites-perimetre.sh (le script s'exécute ICI, jamais dans le module)
#   E8 gates appelés par ci.yml · E9 la citation est une sous-chaîne · E10 `git ls-files` (refus, hors dépôt, fichier supprimé)
#   P1 parité des six classes « est une garde » avec scripts/check-gate-touche.sh · P2 tuples et zone sans témoin · P3 lab non VibeFlow
#   P4 glob linéaire (justesse et croissance) · P5 coût sur ce dépôt
# Dépôts fabriqués dans mktemp. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(git -C "$SCRIPTS" rev-parse --show-toplevel)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home"; AUX="$WORK/aux"; mkdir -p "$HOME" "$AUX"

PASS=0; FAIL=0
assert_eq() { if [ "$3" = "$4" ]; then echo "  ✅ PASS — $1 : $2"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 : $2"; echo "     attendu: [$4]"; echo "     obtenu:  [$3]"; FAIL=$((FAIL+1)); fi; }

# --- outil node : contexteGardes + suitesQuiNomment / gatesDeCi / etat, sorties en texte brut ---
cat > "$AUX/gardes.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, lab, mode, ...args] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-activite-gardes.mjs')).href);
const r = await m.contexteGardes(lab);
if (mode === 'etat') console.log(r.etat);
else if (r.etat !== 'ok') console.log('ETAT ' + r.etat);
else if (mode === 'qui') for (const f of args) console.log(f + '\t' + m.suitesQuiNomment(f, r.ctx).join(','));
else if (mode === 'gates') console.log(r.ctx.gates.join('\n'));
else if (mode === 'suites') console.log(r.ctx.suites.join('\n'));
JS

# qui1 <lab> <fichier> : la liste rendue pour UN fichier ; si le module n'a rien rendu (aucune ligne), la sortie brute, jamais une liste vide inventée
qui1() { local o; o="$(node "$AUX/gardes.mjs" "$SCRIPTS" "$1" qui "$2" 2>&1)"; if printf '%s\n' "$o" | awk -F'\t' -v f="$2" '$1 == f { f2 = 1 } END { exit !f2 }'; then printf '%s\n' "$o" | awk -F'\t' -v f="$2" '$1 == f { print $2; exit }'; else printf '%s\n' "$o" | head -3 | tr '\n' ' '; fi; }

# --- dépôt fixture : deux modules, aucune suite sous mod-a (toute citation est donc une citation, jamais un motif « module ») ---
FIX="$WORK/fix"; mkdir -p "$FIX/scripts" "$FIX/.github/workflows"
cp "$ROOT/scripts/ci-suites-perimetre.sh" "$ROOT/scripts/ci-shard-suites.sh" "$FIX/scripts/"
ecrire() { mkdir -p "$(dirname "$FIX/$1")"; printf '%s\n' "$2" > "$FIX/$1"; }
ecrire plugin/mod-a/module.json '{"name":"mod-a"}'
ecrire plugin/mod-t/module.json '{"name":"mod-t"}'
for f in lib/full uniq p/dup q/dup r/twin s/twin g/glob1 none u/solo v/solo a gated x/lone y/lone; do ecrire "plugin/mod-a/$f.mjs" "// $f"; done
T=plugin/mod-t/scripts/tests
ecrire $T/test-s1.sh '# cite plugin/mod-a/lib/full.mjs'
ecrire $T/test-s2.sh '# cite node ../x/uniq.mjs'
ecrire $T/test-s3.sh '# cite dup.mjs plugin/mod-a/p'
ecrire $T/test-s3x.sh '# cite dup.mjs'
ecrire $T/test-s4.sh '# cite twin.mjs mod-a'
ecrire $T/test-s4x.sh '# cite twin.mjs'
ecrire $T/test-s5.sh '# lit plugin/mod-a/g/*.mjs'
ecrire $T/test-s6.sh '# ne cite rien'
ecrire $T/test-s7.sh '# cite solo.mjs'
ecrire $T/test-s9.sh '# cite ba.mjs'
ecrire $T/test-s10.sh '# cite lone.mjs'
ln -s test-s1.sh "$FIX/$T/test-l.sh" # lien symbolique : ni `find -type f` ni le module ne le comptent
ecrire scripts/check-demo.sh '# cite gated.mjs'
ecrire scripts/check-dot.sh '# gate'
ecrire plugin/mod-t/scripts/check-deep.sh '# gate'
ecrire .github/workflows/ci.yml 'jobs:
  gates:
    steps:
      - run: bash scripts/check-demo.sh
      - run: bash ./scripts/check-dot.sh --x
      - run: bash .claude/scripts/check-absent.sh
      - run: bash FIX/scripts/check-fix.sh
      - run: bash plugin/mod-t/scripts/check-deep.sh
      - run: cat check-bare.sh'
git -C "$FIX" init -q && git -C "$FIX" add -A && git -C "$FIX" commit -q -m init

# touche <fichier> : un commit qui ne touche que lui ; BASE/HEAD_ posés
touche() { BASE="$(git -C "$FIX" rev-parse HEAD)"; echo "// $RANDOM" >> "$FIX/$1"; git -C "$FIX" add -- "$1"; git -C "$FIX" commit -q -m "touche $1"; HEAD_="$(git -C "$FIX" rev-parse HEAD)"; }
# ci <base> <tête> : ensemble des suites jouées selon le script du dépôt (stdout)
ci() { (cd "$FIX" && bash scripts/ci-suites-perimetre.sh --liste "$1" "$2" 2>/dev/null); }

M=plugin/mod-a
declare -a ATT=() ; declare -a FICH=() ; declare -a ID=() ; declare -a LIB=()
temoin() { # id libellé fichier
  touche "$3"; ID+=("$1"); LIB+=("$2"); FICH+=("$3"); ATT+=("$(ci "$BASE" "$HEAD_")")
}
temoin E1 "chemin complet cité" $M/lib/full.mjs
temoin E2 "nom unique cité (dans un chemin d'un autre dossier)" $M/uniq.mjs
temoin E3 "nom ambigu : seule la suite qui cite aussi le dossier" $M/p/dup.mjs
temoin E4 "nom ambigu : seule la suite qui cite le module" $M/r/twin.mjs
temoin E5 "motif plugin/mod-a/g/*.mjs écrit dans une suite" $M/g/glob1.mjs
temoin E6 "fichier non cité" $M/none.mjs
temoin E7 "nom ambigu cité sans dossier ni module : aucune suite" $M/u/solo.mjs
temoin E9 "la citation est une sous-chaîne (ba.mjs cite a.mjs)" $M/a.mjs

OBT="$(node "$AUX/gardes.mjs" "$SCRIPTS" "$FIX" qui "${FICH[@]}" 2>&1)"
for i in "${!ID[@]}"; do
  if printf '%s\n' "$OBT" | awk -F'\t' -v f="${FICH[$i]}" '$1 == f { t = 1 } END { exit !t }'; then
    ligne="$(printf '%s\n' "$OBT" | awk -F'\t' -v f="${FICH[$i]}" '$1 == f { print $2; exit }')"
  else ligne="$(printf '%s\n' "$OBT" | head -3 | tr '\n' ' ')"; fi
  attendu="$(printf '%s\n' "${ATT[$i]}" | grep . | paste -sd, -)"
  assert_eq "${ID[$i]}" "${LIB[$i]}" "$ligne" "$attendu"
done

# E0 : la découverte du module égale celle du script de la CI (`ci-shard-suites.sh --all`), lien symbolique compris ; .git et node_modules sautés
assert_eq E0 "découverte des suites = ci-shard-suites.sh --all (lien symbolique exclu des deux côtés)" \
  "$(node "$AUX/gardes.mjs" "$SCRIPTS" "$FIX" suites 2>&1 | paste -sd, -)" "$(cd "$FIX" && bash scripts/ci-shard-suites.sh --all | paste -sd, -)"
SKIP="$WORK/skip"; for d in plugin/m/node_modules/x/tests plugin/m/.git/tests plugin/m/tests; do mkdir -p "$SKIP/$d"; : > "$SKIP/$d/test-z.sh"; done
git -C "$SKIP" init -q 2>/dev/null; git -C "$SKIP" add -A plugin 2>/dev/null; git -C "$SKIP" commit -q -m s 2>/dev/null
assert_eq E0 ".git et node_modules sautés par la marche" "$(node "$AUX/gardes.mjs" "$SCRIPTS" "$SKIP" suites 2>&1 | paste -sd, -)" "plugin/m/tests/test-z.sh"

# E8 : gates de ci.yml — jetons check-*.sh, « ./ » retiré, gardés s'ils sont des fichiers suivis ; absents et noms nus écartés
assert_eq E8 "gates de ci.yml : trois fichiers suivis, .claude/ FIX/ et le nom nu écartés" \
  "$(node "$AUX/gardes.mjs" "$SCRIPTS" "$FIX" gates 2>&1 | paste -sd, -)" "plugin/mod-t/scripts/check-deep.sh,scripts/check-demo.sh,scripts/check-dot.sh"
assert_eq E8 "un gate qui nomme le fichier le garde (gated.mjs cité par scripts/check-demo.sh)" \
  "$(qui1 "$FIX" $M/gated.mjs)" "scripts/check-demo.sh"

# E10 : liste des fichiers suivis par git ls-files — « +1 si non suivi » (fichier supprimé), refus, hors dépôt
BASE="$(git -C "$FIX" rev-parse HEAD)"; git -C "$FIX" rm -q -- $M/x/lone.mjs; git -C "$FIX" commit -q -m "supprime lone"; HEAD_="$(git -C "$FIX" rev-parse HEAD)"
assert_eq E10 "fichier supprimé : le nom reste ambigu (aucune suite), comme le script" \
  "$(qui1 "$FIX" $M/x/lone.mjs)" "$(ci "$BASE" "$HEAD_" | grep . | paste -sd, -)"
LOURD="$WORK/lourd"; mkdir -p "$LOURD"; git -C "$LOURD" init -q
i=0; while [ "$i" -lt 300 ]; do printf '[filter "f%s"]\n\tclean = cat\n' "$i" >> "$LOURD/.git/config"; i=$((i+1)); done
assert_eq E10 "ls-files refusé (300 pilotes déclarés) : indisponible, jamais une liste devinée" "$(node "$AUX/gardes.mjs" "$SCRIPTS" "$LOURD" etat 2>&1)" "indisponible"
mkdir -p "$WORK/horsgit/plugin/x/tests"; : > "$WORK/horsgit/plugin/x/tests/test-a.sh"
assert_eq E10 "hors dépôt git : indisponible, pas de repli sur le système de fichiers" "$(node "$AUX/gardes.mjs" "$SCRIPTS" "$WORK/horsgit" etat 2>&1)" "indisponible"

echo
echo "BILAN : $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
