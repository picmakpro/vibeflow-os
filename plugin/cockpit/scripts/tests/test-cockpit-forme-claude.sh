#!/usr/bin/env bash
# test-cockpit-forme-claude.sh — test de forme du format interne de Claude Code, étendu aux champs nouvellement lus
# (CKPT-27 ; P69-D-22) : une fixture conforme de forme réelle, puis une fixture amputée par champ ; un champ disparu
# rend la source forme-inconnue, jamais un arbre faux.
#   F0  fixture conforme (m, w, t listés, source lue) · F1 à F10 une amputation par champ lu (agent absent ET source forme-inconnue)
#   F11 le contrat déclare chaque champ lu (dont custom-title, F11.7 à F11.10) · F12 parent absent du dossier · F13 le manager de profondeur 1 sans parentAgentId reste listé
#   F17 index incrémental des transcripts : le contrat déclare chaque champ lu (bloc claudeCode.index), amputation par champ, test miroir, vueAgents et verifieSur (79-08)
#   F14 35 vieux meta.json dégradés hors fenêtre ne changent rien · F15 forme arrêtée {agentType, stoppedByUser}
#   F16 coût de collecte à l'échelle du poste : zéro ouverture hors fenêtre sur 1 000 meta.json
# Le code testé est chargé depuis le dossier de ce script (jamais depuis le répertoire courant).
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; NOSCRIPTS="$WORK/noscripts"
mkdir -p "$AUX" "$NOSCRIPTS"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/q.mjs" <<'JS'
// q.mjs <scripts> who <root> <home> <scriptsDir> [<nowMs>] : le code testé est chargé depuis <scripts>
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, what, root, home, scriptsDir, extra] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-who.mjs')).href);
if (what === 'who') console.log(JSON.stringify(m.collectWho(root, { home, scriptsDir, now: extra ? Number(extra) : undefined })));
JS
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mk-forme.mjs" <<'JS'
// mk-forme.mjs <home> <lab> <idSession> <nowMs> <cas> : un HOME jetable à la forme réelle mesurée (R5.1), valeurs synthétiques.
// Base : session fraîche, manager m (profondeur 1, sans parentAgentId, actif), worker w (profondeur 2, parentAgentId m, actif, sans finished),
// terminé t (profondeur 2, parentAgentId m, finished true, fin depuis 1 h). Cas : base, F1 à F10 (une amputation), F12, H14, H14b, H15, H16.
import fs from 'node:fs';
import path from 'node:path';
const [, , home, lab, sid, nowMs, cas] = process.argv;
const now = Number(nowMs);
const dir = path.join(home, '.claude', 'projects', '-lab'); const sub = path.join(dir, sid, 'subagents');
fs.mkdirSync(sub, { recursive: true });
const iso = (ms) => new Date(ms).toISOString();
const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.322', ...o });
const put = (f, lignes, ageS) => { fs.writeFileSync(f, lignes.map((l) => JSON.stringify(l)).join('\n') + '\n'); const t = (now - ageS * 1000) / 1000; fs.utimesSync(f, t, t); };
const H30 = 108000;
put(path.join(dir, sid + '.jsonl'), [
  base({ type: 'user', timestamp: iso(now - 605000), message: { content: 'salut' } }),
  base({ type: 'assistant', timestamp: iso(now - 5000), message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo bonjour' } }] } }),
], 5);
// amputations : { cible, meta(m), first(l) }
const AMP = {
  F1: { cible: 'w', meta: (m) => delete m.parentAgentId }, F2: { cible: 'w', meta: (m) => delete m.spawnDepth },
  F3: { cible: 'w', meta: (m) => delete m.toolUseId }, F4: { cible: 'w', meta: (m) => delete m.requestShape },
  F5: { cible: 'w', meta: (m) => delete m.agentType }, F6: { cible: 'w', meta: (m) => delete m.description },
  F7: { cible: 't', meta: (m) => { m.finished = 'oui'; } },
  F8: { cible: 'w', first: (l) => delete l.isSidechain }, F9: { cible: 'w', first: (l) => delete l.agentId },
  F10: { cible: 'w', first: (l) => { l.agentId = 'autre'; } },
};
const amp = AMP[cas] || {};
const agent = ({ id, depth, parent, finished, ageS, meta: forme }) => {
  let meta = forme || { agentType: 'vf-coder', isBuiltIn: false, launchedWithDefaults: false, description: `tâche synthétique ${id}`, toolUseId: `toolu_${id}`, spawnDepth: depth, requestShape: 'background', requestNonInteractive: true };
  if (!forme) { if (depth >= 2) meta.parentAgentId = parent; if (finished) meta.finished = true; }
  const first = base({ type: 'user', isSidechain: true, agentId: id, parentUuid: null, timestamp: iso(now - ageS * 1000 - 300000), message: { role: 'user', content: `mandat synthétique de ${id}` } });
  if (amp.cible === id) { if (amp.meta) amp.meta(meta); if (amp.first) amp.first(first); }
  fs.writeFileSync(path.join(sub, `agent-${id}.meta.json`), JSON.stringify(meta));
  put(path.join(sub, `agent-${id}.jsonl`), [first, base({ type: 'assistant', isSidechain: true, agentId: id, timestamp: iso(now - ageS * 1000), message: { role: 'assistant', content: [{ type: 'tool_use', id: `toolu_x${id}`, name: 'Read', input: { file_path: `${lab}/README.md` } }] } })], ageS);
};
const M = { id: 'm', depth: 1, ageS: 10 }, W = { id: 'w', depth: 2, parent: 'm', ageS: 6 }, T = { id: 't', depth: 2, parent: 'm', finished: true, ageS: 3600 };
const vieux = (id, forme) => agent({ id, ageS: H30, meta: forme });
if (cas === 'H14' || cas === 'H14b') {
  agent(M); agent(W);
  if (cas === 'H14b') { const f = path.join(sub, 'agent-w.meta.json'); const m = JSON.parse(fs.readFileSync(f, 'utf8')); delete m.description; fs.writeFileSync(f, JSON.stringify(m)); }
  for (let i = 1; i <= 30; i++) vieux(`vieux${String(i).padStart(2, '0')}`, { agentType: 'vf-coder', stoppedByUser: true });
  for (let i = 31; i <= 35; i++) vieux(`vieux${i}`, { agentType: 'vf-coder' });
} else if (cas === 'H15') {
  agent(M);
  agent({ id: 's1', ageS: 3600, meta: { agentType: 'vf-coder', stoppedByUser: true } });
  agent({ id: 's2', ageS: H30, meta: { agentType: 'vf-coder', stoppedByUser: true } });
} else if (cas === 'H16') {
  agent(M); agent({ id: 'c2', depth: 2, parent: 'm', ageS: 8 });
  agent({ id: 'anc', depth: 1, ageS: H30 }); agent({ id: 'wk', depth: 2, parent: 'anc', ageS: 5 });
  const formes = [
    () => ({ agentType: 'vf-coder', stoppedByUser: true }), () => ({ agentType: 'vf-coder' }), () => ({ description: 'x' }),
    () => ({ agentType: 'vf-coder', description: 'x', spawnDepth: 2, toolUseId: 't', requestShape: 'background', parentAgentId: 'anc', finished: true }), () => ({ agentType: 'vf-coder', description: 'x' }),
  ];
  for (let i = 1; i <= 1000; i++) vieux(`old${String(i).padStart(4, '0')}`, formes[i % 5]());
} else {
  agent(M); agent(W); agent(T);
  if (cas === 'F12') agent({ id: 'w3', depth: 3, parent: 'fantome', ageS: 4 });
}
JS
cat > "$AUX/compte-lectures.mjs" <<'JS'
// compte-lectures.mjs <scripts> <root> <home> <scriptsDir> <nowMs> : remplace readFileSync, openSync et createReadStream par des versions
// qui comptent les ouvertures par préfixe de nom de fichier (agent-old* / autres agent-* / reste), importe ensuite vf-cockpit-who.mjs
// depuis <scripts>, appelle collectWho et imprime en JSON les comptes, la durée et la liste des sous-agents (identifiant, état).
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, root, home, scriptsDir, nowMs] = process.argv;
const opens = {};
const note = (p) => { if (typeof p !== 'string') return; const b = path.basename(p); const k = b.startsWith('agent-old') ? 'agent-old' : b.startsWith('agent-') ? 'agent-autre' : 'autre'; opens[k] = (opens[k] || 0) + 1; };
for (const nom of ['readFileSync', 'openSync', 'createReadStream']) { const o = fs[nom]; fs[nom] = function (p, ...r) { note(p); return o.call(this, p, ...r); }; }
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-who.mjs')).href);
const t0 = Date.now();
const r = m.collectWho(root, { home, scriptsDir, now: Number(nowMs) });
console.log(JSON.stringify({ opens, ms: Date.now() - t0, sous: r.workers.filter((w) => w.kind === 'subagent').map((w) => [w.id, w.etat || null]), source: r.sources.sessions.etat, formeInconnue: r.sources.sessions.formeInconnue }));
JS

Q() { node "$AUX/q.mjs" "$SCRIPTS" "$@"; }
G() { node "$AUX/get.mjs" "$@"; }
NOW="$(node -e 'console.log(Date.now())')"
IFACE="$SCRIPTS/vf-cockpit-interface.json"
LAB="$WORK/lab"; mkdir -p "$LAB"; git -C "$LAB" init -q
SID="aaaa1111-2222-3333-4444-555566667777"
fx() { local h="$WORK/home-$1"; mkdir -p "$h"; node "$AUX/mk-forme.mjs" "$h" "$LAB" "$SID" "$NOW" "$1" || echo "mk-forme KO ($1)" >&2; echo "$h"; }
whofx() { Q who "$LAB" "$(fx "$1")" "$NOSCRIPTS" "$NOW" > "$WORK/who-$1.json"; }
ids() { G "$WORK/who-$1.json" 'j.workers.filter(x=>x.kind==="subagent").map(x=>x.id).sort().join(",")'; }
sf() { G "$WORK/who-$1.json" '(w=>w?('"$3"'):"absent")(j.workers.find(x=>x.kind==="subagent"&&x.id==="'"$2"'"))'; }
src() { G "$WORK/who-$1.json" 'j.sources.sessions.etat+"|"+j.sources.sessions.formeInconnue'; }

echo "=== F0 — fixtures conformes de forme réelle ==="
whofx base
assert_eq "F0.1 — forme réelle : m, w, t listés (t est un terminé de moins d'une heure)" "$(ids base)" "m,t,w"
assert_eq "F0.2 — source lue, formeInconnue 0" "$(src base)" "lue|0"
assert_eq "F0.3 — contrôle positif : m (profondeur 1, sans parentAgentId) et w (actif, sans finished) sont listés" "$(sf base m '"présent"'),$(sf base w '"présent"')" "présent,présent"

echo "=== F1 à F10 — une amputation par champ lu ==="
for cas in F1:w:parentAgentId F2:w:spawnDepth F3:w:toolUseId F4:w:requestShape F5:w:agentType F6:w:description F7:t:finished-non-booleen F8:w:isSidechain F9:w:agentId-absent F10:w:agentId-different; do
  n="${cas%%:*}"; r="${cas#*:}"; cible="${r%%:*}"; champ="${r#*:}"
  whofx "$n"
  assert_eq "${n}.a — ${champ} : l'agent amputé (${cible}) est absent" "$(sf "$n" "$cible" '"présent"')" "absent"
  assert_eq "${n}.b — ${champ} : la source est forme-inconnue" "$(G "$WORK/who-$n.json" 'j.sources.sessions.etat')" "forme-inconnue"
  assert_eq "F13.${n} — m (profondeur 1, sans parentAgentId) reste listé après l'amputation ${n}" "$(sf "$n" m '"présent"')" "présent"
done

echo "=== F11 — le contrat déclare chaque champ lu ==="
assert_eq "F11.0 — contrôle positif : le contrat est lu et porte claudeCode.verifieSur" "$(G "$IFACE" 'typeof j.claudeCode.verifieSur')" "string"
assert_eq "F11.1 — metaSousAgent.requis contient agentType, description, spawnDepth, toolUseId, requestShape" "$(G "$IFACE" '["agentType","description","spawnDepth","toolUseId","requestShape"].every(k=>(j.claudeCode.metaSousAgent?.requis||[]).includes(k))')" "true"
assert_eq "F11.2 — requisSiProfondeur.parentAgentId = 2" "$(G "$IFACE" 'j.claudeCode.metaSousAgent?.requisSiProfondeur?.parentAgentId')" "2"
assert_eq "F11.3 — booleensFacultatifs contient finished" "$(G "$IFACE" '(j.claudeCode.metaSousAgent?.booleensFacultatifs||[]).includes("finished")')" "true"
assert_eq "F11.4 — transcriptSousAgent.requis = isSidechain,agentId" "$(G "$IFACE" '(j.claudeCode.transcriptSousAgent?.requis||[]).join(",")')" "isSidechain,agentId"
assert_eq "F11.5 — verifieSur est de forme N.N.N" "$(G "$IFACE" '/^[0-9]+[.][0-9]+[.][0-9]+$/.test(j.claudeCode.verifieSur)')" "true"
assert_eq "F11.6 — formeArretee.requis = agentType,stoppedByUser" "$(G "$IFACE" '(j.claudeCode.metaSousAgent?.formeArretee?.requis||[]).join(",")')" "agentType,stoppedByUser"
# PU-G-162 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06) : la forme `custom-title` lue par la collecte (vf-cockpit-lecture.mjs) est déclarée au contrat ; `ai-title` n'y entre jamais.
assert_eq "F11.7 — transcriptTitre déclare type custom-title, champ customTitle (chaîne)" "$(G "$IFACE" '[j.claudeCode.transcriptTitre?.type,j.claudeCode.transcriptTitre?.champ,j.claudeCode.transcriptTitre?.typeChamp].join(",")')" "custom-title,customTitle,string"
assert_eq "F11.8 — ai-title est refusé au contrat (refuse) et n'est ni type ni champ lu" "$(G "$IFACE" '(t=>(t.refuse||[]).includes("ai-title")&&![t.type,t.champ].some(x=>/ai-?title/i.test(String(x))))(j.claudeCode.transcriptTitre||{})')" "true"
assert_eq "F11.9 — la collecte lit exactement la forme déclarée (type et champ dans vf-cockpit-lecture.mjs, ai-title jamais lu)" "$(node -e '
const fs=require("fs");const c=JSON.parse(fs.readFileSync(process.argv[1],"utf8")).claudeCode.transcriptTitre||{};
const src=fs.readFileSync(process.argv[2],"utf8").split("\n").filter(l=>!/^\s*\/\//.test(l)).join("\n");
console.log(c.type&&c.champ&&src.includes("d.type === \x27"+c.type+"\x27 && typeof d."+c.champ+" === \x27string\x27")&&!/d\.type === .ai-title./.test(src)&&!/d\.aiTitle/.test(src))' "$IFACE" "$SCRIPTS/vf-cockpit-lecture.mjs")" "true"
assert_eq "F11.10 — types/index.d.ts : SignalWorker porte titre?: string, et who@2.travailleur.optionnels déclare titre" "$(node -e '
const fs=require("fs");const d=fs.readFileSync(process.argv[2],"utf8");const m=d.match(/export type SignalWorker = \{[^}]*\}/);
const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8")).schemas["vibeflow/cockpit-who@2"].travailleur.optionnels;
console.log(!!m&&/^\s*titre\?: string$/m.test(m[0])&&j.includes("titre"))' "$IFACE" "$SCRIPTS/../signal/types/index.d.ts")" "true"

echo "=== F12 — parentAgentId désignant un agent absent du dossier ==="
whofx F12
assert_eq "F12.0 — contrôle positif : m et w sont listés" "$(sf F12 m '"présent"'),$(sf F12 w '"présent"')" "présent,présent"
assert_eq "F12.a — w3 (parentAgentId vers un agent absent) est absent" "$(sf F12 w3 '"présent"')" "absent"
assert_eq "F12.b — la source est forme-inconnue" "$(G "$WORK/who-F12.json" 'j.sources.sessions.etat')" "forme-inconnue"

echo "=== F14 — la fenêtre de 24 h : 35 vieux meta.json dégradés ne changent rien ==="
whofx H14
assert_eq "F14.1 — m et w listés, aucun vieux* listé" "$(ids H14)" "m,w"
assert_eq "F14.2 — source lue, formeInconnue 0 (rougit dès que le contrôle de forme porte sur l'historique entier)" "$(src H14)" "lue|0"
assert_eq "F14.3 — le parent de w est m" "$(sf H14 w w.parent)" "m"
whofx H14b
assert_eq "F14.4 — H14b (description retirée de w) : w absent ET source forme-inconnue (les vieux fichiers n'affaiblissent pas un champ requis)" "$(sf H14b w '"présent"')|$(G "$WORK/who-H14b.json" 'j.sources.sessions.etat')" "absent|forme-inconnue"

echo "=== F15 — forme arrêtée {agentType, stoppedByUser} ==="
whofx H15
assert_eq "F15.1 — s1 (arrêté depuis 1 h) est présent, termine, avec finAt" "$(sf H15 s1 'w.etat+"|"+(w.finAt?"finAt":"sans")')" "termine|finAt"
assert_eq "F15.2 — le parent de s1 est l'identifiant de la session" "$(sf H15 s1 w.parent)" "$SID"
assert_eq "F15.3 — s2 (arrêté depuis 30 h) est absent" "$(sf H15 s2 '"présent"')" "absent"
assert_eq "F15.4 — source lue, formeInconnue 0 (garde : rougit si le contrôle de forme s'applique hors fenêtre ou si s1 sans description est compté)" "$(src H15)" "lue|0"

echo "=== F16 — coût de collecte à l'échelle du poste (1 000 meta.json hors fenêtre) ==="
H16="$(fx H16)"
node "$AUX/compte-lectures.mjs" "$SCRIPTS" "$LAB" "$H16" "$NOSCRIPTS" "$NOW" > "$WORK/f16.json"
assert_eq "F16.0 — contrôle positif : la sonde compte les ouvertures des candidats (au moins 3 fichiers agent-* hors agent-old)" "$(G "$WORK/f16.json" '(j.opens["agent-autre"]||0) >= 3')" "true"
assert_eq "F16.1 — zéro ouverture d'un fichier agent-old*" "$(G "$WORK/f16.json" 'j.opens["agent-old"]||0')" "0"
assert_eq "F16.2 — les 3 candidats actifs (m, c2, wk) sont listés et la source est lue" "$(G "$WORK/f16.json" '["m","c2","wk"].every(k=>j.sous.some(s=>s[0]===k))+"|"+j.source')" "true|lue"
assert_eq "F16.3 — l'ancêtre anc, hors fenêtre, est listé en-attente (recherche ciblée sur parentAgentId)" "$(G "$WORK/f16.json" '(j.sous.find(s=>s[0]==="anc")||[null,"absent"])[1]')" "en-attente"
assert_eq "F16.4 — collectWho < 3 000 ms sur 1 004 meta.json (plafond)" "$(G "$WORK/f16.json" 'j.ms < 3000')" "true"

echo "=== F17 — l'index des transcripts lit exactement les champs déclarés au contrat (79-08, SOCL-12) ==="
cat > "$AUX/mk-forme-index.mjs" <<'JS'
// mk-forme-index.mjs <scripts> <work> <version> : fixture conforme construite de la liste `requis` du contrat, puis une amputation par champ requis déclaré
// (et un changement de type par champ numérique) ; imprime { conforme, amputations: { chemin: forme }, types: { chemin: forme }, mesuresNulles, hors, horsDeclare, miroir }
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , SC, WORK, VERSION] = process.argv; const imp = (n) => import(pathToFileURL(path.join(SC, n)).href);
const idx = await imp('vf-cockpit-index.mjs'), voie = await imp('vf-cockpit-index-voie.mjs'); const CC = JSON.parse(fs.readFileSync(path.join(SC, 'vf-cockpit-interface.json'), 'utf8')).claudeCode; const B = CC.index;
const T0 = Date.parse('2026-11-01T09:00:00Z'), LAB = path.join(WORK, 'lab'); fs.mkdirSync(LAB, { recursive: true });
const ts = (t) => new Date(T0 + t).toISOString(); const R = {};
const lignes = () => [
  { type: 'user', cwd: LAB, sessionId: 'sess-f17', version: VERSION, timestamp: ts(0), message: { role: 'user', content: 'x' } },
  { type: 'assistant', cwd: LAB, sessionId: 'sess-f17', version: VERSION, timestamp: ts(1000), message: { id: 'm1', model: 'claude-test-1', stop_reason: 'tool_use', usage: { input_tokens: 10, output_tokens: 5, cache_read_input_tokens: 100, cache_creation_input_tokens: 0 }, content: [{ type: 'tool_use', id: 't1', name: 'Read', input: {} }] } },
  { type: 'user', cwd: LAB, sessionId: 'sess-f17', version: VERSION, timestamp: ts(2000), message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: 't1', content: 'x' }] } },
];
const retire = (o, ch) => { const k = ch.split('.'); let a = o; for (const x of k.slice(0, -1)) a = a[x]; delete a[k[k.length - 1]]; };
const pose = (o, ch, v) => { const k = ch.split('.'); let a = o; for (const x of k.slice(0, -1)) a = a[x]; a[k[k.length - 1]] = v; };
const cible = { lignesDatees: (L) => L[0], assistant: (L) => L[1], appel: (L) => L[1].message.content[0], resultat: (L) => L[2].message.content[0] };
let n = 0;
const joue = (L) => { const d = path.join(WORK, `f17-${++n}`, 'projects', '-lab'); fs.mkdirSync(d, { recursive: true }); const f = path.join(d, 'sess-f17.jsonl'); fs.writeFileSync(f, L.map((l) => JSON.stringify(l)).join('\n') + '\n'); fs.utimesSync(f, (T0 + 3000) / 1000, (T0 + 3000) / 1000);
  const i = idx.construire(idx.enumerer(path.join(d, '..')), { maintenant: T0 + 3600e3, CC, arbreDe: () => ({ arbre: null }) }); return { i, v: i.voies[0] }; };
