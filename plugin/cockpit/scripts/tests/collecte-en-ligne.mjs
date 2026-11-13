// collecte-en-ligne — collecteur d'essai de MÊME interface que le pilote (vf-cockpit-collecte.mjs), qui exécute les étapes dans le fil
// courant par setImmediate (79-09). Sert au harnais de test-cockpit-cycle-serveur.sh (ses espions sur `fs` et ses compteurs d'appels ne
// verraient rien d'un autre fil), aux preuves de l'instantané (C10) et, en tâche 2, de référence à la sonde de latence. Ce n'est PAS une
// copie du pilote : pas de fil, pas de limites, pas de relance.
// Export : creerCollecteEnLigne({ racine, scriptsDir, home }) -> { demander, surResultat, pret, etat, arreter }
import { creerMemoire, etapePlanning, etapeVerrous, etapeTour } from '../vf-cockpit-collecte-etapes.mjs';

export function creerCollecteEnLigne({ racine, sortie, scriptsDir, home }) {
  const memo = creerMemoire(), base = { racine, sortie, scriptsDir, home };
  const ecouteurs = new Set(), attendants = new Set();
  let enVol = false, attente = null, id = 0, fini = false, arrete = false, derniereA = null, dureeMs = null;
  const dire = (m) => { for (const f of ecouteurs) { try { f(m); } catch {} } };
  const fusion = (a, b) => (a
  ? { planning: a.planning || b.planning, verrous: a.verrous || b.verrous, tour: a.tour || b.tour, motifs: [...a.motifs, ...b.motifs] }
  : b);
  const executer = (r, n) => {
    if (r.planning) {
      try { dire({ type: 'planning', id: n, motifs: r.motifs, graphe: etapePlanning(base) }); }
      catch (e) { dire({ type: 'planning', id: n, motifs: r.motifs, erreur: String(e.message).slice(0, 200) }); }
    }
    if (r.verrous && !r.tour) dire({ type: 'verrous', id: n, verrous: etapeVerrous({ ...base, memo }) });
    if (r.tour) { const t = etapeTour({ ...base, memo }); derniereA = new Date().toISOString(); dureeMs = t.dureeMs; dire({ type: 'tour', id: n, ...t }); }
    fini = true; dire({ type: 'fini', id: n });
  };
  const lancer = (r) => {
    enVol = true;
    setImmediate(() => {
      try { executer(r, ++id); } catch {} // l'essai ne doit jamais tuer le processus de test
      enVol = false;
      if (attente) { const s = attente; attente = null; lancer(s); } else { for (const f of [...attendants]) f(true); attendants.clear(); }
    });
  };
  return {
    demander({ planning = false, verrous = false, tour = false, motifs = [] } = {}) {
      if (arrete) return false;
      const r = { planning, verrous, tour, motifs: [...motifs] };
      if (enVol) attente = fusion(attente, r); else lancer(r);
      return true;
    },
    surResultat(f) { ecouteurs.add(f); return () => ecouteurs.delete(f); },
    pret: (ms = 5000) => (!enVol ? Promise.resolve(true) : new Promise((res) => {
      const t = setTimeout(() => { attendants.delete(f); res(false); }, ms);
      const f = (v) => { clearTimeout(t); res(v); };
      attendants.add(f);
    })),
    etat: () => ({ etat: arrete ? 'indisponible' : fini ? 'ok' : 'en-cours', derniereA, dureeMs }),
    arreter() { arrete = true; for (const f of [...attendants]) f(true); attendants.clear(); },
  };
}
