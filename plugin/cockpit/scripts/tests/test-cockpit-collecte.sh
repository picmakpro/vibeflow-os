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
#   C5   le registre clos lu pour le rattachement (D5) : de bout en bout par le serveur, script sans le verbe, sorties hostiles et bornes, fusion
#   C6   la jointure du rattachement aux voies (A8, A14) : propriété générative (graine imprimée, VF_SEED), lien au signal, mutant
#   C7   A20 : motif de fin d'une session (finMotif) et agents sortis pour silence (sortisSilence), mutants
#   C8   A17 : la signature du who (tout champ ajouté, liste nommée des champs volatils), mutant
#   C11  le cache du scan (AB1) : un lab inchangé ne relance pas le scan ; édition à taille égale, ajout, retrait, git, code du moteur ; mutant
#   C9   A15 : projection des verrous en liste blanche (propriété générative, flux réel, signal construit dans le serveur, contrat), mutants
# Lab neutre dans mktemp, HOME jetable, isolation git, faux verrou (VF_FAUX_JOURNAL, VF_FAUX_DELAI). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
mkdir -p "${TMPDIR:-/tmp}"; WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/faux"
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
  node "$AUX/muter.mjs" "$cible" "$ancre" "$de" "$vers" ${pre:+"$pre"} 2> "$WORK/mut-$nom.err" || { echo "mutant $nom : $(cat "$WORK/mut-$nom.err")"; return 1; }
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
# contenus des transcripts (texte, commande, cible, sortie) : ni branche ni titre, que « qui » montre légitimement
MARQ_CONTENU='MARQ-(TEXTE|COMMANDE|CIBLE|SORTIE|TUR)'
# le flux montre déjà, par le collecteur d'équipe d'avant ce plan, l'intitulé d'une tâche (premier message humain) et la cible relative de la dernière action d'un agent
# actif (`action.cible`, P69-D-16) : pour lui, seuls la commande d'outil et les sorties comptent (l'index, lui, n'en porte aucun : voir C4.2b)
MARQ_FLUX='MARQ-(COMMANDE|SORTIE|TUR)'
IDXF="$LABL/.vibeflow/cockpit/.cache/index-transcripts.json"
node --input-type=module -e "const m=await import('file://$SCRIPTS/vf-cockpit-index-cache.mjs');const r=m.chargerIndex(process.argv[1],process.argv[2]);console.log(r.etat+' '+(r.index?r.index.voies.length:0))" "$IDXF" "$LABL" > "$WORK/idx-charge.txt" 2>&1
MODE_IDX="$(sed -n 1p "$WORK/m-code.json.stat" | cut -d' ' -f3)"
assert_eq "C4.2a — .cache/index-transcripts.json existe, en mode 0600, et le chargement de 79-08 l'accepte avec 64 voies" "$MODE_IDX $(cat "$WORK/idx-charge.txt")" "600 lu 64"
MARQ_DANS_TRANSCRIPTS="$(grep -rl 'MARQ-TEXTE' "$HOMEL" 2> /dev/null | head -1)"
assert_eq "C4.2b — aucun marqueur (texte, commande, cible, sortie) dans le fichier d'index ni dans collecte (témoin positif : il est dans les transcripts)" "$([ -n "$MARQ_DANS_TRANSCRIPTS" ] && echo temoin)/$(grep -cE "$MARQ_CONTENU" "$IDXF")/$(grep -cE "$MARQ_CONTENU" "$WORK/m-code.json.fin")" "temoin/0/0"
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
assert_eq "C4.2c — ni le flux (hello compris) ni la route d'état ne portent un marqueur des transcripts" "$(grep -cE "$MARQ_FLUX" "$WORK/el.jsonl")/$(grep -cE "$MARQ_FLUX" "$WORK/etat-l.json")" "0/0"
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
  assert_eq "M-ECRIVAIN — la ligne garde:collecte-ecrivain n'attend plus la sortie de l'ancien fil : l'écriture du nouveau commence avant la fin de celle de l'ancien (chevauchement au journal)" "$(jq_ "$WORK/c25-mut.json" 'j.ordre+" "+(j.debuts>=2)')" "false true"
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
  mkdir -p "$WORK/c48m1"; node "$AUX/c48.mjs" "$MUT_SCRIPTS" "$TESTS" "$WORK/c48m1" > "$WORK/c48-m1.json" 2> /dev/null
  assert_eq "M-ARBRE-DECLARE — la ligne garde:index-arbre admet tout arbre listé sans preuve : le leurre 1 obtient une voie, les cas (a) et (c) restent verts" "$(jq_ "$WORK/c48-m1.json" '(j.A.l1!=="ABSENT")+" "+j.A.wt+" "+j.C.d1+" "+j.C.uniq')" "true alpha ABSENT uniq"
else assert_eq "M-ARBRE-DECLARE — construction du mutant" "échec" "ok"; fi
if mutant M-COLLISION vf-cockpit-collecte-index.mjs index-collision 'compte.get(n) > 1' 'false'; then
  mkdir -p "$WORK/c48m2"; node "$AUX/c48.mjs" "$MUT_SCRIPTS" "$TESTS" "$WORK/c48m2" > "$WORK/c48-m2.json" 2> /dev/null
  assert_eq "M-COLLISION — la ligne garde:index-collision n'écarte plus un nom porté par deux arbres : le cas (c) rougit (d1 obtient une voie), le cas (a) reste vert" "$(jq_ "$WORK/c48-m2.json" '(j.C.d1!=="ABSENT")+" "+j.A.wt+" "+j.A.l1')" "true alpha ABSENT"
else assert_eq "M-COLLISION — construction du mutant" "échec" "ok"; fi

