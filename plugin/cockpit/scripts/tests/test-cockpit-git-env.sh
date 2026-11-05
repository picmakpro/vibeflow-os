#!/usr/bin/env bash
# test-cockpit-git-env.sh — environnement git unique du cockpit : variables GIT_* héritées retirées, filtres du dépôt neutralisés,
# options de lecture, sortie tronquée signalée (GITC-13, P78-D-21, P78-D-22, P78-D-25)
#   E0 fixtures et contrôles positifs (git réel) · E1 témoins : le piège se déclenche SANS la parade
#   E2 shBorne durci (filtres, GIT_* hérités, options de lecture, journal d'argv) · E3 les lectures réelles du socle (who, arbres, planning, gitCommonDir)
#   E4 lancerGit (ok, tronqué, hors dépôt, git absent, échéance) · E5 lancerGit sur le dépôt piégé (status ET log -p, GIT_DIR hérité)
#   E6 garde « aucun appel git hors de vf-cockpit-paths.mjs » et son témoin · E7 mutants (copies du dossier des scripts, jamais le module)
# Fixtures construites dans mktemp. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
AUX="$WORK/aux"; MARQ="$WORK/marques"; PROGS="$WORK/progs"; HOME_T="$WORK/home"
mkdir -p "$AUX" "$MARQ" "$PROGS" "$HOME_T"
GIT_REEL="$(command -v git)"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
# sh.mjs <scripts> <dépôt> <lab> <args git…> : shBorne('git', [...GIT_SUR, '-C', dépôt, ...args], dépôt, lab), sortie brute
cat > "$AUX/sh.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, repo, lab, ...args] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-paths.mjs')).href);
process.stdout.write(m.shBorne('git', [...m.GIT_SUR, '-C', repo, ...args], repo, lab));
JS
# call.mjs <scripts> <module> <fonction> <json des arguments> : appelle l'export nommé, rend le JSON du résultat
cat > "$AUX/call.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, mod, fn, json] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, mod)).href);
if (typeof m[fn] !== 'function') { console.log('export absent'); process.exit(0); }
console.log(JSON.stringify(m[fn](...JSON.parse(json || '[]'))));
JS
# dagids.mjs <scripts> <lab> <home> : ids des nœuds dag-node que who rend pour ce lab
cat > "$AUX/dagids.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, lab, home] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-who.mjs')).href);
console.log(m.collectWho(lab, { home, scriptsDir: path.join(home, 'sans-scripts') }).workers.filter((w) => w.kind === 'dag-node').map((w) => w.id).join(','));
JS
G() { node -e 'const j=JSON.parse(process.argv[1]);const v=new Function("j","return ("+process.argv[2]+")")(j);console.log(typeof v==="string"?v:JSON.stringify(v))' "$1" "$2" 2>/dev/null || echo "illisible"; }
marque() { if [ -s "$MARQ/$1" ]; then echo posé; else echo absent; fi; }
raz() { rm -f "$MARQ"/*; }

# --- fixtures : un dépôt piégé dont le .git/config déclare des programmes, chacun posant son marqueur ---
mk_prog() { # nom, corps : programme exécutable qui note son lancement dans $MARQ/<nom>
  printf '#!/bin/sh\necho "$0 $*" >> "%s/%s"\n%s\n' "$MARQ" "$1" "${2:-exit 0}" > "$PROGS/$1.sh"; chmod +x "$PROGS/$1.sh"
}
mk_prog PROC "exit 1"; mk_prog CLEAN 'cat'; mk_prog TEXTCONV 'cat "$1"'; mk_prog FSM "exit 1"
P="$WORK/piege"; "$GIT_REEL" init -q -b main "$P"; P="$(cd "$P" && pwd -P)"
printf 'f.txt filter=f\n*.dag.json filter=f\n*.bin diff=bin\n' > "$P/.gitattributes"
printf 'contenu\n' > "$P/f.txt"; printf 'a\0b\n' > "$P/a.bin"
mkdir -p "$P/.planning/missions"
printf '{"nodes":[{"id":"nx","step":"s","stage":"exec","deps":[],"scope":[],"status":"running"}]}\n' > "$P/.planning/missions/MISSION-x.dag.json"
"$GIT_REEL" -C "$P" add -A && "$GIT_REEL" -C "$P" commit -q -m "premier"
printf 'a\0c\n' > "$P/a.bin"; "$GIT_REEL" -C "$P" commit -q -am "SUJET-REEL"
# la configuration piégée vient APRÈS les commits : ni add ni commit ne lancent les programmes
"$GIT_REEL" -C "$P" config filter.f.clean "$PROGS/CLEAN.sh"
"$GIT_REEL" -C "$P" config filter.f.process "$PROGS/PROC.sh"
"$GIT_REEL" -C "$P" config diff.bin.textconv "$PROGS/TEXTCONV.sh"
"$GIT_REEL" -C "$P" config core.fsmonitor "$PROGS/FSM.sh"
# un fichier suivi « stat-dirty » : même contenu, date de modification décalée d'une minute (un DAG vieux de 1 800 s ne passerait pas par git)
UNE_MIN="$(date -v-1M +%Y%m%d%H%M 2>/dev/null || date -d '1 minute ago' +%Y%m%d%H%M)"
touch -t "$UNE_MIN" "$P/f.txt" "$P/.planning/missions/MISSION-x.dag.json"
# un dépôt leurre (sujet unique) et un arbre de travail leurre
L="$WORK/leurre"; "$GIT_REEL" init -q -b main "$L"; "$GIT_REEL" -C "$L" commit -q --allow-empty -m LEURRE; L="$(cd "$L" && pwd -P)"
DT="$WORK/arbre-leurre"; mkdir -p "$DT"; DT="$(cd "$DT" && pwd -P)"
raz

echo "=== E0 — contrôles positifs des fixtures (git réel) ==="
assert_eq "E0.1 — le dépôt piégé a deux commits, le dernier s'appelle SUJET-REEL" "$("$GIT_REEL" -C "$P" rev-list --count HEAD)|$("$GIT_REEL" -C "$P" log -1 --format=%s)" "2|SUJET-REEL"
assert_eq "E0.2 — les marqueurs sont vides après la fabrication (ni add ni commit n'ont lancé de programme)" "$(ls "$MARQ" | wc -l | tr -d ' ')" "0"

echo "=== E1 — témoins : sans la parade, le piège se déclenche (sinon les sondes E2 à E5 seraient aveugles) ==="
"$GIT_REEL" --no-optional-locks -c core.fsmonitor=false -C "$P" status --porcelain=v2 >/dev/null 2>&1
assert_eq "E1.1 — git brut avec GIT_SUR seul : status sur un fichier stat-dirty lance filter.f.process" "$(marque PROC)" "posé"; raz

echo "=== E2 — shBorne durci ==="
assert_eq "E2.0 — témoin : le module se charge et shBorne rend le sujet réel (jamais un vert à vide sur un module cassé)" "$(node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" log -1 --format=%s 2>/dev/null | tr -d '\n')" "SUJET-REEL"
S2="$(node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" status --porcelain -- f.txt 2>/dev/null)"
assert_eq "E2.1 — shBorne + status sur le même cas : aucun filtre lancé" "$(marque PROC)" "absent"
assert_eq "E2.1b — la sortie de status reste conforme (rien de modifié, le contenu est identique)" "$S2" ""; raz

echo "=== E3 — les lectures réelles du socle ==="
IDS="$(HOME="$HOME_T" node "$AUX/dagids.mjs" "$SCRIPTS" "$P" "$HOME_T" 2>/dev/null)"
assert_eq "E3.0 — témoin : who lit le nœud running du DAG suivi (le chemin git de who.mjs est parcouru)" "$IDS" "nx"
assert_eq "E3.1 — collectWho (vf-cockpit-who.mjs, status du DAG stat-dirty sous filter=f) : aucun filtre lancé" "$(marque PROC)" "absent"; raz

vf_hyg_assert

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
