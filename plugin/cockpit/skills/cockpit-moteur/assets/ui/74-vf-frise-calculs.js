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

  window.__vfFriseCalculs = Object.freeze({ etatA, noeudsPortes, delta, voiesAutour, etages });
})();