# ======================= tâche 3 : registre clos, jointure du rattachement, A20, A17, cache du scan =======================
echo "=== C5 — le registre clos reste lu pour le rattachement (D5, P79-D-17) : de bout en bout, dégradation, sortie hostile ==="
DLREEL="$(cd "$SCRIPTS/../../conductor/scripts" && pwd)/driver-lock.sh"
mkdir -p "$WORK/fakebin"; printf '#!/bin/sh\nexit 1\n' > "$WORK/fakebin/claude"; chmod +x "$WORK/fakebin/claude" # jamais le vrai `claude` du poste
SID5="bbbb1111-2222-3333-4444-555566667777"; LAB5="$WORK/lab5"; HOME5="$WORK/home5"
node "$TESTS/collecte-labo.mjs" lab "$LAB5"; node "$TESTS/collecte-labo.mjs" registre "$HOME5" "$LAB5" "$SID5" "$DLREEL"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB5" --quiet > "$WORK/build5.out" 2>&1 || cat "$WORK/build5.out"
assert_eq "C5.0 — témoin : le vrai script a archivé wk01 clos (verrou relâché : status ne tient rien) et registry --all le rend en « done »" "$(cd "$LAB5" && bash "$DLREEL" status | grep -c '"present": *false') $(cd "$LAB5" && bash "$DLREEL" registry --all | node -e 'const j=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(j.agents.map(a=>a.agent_id+":"+a.status+":"+a.node).join())')" "1 wk01:done:n-revue"
cockpit_lancer "$LAB5" HOME="$HOME5" PATH="$WORK/fakebin:$PATH"
lancer_sse "$VF_PORT" "$VF_JETON" 40000 "$WORK/e5.jsonl"
attendre_hello "$WORK/e5.jsonl"
assert_eq "C5.1 — agent consigné puis clos, verrou relâché : hello.who.workers donne à wk01 { rattache, registre, n-revue } et dag égal au fichier du DAG du lab" "$(jq_ "$WORK/e5.jsonl" 'E.filter(e=>e&&e.event==="hello").map(e=>{const w=e.data.who.workers.find(x=>x.id==="wk01");return w&&w.rattachement?[w.rattachement.etat,w.rattachement.source,w.rattachement.noeud,w.rattachement.dag].join("|"):"absent"})[0]')" "rattache|registre|n-revue|.planning/missions/m-revue.dag.json"
vf_hyg_stop "$SSE_PID"; cockpit_arreter "$VF_PID"
mkdir -p "$WORK/faux-sr"; printf '#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"locks\\":[]}" ;; orphans) echo "{\\"orphans\\":[]}" ;; esac\n' > "$WORK/faux-sr/driver-lock.sh"; chmod +x "$WORK/faux-sr/driver-lock.sh"
cat > "$AUX/c5.mjs" <<'JS'
// c5.mjs <scripts> <tests> <work> <mode> : `absente` (script sans le verbe registry), `hostile` (sorties hostiles, bornes, doublons), `fusion`
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, tests, work, mode] = process.argv, imp = (f) => import(pathToFileURL(f).href), S = (f) => imp(path.join(scripts, f));
const out = {}, sortir = () => { console.log(JSON.stringify(out)); process.exit(0); };
let R = null; try { R = await S('vf-cockpit-registre.mjs'); } catch (e) { out.moduleAbsent = String(e.message).slice(0, 120); }
const L = await imp(path.join(tests, 'collecte-labo.mjs'));
const bin = path.join(work, 'fakebin'); process.env.PATH = bin + path.delimiter + process.env.PATH;
if (mode === 'absente') {
  const lab = path.join(work, 'lab52'), home = path.join(work, 'home52'), sr = path.join(work, 'faux-sr');
  L.creerLab(lab); L.ecrireRegistre(home, lab, 'cccc1111-2222-3333-4444-555566667777', null, { mandat: 'reprendre le nœud `n-revue` de la mission' });
  const { collectWho } = await S('vf-cockpit-who.mjs');
  const w = collectWho(lab, { home, scriptsDir: sr }).workers.find((x) => x.id === 'wk01');
  out.collecte = w ? [w.rattachement.etat, w.rattachement.source, w.rattachement.noeud].join('|') : 'absent';
  out.lecture = R ? (await R.lireRegistre({ chemin: path.join(sr, 'driver-lock.sh'), racine: lab })).etat : 'module-absent';
  sortir();
}
if (!R) sortir();
const SEC = 'ghp_' + 'A1b2C3d4E5f6G7h8I9j0K1l2M3n4';
const lab = path.join(work, 'lab53'); L.creerLab(lab);
let n = 0;
const lire = async (contenu) => { // un script de verrou qui rend `contenu` (déjà sérialisé) pour le verbe registry
  const d = path.join(work, 'hostile-' + (++n)); fs.mkdirSync(d, { recursive: true });
  fs.writeFileSync(path.join(d, 'sortie.json'), contenu); fs.writeFileSync(path.join(d, 'driver-lock.sh'), `#!/usr/bin/env bash\ncase "$1" in registry) cat "${path.join(d, 'sortie.json')}" ;; *) echo '{}' ;; esac\n`, { mode: 0o755 });
  try { return await R.lireRegistre({ chemin: path.join(d, 'driver-lock.sh'), racine: lab }); } catch (e) { return { etat: 'LEVE', agents: new Map(), message: String(e.message).slice(0, 80) }; }
};
const ag = (id, o = {}) => ({ agent_id: id, parent: 'p', role: 'vf-coder', node: 'n1', owner: 'm', generation: 'g', dispatched_at: 't', epoch: 5, depth: 2, status: 'done', ...o });
const ids = (r) => [...r.agents.keys()].sort().join();
let r = await lire(JSON.stringify({ present: true, agents: [ag('ok1'), ag('../x'), ag('a b'), ag(7), ag(''), ag('x'.repeat(200)), ag('ok2', { status: 'bizarre' })] }));
out.ids = [r.etat, ids(r)].join('|');
r = await lire(JSON.stringify({ present: true, agents: [ag('ok1', { node: SEC })] })); const nd = r.agents.get('ok1')?.noeud || '';
out.secret = [nd.includes('[masqué]'), !nd.includes('A1b2C3d4')].join();
r = await lire(JSON.stringify({ present: true, agents: Array.from({ length: 6000 }, (_, i) => ({ agent_id: 'a' + i, node: 'n', status: 'done', epoch: i })) }));
out.plafond = [r.etat, r.agents.size].join('|');
r = await lire(JSON.stringify({ present: true, registries: [{ agents: [ag('d1', { status: 'running', epoch: 1, node: 'A' }), ag('d2', { epoch: 5, node: 'B' })] }, { agents: [ag('d1', { epoch: 9, node: 'C' }), ag('d2', { epoch: 7, node: 'D' })] }] }));
out.doublon = [r.agents.get('d1')?.noeud, r.agents.get('d2')?.noeud].join();
const mauvais = []; for (const c of ['[1,2]', 'null', '"x"', '{pas du json', '']) { const x = await lire(c); mauvais.push(x.etat + ':' + x.agents.size); }
out.mauvais = mauvais.join();
r = await lire(JSON.stringify({ present: true, agents: [ag('long1', { node: 'n'.repeat(300), role: 'r'.repeat(300), parent: 'p'.repeat(300) })] })); const g = r.agents.get('long1') || {};
out.bornes = [g.noeud?.length, g.role?.length, g.parent?.length].join();
const carte = new Map([['p1', { noeud: 'orphelin', role: 'x', ws: '' }]]);
R.fusionnerRegistre(carte, new Set(['p1', 'p2', 'p3', 'p4']), { etat: 'lue', agents: new Map([['p1', { noeud: 'ecrase', role: 'r', ws: '', status: 'done', epoch: 1 }], ['p2', { noeud: 'n2', role: 'r', ws: '', status: 'done', epoch: 1 }], ['p3', { noeud: 'n3', role: 'r', ws: '', status: 'running', epoch: 1 }], ['p4', { noeud: '', role: 'r', ws: '', status: 'done', epoch: 1 }], ['p5', { noeud: 'n5', role: 'r', ws: '', status: 'done', epoch: 1 }]]) });
out.fusion = [...carte].map(([k, v]) => k + ':' + v.noeud).sort().join();
sortir();
JS
node "$AUX/c5.mjs" "$SCRIPTS" "$TESTS" "$WORK" absente > "$WORK/c52.json" 2> "$WORK/c52.err" || cat "$WORK/c52.err"
assert_eq "C5.2a — script sans le verbe registry (stdout vide) : la collecte réussit et l'agent dont le mandat cite son nœud reste rattaché par mandat" "$(jq_ "$WORK/c52.json" 'j.collecte')" "rattache|mandat|n-revue"
assert_eq "C5.2b — lireRegistre rend « absente » pour ce script, sans lever" "$(jq_ "$WORK/c52.json" 'j.lecture')" "absente"
node "$AUX/c5.mjs" "$SCRIPTS" "$TESTS" "$WORK" hostile > "$WORK/c53.json" 2> "$WORK/c53.err" || cat "$WORK/c53.err"
assert_eq "C5.3a — identifiants hors ID_RE écartés, statut hors liste écarté : seul ok1 est lu" "$(jq_ "$WORK/c53.json" 'j.ids')" "lue|ok1"
assert_eq "C5.3b — un nœud portant un jeton de forme secrète est masqué" "$(jq_ "$WORK/c53.json" 'j.secret')" "true,true"
assert_eq "C5.3c — 6 000 agents : 5 000 lus" "$(jq_ "$WORK/c53.json" 'j.plafond')" "lue|5000"
assert_eq "C5.3d — un même agent dans deux registres : l'entrée running gagne (A), sinon l'epoch le plus grand (D)" "$(jq_ "$WORK/c53.json" 'j.doublon')" "A,D"
assert_eq "C5.3e — sortie non objet, JSON illisible ou vide : erreur (vide : absente), aucune exception, aucun agent" "$(jq_ "$WORK/c53.json" 'j.mauvais')" "erreur:0,erreur:0,erreur:0,erreur:0,absente:0"
assert_eq "C5.3f — chaque valeur bornée : nœud 128, rôle 80, parent 128" "$(jq_ "$WORK/c53.json" 'j.bornes')" "128,80,128"
assert_eq "C5.3g — fusion : un clos présent avec nœud est ajouté, jamais d'écrasement d'une entrée de orphans, ni running, ni sans nœud, ni absent" "$(jq_ "$WORK/c53.json" 'j.fusion')" "p1:orphelin,p2:n2"

