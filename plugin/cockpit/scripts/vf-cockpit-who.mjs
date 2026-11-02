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
const sh = (cmd, args, cwd) => { try { return execFileSync(cmd, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 10000 }); } catch (e) { return e.stdout || ''; } }; // timeout : un git ou un bash bloqué ne gèle pas la boucle
const ls = (d) => { try { return fs.readdirSync(d); } catch { return []; } };
const mtime = (f) => { try { return fs.statSync(f).mtimeMs; } catch { return 0; } };
const readJson = (f) => { try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return null; } };

// les listes de clés vérifiées sur Claude Code viennent du contrat versionné, pas du code
const IFACE = readJson(path.join(HERE, 'vf-cockpit-interface.json')) || {};
const CC = IFACE.claudeCode || {};
const REQ_TR = CC.transcript?.requis || ['cwd', 'type', 'message', 'timestamp', 'sessionId'];
const REQ_META = CC.metaSousAgent?.requis || ['agentType', 'description'];

// recherche en partant de la fin d'un jsonl, sur des fenêtres de plus en plus larges (256 Kio, 2 Mio, 8 Mio) : `accepte(ligne)` rend la valeur
// cherchée ou null. Une ligne plus longue que la fenêtre (un gros résultat d'outil) est ignorée au lieu de faire croire qu'il n'y a rien :
// c'était la cause d'une session très active absente du badge « au travail » ou sans dernière commande (E-5).
const FENETRES = [256 << 10, 2 << 20, 8 << 20];
const cherche = (f, accepte) => {
  for (const bytes of FENETRES) {
    let fd = null, size = 0, lignes = [];
    try {
      fd = fs.openSync(f, 'r'); size = fs.fstatSync(fd).size; const len = Math.min(size, bytes);
      const buf = Buffer.alloc(len); fs.readSync(fd, buf, 0, len, size - len);
      lignes = buf.toString('utf8').split('\n'); if (size > len) lignes.shift(); // la première ligne de la fenêtre est coupée
    } catch { return null; } finally { if (fd !== null) { try { fs.closeSync(fd); } catch {} } } // le descripteur se ferme aussi quand readSync lève
    for (const l of lignes.reverse()) {
      if (!l.trim()) continue;
      let d; try { d = JSON.parse(l); } catch { continue; }
      const r = d && accepte(d); if (r) return r;
    }
    if (size <= bytes) break;
  }
  return null;
};
// dernière ligne user/assistant d'un jsonl
const tail = (f) => cherche(f, (d) => (d.type === 'user' || d.type === 'assistant' ? d : null));
const formeOk = (d) => !!d && REQ_TR.every((k) => k in d);

// collecte interne : les travailleurs gardent `_tr` (chemin du transcript) hors de la sortie publique
function gather(root, { fresh = 180, ttl = Number(process.env.VF_DRIVER_TTL) || 1800, now = Date.now(), home = os.homedir(), scriptsDir } = {}) {
  root = path.resolve(root);
  const sources = {}; const workers = [];
  const porcelain = sh('git', ['-C', root, 'worktree', 'list', '--porcelain'], root);
  const branchOf = new Map(porcelain.split('\n\n').map((b) => [/^worktree (.*)$/m.exec(b)?.[1], /^branch refs\/heads\/(.*)$/m.exec(b)?.[1] || (b.includes('detached') ? '(détachée)' : '')]).filter(([t]) => t && fs.existsSync(t)).map(([t, br]) => [fs.realpathSync(t), br]));
  // la branche vient de `git worktree list` pour TOUT arbre connu (cwd ou activité) ; le gitBranch du transcript est celui de l'arbre de LANCEMENT : repli seulement
  const branche = (t, ...transcript) => branchOf.get(t) || transcript.find(Boolean) || '';
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
          const brut = readJson(path.join(subDir, m)); const meta = brut && typeof brut === 'object' && !Array.isArray(brut) ? brut : {}; // un meta.json `5` ou `[]` est une forme inconnue, jamais une exception
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
          workers.push({ kind: 'session', id, tree: label(at.tree), treeBy: at.how, branch: branche(at.tree, last.gitBranch), cwd: last.cwd, ageS: Math.round(age), lastAt: last.timestamp, source: 'transcript', _tr: file });
        }
        for (const s of subs) {
          subLive++;
          const sl = tail(s.tr), at = byActivity(sl, inScope(sl?.cwd) || tree);
          workers.push({ kind: 'subagent', id: s.agentId, parent: id, role: s.meta.agentType, task: s.meta.description || '', depth: s.meta.spawnDepth ?? null, background: s.meta.requestShape === 'background',
            tree: label(at.tree), treeBy: at.how, branch: branche(at.tree, sl?.gitBranch, last?.gitBranch), ageS: Math.round(s.age), source: 'subagent-meta', _tr: s.tr });
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
    st = { ...st, locks: Array.isArray(st?.locks) ? st.locks : st?.present ? [st] : [] }; // lab plat : `status --all` rend l'objet d'UN verrou, sans `locks`
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
  const dagDirs = [path.join(root, '.planning'), path.join(root, '.planning', 'missions'), ...ls(path.join(common, 'vf-driver', 'ws')).map((w) => path.join(common, 'vf-driver', 'ws', w)), path.join(common, 'vf-driver', 'repo')];
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
  // task, cwd et role viennent de fichiers que d'autres écrivent (meta.json, transcripts, verrous) : bornés et masqués avant le flux SSE
  const bornes = (v, n) => (typeof v === 'string' ? masque(v).slice(0, n) : v);
  const workers = g.workers.map(({ _tr, ...w }) => ({ ...w, ...(w.task !== undefined ? { task: bornes(w.task, 160) } : {}), ...(w.cwd !== undefined ? { cwd: bornes(w.cwd, 200) } : {}), ...(w.role !== undefined ? { role: bornes(w.role, 80) } : {}) }));
  const sources = { ...g.sources };
  if (typeof sources.sessions?.path === 'string') sources.sessions = { ...sources.sessions, path: sources.sessions.path.replace(opts.home || os.homedir(), '~') };
  return { schema: 'vibeflow/cockpit-who@1', at: g.at, root: g.root, trees: g.trees, fresh: g.fresh, busy: workers.some((w) => !w.stale), workers, sources };
}

