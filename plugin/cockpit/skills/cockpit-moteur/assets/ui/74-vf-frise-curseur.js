// VibeFlow (74-06) : le curseur de relecture de la frise (P74-D-12). Extension `curseur` du registre de 74-vf-frise.js : un repère `role=slider` dans
// la couche HTML superposée aux pistes (jamais sous aria-hidden), un trait plein dans la couche SVG. Au clavier : ← → d'un pas (1/90 de la fenêtre,
// Maj = dix pas ; en lecture Événements, à la frontière de segment ou à l'événement voisin), Début, Fin, Échap (écouteur de REMONTÉE sur la racine de la vue,
// jamais en capture : un appui dont defaultPrevented est vrai est ignoré, une surcouche vient de le prendre ; le conteneur de la frise garde les touches
// pour lui). Au pointeur : un clic ou un glisser dans les pistes pose le curseur, le survol seul trace un
// repère et dit l'heure ; au toucher, un tap seulement (un glissement fait défiler le conteneur). Un instant tombé dans un repère de silence se cale
// sur le bord le plus proche. La pose passe par window.__vfFrise.poserCurseur ; le relâché dit `vf-frise:relache` (lecture immédiate des fichiers,
// 74-vf-frise-fichiers.js). Rien ne se dessine au chargement : le rappel de surOnglet enregistre l'extension et rend son nettoyage (écouteurs, repère,
// trait, finirRelecture).
(() => {
  'use strict';
  const W = window, D = document, SVGNS = 'http://www.w3.org/2000/svg';
  if (D.head && !D.head.querySelector('style[data-vf-curseur]')) {
    const st = D.createElement('style'); st.setAttribute('data-vf-curseur', '');
    st.textContent = `
      .vf-frise-couche > svg { position: absolute; left: 0; top: 0; width: 100%; height: 100%; overflow: visible; pointer-events: none; }
      .vf-frise-curseur-trait { stroke: var(--text); stroke-width: 1.5; }
      .vf-frise-survol { stroke: var(--hair-2); stroke-width: 1; }
      .vf-frise-curseur { position: absolute; top: calc(var(--frise-courbe) + var(--frise-axe) / 2);
        width: 20px; height: var(--frise-axe); box-sizing: border-box;
        transform: translate(-50%, -50%); padding: 0; border: 0; background: transparent; pointer-events: auto; cursor: ew-resize; touch-action: none; }
      .vf-frise-curseur::after { content: ''; position: absolute; left: 50%; top: 0; bottom: 0; width: 6px; transform: translateX(-50%); border-radius: 999px;
        background: var(--text); }
      .vf-frise-curseur:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
      @media (pointer: coarse) { .vf-frise-curseur { width: 44px; height: 44px; } }`;
    D.head.appendChild(st);
  }
  const F = () => W.__vfFrise;
  const pose = () => F().donnees().curseurMs;
  const ligne = (cls) => {
    const l = D.createElementNS(SVGNS, 'line');
    l.setAttribute('class', cls); l.setAttribute('y1', '0'); l.setAttribute('y2', '100%');
    return l;
  };
  const poser = (ctx, ms) => {
    const bornee = Math.min(Math.max(ms, ctx.depuis), ctx.jusqua);
    // calage sur le bord le plus proche d'un repère de silence
    const k = ctx.lecture === 'evenements' ? ctx.proj.troncons.find((x) => x.silence && bornee > x.debut && bornee < x.fin) : null;
    F().poserCurseur(k ? (bornee - k.debut <= k.fin - bornee ? k.debut : k.fin) : bornee);
  };
  const retirer = (annonce) => {
    if (pose() === null) return;
    F().poserCurseur(null);
    if (typeof F().finirRelecture === 'function') F().finirRelecture();
    if (annonce) F().annoncer(annonce);
  };
  const instants = (ctx) => { // frontières de segment et événements de la fenêtre
    const s = new Set();
    for (const v of ctx.frise.voies) { for (const g of v.segments) { s.add(g.debut); s.add(g.fin); } for (const e of v.evenements) s.add(e.t); }
    return [...s].filter((x) => x >= ctx.depuis && x <= ctx.jusqua).sort((a, b) => a - b);
  };
  const msDe = (ctx, px) => { // inverse de ctx.x : tronçons de la projection (Horloge linéaire, Événements par morceaux)
    const x = px - ctx.dim.margeG, T = ctx.proj.troncons;
    if (!T.length || x <= 0) return ctx.depuis;
    const k = T.find((q) => x <= q.x1);
    if (!k) return ctx.jusqua;
    return k.x1 > k.x0 ? k.debut + ((x - k.x0) / (k.x1 - k.x0)) * (k.fin - k.debut) : k.debut;
  };

  const monter = () => {
    const st = { ctx: null, defil: null, el: null, trait: null, survol: null, glisse: null, tap: null, retraits: [] };
    const svg = () => st.ctx.nodes.couche.querySelector('svg'), zone = () => st.ctx.nodes.couche.querySelector('.vf-frise-zone');
    const px = (e) => e.clientX - st.ctx.nodes.couche.getBoundingClientRect().left;
    const sansSurvol = () => { if (st.survol) { st.survol.remove(); st.survol = null; } if (st.defil) st.defil.removeAttribute('title'); };

    const maj = () => {
      const ctx = st.ctx;
      if (!ctx || !st.el) return;
      const cur = pose(), ms = cur === null ? ctx.jusqua : cur, x = ctx.x(ms), M = ctx.modele;
      if (st.el.parentNode !== zone()) zone().append(st.el);
      st.el.style.left = `${x}px`;
      st.el.setAttribute('aria-valuemin', String(ctx.depuis)); st.el.setAttribute('aria-valuemax', String(ctx.jusqua));
      st.el.setAttribute('aria-valuenow', String(ms));
      st.el.setAttribute('aria-valuetext', cur === null ? 'maintenant' : M.fmtHeure(ms, { phrase: true }));
      if (cur === null) { if (st.trait) { st.trait.remove(); st.trait = null; } return; }
      if (!st.trait) st.trait = ligne('vf-frise-curseur-trait');
      st.trait.setAttribute('x1', String(x)); st.trait.setAttribute('x2', String(x));
      if (st.trait.parentNode !== svg()) svg().append(st.trait);
    };
    const surTouche = (e) => {
      const ctx = st.ctx;
      if (!ctx || e.altKey || e.ctrlKey || e.metaKey) return;
      const cur = pose(), ici = cur === null ? ctx.jusqua : cur, p = (ctx.jusqua - ctx.depuis) / 90, n = e.shiftKey ? 10 : 1, ev = ctx.lecture === 'evenements';
      let t;
      if (e.key === 'ArrowLeft') {
        if (ev) { const avant = instants(ctx).filter((x) => x < ici - 0.5); t = avant.length ? avant[avant.length - 1] : ctx.depuis; } else t = ici - n * p;
      } else if (e.key === 'ArrowRight') {
        if (cur !== null) {
          const apres = ev ? instants(ctx).filter((x) => x > ici + 0.5) : [];
          t = ev ? (apres.length ? apres[0] : ctx.jusqua) : ici + n * p;
          if (t >= ctx.jusqua) { e.preventDefault(); e.stopPropagation(); return retirer(); }
        }
      } else if (e.key === 'Home') t = ctx.depuis;
      else if (e.key === 'End') { e.preventDefault(); e.stopPropagation(); return retirer(); }
      else return;
      e.preventDefault(); e.stopPropagation();
      if (t !== undefined) poser(ctx, t);
    };
    const surEchap = (e) => { // remontée sur la racine de la vue : un appui déjà pris par une surcouche (defaultPrevented) est ignoré
      if (e.key !== 'Escape' || e.defaultPrevented || !st.ctx || pose() === null) return;
      e.preventDefault(); e.stopPropagation(); retirer();
    };
    const relache = () => D.dispatchEvent(new CustomEvent('vf-frise:relache'));
    const surBas = (e) => {
      const ctx = st.ctx, c = e.target;
      if (!ctx || e.button > 0 || !(c instanceof Element)) return;
      const poignee = c === st.el;
      if (!poignee && (c.closest('button, a, input, [data-foc]') || !c.closest('.vf-frise-p'))) return;
      if (e.pointerType === 'touch' && !poignee) { st.tap = { x: e.clientX, y: e.clientY, id: e.pointerId }; return; }
      st.glisse = e.pointerId; sansSurvol();
      try { st.defil.setPointerCapture(e.pointerId); } catch { /* capture refusée : le glisser reste dans le conteneur */ }
      poser(ctx, msDe(ctx, px(e))); e.preventDefault(); st.el.focus({ preventScroll: true });
    };
    const surMouvement = (e) => {
      const ctx = st.ctx, c = e.target;
      if (!ctx) return;
      if (st.glisse === e.pointerId) return poser(ctx, msDe(ctx, px(e)));
      if (st.tap || e.pointerType === 'touch' || e.buttons || !(c instanceof Element) || !c.closest('.vf-frise-p')) return e.buttons ? undefined : sansSurvol();
      const ms = msDe(ctx, px(e)), x = ctx.x(ms);
      if (!st.survol) { st.survol = ligne('vf-frise-survol'); st.survol.setAttribute('data-survol', ''); svg().append(st.survol); }
      st.survol.setAttribute('x1', String(x)); st.survol.setAttribute('x2', String(x)); st.defil.title = ctx.modele.fmtHeure(ms);
    };
    const surHaut = (e) => {
      const ctx = st.ctx;
      if (st.glisse === e.pointerId) { st.glisse = null; try { st.defil.releasePointerCapture(e.pointerId); } catch { /* déjà relâchée */ } relache(); return; }
      if (st.tap && st.tap.id === e.pointerId) {
        const t = st.tap; st.tap = null;
        if (ctx && Math.hypot(e.clientX - t.x, e.clientY - t.y) < 10) { poser(ctx, msDe(ctx, px(e))); st.el.focus({ preventScroll: true }); relache(); }
      }
    };
    const surAnnule = () => { st.glisse = null; st.tap = null; };
    const lier = (ctx) => {
      if (st.defil === ctx.nodes.defil) return;
      delier();
      const d = st.defil = ctx.nodes.defil, el = st.el = D.createElement('div');
      el.className = 'vf-frise-curseur'; el.setAttribute('role', 'slider'); el.setAttribute('aria-label', 'Curseur de la frise'); el.tabIndex = 0;
      el.addEventListener('keydown', surTouche);
      const racine = d.closest('.vf-frise');
      if (racine) { racine.addEventListener('keydown', surEchap); st.retraits.push(() => racine.removeEventListener('keydown', surEchap)); }
      const ecouteurs = [['pointerdown', surBas], ['pointermove', surMouvement], ['pointerup', surHaut], ['pointercancel', surAnnule],
        ['pointerleave', sansSurvol]];
      for (const [n, f] of ecouteurs) {
        d.addEventListener(n, f); st.retraits.push(() => d.removeEventListener(n, f));
      }
    };
    const delier = () => {
      for (const r of st.retraits.splice(0)) r();
      if (st.el) st.el.remove();
      if (st.trait) st.trait.remove();
      sansSurvol(); st.el = st.trait = st.defil = null;
    };
    const surCurseur = () => maj();
    D.addEventListener('vf-frise:curseur', surCurseur);
    return {
      rendre(ctx) {
        st.ctx = ctx; lier(ctx);
        const cur = pose();
        if (cur !== null && cur < ctx.depuis) retirer('Le curseur est sorti de la fenêtre');
        maj();
      },
      fin() {
        D.removeEventListener('vf-frise:curseur', surCurseur); delier(); st.ctx = null;
        const f = F();
        if (f && typeof f.finirRelecture === 'function') f.finirRelecture();
      },
    };
  };

  const rappel = (a) => {
    const f = F();
    if (!a || a.onglet !== 'equipe' || !f || typeof f.enregistrer !== 'function') return undefined;
    const c = monter();
    f.enregistrer('curseur', { rendre: (ctx) => c.rendre(ctx) });
    return () => c.fin();
  };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(rappel, { cle: '74-vf-frise-curseur.js' });
})();
