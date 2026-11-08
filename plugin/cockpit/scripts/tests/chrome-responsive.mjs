// chrome-responsive.mjs — mesure de la mise en page du cockpit à plusieurs largeurs (CKPT-12, P67-D-21). Aucune dépendance.
// Usage : node chrome-responsive.mjs <chrome> <url> <largeurs> <resize|-> [<dossierCaptures>]
//   <largeurs>  « 1024,1280,1440,1920 » : un chargement par largeur, hauteur déduite (16:10 environ)
//   <resize>    « 1920:1024 » : charge à la première largeur puis redimensionne À CHAUD à la seconde, puis revient ; « - » = rien
// Rend sur une ligne { mesures: { "<largeur>" | "resize:<a>:<b>" | "resize:<b>:<a>": { v: [violations], m: {chiffres} } } } ou { erreur }.
// Une violation = deux éléments frères visibles qui se recouvrent, un texte rogné (scrollWidth > clientWidth), un élément hors de la fenêtre,
// un bouton ou lien d'en-tête qui sort de la fenêtre (x + largeur > innerWidth), une recherche, un logo ou une barre de question sous leur taille minimale (sur plusieurs lignes tolérée sous 1 000 px : le gabarit étroit du viewer). RESP_INJECT : expression évaluée après le chargement (boutons d'en-tête optionnels de l'onglet Code, absents d'un lab de test). Le HOME réel est rendu à Chrome (REAL_HOME).
// 70-12 : fenetre, nCartes, carte1, titreRect, titreCarte, zoomCartes, filRect, rechercheRect, filRecherche (page Équipe, UIFN-14).
// 70-04 : mesures neuves rangées dans `m` seulement (rangees, actionsRangee, plus, plusPastille, sources, menu, onglets, zoom, askRect, upRect, btnPanel, tiroir, poignee, croix, titreMots) ; les interactions (ouvrir le menu, taper une carte, le titre, la croix, Échap, le vide, lancer un parcours) passent par RESP_INJECT, une interaction par chargement (la mesure attend deux relevés identiques : la mise en page est posée).
import fs from 'node:fs'; import path from 'node:path';
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, url, largeurs, resize, shots] = process.argv;
const HAUT = { 390: 844, 800: 600, 1024: 768, 1280: 800, 1440: 900, 1920: 1080, 2560: 1300 };
const hauteur = (w) => HAUT[w] || Math.round(w * 0.625);

