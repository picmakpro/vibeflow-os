// vf-cockpit-trace-memoire — mémoire versionnée des agents lue en structure (76-03 ; TRAC-07, TRAC-08 ; P76-D-19 à D-23).
// Module PUR : aucun accès disque ni git.
// Exports : liensDe(txt), MOTIF_CHEMIN, entreesMemoire({ fichiers, index, head, historique, jours, fm }) ->
//   { agents: [{ agent, entrees, horsIndex, liensCasses, cheminsAbsents, sansEntrant, resolusParNom }],
//     entrees: [{ cle, chemin, agent, name, type, jour, sortants: [{ cible, etat: 'resolu' | 'resolu-par-nom' | 'casse', vers? }],
//       entrants: [cle], nbSortants, nbEntrants, horsIndex, sansEntrant, cheminsAbsents }],
//     compteurs: { entrees, agents, horsIndex, liensCasses, sansEntrant, cheminsAbsents, resolusParNom, entreesCitantAbsent } }
//   (P76-D-23 : contrat fourni à la Phase 77 par la route).
// Unités des compteurs : entrées pour entrees, horsIndex, sansEntrant, entreesCitantAbsent ; liens pour liensCasses et
// resolusParNom ; chemins DISTINCTS pour cheminsAbsents (chaque compteur dans son unité, jamais sommés).
// Aucun état tiré d'une date : le jour du dernier commit est une information, pas un verdict.
// Le texte des fichiers est lu ici pour en extraire liens et chemins, puis JETÉ : aucun objet rendu ne porte
// description, corps ou texte.
import { valeurImbriquee } from './vf-cockpit-frontmatter.mjs';

const RACINE = '.claude/agent-memory/';
// chemin relatif à extension (`segment/…/nom.ext`) ; jamais un jeton qui commence par `/` ou `~`
// (le point de départ ne suit ni un mot, ni `.`, ni `/`, ni `~`)
export const MOTIF_CHEMIN = /(?<![\w./~@-])(?:[\w@.-]+\/)+[\w@-][\w@.-]*\.[A-Za-z0-9]{1,8}(?![\w/])/g;

