#!/usr/bin/env bash
# test-vf-cockpit.sh — Tests du serveur cockpit (vf-cockpit-serve.mjs + parsers + sécurité).
# Couvre : lab complet (snapshot correct), lab nu (états vides propres, jamais d'exception),
# lab absent (message clair, sortie propre), "### Phase N:" en double (dernière occurrence
# gagne), garde anti-traversée sur ?num=, résolution des assets dans les deux dispositions
# (dépôt / installée), parsing tolérant au CRLF, et bind strict sur 127.0.0.1.
# Aucun accès réseau externe — tout tourne en local sur un port libre.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$HERE/.." && pwd)"
SERVER="$SCRIPTS_DIR/vf-cockpit-serve.mjs"
PASS=0 FAIL=0
ok()  { echo "  ✓ $1"; PASS=$((PASS+1)); }
nok() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
SERVER_PID=""
cleanup() {
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

# ---------- fixtures ----------
FULL="$TMP/full-lab"
mkdir -p "$FULL/.planning/phases/VFDO-30-portabilite"
cat > "$FULL/.planning/ROADMAP.md" <<'MD'
- [x] Phase 29: ancienne étape (completed 2026-08-01)
- [ ] Phase 30: portabilité Windows

### Phase 30: portabilité Windows (version héritée, à ignorer)
**Goal**: ancienne section, ne doit PAS gagner.

### Phase 30: portabilité Windows
**Goal**: section courante, doit gagner (dernière occurrence).
Corps détaillé de la phase courante.
MD
cat > "$FULL/.planning/STATE.md" <<'MD'
---
milestone: "fiabilite-v1.0"
phase: "30"
progress:
  done: 5
  total: 8
---
MD
cat > "$FULL/.planning/MILESTONES.md" <<'MD'
## ✅ agentique-v1.0 (clos 2026-08-15)
## 🚧 fiabilite-v1.0 (démarré 2026-08-15)
MD
mkdir -p "$FULL/.planning/DRIVER.lock"
cat > "$FULL/.planning/DRIVER.lock/meta" <<META
owner=vf-coder
step=exec-core
heartbeat_epoch=$(date +%s)
META
cat > "$FULL/.planning/MISSION-30.dag.json" <<'JSON'
{"nodes": [{"id": "exec-core", "status": "running"}]}
JSON
touch "$FULL/.planning/phases/VFDO-30-portabilite/30-01-PLAN.md"
touch "$FULL/.planning/phases/VFDO-30-portabilite/30-01-SUMMARY.md"
touch "$FULL/.planning/phases/VFDO-30-portabilite/30-02-PLAN.md"

BARE="$TMP/bare-lab"
mkdir -p "$BARE/.planning"
cat > "$BARE/.planning/ROADMAP.md" <<'MD'
- [ ] Phase 1: seule étape
MD

NOLAB="$TMP/no-lab/deep/nested/dir"
mkdir -p "$NOLAB"

CRLF="$TMP/crlf-lab"
mkdir -p "$CRLF/.planning"
printf -- '---\r\nmilestone: "crlf-test"\r\nphase: "1"\r\n---\r\n' > "$CRLF/.planning/STATE.md"

# ---------- tests unitaires (parsers + sécurité), sans réseau ----------
UNIT_OUT="$(node --input-type=module -e "
import { parseState, parseRoadmapSections, phaseDetail, parseRoadmapChecklist } from '$SCRIPTS_DIR/vf-cockpit-parsers.mjs';
import { resolveReferencesDir, safeJoin } from '$SCRIPTS_DIR/vf-cockpit-security.mjs';
import path from 'node:path';
import fs from 'node:fs';

const results = [];
function assertEq(name, got, want) { results.push([name, JSON.stringify(got) === JSON.stringify(want), got, want]); }
function assertTrue(name, cond) { results.push([name, !!cond, cond, true]); }

// CRLF tolérant
const st = parseState('$CRLF/.planning');
assertEq('crlf: milestone parsé', st && st.milestone, 'crlf-test');

// dernière occurrence de ### Phase N: gagne
const sections = parseRoadmapSections('$FULL/.planning');
assertTrue('doublon phase: dernière occurrence gagne', sections[30] && /section courante/.test(sections[30].body));
assertTrue('doublon phase: ancienne absente du body retenu', sections[30] && !/à ignorer/.test(sections[30].goal || ''));

// phaseDetail sur numéro inexistant : pas d'exception, structure vide propre
const missing = phaseDetail('$BARE/.planning', 999, () => {});
assertEq('phaseDetail inexistant: name null', missing.name, null);
assertEq('phaseDetail inexistant: plans vide', missing.plans, []);

// phaseDetail avec num invalide (NaN) : pas d'exception
const invalid = phaseDetail('$FULL/.planning', NaN, () => {});
assertTrue('phaseDetail NaN: erreur explicite sans exception', !!invalid.error);

// checklist vide sur lab sans ROADMAP.md
const noRoadmap = parseRoadmapChecklist('$TMP/no-lab');
assertEq('checklist sans ROADMAP.md: tableau vide', noRoadmap, []);

// résolution des assets — disposition dépôt : scripts/ -> ../references/
const repoRefs = '$TMP/repo-disposition/plugin/vf-cockpit/references';
fs.mkdirSync(repoRefs, { recursive: true });
const repoScripts = path.join('$TMP', 'repo-disposition', 'plugin', 'vf-cockpit', 'scripts');
fs.mkdirSync(repoScripts, { recursive: true });
assertEq('assets: disposition dépôt résolue', resolveReferencesDir(repoScripts), repoRefs);

// résolution des assets — disposition installée : .claude/scripts/ -> ../skills/vf-cockpit/references/
const installedRefs = '$TMP/installed-disposition/.claude/skills/vf-cockpit/references';
fs.mkdirSync(installedRefs, { recursive: true });
const installedScripts = path.join('$TMP', 'installed-disposition', '.claude', 'scripts');
fs.mkdirSync(installedScripts, { recursive: true });
assertEq('assets: disposition installée résolue', resolveReferencesDir(installedScripts), installedRefs);

// aucune disposition : résolution null, pas d'exception
const emptyScripts = path.join('$TMP', 'nothing-here');
fs.mkdirSync(emptyScripts, { recursive: true });
assertEq('assets: aucune disposition -> null', resolveReferencesDir(emptyScripts), null);

// garde anti-traversée
const root = '$FULL/.planning';
assertEq('safeJoin: traversée bloquée', safeJoin(root, '../../etc/passwd'), null);
assertTrue('safeJoin: chemin légitime accepté', safeJoin(root, 'ROADMAP.md') === path.join(root, 'ROADMAP.md'));

console.log(JSON.stringify(results));
")"
echo "$UNIT_OUT" | node -e "
const results = JSON.parse(require('fs').readFileSync(0, 'utf8'));
for (const [name, passed] of results) {
  console.log((passed ? 'OK ' : 'KO ') + name);
}
" > "$TMP/unit-results.txt"

while IFS= read -r line; do
  case "$line" in
    OK\ *) ok "${line#OK }" ;;
    KO\ *) nok "${line#KO }" ;;
  esac
