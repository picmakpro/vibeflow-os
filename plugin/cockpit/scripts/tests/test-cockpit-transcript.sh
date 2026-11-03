#!/usr/bin/env bash
# test-cockpit-transcript.sh — transcript d'un agent lu à la demande : réduction à liste blanche, requête authentifiée, jamais dans le flux,
# les fichiers générés, le journal ni l'export ; rendu en texte et CSP inchangée (CKPT-24 à CKPT-26 ; P69-D-19, P69-D-23).
# Fixtures reconstruites dans mktemp, SYNTHÉTIQUES (aucun transcript réel de ~/.claude/projects n'est lu ni copié). Le code testé est chargé depuis
# l'emplacement de la suite (module, serveur assemblé, couche d'affichage) : jamais depuis l'installation du poste.
#   T0  contrôles positifs : chaque marqueur négatif est présent dans la fixture, à son emplacement de sortie d'outil
#   T24 reduireTranscript : mandat, messages et outils visibles ; aucune sortie d'outil ; borne, masque, durée
#   T25 GET /api/vf/transcript : jeton, identifiants, fenêtre de 24 h, aucun marqueur dans le flux, les fichiers, le journal ni l'export ;
#       mutants M-JETON (contrôle du jeton neutralisé) et M-PORTE (garde d'émission neutralisée) : les négatifs savent rougir
#   T26 rendu en texte (vm, puis Chrome s'il est présent) et CSP de /equipe.html égale à celle de v2.75.0
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
HERE_T="$(cd "$(dirname "$0")" && pwd)"
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"

WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX"
PIDS=()

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite (jamais de long node -e) ---
cat > "$AUX/mk-transcript.mjs" <<'JS'
// mk-transcript.mjs <fichier> <racineLab> [--id=ag1] [--gros] [--payload] [--age=<s>] : transcript d'un sous-agent à la forme réelle mesurée (R5.1), valeurs SYNTHÉTIQUES.
// Un marqueur dans chaque emplacement de sortie d'outil : tool_result, toolUseResult, ligne api-request-blob, ligne attachment, bloc thinking,
// contenu d'un fichier lu, commande Bash. --gros : remplissage au-delà de 9 Mio ; --payload : le mandat et le message sont un élément img piégé.
import fs from 'node:fs';
const [, , out, lab, ...opts] = process.argv;
const opt = (k) => (opts.find((o) => o.startsWith(`--${k}=`)) || '').slice(k.length + 3);
const ID = opt('id') || 'ag1', gros = opts.includes('--gros'), payload = opts.includes('--payload'), age = opt('age');
const PIEGE = '<img src=x onerror=alert(1)>';
const t0 = Date.now() - 600000; const iso = (k) => new Date(t0 + k * 1000).toISOString();
const base = (o) => ({ cwd: lab, sessionId: 'sess-synthetique', gitBranch: 'main', version: '2.1.317', ...o });
const side = (k, o) => base({ isSidechain: true, agentId: ID, timestamp: iso(k), ...o });
const lignes = [
  side(0, { type: 'user', parentUuid: null, message: { role: 'user', content: payload ? PIEGE : 'MANDAT-VISIBLE-69 Nœud `revue-p3` GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwx' } }),
  side(1, { type: 'assistant', message: { role: 'assistant', content: [
    { type: 'thinking', thinking: 'PENSEE-69' },
    { type: 'text', text: payload ? PIEGE : 'MESSAGE-VISIBLE-69' },
    { type: 'tool_use', id: 'toolu_r1', name: 'Read', input: { file_path: `${lab}/src/a.js` } }] } }),
  side(2, { type: 'user', message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: 'toolu_r1', content: 'FICHIER-LU-69' }] }, toolUseResult: { type: 'text', file: { filePath: `${lab}/src/a.js`, content: 'TOOLUSERESULT-69' } } }),
  { type: 'api-request-blob', timestamp: iso(3), agentId: ID, blob: { sortie: 'SORTIE-OUTIL-69' } },
  { type: 'attachment', timestamp: iso(4), agentId: ID, attachment: { type: 'hook_additional_context', content: 'ATTACHMENT-69' } },
  side(5, { type: 'assistant', message: { role: 'assistant', content: [{ type: 'tool_use', id: 'toolu_b1', name: 'Bash', input: { command: 'echo COMMANDE-SECRETE-69', description: 'DESCRIPTION-69' } }] } }),
];
if (gros) for (let i = 0, n = 0; n < 9.5 * 1048576; i++) { const l = JSON.stringify(side(6, { type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: `REMPLISSAGE-${i} ` + 'x'.repeat(2500) }] } })); lignes.push(l); n += l.length + 1; }
lignes.push(side(7, { type: 'user', message: { role: 'user', content: 'SUIVI-69' } }));
fs.writeFileSync(out, lignes.map((l) => (typeof l === 'string' ? l : JSON.stringify(l))).join('\n') + '\n');
if (age) { const t = (Date.now() - Number(age) * 1000) / 1000; fs.utimesSync(out, t, t); }
JS
cat > "$AUX/red.mjs" <<'JS'
// red.mjs <scripts> <fichier> <racine> : { absent } si le module ou la fonction n'existe pas, sinon { r: reduireTranscript(fichier, { root }), ms }
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, fichier, root] = process.argv;
let m;
try { m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-transcript.mjs')).href); } catch { console.log(JSON.stringify({ absent: 'module absent' })); process.exit(0); }
if (typeof m.reduireTranscript !== 'function') { console.log(JSON.stringify({ absent: 'reduireTranscript absent' })); process.exit(0); }
const t0 = Date.now();
try { const r = await m.reduireTranscript(fichier, { root }); console.log(JSON.stringify({ r, ms: Date.now() - t0 })); } catch (e) { console.log(JSON.stringify({ absent: 'exception : ' + String(e.message).slice(0, 80) })); }
JS
cat > "$AUX/jget.mjs" <<'JS'
// jget.mjs <fichier.json> <expression sur j> : valeur (chaîne telle quelle, sinon JSON) ; « non-json » si le fichier n'est pas un JSON
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('non-json'); process.exit(0); }
try { const v = new Function('j', 'return (' + process.argv[3] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v)); } catch (e) { console.log('erreur-expression : ' + e.message); }
JS
cat > "$AUX/jq.mjs" <<'JS'
// jq.mjs <expression sur j> : idem jget.mjs, le JSON vient de l'entrée standard
let s = ''; process.stdin.on('data', (c) => (s += c)).on('end', () => {
  let j; try { j = JSON.parse(s); } catch { console.log('non-json'); return; }
  try { const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v)); } catch (e) { console.log('erreur-expression : ' + e.message); }
});
JS
cat > "$AUX/mk-agents.mjs" <<'JS'
// mk-agents.mjs <home> <lab> <idSession> <nowMs> <spec.json> : session Claude Code + sous-agents à la forme réelle mesurée (R5.1), valeurs synthétiques.
// spec = { sessionAgeS, agents: [{ id, spawnDepth, parent, finished, ageS, mandat, role }] }. La date de modification de chaque .jsonl est posée à now - ageS.
import fs from 'node:fs';
import path from 'node:path';
const [, , home, lab, sid, nowMs, specF] = process.argv;
const now = Number(nowMs);
const spec = JSON.parse(fs.readFileSync(specF, 'utf8'));
const dir = path.join(home, '.claude', 'projects', '-lab'); const sub = path.join(dir, sid, 'subagents');
fs.mkdirSync(sub, { recursive: true });
const iso = (ms) => new Date(ms).toISOString();
const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const put = (f, lignes, ageS) => { fs.writeFileSync(f, lignes.map((l) => JSON.stringify(l)).join('\n') + '\n'); const t = (now - ageS * 1000) / 1000; fs.utimesSync(f, t, t); };
const sAge = spec.sessionAgeS ?? 5;
put(path.join(dir, sid + '.jsonl'), [
  base({ type: 'user', timestamp: iso(now - sAge * 1000 - 600000), message: { content: 'salut' } }),
  base({ type: 'assistant', timestamp: iso(now - sAge * 1000), message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo bonjour' } }] } }),
], sAge);
for (const a of spec.agents) {
  const meta = { agentType: a.role || 'vf-coder', isBuiltIn: false, launchedWithDefaults: false, description: `tâche synthétique ${a.id}`, toolUseId: `toolu_${a.id}`, spawnDepth: a.spawnDepth, requestShape: 'background', requestNonInteractive: true };
  if (a.spawnDepth >= 2) meta.parentAgentId = a.parent;
  if (a.finished) meta.finished = true;
  fs.writeFileSync(path.join(sub, `agent-${a.id}.meta.json`), JSON.stringify(meta));
  const debut = now - a.ageS * 1000 - 300 * 1000;
  put(path.join(sub, `agent-${a.id}.jsonl`), [
    base({ type: 'user', isSidechain: true, agentId: a.id, parentUuid: null, timestamp: iso(debut), message: { role: 'user', content: a.mandat ?? `mandat synthétique de ${a.id}` } }),
    base({ type: 'assistant', isSidechain: true, agentId: a.id, timestamp: iso(now - a.ageS * 1000), message: { role: 'assistant', content: [{ type: 'tool_use', id: `toolu_x${a.id}`, name: 'Read', input: { file_path: `${lab}/README.md` } }] } }),
  ], a.ageS);
}
JS
cat > "$AUX/fake-dl.sh" <<'SH'
#!/usr/bin/env bash
# faux driver-lock.sh de HOME : aucun verrou ; `orphans` rend le fichier orphans.json voisin
D="$(cd "$(dirname "$0")" && pwd)"
case "$1" in
  status) echo '{"present":false}' ;;
  orphans) cat "$D/orphans.json" ;;