echo "=== C6 — la jointure du rattachement aux voies (A8, A14) : propriété générative et mutant ==="
node "$TESTS/collecte-propriete.mjs" "$SCRIPTS" rattachement ${VF_SEED:+--graine="$VF_SEED"} > "$WORK/c61.out" 2> "$WORK/c61.err" || cat "$WORK/c61.err"
head -1 "$WORK/c61.out" | sed 's/^/  (rattachement : /; s/$/)/'; tail -1 "$WORK/c61.out" > "$WORK/c61.json"
assert_eq "C6.1 — rattacherVoies égale l'oracle de la suite sur toutes les forêts aléatoires (aucun écart, quelle que soit la classe)" "$(jq_ "$WORK/c61.json" 'Object.values(j.resultats.ecarts).join()')" "0,0,0,0,0,0"
assert_eq "C6.couverture — chaque classe est exercée au moins une fois : propre, enfants-uniques, enfants-mixtes, aucun-enfant-rattache, enfants-partiellement-rattaches, session" "$(jq_ "$WORK/c61.json" 'Object.keys(j.couverture||{}).length===6 && Object.values(j.couverture).every(v=>v>0)')" "true"
cat > "$AUX/c62.mjs" <<'JS'
// c62.mjs <scripts> <work> : sur le lab du C5.1, une étape de tour dans le fil courant puis le signal@1 du même lab
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, work] = process.argv, imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
process.env.PATH = path.join(work, 'fakebin') + path.delimiter + process.env.PATH;
const lab = path.join(work, 'lab5'), home = path.join(work, 'home5'), out = {};
try {
  const E = await imp('vf-cockpit-collecte-etapes.mjs'), S = await imp('vf-cockpit-signal.mjs'), memo = E.creerMemoire();
  E.etapeTour({ racine: lab, sortie: path.join(lab, '.vibeflow', 'cockpit', 'c62'), scriptsDir: scripts, home, memo, maintenant: Date.now() });
  const rt = memo.rattachements instanceof Map ? memo.rattachements.get('wk01') : undefined, sig = S.collectSignal(lab, { home, scriptsDir: scripts });
  out.voie = !!memo.index?.voies.some((v) => v.id === 'wk01'); out.rt = rt ? [rt.source, rt.noeud].join('|') : 'absent';
  out.egal = !!rt && sig.missions.length === 1 && rt.dag === sig.missions[0].fichier; out.fichier = sig.missions[0]?.fichier;
} catch (e) { out.erreur = String(e.message).slice(0, 160); }
console.log(JSON.stringify(out));
JS
node "$AUX/c62.mjs" "$SCRIPTS" "$WORK" > "$WORK/c62.json" 2> "$WORK/c62.err" || cat "$WORK/c62.err"
assert_eq "C6.2 — sur le lab du C5.1 : la voie de wk01 existe, rattachement { registre, n-revue }, et son dag vaut exactement signal.missions[].fichier du même lab (même réduction à 200)" "$(jq_ "$WORK/c62.json" '[j.voie,j.rt,j.egal].join(" ")')" "true registre|n-revue true"
if mutant M-ENFANTS vf-cockpit-voies-rattachement.mjs rattachement-enfants 'plans.size === 1' 'plans.size >= 1'; then
  node "$TESTS/collecte-propriete.mjs" "$MUT_SCRIPTS" rattachement --graine="$(head -1 "$WORK/c61.out" | sed 's/graine=//')" 2> /dev/null | tail -1 > "$WORK/c61-m.json"
  assert_eq "M-ENFANTS — la ligne garde:rattachement-enfants prend le premier plan sans exiger l'unanimité : C6.1 rougit sur la classe enfants-mixtes seule" "$(jq_ "$WORK/c61-m.json" 'Object.entries(j.resultats.ecarts).filter(([k,v])=>v>0).map(([k])=>k).join()')" "enfants-mixtes"
