// vf-cockpit-port — port préféré d'un lab (recette 3, O4 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-03, « C : port stable par lab »).
// Le port d'un cockpit dépend du LAB, jamais de l'ordre de lancement : empreinte (sha1) de la racine réelle du lab, réduite à PLAGE valeurs à partir de la base.
// Base 4378 (le défaut de l'amont), surchargeable par VF_COCKPIT_PORT_BASE (entier 1024..65000 ; toute autre valeur est ignorée, jamais un échec).
// PLAGE = 100 : deux labs ont ~1 % de chance de viser le même port préféré ; le repli du serveur (port+1, 20 essais, serve.mjs) joue alors, et reste borné à base+119.
import fs from 'node:fs';
import crypto from 'node:crypto';

export const BASE_DEFAUT = 4378;
export const PLAGE = 100;

export function basePort(env = process.env) {
  const v = env.VF_COCKPIT_PORT_BASE;
  if (typeof v === 'string' && /^\d{4,5}$/.test(v) && Number(v) >= 1024 && Number(v) <= 65000) return Number(v);
  return BASE_DEFAUT;
}

// realpathSync.native : sous macOS (APFS insensible à la casse) la casse du chemin est canonisée par le système ; `realpathSync` seul la laisse telle que saisie (deux casses = deux ports = deux localStorage).
export function portPrefere(lab, env = process.env) {
  let reel = lab;
  try { reel = fs.realpathSync.native(lab); } catch {}
  const h = crypto.createHash('sha1').update(reel).digest().readUInt32BE(0);
  return basePort(env) + (h % PLAGE);
}
