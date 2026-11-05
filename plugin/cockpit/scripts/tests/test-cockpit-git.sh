#!/usr/bin/env bash
# test-cockpit-git.sh — route GET /api/vf/git (topologie du tiroir Git, lecture seule) et GET /api/vf/git/entete (GITC-05, 06, 08, 09, 10 ; P78-D-05, 07, 13, 14, 23, 24)
#   S1 serveur réel : route, schéma, octopus, GET seul (POST 405, Origin tierce 403, sans jeton 403) · S2 fenêtre bornée, non mergées, distantes, mergées repliées,
#   refs hostiles, commande jamais masquée (P78-D-27), lecture seule prouvée · S3 tags, stash, auteurs, en-tête · S4 états absent, indisponible, vide
#   S5 dépôt piégé (aucun programme du dépôt lancé) · S6 durées · S7 mutants (copies de la sortie, jamais le module)
# Dépôts fabriqués dans mktemp (dates de commit fixées, aucun dépôt distant). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin"
export HOME="$WORK/home"
GIT_REEL="$(command -v git)"
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; FAIL=$((FAIL+1)); fi; }
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
# j.mjs <fichier|-> <expression sur j> : JSON lu dans le fichier (ou « - » = stdin), expression évaluée
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2] === '-' ? 0 : process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
# lire.mjs <scripts> <lab> : JSON de lireGit(lab) (module chargé depuis <scripts>, copie de mutant possible)
cat > "$AUX/lire.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, lab] = process.argv;
let m; try { m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href); } catch (e) { console.log(JSON.stringify({ erreur: 'module absent' })); process.exit(0); }
console.log(JSON.stringify(m.lireGit(lab)));
JS
LIRE() { node "$AUX/lire.mjs" "$SCRIPTS" "$1" 2>/dev/null; }
# empreinte.mjs <dossier> : une ligne par fichier (chemin, taille, date), triée — lue en Node, jamais par stat ou find (uutils et GNU divergent en CI)
cat > "$AUX/empreinte.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
const lignes = [];
const parcourir = (d) => { for (const e of fs.readdirSync(d)) { const p = path.join(d, e), s = fs.lstatSync(p); if (s.isDirectory()) parcourir(p); else lignes.push(`${path.relative(process.argv[2], p)} ${s.size} ${s.mtimeMs}`); } };
parcourir(process.argv[2]);
console.log(lignes.sort().join('\n'));
JS


# route.mjs <scripts> <méthode> <chemin> : appelle routeGit avec un faux req/res ; rend « traité|statut »
cat > "$AUX/route.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, methode, p, lab] = process.argv;
let m; try { m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href); } catch { console.log('module absent'); process.exit(0); }
let statut = null; const res = { writeHead: (c) => { statut = c; }, end: () => {} };
const traite = m.routeGit({ method: methode }, res, new URL('http://x' + p), { root: lab, json: (r, c) => { statut = c; } });
console.log(traite + '|' + statut);
JS
# argv.mjs <git.log> : sur les lignes `log` de l'emballage, rend « lignes|sans -n|refs hors forme » (refs : refs/… ou sha de 40 caractères)
cat > "$AUX/argv.mjs" <<'JS'
import fs from 'node:fs';
const l = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter((x) => / log /.test(x));
let sansN = 0, hors = 0;
for (const x of l) {
  const t = x.split(' '), i = t.indexOf('-n');
  if (i < 0) { sansN++; continue; }
  for (const r of t.slice(i + 2)) if (r !== '--not' && !/^(refs\/|[0-9a-f]{40}$)/.test(r)) hors++;
}
console.log(`${l.length}|${sansN}|${hors}`);
JS
# fi.mjs : inutile — les petits dépôts sont fabriqués par plumbing (ct), les grands par fast-import (gen.mjs <ref> <n> <t0> [from])
cat > "$AUX/gen.mjs" <<'JS'
const [, , ref, n, t0, from] = process.argv;
let out = '';
for (let i = 1; i <= Number(n); i++) { const msg = `${ref.split('/').pop()} ${i}`; out += `commit ${ref}\ncommitter Alice <a@t.test> ${Number(t0) + i * 60} +0000\ndata ${Buffer.byteLength(msg)}\n${msg}\n` + (i === 1 && from ? `from ${from}\n` : '') + '\n'; }
process.stdout.write(out);
JS
# sonde réseau (modèle test-cockpit-retard.sh) : toute connexion sortante est journalisée puis refusée
cat > "$AUX/sonde.mjs" <<'JS'
import net from 'node:net';
import tls from 'node:tls';
import dns from 'node:dns';
import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';
const out = process.env.VF_SONDE_OUT;
fs.appendFileSync(out + '.charge', 'sonde chargée\n');
const rec = (genre, cible) => { fs.appendFileSync(out, `${genre} ${String(cible ?? '')}\n`); };
const refus = (genre) => (...a) => { rec(genre, typeof a[0] === 'object' ? JSON.stringify(a[0]) : a[0]); throw new Error('sonde : ' + genre); };
net.connect = refus('net'); net.createConnection = refus('net'); tls.connect = refus('tls');
net.Socket.prototype.connect = function (...a) { rec('net', typeof a[0] === 'object' ? JSON.stringify(a[0]) : a[0]); throw new Error('sonde : socket'); };
dns.lookup = refus('dns'); http.request = refus('http'); http.get = refus('http'); https.request = refus('https'); https.get = refus('https');
globalThis.fetch = (u) => { rec('fetch', typeof u === 'string' ? u : u?.url ?? String(u)); return Promise.reject(new Error('sonde : fetch')); };
JS
cat > "$AUX/temoin-sortant.mjs" <<'JS'
fetch('https://exemple.test/').catch(() => {});
import('node:net').then((m) => { try { (m.default || m).connect(443, 'exemple.test'); } catch {} });
setTimeout(() => process.exit(0), 300);
JS
# emballage git : journalise l'argv puis exécute le vrai git (utilisé par PATH=$WORK/bin:$PATH)
cat > "$WORK/bin/git" <<EOS
#!/bin/sh
printf '%s\n' "\$*" >> "\${VF_GITLOG:-/dev/null}"
exec "$GIT_REEL" "\$@"
EOS
chmod +x "$WORK/bin/git"

