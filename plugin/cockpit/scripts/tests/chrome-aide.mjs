// chrome-aide.mjs — l'aide des raccourcis (80-15, FORM-03, FORM-18, P80-D-11/12/13/51/55/59), un vrai Chrome, sans réseau.
// Usage : node chrome-aide.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { ai1, ai2, erreurs } ou { erreur }.
// Modes : base (lab sans --terminal) · term (lab --terminal : la ligne du terminal, AI1.4). Chaque section est isolée (sec).
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SEL = 'f:src/n05.js', MAJ = 8, CTRL = 2, META = 4;
const KEYS = { Enter: ['Enter', 13], Escape: ['Escape', 27], '/': ['Slash', 191], ArrowDown: ['ArrowDown', 40], '>': ['Period', 190],
  '?': ['Slash', 191], '+': ['Equal', 187], '-': ['Minus', 189], Backspace: ['Backspace', 8], Tab: ['Tab', 9] };
const NOEUDS = "document.querySelectorAll('iframe,[class*=\"vf-term\"],[data-vf-flottant]').length";

await executer(chrome, async (s) => {
  const o = { erreurs: {}, ai1: {}, ai2: {} }, reqs = [];
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }); await s.send('Network.enable');
  s.ecouter('Network.requestWillBeSent', (p) => reqs.push(p.request.url));
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(`JSON.stringify(${expr})`); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, mobile) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile });
  const touche = async (key, mod = 0) => {
    const [code, vk] = KEYS[key] || [key, key.toUpperCase().charCodeAt(0)], text = key.length === 1 ? key : undefined;
    for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, text: type === 'keyDown' ? text : undefined,
      modifiers: mod, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk });
  };
  const sansVisite = async () => {
    await pause(1200);
    for (let i = 0; i < 5 && await s.ev('!!(window.VibeFlowTour && VibeFlowTour.active())'); i++) { await touche('Escape'); await pause(400); }
  };
  const charger = async (page, w = 1440, h = 900, mobile = false) => {
    await vue(w, h, mobile); await s.naviguer(`${racine}/${page}`); await s.attendre(PRET, `page ${page}`);
    await s.attendre("!!document.querySelector('#viewport .node, .vp-couloirs, .vp-liste')", `cartes ${page}`); await sansVisite();
  };
  const onglet = async (nom) => { await s.ev(`VF_ONGLETS.aller(${JSON.stringify(nom)})`);
      await s.attendre(`VF_ONGLETS.courant() === ${JSON.stringify(nom)} && ${PRET}`, `onglet ${nom}`); await pause(700); };
  const choisir = async () => { await s.ev(`VibeFlow.reveal(${JSON.stringify(SEL)}); VibeFlow.fit(false); VibeFlow.select(${JSON.stringify(SEL)})`);
      await pause(900); };
  const ouverte = () => s.ev("!!document.querySelector('.vf-aide-modale')");
  const ouvrir = async () => { await touche('?', MAJ); await s.attendre("!!document.querySelector('.vf-aide-modale')", 'aide ouverte'); await pause(150); };
  const foc = (id = 'btn-panel') => s.ev(`document.getElementById(${JSON.stringify(id)}).focus()`);
  const lue = () => lire(`(() => { const b = document.querySelector('.vf-aide-modale'); if (!b) return null; const h = b.querySelector('h2');
    return { role: b.getAttribute('role'), modal: b.getAttribute('aria-modal'), nom: b.getAttribute('aria-labelledby') === h.id, titre: h.textContent,
      tabindex: h.getAttribute('tabindex'), foc: document.activeElement === h, vue: b.querySelector('.vf-aide-vue').textContent,
      groupes: [...b.querySelectorAll('h3')].map((x) => x.textContent), texte: b.innerText,
      rangees: [...b.querySelectorAll('.vf-aide-r')].map((r) => ({ lib: r.querySelector('dt').textContent,
        kbd: [...r.querySelectorAll('kbd')].map((k) => k.textContent),
               groupe: r.closest('dl').previousElementSibling.textContent })) }; })()`);
  const registre = (n) => lire(`VF_RACCOURCIS.entrees(${JSON.stringify(n)}).map((e) => ({ lib: e.libelle, groupe: e.groupe,
    touche: e.touche, info: !!e.info }))`);
  const ecouteursAide = async () => { // nombre d'écouteurs « keydown » du document (CDP : la portée rend window.__x à chaque onglet)
    const d = (await s.send('Runtime.evaluate', { expression: 'document' })).result.objectId;
    return (await s.send('DOMDebugger.getEventListeners', { objectId: d })).listeners.filter((x) => x.type === 'keydown').length;
  };
  const nbReq = (depuis) => reqs.length - depuis;

  if (mode === 'term') {
    await sec('ai14t', async () => {
      await charger('index.html'); await foc(); const avant = await lire(NOEUDS), n0 = reqs.length;
      await ouvrir(); const a = await lue(); await touche('Escape'); await pause(300);
      o.ai1.termAvec = { rangee: a.rangees.filter((r) => r.lib.includes('--terminal')), apres: await lire(NOEUDS), avant,
        requetes: nbReq(n0), reg: await registre('code') };
    });
    return o;
  }

  await sec('ai11', async () => { // AI1.1 à AI1.3, AI1.5 : sur Code
    await charger('index.html'); await foc(); const t0 = await s.ev('performance.timeOrigin');
    await ouvrir(); o.ai1.code = await lue();  o.ai1.regCode = await registre('code');
    o.ai1.ressource = await lire("[performance.getEntriesByType('resource')" +
      ".some((r) => new URL(r.name).pathname === '/_vf/ui/60-vf-aide.js'), typeof window.VF_AIDE]");
    await touche('Escape'); await pause(300);
    o.ai1.ferme = await lire(`({ ouverte: ${await ouverte()}, foc: document.activeElement.id, pile: VF_SURCOUCHES.ouverte(),
      memeFenetre: performance.timeOrigin === ${t0} })`);
  });
  await sec('ai12', async () => { // AI1.2 : Projet ; AI1.4 : le terminal sur Code, Projet, Équipe
    await charger('index.html'); await onglet('projet'); await foc();
    await ouvrir(); o.ai1.projet = await lue(); o.ai1.regProjet = await registre('projet'); await touche('Escape'); await pause(300);
    o.ai1.terminal = {};
    for (const n of ['code', 'projet', 'equipe']) {
      await onglet(n); await foc(); const avant = await lire(NOEUDS), n0 = reqs.length;
      await ouvrir(); const a = await lue(); await touche('Escape'); await pause(300);
      o.ai1.terminal[n] = { rangee: a.rangees.filter((r) => r.lib.includes('--terminal')), groupe: a.groupes[0], apres: await lire(NOEUDS), avant,
        requetes: nbReq(n0), reg: (await registre(n)).filter((e) => e.info).map((e) => e.lib) };
    }
  });
  await sec('ai12b', async () => { // AI1.2 : à 390 px, aucune rangée « bureau » ni « téléphone »
    await charger('index.html', 390, 844, true); await foc(); await ouvrir(); o.ai1.mobile = await lue(); await touche('Escape');
  });

  await sec('ai21', async () => { // AI2.1 : la palette ouvre l'aide ; mêmes libellés que les actions de la palette
    await charger('index.html'); await choisir(); await foc();
    await touche('/'); await s.attendre("document.getElementById('palette').classList.contains('open') && document.activeElement.id === 'search'", 'palette');
    await s.send('Input.insertText', { text: '>' }); await pause(500);
    const libs = () => lire("[...document.querySelectorAll('#results .r .rn')].map((r) => r.textContent.trim())");
    o.ai2.actions = await libs(); const i = o.ai2.actions.indexOf('Afficher les raccourcis');
    for (let k = 0; k < i; k++) await touche('ArrowDown');
    await touche('Enter'); await s.attendre("!!document.querySelector('.vf-aide-modale')", 'aide par la palette'); await pause(200);
    o.ai2.palette = await lue(); await touche('Escape'); await pause(300);
  });
  await sec('ai22', async () => { // AI2.2 : « ? » dans un champ de saisie, avec ⌘ ou Ctrl
    await charger('index.html');
    await s.ev("const t = document.createElement('textarea'); t.id = 'zone-test'; document.body.appendChild(t); t.focus()");
    await touche('?', MAJ); await pause(300);
    o.ai2.saisie = await lire(`({ ouverte: ${await ouverte()}, valeur: document.getElementById('zone-test').value })`);
    await s.ev("document.getElementById('zone-test').remove()"); await foc();
    await touche('?', MAJ | META); await touche('?', MAJ | CTRL); await pause(300); o.ai2.modifs = await ouverte();
  });
  await sec('ai23', async () => { // AI2.3 : piège à Tab, inert derrière ; AI2.6 : mouvement réduit
    await charger('index.html'); await foc(); await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    const anim = "document.getAnimations().filter((a) => a.playState === 'running').length";
    await ouvrir(); const dedans = [];
    for (let i = 0; i < 30; i++) { await touche('Tab'); dedans.push(await s.ev("document.querySelector('.vf-aide-modale').contains(document.activeElement)")); }
    const inerte = "['header', '#stage'].map((q) => !!document.querySelector(q).closest('[inert]'))";
    o.ai2.piege = { dedans: dedans.every(Boolean), pendant: await lire(inerte), anim: [await lire(anim)] };
    await touche('Escape'); await pause(300); o.ai2.piege.apres = await lire(inerte); o.ai2.piege.anim.push(await lire(anim));
    await s.send('Emulation.setEmulatedMedia', { features: [] });
  });
  await sec('ai24', async () => { // AI2.4 : 1024 × 768 et 390 px : débordement, hauteur, colonnes
    const mesure = () => lire(`(() => { const b = document.querySelector('.vf-aide-modale'), l = [...b.querySelector('dl').querySelectorAll('.vf-aide-r')];
      return { sw: b.scrollWidth <= b.clientWidth, h: b.getBoundingClientRect().height <= innerHeight * 0.8 + 1,
        defile: ['auto', 'scroll'].includes(getComputedStyle(b).overflowY), 
        colonnes: new Set(l.map((r) => Math.round(r.getBoundingClientRect().left))).size }; })()`);
    await charger('index.html', 1024, 768); await foc(); await ouvrir(); o.ai2.large = await mesure(); await touche('Escape'); await pause(300);
    await charger('index.html', 390, 844, true); await foc(); await ouvrir(); o.ai2.etroit = await mesure(); await touche('Escape');
  });
  await sec('ai25', async () => { // AI2.5 : chaque touche du registre de Code a son effet
    await charger('index.html'); await choisir(); await foc('btn-panel'); await s.ev('document.activeElement.blur()');
    const k = () => lire('VibeFlow.state.t.k'), eff = {};
    const k0 = await k(); await touche('+'); await pause(500); const k1 = await k(); eff.plus = k1 > k0;
    await touche('-'); await pause(500); const km = await k(); eff.moins = km < k1;
    await touche('-'); await pause(500); const km2 = await k(); await touche('f'); await pause(700); eff.ajuster = (await k()) !== km2;
    await touche('+'); await touche('+'); await pause(500); const kz = await k(), t1 = await lire('({ ...VibeFlow.state.t })');
    await touche('c'); await pause(900); const t2 = await lire('({ ...VibeFlow.state.t })'); eff.cadrer = JSON.stringify(t1) !== JSON.stringify(t2) && kz > 0;
    const p0 = await s.ev("document.body.classList.contains('no-panel')"); await touche('p'); await pause(400);
    eff.detail = (await s.ev("document.body.classList.contains('no-panel')")) !== p0; await touche('p'); await pause(300);
    await touche('g'); await pause(600); eff.git = await s.ev('VFGitTiroir.ouvert()'); await s.ev('VFGitTiroir.fermer()'); await pause(300);
    await s.ev('document.activeElement.blur()'); const c0 = await s.ev('VibeFlow.state.container'); await touche('Backspace'); await pause(700);
    eff.monter = (await s.ev('VibeFlow.state.container')) !== c0;
    await touche('?', MAJ); await pause(400); eff.aide = await ouverte(); await touche('Escape');
    o.ai2.effets = eff;
  });
  await sec('ai27', async () => { // AI2.7 : un seul écouteur après deux allers-retours ; Échap sur Équipe revient à la page
    await charger('index.html');
    const base = await ecouteursAide();
    await onglet('projet'); await onglet('code'); await onglet('projet'); await onglet('code');
    const fin = await ecouteursAide(); await onglet('projet'); await foc(); await ouvrir();
    o.ai2.cycle = await lire("({ aides: document.querySelectorAll('.vf-aide-modale').length, vue: document.querySelector('.vf-aide-vue').textContent })");
    o.ai2.cycle.ecouteurs = fin - base;
    await touche('Escape'); await pause(300);
    await onglet('equipe'); await foc(); await ouvrir(); o.ai2.equipe = { vue: await s.ev("document.querySelector('.vf-aide-vue').textContent") };
    await touche('Escape'); await pause(300); o.ai2.equipe.ferme = !(await ouverte()); o.ai2.equipe.foc = await s.ev('document.activeElement.id');
    await s.ev("window.__ech = null; document.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__ech = { dp: e.defaultPrevented }; }); 1");
    await touche('Escape'); await pause(300);
    o.ai2.equipe.pile = await s.ev('VF_SURCOUCHES.ouverte()'); o.ai2.equipe.recu = await lire('window.__ech');
  });
  return o;
});
