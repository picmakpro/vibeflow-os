// VibeFlow (79-16, SOCL-20) : la portée d'un onglet. Pendant le démarrage d'un onglet (de ouvrir() à fermer()), elle journalise ce que le
// moteur et ses extensions posent HORS du corps du moteur : écouteurs de window, document, html et body, minuteries, observateurs, flux
// d'événements, remplacement de fetch. demonter() les défait avant l'onglet suivant et restaure l'état de base du document (corps, tête,
// classes, attributs, propriétés de window). Limite écrite : une inscription faite après la fermeture de la portée, ou sur une autre cible
// (liste de requêtes média), n'est pas défaite ; les écouteurs liés à des nœuds du corps disparaissent avec eux. Tout ce qui est posé AVANT
// la première portée (coquille, bibliothèques, scripts persistants) fait partie de la base.
(() => {
  'use strict';
  if (window.VF_PORTEE) return;
  const W = window, D = document, H = D.documentElement;
  const AEL = EventTarget.prototype.addEventListener, REL = EventTarget.prototype.removeEventListener;
  const MO = W.MutationObserver, OBS = ['MutationObserver', 'ResizeObserver', 'IntersectionObserver'];
  const natif = { addEventListener: (c, ...a) => AEL.apply(c, a), removeEventListener: (c, ...a) => REL.apply(c, a) }; // jamais journalisés
  const GARDES = new Set(['data-theme', 'lang', 'data-vf-pret']); // attributs de html que le démontage ne touche pas
  let base = null, journal = null, dernier = null, sq = null, observeur = null;
  const etrangers = new Set(); // nœuds du corps qui ne sont pas au moteur (tiroir, lanceur) : posés hors de toute portée
  const attrs = (e) => Object.fromEntries([...e.attributes].map((a) => [a.name, a.value]));
  const cibles = () => [W, D, H, D.body];

  function prendreBase(squelette) {
    sq = squelette;
    const orig = new Set(sq.orig);
    base = { props: new Set(Object.getOwnPropertyNames(W)), tete: new Set(D.head.children), html: attrs(H), body: attrs(D.body) };
    for (const n of D.body.childNodes) if (!orig.has(n)) etrangers.add(n);
    observeur = new MO((ms) => { if (!journal) for (const m of ms) for (const n of m.addedNodes) etrangers.add(n); }); // hors portée seulement
    observeur.observe(D.body, { childList: true });
  }

  function ouvrir(squelette) {
    if (!base) prendreBase(squelette);
    const j = journal = { ecouteurs: [], minuteries: [], observateurs: [], flux: [], fetch: W.fetch, saved: {} };
    for (const c of cibles()) { // garde:coquille-ecouteurs
      c.addEventListener = function (t, f, o) { j.ecouteurs.push([this, t, f, o]); return AEL.call(this, t, f, o); };
    }
    for (const k of ['setTimeout', 'setInterval']) {
      const o = j.saved[k] = W[k];
      W[k] = function (...a) { const id = o.apply(W, a); j.minuteries.push([k, id]); return id; };
    }
    for (const k of OBS) {
      const O = j.saved[k] = W[k]; if (!O) continue;
      W[k] = class extends O { constructor(...a) { super(...a); j.observateurs.push(this); } };
    }
    { const E = j.saved.EventSource = W.EventSource; if (E) W.EventSource = class extends E { constructor(...a) { super(...a); j.flux.push(this); } }; }
    return j;
  }

  // le temps de démarrage est fini : les primitives reviennent, le journal reste pour le démontage
  function fermer() {
    const j = journal; if (!j) return;
    for (const c of cibles()) delete c.addEventListener;
    for (const [k, o] of Object.entries(j.saved)) if (o) W[k] = o;
    if (observeur) observeur.takeRecords(); // les ajouts de la portée sont ceux du moteur : jamais des nœuds étrangers
    dernier = j; journal = null;
  }

  function demonter() {
    const j = dernier; if (!j || !base) return; dernier = null;
    for (const [c, t, f, o] of j.ecouteurs) REL.call(c, t, f, o); // garde:coquille-demontage-ecouteurs
    for (const [k, id] of j.minuteries) (k === 'setTimeout' ? clearTimeout : clearInterval)(id);
    for (const o of j.observateurs) { try { o.disconnect(); } catch { /* déjà débranché */ } }
    for (const e of j.flux) { try { e.close(); } catch { /* déjà fermé */ } }
    W.fetch = j.fetch; // garde:coquille-fetch
    for (const n of [...D.head.children]) if (!base.tete.has(n)) n.remove(); // garde:coquille-head
    for (const k of Object.getOwnPropertyNames(W)) if (!base.props.has(k)) { try { delete W[k]; } catch { /* propriété non configurable */ } }
    for (const [cible, ref, gardes] of [[H, base.html, GARDES], [D.body, base.body, new Set()]]) {
      for (const a of [...cible.attributes]) if (!gardes.has(a.name) && !(a.name in ref)) cible.removeAttribute(a.name);
      for (const [nom, v] of Object.entries(ref)) if (!gardes.has(nom) && cible.getAttribute(nom) !== v) cible.setAttribute(nom, v);
    }
    // le corps du moteur : tout ce qui n'est pas posé hors portée est retiré, le squelette pris au chargement est remis
    for (const n of [...D.body.childNodes]) if (!etrangers.has(n)) n.remove(); // garde:coquille-corps
    D.body.prepend(...sq.copie.map((n) => n.cloneNode(true)));
  }

  W.VF_PORTEE = Object.freeze({ version: 1, ouvrir, fermer, demonter, natif });
})();
