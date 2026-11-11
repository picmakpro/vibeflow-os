// vf-cockpit-terminal-session — la session unique du terminal intégré : lancement de l'assistant PTY, flux, entrée, taille (71-01).
// Export : creerSessions({ engineDir, lab, jetons }) -> { attacher, ecrire, redimensionner, lancer, etat, occupe, fermer, arreterTout }.
// Une seule session. L'assistant (vf-cockpit-pty.py de l'arbre du moteur, lancé en mode isolé) ne se lance qu'à la PREMIÈRE attache, jamais avant ; il
// n'est jamais détaché : il meurt avec le serveur. Sa sortie (descripteur 1) est le flux ; son descripteur 2 porte l'état (FIN, SIG) et n'est
// jamais journalisé ; le descripteur 3 reçoit les tailles. Les messages nomment des états, jamais des données du terminal.
// Lancement (72-02 ; P72-D-01, D-14) : lancer(ligne, onglet) envoie « L <hex> » à l'assistant, qui revalide seul la ligne et ne l'écrit (sans retour chariot) que si le shell est au repos ; sa réponse « LANCE ok|premier-plan|alphabet|invalide|ecriture »
// (descripteur 2) arrive dans l'ordre d'envoi : file FIFO d'attentes, délai de LANCER_DELAI_MS (une attente expirée reste dans la file jusqu'à sa réponse, jamais attribuée à l'appel suivant). Jamais de retour chariot ni de journal de la ligne.
// Cycle de vie (71-04 ; P71-D-05, P71-D-19) : un seul onglet propriétaire (autre onglet : 409) ; flux fermé -> état « detachee » et grâce de GRACE_MS ;
// retour du même onglet avant l'échéance -> même shell, tampon (TAMPON_MAX octets, MÉMOIRE SEULEMENT) rejoué puis direct ; échéance ou fin du shell -> EOF à
// l'assistant (SIGHUP au groupe), tampon vidé. Aucun octet du terminal n'est écrit sur disque ni passé à console.* (TERM-11).
// Une seule session à tout instant (P71-D-05) : à l'échéance la place reste prise (« fermeture ») jusqu'à la MORT de l'assistant, qui peut mettre 3 s ; une
// attache entre-temps reçoit 503 (le client réessaie). Entrée : au plus ENTREE_ATTENTE_MAX octets en attente côté serveur, au-delà 429 (rien n'est écrit, le client garde ses octets).
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { envShell, choisirShell } from './vf-cockpit-terminal-env.mjs';
import { nouveauSecret } from './vf-cockpit-terminal-amorce.mjs';

const ONGLET_RE = /^[A-Za-z0-9_-]{1,64}$/;
const log = (m) => console.error(`vf-cockpit (terminal) : ${m}`);
export const TAMPON_MAX = 262144;
export const TAILLE_MAX = { lignes: 500, colonnes: 1000 }; // l'unique borne de taille : le serveur (/flux, /taille) et l'assistant PTY (vf-cockpit-pty.py) la tiennent à l'identique
export const ENTREE_ATTENTE_MAX = 262144;
export const LIGNE_MAX = 400; // octets d'une ligne lancée : la même borne que LIGNE_MAX de vf-cockpit-pty.py
export const LANCER_DELAI_MS = 2000;
const ATTENTES_MAX = 8;
// Fermeture bornée : un assistant qui n'est pas mort FERMETURE_MAX_MS (6 s : grâce interne 3 s + SIGKILL de la session) après l'EOF reçoit SIGTERM ; s'il vit encore
// ESCALADE_MS plus tard (SIGTERM n'est qu'un drapeau chez lui, s'il est bloqué dans son arrêt), il reçoit SIGKILL ; ESCALADE_MS après, la place est rendue quoi qu'il arrive :
// au plus FERMETURE_MAX_MS + 2 × ESCALADE_MS (8 s) après l'échéance de la grâce, jamais une place prise pour toujours.
const ESCALADE_MS = 1000;
const fermetureDepuis = (v) => { const n = Number(v); return Number.isInteger(n) && n >= 100 && n <= 30000 ? n : 6000; }; // réglage de test seulement (comme la grâce)
const graceDepuis = (v) => { const n = Number(v); return Number.isInteger(n) && n >= 100 && n <= 30000 ? n : 30000; }; // réglage de test seulement (P71-PL-18)
export const FERMETURE_MAX_MS = fermetureDepuis(process.env.VF_COCKPIT_TERM_FERMETURE_MS);
export const GRACE_MS = graceDepuis(process.env.VF_COCKPIT_TERM_GRACE_MS);
// Résolution de l'interpréteur par le serveur (P71-D-25, F3) : le cwd du serveur est le lab, donc un élément relatif ou vide du PATH (« . », « : » en tête ou en
// queue) ferait exécuter un python3 du lab. On cherche python3 dans les seuls éléments ABSOLUS du PATH et on lance son chemin absolu. Le PATH du SHELL n'est pas touché (P71-D-03).
// Introuvable : chemin impossible (ENOTDIR) -> l'événement 'error' habituel, jamais un repli sur la résolution par le cwd.
export function resoudrePython3(pathVar = process.env.PATH) {
  for (const d of String(pathVar || '').split(path.delimiter)) {
    if (!d || !path.isAbsolute(d)) continue;
    const c = path.join(d, 'python3');
    try { if (fs.statSync(c).isFile()) { fs.accessSync(c, fs.constants.X_OK); return c; } } catch {}
  }
  return null;
}
const actif = (c) => !!c && (c.etat === 'vivante' || c.etat === 'detachee');

