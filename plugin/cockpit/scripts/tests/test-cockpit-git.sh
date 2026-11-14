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
. "$(dirname "$0")/socle-serveur.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; FAIL=$((FAIL+1)); fi; }

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
console.log(JSON.stringify(await m.lireGit(lab))); // P78-D-41 : lireGit est asynchrone
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
let statut = null, fini; const attente = new Promise((r) => { fini = r; });
const res = { writeHead: (c) => { statut = c; fini(); }, end: () => {} };
const traite = m.routeGit({ method: methode }, res, new URL('http://x' + p), { root: lab, json: (r, c) => { statut = c; fini(); } });
if (traite) await Promise.race([attente, new Promise((r) => setTimeout(r, 8000))]); // P78-D-41 : GET /api/vf/git répond après la promesse
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
  const refs = t.slice(i + 2), fin = refs[refs.length - 1] === '--'; // A6 : « -- » final obligatoire, une révision n'est jamais prise pour un fichier de l'arbre
  if (!fin) hors++;
  for (const r of fin ? refs.slice(0, -1) : refs) if (r !== '--not' && !/^(refs\/|[0-9a-f]{40}$)/.test(r)) hors++;
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

# mut.mjs <fichier> <de> <vers> : remplace UNE occurrence exacte (rend « absent » si le motif n'existe plus : un mutant sans cible ne compte pas)
cat > "$AUX/mut.mjs" <<'JS'
import fs from 'node:fs';
const [, , f, de, vers] = process.argv;
const t = fs.readFileSync(f, 'utf8');
if (!t.includes(de)) { console.log('absent'); process.exit(0); }
fs.writeFileSync(f, t.replace(de, () => vers)); console.log('applique');
JS

# dur.mjs <scripts> <lab> : « état|rangées|ms » (durée de lireGit, citée, jamais assertée)
cat > "$AUX/dur.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, lab] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href);
const t0 = performance.now(); const j = await m.lireGit(lab);
console.log(`${j.etat}|${(j.rangees || []).length}|${Math.round(performance.now() - t0)}`);
JS

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
cockpit_lancer "$LAB"; SRV="${VF_PID:-}"
PORT="${VF_PORT:-0}"
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
assert_eq "S2.4e — origin/HEAD (symbolique) exclu des étiquettes ET de la liste des mergées" "$(J "$WORK/lab.json" 'j.rangees.flatMap(r=>r.refs).map(e=>e.nom).concat(j.mergees.map(m=>m.nom)).filter(n=>n==="origin/HEAD").length')" "0"
assert_eq "S2.4f — worktrees : principal, branche wtb (cd), détaché ; « ici » = le lab" "$(J "$WORK/lab.json" 'j.worktrees.map(w=>[w.nom,String(w.branche),w.detache,w.ici,w.principal,w.commande===null].join(":")).join(",")')" "lab:main:false:true:true:true,wt-b:wtb:false:false:false:false,wt-det:null:true:false:false:false"
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
assert_eq "S2.6d — tout log porte -n et se termine par « -- » (A6) ; toute ref passée est refs/… ou un sha de 40 caractères (lignes log vues : 4 au moins)" "$(node "$AUX/argv.mjs" "$VF_GITLOG" | awk -F'|' '{print ($1>=4?"vu":"aveugle") "|" $2 "|" $3}')" "vu|0|0"
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

