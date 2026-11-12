// vf-cockpit-terminal — terminal intégré du cockpit, côté serve.mjs (71-01 ; P71-D-02, D-09, D-10, D-11, D-17, D-33).
// serve.mjs (patch vibeflow P26) l'importe seulement sous `--terminal` : AUCUN effet de bord à l'import.
// Export : preparerTerminal({ here, root, jetons, plateforme }) -> { actif, indisponible, injection(), frameSrc(), occupe(), routeP(req, res), demarrer(portP) }.
// P71-D-33 : le serveur Q (second écouteur HTTP, 127.0.0.1, port éphémère, origine distincte de la page hôte P) tourne dans un PROCESSUS ENFANT
// (vf-cockpit-terminal-processus.mjs, child_process.fork) : le travail synchrone de la boucle de serve.mjs ne retarde plus ni frappes ni sortie.
// Ce fichier ne garde que : les garde-fous de démarrage, le lancement et la surveillance de l'enfant, l'état `occupe` (garde d'inactivité de serve.mjs),
// la route de P GET /api/vf/terminal -> { etat, port? }, server.json. Les contrôles Host/Origin/jeton, l'amorçage et la session vivent dans l'enfant.
// Aucun secret dans l'argv ni l'environnement de l'enfant : jetons et environnement d'origine du shell passent par l'IPC.
import fs from 'node:fs';
import path from 'node:path';
import { fork } from 'node:child_process';
import { realUnder, resoudreBinaire } from './vf-cockpit-paths.mjs';
import { envEnfant } from './vf-cockpit-env.mjs';
import { envShell } from './vf-cockpit-terminal-env.mjs';
import { preparerPage } from './vf-cockpit-terminal-page.mjs';
import { TAILLE_MAX, resoudrePython3 } from './vf-cockpit-terminal-session.mjs';
import { injectionTiroir } from './vf-cockpit-terminal-tiroir.mjs';
import { injectionLancer } from './vf-cockpit-lancer-ui.mjs';
import { definir } from './vf-cockpit-lancer-canal.mjs';
import { ouvertureValide } from './vf-cockpit-terminal-amorce.mjs';

const log = (m) => console.error(`vf-cockpit (terminal) : ${m}`);
const json = (res, statut, objet) => { res.writeHead(statut, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(objet)); };
export { CORPS_ENTREE_MAX } from './vf-cockpit-terminal-processus.mjs';
export { TAILLE_MAX }; // définie avec la session, qui la fait respecter aussi à l'attache du flux

// L'environnement du PROCESSUS enfant (pas celui du shell, qui garde l'environnement d'origine, P71-D-03) : celui de tout enfant du cockpit (H-1),
// PATH assaini par vf-cockpit-env.mjs (éléments vides, relatifs ou sous le lab écartés, liens symboliques résolus, repli sur les répertoires système).
export function envDuProcessusTerminal(lab) {
  return envEnfant(lab, process.env);
}

// Lecteurs des pré-vols du lancement (72-09, P72-D-06) : `claude` dans le PATH D'ORIGINE que recevra le shell, `python3` comme le résout Q.
const claudeDisponible = () => { try { return resoudreBinaire('claude', envShell(process.env, []).PATH) !== null; } catch { return false; } };
const python3Disponible = () => { try { return resoudrePython3(process.env.PATH) !== null; } catch { return false; } };

