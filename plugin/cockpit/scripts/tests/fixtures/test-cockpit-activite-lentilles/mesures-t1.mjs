// mesures-t1.mjs — tâche 1 du plan 75-08 : le sélecteur, la lentille « Points chauds » (route réelle du lab), `surOnglet`, la fraîcheur sans sondage.
import { donnees, A } from './donnees.mjs';
const j = JSON.stringify;
const DIR_A = 'd:d-src|src/a', NOEUD = 'n:d-src';
const ETAT = `JSON.stringify({ onglet: VF_COQUILLE.onglet(), boutons: document.querySelectorAll('#btn-lentilles').length, menus: document.querySelectorAll('#lens-menu').length,
  compte: document.querySelectorAll('.vfa-compte').length, live: !!document.getElementById('ask-live'), lm: document.querySelectorAll('#viewport .lm').length,
  styles: document.querySelectorAll('#vfa-style, #vfa-menu-style, #vfa-panneau-style, #vfa-collisions-style').length, abonnes: VF_ETAT.abonnes(), active: VF_MARQUES.active() })`;
const MARQUES = `JSON.stringify(Object.fromEntries([...VibeFlow.state.chipEls].filter(([id]) => id.startsWith('f:')).map(([id, g]) => { const l = [...g.querySelectorAll('.foot .lm')].filter((x) => !x.querySelector('.lg-confluent'));
  return [id, { n: l.length, mot: l[0] ? l[0].querySelector('.lw').textContent : null, glyphe: l[0] ? l[0].querySelector('.lg').className : null, titre: l[0] ? l[0].getAttribute('title') : null, nom: g.getAttribute('aria-label') }]; })))`;

