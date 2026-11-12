// vf-cockpit-collecte — le pilote du collecteur : UN fil `worker_threads` porte toute la collecte (graphe Projet, verrous, équipe, index des
// transcripts), la boucle du serveur garde le HTTP, la surveillance de fichiers, la diffusion et la garde d'émission (79-09, P79-D-12, SOCL-13).
// Export : creerCollecte({ racine, sortie, scriptsDir, home, entree, limites, delais, log })
//           -> { demander, surResultat, pret, etat, redemarrer, arreter } ; LIMITES, DELAIS (constantes).
//   demander({ planning, verrous, tour, motifs }) : une demande en vol, UNE seule en attente (les drapeaux se combinent, les motifs se concatènent) ;
//     fil absent ou en cours de relance : la demande attend le fil suivant (elle n'est perdue qu'à l'arrêt).
//   surResultat(rappel) -> désinscription : rappel(message) pour chaque message du fil (voir l'en-tête de vf-cockpit-collecte-fil.mjs).
//   pret(ms) -> promesse : vrai quand aucune demande n'est en vol, faux après `ms`.
//   etat() -> { etat: 'en-cours' | 'ok' | 'partielle' | 'indisponible', derniereA, dureeMs, index, boucle, erreurs, relances, derniereMort, vivant }.
//   redemarrer({ sansIndex }) : termine le fil, ATTEND sa sortie, puis construit le suivant ; la demande en vol y est rejouée.
// Politique : un fil qui meurt (mémoire, erreur, sortie) est relancé UNE fois SANS index (`partielle`, index `suspendu`) ; une seconde mort dans
// `fenetreMortMs` rend `indisponible`, avec une nouvelle tentative après `reprisePauseMs` ; l'index suspendu est repris après `indexSuspenduMs`.
// UN seul écrivain de l'index : le fil suivant n'est jamais construit avant la sortie du précédent.
// Le fil est construit en UN seul endroit, depuis l'URL du module voisin ; `entree` ne sert qu'aux tests. Ce module ne lit aucune variable
// d'environnement : tout ce que le fil reçoit (racine, sortie, dossier des scripts, home) est calculé par le serveur et passé en chaînes. Le fil
// est détaché de la boucle (`unref`) : il ne retient jamais l'arrêt. Chaque marqueur `garde:` n'est écrit que sur sa ligne (ancres des mutants).
import { Worker } from 'node:worker_threads';
import { monitorEventLoopDelay } from 'node:perf_hooks';

export const LIMITES = Object.freeze({ maxOldGenerationSizeMb: 768, maxYoungGenerationSizeMb: 64, stackSizeMb: 4 });
export const DELAIS = Object.freeze({ fenetreMortMs: 30000, reprisePauseMs: 60000, indexSuspenduMs: 600000 });
const CAUSES = ['memoire', 'erreur', 'sortie'], RESOLUTION_MS = 10;
const INDEX_ATTENTE = Object.freeze({ etat: 'attente', tronque: false, voies: 0, formeInconnue: 0, evinces: 0 });
const INDEX_SUSPENDU = Object.freeze({ etat: 'suspendu', tronque: false, voies: 0, formeInconnue: 0, evinces: 0 });

const fusion = (a, b) => (a && b
  ? { planning: a.planning || b.planning, verrous: a.verrous || b.verrous, tour: a.tour || b.tour, motifs: [...a.motifs, ...b.motifs] }
  : a || b);

