#!/usr/bin/env bash
# test-cockpit-collecte.sh — la collecte du cockpit hors de la boucle d'événements du serveur (79-09 ; P79-D-12, SOCL-13 ; A31, A47).
#   C0   témoins positifs d'entrée : le faux verrou est appelé par le serveur ; la session de fixture figure dans hello après la première collecte
#   C1   tracer : un serveur dont le verrou est lent répond pendant le tour (latence), dit `collecte` sur sa route d'état, retient hello jusqu'à la première
#        collecte, appelle le verrou une fois par tour, s'arrête sans survivant
#   C10  l'instantané (A31) : null avant la première pose, gelé en profondeur, rappels isolés, jamais de collecte déclenchée par une lecture ;
#        A47 : la signature git y est posée, sans qu'aucune lecture n'appelle git, et un doute ne la remplace pas
#   C2   le pilote avec un fil d'essai : coalescence, mort et relance sans index, indisponible et reprise, mémoire plafonnée, un seul écrivain,
#        garde d'émission injectée, arrêt sans fuite
#   C3   la sonde de latence externe : le rouge AFFIRMÉ du code de départ (f763b556), le code livré (p99 < 50 ms, max < 100 ms), le mutant « en ligne »,
#        le vrai serveur
#   C4   l'index dans le fil : 64 voies, fichier 0600 sans marqueur, pas de réécriture sans changement, ligne géante, empreinte du code évalué,
#        rétention par l'état officiel, voie rattachée à un arbre PROUVÉ (leurres, collision de noms)
#   M-*  mutants sur copie du module : la copie diffère (cmp), charge, et le rouge porte sur la bonne mesure
# Les sections C5 à C11 s'ajoutent à la tâche suivante du plan.
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
const K = process.env.VF_GI_COURT ? 4 : 1; // essai de mutant : attentes écourtées (le rouge est attendu)
const jusque = async (f, ms) => { for (let t = 0; t < ms / K; t += 50) { if (f()) return true; await dormir(50); } return false; };
const appels = () => (fs.existsSync(journal) ? fs.readFileSync(journal, 'utf8').split('\n').filter((l) => l.includes('for-each-ref')).length : 0);
// la première pose est celle du graphe : le collecteur en ligne la fait au premier passage de la boucle, la signature git (plusieurs lancements asynchrones) revient après
let premiere; const off0 = surInstantane((i) => { if (premiere === undefined) premiere = i.git; }); // posé AVANT le démarrage : la première pose est vue
const live = startLive({ root: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), onEvent: (n, d) => evs.push([n, d]), log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1, collecteur: M ? (o) => M.creerCollecteEnLigne(o) : undefined });
const g = () => instantane()?.git ?? null;
await jusque(() => instantane() !== null, 20000); off0();
out['C10.6a'] = instantane() !== null && premiere === null; // l'instantané existe avant toute signature git
await jusque(() => g() !== null, 20000); const g1 = g();
out['C10.6b'] = !!g1 && /^[0-9a-f]{16}$/.test(g1.sig) && Number.isInteger(g1.at) && g1.at > 1.7e12;
await jusque(() => g() && g().at !== g1?.at, 15000); const g2 = g();
out['C10.6c'] = !!g2 && !!g1 && g2.sig === g1.sig && g2.at > g1.at;
execFileSync(process.env.VF_VRAI_GIT, ['-C', lab, '-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-q', '--allow-empty', '-m', 'vide'], { stdio: 'ignore' });
await jusque(() => g() && g().sig !== g1?.sig, 15000); const g3 = g();
out['C10.7a'] = !!g3 && !!g1 && g3.sig !== g1.sig && evs.some(([n, d]) => n === 'git' && d.sig === g3.sig);
await dormir(K > 1 ? 6000 : 0); out.evGit = evs.some(([n]) => n === 'git'); // l'événement git est émis même quand la signature n'est pas rangée (le rouge d'un mutant ne vient pas d'un plantage)
const n0 = appels(); let rappels = 0; const off = surInstantane(() => { rappels++; });
for (let i = 0; i < 200; i++) instantane();
await dormir(400); off();
out['C10.7b'] = appels() === n0 && n0 > 0 && rappels === 0;
fs.writeFileSync(process.env.VF_FAUX_GIT_PANNE, '1');
const n1 = appels(); await jusque(() => appels() > n1, 15000); await dormir(600); const g4 = g();
out['C10.7c'] = appels() > n1 && !!g4 && !!g3 && g4.sig === g3.sig && g4.at === g3.at;
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

