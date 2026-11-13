// collecte-pilote — harnais du pilote de la collecte avec le fil d'essai (79-09, tâche 2 ; sections C2.x de test-cockpit-collecte.sh).
// Usage : node collecte-pilote.mjs <dossier-scripts> <dossier-tests> <dossier-essai> <cas>   (cas : c21 … c28)
//   <dossier-scripts> : le code joué (livré, ou copie mutée) ; <dossier-essai> : porte `scenario` et `journal` du fil d'essai (workerData.sortie).
//   Écrit UNE ligne JSON sur la sortie standard ; un cas qui plante rend { erreur } (le module ou une méthode absents rougissent, jamais un blanc).
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , scripts, tests, dossier, cas] = process.argv;
const imp = (f) => import(pathToFileURL(f).href);
const entree = pathToFileURL(path.join(tests, 'collecte-fil-essai.mjs'));
const scen = (s) => fs.writeFileSync(path.join(dossier, 'scenario'), s);
const lignes = () => { try { return fs.readFileSync(path.join(dossier, 'journal'), 'utf8').split('\n').filter(Boolean); } catch { return []; } };
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const jusque = async (f, ms) => { for (let t = 0; t < ms; t += 50) { if (f()) return true; await dormir(50); } return false; };
const sortir = (o) => { console.log(JSON.stringify(o)); process.exit(0); };
const interdit = (o) => !!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => k === 'cleInterdite' || interdit(v));

