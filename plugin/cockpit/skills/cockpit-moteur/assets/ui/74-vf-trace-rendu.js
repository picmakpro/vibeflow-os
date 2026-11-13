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
  const el = VT.el, esp = () => document.createTextNode(' ');

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
      if (p.contradiction) l3.append(VT.glyphe('contradiction'), esp());
      const reste = ms.length - 1, suffixe = reste ? ' · et ' + reste + (reste > 1 ? ' autres mentions' : ' autre mention') : '';
      l3.append(document.createTextNode(VT.T(p.texte + suffixe)));
      b.append(l3);
    }
    b.append(el('span', 'vf-trace-sr', sr(l, ms)));
    if (surOuvrir) b.addEventListener('click', (ev) => surOuvrir(l, ev.detail === 0, b));
    return b;
  };

  // bilans en gabarits fermés, catégories exclusives (§ 10.1) : les nombres sont ceux de la route, jamais recomptés ; zéros écrits
  const tranches = (cases) => cases.map(([n, un, plu]) => VT.N(n) + ' ' + VT.P(n, un, plu)).join(' · ');
  VT.bilanPhase = (b) => (b.total && b.complete === b.total ? 'Par exigence : toutes complètes' : 'Par exigence : ' + tranches([
    [b.contradiction, 'en contradiction', 'en contradiction'], [b.manque, 'avec un manque', 'avec un manque'],
    [b.nonLisible, 'non lisible', 'non lisibles'], [b.complete, 'complète', 'complètes']]));
  VT.bilanJalon = (b) => (b.total && b.complete === b.total ? 'Par phase : toutes complètes' : 'Par phase : ' + tranches([
    [b.contradiction, 'en contradiction', 'en contradiction'], [b.manque, 'avec un manque', 'avec un manque'], [b.nonLisible, 'non lisible', 'non lisibles'],
    [b.sansExigence, 'sans exigence', 'sans exigence'], [b.complete, 'complète', 'complètes']]));
  VT.resume = (b) => {
    const inc = b.total - b.complete, tete = VT.N(b.total) + ' ' + VT.P(b.total, 'exigence', 'exigences') + ', ';
    return VT.T(tete + (inc ? VT.N(inc) + ' ' + VT.P(inc, 'incomplète', 'incomplètes') + ' dont ' + VT.N(b.contradiction) + ' en contradiction' : 'toutes complètes'));
  };
  // légende des glyphes : visible en permanence, quatre paires neutres (jamais de corail), colonnes nommées
  VT.legende = () => {
    const l = el('p', 'vf-trace-legende vf-trace-neutre');
    l.append(document.createTextNode(VT.T('Légende : ')));
    for (const [e, m] of [['lu', 'lu'], ['manque', 'manque'], ['non-lisible', 'non lisible'], ['contradiction', 'contradiction']]) l.append(VT.paire(e, m), esp());
    l.append(document.createTextNode(VT.T('Colonnes : plan, SUMMARY, VERIFICATION, recette.')));
    return l;
  };
  // « + N autres <sorte> » : un bouton, jamais la classe .more du moteur ; `sorte` = [singulier, pluriel]
  VT.plus = (sorte, n, surOuvrir) => {
    const t = VT.T('+ ' + VT.N(n) + (n > 1 ? ' autres ' + sorte[1] : ' autre ' + sorte[0]));
    const b = el('button', 'vf-trace-plus', t, { type: 'button', title: t });
    b.addEventListener('click', (ev) => surOuvrir(ev.detail === 0));
    return b;
  };

  // une preuve : portée et libellé, statut lu, chemin relatif copiable (le contenu du fichier n'est jamais rendu)
  const LIB = { verification: 'VERIFICATION', recette: 'Recette', 'trace-rouge': 'Trace rouge', securite: 'Sécurité', validation: 'Validation' };
  VT.libelleProuve = (p) => (p.plan || 'Phase') + ' · ' + (LIB[p.sorte] || p.sorte);
  VT.chemin = (chemin) => {
    const b = el('button', 'vf-copie vf-ref', null, { type: 'button', 'data-vf-copie': chemin, title: chemin, 'aria-label': 'Copier le chemin : ' + chemin });
    b.append(el('code', null, chemin), el('span', 'vf-copie-etat')); return b;
  };
  VT.ligneProuve = (p) => {
    const d = el('div', 'vf-trace-preuve', null, { 'data-trace': 'preuve:' + p.fichier }), l1 = el('div', 'vf-trace-p1');
    l1.append(el('span', 'vf-trace-nom1', VT.libelleProuve(p)), esp());
    if (p.statut) l1.append(el('span', 'vf-trace-st vf-trace-tt', VT.T('statut : ' + p.statut), { title: p.statut }));
    d.append(l1, esp(), VT.chemin(p.fichier)); return d;
  };
  // ligne d'une phase du Jalon : gabarit fermé de quatre lignes au plus (§ 4.1)
  const ETAT = { 'a-faire': ['todo', 'À faire'], 'en-cours': ['active', 'En cours'], 'a-recetter': ['recette', 'À recetter'], fait: ['done', 'Fait'] };
  VT.ligneJalon = (p, { surOuvrir } = {}) => {
    const b = el('button', 'vf-trace-ligne', null, { type: 'button', 'data-trace': 'phase:' + p.cle }), l1 = el('span', 'vf-trace-jalon-l1'), e = ETAT[p.etat] || ETAT['a-faire'];
    l1.append(el('span', 'vf-trace-nom1', 'Phase ' + p.n), esp(), el('span', 'vf-trace-tt', p.nom, { title: p.nom }), esp(), el('span', 'vst vst-' + e[0], e[1]));
    b.append(l1);
    const x = p.bilan, m = p.maillonsEnDefaut;
    b.append(el('span', 'vf-trace-cl2', x.total ? VT.T('Maillons non lus : plan ' + VT.N(m.plan) + ' · SUMMARY ' + VT.N(m.summary) + ' · VERIFICATION ' + VT.N(m.verification)
      + ' · recette ' + VT.N(m.recette)) : 'aucune exigence rattachée'));
    const tr = [[x.contradiction, 'en contradiction', 'en contradiction'], [x.manque, 'avec un manque', 'avec un manque'], [x.nonLisible, 'non lisible', 'non lisibles']].filter((c) => c[0] > 0);
    if (x.total && !tr.length) b.append(el('span', 'vf-trace-l3', 'toutes complètes'));
    else if (tr.length) {
      const l3 = el('span', 'vf-trace-l3');
      if (x.contradiction) l3.append(VT.glyphe('contradiction'), esp());
      l3.append(document.createTextNode(VT.T(tranches(tr)))); b.append(l3);
    }
    if (p.lignesSansExigence > 0) b.append(el('span', 'vf-trace-l3', VT.T(VT.N(p.lignesSansExigence) + ' ' + VT.P(p.lignesSansExigence, 'ligne', 'lignes') + ' de traçabilité sans exigence')));
    if (surOuvrir) b.addEventListener('click', (ev) => surOuvrir(p, ev.detail === 0, b));
    return b;
  };

  // états de § 9 : tous neutres, chacun dit ce qui l'a produit puis ce qui le lèverait
  const PHRASES = {
    'vide-phase': "Aucune exigence rattachée à cette phase. Une ligne du tableau de traçabilité du registre des exigences, ou le champ « requirements » d'un plan, la rattache.",
    'jalon-vide': 'Aucune phase dans le jalon en cours. Une phase inscrite à la feuille de route sous ce jalon apparaît ici.',
    'aucune-preuve': "Aucune preuve attachée. Un fichier VERIFICATION, de recette, de trace rouge, de sécurité ou de validation dans le dossier de la phase l'attacherait.",
    collecte: "La collecte du dépôt est en cours. La traçabilité apparaît dès qu'elle est faite.",
    compartiment: "Aucun compartiment de planification lu : la traçabilité n'est pas disponible. Un compartiment avec son registre des exigences la rend lisible.",
    disparu: "Cet objet n'existe plus dans le dépôt. Le bouton Retour de l'en-tête rouvre la vue précédente.",
    'aucune-preuve-exigence': 'Aucune preuve lue pour cette exigence. VERIFICATION, recette ou trace rouge dans le dossier de la phase la relierait.',
  };
  VT.etat = (cas, d = {}) => {
    const phrase = (t) => el('p', 'vf-trace-etat', VT.T(t));
    if (cas === 'chargement') {
      const r = el('div', null, null, { role: 'status', 'aria-busy': 'true' });
      for (let i = 0; i < 3; i++) r.append(el('div', 'vf-trace-fantome'));
      r.append(phrase('Lecture de la traçabilité')); return r;
    }
    if (cas === 'erreur') {
      const b = el('div', 'vf-trace-boite', null, { role: 'status' }), r = el('button', 'btn soft', 'Réessayer', { type: 'button' });
      r.addEventListener('click', () => d.surReessayer());
      b.append(el('strong', null, 'La traçabilité est indisponible'), esp(), el('span', null, 'La lecture du dépôt a échoué ou dépassé le délai.'), esp(), r); return b;
    }
    if (cas === 'etapes') { // P76-D-12 : le registre est rangé par Étape N
      const tout = d.lues === d.sansDossier;
      return phrase('La traçabilité de ce registre est rangée par Étape N' + (tout ? ', aucune ne désigne un dossier de phase. Un dossier de phase par étape la rend lisible.'
        : ' : ' + d.lues + ' étapes lues comme des phases, ' + d.sansDossier + ' sans dossier de phase. Un dossier de phase par étape les rend lisibles.'));
    }
    return phrase(PHRASES[cas] || '');
  };
  // le cas dit par une réponse de la route avant tout rendu de données : null si la réponse porte des données à rendre
  VT.etatDe = (c) => {
    if (!c) return { cas: 'erreur' };
    if (c.collecte === 'en-cours') return { cas: 'collecte' };
    if (c.etat === 'indisponible') return { cas: 'erreur' };
    if (c.absences && c.absences.compartiment) return c.absences.etapes ? { cas: 'etapes', donnees: c.absences.etapes } : { cas: 'compartiment' };
    if (c.etat === 'absent') return { cas: 'disparu' };
    return null;
  };
})();
