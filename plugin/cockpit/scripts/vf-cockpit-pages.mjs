// vf-cockpit-pages — une page du cockpit servie en trois parties, sans jamais reconstruire une chaîne d'une page entière (79-15, SOCL-19 ; R8).
// Forme de TRANSITION : la coquille statique de 79-16 (A42) la remplace ; l'export autonome garde « coquille + données incluses ».
// Exports : preparerGabarit(html, { inject, titre }) -> { avant, apres, hachesAvant, hachesApres, prefixeDonnees, donneesGabarit } (tampons,
// construits UNE fois par gabarit),
//   assemblerPage(gabarit, donnees) -> { avant, donnees, apres, longueur, haches } (`donnees` : le JSON échappé d'une page, vf-cockpit-embed.serialiser),
// creerAssembleur() -> { page(onglet, gabarit, courant), vider() } : la page assemblée d'un onglet, mémoïsée par gabarit et signature (une requête de
// plus ne la reconstruit pas),
//   hachesDePage(page) -> liste ordonnée dédoublonnée d'empreintes `'sha256-…'` (entre apostrophes) des scripts en ligne, dans l'ordre du document.
// L'empreinte de la zone de données porte sur les octets servis : préfixe, données échappées, point-virgule fermant.
import crypto from 'node:crypto';
import { decouper, DATA_START, DATA_END } from './vf-cockpit-embed.mjs';

const BALISE = '<script>';
const empreinte = (texte) => `'sha256-${crypto.createHash('sha256').update(texte).digest('base64')}'`;
const dedoublonner = (l) => [...new Set(l)];
const scripts = (texte) => [...String(texte).matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => empreinte(m[1]));

const texteDe = (page) => (typeof page === 'string' ? page : page.avant.toString('utf8') + page.donnees.toString('utf8') + page.apres.toString('utf8'));
export const hachesDePage = (page) => dedoublonner(scripts(texteDe(page)));

export function preparerGabarit(html, { inject = '', titre } = {}) {
  const { avant, donnees, apres } = decouper(html);
  const ins = `${inject}`;
  let debut = avant;
  if (typeof titre === 'string') debut = debut.replace(/<title>[^<]*<\/title>/, () => `<title>${titre}</title>`);
  debut = debut.replace('</head>', () => `${ins}</head>`);
  const prefixeDonnees = DATA_START.slice(BALISE.length); // le texte du script de données avant les données
  let donneesGabarit = null; try { donneesGabarit = JSON.parse(donnees); } catch { donneesGabarit = null; }
  const finApres = apres.slice(DATA_END.length); // ce qui suit la fermeture du script de données
  return {
    avant: Buffer.from(debut, 'utf8'), apres: Buffer.from(apres, 'utf8'),
    hachesAvant: scripts(debut.slice(0, debut.length - DATA_START.length)), // scripts en ligne complets avant le script de données (jeton, terminal)
    hachesApres: scripts(finApres), prefixeDonnees, donneesGabarit,
  };
}

export function assemblerPage(gabarit, donnees) {
  const corps = Buffer.from(String(donnees), 'utf8');
  const haches = dedoublonner([...gabarit.hachesAvant, empreinte(gabarit.prefixeDonnees + String(donnees) + ';'), ...gabarit.hachesApres]); // garde:pages-csp
  return { avant: gabarit.avant, donnees: corps, apres: gabarit.apres, longueur: gabarit.avant.length + corps.length + gabarit.apres.length, haches };
}

// une page par onglet : mêmes tampons tant que ni le gabarit ni la signature ne changent (A27 : jamais reconstruite par requête)
export function creerAssembleur() {
  let memo = {};
  return {
    page(onglet, gab, c) {
      if (!gab || !c || c.interdit) return null;
      const m = memo[onglet];
      if (m && m.gab === gab && m.sig === c.sig) return m.page;
      const page = assemblerPage(gab, c.page()); memo[onglet] = { gab, sig: c.sig, page };
      return page;
    },
    vider() { memo = {}; },
  };
}
