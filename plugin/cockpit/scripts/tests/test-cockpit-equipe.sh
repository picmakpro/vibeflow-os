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
#   E23 onglet Équipe : page /equipe.html, graphe cockpit-equipe@1, couche d'onglets, sonde de libellés (CKPT-23 ; P69-D-17)
#   EUI rendu de l'arbre hors navigateur (vm) : imbrication, terminés repliés, liens dans les deux sens, pied (CKPT-19 à 22 ; P69-D-14 à P69-D-18)
#   EK  clavier et témoins mineurs de l'onglet Équipe dans un vrai Chromium : focus après Entrée sur « Lire le transcript », mutants de comportement (UIFN-12, UIFN-13)
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
for _ in $(seq 1 300); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
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

echo "=== E32 — « écrit à <rôle> », jamais un identifiant brut (Q2a ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-04) ==="
cat > "$AUX/spec-e32.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"w-cible","spawnDepth":2,"parent":"mgr1","ageS":3,"role":"vf-reviewer"},
 {"id":"w-ecrit","spawnDepth":2,"parent":"mgr1","ageS":3,"dernierAppel":{"name":"SendMessage","input":{"to":"w-cible","message":"x"}}},
 {"id":"w-inconnu","spawnDepth":2,"parent":"mgr1","ageS":3,"dernierAppel":{"name":"SendMessage","input":{"to":"destinataire-ABSENT-32","message":"x"}}}]}
JSON
H32="$(mkhome e32 "$AUX/spec-e32.json" "$LAB")"
Q who "$LAB" "$H32" "$NOSCRIPTS" "$NOW" > "$WORK/who-e32.json"
assert_eq "E32.0 — contrôle positif : les trois agents sont listés et le destinataire connu porte son rôle dans la collecte" "$(G "$WORK/who-e32.json" 'j.workers.filter(x=>["w-cible","w-ecrit","w-inconnu"].includes(x.id)).length+"|"+j.workers.find(x=>x.id==="w-cible").role')" "3|vf-reviewer"
assert_eq "E32.1 — rôle connu : « écrit à vf-reviewer »" "$(act "$WORK/who-e32.json" w-ecrit)" "écrit à|vf-reviewer"
assert_eq "E32.2 — rôle inconnu : « écrit à un agent »" "$(act "$WORK/who-e32.json" w-inconnu)" "écrit à|un agent"
assert_eq "E32.3 — aucun identifiant de destinataire brut, ni champ interne _to, dans la sortie (apparié au positif E32.1)" "$(grep -c 'destinataire-ABSENT-32\|"_to"' "$WORK/who-e32.json")" "0"

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

echo "=== E23 — onglet Équipe : page, graphe, onglets, libellés (P69-D-17 ; CKPT-23) ==="
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"
cat > "$AUX/fetchp.mjs" <<'JS'
// fetchp.mjs <port> <chemin> <sortie> : écrit le corps dans <sortie>, rend le statut ; « ERR <code> » si la connexion échoue
import http from 'node:http';
import fs from 'node:fs';
const [, , port, p, out] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { const c = []; r.on('data', (d) => c.push(d)); r.on('end', () => { fs.writeFileSync(out, Buffer.concat(c)); console.log(r.statusCode); }); }).on('error', (e) => console.log('ERR ' + e.code));
JS
cat > "$AUX/graphe.mjs" <<'JS'
// graphe.mjs <dossier du module> <page.html> : le graphe embarqué de la page (extraireGraphe du module de ce dossier : la sortie assemblée), ou { erreur }
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, f] = process.argv;
const { extraireGraphe } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-embed.mjs')).href);
try { console.log(JSON.stringify(extraireGraphe(fs.readFileSync(f, 'utf8')))); } catch (e) { console.log(JSON.stringify({ erreur: 'graphe illisible : ' + String(e.message).slice(0, 80) })); }
JS
cat > "$AUX/sonde-fr.mjs" <<'JS'
// sonde-fr.mjs <scripts> <fichier.js>... : les littéraux que `litteraux` + `estAnglais` jugent anglais ET qui ne figuraient pas déjà, tels quels,
// dans le fichier de v2.75.0 (bruit connu de estAnglais sur du français sans accent : « Session », « Verrou »…). Un fichier nouveau n'a pas de passif.
// Sortie : « aucune », ou une ligne « nom : chaîne » par littéral, ou « fichier absent : nom ».
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, ...fichiers] = process.argv;
const { litteraux, estAnglais } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-fr-inventaire.mjs')).href);
const CONNU = {
  '70-vf-live.js': ['Driver libre', 'Session', 'Verrou', 'Nœud de DAG', '{} min', ' · orphelin', '<p>Personne. Sources lues : ', 'Personne', 'tenu depuis', 'Agent', 'Source illisible', 'Sources illisibles'],
  '72-vf-equipe.js': ['Source illisible', 'Sources illisibles'],
  '71-vf-equipe-rendu.js': ['Session', 'en attente', '{} min', ' · orphelin', 'Agent', 'Mandat', 'Messages', 'Outils', 'Session principale', ', orphelin', 'arbre principal', ' · en attente', ', orphelin ?'], // libellés français affichés, que estAnglais prend pour de l'anglais faute d'accent (la sonde voit tout autre littéral)
  '00-vibeflow.js': ['Projet', 'Code', ', #ask', '#btn-health{} { display: none !important; } #panel .stats:not(.vf-stats) { display: none; } #panel .sec:has(> .list > a[data-hc-open]) { display: none; }', 'Bloquant', 'phase ne figure', 'phases ne figurent', 'non lu', 'non lus', 'header .brand', 'en planification', 'en pause', 'Phase {}{} '],
};
const sortie = [];
for (const f of fichiers) {
  const nom = path.basename(f);
  if (!fs.existsSync(f)) { sortie.push('fichier absent : ' + nom); continue; }
  const connu = new Set(CONNU[nom] || []);
  for (const s of litteraux(fs.readFileSync(f, 'utf8'))) if (estAnglais(s) && !connu.has(s)) sortie.push(nom + ' : ' + s);
}
console.log(sortie.length ? sortie.join('\n') : 'aucune');
JS
cat > "$AUX/spec-e23.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"w1","spawnDepth":2,"parent":"mgr1","ageS":3,"role":"vf-coder"},
 {"id":"fin2h","spawnDepth":2,"parent":"mgr1","ageS":7200,"finished":true}]}
JSON
NOW="$(node -e 'console.log(Date.now())')"
H23="$(mkhome e23 "$AUX/spec-e23.json" "$LABS")"
rm -f "$OUT/.cache/server.json"
HOME="$H23" node "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve23.out" 2>&1 &
SRV23=$!; PIDS+=("$SRV23")
for _ in $(seq 1 300); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
PORT23="$(G "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)"
S23="$(node "$AUX/fetchp.mjs" "$PORT23" /equipe.html "$WORK/equipe.html")"
P23="$(node "$AUX/fetchp.mjs" "$PORT23" /project.html "$WORK/project23.html")"
assert_eq "E23.0 — contrôle positif : serveur démarré et /project.html servi (200)" "$([ "$PORT23" -gt 0 ] && echo serveur)|$P23" "serveur|200"
assert_eq "E23.1 — GET /equipe.html -> 200" "$S23" "200"
assert_has "E23.2 — le titre de la page contient « VibeFlow · Équipe »" "$(grep -o '<title>[^<]*</title>' "$WORK/equipe.html" 2>/dev/null || echo 'aucun titre')" "VibeFlow · Équipe"
# 69-07 : le lecteur du graphe est celui de la SORTIE assemblée (marqueur renommé window.VF_COCKPIT), comme le code servi — jamais celui des sources (window.FLOORPLAN)
node "$AUX/graphe.mjs" "$OUT" "$WORK/equipe.html" > "$WORK/graphe-e23.json"
assert_eq "E23.3 — le graphe embarqué porte le schéma vibeflow/cockpit-equipe@1 et meta.vfTab = equipe" "$(G "$WORK/graphe-e23.json" 'j.erreur||(j.schema+"|"+(j.meta||{}).vfTab)')" "vibeflow/cockpit-equipe@1|equipe"
assert_eq "E23.4 — cartes : session racine, manager sous la session, worker sous son manager, terminés sous un bloc du manager, st active/done, aucun fichier" "$(G "$WORK/graphe-e23.json" 'j.erreur||(()=>{const n=(id)=>(j.nodes||[]).find((x)=>x.id===id)||{};return [n("se-'$SID'").parent??"-",n("ag-mgr1").parent,n("ag-w1").parent,n("ag-mgr1~termines").parent,n("ag-fin2h").parent,n("ag-w1").st,n("ag-fin2h").st,(j.files||[]).length].join("|")})()')" "-|se-$SID|ag-mgr1|ag-mgr1|ag-mgr1~termines|active|done|0"
assert_eq "E23.5 — le graphe est conforme au schéma vibeflow/cockpit-equipe@1 du contrat" "$(node "$AUX/validate2.mjs" "$IFACE" vibeflow/cockpit-equipe@1 "$WORK/graphe-e23.json")" "OK"
assert_eq "E23.6 — 00-vibeflow.js reconnaît la valeur equipe de vfTab et porte le lien equipe.html intitulé « Équipe »" "$([ "$(grep -c "'equipe'" "$UI/00-vibeflow.js")" -ge 1 ] && echo vfTab)|$([ "$(grep -c 'equipe\.html' "$UI/00-vibeflow.js")" -ge 1 ] && echo lien)|$([ "$(grep -c 'Équipe' "$UI/00-vibeflow.js")" -ge 1 ] && echo intitule)" "vfTab|lien|intitule"
assert_eq "E23.7 — sonde de libellés : aucune chaîne anglaise nouvelle dans le chrome de l'équipe (couche d'affichage, onglet, tiroir, onglets)" "$(node "$AUX/sonde-fr.mjs" "$SCRIPTS" "$UI/71-vf-equipe-rendu.js" "$UI/72-vf-equipe.js" "$UI/70-vf-live.js" "$UI/00-vibeflow.js")" "aucune"
mkdir -p "$AUX/sonde"; cp "$UI/70-vf-live.js" "$AUX/sonde/70-vf-live.js"
assert_eq "E23.8a — contrôle positif de la sonde : le tiroir tel quel n'a rien de nouveau" "$(node "$AUX/sonde-fr.mjs" "$SCRIPTS" "$AUX/sonde/70-vf-live.js")" "aucune"
printf "\nconst libelleTemoin = 'Show the transcript now';\n" >> "$AUX/sonde/70-vf-live.js"
assert_has "E23.8 — témoin : la sonde voit la chaîne anglaise Show the transcript now ajoutée à une copie de 70-vf-live.js" "$(node "$AUX/sonde-fr.mjs" "$SCRIPTS" "$AUX/sonde/70-vf-live.js")" "Show the transcript now"
assert_eq "E23.9 — la page n'est jamais écrite sur disque (equipe.html absent), contrôle positif : project.html existe" "equipe:$([ -e "$OUT/equipe.html" ] && echo present || echo absent)|project:$([ -e "$OUT/project.html" ] && echo present || echo absent)" "equipe:absent|project:present"
vf_hyg_stop "$SRV23"

echo "=== EUI — rendu de l'arbre hors navigateur : imbrication, terminés repliés, liens, pied (P69-D-14, D-15, D-16, D-18) ==="
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
cat > "$AUX/nid.mjs" <<'JS'
// nid.mjs <html.txt> <id>... : pour chaque id, l'identifiant du plus proche ancêtre porteur de data-vf-agent (« - » s'il n'en a pas, « absent » s'il n'est pas dans la sortie), séparés par des virgules.
// nid.mjs <html.txt> --termine <id> : « ferme|resume » si l'élément est dans un <details class="vf-termines"> SANS attribut open dont le résumé contient « Terminés depuis moins de 24 h ».
import fs from 'node:fs';
const [, , f, ...args] = process.argv;
const html = fs.readFileSync(f, 'utf8');
const VOID = new Set(['br', 'hr', 'img', 'input', 'meta', 'link', 'area', 'base', 'col', 'embed', 'source', 'track', 'wbr']);
const re = /<(\/?)([A-Za-z][\w-]*)((?:"[^"]*"|'[^']*'|[^'">])*)>/g;
const pile = []; const vus = new Map(); let m;
while ((m = re.exec(html))) {
  const [tout, ferme, tag, attrs] = m; const t = tag.toLowerCase();
  if (ferme) { for (let i = pile.length - 1; i >= 0; i--) if (pile[i].tag === t) { pile.length = i; break; } continue; }
  const agent = /\bdata-vf-agent="([^"]*)"/.exec(attrs)?.[1];
  if (agent !== undefined) { const anc = [...pile].reverse().find((p) => p.agent !== undefined); vus.set(agent, { anc: anc ? anc.agent : '-', pile: pile.map((p) => ({ ...p })) }); }
  if (!VOID.has(t) && !/\/\s*$/.test(attrs)) pile.push({ tag: t, agent, brut: tout, fin: re.lastIndex });
}
if (!vus.size) { console.log('aucun élément data-vf-agent : ' + html.slice(0, 60)); process.exit(0); }
if (args[0] === '--termine') {
  const v = vus.get(args[1]); if (!v) { console.log('absent'); process.exit(0); }
  const d = [...v.pile].reverse().find((p) => p.tag === 'details' && /class="[^"]*\bvf-termines\b/.test(p.brut));
  if (!d) { console.log('pas dans un details.vf-termines'); process.exit(0); }
  if (/\sopen(\s|=|>|\/)/.test(d.brut)) { console.log('details ouvert'); process.exit(0); }
  const s = /<summary[^>]*>([\s\S]*?)<\/summary>/.exec(html.slice(d.fin))?.[1] || '';
  console.log(s.includes('Terminés depuis moins de 24 h') ? 'ferme|resume' : 'ferme|resume absent : ' + s.slice(0, 60));
} else console.log(args.map((id) => (vus.has(id) ? vus.get(id).anc : 'absent')).join(','));
JS
cat > "$AUX/workers-eui.json" <<JSON
{"workers":[
 {"kind":"session","id":"$SID","tree":".","source":"transcript","etat":"actif","task":"salut"},
 {"kind":"subagent","id":"mgr1","tree":".","source":"transcript","etat":"actif","role":"vf-dev-manager","task":"tâche synthétique mgr1","parent":"$SID","depth":1},
 {"kind":"subagent","id":"w1","tree":".","source":"transcript","etat":"actif","role":"vf-coder","task":"tâche synthétique w1","parent":"mgr1","depth":2,"rattachement":{"etat":"rattache","source":"registre","dag":".planning/missions/m1.dag.json","noeud":"revue-p3"}},
 {"kind":"subagent","id":"a-bash","tree":".","source":"transcript","etat":"actif","role":"vf-coder","task":"tâche synthétique a-bash","parent":"mgr1","depth":2,"action":{"verbe":"lance une commande","cible":""}},
 {"kind":"subagent","id":"fin2h","tree":".","source":"transcript","etat":"termine","role":"vf-coder","task":"tâche synthétique fin2h","parent":"mgr1","depth":2,"finAt":"2026-11-03T08:00:00.000Z","dureeS":300}]}
