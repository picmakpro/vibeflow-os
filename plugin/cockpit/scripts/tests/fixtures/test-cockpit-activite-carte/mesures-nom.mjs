// mesures-nom.mjs — mesures navigateur de la tâche 3 du plan 75-07 : nom accessible (D13), cartes « prévues » (D14), chaîne XSS (D15), marque de collision (D16).
const DIR_A = 'd:d-src|src/a', DIR_B = 'd:d-src|src/b', NOEUD = 'n:d-src', F1 = 'f:src/b/n01.js', PREVUE = 'f:src/a/neuf.mjs';
const j = JSON.stringify;
const ins = (base, mots) => { const i = base.lastIndexOf(', '); return base.slice(0, i) + (mots.length ? ', ' + mots.join(', ') : '') + base.slice(i); }; // le gabarit : avant « reliée à N cartes »
const pose = (s, couche, rows, excl = true) => s.ev(`VF_MARQUES.poser(${j(couche)}, ${j(rows)}, { exclusif: ${excl} })`);
const nom = (s, id) => s.ev(`VibeFlow.state.chipEls.get(${j(id)}).getAttribute('aria-label')`);
const base = (s, id) => s.ev(`window.VF_CANEVAS.nomDeCarte(${j(id)})`);
const efface = (s, noms) => s.ev(`for (const n of ${j(noms)}) VF_MARQUES.retirer(n)`);

