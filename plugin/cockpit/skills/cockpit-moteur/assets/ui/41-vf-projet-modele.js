// VibeFlow (80-04) : modèle pur des couloirs de Projet (FORM-05, P80-D-03) — blocs de jalon, couloirs, ligne d'état, troncature, listes. Aucun DOM,
// aucune requête.
// Lit seulement les champs du graphe : `st`, `avancement`, `exigences` (jamais le pied d'une phase, jamais le nœud d'exigences ni les liens de couverture,
// P80-C76-6). Seule exception de forme : la date d'un tag de release est le pied de son entrée (rangée de Releases), pas la ligne d'état d'une phase.
// Exposé : window.__vfProjetModele.
(() => {
  const t = window.__vfFrT;
  const SEUIL = 52, DEBUT = 31, FIN = 20; // P80-D-50 f : au-delà de 52 caractères, 31 premiers + « … » + 20 derniers
  const COULOIRS = [['a-faire', 'À faire', 'todo'], ['en-cours', 'En cours', 'active'], ['a-recetter', 'À recetter', 'recette'], ['fait', 'Fait', 'done']];
  const ETAT_DE_ST = { done: 'fait', recette: 'a-recetter', active: 'en-cours', todo: 'a-faire' }; // inverse de PROJECTION_ST (vf-cockpit-project.mjs)
  const MOTS = { done: 'Fait', active: 'En cours', recette: 'À recetter', todo: 'À faire', blocked: 'Bloqué' };
  const pl = (n, mot) => `${n} ${mot}${n > 1 ? 's' : ''}`;
  const etatDe = (n) => ETAT_DE_ST[n && n.st] || 'a-faire'; // `st` suit le patch du direct ; `avancement.etat` lui est identique par construction
  const titreDe = (n) => String(n.label || '').replace(/^Phase\s+\S+\s*·\s*/, '');
  const numeroDe = (n) => (n.num != null ? String(n.num) : String(n.id || '').replace(/^ph-/, '').replace(/@.*$/, ''));

  const tronquer = (titre) => {
    const car = Array.from(String(titre == null ? '' : titre));
    if (car.length <= SEUIL) return { affiche: car.join(''), complet: car.join(''), coupe: false };
    return { affiche: car.slice(0, DEBUT).join('') + '…' + car.slice(-FIN).join(''), complet: car.join(''), coupe: true };
  };

  // donnée absente n'est pas zéro : chaque segment se décide sur la présence du champ
  const ligneEtat = (n) => {
    const av = n && n.avancement, ex = n && n.exigences, seg = [];
    if (av && av.plans) {
      const p = av.plans;
      if (p.total > 0) seg.push(`${p.faits > 1 ? p.faits + ' plans' : p.faits + ' plan'} sur ${p.total}`);
      else if (p.total === 0) seg.push(Array.isArray(av.reste) && av.reste.includes('cadrage') ? t('no plan · not scoped') : t('no plan'));
    }
    if (ex && ex.total > 0) seg.push(`${ex.faits > 1 ? ex.faits + ' exigences' : ex.faits + ' exigence'} sur ${ex.total}`);
    return seg.join(' · ');
  };
  const etiquettePreuve = () => ''; // emplacement de la Phase 76 : un mot au plus, jamais seul porteur de sens

  const carte = (n) => {
    const tr = tronquer(titreDe(n)), ligne = ligneEtat(n), etat = etatDe(n);
    const mot = COULOIRS.find((c) => c[0] === etat)[1], preuve = etiquettePreuve(n);
    return { id: 'n:' + n.id, num: numeroDe(n), titre: tr.affiche, complet: tr.complet, coupe: tr.coupe, ligne, preuve, etat,
      nom: [`${numeroDe(n)} ${tr.affiche}`, [ligne, preuve].filter(Boolean).join(' · '), 'phase', mot].filter(Boolean).join(', ') };
  };

  const synthese = (f, total, r) => (total ? `${pl(f, 'phase')} faite${f > 1 ? 's' : ''} sur ${total}${r ? `, ${r} à recetter` : ''}` : t('0 phases'));
  const bloc = (j) => {
    const phases = (SC().graph.nodes || []).filter((n) => n.parent === j.id && n.kind === 'phase');
    const couloirs = {}; for (const c of COULOIRS) couloirs[c[0]] = [];
    for (const n of phases) couloirs[etatDe(n)].push(carte(n));
    const faites = couloirs.fait.length, total = phases.length, recette = couloirs['a-recetter'].length;
    const pourcent = total ? Math.floor((100 * faites) / total) : 0; // strict : 100 % seulement si faites = total
    return { jalon: 'n:' + j.id, nom: j.label, total, faites, recette, pourcent, enCours: pourcent > 0 && pourcent < 100, synthese: synthese(faites,
      total, recette), couloirs };
  };
  const SC = () => window.Floorplan;

  // jalon en cours d'abord (celui du STATE, puis les `active`), « Hors jalon » à la fin ; les jalons clos (parent « history ») vont à l'Historique
  const blocs = (G) => {
    const cle = G.meta && G.meta.vf && G.meta.vf.milestone;
    const js = (G.nodes || []).filter((n) => n.kind === 'jalon' && !n.parent);
    const rang = (j) => (j.id === 'ms-hors-jalon' ? 3 : cle && j.label === cle && j.st !== 'done' ? 0 : j.st === 'active' ? 1 : 2);
    return js.map((j, i) => ({ j, i })).sort((a, b) => rang(a.j) - rang(b.j) || a.i - b.i).map((x) => bloc(x.j));
  };
  const historique = (G) => {
    const clos = (G.nodes || []).filter((n) => n.kind === 'jalon' && n.parent === 'history');
    const lignes = clos.map((j) => {
      const ph = (G.nodes || []).filter((n) => n.parent === j.id && n.kind === 'phase'), f = ph.filter((n) => etatDe(n) === 'fait').length;
      return { id: 'n:' + j.id, nom: j.label, texte: synthese(f, ph.length, 0), phases: ph.length };
    });
    const m = lignes.reduce((s, l) => s + l.phases, 0);
    return clos.length ? { resume: `${pl(clos.length, 'jalon')} · ${pl(m, 'phase')}`, lignes } : null;
  };
  const rangee = (id, titre, st, date) => { const tr = tronquer(titre); return { id, titre: tr.affiche, complet: tr.complet, coupe: tr.coupe, st,
    mot: MOTS[st] || MOTS.todo, date: date || '' }; };
  const listes = (G) => {
    const out = [], existe = (id) => (G.nodes || []).some((n) => n.id === id);
    const fichiers = (id) => (G.files || []).filter((f) => f.n === id);
    const l = (cle, titre, unite, rows) => out.push({ cle, titre, compte: pl(rows.length, unite), rows });
    if (existe('backlog')) {
      l('backlog', t('Backlog@project'), 'entrée', fichiers('backlog').map((f) => rangee('f:' + f.p, f.name, f.st === 'done' ? 'done' : 'todo')));
    }
    if (existe('seeds')) l('graines', t('Seeds'), 'graine', fichiers('seeds').map((f) => rangee('f:' + f.p, f.name, 'todo')));
    if (existe('releases')) {
      const tags = fichiers('releases').map(({ p, name, foot: date }) => rangee('f:' + p, name, 'done', date));
      l('releases', t('Releases@project'), 'tag', tags);
    }
    if (existe('missions')) l('missions', t('Missions outside a phase'), 'mission', (G.nodes
      || []).filter((n) => n.parent === 'missions').map((n) => rangee('n:' + n.id, n.label, n.st || 'todo')));
    return out;
  };
  window.__vfProjetModele = Object.freeze({ COULOIRS, MOTS, etatDe, ligneEtat, tronquer, etiquettePreuve, carte, blocs, historique, listes, synthese,
    titreDe, numeroDe });
})();
