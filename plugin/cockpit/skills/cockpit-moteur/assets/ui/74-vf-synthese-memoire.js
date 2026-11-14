// VibeFlow (77-04) : mémoire pure de la dernière visite (P77-D-07, P77-D-08, P77-D-09). Aucun DOM, aucun stockage, aucune horloge : la page lit et écrit
// le stockage du navigateur elle-même (plan 77-05) et passe ici les textes et l'heure en secondes. Tout texte lu est vérifié sur liste fermée ; une valeur
// corrompue, trop grosse, d'une autre version ou portant une clé de plus est lue comme « première visite » (null), sans exception.
// Pose window.__vfSyntheseMemoire.
(() => {
  const PREFIXE = 'vibeflow-cockpit:derniere-visite:', TAILLE_MAX = 8192, SEUIL_ROTATION_S = 1800, LAB_RE = /^[0-9a-f]{12}$/;
  const ETATS = ['a-faire', 'en-cours', 'a-recetter', 'fait'];
  const CLE_PHASE = /^[^|\s]{0,64}\|[0-9]+(\.[0-9]+)*$/, SHA = /^[0-9a-f]{40}$/, H12 = /^[0-9a-f]{12}$/;
  const possede = (o, k) => Object.prototype.hasOwnProperty.call(o, k);

  // une clé par lab (identifiant de 12 hex), jamais de repli par origine
  const cle = (lab) => (typeof lab === 'string' && LAB_RE.test(lab) ? PREFIXE + lab : null);

  // taille en octets UTF-8, sans API du navigateur (une unité isolée compte comme son remplacement : 3 octets)
  function octets(t) {
    let n = 0;
    for (let i = 0; i < t.length; i++) {
      const c = t.charCodeAt(i);
      if (c < 0x80) n += 1;
      else if (c < 0x800) n += 2;
      else if (c >= 0xd800 && c < 0xdc00 && i + 1 < t.length && (t.charCodeAt(i + 1) & 0xfc00) === 0xdc00) { n += 4; i++; }
      else n += 3;
    }
    return n;
  }
  const ferme = (o, cles) => !!o && typeof o === 'object' && !Array.isArray(o) && Object.keys(o).length === cles.length && cles.every((k) => possede(o, k));

  // un instantané relu : null (absent, permis), undefined (invalide) ou l'objet reconstruit sans prototype
  function lireInstantane(o) {
    if (o === null) return null;
    if (!ferme(o, ['vu', 'phases', 'tete', 'blocages'])) return undefined;
    if (!Number.isInteger(o.vu) || o.vu <= 0) return undefined;
    if (!o.phases || typeof o.phases !== 'object' || Array.isArray(o.phases)) return undefined;
    const ks = Object.keys(o.phases);
    if (ks.length > 500) return undefined;
    const phases = Object.create(null);
    for (const k of ks) {
      if (!CLE_PHASE.test(k) || !ETATS.includes(o.phases[k])) return undefined;
      phases[k] = o.phases[k];
    }
    if (o.tete !== null && !(typeof o.tete === 'string' && SHA.test(o.tete))) return undefined;
    if (!Array.isArray(o.blocages) || o.blocages.length > 64 || !o.blocages.every((b) => typeof b === 'string' && H12.test(b))) return undefined;
    const r = Object.create(null);
    r.vu = o.vu; r.phases = phases; r.tete = o.tete; r.blocages = o.blocages.slice();
    return r;
  }
  const valeur = (precedente, courante) => {
    const r = Object.create(null);
    r.v = 1; r.precedente = precedente; r.courante = courante;
    return r;
  };

  function lire(texte) {
    if (typeof texte !== 'string' || octets(texte) > TAILLE_MAX) return null;
    let o;
    try { o = JSON.parse(texte); } catch (e) { return null; }
    if (!ferme(o, ['v', 'precedente', 'courante']) || o.v !== 1) return null;
    const p = lireInstantane(o.precedente), c = lireInstantane(o.courante);
    return p === undefined || c === undefined ? null : valeur(p, c);
  }

  // le texte à garder, ou null s'il dépasse la borne ou ne se relirait pas (la page retire alors la clé)
  function ecrire(v) {
    if (!v) return null;
    const t = JSON.stringify({ v: 1, precedente: v.precedente, courante: v.courante });
    return lire(t) === null ? null : t;
  }

  // rotation au chargement : la courante plus vieille que le seuil devient la précédente
  function tourner(v, maintenant) {
    if (!v || !v.courante || !(maintenant - v.courante.vu > SEUIL_ROTATION_S)) return { valeur: v || null, tourne: false };
    return { valeur: valeur(v.courante, v.courante), tourne: true };
  }

  // fusion de deux écritures : pour chacun des deux instantanés, le plus récent (vu) gagne, null perd
  const plusRecent = (a, b) => (!a ? b : !b ? a : b.vu > a.vu ? b : a);
  function fusionner(stocke, local) {
    if (!stocke && !local) return null;
    const s = stocke || valeur(null, null), l = local || valeur(null, null);
    return valeur(plusRecent(s.precedente, l.precedente), plusRecent(s.courante, l.courante));
  }

  const avecCourante = (v, present) => valeur(v ? v.precedente : null, present);
  const toutVu = (v, present) => valeur(present, present);

  window.__vfSyntheseMemoire = Object.freeze({ PREFIXE, TAILLE_MAX, SEUIL_ROTATION_S, LAB_RE, cle, lire, ecrire, tourner, fusionner, avecCourante, toutVu });
})();
