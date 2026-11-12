// chrome-fr-etats.mjs — sondes et relevé des ÉTATS de la page, en français et sous ?lang=en (79-10, SOCL-14, P79-D-16, P79-D-24).
// Usage : node chrome-fr-etats.mjs sondes  <chrome> <url>                     F21 : libellés connus, lus dans la page
//         node chrome-fr-etats.mjs donnee  <chrome> <url>                     F20.2 : un « Health » posé dans le panneau est-il réécrit ?
//         node chrome-fr-etats.mjs sante   <chrome> <url>                     F23 : un constat de Santé de fixture, tel qu'il s'affiche
//         node chrome-fr-etats.mjs releve  <chrome> <index> <projet> [<sante>] relevé des textes et attributs, par page, mode et état (JSON)
//         node chrome-fr-etats.mjs comparer <avant.json> <apres.json> [<trace>] écarts ; ceux d'une ligne `ECART-ADMIS <page-mode>/<état> <texte>` de la trace sont admis
// Les pages sont des fichiers (`file://`) : aucun serveur. Chaque état part d'une page rechargée ; il est attendu par une condition de la page, jamais par une pause fixe.
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
import { executer, stabiliser, attendreValeur } from './chrome-session.mjs';

const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout && !!document.querySelector('header .brand .mark') && !!document.getElementById('panel')";
const VF = 'window.VibeFlow';
const url = (f, en) => pathToFileURL(f).href + (en ? '?lang=en' : '');
const clic = (id) => `document.getElementById(${JSON.stringify(id)}).click()`;
// une feuille quelconque de l'arbre des cartes (le premier identifiant sans enfant) et un dossier (le premier enfant de la racine qui en a)
const FEUILLE = `(() => { const file = ['root']; const vus = new Set(); while (file.length) { const c = file.shift(); if (vus.has(c)) continue; vus.add(c); let ks = []; try { ks = ${VF}.children(c) || []; } catch (e) { continue; } for (const i of ks) { let k = []; try { k = ${VF}.children(i) || []; } catch (e) {} if (!k.length) return i; file.push(i); } } return null; })()`;
const DOSSIER = `(() => { const ks = ${VF}.children('root') || []; return ks.find((i) => (${VF}.children(i) || []).length) || null; })()`;
// le relevé ne dépend pas du poste : le nom de la branche git du lab (master ou main selon la configuration) est uniformisé, un fragment de chemin (« dossier/ ») n'est pas un texte
const LIRE = `(() => { const norme = (x) => x.replace(/\\s+/g, ' ').trim().replace(/\\b(master|main)\\b/g, 'BRANCHE'); const out = new Set(); const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); for (let n = w.nextNode(); n; n = w.nextNode()) { const p = n.parentElement; if (!p || p.closest('script,style')) continue; const t = norme(n.nodeValue); if (t && !/^[-\\w.]+\\/$/.test(t)) out.add(t); }
  for (const e of document.querySelectorAll('[title],[aria-label],[placeholder],[alt]')) for (const a of ['title', 'aria-label', 'placeholder', 'alt']) { const v = e.getAttribute(a); if (v && v.trim()) out.add('@' + a + ' ' + norme(v)); }
  out.add('@titre-document ' + document.title); out.add('@lang ' + document.documentElement.lang); return [...out].sort(); })()`;

