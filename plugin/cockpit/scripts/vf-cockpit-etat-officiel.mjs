// vf-cockpit-etat-officiel — l'état des sessions vivantes tel que Claude Code le publie (`claude agents --json`), en ENRICHISSEMENT OPTIONNEL (AUDC-V8).
// Jamais la source unique : commande absente, en échec, trop lente, ou de forme inattendue -> la carte reste null et le cockpit garde sa lecture des transcripts.
// Exports : lire(home) -> Map identifiant de session -> { etat } | null (synchrone, jamais d'attente) ; rafraichir({ home, cwd }) -> Promise<Map | null> (une commande à la fois, bornée) ;
//           demander({ home, cwd }) -> declenche un rafraichir() en arrière-plan au plus toutes les REPIT_MS ; formeEtats(json, CC) -> Map | null (la forme vient du contrat, bloc claudeCode.vueAgents).
// Aucun réseau (la commande est locale), aucun shell (execFile), ni `~/.claude/sessions` ni le registre du démon ne sont lus (AUDC-V10). Seuls l'identifiant de session et un état fermé sortent.
import { execFile } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ID_RE } from './vf-cockpit-lecture.mjs';
import { envEnfant } from './vf-cockpit-env.mjs';
import os from 'node:os';
import { nettoie } from './vf-cockpit-arbres.mjs';

export const REPIT_MS = 10000; // au plus une commande toutes les 10 s
export const VALIDITE_MS = 60000; // une lecture plus vieille que 60 s n'est plus rendue : retour à la lecture des transcripts
const DELAI_MS = 5000, MAX_OCTETS = 1 << 20;
const HERE = path.dirname(fileURLToPath(import.meta.url));
let CONTRAT = null;
const contrat = () => { if (CONTRAT === null) { try { CONTRAT = JSON.parse(fs.readFileSync(path.join(HERE, 'vf-cockpit-interface.json'), 'utf8'))?.claudeCode?.vueAgents || {}; } catch { CONTRAT = {}; } } return CONTRAT; };

// états de notre onglet : occupée, vous attend, au repos, close. `state` (working, blocked, done, failed, stopped) prime sur `status` (busy, waiting, idle) quand il dit « fini » ou « bloqué »
export function formeEtats(json, CC = contrat()) {
  if (!Array.isArray(json) || !CC.cleSession) return null;
  const etats = CC.etats || {}, statuts = CC.statuts || {}, out = new Map();
  for (const e of json) {
    if (!e || typeof e !== 'object' || typeof e[CC.cleSession] !== 'string' || !ID_RE.test(e[CC.cleSession])) return null; // une entrée illisible rend TOUTE la liste illisible (dérive de format) : jamais une session vivante prise pour absente
    const st = typeof e.state === 'string' && Object.hasOwn(etats, e.state) ? etats[e.state] : null;
    const su = typeof e.status === 'string' && Object.hasOwn(statuts, e.status) ? statuts[e.status] : null;
    const etat = st === 'termine' || st === 'attend' ? st : su || st;
    const avant = out.get(e[CC.cleSession]);
    if (avant && avant.etat !== 'termine' && etat === 'termine') continue; // AUDC-D2 : un état vivant listé pour cet identifiant n'est jamais écrasé par « termine », quel que soit l'ordre
    // A20 : seul `termine` porte un motif (`failed`, `stopped`), lu du contrat (`motifs`)
    const motif = etat === 'termine' && typeof e.state === 'string' && Object.hasOwn(CC.motifs || {}, e.state) && typeof CC.motifs[e.state] === 'string' ? CC.motifs[e.state] : null;
    out.set(e[CC.cleSession], { etat: etat || null, ...(motif ? { motif } : {}) }); // une session listée d'état inconnu est VIVANTE : présente, sans état
  }
  return out;
}

const caches = new Map(); // home -> { at, carte, enCours, dernier }
const cache = (home) => { let c = caches.get(home); if (!c) { c = { at: 0, carte: null, enCours: null, dernier: 0 }; caches.set(home, c); } return c; };

export function lire(home, now = Date.now()) { const c = caches.get(home); return c && c.carte && now - c.at < VALIDITE_MS ? c.carte : null; }