const { creerCollecte } = await imp(path.join(scripts, 'vf-cockpit-collecte.mjs'));
const mk = (extra = {}) => creerCollecte({ racine: dossier, sortie: dossier, scriptsDir: dossier, home: dossier, entree, log: () => {}, ...extra });
const CAS = {
  async c21() { // cinq demandes en rafale pendant un tour lent : jamais deux exécutions à la fois, deux au plus, la dernière couvre l'union
    scen('lent'); const c = mk(), recus = []; c.surResultat((m) => recus.push(m));
    c.demander({ tour: true }); await dormir(60);
    c.demander({ planning: true, motifs: ['a'] }); c.demander({ verrous: true, motifs: ['b'] }); c.demander({ motifs: ['c'] }); c.demander({ planning: true });
    await c.pret(8000); await dormir(1800); // 5 exécutions de 300 ms au plus : un pilote sans file les aurait toutes envoyées au fil
    const L = lignes().filter((l) => /^exec-(debut|fin) /.test(l)).map((l) => l.split(' ')[0]);
    const dernier = recus.filter((m) => m.type === 'planning').at(-1);
    c.arreter();
    return { execs: L.filter((x) => x === 'exec-debut').length, alterne: L.every((x, i) => x === (i % 2 ? 'exec-fin' : 'exec-debut')), motifs: dernier ? dernier.motifs.join() : null };
  },
  async c22() { // le fil meurt tant qu'il reçoit l'index : relancé sans index, partielle
    scen('mort-avec-index'); const c = mk({ delais: { fenetreMortMs: 20000 } });
    c.demander({ tour: true });
    await jusque(() => ['partielle', 'indisponible'].includes(c.etat().etat), 10000); const e = c.etat(), vu = e.etat === 'partielle'; c.arreter();
    return { vu, etat: e.etat, index: e.index.etat, relances: e.relances, cause: e.derniereMort?.cause, lancements: lignes().filter((l) => l.startsWith('lancement')).length };
  },
  async c23() { // le fil meurt toujours : indisponible, le processus vit, reprise après la pause, retour à ok quand le scénario passe à ok
    scen('mort-toujours'); const c = mk({ delais: { fenetreMortMs: 20000, reprisePauseMs: 900, indexSuspenduMs: 1800 } });
    const indispo = await jusque(() => c.etat().etat === 'indisponible', 8000);
    scen('ok');
    const lance3 = await jusque(() => lignes().filter((l) => l.startsWith('lancement')).length >= 3, 8000);
    const retour = await jusque(() => c.etat().etat === 'ok', 12000), e = c.etat(); c.arreter();
    return { indispo, lance3, retour, etat: e.etat, vivant: e.vivant };
  },
  async c24() { // mémoire plafonnée : le fil meurt par la limite, la cause est `memoire`, le test continue
    scen('oom'); const c = mk({ limites: { maxOldGenerationSizeMb: 24, maxYoungGenerationSizeMb: 8, stackSizeMb: 4 }, delais: { fenetreMortMs: 20000 } });
    c.demander({ tour: true });
    const vu = await jusque(() => c.etat().derniereMort !== null, 20000), e = c.etat(); c.arreter();
    return { vu, cause: e.derniereMort?.cause };
  },
  async c25() { // un seul écrivain : le fil suivant n'écrit qu'après la fin de l'écriture du précédent (ordre du journal)
    scen('ecrivain'); const c = mk();
    c.demander({ tour: true }); await jusque(() => lignes().some((l) => l.startsWith('debut-ecriture')), 5000); await dormir(100);
    const p = c.redemarrer(); c.demander({ tour: true }); await p;
    await jusque(() => lignes().filter((l) => l.startsWith('fin-ecriture')).length >= 2, 8000); c.arreter();
    const L = lignes(), d = L.filter((l) => l.startsWith('debut-ecriture')), f = L.filter((l) => l.startsWith('fin-ecriture')), fil = (l) => l.split(' ')[1];
    const premier = d[0] && fil(d[0]), second = d.find((l) => fil(l) !== premier);
    const ordre = !!premier && !!second && L.indexOf(f.find((l) => fil(l) === premier)) < L.indexOf(second);
    return { debuts: d.length, ordre, fins: f.length };
  },
  async c26() { // la garde injectée, à partir d'un tour ACCEPTÉ : un résultat portant une clé interdite à profondeur 3 n'est ni posé ni émis, l'état et l'instantané du tour précédent restent ; le même résultat sans la clé passe
    const { startLive } = await imp(path.join(scripts, 'vf-cockpit-live.mjs')), { instantane } = await imp(path.join(scripts, 'vf-cockpit-instantane.mjs'));
    scen('ok'); const evs = []; let col = null;
    const live = startLive({ root: process.argv[6], sortie: dossier, onEvent: (n) => evs.push(n), log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1,
      garde: (o) => !interdit(o), collecteur: (o) => { col = creerCollecte({ ...o, entree }); return col; } });
    const premier = await jusque(() => live.snapshot().who.workers.length === 1, 14000); await col.pret(5000); await dormir(200);
    const avant = instantane(), evAvant = evs.filter((n) => n === 'who' || n === 'lock').length;
    scen('interdit'); col.demander({ tour: true }); await col.pret(8000); await dormir(300);
    const apresRefus = instantane(), w = live.snapshot().who.workers;
    const refus = { premier, etat: live.etat().collecte.etat, qui: w.length, evenements: evs.filter((n) => n === 'who' || n === 'lock').length - evAvant,
      conserve: avant !== null && apresRefus === avant && w[0] && w[0].a === undefined };
    scen('ok'); col.demander({ tour: true });
    const accepte = await jusque(() => live.etat().collecte.etat === 'ok' && instantane()?.at > avant.at, 14000);
    const apres = { accepte, etat: live.etat().collecte.etat, avance: instantane()?.at > avant.at }; live.stop();
    return { refus, apres };
  },
  async c28() { // sans garde fournie, la garde est FERMÉE : rien de la collecte n'est posé ni émis (le serveur, lui, fournit la sienne)
    const { startLive } = await imp(path.join(scripts, 'vf-cockpit-live.mjs')), { instantane } = await imp(path.join(scripts, 'vf-cockpit-instantane.mjs'));
    scen('ok'); const evs = []; let col = null;
    const live = startLive({ root: process.argv[6], sortie: dossier, onEvent: (n) => evs.push(n), log: () => {}, mode: 'poll', aClient: () => true, nbClients: () => 1,
      collecteur: (o) => { col = creerCollecte({ ...o, entree }); return col; } });
    await col.pret(8000); await dormir(500);
    const r = { instantane: instantane() === null, qui: live.snapshot().who.workers.length, evenements: evs.filter((n) => n === 'who' || n === 'lock').length, etat: live.etat().collecte.etat };
    live.stop(); return r;
  },
  async c27() { // arreter : fil terminé, pret résout, rien ne repart, le processus sort de lui-même
    scen('ok'); const c = mk(); c.demander({ tour: true }); await c.pret(5000);
    c.arreter(); const pret = await c.pret(1000), apres = c.demander({ tour: true });
    let fuite = false; const g = setTimeout(() => { fuite = true; console.log(JSON.stringify({ pret, apres, fuite })); process.exit(0); }, 4000); g.unref();
    process.on('exit', () => { if (!fuite) console.log(JSON.stringify({ pret, apres, fuite })); });
    return undefined;
  },
};
try { const r = await CAS[cas](); if (r !== undefined) sortir(r); } catch (e) { sortir({ erreur: String(e && e.message).slice(0, 200) }); }