else assert_eq "M-ENFANTS — construction du mutant" "échec" "ok"; fi

echo "=== C7 — A20 : motif de fin d'une session (finMotif) et agents sortis pour silence (sortisSilence) ==="
cat > "$AUX/c7.mjs" <<'JS'
// c7.mjs <scripts> <tests> <work> <mode> : `motif` (fausse commande `claude agents --json`), `silence` (cinq sous-agents de silences connus)
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, tests, work, mode] = process.argv, imp = (f) => import(pathToFileURL(f).href), faux = path.join(work, 'faux');
const L = await imp(path.join(tests, 'collecte-labo.mjs')), W = await imp(path.join(scripts, 'vf-cockpit-who.mjs')), O = await imp(path.join(scripts, 'vf-cockpit-etat-officiel.mjs'));
const bin = path.join(work, 'bin7'); fs.mkdirSync(bin, { recursive: true });
fs.writeFileSync(path.join(bin, 'claude'), '#!/bin/sh\ncat "$(dirname "$0")/sortie.json"\n', { mode: 0o755 });
process.env.PATH = bin + path.delimiter + process.env.PATH;
const out = {}, racine = fs.mkdtempSync(path.join(work, 'l7-')), lab = path.join(racine, 'lab'), home = path.join(racine, 'home'); L.creerLab(lab); // un dossier neuf par passage (les mutants rejouent la même fixture)
if (mode === 'motif') {
  const ids = { fail: 'fm-fail', stop: 'fm-stop', done: 'fm-done', live: 'fm-live' };
  for (const id of Object.values(ids)) L.ecrireSession(home, lab, id);
  fs.writeFileSync(path.join(bin, 'sortie.json'), JSON.stringify([{ sessionId: ids.fail, state: 'failed' }, { sessionId: ids.stop, state: 'stopped' }, { sessionId: ids.done, state: 'done' }, { sessionId: ids.live, state: 'working' }]));
  await O.rafraichir({ home, cwd: lab });
  const ws = W.collectWho(lab, { home, scriptsDir: faux, officiel: true }).workers.filter((w) => w.kind === 'session');
  out.sessions = Object.values(ids).map((id) => { const w = ws.find((x) => x.id === id); return w ? `${id}:${w.etat}:${w.finMotif ?? ''}` : id + ':absent'; }).join(' ');
} else {
  L.ecrireSilence(home, lab, 'dddd1111-2222-3333-4444-555566667777');
  const who = W.collectWho(lab, { home, scriptsDir: faux });
  out.sortis = who.sortisSilence; out.ids = who.workers.filter((w) => w.kind === 'subagent').map((w) => w.id).sort().join();
}
console.log(JSON.stringify(out));
JS
node "$AUX/c7.mjs" "$SCRIPTS" "$TESTS" "$WORK" motif > "$WORK/c71.json" 2> "$WORK/c71.err" || cat "$WORK/c71.err"
assert_eq "C7.1 — failed, stopped, done, working : finMotif echec, arret, aucun, aucun ; l'état reste termine (la session vivante n'en porte pas)" "$(jq_ "$WORK/c71.json" 'j.sessions')" "fm-fail:termine:echec fm-stop:termine:arret fm-done:termine: fm-live:actif:"
node "$AUX/c7.mjs" "$SCRIPTS" "$TESTS" "$WORK" silence > "$WORK/c72.json" 2> "$WORK/c72.err" || cat "$WORK/c72.err"
assert_eq "C7.2 — sortisSilence vaut 1 (seul le muet de 2 000 s compte : 1 700 s, 90 s, le fini muet et l'agent hors de la fenêtre de 24 h ne comptent pas) ; les trois agents retenus restent dans who" "$(jq_ "$WORK/c72.json" 'j.sortis+" "+j.ids')" "1 sil-b,sil-c,sil-d"
if mutant M-SILENCE vf-cockpit-equipe.mjs equipe-silence 'c.sAge >= SILENCE_MAX_S' 'c.sAge >= 0'; then
  node "$AUX/c7.mjs" "$MUT_SCRIPTS" "$TESTS" "$WORK" silence > "$WORK/c72-m1.json" 2> /dev/null
  assert_eq "M-SILENCE — la ligne garde:equipe-silence compte aussi les récents : C7.2 rougit (obtenu 2 sortis)" "$(jq_ "$WORK/c72-m1.json" 'j.sortis')" "2"