JSON
echo '__r = window.__vfEquipeRendu.arbre(DONNEES.workers, h);' > "$AUX/pilote-arbre.js"
cat > "$AUX/pilote-noeud.js" <<'JS'
__r = { a: window.__vfEquipeRendu.agentsDuNoeud(DONNEES.workers, 'f:.planning/missions/m1.dag.json#revue-p3', h), b: window.__vfEquipeRendu.agentsDuNoeud(DONNEES.workers, 'f:autre#x', h) };
JS
echo "__r = window.__vfEquipeRendu.pied(DONNEES.workers.find((w) => w.id === 'a-bash'));" > "$AUX/pilote-pied.js"
RENDU="$UI/71-vf-equipe-rendu.js"
node "$AUX/vm-rendu.mjs" "$RENDU" "$AUX/pilote-arbre.js" "$AUX/workers-eui.json" > "$WORK/vm-arbre.json"
node "$AUX/vm-rendu.mjs" "$RENDU" "$AUX/pilote-noeud.js" "$AUX/workers-eui.json" > "$WORK/vm-noeud.json"
node "$AUX/vm-rendu.mjs" "$RENDU" "$AUX/pilote-pied.js" "$AUX/workers-eui.json" > "$WORK/vm-pied.json"
G "$WORK/vm-arbre.json" 'j.erreur||j.retour' > "$WORK/arbre.html"
assert_eq "EUI.1 — arbre : w1 est imbriqué sous mgr1 et mgr1 sous la session" "$(node "$AUX/nid.mjs" "$WORK/arbre.html" w1 mgr1)" "mgr1,$SID"
assert_eq "EUI.2 — le tiroir (70-vf-live.js) appelle __vfEquipeRendu.arbre" "$([ "$(grep -c '__vfEquipeRendu\.arbre' "$UI/70-vf-live.js")" -ge 1 ] && echo appelle || echo non)" "appelle"
assert_eq "EUI.3 — fin2h est dans un details.vf-termines fermé dont le résumé dit « Terminés depuis moins de 24 h »" "$(node "$AUX/nid.mjs" "$WORK/arbre.html" --termine fin2h)" "ferme|resume"
assert_has "EUI.4 — un agent rattaché porte le lien vers son nœud de mission" "$(cat "$WORK/arbre.html")" 'href="project.html#r=f%3A.planning%2Fmissions%2Fm1.dag.json%23revue-p3"'
assert_eq "EUI.5 — agentsDuNoeud : le lien vers la carte de w1 pour le nœud rattaché, une chaîne vide pour un nœud sans agent" "$(G "$WORK/vm-noeud.json" 'j.erreur||(String(j.retour.a).includes("equipe.html#r=n%3Aag-w1")+"|"+JSON.stringify(j.retour.b))')" 'true|""'
assert_eq "EUI.6 — pied(a-bash) dit « actif » et « lance une commande »" "$(G "$WORK/vm-pied.json" 'j.erreur||(String(j.retour).includes("actif")+"|"+String(j.retour).includes("lance une commande"))')" "true|true"
assert_eq "EUI.7 — chaque session et sous-agent en cours de l'arbre (4) porte un bouton data-vf-doing ; le terminé (fin2h) n'en porte pas (P71.5-D-24 : le bouton reste dans la ligne d'agent, il n'a plus d'objet sur un agent fini)" "$(grep -o 'data-vf-doing=' "$WORK/arbre.html" | wc -l | tr -d ' ')|$(grep -c 'data-vf-doing="fin2h"' "$WORK/arbre.html" | tr -d ' ')" "4|0"

echo "=== E29 — correction d'audit : champs libres, forme typée, taille des meta.json (F2, F3, F4 ; P69-D-23) ==="
cat > "$AUX/spec-e29.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"ok1","spawnDepth":2,"parent":"mgr1","ageS":3},
 {"id":"a-obj","spawnDepth":2,"parent":"mgr1","ageS":3},
 {"id":"a-cwd","spawnDepth":2,"parent":"mgr1","ageS":3},
 {"id":"a-gros","spawnDepth":2,"parent":"mgr1","ageS":3}]}
JSON
H29="$(mkhome e29 "$AUX/spec-e29.json" "$LAB")"
cat > "$AUX/abime-e29.mjs" <<'JS'
// abime-e29.mjs <home> : description et agentType non chaînes, horodatage de 9 Ko, cwd objet, meta de 512 Kio, candidat au nom de fichier piégé, session au cwd numérique
import fs from 'node:fs';
import path from 'node:path';
const home = process.argv[2]; const dir = path.join(home, '.claude', 'projects', '-lab');
const sid = fs.readdirSync(dir).find((f) => f.endsWith('.jsonl')).slice(0, -6); const sub = path.join(dir, sid, 'subagents');
const meta = (id, f) => { const p = path.join(sub, `agent-${id}.meta.json`); const m = JSON.parse(fs.readFileSync(p, 'utf8')); f(m); fs.writeFileSync(p, JSON.stringify(m)); };
meta('a-obj', (m) => { m.description = { x: 'OBJET-69' }; m.agentType = ['TABLEAU-69']; });
meta('a-gros', (m) => { m.description = 'z'.repeat(512 * 1024); });
const dernier = (f, g) => { const L = fs.readFileSync(f, 'utf8').trim().split('\n'); const o = JSON.parse(L[L.length - 1]); g(o); L[L.length - 1] = JSON.stringify(o); const st = fs.statSync(f); fs.writeFileSync(f, L.join('\n') + '\n'); fs.utimesSync(f, st.atimeMs / 1000, st.mtimeMs / 1000); };
dernier(path.join(sub, 'agent-a-cwd.jsonl'), (o) => { o.cwd = { a: 'CWD-OBJET-69' }; });
dernier(path.join(dir, sid + '.jsonl'), (o) => { o.timestamp = 'T' + '9'.repeat(9000); });
const piege = '<img src=x onerror=alert(1)>';
fs.copyFileSync(path.join(sub, 'agent-ok1.meta.json'), path.join(sub, `agent-${piege}.meta.json`)); fs.writeFileSync(path.join(sub, `agent-${piege}.jsonl`), fs.readFileSync(path.join(sub, 'agent-ok1.jsonl'), 'utf8').split('"agentId":"ok1"').join('"agentId":' + JSON.stringify(piege))); // la première ligne porte l'identifiant piégé : seul ID_RE l'exclut
const d2 = path.join(home, '.claude', 'projects', '-lab2'); fs.mkdirSync(d2, { recursive: true });
const ligne = JSON.parse(fs.readFileSync(path.join(dir, sid + '.jsonl'), 'utf8').trim().split('\n')[0]); ligne.cwd = 42; ligne.sessionId = 'sess-cwd-num';
fs.writeFileSync(path.join(d2, 'sess-cwd-num.jsonl'), JSON.stringify(ligne) + '\n');
JS
node "$AUX/abime-e29.mjs" "$H29"
Q who "$LAB" "$H29" "$NOSCRIPTS" "$NOW" > "$WORK/who-e29.json" 2> "$WORK/who-e29.err"
assert_eq "E29.0 — contrôle positif : la collecte aboutit (JSON) et liste ok1, a-obj, a-cwd ... avec leur état" "$(G "$WORK/who-e29.json" 'j.workers?j.workers.filter(x=>x.kind==="subagent"&&["ok1","a-obj"].includes(x.id)).length:"pas de collecte"')" "2"
assert_eq "E29.1 (F2) — aucune description ni agentType objet ou tableau en sortie, a-obj reste listé" "$(grep -cE 'OBJET-69|TABLEAU-69' "$WORK/who-e29.json")|$(sf "$WORK/who-e29.json" a-obj 'w.etat')" "0|actif"
assert_eq "E29.2 (F2) — tout champ libre est une chaîne bornée ou absent (task <= 160, role <= 80, lastAt <= 40)" "$(G "$WORK/who-e29.json" 'j.workers?(j.workers.every(w=>[["task",160],["role",80],["lastAt",40],["cwd",200],["branch",200]].every(([k,n])=>w[k]===undefined||(typeof w[k]==="string"&&w[k].length<=n)))?"ok":"champ libre non borné"):"pas de collecte"')" "ok"
assert_eq "E29.3 (F2) — aucun identifiant ne sort hors de ID_RE, le candidat au nom de fichier piégé est exclu et la source passe en forme-inconnue" "$(grep -c 'onerror' "$WORK/who-e29.json")|$(G "$WORK/who-e29.json" 'j.workers?(j.workers.filter(w=>["session","subagent","registered"].includes(w.kind)).every(w=>/^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/.test(w.id))?"ok":"id hors ID_RE")+"|"+j.sources.sessions.etat:"pas de collecte"')" "0|ok|forme-inconnue"
assert_eq "E29.4 (F3) — un cwd objet (sous-agent) ou numérique (session) ne fait pas lever la collecte : ok1 reste listé, a-cwd est exclu, une erreur de forme est comptée" "$(cat "$WORK/who-e29.err" | grep -c 'startsWith')|$(sf "$WORK/who-e29.json" ok1 w.etat)|$(sf "$WORK/who-e29.json" a-cwd w.etat)|$(G "$WORK/who-e29.json" 'j.sources?String(j.sources.sessions.formeInconnue>=2):"x"')" "0|actif|absent|true"
assert_eq "E29.5 (F4) — un meta.json de 512 Kio (au-delà de la borne) met l'agent en forme-inconnue : a-gros absent, ok1 présent" "$(sf "$WORK/who-e29.json" a-gros w.etat)|$(sf "$WORK/who-e29.json" ok1 w.etat)" "absent|actif"
cat > "$AUX/rv-e29.mjs" <<'JS'
// rv-e29.mjs <scripts> <root> <home> <id>... : revealTranscript pour chaque identifiant ; une ligne par identifiant, « exception » si elle remonte
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, root, home, ...ids] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-who.mjs')).href);
for (const id of ids) { try { const r = m.revealTranscript(root, id, { home, scriptsDir: '/nonexistent' }); console.log(id + '|' + r.schema + '|' + (r.erreur || 'rendu')); } catch (e) { console.log(id + '|exception|' + e.message); } }
JS
assert_eq "E29.6 (F3) — revealTranscript ne lève jamais : agent sain rendu, agent à cwd objet et identifiant inconnu sans exception" "$(node "$AUX/rv-e29.mjs" "$SCRIPTS" "$LAB" "$H29" ok1 a-cwd absent-xyz | tr '\n' ' ')" "ok1|vibeflow/cockpit-transcript@1|rendu a-cwd|vibeflow/cockpit-transcript@1|inconnu absent-xyz|vibeflow/cockpit-transcript@1|inconnu "

echo "=== EUI2 — correction de revue : rechargement, arrivée sur une carte, échappement, badge, lien jamais deviné (P69-D-14, D-15 ; F1, F2, F4, F5) ==="
cat > "$AUX/jq.mjs" <<'JS'
// jq.mjs <expression sur j> : lit un JSON sur l'entrée standard, écrit la valeur de l'expression
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(0, 'utf8'));
const v = new Function('j', 'return (' + process.argv[2] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/vm72.mjs" <<'JS'
// vm72.mjs <72-vf-equipe.js> <71-vf-equipe-rendu.js> <scénario> : exécute l'onglet Équipe hors navigateur (vm), viewer factice. Le premier rendu du viewer n'aboutit jamais
// (`ready` non émis : le cas d'un rerender() lancé pendant le premier rendu) sauf pour le scénario arrivee-ready. Sortie : une ligne JSON.
import fs from 'node:fs';
import vm from 'node:vm';
const [, , f72, f71, sc] = process.argv;
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
let now = 1000000; const timers = []; const store = new Map(); const dom = {}; const hand = {}; const sections = [];
const out = { reloads: 0, rerenders: 0, reveals: [] };
const S = { kind: 'session', id: 'S', etat: 'actif', tree: '.' };
const A = { kind: 'subagent', id: 'A', etat: 'actif', parent: 'S', role: 'vf-dev-manager', tree: '.' };
const F = { kind: 'subagent', id: 'F', etat: 'termine', parent: 'A', tree: '.' };
const n = (id, st, parent) => ({ id, st, parent });
let who = { workers: [S, A, F] };
let nodes = [n('se-S', 'active', null), n('ag-A', 'active', 'se-S'), n('ag-A~termines', 'done', 'ag-A'), n('ag-F', 'done', 'ag-A~termines')];
let hash = '';
if (sc === 'nouveau' || sc === 'borne') nodes = [n('se-S', 'active', null)];
if (sc === 'compte') who = { workers: [{ kind: 'subagent', id: 'a', etat: 'actif', tree: '.' }, { kind: 'subagent', id: 'f', etat: 'termine', tree: '.', parent: 'a' }, { kind: 'subagent', id: 'w', etat: 'en-attente', tree: '.' }, { kind: 'lock', id: 'v', tree: '.' }, { kind: 'dag-node', id: 'd', tree: '.', etat: 'actif' }, { kind: 'registered', id: 'r', tree: '.' }] }; // la collecte de vm70.mjs
if (sc === 'compte') nodes = [n('ag-a', 'active', null), n('ag-a~termines', 'done', 'ag-a'), n('ag-f', 'done', 'ag-a~termines'), n('ag-w', 'active', null)];
if (sc === 'passe') nodes = [n('se-S', 'active', null), n('ag-A', 'active', 'se-S'), n('ag-F', 'active', 'ag-A')]; // F était actif : il passe terminé sans que les cartes aient changé
if (sc === 'arrivee' || sc === 'arrivee-ready') hash = '#r=' + encodeURIComponent('n:ag-A');
if (sc === 'piege2') who = { workers: [{ kind: 'subagent', id: 'r1', etat: 'actif', tree: '.', rattachement: { etat: 'rattache', source: 'registre', dag: '<x-dag>', noeud: '<x-noeud>' } }] };
if (sc === 'piege') who = { workers: [{ kind: 'subagent', id: 'i"><x-id>', etat: 'actif', role: '<x-role>', branch: '<x-branch>', tree: '.', action: { verbe: 'lit', cible: '<x-cible>' }, rattachement: { etat: 'non-rattache', raison: '<x-raison>', dag: 'D', noeud: 'N' } }] };
const SC = { graph: { meta: { vfTab: 'equipe', vf: {} }, nodes, project: { name: 'p' } }, h, setOverview() {}, addPanelSection: (w, fn) => sections.push(fn),
  on: (e, fn) => { (hand[e] ||= []).push(fn); }, rerender: async () => { out.rerenders++; }, exists: (id) => nodes.some((x) => 'n:' + x.id === id), reveal: (id) => out.reveals.push(id) };
const window = { Floorplan: SC, FLOORPLAN_SERVER: { token: 't' }, __vfLive: { who }, addEventListener() {} };
const document = { addEventListener: (e, f) => { (dom[e] ||= []).push(f); }, querySelector: () => null, querySelectorAll: () => [], getElementById: () => null, documentElement: {} };
const location = { hash, reload: () => { out.reloads++; } };
const sessionStorage = { getItem: (k) => (store.has(k) ? store.get(k) : null), setItem: (k, v) => { store.set(k, String(v)); } };
const ctx = vm.createContext({ window, document, location, sessionStorage, URLSearchParams, MutationObserver: class { observe() {} }, encodeURIComponent, Date: { now: () => now }, setTimeout: (fn, ms) => { timers.push({ fn, at: now + ms }); return timers.length; }, fetch: async () => null, console });
const lancer = async () => { await Promise.all((dom['vf-who'] || []).map((f) => f())); };
try {
  vm.runInContext(fs.readFileSync(f71, 'utf8'), ctx, { timeout: 5000 });
  vm.runInContext(fs.readFileSync(f72, 'utf8'), ctx, { timeout: 5000 });
  if (sc === 'borne' || sc === 'passe') {
    await lancer(); out.r1 = out.reloads;
    now += 1000; await lancer(); out.r2 = out.reloads;
    now += 16000; for (const t of timers.splice(0)) if (t.at <= now) await t.fn(); out.r3 = out.reloads;
  } else if (sc === 'compte') {
    await lancer(); out.compte = SC.graph.meta.vf.compte;
  } else if (sc === 'piege' || sc === 'piege2') {
    out.html = sections.map((f) => f('n:ag-' + who.workers[0].id)).join('');
  } else {
    if (sc === 'arrivee-ready') for (const f of hand.ready || []) f();
    await lancer();
  }
  console.log(JSON.stringify(out));
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e.message).slice(0, 160) })); }
JS
cat > "$AUX/vm70.mjs" <<'JS'
// vm70.mjs <70-vf-live.js> <71-vf-equipe-rendu.js> : le tiroir et le badge hors navigateur (vm), un `who` livré par un EventSource factice.
// Sortie : { badge, panneau } (texte du badge, effectif « N actifs » du panneau « Au travail »), ou { erreur }.
import fs from 'node:fs';
import vm from 'node:vm';
const [, , f70, f71] = process.argv;
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
class ES { constructor() { ES.last = this; this.l = {}; } addEventListener(n, f) { this.l[n] = f; } close() {} }
let bouton = null, panneau = '';
const el = () => ({ setAttribute() {}, appendChild() {}, remove() {}, style: {} });
const SC = { graph: { meta: { vfTab: 'equipe' }, nodes: [], files: [] }, h, toast() {}, rerender: async () => {}, addPanelSection() {}, showPanel: (x) => { panneau = x; },
  addHeaderButton: (o) => { bouton = { ...o, className: '', innerHTML: '', setAttribute() {} }; return bouton; } };
