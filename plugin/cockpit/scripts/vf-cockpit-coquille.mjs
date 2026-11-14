// vf-cockpit-coquille — le document unique de la coquille, composé EN MÉMOIRE depuis les sources du MODULE (79-16, SOCL-20 ; C5, A1, P79-D-09, A40).
// Aucune donnée du lab n'y entre (ni nœud, ni nom de phase, ni chemin du poste) : les données de chaque onglet viennent de GET /api/vf/graphe, les scripts
// de /_vf/ (vf-cockpit-coquille-assets.mjs). Le gabarit du moteur (viewer.html) est lu une fois ; chacun de ses marqueurs doit y figurer UNE fois (sinon
// le serveur refuse de démarrer, message français, code 1). Le script du moteur et les extensions en sortent : ce sont des fichiers servis.
// Document, dans l'ordre de la tête : thème (en ligne), style, coquille-portee.js, coquille.js (premiers scripts), l'injection de l'appelant (script de
// jeton, tiroir du terminal sous --terminal), le manifeste (bloc de données, jamais exécuté), le script de classe `wk` ; puis le corps du gabarit.
// Exports : ADRESSES (gelé), PREFIXE, creerCoquille({ dossierMoteur, injection }) -> { document(adresse), empreintes(adresse), manifeste, asset(chemin),
//   table, prefixeScripts(hote) }, prefixeScripts(hote).
//   `injection(adresse)` rend le texte posé avant `</head>` pour cette adresse ; `document(adresse)` rend { octets, longueur, haches } (une entrée par adresse,
//   mêmes octets hors le <title> et l'injection).
import fs from 'node:fs';
import path from 'node:path';
import { lireAssets, PREFIXE } from './vf-cockpit-coquille-assets.mjs';
import { hachesDePage } from './vf-cockpit-pages.mjs';
import { renommerTexte } from './vf-cockpit-rename.mjs';

export { PREFIXE };
export const ADRESSES = Object.freeze(['/', '/index.html', '/project.html', '/equipe.html']);
const TITRES = { '/': 'VibeFlow · Code', '/index.html': 'VibeFlow · Code', '/project.html': 'VibeFlow · Projet', '/equipe.html': 'VibeFlow · Équipe' };
// source de script de la CSP : la seule origine admise en plus des empreintes ; l'hôte est celui que serve.mjs a déjà validé
export const prefixeScripts = (hote) => `http://${hote}${PREFIXE}`; // garde:coquille-source

// nom du moteur dans les jetons de son gabarit : assemblé ici, jamais écrit en toutes lettres (AM4.17, P79-D-08 option a)
const AMONT = ['FLOOR', 'PLAN'].join('');
const MARQUEURS = ['/*__FONTS__*/', '<!--__ELK_SCRIPT__-->', `/*__${AMONT}_DATA__*/`, '/*__GRAPH_QUERY__*/',
  '<!--__UI_I18N__-->', '<!--__UI_EXTENSIONS__-->'];
const compter = (t, m) => t.split(m).length - 1;
const refus = (m) => Object.assign(new Error(`coquille : ${m}`), { code: 1 });
// plages de caractères des polices, comme build.mjs du moteur (en morceaux, pour tenir la largeur de ligne)
const PLAGES = {
  latin: ['U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,',
    'U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD'],
  'latin-ext': ['U+0100-02BA,U+02BD-02C5,U+02C7-02CC,U+02CE-02D7,U+02DD-02FF,U+0304,U+0308,U+0329,',
    'U+1D00-1DBF,U+1E00-1E9F,U+1EF2-1EFF,U+2020,U+20A0-20AB,U+20AD-20C0,U+2113,U+2C60-2C7F,U+A720-A7FF'],
};
const FAMILLES = [['Inter', 'inter'], ['JetBrains Mono', 'jetbrains-mono']];
const police = (assets, famille, fichier, sous, plage) => {
  const b64 = fs.readFileSync(path.join(assets, 'vendor', 'fonts', `${fichier}-${sous}-wght-normal.woff2`)).toString('base64');
  return '@font-face{font-family:"' + famille + '";font-style:normal;font-display:swap;font-weight:100 900;'
    + `unicode-range:${plage.join('')};src:url(data:font/woff2;base64,${b64}) format("woff2")}`;
};
const policesCss = (assets) => FAMILLES.flatMap(([famille, fichier]) => Object.entries(PLAGES)
  .map(([sous, plage]) => police(assets, famille, fichier, sous, plage))).join('\n');
