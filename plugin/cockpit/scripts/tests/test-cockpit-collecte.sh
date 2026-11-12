#!/usr/bin/env bash
# test-cockpit-collecte.sh — la collecte du cockpit hors de la boucle d'événements du serveur (79-09 ; P79-D-12, SOCL-13 ; A31, A47).
#   C0   témoins positifs d'entrée : le faux verrou est appelé par le serveur ; la session de fixture figure dans hello après la première collecte
#   C1   tracer : un serveur dont le verrou est lent répond pendant le tour (latence), dit `collecte` sur sa route d'état, retient hello jusqu'à la première
#        collecte, appelle le verrou une fois par tour, s'arrête sans survivant
#   C10  l'instantané (A31) : null avant la première pose, gelé en profondeur, rappels isolés, jamais de collecte déclenchée par une lecture ;
#        A47 : la signature git y est posée, sans qu'aucune lecture n'appelle git, et un doute ne la remplace pas
# Les sections C2 à C4 (fil qui meurt, mémoire, un seul écrivain, index dans le fil, ligne géante) et C5 à C11 s'ajoutent aux tâches suivantes du plan.
# Lab neutre dans mktemp, HOME jetable, isolation git, faux verrou (VF_FAUX_JOURNAL, VF_FAUX_DELAI). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/faux"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$TESTS/hygiene.sh"; vf_hyg_init
. "$TESTS/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_lt() { if [ "${2:--1}" -ge 0 ] 2>/dev/null && [ "$2" -lt "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 < $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (obtenu $2, attendu < $3)"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "${2:--1}" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 >= $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (obtenu $2, attendu >= $3)"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite : client SSE, sonde de latence, lecteurs de JSON ---
cat > "$AUX/sse.mjs" <<'JS'
// sse.mjs <port> <jeton> <maxMs> <fichier> : une ligne JSON par événement (abs = Date.now()), plus une ligne `connecte` écrite à l'envoi de la requête
import http from 'node:http'; import fs from 'node:fs';
const [, , port, token, maxMs, out] = process.argv;
const log = (o) => fs.appendFileSync(out, JSON.stringify({ abs: Date.now(), ...o }) + '\n');
log({ connecte: true });
const req = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events?token=' + token, headers: { Host: `127.0.0.1:${port}` } }, (res) => {
  let buf = '';
  res.on('data', (c) => { buf += c; let i; while ((i = buf.indexOf('\n\n')) >= 0) { const b = buf.slice(0, i); buf = buf.slice(i + 2); const ev = /^event: (.*)$/m.exec(b)?.[1], dt = /^data: (.*)$/m.exec(b)?.[1]; if (ev) { let d = null; try { d = JSON.parse(dt); } catch {} log({ event: ev, data: d }); } } });
});
req.on('error', (e) => { log({ erreur: e.message }); process.exit(0); });
setTimeout(() => { try { req.destroy(); } catch {} process.exit(0); }, Number(maxMs));
JS
cat > "$AUX/sonde.mjs" <<'JS'
// sonde.mjs <port> <periodeMs> <dureeMs> : GET léger (Host exact) toutes les <periodeMs> ms pendant <dureeMs> ; rend { n, erreurs, max, p99 } (latence : envoi -> fin de réponse)
import http from 'node:http';
const [, , port, periode, duree] = process.argv;
const lat = []; let erreurs = 0, envoyees = 0;
const un = () => { envoyees++; const t0 = Date.now(); http.get({ host: '127.0.0.1', port: Number(port), path: '/zz-sonde-collecte', headers: { Host: `127.0.0.1:${port}` } }, (r) => { r.resume(); r.on('end', () => lat.push(Date.now() - t0)); }).on('error', () => { erreurs++; }); };
const t = setInterval(un, Number(periode));
setTimeout(() => { clearInterval(t); setTimeout(() => { const s = [...lat].sort((a, b) => a - b); console.log(JSON.stringify({ n: lat.length, envoyees, erreurs, max: s[s.length - 1] ?? -1, p99: s[Math.min(s.length - 1, Math.floor(s.length * 0.99))] ?? -1 })); process.exit(0); }, 4000); }, Number(duree));
JS
cat > "$AUX/json.mjs" <<'JS'
// json.mjs <fichier> <expression sur j> : sous le nom E pour un fichier de lignes JSON (sse.mjs)
import fs from 'node:fs';
const t = fs.readFileSync(process.argv[2], 'utf8'); let j;
try { j = JSON.parse(t); } catch { j = t.split('\n').filter(Boolean).map((l) => { try { return JSON.parse(l); } catch { return null; } }); }
const v = new Function('j', 'E', 'return (' + process.argv[3] + ')')(j, j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
jq_() { node "$AUX/json.mjs" "$1" "$2" 2>/dev/null || echo illisible; }
now_ms() { node -e 'console.log(Date.now())'; }
mort() { ! _cockpit_vivant "$1"; }
attendre_hello() { for _ in $(seq 1 120); do grep -q '"event":"hello"' "$1" 2>/dev/null && return 0; sleep 0.1; done; return 1; }
lancer_sse() { node "$AUX/sse.mjs" "$1" "$2" "$3" "$4" & SSE_PID=$!; PIDS+=("$SSE_PID"); }

# --- lab neutre, faux verrou, session fraîche, assemblage ---
SID1="aaaa1111-2222-3333-4444-555566667777"
node "$TESTS/collecte-labo.mjs" verrou "$WORK/faux"
mklab() { node "$TESTS/collecte-labo.mjs" lab "$1"; node "$TESTS/collecte-labo.mjs" session "$HOME" "$1" "$SID1"; node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; }; }