const document = { createElement: el, head: { appendChild() {} }, body: { appendChild() {}, classList: { contains: () => false } }, documentElement: {}, addEventListener() {}, dispatchEvent: () => true, getElementById: () => null, querySelectorAll: () => [], querySelector: () => null };
const window = { Floorplan: SC, FLOORPLAN_SERVER: { token: 't' } };
const ctx = vm.createContext({ window, document, MutationObserver: class { observe() {} }, EventSource: ES, CustomEvent: class { constructor(t) { this.type = t; } }, location: { reload() {} }, fetch: async () => ({ ok: false }), setTimeout, clearTimeout, Date, console, encodeURIComponent });
try {
  vm.runInContext(fs.readFileSync(f71, 'utf8'), ctx, { timeout: 5000 });
  vm.runInContext(fs.readFileSync(f70, 'utf8'), ctx, { timeout: 5000 });
  const w = [{ kind: 'subagent', id: 'a', etat: 'actif', tree: '.' }, { kind: 'subagent', id: 'f', etat: 'termine', tree: '.', parent: 'a' }, { kind: 'subagent', id: 'w', etat: 'en-attente', tree: '.' }, { kind: 'lock', id: 'v', tree: '.' }, { kind: 'dag-node', id: 'd', tree: '.', etat: 'actif' }, { kind: 'registered', id: 'r', tree: '.' }]; // un actif, un terminé, un en attente, puis ce qui n'est pas un agent
  ES.last.l.who({ data: JSON.stringify({ seq: 1, who: { workers: w, sources: {} } }) });
  bouton.onClick();
  console.log(JSON.stringify({ badge: bouton.innerHTML.replace(/<[^>]*>/g, ''), panneau: (/class="aw-count"><b>(\d+)<\/b>/.exec(panneau) || [])[1] || 'titre absent' }));
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e.message).slice(0, 160) })); }
JS
cat > "$AUX/juge71.mjs" <<'JS'
// juge71.mjs <71-vf-equipe-rendu.js> : « ok », ou la liste des propriétés violées. Id, rôle, branche, cible d'action, raison et tâche piégés (balises <x-…>) ne sortent
// jamais en balise, dans l'arbre, le pied et la liste d'un nœud ; un agent non rattaché n'a jamais de lien vers un nœud (même avec dag et noeud renseignés).
import fs from 'node:fs';
import vm from 'node:vm';
const ctx = vm.createContext({ window: {}, encodeURIComponent });
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
const ko = [];
try {
  vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), ctx, { timeout: 5000 });
  const R = ctx.window.__vfEquipeRendu;
  const piege = { kind: 'subagent', id: 'i"><x-id>', etat: 'actif', role: '<x-role>', branch: '<x-branch>', task: '<x-tache>', tree: '.', action: { verbe: 'lit', cible: '<x-cible>' }, rattachement: { etat: 'non-rattache', raison: '<x-raison>', dag: 'D', noeud: 'N' } };
  const lieP = { kind: 'subagent', id: 'r1', etat: 'actif', tree: '.', rattachement: { etat: 'rattache', source: 'registre', dag: '<x-dag>', noeud: '<x-noeud>' } };
  const html = R.arbre([piege, lieP], h);
  if (!html.includes('Nœud &lt;x-noeud&gt;')) ko.push('noeud d\'un agent rattaché non échappé ou absent');
  if (html.includes('<x-')) ko.push('balise piégée dans l\'arbre');
  for (const [cle, attendu] of [['id', 'i&quot;&gt;&lt;x-id&gt;'], ['rôle', '&lt;x-role&gt;'], ['branche', 'title="&lt;x-branch&gt;"'], ['cible', '&lt;x-cible&gt;'], ['raison', '&lt;x-raison&gt;']]) if (!html.includes(attendu)) ko.push(cle + ' non échappé(e) ou absent(e) de l\'arbre');
  if (/data-vf-agent="[^"]*<x-/.test(html) || /data-vf-agent="i"/.test(html)) ko.push('attribut data-vf-agent brut');
  if (R.pied(piege) !== 'actif · ' + 'lit <x-cible>') ko.push('pied : texte brut attendu, obtenu ' + R.pied(piege));
  if (R.arbre([piege], h).includes('project.html#r=')) ko.push('lien deviné vers un nœud pour un agent non rattaché');
  if (!R.arbre([piege], h).includes('non rattaché : &lt;x-raison&gt;')) ko.push('« non rattaché » absent');
  const lie = { kind: 'subagent', id: 'k', etat: 'actif', role: '<x-role>', task: '<x-tache>', rattachement: { etat: 'rattache', dag: 'D', noeud: 'N' } };
  const liste = R.agentsDuNoeud([lie, piege], 'f:D#N', h);
  if (liste.includes('<x-')) ko.push('balise piégée dans la liste d\'un nœud');
  if (!liste.includes('&lt;x-role&gt;')) ko.push('liste d\'un nœud : rôle absent');
  if (liste.includes('i&quot;') || liste.includes('n%3Aag-i')) ko.push('liste d\'un nœud : un agent non rattaché y figure');
} catch (e) { ko.push('exécution : ' + String(e.message).slice(0, 100)); }
console.log(ko.length ? ko.join(' ; ') : 'ok');
JS
cat > "$AUX/mutant.sh" <<'SH'
#!/usr/bin/env bash
# mutant.sh <source> <sortie> <motif sed> <remplacement> : copie <source> vers <sortie> avec UNE substitution, et échoue si elle n'a rien changé (un mutant identique à l'original ne prouve rien)
sed -e "s#$3#$4#" "$1" > "$2"; cmp -s "$1" "$2" && { echo "mutant identique à l'original" >&2; exit 1; }; exit 0
SH
MUT="$WORK/mut"; mkdir -p "$MUT"
M() { bash "$AUX/mutant.sh" "$1" "$2" "$3" "$4" || echo "MUTANT VIDE : $3"; }
J71() { node "$AUX/juge71.mjs" "$1"; }
V72() { node "$AUX/vm72.mjs" "$1" "$2" "$3"; }
U72="$UI/72-vf-equipe.js"

# F4, F5b : échappement et lien jamais deviné (rendus de 71), puis chaque mutant doit rougir
assert_eq "EUI2.1 — 71 : id, rôle, branche, cible, raison et tâche piégés sortent échappés ; un agent non rattaché n'a aucun lien de nœud" "$(J71 "$RENDU")" "ok"
M "$RENDU" "$MUT/71-id.js" 'data-vf-agent="${h(w.id)}"' 'data-vf-agent="${w.id}"'
assert_has "EUI2.2 — mutant : data-vf-agent brut -> détecté" "$(J71 "$MUT/71-id.js")" "balise piégée dans l'arbre"
M "$RENDU" "$MUT/71-role.js" '<b>${h(w.role || '"'"'Agent'"'"')}</b>' '<b>${w.role || '"'"'Agent'"'"'}</b>'
assert_has "EUI2.3 — mutant : rôle brut dans bloc() -> détecté" "$(J71 "$MUT/71-role.js")" "balise piégée dans l'arbre"
M "$RENDU" "$MUT/71-pied.js" "' · ' + h(v)" "' · ' + v"
assert_has "EUI2.4 — mutant : verbe et cible bruts dans l'arbre (la cible vient de l'action) -> détecté" "$(J71 "$MUT/71-pied.js")" "balise piégée dans l'arbre"
M "$RENDU" "$MUT/71-branche.js" 'title="${h(court(w))}"' 'title="${court(w)}"'
assert_has "EUI2.5 — mutant : branche brute -> détecté" "$(J71 "$MUT/71-branche.js")" "balise piégée dans l'arbre"
M "$RENDU" "$MUT/71-lien.js" "w.rattachement && w.rattachement.etat === 'rattache' ?" "w.rattachement ?"
assert_has "EUI2.6 — mutant : lien vers un nœud pour tout rattachement (même non établi) -> détecté" "$(J71 "$MUT/71-lien.js")" "lien deviné"
M "$RENDU" "$MUT/71-noeudrole.js" '<span>${h(w.role || '"'"'Agent'"'"')}</span>' '<span>${w.role || '"'"'Agent'"'"'}</span>'
assert_has "EUI2.7 — mutant : rôle brut dans la liste d'un nœud -> détecté" "$(J71 "$MUT/71-noeudrole.js")" "balise piégée dans la liste d'un nœud"
# le panneau de l'onglet Équipe (72) : mêmes propriétés, via le panneau d'un agent piégé
assert_eq "EUI2.8 — panneau d'un agent piégé (72) : aucune balise, le pied et la raison échappés" "$(V72 "$U72" "$RENDU" piege | node "$AUX/jq.mjs" 'j.erreur||(!j.html.includes("<x-")&&j.html.includes("&lt;x-cible&gt;")&&j.html.includes("&lt;x-raison&gt;")&&!j.html.includes("project.html#r=")?"ok":"panneau : "+j.html.slice(0,200))')" "ok"
M "$U72" "$MUT/72-pied.js" 'h(R().pied(w))' 'R().pied(w)'
assert_has "EUI2.9 — mutant : pied brut dans le panneau -> détecté" "$(V72 "$MUT/72-pied.js" "$RENDU" piege | node "$AUX/jq.mjs" 'j.erreur||(j.html.includes("<x-")?"balise dans le panneau":"ok")')" "balise dans le panneau"

# F1 : tant que l'ensemble des agents (états compris) est stable, aucun rechargement, bloc « Terminés » compris ; F1 bis : la borne de 15 s
assert_eq "EUI2.10 — un agent actif et un agent terminé (bloc « Terminés » dans les cartes) : 0 rechargement, 1 rendu" "$(V72 "$U72" "$RENDU" termine | node "$AUX/jq.mjs" 'j.erreur||(j.reloads+"|"+j.rerenders)')" "0|1"
M "$U72" "$MUT/72-signature.js" "&& !x.id.includes('~')" ""
assert_eq "EUI2.11 — mutant : le bloc « Terminés » compte comme un agent -> 1 rechargement, détecté" "$(V72 "$MUT/72-signature.js" "$RENDU" termine | node "$AUX/jq.mjs" 'j.erreur||(j.reloads+"|"+j.rerenders)')" "1|0"
assert_eq "EUI2.12 — borne : un agent nouveau recharge une fois, puis rien avant 15 s, puis une fois de plus à l'échéance" "$(V72 "$U72" "$RENDU" borne | node "$AUX/jq.mjs" 'j.erreur||[j.r1,j.r2,j.r3].join("|")')" "1|1|2"
M "$U72" "$MUT/72-borne.js" 'const PAUSE_MS = 15000' 'const PAUSE_MS = 0'
assert_eq "EUI2.13 — mutant : borne à 0 -> le deuxième événement recharge aussitôt, détecté" "$(V72 "$MUT/72-borne.js" "$RENDU" borne | node "$AUX/jq.mjs" 'j.erreur||[j.r1,j.r2,j.r3].join("|")')" "1|2|2"

# F2 : l'arrivée sur #r=n:<carte> révèle la carte même quand `ready` n'est jamais émis ; une seule fois, et jamais en double quand 00-vibeflow.js l'a traitée à `ready`
assert_eq "EUI2.14 — arrivée sur #r=n:ag-A sans ready : la carte est révélée une fois, après le premier rendu" "$(V72 "$U72" "$RENDU" arrivee | node "$AUX/jq.mjs" 'j.erreur||j.reveals.join(",")')" "n:ag-A"
assert_eq "EUI2.15 — avec ready émis avant (00-vibeflow.js a révélé la carte) : 72 ne la révèle pas une seconde fois" "$(V72 "$U72" "$RENDU" arrivee-ready | node "$AUX/jq.mjs" 'j.erreur||("["+j.reveals.join(",")+"]")')" "[]"
M "$U72" "$MUT/72-arrivee.js" '^    arrivee();$' '    void 0;'
assert_eq "EUI2.16 — mutant : plus de révélation après le rendu -> aucune carte révélée, détecté" "$(V72 "$MUT/72-arrivee.js" "$RENDU" arrivee | node "$AUX/jq.mjs" 'j.erreur||("["+j.reveals.join(",")+"]")')" "[]"

# F5a : le badge et le titre du tiroir ne comptent que les agents actifs (ni terminé, ni en attente)
assert_eq "EUI2.17 — un actif, un terminé, un en attente, un verrou, un nœud de DAG, un enregistrement : badge « 1 au travail » et effectif « 1 actif » du panneau (seuls les agents actifs comptent)" "$(node "$AUX/vm70.mjs" "$UI/70-vf-live.js" "$RENDU" | node "$AUX/jq.mjs" 'j.erreur||(j.badge+"|"+j.panneau)')" "1 au travail|1"
M "$RENDU" "$MUT/71-actif.js" "w.etat !== 'termine' \&\& w.etat !== 'en-attente'" "true"
assert_eq "EUI2.18 — mutant : le terminé et l'agent en attente comptent -> 3, détecté" "$(node "$AUX/vm70.mjs" "$UI/70-vf-live.js" "$MUT/71-actif.js" | node "$AUX/jq.mjs" 'j.erreur||(j.badge+"|"+j.panneau)')" "3 au travail|3"
M "$UI/70-vf-live.js" "$MUT/70-badge.js" "window.__vfEquipeRendu.actif(w)" "!w.stale"
assert_eq "EUI2.18b — mutant : le badge compte aussi verrous, nœuds de DAG et enregistrements (le défaut de la recette) -> 6, détecté" "$(node "$AUX/vm70.mjs" "$MUT/70-badge.js" "$RENDU" | node "$AUX/jq.mjs" 'j.erreur||(j.badge+"|"+j.panneau)')" "6 au travail|6"
assert_eq "EUI2.18c — même collecte : les effectifs « actifs » de l'onglet Équipe valent ceux du badge (1), verrou et nœud de DAG exclus" "$(V72 "$U72" "$RENDU" compte | node "$AUX/jq.mjs" 'j.erreur||(j.compte.actif+"|"+j.compte.enAttente+"|"+j.compte.termine)')" "1|1|1"