esac
SH
cat > "$AUX/req.mjs" <<'JS'
// req.mjs <port> <méthode> <chemin> [jeton] [corps] : ligne 1 statut, ligne 2 en-têtes (JSON), puis le corps ; « ERR <code> » si la connexion échoue (chemin brut, jamais normalisé)
import http from 'node:http';
const [, , port, method, p, token, body] = process.argv;
const headers = { Host: `127.0.0.1:${port}`, ...(token ? { 'x-vf-cockpit-token': token } : {}), ...(body !== undefined ? { 'content-type': 'application/json' } : {}) };
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers }, (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => { console.log(res.statusCode); console.log(JSON.stringify(res.headers)); process.stdout.write(b); }); });
r.on('error', (e) => console.log('ERR ' + e.code)); r.setTimeout(10000, () => r.destroy()); r.end(body);
JS
cat > "$AUX/token.mjs" <<'JS'
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
cat > "$AUX/sse.mjs" <<'JS'
// sse.mjs <port> <jeton> <maxMs> <until> <fichier> : une ligne JSON par événement, s'arrête sur <until> ou après maxMs
import http from 'node:http';
import fs from 'node:fs';
const [, , port, token, maxMs, until, out] = process.argv;
const log = (o) => fs.appendFileSync(out, JSON.stringify({ abs: Date.now(), ...o }) + '\n');
const done = () => { try { req.destroy(); } catch {} process.exit(0); };
const req = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events?token=' + token, headers: { Host: `127.0.0.1:${port}` } }, (res) => {
  log({ status: res.statusCode, headers: res.headers });
  let buf = '';
  res.on('data', (c) => { buf += c; let i; while ((i = buf.indexOf('\n\n')) >= 0) { const b = buf.slice(0, i); buf = buf.slice(i + 2); const ev = /^event: (.*)$/m.exec(b)?.[1], dt = /^data: (.*)$/m.exec(b)?.[1]; if (ev) { log({ event: ev, data: JSON.parse(dt) }); if (ev === until) done(); } } });
});
req.on('error', (e) => { log({ erreur: e.message }); process.exit(0); });
setTimeout(done, Number(maxMs));
JS
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs';
const E = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
const v = new Function('E', 'return (' + process.argv[3] + ')')(E);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/scan.sh" <<'SH'
# scan.sh <dossier> <motif étendu> : « <nombre de fichiers lus> <nombre de fichiers portant le motif> » (le premier nombre est le témoin que le balayage voit quelque chose)
echo "$(find "$1" -type f 2>/dev/null | grep -c .) $(grep -rlE -- "$2" "$1" 2>/dev/null | grep -c .)"
SH
cat > "$AUX/csp.mjs" <<'JS'
// csp.mjs : un en-tête CSP sur l'entrée ; retire les jetons 'sha256-…' et normalise les espaces
let s = ''; process.stdin.on('data', (c) => (s += c)).on('end', () => console.log(s.replace(/'sha256-[A-Za-z0-9+\/=]+'/g, '').replace(/\s+/g, ' ').trim()));
JS
cat > "$AUX/vm-rendu.mjs" <<'JS'
// vm-rendu.mjs <couche.js> <pilote.js> [<données.json>] : exécute la couche d'affichage hors navigateur (vm), fenêtre et document factices (C9).
// Les éléments créés enregistrent leur balise ; tout texte posé (textContent, createTextNode) est conservé ; toute affectation innerHTML est comptée.
// Sortie : une ligne JSON { tags, textes, innerHTML, retour } (retour = la variable __r posée par le pilote), ou { erreur } ; « fichier absent » si la couche n'existe pas.
import fs from 'node:fs';
import vm from 'node:vm';
const [, , couche, pilote, donnees] = process.argv;
if (!fs.existsSync(couche)) { console.log(JSON.stringify({ erreur: 'fichier absent' })); process.exit(0); }
const journal = { tags: [], textes: [], innerHTML: 0 };
const texte = (s) => { journal.textes.push(String(s)); };
function elt(tag, compter = true) {
  const o = { tag, children: [], attrs: {}, className: '', style: {}, dataset: {}, hidden: false, _t: '' };
  if (compter) journal.tags.push(tag);
  for (const k of ['textContent', 'innerText']) Object.defineProperty(o, k, { get: () => o._t, set: (v) => { o._t = String(v); texte(v); } });
  for (const k of ['innerHTML', 'outerHTML']) Object.defineProperty(o, k, { get: () => '', set: () => { journal.innerHTML++; } });
  o.insertAdjacentHTML = () => { journal.innerHTML++; };
  o.appendChild = (c) => { o.children.push(c); return c; };
  o.append = (...cs) => { for (const c of cs) { if (typeof c === 'string') texte(c); o.children.push(c); } };
  o.setAttribute = (k, v) => { o.attrs[k] = String(v); };
  o.getAttribute = (k) => (k in o.attrs ? o.attrs[k] : null);
  o.classList = { add() {}, remove() {}, toggle() {}, contains: () => false };
  o.addEventListener = () => {};
  o.replaceChildren = (...cs) => { o.children = cs; };
  return o;
}
const document = { createElement: (t) => elt(String(t).toLowerCase()), createDocumentFragment: () => elt('#fragment', false), createTextNode: (s) => { texte(s); return { nodeValue: String(s), textContent: String(s) }; } };
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
const ctx = vm.createContext({ window: {}, document, h, DONNEES: donnees ? JSON.parse(fs.readFileSync(donnees, 'utf8')) : null, console });
try {
  vm.runInContext(fs.readFileSync(couche, 'utf8'), ctx, { timeout: 5000 });
  vm.runInContext(fs.readFileSync(pilote, 'utf8'), ctx, { timeout: 5000 });
  console.log(JSON.stringify({ tags: journal.tags, textes: journal.textes, innerHTML: journal.innerHTML, retour: ctx.__r === undefined ? null : ctx.__r }));
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e.message).slice(0, 120) })); }
JS
cat > "$WORK/leurre.mjs" <<'JS'
import net from 'node:net'; const s = net.createServer((c) => { c.on('error', () => {}); c.end('leurre\n'); }); s.listen(Number(process.argv[2]), '127.0.0.1');
JS
# double de vf-cockpit-live.mjs injecté par un crochet de résolution ESM (patron de F3, test-cockpit-serveur.sh) : le serveur est le vrai
cat > "$AUX/live-double.mjs" <<'JS'
export function startLive({ onEvent }) { globalThis.__vfOnEvent = onEvent; return { snapshot: () => globalThis.__vfSnap, etat: () => ({ mode: 'double', seq: 0 }), stop() {} }; }
JS
cat > "$AUX/reg-double.mjs" <<'JS'
import { register } from 'node:module';
register('data:text/javascript,' + encodeURIComponent(`export async function resolve(s, c, n) { if (s === './vf-cockpit-live.mjs') return { url: process.env.VF_DOUBLE_LIVE, shortCircuit: true }; return n(s, c); }`));
JS
cat > "$AUX/porte.mjs" <<'JS'
// porte.mjs <scripts> <lab> : le vrai vf-cockpit-server.mjs de <scripts> (attach + route derrière un http.createServer), le direct remplacé par un double.
// Phases : hello propre (témoin positif) ; flux : un événement propre puis des événements portant mandat / outils / messages à plusieurs profondeurs ; hello portant mandat.
import http from 'node:http';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv; const logs = []; const VALEUR = 'VALEUR-INTERDITE-69';
const { attach } = await import(pathToFileURL(scripts + '/vf-cockpit-server.mjs').href);
const a = attach({ here: lab, root: lab, token: 'tk', inject: '', log: (niv, msg) => logs.push(niv + ' ' + msg) });
const srv = http.createServer((req, res) => { if (!a.route(req, res, new URL(req.url, 'http://x'))) { res.writeHead(404); res.end(); } });
await new Promise((r) => srv.listen(0, '127.0.0.1', r)); const port = srv.address().port;
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const lire = (ms) => new Promise((resolve) => { const ev = []; let fini = false; const rq = http.get({ host: '127.0.0.1', port, path: '/api/vf/events' }, (res) => { let b = ''; res.on('data', (c) => { b += c; for (const m of b.matchAll(/event: (\S+)\ndata: (.*)\n\n/g)) if (!ev.includes(m[1] + m[2])) ev.push(m[1] + m[2]); }); res.on('end', () => { fini = true; }); setTimeout(() => { rq.destroy(); resolve({ ev: ev.map((e) => e.split('{')[0]), brut: ev, fini }); }, ms); }); rq.on('error', () => {}); });
const sortie = {};
globalThis.__vfSnap = { seq: 0, lock: { available: false }, who: { workers: [], sources: {} } };
sortie.helloPropre = await lire(400);
const flux = lire(1100); await pause(300);
globalThis.__vfOnEvent('patch', { seq: 1, patch: [], at: 1 });                                                                  // témoin positif : un événement propre part
globalThis.__vfOnEvent('who', { seq: 2, at: 2, who: { workers: [{ id: 'w', detail: [{ x: [{ mandat: VALEUR }] }] }] } });       // mandat à trois niveaux de profondeur
globalThis.__vfOnEvent('patch', { seq: 3, patch: [], at: 3, outils: VALEUR });                                                  // outils à la racine
globalThis.__vfOnEvent('who', { seq: 4, at: 4, who: { workers: [{ id: 'w', sub: { messages: [VALEUR] } }] } });               // messages dans un travailleur
sortie.flux = await flux;
globalThis.__vfSnap = { seq: 5, lock: { available: false }, who: { workers: [{ id: 'w', sub: { mandat: VALEUR } }], sources: {} } };
sortie.hello = await lire(500);
sortie.logs = logs; sortie.fuite = JSON.stringify(sortie).includes(VALEUR);
console.log(JSON.stringify(sortie)); a.stop(); srv.close(); setTimeout(() => process.exit(0), 100); setTimeout(() => process.exit(1), 8000).unref();
JS

