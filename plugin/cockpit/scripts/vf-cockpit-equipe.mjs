// vf-cockpit-equipe — collecte des sessions Claude Code et de leurs sous-agents en arbre (P69-D-14, P69-D-18, P69-D-22).
// Exports : FENETRE (86400 s), collecteAgents(ctx) -> { workers, source }, formeSousAgent(meta, premiere, id, CC) -> 'complete' | 'arretee' | null,
//           rattacher(workers, { index, registre, mandatDe }) -> champ `rattachement` des sous-agents (P69-D-15), indexDesNoeuds(dags) -> Map nœud -> [{ dag, ws, wsDeclare }]
// Lecture seule, aucun réseau ; les listes de forme viennent du contrat (vf-cockpit-interface.json, bloc claudeCode passé en ctx.CC), jamais du code.
// Seuls les candidats de la fenêtre (le .jsonl voisin modifié depuis moins de `fenetre`) et leurs ancêtres retrouvés par identifiant sont ouverts.
import fs from 'node:fs';
import path from 'node:path';
import { ls, mtime, readJson, ID_RE, premiereLigne, titreSession } from './vf-cockpit-lecture.mjs';
import { derniereAction, citationsDuMandat } from './vf-cockpit-transcript.mjs';
import { SILENCE_MAX_S, ATTEND_UN_ENFANT, outilEnCours } from './vf-cockpit-equipe-etat.mjs';

export const FENETRE = 86400;
const PROFONDEUR_MAX = 8;
const META_MAX = 256 << 10; // un meta.json plus gros n'est pas lu : l'agent est de forme inconnue (F4)
const REQUIS_PAR_DEFAUT = ['agentType', 'description', 'spawnDepth', 'toolUseId', 'requestShape'];
const objet = (v) => !!v && typeof v === 'object' && !Array.isArray(v);

export function formeSousAgent(meta, premiere, id, CC) {
  const M = CC?.metaSousAgent || {}, T = CC?.transcriptSousAgent?.requis || ['isSidechain', 'agentId'];
  if (!objet(meta) || !objet(premiere) || !T.every((k) => k in premiere) || premiere.isSidechain !== true || premiere.agentId !== id) return null;
  const ar = M.formeArretee;
  if (ar && Object.keys(meta).length === ar.requis.length && ar.requis.every((k) => k in meta) && (ar.booleens || []).every((k) => typeof meta[k] === 'boolean')) return 'arretee';
  if (!(M.requis || REQUIS_PAR_DEFAUT).every((k) => k in meta) || typeof meta.spawnDepth !== 'number') return null;
  for (const [k, d] of Object.entries(M.requisSiProfondeur || {})) if (meta.spawnDepth >= d && typeof meta[k] !== 'string') return null;
  for (const k of M.booleensFacultatifs || []) if (k in meta && typeof meta[k] !== 'boolean') return null;
  return 'complete';
}

