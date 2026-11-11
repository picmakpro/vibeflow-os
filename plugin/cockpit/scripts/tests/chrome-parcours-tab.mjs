// chrome-parcours-tab.mjs — parcours de Tab partagé des suites navigateur du cockpit (EK18, test-cockpit-equipe) : des vraies touches Tab depuis le début de la page.
// parcoursTab(s, touche, detail, nom) : s = session de chrome-session.mjs, touche = fabrique de vraies touches de la suite, detail = objet où le parcours range ses arrêts (détail[nom], pour le DIAG), nom = clé.
// Rend la liste des arrêts ('titre' pour un arrêt dans #context, sinon l'id ou la balise), jusqu'au retour au corps de la page OU au premier arrêt déjà visité (le cycle), borne de sécurité large.
export async function parcoursTab(s, touche, detail, nom) {
  // Ni blur() ni une sélection posée au début du document ne ramènent de façon sûre le point de départ de la navigation séquentielle : il reste là où le focus était (le tiroir Git qui vient de s'ouvrir, ou le bouton que la fermeture a refocalisé), et le parcours démarrait alors APRÈS le titre (DIAG du run 42500903126 rejoué : « ouvert » commençait au bouton de fermeture du tiroir, « referme » après le bouton Git). Départ explicite : un repère hors parcours (tabindex -1) en tête du corps reçoit le focus ; la touche Tab suivante va au premier arrêt qui le suit, donc au premier arrêt du document.
  await s.ev("(() => { document.getElementById('vf-tab-depart')?.remove(); const d = document.createElement('span'); d.id = 'vf-tab-depart'; d.tabIndex = -1; d.setAttribute('style', 'position:fixed;left:0;top:0;width:0;height:0;outline:none'); document.body.prepend(d); d.focus({ preventScroll: true }); return document.activeElement === d; })()");
  const arrets = [], vus = new Set(), fiche = [];
  const LIRE = `(() => { const a = document.activeElement; if (!a || a === document.body) return JSON.stringify({ fin: true });
    const W = (window.__tabIds ||= new WeakMap()); if (!W.has(a)) W.set(a, (window.__tabN = (window.__tabN || 0) + 1)); const cs = getComputedStyle(a), r = a.getBoundingClientRect();
    return JSON.stringify({ n: W.get(a), titre: !!a.closest('#context'), cle: a.id || a.tagName, balise: a.tagName.toLowerCase(), id: a.id || '', classe: String(a.className && a.className.baseVal !== undefined ? a.className.baseVal : a.className || '').slice(0, 40), texte: (a.textContent || '').trim().replace(/\\s+/g, ' ').slice(0, 30), tabindex: a.getAttribute('tabindex'), visible: cs.visibility !== 'hidden' && cs.display !== 'none' && r.width > 0 && r.height > 0 }); })()`;
  for (let i = 0; i < 400; i++) {
    await touche('Tab', 'Tab', 9);
    const a = JSON.parse(await s.stable(LIRE, 'arrêt de Tab stable'));
    if (a.fin) { fiche.push('<corps>'); break; }
    if (vus.has(a.n)) { fiche.push('<cycle sur #' + a.n + '>'); break; }
    vus.add(a.n); arrets.push(a.titre ? 'titre' : a.cle);
    fiche.push(`#${a.n} <${a.balise}${a.id ? '#' + a.id : ''}${a.classe ? '.' + a.classe.split(/\s+/)[0] : ''}> « ${a.texte} » tabindex=${a.tabindex} ${a.visible ? 'visible' : 'MASQUÉ'}${a.titre ? ' [dans #context]' : ''}`);
  }
  await s.ev("document.getElementById('vf-tab-depart')?.remove()");
  detail[nom] = fiche;
  return arrets;
}
