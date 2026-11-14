// VibeFlow (73-11) : rendu des questions en attente des cadrages dans « À vous » (P73-D-37) : ligne de question, replis
// « Décisions prises pour vous, contestables (N) » et « À vérifier (N) », signalements, bilan, message d'absence, Échap des replis.
// Pur DOM : createElement et textContent seuls, jamais de HTML construit ; tout texte du disque est posé en textContent dans un élément
// de classe .rp ou .mono. Aucun bouton, aucune action. Complète window.__vfRegieQuestions { noeud, maj, pied, monter }.
(() => {
  const D = document, SVG = 'http://www.w3.org/2000/svg', NB = '\xa0';
  const poser = (e, t) => { if (e.textContent !== t) e.textContent = t; }; // garde:q-texte
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt) poser(e, txt); return e; };
  const attr = (e, k, v) => { if (e.getAttribute(k) !== v) e.setAttribute(k, v); };
  const cacher = (e, oui) => { if (e.hasAttribute('hidden') !== oui) e.hidden = oui; };
  // 00-vibeflow.js annule le clic de tout élément sous [data-vf-section] (ancre du viewer) : un lien ou un résumé de repli n'agirait pas ;
  // le clic s'arrête donc ici, sans preventDefault
  const garder = (e) => e.addEventListener('click', (ev) => ev.stopPropagation());
  const tampon = []; // les replis ouverts de cette source, le plus récent en dernier (posé par l'événement toggle)
  const ouvert = (d) => d.open === true || d.hasAttribute('open');
  const suivre = (d) => { const i = tampon.indexOf(d); if (i >= 0) tampon.splice(i, 1); if (ouvert(d)) tampon.push(d); };
  // glyphe d'état : le tracé de 71-vf-equipe-rendu.js, reposé en nœuds SVG, jamais en HTML
  const glyphe = (nom) => {
    const src = window.__vfEquipeRendu.glyphe(nom, ''), svg = D.createElementNS(SVG, 'svg');
    const att = (e, s) => { for (const m of s.matchAll(/([\w-]+)="([^"]*)"/g)) e.setAttribute(m[1], m[2]); };
    att(svg, src.slice(0, src.indexOf('>')));
    for (const m of src.matchAll(/<(circle|path)\s([^>]*?)\/>/g)) { const n = D.createElementNS(SVG, m[1]); att(n, m[2]); svg.appendChild(n); }
    return svg;
  };
  // le lien de phase : une ancre au style de lien existant quand la carte existe, sinon le seul texte
  const phase = (p, lien, texte) => {
    if (lien) {
      if (!p._lien) { p._lien = h('a', 'vf-link'); p.replaceChildren(p._lien); }
      poser(p._lien, texte); attr(p._lien, 'href', lien);
    } else { p._lien = null; poser(p, texte); }
  };

  // ---------- une ligne de question ----------
  function noeud() {
    const li = D.createElement('li'), row = h('div', 'vf-rg-row vf-rg-q-row'), corps = h('div', 'vf-rg-q-corps'), tete = h('p', 'vf-rg-q-tete');
    const r = li._q = { id: h('span', 'vf-rg-q-id mono rp'), nom: h('span', 'vf-rg-nom rp'), q: h('p', 'vf-rg-q-q rp'), opts: h('ul', 'vf-rg-q-opts'),
      reco: h('p', 'vf-rg-q-aucune'), bloque: h('p', 'vf-rg-q-bloque rp'), phase: h('p', 'vf-rg-q-phase'), sig: null };
    garder(li); li._r = { role: r.id }; // la recherche lit le nom et l'identifiant visibles
    tete.append(r.id, r.nom); corps.append(tete, r.q, r.opts, r.reco, r.bloque, r.phase); row.append(glyphe('attend'), corps); li.append(row);
    return li;
  }
  function maj(li, l) {
    const r = li._q; li._ln = l;
    attr(li, 'data-vf-cle', l.cle); attr(li, 'data-vf-question', l.attrs.question); attr(li, 'data-vf-etat', l.attrs.etat);
    attr(li, 'class', 'vf-rg-lig vf-rg-q');
    if (r.sig === l.sig) return;
    r.sig = l.sig; poser(r.id, l.id); poser(r.nom, l.nom); poser(r.q, l.question);
    r.opts.replaceChildren(...l.options.map((o) => {
      const it = h('li', 'vf-rg-q-opt'); it.append(h('span', 'rp', `(${o.cle}) ${o.texte}`));
      if (o.recommandee) it.append(h('span', 'vf-rg-q-reco', ' recommandée'));
      return it;
    }));
    poser(r.reco, l.recommandation === null ? 'Aucune recommandation.' : ''); cacher(r.reco, l.recommandation !== null);
    poser(r.bloque, l.bloque.length ? `bloque${NB}: ${l.bloque.join(', ')}` : ''); cacher(r.bloque, !l.bloque.length);
    phase(r.phase, l.lien, l.lienTexte);
  }

  // ---------- le pied de « À vous » : message, replis, signalements, bilan ----------
  const entree = (li, it) => {
    const k = JSON.stringify(it); if (li._k === k) return; li._k = k;
    const p = (cls, t) => h('p', cls, t), ph = h('p', 'vf-rg-q-phase');
    const noms = [p('vf-rg-q-id mono rp', it.id), p('rp', it.question)];
    if (it.option) noms.push(p('rp', it.option), p('mono rp', it.decision)); // une décision appliquée
    else noms.push(p('mono rp', it.lieu), p('vf-rg-q-def', it.defauts)); // une entrée à vérifier
    if (it.lienTexte) phase(ph, it.lien, it.lienTexte);
    li.replaceChildren(...noms.filter((x) => x.textContent), ...(it.lienTexte ? [ph] : []));
  };
  const repli = (p, id, titre, items) => {
    if (!items.length) { if (p[id]) { p[id].d.remove(); p[id] = null; } return null; }
    if (!p[id]) {
      const d = h('details', 'vf-rg-relus vf-rg-q-repli'), sm = h('summary'), ul = h('ul', 'vf-rg-q-liste');
      d.setAttribute('data-vf-repli', id); d.append(sm, ul); d.addEventListener('toggle', () => suivre(d)); p[id] = { d, sm, ul, lis: new Map() };
    }
    const r = p[id], vus = new Set(items.map((it) => it.cle));
    poser(r.sm, `${titre} (${items.length})`);
    for (const [k, li] of r.lis) if (!vus.has(k)) { li.remove(); r.lis.delete(k); }
    items.forEach((it, i) => {
      let li = r.lis.get(it.cle);
      if (!li) { li = h('li', 'vf-rg-q-item'); attr(li, 'data-vf-cle', it.cle); r.lis.set(it.cle, li); }
      entree(li, it);
      if (r.ul.childNodes[i] !== li) r.ul.insertBefore(li, r.ul.childNodes[i] || null);
    });
    return r.d;
  };
  function pied(sec, b) {
    const a = D.activeElement;
    let z = sec.querySelector('[data-vf-qpied]');
    if (!z) { z = h('div', 'vf-rg-qpied'); z.setAttribute('data-vf-qpied', ''); garder(z);
      z._p = { msg: h('p', 'vf-rg-qmsg'), bilan: h('p', 'vf-rg-qbilan'), tr: h('p', 'vf-rg-qtronque'), sg: [] }; sec.append(z);
    }
    const p = z._p, dedans = a && z.contains(a);
    poser(p.msg, b.message); cacher(p.msg, !b.message); poser(p.bilan, b.bilan); cacher(p.bilan, !b.bilan); poser(p.tr, b.tronque); cacher(p.tr, !b.tronque);
    while (p.sg.length < b.signalements.length) p.sg.push(h('p', 'vf-rg-qsig rp'));
    while (p.sg.length > b.signalements.length) p.sg.pop().remove();
    b.signalements.forEach((t, i) => poser(p.sg[i], t));
    const ordre = [p.msg, repli(p, 'decisions', 'Décisions prises pour vous, contestables', b.decisions),
      repli(p, 'a-verifier', 'À vérifier', b.aVerifier), ...p.sg, p.bilan, p.tr];
    ordre.filter(Boolean).forEach((n, i) => { if (z.childNodes[i] !== n) z.insertBefore(n, z.childNodes[i] || null); });
    while (z.childNodes.length > ordre.filter(Boolean).length) z.removeChild(z.childNodes[z.childNodes.length - 1]);
    // P73-D-29 : le focus qui était dans le pied et qui disparaît va au titre de la section, jamais à une jumelle
    if (dedans && !a.isConnected) { const t = sec.querySelector('h2'); if (t) t.focus({ preventScroll: true }); }
  }

  // ---------- montage : feuille propre et Échap ----------
  const STYLE = `
    body.vf-regie-montee .vf-rg-q-row { display: grid; grid-template-columns: 16px minmax(0, 1fr); column-gap: var(--sp-12);
      align-items: start; box-sizing: border-box;
      padding: var(--inset-row); border-radius: var(--r-ctl); }
    body.vf-regie-montee .vf-rg-q-corps { min-width: 0; display: flex; flex-direction: column; gap: var(--sp-4); }
    body.vf-regie-montee .vf-rg-q-corps p, body.vf-regie-montee .vf-rg-q-opts, body.vf-regie-montee .vf-rg-q-opt {
      margin: 0; padding: 0; list-style: none; font-size: 12px;
      line-height: 16px; color: var(--text-3); overflow-wrap: anywhere; }
    body.vf-regie-montee .vf-rg-q-corps .vf-rg-q-tete { font-size: 13px; line-height: 20px; color: var(--text); }
    body.vf-regie-montee .vf-rg-q-id { margin-right: var(--sp-6); font: 500 12px/16px var(--mono, monospace); color: var(--text-2); }
    body.vf-regie-montee .vf-rg-q-opts, body.vf-regie-montee .vf-rg-q-reco { color: var(--text-2); }
    body.vf-regie-montee .vf-rg-q-reco { font-weight: 600; }
    body.vf-regie-montee .vf-rg-qpied { min-width: 0; margin: var(--sp-8) 0 0; }
    body.vf-regie-montee .vf-rg-qpied p, body.vf-regie-montee .vf-rg-q-item { margin: var(--sp-4) 0 0; font-size: 12px; line-height: 16px; color: var(--text-3);
      overflow-wrap: anywhere; }
    body.vf-regie-montee .vf-rg-q-repli { margin: var(--sp-4) 0 0; min-width: 0; }
    body.vf-regie-montee .vf-rg-q-repli summary { min-height: 24px; font-size: 12px; line-height: 16px; color: var(--text-2); cursor: pointer; }
    body.vf-regie-montee .vf-rg-q-liste { margin: var(--sp-4) 0 0; padding: 0 0 0 var(--sp-16); list-style: none; }
    body.vf-regie-montee .vf-rg-q-item { padding: var(--sp-4) 0; }
    body.vf-regie-montee .vf-rg-q-item + .vf-rg-q-item { border-top: 1px solid var(--hair); }
    body.vf-regie-montee .vf-rg-q-repli summary:focus-visible, body.vf-regie-montee .vf-rg-q-corps a:focus-visible,
    body.vf-regie-montee .vf-rg-q-item a:focus-visible {
      outline: 2px solid var(--ring); outline-offset: 2px; border-radius: 8px; }
    @media (pointer: coarse) {
      body.vf-regie-montee .vf-rg-q-repli summary, body.vf-regie-montee .vf-rg-q-phase a { min-height: 44px; display: inline-flex; align-items: center; }
    }
  `;
  function monter() {
    if (D.head && !D.head.querySelector('style[data-vf-regie-questions]')) {
      const st = D.createElement('style'); st.setAttribute('data-vf-regie-questions', ''); st.textContent = STYLE; D.head.appendChild(st);
    }
    tampon.length = 0;
    // P73-D-33 : écouté en remontée sur document ; un appui déjà pris (surcouche, détail en flux) est ignoré ; rien à replier : ni appui pris ni focus déplacé
    const surEchap = (e) => {
      if (e.defaultPrevented) return; // garde:q-echap-prevenu
      const t = e.target;
      const racine = e.key === 'Escape' && t && t.closest ? t.closest('section#vf-equipe') : null;
      if (!racine) return;
      // l'événement toggle arrive après coup : un repli ouvert à l'instant se retrouve aussi dans le DOM
      const d = tampon.slice().reverse().find((x) => x.isConnected && ouvert(x)) || [...racine.querySelectorAll('details[data-vf-repli]')].reverse().find(ouvert);
      if (!d) return; // garde:q-echap-rien
      d.open = false; d.removeAttribute('open'); suivre(d);
      const s = d.querySelector('summary'); if (s) s.focus({ preventScroll: true });
      e.preventDefault();
    };
    D.addEventListener('keydown', surEchap);
    return () => { D.removeEventListener('keydown', surEchap); tampon.length = 0; };
  }

  window.__vfRegieQuestions = Object.assign(window.__vfRegieQuestions || {}, { noeud, maj, pied, monter });
})();
