// chrome-regie-tiroir.mjs <chrome> <url de equipe.html> : le lien « N à relire dans Équipe » du tiroir « Au travail », dans un vrai navigateur (Phase 73, plan 73-10, RG11.22).
// Sur l'onglet Projet, un `who` rejoué par le flux (EventSource enveloppé, __emit) porte trois sous-agents terminés dont aucun n'est lu ; le tiroir s'ouvre, son lien est lu, puis suivi :
// Équipe s'ouvre, la régie est montée et le focus est sur le titre de « Terminé, à relire ». Rend UNE ligne JSON ({ erreur } sur échec nommé).
import { executer, attendreEtStabiliser } from './chrome-session.mjs';
const [, , chrome, url] = process.argv;
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
const S = 's0000000-aaaa-bbbb-cccc-111111111111';
const fini = (id, n) => ({ kind: 'subagent', id, etat: 'termine', parent: S, role: 'vf-reviewer', task: 'Rapport ' + n, ageS: 300 + n, dureeS: 40, tree: '.' });
const WHO = { workers: [{ kind: 'session', id: S, etat: 'actif', titre: 'Atelier', tree: '.', ageS: 4 }, fini('f1f1f1f1f1f1', 1), fini('f2f2f2f2f2f2', 2), fini('f3f3f3f3f3f3', 3)], sources: {} };
await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ });
  await s.naviguer(url.replace('equipe.html', 'project.html') + '#sans-visite');
  await s.attendre("window.__es.some((e) => e.url.includes('/api/vf/events'))", 'flux');
  await s.ev(`window.__es.find((x) => x.url.includes('/api/vf/events')).__emit('who', { seq: 9101, who: ${JSON.stringify(WHO)} })`);
  await s.attendre("!!document.getElementById('vf-lock')", 'bouton du tiroir');
  await s.ev("document.getElementById('vf-lock').click()");
  const lire = () => s.ev("(() => { const a = document.querySelector('.vf-whop a[href*=\"vf-a-relire\"]'); return a ? { texte: a.textContent.trim(), href: a.getAttribute('href'), plis: document.querySelectorAll('.vf-whop details.vf-termines').length } : null; })()");
  const lien = await attendreEtStabiliser(lire, (v) => !!v, { pas: 150, max: 8000 });
  const avant = await s.ev('performance.timeOrigin');
  await s.ev("document.querySelector('.vf-whop a[href*=\"vf-a-relire\"]').click()");
  await s.attendre("!!document.getElementById('vf-equipe') && document.body.classList.contains('vf-regie-montee')", 'régie montée après le lien');
  const lireFocus = () => s.ev("(() => { const a = document.activeElement, sec = a && a.closest && a.closest('section[data-vf-section]'); return { tag: a ? a.tagName : '', section: sec ? sec.dataset.vfSection : '' }; })()");
  const focus = await attendreEtStabiliser(lireFocus, (v) => v && v.tag === 'H2', { pas: 150, max: 8000 });
  return { lien, focus, rechargee: (await s.ev('performance.timeOrigin')) !== avant };
}, { csp: true });
