// chrome-tracabilite-memoire.mjs — section « Mémoire des agents », liste d'un agent, panneau d'une entrée, chaînes de Retour, absences, confidentialité (76-07), vrai Chrome sans tête.
// Usage : node chrome-tracabilite-memoire.mjs <chrome> <racine-du-serveur> <sections>   Rend UNE ligne JSON { m1, … } ou { erreur }. Chaque section est isolée.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, liste] = process.argv;
const SEL = new Set((liste || 'm1,m2,m3,m4,m6,m7,m8,m10').split(','));
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const AIDES = `window.__tr = { nb: (x) => String(x == null ? '' : x).replace(/\\u00a0/g, ' ').replace(/\\s+/g, ' ').trim() };`;
const SEC = (n) => `#panel details[data-vf-trace-${n}]`;
const BTN = `(() => { const b = document.querySelector('#panel .vf-retour'); return b ? { label: __tr.nb(b.getAttribute('aria-label')), dis: b.getAttribute('aria-disabled') } : null; })()`;
// le panneau d'objet affiché : étiquette, titre, fiche, état, liens sortants et entrants, chemins absents, pied ; texte normalisé
const PAN = `(() => { const p = document.querySelector('#panel [data-vf-trace-panneau]'); if (!p) return null; const t = p.querySelector('.pt'), nb = __tr.nb;
  const rows = (n, f) => { const s = [...p.querySelectorAll('.sec')].find((x) => nb(x.querySelector('h3').firstChild.textContent) === n); return s ? f(s) : null; };
  return { kind: nb((p.querySelector('.kindlabel') || {}).textContent), titre: t && nb(t.textContent), id: t && t.id, trace: t && t.getAttribute('data-trace'), texte: nb(p.textContent),
    secs: [...p.querySelectorAll('h3')].map((h) => nb(h.firstChild.textContent)), rappel: nb((p.querySelector('.vf-trace-note') || {}).textContent),
    fiche: [...p.querySelectorAll('.vf-trace-fiche dt')].map((d) => nb(d.textContent) + '=' + nb(d.nextElementSibling.textContent)),
    etat: rows('État', (s) => ({ mots: [...s.querySelectorAll('.vf-trace-etatm')].map((e) => nb(e.textContent) + (e.querySelector('.vf-trace-g-contradiction') ? '+octogone' : '')),
      phrase: nb((s.querySelector('.vf-trace-etat') || {}).textContent) })),
    sortants: rows('Liens sortants', (s) => [...s.querySelectorAll('.vf-trace-ligne, .vf-trace-inerte')].map((e) => [e.tagName, nb(e.querySelector('.vf-trace-m1').textContent),
      nb(e.querySelector('.vf-trace-l2e').textContent), [...e.querySelectorAll('.vf-trace-g')].map((g) => g.className.replace(/.*vf-trace-g-/, '')).join('+')].join('|'))),
    entrants: rows('Liens entrants', (s) => [...s.querySelectorAll('.vf-trace-ligne')].map((e) => e.tagName + '|' + nb(e.textContent))),
    absents: rows('Chemins cités et absents de HEAD', (s) => [...s.querySelectorAll('.vf-trace-absent')].map((e) => e.tagName + '|' + nb(e.querySelector('.vf-trace-chem').textContent) + ' ' + nb(e.querySelector('.vf-trace-l2e').textContent) + '|'
      + e.querySelectorAll('.vf-trace-g-contradiction').length)),
    pied: nb((p.querySelector('.vf-trace-pied') || {}).textContent) }; })()`;