export function collecteAgents(ctx) {
  const { projects, now, fresh, fenetre = FENETRE, inScope, label, branche, byActivity, CC, tail, root } = ctx;
  const action = (w) => { if (w.etat === 'actif') { const a = derniereAction(w._tr, root); if (a) w.action = a; } return w; }; // P69-D-16 : agents actifs seulement
  if (!fs.existsSync(projects)) return { workers: [], source: { etat: 'absente', path: projects } };
  const seuil = CC?.metaSousAgent?.requisSiProfondeur?.parentAgentId ?? 2;
  const workers = [];
  let scanned = 0, live = 0, subLive = 0, inconnuSub = 0, inconnuSession = 0;
  for (const slug of ls(projects)) {
    const dir = path.join(projects, slug);
    for (const f of ls(dir).filter((x) => x.endsWith('.jsonl'))) {
     try { // F3 : une session ou un agent qui fait lever la lecture est compté en forme inconnue, jamais fatal pour les autres
      const file = path.join(dir, f); const age = (now - mtime(file)) / 1000;
      const id = f.slice(0, -6); if (!ID_RE.test(id)) { inconnuSession++; continue; }
      const subDir = path.join(dir, id, 'subagents');
      const infos = new Map(); // identifiant -> { id, meta, tr, sAge, forme, premiere }
      const charge = (aid, candidat) => {
        if (infos.has(aid)) return infos.get(aid);
        const mj = path.join(subDir, `agent-${aid}.meta.json`); let r = null;
        if (!ID_RE.test(aid)) return null; // l'identifiant vient d'un nom de fichier : jamais émis hors ID_RE (F2)
        if (candidat || (ID_RE.test(aid) && fs.existsSync(mj))) {
          const tr = path.join(subDir, `agent-${aid}.jsonl`), meta = readJson(mj, META_MAX), premiere = premiereLigne(tr);
          r = { id: aid, meta, tr, sAge: (now - mtime(tr)) / 1000, premiere, forme: formeSousAgent(meta, premiere, aid, CC) };
        }
        infos.set(aid, r); return r;
      };
      const cands = [];
      for (const m of ls(subDir).filter((x) => x.endsWith('.meta.json'))) {
        const aid = m.replace(/^agent-|\.meta\.json$/g, '');
        const sAge = (now - mtime(path.join(subDir, `agent-${aid}.jsonl`))) / 1000;
        if (sAge >= fenetre) continue; // FENETRE-24H
        const c = charge(aid, true); if (!c) { inconnuSub++; continue; } // identifiant hors ID_RE
        cands.push(c);
      }
      // AUDC-D1 : un agent non fini et muet reste vivant tant que son silence ne passe pas SILENCE_MAX_S ; « actif » s'il a un appel d'outil sans résultat (autre qu'une attente d'agent), sinon « en attente »
      const enCours = (c) => { if (c.pend === undefined) c.pend = c.meta.finished === true || c.forme === 'arretee' || c.sAge >= SILENCE_MAX_S ? null : outilEnCours(c.tr); return c.pend; };
      const propre = (c) => { if (c.meta.finished === true || c.forme === 'arretee') return 'termine'; if (c.sAge < fresh) return 'actif'; const p = enCours(c); return p && !ATTEND_UN_ENFANT.has(p.nom) ? 'actif' : 'en-attente'; };
      const parentsFrais = new Set(); // un agent muet qui a un descendant en train d'écrire attend celui-ci : « en attente », jamais « actif » (E19.4)
      const final = (x) => { const e = propre(x); return e === 'actif' && x.sAge >= fresh && parentsFrais.has(x.id) ? 'en-attente' : e; };
      const inclus = new Map(); // identifiant -> { c, etat }
      for (const c of cands) {
        if (!c.forme) { inconnuSub++; continue; }
        const anc = []; let cur = c, casse = false; const vus = new Set([c.id]);
        while (cur.forme === 'complete' && cur.meta.spawnDepth >= seuil) {
          const pid = cur.meta.parentAgentId; const p = anc.length < PROFONDEUR_MAX && !vus.has(pid) ? charge(pid, false) : null;
          if (!p || !p.forme) { casse = true; break; }
          vus.add(pid); anc.push(p); cur = p;
        }
        if (casse) { inconnuSub++; continue; }
        const etat = propre(c);
        if (etat === 'en-attente' && c.sAge >= SILENCE_MAX_S) continue; // un candidat ni fini ni vivant (muet depuis plus de SILENCE_MAX_S) n'est présent que comme ancêtre
        if (etat === 'actif' && c.sAge < fresh) for (const x of anc) parentsFrais.add(x.id);
        for (const x of [c, ...anc]) if (!inclus.has(x.id)) inclus.set(x.id, { c: x, etat: null });
      }
      for (const v of inclus.values()) v.etat = final(v.c);
      if (age > fresh && !inclus.size) continue;
      scanned++;
      const last = tail(file);
      if (last && !ctx.formeOk(last)) { inconnuSession++; continue; }
      const tree = inScope(last?.cwd);
      if (!tree) continue;
      if (age <= fresh) live++;
      if (age <= fresh || inclus.size) {
        const at = byActivity(last, tree, file);
        const desc = [...inclus.values()].some((x) => x.etat !== 'termine');
        workers.push(action({ kind: 'session', id, tree: label(at.tree), treeBy: at.how, branch: branche(at.tree, last.gitBranch), cwd: last.cwd, ...(titreSession(file) ? { titre: titreSession(file) } : {}), ageS: Math.round(age), lastAt: last.timestamp, source: 'transcript', etat: age <= fresh ? 'actif' : desc ? 'en-attente' : 'termine', _tr: file }));
      }
      for (const { c, etat } of inclus.values()) {
        const sl = tail(c.tr); if (sl && !ctx.formeOk(sl)) { inconnuSub++; continue; } // dernière ligne hors forme : l'agent est exclu
        subLive++;
        const at = byActivity(sl, inScope(sl?.cwd) || tree, c.tr);
        const parent = c.forme === 'complete' && c.meta.spawnDepth >= seuil ? c.meta.parentAgentId : id;
        const t0 = Date.parse(c.premiere?.timestamp), fin = etat === 'termine' ? mtime(c.tr) : null;
        const w = { kind: 'subagent', id: c.id, parent, role: c.meta.agentType, task: c.meta.description || '', ...(c.forme === 'complete' ? { depth: c.meta.spawnDepth, background: c.meta.requestShape === 'background' } : {}),
          tree: label(at.tree), treeBy: at.how, branch: branche(at.tree, sl?.gitBranch, last.gitBranch), ageS: Math.round(c.sAge), source: 'subagent-meta', etat };
        if (fin) w.finAt = new Date(fin).toISOString();
        if (etat === 'actif' && enCours(c)) w.enCours = true; // l'appel d'outil sans résultat dont l'âge (ageS) est la durée (AUDC-D1)
        if (Number.isFinite(t0)) w.dureeS = Math.max(0, Math.round(((fin || now) - t0) / 1000));
        w._tr = c.tr; workers.push(action(w));
      }
     } catch { inconnuSub++; }
    }
  }
  const inconnue = inconnuSub > 0 || (inconnuSession > 0 && live + subLive === 0);
  return { workers, source: { etat: inconnue ? 'forme-inconnue' : 'lue', path: projects, recentFiles: scanned, liveSessions: live, liveSubagents: subLive, formeInconnue: inconnuSub + inconnuSession } };
}

