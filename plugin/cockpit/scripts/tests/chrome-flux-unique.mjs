// chrome-flux-unique.mjs — les onglets d'un même lab dans un même Chrome ne tiennent qu'UN flux d'événements (SOCL-18, AUDC-H1, P79-D-14).
// Usage : node chrome-flux-unique.mjs <chrome> <port> <fichierCarte> <nombre d'onglets> <scénario>
//   Chrome plafonne à six connexions par origine : un flux par onglet sature le serveur au septième et l'onglet ne charge jamais.
//   Onglet 1 (Code) via la session, les autres (Projet, Équipe, Code en alternance) via ouvrirOnglet, chacun avec l'amorce de comptage des flux.
//   Scénario « partage » : comptes de flux construits, rôles, flux vus du serveur, lecture de /api/vf/state par le dernier onglet, un `who` émis
//   sur le flux de l'élu atteint tous les onglets, la carte reconstruite les recharge tous. Les lectures se font dans la page avec SON jeton :
//   seuls des booléens, des nombres et des adresses sans paramètre sortent. Rend une ligne JSON, ou { erreur }.
//   (le `who` d'essai porte un verrou, jamais une session : la page Équipe se recharge d'elle-même sur un agent inconnu.)
//   Scénario « complet » : tous les onglets passent par ouvrirOnglet (l'élu doit pouvoir se fermer sans fermer la session) ; en plus : l'élu fermé, un autre
//   onglet reprend sans rechargement (marqueur de page, suite de connexion reprise puis ouvert, jeton de SA page, un flux compté), puis la carte reconstruite.
import fs from 'node:fs';
import { executer, pause, stabiliser } from './chrome-session.mjs';
import { ouvrirOnglet, AMORCE_FLUX } from './chrome-onglets.mjs';

const [, , chrome, port, carte, nbArg, scenario = 'partage'] = process.argv;
const nombre = Math.max(1, Number(nbArg) || 2);
const base = `http://127.0.0.1:${port}`;
const CHEMINS = ['/', '/project.html', '/equipe.html', '/', '/', '/project.html', '/'];
const MARQUE = 'marqueur-flux-14';
const LIRE_SERVEUR = `(async () => { const t = performance.now(); const h = { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token };
  try { const a = await fetch('/api/status', { headers: h, cache: 'no-store', signal: AbortSignal.timeout(4000) }).then((r) => r.json());
    const b = await fetch('/api/vf/etat', { headers: h, cache: 'no-store', signal: AbortSignal.timeout(4000) }).then((r) => r.json());
    return { ok: true, tabs: a.tabs, clients: b.clients, ms: Math.round(performance.now() - t) };
  } catch (e) { return { ok: false, erreur: e.name }; } })()`;
const LIRE_ETAT = `(async () => { const t = performance.now(); try { const r = await fetch('/api/vf/state', { headers: { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token },
  cache: 'no-store', signal: AbortSignal.timeout(4000) }); return { code: r.status, ms: Math.round(performance.now() - t) }; } catch (e) { return { code: 0, ms: null }; } })()`;
const ROLE = '(window.VF_FLUX && window.VF_FLUX.role ? window.VF_FLUX.role() : null)';
const sansParam = (u) => String(u).replace(/\?.*/, '');

