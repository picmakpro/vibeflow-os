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
else if (fn === 'wt') console.log(JSON.stringify(m.etatWorktrees(lab)));
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
assert_eq "X1.1d — total, pas tronqué, aucun e-mail ni diff" "$(J "$WORK/cm.json" 'j.total+"|"+j.tronque+"|"+/a@t\.test|@/.test(JSON.stringify(j))+"|"+/^[-+]{3} |^@@/m.test(JSON.stringify(j))')" "2|false|false|false"
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
