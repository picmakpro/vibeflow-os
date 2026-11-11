#!/usr/bin/env bash
# test-cockpit-git-env.sh — environnement git unique du cockpit : variables GIT_* héritées retirées, filtres du dépôt neutralisés,
# options de lecture, sortie tronquée signalée (GITC-13, P78-D-21, P78-D-22, P78-D-25)
#   E0 fixtures et contrôles positifs (git réel) · E1 témoins : le piège se déclenche SANS la parade
#   E2 shBorne durci (filtres, GIT_* hérités, options de lecture, journal d'argv) · E3 les lectures réelles du socle (who, arbres, planning, gitCommonDir)
#   E4 lancerGit (ok, tronqué, hors dépôt, git absent, échéance) · E5 lancerGit sur le dépôt piégé (status ET log -p, GIT_DIR hérité)
#   E6 garde « aucun importeur de child_process hors liste blanche, aucun git lancé hors vf-cockpit-paths.mjs » (A7, audit 2026-11-06 : récursive, 11 plantés, mutants de la garde) et ses témoins · E7 mutants (copies du dossier des scripts, jamais le module)
#   E9 audit 2026-11-06 : A1 (aucun filtre déclaré exécuté, 70 filtres, borne, liste illisible) et A2 (sous-modules : --ignore-submodules=all) · E8 le moteur vendorisé (envGit passé par l'assemblage, git() fermé par défaut sans le marqueur) et ses mutants M-GARDE, M-ENV-MOTEUR
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
assert_eq "E1.2 — GIT_DIR=<leurre> détourne git brut malgré -C (le dépôt lu est le leurre)" "$(GIT_DIR="$L/.git" "$GIT_REEL" -C "$P" log -1 --format=%s)" "LEURRE"
"$GIT_REEL" -C "$P" log -p -1 >/dev/null 2>&1
assert_eq "E1.3 — git log -p brut lance le textconv déclaré" "$(marque TEXTCONV)" "posé"; raz
assert_eq "E1.4 — GIT_WORK_TREE hérité détourne git brut (rev-parse --show-toplevel rend l'arbre leurre)" "$(GIT_WORK_TREE="$DT" "$GIT_REEL" -C "$P" rev-parse --show-toplevel)" "$DT"
ABB_BRUT() { "$GIT_REEL" -C "$P" rev-parse --short HEAD | tr -d '\n' | wc -c | tr -d ' '; }
assert_eq "E1.5a — témoin : sans variable héritée, l'abréviation par défaut est de 7 caractères" "$(ABB_BRUT)" "7"
assert_eq "E1.5 — GIT_CONFIG_PARAMETERS hérité (core.abbrev=12) change git brut : 12 caractères" "$(GIT_CONFIG_PARAMETERS="'core.abbrev=12'" ABB_BRUT)" "12"
assert_eq "E1.6 — GIT_CONFIG_COUNT/KEY/VALUE hérités (core.abbrev=12) changent git brut : 12 caractères" "$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.abbrev GIT_CONFIG_VALUE_0=12 ABB_BRUT)" "12"
assert_has "E1.7 — GIT_INDEX_FILE hérité (index vide) change la sortie de status de git brut (f.txt non suivi)" "$(GIT_INDEX_FILE="$WORK/index-vide" "$GIT_REEL" --no-optional-locks -c core.fsmonitor=false -C "$P" status --porcelain -- f.txt)" "?? f.txt"; raz
# programmes du dépôt signé : un commit portant un en-tête gpgsig, un gpg.program factice et log.showSignature=true dans la config de l'UTILISATEUR (HOME)
SG="$WORK/signe"; "$GIT_REEL" init -q -b main "$SG"; SG="$(cd "$SG" && pwd -P)"; "$GIT_REEL" -C "$SG" commit -q --allow-empty -m signé
SIGNE="$("$GIT_REEL" -C "$SG" cat-file commit HEAD | awk 'BEGIN{d=0} {print} /^committer /&&!d{print "gpgsig -----BEGIN PGP SIGNATURE-----"; print " FAUX"; print " -----END PGP SIGNATURE-----"; d=1}' | "$GIT_REEL" -C "$SG" hash-object -t commit -w --stdin)"
"$GIT_REEL" -C "$SG" update-ref refs/heads/main "$SIGNE"
printf '#!/bin/sh\necho "gpg: SORTIE-GPG-FACTICE" >&2\necho "[GNUPG:] GOODSIG 0000000000000000 t"\nexit 0\n' > "$PROGS/gpg.sh"; chmod +x "$PROGS/gpg.sh"
HS="$WORK/home-sig"; mkdir -p "$HS"; printf '[log]\n\tshowSignature = true\n[gpg]\n\tprogram = %s\n' "$PROGS/gpg.sh" > "$HS/.gitconfig"
sig_brut() { ( unset GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM; HOME="$HS" "$GIT_REEL" -C "$SG" log -1 --format=%H ); }
assert_has "E1.8 — log.showSignature=true de l'utilisateur ajoute la sortie gpg à git log (brut) : le parseur serait désaligné" "$(sig_brut)" "SORTIE-GPG-FACTICE"

echo "=== E2 — shBorne durci ==="
assert_eq "E2.0 — témoin : le module se charge et shBorne rend le sujet réel (jamais un vert à vide sur un module cassé)" "$(node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" log -1 --format=%s 2>/dev/null | tr -d '\n')" "SUJET-REEL"
S2="$(node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" status --porcelain -- f.txt 2>/dev/null)"
assert_eq "E2.1 — shBorne + status sur le même cas : aucun filtre lancé" "$(marque PROC)" "absent"
assert_eq "E2.1b — la sortie de status reste conforme (rien de modifié, le contenu est identique)" "$S2" ""; raz
assert_eq "E2.2 — GIT_DIR=<leurre> hérité par node : shBorne rend le sujet du vrai dépôt" "$(GIT_DIR="$L/.git" node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" log -1 --format=%s 2>/dev/null | tr -d '\n')" "SUJET-REEL"
TOP() { node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" rev-parse --show-toplevel 2>/dev/null | tr -d '\n'; }
assert_eq "E2.3a — GIT_WORK_TREE hérité : sans effet" "$(GIT_WORK_TREE="$DT" TOP)" "$P"
ABB() { node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" rev-parse --short HEAD 2>/dev/null | tr -d '\n' | wc -c | tr -d ' '; }
assert_eq "E2.3b — GIT_CONFIG_PARAMETERS hérité (core.abbrev=12) : sans effet, 7 caractères" "$(GIT_CONFIG_PARAMETERS="'core.abbrev=12'" ABB)" "7"
assert_eq "E2.3c — GIT_CONFIG_COUNT/KEY/VALUE hérités (core.abbrev=12) : sans effet, 7 caractères" "$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.abbrev GIT_CONFIG_VALUE_0=12 ABB)" "7"
assert_eq "E2.3d — GIT_INDEX_FILE hérité (index vide) : la sortie de status est celle du vrai index" "$(GIT_INDEX_FILE="$WORK/index-vide" node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" status --porcelain -- f.txt 2>/dev/null)" ""
GIT_CONFIG_PARAMETERS="'core.fsmonitor=$PROGS/FSM.sh'" node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" status --porcelain >/dev/null 2>&1
assert_eq "E2.3e — core.fsmonitor posé par GIT_CONFIG_PARAMETERS : aucun hook lancé" "$(marque FSM)" "absent"; raz
S24="$(node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" log -p -1 2>/dev/null)"
assert_eq "E2.4 — shBorne + log -p -1 sur le dépôt piégé : aucun textconv lancé" "$(marque TEXTCONV)" "absent"
assert_has "E2.4a — témoin : la sortie est bien celle de log -p (sujet réel présent)" "$S24" "SUJET-REEL"; raz
sig_dur() { ( HOME="$HS" node "$AUX/sh.mjs" "$SCRIPTS" "$SG" "$SG" log -1 --format=%H 2>/dev/null ); }
assert_eq "E2.4b — sous un HOME à log.showSignature=true : exactement 40 hexadécimaux et un saut de ligne" "$(sig_dur | LC_ALL=C grep -cE '^[0-9a-f]{40}$')|$(sig_dur | wc -c | tr -d ' ')" "1|41"
# emballage git : journalise l'argv puis l'environnement GIT_*/VF_COCKPIT_GIT*, puis exécute le vrai git
mkdir -p "$WORK/bin"; printf '#!/bin/sh\nprintf "ARGV %%s\\n" "$*" >> "%s/git.log"\nenv | grep "^GIT_\\|^VF_COCKPIT_GIT" | sed "s/^/ENV /" >> "%s/git.log"\nexec "%s" "$@"\n' "$WORK" "$WORK" "$GIT_REEL" > "$WORK/bin/git"; chmod +x "$WORK/bin/git"
: > "$WORK/git.log"; PATH="$WORK/bin:$PATH" GIT_DIR="$L/.git" node "$AUX/sh.mjs" "$SCRIPTS" "$P" "$P" log -1 --format=%s >/dev/null 2>&1
LOGG="$(cat "$WORK/git.log")"
assert_has "E2.5a — témoin : l'emballage a vu l'appel log (sinon le journal est vide à vide)" "$LOGG" "ARGV --no-optional-locks"
assert_has "E2.5b — l'argv porte core.fsmonitor=false et --no-optional-locks" "$LOGG" "-c core.fsmonitor=false"
assert_has "E2.5c — les options de lecture suivent la sous-commande log" "$LOGG" "log --no-ext-diff --no-textconv --no-show-signature"
assert_not "E2.5d — aucun GIT_DIR dans l'environnement de l'enfant" "$(grep '^ENV GIT_DIR' "$WORK/git.log")" "GIT_DIR"
assert_has "E2.5e — le marqueur VF_COCKPIT_GIT_DURCI=1 est posé (lu par la garde du moteur)" "$LOGG" "ENV VF_COCKPIT_GIT_DURCI=1"
assert_has "E2.5f — GIT_OPTIONAL_LOCKS=0 est posé par l'environnement" "$LOGG" "ENV GIT_OPTIONAL_LOCKS=0"

