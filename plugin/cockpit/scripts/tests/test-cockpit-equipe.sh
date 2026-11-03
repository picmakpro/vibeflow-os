#!/usr/bin/env bash
# test-cockpit-equipe.sh — équipe au travail : arbre, historique de 24 h, rattachement aux nœuds, dernière action,
# schéma who@2 (CKPT-19 à 22, 28 ; P69-D-14 à P69-D-18, P69-D-23). Fixtures reconstruites dans mktemp à chaque appel.
#   E0  contrôles positifs de la fixture (fichiers écrits, la session est listée)
#   E19 arbre session -> manager -> worker ; manager silencieux en attente ; registre fusionné
#   E20 historique : terminé depuis 2 h présent, depuis 25 h absent, fenêtre de 86400 s
#   E21 rattachement aux nœuds de mission : registre, citation du mandat, inconnu, ambigu, jamais deviné
#   E22 dernière action lisible (verbe + cible), jamais l'argument d'une commande, ni dans who ni dans le flux SSE
#   E28 schéma vibeflow/cockpit-who@2 conforme au contrat, qui ne déclare plus @1
#   EP  coût de collecte sur 40 sous-agents (garde de non-régression, T-69-06)
# 69-04 ajoute E23 et EUI.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"

WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; NOSCRIPTS="$WORK/noscripts"
mkdir -p "$AUX" "$NOSCRIPTS"
PIDS=()

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite (jamais de long node -e) ---
cat > "$AUX/q.mjs" <<'JS'
// q.mjs <scripts> who|whotime|project <root> <home> <scriptsDir> [<nowMs>] : le code testé est chargé depuis <scripts>
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, what, root, home, scriptsDir, extra] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const now = extra ? Number(extra) : undefined;
if (what === 'who') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.collectWho(root, { home, scriptsDir, now }))); }
else if (what === 'whotime') { const m = await imp('vf-cockpit-who.mjs'); const t0 = Date.now(); const r = m.collectWho(root, { home, scriptsDir, now }); console.log(JSON.stringify({ ms: Date.now() - t0, n: r.workers.filter((w) => w.kind === 'subagent').length })); }
else if (what === 'project') { const m = await imp('vf-cockpit-project.mjs'); console.log(JSON.stringify(m.buildProjectGraph(root))); }
JS
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <entrée> <sortie> <instructions sur j> : copie modifiée d'une sortie JSON (témoins du validateur)
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
new Function('j', process.argv[4])(j);
fs.writeFileSync(process.argv[3], JSON.stringify(j));
JS
cat > "$AUX/validate2.mjs" <<'JS'
// validate2.mjs <interface.json> <schemaId> <sortie.json> — validateur de test-cockpit-who.sh étendu :
// schéma absent du contrat, clés requises et typées, `schema` égal, clés interdites à toute profondeur,
// requis des travailleurs, kinds, états de source, ET toute clé d'un travailleur hors requis ∪ optionnels.
import fs from 'node:fs';
const [, , ifaceF, id, outF] = process.argv;
const spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas?.[id];
if (!spec) { console.log('KO schéma absent du contrat : ' + id); process.exit(1); }
const out = JSON.parse(fs.readFileSync(outF, 'utf8'));
const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) {
  if (!(k in out)) errs.push(`clé requise absente : ${k}`);
  else if (t !== 'any' && type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])} au lieu de ${t}`);
}
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`clé interdite présente : ${k}`); });
const permis = new Set([...(spec.travailleur?.requis || []), ...(spec.travailleur?.optionnels || [])]);
for (const w of out.workers || []) {
  for (const k of spec.travailleur?.requis || []) if (!(k in w)) errs.push(`travailleur ${w.id} : clé ${k} absente`);
  for (const k of Object.keys(w)) if (!permis.has(k)) errs.push(`travailleur ${w.id} : clé non déclarée : ${k}`);
  if (!(spec.kinds || []).includes(w.kind)) errs.push(`kind inconnu : ${w.kind}`);
}
for (const s of Object.values(out.sources || {})) if (!(spec.etatsSource || []).includes(s.etat)) errs.push(`état de source inconnu : ${s.etat}`);
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
process.exit(errs.length ? 1 : 0);
JS
cat > "$AUX/mk-agents.mjs" <<'JS'
// mk-agents.mjs <home> <lab> <idSession> <nowMs> <spec.json> : session Claude Code + sous-agents à la forme réelle mesurée (R5.1),
// valeurs synthétiques. spec = { sessionAgeS, agents: [{ id, spawnDepth, parent, finished, ageS, mandat, role, dureeS, dernierAppel: { name, input } }] }.
// `{{LAB}}` est remplacé par la racine du lab. La date de modification de chaque .jsonl est posée à now - ageS.
import fs from 'node:fs';
import path from 'node:path';
const [, , home, lab, sid, nowMs, specF] = process.argv;
const now = Number(nowMs);
const spec = JSON.parse(fs.readFileSync(specF, 'utf8').split('{{LAB}}').join(lab));
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
  const debut = now - a.ageS * 1000 - (a.dureeS ?? 300) * 1000;
  const appel = a.dernierAppel || { name: 'Read', input: { file_path: `${lab}/README.md` } };
  put(path.join(sub, `agent-${a.id}.jsonl`), [
    base({ type: 'user', isSidechain: true, agentId: a.id, parentUuid: null, timestamp: iso(debut), message: { role: 'user', content: a.mandat ?? `mandat synthétique de ${a.id}` } }),
    base({ type: 'assistant', isSidechain: true, agentId: a.id, timestamp: iso(now - a.ageS * 1000), message: { role: 'assistant', content: [{ type: 'tool_use', id: `toolu_x${a.id}`, name: appel.name, input: appel.input }] } }),
  ], a.ageS);
}
JS
cat > "$AUX/gen-ep.mjs" <<'JS'
// gen-ep.mjs <sortie.json> : 40 sous-agents (1 manager + 19 workers actifs, 20 workers terminés depuis 1 h)
import fs from 'node:fs';
const agents = [{ id: 'mgr1', spawnDepth: 1, ageS: 5, role: 'vf-dev-manager' }];
for (let i = 1; i <= 19; i++) agents.push({ id: `act${i}`, spawnDepth: 2, parent: 'mgr1', ageS: 4 });
for (let i = 1; i <= 20; i++) agents.push({ id: `fin${i}`, spawnDepth: 2, parent: 'mgr1', ageS: 3600, finished: true });
fs.writeFileSync(process.argv[2], JSON.stringify({ sessionAgeS: 5, agents }));
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
cat > "$AUX/token.mjs" <<'JS'
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs';
const E = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
const v = new Function('E', 'return (' + process.argv[3] + ')')(E);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
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
cat > "$WORK/leurre.mjs" <<'JS'
import net from 'node:net'; const s = net.createServer((c) => { c.on('error', () => {}); c.end('leurre\n'); }); s.listen(Number(process.argv[2]), '127.0.0.1');
JS

Q() { node "$AUX/q.mjs" "$SCRIPTS" "$@"; }
G() { node "$AUX/get.mjs" "$@"; }
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
NOW="$(node -e 'console.log(Date.now())')"
IFACE="$SCRIPTS/vf-cockpit-interface.json"
mkhome() { # $1 nom, $2 fichier de spécification, $3 racine du lab, $4 fichier orphans (facultatif) -> chemin du HOME jetable
  local h="$WORK/home-$1"; mkdir -p "$h/.claude/scripts"
  cp "$AUX/fake-dl.sh" "$h/.claude/scripts/driver-lock.sh"
  if [ -n "${4:-}" ]; then cp "$4" "$h/.claude/scripts/orphans.json"; else echo '{"orphans":[]}' > "$h/.claude/scripts/orphans.json"; fi
  node "$AUX/mk-agents.mjs" "$h" "$3" "$SID" "$NOW" "$2" || echo "mk-agents KO ($1)" >&2
  echo "$h"
}
# sf <sortie who> <id sous-agent> <expression sur w> : valeur, ou « absent » si le sous-agent n'est pas dans la sortie
sf() { G "$1" '(w=>w?('"$3"'):"absent")(j.workers.find(x=>x.kind==="subagent"&&x.id==="'"$2"'"))'; }
# ratt <sortie who> <id> : rattachement en une ligne
ratt() { G "$1" '(w=>{const r=w&&w.rattachement;return r?(r.etat==="rattache"?["rattache",r.source,r.dag,r.noeud].join("|"):["non-rattache",r.raison].join("|")):"aucun"})(j.workers.find(x=>x.kind==="subagent"&&x.id==="'"$2"'"))'; }
# act <sortie who> <id> : action en une ligne (verbe|cible), « aucune » sinon
act() { G "$1" '(w=>w&&w.action?w.action.verbe+"|"+w.action.cible:"aucune")(j.workers.find(x=>x.kind==="subagent"&&x.id==="'"$2"'"))'; }

# --- lab git jetable commun ---
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning"; git -C "$LAB" init -q
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
SID="aaaa1111-2222-3333-4444-555566667777"

echo "=== E0 — contrôles positifs de la fixture ==="
cat > "$AUX/spec-f3n.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"w1","spawnDepth":2,"parent":"mgr1","ageS":3,"role":"vf-coder"}]}
JSON
H3N="$(mkhome f3n "$AUX/spec-f3n.json" "$LAB")"
SUBD="$H3N/.claude/projects/-lab/$SID/subagents"
Q who "$LAB" "$H3N" "$NOSCRIPTS" "$NOW" > "$WORK/who-f3n.json"
assert_eq "E0.1 — la fixture porte 2 meta.json et 2 transcripts de sous-agent" "$(ls "$SUBD" | grep -c 'meta.json')|$(ls "$SUBD" | grep -c '[.]jsonl$')" "2|2"
assert_eq "E0.2 — la session fraîche est listée" "$(G "$WORK/who-f3n.json" 'j.workers.filter(w=>w.kind==="session"&&w.id==="'$SID'").length')" "1"
assert_eq "E0.3 — la première ligne du transcript de w1 est une ligne de sous-agent (isSidechain, agentId, mandat chaîne)" "$(head -1 "$SUBD/agent-w1.jsonl" | node -e 'const l=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log([l.type,l.isSidechain,l.agentId,typeof l.message.content].join(","))')" "user,true,w1,string"
assert_eq "E0.4 — w1 (profondeur 2) porte parentAgentId, mgr1 (profondeur 1) n'en porte pas" "$(node -e 'const fs=require("fs");const d=process.argv[1];const a=JSON.parse(fs.readFileSync(d+"/agent-w1.meta.json","utf8")),b=JSON.parse(fs.readFileSync(d+"/agent-mgr1.meta.json","utf8"));console.log(a.parentAgentId+","+("parentAgentId" in b))' "$SUBD")" "mgr1,false"
assert_eq "E0.5 — témoin : les deux sous-agents actifs sont listés (la fixture est lisible)" "$(G "$WORK/who-f3n.json" 'j.workers.filter(x=>x.kind==="subagent").map(x=>x.id).sort().join(",")')" "mgr1,w1"

echo "=== E19 — arbre session -> manager -> worker (P69-D-14) ==="
assert_eq "E19.1 — w1 a pour parent son manager (pas la session)" "$(sf "$WORK/who-f3n.json" w1 w.parent)" "mgr1"
assert_eq "E19.2 — mgr1 a pour parent la session" "$(sf "$WORK/who-f3n.json" mgr1 w.parent)" "$SID"
assert_eq "E19.3 — profondeurs mgr1=1 et w1=2" "$(sf "$WORK/who-f3n.json" mgr1 w.depth):$(sf "$WORK/who-f3n.json" w1 w.depth)" "1:2"
cat > "$AUX/spec-e19.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"w1","spawnDepth":2,"parent":"mgr1","ageS":3},
 {"id":"mgr2","spawnDepth":1,"ageS":600,"role":"vf-dev-manager"},
 {"id":"w2","spawnDepth":2,"parent":"mgr2","ageS":4}]}
JSON
echo '{"orphans":[{"agent_id":"w1","role":"vf-coder","node":"revue-p3","parent":"mgr1","depth":2,"age_seconds":3,"status":"running"}]}' > "$AUX/orphans-e19.json"
H19="$(mkhome e19 "$AUX/spec-e19.json" "$LAB" "$AUX/orphans-e19.json")"
Q who "$LAB" "$H19" "$NOSCRIPTS" "$NOW" > "$WORK/who-e19.json"
assert_eq "E19.0 — contrôle positif : le registre est lu (source locks lue) et w2 est listé" "$(G "$WORK/who-e19.json" 'j.sources.locks.etat')|$(sf "$WORK/who-e19.json" w2 '"present"')" "lue|present"
assert_eq "E19.4 — mgr2 (silencieux, worker actif) est présent en en-attente" "$(sf "$WORK/who-e19.json" mgr2 w.etat)" "en-attente"
assert_eq "E19.5 — w2 a pour parent mgr2" "$(sf "$WORK/who-e19.json" w2 w.parent)" "mgr2"
assert_eq "E19.6 — un seul travailleur d'identifiant w1 (sous-agent et registre fusionnés)" "$(G "$WORK/who-e19.json" 'j.workers.filter(x=>x.id==="w1").length')" "1"

echo "=== E20 — historique de 24 h (P69-D-18) ==="
cat > "$AUX/spec-e20.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"fin2h","spawnDepth":2,"parent":"mgr1","ageS":7200,"finished":true},
 {"id":"fin25h","spawnDepth":2,"parent":"mgr1","ageS":90000,"finished":true}]}
JSON
H20="$(mkhome e20 "$AUX/spec-e20.json" "$LAB")"
D20="$H20/.claude/projects/-lab/$SID/subagents"
Q who "$LAB" "$H20" "$NOSCRIPTS" "$NOW" > "$WORK/who-e20.json"
assert_eq "E20.0 — contrôle positif : les deux meta.json portent finished: true" "$(grep -l '"finished":true' "$D20/agent-fin2h.meta.json" "$D20/agent-fin25h.meta.json" | wc -l | tr -d ' ')" "2"
assert_eq "E20.1 — fin2h est présent et termine" "$(sf "$WORK/who-e20.json" fin2h w.etat)" "termine"
assert_eq "E20.2 — fin2h porte finAt" "$(sf "$WORK/who-e20.json" fin2h 'typeof w.finAt')" "string"
assert_eq "E20.3 — fin25h est absent (garde : vert avant le code, le positif est E20.1)" "$(sf "$WORK/who-e20.json" fin25h w.etat)" "absent"
assert_eq "E20.4 — fenetre = 86400" "$(G "$WORK/who-e20.json" 'j.fenetre')" "86400"
cat > "$AUX/spec-e20b.json" <<'JSON'
{"sessionAgeS":600,"agents":[
 {"id":"fin1","spawnDepth":1,"ageS":7200,"finished":true}]}
JSON
H20B="$(mkhome e20b "$AUX/spec-e20b.json" "$LAB")"
Q who "$LAB" "$H20B" "$NOSCRIPTS" "$NOW" > "$WORK/who-e20b.json"
assert_eq "E20.5 — session silencieuse et un seul terminé : busy = false et la session racine est termine" "$(G "$WORK/who-e20b.json" 'j.busy+"|"+((j.workers.find(x=>x.kind==="session"&&x.id==="'$SID'")||{}).etat)')" "false|termine"

echo "=== E21 — rattachement aux nœuds de mission (P69-D-15) ==="
LAB21="$WORK/lab21"; mkdir -p "$LAB21/.planning/missions"; git -C "$LAB21" init -q
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB21/.planning/ROADMAP.md"
dag() { printf '{"nodes":[{"id":"%s","step":"x","stage":"s","deps":[],"scope":[],"status":"ready"}]}\n' "$2" > "$1"; }
dag "$LAB21/.planning/missions/m1.dag.json" revue-p3
dag "$LAB21/.planning/MISSION-5.dag.json" docs
dag "$LAB21/.planning/missions/m2.dag.json" docs
assert_eq "E21.0 — contrôle positif : un DAG porte revue-p3 et deux DAG portent docs" "$(grep -l 'revue-p3' "$LAB21"/.planning/missions/*.dag.json "$LAB21"/.planning/*.dag.json | wc -l | tr -d ' ')|$(grep -l '"docs"' "$LAB21"/.planning/missions/*.dag.json "$LAB21"/.planning/*.dag.json | wc -l | tr -d ' ')" "1|2"
cat > "$AUX/spec-e21.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"w1","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"Exécute le travail demandé."},
 {"id":"a-cite","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"Nœud `revue-p3` — fais la revue"},
 {"id":"a-inconnu","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"Nœud `noeud-absent` — fais le travail"},
 {"id":"a-ambigu","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"Nœud `docs` — rédige"},
 {"id":"a-prose","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"le nœud revue-p3 est à faire"},
 {"id":"a-reg-ambigu","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"Nœud `revue-p3` — fais la revue"}]}
JSON
cat > "$AUX/orphans-e21.json" <<'JSON'
{"orphans":[
 {"agent_id":"w1","role":"vf-coder","node":"revue-p3","parent":"mgr1","depth":2,"age_seconds":3,"status":"running"},
 {"agent_id":"a-reg-ambigu","role":"vf-coder","node":"docs","parent":"mgr1","depth":2,"age_seconds":3,"status":"running"}]}
JSON
H21="$(mkhome e21 "$AUX/spec-e21.json" "$LAB21" "$AUX/orphans-e21.json")"
Q who "$LAB21" "$H21" "$NOSCRIPTS" "$NOW" > "$WORK/who-e21.json"
assert_eq "E21.1 — w1 : le registre décide -> rattache|registre|m1|revue-p3" "$(ratt "$WORK/who-e21.json" w1)" "rattache|registre|.planning/missions/m1.dag.json|revue-p3"
assert_eq "E21.2 — a-cite : « Nœud \`revue-p3\` » du mandat -> rattache|mandat|m1|revue-p3" "$(ratt "$WORK/who-e21.json" a-cite)" "rattache|mandat|.planning/missions/m1.dag.json|revue-p3"
assert_eq "E21.3 — a-inconnu : nœud absent de tout DAG -> non-rattache|inconnu" "$(ratt "$WORK/who-e21.json" a-inconnu)" "non-rattache|inconnu"
assert_eq "E21.4 — a-ambigu : docs vit dans deux DAG -> non-rattache|ambigu (jamais deviné)" "$(ratt "$WORK/who-e21.json" a-ambigu)" "non-rattache|ambigu"
assert_eq "E21.5 — a-prose : nœud cité sans accents graves -> non-rattache|sans-citation" "$(ratt "$WORK/who-e21.json" a-prose)" "non-rattache|sans-citation"
assert_eq "E21.6 — a-reg-ambigu : le registre (docs, ambigu) décide seul malgré une citation claire -> non-rattache|ambigu" "$(ratt "$WORK/who-e21.json" a-reg-ambigu)" "non-rattache|ambigu"
LAB21W="$WORK/lab21w"; mkdir -p "$LAB21W/.planning/workstreams/alpha"; git -C "$LAB21W" init -q
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB21W/.planning/workstreams/alpha/ROADMAP.md"
dag "$LAB21W/.planning/workstreams/alpha/MISSION-9.dag.json" seul-ws
cat > "$AUX/spec-e21w.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"a-ws","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"--node=seul-ws"}]}
JSON
H21W="$(mkhome e21w "$AUX/spec-e21w.json" "$LAB21W")"
Q who "$LAB21W" "$H21W" "$NOSCRIPTS" "$NOW" > "$WORK/who-e21w.json"
assert_eq "E21.7 — a-ws : le nœud ne vit que dans un DAG de compartiment (lab partitionné) -> rattache|mandat|…alpha/MISSION-9|seul-ws" "$(ratt "$WORK/who-e21w.json" a-ws)" "rattache|mandat|.planning/workstreams/alpha/MISSION-9.dag.json|seul-ws"

echo "=== E22 — dernière action lisible, sans argument de commande (P69-D-16) ==="
cat > "$AUX/spec-e22.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"a-bash","spawnDepth":2,"parent":"mgr1","ageS":3,"dernierAppel":{"name":"Bash","input":{"command":"curl -H \"Authorization: Bearer SECRET-FACTICE-69\" https://exemple.test/x"}}},
 {"id":"a-lit","spawnDepth":2,"parent":"mgr1","ageS":3,"dernierAppel":{"name":"Read","input":{"file_path":"{{LAB}}/src/a.js"}}},
 {"id":"a-hors","spawnDepth":2,"parent":"mgr1","ageS":3,"dernierAppel":{"name":"Read","input":{"file_path":"/etc/FACTICE-HORS-LAB-69"}}},
 {"id":"a-web","spawnDepth":2,"parent":"mgr1","ageS":3,"dernierAppel":{"name":"WebFetch","input":{"url":"https://exemple.test/p?token=SECRET-URL-69"}}},
 {"id":"a-agent","spawnDepth":2,"parent":"mgr1","ageS":3,"dernierAppel":{"name":"Agent","input":{"subagent_type":"vf-coder","description":"d","prompt":"p"}}},
 {"id":"fin2h","spawnDepth":2,"parent":"mgr1","ageS":7200,"finished":true}]}
JSON
H22="$(mkhome e22 "$AUX/spec-e22.json" "$LAB")"
Q who "$LAB" "$H22" "$NOSCRIPTS" "$NOW" > "$WORK/who-e22.json"
assert_eq "E22.0 — contrôle positif : les cinq agents actifs sont listés" "$(G "$WORK/who-e22.json" 'j.workers.filter(x=>x.kind==="subagent"&&x.id.startsWith("a-")).length')" "5"
assert_eq "E22.1 — a-bash : lance une commande, cible vide" "$(act "$WORK/who-e22.json" a-bash)" "lance une commande|"
assert_eq "E22.2 — a-lit : lit, chemin relatif au lab" "$(act "$WORK/who-e22.json" a-lit)" "lit|src/a.js"
assert_eq "E22.3 — a-hors : lit un fichier hors du lab" "$(act "$WORK/who-e22.json" a-hors)" "lit|un fichier hors du lab"
assert_eq "E22.4 — a-web : hôte seul" "$(act "$WORK/who-e22.json" a-web)" "consulte une page|exemple.test"
assert_eq "E22.5 — a-agent : lance un agent, cible = type" "$(act "$WORK/who-e22.json" a-agent)" "lance un agent|vf-coder"
assert_eq "E22.6 — fin2h (terminé) sans action" "$(act "$WORK/who-e22.json" fin2h)" "aucune"
LEAK="$(grep -cE 'SECRET-FACTICE-69|SECRET-URL-69|FACTICE-HORS-LAB-69|curl' "$WORK/who-e22.json")"
assert_eq "E22.7 — aucun secret, aucun chemin hors lab, pas le mot curl dans la sortie JSON de who (garde appariée au positif E22.1)" "$LEAK" "0"
# flux SSE : serveur du lab neutre, sous un HOME jetable portant la même équipe (fixture rafraîchie : le serveur lit l'horloge réelle)
LABS="$WORK/labsrv"; mkdir -p "$LABS/src" "$LABS/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LABS/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LABS/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LABS/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LABS/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LABS" init -q && git -C "$LABS" add -A && git -C "$LABS" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LABS" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
NOW="$(node -e 'console.log(Date.now())')"
HS="$(mkhome srv "$AUX/spec-e22.json" "$LABS")"
OUT="$LABS/.vibeflow/cockpit"
node "$WORK/leurre.mjs" "$(libre)" & LEURRE=$!; PIDS+=("$LEURRE")
HOME="$HS" node "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 &
SRV=$!; PIDS+=("$SRV")
for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
PORT="$(G "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)"
TOK="$(node "$AUX/token.mjs" "$PORT" /)"
assert_eq "E22.0b — contrôle positif : serveur démarré, jeton lu dans la page, leurre vivant" "$([ "$PORT" -gt 0 ] && [ "${#TOK}" -ge 16 ] && echo serveur)|$(ps -p "$LEURRE" >/dev/null 2>&1 && echo leurre)" "serveur|leurre"
: > "$WORK/flux.jsonl"; node "$AUX/sse.mjs" "$PORT" "$TOK" 3000 hello "$WORK/flux.jsonl"
assert_eq "E22.8a — contrôle positif : le hello du flux liste le sous-agent a-bash" "$(node "$AUX/ev.mjs" "$WORK/flux.jsonl" 'E.find(e=>e.event==="hello").data.who.workers.filter(w=>w.id==="a-bash").length')" "1"
assert_eq "E22.8 — le hello du flux contient « lance une commande »" "$([ "$(grep -c 'lance une commande' "$WORK/flux.jsonl")" -ge 1 ] && echo present || echo absent)" "present"
assert_eq "E22.9 — aucun des trois secrets dans le flux" "$(grep -cE 'SECRET-FACTICE-69|SECRET-URL-69|FACTICE-HORS-LAB-69' "$WORK/flux.jsonl")" "0"
vf_hyg_stop "$SRV"
assert_eq "E22.10 — le leurre est toujours vivant après l'arrêt du serveur (jamais arrêté par la marque seule)" "$(ps -p "$LEURRE" >/dev/null 2>&1 && echo vivant || echo mort)" "vivant"
vf_hyg_stop "$LEURRE"
NOW="$(node -e 'console.log(Date.now())')"

echo "=== E28 — schéma vibeflow/cockpit-who@2 (P69-D-23) ==="
cat > "$AUX/contrat-mini.json" <<'JSON'
{"schemas":{"vibeflow/cockpit-who@2":{"requis":{"at":"string","root":"string","trees":"array","fresh":"number","fenetre":"number","busy":"boolean","workers":"array","sources":"object"},"travailleur":{"requis":["kind","id","tree","source"],"optionnels":["role","task","parent","depth","etat"]},"interdits":["doing","mandat","messages","outils"],"kinds":["session","subagent","lock","registered","dag-node"],"etatsSource":["lue","absente","erreur","forme-inconnue"]}}}
JSON
echo '{"schema":"vibeflow/cockpit-who@2","at":"x","root":"x","trees":[],"fresh":180,"fenetre":86400,"busy":false,"workers":[{"kind":"session","id":"s","tree":"t","source":"transcript"}],"sources":{}}' > "$WORK/mini-ok.json"
node "$AUX/mut.mjs" "$WORK/mini-ok.json" "$WORK/mini-etat2.json" 'j.workers[0].etat2="x"'
node "$AUX/mut.mjs" "$WORK/mini-ok.json" "$WORK/mini-mandat.json" 'j.mandat="x"'
assert_eq "E28.0a — contrôle du validateur (contrat jetable) : une sortie conforme est acceptée" "$(node "$AUX/validate2.mjs" "$AUX/contrat-mini.json" vibeflow/cockpit-who@2 "$WORK/mini-ok.json")" "OK"
assert_has "E28.0b — contrôle du validateur : une clé de travailleur non déclarée est refusée" "$(node "$AUX/validate2.mjs" "$AUX/contrat-mini.json" vibeflow/cockpit-who@2 "$WORK/mini-etat2.json")" "clé non déclarée"
assert_has "E28.0c — contrôle du validateur : la clé mandat est refusée" "$(node "$AUX/validate2.mjs" "$AUX/contrat-mini.json" vibeflow/cockpit-who@2 "$WORK/mini-mandat.json")" "clé interdite présente : mandat"
assert_eq "E28.1 — la sortie porte le schéma vibeflow/cockpit-who@2" "$(G "$WORK/who-f3n.json" 'j.schema')" "vibeflow/cockpit-who@2"
assert_eq "E28.2 — la sortie de la fixture F3N est conforme au schéma @2 du contrat" "$(node "$AUX/validate2.mjs" "$IFACE" vibeflow/cockpit-who@2 "$WORK/who-f3n.json")" "OK"
node "$AUX/mut.mjs" "$WORK/who-f3n.json" "$WORK/who-etat2.json" 'j.workers[0].etat2="x"'
node "$AUX/mut.mjs" "$WORK/who-f3n.json" "$WORK/who-mandat.json" 'j.mandat="x"'
assert_has "E28.3 — témoin : une copie où un travailleur gagne etat2 est refusée (clé non déclarée)" "$(node "$AUX/validate2.mjs" "$IFACE" vibeflow/cockpit-who@2 "$WORK/who-etat2.json")" "clé non déclarée"
assert_has "E28.4 — témoin : une copie qui porte mandat est refusée (clé interdite)" "$(node "$AUX/validate2.mjs" "$IFACE" vibeflow/cockpit-who@2 "$WORK/who-mandat.json")" "clé interdite présente : mandat"
assert_eq "E28.5 — le contrat ne déclare plus vibeflow/cockpit-who@1" "$(G "$IFACE" 'Object.keys(j.schemas).filter(k=>k==="vibeflow/cockpit-who@1").length')" "0"

echo "=== EP — coût de collecte sur 40 sous-agents (T-69-06) ==="
node "$AUX/gen-ep.mjs" "$AUX/spec-ep.json"
HEP="$(mkhome ep "$AUX/spec-ep.json" "$LAB")"
Q whotime "$LAB" "$HEP" "$NOSCRIPTS" "$NOW" > "$WORK/ep.json"
assert_eq "EP.1 — collectWho rend en moins de 3 000 ms (garde, vert avant le code ; ce n'est pas un témoin)" "$(G "$WORK/ep.json" 'j.ms < 3000')" "true"
assert_eq "EP.2 — les 40 sous-agents (20 actifs, 20 terminés depuis moins de 24 h) sont listés" "$(G "$WORK/ep.json" 'j.n')" "40"

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
