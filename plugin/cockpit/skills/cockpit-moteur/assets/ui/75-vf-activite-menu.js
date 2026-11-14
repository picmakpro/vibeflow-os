// VibeFlow (75-08, ACTV-01, ACTV-07, ACTV-08) : le menu `#lens-menu` du sélecteur de lentilles (75-UI-SPEC § 1.2, § 1.3, § 8).
// Un volant posé comme `#legend`, enregistré dans la pile de surcouches (Échap, retour du focus). `role="menu"` sur le SEUL conteneur des rangées
// (`menuitemradio` dans les groupes « Lentille » et « Agents ») ; titre, légende et ligne du radar sont HORS du menu, reliés par `aria-describedby`.
// Inscription : VF_COQUILLE.surOnglet(..., { cle }) → window.VF_ACTIVITE.brancher('menu', creer) ; le nettoyage rendu défait tout ce qui est posé
// ici.
(() => {
  'use strict';
  const CLE = '75-vf-activite-menu.js', ID = 'vfa-menu-style', NS = 'http://www.w3.org/2000/svg';
  const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const CSS = `
    #lens-menu .lh { padding: var(--sp-8) var(--sp-12) var(--sp-6); font-size: 12px; color: var(--text-3); } /* dérivé : DESIGN § 3 */
    #lens-menu .lr { display: flex; align-items: center; gap: var(--sp-8); width: 100%; min-height: 44px; padding: var(--inset-row);
      border: 0; border-radius: 12px; background: none; color: var(--text); font: inherit; text-align: left; cursor: pointer; }
    #lens-menu .lr:hover, #lens-menu .lr[aria-checked="true"] { background: rgba(var(--ink), .07); }
    #lens-menu .lr[aria-disabled="true"] { color: var(--text-3); cursor: default; }
    #lens-menu .lr[aria-disabled="true"]:hover { background: none; }
    #lens-menu .lr:focus-visible, #lens-menu summary:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
    #lens-menu .lt { flex: 1; min-width: 0; }
    #lens-menu .lt b { display: block; font-weight: 500; font-size: 13.5px; } /* dérivé : DESIGN § 3 */
    #lens-menu .lt span { display: block; color: var(--text-3); font-size: 12px; } /* dérivé : DESIGN § 3 */
    #lens-menu .ln { margin-left: auto; color: var(--text-2); font-size: 11px; font-variant-numeric: tabular-nums; } /* dérivé : DESIGN § 3 */
    #lens-menu .lk { flex: none; width: var(--sp-16); height: var(--sp-16); fill: none; stroke: currentColor; stroke-width: 2;
      stroke-linecap: round; stroke-linejoin: round; }
    #lens-menu .lr:not([aria-checked="true"]) .lk { visibility: hidden; }
    #lens-menu .vh { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
    #lens-menu .sep { border-top: 1px solid var(--hair); margin-top: var(--sp-4); padding-top: var(--sp-4); }
    #lens-menu .ll { display: flex; align-items: center; gap: var(--sp-8); padding: var(--sp-4) var(--sp-12); color: var(--text-2);
      font-size: 12px; } /* dérivé : DESIGN § 3 */
    #lens-menu .ll .lg { font-size: 12px; } /* dérivé : le glyphe suit le texte (1,45 em) */
    #lens-menu summary { padding: var(--sp-8) var(--sp-12); color: var(--text-3); cursor: pointer; border-radius: 12px;
      font-size: 12px; } /* dérivé : DESIGN § 3 */
    #lens-menu .lradar { padding: var(--sp-4) var(--sp-12) var(--sp-8); margin: var(--sp-4) 0 0; color: var(--text-3);
      font-size: 12px; } /* dérivé : DESIGN § 3 */`;

  const creer = (ctx) => {
    const { T, M, S, bouton, racine } = ctx, TX = T.TEXTES;
    const menu = el('div', 'menu'), titre = el('div', 'lh', TX.titre), boite = el('div'), lentilles = el('div');
    const leg = el('div', 'sep'), radar = el('p', 'lradar');
    menu.id = 'lens-menu'; titre.id = 'lens-titre'; leg.id = 'lens-legende'; radar.id = 'lens-radar'; boite.id = 'lens-boite';
    boite.setAttribute('role', 'menu'); boite.setAttribute('aria-labelledby', 'lens-titre');
      boite.setAttribute('aria-describedby', 'lens-titre lens-legende lens-radar');
    lentilles.setAttribute('role', 'group'); lentilles.setAttribute('aria-label', TX.groupeLentille);
    leg.setAttribute('role', 'group'); leg.setAttribute('aria-label', TX.legende);
    const agents = el('details', 'ag'), grpAg = el('div'); agents.hidden = true;
    grpAg.setAttribute('role', 'group'); grpAg.setAttribute('aria-label', TX.groupeAgents);
    agents.append(el('summary', '', TX.groupeAgents), grpAg);
    boite.append(lentilles, agents); menu.append(titre, boite, leg, radar);
    racine.appendChild(menu);
    const st = el('style'); st.id = ID; st.textContent = CSS; document.head.appendChild(st);

    const rangee = (id) => {
      const b = el('button', 'lr'), t = el('span', 'lt');
      b.type = 'button'; b.setAttribute('role', 'menuitemradio'); b.dataset.id = id;
      t.append(el('b'), el('span')); b.append(coche(), t, el('span', 'ln'), el('span', 'vh'));
      return b;
    };
    const coche = () => {
      const s = document.createElementNS(NS, 'svg'), p = document.createElementNS(NS, 'path');
      s.setAttribute('viewBox', '0 0 24 24'); s.setAttribute('class', 'lk'); s.setAttribute('aria-hidden', 'true');
        p.setAttribute('d', 'M5 12.5l4.5 4.5L19 7.5'); s.appendChild(p);
      return s;
    };
    const rangs = () => [...menu.querySelectorAll('.lr')].filter((r) => r.offsetParent !== null);
    let ouvert = false;
    const maj = (m) => {
      const actifs = new Set(m.lignes.map((l) => l.id));
      for (const r of [...lentilles.children]) if (!actifs.has(r.dataset.id)) r.remove();
      m.lignes.forEach((l, i) => {
        let r = [...lentilles.children].find((x) => x.dataset.id === l.id);
        if (!r) { r = rangee(l.id); lentilles.insertBefore(r, lentilles.children[i] || null); }
        r.querySelector('b').textContent = l.nom; r.querySelector('.lt span').textContent = l.sous;
        const n = r.querySelector('.ln'), d = r.querySelector('.vh');
        n.textContent = l.compte === null || l.compte === undefined ? '' : String(l.compte); n.hidden = !n.textContent;
        r.setAttribute('aria-checked', String(l.coche));
        if (l.etat === 'ok') { r.removeAttribute('aria-disabled'); r.removeAttribute('aria-describedby'); d.textContent = ''; d.id = ''; } else {
          r.setAttribute('aria-disabled', 'true'); d.id = 'lens-d-' + l.id; r.setAttribute('aria-describedby', d.id);
          d.textContent = (l.description || [l.sous]).join('. ');
        }
      });
      const focus = document.activeElement && grpAg.contains(document.activeElement) ? document.activeElement.dataset.id : null;
      grpAg.replaceChildren();
      agents.hidden = m.agents.length === 0;
      for (const a of [{ id: '', nom: TX.toutes }, ...m.agents.map((x) => ({ id: x, nom: x }))]) {
        const r = rangee('ag:' + a.id); r.querySelector('b').textContent = a.nom; r.querySelector('.lt span').hidden = true;
        r.setAttribute('aria-checked', String((ctx.filtre() || '') === a.id)); r.dataset.agent = a.id; grpAg.appendChild(r);
        if (focus === r.dataset.id) r.focus();
      }
      const ligne = (g, t) => { const l = el('div', 'll'); if (g) { const i = el('i', 'lg lg-' + g); i.setAttribute('aria-hidden', 'true');
        l.appendChild(i); } l.appendChild(el('span', '', t)); return l; };
      leg.replaceChildren(...m.legende.map((x) => ligne(x.g, x.t)));
      if (m.limites.length) { const d = el('details', 'lim'); d.append(el('summary', '', TX.limites), ...m.limites.map((t) => ligne(null, t)));
        leg.appendChild(d); }
      radar.textContent = m.radar.ligne;
    };

    const ouvreur = () => (bouton.getClientRects().length ? bouton : document.getElementById('vf-plus') || bouton);
    const fermer = (rendre) => {
      if (!ouvert) return;
      ouvert = false; menu.classList.remove('open'); bouton.setAttribute('aria-expanded', 'false'); S && S.fermer(menu);
      window.removeEventListener('click', dehors);
      if (rendre) ouvreur().focus();
    };
    const dehors = (ev) => { if (!menu.contains(ev.target) && !bouton.contains(ev.target)) fermer(false); };
    const ouvrir = () => {
      if (ouvert) return;
      if (M.closeMenus) M.closeMenus(); // #legend, #flowmenu et le menu contextuel : hors de la pile, ils se ferment l'un l'autre
      ouvert = true; menu.classList.add('open'); bouton.setAttribute('aria-expanded', 'true');
      if (S) S.ouvrir(menu, { modale: false, ouvreur: ouvreur(), fermer: () => fermer(true) });
      window.addEventListener('click', dehors);
      (menu.querySelector('.lr[aria-checked="true"]') || rangs()[0]).focus();
    };
    const voisins = new MutationObserver(() => { if (document.querySelector('#legend.open, #flowmenu.open')) fermer(false); });
    for (const id of ['legend', 'flowmenu']) { const n = document.getElementById(id);
      if (n) voisins.observe(n, { attributes: true, attributeFilter: ['class'] }); }
    menu.addEventListener('click', (ev) => {
      ev.stopPropagation();
      const r = ev.target.closest('.lr');
      if (!r || r.getAttribute('aria-disabled') === 'true') return;
      if (r.dataset.agent !== undefined) { ctx.filtrer(r.dataset.agent || null); return; }
      ctx.choisir(r.dataset.id); fermer(true);
    });
    menu.addEventListener('keydown', (ev) => {
      const l = rangs(), i = l.indexOf(document.activeElement);
      if (ev.key === 'Escape') { ev.preventDefault(); ev.stopPropagation(); fermer(true); return; }
      const j = ev.key === 'ArrowDown' ? (i + 1) % l.length : ev.key === 'ArrowUp' ? (i - 1 + l.length) % l.length
        : ev.key === 'Home' ? 0 : ev.key === 'End' ? l.length - 1 : -1;
      if (j < 0 || !l.length) return;
      ev.preventDefault(); ev.stopPropagation(); l[j].focus();
    });
    return { maj, ouvrir, fermer, basculer: () => (ouvert ? fermer(true) : ouvrir()), ouvert: () => ouvert, el: menu,
      detruire: () => { fermer(false); voisins.disconnect(); menu.remove(); st.remove(); } };
  };

  const arrivee = (ev) => {
    const H = window.VF_ACTIVITE;
    return !ev || ev.onglet !== 'code' || !H ? () => {} : H.brancher('menu', creer);
  };
  if (window.VF_COQUILLE && typeof window.VF_COQUILLE.surOnglet === 'function') window.VF_COQUILLE.surOnglet(arrivee, { cle: CLE });
})();
