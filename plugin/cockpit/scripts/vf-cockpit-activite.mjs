// vf-cockpit-activite — l'objet de GET /api/vf/activite (Phase 75, plan 75-05 ; ACTV-04, ACTV-08, ACTV-10 ; P75-D-09, P75-D-22, P75-D-23, A31, A45, A47).
// Exports : SCHEMA_ACTIVITE, COLLISIONS_MAX, GRACE_MS, creerActivite(options) -> activite(ctx), activite,
//   routeActivite (le lecteur de la ligne de la table des routes).
// Entrées : l'instantané en mémoire (signal, projet, frise, git.sig) et graph.json de la sortie, relu quand il change.
//   Jamais une collecte, jamais une route rappelée, jamais le lab.
// La part git (journal, branches, gardes) est calculée HORS de la requête, en mono-vol, SEULEMENT quand `git.sig` (ou le graphe)
//   change : la requête répond tout de suite avec l'objet précédent et `calcul: "en-cours"` (premier calcul : `etat: "en-calcul"`).
//   La part agents et plans est recalculée par instantané.
// Un chemin, une branche, un rôle ne sont jamais des clés d'objet : des tableaux de tuples. Un chemin rendu n'est jamais ouvert, décodé ni résolu ici.
// Une exception d'un module rend `indisponible` sur la lentille seule. Options d'essai : `binaire` (le programme git), `horloge`, `lireInstantane`.
import path from 'node:path';
import { instantane } from './vf-cockpit-instantane.mjs';
import { lancerGitAsync } from './vf-cockpit-git-lanceur.mjs';
import { monoVol } from './vf-cockpit-git.mjs';
import { lireWorktrees } from './vf-cockpit-git-graphe.mjs';
import { worktreeVerifie } from './vf-cockpit-git-details.mjs';
import { nettoie } from './vf-cockpit-arbres.mjs';
import { HORS } from './vf-cockpit-cible.mjs';
import { lireGrapheCode } from './vf-cockpit-graphe-fichier.mjs';
import { calculerGit, pointsChauds } from './vf-cockpit-activite-git.mjs';
import { resoudre } from './vf-cockpit-activite-log.mjs';
import { collisionsBranches } from './vf-cockpit-activite-branches.mjs';
import { contexteGardes, calculerGardes } from './vf-cockpit-activite-gardes.mjs';
import { empreinte, VOIES_MAX, LIMITE } from './vf-cockpit-activite-empreinte.mjs';
import { collisionsAgents, collisionsPlans } from './vf-cockpit-activite-collisions.mjs';

const SCHEMA = 'vibeflow/cockpit-activite@1';
export const SCHEMA_ACTIVITE = SCHEMA;
export const COLLISIONS_MAX = 500, GRACE_MS = 30000;
const SANS_SIGNATURE = 'sans-signature', ECHEANCE_MS = 20000;
const LECTURE = { etat: 'en-lecture' };
const INDISPO = { etat: 'indisponible' };
const SANS_ARBRES = { liste: undefined, principal: null, verifies: [] };
const RANG = { agents: 0, arbres: 1, branches: 2, plans: 3 };
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const essai = (f, repli) => { try { return f(); } catch { return repli; } };
const essaiA = async (f, repli) => { try { return await f(); } catch { return repli; } };
const cleVol = (lab) => `activite\0${lab}`;
const nomDe = (c) => nettoie(path.basename(c), 200);
const gardesVides = (etat, prevus = 0) => ({ etat, gardes: [], estGarde: [], prevusIgnores: prevus });
const videEmp = (etat, raisons) => ({ etat, incomplet: true, limite: [LIMITE, ...raisons], marques: [], horsCarte: 0, horsLab: 0, coupees: 0, rejetes: 0,
  ignorees: 0, voiesTronquees: false, voiesCiblesTronquees: 0 });
const RADAR_VIDE = { incomplet: true, raisons: ['agents-indisponible'], total: 0, tronque: false, sansVague: 0, plansTronques: false, limites: [] };
const horsService = (o) => ({ schema: SCHEMA, at: new Date(o.horloge()).toISOString(), etat: 'indisponible', calcul: 'pret',
  git: { ...INDISPO }, branches: { ...INDISPO }, gardes: gardesVides('indisponible'), empreinte: videEmp('indisponible', []),
  collisions: [], radar: { ...RADAR_VIDE } });

