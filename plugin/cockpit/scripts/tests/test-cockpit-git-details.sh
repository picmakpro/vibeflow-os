#!/usr/bin/env bash
# test-cockpit-git-details.sh — détail d'un commit sans diff (GET /api/vf/git/commit?sha=) et état des worktrees à la demande (GET /api/vf/git/worktrees)
#   (GITC-07, GITC-08, GITC-09 ; P78-D-06, D-13, D-14, D-21, D-23, D-31)
#   X1 détail d'un commit : validation du sha (motif strict puis rev-parse --verify), fichiers, binaires, renommages, racine, merge, bornes
#   X2 état des worktrees · X3 dépôt piégé (aucun filtre lancé), lecture seule, GET seul · X4 mutants · X5 ref sans date (P78-D-31), auteurs de la fenêtre
# Dépôts fabriqués dans mktemp (dates de commit fixées, aucun dépôt distant). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
GIT_REEL="$(command -v git)"
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }

# --- outils node écrits par la suite ---
# req.mjs <port> <méthode> <chemin> <jeton|-> <origin|-> : ligne 1 = statut, puis le corps
cat > "$AUX/req.mjs" <<'JS'
import http from 'node:http';
const [, , port, methode, p, token, origin] = process.argv;
const headers = { Host: `127.0.0.1:${port}`, ...(token !== '-' ? { 'x-vf-cockpit-token': token } : {}), ...(origin !== '-' ? { Origin: origin } : {}) };
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method: methode, headers }, (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => { console.log(res.statusCode); process.stdout.write(b); }); });
r.on('error', (e) => console.log('ERR ' + e.message)); r.end();
JS
cat > "$AUX/token.mjs" <<'JS'
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
# j.mjs <fichier|-> <expression sur j> : JSON lu dans le fichier, expression évaluée
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2] === '-' ? 0 : process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
# det.mjs <scripts> <commit|wt|git|route> <lab> [arg] : JSON du module chargé depuis <scripts> (copie de mutant possible)
cat > "$AUX/det.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, fn, lab, arg] = process.argv;
let m, g;
try { m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git-details.mjs')).href); } catch { console.log(JSON.stringify({ erreur: 'module absent' })); process.exit(0); }
if (fn === 'commit') console.log(JSON.stringify(m.detailCommit(lab, arg)));
else if (fn === 'wt') console.log(JSON.stringify(await m.etatWorktrees(lab)));
else if (fn === 'git') { g = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href); console.log(JSON.stringify(g.lireGit(lab))); }
else if (fn === 'status') console.log(JSON.stringify(m.lireStatusV2(arg, { max: 200 })));
JS
# route.mjs <scripts> <méthode> <chemin> <lab> : appelle routeGit avec un faux req/res ; rend « traité|statut »
cat > "$AUX/route.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, methode, p, lab] = process.argv;
let m; try { m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href); } catch { console.log('module absent'); process.exit(0); }
let statut = null; const res = { writeHead: (c) => { statut = c; }, end: () => {} };
const traite = m.routeGit({ method: methode }, res, new URL('http://x' + p), { root: lab, json: (r, c) => { statut = c; } });
console.log(traite + '|' + statut);
JS
# empreinte.mjs <dossier> : une ligne par fichier (chemin, taille, date), triée — lue en Node, jamais par stat ou find
cat > "$AUX/empreinte.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
const lignes = [];
const parcourir = (d) => { for (const e of fs.readdirSync(d)) { const p = path.join(d, e), s = fs.lstatSync(p); if (s.isDirectory()) parcourir(p); else lignes.push(`${path.relative(process.argv[2], p)} ${s.size} ${s.mtimeMs}`); } };
parcourir(process.argv[2]);
console.log(lignes.sort().join('\n'));
JS
# mut.mjs <fichier> <de> <vers> : remplace UNE occurrence exacte (rend « absent » si le motif n'existe plus : un mutant sans cible ne compte pas)
cat > "$AUX/mut.mjs" <<'JS'
import fs from 'node:fs';
const [, , f, de, vers] = process.argv;
const t = fs.readFileSync(f, 'utf8');
if (!t.includes(de)) { console.log('absent'); process.exit(0); }
fs.writeFileSync(f, t.replace(de, () => vers)); console.log('applique');
JS

