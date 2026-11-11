// vf-cockpit-index — index incrémental des transcripts de Claude Code (C1, vibeflow/cockpit-index@1, P79-D-03, P79-D-29). Synchrone, aucun processus, aucun réseau.
// Exports : FENETRE_S (86 400), enumerer(projects) -> candidats { fichier, kind, session, id, meta }, mettreAJour(index, candidats, opts) -> { index, change },
//           construire(candidats, opts) (une passe), bilan(index) -> { voies, formeInconnue, tronque, evinces, versionsHorsContrat }
// Seuls les octets ajoutés depuis le curseur sont lus (lignes complètes seulement) ; fichier raccourci ou tête changée : voie relue depuis zéro ; transcript disparu : voie retirée.
// opts : maintenant, arbreDe(cwd) -> { arbre } | null (preuve de l'appartenance au lab : celle de l'appelant), vivantes (Set, état officiel), memoHors (Map), bornes, CC (contrat).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { ID_RE, readJson, retireAffichage, masqueCoupe } from './vf-cockpit-lecture.mjs';
import { formeSousAgent } from './vf-cockpit-equipe.mjs';
import { BORNES, CONTRAT, voieNeuve, plierLigne, enCours, inconnue } from './vf-cockpit-index-voie.mjs';
import { SCHEMA_INDEX, indexVide } from './vf-cockpit-index-cache.mjs';

export const FENETRE_S = BORNES.fenetreS;
const META_MAX = 256 << 10;

export function enumerer(projects) {
  const r = [], ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
  const meta = (f) => ({ configurable: true, enumerable: false, get: () => readJson(f, META_MAX) });
  for (const slug of ls(projects)) {
    const dir = path.join(projects, slug);
    for (const f of ls(dir)) {
      if (f.endsWith('.jsonl') && ID_RE.test(f.slice(0, -6))) r.push({ fichier: path.join(dir, f), kind: 'session', session: f.slice(0, -6), id: f.slice(0, -6), meta: null });
      else if (ID_RE.test(f)) {
        const sub = path.join(dir, f, 'subagents');
        for (const g of ls(sub)) {
          const m = /^agent-(.+)\.jsonl$/.exec(g);
          if (m && ID_RE.test(m[1])) { const c = { fichier: path.join(sub, g), kind: 'subagent', session: f, id: m[1] }; Object.defineProperty(c, 'meta', meta(path.join(sub, `agent-${m[1]}.meta.json`))); r.push(c); }
        }
      }
    }
  }
  return r;
}

const hash = (b) => crypto.createHash('sha256').update(b).digest('hex').slice(0, 16);
// identité d'un sous-agent depuis son meta.json (R9) ; null si le meta est refusé par formeSousAgent
function identiteSous(c, CC, seuil) {
  const meta = c.meta, f = formeSousAgent(meta, { isSidechain: true, agentId: c.id }, c.id, CC);
  if (!f) return null;
  const brut = meta.agentType; // garde:index-role : le rôle est le type d'agent, jamais la description de la tâche
  const role = typeof brut === 'string' ? masqueCoupe(retireAffichage(brut), BORNES.role) : null;
  return { id: c.id, kind: 'subagent', session: c.session, parent: typeof meta.parentAgentId === 'string' && meta.spawnDepth >= seuil ? meta.parentAgentId : c.session, depth: typeof meta.spawnDepth === 'number' ? meta.spawnDepth : null,
    role, background: meta.requestShape === 'background', fini: meta.finished === true, arrete: f === 'arretee' && meta.stoppedByUser === true };
}