// états de chaque page : [nom, geste (expression), condition d'arrivée]
const ETATS = {
  code: [
    ['accueil', 'true', 'true'],
    ['legende', clic('filters-btn'), "document.getElementById('legend').classList.contains('open')"],
    ['parcours', clic('flows-btn'), "document.getElementById('flowmenu').classList.contains('open')"],
    ['recherche', `(() => { ${clic('search-btn')}; const i = document.getElementById('search'); i.value = 'src'; i.dispatchEvent(new Event('input', { bubbles: true })); })()`, "document.querySelectorAll('#results .r').length > 0"],
    ['recherche-vide', `(() => { ${clic('search-btn')}; const i = document.getElementById('search'); i.value = 'zzzzqq'; i.dispatchEvent(new Event('input', { bubbles: true })); })()`, "document.getElementById('results').innerText.trim().length > 0 && document.querySelectorAll('#results .r').length === 0"],
    ['sante', clic('btn-health'), "!!document.querySelector('#panel .hc-issue, #panel .hc-calm')"],
    ['detail-technique', `${VF}.setTechnical(true)`, `${VF}.technical() === true`],
    ['export', clic('btn-export'), "document.getElementById('modal').classList.contains('open') || !!document.querySelector('#modal .box h2, #modal .box .pt')"],
    ['fichier', `${VF}.reveal(${FEUILLE})`, "!!document.querySelector('#panel .pt') && !!document.querySelector('#panel .pd, #panel .sec')"],
    ['dossier', `${VF}.go(${DOSSIER})`, `${VF}.state.container !== 'root' && !!document.querySelector('#viewport .node .card')`],
    ['reponse', `${VF}.showBoard({ title: 'Résultat', items: [${FEUILLE}] })`, "!!document.querySelector('#panel .row.vf-rep, #panel .row')"],
    ['infobulle', `(() => { const g = document.querySelector('#viewport .node'); g.dispatchEvent(new MouseEvent('mouseenter', { bubbles: false })); })()`, "!document.getElementById('tooltip').hidden"],
    ['lien', `(async () => { ${VF}.go(${DOSSIER}); await new Promise((ok) => setTimeout(ok, 600)); const es = [...(${VF}.state.edgeEls || new Map()).entries()].filter(([, v]) => v.e.k !== 'contains'); if (es.length) es[0][1].g.dispatchEvent(new MouseEvent('click', { bubbles: true })); })()`, "!!document.querySelector('#panel .pt') && document.querySelector('#panel .pt').textContent.includes('→')"],
  ],
  projet: [
    ['accueil', 'true', 'true'],
    ['phase', `${VF}.reveal(${FEUILLE})`, "!!document.querySelector('#panel .pt') && !!document.querySelector('#panel .sec')"],
    ['sante', clic('btn-health'), "!!document.querySelector('#panel .hc-issue, #panel .hc-calm')"],
  ],
};
const lire = (s) => stabiliser(() => s.ev(LIRE), { pas: 300, max: 8000 });
// la page est prête quand la visite guidée de départ, qui change la vue, a fini de se poser (elle part après le premier rendu : un geste fait avant la rejoue sur une autre vue)
async function pret(s) { await s.attendre(PRET, 'page prête'); await attendreValeur(() => s.ev("!!document.querySelector('#tour .tk')"), (v) => v, { pas: 150, max: 6000 }); }
async function charger(s, f, en) { try { await s.send('Storage.clearDataForOrigin', { origin: 'file://', storageTypes: 'local_storage' }); } catch (e) {} await s.naviguer(url(f, en)); await pret(s); }
async function fenetre(s) { await s.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 900, deviceScaleFactor: 1, mobile: false }); }

