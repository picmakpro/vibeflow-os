#!/usr/bin/env node
// vf-cockpit-project — graphe Projet du cockpit (promu du spike 002, généralisé : lab plat, partitionné, sans jalons).
// Export : buildProjectGraph(root, { layout }) -> schéma vibeflow/cockpit-project@1 (format du viewer :
//   nodes, files, links, flows, tour, routes, meta, project). CLI : node vf-cockpit-project.mjs <root> (JSON compact).
// Hiérarchie : jalon -> phase -> plans + exigences ; missions (DAG) rattachées à leur phase ; backlog, graines, releases.
// Identité d'une phase = (compartiment, numéro) : `ph-<N>` si le numéro est unique dans le lab, sinon `ph-<N>@<ws>`.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { planningLayout } from './vf-cockpit-paths.mjs';
import { readPlanning, read, clip, sentence, num, fm, list } from './vf-cockpit-planning.mjs';
import { texte } from './vf-cockpit-formats.mjs';
import { trouverPhase, LIBELLES_RESTE, LIBELLES_MISSION, LIBELLES_ETAT } from './vf-cockpit-avancement.mjs';
import { KIND_ICONS, KIND_COLORS } from './vf-cockpit-types.mjs';
import { detectDrift, commandeCorrectif } from './vf-cockpit-drift.mjs';
import { lireAilleurs, fusionner } from './vf-cockpit-ailleurs.mjs';

const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
const DST = { done: 'done', running: 'active', ready: 'todo', blocked: 'todo', failed: 'blocked' }; // dag.sh : blocked = en attente des deps
const pct = (a, b) => (b ? Math.round((100 * a) / b) : 0);
// projection de l'état d'avancement sur les statuts du viewer : « à recetter » prend la teinte « en cours » mais son propre statut `recette` : glyphe et mot « À recetter » sur la carte (P69-D-25, P69-PL-02, P71.5-D-20) ; l'état exact reste dans avancement.etat
const PROJECTION_ST = { fait: 'done', 'a-recetter': 'recette', 'en-cours': 'active', 'a-faire': 'todo' };
// pied de jalon : « N clos · [N en cours · ]N à recetter · N à faire · N % » ; le pourcentage ne compte que les phases closes (P69-D-06, P69-PL-03)
function piedJalon(ks) {
  const n = (e) => ks.filter((p) => p.avancement.etat === e).length; const clos = n('fait'), enc = n('en-cours');
  return [`${clos} clos`, enc ? `${enc} en cours` : '', `${n('a-recetter')} à recetter`, `${n('a-faire')} à faire`, `${pct(clos, ks.length)} %`].filter(Boolean).join(' · ');
}

// contenu de la première balise <objective> (indexOf : une balise sans fermeture ne fait pas rebalayer le texte pour chaque ouverture)
const objectif = (t) => { const a = t.indexOf('<objective>'); if (a < 0) return undefined; const b = t.indexOf('</objective>', a + 11); return b < 0 ? undefined : t.slice(a + 11, b).replace(/^\s+/, ''); };

