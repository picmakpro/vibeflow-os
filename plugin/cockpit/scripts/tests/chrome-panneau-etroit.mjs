// chrome-panneau-etroit.mjs <chrome> <url de project.html> — le panneau de détail de 701 à 999 px, au GESTE RÉEL (Input.dispatchMouseEvent, Input.dispatchKeyEvent, jamais un évènement fabriqué).
// Revue de la recette du 2026-11-08 (lot B, PU-G-045) : P1 la préférence « panneau ouvert » du bureau n'est écrite que par le bouton « Détail » · P2 la palette au clavier amène le focus dans le panneau ·
// P3 un rendu de la même sélection, peu après la fermeture par « Détail », ne rouvre rien · P4 ouvrir le panneau par une sélection replie le tiroir Git · S7 Échap referme le panneau SANS effacer la sélection.
// Rend sur une ligne { p1, p2, p3, p4, s7 } (chaînes courtes à comparer mot pour mot) ou { erreur }. Chaque scénario repart d'un stockage vide.
import { executer, pause, attendreValeur } from './chrome-session.mjs';
const [, , chrome, url] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";
const CODES = { Tab: [9, 'Tab'], Escape: [27, 'Escape'], Enter: [13, 'Enter'], '/': [191, 'Slash'], g: [71, 'KeyG'] };
const touche = async (s, k) => {
  const [vk, code] = CODES[k]; const base = { key: k, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk };
  await s.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', ...base });
  if (k === 'Enter' || k === '/' || k === 'g') await s.send('Input.dispatchKeyEvent', { type: 'char', text: k === 'Enter' ? '\r' : k, ...base });
  await s.send('Input.dispatchKeyEvent', { type: 'keyUp', ...base });
};
const clic = async (s, x, y) => {
  await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
  await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
};
const OUVERT = "!document.body.classList.contains('no-panel') && getComputedStyle(document.getElementById('panel')).visibility === 'visible'";
const CENTRE = (expr) => `(() => { const e = ${expr}; if (!e) return null; const b = e.getBoundingClientRect(); return b.width > 0 ? { x: b.x + b.width / 2, y: b.y + b.height / 2 } : null; })()`;
const CARTE = "[...document.querySelectorAll('#svg g.node')].find((e) => { const b = e.getBoundingClientRect(); return b.width > 0 && b.left > 40; })";
const STORE = "(Object.keys(localStorage).filter((k) => /:panel$/.test(k)).map((k) => k + '=' + localStorage.getItem(k)).join(',') || 'aucune')";