function lireVoie(voie, fichier, fd, taille, bornes, CC) {
  const c = voie.curseur, bloc = bornes.bloc, travail = { dernierMsgId: c.dernierMsgId, usage: c.usage, maxClos: c.maxClos, clos: c.clos.slice(), cwd: undefined };
  let pos = c.octets, pend = Buffer.alloc(0), saut = c.saut;
  const lu = () => { const n = Math.min(bloc, taille - pos); const b = Buffer.alloc(n); const k = fs.readSync(fd, b, 0, n, pos); pos += k; return b.subarray(0, k); };
  while (pos < taille && voie.forme !== 'inconnue') {
    let chunk = lu(); if (!chunk.length) break;
    if (saut) { const i = chunk.indexOf(10); if (i < 0) continue; chunk = chunk.subarray(i + 1); saut = false; }
    const tout = Buffer.concat([pend, chunk]), dernier = tout.lastIndexOf(10);
    pend = dernier < 0 ? tout : tout.subarray(dernier + 1);
    if (dernier >= 0) for (const l of tout.subarray(0, dernier).toString('utf8').split('\n')) {
      if (!l) continue;
      if (Buffer.byteLength(l) > bornes.ligneMax) { voie.tronque = true; continue; }
      let d; try { d = JSON.parse(l); } catch { continue; }
      plierLigne(voie, d, travail, CC);
    }
    if (pend.length > bornes.ligneMax) { pend = Buffer.alloc(0); saut = true; voie.tronque = true; }
  }
  const fin = voie.forme === 'inconnue' || saut ? pos : pos - pend.length;
  c.octets = fin; // garde:index-octets
  c.saut = voie.forme === 'inconnue' ? false : saut; c.taille = taille;
  c.dernierMsgId = travail.dernierMsgId; c.usage = travail.usage; c.maxClos = travail.maxClos; c.clos = travail.clos; // garde:index-msgid
  return travail;
}

function ouvrir(fichier) {
  const k = fs.constants; let fd = null;
  try { const st = fs.lstatSync(fichier); if (!st.isFile()) return null; fd = fs.openSync(fichier, k.O_RDONLY | (k.O_NOFOLLOW || 0) | (k.O_NONBLOCK || 0)); const s = fs.fstatSync(fd); if (!s.isFile()) throw new Error(); return { fd, st: s }; }
  catch { if (fd !== null) { try { fs.closeSync(fd); } catch {} } return null; }
}
function teteDe(fd, taille, lim) {
  const n = Math.min(taille, lim), b = Buffer.alloc(n), k = n ? fs.readSync(fd, b, 0, n, 0) : 0, nl = b.subarray(0, k).indexOf(10);
  if (nl >= 0) return hash(b.subarray(0, nl));
  return k >= lim ? hash(b.subarray(0, k)) : null;
}