export function creerCollecte({ racine, sortie, scriptsDir, home, entree, limites = LIMITES, delais, log = () => {} }) {
  const D = { ...DELAIS, ...(delais || {}) };
  const ecouteurs = new Set(), attendants = new Set(), minuteurs = new Set();
  let fil = null, enVol = null, attente = null, id = 0, ferme = false, ok = false, indispo = false, derniereA = null, dureeMs = null;
  let index = INDEX_ATTENTE, erreurs = [], relances = 0, derniereMort = null, mortT = 0;
  const moniteur = monitorEventLoopDelay({ resolution: RESOLUTION_MS }); moniteur.enable();

  const reveiller = () => { for (const f of [...attendants]) f(true); attendants.clear(); };
  const dire = (m) => {
    for (const f of [...ecouteurs]) { try { f(m); } catch (e) { log('error', `résultat de collecte : ${String(e.message).slice(0, 160)}`); } }
  };
  const minuter = (ms, f) => {
    const t = setTimeout(() => { minuteurs.delete(t); if (!ferme) f(); }, ms); t.unref?.(); minuteurs.add(t);
  };
  const annulerMinuteurs = () => { for (const t of minuteurs) clearTimeout(t); minuteurs.clear(); };

  const envoyer = (r) => {
    enVol = { ...r, id: ++id };
    fil.w.postMessage(enVol); // garde:collecte-fil
  };
  const suivante = () => {
    enVol = null;
    if (attente && !ferme && fil) { const s = attente; attente = null; envoyer(s); } else reveiller();
  };
  const envoyerAttente = () => { if (attente && fil && !enVol) { const s = attente; attente = null; envoyer(s); } };

  // UNE construction du fil ; `cur.sorti` se résout à sa sortie, `cur.voulu` dit qu'on l'a terminé nous-mêmes (ce n'est pas une mort)
  function lancer(sansIndex) {
    const cur = { w: null, voulu: false, cause: null, sorti: null };
    cur.sorti = new Promise((res) => { cur.fini = res; });
    try {
      const opts = { workerData: { racine, sortie, scriptsDir, home, sansIndex }, resourceLimits: { ...limites } };
      cur.w = new Worker(entree || new URL('./vf-cockpit-collecte-fil.mjs', import.meta.url), opts);
    } catch (e) { cur.fini(); fil = null; surMort('erreur', String(e && e.message).slice(0, 160)); return; }
    cur.w.unref();
    cur.w.on('message', (m) => {
      if (fil !== cur) return; // un message d'un fil qu'on a quitté n'entre jamais dans la collecte
      if (m && m.type === 'tour') {
        derniereA = new Date().toISOString(); dureeMs = Number.isInteger(m.dureeMs) && m.dureeMs > 0 ? m.dureeMs : 1;
        erreurs = Array.isArray(m.erreurs) ? m.erreurs.filter((e) => typeof e === 'string').slice(0, 8) : [];
      }
      if (m && m.type === 'index' && m.index && typeof m.index === 'object') index = { ...INDEX_ATTENTE, ...m.index };
      dire(m);
      if (m && m.type === 'fini') { ok = true; suivante(); }
    });
    cur.w.on('error', (e) => {
      cur.cause = e && e.code === 'ERR_WORKER_OUT_OF_MEMORY' ? 'memoire' : 'erreur'; cur.detail = String(e && e.message).slice(0, 160);
    });
    cur.w.on('exit', (code) => { cur.fini(); if (!cur.voulu && fil === cur) surMort(cur.cause || 'sortie', cur.detail || `fil sorti (code ${code})`); });
    fil = cur;
  }

  // reprise de l'index suspendu : un fil neuf AVEC l'index, après `indexSuspenduMs` sans mort
  const armerIndex = () => minuter(D.indexSuspenduMs, () => { redemarrer({ sansIndex: false }).catch(() => {}); });
  const armerReprise = () => minuter(D.reprisePauseMs, () => {
    indispo = false; relances++; index = INDEX_SUSPENDU;
    lancer(true); armerIndex();
    if (fil) { attente = fusion(attente, { planning: false, verrous: false, tour: true, motifs: [] }); envoyerAttente(); }
  });

  function surMort(cause, detail) {
    if (ferme) return;
    const t = Date.now(), recente = derniereMort !== null && t - mortT <= D.fenetreMortMs;
    derniereMort = { cause: CAUSES.includes(cause) ? cause : 'erreur', at: new Date(t).toISOString() }; mortT = t;
    attente = fusion(enVol, attente); enVol = null; fil = null; annulerMinuteurs(); // la demande en vol est rejouée par le fil suivant
    log('error', `collecte : fil mort (${derniereMort.cause}) ${detail || ''}`.trim());
    if (recente) { indispo = true; reveiller(); armerReprise(); log('error', 'collecte indisponible : seconde mort rapprochée'); return; }
    relances++; index = INDEX_SUSPENDU;
    lancer(true); // garde:collecte-sans-index
    armerIndex(); envoyerAttente();
  }

  async function redemarrer({ sansIndex = false } = {}) {
    if (ferme) return;
    const ancien = fil; fil = null; annulerMinuteurs();
    attente = fusion(enVol, attente); enVol = null;
    if (ancien) { ancien.voulu = true; ancien.w.terminate().catch(() => {}); await ancien.sorti; } // garde:collecte-ecrivain
    if (ferme) return;
    indispo = false; relances++; index = sansIndex ? INDEX_SUSPENDU : INDEX_ATTENTE;
    lancer(sansIndex);
    if (sansIndex) armerIndex();
    envoyerAttente();
  }

  lancer(false);

  return {
    demander({ planning = false, verrous = false, tour = false, motifs = [] } = {}) {
      if (ferme) return false;
      const r = { planning: !!planning, verrous: !!verrous, tour: !!tour, motifs: [...motifs] };
      if (enVol || !fil) attente = fusion(attente, r); else envoyer(r);
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
    etat() {
      const partiel = ok && (erreurs.length > 0 || (index.etat !== 'ok' && index.etat !== 'attente'));
      const ms = (ns) => Math.max(0, Math.round(ns / 1e6) - RESOLUTION_MS);
      return {
        etat: indispo ? 'indisponible' : !ok ? 'en-cours' : partiel ? 'partielle' : 'ok', derniereA, dureeMs, index: { ...index }, erreurs: [...erreurs],
        boucle: { p99Ms: ms(moniteur.percentile(99)), maxMs: ms(moniteur.max) }, relances, vivant: fil !== null,
        derniereMort: derniereMort && { ...derniereMort },
      };
    },
    redemarrer,
    arreter() {
      if (ferme) return;
      ferme = true; attente = null; enVol = null; annulerMinuteurs(); moniteur.disable(); reveiller();
      const f = fil; fil = null;
      if (f) { f.voulu = true; f.w.terminate().catch(() => {}); }
    },
  };
}
