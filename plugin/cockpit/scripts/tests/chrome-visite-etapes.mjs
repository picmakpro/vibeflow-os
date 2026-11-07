// chrome-visite-etapes.mjs — la visite « Par où commencer » parcourue étape par étape, à deux largeurs (70-07, UIFN-04, P70-D-02, régime P70-D-08). Aucune dépendance.
// Usage : node chrome-visite-etapes.mjs <chrome> <url> <largeurs> [recharge,passer,panneau,equipe,echap,police,dejavu,titrehaut,tangent,cartehaute]      (largeurs : « 1440,390 »)
//   equipe : url = l'onglet Équipe d'un lab qui a une session et un sous-agent (donc au moins deux cartes) ; ne parcourt rien : rend { e<largeur>: { cartes, auto, manuel } } = cartes du graphe, la visite est ouverte par l'appel que fait le démarrage d'office (start() sans argument, 75-vf-modele.js et 40-tour.js), ouverte par le bouton « Par où commencer »
//   echap : (largeur étroite, onglet Projet) un détail de carte est ouvert dans le tiroir, la visite est ouverte, puis Échap deux fois : clé t<largeur> { tiroir0, tour1, tiroir1, tour2, tiroir2 } = état du tiroir (ouvert vrai/faux) et de la visite après chaque temps (la visite, au-dessus, doit capter la première Échap ; le tiroir ne doit pas être touché par l'ouverture ni la sortie de la visite)
//   police : police large imposée à la carte de visite, au titre et aux cartes du graphe (Verdana, puis DejaVu Sans ; l'en-tête et la barre de question gardent la police du poste : DejaVu est moins large que Verdana, R1 « invite tronquée » rougirait sans rapport avec la visite) : la police du poste ne décide plus de la taille des textes ; c'est la contrainte du runner Linux (DejaVu Sans, plus large que les polices de macOS)
//   dejavu : la VRAIE police DejaVu Sans (fichiers TTF dans $VF_DEJAVU_DIR : DejaVuSans.ttf et DejaVuSans-Bold.ttf, jamais dans le dépôt) chargée par @font-face en data: et imposée à toute la page, comme le fait fontconfig sous Ubuntu ; rend { erreur } nommée si les fichiers manquent
//   titrehaut : le bloc titre (#context) est rempli d'une description de 600 caractères avant la visite (un titre plus haut que prévu : police, nom de projet long) ; la carte de visite ne doit toujours rien recouvrir, quitte à replier la description
//   tangent : la barre de question (#ask, élargie en hauteur comme avec un avis) est posée à 2 px de large DANS le bord droit de la carte de visite à sa largeur d'origine (360 px, soit x = 374) : la carte, pendant son animation d'entrée (98 % de sa taille), y paraît à 2 px de distance et le placement la juge libre ; une fois posée elle recouvre la barre (CI Linux de f41cfd25 : carte 16..276, #ask à 274)
//   cartehaute : la carte de visite est haute (hauteur minimale 420 px : texte long, police large) ; la zone libre « au-dessus » est petite, celle « à côté » devient la plus grande, et la carte ciblée y est centrée : tout le graphe doit rester dans la zone libre à gauche du panneau (critère de R1) à l'état stable
//   diag (toujours) : par étape, une ligne compacte de bbox (carte de visite, titre et ses enfants visibles, cible, fenêtre), police calculée du titre, polices réellement rendues (CDP CSS.getPlatformFontsForNode) et polices chargées de la page
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
//   surfaces = noms des surfaces fixes (#zoom, #panel, #context, header, #ask, contour de la cible) que la carte de visite recouvre : vide à chaque étape, à toute largeur, visite ouverte d'office ou par l'API
//   selectionne = la visite a sélectionné quelque chose (le panneau montre alors le détail d'une carte au lieu de la vue d'ensemble) · toutLibre = une carte du graphe sort de la zone libre à gauche du panneau, visite active (critère de R1) · dansZone = la carte ciblée sort de la zone libre de la carte (sous le panneau, l'en-tête ou la barre de question ; 70-07, grandes cartes) · tient = la carte de visite sort de la fenêtre · passer = aucun bouton « Passer » visible dans la carte · repere = texte « n sur N » lu · anglais = mots témoins anglais (liste de F11) dans le texte de la carte de visite.
import { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser } from './chrome-session.mjs';
const [, , chrome, url, largeurs, options = ''] = process.argv;
const recharge = /recharge/.test(options), passer = /passer/.test(options), panneau = /panneau/.test(options), equipe = /equipe/.test(options), echap = /echap/.test(options), police = /police/.test(options), dejavu = /dejavu/.test(options), titrehaut = /titrehaut/.test(options), tangent = /tangent/.test(options), cartehaute = /cartehaute/.test(options);
const DEJAVU_DIR = process.env.VF_DEJAVU_DIR || '';
const HAUT = { 390: 844, 768: 1024, 800: 600, 1024: 768, 1440: 900 };
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlowTour && !!document.getElementById('tour-btn')";
const INIT = "!!window.__vfModele && !!window.__vfModele.modele";
// signature de calme (même grain que CALME de chrome-responsive.mjs) : boîte du graphe, de la carte de visite, transformation, classe « anim » du viewport, repère « n sur N » affiché
const CALME = `(() => { const b = (e) => { const r = e.getBoundingClientRect(); return [r.left, r.top, r.right, r.bottom].map(Math.round); }; const n = [...document.querySelectorAll('#svg g.node')].map(b); const T = document.getElementById('tour'); const t = window.VibeFlow && window.VibeFlow.state.t; const v = document.getElementById('viewport');
  return { n: n.length ? [Math.min(...n.map((x) => x[0])), Math.min(...n.map((x) => x[1])), Math.max(...n.map((x) => x[2])), Math.max(...n.map((x) => x[3]))] : null, tour: T && !T.hidden ? b(T) : null, t: t && [t.k, t.x, t.y].map((x) => Math.round(x * 100)), anim: !!v && v.classList.contains('anim'), rep: ((document.querySelector('#tour .tk') || {}).textContent || '') }; })()`;