echo "=== C0 / C1 — serveur dont le verrou est lent (3 s) : latence, collecte, hello, journal ==="
LAB="$WORK/lab"; mklab "$LAB"; JA="$WORK/journal-a"; : > "$JA"
cockpit_lancer "$LAB" VF_COCKPIT_SCRIPTS_DIR="$WORK/faux" VF_FAUX_JOURNAL="$JA" VF_FAUX_DELAI=3
PORT="$VF_PORT"; TOK="$VF_JETON"
assert_eq "C0.0 — témoin : le serveur écoute (port et jeton lus)" "$([ "$PORT" -gt 0 ] && [ "${#TOK}" -ge 16 ] && echo oui || echo non)" "oui"
cockpit_get /api/vf/etat > "$WORK/etat0.json"
ETAT0="$(jq_ "$WORK/etat0.json" 'j.collecte && j.collecte.etat')"
lancer_sse "$PORT" "$TOK" 40000 "$WORK/ea.jsonl"
attendre_hello "$WORK/ea.jsonl"; HELLO_OK=$?
assert_eq "C0.2 — témoin : hello est reçu et sa liste « qui » contient la session de fixture SID1 (après la première collecte)" "$HELLO_OK $(jq_ "$WORK/ea.jsonl" 'E.filter(e=>e&&e.event==="hello").map(e=>e.data.who.workers.filter(w=>w.id==="'$SID1'").length).join()')" "0 1"
assert_ge "C0.1 — témoin : le faux verrou a été appelé par le serveur (au moins un « status » au journal)" "$(grep -c '^status$' "$JA")" 1
assert_ge "C1.3 — hello attend la première collecte : il arrive au moins 500 ms après la connexion (verrou à 3 s)" "$(jq_ "$WORK/ea.jsonl" '(E.find(e=>e&&e.event==="hello")||{abs:0}).abs-E.find(e=>e&&e.connecte).abs')" 500
node "$AUX/sonde.mjs" "$PORT" 100 8000 > "$WORK/sonde-a.json"
echo "  (sonde : $(cat "$WORK/sonde-a.json"))"
assert_eq "C1.1a — la sonde a bien mesuré (au moins 40 réponses, aucune erreur de connexion)" "$(jq_ "$WORK/sonde-a.json" 'j.n>=40 && j.erreurs===0')" "true"
assert_lt "C1.1 — latence maximale d'une requête légère pendant un tour de 3 s (ms)" "$(jq_ "$WORK/sonde-a.json" 'j.max')" 200
cockpit_get /api/vf/etat > "$WORK/etat1.json"
assert_eq "C1.2a — juste après l'écoute, collecte.etat vaut en-cours" "$ETAT0" "en-cours"
assert_eq "C1.2b — puis collecte.etat vaut ok, derniereA est un ISO, dureeMs un entier positif" "$(jq_ "$WORK/etat1.json" 'j.collecte.etat+" "+/^20[0-9]{2}-[0-9]{2}-[0-9]{2}T/.test(j.collecte.derniereA)+" "+(Number.isInteger(j.collecte.dureeMs)&&j.collecte.dureeMs>0)')" "ok true true"
assert_eq "C1.2c — collecte.mode vaut watch ou poll, collecte.clients vaut 1 tant que le client est connecté" "$(jq_ "$WORK/etat1.json" '(/^(watch|poll)$/.test(j.collecte.mode))+" "+j.collecte.clients')" "true 1"
vf_hyg_stop "$SSE_PID"
PIDA="$VF_PID"; T0="$(now_ms)"; cockpit_arreter "$PIDA"; attendre 5 mort "$PIDA"; RCA=$?
assert_eq "C1.5 — arrêté par l'aide : le serveur sort de lui-même, sans attendre le délai d'inactivité (moins de 5 s)" "$RCA $([ "$(( $(now_ms) - T0 ))" -lt 5000 ] && echo oui || echo non)" "0 oui"

echo "=== C1.4 — un seul appel au verrou par tour du filet ==="
JB="$WORK/journal-b"; : > "$JB"
cockpit_lancer "$LAB" VF_COCKPIT_SCRIPTS_DIR="$WORK/faux" VF_FAUX_JOURNAL="$JB"
PORT="$VF_PORT"; TOK="$VF_JETON"
lancer_sse "$PORT" "$TOK" 40000 "$WORK/eb.jsonl"
attendre_hello "$WORK/eb.jsonl"
: > "$JB"; sleep 5.7
assert_eq "C1.4 — 5,7 s après hello, le journal contient exactement un « status » (un seul appel au verrou par tour)" "$(grep -c '^status$' "$JB")" "1"
vf_hyg_stop "$SSE_PID"; cockpit_arreter "$VF_PID"

echo "=== C10 — l'instantané (A31) ==="
cat > "$AUX/c10.mjs" <<'JS'
// c10.mjs <scripts> : C10.1 à C10.4 sur le module de l'instantané du dossier de scripts testé ; module absent : tout est faux
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const out = {}; let M = null;
try { M = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-instantane.mjs')).href); } catch { M = null; }
const faux = ['C10.1', 'C10.2', 'C10.3', 'C10.4'];
if (!M) { for (const k of faux) out[k] = false; console.log(JSON.stringify(out)); process.exit(0); }
const { instantane, surInstantane, poser } = M;
let refus = false; try { poser({ seq: 'x' }); } catch { refus = true; }
out['C10.1'] = instantane() === null && refus && instantane() === null;
const o = { seq: 1, at: 1, git: { sig: 'a' }, projet: { nodes: [{ id: 'x' }] } };
o.projet.nodes[0].id = 'y'; const modifiable = o.projet.nodes[0].id === 'y'; // témoin positif : l'objet est modifiable avant la pose
const recus = [], autres = [];
const off = surInstantane((i) => recus.push(i.seq));
surInstantane(() => { throw new Error('rappel qui lève'); });
surInstantane((i) => autres.push(i.seq));
let leve = false; try { poser(o); } catch { leve = true; }
const i = instantane(); const tente = (f) => { try { f(); return false; } catch { return true; } };
out['C10.2'] = modifiable && i !== null && tente(() => { i.projet.nodes[0].id = 'z'; }) && tente(() => { i.git.sig = 'b'; }) && tente(() => { i.projet.nodes.push({}); }) && Object.isFrozen(i) && Object.isFrozen(i.projet.nodes[0]);
out['C10.4'] = !leve && i !== null && autres.join() === '1';
poser({ seq: 2 }); const avantOff = recus.join(); off(); poser({ seq: 3 });
out['C10.3'] = recus.join() === '1,2' && avantOff === '1,2' && autres.join() === '1,2,3';
console.log(JSON.stringify(out));
JS
node "$AUX/c10.mjs" "$SCRIPTS" > "$WORK/c10.json" 2> "$WORK/c10.err" || cat "$WORK/c10.err"
assert_eq "C10.1 — instantane() rend null avant toute pose ; un seq non entier est refusé et ne pose rien" "$(jq_ "$WORK/c10.json" 'j["C10.1"]')" "true"
assert_eq "C10.2 — après poser, l'objet est gelé en profondeur (témoin : modifiable avant la pose)" "$(jq_ "$WORK/c10.json" 'j["C10.2"]')" "true"
assert_eq "C10.3 — surInstantane rappelle une fois par pose avec l'instantané, plus rien après la désinscription" "$(jq_ "$WORK/c10.json" 'j["C10.3"]')" "true"
assert_eq "C10.4 — un rappel qui lève n'empêche ni la pose ni les autres rappels" "$(jq_ "$WORK/c10.json" 'j["C10.4"]')" "true"
assert_eq "C10.5 — le module de l'instantané n'importe ni le pilote ni les étapes de la collecte (aucune collecte déclenchée par une lecture)" "$([ -f "$SCRIPTS/vf-cockpit-instantane.mjs" ] && [ "$(grep -cE "^import .*collecte" "$SCRIPTS/vf-cockpit-instantane.mjs")" = 0 ] && echo oui || echo non)" "oui"

echo "=== C10.6 / C10.7 — la signature git dans l'instantané (A47) ==="
mkdir -p "$WORK/fakegit"; VRAI_GIT="$(command -v git)"
cat > "$WORK/fakegit/git" <<'SH'
#!/usr/bin/env bash
echo "$*" >> "$VF_FAUX_GIT_JOURNAL"
case " $* " in *" for-each-ref "*)
  [ ! -f "$VF_FAUX_GIT_PANNE" ] || exit 1 ;;
esac
exec "$VF_VRAI_GIT" "$@"
SH
chmod +x "$WORK/fakegit/git"
cat > "$AUX/gi.mjs" <<'JS'
// gi.mjs <scripts> <tests> <lab> <journal> : startLive avec le collecteur en ligne, un onglet permanent, un faux git de comptage en tête du chemin
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url'; import { execFileSync } from 'node:child_process';
const [, , scripts, tests, lab, journal] = process.argv, imp = (f) => import(pathToFileURL(f).href);
process.env.PATH = path.join(path.dirname(journal), 'fakegit') + path.delimiter + process.env.PATH;
const { startLive } = await imp(path.join(scripts, 'vf-cockpit-live.mjs')), { instantane, surInstantane } = await imp(path.join(scripts, 'vf-cockpit-instantane.mjs'));
let M = null; try { M = await imp(path.join(tests, 'collecte-en-ligne.mjs')); } catch {}
const out = {}, evs = [], dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const jusque = async (f, ms) => { for (let t = 0; t < ms; t += 50) { if (f()) return true; await dormir(50); } return false; };
const appels = () => (fs.existsSync(journal) ? fs.readFileSync(journal, 'utf8').split('\n').filter((l) => l.includes('for-each-ref')).length : 0);
// la première pose est celle du graphe : le collecteur en ligne la fait au premier passage de la boucle, la signature git (plusieurs lancements asynchrones) revient après
let premiere; const off0 = surInstantane((i) => { if (premiere === undefined) premiere = i.git; }); // posé AVANT le démarrage : la première pose est vue
const live = startLive({ root: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), onEvent: (n, d) => evs.push([n, d]), log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1, collecteur: M ? (o) => M.creerCollecteEnLigne(o) : undefined });
const g = () => instantane()?.git ?? null;
await jusque(() => instantane() !== null, 20000); off0();
out['C10.6a'] = instantane() !== null && premiere === null; // l'instantané existe avant toute signature git
await jusque(() => g() !== null, 20000); const g1 = g();
out['C10.6b'] = !!g1 && /^[0-9a-f]{16}$/.test(g1.sig) && Number.isInteger(g1.at) && g1.at > 1.7e12;
await jusque(() => g() && g().at !== g1.at, 15000); const g2 = g();
out['C10.6c'] = !!g2 && g2.sig === g1.sig && g2.at > g1.at;
execFileSync(process.env.VF_VRAI_GIT, ['-C', lab, '-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-q', '--allow-empty', '-m', 'vide'], { stdio: 'ignore' });
await jusque(() => g() && g().sig !== g1.sig, 15000); const g3 = g();
out['C10.7a'] = !!g3 && g3.sig !== g1.sig && evs.some(([n, d]) => n === 'git' && d.sig === g3.sig);
const n0 = appels(); let rappels = 0; const off = surInstantane(() => { rappels++; });
for (let i = 0; i < 200; i++) instantane();
await dormir(400); off();
out['C10.7b'] = appels() === n0 && n0 > 0 && rappels === 0;
fs.writeFileSync(process.env.VF_FAUX_GIT_PANNE, '1');
const n1 = appels(); await jusque(() => appels() > n1, 15000); await dormir(600); const g4 = g();
out['C10.7c'] = appels() > n1 && !!g4 && g4.sig === g3.sig && g4.at === g3.at;
live.stop(); console.log(JSON.stringify(out)); process.exit(0);
JS
export VF_FAUX_GIT_JOURNAL="$WORK/git-journal" VF_FAUX_GIT_PANNE="$WORK/git-panne" VF_VRAI_GIT="$VRAI_GIT"
LABG="$WORK/labg"; node "$TESTS/collecte-labo.mjs" lab "$LABG"; : > "$VF_FAUX_GIT_JOURNAL"
node "$AUX/gi.mjs" "$SCRIPTS" "$TESTS" "$LABG" "$VF_FAUX_GIT_JOURNAL" > "$WORK/gi.json" 2> "$WORK/gi.err" || cat "$WORK/gi.err"
unset VF_FAUX_GIT_JOURNAL VF_FAUX_GIT_PANNE VF_VRAI_GIT
assert_eq "C10.6a — la première pose de l'instantané (celle du graphe) précède toute signature git : git vaut null" "$(jq_ "$WORK/gi.json" 'j["C10.6a"]')" "true"
assert_eq "C10.6b — puis { sig, at } : sig de 16 caractères hexadécimaux, at entier en millisecondes" "$(jq_ "$WORK/gi.json" 'j["C10.6b"]')" "true"
assert_eq "C10.6c — deux calculs successifs sans rien changer rendent le même sig et un at qui avance" "$(jq_ "$WORK/gi.json" 'j["C10.6c"]')" "true"
assert_eq "C10.7a — un commit vide change instantane().git.sig au calcul suivant, l'événement git porte le même sig" "$(jq_ "$WORK/gi.json" 'j["C10.7a"]')" "true"
assert_eq "C10.7b — 200 lectures et un rappel ne lancent pas git (témoin : le journal portait les appels du calcul lui-même)" "$(jq_ "$WORK/gi.json" 'j["C10.7b"]')" "true"
assert_eq "C10.7c — un calcul qui échoue (doute) ne remplace pas la valeur précédente par null (témoin : le calcul a bien eu lieu)" "$(jq_ "$WORK/gi.json" 'j["C10.7c"]')" "true"

vf_hyg_assert
echo "== Résultats : $PASS PASS / $FAIL FAIL =="
[ "$PASS" -gt 0 ] || { echo "garde anti-vert-à-vide : aucune assertion jouée"; exit 1; }
[ "$FAIL" -eq 0 ]
