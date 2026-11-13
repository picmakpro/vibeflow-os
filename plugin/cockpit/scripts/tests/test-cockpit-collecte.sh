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
#   C12  durcissements après l'audit de sécurité de 79-09 : verrou et registre d'un lab à gitfile sortant jamais lus, signature du lab en lecture bornée,
#        redémarrage réentrant, chien de garde d'une demande en vol, motifs bornés et dédoublonnés (mutants M-LANCEUR-ENFANT à M-DEDOUBLON)
#   C13  correction ciblée après la revue rv2 : un tour qui lève dégrade (étape et fil), signature du cache couvrant config et exclusions, écriture
#        de la signature confinée d'abord et sans lien suivi, motif « confirm » réservé, garde de startLive fermée par défaut, mutants de coalescence,
#        d'arrêt et de garde (C2.1, C2.6a, C2.7, C2.8)
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
const live = startLive({ root: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), onEvent: (n, d) => evs.push([n, d]), log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1, garde: () => true, collecteur: M ? (o) => M.creerCollecteEnLigne(o) : undefined });
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
  # le point d'entrée du fil ne se charge que dans un fil (parentPort nul sur le fil principal) : MUT_NOLOAD=1 saute le chargement, la preuve est l'exécution dans un vrai fil
  [ -n "${MUT_NOLOAD:-}" ] || node --input-type=module -e "await import('file://$cible')" > /dev/null 2>&1 || { echo "mutant $nom : la copie ne charge pas"; return 1; }
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
assert_eq "C2.6a — après un tour ACCEPTÉ (« qui » porte w1), un résultat portant une clé interdite à profondeur 3 : l'instantané du tour précédent est gardé (même objet), « qui » reste celui du tour accepté (sans la clé), aucun événement, collecte.etat partielle" "$(jq_ "$WORK/c26.json" 'j.refus.premier+" "+j.refus.etat+" "+j.refus.qui+" "+j.refus.evenements+" "+j.refus.conserve')" "true partielle 1 0 true"
assert_eq "C2.6b — témoin positif : le même résultat sans la clé est accepté (l'instantané avance) et l'état redevient ok" "$(jq_ "$WORK/c26.json" 'j.apres.accepte+" "+j.apres.etat')" "true ok"
pilote "$SCRIPTS" c28 "$WORK/lab26" > "$WORK/c28.json"; assert_eq "C2.8 — startLive sans garde fournie : garde fermée par défaut, aucun instantané posé, « qui » vide, aucun événement de la collecte, collecte.etat partielle (le serveur fournit la sienne)" "$(jq_ "$WORK/c28.json" 'j.erreur||j.instantane+" "+j.qui+" "+j.evenements+" "+j.etat')" "true 0 0 partielle"
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
assert_eq "C9.couverture — chacune des seize classes (quinze hostiles et la clé en trop) est exercée au moins 20 fois (un marqueur écrasé par une classe suivante de la même entrée ne compte pas), témoin positif : des marqueurs sont bien dans l'entrée avant projection" "$(jq_ "$WORK/c91.json" 'j.erreur||(Object.keys(j.couverture).length===16 && Object.values(j.couverture).every(v=>v>=20))+" "+(j.resultats.temoin.vu>0)')" "true true"
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
{"present": true, "scope": "lab", "location": "/srv/MQLOCATION9/lab/.git/vf-driver", "legacy_lock": false, "children_running": 2, "locks": [
 {"present": true, "owner": "mgr-p79", "step": "exec", "age_seconds": __N__, "ttl": 1800, "stale": false, "generation": "g1", "session_ids": ["MQSESSIONID9a", "MQSESSIONID9b"], "lease_seconds": 3000, "guard_effective": true, "progress_epoch": 1, "progress_age_seconds": 5, "children_running": 2, "scope": "compartiment", "ws": "fiabilite", "phase": "79", "location": "git-common-dir", "lock": "/srv/MQCHEMIN9/lab/.git/vf-driver/ws/fiabilite/DRIVER.lock", "dag": {"ws": "fiabilite", "phase": "79", "at": 1700000000, "nodes": [{"id": "n1", "deps": [], "status": "running"}, {"id": "n2", "deps": ["n1"], "status": "blocked"}]}},
 {"present": false, "lock": "/srv/MQCHEMIN9/lab/.git/vf-driver/DRIVER.lock", "children_running": 0, "scope": "depot"}]}
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
const live = startLive({ root: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), onEvent: () => {}, log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1, garde: () => true });
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

