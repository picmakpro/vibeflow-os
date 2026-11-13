// chrome-sante-fr.mjs — le panneau Santé lu dans la page SERVIE (80-19, P80-D-54, FORM-18).
// Usage : node chrome-sante-fr.mjs <chrome> <url de index.html>
// Imprime une ligne JSON : { donnees, affiches, intro, hostile, invite, services }
//   donnees  : les constats tels que le collecteur les a écrits dans la page (id, title, detail, fix)
//   affiches : ce que le panneau montre pour chacun (titre, détail), après t.constat
//   intro    : l'introduction du panneau (ni retouchée ni traduite par ce plan)
//   hostile  : le constat dont le titre porte un nom de fichier hostile — texte du titre, nombre d'éléments img du panneau, window.__p
//   invite   : le texte de l'invite (<pre>) du constat de clé en fichier de test
//   services : la liste des services lue dans les données de la page
//   retour   : SF3.5, après Code -> Projet -> Code par VF_ONGLETS.aller : { trajet, memeOrigine, rouvert (titre, détail), invite }
// Chaque état est attendu par une condition de la page, jamais par une pause fixe.
import { executer, stabiliser, attendreValeur } from './chrome-session.mjs';

const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state"
  + " && !!document.querySelector('header .brand .mark') && !!document.getElementById('panel')";
const SANTE = "((window.VF_COCKPIT || window.VibeFlow.graph).health || {})";
const DONNEES = `(${SANTE}.issues || []).map((i) => ({ id: i.id, title: i.title, detail: i.detail, fix: i.fix }))`;
const TITRE = "((x.querySelector('.hc-t') || {}).textContent || '')";
const AFFICHES = "[...document.querySelectorAll('#panel .hc-issue')].map((e) => ({"
  + " titre: (e.querySelector('.hc-t') || {}).textContent, detail: (e.querySelector('.hc-d') || {}).textContent }))";
const INTRO = "[...document.querySelectorAll('#panel .pd')].map((e) => e.textContent).join(' || ') || null";
const HOSTILE = "(() => { const e = [...document.querySelectorAll('#panel .hc-issue')].find((x) => /onerror/.test(" + TITRE + "));"
  + " return { titre: e ? e.querySelector('.hc-t').textContent : null,"
  + " imgs: document.querySelectorAll('#panel img').length, p: typeof window.__p }; })()";
// le bouton « Corriger » du constat de clé en fichier de test : son invite s'ouvre dans la fenêtre modale
const OUVRIR_INVITE = "(() => { const e = [...document.querySelectorAll('#panel .hc-issue')].find((x) => /aws\\.test\\.js/.test(" + TITRE + "));"
  + " const b = e && e.querySelector('[data-hc-fix]'); if (b) b.click(); return !!b; })()";
const posee = (lire) => stabiliser(lire, { pas: 300, max: 8000 });

const [, , chrome, url] = process.argv;
await executer(chrome, async (s) => {
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(url); await s.attendre(PRET, 'page prête');
  // la visite guidée de départ change la vue : on attend qu'elle se soit posée, comme les autres pilotes
  await attendreValeur(() => s.ev("!!document.querySelector('#tour .tk')"), (v) => v, { pas: 150, max: 6000 });
  const donnees = await s.ev(DONNEES);
  await s.ev("document.getElementById('btn-health').click()");
  await s.attendre("!!document.querySelector('#panel .hc-issue')", 'liste de Santé');
  const affiches = await posee(() => s.ev(AFFICHES));
  const intro = await posee(() => s.ev(INTRO));
  const hostile = await posee(() => s.ev(HOSTILE));
  const ouvert = await s.ev(OUVRIR_INVITE);
  let invite = null;
  if (ouvert) {
    await s.attendre("!!document.querySelector('#modal pre')", 'invite ouverte');
    invite = await posee(() => s.ev("document.querySelector('#modal pre').textContent"));
  }
  const services = await s.ev(`${SANTE}.services || null`);
  // SF3.5 (P80-D-59) : Code -> Projet -> Code par VF_ONGLETS.aller (promesses attendues), sans rechargement : prouvé par performance.timeOrigin
  // (un marqueur posé sur window est retiré par la portée d'onglet de la 79). Puis le panneau Santé rouvert : même constat que à froid.
  const origine = await s.ev('performance.timeOrigin');
  const aller = (nom) => s.ev(`VF_ONGLETS.aller(${JSON.stringify(nom)}).then(() => 'ok', (e) => String(e && e.message))`);
  await s.ev("const c = document.querySelector('#modal [data-close]'); if (c) c.click()");
  const trajet = [await aller('projet'), await aller('code')];
  await s.attendre(PRET, 'page Code revenue'); await s.attendre("document.getElementById('btn-health')", 'bouton Santé');
  if (!(await s.ev("!!document.querySelector('#panel .hc-issue')"))) await s.ev("document.getElementById('btn-health').click()");
  await s.attendre("!!document.querySelector('#panel .hc-issue')", 'liste de Santé rouverte');
  const rouvert = await posee(() => s.ev(AFFICHES));
  let inviteRouverte = null;
  if (await s.ev(OUVRIR_INVITE)) {
    await s.attendre("!!document.querySelector('#modal pre')", 'invite rouverte');
    inviteRouverte = await posee(() => s.ev("document.querySelector('#modal pre').textContent"));
  }
  const retour = { trajet, memeOrigine: (await s.ev('performance.timeOrigin')) === origine, rouvert, invite: inviteRouverte };
  return { donnees, affiches, intro, hostile, invite, services, retour };
});
