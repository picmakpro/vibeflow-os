// vf-cockpit-terminal-session — la session unique du terminal intégré : lancement de l'assistant PTY, flux, entrée, taille (71-01).
// Export : creerSessions({ engineDir, lab, jetons }) -> { attacher, ecrire, redimensionner, etat, occupe, arreterTout }.
// Une seule session. L'assistant (vf-cockpit-pty.py de l'arbre du moteur, lancé en mode isolé) ne se lance qu'à la PREMIÈRE attache, jamais avant ; il
// n'est jamais détaché : il meurt avec le serveur. Sa sortie (descripteur 1) est le flux ; son descripteur 2 porte l'état (FIN, SIG) et n'est
// jamais journalisé ; le descripteur 3 reçoit les tailles. Les messages nomment des états, jamais des données du terminal.
// Cycle de vie (71-04 ; P71-D-05, P71-D-19) : un seul onglet propriétaire (autre onglet : 409) ; flux fermé -> état « detachee » et grâce de GRACE_MS ;
// retour du même onglet avant l'échéance -> même shell, tampon (TAMPON_MAX octets, MÉMOIRE SEULEMENT) rejoué puis direct ; échéance ou fin du shell -> EOF à
// l'assistant (SIGHUP au groupe), tampon vidé. Aucun octet du terminal n'est écrit sur disque ni passé à console.* (TERM-11).
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { envShell, choisirShell } from './vf-cockpit-terminal-env.mjs';
import { nouveauSecret } from './vf-cockpit-terminal-amorce.mjs';

const ONGLET_RE = /^[A-Za-z0-9_-]{1,64}$/;
const log = (m) => console.error(`vf-cockpit (terminal) : ${m}`);
export const TAMPON_MAX = 262144;
export const TAILLE_MAX = { lignes: 500, colonnes: 1000 }; // l'unique borne de taille : le serveur (/flux, /taille) et l'assistant PTY (vf-cockpit-pty.py) la tiennent à l'identique
const graceDepuis = (v) => { const n = Number(v); return Number.isInteger(n) && n >= 100 && n <= 30000 ? n : 30000; }; // réglage de test seulement (P71-PL-18)
export const GRACE_MS = graceDepuis(process.env.VF_COCKPIT_TERM_GRACE_MS);
const actif = (c) => !!c && (c.etat === 'vivante' || c.etat === 'detachee');

