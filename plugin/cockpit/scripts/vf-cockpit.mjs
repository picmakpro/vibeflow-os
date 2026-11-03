#!/usr/bin/env node
// vf-cockpit — lanceur du cockpit d'un lab (67-06 ; P67-D-05, P67-D-06).
// Verbes : open (défaut) · build · stop · status. Options : --lab <dossier> · --no-open · --port <p> · --rebuild · --terminal · --help.
// Écrit sous <lab>/.vibeflow/cockpit/ (ignoré par git), sert 127.0.0.1 par le serveur unique de la sortie.
// Codes : 0 succès · 2 lab sans .planning/ · 3 moteur absent · 4 assemblage en échec · 5 serveur non démarré · 64 usage.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import crypto from 'node:crypto';
import { spawn, execFileSync } from 'node:child_process';
import { envEnfant } from './vf-cockpit-env.mjs';
import { findLabRoot, engineDir, outputDir, resolveScriptsDir, verifierSortie } from './vf-cockpit-paths.mjs';
import { portPrefere } from './vf-cockpit-port.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const AIDE = `Usage : node vf-cockpit.mjs [open|build|stop|status] [--lab <dossier>] [--no-open] [--port <p>] [--rebuild] [--terminal]
  open    assemble le cockpit du lab s'il le faut, démarre le serveur local et rend l'adresse (défaut)
  build   assemble le cockpit sans démarrer de serveur
  stop    arrête le serveur du lab
  status  dit l'adresse et le PID du serveur, ou « arrêté »
  --terminal  ouvre aussi un terminal dans le tiroir de la page (macOS, Linux)
Codes : 0 succès · 2 lab sans .planning/ · 3 moteur absent · 4 assemblage en échec · 5 serveur non démarré`;

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
const serveurVivant = (sortie) => { const s = lireEtat(sortie); return s && s.pid && s.url && vivant(s.pid) ? s : null; };
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));
const adresses = (url) => `Cockpit : ${url}/ (Code) · ${url}/project.html (Projet)`;

// 67-SECURITY M3 : le lanceur n'exécute JAMAIS un script du lab (serve.mjs de la sortie compris). Arrêt par signal, sur un PID que le fichier
// d'état du lab (donc non fiable) désigne : entier > 1, ni le nôtre, vivant, et dont la ligne de commande est le serve.mjs de CETTE sortie.
function estNotre(pid, serve, lab) {
  if (!Number.isInteger(pid) || pid <= 1 || pid === process.pid || !vivant(pid)) return false;
  if (process.platform === 'win32') return true; // pas de `ps` : le PID vient du fichier d'état, reste borné ci-dessus
  try {
    const cmd = execFileSync('ps', ['-o', 'command=', '-p', String(pid)], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 5000, env: envEnfant(lab) });
    return cmd.includes(serve) || cmd.includes(fs.realpathSync(serve));
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
const effacerAmorce = (sortie) => { try { fs.unlinkSync(path.join(sortie, '.cache', 'terminal-amorce')); } catch {} };
// même ouvreur que serve.mjs, détaché, sorties ignorées
function ouvrir(url) {
  const op = process.platform === 'win32' ? ['cmd', ['/c', 'start', '', url]] : process.platform === 'darwin' ? ['open', [url]] : ['xdg-open', [url]];
  try { spawn(op[0], op[1], { stdio: 'ignore', detached: true }).unref(); } catch {}
}
// P71-D-12 : l'onglet s'ouvre sur la page du terminal (Q), l'amorçage dans le fragment ; le serveur ne s'ouvre pas lui-même
function ouvrirQ(s, amorce, o) { if (!o.noOpen) ouvrir(`${s.terminal.url}/#t=${amorce}`); }
async function attendreTerminal(sortie) {
  for (let i = 0; i < 100; i++) { const s = serveurVivant(sortie); if (s && s.terminal && s.terminal.url) return s; await attendre(100); }
  return null;
}
const termActif = (s) => !!(s && s.terminal && s.terminal.url);

async function assemblerLab(lab, scriptsDir) {
  const { assembler } = await import('./vf-cockpit-build.mjs');
  try { assembler({ lab, scriptsDir }); }
  catch (e) { console.error(e.message); process.exit(e.code === 2 || e.code === 3 ? e.code : 4); }
}