# --- fixture : un dépôt à historique varié ---
T=0
tick() { T=$((T+1)); export GIT_AUTHOR_DATE="@$((1700000000+T*60)) +0000" GIT_COMMITTER_DATE="@$((1700000000+T*60)) +0000"; }
LAB="$WORK/lab"; mkdir -p "$LAB"
G() { "$GIT_REEL" -C "$LAB" "$@"; }
G init -q -b main
printf 'l1\nl2\nl3\n' > "$LAB/a.txt"; printf 'o1\no2\no3\no4\no5\n' > "$LAB/old.txt"
G add -A; tick; G commit -q -m "c0 racine"; C0="$(G rev-parse HEAD)"
printf 'l1\nL2\nl3\nl4\nl5\n' > "$LAB/a.txt"; printf 'n1\n' > "$LAB/new.txt"
G add -A; tick; G commit -q -m "sujet" -m "corps ligne 2"; C1="$(G rev-parse HEAD)"
printf 'a\0b\n' > "$LAB/img.bin"; G mv old.txt renamed.txt
G add -A; tick; G commit -q -m "c2 binaire et renommage"; C2="$(G rev-parse HEAD)"
G checkout -q -b f; printf 'f1\nf2\n' > "$LAB/f.txt"; G add -A; tick; G commit -q -m "f1"
G checkout -q main; printf 'm1\n' > "$LAB/m.txt"; G add -A; tick; G commit -q -m "m1"; M1="$(G rev-parse HEAD)"
tick; G merge -q --no-ff f -m "merge f"; MG="$(G rev-parse HEAD)"
# message de 10 Kio
node -e "process.stdout.write('sujet long\n\n' + ('x'.repeat(79) + '\n').repeat(128))" > "$WORK/msg10k.txt"
tick; G commit -q --allow-empty -F "$WORK/msg10k.txt"; CMSG="$(G rev-parse HEAD)"
# 600 fichiers
mkdir -p "$LAB/many"; for i in $(seq 1 600); do printf 'x%s\n' "$i" > "$LAB/many/f$(printf '%03d' "$i").txt"; done
G add -A; tick; G commit -q -m "600 fichiers"; CMANY="$(G rev-parse HEAD)"
G tag v1 "$C1"; tick; G tag -a ann -m annotee "$C1"
TREE="$(G rev-parse "$CMANY^{tree}")"; BLOB="$(G rev-parse "$C1:a.txt")"; TAGOBJ="$(G rev-parse ann)"
assert_eq "X0.1 — fixture : racine, merge à 2 parents, tag annoté distinct du commit" "$(G rev-list --count --max-parents=0 HEAD)|$(G rev-list --count --min-parents=2 HEAD)|$([ "$TAGOBJ" != "$C1" ] && echo distinct)" "1|1|distinct"

