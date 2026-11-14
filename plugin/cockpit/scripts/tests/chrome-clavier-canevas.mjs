// chrome-clavier-canevas.mjs — mesures du clavier du canevas (80-01, FORM-01) dans un vrai Chrome headless, de vraies touches (Input.dispatchKeyEvent).
// Usage : node chrome-clavier-canevas.mjs <chrome> <racine-du-serveur>   Rend UNE ligne JSON { cc1 … cc62 } ou { erreur }. ?lang=en : libellés du moteur ; mode « fr » : le défaut français.
// Chaque section est isolée (sec) : une section qui échoue (module absent ou muté) laisse ses champs vides, les autres sont mesurées.
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv; // mode « cc7 » : seul le niveau à connecteurs, sur le lab à deux modules qui s'importent
const LANG = mode === 'fr' ? '' : '?lang=en'; // mode « fr » : le défaut (français), sans ?lang=en ; tous les autres modes : ?lang=en
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const POSEE = "(() => { const v = document.querySelector('#viewport'); return !!v && v.style.opacity !== '0' && !v.classList.contains('anim'); })()";
const OUTIL = `window.__cc = {
  idDe(g) { for (const [i, x] of VibeFlow.state.chipEls) if (x === g) return i; return null; },
  etat() {
    const a = document.activeElement, g = a && a.closest ? a.closest('g.node') : null, S = VibeFlow.state;
    return JSON.stringify({ id: g ? this.idDe(g) : null, tag: a ? a.tagName.toLowerCase() : '', stage: a === document.getElementById('stage'),
      sel: S.selected, c: S.container, t0: document.querySelectorAll('g.node[tabindex="0"]').length,
      sa: document.querySelectorAll('g.node[aria-selected="true"]').length, k: S.t.k });
  },
  lecture() { return VibeFlow.state.layout.children.slice().sort((a, b) => a.y - b.y || a.x - b.x).map((c) => c.id); },
  pos(id) { const c = VibeFlow.state.layout.children.find((x) => x.id === id); return c ? { x: c.x, y: c.y } : { x: null, y: null }; },
  actives() { return document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length; } }`;
