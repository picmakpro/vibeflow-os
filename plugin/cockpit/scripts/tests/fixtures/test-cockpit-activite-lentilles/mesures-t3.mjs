// mesures-t3.mjs — tâche 3 du plan 75-08 : marques de collision, sections du panneau, compte du radar dans `.k`, annonce unique, chaîne XSS, retrait par `surOnglet`.
import { donnees, avec, A, PREVUE, HOSTILE } from './donnees.mjs';
const j = JSON.stringify, DIR_A = 'd:d-src|src/a';
const FICHIER_HOSTILE = 'src/b/h<img src=x onerror=window.__xss=1>"x.js';
const MOTS = (ids) => `JSON.stringify(Object.fromEntries(${j(ids)}.map((id) => { const g = VibeFlow.state.chipEls.get(id); return [id, [...g.querySelectorAll('.foot .lm')].map((m) => m.querySelector('.lw').textContent)]; })))`;
const SECTIONS = `JSON.stringify([...document.querySelectorAll('#panel .vfa-sec')].map((s) => [s.dataset.vfa, s.querySelector('h3').textContent, [...s.querySelectorAll('.vfa-l, .vfa-pied, summary')].map((r) => r.textContent.replace(/[ \\t\\n\\r]+/g, ' ').trim()),
  s.querySelectorAll('[data-go]').length, [...s.querySelectorAll('[data-go]')].map((a) => a.dataset.go)]))`;
const sec = (cle) => `JSON.stringify((() => { const s = document.querySelector('#panel [data-vfa="${cle}"]'); return s && { titre: s.querySelector('h3').textContent, lignes: [...s.querySelectorAll('.vfa-l')].map((r) => r.textContent.replace(/[ \\t\\n\\r]+/g, ' ').trim()),
  go: [...s.querySelectorAll('[data-go]')].map((a) => a.dataset.go), pieds: [...s.querySelectorAll('.vfa-pied')].map((p) => p.textContent), details: [...s.querySelectorAll('details')].map((d) => [d.open, d.querySelector('summary').textContent]) }; })())`;
const COLLISIONS = (n) => Array.from({ length: n }, (_, i) => [A(i + 1), 'agents', ['vf-coder · a', 'vf-coder · b'], null]);
const COMPTE = `JSON.stringify((() => { const b = document.querySelector('#context .vfa-compte'), k = document.querySelector('#context .k'), c = document.getElementById('context'), av = b && getComputedStyle(b, '::before');
  return b && { texte: b.textContent, aria: b.getAttribute('aria-label'), titre: b.title, cache: b.hidden, dansK: b.parentNode === k, h: c.getBoundingClientRect().height, tactile: av ? [parseFloat(av.width), parseFloat(av.height)] : null,
    dansP: !!c.querySelector('p .vfa-compte'), p: [...c.querySelectorAll('p')].map((p) => p.textContent).join('|'), deborde: b.querySelector('span').getBoundingClientRect().right > c.getBoundingClientRect().right + 1 }; })())`;

