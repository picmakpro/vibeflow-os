// VibeFlow (Phase 74, plan 74-01) : modèle pur de la frise (P74-D-05, D-08, D-09, D-10, D-25, D-26, D-52) : lecture gardée par le schéma,
// arbre et repli des voies, projection du temps (Horloge et Événements), courbe du nombre d'agents. Aucune couleur, aucun nœud DOM, aucun réseau.
// Chargé APRÈS 74-vf-frise-calculs.js (ordre lexical) : pose window.__vfFriseModele (gelé) = ses propres noms + tout window.__vfFriseCalculs,
// lu au chargement (le seul cas : le module précédent dans l'ordre lexical).
// Convention : un champ absent de la source s'écrit `null` dans le résultat (la page écrit « inconnu »), jamais 0 ;
// `arbre: null` = arbre principal ; `cibles: null` = forme inconnue.
(() => {
  'use strict';
  const SCHEMA = 'vibeflow/cockpit-frise@1';
  const FENETRES = Object.freeze({ '1h30': 5400000, '6h': 21600000, '24h': 86400000 }); // clés fermées, jamais au-delà de 24 h (AUDC-Q2)
  const SEUIL_REPLI = 12, SILENCE_MS = 120000, MAX_VOIES = 500;
  const GENRES_SEG = ['travail', 'attend-agents', 'attend-humain', 'repos', 'silence'];
  const GENRES_EVT = ['compaction', 'erreur', 'humain', 'rapport', 'dispatch'];
  const COMPTEURS = ['appels', 'erreurs', 'refus', 'questions', 'compactions', 'tours', 'reponsesApi'];
  const JETONS = ['entree', 'sortie', 'cacheLu', 'cacheCree', 'contexteMax', 'contexteDernier'];
  const DUREES = ['travailS', 'attenteHumainS', 'attenteAgentsS', 'reposS', 'silenceS'];
  const CHAMPS_LUS = Object.freeze(['id', 'kind', 'parent', 'depth', 'role', 'arbre', 'debut', 'fin', 'dispatchA', 'fini', 'etatOfficiel',
    ...COMPTEURS.map((c) => `compteurs.${c}`), ...JETONS.map((c) => `jetons.${c}`), ...DUREES.map((c) => `durees.${c}`), 'segments', 'evenements',
    'rattachement.dag', 'rattachement.noeud', 'rattachement.source', 'cibles.etat', 'cibles.tronque', 'cibles.ecritures', 'cibles.lectures',
    'source.etat', 'tronque', 'voiesOmises', 'depuis', 'jusqua']);

  const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
  const txt = (v) => (typeof v === 'string' ? v : null);
  const objet = (v) => (v && typeof v === 'object' && !Array.isArray(v) ? v : {});
  const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
  const champs = (src, noms) => Object.fromEntries(noms.map((k) => [k, num(src[k])]));
  const entrees = (l) => (Array.isArray(l)
    ? l.filter((e) => e && typeof e.cible === 'string').slice(0, 200)
      .map((e) => ({ arbre: txt(e.arbre), cible: e.cible, n: num(e.n), dernierMs: num(e.dernierMs) }))
    : []);
  const cibles = (c) => (c && typeof c === 'object' && !Array.isArray(c)
    ? { etat: txt(c.etat), tronque: c.tronque === true, ecritures: entrees(c.ecritures), lectures: entrees(c.lectures) }
    : null);

  const voieLue = (b, ign) => {
    const segments = [], evenements = [];
    for (const s of Array.isArray(b.segments) ? b.segments : []) {
      if (Array.isArray(s) && num(s[0]) != null && num(s[1]) != null && GENRES_SEG.includes(s[2])) segments.push({ debut: s[0], fin: s[1], genre: s[2] });
      else ign.n++;
    }
    for (const e of Array.isArray(b.evenements) ? b.evenements : []) {
      if (Array.isArray(e) && num(e[0]) != null && GENRES_EVT.includes(e[1])) evenements.push({ t: e[0], genre: e[1] });
      else ign.n++;
    }
    segments.sort((p, q) => p.debut - q.debut || p.fin - q.fin || cmp(p.genre, q.genre));
    evenements.sort((p, q) => p.t - q.t || cmp(p.genre, q.genre));
    const ra = b.rattachement && typeof b.rattachement === 'object' ? b.rattachement : null;
    const ec = b.enCours && typeof b.enCours === 'object' ? { verbe: txt(b.enCours.verbe), depuisMs: num(b.enCours.depuisMs) } : null;
    return {
      id: b.id, kind: txt(b.kind), session: txt(b.session), parent: txt(b.parent), depth: num(b.depth), role: txt(b.role), arbre: txt(b.arbre),
      background: b.background === true, debut: num(b.debut), fin: num(b.fin), dispatchA: num(b.dispatchA), fini: b.fini === true,
      arrete: b.arrete === true, etatOfficiel: txt(b.etatOfficiel),
      modeles: (Array.isArray(b.modeles) ? b.modeles : []).filter((m) => typeof m === 'string').slice(0, 4),
      compteurs: champs(objet(b.compteurs), COMPTEURS), jetons: champs(objet(b.jetons), JETONS), durees: champs(objet(b.durees), DUREES),
      segments, evenements, enCours: ec, cibles: cibles(b.cibles),
      rattachement: ra ? { dag: txt(ra.dag), noeud: txt(ra.noeud), source: txt(ra.source) } : null,
    };
  };

  // P74-D-25, C0 : le schéma est vérifié AVANT tout autre champ ; un autre schéma rend { ok: false } sans avoir lu `voies`
  const lire = (brut) => {
    if (!brut || typeof brut !== 'object' || brut.schema !== SCHEMA) return { ok: false, raison: 'schema' };
    const voies = brut.voies;
    if (!Array.isArray(voies)) return { ok: false, raison: 'forme' };
    const ign = { n: 0 };
    const lues = voies.slice(0, MAX_VOIES).filter((b) => b && typeof b === 'object' && typeof b.id === 'string').map((b) => voieLue(b, ign));
    return {
      ok: true,
      frise: {
        schema: SCHEMA, at: num(brut.at), depuis: num(brut.depuis), jusqua: num(brut.jusqua), fenetreS: num(brut.fenetreS),
        source: { etat: txt(objet(brut.source).etat) }, tronque: brut.tronque === true,
        voiesOmises: Number.isInteger(brut.voiesOmises) ? brut.voiesOmises : null, voies: lues, ignores: ign.n,
      },
    };
  };
  // D-52 : `n` = voies retirées par la borne quand c'est un entier, sinon null (la page écrit « des voies ne sont pas montrées » sans chiffre)
  const omises = (f) => {
    const tronque = !!(f && f.tronque), n = f && f.voiesOmises;
    return { tronque, n: tronque ? (Number.isInteger(n) && n >= 0 ? n : null) : 0 };
  };

  const t0 = (v) => (v.segments.length ? v.segments[0].debut : v.debut != null ? v.debut : Infinity);
  const ordre = (a, b) => (a - b) || 0; // Infinity - Infinity = NaN : traité comme une égalité
  const empiler = (m, k, x) => (m.get(k) || m.set(k, []).get(k)).push(x);
  // rangs de la frise : arbres par heure du premier segment (un nouvel arbre en bas), enfants sous leur parent par `dispatchA` ;
  // pile explicite (un cycle de `parent` ne boucle pas)
  const arbre = (voies, who) => {
    const vs = voies.slice(0, MAX_VOIES), ids = new Set(vs.map((v) => v.id)), enfants = new Map(), vus = new Set(), groupes = new Map();
    const liste = (Array.isArray(who) ? who : who && who.workers) || [];
    const ws = new Map(liste.filter((w) => w && typeof w.id === 'string').map((w) => [w.id, w]));
    for (const v of vs) if (v.parent != null && v.parent !== v.id && ids.has(v.parent)) empiler(enfants, v.parent, v);
    for (const l of enfants.values()) l.sort((a, b) => ordre(a.dispatchA ?? Infinity, b.dispatchA ?? Infinity) || cmp(a.id, b.id));
    const parcourir = (racine) => {
      const rangs = [], pile = [[racine, 0]];
      while (pile.length) {
        const [v, niveau] = pile.pop();
        if (vus.has(v.id)) continue;
        vus.add(v.id);
        rangs.push({ id: v.id, niveau, parentId: niveau > 0 ? v.parent : null, voie: v, travailleur: ws.get(v.id) || null });
        const k = enfants.get(v.id) || [];
        for (let i = k.length - 1; i >= 0; i--) pile.push([k[i], niveau + 1]);
      }
      const g = groupes.get(racine.arbre) || { cle: racine.arbre, t: Infinity, rangs: [] };
      g.t = rangs.reduce((m, r) => Math.min(m, t0(r.voie)), g.t);
      g.rangs.push(...rangs);
      groupes.set(racine.arbre, g);
    };
    const parHeure = (a, b) => ordre(t0(a), t0(b)) || cmp(a.id, b.id);
    for (const v of vs.filter((x) => x.parent == null || x.parent === x.id || !ids.has(x.parent)).sort(parHeure)) parcourir(v);
    for (const v of vs.slice().sort(parHeure)) if (!vus.has(v.id)) parcourir(v); // reste : voies d'un cycle de parent
    return [...groupes.values()].sort((a, b) => ordre(a.t, b.t) || cmp(String(a.cle), String(b.cle))).flatMap((g) => g.rangs);
  };

  const travaille = (v) => v.etatOfficiel === 'actif'
    || (v.etatOfficiel == null && !v.fini && v.segments.length > 0 && v.segments[v.segments.length - 1].genre === 'travail');
  // D-10 : au-delà de `seuil` voies, les workers se replient sous leur manager, le plus peuplé d'abord, tout ou rien ;
  // le compte replié est toujours rendu
  const replier = (rangs, { seuil = SEUIL_REPLI, deplies = new Set() } = {}) => {
    const fils = new Map(), total = rangs.length;
    for (const r of rangs) if (r.parentId != null) empiler(fils, r.parentId, r);
    const feuilles = (id) => (fils.get(id) || []).filter((r) => !fils.has(r.id) && r.voie.kind !== 'session');
    const cand = rangs.map((r, i) => ({ r, i, ws: feuilles(r.id) }))
      .filter((c) => c.r.voie.kind !== 'session' && fils.has(c.r.id) && !deplies.has(c.r.id) && c.ws.length > 0)
      .sort((a, b) => b.ws.length - a.ws.length || a.i - b.i);
    const repliees = new Set(), replies = [];
    let visibles = total;
    for (const c of cand) {
      if (visibles <= seuil) break;
      for (const w of c.ws) repliees.add(w.id);
      visibles -= c.ws.length;
      replies.push({ managerId: c.r.id, n: c.ws.length, auTravail: c.ws.filter((w) => travaille(w.voie)).length });
    }
    const nbReplies = replies.reduce((a, r) => a + r.n, 0);
    return { visibles: rangs.filter((r) => !repliees.has(r.id)), replies, total, nbReplies };
  };

  const fusion = (ints) => {
    const out = [];
    for (const [a, b] of ints.slice().sort((p, q) => p[0] - q[0] || p[1] - q[1])) {
      const l = out[out.length - 1];
      if (l && a <= l[1]) l[1] = Math.max(l[1], b); else out.push([a, b]);
    }
    return out;
  };
  const travail = (v, depuis, jusqua) => v.segments.filter((s) => s.genre === 'travail')
    .map((s) => [Math.max(s.debut, depuis), Math.min(s.fin, jusqua)]).filter(([a, b]) => b > a);
  const deux = (n) => String(n).padStart(2, '0');
  const hhmm = (ms) => { const d = new Date(ms); return `${deux(d.getHours())}:${deux(d.getMinutes())}`; };

  // graduations alignées sur l'heure LOCALE (Date, jamais un décalage de fuseau fixe) : candidats toutes les 15 min ou toutes les heures,
  // gardés quand l'heure locale est alignée sur le pas
  const graduations = (depuis, jusqua, x) => {
    const dur = jusqua - depuis, out = [];
    const pas = dur <= 5400000 ? 900000 : dur <= 21600000 ? 3600000 : 10800000, unite = pas < 3600000 ? 900000 : 3600000;
    const d0 = new Date(depuis);
    d0.setMinutes(unite === 900000 ? Math.floor(d0.getMinutes() / 15) * 15 : 0, 0, 0);
    for (let t = d0.getTime(); t <= jusqua; t += unite) {
      if (t < depuis) continue;
      const d = new Date(t);
      const aligne = pas < 3600000 ? d.getMinutes() % 15 === 0 : d.getMinutes() === 0 && d.getHours() % (pas / 3600000) === 0;
      if (aligne) out.push({ ms: t, x: x(t), libelle: hhmm(t) });
    }
    return out;
  };

  // les silences d'Événements : aucune voie au travail et aucun événement pendant plus de SILENCE_MS
  const silencesDe = (voies, depuis, jusqua) => {
    const evts = (v) => v.evenements.filter((e) => e.t >= depuis && e.t <= jusqua).map((e) => [e.t, e.t]);
    const act = fusion(voies.flatMap((v) => [...travail(v, depuis, jusqua), ...evts(v)])), silences = [];
    let cur = depuis;
    for (const [a, b] of act) { if (a - cur > SILENCE_MS) silences.push([cur, a]); cur = Math.max(cur, b); }
    if (jusqua - cur > SILENCE_MS) silences.push([cur, jusqua]);
    return silences;
  };

  // P74-D-09 : Horloge = projection linéaire ; Événements = les silences de plus de SILENCE_MS tiennent une largeur FIXE,
  // la durée vraie reste dans `reperes`
  const projection = ({ depuis, jusqua, largeur, lecture, voies, largeurRepere = 40 }) => {
    const dur = jusqua - depuis, silences = lecture === 'evenements' && dur > 0 ? silencesDe(voies || [], depuis, jusqua) : [];
    const morceaux = [];
    let pos = depuis;
    for (const [a, b] of silences) {
      if (a > pos) morceaux.push({ debut: pos, fin: a, silence: false });
      morceaux.push({ debut: a, fin: b, silence: true });
      pos = b;
    }
    if (jusqua > pos || !morceaux.length) morceaux.push({ debut: pos, fin: jusqua, silence: false });
    const actif = morceaux.reduce((s, m) => s + (m.silence ? 0 : m.fin - m.debut), 0);
    const echelle = actif > 0 ? Math.max(0, largeur - silences.length * largeurRepere) / actif : 0;
    let x0 = 0;
    const troncons = morceaux.map((m) => {
      const x1 = x0 + (m.silence ? largeurRepere : (m.fin - m.debut) * echelle), o = { ...m, x0, x1 };
      x0 = x1;
      return o;
    });
    const x = (ms) => {
      if (!(dur > 0)) return 0;
      const t = Math.min(Math.max(ms, depuis), jusqua), m = troncons.find((k) => t <= k.fin) || troncons[troncons.length - 1];
      return m.fin > m.debut ? m.x0 + ((t - m.debut) / (m.fin - m.debut)) * (m.x1 - m.x0) : m.x0;
    };
    const reperes = troncons.filter((m) => m.silence).map((m) => ({ x: m.x0, largeur: m.x1 - m.x0, dureeS: Math.round((m.fin - m.debut) / 1000) }));
    return { x, troncons, reperes, graduations: graduations(depuis, jusqua, x) };
  };

  // segments voisins de même genre séparés de moins d'un pixel : un seul tronçon (`n` = nombre fusionné)
  const coalescer = (segments, msParPixel) => {
    const out = [];
    for (const s of segments) {
      const l = out[out.length - 1];
      if (l && l.genre === s.genre && s.debut - l.fin < msParPixel) { l.fin = Math.max(l.fin, s.fin); l.n++; }
      else out.push({ debut: s.debut, fin: s.fin, genre: s.genre, n: 1 });
    }
    return out;
  };
  const voiesTronquees = (voies, depuis) => voies.filter((v) => v.debut != null && v.debut < depuis).length;

  // courbe du nombre de voies au travail : escalier contigu sur [depuis, jusqua], échelle = max(4, pic)
  const courbe = (voies, depuis, jusqua) => {
    const ev = [], pas = [];
    for (const v of voies) for (const [a, b] of fusion(travail(v, depuis, jusqua))) ev.push([a, 1], [b, -1]);
    ev.sort((p, q) => p[0] - q[0] || p[1] - q[1]);
    const pousser = (d, f, k) => {
      const l = pas[pas.length - 1];
      if (f <= d) return;
      if (l && l.n === k) l.fin = f; else pas.push({ debut: d, fin: f, n: k });
    };
    let n = 0, pic = 0, cur = depuis;
    for (let i = 0; i < ev.length;) {
      const t = ev[i][0];
      pousser(cur, t, n);
      while (i < ev.length && ev[i][0] === t) n += ev[i++][1];
      pic = Math.max(pic, n);
      cur = t;
    }
    pousser(cur, jusqua, n);
    return { pas, pic, echelle: Math.max(4, pic) };
  };

  window.__vfFriseModele = Object.freeze({
    SCHEMA, CHAMPS_LUS, FENETRES, SEUIL_REPLI, SILENCE_MS, lire, omises, arbre, replier, projection, coalescer, courbe, voiesTronquees,
    ...window.__vfFriseCalculs,
  });
})();