// cibles `[[…]]` : après retrait des blocs ```, des passages entre accents graves et des classes POSIX `[[:…:]]` ;
// cible bornée à 128 caractères, sans saut de ligne
export function liensDe(txt) {
  const nu = String(txt ?? '')
    .replace(/```[\s\S]*?(?:```|$)/g, ' ')
    .replace(/`[^`\n]*`/g, ' ')
    .replace(/\[\[:[^\]\n]*:\]\]/g, ' ');
  const out = [];
  for (const m of nu.matchAll(/\[\[([^[\]\n]{1,128})\]\]/g)) {
    const cible = m[1].split(/[|#]/)[0].trim();
    if (cible) out.push(cible);
  }
  return out;
}

// noms de fichier cités par les liens `](fichier.md)` d'un index, `./` initial retiré : le jugement « indexé » est une
// ÉGALITÉ sur cet ensemble (jamais une sous-chaîne)
const nomsIndexes = (txt) => new Set([...String(txt ?? '').matchAll(/\]\(([^)\s#]+)\)/g)]
  .map((m) => m[1].replace(/^(?:\.\/)+/, '')));
const decoupe = (chemin) => {
  const m = /^\.claude\/agent-memory\/([^/]+)\/([^/]+)$/.exec(chemin);
  return m ? { agent: m[1], fichier: m[2] } : null;
};
const ajoute = (m, k, v) => m.set(k, [...(m.get(k) ?? []), v]);
const stem = (f) => f.replace(/\.md$/, '');

// résolution d'une cible : name du même agent, puis du lab ; puis nom de fichier (même agent, puis lab) ; sinon casse.
// Plusieurs candidates : jamais un choix (pas de `vers`)
function resoudre(cible, e, ix) {
  const unique = (c, etat) => ({ cible, etat, ...(c.length === 1 ? { vers: c[0].cle } : {}) });
  let c = ix.nomAgent.get(`${e.agent}\0${cible}`) ?? [];
  if (!c.length) c = ix.nomLab.get(cible) ?? [];
  if (c.length) return unique(c, 'resolu');
  const s = stem(cible);
  c = ix.fichierAgent.get(`${e.agent}\0${s}`) ?? [];
  if (!c.length) c = ix.fichierLab.get(s) ?? [];
  return c.length ? unique(c, 'resolu-par-nom') : { cible, etat: 'casse' };
}

// chemins cités par un texte, relatifs au dépôt (premier segment connu de HEAD ou de l'historique),
// absents de HEAD et présents dans l'historique
function absentsCites(txt, { head, historique, premiers }) {
  const out = new Set();
  for (const m of String(txt ?? '').matchAll(MOTIF_CHEMIN)) {
    const p = m[0];
    if (premiers.has(p.split('/')[0]) && !head.has(p) && historique.has(p)) out.add(p);
  }
  return [...out].sort();
}

export function entreesMemoire(
  { fichiers = [], index = new Map(), head = new Set(), historique = new Set(), jours = new Map(), fm = () => ({}) } = {},
) {
  const entrees = [], textes = new Map(), indexes = new Map(index);
  for (const f of fichiers) {
    const d = decoupe(f.chemin);
    if (!d) continue;
    if (d.fichier === 'MEMORY.md') { if (!indexes.has(d.agent)) indexes.set(d.agent, f.txt); continue; }
    const cle = `${d.agent}/${d.fichier}`;
    textes.set(cle, f.txt);
    entrees.push({ cle, chemin: `${RACINE}${cle}`, agent: d.agent, fichier: d.fichier, name: fm(f.txt).name || null,
      type: valeurImbriquee(f.txt, ['metadata', 'type']), jour: jours.get(`${RACINE}${cle}`) ?? null, sortants: [], entrants: [] });
  }
  const ix = { nomAgent: new Map(), nomLab: new Map(), fichierAgent: new Map(), fichierLab: new Map() };
  for (const e of entrees) {
    if (e.name) { ajoute(ix.nomAgent, `${e.agent}\0${e.name}`, e); ajoute(ix.nomLab, e.name, e); }
    ajoute(ix.fichierAgent, `${e.agent}\0${stem(e.fichier)}`, e);
    ajoute(ix.fichierLab, stem(e.fichier), e);
  }
  const par = new Map(entrees.map((e) => [e.cle, e]));
  const premiers = new Set([...head, ...historique].map((p) => p.split('/')[0]));
  const jugeChemins = head.size > 0; // HEAD illisible (ensemble vide) : aucun chemin n'est jugé absent
  const indexes2 = new Map([...indexes].map(([a, t]) => [a, nomsIndexes(t)]));
  for (const e of entrees) {
    const txt = textes.get(e.cle);
    for (const cible of new Set(liensDe(txt))) {
      const s = resoudre(cible, e, ix);
      e.sortants.push(s);
      const v = s.vers && par.get(s.vers);
      if (v && v !== e && !v.entrants.includes(e.cle)) v.entrants.push(e.cle); // auto-liens exclus ; l'index n'est pas un lien
    }
    e.horsIndex = !(indexes2.get(e.agent) ?? new Set()).has(e.fichier);
    e.cheminsAbsents = jugeChemins ? absentsCites(txt, { head, historique, premiers }) : [];
  }
  for (const e of entrees) {
    e.nbSortants = e.sortants.length; e.nbEntrants = e.entrants.length; e.sansEntrant = e.entrants.length === 0;
    delete e.fichier;
  }
  const bilan = (liste) => {
    const liens = liste.flatMap((e) => e.sortants);
    return { entrees: liste.length, horsIndex: liste.filter((e) => e.horsIndex).length,
      liensCasses: liens.filter((l) => l.etat === 'casse').length, sansEntrant: liste.filter((e) => e.sansEntrant).length,
      cheminsAbsents: new Set(liste.flatMap((e) => e.cheminsAbsents)).size,
      resolusParNom: liens.filter((l) => l.etat === 'resolu-par-nom').length,
      entreesCitantAbsent: liste.filter((e) => e.cheminsAbsents.length).length };
  };
  const noms = [...new Set([...entrees.map((e) => e.agent), ...indexes.keys()])].sort();
  const agents = noms.map((agent) => {
    const { entreesCitantAbsent, ...b } = bilan(entrees.filter((e) => e.agent === agent));
    return { agent, ...b };
  });
  return { agents, entrees, compteurs: { ...bilan(entrees), agents: agents.length } };
}
