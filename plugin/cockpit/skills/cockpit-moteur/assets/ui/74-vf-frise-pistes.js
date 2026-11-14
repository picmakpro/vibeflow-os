// VibeFlow (74-04) : les pistes de la frise en SVG : segments (quatre sortes lisibles sans la couleur), événements dans le rail du haut, axe et trait «
// maintenant »,
// bandeau haut (courbe du nombre d'agents au travail), légende, liste textuelle `.sr`. Tout est créé par createElementNS et posé en UN replaceChildren par
// zone.
// Une erreur ne teinte jamais une voie ; le genre « silence » ne dessine rien ; aucune couleur par nœud. Lu à l'usage : window.__vfFrisePistes.dessiner(ctx).
(() => {
  'use strict';
  const D = document, SVGNS = 'http://www.w3.org/2000/svg', NB = ' ', ID_HACHURES = 'vf-frise-hachures';
  const el = (tag, attrs, parent) => {
    const e = D.createElementNS(SVGNS, tag);
    for (const k of Object.keys(attrs || {})) e.setAttribute(k, String(attrs[k]));
    if (parent) parent.appendChild(e);
    return e;
  };
  const txt = (parent, attrs, t) => { const e = el('text', attrs, parent); e.textContent = t; return e; };
  const ETAT = { travail: 'travail', 'attend-humain': 'attend', 'attend-agents': 'agents', repos: 'repos' };
  const MOT = { travail: 'au travail', 'attend-humain': 'vous attend', 'attend-agents': 'attend ses agents', repos: 'au repos' };
  const MOT_EVT = { compaction: 'compaction', erreur: "erreur d'outil", humain: "message de l'humain", rapport: 'rapport rendu',
    dispatch: "lancement d'un agent" };
  const PRIORITE = ['erreur', 'compaction', 'rapport', 'humain'];

  // glyphes d'événement : début
  const glyphe = (parent, genre, cx, cy) => {
    const g = el('g', { 'data-evt': genre }, parent);
    if (genre === 'compaction') el('path', { d: `M${cx} ${cy - 5}L${cx + 5} ${cy + 4}L${cx - 5} ${cy + 4}Z` }, g);
    else if (genre === 'erreur') el('path', { d: `M${cx - 4} ${cy - 4}L${cx + 4} ${cy + 4}M${cx + 4} ${cy - 4}L${cx - 4} ${cy + 4}` }, g);
    else if (genre === 'rapport') el('path', { d: `M${cx - 5} ${cy}L${cx - 1.5} ${cy + 3.5}L${cx + 5} ${cy - 4}` }, g);
    else el('circle', { cx, cy, r: 3.5 }, g);
    return g;
  };
  // glyphes d'événement : fin

  // segments affichés : coalescés par le modèle, bornés à la fenêtre, sans silence (la liste `.sr` et le dessin lisent la même fonction)
  const segmentsDe = (v, ctx) => ctx.modele.coalescer(v.segments, ctx.msParPixel)
    .filter((s) => s.genre !== 'silence' && Math.min(s.fin, ctx.jusqua) > Math.max(s.debut, ctx.depuis));
  const titre = (e, mot, a, b, ctx) => { const t = el('title', {}, e);
    t.textContent = `${mot}, ${ctx.modele.fmtHeure(a)} à ${ctx.modele.fmtHeure(b)}, ${ctx.modele.fmtDuree((b - a) / 1000)}`; };

  const segment = (g, v, s, y, ctx) => {
    const { dim } = ctx, a = Math.max(s.debut, ctx.depuis), b = Math.min(s.fin, ctx.jusqua), x0 = ctx.x(a), w = Math.max(1, ctx.x(b) - x0),
      cy = y + dim.barre / 2;
    const etat = ETAT[s.genre], coupe = s.debut < ctx.depuis;
    let e;
    if (etat === 'travail' || etat === 'attend') {
      const rect = el('rect', { x: x0, y, width: w, height: dim.barre, rx: dim.barre / 2, 'data-etat': etat, stroke: 'none' }, g);
      if (etat === 'attend') {
        rect.setAttribute('fill', 'url(#' + ID_HACHURES + ')');
      } else rect.classList.add('vf-frise-seg');
      e = rect;
      if (coupe) { // coupé net à gauche : un cache de rayon 0 sur le bord gauche
        const cap = el('rect', { x: x0, y, width: Math.min(dim.barre / 2, w), height: dim.barre, rx: 0, class: 'vf-frise-coupe', 'data-coupe': '',
          stroke: 'none' }, g);
        if (etat === 'attend') cap.setAttribute('fill', 'url(#' + ID_HACHURES + ')'); else cap.classList.add('vf-frise-seg');
      }
    } else {
      e = el('line', { x1: x0, x2: x0 + w, y1: cy, y2: cy, 'data-etat': etat, 'stroke-linecap': 'round' }, g);
      if (etat === 'repos') e.setAttribute('stroke-dasharray', `0 ${dim.sp8}`);
    }
    titre(e, MOT[s.genre] || s.genre, s.debut, s.fin, ctx);
  };

  // événements du rail : deux événements à moins de --sp-12 se confondent en un glyphe suivi de « +N » (le compte est écrit)
  const evenements = (g, v, y, ctx, indexDe, V) => {
    const { dim } = ctx, cy = y + dim.glyphe / 2, evts = v.evenements.filter((e) => e.t >= ctx.depuis && e.t <= ctx.jusqua), groupes = [];
    for (const e of evts) {
      if (e.genre === 'dispatch') continue;
      const gr = groupes[groupes.length - 1], x = ctx.x(e.t);
      if (gr && x - gr.xPrec < dim.glyphe) { gr.evts.push(e); gr.xPrec = x; } else groupes.push({ x, xPrec: x, evts: [e] });
    }
    for (const gr of groupes) {
      const genre = PRIORITE.find((p) => gr.evts.some((e) => e.genre === p)) || gr.evts[0].genre, gl = glyphe(g, genre, gr.x, cy);
      const t = el('title', {}, gl); t.textContent = `${MOT_EVT[genre]}, ${ctx.modele.fmtHeure(gr.evts[0].t)}`;
      if (gr.evts.length > 1) txt(g, { class: 'vf-frise-plus', x: gr.x + dim.glyphe / 2 + 2, y: cy + 4 }, `+${gr.evts.length - 1}`);
    }
    for (const e of evts.filter((x) => x.genre === 'dispatch')) { // lancement : trait vertical du parent à la voie de l'enfant
      const pi = indexDe.get(v.parent);
      if (pi === undefined) continue;
      const x = ctx.x(e.t), py = pi * V + dim.voie / 2;
      el('line', { x1: x, x2: x, y1: Math.min(py, y), y2: Math.max(py, y), class: 'vf-frise-dispatch' }, g);
    }
  };

  const voies = (ctx) => {
    const { dim } = ctx, V = dim.voie, n = ctx.lignes.length, svg = el('svg', { class: 'vf-frise-pistes', width: ctx.largeur, height: n * V,
      'aria-hidden': 'true', focusable: 'false' });
    const defs = el('defs', {}, svg), pat = el('pattern', { id: ID_HACHURES, patternUnits: 'userSpaceOnUse', width: dim.sp6, height: dim.sp6,
      patternTransform: 'rotate(45)' }, defs);
    el('line', { x1: 0, y1: 0, x2: 0, y2: dim.sp6, class: 'vf-frise-hachure', 'stroke-width': dim.sp2 }, pat);
    for (const gr of ctx.proj.graduations) el('line', { x1: gr.x + dim.margeG, x2: gr.x + dim.margeG, y1: 0, y2: n * V, class: 'vf-frise-trait' }, svg);
    const indexDe = new Map(ctx.lignes.map((l, i) => [l.rang && l.rang.id, i]));
    const mh = V > 40 ? dim.sp12 : dim.sp4;
    ctx.lignes.forEach((l, i) => {
      if (!l.rang) return;
      const v = l.rang.voie, g = el('g', { 'data-voie': v.id }, svg), y0 = i * V, yBarre = y0 + mh + dim.glyphe + dim.sp4;
      for (const s of segmentsDe(v, ctx)) segment(g, v, s, yBarre, ctx);
      evenements(g, v, y0 + mh, ctx, indexDe, V);
    });
    maintenant(svg, ctx, n * V);
    ctx.nodes.voiesP.replaceChildren(svg);
  };
  const maintenant = (svg, ctx, hauteur) => {
    const x = ctx.x(ctx.jusqua);
    el('line', { x1: x, x2: x, y1: 0, y2: hauteur, class: 'vf-frise-maintenant', 'stroke-dasharray': `${ctx.dim.sp4} ${ctx.dim.sp4}` }, svg);
  };

  // bandeau haut : escalier du nombre de voies au travail, rempli en neutre, trait supérieur ; échelle 0 à max(4, pic)
  const courbe = (ctx) => {
    const { dim } = ctx, H = dim.courbe, c = ctx.courbe, svg = el('svg', { class: 'vf-frise-courbe-svg', width: ctx.largeur, height: H,
      'aria-hidden': 'true', focusable: 'false' });
    const y = (k) => H - (k / c.echelle) * (H - 2), haut = [];
    for (const p of c.pas) haut.push([ctx.x(p.debut), y(p.n)], [ctx.x(p.fin), y(p.n)]);
    const pts = (l) => l.map((q) => q.join(',')).join(' ');
    const poly = el('polygon', { class: 'vf-frise-courbe-fond', points: pts([[ctx.x(ctx.depuis), H], ...haut, [ctx.x(ctx.jusqua), H]]) }, svg);
    poly.setAttribute('data-marches', String(c.pas.length));
    el('polyline', { class: 'vf-frise-courbe-trait', points: pts(haut) }, svg);
    ctx.nodes.courbe.p.replaceChildren(svg);
  };

  const heureAxe = (ms, M) => { const d = new Date(ms); return d.getHours() === 0 && d.getMinutes() === 0 ? d.toLocaleDateString('fr-FR', { day: 'numeric',
    month: 'short' }) : M.fmtHeure(ms); };
  const axe = (ctx) => {
    const { dim } = ctx, H = dim.axe, svg = el('svg', { class: 'vf-frise-axe-svg', width: ctx.largeur, height: H, 'aria-hidden': 'true', focusable: 'false' });
    for (const gr of ctx.proj.graduations) {
      el('line', { x1: gr.x + dim.margeG, x2: gr.x + dim.margeG, y1: H - dim.sp4, y2: H, class: 'vf-frise-trait' }, svg);
      txt(svg, { class: 'vf-frise-grad', x: gr.x + dim.margeG, y: H - dim.sp8, 'text-anchor': 'middle' }, heureAxe(gr.ms, ctx.modele));
    }
    for (const r of ctx.proj.reperes) { // silence raccourci : deux filets et la durée vraie
      const g = el('g', { class: 'vf-frise-repere', 'data-duree': r.dureeS }, svg), a = r.x + dim.margeG, b = a + r.largeur;
      el('line', { x1: a, x2: a, y1: 0, y2: H, class: 'vf-frise-filet' }, g); el('line', { x1: b, x2: b, y1: 0, y2: H, class: 'vf-frise-filet' }, g);
      txt(g, { class: 'vf-frise-repere-t', x: (a + b) / 2, y: H - dim.sp8, 'text-anchor': 'middle' }, ctx.modele.fmtDuree(r.dureeS));
    }
    const x = ctx.x(ctx.jusqua);
    maintenant(svg, ctx, H);
    txt(svg, { class: 'vf-frise-grad', x: x - dim.sp4, y: dim.sp12, 'text-anchor': 'end' }, 'maintenant');
    ctx.nodes.axe.p.replaceChildren(svg);
  };

  // légende : échantillons de 24 × 8 dessinés comme les segments, puis les glyphes
  const echantillon = (genre, dim) => {
    const svg = el('svg', { width: 24, height: 8, viewBox: '0 0 24 8', 'aria-hidden': 'true', focusable: 'false' }), etat = ETAT[genre];
    if (etat === 'travail') el('rect', { x: 0, y: 0, width: 24, height: 8, rx: 4, class: 'vf-frise-seg', 'data-ech': etat }, svg);
    else if (etat === 'attend') el('rect', { x: 0, y: 0, width: 24, height: 8, rx: 4, fill: 'url(#' + ID_HACHURES + ')', 'data-ech': etat }, svg);
    else el('line', { x1: 1, x2: 23, y1: 4, y2: 4, 'data-ech': etat, 'stroke-linecap': 'round',
      ...(etat === 'repos' ? { 'stroke-dasharray': `0 ${dim.sp8}` } : {}) }, svg);
    return svg;
  };
  const legende = (ctx) => {
    const L = ctx.nodes.legende, items = [];
    const item = (svg, t) => { const s = D.createElement('span'); s.className = 'vf-frise-leg'; s.append(svg, t); items.push(s); };
    for (const genre of ['travail', 'attend-humain', 'attend-agents', 'repos']) item(echantillon(genre, ctx.dim),
      MOT[genre][0].toUpperCase() + MOT[genre].slice(1));
    for (const [genre, t] of [['compaction', 'Compaction'], ['erreur', "Erreur d'outil"], ['humain', "Message de l'humain"], ['rapport', 'Rapport rendu']]) {
      const svg = el('svg', { width: 16, height: 16, viewBox: '0 0 16 16', 'aria-hidden': 'true', focusable: 'false' }); glyphe(svg, genre, 8, 8); item(svg, t);
    }
    const dm = el('svg', { width: 16, height: 16, viewBox: '0 0 16 16', 'aria-hidden': 'true', focusable: 'false' }); el('polygon',
      { points: '8,2 14,8 8,14 2,8', class: 'vf-frise-losange' }, dm); item(dm, 'Commit');
    const ls = el('svg', { width: 16, height: 16, viewBox: '0 0 16 16', 'aria-hidden': 'true', focusable: 'false' }); el('line', { x1: 8, x2: 8, y1: 2,
      y2: 14, class: 'vf-frise-dispatch' }, ls); item(ls, "Lancement d'un agent");
    L.replaceChildren(...items);
  };

  // alternative textuelle : une voie par élément, un sous-élément par segment affiché et par événement, jamais tronquée par le repli
  const liste = (ctx) => {
    const S = ctx.nodes.sr, M = ctx.modele, ul = D.createElement('ul'), h3 = D.createElement('h3');
    h3.className = 'sr';
      h3.textContent = `Frise en liste, sur les dernières ${ctx.libFenetre}, lecture ${ctx.lecture === 'horloge' ? 'horloge' : 'événements'}`;
    for (const r of ctx.rangs) {
      const li = D.createElement('li'), sous = D.createElement('ul'), v = r.voie, etat = M.etatA(v, ctx.jusqua - 1);
      li.setAttribute('data-id', v.id); li.append(`${ctx.nomsParId.get(r.id) || v.id}, ${etat}`);
      for (const s of segmentsDe(v, ctx)) {
        const e = D.createElement('li'); e.setAttribute('data-seg', ETAT[s.genre]);
        e.textContent = `de ${M.fmtHeure(s.debut, { phrase: true })} à ${M.fmtHeure(s.fin, { phrase: true })}, ${MOT[s.genre]}`; sous.append(e);
      }
      for (const ev of v.evenements.filter((x) => x.t >= ctx.depuis && x.t <= ctx.jusqua)) {
        const e = D.createElement('li'); e.setAttribute('data-evt-li', ev.genre);
          e.textContent = `${M.fmtHeure(ev.t, { phrase: true })}, ${MOT_EVT[ev.genre]}`; sous.append(e);
      }
      li.append(sous); ul.append(li);
    }
    S.replaceChildren(h3, ul);
  };

  function dessiner(ctx) {
    ctx.msParPixel = Math.max(1, (ctx.jusqua - ctx.depuis) / Math.max(1, ctx.largeur));
    courbe(ctx); axe(ctx); voies(ctx); legende(ctx); liste(ctx);
  }
  window.__vfFrisePistes = { dessiner, segmentsDe, glyphe };
})();