echo "=== S3 — tags, stash, auteurs, en-tête servi, contrat ==="
H7() { "$GIT_REEL" -C "$LAB" rev-parse --short=7 "$1"; }
assert_eq "S3.1a — tags annoté et léger : deux entrées, triées par date décroissante (ann puis light)" "$(J "$WORK/lab.json" 'j.tags.map(t=>t.nom).join(",")')" "ann,light"
assert_eq "S3.1b — le h7 de l'annoté est celui du COMMIT (cible peelée), celui du léger aussi" "$(J "$WORK/lab.json" 'j.tags.map(t=>t.h7).join(",")')" "$(H7 'main~2^{commit}'),$(H7 'main~4')"
assert_eq "S3.1c — la date des tags est un entier" "$(J "$WORK/lab.json" 'j.tags.every(t=>Number.isInteger(t.at))')" "true"
assert_eq "S3.2a — deux stash : stash@{0} et stash@{1}, branche main" "$(J "$WORK/lab.json" 'j.stash.map(x=>x.ref+":"+x.branche).join(",")')" "stash@{0}:main,stash@{1}:main"
assert_eq "S3.2b — commande de stash@{0}" "$(J "$WORK/lab.json" 'j.stash[0].commande')" "git stash show --stat 'stash@{0}'"
assert_eq "S3.2c — le message hostile est servi tel quel (le rendu est en textContent)" "$(J "$WORK/lab.json" 'j.stash[1].message')" "On main: wip <b>hostile</b>"
assert_eq "S3.2d — h7 et date du stash" "$(J "$WORK/lab.json" 'j.stash.every(x=>/^[0-9a-f]{7}$/.test(x.h7)&&Number.isInteger(x.at))')" "true"
# S3.3 : auteurs agrégés en JS, jamais shortlog
newrepo "$WORK/r-aut"; R="$WORK/r-aut"
a1=$(ct "$R" refs/heads/main 1700000000 c1); a2=$(ct "$R" refs/heads/main 1700000100 c2 "$a1"); a3=$(ct "$R" refs/heads/main 1700000200 c3 "$a2")
a4=$(GIT_AUTHOR_NAME='<img src=x onerror=1>' ct "$R" refs/heads/main 1700000300 c4 "$a3")
AUT="$("$GIT_REEL" -C "$R" log -1 --format=%an "$a4")"
export VF_GITLOG="$WORK/git-aut.log"; : > "$VF_GITLOG"
PATH="$WORK/bin:$PATH" node "$AUX/lire.mjs" "$SCRIPTS" "$R" > "$WORK/aut.json" 2>/dev/null; unset VF_GITLOG
assert_eq "S3.3a — auteurs : Alice 3 commits (dernier c3), l'autre 1 (dernier c4), comptes exacts" "$(J "$WORK/aut.json" 'j.auteurs.map(a=>a.nom+":"+a.commits+":"+a.dernier).join(",")')" "Alice:3:1700000200,$AUT:1:1700000300"
assert_eq "S3.3b — aucun appel shortlog dans l'argv (emballage vu à l'œuvre : au moins 5 appels)" "$(grep -c shortlog "$WORK/git-aut.log")|$([ "$(grep -c . "$WORK/git-aut.log")" -ge 5 ] && echo vu || echo aveugle)" "0|vu"
assert_eq "S3.3c — activité par branche : main, avance 0 sur la base, dernier = pointe" "$(J "$WORK/aut.json" 'j.parBranche.map(b=>b.nom+":"+b.avance+":"+b.dernier).join(",")')" "main:0:1700000300"
assert_eq "S3.4 — GET /api/vf/git/entete : schéma, état ok, dépôt et branche" "$(GET /api/vf/git/entete | sed -n '2,$p' > "$WORK/ent.json"; J "$WORK/ent.json" '[j.schema,j.etat,j.depot,j.branche].join("|")')" "vibeflow/cockpit-git-entete@1|ok|lab|main"
node "$AUX/j.mjs" "$SCRIPTS/vf-cockpit-interface.json" 'JSON.stringify(j.schemas["vibeflow/cockpit-git@1"])' > "$WORK/contrat.json"
assert_eq "S3.5a — contrat : chaque clé requise est présente avec son type dans la réponse réelle (lab.json)" "$(node -e 'const c=JSON.parse(process.argv[1]);const j=JSON.parse(require("fs").readFileSync(process.argv[2],"utf8"));const t=(v)=>Array.isArray(v)?"array":typeof v;console.log(Object.entries(c.requis).filter(([k,ty])=>t(j[k])!==ty).map(([k])=>k).join(",")||"conforme")' "$(cat "$WORK/contrat.json")" "$WORK/lab.json")" "conforme"
assert_eq "S3.5b — contrat : chaque rangée porte toutes les clés de rangee.requis" "$(node -e 'const c=JSON.parse(process.argv[1]);const j=JSON.parse(require("fs").readFileSync(process.argv[2],"utf8"));console.log(j.rangees.filter(r=>c.rangee.requis.some(k=>!(k in r))).length)' "$(cat "$WORK/contrat.json")" "$WORK/lab.json")" "0"
assert_eq "S3.5c — contrat : l'état de la réponse est dans la liste des états" "$(node -e 'const c=JSON.parse(process.argv[1]);const j=JSON.parse(require("fs").readFileSync(process.argv[2],"utf8"));console.log(c.etats.includes(j.etat))' "$(cat "$WORK/contrat.json")" "$WORK/lab.json")" "true"
# S3.6 : repli quand git refuse %(ahead-behind:…) (version ancienne) — un emballage le refuse
mkdir -p "$WORK/bin2"; cat > "$WORK/bin2/git" <<EOS
#!/bin/sh
case "\$*" in *ahead-behind*) echo "fatal: unknown field name: ahead-behind" >&2; exit 129 ;; esac
exec "$GIT_REEL" "\$@"
EOS
chmod +x "$WORK/bin2/git"
PATH="$WORK/bin2:$PATH" node "$AUX/lire.mjs" "$SCRIPTS" "$WORK/r-dist" > "$WORK/dist-repli.json" 2>/dev/null
PATH="$WORK/bin2:$PATH" node "$AUX/lire.mjs" "$SCRIPTS" "$LAB" > "$WORK/lab-repli.json" 2>/dev/null
assert_eq "S3.6a — sans ahead-behind (emballage vu : il refuse bien le champ), le dépôt divergent donne les mêmes comptes" "$(PATH="$WORK/bin2:$PATH" git -C "$LAB" for-each-ref '--format=%(ahead-behind:main)' refs/heads/main > /dev/null 2>&1; echo "refus=$?")|$(J "$WORK/dist-repli.json" 'JSON.stringify([j.etat,j.base.locale,j.base.distante,j.base.divergent])')" 'refus=129|["ok",1,1,true]'
assert_eq "S3.6b — sans ahead-behind, le lab principal replie les mêmes mergées et garde les mêmes non mergées" "$(J "$WORK/lab-repli.json" 'j.mergees.map(m=>m.nom).sort().join(",")+"|"+j.rangees.flatMap(r=>r.refs).map(e=>e.nom).filter(n=>["u1","origin/u1","wtb"].includes(n)).sort().join(",")')" "f,g1,g2,other|origin/u1,u1,wtb"