G() { node "$AUX/jget.mjs" "$@"; }
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
NEG=(PENSEE-69 FICHIER-LU-69 TOOLUSERESULT-69 SORTIE-OUTIL-69 ATTACHMENT-69 COMMANDE-SECRETE-69 DESCRIPTION-69 SUIVI-69)
JETON_FACTICE="ghp_abcdefghijklmnopqrstuvwx"
fuites() { local f="$1" n=0 m; for m in "${NEG[@]}" "$JETON_FACTICE"; do grep -q -- "$m" "$f" 2>/dev/null && n=$((n+1)); done; echo "$n"; }    # marqueurs négatifs présents dans un fichier
positifs() { local f="$1" n=0 m; for m in MANDAT-VISIBLE-69 MESSAGE-VISIBLE-69; do grep -q -- "$m" "$f" 2>/dev/null && n=$((n+1)); done; echo "$n"; }  # marqueurs positifs présents

# =====================================================================================================================
echo "=== T0 — contrôles positifs : chaque marqueur négatif est dans la fixture ==="
LAB0="$WORK/lab0"; mkdir -p "$LAB0/src" "$AUX/fx"
node "$AUX/mk-transcript.mjs" "$AUX/fx/agent-ag1.jsonl" "$LAB0"
node "$AUX/mk-transcript.mjs" "$AUX/fx/agent-gros.jsonl" "$LAB0" --id=gros --gros
i=0; for m in "${NEG[@]}"; do i=$((i+1)); assert_eq "T0.$i — la fixture porte $m" "$([ "$(grep -c -- "$m" "$AUX/fx/agent-ag1.jsonl")" -ge 1 ] && echo présent || echo absent)" "présent"; done
assert_eq "T0.9 — la fixture porte le jeton factice du mandat" "$([ "$(grep -c -- "$JETON_FACTICE" "$AUX/fx/agent-ag1.jsonl")" -ge 1 ] && echo présent || echo absent)" "présent"
assert_eq "T0.10 — les lignes ont les types réels (user, assistant, user, api-request-blob, attachment, assistant, user) et la première est une ligne de sous-agent" "$(node -e 'const l=require("fs").readFileSync(process.argv[1],"utf8").trim().split("\n").map(JSON.parse);console.log(l.map((x)=>x.type).join(",")+"|"+l[0].isSidechain+"|"+l[0].agentId+"|"+typeof l[0].message.content)' "$AUX/fx/agent-ag1.jsonl")" "user,assistant,user,api-request-blob,attachment,assistant,user|true|ag1|string"
assert_eq "T0.11 — emplacements : tool_result, toolUseResult et thinking portent chacun leur marqueur" "$(node -e 'const l=require("fs").readFileSync(process.argv[1],"utf8").trim().split("\n").map(JSON.parse);console.log([l[2].message.content[0].type+":"+l[2].message.content[0].content,"toolUseResult:"+l[2].toolUseResult.file.content,l[1].message.content[0].type+":"+l[1].message.content[0].thinking].join(","))' "$AUX/fx/agent-ag1.jsonl")" "tool_result:FICHIER-LU-69,toolUseResult:TOOLUSERESULT-69,thinking:PENSEE-69"
assert_eq "T0.12 — la fixture --gros dépasse 9 Mio" "$([ "$(wc -c < "$AUX/fx/agent-gros.jsonl" | tr -d ' ')" -gt 9437184 ] && echo oui || echo non)" "oui"

