#!/usr/bin/env node
// vf-cockpit-who — « qui est au travail ? » (socle du cockpit, P67-D-12, promu du spike 004). Lecture seule.
// Exports : collectWho(root, opts) -> schéma vibeflow/cockpit-who@1 (JAMAIS de champ `doing`, P67-D-14)
//           revealDoing(root, id, opts) -> schéma vibeflow/cockpit-doing@1 (dernière commande, à la demande)
// Quatre sources disque : sessions Claude Code (~/.claude/projects), sous-agents (meta.json), verrous et
// registre (driver-lock.sh, résolu hors de l'arbre observé : T-67-06), DAG de mission (nœuds running).
// Chaque source rend son état (lue, absente, erreur, forme-inconnue) : un « personne » n'est jamais aveugle.
// CLI : node vf-cockpit-who.mjs <root> [--fresh 180] [--json]
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import { driverLockScript, gitCommonDir, resolveScriptsDir } from './vf-cockpit-paths.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const sh = (cmd, args, cwd) => { try { return execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }); } catch (e) { return e.stdout || ''; } };
const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
const mtime = (f) => { try { return fs.statSync(f).mtimeMs; } catch { return 0; } };
const readJson = (f) => { try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return null; } };

// les listes de clés vérifiées sur Claude Code viennent du contrat versionné, pas du code
const IFACE = readJson(path.join(HERE, 'vf-cockpit-interface.json')) || {};
const CC = IFACE.claudeCode || {};
const REQ_TR = CC.transcript?.requis || ['cwd', 'type', 'message', 'timestamp', 'sessionId'];
const REQ_META = CC.metaSousAgent?.requis || ['agentType', 'description'];

// dernière ligne user/assistant d'un jsonl, en ne lisant que la fin du fichier (256 Kio)
const tail = (f, bytes = 256 << 10) => {
  try {
    const fd = fs.openSync(f, 'r'); const size = fs.fstatSync(fd).size; const len = Math.min(size, bytes);
    const buf = Buffer.alloc(len); fs.readSync(fd, buf, 0, len, size - len); fs.closeSync(fd);
    for (const l of buf.toString('utf8').split('\n').reverse()) {
      if (!l.trim()) continue;
      let d; try { d = JSON.parse(l); } catch { continue; }
      if (d && (d.type === 'user' || d.type === 'assistant')) return d;
    }
  } catch {}
  return null;
};
const formeOk = (d) => !!d && REQ_TR.every((k) => k in d);

