// VibeFlow (77-06, SYNT-01, SYNT-08 ; P77-D-02, P77-D-13, P77-D-14) : le bloc « Burn-up du jalon » de la Synthèse. La tête « N sur M · P % » est recopiée
// de `meta.vf.burnup` (jamais recalculée : c'est la valeur du pied de la carte du jalon), la courbe en escalier a deux séries neutres (plein, tirets) aux
// étiquettes directes, sans légende ni teinte, et son équivalent texte est une liste datée. Aucune date n'est estimée : une phase close sans date est
// nommée sous le graphe. Fonctions pures (date du jour passée en argument AAAA-MM-JJ), exposées par window.__vfSyntheseBurnup ; rien ne touche `document`
// au chargement. Inscrit son bloc au registre de la coquille (74-vf-synthese.js) : `rendre` reçoit le conteneur SOUS le h3 que pose la coquille. Script
// par onglet : l'écouteur de média et l'abonnement au magasin d'état sont posés par `installer` et retirés par la fonction qu'il rend. Aucune lecture
// réseau, aucun stockage.
(() => {
  'use strict';
  const NB = ' ', SVG = 'http://www.w3.org/2000/svg';
  const MOIS = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  const jour = (s) => Date.UTC(Number(s.slice(0, 4)), Number(s.slice(5, 7)) - 1, Number(s.slice(8, 10))) / 86400000;
  const iso = (j) => new Date(j * 86400000).toISOString().slice(0, 10);
  const date = (s) => { const j = Number(s.slice(8, 10)); return `${j === 1 ? '1er' : j} ${MOIS[Number(s.slice(5, 7)) - 1]}`; };
  const fin = (s) => (s.endsWith('.') ? s : `${s}.`); // la date abrégée porte déjà son point (« nov. »)
  const r1 = (x) => Math.round(x * 10) / 10;
  const num = (p) => String(p && p.n !== undefined ? p.n : p);
  const phases = (l) => (l.length > 1 ? `Phases ${l.slice(0, -1).map(num).join(', ')} et ${num(l.at(-1))}` : `Phase ${num(l[0])}`);
  const pluriel = (n, mot, accord) => `${n} ${mot}${n > 1 ? 's' : ''}${accord ? ` ${accord}${n > 1 ? 's' : ''}` : ''}`;

  const tete = (b) => [b.clos, 'sur', b.total, '·', b.pct, '%'].join(NB);

  // courbe : viewBox 320 × 160, tracé de x 28 à 236 et de y 128 (valeur 0) à 16 (valeur M) ;
  // t0 = ouverture du jalon, tN = aujourd'hui tant que le jalon n'est pas clos, sinon la dernière clôture (au moins un jour d'écart)
  function courbe(b, aujourdhui) {
    const S = b.serie, M = b.total, t0 = jour(b.ouverture), derniere = S.at(-1), k = derniere.clos;
    const cloture = (S.filter((p) => p.closes.length).at(-1) || derniere).d;
    const tN = Math.max(b.clos < b.total ? Math.max(jour(aujourdhui), jour(derniere.d)) : jour(cloture), t0 + 1);
    const x = (j) => r1(28 + (208 * (j - t0)) / (tN - t0)), y = (v) => r1(128 - (112 * v) / M);
    const escalier = (v0, pts, val) => `M${x(t0)} ${y(v0)}${pts.map((p) => `H${x(jour(p.d))}V${y(val(p))}`).join('')}H${x(tN)}`;
    const per = y(M) + 4, clo = r1(Math.max(y(k) + 4, per + 14)); // « closes » : la plus basse, à 14 unités au moins de « périmètre »
    return {
      chemins: { clos: escalier(0, S, (p) => p.clos), perimetre: escalier(S[0].perimetre, S.slice(1), (p) => p.perimetre) },
      etiquettes: [{ x: 20, y: r1(y(0) + 4), texte: '0', ancre: 'end' }, { x: 20, y: r1(y(M) + 4), texte: String(M), ancre: 'end' },
        { x: 28, y: 142, texte: date(b.ouverture), ancre: 'start' }, { x: 236, y: 142, texte: date(iso(tN)), ancre: 'end' },
        { x: 244, y: r1(per), texte: `périmètre ${M}`, ancre: 'start' }, { x: 244, y: clo, texte: `closes ${k}`, ancre: 'start' }],
    };
  }
  const liste = (b) => b.serie.map((p) => ({ d: p.d, date: date(p.d),
    texte: `${date(p.d)} · périmètre ${p.perimetre} · closes ${p.clos}${p.closes.length ? ` : ${phases(p.closes)}` : ''}` }));
  function notes(b) {
    const c = b.closesSansDate || [], n = [], pl = (l) => l.length > 1;
    const closes = new Set([...c.map(num), ...b.serie.flatMap((p) => p.closes.map(num))]); // une phase close n'est pas « inscrite sans date »
    const i = (b.inscritesSansDate || []).filter((p) => !closes.has(num(p)));
    if (c.length) n.push(pl(c) ? `Closes, date non écrite : ${phases(c)}. Elles comptent dans le pourcentage, sans marche sur la courbe.`
      : `Close, date non écrite : ${phases(c)}. Elle compte dans le pourcentage, sans marche sur la courbe.`);
    if (i.length) {
      n.push(fin(`${pl(i) ? 'Inscrites' : 'Inscrite'} sans date : ${phases(i)}. ${pl(i) ? 'Comptées' : 'Comptée'} dès l'ouverture du jalon`
        + `${b.ouverture ? `, le ${date(b.ouverture)}` : ''}`));
    }
    return n;
  }
  function ariaLabel(b) {
    const S = b.serie, cl = S.filter((p) => p.closes.length), k = S.length ? S.at(-1).clos : 0;
    let t = `Burn-up du jalon ${b.jalon} : ${pluriel(b.clos, 'phase', 'close')} sur ${b.total}, ${b.pct} %.`;
    if (!S.length) return t;
    t += ` Périmètre de ${pluriel(S[0].perimetre, 'phase')} le ${date(S[0].d)} à ${pluriel(b.total, 'phase')} le ${date(S.at(-1).d)} ;`;
    if (!k || !cl.length) return `${t} aucune phase close datée.`;
    const quand = k > 1 ? `entre le ${date(cl[0].d)} et le ${date(cl.at(-1).d)}` : `le ${date(cl[0].d)}`;
    return fin(`${t} ${pluriel(k, 'phase', 'close')} datée${k > 1 ? 's' : ''} ${quand}`);
  }
  window.__vfSyntheseBurnup = Object.freeze({ tete, courbe, liste, notes, ariaLabel });

  // ---------- page ----------
  const el = (tag, attrs, texte, ns) => {
    const e = ns ? document.createElementNS(SVG, tag) : document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) e.setAttribute(k, v);
    if (texte !== undefined && texte !== null) e.textContent = texte;
    return e;
  };
  const auj = () => { const d = new Date(), p = (n) => String(n).padStart(2, '0'); return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`; };
  const feuille = () => {
    if (document.getElementById('vf-sy-burnup')) return;
    const st = document.createElement('style'); st.id = 'vf-sy-burnup';
    st.textContent = `.vf-sy p.vf-sy-tete { margin: 0; font-size: 12.5px; font-weight: 600; line-height: 1.4; color: var(--text);
        font-variant-numeric: tabular-nums; }
      .vf-sy p.vf-sy-note { margin: var(--sp-6) 0 0; font-size: 12.5px; line-height: 1.45; color: var(--text-3); }
      .vf-sy svg.vf-sy-courbe { display: block; width: 100%; height: auto; margin-top: var(--sp-12); }
      .vf-sy-courbe path { fill: none; } .vf-sy-courbe path[data-serie="clos"] { stroke: var(--text-3); stroke-width: 2; }
      .vf-sy-courbe path[data-serie="perimetre"] { stroke: var(--text-4); stroke-width: 1.5; stroke-dasharray: 4 4; }
      .vf-sy-courbe .vf-sy-base { stroke: var(--hair-2); stroke-width: 1; }
      .vf-sy-courbe text { font: 500 11px var(--sans); fill: var(--text-3); font-variant-numeric: tabular-nums; }
      .vf-sy ol.vf-sy-liste { list-style: none; margin: var(--sp-8) 0 0; padding: 0; font-size: 12.5px; font-weight: 500; line-height: 1.4;
        color: var(--text-2); font-variant-numeric: tabular-nums; }
      .vf-sy ol.vf-sy-liste li { margin: 0; padding: var(--sp-2) 0; }
      .vf-sy details.vf-tech > summary { font-size: 12.5px !important; }
      @media (pointer: coarse), (max-width: 999px) { .vf-sy details.vf-tech > summary { min-height: 44px; display: flex; align-items: center; } }`;
    document.head.appendChild(st);
  };

  let corpsCourant = null, ctxCourant = null, signe = '', phone = null;
  const SANS_COURBE = 'Courbe indisponible : aucune date écrite au ROADMAP.';
  const SANS_DATES = 'Burn-up indisponible : le cockpit n\'a pas reçu les dates du ROADMAP.';
  const mot = (texte) => el('p', { class: 'pd vf-sy-note' }, texte);
  function ol(L) {
    const o = el('ol', { class: 'vf-sy-liste' });
    for (const l of L) {
      const li = el('li'); li.append(el('time', { datetime: l.d }, l.date), document.createTextNode(l.texte.slice(l.date.length))); o.append(li);
    }
    return o;
  }
  function dessiner(bu) {
    const c = courbe(bu, auj()), aria = ariaLabel(bu);
    const svg = el('svg', { class: 'vf-sy-courbe', viewBox: '0 0 320 160', role: 'img', 'aria-label': aria, focusable: 'false' }, null, true);
    svg.append(el('line', { class: 'vf-sy-base', x1: 28, y1: 128, x2: 236, y2: 128 }, null, true));
    for (const k of ['perimetre', 'clos']) svg.append(el('path', { 'data-serie': k, d: c.chemins[k] }, null, true));
    for (const e of c.etiquettes) {
      svg.append(el('text', { x: e.x, y: e.y, 'text-anchor': e.ancre, ...(e.x === 244 ? { 'data-direct': '' } : {}) }, e.texte, true));
    }
    return svg;
  }
  const lireVf = (ctx) => { const g = ctx.graphe(); return (g && g.meta && g.meta.vf) || {}; };
  const signature = (V) => JSON.stringify([V.burnup || null, Array.isArray(V.milestones) ? V.milestones.length : null, phone]);
  function rendre(corps, ctx) {
    corpsCourant = corps; ctxCourant = ctx;
    const V = lireVf(ctx), bu = V.burnup, ms = Array.isArray(V.milestones) ? V.milestones : null;
    phone = !!(window.matchMedia && window.matchMedia('(max-width: 700px)').matches); signe = signature(V);
    corps.textContent = '';
    if (ms && (!ms.length || (!bu && ms.every((m) => m && m.st === 'done')))) { corps.append(mot('Aucun jalon en cours : pas de burn-up à tracer.')); return; }
    if (!bu || typeof bu !== 'object' || !Array.isArray(bu.serie)) { corps.append(mot(SANS_DATES)); return; }
    corps.append(el('p', { class: 'vf-sy-tete' }, tete(bu)),
      el('p', { class: 'pd vf-sy-note vf-sy-aide' }, `Phases closes du jalon ${bu.jalon}, sans pondération par les plans.`));
    if (bu.ouverture && bu.serie.length) {
      if (phone) corps.append(ol(liste(bu)));
      else { const d = el('details', { class: 'vf-tech' }); d.append(el('summary', {}, 'Liste datée'), ol(liste(bu))); corps.append(dessiner(bu), d); }
    } else corps.append(mot(SANS_COURBE)); // le décompte existe : seule la courbe manque de dates
    for (const n of notes(bu)) corps.append(el('p', { class: 'pd vf-sy-note', 'data-vf-sy-note': '' }, n));
  }
  function installer() {
    feuille();
    const mql = window.matchMedia ? window.matchMedia('(max-width: 700px)') : null, E = window.VF_ETAT;
    let minuterie = null, off = null;
    const refaire = () => { if (corpsCourant && corpsCourant.isConnected) rendre(corpsCourant, ctxCourant); };
    const change = () => { if (corpsCourant && corpsCourant.isConnected && signature(lireVf(ctxCourant)) !== signe) refaire(); };
    if (mql) mql.addEventListener('change', refaire);
    // le direct remplace meta.vf : le burn-up se redessine en place (jamais showPanel) quand ce qu'il montre a changé
    try {
      off = E && typeof E.abonner === 'function' ? E.abonner('graphe', () => { clearTimeout(minuterie); minuterie = setTimeout(change, 50); }) : null;
    } catch { off = null; }
    return () => { if (mql) mql.removeEventListener('change', refaire); clearTimeout(minuterie); if (off) off(); corpsCourant = null; ctxCourant = null; };
  }
  const R = (window.__vfSyntheseBlocs = window.__vfSyntheseBlocs || []);
  R.push(Object.freeze({ id: 'burnup', titre: 'Burn-up du jalon', installer, present: () => true, rendre, ouvrir: () => {} }));
})();
