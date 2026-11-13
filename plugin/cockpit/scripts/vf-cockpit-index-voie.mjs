// vf-cockpit-index-voie — réduction d'une ligne de transcript dans une voie de l'index (P79-D-13, C1, règles R1 à R11 du plan 79-08). Pur.
// Exports : BORNES, lire(objet, chemin), voieNeuve(identite), plierLigne(voie, ligne, travail), publique(voie), enCours(voie), CONTRAT, formeRequise(CC)
// Liste blanche (R1) : toute valeur du transcript passe par `lire` avec un chemin déclaré au contrat (claudeCode.index) ; jamais un texte,
// l'entrée d'un outil, un résultat, une cible : le nom d'un outil ne sert qu'à son verbe (table fermée) et à sa classe d'attente, il n'est pas gardé.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { etiquette } from './vf-cockpit-transcript.mjs';
import { ATTEND_UN_ENFANT } from './vf-cockpit-equipe-etat.mjs';
import { jetonsVides, plierMessage } from './vf-cockpit-jetons.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
export const CONTRAT = (() => { try { return JSON.parse(fs.readFileSync(path.join(HERE, 'vf-cockpit-interface.json'), 'utf8')); } catch { return {}; } })();
const DEFAUT = { fenetreS: 86400, silenceS: 180, segments: 500, evenements: 500, ouverts: 64, lancements: 256, clos: 256, modeles: 4, versions: 4, versionsVues: 8, role: 64, arbre: 200, tete: 1024, bloc: 1048576, ligneMax: 33554432, fichierOctets: 33554432, voiesMax: 2000 };
export const BORNES = Object.freeze({ ...DEFAUT, ...(CONTRAT.schemas?.['vibeflow/cockpit-index@1']?.bornes || {}) });
const MODELE_RE = /^[A-Za-z0-9._:/-]{1,64}$/, VERSION_RE = /^\d+\.\d+\.\d+$/;
const GENRES = { 'attend-humain': 'attenteHumainS', 'attend-agents': 'attenteAgentsS', travail: 'travailS', repos: 'reposS', silence: 'silenceS' };

// accesseur unique des champs du transcript : chemin pointé en littéral ; undefined si un maillon manque
export const lire = (objet, chemin) => {
  let a = objet;
  for (const k of chemin.split('.')) { if (!a || typeof a !== 'object' || !Object.prototype.hasOwnProperty.call(a, k)) return undefined; a = a[k]; }
  return a;
};
const typeDe = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
// un champ requis du contrat : présent et du type déclaré (une valeur numérique doit être finie)
export const formeRequise = (CC, objet, bloc) => (CC?.index?.[bloc]?.requis || []).every((p) => { const v = lire(objet, p), t = CC.index.types?.[p]; return v !== undefined && (!t || typeDe(v) === t) && (t !== 'number' || Number.isFinite(v)); });
const facultatif = (CC, objet, p) => { const v = lire(objet, p); return v !== undefined && typeDe(v) === (CC?.index?.types?.[p] || typeDe(v)) ? v : undefined; };

export function voieNeuve(identite) {
  return {
    id: identite.id, kind: identite.kind, session: identite.session, parent: identite.parent ?? null, depth: identite.depth ?? null, role: identite.role ?? null,
    arbre: identite.arbre ?? null, background: !!identite.background, debut: null, fin: null, dispatchA: null, fini: !!identite.fini, arrete: !!identite.arrete,
    modeles: [], compteurs: { appels: 0, erreurs: 0, refus: 0, questions: 0, compactions: 0, tours: 0, reponsesApi: 0 }, jetons: jetonsVides(),
    durees: { travailS: 0, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 }, segments: [], evenements: [], enCours: null, forme: 'ok', tronque: false, versions: [],
    curseur: { octets: 0, taille: 0, mtimeMs: 0, tete: null, dernierMsgId: null, usage: null, maxClos: 0, clos: [], ouverts: {}, lancements: [], saut: false, etat: { finDeTour: false, agentsFond: 0, msParGenre: { travail: 0, 'attend-humain': 0, 'attend-agents': 0, repos: 0, silence: 0 } } },
  };
}

