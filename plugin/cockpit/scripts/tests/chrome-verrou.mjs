// chrome-verrou.mjs — recette 68 N2 (P68-D-38) : le tiroir « Au travail » écrit « dépôt » (liste « Verrous tenus »), jamais « depot » (la valeur `tree`/`scope` du flux reste `depot`).
// Usage : node chrome-verrou.mjs <chrome> <url http de project.html>. Rend { lignes, regle } : les textes des lignes de verrou du tiroir et la ligne d'en-tête du verrou (même âge, P68-D-39).
import { executer, attendreEtStabiliser } from './chrome-session.mjs';
const [, , chrome, url] = process.argv;
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ });
  await s.naviguer(url + '#sans-visite');
  await s.attendre("document.readyState === 'complete' && !!document.querySelector('#vf-lock') && window.__es.some((e) => e.url.includes('/api/vf/events'))", 'flux et badge');
  await s.ev(`window.__es.find((e) => e.url.includes('/api/vf/events')).__emit('who', { seq: 9000, at: Date.now(), who: { workers: [{ kind: 'lock', id: 'L1', tree: 'depot', task: 'x', ageS: 1, stale: false }], sources: {} } })`);
  // le `who` reste figé (ageS 1, whoSig exclut l'âge) pendant que le battement du verrou vieillit : le flux `lock` porte leaseS 57 (la prise du verrou) et un ageS différent, 3 (le dernier battement) : la durée « tenu depuis » doit venir du premier (PU-G-179)
  await s.ev(`window.__es.find((e) => e.url.includes('/api/vf/events')).__emit('lock', { seq: 9001, at: Date.now(), verrous: { etat: 'lue', plat: false, liste: [{ ws: '', scope: 'depot', phase: null, tenu: true, stale: false, ageS: 3, ttl: 1800, progressAgeS: null, owner: 'L1', step: 'x', leaseS: 57 }] } })`);
  await s.ev("document.querySelector('#vf-lock').click()");
  await s.attendre("!!document.querySelector('.vf-whop .r-verr li')", 'ligne de verrou');
  // la ligne peut se dessiner depuis `who` (âge figé à 1 s) avant que le flux `lock` n'y pose les 57 s : on attend l'âge du verrou, puis une lecture stable
  const lire = () => s.ev("({ lignes: [...document.querySelectorAll('.vf-whop .r-verr li')].map((e) => [...e.children].map((c) => c.textContent.trim()).join(' · ').slice(0, 80)), regle: (document.querySelector('.vf-whop .aw-driver') || { textContent: '' }).textContent.trim() })");
  return await attendreEtStabiliser(lire, (v) => v && /57 s/.test(v.regle) && v.lignes.length > 0 && !/(^|[^0-9])1 s/.test(String(v.lignes[0])), { pas: 150, max: 8000 });
}, { csp: true });