await executer(chrome, async (s) => {
  const out = {};
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const charger = async (w) => { // la page se juge posée : visite fermée, graphe et cadrage stables
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 800, deviceScaleFactor: 1, mobile: false });
    await s.naviguer(url); await s.attendre(PRET, `page prête à ${w} px`);
    await pause(1500); await s.stable('performance.timeOrigin', 'page posée');
    await s.ev('window.VibeFlowTour && window.VibeFlowTour.active() && window.VibeFlowTour.end(false)'); await pause(300);
  };
  const vider = async () => { await s.naviguer(url); await s.ev('localStorage.clear()'); };
  const ouvert = () => s.ev(OUVERT);
  const attendreOuvert = (v) => attendreValeur(ouvert, (x) => x === v, { max: 4000 });
  const clicCarte = async () => { const c = await s.ev(CENTRE(CARTE)); if (!c) throw new Error('aucune carte visible'); await clic(s, c.x, c.y); };
  const clicDetail = async () => { const c = await s.ev(CENTRE("document.getElementById('btn-panel')")); if (!c) throw new Error('bouton Détail invisible'); await clic(s, c.x, c.y); };

  // P1 : choisir une carte, puis Échap, n'écrivent PAS la préférence ; « Détail » l'écrit (témoin : la clé existe) ; le rechargement à 768 puis à 1 440 px suit le défaut de chaque largeur
  await vider(); await charger(768);
  await clicCarte(); const choix = await attendreOuvert(true);
  const aprChoix = await s.ev(STORE);
  await touche(s, 'Escape'); const ferme = await attendreOuvert(false);
  const aprEchap = await s.ev(STORE);
  await charger(768); const defaut768 = await ouvert();
  await charger(1440); const bureau = await attendreOuvert(true);
  await vider(); await charger(768);
  await clicCarte(); await attendreOuvert(true); await clicDetail(); await attendreOuvert(false);
  const aprDetail = await s.ev(STORE);
  out.p1 = [choix, aprChoix, ferme, aprEchap, defaut768, bureau, aprDetail].join('|');

  // P2 : par la palette (« / », saisie, Entrée), au clavier réel, le focus entre dans le panneau ouvert
  await vider(); await charger(768);
  const nom = await s.ev(`(() => { const e = ${CARTE}; const t = (e.textContent || '').split(/\\s+/).find((m) => /^[A-Za-zÀ-ÿ]{4,}$/.test(m)); return t || ''; })()`);
  await s.ev('document.activeElement && document.activeElement.blur()');
  await touche(s, '/'); await s.attendre("document.getElementById('palette').classList.contains('open')", 'palette ouverte');
  await s.send('Input.insertText', { text: nom }); await pause(400); await touche(s, 'Enter');
  const o2 = await attendreOuvert(true);
  const foc = await attendreValeur(() => s.ev("document.getElementById('panel').contains(document.activeElement)"), (v) => v === true, { max: 4000 }).catch(() => false);
  await pause(1200); // le recentrage de la carte (reveal) rend le focus à la carte après l'animation : on juge une fois posé
  const foc2 = await s.ev("document.getElementById('panel').contains(document.activeElement)");
  out.p2 = [!!nom, o2, foc, foc2].join('|');

  // P3 : « Détail » ferme, un rendu de la MÊME sélection 150 ms plus tard ne rouvre rien ; choisir une AUTRE carte rouvre (témoin)
  await vider(); await charger(768);
  await clicCarte(); await attendreOuvert(true);
  await clicDetail(); await attendreOuvert(false); await pause(150);
  await s.ev('window.VibeFlow.rerender()'); await pause(700);
  const apresRendu = await ouvert();
  const cartes = await s.ev(`[...document.querySelectorAll('#svg g.node')].filter((e) => { const b = e.getBoundingClientRect(); return b.width > 0 && b.left > 40; }).map((e) => { const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; })`);
  if (cartes.length < 2) throw new Error('moins de deux cartes visibles');
  await clic(s, cartes[1].x, cartes[1].y); const autre = await attendreOuvert(true);
  out.p3 = [apresRendu, autre].join('|');

  // P4 : le tiroir Git est ouvert (touche g) ; une sélection ouvre le panneau et replie le tiroir Git, à 768 puis à 999 px
  const p4 = [];
  for (const w of [768, 999]) {
    await vider(); await charger(w);
    await s.ev('document.activeElement && document.activeElement.blur()'); await touche(s, 'g');
    await s.attendre("!!window.VFGitTiroir && window.VFGitTiroir.ouvert()", 'tiroir Git ouvert');
    const id = await s.ev("(() => { const l = [...window.VibeFlow.state.chipEls.entries()].find(([, g]) => g.getBoundingClientRect().width > 0 && g.getBoundingClientRect().left > 40); return l ? l[0] : ''; })()");
    if (!id) throw new Error('aucune carte visible pour la sélection');
    await s.ev(`window.VibeFlow.select(${JSON.stringify(id)})`);
    const o = await attendreOuvert(true);
    await pause(400);
    p4.push([w, o, await s.ev('window.VFGitTiroir.ouvert()')].join(':'));
  }
  out.p4 = p4.join('|');

  // P4 bis : le panneau est ouvert par une sélection, puis Git s'ouvre (touche g réelle, puis clic réel sur l'ouvreur) : le panneau se replie, la sélection reste, la préférence n'est pas écrite, et il ne se rouvre pas quand Git se referme
  const p4b = [];
  for (const [w, via] of [[768, 'touche'], [999, 'clic']]) {
    await vider(); await charger(w);
    await clicCarte(); await attendreOuvert(true);
    const sel = await s.ev('JSON.stringify(window.VibeFlow.state.selected ?? null)');
    await s.ev('document.activeElement && document.activeElement.blur()');
    if (via === 'touche') await touche(s, 'g');
    else { const c = await s.ev(CENTRE("[document.getElementById('vf-git-ouvreur'), document.getElementById('vf-git-ligne')].find((e) => e && e.getBoundingClientRect().width > 0)")); if (!c) throw new Error('aucun ouvreur Git visible'); await clic(s, c.x, c.y); }
    await s.attendre('window.VFGitTiroir.ouvert()', 'tiroir Git ouvert');
    const ferme = await attendreOuvert(false);
    const garde = (await s.ev('JSON.stringify(window.VibeFlow.state.selected ?? null)')) === sel;
    const mem = await s.ev(STORE);
    await s.ev('document.activeElement && document.activeElement.blur()'); await touche(s, 'g'); await s.attendre('!window.VFGitTiroir.ouvert()', 'tiroir Git refermé'); await pause(500);
    p4b.push([w, via, ferme, garde, mem, await ouvert()].join(':'));
  }
  out.p4b = p4b.join('|');

  // S7 : la sélection est choisie à la souris, Échap (focus au corps de la page) referme le panneau, la sélection reste
  await vider(); await charger(768);
  await clicCarte(); await attendreOuvert(true);
  const avant = await s.ev('JSON.stringify(window.VibeFlow.state.selected ?? null)');
  await s.ev('document.activeElement && document.activeElement.blur()');
  await touche(s, 'Escape'); const f7 = await attendreOuvert(false); await pause(300);
  const apres = await s.ev('JSON.stringify(window.VibeFlow.state.selected ?? null)');
  out.s7 = [avant !== 'null', f7, apres === avant].join('|');
  return out;
});
