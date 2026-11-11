// vf-cockpit-lancer-mode — le mode de permission retenu au dernier lancement accepté, gardé d'une relance du cockpit à l'autre (Phase 72, plan 72-16 ; P72-D-02bis, P72-D-20, amendée par AUDC-B-05).
// Support (AUDC-B-05 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-11) : le dossier d'état DU POSTE, projet par projet, jamais le dossier du lab :
//   <base>/<clé>/terminal-mode, un mot, 0600, dossiers 0700. <base> = $VF_COCKPIT_MODE_DIR, sinon ${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/cockpit-mode (convention de
//   guard-health, update-check : cache du poste sous .../vibeflow/). <clé> = empreinte sha256 (32 premiers hexadécimaux) du chemin RÉEL de la racine du lab : jamais le chemin en clair,
//   et deux worktrees d'un même dépôt sont deux projets (deux chemins, chacun son cockpit) ; fusionner exigerait de lire un `.git` que le lab peut forger.
// Un lab reçu ne peut donc plus apporter de présélection : l'ancien <sortie>/.cache/terminal-mode n'est JAMAIS lu (aucune migration), ni retiré ; aucun chemin de code ne le nomme.
// Seul le processus de Q l'importe : jamais lu ni écrit par la page Projet, jamais transmis par l'IPC, ni clé ni chemin servis, journalisés ou envoyés.
// Lecture : une seule fois, à la création (valeur gardée en mémoire ensuite), durcie comme l'amorçage : dossiers à nous (ni lien, ni droits pour groupe ou autres), fichier ouvert sans suivre
// de lien ni bloquer, fstat sur le descripteur (ordinaire, propriétaire = le compte de Q, aucun droit pour groupe ni autres, 32 octets au plus), puis égalité à l'un des quatre mots ;
// tout le reste (dossier d'état absent, illisible, mal formé) vaut `default`. Jamais de repli vers le dossier du lab ; base et dossier du projet, jugés sur leur chemin réel, ne sont jamais sous la racine réelle du lab (ni égaux à elle) : sinon aucun support.
// Écriture : dossiers créés en 0700, fichier temporaire à création exclusive dans le MÊME dossier, puis rename (atomique) ; échec silencieux et sans chemin dans le journal.
// Limite dite (même rang que « poste mono-utilisateur ») : un renommage concurrent d'un dossier entre le jugement de confinement et la création ou l'ouverture n'est pas fermé (fenêtre résiduelle, acceptée, sans code) ; les jugements avant création et avant écriture limitent les dossiers créés sous le lab, mais la fenêtre après le dernier jugement reste ouverte, mot compris ; elle n'est ouverte qu'au même compte, et le lab ne relit jamais ce support.
// Exports : FICHIER_MODE, MODES, cleProjet(racine, { fs }), baseEtat({ env }), creerMemoireMode({ fichier, dossiers, fs, modes, os }), creerMemoireModePoste({ racine, env, fs, modes, os }) -> { lire(), ecrire(mode) }.
import nodeFs from 'node:fs';
import nodeOs from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { MODES } from './vf-cockpit-lancer-gabarit.mjs';

export { MODES };
export const FICHIER_MODE = 'terminal-mode';
const DEFAUT = 'default', MAX_OCTETS = 32;

/** Empreinte du projet : sha256 du chemin réel de la racine, 32 hexadécimaux ; null si la racine n'est pas résoluble. */
export function cleProjet(racine, { fs = nodeFs } = {}) {
  try { return crypto.createHash('sha256').update(fs.realpathSync(racine), 'utf8').digest('hex').slice(0, 32); } catch { return null; }
}

/** Dossier d'état du poste pour ce module (absolu) ; null si aucune base n'est déterminable. */
export function baseEtat({ env = process.env } = {}) {
  const surcharge = env.VF_COCKPIT_MODE_DIR;
  if (typeof surcharge === 'string' && surcharge !== '') return path.isAbsolute(surcharge) ? surcharge : null;
  const xdg = env.XDG_CACHE_HOME;
  let cache = typeof xdg === 'string' && path.isAbsolute(xdg) ? xdg : null;
  if (!cache) { let home = env.HOME; if (typeof home !== 'string' || !path.isAbsolute(home)) { try { home = nodeOs.homedir(); } catch { home = ''; } } cache = home && path.isAbsolute(home) ? path.join(home, '.cache') : null; }
  return cache ? path.join(cache, 'vibeflow', 'cockpit-mode') : null;
}

// 'ok' | 'absent' | 'ko' : un vrai dossier (ni lien, ni autre chose), à nous, sans droit pour groupe ni autres
function dossierSur(d, fs, os) {
  try { // garde:mode-dossier : O_NOFOLLOW ne couvre que le dernier composant du fichier ; chaque dossier d'état est donc contrôlé lui-même
    const ls = fs.lstatSync(d);
    if (ls.isSymbolicLink() || !ls.isDirectory()) return 'ko';
    if (typeof os.getuid === 'function' && (ls.uid !== os.getuid() || (ls.mode & 0o077) !== 0)) return 'ko';
    return 'ok';
  } catch (e) { return e && e.code === 'ENOENT' ? 'absent' : 'ko'; }
}