// forme inconnue (R10) : toutes les mesures passent à null, jamais à zéro
export const inconnue = (voie) => { voie.forme = 'inconnue'; voie.compteurs = voie.jetons = voie.durees = voie.segments = voie.evenements = voie.enCours = null; };
const evenement = (voie, t, genre) => { voie.evenements.push([t, genre]); if (voie.evenements.length > BORNES.evenements) voie.evenements.splice(0, voie.evenements.length - BORNES.evenements); };
const classeDe = (nom) => (nom === 'AskUserQuestion' ? 'humain' : ATTEND_UN_ENFANT.has(nom) ? 'agents' : 'autre');

// R7 : l'écart entre deux lignes datées prend le genre fixé par l'état après la ligne précédente
function segment(voie, avant, t) {
  const e = voie.curseur.etat, ouverts = Object.values(voie.curseur.ouverts), ecart = t - avant;
  const genre = ouverts.some((o) => o.c === 'humain') ? 'attend-humain'
    : ouverts.some((o) => o.c === 'agents') || (e.finDeTour && e.agentsFond > 0) ? 'attend-agents'
      : ouverts.length > 0 ? 'travail' : ecart <= BORNES.silenceS * 1000 ? 'travail' : e.finDeTour ? 'repos' : 'silence';
  e.msParGenre[genre] += ecart;
  const dernier = voie.segments[voie.segments.length - 1];
  if (dernier && dernier[2] === genre && dernier[1] === avant) dernier[1] = t; else voie.segments.push([avant, t, genre]);
  if (voie.segments.length > BORNES.segments) { voie.segments.splice(0, voie.segments.length - BORNES.segments); voie.tronque = true; }
}
const recompte = (voie) => { for (const [g, k] of Object.entries(GENRES)) voie.durees[k] = Math.round(voie.curseur.etat.msParGenre[g] / 1000); };

function appelOuvert(voie, bloc, t, CC) {
  const c = voie.curseur, id = lire(bloc, 'id'), nom = lire(bloc, 'name');
  voie.compteurs.appels++;
  c.ouverts[id] = { v: etiquette(nom).verbe, t, c: classeDe(nom) };
  const cles = Object.keys(c.ouverts); if (cles.length > BORNES.ouverts) for (const k of cles.slice(0, cles.length - BORNES.ouverts)) delete c.ouverts[k];
  if (nom === 'Agent' || nom === 'Task') { c.lancements.push([id, t]); if (c.lancements.length > BORNES.lancements) c.lancements.splice(0, c.lancements.length - BORNES.lancements); evenement(voie, t, 'dispatch'); }
  if (nom === 'AskUserQuestion') voie.compteurs.questions++;
  if (nom === 'SubagentHandback') evenement(voie, t, 'rapport');
}

