// chrome-sante-fr.mjs — le panneau Santé lu dans la page SERVIE (80-19, P80-D-54, FORM-18).
// Usage : node chrome-sante-fr.mjs <chrome> <url de index.html>
// Imprime une ligne JSON : { donnees, affiches, intro, hostile, invite, services }
//   donnees  : les constats tels que le collecteur les a écrits dans la page (id, title, detail, fix)
//   affiches : ce que le panneau montre pour chacun (titre, détail), après t.constat
//   intro    : l'introduction du panneau (ni retouchée ni traduite par ce plan)
//   hostile  : le constat dont le titre porte un nom de fichier hostile — texte du titre, nombre d'éléments img du panneau, window.__p
//   invite   : le texte de l'invite (<pre>) du constat de clé en fichier de test
// Chaque état est attendu par une condition de la page, jamais par une pause fixe.
import { executer, stabiliser, attendreValeur } from './chrome-session.mjs';

const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!document.querySelector('header .brand .mark') && !!document.getElementById('panel')";
const DONNEES = "((window.VF_COCKPIT || window.VibeFlow.graph).health.issues || []).map((i) => ({ id: i.id, title: i.title, detail: i.detail, fix: i.fix }))";
const AFFICHES = "[...document.querySelectorAll('#panel .hc-issue')].map((e) => ({ titre: (e.querySelector('.hc-t') || {}).textContent, detail: (e.querySelector('.hc-d') || {}).textContent }))";
const HOSTILE = "(() => { const e = [...document.querySelectorAll('#panel .hc-issue')].find((x) => /onerror/.test((x.querySelector('.hc-t') || {}).textContent || '')); return { titre: e ? e.querySelector('.hc-t').textContent : null, imgs: document.querySelectorAll('#panel img').length, p: typeof window.__p }; })()";
// le bouton « Corriger » du constat de clé en fichier de test : son invite s'ouvre dans la fenêtre modale
const OUVRIR_INVITE = "(() => { const e = [...document.querySelectorAll('#panel .hc-issue')].find((x) => /aws\\.test\\.js/.test((x.querySelector('.hc-t') || {}).textContent || '')); const b = e && e.querySelector('[data-hc-fix]'); if (b) b.click(); return !!b; })()";

const [, , chrome, url] = process.argv;
await executer(chrome, async (s) => {
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1400, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(url); await s.attendre(PRET, 'page prête');
  // la visite guidée de départ change la vue : on attend qu'elle se soit posée, comme les autres pilotes
  await attendreValeur(() => s.ev("!!document.querySelector('#tour .tk')"), (v) => v, { pas: 150, max: 6000 });
  const donnees = await s.ev(DONNEES);
  await s.ev("document.getElementById('btn-health').click()");
  await s.attendre("!!document.querySelector('#panel .hc-issue')", 'liste de Santé');
  const affiches = await stabiliser(() => s.ev(AFFICHES), { pas: 300, max: 8000 });
  const intro = await stabiliser(() => s.ev("[...document.querySelectorAll('#panel .pd')].map((e) => e.textContent).join(' || ') || null"), { pas: 300, max: 8000 });
  const hostile = await stabiliser(() => s.ev(HOSTILE), { pas: 300, max: 8000 });
  const ouvert = await s.ev(OUVRIR_INVITE);
  let invite = null;
  if (ouvert) { await s.attendre("!!document.querySelector('#modal pre')", 'invite ouverte'); invite = await stabiliser(() => s.ev("document.querySelector('#modal pre').textContent"), { pas: 300, max: 8000 }); }
  const services = await s.ev("((window.VF_COCKPIT || window.VibeFlow.graph).health || {}).services || null");
  return { donnees, affiches, intro, hostile, invite, services };
});
