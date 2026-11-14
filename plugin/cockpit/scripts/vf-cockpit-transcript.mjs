// vf-cockpit-transcript — dernière action lisible, citations du mandat et réducteur de transcript à liste blanche (P69-D-16, P69-D-19, P69-D-23).
// Exports : VERBES (table fermée), etiquette(name, input, root) -> { outil, verbe, cible }, derniereAction(fichier, root) -> { verbe, cible } | null,
//           citationsDuMandat(texte) -> [identifiant], reduireTranscript(fichier, { root, roles, kind }) -> { mandat, fil, tronque } (fil : [{ t, genre: 'message', texte } | { t, genre: 'outil', outil, verbe, cible, n?, echec? }]),
//           CLES_LUES (clés lues d'un résultat d'outil : tool_use.id, tool_use_id, is_error)
// Lecture seule, aucun réseau ; liste blanche ; aucune valeur d'entrée d'outil ne sort hors de la cible réduite (chemin du lab, hôte, type d'agent, nom de skill ou de serveur).
import fs from 'node:fs';
import { cherche, masqueCoupe, MARGE_MASQUE } from './vf-cockpit-lecture.mjs';
import { fin, reduireCible, racinesDeComparaison, arbreDeNom, HORS } from './vf-cockpit-cible.mjs';
import { arbresGit } from './vf-cockpit-arbres.mjs';

// libellés provisoires (P69-PL-19) : à valider avant la publication
export const VERBES = Object.freeze(Object.assign(Object.create(null), {
  Read: 'lit', Write: 'modifie', Edit: 'modifie', MultiEdit: 'modifie', NotebookEdit: 'modifie', Grep: 'cherche dans', Glob: 'cherche dans',
  Bash: 'lance une commande', bash: 'lance une commande', Agent: 'lance un agent', Task: 'lance un agent', SendMessage: 'écrit à',
  WebFetch: 'consulte une page', WebSearch: 'cherche sur le web', Skill: 'utilise le skill',
}));
// clés lues d'un résultat d'outil (P74-D-48) : l'identifiant d'appel et le drapeau d'erreur, jamais le contenu ;
// un ajout est un écart au plan 74-09 (B1)
export const CLES_LUES = Object.freeze(['tool_use.id', 'tool_use_id', 'is_error']);
const VERBE_MCP = 'utilise', VERBE_AUTRE = 'utilise un outil';
const BORNE_MANDAT = 8000, MAX_MESSAGES = 50, BORNE_MESSAGE = 2000, MAX_OUTILS = 200, TETE = 256 << 10, QUEUE = 8 << 20;

// un texte coupé à la borne le dit : la mention vient APRÈS la coupe (masqueCoupe reste la seule voie de coupe, le masque passe avant), avec la borne réelle, jamais écrite en dur
const milliers = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
const coupe = (t, n) => { const r = masqueCoupe(t, n); return t.length > n ? `${r} … (tronqué, ${milliers(n)} caractères)` : r; };
const chaine = (v) => (typeof v === 'string' ? v : '');

// chemin relatif au lab par la règle UNIQUE de vf-cockpit-cible.mjs (résolution physique, échec = hors du lab, A23) ; la cible d'un worktree
// prouvé du dépôt s'écrit `<chemin relatif> (worktree <nom>)` : le suffixe s'ajoute APRÈS la borne d'affichage et n'est pas compté dedans (A48-44)
function ciblePrincipale(valeur, root, arbres) {
  const v = chaine(valeur);
  if (!v || !root) return { cible: v ? HORS : '', suffixe: '' };
  const table = arbres || racinesDeComparaison(root), r = reduireCible(v, table, arbreDeNom(table, null));
  return r === null ? { cible: '', suffixe: '' } : { cible: r.cible, suffixe: r.arbre === null ? '' : ` (worktree ${r.arbre})` };
}

// roles : Map identifiant d'agent -> rôle, tirée de la COLLECTE (registre, meta.json) et jamais du texte de l'entrée ; sans elle (ou destinataire inconnu) la cible d'un message est « un agent »
export function etiquette(name, input, root, roles, arbres) {
  const outil = fin(name) || '?'; const i = input && typeof input === 'object' ? input : {};
  const n = chaine(name);
  let verbe, cible = '', suffixe = '';
  if (n.startsWith('mcp__')) { verbe = VERBE_MCP; cible = n.split('__')[1] || ''; }
  else if (n in VERBES) {
    verbe = VERBES[n];
    if (['Read', 'Write', 'Edit', 'MultiEdit', 'NotebookEdit'].includes(n)) {
      ({ cible, suffixe } = ciblePrincipale(i.file_path ?? i.notebook_path ?? i.path, root, arbres));
    }
    else if (n === 'Grep' || n === 'Glob') ({ cible, suffixe } = ciblePrincipale(i.path ?? i.file_path, root, arbres));
    else if (n === 'Agent' || n === 'Task') cible = chaine(i.subagent_type);
    else if (n === 'SendMessage') cible = roles instanceof Map && roles.has(chaine(i.to)) ? chaine(roles.get(chaine(i.to))) : 'un agent'; // jamais l'identifiant brut (Q2a)
    else if (n === 'Skill') cible = chaine(i.skill);
    else if (n === 'WebFetch') { try { cible = new URL(chaine(i.url)).hostname; } catch { cible = ''; } }
  } else verbe = VERBE_AUTRE;
  return { outil, verbe, cible: fin(cible) + suffixe };
}

