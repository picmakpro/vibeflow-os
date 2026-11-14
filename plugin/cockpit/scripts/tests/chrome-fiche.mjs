// chrome-fiche.mjs <chrome> <scenario.mjs> <base> : joue UN scénario de la fiche d'agent (74-05) dans un Chrome headless, sur le serveur de la suite.
// Le scénario exporte `ids` (sections attendues) et une fonction par défaut `(h) => …` ; chaque section s'écrit `await h.section('P3', async () => …)`,
// et rend ses sondes par h.sonde(id, libellé, ok, obtenu) ou h.egal(id, libellé, obtenu, attendu).
// Sortie : UNE ligne JSON { sondes: [{ id, lib, ok, obtenu }] }.
// Une section qui lève, ou annoncée et jamais jouée, rend UNE sonde rouge : jamais un vert à vide.
// Crochets de page : le fichier nommé par VF_PRE (routes de frise, de transcript et d'état remplacées, espions) est posé avant les scripts
// de la page, derrière l'enveloppe du flux (window.__emit(nom, objet) livre un événement aux écouteurs du flux vivant).
// Aides de h : ev · attendre · monter({ largeur, hauteur, coarse, media, voies, who, fil }) · poser({ voies, statut, tronque, sourceEtat, delai })
//   · filFixe({ id: corps }, { statut, delai }) · who(workers) · ouvrir(id, selecteurOrigine) · fermer() · reqs(motif) · touche() · cycle()
//   · ratio(a, b) · horloge().
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
import { executer, pause, attendreValeur, stabiliser } from './chrome-session.mjs';
import { AMORCE_FLUX } from './chrome-onglets.mjs';
import * as FAB from './frise-fabrique.mjs';

