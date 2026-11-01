// chrome-cdp.mjs — client minimal du protocole DevTools pour les suites du cockpit (aucune dépendance : WebSocket et fetch de node).
// Usage : node chrome-cdp.mjs <chrome> <attenteMs> <expressionJs> <url> [<url> ...]
//   ouvre UN Chrome headless, charge chaque URL (changement de hash seul : navigation complète quand même), attend, évalue l'expression
//   (JSON-sérialisable) dans la page et rend { resultats: [{ url, valeur, violations }] } sur une ligne.
// Le HOME réel est rendu à Chrome (REAL_HOME) : sous un HOME jetable il ne démarre pas sur macOS ; son profil est un dossier jetable.
import { spawn } from 'node:child_process'; import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';
const [, , chrome, wait, expr, ...urls] = process.argv;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cdp-chrome-'));
const ch = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--no-first-run', '--no-default-browser-check', `--user-data-dir=${dir}`, '--remote-debugging-port=0', 'about:blank'],
  { stdio: ['ignore', 'ignore', 'pipe'], env: { ...process.env, HOME: process.env.REAL_HOME || process.env.HOME } });
const fin = (o) => { try { ch.kill('SIGKILL'); } catch {} try { fs.rmSync(dir, { recursive: true, force: true }); } catch {} console.log(JSON.stringify(o)); process.exit(0); };
setTimeout(() => fin({ erreur: 'delai' }), 120000);
let buf = ''; let started = false;
ch.stderr.on('data', async (d) => {
  buf += d; const m = /ws:\/\/127\.0\.0\.1:(\d+)\//.exec(buf); if (!m || started) return; started = true;
  try {
    const t = await (await fetch(`http://127.0.0.1:${m[1]}/json/new?about:blank`, { method: 'PUT' })).json();
    const ws = new WebSocket(t.webSocketDebuggerUrl); let id = 0; const pend = new Map(); let violations = [];
    const send = (method, params = {}) => new Promise((res) => { const i = ++id; pend.set(i, res); ws.send(JSON.stringify({ id: i, method, params })); });
    ws.onmessage = (e) => { const j = JSON.parse(e.data); if (j.id && pend.has(j.id)) pend.get(j.id)(j.result); else if (j.method === 'Log.entryAdded' && /Content Security Policy|Refused to/i.test(j.params.entry.text)) violations.push(j.params.entry.text.slice(0, 160)); };
    await new Promise((r) => (ws.onopen = r));
    await send('Log.enable'); await send('Page.enable');
    const resultats = [];
    for (const url of urls) {
      violations = [];
      await send('Page.navigate', { url: 'about:blank' });
      await send('Page.navigate', { url });
      await new Promise((r) => setTimeout(r, Number(wait)));
      const r = await send('Runtime.evaluate', { expression: `JSON.stringify((${expr}))`, returnByValue: true });
      let valeur = null; try { valeur = JSON.parse(r?.result?.value); } catch {}
      resultats.push({ url, valeur, violations });
    }
    fin({ resultats });
  } catch (e) { fin({ erreur: String(e.message) }); }
});
