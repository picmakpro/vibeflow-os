// canal-harness.mjs — les comptes de l'activité, de la table des marques au canal (R1, R2 de test-cockpit-ecrans-recent.sh ; 75-09b).
// usage : node canal-harness.mjs <75-vf-activite-tables.js> <75-vf-marques.js> <données.json>   (stdout : JSON)
// Les fonctions pures des tables et le canal VF_MARQUES tournent en `vm`, sans navigateur : un fichier écrit par deux agents est UNE carte.
import fs from 'node:fs';
import vm from 'node:vm';
const [, , fTables, fMarques, fDonnees] = process.argv;
const data = JSON.parse(fs.readFileSync(fDonnees, 'utf8'));
const lire = (f, win) => vm.runInContext(fs.readFileSync(f, 'utf8'), vm.createContext({ window: win, console, document: {} }));
const wT = {}; lire(fTables, wT);
const T = wT.VF_ACTIVITE_TABLES;
const fich = Object.fromEntries(data.fichiers.map((p) => [p, { l: 'js' }]));
const vue = { fichier: (p) => fich[p] || null, existe: (id) => id.startsWith('f:') && !!fich[id.slice(2)], visible: () => true,
  ancetres: (id) => (data.chains[id] || [id]).slice(1).filter((a) => a !== 'root'), selection: null, filtre: null };
const d = { schema: 'vibeflow/cockpit-activite@1', etat: 'ok', calcul: 'pret', git: { etat: 'absent' }, branches: { etat: 'absent' }, gardes: { etat: 'non-lues', gardes: [], estGarde: [] },
  empreinte: { etat: 'ok', incomplet: false, limite: [], marques: data.marques, horsCarte: 0, horsLab: 0, coupees: 0, rejetes: 0, ignorees: 0 }, collisions: [],
  radar: { incomplet: false, raisons: [], total: 0, tronque: false, limites: [] } };
const m = T.modele({ d, conn: 'ouvert', lentille: 'empreinte', filtre: null, vue });
const chain = (id) => data.chains[id] || [id, 'root'];
const wM = { console, VibeFlow: Object.freeze({ chain, on() {}, render() {}, rerender() {} }) };
lire(fMarques, wM);
const V = wM.VF_MARQUES;
const posee = V.poser('empreinte', m.rows);
console.log(JSON.stringify({ posee, pastille: m.pastille, cartes: m.rows.length, fichier: V.lire('f:a.js').length, noeud: V.lire('n:part').map((x) => `${x.compte}|${x.mot}|${x.agrege}`) }));