# F6 : la liste CONNU de la sonde ne couvre que les mots français affichés par 71 ; un libellé anglais ajouté à une copie de 71 reste vu
mkdir -p "$AUX/sonde"; cp "$RENDU" "$AUX/sonde/71-vf-equipe-rendu.js"
assert_eq "EUI2.19a — contrôle positif : 71 tel quel n'a rien de nouveau pour la sonde" "$(node "$AUX/sonde-fr.mjs" "$SCRIPTS" "$AUX/sonde/71-vf-equipe-rendu.js")" "aucune"
printf "\nconst libelleTemoin = 'Show the transcript now';\n" >> "$AUX/sonde/71-vf-equipe-rendu.js"
assert_has "EUI2.19 — témoin : la sonde voit un libellé anglais ajouté à une copie de 71" "$(node "$AUX/sonde-fr.mjs" "$SCRIPTS" "$AUX/sonde/71-vf-equipe-rendu.js")" "Show the transcript now"

echo "=== E30 — revue fraîche : tubes, champs imbriqués, nombres, coupe avant masque (points 2, 3, 5, 7) ==="
cat > "$AUX/borne.mjs" <<'JS'
// borne.mjs <ms> <commande node et arguments...> : exécute un enfant node borné par une limite de temps (SIGKILL, sans tube) ; une ligne JSON { timedOut, status, out }
import { spawnSync } from 'node:child_process';
const [, , ms, ...args] = process.argv;
const r = spawnSync(process.execPath, args, { timeout: Number(ms), killSignal: 'SIGKILL', encoding: 'utf8', maxBuffer: 64 << 20 });
console.log(JSON.stringify({ timedOut: r.error?.code === 'ETIMEDOUT', status: r.status, out: r.stdout || '' }));
JS
cat > "$AUX/spec-e30.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"ok1","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"Nœud `revue-p3` — fais la revue"},
 {"id":"w1","spawnDepth":2,"parent":"mgr1","ageS":3,"mandat":"Exécute."}]}
JSON
H30="$(mkhome e30 "$AUX/spec-e30.json" "$LAB21" )"
SUB30="$H30/.claude/projects/-lab/$SID/subagents"; DIR30="$H30/.claude/projects/-lab"
cp "$SUB30/agent-ok1.meta.json" "$SUB30/agent-fifoB.meta.json"
cp "$SUB30/agent-ok1.jsonl" "$SUB30/agent-fifoA.jsonl" # le tube meta.json est candidat : son transcript voisin est récent
mkfifo "$SUB30/agent-fifoA.meta.json" "$SUB30/agent-fifoB.jsonl" "$DIR30/fifoS.jsonl"
node "$AUX/borne.mjs" 8000 "$AUX/q.mjs" "$SCRIPTS" who "$LAB21" "$H30" "$NOSCRIPTS" "$NOW" > "$WORK/fifo-who.json"
rm -f "$SUB30/agent-fifoA.meta.json" "$SUB30/agent-fifoB.jsonl" "$DIR30/fifoS.jsonl"
assert_eq "E30.0 — contrôle positif : sans tube, la collecte de la même fixture aboutit et liste ok1 (enfant borné)" "$(node "$AUX/borne.mjs" 8000 "$AUX/q.mjs" "$SCRIPTS" who "$LAB21" "$H30" "$NOSCRIPTS" "$NOW" | node "$AUX/jq.mjs" '(j.timedOut?"bloqué":"rendu")+"|"+(()=>{try{return JSON.parse(j.out).workers.filter(w=>w.id==="ok1").map(w=>w.etat).join()}catch{return "illisible"}})()')" "rendu|actif"
assert_eq "E30.1 (points 4, 5) — trois tubes (meta.json, transcript de sous-agent, session) ne bloquent pas la collecte (enfant borné à 8 s) et ok1 reste listé" "$(G "$WORK/fifo-who.json" '(j.timedOut?"bloqué":"rendu")+"|"+(()=>{try{return JSON.parse(j.out).workers.filter(w=>w.id==="ok1").map(w=>w.etat).join()}catch{return "illisible"}})()')" "rendu|actif"
# point 3 : rattachement.noeud / dag venus d'un identifiant de nœud de 3 000 caractères ; point 7 : nombres et chaînes du registre qui ne sont pas ce qu'ils doivent être
LAB30="$WORK/lab30"; mkdir -p "$LAB30/.planning/missions"; git -C "$LAB30" init -q
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB30/.planning/ROADMAP.md"
LONG30="$(printf 'N%.0s' $(seq 1 3000))"
printf '{"nodes":[{"id":"%s","step":"x","stage":"s","deps":[],"scope":[],"status":"ready"},{"id":"run1","step":"%s ghp_abcdefghijklmnopqrstuvwxyz0123456789 fin","stage":"s","deps":[],"scope":[],"status":"running"},{"id":"n-ghp_abcdefghijklmnopqrstuvwxyz0123456789","step":"y","stage":"s","deps":[],"scope":[],"status":"ready"}]}\n' "$LONG30" "$(printf 'x%.0s' $(seq 1 90))" > "$LAB30/.planning/missions/m30.dag.json"
cat > "$AUX/orphans-e30.json" <<JSON
{"orphans":[
 {"agent_id":"w1","role":"vf-coder","node":"$LONG30","parent":"mgr1","depth":2,"age_seconds":3,"status":"running"},
 {"agent_id":"ok1","role":"vf-coder","node":"n-ghp_abcdefghijklmnopqrstuvwxyz0123456789","parent":"mgr1","depth":2,"age_seconds":3,"status":"running"},
 {"agent_id":"reg1","role":"vf-coder","node":{"o":"OBJET-NOEUD-69"},"parent":"mgr1","depth":"profond","age_seconds":{"o":"OBJET-AGE-69"},"status":"running"}]}
JSON
H30B="$(mkhome e30b "$AUX/spec-e30.json" "$LAB30" "$AUX/orphans-e30.json")"
Q who "$LAB30" "$H30B" "$NOSCRIPTS" "$NOW" > "$WORK/who-e30.json"
assert_eq "E30.2 — contrôle positif : w1 est rattaché par le registre au nœud de 3 000 caractères" "$(sf "$WORK/who-e30.json" w1 'w.rattachement.etat+"|"+w.rattachement.source')" "rattache|registre"
assert_eq "E30.3 (point 3) — rattachement.noeud <= 128 et rattachement.dag <= 200 caractères" "$(sf "$WORK/who-e30.json" w1 '(w.rattachement.noeud.length<=128&&w.rattachement.dag.length<=200)?"ok":"noeud="+w.rattachement.noeud.length+" dag="+w.rattachement.dag.length')" "ok"
assert_eq "E30.4 (point 7) — une entrée de registre à nœud objet, profondeur chaîne et âge objet : listée sans ces valeurs" "$(G "$WORK/who-e30.json" '(w=>w?(JSON.stringify(w).includes("OBJET-")||typeof w.depth==="string"?"valeur conservée":"ok"):"absente")(j.workers.find(x=>x.id==="reg1"))')" "ok"
assert_eq "E30.5 (point 2) — l'étape d'un nœud running (jeton à cheval sur 100 caractères) : task sans fragment ghp_ (masque avant la coupe)" "$(G "$WORK/who-e30.json" '(w=>w?(w.task.includes("ghp")?"fragment":(w.task.length>0?"ok":"vide")):"absent")(j.workers.find(x=>x.kind==="dag-node"&&x.id==="run1"))')" "ok"

# points 1 à 3 de la dernière passe : un agent qui passe terminé recharge (borne de 15 s), noeud et dag piégés, libellés exacts
cat > "$AUX/libelles71.mjs" <<'JS'
// libelles71.mjs <71-vf-equipe-rendu.js> : « ok », ou les libellés qui diffèrent de ce que l'interface doit afficher
import fs from 'node:fs';
import vm from 'node:vm';
const ctx = vm.createContext({ window: {}, encodeURIComponent });
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const ko = [];
try {
  vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), ctx, { timeout: 5000 });
  const R = ctx.window.__vfEquipeRendu;
  const S = { kind: 'session', id: 'S', etat: 'actif', tree: '.' }, A = { kind: 'subagent', id: 'A', etat: 'en-attente', parent: 'S', tree: '.' }, F = { kind: 'subagent', id: 'F', etat: 'termine', parent: 'S', tree: '.' };
  const html = R.arbre([S, A, F], h);
  for (const [nom, attendu] of [['titre session', 'Session principale'], ['rôle sous-agent', '<b>Agent</b>'], ['mot lu « en attente »', '(en attente'], ['mot visible « en attente »', ' · en attente'], ['mot lu « terminé »', '(terminé)'], ['titre du bloc des terminés', 'Terminés depuis moins de 24 h (1)']]) if (!html.includes(attendu)) ko.push(nom);
  if (!R.pied(A).startsWith('en attente')) ko.push('pied en attente : ' + R.pied(A));
  if (!R.pied(F).startsWith('terminé')) ko.push('pied terminé : ' + R.pied(F));
  if (!R.pied(S).startsWith('actif')) ko.push('pied actif : ' + R.pied(S));
} catch (e) { ko.push('exécution : ' + String(e.message).slice(0, 100)); }
console.log(ko.length ? ko.join(' ; ') : 'ok');
JS
assert_eq "EUI2.20 — libellés exacts : Session principale, rôle, « en attente » (lu et visible), « terminé », bloc « Terminés depuis moins de 24 h (1) »" "$(node "$AUX/libelles71.mjs" "$RENDU")" "ok"
M "$RENDU" "$MUT/71-attente.js" "'en attente'" "'en-attente'"
assert_has "EUI2.21 — mutant : « en attente » devient « en-attente » -> détecté" "$(node "$AUX/libelles71.mjs" "$MUT/71-attente.js")" "pied en attente"
M "$RENDU" "$MUT/71-noeud.js" 'Nœud ${h(w.rattachement.noeud)}' 'Nœud ${w.rattachement.noeud}'
assert_has "EUI2.22 — mutant : noeud brut dans l'arbre -> détecté" "$(J71 "$MUT/71-noeud.js")" "balise piégée dans l'arbre"
assert_eq "EUI2.23 — panneau d'un agent rattaché à un nœud et un DAG piégés : aucune balise, noeud échappé" "$(V72 "$U72" "$RENDU" piege2 | node "$AUX/jq.mjs" 'j.erreur||(!j.html.includes("<x-")&&j.html.includes("&lt;x-noeud&gt;")?"ok":"panneau : "+j.html.slice(0,200))')" "ok"
assert_has "EUI2.24 — mutant : noeud brut dans le panneau (71 muté) -> détecté" "$(V72 "$U72" "$MUT/71-noeud.js" piege2 | node "$AUX/jq.mjs" 'j.erreur||(j.html.includes("<x-")?"balise dans le panneau":"ok")')" "balise dans le panneau"
assert_eq "EUI2.25 — un agent passe d'actif à terminé (cartes inchangées) : 1 rechargement, puis aucun avant 15 s" "$(V72 "$U72" "$RENDU" passe | node "$AUX/jq.mjs" 'j.erreur||[j.r1,j.r2].join("|")')" "1|1"
M "$U72" "$MUT/72-fini.js" "\${id}\${fini ? '~' : ''}" '${id}'
assert_eq "EUI2.26 — mutant : l'appartenance aux terminés sort de la signature -> aucun rechargement, détecté" "$(V72 "$MUT/72-fini.js" "$RENDU" passe | node "$AUX/jq.mjs" 'j.erreur||[j.r1,j.r2].join("|")')" "0|0"

assert_eq "E30.6 (point 5) — contrôle positif : ok1 est rattaché par le registre à un nœud dont l'identifiant porte un jeton" "$(sf "$WORK/who-e30.json" ok1 'w.rattachement.etat+"|"+w.rattachement.source')" "rattache|registre"
assert_eq "E30.7 (point 5) — le jeton du nœud rattaché ne sort pas en clair (rattachement.noeud masqué)" "$(G "$WORK/who-e30.json" '(w=>w?(JSON.stringify(w).includes("ghp_")?"jeton en clair":(JSON.stringify(w).includes("[masqué]")?"ok":"rien de masqué")):"absent")(j.workers.find(x=>x.id==="ok1"))')" "ok"
MSRC="$WORK/mutwho"; mkdir -p "$MSRC"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$MSRC/"
M "$SCRIPTS/vf-cockpit-who.mjs" "$MSRC/vf-cockpit-who.mjs" 'r\[k\] = bornes(o\[k\], n)' 'r[k] = o[k].slice(0, n)'
Q_MUT() { node "$AUX/q.mjs" "$MSRC" who "$LAB30" "$H30B" "$NOSCRIPTS" "$NOW"; }
assert_eq "E30.8 — mutant : champs imbriqués seulement coupés, jamais masqués -> le jeton sort en clair, détecté" "$(Q_MUT | node "$AUX/jq.mjs" '(w=>w?(JSON.stringify(w).includes("ghp_")?"jeton en clair":"ok"):"absent")(j.workers.find(x=>x.id==="ok1"))')" "jeton en clair"
# point 6 : un *.dag.json qui est un tube ou un lien vers /dev/zero ne bloque ni ne remplit la mémoire
LAB31="$WORK/lab31"; mkdir -p "$LAB31/.planning/missions"; git -C "$LAB31" init -q
printf -- '- [ ] **Phase 1: Socle** - premier jet\n' > "$LAB31/.planning/ROADMAP.md"
printf '{"nodes":[{"id":"okrun","step":"visible","stage":"s","deps":[],"scope":[],"status":"running"}]}\n' > "$LAB31/.planning/missions/ok.dag.json"
H31="$(mkhome e31 "$AUX/spec-e30.json" "$LAB31")"
QB() { node "$AUX/borne.mjs" 6000 "$AUX/q.mjs" "$1" who "$LAB31" "$H31" "$NOSCRIPTS" "$NOW" | node "$AUX/jq.mjs" '(j.timedOut?"bloqué":"rendu")+"|"+(()=>{try{return JSON.parse(j.out).workers.filter(w=>w.id==="okrun").length}catch{return "illisible"}})()'; }
assert_eq "E31.0 — contrôle positif : sans fichier spécial, le nœud running d'un DAG est listé (enfant borné)" "$(QB "$SCRIPTS")" "rendu|1"
MSRC31="$WORK/mutplan"; mkdir -p "$MSRC31"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$MSRC31/"
M "$SCRIPTS/vf-cockpit-planning.mjs" "$MSRC31/vf-cockpit-planning.mjs" "return st.isFile() && st.size <= MAX_LECTURE ? fs.readFileSync(f, 'utf8') : '';" "return fs.readFileSync(f, 'utf8');"
mkfifo "$LAB31/.planning/missions/a.dag.json"; ln -s /dev/zero "$LAB31/.planning/missions/b.dag.json"
RES31="$(QB "$SCRIPTS")"; MUT31="$(QB "$MSRC31")"
rm -f "$LAB31/.planning/missions/a.dag.json" "$LAB31/.planning/missions/b.dag.json"
assert_eq "E31.1 — un *.dag.json en tube et un lien vers /dev/zero ne bloquent pas la collecte et le DAG régulier reste lu" "$RES31" "rendu|1"
assert_eq "E31.2 — mutant : lecture sans contrôle du type de fichier -> la collecte est bloquée (tuée par SIGKILL), détecté" "$MUT31" "bloqué|illisible"

