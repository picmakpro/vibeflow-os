// vf-cockpit-serveur-vivant — reconnaître le serveur d'un lab SANS l'adopter, et décider si un PID est CE serveur (79-06, P79-D-10, D-M13, P79-D-26, A37).
// Extrait de vf-cockpit.mjs. Ce module n'importe AUCUN module de lancement de processus : la lecture de la ligne de commande d'un PID est injectée
// par l'appelant (`lireCommande(pid, lab)`, rend la ligne ENTIÈRE ou null) ; un appelant qui lance `ps` lui-même s'inscrit à la liste blanche
// des importeurs (79-12).
// Exports : etatFile, lireEtat, vivant, hashSur, pidSur, portValide, portDeUrl, adresseLocale, serveurVivant, identiteServeur, estNotre, detecterServeur.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { engineDir } from './vf-cockpit-paths.mjs';
import { cheminPhysique } from './vf-cockpit-git-sortant.mjs';

export const etatFile = (sortie) => path.join(sortie, '.cache', 'server.json');
export const lireEtat = (sortie) => { try { return JSON.parse(fs.readFileSync(etatFile(sortie), 'utf8')); } catch { return null; } };
export const vivant = (pid) => { try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; } };
// Une valeur de server.json (fichier que le lab peut fournir) n'entre jamais dans une ligne ni dans un fichier sans forme valide.
export const hashSur = (h) => (h === undefined || h === null ? undefined : typeof h === 'string' && /^[0-9a-f]{1,64}$/.test(h) ? h : 'illisible'); // illisible = code inconnu : le serveur est remplacé
export const pidSur = (v) => (Number.isInteger(v) && v > 0 ? v : null);
// P71-D-25 (F1) : server.json est écrit dans le lab, donc non fiable. Aucune adresse n'en est jamais reprise telle quelle : seul un PORT entier
// (^[0-9]{1,5}$, 1..65535) en est lu, et l'adresse est reconstruite en http://127.0.0.1:<port>. Un port invalide vaut « pas de serveur ».
export const portValide = (v) => {
  const t = typeof v === 'number' || typeof v === 'string' ? String(v) : '';
  if (!/^[0-9]{1,5}$/.test(t)) return null;
  const n = Number(t); return n >= 1 && n <= 65535 ? n : null;
};
export const portDeUrl = (u) => { const m = typeof u === 'string' ? /^http:\/\/127\.0\.0\.1:([0-9]{1,5})$/.exec(u) : null; return m ? portValide(m[1]) : null };
export const adresseLocale = (port) => `http://127.0.0.1:${port}`;
export const serveurVivant = (sortie) => {
  const s = lireEtat(sortie);
  const pid = s ? pidSur(s.pid) : null;
  if (pid === null || !vivant(pid)) return null;
  const port = portValide(s.port) ?? portDeUrl(s.url);
  if (port === null) return null;
  const pq = s.terminal ? portDeUrl(s.terminal.url) : null;
  const { terminal: _t, ...reste } = s;
  return { ...reste, pid, ...(Object.hasOwn(reste, 'hash') ? { hash: hashSur(reste.hash) } : {}), port, url: adresseLocale(port), ...(pq === null ? {} : { terminal: { url: adresseLocale(pq) } }) };
};

// Identité d'un serveur : le chemin réel du serve.mjs du MODULE (celui du moteur voisin du dossier de scripts) et le chemin réel de la sortie.
// Résolution PHYSIQUE (`cheminPhysique` de 79-07, A37), FERMÉE PAR DÉFAUT : si l'un des deux ne se résout pas, il n'y a pas d'identité
// (estNotre est faux, aucun signal n'est envoyé), jamais un repli sur la forme écrite du chemin.
// `sortieEcrite` ne sert qu'à l'ancienne forme (transition P79-D-26).
export function identiteServeur(dossierScripts, sortie) {
  try {
    const moteur = engineDir(dossierScripts).chemin; if (!moteur) return null;
    const serve = cheminPhysique(path.join(moteur, 'assets', 'serve.mjs')), reelle = cheminPhysique(sortie);
    if (serve === null || reelle === null) return null;
    return { serve, sortie: reelle, sortieEcrite: path.resolve(sortie) };
  } catch { return null; }
}
// Messages du lanceur (dits à l'écran ou au journal), écrits ici pour tenir sa taille de base (79-06).
export const MESSAGES = {
  psAbsent: "arrêt refusé : « ps » est introuvable dans les éléments absolus du PATH, le serveur n'est pas arrêté " +
    "(un PID du lab n'est jamais signalé sans vérification).",
  labAmbigu: "le chemin du lab contient « --sortie= » ou un saut de ligne : refusé (identité du serveur ambiguë).",
  pidInconnu: (pid) => `PID ${pid} non reconnu comme le serveur de ce cockpit : rien n'a été arrêté (fichier d'état du lab non fiable).`,
};
// Motif écrit au journal quand un serveur en cours est remplacé ; `empreinte` est une fonction, appelée seulement si le code est périmé.
export const motifRelance = (o, perime, hash, empreinte) => (o.rebuild ? '--rebuild demandé'
  : perime ? `code du serveur changé, empreinte ${hash} -> ${empreinte()}`
    : '--terminal demandé, aucun terminal enregistré pour le serveur en cours');
