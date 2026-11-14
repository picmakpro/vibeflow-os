// VibeFlow (Phase 74, TEMP-08) : modèle du fil de la fiche d'agent et rendu en texte (P74-D-17, D-18, D-19, D-48). Les modules ne lisent rien : ils
// mettent en forme ce qu'on leur donne (réponse de transcript `cockpit-transcript@2`, `evenements` d'une voie de frise). Liste blanche côté rendu :
// un champ inconnu d'une ligne n'est jamais rendu. Aucun glyphe ni couleur ici : le glyphe d'une ligne vient du rappel `glyphe(nom)` (74-05).
// Pose window.__vfFicheTexte ; le markdown vit dans 74-vf-fiche-md.js (window.__vfFicheMd, lu à l'usage).
(() => {
  const SCHEMA = 'vibeflow/cockpit-transcript@2';
  const COUPE = "Plus ancien que la fenêtre lue. Seuls les 50 derniers messages et les 200 derniers appels d'outil sont affichés.";
  const TXT_HUMAIN = "Message de l'humain";
  const TXT_COMPACTION = 'Compaction';
  const PLAFOND_GENRE = 200;
  const GENRES = ['message', 'humain', 'compaction', 'outil'];
  const LIGNES_REPLI = 6;
  const chaine = (v) => (typeof v === 'string' ? v : '');

  // lecture gardée : le schéma d'abord, aucun champ avant ; un genre autre que message et outil (compaction, humain compris) est écarté et compté
  function lireFil(brut) {
    if (!brut || typeof brut !== 'object') return { ok: false, raison: 'forme' };
    if (brut.schema !== SCHEMA) return { ok: false, raison: 'schema' };
    if (brut.erreur === 'inconnu') return { ok: false, raison: 'inconnu' };
    if (brut.erreur) return { ok: false, raison: 'erreur' };
    if (!Array.isArray(brut.fil)) return { ok: false, raison: 'forme' };
    const lignes = [];
    let ecartes = 0;
    for (const e of brut.fil) {
      const t = e && typeof e === 'object' ? chaine(e.t) : '';
      if (!t || !Number.isFinite(Date.parse(t))) { ecartes++; continue; }
      if (e.genre === 'message') lignes.push({ t, genre: 'message', texte: chaine(e.texte) });
      else if (e.genre === 'outil') {
        const l = { t, genre: 'outil', outil: chaine(e.outil), verbe: chaine(e.verbe), cible: chaine(e.cible) };
        if (Number.isFinite(e.n) && e.n > 1) l.n = Math.floor(e.n);
        if (e.echec === true) l.echec = true;
        lignes.push(l);
      } else ecartes++;
    }
    return { ok: true, mandat: typeof brut.mandat === 'string' ? brut.mandat : null, lignes, tronque: brut.tronque === true, ecartes };
  }

  // fusion PURE des événements de la voie (compaction, humain) dans le fil : bornés au plus ancien `t` du fil, 200 de chaque genre au plus
  // (les plus récents), rien pendant la construction de l'index ; `tronque` est accepté pour la jointure, seule la borne décide
  function fusionnerEvenements(lignes, evenements, options) {
    const fil = Array.isArray(lignes) ? lignes.slice() : [];
    const etatSource = options && options.etatSource;
    if (etatSource === 'en-construction' || !Array.isArray(evenements)) return fil;
    const ts = fil.map((l) => Date.parse(l && l.t)).filter((x) => Number.isFinite(x));
    if (!ts.length) return fil;
    const borne = ts.reduce((a, b) => (b < a ? b : a));
    const genres = { compaction: [], humain: [] };
    for (const ev of evenements) {
      if (!Array.isArray(ev) || !Object.prototype.hasOwnProperty.call(genres, ev[1])) continue;
      const ms = ev[0];
      if (typeof ms !== 'number' || !Number.isFinite(ms) || !Number.isFinite(new Date(ms).getTime())) continue;
      if (ms < borne) continue;
      genres[ev[1]].push(ms);
    }
    const lignesEv = [];
    for (const g of Object.keys(genres)) {
      genres[g].sort((a, b) => a - b);
      for (const ms of genres[g].slice(-PLAFOND_GENRE)) lignesEv.push({ ms, ligne: { t: new Date(ms).toISOString(), genre: g } });
    }
    const tous = fil.map((l, idx) => ({ ms: Date.parse(l && l.t), rang: 0, idx, ligne: l }))
      .concat(lignesEv.map((e, idx) => ({ ms: e.ms, rang: 1, idx, ligne: e.ligne })));
    tous.sort((a, b) => (a.ms - b.ms) || (a.rang - b.rang) || (a.idx - b.idx));
    return tous.map((x) => x.ligne);
  }

  // filtres cumulables (union) ; aucun enfoncé = tout ; « Messages » = message et humain, « Outils » = outil, « Erreurs » = outil en échec
  function filtrer(lignes, filtres) {
    const liste = Array.isArray(lignes) ? lignes : [];
    const f = filtres || {};
    const actifs = [];
    if (f.messages) actifs.push((l) => l.genre === 'message' || l.genre === 'humain');
    if (f.outils) actifs.push((l) => l.genre === 'outil');
    if (f.erreurs) actifs.push((l) => l.genre === 'outil' && l.echec === true);
    const retenues = actifs.length ? liste.filter((l) => actifs.some((p) => p(l))) : liste.slice();
    return { lignes: retenues, affichees: retenues.length, total: liste.length };
  }

  const lignesDe = (texte) => (typeof texte === 'string' && texte ? texte.split('\n').length : 0);

  let formateur = null;
  function fmtHeureFil(iso) {
    try {
      if (!formateur) formateur = new Intl.DateTimeFormat('fr-FR', { hourCycle: 'h23', hour: '2-digit', minute: '2-digit', second: '2-digit' });
      return formateur.format(new Date(iso));
    } catch (e) { return ''; }
  }

  const md = () => window.__vfFicheMd;
  const markdown = (texte, doc) => {
    if (md()) return md().markdown(texte, doc);
    const f = doc.createDocumentFragment();
    f.appendChild(doc.createTextNode(chaine(texte)));
    return f;
  };
  const mandatDom = (texte, doc) => {
    if (md()) return md().mandatDom(texte, doc);
    const pre = doc.createElement('pre');
    pre.textContent = chaine(texte);
    return pre;
  };

  // une ligne du fil : heure, glyphe (rappel), texte. Liste blanche : seuls les champs de la route normalisée sont lus.
  function ligneDom(ligne, doc, options) {
    const glyphe = options && typeof options.glyphe === 'function' ? options.glyphe : null;
    const li = doc.createElement('li');
    li.className = 'vf-fiche-ligne';
    if (!GENRES.includes(ligne && ligne.genre)) return li; // liste blanche au rendu : ni classe dérivée du genre ni contenu
    li.className += ' vf-fiche-' + ligne.genre;
    const heure = doc.createElement('span');
    heure.className = 'vf-fiche-heure';
    heure.textContent = fmtHeureFil(ligne.t);
    const marque = doc.createElement('span');
    marque.className = 'vf-fiche-glyphe';
    const nom = ligne.genre === 'outil' && ligne.echec === true ? 'echec' : ligne.genre;
    const g = glyphe ? glyphe(nom) : null;
    if (g && typeof g === 'object') marque.appendChild(g);
    const corps = doc.createElement('span');
    corps.className = 'vf-fiche-texte';
    if (ligne.genre === 'message') corps.appendChild(markdown(ligne.texte, doc));
    else if (ligne.genre === 'humain') corps.textContent = TXT_HUMAIN;
    else if (ligne.genre === 'compaction') corps.textContent = TXT_COMPACTION;
    else if (ligne.genre === 'outil') {
      const verbe = ligne.verbe || ligne.outil || '';
      corps.appendChild(doc.createTextNode(verbe));
      if (ligne.cible) {
        const code = doc.createElement('code');
        code.className = 'vf-fiche-cible';
        code.textContent = ligne.cible;
        corps.appendChild(doc.createTextNode(' '));
        corps.appendChild(code);
      }
      if (Number.isFinite(ligne.n) && ligne.n > 1) corps.appendChild(doc.createTextNode(' × ' + ligne.n));
      if (ligne.echec === true) {
        const e = doc.createElement('span');
        e.className = 'vf-fiche-echec';
        e.textContent = 'échec';
        corps.appendChild(doc.createTextNode(' '));
        corps.appendChild(e);
      }
    }
    li.appendChild(heure);
    li.appendChild(marque);
    li.appendChild(corps);
    return li;
  }

  window.__vfFicheTexte = Object.freeze({
    lireFil, fusionnerEvenements, filtrer, lignesDe, ligneDom, markdown, mandatDom, fmtHeureFil,
    COUPE, TXT_HUMAIN, TXT_COMPACTION, LIGNES_REPLI, PLAFOND_GENRE,
  });
})();