else assert_eq "M-SILENCE — construction du mutant" "échec" "ok"; fi
if mutant M-SILENCE-FENETRE vf-cockpit-equipe.mjs equipe-fenetre 'sAge >= fenetre' 'false'; then
  node "$AUX/c7.mjs" "$MUT_SCRIPTS" "$TESTS" "$WORK" silence > "$WORK/c72-m2.json" 2> /dev/null
  assert_eq "M-SILENCE-FENETRE — la ligne garde:equipe-fenetre ne retient plus la fenêtre : C7.2 rougit pour la seule raison de l'agent hors fenêtre (obtenu 2 sortis, mêmes agents retenus)" "$(jq_ "$WORK/c72-m2.json" 'j.sortis+" "+j.ids')" "2 sil-b,sil-c,sil-d"
else assert_eq "M-SILENCE-FENETRE — construction du mutant" "échec" "ok"; fi
assert_eq "C7.3 — le contrat déclare sortisSilence (facultatif de cockpit-who@2), finMotif (facultatif de travailleur), motifsFin et vueAgents.motifs" "$(node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));const w=j.schemas["vibeflow/cockpit-who@2"];console.log([(w.optionnels||[]).includes("sortisSilence"),w.travailleur.optionnels.includes("finMotif"),JSON.stringify(w.travailleur.motifsFin),JSON.stringify(j.claudeCode.vueAgents.motifs)].join(" "))' "$SCRIPTS/vf-cockpit-interface.json")" 'true true ["echec","arret"] {"failed":"echec","stopped":"arret"}'

echo "=== C8 — A17 : la signature du who couvre tout champ ajouté, moins la liste nommée des champs volatils ==="
node "$TESTS/collecte-propriete.mjs" "$SCRIPTS" signature > "$WORK/c8.out" 2> "$WORK/c8.err" || cat "$WORK/c8.err"
head -1 "$WORK/c8.out" | sed 's/^/  (signature : /; s/$/)/'; tail -1 "$WORK/c8.out" > "$WORK/c8.json"
assert_eq "C8.1 — la liste des champs volatils est exactement at, ageS, dureeS, lastAt" "$(jq_ "$WORK/c8.json" 'j.resultats.liste')" "true"
assert_eq "C8.2 — chaque clé hors liste (premier niveau et travailleur de plus de vingt clés) change la signature, chaque clé de la liste non" "$(jq_ "$WORK/c8.json" '[j.resultats.hors.length,j.resultats.dedans.length,j.resultats.nTrav>=20].join()')" "0,0,true"
assert_eq "C8.3 — l'ordre des clés est sans effet ; un champ inconnu ajouté à un travailleur change la signature sans retouche ; un champ volatil à toute profondeur n'a pas d'effet" "$(jq_ "$WORK/c8.json" '[j.resultats.ordre,j.resultats.ajoute,j.resultats.profondeur].join()')" "true,true,true"
if mutant M-VOLATILS vf-cockpit-who-signature.mjs who-volatils "'lastAt']" "'lastAt', 'titre']"; then
  node "$TESTS/collecte-propriete.mjs" "$MUT_SCRIPTS" signature 2> /dev/null | tail -1 > "$WORK/c8-m.json"
  assert_eq "M-VOLATILS — la ligne garde:who-volatils ajoute titre à la liste : C8.1 et C8.2 rougissent (le renommage d'un travailleur ne change plus la signature)" "$(jq_ "$WORK/c8-m.json" '[j.resultats.liste,j.resultats.hors.join("+")].join(" ")')" "false workers[0].titre"
else assert_eq "M-VOLATILS — construction du mutant" "échec" "ok"; fi

echo "=== C11 — le cache du scan (AB1, P79-D-21) : un lab inchangé ne relance pas le scan ==="
cat > "$AUX/journaliser-scan.mjs" <<'JS'
// journaliser-scan.mjs <scan.mjs de la copie> <journal> : le scan de CETTE copie consigne chaque lancement (une ligne) ; le journal est un chemin posé à l'écriture
import fs from 'node:fs';
const [, , f, journal] = process.argv, L = fs.readFileSync(f, 'utf8').split('\n'), i = L[0].startsWith('#!') ? 1 : 0;
L.splice(i, 0, `import __fs from 'node:fs'; __fs.appendFileSync(${JSON.stringify(journal)}, 'scan\\n');`);
fs.writeFileSync(f, L.join('\n'));
JS
c11_prepare() { C11_MODULE="$1"; C11_JOURNAL="$2"; : > "$C11_JOURNAL"; node "$AUX/journaliser-scan.mjs" "$C11_MODULE/skills/cockpit-moteur/scripts/scan.mjs" "$C11_JOURNAL"; }
c11_assemble() { node "$C11_MODULE/scripts/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/c11-build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/c11-build.out"; }; }
c11_lancements() { wc -l < "$C11_JOURNAL" | tr -d ' '; }
c11_serie() { # c11_serie <nom> -> « C11.1 C11.2 C11.3 C11.4a C11.4b C11.5a C11.5b » (journal après chaque geste)
  local lab="$WORK/lab11-$1" r=""
  node "$TESTS/collecte-labo.mjs" lab "$lab"; c11_assemble "$lab"; r="$(c11_lancements)"
  c11_assemble "$lab"; r="$r $(c11_lancements)"
  node -e 'const fs=require("fs");const f=process.argv[1];const t=fs.readFileSync(f,"utf8");fs.writeFileSync(f,t.replace("REQ-01","REQ-0Z"));const d=new Date(Date.now()+5000);fs.utimesSync(f,d,d)' "$lab/.planning/REQUIREMENTS.md"
  c11_assemble "$lab"; r="$r $(c11_lancements)"
  echo "ajout" > "$lab/ajout.txt"; c11_assemble "$lab"; r="$r $(c11_lancements)"
  rm -f "$lab/ajout.txt"; c11_assemble "$lab"; r="$r $(c11_lancements)"
  for i in $(seq 1 257); do printf '[filter "f%s"]\n\tclean = cat\n' "$i"; done >> "$lab/.git/config"; c11_assemble "$lab"; r="$r $(c11_lancements)"
  echo "// un octet de plus" >> "$C11_MODULE/skills/cockpit-moteur/scripts/scan.mjs"; c11_assemble "$lab"; r="$r $(c11_lancements)"
  echo "$r"
}
c11_prepare "$(cockpit_module_copie "$WORK/c11-module")" "$WORK/scan-journal"
C11="$(c11_serie ok)"
assert_eq "C11.1 — le premier assemblage lance le scan (journal à 1)" "$(echo "$C11" | cut -d' ' -f1)" "1"
assert_eq "C11.2 — un second assemblage sans rien changer ne relance pas le scan (journal toujours à 1)" "$(echo "$C11" | cut -d' ' -f2)" "1"
assert_eq "C11.3 — l'édition d'un fichier du lab à taille égale (contenu et date changés) relance le scan (2)" "$(echo "$C11" | cut -d' ' -f3)" "2"
assert_eq "C11.4 — un fichier ajouté, puis retiré : le scan est relancé chaque fois (3 puis 4)" "$(echo "$C11" | cut -d' ' -f4-5)" "3 4"
assert_eq "C11.5 — l'état de l'environnement git (plus de filtres que la borne) puis le code du moteur (un octet) relancent le scan (5 puis 6)" "$(echo "$C11" | cut -d' ' -f6-7)" "5 6"
if mutant M-CACHE vf-cockpit-code-cache.mjs scan-cache-fichiers '!e.isDirectory()' 'e.isDirectory()'; then
  c11_prepare "$(cockpit_module_copie "$WORK/c11-module-m")" "$WORK/scan-journal-m"
  # le mutant signe les dossiers seuls : le module copié est le module muté (le scan de CETTE copie journalise)
  cp "$MUT_SCRIPTS/vf-cockpit-code-cache.mjs" "$C11_MODULE/scripts/vf-cockpit-code-cache.mjs"
  CM="$(c11_serie mut)"
  assert_eq "M-CACHE — la ligne garde:scan-cache-fichiers signe les dossiers seuls : C11.3 rougit (l'édition de contenu sans changement de dossier ne relance pas : 1 au lieu de 2), le premier assemblage reste à 1" "$(echo "$CM" | cut -d' ' -f1,3)" "1 1"
