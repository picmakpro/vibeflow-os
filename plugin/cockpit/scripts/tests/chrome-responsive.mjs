// chrome-responsive.mjs — mesure de la mise en page du cockpit à plusieurs largeurs (CKPT-12, P67-D-21). Aucune dépendance.
// Usage : node chrome-responsive.mjs <chrome> <url> <largeurs> <resize|-> [<dossierCaptures>]
//   <largeurs>  « 1024,1280,1440,1920 » : un chargement par largeur, hauteur déduite (16:10 environ)
//   <resize>    « 1920:1024 » : charge à la première largeur puis redimensionne À CHAUD à la seconde, puis revient ; « - » = rien
// Rend sur une ligne { mesures: { "<largeur>" | "resize:<a>:<b>" | "resize:<b>:<a>": { v: [violations], m: {chiffres} } } } ou { erreur }.
// Une violation = deux éléments frères visibles qui se recouvrent, un texte rogné (scrollWidth > clientWidth), un élément hors de la fenêtre,
// un bouton ou lien d'en-tête qui sort de la fenêtre (x + largeur > innerWidth), une recherche, un logo ou une barre de question sous leur taille minimale (sur plusieurs lignes tolérée sous 1 000 px : le gabarit étroit du viewer). RESP_INJECT : expression évaluée après le chargement (boutons d'en-tête optionnels de l'onglet Code, absents d'un lab de test). Le HOME réel est rendu à Chrome (REAL_HOME).
import fs from 'node:fs'; import path from 'node:path';
import { executer } from './chrome-session.mjs';
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
  const charger = async (w) => { await taille(w); await s.naviguer(url); await s.attendre(PRET, `page prête à ${w} px`); if (process.env.RESP_INJECT) await s.ev(process.env.RESP_INJECT); };
  for (const w of largeurs.split(',').map(Number)) { await charger(w); await mesurer(String(w)); }
  if (resize && resize !== '-') {
    const [a, b] = resize.split(':').map(Number);
    await charger(a); await taille(b); await mesurer(`resize:${a}:${b}`);
    await taille(a); await mesurer(`resize:${b}:${a}`);
  }
  return { mesures };
});
