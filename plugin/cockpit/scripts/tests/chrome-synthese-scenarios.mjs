// chrome-synthese-scenarios.mjs — scénarios navigateur de la coquille de la Synthèse (77-05), joués par chrome-synthese.mjs. Une ligne JSON, ou { erreur }.
//   nue     module SANS bloc : le bouton, ses attributs, la ligne-résumé absente, ouverture, focus, Échap, onglets Code et Équipe, page exportée, CSP, fichier servi
//   temoin  module + bloc témoin (registre, ligne-résumé, titre, rafraîchissement, onglets, écouteurs, réseau, mouvement réduit, largeurs, tactile, tiroirs)
// Les lectures se font une fois la page posée (stabiliser / attendre), jamais dans la foulée du geste.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
import { AMORCE_ECOUTEURS, AMORCE_VISITE, journalReseau, MARQUEUR_RACINE } from './chrome-synthese.mjs';

const BTN = `document.getElementById('btn-synthese')`;
const OUVERTE = `!!document.querySelector('#panel > .vf-sy')`;
const NOM = `(() => { const b = ${BTN}; return b ? (b.getAttribute('aria-label') || b.title || '') : null; })()`;
const FICHE_BTN = `(() => { const b = ${BTN}; if (!b) return null; const sa = document.getElementById('btn-health');
  return { n: document.querySelectorAll('#btn-synthese').length, apresSante: !!sa && sa.nextElementSibling === b, controls: b.getAttribute('aria-controls'), expanded: b.getAttribute('aria-expanded'),
    nom: b.getAttribute('aria-label') || '', title: b.title, badge: !!b.querySelector('.badge'), bl: (b.querySelector('.bl') || {}).textContent || '', chiffre: /[0-9]/.test(b.textContent) }; })()`;
const FOCUS = `(() => { const a = document.activeElement; return a ? { tag: a.tagName, id: a.id || '', dansSynth: !!a.closest('.vf-sy'), texte: (a.textContent || '').slice(0, 30) } : null; })()`;
const touche = async (s, key, code, vk) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk }); };
const largeur = async (s, w) => { await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(150); };

async function pages(s, base, r) {
  r.pages = [];
  for (const u of ['/', '/project.html', '/equipe.html']) {
    await s.naviguer(base + u);
    r.pages.push(await s.ev(`({ u: ${JSON.stringify(u)}, tabs: document.querySelectorAll('nav.vf-tabs a').length, roleTab: document.querySelectorAll('[role="tab"]').length,
      btn: document.querySelectorAll('#btn-synthese').length, sante: document.querySelectorAll('#btn-health').length })`));
  }
}
async function exportee(s, fichier, r) {
  await s.naviguer('file://' + fichier, { brut: true }); await s.attendre(`!!window.VibeFlow`, 'page exportée chargée');
  r.exportee = await s.ev(`({ btn: document.querySelectorAll('#btn-synthese').length, coquille: !!window.VF_COQUILLE, exportee: !!window.VibeFlow.exported })`);
}