# --- C12 : durcissements après l'audit de sécurité de 79-09 (verrou hors du lab, cache du scan, redémarrage réentrant, chien de garde, motifs bornés)
mkdir -p "$WORK/c12"
cat > "$AUX/c121.mjs" <<'JS'
// c121.mjs <scripts> <travail> : le verrou et le registre d'un lab dont .git désigne un dépôt hors du lab ne sont jamais lus (AUDC-A-02, 79-09 correctif)
import fs from 'node:fs'; import path from 'node:path'; import { spawnSync } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , scripts, w] = process.argv, out = {};
const U = (f) => import(pathToFileURL(path.join(scripts, f)).href);
try {
  const { etapeVerrous } = await U('vf-cockpit-collecte-etapes.mjs'), { lireRegistre } = await U('vf-cockpit-registre.mjs'), { lireVerrous } = await U('vf-cockpit-vie.mjs').catch(() => ({}));
  const faux = path.join(w, 'faux'), journal = path.join(w, 'journal'); fs.mkdirSync(faux, { recursive: true });
  fs.writeFileSync(path.join(faux, 'driver-lock.sh'), `#!/usr/bin/env bash\necho "$1 $2" >> "${journal}"\ncase "$1" in\n status) echo '{"present":true,"scope":"lab","locks":[{"present":true,"owner":"OWNER-ETRANGER","step":"STEP-ETRANGER","ws":"WS-ETRANGER","scope":"phase","phase":"79","age_seconds":1,"ttl":1800,"stale":false}]}' ;;\n registry) echo '{"registries":[{"ws":"w","phase":"79","agents":[{"agent_id":"ag1","status":"done","node":"n1","role":"r","epoch":1}]}]}' ;;\n *) echo '{}' ;;\nesac\n`, { mode: 0o755 });
  const git = (...a) => spawnSync('git', ['-c', 'user.email=a@b.c', '-c', 'user.name=t', ...a], { encoding: 'utf8' });
  const mk = (n) => { const d = path.join(w, n); fs.mkdirSync(d, { recursive: true }); return d; };
  const ord = mk('ordinaire'); git('init', '-q', ord);
  const hote = mk('hote'); git('init', '-q', hote); git('-C', hote, 'commit', '--allow-empty', '-q', '-m', 'x');
  const etr = mk('etranger'); fs.writeFileSync(path.join(etr, '.git'), `gitdir: ${path.join(hote, '.git')}\n`);
  const wt = path.join(w, 'arbre'); git('-C', hote, 'worktree', 'add', '-q', '-b', 'wt', wt);
  const lit = () => { try { return fs.readFileSync(journal, 'utf8').trim().split('\n').filter(Boolean).length; } catch { return 0; } };
  const cas = (nom, lab) => {
    fs.rmSync(journal, { force: true });
    const v = etapeVerrous({ racine: lab, scriptsDir: faux, home: path.join(w, 'home') });
    const r = lireRegistre({ chemin: path.join(faux, 'driver-lock.sh'), racine: lab });
    const dump = JSON.stringify(v) + JSON.stringify([...r.agents]);
    out[nom] = `appels=${lit()} verrous=${v.etat}/${v.liste.length} registre=${r.etat}/${r.agents.size} fuite=${/ETRANGER|ag1/.test(dump)}`;
  };
  cas('ordinaire', ord); cas('worktree', wt); cas('etranger', etr);
} catch (e) { out.erreur = String(e && e.stack || e).slice(0, 300); }
console.log(JSON.stringify(out));
JS
cat > "$AUX/c122.mjs" <<'JS'
// c122.mjs <scripts> <travail> : signatureDuLab sur un `.git` ou un `.git/HEAD` qui est un tube nommé, un lien vers un périphérique sans fin ou un gros fichier : rend vite, mémoire bornée (79-09 correctif)
import fs from 'node:fs'; import path from 'node:path'; import { spawnSync } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , scripts, w, enfant] = process.argv, U = (f) => pathToFileURL(path.join(scripts, f)).href;
if (enfant) { // processus enfant : UNE signature, rend la durée et la mémoire
  const { signatureDuLab } = await import(U('vf-cockpit-code-cache.mjs')), t0 = Date.now();
  const s = signatureDuLab({ lab: enfant, moteur: path.join(scripts, '..', 'skills', 'cockpit-moteur'), etatGit: '[]' });
  console.log(JSON.stringify({ ok: typeof s === 'string' && s.length === 64, ms: Date.now() - t0, rss: Math.round(process.memoryUsage().rss / 1e6) })); process.exit(0);
}
const git = (...a) => spawnSync('git', a, { encoding: 'utf8' }), out = {};
const cas = {
  temoin: (l) => { git('init', '-q', l); },
  'git-tube': (l) => { spawnSync('mkfifo', [path.join(l, '.git')]); },
  'head-tube': (l) => { git('init', '-q', l); fs.rmSync(path.join(l, '.git', 'HEAD')); spawnSync('mkfifo', [path.join(l, '.git', 'HEAD')]); },
  'git-lien-zero': (l) => { fs.symlinkSync('/dev/zero', path.join(l, '.git')); },
  'head-lien-zero': (l) => { git('init', '-q', l); fs.rmSync(path.join(l, '.git', 'HEAD')); fs.symlinkSync('/dev/zero', path.join(l, '.git', 'HEAD')); },
  'head-gros': (l) => { git('init', '-q', l); fs.writeFileSync(path.join(l, '.git', 'HEAD'), 'ref: refs/heads/' + 'x'.repeat(64 << 20)); },
};
for (const [n, f] of Object.entries(cas)) {
  const l = fs.mkdtempSync(path.join(w, 'c.')); f(l); const t0 = Date.now();
  const r = spawnSync(process.execPath, [process.argv[1], scripts, w, l], { timeout: 6000, encoding: 'utf8', killSignal: 'SIGKILL' });
  let j = {}; try { j = JSON.parse(r.stdout.trim().split('\n').pop()); } catch {}
  out[n] = r.signal ? 'bloque:' + r.signal : j.ok === true && j.ms < 3000 && j.rss < 400 ? 'ok' : 'echec:' + JSON.stringify(j);
}
console.log(JSON.stringify(out));
JS
cat > "$AUX/c123-fil.mjs" <<'JS'
// fil d'essai de C12.3 : bat (une ligne au journal toutes les 40 ms) tant qu'il vit ; répond à chaque demande
import { parentPort, workerData, threadId } from 'node:worker_threads'; import fs from 'node:fs'; import path from 'node:path';
const J = path.join(workerData.sortie, 'journal'); fs.appendFileSync(J, `lancement ${threadId}\n`);
setInterval(() => fs.appendFileSync(J, `bat ${threadId}\n`), 40);
parentPort.on('message', (m) => parentPort.postMessage({ type: 'fini', id: m.id }));
JS
cat > "$AUX/c123.mjs" <<'JS'
// c123.mjs <scripts> <travail> : deux redémarrages simultanés ne laissent aucun fil orphelin (un seul fil neuf, rien ne bat après arreter())
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, w] = process.argv, J = path.join(w, 'journal'); fs.writeFileSync(J, '');
const { creerCollecte } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-collecte.mjs')).href);
const lire = () => fs.readFileSync(J, 'utf8').split('\n').filter(Boolean), dort = (ms) => new Promise((r) => setTimeout(r, ms));
const c = creerCollecte({ racine: w, sortie: w, scriptsDir: scripts, home: w, entree: path.join(path.dirname(process.argv[1]), 'c123-fil.mjs') });
await dort(300);
await Promise.all([c.redemarrer({ sansIndex: true }), c.redemarrer({ sansIndex: true }), c.redemarrer()]);
await dort(300);
const lancements = lire().filter((l) => l.startsWith('lancement')).length;
c.arreter(); await dort(400);
const n0 = lire().length; await dort(400);
console.log(JSON.stringify({ lancements, batApresArret: lire().length - n0 })); process.exit(0);
JS
cat > "$AUX/c124-fil.mjs" <<'JS'
// fil d'essai de C12.4 (scénario lu dans le dossier de sortie) : `bloque` (boucle sans fin à la 1re demande du fil AVEC index, le fil relancé répond),
// `lent` (la 1re demande du premier fil dure 1,5 s, ce qui laisse les demandes suivantes s'accumuler) ; toute demande rejouée rend `recu` (nombre de motifs, motifs) puis `fini`
import { parentPort, workerData } from 'node:worker_threads'; import fs from 'node:fs'; import path from 'node:path';
const sc = fs.readFileSync(path.join(workerData.sortie, 'scenario'), 'utf8').trim(); let n = 0;
parentPort.on('message', (m) => {
  n++;
  if (!workerData.sansIndex && n === 1) { if (sc === 'bloque') for (;;) {} Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 1500); }
  parentPort.postMessage({ type: 'recu', id: m.id, n: m.motifs.length, motifs: m.motifs.slice(0, 4), confirm: m.motifs.includes('confirm') });
  parentPort.postMessage({ type: 'fini', id: m.id });
});
JS
cat > "$AUX/c124.mjs" <<'JS'
// c124.mjs <scripts> <travail> : chien de garde d'une demande en vol (un fil bloqué est relancé) et motifs bornés et dédoublonnés (fusion linéaire : N puis 2N)
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, w] = process.argv, out = {}, dort = (ms) => new Promise((r) => setTimeout(r, ms));
const { creerCollecte } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-collecte.mjs')).href);
const entree = path.join(path.dirname(process.argv[1]), 'c124-fil.mjs');
const nouvelle = (scenario, delais) => { const d = fs.mkdtempSync(path.join(w, 'k.')); fs.writeFileSync(path.join(d, 'scenario'), scenario);
  const recus = []; const c = creerCollecte({ racine: d, sortie: d, scriptsDir: scripts, home: d, entree, delais }); c.surResultat((m) => { if (m.type === 'recu') recus.push(m); }); return { c, recus }; };
{ // chien de garde
  const { c, recus } = nouvelle('bloque', { demandeMs: 500, fenetreMortMs: 30000 });
  c.demander({ tour: true, motifs: ['m1'] });
  const t0 = Date.now(); const pret = await c.pret(4000), e = c.etat();
  out.chien = `pret=${pret} relances=${e.relances} mort=${!!e.derniereMort} recu=${recus.length} motifs=${(recus[0] || {}).motifs} ms<4000=${Date.now() - t0 < 4000}`; c.arreter();
}
const mesure = async (N, motif) => { // N demandes pendant que la première dure 1,5 s : la fusion de l'attente
  const { c, recus } = nouvelle('lent', {}); c.demander({ tour: true }); await dort(100);
  const t0 = process.hrtime.bigint(); for (let i = 0; i < N; i++) c.demander({ tour: true, motifs: [motif(i)] });
  const ms = Number(process.hrtime.bigint() - t0) / 1e6; await c.pret(6000); c.arreter();
  return { ms, n: recus.length > 1 ? recus[1].n : -1 };
};
{ // `confirm` réservé : jamais évincé par le plafond, qu'il arrive après une rafale, avant elle, ou seul
  const cas = async (avant, apres) => { const { c, recus } = nouvelle('lent', {}); c.demander({ tour: true }); await dort(100);
    for (let i = 0; i < avant; i++) c.demander({ tour: true, motifs: ['motif-' + i] });
    c.demander({ tour: true, motifs: ['confirm'] });
    for (let i = 0; i < apres; i++) c.demander({ tour: true, motifs: ['suite-' + i] });
    await c.pret(6000); c.arreter(); const r = recus[1]; return r ? `n=${r.n} confirm=${r.confirm}` : 'aucun'; };
  out.confirm = [await cas(70, 0), await cas(0, 70), await cas(0, 0)].join(' | ');
}
const a = await mesure(20000, (i) => 'motif-' + i), b = await mesure(40000, (i) => 'motif-' + i), d = await mesure(2000, (i) => 'm' + (i % 2));
out.bornes = `${a.n},${b.n}`; out.lineaire = `${b.ms < 3 * a.ms + 80 && b.ms < 1500} (${Math.round(a.ms)}ms puis ${Math.round(b.ms)}ms)`; out.dedoublon = d.n;
console.log(JSON.stringify(out)); process.exit(0);
JS
c12run() { local n="$1" scripts="$2"; rm -rf "$WORK/c12/$n"; mkdir -p "$WORK/c12/$n"; node "$AUX/$n.mjs" "$scripts" "$WORK/c12/$n" 2> "$WORK/c12/$n.err" | tail -1 > "$WORK/c12/$n.json"; }
c12run c121 "$SCRIPTS"
assert_eq "C12.1a — lab ordinaire : le verrou et le registre sont lus (témoin positif)" "$(jq_ "$WORK/c12/c121.json" 'j.erreur||j.ordinaire')" "appels=2 verrous=lue/1 registre=lue/1 fuite=true"
assert_eq "C12.1b — arbre de travail dont le gitfile est vérifié (dépôt commun hors du lab) : lu comme avant (témoin positif)" "$(jq_ "$WORK/c12/c121.json" 'j.erreur||j.worktree')" "appels=2 verrous=lue/1 registre=lue/1 fuite=true"
assert_eq "C12.1c — lab dont le .git désigne un dépôt hors du lab : driver-lock.sh n'est jamais lancé, ni verrou ni registre publiés (AUDC-A-02)" "$(jq_ "$WORK/c12/c121.json" 'j.erreur||j.etranger')" "appels=0 verrous=erreur/0 registre=absente/0 fuite=false"
c12run c122 "$SCRIPTS"
assert_eq "C12.2 — signatureDuLab rend vite et sans saturer la mémoire sur un .git ou un .git/HEAD en tube nommé, en lien vers un périphérique sans fin, ou énorme (le témoin ordinaire reste vert)" "$(jq_ "$WORK/c12/c122.json" 'j.erreur||Object.entries(j).map(([k,v])=>k+"="+v).join(" ")')" "temoin=ok git-tube=ok head-tube=ok git-lien-zero=ok head-lien-zero=ok head-gros=ok"
c12run c123 "$SCRIPTS"
assert_eq "C12.3 — trois redémarrages simultanés : un seul fil neuf (deux lancements en tout) et rien ne bat après arreter()" "$(jq_ "$WORK/c12/c123.json" 'j.erreur||j.lancements+" "+j.batApresArret')" "2 0"
c12run c124 "$SCRIPTS"
assert_eq "C12.4a — un fil bloqué sans mourir est relancé après demandeMs : la demande est rejouée, la collecte redevient prête, la mort est comptée" "$(jq_ "$WORK/c12/c124.json" 'j.erreur||j.chien')" "pret=true relances=1 mort=true recu=1 motifs=m1 ms<4000=true"
assert_eq "C12.4b — motifs plafonnés à 64 pour N puis 2N demandes distinctes, et la fusion reste linéaire (le double de demandes ne coûte pas le quadruple)" "$(jq_ "$WORK/c12/c124.json" 'j.erreur||j.bornes+" "+j.lineaire.split(" ")[0]')" "64,64 true"
assert_eq "C12.4c — deux motifs répétés 2 000 fois n'en font que deux" "$(jq_ "$WORK/c12/c124.json" 'j.erreur||j.dedoublon')" "2"
assert_eq "C13.5 — le motif « confirm » n'est jamais évincé par le plafond de 64 : après 70 motifs distincts, avant 70 autres, ou seul, la demande rejouée le porte (64 motifs au plus)" "$(jq_ "$WORK/c12/c124.json" 'j.erreur||j.confirm')" "n=64 confirm=true | n=64 confirm=true | n=1 confirm=true"
# mutants : lanceur sans garde d'enfant (M-LANCEUR-ENFANT), lecture du cache sans O_NONBLOCK (M-CACHE-OUVERTURE) ou à l'ancienne, non bornée (M-CACHE-BORNE), redémarrage non partagé (M-REENTRANT),
# chien de garde inerte (M-CHIEN), motifs sans plafond (M-MOTIFS), motifs sans dédoublonnage (M-DEDOUBLON)
if mutant M-LANCEUR-ENFANT vf-cockpit-git-lanceur.mjs lanceur-enfant-sortant '&& gitSortant(' '&& false && gitSortant('; then
  c12run c121 "$MUT_SCRIPTS"
  assert_eq "M-LANCEUR-ENFANT — sans la garde, le script de verrou d'un lab à gitfile sortant est lancé et son contenu publié : C12.1c rougit" "$(jq_ "$WORK/c12/c121.json" 'j.erreur||j.etranger')" "appels=2 verrous=lue/1 registre=lue/1 fuite=true"
