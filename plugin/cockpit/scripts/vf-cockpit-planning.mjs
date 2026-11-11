// vf-cockpit-planning — lecteurs de .planning (plat, partitionné, archivé) du socle du cockpit (CKPT-06).
// Export principal : readPlanning(root, layout) -> { phases, phaseDirs, reqs, milestones, state, dags,
//   backlog, seeds, tags, projectName } ; chaque phase porte `avancement` (vf-cockpit-avancement.mjs), chaque DAG `phaseKey` et `regle`.
//   lireDags(root, layout) : la découverte unique des DAG (compartiments, .planning, .planning/missions, dossiers de phase). Utilitaires partagés : fm, clip, sentence, list, num, normNum.
// Identité d'une phase = couple (compartiment, numéro) : `key` = `<ws>|<n>` ('' pour un lab plat).
// Aucun nom de compartiment, de jalon ou de projet codé en dur. Lecture seule.
import fs from 'node:fs';
import path from 'node:path';
import { planningLayout, stateFile, GIT_SUR, shBorne, realUnder } from './vf-cockpit-paths.mjs';
import { gitSortant } from './vf-cockpit-git-sortant.mjs';
import { avancement, rattacherMission, etatMission } from './vf-cockpit-avancement.mjs';
import { lireVerrous, vieDe } from './vf-cockpit-vie.mjs';
import { COLON, NUM, normNum, texte, lireGoal, lireDependances, reTitreCase, reTitreSection, reExigences, idExigence, texteExigence, reTraceabilite, normStatut, phaseCourante } from './vf-cockpit-formats.mjs';
export { COLON, normNum };