export async function jouer(chrome, port, mode, fichierExport) {
  await executer(chrome, async (s) => {
    const base = `http://127.0.0.1:${port}`, r = { mode }, erreurs = [];
    await s.send('Runtime.enable'); s.ecouter('Runtime.exceptionThrown', (p) => erreurs.push(String(p.exceptionDetails?.exception?.description || p.exceptionDetails?.text).slice(0, 160)));
    await largeur(s, 1440); // poste de bureau : sous 1000 px le bouton d'en-tête vit dans le menu « ⋯ » et un panneau fermé s'ouvre en poussant la carte
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_ECOUTEURS + AMORCE_VISITE });
    const J = await journalReseau(s);
    await pages(s, base, r); if (fichierExport) await exportee(s, fichierExport, r);
    await s.naviguer(base + '/project.html'); await s.attendre(`!!${BTN}`, 'bouton Synthèse posé');
    // la clé du viewer lui-même (vf-cockpit:panel, état ouvert/fermé du panneau, écrite à l'ouverture de TOUT panneau) est hors du périmètre de la Synthèse
    const stocks = `JSON.stringify([Object.keys(localStorage).filter((k) => k !== 'vf-cockpit:panel').sort(), Object.keys(sessionStorage).sort(), Object.entries(sessionStorage)])`, stock0 = await s.ev(stocks);
    r.pre = await s.ev(`({ surOnglet: typeof window.VF_COQUILLE.surOnglet, lireJson: typeof window.VF_ETAT.lireJson, jeton: typeof window.VF_ETAT.jeton })`);
    r.bouton = await s.ev(FICHE_BTN); r.ligneAvant = await s.ev(`document.querySelectorAll('[data-vf-sy-resume]').length`);
    const vp = `(() => { const v = document.getElementById('viewport'); const b = v.getBoundingClientRect(); return JSON.stringify([b.x, b.y, b.width, b.height, v.getAttribute('transform')]); })()`;
    const p = `(() => { const e = document.getElementById('panel'); return Math.round(e.getBoundingClientRect().width * 10) / 10; })()`;
    r.vp0 = await stabiliser(() => s.ev(vp)); r.panneauLargeur0 = await s.ev(p);
    await s.ev(`${BTN}.click()`); await s.attendre(OUVERTE, 'Synthèse ouverte'); await pause(300);
    r.ouvert = await s.ev(`({ ...${FICHE_BTN}, h2: (document.querySelector('#panel > .vf-sy h2.pt') || {}).textContent, tab: (document.querySelector('#panel > .vf-sy h2.pt') || {}).getAttribute?.('tabindex'),
      sr: (() => { const e = document.querySelector('#panel > .vf-sy .sr'); return e ? [e.getAttribute('role'), e.getAttribute('aria-live'), e.getAttribute('aria-atomic')].join() : null; })(),
      fermer: [...document.querySelectorAll('#panel .vf-sy button')].map((b) => b.textContent.trim()), focus: ${FOCUS}.tag + ':' + ${FOCUS}.dansSynth })`);
    r.vp1 = await stabiliser(() => s.ev(vp)); r.panneauLargeur1 = await s.ev(p);
    r.regleFeuille = await s.ev(`(() => { const st = document.getElementById('vf-sy-coquille'); return st ? { n: document.querySelectorAll('#vf-sy-coquille').length, surPanneau: /#panel(?![\\w-])/.test(st.textContent) } : null; })()`);
    await touche(s, 'Escape', 'Escape', 27); await attendreValeur(() => s.ev(`!${OUVERTE}`), (v) => v === true, { max: 3000 });
    r.echap = await s.ev(`({ ouverte: ${OUVERTE}, focus: ${FOCUS}.id, expanded: ${BTN}.getAttribute('aria-expanded') })`);
    await s.ev(`${BTN}.click()`); await s.attendre(OUVERTE, 'Synthèse rouverte'); await s.ev(`${BTN}.focus()`); await touche(s, 'Escape', 'Escape', 27);
    await attendreValeur(() => s.ev(`!${OUVERTE}`), (v) => v === true, { max: 3000 }); r.echapBouton = await s.ev(`({ ouverte: ${OUVERTE}, focus: ${FOCUS}.id })`);
    await s.ev(`${BTN}.click()`); await s.attendre(OUVERTE, 'ouverte'); await s.ev(`${BTN}.click()`); await attendreValeur(() => s.ev(`!${OUVERTE}`), (v) => v === true, { max: 3000 });
    r.basculeFerme = await s.ev(`({ ouverte: ${OUVERTE}, expanded: ${BTN}.getAttribute('aria-expanded') })`);
    const stock1 = await s.ev(stocks); r.stockApres = stock1 === stock0; r.stockDiag = [stock0, stock1]; r.csp = s.violations.length;
    r.fichier = await s.ev(`(async () => { const e = performance.getEntriesByType('resource').find((x) => /\\/74-vf-synthese\\.js(\\?|$)/.test(x.name)); if (!e) return null;
      const f = await fetch(e.name); return { statut: f.status, etag: !!f.headers.get('ETag') }; })()`);
    if (mode === 'temoin') await (await import('./chrome-synthese-temoin.mjs')).mesures(s, base, r, J);
    r.erreursPage = erreurs; r.reseauNb = J.length; r.marqueur = MARQUEUR_RACINE;
    return r;
  }, { csp: true });
}