# ======================= tâche 2 : le pilote, la preuve de latence, l'index dans le fil =======================
cat > "$AUX/muter.mjs" <<'JS'
// muter.mjs <fichier> <ancre> <de> <vers> [prefixe] : sur l'UNE ligne qui porte « garde:<ancre> », remplace la chaîne <de> (littérale) par <vers> ; <prefixe> : ligne ajoutée en tête
import fs from 'node:fs';
const [, , f, ancre, de, vers, prefixe] = process.argv, L = fs.readFileSync(f, 'utf8').split('\n');
const i = L.map((l, k) => (l.includes('garde:' + ancre) ? k : -1)).filter((k) => k >= 0);
if (i.length !== 1) { console.error(`ancre garde:${ancre} : ${i.length} ligne(s)`); process.exit(2); }
if (!L[i[0]].includes(de)) { console.error(`texte à remplacer absent de la ligne garde:${ancre}`); process.exit(3); }
L[i[0]] = L[i[0]].replace(de, () => vers);
fs.writeFileSync(f, (prefixe ? prefixe + '\n' : '') + L.join('\n'));
JS
# mutant NOM FICHIER ANCRE DE VERS [PREFIXE] -> MUT_SCRIPTS (copie complète du module, le fichier muté seul diffère ; la copie charge sans erreur)
mutant() {
  local nom="$1" fic="$2" ancre="$3" de="$4" vers="$5" pre="${6:-}" d cible
  MUT_SCRIPTS=""; d="$(cockpit_module_copie "$WORK/mut-$nom")" || { echo "mutant $nom : copie impossible"; return 1; }
  cible="$d/scripts/$fic"; cp "$cible" "$WORK/mut-$nom.avant"
  node "$AUX/muter.mjs" "$cible" "$ancre" "$de" "$vers" $pre 2> "$WORK/mut-$nom.err" || { echo "mutant $nom : $(cat "$WORK/mut-$nom.err")"; return 1; }
  cmp -s "$WORK/mut-$nom.avant" "$cible" && { echo "mutant $nom : la copie n'a pas changé"; return 1; }
  node --input-type=module -e "await import('file://$cible')" > /dev/null 2>&1 || { echo "mutant $nom : la copie ne charge pas"; return 1; }
  MUT_SCRIPTS="$d/scripts"; return 0
}
libre_port() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
cat > "$AUX/get.mjs" <<'JS'
// get.mjs <port> <chemin> : corps de la réponse (Host exact), vide si la connexion échoue
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let s = ''; r.on('data', (c) => { s += c; }); r.on('end', () => { process.stdout.write(s); process.exit(0); }); }).on('error', () => process.exit(1));
JS
PILOTE_N=0
pilote() { PILOTE_N=$((PILOTE_N+1)); local d="$WORK/essai-$PILOTE_N"; mkdir -p "$d"; node "$TESTS/collecte-pilote.mjs" "$1" "$TESTS" "$d" "$2" ${3:+"$3"} 2> "$d/err"; }

echo "=== C2 — le pilote : coalescence, mort du fil, mémoire, un seul écrivain, garde, arrêt ==="
pilote "$SCRIPTS" c21 > "$WORK/c21.json"; assert_eq "C2.1 — cinq demandes en rafale pendant un tour lent : deux exécutions au plus, jamais en même temps, la dernière couvre l'union des drapeaux et des motifs" "$(jq_ "$WORK/c21.json" 'j.execs+" "+j.alterne+" "+j.motifs')" "2 true a,b,c"
pilote "$SCRIPTS" c22 > "$WORK/c22.json"; assert_eq "C2.2 — le fil meurt tant qu'il reçoit l'index : relancé sans index, partielle, index suspendu, une relance, cause dans la liste fermée" "$(jq_ "$WORK/c22.json" 'j.vu+" "+j.etat+" "+j.index+" "+j.relances+" "+["memoire","erreur","sortie"].includes(j.cause)+" "+j.lancements')" "true partielle suspendu 1 true 2"
pilote "$SCRIPTS" c23 > "$WORK/c23.json"; assert_eq "C2.3 — le fil meurt toujours : indisponible, le processus vit, un troisième lancement après la pause, retour à ok quand le scénario passe à ok" "$(jq_ "$WORK/c23.json" 'j.indispo+" "+j.lance3+" "+j.retour+" "+j.etat+" "+j.vivant')" "true true true ok true"
pilote "$SCRIPTS" c24 > "$WORK/c24.json"; assert_eq "C2.4 — mémoire de 24 Mio imposée : le fil meurt par la limite, la cause est « memoire », le test continue" "$(jq_ "$WORK/c24.json" 'j.vu+" "+j.cause')" "true memoire"
pilote "$SCRIPTS" c25 > "$WORK/c25.json"; assert_eq "C2.5 — un seul écrivain : pendant une tenue d'écriture de l'ancien fil, redemarrer() n'écrit qu'après la fin de l'écriture de l'ancien (ordre du journal)" "$(jq_ "$WORK/c25.json" 'j.ordre+" "+j.debuts')" "true 2"
mkdir -p "$WORK/lab26"; node "$TESTS/collecte-labo.mjs" lab "$WORK/lab26"; pilote "$SCRIPTS" c26 "$WORK/lab26" > "$WORK/c26.json"
assert_eq "C2.6a — résultat portant une clé interdite à profondeur 3 : instantané précédent gardé (non nul), aucun événement, « qui » vide, collecte.etat partielle" "$(jq_ "$WORK/c26.json" 'j.refus.etat+" "+j.refus.qui+" "+j.refus.evenements')" "partielle 0 0"
assert_eq "C2.6b — témoin positif : le même résultat sans la clé est accepté (« qui » porte w1) et l'état redevient ok" "$(jq_ "$WORK/c26.json" 'j.apres.accepte+" "+j.apres.etat')" "true ok"
pilote "$SCRIPTS" c27 > "$WORK/c27.json"; assert_eq "C2.7 — arreter() : pret résout, une demande ultérieure ne fait rien, le processus sort de lui-même (aucun descripteur ne fuit)" "$(jq_ "$WORK/c27.json" 'j.pret+" "+j.apres+" "+j.fuite')" "true false false"

