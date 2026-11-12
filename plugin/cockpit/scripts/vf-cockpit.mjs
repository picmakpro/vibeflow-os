#!/usr/bin/env node
// vf-cockpit — lanceur du cockpit d'un lab (67-06 ; P67-D-05, P67-D-06).
// Verbes : open (défaut) · build · stop · status. Options : --lab <dossier> · --no-open · --port <p> · --rebuild · --terminal · --help.
// Écrit sous <lab>/.vibeflow/cockpit/ (ignoré par git), sert 127.0.0.1 par le serveur unique de la sortie.
// Codes : 0 succès · 2 lab sans .planning/ · 3 moteur absent · 4 assemblage en échec (lien symbolique refusé dans la sortie compris) · 5 serveur non démarré (attente jusqu'à 30 s) · 64 usage.
// Aucun échec ne sort avec une trace : le message est écrit, le code est l'un de ceux-là (main().catch en bas).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';
import { empreinteModule } from './vf-cockpit-module.mjs';
import { spawn, execFileSync } from 'node:child_process';

import { envEnfant } from './vf-cockpit-env.mjs';
import { findLabRoot, engineDir, outputDir, verifierSortie, resoudreBinaire } from './vf-cockpit-paths.mjs';
import { portPrefere } from './vf-cockpit-port.mjs';
import { FICHIER_OUVRIR, FICHIER_SECRET_OUVRIR } from './vf-cockpit-terminal-amorce.mjs';
import { prendreVerrou, serveurOrphelin, noter, hashSur, pidSur } from './vf-cockpit-lanceur-verrou.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const AIDE = `Usage : node vf-cockpit.mjs [open|build|stop|status] [--lab <dossier>] [--no-open] [--port <p>] [--rebuild] [--terminal]
  open    assemble le cockpit du lab s'il le faut, démarre le serveur local et rend l'adresse (défaut)
  build   assemble le cockpit sans démarrer de serveur
  stop    arrête le serveur du lab
  status  dit l'adresse et le PID du serveur, ou « arrêté »
  --terminal  ouvre aussi un terminal dans le tiroir de la page (macOS, Linux)