else assert_eq "M-LANCEUR-ENFANT — construction du mutant" "échec" "ok"; fi
if mutant M-CACHE-OUVERTURE vf-cockpit-code-cache.mjs code-cache-ouverture 'fs.constants.O_RDONLY | BAS' 'fs.constants.O_RDONLY'; then
  c12run c122 "$MUT_SCRIPTS"
  assert_eq "M-CACHE-OUVERTURE — sans O_NONBLOCK, l'ouverture d'un tube nommé bloque : C12.2 rougit sur git-tube et head-tube" "$(jq_ "$WORK/c12/c122.json" 'j.erreur||(j["git-tube"].startsWith("bloque")&&j["head-tube"].startsWith("bloque"))')" "true"
else assert_eq "M-CACHE-OUVERTURE — construction du mutant" "échec" "ok"; fi
if mutant M-CACHE-BORNE vf-cockpit-code-cache.mjs code-cache-ouverture "fs.constants.O_RDONLY | BAS);" "fs.constants.O_RDONLY | fs.constants.O_NONBLOCK); return fs.readFileSync(fd, 'utf8').slice(0, 512).trim();"; then
  c12run c122 "$MUT_SCRIPTS"
  assert_eq "M-CACHE-BORNE — l'ancienne lecture (lien suivi, aucun contrôle de type, lecture entière) sature sur un lien vers un périphérique sans fin : C12.2 rougit sur git-lien-zero et head-lien-zero" "$(jq_ "$WORK/c12/c122.json" 'j.erreur||(j["git-lien-zero"].startsWith("bloque")&&j["head-lien-zero"].startsWith("bloque"))')" "true"