const [, , mode, ...a] = process.argv;
if (mode === 'comparer') {
  const [avant, apres, trace] = a; const A = JSON.parse(fs.readFileSync(avant, 'utf8')), B = JSON.parse(fs.readFileSync(apres, 'utf8'));
  const admis = new Set(trace ? fs.readFileSync(trace, 'utf8').split('\n').filter((l) => l.startsWith('ECART-ADMIS ')).map((l) => l.slice(12)) : []);
  const ecarts = [];
  for (const [cle, etats] of Object.entries(A)) for (const [nom, av] of Object.entries(etats)) {
    const ap = new Set((B[cle] || {})[nom] || []), as = new Set(av);
    for (const t of av) if (!ap.has(t) && !admis.has(`${cle}/${nom} ${t}`)) ecarts.push(`${cle}/${nom} AVANT seulement : ${t}`);
    for (const t of ap) if (!as.has(t) && !admis.has(`${cle}/${nom} ${t}`)) ecarts.push(`${cle}/${nom} APRÈS seulement : ${t}`);
  }
  for (const cle of Object.keys(B)) if (!A[cle]) ecarts.push(`${cle} absent du relevé AVANT`);
  console.log(JSON.stringify(ecarts)); process.exit(0);
}
const [chrome, f1, f2, f3] = a;
await executer(chrome, async (s) => {
  await fenetre(s);
  if (mode === 'sondes') {
    await s.naviguer(f1); await pret(s);
    await s.ev(clic('search-btn')); await s.ev("(() => { const i = document.getElementById('search'); i.value = 'zzzzqq'; i.dispatchEvent(new Event('input', { bubbles: true })); })()");
    await s.attendre("document.getElementById('results').innerText.trim().length > 0", 'résultat vide');
    return stabiliser(() => s.ev("({ fit: document.getElementById('z-fit').title, vide: document.getElementById('results').innerText, export: (document.getElementById('btn-export') || {}).textContent, exportTitre: (document.getElementById('btn-export') || {}).title, sante: (document.querySelector('#btn-health .bl') || {}).textContent })"), { pas: 300, max: 8000 });
  }
  if (mode === 'donnee') {
    await s.naviguer(f1); await pret(s);
    await s.ev("(() => { const e = document.createElement('span'); e.id = 'vf-sonde-donnee'; e.textContent = 'Health'; document.getElementById('panel').appendChild(e); })()");
    return { texte: await stabiliser(() => s.ev("document.getElementById('vf-sonde-donnee').textContent"), { pas: 400, max: 5000 }) };
  }
  if (mode === 'sante') {
    await s.naviguer(f1); await pret(s);
    await s.ev(`${VF}.setTechnical(true)`); await stabiliser(() => s.ev("document.getElementById('panel').innerHTML.length"), { pas: 300, max: 8000 }); // le rendu qui suit ne referme pas la liste
    await s.ev(clic('btn-health')); await s.attendre("!!document.querySelector('#panel .hc-issue .hc-w')", 'liste de Santé et localisations');
    const liste = await stabiliser(() => s.ev("[...document.querySelectorAll('#panel .hc-issue')].map((e) => ({ titre: (e.querySelector('.hc-t') || {}).textContent, detail: (e.querySelector('.hc-d') || {}).textContent || null, lieux: (e.querySelector('.hc-w') || {}).innerText || null }))"), { pas: 300, max: 8000 });
    await s.ev("document.querySelector('[data-hc-show]').click()"); await s.attendre("!!document.querySelector('#panel .pt') && !document.querySelector('#panel .hc-issue')", 'tableau sur la carte');
    const tableau = await stabiliser(() => s.ev("({ titre: document.querySelector('#panel .pt').textContent, question: (document.querySelector('#panel .pd') || {}).textContent })"), { pas: 300, max: 8000 });
    return { liste, tableau };
  }
  if (mode === 'releve') {
    const sortie = {};
    const pages = [['code', f1, ETATS.code], ['projet', f2, ETATS.projet], ...(f3 ? [['sante', f3, [['constats', clic('btn-health'), "!!document.querySelector('#panel .hc-issue')"], ['constats-detail', `(async () => { ${VF}.setTechnical(true); await new Promise((ok) => setTimeout(ok, 1200)); ${clic('btn-health')}; })()`, "!!document.querySelector('#panel .hc-w')"]]]] : [])];
    for (const [nom, fichier, etats] of pages) for (const en of [false, true]) {
      const cle = `${nom}-${en ? 'en' : 'fr'}`; sortie[cle] = {}; let base = new Set();
      for (const [etat, geste, cond] of etats) {
        await charger(s, fichier, en); await s.ev(geste); await s.attendre(cond, `état ${cle}/${etat}`);
        const v = await lire(s); if (etat === 'accueil' || etat === 'constats') base = new Set(v);
        sortie[cle][etat] = etat === 'accueil' || etat === 'constats' ? v : v.filter((t) => !base.has(t));
      }
    }
    return sortie;
  }
  return { erreur: `mode inconnu : ${mode}` };
});