# =====================================================================================================================
echo "=== T24 — reduireTranscript : liste blanche, borne, masque (P69-D-19 ; CKPT-24) ==="
node "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/agent-ag1.jsonl" "$LAB0" > "$WORK/red.json"
node "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/agent-gros.jsonl" "$LAB0" > "$WORK/red-gros.json"
RX() { G "$WORK/red.json" "j.absent||($1)"; }
assert_has "T24.1 — le mandat contient MANDAT-VISIBLE-69" "$(RX 'String(j.r.mandat)')" "MANDAT-VISIBLE-69"
assert_eq "T24.2 — le jeton du mandat est masqué ([masqué]) et le mandat reste lisible" "$(RX '(()=>{const m=String(j.r.mandat);return m.includes("ghp_abcdefghijklmnopqrstuvwx")?"jeton en clair":(m.includes("[masqué]")&&m.includes("MANDAT-VISIBLE-69")?"ok":"pas masqué : "+m.slice(0,80))})()')" "ok"
assert_has "T24.3 — les messages contiennent MESSAGE-VISIBLE-69" "$(RX 'JSON.stringify(j.r.messages)')" "MESSAGE-VISIBLE-69"
assert_eq "T24.4 — les outils sont Read|lit|src/a.js puis Bash|lance une commande|" "$(RX '(j.r.outils||[]).map((o)=>[o.outil,o.verbe,o.cible].join("|")).join(",")')" "Read|lit|src/a.js,Bash|lance une commande|"
i=4; for m in "${NEG[@]}"; do i=$((i+1)); assert_eq "T24.$i — la sortie ne contient pas $m (appariée au mandat et au message visibles)" "$(RX '(()=>{const s=JSON.stringify(j.r);if(!(s.includes("MANDAT-VISIBLE-69")&&s.includes("MESSAGE-VISIBLE-69")))return "positifs absents";return s.includes("'"$m"'")?"fuite : '"$m"'":"ok"})()')" "ok"; done
assert_eq "T24.13 — aucune clé input à aucune profondeur (appariée aux positifs)" "$(RX '(()=>{const s=JSON.stringify(j.r);if(!(s.includes("MANDAT-VISIBLE-69")&&s.includes("MESSAGE-VISIBLE-69")))return "positifs absents";const f=(o)=>!!o&&typeof o==="object"&&Object.entries(o).some(([k,v])=>k==="input"||f(v));return f(j.r)?"clé input présente":"ok"})()')" "ok"
assert_eq "T24.14 — fixture --gros : tronque = vrai et réponse en moins de 2 000 ms" "$(G "$WORK/red-gros.json" 'j.absent||(j.r.tronque===true&&j.ms<2000?"ok":"tronque="+j.r.tronque+" ms="+j.ms)')" "ok"
assert_eq "T24.15 — fixture normale : tronque = faux" "$(RX 'j.r.tronque===false?"ok":"tronque="+j.r.tronque')" "ok"
assert_eq "T24.16 — fixture --gros : le mandat tient en 8 000 caractères, de 1 à 50 messages de 2 000 caractères au plus" "$(G "$WORK/red-gros.json" 'j.absent||(()=>{const m=j.r.messages||[];return String(j.r.mandat).length<=8000&&m.length>=1&&m.length<=50&&m.every((x)=>String(x).length<=2000)?"ok":"mandat="+String(j.r.mandat).length+" messages="+m.length+" max="+Math.max(0,...m.map((x)=>String(x).length))})()')" "ok"

# =====================================================================================================================
echo "=== T25 — GET /api/vf/transcript : jeton, identifiants, fenêtre, aucune fuite (P69-D-19, P69-D-23 ; CKPT-25) ==="
LABS="$WORK/labsrv"; mkdir -p "$LABS/src" "$LABS/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LABS/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LABS/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LABS/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LABS/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LABS" init -q && git -C "$LABS" add -A && git -C "$LABS" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LABS" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LABS/.vibeflow/cockpit"
SID="aaaa1111-2222-3333-4444-555566667777"
H="$WORK/home"; mkdir -p "$H/.claude/scripts"
cp "$AUX/fake-dl.sh" "$H/.claude/scripts/driver-lock.sh"; echo '{"orphans":[]}' > "$H/.claude/scripts/orphans.json"
cat > "$AUX/spec-t25.json" <<'JSON'
{"sessionAgeS":2,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":2,"role":"vf-dev-manager"},
 {"id":"ag1","spawnDepth":2,"parent":"mgr1","ageS":2},
 {"id":"ximg","spawnDepth":2,"parent":"mgr1","ageS":2},
 {"id":"xsec","spawnDepth":2,"parent":"mgr1","ageS":2},
 {"id":"ag2h","spawnDepth":2,"parent":"mgr1","ageS":7200,"finished":true,"mandat":"MANDAT-VISIBLE-69 ag2h"},
 {"id":"ag25h","spawnDepth":2,"parent":"mgr1","ageS":90000,"finished":true,"mandat":"MANDAT-VISIBLE-69 ag25h"}]}
JSON
NOW="$(node -e 'console.log(Date.now())')"
node "$AUX/mk-agents.mjs" "$H" "$LABS" "$SID" "$NOW" "$AUX/spec-t25.json" || echo "mk-agents KO" >&2
SUBD="$H/.claude/projects/-lab/$SID/subagents"
node "$AUX/mk-transcript.mjs" "$SUBD/agent-ag1.jsonl" "$LABS" --id=ag1 --age=2
node "$AUX/mk-transcript.mjs" "$SUBD/agent-ximg.jsonl" "$LABS" --id=ximg --payload --age=2
cat > "$AUX/mk-f3.mjs" <<'JS'
// mk-f3.mjs <fichier> <racineLab> <secret> : un mandat propre, un message de l'assistant, un outil Read dont la CIBLE porte le secret et un outil dont le NOM le porte
import fs from 'node:fs';
const [, , out, lab, S] = process.argv;
let k = 0; const side = (o) => JSON.stringify({ cwd: lab, sessionId: 'sess-synthetique', gitBranch: 'main', version: '2.1.317', isSidechain: true, agentId: 'xsec', timestamp: new Date(Date.now() - 600000 + 1000 * k++).toISOString(), ...o });
const tu = (name, input) => side({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'tool_use', id: 'u', name, input }] } });
fs.writeFileSync(out, [side({ type: 'user', message: { role: 'user', content: 'MANDAT-VISIBLE-69' } }),
  side({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: 'MESSAGE-VISIBLE-69 la clé est ' + S + ' fin' }] } }),
  tu('Read', { file_path: `${lab}/src/${S}.js` }), tu('Outil ' + S, {})].join('\n') + '\n');