// dernière action : le dernier bloc tool_use d'une ligne assistant, en remontant le transcript
export function derniereAction(fichier, root) {
  return cherche(fichier, (d) => {
    const c = d.type === 'assistant' ? d.message?.content : null; if (!Array.isArray(c)) return null;
    for (let k = c.length - 1; k >= 0; k--) if (c[k]?.type === 'tool_use' && typeof c[k].name === 'string') { const e = etiquette(c[k].name, c[k].input, root); const a = { verbe: e.verbe, cible: e.cible }; if (c[k].name === 'SendMessage' && typeof c[k].input?.to === 'string') a._to = c[k].input.to.slice(0, 128); return a; } // _to : destinataire brut, résolu en rôle par la collecte puis retiré (jamais émis)
    return null;
  });
}

// citations du mandat : motifs fixes (jamais construits depuis le lab) ; « nœud `id` » (toute casse, deux-points facultatif) ou `--node=id`
const CITATION = /n(?:[œŒ]|oe|OE)ud\s{0,8}:?\s{0,8}`([A-Za-z0-9][A-Za-z0-9._-]{0,63})`/gi;
const CITATION_OPT = /--node=([A-Za-z0-9][A-Za-z0-9._-]{0,63})/g;
export function citationsDuMandat(texte) {
  const t = chaine(texte).slice(0, 8000), ids = new Set();
  for (const re of [CITATION, CITATION_OPT]) { re.lastIndex = 0; let m; while ((m = re.exec(t))) ids.add(m[1]); }
  return [...ids];
}

// lecture d'une fenêtre : { texte, coupe } ; `fin` = depuis la fin du fichier, sinon depuis le début
function fenetre(fichier, octets, depuisLaFin) {
  let fd = null;
  try {
    if (!fs.statSync(fichier).isFile()) return null; // un tube (FIFO) bloquerait l'ouverture
    fd = fs.openSync(fichier, 'r'); const size = fs.fstatSync(fd).size, len = Math.min(size, octets), buf = Buffer.alloc(len);
    fs.readSync(fd, buf, 0, len, depuisLaFin ? size - len : 0);
    return { texte: buf.toString('utf8'), coupe: size > len };
  } catch { return null; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } }
}
const json = (l) => { try { return JSON.parse(l); } catch { return null; } };

