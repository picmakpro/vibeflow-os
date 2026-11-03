// vf-cockpit-terminal-env — environnement et choix du shell du terminal intégré (amorce posée par 71-01, remplie par 71-03).
// Exports : envShell(env, secrets) -> copie de l'environnement ; choisirShell(env) -> chemin absolu du shell.
// Ici : aucune variable VF_COCKPIT_* ni aucune valeur qui contienne un secret ne passe au shell ; le filtre complet (liste fermée) est celui de 71-03.
import path from 'node:path';

export function envShell(env, secrets = []) {
  const sortie = {};
  const interdits = secrets.filter((s) => typeof s === 'string' && s !== '');
  for (const [k, v] of Object.entries(env || {})) {
    if (/^VF_COCKPIT_/.test(k)) continue;
    if (typeof v === 'string' && interdits.some((s) => v.includes(s))) continue;
    sortie[k] = v;
  }
  return sortie;
}

export const choisirShell = (env) => (env && typeof env.SHELL === 'string' && path.isAbsolute(env.SHELL) ? env.SHELL : '/bin/sh');