else assert_eq "M-CACHE — construction du mutant" "échec" "ok"; fi

# ======================= tâche 4 : verrous projetés en liste blanche (A15), signal construit dans le serveur =======================
echo "=== C9.1 / C9.3 — la projection des verrous en liste blanche : propriété générative (graine imprimée), formes, sansSession ==="
node "$TESTS/collecte-propriete.mjs" "$SCRIPTS" verrous ${VF_SEED:+--graine="$VF_SEED"} > "$WORK/c91.out" 2> "$WORK/c91.err" || cat "$WORK/c91.err"
head -1 "$WORK/c91.out" | sed 's/^/  (verrous : /; s/$/)/'; tail -1 "$WORK/c91.out" > "$WORK/c91.json"
assert_eq "C9.1 — verrousDe puis projeterVerrous, et projeterVerrous seul sur des entrées hostiles : aucune clé hors des quatorze, aucun marqueur planté, chaînes bornées, dag borné et revalidé (aucune classe n'a fui)" "$(jq_ "$WORK/c91.json" 'j.erreur||JSON.stringify(j.resultats.ecarts)')" "{}"
assert_eq "C9.couverture — chacune des seize classes (quinze hostiles et la clé en trop) est exercée au moins 20 fois, témoin positif : chaque marqueur planté est dans l'entrée avant projection" "$(jq_ "$WORK/c91.json" 'j.erreur||(Object.keys(j.couverture).length===16 && Object.values(j.couverture).every(v=>v>=20))+" "+(j.resultats.temoin.plante>0 && j.resultats.temoin.plante===j.resultats.temoin.vu)')" "true true"
assert_eq "C9.1b — formes de la sortie du script : absent -> absente, erreur -> erreur, aucun verrou -> lue et plat et vide, forme inconnue ou nulle -> erreur, entrées non tenues écartées" "$(jq_ "$WORK/c91.json" 'j.erreur||j.resultats.formes')" "absente,erreur,luetrue0,erreur,erreur,1"
assert_eq "C9.3 — sansSession : vrai si session_ids est non vide et ne nomme aucune session de la collecte ; faux pour une session présente, pour une liste vide, pour un mélange ; absent sans l'ensemble des sessions" "$(jq_ "$WORK/c91.json" 'j.erreur||j.resultats.c93.sansSession')" "true,false,false,false,false"
assert_eq "C9.3b — leaseS rend la date de prise, childrenRunning et step suivent le verrou, et la projection les garde" "$(jq_ "$WORK/c91.json" 'j.erreur||[j.resultats.c93.lease,j.resultats.c93.enfants,j.resultats.c93.step,j.resultats.c93.proj].join(" ")')" "3000 4 etape true,3000,4,etape"

echo "=== C9.2 / C9.4 / C9.6 — le flux réel : liste blanche seule, même collecte que le signal, un seul appel au verrou ==="
FA="$WORK/faux-a15"; mkdir -p "$FA"
cat > "$FA/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
# faux verrou de forme réelle (status --all d'un lab partitionné) ; `age_seconds` suit le nombre d'appels : l'événement lock change à chaque tour
[ -z "${VF_FAUX_JOURNAL:-}" ] || echo "$1" >> "$VF_FAUX_JOURNAL"
case "$1" in
  status) sed "s/__N__/$(wc -l < "$VF_FAUX_JOURNAL" | tr -d ' ')/" "$VF_FAUX_STATUS" ;;
  orphans) echo '{"orphans":[]}' ;;
  registry) echo '{"present": false, "count": 0, "agents": []}' ;;
  *) echo '{}' ;;