done < "$TMP/unit-results.txt"

# ---------- invariant "lecture seule" : garde statique anti-écriture disque ----------
# Propriété centrale du produit (Iron Law du SKILL.md) — aujourd'hui protégée par la seule
# discipline de revue, pas d'outillage. On ignore les lignes de commentaire (`//`) pour ne
# pas faire échouer le test sur de la PROSE qui mentionne ces mots (ex: le commentaire d'en-
# tête de vf-cockpit-serve.mjs cite "fs.write*/mkdir/rm/appendFile" en toutes lettres) — seul
# du CODE réel doit compter. `res.write` (réponse HTTP, légitime) ne matche aucun motif
# ci-dessous par construction (nom d'API, pas le mot nu "write"), donc n'a besoin d'aucune
# exclusion dédiée.
WRITE_PATTERN='writeFile|mkdirSync|appendFile|unlink|rmSync|createWriteStream|truncate|renameSync|copyFileSync'
WRITE_HITS=0
for f in "$SCRIPTS_DIR"/*.mjs; do
  CODE_ONLY="$(sed -E 's#^[[:space:]]*//.*$##' "$f")"
  if echo "$CODE_ONLY" | grep -qE "$WRITE_PATTERN"; then
    WRITE_HITS=$((WRITE_HITS+1))
    echo "    (motif d'écriture disque trouvé dans $(basename "$f"))"
  fi
