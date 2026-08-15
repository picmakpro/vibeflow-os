// vf-cockpit-security.mjs — résolution de chemins et gardes sécurité du cockpit.
// Zéro dépendance npm. Aucune écriture disque ici.
import fs from 'node:fs';
import path from 'node:path';

// ---------- résolution de la racine .planning/ (cwd utilisateur, jamais ce repo) ----------
// Ordre de priorité : argument CLI > variable d'env VF_COCKPIT_PLANNING_ROOT >
// remontée d'arborescence depuis process.cwd() (comme un outil git-like).
export function findPlanningRoot(startDir) {
  let dir = path.resolve(startDir);
  for (;;) {
    const candidate = path.join(dir, '.planning');
    if (fs.existsSync(candidate) && fs.statSync(candidate).isDirectory()) return candidate;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

export function resolvePlanningRoot(argv, env) {
  const cliArg = argv.find((a) => !a.startsWith('--')) || null;
  const cliFlag = argv.find((a) => a.startsWith('--planning-root='));
  if (cliFlag) return path.resolve(cliFlag.slice('--planning-root='.length));
  if (cliArg) return path.resolve(cliArg);
  if (env.VF_COCKPIT_PLANNING_ROOT) return path.resolve(env.VF_COCKPIT_PLANNING_ROOT);
  return findPlanningRoot(env.VF_COCKPIT_CWD || process.cwd());
}

// ---------- résolution des assets front (dépôt vs installé) ----------
// Le serveur vit soit à plugin/vf-cockpit/scripts/ (dépôt, assets à ../references/),
// soit à .claude/scripts/ (installé, assets à ../skills/vf-cockpit/references/).
// Sondage : premier candidat existant l'emporte. Jamais résolu au cwd.
export function resolveReferencesDir(here) {
  const candidates = [
    path.join(here, '..', 'references'),
    path.join(here, '..', 'skills', 'vf-cockpit', 'references'),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c) && fs.statSync(c).isDirectory()) return c;
  }
  return null;
}

// ---------- garde anti-traversée ----------
// Résout un chemin relatif sous une racine autorisée et vérifie qu'il en reste
// descendant après résolution (bloque `..`, encodages, chemins absolus injectés).
export function safeJoin(root, relPath) {
  if (!root) return null;
  const resolved = path.resolve(root, '.' + path.sep + relPath);
  const rootWithSep = root.endsWith(path.sep) ? root : root + path.sep;
  if (resolved !== root && !resolved.startsWith(rootWithSep)) return null;
  return resolved;
}

export const MIME_ALLOWLIST = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.woff2': 'font/woff2',
};

export function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}
