// VibeFlow (73-11) : lecture des questions en attente des cadrages (champ meta.vf.questions, contrat C76-Q2 de la Phase 76) : normalisation fermée par défaut,
// lignes de « À vous », pied (repli des décisions, à vérifier, bilan, absence). Aucun DOM, aucun réseau, aucun stockage. Complète window.__vfRegieQuestions.
// La page ne fait confiance ni à `etat` ni à la forme : une entrée devient une ligne « en attente » seulement si `etat` vaut exactement
// `en-attente` ET si sa forme est complète.
(() => {
  const NB = '\xa0', DP = NB + ':', LET = 'abcdefghijklmnopqrstuvwxyz';
  const ID = /^P[0-9]+(\.[0-9]+)*-Q-[0-9]{2,}$/, PH = /^ph-[0-9]+(\.[0-9]+)*(@[A-Za-z0-9_-]{1,64})?$/, DEC = /^P[0-9]+(\.[0-9]+)*-D-[0-9]{2,}$/;
  const PLAN = /^[0-9]+(\.[0-9]+)?-[0-9]+$/, NUM = /^[0-9]+(\.[0-9]+)*$/;
  const objet = (v) => Object.prototype.toString.call(v) === '[object Object]';
  const txt = (v, n) => (typeof v === 'string' ? v.replace(/[\p{Cc}\p{Cf}]/gu, '').trim().slice(0, n) : '');
  const entier = (v) => Number.isSafeInteger(v) && v >= 0;
  const fichier = (v) => { const s = txt(v, 200); return s && !/(^[/~]|[~\\]|\.\.|^[A-Za-z]:)/.test(s) ? s : null; }; // garde:q-fichier

  const MOTS_DEFAUTS = Object.freeze({
    'etat-absent': 'ligne État absente', 'etat-invalide': 'ligne État illisible', 'options-invalides': 'options mal écrites',
    'recommandation-hors-options': 'recommandation hors des options', 'bloque-invalide': 'ligne Bloque illisible', 'champ-repete': 'un champ écrit deux fois',
    'champ-manquant': 'un champ manque', 'phase-incoherente': "identifiant d'une autre phase que son dossier",
    'identifiant-double': 'identifiant déjà utilisé ailleurs',
    'citation-incoherente': "notée en attente alors qu'une décision la dit tranchée",
    'appliquee-hors-recommandation': 'option appliquée différente de la recommandée',
    'decision-introuvable': 'décision citée introuvable dans le cadrage' });
  const mot = (d) => (typeof d === 'string' && Object.hasOwn(MOTS_DEFAUTS, d) ? MOTS_DEFAUTS[d] : 'défaut non reconnu');

  // le lien d'une carte de phase : même construction que les lignes de phase de 73-04 ; jamais un lien deviné
  const lienPhase = (phase) => (typeof phase === 'string' && PH.test(phase) ? 'project.html#r=' + encodeURIComponent('n:' + phase) : null); // garde:q-lien
  const numPhase = (e) => { const m = /^ph-([0-9]+(?:\.[0-9]+)*)/.exec(e.phase || '') || /^P([0-9]+(?:\.[0-9]+)*)-/.exec(e.id); return m ? m[1] : ''; };

  const options = (v) => {
    if (!Array.isArray(v)) return null;
    const o = v.slice(0, 26).map((x, i) => (objet(x) && x.cle === LET[i] && txt(x.texte, 160) ? { cle: x.cle, texte: txt(x.texte, 160) } : null));
    return o.length >= 2 && o.every(Boolean) ? o : null;
  };
  const bloque = (v) => {
    if (!Array.isArray(v)) return null;
    const o = v.slice(0, 20).map((x) => {
      const n = objet(x) && (typeof x.n === 'number' && Number.isInteger(x.n) && x.n >= 0 ? String(x.n) : x.n);
      return objet(x) && x.type === 'plan' && typeof x.id === 'string' && PLAN.test(x.id) ? x.id
        : objet(x) && x.type === 'phase' && typeof n === 'string' && NUM.test(n) ? 'Phase ' + n : null;
    });
    return o.every(Boolean) ? o : null;
  };
  const base = (e) => ({ id: e.id, phase: typeof e.phase === 'string' && PH.test(e.phase) ? e.phase : null, fichier: fichier(e.fichier),
    ligne: Number.isInteger(e.ligne) && e.ligne > 0 ? e.ligne : null, titre: txt(e.titre, 80), question: txt(e.question, 240),
    defauts: Array.isArray(e.defauts) ? e.defauts.slice(0, 12).map(mot) : [] });
  const complete = (e, b) => {
    const o = options(e.options), bl = bloque(e.bloque), r = e.recommandation;
    if (!b.titre || !b.question || !o || !bl || !(r === null || (typeof r === 'string' && o.some((x) => x.cle === r)))) return null;
    return { ...b, options: o, recommandation: r, bloque: bl };
  };
  const neuf = () => ({ source: 'absente', enAttente: [], appliquees: [], aVerifier: [], malFormees: [], tronque: false, ignorees: 0, longueur: 0,
    bilan: { tranchees: 0, aVerifier: 0, malFormees: 0, nonStructurees: 0 } });

  function normaliser(brut) {
    const o = neuf();
    if (brut === undefined || brut === null) return o;
    if (!objet(brut) || !Array.isArray(brut.liste)) { o.source = 'illisible'; return o; }
    o.source = 'lue'; o.longueur = brut.liste.length; o.tronque = brut.tronque === true;
    let tranchees = 0;
    for (const e of brut.liste.slice(0, 200)) {
      if (!objet(e) || typeof e.id !== 'string' || !ID.test(e.id)) { o.ignorees++; continue; }
      const st = e.etat, b = base(e);
      const attend = st === 'en-attente'; // garde:q-etat-exact
      const c = attend || st === 'appliquee' ? complete(e, b) : null;
      if (attend) { if (c) o.enAttente.push(c); else o.ignorees++; }
      else if (st === 'appliquee') {
        const a = objet(e.appliquee) ? e.appliquee : null;
        if (c && a && typeof a.option === 'string' && c.options.some((x) => x.cle === a.option) && typeof a.decision === 'string' && DEC.test(a.decision)) {
          o.appliquees.push({ ...c, appliquee: { option: a.option, decision: a.decision } });
        } else o.ignorees++;
      } else if (st === 'tranchee') tranchees++;
      else if (st === 'a-verifier') o.aVerifier.push(b);
      else if (st === 'mal-formee') o.malFormees.push({ id: b.id, phase: b.phase, fichier: b.fichier, ligne: b.ligne, defauts: b.defauts });
      else o.ignorees++;
    }
    const bi = objet(brut.bilan) ? brut.bilan : {}, nb = (v, d) => (entier(v) ? v : d);
    o.bilan = { tranchees: nb(bi.tranchees, tranchees), aVerifier: nb(bi.aVerifier, o.aVerifier.length), malFormees: nb(bi.malFormees, o.malFormees.length),
      nonStructurees: nb(bi.nonStructurees, 0) };
    return o;
  }

  // P73-D-41 : la page trie elle-même, par phase (ordre numérique, segment par segment : 71.5 avant 71.10), puis identifiant ; sans phase lisible en dernier
  const cle = (e) => { const m = /^ph-([0-9.]+)/.exec(e.phase || '') || /^P([0-9.]+)-Q-/.exec(e.id); return m ? m[1].split('.').map(Number) : null; };
  const cmpPhase = (a, b) => {
    const x = cle(a), y = cle(b);
    if (!x || !y) return x ? -1 : y ? 1 : 0;
    for (let i = 0; i < Math.max(x.length, y.length); i++) { const d = (x[i] === undefined ? -1 : x[i]) - (y[i] === undefined ? -1 : y[i]); if (d) return d; }
    return 0;
  };
  const cmpEntree = (a, b) => cmpPhase(a, b) || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
  const texteLien = (e) => (lienPhase(e.phase) ? `Voir la phase ${numPhase(e)} dans Projet` : `Phase ${numPhase(e)}, sans carte dans Projet`);

  function lignes(etat) {
    if (!etat || etat.source !== 'lue') return [];
    return etat.enAttente.slice().sort(cmpEntree).map((q, i) => {
      const options = q.options.map((o) => ({ cle: o.cle, texte: o.texte, recommandee: o.cle === q.recommandation }));
      const l = { kind: 'question', cle: 'a-vous:' + q.id, id: q.id, nom: q.titre, role: q.id, etat: 'attend', rang: q.bloque.length ? 2 : 3, ordre: i,
        question: q.question,
        options, recommandation: q.recommandation, bloque: q.bloque, lien: lienPhase(q.phase), lienTexte: texteLien(q), numPhase: numPhase(q),
        attrs: { question: q.id, etat: 'attend' } };
      l.sig = JSON.stringify([l.nom, l.question, l.options, l.recommandation, l.bloque, l.lien, l.lienTexte]);
      return l;
    });
  }

  const ABSENT = 'Lecture des questions des cadrages pas encore livrée (Phase 76)', LECTURE = 'Lecture des questions des cadrages…';
  const ILLISIBLE = 'Questions des cadrages illisibles' + DP + ' forme inattendue, relue à la prochaine mise à jour.';
  const pl = (n, un, plu) => `${n} ${n > 1 ? plu : un}`;
  const lieu = (e) => (e.fichier ? e.fichier + (e.ligne ? `, ligne ${e.ligne}` : '') : '');

  function bloc(etat) {
    const b = { message: '', decisions: [], aVerifier: [], signalements: [], bilan: '', tronque: '' };
    const s = etat && etat.source;
    if (s !== 'lue') { b.message = s === 'lecture' ? LECTURE : s === 'illisible' ? ILLISIBLE : ABSENT; return b; }
    b.decisions = etat.appliquees.map((e) => ({ cle: 'decisions-prises:' + e.id, id: e.id, question: e.question,
      option: `Option appliquée${DP} (${e.appliquee.option}) ${(e.options.find((o) => o.cle === e.appliquee.option) || {}).texte}`,
      decision: `Décision${DP} ${e.appliquee.decision}`, lien: lienPhase(e.phase), lienTexte: texteLien(e) }));
    b.aVerifier = etat.aVerifier.map((e) => ({ cle: 'a-verifier:' + e.id, id: e.id, question: e.question, lieu: lieu(e), defauts: e.defauts.join(', ') }));
    const sg = etat.malFormees.map((e) => `Entrée mal formée${DP} ${e.id}, ${e.fichier && e.ligne ? lieu(e) : 'emplacement non affiché'}${DP} `
      + e.defauts.join(', '));
    b.signalements = sg.length > 5 ? [...sg.slice(0, 5), `et ${sg.length - 5} autres`] : sg;
    const bi = etat.bilan, seg = [bi.tranchees ? pl(bi.tranchees, 'tranchée', 'tranchées') : '', bi.aVerifier ? `${bi.aVerifier} à vérifier` : '',
      bi.malFormees ? pl(bi.malFormees, 'mal formée', 'mal formées') : '',
      bi.nonStructurees ? (bi.nonStructurees > 1 ? `${bi.nonStructurees} questions écrites dans un autre format, non lues`
        : '1 question écrite dans un autre format, non lue') : '',
      etat.ignorees ? (etat.ignorees > 1 ? `${etat.ignorees} entrées de forme inattendue, ignorées`
        : '1 entrée de forme inattendue, ignorée') : ''].filter(Boolean);
    b.bilan = seg.length ? `Cadrages lus${DP} ${seg.join(' · ')}` : '';
    b.tronque = etat.tronque ? `Liste tronquée à ${etat.longueur} questions${DP} les suivantes ne sont pas lues.` : '';
    return b;
  }
  const vide = (etat) => (!etat || etat.source === 'lue' ? 'Rien ne vous attend.' : '');
  const nEnAttente = (etat) => (etat && etat.source === 'lue' ? etat.enAttente.length : 0);

  window.__vfRegieQuestions = Object.assign(window.__vfRegieQuestions || {}, { normaliser, lignes, bloc, vide, nEnAttente, MOTS_DEFAUTS, lienPhase });
})();
