#!/usr/bin/env node
// Spike 004 — « qui est au travail ? » sans dépendre d'un DAG dans l'arbre regardé. Croise quatre
// sources disque, lecture seule :
//   1. sessions Claude Code : ~/.claude/projects/<slug>/<id>.jsonl (mtime = pouls ; cwd et gitBranch
//      de la dernière ligne user/assistant) — retenues si leur cwd est dans le dépôt ou un worktree ;
//   2. sous-agents : <id>/subagents/agent-*.meta.json (agentType, description, spawnDepth, finished)
//      + mtime du transcript voisin ;
//   3. verrous de driver et registre des agents : driver-lock.sh status --all / orphans ;
//   4. DAG de mission : nœuds `running` dans .planning/ ET dans <git-common-dir>/vf-driver/ws/*.
// Chaque source rend aussi son état (lue, absente, en erreur) : un « personne » n'est jamais aveugle.
// usage: node who.mjs <root> [--fresh 180] [--json]
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const sh = (cmd, args, cwd) => { try { return execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }); } catch (e) { return e.stdout || ''; } };
const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
const mtime = (f) => { try { return fs.statSync(f).mtimeMs; } catch { return 0; } };

// dernière ligne user/assistant d'un jsonl, en ne lisant que la fin du fichier
const tail = (f, bytes = 256 << 10) => {
  try {
    const fd = fs.openSync(f, 'r'); const size = fs.fstatSync(fd).size; const len = Math.min(size, bytes);
    const buf = Buffer.alloc(len); fs.readSync(fd, buf, 0, len, size - len); fs.closeSync(fd);
    const lines = buf.toString('utf8').split('\n').reverse();
    for (const l of lines) { if (!l.includes('"cwd"')) continue; try { const d = JSON.parse(l); if (d.type === 'user' || d.type === 'assistant') return d; } catch {} }
  } catch {}
  return null;
};
const lastText = (d) => {
  const c = d?.message?.content; if (!c) return '';
  const s = typeof c === 'string' ? c : c.map((x) => x.text || (x.type === 'tool_use' ? `▸ ${x.name}${x.input?.description ? ' : ' + x.input.description : ''}` : '')).filter(Boolean).join(' ');
  return s.replace(/\s+/g, ' ').slice(0, 120);
};