// l'arbre principal (nom), les worktrees VÉRIFIÉS du même dépôt (noms ; le lien retour est prouvé, jamais déclaré) : A45, A46
async function arbresDe(lire) {
  const cm = await lire(['rev-parse', '--path-format=absolute', '--git-common-dir']), w = await lire(['worktree', 'list', '--porcelain', '-z']);
  const lu = cm.ok && w.ok ? lireWorktrees(w.sortie) : { ok: false };
  if (!lu.ok || !lu.worktrees.length) return SANS_ARBRES;
  const [premier, ...autres] = lu.worktrees;
  return { liste: lu.worktrees, principal: nomDe(premier.chemin),
    verifies: autres.filter((x) => !x.nu && worktreeVerifie(cm.sortie.trim(), x.chemin)).map((x) => nomDe(x.chemin)) };
}

// lecture git sur une clé neuve : journal incrémental, arbres vérifiés, collisions committées ; chaque lentille tombe seule en `indisponible`
async function lireBase(lab, cle, prec, loc, o) {
  const git = await essaiA(() => calculerGit(lab, { loc, etatPrecedent: prec && prec.git, binaire: o.binaire, maintenant: o.horloge() }), INDISPO);
  if (git.etat === 'absent') return { cle, git, branches: { etat: 'absent' }, arbres: SANS_ARBRES };
  const lire = (args) => lancerGitAsync(lab, args, { fin: Date.now() + ECHEANCE_MS, binaire: o.binaire, maxBuffer: 16 << 20 });
  const arbres = await essaiA(() => arbresDe(lire), SANS_ARBRES);
  const branches = await essaiA(() => collisionsBranches(lab, { worktrees: arbres.liste, binaire: o.binaire }), INDISPO);
  return { cle, git, branches, arbres };
}

function sectionGit(b, loc) {
  const g = b.git;
  if (g.etat !== 'ok' && g.etat !== 'vide') return { etat: g.etat };
  const p = pointsChauds(resoudre(g.memo.commits), loc);
  return { etat: g.etat, fenetre: g.fenetre, chauds: p.chauds, couplage: g.couplage, paliers: p.paliers };
}
const sectionBranches = (br) => (br.etat === 'ok'
  ? { etat: 'ok', tetes: br.tetes, plafond: br.plafond, plafondAtteint: br.plafondAtteint } : { etat: br.etat });

async function sectionGardes(lab, b, carte) {
  const g = carte && carte.g;
  if (!g || !g.meta || g.meta.vfCodeExtractor !== 'vibeflow') return gardesVides('non-lues'); // lab non VibeFlow : jamais « tout sans témoin »
  const prevus = Number.isInteger(g.meta.prevusIgnores) && g.meta.prevusIgnores > 0 ? g.meta.prevusIgnores : 0;
  if (b.git.etat === 'absent') return gardesVides('indisponible', prevus);
  b.gctx ??= await essaiA(() => contexteGardes(lab), INDISPO);
  if (b.gctx.etat !== 'ok') return gardesVides('indisponible', prevus);
  const r = await essaiA(() => calculerGardes(lab, g, { ctx: b.gctx.ctx }), INDISPO);
  return { etat: r.etat, gardes: r.gardes || [], estGarde: r.estGarde || [], prevusIgnores: prevus };
}

// la tâche de fond : git seulement si la clé a changé ; le graphe seul qui change ne relance aucun git (les gardes réutilisent leur contexte)
async function rafraichir(lab, e, o, cle, carte, gsig) {
  let b = e.base;
  const loc = carte && Array.isArray(carte.g.files) ? carte.g.files : [];
  try {
    if (!b || b.cle !== cle) b = await lireBase(lab, cle, b, loc, o);
    const git = essai(() => sectionGit(b, loc), { ...INDISPO });
    const gardes = await sectionGardes(lab, b, carte);
    Object.assign(e, { base: b, git, gardes, cle, gsig, vers: e.vers + 1 });
  } catch {
    const panne = { cle, git: INDISPO, branches: INDISPO, arbres: SANS_ARBRES };
    Object.assign(e, { base: panne, git: { ...INDISPO }, gardes: gardesVides('indisponible'), cle, gsig, vers: e.vers + 1 });
  }
}

function demarrer(ctx, e, o, cle, carte, gsig) {
  e.enVol = true;
  const fin = () => { e.enVol = false; };
  monoVol(cleVol(ctx.root), () => rafraichir(ctx.root, e, o, cle, carte, gsig)).then(fin, fin);
}

