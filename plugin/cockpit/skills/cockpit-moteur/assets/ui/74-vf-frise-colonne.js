// VibeFlow (74-04) : la colonne de gauche de la frise : une cellule par voie (glyphe d'état tiré de la table de la régie, nom, seconde ligne « mot d'état ·
// nœud »),
// lignes de repli « + N agents », textes du bandeau haut et de la cellule d'axe. Aucun fond, aucune couleur par nœud : la couleur dit l'état, le nœud s'écrit.
// Données posées en textContent seulement, dans un élément .mono que la traduction de la page saute. Lu à l'usage : window.__vfFriseColonne.dessiner(ctx).
(() => {
  'use strict';
  const D = document, NB = ' ', SVGNS = 'http://www.w3.org/2000/svg';
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const MOTS = { travail: 'au travail', 'attend-humain': 'vous attend', 'attend-agents': 'attend ses agents', repos: 'au repos', termine: 'terminé',
    'pas-lance': 'pas encore lancé' };
  // état de voie -> clé de la table de glyphes de la régie (la frise n'a aucun jeu propre)
  const CLE_ETAT = { travail: 'actif', 'attend-humain': 'attend', 'attend-agents': 'en-attente', repos: 'au-repos', termine: 'termine',
    'pas-lance': 'au-repos' };

  const glyphe = (etat) => {
    const R = window.__vfEquipeRendu, cle = R.GLYPHE_ETAT[CLE_ETAT[etat]] || 'repos';
    const src = R.glyphe(cle, '').replace('<svg ', `<svg xmlns="${SVGNS}" `);
    const s = D.importNode(new DOMParser().parseFromString(src, 'image/svg+xml').documentElement, true);
    s.setAttribute('class', 'vf-frise-glyphe'); s.setAttribute('data-glyphe', cle);
    return s;
  };
  const nomDe = (r, ctx) => {
    const v = r.voie, w = r.travailleur;
    if (v.kind === 'session') return window.__vfEquipeRendu.nomDeSession(ctx.workers, v.id) || 'Session principale';
    if (w && typeof w.task === 'string' && w.task) return w.task;
    return `${v.role || 'Agent'} · ${String(v.id).slice(0, 8)}`;
  };
  const mono = (t) => h('span', 'mono', t);
  // « mot d'état · nœud id » (agent rattaché), « … · rattaché par ses agents » (manager), « … · tête · arbre principal » (session), sinon l'arbre
  const sousLigne = (v, etat) => {
    const e = h('span', 'vf-frise-sous'), arbre = v.arbre == null ? 'arbre principal' : v.arbre, ra = v.rattachement;
    e.append(`${MOTS[etat] || etat} · `);
    if (v.kind === 'session') e.append(`tête · ${arbre}`);
    else if (ra && ra.source === 'enfants') e.append('rattaché par ses agents');
    else if (ra && ra.noeud != null) e.append('nœud ', mono(ra.noeud));
    else e.append(mono(arbre));
    return e;
  };
  const voie = (r, ctx) => {
    const v = r.voie, nom = nomDe(r, ctx), li = h('li', 'vf-frise-voie'), b = h('button', 'vf-frise-cell'), etat = ctx.modele.etatA(v, ctx.jusqua - 1);
    li.setAttribute('data-id', v.id); li.setAttribute('data-niveau', String(r.niveau)); li.style.setProperty('--niv', String(r.niveau));
    b.type = 'button'; b.setAttribute('data-id', v.id); b.setAttribute('aria-label', `Ouvrir la fiche de ${nom}`);
    const t = h('span', 'vf-frise-textes'), n = h('span', 'vf-frise-nom mono vf-donnee', nom);
    t.append(n, sousLigne(v, etat));
    b.append(glyphe(etat), t);
    b.addEventListener('click', () => ctx.ouvrirFiche(v.id, b));
    li.append(b);
    return li;
  };
  // ligne de repli : le bouton dit le compte replié, la ligne dit combien travaillent « maintenant » ; les pistes d'une ligne repliée restent vides
  const repli = (l, ctx) => {
    const { managerId, n, auTravail } = l.repli, li = h('li', 'vf-frise-repli-ligne'), b = h('button', 'vf-frise-repli');
    const nom = ctx.nomsParId.get(managerId) || managerId;
    const texte = l.ouvert ? 'Replier les agents' : '+ ' + n + ' agents';
    b.type = 'button'; b.textContent = texte; b.setAttribute('data-id', `repli:${managerId}`); b.setAttribute('aria-expanded', l.ouvert ? 'true' : 'false');
    b.setAttribute('aria-label', l.ouvert ? `${texte}${NB}: revenir à la ligne repliée de ${nom}` : `${texte}${NB}: afficher les ${n} agents de ${nom}`);
    b.addEventListener('click', () => ctx.basculerRepli(managerId));
    li.setAttribute('data-id', `repli:${managerId}`); li.append(b);
    if (!l.ouvert && auTravail > 0) li.append(h('span', 'vf-frise-repli-n', `${auTravail} au travail`));
    return li;
  };

  function dessiner(ctx) {
    const N = ctx.nodes;
    ctx.nomsParId = new Map(ctx.rangs.map((r) => [r.id, nomDe(r, ctx)]));
    N.voies.replaceChildren(...ctx.lignes.map((l) => (l.rang ? voie(l.rang, ctx) : repli(l, ctx))));
    N.courbe.c.replaceChildren(h('div', 'vf-frise-bandeau-t', 'Agents au travail'),
      h('div', 'vf-frise-bandeau-s', `jusqu'à ${ctx.courbe.pic} en même temps sur ${ctx.libFenetre}`));
    N.axe.c.replaceChildren(h('div', 'vf-frise-axe-t', ctx.lecture === 'horloge' ? 'Horloge' : 'Événements, silences raccourcis'));
  }
  window.__vfFriseColonne = { dessiner, nomDe };
})();
