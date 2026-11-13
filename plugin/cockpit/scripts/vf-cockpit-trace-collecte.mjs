// vf-cockpit-trace-collecte — lecture de collecte des maillons d'une phase et projection sur cockpit-project@1 (TRAC-01, TRAC-02, TRAC-04 ; P76-D-13,
// P76-D-14, P76-D-31).
// Exports : lireTrace, traceDePhase, projeterTrace. Tout texte projeté passe par `servi` (secrets masqués, aucun chemin du poste, TRAC-11).
// Lecture uniquement par les fonctions injectées (`lire`, `lister`, `rel`, `fm`, `list`) : aucun `fs`, aucun import du module de lecture du planning
// (pas de cycle, 76-04 appelle `lireTrace` depuis `readPlanning`).
// Aucun corps de fichier n'entre dans un objet produit ; aucune RegExp n'est construite depuis une valeur lue dans le lab.
import path from 'node:path';
import { listeImbriquee } from './vf-cockpit-frontmatter.mjs';
import { traceDuLedger, citationsLigne } from './vf-cockpit-trace-ledger.mjs';
import { ligneStatutRecette, recetteFaite } from './vf-cockpit-avancement.mjs';
import { servi } from './vf-cockpit-trace-texte.mjs';
import { definitionsRegistre } from './vf-cockpit-registres.mjs';

