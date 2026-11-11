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
  // ---- D3 : « À surveiller » et « commande en cours depuis 15 min » de bout en bout ; l'âge avance dans la page ----
  D3() {
    console.log('=== D3 — alerte de silence ===');
    const un = (ageS, outil) => collecte(monter({ session: { ageS }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS, outil }] }));
    const rd = rendu();
    const c = un(1000, 'Bash');
    const tc = texte(rd.surveiller(c.workers) + rd.arbre(c.workers, h));
    ok('D3.1 — collecteur réel : un worker muet 1 000 s dans une commande déclenche « commande en cours depuis plus de 15 min »', /À surveiller.*1 commande en cours depuis plus de 15 min/.test(tc), tc);
    ok('D3.2 — et sa ligne dit « commande en cours, sans nouvelle depuis 17 min »', /commande en cours, sans nouvelle depuis 17 min/.test(tc), tc);
    const m = un(200, 'Read');
    ok('D3.3 — collecteur réel : muet 200 s hors commande : « À surveiller · 1 agent sans nouvelle depuis plus de 2 min »', /À surveiller.*1 agent sans nouvelle depuis plus de 2 min/.test(texte(rd.surveiller(m.workers))), texte(rd.surveiller(m.workers)));
    ok('D3.4 — témoin : un worker qui écrit (30 s) ne déclenche rien', rd.surveiller(un(30, 'Bash').workers) === '');
    // l'âge avance entre deux poussées : la page le recalcule depuis la réception du dernier `who`
    const vive = (ecouleS, ageS) => { const sb = { window: { __vfLive: { whoAt: Date.now() - ecouleS * 1000 } }, document: {} }; vm.createContext(sb); vm.runInContext(fs.readFileSync(path.join(ui, '71-vf-equipe-rendu.js'), 'utf8'), sb); return sb.window.__vfEquipeRendu; };
    const w = [{ kind: 'subagent', id: 'a', etat: 'actif', tree: '.', role: 'vf-coder', task: 'x', ageS: 60, dureeS: 100, action: { verbe: 'lance une commande', cible: '' } }];
    eq('D3.5 — témoin : sans temps écoulé, un agent à 60 s n\'est pas à surveiller', vive(0).surveiller(w), '');
    const v = vive(960);
    ok('D3.6 — 16 min après la réception, le même agent est « commande en cours depuis plus de 15 min » sans nouveau `who`', /commande en cours depuis plus de 15 min/.test(texte(v.surveiller(w))), texte(v.surveiller(w)));
    ok('D3.7 — son âge affiché a avancé (17 min), la durée « depuis » aussi', /sans nouvelle depuis 17 min/.test(texte(v.arbre(w, h))) && /depuis 18 min/.test(texte(v.arbre(w, h))), texte(v.arbre(w, h)));
    ok('D3.8 — un terminé ne vieillit pas dans la page', /a duré 2 min/.test(texte(vive(960).arbre([{ kind: 'subagent', id: 'b', etat: 'termine', tree: '.', role: 'vf-coder', task: 'y', ageS: 60, dureeS: 120 }], h))));
  },
  // ---- M3 : le titre de la vue Équipe est vrai, la santé d'Équipe ne contredit plus celle de Code ----
  M3() {
    console.log('=== M3 — titre et santé de la vue Équipe ===');
    const rd = rendu();
    const t = (M, c) => (typeof rd.titreEquipe === 'function' ? rd.titreEquipe(M, c) : '(titreEquipe absent)');
    eq('M3.1 — sept agents actifs, aucune mission : « 7 agents actifs », jamais « Aucune mission en cours »', t([], { actif: 7 }), '7 agents actifs');
    eq('M3.2 — un seul agent actif : « 1 agent actif »', t([], { actif: 1 }), '1 agent actif');
    eq('M3.3 — personne ni mission : « Aucune mission en cours » reste vrai', t([], { actif: 0 }), 'Aucune mission en cours');
    eq('M3.4 — une mission : le titre la nomme (PU-G-166 inchangé)', t(['Phase 73'], { actif: 3 }), 'Mission : Phase 73');
    eq('M3.5 — deux missions : « 2 missions en cours » (PU-G-166 inchangé)', t(['a', 'b'], { actif: 3 }), '2 missions en cours');
    const w = collecte(monter({ session: { ageS: 20 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 20, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 5 }] }));
    const g = carte.buildEquipeGraph(w, {});
    eq('M3.6 — de bout en bout (collecteur réel puis carte) : le titre dit le nombre d\'agents actifs', t([], g.meta.vf.compte), '3 agents actifs');
    const l = typeof rd.ligneAgents === 'function' ? rd.ligneAgents({ actif: 0, enAttente: 0, auRepos: 2, attend: 1, termine: 4 }) : '(absent)';
    ok('M3.7 — la ligne des agents dit aussi ceux qui vous attendent et ceux au repos', /1 vous attend/.test(l) && /2 au repos/.test(l), l);
    // santé : sur l'onglet Équipe, le bloc « Santé » du panneau (contrôle du CODE) est retiré, comme sur le Projet (DG-15)
    const src = fs.readFileSync(path.join(ui, '00-vibeflow.js'), 'utf8');
    const ligneEquipe = src.split('\n').find((x) => x.includes("TAB === 'equipe') style.textContent += '#btn-health")) || '';
    ok('M3.8 — la feuille de l\'onglet Équipe masque le bloc « Santé » du panneau (lignes de Code non analysées ici)', ligneEquipe.includes('#panel .sec:has(> .list > a[data-hc-open]) { display: none; }'), ligneEquipe);
  },
  // ---- D2b : « close » par absence d'une liste officielle lue ; câblage par le chemin réel du serveur ; environnement de l'enfant ----
  async D2b() {
    console.log('=== D2b — état officiel : absence, chemin réel du serveur, environnement ===');
    const officiel = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-etat-officiel.mjs')).href);
    const bin = path.join(work, 'bin2'); fs.mkdirSync(bin, { recursive: true });
    const marque = path.join(work, 'appels2.txt');
    fs.writeFileSync(path.join(bin, 'claude'), '#!/bin/sh\necho "$@" >> "$VF_FAKE_MARK"\n[ -n "$VF_FAKE_SORTIE" ] && printf "%s" "$VF_FAKE_SORTIE"\nexit "${VF_FAKE_RC:-0}"\n', { mode: 0o755 });
    const PATH0 = process.env.PATH;
    process.env.PATH = bin + path.delimiter + PATH0; process.env.VF_FAKE_MARK = marque; process.env.VF_FAKE_RC = '0';
    const autre = JSON.stringify([{ sessionId: '22222222-2222-4222-8222-222222222222', kind: 'interactive', pid: 2, cwd: lab, status: 'idle' }]);
    const cas = async (sortie, rc, spec) => { process.env.VF_FAKE_SORTIE = sortie; process.env.VF_FAKE_RC = String(rc); const home = monter(spec); await officiel.rafraichir({ home, cwd: lab }); return collecte(home, { officiel: true }); };
    eq('D2b.1 — une liste officielle lue sans cette session : elle est close (« termine »)', sess(await cas(autre, 0, { session: { ageS: 300 } }))?.etat, 'termine');
    eq('D2b.2 — une liste officielle VIDE lue avec succès : close aussi', sess(await cas('[]', 0, { session: { ageS: 300 } }))?.etat, 'termine');
    eq('D2b.3 — mais jamais une session écrite il y a 20 s (elle peut être hors liste, par exemple lancée sans terminal)', sess(await cas(autre, 0, { session: { ageS: 20 } }))?.etat, 'actif');
    eq('D2b.4 — ni une session dont un agent écrit encore', sess(await cas(autre, 0, { session: { ageS: 600 }, agents: [{ id: 'mgr', role: 'vf-dev-manager', ageS: 600, outil: 'Agent' }, { id: 'wrk', role: 'vf-coder', parent: 'mgr', ageS: 20 }] }))?.etat, 'en-attente');
    eq('D2b.5 — commande en échec : jamais « close », lecture des transcripts', sess(await cas('', 1, { session: { ageS: 300 } }))?.etat, 'au-repos');
    eq('D2b.6 — liste de forme inattendue (un objet) : jamais « close »', sess(await cas('{"sessions":[]}', 0, { session: { ageS: 300 } }))?.etat, 'au-repos');
    const renomme = JSON.stringify([{ pid: 1, kind: 'interactive', session_id: SID, status: 'busy' }]);
    eq('D2b.10 — liste non vide dont la clé de session est renommée (dérive de format) : illisible, jamais « close »', sess(await cas(renomme, 0, { session: { ageS: 300 } }))?.etat, 'au-repos');
    eq('D2b.11 — liste non vide à identifiant invalide : illisible, jamais « close »', sess(await cas(JSON.stringify([{ sessionId: '../x', status: 'idle' }]), 0, { session: { ageS: 300 } }))?.etat, 'au-repos');
    eq('D2b.12 — une entrée illisible parmi des entrées lisibles rend toute la liste illisible', sess(await cas(JSON.stringify([JSON.parse(autre)[0], { pid: 3 }]), 0, { session: { ageS: 300 } }))?.etat, 'au-repos');
    // AUDC-D2 : un même identifiant listé deux fois avec des états contradictoires — un état vivant n'est jamais écrasé par « termine », quel que soit l'ordre
    const dbl = (...o) => officiel.formeEtats(o.map((x) => ({ sessionId: SID, kind: 'interactive', pid: 1, cwd: lab, ...x })));
    const lu = (m) => (m && m.has(SID) ? m.get(SID).etat : 'absente');
    eq('D2b.13 — « terminé » puis « occupé » (et l\'inverse) : vivante, « actif » dans les deux ordres', [lu(dbl({ state: 'done' }, { status: 'busy' })), lu(dbl({ status: 'busy' }, { state: 'done' }))], ['actif', 'actif']);
    eq('D2b.14 — « terminé » et « vous attend » : « attend » dans les deux ordres', [lu(dbl({ state: 'done' }, { status: 'waiting' })), lu(dbl({ status: 'waiting' }, { state: 'done' }))], ['attend', 'attend']);
    eq('D2b.15 — « terminé » et « au repos » : « au-repos » dans les deux ordres', [lu(dbl({ state: 'done' }, { status: 'idle' })), lu(dbl({ status: 'idle' }, { state: 'done' }))], ['au-repos', 'au-repos']);
    eq('D2b.16 — « terminé » et un état inconnu (vivante, sans état) : jamais « termine », dans les deux ordres', [lu(dbl({ state: 'done' }, {})), lu(dbl({}, { state: 'done' }))].map((x) => x !== 'termine'), [true, true]);
    eq('D2b.17 — témoins : « terminé » seul ou doublé reste « termine » ; deux entrées vivantes, la dernière gagne', [lu(dbl({ state: 'done' })), lu(dbl({ state: 'done' }, { state: 'stopped' })), lu(dbl({ status: 'busy' }, { status: 'idle' }))], ['termine', 'termine', 'au-repos']);
    // chemin réel du serveur : startLive -> whoNow doit demander l'état officiel (un test par collectWho seul ne voit pas le câblage)
    fs.rmSync(marque, { force: true });
    const homeLive = monter({ session: { ageS: 300 } }); process.env.HOME = homeLive; process.env.VF_FAKE_SORTIE = autre;
    const live = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-live.mjs')).href);
    const sortie = path.join(work, 'sortie'); fs.mkdirSync(sortie, { recursive: true });
    let h0 = null; try { h0 = live.startLive({ root: lab, sortie, mode: 'poll' }); } catch (e) { console.log('     startLive : ' + e.message); }
    for (let i = 0; i < 30 && !fs.existsSync(marque); i++) await new Promise((r) => setTimeout(r, 100));
    ok('D2b.7 — le serveur (startLive, chemin réel de whoNow) demande l\'état officiel à `claude agents --json`', fs.existsSync(marque) && /agents --json/.test(fs.readFileSync(marque, 'utf8')), fs.existsSync(marque));
    h0?.stop();
    // environnement de l'enfant : un `claude` posé dans le lab n'est jamais exécuté, même si le PATH le désigne (audit H-1)
    const piege = path.join(lab, 'claude'), piegeMarque = path.join(work, 'piege.txt');
    fs.writeFileSync(piege, '#!/bin/sh\necho appele > "' + piegeMarque + '"\n', { mode: 0o755 });
    process.env.PATH = lab + path.delimiter + bin + path.delimiter + PATH0; fs.rmSync(marque, { force: true });
    await cas(autre, 0, { session: { ageS: 300 } });
    ok('D2b.8 — témoin : le claude du chemin sûr est bien lancé', fs.existsSync(marque));
    ok('D2b.9 — l\'enfant est lancé avec un PATH assaini : le programme posé dans le lab n\'est jamais exécuté', !fs.existsSync(piegeMarque));
    fs.rmSync(piege, { force: true }); process.env.PATH = PATH0;
  },
  // ---- D3b : l'âge avance dans les pieds de carte et le panneau de l'onglet Équipe sans nouveau who ----
  async D3b() {
    console.log('=== D3b — minuterie de l\'onglet Équipe ===');
    const minuteries = []; let rerendus = 0, sections = null;
    const G = { meta: { vfTab: 'equipe', vf: {} }, project: { name: 'P' }, nodes: [{ id: 'ag-a', foot: '' }] };
    const SC = { graph: G, h, exists: () => false, on() {}, setOverview() {}, addPanelSection(_, f) { sections = f; }, rerender: async () => { rerendus++; }, fit() {}, reveal() {}, plafond() {} };
    const sb = { window: { Floorplan: SC, FLOORPLAN_SERVER: {}, __vfLive: {} }, document: { getElementById: () => null, querySelector: () => null, querySelectorAll: () => [], addEventListener() {}, hidden: false, documentElement: {} }, location: { hash: '' }, sessionStorage: { getItem: () => null, setItem() {}, removeItem() {} },
      MutationObserver: class { observe() {} }, setInterval: (f, ms) => { minuteries.push([f, ms]); return 1; }, setTimeout, fetch: async () => ({ ok: false }), console };
    vm.createContext(sb);
    vm.runInContext(fs.readFileSync(path.join(ui, '71-vf-equipe-rendu.js'), 'utf8'), sb);
    vm.runInContext(fs.readFileSync(path.join(ui, '72-vf-equipe.js'), 'utf8'), sb);
    ok('D3b.1 — l\'onglet Équipe arme une minuterie de recalcul', minuteries.length >= 1, minuteries.length);
    const w = { kind: 'subagent', id: 'a', etat: 'actif', tree: '.', role: 'vf-coder', task: 'x', ageS: 60, dureeS: 100 };
    sb.window.__vfLive = { who: { workers: [w] }, whoAt: Date.now() - 600000 };
    for (const [f] of minuteries) await f();
    ok('D3b.2 — le pied de la carte a avancé sans nouveau who (10 min de plus)', /dernière activité il y a 11 min|au travail depuis 12 min/.test(G.nodes[0].foot), G.nodes[0].foot);
    ok('D3b.3 — la vue est redessinée', rerendus >= 1, rerendus);
    const panneau = sections ? sections('n:ag-a') : '';
    ok('D3b.4 — la ligne « Activité » du panneau porte le même âge avancé', /au travail depuis 12 min/.test(texte(panneau)), texte(panneau));
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

run D1 D2 D2b D4 D3 D3b M3

echo
echo "=== Bilan : $PASS réussi(s), $FAIL échec(s) ==="
[ "$FAIL" -eq 0 ]