export function preparerTerminal({ here, root, jetons = () => [], plateforme = process.platform } = {}) {
  let etat = 'arrete'; // 'actif' | 'arrete' | 'indisponible'
  let portQ = null, enfant = null, occupe = false;
  const origineQ = () => `http://127.0.0.1:${portQ}`;
  const abonnes = []; // abonnés aux messages `lancee` de l'enfant (le lanceur de P, 72-09)
  const inerte = (indisponible) => (definir({ etat: () => (indisponible ? 'indisponible' : 'arrete'), envoyer: () => false, abonner: () => {}, claude: claudeDisponible, python3: python3Disponible }), {
    actif: false, indisponible, injection: () => injectionTiroir({ indisponible }) + injectionLancer({ indisponible }), frameSrc: () => '', occupe: () => false,
    routeP: (req, res) => { json(res, 200, { etat: indisponible ? 'indisponible' : 'arrete' }); return true; }, demarrer: () => {},
  });

  if (plateforme === 'win32') { log('Terminal indisponible sous Windows.'); return inerte(true); }
  const moteur = process.env.VF_COCKPIT_ENGINE_DIR;
  const assistant = moteur && path.isAbsolute(moteur) ? path.join(moteur, 'terminal', 'vf-cockpit-pty.py') : null;
  const ordinaire = (f) => { try { return fs.lstatSync(f).isFile() && !realUnder(f, path.join(root, '.vibeflow'), { siEchec: true }); } catch { return false; } };
  if (!assistant || !ordinaire(assistant)) { log('assistant du terminal introuvable dans le moteur du cockpit : réinstaller le module cockpit.'); return inerte(false); }
  try { preparerPage({ engineDir: moteur }); } catch (e) { log(`${e.message}`); return inerte(false); }

  const envoyer = (msg) => { try { if (enfant && enfant.connected) { enfant.send(msg); return true; } } catch {} return false; };
  definir({ etat: () => (etat === 'actif' ? 'actif' : 'arrete'), envoyer, abonner: (f) => { if (typeof f === 'function') abonnes.push(f); }, claude: claudeDisponible, python3: python3Disponible });
  return {
    get actif() { return etat === 'actif'; }, indisponible: false,
    injection: () => injectionTiroir({ indisponible: false }) + injectionLancer({ indisponible: false }),
    frameSrc: () => (portQ ? `; frame-src http://127.0.0.1:${portQ}` : ''),
    occupe: () => occupe,
    ouvertureLanceur: (secret) => ouvertureValide(path.join(here, '.cache'), secret), // AUDC-B-03 bis : navigation inter-sites de la page de redirection du lanceur (secret d'ouverture + clé armée)
    routeP(req, res) { envoyer({ t: 'jetons', jetons: jetons() }); json(res, 200, etat === 'actif' ? { etat: 'actif', port: portQ } : { etat: 'arrete' }); return true; },
    demarrer(portP) {
      const fichier = path.join(here || '.', 'vf-cockpit-terminal-processus.mjs');
      try {
        enfant = fork(fichier, [], { env: envDuProcessusTerminal(root), stdio: ['inherit', 'inherit', 'inherit', 'ipc'], serialization: 'json' });
      } catch (e) { log(`le serveur du terminal ne démarre pas (${e.code || 'erreur'}).`); return; }
      enfant.on('message', (m) => {
        if (!m || typeof m !== 'object') return;
        if (m.t === 'occupe') occupe = m.v === true;
        else if (m.t === 'lancee') { for (const f of abonnes) { try { f(m); } catch {} } } // validé par le lanceur de P, jamais ici
        else if (m.t === 'echec') { etat = 'arrete'; occupe = false; }
        else if (m.t === 'pret' && Number.isInteger(m.port)) {
          portQ = m.port; etat = 'actif';
          try { // server.json gagne la clé terminal { url } : jamais un secret
            const f = path.join(here, '.cache', 'server.json'); const j = JSON.parse(fs.readFileSync(f, 'utf8'));
            fs.writeFileSync(f, JSON.stringify({ ...j, terminal: { url: origineQ() } }, null, 2), { mode: 0o600 }); fs.chmodSync(f, 0o600);
          } catch { log('server.json illisible : l\'adresse du terminal n\'a pas pu être publiée.'); }
        }
      });
      enfant.on('error', () => { etat = 'arrete'; occupe = false; });
      enfant.on('exit', () => { etat = 'arrete'; occupe = false; });
      // le shell garde l'environnement d'ORIGINE (P71-D-03) : il passe par l'IPC, avec les jetons, jamais par l'argv ni l'environnement de l'enfant
      envoyer({ t: 'init', engineDir: moteur, root, here, jetons: jetons(), portP, envOrigine: { ...process.env } });
      // arrêt volontaire (P71-D-35) : signal ou sortie ordinaire -> l'enfant passe en « arret ». Une coupure brutale (SIGKILL) ne passe ici nulle part.
      const prevenir = () => { envoyer({ t: 'arret' }); };
      for (const sig of ['SIGINT', 'SIGTERM', 'SIGHUP']) process.on(sig, prevenir);
      process.on('exit', prevenir);
    },
  };
}