// liste blanche : mandat (agent seulement : kind 'session' n'en a pas) = contenu chaîne de la première ligne `user` ; fil = les blocs `text` des lignes `assistant` et le nom et la cible réduite des blocs `tool_use`, UN seul tableau
// dans l'ordre du fichier, chaque ligne avec son heure (AUDC-D8). Tout le reste (lignes user ultérieures, api-request*, attachment, blocs thinking et tool_result, champ des résultats d'outils) n'est jamais lu.
// Le coût est borné par ce qui sort (F4) : la fenêtre n'est qu'analysée ; masque et étiquette (donc realpath) ne s'appliquent qu'aux 50 messages et 200 outils gardés.
// PU-G-170 : des appels consécutifs du fil de même étiquette (même outil, même verbe, même cible) ne font plus qu'une entrée, avec leur nombre `n` (absent pour un appel seul) et l'heure du premier ; un appel en échec (`echec: true`, P74-D-48) ne se regroupe jamais avec des réussites ; le regroupement ne lit que l'étiquette déjà réduite, jamais une valeur d'entrée (liste blanche inchangée)
const regrouper = (fil) => fil.reduce((acc, e) => { const d = acc[acc.length - 1]; if (d && d.genre === 'outil' && e.genre === 'outil' && d.outil === e.outil && d.verbe === e.verbe && d.cible === e.cible && d.echec === e.echec) d.n = (d.n || 1) + 1; else acc.push({ ...e }); return acc; }, []);
// l'heure d'une ligne : l'horodatage du transcript, relu comme une date et rendu en ISO 8601 ; jamais la chaîne du fichier telle quelle
const heure = (v) => { if (typeof v !== 'string') return null; const ms = Date.parse(v); return Number.isFinite(ms) ? new Date(ms).toISOString() : null; };
export function reduireTranscript(fichier, { root, roles, kind } = {}) {
  try { return reduire(fichier, root, roles, kind); } catch { return { mandat: '', fil: [], tronque: true }; } // aucune exception ne remonte à l'appelant
}
function reduire(fichier, root, roles, kind) {
  let tronque = false, mandat = '';
  const tete = kind === 'session' ? null : fenetre(fichier, TETE, false); // AUDC-D7 : une session n'a pas de mandat (sa première ligne est ce que l'utilisateur a tapé) ; celui d'un agent est son dispatch, première ligne de son transcript
  if (tete?.coupe && !tete.texte.includes('\n')) tronque = true; // la première ligne dépasse la fenêtre de tête : le mandat est illisible
  if (tete) { const p = json(tete.texte.split('\n')[0]); if (p?.type === 'user' && typeof p.message?.content === 'string') { const c = p.message.content; if (c.length > BORNE_MANDAT) tronque = true; mandat = coupe(c, BORNE_MANDAT); } }
  const q = fenetre(fichier, QUEUE, true);
  if (!q) return { mandat, fil: [], tronque };
  const lignes = q.texte.split('\n'); if (q.coupe) { lignes.shift(); tronque = true; } // la première ligne de la fenêtre est coupée
  let msgs = [], outs = [], seq = 0, table; // table : les arbres prouvés du dépôt, calculés UNE fois par appel et seulement si un outil est gardé
  const arbres = () => (table ??= (() => { // les arbres prouvés du dépôt ; échec : l'arbre principal seul
    try { return racinesDeComparaison(root, arbresGit(root)); } catch { return root ? racinesDeComparaison(root) : undefined; }
  })());
  // identifiant d'appel -> entrée d'outil : interne, borné à `outs`, jamais émis (P69-D-16) ; porté par deux appels, il désigne le plus récent
  const ids = new Map();
  const purge = () => { const vivants = new Set(outs); for (const [k, o] of ids) if (!vivants.has(o)) ids.delete(k); };
  for (const l of lignes) {
    if (!l.trim()) continue;
    const assist = l.includes('"assistant"'), echec = l.includes('"is_error":true') || l.includes('"is_error": true');
    if (!assist && !echec) continue; // écarte sans analyser les lignes d'une autre sorte (une ligne user sans drapeau vrai n'est jamais analysée)
    const d = json(l); if (!d) continue;
    const c = typeof d.message?.content === 'string' ? [{ type: 'text', text: d.message.content }] : d.message?.content; if (!Array.isArray(c)) continue;
    const t = heure(d.timestamp);
    if (d.type === 'user') { // résultats d'outil : seuls tool_use_id et le booléen is_error strictement vrai sont lus, jamais le contenu (P74-D-48, P69-D-19)
      if (echec) for (const b of c) {
        if (b?.type === 'tool_result' && b.is_error === true && typeof b.tool_use_id === 'string') { const o = ids.get(b.tool_use_id); if (o) o.e = true; }
      }
      continue;
    }
    if (d.type !== 'assistant') continue;
    for (const b of c) {
      if (b?.type === 'text' && typeof b.text === 'string' && b.text.trim()) msgs.push({ s: seq++, t, x: b.text.slice(0, BORNE_MESSAGE + MARGE_MASQUE) });
      else if (b?.type === 'tool_use' && typeof b.name === 'string') {
        const o = { s: seq++, t, n: b.name, i: b.input, e: false }; outs.push(o); if (typeof b.id === 'string') ids.set(b.id, o);
      }
    }
    if (msgs.length > 2 * MAX_MESSAGES) { msgs = msgs.slice(-MAX_MESSAGES); tronque = true; }
    if (outs.length > 2 * MAX_OUTILS) { outs = outs.slice(-MAX_OUTILS); tronque = true; purge(); }
  }
  if (msgs.length > MAX_MESSAGES) { msgs = msgs.slice(-MAX_MESSAGES); tronque = true; }
  if (outs.length > MAX_OUTILS) { outs = outs.slice(-MAX_OUTILS); tronque = true; purge(); }
  if (msgs.some((m) => m.x.length > BORNE_MESSAGE)) tronque = true;
  const fil = [...msgs.map((m) => ({ s: m.s, e: { t: m.t, genre: 'message', texte: coupe(m.x, BORNE_MESSAGE) } })),
    ...outs.map((o) => ({ s: o.s, e: { t: o.t, genre: 'outil', ...etiquette(o.n, o.i, root, roles, arbres()),
      ...(o.e ? { echec: true } : {}) } }))].sort((a, b) => a.s - b.s).map((x) => x.e);
  return { mandat, fil: regrouper(fil), tronque };
}