const [, , chrome, fichier, base] = process.argv;
const PRE = process.env.VF_PRE ? fs.readFileSync(process.env.VF_PRE, 'utf8') : '';
const appel = (f, args) => (typeof f === 'function' ? `(${f})(...${JSON.stringify(args)})` : f);
const lum = (c) => {
  const m = /rgba?\((\d+),\s*(\d+),\s*(\d+)/.exec(c);
  if (!m) return null;
  const l = [m[1], m[2], m[3]].map((x) => { const v = x / 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
  return 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2];
};
const FICHE_PRETE = "(() => { const f = document.querySelector('.vf-fiche'); return !!f && f.getAttribute('aria-busy') !== 'true'; })()";

await executer(chrome, async (s) => {
  const mod = await import(pathToFileURL(fichier).href);
  const sondes = [], vues = new Set();
  const h = { s, base, FAB, MIN: FAB.MIN, pause, attendreValeur, stabiliser, sondes };
  h.ev = (f, ...a) => s.ev(appel(f, a));
  h.attendre = (f, nom, ms) => s.attendre(typeof f === 'function' ? appel(f, []) : f, nom, ms);
  h.sonde = (id, lib, ok, obtenu = '') => {
    vues.add(id.split('.')[0]);
    sondes.push({ id, lib, ok: !!ok, obtenu: String(obtenu).replace(/\s+/g, ' ').slice(0, 400) });
  };
  h.egal = (id, lib, obtenu, attendu) => {
    const o = JSON.stringify(obtenu), a = JSON.stringify(attendu);
    h.sonde(id, lib, o === a, o === a ? '' : `obtenu ${o} attendu ${a}`);
  };
  h.section = async (id, corps) => {
    vues.add(id);
    const avant = sondes.length;
    try { await corps(); } catch (e) { h.sonde(id, 'section interrompue', false, e.message); }
    if (sondes.length === avant) h.sonde(id, 'section sans sonde', false, 'aucune sonde rendue');
  };
  h.ratio = (a, b) => {
    const x = lum(a), y = lum(b);
    return x == null || y == null ? 0 : (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
  };
  h.horloge = () => s.ev('Date.now()');

  // les fixtures sont posées dans la page : la frise (fabrique, à l'heure de la page), les fils par agent, l'état (missions et phases)
  h.poser = async (o = {}) => {
    const now = await h.horloge();
    const voies = typeof o.voies === 'function' ? o.voies(now, FAB) : o.voies;
    const rep = o.brut ?? FAB.fabrique({ now, voies, tronque: o.tronque, voiesOmises: o.voiesOmises, sourceEtat: o.sourceEtat });
    await s.ev(`Object.assign(window.__vfF, { reponse: ${JSON.stringify(rep)}, statut: ${o.statut ?? 200}, delai: ${o.delai ?? 0} })`);
    return now;
  };
  h.filFixe = async (par, o = {}) => {
    await s.ev(`Object.assign(window.__vfT, { parId: ${JSON.stringify(par)}, statut: ${o.statut ?? 200}, delai: ${o.delai ?? 0} })`);
  };
  h.reqs = (motif = 'depuis=') => s.ev(`window.__req.filter((u) => u.includes(${JSON.stringify(motif)})).length`);
  h.emettre = (nom = 'frise', n = 1) => s.ev(`window.__emit(${JSON.stringify(nom)}, { seq: ${n}, at: Date.now(), sig: 'x${n}' })`);
  // who : le garde-fou de rechargement de 72-vf-equipe.js est posé (une structure d'équipe changée recharge la page au plus une fois par 15 s)
  h.who = async (workers, seq = 1) => {
    const corps = JSON.stringify({ workers });
    await s.ev(`sessionStorage.setItem('vf-equipe-rechargement', String(Date.now())); window.__emit('who', { seq: ${seq}, at: Date.now(), who: ${corps} })`);
    await s.attendre(`!!window.VF_ETAT.lire('who') && window.VF_ETAT.lire('who').workers.length === ${workers.length}`, 'who posé');
  };
  h.touche = async (key, code, vk, text) => {
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk, text });
    await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk });
  };
  h.echap = () => h.touche('Escape', 'Escape', 27);
  h.fiche = async () => {
    await s.attendre(FICHE_PRETE, 'fiche posée');
    const lire = "(() => { const f = document.querySelector('.vf-fiche'); "
      + "return f ? [f.getBoundingClientRect().height, f.querySelectorAll('*').length] : null; })()";
    return stabiliser(() => s.ev(lire), { pas: 200, max: 8000 });
  };
  // ouvrir : par la fonction publique (origine = élément du sélecteur, sinon null), puis attend la fiche posée
  h.ouvrir = async (id, selecteur = null, attente = true) => {
    const ok = await s.ev(`(() => { const o = ${selecteur ? `document.querySelector(${JSON.stringify(selecteur)})` : 'null'};
      if (!window.__vfFiche) return false; window.__vfFiche.ouvrir(${JSON.stringify(id)}, o); return true; })()`);
    if (!ok) throw new Error('window.__vfFiche absent');
    if (attente) await h.fiche();
  };
  h.fermer = async () => {
    await s.ev("(() => { const b = document.querySelector('.vf-fiche-retour'); if (b) b.click(); })()");
    await s.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée');
  };
  h.cycle = async (autre = 'code') => {
    await s.ev(`window.VF_COQUILLE.chargerOnglet(${JSON.stringify(autre)}).then(() => 1)`);
    await s.attendre(`window.VF_COQUILLE.onglet() === ${JSON.stringify(autre)} && document.documentElement.dataset.vfPret === 'oui'`, `onglet ${autre}`);
    await s.ev("window.VF_COQUILLE.chargerOnglet('equipe').then(() => 1)");
    const revenu = "window.VF_COQUILLE.onglet() === 'equipe' && document.documentElement.dataset.vfPret === 'oui' && !!document.querySelector('#vf-equipe')";
    await s.attendre(revenu, 'retour sur Équipe');
    await s.attendre("!!window.VF_ETAT.lire('etat')", 'état relu après le retour');
  };
  // monter : la page Équipe (régie), fixtures posées, who émis si demandé
  h.monter = async (o = {}) => {
    const { largeur = 1280, hauteur = 800, coarse = false, media = [] } = o;
    await s.ev("(() => { try { sessionStorage.clear(); localStorage.clear(); } catch {} })()");
    await s.send('Emulation.setDeviceMetricsOverride', { width: largeur, height: hauteur, deviceScaleFactor: 1, mobile: coarse && largeur <= 700 });
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: coarse, maxTouchPoints: coarse ? 1 : 0 });
    await s.send('Emulation.setEmulatedMedia', { features: media });
    await s.naviguer(`${base}/equipe.html`);
    await s.attendre("!!document.querySelector('#vf-equipe') && !!window.VF_ETAT && !!window.VF_ETAT.lire('etat')", 'régie et état montés');
    await h.poser(o);
    if (o.fil) await h.filFixe(typeof o.fil === 'function' ? o.fil(await h.horloge(), FAB) : o.fil);
    if (o.who) await h.who(o.who);
  };

  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_FLUX });
  if (PRE) await s.send('Page.addScriptToEvaluateOnNewDocument', { source: PRE });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  try { await mod.default(h); } catch (e) { for (const id of mod.ids || []) if (!vues.has(id)) h.sonde(id, 'scénario interrompu', false, e.message); }
  for (const id of mod.ids || []) if (!vues.has(id)) h.sonde(id, 'section non jouée', false, 'aucune sonde rendue');
  return { sondes };
}, { csp: true });