else assert_eq "M-CACHE-BORNE — construction du mutant" "échec" "ok"; fi
if mutant M-REENTRANT vf-cockpit-collecte.mjs collecte-reentrant 'if (!redemarrage) ' ''; then
  c12run c123 "$MUT_SCRIPTS"
  assert_eq "M-REENTRANT — sans le partage, trois appels simultanés construisent trois fils : C12.3 rougit (lancements > 2, fils orphelins)" "$(jq_ "$WORK/c12/c123.json" 'j.erreur||(j.lancements>2&&j.batApresArret>0)')" "true"
else assert_eq "M-REENTRANT — construction du mutant" "échec" "ok"; fi
if mutant M-CHIEN vf-cockpit-collecte.mjs collecte-chien 'setTimeout(() => {' 'setTimeout(() => { return;'; then
  c12run c124 "$MUT_SCRIPTS"
  assert_eq "M-CHIEN — chien de garde inerte : le fil bloqué n'est jamais relancé, la collecte reste en cours : C12.4a rougit" "$(jq_ "$WORK/c12/c124.json" 'j.erreur||j.chien.startsWith("pret=false relances=0")')" "true"
else assert_eq "M-CHIEN — construction du mutant" "échec" "ok"; fi
if mutant M-MOTIFS vf-cockpit-collecte.mjs collecte-motifs '.slice(0, MAX_MOTIFS)' ''; then
  c12run c124 "$MUT_SCRIPTS"
  assert_eq "M-MOTIFS — sans plafond, l'attente garde tous les motifs distincts (20 000 puis 40 000) : C12.4b rougit" "$(jq_ "$WORK/c12/c124.json" 'j.erreur||j.bornes')" "20000,40000"
