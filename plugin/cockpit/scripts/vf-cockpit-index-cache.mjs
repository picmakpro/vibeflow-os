// vf-cockpit-index-cache — fichier d'index des transcripts : non fiable à la lecture, écriture atomique 0600 (C1, classe AUDC-B-05, T-79-801, T-79-804).
// Exports : FICHIER_INDEX, SCHEMA_INDEX, indexVide(ccVerifie), validerIndex(objet, { maintenant, CC, bornes }) -> { ok, raison },
//           chargerIndex(fichier, lab, opts) -> { etat: 'lu' | 'absent' | 'ecarte', index, raison }, ecrireIndex(fichier, lab, index) -> booléen
// Un fichier invalide est écarté (raison nommée, jamais son contenu) ; jamais importé ni évalué ; aucun lien suivi, fichier ordinaire, à nous, sans droit pour groupe ni autres.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { ID_RE } from './vf-cockpit-lecture.mjs';
import { confiner } from './vf-cockpit-paths.mjs';
import { BORNES, CONTRAT } from './vf-cockpit-index-voie.mjs';

export const FICHIER_INDEX = 'index-transcripts.json';
export const SCHEMA_INDEX = 'vibeflow/cockpit-index@1';
const SPEC = CONTRAT.schemas?.[SCHEMA_INDEX] || {};
const INTERDITES = new Set([...(SPEC.interdits || []), ...(SPEC.jamaisStocke || [])]);
const T2020 = Date.UTC(2020, 0, 1), JOUR = 86400e3;
const GENRES = ['travail', 'attend-agents', 'attend-humain', 'repos', 'silence'], EVTS = ['compaction', 'erreur', 'humain', 'rapport', 'dispatch'];
const ENTIER = (v) => Number.isInteger(v) && v >= 0, OBJ = (v) => !!v && typeof v === 'object' && !Array.isArray(v), CHAINE = (v, n) => typeof v === 'string' && v.length <= n;

export const indexVide = (ccVerifie) => ({ schema: SCHEMA_INDEX, ccVerifie: typeof ccVerifie === 'string' ? ccVerifie : '', versionsVues: [], genereA: new Date(0).toISOString(), fenetreS: BORNES.fenetreS, evinces: 0, voies: [] });

// clé interdite ou de cible à toute profondeur (profondeur bornée)
function cleInterdite(v, prof = 0) {
  if (prof > 12 || !v || typeof v !== 'object') return null;
  for (const k of Object.keys(v)) { if (INTERDITES.has(k)) return k; const r = cleInterdite(v[k], prof + 1); if (r) return r; }
  return null;
}
const sansChemin = (s) => typeof s === 'string' && !/[/\\]/.test(s) && !/^\.\.?$/.test(s);

export function validerIndex(o, opts = {}) {
  const r = controle(o, opts);
  return r; // garde:index-valide
}
function controle(o, { maintenant = Date.now(), bornes = {} } = {}) {
  const B = { ...BORNES, ...bornes }, ko = (raison) => ({ ok: false, raison }), instant = (v) => Number.isFinite(v) && v >= T2020 && v <= maintenant + JOUR;
  if (!OBJ(o)) return ko('index: pas un objet');
  if (o.schema !== SCHEMA_INDEX) return ko('schema: version inconnue');
  const k = cleInterdite(o); if (k) return ko(`cle-interdite: ${k}`);
  if (typeof o.ccVerifie !== 'string' || o.ccVerifie.length > 32) return ko('ccVerifie: forme');
  if (!Array.isArray(o.versionsVues) || o.versionsVues.length > B.versionsVues || !o.versionsVues.every((v) => CHAINE(v, 32))) return ko('versionsVues: forme');
  if (typeof o.genereA !== 'string' || !Number.isFinite(Date.parse(o.genereA))) return ko('genereA: forme');
  if (o.fenetreS !== B.fenetreS) return ko('fenetreS: valeur');
  if (!ENTIER(o.evinces)) return ko('evinces: forme');
  if (!Array.isArray(o.voies)) return ko('voies: pas une liste');
  if (o.voies.length > B.voiesMax) return ko('voies: trop nombreuses');
  const vus = new Set();
  for (const v of o.voies) { const r = validerVoie(v, B, instant); if (r) return ko(`voie: ${r}`); if (vus.has(v.id)) return ko('voie: identifiant en double'); vus.add(v.id); }
  return { ok: true, raison: '' };
}

