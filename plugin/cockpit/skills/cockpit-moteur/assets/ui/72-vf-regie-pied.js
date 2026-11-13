// VibeFlow (73-05) : états de page de la régie (UI-SPEC § 4.5) et pied. Chaque message dit son état et, en une demi-phrase, ce qui le résout (P73-D-32).
// monter(racine) pose la zone des états et le pied, rend le nettoyage ; maj(info) dessine l'état ; ajouter(bloc) est le point où le plan 73-07 branche
// arbres de travail et « ailleurs ». Texte seul (textContent). Pose window.__vfRegiePied.
(() => {
  const D = document, DP = ' :';
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt) e.textContent = txt; return e; };
  const ecrire = (e, t) => { if (e.textContent !== t) e.textContent = t; };
  const SOURCES = { sessions: 'Sessions et sous-agents', locks: 'Verrous du dépôt', dags: 'Plans de la mission' };
  const BOITES = {
    lecture: ["Lecture de l'équipe"],
    aucun: ['Aucun agent dans les dernières 24 h.', "Les sessions de ce dépôt apparaîtront ici dès qu'elles écrivent."],
    direct: ["Le direct n'est pas branché.", "Ouvrez le cockpit depuis le projet pour voir l'équipe."],
  };
  let courant = null;

  function monter(racine) {
    const etats = h('div', 'vf-rg-etats'), zone = h('div', 'vf-rg-piedzone'), source = h('p', 'vf-rg-source'), direct = h('p', 'vf-rg-direct');
    const entete = racine.querySelector('#vf-equipe-entete');
    let boite = null, nom = '';
    source.hidden = true; zone.append(source);
    if (entete) racine.insertBefore(etats, entete.nextSibling); else racine.append(etats);
    racine.append(zone);
    const poser = (n) => {
      if (n === nom) return;
      nom = n; if (boite) { boite.remove(); boite = null; }
      if (!n) return;
      boite = h('div', 'vf-rg-note'); for (const t of BOITES[n]) boite.append(h('p', '', t)); etats.append(boite);
    };
    // info : { lecture (muet : pas encore de boîte, avant 150 ms), direct (faux = pas de direct), aucun, sources,
    //   coupe (secondes depuis la dernière donnée, ou null) }
    const maj = (info) => {
      info = info || {};
      if (info.lecture) racine.setAttribute('aria-busy', 'true'); else if (racine.hasAttribute('aria-busy')) racine.removeAttribute('aria-busy');
      poser(info.direct === false ? 'direct' : info.lecture ? (info.muet ? '' : 'lecture') : info.aucun ? 'aucun' : '');
      const mal = Object.entries(info.sources || {}).filter(([, s]) => s && (s.etat === 'erreur' || s.etat === 'forme-inconnue'))
        .map(([k]) => (Object.hasOwn(SOURCES, k) ? SOURCES[k] : k));
      ecrire(source, mal.length ? `Source illisible${DP} ${mal.join(', ')}` : '');
      if (source.hidden === !!mal.length) source.hidden = !mal.length;
      if (info.coupe == null) { if (direct.parentNode) direct.remove(); return; }
      const d = window.__vfEquipeRendu.duree(Math.max(0, Math.round(info.coupe)));
      ecrire(direct, `Direct coupé${DP} durées figées, données d'il y a ${d}`);
      if (!direct.parentNode && entete) entete.append(direct);
    };
    const ajouter = (bloc) => { if (bloc) zone.insertBefore(bloc, source); };
    courant = { maj, ajouter };
    return () => { courant = null; etats.remove(); zone.remove(); direct.remove(); };
  }
  window.__vfRegiePied = { monter, maj: (i) => { if (courant) courant.maj(i); }, ajouter: (b) => { if (courant) courant.ajouter(b); } };
})();
