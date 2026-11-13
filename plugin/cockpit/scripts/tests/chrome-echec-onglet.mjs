// chrome-echec-onglet.mjs — mesures de l'échec d'un chargement d'onglet (80-21, FORM-16) dans un vrai Chrome headless (vrais clics, vraies touches).
// Usage : node chrome-echec-onglet.mjs <chrome> <racine-du-serveur> <mode> <fichier-00-vf-onglets-echec.js>   Rend UNE ligne JSON { … } ou { erreur }.
// Modes : ec1 (EC1.1 à EC1.4, EC3.1 : un onglet affiché, la lecture de Projet en échec), ec2 (EC2.1 et EC2.2 : premier chargement en échec).
// La panne de lecture est un instrument posé avant la page (fetch de /api/vf/graphe refusé tant que __e.echec vaut 1), levée à la demande ;
// l'absence de rechargement se lit sur performance.timeOrigin.
import fs from 'node:fs';
import vm from 'node:vm';
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode, fichier] = process.argv;
const amorce = (e0) => `(() => { const A = window.__e = { echec: ${e0}, fetchs: [], posts: 0, evs: [], prevented: [] };
  const f = window.fetch;
  window.fetch = function (u, o) { const m = String((o && o.method) || 'GET').toUpperCase(); if (m !== 'GET') A.posts++;
    if (String(u).includes('/api/vf/graphe')) { A.fetchs.push(String(u)); if (A.echec) return Promise.reject(new TypeError('forcé')); }
    return f.apply(this, arguments); };
  document.addEventListener('vf:coquille-echec', (ev) => { A.evs.push(ev.detail.onglet + ':' + ev.detail.initial);
    queueMicrotask(() => A.prevented.push(ev.defaultPrevented)); }); })()`;
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const TAB = { code: 'index.html', projet: 'project.html', equipe: 'equipe.html' };
const TEXTE = "Lecture impossible : les données de cet onglet n'ont pas pu être lues.";
const ETAT = `({ p: location.pathname, n: history.length, t: document.title, o: performance.timeOrigin, etat: VF_COQUILLE.etat(), aff: VF_COQUILLE.onglet(),
  ech: VF_ONGLETS.echec(), live: (document.querySelector('.vp-status') || document.getElementById('ask-live') || {}).textContent || '',
  ae: (() => { const a = document.activeElement; return !a ? null : a === document.body ? 'body' : a.id || a.tagName; })(),
  evs: __e.evs.length, prevented: __e.prevented.slice(), fetchs: __e.fetchs.length, posts: __e.posts, boite: !!document.getElementById('vf-onglets-echec'),
  repli: !!document.getElementById('vf-coquille-echec'), lectures: (document.body.innerText.match(/Lecture impossible/g) || []).length })`;

function evalIsolee() { // EC2.2 : le fichier évalué deux fois dans un contexte vide : un seul objet, une seule écoute, rien posé, rien lu du moteur
  const src = fs.readFileSync(fichier, 'utf8'), c = { ecoutes: [], noeuds: 0, lectures: [] };
  const el = () => ({ append() { c.noeuds++; }, appendChild() { c.noeuds++; }, setAttribute() {}, style: {}, addEventListener() {} });
  const doc = { addEventListener: (t) => c.ecoutes.push(t), createElement: el, head: el(), body: el(), getElementById: () => null };
  const w = { document: doc, VF_COQUILLE: { etat: () => ({}), onglet: () => null }, VF_ONGLETS: {} };
  for (const k of ['Floorplan', 'VibeFlow']) Object.defineProperty(w, k, { get() { c.lectures.push(k); return undefined; } });
  w.window = w; const ctx = vm.createContext(w); vm.runInContext(src, ctx); const un = w.VF_ONGLETS_ECHEC; vm.runInContext(src, ctx);
  return { un: !!un && un === w.VF_ONGLETS_ECHEC, gele: !!un && Object.isFrozen(un), cles: un ? Object.keys(un).sort() : [], ecoutes: c.ecoutes,
    noeuds: c.noeuds, lectures: c.lectures, marqueur: src.split('\n').slice(0, 8).some((l) => l.includes('vf-coquille: persistant')) };
}

