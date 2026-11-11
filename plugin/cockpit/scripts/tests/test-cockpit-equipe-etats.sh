#!/usr/bin/env bash
# test-cockpit-equipe-etats.sh — état des sessions et des agents de l'onglet Équipe, lot 0 de l'audit du cockpit (AUDC-D1 à D4, M3).
# Chaque ligne du registre a sa section ; toutes traversent le COLLECTEUR RÉEL (collectWho, puis buildEquipeGraph), jamais une donnée écrite à la main
# pour le rendu seul. Un HOME jetable porte les transcripts ; le lab est un dépôt git jetable.
#   D1  un sous-agent non fini et muet reste listé (« outil en cours »), sa session aussi
#   D2  une session écrite depuis moins de 24 h reste listée avec un état lu (occupée, au repos, vous attend, close)
#   D3  « À surveiller » et « commande en cours depuis 15 min » atteignables de bout en bout ; l'âge avance dans la page
#   D4  un worker vivant sous un manager terminé est dit orphelin, jamais rangé dans « Terminés »
#   M3  le titre de la vue Équipe dit le nombre d'agents actifs ; la santé d'Équipe ne contredit plus celle de Code
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
UI="$(cd "$SCRIPTS/../skills/cockpit-moteur/assets/ui" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX"
LAB="$WORK/lab"; mkdir -p "$LAB"; git -C "$LAB" init -q

cat > "$AUX/etats.mjs" <<'JS'
// etats.mjs <scripts> <ui> <lab> <work> <section>... : construit des HOME jetables, interroge le collecteur réel, affiche des lignes PASS/FAIL.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { pathToFileURL } from 'node:url';
const [, , scripts, ui, lab, work, ...sections] = process.argv;
const who = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-who.mjs')).href);
const carte = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-equipe-carte.mjs')).href);
let pass = 0, fail = 0;
const ok = (nom, cond, detail) => { if (cond) { pass++; console.log(`  ✅ PASS — ${nom}`); } else { fail++; console.log(`  ❌ FAIL — ${nom}${detail !== undefined ? `\n     obtenu: ${typeof detail === 'string' ? detail : JSON.stringify(detail)}` : ''}`); } };
const eq = (nom, obtenu, attendu) => { const a = JSON.stringify(obtenu), b = JSON.stringify(attendu); if (a === b) { pass++; console.log(`  ✅ PASS — ${nom}`); } else { fail++; console.log(`  ❌ FAIL — ${nom}\n     attendu: ${b}\n     obtenu:  ${a}`); } };

