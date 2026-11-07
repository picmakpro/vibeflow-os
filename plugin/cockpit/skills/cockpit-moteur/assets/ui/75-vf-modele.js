// VibeFlow (67-05) : sélecteur du modèle de l'agent, sur les trois onglets, près de la barre de question.
// La liste fermée, le défaut effectif (variable VF_COCKPIT_MODEL ou sonnet) et l'identifiant du lab viennent du serveur
// (/api/vf/modeles, jeton en en-tête). Le choix est gardé dans ce navigateur seulement, sous
// vibeflow-cockpit:modele:<lab> ; il n'est ni écrit dans un fichier généré ni exporté. Une question (POST /api/ask) ne porte
// `model` que si un choix est gardé : sinon la variable ou le défaut s'appliquent côté serveur. Le serveur revalide tout.
// Ne touche pas au viewer : une enveloppe de window.fetch limitée à ce chemin ajoute le champ.
// Même fichier, autre sujet (O4) : la visite « Par où commencer » est mémorisée par lab, voir plus bas.
(() => {
  const SC = window.Floorplan, SRV = window.FLOORPLAN_SERVER;
  if (!SC || !SRV || !SRV.token) return; // page exportée ou ouverte en fichier : pas de serveur, pas d'agent
  const probe = (window.__vfModele = { modele: null, source: null });
  let choix = null; // choix gardé par la personne, dans la liste ; null = laisser le serveur décider

  const nativeFetch = window.fetch.bind(window);
  window.fetch = (input, init) => {
    try {
      const url = typeof input === 'string' ? input : input?.url || '';
      if (choix && init && String(init.method).toUpperCase() === 'POST' && new URL(url, location.href).pathname === '/api/ask') {
        init = { ...init, body: JSON.stringify({ ...JSON.parse(init.body), model: choix }) };
      }
    } catch {} // une enveloppe qui échoue laisse passer la requête telle quelle
    return nativeFetch(input, init);
  };

  const style = document.createElement('style');
  style.textContent = `#vf-modele { flex: none; max-width: 110px; font: inherit; font-size: 12px; color: var(--text-3); background: transparent; border: 0; border-radius: 8px; padding: var(--sp-4) var(--sp-2); cursor: pointer; }
    #vf-modele:hover { color: var(--text); } #vf-modele:focus-visible { outline: 2px solid var(--ring); outline-offset: 1px; }`;
  document.head.appendChild(style);

  // O4 (recette 3) : la visite « Par où commencer » (40-tour.js) garde son « déjà vue » dans SC.store, donc dans le localStorage de l'ORIGINE (port compris). Ici, sans toucher au moteur vendorisé,
  // ce « déjà vue » est rangé par lab, sous vibeflow-cockpit:visite:<lab> (même identifiant de lab que le sélecteur ci-dessous, servi par /api/vf/modeles). Le port du serveur est stable par lab
  // (vf-cockpit-port.mjs) : l'origine, donc ce stockage, est la même d'un lancement à l'autre ; aucun cookie (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03, « C : port stable par lab »).
  // Le sélecteur de modèle, lui, reste par origine. Tant que le lab n'est pas connu, la visite ne démarre pas d'elle-même ;
  // le bouton « Par où commencer » reste utilisable. Lab inconnu (serveur muet) : pas de démarrage automatique, jamais un retour au stockage par port.
  let visiteVue = true, visiteCle = null, visiteMarquee = false;
  const tourCle = (k) => typeof k === 'string' && k.startsWith('tour-seen:');
  const stockGet = SC.store.get, stockSet = SC.store.set;
  SC.store.get = (k, d) => (tourCle(k) ? visiteVue : stockGet(k, d));
  SC.store.set = (k, v) => {
    if (!tourCle(k)) return stockSet(k, v);
    visiteVue = !!v; if (v) { visiteMarquee = true; if (visiteCle) marquer(); }
  };
  const marquer = () => { try { localStorage.setItem(visiteCle, '1'); } catch {} };
  const dejaVue = () => { try { return !!localStorage.getItem(visiteCle); } catch { return false; } };
  const visitePose = (lab) => {
    if (typeof lab !== 'string' || !lab || visiteCle) return;
    visiteCle = 'vibeflow-cockpit:visite:' + lab;
    const vue = dejaVue();
    if (visiteMarquee) { marquer(); return; } // la personne l'a déjà lancée avec le bouton avant que le lab soit connu
    visiteVue = vue; if (vue) return;
    let auto = false;
    const go = () => {
      if (auto) return; auto = true;
      if (location.hash.length > 1) return; // un lien qui désigne un endroit précis : pas de visite d'office (comme 40-tour.js)
      setTimeout(() => { const T = window.FloorplanTour; if (T && !visiteVue && !T.active() && !SC.state.flow && SC.state.container === 'root') T.start(); }, 700);
    };
    if (SC.state.layout) go(); else SC.on('ready', go);
  };

  // PU-G-087 : le tiroir Git (z-index 7) recouvre la carte de la visite (6) : la visite, toujours ouverte dessous, prenait la première Échap et le tiroir en demandait une seconde.
  // Ouvrir le tiroir Git sort donc de la visite ; une seule Échap ferme alors le tiroir.
  window.addEventListener('vf-git:etat', (e) => { const T = window.FloorplanTour; if (e.detail && e.detail.ouvert && T && T.active()) T.end(false); });

  const init = async () => {
    let d;
    try {
      const r = await nativeFetch('/api/vf/modeles', { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' });
      if (!r.ok) return;
      d = await r.json();
    } catch { return; }
    visitePose(d.lab);
    if (!Array.isArray(d.modeles) || !d.modeles.length) return;
    const key = 'vibeflow-cockpit:modele:' + d.lab;
    try { const v = localStorage.getItem(key); if (v && d.modeles.includes(v)) choix = v; } catch {}
    probe.modele = choix || d.defaut; probe.source = choix ? 'selecteur' : 'serveur';
    const form = document.getElementById('ask-form');
    if (!form || document.getElementById('vf-modele')) return;
    const sel = document.createElement('select');
    sel.id = 'vf-modele'; sel.title = "Modèle de l'agent (gardé dans ce navigateur, pour ce projet)"; sel.setAttribute('aria-label', "Modèle de l'agent");
    sel.innerHTML = d.modeles.map((m) => `<option value="${SC.h(m)}">${SC.h(m)}${m === d.defaut && !choix ? ' (défaut)' : ''}</option>`).join('');
    sel.value = probe.modele;
    sel.onchange = () => {
      choix = d.modeles.includes(sel.value) ? sel.value : null;
      probe.modele = choix || d.defaut; probe.source = choix ? 'selecteur' : 'serveur';
      try { if (choix) localStorage.setItem(key, choix); else localStorage.removeItem(key); } catch {}
    };
    form.insertBefore(sel, document.getElementById('ask-engine') || document.getElementById('ask-send'));
  };
  init();
})();