Codes : 0 succès · 2 lab sans .planning/ · 3 moteur absent · 4 assemblage en échec (lien symbolique refusé dans la sortie compris) · 5 serveur non démarré`;

const VERBES = ['open', 'build', 'stop', 'status'];
function lireArgs(argv) {
  const o = { verbe: 'open', lab: null, noOpen: false, port: null, rebuild: false, terminal: false, aide: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--help' || a === '-h') o.aide = true;
    else if (a === '--no-open') o.noOpen = true;
    else if (a === '--rebuild') o.rebuild = true;
    else if (a === '--terminal') o.terminal = true;
    else if (a === '--lab') o.lab = argv[++i];
    else if (a === '--port') o.port = argv[++i];
    else if (VERBES.includes(a)) o.verbe = a;
    else return { erreur: `argument inconnu : ${a}` };
  }
  // Borne haute 65515 = 65535 − 20 : le repli de serve.mjs tente port+1 sur 20 essais ; au-delà de 65515 il sortirait de la plage (65536 : ERR_SOCKET_BAD_PORT avalée, serveur orphelin sans server.json).
  if (o.port !== null && !(/^\d{1,5}$/.test(String(o.port)) && Number(o.port) >= 1024 && Number(o.port) <= 65515)) return { erreur: `port invalide : ${o.port}` };
  return o;
}

const etatFile = (sortie) => path.join(sortie, '.cache', 'server.json');
const lireEtat = (sortie) => { try { return JSON.parse(fs.readFileSync(etatFile(sortie), 'utf8')); } catch { return null; } };
const vivant = (pid) => { try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; } };
// P71-D-25 (F1) : server.json est écrit dans le lab, donc non fiable. Aucune adresse n'en est jamais reprise telle quelle : seul un PORT entier
// (^[0-9]{1,5}$, 1..65535) en est lu, et l'adresse est reconstruite en http://127.0.0.1:<port>. Un port invalide vaut « pas de serveur ».
const portValide = (v) => { const t = typeof v === 'number' || typeof v === 'string' ? String(v) : ''; if (!/^[0-9]{1,5}$/.test(t)) return null; const n = Number(t); return n >= 1 && n <= 65535 ? n : null; };
const portDeUrl = (u) => { const m = typeof u === 'string' ? /^http:\/\/127\.0\.0\.1:([0-9]{1,5})$/.exec(u) : null; return m ? portValide(m[1]) : null; };
const adresseLocale = (port) => `http://127.0.0.1:${port}`;
const serveurVivant = (sortie) => {
  const s = lireEtat(sortie);
  const pid = s ? pidSur(s.pid) : null;
  if (pid === null || !vivant(pid)) return null;
  const port = portValide(s.port) ?? portDeUrl(s.url);
  if (port === null) return null;
  const pq = s.terminal ? portDeUrl(s.terminal.url) : null;
  const { terminal: _t, ...reste } = s;
  return { ...reste, pid, ...(Object.hasOwn(reste, 'hash') ? { hash: hashSur(reste.hash) } : {}), port, url: adresseLocale(port), ...(pq === null ? {} : { terminal: { url: adresseLocale(pq) } }) };
};
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));
const adresses = (url) => `Cockpit : ${url}/ (Code) · ${url}/project.html (Projet)`;
// AUDC-H3 : le journal du serveur (serveur.log) reçoit aussi les décisions du lanceur, datées, avec leur motif (jamais un jeton ni un contenu)
// AUDC-H3 : empreinte du code que le serveur en cours a chargé (server.json.hash, écrite au démarrage) contre celle de la sortie assemblée ; différentes = le serveur tourne sur un code périmé
// 79-06 (SOCL-08) : l'empreinte couvre tout le code évalué du MODULE (même fonction que le serveur) ; le serveur est le serve.mjs du module, jamais un fichier de la sortie
const empreinteDuModule = () => empreinteModule({ dossierScripts: HERE, dossierMoteur: engineDir(HERE).chemin || '' });
const serveDuModule = () => { try { return fs.realpathSync(path.join(engineDir(HERE).chemin || '', 'assets', 'serve.mjs')); } catch { return null; } };
const motEntier = (cmd, mot) => !!mot && (` ${cmd} `).includes(` ${mot} `);
// 67-SECURITY M3 : le lanceur n'exécute JAMAIS un script du lab (serve.mjs de la sortie compris). Arrêt par signal, sur un PID que le fichier
// d'état du lab (donc non fiable) désigne : entier > 1, ni le nôtre, vivant, et dont la ligne de commande est le serve.mjs de CETTE sortie.
// Dit UNE fois par processus : estNotre est rappelée à chaque tour d'attente du terminal (100 fois) et l'absence de `ps` ne change pas entre deux appels.
// N12 (P71-D-29, 2026-11-04) : les binaires du lanceur (ps, ouvreur, python3) sont cherchés dans le PATH ASSAINI du lab (envEnfant : ni vide, ni relatif, ni dossier du lab,
// y compris absolu : `<lab>/bin` de `npm run` ou de direnv), jamais dans le PATH brut. L'ouvreur reçoit ce même environnement (xdg-open cherche ses auxiliaires dans son PATH).
// Le shell du terminal garde le PATH d'origine (P71-D-03) : ceci ne concerne que les processus que le lanceur exécute lui-même.
let LABV = null; const pathSur = () => envEnfant(LABV).PATH;
let psDit = false;
function estNotre(pid, serve, lab) {
  if (!Number.isInteger(pid) || pid <= 1 || pid === process.pid || !vivant(pid)) return false;
  if (process.platform === 'win32') return true; // pas de `ps` : le PID vient du fichier d'état, reste borné ci-dessus
  const ps = resoudreBinaire('ps', pathSur());
  if (!ps) { if (!psDit) { psDit = true; console.error("arrêt refusé : « ps » est introuvable dans les éléments absolus du PATH, le serveur n'est pas arrêté (un PID du lab n'est jamais signalé sans vérification)."); } return false; }
  try {
    const cmd = execFileSync(ps, ['-o', 'command=', '-p', String(pid)], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 5000, env: envEnfant(lab) });
    // identité : serve.mjs du module en mot entier ET --sortie=<chemin réel> exact en fin de ligne ; l'ancienne forme (<sortie>/serve.mjs, sans --sortie=) reste reconnue pendant la transition (P79-D-26, à retirer à la version suivante)
    const c = cmd.trimEnd(), sortie = path.dirname(serve); let reelle = sortie; try { reelle = fs.realpathSync(sortie); } catch {}
    return (motEntier(c, serveDuModule()) && c.endsWith(` --sortie=${reelle}`)) || motEntier(c, serve) || motEntier(c, path.join(reelle, 'serve.mjs'));
  } catch { return false; }
}
function arreter(sortie) {
  const s = lireEtat(sortie);
  const serve = path.join(sortie, 'serve.mjs');
  if (!s || !estNotre(s.pid, serve, path.resolve(sortie, '..', '..'))) return false;
  try { process.kill(s.pid, 'SIGTERM'); return true; } catch { return false; }
}

