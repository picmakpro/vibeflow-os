// chrome-tracabilite-exigence.mjs — le panneau d'une exigence, la liste paginée, la pile Retour, le clavier, les onglets et la confidentialité (76-06), vrai Chrome sans tête.
// Usage : node chrome-tracabilite-exigence.mjs <chrome> <racine-du-serveur> <dossier-du-lab> [sections]   Rend UNE ligne JSON { e1a, … } ou { erreur }.
// Les sections destructives (e5, e7 : fichiers du lab modifiés) passent en dernier. Chaque section est isolée.
import fs from 'node:fs';
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, lab, liste] = process.argv;
const SEL = new Set((liste || 'e1,e2,e3,e4,e6,e8,e9,e5,e7').split(','));
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const AIDES = `window.__tr = { sec: () => document.getElementById('vf-trace-phase'),
  nb: (x) => String(x == null ? '' : x).replace(/\\u00a0/g, ' ').replace(/\\s+/g, ' ').trim() };`;
const BTN = `(() => { const b = document.querySelector('#panel .vf-retour'); return b ? { label: __tr.nb(b.getAttribute('aria-label')), dis: b.getAttribute('aria-disabled') } : null; })()`;
const PAN = `(() => { const p = document.querySelector('#panel [data-vf-trace-panneau]'); if (!p) return null; const t = p.querySelector('.pt');
  return { titre: t && __tr.nb(t.textContent), id: t && t.id, sections: [...p.querySelectorAll('h3')].map((h) => __tr.nb(h.firstChild.textContent)), texte: __tr.nb(p.textContent), corps: __tr.nb(p.querySelector('[data-vf-trace-corps]').textContent) }; })()`;
