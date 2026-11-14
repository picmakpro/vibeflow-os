// vf-cockpit-lecture — lecteurs bas niveau partagés du socle du cockpit (déplacés de vf-cockpit-who.mjs, comportement inchangé).
// Exports : ls, mtime, readJson, cherche (recherche en fin de fichier), titreSession (nom /rename d'une session), masque / MAX_MASQUE (masques de secrets), masqueCoupe / MARGE_MASQUE (masquer avant de couper), ID_RE, premiereLigne.
// Lecture seule, aucun réseau.
import fs from 'node:fs';

export const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
export const mtime = (f) => { try { return fs.statSync(f).mtimeMs; } catch { return 0; } };
// `max` (octets) : au-delà, le fichier n'est pas lu (null) — un meta.json de 300 Mio ne doit pas peser sur la mémoire (F4)
export const readJson = (f, max = Infinity) => { try { const st = fs.statSync(f); if (!st.isFile() || st.size > max) return null; return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return null; } };

// recherche en partant de la fin d'un jsonl, sur des fenêtres de plus en plus larges (256 Kio, 2 Mio, 8 Mio) : `accepte(ligne)` rend la valeur
// cherchée ou null. Une ligne plus longue que la fenêtre (un gros résultat d'outil) est ignorée au lieu de faire croire qu'il n'y a rien :
// c'était la cause d'une session très active absente du badge « au travail » ou sans dernière commande (E-5).
const FENETRES = [256 << 10, 2 << 20, 8 << 20];
// `fenetres` : liste des fenêtres essayées (défaut : les trois) ; `[FENETRES[0]]` = une seule lecture de 256 Kio, sans escalade.
// `etat` (optionnel) : objet où `etat.erreur = true` signale un échec de lecture (distinct de « rien trouvé »).
export const cherche = (f, accepte, fenetres = FENETRES, etat = null) => {
  for (const bytes of fenetres) {
    let fd = null, size = 0, lignes = [];
    try {
      if (!fs.statSync(f).isFile()) return null; // un tube (FIFO) bloquerait l'ouverture
      fd = fs.openSync(f, 'r'); size = fs.fstatSync(fd).size; const len = Math.min(size, bytes);
      const buf = Buffer.alloc(len); fs.readSync(fd, buf, 0, len, size - len);
      lignes = buf.toString('utf8').split('\n'); if (size > len) lignes.shift(); // la première ligne de la fenêtre est coupée
    } catch { if (etat) etat.erreur = true; return null; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } } // le descripteur se ferme aussi quand readSync lève
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
// Jetons à format reconnu : le PRÉFIXE et le CORPS portent la reconnaissance, pas la frontière de mot. `\b` ne coupe ni après `_` ni entre un chiffre et une lettre : un jeton collé
// à un mot (`xxxghp_…`, `key_sk-…`, `1ghp_…`) y échappait. Règle par motif (preuve : test-cockpit-who.sh W24, jeu négatif de noms réels du dépôt) :
//  - `ghp_`, `github_pat_`, `AKIA`, `xoxb-` : préfixe assez rare et corps long ou typé, aucune frontière (un mot ordinaire ne les porte pas) ;
//  - `sk-` : « ask- », « task- », « desk- », « risk- » sont des mots ; une lettre juste avant exige donc la forme réelle d'une clé (corps de 40 caractères, une majuscule et un chiffre,
//    `proj-`/`ant-`… ou 40 alphanumériques d'un seul tenant), sinon (début, blanc, `_`, chiffre, ponctuation) le corps de 16 suffit ;
//  - `Bearer` : « Flagbearer » est un mot ; une lettre juste avant exige un corps de 24, sinon 16. Les lookbehinds sont d'un seul caractère (coût constant), les lookaheads bornés (127).
const MASQUES = [
  /gh[pousr]_[A-Za-z0-9]{20,}/g, /github_pat_[A-Za-z0-9_]{20,}/g, /(?<![A-Za-z])sk-[A-Za-z0-9_-]{16,}/g,
  /(?<=[A-Za-z])sk-(?=[A-Za-z0-9_-]{0,127}[A-Z])(?=[A-Za-z0-9_-]{0,127}\d)(?:(?:proj|ant|svcacct|admin)-[A-Za-z0-9_-]{36,}|[A-Za-z0-9]{40,})/g, /AKIA[A-Z0-9]{16}/g, /xox[baprs]-[A-Za-z0-9-]+/g,
  /(?<![A-Za-z])Bearer\s+[A-Za-z0-9._~+\/=-]{16,}/gi, /(?<=[A-Za-z])Bearer\s+[A-Za-z0-9._~+\/=-]{24,}/gi,
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
// Aucun caractère venu au-delà de n dans le texte brut n'est rendu : on garde le plus long préfixe commun au masque de [0, n) et au masque de [0, n + marge) (limite : le masque
// de la tranche élargie voit le secret en entier, celui de la tranche courte n'en voit qu'un fragment : ils divergent au début du secret, qui n'est jamais rendu).
export const MARGE_MASQUE = 700; // > 385 caractères, la plus longue portée d'un motif (`://user:pass@`)
export const masqueCoupe = (t, n) => {
  const s = String(t), a = masque(s, n); if (s.length <= n) return a;
  const b = masque(s, n + MARGE_MASQUE), m = Math.min(a.length, b.length); let i = 0;
  while (i < m && a.charCodeAt(i) === b.charCodeAt(i)) i++;
  const r = a.slice(0, Math.min(i, n)), d = r.charCodeAt(r.length - 1);
  return d >= 0xd800 && d <= 0xdbff ? r.slice(0, -1) : r; // PU-G-162 (S5) : une coupe ne laisse jamais une moitié de paire de substitution
};
// PU-G-162 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06, « Branche + ton nom /rename ») : amendement de la liste blanche de lecture des transcripts
// (P69-D-19, P69-D-23) pour le SEUL champ `customTitle` d'une entrée `custom-title` (le nom que l'utilisateur donne avec /rename). Jamais `ai-title` (texte écrit par le modèle),
// ni `last-prompt`, ni un message. Garanties : une seule fenêtre de 256 Kio en fin de fichier (aucune escalade pour chercher un titre), forme typée (chaîne), contrôles retirés
// (C0, C1, U+2028/U+2029, catégorie Cf), masque des secrets AVANT la coupe, 80 caractères au plus APRÈS nettoyage ; la page ne l'affiche qu'en `textContent`.
export const BORNE_TITRE = 80;
// la classe d'affichage (C0, C1, U+2028/2029, catégorie Cf) : copie n°5, mesurée par la parité R4.1 de test-cockpit-git-commandes.sh ; `retireAffichage` la retire sans rien laisser, `nettoieTitre` met une espace à la place
// exportée SANS drapeau g (un `.test` d'appelant n'alterne pas par lastIndex, cf. R4.2) ; les remplacements utilisent la copie globale privée
export const CLASSE_AFFICHAGE = /[\u0000-\u001f\u007f-\u009f\u2028\u2029\p{Cf}]/u;
const CLASSE_GLOBALE = new RegExp(CLASSE_AFFICHAGE.source, 'gu');
export const retireAffichage = (t) => (typeof t === 'string' ? t.replace(CLASSE_GLOBALE, '') : '');
export const nettoieTitre = (t) => {
  if (typeof t !== 'string') return '';
  const entree = t.slice(0, MAX_MASQUE), d = entree.charCodeAt(entree.length - 1); // la borne d'entrée ne coupe pas non plus une paire de substitution
  const propre = (d >= 0xd800 && d <= 0xdbff ? entree.slice(0, -1) : entree).replace(CLASSE_GLOBALE, ' ').replace(/ {2,}/g, ' ').trim();
  return masqueCoupe(propre, BORNE_TITRE).trim();
};
const CACHE_TITRES = new Map();
const TITRE_PAR_DEFAUT = /^new session$/i; // valeur par défaut de `custom-title` (application de bureau de Claude Code), mesurée sur 407 lignes d'une session ouverte
// le titre le plus récent l'emporte, même vide (l'utilisateur a pu le vider) ; un échec de lecture n'est jamais mémorisé comme « pas de titre »
export const titreSession = (f) => {
  let st; try { st = fs.statSync(f); } catch { return ''; }
  const c = CACHE_TITRES.get(f); if (c && c.mt === st.mtimeMs && c.size === st.size) return c.titre;
  const etat = {}, r = cherche(f, (d) => (d.type === 'custom-title' && typeof d.customTitle === 'string' ? { t: d.customTitle } : null), [FENETRES[0]], etat);
  if (etat.erreur) return '';
  const propre = nettoieTitre(r ? r.t : '');
  const titre = TITRE_PAR_DEFAUT.test(propre) ? '' : propre; // AUDC-D6 : la valeur par défaut écrite par l'application de bureau n'est pas un nom choisi ; jamais de titre généré (PU-G-162)
  if (CACHE_TITRES.size >= 4000) CACHE_TITRES.clear();
  CACHE_TITRES.set(f, { mt: st.mtimeMs, size: st.size, titre });
  return titre;
};
export const ID_RE = /^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/;

// première ligne d'un jsonl (256 premiers Kio), analysée en JSON ; null si illisible. Cache par chemin, borné (vidé au-delà de 4 000 entrées) et invalidé par la date et la taille :
// un échec transitoire (fichier vide lu avant son écriture) n'est jamais retenu.
const CACHE = new Map();
export const premiereLigne = (f) => {
  let st = null, fd = null, r = null;
  try { st = fs.statSync(f); } catch { return null; }
  const c = CACHE.get(f); if (c && c.mt === st.mtimeMs && c.size === st.size) return c.r;
  try {
    if (!st.isFile()) throw new Error('pas un fichier'); // un tube (FIFO) bloquerait l'ouverture
    fd = fs.openSync(f, 'r'); const buf = Buffer.alloc(256 << 10); const n = fs.readSync(fd, buf, 0, buf.length, 0);
    r = JSON.parse(buf.toString('utf8', 0, n).split('\n')[0]);
  } catch { r = null; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } }
  if (CACHE.size >= 4000) CACHE.clear();
  CACHE.set(f, { mt: st.mtimeMs, size: st.size, r });
  return r;
};