JS
SECRET_F3="ghp_abcdefghijklmnopqrstuvwxyz0123456789"
node "$AUX/mk-f3.mjs" "$SUBD/agent-xsec.jsonl" "$LABS" "$SECRET_F3"
rafraichir() { touch "$SUBD/agent-mgr1.jsonl" "$SUBD/agent-ag1.jsonl" "$SUBD/agent-ximg.jsonl" "$SUBD/agent-xsec.jsonl" "$H/.claude/projects/-lab/$SID.jsonl"; }
demarrer() { # $1 dossier de sortie, $2 HOME -> SRV_PID SRV_PORT (le serveur est celui de la sortie assemblée ; sa racine est <sortie>/../..)
  local o="$1"; rm -f "$o/.cache/server.json"
  HOME="$2" node "$o/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve-$(basename "$o").out" 2>&1 &
  SRV_PID=$!; PIDS+=("$SRV_PID")
  for _ in $(seq 1 100); do [ -s "$o/.cache/server.json" ] && break; sleep 0.1; done
  SRV_PORT="$(G "$o/.cache/server.json" 'j.port' 2>/dev/null || echo 0)"
}
node "$WORK/leurre.mjs" "$(libre)" & LEURRE=$!; PIDS+=("$LEURRE")
demarrer "$OUT" "$H"; SRV="$SRV_PID"; PORT="$SRV_PORT"
TOK="$(node "$AUX/token.mjs" "$PORT" /)"
RQ() { node "$AUX/req.mjs" "$PORT" "$@"; }
assert_eq "T25.0 — contrôle positif : serveur démarré, jeton lu, leurre vivant, la fixture du HOME porte les 8 marqueurs négatifs" "$([ "$PORT" -gt 0 ] && [ "${#TOK}" -ge 16 ] && echo serveur)|$(ps -p "$LEURRE" >/dev/null 2>&1 && echo leurre)|$(n=0; for m in "${NEG[@]}"; do grep -q -- "$m" "$SUBD/agent-ag1.jsonl" && n=$((n+1)); done; echo "$n")" "serveur|leurre|8"
RQ GET "/api/vf/transcript?id=ag1" "$TOK" > "$WORK/t1.out"; sed '1,2d' "$WORK/t1.out" > "$WORK/t1.body"
assert_eq "T25.1 — avec le jeton : statut 200, schéma vibeflow/cockpit-transcript@1, mandat visible" "$(sed -n 1p "$WORK/t1.out")|$(node "$AUX/jget.mjs" "$WORK/t1.body" 'j.schema')|$(node "$AUX/jget.mjs" "$WORK/t1.body" 'String(j.mandat).includes("MANDAT-VISIBLE-69")')" "200|vibeflow/cockpit-transcript@1|true"
assert_eq "T25.2 — la réponse porte le mandat et le message visibles et aucun marqueur négatif (ni le jeton factice)" "pos=$(positifs "$WORK/t1.body")|neg=$(fuites "$WORK/t1.body")" "pos=2|neg=0"
assert_eq "T25.3 — sans jeton : 403 (apparié à T25.1)" "$(RQ GET "/api/vf/transcript?id=ag1" | sed -n 1p)" "403"
RQ GET "/api/vf/transcript?id=..%2Fetc" "$TOK" > "$WORK/t4.out"
assert_eq "T25.4 — un identifiant porteur de chemin : 400 id-invalide" "$(sed -n 1p "$WORK/t4.out")|$(sed '1,2d' "$WORK/t4.out" | node "$AUX/jq.mjs" 'j.erreur')" "400|id-invalide"
RQ GET "/api/vf/transcript?id=constructor" "$TOK" > "$WORK/t5.out"
assert_eq "T25.5 — un identifiant hors collecte (constructor) : 200 et erreur inconnu" "$(sed -n 1p "$WORK/t5.out")|$(sed '1,2d' "$WORK/t5.out" | node "$AUX/jq.mjs" 'j.erreur')" "200|inconnu"
RQ GET "/api/vf/transcript?id=ag2h" "$TOK" > "$WORK/t6.out"
assert_eq "T25.6 — terminé depuis 2 h : 200 avec son mandat" "$(sed -n 1p "$WORK/t6.out")|$(sed '1,2d' "$WORK/t6.out" | node "$AUX/jq.mjs" 'String(j.mandat).includes("MANDAT-VISIBLE-69")')" "200|true"
RQ GET "/api/vf/transcript?id=ag25h" "$TOK" > "$WORK/t7.out"
assert_eq "T25.7 — terminé depuis 25 h (hors fenêtre) : 200 et erreur inconnu (apparié à T25.6)" "$(sed -n 1p "$WORK/t7.out")|$(sed '1,2d' "$WORK/t7.out" | node "$AUX/jq.mjs" 'j.erreur')" "200|inconnu"
assert_eq "T25.8 — la réponse du transcript porte Cache-Control: no-store" "$(sed -n 2p "$WORK/t1.out" | node "$AUX/jq.mjs" 'j["cache-control"]')" "no-store"
assert_eq "T25.9 — POST avec jeton : 405" "$(RQ POST "/api/vf/transcript?id=ag1" "$TOK" '{}' | sed -n 1p)" "405"
RQ GET "/api/vf/transcript?id=xsec" "$TOK" > "$WORK/t10.out"; sed '1,2d' "$WORK/t10.out" > "$WORK/t10.body"
assert_eq "T25.9b — la route masque le secret d'un message, d'une cible d'outil et d'un nom d'outil (apparié aux positifs : message et 2 outils rendus, 3 masques)" "$(sed -n 1p "$WORK/t10.out")|$(node "$AUX/jget.mjs" "$WORK/t10.body" 'String(j.messages).includes("MESSAGE-VISIBLE-69")&&(j.outils||[]).length===2?(JSON.stringify(j).includes("ghp_")?"fuite":(JSON.stringify(j).split("[masqué]").length-1)+" masques"):"positifs absents : "+JSON.stringify(j).slice(0,120)')" "200|3 masques"
# flux : le hello liste ag1 (positif) ; une session neuve force un événement who ; ni mandat ni message dans le flux
rafraichir
: > "$WORK/flux.jsonl"; node "$AUX/sse.mjs" "$PORT" "$TOK" 12000 who "$WORK/flux.jsonl" & CSSE=$!
for _ in $(seq 1 80); do grep -q '"event":"hello"' "$WORK/flux.jsonl" 2>/dev/null && break; sleep 0.1; done
printf '%s\n' "{\"type\":\"user\",\"cwd\":\"$LABS\",\"sessionId\":\"bbbb1111-2222-3333-4444-555566667777\",\"timestamp\":\"2026-11-03T10:00:00Z\",\"message\":{\"content\":\"autre\"}}" > "$H/.claude/projects/-lab/bbbb1111-2222-3333-4444-555566667777.jsonl"
wait "$CSSE"
assert_eq "T25.10 — le hello liste ag1 (positif), un événement who est arrivé, ni mandat ni message dans le flux" "hello:$(node "$AUX/ev.mjs" "$WORK/flux.jsonl" 'E.find(e=>e.event==="hello").data.who.workers.filter(w=>w.id==="ag1").length')|who:$(node "$AUX/ev.mjs" "$WORK/flux.jsonl" 'E.some(e=>e.event==="who")')|fuite:$(grep -cE 'MANDAT-VISIBLE-69|MESSAGE-VISIBLE-69' "$WORK/flux.jsonl")" "hello:1|who:true|fuite:0"
# fichiers générés, journal du processus
assert_eq "T25.11a — le balayage voit les fichiers de la sortie (au moins 5, project.html compris)" "$([ "$(bash "$AUX/scan.sh" "$OUT" 'MANDAT-VISIBLE-69|MESSAGE-VISIBLE-69' | cut -d' ' -f1)" -ge 5 ] && [ -e "$OUT/project.html" ] && echo oui || echo non)" "oui"
mkdir -p "$WORK/temoin"; printf 'x MANDAT-VISIBLE-69 x\n' > "$WORK/temoin/a.txt"; printf 'MESSAGE-VISIBLE-69\n' > "$WORK/temoin/b.txt"
assert_eq "T25.11b — témoin : le même balayage trouve les deux marqueurs injectés" "$(bash "$AUX/scan.sh" "$WORK/temoin" 'MANDAT-VISIBLE-69|MESSAGE-VISIBLE-69')" "2 2"
assert_eq "T25.11 — aucun fichier de .vibeflow/cockpit ni la sortie du serveur ne porte le mandat ou un message ; equipe.html n'est pas écrit" "$(bash "$AUX/scan.sh" "$OUT" 'MANDAT-VISIBLE-69|MESSAGE-VISIBLE-69' | cut -d' ' -f2)|$(grep -cE 'MANDAT-VISIBLE-69|MESSAGE-VISIBLE-69' "$WORK/serve-cockpit.out")|$([ -e "$OUT/equipe.html" ] && echo equipe.html || echo absent)" "0|0|absent"
RQ GET /api/vf/journal "$TOK" > "$WORK/jr.out"
assert_eq "T25.12 — le journal : 200, au moins un événement (positif), aucun marqueur" "$(sed -n 1p "$WORK/jr.out")|$(sed '1,2d' "$WORK/jr.out" | node "$AUX/jq.mjs" 'j.evenements.length>=1')|$(sed '1,2d' "$WORK/jr.out" | grep -cE 'MANDAT-VISIBLE-69|MESSAGE-VISIBLE-69')" "200|true|0"
RQ POST /api/export "$TOK" '{}' > "$WORK/ex.out"; sed '1,2d' "$WORK/ex.out" > "$WORK/ex.html"
assert_eq "T25.13 — l'export : 200 et un fichier du lab (positif), aucun marqueur" "$(sed -n 1p "$WORK/ex.out")|$([ "$(grep -c 'util.js' "$WORK/ex.html")" -ge 1 ] && echo données)|$(grep -cE 'MANDAT-VISIBLE-69|MESSAGE-VISIBLE-69' "$WORK/ex.html")" "200|données|0"
vf_hyg_stop "$SRV"
assert_eq "T25.14 — le leurre est toujours vivant après l'arrêt du serveur (jamais arrêté par la marque seule)" "$(ps -p "$LEURRE" >/dev/null 2>&1 && echo vivant || echo mort)" "vivant"
vf_hyg_stop "$LEURRE"

# --- M-JETON : copie de la sortie dont le contrôle du jeton est neutralisé (le test de T25.3 sait rougir) ---
MJ="$LABS/.vibeflow/mut-jeton"; cp -R "$OUT" "$MJ"
sed -i.bak "s#if (!sameOrigin || (given !== token \&\& !VF?.jetonValide(given)))#if (false)#" "$MJ/serve.mjs"
rafraichir
demarrer "$MJ" "$H"; PORT="$SRV_PORT"
assert_eq "T25.15 — témoin : sans contrôle de jeton, la route répond 200 sans jeton (le mutant est vu)" "appliqué:$(grep -c 'if (false)' "$MJ/serve.mjs")|sans-jeton:$(RQ GET "/api/vf/transcript?id=ag1" | sed -n 1p)" "appliqué:1|sans-jeton:200"
vf_hyg_stop "$SRV_PID"

# --- M-PORTE : la garde d'émission (flux, hello) et son mutant ---
mkdir -p "$WORK/lab-porte" "$WORK/scripts-mut"
cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$WORK/scripts-mut/"
sed -i.bak 's#^const \(porte[A-Za-z]*\) = .*#const \1 = () => false;#' "$WORK/scripts-mut/vf-cockpit-server.mjs"
APPLIQUE="$(cmp -s "$SCRIPTS/vf-cockpit-server.mjs" "$WORK/scripts-mut/vf-cockpit-server.mjs" && echo non-appliqué || echo appliqué)"
DG="$(VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" VF_DOUBLE_LIVE="file://$AUX/live-double.mjs" node --import "$AUX/reg-double.mjs" "$AUX/porte.mjs" "$SCRIPTS" "$WORK/lab-porte" 2>"$WORK/porte.err")"
DM="$(VF_COCKPIT_SCRIPTS_DIR="$WORK/scripts-mut" VF_DOUBLE_LIVE="file://$AUX/live-double.mjs" node --import "$AUX/reg-double.mjs" "$AUX/porte.mjs" "$WORK/scripts-mut" "$WORK/lab-porte" 2>"$WORK/porte-mut.err")"
dg() { printf '%s' "$DG" | node "$AUX/jq.mjs" "$1"; }
dm() { printf '%s' "$DM" | node "$AUX/jq.mjs" "$1"; }
assert_eq "T25.16a — témoin positif : un hello propre part, puis le hello et l'événement propre arrivent dans le flux" "$(dg 'j.helloPropre.ev.length+","+j.flux.ev.slice(0,2).join("/")')" "1,hello/patch"
assert_eq "T25.16 — un snapshot portant une clé mandat : le hello n'est jamais émis, la réponse est close" "$(dg 'j.hello.ev.length+","+j.hello.fini')" "0,true"
assert_eq "T25.16b — dans le flux, les événements portant mandat, outils ou messages (toute profondeur) sont refusés : seul l'événement propre passe" "$(dg 'j.flux.ev.filter(e=>e!=="hello").join(",")')" "patch"
assert_eq "T25.16c — la valeur interdite ne figure nulle part dans la sortie du serveur (flux, hello, journal des refus)" "$(dg 'j.fuite')" "false"
assert_eq "T25.17 — témoin : une copie dont la garde d'émission rend toujours faux laisse passer le hello à clé mandat, l'original le refuse" "$APPLIQUE|copie:$(dm 'j.hello.ev.length')|original:$(dg 'j.hello.ev.length')" "appliqué|copie:1|original:0"