done
[ "$WRITE_HITS" -eq 0 ] \
  && ok "invariant lecture seule: aucun motif d'écriture disque dans scripts/*.mjs" \
  || nok "invariant lecture seule: motif d'écriture disque détecté (voir ci-dessus)"

# ---------- tests serveur en direct (fetch node, jamais curl — cf CONVENTIONS.md) ----------
PORT=$((20000 + RANDOM % 10000))
VF_COCKPIT_PLANNING_ROOT="$FULL/.planning" VF_COCKPIT_PORT="$PORT" node "$SERVER" >"$TMP/server.log" 2>&1 &
SERVER_PID=$!

READY=0
for _ in $(seq 1 50); do
  if node -e "fetch('http://127.0.0.1:$PORT/api/state').then(()=>process.exit(0)).catch(()=>process.exit(1))" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 0.1
done
[ "$READY" = "1" ] && ok "serveur démarré et répond" || nok "serveur démarré et répond"

LIVE_OUT="$(node --input-type=module -e "
const base = 'http://127.0.0.1:$PORT';
const results = [];
function assertEq(name, got, want) { results.push([name, JSON.stringify(got) === JSON.stringify(want), got, want]); }
function assertTrue(name, cond) { results.push([name, !!cond]); }

const state = await (await fetch(base + '/api/state')).json();
assertEq('lab complet: 2 phases dans la checklist', state.phases.length, 2);
assertTrue('lab complet: lock présent', state.lock.present === true);
assertTrue('lab complet: dag présent', Array.isArray(state.dags) && state.dags.length === 1);
assertTrue('lab complet: watch mode exposé', state.watch && ['watch','poll'].includes(state.watch.mode));

const phase = await (await fetch(base + '/api/phase?num=30')).json();
assertTrue('phase 30: 2 plans détectés', Array.isArray(phase.plans) && phase.plans.length === 2);
assertTrue('phase 30: dernière section gagne (goal)', (phase.goal || '').includes('courante'));

// garde anti-traversée sur /api/phase?num=
const traversalRes = await fetch(base + '/api/phase?num=../../../etc/passwd');
const traversalBody = await traversalRes.text();
assertEq('traversée num=: statut 400', traversalRes.status, 400);
assertTrue('traversée num=: pas de contenu sensible', !traversalBody.includes('root:'));

const traversal2 = await fetch(base + '/api/phase?num=' + encodeURIComponent('..%2f..%2fetc%2fpasswd'));
assertEq('traversée num= encodée: statut 400', traversal2.status, 400);

const notFound = await fetch(base + '/nope');
assertEq('404 propre sur route inconnue', notFound.status, 404);

console.log(JSON.stringify(results));
")"
echo "$LIVE_OUT" | node -e "
const results = JSON.parse(require('fs').readFileSync(0, 'utf8'));
for (const [name, passed] of results) {
  console.log((passed ? 'OK ' : 'KO ') + name);
}
" > "$TMP/live-results.txt"

while IFS= read -r line; do
  case "$line" in
    OK\ *) ok "${line#OK }" ;;
    KO\ *) nok "${line#KO }" ;;
  esac
done < "$TMP/live-results.txt"