# ---------- EK — clavier et témoins mineurs de l'onglet Équipe, dans un vrai Chromium (UIFN-12, UIFN-13 ; Phase 70, plan 70-11) ----------
# Un vrai navigateur (socle chrome-session.mjs, son propre Chromium headless), le vrai serveur de la SORTIE assemblée, un HOME jetable. Les mutants de
# comportement sont posés dans la page RÉELLEMENT servie (la copie assemblée project.html de la sortie, que le serveur lit à son démarrage) : un mutant sur
# une copie que personne ne sert ne prouverait rien. Le serveur est relancé à chaque mutant, la sortie restaurée ensuite.
echo "=== EK — clavier et témoins mineurs de l'onglet Équipe (UIFN-12, UIFN-13) ==="
EKCHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then EKCHROME="$c"; break; fi; done
if [ -z "$EKCHROME" ]; then
  echo "  ⊘ EK SAUTÉ : aucun navigateur — non compté comme réussi, et non vérifié"
else
  HERE_EK="$(cd "$(dirname "$0")" && pwd)"
  cat > "$AUX/ek-sub.mjs" <<'JS'
// ek-sub.mjs <fichier> : remplace UNE fois la chaîne EK_FROM par EK_TO (variables d'environnement) ; sort 1 (« ancre absente ») si EK_FROM n'y est pas : un mutant vide ne prouve rien
import fs from 'node:fs';
const f = process.argv[2]; const t = fs.readFileSync(f, 'utf8');
if (!process.env.EK_FROM || !t.includes(process.env.EK_FROM)) { console.log('ancre absente'); process.exit(1); }
if (t.split(process.env.EK_FROM).length > 2) { console.log('ancre ambiguë'); process.exit(1); } // deux occurrences : le mutant pourrait viser le mauvais fichier (faux vert, 70-11)
fs.writeFileSync(f, t.replace(process.env.EK_FROM, () => process.env.EK_TO)); console.log('muté');
JS
  LABEK="$WORK/lab-ek"; mkdir -p "$LABEK/src" "$LABEK/.planning/phases/01-x"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LABEK/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$LABEK/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LABEK/.planning/phases/01-x/01-01-SUMMARY.md"
  git -C "$LABEK" init -q && git -C "$LABEK" add -A && git -C "$LABEK" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$LABEK" --quiet > "$WORK/build-ek.out" 2>&1 || cat "$WORK/build-ek.out"
  cat > "$AUX/spec-ek.json" <<'JSON'
{"sessionAgeS":5,"agents":[
 {"id":"mgr1","spawnDepth":1,"ageS":5,"role":"vf-dev-manager"},
 {"id":"a1","spawnDepth":2,"parent":"mgr1","ageS":3,"role":"vf-coder"},
 {"id":"a2","spawnDepth":2,"parent":"mgr1","ageS":3,"role":"vf-coder"},
 {"id":"a3","spawnDepth":2,"parent":"mgr1","ageS":3,"role":"general-purpose","dureeS":130,"dernierAppel":{"name":"Agent","input":{"subagent_type":"general-purpose","description":"d","prompt":"p"}}}]}