echo "=== C3 / C4 — la sonde de latence : base, code livré, mutant en ligne, vrai serveur ; index dans le fil ==="
HOMEL="$WORK/home-lourd"; LABL="$WORK/labl"; mkdir -p "$HOMEL"; node "$TESTS/collecte-labo.mjs" lab "$LABL"
node "$TESTS/collecte-labo.mjs" lourd "$HOMEL" "$LABL"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LABL" --quiet > "$WORK/build-l.out" 2>&1 || cat "$WORK/build-l.out"
JM="$WORK/journal-m"
# mesure <scripts> <lab> <home> <duree-ms> <sortie-json> [apres-ms] : harnais mini + sonde (GET toutes les 100 ms) ; écrit <sortie-json>, <sortie-json>.debut (etat au début), .fin (etat à la fin), .stat (index avant/après)
mesure() {
  local sc="$1" lab="$2" home="$3" dur="$4" out="$5" apres="${6:-0}" port st="$WORK/mini-$RANDOM.json" idx
  port="$(libre_port)"; : > "$JM"; idx="$lab/.vibeflow/cockpit/.cache/index-transcripts.json"; rm -f "$idx"
  VF_COCKPIT_SCRIPTS_DIR="$WORK/faux" VF_FAUX_JOURNAL="$JM" VF_FAUX_DELAI=0.4 HOME="$home" node "$TESTS/collecte-mini.mjs" "$sc" "$lab" "$lab/.vibeflow/cockpit" "$port" "$st" > "$WORK/mini.out" 2>&1 &
  MINI_PID=$!; PIDS+=("$MINI_PID")
  attendre 30 test -f "$st" || { echo "  mini : n'écoute pas"; cat "$WORK/mini.out"; }
  node "$AUX/get.mjs" "$port" /etat > "$out.debut" 2> /dev/null
  node "$TESTS/collecte-sonde.mjs" "$port" 100 "$dur" > "$out"
  node "$AUX/get.mjs" "$port" /etat > "$out.fin" 2> /dev/null
  if [ "$apres" -gt 0 ]; then
    node -e 'const f=process.argv[1],fs=require("fs");const s=()=>{try{const t=fs.statSync(f);return [t.ino,t.mtimeMs,(t.mode&0o777).toString(8)].join(" ")}catch{return "absent"}};console.log(s());setTimeout(()=>{console.log(s());process.exit(0)},Number(process.argv[2]))' "$idx" "$apres" > "$out.stat"
  fi
  vf_hyg_stop "$MINI_PID"
}
# C3.0 — le rouge de la base, AFFIRMÉ : le code de départ (f763b556, avant tout code de la phase), même sonde, même faux verrou, même fixture
DEPOT="${VF_COLLECTE_DEPOT:-$(git -C "$SCRIPTS" rev-parse --show-toplevel 2>/dev/null)}"; BASE_SHA=f763b556; BASED="$WORK/base"
if [ -n "$DEPOT" ] && git -C "$DEPOT" cat-file -e "$BASE_SHA^{commit}" 2> /dev/null; then
  mkdir -p "$BASED"; git -C "$DEPOT" archive "$BASE_SHA" plugin/cockpit/scripts | tar -x -C "$BASED"; rm -rf "$BASED/plugin/cockpit/scripts/tests"
  mesure "$BASED/plugin/cockpit/scripts" "$LABL" "$HOMEL" 14000 "$WORK/m-base.json"
  echo "  (base : $(cat "$WORK/m-base.json"))"
  assert_ge "C3.0 — le code de départ (f763b556) fige la boucle : latence maximale d'au moins 300 ms (la mesure sait rougir) ; aucune erreur de connexion" "$(jq_ "$WORK/m-base.json" 'j.erreurs===0 ? j.max : -1')" 300
else
  assert_eq "C3.0 — base absente : historique complet requis (commit f763b556 introuvable)" "absent" "présent"