else assert_eq "M-MOTIFS — construction du mutant" "échec" "ok"; fi
if mutant M-DEDOUBLON vf-cockpit-collecte.mjs collecte-motifs '[...new Set([...a, ...b])]' '[...a, ...b]'; then
  c12run c124 "$MUT_SCRIPTS"
  assert_eq "M-DEDOUBLON — sans dédoublonnage, les répétitions comptent (le plafond les garde à 64) : C12.4c rougit" "$(jq_ "$WORK/c12/c124.json" 'j.erreur||j.dedoublon')" "64"
else assert_eq "M-DEDOUBLON — construction du mutant" "échec" "ok"; fi

# --- C13 : correction ciblée après la revue rv2 de 79-09 (tour qui dégrade, signature du cache : config et exclusions, écriture confinée, preuves de coalescence et d'arrêt)
mkdir -p "$WORK/c13"
cat > "$AUX/c131.mjs" <<'JS'
// c131.mjs <scripts> <travail> : etapeTour ne lève jamais, même si la projection des verrous lève (sessions de la collecte hostiles : `has` lève) ; témoin : mémoire ordinaire
import fs from 'node:fs'; import path from 'node:path'; import { spawnSync } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , scripts, w] = process.argv, out = {};
const bin = path.join(w, 'fakebin'); fs.mkdirSync(bin, { recursive: true }); fs.writeFileSync(path.join(bin, 'claude'), '#!/bin/sh\nexit 1\n', { mode: 0o755 });
process.env.PATH = bin + path.delimiter + process.env.PATH;
try {
  const { etapeTour, creerMemoire } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-collecte-etapes.mjs')).href);
  const faux = path.join(w, 'faux'); fs.mkdirSync(faux, { recursive: true });
  fs.writeFileSync(path.join(faux, 'driver-lock.sh'), `#!/usr/bin/env bash\ncase "$1" in\n status) echo '{"present":true,"scope":"lab","locks":[{"present":true,"owner":"o","step":"s","ws":"w","scope":"phase","phase":"79","age_seconds":1,"ttl":1800,"stale":false,"session_ids":["x1"]}]}' ;;\n *) echo '{}' ;;\nesac\n`, { mode: 0o755 });
  const lab = path.join(w, 'lab'); fs.mkdirSync(lab, { recursive: true }); spawnSync('git', ['init', '-q', lab]);
  const base = { racine: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), scriptsDir: faux, home: path.join(w, 'home'), sansIndex: true };
  const r0 = etapeTour({ ...base, memo: creerMemoire() });
  out.temoin = `verrous=${r0.verrous.etat}/${r0.verrous.liste.length} erreurVerrous=${r0.erreurs.includes('verrous')}`;
  const memo = creerMemoire(); Object.defineProperty(memo, 'sessions', { get: () => ({ has() { throw new Error('essai'); } }), set() {}, configurable: true });
  let r1 = null, levee = null; try { r1 = etapeTour({ ...base, memo }); } catch (e) { levee = String(e && e.message).slice(0, 40); }
  out.hostile = levee ? `leve:${levee}` : `verrous=${r1.verrous.etat}/${r1.verrous.liste.length} erreurVerrous=${r1.erreurs.includes('verrous')} dureeMs=${typeof r1.dureeMs}`;
} catch (e) { out.erreur = String(e && e.stack || e).slice(0, 300); }
console.log(JSON.stringify(out));
JS
cat > "$AUX/c132.mjs" <<'JS'
// c132.mjs <scripts> <travail> : le VRAI fil de cette copie du module, dont etapeTour lève (greffe posée par la suite) : la collecte n'en meurt pas, un tour neuf et neutre porte `tour` dans ses erreurs
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, w] = process.argv, dort = (ms) => new Promise((r) => setTimeout(r, ms));
const { creerCollecte } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-collecte.mjs')).href);
const lab = path.join(w, 'lab'); fs.mkdirSync(lab, { recursive: true });
const c = creerCollecte({ racine: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), scriptsDir: scripts, home: w, log: () => {} }), recus = []; c.surResultat((m) => recus.push(m));
const tenir = setInterval(() => {}, 200); // la boucle reste vivante même si le fil meurt (fil et minuteurs du pilote sont détachés)
c.demander({ tour: true }); const pret = await c.pret(15000); await dort(300); clearInterval(tenir);
const t = recus.find((m) => m.type === 'tour'), e = c.etat(); c.arreter();
console.log(JSON.stringify({ pret, tour: !!t, erreurs: t ? t.erreurs.join('+') : null, equipe: t ? t.equipe.workers.length : null, etat: e.etat, relances: e.relances, vivant: e.vivant, mort: e.derniereMort }));
process.exit(0);
JS
cat > "$AUX/c133.mjs" <<'JS'
// c133.mjs <scripts> <travail> : la signature du lab couvre `.git/config` (adresse distante) et `.git/info/exclude` (exclusions), de l'arbre principal comme du dépôt commun d'un arbre de travail
import fs from 'node:fs'; import path from 'node:path'; import { spawnSync } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , scripts, w] = process.argv, out = {};
try {
  const { signatureDuLab } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-code-cache.mjs')).href), moteur = path.join(scripts, '..', 'skills', 'cockpit-moteur');
  const git = (...a) => spawnSync('git', ['-c', 'user.email=a@b.c', '-c', 'user.name=t', ...a], { encoding: 'utf8' });
  const sig = (lab) => signatureDuLab({ lab, moteur, etatGit: '[]' });
  const lab = path.join(w, 'lab'); fs.mkdirSync(lab, { recursive: true }); git('init', '-q', lab);
  const s0 = sig(lab); out.stable = s0 === sig(lab);
  fs.appendFileSync(path.join(lab, '.git', 'config'), '[remote "origin"]\n\turl = https://exemple.invalid/a.git\n'); const s1 = sig(lab); out.config = s1 !== s0;
  fs.mkdirSync(path.join(lab, '.git', 'info'), { recursive: true }); fs.appendFileSync(path.join(lab, '.git', 'info', 'exclude'), 'secret.txt\n'); const s2 = sig(lab); out.exclude = s2 !== s1;
  out.stable2 = s2 === sig(lab);
  const hote = path.join(w, 'hote'); fs.mkdirSync(hote); git('init', '-q', hote); git('-C', hote, 'commit', '--allow-empty', '-q', '-m', 'x');
  const wt = path.join(w, 'arbre'); git('-C', hote, 'worktree', 'add', '-q', '-b', 'wt', wt);
  const t0 = sig(wt); fs.appendFileSync(path.join(hote, '.git', 'config'), '[remote "origin"]\n\turl = https://exemple.invalid/b.git\n'); const t1 = sig(wt);
  fs.appendFileSync(path.join(hote, '.git', 'info', 'exclude'), 'autre.txt\n'); const t2 = sig(wt);
  out.arbre = `${t1 !== t0} ${t2 !== t1}`;
} catch (e) { out.erreur = String(e && e.stack || e).slice(0, 300); }
console.log(JSON.stringify(out));
JS
cat > "$AUX/c134.mjs" <<'JS'
// c134.mjs <scripts> <travail> : ecrireSignature confine AVANT de créer quoi que ce soit, et ne suit aucun lien pour son temporaire
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, w] = process.argv, out = {};
try {
  const { ecrireSignature, lireSignature } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-code-cache.mjs')).href);
  const mk = (n) => { const d = path.join(w, n); fs.mkdirSync(d, { recursive: true }); return d; };
  // témoin : écriture ordinaire, 0600, aucun temporaire laissé
  const lab = mk('lab'), sortie = path.join(lab, '.vibeflow', 'cockpit'); fs.mkdirSync(sortie, { recursive: true });
  ecrireSignature(lab, sortie, 'abc');
  const f = path.join(sortie, '.cache', 'scan-signature.json');
  out.temoin = `${lireSignature(sortie)} ${(fs.statSync(f).mode & 0o777).toString(8)} restes=${fs.readdirSync(path.join(sortie, '.cache')).filter((x) => x.endsWith('.tmp')).length}`;
  // la sortie est un lien vers un dossier hors du lab : aucun dossier `.cache` n'y est créé
  const lab2 = mk('lab2'), dehors = mk('dehors2'); fs.mkdirSync(path.join(lab2, '.vibeflow')); fs.symlinkSync(dehors, path.join(lab2, '.vibeflow', 'cockpit'));
  ecrireSignature(lab2, path.join(lab2, '.vibeflow', 'cockpit'), 'abc'); out.lien = `dehors=${fs.readdirSync(dehors).length}`;
  // le temporaire attendu est un lien vers un fichier hors du lab : le fichier visé n'est jamais écrit
  const lab3 = mk('lab3'), dehors3 = mk('dehors3'), sortie3 = path.join(lab3, '.vibeflow', 'cockpit'); fs.mkdirSync(path.join(sortie3, '.cache'), { recursive: true });
  const victime = path.join(dehors3, 'victime.txt'); fs.writeFileSync(victime, 'intact');
  fs.symlinkSync(victime, path.join(sortie3, '.cache', `scan-signature.json.${process.pid}.tmp`));
  ecrireSignature(lab3, sortie3, 'abc'); out.tmp = fs.readFileSync(victime, 'utf8');
} catch (e) { out.erreur = String(e && e.stack || e).slice(0, 300); }
console.log(JSON.stringify(out));
JS
c13run() { local n="$1" scripts="$2"; rm -rf "$WORK/c13/$n"; mkdir -p "$WORK/c13/$n"; node "$AUX/$n.mjs" "$scripts" "$WORK/c13/$n" 2> "$WORK/c13/$n.err" | tail -1 > "$WORK/c13/$n.json"; }
# greffe d'essai : etapeTour lève dès son entrée (sur la copie, jamais sur le module livré) ; sert au témoin C13.2 et à son mutant
GREFFE_DE='sansIndex = false }) {'; GREFFE_VERS="sansIndex = false }) { throw new Error('essai');"
c13run c131 "$SCRIPTS"
assert_eq "C13.1a — témoin : une mémoire ordinaire, un verrou tenu : projection lue, aucune erreur de verrous" "$(jq_ "$WORK/c13/c131.json" 'j.erreur||j.temoin')" "verrous=lue/1 erreurVerrous=false"
assert_eq "C13.1b — la projection des verrous lève : etapeTour ne lève pas, la projection vaut erreur (liste vide), « verrous » est dans les erreurs du tour" "$(jq_ "$WORK/c13/c131.json" 'j.erreur||j.hostile')" "verrous=erreur/0 erreurVerrous=true dureeMs=number"
if mutant M-GREFFE-TOUR vf-cockpit-collecte-etapes.mjs etape-tour "$GREFFE_DE" "$GREFFE_VERS"; then
  c13run c132 "$MUT_SCRIPTS"
  assert_eq "C13.2 — le fil dont etapeTour lève ne meurt pas : un tour neuf (équipe vide, erreurs « tour ») est posté, la collecte est partielle, aucune relance, le fil vit" "$(jq_ "$WORK/c13/c132.json" 'j.erreur||[j.pret,j.tour,j.erreurs,j.equipe,j.etat,j.relances,j.vivant,j.mort===null].join(" ")')" "true true tour 0 partielle 0 true true"
