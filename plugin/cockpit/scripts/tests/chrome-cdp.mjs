// chrome-cdp.mjs — client minimal du protocole DevTools pour les suites du cockpit (socle : chrome-session.mjs, aucune dépendance).
// Usage : node chrome-cdp.mjs <chrome> <graceMs> <expressionJs> <url> [<url> ...]
//   ouvre UN Chrome headless, charge chaque URL (changement de hash seul : navigation complète quand même), attend que la page soit PRÊTE
//   (load, en-tête et logo chargés — jamais un délai fixe), laisse <graceMs> de plus au rendu, puis relève l'expression (JSON-sérialisable, ou une
//   promesse qui s'y résout) jusqu'à ce que deux relevés consécutifs soient identiques. CDP_VIEWPORT=<L>x<H> fixe la taille de la fenêtre. Rend { resultats: [{ url, valeur, violations }] } sur une
//   ligne, ou { erreur: "<mesure indisponible, nommée>" }. Pour une page sans en-tête de cockpit : CDP_PRET=<expression booléenne>.
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, grace, expr, ...urls] = process.argv;
const PRET = process.env.CDP_PRET || `document.readyState === 'complete' && !!document.querySelector('header .brand .mark') && document.querySelector('header .brand .mark').naturalWidth > 0`;
await executer(chrome, async (s) => {
  const resultats = [];
  const vp = /^(\d+)x(\d+)$/.exec(process.env.CDP_VIEWPORT || '');
  if (vp) await s.send('Emulation.setDeviceMetricsOverride', { width: Number(vp[1]), height: Number(vp[2]), deviceScaleFactor: 1, mobile: false });
  for (const url of urls) {
    await s.naviguer(url); await s.attendre(PRET, `page prête (${url})`); await pause(Number(grace) || 0);
    resultats.push({ url, valeur: await s.stable(expr, `expression sur ${url}`), violations: [...s.violations] });
  }
  return { resultats };
}, { csp: true });
