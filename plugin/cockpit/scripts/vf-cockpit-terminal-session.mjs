// vf-cockpit-terminal-session — la session unique du terminal intégré : lancement de l'assistant PTY, flux, entrée, taille (71-01).
// Export : creerSessions({ engineDir, lab, jetons }) -> { attacher, ecrire, redimensionner, etat, occupe, arreterTout }.
// Une seule session. L'assistant (vf-cockpit-pty.py de l'arbre du moteur, lancé en mode isolé) ne se lance qu'à la PREMIÈRE attache, jamais avant ; il
// n'est jamais détaché : il meurt avec le serveur. Sa sortie (descripteur 1) est le flux ; son descripteur 2 porte l'état (FIN, SIG) et n'est
// jamais journalisé ; le descripteur 3 reçoit les tailles. Les messages nomment des états, jamais des données du terminal.
// Limite de cette tranche (complétée par 71-04) : un flux fermé laisse la session « detachee » sans tampon ni délai de grâce.
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { envShell, choisirShell } from './vf-cockpit-terminal-env.mjs';
import { nouveauSecret } from './vf-cockpit-terminal-amorce.mjs';

const ONGLET_RE = /^[A-Za-z0-9_-]{1,64}$/;
const log = (m) => console.error(`vf-cockpit (terminal) : ${m}`);

export function creerSessions({ engineDir, lab, jetons = () => [] }) {
  let s = null; // { enfant, onglet, res, etat, code, signal }
  const secretShell = nouveauSecret(); // jamais transmis tel quel : sert à écarter de l'environnement tout ce qui le contiendrait

  const detacher = (cible, res) => { if (cible.res === res && cible.etat === 'vivante') { cible.res = null; cible.etat = 'detachee'; } };
  const fin = (cible, code, signal) => {
    if (cible.etat === 'terminee') return;
    cible.etat = 'terminee'; if (code !== undefined) cible.code = code; if (signal !== undefined) cible.signal = signal;
    const r = cible.res; cible.res = null; try { r?.end(); } catch {}
  };

  function lancer(onglet, lignes, colonnes) {
    const assistant = path.join(engineDir, 'terminal', 'vf-cockpit-pty.py');
    const enfant = spawn('python3', ['-I', assistant, String(lignes), String(colonnes), choisirShell(process.env)], {
      cwd: fs.realpathSync(lab), env: envShell(process.env, [...jetons(), secretShell]), stdio: ['pipe', 'pipe', 'pipe', 'pipe'],
    });
    const cible = { enfant, onglet, res: null, etat: 'vivante', code: null, signal: null };
    enfant.stdout.on('data', (b) => {
      const r = cible.res; if (!r) return; // sans flux attaché, la sortie est perdue (tampon : 71-04)
      if (!r.write(b)) { enfant.stdout.pause(); r.once('drain', () => enfant.stdout.resume()); }
    });
    let reste = '';
    enfant.stderr.on('data', (b) => { // état de l'assistant : lignes « FIN <code> » ou « SIG <n> » seulement
      reste += b.toString('utf8'); let i;
      while ((i = reste.indexOf('\n')) >= 0) {
        const l = reste.slice(0, i); reste = reste.slice(i + 1);
        const m = /^(FIN|SIG) (\d{1,3})$/.exec(l);
        if (m) fin(cible, m[1] === 'FIN' ? Number(m[2]) : null, m[1] === 'SIG' ? Number(m[2]) : null);
      }
    });
    enfant.stdin.on('error', () => {}); enfant.stdio[3].on('error', () => {});
    enfant.on('error', () => { log('python3 est introuvable ou ne se lance pas : le terminal est arrêté.'); fin(cible, null, null); });
    enfant.on('close', () => fin(cible)); // la session terminée reste lisible par /etat
    return cible;
  }

  return {
    // rend 200 (réponse prise en charge), 400 ou 409 ; les autres statuts sont écrits par l'appelant
    attacher(req, res, { onglet, lignes = 24, colonnes = 80 } = {}) {
      if (!ONGLET_RE.test(String(onglet || ''))) return 400;
      if (!Number.isInteger(lignes) || !Number.isInteger(colonnes) || lignes < 1 || lignes > 999 || colonnes < 1 || colonnes > 999) return 400;
      if (s && s.etat !== 'terminee' && s.onglet !== onglet) return 409;
      if (!s || s.etat === 'terminee') s = lancer(onglet, lignes, colonnes);
      else if (s.res) { try { s.res.end(); } catch {} } // même onglet : le nouveau flux remplace l'ancien
      const cible = s; cible.res = res; cible.etat = 'vivante';
      res.writeHead(200, { 'Content-Type': 'application/octet-stream', 'Cache-Control': 'no-store' });
      res.on('close', () => detacher(cible, res));
      return 200;
    },
    ecrire(octets, onglet) {
      if (!s || s.etat === 'terminee') return 410;
      if (s.onglet !== onglet) return 409;
      try { s.enfant.stdin.write(octets); } catch { return 410; }
      return 204;
    },
    redimensionner(lignes, colonnes, onglet) {
      if (!s || s.etat === 'terminee') return 410;
      if (s.onglet !== onglet) return 409;
      try { s.enfant.stdio[3].write(`R ${lignes} ${colonnes}\n`); } catch { return 410; }
      return 204;
    },
    etat: () => ({ session: s ? s.etat : 'absente', code: s ? s.code : null, signal: s ? s.signal : null }),
    occupe: () => !!s && s.etat !== 'terminee',
    arreterTout() {
      if (!s) return;
      const e = s.enfant; s.etat = 'terminee'; s.res = null;
      try { e.stdin.end(); } catch {}
      try { e.kill('SIGTERM'); } catch {}
    },
  };
}
