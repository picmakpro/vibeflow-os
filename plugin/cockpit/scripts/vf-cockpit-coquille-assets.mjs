// vf-cockpit-coquille-assets — les fichiers de script de la coquille, servis sous /_vf/ depuis le MODULE (79-16, SOCL-20 ; C5, A37, A40, A53, P79-D-09).
// Table FERMÉE construite au démarrage : une recherche exacte dans une Map, jamais une adresse convertie en chemin de fichier. La liste des scripts de
// `ui/` est calculée UNE fois depuis le dossier `ui/` de premier niveau du module que ce serveur sert (jamais la sortie du lab, jamais la requête) ;
// un fichier ajouté après le démarrage, ou de même nom dans la sortie, n'y entre pas. Les sous-dossiers (ui/tiroir, ui/terminal, 79-11) ne sont pas des
// extensions de page. Le chemin physique de chaque fichier doit rester sous le dossier des assets du moteur (A37 : sinon, refus de démarrer).
// Exports : lireAssets(dossierMoteur, { moteur }) -> { table, fichiers }, classerScripts(liste) -> { bibliotheques, persistants, i18n, parOnglet },
//   servirAsset(req, res, table) -> true si l'adresse est sous le préfixe (la réponse est écrite), false sinon.
// Classes : bibliotheque (déclarent des noms globaux : jamais ré-exécutées), persistant (marqueur `vf-coquille: persistant` dans les huit premières lignes,
// une évaluation par chargement de la coquille, ordre d'octets du nom), i18n (première ligne `// vibeflow:fr` : lit la donnée de l'onglet, posée avant le
// moteur), onglet (le défaut : ré-exécuté à chaque onglet, après le moteur).
// `moteur.js` est le script du moteur extrait du gabarit (texte rendu par l'appelant).
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { cheminPhysique } from './vf-cockpit-git-sortant.mjs';
import { correspond } from './vf-cockpit-graphe.mjs';
import { renommerTexte } from './vf-cockpit-rename.mjs';

export const PREFIXE = '/_vf/';
const TAILLE_MAX = 6 * 1024 * 1024;
const octets = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const MARQUEUR_PERSISTANT = 'vf-coquille: persistant';

// la classe d'un fichier de ui/ : lue du texte, jamais d'une liste de noms
export function classerScripts(liste) {
  const r = { bibliotheques: [], persistants: [], i18n: [], parOnglet: [] };
  for (const f of [...liste].sort((a, b) => octets(a.nom, b.nom))) {
    const lignes = String(f.texte).split('\n');
    if (lignes.slice(0, 8).some((l) => l.includes(MARQUEUR_PERSISTANT))) r.persistants.push(f.nom); // garde:coquille-classe
    else if (lignes[0].replace(/\r$/, '') === '// vibeflow:fr') r.i18n.push(f.nom);
    else r.parOnglet.push(f.nom);
  }
  return r;
}

const refus = (m) => Object.assign(new Error(`coquille : ${m}`), { code: 1 });
const entree = (nom, classe, texte) => {
  const buf = Buffer.from(texte, 'utf8');
  return { nom, classe, texte, octets: buf, etag: `"${crypto.createHash('sha256').update(buf).digest('hex').slice(0, 16)}"` };
};

// lit les fichiers du moteur ; lève (français) si un chemin physique sort du dossier des assets ou si un fichier est illisible ou trop gros
export function lireAssets(dossierMoteur, { moteur } = {}) {
  const assets = path.join(dossierMoteur, 'assets');
  const racine = cheminPhysique(assets);
  if (!racine) throw refus('dossier des assets du moteur introuvable : refus de démarrer.');
  const lire = (relatif, { renommer = true } = {}) => {
    const f = path.join(assets, relatif), reel = cheminPhysique(f);
    if (!reel || !(reel === racine || reel.startsWith(racine + path.sep))) { // garde:coquille-chemin
      throw refus(`le fichier ${relatif} sort du dossier des assets du moteur (chemin physique) : refus de démarrer.`);
    }
    let st; try { st = fs.statSync(reel); } catch { throw refus(`le fichier ${relatif} est illisible : refus de démarrer.`); }
    if (!st.isFile() || st.size > TAILLE_MAX) throw refus(`${relatif} n'est pas un fichier ordinaire de taille admise : refus de démarrer.`);
    const t = fs.readFileSync(reel, 'utf8');
    return renommer ? renommerTexte(t) : t;
  };
  const fichiers = [];
  fichiers.push(entree('coquille-portee.js', 'coquille', lire('vf-coquille-portee.js', { renommer: false })));
  fichiers.push(entree('coquille.js', 'coquille', lire('vf-coquille.js', { renommer: false })));
  fichiers.push(entree('graph-query.js', 'bibliotheque', lire('graph-query.js')));
  fichiers.push(entree('vendor/elk.bundled.js', 'bibliotheque', lire(path.join('vendor', 'elk.bundled.js'), { renommer: false })));
  let noms;
  try { noms = fs.readdirSync(path.join(assets, 'ui'), { withFileTypes: true }).filter((d) => !d.isDirectory() && d.name.endsWith('.js')).map((d) => d.name); }
  catch { throw refus('dossier ui/ du moteur illisible : refus de démarrer.'); }
  const ui = noms.map((n) => ({ nom: `ui/${n}`, texte: lire(path.join('ui', n)) }));
  const classes = classerScripts(ui), classeDe = new Map();
  const NOMS = { persistants: 'persistant', i18n: 'i18n', parOnglet: 'onglet' };
  for (const k of Object.keys(NOMS)) for (const n of classes[k]) classeDe.set(n, NOMS[k]);
  for (const f of ui) fichiers.push(entree(f.nom, classeDe.get(f.nom), f.texte));
  if (typeof moteur === 'string') fichiers.push(entree('moteur.js', 'moteur', renommerTexte(moteur)));
  const table = new Map(fichiers.map((f) => [PREFIXE + f.nom, f]));
  return { table, fichiers };
}

const ENTETES = { 'Content-Type': 'text/javascript; charset=utf-8', 'Cache-Control': 'no-cache' };
export function servirAsset(req, res, table) {
  let p; try { p = new URL(req.url, 'http://x').pathname; } catch { return false; }
  if (!p.startsWith(PREFIXE)) return false;
  if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405, { Allow: 'GET, HEAD' }); res.end(); return true; }
  const f = table.get(p); // garde:coquille-404
  if (!f) { res.writeHead(404); res.end(); return true; }
  if (correspond(req.headers['if-none-match'], f.etag)) {
    res.writeHead(304, { ETag: f.etag, 'Cache-Control': ENTETES['Cache-Control'] }); res.end(); return true;
  }
  res.writeHead(200, { ...ENTETES, ETag: f.etag, 'Content-Length': f.octets.length });
  res.end(req.method === 'HEAD' ? undefined : f.octets);
  return true;
}