echo "=== E3 — les lectures réelles du socle ==="
IDS="$(HOME="$HOME_T" node "$AUX/dagids.mjs" "$SCRIPTS" "$P" "$HOME_T" 2>/dev/null)"
assert_eq "E3.0 — témoin : who lit le nœud running du DAG suivi (le chemin git de who.mjs est parcouru)" "$IDS" "nx"
assert_eq "E3.1 — collectWho (vf-cockpit-who.mjs, status du DAG stat-dirty sous filter=f) : aucun filtre lancé" "$(marque PROC)" "absent"; raz
"$GIT_REEL" -C "$P" tag -a v1.0.0 -m "vrai tag"; "$GIT_REEL" -C "$L" tag -a vleurre -m "tag leurre"
assert_eq "E3.2 — arbresGit sous GIT_DIR leurre : l'arbre du vrai dépôt" "$(GIT_DIR="$L/.git" node "$AUX/call.mjs" "$SCRIPTS" vf-cockpit-arbres.mjs arbresGit "[\"$P\"]" 2>/dev/null | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(j.map(a=>a.chemin).join(","))')" "$P"
assert_eq "E3.3 — gitCommonDir sous GIT_DIR leurre : le dossier git du vrai dépôt" "$(GIT_DIR="$L/.git" node "$AUX/call.mjs" "$SCRIPTS" vf-cockpit-paths.mjs gitCommonDir "[\"$P\"]" 2>/dev/null)" "\"$P/.git\""
cat > "$AUX/tags.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, lab] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-planning.mjs')).href);
console.log(m.readPlanning(lab, undefined, { home: path.join(lab, '.sans-home') }).tags.map((t) => t.tag).join(','));
JS
assert_eq "E3.4 — les tags de readPlanning sous GIT_DIR leurre sont ceux du vrai dépôt" "$(GIT_DIR="$L/.git" node "$AUX/tags.mjs" "$SCRIPTS" "$P" 2>/dev/null)" "v1.0.0"
assert_eq "E3.4a — témoin : git brut sous GIT_DIR leurre lirait le tag du leurre" "$(GIT_DIR="$L/.git" "$GIT_REEL" for-each-ref --format='%(refname:short)' 'refs/tags/v*')" "vleurre"

echo "=== E4 — lancerGit ==="
# lg.mjs <scripts> <dépôt> <options JSON> <args git…> : JSON de lancerGit(dépôt, args, options)
cat > "$AUX/lg.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, repo, opts, ...args] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-paths.mjs')).href);
console.log(JSON.stringify(m.lancerGit(repo, args, JSON.parse(opts || '{}'))));
JS
LG() { node "$AUX/lg.mjs" "$SCRIPTS" "$@" 2>/dev/null || echo "illisible"; }
R41="$(LG "$P" '{}' rev-parse HEAD)"
assert_eq "E4.1 — lancerGit rev-parse HEAD : ok, 40 hexadécimaux, code 0, ni tronqué ni absent" "$(G "$R41" '[j.ok,/^[0-9a-f]{40}\n$/.test(j.sortie),j.code,j.tronque,j.absent].join("|")')" "true|true|0|false|false"
R42="$(LG "$P" '{"maxBuffer":64}' log --format=%H%n%H%n%H)"
assert_eq "E4.2 — maxBuffer 64 sur un log plus long : ok=false, tronque=true (jamais une sortie partielle présentée comme complète)" "$(G "$R42" '[j.ok,j.tronque].join("|")')" "false|true"
mkdir -p "$WORK/hors-depot"
R43="$(LG "$WORK/hors-depot" '{}' rev-parse HEAD)"
assert_eq "E4.3 — hors dépôt : ok=false, code 128, ni tronqué ni absent" "$(G "$R43" '[j.ok,j.code,j.tronque,j.absent].join("|")')" "false|128|false|false"
R44="$(LG "$P" '{"binaire":"/nonexistent/git"}' rev-parse HEAD)"
assert_eq "E4.4 — binaire introuvable : ok=false, absent=true" "$(G "$R44" '[j.ok,j.absent].join("|")')" "false|true"
mk_prog ECH "exit 0"
cat > "$AUX/ech.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, repo, prog, avec] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-paths.mjs')).href);
const lance = () => { const t = Date.now(); while (Date.now() - t < 10); return m.lancerGit(repo, ['rev-parse', 'HEAD'], { binaire: prog }); };
console.log(JSON.stringify(avec === '1' ? m.avecEcheance(1, lance) : lance()));
JS
node "$AUX/ech.mjs" "$SCRIPTS" "$P" "$PROGS/ECH.sh" 0 >/dev/null 2>&1
assert_eq "E4.5a — témoin : sans échéance, le programme est lancé (la sonde n'est pas aveugle)" "$(marque ECH)" "posé"; raz
R45="$(node "$AUX/ech.mjs" "$SCRIPTS" "$P" "$PROGS/ECH.sh" 1 2>/dev/null)"
assert_eq "E4.5 — avecEcheance(1, …) dépassée après 10 ms : rien n'est lancé, ok=false" "$(marque ECH)|$(G "$R45" 'j.ok')" "absent|false"; raz

echo "=== E5 — lancerGit sur le dépôt piégé, GIT_DIR hérité : status ET log -p (plans 78-05 et 78-08) ==="
"$GIT_REEL" --no-optional-locks -c core.fsmonitor=false -C "$P" status --porcelain=v2 >/dev/null 2>&1
"$GIT_REEL" -C "$P" log -p -1 >/dev/null 2>&1
assert_eq "E5.0 — témoins : git brut lance le filtre (status) ET le textconv (log -p)" "$(marque PROC)|$(marque TEXTCONV)" "posé|posé"; raz
R51="$(GIT_DIR="$L/.git" LG "$P" '{}' status --porcelain -- f.txt)"
assert_eq "E5.1 — lancerGit status sous GIT_DIR leurre : aucun filtre lancé, ok, sortie conforme" "$(marque PROC)|$(G "$R51" '[j.ok,JSON.stringify(j.sortie)].join("|")')" "absent|true|\"\""; raz
R52="$(GIT_DIR="$L/.git" LG "$P" '{}' log -p -1)"
assert_eq "E5.2 — lancerGit log -p -1 sous GIT_DIR leurre : aucun textconv lancé" "$(marque TEXTCONV)" "absent"
assert_eq "E5.2a — témoin : la sortie est le log -p du VRAI dépôt (sujet réel, jamais LEURRE)" "$(G "$R52" '[/SUJET-REEL/.test(j.sortie),/LEURRE/.test(j.sortie)].join("|")')" "true|false"; raz
R53="$(LG "$P" '{}' show --stat HEAD)"
assert_eq "E5.3 — lancerGit show : sous-commande à options de lecture, aucun textconv lancé, sortie utile" "$(marque TEXTCONV)|$(G "$R53" '/SUJET-REEL/.test(j.sortie)')" "absent|true"; raz

echo "=== E6 — garde : aucun appel git hors de vf-cockpit-paths.mjs (A7 : liste blanche des importeurs de child_process, balayage récursif) ==="
# garde.mjs <racine> [--exact] [--importeurs] : « fichier: raison » par violation, chemins relatifs à la racine.
#  Règle 1 : tout fichier JS (mjs, cjs, js, jsx, mts, cts, ts, tsx), HORS dossiers tests, node_modules et .git, balayé RÉCURSIVEMENT, qui importe child_process (import, require, import dynamique,
#            process.getBuiltinModule) doit figurer dans la liste blanche. Règle 2 : un importeur de la liste, autre que le socle (vf-cockpit-paths.mjs), ne lance rien dont un argument contient le mot git
#            (appel direct, alias d'import, promisify, objet d'import, chaîne require(...).fn, identifiant résolu par sa déclaration) ; seule exception : common.mjs du moteur vendorisé, tant que sa garde
#            VF_COCKPIT_GIT_DURCI (commentaire de provenance P27 de common.mjs, E8.4) est en tête de git(). --exact : une entrée de la liste qui n'importe plus child_process est périmée. --importeurs : liste les importeurs trouvés.
#  Limite assumée (analyse textuelle, pas un AST) : un nom de module construit (« child_ » + « process »), un import(...).then(({ execFile }) => …) ou un eval ne sont pas suivis.
cat > "$AUX/garde.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
const [, , racine, ...opts] = process.argv;
const LISTE = {
  'scripts/vf-cockpit-paths.mjs': 'socle',
  'scripts/vf-cockpit.mjs': 'sans-git', 'scripts/vf-cockpit-build.mjs': 'sans-git', 'scripts/vf-cockpit-live.mjs': 'sans-git', 'scripts/vf-cockpit-terminal.mjs': 'sans-git', 'scripts/vf-cockpit-terminal-session.mjs': 'sans-git', 'scripts/vf-cockpit-etat-officiel.mjs': 'sans-git',
  'skills/cockpit-moteur/assets/serve.mjs': 'sans-git', 'skills/cockpit-moteur/scripts/open.mjs': 'sans-git', 'skills/cockpit-moteur/scripts/refresh.mjs': 'sans-git',
  'skills/cockpit-moteur/scripts/lib/common.mjs': 'git-garde',
};
const SUFFIXES = /\.(?:mjs|cjs|js|jsx|mts|cts|ts|tsx)$/;
const IGNORES = new Set(['tests', 'node_modules', '.git']);
const fichiers = [];
const parcourir = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) { if (!IGNORES.has(e.name)) parcourir(p); } else if (SUFFIXES.test(e.name)) fichiers.push(p); } };
parcourir(racine);
const IMPORT = /(?:\bfrom\s*|\brequire\s*\(\s*|\bimport\s*\(\s*|\bimport\s+|\bgetBuiltinModule\s*\(\s*)(['"`])(?:node:)?child_process(?:\/promises)?\1/;
const GIT = /\bgit\b/i;
const garde = /process\.env\.VF_COCKPIT_GIT_DURCI\s*!==\s*'1'\s*\)\s*return null/;
function lanceurs(txt) {
  const noms = new Set(), espaces = new Set();
  const clause = (c) => {
    const acc = /\{([^}]*)\}/.exec(c);
    if (acc) for (const x of acc[1].split(',')) { const m = /^\s*([\w$]+)(?:\s+as\s+([\w$]+)|\s*:\s*([\w$]+))?\s*$/.exec(x); if (m) noms.add(m[2] || m[3] || m[1]); }
    for (const x of c.replace(/\{[^}]*\}/, '').split(',')) { const m = /^\s*(?:\*\s*as\s+)?([\w$]+)\s*$/.exec(x); if (m) espaces.add(m[1]); }
  };
  for (const m of txt.matchAll(/\bimport\s+([^;'"`]*?)\s+from\s*(['"`])(?:node:)?child_process(?:\/promises)?\2/g)) clause(m[1]);
  for (const m of txt.matchAll(/\b(?:const|let|var)\s+([^=;]*?)\s*=\s*(?:await\s+)?(?:require\s*\(|import\s*\(|process\s*\.\s*getBuiltinModule\s*\()\s*(['"`])(?:node:)?child_process(?:\/promises)?\2/g)) clause(m[1]);
  for (let k = 0; k < 4; k++) for (const m of txt.matchAll(/\b(?:const|let|var)\s+([\w$]+)\s*=\s*(?:util\s*\.\s*)?promisify\s*\(\s*([\w$.]+)\s*\)/g)) { const [a, b] = m[2].split('.'); if (noms.has(m[2]) || (b && espaces.has(a))) noms.add(m[1]); }
  return { noms, espaces };
}
function argumentsDe(txt, i) { // i : index de la parenthèse ouvrante ; rend le texte jusqu'à la fermante (chaînes sautées, plusieurs lignes)
  let d = 0, q = null;
  for (let k = i; k < txt.length; k++) {
    const c = txt[k];
    if (q) { if (c === '\\') k++; else if (c === q) q = null; continue; }
    if (c === '"' || c === "'" || c === '`') { q = c; continue; }
    if (c === '(') d++; else if (c === ')') { d--; if (d === 0) return txt.slice(i + 1, k); }
  }
  return txt.slice(i + 1);
}
function lanceGit(txt) {
  const { noms, espaces } = lanceurs(txt), motifs = [];
  const ech = (s) => s.replace(/\$/g, '\\$');
  for (const n of noms) motifs.push(new RegExp(`(?<![\\w$.])${ech(n)}\\s*\\(`, 'g'));
  for (const n of espaces) motifs.push(new RegExp(`(?<![\\w$.])${ech(n)}\\s*\\.\\s*[\\w$]+\\s*\\(`, 'g'));
  motifs.push(/(['"`])(?:node:)?child_process(?:\/promises)?\1\s*\)\s*\)?\s*\.\s*[\w$]+\s*\(/g);
  for (const m of txt.matchAll(/promisify\s*\(\s*([\w$.]+)\s*\)\s*\(/g)) { const [a, b] = m[1].split('.'); if (noms.has(m[1]) || (b && espaces.has(a))) { if (GIT.test(argumentsDe(txt, m.index + m[0].length - 1))) return true; } }
  for (const re of motifs) for (const m of txt.matchAll(re)) {
    const a = argumentsDe(txt, m.index + m[0].length - 1);
    if (GIT.test(a)) return true;
    const id = /^\s*([A-Za-z_$][\w$]*)\s*(?:,|$)/.exec(a)?.[1]; // premier argument = identifiant : sa déclaration est lue
    if (id) { const d = new RegExp(`\\b(?:const|let|var)\\s+${ech(id)}\\s*=\\s*([^;]{0,200})`).exec(txt); if (d && GIT.test(d[1])) return true; }
  }
  return false;
}
const sorties = [], trouves = [];
for (const f of fichiers.sort()) {
  const rel = path.relative(racine, f).split(path.sep).join('/');
  const txt = fs.readFileSync(f, 'utf8');
  if (!IMPORT.test(txt)) continue;
  trouves.push(rel);
  const nature = LISTE[rel];
  if (!nature) { sorties.push(`${rel}: importeur de child_process hors liste blanche`); continue; }
  if (nature === 'socle') continue;
  if (lanceGit(txt) && !(nature === 'git-garde' && garde.test(txt))) sorties.push(`${rel}: lancement dont un argument contient git`);
}
if (opts.includes('--exact')) for (const rel of Object.keys(LISTE)) if (!trouves.includes(rel)) sorties.push(`${rel}: liste blanche périmée (n'importe plus child_process, ou absent)`);
for (const l of opts.includes('--importeurs') ? trouves : sorties) console.log(l);
JS
PLUGIN="$(cd "$SCRIPTS/.." && pwd)"
GARDE="$(node "$AUX/garde.mjs" "$PLUGIN" --exact)"
assert_eq "E6.1 — aucun importeur de child_process hors liste blanche, aucun lancement de git hors vf-cockpit-paths.mjs (arbre réel de plugin/cockpit, balayage récursif)" "${GARDE:-aucun}" "aucun"
assert_eq "E6.1a — la garde a bien ouvert des fichiers : exactement les 11 importeurs de la liste sont trouvés (pas un dossier vide)" "$(node "$AUX/garde.mjs" "$PLUGIN" --importeurs | wc -l | tr -d ' ')" "11"
# les onze fichiers plantés de l'audit (promisify, alias d'import, multiligne, autre nom de variable, chemin absolu, execSync, bash -c, témoin direct, .cjs, .js)
PLANTES_NOMS="a-promisify.mjs b-promisify-var.mjs c-alias.mjs d-multiligne.mjs e-variable-autre-nom.mjs f-chemin-absolu.mjs g-shell.mjs h-bash-c.mjs i-temoin-direct.mjs j-cjs.cjs k-js.js"
planter() { # planter <nom> : écrit le contenu du fichier planté sur la sortie standard
  case "$1" in
    a-*) printf "import { execFile } from 'node:child_process';\nimport { promisify } from 'node:util';\nawait promisify(execFile)('git', ['status']);\n";;
    b-*) printf "import { execFile } from 'node:child_process';\nimport { promisify } from 'node:util';\nconst run = promisify(execFile);\nawait run('git', ['log']);\n";;
    c-*) printf "import { execFileSync as sh } from 'node:child_process';\nsh('git', ['status']);\n";;
    d-*) printf "import cp from 'node:child_process';\ncp.execFileSync(\n  'git', ['status']);\n";;
    e-*) printf "import cp from 'node:child_process';\nconst BIN = 'git';\ncp.execFileSync(BIN, ['status']);\n";;
    f-*) printf "import cp from 'node:child_process';\ncp.spawnSync('/usr/bin/git', ['status']);\n";;
    g-*) printf "import cp from 'node:child_process';\ncp.execSync('cd x && git status');\n";;
    h-*) printf "import cp from 'node:child_process';\ncp.execFileSync('bash', ['-c', 'git status']);\n";;
    i-*) printf "import cp from 'node:child_process';\ncp.execFileSync('git', ['status']);\n";;
    j-*|k-*) printf "require('child_process').execFileSync('git', ['status']);\n";;
  esac
}
# E6.2 — règle 1 : chaque fichier planté, hors liste et hors scripts/*.mjs (skills/…/assets, tous suffixes), rougit la garde
PH="$WORK/e6-hl"; rm -rf "$PH"; mkdir -p "$PH/skills/cockpit-moteur/assets/ui"
for n in $PLANTES_NOMS; do planter "$n" > "$PH/skills/cockpit-moteur/assets/ui/zz-$n"; done
R62="$(node "$AUX/garde.mjs" "$PH")"
assert_eq "E6.2 — règle 1 : les 11 fichiers plantés (.mjs, .cjs, .js ; hors scripts/*.mjs) sont tous signalés « hors liste blanche »" "$(printf '%s\n' "$R62" | grep -c 'importeur de child_process hors liste blanche')" "11"
mkdir -p "$PH/zz"; printf "import cp from 'node:child_process';\ncp.execFileSync('ps', ['-p', '1']);\n" > "$PH/zz/sans-git.mjs"
assert_eq "E6.2a — un importeur hors liste SANS le mot git rougit aussi (la règle 1 ne dépend pas de la règle 2)" "$(node "$AUX/garde.mjs" "$PH" | grep -c 'zz/sans-git.mjs: importeur de child_process hors liste blanche')" "1"
# E6.3 — règle 2 : sous le nom d'un importeur DE LA LISTE, chacun des onze contenus rougit pour son « git » (alias, promisify, multiligne, variable, chemin absolu, shell, bash -c, cjs)
R63=""
for n in $PLANTES_NOMS; do
  PL="$WORK/e6-li"; rm -rf "$PL"; mkdir -p "$PL/scripts"; planter "$n" > "$PL/scripts/vf-cockpit-live.mjs"
  R63="$R63$(node "$AUX/garde.mjs" "$PL" | grep -c 'scripts/vf-cockpit-live.mjs: lancement dont un argument contient git' | tr -d ' ')"
done
assert_eq "E6.3 — règle 2 : sous le nom d'un importeur de la liste, les 11 contenus plantés sont tous signalés (1 chacun)" "$R63" "11111111111"
# E6.4 — négatifs : la garde ne sur-signale pas
PL="$WORK/e6-neg"; rm -rf "$PL"; mkdir -p "$PL/scripts" "$PL/skills/cockpit-moteur/scripts/lib" "$PL/scripts/tests" "$PL/autre"
printf "import { execFileSync } from 'node:child_process';\nemit('git', {});\nexecFileSync('ps', ['-p', '1']);\n" > "$PL/scripts/vf-cockpit-live.mjs"
printf "import cp from 'node:child_process';\ncp.execFileSync('git', ['status']);\n" > "$PL/scripts/tests/outil.mjs"
printf "const NATIFS = new Set(['child_process', 'cluster']);\n" > "$PL/autre/set.mjs"
printf "import { execFileSync } from 'node:child_process';\nexport function git(cwd, args) {\n  if (process.env.VF_COCKPIT_GIT_DURCI !== '1') return null;\n  return execFileSync('git', ['-C', cwd, ...args]);\n}\n" > "$PL/skills/cockpit-moteur/scripts/lib/common.mjs"
assert_eq "E6.4 — négatifs : « git » hors lancement (emit), dossier tests, simple chaîne child_process, common.mjs gardé : aucune violation" "$(node "$AUX/garde.mjs" "$PL")" ""
printf "import { execFileSync } from 'node:child_process';\nexport function git(cwd, args) {\n  return execFileSync('git', ['-C', cwd, ...args]);\n}\n" > "$PL/skills/cockpit-moteur/scripts/lib/common.mjs"
assert_eq "E6.4a — common.mjs SANS sa garde VF_COCKPIT_GIT_DURCI : signalé (l'exemption tient à la garde, pas au nom du fichier)" "$(node "$AUX/garde.mjs" "$PL")" "skills/cockpit-moteur/scripts/lib/common.mjs: lancement dont un argument contient git"
assert_eq "E6.4b — l'exemption du socle est celle de vf-cockpit-paths.mjs et d'aucun autre fichier (même contenu sous un autre nom : signalé)" "$(rm -rf "$WORK/e6-sc"; mkdir -p "$WORK/e6-sc/scripts"; planter i-x > "$WORK/e6-sc/scripts/vf-cockpit-paths.mjs"; node "$AUX/garde.mjs" "$WORK/e6-sc"; rm -f "$WORK/e6-sc/scripts/vf-cockpit-paths.mjs"; planter i-x > "$WORK/e6-sc/scripts/vf-cockpit-intrus.mjs"; node "$AUX/garde.mjs" "$WORK/e6-sc")" "scripts/vf-cockpit-intrus.mjs: importeur de child_process hors liste blanche"
# E6.5 — sur une COPIE de l'arbre réel : un importeur planté dans skills/…/assets/ui et un git lancé dans un importeur de la liste rougissent chacun, rien d'autre
assert_eq "E6.5a — témoin : l'exécuteur asynchrone vit bien dans vf-cockpit-paths.mjs (execFile y est appelé : l'exemption est exercée)" "$(grep -c 'execFile(cmd' "$SCRIPTS/vf-cockpit-paths.mjs" | tr -d ' ')" "1"
PC="$WORK/e6-copie"; rm -rf "$PC"; cp -R "$PLUGIN" "$PC"
assert_eq "E6.5b — la copie de l'arbre réel passe la garde (--exact)" "$(node "$AUX/garde.mjs" "$PC" --exact)" ""
planter k-x > "$PC/skills/cockpit-moteur/assets/ui/zz-intrus.js"
assert_eq "E6.5c — un require('child_process').execFileSync('git') planté dans skills/cockpit-moteur/assets/ui/zz-intrus.js (hors scripts/*.mjs) rougit, seul" "$(node "$AUX/garde.mjs" "$PC")" "skills/cockpit-moteur/assets/ui/zz-intrus.js: importeur de child_process hors liste blanche"
rm -f "$PC/skills/cockpit-moteur/assets/ui/zz-intrus.js"
printf "\nexecFileSync('git', ['status']);\n" >> "$PC/scripts/vf-cockpit-live.mjs"
assert_eq "E6.5d — un execFileSync('git', …) ajouté à vf-cockpit-live.mjs (importeur de la liste) rougit, seul" "$(node "$AUX/garde.mjs" "$PC")" "scripts/vf-cockpit-live.mjs: lancement dont un argument contient git"

# E6.6 — mutants de la garde : chacun rougit SA sonde, pour la bonne raison (l'ancre existe, la sonde non mutée est verte)
cat > "$AUX/mutg.mjs" <<'JS'
import fs from 'node:fs';
const [, , src, dst] = process.argv;
const t = fs.readFileSync(src, 'utf8');
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(dst, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
mutg() { FROM="$2" TO="$3" node "$AUX/mutg.mjs" "$AUX/garde.mjs" "$AUX/garde-$1.mjs" 2>&1; }
r63() { local g="$1" out="" n PL; for n in $PLANTES_NOMS; do PL="$WORK/e6-li"; rm -rf "$PL"; mkdir -p "$PL/scripts"; planter "$n" > "$PL/scripts/vf-cockpit-live.mjs"; out="$out$(node "$g" "$PL" | grep -c 'scripts/vf-cockpit-live.mjs: lancement dont un argument contient git' | tr -d ' ')"; done; echo "$out"; }
assert_eq "M-LISTE.0 — l'ancre existe" "$(mutg liste 'if (!nature) {' 'if (false) {')" "muté"
assert_eq "M-LISTE — rougit E6.2a : l'importeur hors liste sans git n'est plus signalé" "$(node "$AUX/garde-liste.mjs" "$PH" | grep -c 'zz/sans-git.mjs')" "0"
assert_eq "M-RECURSIF.0 — l'ancre existe" "$(mutg recursif 'if (!IGNORES.has(e.name)) parcourir(p);' '{}')" "muté"
assert_eq "M-RECURSIF — rougit E6.2 : le balayage ne descend plus, aucun des 11 fichiers (sous skills/…/assets/ui) n'est vu" "$(node "$AUX/garde-recursif.mjs" "$PH" | grep -c 'hors liste blanche')" "0"
assert_eq "M-SUFFIXE.0 — l'ancre existe" "$(mutg suffixe '/\.(?:mjs|cjs|js|jsx|mts|cts|ts|tsx)$/' '/\.mjs$/')" "muté"
assert_eq "M-SUFFIXE — rougit E6.2 : .cjs et .js ne sont plus balayés (9 des 11 plantés signalés)" "$(node "$AUX/garde-suffixe.mjs" "$PH" | grep -c 'assets/ui/zz-.*hors liste blanche')" "9"
assert_eq "M-ALIAS.0 — l'ancre existe" "$(mutg alias 'noms.add(m[2] || m[3] || m[1]);' 'noms.add(m[1]);')" "muté"
assert_eq "M-ALIAS — rougit E6.3 : l'alias d'import (c-alias) n'est plus suivi" "$(r63 "$AUX/garde-alias.mjs")" "11011111111"
assert_eq "M-IDENT.0 — l'ancre existe" "$(mutg ident 'if (d && GIT.test(d[1])) return true;' '')" "muté"
assert_eq "M-IDENT — rougit E6.3 : la variable portant « git » (e-variable-autre-nom) n'est plus résolue" "$(r63 "$AUX/garde-ident.mjs")" "11110111111"
assert_eq "M-EXEMPTION.0 — l'ancre existe" "$(mutg exemption "!(nature === 'git-garde' && garde.test(txt))" "!(nature === 'git-garde')")" "muté"
assert_eq "M-EXEMPTION — rougit E6.4a : common.mjs sans sa garde n'est plus signalé" "$(rm -rf "$WORK/e6-ex"; mkdir -p "$WORK/e6-ex/skills/cockpit-moteur/scripts/lib"; cp "$WORK/e6-neg/skills/cockpit-moteur/scripts/lib/common.mjs" "$WORK/e6-ex/skills/cockpit-moteur/scripts/lib/common.mjs"; node "$AUX/garde-exemption.mjs" "$WORK/e6-ex")" ""

echo "=== E7 — mutants : chacun rougit SA sonde, pour la bonne raison ==="
cat > "$AUX/mutsub.mjs" <<'JS'
import fs from 'node:fs';
const f = process.argv[2]; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
mutant() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$d/"; FROM="$2" TO="$3" node "$AUX/mutsub.mjs" "$d/vf-cockpit-paths.mjs" 2>&1; }
sig_mut() { ( HOME="$HS" node "$AUX/sh.mjs" "$1" "$SG" "$SG" log -1 --format=%H 2>/dev/null ); }

# M-ENV : le retrait des variables GIT_* hérités est supprimé -> E2.2 rend le sujet du leurre, E5 aussi
assert_eq "M-ENV.0 — l'ancre du mutant existe dans le module" "$(mutant env 'if (!GIT_HERITE.test(k)) e[k] = v;' 'e[k] = v;')" "muté"
MD="$WORK/mut-env"
assert_eq "M-ENV — rougit E2.2 : shBorne lit le dépôt leurre (LEURRE)" "$(GIT_DIR="$L/.git" node "$AUX/sh.mjs" "$MD" "$P" "$P" log -1 --format=%s 2>/dev/null | tr -d '\n')" "LEURRE"
assert_eq "M-ENV — rougit aussi E2.3a : le GIT_WORK_TREE hérité détourne le toplevel" "$(GIT_WORK_TREE="$DT" node "$AUX/sh.mjs" "$MD" "$P" "$P" rev-parse --show-toplevel 2>/dev/null | tr -d '\n')" "$DT"
assert_eq "M-ENV — rougit aussi E5.2a : lancerGit sous GIT_DIR leurre lit le log du leurre" "$(GIT_DIR="$L/.git" node "$AUX/lg.mjs" "$MD" "$P" '{}' log -1 --format=%s 2>/dev/null | node -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).sortie.trim())')" "LEURRE"

# M-FILTRES : configFiltres rend [] -> E2.1 et E5.1 voient le filtre se lancer
assert_eq "M-FILTRES.0 — l'ancre du mutant existe" "$(mutant filtres 'export const configFiltres = (noms) =>' 'export const configFiltres = (noms) => [] ||')" "muté"
MD="$WORK/mut-filtres"; raz
node "$AUX/sh.mjs" "$MD" "$P" "$P" status --porcelain -- f.txt >/dev/null 2>&1
assert_eq "M-FILTRES — rougit E2.1 : le filtre déclaré par le dépôt est lancé par shBorne" "$(marque PROC)" "posé"; raz
node "$AUX/lg.mjs" "$MD" "$P" '{}' status --porcelain -- f.txt >/dev/null 2>&1
assert_eq "M-FILTRES — rougit aussi E5.1 : le filtre est lancé par lancerGit" "$(marque PROC)" "posé"; raz

# M-LECTURE : OPTIONS_LECTURE non insérées -> E2.4 et E5.2 voient le textconv se lancer, E2.4b la sortie gpg
assert_eq "M-LECTURE.0 — l'ancre du mutant existe" "$(mutant lecture 'ins = OPTIONS_LECTURE[sous] || [];' 'ins = [];')" "muté"
MD="$WORK/mut-lecture"
node "$AUX/sh.mjs" "$MD" "$P" "$P" log -p -1 >/dev/null 2>&1
assert_eq "M-LECTURE — rougit E2.4 : le textconv est lancé par shBorne" "$(marque TEXTCONV)" "posé"; raz
node "$AUX/lg.mjs" "$MD" "$P" '{}' log -p -1 >/dev/null 2>&1
assert_eq "M-LECTURE — rougit aussi E5.2 : le textconv est lancé par lancerGit" "$(marque TEXTCONV)" "posé"; raz
# AUDC-A-04 : le programme de signature est aussi neutralisé par l'environnement (gpg.program, gpg.openpgp.program) : options de lecture retirées SEULES, la sortie gpg ne s'ajoute plus (deux protections)
assert_eq "M-LECTURE — E2.4b : options de lecture retirées, mais gpg neutralisé par l'environnement : le hash reste seul (mis à jour en place, AUDC-A-04)" "$(sig_mut "$MD" | LC_ALL=C grep -c 'SORTIE-GPG-FACTICE')" "0"
# la sonde E2.4b garde SON mutant : options de lecture retirées ET programmes de signature de l'environnement retirés -> la sortie gpg s'ajoute au hash
assert_eq "M-LECTURE.2 — mutant double : ancres" "$(mutant lecture2 'ins = OPTIONS_LECTURE[sous] || [];' 'ins = [];')|$(FROM="['gpg.program', INERTE]," TO="" node "$AUX/mutsub.mjs" "$WORK/mut-lecture2/vf-cockpit-git-durci.mjs")|$(FROM="['gpg.openpgp.program', INERTE]," TO="" node "$AUX/mutsub.mjs" "$WORK/mut-lecture2/vf-cockpit-git-durci.mjs")" "muté|muté|muté"
assert_has "M-LECTURE.2 — rougit E2.4b : la sortie gpg de log.showSignature s'ajoute au hash" "$(sig_mut "$WORK/mut-lecture2")" "SORTIE-GPG-FACTICE"

# M-TRONQUE : ENOBUFS ignoré -> E4.2 ne voit plus la troncature
assert_eq "M-TRONQUE.0 — l'ancre du mutant existe" "$(mutant tronque "tronque: e.code === 'ENOBUFS'" "tronque: false && e.code === 'ENOBUFS'")" "muté"
MD="$WORK/mut-tronque"
RM="$(node "$AUX/lg.mjs" "$MD" "$P" '{"maxBuffer":64}' log --format=%H%n%H%n%H 2>/dev/null)"
assert_eq "M-TRONQUE — rougit E4.2 : la troncature n'est plus signalée (tronque=false)" "$(G "$RM" 'j.tronque')" "false"

echo "=== E8 — le moteur vendorisé : environnement durci passé par l'assemblage, git fermé par défaut (GITC-13, P78-D-25) ==="
MOTEUR="$(cd "$SCRIPTS/.." && pwd)/skills/cockpit-moteur"
BUILD="$SCRIPTS/vf-cockpit-build.mjs"
LAB8="$WORK/lab8"; cp -R "$P" "$LAB8"; printf "export const un = 1;\n" > "$LAB8/m.js"   # un fichier de code, suivi par git (non ignoré)
cat > "$AUX/tete.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const r = (j.meta && j.meta.repos) || j.repos || [];
console.log(r.length && r[0].head ? r[0].head : 'aucun');
JS
nfich() { node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));console.log((j.files||[]).length)' "$1"; }
HEAD_LAB="$("$GIT_REEL" -C "$LAB8" rev-parse HEAD)"; HEAD_LEURRE="$("$GIT_REEL" -C "$L" rev-parse HEAD)"
assert_eq "E8.0 — témoin : le HEAD du lab et celui du leurre diffèrent" "$([ "$HEAD_LAB" != "$HEAD_LEURRE" ] && echo oui || echo non)" "oui"
# copie du moteur dont la garde de git() est retirée (témoin positif et mutant M-GARDE)
sans_garde() { FROM="  if (process.env.VF_COCKPIT_GIT_DURCI !== '1') return null;
" TO="" node "$AUX/mutsub.mjs" "$1/scripts/lib/common.mjs" 2>&1; }
# E8.1 — témoin positif : un moteur SANS garde, sous GIT_DIR hérité, lit le leurre
SG8="$WORK/moteur-sans-garde"; rm -rf "$SG8"; cp -R "$MOTEUR" "$SG8"; sans_garde "$SG8" >/dev/null
GIT_DIR="$L/.git" node "$SG8/scripts/scan.mjs" "$LAB8" --out="$WORK/o81/.cache/scan.json" >/dev/null 2>&1
assert_eq "E8.1 — témoin : le moteur sans garde, sous GIT_DIR hérité, écrit le HEAD du leurre" "$(node "$AUX/tete.mjs" "$WORK/o81/.cache/scan.json" 2>/dev/null || echo illisible)" "$HEAD_LEURRE"
# E8.2 — l'assemblage sous GIT_DIR hérité lit le vrai dépôt et ne lance aucun programme du dépôt piégé
raz; rm -rf "$LAB8/.vibeflow"
GIT_DIR="$L/.git" node "$BUILD" "$LAB8" --quiet >/dev/null 2>&1
assert_eq "E8.2 — l'assemblage sous GIT_DIR hérité : meta.repos[0].head = HEAD réel du lab" "$(node "$AUX/tete.mjs" "$LAB8/.vibeflow/cockpit/graph.json" 2>/dev/null || echo illisible)" "$HEAD_LAB"
assert_eq "E8.2a — aucun programme du dépôt piégé lancé pendant l'assemblage (filtre, textconv, fsmonitor)" "$(for m in PROC CLEAN TEXTCONV FSM; do marque $m; done | sort -u | tr '\n' ' ')" "absent "
assert_eq "E8.2b — la carte Code porte des fichiers (au moins un)" "$([ "$(nfich "$LAB8/.vibeflow/cockpit/graph.json" 2>/dev/null || echo 0)" -ge 1 ] && echo oui || echo non)" "oui"
# E8.3 — sans le marqueur, le moteur ne lance aucun git
: > "$WORK/git.log"; rm -rf "$WORK/o83"
env -u VF_COCKPIT_GIT_DURCI PATH="$WORK/bin:$PATH" GIT_DIR="$L/.git" node "$MOTEUR/scripts/scan.mjs" "$LAB8" --out="$WORK/o83/.cache/scan.json" >/dev/null 2>&1
assert_eq "E8.3 — sans VF_COCKPIT_GIT_DURCI : aucun appel git (journal de l'emballage vide)" "$(wc -c < "$WORK/git.log" | tr -d ' ')" "0"
assert_eq "E8.3a — le scan a bien tourné sans marqueur et n'écrit aucun HEAD" "$(node "$AUX/tete.mjs" "$WORK/o83/.cache/scan.json" 2>/dev/null || echo illisible)" "aucun"
: > "$WORK/git.log"; rm -rf "$WORK/o83b"
VF_COCKPIT_GIT_DURCI=1 PATH="$WORK/bin:$PATH" node "$MOTEUR/scripts/scan.mjs" "$LAB8" --out="$WORK/o83b/.cache/scan.json" >/dev/null 2>&1
assert_has "E8.3b — témoin : avec le marqueur, l'emballage journalise des appels git (le journal vide de E8.3 prouve donc quelque chose)" "$(cat "$WORK/git.log")" "ARGV"
# E8.4 — la trace de provenance « // vibeflow P<n> : » est juste au-dessus de la garde de git() dans common.mjs et dit « environnement durci »
trace_provenance() { awk '/VF_COCKPIT_GIT_DURCI/ && /process\.env/ {print prev; exit} {prev=$0}' "$1/scripts/lib/common.mjs" | grep -qE '^ *// vibeflow P[0-9]+ :.*environnement durci' && echo presente || echo absente; }
assert_eq "E8.4 — la garde de git() est précédée d'un commentaire de provenance « // vibeflow P<n> : » qui dit « environnement durci »" "$(trace_provenance "$MOTEUR")" "presente"
# mutants du moteur
rm -rf "$WORK/mut-garde"; cp -R "$MOTEUR" "$WORK/mut-garde"
assert_eq "M-GARDE.0 — l'ancre du mutant existe (garde présente dans le moteur)" "$(sans_garde "$WORK/mut-garde")" "muté"
: > "$WORK/git.log"; rm -rf "$WORK/o8m"
env -u VF_COCKPIT_GIT_DURCI PATH="$WORK/bin:$PATH" GIT_DIR="$L/.git" node "$WORK/mut-garde/scripts/scan.mjs" "$LAB8" --out="$WORK/o8m/.cache/scan.json" >/dev/null 2>&1
assert_has "M-GARDE — rougit E8.3 : sans la garde le moteur lance git (journal non vide)" "$(cat "$WORK/git.log")" "ARGV"
rm -rf "$WORK/mut-trace"; cp -R "$MOTEUR" "$WORK/mut-trace"
assert_eq "M-TRACE.0 — l'ancre du mutant existe (marque de provenance P27 dans common.mjs)" "$(FROM="// vibeflow P27 :" TO="//" node "$AUX/mutsub.mjs" "$WORK/mut-trace/scripts/lib/common.mjs" 2>&1)" "muté"
assert_eq "M-TRACE — rougit E8.4 : la copie sans la marque de provenance fait dire « absente »" "$(trace_provenance "$WORK/mut-trace")" "absente"
MT="$WORK/mut-env-moteur"; rm -rf "$MT"; mkdir -p "$MT/scripts" "$MT/skills"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$MT/scripts/"; cp -R "$MOTEUR" "$MT/skills/cockpit-moteur"
assert_eq "M-ENV-MOTEUR.0 — l'ancre du mutant existe dans vf-cockpit-build.mjs" "$(FROM="env: etatMoteur(lab).env" TO="env: envEnfant(lab)" node "$AUX/mutsub.mjs" "$MT/scripts/vf-cockpit-build.mjs" 2>&1)" "muté"
rm -rf "$LAB8/.vibeflow"; GIT_DIR="$L/.git" node "$MT/scripts/vf-cockpit-build.mjs" "$LAB8" --quiet >/dev/null 2>&1
assert_eq "M-ENV-MOTEUR — rougit E8.2 : run() sans envGit, le moteur (marqueur absent ou GIT_DIR hérité) ne rend plus le HEAD réel" "$([ "$(node "$AUX/tete.mjs" "$LAB8/.vibeflow/cockpit/graph.json" 2>/dev/null || echo illisible)" != "$HEAD_LAB" ] && echo rouge || echo vert)" "rouge"

echo "=== E9 — audit 2026-11-06 : A1 (aucun filtre déclaré exécuté, quel que soit leur nombre) et A2 (sous-modules) ==="
# lga.mjs <scripts> <dépôt> <options JSON> <args git…> : JSON de lancerGitAsync(dépôt, args, options)
cat > "$AUX/lga.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, repo, opts, ...args] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-paths.mjs')).href);
console.log(JSON.stringify(await m.lancerGitAsync(repo, args, JSON.parse(opts || '{}'))));
JS
LGA() { node "$AUX/lga.mjs" "$SCRIPTS" "$@" 2>/dev/null || echo "illisible"; }
mk_prog F9 'cat'; mk_prog SUBCLEAN 'cat'
mk_filtres() { # mk_filtres <dossier> <n> : dépôt à n filtres déclarés ; le DERNIER (f<n>) est celui que .gitattributes applique et qui pose le marqueur F9 ; f.txt est « stat-dirty » (status relit son contenu)
  local d="$1" n="$2" i; "$GIT_REEL" init -q -b main "$d"; printf 'f.txt filter=f%s\n' "$n" > "$d/.gitattributes"; printf 'contenu\n' > "$d/f.txt"
  "$GIT_REEL" -C "$d" add -A; "$GIT_REEL" -C "$d" commit -q -m un
  { for i in $(seq 1 "$n"); do if [ "$i" -eq "$n" ]; then printf '[filter "f%s"]\n\tclean = %s\n' "$i" "$PROGS/F9.sh"; else printf '[filter "f%s"]\n\tclean = cat\n' "$i"; fi; done; } >> "$d/.git/config"
  touch -t "$UNE_MIN" "$d/f.txt"
}
F70="$WORK/f70"; mk_filtres "$F70" 70; F1="$WORK/f1"; mk_filtres "$F1" 1; F300="$WORK/f300"; mk_filtres "$F300" 300
raz
"$GIT_REEL" --no-optional-locks -c core.fsmonitor=false -C "$F70" status --porcelain >/dev/null 2>&1
assert_eq "E9.0 — témoin : git brut sur 70 filtres (le 70e est celui de .gitattributes) lance le programme du 70e filtre : la sonde n'est pas aveugle" "$(marque F9)" "posé"; raz
NB() { node "$AUX/call.mjs" "$SCRIPTS" vf-cockpit-paths.mjs filtresDeclares "[\"$1\"]" 2>/dev/null | node -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).length)'; }
assert_eq "E9.0a — témoin : le module voit les 70 filtres du dépôt à 70 filtres (69 de plus que celui à 1 filtre : la config de l'utilisateur, lfs par exemple, s'ajoute aux deux) : filtresDeclares n'en tronque aucun" "$(( $(NB "$F70") - $(NB "$F1") ))" "69"
# A1 : lancerGit, shBorne et lancerGitAsync, 70 filtres puis 1 filtre : le programme n'est jamais lancé, status aboutit
R="$(LG "$F70" '{}' status --porcelain)"
assert_eq "E9.1 — lancerGit status, 70 filtres : aucun programme lancé, status aboutit (ok)" "$(marque F9)|$(G "$R" 'j.ok')" "absent|true"; raz
node "$AUX/sh.mjs" "$SCRIPTS" "$F70" "$F70" status --porcelain >/dev/null 2>&1
assert_eq "E9.2 — shBorne status, 70 filtres : aucun programme lancé" "$(marque F9)" "absent"; raz
R="$(LGA "$F70" '{}' status --porcelain)"
assert_eq "E9.3 — lancerGitAsync status, 70 filtres : aucun programme lancé, status aboutit (ok)" "$(marque F9)|$(G "$R" 'j.ok')" "absent|true"; raz
R="$(LG "$F1" '{}' status --porcelain)"; R2="$(LGA "$F1" '{}' status --porcelain)"
assert_eq "E9.4 — un seul filtre : aucun programme lancé (lancerGit et lancerGitAsync), status aboutit" "$(marque F9)|$(G "$R" 'j.ok')|$(G "$R2" 'j.ok')" "absent|true|true"; raz
# borne de l'environnement : au-delà de MAX_FILTRES (256), status n'est PAS lancé (refus explicite), jamais « le reste n'est pas vidé »
R="$(LG "$F300" '{}' status --porcelain)"; R2="$(LGA "$F300" '{}' status --porcelain)"
assert_eq "E9.5 — 300 filtres (au-delà de la borne) : lancerGit et lancerGitAsync refusent (ok=false, refuse, sortie vide), aucun programme lancé" "$(marque F9)|$(G "$R" '[j.ok,j.refuse,JSON.stringify(j.sortie)].join(":")')|$(G "$R2" '[j.ok,j.refuse,JSON.stringify(j.sortie)].join(":")')" 'absent|false:true:""|false:true:""'; raz
S9="$(node "$AUX/sh.mjs" "$SCRIPTS" "$F300" "$F300" status --porcelain 2>/dev/null)"
assert_eq "E9.5a — shBorne status, 300 filtres : sortie vide (inconnu), aucun programme lancé" "$(marque F9)|${S9:-vide}" "absent|vide"; raz
R="$(LG "$F300" '{}' log -1 --format=%s)"
assert_eq "E9.5b — la borne ne vise que les sous-commandes filtrantes : log reste lu sur le même dépôt" "$(G "$R" 'j.ok+"|"+j.sortie.trim()')" "true|un"
# liste des filtres illisible (git config en échec) : status n'est pas lancé non plus (un filtre inconnu n'est pas un filtre absent)
mkdir -p "$WORK/bin-cfg"; printf '#!/bin/sh\ncase "$*" in *--get-regexp*) exit 2;; esac\nexec "%s" "$@"\n' "$GIT_REEL" > "$WORK/bin-cfg/git"; chmod +x "$WORK/bin-cfg/git"
R="$(PATH="$WORK/bin-cfg:$PATH" LG "$F70" '{}' status --porcelain)"; R2="$(PATH="$WORK/bin-cfg:$PATH" LGA "$F70" '{}' status --porcelain)"
assert_eq "E9.6 — liste des filtres illisible (git config --get-regexp rend 2) : status refusé en synchrone et en asynchrone, aucun programme lancé" "$(marque F9)|$(G "$R" '[j.ok,j.refuse].join(":")')|$(G "$R2" '[j.ok,j.refuse].join(":")')" "absent|false:true|false:true"; raz
R="$(PATH="$WORK/bin-cfg:$PATH" LG "$F70" '{}' rev-parse HEAD)"
assert_eq "E9.6a — témoin : le même emballage laisse passer les autres commandes (rev-parse ok) : le refus vient de la liste illisible" "$(G "$R" 'j.ok')" "true"

# A2 : sous-modules — la config de .git/modules/<n>/config n'est jamais lue par un status lancé par le cockpit
mk_sous_module() { # mk_sous_module <dossier> : super-dépôt `repo` + sous-module `sub` dont la configuration (sous .git/modules) déclare un filtre qui pose SUBCLEAN
  local w="$1"; mkdir -p "$w"
  "$GIT_REEL" init -q -b main "$w/subsrc"; printf 'f.txt filter=f\n' > "$w/subsrc/.gitattributes"; printf 'c\n' > "$w/subsrc/f.txt"
  "$GIT_REEL" -C "$w/subsrc" add -A; "$GIT_REEL" -C "$w/subsrc" commit -q -m s
  "$GIT_REEL" init -q -b main "$w/repo"; printf 'x\n' > "$w/repo/a.txt"; "$GIT_REEL" -C "$w/repo" add -A; "$GIT_REEL" -C "$w/repo" commit -q -m r
  "$GIT_REEL" -C "$w/repo" -c protocol.file.allow=always submodule add -q "$w/subsrc" sub >/dev/null 2>&1
  "$GIT_REEL" -C "$w/repo" commit -q -m addsub
  "$GIT_REEL" -C "$w/repo/sub" config filter.f.clean "$PROGS/SUBCLEAN.sh"
  touch -t "$UNE_MIN" "$w/repo/sub/f.txt"
}
SM="$WORK/sm"; mk_sous_module "$SM"; raz
"$GIT_REEL" --no-optional-locks -c core.fsmonitor=false -C "$SM/repo" status --porcelain=v2 --branch -z -unormal >/dev/null 2>&1
assert_eq "E9.7 — témoin : status brut sur le super-dépôt relance un status DANS le sous-module et y lance le filtre de .git/modules/sub/config" "$(marque SUBCLEAN)" "posé"; raz
R="$(LG "$SM/repo" '{}' status --porcelain=v2 --branch -z -unormal)"
assert_eq "E9.8 — lancerGit status (forme d'etatWorktrees) : le filtre du sous-module n'est pas lancé, status aboutit" "$(marque SUBCLEAN)|$(G "$R" 'j.ok')" "absent|true"; raz
node "$AUX/sh.mjs" "$SCRIPTS" "$SM/repo" "$SM/repo" status --porcelain >/dev/null 2>&1
assert_eq "E9.9 — shBorne status : le filtre du sous-module n'est pas lancé" "$(marque SUBCLEAN)" "absent"; raz
R="$(LGA "$SM/repo" '{}' status --porcelain=v2 --branch -z -unormal)"
assert_eq "E9.10 — lancerGitAsync status : le filtre du sous-module n'est pas lancé, status aboutit" "$(marque SUBCLEAN)|$(G "$R" 'j.ok')" "absent|true"; raz
LG "$SM/repo" '{}' diff --stat >/dev/null 2>&1
assert_eq "E9.11 — lancerGit diff : le filtre du sous-module n'est pas lancé non plus" "$(marque SUBCLEAN)" "absent"; raz
# classe : TOUT status lancé par les trois lanceurs porte --ignore-submodules=all (journal d'argv de l'emballage, quel que soit le dépôt)
: > "$WORK/git.log"
PATH="$WORK/bin:$PATH" LG "$SM/repo" '{}' status --porcelain >/dev/null 2>&1; PATH="$WORK/bin:$PATH" LGA "$SM/repo" '{}' status -s >/dev/null 2>&1
PATH="$WORK/bin:$PATH" node "$AUX/sh.mjs" "$SCRIPTS" "$SM/repo" "$SM/repo" status >/dev/null 2>&1; PATH="$WORK/bin:$PATH" LG "$F1" '{}' status --porcelain=v2 -z >/dev/null 2>&1
NS="$(grep '^ARGV ' "$WORK/git.log" | grep -cE ' status( |$)')"
assert_eq "E9.12 — classe : chaque status lancé (4 lancements : lancerGit, lancerGitAsync, shBorne) porte --ignore-submodules=all dans son argv" "$NS|$(grep '^ARGV ' "$WORK/git.log" | grep -E ' status( |$)' | grep -vc -e '--ignore-submodules=all')" "4|0"

# mutants A1/A2 : chacun remet le défaut et rougit SA sonde de E9, pour la bonne raison
assert_eq "M-PLAFOND.0 — l'ancre du mutant existe (le plafond de 64 filtres est remis)" "$(mutant plafond '.filter(Boolean))],' '.filter(Boolean))].slice(0, 64),')" "muté"
MD="$WORK/mut-plafond"; raz
node "$AUX/lg.mjs" "$MD" "$F70" '{}' status --porcelain >/dev/null 2>&1; A="$(marque F9)"; raz
node "$AUX/lga.mjs" "$MD" "$F70" '{}' status --porcelain >/dev/null 2>&1; B="$(marque F9)"; raz
node "$AUX/sh.mjs" "$MD" "$F70" "$F70" status --porcelain >/dev/null 2>&1; C="$(marque F9)"; raz
assert_eq "M-PLAFOND — rougit E9.1, E9.2 et E9.3 : le 70e filtre n'est plus vidé, son programme est lancé (lancerGit, lancerGitAsync, shBorne)" "$A|$B|$C" "posé|posé|posé"
R="$(node "$AUX/lg.mjs" "$MD" "$F1" '{}' status --porcelain 2>/dev/null)"; assert_eq "M-PLAFOND — témoin : à 1 filtre le mutant reste vert (E9.4 : le rouge vient du plafond, pas d'un module cassé)" "$(marque F9)|$(G "$R" 'j.ok')" "absent|true"; raz
assert_eq "M-BORNE.0 — l'ancre du mutant existe (la borne MAX_FILTRES est retirée)" "$(mutant borne '!fiable || noms.length > MAX_FILTRES' '!fiable')" "muté"
R="$(node "$AUX/lg.mjs" "$WORK/mut-borne" "$F300" '{}' status --porcelain 2>/dev/null)"; R2="$(node "$AUX/lga.mjs" "$WORK/mut-borne" "$F300" '{}' status --porcelain 2>/dev/null)"
assert_eq "M-BORNE — rougit E9.5 : à 300 filtres le mutant lance status (ok=true, plus de refus)" "$(G "$R" '[j.ok,j.refuse].join(":")')|$(G "$R2" '[j.ok,j.refuse].join(":")')" "true:|true:"; raz
assert_eq "M-FIABLE.0 — l'ancre du mutant existe (la liste illisible n'est plus un refus)" "$(mutant fiable '!fiable || noms.length > MAX_FILTRES' 'noms.length > MAX_FILTRES')" "muté"
PATH="$WORK/bin-cfg:$PATH" node "$AUX/lg.mjs" "$WORK/mut-fiable" "$F70" '{}' status --porcelain >/dev/null 2>&1
assert_eq "M-FIABLE — rougit E9.6 : liste illisible, le mutant lance status et le programme du 70e filtre" "$(marque F9)" "posé"; raz
assert_eq "M-SOUS-MODULES.0 — l'ancre du mutant existe (status n'ignore plus les sous-modules)" "$(mutant sousmod "status: [IGNORER_SOUS_MODULES] };" "status: [] };")" "muté"
MD="$WORK/mut-sousmod"
node "$AUX/lg.mjs" "$MD" "$SM/repo" '{}' status --porcelain=v2 --branch -z -unormal >/dev/null 2>&1
assert_eq "M-SOUS-MODULES — rougit E9.8 : le status du mutant relance le filtre du sous-module" "$(marque SUBCLEAN)" "posé"; raz
: > "$WORK/git.log"; PATH="$WORK/bin:$PATH" node "$AUX/lg.mjs" "$MD" "$SM/repo" '{}' status --porcelain >/dev/null 2>&1; PATH="$WORK/bin:$PATH" node "$AUX/lga.mjs" "$MD" "$SM/repo" '{}' status -s >/dev/null 2>&1
assert_eq "M-SOUS-MODULES — rougit aussi E9.12 : les status du mutant ne portent plus l'option (2 lancements, 2 sans option)" "$(grep '^ARGV ' "$WORK/git.log" | grep -E ' status( |$)' | grep -vc -e '--ignore-submodules=all')" "2"

echo "=== E10 — revue serveur 2026-11-06 (R6, S9) : le moteur d'assemblage ne lit pas git quand la liste des filtres est illisible ou au-delà de la borne ==="
# même règle fail-closed que A1 (lancerGit, shBorne) : l'environnement du moteur ne reçoit le marqueur VF_COCKPIT_GIT_DURCI que si la liste est lisible et bornée ; sinon git du moteur reste fermé
# (carte sans fichiers suivis ni head, mention explicite dans le résumé), jamais « les filtres inconnus ne sont pas vidés ».
LAB10="$WORK/lab10"; cp -R "$P" "$LAB10"; printf "export const un = 1;\n" > "$LAB10/m.js"; "$GIT_REEL" -C "$LAB10" add m.js; "$GIT_REEL" -C "$LAB10" commit -q -m m
HEAD10="$("$GIT_REEL" -C "$LAB10" rev-parse HEAD)"; touch -t "$UNE_MIN" "$LAB10/f.txt"
b10() { rm -rf "$LAB10/.vibeflow"; raz; "$@" node "$BUILD" "$LAB10" > "$WORK/b10.out" 2>&1; }
marques10() { for m in PROC CLEAN; do marque $m; done | sort -u | tr '\n' ' '; }
b10 env; TETE="$(node "$AUX/tete.mjs" "$LAB10/.vibeflow/cockpit/graph.json" 2>/dev/null || echo illisible)"
assert_eq "E10.0 — témoin : liste lisible (1 filtre) : le moteur lit git (head réel), aucun programme du dépôt lancé, aucune mention de git fermé" "$TETE|$(marques10)|$(grep -c 'git du moteur fermé' "$WORK/b10.out")" "$HEAD10|absent |0"
b10 env PATH="$WORK/bin-cfg:$PATH"; TETE="$(node "$AUX/tete.mjs" "$LAB10/.vibeflow/cockpit/graph.json" 2>/dev/null || echo illisible)"
assert_eq "E10.1 — liste des filtres illisible (git config --get-regexp rend 2) : aucun programme du dépôt lancé par le moteur, git du moteur fermé (aucun head), la carte est écrite" "$(marques10)|$TETE|$([ -s "$LAB10/.vibeflow/cockpit/graph.json" ] && echo carte || echo sans-carte)" "absent |aucun|carte"
assert_eq "E10.2 — l'état dégradé est dit : le résumé de l'assemblage nomme git du moteur fermé et la cause (liste illisible)" "$(grep -c 'git du moteur fermé.*illisible' "$WORK/b10.out")" "1"
# plus de MAX_FILTRES (256) filtres déclarés : même fermeture, sans emballage
{ for i in $(seq 1 300); do printf '[filter "g%s"]\n\tclean = cat\n' "$i"; done; } >> "$LAB10/.git/config"
b10 env; TETE="$(node "$AUX/tete.mjs" "$LAB10/.vibeflow/cockpit/graph.json" 2>/dev/null || echo illisible)"
assert_eq "E10.3 — 301 filtres déclarés (au-delà de 256) : git du moteur fermé (aucun head), aucun programme lancé, la cause nomme la borne" "$(marques10)|$TETE|$(grep -c 'git du moteur fermé.*256' "$WORK/b10.out")" "absent |aucun|1"
# mutant : la fermeture est retirée (le moteur reçoit toujours le marqueur) — E10.1 et E10.3 rougissent pour leur raison
MS9="$WORK/mut-s9"; rm -rf "$MS9"; mkdir -p "$MS9/scripts" "$MS9/skills"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$MS9/scripts/"; cp -R "$MOTEUR" "$MS9/skills/cockpit-moteur"
assert_eq "M-S9.0 — l'ancre du mutant existe dans vf-cockpit-build.mjs (la fermeture du moteur est retirée)" "$(FROM="if (!f.refus)" TO="if (true)" node "$AUX/mutsub.mjs" "$MS9/scripts/vf-cockpit-build.mjs" 2>&1)" "muté"
rm -rf "$LAB10/.vibeflow"; raz; PATH="$WORK/bin-cfg:$PATH" node "$MS9/scripts/vf-cockpit-build.mjs" "$LAB10" > "$WORK/b10m.out" 2>&1; TETEM="$(node "$AUX/tete.mjs" "$LAB10/.vibeflow/cockpit/graph.json" 2>/dev/null || echo illisible)"
assert_eq "M-S9 — sans la fermeture, E10.1 et E10.3 rougissent : le moteur lit git (head réel) alors que la liste est illisible ou trop longue" "$TETEM|$(grep -c 'git du moteur fermé' "$WORK/b10m.out")" "$HEAD10|0"

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