echo "=== S4 — états absent, indisponible, vide ==="
mkdir -p "$WORK/hors-depot"; LIRE "$WORK/hors-depot" > "$WORK/absent.json"
assert_eq "S4.1 — lab hors dépôt : état absent" "$(J "$WORK/absent.json" 'j.schema+"|"+j.etat')" "vibeflow/cockpit-git@1|absent"
newrepo "$WORK/r-casse"; R="$WORK/r-casse"; k1=$(ct "$R" refs/heads/main 1700000000 c1); ct "$R" refs/heads/main 1700000060 c2 "$k1" > /dev/null
assert_eq "S4.2a — témoin : avant la casse, le dépôt est lu (ok)" "$(LIRE "$R" | node "$AUX/j.mjs" - 'j.etat')" "ok"
OBJ="$("$GIT_REEL" -C "$R" rev-parse refs/heads/main)"; mv "$R/.git/objects/${OBJ:0:2}/${OBJ:2}" "$WORK/objet-retire"; LIRE "$R" > "$WORK/casse.json"; ROUTE="$(node "$AUX/route.mjs" "$SCRIPTS" GET /api/vf/git "$R")"; mv "$WORK/objet-retire" "$R/.git/objects/${OBJ:0:2}/${OBJ:2}"
assert_eq "S4.2b — objet de la pointe manquant (git échoue, le dépôt reste reconnu) : état indisponible, sans aucun chemin absolu ni trace dans la réponse" "$(J "$WORK/casse.json" 'j.etat')|$(grep -c "$WORK" "$WORK/casse.json")|$(grep -ci 'fatal\|error\|stack' "$WORK/casse.json")" "indisponible|0|0"
assert_eq "S4.2c — la route répond 200 (jamais un 500) sur ce dépôt" "$ROUTE" "true|200"
newrepo "$WORK/r-vide"; LIRE "$WORK/r-vide" > "$WORK/vide.json"
assert_eq "S4.3 — dépôt sans commit : état vide, commande du premier commit" "$(J "$WORK/vide.json" 'j.etat+"|"+j.commandes.vide')" 'vide|git commit -m "premier commit"'
assert_eq "S4.4 — chaque état porte le schéma" "$(J "$WORK/vide.json" 'j.schema')|$(J "$WORK/casse.json" 'j.schema')" "vibeflow/cockpit-git@1|vibeflow/cockpit-git@1"