export function rafraichir({ home, cwd, commande = 'claude' } = {}) {
  const c = cache(home);
  if (c.enCours) return c.enCours;
  c.dernier = Date.now();
  c.enCours = new Promise((resolve) => {
    let fini = false;
    const clos = (carte) => { if (fini) return; fini = true; c.enCours = null; if (carte) { c.carte = carte; c.at = Date.now(); } else c.carte = null; resolve(carte); };
    try {
      execFile(commande, ['agents', '--json'], { cwd, env: { ...envEnfant(cwd), HOME: home } /* PATH assaini : jamais un `claude` posé dans le lab (audit H-1) */, timeout: DELAI_MS, maxBuffer: MAX_OCTETS, windowsHide: true }, (err, out) => {
        if (err) return clos(null);
        let j = null; try { j = JSON.parse(String(out)); } catch {}
        const carte = formeEtats(j); c.attendent = carte ? dossiersEnAttente(j, carte) : null; clos(carte); // 73-02
      });
    } catch { clos(null); }
  });
  return c.enCours;
}

export function demander({ home, cwd, now = Date.now() } = {}) {
  const c = cache(home);
  if (c.enCours || now - c.dernier < REPIT_MS) return;
  rafraichir({ home, cwd }).catch(() => {});
}

// ---- 73-02 : « ailleurs sur ce poste » (REGI-13, P73-D-16) ----
// ailleurs(home, { racines, now, homeDir }) -> [{ lab, n }] | null : combien de sessions à l'état « vous attend » ont leur dossier
//   HORS des arbres du lab (racines), groupées par NOM de lab. Ni chemin, ni identifiant, ni titre ne sort : les dossiers vivent dans
//   la mémoire privée de la dernière lecture (c.attendent), jamais exportée. Aucune commande, aucun git, aucun fichier lu ici.
//   null (jamais 0) : pas de lecture officielle fraîche (60 s), liste illisible, racines inconnues. Nom du lab : dernier segment,
//   suffixe /.claude/worktrees/<n> retiré, nettoyé, borné à 40 ; dossier personnel, un de ses ancêtres ou chemin de moins de
//   deux segments : « un autre dossier » (hypothèse A7).
const AUTRE = 'un autre dossier', SUFFIXE_ARBRE = /[\\/]\.claude[\\/]worktrees[\\/][^\\/]+(?:[\\/].*)?$/;
const dessous = (racine, p) => {
  const r = path.relative(racine, p);
  return r === '' || (r !== '..' && !r.startsWith('..' + path.sep) && !path.isAbsolute(r));
};
// chemin réel quand il se résout ; sinon l'ancêtre existant le plus proche résolu, suivi du reste (un dossier supprimé reste comparable)
function reelOuResolu(p) {
  const abs = path.resolve(p);
  try { return fs.realpathSync(abs); } catch { const haut = path.dirname(abs); return haut === abs ? abs : path.join(reelOuResolu(haut), path.basename(abs)); }
}
function nomDuLab(d, hd) {
  const base = d.replace(SUFFIXE_ARBRE, '');
  if (dessous(base, hd)) return AUTRE;
  const segs = base.split(/[\\/]/).filter(Boolean);
  if (segs.length < 2) return AUTRE;
  return nettoie(segs[segs.length - 1], 40) || AUTRE;
}
// les dossiers des sessions qui attendent (une fois par identifiant) ; une session en attente sans dossier lisible rend le compte inconnu (null)
function dossiersEnAttente(json, carte) {
  const CC = contrat(), vus = new Set(), out = [];
  for (const e of json) {
    const id = e[CC.cleSession];
    if (vus.has(id) || !carte.get(id) || carte.get(id).etat !== 'attend') continue;
    vus.add(id);
    if (typeof e.cwd !== 'string' || !e.cwd) return null;
    out.push(e.cwd);
  }
  return out;
}
export function ailleurs(home, { racines, now = Date.now(), homeDir = os.homedir() } = {}) {
  const c = caches.get(home);
  if (!c || !c.carte || now - c.at >= VALIDITE_MS || !Array.isArray(c.attendent) || !Array.isArray(racines)) return null;
  const rs = racines.filter((r) => typeof r === 'string' && r).map(reelOuResolu);
  if (!rs.length) return null;
  const hd = reelOuResolu(homeDir), lignes = new Map();
  for (const cwd of c.attendent) {
    const d = reelOuResolu(cwd);
    if (path.isAbsolute(cwd) && rs.some((r) => dessous(r, d))) continue;
    const lab = nomDuLab(d, hd);
    const l = lignes.get(lab) || { lab, n: 0 };
    l.n++; lignes.set(lab, l);
  }
  return [...lignes.values()].sort((x, y) => y.n - x.n || (x.lab < y.lab ? -1 : x.lab > y.lab ? 1 : 0));
}
