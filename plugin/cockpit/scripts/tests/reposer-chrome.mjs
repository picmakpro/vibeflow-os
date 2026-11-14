// reposer-chrome.mjs — ce qui est reposé après un redessin du panneau, dans un vrai Chromium headless (79-17, SOCL-21 ; EKR1, EKR2).
// Usage : EKR_ACTION=<action> node reposer-chrome.mjs <chrome> <url>
//   reponse-puis-who   : (EKR1) tiroir « Au travail » ouvert, « Voir la dernière commande » activé (réponse du serveur remplacée par un texte fixe), puis un second
//                        `who` qui redessine le tiroir : la réponse reste affichée dans la ligne du bouton neuf → { remplace, texte, visible }
//   (EKR2, « Lire le transcript » puis `who`, retiré en fin de Phase 73 : plus de producteur du bouton ; la même propriété est mesurée sur le lecteur de repli de la régie par l'action lecteur-puis-who de chrome-equipe-clavier.mjs)
// Rend une ligne JSON { ... } ou { erreur }. Socle : chrome-session.mjs. Les attentes interrogent la page, jamais une durée fixe.
import { executer } from './chrome-session.mjs';

const [, , chrome, url] = process.argv;
const ACTION = process.env.EKR_ACTION || '';
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
const EMETTRE = `const flux = () => window.__es.find((e) => e.url.includes('/api/vf/events')); let seq = 8000;
  const emettre = (workers) => flux().__emit('who', { seq: seq++, at: Date.now(), who: { workers, sources: {} } });
  const S = { kind: 'session', id: 'S1', etat: 'actif', tree: '.', task: 'session' }, M = { kind: 'subagent', id: 'M1', etat: 'actif', role: 'vf-dev-manager', tree: '.', parent: 'S1', task: 'manager', dureeS: 60 };
  const C = (task) => ({ kind: 'subagent', id: 'C1', etat: 'actif', role: 'vf-coder', tree: '.', parent: 'M1', task, dureeS: 5 });`;

await executer(chrome, async (s) => {
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ });
  await s.naviguer(url);
  await s.attendre(PRET, 'viewer prêt');
  if (ACTION === 'reponse-puis-who') {
    await s.attendre("!!window.__es && !!window.__es.find((e) => e.url.includes('/api/vf/events')) && !!document.querySelector('#vf-lock')", 'flux et badge');
    await s.ev(`(() => { ${EMETTRE} emettre([S, M, C('un')]); const R = window.fetch.bind(window);
      window.fetch = (u, o) => String(u).includes('/api/vf/doing') ? Promise.resolve({ ok: true, json: async () => ({ doing: 'réponse fixe EKR1' }) }) : R(u, o); })()`);
    await s.ev("document.querySelector('#vf-lock').click()");
    const ZB = '.vf-whop [data-vf-doing="M1"]'; // la ligne du bouton cliqué (M1), jamais la première de la page
    await s.attendre(`!!document.querySelector('${ZB}')`, 'bouton « Voir la dernière commande » du tiroir');
    await s.ev(`window.__b = document.querySelector('${ZB}'); window.__b.click()`);
    await s.attendre(`(() => { const z = document.querySelector('${ZB} + .vf-doing'); return !!z && !z.hidden && z.textContent.includes('EKR1'); })()`, 'réponse affichée');
    await s.ev(`(() => { ${EMETTRE} emettre([S, M, C('deux')]); })()`);
    const remplace = await s.attendre(`!document.contains(window.__b) && !!document.querySelector('${ZB}')`, 'bouton remplacé par le redessin', 8000).then(() => true, () => false);
    const r = await s.stable(`(() => { const b = document.querySelector('${ZB}'); const z = b && b.nextElementSibling; return { texte: z ? z.textContent : null, visible: !!z && !z.hidden }; })()`, 'zone de la réponse stable');
    return { remplace, texte: r.texte, visible: r.visible };
  }
  return { erreur: 'action inconnue : ' + ACTION };
});
