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

echo "=== E6 — garde : aucun appel git hors de vf-cockpit-paths.mjs ==="
# garde.mjs <dossier> : « fichier:ligne » de chaque appel execFileSync, execFile, spawnSync, spawn, exec ou execSync dont le premier argument est git (littéral ou identifiant), hors vf-cockpit-paths.mjs
cat > "$AUX/garde.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
const dir = process.argv[2];
const RE = /\b(?:execFileSync|execFile|spawnSync|spawn|execSync|exec)\(\s*(?:['"`]git\b|git\b|GIT\b)/;
for (const f of fs.readdirSync(dir).filter((x) => x.endsWith('.mjs') && x !== 'vf-cockpit-paths.mjs').sort())
  fs.readFileSync(path.join(dir, f), 'utf8').split('\n').forEach((l, i) => { if (RE.test(l)) console.log(`${f}:${i + 1}`); });
JS
GARDE="$(node "$AUX/garde.mjs" "$SCRIPTS")"
assert_eq "E6.1 — aucun script du module (hors vf-cockpit-paths.mjs) ne lance git lui-même" "${GARDE:-aucun}" "aucun"
NBF="$(ls "$SCRIPTS"/*.mjs | wc -l | tr -d ' ')"
assert_eq "E6.1a — la garde a bien ouvert des fichiers (plus de 30 scripts balayés, pas un dossier vide)" "$([ "$NBF" -gt 30 ] && echo oui || echo "non:$NBF")" "oui"
for fn in execFileSync execFile spawnSync spawn exec execSync; do
  PL="$WORK/plante-$fn"; mkdir -p "$PL"
  printf "import cp from 'node:child_process';\ncp.%s('git', ['status']);\n" "$fn" > "$PL/vf-cockpit-intrus.mjs"
  assert_eq "E6.2 — témoin : un appel $fn('git', …) planté exprès rend la garde rouge" "$(node "$AUX/garde.mjs" "$PL")" "vf-cockpit-intrus.mjs:2"
done
PL="$WORK/plante-identifiant"; mkdir -p "$PL"; printf "const git = 'git';\nexecFileSync(git, ['log']);\n" > "$PL/vf-cockpit-intrus.mjs"
assert_eq "E6.3 — témoin : un appel dont le premier argument est l'identifiant git rend aussi la garde rouge" "$(node "$AUX/garde.mjs" "$PL")" "vf-cockpit-intrus.mjs:2"
PL="$WORK/plante-paths"; mkdir -p "$PL"; printf "import cp from 'node:child_process';\ncp.execFileSync('git', ['status']);\n" > "$PL/vf-cockpit-paths.mjs"
assert_eq "E6.4 — l'exemption est celle de vf-cockpit-paths.mjs et d'aucun autre fichier (le point d'injection)" "$(node "$AUX/garde.mjs" "$PL")" ""

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
assert_has "M-LECTURE — rougit aussi E2.4b : la sortie gpg de log.showSignature s'ajoute au hash" "$(sig_mut "$MD")" "SORTIE-GPG-FACTICE"

# M-TRONQUE : ENOBUFS ignoré -> E4.2 ne voit plus la troncature
assert_eq "M-TRONQUE.0 — l'ancre du mutant existe" "$(mutant tronque "tronque: e.code === 'ENOBUFS'" "tronque: false && e.code === 'ENOBUFS'")" "muté"
MD="$WORK/mut-tronque"
RM="$(node "$AUX/lg.mjs" "$MD" "$P" '{"maxBuffer":64}' log --format=%H%n%H%n%H 2>/dev/null)"
assert_eq "M-TRONQUE — rougit E4.2 : la troncature n'est plus signalée (tronque=false)" "$(G "$RM" 'j.tronque')" "false"

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
