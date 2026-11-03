// vf-cockpit-lecture — lecteurs bas niveau partagés du socle du cockpit (déplacés de vf-cockpit-who.mjs, comportement inchangé).
// Exports : ls, mtime, readJson, cherche (recherche en fin de fichier), masque / MAX_MASQUE (masques de secrets), ID_RE, premiereLigne.
// Lecture seule, aucun réseau.
import fs from 'node:fs';

export const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
export const mtime = (f) => { try { return fs.statSync(f).mtimeMs; } catch { return 0; } };
// `max` (octets) : au-delà, le fichier n'est pas lu (null) — un meta.json de 300 Mio ne doit pas peser sur la mémoire (F4)
export const readJson = (f, max = Infinity) => { try { if (max !== Infinity && fs.statSync(f).size > max) return null; return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return null; } };

// recherche en partant de la fin d'un jsonl, sur des fenêtres de plus en plus larges (256 Kio, 2 Mio, 8 Mio) : `accepte(ligne)` rend la valeur
// cherchée ou null. Une ligne plus longue que la fenêtre (un gros résultat d'outil) est ignorée au lieu de faire croire qu'il n'y a rien :
// c'était la cause d'une session très active absente du badge « au travail » ou sans dernière commande (E-5).
const FENETRES = [256 << 10, 2 << 20, 8 << 20];
export const cherche = (f, accepte) => {
  for (const bytes of FENETRES) {
    let fd = null, size = 0, lignes = [];
    try {
      if (!fs.statSync(f).isFile()) return null; // un tube (FIFO) bloquerait l'ouverture
      fd = fs.openSync(f, 'r'); size = fs.fstatSync(fd).size; const len = Math.min(size, bytes);
      const buf = Buffer.alloc(len); fs.readSync(fd, buf, 0, len, size - len);
      lignes = buf.toString('utf8').split('\n'); if (size > len) lignes.shift(); // la première ligne de la fenêtre est coupée
    } catch { return null; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } } // le descripteur se ferme aussi quand readSync lève
    for (const l of lignes.reverse()) {
      if (!l.trim()) continue;
      let d; try { d = JSON.parse(l); } catch { continue; }
      const r = d && accepte(d); if (r) return r;
    }
    if (size <= bytes) break;
  }
  return null;
};

// Ces masques restent le filet de ce qui est affiché (un premier argument peut être une URL à identifiants ou un jeton nu) ET de task/cwd/role (texte libre écrit par d'autres, voir `bornes`).
const MASQUES = [
  /\bgh[pousr]_[A-Za-z0-9]{20,}/g, /\bgithub_pat_[A-Za-z0-9_]{20,}/g, /\bsk-[A-Za-z0-9_-]{16,}/g, /\bAKIA[A-Z0-9]{16}/g, /\bxox[baprs]-[A-Za-z0-9-]+/g,
  /\bBearer\s+[A-Za-z0-9._~+\/=-]{16,}/gi,
  // un nom de variable ou de clé qui finit par un mot sensible (GITHUB_TOKEN=, AWS_SECRET_ACCESS_KEY=, API_KEY=) : `\b` ne coupe pas après `_`, d'où `[A-Za-z0-9_]*`
  /[A-Za-z0-9_]{0,64}(?:password|passwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credential)[A-Za-z0-9_]{0,64}=\S+/gi,
  /--(?:password|passwd|secret|token|api[_-]?key)(?:=|\s+)\S+/gi, /\bX-Api-Key:\s*\S+/gi,
  // F-1 (revue de D3) : identifiants d'une commande Bash hors « NOM=valeur ». Tous les quantificateurs sont bornés (pas de retour quadratique) ; le contexte est en lookbehind,
  // seule la valeur secrète est remplacée. Les `export FOO=valeur` génériques ne sont pas masqués par ces règles : seuls les noms sensibles le sont (règle plus haut).
  // `mysql -pXXX` et `sshpass -p XXX` : la dernière commande ne les affiche plus (option en « - »), mais task/cwd/role (`bornes`) les diffusent encore, d'où leur maintien.
  /(?<=\b(?:mysql|mysqladmin|mysqldump|mariadb)\b[^|;&\n]{0,100}\s-p)\S+/g, // mysql -pMotDePasse (collé) ; « -p » seul = invite, intact
  /(?<=\bsshpass\s{1,5}-p\s{0,3})\S+/g, // sshpass -p <mot de passe>
  /(?<=:\/\/)[^\s:@\/]{1,128}:[^\s@\/]{1,256}(?=@)/g, // scheme://user:pass@hôte
  /(?<=(?:^|\s)(?:-u|--user)[ =]{0,3})[^\s:]{1,128}:\S+/g, // curl -u user:pass, --user=user:pass (« -u root » seul n'a pas de « : »)
  /\bAuthorization:\s{0,8}(?:Digest\s[^'\n]{1,300}|(?:[A-Za-z]{1,20}\s{1,8})?[^\s"']+)/gi, // en-tête Authorization, tout schéma (Basic, Bearer, Token, Digest…)
];
// l'entrée est bornée AVANT les masques (les sorties sont tronquées à 200 car. au plus pour task/cwd/role, à 80 pour la dernière commande) : le nom de variable sensible est en {0,64} et l'entrée en MAX_MASQUE,
// sinon un mot de 100 Kio rendait le masque quadratique (17 s)
export const MAX_MASQUE = 4000;
export const masque = (t, max = MAX_MASQUE) => MASQUES.reduce((a, re) => a.replace(re, '[masqué]'), String(t).slice(0, max));
// F1 : masquer AVANT de couper. La tranche masquée dépasse la borne d'une marge (plus longue que le plus long secret reconnu, ~600 car.), la coupe vient après :
// un jeton à cheval sur la borne est remplacé en entier, jamais rendu en fragment. Le coût reste borné (borne + marge).
export const MARGE_MASQUE = 700;
export const masqueCoupe = (t, n) => masque(t, n + MARGE_MASQUE).slice(0, n);
export const ID_RE = /^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/;

// première ligne d'un jsonl (256 premiers Kio), analysée en JSON ; null si illisible. Cache par chemin, borné : vidé au-delà de 4 000 entrées.
const CACHE = new Map();
export const premiereLigne = (f) => {
  if (CACHE.has(f)) return CACHE.get(f);
  let fd = null, r = null;
  try {
    if (!fs.statSync(f).isFile()) throw new Error('pas un fichier');
    fd = fs.openSync(f, 'r'); const buf = Buffer.alloc(256 << 10); const n = fs.readSync(fd, buf, 0, buf.length, 0);
    const ligne = buf.toString('utf8', 0, n).split('\n')[0];
    r = JSON.parse(ligne);
  } catch { r = null; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } }
  if (CACHE.size >= 4000) CACHE.clear();
  CACHE.set(f, r);
  return r;
};
