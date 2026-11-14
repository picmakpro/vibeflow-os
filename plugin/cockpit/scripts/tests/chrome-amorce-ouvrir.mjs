// chrome-amorce-ouvrir.mjs — témoin du chemin RÉEL de l'ouverture du terminal (AUDC-B-03 bis) : la page de redirection écrite par le lanceur
// est ouverte par Chrome comme fichier local (file://), suit sa redirection vers le cockpit, et on relève ce que le navigateur ENVOIE.
// Entrée : <chrome> <json { ouvert, P, attenteMs }> ; sortie : UNE ligne JSON { sfs, sfm, sfd, statut, href } ou { erreur }.
//   ouvert = fichier où l'ouvreur factice consigne son argument (le chemin de la page) ; P = port du cockpit.
// Aucune attente à durée fixe pour décider d'un état : on attend l'événement (réponse du document du cockpit) avec une échéance bornée.
import { spawn } from 'node:child_process'; import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';
const [, , chrome, brut] = process.argv; const { ouvert, P, attenteMs = 60000 } = JSON.parse(brut);
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const home = (() => { try { return os.userInfo().homedir; } catch { return process.env.HOME; } })();
const dir = fs.mkdtempSync(path.join(os.tmpdir(), `cdp-chrome-${process.env.VF_CDP_TAG ? process.env.VF_CDP_TAG + '-' : ''}`));
const ch = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--remote-debugging-port=0', `--user-data-dir=${dir}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'], env: { ...process.env, HOME: home } });
let sorti = false; const sortie = new Promise((r) => ch.once('exit', () => { sorti = true; r(); }));
const fermer = async () => { try { ch.kill('SIGKILL'); } catch {} if (!sorti) await Promise.race([sortie, pause(3000)]); try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} };
const fin = async (o) => { await fermer(); console.log(JSON.stringify(o)); process.exit(0); };
for (const s of ['SIGTERM', 'SIGINT']) process.on(s, () => fin({ erreur: `interrompu (${s})` }));
try {
  const port = await new Promise((ok, ko) => { let b = ''; const t = setTimeout(() => ko(new Error('Chrome sans port')), 120000);
    ch.stderr.on('data', (d) => { b += d; const m = /ws:\/\/127\.0\.0\.1:(\d+)\//.exec(b); if (m) { clearTimeout(t); ok(m[1]); } }); ch.once('exit', (c) => ko(new Error(`Chrome arrêté (${c})`))); });
  const cible = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT' })).json();
  const ws = new WebSocket(cible.webSocketDebuggerUrl); let id = 0; const pend = new Map(); const urls = new Map(); const extra = new Map(); const rep = [];
  ws.onmessage = (e) => { const j = JSON.parse(e.data);
    if (j.id && pend.has(j.id)) { pend.get(j.id)(j.result); pend.delete(j.id); return; }
    const p = j.params || {};
    if (j.method === 'Network.requestWillBeSent') urls.set(p.requestId, { url: p.request.url, type: p.type });
    if (j.method === 'Network.requestWillBeSentExtraInfo') extra.set(p.requestId, p.headers);
    if (j.method === 'Network.responseReceived') rep.push({ requestId: p.requestId, url: p.response.url, status: p.response.status, type: p.type }); };
  await new Promise((ok, ko) => { ws.onopen = ok; ws.onerror = () => ko(new Error('connexion CDP impossible')); });
  const send = (method, params = {}) => new Promise((ok) => { const i = ++id; pend.set(i, ok); ws.send(JSON.stringify({ id: i, method, params })); });
  await send('Network.enable'); await send('Page.enable');
  // l'ouvreur factice a consigné le chemin de la page : on l'ouvre comme le fait le système (fichier local)
  const dl = Date.now() + attenteMs; let page = '';
  while (Date.now() < dl) { try { page = fs.readFileSync(ouvert, 'utf8').split('\n')[0].trim(); } catch {} if (page) break; await pause(50); }
  if (!page) await fin({ erreur: "l'ouvreur factice n'a rien consigné" });
  await send('Page.navigate', { url: 'file://' + page });
  let doc = null; // réponse du document du cockpit (project.html), quel qu'en soit le code
  while (Date.now() < dl) { doc = rep.find((r) => r.type === 'Document' && r.url.startsWith(`http://127.0.0.1:${P}/`)); if (doc) break; await pause(50); }
  if (!doc) await fin({ erreur: 'aucune réponse du cockpit pour le document', vus: rep.map((r) => `${r.status} ${r.url.slice(0, 60)}`) });
  const dx = Date.now() + 5000; while (!extra.has(doc.requestId) && Date.now() < dx) await pause(50); // les en-têtes bruts arrivent par un événement frère
  const h = Object.fromEntries(Object.entries(extra.get(doc.requestId) || {}).map(([k, v]) => [k.toLowerCase(), v])), g = (k) => h[k] ?? null;
  // la suite du chemin : la page Projet monte le cadre du terminal, qui échange la clé (POST /amorce) ; on attend cet échange (ou son absence à l'échéance)
  let echange = null; const dz = Date.now() + (doc.status === 200 ? 30000 : 0); // refus : rien à attendre
  while (Date.now() < dz) { echange = rep.find((r) => /\/amorce$/.test(r.url)); if (echange) break; await pause(100); }
  const vus = rep.filter((r) => r.type === 'Document' || /\/amorce$/.test(r.url) || r.status >= 400).map((r) => `${r.status} ${r.url.replace(/^http:\/\/127\.0\.0\.1:\d+/, '').replace(/^file:.*/, 'file://…').slice(0, 40)}`);
  const href = (await send('Runtime.evaluate', { expression: 'location.href', returnByValue: true }))?.result?.value;
  await fin({ sfs: g('sec-fetch-site'), sfm: g('sec-fetch-mode'), sfd: g('sec-fetch-dest'), statut: doc.status, amorce: echange ? echange.status : null, vus, href: String(href || '').replace(/[?#].*/, '?…') });
} catch (e) { await fin({ erreur: String(e.message) }); }
