# regie-rg-collecte.sh — fragment du plan 73-03, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) : champs de gouvernance de who@2 (P73-D-35).
#   RG4_collecte · RG4_direct (À vous : phases à vérification humaine lues une fois par reconstruction, REGI-04) · RG5_collecte (détention et impact, REGI-05)
#   RG6_collecte (aucun champ brut du verrou, REGI-06) · RG7_collecte (fenêtre de stall, REGI-07) · RG9_direct (âge frais au hello, REGI-09)
#   RG10_collecte (« attend ses agents », REGI-10) · RG16_collecte · RG16_direct (nettoyage à l'émission, contrat et signature, REGI-16).
# Mutants (une assertion chacun, M-<NOM>) : seulement pour une garde qui filtre ce que who@2 expose (détention brute, nettoyage à l'émission).
# Fixtures : noms inventés, identifiants de session en UUID inventés, aucun chemin de poste ; verrou RÉEL posé par le driver-lock.sh du dépôt dans un dépôt git jetable.

RGC_SID="3f2c9a10-5b7e-4c1d-9a2e-0d4f6b8c1e77"
rgc_conducteur() { (cd "$SCRIPTS/../../conductor/scripts" && pwd); }

# harnais Node (créé une fois) : rgc.mjs <scripts> <scénario> <dossier de travail> [arg…]
rgc_outils() {
  [ -f "$AUX/rgc.mjs" ] && return 0
  cat > "$AUX/rgc.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
const [, , scripts, sc, work0, a1, a2] = process.argv;
fs.mkdirSync(work0, { recursive: true });
const work = fs.realpathSync(work0), home = process.env.HOME;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const sleep = (ms) => new Promise((k) => setTimeout(k, ms));
const U = (n) => `${String(n).repeat(8)}-${String(n).repeat(4)}-4${String(n).repeat(3)}-8${String(n).repeat(3)}-${String(n).repeat(12)}`;
const SID = '3f2c9a10-5b7e-4c1d-9a2e-0d4f6b8c1e77';
const git = (d, ...a) => execFileSync('git', ['-C', d, ...a], { stdio: 'ignore' });
const L = (d, id, o) => JSON.stringify({ cwd: d, sessionId: id, gitBranch: 'main', version: '2.1.316', ...o });
const HUMAIN = '---\nstatus: human_needed\n---\ncorps\n';
function transcript(f, d, id, ageS, { tail = [], titre } = {}) {
  fs.mkdirSync(path.dirname(f), { recursive: true });
  const l = [L(d, id, { type: 'user', timestamp: '2026-11-01T11:59:00Z', message: { content: 'salut' } }),
    L(d, id, { type: 'assistant', timestamp: '2026-11-01T11:59:05Z', message: { content: [{ type: 'tool_use', name: 'Bash', input: { description: 'ls', command: 'ls' } }] } })];
  if (titre !== undefined) l.push(JSON.stringify({ type: 'custom-title', customTitle: titre, sessionId: id }));
  fs.writeFileSync(f, [...l, ...tail].join('\n') + '\n');
  const t = Date.now() / 1000 - ageS; fs.utimesSync(f, t, t);
}
const turn = (id, n) => JSON.stringify({ type: 'system', subtype: 'turn_duration', durationMs: 1000, pendingBackgroundAgentCount: n, timestamp: '2026-11-01T11:59:09Z', sessionId: id });
function sub(nom, sid, aid, o = {}) {
  const sd = path.join(home, '.claude', 'projects', '-' + nom, sid, 'subagents'), a = path.join(sd, `agent-${aid}`), d = path.join(work, nom);
  fs.mkdirSync(sd, { recursive: true });
  fs.writeFileSync(a + '.meta.json', JSON.stringify({ agentType: 'vf-coder', description: 'tâche', spawnDepth: 1, toolUseId: 'toolu_x', requestShape: 'background' }));
  transcript(a + '.jsonl', d, sid, 30, o);
  const l = fs.readFileSync(a + '.jsonl', 'utf8').split('\n'); l[0] = l[0].replace(/^\{/, `{"isSidechain":true,"agentId":"${aid}",`); fs.writeFileSync(a + '.jsonl', l.join('\n'));
  const t = Date.now() / 1000 - 30; fs.utimesSync(a + '.jsonl', t, t);
}
// lab de fixture : plat (ROADMAP à cases) ou partitionné (compartiment alpha) ; phases 7 (non cochée) et 8 (cochée) ; VERIFICATION human_needed si `verif`
function lab(nom, { ws = false, verif = false, dag = false, branche = 'main', sessions = [] } = {}) {
  const d = path.join(work, nom); fs.mkdirSync(d, { recursive: true });
  git(d, 'init', '-q'); git(d, 'symbolic-ref', 'HEAD', 'refs/heads/' + branche);
  const plan = ws ? path.join(d, '.planning', 'workstreams', 'alpha') : path.join(d, '.planning');
  fs.mkdirSync(plan, { recursive: true });
  fs.writeFileSync(path.join(plan, 'ROADMAP.md'), '- [ ] **Phase 7: Alpha**\n- [x] **Phase 8: Beta**\n');
  for (const [n, slug] of [['7', 'alpha'], ['8', 'beta']]) {
    const pd = path.join(plan, 'phases', `${n}-${slug}`); fs.mkdirSync(pd, { recursive: true });
    if (verif) fs.writeFileSync(path.join(pd, `${n}-VERIFICATION.md`), HUMAIN);
  }
  if (dag) {
    fs.mkdirSync(path.join(d, '.planning', 'missions'), { recursive: true });
    const N = (id, deps, status) => ({ id, deps, status });
    fs.writeFileSync(path.join(d, '.planning', 'missions', 'MISSION-7.dag.json'), JSON.stringify({ name: 'MISSION-7', ws: ws ? 'alpha' : undefined, phase: '7',
      nodes: [N('n1', [], 'done'), N('n2', ['n1'], 'done'), N('n3', ['n2'], 'ready'), N('n4', ['n3'], 'ready'), N('n5', ['n4'], 'blocked'), N('n6', [], 'ready')] }));
  }
  for (const s of sessions) transcript(path.join(home, '.claude', 'projects', '-' + nom, s.id + '.jsonl'), d, s.id, s.ageS, s);
  return d;
}
// gouvernance de test : les phases lues par readPlanning et phasesHumaines() du module, sans passer par le code livré du fil de collecte
async function gov(d) {
  const { readPlanning } = await imp('vf-cockpit-planning.mjs'), gm = await imp('vf-cockpit-gouvernance.mjs');
  const P = readPlanning(d, undefined, { sansTags: true });
  const dir = (cle) => { const p = P.phases.get(cle); return P.phaseDirs.get(`${p.ws || ''}|${p.n}`) || P.phaseDirs.get(`*|${p.n}`); };
  const ph = gm.phasesHumaines({ phases: P.phases, fichiers: (cle) => fs.readdirSync(dir(cle)), lire: (cle, f) => fs.readFileSync(path.join(dir(cle), f), 'utf8') });
  return { phases: P.phases, phasesHumaines: ph };
}
const collecte = async (d, o = {}) => (await imp('vf-cockpit-who.mjs')).collectWho(d, { home, scriptsDir: path.join(work, 'noscripts'), ...o });
const session = (w, id) => w.workers.find((x) => x.kind === 'session' && x.id === id);
const SC = {
  rg4: async () => { const d = lab('rg4', { verif: a1 === '1' }); const w = await collecte(d, { gouvernance: await gov(d) }); return 'phasesHumaines' in w ? JSON.stringify(w.phasesHumaines.map((p) => p.phase)) : 'absent'; },
  fabrique5: async () => { lab('lab', { ws: true, verif: true, dag: a1 === '1', sessions: [{ id: SID, ageS: 3600 }] }); return 'ok'; },
  collecte5: async () => {
    const d = path.join(work, 'lab'); const w = await collecte(d, { scriptsDir: a1, gouvernance: await gov(d) });
    fs.writeFileSync(path.join(work, 'who.json'), JSON.stringify(w)); const s = session(w, SID);
    return JSON.stringify({ detient: s?.detient, retient: s?.retient });
  },
  fenetre: async () => {
    if (a2) process.env.VF_STALL_WINDOW = a2; else delete process.env.VF_STALL_WINDOW;
    const d = lab('rg7'); const w = await collecte(d, { scriptsDir: a1 }); return 'fenetreStallS' in w ? String(w.fenetreStallS) : 'absent';
  },
  rg10: async () => {
    const d = lab('rg10', { sessions: [{ id: U(1), ageS: 3600, tail: [turn(U(1), 2)] }, { id: U(2), ageS: 60, tail: [turn(U(2), 2)] }, { id: U(3), ageS: 3600 }] });
    sub('rg10', U(1), 'agent7', { tail: [turn(U(1), 2)] });
    const w = await collecte(d), v = (x) => (x && 'attendAgents' in x ? String(x.attendAgents) : 'absent');
    return `a:${v(session(w, U(1)))}|sub:${v(w.workers.find((x) => x.kind === 'subagent'))}|actif:${v(session(w, U(2)))}|c:${v(session(w, U(3)))}`;
  },
  rg16: async () => {
    const d = lab('rg16', { branche: 'feat/‮evil​x', sessions: [{ id: U(1), ageS: 60, titre: 'Mon\u0007 chan‮tier​' }] });
    const s = session(await collecte(d), U(1)), sale = /[\u0000-\u001f\u007f-\u009f‮​]/;
    return `branch:${typeof s.branch === 'string' && s.branch.includes('feat/') && !sale.test(s.branch) ? 'propre' : 'sale ' + JSON.stringify(s.branch)}|titre:${typeof s.titre === 'string' && s.titre.includes('Mon') && !sale.test(s.titre) ? 'propre' : 'sale ' + JSON.stringify(s.titre)}`;
  },
  contrat: async () => {
    const c = JSON.parse(fs.readFileSync(path.join(scripts, 'vf-cockpit-interface.json'), 'utf8')).schemas;
    const w = c['vibeflow/cockpit-who@2'], a = c['vibeflow/cockpit-ailleurs@1'];
    if (a1 === '11') return JSON.stringify(['phasesHumaines', 'fenetreStallS'].filter((k) => !(w.optionnels || []).includes(k)).concat(['attendAgents', 'lancee', 'detient', 'retient'].filter((k) => !(w.travailleur.optionnels || []).includes(k))));
    if (a1 === '12') return a ? JSON.stringify({ entree: a.entree?.requis, cwd: (a.interdits || []).includes('cwd'), requis: Object.keys(a.requis || {}) }) : 'absent';
    const who = JSON.parse(fs.readFileSync(a2, 'utf8')), ok = new Set([...Object.keys(w.requis), ...(w.optionnels || []), 'schema']), okw = new Set([...w.travailleur.requis, ...w.travailleur.optionnels]);
    return JSON.stringify([...Object.keys(who).filter((k) => !ok.has(k)), ...who.workers.flatMap((x) => Object.keys(x).filter((k) => !okw.has(k)).map((k) => `${x.kind}.${k}`))]);
  },
  sigs: async () => {
    const { whoSig } = await imp('vf-cockpit-live.mjs');
    const base = () => ({ at: 'x', fenetre: 1, workers: [{ kind: 'session', id: 's', ageS: 5, etat: 'au-repos', orphan: false, attendAgents: 1, lancee: { phase: '7', verbe: 'cadrer' }, detient: { ws: 'a', phase: '7' }, retient: { n: 1, portee: 'noeuds' } }],
      phasesHumaines: [{ phase: '7', ws: '' }], fenetreStallS: 900 });
    const S = whoSig(base()), v = (f) => { const x = base(); f(x); return whoSig(x) !== S; };
    const champs = [(x) => { x.workers[0].attendAgents = 2; }, (x) => { x.workers[0].lancee.verbe = 'planifier'; }, (x) => { x.workers[0].detient.phase = '8'; }, (x) => { x.workers[0].retient.n = 2; },
      (x) => { x.workers[0].orphan = true; }, (x) => { x.phasesHumaines[0].phase = '9'; }, (x) => { x.fenetreStallS = 600; }];
    return `champs:${champs.map(v).join(',')}|age:${v((x) => { x.workers[0].ageS = 999; x.at = 'y'; }) ? 'differe' : 'egal'}`;
  },
  direct: async () => {
    const d = lab('direct', { verif: true, sessions: [{ id: SID, ageS: 3600 }] }); const sortie = path.join(d, '.vibeflow', 'cockpit'); fs.mkdirSync(sortie, { recursive: true });
    const { startLive } = await imp('vf-cockpit-live.mjs');
    const live = startLive({ root: d, sortie, mode: 'poll', garde: () => true });
    const age = () => live.snapshot().who.workers.find((x) => x.kind === 'session' && x.id === SID)?.ageS;
    for (let i = 0; i < 200 && age() === undefined; i++) await sleep(100);
    await live.pret(10000);
    const c0 = live.etat().lecturesPlanning, age1 = age();
    await sleep(11500); // deux tours du filet (5 s) sans aucun changement de .planning/
    const c1 = live.etat().lecturesPlanning, age2 = age(), ph = live.snapshot().who.phasesHumaines;
    fs.writeFileSync(path.join(d, '.planning', 'phases', '7-alpha', '7-NOTE.md'), 'note\n');
    let c2 = c1; for (let i = 0; i < 100 && !(c2 > c1); i++) { await sleep(100); c2 = live.etat().lecturesPlanning; }
    live.stop(); return JSON.stringify({ c0, c1, c2, age1, age2, ph });
  },
};
console.log(await SC[sc]());
process.exit(0);
JS
}
rgc() { local sc="$1" d="$2"; shift 2; rgc_outils; mkdir -p "$WORK/noscripts"; node "$AUX/rgc.mjs" "${RGC_SCRIPTS:-$SCRIPTS}" "$sc" "$d" "$@" 2>&1; }

# lab du verrou : verrou RÉEL de la phase 7 du compartiment alpha, tenu par la session de fixture (CLAUDE_CODE_SESSION_ID donne session_ids) ; $1 = dossier, $2 = 1 si un DAG rattaché
rgc_verrou() {
  local d="$WORK/$1"; rgc fabrique5 "$d" "$2" > /dev/null
  ( cd "$d/lab" && CLAUDE_CODE_SESSION_ID="$RGC_SID" bash "$(rgc_conducteur)/driver-lock.sh" acquire --ws=alpha --phase=7 --owner=mgr-7 --step=exec > /dev/null 2>&1 )
}
rgc_verrou_pose() { find "$WORK/$1/lab/.git/vf-driver/ws/alpha/phases/7" -name 'DRIVER.lock' 2> /dev/null | grep -c .; }
rgc_prepare5() { [ -f "$WORK/rg5-a/who.json" ] && return 0; rgc_verrou rg5-a 1; rgc collecte5 "$WORK/rg5-a" "$(rgc_conducteur)" > "$WORK/rg5-a.out"; }

# ---------- RG4 — phases à vérification humaine : collecte (REGI-04, A1) ----------
rg_RG4_collecte() {
  assert_eq "RG4.10 — phase 7 non cochée et phase 8 cochée, VERIFICATION human_needed dans les deux : who.phasesHumaines ne liste que la phase « 7 » (A1)" "$(rgc rg4 "$WORK/rg4-a" 1)" '["7"]'
  assert_eq "RG4.11 — aucune VERIFICATION concernée : la clé phasesHumaines est absente" "$(rgc rg4 "$WORK/rg4-b" 0)" 'absent'
}

# ---------- RG4_direct — planning de gouvernance lu une fois par reconstruction (REGI-04) ----------
# faux `claude` en tête du PATH (sortie 1) : aucun vrai appel, l'état officiel reste absent et l'état des sessions ne change pas en cours de mesure
rgc_faux_claude() { mkdir -p "$WORK/fakebin"; printf '#!/bin/sh\nexit 1\n' > "$WORK/fakebin/claude"; chmod +x "$WORK/fakebin/claude"; }
rgc_direct() { [ -f "$WORK/direct.json" ] && return 0; rgc_faux_claude; PATH="$WORK/fakebin:$PATH" rgc direct "$WORK/rgd" > "$WORK/direct.json"; }
rg_RG4_direct() {
  rgc_direct
  assert_eq "RG4.12 — etat() expose un compteur de lectures du planning : 1 après la construction initiale et deux tours de 5 s, 2 après une écriture dans .planning/" "$(G "$WORK/direct.json" '[j.c1, j.c2]' 2> /dev/null)" '[1,2]'
  assert_eq "RG4.13 — snapshot().who.phasesHumaines : une seule entrée, phase « 7 », ref « n:ph-7 »" "$(G "$WORK/direct.json" 'j.ph.map(p => p.phase + "/" + p.ref)' 2> /dev/null)" '["7/n:ph-7"]'
}

# ---------- RG5 — détention et impact dans who@2 (REGI-05) ----------
rg_RG5_collecte() {
  rgc_verrou rg5-a 1; rgc_verrou rg5-b 0
  assert_eq "RG5.0 — témoin positif : le verrou réel de la phase 7 existe dans les deux labs" "$(rgc_verrou_pose rg5-a)|$(rgc_verrou_pose rg5-b)" '1|1'
  assert_eq "RG5.10 — verrou de phase tenu par la session, DAG de mission rattaché (6 nœuds, 2 terminés) : detient { ws, phase } et retient { n: 4, portee: mission }" "$(rgc collecte5 "$WORK/rg5-a" "$(rgc_conducteur)" | tee "$WORK/rg5-a.out")" '{"detient":{"ws":"alpha","phase":"7"},"retient":{"n":4,"portee":"mission"}}'
  assert_eq "RG5.11 — même verrou sans DAG visible : detient présent, retient absent (jamais deviné)" "$(rgc collecte5 "$WORK/rg5-b" "$(rgc_conducteur)")" '{"detient":{"ws":"alpha","phase":"7"}}'
}

# ---------- RG6 — aucun champ brut du verrou dans who@2 (REGI-06) ----------
# fuites : la liste d'identifiants de session, le chemin du dossier de verrou, l'emplacement, la durée de bail, la génération ; sentinelles assemblées à l'exécution
rgc_fuites() {
  local f="$1" n=0 s
  for s in "session_""ids" "lease_""seconds" "gener""ation" "loca""tion" "vf-""driver" "DRIVER"".lock" "guard_""effective" "progress_""epoch"; do
    grep -q -- "$s" "$f" && n=$((n+1))
  done
  echo "$n"
}
rgc6_sonde() { RGC_SCRIPTS="$1" rgc collecte5 "$WORK/mut6" "$(rgc_conducteur)" > /dev/null; rgc_fuites "$WORK/mut6/who.json"; }
rg_RG6_collecte() {
  rgc_prepare5
  assert_eq "RG6.0 — témoin positif : la session porte detient (RG5.10 vert d'abord)" "$(G "$WORK/rg5-a/who.json" 'j.workers.some(w => w.kind === "session" && w.detient)')" 'true'
  assert_eq "RG6.10 — who@2 ne contient ni la liste d'identifiants du verrou, ni le chemin de son dossier, ni l'emplacement, ni la durée de bail" "$(rgc_fuites "$WORK/rg5-a/who.json")" '0'
  rm -rf "$WORK/mut6"; cp -R "$WORK/rg5-a" "$WORK/mut6"; rm -f "$WORK/mut6/who.json"
  rg_mutant DETENTION-BRUTE "l'entrée de verrou entière posée sur la session" "$SCRIPTS" vf-cockpit-gouvernance-lecture.mjs 'w.detient = { ws: det.ws, phase: det.phase }; // garde:detient' \
    'w.detient = { ...(brut.locks || []).find((l) => l && l.present && (l.session_ids || []).includes(w.id)) }; // garde:detient' rgc6_sonde '0'
}

# ---------- RG7 — fenêtre de stall à source unique (REGI-07) ----------
rg_RG7_collecte() {
  local avec="$WORK/rg7-avec" sans="$WORK/rg7-sans" stub
  mkdir -p "$avec" "$sans"; stub='#!/usr/bin/env bash\ncase "$1" in status) echo "{\\"present\\": false}";; orphans) echo "{\\"orphans\\":[]}";; esac\n'
  printf "$stub" > "$avec/driver-lock.sh"; printf "$stub" > "$sans/driver-lock.sh"; cp "$(rgc_conducteur)/check-guard-health.sh" "$avec/check-guard-health.sh"
  assert_eq "RG7.10 — copie de check-guard-health.sh voisine du script de verrou : 900 ; VF_STALL_WINDOW=600 : 600 ; sans le script : clé absente" "$(rgc fenetre "$WORK/rg7-1" "$avec")|$(rgc fenetre "$WORK/rg7-2" "$avec" 600)|$(rgc fenetre "$WORK/rg7-3" "$sans")" '900|600|absent'
}

# ---------- RG9 — âge frais pour tout nouvel onglet (REGI-09, C4) ----------
rg_RG9_direct() {
  rgc_direct
  assert_eq "RG9.10 — deux snapshot() pris à plus d'un tour d'écart (ce que porte chaque hello), transcript figé dans le passé : l'âge du second dépasse celui du premier d'au moins 5 s" "$(G "$WORK/direct.json" 'j.age2 - j.age1 >= 5' 2> /dev/null)" 'true'
}

# ---------- RG10 — « attend ses agents » (REGI-10) ----------
rg_RG10_collecte() {
  assert_eq "RG10.10 — session non active dont la dernière ligne est turn_duration (2 agents) : attendAgents 2 ; sous-agent du même transcript, session active, session sans turn_duration : absent" "$(rgc rg10 "$WORK/rg10")" 'a:2|sub:absent|actif:absent|c:absent'
}

# ---------- RG16 — nettoyage à l'émission, contrat, signature (REGI-16) ----------
rgc16_sonde() { RGC_SCRIPTS="$1" rgc rg16 "$WORK/mut16"; }
rg_RG16_collecte() {
  assert_eq "RG16.10 — branche (U+202E, U+200B) et titre (contrôle, U+202E, U+200B) de session : retirés dans who@2" "$(rgc rg16 "$WORK/rg16")" 'branch:propre|titre:propre'
  assert_eq "RG16.11 — le contrat déclare phasesHumaines et fenetreStallS (premier niveau) et attendAgents, lancee, detient, retient (travailleur)" "$(rgc contrat "$WORK/rg16c" 11)" '[]'
  assert_eq "RG16.12 — le contrat déclare vibeflow/cockpit-ailleurs@1 : entrée [lab, n], cwd interdit, requis schema et ailleurs" "$(rgc contrat "$WORK/rg16c" 12)" '{"entree":["lab","n"],"cwd":true,"requis":["schema","ailleurs"]}'
  rgc_prepare5
  assert_eq "RG16.14 — toute clé émise par who@2 (premier niveau et travailleurs, collecte riche : détention, impact, phases humaines, fenêtre) est déclarée au contrat" "$(rgc contrat "$WORK/rg16c" 14 "$WORK/rg5-a/who.json")" '[]'
  rg_mutant NETTOIE-EMISSION "branche et titre repassés au seul masque" "$SCRIPTS" vf-cockpit-who.mjs 'w[k] = nettoie(w[k], n); // garde:nettoie' 'w[k] = bornes(w[k], n); // garde:nettoie' rgc16_sonde 'branch:propre|titre:propre'
}
rg_RG16_direct() {
  assert_eq "RG16.13 — whoSig diffère quand seul un champ ajouté (attendAgents, lancee, detient, retient, orphan, phasesHumaines, fenetreStallS) diffère, et ne diffère pas quand seuls ageS et at diffèrent" "$(rgc sigs "$WORK/rg16s")" 'champs:true,true,true,true,true,true,true|age:egal'
}