const motEntier = (cmd, mot) => !!mot && (` ${cmd} `).includes(` ${mot} `);
// 67-SECURITY M3 : le lanceur n'exécute JAMAIS un script du lab. Arrêt par signal sur un PID que le fichier d'état du lab (donc non fiable) désigne :
// entier > 1, ni le nôtre, vivant, et dont la ligne de commande, lue EN ENTIER, est le serve.mjs du module en mot entier ET se termine exactement
// par ` --sortie=<chemin réel>`. Deux labs dont le nom de l'un est le préfixe de l'autre (« lab », « lab bis ») ne se confondent donc pas.
// Windows n'a pas de `ps` : le PID du fichier d'état reste borné par les contrôles ci-dessus.
export function estNotre(pid, identite, lab, lireCommande) {
  if (!Number.isInteger(pid) || pid <= 1 || pid === process.pid || !vivant(pid)) return false;
  if (process.platform === 'win32') return true;
  if (!identite) return false;
  const brut = lireCommande(pid, lab); if (typeof brut !== 'string') return false;
  const c = brut.trimEnd();
  const duModule = motEntier(c, identite.serve); // m:module
  const finExacte = c.endsWith(` --sortie=${identite.sortie}`); // m:prefixe
  // forme de la version précédente (P79-D-26) : à retirer à la version suivante ; le marqueur de fin de ligne est celui du mutant
  const ancienne = [identite.sortieEcrite, identite.sortie].some((s) => motEntier(c, path.join(s, 'serve.mjs'))); // m:ancienne
  return (duModule && finExacte) || ancienne;
}

// AUDC-H3 : un serveur de CE lab à l'écoute alors que server.json manque se reconnaît à sa page (jeton) et à /api/status (racine du lab, PID
// reconnu par `estNotre`, déjà lié par l'appelant à `lireCommande`). Seuls les ports du lab (préféré et repli de 20) sont sondés, sur 127.0.0.1.
// D-M13 : DÉTECTER n'écrit RIEN (ni server.json, ni journal) ; adopter est le geste séparé de l'appelant qui lance (serveurOrphelin).
// Rend { pid, port, url, token, hash, startedAt } ou null.
const lireHttp = (port, chemin, jeton) => new Promise((resolve) => {
  const r = http.get({ host: '127.0.0.1', port, path: chemin, timeout: 1500, headers: { Host: `127.0.0.1:${port}`, ...(jeton ? { 'x-vf-cockpit-token': jeton } : {}) } }, (res) => {
    let b = ''; res.on('data', (c) => { if (b.length < 3 << 20) b += c; }); res.on('end', () => resolve({ code: res.statusCode, corps: b }));
  });
  r.on('error', () => resolve(null)); r.on('timeout', () => { r.destroy(); resolve(null); });
});
export async function detecterServeur(lab, sortie, port0, { estNotre: reconnu }) {
  let racine; try { racine = fs.realpathSync(lab); } catch { return null; }
  for (let p = port0; p <= Math.min(65535, port0 + 20); p++) {
    const page = await lireHttp(p, '/');
    const jeton = page && page.code === 200 ? /VF_COCKPIT_SERVER=\{"token":"([0-9a-f]{1,128})"/.exec(page.corps)?.[1] : null;
    if (!jeton) continue;
    const st = await lireHttp(p, '/api/status', jeton);
    let o = null; try { o = JSON.parse(st?.corps || ''); } catch {}
    if (!o || !Number.isInteger(o.pid) || typeof o.root !== 'string') continue;
    let r; try { r = fs.realpathSync(o.root); } catch { continue; }
    if (r !== racine || !reconnu(o.pid)) continue;
    const trouve = { pid: o.pid, port: p, url: adresseLocale(p), token: jeton, hash: hashSur(o.hash), startedAt: new Date().toISOString() };
    return trouve; // m:detecte
  }
  return null;
}