JSON
  NOW="$(node -e 'console.log(Date.now())')"
  HEK="$(mkhome ek "$AUX/spec-ek.json" "$LABEK")"
  # sept sessions racines en plus : la scène du premier affichage est assez large pour que l'ajustement à tout l'écran la réduise sous 0,75 sur un écran étroit
  for n in 1 2 3 4 5 6 7; do sed "s/$SID/bbbb000$n-2222-3333-4444-555566667777/g" "$HEK/.claude/projects/-lab/$SID.jsonl" > "$HEK/.claude/projects/-lab/bbbb000$n-2222-3333-4444-555566667777.jsonl"; done
  OUTEK="$LABEK/.vibeflow/cockpit"; cp "$OUTEK/project.html" "$WORK/project-ek.html.orig"
  ek_rafraichir() { touch "$HEK/.claude/projects/-lab/$SID/subagents/"agent-*.jsonl "$HEK/.claude/projects/-lab/"*.jsonl; }
  ek_demarrer() { rm -f "$OUTEK/.cache/server.json"; ek_rafraichir
    HOME="$HEK" node "$OUTEK/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve-ek.out" 2>&1 &
    EK_PID=$!; PIDS+=("$EK_PID")
    for _ in $(seq 1 300); do [ -s "$OUTEK/.cache/server.json" ] && break; sleep 0.1; done
    EK_PORT="$(G "$OUTEK/.cache/server.json" 'j.port' 2>/dev/null || echo 0)"; }
  # ek_muter <ancre> <remplacement> : pose le mutant dans la page assemblée (project.html de la sortie), « muté » ou « ancre absente »
  ek_muter() { cp "$WORK/project-ek.html.orig" "$OUTEK/project.html"; if [ -z "${3:-}" ]; then EK_FROM="$1" EK_TO="$2" node "$AUX/ek-sub.mjs" "$OUTEK/project.html"; else EK_FROM="$1" EK_TO="$2" node "$AUX/ek-sub.mjs" "$OUTEK/project.html" >/dev/null || return 1; EK_FROM="$3" EK_TO="$4" node "$AUX/ek-sub.mjs" "$OUTEK/project.html"; fi; }  # $3/$4 : seconde substitution (fusion de la 68 : deux règles de pied de carte)
  ek_restaurer() { cp "$WORK/project-ek.html.orig" "$OUTEK/project.html"; }
  # EKC <action> <page> : une interaction, un Chromium ; la ligne JSON rendue est lue par G
  EKC() { ek_rafraichir; VF_CDP_ECHEANCE_MS=30000 EK_ACTION="$1" node "$HERE_EK/chrome-equipe-clavier.mjs" "$EKCHROME" "http://127.0.0.1:$EK_PORT/$2" 2>/dev/null > "$WORK/ek-$1.json"; }
  EKA1="equipe.html#r=n%3Aag-a1"
  ek_demarrer
  assert_eq "EK0 — contrôle positif : serveur de la sortie démarré, page Équipe servie et fixture à deux agents lisibles" "$([ "$EK_PORT" -gt 0 ] && echo serveur)|$(node "$AUX/fetchp.mjs" "$EK_PORT" /equipe.html "$WORK/ek-equipe.html")" "serveur|200"
  # EK1 (UIFN-12) : Entrée sur « Lire le transcript » ne fait pas perdre le focus clavier
  EKC focus-transcript "$EKA1"
  assert_eq "EK1.0 — témoin : avant l'Entrée, l'élément actif est le bouton « Lire le transcript » de l'agent a1 (la sonde sait lire le focus)" "$(G "$WORK/ek-focus-transcript.json" 'j.erreur||(j.avant.tag+"|"+j.avant.transcript)')" "BUTTON|a1"
  assert_eq "EK1 — après Entrée sur « Lire le transcript », le transcript s'affiche ET l'élément actif reste dans le tiroir, jamais BODY" "$(G "$WORK/ek-focus-transcript.json" 'j.erreur||("lu="+j.lu+" | actif="+(j.apres.tag==="BODY"?"BODY":(j.apres.dansTiroir?"dans le tiroir":"hors du tiroir : "+j.apres.tag)))')" "lu=true | actif=dans le tiroir"
  EKC focus-transcript "equipe.html#r=n%3Aag-mgr1"
  assert_eq "EK1.1 — sur un manager qui porte des agents, Entrée sur « Lire le transcript » lit le transcript, garde le focus et ne fait pas descendre le viewer dans le nœud" "$(G "$WORK/ek-focus-transcript.json" 'j.erreur||("lu="+j.lu+" | actif="+j.apres.tag+" | vue "+(j.hashAvant===j.hashApres?"inchangée":"changée"))')" "lu=true | actif=BUTTON | vue inchangée"
  # EK2 (m1) : changer d'agent efface la clé de rechargement
  EKC changer-agent "$EKA1"
  assert_eq "EK2.1 — changer d'agent efface la clé de rechargement (avant : l'identifiant a1 ; après : aucune)" "$(G "$WORK/ek-changer-agent.json" 'j.erreur||(j.avant+"|"+j.apres)')" "a1|null"
  # EK3 (m10) : le sessionStorage ne garde que l'identifiant de l'agent
  EKC recharger "$EKA1"
  assert_eq "EK3.1 — le sessionStorage ne contient que l'identifiant de l'agent (jamais le texte lu, qui est bien affiché)" "$(G "$WORK/ek-recharger.json" 'j.erreur||(JSON.stringify(j.entrees)+"|"+j.texteLu+"|"+j.fuite)')" '{"vf-equipe-ouvert":"a1"}|true|false'
  # EK4 (m8) : un tiroir fermé n'est pas rouvert par un nouveau who
  EKC ferme-puis-who "project.html#t"
  assert_eq "EK4.1 — le tiroir « Au travail » fermé n'est pas rouvert par un who qui change l'arbre (ouvert, fermé, rouvert)" "$(G "$WORK/ek-ferme-puis-who.json" 'j.erreur||(j.ouvert+"|"+j.ferme+"|"+j.rouvert)')" "true|true|false"
  # EK5 (m5) : la commande demandée est rendue en texte, jamais en HTML
  EKC rendu-commande "$EKA1"
  assert_eq "EK5.1 — une commande qui porte du balisage s'affiche en texte (0 élément créé, aucun #ek-injecte, la source lisible)" "$(G "$WORK/ek-rendu-commande.json" 'j.erreur||(j.elements+"|"+j.injecte+"|"+j.texte.includes("<b id=ek-injecte>"))')" "0|false|true"
  # EK8 (UIFN-12, bouton voisin) : Entrée sur « Voir la dernière commande » du tiroir « Au travail » ne fait pas perdre le focus clavier
  EKC focus-doing-tiroir "project.html#t"
  assert_eq "EK8.0 — témoin : avant l'Entrée, l'élément actif est le bouton « Voir la dernière commande » du tiroir (la sonde sait lire le focus)" "$(G "$WORK/ek-focus-doing-tiroir.json" 'j.erreur||(j.avant.tag+"|"+(j.avant.doing?"doing":"sans id")+"|"+j.avant.dansTiroir)')" "BUTTON|doing|true"
  assert_eq "EK8 — après Entrée sur « Voir la dernière commande » du tiroir, la commande s'affiche ET l'élément actif reste ce bouton, jamais BODY" "$(G "$WORK/ek-focus-doing-tiroir.json" 'j.erreur||("lu="+j.lu+" | actif="+(j.apres.tag==="BODY"?"BODY":(j.apres.doing?"bouton « dernière commande »":"autre : "+j.apres.tag)))')" "lu=true | actif=bouton « dernière commande »"
  # --- recette de la Phase 70 (juge Playwright frais) : focus au redessin, badge du pied long, libellés ---
  EKC focus-puis-who "$EKA1"
  assert_eq "EK8.0 — témoin : le bouton du panneau avait le focus et le événement who l'a bien remplacé (le redessin a eu lieu)" "$(G "$WORK/ek-focus-puis-who.json" 'j.erreur||(j.focalise+"|"+j.remplace)')" "true|true"
  assert_eq "EK8 — après le redessin du panneau par un événement who, le focus est rendu au bouton « Lire le transcript » de même identifiant" "$(G "$WORK/ek-focus-puis-who.json" 'j.erreur||(j.apres.tag==="BODY"?"BODY":(j.apres.estLeBouton&&j.apres.transcript==="a1"?"le bouton":"autre : "+j.apres.tag))')" "le bouton"
  EKC focus-tiroir "project.html#t"
  assert_eq "EK9.0 — témoin : le bouton du tiroir avait le focus et le événement who l'a bien remplacé" "$(G "$WORK/ek-focus-tiroir.json" 'j.erreur||(j.focalise+"|"+j.remplace)')" "true|true"
  assert_eq "EK9 — après le redessin du tiroir « Au travail » par un événement who, le focus est rendu au bouton « Voir la dernière commande » de la même ligne" "$(G "$WORK/ek-focus-tiroir.json" 'j.erreur||(j.apres.tag==="BODY"?"BODY":(j.apres.estLeBouton?"le bouton":"autre : "+j.apres.tag))')" "le bouton"
  EKC badge "$EKA1"
  assert_eq "EK10 — pied long (« actif · … · lance un agent general-purpose ») : le badge d'état reste entièrement dans sa carte à 390, 1024 et 1440 px (marge >= 0)" "$(G "$WORK/ek-badge.json" 'j.erreur||(["390","1024","1440"].map((l)=>typeof j[l]==="number"&&j[l]>=0?"ok":l+"="+j[l]).join(","))')" "ok,ok,ok"
  EKC echelle "equipe.html"
  assert_eq "EK13.0 — témoin : la scène porte au moins une carte à chacun des 7 chargements (5 à 390 px, 2 à 768 px)" "$(G "$WORK/ek-echelle.json" 'j.erreur||(["390","768"].every((l)=>j[l].every((m)=>m.cartes>0))?"cartes":"aucune carte")')" "cartes"
  assert_eq "EK13 — premier affichage, 5 chargements à 390 px et 2 à 768 px : échelle >= 0,75 à chacun, aucun recouvrement entre #context (lien « Plus » compris) et la première carte, carte entièrement visible (x >= 0)" "$(G "$WORK/ek-echelle.json" 'j.erreur||["390","768"].map((l)=>l+" : "+j[l].map((m)=>(m.k>=0.75?"k":"k="+m.k)+(m.aire===0?"":" recouvre "+m.aire+" px²")+(m.gauche>=0?"":" x="+m.gauche)).join(",")).join(" ; ")')" "390 : k,k,k,k,k ; 768 : k,k"
  G "$WORK/ek-echelle.json" '(j.erreur?[]:["390","768"].flatMap((l)=>j[l].map((m,i)=>[l+"#"+i,m]))).filter(([,m])=>m.aire>0||m.k<0.75).map(([n,m])=>"  diag EK13 "+n+" : "+m.diag).join("\n")'
  EKC titre-grandi "equipe.html"
  assert_eq "EK14 — le titre grandit après le cadrage (768 px, corps 40 px sur 9 caractères de large) : aucun recouvrement avec la première carte une fois la page stable, échelle >= 0,75" "$(G "$WORK/ek-titre-grandi.json" 'j.erreur||((j.k>=0.75?"k":"k="+j.k)+" / "+(j.aire===0?"sans recouvrement":"recouvre "+j.aire+" px²"))')" "k / sans recouvrement"
  EKC libelles "equipe.html#t"
  assert_eq "EK11 — le pied du tiroir, qui ne nomme plus qu'une source illisible (PU-G-180), est en français (aucune clé « sessions », « locks », « dags » brute)" "$(G "$WORK/ek-libelles.json" 'j.erreur||(/\b(sessions|locks|dags)\b/.test(j.src)?"anglais : "+j.src:"français")')" "français"
  assert_eq "EK12 — l'infobulle de la recherche de l'onglet Équipe dit la même chose que son libellé" "$(G "$WORK/ek-libelles.json" 'j.erreur||j.titre')" "Chercher un agent ou une session"
  # EK15 (EA3, PU-G-189, PU-G-190) : Échap ferme le tiroir « Au travail » seul, le bouton dit s'il est ouvert et ce qu'il ouvre
  EK15() { EK_FOCUS="$1" EKC echap-tiroir "project.html#t"; mv "$WORK/ek-echap-tiroir.json" "$WORK/ek-echap-$1.json"; }
  EK15 panneau
  assert_eq "EK15.0 — témoin : le bouton « N au travail » porte aria-controls=panel ; aria-expanded vaut false tiroir fermé, true tiroir ouvert (PU-G-190)" "$(G "$WORK/ek-echap-panneau.json" 'j.erreur||[j.ferme0.controls,j.ferme0.expanded,j.ouvert.controls,j.ouvert.expanded].join()')" "panel,false,panel,true"
  assert_eq "EK15.1 — témoin : avant Échap le focus est dans le tiroir et une carte est sélectionnée (la sonde sait lire le focus et la sélection)" "$(G "$WORK/ek-echap-panneau.json" 'j.erreur||[j.place.dansTiroir,j.avant.selection!==null].join()')" "true,true"
  assert_eq "EK15 — Échap, focus dans le tiroir : le tiroir se ferme seul, la sélection et la vue ne bougent pas, le focus revient au bouton « N au travail », aria-expanded repasse à false (PU-G-189)" "$(G "$WORK/ek-echap-panneau.json" 'j.erreur||["ferme="+j.ferme,"selection "+(j.apres.selection===j.avant.selection?"gardée":"perdue ("+j.avant.selection+" -> "+j.apres.selection+")"),"vue "+(j.apres.hash===j.avant.hash?"gardée":"changée"),"focus="+j.apres.actif,"expanded="+j.apres.expanded].join(" | ")')" "ferme=true | selection gardée | vue gardée | focus=vf-lock | expanded=false"
  assert_eq "EK15.9 — Échap, focus dans le tiroir : l'événement ne remonte pas jusqu'au viewer (écouteur de fenêtre muet ; sain : non, mutants EK15.3/4/5 : oui)" "$(G "$WORK/ek-echap-panneau.json" 'j.erreur||"remonté au viewer : "+(j.remonte?"oui":"non")')" "remonté au viewer : non"
  EK15 bouton
  assert_eq "EK15.2 — Échap, focus sur le bouton « N au travail » lui-même : même résultat (PU-G-189)" "$(G "$WORK/ek-echap-bouton.json" 'j.erreur||["ferme="+j.ferme,"selection "+(j.apres.selection===j.avant.selection?"gardée":"perdue"),"vue "+(j.apres.hash===j.avant.hash?"gardée":"changée"),"focus="+j.apres.actif,"expanded="+j.apres.expanded].join(" | ")')" "ferme=true | selection gardée | vue gardée | focus=vf-lock | expanded=false"
  # EK16 (Q12, PU-G-203) : sous 1280 px un seul tiroir latéral (Git à gauche, « Au travail » à droite) ; l'état se lit « G » (Git ouvert) « T » (Au travail ouvert) puis le focus
  EK16() { EK_LARGEUR="$1" EK_ORDRE="$2" EKC un-lateral "project.html#t"; mv "$WORK/ek-un-lateral.json" "$WORK/ek-lat-$1-$2.json"; }
  EK16V='j.erreur||["premier","second","large"].map((k)=>{const e=j.etapes[k];return (e.git?"G":"-")+(e.travail?"T":"-")+":"+e.focus}).join(" ")'
  EK16 1024 git-puis-travail
  assert_eq "EK16.0 — 1024 px, Git puis « Au travail » : Git est replié, le focus va au bouton « N au travail » ; élargi à 1440 px, Git ne se rouvre pas (Q12, PU-G-203)" "$(G "$WORK/ek-lat-1024-git-puis-travail.json" "$EK16V")" "G-:git -T:bouton-travail -T:bouton-travail"
  EK16 1024 travail-puis-git
  assert_eq "EK16.1 — 1024 px, « Au travail » puis Git : « Au travail » est replié, le focus est dans Git ; élargi à 1440 px, « Au travail » ne se rouvre pas" "$(G "$WORK/ek-lat-1024-travail-puis-git.json" "$EK16V")" "-T:BODY G-:git G-:git"
  EK16 1279 travail-puis-git
  assert_eq "EK16.2 — 1279 px (sous 1280) : un seul tiroir latéral" "$(G "$WORK/ek-lat-1279-travail-puis-git.json" 'j.erreur||(j.etapes.second.git?"G":"-")+(j.etapes.second.travail?"T":"-")')" "G-"
  EK16 1280 travail-puis-git
  assert_eq "EK16.3 — 1280 px : les deux tiroirs coexistent" "$(G "$WORK/ek-lat-1280-travail-puis-git.json" 'j.erreur||(j.etapes.second.git?"G":"-")+(j.etapes.second.travail?"T":"-")')" "GT"
  EK16 1440 git-puis-travail
  assert_eq "EK16.4 — 1440 px, Git puis « Au travail » : les deux restent ouverts" "$(G "$WORK/ek-lat-1440-git-puis-travail.json" 'j.erreur||(j.etapes.second.git?"G":"-")+(j.etapes.second.travail?"T":"-")')" "GT"
  vf_hyg_stop "$EK_PID"

  # --- mutants : chacun posé dans la page servie, serveur relancé, le témoin DOIT rougir ---
  ek_mutant() { # $1 nom, $2 action, $3 page, $4 expression sur la sortie, $5 ancre, $6 remplacement -> « muté|<valeur> »
    local m; m="$(ek_muter "$5" "$6" "${7:-}" "${8:-}")"; ek_demarrer; EKC "$2" "$3"; local v; v="$(G "$WORK/ek-$2.json" "$4")"; vf_hyg_stop "$EK_PID"; ek_restaurer; echo "$m|$v"; }
  assert_eq "EK2.2 — mutant (marque(null) retiré de la page servie) : la clé survit au changement d'agent, détecté" "$(ek_mutant m1 changer-agent "$EKA1" 'j.erreur||(j.avant+"|"+j.apres)' 'lu = null; marque(null); return;' 'lu = null; return;')" "muté|a1|a1"
  assert_eq "EK3.2 — mutant (le sessionStorage reçoit aussi le texte lu) : la fuite est détectée" "$(ek_mutant m10 recharger "$EKA1" 'j.erreur||(j.fuite+"|"+j.texteLu)' 'sessionStorage.setItem(CLE_OUVERT, id);' "sessionStorage.setItem(CLE_OUVERT, id + ' ' + lu.noeuds.map((n) => n.textContent).join(' '));")" "muté|true|true"
  assert_eq "EK4.2 — mutant (garde « tiroir fermé » retirée de redessiner) : le who rouvre le tiroir, détecté" "$(ek_mutant m8 ferme-puis-who "project.html#t" 'j.erreur||(j.ouvert+"|"+j.ferme+"|"+j.rouvert)' "if (!document.querySelector('.vf-whop') || document.body.classList.contains('no-panel')) return;" 'if (false) return;')" "muté|true|true|true"
  assert_eq "EK5.2 — mutant (la commande est rendue en HTML) : un élément est créé, détecté" "$(ek_mutant m5 rendu-commande "$EKA1" 'j.erreur||(j.elements+"|"+j.injecte)' "z.textContent !== t) { z.textContent = t; z.hidden = false; }" "!z.dataset.ek) { z.dataset.ek = '1'; z.innerHTML = t; z.hidden = false; }")" "muté|1|true"
  # l'ancre doit être propre à 72-vf-equipe.js : le viewer porte d'autres ev.stopPropagation(), un mutant posé sur l'un d'eux serait un faux vert
  EKANC1="ev.target.closest?.('#panel [data-vf-transcript], #panel [data-vf-doing]')) ev.stopPropagation();"
  assert_eq "EK1.2 — mutant (l'Entrée du bouton n'est plus arrêtée avant le viewer) : le viewer descend dans le nœud du manager (la vue change), détecté" "$(ek_mutant f1 focus-transcript "equipe.html#r=n%3Aag-mgr1"  'j.erreur||("lu="+j.lu+" | actif="+j.apres.tag+" | vue "+(j.hashAvant===j.hashApres?"inchangée":"changée"))' "$EKANC1" "${EKANC1/ev.stopPropagation();/void 0;}")" "muté|lu=true | actif=BUTTON | vue changée"
  assert_eq "EK1.3 — mutant (le bouton focalisé est désactivé pendant la lecture) : le transcript est lu mais le focus tombe sur BODY, détecté" "$(ek_mutant f2 focus-transcript "$EKA1" 'j.erreur||("lu="+j.lu+" | actif="+j.apres.tag)' "b.setAttribute('aria-disabled', 'true'); // jamais \`disabled\` : un bouton désactivé perd le focus clavier (UIFN-12)" 'b.disabled = true;')" "muté|lu=true | actif=BODY"
  assert_eq "EK8.1 — mutant (le bouton focalisé du tiroir est désactivé pendant la lecture) : la commande est lue mais le focus tombe sur BODY, détecté" "$(ek_mutant f3 focus-doing-tiroir "project.html#t" 'j.erreur||("lu="+j.lu+" | actif="+j.apres.tag)' "b.setAttribute('aria-disabled', 'true'); // jamais \`disabled\` : un bouton focalisé désactivé perd le focus clavier (UIFN-12, même défaut" 'b.disabled = true; //')" "muté|lu=true | actif=BODY"
  assert_eq "EK8.2 — mutant (le focus n'est plus rendu après un redessin) : il tombe sur BODY, détecté" "$(ek_mutant r1 focus-puis-who "$EKA1" 'j.erreur||(j.apres.tag)' 'new MutationObserver(() => { rendreFocus(); ' 'new MutationObserver(() => { ')" "muté|BODY"
  assert_eq "EK9.2 — même mutant, tiroir « Au travail » : le focus tombe sur BODY, détecté" "$(ek_mutant r2 focus-tiroir "project.html#t" 'j.erreur||(j.apres.tag)' 'new MutationObserver(() => { rendreFocus(); ' 'new MutationObserver(() => { ')" "muté|BODY"
  assert_eq "EK10.2 — mutant (la règle du pied retirée de la page servie) : le badge sort de sa carte à 1440 px, détecté" "$(ek_mutant r3 badge "$EKA1" 'j.erreur||(j["1440"]<0?"rogné":"dans la carte")' ".foot .meta { min-width: 0; overflow: hidden; text-overflow: ellipsis; } .foot .vst { flex: none; }" '.foot .meta { }' ".foot .meta { white-space: normal; min-width: 0; border-radius: 12px; }" '.foot .meta { }')" "muté|rogné"
  assert_eq "EK11.2 — mutant (les clés de la collecte affichées telles quelles) : « sessions : lue » reparaît, détecté" "$(ek_mutant r4 libelles "equipe.html#t" 'j.erreur||(/\b(sessions|locks|dags)\b/.test(j.src)?"anglais":"français")' '.map(([k]) => SOURCES[k] || k);' '.map(([k]) => k);')" "muté|anglais"
  assert_eq "EK12.2 — mutant (infobulle laissée au viewer) : « Chercher un fichier, une route, un module » reparaît, détecté" "$(ek_mutant r5 libelles "equipe.html#t" 'j.erreur||j.titre' "bouton.setAttribute('aria-label', LIB); bouton.title = LIB;" "bouton.setAttribute('aria-label', LIB);")" "muté|Chercher un fichier, une route, un module"
  assert_eq "EK13.2 — mutant (plafond de 0,75 retiré) : la scène est réduite sous 0,75, détecté" "$(ek_mutant r6 echelle "equipe.html" 'j.erreur||(j["390"].concat(j["768"]).some((m)=>m.k<0.75)?"réduit":"plafonné")' 'if (!actif || !st.t || st.t.k > 0.75) return;' 'return;')" "muté|réduit"
  assert_eq "EK13.3 — mutant (cadrage sous freeArea() au lieu du bas réel de #context) : le titre recouvre la première carte, détecté" "$(ek_mutant r7 echelle "equipe.html" 'j.erreur||(j["390"].concat(j["768"]).some((m)=>m.aire>0)?"recouvre":"libre")' 'const y = Math.max(a.y, bas - haut + 12)' 'const y = a.y')" "muté|recouvre"
  assert_eq "EK14.2 — mutant (le cadrage n'écoute plus la taille du titre) : le titre qui grandit recouvre la première carte, détecté" "$(ek_mutant r8 titre-grandi "equipe.html" 'j.erreur||(j.aire>0?"recouvre":"libre")' 'taille?.observe(ctx);' '')" "muté|recouvre"
  EK15M() { local m; m="$(ek_muter "$2" "$3")"; ek_demarrer; EK_FOCUS="$1" EKC echap-tiroir "project.html#t"; local v; v="$(G "$WORK/ek-echap-tiroir.json" "$4")"; vf_hyg_stop "$EK_PID"; ek_restaurer; echo "$m|$v"; }
  EK15V='j.erreur||(j.ferme?"fermé":"ouvert")+" | "+(j.apres.selection===j.avant.selection?"sélection gardée":"sélection perdue")+" | remonté au viewer : "+(j.remonte?"oui":"non")'
  assert_eq "EK15.3 — mutant (aucun écouteur d'Échap dans le tiroir) : le tiroir reste ouvert et Échap remonte au viewer, détecté (PU-G-175 : le viewer ne désélectionne plus hors du canevas, c'est le tiroir resté ouvert qui trahit le mutant ; trace sain : fermé | sélection gardée | remonté au viewer : non)" "$(EK15M panneau "panneau.addEventListener('keydown', echap);" "" "$EK15V")" "muté|ouvert | sélection gardée | remonté au viewer : oui"
  assert_eq "EK15.4 — mutant (aucun écouteur d'Échap pour le bouton) : focus sur le bouton, le tiroir reste ouvert et Échap remonte au viewer, détecté" "$(EK15M bouton "document.addEventListener('keydown', (e) => { if (e.target === bouton()) echap(e); }, true);" "" "$EK15V")" "muté|ouvert | sélection gardée | remonté au viewer : oui"
  assert_eq "EK15.5 — mutant (l'Échap du tiroir ne s'arrête pas avant le viewer) : le tiroir se ferme MAIS Échap remonte jusqu'au viewer (qui, depuis PU-G-175, ne désélectionne plus hors du canevas : on lit la remontée sur un écouteur de fenêtre), détecté" "$(EK15M panneau "e.stopPropagation(); e.preventDefault(); // le viewer" "e.preventDefault(); // le viewer" "$EK15V")" "muté|fermé | sélection gardée | remonté au viewer : oui"
  assert_eq "EK15.6 — mutant (le focus n'est plus rendu au bouton) : il reste sur le bouton du tiroir (BUTTON) au lieu de revenir sur #vf-lock, détecté" "$(EK15M panneau "bouton()?.focus({ preventScroll: true });" "" 'j.erreur||j.apres.actif')" "muté|BUTTON"
  assert_eq "EK15.7 — mutant (aria-expanded figé à false) : le tiroir ouvert n'est pas dit ouvert, détecté" "$(EK15M panneau "b.setAttribute('aria-controls', 'panel'); b.setAttribute('aria-expanded', String(o));" "b.setAttribute('aria-controls', 'panel'); b.setAttribute('aria-expanded', 'false');" 'j.erreur||j.ouvert.expanded')" "muté|false"
  assert_eq "EK15.8 — mutant (aria-controls retiré) : le bouton ne dit plus ce qu'il ouvre, détecté" "$(EK15M panneau "b.setAttribute('aria-controls', 'panel'); " "" 'j.erreur||String(j.ouvert.controls)')" "muté|null"
  EK16M() { local m; m="$(ek_muter "$3" "$4")"; ek_demarrer; EK_LARGEUR="$1" EK_ORDRE="$2" EKC un-lateral "project.html#t"; local v; v="$(G "$WORK/ek-un-lateral.json" "$EK16V")"; vf_hyg_stop "$EK_PID"; ek_restaurer; echo "$m|$v"; }
  assert_eq "EK16.5 — mutant (la règle Q12 retirée : seuil à 0 px) : à 1024 px les deux tiroirs restent ouverts, détecté" "$(EK16M 1024 git-puis-travail "window.matchMedia('(max-width: 1279px)')" "window.matchMedia('(max-width: 0px)')")" "muté|G-:git GT:git GT:git"
  assert_eq "EK16.6 — mutant (seuil à 1500 px) : à 1440 px le second tiroir replie le premier, détecté" "$(EK16M 1440 git-puis-travail "window.matchMedia('(max-width: 1279px)')" "window.matchMedia('(max-width: 1500px)')")" "muté|G-:git -T:bouton-travail -T:bouton-travail"
  assert_eq "EK16.7 — mutant (le focus n'est plus posé sur le bouton après le repli de Git) : il ne va plus au tiroir qui s'ouvre, détecté" "$(EK16M 1024 git-puis-travail "if (!panneau.contains(document.activeElement)) b.focus({ preventScroll: true });" "")" "muté|G-:git -T:BODY -T:BODY"
  # témoins de la sonde de mutation elle-même
  ek_demarrer; EKC changer-agent "$EKA1"; vf_hyg_stop "$EK_PID"
  assert_eq "EK6 — témoin de la sonde : la sortie restaurée après les mutants redonne le vert (EK2.1 rejoué sur la page remise à l'identique)" "$(G "$WORK/ek-changer-agent.json" 'j.erreur||(j.avant+"|"+j.apres)')|$(cmp -s "$WORK/project-ek.html.orig" "$OUTEK/project.html" && echo identique || echo differe)" "a1|null|identique"
  assert_eq "EK7 — témoin de la sonde : un mutant dont l'ancre n'existe pas est refusé, la page servie reste intacte" "$(ek_muter 'ANCRE-QUI-N-EXISTE-PAS-70-11' 'x')|$(cmp -s "$WORK/project-ek.html.orig" "$OUTEK/project.html" && echo identique || echo differe)" "ancre absente|identique"