export function mettreAJour(index, candidats, opts = {}) {
  const maintenant = opts.maintenant ?? Date.now(), bornes = { ...BORNES, ...(opts.bornes || {}) }, CC = opts.CC || CONTRAT.claudeCode, vivantes = opts.vivantes || new Set();
  const arbreDe = opts.arbreDe || (() => ({ arbre: null })), memoHors = opts.memoHors || new Map(), seuil = CC?.metaSousAgent?.requisSiProfondeur?.parentAgentId ?? 2;
  if (!index || index.schema !== SCHEMA_INDEX) index = indexVide(CC?.verifieSur);
  const avant = JSON.stringify(index.voies), parId = new Map(index.voies.map((v) => [v.id, v])), vus = new Map();
  for (const c of candidats) { let st; try { st = fs.lstatSync(c.fichier); } catch { continue; } if (!st.isFile()) continue; const p = vus.get(c.id); if (!p || st.mtimeMs > p.st.mtimeMs) vus.set(c.id, { c, st }); }
  const debutFen = maintenant - FENETRE_S * 1000;
  for (const [id, voie] of [...parId]) if (!vus.has(id)) { parId.delete(id); index.voies = index.voies.filter((v) => v !== voie); }
  for (const [id, { c, st }] of vus) {
    let voie = parId.get(id), neuve = false;
    const cle = `${st.mtimeMs}:${st.size}`;
    if (!voie) { if (st.mtimeMs < debutFen || memoHors.get(c.fichier) === cle) continue; neuve = true; }
    else if (voie.curseur.taille === st.size && voie.curseur.mtimeMs === st.mtimeMs) { if (voie.kind === 'subagent') majMeta(voie, c, CC, seuil); continue; }
    const o = ouvrir(c.fichier); if (!o) continue;
    try {
      const tete = teteDe(o.fd, o.st.size, bornes.tete);
      if (voie) {
        const teteDiff = voie.curseur.tete !== null && tete !== voie.curseur.tete; // garde:index-tete
        const relit = teteDiff || o.st.size < voie.curseur.octets; // garde:index-relit
        if (relit) { const ident = { id, kind: voie.kind, session: voie.session }; voie = Object.assign(voieNeuve(ident), { parent: voie.parent, depth: voie.depth, role: voie.role, arbre: voie.arbre, background: voie.background, fini: voie.fini, arrete: voie.arrete }); neuve = true; }
      }
      if (neuve && !voie) {
        let ident = { id, kind: c.kind, session: c.session };
        if (c.kind === 'subagent') { ident = identiteSous(c, CC, seuil); if (!ident) { const v = voieNeuve({ id, kind: 'subagent', session: c.session }); inconnue(v); v.curseur.taille = o.st.size; v.curseur.mtimeMs = o.st.mtimeMs; v.curseur.octets = o.st.size; v.curseur.tete = tete; voie = v; } }
        if (!voie) voie = voieNeuve(ident);
      }
      const t = voie.forme === 'inconnue' && neuve && voie.curseur.octets ? { cwd: undefined } : lireVoie(voie, c.fichier, o.fd, o.st.size, bornes, CC);
      voie.enCours = voie.forme === 'inconnue' ? null : enCours(voie);
      voie.curseur.tete = tete; voie.curseur.mtimeMs = o.st.mtimeMs; voie.curseur.taille = o.st.size;
      if (neuve) {
        if (voie.debut === null && voie.forme === 'ok') { parId.delete(id); index.voies = index.voies.filter((v) => v.id !== id); continue; } // aucune ligne datée encore : rien à indexer, retenté au prochain tour
        const r = opts.arbreDe === undefined ? { arbre: null } : arbreDe(t.cwd ?? null);
        if (!r || (r.arbre !== null && !/^[^/\\]{1,200}$/.test(String(r.arbre)))) { memoHors.set(c.fichier, cle); parId.delete(id); index.voies = index.voies.filter((v) => v.id !== id); continue; }
        voie.arbre = r.arbre; parId.set(id, voie); index.voies = index.voies.filter((v) => v.id !== id); index.voies.push(voie);
      }
      if (voie.kind === 'subagent') majMeta(voie, c, CC, seuil);
    } finally { try { fs.closeSync(o.fd); } catch {} }
  }
  for (const v of index.voies) if (v.kind === 'subagent' && v.dispatchA === null) { const p = parId.get(v.parent), tu = vus.get(v.id)?.c.meta?.toolUseId; const l = p && p.curseur.lancements.find((x) => x[0] === tu); if (l) v.dispatchA = l[1]; }
  // R13 : fenêtre, état officiel, ancêtres, plafond
  const gardees = new Set();
  for (const v of index.voies) {
    const ref = v.fin ?? v.curseur.mtimeMs;
    const garde = ref >= debutFen || vivantes.has(v.id); // garde:index-retention
    if (garde) gardees.add(v.id);
  }
  for (const id of [...gardees]) for (let p = parId.get(id)?.parent, n = 0; p && n < 16; p = parId.get(p)?.parent, n++) gardees.add(p);
  let restant = index.voies.filter((v) => gardees.has(v.id)).sort((a, b) => (b.fin ?? b.curseur.mtimeMs) - (a.fin ?? a.curseur.mtimeMs));
  index.evinces = Math.max(0, restant.length - bornes.voiesMax); restant = restant.slice(0, bornes.voiesMax);
  index.voies = index.voies.filter((v) => restant.includes(v)).sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  index.versionsVues = [...new Set(index.voies.flatMap((v) => v.versions))].sort().slice(0, bornes.versionsVues);
  index.genereA = new Date(maintenant).toISOString(); index.fenetreS = FENETRE_S;
  return { index, change: JSON.stringify(index.voies) !== avant };
}
function majMeta(voie, c, CC, seuil) {
  const i = identiteSous(c, CC, seuil);
  if (!i) { inconnue(voie); return; }
  Object.assign(voie, { parent: i.parent, depth: i.depth, role: i.role, background: i.background, fini: i.fini, arrete: i.arrete });
}

export const construire = (candidats, opts = {}) => mettreAJour(indexVide((opts.CC || CONTRAT.claudeCode)?.verifieSur), candidats, opts).index;

export function bilan(index, opts = {}) {
  const cc = index.ccVerifie, voies = index.voies;
  return { voies: voies.length, formeInconnue: voies.filter((v) => v.forme === 'inconnue').length, tronque: voies.some((v) => v.tronque) || index.evinces > 0, evinces: index.evinces, versionsHorsContrat: index.versionsVues.filter((v) => v !== cc) };
}