export function collect(root, { fresh = 180, ttl = Number(process.env.VF_DRIVER_TTL) || 1800, now = Date.now(), home = os.homedir() } = {}) {
  root = path.resolve(root);
  const sources = {};
  const workers = [];
  // périmètre : le dépôt et ses worktrees
  const porcelain = sh('git', ['-C', root, 'worktree', 'list', '--porcelain'], root);
  const branchOf = new Map(porcelain.split('\n\n').map((b) => [/^worktree (.*)$/m.exec(b)?.[1], /^branch refs\/heads\/(.*)$/m.exec(b)?.[1] || (b.includes('detached') ? '(détachée)' : '')]).filter(([t]) => t && fs.existsSync(t)).map(([t, br]) => [fs.realpathSync(t), br]));
  const trees = porcelain.split('\n').filter((l) => l.startsWith('worktree ')).map((l) => l.slice(9))
    .filter((t) => fs.existsSync(t)).map((t) => fs.realpathSync(t)); // un worktree « prunable » n'a plus de dossier
  if (!trees.length) trees.push(root);
  const inScope = (cwd) => { if (!cwd) return null; const r = (() => { try { return fs.realpathSync(cwd); } catch { return cwd; } })(); return trees.filter((t) => r === t || r.startsWith(t + '/')).sort((a, b) => b.length - a.length)[0] || null; };
  const label = (t) => (t === trees[0] ? 'arbre principal' : path.relative(trees[0], t) || t);
  // le cwd du transcript reste celui du lancement : un `cd` dans une commande ne le change pas.
  // On préfère l'arbre le plus profond cité par le dernier appel d'outil (commande, chemin de fichier).
  const byActivity = (d, fallback) => {
    const txt = JSON.stringify(d?.message?.content || '');
    const hit = trees.filter((t) => t !== trees[0] && txt.includes(t)).sort((a, b) => b.length - a.length)[0];
    return hit ? { tree: hit, how: 'activité' } : { tree: fallback, how: 'cwd' };
  };

  // 1 + 2 — sessions et sous-agents
  const projects = path.join(home, '.claude', 'projects');
  if (!fs.existsSync(projects)) sources.sessions = { state: 'absente', path: projects };
  else {
    let scanned = 0, live = 0, subLive = 0;
    for (const slug of ls(projects)) {
      const dir = path.join(projects, slug);
      for (const f of ls(dir).filter((x) => x.endsWith('.jsonl'))) {
        const file = path.join(dir, f); const age = (now - mtime(file)) / 1000;
        const id = f.slice(0, -6); const subDir = path.join(dir, id, 'subagents');
        // une session muette peut avoir un sous-agent qui travaille : on regarde aussi ses sous-agents
        const subs = ls(subDir).filter((x) => x.endsWith('.meta.json')).map((m) => {
          let meta = {}; try { meta = JSON.parse(fs.readFileSync(path.join(subDir, m), 'utf8')); } catch {}
          const tr = path.join(subDir, m.replace(/\.meta\.json$/, '.jsonl'));
          return { meta, tr, age: (now - mtime(tr)) / 1000, agentId: m.replace(/^agent-|\.meta\.json$/g, '') };
        });
        const subsLive = subs.filter((s) => !s.meta.finished && s.age < fresh);
        if (age > fresh && !subsLive.length) continue;
        scanned++;
        const last = tail(file); const tree = inScope(last?.cwd);
        if (!tree) continue;
        if (age <= fresh) {
          live++;
          const at = byActivity(last, tree);
          workers.push({ kind: 'session', id, tree: label(at.tree), treeBy: at.how, branch: at.how === 'activité' ? branchOf.get(at.tree) : last.gitBranch || '', cwd: last.cwd, ageS: Math.round(age), lastAt: last.timestamp, doing: lastText(last), source: 'transcript' });
        }
        for (const s of subsLive) {
          subLive++;
          const sl = tail(s.tr), at = byActivity(sl, inScope(sl?.cwd) || tree);
          workers.push({ kind: 'subagent', id: s.agentId, parent: id, role: s.meta.agentType || '?', task: s.meta.description || '', depth: s.meta.spawnDepth ?? null, background: s.meta.requestShape === 'background',
            tree: label(at.tree), treeBy: at.how, branch: at.how === 'activité' ? branchOf.get(at.tree) : sl?.gitBranch || last.gitBranch || '', ageS: Math.round(s.age), doing: lastText(sl), source: 'subagent-meta' });
        }
      }
    }
    sources.sessions = { state: 'lue', path: projects, recentFiles: scanned, liveSessions: live, liveSubagents: subLive };
  }

  // 3 — verrous et registre
  const DL = [path.join(root, 'plugin/conductor/scripts/driver-lock.sh'), path.join(root, '.claude/scripts/driver-lock.sh')].find((p) => fs.existsSync(p));
  if (!DL) sources.locks = { state: 'absente' };
  else {
    let st = {}; try { st = JSON.parse(sh('bash', [DL, 'status', '--all'], root)); } catch { sources.locks = { state: 'erreur' }; }
    for (const l of (st.locks || []).filter((x) => x.present)) workers.push({ kind: 'lock', id: l.owner, task: l.step, tree: l.ws ? `compartiment ${l.ws}` : l.scope, ageS: l.age_seconds, stale: !!l.stale, children: l.children_running, source: 'driver-lock' });
    const wsList = ['', ...ls(path.join(sh('git', ['-C', root, 'rev-parse', '--path-format=absolute', '--git-common-dir'], root).trim(), 'vf-driver', 'ws'))];
    let reg = 0;
    for (const ws of wsList) {
      let o = {}; try { o = JSON.parse(sh('bash', [DL, 'orphans', ...(ws ? [`--ws=${ws}`] : [])], root)); } catch {}
      // une entrée `running` dont le verrou n'est plus tenu est un orphelin (manager mort ou release sans close)
      const held = (st.locks || []).some((l) => l.present && !l.stale && (l.ws || '') === ws);
      for (const a of o.orphans || []) { reg++; workers.push({ kind: 'registered', id: a.agent_id, role: a.role, task: a.node || '', parent: a.parent || '', depth: a.depth ?? null, tree: ws ? `compartiment ${ws}` : 'dépôt', ageS: a.age_seconds, stale: !held, orphan: !held, source: 'registre' }); }
    }
    sources.locks ||= { state: 'lue', held: (st.locks || []).filter((x) => x.present).length, registered: reg };
  }

  // 4 — DAG : nœuds running, dans .planning/ et dans le dossier commun des verrous
  const common = sh('git', ['-C', root, 'rev-parse', '--path-format=absolute', '--git-common-dir'], root).trim();
  const dagDirs = [path.join(root, '.planning'), ...ls(path.join(common, 'vf-driver', 'ws')).map((w) => path.join(common, 'vf-driver', 'ws', w)), path.join(common, 'vf-driver', 'repo')];
  let dags = 0, running = 0, staleNodes = 0;
  for (const d of dagDirs) for (const f of ls(d).filter((x) => x.endsWith('.dag.json'))) {
    dags++;
    let j; try { j = JSON.parse(fs.readFileSync(path.join(d, f), 'utf8')); } catch { continue; }
    // un DAG que personne n'a réécrit depuis le TTL du verrou garde des `running` fantômes (mission morte)
    const fp = path.join(d, f);
    let age = Math.round((now - mtime(fp)) / 1000);
    if (age <= ttl && (j.nodes || []).some((x) => x.status === 'running')) {
      const tracked = sh('git', ['-C', d, 'ls-files', '--error-unmatch', f], d).trim(), dirty = sh('git', ['-C', d, 'status', '--porcelain', '--', f], d).trim();
      const ct = Number(sh('git', ['-C', d, 'log', '-1', '--format=%ct', '--', f], d).trim());
      if (tracked && !dirty && ct) age = Math.round(now / 1000 - ct); // contenu identique au commit : écrit au plus tard à cette date
    }
    const stale = age > ttl;
    for (const n of (j.nodes || []).filter((x) => x.status === 'running')) { running++; if (stale) staleNodes++; workers.push({ kind: 'dag-node', id: n.id, role: n.stage || '', task: (n.step || '').slice(0, 100), tree: path.relative(root, d) || d, dag: f, ageS: age, stale, source: 'dag' }); }
  }
  sources.dags = { state: 'lue', files: dags, running, stale: staleNodes };

  return { at: new Date(now).toISOString(), root, trees: trees.map(label), fresh, busy: workers.some((w) => !w.stale), workers, sources };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const root = process.argv[2] && !process.argv[2].startsWith('--') ? process.argv[2] : '.';
  const fresh = Number(process.argv[process.argv.indexOf('--fresh') + 1]) || 180;
  const r = collect(root, { fresh });
  if (process.argv.includes('--json')) { console.log(JSON.stringify(r, null, 1)); process.exit(0); }
  console.log(`${r.busy ? 'Au travail' : 'Personne au travail'} — ${r.workers.length} signal(aux) · arbres : ${r.trees.join(', ')}`);
  for (const w of r.workers) console.log(`  ${w.kind.padEnd(10)} ${String(w.role || '').padEnd(16)} ${String(w.tree).padEnd(34)} ${w.ageS != null ? String(w.ageS).padStart(8) + ' s' : '          '}${w.orphan ? ' ORPHELIN' : w.stale ? ' PÉRIMÉ' : ''}  ${w.task || w.doing || ''}`.slice(0, 180));
  console.log('sources :', JSON.stringify(r.sources));
}
