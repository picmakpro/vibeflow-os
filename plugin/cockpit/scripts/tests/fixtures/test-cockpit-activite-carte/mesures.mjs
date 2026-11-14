// mesures.mjs — les mesures navigateur du plan 75-07, une fonction par section ; chaque fonction rend un objet JSON simple que lit la suite.
// Appelée par chrome-activite-carte.mjs avec un contexte { s, vue, charger, aller, poser, zoom, SNAP, racine, sid, stabiliser, attendreValeur }.
import { mesuresPied } from './mesures-pied.mjs';

const DIR_B = 'd:d-src|src/b', NOEUD = 'n:d-src';
const HOSTILE = '<img src=x onerror=window.__xss=1>"\'</script> __proto__';
// un tableau de rangées sur les fichiers du graphe (n'importe quelle carte visible en est le parent, par l'agrégat)
const FICHIERS = `VibeFlow.graph.files.slice(0, 30).map((f, i) => ['f:' + f.p, ['haut', 'moyen', 'bas'][i % 3], 'barres', (i + 1) + ' changements', 'infobulle ' + i])`;

export const sections = {
  // D3 : une marque posée sur une carte, le mot par textContent ; noms de fichier hostiles dans le lab ; aucune injection
  async d3(c) {
    const { s } = c;
    await c.vue(1440, 900); await c.charger('index.html');
    const dossier = await c.aller(DIR_B); // les fichiers hostiles du lab (balises, très long, U+2028) : la carte et le DOM tiennent
    const cartesB = await s.ev("document.querySelectorAll('#viewport .node').length");
    await c.aller(NOEUD);
    const avant = await s.ev("document.querySelectorAll('#viewport img, #viewport script').length");
    const poseOk = await s.ev(`VF_MARQUES.poser('d3', [[${JSON.stringify(DIR_B)}, 'haut', 'haut', ${JSON.stringify(HOSTILE)}, ${JSON.stringify(HOSTILE)}]], { exclusif: true })`);
    await c.poser();
    const lu = await s.ev(`JSON.stringify((() => { const g = VibeFlow.state.chipEls.get(${JSON.stringify(DIR_B)}); const lm = g.querySelectorAll('.card .foot .lm'); const w = g.querySelector('.card .foot .lm .lw');
      return { n: lm.length, mot: w ? w.textContent : null, titre: lm[0] ? lm[0].getAttribute('title') : null, enfants: w ? w.children.length : -1, cache: lm[0] ? !!lm[0].closest('[aria-hidden="true"]') : false,
        injectes: document.querySelectorAll('#viewport img, #viewport script').length, xss: window.__xss === undefined }; })())`);
    return { cartesB, dossier: !!dossier, poseOk, avant, ...JSON.parse(lu), hostile: HOSTILE };
  },

  // D4 : géométrie invariante (P75-D-03) à trois largeurs et trois paliers de zoom, sans aucun render() ni rerender() après une pose
  async d4(c) {
    const { s } = c, sorties = [];
    for (const [w, h] of [[1440, 900], [1024, 768], [390, 844]].filter(([w]) => (process.env.D4_LARGEURS || '1440,1024,390').split(',').includes(String(w)))) { // D4_LARGEURS : restreindre (mise au point)
      await c.vue(w, h, w < 500); await c.charger('index.html');
      for (const cont of [NOEUD, DIR_B]) {
        await c.aller(cont);
        await s.ev(`window.__rc = 0; if (!window.__rcOn) { window.__rcOn = true; VibeFlow.on('render', () => { window.__rc++; }); }`);
        for (const z of ['ouverture', 'mid', 'bas']) {
          await c.zoom(z);
          const S0 = await c.poser(), ecarts = [], mesure = async (nom) => { if ((await c.poser()) !== S0) ecarts.push(nom); };
          const rows = (i) => `VF_MARQUES.poser('c${i}', ${FICHIERS}.map((r) => [r[0], r[1], r[2], r[3] + ${i}, r[4]]), { exclusif: true })`;
          await s.ev(rows(0)); await mesure('poser');
          const marques = await s.ev("document.querySelectorAll('#viewport .lm').length");
          await s.ev("VF_MARQUES.retirer('c0')"); await mesure('retirer');
          for (let i = 1; i <= 5; i++) { await s.ev(rows(i)); await mesure('bascule' + i); }
          await s.ev(rows(6)); await mesure('mise-a-jour'); // une donnée neuve injectée : la couche reposée
          await s.ev("for (const n of ['c1','c2','c3','c4','c5','c6']) VF_MARQUES.retirer(n)");
          sorties.push({ w, cont, z, ecarts, marques, renders: await s.ev('window.__rc') });
        }
      }
    }
    return sorties;
  },

  ...mesuresPied,
};
