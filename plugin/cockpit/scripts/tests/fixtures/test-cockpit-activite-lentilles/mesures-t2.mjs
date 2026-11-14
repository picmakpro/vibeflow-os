// mesures-t2.mjs — tâche 2 du plan 75-08 : le menu (structure, états, clavier, annonces), couplage, gardes, empreinte. Les données de route sont poussées par la page (aide `pousser`).
import { donnees, avec, A, B } from './donnees.mjs';
const j = JSON.stringify, DIR_A = 'd:d-src|src/a', NOEUD = 'n:d-src';
const LIGNES = `JSON.stringify([...document.querySelectorAll('#lens-boite .lr')].filter((r) => r.closest('[role=group]').getAttribute('aria-label') === 'Lentille')
  .map((r) => [r.dataset.id, r.querySelector('b').textContent, r.querySelector('.lt span').textContent, r.querySelector('.ln').textContent, r.getAttribute('aria-checked'), r.getAttribute('aria-disabled'),
    r.tabIndex, r.disabled, ((document.getElementById(r.getAttribute('aria-describedby') || 'x') || {}).textContent) || '']))`;
const TEXTES = `JSON.stringify({ legende: [...document.querySelectorAll('#lens-legende > .ll')].map((l) => l.textContent), limites: [...document.querySelectorAll('#lens-legende details.lim .ll')].map((l) => l.textContent),
  radar: document.getElementById('lens-radar').textContent, glyphes: [...document.querySelectorAll('#lens-legende .ll .lg')].map((g) => g.className.replace('lg lg-', '')),
  agents: [...document.querySelectorAll('#lens-boite details.ag .lr')].map((r) => [r.querySelector('b').textContent, r.getAttribute('aria-checked')]), agentsCaches: document.querySelector('#lens-boite details.ag').hidden })`;
const MARQUES = `JSON.stringify(Object.fromEntries([...VibeFlow.state.chipEls].map(([id, g]) => { const l = [...g.querySelectorAll('.foot .lm')].filter((x) => !x.querySelector('.lg-confluent')); const m = l[0];
  return [id, m ? [m.querySelector('.lw').textContent, m.querySelector('.lg').className.replace('lg lg-', '')] : null]; })))`;

