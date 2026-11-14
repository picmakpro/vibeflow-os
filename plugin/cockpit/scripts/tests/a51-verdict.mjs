#!/usr/bin/env node
// a51-verdict.mjs — juge la sortie de a51-rejeu.mjs (80-a51, idiome A51) : lit la ligne JSON sur l'entrée standard, écrit « ok » ou la première
// anomalie. Usage : node a51-verdict.mjs retours|rejeu [--absent-ailleurs]
//   retours : deux allers-retours d'onglet laissent l'onglet comme à la première arrivée (écouteurs nets, observateurs, intervalles, classes du corps,
//             propriétés, feuilles, nœuds de la famille) ; chaque jeton de style compte UN SEUL <style> à l'arrivée (témoin : sinon la mesure ne prouve rien)
//   rejeu   : deux réévaluations de chaque fichier de la famille (même cle) laissent l'onglet comme avant elles
//   --absent-ailleurs : la famille est propre à l'onglet : sur l'autre onglet, aucune feuille et aucun nœud de la famille
import fs from 'node:fs';

const [, , mode, option] = process.argv;
let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const CHAMPS = ['ecouteurs', 'vivants', 'classesBody', 'props', 'styles', 'noeuds', 'nStyle', 'onglet'];
const egal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const ecart = (nom, a, b) => {
  const c = CHAMPS.find((k) => !egal(a[k], b[k]));
  return c ? `${nom} : « ${c} » diffère (${JSON.stringify(a[c]).slice(0, 220)} -> ${JSON.stringify(b[c]).slice(0, 220)})` : null;
};
const verdict = () => {
  if (j.manque && j.manque.length) return 'fichier absent du manifeste : ' + j.manque.join();
  if (j.erreurs && j.erreurs.length) return 'exception de page : ' + j.erreurs[0];
  const nb = Object.values(j.a1.ecouteurs || {}).reduce((s, n) => s + n, 0);
  if (!(nb > 0)) return 'témoin : aucun écouteur compté à l\'arrivée (la sonde ne voit rien)';
  const mal = Object.entries(j.a1.styles).filter(([, n]) => n !== 1).map(([k, n]) => `${k} ×${n}`);
  if (mal.length) return 'témoin : un jeton de style n\'est pas vu une seule fois à l\'arrivée : ' + mal.join();
  if (mode === 'retours') {
    const e = ecart('a1 -> a2', j.a1, j.a2) || ecart('a1 -> a3', j.a1, j.a3);
    if (e) return e;
    if (option === '--absent-ailleurs') {
      const reste = [...Object.entries(j.autre.styles), ...Object.entries(j.autre.noeuds)].filter(([, n]) => n > 0).map(([k, n]) => `${k} ×${n}`);
      if (reste.length) return 'resté sur l\'autre onglet : ' + reste.join();
    }
    return 'ok';
  }
  if (mode === 'rejeu') return ecart('avant -> après la réévaluation', j.a3, j.rejeu) || 'ok';
  return 'mode inconnu';
};
console.log(verdict());
