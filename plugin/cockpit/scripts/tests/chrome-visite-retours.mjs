// chrome-visite-retours.mjs — témoins des retours du panel sur la visite guidée et le bouton de thème (lot « visite et thème »).
// Usage : node chrome-visite-retours.mjs <chrome> <urlCode> <largeur> <scenario>      scenario : theme | visite | tiroir | focus
//   theme    : texte du bouton de thème à l'arrivée puis après chaque clic souris réel (Auto, Clair, Sombre attendus)
//   visite   : visite ouverte d'office, parcourue jusqu'au bout ; par étape : croix (nom accessible), largeur de la feuille, « Étape n sur N » sur une ligne,
//              largeur à l'écran de la carte présentée, cadre dessiné autour du titre, boutons éclairés (.tour-target.lit), cartes éclairées visibles
//   tiroir   : le tiroir Git est ouvert pendant la visite, puis UNE seule Échap réelle : le tiroir doit être fermé
//   focus    : clic souris réel sur le bouton de visite (rouvre la visite), puis une flèche : le bouton ne doit pas porter d'anneau (:focus-visible) ;
//              activé au clavier (Entrée), il le garde
// Rend une ligne JSON ou { erreur }.
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, url, largeur = '1440', scenario = 'visite'] = process.argv;
const W = Number(largeur), HAUT = { 390: 844, 1000: 760, 1280: 800, 1440: 900 };
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlowTour && !!document.getElementById('tour-btn') && !!window.__vfModele && !!window.__vfModele.modele";
const OUVERTE = "(() => { const t = document.getElementById('tour'); return !!t && !t.hidden; })()";
const KEY = { Escape: 27, ArrowRight: 39, Enter: 13, Tab: 9 };
await executer(chrome, async (s) => {
  await s.send('Emulation.setDeviceMetricsOverride', { width: W, height: HAUT[W] || 800, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(url); await s.attendre(PRET, 'page prête');
  const touche = async (k) => { for (const t of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type: t, key: k, code: k, windowsVirtualKeyCode: KEY[k], ...(k === 'Enter' && t === 'keyDown' ? { text: '\r' } : {}) }); };
  const clic = async (sel) => { const r = await s.ev(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; const b = e.getBoundingClientRect(); return [b.x + b.width / 2, b.y + b.height / 2]; })()`); if (!r) return false; for (const t of ['mouseMoved', 'mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type: t, x: r[0], y: r[1], button: 'left', clickCount: 1 }); return true; };
  if (scenario === 'theme') {
    const lire = () => s.ev("(() => { const b = document.getElementById('theme-toggle'); return b ? (b.querySelector('.theme-word') || {}).textContent || b.innerText : null; })()");
    const textes = [await lire()];
    for (let i = 0; i < 3; i++) { await clic('#theme-toggle'); await pause(400); textes.push(await lire()); }
    return { textes };
  }
  await s.attendre(OUVERTE, 'visite ouverte d\'office', 30000);
  if (scenario === 'tiroir') {
    await s.ev('window.VFGitTiroir.ouvrir()'); await pause(600);
    const avant = await s.ev('({ tiroir: window.VFGitTiroir.ouvert(), visite: window.VibeFlowTour.active() })');
    await touche('Escape'); await pause(500);
    const apres = await s.ev('({ tiroir: window.VFGitTiroir.ouvert(), visite: window.VibeFlowTour.active() })');
    return { avant, apres };
  }
  if (scenario === 'focus') {
    await s.ev('window.VibeFlowTour.end()'); await pause(300);
    const info = () => s.ev("(() => { const b = document.getElementById('tour-btn'); return { actif: document.activeElement === b, fv: b.matches(':focus-visible'), ouverte: window.VibeFlowTour.active() }; })()");
    await clic('#tour-btn'); await s.attendre(OUVERTE, 'visite rouverte à la souris'); await pause(300);
    const souris0 = await info(); await touche('ArrowRight'); await pause(300); const souris1 = await info();
    await s.ev('window.VibeFlowTour.end()'); await pause(300);
    await touche('Tab'); await s.ev("document.getElementById('tour-btn').focus()"); await touche('Enter'); await pause(500);
    const clavier = await info();
    return { souris0, souris1, clavier };
  }
  // visite : parcours
  const mesure = () => s.ev(`(() => {
    const SC = window.VibeFlow, card = document.getElementById('tour'), R = (e) => { const r = e.getBoundingClientRect(); return { l: r.left, t: r.top, r: r.right, b: r.bottom, w: r.width, h: r.height }; };
    const x = card.querySelector('[data-x].tx'), cr = R(card);
    const spans = [...card.querySelectorAll('.tk span')].map((e) => ({ t: e.textContent, h: Math.round(R(e).h) }));
    const lit = [...document.querySelectorAll('.tour-target.lit')].map((e) => R(e));
    const ctx = R(document.getElementById('context'));
    const cadres = [...document.querySelectorAll('.tour-target')].filter((e) => !e.classList.contains('lit')).map((e) => ({ r: R(e), contour: getComputedStyle(e).outlineStyle, fond: getComputedStyle(e).backgroundColor }));
    const hl = SC.state.chipEls ? [...SC.state.chipEls.values()].filter((g) => g.classList.contains('hl')).map((g) => R(g)) : [];
    const bt = document.getElementById('tour-btn'), btr = bt ? R(bt) : null;
    return { croix: x ? x.getAttribute('aria-label') : null, carte: { l: Math.round(cr.l), r: Math.round(cr.r), b: Math.round(cr.b), w: Math.round(cr.w) }, ecran: [innerWidth, innerHeight],
      repere: spans.map((e) => e.t).join(' | '), repereHauteurs: spans.map((e) => e.h), litBoutons: lit.length, litSurTour: !!btr && lit.some((l) => Math.abs(l.l - btr.l) < 2 && Math.abs(l.w - btr.w) < 2),
      cadreSurTitre: cadres.some((c) => Math.abs(c.r.l - ctx.l) < 2 && Math.abs(c.r.w - ctx.w) < 2 && (c.contour !== 'none')),
      contours: cadres.map((c) => c.contour), cartesEclairees: hl.length, largeurCartes: hl.map((r) => Math.round(r.w)), dansFenetre: hl.every((r) => r.l >= 0 && r.r <= innerWidth && r.t >= 0 && r.b <= innerHeight) };
  })()`);
  const etapes = [];
  for (let i = 0; i < 12; i++) {
    await pause(1600); etapes.push(await mesure());
    const dernier = await s.ev("!!document.querySelector('#tour [data-next]') && /^(Done|Terminé)$/.test(document.querySelector('#tour [data-next]').textContent.trim())");
    if (dernier) break;
    await s.ev("document.querySelector('#tour [data-next]').click()");
  }
  return { n: etapes.length, etapes };
}, {});