fi

echo "=== EA1 — retours du panel (PU-G-134, 163, 164, 165, 167, 171 compatible, 173) ==="
cat > "$AUX/ea1-workers.json" <<'JSON'
{"workers":[{"kind":"session","id":"s1","etat":"actif","ageS":11,"branch":"feat/x","tree":".claude/worktrees/wt1","action":{"verbe":"lance une commande"}},
 {"kind":"session","id":"s2","etat":"en-attente","ageS":7200,"tree":"arbre principal"},
 {"kind":"subagent","id":"a1","etat":"actif","dureeS":2280,"ageS":3,"role":"vf-coder","rattachement":{"etat":"non","raison":"sans-citation"}},
 {"kind":"subagent","id":"a2","etat":"termine","dureeS":60,"rattachement":{"etat":"non","raison":"<x-raison>"}}]}
JSON
cat > "$AUX/ea1-pilote.js" <<'JS'
const R = window.__vfEquipeRendu, W = DONNEES.workers, w = (i) => W.find((x) => x.id === i);
__r = { p1: R.pied(w('s1')), c1: R.piedCarte(w('s1')), c2: R.piedCarte(w('s2')), p3: R.pied(w('a1')), p4: R.pied(w('a2')), st: W.map((x) => String(R.st(x))).join(','), v1: R.versNoeud(w('a1'), h), v2: R.versNoeud(w('a2'), h) };
JS
node "$AUX/vm-rendu.mjs" "$RENDU" "$AUX/ea1-pilote.js" "$AUX/ea1-workers.json" > "$WORK/vm-ea1.json"
assert_eq "EA1.1 — pied : « dernière activité il y a 11 s » (session), « au travail depuis 38 min » (agent), « a duré 60 s » (terminé) (PU-G-173)" "$(G "$WORK/vm-ea1.json" 'j.erreur||[j.retour.p1,j.retour.p3,j.retour.p4].join("|")')" "actif · dernière activité il y a 11 s · lance une commande|actif · au travail depuis 38 min|terminé · a duré 60 s"
assert_eq "EA1.2 — pied de carte : pas de mot d'état quand la pastille le dit, « en attente » gardé sans pastille, action générique tue (PU-G-165)" "$(G "$WORK/vm-ea1.json" 'j.erreur||[j.retour.c1,j.retour.c2].join("|")')" "dernière activité il y a 11 s|en attente · dernière activité il y a 2 h"
assert_eq "EA1.3 — pastille : l'agent en attente n'en porte aucune (jamais « En cours »)" "$(G "$WORK/vm-ea1.json" 'j.erreur||j.retour.st')" "active,undefined,active,done"
assert_eq "EA1.4 — « non rattaché » : « sans-citation » dit en clair, une raison inattendue reste affichée et échappée (PU-G-167)" "$(G "$WORK/vm-ea1.json" 'j.erreur||(j.retour.v1.includes("pas lié à une phase du projet")+"|"+j.retour.v2.includes("non rattaché (&lt;x-raison&gt;)"))')" "true|true"
cat > "$AUX/ea1-carte.mjs" <<'JS'
const { buildEquipeGraph } = await import(process.argv[2]);
const W = JSON.parse((await import('node:fs')).readFileSync(process.argv[3], 'utf8')).workers;
const g = buildEquipeGraph({ workers: W }, { nom: 'x', lancees: new Map([['s1', { phase: '71.5', verbe: 'planifier' }]]) });
const n = (i) => g.nodes.find((x) => x.id === i);
console.log(JSON.stringify({ s1: n('se-s1').summary, s2: n('se-s2').summary, st: ['se-s1', 'se-s2', 'ag-a1', 'ag-a2'].map((i) => String(n(i).st)).join(',') }));
JS
assert_eq "EA1.5 — carte : étiquette de lancement, branche et arbre en description (jamais vide), « en attente » sans état projeté (PU-G-134, 163, 164, 165)" "$(node "$AUX/ea1-carte.mjs" "$SCRIPTS/vf-cockpit-equipe-carte.mjs" "$AUX/ea1-workers.json" 2>&1 | node "$AUX/jq.mjs" 'j.s1+"|"+j.s2+"|"+j.st' 2>&1)" "Depuis Phase 71.5 · Branche feat/x · arbre wt1|arbre principal|active,undefined,active,done"

cat > "$AUX/ea1-vides.mjs" <<'JS'
const { buildEquipeGraph } = await import(process.argv[2]);
const W = [{ kind: 'session', id: 's9', etat: 'actif', ageS: 3, titre: 'Travail', action: { verbe: 'lance une commande' } },
  { kind: 'subagent', id: 'g1', etat: 'termine', parent: 's9', role: 'general-purpose', dureeS: 60 },
  { kind: 'subagent', id: 'g2', etat: 'termine', parent: 's9', dureeS: 5 },
  { kind: 'subagent', id: 'g3', etat: 'actif', parent: 's9', dureeS: 5 }];
const g = buildEquipeGraph({ workers: W }, { nom: 'x' });
console.log(JSON.stringify(g.nodes.map((x) => ({ id: x.id, vide: !String(x.summary || '').trim(), s: x.summary }))));
JS
# PU-G-163 (recette du 2026-11-08) : ni le groupe « Terminés depuis moins de 24 h » ni un agent sans tâche ne portent une description vide (le viewer y met « Pas encore de description »)
assert_eq "EA1.6 — carte : aucune description vide (groupe « Terminés », agent general-purpose sans tâche, session sans tâche) ; le groupe compte ses agents (PU-G-163)" "$(node "$AUX/ea1-vides.mjs" "$SCRIPTS/vf-cockpit-equipe-carte.mjs" 2>&1 | node "$AUX/jq.mjs" 'j.length + "|" + j.filter((x) => x.vide).length + "|" + j.find((x) => x.id.endsWith("~termines")).s + "|" + j.find((x) => x.id === "ag-g3").s' 2>&1)" "5|0|2 agents de cette session, terminés depuis moins de 24 h.|Agent sans tâche annoncée · actif"

echo "=== EA2 — tiroir « Au travail » : orphelins, verrous, libellés (PU-G-177, 178, 179, 180, 182, 184, 186, 187) ==="
cat > "$AUX/vm70s.mjs" <<'JS'
// vm70s.mjs <70-vf-live.js> <71-vf-equipe-rendu.js> <scénario.json> : le tiroir hors navigateur (vm) ; le scénario porte `who` (workers, sources) et, facultatif, `lock` (flux lock brut). Sortie : le HTML du tiroir, ou { erreur }.
import fs from 'node:fs';
import vm from 'node:vm';
const [, , f70, f71, scen] = process.argv;
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
class ES { constructor() { ES.last = this; this.l = {}; } addEventListener(n, f) { this.l[n] = f; } close() {} }
let bouton = null, panneau = '';
const el = () => ({ setAttribute() {}, appendChild() {}, remove() {}, style: {} });
const SC = { graph: { meta: { vfTab: 'equipe' }, nodes: [], files: [] }, h, toast() {}, rerender: async () => {}, addPanelSection() {}, showPanel: (x) => { panneau = x; },
  addHeaderButton: (o) => { bouton = { ...o, className: '', innerHTML: '', setAttribute() {} }; return bouton; } };
const document = { createElement: el, head: { appendChild() {} }, body: { appendChild() {}, classList: { contains: () => false } }, documentElement: {}, addEventListener() {}, dispatchEvent: () => true, getElementById: () => null, querySelectorAll: () => [], querySelector: () => null };
const window = { Floorplan: SC, FLOORPLAN_SERVER: { token: 't' } };
const ctx = vm.createContext({ window, document, MutationObserver: class { observe() {} }, EventSource: ES, CustomEvent: class { constructor(t) { this.type = t; } }, location: { reload() {} }, fetch: async () => ({ ok: false }), setTimeout, clearTimeout, Date, console, encodeURIComponent });
try {
  const S = JSON.parse(fs.readFileSync(scen, 'utf8'));
  vm.runInContext(fs.readFileSync(f71, 'utf8'), ctx, { timeout: 5000 });
  vm.runInContext(fs.readFileSync(f70, 'utf8'), ctx, { timeout: 5000 });
  if (S.lock) ES.last.l.lock({ data: JSON.stringify({ seq: 1, lock: S.lock }) });
  ES.last.l.who({ data: JSON.stringify({ seq: 2, who: S.who }) });
  bouton.onClick();
  console.log(JSON.stringify({ html: panneau }));
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e.message).slice(0, 160) })); }
JS
UUID_OWNER="88f83d8b-65ec-4000-8000-000000000001"
cat > "$AUX/ea2-orph.json" <<'JSON'
{"who":{"sources":{},"workers":[
 {"kind":"registered","id":"ag-orph","role":"vf-coder","task":"TACHE-ORPH","stale":true,"orphan":true,"ageS":600,"tree":"dépôt"},
 {"kind":"dag-node","id":"d1","role":"s","task":"NOEUD-PERIME","stale":true,"ageS":9000,"tree":"x"},
 {"kind":"session","id":"s1","etat":"en-attente","ageS":2400,"tree":".","branch":"main"},
 {"kind":"subagent","id":"a1","etat":"actif","ageS":3,"dureeS":60,"role":"vf-coder","task":"TACHE-ENFANT","parent":"s1","tree":"."}]}}
JSON
sed 's/"ageS":2400/"ageS":600/' "$AUX/ea2-orph.json" > "$AUX/ea2-orph-court.json"
cat > "$AUX/ea2-verrou.json" <<JSON
{"lock":{"present":true,"locks":[{"present":true,"owner":"$UUID_OWNER","step":"exec","scope":"depot","age_seconds":1,"lease_seconds":3000,"session_ids":["sess-presente"]}]},
 "who":{"sources":{"sessions":{"etat":"lue"},"locks":{"etat":"lue"},"dags":{"etat":"lue"}},"workers":[
 {"kind":"lock","id":"$UUID_OWNER","task":"exec","tree":"depot","ageS":1,"stale":false},
 {"kind":"session","id":"sess-presente","etat":"actif","ageS":2,"tree":".","branch":"main"}]}}
