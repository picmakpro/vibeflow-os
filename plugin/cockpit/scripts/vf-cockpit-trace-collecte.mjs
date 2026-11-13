// vf-cockpit-trace-collecte — lecture de collecte des maillons d'une phase et projection sur cockpit-project@1 (TRAC-01, TRAC-02, TRAC-04 ; P76-D-13, P76-D-14, P76-D-31).
// Exports : lireTrace, traceDePhase, projeterTrace.
// Lecture uniquement par les fonctions injectées (`lire`, `lister`, `rel`, `fm`, `list`) : aucun `fs`, aucun import du module de lecture du planning (pas de cycle, 76-04 appelle `lireTrace` depuis `readPlanning`).
// Aucun corps de fichier n'entre dans un objet produit ; aucune RegExp n'est construite depuis une valeur lue dans le lab.
import path from 'node:path';
import { traceDuLedger } from './vf-cockpit-trace-ledger.mjs';

// identifiant d'exigence en mot entier (ni précédé ni suivi d'une lettre, d'un chiffre ou d'un tiret) : `P76-D-13` ou `ADR-073` n'en sont pas confondus avec un maillon
const ID_MOT = /(?<![A-Za-z0-9-])[A-Z][A-Z0-9]*-\d+[a-z]?(?![A-Za-z0-9-])/g;
const PLAFOND_CITES = 300;
const cites = (txt, seulementTables) => {
  const out = new Set();
  for (const l of String(txt || '').split('\n')) { if (seulementTables && !l.startsWith('|')) continue; for (const m of l.matchAll(ID_MOT)) { out.add(m[0]); if (out.size >= PLAFOND_CITES) return [...out]; } }
  return [...out];
};
const champ = (meta, nom, list) => (Object.hasOwn(meta, nom) ? list(meta[nom]) : null);

// { fichiers, lire(nom), rel(abs), dir, fm, list } -> trace d'une phase (forme de nodes[i].trace, voir le plan 76-01)
export function traceDePhase({ fichiers, lire, rel, dir, fm, list }) {
  const noms = [...(fichiers || [])].sort();
  const plans = noms.filter((f) => f.endsWith('-PLAN.md')).map((f) => {
    const id = f.slice(0, -'-PLAN.md'.length), s = `${id}-SUMMARY.md`;
    const exigences = champ(fm(lire(f)), 'requirements', list);
    const summary = noms.includes(s) ? { fichier: rel(path.join(dir, s)), exigences: champ(fm(lire(s)), 'requirements-completed', list) } : null;
    return { id, fichier: rel(path.join(dir, f)), exigences, criteres: null, summary };
  });
  const ver = noms.find((f) => /-VERIFICATION(?:-[\w-]+)?\.md$/.test(f));
  const verification = ver ? { fichier: rel(path.join(dir, ver)), status: null, cites: cites(lire(ver), true) } : null;
  return { plans, correctifs: [], verification, recette: null, preuves: [], lignesSansExigence: 0 };
}

// { phases, phaseDirs, reqs, ledgers: [{ ws, fichier, txt }], lire(abs), lister(dir), rel, fm, list } -> { phases: Map(key -> trace), ledger, exigences }
// phases non archivées seulement ; `reqs` : la Map de readPlanning ('<wsKey>|<id>' -> { id, ws, wsKey, done, text, file })
export function lireTrace({ phases, phaseDirs, reqs, ledgers, lire, lister, rel, fm, list }) {
  const statuts = new Map(), lignes = new Map(), sans = [];
  for (const l of ledgers || []) {
    const r = traceDuLedger({ txt: l.txt, ws: l.ws });
    for (const [k, v] of r.statuts) statuts.set(k, v);
    for (const [k, v] of r.lignes) lignes.set(k, v);
    sans.push(...r.lignesSansExigence);
  }
  const traces = new Map(), vivantes = [];
  for (const ph of phases.values()) {
    if (ph.archive) continue;
    const dir = phaseDirs.get(`${ph.ws || ''}|${ph.n}`) || phaseDirs.get(`*|${ph.n}`);
    const t = dir ? traceDePhase({ fichiers: lister(dir), lire: (f) => lire(path.join(dir, f)), rel, dir, fm, list }) : traceDePhase({ fichiers: [], lire, rel, dir: '', fm, list });
    t.lignesSansExigence = sans.filter((x) => x.phase === ph.n && x.ws === (ph.ws || '')).length;
    traces.set(ph.key, t); vivantes.push(ph);
  }
  const exigences = [];
  for (const r of reqs.values()) {
    const cle = `${r.wsKey ?? ''}|${r.id}`, st = statuts.get(cle) || null;
    const parPlan = vivantes.filter((ph) => (r.wsKey === '*' || (ph.ws || '') === r.wsKey) && traces.get(ph.key).plans.some((p) => p.exigences && p.exigences.includes(r.id))).map((ph) => ph.n).sort((a, b) => parseFloat(a) - parseFloat(b));
    const phase = st && st.phase != null ? st.phase : parPlan[0] ?? null;
    exigences.push({ id: r.id, ws: r.ws, coche: r.done, phase, phasesParPlan: parPlan, statut: st ? st.statut : null, fait: st ? st.fait : false,
      rattachement: st && st.phase != null ? st.rattachement : parPlan.length ? 'plan' : null, libelle: r.text, fichier: r.file, cites: { decisions: [], adrs: [], nues: [] } });
  }
  return { phases: traces, ledger: { statuts, lignes, lignesSansExigence: sans, etapes: null, n: (ledgers || []).length }, exigences };
}

const coupeDefaut = (s, n) => String(s ?? '').slice(0, n);
// pose les champs facultatifs sur `graphe` (cockpit-project@1 ne change pas de version) : nodes[i].trace, meta.vf.trace, meta.vf.jalonActif ; rend `graphe`
// `couper(texte, n)` : la coupe au mot reçue de l'appelant (critère <= 200, libellé <= 220)
export function projeterTrace(graphe, trace, { jalonActif = null, couper = coupeDefaut } = {}) {
  for (const n of graphe.nodes) {
    if (n.kind !== 'phase') continue;
    const t = trace.phases.get(`${n.ws || ''}|${n.num}`);
    if (t) n.trace = { ...t, plans: t.plans.map((p) => ({ ...p, criteres: p.criteres && { n: p.criteres.n, liste: p.criteres.liste.map((c) => couper(c, 200)) } })) };
  }
  const vf = ((graphe.meta ||= {}).vf ||= {});
  vf.trace = { exigences: trace.exigences.map((e) => ({ ...e, libelle: couper(e.libelle, 220), statut: e.statut === null ? null : couper(e.statut, 200) })), etapes: trace.ledger.etapes, ledgers: trace.ledger.n };
  vf.jalonActif = jalonActif;
  return graphe;
}
