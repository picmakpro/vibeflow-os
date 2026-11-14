// chrome-palette.mjs — la palette de commandes (80-14, FORM-04, P80-D-11/14/55), un vrai Chrome, sans réseau.
// Usage : node chrome-palette.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { pa1, pa2, pa3, erreurs } ou { erreur }.
// Modes : base (lab sans --terminal) · term (lab --terminal : la ligne du terminal, PA2.8). Chaque section est isolée (sec).
// Les gestes passent par Input.dispatchKeyEvent et Input.insertText ; le réseau par CDP Network (aucune requête d'une action).
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SEL = 'f:src/n05.js';
const KEYS = { Enter: ['Enter', 13], Escape: ['Escape', 27], '/': ['Slash', 191], ArrowDown: ['ArrowDown', 40], '>': ['Period', 190] };
const HUIT = ["Ajuster à l'écran", 'Cadrer la sélection et ses voisins', "Monter d'un niveau", 'Afficher ou masquer le détail', 'Zoom avant', 'Zoom arrière',
  "Ouvrir l'historique Git", 'Afficher les raccourcis'];
const TERMINAL = "Le terminal s'active avec --terminal";
// who de fixture : le mandat et le titre ne doivent jamais s'afficher (P69-D-16)
// T-80-29 : un nom de phase, un rôle d'agent et un libellé d'extension hostiles doivent s'afficher en texte
const HOSTILE = '<img src=x onerror=window.__p=1>';
const WHO = [{ kind: 'subagent', id: 'a1b2c3d4e5f6', role: 'vf-coder', tree: 't', source: 'registered', task: 'MANDAT-SECRET', titre: 'TITRE-SECRET' },
  { kind: 'subagent', id: 'f0e1d2c3b4a5', role: HOSTILE, tree: 't', source: 'registered' }];