export const mesuresT3 = {
  async t3(c) {
    const { s } = c, o = {}, lire = async (e) => JSON.parse(await s.ev(e));
    await c.vue(1440, 900); await c.charger('index.html'); await c.pousser(donnees()); await c.aller(DIR_A);
    // L13 : la marque de collision sur la route poussée (un mot par fichier, la prévue à gauche)
    o.mots = await lire(MOTS([`f:${'src/a/m05.js'}`, 'f:src/a/m06.js', `f:${PREVUE}`, 'f:src/a/m01.js']));
    o.prevue = await s.ev(`(() => { const p = VibeFlow.state.chipEls.get('f:${PREVUE}').querySelector('.foot'); return [p.firstElementChild.className, p.lastElementChild.className].join('|'); })()`);
    // L14 : sections du panneau d'un fichier
    await s.ev("VibeFlow.select('f:src/a/m01.js')"); await c.pause(500);
    o.fichier = await lire(SECTIONS);
    o.couplage = await lire(sec('couplage')); o.chaudsPanneau = await lire(sec('chauds')); o.gardes = await lire(sec('gardes')); o.agents = await lire(sec('agents'));
    o.rtl = await s.ev("getComputedStyle(document.querySelector('#panel .vfa-nom')).direction");
    await s.ev("VibeFlow.select('f:src/a/m14.js')"); await c.pause(400); o.vide = await lire(sec('couplage'));
    await s.ev("VibeFlow.select('f:src/a/m05.js')"); await c.pause(400); o.gardes5 = await lire(sec('gardes')); o.collisionFichier = await lire(sec('collisions'));
    await s.ev("VibeFlow.select('f:src/a/m04.js')"); await c.pause(400); o.fini = await lire(sec('agents'));
    await s.ev(`VibeFlow.select('f:${PREVUE}')`); await c.pause(400); o.collisionPrevue = await lire(sec('collisions'));
    await c.pousser(avec('git', (g) => ({ ...g, fenetre: { ...g.fenetre, partiel: true } }))); await s.ev("VibeFlow.select('f:src/a/m01.js')"); await c.pause(300); o.partiel = (await lire(sec('couplage'))).pieds[0];
    await c.pousser(donnees());
    await s.ev("VibeFlow.select('d:d-src|src/a')"); await c.pause(400); o.noeud = await lire(sec('collisions'));
    await c.pousser(donnees({ collisions: COLLISIONS(7), branches: { etat: 'ok', tetes: 14, plafond: 12, plafondAtteint: true } })); await s.ev("VibeFlow.select('d:d-src|src/a')"); await c.pause(300);
    o.noeud7 = await lire(sec('collisions'));
    await s.ev('VibeFlow.select(null)'); await c.aller('root'); await c.pousser(donnees({ collisions: COLLISIONS(12) })); await c.pause(300);
    o.racine = await lire(sec('collisions'));
    await c.pousser(donnees()); await c.aller(DIR_A);
    // L15 : le compte de la rangée .k, sans lentille
    o.compte = await lire(COMPTE);
    await c.pousser(donnees({ collisions: [], radar: { incomplet: false, raisons: [], total: 0 } })); await c.pause(200); o.compteZero = await lire(COMPTE);
    await c.pousser(donnees()); o.compteHauteur = [o.compte.h, (await lire(COMPTE)).h, o.compteZero.h];
    await c.pousser(donnees({ calcul: 'en-cours', etat: 'en-calcul', radar: { incomplet: true, raisons: ['en-construction'], total: 1 } })); await c.pause(200); o.compteRelecture = await lire(COMPTE);
    await c.pousser(donnees());
    o.largeurs = {};
    for (const [w, h] of [[1024, 768], [900, 700], [390, 844]]) { await c.vue(w, h, w < 500); await c.pause(500); o.largeurs[w] = await lire(COMPTE); }
    await c.pousser(donnees({ calcul: 'en-cours', radar: { incomplet: true, raisons: ['en-construction'], total: 1 } })); await c.pause(200); o.largeurs.relecture = await lire(COMPTE);
    await c.pousser(donnees());
    await c.vue(800, 700); await c.pause(500); await s.ev("if (document.body.classList.contains('no-panel')) document.getElementById('btn-panel').click()"); await c.pause(600);
    o.s18 = await lire(COMPTE);
    await c.vue(1440, 900); await c.pause(500);
    await s.ev("document.getElementById('context').style.maxWidth = '90px'; window.dispatchEvent(new Event('resize'))"); await c.pause(300);
    o.etroit = await lire(COMPTE); await s.ev("document.getElementById('context').style.maxWidth = ''; window.dispatchEvent(new Event('resize'))"); await c.pause(200);
    // L16 : l'ouverture du panneau depuis le compte ; la carte ne bouge pas ; le focus va au TITRE de la section
    await s.ev("VibeFlow.select(null)"); await c.pause(300);
    if (await s.ev("!document.body.classList.contains('no-panel')")) await s.ev("document.getElementById('btn-panel').click()");
    await c.pause(500);
    const r0 = await c.poser(), t0 = await s.ev("document.getElementById('viewport').style.transform");
    await s.ev("document.querySelector('#context .vfa-compte').click()"); await c.pause(500);
    o.ouverture = { ouvert: await s.ev("!document.body.classList.contains('no-panel')"), focus: await s.ev("(() => { const a = document.activeElement; return a && [a.tagName, a.dataset.vfaTitre, a.getAttribute('tabindex'), a.textContent].join('|'); })()"),
      cartes: (await c.poser()) === r0, vue: (await s.ev("document.getElementById('viewport').style.transform")) === t0 };
    await s.ev("VibeFlow.select('f:src/a/m01.js')"); await c.pause(400); await s.ev("document.querySelector('#context .vfa-compte').click()"); await c.pause(500);
    o.ouvertureSansCollision = { focus: await s.ev("(() => { const a = document.activeElement; return a && [a.tagName, a.dataset.vfaTitre].join('|'); })()"), titre: await s.ev("document.querySelector('#panel .pt') && document.querySelector('#panel .pt').textContent") };
    await s.ev('VibeFlow.select(null)'); await c.pause(300);
    // L16 : annonce à CHAQUE passage de 0 vers n (0, n, 0, n : deux annonces), jamais aux variations ni au retour à 0
    await s.ev(`window.__radar = []; const z = document.getElementById('ask-live'); new MutationObserver(() => { if (/^Radar/.test(z.textContent)) window.__radar.push(z.textContent); }).observe(z, { childList: true, characterData: true, subtree: true });`);
    const zero = donnees({ collisions: [], radar: { incomplet: false, raisons: [], total: 0 } });
    const lus = [];
    for (const d of [zero, donnees(), zero, donnees(), donnees({ collisions: COLLISIONS(4) }), zero]) { await c.pousser(d); lus.push(await s.ev('window.__radar.length')); }
    o.annonces = { suite: lus, textes: await lire('JSON.stringify(window.__radar)') };
    await c.pousser(donnees());
    // L17 : chaîne XSS (chemin, branche, rôle, titre hostiles) dans les tables, sections, compte et annonces
    o.xss = await mesuresT3.t3x(c, true);
    // L18 : `surOnglet` retire sections, compte et marques (jamais #ask-live) ; retour sur Code sans doublon
    await s.ev("VibeFlow.select('f:src/a/m01.js')"); await c.pause(300);
    o.avantQuitter = JSON.parse(await s.ev("JSON.stringify([document.querySelectorAll('#panel .vfa-sec').length, document.querySelectorAll('.vfa-compte').length, document.querySelectorAll('#viewport .lm').length])"));
    for (const onglet of ['projet', 'code']) {
      await s.ev(`VF_COQUILLE.chargerOnglet(${j(onglet)})`); await s.attendre(`VF_COQUILLE.onglet() === ${j(onglet)} && document.documentElement.dataset.vfPret === 'oui'`, onglet);
      if (onglet === 'code') await s.attendre("!!document.getElementById('btn-lentilles')", 'retour'); await c.pause(500);
      o[onglet] = JSON.parse(await s.ev("JSON.stringify([document.querySelectorAll('#panel .vfa-sec').length, document.querySelectorAll('.vfa-compte').length, document.querySelectorAll('#viewport .lm').length, !!document.getElementById('ask-live')])"));
    }
    await c.pousser(donnees()); await c.aller(DIR_A); await s.ev("VibeFlow.select('f:src/a/m05.js')"); await c.pause(500);
    o.retour = JSON.parse(await s.ev("JSON.stringify([document.querySelectorAll('#panel [data-vfa=collisions]').length, document.querySelectorAll('.vfa-compte').length, document.querySelectorAll('#panel [data-vfa=gardes]').length])"));
    return o;
  },
  // la chaîne XSS (aussi jouée seule : `t3x`, sur la copie mutée du module)
  async t3x(c, dedans = false) {
    const { s } = c, o = {};
    if (!dedans) { await c.vue(1440, 900); await c.charger('index.html'); }
    const NOMS = [HOSTILE, 'x'.repeat(5000), '__proto__', ' <script>window.__xss=1</script>'];
    const d = donnees({
      git: { ...donnees().git, chauds: [[FICHIER_HOSTILE, 3, 30, 1, 3], ...donnees().git.chauds], couplage: [[A(1), FICHIER_HOSTILE, 6, 90], ...donnees().git.couplage] },
      empreinte: { ...donnees().empreinte, marques: [[A(1), 'en-cours', [HOSTILE + ' · nœud ' + HOSTILE, NOMS[1]]], [A(2), 'modifie', [NOMS[2] + ' · nœud ' + NOMS[2]]],
      [A(3), 'lu', ['vf-coder · nœud <img src=x onerror=window.__xss=1>']]] },
      collisions: [[A(5), 'agents', NOMS, null], [A(5), 'branches', [HOSTILE, NOMS[3]], null], [A(6), 'arbres', [HOSTILE, '__proto__'], null], [FICHIER_HOSTILE, 'plans', [HOSTILE, NOMS[3]], 2]],
    });
    await c.pousser(d); await c.aller('d:d-src|src/b'); await c.pause(300);
    const avant = await s.ev("document.querySelectorAll('#viewport img, #viewport script, #panel img, #panel script, #lens-menu img, #lens-menu script, #context img, #context script').length");
    await c.lentille('empreinte'); await c.ouvrirMenu(); await s.ev(`document.querySelector('#lens-boite details.ag').open = true`); await c.pause(300);
    const menuAgents = await s.ev("[document.querySelectorAll('#lens-menu img, #lens-menu script').length, document.querySelectorAll('#lens-boite details.ag .lr').length]");
    await c.touche('Escape');
    await s.ev("VibeFlow.select('f:src/b/h<img src=x onerror=window.__xss=1>\"x.js')"); await c.pause(500);
    const hostileSel = await s.ev("document.getElementById('panel').textContent.includes('onerror=window.__xss=1')");
    await c.aller('d:d-src|src/a'); await s.ev("VibeFlow.select('f:src/a/m05.js')"); await c.pause(400);
    const a5 = await s.ev("document.getElementById('panel').textContent");
    await s.ev("VibeFlow.select('f:src/a/m01.js')"); await c.pause(400);
    const a1 = await s.ev("document.getElementById('panel').textContent");
    await c.lentille('chauds'); await c.lentille('gardes'); await c.lentille('aucune');
    Object.assign(o, { avant, apres: await s.ev("document.querySelectorAll('#viewport img, #viewport script, #panel img, #panel script, #lens-menu img, #lens-menu script, #context img, #context script').length"),
      menuAgents, xss: await s.ev('window.__xss === undefined'), litteral: [hostileSel, a5.includes(HOSTILE), a5.includes('x'.repeat(5000)), a5.includes('__proto__'), a1.includes('onerror=window.__xss=1')],
      proto: await s.ev("({}).polluted === undefined && Object.prototype.hasOwnProperty.call(Object.prototype, 'x') === false"),
      menu: await s.ev("document.getElementById('lens-menu').textContent.includes('onerror=window.__xss=1')") });
    return o;
  },
};
void j; void FICHIER_HOSTILE;
