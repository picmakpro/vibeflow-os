// vf-cockpit-trace-bilans — bilans exclusifs, vue de phase et vue de jalon de la traçabilité (TRAC-03 ; P76-D-14, UI-SPEC § 10.1).
// Exports : bilanExigences, vuePhase, vueJalon. Des chiffres et des codes, jamais de texte français : la page ne recompte jamais (§ 4.3).
import { MAILLONS, lignesDePhase } from './vf-cockpit-trace-chaine.mjs';

// catégorie exclusive d'une exigence, dans l'ordre contradiction, manque, non lisible, complète : « complète » seulement si les quatre maillons sont lus
const RANG = ['contradiction', 'manque', 'non-lisible', 'complete'];
const categorie = (ligne) => { const e = MAILLONS.map((m) => ligne.maillons[m].etat); return RANG.find((c) => c === 'complete' || e.includes(c)); };
const nomDe = (n) => n.label.replace(/^Phase [\d.]+ · /, '');
const noeudPhase = (projet, cle) => projet.nodes.find((n) => n.kind === 'phase' && `${n.ws || ''}|${n.num}` === cle) || null;

// lignes d'exigence -> { total, contradiction, manque, nonLisible, complete } (somme des quatre = total)
export function bilanExigences(lignes) {
  const b = { total: lignes.length, contradiction: 0, manque: 0, nonLisible: 0, complete: 0 };
  for (const l of lignes) { const c = categorie(l); b[c === 'non-lisible' ? 'nonLisible' : c]++; }
  return b;
}

// une phase par sa clé `<ws>|<n>` : bilan, exigences triées par catégorie (à égalité, l'ordre du ledger), plans et preuves
export function vuePhase(projet, cle) {
  const n = noeudPhase(projet, cle);
  if (!n) return null;
  const lignes = lignesDePhase(projet, n);
  const triees = lignes.map((l, i) => [RANG.indexOf(categorie(l)), i, l]).sort((a, b) => a[0] - b[0] || a[1] - b[1]).map((x) => x[2]);
  return { phase: { id: n.id, cle, n: n.num, ws: n.ws || null, nom: nomDe(n) }, bilan: bilanExigences(lignes), exigences: triees,
    plans: n.trace ? n.trace.plans : [], preuves: n.trace ? n.trace.preuves : [] };
}

// le jalon mis en avant seulement (meta.vf.jalonActif) : bilan exclusif par phase selon sa pire exigence plus `sansExigence`, somme = nombre de phases
export function vueJalon(projet) {
  const id = String(projet.meta?.vf?.jalonActif || '').replace(/^n:/, '');
  const jalon = projet.nodes.find((n) => n.kind === 'jalon' && n.id === id) || null;
  const bilan = { total: 0, contradiction: 0, manque: 0, nonLisible: 0, sansExigence: 0, complete: 0 };
  const phases = (jalon ? projet.nodes.filter((n) => n.kind === 'phase' && n.parent === jalon.id) : []).map((n) => {
    const lignes = lignesDePhase(projet, n), b = bilanExigences(lignes);
    const pire = !lignes.length ? 'sansExigence' : b.contradiction ? 'contradiction' : b.manque ? 'manque' : b.nonLisible ? 'nonLisible' : 'complete';
    bilan.total++; bilan[pire]++;
    // chevauchement entre maillons : un compteur par maillon (non lu = manque, non lisible ou contradiction), puis les maillons par état (la
    // contradiction n'est jamais comptée manque)
    const defaut = { plan: 0, summary: 0, verification: 0, recette: 0, manquants: 0, nonLisibles: 0, contradictions: 0 };
    const parEtat = { manque: 'manquants', 'non-lisible': 'nonLisibles', contradiction: 'contradictions' };
    for (const l of lignes) for (const m of MAILLONS) { const e = l.maillons[m].etat; if (e !== 'lu') { defaut[m]++; defaut[parEtat[e]]++; } }
    return { id: n.id, cle: `${n.ws || ''}|${n.num}`, n: n.num, ws: n.ws || null, nom: nomDe(n), etat: n.avancement ? n.avancement.etat : null,
      bilan: b, maillonsEnDefaut: defaut, exigencesEnContradiction: b.contradiction, lignesSansExigence: n.trace ? n.trace.lignesSansExigence : 0 };
  });
  return { jalon: jalon ? { id: jalon.id, nom: jalon.label } : null, bilan, phases };
}