# =====================================================================================================================
echo "=== T26 — rendu en texte et CSP inchangée (P69-D-23 ; CKPT-26) ==="
RENDU="$UI/71-vf-equipe-rendu.js"
cat > "$AUX/pilote-transcript.js" <<'JS'
__r = !!window.__vfEquipeRendu.transcript({ mandat: '<img src=x onerror=alert(1)>', messages: ['<script>x()</script>'], outils: [{ outil: 'Read', verbe: 'lit', cible: 'src/a.js' }] }, document);
JS
cat > "$AUX/pilote-arbre.js" <<'JS'
__r = window.__vfEquipeRendu.arbre([
  { kind: 'session', id: 's1', tree: '.', source: 'transcript', etat: 'actif', task: '' },
  { kind: 'subagent', id: 'a1', tree: '.', source: 'transcript', etat: 'actif', role: 'vf-coder', task: '<img src=x onerror=alert(1)>', parent: 's1', depth: 1 }], h);
JS
node "$AUX/vm-rendu.mjs" "$RENDU" "$AUX/pilote-transcript.js" > "$WORK/vm-t.json"
node "$AUX/vm-rendu.mjs" "$RENDU" "$AUX/pilote-arbre.js" > "$WORK/vm-a.json"
VT() { G "$WORK/vm-t.json" "j.erreur||($1)"; }
assert_eq "T26.1 — transcript() ne crée que des balises div, h4, p, ul, li, pre, span (ni img ni script), et en crée" "$(VT '(()=>{const ok=new Set(["div","h4","p","ul","li","pre","span"]);const t=j.tags;const hors=[...new Set(t.filter((x)=>!ok.has(x)))];return !t.length?"aucune balise créée":hors.length?"hors liste : "+hors.join(","):"ok"})()')" "ok"
assert_eq "T26.2 — un nœud a pour texte exactement <img src=x onerror=alert(1)>" "$(VT 'j.tags.length?String(j.textes.includes("<img src=x onerror=alert(1)>")):"aucune balise créée"')" "true"
assert_eq "T26.3 — aucune affectation innerHTML (appariée à la création de balises)" "$(VT 'j.tags.length?String(j.innerHTML):"aucune balise créée"')" "0"
assert_eq "T26.4 — arbre() avec l'échappement standard : la description piégée sort en &lt;img, jamais en <img" "$(G "$WORK/vm-a.json" 'j.erreur||(String(j.retour).includes("&lt;img")+"|"+!String(j.retour).includes("<img"))')" "true|true"
CSPV="default-src 'none'; script-src ; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'"
rafraichir
demarrer "$OUT" "$H"; PORT="$SRV_PORT"
csp_de() { RQ GET "$1" | sed -n 2p | node "$AUX/jq.mjs" 'j["content-security-policy"]||"aucun en-tête"' | node "$AUX/csp.mjs"; }
assert_eq "T26.0 — contrôle positif : la CSP réduite de /project.html vaut la chaîne de v2.75.0" "$(csp_de /project.html)" "$CSPV"
assert_eq "T26.5 — la CSP réduite de /equipe.html vaut la chaîne de v2.75.0" "$(csp_de /equipe.html)" "$CSPV"
assert_eq "T26.6 — elle est égale à celle de /project.html réduite" "$(csp_de /equipe.html)" "$(csp_de /project.html)"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then
  echo "  ⊘ T26.7 SAUTÉ : aucun navigateur — non compté comme réussi"
else
  cat > "$AUX/chrome-t26.js" <<'JS'
(async () => {
  const attendre = async (sel) => { for (let i = 0; i < 100 && !document.querySelector(sel); i++) await new Promise((r) => setTimeout(r, 100)); return document.querySelector(sel); };
  if (!document.querySelector('.vf-transcript')) { const b = await attendre('[data-vf-transcript]'); if (!b) return { erreur: 'bouton Lire le transcript absent' }; b.click(); }
  const c = await attendre('.vf-transcript'); if (!c) return { erreur: 'conteneur .vf-transcript absent' };
  return { img: c.querySelectorAll('img').length, texte: c.textContent.includes('<img src=x onerror='), sel: window.VibeFlow.state.selected };
})()
JS
  rafraichir
  VF_CDP_ECHEANCE_MS=20000 CDP_PRET="document.readyState === 'complete'" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 500 "$(cat "$AUX/chrome-t26.js")" "http://127.0.0.1:$PORT/equipe.html#r=n%3Aag-ximg" > "$WORK/chrome-t26.json" 2>&1
  assert_eq "T26.7 — Chrome : le transcript d'un agent au message <img onerror> s'affiche en texte (0 élément img, la source lisible)" "$(G "$WORK/chrome-t26.json" 'j.erreur||(j.resultats[0].valeur.erreur||("img="+j.resultats[0].valeur.img+"|texte="+j.resultats[0].valeur.texte))')" "img=0|texte=true"
  assert_eq "T26.8 — Chrome : arriver sur equipe.html#r=n:ag-ximg sélectionne la carte visée (state.selected), quel que soit l'ordre de livraison du flux (F2)" "$(G "$WORK/chrome-t26.json" 'j.erreur||(j.resultats[0].valeur.erreur||String(j.resultats[0].valeur.sel))')" "n:ag-ximg"
fi
vf_hyg_stop "$SRV_PID"

