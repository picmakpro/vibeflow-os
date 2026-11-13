// VibeFlow (76-06) : briques de rendu de la traçabilité (UI-SPEC § 1, § 2.2, § 9) : glyphes, bande, ligne d'exigence, états, « + N autres ».
// Tout texte venu du lab est posé en textContent (P76-D-11) ; le copy français est écrit ici, les espaces insécables posées à l'exécution,
// aucun tiret cadratin.
(() => {
  const VT = (window.VFTrace = window.VFTrace || {});
  const NB = ' ';
  const MAILLONS = ['plan', 'summary', 'verification', 'recette'];
  const NOM = { plan: 'plan', summary: 'SUMMARY', verification: 'VERIFICATION', recette: 'recette' };
  const CAP = { plan: 'Plan', summary: 'SUMMARY', verification: 'VERIFICATION', recette: 'Recette' };
  const CONTRA = { 'cochee-sans-summary': 'cochée, sans SUMMARY', 'complete-sans-plan': 'Complete, sans plan' };
  const MENTION = { 'non-cochee-summary-lu': 'non cochée, SUMMARY lu', 'sans-ligne-tracabilite': 'sans ligne de traçabilité' };
  Object.assign(VT, { NB, MAILLONS, NOM, CAP });
  // une espace insécable avant : ; ! ? et entre un nombre et son unité (copy écrit avec des espaces ordinaires)
  VT.T = (s) => String(s).replace(/ ([:;!?])/g, NB + '$1').replace(/(\d) (?=\p{L})/gu, '$1' + NB);
  VT.N = (n) => (n > 9999 ? '9' + NB + '999+' : String(n)); // plafond à 4 chiffres : le nombre exact est dans le compteur du panneau ouvert
  VT.P = (n, un, plu) => (n > 1 ? plu : un); // singulier pour 0 et 1
  VT.el = (tag, cls, txt, at) => {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (txt != null) e.textContent = txt;
    if (at) for (const k of Object.keys(at)) e.setAttribute(k, at[k]);
    return e;
  };
  const el = VT.el;

  VT.glyphe = (etat) => el('span', 'vf-trace-g vf-trace-g-' + etat, null, { 'aria-hidden': 'true' });
  VT.bande = (maillons) => { const b = el('span', 'vf-trace-bande'); for (const m of MAILLONS) b.append(VT.glyphe(maillons[m].etat)); return b; };
  VT.paire = (etat, mot) => { const p = el('span', 'vf-trace-paire'); p.append(VT.glyphe(etat), el('span', null, mot)); return p; };

  // le mot de la ligne 2 : le premier maillon qui n'est pas « lu », jamais masqué ; « chaîne complète » seulement si les quatre maillons sont lus
  VT.mot = (l) => {
    const m = l.mot;
    if (!m) return 'chaîne complète';
    if (m.etat === 'contradiction') return 'contradiction : ' + (CONTRA[m.code] || m.code);
    return (m.etat === 'manque' ? 'manque' : 'non lisible') + ' : ' + NOM[m.maillon];
  };
  // mentions par priorité : (a) contradiction hors du mot, (b) mention neutre, (c) niveau phase
  VT.mentions = (l) => {
    const a = l.contradictions.map((c) => ({ texte: 'contradiction : ' + (CONTRA[c] || c), contradiction: true }));
    for (const m of l.mentions) a.push({ texte: MENTION[m] || m });
    if (l.niveauPhase.length) a.push({ texte: 'lu au niveau phase : ' + l.niveauPhase.map((m) => NOM[m]).join(', '), niveau: true });
    return a;
  };
  // texte masqué : état et niveau de chaque maillon, dits une seule fois (le niveau d'une mention visible n'est pas redit)
  const sr = (l, ms) => {
    const niveauVisible = !!(ms[0] && ms[0].niveau);
    const parts = MAILLONS.map((m) => {
      const x = l.maillons[m];
      const lu = niveauVisible && l.niveauPhase.includes(m) ? 'lu' : 'lu, niveau ' + x.niveau;
      const e = x.etat === 'lu' ? lu : x.etat === 'non-lisible' ? 'non lisible' : x.etat;
      return CAP[m] + ' : ' + e + '.';
    });
    const autres = ms.filter((x) => !x.niveau).map((x) => x.texte);
    if (autres.length) parts.push('Mentions : ' + autres.join(' ; ') + '.');
    parts.push("Ouvrir l'exigence.");
    return VT.T(parts.join(' '));
  };
  // ligne d'exigence : un seul bouton, trois lignes de longueur bornée, nom accessible = texte visible puis texte masqué (§ 2.2)
  VT.ligneExigence = (l, { surOuvrir } = {}) => {
    const b = el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': 'exigence:' + (l.cle || l.id) });
    const l1 = el('span', 'vf-trace-l1'); l1.append(el('span', 'vf-trace-id', l.id), el('span', 'vf-trace-tx', l.libelle));
    const l2 = el('span', 'vf-trace-l2'); l2.append(VT.bande(l.maillons), el('span', 'vf-trace-mot', VT.T(VT.mot(l))));
    b.append(l1, l2);
    const ms = VT.mentions(l);
    if (ms.length) {
      const l3 = el('span', 'vf-trace-l3'), p = ms[0];
      if (p.contradiction) l3.append(VT.glyphe('contradiction'), document.createTextNode(' '));
      const reste = ms.length - 1, suffixe = reste ? ' · et ' + reste + (reste > 1 ? ' autres mentions' : ' autre mention') : '';
      l3.append(document.createTextNode(VT.T(p.texte + suffixe)));
      b.append(l3);
    }
    b.append(el('span', 'vf-trace-sr', sr(l, ms)));
    if (surOuvrir) b.addEventListener('click', (ev) => surOuvrir(l, ev.detail === 0, b));
    return b;
  };

  // états de § 9 : tous neutres, chacun dit ce qui l'a produit puis ce qui le lèverait
  VT.etat = (cas, d) => {
    const phrase = (t) => el('p', 'vf-trace-etat', VT.T(t));
    if (cas === 'chargement') {
      const r = el('div', null, null, { role: 'status', 'aria-busy': 'true' });
      for (let i = 0; i < 3; i++) r.append(el('div', 'vf-trace-fantome'));
      r.append(phrase('Lecture de la traçabilité')); return r;
    }
    if (cas === 'erreur') {
      const b = el('div', 'vf-trace-boite', null, { role: 'status' }), r = el('button', 'btn soft', 'Réessayer', { type: 'button' });
      r.addEventListener('click', () => d.surReessayer());
      b.append(el('strong', null, 'La traçabilité est indisponible'), el('span', null, 'La lecture du dépôt a échoué ou dépassé le délai.'), r); return b;
    }
    return phrase('');
  };
})();
