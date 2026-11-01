// VibeFlow (67-05) : sélecteur du modèle de l'agent, sur les deux onglets, près de la barre de question.
// La liste fermée, le défaut effectif (variable VF_COCKPIT_MODEL ou sonnet) et l'identifiant du lab viennent du serveur
// (/api/vf/modeles, jeton en en-tête). Le choix est gardé dans ce navigateur seulement, sous
// vibeflow-cockpit:modele:<lab> ; il n'est ni écrit dans un fichier généré ni exporté. Une question (POST /api/ask) ne porte
// `model` que si un choix est gardé : sinon la variable ou le défaut s'appliquent côté serveur. Le serveur revalide tout.
// Ne touche pas au viewer : une enveloppe de window.fetch limitée à ce chemin ajoute le champ.
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
  style.textContent = `#vf-modele { flex: none; max-width: 110px; font: inherit; font-size: 12px; color: var(--text-3); background: transparent; border: 0; border-radius: 8px; padding: 4px 2px; cursor: pointer; }
    #vf-modele:hover { color: var(--text); } #vf-modele:focus-visible { outline: 2px solid var(--ring); outline-offset: 1px; }`;
  document.head.appendChild(style);

  const init = async () => {
    let d;
    try {
      const r = await nativeFetch('/api/vf/modeles', { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' });
      if (!r.ok) return;
      d = await r.json();
    } catch { return; }
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