async function demarrer(lab, sortie, o) {
  try { fs.unlinkSync(etatFile(sortie)); } catch {} // état d'un serveur mort : jamais pris pour un démarrage
  verifierSortie(lab, sortie);
  const logFd = fs.openSync(path.join(sortie, '.cache', 'serveur.log'), 'a');
  const args = [path.join(sortie, 'serve.mjs'), '--idle-exit', '60'];
  if (o.noOpen || o.avecQ) args.push('--no-open');
  if (o.terminal) args.push('--terminal');
  // port stable par lab (O4) : --port de l'utilisateur d'abord, sinon l'empreinte du lab ; le repli port+1 reste celui du serveur
  args.push('--port', String(o.port || portPrefere(lab)));
  // le serveur ne se fie qu'à ces deux chemins, posés ici depuis le module (jamais lus dans un .cache/ du lab)
  const env = { ...envEnfant(lab), VF_COCKPIT_ENGINE_DIR: engineDir(resolveScriptsDir(HERE)).chemin || '', VF_COCKPIT_SCRIPTS_DIR: resolveScriptsDir(HERE) };
  const enfant = spawn(process.execPath, args, { cwd: lab, env, detached: true, stdio: ['ignore', logFd, logFd] });
  enfant.unref();
  fs.closeSync(logFd);
  for (let i = 0; i < 100; i++) { // borné à 10 s
    const s = serveurVivant(sortie);
    if (s) return s;
    await attendre(100);
  }
  return null;
}

async function main() {
  const o = lireArgs(process.argv.slice(2));
  if (o.erreur) { console.error(`${o.erreur}\n${AIDE}`); process.exit(64); }
  if (o.aide) { console.log(AIDE); return; }
  const lab = findLabRoot(o.lab || process.cwd());
  if (!lab) { console.error('aucun dossier .planning trouvé : le cockpit se construit dans un lab GSD.'); process.exit(2); }
  const scriptsDir = resolveScriptsDir(HERE);
  const sortie = outputDir(lab);

  if (o.verbe === 'status') {
    const s = serveurVivant(sortie);
    console.log(s ? `${adresses(s.url)} · PID ${s.pid}` : 'Cockpit arrêté.');
    return;
  }
  if (o.verbe === 'stop') {
    const s = serveurVivant(sortie);
    if (!s) { console.log('Cockpit déjà arrêté.'); return; }
    if (!arreter(sortie)) { console.error(`PID ${s.pid} non reconnu comme le serveur de ce cockpit : rien n'a été arrêté (fichier d'état du lab non fiable).`); process.exit(5); }
    for (let i = 0; i < 30 && vivant(s.pid); i++) await attendre(100);
    console.log(vivant(s.pid) ? `Le serveur (PID ${s.pid}) tarde à s'arrêter.` : 'Cockpit arrêté.');
    return;
  }
  if (o.verbe === 'build') { await assemblerLab(lab, scriptsDir); return; }

  // open : réutiliser un serveur vivant du même lab, sauf --rebuild
  const win = o.terminal && process.platform === 'win32'; // P71-D-07 : pas de terminal sous Windows, le cockpit s'ouvre comme avant
  if (win) console.error('Terminal indisponible sous Windows.');
  o.avecQ = o.terminal && !win;
  const vif = serveurVivant(sortie);
  if (vif && !o.rebuild) {
    if (!o.avecQ) { console.log(adresses(vif.url)); return; }
    if (termActif(vif)) { ouvrirQ(vif, amorcer(lab, sortie), o); console.log(adresses(vif.url)); return; } // O2 c : même serveur, nouvel amorçage
  }
  if (vif) { if (!arreter(sortie)) { console.error(`PID ${vif.pid} non reconnu comme le serveur de ce cockpit : rien n'a été arrêté.`); process.exit(5); } for (let i = 0; i < 30 && vivant(vif.pid); i++) await attendre(100); }
  if (engineDir(scriptsDir).etat !== 'trouve') { console.error('moteur du cockpit introuvable : réinstaller le module cockpit.'); process.exit(3); }
  await assemblerLab(lab, scriptsDir);
  const amorce = o.avecQ ? amorcer(lab, sortie) : null; // avant le démarrage : le serveur ne reçoit jamais la valeur
  let s = await demarrer(lab, sortie, o);
  if (s && o.avecQ) {
    const t = await attendreTerminal(sortie);
    if (t) { s = t; ouvrirQ(t, amorce, o); }
    else { effacerAmorce(sortie); console.error("le terminal n'a pas démarré (voir serveur.log) ; le cockpit est ouvert sans terminal."); if (!o.noOpen) ouvrir(s.url); }
  }
  if (!s) { console.error(`le serveur n'a pas démarré : voir ${path.join(sortie, '.cache', 'serveur.log')}`); process.exit(5); }
  console.log(adresses(s.url));
}
main();
