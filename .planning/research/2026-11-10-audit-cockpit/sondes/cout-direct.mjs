// Mesure en lecture seule : coût d'un tour du « filet » (5 s) et d'une régénération du graphe Projet.
// Compte et chronomètre les sous-processus synchrones (execFileSync) lancés par les modules du socle.
import cp from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { syncBuiltinESMExports } from 'node:module';
import { pathToFileURL } from 'node:url';
const [, , scripts, root] = process.argv;
let appels = [];
const orig = cp.execFileSync;
cp.execFileSync = function (cmd, args, opts) { const t = process.hrtime.bigint(); try { return orig.apply(this, arguments); } finally { appels.push([path.basename(String(cmd)), (args || []).filter((a) => !String(a).startsWith('-') && !/[=\/]/.test(String(a))).slice(0, 2).join(' '), Number(process.hrtime.bigint() - t) / 1e6]); } };
let lectures = 0, octets = 0;
const rf = fs.readFileSync; fs.readFileSync = function (f, o) { const r = rf.apply(this, arguments); lectures++; octets += r.length; return r; };
const rs = fs.readSync; let rsN = 0, rsO = 0; fs.readSync = function () { const n = rs.apply(this, arguments); rsN++; rsO += n; return n; };
const st = fs.statSync; let stats = 0; fs.statSync = function () { stats++; return st.apply(this, arguments); };
const rd = fs.readdirSync; let dirs = 0; fs.readdirSync = function () { dirs++; return rd.apply(this, arguments); };
syncBuiltinESMExports();
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { collectWho } = await imp('vf-cockpit-who.mjs');
const { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
const mesurer = (nom, fn, n = 5) => {
  const temps = []; let dernier = null;
  for (let i = 0; i < n; i++) { appels = []; lectures = octets = rsN = rsO = stats = dirs = 0; const t = process.hrtime.bigint(); const r = fn(); temps.push(Number(process.hrtime.bigint() - t) / 1e6); dernier = { r, appels: appels.slice(), lectures, octets, rsN, rsO, stats, dirs }; }
  temps.sort((a, b) => a - b);
  const sp = dernier.appels.reduce((s, a) => s + a[2], 0);
  const parCmd = {}; for (const a of dernier.appels) { const k = a[0] + ' ' + a[1]; (parCmd[k] ||= [0, 0]); parCmd[k][0]++; parCmd[k][1] += a[2]; }
  console.log(`\n== ${nom} : médiane ${temps[Math.floor(n / 2)].toFixed(0)} ms (min ${temps[0].toFixed(0)}, max ${temps[n - 1].toFixed(0)}) sur ${n} tours`);
  console.log(`   sous-processus synchrones : ${dernier.appels.length}, ${sp.toFixed(0)} ms cumulés (${(100 * sp / temps[Math.floor(n / 2)]).toFixed(0)} % du tour)`);
  console.log('   ' + Object.entries(parCmd).sort((a, b) => b[1][1] - a[1][1]).slice(0, 10).map(([k, [c, t]]) => `${k} ×${c} ${t.toFixed(0)}ms`).join(' · '));
  console.log(`   fichiers : readFileSync ×${dernier.lectures} (${(dernier.octets / 1024).toFixed(0)} Kio) · readSync ×${dernier.rsN} (${(dernier.rsO / 1024).toFixed(0)} Kio) · statSync ×${dernier.stats} · readdirSync ×${dernier.dirs}`);
  return dernier.r;
};
const w = mesurer('collectWho (un tour du filet, toutes les 5 s)', () => collectWho(root, { scriptsDir: scripts }));
console.log(`   -> ${w.workers.length} travailleurs, sources ${JSON.stringify(Object.fromEntries(Object.entries(w.sources).map(([k, v]) => [k, v.etat])))}, ${JSON.stringify(w).length} octets de JSON`);
const g = mesurer('buildProjectGraph (à chaque changement de .planning, 2 fois si retrait)', () => buildProjectGraph(root));
console.log(`   -> ${g.nodes.length} cartes, ${g.files.length} éléments, ${g.links.length} liens, ${JSON.stringify(g).length} octets de JSON`);