const MESURE = `(() => {
  const vw = innerWidth, vh = innerHeight, v = [], m = {};
  const vis = (e) => { const r = e.getBoundingClientRect(), s = getComputedStyle(e); return r.width > 0 && r.height > 0 && s.visibility !== 'hidden' && s.display !== 'none' && Number(s.opacity) > 0.01 && !e.hidden; };
  const nom = (e) => e.id ? '#' + e.id : e.tagName.toLowerCase() + (typeof e.className === 'string' && e.className.trim() ? '.' + e.className.trim().split(/\\s+/)[0] : '');
  const rec = (e) => e.getBoundingClientRect();
  const inter = (a, b) => Math.min(a.right, b.right) - Math.max(a.left, b.left) > 1.5 && Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top) > 1.5;
  const paires = (liste, groupe) => { for (let i = 0; i < liste.length; i++) for (let j = i + 1; j < liste.length; j++) if (!liste[i].contains(liste[j]) && !liste[j].contains(liste[i]) && inter(rec(liste[i]), rec(liste[j]))) v.push(groupe + ' : ' + nom(liste[i]) + ' recouvre ' + nom(liste[j])); };
  const dedans = (liste, groupe) => { for (const e of liste) { const r = rec(e); if (r.left < -0.5 || r.right > vw + 0.5) v.push(groupe + ' : ' + nom(e) + ' sort de la fenêtre (' + Math.round(r.left) + '..' + Math.round(r.right) + ' sur ' + vw + ')'); } };
  const rogne = (liste, groupe) => { for (const e of liste) { if (e.scrollWidth > e.clientWidth + 1) { const s = getComputedStyle(e); if (e.id === 'proj-name' && s.textOverflow === 'ellipsis' && s.overflow !== 'visible') continue; v.push(groupe + ' : ' + nom(e) + ' rogné (scrollWidth ' + e.scrollWidth + ' > ' + e.clientWidth + ')'); } } };

  // --- en-tête : éléments terminaux (jamais un conteneur et son contenu)
  const hd = document.querySelector('header');
  const items = [...hd.querySelectorAll('.brand, .vf-tabs, #btn-up, #crumbs, #search-btn, #hdr-ext > *, .hr > :not(#hdr-ext)')].filter(vis);
  m.enteteElements = items.length; m.enteteHauteur = Math.round(rec(hd).height);
  paires(items, 'en-tête'); dedans(items, 'en-tête');
  // sortie d'écran : TOUT élément visible de l'en-tête, à n'importe quelle profondeur (x + largeur > innerWidth), pas seulement les éléments terminaux listés
  dedans([...hd.querySelectorAll('button, a, input, .bl')].filter(vis), 'en-tête (sortie d\\'écran)');
  rogne([hd, ...items, ...hd.querySelectorAll('#proj-name, .bl, .vf-tabs a')].filter(vis), 'en-tête');
  if (document.documentElement.scrollWidth > vw + 1) v.push('page : défilement horizontal (' + document.documentElement.scrollWidth + ' > ' + vw + ')');

  // --- recherche et logo
  const sb = document.querySelector('#search-btn'); m.recherche = sb && vis(sb) ? Math.round(rec(sb).width) : 0;
  if (vw >= 1000 && m.recherche < 200) v.push('recherche : ' + m.recherche + ' px, minimum 200');
  const mk = document.querySelector('.brand .mark'); const rm = mk && rec(mk);
  m.logo = rm ? Math.round(rm.width) + 'x' + Math.round(rm.height) : '0x0'; m.logoFiltre = mk ? getComputedStyle(mk).filter : '';
  if (!rm || rm.width < 20 || rm.height < 18 || !mk.naturalWidth) v.push('logo : ' + m.logo + ' (minimum 20x18, image chargée)');
  if (mk && getComputedStyle(mk).filter !== 'none') v.push('logo : filtre ' + getComputedStyle(mk).filter + ' (le logo VibeFlow est déjà au bon contraste)');

  // --- panneaux et surfaces flottantes
  const surf = ['#panel', '#ask', '#zoom', '#context', '#tour', '#flowbar'].map((s) => document.querySelector(s)).filter((e) => e && vis(e));
  paires(surf, 'surfaces'); paires([...items, ...surf.filter((e) => e.id !== 'context')], 'en-tête et surfaces'); dedans(surf, 'surfaces');
  m.surfaces = surf.map(nom).join(' ');

  // --- barre de question : une seule ligne, le texte d'invite entier, aucun enfant qui se recouvre
  const ask = document.querySelector('#ask-form');
  if (ask && vis(ask)) {
    const enf = [...ask.children].filter(vis); paires(enf, 'barre de question'); dedans(enf, 'barre de question');
    m.askLargeur = Math.round(rec(ask).width); m.askHauteur = Math.round(rec(ask).height);
    if (vw >= 1000 && rec(ask).height > 64) v.push('barre de question : sur plusieurs lignes (' + m.askHauteur + ' px)');
    const inp = document.querySelector('#ask-input');
    if (inp && vis(inp)) {
      const s = getComputedStyle(inp), c = document.createElement('canvas').getContext('2d'); c.font = s.fontStyle + ' ' + s.fontWeight + ' ' + s.fontSize + ' ' + s.fontFamily;
      const besoin = Math.ceil(c.measureText(inp.placeholder || '').width) + 4, dispo = Math.floor(inp.clientWidth - parseFloat(s.paddingLeft) - parseFloat(s.paddingRight));
      m.askInvite = besoin + '/' + dispo; if (besoin > dispo) v.push('barre de question : invite tronquée (' + besoin + ' px > ' + dispo + ')');
    }
  }
  // --- la carte tient dans la zone libre (hors panneau)
  const noeuds = [...document.querySelectorAll('#svg g.node')].filter(vis);
  if (noeuds.length) {
    const r = noeuds.map(rec), g = { l: Math.min(...r.map((x) => x.left)), r: Math.max(...r.map((x) => x.right)), t: Math.min(...r.map((x) => x.top)) };
    const pan = document.querySelector('#panel'), libreD = pan && vis(pan) && vw >= 1000 ? rec(pan).left : vw;
    m.carte = Math.round(g.l) + '..' + Math.round(g.r) + ' / libre 0..' + Math.round(libreD);
    if (g.r > libreD + 1 || g.l < -1) v.push('carte : sort de la zone libre (' + m.carte + ')');
  }
  // --- 70-04 (UIFN-01 à UIFN-03, P70-D-16) : mesures neuves, rangées dans m seulement (jamais dans v : R1 à R8 gardent leur sens)
  const lib = (b) => (b.querySelector('.bl')?.textContent || b.getAttribute('aria-label') || b.getAttribute('title') || '').trim();
  const court = (b) => b.id === 'theme-toggle' ? lib(b).split(/[(.]/)[0].trim() : lib(b); // Q11 : le menu « ⋯ » abrège le libellé du thème à son état (« Thème : Auto »)
  const pastille = (b) => (b.querySelector('.badge')?.textContent || '').trim();
  const arr = (r) => [r.left, r.top, r.width, r.height].map(Math.round);
  const act = [...hd.querySelectorAll('.hr button')].filter((b) => !['vf-lock', 'vf-plus', 'btn-panel'].includes(b.id) && !b.hidden);
  // rangées : éléments terminaux visibles de l'en-tête, regroupés par centre vertical (tolérance 4 px ; des éléments de hauteurs différentes d'une même rangée n'ont pas le même haut)
  const centres = [...hd.querySelectorAll('.brand, .vf-tabs, #btn-up, #search-btn, #zoom, .hr button')].filter(vis).map((e) => rec(e).top + rec(e).height / 2).sort((a, b) => a - b);
  m.rangees = 0; for (let i = 0, d = -1e9; i < centres.length; i++) if (centres[i] - d > 4) { m.rangees++; d = centres[i]; }
  m.actionsRangee = act.filter(vis).map((b) => b.id || b.className).join(',');
  const pl = document.querySelector('#vf-plus'); m.plus = !!(pl && vis(pl)); m.plusPastille = pl && pl.querySelector('.badge') ? 'point' : ''; // Q8 : un point de présence, sans compte
  m.sources = act.map((b) => ({ id: b.id, t: court(b), b: pastille(b), off: b.disabled || b.getAttribute('aria-disabled') === 'true', ti: b.getAttribute('title') || '' }));
  const mn = document.querySelector('#vf-plus-menu');
  m.menu = mn && vis(mn) ? [...mn.querySelectorAll('[role="menuitem"]')].filter(vis).map((e) => { const c = e.cloneNode(true); c.querySelector('.badge')?.remove(); return { t: c.textContent.trim(), b: pastille(e), off: e.getAttribute('aria-disabled') === 'true' || e.disabled, op: Number(getComputedStyle(e).opacity), ti: e.getAttribute('title') || '' }; }) : null;
  const tabs = [...hd.querySelectorAll('.vf-tabs a')], piste = hd.querySelector('.vf-tabs');
  m.onglets = piste && tabs.length ? { n: tabs.length, police: [...new Set(tabs.map((a) => getComputedStyle(a).fontSize))].join('/'), piste: getComputedStyle(piste).paddingTop + '/' + getComputedStyle(piste).paddingLeft, pad: getComputedStyle(tabs[0]).paddingLeft } : null;
  const zm = document.querySelector('#zoom'), af = document.querySelector('#ask-form'), up = document.querySelector('#btn-up');
  m.zoom = zm ? { entete: hd.contains(zm), vis: vis(zm), replie: zm.getAttribute('data-vf-replie'), feuille: innerWidth <= 700 && !document.body.classList.contains('no-panel'), dir: getComputedStyle(zm).flexDirection, r: arr(rec(zm)), boutons: [...zm.querySelectorAll('button')].map((b) => ({ id: b.id, aria: b.getAttribute('aria-label') || '', title: b.getAttribute('title') || '' })) } : null;
  m.askRect = af && vis(af) ? arr(rec(af)) : null; m.upRect = up && vis(up) ? arr(rec(up)) : null;
  const bp = document.querySelector('#btn-panel'), pn = document.querySelector('#panel');
  // diagnostic de la visite ouverte (lu par les suites quand une assertion rougit : bbox de la carte de visite, de #ask et de ses avis, de la fenêtre, obstacles vus au dernier placement)
  { const T = document.getElementById('tour'), A = document.getElementById('ask'); if (T && !T.hidden) { const B = (e) => { if (!e) return '-'; const r = e.getBoundingClientRect(); return '[' + [r.left, r.top, r.right, r.bottom].map(Math.round).join(',') + ']'; };
      m.tourDiag = 'fen=' + vw + 'x' + vh + ' tour=' + B(T) + ' (w ' + T.style.width + ' b ' + T.style.bottom + ' mh ' + T.style.maxHeight + ') ask=' + B(A) + ' enfants: ' + (A ? [...A.children].map((c) => (c.id || c.className || c.tagName) + B(c) + (vis(c) ? '' : '(caché)')).join(' ') : '') + ' | ' + (window.VibeFlowTour && window.VibeFlowTour.diag ? window.VibeFlowTour.diag() : 'sans diag'); } }
  m.btnPanel = !!(bp && vis(bp)); m.tiroir = !!(pn && vis(pn)) && !document.body.classList.contains('no-panel');
  m.poignee = !!pn && [...pn.querySelectorAll('[aria-hidden="true"]')].some((e) => vis(e) && rec(e).width >= 24 && rec(e).height <= 8 && rec(e).top - rec(pn).top < 24);
  m.croix = !!pn && [...pn.querySelectorAll('button')].some((b) => vis(b) && /^Fermer/i.test(b.getAttribute('aria-label') || ''));
  // titre de la vue d'ensemble : un mot (suite de caractères non blancs, d'un seul tenant même si le texte est coupé en plusieurs noeuds) sur plusieurs rectangles = coupé ; exempt s'il est plus large que sa boîte
  const h1 = document.querySelector('#context h1');
  if (h1 && vis(h1)) {
    const noeuds = [], tw = document.createTreeWalker(h1, NodeFilter.SHOW_TEXT); let t, txt = ''; while ((t = tw.nextNode())) { noeuds.push({ n: t, d: txt.length }); txt += t.data; }
    const pos = (i) => { let k = noeuds.length - 1; while (k > 0 && noeuds[k].d > i) k--; return [noeuds[k].n, i - noeuds[k].d]; };
    m.titreMots = []; for (const w of txt.matchAll(/\\S+/g)) { const rg = document.createRange(), [a, ao] = pos(w.index), [z, zo] = pos(w.index + w[0].length - 1); rg.setStart(a, ao); rg.setEnd(z, zo + 1);
      const rs = [...rg.getClientRects()].filter((r) => r.width > 0), larg = rs.reduce((s, r) => s + r.width, 0);
      m.titreMots.push({ mot: w[0], rect: rs.length, large: larg > h1.clientWidth }); }
    m.titreBoite = h1.clientWidth; m.titreTexte = txt;
  }
  // 70-12 (UIFN-14, P70-D-20) : mesures de la page Équipe (zoom, titre, première carte, fil d'Ariane, recherche), rangées dans m seulement (jamais dans v : R1 à R9 gardent leur sens)
  const aire = (a, b) => { const x = Math.min(a.right, b.right) - Math.max(a.left, b.left), y = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top); return x > 0 && y > 0 ? Math.round(x * y) : 0; };
  m.fenetre = [vw, vh];
  const cartes = [...document.querySelectorAll('#svg g.node .card')].filter(vis).sort((a, b) => rec(a).top - rec(b).top || rec(a).left - rec(b).left);
  m.nCartes = cartes.length; m.carte1 = cartes[0] ? arr(rec(cartes[0])) : null;
  m.titreRect = h1 && vis(h1) ? arr(rec(h1)) : null;
  m.titreCarte = h1 && vis(h1) && cartes[0] ? aire(rec(h1), rec(cartes[0])) : null; // aire (px²) du titre qui recouvre la première carte
  m.zoomCartes = zm && vis(zm) ? cartes.filter((c) => aire(rec(zm), rec(c)) > 0).length : null; // nombre de cartes que le zoom recouvre
  const fil = document.querySelector('#crumbs');
  m.filRect = fil && vis(fil) ? arr(rec(fil)) : null; m.rechercheRect = sb && vis(sb) ? arr(rec(sb)) : null;
  m.filRecherche = fil && vis(fil) && sb && vis(sb) ? aire(rec(fil), rec(sb)) : null; // aire (px²) du fil d'Ariane qui recouvre la recherche
  m.pointeur = ['none', 'coarse', 'fine'].find((p) => matchMedia('(pointer: ' + p + ')').matches) || '?';
  return { v, m };
})()`;

