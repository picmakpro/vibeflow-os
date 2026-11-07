// croissance.mjs <scripts> [bavard] : test de CROISSANCE générique. Pour chaque forme de ligne que le cockpit lit dans .planning/ (titres, cases, dépendances, Goal, exigences, jalons,
// STATE, puces) et chaque caractère de chaque classe (espaces des 4 sortes, * _ ( ) [ ] - — – # : : chiffres), une ligne pathologique est fabriquée (trous « ◇ » remplis de N caractères,
// avec et sans saut de ligne final) puis lue à N et 2N par readPlanning ET detectDrift. Échec : le temps à 2N dépasse 2,8 fois celui à N (tailles où il dépasse le bruit) ou 1,5 s.
// Sortie : « ok <nb de cas> » ou les premiers échecs « forme | caractère | opération | N → 2N | t1 → t2 | ratio ».
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, bavard] = process.argv; const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { readPlanning } = await imp('vf-cockpit-planning.mjs'); const { detectDrift } = await imp('vf-cockpit-drift.mjs'); const { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
const N = 20000, SEUIL = 2.8, BRUIT = 40, PLAFOND = 1500;
const CARS = [' ', '\t', ' ', ' ', '*', '_', '(', ')', '[', ']', '-', '—', '–', '#', ':', '1', '.', '·', '\n', '\u2028', '\u2029'];
// formes : { f: ligne avec trous ◇, doc: 'roadmap' | 'exigences' | 'state' | 'jalons' }
const FORMES = [
  ['##◇', 'roadmap'], ['## ◇Phase 1◇', 'roadmap'], ['## Phase 1◇:◇x', 'roadmap'], ['### Phase 1 ◇—◇x', 'roadmap'], ['#### **◇Phase 1: x**◇', 'roadmap'], ['## Phase ◇1 — ◇', 'roadmap'], ['## Phase 1 ◇—', 'roadmap'],
  ['- [ ]◇', 'roadmap'], ['- [x] **◇Phase 1: x◇**◇- ◇d', 'roadmap'], ['- [ ] Phase 1: A◇(complete◇', 'roadmap'], ['- [X] Phase 1 ◇- ◇Trois', 'roadmap'], ['* [ ] **Phase ◇1◇**', 'roadmap'],
  ['### Phase 1: A\n**Depends on:**◇', 'roadmap'], ['### Phase 1: A\n**Depends on:** 1 **◇x', 'roadmap'], ['### Phase 1: A\n**Depends on:** (◇', 'roadmap'], ['### Phase 1: A\n**Depends on:** 2 ◇· ◇x', 'roadmap'],
  ['### Phase 1: A\nDepends on◇:◇1◇', 'roadmap'], ['### Phase 1: A\n- ◇Depends on ◇Phase 2', 'roadmap'], ['### Phase 1: A\n**◇Depends on◇**◇:◇ 2', 'roadmap'], ['### Phase 1: A\n**Depends on:**\n◇- ◇Phase 1', 'roadmap'],
  ['### Phase 1: A\n**Depends on:** 3. ◇A', 'roadmap'], ['### Phase 1: A\n**Depends on:** P1-D-◇1', 'roadmap'],
  ['### Phase 1: A\n**Goal**:◇\n**x', 'roadmap'], ['### Phase 1: A\nGoal ◇: ◇y', 'roadmap'], ['### Phase 1: A\n**Goal** ◇— ◇z', 'roadmap'], ['### Phase 1: A\n**Goal**: a\n◇\n◇\n**Depends on**: 1', 'roadmap'],
  ['- [ ] **◇REQ-1◇**:◇x', 'exigences'], ['- [ ] ◇A-◇1', 'exigences'], ['- [x] **A-1:**◇y', 'exigences'], ['| ◇AB-1◇ | Phase ◇2 |', 'exigences'],
  ['## Milestones\n\n- ✅ **v1** — Phases 1-◇', 'jalons'], ['## Milestones\n\n- ✅ **v1** — Phases ◇-◇', 'jalons'], ['## Milestones\n\n- ✅ **◇v1◇** — ◇Phases ◇1', 'jalons'],
  ['## T◇— x', 'backlog'], ['## T ◇— ◇x', 'backlog'], ['## ◇T — ◇', 'backlog'], ['<objective>◇', 'plan'], ['<objective>◇</objective>', 'plan'], ['※', 'plan'], ['---\ndepends_on: ◇\n', 'plan'], ['---\nfiles_modified: [◇\n', 'plan'],
  ['current_phase: ◇', 'state'], ['status: ◇', 'state'], ['current_phase: "◇2"', 'state'],
];
const holes = (f, c) => f.split('◇').join(c.repeat(N));
const t = (g) => { const a = process.hrtime.bigint(); g(); return Number(process.hrtime.bigint() - a) / 1e6; };
const mesure = (ops, ecrire, taille) => { const d = fs.mkdtempSync(path.join(os.tmpdir(), 'cr-')); fs.mkdirSync(path.join(d, '.planning')); ecrire(d, taille); const r = Object.fromEntries(ops.map(([nom, g]) => [nom, Math.min(t(() => g(d)), t(() => g(d)))])); fs.rmSync(d, { recursive: true, force: true }); return r; };
const OPS = [['readPlanning', (d) => readPlanning(d, undefined, { sansTags: true })], ['detectDrift', (d) => detectDrift(d)]];
const OPS_PROJET = [['buildProjectGraph', (d) => buildProjectGraph(d)]]; // BACKLOG, plans : lus par le graphe Projet seulement
const echecs = []; let cas = 0; const FILTRE = process.env.CROISSANCE_FORME || ''; // sous-chaîne : restreint aux formes qui la contiennent (preuves par mutant)
for (const [forme, doc] of FORMES.filter(([f]) => f.includes(FILTRE))) for (const c of CARS) for (const [queue, fin] of [['', '\n'], ['', ''], ['v\u2028w', '\n']]) {
  if (forme.includes('※') && c !== CARS[0]) continue; // forme à jeton : une seule passe
  const ops = doc === 'backlog' || doc === 'plan' ? OPS_PROJET : OPS;
  const f = (taille) => forme.split('◇').join(c.repeat(taille)).split('※').join('<objective>'.repeat(Math.floor(taille / 2)));
  const ecrire = (d, taille) => {
    const p = (x) => path.join(d, '.planning', x); const ligne = f(taille) + queue + fin;
    if (doc === 'exigences') fs.writeFileSync(p('REQUIREMENTS.md'), ligne);
    else if (doc === 'state') { fs.writeFileSync(p('ROADMAP.md'), '### Phase 1: A\n'); fs.writeFileSync(p('STATE.md'), '---\n' + ligne + (fin ? '---\n' : '')); }
    else if (doc === 'backlog' || doc === 'plan') {
      fs.writeFileSync(p('ROADMAP.md'), '- [ ] **Phase 1: A** - x\n### Phase 1: A\n');
      if (doc === 'backlog') fs.writeFileSync(p('BACKLOG.md'), ligne); else { fs.mkdirSync(p('phases/01-a'), { recursive: true }); fs.writeFileSync(p('phases/01-a/01-01-PLAN.md'), ligne); }
    }
    else fs.writeFileSync(p('ROADMAP.md'), (doc === 'jalons' ? '- [ ] **Phase 1: A**\n\n' : '') + ligne);
  };
  cas++;
  let a = mesure(ops, ecrire, N), b = mesure(ops, ecrire, 2 * N);
  for (const [nom] of ops) {
    let r = b[nom] / Math.max(a[nom], 1);
    for (let k = 0; k < 2 && b[nom] > BRUIT && (r > SEUIL || b[nom] > PLAFOND); k++) { a = mesure(ops, ecrire, N); b = mesure(ops, ecrire, 2 * N); r = b[nom] / Math.max(a[nom], 1); } // un faux rouge de bruit ne survit pas à deux rejeux
    if (b[nom] > BRUIT && (r > SEUIL || b[nom] > PLAFOND)) echecs.push(`${JSON.stringify(forme)} | ${JSON.stringify(c)}${fin ? '' : ' sans \\n final'}${queue ? ' + queue ' + JSON.stringify(queue) : ''} | ${nom} | ${N} → ${2 * N} | ${a[nom].toFixed(0)} ms → ${b[nom].toFixed(0)} ms | ×${r.toFixed(1)}`);
  }
}
console.log(echecs.length ? `${echecs.length} échec(s) sur ${cas} cas :\n` + echecs.slice(0, Number(bavard) || 12).join('\n') : `ok ${cas}`);