# --- serveur réel sur le lab (un lab GSD : .planning ; ni lui ni la sortie du build ne comptent comme non suivis) ---
mkdir -p "$LAB/.planning/phases/01-x"; printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
printf '.planning\n.vibeflow\n' >> "$LAB/.git/info/exclude"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"
node "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
SRV=$!
for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
PORT=$(node "$AUX/j.mjs" "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)
TOK=$(node "$AUX/token.mjs" "$PORT" /)
assert_eq "X0.2 — serveur démarré, jeton lu dans la page" "$([ "$PORT" -gt 0 ] && [ "${#TOK}" -ge 16 ] && echo oui || echo non)" "oui"
GET() { node "$AUX/req.mjs" "$PORT" GET "$1" "$TOK" - ; }
CM() { GET "/api/vf/git/commit?sha=$1" > "$WORK/cm.out"; sed -n '2,$p' "$WORK/cm.out" > "$WORK/cm.json"; sed -n 1p "$WORK/cm.out"; } # statut ; corps dans cm.json

echo "=== X1 — détail d'un commit ==="
S="$(CM "$C1")"
assert_eq "X1.1a — commit ordinaire : 200, schéma, état, sha, h7" "$S|$(J "$WORK/cm.json" 'j.schema+"|"+j.etat+"|"+(j.h==="'"$C1"'")+"|"+(j.h7==="'"${C1:0:7}"'")')" "200|vibeflow/cockpit-git-commit@1|ok|true|true"
assert_eq "X1.1b — auteur, date ISO, message entier, un parent" "$(J "$WORK/cm.json" 'j.auteur+"|"+/^\d{4}-\d\d-\d\dT/.test(j.date)+"|"+JSON.stringify(j.message)+"|"+j.p.length')" 'Alice|true|"sujet\n\ncorps ligne 2"|1'
assert_eq "X1.1c — fichiers touchés avec + et − exacts" "$(J "$WORK/cm.json" 'JSON.stringify(j.fichiers.map(f=>[f.chemin,f.ancien,f.plus,f.moins,f.binaire]))')" '[["a.txt",null,3,1,false],["new.txt",null,1,0,false]]'
assert_eq "X1.1d — total, pas tronqué, aucun e-mail ni diff" "$(J "$WORK/cm.json" 'j.total+"|"+j.tronque+"|"+/a@t\.test|[^\s"]@[^\s"]/.test(JSON.stringify({...j,schema:""}))+"|"+/^[-+]{3} |^@@/m.test(JSON.stringify(j))')" "2|false|false|false"
assert_eq "X1.1e — commandes à copier (P78-D-14 : formes de 78-03)" "$(J "$WORK/cm.json" 'j.commandes.show+"|"+j.commandes.detacher')" "git show --stat --end-of-options ${C1:0:7}|git switch --detach --end-of-options ${C1:0:7}"

echo "=== X1.2 — le sha : motif strict puis rev-parse --verify ==="
# 400 sha-invalide : rien d'autre qu'un sha complet en minuscules n'est accepté (HEAD, v1 et un sha court de 12 caractères existent bel et bien)
UPPER="$(printf '%s' "$C1" | tr 'a-f' 'A-F')"
check400() { local nom="$1" q="$2"; S="$(CM "$q")"; assert_eq "X1.2 — $nom : 400 sha-invalide" "$S|$(J "$WORK/cm.json" 'j.etat')" "400|sha-invalide"; }
check400 "sha court de 12 caractères (existe : rev-parse --verify l'accepterait)" "${C1:0:12}"
check400 "sha en majuscules" "$UPPER"
check400 "HEAD (existe)" "HEAD"
check400 "v1 (le tag existe)" "v1"
check400 "--all" "--all"
check400 "-x" "-x"
check400 "sha suivi d'une espace" "$C1%20"
check400 "sha de 41 caractères" "${C1}0"
check400 "paramètre vide" ""
GET "/api/vf/git/commit" > "$WORK/cm0.out"
assert_eq "X1.2 — paramètre sha absent : 400 sha-invalide" "$(sed -n 1p "$WORK/cm0.out")|$(sed -n '2,$p' "$WORK/cm0.out" | node "$AUX/j.mjs" - 'j.etat')" "400|sha-invalide"
# 404 commit-inconnu : forme valide, mais pas un commit, ou un objet qui n'est pas lui-même le commit (rev-parse --verify <tag>^{commit} pèle jusqu'au commit)
check404() { local nom="$1" q="$2"; S="$(CM "$q")"; assert_eq "X1.2 — $nom : 404 commit-inconnu" "$S|$(J "$WORK/cm.json" 'j.etat')" "404|commit-inconnu"; }
check404 "0000…0" "0000000000000000000000000000000000000000"
check404 "sha d'un arbre" "$TREE"
check404 "sha d'un blob" "$BLOB"
check404 "sha d'un tag annoté (pèle vers un commit : ce n'est pas le même sha)" "$TAGOBJ"
check404 "sha inexistant bien formé" "1234567890123456789012345678901234567890"

echo "=== X1.3 à X1.5 — binaire, renommage, racine, merge, bornes ==="
CM "$C2" > /dev/null
assert_eq "X1.3 — binaire (binaire: true, plus et moins nuls) et renommage (ancien et nouveau chemin)" "$(J "$WORK/cm.json" 'JSON.stringify(j.fichiers.map(f=>[f.chemin,f.ancien,f.plus,f.moins,f.binaire]))')" '[["img.bin",null,null,null,true],["renamed.txt","old.txt",0,0,false]]'
CM "$C0" > /dev/null
assert_eq "X1.4a — commit racine : fichiers de --root, aucun parent" "$(J "$WORK/cm.json" 'JSON.stringify(j.fichiers.map(f=>[f.chemin,f.plus,f.moins]))+"|"+j.p.length')" '[["a.txt",3,0],["old.txt",5,0]]|0'
S="$(CM "$MG")"
assert_eq "X1.4b — merge --no-ff : fichiers contre le PREMIER parent seulement (f.txt, pas m.txt), deux parents" "$S|$(J "$WORK/cm.json" 'JSON.stringify(j.fichiers.map(f=>f.chemin))+"|"+j.p.length+"|"+(j.p[0]==="'"$M1"'")')" '200|["f.txt"]|2|true'
CM "$CMSG" > /dev/null
assert_eq "X1.5a — message de 10 Kio : tronque vrai, au plus 8192 octets, début conservé" "$(J "$WORK/cm.json" 'j.tronque+"|"+(Buffer.byteLength(j.message)<=8192)+"|"+(Buffer.byteLength(j.message)>8000)+"|"+j.message.startsWith("sujet long")')" "true|true|true|true"
CM "$CMANY" > /dev/null
assert_eq "X1.5b — 600 fichiers : 500 lus, total 600" "$(J "$WORK/cm.json" 'j.fichiers.length+"|"+j.total')" "500|600"

echo "=== X1.6 — le contrat du schéma tient contre la réponse réelle ==="
CM "$C2" > /dev/null
CONTRAT_C="$(node "$AUX/j.mjs" "$SCRIPTS/vf-cockpit-interface.json" 'JSON.stringify(j.schemas["vibeflow/cockpit-git-commit@1"])')"
assert_eq "X1.6a — chaque clé « requis » du schéma commit existe dans la réponse avec le bon type, chaque fichier porte ses clés" "$(J "$WORK/cm.json" '(()=>{const c='"$CONTRAT_C"';const ty=(v)=>Array.isArray(v)?"array":v===null?"null":typeof v;const ko=Object.entries(c.requis).filter(([k,t])=>ty(j[k])!==t);const kf=j.fichiers.filter(f=>!c.fichier.requis.every(k=>k in f));return JSON.stringify([ko,kf.length,c.interdits.filter(k=>k in j)])})()')" '[[],0,[]]'

echo "=== X1.7 — dépôt sha256 : le motif suit le format d'objets ==="
S256="$WORK/s256"; "$GIT_REEL" init -q -b main --object-format=sha256 "$S256" 2>/dev/null; S256="$(cd "$S256" && pwd -P)"
tick; "$GIT_REEL" -C "$S256" commit -q --allow-empty -m "c256"; H256="$("$GIT_REEL" -C "$S256" rev-parse HEAD)"
assert_eq "X1.7a — dépôt sha256 : le sha de 64 caractères d'un commit rend 200 ok" "$(node "$AUX/det.mjs" "$SCRIPTS" commit "$S256" "$H256" | node "$AUX/j.mjs" - 'j.code+"|"+j.corps.etat+"|"+(j.corps.h.length)')" "200|ok|64"
assert_eq "X1.7b — dépôt sha1 : un sha de 64 caractères est invalide (400), le motif ne se contente pas de la longueur" "$(node "$AUX/det.mjs" "$SCRIPTS" commit "$LAB" "$H256" | node "$AUX/j.mjs" - 'j.code+"|"+j.corps.etat')" "400|sha-invalide"
assert_eq "X1.7c — dépôt sha256 : un sha de 40 caractères est invalide (400)" "$(node "$AUX/det.mjs" "$SCRIPTS" commit "$S256" "${H256:0:40}" | node "$AUX/j.mjs" - 'j.code+"|"+j.corps.etat')" "400|sha-invalide"

echo "=== X2 — état des worktrees à la demande ==="
GETWT() { GET /api/vf/git/worktrees > "$WORK/wt.out"; sed -n '2,$p' "$WORK/wt.out" > "$WORK/wt.json"; sed -n 1p "$WORK/wt.out"; }
WTS="$WORK/wt-sale"; WTP="$WORK/wt-propre"; WTD="$WORK/wt-det"; WTM="$WORK/wt-many"
G worktree add -q -b ws "$WTS" "$C1"; G worktree add -q -b wp "$WTP" "$C1"; G worktree add -q --detach "$WTD" "$C2"; G worktree add -q -b wm "$WTM" "$C1"
G update-ref refs/remotes/origin/main "$MG" # main local en avance de 2 (le message de 10 Kio, les 600 fichiers) sur origin/main
for f in a.txt old.txt new.txt; do printf 'modif\n' >> "$WTS/$f"; done; printf 'u\n' > "$WTS/u1.txt"; printf 'u\n' > "$WTS/u2.txt"
for i in $(seq 1 250); do printf 'u\n' > "$WTM/nonsuivi$i.txt"; done
oracle() { local oid; oid="$(G rev-parse "$1")"; echo "$(G rev-list --count "refs/heads/main..$oid")|$(G rev-list --count "$oid..refs/heads/main")|$(G rev-list --count "refs/remotes/origin/main..$oid")|$(G rev-list --count "$oid..refs/remotes/origin/main")"; }
WT() { J "$WORK/wt.json" '(()=>{const w=j.worktrees.find(w=>w.nom==="'"$1"'");return w?('"$2"'):"absent"})()'; }
S="$(GETWT)"
assert_eq "X2.1a — GET : 200, schéma, état ok, sans filtre : approximatif faux et aucune mention ; 5 worktrees" "$S|$(J "$WORK/wt.json" 'j.schema+"|"+j.etat+"|"+j.approximatif+"|"+j.mention+"|"+j.worktrees.length')" "200|vibeflow/cockpit-git-worktrees@1|ok|false|null|5"
assert_eq "X2.1b — 3 fichiers modifiés et 2 non suivis : modifies 3, nonSuivis 2, propre faux" "$(WT wt-sale 'w.modifies+"|"+w.nonSuivis+"|"+w.propre+"|"+w.plus')" "3|2|false|false"
assert_eq "X2.1c — worktree propre : 0, 0, propre vrai ; le lab (arbre principal) aussi" "$(WT wt-propre 'w.modifies+"|"+w.nonSuivis+"|"+w.propre')|$(WT lab 'w.propre')" "0|0|true|true"
assert_eq "X2.1d — worktree détaché : présent, avance et retard calculés sur son oid (sur main puis sur origin/main)" "$(WT wt-det 'w.avance+"|"+w.retard+"|"+w.avanceOrigin+"|"+w.retardOrigin')" "$(oracle "$C2")"
assert_eq "X2.2a — arbre principal sur main : 0|0 sur la locale, 2 d'avance sur origin/main (distincts)" "$(WT lab 'w.avance+"|"+w.retard+"|"+w.avanceOrigin+"|"+w.retardOrigin')" "0|0|2|0"
assert_eq "X2.2b — branche ws (en retard de la base) : comptes conformes à rev-list ; retard sur origin/main de 2 de moins que sur main" "$(WT wt-sale 'w.avance+"|"+w.retard+"|"+w.avanceOrigin+"|"+w.retardOrigin+"|"+(w.retard-w.retardOrigin)')" "$(oracle ws)|2"
assert_eq "X2.3 — 250 fichiers non suivis : borne de 200 entrées lues, plus vrai, propre faux, aucun modifié" "$(WT wt-many 'w.nonSuivis+"|"+w.plus+"|"+w.propre+"|"+w.modifies')" "200|true|false|0"
assert_eq "X2.4 — commande à copier : cd cité pour chaque worktree ; aucun diff ni e-mail dans la réponse" "$(WT wt-sale 'w.commande')|$(J "$WORK/wt.json" '/a@t\.test|^[-+]{3} |^@@/m.test(JSON.stringify(j))')" "cd -- '$WTS'|false"
CONTRAT_W="$(node "$AUX/j.mjs" "$SCRIPTS/vf-cockpit-interface.json" 'JSON.stringify(j.schemas["vibeflow/cockpit-git-worktrees@1"]||null)')"
assert_eq "X2.5 — le contrat du schéma worktrees tient contre la réponse réelle (clés, types, clés de chaque worktree)" "$(J "$WORK/wt.json" '(()=>{const c='"$CONTRAT_W"';if(!c)return "schéma absent";const ty=(v)=>Array.isArray(v)?"array":v===null?"null":typeof v;const ko=Object.entries(c.requis).filter(([k,t])=>t!=="any"&&ty(j[k])!==t&&!(t==="string"&&j[k]===null));const kw=j.worktrees.filter(w=>!c.worktree.requis.every(k=>k in w));return JSON.stringify([ko,kw.length])})()')" '[[],0]'

echo "=== X3 — dépôt piégé, lecture seule, GET seul ==="
MARQ="$WORK/marques"; PROGS="$WORK/progs"; mkdir -p "$MARQ" "$PROGS"
raz() { rm -f "$MARQ"/*; }
marque() { if [ -s "$MARQ/$1" ]; then echo posé; else echo absent; fi; }
mk_prog() { printf '#!/bin/sh\necho "$0 $*" >> "%s/%s"\n%s\n' "$MARQ" "$1" "${2:-exit 0}" > "$PROGS/$1.sh"; chmod +x "$PROGS/$1.sh"; }
mk_prog PROC "exit 1"; mk_prog CLEAN 'cat'; mk_prog TEXTCONV 'cat "$1"'; mk_prog FSM "exit 1"
P="$WORK/piege"; "$GIT_REEL" init -q -b main "$P"; P="$(cd "$P" && pwd -P)"
printf 'f.txt filter=f\n*.bin diff=bin\n' > "$P/.gitattributes"; printf 'contenu\n' > "$P/f.txt"; printf 'a\0b\n' > "$P/a.bin"
"$GIT_REEL" -C "$P" add -A && "$GIT_REEL" -C "$P" commit -q -m "premier"
printf 'a\0c\n' > "$P/a.bin"; "$GIT_REEL" -C "$P" commit -q -am "SUJET-REEL"; HP="$("$GIT_REEL" -C "$P" rev-parse HEAD)"
"$GIT_REEL" -C "$P" config filter.f.clean "$PROGS/CLEAN.sh"; "$GIT_REEL" -C "$P" config filter.f.process "$PROGS/PROC.sh"
"$GIT_REEL" -C "$P" config diff.bin.textconv "$PROGS/TEXTCONV.sh"; "$GIT_REEL" -C "$P" config core.fsmonitor "$PROGS/FSM.sh"
UNE_MIN="$(date -v-1M +%Y%m%d%H%M 2>/dev/null || date -d '1 minute ago' +%Y%m%d%H%M)"; touch -t "$UNE_MIN" "$P/f.txt"
raz
"$GIT_REEL" --no-optional-locks -c core.fsmonitor=false -C "$P" status --porcelain=v2 >/dev/null 2>&1
assert_eq "X3.0a — TÉMOIN POSITIF : git brut avec GIT_SUR seul lance filter.f.process sur le fichier stat-dirty du dépôt piégé" "$(marque PROC)" "posé"; raz
"$GIT_REEL" -C "$P" log -p -1 >/dev/null 2>&1
assert_eq "X3.0b — TÉMOIN POSITIF : git log -p brut lance le textconv déclaré" "$(marque TEXTCONV)" "posé"; raz
# sonde : status des worktrees du dépôt piégé via le module ; rend les marqueurs, puis approximatif et la mention
sonde_filtres() { raz; node "$AUX/det.mjs" "$1" wt "$P" > "$WORK/piege-wt.json"; echo "$(marque PROC)|$(marque CLEAN)|$(marque FSM)"; raz; }
assert_eq "X3.1a — dépôt piégé : GET worktrees ne lance aucun filtre (process, clean) ni fsmonitor" "$(sonde_filtres "$SCRIPTS")" "absent|absent|absent"
assert_eq "X3.1b — dépôt piégé : approximatif vrai et la mention « approximatif : filtres du dépôt non exécutés »" "$(J "$WORK/piege-wt.json" 'j.etat+"|"+j.approximatif+"|"+j.mention')" "ok|true|approximatif : filtres du dépôt non exécutés"
raz; node "$AUX/det.mjs" "$SCRIPTS" commit "$P" "$HP" > "$WORK/piege-commit.json"
assert_eq "X3.3 — détail d'un commit du dépôt piégé (binaire sous textconv déclaré) : 200, le binaire est lu, aucun textconv lancé" "$(J "$WORK/piege-commit.json" 'j.code+"|"+JSON.stringify(j.corps.fichiers.map(f=>[f.chemin,f.binaire]))')|$(marque TEXTCONV)" '200|[["a.bin",true]]|absent'
raz

echo "=== X3.2 — .git intact, GET seul ==="
EMP() { node "$AUX/empreinte.mjs" "$LAB/.git" > "$1"; }
GET "/api/vf/git/worktrees" > /dev/null; GET "/api/vf/git/commit?sha=$C1" > /dev/null
EMP "$WORK/emp-avant"
for _ in 1 2 3 4 5 6 7 8 9 10; do GET "/api/vf/git/worktrees" > /dev/null; GET "/api/vf/git/commit?sha=$CMANY" > /dev/null; done
EMP "$WORK/emp-apres"
assert_eq "X3.2a — empreinte de .git (chemin, taille, date) identique après dix GET de chaque route (cmp -s)" "$(cmp -s "$WORK/emp-avant" "$WORK/emp-apres" && echo identique || echo different)" "identique"
G update-ref refs/heads/temoin-ecriture "$C1"; EMP "$WORK/emp-ecrit"
assert_eq "X3.2b — témoin : une écriture délibérée (update-ref) CHANGE l'empreinte" "$(cmp -s "$WORK/emp-avant" "$WORK/emp-ecrit" && echo identique || echo different)" "different"
G update-ref -d refs/heads/temoin-ecriture
for R in "/api/vf/git/commit?sha=$C1" "/api/vf/git/worktrees"; do
  N="${R%%\?*}"
  assert_eq "X3.2c — $N : POST -> 405" "$(node "$AUX/req.mjs" "$PORT" POST "$R" "$TOK" - | sed -n 1p)" "405"
  assert_eq "X3.2d — $N : Origin tierce -> 403, Origin de la page -> 200 (témoin)" "$(node "$AUX/req.mjs" "$PORT" GET "$R" "$TOK" http://evil.example | sed -n 1p)|$(node "$AUX/req.mjs" "$PORT" GET "$R" "$TOK" "http://127.0.0.1:$PORT" | sed -n 1p)" "403|200"
  assert_eq "X3.2e — $N : sans jeton -> 403" "$(node "$AUX/req.mjs" "$PORT" GET "$R" - - | sed -n 1p)" "403"
done
assert_eq "X3.2f — le code ne contient aucune route POST ni sous-commande d'écriture ni diff contre l'arbre" "$(grep -c "POST\|'add'\|'commit'\|'checkout'\|'reset'\|'-p'\|'--patch'\|%ae\|%ce" "$SCRIPTS/vf-cockpit-git-details.mjs" | tr -d ' ')" "0"

echo "=== X5 — refs sans date (P78-D-31) et auteurs de la fenêtre ==="
RB="$WORK/refs-sans-date"; "$GIT_REEL" init -q -b main "$RB"; RB="$(cd "$RB" && pwd -P)"
RG() { "$GIT_REEL" -C "$RB" "$@"; }
printf 'a\n' > "$RB/a.txt"; RG add -A; tick; RG commit -q -m "r0"; tick; RG checkout -q -b b; printf 'b\n' > "$RB/b.txt"; RG add -A; RG commit -q -m "r1 sur b"; RG checkout -q main
BL="$(echo blob | RG hash-object -w --stdin)"; TR="$(RG rev-parse 'main^{tree}')"
RG tag tblob "$BL"; RG tag ttree "$TR"; RG update-ref refs/remotes/origin/bizarre "$BL"
assert_eq "X5.0 — TÉMOIN POSITIF : for-each-ref rend 3 refs à date vide (tag vers un blob, tag vers un arbre, distante vers un blob)" "$(RG for-each-ref --format='%(creatordate:unix)|%(refname)' | grep -c '^|')" "3"
assert_eq "X5.1a — dépôt avec refs sans date : la lecture reste ok (pas indisponible), refsIgnorees 3" "$(node "$AUX/det.mjs" "$SCRIPTS" git "$RB" | node "$AUX/j.mjs" - 'j.etat+"|"+j.refsIgnorees')" "ok|3"
assert_eq "X5.1b — le reste du graphe est gardé : 2 rangées, la branche b figure dans parBranche et la non mergée dans horsFenetre ou le graphe, aucun tag servi" "$(node "$AUX/det.mjs" "$SCRIPTS" git "$RB" | node "$AUX/j.mjs" - 'j.rangees.length+"|"+j.parBranche.map(x=>x.nom).sort().join(",")+"|"+j.tags.length')" "2|b,main|0"
assert_eq "X5.1c — un dépôt sans ref sans date : refsIgnorees 0" "$(node "$AUX/det.mjs" "$SCRIPTS" git "$LAB" | node "$AUX/j.mjs" - 'j.etat+"|"+j.refsIgnorees')" "ok|0"
# auteurs : agrégés sur la fenêtre lue (500 commits de la base), pas sur tout l'historique
AU="$WORK/auteurs"; "$GIT_REEL" init -q -b main "$AU"; AU="$(cd "$AU" && pwd -P)"
node -e '
let s = "";
const au = (nom, t, n) => { s += "commit refs/heads/main\nauthor " + nom + " <" + nom + "@t.test> " + t + " +0000\ncommitter " + nom + " <" + nom + "@t.test> " + t + " +0000\ndata 3\nmsg\n"; if (n === 0) s += "M 644 inline f.txt\ndata 1\nx\n"; s += "\n"; };
au("Ancien", 1700000000, 0);
for (let i = 1; i <= 510; i++) au("Recent", 1700000000 + i * 60, i);
process.stdout.write(s);
' | "$GIT_REEL" -C "$AU" fast-import --quiet
assert_eq "X5.2a — fixture : 511 commits, 2 auteurs dans tout l'historique" "$("$GIT_REEL" -C "$AU" rev-list --count main)|$("$GIT_REEL" -C "$AU" log --format=%an | sort -u | tr '\n' ',')" "511|Ancien,Recent,"
assert_eq "X5.2b — auteurs = ceux de la FENÊTRE lue (500 commits) : Ancien (hors fenêtre) n'y est pas, Recent y est avec 500 ; bornes.tronque vrai" "$(node "$AUX/det.mjs" "$SCRIPTS" git "$AU" | node "$AUX/j.mjs" - 'JSON.stringify(j.auteurs.map(a=>[a.nom,a.commits]))+"|"+j.bornes.tronque')" '[["Recent",500]]|true'
assert_eq "X5.2c — le contrat le dit : la description du schéma précise que les auteurs sont ceux de la fenêtre lue, pas de tout l'historique" "$(node "$AUX/j.mjs" "$SCRIPTS/vf-cockpit-interface.json" '/auteurs[^.]*fenêtre[^.]*pas[^.]*historique/.test(j.schemas["vibeflow/cockpit-git@1"].description)')" "true"

echo "=== X4 — mutants (copies des scripts, jamais le module) ==="
mutant_dir() { local d="$WORK/m-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/"; echo "$d"; }
muter() { node "$AUX/mut.mjs" "$@"; }
sonde_motif()    { node "$AUX/det.mjs" "$1" commit "$LAB" "${C1:0:12}" | node "$AUX/j.mjs" - 'j.code ?? j.erreur'; }
sonde_motif64()  { node "$AUX/det.mjs" "$1" commit "$LAB" "$H256" | node "$AUX/j.mjs" - 'j.code ?? j.erreur'; }
sonde_verify()   { node "$AUX/det.mjs" "$1" commit "$LAB" "$TREE" | node "$AUX/j.mjs" - 'j.code ?? j.erreur'; }
sonde_pp()       { node "$AUX/det.mjs" "$1" commit "$LAB" "$MG" | node "$AUX/j.mjs" - 'j.corps ? JSON.stringify(j.corps.fichiers.map(f=>f.chemin)) : j.erreur'; }
sonde_borne()    { node "$AUX/det.mjs" "$1" commit "$LAB" "$CMANY" | node "$AUX/j.mjs" - 'j.corps ? j.corps.fichiers.length : j.erreur'; }
sonde_ignorees() { node "$AUX/det.mjs" "$1" git "$RB" | node "$AUX/j.mjs" - 'j.etat+"|"+j.refsIgnorees'; }
verifie() { # nom, sonde, attendu réel, dossier du mutant : la sonde est verte sur l'original, ROUGE sur le mutant, et le mutant se charge (un module cassé ne compte pas)
  local nom="$1" sonde="$2" att="$3" d="$4" obt; obt="$($sonde "$d")"
  assert_eq "X4 $nom — la sonde est verte sur l'original" "$($sonde "$SCRIPTS")" "$att"
  if [ "$obt" != "$att" ] && [ "$obt" != "module absent" ] && [ "$obt" != "illisible" ]; then assert_eq "X4 $nom — rouge sur le mutant (obtenu : $obt)" "rouge" "rouge"; else assert_eq "X4 $nom — rouge sur le mutant (obtenu : $obt)" "$obt" "différent de [$att] et chargeable"; fi
}
D="$(mutant_dir motif)"; DET="$D/vf-cockpit-git-details.mjs"
A1="$(muter "$DET" "if (typeof sha !== 'string' || !motifLong(sha)) return invalide;" "if (typeof sha !== 'string') return invalide;")"
A2="$(muter "$DET" "if (!MOTIF(fmt.sortie.trim() === 'sha256' ? 64 : 40).test(sha)) return invalide;" "")"
assert_eq "X4 M-MOTIF — le motif est retiré des deux endroits (cibles présentes)" "$A1|$A2" "applique|applique"
verifie "M-MOTIF (sha court)" sonde_motif 400 "$D"
verifie "M-MOTIF (64 caractères dans un dépôt sha1)" sonde_motif64 400 "$D"
D="$(mutant_dir verify)"
A="$(muter "$D/vf-cockpit-git-details.mjs" "if (v.sortie.trim() !== sha) return { code: 404, corps: { schema: SCHEMA_COMMIT, etat: 'commit-inconnu' } };" "")"
assert_eq "X4 M-VERIFY — rev-parse --verify retiré (cible présente)" "$A" "applique"
verifie "M-VERIFY (sha d'un arbre)" sonde_verify 404 "$D"
D="$(mutant_dir pp)"
A="$(muter "$D/vf-cockpit-git-details.mjs" '[`${sha}^1`, sha]' "['-m', sha]")"
assert_eq "X4 M-PREMIER-PARENT — « -m » au lieu de « <sha>^1 » (cible présente)" "$A" "applique"
verifie "M-PREMIER-PARENT" sonde_pp '["f.txt"]' "$D"
D="$(mutant_dir borne)"
A="$(muter "$D/vf-cockpit-git-details.mjs" "if (fichiers.length < max)" "if (true)")"
assert_eq "X4 M-BORNE-FICHIERS — borne de 500 retirée (cible présente)" "$A" "applique"
verifie "M-BORNE-FICHIERS" sonde_borne 500 "$D"
D="$(mutant_dir filtres)"
A="$(muter "$D/vf-cockpit-git-details.mjs" "const st = await lancerGitAsync(w.chemin, ['status', '--porcelain=v2', '--branch', '-z', '-unormal'], { lab, maxBuffer: 1 << 20, fin });" "const st = (() => { try { return { ok: true, sortie: process.getBuiltinModule('node:child_process').execFileSync('git', ['--no-optional-locks', '-c', 'core.fsmonitor=false', '-C', w.chemin, 'status', '--porcelain=v2', '--branch', '-z', '-unormal'], { encoding: 'utf8' }) }; } catch { return { ok: false, sortie: '' }; } })();")"
assert_eq "X4 M-FILTRES-STATUS — status lancé hors lancerGit, GIT_SUR seul (cible présente)" "$A" "applique"
verifie "M-FILTRES-STATUS" sonde_filtres "absent|absent|absent" "$D"
D="$(mutant_dir ignorees)"
A="$(muter "$D/vf-cockpit-git.mjs" "f[3] === ''" "false")"
assert_eq "X4 M-IGNOREES — les refs sans date ne sont plus écartées (cible présente)" "$A" "applique"
verifie "M-IGNOREES" sonde_ignorees "ok|3" "$D"

echo "=== X6 — P78-D-32 : la lecture des worktrees ne bloque pas la boucle du serveur ==="
# git emballé : `status` dort 0,4 s (5 worktrees : lecture de plus de 1,5 s), tout le reste passe tel quel ; le PATH absolu du wrapper est conservé par l'environnement assaini
WRAP="$WORK/wrap-git"; mkdir -p "$WRAP"
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = status ] && sleep 0.4; done\nexec "%s" "$@"\n' "$GIT_REEL" > "$WRAP/git"; chmod +x "$WRAP/git"
# lat.mjs <scripts> <lab> : serveur http en processus avec le VRAI routeGit des <scripts> ; la lecture des worktrees part, 150 ms plus tard une requête légère ; rend « légère terminée avant la lourde | état | lourde lente »
cat > "$AUX/lat.mjs" <<'JS'
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href);
const json = (res, code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(obj)); };
const srv = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  if (url.pathname === '/legere') { res.end('ok'); return; }
  if (!m.routeGit(req, res, url, { root: lab, json })) { res.writeHead(404); res.end(); }
}).listen(0, '127.0.0.1', async () => {
  const port = srv.address().port, t0 = Date.now();
  const get = (p) => new Promise((ok) => http.get({ host: '127.0.0.1', port, path: p }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => ok({ ms: Date.now() - t0, b })); }));
  const lourde = get('/api/vf/git/worktrees');
  await new Promise((r) => setTimeout(r, 150));
  const legere = await get('/legere');
  const l = await lourde;
  let etat = 'illisible'; try { etat = JSON.parse(l.b).etat; } catch {}
  console.log(`${legere.ms < l.ms}|${etat}|${l.ms >= 1500}`);
  srv.close(); process.exit(0);
});
JS
LAT() { PATH="$WRAP:$PATH" node "$AUX/lat.mjs" "$1" "$LAB" 2>&1 | tail -1; }
assert_eq "X6.1 — pendant une lecture lente des worktrees (git emballé : > 1,5 s), une requête légère est servie AVANT la fin de la lecture ; la lecture aboutit (état ok)" "$(LAT "$SCRIPTS")" "true|ok|true"
D="$(mutant_dir sync)"
A1="$(muter "$D/vf-cockpit-git-details.mjs" "lancerGitAsync, " "")"
A2="$(muter "$D/vf-cockpit-git-details.mjs" "export const BORNES_DETAILS" "const lancerGitAsync = async (...a) => lancerGit(...a); // MUTANT : appel git synchrone
export const BORNES_DETAILS")"
assert_eq "X6.2 — M-SYNC : le git de la lecture des worktrees redevient synchrone (cibles présentes)" "$A1|$A2" "applique|applique"
assert_eq "X6.2 — M-SYNC : la requête légère n'est servie qu'APRÈS la lecture (légère avant lourde : false), la lecture aboutit et elle est lente (le rouge vient de l'ordre, pas d'un module cassé)" "$(LAT "$D")" "false|ok|true"

# --- FIN ---
stop_srv
vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