// la part agents et plans, de l'instantané en mémoire : jamais « aucune collision » sans le dire quand la lecture est incomplète
function deriver(inst, e, carte, o) {
  const frise = inst && inst.frise, b = e.base;
  const voies = frise && Array.isArray(frise.voies) ? frise.voies : [];
  const attente = !frise || !b || (!!frise.source && frise.source.etat === 'en-construction');
  const fichiers = carte && Array.isArray(carte.g.files) ? carte.g.files : [];
  const cx = { maintenant: o.horloge(), cartes: new Set(fichiers.filter((f) => f && typeof f.p === 'string' && f.st !== 'prevu').map((f) => f.p)),
    libelleHorsLab: HORS, worktreesVerifies: b ? b.arbres.verifies : [], nomPrincipal: b ? b.arbres.principal : null,
    friseTronque: !!frise && frise.tronque === true, titres: new Map() };
  const lues = voies; // les cibles ENTIÈRES d'une voie dont la liste est coupée sont jointes normalement (P75-D-31)
  const nbCoupees = voies.slice(0, VOIES_MAX).filter((v) => v && v.cibles && v.cibles.tronque === true).length;
  const emp = attente ? videEmp('en-construction', ['en-construction'])
    : essai(() => ({ ...empreinte(lues, cx), voiesCiblesTronquees: nbCoupees }), videEmp('indisponible', []));
  const ag = attente ? { collisions: [], raisons: ['en-construction'] } : essai(() => collisionsAgents(lues, cx), null);
  const dossiers = inst && inst.projet && Array.isArray(inst.projet.files) ? inst.projet.files : [];
  const cp = essai(() => collisionsPlans(dossiers.filter((f) => f && typeof f.p === 'string' && f.p.endsWith('-PLAN.md') && Array.isArray(f.touched))), null);
  const br = b && b.branches.etat === 'ok' ? b.branches.collisions : [];
  const t = [...(ag ? ag.collisions : []), ...br.map(([c, n]) => [c, 'branches', n, null]), ...(cp ? cp.collisions : [])];
  t.sort((x, y) => cmp(x[0], y[0]) || RANG[x[1]] - RANG[y[1]] || cmp(String(x[3]), String(y[3])));
  const liste = t.slice(0, o.max);
  const raisons = [...(ag ? ag.raisons : ['agents-indisponible']), ...(cp ? [] : ['plans-indisponible']), ...(cp && cp.plansTronques ? ['plans-tronques'] : []),
    ...(b && b.branches.etat === 'indisponible' ? ['branches-indisponible'] : []), ...(t.length > liste.length ? ['collisions-tronquees'] : [])];
  return { at: new Date(o.horloge()).toISOString(), empreinte: emp, collisions: liste,
    radar: { incomplet: raisons.length > 0, raisons: [...new Set(raisons)], total: t.length, tronque: t.length > liste.length, sansVague: cp ? cp.sansVague : 0,
      plansTronques: !!cp && cp.plansTronques, limites: ['plans-comparaison-textuelle'] } };
}

function servir(ctx, e, o, inst, graceMs) {
  const carte = ctx.here ? lireGrapheCode(ctx.here, e.memoCode) : null;
  let cle = inst && inst.git && typeof inst.git.sig === 'string' ? inst.git.sig : null;
  if (cle !== null) e.nullDepuis = null;
  else if (inst) { e.nullDepuis ??= o.horloge(); if (o.horloge() - e.nullDepuis >= graceMs) cle = SANS_SIGNATURE; } // jamais de signature : un lab hors dépôt
  const gsig = carte ? carte.sig : null;
  const manque = cle !== null && (cle !== e.cle || gsig !== e.gsig);
  if (manque && !e.enVol) demarrer(ctx, e, o, cle, carte, gsig);
  const frais = e.der && e.der.inst === inst && e.der.vers === e.vers && e.der.gsig === gsig;
  const der = frais ? e.der : (e.der = { inst, vers: e.vers, gsig, ...deriver(inst, e, carte, o) });
  const b = e.base;
  return { schema: SCHEMA, at: der.at, etat: b ? 'ok' : 'en-calcul', calcul: manque || e.enVol || cle === null ? 'en-cours' : 'pret',
    git: b ? e.git : { ...LECTURE }, branches: b ? sectionBranches(b.branches) : { ...LECTURE }, gardes: b ? e.gardes : gardesVides('en-lecture'),
    empreinte: der.empreinte, collisions: der.collisions, radar: der.radar };
}

export function creerActivite({ binaire, horloge = Date.now, lireInstantane = instantane, graceMs = GRACE_MS, collisionsMax = COLLISIONS_MAX } = {}) {
  const o = { binaire, horloge, max: collisionsMax }, labs = new Map();
  return function activite(ctx) {
    try {
      let e = labs.get(ctx.root);
      if (!e) {
        e = { memoCode: {}, base: null, git: null, gardes: null, cle: null, gsig: null, enVol: false, vers: 0, nullDepuis: null, der: null };
        labs.set(ctx.root, e);
      }
      return servir(ctx, e, o, lireInstantane(), graceMs);
    } catch { return horsService(o); }
  };
}
export const activite = creerActivite();
export const routeActivite = (ctx) => activite(ctx);