fi
mesure "$SCRIPTS" "$LABL" "$HOMEL" 14000 "$WORK/m-code.json" 11500
echo "  (code : $(cat "$WORK/m-code.json"))"
assert_eq "C3.1a — témoin d'entrée : la collecte était « en-cours » au début de la mesure et le journal montre au moins deux « status » dans la fenêtre" "$(jq_ "$WORK/m-code.json.debut" 'j.collecte.etat')/$([ "$(grep -c '^status$' "$JM")" -ge 2 ] && echo oui || echo non)" "en-cours/oui"
assert_eq "C3.1b — la sonde a bien mesuré (au moins 100 réponses, aucune erreur de connexion)" "$(jq_ "$WORK/m-code.json" 'j.n>=100 && j.erreurs===0')" "true"
assert_lt "C3.1c — p99 d'une requête légère pendant le remplissage de l'index (50 Mio) et deux tours (ms)" "$(jq_ "$WORK/m-code.json" 'j.p99')" 50
assert_lt "C3.1 — latence maximale pendant le remplissage de l'index et deux tours, faux verrou à 0,4 s (ms)" "$(jq_ "$WORK/m-code.json" 'j.max')" 100
assert_lt "C3.2 — le moniteur de boucle interne dit la même chose : collecte.boucle.maxMs (ms)" "$(jq_ "$WORK/m-code.json.fin" 'j.collecte.boucle.maxMs')" 100
assert_eq "C4.1 — après la première collecte sur la fixture : 64 voies (16 sessions, 48 sous-agents), index ok, collecte ok" "$(jq_ "$WORK/m-code.json.fin" 'j.collecte.index.voies+" "+j.collecte.index.etat+" "+j.collecte.etat')" "64 ok ok"
IDXF="$LABL/.vibeflow/cockpit/.cache/index-transcripts.json"
node --input-type=module -e "const m=await import('file://$SCRIPTS/vf-cockpit-index-cache.mjs');const r=m.chargerIndex(process.argv[1],process.argv[2]);console.log(r.etat+' '+(r.index?r.index.voies.length:0))" "$IDXF" "$LABL" > "$WORK/idx-charge.txt" 2>&1
MODE_IDX="$(sed -n 1p "$WORK/m-code.json.stat" | cut -d' ' -f3)"
assert_eq "C4.2a — .cache/index-transcripts.json existe, en mode 0600, et le chargement de 79-08 l'accepte avec 64 voies" "$MODE_IDX $(cat "$WORK/idx-charge.txt")" "600 lu 64"
MARQ_DANS_TRANSCRIPTS="$(grep -rl 'MARQ-TEXTE' "$HOMEL" 2> /dev/null | head -1)"
assert_eq "C4.2b — aucun marqueur (texte, commande, cible, sortie) dans le fichier d'index ni dans collecte (témoin positif : il est dans les transcripts)" "$([ -n "$MARQ_DANS_TRANSCRIPTS" ] && echo temoin)/$(grep -c 'MARQ-' "$IDXF")/$(grep -c 'MARQ-' "$WORK/m-code.json.fin")" "temoin/0/0"
assert_eq "C4.3 — deux tours sans changement de transcript ne réécrivent pas le fichier (inode et date identiques)" "$([ "$(sed -n 1p "$WORK/m-code.json.stat")" = "$(sed -n 2p "$WORK/m-code.json.stat")" ] && [ "$(sed -n 1p "$WORK/m-code.json.stat")" != absent ] && echo identique || echo different)" "identique"
# C3.3 — mutant M-EN-LIGNE : la ligne garde:collecte-fil exécute la demande sur la boucle
PREF_EL="import * as E from './vf-cockpit-collecte-etapes.mjs';"
VERS_EL="const b = { racine, scriptsDir, home, sortie }, m = enVol, memo = (globalThis.__memo ??= E.creerMemoire()); queueMicrotask(() => { try { if (m.planning) fil.w.emit('message', { type: 'planning', id: m.id, motifs: m.motifs, graphe: E.etapePlanning(b) }); if (m.tour) { const { index, ...t } = E.etapeTour({ ...b, memo }); fil.w.emit('message', { type: 'tour', id: m.id, ...t }); } } catch {} fil.w.emit('message', { type: 'fini', id: m.id }); });"
if mutant M-EN-LIGNE vf-cockpit-collecte.mjs collecte-fil 'fil.w.postMessage(enVol);' "$VERS_EL" "$PREF_EL"; then
  mesure "$MUT_SCRIPTS" "$LABL" "$HOMEL" 14000 "$WORK/m-mut.json"
  echo "  (mutant en ligne : $(cat "$WORK/m-mut.json"))"
  assert_eq "M-EN-LIGNE — la ligne garde:collecte-fil exécute la demande sur la boucle : latence maximale d'au moins 300 ms, aucune erreur de connexion (le rouge vient de la latence, pas d'un plantage)" "$(jq_ "$WORK/m-mut.json" 'j.erreurs===0 && j.n>=20 && j.max>=300')" "true"