function validerVoie(v, B, instant) {
  if (!OBJ(v)) return 'forme';
  for (const c of ['id', 'session']) if (typeof v[c] !== 'string' || !ID_RE.test(v[c])) return `${c}: identifiant`;
  if (v.parent !== null && (typeof v.parent !== 'string' || !ID_RE.test(v.parent))) return 'parent: identifiant';
  if (v.kind !== 'session' && v.kind !== 'subagent') return 'kind: valeur';
  if (v.depth !== null && !ENTIER(v.depth)) return 'depth: forme';
  if (v.role !== null && !CHAINE(v.role, B.role)) return 'role: forme';
  if (v.arbre !== null && (!sansChemin(v.arbre) || v.arbre.length > B.arbre)) return 'arbre: forme de chemin';
  for (const c of ['background', 'fini', 'arrete', 'tronque']) if (typeof v[c] !== 'boolean') return `${c}: forme`;
  if (v.forme !== 'ok' && v.forme !== 'inconnue') return 'forme: valeur';
  for (const c of ['debut', 'fin']) if (v[c] !== null && !instant(v[c])) return `${c}: instant`;
  if ((v.debut === null) !== (v.fin === null) || (v.debut !== null && v.fin < v.debut)) return 'debut-fin: incohérents';
  if (v.dispatchA !== null && !instant(v.dispatchA)) return 'dispatchA: instant';
  if (!Array.isArray(v.modeles) || v.modeles.length > B.modeles || !v.modeles.every((m) => CHAINE(m, 64))) return 'modeles: forme';
  if (!Array.isArray(v.versions) || v.versions.length > B.versions || !v.versions.every((m) => CHAINE(m, 32))) return 'versions: forme';
  const mesures = [v.compteurs, v.jetons, v.durees, v.segments, v.evenements];
  const toutesNulles = mesures.every((m) => m === null), aucuneNulle = mesures.every((m) => m !== null);
  if (v.forme === 'inconnue' ? !toutesNulles && !aucuneNulle : !aucuneNulle) return 'mesures: incohérentes avec la forme';
  if (aucuneNulle) {
    for (const [c, noms] of [['compteurs', SPEC.compteurs], ['jetons', SPEC.jetons], ['durees', SPEC.durees]]) if (!OBJ(v[c]) || !(noms || []).every((n) => ENTIER(v[c][n]))) return `${c}: forme`;
    if (!Array.isArray(v.segments) || v.segments.length > B.segments) return 'segments: nombre';
    let prec = -Infinity;
    for (const s of v.segments) { if (!Array.isArray(s) || s.length !== 3 || !instant(s[0]) || !instant(s[1]) || s[1] <= s[0] || s[0] < prec || !GENRES.includes(s[2])) return 'segments: forme ou ordre'; prec = s[1]; }
    if (!Array.isArray(v.evenements) || v.evenements.length > B.evenements || !v.evenements.every((e) => Array.isArray(e) && e.length === 2 && instant(e[0]) && EVTS.includes(e[1]))) return 'evenements: forme';
  }
  if (v.forme === 'inconnue' ? v.enCours !== null : false) return 'enCours: attendu nul';
  {
    if (v.enCours !== null && !(OBJ(v.enCours) && CHAINE(v.enCours.verbe, 64) && instant(v.enCours.depuisMs))) return 'enCours: forme';
  }
  const c = v.curseur; if (!OBJ(c)) return 'curseur: forme';
  for (const n of ['octets', 'taille']) if (!ENTIER(c[n])) return `curseur.${n}: forme`;
  if (c.octets > c.taille) return 'curseur.octets: au-delà de la taille';
  if (!Number.isFinite(c.mtimeMs) || c.mtimeMs < 0) return 'curseur.mtimeMs: forme';
  if (c.tete !== null && !/^[0-9a-f]{16}$/.test(String(c.tete))) return 'curseur.tete: forme';
  if (c.dernierMsgId !== null && !CHAINE(c.dernierMsgId, 256)) return 'curseur.dernierMsgId: forme';
  if (c.usage !== null && !(OBJ(c.usage) && ['entree', 'sortie', 'cacheLu', 'cacheCree'].every((n) => ENTIER(c.usage[n])))) return 'curseur.usage: forme';
  if (!ENTIER(c.maxClos)) return 'curseur.maxClos: forme';
  if (!Array.isArray(c.clos) || c.clos.length > B.clos || !c.clos.every((x) => CHAINE(x, 256))) return 'curseur.clos: forme';
  if (!OBJ(c.ouverts) || Object.keys(c.ouverts).length > B.ouverts || !Object.entries(c.ouverts).every(([id, o]) => CHAINE(id, 256) && OBJ(o) && CHAINE(o.v, 64) && instant(o.t) && ['humain', 'agents', 'autre'].includes(o.c))) return 'curseur.ouverts: forme';
  if (!Array.isArray(c.lancements) || c.lancements.length > B.lancements || !c.lancements.every((l) => Array.isArray(l) && l.length === 2 && CHAINE(l[0], 256) && instant(l[1]))) return 'curseur.lancements: forme';
  if (typeof c.saut !== 'boolean') return 'curseur.saut: forme';
  const e = c.etat; if (!OBJ(e) || typeof e.finDeTour !== 'boolean' || !ENTIER(e.agentsFond) || !OBJ(e.msParGenre) || !GENRES.every((g) => Number.isFinite(e.msParGenre[g]) && e.msParGenre[g] >= 0)) return 'curseur.etat: forme';
  return null;
}

