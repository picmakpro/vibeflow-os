// chrome-visite-retours.mjs — témoins des retours du panel sur la visite guidée et le bouton de thème (lot « visite et thème »).
// Usage : node chrome-visite-retours.mjs <chrome> <urlCode> <largeur> <scenario>      scenario : theme | visite | tiroir | focus | fin | fin-sans
//   theme    : texte du bouton de thème à l'arrivée puis après chaque clic souris réel (Auto, Clair, Sombre attendus)
//   visite   : visite ouverte d'office, parcourue jusqu'au bout ; par étape : croix (nom accessible), largeur de la feuille, « Étape n sur N » sur une ligne,
//              largeur à l'écran de la carte présentée, cadre dessiné autour du titre, boutons éclairés (.tour-target.lit), cartes éclairées visibles
//   tiroir   : le tiroir Git est ouvert pendant la visite, puis UNE seule Échap réelle : le tiroir doit être fermé
//   fin      : fin de visite avec le terminal (pastille) après un redimensionnement PENDANT la visite (fin-sans : sans redimensionnement) : le zoom, la pastille et la barre ne se recouvrent pas
//   focus    : clic souris réel sur le bouton de visite (rouvre la visite), puis une flèche : le bouton ne doit pas porter d'anneau (:focus-visible) ;
//              activé au clavier (Entrée), il le garde
// Rend une ligne JSON ou { erreur }.
import { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } from './chrome-session.mjs';
const [, , chrome, url, largeur = '1440', scenario = 'visite'] = process.argv;
const W = Number(largeur), HAUT = { 390: 844, 1000: 760, 1280: 800, 1440: 900 };
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlowTour && !!document.getElementById('tour-btn') && !!window.__vfModele && !!window.__vfModele.modele";
const OUVERTE = "(() => { const t = document.getElementById('tour'); return !!t && !t.hidden; })()";
const KEY = { Escape: 27, ArrowRight: 39, Enter: 13, Tab: 9 };
await executer(chrome, async (s) => {
  await s.send('Emulation.setDeviceMetricsOverride', { width: W, height: HAUT[W] || 800, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(url); await s.attendre(PRET, 'page prête');
  const touche = async (k) => { for (const t of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type: t, key: k, code: k, windowsVirtualKeyCode: KEY[k], ...(k === 'Enter' && t === 'keyDown' ? { text: '\r' } : {}) }); };
  // le centre du bouton est lu une fois posé (deux relevés égaux), jamais dans la foulée d'un changement de mise en page
  const clic = async (sel) => { const p = await positionPosee(s.ev, `document.querySelector(${JSON.stringify(sel)})`); if (!p) return false; for (const t of ['mouseMoved', 'mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type: t, x: p.cx, y: p.cy, button: 'left', clickCount: 1 }); return true; };
  if (scenario === 'theme') {
    const lire = () => s.ev("(() => { const b = document.getElementById('theme-toggle'); return b ? (b.querySelector('.theme-word') || {}).textContent || b.innerText : null; })()");
    const textes = [await stabiliser(lire, { pas: 150, max: 3000 })];
    for (let i = 0; i < 3; i++) { const prec = textes[textes.length - 1]; await clic('#theme-toggle'); textes.push(await attendreEtStabiliser(lire, (v) => v !== prec, { pas: 150, max: 3000 })); }
    return { textes };
  }
  await s.attendre(OUVERTE, 'visite ouverte d\'office', 30000);
  if (scenario === 'tiroir') {
    await s.ev('window.VFGitTiroir.ouvrir()');
    const lireT = () => s.ev('({ tiroir: window.VFGitTiroir.ouvert(), visite: window.VibeFlowTour.active() })');
    const avant = await attendreEtStabiliser(lireT, (v) => v && v.tiroir === true, { pas: 150, max: 3000 });
    await touche('Escape');
    const apres = await attendreEtStabiliser(lireT, (v) => v && v.tiroir === false, { pas: 150, max: 3000 });
    return { avant, apres };
  }
  if (scenario === 'focus') {
    await s.ev('window.VibeFlowTour.end()'); await attendreValeur(() => s.ev(OUVERTE), (v) => v === false, { max: 3000 });
    const info = () => s.ev("(() => { const b = document.getElementById('tour-btn'); return { actif: document.activeElement === b, fv: b.matches(':focus-visible'), ouverte: window.VibeFlowTour.active() }; })()");
    await clic('#tour-btn'); await s.attendre(OUVERTE, 'visite rouverte à la souris'); await positionPosee(s.ev, "document.getElementById('tour')");
    const souris0 = await info(); await touche('ArrowRight'); await pause(300); const souris1 = await stabiliser(info, { pas: 120, max: 3000 }); // la pause reste : fv doit rester FAUX (absence d'anneau)
    await s.ev('window.VibeFlowTour.end()'); await attendreValeur(() => s.ev(OUVERTE), (v) => v === false, { max: 3000 });
    await touche('Tab'); await s.ev("document.getElementById('tour-btn').focus()"); await touche('Enter');
    const clavier = await attendreEtStabiliser(info, (v) => v && v.ouverte === true, { pas: 150, max: 3000 });
    return { souris0, souris1, clavier };
  }
  if (scenario === 'fin' || scenario === 'fin-sans') {
    // I-1 (intégration, revue du lot A) : pendant la visite, une règle !important (ui/02, data-vf-visite) masque le style en ligne du zoom ; si la fenêtre bouge, eviter() (terminal-tiroir) le vide faute de recouvrement visible,
    // et à la fin de la visite le zoom retombait sur la pastille jusqu'au redimensionnement suivant. 'fin' : un redimensionnement PENDANT la visite ; 'fin-sans' : aucun. On mesure une fois la fin de visite posée.
    const recouvrements = () => s.ev(`(() => { const R = (e) => { if (!e || e.hidden) return null; const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 ? r : null; };
      const z = R(document.getElementById('zoom')), p = R(document.querySelector('.vf-term-pastille')), a = R(document.getElementById('ask'));
      const sur = (x, y) => !!x && !!y && x.left < y.right && x.right > y.left && x.top < y.bottom && x.bottom > y.top;
      return { visite: document.documentElement.hasAttribute('data-vf-visite'), pastille: !!p, zoomPastille: sur(z, p), zoomBarre: sur(z, a), pastilleBarre: sur(p, a) }; })()`);
    const pendant = await stabiliser(recouvrements, { pas: 300, max: 6000 });
    if (scenario === 'fin') { await s.ev("window.dispatchEvent(new Event('resize'))"); await stabiliser(recouvrements, { pas: 300, max: 6000 }); }
    await s.ev('window.VibeFlowTour.end()');
    const apres = await attendreEtStabiliser(recouvrements, (v) => v && v.visite === false, { pas: 300, max: 6000 });
    return { pendant, apres };
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
    const tb = card.querySelector('.tb'), tf = card.querySelector('.tf'), zr = document.getElementById('zoom').getBoundingClientRect(), pa = document.querySelector('.vf-term-pastille'), par = pa ? pa.getBoundingClientRect() : null;
    const lisible = { texteEntier: tb.scrollHeight <= tb.clientHeight + 1, texteBas: Math.round(R(tb).b), boutonsHaut: Math.round(R(tf).t), carteH: Math.round(cr.h), carteHaut: Math.round(cr.t), zoomBas: Math.round(zr.bottom), pastille: !!par && par.width > 0 && !pa.hidden, pastilleHaut: par ? Math.round(par.top) : null };
    return { lisible, croix: x ? x.getAttribute('aria-label') : null, carte: { l: Math.round(cr.l), r: Math.round(cr.r), b: Math.round(cr.b), w: Math.round(cr.w) }, ecran: [innerWidth, innerHeight],
      repere: spans.map((e) => e.t).join(' | '), repereHauteurs: spans.map((e) => e.h), litBoutons: lit.length, litSurTour: !!btr && lit.some((l) => Math.abs(l.l - btr.l) < 2 && Math.abs(l.w - btr.w) < 2),
      cadreSurTitre: cadres.some((c) => Math.abs(c.r.l - ctx.l) < 2 && Math.abs(c.r.w - ctx.w) < 2 && (c.contour !== 'none')),
      contours: cadres.map((c) => c.contour), cartesEclairees: hl.length, largeurCartes: hl.map((r) => Math.round(r.w)), dansFenetre: hl.every((r) => r.l >= 0 && r.r <= innerWidth && r.t >= 0 && r.b <= innerHeight) };
  })()`);
  const etapes = []; let precRepere = null;
  for (let i = 0; i < 12; i++) {
    // la caméra et la feuille bougent après chaque étape : on attend le repère de la NOUVELLE étape, puis une mesure stable
    const m = i === 0 ? await stabiliser(mesure, { pas: 400, max: 8000 }) : await attendreEtStabiliser(mesure, (v) => v && v.repere !== precRepere, { pas: 400, max: 8000 });
    etapes.push(m); precRepere = m && m.repere;
    const dernier = await s.ev("!!document.querySelector('#tour [data-next]') && /^(Done|Terminé)$/.test(document.querySelector('#tour [data-next]').textContent.trim())");
    if (dernier) break;
    await s.ev("document.querySelector('#tour [data-next]').click()");
  }
  return { n: etapes.length, etapes };
}, {});