else assert_eq "M-EN-LIGNE — construction du mutant" "échec" "ok"; fi
# C3.4 — le vrai serveur lancé par l'aide, mêmes seuils ; fuite de marqueurs vers le flux et la route d'état
: > "$JM"; cockpit_lancer "$LABL" VF_COCKPIT_SCRIPTS_DIR="$WORK/faux" VF_FAUX_JOURNAL="$JM" VF_FAUX_DELAI=0.4 HOME="$HOMEL"
PORTL="$VF_PORT"; TOKL="$VF_JETON"; PIDL="$VF_PID"
lancer_sse "$PORTL" "$TOKL" 60000 "$WORK/el.jsonl"
attendre_hello "$WORK/el.jsonl"
node "$TESTS/collecte-sonde.mjs" "$PORTL" 100 14000 > "$WORK/m-serveur.json"
echo "  (serveur : $(cat "$WORK/m-serveur.json"))"
assert_eq "C3.4a — vrai serveur : la sonde a mesuré (au moins 100 réponses, aucune erreur)" "$(jq_ "$WORK/m-serveur.json" 'j.n>=100 && j.erreurs===0')" "true"
assert_lt "C3.4b — vrai serveur : p99 (ms)" "$(jq_ "$WORK/m-serveur.json" 'j.p99')" 50
assert_lt "C3.4 — vrai serveur : latence maximale pendant des tours sur la fixture volumineuse (ms)" "$(jq_ "$WORK/m-serveur.json" 'j.max')" 100
cockpit_get /api/vf/etat > "$WORK/etat-l.json"
assert_eq "C4.2c — ni le flux (hello compris) ni la route d'état ne portent un marqueur des transcripts" "$(grep -c 'MARQ-' "$WORK/el.jsonl")/$(grep -c 'MARQ-' "$WORK/etat-l.json")" "0/0"
vf_hyg_stop "$SSE_PID"; cockpit_arreter "$PIDL"
# C4.4 — une ligne au-delà de la borne de lecture de l'index (33 Mio + 1 Mio, générés au test)
HOMEG="$WORK/home-geant"; LABG2="$WORK/labg2"; mkdir -p "$HOMEG"; node "$TESTS/collecte-labo.mjs" lab "$LABG2"; node "$TESTS/collecte-labo.mjs" geant "$HOMEG" "$LABG2" geant0001
mesure "$SCRIPTS" "$LABG2" "$HOMEG" 6000 "$WORK/m-geant.json"
echo "  (géante : $(cat "$WORK/m-geant.json"))"
assert_lt "C4.4a — ligne géante : latence maximale d'une requête légère pendant la lecture (ms)" "$(jq_ "$WORK/m-geant.json" 'j.erreurs===0 ? j.max : -1')" 100
assert_eq "C4.4b — le serveur répond, collecte.etat partielle, collecte.index.tronque vrai, les autres voies sont indexées (au moins deux)" "$(jq_ "$WORK/m-geant.json.fin" 'j.collecte.etat+" "+j.collecte.index.tronque+" "+(j.collecte.index.voies>=2)')" "partielle true true"
rm -f "$HOMEG"/.claude/projects/-lab/geant0001.jsonl

echo "=== C4.5 / C4.6 — mutant de relance ; l'empreinte du code évalué couvre le fil ==="
if mutant M-RELANCE vf-cockpit-collecte.mjs collecte-sans-index 'lancer(true);' 'lancer(false);'; then
  pilote "$MUT_SCRIPTS" c22 > "$WORK/c22-mut.json"
  assert_eq "M-RELANCE — la ligne garde:collecte-sans-index relance avec l'index : le scénario mort-avec-index reste indisponible au lieu de partielle (le fil a bien été relancé deux fois)" "$(jq_ "$WORK/c22-mut.json" 'j.etat+" "+j.lancements')" "indisponible 2"
else assert_eq "M-RELANCE — construction du mutant" "échec" "ok"; fi
if mutant M-ECRIVAIN vf-cockpit-collecte.mjs collecte-ecrivain 'await ancien.sorti;' ';'; then
  pilote "$MUT_SCRIPTS" c25 > "$WORK/c25-mut.json"
  assert_eq "M-ECRIVAIN — la ligne garde:collecte-ecrivain n'attend plus la sortie de l'ancien fil : l'écriture du nouveau commence avant la fin de celle de l'ancien (chevauchement au journal)" "$(jq_ "$WORK/c25-mut.json" 'j.ordre+" "+j.debuts')" "false 2"
else assert_eq "M-ECRIVAIN — construction du mutant" "échec" "ok"; fi
if mutant M-GEL vf-cockpit-instantane.mjs instantane-gel 'Object.freeze(o);' ';'; then
  node "$AUX/c10.mjs" "$MUT_SCRIPTS" > "$WORK/c10-mut.json" 2> "$WORK/c10-mut.err"
  assert_eq "M-GEL — la ligne garde:instantane-gel ne gèle plus : C10.2 rougit (objet modifiable), C10.1 reste vrai (pas un plantage)" "$(jq_ "$WORK/c10-mut.json" 'j["C10.2"]+" "+j["C10.1"]')" "false true"