async function ouvrirTous(s, n, complet) {
  const onglets = [];
  if (!complet) { onglets.push({ ev: s.ev, charge: true }); await s.attendre('!!(window.__vfLive && window.__vfLive.connected)', 'direct connecté (onglet 1)'); await s.ev('window.__marque = 1'); }
  for (let i = onglets.length; i < n; i++) {
    try { const o = await ouvrirOnglet(s, base + CHEMINS[i % CHEMINS.length], { amorce: AMORCE_FLUX, echeance: 20000 }); await o.ev('window.__marque = 1'); onglets.push({ ...o, charge: true }); }
    catch (e) { onglets.push({ charge: false, erreur: e.message }); break; }
  }
  return onglets;
}
const vivants = (onglets) => onglets.filter((o) => o.charge);
async function resolus(onglets) { // rôle résolu et hello reçu, attente active bornée (l'assertion juge)
  const fin = Date.now() + 25000; let ok = false;
  while (!ok && Date.now() < fin) {
    ok = true;
    for (const o of vivants(onglets)) { let v = false; try { v = await o.ev(`!!(window.__vfLive && window.__vfLive.connected) && ${ROLE} !== null`); } catch { /* page en rechargement */ } if (!v) ok = false; }
    if (!ok) await pause(250);
  }
  return ok;
}
async function serveur(o, attendu) { // mesure stabilisée, ou l'échéance
  return stabiliser(() => o.ev(LIRE_SERVEUR), { pas: 500, max: attendu ? 12000 : 6000 });
}
async function whoAtteint(onglets, marque = MARQUE) {
  const roles = []; for (const o of vivants(onglets)) roles.push(await o.ev(ROLE));
  const elu = Math.max(0, roles.indexOf('elu')); const o = vivants(onglets)[elu];
  await o.ev(`window.__emit('who', { who: { workers: [{ kind: 'lock', id: '${marque}', tree: '.' }], sources: {} } })`);
  const fin = Date.now() + 8000; let tous = false;
  while (!tous && Date.now() < fin) {
    tous = true;
    for (const p of vivants(onglets)) { let v = false; try { v = await p.ev(`JSON.stringify(window.__vfLive.who || null).includes('${marque}')`); } catch { /* ignoré */ } if (!v) tous = false; }
    if (!tous) await pause(150);
  }
  return tous;
}
async function reprise(onglets, mesureur) { // FU3 : l'élu fermé, un autre reprend sans rechargement
  const R = {}; const v0 = vivants(onglets);
  for (const o of v0) await o.ev('window.__conns = []; window.VF_FLUX.surConnexion((e) => window.__conns.push(e))');
  const ie = []; for (const o of v0) ie.push(await o.ev(ROLE));
  const e = v0[ie.indexOf('elu')]; await e.fermer(); e.charge = false;
  const reste = vivants(onglets); let elu = null; const fin = Date.now() + 10000;
  while (!elu && Date.now() < fin) { for (const o of reste) { if ((await o.ev(ROLE)) === 'elu') elu = o; } if (!elu) await pause(200); }
  R.nouvelElu = !!elu;
  if (!elu) return R;
  await elu.attendre('window.__conns.slice(-1)[0] === "ouvert"', 'nouvel élu : connexion ouverte');
  R.marqueursIntacts = true; R.rechargesParChemin = []; for (const o of reste) if ((await o.ev('window.__marque')) !== 1) { R.marqueursIntacts = false; R.rechargesParChemin.push(await o.ev('location.pathname + ":" + (window.__vfLive.resync || 0)')); }
  R.suite = (await elu.ev('window.__conns')).slice(-2).join(); R.rolesApres = []; for (const o of reste) R.rolesApres.push(await o.ev(ROLE));
  R.jetonPropre = await elu.ev('window.__fluxUrl.slice(-1)[0].includes(encodeURIComponent(window.VF_COCKPIT_SERVER.token))');
  const m = await serveur(mesureur, true); R.tabs = m?.tabs ?? null; R.clients = m?.clients ?? null;
  R.whoAtteint = await whoAtteint(onglets, 'marqueur-reprise-14');
  return R;
}
async function rechargees(onglets) {
  fs.utimesSync(carte, new Date(), new Date()); // la carte est « reconstruite » : toutes les pages se rechargent par le flux partagé
  const fin = Date.now() + 15000; let n = 0;
  while (Date.now() < fin) {
    n = 0; for (const o of vivants(onglets)) { try { if ((await o.ev('window.__marque')) === undefined) n++; } catch { n++; } }
    if (n === vivants(onglets).length) break; await pause(300);
  }
  return n;
}

await executer(chrome, async (s) => {
  const complet = scenario === 'complet';
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_FLUX });
  if (!complet) await s.naviguer(`${base}/`);
  const onglets = await ouvrirTous(s, nombre, complet);
  const chargesAvant = onglets.map((o) => o.charge);
  const pret = await resolus(onglets);
  const mesureur = complet ? vivants(onglets).at(-1) : onglets[0];
  const dernier = vivants(onglets).at(-1);
  const m = await serveur(mesureur, true);
  const e = await dernier.ev(LIRE_ETAT);
  const roles = []; const flux = [];
  for (const o of vivants(onglets)) { roles.push(await o.ev(ROLE)); flux.push((await o.ev('window.__fluxUrl')).map(sansParam)); }
  const atteint = pret ? await whoAtteint(onglets) : false;
  const rep = complet && pret ? await reprise(onglets, mesureur) : null;
  const rech = await rechargees(onglets);
  await resolus(onglets);
  const m2 = await serveur(mesureur, true);
  return { scenario, charges: chargesAvant, erreurs: onglets.filter((o) => o.erreur).map((o) => o.erreur), pret, fluxParOnglet: flux, roles,
    tabs: m?.tabs ?? null, clients: m?.clients ?? null, etat200: e?.code === 200, msEtat: e?.ms ?? null, whoAtteint: atteint, reprise: rep, rechargees: rech,
    nbVivants: vivants(onglets).length, tabsApres: m2?.tabs ?? null, clientsApres: m2?.clients ?? null, violations: s.violations.length };
}, { csp: true });