# =====================================================================================================================
echo "=== T24F — correction d'audit : masque avant la coupe, coût borné par ce qui sort (F1, F4 ; P69-D-19) ==="
cat > "$AUX/mk-f1.mjs" <<'JS'
// mk-f1.mjs <fichier> <secret> : mandat portant le secret à 16 caractères avant 4 000 et avant 8 000, un message le portant à 16 caractères avant 2 000 (les bornes de coupe : il reste son préfixe et quelques caractères, trop peu pour qu'un masque appliqué APRÈS la coupe le reconnaisse)
import fs from 'node:fs';
const [, , out, S] = process.argv; const pad = (n) => 'x'.repeat(n);
// le secret est séparé de son remplissage par une espace (les motifs de secret exigent une frontière de mot)
const mandat = pad(3983) + ' ' + S + pad(7983 - 3983 - S.length) + ' ' + S + ' ' + pad(100), message = pad(1983) + ' ' + S + ' ' + pad(500);
const side = (o) => ({ isSidechain: true, agentId: 'f1', ...o });
fs.writeFileSync(out, [side({ type: 'user', message: { role: 'user', content: mandat } }), side({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: message }] } })].map((l) => JSON.stringify(l)).join('\n') + '\n');
JS
cat > "$AUX/mk-f4.mjs" <<'JS'
// mk-f4.mjs <fichier> <racineLab> texte|outils : 8,5 Mio de lignes assistant, soit des blocs text de 3 900 caractères (motif dense pour le masque), soit des tool_use Read
import fs from 'node:fs';
const [, , out, lab, mode] = process.argv; const motif = 'tokensecret'.repeat(355).slice(0, 3900);
const L = [JSON.stringify({ type: 'user', isSidechain: true, agentId: 'f4', message: { role: 'user', content: 'MANDAT-VISIBLE-69' } })]; let n = 0;
while (n < 8.5 * 1048576) {
  const c = mode === 'outils' ? [{ type: 'tool_use', id: 'u', name: 'Read', input: { file_path: `${lab}/src/a.js` } }] : [{ type: 'text', text: motif }];
  const l = JSON.stringify({ type: 'assistant', isSidechain: true, agentId: 'f4', message: { role: 'assistant', content: c } }); L.push(l); n += l.length + 1;
}
fs.writeFileSync(out, L.join('\n') + '\n');
JS
i=0; for P in 'ghp_|ghp_abcdefghijklmnopqrstuvwxyz0123456789' 'github_pat_|github_pat_abcdefghijklmnopqrstuvwxyz0123456789' 'sk-|sk-abcdefghijklmnopqrstuvwxyz0123456789' 'AKIA|AKIAABCDEFGHIJKLMNOP' 'Bearer|Bearer abcdefghijklmnopqrstuvwxyz0123456789'; do
  i=$((i+1)); PRE="${P%%|*}"; SEC="${P#*|}"
  node "$AUX/mk-f1.mjs" "$AUX/fx/f1-$i.jsonl" "$SEC"; node "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/f1-$i.jsonl" "$LAB0" > "$WORK/f1-$i.json"
  assert_eq "T24F1.$i.0 — contrôle positif : la fixture porte $PRE trois fois et la sortie existe" "$(grep -o -- "$PRE" "$AUX/fx/f1-$i.jsonl" | wc -l | tr -d ' ')|$(G "$WORK/f1-$i.json" 'j.absent||"sortie"')" "3|sortie"
  assert_eq "T24F1.$i.1 — aucun fragment de $PRE au point de coupe du mandat (4 000, 8 000) ni du message (2 000)" "$(G "$WORK/f1-$i.json" 'j.absent||(()=>{const s=JSON.stringify(j.r);return s.includes("[masqué]")?(s.includes("'"$PRE"'")?"fragment présent":"ok"):"rien de masqué"})()')" "ok"
done
mkdir -p "$AUX/f4/lab/src"; echo ok > "$AUX/f4/lab/src/a.js"
node "$AUX/mk-f4.mjs" "$AUX/fx/f4-texte.jsonl" "$AUX/f4/lab" texte; node "$AUX/mk-f4.mjs" "$AUX/fx/f4-outils.jsonl" "$AUX/f4/lab" outils
node "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/f4-texte.jsonl" "$AUX/f4/lab" > "$WORK/f4-texte.json"; node "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/f4-outils.jsonl" "$AUX/f4/lab" > "$WORK/f4-outils.json"
assert_eq "T24F4.0 — contrôle positif : fixtures de plus de 8 Mio, 50 messages et 200 outils rendus" "$([ "$(wc -c < "$AUX/fx/f4-texte.jsonl" | tr -d ' ')" -gt 8388608 ] && [ "$(wc -c < "$AUX/fx/f4-outils.jsonl" | tr -d ' ')" -gt 8388608 ] && echo grosses)|$(G "$WORK/f4-texte.json" 'j.absent||j.r.messages.length')|$(G "$WORK/f4-outils.json" 'j.absent||j.r.outils.length')" "grosses|50|200"
assert_eq "T24F4.1 — 8,5 Mio de blocs text au motif dense : moins de 2 000 ms (le masque ne couvre que les 50 messages gardés)" "$(G "$WORK/f4-texte.json" 'j.absent||(j.ms<2000?"ok":"ms="+j.ms)')" "ok"
assert_eq "T24F4.2 — GARDE NON DISCRIMINANTE (durée seule : l'ancien code passait en 0,8 s) ; la borne de l'étiquette est prouvée par T24G2 — 8,5 Mio de tool_use Read en moins de 2 000 ms" "$(G "$WORK/f4-outils.json" 'j.absent||(j.ms<2000?"ok":"ms="+j.ms)')" "ok"

# =====================================================================================================================
echo "=== T24F3 — correction de revue : chacun des sites de masque (message de l'assistant, cible d'outil, nom d'outil) a son témoin et son mutant (F3 ; P69-D-19) ==="
node "$AUX/mk-f3.mjs" "$AUX/fx/f3.jsonl" "$LAB0" "$SECRET_F3"
f3() { node "$AUX/red.mjs" "$1" "$AUX/fx/f3.jsonl" "$LAB0" | G /dev/stdin 'j.absent||(()=>{const s=JSON.stringify(j.r);const o=j.r.outils||[];const pos=s.includes("MESSAGE-VISIBLE-69")&&o.length===2&&String(o[0].cible).startsWith("src/")&&String(o[0].outil)==="Read";if(!pos)return "positifs absents : "+s.slice(0,160);return s.includes("ghp_")?"fuite : "+(String(j.r.messages).includes("ghp_")?"message ":"")+(o.some((x)=>String(x.cible).includes("ghp_"))?"cible ":"")+(o.some((x)=>String(x.outil).includes("ghp_"))?"nom d outil":""):"ok"})()'; }
assert_eq "T24F3.0 — contrôle positif : la fixture porte le secret trois fois (message, cible, nom d'outil)" "$(grep -o -- "$SECRET_F3" "$AUX/fx/f3.jsonl" | wc -l | tr -d ' ')" "3"
assert_eq "T24F3.1 — reduireTranscript : le secret d'un message de l'assistant, d'une cible d'outil et d'un nom d'outil sort masqué (apparié aux positifs)" "$(f3 "$SCRIPTS")" "ok"
MUTD="$AUX/mutsrc"; mkdir -p "$MUTD"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$MUTD/"
mutant() { cp "$SCRIPTS/vf-cockpit-transcript.mjs" "$MUTD/vf-cockpit-transcript.mjs"; sed -i.bak "s#$1#$2#" "$MUTD/vf-cockpit-transcript.mjs"; if cmp -s "$SCRIPTS/vf-cockpit-transcript.mjs" "$MUTD/vf-cockpit-transcript.mjs"; then echo "MUTANT VIDE"; else f3 "$MUTD"; fi; }
assert_eq "T24F3.2 — mutant : message de l'assistant non masqué -> détecté" "$(mutant 'msgs.map((t) => masqueCoupe(t, BORNE_MESSAGE))' 'msgs.map((t) => t.slice(0, BORNE_MESSAGE))')" "fuite : message "
assert_eq "T24F3.3 — mutant : cible d'outil non masquée -> détecté" "$(mutant 'return { outil, verbe, cible: fin(cible) };' 'return { outil, verbe, cible };')" "fuite : cible "
assert_eq "T24F3.4 — mutant : nom d'outil non masqué -> détecté" "$(mutant "const outil = fin(name) || '?';" "const outil = chaine(name) || '?';")" "fuite : nom d outil"

