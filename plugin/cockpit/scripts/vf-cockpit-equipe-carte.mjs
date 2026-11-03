// vf-cockpit-equipe-carte — le graphe de l'onglet Équipe (69-05, P69-D-17), au format du viewer.
// Export : buildEquipeGraph(who, { nom, racine, logos }) -> graphe vibeflow/cockpit-equipe@1.
// Module pur ; schéma vibeflow/cockpit-equipe@1 ; aucun champ de transcript : seuls les champs de la collecte `who`
// (déjà bornés et masqués par collectWho) entrent dans une carte. Les sortes de carte (session, agent, terminés) n'ont
// ni pictogramme ni couleur : le viewer prend son repli. Aucun fichier (`files` vide), aucun lien.
const SORTES = new Set(['session', 'subagent']);
const clip = (s, n) => { const t = String(s ?? '').replace(/\s+/g, ' ').trim(); return t.length > n ? t.slice(0, n - 1) + '…' : t; };
const ST = { actif: 'active', 'en-attente': 'active', termine: 'done' };
const ETAT = { actif: 'actif', 'en-attente': 'en attente', termine: 'terminé' };

export function buildEquipeGraph(who, { nom = 'Projet', racine, logos } = {}) {
  const travailleurs = (Array.isArray(who?.workers) ? who.workers : []).filter((w) => w && SORTES.has(w.kind) && typeof w.id === 'string');
  const idCarte = (w) => (w.kind === 'session' ? 'se-' : 'ag-') + w.id;
  const parId = new Map(); // identifiant de travailleur -> carte (Map : jamais un objet indexé par une valeur lue sur disque, T-69-09)
  for (const w of travailleurs) if (!parId.has(w.id)) parId.set(w.id, idCarte(w));
  const compte = { actif: 0, enAttente: 0, termine: 0 };
  const nodes = [];
  const termines = new Map(); // carte parente -> nombre d'enfants terminés
  const base = { tags: [], paths: [], packages: [], hosts: [], stats: { files: 0, loc: 0, langs: {}, repos: ['.'] } };

  for (const w of travailleurs) {
    if (w.etat === 'termine') compte.termine++; else if (w.etat === 'en-attente') compte.enAttente++; else compte.actif++;
    const sous = w.kind === 'subagent';
    const parent = sous ? parId.get(w.parent) ?? null : null;
    const fini = w.etat === 'termine';
    if (fini && parent) termines.set(parent, (termines.get(parent) || 0) + 1);
    const lignes = [];
    if (w.role) lignes.push(`Rôle : ${w.role}`);
    lignes.push(`État : ${ETAT[w.etat] || 'actif'}`);
    if (w.branch) lignes.push(`Branche : ${w.branch}`);
    if (w.tree) lignes.push(`Arbre : ${w.tree}`);
    if (w.rattachement?.etat === 'rattache') lignes.push(`Nœud de mission : ${w.rattachement.noeud} (${w.rattachement.dag})`);
    nodes.push({ ...base, id: idCarte(w), parent: fini && parent ? `${parent}~termines` : parent, kind: sous ? 'agent' : 'session',
      label: sous ? clip([w.role, w.task].filter(Boolean).join(' · ') || 'Agent', 80) : `Session ${w.id.slice(0, 8)}`,
      summary: clip(w.task || '', 200), details: lignes.join('\n'), st: ST[w.etat] || 'active', foot: '' });
  }
  for (const [carte, n] of termines) {
    nodes.push({ ...base, id: `${carte}~termines`, parent: carte, kind: 'terminés', label: `Terminés depuis moins de 24 h (${n})`, summary: '', details: '', st: 'done', foot: '' });
  }
  const etatSource = (s) => ({ etat: s?.etat === 'lue' || s?.etat === 'absente' || s?.etat === 'erreur' || s?.etat === 'forme-inconnue' ? s.etat : 'absente' });
  const sources = {};
  for (const k of Object.keys(who?.sources || {})) sources[k] = etatSource(who.sources[k]);
  return {
    schema: 'vibeflow/cockpit-equipe@1',
    meta: { generatedAt: new Date().toISOString(), rootName: nom, root: racine, vfLogos: logos, audience: 'everyone', agent: 'claude', repos: [], counts: { files: 0, loc: 0 }, vfTab: 'equipe',
      kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Dispatche', contains: 'Contient' },
      vf: { compte, fenetre: who?.fenetre ?? null, sources } },
    project: { name: `${nom} — Équipe`, summary: `${compte.actif} actifs · ${compte.enAttente} en attente · ${compte.termine} terminés depuis moins de 24 h.` },
    nodes, files: [], links: [], flows: [], routes: [], tour: [],
  };
}