else assert_eq "C13.2 — construction de la greffe" "échec" "ok"; fi
c13run c133 "$SCRIPTS"
assert_eq "C13.3a — la signature est stable, puis change quand .git/config change (adresse distante) puis quand .git/info/exclude change, et reste stable ensuite" "$(jq_ "$WORK/c13/c133.json" 'j.erreur||[j.stable,j.config,j.exclude,j.stable2].join(" ")')" "true true true true"
assert_eq "C13.3b — même chose pour un arbre de travail : la config et les exclusions du dépôt commun changent sa signature" "$(jq_ "$WORK/c13/c133.json" 'j.erreur||j.arbre')" "true true"
c13run c134 "$SCRIPTS"
assert_eq "C13.4a — témoin : l'écriture ordinaire se relit, en 0600, sans temporaire laissé" "$(jq_ "$WORK/c13/c134.json" 'j.erreur||j.temoin')" "abc 600 restes=0"
assert_eq "C13.4b — la sortie est un lien vers un dossier hors du lab : rien n'est créé dehors (le confinement précède le mkdir)" "$(jq_ "$WORK/c13/c134.json" 'j.erreur||j.lien')" "dehors=0"
assert_eq "C13.4c — le temporaire attendu est un lien vers un fichier hors du lab : le fichier visé reste intact" "$(jq_ "$WORK/c13/c134.json" 'j.erreur||j.tmp')" "intact"
# mutants
if MUT_NOLOAD=1 mutant M-FIL-TOUR vf-cockpit-collecte-fil.mjs fil-tour ' catch {' ' catch (e) { throw e; } if (false) {'; then
  node "$AUX/muter.mjs" "$MUT_SCRIPTS/vf-cockpit-collecte-etapes.mjs" etape-tour "$GREFFE_DE" "$GREFFE_VERS" && c13run c132 "$MUT_SCRIPTS"
  assert_eq "M-FIL-TOUR — sans le try du fil, un tour qui lève tue le fil : aucun tour posté, mort comptée, C13.2 rougit" "$(jq_ "$WORK/c13/c132.json" 'j.erreur||[j.tour,(j.relances>0||j.mort!==null)].join(" ")')" "false true"
