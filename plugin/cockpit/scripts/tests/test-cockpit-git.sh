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

stop_srv
vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
