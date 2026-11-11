// chrome-panneau-etroit.mjs <chrome> <url de project.html> — le panneau de détail de 701 à 999 px, au GESTE RÉEL (Input.dispatchMouseEvent, Input.dispatchKeyEvent, jamais un évènement fabriqué).
// Revue de la recette du 2026-11-08 (lot B, PU-G-045) : P1 la préférence « panneau ouvert » du bureau n'est écrite que par le bouton « Détail » · P2 la palette au clavier amène le focus dans le panneau ·
// P3 un rendu de la même sélection, peu après la fermeture par « Détail », ne rouvre rien · P4 ouvrir le panneau par une sélection replie le tiroir Git · S7 Échap referme le panneau SANS effacer la sélection.
// F1 (3e tour) : fermé par « Détail », un glisser sur le fond (souris réelle, doigt réel, pincement) ne rouvre rien, un rendu non plus ; un clic réel sur une carte rouvre (témoin) · F5 : « Détail » (clavier, clic réel) avec Git ouvert replie Git.
// Rend sur une ligne { p1, p2, p3, p4, p4b, s7, f1, f5, j6, j6s, j6k } (chaînes courtes à comparer mot pour mot) ou { erreur }. Chaque scénario repart d'un stockage vide.
import { executer, pause, attendreValeur } from './chrome-session.mjs';
const [, , chrome, url] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";
const CODES = { Tab: [9, 'Tab'], Escape: [27, 'Escape'], Enter: [13, 'Enter'], '/': [191, 'Slash'], g: [71, 'KeyG'], ' ': [32, 'Space'] };
const touche = async (s, k) => {
  const [vk, code] = CODES[k]; const base = { key: k, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk };
  await s.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', ...base });
  if (k === 'Enter' || k === '/' || k === 'g' || k === ' ') await s.send('Input.dispatchKeyEvent', { type: 'char', text: k === 'Enter' ? '\r' : k, ...base });
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
const toucher = async (s, type, points) => s.send('Input.dispatchTouchEvent', { type, touchPoints: points.map((p, i) => ({ x: p.x, y: p.y, id: i + 1 })) });
const glisserSouris = async (s, { x, y }) => { // un glisser au pointeur réel sur le fond du graphe (le pan du viewer)
  await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
  await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  for (let i = 1; i <= 6; i++) await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: x + i * 12, y: y + i * 6, button: 'left', buttons: 1 });
  await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: x + 72, y: y + 36, button: 'left', clickCount: 1 });
};
const glisserDoigt = async (s, { x, y }) => { // le même glisser au toucher réel
  await toucher(s, 'touchStart', [{ x, y }]);
  for (let i = 1; i <= 6; i++) await toucher(s, 'touchMove', [{ x: x + i * 12, y: y + i * 6 }]);
  await toucher(s, 'touchEnd', []);
};
const pincer = async (s, { x, y }) => { // un pincement à deux doigts sur le fond
  await toucher(s, 'touchStart', [{ x, y }, { x: x + 40, y }]);
  for (let i = 1; i <= 5; i++) await toucher(s, 'touchMove', [{ x: x - i * 6, y }, { x: x + 40 + i * 6, y }]);
  await toucher(s, 'touchEnd', []);
};
const VIDE = `(() => { const n = [...document.querySelectorAll('#svg g.node')].map((e) => e.getBoundingClientRect()); for (let y = 200; y < 700; y += 40) for (let x = 60; x < 700; x += 40) { if (!n.some((b) => x > b.left - 20 && x < b.right + 20 && y > b.top - 20 && y < b.bottom + 20)) { const el = document.elementFromPoint(x, y); if (el && el.closest('#svg') && el.closest('#svg').id === 'svg') return { x, y }; } } return null; })()`;
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

  // F1 : fermé par « Détail », un glisser sur le fond du graphe (souris réelle, puis doigt réel, puis pincement) ne rouvre rien, ni le rendu qui suit ; un vrai clic sur la carte choisie la rouvre (témoin)
  await vider(); await charger(768);
  await clicCarte(); await attendreOuvert(true); await clicDetail(); await attendreOuvert(false);
  const vide = await s.ev(VIDE); if (!vide) throw new Error('aucun point de fond libre');
  const f1 = [];
  const fermer = async () => { if (await ouvert()) { await clicDetail(); await attendreOuvert(false); } }; // chaque geste repart d'un panneau fermé par « Détail » : un geste qui le rouvre ne masque pas les suivants
  const geste = async (f) => { await fermer(); await f(); await pause(400); f1.push(await ouvert()); await s.ev('window.VibeFlow.rerender()'); await pause(700); f1.push(await ouvert()); };
  await geste(() => glisserSouris(s, vide));
  await s.send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
  await geste(() => glisserDoigt(s, vide));
  await geste(() => pincer(s, vide));
  await s.send('Emulation.setTouchEmulationEnabled', { enabled: false });
  await fermer(); await s.ev('window.VibeFlow.fit(true)'); await pause(1200); // le pan et le pincement ont déplacé le graphe : on le recadre avant le témoin
  const dansVue = `[...document.querySelectorAll('#svg g.node')].find((e) => { const b = e.getBoundingClientRect(), x = b.x + b.width / 2, y = b.y + b.height / 2; if (!(b.width > 0 && x > 40 && x < innerWidth - 40 && y > 120 && y < innerHeight - 60)) return false; const h = document.elementFromPoint(x, y); return !!h && h.closest('g.node') === e; })`; // une carte dont le centre est dans la fenêtre ET qui reçoit le clic
  await clic(s, vide.x, vide.y); await pause(300); // le viewer avale le premier clic qui suit un pan au doigt (swallowClick) : un clic sur le fond le consomme, le témoin ci-dessous est le clic suivant
  const cv = await s.ev(CENTRE(dansVue)); if (!cv) throw new Error('aucune carte dont le centre reçoit le clic, pour le témoin');
  await clic(s, cv.x, cv.y); f1.push(await attendreOuvert(true));
  out.f1 = f1.join('|');

  // F5 : tiroir Git ouvert (touche g), « Détail » ouvre le panneau et replie Git, à 768 px (clavier : focus + Entrée) puis à 999 px (clic réel) ; au sommet, le panneau (jamais Git) ; la préférence est celle du bouton
  const f5 = [];
  for (const [w, via] of [[768, 'clavier'], [999, 'clic']]) {
    await vider(); await charger(w);
    await s.ev('document.activeElement && document.activeElement.blur()'); await touche(s, 'g');
    await s.attendre('!!window.VFGitTiroir && window.VFGitTiroir.ouvert()', 'tiroir Git ouvert');
    if (via === 'clavier') { await s.ev("document.getElementById('btn-panel').focus()"); await touche(s, 'Enter'); } else await clicDetail();
    const o = await attendreOuvert(true); await pause(400);
    const haut = await s.ev("(() => { const p = document.getElementById('panel').getBoundingClientRect(), e = document.elementFromPoint(p.x + p.width / 2, p.y + 200); return e ? (e.closest('#vf-git-tiroir') ? 'GIT' : e.closest('#panel') ? 'PANEL' : e.tagName) : null; })()");
    f5.push([w, via, o, await s.ev('window.VFGitTiroir.ouvert()'), haut, await s.ev(STORE)].join(':'));
  }
  out.f5 = f5.join('|');

  // J6 (passe de suivi) : un geste de palette qui ne choisit RIEN ne laisse aucun armement derrière lui. À 768 px : une carte choisie, « Détail » la referme, la palette (« / »), une saisie sans résultat, Entrée, Échap, puis un rendu : le panneau reste fermé
  await vider(); await charger(768);
  await clicCarte(); const j6a = await attendreOuvert(true); await clicDetail(); const j6b = await attendreOuvert(false);
  await s.ev('document.activeElement && document.activeElement.blur()');
  await touche(s, '/'); await s.attendre("document.getElementById('palette').classList.contains('open')", 'palette ouverte');
  await s.ev("(() => { const i = document.querySelector('#palette input'); i.focus(); i.value = 'zzzzqqqq'; i.dispatchEvent(new Event('input', { bubbles: true })); return true; })()"); await pause(400);
  const j6r = await s.ev("document.querySelectorAll('#results .r').length");
  await touche(s, 'Enter'); await pause(300); await touche(s, 'Escape');
  const j6c = await attendreValeur(() => s.ev("document.getElementById('palette').classList.contains('open')"), (v) => v === false, { max: 3000 });
  await s.ev('window.VibeFlow.rerender()'); await pause(800);
  out.j6 = [j6a, j6b, j6r === 0, j6c === false, await ouvert()].join('|');

  // J6, variante ESPACE (revue finale, M-C) : dans la saisie de la palette l'Espace est un caractère de la requête ; seule l'Entrée CHOISIT un résultat. Une saisie qui a des résultats, un Espace, Échap, un rendu : le panneau reste fermé (rouge sur b06a58be : « pha » + espace armait la réouverture)
  await vider(); await charger(768);
  await clicCarte(); const j6sa = await attendreOuvert(true); await clicDetail(); const j6sb = await attendreOuvert(false);
  await s.ev('document.activeElement && document.activeElement.blur()');
  await touche(s, '/'); await s.attendre("document.getElementById('palette').classList.contains('open')", 'palette ouverte');
  await s.ev("(() => { const i = document.querySelector('#palette input'); i.focus(); i.value = 'pha'; i.dispatchEvent(new Event('input', { bubbles: true })); return true; })()");
  const j6sr = await attendreValeur(() => s.ev("document.querySelectorAll('#results .r.active').length"), (v) => v >= 1, { max: 3000 }); // témoin : un résultat est actif, c'est ce qui armait l'Espace
  await touche(s, ' '); await pause(300); await touche(s, 'Escape');
  const j6sc = await attendreValeur(() => s.ev("document.getElementById('palette').classList.contains('open')"), (v) => v === false, { max: 3000 });
  await s.ev('window.VibeFlow.rerender()'); await pause(800);
  out.j6s = [j6sa, j6sb, j6sr >= 1, j6sc === false, await ouvert()].join('|');

  // J6, témoin du choix clavier HORS palette (F1) : une touche Entrée puis Espace sur une carte de #svg (un écouteur de la sonde choisit la carte, comme le ferait un choix au clavier) ouvrent le panneau fermé par « Détail »
  await vider(); await charger(768);
  await clicCarte(); await attendreOuvert(true);
  const j6k = [];
  for (const k of ['Enter', ' ']) {
    if (await ouvert()) { await clicDetail(); await attendreOuvert(false); }
    await s.ev(`(() => { const g = ${CARTE}; if (!g) return false; const id = window.VibeFlow.state.selected; g.setAttribute('tabindex', '-1'); if (!g.__k) { g.__k = true; g.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') window.VibeFlow.select(id); }); } g.focus({ preventScroll: true }); return document.activeElement === g; })()`);
    await touche(s, k); j6k.push(await attendreOuvert(true));
  }
  out.j6k = j6k.join('|');
  return out;
});
