// chrome-frise.mjs <chrome> <scenario.mjs> <base> : joue UN scénario de la frise (74-04) dans un Chrome headless, sur le serveur de la suite.
// Le scénario exporte `ids` (les sections qu'il doit rendre) et une fonction par défaut `(h) => …` ; chaque section s'écrit `await h.section('S4', async () => …)`,
// et rend ses sondes par h.sonde(section, libellé, ok, obtenu) ou h.egal(section, libellé, obtenu, attendu). Sortie : UNE ligne JSON { sondes: [{ id, lib, ok, obtenu }] }
// (jamais un chemin du poste). Une section qui lève, ou une section annoncée jamais jouée, rend UNE sonde rouge : jamais un vert à vide.
// Crochets de page : le fichier nommé par VF_PRE (fetch de la route de frise remplacé, espions) est posé avant les scripts de la page, derrière l'enveloppe du flux
// (AMORCE_FLUX : window.__emit(nom, objet) livre un événement aux écouteurs du flux vivant). Aides « mesurer une fois posé » : chrome-session.mjs.
// Aides de h : ev(f, ...args) · attendre · monter({ vue, largeur, hauteur, coarse, media, voies… }) · poser({ voies, tronque, voiesOmises, sourceEtat, statut, delai, brut })
//   · choisir(libelle) · attendreFrise() · emettre() · reqs() · touche(…) · couleur(variable) · cycle() · ratio(a, b) (contraste WCAG).
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
import { executer, pause, attendreValeur, stabiliser } from './chrome-session.mjs';
import { AMORCE_FLUX } from './chrome-onglets.mjs';
import * as FAB from './frise-fabrique.mjs';

const [, , chrome, fichier, base] = process.argv;
const PRE = process.env.VF_PRE ? fs.readFileSync(process.env.VF_PRE, 'utf8') : '';
const NB = ' ';
const appel = (f, args) => (typeof f === 'function' ? `(${f})(...${JSON.stringify(args)})` : f);
const lum = (c) => { const m = /rgba?\((\d+),\s*(\d+),\s*(\d+)/.exec(c); if (!m) return null; const l = [m[1], m[2], m[3]].map((x) => { const v = x / 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; }); return 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2]; };