else assert_eq "M-GEL — construction du mutant" "échec" "ok"; fi
if mutant M-GIT vf-cockpit-live.mjs live-git 'gitInfo = { sig: gs.slice(0, 16), at: Date.now() };' ';'; then
  LABM="$WORK/labm"; node "$TESTS/collecte-labo.mjs" lab "$LABM"; : > "$WORK/git-journal-m"
  VF_GI_COURT=1 VF_FAUX_GIT_JOURNAL="$WORK/git-journal-m" VF_FAUX_GIT_PANNE="$WORK/git-panne-m" VF_VRAI_GIT="$VRAI_GIT" node "$AUX/gi.mjs" "$MUT_SCRIPTS" "$TESTS" "$LABM" "$WORK/git-journal-m" > "$WORK/gi-mut.json" 2> "$WORK/gi-mut.err"
  assert_eq "M-GIT — la ligne garde:live-git ne range plus la signature : C10.7a rougit, l'événement git reste émis (pas un plantage)" "$(jq_ "$WORK/gi-mut.json" 'j["C10.7a"]+" "+j.evGit')" "false true"
else assert_eq "M-GIT — construction du mutant" "échec" "ok"; fi
EMP="$WORK/emp"; cockpit_module_copie "$EMP" > /dev/null
emp() { node --input-type=module -e "const m=await import('file://$EMP/scripts/vf-cockpit-module.mjs');console.log(m.empreinteModule({dossierScripts:'$EMP/scripts',dossierMoteur:'$EMP/skills/cockpit-moteur'})||'nul')"; }
E1="$(emp)"; echo '// un octet de plus' >> "$EMP/scripts/vf-cockpit-collecte-fil.mjs"; E2="$(emp)"
assert_eq "C4.6 — l'empreinte du code évalué (79-06) change quand un octet de vf-cockpit-collecte-fil.mjs change (deux empreintes de 12 hexadécimaux)" "$([[ "$E1" =~ ^[0-9a-f]{12}$ ]] && [[ "$E2" =~ ^[0-9a-f]{12}$ ]] && [ "$E1" != "$E2" ] && echo change || echo "$E1/$E2")" "change"

echo "=== C4.7 — la rétention d'une voie au-delà de 24 h vient de l'état officiel (P79-D-29) ==="
cat > "$AUX/c47.mjs" <<'JS'
// c47.mjs <scripts> <tests> <lab> <work> <dossier-verrou> : étapes appelées dans le fil courant, `claude agents --json` simulé, `maintenant` imposé
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, tests, lab, work, faux] = process.argv, imp = (f) => import(pathToFileURL(f).href);
let E, O, L;
try { E = await imp(path.join(scripts, 'vf-cockpit-collecte-etapes.mjs')); O = await imp(path.join(scripts, 'vf-cockpit-etat-officiel.mjs')); L = await imp(path.join(tests, 'collecte-labo.mjs')); } catch (e) { console.log(JSON.stringify({ erreur: String(e.message).slice(0, 160) })); process.exit(0); }
const SID = 'ancienne-aaaa-bbbb-cccc-dddddddddddd', bin = path.join(work, 'bin47'); fs.mkdirSync(bin, { recursive: true });
fs.writeFileSync(path.join(bin, 'claude'), '#!/bin/sh\n[ -n "$VF_FAKE_SORTIE" ] && printf "%s" "$VF_FAKE_SORTIE"\nexit "${VF_FAKE_RC:-0}"\n', { mode: 0o755 });
process.env.PATH = bin + path.delimiter + process.env.PATH;
const out = {};
async function cas(nom, sortieOfficielle, rc = 0) {
  const home = path.join(work, 'home47-' + nom); L.ecrireAncienne(home, lab, SID);
  process.env.VF_FAKE_SORTIE = sortieOfficielle; process.env.VF_FAKE_RC = String(rc);
  await O.rafraichir({ home, cwd: lab });
  const memo = E.creerMemoire(), sortie = path.join(lab, '.vibeflow', 'cockpit', 'c47-' + nom);
  E.etapeTour({ racine: lab, sortie, scriptsDir: faux, home, memo, maintenant: Date.now() });
  out[nom] = !!memo.index && memo.index.voies.some((v) => v.id === SID);
}
await cas('absente', '', 1);
await cas('vivante', JSON.stringify([{ sessionId: SID, state: 'working' }]));
await cas('inconnue', JSON.stringify([{ sessionId: SID }]));
await cas('termine', JSON.stringify([{ sessionId: SID, state: 'done' }]));
console.log(JSON.stringify(out));
JS
node "$AUX/c47.mjs" "$SCRIPTS" "$TESTS" "$LABL" "$WORK" "$WORK/faux" > "$WORK/c47.json" 2> "$WORK/c47.err" || cat "$WORK/c47.err"
assert_eq "C4.7a — session de 25 h, appel d'outil sans résultat, fichier récent : absente des voies quand la carte officielle est absente (un appel ouvert seul ne retient plus)" "$(jq_ "$WORK/c47.json" 'j.absente')" "false"
assert_eq "C4.7b — présente quand la carte officielle la liste vivante, état inconnu compris (témoin positif)" "$(jq_ "$WORK/c47.json" 'j.vivante+" "+j.inconnue')" "true true"
assert_eq "C4.7c — absente quand la carte officielle la dit terminée" "$(jq_ "$WORK/c47.json" 'j.termine')" "false"

