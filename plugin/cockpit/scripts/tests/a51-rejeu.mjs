#!/usr/bin/env node
// a51-rejeu.mjs — témoin de l'idiome A51 (80-a51) : une extension réexécutée ne laisse qu'un seul branchement actif, dans un vrai Chrome.
// Usage : node a51-rejeu.mjs <chrome> <url> <onglet> <autre> <fichiers> <styles> <selecteurs> [<amorce>]
//   <onglet>   onglet de l'adresse (code, projet, equipe) ; <autre> l'onglet par lequel on passe (deux allers-retours onglet -> autre -> onglet)
//   <fichiers> noms des extensions ui/ de la famille (virgules) ; <styles> jetons cherchés dans le texte des <style> (virgules) ;
//   <selecteurs> sélecteurs CSS dont on compte les nœuds (virgules ; « - » pour aucun)
//   <amorce>   expression JS (async) rejouée à chaque arrivée sur <onglet> avant le relevé : ouvrir ce qui doit être défait (tiroir, volet)
// Rend UNE ligne JSON : { a1, a2, autre, a3, rejeu, manque, erreurs } où chaque relevé est l'état du document (coquille-sonde.mjs : écouteurs nets de
// window/document/html/body, observateurs, intervalles, classes du corps, propriétés de window, tête) plus les décomptes de la famille.
//   a1      arrivée sur <onglet> par l'adresse · rejeu  après deux réévaluations de chaque fichier, prises EN DERNIER (même cle : remplacement)
//   a2, a3  arrivées suivantes sur <onglet> (après un aller-retour, puis deux) · autre  le dernier passage sur <autre>
// Les relevés sont pris une fois posés (deux relevés consécutifs identiques), jamais dans la foulée du geste.
import { executer, pause, stabiliser } from './chrome-session.mjs';
import { SONDE } from './coquille-sonde.mjs';

const [, , chrome, url, onglet, autre, fichiers, styles, selecteurs, amorce] = process.argv;
const liste = (t) => (t && t !== '-' ? t.split(',') : []);
const FICHIERS = liste(fichiers), STYLES = liste(styles), SELS = liste(selecteurs);
// la visite du premier passage s'ouvre d'elle-même : ses clés sont lues comme posées
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";

await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SONDE + '\n' + SANS_VISITE });
  await s.send('Runtime.enable');
  const erreurs = [];
  s.ecouter('Runtime.exceptionThrown', (p) => erreurs.push(String(p.exceptionDetails?.exception?.description || p.exceptionDetails?.text).slice(0, 160)));
  // le relevé : l'empreinte de la sonde (sans le corps, qui change avec le rendu) et les décomptes de la famille
  const releve = () => s.ev(`(() => { const e = __s.empreinte();
    const tous = [...document.querySelectorAll('style')];
    const styles = Object.fromEntries(${JSON.stringify(STYLES)}.map((j) => [j, tous.filter((x) => x.textContent.includes(j)).length]));
    const noeuds = Object.fromEntries(${JSON.stringify(SELS)}.map((q) => [q, document.querySelectorAll(q).length]));
    const { ecouteurs, vivants, classesBody, tete } = e, props = e.props.filter((p) => /^(VF|__vf)/.test(p));
    return JSON.stringify({ ecouteurs, vivants, classesBody, tete, props, styles, noeuds, nStyle: tous.length, onglet: window.VF_COQUILLE.onglet() }); })()`);
  const pose = async (avecAmorce = true) => {
    if (amorce && avecAmorce) { await s.ev(`(async () => { ${amorce} })()`); await pause(400); }
    return JSON.parse(await stabiliser(async () => releve(), { pas: 300, max: 15000 }));
  };
  const aller = async (nom) => { await s.ev(`VF_COQUILLE.chargerOnglet(${JSON.stringify(nom)}).then(() => 1)`); await pause(300); };
  // réévaluer un fichier : un <script src> du préfixe de la coquille (son rappel surOnglet est appelé aussitôt, l'onglet étant prêt)
  const rejouer = async (nom) => s.ev(`(async () => { const m = JSON.parse(document.getElementById('vf-coquille-manifeste').textContent);
    const n = ${JSON.stringify(nom)}, f = m.fichiers.find((x) => x.nom.endsWith('/' + n) || x.nom === n); if (!f) return 'absent';
    await new Promise((ok, ko) => { const e = document.createElement('script'); e.src = m.prefixe + f.nom; e.onload = ok; e.onerror = ko;
      document.head.appendChild(e); });
    return 'ok'; })()`);
  const o = {};
  await s.naviguer(url, { brut: true });
  await s.attendre(`window.VF_COQUILLE.onglet() === ${JSON.stringify(onglet)}`, `onglet ${onglet} affiché`);
  o.a1 = await pose();
  await aller(autre); await aller(onglet); o.a2 = await pose();
  await aller(autre); o.autre = await pose(false); await aller(onglet); o.a3 = await pose();
  // le rejeu vient en dernier : une inscription posée après le premier rendu n'est plus défaite avec l'onglet, elle fausserait les arrivées
  o.manque = [];
  for (const f of FICHIERS) {
    for (let i = 0; i < 2; i++) { const r = await rejouer(f); if (r !== 'ok' && !o.manque.includes(f)) o.manque.push(f); await pause(200); }
  }
  o.rejeu = await pose();
  o.erreurs = erreurs;
  return o;
}, { csp: true });
