// VibeFlow (77-06, SYNT-01, SYNT-04 ; P77-D-02, P77-D-04 à P77-D-06, P77-D-20) : le bloc « Santé de la méthode » de la Synthèse. Onze jauges lues dans les
// gates du dépôt par GET /api/vf/methode, UNE fois par ouverture de la Synthèse (jamais au chargement, jamais en boucle). Chacune dit son nom, « valeur sur
// budget », une barre neutre et son verdict par un glyphe ET un mot ; la page ne recalcule ni mesure ni verdict, et une mesure absente n'est jamais un 0.
// Le champ `chemin` d'une jauge est un TEXTE LIBRE venu du lab : il est rendu par textContent (poserTexte), jamais par innerHTML, et un chemin qui commence
// par « / » ou « ~ » n'est jamais affiché. Fonctions pures exposées par window.__vfSyntheseJauges ; rien ne touche `document` au chargement.
// Inscrit son bloc au registre de la coquille : `rendre` reçoit le conteneur SOUS le h3 de la coquille, `ouvrir` lance la lecture. Aucun jeton lu ici
// (ctx.lireJson), aucun stockage, aucune écriture.
(() => {
  'use strict';
  const NB = ' ', SCHEMA = 'vibeflow/cockpit-jauges@1', ROUTE = '/api/vf/methode';
  const NOMS = Object.freeze({ state: 'Taille de STATE.md', 'state-prose': 'Paragraphe de prose de STATE.md', 'backlog-ouverts': 'Sujets ouverts du BACKLOG',
    'backlog-entree': 'Longueur d\'une entrée du BACKLOG', 'backlog-clos': 'Sujets clos encore au BACKLOG', roadmap: 'Taille de ROADMAP.md',
    'memory-index': 'Index de mémoire MEMORY.md', worktrees: 'Worktrees actifs', agent: 'Agents : lignes du plus long', skill: 'Skills : lignes du plus long',
    socle: 'Socle de démarrage' });
  const groupe = (titre, ...types) => Object.freeze({ titre, types: Object.freeze(types) });
  const GROUPES = Object.freeze([groupe('Planning', 'state', 'state-prose', 'backlog-ouverts', 'backlog-entree', 'backlog-clos', 'roadmap'),
    groupe('Mémoire et chantiers', 'memory-index', 'worktrees'), groupe('Instructions des agents', 'agent', 'skill', 'socle')]);
  const mot = (texte, classe) => Object.freeze([texte, classe]);
  const MOTS = Object.freeze({ ok: mot('Dans le budget', 'vst-done'), surveiller: mot('À surveiller', 'vst-tolere'), depasse: mot('Dépassé', 'vst-ignore'),
    na: mot('Non applicable dans ce lab', 'vst-abandonnee'), indispo: mot('Indisponible', 'vst-todo'), format: mot('Format non reconnu', 'vst-info') });
  const FORME = 'Le cockpit ne reconnaît pas la forme de cette mesure.';
  const RAISONS = Object.freeze({ na: 'Ce contrôle ne mesure que le dépôt de distribution de VibeFlow.',
    indispo: Object.freeze({ absent: 'Le contrôle n\'est pas installé.', ancien: 'Le contrôle installé est trop ancien. Mettez VibeFlow à jour : /vf-update.',
      delai: 'Le contrôle n\'a pas répondu à temps.', format: FORME, defaut: 'Mesure indisponible.' }), format: FORME });
  const RELATIONS = Object.freeze({ egale: 'égale', 'au-dessus': 'au-dessus', 'en-dessous': 'en dessous' });
  const MESURES = ['ok', 'surveiller', 'depasse'];
  const nb = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, NB);
  const r1 = (x) => Math.round(x * 10) / 10;
  const verdictDe = (j) => (j && typeof j.verdict === 'string' && Object.hasOwn(MOTS, j.verdict) ? j.verdict : 'format');
  const sauf = (chemin) => (typeof chemin === 'string' && chemin !== '' && !/^([/~]|[A-Za-z]:)/.test(chemin) ? chemin : null); // jamais un chemin du poste

  function valeurTexte(m, unite) {
    if (!m || typeof m !== 'object' || !Number.isFinite(m.valeur) || !Number.isFinite(m.budget) || ['na', 'indispo', 'format'].includes(m.verdict)) return null;
    return m.budget === 0 ? `${nb(m.valeur)}, budget 0` : `${nb(m.valeur)} sur ${nb(m.budget)} ${unite === 'worktrees' ? 'worktrees actifs' : unite}`;
  }
  const CATEGORIES = [['ok', (n) => `${n}${NB}dans le budget`], ['surveiller', (n) => `${n}${NB}à surveiller`],
    ['depasse', (n) => `${n}${NB}dépassée${n > 1 ? 's' : ''}`],
    ['na', (n) => `${n}${NB}non applicable${n > 1 ? 's' : ''}`], ['indispo', (n) => `${n}${NB}indisponible${n > 1 ? 's' : ''}`],
    ['format', (n) => `${n}${NB}format non reconnu`]];
  function bilan(jauges) {
    const c = {}; for (const j of jauges) { const v = verdictDe(j); c[v] = (c[v] || 0) + 1; }
    return [`${jauges.length}${NB}jauge${jauges.length > 1 ? 's' : ''}`, ...CATEGORIES.filter(([v]) => c[v]).map(([v, f]) => f(c[v]))].join(' · ');
  }
  window.__vfSyntheseJauges = Object.freeze({ NOMS, GROUPES, MOTS, RAISONS, valeurTexte, bilan });

  // ---------- page ----------
  const poserTexte = (e, t) => { e.textContent = t; }; // toute valeur venue du lab passe par ici : du texte, jamais du balisage
  const el = (tag, attrs, texte) => {
    const e = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) e.setAttribute(k, v);
    if (texte !== undefined && texte !== null) poserTexte(e, String(texte));
    return e;
  };
  const HACHURES = '<svg xmlns=\'http://www.w3.org/2000/svg\' width=\'8\' height=\'8\'>'
    + '<path d=\'M-2 2L2 -2M0 8L8 0M6 10L10 6\' stroke=\'black\' stroke-width=\'3\'/></svg>';
  const feuille = () => {
    if (document.getElementById('vf-sy-jauges')) return;
    const masque = `url("data:image/svg+xml,${encodeURIComponent(HACHURES)}") 0 0 / 8px 8px`;
    const st = document.createElement('style'); st.id = 'vf-sy-jauges';
    st.textContent = `.vf-sy .vst { --c-st: var(--text-2); }
      .vf-sy p.vf-sy-mnote, .vf-sy p.vf-sy-bilan { margin: var(--sp-6) 0 0; font-size: 12.5px; line-height: 1.45; color: var(--text-3); }
      .vf-sy-corps > .btn { margin-top: var(--sp-8); }
      .vf-sy p.vf-sy-bilan { color: var(--text-2); font-weight: 500; }
      .vf-sy p.vf-sy-pied { margin: var(--sp-12) 0 0; font-size: 11px; font-weight: 500; line-height: 1.45; color: var(--text-3); }
      .vf-sy .vf-sy-corps h4 { margin: var(--sp-16) 0 var(--sp-4); font-size: 11px; font-weight: 500; line-height: 16px; color: var(--text-3); }
      .vf-sy ul.vf-sy-groupe, .vf-sy ul.vf-sy-autres { list-style: none; margin: 0; padding: 0; }
      .vf-sy li.vf-sy-jauge { display: grid; grid-template-columns: 1fr auto; column-gap: var(--sp-12); row-gap: var(--sp-4); margin: 0;
        padding: var(--sp-8) 0; font-size: 12.5px; font-weight: 500; line-height: 1.4; }
      .vf-sy-jauge > .vf-bar, .vf-sy-jauge > .vf-sy-l3, .vf-sy-jauge > .vf-sy-autres, .vf-sy-jauge > .vf-sy-more { grid-column: 1 / -1; }
      .vf-sy-nom { color: var(--text); min-width: 0; overflow-wrap: anywhere; }
      .vf-sy-val { color: var(--text-2); font-variant-numeric: tabular-nums; white-space: nowrap; }
      .vf-sy-jauge .vf-bar { margin-top: 0; }
      .vf-sy-jauge .vf-sy-hach { -webkit-mask: ${masque}; mask: ${masque}; }
      .vf-sy-l3, .vf-sy-autres li { display: flex; flex-wrap: wrap; align-items: center; gap: var(--sp-2) var(--sp-8); }
      .vf-sy-chemin, .vf-sy-autres code { font: 500 11px var(--mono); color: var(--text-3); overflow-wrap: anywhere; }
      .vf-sy-micro { font-size: 11px; font-weight: 500; line-height: 1.45; color: var(--text-3); font-variant-numeric: tabular-nums; }
      .vf-sy-autres li { margin: 0; padding: var(--sp-2) 0; font-size: 11px; font-weight: 500; color: var(--text-3); font-variant-numeric: tabular-nums; }
      .vf-sy p.vf-sy-more { margin: var(--sp-4) 0 0; font-size: 11px; font-weight: 500; line-height: 1.45; color: var(--text-4); }
      @media (pointer: coarse), (max-width: 999px) { .vf-sy .vf-sy-corps .btn { min-height: 44px; } }`;
    document.head.appendChild(st);
  };

  function code(chemin) { // chaque segment est du texte ; une coupure possible (<wbr>) après chaque « / », jamais au milieu d'un segment
    const c = el('code', { class: 'vf-sy-chemin' }), seg = chemin.split('/');
    seg.forEach((s, i) => { c.append(el('span', {}, i < seg.length - 1 ? `${s}/` : s)); if (i < seg.length - 1) c.append(document.createElement('wbr')); });
    return c;
  }
  const verdictLigne = (verdict, chemin) => (chemin !== null && sauf(chemin) === null ? 'format' : verdict);
  function normer(j) { // le verdict affiché : celui de la route, sauf une forme que la page ne reconnaît pas (chemin du poste, valeur illisible)
    const m = Array.isArray(j.mesures) && j.mesures.length ? j.mesures[0] : null, brut = m && typeof m.chemin === 'string' ? m.chemin : null;
    let v = verdictLigne(verdictDe(j), brut);
    const val = MESURES.includes(v) ? valeurTexte({ ...m, verdict: v }, j.unite) : null;
    if (MESURES.includes(v) && val === null) v = 'format';
    return { m, v, val, chemin: v === 'format' ? null : sauf(brut) };
  }
  function ligne(j) {
    const { m, v, val, chemin } = normer(j), li = el('li', { class: 'vf-sy-jauge', 'data-vf-sy-jauge': j.type, 'data-verdict': v });
    li.append(el('span', { class: 'vf-sy-nom' }, NOMS[j.type]));
    if (val !== null) {
      li.append(el('span', { class: 'vf-sy-val' }, val));
      const plein = v === 'depasse' || (m.budget === 0 && m.valeur > 0), i = el('i', plein ? { class: 'vf-sy-hach' } : {});
      i.style.width = `${plein ? 100 : m.budget === 0 ? 0 : Math.min(100, r1((100 * m.valeur) / m.budget))}%`;
      const barre = el('div', { class: 'vf-bar', 'aria-hidden': 'true' }); barre.append(i); li.append(barre);
    }
    const l3 = el('div', { class: 'vf-sy-l3' }); l3.append(el('span', { class: `vst ${MOTS[v][1]}` }, MOTS[v][0]));
    if (chemin && chemin !== '.') l3.append(code(chemin));
    const b = j.type === 'socle' && j.baseline && Number.isFinite(j.baseline.valeur) && Object.hasOwn(RELATIONS, j.baseline.relation) ? j.baseline : null;
    if (b) l3.append(el('span', { class: 'vf-sy-micro' }, `Ligne de baseline : ${nb(b.valeur)} jetons, mesure ${RELATIONS[b.relation]}.`));
    const raison = v === 'na' ? (['agent', 'skill', 'socle'].includes(j.type) ? RAISONS.na : '') : v === 'format' ? RAISONS.format
      : v === 'indispo' ? RAISONS.indispo[Object.hasOwn(RAISONS.indispo, j.cause) ? j.cause : 'defaut'] : '';
    if (raison) l3.append(el('span', { class: 'vf-sy-micro' }, raison));
    li.append(l3);
    const autres = (Array.isArray(j.mesures) ? j.mesures.slice(1) : []).filter((x) => x && (x.verdict === 'depasse' || x.verdict === 'surveiller'));
    if (autres.length) {
      const ul = el('ul', { class: 'vf-sy-autres' });
      for (const a of autres.slice(0, 5)) {
        const sa = sauf(a.chemin), va = sa === null && a.chemin !== null ? 'format' : verdictDe(a), x = el('li');
        const vt = valeurTexte({ ...a, verdict: va }, j.unite);
        if (sa) x.append(code(sa));
        if (vt !== null) x.append(el('span', {}, vt));
        x.append(el('span', { class: `vst ${MOTS[va][1]}` }, MOTS[va][0])); ul.append(x);
      }
      li.append(ul);
      if (autres.length > 5) li.append(el('p', { class: 'more vf-sy-more' }, `et ${autres.length - 5} autres`));
    }
    return li;
  }

  let corpsCourant = null, ctxCourant = null, reponse, lecture = 0;
  const bouton = () => {
    const b = el('button', { type: 'button', class: 'btn soft', 'data-vf-sy-relire': '' }, 'Relire les jauges');
    b.addEventListener('click', () => { if (b.getAttribute('aria-disabled') !== 'true') { b.setAttribute('aria-disabled', 'true'); lire(true); } });
    return b;
  };
  const note = (texte) => el('p', { class: 'pd vf-sy-mnote' }, texte);
  const attente = (corps) => {
    corps.parentElement.setAttribute('aria-busy', 'true'); corps.textContent = ''; corps.append(note('Lecture des jauges en cours.'));
  };
  const heure = (at) => {
    const d = new Date(at), mn = String(d.getMinutes()).padStart(2, '0');
    return Number.isNaN(d.getTime()) ? '' : `Mesuré à ${d.getHours()} h ${mn} par les contrôles de la méthode.`;
  };
  function dessiner(corps, j, annoncer) {
    const sec = corps.parentElement, ctx = ctxCourant, avait = corps.contains(document.activeElement);
    sec.removeAttribute('aria-busy'); corps.textContent = '';
    const par = j && typeof j === 'object' && j.schema === SCHEMA && Array.isArray(j.jauges) ? new Map(j.jauges.map((g) => [g && g.type, g])) : null;
    const jauges = par ? GROUPES.flatMap((g) => g.types).filter((t) => par.has(t)).map((t) => par.get(t)) : [];
    let dit;
    if (!par) { corps.append(note('Les jauges sont indisponibles : le serveur du cockpit n\'a pas répondu.'), bouton()); dit = 'Jauges indisponibles.'; }
    else if (jauges.length && jauges.every((g) => verdictDe(g) === 'indispo')) {
      const causes = new Set(jauges.map((g) => g.cause)), c = causes.size === 1 ? [...causes][0] : null;
      const raison = RAISONS.indispo[Object.hasOwn(RAISONS.indispo, c) ? c : 'defaut'];
      corps.append(note('Aucune jauge n\'a pu être lue.'), note(raison), bouton()); dit = 'Jauges indisponibles.';
    } else {
      const b = bilan(jauges.map((g) => ({ verdict: normer(g).v }))); corps.append(el('p', { class: 'vf-sy-bilan' }, b));
      for (const g of GROUPES) {
        const ls = g.types.filter((t) => par.has(t)); if (!ls.length) continue;
        const ul = el('ul', { class: 'vf-sy-groupe' }); for (const t of ls) ul.append(ligne(par.get(t)));
        corps.append(el('h4', {}, g.titre), ul);
      }
      const pied = heure(j.at); if (pied) corps.append(el('p', { class: 'vf-sy-pied' }, pied));
      dit = `Jauges lues : ${b.split(' · ').slice(1).join(', ')}.`;
    }
    if (annoncer && ctx) ctx.annoncer(dit);
    // le focus ne se perd jamais sur le corps de la page
    if (avait) (corps.querySelector('button.btn') || sec.querySelector('h3')).focus({ preventScroll: true });
  }
  function lire(garder) { // une lecture par appel ; sur « Relire », le contenu reste en place (le bouton garde le focus) jusqu'à l'arrivée
    const n = ++lecture, ctx = ctxCourant;
    if (!garder) attente(corpsCourant); else corpsCourant.parentElement.setAttribute('aria-busy', 'true');
    ctx.lireJson(ROUTE).then((j) => {
      if (n !== lecture) return;
      reponse = j; if (corpsCourant && corpsCourant.isConnected) dessiner(corpsCourant, j, true);
    });
  }
  function rendre(corps, ctx) {
    corpsCourant = corps; ctxCourant = ctx;
    if (reponse === undefined) attente(corps); else dessiner(corps, reponse, false); // un rafraîchissement du panneau ne relit rien
  }
  function ouvrir(corps, ctx) { corpsCourant = corps; ctxCourant = ctx; reponse = undefined; lire(false); }
  function installer() {
    feuille(); corpsCourant = null; ctxCourant = null; reponse = undefined; lecture++;
    return () => { lecture++; corpsCourant = null; ctxCourant = null; };
  }
  const R = (window.__vfSyntheseBlocs = window.__vfSyntheseBlocs || []);
  for (let i = R.length - 1; i >= 0; i--) if (R[i] && R[i].id === 'methode') R.splice(i, 1);
  R.push(Object.freeze({ id: 'methode', titre: 'Santé de la méthode', installer, present: () => true, rendre, ouvrir }));
})();
