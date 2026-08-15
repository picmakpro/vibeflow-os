// vf-cockpit-parsers.mjs — parsing pur de .planning/, sans I/O réseau.
// Chaque parseur est individuellement faillible : il ne lève jamais, il rend un
// résultat vide/nul + laisse l'appelant décider de la disponibilité de la source.
// Zéro dépendance npm — node:fs / node:path uniquement.
import fs from 'node:fs';
import path from 'node:path';

const LOCK_TTL = 1800;

// CRLF-tolerant : normalise les fins de ligne avant tout parsing.
function normalizeEol(raw) {
  return raw.replace(/\r\n/g, '\n');
}

export function readIf(p) {
  try {
    return normalizeEol(fs.readFileSync(p, 'utf8'));
  } catch {
    return null;
  }
}

// ---------- STATE.md (frontmatter YAML minimal) ----------
export function parseState(planningRoot) {
  const raw = readIf(path.join(planningRoot, 'STATE.md'));
  if (!raw) return null;
  try {
    const m = raw.match(/^---\n([\s\S]*?)\n---/);
    if (!m) return null;
    const out = {};
    let inProgress = false;
    for (const line of m[1].split('\n')) {
      const sub = line.match(/^ {2}(\w+): *(.*)$/);
      if (inProgress && sub) {
        (out.progress ??= {})[sub[1]] = Number(sub[2]);
        continue;
      }
      const kv = line.match(/^(\w+): *(.*)$/);
      if (!kv) continue;
      inProgress = kv[1] === 'progress';
      if (!inProgress) out[kv[1]] = kv[2].replace(/^"|"$/g, '');
    }
    return out;
  } catch {
    return null;
  }
}

// ---------- ROADMAP.md — checklist machine ----------
export function parseRoadmapChecklist(planningRoot) {
  const raw = readIf(path.join(planningRoot, 'ROADMAP.md'));
  if (!raw) return [];
  try {
    const phases = [];
    const re = /^- \[([ x])\] Phase (\d+): (.+?)(?: \(completed ([^)]+)\))?$/gm;
    let m;
    while ((m = re.exec(raw)) !== null) {
      phases.push({ done: m[1] === 'x', num: Number(m[2]), name: m[3].trim(), completed: m[4] || null });
    }
    return phases;
  } catch {
    return [];
  }
}

// ---------- ROADMAP.md — sections détaillées (### / #### Phase N:) ----------
// Deux profondeurs de titre coexistent dans l'historique réel (###/####) : les deux
// sont acceptées. Quand une phase a deux sections (héritage), la DERNIÈRE occurrence
// gagne — c'est un acquis validé du spike, jamais à renverser silencieusement.
export function parseRoadmapSections(planningRoot) {
  const raw = readIf(path.join(planningRoot, 'ROADMAP.md'));
  if (!raw) return {};
  try {
    const out = {};
    const re = /^#{3,4} Phase (\d+): ([^\n]+)\n([\s\S]*?)(?=^#{2,4} |\n<details>|(?![\s\S]))/gm;
    let m;
    while ((m = re.exec(raw)) !== null) {
      const body = m[3].trim();
      const goal = (body.match(/\*\*Goal\*\*: ?([\s\S]*?)(?=\n\*\*|$)/) || [])[1]?.replace(/\n/g, ' ').trim() || null;
      out[Number(m[1])] = { name: m[2].trim(), goal, body };
    }
    return out;
  } catch {
    return {};
  }
}

// ---------- Fiche de phase : section ROADMAP + paires PLAN/SUMMARY ----------
export function phaseDetail(planningRoot, num, logEvent = () => {}) {
  if (!Number.isFinite(num) || num < 0) {
    return { num: null, name: null, goal: null, body: null, dir: null, plans: [], error: 'numéro de phase invalide' };
  }
  const sections = parseRoadmapSections(planningRoot);
  const section = sections[num] || null;
  let dir = null;
  let plans = [];
  try {
    const phasesDir = path.join(planningRoot, 'phases');
    const entries = fs.readdirSync(phasesDir);
    const prefix = `VFDO-${num}-`;
    const d = entries.find((n) => n.startsWith(prefix));
    if (d) {
      dir = d;
      const files = fs.readdirSync(path.join(phasesDir, d));
      const ids = [...new Set(
        files.map((f) => (f.match(/^(\d+-\d+)-(PLAN|SUMMARY)\.md$/) || [])[1]).filter(Boolean),
      )].sort();
      plans = ids.map((id) => ({
        id,
        plan: files.includes(`${id}-PLAN.md`),
        done: files.includes(`${id}-SUMMARY.md`),
      }));
    }
  } catch (e) {
    logEvent('parse', `dossier de phase illisible pour ${num}`, { error: String(e) });
  }
  logEvent('http', `détail phase ${num}`, { found: !!section, dir });
  return {
    num,
    name: section?.name || null,
    goal: section?.goal || null,
    body: section?.body?.slice(0, 4000) || null,
    dir,
    plans,
  };
}