# garde anti-traversée sur /assets/ — symétrique au test /api/phase ci-dessus, mais via
# socket TCP brute : `fetch` normalise les dot-segments côté client avant même d'émettre
# la requête, donc un test fetch() ne prouverait rien sur la garde serveur. On envoie la
# ligne de requête HTTP à la main pour que le serveur reçoive le chemin NON normalisé.
ASSET_TRAVERSAL_OUT="$(node -e "
const net = require('net');
function rawGet(reqPath) {
  return new Promise((resolve) => {
    const s = net.connect({ host: '127.0.0.1', port: $PORT }, () => {
      s.write('GET ' + reqPath + ' HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n');
    });
    let data = '';
    s.setTimeout(2000, () => { s.destroy(); resolve(data); });
    s.on('data', (d) => { data += d; });
    s.on('end', () => resolve(data));
    s.on('error', () => resolve(data));
  });
}
(async () => {
  const results = [];

  const raw1 = await rawGet('/assets/../../../../../../etc/passwd');
  const status1 = (raw1.match(/^HTTP\/1\.1 (\d+)/) || [])[1];
  results.push(['assets: traversée non-normalisée -> 404', status1 === '404']);
  results.push(['assets: traversée non-normalisée -> pas de contenu sensible', !raw1.includes('root:')]);

  const raw2 = await rawGet('/assets/..%2f..%2f..%2f..%2f..%2f..%2fetc%2fpasswd.css');
  const status2 = (raw2.match(/^HTTP\/1\.1 (\d+)/) || [])[1];
  results.push(['assets: traversée encodée (%2f) -> 404', status2 === '404']);
  results.push(['assets: traversée encodée -> pas de contenu sensible', !raw2.includes('root:')]);

  const raw3 = await rawGet('/assets/....//....//....//etc/passwd');
  const status3 = (raw3.match(/^HTTP\/1\.1 (\d+)/) || [])[1];
  results.push(['assets: traversée ....// -> 404', status3 === '404']);

  console.log(JSON.stringify(results));
})();
")"
echo "$ASSET_TRAVERSAL_OUT" | node -e "
const results = JSON.parse(require('fs').readFileSync(0, 'utf8'));
for (const [name, passed] of results) console.log((passed ? 'OK ' : 'KO ') + name);
" > "$TMP/asset-traversal-results.txt"
while IFS= read -r line; do
  case "$line" in
    OK\ *) ok "${line#OK }" ;;
    KO\ *) nok "${line#KO }" ;;
  esac
done < "$TMP/asset-traversal-results.txt"

kill "$SERVER_PID" >/dev/null 2>&1 || true
wait "$SERVER_PID" 2>/dev/null || true
SERVER_PID=""

# ---------- lab NU : pas d'exception, états vides explicites ----------
PORT2=$((30000 + RANDOM % 10000))
VF_COCKPIT_PLANNING_ROOT="$BARE/.planning" VF_COCKPIT_PORT="$PORT2" node "$SERVER" >"$TMP/server-bare.log" 2>&1 &
SERVER_PID=$!
READY2=0
for _ in $(seq 1 50); do
  if node -e "fetch('http://127.0.0.1:$PORT2/api/state').then(()=>process.exit(0)).catch(()=>process.exit(1))" >/dev/null 2>&1; then
    READY2=1
    break
  fi
  sleep 0.1
done
[ "$READY2" = "1" ] && ok "lab nu: serveur répond sans exception" || nok "lab nu: serveur répond sans exception"

BARE_OUT="$(node --input-type=module -e "
const base = 'http://127.0.0.1:$PORT2';
const results = [];
function assertEq(name, got, want) { results.push([name, JSON.stringify(got) === JSON.stringify(want), got, want]); }
function assertTrue(name, cond) { results.push([name, !!cond]); }
const state = await (await fetch(base + '/api/state')).json();
assertEq('lab nu: state STATE.md = null', state.state, null);
assertEq('lab nu: milestones vide', state.milestones, []);
assertEq('lab nu: lock absent', state.lock.present, false);
assertTrue('lab nu: disponibilité roadmap=true, state=false', state.availability.roadmap === true && state.availability.state === false);
console.log(JSON.stringify(results));
")"
echo "$BARE_OUT" | node -e "
const results = JSON.parse(require('fs').readFileSync(0, 'utf8'));
for (const [name, passed] of results) console.log((passed ? 'OK ' : 'KO ') + name);
" > "$TMP/bare-results.txt"
while IFS= read -r line; do
  case "$line" in
    OK\ *) ok "${line#OK }" ;;
    KO\ *) nok "${line#KO }" ;;
  esac