// P71-D-11, O3 : amorçage du terminal écrit AVANT le démarrage du serveur ; jamais imprimé, journalisé ni passé au serveur.
// Suppression préalable puis création exclusive (`wx`) : un lien préplacé n'est jamais suivi ; mode 0600.
const MODE_AMORCE = 0o600;
const MODE_PAGE = 0o600;
function ecrireAmorce(sortie) {
  const f = path.join(sortie, '.cache', 'terminal-amorce');
  const valeur = crypto.randomBytes(32).toString('hex');
  try {
    fs.mkdirSync(path.dirname(f), { recursive: true });
    try { fs.unlinkSync(f); } catch (e) { if (e.code !== 'ENOENT') throw e; }
    const fd = fs.openSync(f, 'wx', MODE_AMORCE);
    try { fs.writeSync(fd, valeur); } finally { fs.closeSync(fd); }
  } catch { console.error('amorçage du terminal impossible : fichier inattendu dans .cache'); process.exit(5); }
  return valeur;
}
const amorcer = (lab, sortie) => { verifierSortie(lab, sortie); return ecrireAmorce(sortie); };
const effacerAmorce = (sortie) => { for (const n of ['terminal-amorce', FICHIER_SECRET_OUVRIR]) { try { fs.unlinkSync(path.join(sortie, '.cache', n)); } catch {} } };
// même ouvreur que serve.mjs, détaché, sorties ignorées. L'erreur ASYNCHRONE du spawn (ouvreur absent : ENOENT, pas de xdg-open) est rattrapée : sans écouteur
// elle ferait tomber le lanceur avec une trace. `surErreur(err)` la reçoit ; par défaut elle est dite en clair avec `marche`.
const OUVERTURE_MS = (() => { const n = Number(process.env.VF_COCKPIT_OUVERTURE_MS); return Number.isInteger(n) && n >= 100 && n <= 60000 ? n : 15000; })(); // réglage de test seulement
function ouvrir(url, marche = '', surErreur = null) {
  const op = process.platform === 'win32' ? ['cmd', ['/c', 'start', '', url]] : process.platform === 'darwin' ? ['open', [url]] : ['xdg-open', [url]];
  const dire = (e) => { if (surErreur) surErreur(e); else console.error(`ouverture impossible : « ${op[0]} » ne se lance pas (${(e && e.code) || (e && e.message) || 'erreur'}).${marche ? ' ' + marche : ''}`); };
  try {
    const exe = resoudreBinaire(op[0], pathSur()); // N2 : chemin absolu, jamais le nom nu (le cwd est le lab)
    if (!exe) { setImmediate(() => dire(Object.assign(new Error(`${op[0]} introuvable dans les éléments absolus du PATH`), { code: 'ENOENT' }))); return; }
    const enfant = spawn(exe, op[1], { stdio: 'ignore', detached: true, env: envEnfant(LABV) });
    enfant.on('error', dire);
    enfant.unref();
  } catch (e) { dire(e); }
}
// P71-D-12, P71-D-27 (F6), SAF-1 : l'onglet s'ouvre sur la page Projet (P), qui monte le cadre de Q et lui passe l'amorçage ; l'échange se fait DANS le cadre (Safari découpe
// le stockage d'un cadre par origine de premier niveau, port compris : un secret posé par Q au premier niveau serait illisible depuis le cadre de P). L'amorçage n'est JAMAIS dans l'argv de l'ouvreur (lisible par `ps`).
// Le lanceur écrit une page de redirection (0600, suppression préalable puis création exclusive : aucun lien suivi) dans .cache, l'ouvreur ne reçoit
// que son chemin. Le serveur la supprime dès l'échange de l'amorçage, et la balaie au plus tard 60 s après sa création.
// AUDC-B-03 bis : secret d'ouverture, distinct de la clé, écrit comme elle (suppression préalable, création exclusive, 0600) ; il rend la page de redirection la seule
// navigation inter-sites que le serveur admet vers la page Projet. Jamais imprimé ni passé à un ouvreur.
function ecrireSecretOuvrir(sortie) {
  const f = path.join(sortie, '.cache', FICHIER_SECRET_OUVRIR), valeur = crypto.randomBytes(32).toString('hex');
  try {
    try { fs.unlinkSync(f); } catch (e) { if (e.code !== 'ENOENT') throw e; }
    const fd = fs.openSync(f, 'wx', MODE_AMORCE);
    try { fs.writeSync(fd, valeur); } finally { fs.closeSync(fd); }
  } catch { return null; }
  return valeur;
}
function ecrirePageOuvrir(sortie, cible) {
  const f = path.join(sortie, '.cache', FICHIER_OUVRIR);
  const html = `<!doctype html>\n<meta charset="utf-8">\n<meta name="referrer" content="no-referrer">\n<meta http-equiv="refresh" content="0;url=${cible}">\n<title>Terminal</title>\n`;
  try {
    try { fs.unlinkSync(f); } catch (e) { if (e.code !== 'ENOENT') throw e; }
    const fd = fs.openSync(f, 'wx', MODE_PAGE);
    try { fs.writeSync(fd, html); } finally { fs.closeSync(fd); }
  } catch { return null; }
  return f;
}
// Rend { page, echec } : `echec` reçoit l'erreur asynchrone de l'ouvreur (lue par attendreOuverture), null si l'ouverture n'est pas tentée.
function ouvrirQ(s, amorce, o, sortie) {
  if (o.noOpen) return null;
  const secret = ecrireSecretOuvrir(sortie);
  const page = secret ? ecrirePageOuvrir(sortie, `${s.url}/project.html?o=${secret}#t=${amorce}`) : null;
  if (!page) { effacerAmorce(sortie); console.error("ouverture du terminal impossible : fichier inattendu dans .cache"); return null; }
  const suivi = { page, echec: null };
  ouvrir(page, '', (e) => { suivi.echec = e; });
  return suivi;
}
// M6 : l'ouvreur du poste (association de fichiers) peut ne pas charger la page : `.html` associé à un éditeur, navigateur sans accès aux dossiers cachés (Firefox
// en snap sous Linux), ouvreur absent. Il ne rend jamais d'échec : la seule preuve d'ouverture est l'amorçage consommé par le serveur (fichier effacé à l'échange).
// Au-delà de OUVERTURE_MS (15 s) sans cette preuve, ou dès que l'ouvreur ne se lance pas, le lanceur le dit avec la marche à suivre ; le principe de P71-D-27 ne change pas.
async function attendreOuverture(suivi, sortie) {
  if (!suivi) return;
  const amorce = path.join(sortie, '.cache', 'terminal-amorce');
  const fin = Date.now() + OUVERTURE_MS;
  while (!suivi.echec && fs.existsSync(amorce) && Date.now() < fin) await attendre(100);
  if (!suivi.echec && !fs.existsSync(amorce)) return;
  const cause = suivi.echec ? `l'ouvreur du poste ne se lance pas (${suivi.echec.code || suivi.echec.message || 'erreur'})` : `le navigateur n'a pas chargé la page en ${Math.round(OUVERTURE_MS / 1000)} s (ouvreur qui envoie le .html à un éditeur, ou navigateur sans accès aux dossiers cachés, comme Firefox en snap sous Linux)`;
  console.error(`le terminal ne s'est pas ouvert : ${cause}. Ouvrez ce fichier dans un navigateur, dans la minute qui suit : ${suivi.page} ; ou relancez cette commande après avoir réglé l'ouvreur du poste pour les fichiers .html.`);
}
// F1 : une adresse de Q n'est remise à l'ouvreur que si le processus de server.json est le serveur de CETTE sortie (estNotre)
const termOuvrable = (s, sortie) => !!(s && s.terminal && s.terminal.url) && estNotre(s.pid, path.join(sortie, 'serve.mjs'));
async function attendreTerminal(sortie) {
  for (let i = 0; i < 100; i++) { const s = serveurVivant(sortie); if (s && termOuvrable(s, sortie)) return s; await attendre(100); }
  return null;
}

