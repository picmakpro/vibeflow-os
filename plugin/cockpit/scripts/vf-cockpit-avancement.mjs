// vf-cockpit-avancement — avancement d'une phase, calculé en bibliothèque du socle (CKPT-13 à CKPT-17 ; P69-D-01 à P69-D-09).
// Exports : ETATS, RESTE, ETATS_MISSION, LIBELLES_ETAT, LIBELLES_RESTE, LIBELLES_MISSION, decompte, trouverPhase, rattacherMission, etatMission, reste, avancement, ligneStatutRecette, recetteFaite.
// Contrat figé en version 2 (déclaré dans vf-cockpit-interface.json, clé `avancement`, lu par la Phase 68 ; VFSG-06, P68-D-16) :
//   { version: 2, etat, plans: { faits, total }, correctifs, mission: { nom, etat, vie } | null, reste: [codes] } — ajouts de champs seulement.
//   `vie` = { tenu, stale, progressAgeS, ttl } (verrou lu) ou null ; absent quand l'appelant ne lit pas les verrous.
//   `vie: null` porte DEUX sens, que la forme ne distingue pas et que `etat` départage (F-08, `mission.vieNulle` du contrat) : `etat: inconnu` = source des verrous illisible (P68-D-23, un nœud running dont on ne sait rien) ;
//   `etat` done, ready ou failed = aucun nœud running, les verrous ne sont pas lus. Une mission `running` ou `abandonnee` porte toujours une vie. Un consommateur lit donc `vie: null` sur `etat`, jamais seul.
// Module pur : ne lit que ce qu'on lui passe (la lecture du verrou est celle de vf-cockpit-vie.mjs, en amont), aucune lecture réseau, aucun nom de lab codé en dur.
import { estVivante } from './vf-cockpit-vie.mjs';

export const ETATS = ['a-faire', 'en-cours', 'a-recetter', 'fait'];
export const RESTE = ['cadrage', 'plan', 'execution', 'recette', 'verification', 'cloture'];
export const LIBELLES_ETAT = { 'a-faire': 'à faire', 'en-cours': 'en cours', 'a-recetter': 'à recetter', fait: 'fait' };
export const LIBELLES_RESTE = { cadrage: 'cadrage', plan: 'plan', execution: 'exécution', recette: 'recette humaine', verification: 'vérification', cloture: 'clôture' };
export const ETATS_MISSION = ['running', 'abandonnee', 'inconnu', 'failed', 'done', 'ready'];
export const LIBELLES_MISSION = { running: 'en cours', abandonnee: 'abandonnée, nœuds non refermés', inconnu: 'état inconnu', failed: 'en échec', done: 'faite', ready: 'prête' };

const NUM_STRICT = /^\d+(?:\.\d+)?$/;
const MOTIF_MISSION = /^MISSION-(\d+(?:\.\d+)?)/;
// 01 -> 1, 02.1 -> 2.1 (même règle que normNum de vf-cockpit-formats, ré-exporté par vf-cockpit-planning, qui importe ce module : pas de cycle)
const norm = (s) => { const [a, b] = String(s).split('.'); return `${Number(a)}${b !== undefined ? '.' + b : ''}`; };

// Un plan est fait s'il a son *-PLAN.md ET son *-SUMMARY.md ; un SUMMARY sans PLAN est un correctif (P69-D-04).
// `fichiers` = noms de fichiers du dossier de phase. Rend { faits, total, correctifs }.
export function decompte(fichiers) {
  const plans = new Set(), sommes = new Set();
  for (const f of fichiers || []) {
    if (f.endsWith('-PLAN.md')) plans.add(f.slice(0, -'-PLAN.md'.length));
    else if (f.endsWith('-SUMMARY.md')) sommes.add(f.slice(0, -'-SUMMARY.md'.length));
  }
  let faits = 0, correctifs = 0;
  for (const p of plans) if (sommes.has(p)) faits++;
  for (const s of sommes) if (!plans.has(s)) correctifs++;
  return { faits, total: plans.size, correctifs };
}

// Une référence de phase se résout d'abord dans le compartiment qui la porte, sinon par numéro unique dans le lab.
// Comparaison par égalité après normalisation ; jamais une RegExp construite depuis une valeur du lab (T-69-08).
export function trouverPhase(phases, n, ws) {
  if (!NUM_STRICT.test(String(n))) return null;
  const c = [...phases.values()].filter((p) => p.n === norm(n));
  return c.find((p) => (p.ws || '') === (ws || '')) || (c.length === 1 ? c[0] : null);
}