echo "=== T24G — revue fraîche : masque borné au texte brut, première ligne trop longue, tube, cache, borne d'étiquette (points 1, 4, 5, 6, 8, 9, 10) ==="
cat > "$AUX/mk-f1b.mjs" <<'JS'
// mk-f1b.mjs <fichier> blob|url : mandat (borne 8 000) et message (borne 2 000).
// blob : un blob masqué de 1 200 caractères avant la borne (le masque raccourcit la tranche) puis un jeton à cheval sur la borne de la tranche ÉLARGIE ;
// url : identifiants d'URL (portée 385 caractères) commençant 10 caractères avant la borne, leur « @ » se trouvant 375 caractères après.
import fs from 'node:fs';
const [, , out, mode] = process.argv; const pad = (n) => 'x'.repeat(n); const S = 'ghp_abcdefghijklmnopqrstuvwxyz0123456789';
const texte = (n) => { if (mode === 'blob') { const b = 'API_TOKEN=' + 'a'.repeat(1200) + ' '; return b + pad(n + 684 - b.length) + ' ' + S; } return pad(n - 14) + ' ://' + 'U'.repeat(128) + ':' + 'P'.repeat(256) + '@h.example ' + 'y'.repeat(50); };
const side = (o) => ({ isSidechain: true, agentId: 'f1b', ...o });
fs.writeFileSync(out, [side({ type: 'user', message: { role: 'user', content: texte(8000) } }), side({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: texte(2000) }] } })].map((l) => JSON.stringify(l)).join('\n') + '\n');
JS
node "$AUX/mk-f1b.mjs" "$AUX/fx/f1b-blob.jsonl" blob; node "$AUX/mk-f1b.mjs" "$AUX/fx/f1b-url.jsonl" url
node "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/f1b-blob.jsonl" "$LAB0" > "$WORK/f1b-blob.json"; node "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/f1b-url.jsonl" "$LAB0" > "$WORK/f1b-url.json"
assert_eq "T24G1.0 — contrôle positif : les fixtures portent le jeton (ghp_) et les identifiants d'URL (U, P), les sorties existent" "$(grep -c 'ghp_' "$AUX/fx/f1b-blob.jsonl")|$(grep -c '://UUUU' "$AUX/fx/f1b-url.jsonl")|$(G "$WORK/f1b-blob.json" 'j.absent||"sortie"')|$(G "$WORK/f1b-url.json" 'j.absent||"sortie"')" "2|2|sortie|sortie"
assert_eq "T24G1.1 (point 1) — un blob masqué raccourcit la tranche : aucun caractère de la zone d'extension (ghp) dans le mandat ni le message" "$(G "$WORK/f1b-blob.json" 'j.absent||(()=>{const m=String(j.r.mandat),g=j.r.messages.join("");return m.includes("[masqué]")&&g.includes("[masqué]")?(/ghp/.test(m+g)?"fuite de la zone d extension":"ok"):"blob non masqué"})()')" "ok"
assert_eq "T24G1.2 (point 6) — identifiants d'URL (portée 385) commençant avant la borne : aucun fragment (U, P) au mandat ni au message, sorties non vides" "$(G "$WORK/f1b-url.json" 'j.absent||(()=>{const m=String(j.r.mandat),g=j.r.messages.join("");return m.length>100&&g.length>100?(/UUUU|PPPP/.test(m+g)?"fragment d identifiants":"ok"):"sortie vide"})()')" "ok"
cat > "$AUX/cnt.mjs" <<'JS'
// cnt.mjs <scripts> <fichier> <racine> : nombre d'appels à fs.realpathSync pendant reduireTranscript (la borne de l'étiquette, sans horloge)
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, fichier, root] = process.argv; const orig = fs.realpathSync; let n = 0;
fs.realpathSync = (...a) => { n++; return orig(...a); };
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-transcript.mjs')).href);
const r = m.reduireTranscript(fichier, { root }); console.log(JSON.stringify({ n, outils: r.outils.length }));
JS
assert_eq "T24G2 (point 9) — 8,5 Mio de tool_use Read : au plus 2 appels à realpath par outil gardé (200 outils, 410 appels), donc pas d'étiquette sur les outils écartés" "$(node "$AUX/cnt.mjs" "$SCRIPTS" "$AUX/fx/f4-outils.jsonl" "$AUX/f4/lab" | node "$AUX/jq.mjs" 'j.outils===200&&j.n>0&&j.n<=410?"ok":"n="+j.n+" outils="+j.outils')" "ok"
cat > "$AUX/mk-long.mjs" <<'JS'
// mk-long.mjs <fichier> : première ligne user de 300 Kio (au-delà de la fenêtre de tête de 256 Kio), puis un message
import fs from 'node:fs';
const side = (o) => JSON.stringify({ isSidechain: true, agentId: 'long', ...o });
fs.writeFileSync(process.argv[2], side({ type: 'user', message: { role: 'user', content: 'L'.repeat(300 * 1024) } }) + '\n' + side({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: 'MESSAGE-VISIBLE-69' }] } }) + '\n');
JS
node "$AUX/mk-long.mjs" "$AUX/fx/long.jsonl"; node "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/long.jsonl" "$LAB0" > "$WORK/long.json"
assert_eq "T24G3 (point 10) — première ligne de 300 Kio : mandat vide ET tronque = vrai (le message reste rendu : contrôle positif)" "$(G "$WORK/long.json" 'j.absent||(j.r.messages.join("").includes("MESSAGE-VISIBLE-69")?(j.r.mandat===""&&j.r.tronque===true?"ok":"mandat="+j.r.mandat.length+" tronque="+j.r.tronque):"message absent")')" "ok"
cat > "$AUX/pl.mjs" <<'JS'
// pl.mjs <scripts> <fichier> : premiereLigne d'un fichier vide (échec), puis du même fichier une fois écrit
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, f] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-lecture.mjs')).href);
fs.writeFileSync(f, ''); const a = m.premiereLigne(f);
fs.writeFileSync(f, JSON.stringify({ type: 'user', ok: 1 }) + '\n'); const b = m.premiereLigne(f);
console.log(JSON.stringify({ a, b }));
JS
assert_eq "T24G4 (point 8) — un échec transitoire (fichier vide) n'est pas retenu : null puis l'objet une fois le fichier écrit" "$(node "$AUX/pl.mjs" "$SCRIPTS" "$AUX/fx/pl.jsonl" | node "$AUX/jq.mjs" 'j.a===null&&j.b&&j.b.ok===1?"ok":JSON.stringify(j)')" "ok"
cat > "$AUX/borne.mjs" <<'JS'
// borne.mjs <ms> <commande node et arguments...> : exécute un enfant node borné par une limite de temps (SIGKILL, sans tube) ; une ligne JSON { timedOut, status, out }
import { spawnSync } from 'node:child_process';
const [, , ms, ...args] = process.argv;
const r = spawnSync(process.execPath, args, { timeout: Number(ms), killSignal: 'SIGKILL', encoding: 'utf8', maxBuffer: 64 << 20 });
console.log(JSON.stringify({ timedOut: r.error?.code === 'ETIMEDOUT', status: r.status, out: r.stdout || '' }));
JS
rm -f "$AUX/fx/fifo.jsonl"; mkfifo "$AUX/fx/fifo.jsonl"
node "$AUX/borne.mjs" 5000 "$AUX/red.mjs" "$SCRIPTS" "$AUX/fx/fifo.jsonl" "$LAB0" > "$WORK/fifo.json"; rm -f "$AUX/fx/fifo.jsonl"
assert_eq "T24G5 (points 4, 5) — un transcript qui est un tube (FIFO) ne bloque pas reduireTranscript (enfant borné à 5 s) : ni délai dépassé, ni mandat" "$(G "$WORK/fifo.json" '(j.timedOut?"bloqué":"rendu")+"|"+(j.out.includes("mandat")?"mandat":"sans mandat")')" "rendu|mandat"

vf_hyg_assert

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
