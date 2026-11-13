// VibeFlow (74-07) : tableau « Coût » de la frise (P74-D-20 à D-23, D-32, D-34, D-42), pose window.__vfCoutTableau et la feuille de
// la synthèse et de la section.
// Jetons et durées seulement, sommes déjà faites par __vfFriseModele.agreger : aucune lecture de transcript, aucun calcul de jetons ici, aucune devise, aucune
// barre, aucune teinte. Une valeur absente de la source se lit « inconnu », jamais 0. Chargé avant 74-vf-cout.js (ordre lexical). Chaque valeur porte son
// libellé (data-lib) et sa valeur entière (data-v) : au téléphone, chaque ligne devient un bloc.
(() => {
  'use strict';
  const D = document, NB = ' ';
  const COLS = [['travailS', 'Au travail', 'd'], ['attenteHumainS', 'À vous attendre', 'd'], ['entree', 'Entrée', 'j'], ['sortie', 'Sortie', 'j'],
    ['cacheLu', 'Cache lu', 'j'], ['cacheCree', 'Cache écrit', 'j']];
  const PREMIERE = { mission: 'Mission et phase', agent: 'Agent', etage: 'Étage' };
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const tri = (ls) => ls.slice().sort((a, b) => (b.travailS ?? -1) - (a.travailS ?? -1));
  const rattache = (v) => !!(v.rattachement && v.rattachement.dag != null);

  function construire(M, agg, voies, o) {
    const { par, titre, lib, ouvertes, surBascule } = o, hors = voies.filter((v) => !rattache(v)), horsIds = new Set(hors.map((v) => v.id));
    const t = h('table', 'vf-cout-table'), cap = h('caption', 'sr', titre), th = h('thead'), corps = h('tbody');
    const r1 = h('tr'), r2 = h('tr');
    const entete = (tr, texte, span, scope) => {
      const c = h('th', null, texte); c.setAttribute('scope', scope); if (span > 1) c.colSpan = span; tr.append(c);
    };
    entete(r1, '', 1, 'col'); entete(r1, `Durées, sur les dernières ${lib}`, 2, 'colgroup'); entete(r1, `Jetons, sur les dernières 24${NB}h`, 4, 'colgroup');
    entete(r2, PREMIERE[par], 1, 'col');
    for (const [, nom] of COLS) entete(r2, nom, 1, 'col');
    th.append(r1, r2); t.append(cap, th, corps);

    const cellules = (tr, l) => {
      for (const [cle, nom, genre] of COLS) {
        const v = l[cle], td = h('td', null, v == null ? 'inconnu' : (genre === 'd' ? M.fmtDuree(v) : M.fmtJetons(v)));
        td.setAttribute('data-lib', nom); if (v != null) td.setAttribute('data-v', String(v));
        tr.append(td);
      }
    };
    const rang = (nom, l, opt = {}) => {
      const tr = h('tr', opt.phase ? 'vf-cout-phase' : opt.total ? 'vf-cout-total' : ''), c = h('th');
      const n = h('span', opt.mono ? 'vf-cout-nom mono' : 'vf-cout-nom', nom);
      c.setAttribute('scope', 'row');
      if (opt.exp != null) {
        const b = h('button', 'vf-cout-depli'); b.type = 'button';
        b.setAttribute('aria-expanded', opt.exp ? 'true' : 'false'); b.setAttribute('data-cle', opt.cle);
        n.className = 'vf-cout-nom'; b.append(n); b.addEventListener('click', () => surBascule(opt.cle)); c.append(b);
      } else c.append(n);
      if (opt.sous) c.append(h('span', 'vf-cout-sous', opt.sous));
      if (opt.titre) tr.title = opt.titre;
      tr.setAttribute('data-niveau', opt.phase ? 'phase' : opt.total ? 'total' : 'ligne');
      tr.prepend(c); cellules(tr, l);
      return tr;
    };
    if (par === 'mission') {
      for (const m of tri(agg.lignes)) {
        const ph = m.phases || [], ouv = ouvertes.has(m.cle);
        corps.append(rang(m.libelle, m, ph.length ? { exp: ouv, cle: m.cle } : {}));
        if (ph.length && ouv) for (const p of tri(ph)) corps.append(rang(p.libelle, p, { phase: true }));
      }
      if (hors.length) corps.append(rang('Hors mission', agg.horsMission, { sous: 'agents sans nœud de plan rattaché' }));
    } else if (par === 'agent') {
      for (const l of tri(agg.lignes)) corps.append(rang(l.libelle, l, { mono: true, sous: horsIds.has(l.cle) ? 'hors mission' : null }));
    } else for (const l of tri(agg.lignes)) corps.append(rang(l.libelle, l, {}));
    const inc = agg.incomplet;
    const titreTotal = inc ? 'Lecture incomplète : des voies ne sont pas montrées.' : null;
    corps.append(rang(inc ? 'Total (incomplet)' : 'Total', agg.total, { total: true, titre: titreTotal }));
    return t;
  }

  const feuille = () => {
    if (typeof document === 'undefined' || !D.head || D.head.querySelector('style[data-vf-cout]')) return;
    const st = D.createElement('style');
    st.setAttribute('data-vf-cout', '');
    st.textContent = `
      .vf-frise-synthese { color: var(--text-2); }
      .vf-frise-synthese a { color: var(--text); text-decoration: underline; cursor: pointer; }
      .vf-cout { margin: var(--sp-16) 0 0; }
      .vf-cout-titre { margin: 0 0 var(--sp-4); font: 600 15px/20px var(--sans); letter-spacing: -.015em; color: var(--text); }
      .vf-cout-titre:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
      .vf-cout-sous, .vf-cout-note { margin: 0 0 var(--sp-8); color: var(--text-3); }
      .vf-cout .vf-frise-groupe { margin: 0 0 var(--sp-8); }
      .vf-cout-table { width: 100%; border-collapse: collapse; font-size: 12.5px; line-height: 16px; background: var(--surface); }
      .vf-cout-table th, .vf-cout-table td { padding: var(--sp-6) var(--sp-8); border-top: 1px solid var(--hair); text-align: right; font-weight: 400; }
      .vf-cout-table thead th { border-top: 0; color: var(--text-3); font: 400 11.5px/14px var(--sans); }
      .vf-cout-table td { font-variant-numeric: tabular-nums; color: var(--text); }
      .vf-cout-table th[scope=row] { text-align: left; color: var(--text); }
      .vf-cout-table th[scope=col]:first-child { text-align: left; }
      .vf-cout-nom { font-weight: 500; }
      .vf-cout-sous { display: block; margin: 0; font-size: 12.5px; }
      .vf-cout-phase th[scope=row] { padding-left: calc(var(--sp-8) + var(--sp-16)); }
      .vf-cout-depli { padding: 0; border: 0; background: transparent; color: inherit; font: inherit; text-align: left; cursor: pointer; }
      .vf-cout-depli::before { content: '\\25B8'; display: inline-block; margin-right: var(--sp-4); color: var(--text-3); }
      .vf-cout-depli[aria-expanded=true]::before { content: '\\25BE'; }
      .vf-cout-total th, .vf-cout-total td { font-weight: 600; }
      @media (max-width: 700px) {
        .vf-cout-table, .vf-cout-table tbody, .vf-cout-table tr, .vf-cout-table th, .vf-cout-table td { display: block; }
        .vf-cout-table thead { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); }
        .vf-cout-table tr { padding: var(--sp-8) 0; border-top: 1px solid var(--hair); }
        .vf-cout-table th, .vf-cout-table td { border-top: 0; padding: var(--sp-2) 0; text-align: left; }
        .vf-cout-table td { display: grid; grid-template-columns: 1fr auto; gap: var(--sp-8); text-align: right; }
        .vf-cout-table td::before { content: attr(data-lib); color: var(--text-3); text-align: left; }
      }
    `;
    D.head.appendChild(st);
  };
  feuille();

  window.__vfCoutTableau = Object.freeze({ construire, COLS });
})();
