// vf-cockpit-questions-attente — questions en attente lues dans les sections « À Samuel » des registres de phase (76-09 ; TRAC-13 ;
// P76-D-34 à D-37 ; grammaire C76-Q1, forme C76-Q2). Module PUR : le texte des `*-CONTEXT.md` est lu par la collecte (confiné), aucune lecture ici.
// Exports : lireQuestions, projeterQuestions, DEFAUTS, MAX_QUESTIONS.
// Fermé par défaut (P76-D-36) : une entrée hors grammaire est « mal formée » avec ses défauts nommés, jamais « en attente » ; aucun balisage produit.
// Aucune RegExp n'est construite depuis une valeur lue dans le lab.
import { DEFAUTS, lireOptions, lireReco, lireBloque, lireEtat } from './vf-cockpit-questions-champs.mjs';
import { definitionsRegistre } from './vf-cockpit-registres.mjs';

export { DEFAUTS };
export const MAX_QUESTIONS = 200;
const MAX_LUES = 2000;
const TETE = /^- \*\*(P[0-9]+(?:\.[0-9]+)*-Q-[0-9]{2,}) — (.+?)\.\*\*(.*)$/;
const CHAMP = /^(Options|Recommandation|Bloque|État)[  ]*:[  ]*(.*)$/;
const FENCE = /^\s*(```|~~~)/;
const INDENTEE = /^[ \t]+\S/;

// [début, fin[ de la première section `## À Samuel…` (hors blocs de code), ou null
function section(lignes) {
  let dedans = false, deb = -1;
  for (let i = 0; i < lignes.length; i++) {
    if (FENCE.test(lignes[i])) { dedans = !dedans; continue; }
    if (dedans || !/^## /.test(lignes[i])) continue;
    if (deb >= 0) return [deb, i];
    if (/^##[ \t]+À Samuel/.test(lignes[i])) deb = i;
  }
  return deb < 0 ? null : [deb, lignes.length];
}

// têtes d'entrées de la section (avec leurs lignes de suite indentées) et nombre de puces de premier niveau d'un autre format
function entrees(lignes, [deb, fin]) {
  const out = []; let nonStructurees = 0;
  for (let i = deb + 1; i < fin;) {
    if (!/^[-*+][ \t]/.test(lignes[i])) { i++; continue; }
    const m = TETE.exec(lignes[i]);
    if (!m) { nonStructurees++; i++; continue; }
    const corps = []; let j = i + 1;
    for (; j < fin; j++) {
      if (INDENTEE.test(lignes[j])) { corps.push(lignes[j]); continue; }
      if (lignes[j].trim() !== '') break;
      let k = j + 1; while (k < fin && lignes[k].trim() === '') k++;
      if (k >= fin || !INDENTEE.test(lignes[k])) break;
    }
    out.push({ m, ligne: i + 1, corps, debut: i, fin: j }); i = j;
  }
  return { out, nonStructurees };
}

const norme = (n) => String(Number(n));
// lit une entrée : jamais d'état final ici (les doublons se jugent sur l'ensemble des fichiers), seulement les champs, les défauts et le genre d'état
function lireEntree(e, ctx, lignes, defs, servi) {
  const [, id, titre, reste] = e.m, d = new Set(), champs = {}, libres = [reste.trim()];
  for (const l of e.corps) {
    const c = CHAMP.exec(l.trim());
    if (!c) { libres.push(l.trim()); continue; }
    if (c[1] in champs) d.add('champ-repete'); else champs[c[1]] = c[2].trim();
  }
  if (['Options', 'Recommandation', 'Bloque'].some((n) => !(n in champs))) d.add('champ-manquant');
  const options = 'Options' in champs ? lireOptions(champs.Options) : null;
  if ('Options' in champs && !options) d.add('options-invalides');
  const reco = 'Recommandation' in champs ? lireReco(champs.Recommandation, options) : null;
  if ('Recommandation' in champs && !reco) d.add('recommandation-hors-options');
  const bloque = 'Bloque' in champs ? lireBloque(champs.Bloque) : null;
  if ('Bloque' in champs && !bloque) d.add('bloque-invalide');
  let etat = null;
  if (!('État' in champs)) d.add('etat-absent');
  else {
    etat = lireEtat(champs['État'], options);
    if (etat.kind === 'invalide') d.add('etat-invalide');
    else if (etat.kind === 'appliquee') {
      if (reco && reco.lettre !== etat.appliquee.option) d.add('appliquee-hors-recommandation');
      else if (reco && !defs.has(etat.appliquee.decision)) d.add('decision-introuvable');
    } else if (etat.kind === 'attente' && citeParDecision(lignes, id, e)) d.add('citation-incoherente');
  }
  if (norme(/^P([0-9]+(?:\.[0-9]+)*)-/.exec(id)[1]) !== norme(ctx.key.split('|')[1])) d.add('phase-incoherente');
  const s = (x, n) => servi(x, n);
  return { id, ctx, ligne: e.ligne, d, kind: etat ? etat.kind : 'absent', etat, reco,
    corps: { titre: s(titre, 80), question: s(libres.filter(Boolean).join(' '), 240),
      options: (options || []).map((o) => ({ cle: o.cle, texte: s(o.texte, 160) })),
      recommandation: reco ? reco.lettre : null, bloque: bloque || [] },
    sv: s };
}

// une décision du même fichier, hors de l'entrée, qui contient l'identifiant (mot entier) ET « arbitrage Samuel »
function citeParDecision(lignes, id, e) {
  return lignes.some((l, i) => {
    if ((i >= e.debut && i < e.fin) || !l.includes('arbitrage Samuel')) return false;
    let p = l.indexOf(id);
    while (p >= 0) {
      if (!/[A-Za-z0-9-]/.test(l[p - 1] || ' ') && !/[A-Za-z0-9]/.test(l[p + id.length] || ' ')) return true;
      p = l.indexOf(id, p + 1);
    }
    return false;
  });
}

const ORDRE = new Map(DEFAUTS.map((x, i) => [x, i]));
function finale(r, double, phases) {
  const d = new Set(r.d); if (double) d.add('identifiant-double');
  const defauts = [...d].sort((a, b) => ORDRE.get(a) - ORDRE.get(b));
  const phase = phases.get(r.ctx.key) ?? null, base = { id: r.id, phase, fichier: r.ctx.fichier, ligne: r.ligne };
  const avert = defauts.length > 0 && defauts.every((x) => x === 'citation-incoherente' || x === 'decision-introuvable');
  if (defauts.length && !avert) return { ...base, etat: 'mal-formee', defauts };
  const etat = avert ? 'a-verifier' : { attente: 'en-attente', tranchee: 'tranchee', appliquee: 'appliquee' }[r.kind];
  const tr = r.kind === 'tranchee' && !avert, ap = r.kind === 'appliquee';
  return { ...base, ws: r.ctx.ws || null, titre: r.corps.titre, question: r.corps.question, options: r.corps.options, recommandation: r.corps.recommandation,
    bloque: r.corps.bloque, etat, tranchee: tr ? { ...r.etat.tranchee, canal: r.sv(r.etat.tranchee.canal, 80), citation: r.sv(r.etat.tranchee.citation, 240) }
      : null,
    appliquee: ap ? { ...r.etat.appliquee, canal: r.sv(r.etat.appliquee.canal, 80) } : null, defauts };
}

// { contextes: [{ key, ws, fichier, txt }], phases: Map(clé `<ws>|<n>` -> identifiant de nœud), servi(texte, n) } -> { liste, bilan, tronque }
export function lireQuestions({ contextes = [], phases = new Map(), servi = (s, n) => String(s ?? '').slice(0, n) } = {}) {
  const lues = []; let nonStructurees = 0, registresLus = 0, tronque = false;
  for (const ctx of contextes) {
    if (String(ctx.key).startsWith('*|') || tronque) continue; // une question d'un jalon clos n'attend plus rien (archives écartées avant toute lecture)
    const lignes = String(ctx.txt ?? '').replace(/\r\n?/g, '\n').split('\n'), sec = section(lignes);
    if (!sec) continue;
    registresLus++;
    const { out, nonStructurees: ns } = entrees(lignes, sec); nonStructurees += ns;
    const defs = new Set(definitionsRegistre(ctx.txt).map((x) => x.id));
    for (const e of out) {
      if (lues.length >= MAX_LUES) { tronque = true; break; }
      lues.push(lireEntree(e, ctx, lignes, defs, servi));
    }
  }
  const nb = new Map(); for (const r of lues) nb.set(r.id, (nb.get(r.id) || 0) + 1);
  const toutes = lues.map((r) => finale(r, nb.get(r.id) > 1, phases));
  const compte = (etat) => toutes.filter((x) => x.etat === etat).length;
  const bilan = { enAttente: compte('en-attente'), appliquees: compte('appliquee'), tranchees: compte('tranchee'), aVerifier: compte('a-verifier'),
    malFormees: compte('mal-formee'), nonStructurees, registresLus };
  const num = (x) => Number(x.id.slice(1, x.id.indexOf('-Q-')));
  toutes.sort((a, b) => num(a) - num(b) || String(a.ws).localeCompare(String(b.ws)) || a.id.localeCompare(b.id, 'en', { numeric: true }));
  return { liste: toutes.slice(0, MAX_QUESTIONS), bilan, tronque: tronque || toutes.length > MAX_QUESTIONS };
}

// pose `graphe.meta.vf.questions` (absent si aucun registre lu n'a de section) ; une panne laisse le champ absent, jamais le graphe cassé
export function projeterQuestions(graphe, trace, { servi, racine, phases } = {}) {
  try {
    const q = lireQuestions({ contextes: (trace && trace.contextes) || [], phases: phases || new Map(),
      ...(typeof servi === 'function' ? { servi: (s, n) => servi(s, n, { racine }) } : {}) });
    if (q.bilan.registresLus > 0) ((graphe.meta ||= {}).vf ||= {}).questions = q;
  } catch { /* le graphe se construit sans le champ */ }
  return graphe;
}