// un dossier à nous (ni lien, ni autre chose)
const dossierOk = (d, uid) => { try { const s = fs.lstatSync(d); return s.isDirectory() && !s.isSymbolicLink() && (uid === undefined || s.uid === uid); } catch { return false; } };

export function chargerIndex(fichier, lab, opts = {}) {
  const k = fs.constants, uid = opts.uid ?? (typeof process.getuid === 'function' ? process.getuid() : undefined); let fd = null;
  const B = { ...BORNES, ...(opts.bornes || {}) };
  try {
    try { fd = fs.openSync(fichier, k.O_RDONLY | (k.O_NOFOLLOW || 0) | (k.O_NONBLOCK || 0)); } catch (e) { return { etat: e && e.code === 'ENOENT' ? 'absent' : 'ecarte', index: null, raison: e && e.code === 'ENOENT' ? '' : 'ouverture refusée (lien ou fichier illisible)' }; }
    const st = fs.fstatSync(fd);
    if (!st.isFile()) return { etat: 'ecarte', index: null, raison: 'pas un fichier ordinaire' };
    if (uid !== undefined && st.uid !== uid) return { etat: 'ecarte', index: null, raison: 'autre propriétaire' };
    if ((st.mode & 0o077) !== 0) return { etat: 'ecarte', index: null, raison: 'droits trop larges' };
    if (st.size > B.fichierOctets) return { etat: 'ecarte', index: null, raison: 'fichier trop gros' };
    const buf = Buffer.alloc(st.size), n = fs.readSync(fd, buf, 0, st.size, 0);
    let o; try { o = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(buf.subarray(0, n))); } catch { return { etat: 'ecarte', index: null, raison: 'JSON illisible' }; }
    const r = validerIndex(o, { maintenant: opts.maintenant, CC: opts.CC, bornes: opts.bornes });
    return r.ok ? { etat: 'lu', index: o, raison: '' } : { etat: 'ecarte', index: null, raison: r.raison };
  } catch { return { etat: 'ecarte', index: null, raison: 'lecture impossible' }; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } }
}

export function ecrireIndex(fichier, lab, index) {
  const dossier = path.dirname(fichier); let tmp = null, fd = null;
  try {
    let a = dossier; while (!fs.existsSync(a) && a !== path.dirname(a)) a = path.dirname(a);
    confiner(lab, path.join(a, 'x')); // le plus proche ancêtre existant est dans le lab, jamais un lien qui en sort
    fs.mkdirSync(dossier, { recursive: true, mode: 0o700 });
    if (!dossierOk(dossier, typeof process.getuid === 'function' ? process.getuid() : undefined)) return false;
    confiner(lab, fichier);
    tmp = path.join(dossier, `${FICHIER_INDEX}.${process.pid}.${crypto.randomBytes(8).toString('hex')}.tmp`);
    fd = fs.openSync(tmp, 'wx', 0o600); fs.writeSync(fd, JSON.stringify(index)); fs.fsyncSync(fd); fs.closeSync(fd); fd = null;
    fs.renameSync(tmp, fichier); tmp = null;
    return true;
  } catch { return false; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } if (tmp) { try { fs.unlinkSync(tmp); } catch {} } }
}