// Rattachement d'une mission à une phase (P69-D-05) : règle 1 le champ `phase` du DAG (il décide seul, P69-PL-06),
// règle 2 le nom `MISSION-<n>`, règle 3 le dossier de phase qui le porte. Rend { cle, regle } ou null (hors phase).
export function rattacherMission(dag, phases) {
  const ws = dag.ws || dag.wsDeclare || null;
  if (dag.phase != null) { const p = trouverPhase(phases, dag.phase, ws); return p ? { cle: p.key, regle: 1 } : null; }
  const k = MOTIF_MISSION.exec(dag.name || '')?.[1];
  if (k) { const p = trouverPhase(phases, k, ws); if (p) return { cle: p.key, regle: 2 }; }
  if (dag.dossierPhase) {
    const [w, n] = String(dag.dossierPhase).split('|');
    const p = trouverPhase(phases, n, w === '*' || w === '' ? null : w);
    if (p) return { cle: p.key, regle: 3 };
  }
  return null;
}

// État d'une mission, vocabulaire de dag.sh : running > failed > done (tous, au moins un nœud) > ready.
// Un nœud `running` ne vaut `running` que si la mission est vivante (P68-D-05) : `vie` undefined = appelant qui ne lit pas les verrous (version 1),
// `vie` null = verrous illisibles (`inconnu`, P68-D-23), sinon `running` si estVivante(vie), `abandonnee` sinon.
export function etatMission(nodes, vie) {
  const ns = Array.isArray(nodes) ? nodes : [];
  if (ns.some((x) => x?.status === 'running')) return vie === undefined || estVivante(vie) ? 'running' : vie === null ? 'inconnu' : 'abandonnee';
  if (ns.some((x) => x?.status === 'failed')) return 'failed';
  if (ns.length && ns.every((x) => x?.status === 'done')) return 'done';
  return 'ready';
}

// Étapes restantes (P69-D-07, P69-PL-07) : seulement ce que disent les fichiers du dossier de phase et la case de ROADMAP.
// `lire(nom)` rend le texte d'un fichier du dossier. Vide pour une phase `fait`.
// PU-G-098 : une phase sans aucun *-PLAN.md et sans mission vivante (`vivante`) n'a rien commencé : « cadrage » (absent si un *-CONTEXT.md existe), « plan », « exécution » précèdent le reste.
export function reste({ ph, fichiers, lire, vivante }) {
  if (ph?.done) return [];
  const fs = fichiers || [], r = [];
  if (!vivante && !fs.some((f) => f.endsWith('-PLAN.md'))) { if (!fs.some((f) => f.endsWith('-CONTEXT.md'))) r.push('cadrage'); r.push('plan', 'execution'); }
  const rec = fs.filter((f) => f.endsWith('-RECETTE-HUMAINE.md')).sort()[0];
  if (rec) {
    const ligne = ligneStatutRecette((lire && lire(rec)) || '');
    if (!recetteFaite(ligne)) r.push('recette');
  }
  if (!fs.some((f) => f.endsWith('-VERIFICATION.md'))) r.push('verification');
  r.push('cloture');
  return r;
}

// Mission désignée quand plusieurs sont rattachées : celle qui a un nœud `running`, puis la plus petite règle, puis le nom le plus petit.
function choisir(missions) {
  const l = missions.map((m) => ({ nom: m.nom, regle: m.regle ?? 9, etat: etatMission(m.nodes, m.vie), vie: m.vie }));
  l.sort((a, b) => (b.etat === 'running') - (a.etat === 'running') || a.regle - b.regle || (a.nom < b.nom ? -1 : a.nom > b.nom ? 1 : 0));
  return l.length ? { nom: l[0].nom, etat: l[0].etat, vie: l[0].vie } : null;
}

// Objet versionné posé par readPlanning sur chaque phase. `missions` = [{ nom, regle, nodes, vie }] rattachées à la phase.
// Évaluation (P69-D-03) : fait (case cochée) > a-recetter (tous les plans faits) > en-cours (un plan fait ou un nœud running) > a-faire.
// Ni current_phase ni le compartiment actif n'entrent dans le calcul.
export function avancement({ ph, fichiers, missions, lire } = {}) {
  const ms = missions || [];
  const { faits, total, correctifs } = decompte(fichiers);
  const lance = ms.some((m) => etatMission(m.nodes, m.vie) === 'running'); // ni une mission abandonnée ni une mission inconnue ne gardent la phase en cours
  const etat = ph?.done ? 'fait' : total > 0 && faits === total ? 'a-recetter' : faits > 0 || lance ? 'en-cours' : 'a-faire';
  return { version: 2, etat, plans: { faits, total }, correctifs, mission: choisir(ms), reste: reste({ ph, fichiers, lire, vivante: lance }) };
}

// Statut d'une recette (P76-D-14 : la règle de reste() est réutilisée par la traçabilité, jamais réécrite) : la ligne qui commence par `**Statut :`, '' sinon ;
// la recette est faite quand le mot FAITE y figure en mot entier (découpe sur tout ce qui n'est ni lettre ni chiffre).
export function ligneStatutRecette(txt) { return String(txt || '').split('\n').find((l) => l.startsWith('**Statut :')) || ''; }
export function recetteFaite(ligne) { return String(ligne || '').split(/[^\p{L}\p{N}]+/u).includes('FAITE'); }