// plierLigne(voie, ligne, travail) : `travail` = état de travail de la mise à jour { dernierMsgId, usage, maxClos, clos, cwd } reporté au curseur par l'appelant
export function plierLigne(voie, d, travail, CC = CONTRAT.claudeCode) {
  if (voie.forme === 'inconnue' || !d || typeof d !== 'object') return;
  const type = lire(d, 'type'), c = voie.curseur, e = c.etat;
  if (type === 'system') {
    const st = facultatif(CC, d, 'subtype'), ts = Date.parse(lire(d, 'timestamp'));
    if (st === 'compact_boundary') { voie.compteurs.compactions++; if (Number.isFinite(ts)) evenement(voie, ts, 'compaction'); }
    if (st === 'turn_duration') { voie.compteurs.tours++; e.finDeTour = true; const p = facultatif(CC, d, 'pendingBackgroundAgentCount'); e.agentsFond = Number.isInteger(p) && p > 0 ? p : 0; }
    return;
  }
  if (type !== 'user' && type !== 'assistant') return;
  if (!formeRequise(CC, d, 'lignesDatees') || !Number.isFinite(Date.parse(lire(d, 'timestamp')))) return inconnue(voie);
  const t = Date.parse(lire(d, 'timestamp'));
  if (type === 'assistant' && !formeRequise(CC, d, 'assistant')) return inconnue(voie);
  const blocs = lire(d, 'message.content');
  const liste = Array.isArray(blocs) ? blocs.filter((b) => b && typeof b === 'object') : [];
  for (const b of liste) {
    const tb = lire(b, 'type');
    if (type === 'assistant' && tb === 'tool_use' && !formeRequise(CC, b, 'appel')) return inconnue(voie);
    if (type === 'user' && tb === 'tool_result' && !formeRequise(CC, b, 'resultat')) return inconnue(voie);
  }
  if (type === 'assistant') {
    const id = lire(d, 'message.id');
    const rouvert = id !== travail.dernierMsgId && travail.clos.includes(id); // garde:index-clos
    if (rouvert) return inconnue(voie); // A, B, A : l'usage de A n'est pas gardé, jamais un comptage double silencieux
    const u = { entree: lire(d, 'message.usage.input_tokens'), sortie: lire(d, 'message.usage.output_tokens'), cacheLu: facultatif(CC, d, 'message.usage.cache_read_input_tokens'), cacheCree: facultatif(CC, d, 'message.usage.cache_creation_input_tokens') };
    const precedent = travail.dernierMsgId;
    if (plierMessage(voie.jetons, travail, id, u)) {
      voie.compteurs.reponsesApi++;
      if (precedent) { travail.clos.push(precedent); if (travail.clos.length > BORNES.clos) travail.clos.splice(0, travail.clos.length - BORNES.clos); }
    }
    const m = facultatif(CC, d, 'message.model'); if (typeof m === 'string' && MODELE_RE.test(m) && !voie.modeles.includes(m) && voie.modeles.length < BORNES.modeles) voie.modeles.push(m);
  }
  const v = facultatif(CC, d, 'version'); if (typeof v === 'string' && VERSION_RE.test(v) && !voie.versions.includes(v) && voie.versions.length < BORNES.versions) voie.versions.push(v);
  if (voie.debut === null) { voie.debut = t; voie.fin = t; if (travail.cwd === undefined) travail.cwd = facultatif(CC, d, 'cwd') ?? null; }
  else if (t > voie.fin) { segment(voie, voie.fin, t); voie.fin = t; recompte(voie); }
  for (const b of liste) {
    const tb = lire(b, 'type');
    if (type === 'assistant' && tb === 'tool_use') appelOuvert(voie, b, t, CC);
    if (type === 'user' && tb === 'tool_result') {
      delete c.ouverts[lire(b, 'tool_use_id')];
      if (facultatif(CC, b, 'is_error') === true) { voie.compteurs.erreurs++; evenement(voie, t, 'erreur'); }
    }
  }
  if (type === 'user') {
    if (facultatif(CC, d, 'origin.kind') === 'human') evenement(voie, t, 'humain');
    if (facultatif(CC, d, 'permissionDecision.decision') === 'reject') voie.compteurs.refus++;
    e.finDeTour = false; e.agentsFond = 0;
  } else { e.finDeTour = facultatif(CC, d, 'message.stop_reason') === 'end_turn'; e.agentsFond = 0; }
}

// R8 : l'appel ouvert le plus récent, jamais le nom ni l'entrée
export function enCours(voie) {
  if (voie.forme === 'inconnue') return null;
  let r = null;
  for (const o of Object.values(voie.curseur.ouverts)) if (!r || o.t >= r.depuisMs) r = { verbe: o.v, depuisMs: o.t };
  return r;
}

// projection de la voie (champs de C3 sans etatOfficiel ni cibles, ni curseur) ; mesures nulles quand la forme est inconnue ; rattachement jamais persisté
export function publique(voie) {
  const inc = voie.forme === 'inconnue', m = (v) => (inc ? null : v);
  return {
    id: voie.id, kind: voie.kind, session: voie.session, parent: voie.parent, depth: voie.depth, role: voie.role, arbre: voie.arbre, background: voie.background,
    debut: voie.debut, fin: voie.fin, dispatchA: voie.dispatchA, fini: voie.fini, arrete: voie.arrete, modeles: voie.modeles,
    compteurs: m(voie.compteurs), jetons: m(voie.jetons), durees: m(voie.durees), segments: m(voie.segments), evenements: m(voie.evenements), enCours: inc ? null : enCours(voie), rattachement: null,
  };
}