async function assemblerLab(lab, scriptsDir) {
  const { assembler } = await import('./vf-cockpit-build.mjs');
  try { assembler({ lab, scriptsDir }); }
  catch (e) { console.error(e.message); process.exit(e.code === 2 || e.code === 3 ? e.code : 4); }
}

// E5 : borne d'attente du démarrage du serveur. 30 s par défaut (réglage de test seulement : VF_COCKPIT_DEMARRAGE_MS, 1 s à 120 s) ; le message « démarrage lent » vient après 5 s, ou à mi-borne si elle est plus courte.
const DEMARRAGE_MS = (() => { const n = Number(process.env.VF_COCKPIT_DEMARRAGE_MS); return Number.isInteger(n) && n >= 1000 && n <= 120000 ? n : 30000; })();
const LENT_MS = Math.min(5000, Math.floor(DEMARRAGE_MS / 2));
async function demarrer(lab, sortie, o) {
  try { fs.unlinkSync(etatFile(sortie)); } catch {} // état d'un serveur mort : jamais pris pour un démarrage
  verifierSortie(lab, sortie);
  const logFd = fs.openSync(path.join(sortie, '.cache', 'serveur.log'), 'a');
  const serve = serveDuModule(); if (!serve) throw Object.assign(new Error('serveur du cockpit introuvable (serve.mjs absent du module)'), { code: 3 }); // jamais de repli sur la sortie du lab
  const args = [serve, '--idle-exit', '60'];
  args.push('--no-open'); // N2 (P71-D-29) : le serveur ne lance jamais l'ouvreur par son nom depuis le lab ; le lanceur ouvre lui-même, par chemin absolu (ouvrir)
  if (o.terminal) args.push('--terminal');
  // port stable par lab (O4) : --port de l'utilisateur d'abord, sinon l'empreinte du lab ; le repli port+1 reste celui du serveur
  args.push('--port', String(o.port || portPrefere(lab)));
  args.push(`--sortie=${fs.realpathSync(sortie)}`); // DERNIER argument : la sortie du lab ne porte que des données, le serveur est celui du module
  // le serveur ne se fie qu'à ces deux chemins, posés ici depuis le module (jamais lus dans un .cache/ du lab) ; le dossier de scripts est celui de CE fichier,
  // jamais une variable VF_COCKPIT_SCRIPTS_DIR héritée de l'environnement du lanceur (AUDC-B-06)
  const env = { ...envEnfant(lab), VF_COCKPIT_ENGINE_DIR: engineDir(HERE).chemin || '', VF_COCKPIT_SCRIPTS_DIR: HERE };
  // P71-D-03 (arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-03) : le shell du terminal reçoit le PATH D'ORIGINE du lanceur. Le serveur et ses enfants
  // gardent le PATH assaini (H-1) ; le PATH d'origine voyage dans VF_COCKPIT_PATH_ORIGINE jusqu'au filtre du shell (vf-cockpit-terminal-env.mjs), qui le restitue en PATH puis le retire.
  if (typeof process.env.PATH === 'string') env.VF_COCKPIT_PATH_ORIGINE = process.env.PATH;
  const enfant = spawn(process.execPath, args, { cwd: lab, env, detached: true, stdio: ['ignore', logFd, logFd] });
  enfant.unref();
  fs.closeSync(logFd);
  // E5 : sous charge, le serveur met jusqu'à ~19 s à écrire son état. Tant qu'il vit, le lanceur attend jusqu'à DEMARRAGE_MS (30 s) ; passé LENT_MS il dit « démarrage lent »
  // UNE fois. Un serveur qui s'est arrêté sans écrire d'état est un échec certain (aucune raison d'attendre la borne).
  let fini = false; enfant.on('exit', () => { fini = true; });
  const debut = Date.now(); let dit = false;
  for (;;) {
    const s = serveurVivant(sortie);
    if (s) return s;
    if (fini) return null;
    const ecoule = Date.now() - debut;
    if (ecoule >= DEMARRAGE_MS) return null;
    if (!dit && ecoule >= LENT_MS) { dit = true; console.error(`démarrage lent… le serveur n'a pas encore écrit son état, attente jusqu'à ${Math.round(DEMARRAGE_MS / 1000)} s (machine chargée ?).`); }
    await attendre(100);
  }
}

