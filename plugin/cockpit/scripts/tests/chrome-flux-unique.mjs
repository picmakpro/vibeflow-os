// chrome-flux-unique.mjs — une page n'ouvre qu'UN flux d'événements, quatre onglets ouverts répondent (AUDC-H1, scénario « trois onglets »).
// Usage : node chrome-flux-unique.mjs <chrome> <port> <fichierCarte>
//   Chrome plafonne à six connexions par origine : deux flux par page saturent le serveur à la troisième page et la quatrième ne charge jamais.
//   La page 1 (Code) compte les EventSource qu'elle crée (script posé avant ses scripts), trois autres onglets s'ouvrent (Projet, Équipe, une
//   quatrième page), puis on relève : flux de la page 1, onglets vus du serveur (/api/status), flux du direct (/api/vf/etat), temps de réponse
//   d'une requête d'état depuis la page 1, et le rechargement automatique (la carte est réécrite : la page 1 doit se recharger seule).
//   Rend sur une ligne { flux, tabs, clients, ms, ok, rechargee } ou { erreur }.
import fs from 'node:fs';
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, port, carte] = process.argv;
const base = `http://127.0.0.1:${port}`;
const COMPTEUR = `(() => { window.__flux = []; const O = window.EventSource; if (!O) return; window.EventSource = function (u, o) { window.__flux.push(String(u).replace(/\\?.*/, '')); return new O(u, o); }; window.EventSource.prototype = O.prototype; })();`;
await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: COMPTEUR });
  await s.naviguer(`${base}/`);
  await s.attendre('!!(window.__vfLive && window.__vfLive.connected)', 'direct connecté (page 1)');
  await s.ev('window.__marque = 1');
  for (const chemin of ['/project.html', '/equipe.html', '/']) await s.send('Target.createTarget', { url: `${base}${chemin}` });
  const lire = `(async () => { const t = performance.now(); const h = { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token };
    try { const a = await fetch('/api/status', { headers: h, cache: 'no-store', signal: AbortSignal.timeout(4000) }).then((r) => r.json());
      const b = await fetch('/api/vf/etat', { headers: h, cache: 'no-store', signal: AbortSignal.timeout(4000) }).then((r) => r.json());
      return { ok: true, ms: Math.round(performance.now() - t), tabs: a.tabs, clients: b.clients }; } catch (e) { return { ok: false, ms: Math.round(performance.now() - t), erreur: e.name }; } })()`;
  let m = null; const fin = Date.now() + 20000;
  do { await pause(500); m = await s.ev(lire); } while (!(m && m.ok && m.tabs >= 4) && Date.now() < fin); // quatre pages ouvertes, ou l'échéance : l'assertion juge
  const flux = await s.ev('window.__flux');
  fs.utimesSync(carte, new Date(), new Date()); // la carte est « reconstruite » : toutes les pages se rechargent
  let rechargee = false; const fin2 = Date.now() + 15000;
  while (!rechargee && Date.now() < fin2) { await pause(500); try { rechargee = (await s.ev('window.__marque')) === undefined; } catch {} }
  return { flux, tabs: m?.tabs ?? null, clients: m?.clients ?? null, ms: m?.ms ?? null, ok: !!m?.ok, brut: m ?? null, rechargee };
}, { csp: false });
