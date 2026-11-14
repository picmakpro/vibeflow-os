// VibeFlow (80-05) : la ligne d'état du coin bas-droit (FORM-12, P80-D-18, P80-D-26) : la branche entière (ellipse au milieu, nom complet en title
// et en étiquette), « Direct » ou « Direct coupé » (seule rangée role=status), « Mis à jour à HH:MM ». Aucune requête : la branche est celle de
// l'en-tête Git (76-vf-git-entete.js), le direct celui du badge « au travail » (70-vf-live.js). Rien du terminal (P71-D-02) ni la dernière commande
// (P67-D-14). Texte posé par textContent seulement.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const t = window.__vfFrT;
  const style = document.createElement('style');
  style.textContent = `
    .vf-ls { display: flex; flex-direction: column; font-size: 11px; line-height: 16px; }
    .vf-ls > div { display: flex; align-items: center; gap: var(--sp-4); min-height: 16px; white-space: nowrap; overflow: hidden; }
    .vf-ls [hidden] { display: none; }
    .vf-ls-br { font-family: var(--mono); font-weight: 500; color: var(--text-2); }
    .vf-ls-br svg { width: 16px; height: 16px; flex: none; }
    .vf-ls-nom { flex: 1; min-width: 0; overflow: hidden; }
    .vf-ls-dr { font-weight: 500; color: var(--text-2); }
    .vf-ls-g { flex: none; width: 8px; height: 8px; margin: 0 var(--sp-4); border-radius: 999px; background: var(--st-done); }
    .vf-ls-g.coupe { background: none; box-shadow: inset 0 0 0 1.5px var(--text-4); }
    .vf-ls-sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
    .vf-ls-hc { display: none; font-weight: 400; font-variant-numeric: tabular-nums; color: var(--text-3); }
    .vf-ls-hr { font-weight: 400; font-variant-numeric: tabular-nums; color: var(--text-3); }
    .vf-ls-hr.coupe { white-space: normal; }
    #vf-coin[data-compact] .vf-ls-hr { display: none; } #vf-coin[data-compact] .vf-ls-hc { display: inline; }
  `;

  const NS = 'http://www.w3.org/2000/svg';
  const div = (c, txt) => { const d = document.createElement('div'); d.className = c; if (txt !== undefined) d.textContent = txt; return d; };
  const span = () => document.createElement('span');
  const br = div('vf-ls-br'), nom = span(), dr = div('vf-ls-dr'), mot = span(), hc = span();
  const hr = div('vf-ls-hr'), glyphe = span(), sr = span(), ls = div('vf-ls');
  { const ic = document.createElementNS(NS, 'svg'), tr = document.createElementNS(NS, 'path'); // glyphe branche, comme l'ouvreur Git
    ic.setAttribute('class', 'i'); ic.setAttribute('viewBox', '0 0 24 24'); ic.setAttribute('aria-hidden', 'true');
    tr.setAttribute('d', 'M6 5v14M18 8c0 5-12 3-12 9'); ic.appendChild(tr); br.appendChild(ic); }
  nom.className = 'vf-ls-nom'; br.appendChild(nom); br.setAttribute('role', 'img');
  glyphe.className = 'vf-ls-g'; glyphe.setAttribute('aria-hidden', 'true'); hc.className = 'vf-ls-hc'; hc.setAttribute('aria-hidden', 'true');
  sr.className = 'vf-ls-sr'; dr.setAttribute('role', 'status'); dr.append(glyphe, mot, sr, hc); ls.append(br, dr, hr);

  const SUITE_COUPE = 'Reprise automatique ; si elle échoue, rechargez la page.';
  let branche = '', rendu = '', majA = new Date(), patches = -1, vivant = false;
  const heure = (d) => `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  const sonde = () => window.__vfLive || null;
  const lireBranche = () => { // la ligne de l'en-tête Git, déjà lue, jamais redemandée au serveur
    const l = document.getElementById('vf-git-ligne'), b = l && !l.hidden ? l.querySelector('.vf-git-branche') : null;
    return b ? b.textContent.replace(/^○ /, '').trim() : '';
  };
  const lireDirect = () => { // 'on' | 'off' | null (pas de serveur, ou pas encore de nouvelles)
    const p = sonde(), lock = document.getElementById('vf-lock');
    if (!p || !window.FLOORPLAN_SERVER) return null;
    if (lock && lock.classList.contains('off')) return 'off';
    return p.connected ? 'on' : null;
  };
  const coupe = (nomEntier) => { // ellipse au milieu : début 10 caractères, « … », fin 8, seulement si le nom entier ne tient pas dans la largeur mesurée
    nom.textContent = nomEntier;
    if (nom.scrollWidth > nom.clientWidth && nomEntier.length > 19) nom.textContent = `${nomEntier.slice(0, 10)}…${nomEntier.slice(-8)}`;
  };
  const rendre = () => {
    if (!vivant) return;
    const b = lireBranche(), d = lireDirect(), h = heure(majA), cle = [b, d, h, nom.clientWidth].join('|');
    if (cle === rendu) return;
    rendu = cle; br.hidden = !b; dr.hidden = hr.hidden = !d;
    if (b !== branche || !nom.textContent) { branche = b; coupe(b); br.title = b; br.setAttribute('aria-label', t('Branch {}', b)); } else coupe(b);
    if (d) {
      const off = d === 'off';
      mot.textContent = off ? t('Live off') : t('Live'); glyphe.classList.toggle('coupe', off);
      dr.title = off ? `${t('Live off')}. ${SUITE_COUPE}` : t('Live'); sr.textContent = off ? `. ${SUITE_COUPE}` : '';
      hc.textContent = ` · ${h}`; hr.classList.toggle('coupe', off);
      hr.textContent = off ? `Reprise en cours, mise à jour à ${h}` : `Mis à jour à ${h}`;
    }
    slot().hidden = br.hidden && dr.hidden;
  };
  const slot = () => document.getElementById('vf-coin-etat');

  const pose = [];
  const init = () => {
    const s = slot(); if (!s) return undefined;
    vivant = true; document.head.appendChild(style); const p = sonde(); majA = p && p.whoAt ? new Date(p.whoAt) : new Date(); patches = p ? p.patches : -1;
    s.appendChild(ls);
    const sur = (cible, type, fn) => { cible.addEventListener(type, fn); pose.push(() => cible.removeEventListener(type, fn)); };
    const observer = (O, cible, opts, fn) => { const o = new O(fn); o.observe(cible, opts); pose.push(() => o.disconnect()); };
    const o = { childList: true, subtree: true, attributes: true, attributeFilter: ['hidden', 'class'], characterData: true };
    for (const q of ['header', '#vf-git-ligne']) { const e = document.querySelector(q); if (e) observer(MutationObserver, e, o, rendre); }
    if (window.ResizeObserver) observer(ResizeObserver, nom, undefined, rendre);
    sur(document, 'vf-who', () => { majA = new Date(); rendre(); }); // l'événement du direct reçu par la page (avant l'événement `graphe` de la Phase 79)
    SC.on('render', () => { const q = sonde(); if (q && q.patches !== patches) { patches = q.patches; majA = new Date(); } rendre(); });
    rendre();
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); ls.remove(); style.remove(); };
  };
  const K = window.VF_COQUILLE, demarrer = () => (vivant ? undefined : init());
  if (K && typeof K.surOnglet === 'function') K.surOnglet(init, { cle: '02-vf-ligne-etat.js' }); // la coquille (A51), sinon `ready`
  else if (SC.state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
