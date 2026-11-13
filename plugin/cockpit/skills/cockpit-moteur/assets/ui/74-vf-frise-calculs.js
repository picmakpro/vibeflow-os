// VibeFlow (Phase 74, plan 74-01) : calculs purs de la frise et de la fiche (P74-D-12, D-13, D-20 à D-23, D-34, D-42, D-49, D-50).
// Aucun accès au viewer ni au DOM, aucun réseau : tout part des voies de `vibeflow/cockpit-frise@1` normalisées par `lire`
// (74-vf-frise-modele.js, chargé ensuite), du dépôt `cockpit-git@1` et de `signal.missions`.
// Pose window.__vfFriseCalculs (gelé). Chargé EN PREMIER (ordre lexical) : n'appelle rien du modèle. Une valeur absente de la source reste `null`, jamais 0.
(() => {
  'use strict';
  const ETATS_VOIE = ['travail', 'attend-humain', 'attend-agents', 'repos'];

  // état d'une voie à l'instant t : intervalles semi-ouverts [debut, fin[ ; la queue `attend-humain` (A43) est un segment comme les autres,
  // jamais retypée
  const etatA = (v, t) => {
    if (v.debut != null && t < v.debut) return 'pas-lance';
    let genre = null;
    for (const s of v.segments) if (s.debut <= t && t < s.fin) genre = s.genre; // le dernier segment qui couvre t (triés : la queue passe après)
    if (genre) return genre;
    return v.fini && v.fin != null && t >= v.fin ? 'termine' : 'repos';
  };

  // nœuds du plan portés à t : l'état de la VOIE qui porte le nœud (D-49), jamais un statut de DAG ;
  // `sansAgent` = nœuds des missions qui disent leurs nœuds, moins les portés
  const noeudsPortes = (voies, t, missions) => {
    const portes = [];
    for (const v of voies) {
      const r = v.rattachement;
      if (!r || r.noeud == null || r.source === 'enfants') continue;
      const etat = etatA(v, t);
      if (ETATS_VOIE.includes(etat)) portes.push({ dag: r.dag, noeud: r.noeud, agentId: v.id, etat });
    }
    const avec = (Array.isArray(missions) ? missions : []).filter((m) => m && Array.isArray(m.noeuds));
    if (!avec.length) return { portes, sansAgent: null };
    const pris = new Set(portes.map((p) => JSON.stringify([p.dag, p.noeud])));
    let n = 0;
    for (const m of avec) for (const x of m.noeuds) if (!pris.has(JSON.stringify([m.fichier, x.id]))) n++;
    return { portes, sansAgent: n };
  };

  // relecture au curseur (D-49) : pas du curseur = fenêtre / 90, δ = demi-pas, plancher 2 min
  const delta = (fenetreMs) => Math.max(120000, fenetreMs / 180);
  const voiesAutour = (voies, t, d) => voies.filter((v) => v.segments.some((s) => s.genre === 'travail' && s.debut <= t + d && s.fin > t - d));

  // étage (D-42) : tête = session ; manager = sous-agent qui a au moins une voie enfant ; worker = sous-agent sans voie enfant.
  // Jamais la profondeur seule.
  const etages = (voies) => {
    const parents = new Set(voies.map((v) => v.parent).filter((p) => p != null));
    return new Map(voies.map((v) => [v.id, v.kind === 'session' ? 'tete' : parents.has(v.id) ? 'manager' : 'worker']));
  };

  // ---- fichiers écrits autour de t (P74-D-49, D-52) : PURE, aucune lecture ; `fils` = Map id -> { fil, tronque } déjà lue, absente ou nulle = non lue ----
  const HORS = 'un fichier hors du lab';
  const SUFFIXE = /^(.*) \(worktree (.+)\)$/; // forme textuelle du transcript pour un fichier d'un worktree vérifié (A45)
  const cibleDeFil = (c) => { const m = SUFFIXE.exec(c); return m ? { arbre: m[2], cible: m[1] } : { arbre: null, cible: c }; };
  const poser = (m, k, x) => (m.get(k) || m.set(k, []).get(k)).push(x);

  const fichiersA = (t, d, voies, fils) => {
    const lo = t - d, hi = t + d, ecrits = new Map(), aLire = [], nonLues = [];
    let plus = false;
    const noter = (arbre, cible) => {
      const k = JSON.stringify([arbre, cible]);
      if (cible !== HORS && !ecrits.has(k)) ecrits.set(k, { arbre, cible });
    };
    for (const v of voiesAutour(voies, t, d)) {
      const c = v.cibles;
      if (c && c.tronque) plus = true; // « 200 ou plus »
      let incertaine = !c || c.tronque; // forme inconnue ou table coupée : tout fichier absent de la table est incertain
      if (c) {
        for (const e of c.ecritures) {
          if (e.dernierMs == null || e.dernierMs > hi) incertaine = true; // après t + δ : le fil seul dit s'il y a eu écriture autour de t
          else if (e.dernierMs >= lo) noter(e.arbre, e.cible); // dans [t - δ, t + δ] : écrit, certain ; avant : non écrit, certain
        }
      }
      if (!incertaine) continue;
      const lu = fils && fils.get(v.id);
      if (!lu) { aLire.push(v.id); continue; }
      const f = Array.isArray(lu.fil) ? lu.fil : [];
      if (lu.tronque && (!f.length || f[0].t > lo)) nonLues.push(v.id); // fil trop court : il ne remonte pas jusqu'à t - δ
      f.forEach((el, i) => {
        if (el.genre !== 'outil' || el.verbe !== 'modifie' || typeof el.cible !== 'string' || typeof el.t !== 'number') return;
        const fin = el.n > 1 && f[i + 1] && typeof f[i + 1].t === 'number' ? f[i + 1].t : el.t; // une entrée regroupée n'est pas un instant
        if (el.t <= hi && fin >= lo) { const o = cibleDeFil(el.cible); noter(o.arbre, o.cible); }
      });
    }
    return { ecrits: [...ecrits.values()], plus, aLire, nonLues, partiel: nonLues.length > 0 };
  };

  // ---- agrégats de coût (P74-D-20 à D-23, D-32, D-34) : jetons et durées seulement, jamais recomptés ; une seule passe, sommes entières ----
  const COLS = [['travailS', (v) => v.durees.travailS], ['attenteHumainS', (v) => v.durees.attenteHumainS], ['entree', (v) => v.jetons.entree],
    ['sortie', (v) => v.jetons.sortie], ['cacheLu', (v) => v.jetons.cacheLu], ['cacheCree', (v) => v.jetons.cacheCree]];
  const FENETRE_JETONS = 'dernières 24 h'; // horizon de l'index : les jetons ne se découpent pas sur la fenêtre affichée (D-32)
  const somme = (voies) => Object.fromEntries(COLS.map(([k, f]) => {
    let s = 0;
    for (const v of voies) { const x = f(v); if (x == null) return [k, null]; s += x; } // un champ absent : la ligne dit null, jamais 0
    return [k, s];
  }));
  const totaux = (voies) => Object.fromEntries(COLS.map(([k, f]) => [k, voies.reduce((s, v) => s + (f(v) ?? 0), 0)]));
  const ligne = (cle, libelle, voies, extra) => ({ cle, libelle, ...somme(voies), ...extra });
  const nomVoie = (v) => `${v.kind === 'session' ? 'Session' : v.role || 'agent'} ${String(v.id).slice(0, 8)}`;

  const agreger = (voies, par, opt = {}) => {
    const { missions = [], phases = [], fenetreLibelle = null, tronque = false } = opt;
    const rattache = (v) => v.rattachement && v.rattachement.dag != null;
    let lignes;
    if (par === 'agent') {
      const enfants = new Map();
      for (const v of voies) if (v.parent != null) poser(enfants, v.parent, v.id);
      lignes = voies.map((v) => ligne(v.id, nomVoie(v), [v], enfants.has(v.id) ? { enfants: enfants.get(v.id) } : {}));
    } else if (par === 'etage') {
      const E = etages(voies);
      lignes = [['tete', 'Têtes'], ['manager', 'Managers'], ['worker', 'Workers']].map(([k, l]) => ligne(k, l, voies.filter((v) => E.get(v.id) === k)));
    } else { // mission : jointure `dag === missions[].fichier`, puis `phaseKey === phases[].key` ; une mission sans phaseKey est comptée, sans ligne de phase
      const parDag = new Map();
      for (const v of voies) if (rattache(v)) poser(parDag, v.rattachement.dag, v);
      const connues = missions.filter((m) => parDag.has(m.fichier)).map((m) => ({ dag: m.fichier, nom: m.nom, phaseKey: m.phaseKey ?? null }));
      const autres = [...parDag.keys()].filter((g) => !missions.some((m) => m.fichier === g)).map((g) => ({ dag: g, nom: g, phaseKey: null }));
      lignes = [...connues, ...autres].map((m) => {
        const vs = parDag.get(m.dag), ph = m.phaseKey != null ? phases.find((p) => p.key === m.phaseKey) : null;
        const phase = m.phaseKey != null ? [ligne(m.phaseKey, (ph && ph.nom) || m.phaseKey, vs)] : [];
        return ligne(m.dag, m.nom || m.dag, vs, { phases: phase });
      });
    }
    return {
      lignes, horsMission: somme(voies.filter((v) => !rattache(v))), total: totaux(voies),
      inconnus: voies.filter((v) => COLS.some(([, f]) => f(v) == null)).length, incomplet: !!tronque,
      fenetreDurees: fenetreLibelle, fenetreJetons: FENETRE_JETONS,
    };
  };

  // ---- dépôt (P74-D-33 amendée par D-50) : `rangees[].at` est en SECONDES Unix ----
  const rangeesDe = (git) => (git && Array.isArray(git.rangees) ? git.rangees : []);
  const commit = (r) => ({ h: r.h, h7: r.h7 || String(r.h).slice(0, 7), atMs: r.at * 1000, sujet: typeof r.s === 'string' ? r.s : null });
  const commitsParBranche = (git) => {
    const rangees = rangeesDe(git), par = new Map(rangees.map((r) => [r.h, r])), pris = new Set(), nomBase = git && git.base && git.base.nom;
    const tetes = (type) => rangees.flatMap((r) => (r.refs || []).filter((x) => x.type === type).map((x) => ({ nom: x.nom, h: r.h })));
    const toutes = [...tetes('locale'), ...tetes('distante')], base = toutes.find((x) => x.nom === nomBase);
    const branches = [];
    for (const b of [...(base ? [base] : []), ...toutes.filter((x) => x !== base)]) { // la chaîne de la base d'abord, puis les locales, puis les distantes
      const commits = [];
      for (let r = par.get(b.h); r && !pris.has(r.h); r = par.get(r.p && r.p[0])) { // descente du premier parent
        pris.add(r.h);
        commits.push(commit(r));
      }
      if (commits.length) branches.push({ nom: b.nom, commits });
    }
    const reste = rangees.filter((r) => !pris.has(r.h)).map(commit);
    return { branches, autres: { n: reste.length, commits: reste } };
  };

  // couverture : la marche est topologique, le plus ancien commit lu ne borne rien seul. Frontière = le plus récent des instants entre le plus ancien commit lu
  // et la plus récente rangée dont un parent n'est pas lu ; « incomplet » seulement si la marche est tronquée ET la frontière est dans la fenêtre
  const couverture = (git, depuis) => {
    const rangees = rangeesDe(git), lus = new Set(rangees.map((r) => r.h));
    if (!rangees.length) return { incomplet: false, depuisMs: null };
    const trous = rangees.filter((r) => (r.p || []).some((p) => !lus.has(p))).map((r) => r.at * 1000);
    const frontiere = Math.max(Math.min(...rangees.map((r) => r.at * 1000)), ...trous);
    return { incomplet: !!(git.bornes && git.bornes.tronque) && frontiere >= depuis, depuisMs: frontiere };
  };

  // ---- formats français (UI-SPEC § 5) : espace insécable devant k, M, h, min, s ; valeur absente -> null ----
  const NB = ' ';
  const fini = (n) => typeof n === 'number' && Number.isFinite(n);
  const deux = (n) => String(n).padStart(2, '0');
  const fmtJetons = (n) => {
    if (!fini(n)) return null;
    const r = Math.round(n), k1 = Math.round(n / 100) / 10, k = Math.round(n / 1000);
    if (r < 1000) return String(r);
    if (k1 < 100) return `${k1.toFixed(1).replace('.', ',')}${NB}k`;
    return k < 1000 ? `${k}${NB}k` : `${(n / 1e6).toFixed(1).replace('.', ',')}${NB}M`;
  };
  const fmtDuree = (s) => {
    if (!fini(s)) return null;
    if (s < 90) return `${Math.round(s)}${NB}s`;
    if (Math.round(s / 60) < 60) return `${Math.round(s / 60)}${NB}min`;
    let h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
    if (m === 60) { h++; m = 0; }
    return `${h}${NB}h ${deux(m)}`;
  };
  const fmtNombre = (n) => (fini(n) ? String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, NB) : null);
  const fmtHeure = (ms, opt = {}) => {
    if (!fini(ms)) return null;
    const d = new Date(ms);
    if (opt.phrase) return `${d.getHours()}${NB}h ${deux(d.getMinutes())}`;
    return `${deux(d.getHours())}:${deux(d.getMinutes())}${opt.secondes ? `:${deux(d.getSeconds())}` : ''}`;
  };

  window.__vfFriseCalculs = Object.freeze({
    etatA, noeudsPortes, etages, agreger, delta, voiesAutour, fichiersA, commitsParBranche, couverture, fmtJetons, fmtDuree, fmtHeure, fmtNombre,
  });
})();