esac
SH
chmod +x "$FA/driver-lock.sh"
cat > "$WORK/a15-status.json" <<'JSON'
{"present": true, "scope": "lab", "location": "/Users/MQLOCATION9/lab/.git/vf-driver", "legacy_lock": false, "children_running": 2, "locks": [
 {"present": true, "owner": "mgr-p79", "step": "exec", "age_seconds": __N__, "ttl": 1800, "stale": false, "generation": "g1", "session_ids": ["MQSESSIONID9a", "MQSESSIONID9b"], "lease_seconds": 3000, "guard_effective": true, "progress_epoch": 1, "progress_age_seconds": 5, "children_running": 2, "scope": "compartiment", "ws": "fiabilite", "phase": "79", "location": "git-common-dir", "lock": "/Users/MQCHEMIN9/lab/.git/vf-driver/ws/fiabilite/DRIVER.lock", "dag": {"ws": "fiabilite", "phase": "79", "at": 1700000000, "nodes": [{"id": "n1", "deps": [], "status": "running"}, {"id": "n2", "deps": ["n1"], "status": "blocked"}]}},
 {"present": false, "lock": "/Users/MQCHEMIN9/lab/.git/vf-driver/DRIVER.lock", "children_running": 0, "scope": "depot"}]}
JSON
LAB9="$WORK/lab9"; mklab "$LAB9"; J9="$WORK/journal-9"; : > "$J9"
cockpit_lancer "$LAB9" VF_COCKPIT_SCRIPTS_DIR="$FA" VF_FAUX_JOURNAL="$J9" VF_FAUX_STATUS="$WORK/a15-status.json"
lancer_sse "$VF_PORT" "$VF_JETON" 40000 "$WORK/e9.jsonl"
attendre_hello "$WORK/e9.jsonl"
for _ in $(seq 1 160); do grep -q '"event":"lock"' "$WORK/e9.jsonl" 2>/dev/null && break; sleep 0.1; done
cockpit_get /api/vf/etat > "$WORK/etat9.json"
assert_ge "C9.2.0 — témoin positif : le faux verrou est appelé et l'événement lock arrive (au moins un status au journal, un lock dans le flux)" "$(( $(grep -c '^status$' "$J9") + $(grep -c '"event":"lock"' "$WORK/e9.jsonl") ))" 2
assert_eq "C9.2a — aucun marqueur (chemin du verrou, emplacement, identifiants de session) dans le flux ni dans la route d'état (témoin : le verrou est bien dans hello, avec son propriétaire)" "$(cat "$WORK/e9.jsonl" "$WORK/etat9.json" | grep -cE 'MQCHEMIN9|MQLOCATION9|MQSESSIONID9')/$(jq_ "$WORK/e9.jsonl" 'E.filter(e=>e&&e.event==="hello").map(e=>e.data.lock.verrous.liste.map(x=>x.owner).join()).join()')" "0/mgr-p79"
assert_eq "C9.2b — l'événement lock a exactement les clés seq, at, verrous ; hello.lock aussi ; aucune clé present ni locks dans l'un ni l'autre" "$(jq_ "$WORK/e9.jsonl" '[E.find(e=>e&&e.event==="lock").data, E.find(e=>e&&e.event==="hello").data.lock].map(o=>Object.keys(o).sort().join()).join("|")+"|"+/"present"|"locks"/.test(JSON.stringify([E.find(e=>e&&e.event==="lock").data, E.find(e=>e&&e.event==="hello").data.lock]))')" "at,seq,verrous|at,seq,verrous|false"
assert_eq "C9.2c — chaque entrée de verrous.liste a exactement les quatorze clés de la liste blanche, dag compris ; sansSession vaut vrai (aucune session de la collecte ne porte MQSESSIONID9a)" "$(jq_ "$WORK/e9.jsonl" 'E.filter(e=>e&&e.event==="hello").map(e=>{const x=e.data.lock.verrous.liste[0];return Object.keys(x).sort().join()+" "+x.sansSession+" "+x.leaseS+" "+x.childrenRunning+" "+x.step+" "+x.dag.nodes.length}).join()')" "ageS,childrenRunning,dag,leaseS,owner,phase,progressAgeS,sansSession,scope,stale,step,tenu,ttl,ws true 3000 2 exec 2"
: > "$J9"; sleep 5.7
assert_eq "C9.4a — un tour du filet (signal construit dans le serveur, équipe et verrous partagés) fait un seul appel status au verrou et au plus un registry" "$(grep -c '^status$' "$J9")/$([ "$(grep -c '^registry$' "$J9")" -le 1 ] && echo oui || echo non)" "1/oui"
vf_hyg_stop "$SSE_PID"; cockpit_arreter "$VF_PID"
cat > "$AUX/c94.mjs" <<'JS'
// c94.mjs <scripts> <lab> : startLive avec le vrai pilote (fil) ; une fois l'instantané posé avec son signal : mêmes entrées de verrou, mêmes identifiants de travailleurs que le flux, champs schema
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv, imp = (f) => import(pathToFileURL(path.join(scripts, f)).href), out = {};
const { startLive } = await imp('vf-cockpit-live.mjs'), { instantane } = await imp('vf-cockpit-instantane.mjs');
const live = startLive({ root: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), onEvent: () => {}, log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1 });
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
for (let t = 0; t < 40000 && !instantane()?.signal; t += 100) await dormir(100);
await live.pret(20000);
const i = instantane(), s = live.snapshot();
try {
  out.verrous = i?.signal ? JSON.stringify(i.signal.verrous.liste) === JSON.stringify(s.lock.verrous.liste) && i.signal.verrous.liste.length === 1 : 'signal absent';
  const ids = (w) => w.map((x) => x.id).sort().join();
  out.equipe = i?.signal ? ids(i.signal.equipe.workers) === ids(s.who.workers) && s.who.workers.length > 0 : 'signal absent';
  out.schemas = [i?.signal?.schema, i?.projet?.schema].join();
  out.gele = !!i?.signal && Object.isFrozen(i.signal) && Object.isFrozen(i.signal.verrous);
} catch (e) { out.erreur = String(e.message).slice(0, 160); }
live.stop(); console.log(JSON.stringify(out)); process.exit(0);
JS
VF_COCKPIT_SCRIPTS_DIR="$FA" VF_FAUX_JOURNAL="$WORK/journal-94" VF_FAUX_STATUS="$WORK/a15-status.json" node "$AUX/c94.mjs" "$SCRIPTS" "$LAB9" > "$WORK/c94.json" 2> "$WORK/c94.err" || cat "$WORK/c94.err"
assert_eq "C9.4b — instantane().signal.verrous.liste porte les mêmes entrées que le flux (une seule collecte)" "$(jq_ "$WORK/c94.json" 'j.erreur||j.verrous')" "true"
assert_eq "C9.4c — instantane().signal.equipe a les mêmes identifiants de travailleurs que le who du flux (au moins un)" "$(jq_ "$WORK/c94.json" 'j.erreur||j.equipe')" "true"
assert_eq "C9.4d — signal et projet portent leur champ schema, et le signal posé est gelé" "$(jq_ "$WORK/c94.json" 'j.erreur||j.schemas+" "+j.gele')" "vibeflow/cockpit-signal@1,vibeflow/cockpit-project@1 true"
cat > "$AUX/c96.mjs" <<'JS'
// c96.mjs <scripts> <lab> : le signal@1 de l'émetteur CLI (sans injection) sur le faux verrou : entrées de verrou dans les clés du contrat ; le contrat déclare les cinq facultatifs et le bloc dag
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv, out = {};
try {
  const S = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-signal.mjs')).href), j = JSON.parse(fs.readFileSync(path.join(scripts, 'vf-cockpit-interface.json'), 'utf8'));
  const v = j.schemas['vibeflow/cockpit-signal@1'].verrou, cles = Object.keys(v), sig = S.collectSignal(lab, { scriptsDir: process.env.VF_COCKPIT_SCRIPTS_DIR });
  const permis = new Set([...v.requis, ...v.optionnels]);
  out.entrees = sig.verrous.liste.length + ' ' + sig.verrous.liste.every((e) => Object.keys(e).every((k) => permis.has(k)) && v.requis.every((k) => k in e));
  out.contrat = ['step', 'childrenRunning', 'dag', 'leaseS', 'sansSession'].every((k) => v.optionnels.includes(k)) + ' ' + !!v.dag + ' ' + (cles.indexOf('dag') === cles.indexOf('requis') + 1);
  out.cli = Object.keys(sig.verrous.liste[0] || {}).includes('sansSession') ? 'sansSession' : 'sans';
} catch (e) { out.erreur = String(e.message).slice(0, 160); }
console.log(JSON.stringify(out));
JS
VF_COCKPIT_SCRIPTS_DIR="$FA" VF_FAUX_JOURNAL="$WORK/journal-96" VF_FAUX_STATUS="$WORK/a15-status.json" node "$AUX/c96.mjs" "$SCRIPTS" "$LAB9" > "$WORK/c96.json" 2> "$WORK/c96.err" || cat "$WORK/c96.err"
assert_eq "C9.6a — signal@1 de l'émetteur CLI : une entrée de verrou, dont toutes les clés sont dans requis et optionnels de cockpit-signal@1.verrou et dont les requis sont tous là ; sansSession absent (l'émetteur ne compare pas aux sessions)" "$(jq_ "$WORK/c96.json" 'j.erreur||j.entrees+" "+j.cli')" "1 true sans"
assert_eq "C9.6b — le contrat déclare step, childrenRunning, dag, leaseS, sansSession en facultatifs de cockpit-signal@1.verrou, décrit le bloc dag, juste après requis" "$(jq_ "$WORK/c96.json" 'j.erreur||j.contrat')" "true true true"
# mutants : la liste blanche recopie l'entrée (M-LISTE), le dag n'est pas revalidé à la projection (M-VERROU-DAG), sansSession ne regarde plus les sessions (M-SANS)
GR="$(head -1 "$WORK/c91.out" | sed 's/graine=//')"
if mutant M-LISTE vf-cockpit-signal.mjs verrou-liste-blanche '({ ws:' '({ ...l, ws:'; then
  node "$TESTS/collecte-propriete.mjs" "$MUT_SCRIPTS" verrous --graine="$GR" 2> /dev/null | tail -1 > "$WORK/c91-ml.json"
  echo "  (M-LISTE : classes qui ont fui : $(jq_ "$WORK/c91-ml.json" 'Object.keys(j.resultats.ecarts||{}).join()'))"
  assert_eq "M-LISTE — la ligne garde:verrou-liste-blanche recopie l'entrée par propagation d'objet : C9.1 rougit et nomme au moins les classes chemin et session-ids" "$(jq_ "$WORK/c91-ml.json" '["chemin","session-ids"].every(c=>c in (j.resultats.ecarts||{}))')" "true"