// P67-D-14 : la dernière commande ne sort que par cette révélation ponctuelle (T-67-05), réduite au programme et à son premier argument (décision de Samuel, AskUserQuestion session principale, 2026-11-02).
// Ces masques restent le filet de ce qui est affiché (un premier argument peut être une URL à identifiants ou un jeton nu) ET de task/cwd/role (texte libre écrit par d'autres, voir `bornes`).
const MASQUES = [
  /\bgh[pousr]_[A-Za-z0-9]{20,}/g, /\bgithub_pat_[A-Za-z0-9_]{20,}/g, /\bsk-[A-Za-z0-9_-]{16,}/g, /\bAKIA[A-Z0-9]{16}/g, /\bxox[baprs]-[A-Za-z0-9-]+/g,
  /\bBearer\s+[A-Za-z0-9._~+\/=-]{16,}/gi,
  // un nom de variable ou de clé qui finit par un mot sensible (GITHUB_TOKEN=, AWS_SECRET_ACCESS_KEY=, API_KEY=) : `\b` ne coupe pas après `_`, d'où `[A-Za-z0-9_]*`
  /[A-Za-z0-9_]{0,64}(?:password|passwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credential)[A-Za-z0-9_]{0,64}=\S+/gi,
  /--(?:password|passwd|secret|token|api[_-]?key)(?:=|\s+)\S+/gi, /\bX-Api-Key:\s*\S+/gi,
  // F-1 (revue de D3) : identifiants d'une commande Bash hors « NOM=valeur ». Tous les quantificateurs sont bornés (pas de retour quadratique) ; le contexte est en lookbehind,
  // seule la valeur secrète est remplacée. Les `export FOO=valeur` génériques ne sont pas masqués par ces règles : seuls les noms sensibles le sont (règle plus haut).
  // `mysql -pXXX` et `sshpass -p XXX` : la dernière commande ne les affiche plus (option en « - »), mais task/cwd/role (`bornes`) les diffusent encore, d'où leur maintien.
  /(?<=\b(?:mysql|mysqladmin|mysqldump|mariadb)\b[^|;&\n]{0,100}\s-p)\S+/g, // mysql -pMotDePasse (collé) ; « -p » seul = invite, intact
  /(?<=\bsshpass\s{1,5}-p\s{0,3})\S+/g, // sshpass -p <mot de passe>
  /(?<=:\/\/)[^\s:@\/]{1,128}:[^\s@\/]{1,256}(?=@)/g, // scheme://user:pass@hôte
  /(?<=(?:^|\s)(?:-u|--user)[ =]{0,3})[^\s:]{1,128}:\S+/g, // curl -u user:pass, --user=user:pass (« -u root » seul n'a pas de « : »)
  /\bAuthorization:\s{0,8}(?:Digest\s[^'\n]{1,300}|(?:[A-Za-z]{1,20}\s{1,8})?[^\s"']+)/gi, // en-tête Authorization, tout schéma (Basic, Bearer, Token, Digest…)
];
// l'entrée est bornée AVANT les masques (les sorties sont tronquées à 200 car. au plus pour task/cwd/role, à 80 pour la dernière commande) : le nom de variable sensible est en {0,64} et l'entrée en MAX_MASQUE,
// sinon un mot de 100 Kio rendait le masque quadratique (17 s)
const MAX_MASQUE = 4000;
const masque = (t) => MASQUES.reduce((a, re) => a.replace(re, '[masqué]'), String(t).slice(0, MAX_MASQUE));
const BORNE_COMMANDE = 80;
// réduit une commande au programme et à son premier argument (« git push … ») ; limite acceptée : un secret passé en premier argument positionnel (`ls Secret99`) reste visible.
// Liste blanche, aucune lecture des guillemets : un mot est « simple » s'il ne contient que des lettres ASCII, des chiffres et `_ . / : @ % + , ~ -` (donc jamais de guillemet, `$`, backtick, `\`,
// parenthèse, `;`, `|`, `&`, `<`, `>`, `*`, `?`, `[`, `]`, `{`, `}`, `!`, `#`, `=`). Les affectations de tête ne sont sautées que si le mot entier vaut `NOM=<mot simple ou vide>` ; tout autre mot de tête
// (valeur citée, `$(…)`, tableau, espace échappé) arrête la lecture et le programme, non simple, donne « … ». Le programme n'est affiché que s'il est simple et ne commence pas par « - » ;
// un retour à la ligne compte comme `;` (non simple) ; le premier argument que s'il est simple, ne commence pas par « - » et ne contient pas « = » (`DB_PASS=…` en est exclu par la liste blanche). « … » s'il reste des mots non affichés.
const SIMPLE = /^[A-Za-z0-9_.\/:@%+,~-]+$/;
const AFFECTATION = /^[A-Za-z_][A-Za-z0-9_]*=[A-Za-z0-9_.\/:@%+,~-]*$/;
const resume = (cmd) => {
  // un retour à la ligne est un séparateur de commandes : il devient un mot non simple (comme `;`), jamais un simple espace, sinon le mot de la ligne suivante serait pris pour un argument
  const mots = cmd.trim().replace(/\s*\n\s*/g, ' \n ').split(/[ \t\r\f\v]+/).filter(Boolean); let i = 0;
  while (i < mots.length && AFFECTATION.test(mots[i])) i++;
  const prog = mots[i]; if (prog === undefined || !SIMPLE.test(prog) || prog.startsWith('-')) return '…';
  const arg = mots[i + 1]; const montre = arg !== undefined && SIMPLE.test(arg) && !arg.startsWith('-');
  return [prog, ...(montre ? [arg] : []), ...(mots.length > i + (montre ? 2 : 1) ? ['…'] : [])].join(' ');
};
// D3 (recette 2026-11-02) : « la dernière commande » est la dernière commande de l'outil Bash (tool_use name=Bash, input.command) de la session.
// Un message texte de l'assistant n'est jamais rendu, même en repli : sans appel Bash lisible, `lastDoing` rend null (erreur « sans-action »).
// forme affichée d'une commande : réduction, masque PUIS borne (exportée pour la preuve générative, qui ne peut pas passer par une session disque par commande)
export const commandeAffichee = (cmd) => masque(resume(String(cmd).slice(0, MAX_MASQUE))).slice(0, BORNE_COMMANDE);
const lastCommand = (d) => {
  const c = d?.message?.content; if (!Array.isArray(c)) return '';
  for (const x of [...c].reverse()) if (x?.type === 'tool_use' && x.name === 'Bash' && typeof x.input?.command === 'string' && x.input.command.trim()) return commandeAffichee(x.input.command);
  return '';
};
// E-5 : la dernière ligne d'une session active est presque toujours un résultat d'outil (message user sans texte) ou une réflexion : on remonte
// jusqu'au dernier appel Bash de l'assistant.
const lastDoing = (f) => cherche(f, (d) => (d.type === 'assistant' ? lastCommand(d) : null));
const ID_RE = /^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/;

