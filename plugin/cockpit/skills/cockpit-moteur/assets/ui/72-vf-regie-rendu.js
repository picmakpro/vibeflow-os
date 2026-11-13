// VibeFlow (73-05) : rendu de la régie (onglet Équipe) : en-tête, bascule de vues, sections, lignes mises à jour en place, focus, annonce, recherche.
// Pur DOM : createElement et textContent seuls, jamais de HTML construit (le modèle rend des chaînes brutes). Une ligne est un li gardé par sa clé ;
// une mise à jour n'écrit que ce qui change. Pose window.__vfRegieRendu = { monter(racine) } ; monter rend l'objet qui sert la source.
(() => {
  const D = document, SVG = 'http://www.w3.org/2000/svg', NB = ' ';
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt) e.textContent = txt; return e; };
  const ecrire = (e, t) => { if (e.textContent !== t) e.textContent = t; };
  const attr = (e, k, v) => { if (e.getAttribute(k) !== v) e.setAttribute(k, v); };
  const classe = (e, c) => { if (e.className !== c) e.className = c; };
  const cacher = (e, oui) => { if (e.hasAttribute('hidden') !== oui) e.hidden = oui; };
  const norme = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
  // glyphe d'état : le tracé de 71-vf-equipe-rendu.js (constante du dépôt), reposé en nœuds SVG, jamais en HTML
  const glyphe = (nom, cls) => {
    const src = window.__vfEquipeRendu.glyphe(nom, cls), svg = D.createElementNS(SVG, 'svg');
    const att = (e, s) => { for (const m of s.matchAll(/([\w-]+)="([^"]*)"/g)) e.setAttribute(m[1], m[2]); };
    att(svg, src.slice(0, src.indexOf('>')));
    for (const m of src.matchAll(/<(circle|path)\s([^>]*?)\/>/g)) { const n = D.createElementNS(SVG, m[1]); att(n, m[2]); svg.appendChild(n); }
    return svg;
  };

  function monter(racine) {
    let seq = 0; const cache = new Map(), secs = new Map(), ouverts = new Set(); let avous = null;
    const entete = h('div'), h1 = h('h1'), sous = h('p', 'vf-rg-sous'), verrou = h('p', 'vf-rg-verrou'), live = h('div');
    entete.id = 'vf-equipe-entete'; entete.append(h1, sous, verrou); cacher(verrou, true);
    live.setAttribute('role', 'status'); live.setAttribute('aria-live', 'polite'); live.className = 'vf-rg-live';
    live.style.cssText = 'position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap';
    const vues = new Map(), fin = () => racine.querySelector('.vf-rg-piedzone');
    const vue = (id) => {
      if (!vues.has(id)) { const v = h('div', 'vf-vue'); v.setAttribute('data-vf-vue', id); racine.insertBefore(v, fin()); vues.set(id, v); }
      return vues.get(id);
    };
    racine.append(entete, live);
    const regie = vue('regie'), corps = h('div', 'vf-rg-sections'), note = h('p', 'vf-rg-note');
    note.textContent = "Aucun agent ne correspond. Effacez la recherche pour revoir toute l'équipe."; cacher(note, true);
    regie.append(corps, note);

    // ---------- une ligne ----------
    const creerLigne = (l) => {
      const li = h('li'), row = h('div', 'vf-rg-row'), qui = h('div', 'vf-rg-qui'), quoi = h('div', 'vf-rg-quoi');
      const dur = h('div', 'vf-rg-dur'), act = h('div', 'vf-rg-act');
      const r = li._r = { row, qui, act, nom: h('span', 'vf-rg-nom'), role: h('span', 'vf-rg-role'), mot: h('span', 'vf-rg-mot'), det: h('span', 'vf-rg-det'),
        l2: h('div', 'vf-rg-l2'), di: h('i'), dv: h('span'), id: 'vf-rg-n-' + (++seq) };
      li.setAttribute('data-vf-cle', ''); r.nom.id = r.id;
      qui.append(r.nom, r.role); quoi.append(r.mot, r.det, r.l2); dur.append(r.di, r.dv); row.append(qui, quoi, dur, act); li.append(row);
      return li;
    };
    const tog = (li) => {
      const r = li._r, b = h('button', 'vf-rg-tog');
      b.setAttribute('type', 'button'); b.setAttribute('aria-expanded', 'false'); b.setAttribute('aria-labelledby', r.id); b.append(glyphe('repli', 'r-caret'));
      r.qui.insertBefore(b, r.nom); return b;
    };
    const plus = (li, l, ouvert) => {
      if (!ouvert) { if (li._p) { li._p.remove(); li._p = null; } return; }
      const t = [`Identifiant${NB}: ${String(l.id).slice(0, 8)}`, ...l.ligne2], k = t.join('\n') + l.lien;
      if (!li._p) { li._p = h('div', 'vf-rg-plus'); li.append(li._p); }
      if (li._p._k === k) return;
      li._p._k = k; li._p.replaceChildren(...t.map((x) => h('p', 'vf-rg-l2', x)));
      if (l.lien) { const a = h('a', 'vf-link', 'Nœud' + (l.attrs.noeud ? NB + l.attrs.noeud : '')); a.setAttribute('href', l.lien); li._p.append(a); }
    };
    const mission = (li, l) => {
      const r = li._r, k = l.nom + '|' + l.marques.map((m) => m.texte).join('|');
      if (!r.m) { r.m = h('div', 'vf-rg-mission'); li.replaceChildren(r.m); }
      if (r.m._k === k) return; r.m._k = k;
      const marque = (m) => { const s = h('span', 'vf-rg-marque'); s.append(glyphe('surveiller'), m.texte); return s; };
      r.m.replaceChildren(h('span', 'vf-rg-nom', l.nom), ...l.marques.map(marque));
    };
    const majLigne = (li, l) => {
      const r = li._r; li._ln = l; attr(li, 'data-vf-cle', l.cle);
      attr(li, 'data-vf-agent', l.attrs.agent); attr(li, 'data-vf-noeud', l.attrs.noeud); attr(li, 'data-vf-etat', l.attrs.etat);
      classe(li, ['vf-rg-lig', l.niveau ? 'vf-rg-n' + l.niveau : '', l.grise ? 'vf-rg-grise' : '', l.kind === 'session' ? 'vf-rg-sess' : '',
        l.poids >= 600 ? 'vf-rg-fort' : ''].filter(Boolean).join(' '));
      if (l.kind === 'mission') { mission(li, l); return; }
      if (li._g !== l.etat) {
        const g = glyphe(l.etat || 'repos', l.etat === 'actif' ? 'aw-pulse' : '');
        if (li._gn) li._gn.remove();
        r.row.prepend(g); li._gn = g; li._g = l.etat;
      }
      const agent = l.kind === 'session' || l.kind === 'subagent', ouvert = agent && ouverts.has(l.cle);
      if (agent && !li._t) li._t = tog(li);
      if (li._t) attr(li._t, 'aria-expanded', ouvert ? 'true' : 'false');
      ecrire(r.nom, l.nom); ecrire(r.role, l.role); ecrire(r.mot, l.mot); ecrire(r.det, l.detail); ecrire(r.l2, l.ligne2.join(' · '));
      if (l.infobulle) attr(r.det, 'title', l.infobulle); else if (r.det.hasAttribute('title')) r.det.removeAttribute('title');
      ecrire(r.di, l.duree.prefixe ? l.duree.prefixe + ' ' : ''); ecrire(r.dv, l.duree.valeur);
      if (l.action === 'lire-rapport' && !li._b) {
        const b = li._b = h('button', 'btn', 'Lire le rapport'); b.id = r.id + '-b'; b.setAttribute('type', 'button');
        b.setAttribute('aria-labelledby', `${b.id} ${r.id}`); r.act.append(b);
      } else if (l.action !== 'lire-rapport' && li._b) { li._b.remove(); li._b = null; }
      if (l.kind === 'phase' && l.lien && !li._a) { li._a = h('a', 'vf-link', 'Carte de la phase'); li._a.setAttribute('href', l.lien); r.act.append(li._a); }
      plus(li, l, ouvert);
    };
    const synchro = (ul, lis) => {
      lis.forEach((li, i) => { if (ul.childNodes[i] !== li) ul.insertBefore(li, ul.childNodes[i] || null); });
      while (ul.childNodes.length > lis.length) ul.removeChild(ul.childNodes[ul.childNodes.length - 1]);
    };

    // ---------- une section ----------
    const creerSec = (id) => {
      const sec = h('section'), h2 = h('h2'), tete = h('div', 'vf-rg-tete'), r = { h2, compte: h('span', 'vf-rg-compte'), aide: h('p', 'vf-rg-aide'),
        ul: h('ul', 'vf-rg-corps'), vide: h('p', 'vf-rg-vide'), pied: h('p', 'vf-rg-pied'), det: h('details', 'vf-rg-relus'), sm: h('summary'),
        ulr: h('ul', 'vf-rg-corps') };
      sec.setAttribute('data-vf-section', id); h2.id = 'vf-rg-h-' + id; h2.tabIndex = -1; sec.setAttribute('aria-labelledby', h2.id);
      tete.append(h2, r.compte, r.aide); r.det.append(r.sm, r.ulr); sec.append(tete, r.ul, r.vide, r.pied, r.det); corps.append(sec); r.sec = sec;
      return r;
    };
    const rendre = (m, o = {}) => {
      const a = D.activeElement, dedans = a && a.closest && a.closest('li[data-vf-cle]');
      const garde = dedans && racine.contains(dedans) ? { el: a, cle: dedans.getAttribute('data-vf-cle') } : null;
      ecrire(h1, m.entete.h1); ecrire(sous, m.entete.sousTitre);
      const vd = m.entete.verrouDepot; ecrire(verrou, vd ? [vd.texte, ...vd.marques.map((x) => x.texte)].join(' · ') : ''); cacher(verrou, !vd);
      cacher(corps, o.sections === false);
      const vus = new Set(), ligne = (l) => {
        let li = cache.get(l.cle); if (!li) { li = creerLigne(l); cache.set(l.cle, li); }
        majLigne(li, l); vus.add(l.cle); return li;
      };
      for (const s of m.sections) {
        const r = secs.get(s.id) || (secs.set(s.id, creerSec(s.id)), secs.get(s.id));
        classe(r.sec, 'vf-rg-sec' + (s.id === 'a-vous' ? ' vf-rg-sec-avous' : ''));
        ecrire(r.h2, s.titre); ecrire(r.compte, String(s.compte)); ecrire(r.aide, s.aide);
        synchro(r.ul, s.lignes.map(ligne)); ecrire(r.vide, s.vide); cacher(r.vide, s.lignes.length > 0);
        ecrire(r.pied, [s.pied, s.autresTexte].filter(Boolean).join(' ')); cacher(r.pied, !r.pied.textContent);
        ecrire(r.sm, s.relusTitre); synchro(r.ulr, s.relus.map(ligne)); cacher(r.det, s.relus.length === 0);
      }
      for (const [k, li] of cache) if (!vus.has(k)) { li.remove(); cache.delete(k); ouverts.delete(k); }
      const n = m.sections[0].compte;
      if (avous !== null && n > avous) ecrire(live, `${n} ${n > 1 ? 'vous attendent' : 'vous attend'}`);
      avous = n;
      // P73-D-29 : le focus suit sa ligne ; si elle disparaît, il va au titre de sa section, jamais à une jumelle
      if (garde && D.activeElement !== garde.el) {
        const li = cache.get(garde.cle);
        if (garde.el.isConnected) garde.el.focus({ preventScroll: true });
        else if (li && (li._t || li._b)) (li._t || li._b).focus({ preventScroll: true });
        else if (secs.has(garde.cle.split(':')[0])) secs.get(garde.cle.split(':')[0]).h2.focus({ preventScroll: true });
      }
    };

    // ---------- recherche, détail en flux, bascule ----------
    const filtrer = (q) => {
      q = norme(q).trim(); let total = 0;
      for (const [cle, li] of cache) {
        const ok = !q || norme((li._ln ? li._ln.nom : '') + ' ' + (li._r.role ? li._r.role.textContent : '')).includes(q);
        cacher(li, !ok); if (ok) total++;
      }
      for (const [, r] of secs) cacher(r.sec, !!q && ![...r.sec.querySelectorAll('li[data-vf-cle]')].some((li) => !li.hasAttribute('hidden')));
      cacher(note, !(q && total === 0));
    };
    const premiere = () => { for (const li of racine.querySelectorAll('li[data-vf-cle]')) if (!li.hasAttribute('hidden') && li._t) return li; return null; };
    const basculer = (cle, oui) => {
      const li = cache.get(cle); if (!li || !li._ln) return null;
      if (oui) ouverts.add(cle); else ouverts.delete(cle);
      majLigne(li, li._ln); return li;
    };
    const tabs = new Map(); let tl = null;
    const bascule = (liste, choisie, surChoix) => {
      if (liste.length < 2) { if (tl) { tl.remove(); tl = null; tabs.clear(); } } else {
        if (!tl) { tl = h('div', 'vf-rg-bascule'); tl.setAttribute('role', 'tablist'); tl.setAttribute('aria-label', "Vue de l'équipe"); entete.append(tl); }
        for (const v of liste) {
          if (!tabs.has(v.id)) {
            const b = h('button', 'btn'); b.setAttribute('role', 'tab'); b.setAttribute('type', 'button');
            b.addEventListener('click', () => surChoix(v.id)); tl.append(b); tabs.set(v.id, b);
          }
          ecrire(tabs.get(v.id), v.libelle); attr(tabs.get(v.id), 'aria-selected', v.id === choisie ? 'true' : 'false');
        }
      }
      for (const v of liste) { const c = vue(v.id); cacher(c, v.id !== choisie); }
    };
    return { rendre, filtrer, premiere, basculer, bascule, vue, entete,
      ligne: (cle) => cache.get(cle) || null, lignes: (id) => [...cache.values()].filter((li) => li._ln && (li.getAttribute('data-vf-agent') === id)),
      ouverte: (li) => (li && li._p ? li._p : null), titre: (id) => (secs.has(id) ? secs.get(id).h2 : null), deplie: () => [...ouverts] };
  }
  window.__vfRegieRendu = { monter };
})();