else assert_eq "M-LISTE — construction du mutant" "échec" "ok"; fi
if mutant M-VERROU-DAG vf-cockpit-signal.mjs verrou-dag 'dagP(l.dag)' '{ dag: l.dag }'; then
  node "$TESTS/collecte-propriete.mjs" "$MUT_SCRIPTS" verrous --graine="$GR" 2> /dev/null | tail -1 > "$WORK/c91-md.json"
  assert_eq "M-VERROU-DAG — la ligne garde:verrou-dag recopie le dag sans le revalider : C9.1 rougit sur les classes dag-id, dag-statut, dag-noeuds, dag-deps, dag-ws-phase et dag-forme" "$(jq_ "$WORK/c91-md.json" '["dag-id","dag-statut","dag-noeuds","dag-deps","dag-ws-phase","dag-forme"].every(c=>c in (j.resultats.ecarts||{}))')" "true"
else assert_eq "M-VERROU-DAG — construction du mutant" "échec" "ok"; fi
if mutant M-SANS vf-cockpit-vie.mjs verrou-sanssession '!ids.some((i) => sessions.has(i))' 'true'; then
  node "$TESTS/collecte-propriete.mjs" "$MUT_SCRIPTS" verrous --graine="$GR" 2> /dev/null | tail -1 > "$WORK/c91-ms.json"
  assert_eq "M-SANS — la ligne garde:verrou-sanssession ne regarde plus les sessions de la collecte : C9.3 rougit (une session présente donne vrai)" "$(jq_ "$WORK/c91-ms.json" 'j.resultats.c93.sansSession')" "true,true,false,true,false"
else assert_eq "M-SANS — construction du mutant" "échec" "ok"; fi

vf_hyg_assert
echo "== Résultats : $PASS PASS / $FAIL FAIL =="
[ "$PASS" -gt 0 ] || { echo "garde anti-vert-à-vide : aucune assertion jouée"; exit 1; }
[ "$FAIL" -eq 0 ]
