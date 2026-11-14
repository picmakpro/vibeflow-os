// VibeFlow (74-06) : encart « À cet instant » (P74-D-13, D-39, D-49). Extension `encart` du registre de 74-vf-frise.js : un `div` sous la légende.
// Sans curseur posé il dit comment en poser un ; curseur posé, il dit l'état de chaque voie, les nœuds du plan PORTÉS (l'état est celui de la voie
// porteuse, jamais un statut de plan : window.__vfFriseModele.noeudsPortes) et les fichiers écrits autour de l'instant (lecture : 74-vf-frise-
// fichiers.js, rendu seulement ici). « · déduit » seulement sur l'état PRÉSENT d'une voie sans `etatOfficiel` (P74-D-39). Le bouton « Voir sur la
// carte » n'appelle que window.__vfFrise.voirSurLaCarte. Rien ne se dessine au chargement : le rappel de surOnglet enregistre l'extension, écoute le
// curseur (événements vf-frise:curseur et vf-frise:relache posés par 74-vf-frise-curseur.js) et rend son nettoyage ; chaque contrôle porte `data-foc`,
// restitué quand la zone redessine sous le focus.
(() => {
  'use strict';
  const W = window, D = document, NB = '\u00a0', MAX = 8;
  const MOT = { travail: 'au travail', 'attend-humain': 'vous attend', 'attend-agents': 'attend ses agents', repos: 'au repos', 'pas-lance': 'pas encore lancé',
    termine: 'terminé' };
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const pluriel = (n, un, plusieurs) => `${n} ${n > 1 ? plusieurs : un}`;
  if (D.head && !D.head.querySelector('style[data-vf-encart]')) {
    const st = D.createElement('style'); st.setAttribute('data-vf-encart', '');
    st.textContent = `
      .vf-encart { margin: var(--sp-12) 0 0; color: var(--text); font-size: 12.5px; line-height: 16px; }
      .vf-encart-titre { margin: 0 0 var(--sp-8); font: 600 13px/18px var(--sans); color: var(--text); }
      .vf-encart h4 { margin: var(--sp-12) 0 var(--sp-4); font: 600 12.5px/16px var(--sans); color: var(--text); }
      .vf-encart ul { margin: 0; padding: 0; list-style: none; }
      .vf-encart li { padding: var(--sp-2) 0; }
      .vf-encart-aide, .vf-encart-note, .vf-encart-etat, .vf-encart-bilan { margin: var(--sp-4) 0; color: var(--text-3); }
      .vf-encart-carte { margin-top: var(--sp-8); min-height: 28px; padding: var(--sp-4) var(--sp-12); border: 0; border-radius: 8px; background: var(--raise);
        color: var(--text); font: 500 13px/18px var(--sans); cursor: pointer; }
      .vf-encart button:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
      @media (pointer: coarse) { .vf-encart button { min-height: 44px; } }`;
    D.head.appendChild(st);
  }
  const garderFocus = (zone, refaire) => {
    const a = D.activeElement, k = a && a !== D.body && zone.contains(a) ? a.getAttribute('data-foc') : null;
    refaire();
    const n = k === null ? null : [...zone.querySelectorAll('[data-foc]')].find((x) => x.getAttribute('data-foc') === k);
    if (n) n.focus({ preventScroll: true });
  };
  const aide = () => h('p', 'vf-encart-aide',
    `Posez le curseur sur la frise pour relire un instant${NB}: un clic dans les pistes, ou la flèche gauche. Échap revient à maintenant.`);

  function voies(ctx, t) {
    const ul = h('ul', 'vf-encart-voies'), M = ctx.modele, present = t >= ctx.jusqua - 1000;
    for (const r of ctx.rangs) {
      const v = r.voie, li = h('li'), nom = (ctx.nomsParId && ctx.nomsParId.get(r.id)) || v.id, etat = M.etatA(v, t);
      li.setAttribute('data-id', v.id);
      li.append(h('span', 'mono', nom), ` ${MOT[etat] || etat}${present && v.etatOfficiel === null ? ' · déduit' : ''}`);
      ul.append(li);
    }
    return ul;
  }
  function noeuds(ctx, t) {
    const E = W.VF_ETAT, sg = E && E.lire('etat'), missions = sg && sg.signal && Array.isArray(sg.signal.missions) ? sg.signal.missions : [];
    const { portes, sansAgent } = ctx.modele.noeudsPortes(ctx.frise.voies, t, missions), roles = new Map(ctx.frise.voies.map((v) => [v.id, v.role || 'agent']));
    const out = [];
    if (portes.length) {
      const ul = h('ul', 'vf-encart-noeuds');
      for (const p of portes) {
        const li = h('li'), txt = p.etat === 'repos' ? 'porté, agent au repos' : `porté par ${roles.get(p.agentId)}, ${MOT[p.etat]}`;
        li.append(h('span', 'mono', p.noeud), ` · ${txt}`); ul.append(li);
      }
      out.push(ul);
    }
    if (sansAgent !== null) out.push(h('p', 'vf-encart-bilan', `${pluriel(sansAgent, 'autre nœud', 'autres nœuds')} du plan${NB}: aucun agent`));
    out.push(h('p', 'vf-encart-note', `Chaque nœud est déduit des voies${NB}: aucun statut du plan n'est relu.`));
    return out;
  }

  function fichiers(st, ctx, t) {
    const L = st.lecteur, e = L.etat(), res = L.resultat(), sec = h('section', 'vf-encart-fichiers');
    const occupe = e !== 'ok' && e !== 'echec';
    sec.setAttribute('aria-busy', occupe ? 'true' : 'false');
    sec.append(h('h4', '', 'Fichiers écrits autour de cet instant'));
    if (occupe) { sec.append(h('p', 'vf-encart-etat', 'Lecture des fichiers')); return sec; }
    if (e === 'echec') {
      const b = h('button', 'vf-frise-reessayer', 'Réessayer'); b.type = 'button'; b.setAttribute('data-foc', 'reessayer');
      b.addEventListener('click', () => L.reessayer());
      sec.append(h('p', 'vf-encart-etat', "Les fichiers n'ont pas pu être lus."), b);
      return sec;
    }
    const n = res.ecrits.length;
    if (res.plus) sec.append(h('p', 'vf-encart-etat', `200 ou plus${NB}: la table d'une voie est coupée.`));
    if (n) {
      const ul = h('ul', 'vf-encart-liste');
      for (const f of res.ecrits.slice(0, MAX)) {
        const li = h('li'); li.setAttribute('data-fichier', ''); li.setAttribute('data-cible', f.cible);
        li.setAttribute('data-arbre', f.arbre === null ? '' : f.arbre);
        li.append(h('span', 'mono', f.cible)); if (f.arbre !== null) li.append(' · ', h('span', 'mono', f.arbre));
        ul.append(li);
      }
      sec.append(ul);
      if (n > MAX) sec.append(h('p', 'vf-encart-etat', `et ${n - MAX} ${n - MAX > 1 ? 'autres' : 'autre'}`));
    } else if (res.nonLues > 0) sec.append(h('p', 'vf-encart-etat', 'Fichiers non lus'));
    else if (!res.plus) sec.append(h('p', 'vf-encart-etat', 'Aucun fichier écrit à cet instant.'));
    if (res.nonLues > 0) sec.append(h('p', 'vf-encart-etat', pluriel(res.nonLues, 'voie non lue', 'voies non lues')));
    if (res.coupees > 0) sec.append(h('p', 'vf-encart-etat', pluriel(res.coupees, 'cible coupée', 'cibles coupées')));
    if (n) {
      const b = h('button', 'vf-encart-carte', 'Voir sur la carte'); b.type = 'button'; b.setAttribute('data-foc', 'carte');
      b.setAttribute('aria-label', `Voir ${n > 1 ? `ces ${n} fichiers` : 'ce fichier'} sur la carte`);
      b.addEventListener('click', () => {
        const F = W.__vfFrise, titre = `Fichiers écrits vers ${ctx.modele.fmtHeure(t, { phrase: true })}`;
        if (F && typeof F.voirSurLaCarte === 'function') {
          Promise.resolve(F.voirSurLaCarte(res.ecrits.map((f) => ({ arbre: f.arbre, cible: f.cible })), titre))
            .catch(() => F.annoncer("L'onglet Code n'a pas pu s'ouvrir."));
        }
      });
      sec.append(b);
    }
    return sec;
  }

  function dessiner(st) {
    const ctx = st.ctx, e = ctx && ctx.emplacement, F = W.__vfFrise;
    if (!st.vivant || !e || !e.isConnected || !F) return;
    const t = F.donnees().curseurMs;
    garderFocus(e, () => {
      const racine = h('div', 'vf-encart');
      if (t === null) racine.append(aide());
      else {
        racine.append(h('h3', 'vf-encart-titre', `À cet instant, ${ctx.modele.fmtHeure(t, { phrase: true })}`), voies(ctx, t),
          ...noeuds(ctx, t), fichiers(st, ctx, t));
      }
      e.replaceChildren(racine);
    });
  }

  const rappel = (a) => {
    const F = W.__vfFrise, FI = W.__vfFriseFichiers;
    if (!a || a.onglet !== 'equipe' || !F || !FI || typeof F.enregistrer !== 'function') return undefined;
    const st = { vivant: true, ctx: null, lecteur: null };
    st.lecteur = FI.creer(() => dessiner(st));
    const surCurseur = () => {
      const t = F.donnees().curseurMs;
      if (t === null || !st.ctx) { st.lecteur.annuler(); dessiner(st); } else st.lecteur.demander(st.ctx, t, false);
    };
    const surRelache = () => { const t = F.donnees().curseurMs; if (t !== null && st.ctx) st.lecteur.demander(st.ctx, t, true); };
    D.addEventListener('vf-frise:curseur', surCurseur); D.addEventListener('vf-frise:relache', surRelache);
    F.enregistrer('encart', { rendre: (ctx) => { if (!st.vivant) return; st.ctx = ctx; st.lecteur.majCtx(ctx); dessiner(st); } });
    return () => {
      st.vivant = false; D.removeEventListener('vf-frise:curseur', surCurseur); D.removeEventListener('vf-frise:relache', surRelache); st.lecteur.fermer();
    };
  };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(rappel, { cle: '74-vf-frise-encart.js' });
})();
