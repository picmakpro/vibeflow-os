// VibeFlow (73-05) : états de page de la régie (UI-SPEC § 4.5) et pied. Chaque message dit son état et, en une demi-phrase, ce qui le résout (P73-D-32).
// monter(racine) pose la zone des états et le pied, rend le nettoyage ; maj(info) dessine l'état ; ajouter(bloc) branche un bloc au pied
// (73-07 : les arbres de travail et « ailleurs sur ce poste »). nonCommite() rend à la source la jointure branche → fichiers modifiés
// (ligne 2 d'un agent). Texte seul (textContent). Pose window.__vfRegiePied.
(() => {
  const D = document, DP = ' :';
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt) e.textContent = txt; return e; };
  const ecrire = (e, t) => { if (e.textContent !== t) e.textContent = t; };
  const SOURCES = { sessions: 'Sessions et sous-agents', locks: 'Verrous du dépôt', dags: 'Plans de la mission' };
  const BOITES = {
    lecture: ["Lecture de l'équipe"],
    aucun: ['Aucun agent dans les dernières 24 h.', "Les sessions de ce dépôt apparaîtront ici dès qu'elles écrivent."],
    direct: ["Le direct n'est pas branché.", "Ouvrez le cockpit depuis le projet pour voir l'équipe."],
  };
  let courant = null;

  // ---------- 73-07 : arbres de travail (P73-D-10) et « ailleurs sur ce poste » (P73-D-16) ----------
  // Lectures par VF_ETAT.lireJson (sinon fetch GET et jeton de la page) ; abonnements rendus au nettoyage ; aucune minuterie, aucune écriture de stockage.
  const W = window, SCHEMA_AILLEURS = 'vibeflow/cockpit-ailleurs@1';
  const lire = (chemin) => {
    const E = W.VF_ETAT;
    if (E && typeof E.lireJson === 'function') return E.lireJson(chemin);
    const S = W.FLOORPLAN_SERVER || {};
    const options = { headers: { 'x-floorplan-token': S.token || '' }, cache: 'no-store' };
    return W.fetch(chemin, options).then((r) => (r.ok ? r.json() : Promise.reject(new Error('statut'))));
  };
  const abonner = (cle, evenement, f) => {
    const E = W.VF_ETAT;
    if (E && typeof E.abonner === 'function') return E.abonner(cle, f);
    D.addEventListener(evenement, f); return () => D.removeEventListener(evenement, f);
  };
  const plur = (n, un, plus) => `${n} ${n === 1 ? un : plus}`;
  let nonCommite = Object.create(null); // branche → nombre de fichiers modifiés (branches qui désignent un seul arbre, états lus)

  // une lecture à la fois, une de rattrapage au plus : lance(f) rend la fonction à appeler
  const unique = (f) => {
    let envol = false, encore = false;
    const aller = () => {
      if (envol) { encore = true; return; }
      envol = true; encore = false;
      Promise.resolve().then(f).catch(() => {}).then(() => { envol = false; if (encore) aller(); });
    };
    return aller;
  };

  function arbres() {
    const bloc = h('details', 'vf-rg-sec vf-rg-arbres'), corps = h('div', 'vf-rg-corps vf-rg-arbres-corps');
    const titre = h('summary', 'vf-rg-tete'), mot = h('span', '', 'Arbres de travail');
    let vivant = true, signature = '';
    // repère d'ouverture : le caret du tiroir, couleur du texte
    const G = W.__vfRegieRendu && W.__vfRegieRendu.glyphe, marque = G ? G('repli', 'r-caret') : null;
    titre.append(...(marque ? [marque] : []), mot);
    bloc.append(titre, corps);
    const bouton = (txt, f) => { const b = h('button', 'btn', txt); b.setAttribute('type', 'button'); b.addEventListener('click', f); return b; };
    const dire = (t, ...suite) => corps.replaceChildren(h('p', 'vf-rg-vide', t), ...suite);
    const rendre = (carte) => { // rend la jointure à la source ; un redessin seulement si elle a changé
      const s = JSON.stringify(Object.entries(carte).sort());
      nonCommite = carte; if (s !== signature) { signature = s; D.dispatchEvent(new CustomEvent('vf-regie:redessiner')); }
    };
    const echec = () => {
      if (!vivant) return;
      bloc.hidden = false; dire('Git est indisponible : le dépôt ne répond pas.', bouton('Réessayer', () => lecture())); rendre(Object.create(null));
    };
    const pastilles = (d) => {
      if (!d || !d.verifie || (d.modifies == null && d.nonSuivis == null && d.propre == null)) return ['non vérifié'];
      const p = [], plus = d.plus ? '+' : '';
      if (d.modifies > 0) p.push(`${d.modifies}${plus} ${d.modifies === 1 && !plus ? 'modifié' : 'modifiés'}`);
      if (d.nonSuivis > 0) p.push(`${d.nonSuivis}${plus} ${d.nonSuivis === 1 && !plus ? 'non suivi' : 'non suivis'}`);
      if (d.avance > 0 || d.retard > 0) p.push(`↑${d.avance || 0} ↓${d.retard || 0}`);
      if (d.propre === true) p.push('propre');
      return p;
    };
    const afficher = (g, w) => {
      if (!vivant) return;
      if (g && g.etat === 'absent') { bloc.hidden = true; rendre(Object.create(null)); return; }
      if (!g || g.etat !== 'ok' || !Array.isArray(g.worktrees) || !w || w.etat !== 'ok' || !Array.isArray(w.worktrees)) { echec(); return; }
      bloc.hidden = false;
      const lus = new Map(w.worktrees.map((x) => [x.chemin, x])), L = g.worktrees;
      const noms = new Map(), branches = new Map(), carte = Object.create(null);
      for (const t of L) { noms.set(t.nom, (noms.get(t.nom) || 0) + 1); if (t.branche) branches.set(t.branche, (branches.get(t.branche) || 0) + 1); }
      for (const t of L) {
        const d = lus.get(t.chemin);
        if (t.branche && branches.get(t.branche) === 1 && d && d.verifie && d.modifies > 0) carte[t.branche] = d.modifies;
      }
      ecrire(mot, `Arbres de travail (${L.length})`);
      const ouvrirGit = () => { const o = D.getElementById('vf-git-ouvreur'); if (o) o.click(); };
      const histo = D.getElementById('vf-git-ouvreur') ? bouton("Ouvrir l'historique Git (g)", ouvrirGit) : null;
      if (L.length <= 1) dire('Un seul arbre de travail.', ...(histo ? [histo] : []));
      else {
        const ul = h('ul', 'vf-rg-arbres-liste');
        for (const t of L) {
          const li = h('li', 'vf-rg-lig vf-rg-arbre'), morceaux = [h('code', 'vf-rg-arbre-nom', t.nom)];
          if (t.ici) morceaux.push(h('span', 'vf-rg-compte', 'ici'));
          morceaux.push(h('code', 'vf-rg-arbre-br', t.detache ? 'HEAD détaché' : t.branche || 'sans branche'));
          for (const p of pastilles(lus.get(t.chemin))) morceaux.push(h('span', 'vf-rg-arbre-pastille', p));
          if (noms.get(t.nom) > 1) morceaux.push(h('span', 'vf-rg-l2', 'nom partagé : aucune cible rattachable'));
          morceaux.forEach((m, i) => { if (i) li.append(D.createTextNode(' ')); li.append(m); });
          ul.append(li);
        }
        corps.replaceChildren(ul, ...(histo ? [histo] : []));
      }
      rendre(carte);
    };
    const lecture = unique(() => {
      if (!vivant) return null;
      if (!corps.firstChild) dire('Lecture du dépôt');
      return Promise.all([lire('/api/vf/git'), lire('/api/vf/git/worktrees')]).then(([g, w]) => afficher(g, w), echec);
    });
    const demarrer = () => {
      const surOuverture = () => { if (bloc.open) lecture(); };
      bloc.addEventListener('toggle', surOuverture);
      const fin = abonner('git', 'vf-git:signal', surOuverture);
      return () => { bloc.removeEventListener('toggle', surOuverture); fin(); };
    };
    return { bloc, demarrer, fin: () => { vivant = false; nonCommite = Object.create(null); } };
  }

  function ailleurs() {
    const ligne = h('p', 'vf-rg-ailleurs');
    let donneesAilleurs = null, vivant = true, dessin = '';
    ligne.hidden = true;
    // « Ailleurs sur ce poste : 1 session vous attend, dans « atelier ». » ; le nom d'un lab ne se pose qu'en textContent d'un élément exclu de la traduction
    const dessiner = () => {
      const liste = (donneesAilleurs || []).filter((e) => e && typeof e.lab === 'string' && e.lab && Number.isInteger(e.n) && e.n > 0).slice(0, 50);
      const total = liste.reduce((s, e) => s + e.n, 0), noms = liste.slice(0, 3), reste = liste.length - noms.length, nodes = [];
      const sig = liste.length ? JSON.stringify(liste) : '';
      if (sig === dessin) return;
      dessin = sig; ligne.hidden = !liste.length;
      if (!liste.length) { ligne.replaceChildren(); return; }
      nodes.push(`Ailleurs sur ce poste : ${total === 1 ? '1 session vous attend' : `${total} sessions vous attendent`}, dans `);
      noms.forEach((e, i) => { if (i) nodes.push(i === noms.length - 1 && !reste ? ' et ' : ', '); nodes.push('« ', h('code', '', e.lab), ' »'); });
      if (reste) nodes.push(` et ${plur(reste, 'autre', 'autres')}`);
      nodes.push('.');
      ligne.replaceChildren(...nodes);
    };
    const lecture = unique(() => (!vivant ? null : lire('/api/vf/ailleurs')
      .then((j) => { if (!j || j.schema !== SCHEMA_AILLEURS) throw new Error('forme'); donneesAilleurs = Array.isArray(j.ailleurs) ? j.ailleurs : null; })
      .catch(() => { donneesAilleurs = null; })
      .then(() => { if (vivant) dessiner(); })));
    return { ligne, lecture, fin: () => { vivant = false; donneesAilleurs = null; } };
  }

  function monter(racine) {
    const etats = h('div', 'vf-rg-etats'), zone = h('div', 'vf-rg-piedzone'), source = h('p', 'vf-rg-source'), direct = h('p', 'vf-rg-direct');
    const entete = racine.querySelector('#vf-equipe-entete');
    let boite = null, nom = '';
    source.hidden = true; zone.append(source);
    if (entete) racine.insertBefore(etats, entete.nextSibling); else racine.append(etats);
    racine.append(zone);
    const poser = (n) => {
      if (n === nom) return;
      nom = n; if (boite) { boite.remove(); boite = null; }
      if (!n) return;
      boite = h('div', 'vf-rg-note'); for (const t of BOITES[n]) boite.append(h('p', '', t)); etats.append(boite);
    };
    // info : { lecture (muet : pas encore de boîte, avant 150 ms), direct (faux = pas de direct), aucun, sources,
    //   coupe (secondes depuis la dernière donnée, ou null) }
    const maj = (info) => {
      info = info || {};
      if (info.lecture) racine.setAttribute('aria-busy', 'true'); else if (racine.hasAttribute('aria-busy')) racine.removeAttribute('aria-busy');
      poser(info.direct === false ? 'direct' : info.lecture ? (info.muet ? '' : 'lecture') : info.aucun ? 'aucun' : '');
      const mal = Object.entries(info.sources || {}).filter(([, s]) => s && (s.etat === 'erreur' || s.etat === 'forme-inconnue'))
        .map(([k]) => (Object.hasOwn(SOURCES, k) ? SOURCES[k] : k));
      ecrire(source, mal.length ? `Source illisible${DP} ${mal.join(', ')}` : '');
      if (source.hidden === !!mal.length) source.hidden = !mal.length;
      if (info.coupe == null) { if (direct.parentNode) direct.remove(); return; }
      const d = window.__vfEquipeRendu.duree(Math.max(0, Math.round(info.coupe)));
      ecrire(direct, `Direct coupé${DP} durées figées, données d'il y a ${d}`);
      if (!direct.parentNode && entete) entete.append(direct);
    };
    const ajouter = (bloc) => { if (bloc) zone.insertBefore(bloc, source); };
    courant = { maj, ajouter };
    const A = arbres(), B = ailleurs();
    ajouter(A.bloc); ajouter(B.ligne);
    courant.surWho = B.lecture; // « ailleurs » se relit à chaque who : la source l'avertit (un seul abonnement au who dans la page)
    const retrait = A.demarrer(); B.lecture();
    return () => { courant = null; retrait(); A.fin(); B.fin(); etats.remove(); zone.remove(); direct.remove(); };
  }
  window.__vfRegiePied = {
    monter, maj: (i) => { if (courant) courant.maj(i); }, ajouter: (b) => { if (courant) courant.ajouter(b); },
    surWho: () => { if (courant && courant.surWho) courant.surWho(); }, nonCommite: () => nonCommite,
  };
})();