const PRET = `document.readyState === 'complete' && !!document.querySelector('header .brand .mark') && document.querySelector('header .brand .mark').naturalWidth > 0 && !!document.querySelector('#ask-form')`;
await executer(chrome, async (s) => {
  const taille = async (w) => { await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: hauteur(w), deviceScaleFactor: 1, mobile: false }); await s.attendre(`innerWidth === ${w}`, `largeur ${w} appliquée`); };
  const mesures = {};
  const mesurer = async (cle) => { // un relevé n'est retenu que lorsque deux relevés consécutifs sont identiques (mise en page posée)
    mesures[cle] = await s.stable(MESURE, `mesure de la mise en page à ${cle}`);
    if (shots) { const c = await s.send('Page.captureScreenshot', { format: 'png' }); fs.mkdirSync(shots, { recursive: true }); fs.writeFileSync(path.join(shots, cle.replace(/[^\w]+/g, '-') + '.png'), Buffer.from(c.data, 'base64')); }
  };
  // la mesure se prend quand le graphe et la carte de visite ne bougent plus : mêmes positions sur deux relevés espacés de 250 ms (plafond 5 s). Le cadrage de la visite s'anime ; sur un runner lent, la mesure tombait parfois en plein transit
  // (R1 long / project / 1 024 px, intermittent). RESP_SANS_ATTENTE=1 retire l'attente (mutant, pour prouver que la course est vue).
  const CALME = "(() => { const b = (e) => { const r = e.getBoundingClientRect(); return [r.left, r.top, r.right, r.bottom].map(Math.round); }; const n = [...document.querySelectorAll('#svg g.node')].map(b); const T = document.getElementById('tour'); const t = window.VibeFlow && window.VibeFlow.state.t; return { n: n.length ? [Math.min(...n.map((x) => x[0])), Math.min(...n.map((x) => x[1])), Math.max(...n.map((x) => x[2])), Math.max(...n.map((x) => x[3]))] : null, tour: T && !T.hidden ? b(T) : null, t: t && [t.k, t.x, t.y].map((v) => Math.round(v * 100)), anim: document.getElementById('viewport') && document.getElementById('viewport').classList.contains('anim') }; })()";
  // calme() reste ici, hors des aides communes de chrome-session.mjs (stabiliser, attendreEtStabiliser) : sa spécification est plus forte (valeur identique pendant au moins 800 ms continues, absence de la classe « anim »,
  // plafond 6 s sans erreur) et un arrêt d'animation de 700 ms (RESP_COURSE) trompe un stabiliser à deux relevés ; un prédicat « différent de l'avant » pourrait de plus ne jamais aboutir quand le graphe ne bouge pas.
  // calme : la même valeur sur des relevés espacés de 150 ms pendant au moins 800 ms (plus long qu'un arrêt de l'animation), sans classe « anim » ; plafond 6 s
  const calme = async (w) => { if (process.env.RESP_SANS_ATTENTE) return; const fin = Date.now() + 6000; let prec = null, depuis = 0;
    while (Date.now() < fin) { let c = null; try { c = JSON.stringify(await s.ev(CALME)); } catch { c = null; } const maintenant = Date.now();
      if (c && c === prec && !/"anim":true/.test(c)) { if (maintenant - depuis >= 800) return; } else { prec = c; depuis = maintenant; }
      await pause(150); } };
  const charger = async (w) => { await taille(w); await s.naviguer(url); await s.attendre(PRET, `page prête à ${w} px`);
    // RESP_POLICE=1 : police large imposée à la carte de visite, au titre et aux cartes du graphe (Verdana, puis DejaVu Sans ; l'en-tête et la barre de question gardent la police du poste : DejaVu est moins large que Verdana, R1 « invite tronquée » rougirait sans rapport avec la visite), la contrainte du runner Linux (DejaVu Sans, plus large que macOS) reproduite sur n'importe quel poste ; mêmes assertions
    if (process.env.RESP_POLICE) await s.ev("(() => { const st = document.createElement('style'); st.id = 'vf-police-large'; st.textContent = '#tour, #tour *, #context, #context *, #svg * { font-family: Verdana, \\'DejaVu Sans\\', sans-serif !important; letter-spacing: 0.06em !important; }'; document.head.appendChild(st); })()");
    // la visite d'office s'ouvre 700 ms après le rendu (plus tard sous une machine lente) : on attend qu'elle soit ouverte, ou qu'elle ait eu tout son temps pour l'être (onglet Équipe, lien vers un endroit précis, ou graphe trop petit : elle ne s'ouvre pas), PUIS on mesure ; jamais marquée « vue » d'avance (70-07, classe visite / surfaces)
    await s.attendre("(() => { if (document.body.classList.contains('vf-tab-equipe') || location.hash.length > 1) return true; return !!window.VibeFlowTour && window.VibeFlowTour.active(); })()", `visite d'office ouverte ou écartée à ${w} px`, 1800).catch(() => {});
    // RESP_COURSE=1 : le graphe est en transit, avec un ARRÊT de 700 ms au milieu (un runner lent fige un moment l'animation : deux relevés espacés de 250 ms y sont identiques) : 400 px -> 250 px en 1,3 s, immobile 700 ms (de 1,3 s à 2 s), 250 px -> 0 en 500 ms.
    // Sans l'attente de calme ci-dessous, la mesure prise pendant l'arrêt voit le graphe décalé (carte hors de la zone libre).
    if (process.env.RESP_COURSE) await s.ev("(() => { const sv = document.getElementById('svg'); const t0 = performance.now(); const f = (t) => { const d = t - t0; const x = d < 1300 ? 400 - 150 * d / 1300 : d < 2000 ? 250 : d < 2500 ? 250 * (1 - (d - 2000) / 500) : 0; sv.style.transform = x ? 'translateX(' + Math.round(x) + 'px)' : ''; if (d < 2500) requestAnimationFrame(f); }; requestAnimationFrame(f); })()");
    await calme(w);
    if (process.env.RESP_INJECT) { await s.ev(process.env.RESP_INJECT); await calme(w); } };
  for (const w of largeurs.split(',').map(Number)) { await charger(w); await mesurer(String(w)); }
  if (resize && resize !== '-') {
    const [a, b] = resize.split(':').map(Number);
    await charger(a); await taille(b); await calme(b); await mesurer(`resize:${a}:${b}`); // le re-cadrage qui suit un redimensionnement se pose comme celui d'un chargement : calme() avant de mesurer
    await taille(a); await calme(a); await mesurer(`resize:${b}:${a}`);
  }
  return { mesures };
});