else assert_eq "M-FIL-TOUR — construction du mutant" "échec" "ok"; fi
if mutant M-PROJETER vf-cockpit-collecte-etapes.mjs etape-projeter "catch { erreurs.push('verrous'); }" "catch (e) { throw e; }"; then
  c13run c131 "$MUT_SCRIPTS"
  assert_eq "M-PROJETER — sans le try autour de la projection, le tour lève : C13.1b rougit (le témoin C13.1a reste vert)" "$(jq_ "$WORK/c13/c131.json" 'j.erreur||j.temoin+" | "+j.hostile')" "verrous=lue/1 erreurVerrous=false | leve:essai"
else assert_eq "M-PROJETER — construction du mutant" "échec" "ok"; fi
if mutant M-CACHE-CONFIG vf-cockpit-code-cache.mjs scan-cache-config "stat(path.join(base, 'config'))" "''"; then
  c13run c133 "$MUT_SCRIPTS"
  assert_eq "M-CACHE-CONFIG — la signature ignore .git/config : C13.3a rougit sur config (les exclusions restent vues)" "$(jq_ "$WORK/c13/c133.json" 'j.erreur||[j.config,j.exclude].join(" ")')" "false true"
else assert_eq "M-CACHE-CONFIG — construction du mutant" "échec" "ok"; fi
if mutant M-CACHE-EXCLUDE vf-cockpit-code-cache.mjs scan-cache-config "stat(path.join(base, 'info', 'exclude'))" "''"; then
  c13run c133 "$MUT_SCRIPTS"
  assert_eq "M-CACHE-EXCLUDE — la signature ignore .git/info/exclude : C13.3a rougit sur exclude (la config reste vue)" "$(jq_ "$WORK/c13/c133.json" 'j.erreur||[j.config,j.exclude].join(" ")')" "true false"
else assert_eq "M-CACHE-EXCLUDE — construction du mutant" "échec" "ok"; fi
if mutant M-CACHE-ORDRE vf-cockpit-code-cache.mjs code-cache-confiner 'try { confiner(lab, f); confiner(lab, tmp); } catch { return; }' "fs.mkdirSync(dir, { recursive: true }); try { confiner(lab, f); } catch { return; }"; then
  c13run c134 "$MUT_SCRIPTS"
  assert_eq "M-CACHE-ORDRE — le dossier est créé avant le confinement (ordre d'avant) : C13.4b rougit (un dossier .cache naît hors du lab)" "$(jq_ "$WORK/c13/c134.json" 'j.erreur||j.lien')" "dehors=1"