await executer(chrome, async (s) => {
  const o = { erreurs: {}, pa1: {}, pa2: {}, pa3: {} }, reqs = [];
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }); await s.send('Network.enable');
  s.ecouter('Network.requestWillBeSent', (p) => reqs.push({ m: p.request.method, u: new URL(p.request.url).pathname, t: p.type }));
  const sec = async (nom, f) => { if (process.env.PA_SEC && !process.env.PA_SEC.split(',').includes(nom)) return; try { await f();
      } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(`JSON.stringify(${expr})`); return v === undefined ? null : JSON.parse(v); };
  const vue = (w, h, mobile) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile });
  const touche = async (key, mod = 0) => {
    const [code, vk] = KEYS[key] || [key, key.toUpperCase().charCodeAt(0)], text = key.length === 1 ? key : undefined;
    for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, text: type === 'keyDown' ? text : undefined,
      modifiers: mod, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk });
  };
  const sansVisite = async () => {
    await pause(1200);
    for (let i = 0; i < 5 && await s.ev('!!(window.VibeFlowTour && VibeFlowTour.active())'); i++) { await touche('Escape'); await pause(400); }
  };
  const charger = async (page, w = 1440, h = 900, mobile = false) => {
    await vue(w, h, mobile); await s.naviguer(`${racine}/${page}`); await s.attendre(PRET, `page ${page}`);
    await s.attendre("!!document.querySelector('#viewport .node, .vp-couloirs, .vp-liste')", `cartes ${page}`); await sansVisite();
  };
  const choisir = async () => { await s.ev(`VibeFlow.reveal(${JSON.stringify(SEL)}); VibeFlow.fit(false); VibeFlow.select(${JSON.stringify(SEL)})`);
      await pause(900); };
  const lignes = () => lire(`[...document.querySelectorAll('#results .r')].map((r) => ({ lib: r.querySelector('.rn').textContent.trim(),
    kbd: [...r.querySelectorAll('.kbd')].map((k) => k.textContent), h: Math.round(r.getBoundingClientRect().height) }))`);
  const poser = async (texte) => { // ouvre la palette (« / »), tape, attend que la liste soit posée
    await touche('/'); await s.attendre("document.getElementById('palette').classList.contains('open') && document.activeElement.id === 'search'",
        'palette ouverte');
    if (texte) await s.send('Input.insertText', { text: texte });
    await stabiliser(() => s.ev("document.getElementById('results').innerHTML.length"), { pas: 150, max: 4000 });
  };
  const fermee = () => s.ev("!document.getElementById('palette').classList.contains('open')");
  const onglet = async (nom) => { await s.ev(`VF_ONGLETS.aller(${JSON.stringify(nom)})`);
      await s.attendre(`VF_ONGLETS.courant() === ${JSON.stringify(nom)} && ${PRET}`, `onglet ${nom}`); await pause(700); };
  const envoi = (depuis) => reqs.slice(depuis).filter((r) => r.m === 'POST' || (r.u.startsWith('/api/') && !r.u.startsWith('/api/vf/'))).length;
  // le magasin est lu à la saisie par `window.VF_ETAT` : un `who` de fixture, le reste du magasin réel
  const aide = () => s.ev(`(() => { const r = window.VF_ETAT, H = ${JSON.stringify(HOSTILE)}; window.__etat0 = r; window.VF_ETAT = Object.freeze({ ...r,
      lire: (c) => { const v = r.lire(c); if (c === 'who') return { workers: ${JSON.stringify(WHO)} };
        return c === 'etat' && v && v.signal ? { ...v, signal: { ...v.signal, phases: [...v.signal.phases, { key: 'x|9', n: '9', ws: null,
            nom: H }] } } : v; } });
      return 1; })()`);
  const choisirLigne = async (lib) => { // flèches puis Entrée sur la rangée de ce libellé
    const i = (await lignes()).findIndex((l) => l.lib === lib); if (i < 0) throw new Error(`rangée absente : ${lib}`);
    for (let k = 0; k < i; k++) await touche('ArrowDown'); await touche('Enter');
  };

  if (mode === 'term') {
    await sec('pa28t', async () => {
      await charger('index.html'); await s.ev("document.getElementById('btn-panel').focus()");
      const avant = await lire("document.querySelectorAll('iframe,[class*=\"vf-term\"],[data-vf-flottant]').length"), n0 = reqs.length;
      await poser('terminal'); o.pa2.termAvec = { lignes: await lignes(), avant };
      await touche('Escape'); await pause(300);
      o.pa2.termAvec.apres = await lire("document.querySelectorAll('iframe,[class*=\"vf-term\"],[data-vf-flottant]').length");
          o.pa2.termAvec.requetes = reqs.length - n0;
    });
    return o;
  }

  await sec('pa1', async () => { // PA1.1 : « >git » ouvre l'historique Git sans rien envoyer ; PA1.2 : rôles ARIA et aria-activedescendant
    await charger('index.html'); await choisir(); const n0 = reqs.length;
    await poser('>git'); o.pa1.lignes = await lignes();
    await touche('Enter'); await s.attendre('VFGitTiroir.ouvert()', 'tiroir Git'); await pause(500);
    o.pa1.git = await lire(`({ ferme: ${await fermee()}, foc: document.activeElement.className, envoi: ${envoi(n0)} })`);
    await s.ev('VFGitTiroir.fermer()'); await pause(300);
    await poser('');
    o.pa1.aria = await lire(`(() => { const b = document.querySelector('#palette .box'), i = document.getElementById('search'),
        a0 = i.getAttribute('aria-activedescendant');
      return { dialog: b.getAttribute('role'), modal: b.getAttribute('aria-modal'), nom: b.getAttribute('aria-label'), combo: i.getAttribute('role'),
        etendu: i.getAttribute('aria-expanded'), ctrl: i.getAttribute('aria-controls'), liste: document.getElementById('results').getAttribute('role'), a0,
        option: !!a0 && document.getElementById(a0).getAttribute('role') === 'option', groupes: document.querySelectorAll('#results [role=group]').length };
            })()`);
    await touche('ArrowDown');
    o.pa1.aria.a1 = await lire("(() => { const a = document.getElementById('search').getAttribute('aria-activedescendant'); " +
      "return [a, document.getElementById(a).classList.contains('active')]; })()");
    await touche('Escape');
  });

  await sec('pa2', async () => {
    await charger('index.html'); await choisir(); await s.ev("document.getElementById('btn-panel').focus()");
    await poser(''); const vide = await lignes(); o.pa2.vide = { libs: vide.map((l) => l.lib).slice(0, 10), plus: vide.length, kbd: vide.slice(0,
        8).map((l) => l.kbd.join('+')),
      titres: await lire("[...document.querySelectorAll('#results .gt:not([hidden])')].map((g) => g.textContent)"),
      texte: await s.ev("document.getElementById('palette').innerText") }; await touche('Escape');
    await poser('>'); o.pa2.actions = { libs: (await lignes()).map((l) => l.lib),
        titres: await lire("document.querySelectorAll('#results .gt:not([hidden])').length"),
      pastille: await lire("(() => { const p = document.getElementById('pal-mode'); return [p.hidden, p.textContent.trim()]; })()"),
      grises: await lire("document.querySelectorAll('#results [aria-disabled=true], #results [disabled]').length") };
    await touche('Escape'); await s.ev('VibeFlow.select(null)'); await pause(300); await poser('>cadrer');
    o.pa2.sansSel = (await lignes()).map((l) => l.lib); await touche('Escape'); await choisir();
    // PA2.8 : sans --terminal, la ligne d'information
    await s.ev("document.getElementById('btn-panel').focus()"); const n8 = reqs.length;
    const noeuds = "document.querySelectorAll('iframe,[class*=\"vf-term\"],[data-vf-flottant]').length", a8 = await lire(noeuds);
    await poser('terminal'); const l1 = await lignes(); await touche('Escape'); await poser('>terminal'); const l2 = await lignes();
    await touche('Enter'); await pause(400);
    o.pa2.terminal = { l1, l2, ferme: await fermee(), foc: await s.ev('document.activeElement.id'), requetes: reqs.length - n8, noeuds: [a8,
        await lire(noeuds)] };
    // PA2.3 : copier le lien (le presse-papiers est observé à l'écriture : l'adresse complète) ; PA2.4 : poser une question sans rien envoyer
    await s.ev("document.getElementById('btn-panel').focus(); window.__ecrit = []; " +
      "navigator.clipboard.writeText = (x) => { window.__ecrit.push(x); return Promise.resolve(); }");
    await poser('>copier le lien'); await touche('Enter'); await s.attendre("document.getElementById('toast').classList.contains('on')", 'toast');
    o.pa2.lien = await lire("({ ecrit: window.__ecrit, href: location.href, " +
      "toast: document.getElementById('toast').textContent, foc: document.activeElement.id })");
    await s.ev("navigator.clipboard.writeText = () => Promise.reject(new Error('refus')); document.getElementById('toast').classList.remove('on')");
    await poser('>copier le lien'); await touche('Enter'); await pause(500);
    o.pa2.lienKo = await s.ev("document.getElementById('toast').textContent");
    const n4 = reqs.length; await poser('>poser une question'); await touche('Enter'); await pause(500);
    o.pa2.question = await lire(`({ foc: document.activeElement.id, valeur: document.activeElement.value, envoi: ${envoi(n4)} })`);
    await s.ev("document.activeElement.blur()"); await poser(">poser une question à l'agent pourquoi"); await touche('Enter'); await pause(300);
    o.pa2.questionTexte = await s.ev('document.activeElement.value'); await s.ev('document.activeElement.blur()');
    // PA2.6 : le focus propre à chaque action
    o.pa2.focus = {};
    for (const [cle, lib] of [['ajuster', "Ajuster à l'écran"], ['zoom', 'Zoom avant'], ['detail', 'Afficher ou masquer le détail']]) {
      await choisir(); await poser('>' + lib); await touche('Enter'); await pause(500);
      o.pa2.focus[cle] = await lire(`(() => { const id = VF_CANEVAS.carteItinerante(), a = document.activeElement;
        return [a.id, !!id && a === VibeFlow.state.chipEls.get(id)]; })()`);
    }
    await choisir(); await poser("Monter d'un niveau"); await touche('Enter');
    o.pa2.focus.monter = await attendreValeur(() => lire(`(() => { const id = VF_CANEVAS.carteItinerante();
        return !!id && document.activeElement === VibeFlow.state.chipEls.get(id); })()`),
      (v) => v === true, { max: 4000 });
    // PA2.5 : changer d'onglet sans recharger ; sur Équipe, la pile de Retour de Projet n'existe plus
    const t0 = await s.ev('performance.timeOrigin'); await poser('>'); await touche('Escape'); await poser('Aller à Projet'); await touche('Enter');
    await s.attendre(`VF_ONGLETS.courant() === 'projet' && ${PRET}`, 'Projet'); await pause(800);
    o.pa2.projet = await lire(`({ memeFenetre: performance.timeOrigin === ${t0}, foc: document.activeElement.tagName })`);
    await s.ev("VF_PANNEAU.empiler({ titre: 'x', rouvrir: () => {} })"); const taille = await s.ev('VF_PANNEAU.taille()');
    await poser('Aller à Équipe'); await touche('Enter'); await s.attendre(`VF_ONGLETS.courant() === 'equipe' && ${PRET}`, 'Équipe'); await pause(800);
    o.pa2.equipe = await lire(`({ taille: ${taille}, pile: window.VF_PANNEAU ? VF_PANNEAU.taille() : 'absent' })`);
  });

  await sec('pa2b', async () => { // PA2.2 sur Projet : « Basculer couloirs, liste, graphe » présente
    await charger('project.html'); await poser('>'); o.pa2.projetActions = (await lignes()).map((l) => l.lib); await touche('Escape');
  });

  await sec('pa3', async () => { // PA3.1 à PA3.3 : phases et agents par le magasin, état vide, requête hostile
    await charger('index.html'); await aide();
        await s.attendre("!!(VF_ETAT.lire('etat') && VF_ETAT.lire('etat').signal && VF_ETAT.lire('etat').signal.phases.length)", 'phases du magasin');
    const t0 = await s.ev('performance.timeOrigin'), n0 = reqs.length;
    await poser('socle'); const l = await lignes(); o.pa3.phases = { l,
        groupes: await lire("[...document.querySelectorAll('#results .gt')].map((g) => g.textContent)"), requetes: reqs.length - n0 };
    await choisirLigne('Phase 1 · Socle'); await s.attendre(`VF_ONGLETS.courant() === 'projet' && ${PRET}`, 'Projet'); await pause(900);
    o.pa3.phases.arrivee = await lire(`({ memeFenetre: performance.timeOrigin === ${t0}, sel: VibeFlow.state.selected })`);
    await poser('coder'); const n1 = reqs.length; o.pa3.agents = { l: await lignes(), requetes: reqs.length - n1,
        texte: await s.ev("document.getElementById('results').innerText") };
    await touche('Escape');
    await poser('zzz'); await pause(700);
    o.pa3.vide = await lire("({ en: document.querySelector('#results .en').textContent, " +
      "ed: document.querySelector('#results .ed').textContent, " +
      "live: document.getElementById('pal-live').textContent })");
    await s.ev("document.getElementById('search').select()");
    await s.send('Input.insertText', { text: '<img src=zz onerror=window.__p=1>' }); await pause(500);
    o.pa3.hostile = await lire("({ p: typeof window.__p, img: document.querySelectorAll('#results img').length, " +
      "texte: document.querySelector('#results .en').textContent })");
    await touche('Escape');
  });

  await sec('pa34', async () => { // PA3.4 : 390 px au doigt (44, pied masqué), 800 px à la souris (36, pied visible)
    const forme = async (w, h, doigt) => {
      await s.send('Emulation.setTouchEmulationEnabled', { enabled: doigt }); await charger('index.html', w, h, doigt); await poser('>');
      return lire(`({ grossier: matchMedia('(pointer: coarse)').matches,
          h: [...new Set([...document.querySelectorAll('#results .r')].map((r) => Math.round(r.getBoundingClientRect().height)))],
        pied: getComputedStyle(document.querySelector('#palette .hint > span')).display })`);
    };
    o.pa3.tactile = await forme(390, 844, true); o.pa3.moyen = await forme(800, 900, false);
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: false });
  });

  await sec('pa35', async () => { // PA3.5 : les fichiers sont chargés, aucune action en double après deux allers-retours d'onglet
    await charger('index.html'); await onglet('projet'); await onglet('code'); await onglet('projet'); await onglet('code'); await choisir();
    o.pa3.ressources = await lire("['/_vf/ui/07-vf-raccourcis.js', '/_vf/ui/79-vf-fr-dict-c.js'].map((c) => " +
      "performance.getEntriesByType('resource').some((r) => new URL(r.name).pathname === c))");
    await poser(''); const v = (await lignes()).map((x) => x.lib); await touche('Escape'); await poser('terminal');
        const t = (await lignes()).map((x) => x.lib);
    o.pa3.doubles = { huit: HUIT.map((x) => v.filter((y) => y === x).length), terminal: t.filter((x) => x === TERMINAL).length };
  });
  await sec('pa4', async () => { // M3 : ajouter() valide ou neutralise, retrait, deux allers-retours ; M4 : texte hostile de phase, d'agent, d'extension
    // (les allers-retours d'onglet passent AVANT la première ouverture de la palette : constat de ce plan, une palette ouverte puis fermée avant
    // VF_ONGLETS.aller laisse la promesse sans réponse, y compris sur la tête d'avant ce plan : hors périmètre)
    await charger('index.html');
    const A = (e) => `(window.__r = window.__r || {}, window.__r[${JSON.stringify(e.id || 'x')}] = VF_RACCOURCIS.ajouter({ ...${JSON.stringify(e)},
        action: () => {} }))`;
    const base = { onglets: ['code'], palette: true }, libs = async () => (await lignes()).map((l) => l.lib);
    await s.ev(A({ ...base, id: 'e-quitte', libelle: 'Autre action' }));
    for (const n of ['projet', 'code', 'projet', 'code']) await onglet(n);
    await poser('>'); const apres = await libs(); await touche('Escape');
    o.pa4 = { apres: { zoom: apres.filter((x) => x === 'Zoom avant').length, autre: apres.filter((x) => x === 'Autre action').length } };
    await aide(); await s.attendre("!!(VF_ETAT.lire('etat').signal && VF_ETAT.lire('etat').signal.phases.length)", 'phases');
    await s.ev("window.__ce = []; console.error = (...a) => window.__ce.push(a.join(' ')); 1");
    for (const e of [{ ...base, id: 'e-ok', libelle: 'Mon action' }, { ...base, id: 'e-vis', libelle: 'Autre action', visible: true },
      { ...base, id: 'e-xss', libelle: HOSTILE }, { id: 'e-sans', onglets: ['code'] }, { ...base, id: 'e-ong', libelle: 'Z',
          onglets: ['x'] }]) await s.ev(A(e));
    await poser('>'); const tous = await libs();
    const natifs = [HUIT[0], HUIT[3], HUIT[4], HUIT[5], HUIT[6]].every((x) => tous.includes(x));
    Object.assign(o.pa4, { erreurs: await lire('window.__ce.length'), natifs, ajoutees: ['Mon action', 'Autre action'].map((x) => tous.includes(x)),
        refusee: tous.includes('Z') });
    await touche('Escape'); await s.ev("window.__r['e-ok'](); 1"); await poser('>mon action'); o.pa4.retiree = !(await libs()).includes('Mon action');
    await s.ev("document.getElementById('search').select()"); await s.send('Input.insertText', { text: 'img' }); await pause(500);
    o.pa4.xss = await lire("({ p: typeof window.__p, img: document.querySelectorAll('#results img').length, " +
      "groupes: [...document.querySelectorAll('#results .gt')].map((g) => g.textContent), " +
      "texte: document.getElementById('results').innerText.split('<img').length - 1 })");
    await touche('Escape');
  });
  return o;
});
