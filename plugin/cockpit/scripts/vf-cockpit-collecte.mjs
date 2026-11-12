// vf-cockpit-collecte — le pilote du collecteur : UN fil `worker_threads` porte toute la collecte (graphe Projet, verrous, équipe), la boucle du
// serveur garde le HTTP, la surveillance de fichiers, la diffusion et la garde d'émission (79-09, P79-D-12, SOCL-13).
// Export : creerCollecte({ racine, sortie, scriptsDir, home, entree, limites, log }) -> { demander, surResultat, pret, etat, arreter } ;
//   LIMITES (constante).
//   demander({ planning, verrous, tour, motifs }) : une demande en vol, UNE seule en attente (les drapeaux se combinent, les motifs se
//     concatènent).
//   surResultat(rappel) -> désinscription : rappel(message) pour chaque message du fil (voir l'en-tête de vf-cockpit-collecte-fil.mjs).
//   pret(ms) -> promesse : vrai quand aucune demande n'est en vol, faux après `ms`.
//   etat() -> { etat: 'en-cours' | 'ok' | 'indisponible', derniereA, dureeMs }.
// Le fil est construit UNE fois, depuis l'URL du module voisin ; `entree` ne sert qu'aux tests. Ce module ne lit aucune variable
// d'environnement : tout ce que le fil reçoit (racine, dossier des scripts, home) est calculé par le serveur et passé en chaînes. Le fil est
// détaché de la boucle (`unref`) : il ne retient jamais l'arrêt.
import { Worker } from 'node:worker_threads';

export const LIMITES = Object.freeze({ maxOldGenerationSizeMb: 768, maxYoungGenerationSizeMb: 64, stackSizeMb: 4 });

const fusion = (a, b) => (a
  ? { planning: a.planning || b.planning, verrous: a.verrous || b.verrous, tour: a.tour || b.tour, motifs: [...a.motifs, ...b.motifs] }
  : b);

export function creerCollecte({ racine, sortie, scriptsDir, home, entree, limites = LIMITES, log = () => {} }) {
  const ecouteurs = new Set(), attendants = new Set();
  let fil = null, enVol = false, attente = null, id = 0, ferme = false, ok = false, mort = false, derniereA = null, dureeMs = null;

  const reveiller = () => { for (const f of [...attendants]) f(true); attendants.clear(); };
  const dire = (m) => {
    for (const f of [...ecouteurs]) { try { f(m); } catch (e) { log('error', `résultat de collecte : ${String(e.message).slice(0, 160)}`); } }
  };
  const envoyer = (r) => {
    enVol = true; const demande = { ...r, id: ++id };
    fil.postMessage(demande); // garde:collecte-fil
  };
  const suivante = () => {
    enVol = false;
    if (attente && !ferme && fil) { const s = attente; attente = null; envoyer(s); } else reveiller();
  };
  const tombe = (cause) => { // le fil est mort ou ne démarre pas : indisponible, jamais une exception dans la boucle
    if (ferme || mort) return;
    mort = true; fil = null; attente = null; enVol = false;
    log('error', `collecte indisponible : ${cause}`); reveiller();
  };

  try {
    const opts = { workerData: { racine, sortie, scriptsDir, home }, resourceLimits: { ...limites } };
    fil = new Worker(entree || new URL('./vf-cockpit-collecte-fil.mjs', import.meta.url), opts);
    fil.unref();
    fil.on('message', (m) => {
      if (m && m.type === 'tour') { derniereA = new Date().toISOString(); dureeMs = Number.isInteger(m.dureeMs) && m.dureeMs > 0 ? m.dureeMs : 1; }
      dire(m);
      if (m && m.type === 'fini') { ok = true; suivante(); }
    });
    fil.on('error', (e) => tombe(String(e && e.message).slice(0, 160)));
    fil.on('exit', (code) => tombe(`fil sorti (code ${code})`));
  } catch (e) { tombe(String(e && e.message).slice(0, 160)); }

  return {
    demander({ planning = false, verrous = false, tour = false, motifs = [] } = {}) {
      if (ferme || mort || !fil) return false;
      const r = { planning: !!planning, verrous: !!verrous, tour: !!tour, motifs: [...motifs] };
      if (enVol) attente = fusion(attente, r); else envoyer(r);
      return true;
    },
    surResultat(f) { ecouteurs.add(f); return () => ecouteurs.delete(f); },
    pret(ms = 5000) {
      if (!enVol) return Promise.resolve(true);
      return new Promise((res) => {
        const f = (v) => { clearTimeout(t); attendants.delete(f); res(v); };
        const t = setTimeout(() => f(false), ms); t.unref?.();
        attendants.add(f);
      });
    },
    etat: () => ({ etat: mort ? 'indisponible' : ok ? 'ok' : 'en-cours', derniereA, dureeMs }),
    arreter() {
      if (ferme) return;
      ferme = true; attente = null; enVol = false; reveiller();
      const f = fil; fil = null;
      if (f) { f.terminate().catch(() => {}); }
    },
  };
}
