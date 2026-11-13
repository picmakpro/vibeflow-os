#!/usr/bin/env node
// coquille-chrome.mjs — mesures navigateur de la suite de la coquille (79-16, SOCL-20). Socle : chrome-session.mjs (aucune dépendance).
// Chaque mode rend UNE ligne JSON ({ erreur } sur échec nommé). Les relevés qui jugent un état du document passent par la sonde
// (coquille-sonde.mjs, posée avant tout script de la page), jamais par le journal de la coquille.
//   charger <chrome> <url>…                 charge chaque adresse : onglet vu par le moteur, état, violations, réponses de /_vf/ (CDP réseau)
//   avec <chrome> <url> <fichier-js>        charge <url> (sonde posée) puis joue le corps JS du fichier (async ; reçoit s, reseau, erreurs, SOMMAIRE, pause, panne) :
//                                           rend la valeur qu'il retourne ; `reseau` = requêtes { url, methode, inm, statut } ; `erreurs` = exceptions de page ;
//                                           en-têtes du fichier : `// echec: true`, `// amorce: <js>`, `// panne: oui|non` (interception des lectures de graphe)
import fs from 'node:fs';
import { executer, pause } from './chrome-session.mjs';
import { SONDE } from './coquille-sonde.mjs';

const [, , mode, chrome, ...args] = process.argv;
const SOMMAIRE = `(() => { const V = window.VibeFlow; return { tab: V?.graph?.meta?.vfTab ?? null, layout: !!V?.state?.layout, noeuds: V?.graph?.nodes?.length ?? null,
  vus: (V?.graph?.nodes || []).map((n) => n.id + '|' + (n.st || '')), onglet: window.VF_COQUILLE?.onglet?.() ?? null, pret: document.documentElement.dataset.vfPret ?? null, titre: document.title, etat: window.VF_COQUILLE?.etat?.() ?? null }; })()`;

if (mode === 'charger') {
  await executer(chrome, async (s) => {
    const reponses = [], erreurs = []; await s.send('Network.enable'); await s.send('Runtime.enable');
    s.ecouter('Runtime.exceptionThrown', (p) => erreurs.push(String(p.exceptionDetails?.exception?.description || p.exceptionDetails?.text).slice(0, 200)));
    s.ecouter('Network.responseReceived', (p) => { if (/\/_vf\//.test(p.response.url)) reponses.push({ url: p.response.url, statut: p.response.status, depuisCache: !!p.response.fromDiskCache }); });
    const res = [];
    for (const url of args) { reponses.length = 0; erreurs.length = 0; await s.naviguer(url); await pause(300); res.push({ url, ...(await s.ev(SOMMAIRE)), erreursPage: [...erreurs], violations: [...s.violations], reponses: [...reponses] }); }
    return { res };
  }, { csp: true });
} else if (mode === 'avec') {
  // le fichier est le corps d'une fonction asynchrone ; ses premières lignes peuvent poser `// echec: true` (attendre un premier chargement en échec)
  // et `// amorce: <js>` (posé avant tout script, après la sonde)
  const [url, fichier] = args; const corps = fs.readFileSync(fichier, 'utf8');
  const entete = corps.split('\n').slice(0, 6), amorce = entete.filter((l) => l.startsWith('// amorce: ')).map((l) => l.slice(11)).join('\n');
  await executer(chrome, async (s) => {
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SONDE + '\n' + amorce });
    await s.send('Network.enable'); await s.send('Runtime.enable');
    const reseau = [], erreurs = [];
    s.ecouter('Runtime.exceptionThrown', (p) => erreurs.push(String(p.exceptionDetails?.exception?.description || p.exceptionDetails?.text).slice(0, 200)));
    s.ecouter('Network.requestWillBeSent', (p) => reseau.push({ url: p.request.url, methode: p.request.method, inm: p.request.headers['If-None-Match'] || p.request.headers['if-none-match'] || null, id: p.requestId }));
    s.ecouter('Network.responseReceived', (p) => { const r = reseau.find((x) => x.id === p.requestId); if (r) r.statut = p.response.status; });
    // `// panne: oui|non` : les lectures de graphe passent par une interception CDP (Fetch) que le corps pilote par `panne.actif` ; actif = réponse 500 au corps synthétique
    const panne = { actif: entete.some((l) => /^\/\/ panne: oui/.test(l)) };
    if (entete.some((l) => /^\/\/ panne: /.test(l))) {
      await s.send('Fetch.enable', { patterns: [{ urlPattern: '*api/vf/graphe*' }] });
      s.ecouter('Fetch.requestPaused', (p) => { s.send(panne.actif ? 'Fetch.fulfillRequest' : 'Fetch.continueRequest', panne.actif
        ? { requestId: p.requestId, responseCode: 500, body: Buffer.from('{"erreur":"MQ16-CORPS"}').toString('base64') } : { requestId: p.requestId }).catch(() => {}); });
    }
    await s.naviguer(url, entete.some((l) => /^\/\/ echec: true/.test(l)) ? { echec: true } : {});
    const f = new (Object.getPrototypeOf(async () => {}).constructor)('s', 'reseau', 'erreurs', 'SOMMAIRE', 'pause', 'panne', corps);
    return await f(s, reseau, erreurs, SOMMAIRE, pause, panne);
  }, { csp: true });
} else { console.log(JSON.stringify({ erreur: `mode inconnu : ${mode}` })); process.exit(2); }