else assert_eq "M-CACHE-ORDRE — construction du mutant" "échec" "ok"; fi
if mutant M-CACHE-TMP vf-cockpit-code-cache.mjs code-cache-confiner 'confiner(lab, f); confiner(lab, tmp);' 'confiner(lab, f);' \
   && node "$AUX/muter.mjs" "$MUT_SCRIPTS/vf-cockpit-code-cache.mjs" code-cache-ecriture 'fs.openSync(tmp, drapeaux, 0o600)' "fs.openSync(tmp, 'w', 0o600)"; then
  c13run c134 "$MUT_SCRIPTS"
  assert_eq "M-CACHE-TMP — temporaire ni confiné ni créé en exclusif sans suivre les liens (écriture d'avant) : C13.4c rougit (le fichier visé par le lien est écrasé)" "$(jq_ "$WORK/c13/c134.json" 'j.erreur||j.tmp')" "{\"signature\":\"abc\"}"
else assert_eq "M-CACHE-TMP — construction du mutant" "échec" "ok"; fi
if mutant M-CONFIRM vf-cockpit-collecte.mjs collecte-motifs 'reserve(t)' 't.slice(0, MAX_MOTIFS)'; then
  c12run c124 "$MUT_SCRIPTS"
  assert_eq "M-CONFIRM — sans la réserve, le plafond évince « confirm » derrière une rafale de 70 motifs : C13.5 rougit (confirm=false), le cas seul reste vrai" "$(jq_ "$WORK/c12/c124.json" 'j.erreur||j.confirm')" "n=64 confirm=false | n=64 confirm=true | n=1 confirm=true"
else assert_eq "M-CONFIRM — construction du mutant" "échec" "ok"; fi
# preuves de coalescence (C2.1), d'arrêt (C2.7) et de garde (C2.6a, C2.8) : chacune rougit sur son mutant
if mutant M-COALESCENCE vf-cockpit-collecte.mjs collecte-demander 'if (enVol || !fil)' 'if (!fil)'; then
  pilote "$MUT_SCRIPTS" c21 > "$WORK/c21-m.json"
  assert_eq "M-COALESCENCE — sans file d'attente, les cinq demandes partent aussitôt : C2.1 rougit (cinq exécutions au lieu de deux)" "$(jq_ "$WORK/c21-m.json" 'j.erreur||j.execs')" "5"
else assert_eq "M-COALESCENCE — construction du mutant" "échec" "ok"; fi
if mutant M-UNION vf-cockpit-collecte.mjs collecte-fusion 'unir(a.motifs, b.motifs)' 'b.motifs'; then
  pilote "$MUT_SCRIPTS" c21 > "$WORK/c21-m2.json"
  assert_eq "M-UNION — la fusion de l'attente perd les motifs déjà en attente : C2.1 rougit (la dernière exécution ne porte plus a,b,c)" "$(jq_ "$WORK/c21-m2.json" 'j.erreur||(j.motifs===null?"aucun":j.motifs)')" ""
else assert_eq "M-UNION — construction du mutant" "échec" "ok"; fi
if mutant M-ARRET-FERME vf-cockpit-collecte.mjs collecte-ferme 'ferme = true;' ''; then
  pilote "$MUT_SCRIPTS" c27 > "$WORK/c27-m.json"
  assert_eq "M-ARRET-FERME — arreter() ne ferme plus le pilote : une demande ultérieure est acceptée, C2.7 rougit" "$(jq_ "$WORK/c27-m.json" 'j.erreur||j.apres')" "true"
else assert_eq "M-ARRET-FERME — construction du mutant" "échec" "ok"; fi
if mutant M-ARRET-FIL vf-cockpit-collecte.mjs collecte-terminer 'f.w.terminate().catch(() => {});' ';'; then
  c12run c123 "$MUT_SCRIPTS"
  assert_eq "M-ARRET-FIL — arreter() ne termine pas le fil : il bat encore après l'arrêt (C12.3 rougit sur batApresArret)" "$(jq_ "$WORK/c12/c123.json" 'j.erreur||j.batApresArret>0')" "true"
else assert_eq "M-ARRET-FIL — construction du mutant" "échec" "ok"; fi
if mutant M-GARDE-TOUR vf-cockpit-live.mjs live-garde-tour 'if (!garde({ verrous: n, equipe: nw, signal: sg }))' 'if (false)'; then
  pilote "$MUT_SCRIPTS" c26 "$WORK/lab26" > "$WORK/c26-m.json"
  assert_eq "M-GARDE-TOUR — la garde ne refuse plus le tour : le tour interdit est posé, l'instantané du tour accepté n'est pas conservé, C2.6a rougit" "$(jq_ "$WORK/c26-m.json" 'j.erreur||j.refus.conserve')" "false"
else assert_eq "M-GARDE-TOUR — construction du mutant" "échec" "ok"; fi
if mutant M-GARDE-DEFAUT vf-cockpit-live.mjs live-garde-defaut 'garde = () => false' 'garde = () => true'; then
  pilote "$MUT_SCRIPTS" c28 "$WORK/lab26" > "$WORK/c28-m.json"
  assert_eq "M-GARDE-DEFAUT — la garde par défaut redevient ouverte : l'instantané est posé et « qui » rempli sans garde fournie, C2.8 rougit" "$(jq_ "$WORK/c28-m.json" 'j.erreur||j.instantane+" "+j.qui')" "false 1"
else assert_eq "M-GARDE-DEFAUT — construction du mutant" "échec" "ok"; fi

vf_hyg_assert
echo "== Résultats : $PASS PASS / $FAIL FAIL =="
[ "$PASS" -gt 0 ] || { echo "garde anti-vert-à-vide : aucune assertion jouée"; exit 1; }
[ "$FAIL" -eq 0 ]