export const mesuresNom = {
  // D13, D13b : <titre>, <état>, <pied>, [mot de lentille], [mot de collision], reliée à N cartes ; reposé après chaque render ; une carte à statut sans mot de lentille
  async d13(c) {
    const { s } = c, cas = [];
    const essai = async (nomCas, id, lentille, collisions, mots) => {
      await efface(s, ['len', 'col']); await c.poser(); const b = await base(s, id);
      if (lentille) await pose(s, 'len', lentille, true);
      if (collisions) await pose(s, 'col', collisions, false);
      await c.poser(); const avec = await nom(s, id);
      cas.push({ cas: nomCas, id, base: b, avec, attendu: ins(b, mots) });
    };
    await c.vue(1440, 900); await c.charger('index.html'); await c.aller(DIR_B);
    const LEN = [[F1, 'haut', 'haut', '41 changements', 'i']], COL = [[F1, 'agents', 'confluent', 'écrit par 2 agents', 'i'], [F1, 'branches', 'confluent', 'modifié sur 2 branches', 'i']];
    await essai('fichier : lentille', F1, LEN, null, ['41 changements']);
    await essai('fichier : lentille puis collision (toutes les sources)', F1, LEN, COL, ['41 changements', 'écrit par 2 agents', 'modifié sur 2 branches']);
    await essai('fichier : collision seule', F1, null, COL, ['écrit par 2 agents', 'modifié sur 2 branches']);
    await s.ev('VibeFlow.rerender()'); await c.poser(); const apresRender = await nom(s, F1); // reposé après le render de la page, qui réécrit le nom de base
    await efface(s, ['len', 'col']); await c.aller(NOEUD);
    const fichiers = ['f:src/b/n01.js', 'f:src/b/n02.js', 'f:src/b/n03.js'];
    await essai('nœud : agrégat de lentille et de collision', DIR_B, fichiers.map((f) => [f, 'haut', 'haut', '9 changements', 'i']), fichiers.slice(0, 2).map((f) => [f, 'agents', 'confluent', 'écrit par 2 agents', 'i']), ['3 chauds', '2 fichiers en collision']);
    return { cas, apresRender, attenduRender: cas[2].attendu };
  },

  // D14, D14b : la carte « prévue » (classe, mot, bordure, immobilité du contenu, menu, panneau, dossier virtuel, nom) ; la carte « non assignés »
  async d14(c) {
    // densité 2 : une bordure de 1,5 px y tombe sur un nombre entier de pixels (à densité 1 le navigateur l'arrondit à 1 px et le contenu bouge de 0,5 px)
    const { s } = c; await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 2, mobile: false }); await c.charger('index.html'); const o = {};
    o.racine = await s.ev(`!!VibeFlow.state.chipEls.get('n:unassigned')`); // un nœud « non assignés » sans fichier réel tient
    await c.aller('n:unassigned'); o.dansNonAssignes = await s.ev(`!!VibeFlow.state.chipEls.get('f:autre/orphelin.mjs')`);
    await c.aller(DIR_A);
    // le contour se lit dans le CSSOM : le style calculé arrondit 1,5 px au pixel
    const lire = (id) => `(() => { const g = VibeFlow.state.chipEls.get(${j(id)}), ca = g.querySelector('.card'), st = getComputedStyle(ca), hd = g.querySelector('.head').getBoundingClientRect(), r = ca.getBoundingClientRect(), v = g.querySelector('.vst');
      return { classe: ca.classList.contains('st-prevu'), mot: v ? v.textContent : null, bordure: st.outlineStyle + ' ' + ([...document.getElementById('vf-marques-style').sheet.cssRules].find((x) => x.selectorText === '.card.st-prevu').cssText.includes('outline: 1.5px dashed') ? '1.5px' : '?') + ' ' + st.borderTopWidth, ombre: st.boxShadow, fond: st.backgroundColor, padding: st.paddingLeft,
        ico: getComputedStyle(g.querySelector('.ico')).color, texte3: (() => { const p = document.createElement('i'); p.style.color = 'var(--text-3)'; document.body.append(p); const v = getComputedStyle(p).color; p.remove(); return v; })(), decalage: g.querySelector('.head').offsetLeft + '|' + g.querySelector('.head').offsetTop, meta: !!g.querySelector('.meta'), hauteur: ca.offsetHeight }; })()`;
    o.prevue = await s.ev(lire(PREVUE)); o.simple = await s.ev(lire('f:src/a/m01.js'));
    o.dossier = await s.ev(`(() => { const i = VibeFlow.info(${j(DIR_A)}); return { fichiers: i.d.files.length, reels: VibeFlow.graph.files.filter((f) => f.p.startsWith('src/a/') && f.st !== 'prevu').length }; })()`);
    const menu = async (id) => { await s.ev(`VibeFlow.state.chipEls.get(${j(id)}).dispatchEvent(new MouseEvent('contextmenu', { bubbles: true, cancelable: true, clientX: 300, clientY: 300 }))`);
      const m = await s.ev("[...document.querySelectorAll('#ctxmenu .mi span')].map((e) => e.textContent).join('|')"); await s.ev("document.querySelector('#ctxmenu').hidden = true"); return m; };
    o.menuPrevue = await menu(PREVUE); o.menuSimple = await menu('f:src/a/m01.js');
    await s.ev(`VibeFlow.select(${j(PREVUE)})`); await s.attendre(`VibeFlow.state.selected === ${j(PREVUE)} && !!document.querySelector('#panel h2')`, 'fiche prévue', 8000);
    o.panneau = await s.ev("JSON.stringify({ editeur: !!document.querySelector('#panel a[href^=\"vscode:\"]'), texte: /n.existe pas encore/.test(document.querySelector('#panel').innerText) })").then(JSON.parse);
    o.nom = { id: PREVUE, vu: await nom(s, PREVUE), titre: await s.ev(`VibeFlow.state.chipEls.get(${j(PREVUE)}).querySelector('.title').textContent.trim()`), desc: await s.ev(`VibeFlow.state.chipEls.get(${j(PREVUE)}).querySelector('.desc').textContent.trim()`) };
    return o;
  },

  // D15 : chemin, branche, rôle et titre hostiles dans les tables : aucun nœud injecté, texte littéral dans la marque, l'infobulle et le nom accessible
  async d15(c) {
    const { s } = c; await c.vue(1440, 900); await c.charger('index.html'); await c.aller(NOEUD);
    const H = '"><img src=x onerror=window.__xss=1><script>window.__xss=1</script>\'</script> __proto__ constructor ' + 'x'.repeat(250);
    const avant = await s.ev("document.querySelectorAll('#viewport img, #viewport script, #viewport i[title], #viewport i[aria-label]').length");
    await pose(s, 'h15', [[DIR_B, 'haut', 'haut', H, H], [DIR_A, 'agents', 'confluent', H, H]], true); await c.poser();
    return JSON.parse(await s.ev(`JSON.stringify((() => { const g = VibeFlow.state.chipEls.get(${j(DIR_B)}), lw = g.querySelector('.lw'), lm = g.querySelector('.lm');
      return { avant: ${avant}, apres: document.querySelectorAll('#viewport img, #viewport script, #viewport i[title], #viewport i[aria-label]').length, xss: window.__xss === undefined, enfants: lw.children.length,
        mot: lw.textContent === ${j(H.slice(0, 300))}, titre: lm.getAttribute('title') === ${j(H.slice(0, 600))}, nom: g.getAttribute('aria-label').includes(${j(H.slice(0, 300))}), proto: ({}).polluted === undefined }; })())`));
  },

  // D16 : la marque de collision (priorité des quatre sources, forme compacte avec une lentille, emplacement gauche d'une prévue, bords aux trois zooms)
  async d16(c) {
    const { s } = c; await c.vue(1440, 900); await c.charger('index.html'); await c.aller(NOEUD); const o = { niveaux: [], compact: null, prevue: null, bords: [] };
    const SRC = { agents: 'écrit par 2 agents', arbres: 'modifié dans 2 arbres : conflit de fusion possible', branches: 'modifié sur 2 branches', plans: 'prévu par 2 plans, vague 3' };
    const rows = (...ks) => ks.map((k) => [DIR_B, k, 'confluent', SRC[k], 'info ' + k]);
    const mot = () => s.ev(`(() => { const l = VibeFlow.state.chipEls.get(${j(DIR_B)}).querySelectorAll('.lmg .lm'); return [...l].map((e) => e.querySelector('.lw').textContent); })()`);
    for (const ks of [['plans', 'branches', 'arbres', 'agents'], ['plans', 'branches', 'arbres'], ['plans', 'branches'], ['plans']]) { await pose(s, 'col', rows(...ks), false); await c.poser(); o.niveaux.push(await mot()); }
    const lentille = [[DIR_B, 'haut', 'haut', '41 changements', 'i']];
    await pose(s, 'col', rows('plans', 'branches', 'arbres', 'agents'), false); await pose(s, 'len', lentille, true); await c.poser();
    o.compact = JSON.parse(await s.ev(`JSON.stringify((() => { const g = VibeFlow.state.chipEls.get(${j(DIR_B)}), l = [...g.querySelectorAll('.lmg .lm')]; return { n: l.length, premier: l[0].querySelector('.lw').textContent, compact: l[0].classList.contains('lm-n'), titre: l[0].getAttribute('title'), second: l[1] && l[1].querySelector('.lw').textContent, nom: g.getAttribute('aria-label') }; })())`));
    for (const z of ['ouverture', 'mid', 'bas']) { await c.zoom(z); await c.poser();
      o.bords.push({ z, ...JSON.parse(await s.ev(`JSON.stringify((() => { const g = VibeFlow.state.chipEls.get(${j(DIR_B)}), r = g.querySelector('.card').getBoundingClientRect(), p = g.querySelector('.foot').getBoundingClientRect(), l = [...g.querySelectorAll('.lm')].map((e) => e.getBoundingClientRect());
        return { droit: l.every((b) => b.right <= r.right + 0.5), bas: l.every((b) => b.bottom <= p.bottom + 0.5 && b.top >= p.top - 0.5), pied: g.querySelector('.foot').offsetHeight }; })())`)) }); }
    await c.zoom('ouverture'); await efface(s, ['col', 'len']); await c.aller(DIR_A);
    await pose(s, 'col', [[PREVUE, 'plans', 'confluent', SRC.plans, 'info']], false); await pose(s, 'len', [[PREVUE, 'haut', 'haut', '41 changements', 'i'], ['f:src/a/m01.js', 'haut', 'haut', '41 changements', 'i']], true); await c.poser();
    o.prevue = JSON.parse(await s.ev(`JSON.stringify((() => { const g = VibeFlow.state.chipEls.get(${j(PREVUE)}), p = g.querySelector('.foot'), ms = [...g.querySelectorAll('.lm')];
      return { gauche: p.firstElementChild.classList.contains('lmg-g'), vstADroite: p.lastElementChild.classList.contains('vst'), mots: ms.map((e) => e.querySelector('.lw').textContent), nom: g.getAttribute('aria-label'),
        simple: VibeFlow.state.chipEls.get('f:src/a/m01.js').querySelectorAll('.lm').length }; })())`));
    return o;
  },
};