const KEYS = { Tab: 9, ArrowRight: 39, ArrowLeft: 37, ArrowUp: 38, ArrowDown: 40, Home: 36, End: 35, Enter: 13, Space: 32, Escape: 27, Backspace: 8 };
const NOTE = (g) => `[...document.querySelectorAll('${g}')]`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }); // sans lui, requestAnimationFrame ne tourne pas (headless non focalisé)
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, mobile) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile });
  const touche = async (nom) => {
    const key = nom === 'Space' ? ' ' : nom;
    for (const type of ['keyDown', 'keyUp']) {
      await s.send('Input.dispatchKeyEvent', { type, key, code: nom, windowsVirtualKeyCode: KEYS[nom], nativeVirtualKeyCode: KEYS[nom] });
    }
  };
  const vide = { id: null, tag: '', stage: false, sel: null, c: null, t0: 0, sa: 0, k: 0 };
  const etat = async () => (await lire('__cc.etat()')) || vide;
  const lireVue = () => s.ev('JSON.stringify([VibeFlow.state.container, document.querySelectorAll("#viewport .node").length])');
  const niveau = async (id) => {
    await s.ev(`VibeFlow.go(${JSON.stringify(id)})`);
    await s.attendre(`VibeFlow.state.container === ${JSON.stringify(id)} && ${POSEE}`, `niveau ${id}`);
    await stabiliser(lireVue, { pas: 120, max: 5000 });
  };
  const charger = async (page, w = 1440, h = 900, mobile = false) => {
    await vue(w, h, mobile); await s.naviguer(`${racine}/${page}${LANG}`); await s.attendre(PRET, `page ${page}`);
    await s.attendre("!!document.querySelector('#viewport .node')", `cartes ${page}`); await s.attendre(POSEE, `vue posée ${page}`);
    await stabiliser(lireVue, { pas: 120, max: 5000 });
    await pause(1200); // la visite guidée du premier passage démarre après le chargement : Échap jusqu'à sa fermeture
    for (let i = 0; i < 5 && await s.ev('!!(window.VibeFlowTour && VibeFlowTour.active())'); i++) { await touche('Escape'); await pause(400); }
    await s.ev(OUTIL);
  };
  // vraies touches Tab depuis un départ posé avant l'en-tête ; rend les arrêts (dans #svg ou non, carte ou non)
  const ARRET = `(() => { const a = document.activeElement; if (!a || a === document.body) return JSON.stringify({ fin: true });
    const W = (window.__tn ||= new WeakMap()); if (!W.has(a)) W.set(a, (window.__tc = (window.__tc || 0) + 1));
    return JSON.stringify({ n: W.get(a), svg: !!a.closest('#svg'), g: a.matches('g.node') }); })()`;
  const tab = async (jusquauCanevas) => {
    await s.ev("(() => { document.activeElement && document.activeElement.blur(); const d = document.createElement('span');" +
      " d.id = 'vf-depart'; d.tabIndex = -1; document.body.prepend(d); d.focus(); })()");
    const arrets = [], vus = new Set();
    for (let i = 0; i < 90; i++) {
      await touche('Tab'); const a = await lire(ARRET);
      if (!a || a.fin || vus.has(a.n)) break;
      vus.add(a.n); arrets.push(a);
      if (jusquauCanevas && a.svg) break;
    }
    await s.ev("document.getElementById('vf-depart')?.remove()");
    return arrets;
  };
  const presser = async (nom, attendu = 250) => { await touche(nom); await pause(attendu); return etat(); };
  // premier rendu APRÈS un changement de niveau (un redessin en direct du même niveau ne compte pas)
  const ecouteRender = (champs) => s.ev(`window.__r = []; window.__c0 = VibeFlow.state.container;
    VibeFlow.on('render', () => window.__r.push({ c: VibeFlow.state.container, e: ${champs} }))`);
  const premierRender = async () => {
    await stabiliser(() => s.ev('window.__r.filter((r) => r.c !== window.__c0).length'), { pas: 300, max: 6000 });
    const r = await lire('JSON.stringify(window.__r.find((x) => x.c !== window.__c0) || null)');
    return r ? { c: r.c, e: JSON.parse(r.e) } : { c: null, e: vide };
  };

  if (mode === 'cc7') { // CC7 : un niveau à connecteurs (cartes x:) : options nommées d'après l'entité liée et la direction, jamais l'id interne
    o.cc7 = { x: [] }; await charger('index.html');
    await sec('cc7', async () => {
      await niveau('n:m-m1'); await pause(300);
      o.cc7 = await lire(`JSON.stringify({ x: [...VibeFlow.state.chipEls].filter(([i]) => i.startsWith('x:'))
        .map(([i, g]) => [i, g.getAttribute('role'), g.getAttribute('aria-label')]), n: VibeFlow.state.chipEls.size })`);
    });
    return o;
  }
  if (mode === 'fr') { // le défaut français : le nom de la listbox et ceux des cartes, lus dans le DOM (le texte du dictionnaire, pas la clé anglaise)
    await charger('index.html'); await niveau('n:unassigned');
    o.fr = await lire(`JSON.stringify({ listbox: document.getElementById('svg').getAttribute('aria-label'),
      noms: ${NOTE('g.node')}.map((g) => g.getAttribute('aria-label')) })`);
    return o;
  }
  // ---------- CC1, CC2 : Code, 1440 px, niveau « non classé » : 19 cartes, des liens, plusieurs couches ----------
  await charger('index.html'); await niveau('n:unassigned');
  o.cc1 = { arretsCanevas: 0, carte: false, arrets: 0, listbox: {}, mouv: {} }; o.cc2 = {}; o.cc22 = {};
  await sec('cc1', async () => {
    const tous = await tab(false), dansSvg = tous.filter((a) => a.svg);
    o.cc1 = { arretsCanevas: dansSvg.length, carte: dansSvg.every((a) => a.g) && dansSvg.length > 0, arrets: tous.length, mouv: {} };
    o.cc1.listbox = await lire("(() => { const e = document.getElementById('svg');" +
      " return JSON.stringify({ role: e.getAttribute('role'), nom: e.getAttribute('aria-label') }); })()");
    await tab(true); o.cc1.depart = await etat();
    for (const [nom, k] of [['droite', 'ArrowRight'], ['gauche', 'ArrowLeft'], ['bas', 'ArrowDown'], ['haut', 'ArrowUp']]) {
      const av = await etat(), ap = await presser(k);
      const [pde, pvers] = [await lire(`JSON.stringify(__cc.pos(${JSON.stringify(av.id)}))`), await lire(`JSON.stringify(__cc.pos(${JSON.stringify(ap.id)}))`)];
      o.cc1.mouv[nom] = { de: av.id, vers: ap.id, pde, pvers, t0: ap.t0, sel: ap.sel, sa: ap.sa };
    }
  });
  await sec('cc2', async () => { // CC2.1 : l'arbre d'accessibilité réel (Accessibility.getFullAXTree)
    await s.send('Accessibility.enable'); const ax = (await s.send('Accessibility.getFullAXTree')).nodes.filter((n) => !n.ignored);
    const nom = (n) => (n.name && n.name.value) || '', parNoeud = (i) => ax.find((n) => n.nodeId === i);
    const lb = ax.find((n) => n.role.value === 'listbox' && /^(Carte|Map)/.test(nom(n))), enf = lb ? lb.childIds.map(parNoeud).filter(Boolean) : [];
    o.cc2 = { listbox: lb ? nom(lb) : null, enfants: enf.map((n) => n.role.value),
      options: enf.filter((n) => n.role.value === 'option').map((n) => ({ nom: nom(n) })),
      ordre: await s.ev('__cc.lecture()'), decor: await s.ev(`${NOTE('#svg .edges, #svg .cols')}.map((e) => e.getAttribute('aria-hidden')).join()`),
      dom: await lire(`JSON.stringify(${NOTE('g.node')}.map((g) => [g.getAttribute('aria-label'),
        +g.getAttribute('aria-posinset'), +g.getAttribute('aria-setsize')]))`),
      titres: await lire(`JSON.stringify(${NOTE('g.node')}.map((g) => [__cc.idDe(g), (g.querySelector('.title') || { textContent: '' }).textContent.trim()]))`),
      xss: await lire(`JSON.stringify({ img: document.querySelectorAll('img[src=x]').length, flag: window.__xss === undefined,
        nom: ${NOTE('g.node')}.filter((g) => (g.getAttribute('aria-label') || '').includes('<img src=x')).length })`) };
  });
  await sec('cc22', async () => { // CC2.2 : Fin, Origine, extrémités (une flèche au bord ne bouge pas, aucune boucle)
    const lect = o.cc2.ordre, fin = await presser('End'), bas = await presser('ArrowDown'), deb = await presser('Home');
    const haut = await presser('ArrowUp'), gau = await presser('ArrowLeft');
    o.cc22 = { fin: [fin.id, lect[lect.length - 1]], debut: [deb.id, lect[0]], bas: [fin.id, bas.id], haut: [deb.id, haut.id, gau.id] };
  });
  o.cc21p = { examinees: 0, ecarts: 0 };
  await sec('cc21p', async () => { // CC2.1e : sur Projet, le mot d'état de la pastille est dans le nom de la carte
    await charger('project.html');
    for (let n = 0; n < 4 && !o.cc21p.examinees; n++) {
      const m = await lire(`JSON.stringify(${NOTE('g.node')}.filter((g) => g.querySelector('.vst'))
        .map((g) => [g.getAttribute('aria-label') || '', g.querySelector('.vst').textContent.trim()]))`);
      o.cc21p.examinees += m.length; o.cc21p.ecarts += m.filter(([nom, mot]) => !nom.includes(`, ${mot}`)).length;
      const f = await s.ev('VibeFlow.state.layout.children.map((x) => x.id).find((i) => VibeFlow.children(i).length) || null');
      if (o.cc21p.examinees || !f) break; await niveau(f);
    }
  });

  // ---------- CC3 : panneau latéral, redessin, tiroir Git ----------
  await charger('index.html'); await niveau('n:unassigned'); await tab(true); o.cc31 = {}; o.cc33 = {}; o.cc34 = { disjoints: false, k: [0, 1] };
  await sec('cc31', async () => { // CC3.1 : la sélection suit le focus ; Échap désélectionne ; Espace resélectionne
    await presser('Home'); const a1 = await presser('ArrowRight'), e1 = await presser('Escape'), sp = await presser('Space');
    o.cc31 = { suit: [a1.sel === a1.id && a1.id !== null, a1.sa], echap: [e1.sel, e1.id === a1.id, e1.sa], espace: [sp.sel === a1.id, sp.sa] };
    await s.ev('window.__rd = 0; VibeFlow.on("render", () => { window.__rd++; })'); // CC3.3 : un redessin recrée les cartes
    await s.ev('VibeFlow.render()'); await s.attendre('window.__rd > 0', 'redessin'); await stabiliser(lireVue, { pas: 120, max: 3000 });
    const r3 = await etat(); o.cc33 = { avant: sp.id, apres: r3.id, t0: r3.t0 };
  });
  o.cc8 = {};
  await sec('cc8', async () => { // CC8 : le focus est ailleurs (champ de question) : un redessin ne le vole pas
    await s.ev("document.getElementById('ask-input').focus()");
    const av = await s.ev('document.activeElement.id');
    await s.ev('window.__rd = 0'); await s.ev('VibeFlow.render()'); await s.attendre('window.__rd > 0', 'redessin (focus ailleurs)');
    await stabiliser(lireVue, { pas: 120, max: 3000 }); o.cc8 = { avant: av, apres: await s.ev('document.activeElement.id') };
  });
  await sec('cc34', async () => { // CC3.4 : tiroir Git ouvert : la carte focalisée est ramenée hors de lui, zoom inchangé
    await s.ev('VFGitTiroir.ouvrir()'); await s.attendre('VFGitTiroir.ouvert()', 'tiroir Git ouvert');
    await stabiliser(() => s.ev("document.getElementById('vf-git-tiroir').getBoundingClientRect().right"), { pas: 150, max: 4000 });
    await tab(true); await presser('Home');
    const dr = await presser('ArrowRight'); // la carte de droite est ensuite placée sous le tiroir
    const pd = await lire(`JSON.stringify(__cc.pos(${JSON.stringify(dr.id)}))`);
    await s.ev(`(() => { const S = VibeFlow.state, k = S.t.k, x = 120 - ${pd.x} * k; S.t = { k, x, y: S.t.y };
      document.getElementById('viewport').style.transform = 'translate(' + x + 'px,' + S.t.y + 'px) scale(' + k + ')'; })()`);
    const k0 = (await etat()).k, ga = await presser('ArrowLeft', 400);
    o.cc34 = await lire(`JSON.stringify((() => { try { const g = VibeFlow.state.chipEls.get(__cc.idDe(document.activeElement));
      const c = g.querySelector('.card').getBoundingClientRect(), t = document.getElementById('vf-git-tiroir').getBoundingClientRect();
      return { gauche: c.left, droit: t.right, disjoints: c.left >= t.right || c.right <= t.left || c.bottom <= t.top || c.top >= t.bottom };
      } catch (e) { return { disjoints: false, gauche: 0, droit: 0 }; } })())`);
    o.cc34.k = [k0, ga.k]; o.cc34.id = ga.id; await s.ev('VFGitTiroir.fermer()'); await pause(300);
  });

  // ---------- CC3.2, CC3.5 : plongée, remontée, niveau sans carte (racine : trois cartes en colonne) ----------
  o.cc32 = { remonte: {} }; o.cc35 = { Backspace: {}, Escape: {} };
  await sec('cc32', async () => {
    await niveau('root'); await tab(true); await presser('Home'); await ecouteRender('__cc.etat()');
    const r0 = await etat(); await touche('Enter'); const rr = await premierRender(); await pause(500);
    o.cc32 = { de: r0.id, niveau: rr.c, auRender: rr.e.id, premier: await s.ev('__cc.lecture()[0]'), apres: (await etat()).id };
    for (let i = 0; i < 3 && (await etat()).c !== 'root'; i++) { await touche('Escape'); await pause(700); }
    const re = await etat(); o.cc32.remonte = { c: re.c, id: re.id, tag: re.tag };
  });
  for (const retour of ['Backspace', 'Escape']) {
    await sec('cc35' + retour, async () => {
      await niveau('root'); await tab(true); await presser('Home'); await presser('ArrowDown'); // focus sur la carte du module sans fichier
      const f = await etat(); await ecouteRender('__cc.etat()'); await s.ev("VibeFlow.go('n:m-vide')"); const rv = await premierRender(); await pause(500);
      const live = await s.ev("(document.getElementById('vf-canevas-live') || { textContent: null }).textContent");
      const v = await lire("JSON.stringify({ vide: document.querySelector('#empty').textContent," +
        " ti: document.getElementById('stage').getAttribute('tabindex')," +
        " role: document.getElementById('svg').getAttribute('role'), nomSvg: document.getElementById('svg').getAttribute('aria-label') })");
      await touche(retour); await s.attendre("VibeFlow.state.container === 'root'", 'remontée du niveau vide'); await pause(700);
      const b = await etat();
      o.cc35[retour] = { focus: f.id, c: rv.c, stage: rv.e.stage, tag: rv.e.tag, live, vide: v.vide, ti: v.ti,
        role: v.role, nomSvg: v.nomSvg, retour: [b.c, b.id, b.tag] };
    });
  }

  // ---------- CC6 : anneau sur la .card (deux thèmes), clic sans anneau ----------
  o.cc6 = { sombre: {}, clair: {}, clic: {}, fleche: false };
  await sec('cc6', async () => {
    await niveau('n:unassigned'); await tab(true); await presser('ArrowRight');
    const anneau = async (th) => { // les transitions de la carte sont finies après 600 ms
      await s.ev(`document.documentElement.setAttribute('data-theme', '${th}')`); await pause(600);
      return lire(`(() => { const p = document.createElement('i'); p.style.color = 'var(--ring)'; p.style.boxShadow = 'var(--shadow-card)';
      document.body.appendChild(p); const ring = getComputedStyle(p).color, repos = getComputedStyle(p).boxShadow; p.remove();
      const g = document.activeElement, k = getComputedStyle(g.querySelector('.card'));
      return JSON.stringify({ l: k.outlineWidth, st: k.outlineStyle, couleur: k.outlineColor, ring,
        gOutline: getComputedStyle(g).outlineStyle, ombre: k.boxShadow, repos }); })()`); };
    o.cc6 = { sombre: await anneau('dark'), clair: await anneau('light') };
    const c = await lire("(() => { const r = document.querySelectorAll('.card')[1].getBoundingClientRect();" +
      " return JSON.stringify({ x: r.x + r.width / 2, y: r.y + r.height / 2 }); })()");
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: c.x, y: c.y, button: 'left', clickCount: 1 });
    await pause(300);
    o.cc6.clic = await lire(`JSON.stringify({ focus: !!document.activeElement.closest('g.node'), contours: document.querySelectorAll('.card').length &&
      ${NOTE('.card')}.filter((c) => getComputedStyle(c).outlineStyle !== 'none' && parseFloat(getComputedStyle(c).outlineWidth) > 0
        && !c.closest('.flash')).length })`);
    await presser('ArrowLeft'); o.cc6.fleche = (await etat()).id !== null;
  });

  // ---------- CC4 : feuille de détail (390 px tactile, puis 800 px pointeur fin) ----------
  o.cc4 = {};
  for (const [cle, w, h, tactile] of [['tactile', 390, 844, true], ['moyen', 800, 900, false]]) {
    await sec('cc4' + cle, async () => {
      await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile }); await charger('index.html', w, h, tactile); await niveau('n:unassigned');
      await tab(true); const av = await etat(), fl = await presser('ArrowRight'), sp = await presser('Space', 400);
      const np = await s.ev("document.body.classList.contains('no-panel')");
      const feuille = await s.ev("matchMedia('(max-width: 999px), (pointer: coarse)').matches");
      await niveau('root'); await tab(true); await presser('Home'); await ecouteRender('1'); await touche('Enter'); await premierRender(); await pause(500);
      o.cc4[cle] = { feuille, depart: av.id, fleche: [fl.id !== av.id, fl.sel], espace: [sp.sel === fl.id, np], plonge: (await etat()).c };
    });
  }
  await s.send('Emulation.setTouchEmulationEnabled', { enabled: false });

  // ---------- CC5 : Équipe : ni rôle ni tabindex ----------
  o.cc5 = null;
  await sec('cc5', async () => {
    // 73-08 : Équipe n'a plus de canevas ni de cartes ; sa liste est la régie (#vf-equipe). Le témoin est la régie posée ; la propriété reste : ni tabindex ni role=option posés
    // par le clavier du canevas (sur les cartes, #svg, #stage), pas de listbox ; la régie gère elle-même son clavier (EK)
    await vue(1440, 900, false); await s.naviguer(`${racine}/equipe.html${LANG}`); await s.attendre(PRET, 'page equipe.html');
    await s.attendre("!!document.getElementById('vf-equipe')", 'régie de l\'onglet Équipe'); await pause(1200);
    for (let i = 0; i < 5 && await s.ev('!!(window.VibeFlowTour && VibeFlowTour.active())'); i++) { await touche('Escape'); await pause(400); }
    o.cc5 = await lire(`JSON.stringify({ cartes: document.querySelectorAll('#vf-equipe').length, tab: document.querySelectorAll('g.node[tabindex]').length,
      opt: document.querySelectorAll('[role=option]').length, lb: document.getElementById('svg').getAttribute('role'),
      svgTab: document.getElementById('svg').getAttribute('tabindex'), canevas: typeof window.VF_CANEVAS,
      stageTab: document.getElementById('stage').getAttribute('tabindex') })`);
  });

  // ---------- CC6.2 : mouvement réduit : aucune animation active après flèche, plongée et remontée ; focus posé au rendu ----------
  o.cc62 = {};
  await sec('cc62', async () => {
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    await charger('index.html'); await tab(true); await ecouteRender('__cc.etat()');
    await presser('ArrowDown'); const a1 = await s.ev('__cc.actives()');
    await presser('Home'); await touche('Enter'); const rm = await premierRender(); await pause(100);
    const a2 = await s.ev('__cc.actives()');
    for (let i = 0; i < 3 && (await etat()).c !== 'root'; i++) { await touche('Escape'); await pause(500); }
    await pause(300); o.cc62 = { fleche: a1, plongee: a2, remontee: await s.ev('__cc.actives()'), auRender: rm.e.id !== null, racine: (await etat()).c };
  });
  return o;
});