// collecte interne : les travailleurs gardent `_tr` (chemin du transcript) hors de la sortie publique
function gather(root, { fresh = 180, ttl = Number(process.env.VF_DRIVER_TTL) || 1800, now = Date.now(), home = os.homedir(), scriptsDir } = {}) {
  root = path.resolve(root);
  const sources = {}; const workers = [];
  const porcelain = sh('git', ['-C', root, 'worktree', 'list', '--porcelain'], root);
  const branchOf = new Map(porcelain.split('\n\n').map((b) => [/^worktree (.*)$/m.exec(b)?.[1], /^branch refs\/heads\/(.*)$/m.exec(b)?.[1] || (b.includes('detached') ? '(détachée)' : '')]).filter(([t]) => t && fs.existsSync(t)).map(([t, br]) => [fs.realpathSync(t), br]));
  const trees = porcelain.split('\n').filter((l) => l.startsWith('worktree ')).map((l) => l.slice(9)).filter((t) => fs.existsSync(t)).map((t) => fs.realpathSync(t));
  if (!trees.length) trees.push(root);
  const real = (p) => { try { return fs.realpathSync(p); } catch { return p; } };
  const inScope = (cwd) => { if (!cwd) return null; const r = real(cwd); return trees.filter((t) => r === t || r.startsWith(t + path.sep)).sort((a, b) => b.length - a.length)[0] || null; };
  const label = (t) => (t === trees[0] ? 'arbre principal' : path.relative(trees[0], t) || t);
  // le cwd d'un transcript reste celui du lancement : on préfère l'arbre le plus profond cité par le dernier appel
  const byActivity = (d, fallback) => {
    const txt = JSON.stringify(d?.message?.content || '');
    const hit = trees.filter((t) => t !== trees[0] && txt.includes(t)).sort((a, b) => b.length - a.length)[0];
    return hit ? { tree: hit, how: 'activité' } : { tree: fallback, how: 'cwd' };
  };

  // 1 + 2 — sessions et sous-agents
  const projects = path.join(home, '.claude', 'projects');
  if (!fs.existsSync(projects)) sources.sessions = { etat: 'absente', path: projects };
  else {
    let scanned = 0, live = 0, subLive = 0, formeInconnue = 0;
    for (const slug of ls(projects)) {
      const dir = path.join(projects, slug);
      for (const f of ls(dir).filter((x) => x.endsWith('.jsonl'))) {
        const file = path.join(dir, f); const age = (now - mtime(file)) / 1000;
        const id = f.slice(0, -6); const subDir = path.join(dir, id, 'subagents');
        const subs = [];
        for (const m of ls(subDir).filter((x) => x.endsWith('.meta.json'))) {
          const meta = readJson(path.join(subDir, m)) || {};
          const tr = path.join(subDir, m.replace(/\.meta\.json$/, '.jsonl'));
          const sAge = (now - mtime(tr)) / 1000;
          if (meta.finished || sAge >= fresh) continue;
          if (!REQ_META.every((k) => k in meta)) { formeInconnue++; continue; }
          subs.push({ meta, tr, age: sAge, agentId: m.replace(/^agent-|\.meta\.json$/g, '') });
        }
        if (age > fresh && !subs.length) continue;
        scanned++;
        const last = tail(file);
        if (last && !formeOk(last)) { formeInconnue++; continue; }
        const tree = inScope(last?.cwd);
        if (!tree) continue;
        if (age <= fresh) {
          live++;
          const at = byActivity(last, tree);
          workers.push({ kind: 'session', id, tree: label(at.tree), treeBy: at.how, branch: at.how === 'activité' ? branchOf.get(at.tree) : last.gitBranch || '', cwd: last.cwd, ageS: Math.round(age), lastAt: last.timestamp, source: 'transcript', _tr: file });
        }
        for (const s of subs) {
          subLive++;
          const sl = tail(s.tr), at = byActivity(sl, inScope(sl?.cwd) || tree);
          workers.push({ kind: 'subagent', id: s.agentId, parent: id, role: s.meta.agentType, task: s.meta.description || '', depth: s.meta.spawnDepth ?? null, background: s.meta.requestShape === 'background',
            tree: label(at.tree), treeBy: at.how, branch: at.how === 'activité' ? branchOf.get(at.tree) : sl?.gitBranch || last?.gitBranch || '', ageS: Math.round(s.age), source: 'subagent-meta', _tr: s.tr });
        }
      }
    }
    const inconnue = formeInconnue > 0 && live + subLive === 0;
    sources.sessions = { etat: inconnue ? 'forme-inconnue' : 'lue', path: projects, recentFiles: scanned, liveSessions: live, liveSubagents: subLive, formeInconnue };
  }

  // 3 — verrous et registre (script résolu hors de l'arbre observé)
  const dl = driverLockScript({ scriptsDir: scriptsDir || resolveScriptsDir(HERE), labRoot: root, home });
  const common = gitCommonDir(root) || '';
  if (dl.etat === 'absent') sources.locks = { etat: 'absente' };
  else {
    const DL = dl.chemin; let st = {};
    try { st = JSON.parse(sh('bash', [DL, 'status', '--all'], root)); } catch { sources.locks = { etat: 'erreur' }; }
    for (const l of (st.locks || []).filter((x) => x.present)) workers.push({ kind: 'lock', id: l.owner, task: l.step, tree: l.ws ? `compartiment ${l.ws}` : l.scope, ageS: l.age_seconds, stale: !!l.stale, children: l.children_running, source: 'driver-lock' });
    const wsList = ['', ...ls(path.join(common, 'vf-driver', 'ws'))];
    let reg = 0;
    for (const ws of wsList) {
      let o = {}; try { o = JSON.parse(sh('bash', [DL, 'orphans', ...(ws ? [`--ws=${ws}`] : [])], root)); } catch {}
      const held = (st.locks || []).some((l) => l.present && !l.stale && (l.ws || '') === ws);
      for (const a of o.orphans || []) { reg++; workers.push({ kind: 'registered', id: a.agent_id, role: a.role, task: a.node || '', parent: a.parent || '', depth: a.depth ?? null, tree: ws ? `compartiment ${ws}` : 'dépôt', ageS: a.age_seconds, stale: !held, orphan: !held, source: 'registre' }); }
    }
    sources.locks ||= { etat: 'lue', held: (st.locks || []).filter((x) => x.present).length, registered: reg };
  }

  // 4 — DAG : nœuds running, dans .planning/ et dans le dossier commun des verrous
  const dagDirs = [path.join(root, '.planning'), ...ls(path.join(common, 'vf-driver', 'ws')).map((w) => path.join(common, 'vf-driver', 'ws', w)), path.join(common, 'vf-driver', 'repo')];
  let dags = 0, running = 0, staleNodes = 0;
  for (const d of dagDirs) for (const f of ls(d).filter((x) => x.endsWith('.dag.json'))) {
    dags++;
    const fp = path.join(d, f); const j = readJson(fp); if (!j) continue;
    let age = Math.round((now - mtime(fp)) / 1000);
    if (age <= ttl && (j.nodes || []).some((x) => x.status === 'running')) {
      const tracked = sh('git', ['-C', d, 'ls-files', '--error-unmatch', f], d).trim(), dirty = sh('git', ['-C', d, 'status', '--porcelain', '--', f], d).trim();
      const ct = Number(sh('git', ['-C', d, 'log', '-1', '--format=%ct', '--', f], d).trim());
      if (tracked && !dirty && ct) age = Math.round(now / 1000 - ct); // contenu identique au commit : écrit au plus tard à cette date
    }
    const stale = age > ttl;
    for (const n of (j.nodes || []).filter((x) => x.status === 'running')) { running++; if (stale) staleNodes++; workers.push({ kind: 'dag-node', id: n.id, role: n.stage || '', task: (n.step || '').slice(0, 100), tree: path.relative(root, d) || d, dag: f, ageS: age, stale, source: 'dag' }); }
  }
  sources.dags = { etat: 'lue', files: dags, running, stale: staleNodes };
  return { at: new Date(now).toISOString(), root, trees: trees.map(label), fresh, workers, sources };
}