done < "$TMP/bare-results.txt"

# bind strict sur 127.0.0.1, jamais une interface publique
if node -e "
const net = require('net');
const s = net.connect({ host: '127.0.0.1', port: $PORT2 }, () => { s.end(); process.exit(0); });
s.on('error', () => process.exit(1));
" >/dev/null 2>&1; then
  ok "serveur écoute sur 127.0.0.1"
else
  nok "serveur écoute sur 127.0.0.1"
fi
# Le grep sur le littéral "0.0.0.0" est tautologique : le code n'émet jamais ce mot (le log
# affiche `HOST`), donc il reste vert même si une régression faisait écouter le serveur sur
# toutes les interfaces. Assertion qui peut réellement échouer : tenter une connexion sur
# l'IP réseau non-loopback réelle de la machine et exiger un échec (ECONNREFUSED/timeout).
# Se dégrade proprement (ok, pas nok) si la machine n'a aucune interface non-loopback — cas
# CI fréquent — plutôt que d'échouer à tort sur une absence de réseau.
BIND_CHECK="$(node -e "
const net = require('net');
const os = require('os');
const ifaces = Object.values(os.networkInterfaces()).flat();
const iface = (ifaces || []).find((i) => i && i.family === 'IPv4' && !i.internal);
if (!iface) { console.log('SKIP'); process.exit(0); }
const s = net.connect({ host: iface.address, port: $PORT2, timeout: 800 });
s.on('connect', () => { s.destroy(); console.log('LISTENING'); });
s.on('timeout', () => { s.destroy(); console.log('UNREACHABLE'); });
s.on('error', () => { console.log('UNREACHABLE'); });
" 2>/dev/null)"
case "$BIND_CHECK" in
  SKIP) ok "bind non-public: aucune interface non-loopback disponible (dégradé proprement)" ;;
  UNREACHABLE) ok "bind non-public: injoignable via l'IP réseau réelle" ;;
  *) nok "bind non-public: injoignable via l'IP réseau réelle (reçu: ${BIND_CHECK:-vide})" ;;
esac

kill "$SERVER_PID" >/dev/null 2>&1 || true
wait "$SERVER_PID" 2>/dev/null || true
SERVER_PID=""

# ---------- SANS .planning/ du tout : message clair, sortie propre ----------
# Pas de dépendance à `timeout` (absent par défaut sur macOS) : on lance en fond et on tue.
# Lancer node SANS sous-shell englobant : `cd ... && node ...` dans un `( ... ) &` fait de
# `$!` le PID du sous-shell, pas de node — kill n'atteint alors jamais node, qui survit en
# orphelin (prouvé empiriquement : 2 runs → 2 process résiduels). On pousse cd/env dans le
# process node lui-même via VF_COCKPIT_CWD, en calquant sur le lancement direct l.153.
VF_COCKPIT_CWD="$NOLAB" VF_COCKPIT_PORT=0 node "$SCRIPTS_DIR/vf-cockpit-serve.mjs" >"$TMP/nolab.log" 2>&1 &
NOLAB_PID=$!
sleep 1
kill "$NOLAB_PID" >/dev/null 2>&1 || true
wait "$NOLAB_PID" 2>/dev/null || true
grep -q "aucun dossier .planning" "$TMP/nolab.log" && ok "lab absent: message clair émis" || nok "lab absent: message clair émis"
grep -qi "TypeError\|ReferenceError\|at file://" "$TMP/nolab.log" && nok "lab absent: pas de stack trace" || ok "lab absent: pas de stack trace"

echo
echo "RÉSULTAT: $PASS ok / $FAIL ko"
[ "$FAIL" -eq 0 ]
