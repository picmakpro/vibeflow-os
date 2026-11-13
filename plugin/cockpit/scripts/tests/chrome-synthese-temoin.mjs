// chrome-synthese-temoin.mjs — mesures du scénario « temoin » (77-05) : le module porte le bloc témoin du banc (ui/74-vf-synthese-temoin.js, copie du module).
// Appelé par chrome-synthese-scenarios.mjs après les mesures communes ; remplit r.<clé> ; les assertions vivent dans test-cockpit-synthese-page.sh.
import { pause, stabiliser, attendreValeur } from './chrome-session.mjs';
import { sondeStyle, mesurerUneFoisPose, ecrireStockageAvantChargement, MARQUEUR_RACINE } from './chrome-synthese.mjs';

const BTN = `document.getElementById('btn-synthese')`, OUVERTE = `!!document.querySelector('#panel > .vf-sy')`, SC = `window.VibeFlow`;
const FOCUS = `(() => { const a = document.activeElement; return a ? { tag: a.tagName, id: a.id || '', temoin: a.dataset.temoinBouton || '', dansSynth: !!a.closest('.vf-sy') } : null; })()`;
const BLOCS = `[...document.querySelectorAll('#panel > section.vf-sy[data-vf-sy-bloc]')].map((e) => e.dataset.vfSyBloc)`;
const LIGNE = `(() => { const l = [...document.querySelectorAll('[data-vf-sy-resume]')]; const h3 = [...document.querySelectorAll('#panel h3')].find((h) => /^Prochaines phases/.test(h.textContent));
  const e = l[0]; return { n: l.length, tag: e ? e.tagName : null, classes: e ? e.className : null, avantProchaines: !!(e && h3 && (e.compareDocumentPosition(h3) & Node.DOCUMENT_POSITION_FOLLOWING)),
    texte: e ? (e.querySelector('.rn') || {}).textContent : null, extras: e ? e.querySelectorAll('.badge, .vf-bar, .vst, .dot').length : -1, hauteur: e ? e.getBoundingClientRect().height : 0 }; })()`;
const touche = async (s, key, code, vk) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk }); };
const ouvrir = async (s) => { if (await s.ev(OUVERTE)) return; await s.ev(`${BTN}.click()`); await s.attendre(OUVERTE, 'Synthèse ouverte'); await pause(250); };
const fermer = async (s) => { if (!(await s.ev(OUVERTE))) return; await s.ev(`${BTN}.click()`); await attendreValeur(() => s.ev(`!${OUVERTE}`), (v) => v === true, { max: 3000 }); };
const largeur = async (s, w) => { await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(200); };
const ligneStable = (s) => stabiliser(() => s.ev(LIGNE), { max: 6000 });

