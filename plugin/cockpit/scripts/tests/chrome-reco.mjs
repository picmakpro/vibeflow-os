// chrome-reco.mjs — le cockpit perd son serveur : combien de requêtes la page émet-elle, et que dit-elle à la fin ? (E-6, CKPT-05)
// Usage : node chrome-reco.mjs <chrome> <url> <pidServeur> <port>
//   charge la page, raccourcit les délais de recul (vite 200 ms jusqu'à 1,5 s, puis 600 ms, arrêt à 4 s), arrête le serveur, puis écoute son port :
//   chaque connexion entrante est comptée et coupée. Rend sur une ligne { rapide, lent, tard, banniere, bouton, apresClic } ou { erreur }.
//   rapide = connexions pendant les 1,5 s qui suivent l'arrêt · lent = entre 1,7 s et 3,9 s · tard = entre 5 s et 9 s (doit être 0 : arrêt)
//   banniere = texte du message d'arrêt · apresClic = connexions dans la seconde et demie qui suit le clic sur « Réessayer ».
import { spawn } from 'node:child_process'; import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path'; import net from 'node:net';
const [, , chrome, url, pid, port] = process.argv;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cdp-reco-'));
const ch = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--no-first-run', '--no-default-browser-check', `--user-data-dir=${dir}`, '--remote-debugging-port=0', 'about:blank'],
  { stdio: ['ignore', 'ignore', 'pipe'], env: { ...process.env, HOME: process.env.REAL_HOME || process.env.HOME } });
let ecouteur = null;
const fin = (o) => { try { ch.kill('SIGKILL'); } catch {} try { ecouteur?.close(); } catch {} try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} console.log(JSON.stringify(o)); process.exit(0); };
setTimeout(() => fin({ erreur: 'delai' }), 90000);
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));
let buf = '', started = false;
ch.stderr.on('data', async (d) => {
  buf += d; const m = /ws:\/\/127\.0\.0\.1:(\d+)\//.exec(buf); if (!m || started) return; started = true;
  try {
    const t = await (await fetch(`http://127.0.0.1:${m[1]}/json/new?about:blank`, { method: 'PUT' })).json();
    const ws = new WebSocket(t.webSocketDebuggerUrl); let id = 0; const pend = new Map();
    const send = (method, params = {}) => new Promise((res) => { const i = ++id; pend.set(i, res); ws.send(JSON.stringify({ id: i, method, params })); });
    ws.onmessage = (e) => { const j = JSON.parse(e.data); if (j.id && pend.has(j.id)) pend.get(j.id)(j.result); };
    await new Promise((r) => (ws.onopen = r));
    await send('Page.enable'); await send('Page.navigate', { url });
    const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true }))?.result?.value;
    for (let i = 0; i < 50 && !(await ev('window.__vfLive && window.__vfLive.connected')); i++) await attendre(200);
    if (!(await ev('window.__vfLive && window.__vfLive.connected'))) return fin({ erreur: 'le direct ne s\'est pas connecté avant la coupure' });
    await ev('window.__vfLive.reco = Object.assign(window.__vfLive.reco || {}, { vite: 200, lent: 600, bascule: 1500, fin: 4000 })');
    process.kill(Number(pid), 'SIGTERM');
    const t0 = []; let t_kill = Date.now();
    for (let i = 0; i < 100; i++) { // le port se libère, puis on l'écoute
      try { ecouteur = await new Promise((res, rej) => { const s = net.createServer((c) => { t0.push(Date.now() - t_kill); c.on('error', () => {}); c.destroy(); }); s.once('error', rej); s.listen(Number(port), '127.0.0.1', () => res(s)); }); break; } catch { await attendre(50); }
    }
    if (!ecouteur) return fin({ erreur: 'port non récupéré' });
    t_kill = Date.now(); // l'écoute commence ici : les temps se comptent depuis cet instant
    await attendre(9000);
    const dans = (a, b) => t0.filter((x) => x >= a && x < b).length;
    const rapide = dans(0, 1500), lent = dans(1700, 3900), tard = dans(5000, 9000);
    const banniere = await ev("(document.getElementById('vf-reco')||{}).innerText || ''");
    const avant = t0.length;
    await ev("(document.querySelector('#vf-reco button')||{click(){}}).click()");
    await attendre(1500);
    fin({ rapide, lent, tard, banniere, bouton: await ev("!!document.querySelector('#vf-reco button') || (window.__vfLive.sondages > 0 && !window.__vfLive.abandon)"), apresClic: t0.length - avant, total: avant });
  } catch (e) { fin({ erreur: String(e.message) }); }
});