async function main() {
  const o = lireArgs(process.argv.slice(2));
  if (o.erreur) { console.error(`${o.erreur}\n${AIDE}`); process.exit(64); }
  if (o.aide) { console.log(AIDE); return; }
  const lab = findLabRoot(o.lab || process.cwd());
  if (!lab) { console.error('aucun dossier .planning trouvé : le cockpit se construit dans un lab GSD.'); process.exit(2); }
  const scriptsDir = HERE; LABV = lab; // AUDC-B-06 : le dossier de scripts du module, jamais une valeur héritée
  const sortie = outputDir(lab);

  if (o.verbe === 'status') {
    const s = serveurVivant(sortie);
    console.log(s ? `${adresses(s.url)} · PID ${s.pid}` : 'Cockpit arrêté.');
    return;
  }
  if (o.verbe === 'stop') {
    const s = serveurVivant(sortie);
    if (!s) { console.log('Cockpit déjà arrêté.'); return; }
    noter(sortie, `arrêt demandé (« stop »), serveur PID ${s.pid}`);
    if (!arreter(sortie)) { console.error(`PID ${s.pid} non reconnu comme le serveur de ce cockpit : rien n'a été arrêté (fichier d'état du lab non fiable).`); process.exit(5); }
    for (let i = 0; i < 30 && vivant(s.pid); i++) await attendre(100);
    console.log(vivant(s.pid) ? `Le serveur (PID ${s.pid}) tarde à s'arrêter.` : 'Cockpit arrêté.');
    return;
  }
  if (o.verbe === 'build') { await assemblerLab(lab, scriptsDir); return; }

  // open : réutiliser un serveur vivant du même lab, sauf --rebuild
  const demande = o.terminal; // le terminal a été DEMANDÉ : s'il est écarté plus bas, le cockpit s'ouvre quand même (P71-D-36, R4)
  const win = o.terminal && process.platform === 'win32'; // P71-D-07 : pas de terminal sous Windows, le cockpit s'ouvre comme avant
  if (win) console.error('Terminal indisponible sous Windows.');
  // E4 : le terminal exige python3 (assistant PTY). Résolu comme le fait le serveur (éléments absolus du PATH, chemin absolu) AVANT tout amorçage ou ouverture de Q.
  // Introuvable : message en français avec la marche à suivre, puis le cockpit s'ouvre SANS terminal, code 0 (le cockpit reste utile ; l'échec n'est pas muet).
  if (o.terminal && !win && !resoudreBinaire('python3', pathSur())) {
    console.error("Terminal indisponible : python3 introuvable dans les éléments absolus du PATH. Installez Python 3 (macOS : « xcode-select --install » ou « brew install python » ; Linux : « apt install python3 » ou l'équivalent de votre distribution), puis relancez avec --terminal. Le cockpit s'ouvre sans terminal.");
    o.terminal = false;
  }
  o.avecQ = o.terminal && !win;
  const libere = await prendreVerrou(lab, sortie, { vivant, attendre }); process.on('exit', libere); // AUDC-H3 : relâché avant l'attente d'ouverture, sinon à la sortie
  const vif = serveurVivant(sortie) || (fs.existsSync(path.join(sortie, 'index.html')) && !o.rebuild ? await serveurOrphelin(lab, sortie, o.port ? Number(o.port) : portPrefere(lab), { estNotre, etatFile, adresseLocale, serveurVivant, noter }) : null);
  const perime = !!(vif && vif.hash && empreinteDuModule() && vif.hash !== empreinteDuModule());
  if (vif && !o.rebuild && !perime) {
    // R4 (P71-D-36) : --terminal écarté (python3 absent, Windows) alors que le serveur vit déjà : le message dit « le cockpit s'ouvre sans terminal », on l'ouvre (comme au cas sans serveur) ;
    // une relance ordinaire, sans --terminal, garde son comportement : l'adresse seule.
    if (!o.avecQ) { if (demande && !o.noOpen && estNotre(vif.pid, path.join(sortie, 'serve.mjs'))) ouvrir(vif.url, `Ouvrez ${vif.url} dans un navigateur.`); console.log(adresses(vif.url)); return; }
    if (termOuvrable(vif, sortie)) { const suivi = ouvrirQ(vif, amorcer(lab, sortie), o, sortie); console.log(adresses(vif.url)); libere(); await attendreOuverture(suivi, sortie); return; } // O2 c : même serveur, nouvel amorçage
  }
  if (vif) noter(sortie, `relance : serveur PID ${vif.pid} remplacé (${o.rebuild ? '--rebuild demandé' : perime ? `code du serveur changé, empreinte ${vif.hash} -> ${empreinteDuModule()}` : '--terminal demandé, aucun terminal enregistré pour le serveur en cours'})`);
  if (vif) { if (!arreter(sortie)) { console.error(`PID ${vif.pid} non reconnu comme le serveur de ce cockpit : rien n'a été arrêté.`); process.exit(5); } for (let i = 0; i < 30 && vivant(vif.pid); i++) await attendre(100); }
  if (engineDir(scriptsDir).etat !== 'trouve') { console.error('moteur du cockpit introuvable : réinstaller le module cockpit.'); process.exit(3); }
  if (!serveDuModule()) { console.error('serveur du cockpit introuvable (serve.mjs absent du module) : réinstaller le module cockpit.'); process.exit(3); } // 79-06 F1 : jamais de repli sur un serve.mjs de la sortie du lab
  await assemblerLab(lab, scriptsDir);
  const amorce = o.avecQ ? amorcer(lab, sortie) : null; // avant le démarrage : le serveur ne reçoit jamais la valeur
  let s = await demarrer(lab, sortie, o), suivi = null;
  if (s && o.avecQ) {
    const t = await attendreTerminal(sortie);
    if (t) { s = t; suivi = ouvrirQ(t, amorce, o, sortie); }
    else { effacerAmorce(sortie); console.error("le terminal n'a pas démarré (voir serveur.log) ; le cockpit est ouvert sans terminal."); if (!o.noOpen) ouvrir(s.url, `Ouvrez ${s.url} dans un navigateur.`); }
  }
  if (!s) { console.error(`le serveur n'a pas démarré : voir ${path.join(sortie, '.cache', 'serveur.log')}`); process.exit(5); }
  if (!o.avecQ && !o.noOpen) ouvrir(s.url, `Ouvrez ${s.url} dans un navigateur.`);
  console.log(adresses(s.url));
  libere();
  await attendreOuverture(suivi, sortie);
}
// Jamais de trace : un échec non prévu (lien symbolique planté sur le chemin de sortie en voie de réutilisation du serveur, par exemple) s'écrit en une ligne et sort avec un code documenté.
main().catch((e) => { console.error(e && e.message ? e.message : String(e)); process.exit(e && [2, 3, 4, 5, 64].includes(e.code) ? e.code : 5); });