echo "=== C4.8 — la voie rattachée à un arbre prouvé du dépôt (P79-D-33, A45, A46) ==="
cat > "$AUX/c48.mjs" <<'JS'
// c48.mjs <scripts> <tests> <work> : `etapeIndex` sur un dépôt de fixture (worktrees vérifiés, sibling, leurres, collision de noms)
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url'; import { execFileSync } from 'node:child_process';
const [, , scripts, tests, work] = process.argv, imp = (f) => import(pathToFileURL(f).href);
let I, E, G, L;
try { I = await imp(path.join(scripts, 'vf-cockpit-collecte-index.mjs')); E = await imp(path.join(scripts, 'vf-cockpit-collecte-etapes.mjs')); G = await imp(path.join(scripts, 'vf-cockpit-git-details.mjs')); L = await imp(path.join(tests, 'collecte-labo.mjs')); }
catch (e) { console.log(JSON.stringify({ erreur: String(e.message).slice(0, 160) })); process.exit(0); }
const lab = path.join(work, 'lab48'), ext = path.join(work, 'ext48'), D1 = path.join(ext, 'leurre1'), D2 = path.join(ext, 'leurre2');
L.creerLab(lab); fs.mkdirSync(ext, { recursive: true });
const git = (...a) => execFileSync('git', ['-C', lab, '-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { stdio: 'ignore' });
const commun = fs.realpathSync(path.join(lab, '.git')), adm = (n) => { const d = path.join(commun, 'worktrees', n); fs.mkdirSync(d, { recursive: true }); return d; };
git('worktree', 'add', '-b', 'b-alpha', path.join(lab, 'wt', 'alpha')); git('worktree', 'add', '-b', 'b-beta', path.join(ext, 'sib', 'beta'));
// leurre 1 : un dossier désigné par un fichier `gitdir` forgé sous le dossier commun, dont le lien retour ne désigne pas le dossier ; leurre 2 : un `.git` qui se dit worktree sans lien retour
fs.mkdirSync(D1, { recursive: true }); const a1 = adm('forge1'); fs.writeFileSync(path.join(a1, 'gitdir'), path.join(D1, '.git') + '\n'); fs.writeFileSync(path.join(a1, 'HEAD'), 'ref: refs/heads/b-alpha\n'); fs.writeFileSync(path.join(a1, 'commondir'), '../..\n');
fs.mkdirSync(D2, { recursive: true }); const a2 = adm('forge2'); fs.writeFileSync(path.join(D2, '.git'), `gitdir: ${a2}\n`); fs.writeFileSync(path.join(a2, 'HEAD'), 'ref: refs/heads/b-alpha\n');
const noms = new Map((await G.etatWorktrees(lab)).worktrees.filter((w) => w.verifie).map((w) => [path.basename(w.chemin), w.nom]));
let n = 0; const tout = [];
const ar = (memo, id) => { const v = memo.index.voies.find((x) => x.id === id); return v ? (v.arbre === null ? 'null' : v.arbre) : 'ABSENT'; };
function passe(sessions) {
  const home = path.join(work, 'home48-' + (++n)); for (const [id, cwd] of Object.entries(sessions)) L.ecrireVoie(home, cwd, id, 5 + n);
  const memo = E.creerMemoire(), sortie = path.join(lab, '.vibeflow', 'cockpit', 'c48-' + n);
  const rapport = I.etapeIndex({ racine: lab, sortie, home, memo, maintenant: Date.now() });
  tout.push(JSON.stringify(memo.index), JSON.stringify(rapport)); try { tout.push(fs.readFileSync(path.join(sortie, '.cache', 'index-transcripts.json'), 'utf8')); } catch {}
  return memo;
}
const out = { noms: Object.fromEntries(noms) };
let m = passe({ 'smain-0001': lab, 'swt-0001': path.join(lab, 'wt', 'alpha'), 'ssib-0001': path.join(ext, 'sib', 'beta'), 'sl1-0001': D1, 'sl2-0001': D2 });
out.A = { main: ar(m, 'smain-0001'), wt: ar(m, 'swt-0001'), sib: ar(m, 'ssib-0001'), l1: ar(m, 'sl1-0001'), l2: ar(m, 'sl2-0001') };
git('worktree', 'add', '-b', 'b-uniq', path.join(ext, 'u', 'uniq')); git('worktree', 'add', '-b', 'b-d1', path.join(ext, 'p1', 'dup')); git('worktree', 'add', '-b', 'b-d2', path.join(ext, 'p2', 'dup'));
git('worktree', 'add', '-b', 'b-q', path.join(ext, 'q', path.basename(lab)));
const noms2 = new Map((await G.etatWorktrees(lab)).worktrees.filter((w) => w.verifie).map((w) => [w.chemin, w.nom]));
m = passe({ 'smain-0002': lab, 'su-0001': path.join(ext, 'u', 'uniq'), 'sd1-0001': path.join(ext, 'p1', 'dup'), 'sd2-0001': path.join(ext, 'p2', 'dup'), 'sq-0001': path.join(ext, 'q', path.basename(lab)) });
out.C = { main: ar(m, 'smain-0002'), uniq: ar(m, 'su-0001'), d1: ar(m, 'sd1-0001'), d2: ar(m, 'sd2-0001'), q: ar(m, 'sq-0001') };
git('worktree', 'remove', '--force', path.join(ext, 'p2', 'dup'));
m = passe({ 'sd1-0002': path.join(ext, 'p1', 'dup') }); out.apres = ar(m, 'sd1-0002');
out.nomUniq = [...noms2].find(([c]) => c.endsWith('/u/uniq'))?.[1]; out.nomDup = [...noms2].find(([c]) => c.endsWith('/p1/dup'))?.[1];
out.balayage = !tout.some((t) => t.includes(work) || t.includes('ext48') || t.includes('lab48'));
console.log(JSON.stringify(out));
JS
node "$AUX/c48.mjs" "$SCRIPTS" "$TESTS" "$WORK" > "$WORK/c48.json" 2> "$WORK/c48.err" || cat "$WORK/c48.err"
assert_eq "C4.8a — arbre principal : voie d'arbre null ; worktree sous le lab et worktree FRÈRE vérifiés : leur nom tel que le rend etatWorktrees (comparé à sa sortie réelle)" "$(jq_ "$WORK/c48.json" '[j.A.main, j.A.wt, j.A.sib, j.noms.alpha, j.noms.beta].join(" ")')" "null alpha beta alpha beta"
assert_eq "C4.8b — leurres : un fichier gitdir forgé (leurre 1) et un .git sans lien retour valide (leurre 2) : aucune voie" "$(jq_ "$WORK/c48.json" 'j.A.l1+" "+j.A.l2')" "ABSENT ABSENT"
assert_eq "C4.8c — collision de nom (A46) : deux worktrees au même nom de dossier et un nom égal à celui de l'arbre principal : aucune voie ; arbre principal inchangé ; nom unique garde sa voie (témoin)" "$(jq_ "$WORK/c48.json" '[j.C.d1, j.C.d2, j.C.q, j.C.main, j.C.uniq, j.nomUniq].join(" ")')" "ABSENT ABSENT ABSENT null uniq uniq"
assert_eq "C4.8c2 — après le retrait d'un des deux, l'autre est admis avec son nom (la règle suit la collision, pas le nom)" "$(jq_ "$WORK/c48.json" 'j.apres+" "+j.nomDup')" "dup dup"
assert_eq "C4.8d — aucun arbre de l'index, du fichier d'index ni du rapport ne contient un chemin (lab, frère, poste)" "$(jq_ "$WORK/c48.json" 'j.balayage')" "true"
if mutant M-ARBRE-DECLARE vf-cockpit-collecte-index.mjs index-arbre 'worktreeVerifie(commun, chemin)' 'true'; then
  node "$AUX/c48.mjs" "$MUT_SCRIPTS" "$TESTS" "$WORK" > "$WORK/c48-m1.json" 2> /dev/null
  assert_eq "M-ARBRE-DECLARE — la ligne garde:index-arbre admet tout arbre listé sans preuve : le leurre 1 obtient une voie, les cas (a) et (c) restent verts" "$(jq_ "$WORK/c48-m1.json" '(j.A.l1!=="ABSENT")+" "+j.A.wt+" "+j.C.d1+" "+j.C.uniq')" "true alpha ABSENT uniq"
else assert_eq "M-ARBRE-DECLARE — construction du mutant" "échec" "ok"; fi
if mutant M-COLLISION vf-cockpit-collecte-index.mjs index-collision 'compte.get(n) > 1' 'false'; then
  node "$AUX/c48.mjs" "$MUT_SCRIPTS" "$TESTS" "$WORK" > "$WORK/c48-m2.json" 2> /dev/null
  assert_eq "M-COLLISION — la ligne garde:index-collision n'écarte plus un nom porté par deux arbres : le cas (c) rougit (d1 obtient une voie), le cas (a) reste vert" "$(jq_ "$WORK/c48-m2.json" '(j.C.d1!=="ABSENT")+" "+j.A.wt+" "+j.A.l1')" "true alpha ABSENT"
else assert_eq "M-COLLISION — construction du mutant" "échec" "ok"; fi

vf_hyg_assert
echo "== Résultats : $PASS PASS / $FAIL FAIL =="
[ "$PASS" -gt 0 ] || { echo "garde anti-vert-à-vide : aucune assertion jouée"; exit 1; }
[ "$FAIL" -eq 0 ]