const { i: iOk, v: vOk } = joue(lignes()); R.conforme = vOk ? `${vOk.forme}|${vOk.jetons.entree}|${vOk.jetons.sortie}` : 'absente'; R.bilan = JSON.stringify(idx.bilan(iOk).versionsHorsContrat);
R.bilanAutre = JSON.stringify(idx.bilan(joue(lignes()).i).versionsHorsContrat.length); { const i2 = idx.construire(idx.enumerer(path.join(WORK, 'f17-1', 'projects')), { maintenant: T0 + 3600e3, arbreDe: () => ({ arbre: null }), CC: { ...CC, verifieSur: '9.9.9' } }); R.horsContratEssai = JSON.stringify(idx.bilan(i2).versionsHorsContrat); }
R.amputations = {}; R.types = {};
for (const [bloc, spec] of Object.entries(B)) for (const ch of spec.requis || []) { if (!cible[bloc]) continue; const L = lignes(); retire(cible[bloc](L), ch); const { v } = joue(L); R.amputations[`${bloc}.${ch}`] = v ? `${v.forme}|${v.jetons === null && v.compteurs === null && v.durees === null}` : 'absente'; if (B.types[ch] === 'number') { const M = lignes(); pose(cible[bloc](M), ch, 'x'); const w = joue(M).v; R.types[`${bloc}.${ch}`] = w ? w.forme : 'absente'; } }
// test miroir : tout littéral passé à lire( est déclaré au contrat ; aucun accès direct `.message.` hors de l'accesseur
const declares = new Set(Object.values(B).flatMap((b) => (b && typeof b === 'object' && !Array.isArray(b) ? [...(b.requis || []), ...(b.facultatifs || [])] : [])));
const analyse = (src) => ({ nonDeclares: [...src.matchAll(/\blire\([^,()]+,\s*'([^']+)'\)/g)].map((m) => m[1]).filter((c) => !declares.has(c)), directs: (src.replace(/\/\/.*$/gm, '').match(/\.message\./g) || []).length });
const src = fs.readFileSync(path.join(SC, 'vf-cockpit-index-voie.mjs'), 'utf8');
R.miroir = JSON.stringify(analyse(src)); R.temoinDirect = JSON.stringify(analyse(src + "\nconst x = d.message.id;\n").directs); R.temoinNonDeclare = JSON.stringify(analyse(src + "\nlire(d, 'nouveau.champ');\n").nonDeclares);
console.log(JSON.stringify(R));
JS
FV="$(node -e 'const l=require("fs").readFileSync(process.argv[1],"utf8");console.log((l.match(/version: .([0-9.]+)./)||[])[1])' "$AUX/mk-forme.mjs")"
node "$AUX/mk-forme-index.mjs" "$SCRIPTS" "$WORK/f17" "$FV" > "$WORK/f17.json" 2> "$WORK/f17.err" || head -3 "$WORK/f17.err"
assert_eq "F17.0 — le bloc claudeCode.index déclare le plancher : timestamp, message.id, usage entrée et sortie, id et name d'un appel, tool_use_id d'un résultat" "$(G "$IFACE" '(b=>[b.lignesDatees.requis,b.assistant.requis,b.appel.requis,b.resultat.requis].flat().join(","))(j.claudeCode.index)')" "timestamp,message.id,message.usage.input_tokens,message.usage.output_tokens,id,name,tool_use_id"
assert_eq "F17.1 — fixture conforme à la forme déclarée : voie ok aux jetons attendus (témoin positif)" "$(G "$WORK/f17.json" 'j.conforme')" "ok|10|5"
for c in lignesDatees.timestamp assistant.message.id assistant.message.usage.input_tokens assistant.message.usage.output_tokens appel.id appel.name resultat.tool_use_id; do
  assert_eq "F17.2.$c — amputer le champ requis déclaré : voie inconnue, mesures nulles" "$(G "$WORK/f17.json" "j.amputations[\"$c\"]")" "inconnue|true"; done
for c in assistant.message.usage.input_tokens assistant.message.usage.output_tokens; do assert_eq "F17.2t.$c — changer le type du champ numérique : voie inconnue" "$(G "$WORK/f17.json" "j.types[\"$c\"]")" "inconnue"; done
assert_eq "F17.2n — autant d'amputations jouées que de champs requis déclarés (anti-vert-à-vide)" "$(G "$WORK/f17.json" 'Object.keys(j.amputations).length')" "7"
assert_eq "F17.3 — test miroir : tout littéral lu est déclaré, aucun accès direct .message. hors de l'accesseur" "$(G "$WORK/f17.json" 'j.miroir')" '{"nonDeclares":[],"directs":0}'
assert_eq "F17.3b — témoins : un accès direct supplémentaire compte 1, un littéral non déclaré est vu" "$(G "$WORK/f17.json" 'j.temoinDirect+"|"+j.temoinNonDeclare')" '1|["nouveau.champ"]'
assert_eq "F17.4 — vueAgents.description dit source de référence et repli, sans l'ancienne formulation" "$(G "$IFACE" '(d=>/source de référence/.test(d)&&/repli/.test(d)&&!/enrichissement optionnel|jamais la source unique/.test(d))(j.claudeCode.vueAgents.description)')" "true"
assert_eq "F17.5 — verifieSur égale la version des lignes de la fixture conforme ; aucune version hors contrat avec le contrat réel, une avec un contrat d'essai" "$(G "$IFACE" 'j.claudeCode.verifieSur'),$(G "$WORK/f17.json" 'j.bilan+"|"+j.horsContratEssai')" "$FV,[]|[\"$FV\"]"

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
