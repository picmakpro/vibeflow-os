// VibeFlow (75-08, ACTV-06, ACTV-07, ACTV-08, ACTV-10) : les sections du panneau de détail : « Change souvent avec », « Gardes », « Agents sur ce
// fichier »,
// « Collisions possibles » (75-UI-SPEC § 3, § 4, § 5.3, § 6). Chaque section est posée par le DOM (createElement, textContent) dans le conteneur que
// le moteur rend à
// `bind` : aucun HTML n'est écrit ici, chemins, branches, rôles et titres d'agent (données hostiles) restent du texte. Le moteur ne retire jamais une
// section :
// le nettoyage rendu éteint les fonctions (elles ne rendent plus rien). Inscription : VF_COQUILLE.surOnglet(..., { cle }) →
// window.VF_ACTIVITE.brancher('panneau', creer).
(() => {
  'use strict';
  const CLE = '75-vf-activite-panneau.js', ID = 'vfa-panneau-style';
  const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const CSS = `
    .vfa-l { display: flex; align-items: center; gap: var(--sp-8); padding: var(--inset-row); border-radius: 14px; color: var(--text-2);
      font-size: 13px; } /* dérivé : DESIGN § 3 */
    .vfa-l .lg { font-size: 12px; } /* dérivé : le glyphe suit le texte (1,45 em) */
    .vfa-nom { flex: 1; min-width: 0; direction: rtl; text-align: left; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
      font-family: var(--mono); color: var(--text); }
    .vfa-nom bdi { direction: ltr; unicode-bidi: isolate; }
    .vfa-pct { margin-left: auto; color: var(--text-2); font-variant-numeric: tabular-nums; }
    .vfa-t { flex: 1; min-width: 0; }
    .vfa-t span { display: block; font-size: 12px; color: var(--text-3); } /* dérivé : DESIGN § 3 */
    .vfa-pied { margin: var(--sp-8) 0 0; padding: 0 var(--sp-12); font-size: 12px; line-height: 1.5; color: var(--text-3); } /* dérivé : DESIGN § 3 */
    .vfa-sec details { margin: var(--sp-4) 0 0; }
    .vfa-sec summary { padding: var(--sp-4) var(--sp-12); font-size: 12px; color: var(--text-3); cursor: pointer; } /* dérivé : DESIGN § 3 */`;
  const MAX_NOEUD = 5, MAX_RACINE = 10;

  const creer = (ctx) => {
    const { M, T } = ctx, TX = T.TEXTES, F = T.F;
    let vivant = true, signature = '';
    const st = el('style'); st.id = ID; st.textContent = CSS; document.head.appendChild(st);
    const fichierDe = (id) => (typeof id === 'string' && (id.startsWith('f:') || id.startsWith('m:')) ? id.slice(2) : null);
    const section = (cle, titre, n) => {
      const s = el('div', 'sec vfa-sec'), h = el('h3', '', titre);
      s.dataset.vfa = cle; h.tabIndex = -1; h.dataset.vfaTitre = cle;
      if (n !== undefined) h.append(' ', el('span', 'c', String(n)));
      s.appendChild(h); return s;
    };
    const glyphe = (g) => { const i = el('i', 'lg lg-' + g); i.setAttribute('aria-hidden', 'true'); return i; };
    const nom = (chemin) => { const s = el('span', 'vfa-nom'), b = el('bdi', '', chemin); s.appendChild(b); return s; };
    const ligne = (g, contenu, go, titre) => { // une rangée : cliquable (data-go, le moteur y pose l'écoute) ou de texte
      const a = el(go ? 'a' : 'div', go ? 'row vfa-l' : 'vfa-l');
      if (go) a.dataset.go = go;
      if (titre) a.title = titre;
      if (g) a.appendChild(glyphe(g));
      a.append(...contenu); return a;
    };
    const pied = (...t) => { const p = el('p', 'vfa-pied'); p.textContent = t.filter(Boolean).join(' '); return p; };

    const chauds = (id) => {
      const p = fichierDe(id), D = ctx.donnees(), c = p && D && D.git && D.git.etat === 'ok' && T.marquable(ctx.vue(), p) ? T.chaud(D, p) : null;
      if (!c) return null;
      const s = section('chauds', TX.chaudsTitre);
      s.appendChild(ligne(c.palier, [el('span', 'vfa-t', c.info)]));
      return s;
    };
    const couplage = (id) => {
      const p = fichierDe(id), D = ctx.donnees();
      if (!p || !D || !D.git || (D.git.etat !== 'ok' && D.git.etat !== 'vide')) return null;
      const vs = T.voisins(D, p, Infinity), s = section('couplage', TX.changeAvec, vs.length);
      if (!vs.length) s.appendChild(el('div', 'vfa-pied', TX.sansSeuil));
      for (const [q, deg, com] of vs.slice(0, MAX_NOEUD)) {
        const pct = el('span', 'vfa-pct', `${deg}${T.NB}%`);
        s.appendChild(ligne(T.palCouplage(deg), [nom(q), pct], M.exists('f:' + q) ? 'f:' + q : null,
          `Change avec ce fichier dans ${deg}${T.NB}% des commits, ${T.pl(com, 'révision commune', 'révisions communes')}`));
      }
      if (vs.length > MAX_NOEUD) s.appendChild(el('div', 'vfa-pied', F.etAutres(vs.length - MAX_NOEUD)));
      s.appendChild(pied(TX.pied90, D.git.fenetre && D.git.fenetre.partiel ? TX.partiel + '.' : ''));
      return s;
    };
    const gardes = (id) => {
      const p = fichierDe(id), D = ctx.donnees(), t = p && D && D.gardes && D.gardes.etat === 'ok' ? D.gardes.gardes.find((x) => x[0] === p) : null;
      if (!t) return null;
      const s = section('gardes', TX.gardesTitre);
      if (t[2]) s.appendChild(ligne('bouclier', [el('span', 'vfa-t', TX.gardeDepot)]));
      if (t[1] > 0) s.appendChild(ligne(null, [el('span', 'vfa-t', `${TX.nommePar} ${T.pl(t[1], 'suite', 'suites')}`)]));
      else if (!t[2]) s.appendChild(ligne('sans-temoin', [el('span', 'vfa-t', TX.aucunTemoin)]));
      return s;
    };
    const agents = (id) => {
      const p = fichierDe(id), D = ctx.donnees();
      const t = p && D && D.empreinte && ctx.conn() !== 'perdu' && D.empreinte.etat !== 'indisponible' ? D.empreinte.marques.find((x) => x[0] === p) : null;
      if (!t || !T.MOT_DEGRE[t[1]]) return null;
      const [, deg, noms] = t, s = section('agents', TX.agentsSur, noms.length), mot = T.MOT_DEGRE[deg];
      const rangs = noms.map((n) => ligne(deg, [el('span', 'vfa-t', `${mot} · ${n}`)]));
      if (deg === 'fini') { const d = el('details'); d.append(el('summary', '', F.termines(noms.length)), ...rangs); s.appendChild(d);
        } else s.append(...rangs);
      return s;
    };
    const collisions = (id, racine) => {
      const D = ctx.donnees(), v = ctx.vue();
      if (!D) return null;
      let par = [...T.parFichier(D, v)];
      const p = fichierDe(id);
      if (!racine) par = p ? par.filter(([q]) => q === p) : par.filter(([q]) => v.ancetres('f:' + q).includes(id));
      const m = ctx.modele(), incomplet = m && m.radar.etat === 'incomplet';
      if (!par.length && !(racine && incomplet)) return null;
      const s = section('collisions', TX.collisionsTitre, par.length), max = racine ? MAX_RACINE : MAX_NOEUD;
      for (const [q, l] of par.slice(0, max)) {
        const t = el('span', 'vfa-t'), mots = l.map(([src, noms, vague]) => T.SOURCE_MOT[src](noms.length, vague));
        t.append(el('b', '', q), ...l.map(([, noms], i) => el('span', '', `${mots[i]} · ${T.joindre(noms)}`)));
        if (l.some((x) => x[0] === 'plans')) t.append(el('span', '', TX.plansAJour));
        s.appendChild(ligne('confluent', [t], 'f:' + q));
      }
      if (par.length > max) s.appendChild(el('div', 'vfa-pied', F.etAutres(par.length - max)));
      const plafond = D.branches && D.branches.plafondAtteint ? TX.radarBranchesMax + '.' : '';
      s.appendChild(pied(F.piedLong(D.empreinte ? D.empreinte.horsLab || 0 : 0), plafond, incomplet ? m.radar.ligne : ''));
      return s;
    };
    const emballer = (f) => (id) => {
      if (!vivant) return '';
      const s = f(id);
      return s ? { html: '', bind: (boite) => boite.appendChild(s) } : '';
    };
    M.addPanelSection('item', emballer(chauds)); M.addPanelSection('item', emballer(couplage)); M.addPanelSection('item', emballer(gardes));
    M.addPanelSection('item', emballer(agents)); M.addPanelSection('item', emballer((id) => collisions(id, false)));
    M.addPanelSection('overview', emballer(() => collisions(null, true)));
    ctx.partage.collisionsRacine = () => collisions(null, true); // le compte du radar l'emploie quand la sélection n'a aucune collision

    // le panneau suit l'activité : il n'est reposé que si ce qu'il montre a changé (la section remet sa position de défilement à zéro)
    const cible = () => { const s = M.state && M.state.selected;
      return typeof s === 'string' ? (s.startsWith('m:') ? 'f:' + s.slice(2) : s) : s ? null : M.state.container; };
    const lu = (id) => [chauds(id), couplage(id), gardes(id), agents(id), collisions(id, id === 'root')].map((s) => (s ? s.textContent : '')).join('|');
    const maj = () => {
      const id = cible();
      if (!id) return;
      const s = lu(id);
      if (signature && s !== signature && !document.body.classList.contains('no-panel')) M.refreshPanel();
      signature = s;
    };
    return { maj, detruire: () => { vivant = false; st.remove(); } };
  };

  const arrivee = (ev) => {
    const H = window.VF_ACTIVITE;
    return !ev || ev.onglet !== 'code' || !H ? () => {} : H.brancher('panneau', creer);
  };
  if (window.VF_COQUILLE && typeof window.VF_COQUILLE.surOnglet === 'function') window.VF_COQUILLE.surOnglet(arrivee, { cle: CLE });
})();
