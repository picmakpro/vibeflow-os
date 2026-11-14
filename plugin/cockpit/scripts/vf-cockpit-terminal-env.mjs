// vf-cockpit-terminal-env — environnement et choix du shell du terminal intégré (71-01 en pose l'amorce, 71-03 le filtre complet).
// Exports : envShell(env, secrets) -> copie de l'environnement ; choisirShell(env) -> chemin absolu du shell ; AJOUTS_TOUJOURS.
// Liste NOIRE seulement (P71-D-03, D-14) : CLAUDECODE, CLAUDE_EFFORT, CLAUDE_PID, CLAUDE_CODE_*, VF_COCKPIT_* et toute valeur qui contient un jeton du cockpit sont retirés ;
// le PATH d'origine du lanceur est restitué (VF_COCKPIT_PATH_ORIGINE, P71-D-03) ; le reste passe tel quel (NODE_OPTIONS compris : le cockpit ne le pose pas). Un jeton de moins de 16 caractères n'écarte rien (trop de faux positifs).
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// P71-D-23 (arbitrage de Samuel, AskUserQuestion, session principale Claude Code, 2026-11-03, rend définitive P71-D-22) : le terminal émulé est xterm.js,
// le TERM hérité décrit le terminal du lanceur (voire `dumb`). Posés TOUJOURS, ils écrasent la valeur héritée. Une seule constante : réversible.
export const AJOUTS_TOUJOURS = { TERM: 'xterm-256color', COLORTERM: 'truecolor' };
const LONGUEUR_JETON = 16;

export function envShell(env, secrets = []) {
  const sortie = {};
  const interdits = secrets.filter((s) => typeof s === 'string' && s.length >= LONGUEUR_JETON);
  for (const [k, v] of Object.entries(env || {})) {
    if (k === 'CLAUDECODE' || k === 'CLAUDE_EFFORT' || k === 'CLAUDE_PID' || k.startsWith('CLAUDE_CODE_') || k.startsWith('VF_COCKPIT_')) continue; // CLAUDE_EFFORT et CLAUDE_PID : ceux de la session qui a lancé le serveur, jamais ceux du claude lancé dans le terminal (AUDC-B-06)
    if (typeof v === 'string' && interdits.some((s) => v.includes(s))) continue;
    sortie[k] = v;
  }
  // P71-D-03 : le lanceur garde pour le shell le PATH d'origine dans VF_COCKPIT_PATH_ORIGINE (le serveur et ses enfants ont le PATH assaini de H-1). Restitué en PATH, puis retiré (le préfixe
  // VF_COCKPIT_ l'a déjà écarté ci-dessus). Absente (serveur lancé sans le lanceur), le PATH reçu est conservé. Un jeton du cockpit dans la valeur l'écarte comme tout le reste.
  const origine = env && env.VF_COCKPIT_PATH_ORIGINE;
  if (typeof origine === 'string' && origine !== '' && !interdits.some((s) => origine.includes(s))) sortie.PATH = origine;
  Object.assign(sortie, AJOUTS_TOUJOURS);
  return sortie;
}

const executable = (p) => {
  try { return typeof p === 'string' && path.isAbsolute(p) && fs.statSync(p).isFile() && (fs.accessSync(p, fs.constants.X_OK), true); } catch { return false; }
};

// P71-D-04 : $SHELL s'il est absolu, ordinaire et exécutable, sinon le shell du compte aux mêmes conditions, sinon /bin/sh.
export function choisirShell(env) {
  if (executable(env && env.SHELL)) return env.SHELL;
  let compte = null; try { compte = os.userInfo().shell; } catch {}
  return executable(compte) ? compte : '/bin/sh';
}
