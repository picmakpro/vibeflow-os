// chrome-direct-coupe.mjs — une coupure du direct se dit à temps et la bannière se retire seule au retour (AUDC-M9).
// Usage : node chrome-direct-coupe.mjs <chrome> <url>
//   Coupure simulée dans le navigateur : réseau hors ligne (nouvelles requêtes en échec) puis perte du flux signalée par le crochet de la page
//   (window.VF_COCKPIT_STREAM_LOST, le même appel que fait la page quand son flux tombe). Temps en millisecondes depuis la coupure :
//   à 5,5 s la pastille dit « Direct coupé » (classe, libellé, infobulle) sans bannière ; la bannière arrive à 15 s environ (jamais avant 13 s) ;
//   au retour du réseau elle se retire seule et le flux est rouvert. Rend { avantCoupure (avec un agent actif), a5, avant13, tBanniere, tRetrait, reouvert } ou { erreur } (tBanniere et tRetrait : null si jamais).
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, url] = process.argv;
await executer(chrome, async (s) => {
  // les flux créés par la page sont gardés (window.__es) : un événement `who` posé à la main donne un agent actif à la pastille
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: "(() => { window.__es = []; const O = window.EventSource; if (!O) return; window.EventSource = function (u, o) { const e = new O(u, o); window.__es.push(e); return e; }; window.EventSource.prototype = O.prototype; })();" });
  await s.naviguer(url);
  await s.attendre('!!(window.__vfLive && window.__vfLive.connected)', 'direct connecté avant la coupure');
  const lire = () => s.ev("(() => { const b = document.getElementById('vf-lock'); return { pulse: b ? getComputedStyle(b.querySelector('.dot')).animationName : null, cls: b ? b.className : null, txt: b ? b.textContent : null, title: b ? b.title : null, banniere: !!document.getElementById('vf-reco') }; })()");
  // AU MOINS un agent actif (session) avant la coupure : la pastille est « au travail » (classe held), puis la coupure doit l'emporter
  await s.ev("window.__es.find((e) => /vf\\/events/.test(e.url)).dispatchEvent(new MessageEvent('who', { data: JSON.stringify({ seq: 1, who: { workers: [{ kind: 'session', id: 'agent-essai', etat: 'actif' }], sources: {} } }) }))");
  const avantCoupure = await lire();
  await s.send('Network.enable'); await s.send('Network.emulateNetworkConditions', { offline: true, latency: 0, downloadThroughput: -1, uploadThroughput: -1 });
  await s.ev("window.__reouvert = 0; window.VF_COCKPIT_STREAM_LOST('direct', () => { window.__reouvert++; })");
  const t0 = Date.now(); const depuis = () => Date.now() - t0;
  await pause(5500 - depuis()); const a5 = await lire();
  await pause(13000 - depuis()); const avant13 = await lire();
  let tBanniere = null; while (depuis() < 20000 && tBanniere === null) { if ((await lire()).banniere) tBanniere = depuis(); else await pause(250); }
  await s.send('Network.emulateNetworkConditions', { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1 });
  const tRet0 = depuis(); let tRetrait = null; while (depuis() - tRet0 < 8000 && tRetrait === null) { if (!(await lire()).banniere) tRetrait = depuis() - tRet0; else await pause(250); }
  return { avantCoupure, a5, avant13, tBanniere, tRetrait, reouvert: await s.ev('window.__reouvert') };
});