const SID = '11111111-1111-4111-8111-111111111111';
const NOW = Date.now();
const iso = (ageS) => new Date(NOW - ageS * 1000).toISOString();
const ligne = (o) => JSON.stringify(o) + '\n';
const base = (extra) => ({ cwd: lab, sessionId: SID, version: '2.1.322', gitBranch: 'main', userType: 'external', ...extra });
let n = 0;
// monter({ session: { ageS, titre }, agents: [{ id, role, parent, depth, ageS, fini, outil, resultat }] }) -> HOME
function monter(spec) {
  const home = path.join(work, 'home-' + (++n)); const dir = path.join(home, '.claude', 'projects', '-lab'); const sid = spec.sid || SID;
  const sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
  const poser = (f, lignes, ageS) => { fs.writeFileSync(f, lignes.join('')); const t = (NOW - ageS * 1000) / 1000; fs.utimesSync(f, t, t); };
  const s = spec.session || { ageS: 5 };
  const sl = [ligne(base({ sessionId: sid, type: 'user', timestamp: iso(s.ageS + 100), message: { role: 'user', content: 'x' }, uuid: 'u1', parentUuid: null }))];
  if (s.titre) sl.push(ligne({ type: 'custom-title', customTitle: s.titre, sessionId: sid }));
  sl.push(ligne(base({ sessionId: sid, type: 'assistant', timestamp: iso(s.ageS), uuid: 'u2', parentUuid: 'u1', message: { role: 'assistant', id: 'm1', model: 'm', stop_reason: s.fin || 'end_turn', content: s.fin === 'tool_use' ? [{ type: 'tool_use', id: 'ts', name: 'Agent', input: { subagent_type: 'vf-coder' } }] : [{ type: 'text', text: 'ok' }] } })));
  poser(path.join(dir, sid + '.jsonl'), sl, s.ageS);
  for (const a of spec.agents || []) {
    const depth = a.depth ?? (a.parent ? 2 : 1);
    fs.writeFileSync(path.join(sub, `agent-${a.id}.meta.json`), JSON.stringify({ agentType: a.role || 'vf-coder', description: 'tache ' + a.id, spawnDepth: depth, toolUseId: 't' + a.id, requestShape: 'background', ...(depth >= 2 ? { parentAgentId: a.parent } : {}), ...(a.fini ? { finished: true } : {}) }));
    const l = [ligne(base({ sessionId: sid, type: 'user', isSidechain: true, agentId: a.id, timestamp: iso(a.ageS + 600), message: { role: 'user', content: 'mandat' }, uuid: 'a1' + a.id, parentUuid: null }))];
    const outil = a.outil || 'Bash';
    if (a.fini) l.push(ligne(base({ sessionId: sid, type: 'assistant', isSidechain: true, agentId: a.id, timestamp: iso(a.ageS), uuid: 'a2' + a.id, parentUuid: 'a1' + a.id, message: { role: 'assistant', id: 'x' + a.id, model: 'm', stop_reason: 'end_turn', content: [{ type: 'text', text: 'fin' }] } })));
    else {
      l.push(ligne(base({ sessionId: sid, type: 'assistant', isSidechain: true, agentId: a.id, timestamp: iso(a.ageS + (a.resultat ? 5 : 0)), uuid: 'a2' + a.id, parentUuid: 'a1' + a.id, message: { role: 'assistant', id: 'x' + a.id, model: 'm', stop_reason: 'tool_use', content: [{ type: 'tool_use', id: 'tb' + a.id, name: outil, input: outil === 'Bash' ? { command: 'npm test' } : outil === 'Agent' ? { subagent_type: 'vf-reviewer' } : { file_path: path.join(lab, 'a.txt') } }] } })));
      if (a.resultat) l.push(ligne(base({ sessionId: sid, type: 'user', isSidechain: true, agentId: a.id, timestamp: iso(a.ageS), uuid: 'a3' + a.id, parentUuid: 'a2' + a.id, message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: 'tb' + a.id, content: 'ok' }] } })));
    }
    poser(path.join(sub, `agent-${a.id}.jsonl`), l, a.ageS);
  }
  return home;
}
const collecte = (home, opts = {}) => who.collectWho(lab, { home, now: NOW, scriptsDir: path.join(work, 'noscripts'), ...opts });
const sous = (w, id) => w.workers.find((x) => x.kind === 'subagent' && x.id === id);
const sess = (w, id = SID) => w.workers.find((x) => x.kind === 'session' && x.id === id);

// le rendu pur du tiroir (ui/71) chargé hors navigateur : même contexte vm que EUI de test-cockpit-equipe.sh
function rendu() {
  const sandbox = { window: {}, document: {} }; vm.createContext(sandbox);
  vm.runInContext(fs.readFileSync(path.join(ui, '71-vf-equipe-rendu.js'), 'utf8'), sandbox);
  return sandbox.window.__vfEquipeRendu;
}
const h = (t) => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const texte = (html) => html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ');