const LIGNES_AGENT = `[...document.querySelectorAll(${JSON.stringify(SEC('memoire') + ' .vf-trace-ligne[data-trace^="agent:"]')})].map((b) => ({
  nom: __tr.nb(b.querySelector('.vf-trace-m1').textContent), nb: __tr.nb(b.querySelector('.vf-trace-nb').textContent),
  mot: __tr.nb((b.querySelector('.vf-trace-mot') || {}).textContent), l3: __tr.nb((b.querySelector('.vf-trace-l3') || {}).textContent),
  octo: b.querySelectorAll('.vf-trace-mot .vf-trace-g-contradiction').length, octoL3: b.querySelectorAll('.vf-trace-l3 .vf-trace-g-contradiction').length }))`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} }, reqs = [];
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AIDES });
  await s.send('Network.enable');
  s.ecouter('Network.requestWillBeSent', (p) => { reqs.push(`${p.request.method} ${p.request.url.replace(/^https?:\/\/[^/]+/, '')}`); });
  const sec = async (nom, f) => { if (!SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 200); } };
  const lire = async (expr) => { const v = await s.ev(`(async () => JSON.stringify(await (${expr})))()`); return typeof v === 'string' ? JSON.parse(v) : null; };
  const charger = async (w = 1440, h = 900) => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
    await s.naviguer(`${racine}/project.html?vue=couloirs`, { brut: true }); await s.attendre(PRET, 'page prête');
    await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs'); await pause(300);
  };
  const vrai = (expr, max = 30000) => attendreValeur(() => s.ev(expr), (v) => v === true, { max }).then((v) => v === true);
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'nearest' });
      const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const touche = async (key, code, vk) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk,
    nativeVirtualKeyCode: vk }); };
  const titre = (t) => vrai(`(() => { const e = document.querySelector('#panel [data-vf-trace-panneau] .pt'); return !!e && e.textContent === ${JSON.stringify(t)}; })()`);
  const corps = () => vrai("document.querySelectorAll('#panel [data-vf-trace-panneau] .sec, #panel [data-vf-trace-panneau] .vf-trace-etat').length >= 1 && !document.querySelector('#panel [aria-busy=\"true\"]')");
  const ouvrirSec = async (n) => { // la vue d'ensemble, section n ouverte et lue (bilan ou phrase d'absence)
    await s.ev("VibeFlow.go('root')"); await vrai(`!!document.querySelector(${JSON.stringify(SEC(n))})`); reqs.length = 0;
    await clic(`${SEC(n)} > summary`); await vrai(`!!document.querySelector(${JSON.stringify(SEC(n) + ' .vf-trace-bilan, ' + SEC(n) + ' [data-vf-trace-corps] > p.vf-trace-etat')})`);
  };
  const agent = async (nom) => { await clic(`${SEC('memoire')} .vf-trace-ligne[data-trace="agent:${nom}"]`); await titre(`Entrées de ${nom}`); await pause(200); };
  const entree = async (cle) => { await clic(`#panel .vf-trace-ligne[data-trace="entree:${cle}"]`); await corps(); await pause(250); };
  const retour = async () => { await clic('#panel .vf-retour'); await pause(500); await stabiliser(() => lire(BTN), { pas: 150, max: 3000 }); };
  const lireCle = (vue, cle) => `VFTrace.lire(${JSON.stringify(vue)}, ${JSON.stringify(cle)}).then((j) => j.etat, (e) => 'statut ' + e.statut)`;
  const ENTREE = (cle) => `VFTrace.ouvrir('entree', ${JSON.stringify(cle)})`;

  await sec('m1', async () => { // C4.1 : section repliée, bilan = compteurs de la route, une ligne par agent (gabarit fermé de trois lignes)
    await charger(); await s.ev("VibeFlow.go('root')"); await vrai(`!!document.querySelector(${JSON.stringify(SEC('memoire'))})`);
    o.m1avant = { ferme: await lire(`!document.querySelector(${JSON.stringify(SEC('memoire'))}).open`), req: reqs.filter((x) => x.includes('vue=memoire')).length };
    await ouvrirSec('memoire');
    o.m1 = await lire(`({ bilan: __tr.nb(document.querySelector(${JSON.stringify(SEC('memoire') + ' .vf-trace-bilan')}).textContent), agents: ${LIGNES_AGENT},
      compteur: __tr.nb(document.querySelector(${JSON.stringify(SEC('memoire') + ' > summary .c')}).textContent) })`);
    o.m1.req = reqs.filter((x) => x.includes('vue=memoire')).length;
    o.m1route = await lire(`VF_ETAT.lireJson('/api/vf/tracabilite?vue=memoire').then((j) => j.memoire.compteurs)`);
  });
  await sec('m2', async () => { // C4.2 : liste d'un agent : lignes d'entrée (gabarit fermé de trois lignes) ; agent sans entrée
    await charger(); await ouvrirSec('memoire'); await agent('vf-coder');
    o.m2 = await lire(`[...document.querySelectorAll('#panel [data-vf-trace-panneau] .vf-trace-ligne')].map((b) => ({ nom: __tr.nb(b.querySelector('.vf-trace-m1').textContent),
      type: __tr.nb((b.querySelector('.tag') || {}).textContent), l2: __tr.nb(b.querySelectorAll('.vf-trace-l3')[0].textContent),
      l3: __tr.nb((b.querySelectorAll('.vf-trace-l3')[1] || { textContent: '' }).textContent), octo: b.querySelectorAll('.vf-trace-l3 .vf-trace-g-contradiction').length,
      contra: __tr.nb((b.querySelector('.vf-trace-contra') || {}).textContent) }))`);
    o.m2titre = await lire(PAN);
    await charger(); await ouvrirSec('memoire'); await agent('vide'); o.m2vide = await lire(PAN);
  });
  await sec('m3', async () => { // C4.3 : le panneau d'une entrée : fiche, état, liens sortants, entrants, chemins absents, pied
    await charger(); await ouvrirSec('memoire'); await agent('vf-coder');
    await entree('vf-coder/a.md'); o.m3a = await lire(PAN);
    await charger(); await ouvrirSec('memoire'); await agent('vf-coder'); await entree('vf-coder/c.md'); o.m3c = await lire(PAN);
    await charger(); await ouvrirSec('memoire'); await agent('vf-coder'); await entree('vf-coder/b.md'); o.m3b = await lire(PAN);
    await charger(); await ouvrirSec('memoire'); await agent('vf-reviewer'); await entree('vf-reviewer/x.md'); o.m3x = await lire(PAN);
  });
  await sec('m4', async () => { // C4.4 : ni description ni corps ni « périmée », dans le DOM comme dans les réponses
    await charger(); await ouvrirSec('memoire'); await agent('vf-coder'); await entree('vf-coder/a.md');
    o.m4 = await lire(`({ dom: ['DESC-MARQUEUR-76', 'CORPS-MARQUEUR-76', 'périmée'].filter((m) => document.documentElement.outerHTML.includes(m)),
      reseau: JSON.stringify([await VF_ETAT.lireJson('/api/vf/tracabilite?vue=memoire'), await VF_ETAT.lireJson('/api/vf/tracabilite?vue=memoire&cle=vf-coder'),
        await VF_ETAT.lireJson('/api/vf/tracabilite?vue=entree&cle=vf-coder%2Fa.md')]).match(/DESC-MARQUEUR-76|CORPS-MARQUEUR-76|périmée/g), posee: document.querySelectorAll('.vf-trace').length > 0 })`);
  });
  await sec('m5', async () => { // C4.5 : absences de la mémoire (lab servi), puis ce que dit un panneau d'ADR sans git
    await charger(); await ouvrirSec('memoire');
    o.m5 = await lire(`({ texte: __tr.nb(document.querySelector(${JSON.stringify(SEC('memoire') + ' [data-vf-trace-corps]')}).textContent), sansBilan: !document.querySelector(${JSON.stringify(SEC('memoire') + ' .vf-trace-bilan')}),
      secret: document.documentElement.outerHTML.includes('secret-') })`);
    await s.ev("VFTrace.ouvrir('adr', 'ADR-001')"); await titre('ADR-001'); await corps(); await pause(300); o.m5adr = await lire(`__tr.nb(document.querySelector('#panel [data-vf-trace-panneau]').textContent)`);
  });
  await sec('m6', async () => { // C4.6 : l'état de la pile commune, constaté par le bouton Retour et les panneaux affichés
    await charger(); await s.ev("VibeFlow.go('root')"); await vrai(`!!document.querySelector(${JSON.stringify(SEC('jalon'))})`);
    await clic(`${SEC('jalon')} > summary`); await vrai(`!!document.querySelector(${JSON.stringify(SEC('jalon') + ' .vf-trace-ligne')})`);
    const nom = await lire("VibeFlow.info('n:ph-90').name"); o.m6nom = nom;
    await clic(`${SEC('jalon')} .vf-trace-ligne[data-trace="phase:ph-90"]`); await vrai("!!document.querySelector('#vf-trace-phase .vf-trace-ligne[data-trace=\"exigence:REQ-01\"]')");
    await clic('#vf-trace-phase .vf-trace-ligne[data-trace="exigence:REQ-01"]'); await titre('REQ-01'); await corps(); await stabiliser(() => lire(BTN), { pas: 150, max: 3000 });
    o.m6a1 = await lire(BTN); await retour(); o.m6a2 = await lire(`({ sel: VibeFlow.state.selected, sec: !!document.getElementById('vf-trace-phase'), back: ${BTN} })`);
    // (b) Décisions, ADR-001, P90-D-01, phase 90 : le Retour ramène pas à pas jusqu'à la vue d'ensemble
    await charger(); await ouvrirSec('decisions'); await clic(`${SEC('decisions')} .vf-trace-ligne[data-trace="adr:ADR-001"]`); await titre('ADR-001'); await corps();
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace="decision:P90-D-01:ph-90"]'); await titre('P90-D-01'); await corps();
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace^="phase:"]'); await vrai("VibeFlow.state.selected === 'n:ph-90'"); await stabiliser(() => lire(BTN), { pas: 150, max: 3000 });
    o.m6b0 = await lire(BTN); await retour(); o.m6b1 = await lire(`({ titre: ${PAN}.titre, back: ${BTN} })`); await retour(); o.m6b2 = await lire(`({ titre: ${PAN}.titre, back: ${BTN} })`);
    await retour(); o.m6b3 = await lire(`({ pan: !!document.querySelector('#panel [data-vf-trace-panneau]'), vue: !!document.querySelector(${JSON.stringify(SEC('decisions'))}), back: ${BTN} })`);
    // (c) entrée de mémoire, puis entrée cible par un lien résolu ; Échap suit la pile commune
    await charger(); await ouvrirSec('memoire'); await agent('vf-coder'); await entree('vf-coder/a.md');
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace="entree:vf-reviewer/x.md"]'); await titre('revue-1'); await corps(); await stabiliser(() => lire(BTN), { pas: 150, max: 3000 });
    o.m6c1 = await lire(BTN); await s.ev("document.querySelector('#panel [data-vf-trace-panneau] .pt').focus()"); await touche('Escape', 'Escape', 27);
    await titre('entree-a-MEMOIRE-MARQUEUR-76'); o.m6c2 = await lire(`({ titre: ${PAN}.titre, back: ${BTN} })`);
    // (d) exigence, puis décision citée (P76-D-38)
    await charger(); await s.ev("VibeFlow.select('n:ph-90')"); await vrai("!!document.querySelector('#vf-trace-phase .vf-trace-ligne[data-trace=\"exigence:REQ-01\"]')");
    await clic('#vf-trace-phase .vf-trace-ligne[data-trace="exigence:REQ-01"]'); await titre('REQ-01');
    await vrai("!!document.querySelector('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace=\"decision:P90-D-01:ph-90\"]')");
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace="decision:P90-D-01:ph-90"]'); await titre('P90-D-01'); await corps(); await stabiliser(() => lire(BTN), { pas: 150, max: 3000 });
    o.m6d0 = await lire(`({ titre: ${PAN}.titre, back: ${BTN} })`); await retour(); o.m6d1 = await lire(`({ titre: ${PAN}.titre, back: ${BTN} })`);
    await retour(); o.m6d2 = await lire(`({ sel: VibeFlow.state.selected, sec: !!document.getElementById('vf-trace-phase'), back: ${BTN} })`);
  });
  await sec('m7', async () => { // C4.7 : forme : témoin positif (sections posées et visibles), ordre, état ouvert conservé, ni canevas ni svg
    await charger(); await s.ev("VibeFlow.go('root')"); await vrai(`!!document.querySelector(${JSON.stringify(SEC('memoire'))})`);
    for (const n of ['jalon', 'decisions', 'memoire']) { await clic(`${SEC(n)} > summary`); await pause(250); }
    await vrai(`!!document.querySelector(${JSON.stringify(SEC('memoire') + ' .vf-trace-bilan')})`);
    const ordre = () => lire(`(() => { const d = [...document.querySelectorAll('#panel details[data-vf-trace-jalon], #panel details[data-vf-trace-decisions], #panel details[data-vf-trace-memoire]')];
      const secs = [...document.querySelectorAll('#panel .sec')]; return { ordre: d.map((e) => Object.keys(e.dataset).find((k) => k.startsWith('vfTrace'))).join(), ouverts: d.map((e) => e.open).join(),
        fin: secs.slice(-3).every((e) => e.classList.contains('vf-trace')) }; })()`);
    o.m7a = await lire(`({ posees: document.querySelectorAll('.vf-trace').length, visible: document.querySelector(${JSON.stringify(SEC('memoire'))}).offsetHeight > 0,
      dedans: document.querySelectorAll('.vf-trace canvas, .vf-trace svg').length })`);
    o.m7b = await ordre(); await s.ev("VibeFlow.select('n:ph-90')"); await pause(400); await s.ev("VibeFlow.go('root')"); await vrai(`!!document.querySelector(${JSON.stringify(SEC('memoire'))})`);
    await pause(400); o.m7c = await ordre();
  });
  await sec('m8', async () => { // C4.8 : témoin positif : les trois marqueurs sont visibles dans les sections et les panneaux ; l'export est contrôlé par la suite
    await charger(); await ouvrirSec('decisions'); await clic(`${SEC('memoire')} > summary`); await vrai(`!!document.querySelector(${JSON.stringify(SEC('memoire') + ' .vf-trace-bilan')})`);
    const texte = () => lire(`__tr.nb(document.querySelector('#panel').textContent)`);
    o.m8sec = await texte();
    await s.ev("VFTrace.ouvrir('adr', 'ADR-001')"); await titre('ADR-001'); await corps(); await pause(300); o.m8adr = await texte();
    await s.ev("VFTrace.ouvrir('decision', 'P90-D-01:ph-90')"); await titre('P90-D-01'); await corps(); await pause(300); o.m8dec = await texte();
    await s.ev(ENTREE('vf-coder/a.md')); await titre('entree-a-MEMOIRE-MARQUEUR-76'); await corps(); await pause(300); o.m8ent = await texte();
  });
  await sec('m10', async () => { // C4.10 : Projet, Code, Projet : les panneaux reliés se rouvrent et reviennent comme à la première arrivée ; clés encodées sans refus
    await charger(); await s.ev("VF_COQUILLE.chargerOnglet('code')"); await vrai("VF_COQUILLE.onglet() === 'code' && document.documentElement.dataset.vfPret === 'oui'");
    await s.ev("VF_COQUILLE.chargerOnglet('projet')"); await vrai("VF_COQUILLE.onglet() === 'projet' && !!window.VFTrace && document.querySelectorAll('.vp-carte').length > 0"); await pause(500);
    await ouvrirSec('decisions'); await clic(`${SEC('decisions')} .vf-trace-ligne[data-trace="adr:ADR-001"]`); await titre('ADR-001'); await corps();
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace="decision:P90-D-01:ph-90"]'); await titre('P90-D-01'); await corps(); await stabiliser(() => lire(BTN), { pas: 150, max: 3000 });
    o.m10a = await lire(BTN); await retour(); o.m10b = await lire(PAN + '.titre');
    reqs.length = 0; await ouvrirSec('memoire'); await agent('vf-coder'); await entree('vf-coder/a.md');
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace="entree:vf-reviewer/x.md"]'); await titre('revue-1'); await retour(); o.m10c = await lire(PAN + '.titre');
    o.m10cles = await lire(`Promise.all([${lireCle('entree', 'vf-coder/a.md')}, ${lireCle('decision', 'P90-D-01:ph-90')}, ${lireCle('adr', 'ADR-001')}])`);
    o.m10req = reqs.filter((x) => x.includes('cle=vf-coder%2Fa.md') || x.includes('cle=P90-D-01%3Aph-90') || x.includes('cle=ADR-001')).length;
  });
  return o;
}, { csp: true });
