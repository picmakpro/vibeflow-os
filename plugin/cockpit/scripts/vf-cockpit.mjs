#!/usr/bin/env node
// vf-cockpit — lanceur du cockpit d'un lab (67-06 ; P67-D-05, P67-D-06).
// Verbes : open (défaut) · build · stop · status. Options : --lab <dossier> · --no-open · --port <p> · --rebuild · --help.
// Écrit sous <lab>/.vibeflow/cockpit/ (ignoré par git), sert 127.0.0.1 par le serveur unique de la sortie.
// Codes : 0 succès · 2 lab sans .planning/ · 3 moteur absent · 4 assemblage en échec · 5 serveur non démarré · 64 usage.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';
import { findLabRoot, engineDir, outputDir, resolveScriptsDir } from './vf-cockpit-paths.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const AIDE = `Usage : node vf-cockpit.mjs [open|build|stop|status] [--lab <dossier>] [--no-open] [--port <p>] [--rebuild]
  open    assemble le cockpit du lab s'il le faut, démarre le serveur local et rend l'adresse (défaut)
  build   assemble le cockpit sans démarrer de serveur
  stop    arrête le serveur du lab
  status  dit l'adresse et le PID du serveur, ou « arrêté »
Codes : 0 succès · 2 lab sans .planning/ · 3 moteur absent · 4 assemblage en échec · 5 serveur non démarré`;

const VERBES = ['open', 'build', 'stop', 'status'];
function lireArgs(argv) {
  const o = { verbe: 'open', lab: null, noOpen: false, port: null, rebuild: false, aide: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--help' || a === '-h') o.aide = true;
    else if (a === '--no-open') o.noOpen = true;
    else if (a === '--rebuild') o.rebuild = true;
    else if (a === '--lab') o.lab = argv[++i];
    else if (a === '--port') o.port = argv[++i];
    else if (VERBES.includes(a)) o.verbe = a;
    else return { erreur: `argument inconnu : ${a}` };
  }
  if (o.port !== null && !/^\d{1,5}$/.test(String(o.port))) return { erreur: `port invalide : ${o.port}` };
  return o;
}

const etatFile = (sortie) => path.join(sortie, '.cache', 'server.json');
const lireEtat = (sortie) => { try { return JSON.parse(fs.readFileSync(etatFile(sortie), 'utf8')); } catch { return null; } };
const vivant = (pid) => { try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; } };
const serveurVivant = (sortie) => { const s = lireEtat(sortie); return s && s.pid && s.url && vivant(s.pid) ? s : null; };
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));
const adresses = (url) => `Cockpit : ${url}/ (Code) · ${url}/project.html (Projet)`;

function arreter(sortie) {
  const serve = path.join(sortie, 'serve.mjs');
  if (!fs.existsSync(serve)) return false;
  const r = spawnSync(process.execPath, [serve, '--stop'], { encoding: 'utf8' });
  return r.status === 0;
}

async function assemblerLab(lab, scriptsDir) {
  const { assembler } = await import('./vf-cockpit-build.mjs');
  try { assembler({ lab, scriptsDir }); }
  catch (e) { console.error(e.message); process.exit(e.code === 2 || e.code === 3 ? e.code : 4); }
}

async function demarrer(lab, sortie, o) {
  try { fs.unlinkSync(etatFile(sortie)); } catch {} // état d'un serveur mort : jamais pris pour un démarrage
  const logFd = fs.openSync(path.join(sortie, '.cache', 'serveur.log'), 'a');
  const args = [path.join(sortie, 'serve.mjs'), '--idle-exit', '60'];
  if (o.noOpen) args.push('--no-open');
  if (o.port) args.push('--port', String(o.port));
  const enfant = spawn(process.execPath, args, { cwd: lab, detached: true, stdio: ['ignore', logFd, logFd] });
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
    arreter(sortie);
    for (let i = 0; i < 30 && vivant(s.pid); i++) await attendre(100);
    console.log(vivant(s.pid) ? `Le serveur (PID ${s.pid}) tarde à s'arrêter.` : 'Cockpit arrêté.');
    return;
  }
  if (o.verbe === 'build') { await assemblerLab(lab, scriptsDir); return; }

  // open : réutiliser un serveur vivant du même lab, sauf --rebuild
  const vif = serveurVivant(sortie);
  if (vif && !o.rebuild) { console.log(adresses(vif.url)); return; }
  if (vif) { arreter(sortie); for (let i = 0; i < 30 && vivant(vif.pid); i++) await attendre(100); }
  if (engineDir(scriptsDir).etat !== 'trouve') { console.error('moteur du cockpit introuvable : réinstaller le module cockpit.'); process.exit(3); }
  await assemblerLab(lab, scriptsDir);
  const s = await demarrer(lab, sortie, o);
  if (!s) { console.error(`le serveur n'a pas démarré : voir ${path.join(sortie, '.cache', 'serveur.log')}`); process.exit(5); }
  console.log(adresses(s.url));
}
main();