// PU-G-102 : le texte d'un jalon ou d'une phase vient du ROADMAP en markdown : commentaires d'archive (`<!-- vf-archive … -->`, fermés ou non), gras, accents graves et liens sont retirés à la SOURCE,
// le panneau n'affiche jamais de balisage brut. Un commentaire jamais fermé court jusqu'à la fin du texte (un seul passage : coût linéaire).
const propre = (t) => String(t ?? '').replace(/<!--[\s\S]*?(?:-->|$)/g, '').replace(/\*\*/g, '').replace(/`/g, '').replace(/\[([^\]\n]+)\]\([^)\n]*\)/g, '$1').replace(/[ \t]+\n/g, '\n').replace(/[ \t]{2,}/g, ' ').trim();
// PU-G-103 : le résumé (carte, haut du panneau) et le détail ne répètent plus le même texte. Le résumé porte tout le texte jusqu'à `max` caractères ; au-delà, il s'arrête à la dernière fin de phrase
// (sinon au dernier mot, avec « … ») et le détail ne reprend que la SUITE, jamais le début.
function scinder(t, max) {
  const s = String(t ?? '').replace(/\s+/g, ' ').trim();
  if (s.length <= max) return { resume: s, reste: '' };
  let cut = -1; for (const m of s.matchAll(/[.!?](?=\s)/g)) { if (m.index + 1 > max) break; cut = m.index + 1; }
  if (cut > 25) return { resume: s.slice(0, cut), reste: s.slice(cut).trim() };
  const sp = s.lastIndexOf(' ', max - 1), c = sp > 25 ? sp : max - 1;
  return { resume: s.slice(0, c).trimEnd() + '…', reste: '…' + s.slice(c).trim() };
}

// pied d'une carte de phase, part des exigences (PU-G-097, Q9 option A : mot en texte neutre, aucun glyphe ajouté — le pied n'a pas d'emplacement de pastille) :
// une phase faite dont des exigences ne sont pas cochées dit « N exigence(s) non cochée(s) » (la pastille voisine dit « Fait ») au lieu de « 3/14 exigences », qui se lisait comme un travail à moitié fait
function piedExigences(etat, reqs) {
  if (!reqs.length) return '';
  const ouvertes = reqs.filter((r) => !r.done).length;
  if (etat === 'fait' && ouvertes) return `${ouvertes} exigence${ouvertes > 1 ? 's' : ''} non cochée${ouvertes > 1 ? 's' : ''}`;
  return `${reqs.length - ouvertes}/${reqs.length} exigences`;
}

// PU-G-093 : l'état d'une phase est celui de sa carte (fichiers du dossier, P69-D-08) ; STATE.md ne dit que s'il s'accorde avec elle. Statuts de STATE compatibles avec chaque état de carte ;
// un statut hors de cette table (pause, bloqué, inconnu) ne se contredit jamais.
const COMPAT_STATE = { planning: ['a-faire'], ready_to_plan: ['a-faire'], ready_to_execute: ['a-faire', 'en-cours'], executing: ['a-faire', 'en-cours'], in_progress: ['a-faire', 'en-cours'],
  verifying: ['a-recetter', 'en-cours'], ready_for_verification: ['a-recetter', 'en-cours'], complete: ['fait', 'a-recetter'], completed: ['fait', 'a-recetter'], closed: ['fait'], milestone_complete: ['fait'] };
const etatPerime = (status, etat) => !!etat && Object.hasOwn(COMPAT_STATE, String(status ?? '').trim()) && !COMPAT_STATE[String(status).trim()].includes(etat);

export function buildProjectGraph(root, { layout } = {}) {
  root = path.resolve(root); layout = layout || planningLayout(root);
  // dérive de format mesurée AVANT la lecture : le panneau propose le correctif au lieu d'une carte vide sans explication
  const P = readPlanning(root, layout); const { rel, state, reqs } = P; // AUDC-H2 : lu UNE fois, le contrôle de format reçoit cette lecture
  let drift; try { drift = detectDrift(root, layout, P); } catch (e) { drift = { constats: [], resume: `Contrôle de format impossible : ${e.message}`, erreur: true }; }
  P.phases = fusionner(P.phases, lireAilleurs(root)); // N5 : une phase menée dans un worktree du même dépôt prend l'avancement du worktree si elle y est plus avancée
  const { phases } = P;
  const nodes = [], files = [], links = [];
  const node = (o) => { nodes.push({ details: '', tags: [], paths: [], packages: [], hosts: [], stats: { files: 0, loc: 0, langs: {}, repos: ['.'] }, ...o }); return o.id; };
  const file = (o) => { files.push({ r: '.', l: null, loc: 0, h: '', sig: '', ...o }); for (let n = o.n; n; n = nodes.find((x) => x.id === n)?.parent) { const x = nodes.find((y) => y.id === n); if (x) x.stats.files++; } return 'f:' + o.p; };
  const link = (a, b, k, label) => links.push({ a, b, k, w: 1, ...(label ? { label } : {}) });
  const curPhase = String(state.current_phase || '');
  const count = new Map(); for (const ph of phases.values()) count.set(ph.n, (count.get(ph.n) || 0) + 1);
  const phId = (ph) => (count.get(ph.n) > 1 && ph.ws ? `ph-${ph.n}@${ph.ws}` : `ph-${ph.n}`);
  const dirOf = (ph) => P.phaseDirs.get(`${ph.ws || ''}|${ph.n}`) || P.phaseDirs.get(`*|${ph.n}`);
  const reqOf = (id, ws) => reqs.get(`${ws || ''}|${id}`) || reqs.get(`*|${id}`);
  const reqPath = (r) => `req/${r.ws ? r.ws + '/' : ''}${r.id}`;
  const ownReqs = (ph) => [...reqs.values()].filter((r) => r.phase === ph.n && (r.wsKey === '*' || r.wsKey === (ph.ws || '')));
  const phaseStatus = (ph) => PROJECTION_ST[ph.avancement.etat] || 'todo'; // l'avancement vient des fichiers, jamais du STATE (CKPT-18)

  // jalons : ceux de la section « ## Milestones », sinon un jalon synthétique « Phases » ; les phases orphelines y vont aussi
  const inMs = new Set(P.milestones.flatMap((m) => [...m.phases]));
  const loose = [...phases.values()].filter((p) => !p.archive && !inMs.has(p.key));
  const ms0 = [...P.milestones];
  // PU-G-099 : quand le ROADMAP a de vrais jalons, le groupe des phases sans jalon s'appelle « Hors jalon » : ni dans « Historique », ni dans meta.vf.milestones, jamais le jalon actif, sans enchaînement « puis ».
  // Sans aucun jalon, il garde « Phases » : c'est alors le seul jalon du lab.
  const horsJalon = P.milestones.length > 0;
  if (loose.length) ms0.push(horsJalon ? { key: 'Hors jalon', id: 'ms-hors-jalon', icon: '', text: 'Phases qui ne figurent dans aucun jalon du ROADMAP', phases: new Set(loose.map((p) => p.key)), ws: null, synthetic: true, horsJalon: true }
    : { key: 'Phases', id: 'ms-phases', icon: '', text: 'Phases du lab', phases: new Set(loose.map((p) => p.key)), ws: null, synthetic: true });
  const sortPh = (a, b) => num(a.n) - num(b.n);
  const msList = ms0.map((ms) => {
    const ks = [...ms.phases].map((k) => phases.get(k)).filter(Boolean).sort(sortPh);
    const done = ks.filter((p) => p.done).length;
    const enCours = ks.some((p) => p.avancement.etat === 'en-cours' || p.avancement.etat === 'a-recetter');
    const st = ms.icon === '✅' ? 'done' : done === ks.length && ks.length ? 'done' : enCours || done > 0 || ms.icon === '🚧' || (ms.synthetic && ks.length) ? 'active' : 'todo';
    return { ...ms, ks, done, st };
  });
  const closed = msList.filter((m) => m.st === 'done' && !m.horsJalon);
  const hist = closed.length ? node({ id: 'history', parent: null, label: 'Historique', kind: 'historique', summary: `Les ${closed.length} jalons clos, du premier au dernier.`, st: 'done', foot: `${closed.length} jalons · ${closed.reduce((s, m) => s + m.ks.length, 0)} phases` }) : null;
  const prev = new Map(); // enchaînement « puis » limité à un même compartiment
  for (const ms of msList) {
    const wk = ms.ws || '';
    const mt = propre(ms.text);
    const msId = node({ id: ms.id, parent: ms.st === 'done' && !ms.horsJalon ? hist : null, label: ms.key, kind: 'jalon', summary: sentence(mt.replace(/^[^—]*—\s*/, ''), 180) || mt, details: mt, st: ms.st,
      foot: piedJalon(ms.ks), tags: [ms.ws ? 'compartiment ' + ms.ws : ''].filter(Boolean) });
    const pv = ms.horsJalon ? null : prev.get(wk);
    if (ms.horsJalon) { /* pas d'enchaînement : le groupe n'est pas un jalon de la chaîne */ }
    else if (pv && ms.st !== 'done' && closed.some((m) => m.id === pv)) { link('n:history', 'n:' + msId, 'event', 'puis'); prev.set(wk, msId); }
    else if (pv && pv !== msId) { link('n:' + pv, 'n:' + msId, 'event', 'puis'); prev.set(wk, msId); }
    else if (!pv) prev.set(wk, msId);
    for (const ph of ms.ks) addPhase(ph, msId);
  }
  function addPhase(ph, msId) {
    const st = phaseStatus(ph), dir = dirOf(ph);
    const planFiles = ls(dir).filter((f) => /-PLAN\.md$/.test(f)).sort();
    const sums = new Set(ls(dir).filter((f) => /-SUMMARY\.md$/.test(f)).map((f) => f.replace('-SUMMARY.md', '')));
    const av = ph.avancement;
    const enCours = P.dags.filter((d) => d.phaseKey === ph.key && d.etat === 'running').flatMap((d) => d.nodes.filter((x) => x?.status === 'running')); // un plan non fait est actif si un nœud running d'une mission rattachée le désigne (P69-PL-04) ; seule une mission vivante désigne un plan actif (VFSG-06)
    const phReqs = ownReqs(ph); const id = phId(ph);
    const but = propre(ph.goal), ligne = propre(ph.line), { resume, reste: suite } = but ? scinder(but, 400) : { resume: sentence(ligne || ph.name, 200), reste: '' };
    node({ id, parent: msId, label: `Phase ${ph.n} · ${ph.name}`, kind: 'phase', num: ph.n, ws: ph.ws, summary: resume,
      details: [suite, av.reste.length ? `Reste : ${av.reste.map((c) => LIBELLES_RESTE[c]).join(', ')}.` : '', av.ailleurs ? `Avancement lu dans le worktree ${av.ailleurs.arbre}${av.ailleurs.branche ? ` (branche ${av.ailleurs.branche})` : ''} : plus avancé que celui de l'arbre courant.` : '', av.mission ? `Mission : ${av.mission.nom} (${LIBELLES_MISSION[av.mission.etat] || av.mission.etat}).` : '', ph.depends.length ? `Dépend de : Phase ${ph.depends.join(', ')}.` : '', ligne ? `Ligne de ROADMAP : ${ligne}` : '', `Source : ${ph.roadmap}${dir ? ` · dossier ${rel(dir)}` : ''}`].filter(Boolean).join('\n\n'),
      st, foot: [av.etat === 'a-recetter' ? 'à recetter' : '', av.plans.total ? `${av.plans.faits}/${av.plans.total} plans` : '', av.correctifs ? `${av.correctifs} correctif${av.correctifs > 1 ? 's' : ''}` : '', piedExigences(av.etat, phReqs), av.ailleurs ? `dans worktree ${av.ailleurs.arbre}` : ''].filter(Boolean).join(' · ') || 'pas de plan', paths: dir ? [rel(dir)] : [] });
    for (const pf of planFiles) {
      const txt = texte(read(path.join(dir, pf))); const meta = fm(txt); const pid = pf.replace('-PLAN.md', '');
      const obj = objectif(txt) || /^#\s+(.*)$/m.exec(txt)?.[1] || '';
      const touched = list(meta.files_modified); const p = rel(path.join(dir, pf));
      file({ p, n: id, name: `${pid} — ${clip(obj.split('\n').find((l) => l.trim()) || '', 70)}`, d: sentence(obj, 220), st: sums.has(pid) || ph.done ? 'done' : enCours.some((x) => x.id === pid || (Array.isArray(x.scope) && x.scope.includes(p))) ? 'active' : 'todo',
        foot: `vague ${meta.wave || '?'}${touched.length ? ` · ${touched.length} fichiers` : ''}`, note: touched.length ? `Fichiers touchés : ${touched.slice(0, 12).join(', ')}${touched.length > 12 ? ` … (+${touched.length - 12})` : ''}` : undefined, touched });
      for (const dep of list(meta.depends_on)) { const dp = planFiles.find((x) => x.startsWith(dep.length <= 3 ? `${pf.split('-')[0]}-${dep.padStart(2, '0')}` : dep)); if (dp) link('f:' + rel(path.join(dir, dp)), 'f:' + p, 'import', 'puis'); }
      for (const r of list(meta.requirements)) { const rq = reqOf(r, ph.ws); if (rq) link('f:' + p, 'f:' + reqPath(rq), 'data', 'couvre'); }
    }
    if (phReqs.length) {
      const rId = node({ id: `${id}.req`, parent: id, label: 'Exigences', kind: 'exigences', summary: `${phReqs.filter((r) => r.done).length} cochées sur ${phReqs.length}.`, foot: `${phReqs.filter((r) => r.done).length}/${phReqs.length}`, st: phReqs.every((r) => r.done) ? 'done' : phReqs.some((r) => r.done) ? 'active' : 'todo' });
      for (const r of phReqs) file({ p: reqPath(r), n: rId, name: r.id, d: sentence(r.text, 220), st: r.done ? 'done' : 'todo', foot: sentence(propre(r.text), 120) || r.file.split('/').pop() }); // PU-G-106 : le pied dit l'exigence elle-même, plus « REQUIREMENTS.md »
    }
  }
  // PU-G-100 (mis de côté) : le sens dépendance -> dépendant est celui que le viewer lit pour ranger les cartes (les entrants à gauche, « Utilisé par » ; les sortants à droite) : l'inverser corrige le panneau mais retourne l'ordre des cartes (mesuré en navigateur) ; le libellé « Utilisé par » est du viewer vendorisé, hors périmètre
  for (const ph of phases.values()) for (const d of ph.depends) { const dp = trouverPhase(phases, d, ph.ws); if (dp && nodes.some((n) => n.id === phId(dp)) && nodes.some((n) => n.id === phId(ph))) link('n:' + phId(dp), 'n:' + phId(ph), 'import', 'dépend de'); }

  // missions : chaque DAG rattaché à sa phase par le module d'avancement (champ `phase`, nom, dossier de phase), sinon « hors phase »
  let orphan = null;
  for (const d of P.dags) {
    const tp = d.phaseKey ? phases.get(d.phaseKey) : null;
    let parent = tp && nodes.some((n) => n.id === phId(tp)) ? phId(tp) : null;
    if (!parent) { orphan ||= node({ id: 'missions', parent: null, label: 'Missions hors phase', kind: 'mission', summary: 'Plans de bataille de missions qui ne portent pas un numéro de phase.' }); parent = orphan; }
    const doneN = d.nodes.filter((x) => x.status === 'done').length;
    const mId = node({ id: 'dag-' + d.name, parent, label: `Mission ${d.name.replace(/^MISSION-/, '')}`, kind: 'mission', summary: `Plan de bataille : ${d.nodes.length} nœuds, ${doneN} fait${doneN > 1 ? 's' : ''}.`,
      st: doneN === d.nodes.length ? 'done' : d.etat === 'abandonnee' || d.etat === 'inconnu' ? 'todo' : d.nodes.some((x) => x.status === 'running') ? 'active' : d.nodes.some((x) => x.status === 'failed') ? 'blocked' : 'todo', foot: `${doneN}/${d.nodes.length} nœuds${d.etat === 'abandonnee' || d.etat === 'inconnu' ? ` · ${LIBELLES_MISSION[d.etat]}` : ''}`, paths: [d.file] });
    for (const x of d.nodes) file({ p: `${d.file}#${x.id}`, n: mId, name: x.id, d: sentence(x.step, 200), st: DST[x.status] || 'todo', foot: x.stage || '', note: x.scope?.length ? `Périmètre : ${x.scope.join(', ')}` : undefined, touched: x.scope });
    for (const x of d.nodes) for (const dep of x.deps || []) link(`f:${d.file}#${dep}`, `f:${d.file}#${x.id}`, 'queue', 'puis');
  }
  if (orphan) nodes.find((x) => x.id === 'missions').foot = `${nodes.filter((x) => x.parent === 'missions').length} missions`;

  // backlog, graines, releases
  const bl = node({ id: 'backlog', parent: null, label: 'Backlog', kind: 'backlog', summary: 'Ce qui est consigné, différé ou investigué, hors des jalons.' });
  for (const m of P.backlog.matchAll(/^## ([^\n]*)\n([\s\S]*?)(?=^## |(?![\s\S]))/gm)) {
    const [title, status] = m[1].split(/(?<!\s)\s+—\s+(?=[A-ZÉ]{4,}|consigné|mesuré)/);
    file({ p: `.planning/BACKLOG.md#${title.toLowerCase().replace(/[^a-z0-9à-ÿ]+/g, '-').slice(0, 60)}`, n: bl, name: clip(title, 80), d: sentence(m[2].replace(/^>.*$/gm, ''), 220), st: /INVESTIGUÉ|mesuré/i.test(status || '') ? 'done' : 'todo', foot: clip(status || '', 40) });
  }
  const sd = node({ id: 'seeds', parent: null, label: 'Graines', kind: 'graine', summary: 'Idées de jalons futurs, avec leurs déclencheurs.' });
  for (const s of P.seeds) file({ p: s.file, n: sd, name: clip(/^#\s+(.*)$/m.exec(s.text)?.[1] || path.basename(s.file), 80), d: sentence(s.text.replace(/^---[\s\S]*?---/, '').replace(/^#.*$/gm, ''), 220), st: 'todo' });
  const rl = node({ id: 'releases', parent: null, label: 'Releases', kind: 'release', summary: 'Les 30 derniers tags publiés.' });
  for (const t of P.tags) file({ p: `tag/${t.tag}`, n: rl, name: t.tag, d: clip(t.subject, 200), st: 'done', foot: t.date });
  for (const [id, unit] of [['backlog', 'entrées'], ['seeds', 'graines']]) nodes.find((x) => x.id === id).foot = `${files.filter((f) => f.n === id).length} ${unit}`;
  nodes.find((n) => n.id === 'releases').foot = `${P.tags.length} tags`;

  // jalon mis en avant : celui que nomme le STATE du compartiment actif tant qu'il n'est pas clos, sinon le premier en cours (CKPT-16) ; le STATE ne décide jamais de l'état d'une PHASE (P69-D-08)
  const active = msList.find((m) => state.milestone && m.key === state.milestone && m.ws === (layout.actif || null) && m.st !== 'done') || msList.find((m) => m.st === 'active' && !m.horsJalon) || msList.filter((m) => !m.horsJalon).at(-1) || msList.at(-1);
  const flows = active ? [{ id: 'trajectoire', title: `Trajectoire ${/^[aeiouyàâéèêîôû]/i.test(active.key) ? "d'" : 'de '}${active.key}`, description: "Les phases du jalon en cours, dans l'ordre.", steps: active.ks.map((p) => ({ ref: 'n:' + phId(p), note: `${p.done ? '✓' : '○'} ${p.name}` })) }] : [];
  // visite « Par où commencer » propre à l'onglet Projet (70-08, UIFN-05, P70-D-02) : jalon, phase en cours, missions, au travail ; une étape sans carte est omise, jamais affichée avec « ? » ;
  // sous deux étapes, la liste est vide et le repli du moteur s'applique. Les textes viennent des données du lab ; la `cible` est une constante, jamais une donnée (T-70-13).
  const tour = [], has = (id) => nodes.some((n) => n.id === id);
  if (active && has(active.id)) tour.push({ ref: 'n:' + active.id, kicker: 'Le jalon', title: `Jalon ${active.key}`, note: `VibeFlow fait avancer votre projet par grandes étapes, avec Claude au travail. Jalon = une grande étape du projet ; phase = un morceau d'un jalon ; mission = le travail mené, étape par étape, pour réaliser une phase. Voici le jalon en cours. Phases faites : ${active.done} sur ${active.ks.length}.` }); // PU-G-091
  const cur = trouverPhase(phases, curPhase, layout.actif);
  const phaseEtat = cur ? cur.avancement.etat : null, perime = etatPerime(state.status, phaseEtat);
  if (cur && has(phId(cur))) tour.push({ ref: 'n:' + phId(cur), kicker: 'La phase en cours', title: `Phase ${cur.n}${cur.name ? ` · ${cur.name}` : ''}`, note: `La phase sur laquelle le projet travaille : ${LIBELLES_ETAT[cur.avancement.etat]}${perime ? ' (STATE.md semble périmé)' : ''}.` });
  // PU-G-092 : la mission montrée est une mission VIVANTE du jalon en cours (jamais une abandonnée d'un autre jalon) : celle qui travaille, sinon la première non terminée d'une phase pas faite, sinon la première non terminée,
  // sinon la première vivante ; à défaut, une mission vivante hors phase (la carte « Missions hors phase ») ; aucune -> l'étape est omise. Les comptes sont ceux de ce groupe (les missions rattachées aux phases du jalon,
  // ou celles hors phase), ils s'accordent avec la carte ; le mot du panneau est « étapes », jamais « nœuds ».
  const clesJalon = new Set(active ? active.ks.map((p) => p.key) : []);
  const duJalon = P.dags.filter((d) => clesJalon.has(d.phaseKey) && has('dag-' + d.name)), horsPhase = P.dags.filter((d) => !(d.phaseKey && phases.get(d.phaseKey)) && has('dag-' + d.name));
  const vivante = (d) => d.etat !== 'abandonnee' && d.etat !== 'inconnu', travaille = (d) => d.nodes.some((x) => x?.status === 'running'), ouverte = (d) => d.nodes.some((x) => x?.status !== 'done');
  const choisir = (g) => g.find(travaille) || g.find((d) => vivante(d) && ouverte(d) && phases.get(d.phaseKey)?.avancement.etat !== 'fait') || g.find((d) => vivante(d) && ouverte(d)) || g.find(vivante);
  const grp = choisir(duJalon) ? duJalon : choisir(horsPhase) ? horsPhase : null, dg = grp && choisir(grp);
  if (dg) {
    const fait = dg.nodes.filter((x) => x?.status === 'done').length, enCoursN = grp.filter((d) => vivante(d) && travaille(d)).length, n = grp.length;
    tour.push({ ref: 'n:dag-' + dg.name, kicker: 'Les missions', title: `Mission ${dg.name.replace(/^MISSION-/, '')}`, note: `${grp === duJalon ? 'Ce jalon compte' : 'Hors phase, le projet compte'} ${n} mission${n > 1 ? 's' : ''}${enCoursN ? `, dont ${enCoursN} en cours` : ''} ; celle-ci a ${fait} étape${fait > 1 ? 's' : ''} faite${fait > 1 ? 's' : ''} sur ${dg.nodes.length}.` });
  }
  tour.push({ ref: 'root', cible: '#vf-lock', kicker: 'Au travail', title: 'Qui est au travail', note: "Ce point en haut de la page s'anime quand quelqu'un travaille sur le projet, et reste éteint sinon ; un clic ouvre la liste. L'onglet Équipe en montre le détail." });
  const ids = new Set(nodes.map((n) => 'n:' + n.id)), fids = new Set(files.map((f) => 'f:' + f.p));
  return {
    schema: 'vibeflow/cockpit-project@1',
    meta: { generatedAt: new Date().toISOString(), rootName: path.basename(root), root, audience: 'everyone', agent: 'claude', repos: [], counts: { files: files.length, loc: 0 }, vfTab: 'project',
      kindIcons: KIND_ICONS, kindColors: KIND_COLORS,
      kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Dispatche', contains: 'Contient' },
      vf: { milestone: state.milestone, phase: curPhase, phaseEtat, stateStale: perime, phaseName: state.current_phase_name, status: state.status, lastActivity: state.last_activity, lastDesc: state.last_activity_desc, progress: state.progress,
        milestones: msList.filter((m) => !m.horsJalon).map((m) => ({ key: m.key, st: m.st, done: m.done, total: m.ks.length, id: 'n:' + m.id })),
        next: active ? active.ks.filter((p) => !p.done).map((p) => ({ id: 'n:' + phId(p), label: `Phase ${p.n} · ${p.name}`, etat: p.avancement.etat })) : [],
        drift: { resume: drift.resume, erreur: !!drift.erreur,
          // une règle = un groupe de constats ; `fichier` reste celui du PREMIER constat (champ historique) : la répartition vraie est dans `fichiers` ([{fichier, n}]) et les endroits dans `emplacements` ([{fichier, ligne}], 5 au plus) — PU-G-156
          regles: Object.values(drift.constats.reduce((o, c) => { const r = (o[c.regle] ||= { regle: c.regle, niveau: c.niveau, message: c.message, fichier: c.fichier, n: 0, fichiers: [], emplacements: [], corrigeable: false });
            r.n++; (r.fichiers.find((f) => f.fichier === c.fichier) || (r.fichiers.push({ fichier: c.fichier, n: 0 }), r.fichiers.at(-1))).n++;
            if (c.ligne > 0 && r.emplacements.length < 5) r.emplacements.push({ fichier: c.fichier, ligne: c.ligne }); if (c.apres !== undefined) r.corrigeable = true; return o; }, {})),
          corrigeable: drift.constats.some((c) => c.apres !== undefined),
          // PU-G-155 : le compte de chaque niveau, pour écrire « 5 écarts : 1 toléré, 4 non lus » sans recompter côté page ; `couvertsN` = écarts que le correctif remet en forme (PU-G-156)
          ecartsN: drift.constats.length, couvertsN: drift.constats.filter((c) => c.apres !== undefined).length,
          parNiveau: { bloquant: drift.constats.filter((c) => c.niveau === 'bloquant').length, tolere: drift.constats.filter((c) => c.niveau === 'toléré').length, info: drift.constats.filter((c) => c.niveau === 'info').length, ignore: drift.constats.filter((c) => c.niveau === 'ignoré').length },
          // PU-G-153 : la commande complète (chemins absolus), seule source de ce que le panneau affiche ET copie
          commande: drift.constats.some((c) => c.apres !== undefined) ? commandeCorrectif(root) : '',
          // lignes non comprises (fichier:ligne + extrait), au plus 20 : le total est dans `nonComprisesN` (diagnostic du premier assemblage, P-PARS)
          nonComprisesN: drift.constats.filter((c) => c.regle === 'ligne-non-comprise').length,
          nonComprises: drift.constats.filter((c) => c.regle === 'ligne-non-comprise').slice(0, 20).map((c) => ({ fichier: c.fichier, ligne: c.ligne, extrait: c.avant })) },
        // PU-G-160 : le groupe « Hors jalon » (phases sans jalon dans un ROADMAP qui en a), signalé dans le panneau Format
        horsJalon: horsJalon && loose.length ? { n: loose.length, id: 'n:ms-hors-jalon' } : null,
        counts: { phases: phases.size, plans: files.filter((f) => f.p.endsWith('-PLAN.md')).length, reqs: reqs.size, reqsDone: [...reqs.values()].filter((r) => r.done).length, dags: P.dags.length } },
      layout: { forme: layout.forme, actif: layout.actif } },
    project: { name: `${P.projectName} — Projet`, summary: resume(state, curPhase, phases.size, files, phaseEtat) },
    nodes, files, routes: [], links: links.filter((l) => [l.a, l.b].every((x) => (x.startsWith('n:') ? ids.has(x) : fids.has(x)))), flows, tour: tour.length >= 2 ? tour : [],
  };
}

// libellés français des valeurs de `status:` que gsd-core écrit dans STATE.md ; table unique, reprise à l'identique par le navigateur (STATUT de 00-vibeflow.js, parité vérifiée par Q17)
export const STATUTS = { planning: 'en planification', ready_to_plan: 'prête à planifier', ready_to_execute: 'prête à exécuter', executing: 'en exécution', in_progress: 'en cours',
  verifying: 'en vérification', ready_for_verification: 'prête à vérifier', paused: 'en pause', blocked: 'bloqué', complete: 'terminée', completed: 'terminée', closed: 'clos', milestone_complete: 'jalon terminé' };
// valeur inconnue -> null : elle est omise, jamais affichée brute (P70-D-04)
export function statutLisible(x) { return Object.hasOwn(STATUTS, String(x ?? '').trim()) ? STATUTS[String(x).trim()] : null; }

// sous-titre du projet : seulement les champs connus (un lab sans STATE.md n'affiche ni « ? » ni parenthèses vides), sinon les effectifs
function resume(state, curPhase, nbPhases, files, phaseEtat) {
  const seg = [state.milestone ? `Jalon ${state.milestone}` : '', curPhase ? `phase ${curPhase}${state.current_phase_name ? ` (${state.current_phase_name})` : ''}` : '', (phaseEtat ? LIBELLES_ETAT[phaseEtat] : statutLisible(state.status)) || ''].filter(Boolean);
  if (seg.length) return seg.join(' · ') + '.';
  const plans = files.filter((f) => f.p.endsWith('-PLAN.md')).length;
  return `${nbPhases} phase${nbPhases > 1 ? 's' : ''} · ${plans} plan${plans > 1 ? 's' : ''}.`;
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) process.stdout.write(JSON.stringify(buildProjectGraph(process.argv[2] || '.')));