function charger(fichier, dossiers, fs, modes, os) {
  const c = fs.constants; let fd = null;
  try {
    if (!fichier || dossiers.some((d) => dossierSur(d, fs, os) !== 'ok')) return DEFAUT;
    const noFollow = c.O_NOFOLLOW || 0; // garde:mode-nofollow
    const nonBlock = c.O_NONBLOCK || 0; // garde:mode-nonblock
    fd = fs.openSync(fichier, c.O_RDONLY | noFollow | nonBlock);
    const st = fs.fstatSync(fd);
    if (!st.isFile()) return DEFAUT;
    if (typeof os.getuid === 'function' && st.uid !== os.getuid()) return DEFAUT; // garde:mode-uid
    if ((st.mode & 0o077) !== 0) return DEFAUT; // garde:mode-droits
    if (st.size > MAX_OCTETS) return DEFAUT; // garde:mode-taille
    const tampon = Buffer.alloc(MAX_OCTETS + 1), n = fs.readSync(fd, tampon, 0, tampon.length, 0);
    if (n > MAX_OCTETS) return DEFAUT;
    const txt = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }) /* garde:mode-bom */.decode(tampon.subarray(0, n));
    const mot = txt.endsWith('\n') ? txt.slice(0, -1) : txt;
    return modes.indexOf(mot) >= 0 ? mot : DEFAUT; // garde:mode-valide
  } catch { return DEFAUT; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } }
}

// `garde` : jugement de confinement rejoué avant toute création et avant l'écriture. `fichier` : le fichier du mot ; `dossiers` : les dossiers d'état à contrôler, du plus haut au plus bas (défaut : le dossier du fichier). Sans fichier : un support inutilisable (lit default, n'écrit rien).
export function creerMemoireMode({ fichier, dossiers, garde, fs = nodeFs, modes = MODES, os = process } = {}) {
  const dirs = dossiers || (fichier ? [path.dirname(fichier)] : []);
  let memoire = charger(fichier, dirs, fs, modes, os);
  const ecrire = (mode) => {
    if (typeof mode !== 'string' || modes.indexOf(mode) < 0) return false;
    memoire = mode;
    if (!fichier) return false;
    const dossier = path.dirname(fichier), tmp = path.join(dossier, `${FICHIER_MODE}.${process.pid}.${crypto.randomBytes(8).toString('hex')}.tmp`);
    if (garde && !garde()) return false; // garde:mode-jugement-1 : premier jugement, avant toute création de dossier
    if (dirs.some((d) => dossierSur(d, fs, os) === 'ko')) return false;
    let fd = null;
    try {
      for (const d of dirs) fs.mkdirSync(d, { recursive: true, mode: 0o700 });
      if (garde && !garde()) return false; // garde:mode-rejuge : nouveau jugement une fois les dossiers créés, avant toute écriture
      if (dirs.some((d) => dossierSur(d, fs, os) !== 'ok')) return false;
      fd = fs.openSync(tmp, 'wx', 0o600);
      fs.writeSync(fd, mode + '\n'); fs.fsyncSync(fd); fs.closeSync(fd); fd = null;
      fs.renameSync(tmp, fichier); // garde:mode-rename
      return true;
    } catch {
      if (fd !== null) { try { fs.closeSync(fd); } catch {} }
      try { fs.unlinkSync(tmp); } catch {} // garde:mode-unlink
      console.error('vf-cockpit (terminal) : le mode retenu n\'a pas pu être enregistré.'); // message constant : ni valeur, ni clé, ni chemin du poste
      return false;
    }
  };
  return { lire: () => memoire, ecrire };
}

// Confinement jugé par IDENTITÉ (dev, ino), jamais par une forme textuelle (casse, normalisation Unicode, `.`, `..`, liens : un système de fichiers les rend équivalentes sans que le texte le dise).
// Vrai si ni le plus proche ancêtre existant du chemin, ni aucun de ses ancêtres (suite textuelle ET suite du chemin résolu par le système) n'a l'identité de la racine du lab. Toute erreur de stat : faux (aucun support).
function horsDuLab(chemin, racine, fs) {
  try {
    const rid = fs.statSync(racine, { bigint: true }); let e = path.resolve(chemin);
    for (;;) { try { fs.statSync(e, { bigint: true }); break; } catch (x) { const haut = path.dirname(e); if (haut === e || !x || x.code !== 'ENOENT') return false; e = haut; } }
    const resolu = (fs.realpathSync.native || fs.realpathSync)(e);
    for (const depart of [e, resolu]) {
      for (let p = depart; ; p = path.dirname(p)) {
        const st = fs.statSync(p, { bigint: true });
        if (st.dev === rid.dev && st.ino === rid.ino) return false; // garde:mode-identite
        if (path.dirname(p) === p) break;
      }
    }
    return true;
  } catch { return false; }
}

// Le support du poste pour la racine d'un lab : <base>/<clé>/terminal-mode. Base ou clé introuvables : support inutilisable (default, aucune écriture), jamais le dossier du lab.
export function creerMemoireModePoste({ racine, env = process.env, fs = nodeFs, modes = MODES, os = process } = {}) {
  const brute = baseEtat({ env }), cle = cleProjet(racine, { fs });
  if (!brute || !cle) return creerMemoireMode({ fichier: null, fs, modes, os });
  const base = path.resolve(brute), dossier = path.join(base, cle); // forme normalisée : celle qui est jugée est celle qui est utilisée
  const garde = () => horsDuLab(base, racine, fs) && horsDuLab(dossier, racine, fs); // garde:mode-confinement : jamais sous la racine du lab (ni égale), jugé par identité
  if (!garde()) return creerMemoireMode({ fichier: null, fs, modes, os });
  return creerMemoireMode({ fichier: path.join(dossier, FICHIER_MODE), dossiers: [base, dossier], garde, fs, modes, os });
}
