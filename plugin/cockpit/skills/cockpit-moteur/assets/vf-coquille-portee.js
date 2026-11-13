// VibeFlow (79-16, SOCL-20) : la portée d'un onglet. De ouvrir() à demonter(), c'est-à-dire pendant TOUTE la vie de l'onglet, elle journalise ce que le
// moteur et ses extensions posent HORS du corps du moteur : écouteurs de window, document, html et body, minuteries, observateurs, flux d'événements,
// remplacement de fetch (des inscriptions tardives comprises : un rendu asynchrone, une visite qui démarre). demonter() les défait avant l'onglet suivant
// et rend au document l'état d'avant (corps, tête, classes, attributs, propriétés de window). Ce que la coquille, les bibliothèques et les scripts
// persistants posent AVANT la première portée fait partie de la base ; ce qu'un persistant pose APRÈS (écouteurs tardifs, flux, veille) passe par
// `natif`, jamais journalisé. Limite écrite : une inscription sur une autre cible (liste de requêtes média) n'est pas défaite ; les écouteurs liés à des
// nœuds du corps disparaissent avec eux.
(() => {
  'use strict';
  if (window.VF_PORTEE) return;
  const W = window, D = document, H = D.documentElement;
  const AEL = EventTarget.prototype.addEventListener, REL = EventTarget.prototype.removeEventListener;
  const MO = W.MutationObserver, OBS = ['MutationObserver', 'ResizeObserver', 'IntersectionObserver'];
  // jamais journalisés : pour ce qu'un script persistant pose après son élection (écouteurs tardifs, minuteries, flux)
  const natif = { addEventListener: (c, ...a) => AEL.apply(c, a), removeEventListener: (c, ...a) => REL.apply(c, a), EventSource: W.EventSource,
    setTimeout: W.setTimeout.bind(W), setInterval: W.setInterval.bind(W), clearTimeout: W.clearTimeout.bind(W), clearInterval: W.clearInterval.bind(W) };
  let premiere = true, journal = null, dernier = null, sq = null, observeur = null;
  const GARDES = new Set(['data-theme', 'lang', 'data-vf-pret']); // attributs de html que le démontage ne touche pas
  const etrangers = new Set(); // nœuds du corps qui ne sont pas au moteur (tiroir, lanceur) : posés hors de toute portée
  const attrs = (e) => Object.fromEntries([...e.attributes].map((a) => [a.name, a.value]));
  const etat = () => ({ props: new Set(Object.getOwnPropertyNames(W)), tete: new Set(D.head.children), html: attrs(H), body: attrs(D.body) });
  const cibles = () => [W, D, H, D.body];

  function prendreBase(squelette) {
    sq = squelette; premiere = false;
    const orig = new Set(sq.orig);
    for (const n of D.body.childNodes) if (!orig.has(n)) etrangers.add(n);
    observeur = new MO((ms) => { if (!journal) for (const m of ms) for (const n of m.addedNodes) etrangers.add(n); }); // hors portée seulement
    observeur.observe(D.body, { childList: true });
  }

  function ouvrir(squelette) {
    if (premiere) prendreBase(squelette);
    const j = journal = { ecouteurs: [], minuteries: new Set(), observateurs: new Set(), flux: new Set(), fetch: W.fetch, saved: {}, avant: etat() };
    for (const c of cibles()) { // garde:coquille-ecouteurs
      c.addEventListener = function (t, f, o) { j.ecouteurs.push([this, t, f, o]); return AEL.call(this, t, f, o); };
      c.removeEventListener = function (t, f, o) { // un écouteur retiré par le script sort du journal (la mémoire reste bornée)
        const cap = (x) => !!(x === true || (x && x.capture));
        const i = j.ecouteurs.findLastIndex(([c2, t2, f2, o2]) => c2 === this && t2 === t && f2 === f && cap(o2) === cap(o));
        if (i >= 0) j.ecouteurs.splice(i, 1);
        return REL.call(this, t, f, o);
      };
    }
    for (const [k, annuler] of [['setTimeout', 'clearTimeout'], ['setInterval', 'clearInterval']]) {
      const o = j.saved[k] = W[k], oa = j.saved[annuler] = W[annuler];
      W[k] = function (f, ...a) {
        const id = o.call(W, typeof f === 'function' && k === 'setTimeout' ? function (...b) { j.minuteries.delete(id); return f.apply(this, b); } : f, ...a);
        j.minuteries.add(id); return id;
      };
      W[annuler] = function (id) { j.minuteries.delete(id); return oa.call(W, id); };
    }
    for (const k of OBS) {
      const O = j.saved[k] = W[k]; if (!O) continue;
      W[k] = class extends O {
        constructor(...a) { super(...a); j.observateurs.add(this); }
        disconnect() { j.observateurs.delete(this); return super.disconnect(); }
      };
    }
    const E = j.saved.EventSource = W.EventSource;
    if (E) W.EventSource = class extends E { constructor(...a) { super(...a); j.flux.add(this); } close() { j.flux.delete(this); return super.close(); } };
    return j;
  }

  // ce que la portée a changé sur une cible (html, body) est remis comme avant ; ce qu'un autre a posé depuis (le tiroir) n'est pas touché
  function revenir(cible, avant, apres, gardes) {
    for (const nom of new Set([...Object.keys(avant), ...Object.keys(apres)])) {
      if (gardes.has(nom) || avant[nom] === apres[nom]) continue;
      if (nom === 'class') {
        const a = new Set((avant[nom] || '').split(/\s+/).filter(Boolean)), p = new Set((apres[nom] || '').split(/\s+/).filter(Boolean));
        for (const c of p) if (!a.has(c)) cible.classList.remove(c);
        for (const c of a) if (!p.has(c)) cible.classList.add(c);
      } else if (cible.getAttribute(nom) === (apres[nom] ?? null)) {
        if (avant[nom] === undefined) cible.removeAttribute(nom); else cible.setAttribute(nom, avant[nom]);
      }
    }
  }

  function demonter() {
    const j = journal; if (!j) return; journal = null;
    if (observeur) observeur.takeRecords(); // les ajouts de la vie de l'onglet sont ceux du moteur : jamais des nœuds étrangers
    const apres = etat(); // l'état à la fin de la vie de l'onglet, avant que les primitives reviennent
    for (const c of cibles()) { delete c.addEventListener; delete c.removeEventListener; }
    for (const [k, o] of Object.entries(j.saved)) if (o) W[k] = o;
    for (const [c, t, f, o] of j.ecouteurs) REL.call(c, t, f, o); // garde:coquille-demontage-ecouteurs
    for (const id of j.minuteries) { clearTimeout(id); clearInterval(id); }
    for (const o of j.observateurs) { try { o.disconnect(); } catch { /* déjà débranché */ } }
    for (const e of j.flux) { try { e.close(); } catch { /* déjà fermé */ } }
    W.fetch = j.fetch; // garde:coquille-fetch
    for (const n of apres.tete) if (!j.avant.tete.has(n)) n.remove(); // garde:coquille-head
    for (const k of apres.props) if (!j.avant.props.has(k)) { try { delete W[k]; } catch { /* propriété non configurable */ } }
    revenir(H, j.avant.html, apres.html, GARDES); revenir(D.body, j.avant.body, apres.body, new Set());
    // le corps du moteur : tout ce qui n'est pas posé hors portée est retiré, le squelette pris au chargement est remis
    for (const n of [...D.body.childNodes]) if (!etrangers.has(n)) n.remove(); // garde:coquille-corps
    D.body.prepend(...sq.copie.map((n) => n.cloneNode(true)));
  }

  W.VF_PORTEE = Object.freeze({ version: 1, ouvrir, demonter, natif });
})();