// ---------- MILESTONES.md ----------
export function parseMilestones(planningRoot) {
  const raw = readIf(path.join(planningRoot, 'MILESTONES.md'));
  if (!raw) return [];
  try {
    const out = [];
    const re = /^## (✅|🚧)?\s*([^\n]+)$/gm;
    let m;
    while ((m = re.exec(raw)) !== null) {
      const title = m[2].trim();
      const dates = [...title.matchAll(/(\d{4}-\d{2}-\d{2})/g)].map((d) => d[1]);
      out.push({ closed: m[1] === '✅', title: title.replace(/\s*\(.*\)\s*$/, ''), when: dates.at(-1) || null });
    }
    return out;
  } catch {
    return [];
  }
}

// ---------- MISSION-*.dag.json ----------
export function parseDags(planningRoot, logEvent = () => {}) {
  let files = [];
  try {
    files = fs.readdirSync(planningRoot).filter((f) => /^MISSION-.*\.dag\.json$/.test(f));
  } catch {
    return [];
  }
  return files
    .map((f) => {
      try {
        const raw = readIf(path.join(planningRoot, f));
        if (raw === null) return null;
        return { file: f, ...JSON.parse(raw) };
      } catch (e) {
        logEvent('parse', `dag invalide: ${f}`, { error: String(e) });
        return null;
      }
    })
    .filter(Boolean);
}

// ---------- DRIVER.lock/meta ----------
export function parseLock(planningRoot) {
  const meta = readIf(path.join(planningRoot, 'DRIVER.lock', 'meta'));
  if (!meta) return { present: false };
  try {
    const out = { present: true };
    for (const line of meta.split('\n')) {
      const kv = line.match(/^(\w+)=(.*)$/);
      if (kv) out[kv[1]] = kv[2];
    }
    const hb = Number(out.heartbeat_epoch || out.acquired_epoch || 0);
    out.age_seconds = hb ? Math.max(0, Math.floor(Date.now() / 1000) - hb) : null;
    out.stale = out.age_seconds !== null ? out.age_seconds > LOCK_TTL : null;
    return out;
  } catch {
    return { present: true, error: 'meta illisible' };
  }
}

// ---------- Snapshot agrégé — chaque source isolée, un drapeau de disponibilité par source ----------
export function snapshot(planningRoot, logEvent = () => {}) {
  const t0 = Date.now();

  const sources = {};
  function safe(name, fn, emptyValue) {
    try {
      const v = fn();
      sources[name] = v !== null && v !== undefined && !(Array.isArray(v) && v.length === 0 && emptyValue === undefined);
      return v;
    } catch (e) {
      logEvent('parse', `source ${name} en échec`, { error: String(e) });
      sources[name] = false;
      return emptyValue;
    }
  }

  const state = safe('state', () => parseState(planningRoot), null);
  const phases = safe('phases', () => parseRoadmapChecklist(planningRoot), []);
  const milestones = safe('milestones', () => parseMilestones(planningRoot), []);
  const dags = safe('dags', () => parseDags(planningRoot, logEvent), []);
  const lock = safe('lock', () => parseLock(planningRoot), { present: false });

  // Disponibilité explicite : présence réelle du fichier source, pas juste "non vide".
  const availability = {
    state: fs.existsSync(path.join(planningRoot, 'STATE.md')),
    roadmap: fs.existsSync(path.join(planningRoot, 'ROADMAP.md')),
    milestones: fs.existsSync(path.join(planningRoot, 'MILESTONES.md')),
    dags: dags.length > 0,
    lock: lock?.present === true,
  };

  const snap = {
    generatedAt: new Date().toISOString(),
    state,
    phases,
    milestones,
    dags,
    lock,
    availability,
  };
  logEvent('snapshot', 'construit', { ms: Date.now() - t0, phases: phases.length, dags: dags.length });
  return snap;
}
