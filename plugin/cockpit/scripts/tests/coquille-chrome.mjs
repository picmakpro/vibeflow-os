#!/usr/bin/env node
// coquille-chrome.mjs — mesures navigateur de la suite de la coquille (79-16, SOCL-20). Socle : chrome-session.mjs (aucune dépendance).
// Chaque mode rend UNE ligne JSON ({ erreur } sur échec nommé). Les relevés qui jugent un état du document passent par la sonde
// (coquille-sonde.mjs, posée avant tout script de la page), jamais par le journal de la coquille.
//   charger <chrome> <url>…                 charge chaque adresse : onglet vu par le moteur, état, violations, réponses de /_vf/ (CDP réseau)
//   onglets <chrome> <url> <suite,…>        charge <url> puis enchaîne chargerOnglet ; relève après chaque appel (ordre des événements compris)
//   noms <chrome> <url>                     noms d'onglet invalides : promesse rejetée, aucune requête de graphe, empreinte intacte
//   planter <chrome> <url> <marqueur>       la page est chargée : le marqueur ne s'est pas exécuté, un script posé par la page est refusé (violation)
//   avec <chrome> <url> <fichier-js>        charge <url> (sonde posée) puis joue le corps JS du fichier (async, reçoit `s` et `sonde`) : rend sa valeur
import fs from 'node:fs';
import { executer, pause } from './chrome-session.mjs';
import { SONDE } from './coquille-sonde.mjs';

const [, , mode, chrome, ...args] = process.argv;
const SOMMAIRE = `(() => { const V = window.VibeFlow; return { tab: V?.graph?.meta?.vfTab ?? null, layout: !!V?.state?.layout, noeuds: V?.graph?.nodes?.length ?? null,
  onglet: window.VF_COQUILLE?.onglet?.() ?? null, pret: document.documentElement.dataset.vfPret ?? null, titre: document.title, etat: window.VF_COQUILLE?.etat?.() ?? null }; })()`;

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
  const [url, fichier] = args; const corps = fs.readFileSync(fichier, 'utf8');
  await executer(chrome, async (s) => {
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SONDE });
    await s.send('Network.enable');
    const reseau = []; s.ecouter('Network.requestWillBeSent', (p) => reseau.push({ url: p.request.url, methode: p.request.method }));
    s.ecouter('Network.responseReceived', (p) => { const r = reseau.findLast?.((x) => x.url === p.response.url) || reseau[reseau.length - 1]; if (r) r.statut = p.response.status; });
    await s.naviguer(url, /\bechec: true\b/.test(corps.slice(0, 200)) ? { echec: true } : {});
    const f = new (Object.getPrototypeOf(async () => {}).constructor)('s', 'reseau', 'SOMMAIRE', 'pause', corps);
    return await f(s, reseau, SOMMAIRE, pause);
  }, { csp: true });
} else { console.log(JSON.stringify({ erreur: `mode inconnu : ${mode}` })); process.exit(2); }
