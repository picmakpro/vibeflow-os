// vf-cockpit-watch.mjs — veille sur .planning/ avec fallback portable.
// fs.watch({recursive:true}) n'est pas garanti partout (Linux notamment selon
// version Node). On tente, et on bascule sur un polling de mtimes si ça échoue,
// à l'amorçage OU en cours de route. Aucune écriture disque ici.
import fs from 'node:fs';
import path from 'node:path';

const POLL_INTERVAL_MS = 2000;

export function startWatch(planningRoot, onChange, logEvent = () => {}) {
  if (!planningRoot) return { mode: 'unavailable' };

  let debounce = null;
  const trigger = (reason) => {
    clearTimeout(debounce);
    debounce = setTimeout(() => onChange(reason), 300);
  };

  function startPolling() {
    const mtimes = new Map();
    function walk(dir) {
      let entries = [];
      try {
        entries = fs.readdirSync(dir, { withFileTypes: true });
      } catch {
        return;
      }
      for (const e of entries) {
        const full = path.join(dir, e.name);
        if (e.isDirectory()) {
          walk(full);
        } else {
          try {
            const mt = fs.statSync(full).mtimeMs;
            const prev = mtimes.get(full);
            if (prev !== undefined && prev !== mt) trigger(path.relative(planningRoot, full));
            mtimes.set(full, mt);
          } catch {
            // fichier disparu entre le readdir et le stat : ignoré, non fatal.
          }
        }
      }
    }
    walk(planningRoot); // amorce sans déclencher de broadcast au démarrage
    const interval = setInterval(() => walk(planningRoot), POLL_INTERVAL_MS);
    interval.unref?.();
    logEvent('watch', `polling actif sur ${planningRoot}`, { mode: 'poll', intervalMs: POLL_INTERVAL_MS });
    return { mode: 'poll' };
  }

  try {
    const watcher = fs.watch(planningRoot, { recursive: true }, (_ev, fname) => {
      trigger(String(fname || 'unknown'));
    });
    logEvent('watch', `fs.watch actif sur ${planningRoot}`, { mode: 'watch' });
    watcher.on?.('error', (e) => {
      logEvent('watch', 'fs.watch a échoué en cours de route, bascule polling', { error: String(e) });
      startPolling();
    });
    return { mode: 'watch' };
  } catch (e) {
    logEvent('watch', 'fs.watch indisponible, bascule polling', { error: String(e) });
    return startPolling();
  }
}