// identifiant au format strict ET présent dans une collecte fraîche : aucun chemin construit depuis l'entrée (T-67-07)
export function revealDoing(root, id, opts = {}) {
  if (typeof id !== 'string' || !ID_RE.test(id)) return { schema: 'vibeflow/cockpit-doing@1', id: String(id), doing: null, erreur: 'id-invalide' };
  const w = gather(root, opts).workers.find((x) => (x.kind === 'session' || x.kind === 'subagent') && x.id === id && x._tr);
  if (!w) return { schema: 'vibeflow/cockpit-doing@1', id, doing: null, erreur: 'inconnu' };
  const doing = lastDoing(w._tr);
  return doing ? { schema: 'vibeflow/cockpit-doing@1', id, doing } : { schema: 'vibeflow/cockpit-doing@1', id, doing: null, erreur: 'sans-action' };
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const root = process.argv[2] && !process.argv[2].startsWith('--') ? process.argv[2] : '.';
  const fresh = Number(process.argv[process.argv.indexOf('--fresh') + 1]) || 180;
  const r = collectWho(root, { fresh });
  if (process.argv.includes('--json')) { console.log(JSON.stringify(r, null, 1)); process.exit(0); }
  console.log(`${r.busy ? 'Au travail' : 'Personne au travail'} — ${r.workers.length} signal(aux) · arbres : ${r.trees.join(', ')}`);
  for (const w of r.workers) console.log(`  ${w.kind.padEnd(10)} ${String(w.role || '').padEnd(16)} ${String(w.tree).padEnd(34)} ${w.ageS != null ? String(w.ageS).padStart(8) + ' s' : '          '}${w.orphan ? ' ORPHELIN' : w.stale ? ' PÉRIMÉ' : ''}  ${w.task || ''}`.slice(0, 180));
  console.log('sources :', JSON.stringify(r.sources));
}