// géométrie des surfaces fixes : posée quand deux relevés espacés sont identiques (styles injectés par les options, transitions de #ask et du panneau)
const SURFACES = `(() => { const b = (id) => { const e = document.getElementById(id); if (!e) return null; const r = e.getBoundingClientRect(); return [r.left, r.top, r.right, r.bottom].map(Math.round); }; return ['panel', 'context', 'ask', 'svg', 'zoom'].map(b); })()`;
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
    o.largeur = Math.round(r.w); o.hauteur = Math.round(r.h);
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
  // surfaces fixes de l'interface que la carte de visite ne doit jamais recouvrir (visibles seulement) : zoom, panneau de détail, titre, en-tête, barre de question (et ses avis), contour de la cible
  { const vis = (e) => { const r = e.getBoundingClientRect(), cs = getComputedStyle(e); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'; };
    const liste = [['#zoom', document.getElementById('zoom')], ['#panel', document.getElementById('panel')], ['#context', document.getElementById('context')], ['header', document.querySelector('header')], ['#ask', document.getElementById('ask')], ['cible', document.querySelector('.tour-target')]];
    const ask = document.getElementById('ask'); if (ask) for (const c of ask.children) liste.push(['#ask>' + (c.id || c.className || c.tagName), c]);
    o.surfaces = liste.filter(([, e]) => e && vis(e) && inter(cr, R(e))).map(([n]) => n); }
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
  // diagnostic : bbox des surfaces en jeu et polices, une ligne compacte par étape (aucune assertion n'en dépend)
  const diag = async (i, m) => {
    try {
      const d = await s.ev(`(() => { const R = (e) => { if (!e) return null; const r = e.getBoundingClientRect(); return [r.left, r.top, r.right, r.bottom].map(Math.round).join(','); };
        const ctx = document.getElementById('context'); const kids = ctx ? [...ctx.querySelectorAll('*')].filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0; }).map((e) => e.tagName.toLowerCase() + '[' + R(e) + ']').join(' ') : '';
        const h1 = document.querySelector('#context h1'); const cs = h1 ? getComputedStyle(h1) : null; const T = document.getElementById('tour'), z = document.querySelector('.tour-target');
        const chargees = [...document.fonts].filter((f) => f.status === 'loaded').map((f) => f.family + ' ' + f.weight).join(';');
        const SCv = window.VibeFlow, fa = SCv.freeArea(), sv = document.getElementById('svg').getBoundingClientRect(), nd = [...document.querySelectorAll('#svg g.node')].map((e) => e.getBoundingClientRect()).filter((r) => r.width > 0);
        const gr = nd.length ? [Math.min(...nd.map((r) => r.left)), Math.min(...nd.map((r) => r.top)), Math.max(...nd.map((r) => r.right)), Math.max(...nd.map((r) => r.bottom))].map(Math.round).join(',') : '-';
        const hl = [...(SCv.state.chipEls || new Map()).values()].find((g) => g.classList.contains('hl'));
        const zoneLibre = [sv.left + fa.x, sv.top + fa.y, sv.left + fa.x + fa.w, sv.top + fa.y + fa.h].map(Math.round).join(',');
        return 'zoneLibre=[' + zoneLibre + '] graphe=[' + gr + '] zoom avant visite=' + (window.__vfK0 && window.__vfK0.toFixed(3)) + ' zoom retenu=' + SCv.state.t.k.toFixed(3) + ' carte ciblée=[' + R(hl) + '] fen=' + innerWidth + 'x' + innerHeight + ' tour=[' + R(T) + '] (w ' + T.style.width + ' b ' + T.style.bottom + ' mh ' + T.style.maxHeight + ' ' + T.className + ') context=[' + R(ctx) + '] enfants: ' + kids + ' cible=[' + R(z) + '] h1.font=' + (cs ? cs.fontFamily + ' ' + cs.fontSize + ' ' + cs.fontWeight : '-') + ' check(DejaVu)=' + document.fonts.check("16px 'DejaVu Sans'") + ' chargees=' + chargees; })()`);
      let rendu = '';
      try { await s.send('DOM.enable'); await s.send('CSS.enable'); const doc = await s.send('DOM.getDocument', { depth: 0 }); const n = await s.send('DOM.querySelector', { nodeId: doc.root.nodeId, selector: '#context h1' });
        if (n.nodeId) { const pf = await s.send('CSS.getPlatformFontsForNode', { nodeId: n.nodeId }); rendu = (pf.fonts || []).map((f) => f.familyName + ':' + f.glyphCount).join(','); } } catch (e) { rendu = 'indisponible'; }
      return d + ' rendu=' + rendu;
    } catch (e) { return 'diag indisponible : ' + e.message; }
  };
  for (const w of String(largeurs).split(',').map(Number)) for (const passe of recharge ? [0, 1] : [0]) {
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: HAUT[w] || Math.round(w * 0.625), deviceScaleFactor: 1, mobile: false });
    await s.attendre(`innerWidth === ${w}`, `largeur ${w} appliquée`);
    await s.naviguer(url); await s.attendre(PRET, `page prête à ${w} px`); await s.attendre(INIT, `lab connu à ${w} px`);
    await s.attendre(`document.documentElement.lang === 'fr'`, `page en français à ${w} px`);
    // le démarrage d'office attend 700 ms après le rendu (plus sous un runner lent) : on attend qu'il ait eu lieu (plafond 3 s : l'onglet Équipe n'ouvre rien), PUIS on ferme
    await attendreValeur(() => s.ev('window.VibeFlowTour.active()'), (v) => v === true, { max: 3000 });
    await s.ev('window.VibeFlowTour.end()');
    if (echap) {
      await attendreValeur(() => s.ev('window.VibeFlowTour.active()'), (v) => v === false, { max: 3000 });
      const T = () => s.ev("({ tiroir: !document.body.classList.contains('no-panel'), tour: window.VibeFlowTour.active() })");
      const esc = () => s.ev("document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))");
      await s.ev("[...document.querySelectorAll('#svg g.node')].find((e) => e.getBoundingClientRect().width > 0).dispatchEvent(new MouseEvent('click', { bubbles: true }))");
      const ouvert = await attendreEtStabiliser(T, (v) => v.tiroir, { max: 10000 }); await s.ev('window.VibeFlowTour.start()'); const demarree = await attendreEtStabiliser(T, (v) => v.tour, { max: 10000 });
      await esc(); const e1 = await attendreEtStabiliser(T, (v) => v.tour === false, { max: 10000 }); await esc(); const e2 = await attendreEtStabiliser(T, (v) => v.tiroir === false, { max: 10000 });
      sortie['t' + w] = { carteOuverte: ouvert, visiteDemarree: demarree, echap1: e1, echap2: e2 }; continue;
    }
    if (equipe) {
      const cartes = await s.ev('window.VibeFlow.graph.nodes.length');
      await s.ev('window.VibeFlowTour.end()'); await s.ev('window.VibeFlowTour.start()'); await pause(1200);
      const auto = await s.ev('window.VibeFlowTour.active()'); await s.ev('window.VibeFlowTour.end()'); await pause(300);
      await s.ev("document.getElementById('tour-btn').click()"); await pause(1200);
      const bouton = await s.ev("(() => { const b = document.getElementById('tour-btn'); return { aria: b.getAttribute('aria-disabled'), titre: b.title }; })()");
      sortie['e' + w] = { cartes, auto, manuel: await s.ev('window.VibeFlowTour.active()'), bouton };
      await s.ev('window.VibeFlowTour.end()'); continue;
    }
    if (dejavu) {
      const fs = await import('node:fs'); const lire = (f) => { try { return fs.readFileSync(DEJAVU_DIR + '/' + f).toString('base64'); } catch { return null; } };
      const r = lire('DejaVuSans.ttf'), b = lire('DejaVuSans-Bold.ttf'); if (!r || !b) throw new Error('police DejaVu Sans introuvable : VF_DEJAVU_DIR=' + DEJAVU_DIR);
      await s.ev(`(async () => { const st = document.createElement('style'); st.id = 'vf-dejavu'; st.textContent = "@font-face { font-family: 'DejaVu Sans'; font-weight: 400; src: url(data:font/ttf;base64,${r}) format('truetype'); } @font-face { font-family: 'DejaVu Sans'; font-weight: 700; src: url(data:font/ttf;base64,${b}) format('truetype'); } *, *::before, *::after { font-family: 'DejaVu Sans', sans-serif !important; }"; document.head.appendChild(st); await document.fonts.load("16px 'DejaVu Sans'"); await document.fonts.load("700 16px 'DejaVu Sans'"); return document.fonts.check("16px 'DejaVu Sans'"); })()`);
      await pause(500);
    }
    if (cartehaute) await s.ev("(() => { const st = document.createElement('style'); st.textContent = '#tour { min-height: 420px !important; }'; document.head.appendChild(st); })()");
    if (tangent) await s.ev("(() => { const a = document.getElementById('ask'); a.style.setProperty('left', '374px', 'important'); a.style.setProperty('right', 'auto', 'important'); a.style.setProperty('transform', 'none', 'important'); a.style.setProperty('width', '560px', 'important'); a.style.setProperty('min-height', '150px', 'important'); })()");
    if (titrehaut) await s.ev("(() => { const p = document.querySelector('#context p'); if (p) p.textContent = 'Description volontairement très longue du projet, pour que le bloc titre occupe beaucoup de place : ' + 'mot '.repeat(120); })()");
    if (police) await s.ev("(() => { const st = document.createElement('style'); st.id = 'vf-police-large'; st.textContent = '#tour, #tour *, #context, #context *, #svg * { font-family: Verdana, \\'DejaVu Sans\\', sans-serif !important; letter-spacing: 0.06em !important; }'; document.head.appendChild(st); })()");
    if (panneau) await s.ev("(() => { const p = document.getElementById('panel'); p.style.width = '440px'; })()");
    // la mise en page posée avant la visite (tiroir, barre de question déplacée, titre, police, panneau élargi) : la visite place sa carte sur une géométrie qui ne bouge plus (comme sur la CI)
    await stabiliser(() => s.ev(SURFACES), { pas: 250, max: 5000 });
    const noeuds = await s.ev(DONNEE);
    await s.ev('window.__vfK0 = window.VibeFlow.state.t.k; window.VibeFlowTour.start()');
    await s.attendre("window.VibeFlowTour.active()", `visite lancée à ${w} px (${noeuds} cartes)`, 15000);
    const etapes = [];
    for (let i = 0; i < 14 && (await s.ev('window.VibeFlowTour.active()')); i++) {
      // le centrage de la carte s'anime (520 ms) : on attend l'étape affichée (« i sur N »), l'animation finie (classe anim) et le graphe, la carte et la transformation immobiles, PUIS on mesure
      await attendreEtStabiliser(() => s.ev(CALME), (v) => !v.anim && ((/(\d+) sur \d+/.exec(v.rep) || [])[1] === String(i + 1)), { pas: 300, max: 8000 });
      const m = await s.stable(MESURE, `étape ${i + 1} stable à ${w} px`, 20000);
      if (m.element) { await s.ev("(() => { const e = document.getElementById('vf-lock'); if (e) e.className = 'btn held'; })()"); await pause(1500); m.anneau = !(await s.ev("(() => { const e = document.querySelector('.tour-target'); if (!e) return false; const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0; })()")); }
      m.diag = await diag(i + 1, m);
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
      await pause(1200); await attendreEtStabiliser(() => s.ev(CALME), (v) => !v.anim && !v.tour, { pas: 300, max: 8000 }); const avant = await s.stable(VUE, 'vue avant la visite');
      await s.ev('window.VibeFlowTour.start()'); await s.attendre('window.VibeFlowTour.active()', 'visite relancée', 15000);
      for (let i = 0; i < 2; i++) { await pause(900); await s.ev("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }))"); }
      await pause(900); await s.ev("document.querySelector('#tour .tf [data-x]').click()");
      await pause(1200); await attendreEtStabiliser(() => s.ev(CALME), (v) => !v.anim && !v.tour, { pas: 300, max: 8000 }); sortie['p' + w] = { avant, apres: await s.stable(VUE, 'vue après « Passer »') };
    }
  }
  return sortie;
});
