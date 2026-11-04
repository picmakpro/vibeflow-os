// chrome-visite-etapes.mjs — la visite « Par où commencer » parcourue étape par étape, à deux largeurs (70-07, UIFN-04, P70-D-02, régime P70-D-08). Aucune dépendance.
// Usage : node chrome-visite-etapes.mjs <chrome> <url> <largeurs>      (largeurs : « 1440,390 »)
//   url : l'onglet Code d'un lab jetable dont le graphe a au moins trois cartes de premier niveau (donc au moins trois étapes).
//   Donnée de test : le résumé de chaque carte du graphe chargé, et celui du projet, est allongé au-delà de 230 caractères et se termine par FINDETEXTE.
//   La visite est lancée par son API (le bouton d'en-tête est derrière le menu « ⋯ » sous 700 px) après avoir fermé celle qui démarre d'office.
//   Rend sur une ligne { l<largeur>: { n, etapes: [ { i, cible, centre, couvert, visible, entier, coupe, tient, passer, repere, anglais } ] } } ou { erreur } nommée. Une étape par entrée ; les valeurs de défaut sont :
//   cible = ni carte sélectionnée ni élément du chrome mis en évidence (.tour-target) · centre = carte sélectionnée dont le centre n'est pas dans le tiers central d'une zone libre (au-dessus ou à droite de la carte de visite, hors en-tête, titre, panneau et barre de question)
//   couvert = la carte de visite recouvre la cible · visible = la cible n'est pas entièrement dans la fenêtre · entier = le texte de l'étape n'a pas sa fin (FINDETEXTE) alors que sa source la porte · coupe = le texte finit par « … »
//   tient = la carte de visite sort de la fenêtre · passer = aucun bouton « Passer » visible dans la carte · repere = texte « n sur N » lu · anglais = mots témoins anglais (liste de F11) dans le texte de la carte de visite.
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, url, largeurs] = process.argv;
const HAUT = { 390: 844, 1440: 900 };
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlowTour && !!document.getElementById('tour-btn')";
const INIT = "!!window.__vfModele && !!window.__vfModele.modele";
const DONNEE = `(() => { const G = window.VibeFlow.graph; const long = (n) => 'RESUME-' + n + ' Ce résumé de test est volontairement très long : il dépasse deux cent trente caractères pour que la visite le coupe, ou le montre entier. Il continue encore un peu pour être sûr de passer la limite, puis il se termine ici : FINDETEXTE';
  for (const n of G.nodes) n.summary = long(n.id); G.project = G.project || {}; G.project.summary = long('projet'); return G.nodes.length; })()`;
const MESURE = `(() => {
  const SC = window.VibeFlow, card = document.getElementById('tour');
  const R = (e) => { const r = e.getBoundingClientRect(); return { l: r.left, t: r.top, r: r.right, b: r.bottom, w: r.width, h: r.height }; };
  const inter = (a, b) => Math.min(a.r, b.r) - Math.max(a.l, b.l) > 1 && Math.min(a.b, b.b) - Math.max(a.t, b.t) > 1;
  const dans = (a) => a.l >= -0.5 && a.t >= -0.5 && a.r <= innerWidth + 0.5 && a.b <= innerHeight + 0.5;
  const cr = R(card), sel = SC.state.selected;
  const chip = typeof sel === 'string' && SC.state.chipEls ? SC.state.chipEls.get(sel) : null;
  const cible = document.querySelector('.tour-target');
  const o = { cible: false, centre: true, couvert: false, visible: true };
  if (chip) {
    const r = R(chip), s = R(document.getElementById('svg')), a = SC.freeArea();
    const free = { l: s.l + a.x, t: s.t + a.y, r: s.l + a.x + a.w, b: s.t + a.y + a.h };
    const zones = [{ l: free.l, t: free.t, r: free.r, b: Math.min(free.b, cr.t - 8) }, { l: Math.max(free.l, cr.r + 8), t: free.t, r: free.r, b: free.b }].filter((z) => z.r - z.l > 40 && z.b - z.t > 40);
    const cx = (r.l + r.r) / 2, cy = (r.t + r.b) / 2;
    o.cible = true; o.couvert = inter(r, cr); o.visible = dans(r);
    o.centre = zones.some((z) => Math.abs(cx - (z.l + z.r) / 2) <= (z.r - z.l) / 6 && Math.abs(cy - (z.t + z.b) / 2) <= (z.b - z.t) / 6);
  } else if (cible) {
    const r = R(cible); o.cible = r.w > 0 && r.h > 0; o.couvert = inter(r, cr); o.visible = dans(r);
  }
  const tn = card.querySelector('.tn'), note = tn ? tn.textContent : '';
  o.entier = !/RESUME-/.test(note) || /FINDETEXTE/.test(note); o.coupe = /…\\s*$/.test(note);
  o.tient = dans(cr);
  const p = card.querySelector('.tf [data-x]'); let pr = false;
  if (p) { const r = R(p), cs = getComputedStyle(p); pr = r.w > 0 && r.h > 0 && cs.visibility !== 'hidden' && cs.display !== 'none' && dans(r) && r.b <= cr.b + 0.5 && r.t >= cr.t - 0.5 && /^(Passer|Skip)$/.test(p.textContent.trim()); }
  o.passer = pr;
  const m = /(\\d+) sur (\\d+)/.exec((card.querySelector('.tk') || {}).textContent || ''); o.repere = m ? m[0] : '';
  const TEMOINS = /\\b(and|of|the|at|top|up|here|calls?|steps?|show|changes|endpoints|uses|resolve|still|generated|names|again|worth|fixing|minor|skip|next|back|done|start)\\b/i;
  const texte = card.innerText.replace(note, ''); o.anglais = (TEMOINS.exec(texte) || [''])[0];
  return o;
})()`;
await executer(chrome, async (s) => {
  const sortie = {};
  for (const w of String(largeurs).split(',').map(Number)) {
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: HAUT[w] || Math.round(w * 0.625), deviceScaleFactor: 1, mobile: false });
    await s.attendre(`innerWidth === ${w}`, `largeur ${w} appliquée`);
    await s.naviguer(url); await s.attendre(PRET, `page prête à ${w} px`); await s.attendre(INIT, `lab connu à ${w} px`);
    await s.attendre(`document.documentElement.lang === 'fr'`, `page en français à ${w} px`);
    await pause(1200); // le démarrage d'office attend 700 ms après le rendu
    await s.ev('window.VibeFlowTour.end()');
    const noeuds = await s.ev(DONNEE);
    await s.ev('window.VibeFlowTour.start()');
    await s.attendre("window.VibeFlowTour.active()", `visite lancée à ${w} px (${noeuds} cartes)`, 15000);
    const etapes = [];
    for (let i = 0; i < 14 && (await s.ev('window.VibeFlowTour.active()')); i++) {
      await pause(1000); // le centrage de la carte s'anime (520 ms) avant la mesure
      const m = await s.stable(MESURE, `étape ${i + 1} stable à ${w} px`, 20000);
      etapes.push({ i: i + 1, ...m });
      await s.ev("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }))");
      await pause(150);
    }
    sortie['l' + w] = { n: etapes.length, noeuds, etapes };
  }
  return sortie;
});