await executer(chrome, async (s) => {
  const mod = await import(pathToFileURL(fichier).href);
  const sondes = [], vues = new Set();
  const h = { s, base, FAB, NB, MIN: FAB.MIN, pause, attendreValeur, stabiliser, sondes };
  h.ev = (f, ...a) => s.ev(appel(f, a));
  h.attendre = (f, nom, ms) => s.attendre(typeof f === 'function' ? appel(f, []) : f, nom, ms);
  h.sonde = (id, lib, ok, obtenu = '') => { vues.add(id); sondes.push({ id, lib, ok: !!ok, obtenu: String(obtenu).replace(/\s+/g, ' ').slice(0, 400) }); };
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
  h.ratio = (a, b) => { const x = lum(a), y = lum(b); return x == null || y == null ? 0 : (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };

  // la réponse de la route de frise : fixture de la fabrique, à l'heure de la page (jamais l'horloge du scénario)
  h.poser = async (o = {}) => {
    const now = await s.ev('Date.now()');
    let voies = typeof o.voies === 'function' ? o.voies(now, FAB) : o.voies;
    // la fabrique pose la queue « attend-humain » jusqu'à son NOW constant : ramenée à l'heure de la page (la route la pose jusqu'à `jusqua`)
    if (voies === undefined && !o.brut) voies = FAB.voiesParDefaut(now);
    for (const v of voies || []) { if (v.fin === FAB.NOW) v.fin = now; for (const s of v.segments) if (s[1] === FAB.NOW) s[1] = now; }
    const rep = o.brut ?? FAB.fabrique({ now, voies, tronque: o.tronque, voiesOmises: o.voiesOmises, sourceEtat: o.sourceEtat });
    if (o.sansOmises) delete rep.voiesOmises;
    await s.ev(`window.__vfF.reponse = ${JSON.stringify(rep)}; window.__vfF.statut = ${o.statut ?? 200}; window.__vfF.delai = ${o.delai ?? 0}`);
    return now;
  };
  h.reqs = async (motif = 'depuis=') => s.ev(`window.__vfF.reqs.filter((r) => r.url.includes(${JSON.stringify(motif)})).map((r) => r.url)`);
  h.emettre = (n = 1) => s.ev(`window.__emit('frise', { seq: ${n}, at: Date.now(), sig: 'x${n}' })`);
  h.couleur = (v) => s.ev(`window.__couleur(${JSON.stringify(v)})`);
  // calme : le nombre de lectures de la route ne bouge plus pendant 1,6 s (les lectures du montage et de la coalescence sont passées)
  h.calme = () => stabiliser(async () => (await h.reqs()).length, { pas: 1600, max: 15000 });
  // changer : joue un geste, attend UNE lecture de plus de la route (bornes) puis la frise posée
  h.changer = async (geste) => {
    const n0 = (await h.reqs()).length;
    await geste();
    await attendreValeur(async () => (await h.reqs()).length, (n) => n > n0, { max: 8000 });
    return h.attendreFrise();
  };
  h.radio = (libelle) => h.ev((l) => { const r = [...document.querySelectorAll('.vf-frise-outils [role=radio]')].find((x) => x.textContent === l); if (r) r.click(); return !!r; }, libelle);
  h.touche = async (key, code, vk, text) => {
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk, text });
    await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk });
  };
  h.attendreFrise = async () => {
    await s.attendre("!!document.querySelector('.vf-frise') && document.querySelector('.vf-frise').getAttribute('aria-busy') !== 'true'", 'frise posée');
    return stabiliser(() => s.ev("(() => { const r = document.querySelector('.vf-frise'); return r ? [r.getBoundingClientRect().height, r.querySelectorAll('*').length] : null; })()"), { pas: 200, max: 8000 });
  };
  h.choisir = async (libelle) => {
    await s.attendre("!!document.querySelector('#vf-equipe [role=tablist] [role=tab]')", 'bascule dessinée par la régie');
    const ok = await h.ev((l) => { const t = [...document.querySelectorAll('#vf-equipe [role=tab]')].find((x) => x.textContent === l); if (t) t.click(); return !!t; }, libelle);
    if (!ok) throw new Error(`position « ${libelle} » absente de la bascule`);
  };
  // monter : la page Équipe (régie), puis, par défaut, la position « Frise » ; les réglages de session ne survivent à aucun montage sauf { garder: true }
  h.monter = async (o = {}) => {
    const { largeur = 1440, hauteur = 900, vue = 'frise', coarse = false, media = [], garder = false } = o;
    if (!garder) await s.ev("(() => { try { sessionStorage.clear(); } catch {} })()");
    await s.send('Emulation.setDeviceMetricsOverride', { width: largeur, height: hauteur, deviceScaleFactor: 1, mobile: coarse && largeur <= 700 });
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: coarse, maxTouchPoints: coarse ? 1 : 0 });
    await s.send('Emulation.setEmulatedMedia', { features: media });
    await s.naviguer(`${base}/equipe.html`);
    await s.attendre("!!document.querySelector('#vf-equipe') && !!window.__vfEquipeVues && !!window.VF_ETAT", 'régie montée');
    if (o.voies !== undefined || o.brut !== undefined || o.statut !== undefined || o.sourceEtat !== undefined || o.delai !== undefined || o.tronque !== undefined || !o.sans) await h.poser(o);
    if (vue === 'frise') { await h.choisir('Frise'); if (!o.sansAttente) await h.attendreFrise(); }
  };
  // cycle : quitter l'onglet Équipe pour un autre et y revenir (la coquille ré-exécute les scripts de l'onglet)
  h.cycle = async (autre = 'code') => {
    await s.ev(`window.VF_COQUILLE.chargerOnglet(${JSON.stringify(autre)}).then(() => 1)`);
    await s.attendre(`window.VF_COQUILLE.onglet() === ${JSON.stringify(autre)} && document.documentElement.dataset.vfPret === 'oui'`, `onglet ${autre}`);
    await s.ev("window.VF_COQUILLE.chargerOnglet('equipe').then(() => 1)");
    await s.attendre("window.VF_COQUILLE.onglet() === 'equipe' && document.documentElement.dataset.vfPret === 'oui' && !!document.querySelector('#vf-equipe')", 'retour sur Équipe');
  };

  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_FLUX });
  if (PRE) await s.send('Page.addScriptToEvaluateOnNewDocument', { source: PRE });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  try { await mod.default(h); } catch (e) { for (const id of mod.ids || []) if (!vues.has(id)) h.sonde(id, 'scénario interrompu', false, e.message); }
  for (const id of mod.ids || []) if (!vues.has(id)) h.sonde(id, 'section non jouée', false, 'aucune sonde rendue');
  return { sondes };
}, { csp: true });