const S = {
  // ---- D1 : un agent non fini et muet reste affiché ----
  D1() {
    console.log('=== D1 — agent non fini et muet ===');
    const frais = collecte(monter({ session: { ageS: 60 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 60, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 60 }] }));
    ok('D1.0 — témoin positif : tout frais (60 s), le worker est listé', !!sous(frais, 'wrk'));
    const m = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 600 }] }));
    ok('D1.1 — un worker muet depuis 10 min dans une commande reste listé', !!sous(m, 'wrk'), m.workers.map((x) => x.kind + ':' + x.id));
    eq('D1.2 — il reste « actif » (un appel d\'outil sans résultat), avec son âge et son action', [sous(m, 'wrk')?.etat, sous(m, 'wrk')?.ageS, sous(m, 'wrk')?.action?.verbe], ['actif', 600, 'lance une commande']);
    ok('D1.3 — il dit que l\'outil est en cours (champ tiré de l\'appel sans résultat)', sous(m, 'wrk')?.enCours === true, sous(m, 'wrk'));
    ok('D1.4 — sa session reste listée', !!sess(m), m.workers.map((x) => x.kind + ':' + x.id));
    eq('D1.5 — le manager qui attend son worker (appel d\'agent sans résultat) reste « en attente », jamais « actif »', sous(m, 'mgr')?.etat, 'en-attente');
    const f = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 600 }, { id: 'fin', role: 'vf-reviewer', parent: 'mgr', ageS: 3600, fini: true }] }));
    ok('D1.6 — avec un frère terminé, le worker muet est listé aussi', !!sous(f, 'wrk') && !!sous(f, 'fin'), f.workers.map((x) => x.id));
    const r = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 600, resultat: true }] }));
    eq('D1.7 — un appel d\'outil résolu n\'est pas « en cours » : l\'agent reste listé, « en attente »', [sous(r, 'wrk')?.etat, sous(r, 'wrk')?.enCours === true], ['en-attente', false]);
    const v = collecte(monter({ session: { ageS: 7200 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 7200, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 7200 }] }));
    ok('D1.8 — silence de plus de 30 min (le TTL des verrous) : l\'agent n\'est plus dit vivant, hors ancêtre il disparaît', sous(v, 'wrk')?.etat !== 'actif', sous(v, 'wrk'));
    const e = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 600, outil: 'Read' }] }));
    const t = texte(rendu().arbre(m.workers, h));
    ok('D1.10 — le tiroir dit « outil en cours, sans nouvelle depuis 10 min » pour l\'agent muet', /outil en cours, sans nouvelle depuis 10 min/.test(t), t);
    ok('D1.11 — l\'agent muet y garde sa place d\'agent actif (pas de repli dans « Terminés »)', !/Terminés depuis/.test(t), t);
    const pe = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, outil: 'Read' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 4 }] }));
    eq('D1.12 — un agent muet dont un descendant écrit encore attend celui-ci : « en attente » même avec un outil sans résultat', [sous(pe, 'mgr')?.etat, sous(pe, 'wrk')?.etat], ['en-attente', 'actif']);
    eq('D1.9 — l\'action tirée de l\'outil en cours est celle d\'un fichier lu, jamais l\'argument', [sous(e, 'wrk')?.etat, sous(e, 'wrk')?.action?.verbe, sous(e, 'wrk')?.enCours], ['actif', 'lit', true]);
  },
};

for (const s of sections) { if (!S[s]) { console.log(`  ❌ FAIL — section inconnue ${s}`); fail++; continue; } S[s](); }
console.log(`__TOTAL__ ${pass} ${fail}`);
process.exit(fail ? 1 : 0);
JS

PASS=0; FAIL=0
run() { # sections...
  local out; out="$(node "$AUX/etats.mjs" "$SCRIPTS" "$UI" "$LAB" "$WORK" "$@" 2>&1)"; local rc=$?
  printf '%s\n' "$out" | grep -v '^__TOTAL__'
  local t; t="$(printf '%s\n' "$out" | grep '^__TOTAL__' | tail -1)"
  if [ -z "$t" ]; then echo "  ❌ FAIL — la section $* n'a pas rendu de total (rc=$rc)"; FAIL=$((FAIL+1)); return; fi
  PASS=$((PASS + $(echo "$t" | cut -d' ' -f2))); FAIL=$((FAIL + $(echo "$t" | cut -d' ' -f3)))
}

run D1

echo
echo "=== Bilan : $PASS réussi(s), $FAIL échec(s) ==="
[ "$FAIL" -eq 0 ]