export function collectWho(root, opts = {}) {
  const g = gather(root, opts);
  const workers = g.workers.map(({ _tr, ...w }) => w);
  return { schema: 'vibeflow/cockpit-who@1', at: g.at, root: g.root, trees: g.trees, fresh: g.fresh, busy: workers.some((w) => !w.stale), workers, sources: g.sources };
}

// tracer : implémentée en tâche 3
export function revealDoing(root, id) {
  return { schema: 'vibeflow/cockpit-doing@1', id, doing: null, erreur: 'non-implemente' };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const root = process.argv[2] && !process.argv[2].startsWith('--') ? process.argv[2] : '.';
  const fresh = Number(process.argv[process.argv.indexOf('--fresh') + 1]) || 180;
  const r = collectWho(root, { fresh });
  if (process.argv.includes('--json')) { console.log(JSON.stringify(r, null, 1)); process.exit(0); }
  console.log(`${r.busy ? 'Au travail' : 'Personne au travail'} — ${r.workers.length} signal(aux) · arbres : ${r.trees.join(', ')}`);
  for (const w of r.workers) console.log(`  ${w.kind.padEnd(10)} ${String(w.role || '').padEnd(16)} ${String(w.tree).padEnd(34)} ${w.ageS != null ? String(w.ageS).padStart(8) + ' s' : '          '}${w.orphan ? ' ORPHELIN' : w.stale ? ' PÉRIMÉ' : ''}  ${w.task || ''}`.slice(0, 180));
  console.log('sources :', JSON.stringify(r.sources));
}