// jamais d'ouverture d'un fichier non régulier (un tube FIFO bloque ; un lien vers /dev/zero ne finit pas, et git versionne les liens symboliques) ni d'un fichier au-delà de MAX_LECTURE
const MAX_LECTURE = 8 << 20;
// confinement (lecture d'un AUTRE arbre, N5) : pendant `lireConfine(racine, fn)`, read et ls refusent tout chemin dont le realpath sort de `racine` (lien symbolique sortant)
let CONFINE = null;
const dedans = (p) => !CONFINE || realUnder(p, CONFINE);
export function lireConfine(racine, fn) { const avant = CONFINE; CONFINE = fs.realpathSync(racine); try { return fn(); } finally { CONFINE = avant; } }
export const lister = (d) => ls(d); // listage de noms sous le même confinement que `read` (AUDC-A-02)
export const read = (f) => { try { if (!dedans(f)) return ''; const st = fs.statSync(f); return st.isFile() && st.size <= MAX_LECTURE ? fs.readFileSync(f, 'utf8') : ''; } catch { return ''; } };
const ls = (d) => { try { return dedans(d) ? fs.readdirSync(d) : []; } catch { return []; } };
// PU-G-147 : tout texte que le chat Projet affiche (noms de plan, de phase, de backlog, de seed, sujets de tag) se coupe au mot entier, par la même fonction que `sentence` (une seule)
export const clip = (s, n) => clipMot(s, n);
// PU-G-147 : la phrase d'un pied ou d'une description se coupe au mot entier (jamais « … avec le vr… ») ; un seul mot plus long que n est coupé net
export const clipMot = (s, n) => { s = String(s || '').replace(/\s+/g, ' ').replace(/\*\*/g, '').replace(/`/g, '').trim(); if (s.length <= n) return s; let c = s.slice(0, n - 1); if (/\S/.test(c.at(-1)) && /\S/.test(s[n - 1])) { const m = c.replace(/\s*\S+$/, ''); if (m) c = m; } return c.replace(/[\s,;:·(–—-]+$/, '') + '…'; };
export const sentence = (s, n = 200) => { s = String(s || '').replace(/\s+/g, ' ').replace(/\*\*/g, '').replace(/`/g, '').trim(); const i = s.search(/[.!?](\s|$)/); return clipMot(i > 25 ? s.slice(0, i + 1) : s, n); };
export const num = (s) => parseFloat(s);
export const fm = (txt) => { txt = texte(txt); const m = /^---\n([\s\S]*?)\n---/.exec(txt); const o = {}; if (!m) return o; for (const l of m[1].split('\n')) { const k = /^([\w-]+):[ \t]*([^\n]*)$/.exec(l); if (k) o[k[1]] = k[2].trim(); } return o; };
export const list = (v) => (v || '').replace(/^\[|\]$/g, '').split(',').map((s) => s.trim().replace(/^["']|["']$/g, '')).filter(Boolean);
// motifs des champs lus (titres, Goal, dépendances, exigences, statut) : vf-cockpit-formats.mjs, partagés avec le diagnostic de vf-cockpit-drift.mjs
const STATUS_SUFFIX = /\s*\((inscrite|completed|INSERTED|exécutée|cadrée|complete|clôturée|clos|CLOSE).*$/i;

function parseRoadmap(txt, ws, rel, phases) {
  // cases de phase : avec ou sans gras autour de « Phase N: nom » (ou « Phase N : nom »), suffixe « - … » ou « — … » retiré ; texte normalisé (CRLF, BOM) par l'appelant
  for (const m of txt.matchAll(reTitreCase())) {
    const n = normNum(m[2]); const key = `${ws || ''}|${n}`;
    if (phases.has(key)) continue;
    const reste = m[3].replace(/\s{2,}/g, ' '); // suites d'espaces repliées avant les motifs à \s+ (coût linéaire)
    let name = reste.includes('**') ? reste.split('**')[0] : reste.replace(/\s+[-—]\s.*$/, '');
    name = name.replace(STATUS_SUFFIX, '').replace(/\s+—\s+(complete|clôturée|CLOSE).*$/, '').replace(/^\[|\]$/g, '');
    phases.set(key, { key, n, ws: ws || null, name: clip(name, 90), done: m[1].toLowerCase() === 'x', line: m[3], roadmap: rel, goal: '', depends: [] });
  }
  // sections « ## », « ### » ou « #### » + « Phase N: nom » (ou « — nom ») : corps jusqu'au prochain en-tête de niveau 2 à 4
  for (const m of txt.matchAll(reTitreSection())) {
    const n = normNum(m[1]); const key = `${ws || ''}|${n}`;
    let ph = phases.get(key);
    if (!ph) { ph = { key, n, ws: ws || null, name: clip(m[2].replace(/^\[|\]$/g, ''), 90), done: false, line: '', roadmap: rel, goal: '', depends: [] }; phases.set(key, ph); }
    if (ph.goal) continue;
    ph.goal = lireGoal(m[3]);
    ph.depends = lireDependances(m[3], n);
  }
}

// jalons de la section « ## Milestones » : tiret simple ou cadratin, clé pouvant contenir des espaces
function parseMilestones(txt, ws, phases, out) {
  const sec = /## (?:Milestones|Jalons)\n([\s\S]*?)(?=\n## |\n> |(?![\s\S]))/.exec(txt)?.[1] || '';
  for (const entry of ('\n' + sec).split(/\n(?=- )/).filter((e) => e.startsWith('- '))) {
    const m = /^- (\S+) \*\*([^*]+)\*\*\s+[-—]\s+([\s\S]*)$/.exec(entry.trim());
    if (!m) continue;
    const key = m[2].trim();
    if (out.some((x) => x.key === key && x.ws === (ws || null))) continue;
    const text = m[3].replace(/\s+/g, ' ');
    const range = (/Phases? ([^—(]*)/.exec(text)?.[1] || '').replace(/Phases?|\*\*/g, '');
    const set = new Set();
    for (const part of range.split(/,|\+|\bet\b/)) {
      const r = new RegExp(`(?<![\\d.])${NUM}\\s*(?:-|→)\\s*${NUM}`).exec(part);
      if (r) { for (const ph of phases.values()) if (ph.ws === (ws || null) && num(ph.n) >= num(r[1]) && Math.floor(num(ph.n)) <= num(r[2])) set.add(ph.key); }
      else for (const x of part.matchAll(/\d+(?:\.\d+)?/g)) { const k = `${ws || ''}|${normNum(x[0])}`; if (phases.has(k)) set.add(k); }
    }
    for (const k of set) for (const o of out) if (o.ws === (ws || null)) o.phases.delete(k); // la phase appartient au dernier jalon qui la cite
    out.push({ key, id: 'ms-' + key.toLowerCase().replace(/[^a-z0-9.]/g, '-'), icon: m[1], text, phases: set, ws: ws || null });
  }
}

// dossiers de phase : NN-slug ou PREFIXE-NN-slug ; clé `<ws>|<n>`, repli `*|<n>` pour les archives
function dossiersDePhase(B, comps) {
  const phaseDirs = new Map(); const archives = ls(path.join(B, 'milestones'));
  const bases = [...comps.map((c) => [c.ws || '', path.join(c.dir, 'phases')]), ...archives.filter((d) => d.endsWith('-phases')).map((d) => ['*', path.join(B, 'milestones', d)])];
  for (const [ws, base] of bases) for (const d of ls(base)) {
    const m = /^(?:[A-Z][A-Z0-9]*-)?(\d+(?:\.\d+)?)-/.exec(d);
    if (m && !phaseDirs.has(`${ws}|${normNum(m[1])}`)) phaseDirs.set(`${ws}|${normNum(m[1])}`, path.join(base, d));
  }
  return phaseDirs;
}

// DAG : .planning, chaque compartiment, .planning/missions, puis chaque dossier de phase (JSON illisible ignoré).
// Chaque DAG : name, ws (dossier), wsDeclare (champ `ws` du DAG), phase (champ `phase` du DAG), file, nodes, dossierPhase.
export function lireDags(root, layout, phaseDirs) {
  root = path.resolve(root); layout = layout || planningLayout(root);
  const B = path.join(root, '.planning'); const comps = layout.compartiments || [];
  phaseDirs ||= dossiersDePhase(B, comps);
  const dags = []; const seen = new Set();
  const lots = [...comps.map((c) => [c.ws, c.dir, null]), [null, B, null], [null, path.join(B, 'missions'), null],
    ...[...phaseDirs].map(([k, d]) => [k.split('|')[0] === '*' || k.startsWith('|') ? null : k.split('|')[0], d, k])];
  for (const [ws, d, dossierPhase] of lots) {
    if (seen.has(d)) continue; seen.add(d);
    for (const f of ls(d).filter((x) => x.endsWith('.dag.json') || (x.startsWith('dag-') && x.endsWith('.json')))) { // AUDC-D5 : deux nommages (`<nom>.dag.json`, `dag-<nom>.json`) ; un JSON sans `nodes` est ignoré
      let j; try { j = JSON.parse(read(path.join(d, f))); } catch { continue; }
      if (j && Array.isArray(j.nodes)) dags.push({ name: f.endsWith('.dag.json') ? f.slice(0, -'.dag.json'.length) : f.slice('dag-'.length, -'.json'.length), ws, wsDeclare: typeof j.ws === 'string' ? j.ws : null,
        phase: typeof j.phase === 'string' || typeof j.phase === 'number' ? String(j.phase) : null, file: path.relative(root, path.join(d, f)).split(path.sep).join('/'), nodes: j.nodes, dossierPhase });
    }
  }
  return dags;
}

// opts : { sansTags (aucun appel git pour les tags : lecture d'un autre arbre), verrous (injectable : { etat, plat, liste }), scriptsDir, home, lab (racine du LAB observé pour l'environnement borné des sous-processus, H-1 ; défaut : root) } — la vie d'une mission se lit sur le verrou de sa phase (VFSG-06) ; lecture seulement si un nœud est `running`
export function readPlanning(root, layout, opts = {}) {
  root = path.resolve(root);
  // AUDC-A-02 : lecture confinée à la racine RÉELLE du lab par défaut — un lien symbolique sortant n'est jamais suivi (un confinement posé par l'appelant, N5, prime)
  if (CONFINE === null && fs.existsSync(root)) return lireConfine(root, () => readPlanning(root, layout, opts));
  layout = layout || planningLayout(root);
  const LAB = path.resolve(opts.lab || root); // un arbre git sous le lab (worktree) se lit avec cwd = l'arbre, mais le PATH est assaini par rapport au LAB (H-1)
  const B = path.join(root, '.planning');
  const rel = (abs) => path.relative(root, abs).split(path.sep).join('/');
  const archives = ls(path.join(B, 'milestones'));
  const phases = new Map(), reqs = new Map(), milestones = [];
  const comps = layout.compartiments.length ? layout.compartiments : [];

  for (const c of comps) parseRoadmap(texte(read(path.join(c.dir, 'ROADMAP.md'))), c.ws, rel(path.join(c.dir, 'ROADMAP.md')), phases);
  const activeKeys = new Set(phases.keys());
  for (const f of archives.filter((x) => x.endsWith('-ROADMAP.md'))) {
    const tmp = new Map(); parseRoadmap(texte(read(path.join(B, 'milestones', f))), null, rel(path.join(B, 'milestones', f)), tmp);
    for (const ph of tmp.values()) if (![...phases.values()].some((p) => p.n === ph.n)) phases.set(ph.key, { ...ph, archive: true });
  }
  for (const c of comps) parseMilestones(texte(read(path.join(c.dir, 'ROADMAP.md'))), c.ws, phases, milestones);
  for (const ms of milestones) for (const k of [...ms.phases]) if (!phases.has(k)) ms.phases.delete(k);

  const phaseDirs = dossiersDePhase(B, comps);

  // exigences : cases à cocher et table de traçabilité, rattachées dans le compartiment du fichier porteur
  const reqFiles = [...comps.map((c) => [c.ws || '', path.join(c.dir, 'REQUIREMENTS.md')]), ...archives.filter((f) => f.endsWith('-REQUIREMENTS.md')).map((f) => ['*', path.join(B, 'milestones', f)])];
  for (const [ws, f] of reqFiles) {
    const txt = texte(read(f));
    for (const m of txt.matchAll(reExigences())) { const id = idExigence(m); if (!reqs.has(`${ws}|${id}`)) reqs.set(`${ws}|${id}`, { id, ws: ws || null, wsKey: ws, done: m[1].toLowerCase() === 'x', text: texteExigence(m), file: rel(f) }); }
    for (const m of txt.matchAll(reTraceabilite())) { const r = reqs.get(`${ws}|${m[1]}`); if (r && !r.phase) r.phase = normNum(m[2]); }
  }
  // DG-10 (PU-G-052) : une exigence lue dans le fichier vivant d'un compartiment ET dans l'archive de jalon (clé joker `*`), avec le même identifiant et la même phase par la traçabilité,
  // est UNE exigence : l'entrée du fichier vivant (case à jour) reste, celle de l'archive est écartée. Sans phase connue des deux côtés, rien n'est écarté (deux archives peuvent réutiliser un identifiant).
  const vivantes = new Set([...reqs.values()].filter((r) => r.wsKey !== '*' && r.phase).map((r) => `${r.id}|${r.phase}`));
  for (const [k, r] of [...reqs]) if (r.wsKey === '*' && r.phase && vivantes.has(`${r.id}|${r.phase}`)) reqs.delete(k);

  // état : frontmatter du STATE du compartiment actif, repli sur la ligne de corps « Phase: N »
  const sf = stateFile(root, layout); const sTxt = sf ? texte(read(sf)) : '';
  const state = fm(sTxt);
  if (state.status) state.status = normStatut(state.status); // « In Progress », « "executing" » -> in_progress, executing
  if (state.current_phase) { const c = phaseCourante(state.current_phase); if (c !== null) state.current_phase = c; } // « "02" », « Phase 2 » -> 02, 2
  if (!state.current_phase) { const b = new RegExp(`^Phase:\\s*${NUM}`, 'm').exec(sTxt)?.[1]; if (b) state.current_phase = normNum(b); }

  // DAG puis avancement de chaque phase : missions rattachées par rattacherMission, état calculé sur les fichiers du dossier
  const dags = lireDags(root, layout, phaseDirs); const parPhase = new Map(); let verrous = null;
  for (const d of dags) {
    const r = rattacherMission(d, phases); d.phaseKey = r ? r.cle : null; d.regle = r ? r.regle : null;
    d.vie = null;
    if (d.nodes.some((x) => x?.status === 'running')) {
      verrous ||= opts.verrous || lireVerrous(root, { scriptsDir: opts.scriptsDir, home: opts.home, lab: LAB });
      const po = r ? phases.get(r.cle) : null; // ws et numéro viennent de l'objet de la phase rattachée (P68-D-22)
      d.vie = vieDe(po ? { ws: po.ws, phase: po.n } : { ws: d.ws || d.wsDeclare || null, phase: null }, verrous); d.etat = etatMission(d.nodes, d.vie);
    } else d.etat = etatMission(d.nodes);
    if (r) parPhase.set(r.cle, [...(parPhase.get(r.cle) || []), { nom: d.name, regle: r.regle, nodes: d.nodes, vie: d.vie }]);
  }
  for (const ph of phases.values()) {
    const dir = phaseDirs.get(`${ph.ws || ''}|${ph.n}`) || phaseDirs.get(`*|${ph.n}`);
    ph.avancement = avancement({ ph, fichiers: ls(dir), missions: parPhase.get(ph.key) || [], lire: (f) => read(path.join(dir, f)) });
  }
  const backlog = texte(read(path.join(B, 'BACKLOG.md')));
  const seeds = ls(path.join(B, 'seeds')).filter((f) => f.endsWith('.md')).map((f) => ({ file: rel(path.join(B, 'seeds', f)), text: texte(read(path.join(B, 'seeds', f))) }));
  let tags = [];
  if (!opts.sansTags && !gitSortant(root)) { // shBorne : même plafond, même échéance globale et même PATH assaini que les autres appels git du socle (F-06, H-1) ; sortie vide = aucun tag
    const out = shBorne('git', [...GIT_SUR, '-C', root, 'for-each-ref', '--sort=-creatordate', '--count=30', '--format=%(refname:short)\t%(creatordate:short)\t%(contents:subject)', 'refs/tags/v*'], undefined, LAB);
    tags = out.trim().split('\n').filter(Boolean).map((l) => { const [tag, date, subject] = l.split('\t'); return { tag, date, subject }; });
  }
  const title = /^# (.*)$/m.exec(texte(read(path.join(B, 'PROJECT.md'))))?.[1];
  const projectName = (title ? title.replace(/^(Project|Roadmap):\s*/i, '').trim() : '') || path.basename(root);
  return { phases, phaseDirs, reqs, milestones, state, dags, backlog, seeds, tags, projectName, activeKeys, rel };
}