export function creerSessions({ engineDir, lab, jetons = () => [] }) {
  let s = null; // { enfant, onglet, res, etat, code, signal, minuterie, pause }
  let tampon = [], octets = 0; // tampon de reprise : les derniers TAMPON_MAX octets de la sortie, en mémoire seulement
  const secretShell = nouveauSecret(); // jamais transmis tel quel : sert à écarter de l'environnement tout ce qui le contiendrait

  const vider = () => { tampon = []; octets = 0; };
  const ajouter = (b) => {
    tampon.push(b); octets += b.length;
    while (octets > TAMPON_MAX) {
      const exces = octets - TAMPON_MAX, tete = tampon[0];
      if (tete.length <= exces) { tampon.shift(); octets -= tete.length; } else { tampon[0] = tete.subarray(exces); octets -= exces; }
    }
  };
  const reprendre = (c) => { if (c.pause) { c.pause = false; c.enfant.stdout.resume(); } };
  const terminer = (cible) => { // l'unique voie de fin : état, flux du client, minuterie, tampon
    if (cible.etat === 'terminee') return;
    clearTimeout(cible.minuterie); cible.etat = 'terminee';
    const r = cible.res; cible.res = null; try { r?.end(); } catch {}
    if (cible === s) vider();
  };
  const expirer = (cible) => { // échéance de la grâce : EOF à l'assistant (il envoie SIGHUP au groupe), la session disparaît
    if (s !== cible || cible.etat !== 'detachee') return;
    s = null; vider(); cible.etat = 'terminee';
    try { cible.enfant.stdin.end(); } catch {}
  };
  const detacher = (cible, res) => {
    if (cible.res !== res || cible.etat !== 'vivante') return;
    cible.res = null; cible.etat = 'detachee'; reprendre(cible);
    clearTimeout(cible.minuterie); cible.minuterie = setTimeout(() => expirer(cible), GRACE_MS); cible.minuterie.unref?.();
  };

  function lancer(onglet, lignes, colonnes) {
    const assistant = path.join(engineDir, 'terminal', 'vf-cockpit-pty.py');
    const enfant = spawn('python3', ['-I', assistant, String(lignes), String(colonnes), choisirShell(process.env)], {
      cwd: fs.realpathSync(lab), env: envShell(process.env, [...jetons(), secretShell]), stdio: ['pipe', 'pipe', 'pipe', 'pipe'],
    });
    const cible = { enfant, onglet, res: null, etat: 'vivante', code: null, signal: null, minuterie: null, pause: false };
    enfant.stdout.on('data', (b) => { // lue même sans flux attaché : le tampon se remplit pendant la grâce
      if (cible !== s || cible.etat === 'terminee') return;
      ajouter(b);
      const r = cible.res; if (!r) return;
      if (!r.write(b) && !cible.pause) { cible.pause = true; enfant.stdout.pause(); r.once('drain', () => reprendre(cible)); }
    });
    let reste = '', fermes = 0; const unFerme = () => { if (++fermes === 2) terminer(cible); }; // fin = stdout ET stderr clos : le code a été lu
    enfant.stdout.on('end', unFerme); enfant.stderr.on('end', unFerme);
    enfant.stderr.on('data', (b) => { // état de l'assistant : lignes « FIN <code> » ou « SIG <n> » seulement, toute autre ligne ignorée sans trace
      reste += b.toString('latin1'); let i;
      while ((i = reste.indexOf('\n')) >= 0) {
        const l = reste.slice(0, i); reste = reste.slice(i + 1);
        const m = /^(FIN|SIG) (\d{1,3})$/.exec(l);
        if (m && cible.etat !== 'terminee') { if (m[1] === 'FIN') cible.code = Number(m[2]); else cible.signal = Number(m[2]); }
      }
      if (reste.length > 64) reste = reste.slice(-64);
    });
    enfant.stdin.on('error', () => {}); enfant.stdio[3].on('error', () => {});
    enfant.on('error', () => { log('python3 est introuvable ou ne se lance pas : le terminal est arrêté.'); terminer(cible); });
    enfant.on('exit', () => { setTimeout(() => terminer(cible), 2000).unref?.(); }); // filet : un tube retenu ne bloque pas la fin
    return cible;
  }

  return {
    // rend 200 (réponse prise en charge), 400 ou 409 ; les autres statuts sont écrits par l'appelant
    attacher(req, res, { onglet, lignes = 24, colonnes = 80 } = {}) {
      if (!ONGLET_RE.test(String(onglet || ''))) return 400;
      if (!Number.isInteger(lignes) || !Number.isInteger(colonnes) || lignes < 1 || lignes > TAILLE_MAX.lignes || colonnes < 1 || colonnes > TAILLE_MAX.colonnes) return 400;
      if (s && s.etat !== 'terminee' && s.onglet !== onglet) return 409;
      if (!s || s.etat === 'terminee') s = lancer(onglet, lignes, colonnes);
      const cible = s; clearTimeout(cible.minuterie);
      const ancienne = cible.res; cible.res = res; cible.etat = 'vivante'; reprendre(cible);
      if (ancienne) { try { ancienne.end(); } catch {} } // même onglet : le nouveau flux remplace l'ancien
      res.on('error', () => {});
      res.writeHead(200, { 'Content-Type': 'application/octet-stream', 'Cache-Control': 'no-store' });
      for (const c of tampon) res.write(c); // reprise : le tampon d'abord, le direct ensuite (aucun octet entre les deux : tout est synchrone)
      res.on('close', () => detacher(cible, res));
      return 200;
    },
    ecrire(octets, onglet) {
      if (!actif(s)) return 410;
      if (s.onglet !== onglet) return 409;
      try { s.enfant.stdin.write(octets); } catch { return 410; }
      return 204;
    },
    redimensionner(lignes, colonnes, onglet) {
      if (!actif(s)) return 410;
      if (s.onglet !== onglet) return 409;
      try { s.enfant.stdio[3].write(`R ${lignes} ${colonnes}\n`); } catch { return 410; }
      return 204;
    },
    etat: () => ({ session: s ? s.etat : 'absente', code: s ? s.code : null, signal: s ? s.signal : null }),
    occupe: () => actif(s),
    arreterTout() {
      if (!s) return;
      const c = s; clearTimeout(c.minuterie); c.etat = 'terminee'; c.res = null; vider();
      try { c.enfant.stdin.end(); } catch {}
      try { c.enfant.kill('SIGTERM'); } catch {}
    },
  };
}
