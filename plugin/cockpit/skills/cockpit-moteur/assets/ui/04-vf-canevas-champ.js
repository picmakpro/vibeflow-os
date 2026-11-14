// VibeFlow (80-12) : cadrer la sélection et ses voisins (FORM-11, P80-D-17). Chargé avant 04-vf-clavier-canevas.js, qui l'appelle à l'exécution ;
// ne lit que window.Floorplan et, à l'appel, window.VF_CANEVAS. Aucun écouteur, aucun état : rien à retirer au changement d'onglet.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const { state } = SC;
  const rect = (id) => (state.layout ? state.layout.children : []).find((c) => c.id === id);
  const feuille = () => matchMedia('(max-width: 999px), (pointer: coarse)').matches; // feuille de détail ; sinon panneau latéral
  // voisins = cartes reliées à la sélection par une arête du niveau, quel qu'en soit le genre (P80-C76-6)
  const groupeDe = (id) => {
    const s = new Set([id]);
    for (const x of (state.edgeEls ? state.edgeEls.values() : [])) { if (x.e.a === id) s.add(x.e.b); else if (x.e.b === id) s.add(x.e.a); }
    return [...s].filter(rect);
  };
  // tiroir Git ouvert : la plus grande découpe du champ de cadrage, à droite du tiroir (sinon null : le champ de cadrage du moteur)
  const zoneSansTiroir = (C) => {
    const tir = document.getElementById('vf-git-tiroir');
    if (!tir || tir.hidden || !tir.offsetWidth) return null;
    const d = tir.getBoundingClientRect().right + 16 - document.getElementById('svg').getBoundingClientRect().left;
    const a = C.champsDeCadrage().sort((p, q) => q.w * q.h - p.w * p.h)[0];
    return d > a.x ? { x: d, y: a.y, w: Math.max(200, a.x + a.w - d), h: a.h } : a;
  };
  // feuille ou doigt : la carte sélectionnée ne reste ni sous #zoom ni sous la pastille « Terminal » (NAVIGATION 4.6) ; la plus petite translation
  // qui l'en sort et la garde dans le champ (sinon la plus petite), k inchangé
  const sortirDesCommandes = (C, id) => {
    const g = state.chipEls.get(id), carte = g && g.querySelector('.card'), o = document.getElementById('svg').getBoundingClientRect();
    if (!carte || !feuille()) return;
    for (const q of ['#zoom', '[data-vf-flottant="bouton"]']) {
      const e = document.querySelector(q), c = carte.getBoundingClientRect(), r = e && e.getClientRects().length ? e.getBoundingClientRect() : null;
      if (!r || c.right <= r.left || r.right <= c.left || c.bottom <= r.top || r.bottom <= c.top) continue;
      const dans = (d) => C.champsDeCadrage().some((a) => c.left + (d.x || 0) >= o.left + a.x - 1 && c.right + (d.x || 0) <= o.left + a.x + a.w + 1
        && c.top + (d.y || 0) >= o.top + a.y - 1 && c.bottom + (d.y || 0) <= o.top + a.y + a.h + 1);
      const d = [{ x: r.left - c.right }, { x: r.right - c.left }, { y: r.top - c.bottom }, { y: r.bottom - c.top }]
        .sort((p, s) => Math.abs(p.x ?? p.y) - Math.abs(s.x ?? s.y));
      C.deplacer(d.find(dans) || d[0]);
    }
  };
  // la formule est celle du moteur (SC.cadrage, plancher de l'onglet) ; aucune relance de render ; le focus revient sur la carte sélectionnée
  const cadrerVoisins = () => {
    const C = window.VF_CANEVAS, id = state.selected;
    if (!C || typeof id !== 'string' || !rect(id)) return false;
    const ids = groupeDe(id), zone = zoneSansTiroir(C), m = SC.cadrage(zone ? { ids, zone } : { ids });
    if (!m || !SC.transformer(m)) return false;
    C.focaliser(id); // carte itinérante, focus, et la carte ramenée dans le champ si le plancher a rogné le groupe
    sortirDesCommandes(C, id);
    return true;
  };
  window.VF_CANEVAS_CHAMP = Object.freeze({ cadrerVoisins });
})();