# --- dépôts fabriqués ---
T=0
tick() { T=$((T+1)); export GIT_AUTHOR_DATE="@$((1700000000+T*60)) +0000" GIT_COMMITTER_DATE="@$((1700000000+T*60)) +0000"; }
G() { "$GIT_REEL" -C "$LAB" "$@"; }
cm() { tick; echo "$2" >> "$LAB/$1"; G add "$1"; G commit -q -m "$3"; } # fichier, contenu, sujet

# lab principal : c0, f mergée --no-ff, octopus, seconde racine fusionnée, u1 non mergée, origin/*, deux worktrees, deux tags, deux stash
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
G init -q -b main; G add -A; cm a x "c0"
G checkout -q -b f; cm f f1 "f1"; G checkout -q main; cm m m1 "m1"; tick; G merge -q --no-ff f -m "merge f"
G checkout -q -b g1 main; cm g1 x "g1"; G checkout -q -b g2 main; cm g2 x "g2"; G checkout -q main; cm m m1b "m1b"; tick; G merge -q -m "octopus" g1 g2 >/dev/null 2>&1
G checkout -q --orphan other; G rm -rqf . ; cm r1 r "racine2"; G checkout -q main; tick; G merge -q --allow-unrelated-histories -m "merge other" other
G checkout -q -b u1 main; cm u1 x "u1"; G checkout -q main; cm a m2 "m2"
G update-ref refs/remotes/origin/main "$(G rev-parse main~1)"; G symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main; G update-ref refs/remotes/origin/u1 "$(G rev-parse u1)"
G worktree add -q "$WORK/wt-b" -b wtb; tick; "$GIT_REEL" -C "$WORK/wt-b" commit -q --allow-empty -m wtb1
G worktree add -q --detach "$WORK/wt-det" main~3
G tag light main~4; tick; G tag -a ann -m annotee main~2
echo s1 >> "$LAB/a"; tick; G stash push -q -m 'wip <b>hostile</b>'; echo s2 >> "$LAB/a"; tick; G stash push -q -m deux
G rev-parse HEAD > /dev/null && echo "fixture prête : $(G rev-list --count --all) commits"


# petits dépôts : newrepo <dir> crée un dépôt à arbre vide ; ct <dir> <ref> <ts> <msg> [parents…] écrit un commit et déplace la ref (rend le sha)
newrepo() { mkdir -p "$1"; "$GIT_REEL" init -q -b main "$1"; EMPTY="$("$GIT_REEL" -C "$1" mktree </dev/null)"; }
ct() { local R="$1" ref="$2" ts="$3" msg="$4" a=() p s; shift 4; for p in "$@"; do a+=(-p "$p"); done
  s="$(GIT_AUTHOR_DATE="@$ts +0000" GIT_COMMITTER_DATE="@$ts +0000" "$GIT_REEL" -C "$R" commit-tree "$EMPTY" ${a[@]+"${a[@]}"} -m "$msg")"; "$GIT_REEL" -C "$R" update-ref "$ref" "$s"; echo "$s"; }

