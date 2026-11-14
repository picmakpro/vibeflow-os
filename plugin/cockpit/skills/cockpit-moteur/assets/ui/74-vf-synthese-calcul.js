// VibeFlow (77-04) : calcul pur de « depuis votre dernière visite » (P77-D-10, P77-D-11, P77-D-22). Aucun DOM, aucun stockage, aucune horloge ni hasard :
// la page passe les données au format de signal@1 (phases, missions, équipe) et l'heure en secondes. Pose window.__vfSyntheseCalcul et rien d'autre.
// Les instantanés gardés ne contiennent que des états, un sha et des condensats : jamais un titre, un sujet, une commande ni un chemin.
(() => {
  const ETATS = ['a-faire', 'en-cours', 'a-recetter', 'fait'];
  const DEPUIS_ST = { done: 'fait', recette: 'a-recetter', active: 'en-cours', todo: 'a-faire' }; // inverse de PROJECTION_ST (vf-cockpit-project.mjs)
  const FENETRE_S = 86400, MAX_BLOCAGES = 64, MAX_PHASES = 500;
  const CLE_PHASE = /^[^|\s]{0,64}\|[0-9]+(\.[0-9]+)*$/, SHA = /^[0-9a-f]{40}$/, H12 = /^[0-9a-f]{12}$/;
  const liste = (v) => (Array.isArray(v) ? v : []);
  const objet = (v) => (v && typeof v === 'object' ? v : {});
  const a = (o, k) => Object.prototype.hasOwnProperty.call(o, k);
  const secondes = (v) => {
    if (typeof v === 'number' && Number.isFinite(v)) return v;
    return typeof v === 'string' && !isNaN(Date.parse(v)) ? Date.parse(v) / 1000 : null;
  };

  // adaptateurs : la forme { phases: [{ key, avancement: { etat } }], missions: [{ nom, noeuds: [{ status }] }], equipe: { workers } }
  function depuisGraphe(graphe, who) {
    const phases = [], missions = [];
    for (const n of liste(objet(graphe).nodes)) {
      if (!n || typeof n !== 'object') continue;
      if (n.kind === 'phase' && a(DEPUIS_ST, n.st)) {
        phases.push({ key: (n.ws || '') + '|' + n.num, avancement: { etat: DEPUIS_ST[n.st] } });
      } else if (typeof n.id === 'string' && n.id.startsWith('dag-')) {
        missions.push({ nom: n.id.slice(4), noeuds: n.st === 'blocked' ? [{ status: 'failed' }] : [] });
      }
    }
    return { phases, missions, equipe: { workers: liste(objet(who).workers) } };
  }
  function depuisSignal(signal) {
    const s = objet(signal);
    return {
      phases: liste(s.phases)
        .filter((p) => p && typeof p.key === 'string' && p.avancement && ETATS.includes(p.avancement.etat))
        .map((p) => ({ key: p.key, avancement: { etat: p.avancement.etat } })),
      missions: liste(s.missions)
        .filter((m) => m && typeof m.nom === 'string')
        .map((m) => ({ nom: m.nom, noeuds: liste(m.noeuds).map((x) => ({ status: x && x.status })) })),
      equipe: { workers: liste(objet(s.equipe).workers) },
    };
  }

  // FNV-1a 64 bits sur les unités UTF-16 du texte (aucune API du navigateur) : les douze premiers caractères hexadécimaux
  function condensat(texte) {
    const t = String(texte);
    let h = 0xcbf29ce484222325n;
    for (let i = 0; i < t.length; i++) h = BigInt.asUintN(64, (h ^ BigInt(t.charCodeAt(i))) * 0x100000001b3n);
    return h.toString(16).padStart(16, '0').slice(0, 12);
  }

  // blocages présents : mission à nœud échoué, agent qui attend, entrée du STATE ({ h, t }, plan 77-02)
  function blocagesPresents({ missions, workers, blocagesState } = {}) {
    const r = [];
    for (const m of liste(missions)) {
      if (m && typeof m.nom === 'string' && liste(m.noeuds).some((x) => x && x.status === 'failed')) {
        r.push({ cle: condensat('mission|' + m.nom), kind: 'mission', texte: m.nom });
      }
    }
    for (const w of liste(workers)) {
      if (!w || w.etat !== 'attend' || typeof w.id !== 'string') continue;
      const role = typeof w.role === 'string' && w.role ? w.role : w.kind === 'subagent' ? 'sous-agent' : 'session';
      r.push({ cle: condensat('attend|' + w.id), kind: 'agent', texte: role });
    }
    for (const b of liste(blocagesState)) {
      if (b && typeof b.h === 'string' && typeof b.t === 'string') r.push({ cle: condensat('state|' + b.h), kind: 'state', texte: b.t });
    }
    return r.slice(0, MAX_BLOCAGES);
  }

  // instantané gardé, sur liste fermée : phases (clé -> état), tete (40 hex ou null), blocages (clés de 12 hex, uniques), vu (secondes)
  function instantane({ phases, tete, blocages, vu } = {}) {
    const p = Object.create(null), src = objet(phases);
    for (const k of Object.keys(src)) {
      if (Object.keys(p).length < MAX_PHASES && CLE_PHASE.test(k) && ETATS.includes(src[k])) p[k] = src[k];
    }
    const b = [...new Set(liste(blocages).filter((x) => typeof x === 'string' && H12.test(x)))].slice(0, MAX_BLOCAGES);
    const t = typeof tete === 'string' && SHA.test(tete) ? tete : null;
    return { vu: Number.isFinite(vu) && vu > 0 ? Math.floor(vu) : 0, phases: p, tete: t, blocages: b };
  }

  // commits arrivés (P77-D-22) : ancêtres du sommet de la base moins ancêtres de tete, en suivant les parents des rangées lues ; jamais un filtre sur la date
  function commitsArrives(rangees, tete, sommet) {
    const par = new Map();
    for (const r of liste(rangees)) if (r && typeof r.h === 'string') par.set(r.h, r);
    const ancetres = (depart) => {
      const vus = new Set(), pile = [depart];
      while (pile.length) {
        const h = pile.pop();
        if (vus.has(h) || !par.has(h)) continue;
        vus.add(h);
        for (const p of liste(par.get(h).p)) pile.push(p);
      }
      return vus;
    };
    if (!tete || !sommet || !par.has(sommet)) return { etat: 'inconnu', n: null, plusDe500: false };
    if (tete === sommet) return { etat: 'ok', n: 0, plusDe500: false };
    if (!par.has(tete)) return { etat: 'ok', n: null, plusDe500: true };
    const anc = ancetres(tete);
    let n = 0;
    for (const h of ancetres(sommet)) if (!anc.has(h)) n++;
    return { etat: 'ok', n, plusDe500: false };
  }

  // sessions finies : travailleurs terminés dont la fin (finAt, sinon lastAt) suit la visite ; au-delà de 24 h, « au moins » et la réserve
  function sessionsFinies(workers, vu, maintenant) {
    let n = 0;
    for (const w of liste(workers)) {
      if (!w || w.etat !== 'termine') continue;
      const f = secondes(w.finAt ?? w.lastAt);
      if (f !== null && f > vu) n++;
    }
    const longue = maintenant - vu > FENETRE_S;
    return { n, auMoins: longue, reserve24h: longue };
  }

  // différence entre la visite précédente (instantané ou null) et le présent ; opts.blocages = la liste de blocagesPresents (les nouveaux y sont nommés)
  function difference(precedente, present, { rangees, sommet, gitLu, workers, maintenant, blocages } = {}) {
    if (!precedente) return { premiere: true };
    const phases = [];
    for (const k of Object.keys(present.phases)) {
      const de = a(precedente.phases, k) ? precedente.phases[k] : null;
      if (de !== present.phases[k]) phases.push({ key: k, de, vers: present.phases[k] });
    }
    const commits = gitLu === false ? { etat: 'non-lus', n: null, plusDe500: false }
      : commitsArrives(rangees, precedente.tete, sommet);
    const sessions = sessionsFinies(workers, precedente.vu, maintenant);
    const avant = new Set(precedente.blocages), presents = new Set(present.blocages);
    const noms = Array.isArray(blocages) ? blocages : present.blocages.map((cle) => ({ cle, kind: null, texte: '' }));
    const nouveaux = noms.filter((x) => presents.has(x.cle) && !avant.has(x.cle))
      .map((x) => ({ cle: x.cle, kind: x.kind, texte: x.texte }));
    const leves = precedente.blocages.filter((c) => !presents.has(c)).length;
    const dit = phases.length > 0 || commits.plusDe500 || commits.etat === 'non-lus' || (commits.n || 0) > 0
      || sessions.n > 0 || sessions.reserve24h || nouveaux.length > 0 || leves > 0;
    return { premiere: false, phases, commits, sessions, blocages: { nouveaux, leves }, vide: !dit };
  }

  // les nombres de la ligne-résumé, sans texte (les mots sont écrits par la page)
  function resume(diff) {
    if (!diff || diff.premiere) return { phases: 0, commits: 0, sessions: 0, nouveaux: 0, leves: 0 };
    const b = diff.blocages;
    return { phases: diff.phases.length, commits: diff.commits.n, sessions: diff.sessions.n, nouveaux: b.nouveaux.length, leves: b.leves };
  }

  window.__vfSyntheseCalcul = Object.freeze({
    ETATS, DEPUIS_ST, FENETRE_S, depuisGraphe, depuisSignal, condensat, blocagesPresents, instantane, commitsArrives, sessionsFinies, difference, resume,
  });
})();
