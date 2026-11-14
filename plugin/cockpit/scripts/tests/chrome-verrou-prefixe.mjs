// chrome-verrou-prefixe.mjs — recette 68 M-3 (P68-D-39) : deux verrous d'un même propriétaire, dont un compartiment est préfixe de l'autre (`fiabilite` et `fiabilite-2`),
// gardent chacun leur âge dans le tiroir « Au travail » (correspondance exacte sur la portée et le compartiment, jamais par sous-chaîne).
// Usage : node chrome-verrou-prefixe.mjs <chrome> <url http de project.html>. Rend { lignes } : le texte de chaque ligne de verrou, dans l'ordre du flux `who`.
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
  const flux = "window.__es.find((e) => e.url.includes('/api/vf/events'))";
  // le `who` porte des âges figés (1 s) ; le flux `lock` porte les vrais (`leaseS`, la prise ; `ageS` du battement reste distinct) : `fiabilite` 40 s, `fiabilite-2` 600 s, `fiabilite` listé AVANT son extension (l'ordre qui trompait la sous-chaîne)
  await s.ev(`${flux}.__emit('who', { seq: 9000, at: Date.now(), who: { workers: [
    { kind: 'lock', id: 'L1', tree: 'compartiment fiabilite', task: 'a', ageS: 1, stale: false },
    { kind: 'lock', id: 'L1', tree: 'compartiment fiabilite-2', task: 'b', ageS: 1, stale: false }], sources: {} } })`);
  await s.ev(`${flux}.__emit('lock', { seq: 9001, at: Date.now(), verrous: { etat: 'lue', plat: false, liste: [
    { ws: 'fiabilite', scope: 'compartiment', phase: null, tenu: true, stale: false, ageS: 4, ttl: 1800, progressAgeS: null, owner: 'L1', step: 'a', leaseS: 40 },
    { ws: 'fiabilite-2', scope: 'compartiment', phase: null, tenu: true, stale: false, ageS: 5, ttl: 1800, progressAgeS: null, owner: 'L1', step: 'b', leaseS: 600 }] } })`);
  await s.ev("document.querySelector('#vf-lock').click()");
  await s.attendre("document.querySelectorAll('.vf-whop .r-verr li').length >= 2", 'deux lignes de verrou');
  // les âges réels (40 s, 10 min) viennent du flux `lock` : on les attend avant de lire, puis une lecture stable
  const lire = () => s.ev("[...document.querySelectorAll('.vf-whop .r-verr li')].map((e) => [...e.children].map((c) => c.textContent.trim()).join(' · ').slice(0, 120))");
  return { lignes: await attendreEtStabiliser(lire, (v) => v.length >= 2 && /fiabilite · .*40 s/.test(String(v[0])) && /fiabilite-2 · .*10 min/.test(String(v[1])), { pas: 150, max: 8000 }) };
}, { csp: true });