export const mesuresT2 = {
  async t2(c) {
    const { s } = c, o = {};
    await c.vue(1440, 900); await c.charger('index.html');
    await c.pousser(donnees()); await c.aller(DIR_A);
    const lire = async (expr) => JSON.parse(await s.ev(expr));
    // L5 : structure du menu ; rien ne pousse la carte
    const rects0 = await c.poser();
    await c.ouvrirMenu();
    o.menu = await lire(`JSON.stringify((() => { const m = document.getElementById('lens-menu'), b = document.getElementById('lens-boite'), t = document.getElementById('lens-titre'), l = document.getElementById('lens-legende'), r = document.getElementById('lens-radar');
      return { roles: [...document.querySelectorAll('#lens-menu [role=menu]')].map((e) => e.id), groupes: [...m.querySelectorAll('[role=group]')].map((g) => g.getAttribute('aria-label')), titre: t.textContent,
        hors: [t, l, r].map((e) => !b.contains(e)), decrit: b.getAttribute('aria-describedby'), radios: b.querySelectorAll('[role=menuitemradio]').length, position: getComputedStyle(m).position, classe: m.className }; })())`);
    o.lignes = await lire(LIGNES); o.textes = await lire(TEXTES);
    o.rects = [rects0 === await c.poser()];
    // L6 : les états, un par un (la ligne, sa description, sa couleur ; la légende ; le radar)
    const CONTRASTE = `(() => { const sonde = (v) => { const e = document.createElement('i'); e.style.color = 'var(' + v + ')'; e.style.background = 'var(' + v + ')'; document.body.appendChild(e); const c = getComputedStyle(e).color; e.remove(); return c; };
      const rgb = (x) => x.match(/[\\d.]+/g).map(Number), lum = ([r, g, b]) => { const f = (v) => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }; return .2126 * f(r) + .7152 * f(g) + .0722 * f(b); };
      const ink = getComputedStyle(document.documentElement).getPropertyValue('--ink').split(',').map(Number), bg = rgb(sonde('--bg')), fond = bg.map((v, i) => v * .93 + ink[i] * .07), fg = rgb(sonde('--text-3'));
      const a = lum(fg), b = lum(fond); return { texte3: sonde('--text-3'), texte4: sonde('--text-4'), ratio: (Math.max(a, b) + .05) / (Math.min(a, b) + .05) }; })()`;
    o.couleur = await lire(`JSON.stringify(${CONTRASTE})`);
    const etat = async (nom, d) => { await c.pousser(d); await c.ouvrirMenu(); o[nom] = { lignes: await lire(LIGNES), ...(await lire(TEXTES)), couleurs: await lire(`JSON.stringify([...document.querySelectorAll('#lens-boite .lr')].filter((r) => r.getAttribute('aria-disabled') === 'true').map((r) => getComputedStyle(r.querySelector('b')).color))`) }; };
    await c.lentille('chauds'); await c.pousser(donnees());
    await etat('indispoActive', avec('git', { etat: 'indisponible' }));
    o.indispoActive.active = await s.ev('VF_MARQUES.active()'); o.indispoActive.coche = await s.ev("document.querySelector('#lens-boite .lr[data-id=chauds]').getAttribute('aria-checked')");
    const clic = await lire(`(async () => { const r = document.querySelector('#lens-boite .lr[data-id=chauds]'); const avant = document.querySelector('#lens-boite .lr[aria-checked=true]').dataset.id; r.click(); await new Promise((ok) => setTimeout(ok, 150));
      return JSON.stringify([avant, document.querySelector('#lens-boite .lr[aria-checked=true]').dataset.id, document.getElementById('lens-menu').classList.contains('open'), document.activeElement === r]); })()`);
    o.clicIndispo = clic;
    await c.pousser(donnees()); await c.lentille('aucune');
    await etat('gardesAbsentes', avec('gardes', { etat: 'non-lues', gardes: [], estGarde: [], prevusIgnores: 0 }));
    await etat('gitAbsent', avec('git', { etat: 'absent' }));
    await etat('gitVide', avec('git', { etat: 'vide', fenetre: { jours: 90 }, chauds: [], couplage: [], paliers: 1, tronque: false })); await c.lentille('chauds'); o.gitVide.legende = (await lire(TEXTES)).legende; await c.ouvrirMenu();
    await c.lentille('aucune');
    await etat('gitEnLecture', avec('git', { etat: 'en-lecture' }, { calcul: 'en-cours', etat: 'en-calcul' }));
    await etat('relecture', avec('empreinte', (e) => ({ ...e, etat: 'en-construction', incomplet: true }), { calcul: 'en-cours', radar: { incomplet: true, raisons: ['en-construction'], total: 0 }, collisions: [] }));
    await c.lentille('empreinte'); o.relecture.legende = (await lire(TEXTES)).legende; o.relecture.marques = await s.ev('VF_MARQUES.active()'); await c.ouvrirMenu();
    await etat('branches', avec('radar', { incomplet: true, raisons: ['branches-indisponible'], total: 0 }, { collisions: [] }));
    await etat('tronque', avec('radar', { incomplet: true, raisons: ['tronque'], total: 0 }, { collisions: [] }));
    await etat('coupees', avec('empreinte', (e) => ({ ...e, coupees: 2 }), { radar: { incomplet: true, raisons: ['cibles-coupees'], total: 0 }, collisions: [] }));
    await etat('complet', donnees({ collisions: [] }));
    await etat('limites', donnees());
    await c.lentille('aucune');
    // L6, connexion perdue : les marques d'Empreinte partent, Points chauds garde les siennes
    await c.pousser(donnees()); await c.lentille('empreinte'); await c.aller(DIR_A);
    o.perdue = { avant: await lire(MARQUES) };
    await s.ev("(() => { const e = window.__es.filter((x) => x.readyState !== 2).pop(); if (e && e.onerror) e.onerror({ type: 'error' }); })()");
    await s.attendre("window.VF_ETAT.lire('connexion') === 'perdu'", 'connexion perdue'); await c.pause(300);
    await c.ouvrirMenu(); Object.assign(o.perdue, { pendant: await lire(MARQUES), ...(await lire(TEXTES)), lignes: await lire(LIGNES), badge: await s.ev("(document.querySelector('#btn-lentilles .badge') || {}).textContent || ''") });
    await c.lentille('chauds'); await c.ouvrirMenu(); o.perdue.chauds = { ...(await lire(TEXTES)), marques: await lire(MARQUES) };
    await s.attendre("window.VF_ETAT.lire('connexion') === 'ouvert'", 'connexion rétablie', 40000).catch(() => {}); await c.lentille('aucune');
    // L8 : couplage (5 voisins au plus, dans la vue, aucun lien ajouté)
    const dc = avec('git', (g) => ({ ...g, couplage: [[A(1), A(2), 6, 100], [A(1), A(3), 5, 78], [A(1), A(4), 5, 55], [A(1), A(7), 5, 40], [A(1), B(1), 6, 60], [A(2), A(3), 5, 55]] }));
    await c.pousser(dc); await c.lentille('couplage'); await c.aller(DIR_A);
    const liens0 = await s.ev('VibeFlow.state.edgeEls.size'); const t0 = await lire(TEXTES);
    o.couplage = { attente: t0.legende, vide: await lire(MARQUES) };
    await s.ev("VibeFlow.select('f:src/a/m01.js')"); await c.pause(500);
    o.couplage.selection = await lire(MARQUES); o.couplage.legende = (await lire(TEXTES)).legende; o.couplage.liens = [liens0, await s.ev('VibeFlow.state.edgeEls.size')];
    await s.ev("VibeFlow.select('d:d-src|src/a')"); await c.pause(400); o.couplage.noeud = (await lire(TEXTES)).legende; o.couplage.noeudMarques = Object.values(await lire(MARQUES)).filter(Boolean).length;
    await s.ev('VibeFlow.select(null)'); await c.lentille('aucune');
    // L9 : gardes
    await c.pousser(donnees()); await c.lentille('gardes'); await c.aller(DIR_A);
    o.gardes = { fichiers: await lire(MARQUES), legende: (await lire(TEXTES)).legende };
    await c.aller(NOEUD); o.gardes.noeuds = await lire(MARQUES); await c.aller('n:d-scripts'); o.gardes.scripts = await lire(MARQUES);
    // L10 : empreinte, degrés, agrégat de nœud (une forme par degré maximal), filtre « Agents »
    await c.lentille('empreinte'); await c.aller(DIR_A);
    o.empreinte = { fichiers: await lire(MARQUES) }; await c.aller(NOEUD); o.empreinte.noeuds = await lire(MARQUES);
    await c.pousser(avec('empreinte', (e) => ({ ...e, marques: [[A(1), 'modifie', ['vf-coder']], [A(2), 'modifie', ['vf-coder']], [A(3), 'modifie', ['vf-coder']], [A(4), 'lu', ['vf-coder']], [A(5), 'lu', ['vf-coder']]] })));
    o.empreinte.agregat = await lire(MARQUES); await c.pousser(donnees());
    await c.ouvrirMenu(); o.empreinte.menu = await lire(TEXTES);
    const hauteur = await lire(`JSON.stringify((() => { const m = document.getElementById('lens-menu'), r = m.getBoundingClientRect(), hh = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--hh')) || 56;
      return { defile: m.scrollHeight > m.clientHeight, h: r.height, plafond: innerHeight - hh - 16, details: [document.querySelector('#lens-boite details.ag').open, document.querySelector('#lens-legende details.lim').open] }; })())`);
    o.hauteur = hauteur;
    await s.ev("document.querySelector('#lens-boite details.ag summary').focus()"); await c.touche('Enter');
    o.ouvreAuClavier = await s.ev("document.querySelector('#lens-boite details.ag').open");
    await c.aller(DIR_A);
    await s.ev("document.querySelector('#lens-boite .lr[data-agent=\"75-08\"]').focus()"); await c.touche('Enter');
    o.filtre = { coche: await s.ev("document.querySelector('#lens-boite .lr[data-agent=\"75-08\"]').getAttribute('aria-checked')"), ouvert: await s.ev("document.getElementById('lens-menu').classList.contains('open')"), marques: await lire(MARQUES),
      focus: await s.ev("document.activeElement && document.activeElement.dataset.agent") };
    await s.ev("document.querySelector('#lens-boite .lr[data-agent=\"\"]').focus()"); await c.touche(' ');
    o.filtre.tous = [await s.ev("document.querySelector('#lens-boite .lr[data-agent=\"\"]').getAttribute('aria-checked')"), Object.values(await lire(MARQUES)).filter(Boolean).length];
    await c.pousser(donnees({ empreinte: { ...donnees().empreinte, marques: [[A(1), 'en-cours', ['vf-coder · non rattaché']]] } })); await c.ouvrirMenu();
    o.sansRattachement = (await lire(TEXTES)).agentsCaches;
    await c.pousser(donnees()); await c.lentille('aucune');
    // L11 : annonces par #ask-live (jamais retirée), les mises à jour d'empreinte ne sont pas annoncées
    await s.ev(`window.__live = []; const z = document.getElementById('ask-live'); window.__zone = z; new MutationObserver(() => window.__live.push(z.textContent)).observe(z, { childList: true, characterData: true, subtree: true });`);
    for (const id of ['chauds', 'gardes', 'empreinte', 'couplage', 'aucune']) await c.lentille(id);
    await c.lentille('empreinte'); const n0 = await s.ev('window.__live.length');
    await c.pousser(avec('empreinte', (e) => ({ ...e, marques: [[A(2), 'en-cours', ['vf-coder · nœud 75-08']]] }))); await c.pause(300);
    o.annonces = { suite: await lire('JSON.stringify(window.__live)'), maj: [n0, await s.ev('window.__live.length')], meme: await s.ev("document.getElementById('ask-live') === window.__zone") };
    await c.lentille('chauds'); await c.pousser(avec('git', { etat: 'indisponible' })); await c.pause(300); o.annonces.indispo = (await lire('JSON.stringify(window.__live)')).slice(-1)[0];
    await c.pousser(donnees()); await c.lentille('couplage'); await c.aller(DIR_A); const l0 = await s.ev('window.__live.length');
    await s.ev("VibeFlow.select('f:src/a/m01.js')"); await c.pause(150); const l1 = await s.ev('window.__live.length'); await c.pause(450);
    o.annonces.couplage = [l1 - l0, (await lire('JSON.stringify(window.__live)')).slice(-1)[0]]; await s.ev('VibeFlow.select(null)'); await c.lentille('aucune');
    return o;
  },
  // L7 : le clavier du menu, au bureau puis à 900 px (ouvreur : le « ⋯ »)
  async t7(c) {
    const { s } = c, o = {};
    await c.vue(1440, 900); await c.charger('index.html'); await c.pousser(donnees()); await c.pousser(donnees());
    const foc = () => s.ev("document.activeElement && (document.activeElement.dataset.id || document.activeElement.id)");
    const ouvert = () => s.ev("document.getElementById('lens-menu').classList.contains('open')");
    await c.ouvrirMenu(); o.ouverture = [await foc(), await ouvert()];
    o.fleches = []; for (const k of ['ArrowDown', 'ArrowDown', 'ArrowDown', 'ArrowDown', 'ArrowDown', 'ArrowUp', 'Home', 'End']) { await c.touche(k); o.fleches.push(await foc()); }
    o.desactivee = await (async () => { await c.pousser(avec('git', { etat: 'indisponible' })); await c.ouvrirMenu(); await s.ev("document.querySelector('#lens-boite .lr[data-id=chauds]').focus()"); const f = await foc(); await c.touche('Enter');
      return [f, await ouvert(), await s.ev('VF_MARQUES.active()')]; })();
    await c.pousser(donnees()); await c.touche('Home'); await c.touche('ArrowDown'); await c.touche('Enter');
    o.entree = [await ouvert(), await s.ev("document.activeElement === document.getElementById('btn-lentilles')"), await s.ev('VF_MARQUES.active()')];
    await c.ouvrirMenu(); o.focusCoche = await foc(); await c.touche('ArrowDown'); await c.touche(' ');
    o.espace = [await ouvert(), await s.ev("document.activeElement === document.getElementById('btn-lentilles')"), await s.ev("document.querySelector('#btn-lentilles .bl').textContent")];
    await c.ouvrirMenu(); await c.touche('Escape'); o.echap = [await ouvert(), await s.ev("document.activeElement === document.getElementById('btn-lentilles')")];
    await c.ouvrirMenu(); await s.ev("document.getElementById('stage').click()"); await c.pause(150); o.dehors = await ouvert();
    await c.ouvrirMenu(); await s.ev("document.getElementById('filters-btn').click()"); await c.pause(200);
    o.legende = [await ouvert(), await s.ev("document.getElementById('legend').classList.contains('open')")];
    await s.ev("document.getElementById('btn-lentilles').click()"); await c.pause(200);
    o.reciproque = [await ouvert(), await s.ev("document.getElementById('legend').classList.contains('open')")];
    await c.touche('Escape'); await c.lentille('aucune'); await c.touche('Escape');
    // à 900 px : l'ouvreur est le « ⋯ »
    await c.vue(900, 700); await c.pause(400);
    const plus = async () => { await s.ev("document.getElementById('vf-plus').click()"); await c.pause(200); await s.ev("[...document.querySelectorAll('#vf-plus-menu .vf-pl-i')].find((b) => b.textContent.includes('Lentille')).click()"); await c.pause(250); };
    await plus(); o.tablette = { ouvert: await ouvert(), position: await s.ev("getComputedStyle(document.getElementById('lens-menu')).position"), focus: await foc() };
    await c.touche('Escape'); o.tablette.echap = [await ouvert(), await s.ev("document.activeElement === document.getElementById('vf-plus')")];
    await plus(); await c.touche('ArrowDown'); await c.touche('Enter');
    o.tablette.entree = [await ouvert(), await s.ev("document.activeElement === document.getElementById('vf-plus')"), await s.ev('VF_MARQUES.active()')];
    return o;
  },
};
void B;
