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
  // ---- D2 : une session de moins de 24 h reste listée, avec un état lu ----
  async D2() {
    console.log('=== D2 — sessions au repos ===');
    const t = collecte(monter({ session: { ageS: 60 } }));
    eq('D2.0 — témoin : une session écrite il y a 60 s est « actif »', sess(t)?.etat, 'actif');
    const r = collecte(monter({ session: { ageS: 300 } }));
    eq('D2.1 — une session au repos depuis 5 min reste listée, « au-repos »', sess(r)?.etat, 'au-repos');
    eq('D2.2 — au repos depuis 3 h : listée aussi', sess(collecte(monter({ session: { ageS: 10800 } })))?.etat, 'au-repos');
    ok('D2.3 — écrite il y a 25 h : hors fenêtre, absente', !sess(collecte(monter({ session: { ageS: 90000 } }))));
    const fin = collecte(monter({ session: { ageS: 900 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 900, fini: true }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 900, fini: true }] }));
    eq('D2.4 — une session au repos dont les agents ont fini n\'est JAMAIS dite « terminé »', sess(fin)?.etat, 'au-repos');
    const att = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 20 }] }));
    eq('D2.5 — une session dont un agent écrit encore reste « en-attente »', sess(att)?.etat, 'en-attente');
    eq('D2.6 — une session seulement au repos ne rend pas la collecte « busy »', collecte(monter({ session: { ageS: 300 } })).busy, false);
    const g = carte.buildEquipeGraph(r, {}), nd = g.nodes.find((x) => x.id === 'se-' + SID);
    ok('D2.7 — la carte de la session au repos dit « au repos » et n\'a pas la pastille « En cours »', !!nd && /État : au repos/.test(nd.details) && nd.st === undefined, nd);
    eq('D2.8 — le compte de la carte sépare les sessions au repos', [g.meta.vf.compte.actif, g.meta.vf.compte.auRepos], [0, 1]);
    const rd = rendu();
    ok('D2.9 — le tiroir écrit « au repos » (mot) pour la session', /au repos/.test(texte(rd.arbre(r.workers, h))), texte(rd.arbre(r.workers, h)));
    ok('D2.10 — « au repos » n\'est pas un agent actif (effectifs, badge)', rd.actif(sess(r)) === false);
    // état officiel (enrichissement optionnel) : faux `claude` sur le chemin de recherche
    const officiel = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-etat-officiel.mjs')).href);
    const bin = path.join(work, 'bin'); fs.mkdirSync(bin, { recursive: true });
    const marque = path.join(work, 'appels.txt');
    fs.writeFileSync(path.join(bin, 'claude'), '#!/bin/sh\necho "$@" >> "$VF_FAKE_MARK"\n[ -n "$VF_FAKE_SORTIE" ] && printf "%s" "$VF_FAKE_SORTIE"\nexit "${VF_FAKE_RC:-0}"\n', { mode: 0o755 });
    process.env.PATH = bin + path.delimiter + process.env.PATH; process.env.VF_FAKE_MARK = marque;
    const cas = async (sortie, rc, age) => { process.env.VF_FAKE_SORTIE = sortie; process.env.VF_FAKE_RC = String(rc); const home = monter({ session: { ageS: age } }); await officiel.rafraichir({ home, cwd: lab }); return collecte(home, { officiel: true }); };
    const entree = (o) => JSON.stringify([{ sessionId: SID, kind: 'interactive', pid: 1, cwd: lab, ...o }]);
    const home0 = monter({ session: { ageS: 300 } }); process.env.VF_FAKE_SORTIE = entree({ status: 'waiting' }); process.env.VF_FAKE_RC = '0';
    eq('D2.11 — avant toute lecture asynchrone, la collecte ne bloque pas et garde la lecture des transcripts', sess(collecte(home0, { officiel: true }))?.etat, 'au-repos');
    eq('D2.12 — status « waiting » : la session « vous attend »', sess(await cas(entree({ status: 'waiting' }), 0, 300))?.etat, 'attend');
    eq('D2.13 — status « busy » : « actif » même avec un transcript muet', sess(await cas(entree({ status: 'busy' }), 0, 900))?.etat, 'actif');
    eq('D2.14 — status « idle » : « au-repos » même avec un transcript frais', sess(await cas(entree({ status: 'idle' }), 0, 20))?.etat, 'au-repos');
    eq('D2.15 — state « done » : la session est close (« termine »)', sess(await cas(entree({ state: 'done' }), 0, 300))?.etat, 'termine');
    eq('D2.16 — commande en échec : lecture des transcripts', sess(await cas('', 1, 300))?.etat, 'au-repos');
    eq('D2.17 — sortie illisible : lecture des transcripts', sess(await cas('pas du json', 0, 300))?.etat, 'au-repos');
    eq('D2.18 — forme inattendue (un objet, pas une liste) : lecture des transcripts', sess(await cas('{"sessionId":"x","status":"waiting"}', 0, 300))?.etat, 'au-repos');
    eq('D2.19 — un état inconnu est ignoré : lecture des transcripts', sess(await cas(entree({ status: 'inventé' }), 0, 300))?.etat, 'au-repos');
    fs.rmSync(marque, { force: true });
    collecte(monter({ session: { ageS: 300 } }));
    ok('D2.20 — sans l\'option officiel, la commande n\'est jamais lancée', !fs.existsSync(marque));
  },
  // ---- D4 : un worker vivant sous un manager terminé est orphelin ----
  D4() {
    console.log('=== D4 — orphelin ===');
    const vif = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 30 }] }));
    ok('D4.0 — témoin : sous un manager vivant (muet), le worker n\'est pas orphelin', !!sous(vif, 'wrk') && sous(vif, 'wrk').orphan !== true, sous(vif, 'wrk'));
    const o = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, fini: true }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 30 }] }));
    eq('D4.1 — un worker vivant sous un manager terminé est « orphelin » dans la collecte', [sous(o, 'wrk')?.etat, sous(o, 'wrk')?.orphan], ['actif', true]);
    ok('D4.2 — le manager terminé n\'est pas orphelin', sous(o, 'mgr')?.orphan !== true);
    const ft = collecte(monter({ session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, fini: true }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 700, fini: true }] }));
    ok('D4.3 — un worker terminé sous un manager terminé n\'est pas orphelin', sous(ft, 'wrk')?.orphan !== true && !!sous(ft, 'wrk'));
    const g = carte.buildEquipeGraph(o, {}), nd = g.nodes.find((x) => x.id === 'ag-wrk');
    ok('D4.4 — sur la carte, le worker orphelin n\'est pas rangé sous « Terminés » : son parent est la session', !!nd && nd.parent === 'se-' + SID, nd?.parent);
    ok('D4.5 — la carte le nomme « orphelin » (détail et résumé)', !!nd && /Orphelin/.test(nd.details) && /^Orphelin/.test(nd.summary), nd);
    const t = texte(rendu().arbre(o.workers, h));
    ok('D4.6 — le tiroir le nomme « orphelin ? »', /orphelin \?/.test(t) && !/Terminés depuis/.test(t), t);
  },
};

for (const s of sections) { if (!S[s]) { console.log(`  ❌ FAIL — section inconnue ${s}`); fail++; continue; } await S[s](); }
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

run D1 D2 D4

echo
echo "=== Bilan : $PASS réussi(s), $FAIL échec(s) ==="
[ "$FAIL" -eq 0 ]
