// mise-en-page-hostile.mjs — messages hostiles posés DIRECTEMENT au worker et au client de mise en page, sans Chrome (79-18, AU18-03). Aide autonome.
//   fil <dossier assets>      : elk-fil.js chargé sous `vm` avec le paquet ELK réel ; les messages que le protocole fermé { id, graphe } n'admet pas
//                               ne produisent AUCUNE réponse ; un message qui porte des clés internes du paquet ne les atteint pas ; une erreur est bornée
//   page <chemin de viewer.html> : la fabrique d'adaptateur extraite du gabarit, sous `vm` avec un faux Worker : protocole admis, réponses hostiles
// Une ligne JSON sur la sortie standard. Mutants : le bash en passe une copie, l'aide ne connaît aucun mutant.
import vm from 'node:vm';
import fs from 'node:fs';
import path from 'node:path';

const [, , mode, cible] = process.argv;
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const GR = () => ({ id: 'root', children: [{ id: 'a', width: 10, height: 10 }, { id: 'b', width: 10, height: 10 }], edges: [{ id: 'e', sources: ['a'], targets: ['b'] }] });

async function fil(assets) {
  const sortie = [];
  const ctx = vm.createContext({ console, setTimeout, clearTimeout, setImmediate, queueMicrotask });
  ctx.self = ctx; ctx.globalThis = ctx;
  ctx.postMessage = (m) => sortie.push(m);
  ctx.importScripts = (p) => vm.runInContext(fs.readFileSync(path.join(assets, p), 'utf8'), ctx, { filename: p });
  vm.runInContext(fs.readFileSync(path.join(assets, 'elk-fil.js'), 'utf8'), ctx, { filename: 'elk-fil.js' });
  // les graphes sont construits DANS le contexte du worker, comme l'est un message cloné : un tableau d'un autre contexte n'est pas reconnu par le paquet (calcul sans positions)
  const G = () => vm.runInContext('(' + JSON.stringify(GR()) + ')', ctx);
  const r = { charge: sortie.length, poseur: typeof ctx.onmessage };
  const envoyer = (m) => { try { ctx.onmessage({ data: m }); return 0; } catch { return 1; } };
  // 1. des messages qui ne sont pas { id entier >= 0, graphe objet } : aucune réponse, aucun plantage
  const hostiles = [null, undefined, 42, 'x', true, [], {}, { id: 1 }, { graphe: G() }, { id: -1, graphe: G() }, { id: 1.5, graphe: G() }, { id: '1', graphe: G() },
    { id: null, graphe: G() }, { id: NaN, graphe: G() }, { id: 2, graphe: [] }, { id: 3, graphe: 'x' }, { id: 4, graphe: null }, { id: 5, graphe: 7 }];
  r.plantages = hostiles.reduce((n, m) => n + envoyer(m), 0);
  await dormir(150);
  r.ignores = sortie.length;
  // 2. le contrôle de l'identifiant précède toute lecture du graphe (sonde : un accès à `graphe` est compté)
  let lectures = 0;
  for (const id of [-1, 1.5, '1', null, NaN]) envoyer({ id, get graphe() { lectures++; return G(); } });
  r.lectures = lectures;
  // 3. un message qui porte des clés internes du paquet (commande, options de calcul) : elles ne sont pas transmises ; même réponse qu'un message propre
  sortie.length = 0;
  envoyer({ id: 11, graphe: G() });
  envoyer({ id: 12, graphe: G(), cmd: 'register', algorithms: [], layoutOptions: { 'elk.algorithm': 'inconnu' }, options: { x: 1 } });
  envoyer({ id: 13, cmd: 'layout', graph: G(), layoutOptions: {}, options: {} });
  await dormir(300);
  const rep = (id) => sortie.find((m) => m.id === id);
  const sans = (m) => JSON.stringify(m && m.resultat, (k, v) => (k === '$H' ? undefined : v));
  r.interne = { reponses: sortie.map((m) => m.id).sort((a, b) => a - b), positions: !!rep(11) && !!rep(11).resultat && Number.isFinite(rep(11).resultat.children[1].x) && rep(11).resultat.children[1].x > rep(11).resultat.children[0].x, egal: !!rep(11) && !!rep(11).resultat && sans(rep(11)) === sans(rep(12)), nu13: rep(13) === undefined };
  r.cles = [...new Set(sortie.flatMap((m) => Object.keys(m)))].sort();
  // 4. une erreur du calcul : texte de 200 caractères au plus, pas de résultat
  sortie.length = 0;
  const g = GR(); g.edges = [{ id: 'e', sources: ['zz'.repeat(300)], targets: ['b'] }];
  envoyer({ id: 20, graphe: vm.runInContext('(' + JSON.stringify(g) + ')', ctx) });
  await dormir(300);
  const e = rep(20);
  r.limite = { texte: !!e && typeof e.erreur === 'string' && e.erreur.includes('Referenced shape does not exist'), borne: !!e && typeof e.erreur === 'string' && e.erreur.length === 200, sansResultat: !!e && !('resultat' in e) };
  return r;
}