JSON
sed 's/"sess-presente"\]/"sess-absente"]/' "$AUX/ea2-verrou.json" > "$AUX/ea2-verrou-absent.json"
sed 's/"sess-presente"\]/]/' "$AUX/ea2-verrou.json" > "$AUX/ea2-verrou-vide.json"
sed 's/"lease_seconds":3000,//' "$AUX/ea2-verrou.json" > "$AUX/ea2-verrou-sanslease.json"
sed 's/"locks":{"etat":"lue"}/"locks":{"etat":"erreur"}/' "$AUX/ea2-verrou.json" > "$AUX/ea2-verrou-illisible.json"
cat > "$AUX/ea2-vide.json" <<'JSON'
{"who":{"sources":{"sessions":{"etat":"lue"},"locks":{"etat":"lue"},"dags":{"etat":"lue"}},"workers":[]}}
JSON
T70() { node "$AUX/vm70s.mjs" "${3:-$UI/70-vf-live.js}" "${4:-$RENDU}" "$AUX/$1" | node "$AUX/jq.mjs" "j.erreur||($2)"; }
assert_eq "EA2.1 — orphelin du registre (PU-G-182) : l'agent consigné sans verrou tenu est montré, « orphelin ? » ; le nœud de DAG périmé reste écarté (P71.5-D-14, apparié)" "$(T70 ea2-orph.json '[j.html.includes("TACHE-ORPH"), j.html.includes("orphelin ?"), j.html.includes("NOEUD-PERIME")].join()')" "true,true,false"
assert_eq "EA2.2 — enfant actif d'une session muette depuis 40 min : « orphelin ? » sur sa ligne (PU-G-182)" "$(T70 ea2-orph.json '/class="r-task">TACHE-ENFANT <span class="sr">\(([^)]*)\)/.exec(j.html)[1].includes("orphelin ?")')" "true"
assert_eq "EA2.2b — apparié : la même session muette depuis 10 min ne marque pas l'enfant, et l'orphelin du registre reste dit une seule fois" "$(T70 ea2-orph-court.json '[/class="r-task">TACHE-ENFANT <span class="sr">\(([^)]*)\)/.exec(j.html)[1].includes("orphelin ?"), j.html.split("orphelin ?").length-1].join()')" "false,1"
assert_eq "EA2.3 — « tenu depuis » lit la date de prise (lease_seconds 3000 s = 50 min), jamais le battement (age_seconds 1 s) : ligne du verrou ET ligne du driver (PU-G-179)" "$(T70 ea2-verrou.json '(j.html.match(/tenu depuis.50 min/g)||[]).length+"|"+j.html.includes("tenu depuis 1 s")')" "2|false"
assert_eq "EA2.4 — lease_seconds absent : « tenu » sans durée, jamais un battement présenté comme une prise (PU-G-179)" "$(T70 ea2-verrou-sanslease.json '[j.html.includes("tenu depuis"), (j.html.match(/>tenu</g)||[]).length].join()')" "false,2"
assert_eq "EA2.5 — verrou dont session_ids ne nomme aucune session de la collecte : « aucune session active », jamais « orphelin » ni « introuvable » (PU-G-179)" "$(T70 ea2-verrou-absent.json '[j.html.includes("aucune session active"), /orphelin|introuvable/.test(j.html.replace(/<[^>]*>/g, " "))].join()')" "true,false"
assert_eq "EA2.6 — apparié : session présente ou session_ids vide : aucun verdict" "$(T70 ea2-verrou.json 'j.html.includes("aucune session active")')|$(T70 ea2-verrou-vide.json 'j.html.includes("aucune session active")')" "false|false"
assert_eq "EA2.7 — le driver se dit en clair : « Session qui pilote : », jamais l'identifiant brut du propriétaire, ni dans le driver ni dans la liste (PU-G-177)" "$(T70 ea2-verrou.json '[j.html.includes("Session qui pilote : "), j.html.includes("88f83d8b")].join()')" "true,false"
assert_eq "EA2.8 — « Qui a la main » remplace « Verrous tenus », avec « rien à faire de votre côté » (PU-G-178)" "$(T70 ea2-verrou.json '[j.html.includes("Qui a la main"), j.html.includes("Verrous tenus"), j.html.includes("rien à faire de votre côté")].join()')" "true,false,true"
assert_eq "EA2.9 — tout est lu : aucun pied de sources ; une source illisible : le pied la nomme, elle seule (PU-G-180)" "$(T70 ea2-verrou.json '[j.html.includes("Sessions et sous-agents"), j.html.includes("class=\"src\"")].join()')|$(T70 ea2-verrou-illisible.json '(/class="src">([^<]*)</.exec(j.html)||[])[1]')" "false,false|Source illisible : Verrous du dépôt"
assert_eq "EA2.10 — personne : « Personne ne travaille en ce moment », sans la liste des sources (PU-G-180)" "$(T70 ea2-vide.json '[j.html.includes("Personne ne travaille en ce moment"), j.html.includes("Sources lues")].join()')" "true,false"
# témoins rouges : le code d'avant (HEAD, c7d96740) et deux mutants
mkdir -p "$MUT/avant"
for f in 70-vf-live.js 71-vf-equipe-rendu.js; do git -C "$SCRIPTS" show "c7d96740:plugin/cockpit/skills/cockpit-moteur/assets/ui/$f" > "$MUT/avant/$f" 2>/dev/null; done
assert_eq "EA2.11 — témoin rouge : le code d'avant (c7d96740) ne montre pas l'orphelin du registre, ne marque pas l'enfant et lit le battement" "$(T70 ea2-orph.json '[j.html.includes("TACHE-ORPH"), j.html.includes("orphelin ?")].join()' "$MUT/avant/70-vf-live.js" "$MUT/avant/71-vf-equipe-rendu.js")|$(T70 ea2-verrou.json 'j.html.includes("tenu depuis 50 min")' "$MUT/avant/70-vf-live.js" "$MUT/avant/71-vf-equipe-rendu.js")" "false,false|false"
sed 's#lease_seconds#age_seconds#g' "$UI/70-vf-live.js" > "$MUT/70-lease.js"
assert_eq "EA2.12 — mutant (lease_seconds lu comme age_seconds) : la durée de prise disparaît, détecté" "$(T70 ea2-verrou.json '(j.html.match(/tenu depuis.50 min/g)||[]).length' "$MUT/70-lease.js")" "0"
M "$UI/70-vf-live.js" "$MUT/70-orph.js" "orph = reste.filter((w) => w.orphan)" "orph = []"
assert_eq "EA2.13 — mutant (orphelins du registre non listés) : détecté" "$(T70 ea2-orph.json 'j.html.includes("TACHE-ORPH")' "$MUT/70-orph.js")" "false"
cat > "$AUX/ea2-rendu.mjs" <<'JS'
// ea2-rendu.mjs <71-vf-equipe-rendu.js> : { deux, un, fini, doing } — l'arbre de deux sessions de même titre (même arbre, puis arbres distincts), d'une seule, d'un terminé sans titre, et le glyphe du bouton de commande.
import fs from 'node:fs';
import vm from 'node:vm';
const ctx = vm.createContext({ window: {}, encodeURIComponent });
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), ctx, { timeout: 5000 });
const R = ctx.window.__vfEquipeRendu;
const s = (id, tree) => ({ kind: 'session', id, tree, etat: 'actif', ageS: 3 });
const noms = (html) => [...html.matchAll(/<span class="r-task">([^<]*?)(?: <span class="sr">|<\/span>)/g)].map((m) => m[1]);
console.log(JSON.stringify({
  memeArbre: noms(R.arbre([s('aaaaaaaa-1111', '.'), s('bbbbbbbb-2222', '.')], h)),
  arbres: noms(R.arbre([s('aaaaaaaa-1111', '.'), s('bbbbbbbb-2222', '.claude/worktrees/wt1')], h)),
  une: noms(R.arbre([s('aaaaaaaa-1111', '.')], h)),
  fini: noms(R.arbre([{ kind: 'subagent', id: 'cccccccc-3333', tree: '.', etat: 'termine', role: 'vf-coder', ageS: 5, dureeS: 360 }], h)),
  terminal: R.arbre([s('aaaaaaaa-1111', '.')], h).includes('M3 4.5'),
}));
JS
ER() { node "$AUX/ea2-rendu.mjs" "${2:-$RENDU}" | node "$AUX/jq.mjs" "$1"; }
assert_eq "EA2.14 — plusieurs « Session principale » se distinguent par l'arbre, puis par l'identifiant court quand l'arbre est le même ; une seule garde son titre (PU-G-186)" "$(ER 'JSON.stringify([j.memeArbre,j.arbres,j.une])')" '[["Session principale · main · aaaaaaaa","Session principale · main · bbbbbbbb"],["Session principale · main","Session principale · wt1"],["Session principale"]]'
assert_eq "EA2.15 — agent terminé sans titre : « rôle · identifiant court » (PU-G-184)" "$(ER 'j.fini.join()')" "vf-coder · cccccccc"
assert_eq "EA2.16 — le bouton « Voir la dernière commande » ne porte plus le chevron et le tiret d'un terminal (PU-G-187) ; témoin : le code d'avant le portait" "$(ER 'j.terminal')|$(ER 'j.terminal' "$MUT/avant/71-vf-equipe-rendu.js")" "false|true"

# --- EA3 (lot 9) : « À surveiller » (PU-G-181), commande longue (PU-G-183), titre /rename des sessions (PU-G-186) ---
cat > "$AUX/ea3-surveiller.json" <<'JSON'
{"who":{"sources":{},"workers":[
 {"kind":"session","id":"s1","etat":"actif","ageS":5,"tree":".","branch":"main"},
 {"kind":"subagent","id":"a1","etat":"actif","ageS":300,"dureeS":700,"role":"vf-coder","task":"TACHE-MUETTE","parent":"s1","tree":".","action":{"verbe":"lit","cible":"x"}},
 {"kind":"subagent","id":"a2","etat":"actif","ageS":1200,"dureeS":1500,"role":"vf-auditer","task":"TACHE-LONGUE","parent":"s1","tree":".","action":{"verbe":"lance une commande"}},
 {"kind":"subagent","id":"a3","etat":"actif","ageS":4,"dureeS":60,"role":"vf-coder","task":"TACHE-VIVANTE","parent":"s1","tree":".","action":{"verbe":"lance une commande"}}]}}
JSON
cat > "$AUX/ea3-calme.json" <<'JSON'
{"who":{"sources":{},"workers":[
 {"kind":"session","id":"s1","etat":"actif","ageS":900,"tree":".","branch":"main"},
 {"kind":"subagent","id":"a3","etat":"actif","ageS":4,"dureeS":60,"role":"vf-coder","task":"TACHE-VIVANTE","parent":"s1","tree":".","action":{"verbe":"lance une commande"}},
 {"kind":"subagent","id":"a4","etat":"en-attente","ageS":5000,"dureeS":60,"role":"vf-coder","task":"TACHE-ATTENTE","parent":"s1","tree":"."}]}}
JSON
mkdir -p "$MUT/avant3"
for f in 70-vf-live.js 71-vf-equipe-rendu.js; do git -C "$SCRIPTS" show "f146c21d:plugin/cockpit/skills/cockpit-moteur/assets/ui/$f" > "$MUT/avant3/$f" 2>/dev/null; done
TXT='j.html.replace(/<[^>]*>/g,"").replace(/\u00a0/g," ")'
assert_eq "EA3.1 — « À surveiller » en tête du tiroir (avant le driver et l'arbre) : un agent sans nouvelle depuis plus de 2 min, une commande en cours depuis plus de 15 min, l'agent vivant ignoré (PU-G-181, PU-G-183)" "$(T70 ea3-surveiller.json "[($TXT).includes('À surveiller · 1 agent sans nouvelle depuis plus de 2 min · 1 commande en cours depuis plus de 15 min'), j.html.indexOf('aw-surv') < j.html.indexOf('aw-driver'), j.html.indexOf('aw-driver') < j.html.indexOf('r-tree')].join()")" "true,true,true"
assert_eq "EA3.2 — la ligne de l'agent le dit aussi : « commande en cours, sans nouvelle depuis 20 min » ; l'agent muet reste « sans nouvelle depuis 5 min » (PU-G-183)" "$(T70 ea3-surveiller.json "[($TXT).includes('commande en cours, sans nouvelle depuis 20 min'), ($TXT).includes('sans nouvelle depuis 5 min'), (($TXT).match(/commande en cours,/g)||[]).length].join()")" "true,true,1"
assert_eq "EA3.3 — règle Q9 « Règle actuelle » : un glyphe et des mots, aucune couleur d'alerte, aucun style en ligne, ni la forme « bloqué » (PU-G-181)" "$(T70 ea3-surveiller.json '(() => { const p = /<p class="aw-surv">.*?<\/p>/.exec(j.html)[0]; return [p.includes("<svg"), p.includes("style="), /bloque|alerte|danger|rouge/.test(p), p.includes("aw-s-attente")].join(); })()')" "true,false,false,true"
assert_eq "EA3.4 — rien à surveiller (agent vivant, session muette, agent en attente) ou personne : aucune ligne « À surveiller » (PU-G-181)" "$(T70 ea3-calme.json 'j.html.includes("aw-surv")')|$(T70 ea2-vide.json 'j.html.includes("aw-surv")')|$(T70 ea2-orph.json 'j.html.includes("aw-surv")')" "false|false|false"
assert_eq "EA3.5 — témoin rouge : le code d'avant (f146c21d) n'a ni la ligne « À surveiller » ni la commande en cours" "$(T70 ea3-surveiller.json "[j.html.includes('À surveiller'), ($TXT).includes('commande en cours')].join()" "$MUT/avant3/70-vf-live.js" "$MUT/avant3/71-vf-equipe-rendu.js")" "false,false"
sed 's/const LONGUE_S = 900;/const LONGUE_S = 9e9;/' "$RENDU" > "$MUT/71-longue.js"
assert_eq "EA3.6 — mutant (seuil de la commande longue inatteignable) : la commande longue disparaît de la ligne et des rangées, détectée" "$(T70 ea3-surveiller.json "[($TXT).includes('commande en cours'), ($TXT).includes('2 agents sans nouvelle')].join()" "$UI/70-vf-live.js" "$MUT/71-longue.js")" "false,true"
cat > "$AUX/ea3-rendu.mjs" <<'JS'
// ea3-rendu.mjs <71-vf-equipe-rendu.js> : { titree, deux, blanc, balise, sans } — les noms de session rendus par l'arbre : titre /rename, deux sessions de même titre, titre blanc, titre porteur de balisage, session sans titre.
import fs from 'node:fs';
import vm from 'node:vm';
const ctx = vm.createContext({ window: {}, encodeURIComponent });
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), ctx, { timeout: 5000 });
const R = ctx.window.__vfEquipeRendu;
const s = (id, tree, titre) => ({ kind: 'session', id, tree, etat: 'actif', ageS: 3, ...(titre === undefined ? {} : { titre }) });
const noms = (html) => [...html.matchAll(/<span class="r-task">([^<]*?)(?: <span class="sr">|<\/span>)/g)].map((m) => m[1]);
console.log(JSON.stringify({
  titree: noms(R.arbre([s('aaaaaaaa-1111', '.', 'Mon chantier')], h)),
  deux: noms(R.arbre([s('aaaaaaaa-1111', '.', 'Mon chantier'), s('bbbbbbbb-2222', '.claude/worktrees/wt1', 'Mon chantier')], h)),
  blanc: noms(R.arbre([s('aaaaaaaa-1111', '.', '   ')], h)),
  balise: noms(R.arbre([s('aaaaaaaa-1111', '.', '<b>x</b>')], h)),
  sans: noms(R.arbre([s('aaaaaaaa-1111', '.')], h)),
  detenteur: R.nomDeSession([s('aaaaaaaa-1111', '.', 'Mon chantier')], 'aaaaaaaa-1111'),
}));
JS
E3R() { node "$AUX/ea3-rendu.mjs" "${2:-$RENDU}" | node "$AUX/jq.mjs" "$1"; }
assert_eq "EA3.7 — une session nommée avec /rename s'affiche sous son titre ; deux sessions de même titre se distinguent par l'arbre ; titre blanc ou absent : « Session principale » ; le détenteur du verrou la nomme de même (PU-G-186)" "$(E3R 'JSON.stringify([j.titree,j.deux,j.blanc,j.sans,j.detenteur])')" '[["Mon chantier"],["Mon chantier · main","Mon chantier · wt1"],["Session principale"],["Session principale"],"Mon chantier"]'
assert_eq "EA3.8 — un titre porteur de balisage reste du texte : échappé dans le rendu, jamais interprété (PU-G-186)" "$(E3R 'j.balise.join()')" "&lt;b&gt;x&lt;/b&gt;"
assert_eq "EA3.9 — témoin rouge : le code d'avant (f146c21d) ignore le titre /rename" "$(E3R 'j.titree.join()' "$MUT/avant3/71-vf-equipe-rendu.js")" "Session principale"

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