export function creerSessions({ engineDir, lab, jetons = () => [], env = process.env }) { // env : l'environnement d'ORIGINE du shell (transmis au processus du terminal par l'IPC, P71-D-03)
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
  const finirAttentes = (cible, motif) => { for (const a of cible.attentes.splice(0)) a.finir({ ok: false, motif }); }; // appels en attente d'une réponse : rendus sans attendre le délai
  const reprendre = (c) => { if (c.pause) { c.pause = false; c.enfant.stdout.resume(); } };
  const terminer = (cible) => { // l'unique voie de fin : état, flux du client, minuterie, tampon
    if (cible.etat === 'terminee' || (cible.etat === 'fermeture' && !cible.sorti)) return; // en fermeture, la place n'est rendue qu'à la sortie (réapée) de l'assistant
    finirAttentes(cible, 'absente');
    const fermait = cible.etat === 'fermeture';
    clearTimeout(cible.minuterie); cible.etat = 'terminee';
    const r = cible.res; cible.res = null; try { r?.end(); } catch {}
    if (cible === s) { vider(); if (fermait) s = null; } // fin d'une expiration : la session disparaît, la place est libre
  };
  const expirer = (cible) => { // échéance de la grâce : EOF à l'assistant (il envoie SIGHUP au groupe) ; la place reste prise jusqu'à sa mort (terminer la libère)
    if (s !== cible || cible.etat !== 'detachee') return;
    cible.etat = 'fermeture'; vider();
    try { cible.enfant.stdin.end(); } catch {}
    const garde = setTimeout(() => {
      if (cible.etat !== 'fermeture') return;
      try { cible.enfant.kill('SIGTERM'); } catch {}
      const dur = setTimeout(() => {
        if (cible.etat !== 'fermeture') return;
        try { cible.enfant.kill('SIGKILL'); } catch {}
        const rendre = setTimeout(() => { if (cible.etat === 'fermeture') { cible.sorti = true; terminer(cible); } }, ESCALADE_MS); rendre.unref?.();
      }, ESCALADE_MS); dur.unref?.();
    }, FERMETURE_MAX_MS); garde.unref?.();
  };
  const detacher = (cible, res) => {
    if (cible.res !== res || cible.etat !== 'vivante') return;
    cible.res = null; cible.etat = 'detachee'; reprendre(cible);
    clearTimeout(cible.minuterie); cible.minuterie = setTimeout(() => expirer(cible), GRACE_MS); cible.minuterie.unref?.();
  };

  function lancer(onglet, lignes, colonnes) {
    const assistant = path.join(engineDir, 'terminal', 'vf-cockpit-pty.py');
    let enfant; // P71-D-34 : un échec SYNCHRONE de spawn (ENOTDIR du chemin impossible) est rattrapé, jamais un 500 muet
    try {
      enfant = spawn(resoudrePython3(env.PATH) || '/dev/null/python3', ['-I', assistant, String(lignes), String(colonnes), choisirShell(env)], {
        cwd: fs.realpathSync(lab), env: envShell(env, [...jetons(), secretShell]), stdio: ['pipe', 'pipe', 'pipe', 'pipe'],
      });
    } catch { log('python3 est introuvable ou ne se lance pas : le terminal est arrêté.'); return null; }
    const cible = { enfant, onglet, res: null, etat: 'vivante', code: null, signal: null, minuterie: null, pause: false, sorti: false, attentes: [] };
    enfant.stdout.on('data', (b) => { // lue même sans flux attaché : le tampon se remplit pendant la grâce
      if (cible !== s || !actif(cible)) return;
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
        const lm = /^LANCE (ok|premier-plan|alphabet|invalide|ecriture)$/.exec(l); // réponse à une ligne « L » : la PREMIÈRE attente (FIFO) la reçoit, même expirée
        if (lm) { const a = cible.attentes.shift(); if (a) a.finir(lm[1] === 'ok' ? { ok: true } : { ok: false, motif: lm[1] }); }
        const m = /^(FIN|SIG) (\d{1,3})$/.exec(l);
        if (m && cible.etat !== 'terminee') { if (m[1] === 'FIN') cible.code = Number(m[2]); else cible.signal = Number(m[2]); }
      }
      if (reste.length > 64) reste = reste.slice(-64);
    });
    enfant.stdin.on('error', () => {}); enfant.stdio[3].on('error', () => {});
    enfant.on('error', () => { log('python3 est introuvable ou ne se lance pas : le terminal est arrêté.'); terminer(cible); });
    enfant.on('exit', () => { cible.sorti = true; if (cible.etat === 'fermeture') terminer(cible); setTimeout(() => terminer(cible), 2000).unref?.(); }); // filet : un tube retenu ne bloque pas la fin
    return cible;
  }

  return {
    // rend 200 (réponse prise en charge), 400, 409 ou 503 (ancienne session en fermeture) ; les autres statuts sont écrits par l'appelant
    attacher(req, res, { onglet, lignes = 24, colonnes = 80 } = {}) {
      if (!ONGLET_RE.test(String(onglet || ''))) return 400;
      if (!Number.isInteger(lignes) || !Number.isInteger(colonnes) || lignes < 1 || lignes > TAILLE_MAX.lignes || colonnes < 1 || colonnes > TAILLE_MAX.colonnes) return 400;
      if (s && s.etat === 'fermeture') return 503;
      if (s && s.etat !== 'terminee' && s.onglet !== onglet) return 409;
      if (!s || s.etat === 'terminee') { const n = lancer(onglet, lignes, colonnes); if (!n) { s = null; return 503; } s = n; }
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
      if (s.enfant.stdin.writableLength + octets.length > ENTREE_ATTENTE_MAX) return 429; // contre-pression : rien n'est écrit, le client garde ses octets et réessaie
      try { s.enfant.stdin.write(octets); } catch { return 410; }
      return 204;
    },
    redimensionner(lignes, colonnes, onglet) {
      if (!actif(s)) return 410;
      if (s.onglet !== onglet) return 409;
      try { s.enfant.stdio[3].write(`R ${lignes} ${colonnes}\n`); } catch { return 410; }
      return 204;
    },
    lancer(ligne, onglet) { // une ligne de commande au shell, sans retour chariot, seulement s'il est au repos : { ok:true } ou { ok:false, motif }
      const c = s, non = (motif) => Promise.resolve({ ok: false, motif });
      if (!actif(c) || c.onglet !== onglet) return non('absente');
      if (typeof ligne !== 'string' || ligne.length < 1 || ligne.length > LIGNE_MAX) return non('invalide');
      if (!/^[\x20-\x7e]+$/.test(ligne)) return non('alphabet'); // transport seulement : l'alphabet fermé et le préfixe sont jugés par l'assistant (revalidation indépendante)
      if (c.attentes.length >= ATTENTES_MAX) return non('delai');
      return new Promise((resolve) => {
        const entree = { fini: false, minuterie: null, finir(r) { if (entree.fini) return; entree.fini = true; clearTimeout(entree.minuterie); resolve(r); } };
        c.attentes.push(entree);
        entree.minuterie = setTimeout(() => entree.finir({ ok: false, motif: 'delai' }), LANCER_DELAI_MS);
        try { c.enfant.stdio[3].write(`L ${Buffer.from(ligne, 'latin1').toString('hex')}\n`); } catch { const i = c.attentes.indexOf(entree); if (i >= 0) c.attentes.splice(i, 1); entree.finir({ ok: false, motif: 'absente' }); }
      });
    },
    etat: () => { const c = s && s.etat !== 'fermeture' ? s : null; return { session: c ? c.etat : 'absente', code: c ? c.code : null, signal: c ? c.signal : null }; },
    occupe: () => actif(s),
    // fin volontaire de la SESSION (« Terminer la session », AUDC-M10) : flux fermé, puis la même fermeture bornée que l'échéance de la grâce ; la place reste prise jusqu'à la MORT de l'assistant (P71-D-05), une attache entre-temps reçoit 503
    fermer() {
      const c = s; if (!actif(c)) return;
      clearTimeout(c.minuterie); const r = c.res; c.res = null; try { r?.end(); } catch {}
      finirAttentes(c, 'absente'); c.etat = 'detachee'; expirer(c);
    },
    arreterTout() {
      if (!s) return;
      const c = s; clearTimeout(c.minuterie); c.etat = 'terminee'; try { c.res?.end(); } catch {} c.res = null; vider(); // les flux ouverts sont fermés (P71-D-35)
      finirAttentes(c, 'absente');
      try { c.enfant.stdin.end(); } catch {}
      try { c.enfant.kill('SIGTERM'); } catch {}
    },
  };
}
