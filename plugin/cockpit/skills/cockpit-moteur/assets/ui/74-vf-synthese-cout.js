// VibeFlow (77-07, SYNT-10 ; P77-D-15, P77-D-16, P77-D-20, P77-D-28, P77-D-29, P77-D-32) : le bloc « Coût par phase et par étage · dernières 24 h » de la
// Synthèse. Jetons et durée de travail seulement, jamais un montant, sur les dernières 24 h de la frise `vibeflow/cockpit-frise@1` ; aucune route neuve.
// Une voie va à sa phase par sa mission (`rattachement.dag` = `missions[].fichier`, puis `phaseKey`) : jamais une phase devinée, « Non rattaché » sinon.
// Seuls `kind`, `role`, `jetons`, `durees` et `rattachement` d'une voie sont lus. Un champ absent reste `null` (jamais 0) et le total
// l'exclut avec un compteur.
// Frise tronquée : chaque total est un minorant, dit en toutes lettres. Les sommes par mission viennent de l'agrégat de la 74 (window.__vfFriseCalculs) quand
// il existe, d'un calcul propre de même règle sinon ; l'adaptateur ramène les missions aux phases et ajoute l'axe des étages. Fonctions pures, exposées
// par window.__vfSyntheseCout ; rien ne touche `document` au chargement. Inscrit son bloc au registre de la coquille (74-vf-synthese.js), `rendre` reçoit le
// conteneur SOUS le h3. Lecture à l'ouverture : VF_ETAT.lire('frise') puis VF_ETAT.lireJson (le seul accès réseau) ; abonnement posé par `installer`, rendu
// par son nettoyage. Tout texte venu du lab s'écrit par nœuds de texte.
(() => {
  'use strict';
  const NB = ' ', SCHEMA = 'vibeflow/cockpit-frise@1';
  const ETAGES = Object.freeze(['Manager', 'Codeur', 'Revue', 'Audit', 'Vérification', 'Tête de session', 'Autres']);
  const CODEURS = ['vf-coder', 'gsd-executor', 'vf-crafter', 'vf-app-fixer'];
  const REVUES = ['vf-reviewer', 'gsd-code-reviewer'], AUDITS = ['vf-auditer', 'gsd-security-auditor'];
  const VERIFS = ['gsd-verifier', 'gsd-plan-checker', 'vf-test-runner', 'vf-test-orchestrator', 'quality-gate-client', 'prd-gate'];
  // P77-D-16 : l'étage est le rôle de la voie, par une table fermée (relue contre plugin/*/agents/*.md)
  const etage = (v) => {
    const r = v && typeof v.role === 'string' ? v.role : '';
    if (v && v.kind === 'session') return 'Tête de session';
    if (r.endsWith('-manager')) return 'Manager';
    if (CODEURS.includes(r)) return 'Codeur';
    if (REVUES.includes(r) || r.endsWith('-judge')) return 'Revue';
    if (AUDITS.includes(r)) return 'Audit';
    return VERIFS.includes(r) ? 'Vérification' : 'Autres';
  };

  // ---------- voies : normalisation, sommes (une passe, sommes entières) ----------
  const num = (x) => (typeof x === 'number' && Number.isFinite(x) ? x : null);
  const obj = (x) => (x && typeof x === 'object' && !Array.isArray(x) ? x : {});
  const norm = (v) => {
    const b = obj(v), j = obj(b.jetons), d = obj(b.durees), r = b.rattachement && typeof b.rattachement === 'object' ? b.rattachement : null;
    return { kind: typeof b.kind === 'string' ? b.kind : null, role: typeof b.role === 'string' ? b.role : null,
      jetons: { entree: num(j.entree), sortie: num(j.sortie), cacheLu: num(j.cacheLu), cacheCree: num(j.cacheCree) },
      durees: { travailS: num(d.travailS), attenteHumainS: num(d.attenteHumainS) },
      rattachement: r ? { dag: typeof r.dag === 'string' ? r.dag : null } : null };
  };
  const COLS = [['travailS', (v) => v.durees.travailS], ['attenteHumainS', (v) => v.durees.attenteHumainS], ['entree', (v) => v.jetons.entree],
    ['sortie', (v) => v.jetons.sortie], ['cacheLu', (v) => v.jetons.cacheLu], ['cacheCree', (v) => v.jetons.cacheCree]];
  const somme = (vs) => Object.fromEntries(COLS.map(([k, f]) => {
    let s = 0;
    for (const v of vs) { const x = f(v); if (x == null) return [k, null]; s += x; } // un champ absent : la ligne dit null, jamais 0
    return [k, s];
  }));
  const totaux = (vs) => Object.fromEntries(COLS.map(([k, f]) => [k, vs.reduce((s, v) => s + (f(v) ?? 0), 0)]));
  const rattache = (v) => !!v.rattachement && v.rattachement.dag != null;
  const poser = (m, k, x) => (m.get(k) || m.set(k, []).get(k)).push(x);
  // calcul propre, de la forme de `agreger(…, 'mission', …)` de la 74 : une ligne par mission rattachée, `horsMission`, `total`, `inconnus`
  const propre = (vs, tronque) => {
    const par = new Map();
    for (const v of vs) if (rattache(v)) poser(par, v.rattachement.dag, v);
    return { lignes: [...par].map(([dag, l]) => ({ cle: dag, ...somme(l) })), horsMission: somme(vs.filter((v) => !rattache(v))), total: totaux(vs),
      inconnus: vs.filter((v) => COLS.some(([, f]) => f(v) == null)).length, incomplet: !!tronque };
  };

  // ---------- adaptateur mission -> phase (P77-D-16, P77-D-29) et axe des étages ----------
  const CLES = ['entree', 'sortie', 'cacheLu', 'cacheCree', 'travailS'];
  const plus = (a, b) => (a == null || b == null ? null : a + b);
  const fondre = (ls) => {
    const s = Object.fromEntries(CLES.map((k) => [k, 0]));
    for (const l of ls) for (const k of CLES) s[k] = plus(s[k], l[k] ?? null);
    return s;
  };
  const avecJetons = (s) => ({ ...s, jetons: plus(s.entree, s.sortie) }); // chiffre principal (P77-D-28) : entrée + sortie, le cache est à part
  const valeurs = (v) => ({ entree: v.jetons.entree, sortie: v.jetons.sortie, cacheLu: v.jetons.cacheLu, cacheCree: v.jetons.cacheCree,
    travailS: v.durees.travailS });
  // où va une voie : sa phase du jalon (clé de phase), « hors » (phase connue, hors du jalon), « non » (rien de sûr : jamais une phase devinée)
  const destination = (dag, missions, phases, jalon) => {
    const m = dag == null ? null : missions.find((x) => x && x.fichier === dag), pk = m ? m.phaseKey : null;
    if (pk == null || !phases.some((p) => p && p.key === pk)) return 'non';
    return jalon && !jalon.includes(pk) ? 'hors' : pk;
  };
  const depuisAgregat = (agr, o = {}) => {
    const liste = (x) => (Array.isArray(x) ? x : []), missions = liste(o.missions), phases = liste(o.phases), jalon = Array.isArray(o.jalon) ? o.jalon : null;
    const voies = liste(o.voies).map(norm), dest = (dag) => destination(dag, missions, phases, jalon), lignes = new Map(), vs = new Map();
    for (const l of agr.lignes) poser(lignes, dest(l.cle), l);
    poser(lignes, 'non', agr.horsMission);
    for (const v of voies) poser(vs, dest(v.rattachement && v.rattachement.dag), v);
    const ligne = (k, phase, libelle) => {
      const ls = lignes.get(k) || [], g = vs.get(k) || [];
      if (!g.length && ls.length <= (k === 'non' ? 1 : 0)) return null; // aucune activité : pas de ligne
      return { cle: k, phase, libelle, n: g.length, ...avecJetons(fondre(ls)),
        etages: ETAGES.map((nom) => {
          const e = g.filter((v) => etage(v) === nom);
          return e.length ? { etage: nom, n: e.length, ...fondre(e.map(valeurs)) } : null;
        }).filter(Boolean) };
    };
    const connues = [...new Set([...lignes.keys(), ...vs.keys()])].filter((k) => k !== 'hors' && k !== 'non').map((k) => phases.find((p) => p.key === k))
      .sort((a, b) => (a.n - b.n) || String(a.key).localeCompare(String(b.key)));
    const t = agr.total;
    return { lignes: connues.map((p) => ligne(p.key, { key: p.key, n: p.n, nom: p.nom ?? null }, `Phase ${p.n}${p.nom ? ` · ${p.nom}` : ''}`)).filter(Boolean),
      horsJalon: ligne('hors', null, 'Hors jalon'), nonRattache: ligne('non', null, 'Non rattaché'),
      total: avecJetons(Object.fromEntries(CLES.map((k) => [k, t[k]]))), inconnus: agr.inconnus, incomplet: !!agr.incomplet };
  };
  const agreger = (voies, o = {}) => {
    const C = window.__vfFriseCalculs, vs = (Array.isArray(voies) ? voies : []).map(norm), missions = Array.isArray(o.missions) ? o.missions : [];
    const phases = Array.isArray(o.phases) ? o.phases : [];
    const a = C && typeof C.agreger === 'function' ? C.agreger(vs, 'mission', { missions, phases, tronque: !!o.tronque }) : propre(vs, o.tronque);
    return depuisAgregat(a, { ...o, voies: vs });
  };
  // phases des jalons en cours (un jalon dont une phase n'est pas faite) ; à défaut le dernier jalon ; null quand le ROADMAP n'en dit aucun
  const jalonEnCours = (sig) => {
    const js = sig && Array.isArray(sig.jalons) ? sig.jalons.filter((m) => m && Array.isArray(m.phases)) : [];
    const ph = sig && Array.isArray(sig.phases) ? sig.phases : [];
    const faite = (k) => (ph.find((p) => p && p.key === k) || {}).fait === true, en = js.filter((m) => m.phases.some((k) => !faite(k)));
    return js.length ? (en.length ? en : js.slice(-1)).flatMap((m) => m.phases) : null;
  };

  // ---------- minorant, états, formats ----------
  const fmtJetons = (n) => {
    if (typeof n !== 'number' || !Number.isFinite(n)) return null;
    const k1 = Math.round(n / 100) / 10, k = Math.round(n / 1000);
    if (Math.round(n) < 1000) return String(Math.round(n));
    return k1 < 100 ? `${k1.toFixed(1).replace('.', ',')}${NB}k` : k < 1000 ? `${k}${NB}k` : `${(n / 1e6).toFixed(1).replace('.', ',')}${NB}M`;
  };
  const fmtDuree = (s) => {
    if (typeof s !== 'number' || !Number.isFinite(s)) return null;
    if (s < 90) return `${Math.round(s)}${NB}s`;
    if (Math.round(s / 60) < 60) return `${Math.round(s / 60)}${NB}min`;
    let h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
    if (m === 60) { h++; m = 0; }
    return `${h}${NB}h ${String(m).padStart(2, '0')}`;
  };
  const FJ = (n) => (window.__vfFriseCalculs && window.__vfFriseCalculs.fmtJetons ? window.__vfFriseCalculs.fmtJetons(n) : fmtJetons(n));
  const FD = (n) => (window.__vfFriseCalculs && window.__vfFriseCalculs.fmtDuree ? window.__vfFriseCalculs.fmtDuree(n) : fmtDuree(n));
  // P77-D-32 : `tronque` -> chaque total est un minorant ; le nombre de voies omises n'est dit que s'il est un entier STRICTEMENT positif
  const minorant = (r, total) => {
    const x = obj(r);
    if (x.tronque !== true) return { complet: true, phrase: '' };
    const t = obj(total), n = x.voiesOmises, omises = Number.isInteger(n) && n > 0
      ? (n === 1 ? '1 voie omise' : `${n} voies omises`) : 'nombre de voies omises inconnu';
    const j = FJ(plus(t.entree, t.sortie)) ?? 'inconnu', d = FD(t.travailS) ?? 'inconnu';
    return { complet: false, phrase: `Total partiel : au moins ${j} jetons hors cache et ${d}, ${omises}.` };
  };
  const ETATS = ['en-construction', 'partielle', 'forme-inconnue', 'indisponible'];
  const etatDeSource = (source, voies) => {
    const e = source && typeof source === 'object' ? source.etat : null;
    if (e === 'ok') return Array.isArray(voies) && voies.length ? 'ok-avec-voies' : 'ok-vide';
    return ETATS.includes(e) ? e : 'forme-inconnue';
  };
  window.__vfSyntheseCout = Object.freeze({ ETAGES, etage, agreger, depuisAgregat, minorant, etatDeSource, fmtJetons, fmtDuree });

  // ---------- page ----------
  const TEXTES = { indisponible: "Coût indisponible : la frise n'a pas répondu.", 'ok-vide': 'Aucune activité dans les dernières 24 h.',
    'en-construction': "L'index des sessions est en cours de construction : le coût apparaîtra à la fin de la lecture.",
    'forme-inconnue': 'Le cockpit ne reconnaît pas la forme des sessions de cette version de Claude Code.',
    partielle: "Lecture partielle : certaines sessions n'ont pas été lues." };
  const AIDE = "Jetons et durée de travail. Jamais de montant. Les jetons couvrent la vie de chaque agent dans l'index des dernières 24 h, "
    + 'sans coupe à la seconde.';
  const el = (tag, attrs, texte) => {
    const e = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) e.setAttribute(k, v);
    if (texte !== undefined && texte !== null) e.textContent = '' + texte; // texte du lab : jamais du balisage
    return e;
  };
  const feuille = () => {
    if (document.getElementById('vf-sy-cout')) return;
    const st = document.createElement('style'); st.id = 'vf-sy-cout';
    st.textContent = `.vf-sy table.vf-sy-cout { width: 100%; border-collapse: collapse; margin-top: var(--sp-8); font-size: 12.5px; line-height: 1.4;
        font-variant-numeric: tabular-nums; color: var(--text-2); }
      .vf-sy table.vf-sy-cout th { padding: var(--sp-4) var(--sp-6); text-align: right; font-weight: 500;
        color: var(--text-3); border-bottom: 1px solid var(--hair-2); }
      .vf-sy table.vf-sy-cout td { padding: var(--sp-4) var(--sp-6); text-align: right; vertical-align: top; border-bottom: 1px solid var(--hair-2); }
      .vf-sy table.vf-sy-cout th:first-child, .vf-sy table.vf-sy-cout td:first-child { text-align: left; }
      .vf-sy table.vf-sy-cout tfoot td { font-weight: 600; color: var(--text); }
      .vf-sy table.vf-sy-cout summary { cursor: pointer; font-weight: 500; color: var(--text); }
      .vf-sy table.vf-sy-cout ul { list-style: none; margin: var(--sp-4) 0 0; padding: 0; font-size: 11px; color: var(--text-3); }
      @media (pointer: coarse), (max-width: 999px) { .vf-sy table.vf-sy-cout summary { min-height: 44px; display: flex; align-items: center; } }`;
    document.head.appendChild(st);
  };
  const J = (n) => (n == null ? 'inconnu' : FJ(n) ?? 'inconnu'), D = (n) => (n == null ? 'inconnu' : FD(n) ?? 'inconnu');
  const cache = (r) => `lu ${J(r.cacheLu)} · créé ${J(r.cacheCree)}`;
  const ligneTable = (r) => {
    const tr = el('tr'), td = el('td'), d = el('details'), ul = el('ul');
    for (const x of r.etages) {
      ul.append(el('li', {}, `${x.etage} : entrée ${J(x.entree)}, sortie ${J(x.sortie)}, cache lu ${J(x.cacheLu)}, cache créé ${J(x.cacheCree)}`));
    }
    d.append(el('summary', {}, r.libelle), ul); td.append(d);
    tr.append(td, el('td', {}, J(r.jetons)), el('td', {}, cache(r)), el('td', {}, D(r.travailS)));
    return tr;
  };
  const tableau = (a) => {
    const t = el('table', { class: 'vf-sy-cout', 'aria-labelledby': 'vf-sy-t-cout' }), h = el('tr'), pre = a.incomplet ? 'au moins ' : '';
    for (const c of ['Phase', 'Jetons, hors cache', 'Cache lu et créé', 'Durée']) h.append(el('th', { scope: 'col' }, c));
    const corps = el('tbody'), pied = el('tfoot'), tf = el('tr');
    for (const r of [...a.lignes, a.horsJalon, a.nonRattache]) if (r) corps.append(ligneTable(r));
    for (const c of ['Total', `${pre}${J(a.total.jetons)}`, `${pre}${cache(a.total)}`, `${pre}${D(a.total.travailS)}`]) tf.append(el('td', {}, c));
    pied.append(tf); t.append(el('thead', {}, null), corps, pied); t.tHead.append(h);
    return t;
  };

  let corps = null, gen = 0, absent = false, minuterie = null, signe = '';
  const E = () => window.VF_ETAT;
  const section = () => (corps && corps.parentElement) || null;
  const lireFrise = () => { // -> { brut } | { absent } | { indispo } ; le statut n'est lisible que sur le rejet de lireJson
    // (404 : absent, tout autre échec : indisponible)
    const st = E().lire('frise');
    if (st && st.schema === SCHEMA) return Promise.resolve({ brut: st });
    return E().lireJson('/api/vf/frise').then((j) => (j && j.schema === SCHEMA ? { brut: j } : { absent: true }),
      (e) => (e && e.statut === 404 ? { absent: true } : { indispo: true }));
  };
  const lireSignal = () => {
    const e = E().lire('etat');
    if (e && e.signal) return Promise.resolve(e.signal);
    return E().lireJson('/api/vf/state').then((j) => (j && j.signal) || null, () => null);
  };
  function montrer(sec, enfants, s) {
    if (s === signe && corps.firstChild) return; // rien n'a changé : les lignes dépliées restent dépliées
    signe = s; corps.textContent = ''; corps.append(...enfants); sec.hidden = false;
  }
  function dessiner(brut, sig) {
    const sec = section(), voies = Array.isArray(brut.voies) ? brut.voies : [], etat = etatDeSource(brut.source, voies);
    const note = (t) => el('p', { class: 'pd vf-sy-note' }, t);
    if (etat !== 'ok-avec-voies' && etat !== 'partielle') { montrer(sec, [note(TEXTES[etat])], etat); return; }
    const a = agreger(voies, { missions: sig && sig.missions, phases: sig && sig.phases, jalon: jalonEnCours(sig), tronque: brut.tronque === true });
    const enf = [note(AIDE), tableau(a)], m = minorant({ tronque: brut.tronque === true, voiesOmises: brut.voiesOmises }, a.total);
    if (!m.complet) enf.push(note(m.phrase));
    if (a.inconnus > 0) enf.push(note(`${a.inconnus} voie${a.inconnus > 1 ? 's' : ''} sans mesure, non comptée${a.inconnus > 1 ? 's' : ''}.`));
    if (etat === 'partielle') enf.push(note(TEXTES.partielle));
    montrer(sec, enf, JSON.stringify([etat, a, m.phrase]));
  }
  function charger() {
    const mon = ++gen, sec = section(), vivant = () => mon === gen && corps && corps.isConnected;
    if (!sec || !E() || typeof E().lireJson !== 'function') return;
    if (!corps.firstChild) sec.hidden = true; // rien n'est rendu avant la réponse de la frise
    lireFrise().then((r) => {
      if (!vivant()) return null;
      if (r.absent) { absent = true; sec.remove(); return null; } // 404 ou schéma inconnu : aucun nœud DOM du bloc
      if (r.indispo) { montrer(sec, [el('p', { class: 'pd vf-sy-note' }, TEXTES.indisponible)], 'indispo'); return null; }
      return lireSignal().then((sig) => { if (vivant()) dessiner(r.brut, sig); });
    }).catch(() => { if (vivant()) montrer(sec, [el('p', { class: 'pd vf-sy-note' }, TEXTES.indisponible)], 'indispo'); });
  }
  function installer() {
    absent = false; signe = ''; feuille();
    let off = null;
    try {
      off = E() && typeof E().abonner === 'function' ? E().abonner('frise', () => {
        clearTimeout(minuterie); minuterie = setTimeout(() => { if (corps && corps.isConnected) charger(); }, 50);
      }) : null;
    } catch { off = null; }
    return () => { clearTimeout(minuterie); if (off) off(); corps = null; gen++; };
  }
  function rendre(c) { corps = c; signe = ''; charger(); }
  const R = (window.__vfSyntheseBlocs = window.__vfSyntheseBlocs || []);
  for (let i = R.length - 1; i >= 0; i--) if (R[i] && R[i].id === 'cout') R.splice(i, 1);
  R.push(Object.freeze({ id: 'cout', titre: 'Coût par phase et par étage · dernières 24 h', installer, present: () => !absent, rendre, ouvrir() {} }));
})();