// identifiant d'exigence en mot entier (ni précédé ni suivi d'une lettre, d'un chiffre ou d'un tiret) : `P76-D-13` ou `ADR-073` n'en sont pas
// confondus avec un maillon
const ID_MOT = /(?<![A-Za-z0-9-])[A-Z][A-Z0-9]*-\d+[a-z]?(?![A-Za-z0-9-])/g;
const PLAFOND_CITES = 300;
const cites = (txt, seulementTables) => {
  const out = new Set();
  for (const l of String(txt || '').split('\n')) {
    if (seulementTables && !l.startsWith('|')) continue;
    for (const m of l.matchAll(ID_MOT)) { out.add(m[0]); if (out.size >= PLAFOND_CITES) return [...out]; }
  }
  return [...out];
};
// champ de liste du frontmatter : null si absent ou vide (illisible), jamais [] (un champ vide n'est pas un champ lu)
const champ = (meta, nom, list) => (Object.hasOwn(meta, nom) && meta[nom] !== '' ? list(meta[nom]) : null);
// champs d'exigence d'un SUMMARY (`requirements:` ET `requirements-completed:`) : union des champs présents, null si aucun n'est lisible
const champsSummary = (meta, list) => {
  const l = ['requirements', 'requirements-completed'].map((n) => champ(meta, n, list)).filter((x) => x !== null);
  return l.length ? [...new Set(l.flat())] : null;
};
// critères `must_haves.truths` d'un PLAN : comptés (n) et listés (30 au plus), null sans critère ; chaque critère est coupé à 200 caractères à la projection
const criteres = (txt) => { const l = listeImbriquee(txt, ['must_haves', 'truths']); return l.length ? { n: l.length, liste: l.slice(0, 30) } : null; };
const statutDe = (v) => (v ? String(v).replace(/^["']|["']$/g, '').trim() || null : null);

// { fichiers, lire(nom), rel(abs), dir, fm, list } -> trace d'une phase (forme de nodes[i].trace, voir le plan 76-01)
export function traceDePhase({ fichiers, lire, rel, dir, fm, list }) {
  const noms = [...(fichiers || [])].sort();
  const somme = (s) => ({ fichier: rel(path.join(dir, s)), exigences: champsSummary(fm(lire(s)), list) });
  const plans = noms.filter((f) => f.endsWith('-PLAN.md')).map((f) => {
    const id = f.slice(0, -'-PLAN.md'.length), s = `${id}-SUMMARY.md`;
    const exigences = champ(fm(lire(f)), 'requirements', list);
    return { id, fichier: rel(path.join(dir, f)), exigences, criteres: criteres(lire(f)), summary: noms.includes(s) ? somme(s) : null };
  });
  const ids = new Set(plans.map((p) => p.id));
  // un SUMMARY sans PLAN est un correctif (P69-D-04)
  const correctifs = noms.filter((f) => f.endsWith('-SUMMARY.md') && !ids.has(f.slice(0, -'-SUMMARY.md'.length))).map(somme);
  const ver = noms.find((f) => /-VERIFICATION(?:-[\w-]+)?\.md$/.test(f));
  let verification = null;
  if (ver) { const txt = lire(ver); verification = { fichier: rel(path.join(dir, ver)), status: statutDe(fm(txt).status), cites: cites(txt, true) }; }
  const rec = noms.find((f) => /-RECETTE-[\w-]*\.md$/.test(f));
  let recette = null;
  if (rec) {
    const txt = lire(rec), ligne = ligneStatutRecette(txt); // la règle de reste(), réutilisée (P76-D-14)
    const statut = ligne ? ligne.replace(/^\*\*Statut[ \t\u00a0]*:\**[ \t]*/, '').replace(/\*\*/g, '').trim() || null : null;
    recette = { fichier: rel(path.join(dir, rec)), statut, faite: recetteFaite(ligne), cites: cites(txt, false) };
  }
  // preuves (TRAC-04) : chemins relatifs et statut lu, jamais un corps ; un fichier absent ne produit rien
  const preuves = [];
  if (verification) preuves.push({ sorte: 'verification', fichier: verification.fichier, plan: null, statut: verification.status });
  if (recette) preuves.push({ sorte: 'recette', fichier: recette.fichier, plan: null, statut: recette.statut });
  for (const [sorte, fin] of [['trace-rouge', '-RED-TRACE.md'], ['securite', '-SECURITY.md'], ['validation', '-VALIDATION.md']]) {
    for (const f of noms.filter((x) => x.endsWith(fin))) {
      const pid = f.slice(0, -fin.length), plan = sorte === 'trace-rouge' && ids.has(pid) ? pid : null;
      preuves.push({ sorte, fichier: rel(path.join(dir, f)), plan, statut: null });
    }
  }
  return { plans, correctifs, verification, recette, preuves, lignesSansExigence: 0 };
}

// { phases, phaseDirs, reqs, ledgers: [{ ws, fichier, txt }], lire(abs), lister(dir), rel, fm, list }
//   -> { phases: Map(key -> trace), ledger, exigences, contextes }
// phases non archivées seulement ; `reqs` : la Map de readPlanning ('<wsKey>|<id>' -> { id, ws, wsKey, done, text, file })
export function lireTrace({ phases, phaseDirs, reqs, ledgers, lire, lister, rel, fm, list }) {
  const statuts = new Map(), lignes = new Map(), sans = [], etapes = { lues: 0, sansDossier: 0 };
  for (const l of ledgers || []) {
    const r = traceDuLedger({ txt: l.txt, ws: l.ws, dossiers: phaseDirs });
    etapes.lues += r.etapes.lues; etapes.sansDossier += r.etapes.sansDossier;
    for (const [k, v] of r.statuts) statuts.set(k, v);
    for (const [k, v] of r.lignes) lignes.set(k, v);
    sans.push(...r.lignesSansExigence);
  }
  const traces = new Map(), vivantes = [];
  for (const ph of phases.values()) {
    if (ph.archive) continue;
    const dir = phaseDirs.get(`${ph.ws || ''}|${ph.n}`) || phaseDirs.get(`*|${ph.n}`);
    const t = dir ? traceDePhase({ fichiers: lister(dir), lire: (f) => lire(path.join(dir, f)), rel, dir, fm, list })
      : traceDePhase({ fichiers: [], lire, rel, dir: '', fm, list });
    t.lignesSansExigence = sans.filter((x) => x.phase === ph.n && x.ws === (ph.ws || '')).length;
    traces.set(ph.key, t); vivantes.push(ph);
  }
  // textes des *-CONTEXT.md de chaque dossier de phase, gardés en mémoire pour la projection (jamais projetés tels quels)
  const contextes = [];
  for (const [key, dir] of phaseDirs) for (const f of lister(dir).filter((x) => x.endsWith('-CONTEXT.md')).sort()) {
    contextes.push({ key, ws: key.split('|')[0], fichier: rel(path.join(dir, f)), txt: lire(path.join(dir, f)) });
  }
  const exigences = [];
  for (const r of reqs.values()) {
    const cle = `${r.wsKey ?? ''}|${r.id}`, st = statuts.get(cle) || null;
    const citeParPlan = (ph) => traces.get(ph.key).plans.some((p) => p.exigences && p.exigences.includes(r.id));
    const parPlan = vivantes.filter((ph) => (r.wsKey === '*' || (ph.ws || '') === r.wsKey) && citeParPlan(ph))
      .map((ph) => ph.n).sort((a, b) => parseFloat(a) - parseFloat(b));
    const phase = st && st.phase != null ? st.phase : parPlan[0] ?? null;
    exigences.push({ id: r.id, ws: r.ws, coche: r.done, phase, phasesParPlan: parPlan, statut: st ? st.statut : null, fait: st ? st.fait : false,
      rattachement: st && st.phase != null ? st.rattachement : parPlan.length ? 'plan' : null,
      libelle: r.text, fichier: r.file, cites: citationsLigne(lignes.get(cle)) });
  }
  const ledger = { statuts, lignes, lignesSansExigence: sans, etapes: etapes.lues ? etapes : null, n: (ledgers || []).length };
  return { phases: traces, ledger, exigences, contextes };
}

const coupeDefaut = (s, n) => String(s ?? '').slice(0, n);
// pose les champs facultatifs sur `graphe` (cockpit-project@1 ne change pas de version) : nodes[i].trace, meta.vf.trace, meta.vf.registres,
// meta.vf.jalonActif ; rend `graphe`
// `couper(texte, n)` : la coupe au mot reçue de l'appelant ; `racine` : le chemin du lab, rendu relatif dans les textes ;
// une panne laisse `meta.vf.trace = { erreur: true }`
export function projeterTrace(graphe, trace, { jalonActif = null, couper = coupeDefaut, racine } = {}) {
  const vf = ((graphe.meta ||= {}).vf ||= {});
  vf.jalonActif = jalonActif;
  if (!trace || trace.erreur) { vf.trace = { erreur: true }; return graphe; }
  try {
    const sv = (x, n) => (x == null ? null : servi(x, n, { racine, couper }));
    const noeuds = new Map(graphe.nodes.filter((n) => n.kind === 'phase').map((n) => [`${n.ws || ''}|${n.num}`, n]));
    for (const [cle, n] of noeuds) {
      const t = trace.phases.get(cle);
      if (!t) continue;
      const critere = (c) => c && { n: c.n, liste: c.liste.map((x) => sv(x, 200)) };
      n.trace = { ...t, plans: t.plans.map((p) => ({ ...p, criteres: critere(p.criteres) })),
        verification: t.verification && { ...t.verification, status: sv(t.verification.status, 200) },
        recette: t.recette && { ...t.recette, statut: sv(t.recette.statut, 200) },
        preuves: t.preuves.map((p) => ({ ...p, statut: sv(p.statut, 200) })) };
    }
    // registres : une entrée par CONTEXT dont le dossier a un nœud de phase, la clé d'une décision porte l'identifiant de CE nœud (jamais recalculé ici)
    const registres = []; let registresSansPhase = 0;
    for (const c of trace.contextes || []) {
      const n = noeuds.get(c.key) || (c.ws === '*' ? noeuds.get(`|${c.key.split('|')[1]}`) : undefined);
      if (!n) { registresSansPhase++; continue; }
      const decisions = definitionsRegistre(c.txt, { phase: n.id, ws: n.ws || null, fichier: c.fichier, couper: (s, k) => sv(s, k) });
      registres.push({ fichier: c.fichier, ws: n.ws || null, phase: n.id, decisions: decisions.map(({ ligne, ...d }) => d) });
    }
    const exigence = (e) => ({ ...e, libelle: sv(e.libelle, 220), statut: sv(e.statut, 200) });
    vf.trace = { exigences: trace.exigences.map(exigence), etapes: trace.ledger.etapes, ledgers: trace.ledger.n, registresSansPhase };
    vf.registres = registres;
  } catch {
    for (const n of graphe.nodes) delete n.trace;
    vf.trace = { erreur: true }; delete vf.registres;
  }
  return graphe;
}
