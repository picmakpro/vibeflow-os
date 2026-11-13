// VibeFlow (75-07, P75-D-05) : le canal de marquage des cartes. Une couche nommée porte une table de rangées ; la page ne lit que ce canal.
// L'objet global du moteur est gelé (P80-D-33) : le canal vit à part, sous window.VF_MARQUES, et n'étend jamais window.VibeFlow ni window.Floorplan.
//
// API publique (objet gelé) :
//   poser(couche, entrees, { exclusif })  couche = nom (chaîne non vide) ; entrees = rangées [id, palier, glyphe, mot, infobulle] ;
//                                         exclusif vaut true sauf s'il est EXACTEMENT false. Reposer une couche la remplace (elle passe au-dessus).
//                                         Rend true si posée, false si refusée (nom ou table invalide, canal fermé).
//   retirer(couche)                       défait la couche et RESTITUE la précédente ; rend le nom de la couche exclusive alors active, ou null.
//   active()                              nom de la couche exclusive visible, ou null (les couches non exclusives sont toujours visibles).
//   lire(id)                              tableau (vide si rien) de marques visibles de la carte : la couche exclusive d'abord, puis les non
//                                         exclusives dans l'ordre de pose ; marque = { couche, id, palier, glyphe, mot, infobulle, agrege, compte }.
//   brancherDessin(rappel)                point d'entrée de l'application visuelle (seconde moitié du plan) : rappel({ table }) est appelé après
//                                         chaque pose ou retrait et à chaque événement `render` du moteur ; rend la fonction qui le débranche.
//   table()                               [[id, marques]] pour toute carte marquée, ancêtres agrégés compris.
// Agrégat aux ancêtres : pour chaque couche visible et chaque ancêtre d'une carte marquée (chain(id) du moteur, sans la racine), UNE marque :
//   le palier maximal et le NOMBRE de fichiers à ce palier, jamais une somme sur les paliers (« 3 chauds » ; sans palier connu : « 2 fichiers »).
// File de résolution tardive : `window.VF_MARQUES_EN_ATTENTE`, tableau d'éléments { couche, entrees, exclusif } (une pose complète, mêmes
//   arguments que poser). Un consommateur chargé AVANT le canal y dépose sa pose ; au chargement le canal la vide (splice(0)) et applique chaque
//   élément, dans l'ordre, UNE fois. Le côté « dépôt » appartient au consommateur (Phase 74, 74-06) ; ici, seulement le vidage.
// Inscription : VF_COQUILLE.surOnglet(rappel, { cle: '75-vf-marques.js' }) ; le nettoyage rendu retire toutes les couches et ferme le canal.
(() => {
  'use strict';
  const CLE = '75-vf-marques.js', FILE = 'VF_MARQUES_EN_ATTENTE';
  const MAX_RANGEES = 20000, MAX_FILE = 64, MAX_ID = 400, MAX_MOT = 300, MAX_INFO = 600;
  const RANG = { bas: 0, moyen: 1, haut: 2, fini: 0, lu: 1, modifie: 2, 'en-cours': 3 }; // rang d'un palier connu (par couche, jamais mêlé)
  const MOTS = { haut: ['chaud', 'chauds'], moyen: ['moyen', 'moyens'], bas: ['peu changé', 'peu changés'], 'en-cours': ['en écriture', 'en écriture'],
    modifie: ['modifié', 'modifiés'], lu: ['lu', 'lus'], fini: ['fini', 'finis'] };
  const couches = []; // la pile : { nom, exclusif, rangees: [rangée…] } (une rangée par couple carte et palier)
  let ferme = false, index = null, peintre = null;

  const moteur = () => window.VibeFlow || window.Floorplan || null; // résolu tardivement, jamais à l'évaluation
  const rangDe = (p) => (typeof p === 'string' && Object.hasOwn(RANG, p) ? RANG[p] : Number.isInteger(p) && p >= 0 ? p : -1);
  const texte = (v, max) => String(v === undefined || v === null ? '' : v).slice(0, max);
  const visibles = () => {
    let haut = null;
    for (const c of couches) if (c.exclusif) haut = c;
    return couches.filter((c) => !c.exclusif || c === haut);
  };

  const rangee = (r) => {
    if (!Array.isArray(r) || typeof r[0] !== 'string' || r[0].length === 0 || r[0].length > MAX_ID) return null;
    const palier = typeof r[1] === 'number' || typeof r[1] === 'string' ? r[1] : null;
    return Object.freeze({ id: r[0], palier, glyphe: texte(r[2], 40), mot: texte(r[3], MAX_MOT), infobulle: texte(r[4], MAX_INFO) });
  };
  const marque = (couche, r, agrege, compte) => Object.freeze({
    couche, id: r.id, palier: r.palier, glyphe: r.glyphe, mot: r.mot, infobulle: r.infobulle, agrege, compte });

  // l'agrégat d'une couche : par ancêtre, le palier maximal et les fichiers (ids distincts) à ce palier
  const ancetres = (id) => {
    const M = moteur();
    if (!M || typeof M.chain !== 'function') return [];
    try { const c = M.chain(id); return Array.isArray(c) ? c.filter((a) => typeof a === 'string' && a !== id && a !== 'root') : []; } catch { return []; }
  };
  const agreger = (c) => {
    const par = new Map(); // ancêtre -> { rang, ids: Set, modele }
    for (const r of c.rangees) {
      const rang = rangDe(r.palier);
      for (const a of ancetres(r.id)) {
        let s = par.get(a);
        if (!s || rang > s.rang) { s = { rang, ids: new Set(), modele: r }; par.set(a, s); }
        if (rang === s.rang) s.ids.add(r.id);
      }
    }
    const sortie = new Map();
    for (const [a, s] of par) {
      const n = s.ids.size, k = n === 1 ? 0 : 1, mots = s.rang >= 0 ? MOTS[s.modele.palier] : null;
      const mot = `${n} ${(mots || ['fichier', 'fichiers'])[k]}`;
      sortie.set(a, marque(c.nom, { id: a, palier: s.rang >= 0 ? s.modele.palier : null, glyphe: s.modele.glyphe, mot, infobulle: mot }, true, n));
    }
    return sortie;
  };
  const construire = () => { // id -> marques visibles (propres puis agrégées, par couche visible)
    const t = new Map(), ajout = (id, m) => { if (!t.has(id)) t.set(id, []); t.get(id).push(m); };
    for (const c of visibles()) {
      for (const r of c.rangees) ajout(r.id, marque(c.nom, r, false, 1));
      for (const [a, m] of agreger(c)) ajout(a, m);
    }
    return t;
  };
  const indexer = () => { if (!index) index = construire(); return index; };

  // application visuelle : un seul point d'entrée, tolérant ; sans peintre ou sans moteur, il ne fait rien
  const dessiner = () => {
    if (!peintre || ferme) return;
    try { peintre({ table: table() }); } catch (e) { console.error('VibeFlow marques : le dessin a levé : ' + (e && e.message)); }
  };
  const change = () => { index = null; dessiner(); };

  const active = () => { const v = visibles().filter((c) => c.exclusif); return v.length ? v[v.length - 1].nom : null; };
  const lire = (id) => (typeof id === 'string' && indexer().has(id) ? indexer().get(id).slice() : []);
  const table = () => [...indexer()].map(([id, m]) => [id, m.slice()]);
  const retirer = (nom) => {
    const i = couches.findIndex((c) => c.nom === nom);
    if (i >= 0) { couches.splice(i, 1); change(); }
    return active();
  };
  const poser = (nom, entrees, options) => {
    if (ferme || typeof nom !== 'string' || nom.length === 0 || nom.length > 100 || !Array.isArray(entrees)) return false;
    const rangees = [];
    for (const e of entrees) {
      if (rangees.length >= MAX_RANGEES) break;
      const r = rangee(e);
      if (r) rangees.push(r);
    }
    const i = couches.findIndex((c) => c.nom === nom);
    if (i >= 0) couches.splice(i, 1); // reposer remplace, et la couche repasse au-dessus
    couches.push({ nom, exclusif: !(options && options.exclusif === false), rangees });
    change();
    return true;
  };
  const brancherDessin = (rappel) => {
    if (typeof rappel !== 'function') return () => {};
    peintre = rappel; dessiner();
    return () => { if (peintre === rappel) peintre = null; };
  };

  // la file de résolution tardive : vidée une fois, à l'enregistrement du canal
  const viderFile = () => {
    const f = window[FILE];
    if (!Array.isArray(f)) return;
    for (const e of f.splice(0, MAX_FILE)) if (e && typeof e === 'object') poser(e.couche, e.entrees, { exclusif: e.exclusif });
    f.length = 0;
  };

  // l'arrivée sur un onglet : le canal ne marque que le code ; le nettoyage rendu retire tout et ferme le canal
  const arrivee = (ev) => {
    if (!ev || ev.onglet !== 'code') { couches.length = 0; index = null; ferme = true; return () => {}; }
    ferme = false;
    const M = moteur();
    if (M && typeof M.on === 'function') { // `on` ne se défait pas : un seul écouteur par moteur, qui relaie vers l'instance courante
      const h = window.__vfMarquesRendu;
      if (h && h.moteur === M) h.dessiner = dessiner;
      else { const n = { moteur: M, dessiner }; window.__vfMarquesRendu = n; M.on('render', () => n.dessiner()); }
    }
    dessiner();
    return () => { couches.length = 0; index = null; ferme = true; peintre = null; };
  };

  const api = Object.freeze({ poser, retirer, active, lire, table, brancherDessin });
  window.VF_MARQUES = api;
  viderFile();
  if (window.VF_COQUILLE && typeof window.VF_COQUILLE.surOnglet === 'function') window.VF_COQUILLE.surOnglet(arrivee, { cle: CLE });
  else arrivee({ onglet: 'code' });
})();