export const mesuresT1 = {
  async t1(c) {
    const { s } = c, o = {};
    await c.vue(1440, 900); await c.charger('index.html');
    const CLES = "JSON.stringify(Object.keys(localStorage).filter((k) => !/visite|tour/i.test(k)).sort())"; // la visite guidée écrit ses propres clés (hors lentilles)
    const ls0 = await s.ev(CLES);
    // L1 : le bouton, sa place, son libellé, son état
    o.bouton = JSON.parse(await s.ev(`JSON.stringify((() => { const b = document.getElementById('btn-lentilles'), bl = b && b.querySelector('.bl'), r = b && b.parentNode;
      return b && { bl: bl.textContent, haspopup: b.getAttribute('aria-haspopup'), expanded: b.getAttribute('aria-expanded'), pressed: b.hasAttribute('aria-pressed'), title: b.title,
        avant: r.previousElementSibling && r.previousElementSibling.id, apres: r.nextElementSibling && r.nextElementSibling.id, visible: getComputedStyle(b).display !== 'none',
        rond: b.querySelector('.vfa-i') ? +b.querySelector('.vfa-i').getAttribute('r') : null }; })())`));
    o.ariaInactif = await s.ev("document.getElementById('btn-lentilles').getAttribute('aria-label')");
    o.entete = await s.ev("(() => { const h = document.querySelector('header'); return [h.scrollWidth, h.clientWidth, document.getElementById('btn-lentilles').getBoundingClientRect().width]; })()");
    await c.vue(1024, 768); await c.pause(500);
    o.entete1024 = await s.ev("(() => { const h = document.querySelector('header'), b = document.getElementById('btn-panel').getBoundingClientRect(); return [h.scrollWidth, h.clientWidth, Math.round(b.right), innerWidth]; })()");
    await c.vue(1440, 900); await c.pause(300);
    // L1, à 900 px : le bouton quitte l'en-tête, l'entrée du « ⋯ » prend sa place (entre Santé et la suite)
    await c.vue(900, 700); await c.pause(400);
    await s.ev("document.getElementById('vf-plus').click()"); await c.pause(250);
    o.plus = JSON.parse(await s.ev(`JSON.stringify({ entrees: [...document.querySelectorAll('#vf-plus-menu .vf-pl-t')].map((x) => x.textContent), bouton: getComputedStyle(document.getElementById('btn-lentilles')).display })`));
    await c.touche('Escape'); await c.pause(200);
    await c.vue(1440, 900); await c.pause(300);
    // L20 : l'état actif se voit autrement que le survol (le libellé `.bl` est masqué dans l'en-tête : le glyphe de la lentille change)
    await s.attendre("(() => { const r = document.querySelector('#lens-menu .lr[data-id=\"chauds\"]'); return !!r && r.getAttribute('aria-disabled') !== 'true'; })()", 'Points chauds disponible');
    const fondInactif = await s.ev("getComputedStyle(document.getElementById('btn-lentilles')).backgroundColor");
    await c.lentille('chauds');
    o.actif = JSON.parse(await s.ev(`JSON.stringify((() => { const b = document.getElementById('btn-lentilles'); return { bl: b.querySelector('.bl').textContent, rond: +b.querySelector('.vfa-i').getAttribute('r'),
      fond: getComputedStyle(b).backgroundColor, aria: b.getAttribute('aria-label'), active: VF_MARQUES.active(), ferme: !document.getElementById('lens-menu').classList.contains('open'),
      focus: document.activeElement === b, expanded: b.getAttribute('aria-expanded') }; })())`));
    o.fondInactif = fondInactif;
    // L2 : les marques de Points chauds, de la route aux cartes
    await c.aller(NOEUD);
    o.noeud = await s.ev("JSON.stringify([...VibeFlow.state.chipEls].filter(([id]) => id.startsWith('d:')).map(([id, g]) => [id, (g.querySelector('.foot .lm .lw') || {}).textContent]))");
    await c.aller(DIR_A);
    o.marques = JSON.parse(await s.ev(MARQUES));
    o.prevue = await s.ev(`VF_MARQUES.lire('f:src/a/neuf.mjs').length`);
    o.sansMarque = await s.ev(`JSON.stringify([VF_MARQUES.lire('f:scripts/tests/test-lab.sh').length, VF_MARQUES.lire('f:scripts/check-lab.sh').length])`);
    // L19 : le palier est aussi dit par le texte (nom accessible) et le rang par la ligne du panneau
    await s.ev("VibeFlow.select('f:src/a/m14.js')"); await c.pause(500);
    o.panneau = await s.ev("document.getElementById('panel').textContent");
    await s.ev('VibeFlow.select(null)'); await c.pause(200);
    o.nom = await s.ev(`VibeFlow.state.chipEls.get('f:src/a/m14.js').getAttribute('aria-label')`);
    o.nomMoyen = await s.ev(`VibeFlow.state.chipEls.get('f:src/a/m06.js').getAttribute('aria-label')`);
    // L4 : AUCUN sondage quand le calcul est fini (10 s)
    const r0 = await s.ev('window.__reads'); await c.pause(10000);
    o.sondage = (await s.ev('window.__reads')) - r0;
    o.ls = [ls0, await s.ev(CLES)];
    // L4 : tant que `calcul` vaut `en-cours`, une lecture par seconde, 15 au plus, puis l'arrêt
    await c.pousser(donnees({ calcul: 'en-cours', etat: 'en-calcul' }));
    const e0 = await s.ev('window.__reads'); await c.pause(19000);
    const e1 = await s.ev('window.__reads'); await c.pause(5000);
    o.relectures = [e1 - e0, (await s.ev('window.__reads')) - e1];
    await c.pousser(donnees());
    // L1b : la pastille de compte est NEUTRE (fond --on, jamais --recent) et dit le nombre de fichiers en écriture
    o.badge = JSON.parse(await s.ev(`JSON.stringify((() => { const b = document.getElementById('btn-lentilles'), p = b.querySelector('.badge');
      const sonde = (v) => { const e = document.createElement('i'); e.style.background = 'var(' + v + ')'; document.body.appendChild(e); const c = getComputedStyle(e).backgroundColor; e.remove(); return c; };
      return p && { txt: p.textContent, fond: getComputedStyle(p).backgroundColor, on: sonde('--on'), recent: sonde('--recent'), aria: b.getAttribute('aria-label') }; })())`));
    // L3 et L22 : Code, Projet, Code, Projet, Code : rien ne reste, rien ne double
    const visites = [];
    for (const onglet of ['projet', 'code', 'projet', 'code']) {
      await s.ev(`VF_COQUILLE.chargerOnglet(${j(onglet)})`); await s.attendre(`VF_COQUILLE.onglet() === ${j(onglet)} && document.documentElement.dataset.vfPret === 'oui'`, onglet);
      if (onglet === 'code') await s.attendre("!!document.getElementById('btn-lentilles')", 'sélecteur de retour');
      await c.pause(600); visites.push(JSON.parse(await s.ev(ETAT)));
    }
    o.visites = visites;
    await s.attendre("(() => { const r = document.querySelector('#lens-menu .lr[data-id=\"chauds\"]'); return !!r && r.getAttribute('aria-disabled') !== 'true'; })()", 'Points chauds disponible au retour');
    await c.lentille('chauds'); await c.aller(NOEUD); await c.aller(DIR_A);
    o.retour = JSON.parse(await s.ev(MARQUES));
    o.libelleRetour = await s.ev("document.querySelector('#btn-lentilles .bl').textContent");
    o.parties = await s.ev("JSON.stringify([!!document.querySelector('#lens-menu'), !!document.querySelector('#context .vfa-compte'), !!window.VF_ACTIVITE])");
    return o;
  },
};
void A;