echo "=== S5 — dépôt piégé : aucun programme du dépôt n'est lancé ==="
MARQ="$WORK/marques"; PROGS="$WORK/progs"; mkdir -p "$MARQ" "$PROGS"
mk_prog() { printf '#!/bin/sh\necho "$0 $*" >> "%s/%s"\n%s\n' "$MARQ" "$1" "${2:-exit 0}" > "$PROGS/$1.sh"; chmod +x "$PROGS/$1.sh"; }
mk_prog PROC "exit 1"; mk_prog CLEAN 'cat'; mk_prog TEXTCONV 'cat "$1"'; mk_prog FSM "exit 1"
marque() { if [ -s "$MARQ/$1" ]; then echo posé; else echo absent; fi; }
raz() { rm -f "$MARQ"/*; }
P="$WORK/piege"; "$GIT_REEL" init -q -b main "$P"; P="$(cd "$P" && pwd -P)"
printf 'f.txt filter=f\n*.bin diff=bin\n' > "$P/.gitattributes"; printf 'contenu\n' > "$P/f.txt"; printf 'a\0b\n' > "$P/a.bin"
"$GIT_REEL" -C "$P" add -A && "$GIT_REEL" -C "$P" commit -q -m "premier"; printf 'a\0c\n' > "$P/a.bin"; "$GIT_REEL" -C "$P" commit -q -am "SUJET-REEL"
"$GIT_REEL" -C "$P" config filter.f.clean "$PROGS/CLEAN.sh"; "$GIT_REEL" -C "$P" config filter.f.process "$PROGS/PROC.sh"
"$GIT_REEL" -C "$P" config diff.bin.textconv "$PROGS/TEXTCONV.sh"; "$GIT_REEL" -C "$P" config core.fsmonitor "$PROGS/FSM.sh"
touch -t "$(date -v-1M +%Y%m%d%H%M 2>/dev/null || date -d '1 minute ago' +%Y%m%d%H%M)" "$P/f.txt"
L="$WORK/leurre"; "$GIT_REEL" init -q -b main "$L"; "$GIT_REEL" -C "$L" commit -q --allow-empty -m LEURRE; L="$(cd "$L" && pwd -P)"
raz
"$GIT_REEL" -C "$P" log -p -1 > /dev/null 2>&1
assert_eq "S5.0a — témoin positif : git log -p brut lance le textconv du dépôt piégé" "$(marque TEXTCONV)" "posé"; raz
"$GIT_REEL" --no-optional-locks -c core.fsmonitor=false -C "$P" status --porcelain=v2 > /dev/null 2>&1
assert_eq "S5.0b — témoin positif : status brut (GIT_SUR seul) sur un fichier stat-dirty lance le filtre du dépôt" "$(marque PROC)" "posé"; raz
LIRE "$P" > "$WORK/piege.json"
assert_eq "S5.1a — lireGit sur le dépôt piégé : lu (état ok, sujet réel), aucun marqueur" "$(J "$WORK/piege.json" 'j.etat+"|"+j.rangees[0].s')|$(marque TEXTCONV)|$(marque PROC)|$(marque FSM)|$(marque CLEAN)" "ok|SUJET-REEL|absent|absent|absent|absent"; raz
GIT_DIR="$L/.git" LIRE "$P" > "$WORK/piege-env.json"
assert_eq "S5.1b — GIT_DIR=<leurre> hérité : c'est bien le dépôt piégé qui est lu (le sujet leurre n'apparaît pas), aucun marqueur" "$(J "$WORK/piege-env.json" 'j.rangees.map(r=>r.s).join(",")')|$(marque TEXTCONV)|$(marque PROC)" "SUJET-REEL,premier|absent|absent"

echo "=== S6 — durées (citées, jamais assertées) ==="
D1="$(node "$AUX/dur.mjs" "$SCRIPTS" "$LAB")"; TOP="$("$GIT_REEL" -C "$SCRIPTS" rev-parse --show-toplevel)"; D2="$(node "$AUX/dur.mjs" "$SCRIPTS" "$TOP")"
echo "  ℹ S6.1 — fixture : $D1 (état|rangées|ms) ; ce dépôt ($TOP) : $D2"
assert_eq "S6.1 — les deux lectures aboutissent (état ok)" "$(echo "$D1" | cut -d'|' -f1)|$(echo "$D2" | cut -d'|' -f1)" "ok|ok"

echo "=== S7 — mutants (copies des scripts, jamais le module) ==="
mutant() { # nom, de, vers : copie les scripts, applique la mutation ; rend « applique » ou « absent » ; la copie est jugée « avec effet » si le module diffère
  rm -rf "$WORK/mut/$1"; mkdir -p "$WORK/mut/$1"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$WORK/mut/$1/"
  local r; r="$(node "$AUX/mut.mjs" "$WORK/mut/$1/vf-cockpit-git.mjs" "$2" "$3")"
  [ "$r" = applique ] && ! cmp -s "$SCRIPTS/vf-cockpit-git.mjs" "$WORK/mut/$1/vf-cockpit-git.mjs" && echo effet || echo sans-effet
}
LIREM() { node "$AUX/lire.mjs" "$WORK/mut/$1" "$2" 2>/dev/null; }
assert_eq "M-BORNE.0 — mutant avec effet (le -n de la ligne de base est retiré)" "$(mutant borne "'-n', String(BORNES.base), " "")" "effet"
LIREM borne "$WORK/r-big" > "$WORK/m-borne.json"
assert_eq "M-BORNE — sans -n, 600 rangées au lieu de 500 : S2.1a rougit pour sa raison (état ok, fenêtre dépassée)" "$(J "$WORK/m-borne.json" 'j.etat+"|"+j.rangees.length')" "ok|600"
assert_eq "M-COURT.0 — mutant avec effet (noms courts passés à log)" "$(mutant court 'const refLog = (r) => r.ref;' 'const refLog = (r) => r.ref.replace(/^refs\/(heads|remotes)\//, "");')" "effet"
LIREM court "$WORK/r-host" > "$WORK/m-court-host.json"; LIREM court "$LAB" > "$WORK/m-court-lab.json"
assert_eq "M-COURT — noms courts : le dépôt aux refs hostiles n'est plus lu (S2.5a rougit), alors que le lab sans nom hostile reste lu (le mutant ne casse que la raison visée)" "$(J "$WORK/m-court-host.json" 'j.etat')|$(J "$WORK/m-court-lab.json" 'j.etat')" "indisponible|ok"
assert_eq "M-EOO-LOG.0 — mutant avec effet (--not placé avant les refs)" "$(mutant eoo "...nonMergees.map(refLog), ...(refBase ? ['--not', refBase] : []), '--')" "...(refBase ? ['--not', refBase] : []), ...nonMergees.map(refLog), '--')")" "effet"
LIREM eoo "$WORK/r-trente" > "$WORK/m-eoo.json"
assert_eq "M-EOO-LOG — --not avant les refs : aucune des 30 pointes n'a de rangée (S2.2 rougit pour sa raison, état ok)" "$(J "$WORK/m-eoo.json" 'j.etat+"|"+j.rangees.flatMap(r=>r.refs).filter(e=>/^b\d+$/.test(e.nom)).length')" "ok|0"
assert_eq "M-NETTOIE.0 — mutant avec effet (la porte « le nom serait masqué » est retirée)" "$(mutant nettoie 'noms.every((n) => masque(n) === n)' 'true')" "effet"
LIREM nettoie "$WORK/r-host" > "$WORK/m-nettoie.json"
assert_eq "M-NETTOIE — sans la porte, le nom-jeton reçoit une commande (S2.5f rougit pour sa raison : la commande existe et porte le vrai nom)" "$(J "$WORK/m-nettoie.json" 'j.etat+"|"+j.rangees.flatMap(r=>r.refs).filter(e=>e.nom===String.fromCharCode(91)+"masqué]").map(e=>e.commande===null?"null":e.commande.includes("ghp_")?"fuite":"autre").join(",")')" "ok|fuite"

assert_eq "M-HEAD.0 — témoin : la ref symbolique refs/remotes/origin/HEAD existe bien dans le lab" "$("$GIT_REEL" -C "$LAB" for-each-ref refs/remotes/origin/HEAD | grep -c HEAD)" "1"
assert_eq "M-HEAD.1 — mutant avec effet (le filtre des refs symboliques est retiré)" "$(mutant head 'refs.filter((r) => !/^refs\/remotes\/[^/]+\/HEAD$/.test(r.ref))' 'refs.filter(() => true)')" "effet"
LIREM head "$LAB" > "$WORK/m-head.json"
assert_eq "M-HEAD — sans le filtre, « origin/HEAD » réapparaît (dans les mergées : même commit qu'origin/main) : S2.4e et S2.4a rougissent pour leur raison" "$(J "$WORK/m-head.json" 'j.etat+"|"+j.rangees.flatMap(r=>r.refs).map(e=>e.nom).concat(j.mergees.map(m=>m.nom)).filter(n=>n==="origin/HEAD").length')" "ok|1"

echo "=== S8 — revue serveur 2026-11-06, R1 (P78-D-42) : dépôt sans branche de base, le graphe est rendu sans comptes d'avance ==="
# dépôt `master` seul (ni main ni origin/HEAD) ; dépôt `develop` + `feat` sans distant, avec un worktree sur feat et un tag
newrepo "$WORK/r-master"; R="$WORK/r-master"; "$GIT_REEL" -C "$R" symbolic-ref HEAD refs/heads/master
m1=$(ct "$R" refs/heads/master 1700000000 m1); m2=$(ct "$R" refs/heads/master 1700000060 m2 "$m1"); ct "$R" refs/heads/master 1700000120 m3 "$m2" > /dev/null; "$GIT_REEL" -C "$R" tag v-m "$m2"
newrepo "$WORK/r-develop"; R="$WORK/r-develop"; "$GIT_REEL" -C "$R" symbolic-ref HEAD refs/heads/develop
d1=$(ct "$R" refs/heads/develop 1700000000 d1); d2=$(ct "$R" refs/heads/develop 1700000060 d2 "$d1"); ct "$R" refs/heads/feat 1700000120 f1 "$d2" > /dev/null; "$GIT_REEL" -C "$R" tag v-d "$d1"
"$GIT_REEL" -C "$R" worktree add -q "$WORK/wt-feat" feat
export VF_GITLOG="$WORK/git-base.log"; : > "$VF_GITLOG"
PATH="$WORK/bin:$PATH" node "$AUX/lire.mjs" "$SCRIPTS" "$WORK/r-master" > "$WORK/master.json" 2>/dev/null
PATH="$WORK/bin:$PATH" node "$AUX/lire.mjs" "$SCRIPTS" "$WORK/r-develop" > "$WORK/develop.json" 2>/dev/null; unset VF_GITLOG
assert_eq "S8.1a — dépôt master seul : état ok (jamais indisponible), 3 rangées, pas de base nommée" "$(J "$WORK/master.json" 'j.etat+"|"+(j.rangees||[]).length+"|"+j.base?.nom')" "ok|3|null"
assert_eq "S8.1b — dépôt master seul : le tag est rendu, aucun compte d'avance (parBranche.avance null, base.locale null)" "$(J "$WORK/master.json" '(j.tags||[]).map(t=>t.nom).join(",")+"|"+(j.parBranche||[]).map(b=>b.nom+":"+b.avance).join(",")+"|"+j.base?.locale')" "v-m|master:null|null"
assert_eq "S8.1c — dépôt master seul : le worktree courant est listé" "$(J "$WORK/master.json" '(j.worktrees||[]).length+"|"+(j.worktrees||[]).filter(w=>w.ici).map(w=>w.branche).join(",")')" "1|master"
assert_eq "S8.2a — dépôt develop + feat sans distant : état ok, 3 rangées, deux worktrees" "$(J "$WORK/develop.json" 'j.etat+"|"+(j.rangees||[]).length+"|"+(j.worktrees||[]).length')" "ok|3|2"
assert_eq "S8.2b — dépôt develop + feat : tag rendu, comptes d'avance nuls partout (jamais un chiffre inventé)" "$(J "$WORK/develop.json" '(j.tags||[]).map(t=>t.nom).join(",")+"|"+(j.parBranche||[]).map(b=>b.nom+":"+b.avance).sort().join(",")')" "v-d|develop:null,feat:null"
assert_eq "S8.2c — dépôt develop + feat : feat reste étiquetée sur le graphe (non repliée faute de base)" "$(J "$WORK/develop.json" '(j.rangees||[]).flatMap(r=>r.refs).map(e=>e.nom).filter(n=>n==="feat"||n==="develop").sort().join(",")')" "develop,feat"
# aucune construction d'argv qui reçoive null ou undefined : aucun jeton « null » ni « undefined » dans un seul des argv git lancés, et l'emballage est vu à l'œuvre
assert_eq "S8.3 — argv git des deux lectures : aucun jeton null/undefined, ni --not sans révision (emballage vu : au moins 10 appels)" "$(grep -cE '(^| )(null|undefined)( |$)' "$WORK/git-base.log")|$(grep -c -- '--not' "$WORK/git-base.log")|$([ "$(grep -c . "$WORK/git-base.log")" -ge 10 ] && echo vu || echo aveugle)" "0|0|vu"
assert_eq "S8.4 — témoin positif : un dépôt AVEC base (lab principal) émet bien --not (le zéro de S8.3 vient de l'absence de base, pas d'un argv jamais sondé)" "$(export VF_GITLOG="$WORK/git-lab.log"; : > "$VF_GITLOG"; PATH="$WORK/bin:$PATH" node "$AUX/lire.mjs" "$SCRIPTS" "$LAB" > /dev/null 2>&1; grep -c -- '--not' "$VF_GITLOG" | tr -d ' ' | awk '{print ($1>0)?"oui":"non"}')" "oui"
assert_eq "M-NOBASE.0 — mutant avec effet (le défaut revient : --not est émis même sans base)" "$(mutant nobase "...(refBase ? ['--not', refBase] : [])" "'--not', refBase")" "effet"
LIREM nobase "$WORK/r-master" > "$WORK/m-nobase-m.json"; LIREM nobase "$WORK/r-develop" > "$WORK/m-nobase-d.json"; LIREM nobase "$LAB" > "$WORK/m-nobase-lab.json"
assert_eq "M-NOBASE — le défaut revient : les deux dépôts sans base redeviennent indisponibles (S8.1a et S8.2a rougissent pour leur raison), le lab AVEC base reste lu (le mutant ne casse que la raison visée)" "$(J "$WORK/m-nobase-m.json" 'j.etat')|$(J "$WORK/m-nobase-d.json" 'j.etat')|$(J "$WORK/m-nobase-lab.json" 'j.etat')" "indisponible|indisponible|ok"

echo "=== S9 — revue serveur 2026-11-06, R3 (P78-D-41) : GET /api/vf/git ne bloque pas la boucle du serveur ==="
# git emballé : `log` pose un marqueur puis dort 0,5 s (le graphe en lance deux : lecture de plus de 1 s), tout le reste passe tel quel. La requête légère part QUAND le marqueur existe, c'est-à-dire
# pendant que le premier `log` tourne : un git synchrone gèle la boucle, le marqueur n'est vu qu'après la lecture (ordre déterministe, indépendant de la durée de ce qui précède).
WRAPG="$WORK/wrap-glog"; mkdir -p "$WRAPG"; MARQG="$WORK/glog.marque"
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = log ] && { : > "%s"; sleep 0.5; }; done\nexec "%s" "$@"\n' "$MARQG" "$GIT_REEL" > "$WRAPG/git"; chmod +x "$WRAPG/git"
# lat.mjs <scripts> <lab> : serveur http en processus avec le VRAI routeGit des <scripts> ; la lecture du graphe part, 150 ms plus tard une requête légère ; rend « légère terminée avant la lourde | état | lourde lente »
cat > "$AUX/lat-git.mjs" <<'JS'
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import fs from 'node:fs';
const [, , scripts, lab, marque] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href);
const json = (res, code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(obj)); };
const srv = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  if (url.pathname === '/legere') { res.end('ok'); return; }
  if (!m.routeGit(req, res, url, { root: lab, json })) { res.writeHead(404); res.end(); }
}).listen(0, '127.0.0.1', async () => {
  const port = srv.address().port, t0 = Date.now();
  const get = (p) => new Promise((ok) => http.get({ host: '127.0.0.1', port, path: p }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => ok({ ms: Date.now() - t0, b })); }));
  const lourde = get('/api/vf/git');
  for (let i = 0; i < 1000 && !fs.existsSync(marque); i++) await new Promise((r) => setTimeout(r, 10)); // le premier `log` est lancé
  const legere = await get('/legere');
  const l = await lourde;
  let etat = 'illisible'; try { etat = JSON.parse(l.b).etat; } catch {}
  console.log(`${legere.ms < l.ms}|${etat}|${l.ms >= 1000}`);
  srv.close(); process.exit(0);
});
JS
LATG() { rm -f "$MARQG"; PATH="$WRAPG:$PATH" node "$AUX/lat-git.mjs" "$1" "$LAB" "$MARQG" 2>&1 | tail -1; }
assert_eq "S9.1 — pendant une lecture lente du graphe (git emballé : > 1 s), une requête légère est servie AVANT la fin de la lecture ; la lecture aboutit (état ok)" "$(LATG "$SCRIPTS")" "true|ok|true"
# S9.2 : l'en-tête servi dans le graphe (lecture asynchrone) est celui de enteteGit (lecture synchrone de /api/vf/git/entete), sur six dépôts : ok, worktree, détaché, hors dépôt, sans commit, sans base
cat > "$AUX/parite-entete.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, ...labs] = process.argv;
const g = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git.mjs')).href);
const e = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git-entete.mjs')).href);
const out = [];
for (const lab of labs) { const a = JSON.stringify((await g.lireGit(lab)).entete), b = JSON.stringify(e.enteteGit(lab)); out.push(a === b ? 'egal' : `DIFF ${a} ${b}`); }
console.log(out.join('|'));
JS
PARITE="egal|egal|egal|egal|egal|egal"
assert_eq "S9.2 — enteteGit et son miroir asynchrone rendent le même objet (lab, worktree, détaché, hors dépôt, sans commit, sans base)" "$(node "$AUX/parite-entete.mjs" "$SCRIPTS" "$LAB" "$WORK/wt-b" "$WORK/wt-det" "$WORK/hors-depot" "$WORK/r-vide" "$WORK/r-master" 2>&1 | tail -1)" "$PARITE"
# S9.3 (78-05, revue de delta F2, P78-D-41 étendue) : GET /api/vf/git/entete ne lance pas non plus de git synchrone sur la boucle. git emballé : `rev-parse --git-common-dir` dort 1,2 s ;
# même forme que X6 : légère servie AVANT la fin de la lecture de l'en-tête, qui aboutit (état ok) et qui est lente.
WRAPE="$WORK/wrap-entete"; mkdir -p "$WRAPE"
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = --git-common-dir ] && sleep 1.2; done\nexec "%s" "$@"\n' "$GIT_REEL" > "$WRAPE/git"; chmod +x "$WRAPE/git"
cat > "$AUX/lat-entete.mjs" <<'JS'
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
  const lourde = get('/api/vf/git/entete');
  await new Promise((r) => setTimeout(r, 150));
  const legere = await get('/legere');
  const l = await lourde;
  let etat = 'illisible'; try { etat = JSON.parse(l.b).etat; } catch {}
  console.log(`${legere.ms < l.ms}|${etat}|${l.ms >= 1000}`);
  srv.close(); process.exit(0);
});
JS
LATE() { PATH="$WRAPE:$PATH" node "$AUX/lat-entete.mjs" "$1" "$LAB" 2>&1 | tail -1; }
assert_eq "S9.3 — pendant une lecture lente de l'en-tête (git emballé : > 1 s), une requête légère est servie AVANT la fin de la lecture ; la lecture aboutit (état ok)" "$(LATE "$SCRIPTS")" "true|ok|true"
assert_eq "M-SYNC-ENTETE.0 — mutant avec effet (la route de l'en-tête redevient synchrone : enteteGit)" "$(mutant syncent "enteteAsync(root, finDans(BORNES.echeanceMs)).then((e) => json(res, 200, { schema: SCHEMA_ENTETE, ...e }), () => json(res, 200, { schema: SCHEMA_ENTETE, etat: 'indisponible', depot: '' }));" "json(res, 200, { schema: SCHEMA_ENTETE, ...enteteGit(root) }); // MUTANT : appel git synchrone")" "effet"
A3="$(node "$AUX/mut.mjs" "$WORK/mut/syncent/vf-cockpit-git.mjs" "import { masque } from './vf-cockpit-lecture.mjs';" $'import { masque } from \'./vf-cockpit-lecture.mjs\';\nimport { enteteGit } from \'./vf-cockpit-git-entete.mjs\'; // MUTANT : import ajouté')"
assert_eq "M-SYNC-ENTETE.1 — import ajouté (cible présente)" "$A3" "applique"
assert_eq "M-SYNC-ENTETE — la requête légère n'est servie qu'APRÈS la lecture (légère avant lourde : false), la lecture aboutit et elle est lente (le rouge vient de l'ordre, pas d'un module cassé)" "$(LATE "$WORK/mut/syncent")" "false|ok|true"
assert_eq "M-SYNC-GRAPHE.0 — mutant avec effet (le git du graphe redevient synchrone : lancerGit)" "$(mutant syncg "const git = (...a) => lancerGitAsync(lab, a, { fin });" "const git = async (...a) => lancerGit(lab, a); // MUTANT : appel git synchrone")" "effet"
A2="$(node "$AUX/mut.mjs" "$WORK/mut/syncg/vf-cockpit-git.mjs" "import { lancerGitAsync, finDans }" "import { lancerGit, lancerGitAsync, finDans }")"
assert_eq "M-SYNC-GRAPHE.1 — import ajouté (cible présente)" "$A2" "applique"
assert_eq "M-SYNC-GRAPHE — la requête légère n'est servie qu'APRÈS la lecture (légère avant lourde : false), la lecture aboutit et elle est lente (le rouge vient de l'ordre, pas d'un module cassé)" "$(LATG "$WORK/mut/syncg")" "false|ok|true"
assert_eq "M-ENTETE.0 — mutant avec effet (le miroir asynchrone ne détecte plus le worktree)" "$(mutant entete "const worktree = haut && reel(haut) !== reel(racine) ? path.basename(haut) : null;" "const worktree = null; // MUTANT")" "effet"
assert_eq "M-ENTETE — la parité rougit sur les worktrees (wt-b, wt-det) et sur eux seuls" "$(node "$AUX/parite-entete.mjs" "$WORK/mut/entete" "$LAB" "$WORK/wt-b" "$WORK/wt-det" "$WORK/hors-depot" "$WORK/r-vide" "$WORK/r-master" 2>&1 | tail -1 | tr '|' '\n' | cut -c1-4 | paste -sd'|' -)" "egal|DIFF|DIFF|egal|egal|egal"

echo "=== S10 — REG-D-01 (PU-G-191, PU-G-003) : latence par lancement, échéance de 15 s, git muet jamais « absent », une seule lecture à la fois ==="
# Cause mesurée (diagnostic DG-01) : 12 à 13 lancements git en SÉRIE sous UNE échéance globale ; sous la charge du poste chaque lancement attend 0,1 à 0,45 s d'ordonnancement et l'échéance de 5 s sautait.
# Un `git` emballé dort avant chaque lancement (la charge simulée) puis exécute le vrai. Les échéances réduites (BORNES.echeanceMs posée par le témoin) gardent les cas lents courts, jamais l'échéance par défaut qu'asserte S10.4.
cat > "$AUX/reg.mjs" <<'JS'
// reg.mjs <scripts> <lab> <cas> [échéance en ms] : une ligne.
//   lecture : « graphe|en-tête de la route »   muet : « graphe|en-tête porté par le graphe|route en-tête|en-tête synchrone (avecEcheance) »
//   vol : trois lectures du même lab dont deux arrivent PENDANT la première, puis une quatrième après la fin
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, cas, ech] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const m = await imp('vf-cockpit-git.mjs'), p = await imp('vf-cockpit-paths.mjs'), e = await imp('vf-cockpit-git-entete.mjs');
if (ech) m.BORNES.echeanceMs = Number(ech);
const route = () => new Promise((ok) => m.routeGit({ method: 'GET' }, null, new URL('http://x/api/vf/git/entete'), { root: lab, json: (_r, _c, o) => ok(o) }));
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
if (cas === 'echeance') console.log(m.BORNES.echeanceMs);
else if (cas === 'lecture') { const [g, en] = await Promise.all([m.lireGit(lab), route()]); console.log(`${g.etat}|${en.etat}`); }
else if (cas === 'muet') {
  const sync = p.avecEcheance(Number(ech), () => e.enteteGit(lab)).etat; // synchrone d'abord : il tient la boucle le temps de ses lancements
  const [g, en] = await Promise.all([m.lireGit(lab), route()]);
  console.log(`${g.etat}|${g.entete && g.entete.etat}|${en.etat}|${sync}`);
} else if (cas === 'vol') {
  const a = m.lireGit(lab); await pause(60); const b = m.lireGit(lab); await pause(60); const c = m.lireGit(lab);
  const [ra, rb, rc] = await Promise.all([a, b, c]);
  console.log(`${ra.etat}|${rb.etat}|${rc.etat}|${rb === rc}|${ra === rb}`);
  const d = await m.lireGit(lab);
  console.log(`${d.etat}|${d === rc}`);
}
JS
mklat() { mkdir -p "$WORK/lat-$1"; printf '#!/bin/sh\nsleep %s\nexec "%s" "$@"\n' "$1" "$GIT_REEL" > "$WORK/lat-$1/git"; chmod +x "$WORK/lat-$1/git"; }
mklat 0.45; mklat 1.8; mklat 3.1
REG() { local d="$1"; shift; PATH="$WORK/lat-$d:$PATH" node "$AUX/reg.mjs" "$@" 2>&1 | tail -1; }
REGS() { node "$AUX/reg.mjs" "$@" 2>&1 | tail -1; }
assert_eq "S10.1 — 0,45 s d'attente par lancement (12 x 0,45 > 5 s : rouge à 5b7111f5) : la lecture du graphe et celle de l'en-tête aboutissent" "$(REG 0.45 "$SCRIPTS" "$LAB" lecture)" "ok|ok"
assert_eq "S10.2 — 1,8 s par lancement et une échéance de 3 s : indisponible honnête, jamais un faux ok (le graphe et la route de l'en-tête disent la même chose)" "$(REG 1.8 "$SCRIPTS" "$LAB" lecture 3000)" "indisponible|indisponible"
assert_eq "S10.3 — git muet dès le premier lancement (3,1 s, échéance 3 s) : graphe, en-tête du graphe, route de l'en-tête ET enteteGit synchrone disent « indisponible », jamais « absent » (PU-G-003)" "$(REG 3.1 "$SCRIPTS" "$LAB" muet 3000)" "indisponible|indisponible|indisponible|indisponible"
assert_eq "S10.4 — l'échéance globale par défaut est de 15 000 ms (REG-D-01 étend P78-D-41)" "$(REGS "$SCRIPTS" "$LAB" echeance)" "15000"
assert_eq "S10.5 — témoin positif A5 : « absent » reste « pas un dépôt git » (hors dépôt, sans latence) : graphe, en-tête du graphe, route, synchrone" "$(REGS "$SCRIPTS" "$WORK/hors-depot" muet 3000)" "absent|absent|absent|absent"
# mono-vol : le git emballé compte les `worktree list` (un par lecture du graphe) et dort 0,4 s dessus pour que deux appels arrivent pendant la première lecture
WRAPV="$WORK/wrap-vol"; mkdir -p "$WRAPV"; COMPTEV="$WORK/vol.compte"
printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = worktree ] && { echo w >> "%s"; sleep 0.4; }; done\nexec "%s" "$@"\n' "$COMPTEV" "$GIT_REEL" > "$WRAPV/git"; chmod +x "$WRAPV/git"
rm -f "$COMPTEV"; VOL="$(PATH="$WRAPV:$PATH" node "$AUX/reg.mjs" "$SCRIPTS" "$LAB" vol 2>&1 | tr '\n' ' ')"
assert_eq "S10.6 — trois lectures du même lab, deux arrivant pendant la première : états ok, les deux dernières PARTAGENT une seule lecture (même objet), distincte de la première ; un appel après la fin relance une lecture neuve" "$VOL" "ok|ok|ok|true|false ok|false "
assert_eq "S10.6 — jamais empilées : 3 lectures du graphe en tout (la première, UNE seule suivante pour les deux appels arrivés pendant elle, puis celle de l'appel d'après) ; sans mono-vol : 4" "$(grep -c w "$COMPTEV")" "3"
mutantF() { # nom, fichier, de, vers : copie les scripts, applique la mutation au fichier ; rend « effet » ou « sans-effet »
  rm -rf "$WORK/mut/$1"; mkdir -p "$WORK/mut/$1"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$WORK/mut/$1/"
  local r; r="$(node "$AUX/mut.mjs" "$WORK/mut/$1/$2" "$3" "$4")"
  [ "$r" = applique ] && ! cmp -s "$SCRIPTS/$2" "$WORK/mut/$1/$2" && echo effet || echo sans-effet
}
assert_eq "M-MONOVOL.0 — mutant avec effet (la lecture en cours n'est plus partagée)" "$(mutantF monovol vf-cockpit-git.mjs 'const v = EN_VOL.get(cle);' 'const v = undefined;')" "effet"
rm -f "$COMPTEV"; VOLM="$(PATH="$WRAPV:$PATH" node "$AUX/reg.mjs" "$WORK/mut/monovol" "$LAB" vol 2>&1 | head -1)"
assert_eq "M-MONOVOL — rougit S10.6 : plus de partage (trois lectures distinctes) et 4 lectures du graphe au lieu de 3" "$VOLM|$(grep -c w "$COMPTEV")" "ok|ok|ok|false|false|4"
assert_eq "M-ECHEANCE.0 — mutant avec effet (l'échéance revient à 5 000 ms)" "$(mutantF echeance vf-cockpit-git.mjs 'echeanceMs: 15000' 'echeanceMs: 5000')" "effet"
assert_eq "M-ECHEANCE — rougit S10.1 (indisponible à 0,45 s par lancement) et S10.4 (5000)" "$(PATH="$WORK/lat-0.45:$PATH" node "$AUX/reg.mjs" "$WORK/mut/echeance" "$LAB" lecture 2>&1 | tail -1)|$(node "$AUX/reg.mjs" "$WORK/mut/echeance" "$LAB" echeance 2>&1 | tail -1)" "indisponible|ok|5000"
assert_eq "M-MUET-ASYNC.0 — mutant avec effet (l'en-tête asynchrone retraduit un git muet en « absent »)" "$(mutantF muetasync vf-cockpit-git.mjs "vide(muet ? 'indisponible' : 'absent'" "vide('absent'")" "effet"
assert_eq "M-MUET-ASYNC — rougit S10.3 : l'en-tête porté par le graphe et la route disent « absent » ; le graphe et la version synchrone restent indisponibles (le mutant ne touche qu'un côté)" "$(REG 3.1 "$WORK/mut/muetasync" "$LAB" muet 3000)" "indisponible|absent|absent|indisponible"
assert_eq "M-MUET-SYNC.0 — mutant avec effet (enteteGit synchrone retraduit un git muet en « absent »)" "$(mutantF muetsync vf-cockpit-git-entete.mjs "vide(muet ? 'indisponible' : 'absent'" "vide('absent'")" "effet"
assert_eq "M-MUET-SYNC — rougit S10.3 sur la version synchrone seule (parité R3.3 rompue)" "$(REG 3.1 "$WORK/mut/muetsync" "$LAB" muet 3000)" "indisponible|indisponible|indisponible|absent"

stop_srv
vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
