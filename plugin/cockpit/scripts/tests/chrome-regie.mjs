// chrome-regie.mjs <chrome> <url de equipe.html> <scénario> : la régie dans un vrai navigateur (Phase 73, plan 73-05). Rend UNE ligne JSON ({ erreur } sur échec nommé).
//   montage      : la régie est montée, #stage masqué, seule région principale visible, aucun défilement horizontal à 375, 700, 768, 1000 et 1440 px (RG1.20)
//   fuite-verrou : témoin POSITIF d'abord (un événement `lock` à forme projetée fait apparaître la ligne de mission), puis le même événement chargé de sentinelles
//                  (identifiant de session, chemin du dossier de verrou, emplacement, durée de bail) : aucune sentinelle dans le HTML, localStorage, sessionStorage ni l'export (RG6.20)
// L'EventSource de la page est enveloppé (chrome-verrou.mjs) : __emit(nom, donnée) rejoue un événement du flux sans toucher le serveur.
import { executer, attendreEtStabiliser } from './chrome-session.mjs';
const [, , chrome, url, scenario] = process.argv;
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
const PRET = "document.readyState === 'complete' && !!document.getElementById('vf-equipe') && document.body.classList.contains('vf-regie-montee')";
const LARGEURS = [375, 700, 768, 1000, 1440];

await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ });
  await s.naviguer(url + '#sans-visite');
  await s.attendre(PRET, 'régie montée');
  if (scenario === 'montage') {
    const lire = () => s.ev(`({ stage: getComputedStyle(document.getElementById('stage')).display, h2: [...document.querySelectorAll('#vf-equipe h2')].map((e) => e.textContent),
      mains: [...document.querySelectorAll('main, [role="main"]')].filter((e) => e.getClientRects().length > 0).map((e) => e.id || e.tagName) })`);
    const base = await attendreEtStabiliser(lire, (v) => v && v.h2 && v.h2.length === 4, { pas: 150, max: 8000 });
    const defil = {};
    for (const w of LARGEURS) {
      await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 900, deviceScaleFactor: 1, mobile: false });
      defil[w] = await attendreEtStabiliser(() => s.ev('document.documentElement.scrollWidth - document.documentElement.clientWidth'), (v) => typeof v === 'number', { pas: 150, max: 6000 });
    }
    return { ...base, defil };
  }
  if (scenario === 'fuite-verrou') {
    await s.attendre("window.__es.some((e) => e.url.includes('/api/vf/events'))", 'flux');
    const alea = Math.random().toString(36).slice(2, 10), sent = { id: 'sess-' + alea, chemin: ['', 'zz' + alea, 'verrou-' + alea].join('/'), emplacement: 'git-' + alea, bail: 7771771 + alea.length };
    const entree = (extra) => ({ ws: 'fiab', scope: 'phase', phase: '73', step: 'exec-73', tenu: true, stale: false, ageS: 3, ttl: 1800, progressAgeS: 3, owner: 'vf-dev-manager-p73', leaseS: 57, ...extra });
    const emettre = (e) => s.ev(`window.__es.find((x) => x.url.includes('/api/vf/events')).__emit('lock', { seq: ${e.seq}, at: Date.now(), verrous: { etat: 'lue', plat: false, liste: [${JSON.stringify(e.entree)}] } })`);
    await emettre({ seq: 9001, entree: entree({}) });
    const ligne = () => s.ev("[...document.querySelectorAll('#vf-equipe .vf-rg-mission')].map((e) => e.textContent).join(' | ')");
    const positif = await attendreEtStabiliser(ligne, (v) => /verrou/i.test(String(v)), { pas: 150, max: 8000 });
    await emettre({ seq: 9002, entree: entree({ session_ids: [sent.id], location: sent.chemin, lock_location: sent.emplacement, generation: sent.emplacement, lease_ttl_s: sent.bail, guard_effective: true }) });
    await attendreEtStabiliser(ligne, (v) => /verrou/i.test(String(v)), { pas: 150, max: 4000 });
    const jeton = await s.ev("(window.VF_ETAT && window.VF_ETAT.jeton()) || (window.VF_COCKPIT_SERVER || {}).token || ''");
    const exporte = await s.ev(`fetch('/api/export', { method: 'POST', headers: { 'content-type': 'application/json', 'x-vf-cockpit-token': ${JSON.stringify(jeton)} }, body: JSON.stringify({ include: {}, flows: [] }) })
      .then(async (r) => ({ statut: r.status, texte: (await r.text()).slice(0, 4000000) })).catch((e) => ({ statut: 0, texte: String(e) }))`);
    const pages = await s.ev('({ html: document.documentElement.outerHTML, local: JSON.stringify(Object.entries(localStorage)), session: JSON.stringify(Object.entries(sessionStorage)) })');
    const valeurs = [sent.id, sent.chemin, sent.emplacement, String(sent.bail)], dans = (t) => valeurs.filter((v) => String(t).includes(v));
    return { positif, jeton: !!jeton, exportStatut: exporte && exporte.statut, html: dans(pages.html), local: dans(pages.local), session: dans(pages.session), export: dans(exporte && exporte.texte) };
  }
  return { erreur: 'scénario inconnu : ' + scenario };
}, { csp: true });