await executer(chrome, async (s) => {
  const o = { erreurs: {} }; let ident = null;
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const poser = async (e0) => { // l'instrument de la prochaine page : panne dès le premier octet (1) ou non (0)
    if (ident) await s.send('Page.removeScriptToEvaluateOnNewDocument', { identifier: ident });
    ident = (await s.send('Page.addScriptToEvaluateOnNewDocument', { source: amorce(e0) })).identifier;
  };
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 200); } };
  const lire = async (expr) => { const v = await s.ev(`JSON.stringify(${expr})`); return v === undefined ? null : JSON.parse(v); };
  const etat = () => lire(ETAT);
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'nearest' });
      const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const touche = async (key, code, vk) => { // Entrée porte son texte : sans lui, le bouton ne reçoit pas l'évènement d'activation
    for (const type of ['keyDown', 'keyUp']) {
      await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, ...(type === 'keyDown' ? { text: '\r' } : {}) });
    }
  };
  const charger = async (chemin, opts) => {
    await s.naviguer(`${racine}${chemin}`, { brut: true, ...opts }); await s.attendre('!!window.VF_ONGLETS', 'VF_ONGLETS'); await pause(300);
  };
  const PRET = "document.documentElement.dataset.vfPret === 'oui'";
  const chez = (chemin) => s.attendre(`location.pathname === '${chemin}' && ${PRET}`, 'arrivée sur ' + chemin);
  const rien = async (ms) => { await pause(ms); return stabiliser(etat, { pas: 200, max: 4000 }); };
  const rangees = () => lire(`[...document.querySelectorAll('#results .r')]
    .map((r) => (r.querySelector('.rn') || {}).textContent + '|' + ((r.querySelector('.rd') || {}).textContent || ''))
    .filter((x) => x.startsWith('Réessayer'))`);
  const palette = async (saisie) => { // ouvre la palette par son bouton, tape la saisie, rend les rangées « Réessayer »
    await s.ev("document.getElementById('pal-x') && document.getElementById('palette').classList.contains('open') && document.getElementById('pal-x').click()");
    await clic('#search-btn'); await s.attendre("document.activeElement && document.activeElement.id === 'search'", 'champ de la palette');
    if (saisie) await s.send('Input.insertText', { text: saisie });
    await pause(250); return rangees();
  };
  const fermer = () => s.ev("document.getElementById('palette').classList.contains('open') && document.getElementById('pal-x').click()");

  if (mode === 'ec1') {
    await sec('ec1', async () => {
      await poser(0); await charger('/'); await s.attendre("document.documentElement.dataset.vfPret === 'oui'", 'Code prêt');
      await s.ev('document.querySelector(\'nav.vf-tabs a[href="project.html"]\').focus()'); // le clic ne déplace alors pas le focus de lui-même
      const e0 = await etat(); await s.ev('__e.echec = 1'); const nf = e0.fetchs;
      await clic('nav.vf-tabs a[href="project.html"]'); await s.attendre(`__e.fetchs.length > ${nf}`, 'lecture tentée');
      const e1 = await rien(700); o.ec11 = { e0, e1 };
      o.ec12 = { vide: await palette(''), saisie: await palette('réess'), action: await palette('>réess'),
        reg: await lire("VF_RACCOURCIS.entrees('code').map((e) => e.libelle).filter((l) => /essayer/i.test(l))") }; await fermer();
      o.ec31 = { rangee: await lire(`(() => { const r = document.querySelector('#vf-coin .vf-ech'); const b = r && r.querySelector('button');
        const t = b ? getComputedStyle(b, '::after') : null;
        return r ? { texte: r.textContent, nb: document.querySelectorAll('#vf-coin .vf-ech').length,
        h: t && parseFloat(t.height), l: t && parseFloat(t.width), vis: r.getClientRects().length > 0 } : null; })()`) };
      await s.ev("document.querySelector('#vf-coin .vf-ech button').focus()");
      await touche('Enter', 'Enter', 13); // la lecture est encore en panne
      const e2 = await rien(700); o.ec31.encore = { echec: e2.evs, ech: e2.ech, p: e2.p };
      await s.ev('__e.echec = 0'); await s.ev("document.querySelector('#vf-coin .vf-ech button').focus()");
      const n0 = (await etat()).fetchs, p0 = (await etat()).posts;
      await touche('Enter', 'Enter', 13); await chez('/project.html');
      const e3 = await rien(700);
      o.ec12.apres = { p: e3.p, pret: e3.etat, ech: e3.ech, aff: e3.aff, fetchs: e3.fetchs - n0, posts: e3.posts - p0, origine: e3.o === e0.o };
      o.ec31.apres = await lire("document.querySelectorAll('#vf-coin .vf-ech').length");
      o.ec12.sansEchec = { vide: await palette(''), saisie: await palette('réess') }; await fermer();
    });
    await sec('ec13', async () => {
      await poser(0); await charger('/'); await s.attendre("document.documentElement.dataset.vfPret === 'oui'", 'Code prêt');
      await s.ev('__e.echec = 1'); await clic('nav.vf-tabs a[href="project.html"]'); await s.attendre('__e.evs.length >= 1', 'premier échec'); await pause(500);
      const un = await palette('réess'); await fermer(); await s.ev('__e.echec = 0');
      await clic('nav.vf-tabs a[href="project.html"]'); await chez('/project.html');
      await pause(400); await clic('nav.vf-tabs a[href="equipe.html"]'); await chez('/equipe.html');
      await pause(400); const entre = await palette('réess'); await fermer();
      await s.ev('__e.echec = 1'); await clic('nav.vf-tabs a[href="index.html"]'); await s.attendre('__e.evs.length >= 2', 'second échec'); await pause(500);
      const deux = await palette('réess'); await fermer(); await s.ev('__e.echec = 0');
      o.ec13 = { un: un.length, entre: entre.length, deux: deux.length, rangees: await lire("document.querySelectorAll('#vf-coin .vf-ech').length") };
    });
    await sec('ec14', async () => {
      await poser(0); await charger('/'); await s.attendre("document.documentElement.dataset.vfPret === 'oui'", 'Code prêt');
      await s.ev('__e.echec = 1'); await clic('nav.vf-tabs a[href="project.html"]'); await s.attendre('__e.evs.length >= 1', 'échec'); await pause(500);
      const avant = await etat();
      await s.ev('delete window.VF_ONGLETS_ECHEC'); await s.ev(fs.readFileSync(fichier, 'utf8'));
      const apres = await rien(500); o.ec14 = { ech: apres.ech, live: apres.live === avant.live, rangees: (await palette('réess')).length }; await fermer();
      await s.ev('__e.echec = 0');
    });
  }

  if (mode === 'ec2') {
    await sec('ec22', async () => { o.ec22 = evalIsolee(); });
    for (const [nom, chemin, tab] of [['projet', '/project.html', 'project.html'], ['code', '/', 'index.html'], ['equipe', '/equipe.html', 'equipe.html']]) {
      await sec('ec21-' + nom, async () => {
        await poser(1); await charger(chemin, { echec: true }); await pause(500);
        const e1 = await etat(), niv = await lire(`(() => { const b = document.querySelector('#vf-onglets-echec button');
          return { texte: (document.querySelector('#vf-onglets-echec p') || {}).textContent,
          role: (document.querySelector('#vf-onglets-echec') || { getAttribute: () => null }).getAttribute('role'), bouton: b ? b.textContent : null,
          anim: document.getAnimations().length, repli: !!document.getElementById('vf-coquille-echec') }; })()`);
        const r = { e1, niv };
        await s.ev('__e.echec = 1'); await touche('Enter', 'Enter', 13); await s.attendre('__e.fetchs.length >= 2', 'seconde lecture'); await pause(500);
        r.encore = await etat(); await s.ev('__e.echec = 0'); const n = r.encore.n;
        await touche('Enter', 'Enter', 13); await s.attendre(PRET, 'onglet chargé'); r.fin = await rien(700); r.dn = r.fin.n - n;
        o['ec21' + nom] = r; await poser(0);
      });
    }
  }
  return o;
});