const svgUri = (assets, nom) => 'data:image/svg+xml;base64,' + fs.readFileSync(path.join(assets, nom)).toString('base64');
// la fin du gabarit : script de classe `wk`, données, requête, i18n, script du moteur, extensions (chacun à sa place, ou le serveur refuse de démarrer)
const FIN = new RegExp('^<!--__ELK_SCRIPT__-->\\s*(<script>[^\\n]*AppleWebKit[^\\n]*</script>)\\s*<script>[^\\n]*__' + AMONT + '_DATA__[^\\n]*</script>\\s*'
  + '<script>/\\*__GRAPH_QUERY__\\*/</script>\\s*<!--__UI_I18N__-->\\s*<script>\\n([\\s\\S]*)</script>\\s*<!--__UI_EXTENSIONS__-->\\s*</body>\\s*</html>\\s*$');
const ORDRE = ['coquille', 'bibliotheque', 'persistant', 'i18n', 'moteur', 'onglet']; // ordre du manifeste, chaque groupe par ordre d'octets du nom
const parNom = (a, b) => (a.nom < b.nom ? -1 : a.nom > b.nom ? 1 : 0);

export function creerCoquille({ dossierMoteur, injection = () => '' }) {
  const assets = path.join(dossierMoteur, 'assets');
  let gabarit;
  try { gabarit = fs.readFileSync(path.join(assets, 'viewer.html'), 'utf8'); }
  catch { throw refus('le gabarit viewer.html du moteur est illisible : refus de démarrer.'); }
  for (const m of MARQUEURS) { // garde:coquille-marqueur
    const n = compter(gabarit, m);
    if (n !== 1) throw refus(`le marqueur de gabarit « ${m} » doit figurer exactement une fois dans viewer.html (trouvé ${n}) : refus de démarrer.`);
  }
  const iElk = gabarit.indexOf('<!--__ELK_SCRIPT__-->');
  let avant = gabarit.slice(0, iElk);
  const fin = FIN.exec(gabarit.slice(iElk));
  if (!fin) throw refus('la fin de viewer.html n\'a plus la forme attendue (script de classe, données, moteur, extensions) : refus de démarrer.');
  const [, wk, moteur] = fin;
  // le petit script de corps (règle no-panel sur téléphone) sort du document : la coquille applique sa règle à chaque onglet
  avant = avant.replace(/<script>if \(matchMedia\('\(max-width: 700px\)'\)[^\n]*<\/script>\n/, '');
  const logo = svgUri(assets, 'vibeflow-logo-clair.svg');
  avant = avant.replace(new RegExp(`__${AMONT}_TITLE__`, 'g'), '@@VF_TITRE@@')
    .replace(new RegExp(`__${AMONT}_LOGO__`, 'g'), () => logo).replace(new RegExp(`__${AMONT}_FAVICON__`, 'g'), () => logo);
  avant = renommerTexte(avant).replace('/*__FONTS__*/', () => policesCss(assets));
  const { table, fichiers } = lireAssets(dossierMoteur, { moteur });
  const liste = ORDRE.flatMap((c) => fichiers.filter((f) => f.classe === c).sort(parNom).map((f) => ({ nom: f.nom, classe: f.classe })));
  const manifeste = { version: 1, prefixe: PREFIXE, fichiers: liste };
  const bloc = `<script type="application/json" id="vf-coquille-manifeste">${JSON.stringify(manifeste).replace(/</g, '\\u003c')}</script>`;
  const i = avant.indexOf('</head>');
  const tete = `<script src="${PREFIXE}coquille-portee.js"></script>\n<script src="${PREFIXE}coquille.js"></script>\n@@VF_INJECTION@@\n${bloc}\n${wk}\n`;
  const modele = avant.slice(0, i) + tete + avant.slice(i) + '</body>\n</html>\n';
  const documents = new Map();
  for (const adresse of ADRESSES) {
    const texte = modele.replace('@@VF_TITRE@@', () => TITRES[adresse]).replace('@@VF_INJECTION@@', () => injection(adresse));
    const octets = Buffer.from(texte, 'utf8');
    documents.set(adresse, { octets, longueur: octets.length, haches: hachesDePage(texte) });
  }
  return {
    document: (adresse) => documents.get(adresse) || null,
    empreintes: (adresse) => documents.get(adresse)?.haches || null,
    manifeste, table, asset: (chemin) => table.get(chemin) || null, prefixeScripts,
  };
}
