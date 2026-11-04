// chrome-visite-etapes.mjs — la visite « Par où commencer » parcourue étape par étape, à deux largeurs (70-07, UIFN-04, P70-D-02, régime P70-D-08). Aucune dépendance.
// Usage : node chrome-visite-etapes.mjs <chrome> <url> <largeurs> [recharge,passer,panneau,equipe,echap]      (largeurs : « 1440,390 »)
//   equipe : url = l'onglet Équipe d'un lab qui a une session et un sous-agent (donc au moins deux cartes) ; ne parcourt rien : rend { e<largeur>: { cartes, auto, manuel } } = cartes du graphe, la visite est ouverte par l'appel que fait le démarrage d'office (start() sans argument, 75-vf-modele.js et 40-tour.js), ouverte par le bouton « Par où commencer »
//   echap : (largeur étroite, onglet Projet) un détail de carte est ouvert dans le tiroir, la visite est ouverte, puis Échap deux fois : clé t<largeur> { tiroir0, tour1, tiroir1, tour2, tiroir2 } = état du tiroir (ouvert vrai/faux) et de la visite après chaque temps (la visite, au-dessus, doit capter la première Échap ; le tiroir ne doit pas être touché par l'ouverture ni la sortie de la visite)
//   panneau : le panneau de détail est élargi à 440 px avant la visite (ce que font d'autres polices, d'autres plateformes : sur la CI Linux, `#panel` recouvrait `#tour` à 768 px) ; champ surPanneau = la carte de visite recouvre le panneau
//   passer : après la visite parcourue, la visite est relancée, avancée de deux étapes (une carte) puis fermée par « Passer » : clé p<largeur> { avant, apres } = { k : zoom, x, y : position, visibles : cartes entièrement dans la fenêtre, recouvre : cartes recouvertes par le titre } (la vue d'avant la visite doit revenir)
//   anneau (étape sur un élément du chrome) = le contour a disparu quand le className du bouton #vf-lock est réécrit à l'arrivée, comme le fait la couche live (70-vf-live.js : « btn held »)
//   recharge : chaque largeur est mesurée DEUX fois dans le même profil Chrome : au premier chargement (clé l<largeur>) puis à un rechargement de la même page déjà vue (clé r<largeur>) ;
//   la visite d'une page déjà vue ne doit pas se centrer autrement que la première (70-07, correctif : le fit de la première étape défaisait le centrage d'une carte).
//   url : l'onglet Code d'un lab jetable dont le graphe a au moins trois cartes de premier niveau (donc au moins trois étapes).
//   Donnée de test : le résumé de chaque carte du graphe chargé, et celui du projet, est allongé au-delà de 230 caractères et se termine par FINDETEXTE.
//   La visite est lancée par son API (le bouton d'en-tête est derrière le menu « ⋯ » sous 700 px) après avoir fermé celle qui démarre d'office.
//   Rend sur une ligne { l<largeur>: { n, etapes: [ { i, cible, centre, couvert, visible, entier, coupe, tient, passer, repere, anglais } ] } } ou { erreur } nommée. Une étape par entrée ; les valeurs de défaut sont :
//   cible = ni carte éclairée (classe hl, la visite ne sélectionne plus : le panneau garde la vue d'ensemble) ni élément du chrome mis en évidence (.tour-target) · centre = carte sélectionnée dont le centre n'est pas dans le tiers central d'une zone libre, sauf si la centrer ferait sortir une autre carte de la zone libre (au-dessus ou à droite de la carte de visite, hors en-tête, titre, panneau et barre de question)
//   couvert = la carte de visite recouvre la cible · visible = la cible n'est pas entièrement dans la fenêtre · entier = le texte de l'étape n'a pas sa fin (FINDETEXTE) alors que sa source la porte · coupe = le texte finit par « … »
//   selectionne = la visite a sélectionné quelque chose (le panneau montre alors le détail d'une carte au lieu de la vue d'ensemble) · toutLibre = une carte du graphe sort de la zone libre à gauche du panneau, visite active (critère de R1) · dansZone = la carte ciblée sort de la zone libre de la carte (sous le panneau, l'en-tête ou la barre de question ; 70-07, grandes cartes) · tient = la carte de visite sort de la fenêtre · passer = aucun bouton « Passer » visible dans la carte · repere = texte « n sur N » lu · anglais = mots témoins anglais (liste de F11) dans le texte de la carte de visite.
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, url, largeurs, options = ''] = process.argv;
const recharge = /recharge/.test(options), passer = /passer/.test(options), panneau = /panneau/.test(options), equipe = /equipe/.test(options), echap = /echap/.test(options);
const HAUT = { 390: 844, 1024: 768, 1440: 900 };
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
  const chip = (SC.state.chipEls ? [...SC.state.chipEls.values()].find((g) => g.classList.contains('hl') || g.classList.contains('sel')) : null) || null; // la carte de la visite : éclairée (hl), jamais sélectionnée
  const cible = document.querySelector('.tour-target');
  const o = { element: false, cible: false, centre: true, couvert: false, visible: true, dansZone: true };
  if (chip) {
    const r = R(chip), s = R(document.getElementById('svg')), a = SC.freeArea();
    const free = { l: s.l + a.x, t: s.t + a.y, r: s.l + a.x + a.w, b: s.t + a.y + a.h };
    const zones = [{ l: free.l, t: free.t, r: free.r, b: Math.min(free.b, cr.t - 8) }, { l: Math.max(free.l, cr.r + 8), t: free.t, r: free.r, b: free.b }].filter((z) => z.r - z.l > 40 && z.b - z.t > 40);
    const cx = (r.l + r.r) / 2, cy = (r.t + r.b) / 2;
    o.cible = true; o.couvert = inter(r, cr); o.visible = dans(r);
    o.dansZone = r.l >= free.l - 1 && r.t >= free.t - 1 && r.r <= free.r + 1 && r.b <= free.b + 1;
    // centrée dans le tiers central d'une zone, OU aussi centrée que le permet le graphe entier : la mettre au milieu de la zone ferait sortir une autre carte de la zone libre (critère de R1)
    const nds0 = [...document.querySelectorAll('#svg g.node')].map(R).filter((x) => x.w > 0 && x.h > 0);
    const U = nds0.length ? { l: Math.min(...nds0.map((x) => x.l)), t: Math.min(...nds0.map((x) => x.t)), r: Math.max(...nds0.map((x) => x.r)), b: Math.max(...nds0.map((x) => x.b)) } : r;
    const sortirait = (z) => { const dx = (z.l + z.r) / 2 - cx, dy = (z.t + z.b) / 2 - cy; return U.l + dx < free.l - 1 || U.r + dx > free.r + 1 || U.t + dy < free.t - 1 || U.b + dy > free.b + 1; };
    o.centre = zones.some((z) => (Math.abs(cx - (z.l + z.r) / 2) <= (z.r - z.l) / 6 && Math.abs(cy - (z.t + z.b) / 2) <= (z.b - z.t) / 6) || sortirait(z));
  } else if (cible) {
    o.element = true; const r = R(cible); o.cible = r.w > 0 && r.h > 0; o.couvert = inter(r, cr); o.visible = dans(r);
  }
  // la carte entière (toutes les cartes visibles) dans la zone libre à gauche du panneau : le critère de R1 (chrome-responsive.mjs), visite active
  const nds = [...document.querySelectorAll('#svg g.node')].map(R).filter((x) => x.w > 0 && x.h > 0), pan = document.querySelector("#panel"), prp = pan ? R(pan) : null;
  const libreD = prp && prp.w > 0 && innerWidth >= 1000 ? prp.l : innerWidth;
  o.toutLibre = !nds.length || (Math.max(...nds.map((x) => x.r)) <= libreD + 1 && Math.min(...nds.map((x) => x.l)) >= -1);
  const tn = card.querySelector('.tn'), note = tn ? tn.textContent : '';
  o.entier = !/RESUME-/.test(note) || /FINDETEXTE/.test(note); o.coupe = /…\\s*$/.test(note);
  o.selectionne = sel !== null && sel !== undefined; // la visite ne sélectionne rien : le panneau garde la vue d'ensemble (R5.3)
  o.tient = dans(cr);
  { const pn = document.getElementById('panel'), pb = pn ? R(pn) : null; o.surPanneau = !!pb && pb.w > 0 && getComputedStyle(pn).visibility !== 'hidden' && inter(cr, pb); }
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
  for (const w of String(largeurs).split(',').map(Number)) for (const passe of recharge ? [0, 1] : [0]) {
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: HAUT[w] || Math.round(w * 0.625), deviceScaleFactor: 1, mobile: false });
    await s.attendre(`innerWidth === ${w}`, `largeur ${w} appliquée`);
    await s.naviguer(url); await s.attendre(PRET, `page prête à ${w} px`); await s.attendre(INIT, `lab connu à ${w} px`);
    await s.attendre(`document.documentElement.lang === 'fr'`, `page en français à ${w} px`);
    await pause(1200); // le démarrage d'office attend 700 ms après le rendu
    await s.ev('window.VibeFlowTour.end()');
    if (echap) {
      await pause(1200); await s.ev('window.VibeFlowTour.end()'); await pause(500);
      const T = () => s.ev("({ tiroir: !document.body.classList.contains('no-panel'), tour: window.VibeFlowTour.active() })");
      const esc = () => s.ev("document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))");
      await s.ev("[...document.querySelectorAll('#svg g.node')].find((e) => e.getBoundingClientRect().width > 0).dispatchEvent(new MouseEvent('click', { bubbles: true }))"); await pause(600);
      const ouvert = await T(); await s.ev('window.VibeFlowTour.start()'); await pause(1200); const demarree = await T();
      await esc(); await pause(500); const e1 = await T(); await esc(); await pause(500); const e2 = await T();
      sortie['t' + w] = { carteOuverte: ouvert, visiteDemarree: demarree, echap1: e1, echap2: e2 }; continue;
    }
    if (equipe) {
      const cartes = await s.ev('window.VibeFlow.graph.nodes.length');
      await s.ev('window.VibeFlowTour.end()'); await s.ev('window.VibeFlowTour.start()'); await pause(1200);
      const auto = await s.ev('window.VibeFlowTour.active()'); await s.ev('window.VibeFlowTour.end()'); await pause(300);
      await s.ev("document.getElementById('tour-btn').click()"); await pause(1200);
      sortie['e' + w] = { cartes, auto, manuel: await s.ev('window.VibeFlowTour.active()') };
      await s.ev('window.VibeFlowTour.end()'); continue;
    }
    if (panneau) await s.ev("(() => { const p = document.getElementById('panel'); p.style.width = '440px'; })()");
    const noeuds = await s.ev(DONNEE);
    await s.ev('window.VibeFlowTour.start()');
    await s.attendre("window.VibeFlowTour.active()", `visite lancée à ${w} px (${noeuds} cartes)`, 15000);
    const etapes = [];
    for (let i = 0; i < 14 && (await s.ev('window.VibeFlowTour.active()')); i++) {
      await pause(1000); // le centrage de la carte s'anime (520 ms) avant la mesure
      const m = await s.stable(MESURE, `étape ${i + 1} stable à ${w} px`, 20000);
      if (m.element) { await s.ev("(() => { const e = document.getElementById('vf-lock'); if (e) e.className = 'btn held'; })()"); await pause(1500); m.anneau = !(await s.ev("(() => { const e = document.querySelector('.tour-target'); if (!e) return false; const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0; })()")); }
      etapes.push({ i: i + 1, ...m });
      await s.ev("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }))");
      await pause(150);
    }
    sortie[(passe ? 'r' : 'l') + w] = { n: etapes.length, noeuds, etapes };
    if (passer && !passe) {
      const VUE = `(() => { const b = (e) => { const r = e.getBoundingClientRect(); return { l: r.left, t: r.top, r: r.right, b: r.bottom, w: r.width, h: r.height }; };
        const n = [...document.querySelectorAll('#svg g.node')].map(b).filter((x) => x.w > 0 && x.h > 0), c = b(document.getElementById('context'));
        const dans = (x) => x.l >= -1 && x.r <= innerWidth + 1 && x.t >= -1 && x.b <= innerHeight + 1;
        const t = window.VibeFlow.state.t; return { k: Math.round(t.k * 1000) / 1000, x: Math.round(t.x), y: Math.round(t.y), visibles: n.filter(dans).length, recouvre: n.filter((x) => Math.min(x.r, c.r) - Math.max(x.l, c.l) > 1 && Math.min(x.b, c.b) - Math.max(x.t, c.t) > 1).length }; })()`;
      await pause(1200); const avant = await s.stable(VUE, 'vue avant la visite');
      await s.ev('window.VibeFlowTour.start()'); await s.attendre('window.VibeFlowTour.active()', 'visite relancée', 15000);
      for (let i = 0; i < 2; i++) { await pause(900); await s.ev("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }))"); }
      await pause(900); await s.ev("document.querySelector('#tour .tf [data-x]').click()");
      await pause(1200); sortie['p' + w] = { avant, apres: await s.stable(VUE, 'vue après « Passer »') };
    }
  }
  return sortie;
});