async function page(chemin) {
  const lignes = fs.readFileSync(chemin, 'utf8').split('\n');
  const debut = lignes.findIndex((l) => l.startsWith('const elk = (() => {'));
  const fin = lignes.findIndex((l, i) => i > debut && l === '})();');
  if (debut < 0 || fin < 0) return { erreur: 'fabrique d\'adaptateur introuvable dans le gabarit' };
  const code = lignes.slice(debut, fin + 1).join('\n') + '\n;elk;';
  const jouer = async (protocole, manifeste = { prefixe: 'http://h/_vf/' }) => {
    const avert = []; const fils = [];
    class Worker { constructor(u) { this.u = u; fils.push(this); } postMessage(m) { this.dernier = m.id; } terminate() { this.fini = true; } }
    class ELK { layout() { return Promise.resolve({ children: [] }); } }
    const man = manifeste && { textContent: JSON.stringify(manifeste) };
    const ctx = vm.createContext({ console: { warn: (m) => avert.push(String(m)) }, Worker, ELK, t: (s) => s, location: { protocol: protocole },
      document: { getElementById: () => man }, window: { VF_COQUILLE: { surOnglet: () => () => {} } } });
    const elk = vm.runInContext(code, ctx, { filename: 'viewer.html' });
    return { elk, fils, avert };
  };
  const r = {};
  // 1. la condition de repli : un Worker n'est construit que sous http: et https:
  const protos = {};
  for (const p of ['http:', 'https:', 'file:', 'blob:', 'about:', 'data:', 'ftp:', 'chrome-extension:']) protos[p] = (await jouer(p)).fils.length;
  r.protocoles = Object.entries(protos).map(([k, v]) => `${k}${v}`).join(' ');
  r.sansManifeste = (await jouer('https:', null)).fils.length;
  // 2. des réponses hostiles : aucune ne règle ni ne rejette la requête en attente, aucune ne plante le gestionnaire
  const { elk, fils } = await jouer('https:');
  const w = fils[0]; const etat = { regle: 0, rejete: 0 };
  const suivre = (p) => p.then(() => { etat.regle++; }, () => { etat.rejete++; });
  suivre(elk.layout(GR())); // id 0, laissée en attente
  const hostiles = [null, undefined, 42, 'x', true, [], {}, { id: '0', resultat: { children: [] } }, { id: 0.5, resultat: { children: [] } }, { id: -1, resultat: { children: [] } },
    { id: NaN, resultat: { children: [] } }, { id: 99, resultat: { children: [] } }, { resultat: { children: [] } }];
  let plantages = 0;
  for (const m of hostiles) { try { w.onmessage({ data: m }); } catch { plantages++; } }
  await dormir(20);
  r.hostiles = { plantages, regle: etat.regle, rejete: etat.rejete };
  // 3. une réponse de forme fausse pour une requête connue : rejetée avec le texte fixe ; une erreur : son texte borné ; une réponse juste : réglée une seule fois
  const formes = [{ resultat: {} }, { resultat: null }, { resultat: 'x' }, { resultat: { children: 'x' } }, { resultat: { children: {} } }, {}, { erreur: 12 }, { erreur: {} }, { erreur: null }];
  const sorts = [];
  for (const f of formes) {
    const p = elk.layout(GR()); const id = w.dernier;
    let sort = 'attente'; p.then(() => { sort = 'regle'; }, (e) => { sort = 'rejete:' + e.message; });
    try { w.onmessage({ data: { id, ...f } }); } catch { sort = 'plantage'; }
    await dormir(5); sorts.push(sort);
  }
  r.formes = sorts;
  const p1 = elk.layout(GR()); const id1 = w.dernier; let s1 = 'attente'; p1.then(() => { s1 = 'regle'; }, (e) => { s1 = 'rejete:' + e.message; });
  w.onmessage({ data: { id: id1, erreur: 'z'.repeat(500) } }); await dormir(5);
  r.erreurLongue = s1.startsWith('rejete:') ? s1.length - 'rejete:'.length : s1;
  const p2 = elk.layout(GR()); const id2 = w.dernier; let s2 = 'attente'; p2.then((v) => { s2 = 'regle:' + v.children.length; }, () => { s2 = 'rejete'; });
  w.onmessage({ data: { id: id2, resultat: { children: [] } } }); await dormir(5);
  let second = 'sans effet'; try { w.onmessage({ data: { id: id2, resultat: { children: [] } } }); } catch { second = 'plantage'; }
  r.juste = [s2, second];
  return r;
}
const sortie = mode === 'fil' ? await fil(cible) : mode === 'page' ? await page(cible) : { erreur: 'mode inconnu' };
console.log(JSON.stringify(sortie));