const L = (id) => `#vf-trace-phase .vf-trace-ligne[data-trace="exigence:${id}"]`;

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
  const vrai = (expr, max = 6000) => attendreValeur(() => s.ev(expr), (v) => v === true, { max }).then((v) => v === true);
  const phase = async (n) => { await s.ev(`VibeFlow.select('n:ph-${n}')`); return vrai(`!!document.querySelector('#vf-trace-phase .vf-trace-ligne')`); };
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'nearest' });
      const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const touche = async (key, code, vk) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk,
    ...(key === 'Enter' && type === 'keyDown' ? { text: '\r' } : {}) }); };
  const focus = (sel) => s.ev(`document.querySelector(${JSON.stringify(sel)}).focus()`);
  const titre = (t) => vrai(`(() => { const e = document.querySelector('#panel [data-vf-trace-panneau] .pt'); return !!e && e.textContent === ${JSON.stringify(t)}; })()`);
  const sections = () => vrai("document.querySelectorAll('#panel [data-vf-trace-panneau] .sec').length >= 4"); // le corps du panneau est lu de façon asynchrone
  const ouvrir = async (id) => { await clic(L(id)); const ok = await titre(id); return ok && (await sections()); };
  const ouvrirDirect = async (id, ph) => { // une exigence hors des cinq lignes de la section : le panneau est ouvert par l'ouvreur de la page
    await s.ev(`VFTrace.lire('phase', '${ph}').then((p) => VFTrace.ouvrirExigence(p.phase.exigences.find((l) => l.id === '${id}'), false, null))`);
    return (await titre(id)) && (await sections());
  };
  const retour = async () => { await clic('#panel .vf-retour'); await pause(500); await stabiliser(() => lire(BTN), { pas: 150, max: 3000 }); };

  await sec('e1', async () => { // C2.1 : panneau d'exigence et état de la pile commune (le bouton Retour de l'en-tête nomme la vue quittée)
    await charger(); await phase(1); const nom = await lire("VibeFlow.info('n:ph-1').name"); o.e1nom = nom;
    o.e1pose = await ouvrir('REQ-16'); o.e1a = await lire(`({ pan: ${PAN}, back: ${BTN}, chaine: [...document.querySelectorAll('#panel .vf-trace-maillon')].map((m) => __tr.nb(m.textContent)) })`);
    await clic('#panel .vf-trace-puce'); await vrai("typeof VibeFlow.state.selected === 'string' && VibeFlow.state.selected.startsWith('f:')");
    await stabiliser(() => lire(BTN), { pas: 150, max: 3000 }); o.e1b = await lire(`({ sel: VibeFlow.state.selected, back: ${BTN} })`);
    await retour(); o.e1c = await lire(`({ pan: ${PAN}, back: ${BTN} })`);
    await retour(); await vrai("!!document.getElementById('vf-trace-phase')"); o.e1d = await lire(`({ sel: VibeFlow.state.selected, sec: !!__tr.sec(), back: ${BTN} })`);
    await ouvrir('REQ-14'); o.e1mentions = await lire(`${PAN}`);
  });
  await sec('e2', async () => { // C2.2 : « + 26 autres exigences » ouvre la liste paginée de 30 ; « + 1 autre fichier de preuve » ouvre la liste des preuves
    await charger(); await phase(5); await clic('#vf-trace-phase .vf-trace-plus'); await titre('Exigences de la Phase 5');
    const page = () => lire(`({ n: document.querySelectorAll('#panel [data-vf-trace-panneau] .vf-trace-ligne').length, compte: __tr.nb((document.querySelector('#panel .vf-trace-compte') || {}).textContent),
      prec: (document.querySelector('#panel [data-vf-trace-pages] button') || {}).disabled, foc: (document.activeElement || {}).className || '' })`);
    o.e2p1 = await page(); await clic('#panel [data-vf-trace-pages] button:last-child'); await pause(400); o.e2p2 = await page();
    o.e2foc = await lire("document.activeElement === document.querySelector('#panel [data-vf-trace-panneau] .pt')");
    await charger(); await phase(3); await clic('#vf-trace-phase details.vf-trace-repli > summary'); await clic('#vf-trace-phase details .vf-trace-plus');
    await titre('Preuves de la Phase 3'); o.e2pr = await lire(`__tr.nb(document.querySelector('#panel [data-vf-trace-panneau]').textContent)`);
  });
  await sec('e3', async () => { // C2.3 : clavier : Entrée met le focus sur le titre, la souris non ; Échap suit la pile, la surcouche, la fermeture
    await charger(); await phase(1); await focus(L('REQ-16')); await touche('Enter', 'Enter', 13); o.e3titre = await titre('REQ-16');
    o.e3foc = await lire("document.activeElement.id");
    await focus('#panel [data-vf-trace-panneau] .pt'); await touche('Escape', 'Escape', 27); await vrai("!!document.getElementById('vf-trace-phase')");
    o.e3retour = await lire("({ sel: VibeFlow.state.selected, sec: !!__tr.sec(), pan: !!document.querySelector('[data-vf-trace-panneau]') })");
    await ouvrir('REQ-16'); o.e3souris = await lire("document.activeElement.id !== 'vf-trace-exigence-REQ-16'");
    await s.ev("window.__sur = window.VF_SURCOUCHES; window.VF_SURCOUCHES = { ...window.__sur, ouverte: () => true }"); await focus('#panel [data-vf-trace-panneau] .pt');
    await touche('Escape', 'Escape', 27); await pause(400); o.e3surcouche = await lire("!!document.querySelector('[data-vf-trace-panneau]')");
    await s.ev("window.VF_SURCOUCHES = window.__sur"); await s.ev("document.dispatchEvent(new Event('vf:onglet'))"); await pause(200);
    await focus('#panel [data-vf-trace-panneau] .pt'); await touche('Escape', 'Escape', 27); await vrai("!document.querySelector('[data-vf-trace-panneau]')");
    o.e3ferme = await lire(`({ pan: !!document.querySelector('[data-vf-trace-panneau]'), sec: !!__tr.sec(), foc: (document.activeElement.dataset || {}).trace })`);
  });
  await sec('e4', async () => { // C2.4 et C2.10 : aller-retour Projet, Code, Projet sans double section ; la 79 relit window.VF_PANNEAU à chaque appel ; clés bien formées
    await charger(); await phase(1); const abo = () => lire('VF_ETAT.abonnes().planning'); o.e4abo1 = await abo();
    await s.ev("VF_COQUILLE.chargerOnglet('code')"); await vrai("VF_COQUILLE.onglet() === 'code' && document.documentElement.dataset.vfPret === 'oui'");
    o.e4code = await lire("({ abo: VF_ETAT.abonnes().planning, vt: !(window.VFTrace && window.VFTrace.installe), sec: !!document.getElementById('vf-trace-phase') })");
    await s.ev("VF_COQUILLE.chargerOnglet('projet')"); await vrai("VF_COQUILLE.onglet() === 'projet' && !!window.VFTrace && document.querySelectorAll('.vp-carte').length > 0");
    await pause(500); await phase(2); o.e4abo3 = await abo();
    o.e4un = await lire("({ sec: document.querySelectorAll('#vf-trace-phase').length, entree: document.querySelectorAll('[data-vf-section=\"vf-trace-phase\"]').length })");
    await s.ev("VibeFlow.go('root')"); await pause(500); o.e4jalon = await lire("document.querySelectorAll('[data-vf-trace-jalon]').length");
    await phase(2); await ouvrir('REQ-01'); o.e4pile = await lire(BTN); await retour(); o.e4retour = await lire("VibeFlow.state.selected");
    reqs.length = 0;
    o.e4cles = await lire(`(async () => { const r = []; for (const [v, c] of [['exigence', 'REQ-01'], ['phase', 'ph-1@deux'], ['exigence', 'REQ-01@deux']]) {
      try { const j = await VFTrace.lire(v, c); r.push(j.etat); } catch (e) { r.push('statut ' + e.statut); } } return r; })()`);
    o.e4req = reqs.filter((x) => x.includes('/api/vf/tracabilite') && x.includes('%40')).length;
  });
  await sec('e6', async () => { // C2.6 : le texte du lab s'affiche littéralement ; aucune donnée de traçabilité hors du panneau
    await charger(); await phase(5); await stabiliser(() => lire("document.querySelectorAll('#vf-trace-phase .vf-trace-ligne').length"), { pas: 150, max: 3000 });
    o.e6 = await lire(`({ marque: [...document.querySelectorAll('#vf-trace-phase .vf-trace-tx')].some((e) => e.textContent.includes('<img src=x onerror=')),
      xss: typeof window.__xss, img: document.querySelectorAll('#panel .vf-trace img').length, vues: document.querySelectorAll('.vf-trace').length > 0 })`);
    await ouvrir('REQ-501'); o.e6pan = await lire(`({ marque: ${PAN}.texte.includes('<img src=x onerror='), xss: typeof window.__xss, img: document.querySelectorAll('#panel .vf-trace img').length })`);
  });
  await sec('e8', async () => { // C2.8 : aucune forme neuve : le témoin positif d'abord, puis aucun canevas ni svg dans .vf-trace
    await charger(); await phase(1);
    o.e8 = await lire(`({ posee: document.querySelectorAll('.vf-trace').length, visible: !!document.querySelector('#vf-trace-phase') && document.querySelector('#vf-trace-phase').offsetHeight > 0,
      moteur: document.querySelectorAll('#stage svg, #stage canvas, svg#svg, #viewport').length, dedans: document.querySelectorAll('.vf-trace canvas, .vf-trace svg').length })`);
  });
  await sec('e9', async () => { // C2.9 : l'exigence ouvre sa décision et sa preuve (P76-D-38)
    await charger(); await phase(1); await s.ev("window.VFTrace.ouvrir = (sorte, cle) => { window.__ouvert = [sorte, cle]; }");
    await ouvrirDirect('REQ-11', 'ph-1');
    o.e9 = await lire(`({ pan: ${PAN}, lignes: [...document.querySelectorAll('#panel [data-vf-trace-panneau] .vf-trace-ligne')].map((b) => ({ id: __tr.nb((b.querySelector('.vf-trace-id') || {}).textContent), txt: __tr.nb(b.textContent) })),
      inertes: [...document.querySelectorAll('#panel [data-vf-trace-panneau] .vf-trace-inerte')].map((e) => __tr.nb(e.textContent)), glyphes: document.querySelectorAll('#panel [data-vf-trace-panneau] .vf-trace-decisions .vf-trace-g').length,
      nue: (await VF_ETAT.lireJson('/api/vf/tracabilite?vue=exigence&cle=REQ-11')).exigence.decisionsNues })`);
    o.e9ledger = fs.readFileSync(`${lab}/.planning/workstreams/x/REQUIREMENTS.md`, 'utf8').includes('D-04');
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace^="decision:"]'); await pause(300); o.e9appel = await lire('window.__ouvert');
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace^="preuve:"]'); await titre('Preuves de la Phase 1');
    o.e9preuve = await lire(`({ cur: [...document.querySelectorAll('#panel [aria-current="true"]')].map((e) => (e.querySelector('.vf-ref code') || {}).textContent), corps: document.body.innerHTML.includes('PREUVE-MARQUEUR-76'),
      reseau: JSON.stringify([await VF_ETAT.lireJson('/api/vf/tracabilite?vue=phase&cle=ph-1'), await VF_ETAT.lireJson('/api/vf/tracabilite?vue=exigence&cle=REQ-11')]).includes('PREUVE-MARQUEUR-76') })`);
    o.e9fichier = fs.readFileSync(`${lab}/.planning/workstreams/x/phases/01-socle/01-VERIFICATION.md`, 'utf8').includes('PREUVE-MARQUEUR-76');
    await charger(); await phase(3); await ouvrir('REQ-02'); o.e9sans = await lire(`${PAN}`);
    await charger(); await phase(2); await ouvrir('REQ-01'); o.e9aucune = await lire(`${PAN}`);
  });
  await sec('e5', async () => { // C2.5 : section Jalon ouverte : un plan retiré du lab remplace le contenu, section ouverte, défilement gardé ; fermée : aucune requête
    await charger(1440, 500); await s.ev("VibeFlow.go('root')"); await pause(400); await clic('#panel details[data-vf-trace-jalon] > summary');
    await vrai("!!document.querySelector('#panel details[data-vf-trace-jalon] .vf-trace-ligne')");
    const ph2 = "[...document.querySelectorAll('#panel details[data-vf-trace-jalon] .vf-trace-ligne')].map((b) => __tr.nb(b.textContent)).find((t) => t.startsWith('Phase 1'))";
    o.e5avant = await lire(ph2); await s.ev("document.getElementById('panel').scrollTop = 40"); const haut = await lire("document.getElementById('panel').scrollTop");
    // 76-08 : le nœud « Exigences » n'existe plus, retirer une exigence ne change plus la STRUCTURE du graphe (un patch, sans rechargement) ; l'événement planning suit un changement de structure :
    // un plan retiré (la carte disparaît) dit la même chose à la ligne de la phase 1 (le maillon « plan » de REQ-12 passe de lu à manquant)
    const reg = `${lab}/.planning/workstreams/x/phases/01-socle/01-02-PLAN.md`, original = fs.readFileSync(reg, 'utf8');
    fs.unlinkSync(reg);
    o.e5change = await attendreValeur(() => lire(`${ph2}`), (v) => v && v !== o.e5avant, { max: 25000 }) !== o.e5avant;
    o.e5apres = await lire(`({ ouvert: document.querySelector('#panel details[data-vf-trace-jalon]').open, haut: document.getElementById('panel').scrollTop === ${haut || 0} })`);
    await clic('#panel details[data-vf-trace-jalon] > summary'); await pause(300); reqs.length = 0;
    fs.writeFileSync(reg, original); await pause(8000);
    o.e5ferme = reqs.filter((x) => x.includes('vue=jalon')).length;
  });
  await sec('e7', async () => { // C2.7 : l'exigence retirée du registre des exigences puis relue : l'objet a disparu
    await charger(); await phase(2); await ouvrir('REQ-01');
    const f = `${lab}/.planning/workstreams/x/REQUIREMENTS.md`; fs.writeFileSync(f, fs.readFileSync(f, 'utf8').split('\n').filter((l) => !l.includes('REQ-01')).join('\n'));
    o.e7 = await attendreValeur(() => lire(`__tr.nb(document.querySelector('#panel [data-vf-trace-panneau]').textContent)`), (v) => /n'existe plus/.test(v || ''), { max: 25000 });
  });
  return o;
}, { csp: true });