// index des nœuds de mission : Map identifiant de nœud -> [{ dag, ws, wsDeclare }] (une entrée par DAG ; une Map, la clé vient d'un fichier : T-69-09)
export function indexDesNoeuds(dags) {
  const index = new Map();
  for (const d of dags) for (const n of d.nodes || []) {
    if (typeof n?.id !== 'string') continue;
    const l = index.get(n.id) || []; if (!l.some((e) => e.dag === d.file)) l.push({ dag: d.file, ws: d.ws ?? null, wsDeclare: d.wsDeclare ?? null });
    index.set(n.id, l);
  }
  return index;
}

// P69-D-15 : le registre, quand il porte un nœud pour l'agent, décide seul (candidats : DAG du compartiment de l'appel `orphans`, tous pour le dépôt) ;
// sinon les citations du mandat. Un seul DAG -> rattache ; aucun -> inconnu ; plusieurs -> ambigu ; aucune citation -> sans-citation. Jamais deviné.
export function rattacher(workers, { index, registre, mandatDe }) {
  const non = (raison) => ({ etat: 'non-rattache', raison });
  for (const w of workers) {
    if (w.kind !== 'subagent') continue;
    const r = registre.get(w.id);
    if (r && typeof r.noeud === 'string' && r.noeud) {
      const c = (index.get(r.noeud) || []).filter((e) => !r.ws || e.ws === r.ws || e.wsDeclare === r.ws);
      w.rattachement = c.length === 1 ? { etat: 'rattache', source: 'registre', dag: c[0].dag, noeud: r.noeud } : non(c.length ? 'ambigu' : 'inconnu');
      continue;
    }
    const ids = citationsDuMandat(mandatDe(w.id));
    if (!ids.length) { w.rattachement = non('sans-citation'); continue; }
    const paires = []; let multiple = false;
    for (const id of ids) { const c = index.get(id) || []; if (c.length > 1) multiple = true; for (const e of c) paires.push({ dag: e.dag, noeud: id }); }
    w.rattachement = multiple || paires.length > 1 ? non('ambigu') : paires.length === 1 ? { etat: 'rattache', source: 'mandat', ...paires[0] } : non('inconnu');
  }
}