# serveur réel sur le lab
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"
node "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
SRV=$!
for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
PORT=$(node "$AUX/j.mjs" "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)
TOK=$(node "$AUX/token.mjs" "$PORT" /)
assert_eq "S0 — serveur démarré, jeton lu dans la page" "$([ "$PORT" -gt 0 ] && [ "${#TOK}" -ge 16 ] && echo oui || echo non)" "oui"
GET() { node "$AUX/req.mjs" "$PORT" GET "$1" "$TOK" - ; } # route, jeton valide

echo "=== S1 — GET /api/vf/git de bout en bout, GET seul ==="
GET /api/vf/git > "$WORK/git1.out"
sed -n '2,$p' "$WORK/git1.out" > "$WORK/git1.json"
assert_eq "S1.1a — statut 200" "$(sed -n 1p "$WORK/git1.out")" "200"
assert_eq "S1.1b — schéma et état" "$(J "$WORK/git1.json" 'j.schema+"|"+j.etat')" "vibeflow/cockpit-git@1|ok"
assert_eq "S1.1c — chaque rangée a une colonne entière (et il y en a)" "$(J "$WORK/git1.json" 'j.rangees.length>5&&j.rangees.every(r=>Number.isInteger(r.col))')" "true"
assert_eq "S1.1d — une rangée d'octopus : fusion à 3 parents" "$(J "$WORK/git1.json" 'j.rangees.some(r=>r.fusion&&r.p.length===3)')" "true"
assert_eq "S1.2a — POST : 405" "$(node "$AUX/req.mjs" "$PORT" POST /api/vf/git "$TOK" - | sed -n 1p)" "405"
assert_eq "S1.2b — GET sans jeton : 403" "$(node "$AUX/req.mjs" "$PORT" GET /api/vf/git - - | sed -n 1p)" "403"
assert_eq "S1.2c — GET avec une Origin tierce : 403" "$(node "$AUX/req.mjs" "$PORT" GET /api/vf/git "$TOK" http://evil.example | sed -n 1p)" "403"
assert_eq "S1.2d — témoin : la même requête avec l'Origin de la page passe" "$(node "$AUX/req.mjs" "$PORT" GET /api/vf/git "$TOK" "http://127.0.0.1:$PORT" | sed -n 1p)" "200"

echo "=== S1.3 — routeGit : GET seul, aiguillage propre (indépendant de la ligne commune du serveur) ==="
assert_eq "S1.3a — POST /api/vf/git : traité, 405" "$(node "$AUX/route.mjs" "$SCRIPTS" POST /api/vf/git "$LAB")" "true|405"
assert_eq "S1.3b — DELETE /api/vf/git/entete : traité, 405" "$(node "$AUX/route.mjs" "$SCRIPTS" DELETE /api/vf/git/entete "$LAB")" "true|405"
assert_eq "S1.3c — GET /api/vf/git/inconnu : traité, 404" "$(node "$AUX/route.mjs" "$SCRIPTS" GET /api/vf/git/inconnu "$LAB")" "true|404"
assert_eq "S1.3d — GET /api/vf/gitx : pas notre route" "$(node "$AUX/route.mjs" "$SCRIPTS" GET /api/vf/gitx "$LAB" | cut -d'|' -f1)" "false"

echo "=== S2 — fenêtre bornée, non mergées, distantes, mergées repliées, refs hostiles, lecture seule ==="
LIRE "$LAB" > "$WORK/lab.json"
# S2.1 : 600 commits sur main
newrepo "$WORK/r-big"; node "$AUX/gen.mjs" refs/heads/main 600 1700000000 | "$GIT_REEL" -C "$WORK/r-big" fast-import --quiet
LIRE "$WORK/r-big" > "$WORK/big.json"
assert_eq "S2.1a — 600 commits : au plus 500 rangées de base, et 500 (fenêtre pleine)" "$(J "$WORK/big.json" 'j.rangees.length')" "500"
assert_eq "S2.1b — bornes.tronque vrai" "$(J "$WORK/big.json" 'j.bornes.tronque')" "true"
# S2.1c : une branche dont la pointe tombe hors de la fenêtre des non mergées
newrepo "$WORK/r-hors"; node "$AUX/gen.mjs" refs/heads/main 5 1700100000 | "$GIT_REEL" -C "$WORK/r-hors" fast-import --quiet
node "$AUX/gen.mjs" refs/heads/longue 520 1700200000 refs/heads/main | "$GIT_REEL" -C "$WORK/r-hors" fast-import --quiet
node "$AUX/gen.mjs" refs/heads/ancienne 1 1690000000 refs/heads/main | "$GIT_REEL" -C "$WORK/r-hors" fast-import --quiet
LIRE "$WORK/r-hors" > "$WORK/hors.json"
assert_eq "S2.1c — la pointe de « ancienne » est hors fenêtre : listée avec son avance, sans rangée" "$(J "$WORK/hors.json" 'JSON.stringify(j.horsFenetre.map(x=>[x.nom,x.avance])) + "|" + j.rangees.some(r=>r.refs.some(e=>e.nom==="ancienne"))')" '[["ancienne",1]]|false'
assert_eq "S2.1d — témoin : la pointe de « longue » (récente) a sa rangée" "$(J "$WORK/hors.json" 'j.rangees.some(r=>r.refs.some(e=>e.nom==="longue"))')" "true"
# S2.2 : 30 branches non mergées aux pointes anciennes
newrepo "$WORK/r-trente"; node "$AUX/gen.mjs" refs/heads/main 5 1700100000 | "$GIT_REEL" -C "$WORK/r-trente" fast-import --quiet
for i in $(seq 10 39); do node "$AUX/gen.mjs" "refs/heads/b$i" 1 "$((1600000000+i))" refs/heads/main | "$GIT_REEL" -C "$WORK/r-trente" fast-import --quiet; done
LIRE "$WORK/r-trente" > "$WORK/trente.json"
assert_eq "S2.2 — 30 branches non mergées : les 30 pointes ont une rangée, aucune hors fenêtre" "$(J "$WORK/trente.json" 'j.rangees.flatMap(r=>r.refs).filter(e=>/^b\d+$/.test(e.nom)).length + "|" + j.horsFenetre.length')" "30|0"
# S2.3 : distante connue et base divergente
newrepo "$WORK/r-dist"; R="$WORK/r-dist"
c1=$(ct "$R" refs/heads/main 1700000000 c1); c2=$(ct "$R" refs/heads/main 1700000060 c2 "$c1"); c3=$(ct "$R" refs/heads/main 1700000120 c3 "$c2")
ct "$R" refs/heads/main 1700000180 m4 "$c3" > /dev/null; ct "$R" refs/remotes/origin/main 1700000240 r4 "$c3" > /dev/null
"$GIT_REEL" -C "$R" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
f1=$(ct "$R" refs/heads/f 1700000300 f1 "$c3"); "$GIT_REEL" -C "$R" update-ref refs/remotes/origin/f "$f1"
LIRE "$R" > "$WORK/dist.json"
assert_eq "S2.3a — origin/f : étiquette « distante » sur le commit de f, à côté de la locale" "$(J "$WORK/dist.json" 'j.rangees.find(r=>r.h==="'"$f1"'").refs.map(e=>e.type+":"+e.nom).sort().join(",")')" "distante:origin/f,locale:f"
assert_eq "S2.3b — main et origin/main divergents : base.divergent vrai, deux comptes" "$(J "$WORK/dist.json" 'JSON.stringify([j.base.nom,j.base.locale,j.base.distante,j.base.divergent])')" '["main",1,1,true]'
assert_eq "S2.3c — le commit propre à origin/main figure au graphe (étiquette distante)" "$(J "$WORK/dist.json" 'j.rangees.some(r=>r.refs.some(e=>e.type==="distante"&&e.nom==="origin/main"))')" "true"
assert_eq "S2.3d — témoin : la base sans divergence (lab principal : origin/main en retard) n'est pas divergente" "$(J "$WORK/lab.json" 'JSON.stringify([j.base.nom,j.base.divergent])')" '["main",false]'
# S2.4 : mergées repliées (lab principal : f, g1, g2, other ont une avance de 0)
assert_eq "S2.4a — mergées : f, g1, g2, other, sans origin/main" "$(J "$WORK/lab.json" 'j.mergees.map(m=>m.nom).sort().join(",")')" "f,g1,g2,other"
assert_eq "S2.4b — commande de suppression de « f » (forme de 78-03)" "$(J "$WORK/lab.json" 'j.mergees.find(m=>m.nom==="f").commande')" "git branch -d --end-of-options 'f'"
assert_eq "S2.4c — aucune étiquette sur le graphe pour une mergée repliée" "$(J "$WORK/lab.json" 'j.rangees.flatMap(r=>r.refs).filter(e=>["f","g1","g2","other"].includes(e.nom)).length')" "0"
assert_eq "S2.4d — non mergées présentes : u1, origin/u1, wtb ont leur étiquette" "$(J "$WORK/lab.json" 'j.rangees.flatMap(r=>r.refs).map(e=>e.nom).filter(n=>["u1","origin/u1","wtb"].includes(n)).sort().join(",")')" "origin/u1,u1,wtb"
assert_eq "S2.4e — origin/HEAD (symbolique) exclu des étiquettes" "$(J "$WORK/lab.json" 'j.rangees.flatMap(r=>r.refs).filter(e=>/HEAD/.test(e.nom)&&e.type==="distante").length')" "0"
assert_eq "S2.4f — worktrees : principal, branche wtb (cd), détaché ; « ici » = le lab" "$(J "$WORK/lab.json" 'j.worktrees.map(w=>[w.nom,w.branche,w.detache,w.ici,w.principal,w.commande===null].join(":")).join(",")')" "lab:main:false:true:true:true,wt-b:wtb:false:false:false:false,wt-det:null:true:false:false:false"
# S2.5 : refs hostiles
newrepo "$WORK/r-host"; R="$WORK/r-host"
h1=$(ct "$R" refs/heads/main 1700000000 c1); h3=$(ct "$R" refs/heads/main 1700000060 c2 "$h1"); t=1700001000
BIDI="ab$(printf '\xe2\x80\xae')cd"
for n in '-x' '--all' 'x;y|z`w' '<svg/onload=alert(1)>' 'é🙂' "$BIDI" 'ghp_abcdefghijklmnopqrstuvwxyz0123'; do t=$((t+60)); ct "$R" "refs/heads/$n" "$t" "x" "$h3" > /dev/null; done
LIRE "$R" > "$WORK/host.json"
node "$AUX/j.mjs" "$WORK/host.json" 'j.rangees.flatMap(r=>r.refs).filter(e=>e.type==="locale").map(e=>e.nom+"\t"+e.commande).join("\n")' > "$WORK/host.noms"
TAB=$'\t'
L_X="-x${TAB}git switch --end-of-options '-x'"; L_ALL="--all${TAB}git switch --end-of-options '--all'"
L_SH="x;y|z\`w${TAB}git switch --end-of-options 'x;y|z\`w'"
L_SVG="<svg/onload=alert(1)>${TAB}git switch --end-of-options '<svg/onload=alert(1)>'"; L_EMO="é🙂${TAB}git switch --end-of-options 'é🙂'"
L_BIDI="abcd${TAB}null"; L_TOK="[masqué]${TAB}null"
assert_eq "S2.5a — dépôt aux refs hostiles : lu, état ok" "$(J "$WORK/host.json" 'j.etat')" "ok"
assert_eq "S2.5b — « -x » et « --all » : présents, commande avec --end-of-options" "$(grep -Fxc -e "$L_X" -e "$L_ALL" "$WORK/host.noms")" "2"
assert_eq "S2.5c — ; | \` : présent tel quel, citation exacte" "$(grep -Fxc -e "$L_SH" "$WORK/host.noms")" "1"
assert_eq "S2.5d — <svg/onload=alert(1)> et é🙂 présents tels quels" "$(grep -Fxc -e "$L_SVG" -e "$L_EMO" "$WORK/host.noms")" "2"
assert_eq "S2.5e — U+202E retiré du nom affiché, et AUCUNE commande (null)" "$(grep -Fxc -e "$L_BIDI" "$WORK/host.noms")" "1"
assert_eq "S2.5f — P78-D-27 : un nom qui ressemble à un jeton est affiché masqué et n'a aucune commande" "$(grep -Fxc -e "$L_TOK" "$WORK/host.noms")" "1"
EXPR_G='JSON.stringify(j).includes("switch --end-of-options " + String.fromCharCode(39) + String.fromCharCode(91) + "masqu")'
assert_eq "S2.5g — la commande n'est jamais nettoyée : aucune commande servie ne porte un nom masqué" "$(J "$WORK/host.json" "$EXPR_G")" "false"
# S2.6 : lecture seule prouvée
E0="$WORK/e0.txt"; E1="$WORK/e1.txt"; E2="$WORK/e2.txt"
node "$AUX/empreinte.mjs" "$LAB/.git" > "$E0"; for _ in 1 2 3 4 5 6 7 8 9 10; do GET /api/vf/git > /dev/null; GET /api/vf/git/entete > /dev/null; done; node "$AUX/empreinte.mjs" "$LAB/.git" > "$E1"
G update-ref refs/heads/zz_temoin HEAD; node "$AUX/empreinte.mjs" "$LAB/.git" > "$E2"
assert_eq "S2.6a — témoin : l'empreinte voit une écriture délibérée dans .git" "$(cmp -s "$E1" "$E2" && echo identique || echo differe)" "differe"
assert_eq "S2.6b — l'empreinte de .git (chemin, taille, date) est identique avant et après vingt GET (et il y a des fichiers)" "$(cmp -s "$E0" "$E1" && [ "$(grep -c . "$E0")" -ge 10 ] && echo identique || echo differe)" "identique"
G update-ref -d refs/heads/zz_temoin
export VF_GITLOG="$WORK/git.log"; : > "$VF_GITLOG"
PATH="$WORK/bin:$PATH" node "$AUX/lire.mjs" "$SCRIPTS" "$LAB" > /dev/null 2>&1; PATH="$WORK/bin:$PATH" node "$AUX/lire.mjs" "$SCRIPTS" "$WORK/r-host" > /dev/null 2>&1
PATH="$WORK/bin:$PATH" git -C "$LAB" fetch --dry-run origin > /dev/null 2>&1
RES="$(grep -cE '(^| )(fetch|pull|push|ls-remote|remote|commit-graph|gc|maintenance)( |$)' "$VF_GITLOG")"
assert_eq "S2.6c — témoin positif : l'emballage voit un fetch délibéré (1) ; seul celui-là" "$RES|$(grep -cE '(^| )fetch( |$)' "$VF_GITLOG")|$([ "$(grep -c . "$VF_GITLOG")" -ge 10 ] && echo vu || echo aveugle)" "1|1|vu"
assert_eq "S2.6d — tout log porte -n ; toute ref passée est refs/… ou un sha de 40 caractères (lignes log vues : 4 au moins)" "$(node "$AUX/argv.mjs" "$VF_GITLOG" | awk -F'|' '{print ($1>=4?"vu":"aveugle") "|" $2 "|" $3}')" "vu|0|0"
unset VF_GITLOG
export VF_SONDE_OUT="$WORK/sonde.out"; : > "$VF_SONDE_OUT"; rm -f "$VF_SONDE_OUT.charge"
node --import "$AUX/sonde.mjs" "$AUX/temoin-sortant.mjs" > /dev/null 2>&1
assert_eq "S2.6e — témoin positif : la sonde réseau enregistre un fetch et une connexion délibérés" "$(cut -d' ' -f1 "$VF_SONDE_OUT" | sort | tr '\n' ',')" "fetch,net,"
: > "$VF_SONDE_OUT"; rm -f "$VF_SONDE_OUT.charge"
node --import "$AUX/sonde.mjs" "$AUX/lire.mjs" "$SCRIPTS" "$LAB" > "$WORK/sonde-lab.json" 2>/dev/null
assert_eq "S2.6f — lireGit : sonde chargée, 0 connexion sortante, résultat calculé" "$([ -s "$VF_SONDE_OUT.charge" ] && echo charge)|$(grep -c . "$VF_SONDE_OUT")|$(J "$WORK/sonde-lab.json" 'j.etat')" "charge|0|ok"
# S2.7 : ce que la réponse ne porte jamais
assert_eq "S2.7a — aucune clé de la liste commune « interdits » du contrat, ni verrous, arbitrages, watchdog, orphelins, hotspots (à toute profondeur)" "$(J "$WORK/lab.json" '(function f(o,ban){ if(!o||typeof o!=="object") return 0; return Object.entries(o).reduce((n,[k,v])=>n+(ban.includes(k)?1:0)+f(v,ban),0); })(j,["doing","mandat","messages","outils","verrous","arbitrages","watchdog","orphelins","hotspots"])')" "0"
assert_eq "S2.7b — le contrat porte les deux schémas et une liste « interdits »" "$(node "$AUX/j.mjs" "$SCRIPTS/vf-cockpit-interface.json" '(()=>{const s=j.schemas["vibeflow/cockpit-git@1"];return !!s&&Array.isArray(s.interdits)&&s.interdits.length>0&&!!j.schemas["vibeflow/cockpit-git-entete@1"]})()')" "true"

stop_srv
vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