export async function mesures(s, base, r, J) {
  const interdits = (process.env.SYNTH_INTERDITS || '').split('|').filter(Boolean);
  r.t0 = await s.ev('performance.timeOrigin'); r.racine = await s.ev(`String(${SC}.graph.meta.root || '').includes(${JSON.stringify(MARQUEUR_RACINE)})`);
  // ---- sondes positives des outils du banc ----
  r.sondes = { ecouteur: await s.ev(`(() => { const f = () => {}; document.addEventListener('x-sonde-77', f); const a = window.__nbEcout().document; document.removeEventListener('x-sonde-77', f); return a - window.__nbEcout().document; })()`) };
  await s.ev(`(() => { const st = document.createElement('style'); st.id = 'sonde-style-77'; st.textContent = 'body { background-color: rgb(12, 34, 56) !important }'; document.head.appendChild(st); })()`);
  r.sondes.style = (await sondeStyle(s, 'body', ['background-color']))['background-color']; await s.ev(`document.getElementById('sonde-style-77').remove()`);
  r.sondes.pose = await mesurerUneFoisPose(() => s.ev('document.title'), { max: 3000 });
  // ---- ligne-résumé, titre, registre (W18, R1, RB1) ----
  r.ligne = await ligneStable(s); r.titre = await s.ev(`${BTN}.title + '|' + ${BTN}.getAttribute('aria-label')`);
  r.ligneFocus = await s.ev(`(() => { const e = document.querySelector('[data-vf-sy-resume]'); e.focus(); return document.activeElement === e; })()`);
  await ouvrir(s);
  r.blocs = await s.ev(BLOCS); r.refIdentique = await s.ev(`window.__vfSyntheseBlocs === window.__vfTemoinRef`);
  r.blocsTexte = await s.ev(`[...document.querySelectorAll('#panel [data-temoin]')].map((e) => e.dataset.temoin + '=' + e.textContent).join()`);
  r.labelled = await s.ev(`[...document.querySelectorAll('#panel > section.vf-sy[data-vf-sy-bloc]')].every((e) => { const t = document.getElementById(e.getAttribute('aria-labelledby')); return !!t && t.tagName === 'H3' && t.id === 'vf-sy-t-' + e.dataset.vfSyBloc; })`);
  r.compte = await s.ev('window.__vfTemoinCompte()');
  // W10 : aucun chemin du poste dans le texte du panneau (la sonde positive : le marqueur est bien dans meta.root)
  const txt = await s.ev(`document.getElementById('panel').innerText`); r.interditsVus = interdits.filter((x) => txt.includes(x)); r.interditsGeneriques = /\/Users\/|\/home\/|\/var\/folders|\/private\/|[A-Za-z]:\\\\/.test(txt);
  // ---- W13a : l'arrivée de données ne bouge ni le focus ni le défilement ----
  await s.ev(`(() => { const p = document.getElementById('panel'); p.scrollTop = 150; document.querySelector('[data-temoin-bouton]').focus({ preventScroll: true }); })()`);
  r.avantRefresh = { focus: await s.ev(FOCUS), scroll: await s.ev(`document.getElementById('panel').scrollTop`) };
  await s.ev('window.__vfTemoinRafraichir()'); await pause(300);
  r.apresRefresh = { focus: await s.ev(FOCUS), scroll: await s.ev(`document.getElementById('panel').scrollTop`), texte: await s.ev(`document.querySelector('[data-temoin="visite"]').textContent`),
    titre: await s.ev(`${BTN}.title`), sr: await s.ev(`document.querySelector('#panel .vf-sy .sr').textContent`), ouverte: await s.ev(OUVERTE) };
  // ---- RB1 : un bloc inscrit APRÈS la coquille est rendu (au prochain affichage), en dernier ----
  await fermer(s);
  await s.ev(`window.__vfSyntheseBlocs.push(Object.freeze({ id: 'cout', titre: 'Titre cout', installer: () => () => {}, present: () => true, rendre: (c) => { c.textContent = 'T-apres'; }, ouvrir: () => {} }))`);
  await ouvrir(s); r.blocsApres = await s.ev(BLOCS); r.apresTexte = await s.ev(`(document.querySelector('[data-vf-sy-bloc="cout"]') || { textContent: '' }).textContent`);
  // ---- W3, W20 : le panneau garde sa largeur, le tiroir Git n'est pas touché, un autre contenu remplace la Synthèse, une carte sélectionnée la ferme ----
  const largeurPanneau = `Math.round(document.getElementById('panel').getBoundingClientRect().width * 10) / 10`, git = `(window.VFGitTiroir && window.VFGitTiroir.ouvert) ? !!window.VFGitTiroir.ouvert() : null`;
  r.tiroirAvant = await s.ev(git); r.largeurSynth = await s.ev(largeurPanneau);
  await s.ev(`${SC}.showPanel('<div class="vf-whop"><h3>Au travail</h3></div>', () => {})`); await pause(250);
  r.remplace = { synth: await s.ev(OUVERTE), whop: await s.ev(`!!document.querySelector('#panel > .vf-whop')`), expanded: await s.ev(`${BTN}.getAttribute('aria-expanded')`) };
  await s.ev(`${SC}.closePanel()`); await ouvrir(s);
  await s.ev(`(() => { const n = ${SC}.graph.nodes.find((x) => x.kind === 'phase') || ${SC}.graph.nodes[0]; ${SC}.select(n.id); })()`);
  await attendreValeur(() => s.ev(`!${OUVERTE}`), (v) => v === true, { max: 3000 });
  r.selection = { synth: await s.ev(OUVERTE), largeurDetail: await s.ev(largeurPanneau), expanded: await s.ev(`${BTN}.getAttribute('aria-expanded')`), tiroirApres: await s.ev(git) };
  await s.ev(`${SC}.closePanel()`); await pause(200);
  // ---- W14 : mouvement réduit ----
  await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] }); await ouvrir(s);
  r.mouvement = await s.ev(`(() => { const l = [${BTN}, ...document.querySelectorAll('.vf-sy, .vf-sy *')].filter(Boolean).map((e) => { const c = getComputedStyle(e);
    return { anim: c.animationName, trans: c.transitionDuration.split(',').every((d) => d.trim() === '0s') }; }); return { n: l.length, animations: l.filter((x) => x.anim !== 'none').length, transitions: l.filter((x) => !x.trans).length }; })()`);
  await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
  // ---- W16 : cibles de 44 px (≤ 999 px), pas de débordement horizontal ----
  await fermer(s); await largeur(s, 800);
  await s.ev(`(() => { const st = document.createElement('style'); st.id = 'sonde-visible-77'; st.textContent = '#hdr-ext > #btn-synthese { display: inline-flex !important }'; document.head.appendChild(st); })()`);
  r.cibles = { bouton: await s.ev(`${BTN}.getBoundingClientRect().height`), ligne: (await ligneStable(s)).hauteur };
  await ouvrir(s); r.cibles.fermer = await s.ev(`document.querySelector('#panel .vf-sy .btn').getBoundingClientRect().height`);
  r.debordPanneau = [await s.ev(`(() => { const p = document.getElementById('panel'); return p.scrollWidth <= p.clientWidth; })()`)];
  await s.ev(`document.getElementById('sonde-visible-77').remove()`); await fermer(s);
  // ---- W19 : l'en-tête ne déborde pas et ne prend pas une ligne de plus ----
  r.entete = [];
  for (const w of [1280, 1440, 1600, 1639, 1920]) {
    await largeur(s, w); const mesure = `(() => { const h = document.querySelector('header'); return { debord: h.scrollWidth > h.clientWidth, hauteur: Math.round(h.getBoundingClientRect().height) }; })()`;
    const avec = await stabiliser(() => s.ev(mesure)); await s.ev(`(() => { const st = document.createElement('style'); st.id = 'sonde-sans-77'; st.textContent = '#btn-synthese { display: none !important }'; document.head.appendChild(st); })()`);
    const sans = await stabiliser(() => s.ev(mesure)); await s.ev(`document.getElementById('sonde-sans-77').remove()`); r.entete.push({ w, debord: avec.debord, memeHauteur: avec.hauteur === sans.hauteur });
  }
  await largeur(s, 600); await s.ev(`document.getElementById('vf-plus').click()`); await s.attendre(`!!document.getElementById('vf-plus-menu')`, 'menu Plus d\'actions');
  r.menu = await s.ev(`[...document.querySelectorAll('#vf-plus-menu button')].filter((b) => /^Synthèse/.test(b.textContent.trim())).length`);
  await s.ev(`document.getElementById('vf-plus').click()`); await s.send('Emulation.clearDeviceMetricsOverride'); await pause(300);
  // ---- deux thèmes : le titre se lit sur le fond du panneau ----
  r.themes = [];
  for (const th of ['light', 'dark']) { await s.ev(`document.documentElement.setAttribute('data-theme', ${JSON.stringify(th)})`); await ouvrir(s);
    r.themes.push({ th, ok: await s.ev(`(() => { const h = document.querySelector('#panel > .vf-sy h2'); const c = getComputedStyle(h).color, f = getComputedStyle(document.getElementById('panel')).backgroundColor; return c !== f && !!h.textContent; })()`) }); await fermer(s); }
  // ---- O1 : un aller-retour d'onglet ne double rien, sans rechargement de la page ----
  await s.ev(`window.VF_COQUILLE.chargerOnglet('code')`); r.surCode = await s.ev(`document.querySelectorAll('#btn-synthese').length`);
  await s.ev(`window.VF_COQUILLE.chargerOnglet('projet')`); await s.attendre(`!!${BTN}`, 'bouton après retour'); r.ligneRetour = await ligneStable(s);
  r.ecout1 = await s.ev('window.__nbEcout()');
  for (const o of ['code', 'projet', 'code', 'projet']) await s.ev(`window.VF_COQUILLE.chargerOnglet(${JSON.stringify(o)})`);
  await s.attendre(`!!${BTN}`, 'bouton après deux cycles'); r.ligneCycles = await ligneStable(s); r.ecout2 = await s.ev('window.__nbEcout()');
  await ouvrir(s); r.apresCycles = { boutons: await s.ev(`document.querySelectorAll('#btn-synthese').length`), blocs: await s.ev(BLOCS), compte: await s.ev('window.__vfTemoinCompte()'),
    titre: await s.ev(`${BTN}.title`), memeDocument: (await s.ev('performance.timeOrigin')) === r.t0 };
  // ---- W11a : le journal réseau (sonde positive : il voit des GET avec leur jeton) ----
  const api = J.filter((x) => x.url.includes('/api/vf/'));
  r.reseau = { posts: J.filter((x) => x.methode === 'POST').length, interdites: J.filter((x) => /\/api\/vf\/(doing|transcript)/.test(x.url)).length, getsAvecJeton: api.filter((x) => x.methode === 'GET' && x.jeton).length,
    lecturesSansJeton: api.filter((x) => (x.type === 'Fetch' || x.type === 'XHR') && !x.jeton).length };
  r.cleVisite = await s.ev(`Object.keys(localStorage).filter((k) => /visite|tour-seen/.test(k))`);
  await ecrireStockageAvantChargement(s, 'vf-sonde-77', '1'); await s.naviguer(base + '/project.html'); r.sondes.stockage = await s.ev(`localStorage.getItem('vf-sonde-77')`);
}
