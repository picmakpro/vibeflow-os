// chrome-equipe-clavier.mjs — clavier et témoins mineurs de l'onglet Équipe, dans un vrai Chromium headless (UIFN-12, UIFN-13).
// Usage : EK_ACTION=<action> node chrome-equipe-clavier.mjs <chrome> <url>
//   UNE interaction par chargement de page (variable EK_ACTION) ; l'état de la page est attendu par interrogation, jamais par une durée fixe.
//   focus-transcript  : (EK1, UIFN-12) focalise « Lire le transcript », frappe Entrée au clavier (événement de touche réel), attend le transcript, relève l'élément actif
//                       → { avant, apres, lu, trace } ; trace = suite dédoublonnée des relevés (élément actif, bouton désactivé, bouton d'origine ou remplacé) toutes les 10 ms
//   changer-agent     : (EK2, m1) lit le transcript d'un agent, sélectionne un autre agent, relève la clé de rechargement du sessionStorage → { avant, apres }
//   recharger         : (EK3, m10) lit le transcript, relève le sessionStorage entier → { entrees, texteLu, fuite }
//   ferme-puis-who    : (EK4, m8) ouvre le tiroir « Au travail », le ferme, livre un `who` qui change l'arbre → { ouvert, ferme, rouvert }
//   rendu-commande    : (EK5, m5) demande la dernière commande ; la réponse du serveur est remplacée par un texte qui porte du balisage → { elements, injecte, texte, zone }
//   focus-doing-tiroir: (EK8, UIFN-12) tiroir « Au travail » : focalise « Voir la dernière commande », frappe Entrée au clavier, attend la commande, relève l'élément actif
//                       → { avant, apres, lu, trace } (même forme que focus-transcript ; la réponse du serveur est remplacée par un texte fixe)
//   focus-puis-who    : (EK8) focalise « Lire le transcript » du panneau d'un agent, livre un `who` (le panneau est redessiné), relève l'élément actif → { remplace, apres }
//   focus-tiroir      : (EK9) même mesure pour « Voir la dernière commande » du tiroir « Au travail » → { remplace, apres }
//   badge             : (EK10) marge entre le bord droit du badge d'état et celui de sa carte, pied long, à 390 / 1024 / 1440 px → { "390": px, "1024": px, "1440": px }
//   echelle           : (EK13, Q3b) échelle de l'ajustement au premier affichage et recouvrement titre / première carte, à 390 et 768 px → { "390": { k, aire }, "768": { k, aire } }
//   titre-grandi      : (EK14) le titre de #context grandit après le cadrage (police plus large du runner) ; recouvrement avec la première carte une fois la page stable → { k, aire }
//   echap-tiroir      : (EK15) sélectionne une carte, ouvre le tiroir « Au travail », focalise le tiroir ou le bouton (EK_FOCUS), frappe Échap → { ferme0, ouvert, avant, place, ferme, apres } (attributs aria du bouton, sélection et vue avant/après)
//   un-lateral        : (EK16, Q12, PU-G-203) largeur EK_LARGEUR, ordre EK_ORDRE (git-puis-travail | travail-puis-git) : ouvre Git (touche g) puis « Au travail » (ou l'inverse), relève l'état et le focus à chaque pas, puis élargit à 1440 px → { etapes: { premier, second, large }, ... }
//   touches-canevas   : (EK17, PU-G-137, Q8) 1440 px, clic sur le fond, puis f, F, p, P, +, =, - une à une, chacune sur une caméra décalée du cadrage (elle aurait un effet) : la page dont l'URL est donnée (Équipe) ne bouge pas (transformation de la caméra, tiroir de détail) ; mêmes touches sur Projet et sur Code (témoin : elles y agissent toujours)
//                       → { [page]: { depart, apres: { f, F, p, P, plus, egal, moins }, agit: { f, F, p, P, plus, egal, moins } } }
//   tab-titre         : (EK18, S6, revue du 2026-11-08) 1 440 px : vraies touches Tab, le titre de la vue est un arrêt Git fermé, ne l'est pas Git ouvert, l'est de nouveau refermé → { ferme, ouvert, referme, verdict }
//   libelles          : (EK11) ligne des sources du tiroir et infobulle de la recherche de l'onglet Équipe → { src, titre }
// Rend une ligne JSON { ... } ou { erreur }. Socle : chrome-session.mjs (une instance de Chrome, fermée proprement).
import { executer } from './chrome-session.mjs';
import { parcoursTab } from './chrome-parcours-tab.mjs';
const [, , chrome, url] = process.argv;
const ACTION = process.env.EK_ACTION || '';
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";
// enveloppe d'EventSource : le scénario livre lui-même des événements `who` aux écouteurs réels de 70-vf-live.js
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
const DECRIRE = `const dec = (e) => e ? { tag: e.tagName, id: e.id || '', transcript: (e.dataset && e.dataset.vfTranscript) || '', dansTiroir: !!(e.closest && e.closest('#panel')) } : null;`;
const LU = "(() => { const z = document.querySelector('.vf-transcript'); return !!z && z.textContent.length > 0; })()";

await executer(chrome, async (s) => {
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true }); // sans cela, la page headless n'a pas le focus de fenêtre et les évènements focusin / focusout ne partent pas
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ });
  await s.naviguer(url);
  await s.attendre(PRET, 'viewer prêt');
  // page calme : le flux `who` est arrivé et la page ne se recharge plus (une structure d'équipe changée la recharge, et le clic serait perdu)
  const calme = () => s.stable("performance.timeOrigin + ':' + !!(window.__vfLive && window.__vfLive.who)", 'page calme');
  const touche = async (key, code, vk, text) => {
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk, text });
    await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk });
  };
  if (ACTION === 'focus-transcript') {
    await calme();
    await s.attendre("!!document.querySelector('#panel [data-vf-transcript]')", 'bouton « Lire le transcript »');
    await s.ev(`window.__b = document.querySelector('#panel [data-vf-transcript]'); window.__b.focus(); window.__tr = []; (() => { ${DECRIRE}
      const rel = () => { const a = document.activeElement; return JSON.stringify([a ? a.tagName : null, !!window.__b.disabled, a === window.__b, document.contains(window.__b)]); };
      let prec = ''; window.__iv = setInterval(() => { const r = rel(); if (r !== prec) { window.__tr.push(r); prec = r; } }, 10); })()`);
    const avant = await s.ev(`(() => { ${DECRIRE} return dec(document.activeElement); })()`);
    const hashAvant = await s.ev('location.hash');
    await touche('Enter', 'Enter', 13, '\r');
    // le transcript peut ne jamais s'afficher (Entrée sans effet) : on le dit (lu: false) au lieu de lever, pour garder la mesure du focus
    const lu = await s.attendre(LU, 'transcript affiché', 8000).then(() => true, () => false);
    const apres = await s.stable(`(() => { ${DECRIRE} return dec(document.activeElement); })()`, 'élément actif stable');
    const etat = await s.ev("(() => { const b = document.querySelector('#panel [data-vf-transcript]'); return { selection: window.VibeFlow.state.selected, bouton: !!b, desactive: !!(b && b.disabled), url: location.hash }; })()");
    const trace = await s.ev('(() => { clearInterval(window.__iv); return window.__tr; })()');
    return { avant, apres, lu, etat, trace, hashAvant, hashApres: etat.url };
  }
  if (ACTION === 'changer-agent') {
    const autre = process.env.EK_AUTRE || 'n:ag-a2';
    await calme();
    await s.attendre("!!document.querySelector('#panel [data-vf-transcript]')", 'bouton « Lire le transcript »');
    await s.ev("document.querySelector('#panel [data-vf-transcript]').click()");
    await s.attendre(LU, 'transcript affiché');
    const avant = await s.ev("sessionStorage.getItem('vf-equipe-ouvert')");
    await s.ev(`window.VibeFlow.select(${JSON.stringify(autre)})`);
    await s.attendre(`(() => { const b = document.querySelector('#panel [data-vf-transcript]'); return !!b && b.dataset.vfTranscript === ${JSON.stringify(autre.replace(/^n:ag-/, ''))}; })()`, 'panneau du second agent');
    const apres = await s.stable("sessionStorage.getItem('vf-equipe-ouvert')", 'clé de rechargement stable');
    return { avant, apres };
  }
  if (ACTION === 'recharger') {
    await calme();
    await s.attendre("!!document.querySelector('#panel [data-vf-transcript]')", 'bouton « Lire le transcript »');
    await s.ev("document.querySelector('#panel [data-vf-transcript]').click()");
    await s.attendre(LU, 'transcript affiché');
    const marque = process.env.EK_TEXTE || 'mandat synthétique';
    return await s.stable(`(() => { const e = {}; for (let i = 0; i < sessionStorage.length; i++) { const k = sessionStorage.key(i); e[k] = sessionStorage.getItem(k); }
      return { entrees: e, texteLu: document.querySelector('.vf-transcript').textContent.includes(${JSON.stringify(marque)}), fuite: Object.values(e).some((v) => String(v).includes(${JSON.stringify(marque)})) }; })()`, 'sessionStorage stable');
  }
  if (ACTION === 'ferme-puis-who') {
    const corps = `const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
      const flux = () => window.__es.find((e) => e.url.includes('/api/vf/events')); let seq = 5000;
      const emettre = (workers) => flux().__emit('who', { seq: seq++, at: Date.now(), who: { workers, sources: {} } });
      const S = { kind: 'session', id: 'S1', etat: 'actif', tree: '.', task: 'session' }, M = { kind: 'subagent', id: 'M1', etat: 'actif', role: 'vf-dev-manager', tree: '.', parent: 'S1', task: 'manager', dureeS: 60 };`;
    await s.attendre("!!window.__es && !!window.__es.find((e) => e.url.includes('/api/vf/events')) && !!document.querySelector('#vf-lock')", 'flux et badge');
    await s.ev(`(() => { ${corps} emettre([S, M]); window.__corps = 1; })()`);
    await s.ev("document.querySelector('#vf-lock').click()");
    const ouvert = await s.attendre("!!document.querySelector('.vf-whop') && !document.body.classList.contains('no-panel')", 'tiroir ouvert');
    await s.ev("document.querySelector('#btn-panel').click()"); // ferme le panneau
    const ferme = await s.attendre("document.body.classList.contains('no-panel')", 'tiroir fermé');
    await s.ev(`(() => { ${corps} emettre([S, M, { kind: 'subagent', id: 'C1', etat: 'actif', role: 'vf-coder', tree: '.', parent: 'M1', task: 'nouveau', dureeS: 5 }]); })()`);
    await s.attendre("window.__vfLive && window.__vfLive.who && window.__vfLive.who.workers.length === 3", 'le nouveau who est pris en compte');
    const rouvert = await s.stable("!document.body.classList.contains('no-panel')", 'état du tiroir stable');
    return { ouvert: !!ouvert, ferme: !!ferme, rouvert };
  }
  if (ACTION === 'rendu-commande') {
    await s.attendre("!!document.querySelector('#panel [data-vf-doing]')", 'bouton « Voir la dernière commande »');
    await s.ev(`(() => { const R = window.fetch.bind(window); window.fetch = (u, o) => String(u).includes('/api/vf/doing') ? Promise.resolve({ ok: true, json: async () => ({ doing: '<b id=ek-injecte>gras</b>' }) }) : R(u, o); })()`); // le serveur ne rend jamais de balisage (résumé de la commande) : on le fait rendre à la page, pour prouver SON rendu
    await s.ev("document.querySelector('#panel [data-vf-doing]').click()");
    await s.attendre("(() => { const z = document.querySelector('#panel .vf-doing'); return !!z && !z.hidden && z.textContent.length > 0; })()", 'commande affichée');
    return await s.stable(`(() => { const z = document.querySelector('#panel .vf-doing'); return { elements: z.querySelectorAll('*').length, injecte: !!document.getElementById('ek-injecte'), texte: z.textContent, zone: z.innerHTML.slice(0, 120) }; })()`, 'zone de commande stable');
  }
  if (ACTION === 'focus-doing-tiroir') {
    const corps = `const flux = () => window.__es.find((e) => e.url.includes('/api/vf/events'));
      const S = { kind: 'session', id: 'S1', etat: 'actif', tree: '.', task: 'session' }, M = { kind: 'subagent', id: 'M1', etat: 'actif', role: 'vf-dev-manager', tree: '.', parent: 'S1', task: 'manager', dureeS: 60 };`;
    await s.attendre("!!window.__es && !!window.__es.find((e) => e.url.includes('/api/vf/events')) && !!document.querySelector('#vf-lock')", 'flux et badge');
    await s.ev(`(() => { ${corps} flux().__emit('who', { seq: 5000, at: Date.now(), who: { workers: [S, M], sources: {} } });
      const R = window.fetch.bind(window); window.fetch = (u, o) => String(u).includes('/api/vf/doing') ? new Promise((r) => setTimeout(() => r({ ok: true, json: async () => ({ doing: 'ls -la (témoin EK8)' }) }), 150)) : R(u, o); })()`);
    await s.ev("document.querySelector('#vf-lock').click()");
    await s.attendre("!!document.querySelector('.vf-whop [data-vf-doing]')", 'bouton « Voir la dernière commande » du tiroir');
    await s.ev(`window.__b = document.querySelector('.vf-whop [data-vf-doing]'); window.__b.focus(); window.__tr = []; (() => { ${DECRIRE}
      const rel = () => { const a = document.activeElement; return JSON.stringify([a ? a.tagName : null, !!window.__b.disabled, a === window.__b, document.contains(window.__b)]); };
      let prec = ''; window.__iv = setInterval(() => { const r = rel(); if (r !== prec) { window.__tr.push(r); prec = r; } }, 10); })()`);
    const avant = await s.ev(`(() => { ${DECRIRE} const e = document.activeElement; return Object.assign(dec(e), { doing: (e && e.dataset && e.dataset.vfDoing) || '' }); })()`);
    await touche('Enter', 'Enter', 13, '\r');
    const lu = await s.attendre("(() => { const z = document.querySelector('.vf-whop .vf-doing'); return !!z && !z.hidden && z.textContent.includes('témoin EK8'); })()", 'commande affichée', 8000).then(() => true, () => false);
    const apres = await s.stable(`(() => { ${DECRIRE} const e = document.activeElement; return Object.assign(dec(e), { doing: (e && e.dataset && e.dataset.vfDoing) || '' }); })()`, 'élément actif stable');
    const trace = await s.ev('(() => { clearInterval(window.__iv); return window.__tr; })()');
    return { avant, apres, lu, trace };
  }
  if (ACTION === 'focus-puis-who' || ACTION === 'focus-tiroir') {
    const tiroir = ACTION === 'focus-tiroir';
    const corps = `const flux = () => window.__es.find((e) => e.url.includes('/api/vf/events')); let seq = 7000;
      const emettre = (workers) => flux().__emit('who', { seq: seq++, at: Date.now(), who: { workers, sources: {} } });
      const S = { kind: 'session', id: 'S1', etat: 'actif', tree: '.', task: 'session' }, M = { kind: 'subagent', id: 'M1', etat: 'actif', role: 'vf-dev-manager', tree: '.', parent: 'S1', task: 'manager', dureeS: 60 };
      const C = (task) => ({ kind: 'subagent', id: 'C1', etat: 'actif', role: 'vf-coder', tree: '.', parent: 'M1', task, dureeS: 5 });`;
    const SEL = tiroir ? '.vf-whop [data-vf-doing]' : '#panel [data-vf-transcript]';
    if (tiroir) {
      await s.attendre("!!window.__es && !!window.__es.find((e) => e.url.includes('/api/vf/events')) && !!document.querySelector('#vf-lock')", 'flux et badge');
      await s.ev(`(() => { ${corps} emettre([S, M, C('un')]); })()`);
      await s.ev("document.querySelector('#vf-lock').click()");
    } else await calme();
    await s.attendre(`!!document.querySelector('${SEL}')`, 'bouton');
    await s.ev(`window.__b = document.querySelector('${SEL}'); window.__b.focus()`);
    const focalise = await s.ev('document.activeElement === window.__b');
    // un `who` qui change le contenu : le panneau (ou le tiroir) est redessiné, le bouton est remplacé
    if (tiroir) await s.ev(`(() => { ${corps} emettre([S, M, C('deux')]); })()`);
    else await s.ev(`(() => { ${corps} emettre(window.__vfLive.who.workers.map((w) => ({ ...w, ageS: (w.ageS || 0) + 1 }))); })()`);
    const remplace = await s.attendre(`!document.contains(window.__b) && !!document.querySelector('${SEL}')`, 'bouton remplacé par le redessin', 5000).then(() => true, () => false);
    const apres = await s.stable(`(() => { ${DECRIRE} const a = document.activeElement; const d = dec(a); d.estLeBouton = !!a && a.matches && a.matches('${SEL}'); return d; })()`, 'élément actif stable');
    return { focalise, remplace, apres };
  }
  if (ACTION === 'badge') {
    const r = {};
    for (const l of [390, 1024, 1440]) {
      await s.send('Emulation.setDeviceMetricsOverride', { width: l, height: 900, deviceScaleFactor: 1, mobile: false });
      await s.naviguer(url);
      await s.attendre(PRET, 'viewer prêt');
      await s.attendre("!!document.querySelector('.card .foot .vst') && !!(window.__vfLive && window.__vfLive.who)", 'cartes et pieds');
      r[l] = await s.stable(`(() => { let min = 1e9, n = 0; for (const v of document.querySelectorAll('.card .foot .vst')) { const c = v.closest('.card'); if (!c) continue; n++;
        min = Math.min(min, Math.round(c.getBoundingClientRect().right - v.getBoundingClientRect().right)); } return n ? min : 'aucun badge'; })()`, 'marge du badge');
    }
    return r;
  }
  if (ACTION === 'echelle') {
    // 5 chargements successifs à 390 px (le plafond était intermittent : un rendu suivant l'écrasait), puis 768 px ; recouvrement mesuré contre le bas RÉEL de #context
    // et de tout ce qu'il contient (lien « Plus » compris), jamais contre freeArea()
    const r = { 390: [], 768: [] };
    for (const [l, n] of [[390, 5], [768, 2]]) {
      await s.send('Emulation.setDeviceMetricsOverride', { width: l, height: 800, deviceScaleFactor: 1, mobile: false });
      for (let i = 0; i < n; i++) {
        await s.naviguer(url);
        await s.attendre(PRET, 'viewer prêt');
        await s.attendre("document.querySelectorAll('#svg .card').length > 0 && !!(window.__vfLive && window.__vfLive.who)", 'cartes');
        r[l].push(await s.stable(`(() => { const k = Math.round(window.VibeFlow.state.t.k * 100) / 100; const ctx = document.getElementById('context'),
          nd = [...document.querySelectorAll('#svg .card')].filter((e) => e.getBoundingClientRect().width > 0);
          nd.sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top || a.getBoundingClientRect().left - b.getBoundingClientRect().left);
          const c = nd[0] && nd[0].getBoundingClientRect(); let aire = 0, bas = 0;
          if (ctx && c) for (const e of [ctx, ...ctx.querySelectorAll('*')]) { const a = e.getBoundingClientRect(); if (!a.width || !a.height) continue; bas = Math.max(bas, a.bottom);
            aire += Math.round(Math.max(0, Math.min(a.right, c.right) - Math.max(a.left, c.left)) * Math.max(0, Math.min(a.bottom, c.bottom) - Math.max(a.top, c.top))); }
          return { k, aire, gauche: c ? Math.round(c.left) : null, hautCarte: c ? Math.round(c.top) : null, basContexte: Math.round(bas), cartes: nd.length,
            diag: 'ctx.bas=' + Math.round(bas) + ' carte.haut=' + (c ? Math.round(c.top) : '?') + ' k=' + k + ' cadrage=' + JSON.stringify(window.__vfCadrage || null) + ' polices=' + (document.fonts && document.fonts.status) }; })()`, 'échelle stable'));
      }
    }
    return r;
  }
  if (ACTION === 'titre-grandi') {
    await s.send('Emulation.setDeviceMetricsOverride', { width: 768, height: 800, deviceScaleFactor: 1, mobile: false });
    await s.naviguer(url);
    await s.attendre(PRET, 'viewer prêt');
    await s.attendre("document.querySelectorAll('#svg .card').length > 0 && !!(window.__vfLive && window.__vfLive.who) && !!window.__vfCadrage", 'cadrage fait');
    // le titre grandit APRÈS le cadrage : corps de police et deuxième ligne, comme sous une police de repli plus large
    await s.ev("(() => { const h = document.querySelector('#context h1'); h.style.fontSize = '40px'; h.style.lineHeight = '1.3'; h.style.maxWidth = '9ch'; })()");
    return await s.stable(`(() => { const k = Math.round(window.VibeFlow.state.t.k * 100) / 100, ctx = document.getElementById('context'),
      nd = [...document.querySelectorAll('#svg .card')].filter((e) => e.getBoundingClientRect().width > 0); nd.sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top || a.getBoundingClientRect().left - b.getBoundingClientRect().left);
      const c = nd[0].getBoundingClientRect(); let aire = 0; for (const e of [ctx, ...ctx.querySelectorAll('*')]) { const a = e.getBoundingClientRect(); if (!a.width || !a.height) continue;
        aire += Math.round(Math.max(0, Math.min(a.right, c.right) - Math.max(a.left, c.left)) * Math.max(0, Math.min(a.bottom, c.bottom) - Math.max(a.top, c.top))); }
      return { k, aire }; })()`, 'recouvrement stable');
  }
  if (ACTION === 'libelles') {
    await s.attendre("!!window.__es && !!window.__es.find((e) => e.url.includes('/api/vf/events')) && !!document.querySelector('#vf-lock')", 'flux et badge');
    await s.ev(`(() => { window.__es.find((e) => e.url.includes('/api/vf/events')).__emit('who', { seq: 9000, at: Date.now(), who: { workers: window.__vfLive.who.workers, sources: { sessions: { etat: 'lue' }, locks: { etat: 'erreur' }, dags: { etat: 'lue' } } } }); })()`); // PU-G-180 : le pied ne paraît que pour une source illisible
    await s.ev("document.querySelector('#vf-lock').click()");
    await s.attendre("!!document.querySelector('.vf-whop .src')", 'ligne des sources').catch(async () => { throw new Error('ligne des sources absente ; panneau : ' + (await s.ev("document.getElementById('panel').innerHTML.slice(0, 300)")) + ' ; no-panel=' + (await s.ev("document.body.classList.contains('no-panel')"))); });
    return await s.stable("({ src: document.querySelector('.vf-whop .src').textContent, titre: (document.getElementById('search-btn') || {}).title || 'absent' })", 'libellés');
  }
  if (ACTION === 'echap-tiroir') { // (EK15, PU-G-189, PU-G-190) Échap sur le tiroir « Au travail », focus dans le tiroir (EK_FOCUS=panneau) ou sur le bouton (EK_FOCUS=bouton)
    const corps = `const flux = () => window.__es.find((e) => e.url.includes('/api/vf/events'));
      const S = { kind: 'session', id: 'S1', etat: 'actif', tree: '.', task: 'session' }, M = { kind: 'subagent', id: 'M1', etat: 'actif', role: 'vf-dev-manager', tree: '.', parent: 'S1', task: 'manager', dureeS: 60 };`;
    const lire = "(() => { const b = document.querySelector('#vf-lock'); return b ? { expanded: b.getAttribute('aria-expanded'), controls: b.getAttribute('aria-controls') } : null; })()";
    await s.attendre("!!window.__es && !!window.__es.find((e) => e.url.includes('/api/vf/events')) && !!document.querySelector('#vf-lock')", 'flux et badge');
    await s.ev(`(() => { ${corps} flux().__emit('who', { seq: 5000, at: Date.now(), who: { workers: [S, M], sources: {} } }); })()`);
    await calme();
    // une carte sélectionnée : sans écouteur propre au tiroir, Échap la désélectionne (le viewer remonte le canevas) ; la sélection se pose AVANT l'ouverture du tiroir (select() ferme les panneaux posés)
    const nd = await s.ev("(() => { const k = window.VibeFlow.children(window.VibeFlow.state.container || 'root') || [], x = k[0]; return x ? (typeof x === 'string' ? x : x.id) : null; })()");
    if (!nd) return { erreur: 'aucun nœud à sélectionner : ' + await s.ev("(() => { try { const F = window.VibeFlow, V = window.VibeFlow; return JSON.stringify({ c: V.state.container, kids: F.children('root'), keys: Object.keys(F.graph).join(), cartes: document.querySelectorAll('#svg .card').length, noeuds: [...document.querySelectorAll('#svg .node')].slice(0, 3).map((e) => e.getAttribute('data-id') || e.id || e.outerHTML.slice(0, 100)) }); } catch (e) { return 'exc ' + e.message; } })()") };
    await s.ev(`window.VibeFlow.select(${JSON.stringify(nd)})`);
    const ferme0 = await s.stable(lire, 'attributs du bouton, tiroir fermé');
    await s.ev("document.querySelector('#vf-lock').click()");
    await s.attendre("!!document.querySelector('.vf-whop') && !document.body.classList.contains('no-panel')", 'tiroir ouvert');
    const ouvert = await s.stable(lire, 'attributs du bouton, tiroir ouvert');
    const avant = await s.ev("({ selection: window.VibeFlow.state.selected, hash: location.hash })");
    await s.ev(process.env.EK_FOCUS === 'bouton' ? "document.querySelector('#vf-lock').focus()" : "(document.querySelector('.vf-whop [data-vf-doing]') || document.querySelector('.vf-whop .aw-head')).focus()");
    const place = await s.ev("(() => { const a = document.activeElement; return { tag: a.tagName, id: a.id || '', dansTiroir: !!a.closest('#panel') }; })()");
    // PU-G-175 : le viewer ne lève plus la sélection quand le focus est dans un contrôle ; l'arrêt de la propagation se lit donc sur un écouteur de fenêtre (le viewer écoute là), non plus sur la sélection
    await s.ev("(() => { window.__escRemonte = false; window.addEventListener('keydown', (e) => { if (e.key === 'Escape') window.__escRemonte = true; }); })()");
    await touche('Escape', 'Escape', 27);
    const ferme = await s.attendre("document.body.classList.contains('no-panel')", 'tiroir fermé par Échap', 4000).then(() => true, () => false);
    const apres = await s.stable("(() => { const a = document.activeElement, b = document.querySelector('#vf-lock'); return { selection: window.VibeFlow.state.selected, hash: location.hash, actif: a ? a.id || a.tagName : null, expanded: b.getAttribute('aria-expanded'), ferme: document.body.classList.contains('no-panel') }; })()", 'état après Échap');
    const remonte = await s.ev('window.__escRemonte');
    return { ferme0, ouvert, avant, place, ferme, apres, remonte };
  }
  if (ACTION === 'tab-titre') { // (EK18, S6 de la revue du 2026-11-08) à 1 440 px, avec le tiroir Git ouvert, le titre de la vue (masqué dessous) n'est plus un arrêt de Tab ; fermé, il l'est de nouveau (la définition du titre reste atteignable au clavier, PU-G-193)
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 800, deviceScaleFactor: 1, mobile: false });
    await s.attendre("!!window.VFGitTiroir && !!document.querySelector('#context h1[tabindex]')", 'tiroir Git et titre à définition');
    await calme();
    const detail = {}; // les arrêts visités à chaque parcours (balise, id ou classe, texte court, tabindex, visibilité) : le DIAG de la suite les montre quand le verdict n'est pas celui attendu
    // parcours de Tab (départ explicite, cycle borné, arrêts visités rangés dans detail[nom] pour le DIAG) : voir chrome-parcours-tab.mjs
    const parcours = (nom) => parcoursTab(s, touche, detail, nom);
    const r = { ferme: await parcours('ferme') };
    await s.ev('document.activeElement && document.activeElement.blur()'); await touche('g', 'KeyG', 71, 'g'); await s.attendre('window.VFGitTiroir.ouvert()', 'tiroir Git ouvert'); await calme();
    r.ouvert = await parcours('ouvert');
    await s.ev('document.activeElement && document.activeElement.blur()'); await touche('g', 'KeyG', 71, 'g'); await s.attendre('!window.VFGitTiroir.ouvert()', 'tiroir Git refermé'); await calme();
    r.referme = await parcours('referme');
    return { ...r, detail, verdict: [r.ferme.includes('titre'), r.ouvert.includes('titre'), r.ouvert.length > 3, r.referme.includes('titre')].join('/') };
  }
  if (ACTION === 'un-lateral') { // (EK16, PU-G-203) un seul tiroir latéral sous 1280 px ; les deux à 1280 px et au-delà
    await s.send('Emulation.setDeviceMetricsOverride', { width: +process.env.EK_LARGEUR, height: 800, deviceScaleFactor: 1, mobile: false });
    await s.attendre("!!window.__es && !!window.__es.find((e) => e.url.includes('/api/vf/events')) && !!document.querySelector('#vf-lock') && !!window.VFGitTiroir", 'flux, badge et tiroir Git');
    await s.ev("(() => { const S = { kind: 'session', id: 'S1', etat: 'actif', tree: '.', task: 'session' }; window.__es.find((e) => e.url.includes('/api/vf/events')).__emit('who', { seq: 5000, at: Date.now(), who: { workers: [S], sources: {} } }); })()");
    await calme();
    const etat = () => s.stable(`(() => { const a = document.activeElement, g = document.querySelector('#vf-git-tiroir'), b = document.body.classList; return { git: window.VFGitTiroir.ouvert(), travail: !!document.querySelector('#panel > .vf-whop') && !b.contains('no-panel'), focus: !a ? null : g && g.contains(a) ? 'git' : a.closest('#panel') ? 'travail' : a.id === 'vf-lock' ? 'bouton-travail' : a.tagName }; })()`, 'état des tiroirs');
    const ouvrirGit = async () => { await s.ev('document.activeElement && document.activeElement.blur()'); await touche('g', 'KeyG', 71, 'g'); await s.attendre('window.VFGitTiroir.ouvert()', 'tiroir Git ouvert'); };
    const ouvrirTravail = async () => { await s.ev("document.querySelector('#vf-lock').click()"); await s.attendre("!!document.querySelector('#panel > .vf-whop') && !document.body.classList.contains('no-panel')", 'tiroir « Au travail » ouvert'); };
    const etapes = {};
    if (process.env.EK_ORDRE === 'travail-puis-git') { await ouvrirTravail(); etapes.premier = await etat(); await ouvrirGit(); etapes.second = await etat(); }
    else {
      await ouvrirGit(); etapes.premier = await etat(); await ouvrirTravail(); etapes.second = await etat();
      // un nouveau `who` redessine le tiroir (le titre qui avait le focus est remplacé) : le focus doit y rester (recette du 2026-11-08, PU-G-203)
      await s.ev("(() => { const S = { kind: 'session', id: 'S1', etat: 'actif', tree: '.', task: 'session' }, S2 = { kind: 'session', id: 'S2', etat: 'actif', tree: '.', task: 'seconde session' }; window.__es.find((e) => e.url.includes('/api/vf/events')).__emit('who', { seq: 5001, at: Date.now(), who: { workers: [S, S2], sources: {} } }); })()");
      await s.attendre("document.querySelector('#panel > .vf-whop .aw-count b')?.textContent === '2'", 'tiroir redessiné (deux actifs)');
      await calme(); etapes.redessin = await etat();
    }
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 800, deviceScaleFactor: 1, mobile: false });
    etapes.large = await etat();
    return { largeur: +process.env.EK_LARGEUR, etapes };
  }
  if (ACTION === 'touches-canevas') { // PU-G-137 : sur Équipe, la frappe ne déclenche ni cadrage, ni tiroir, ni zoom ; Projet et Code gardent leurs raccourcis (témoin positif : sans lui, un clavier muet partout passerait)
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    const KEYS = { f: ['f', 'KeyF', 70, 'f'], F: ['F', 'KeyF', 70, 'F'], p: ['p', 'KeyP', 80, 'p'], P: ['P', 'KeyP', 80, 'P'], plus: ['+', 'Equal', 187, '+'], egal: ['=', 'Equal', 187, '='], moins: ['-', 'Minus', 189, '-'] };
    const camera = "JSON.stringify([...['x', 'y', 'k'].map((c) => Math.round(window.VibeFlow.state.t[c] * 1000) / 1000), document.body.classList.contains('no-panel')])";
    const lire = () => s.stable(camera, 'caméra posée');
    const attendreCalme = async () => { await new Promise((r) => setTimeout(r, 700)); return lire(); }; // le zoom par bouton s'anime : on mesure une fois la caméra posée
    const sur = async (page) => {
      await s.naviguer(page === 'equipe' ? url : url.replace(/[^/]*$/, page === 'projet' ? 'project.html' : 'index.html')); await s.attendre(PRET, 'viewer prêt (' + page + ')');
      await s.ev("(() => { try { const T = window.VibeFlowTour; if (T && T.active()) T.end(); } catch (e) { void e; } })()");
      await s.stable("performance.timeOrigin + ':' + !!(document.querySelector('#viewport .node'))", 'page calme (' + page + ')');
      const pt = await s.ev("(() => { for (let y = 160; y < innerHeight - 140; y += 40) for (let x = 40; x < innerWidth - 400; x += 40) { const e = document.elementFromPoint(x, y); if (e && e.tagName.toLowerCase() === 'svg' && !e.closest('#zoom,#ask,#context,header')) return { x, y }; } return null; })()");
      if (!pt) return { erreur: 'aucun point de fond (' + page + ')' };
      for (const t of ['mouseMoved', 'mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type: t, x: pt.x, y: pt.y, button: t === 'mouseMoved' ? 'none' : 'left', clickCount: 1 });
      await s.ev('document.activeElement && document.activeElement.blur && document.activeElement.blur()');
      const depart = await lire(), apres = {}, agit = {};
      for (const [nom, k] of Object.entries(KEYS)) {
        // chaque touche est frappée sur une caméra où elle AURAIT un effet : décalée du cadrage par le bouton de zoom (jamais par une touche), pour que f et F aient quelque chose à cadrer
        await s.ev("document.querySelector('#z-in').click(); document.activeElement && document.activeElement.blur && document.activeElement.blur()");
        const avant = await attendreCalme();
        await touche(...k); await new Promise((r) => setTimeout(r, 600)); apres[nom] = await lire();
        agit[nom] = apres[nom] !== avant; // la caméra ou le tiroir a bougé
      }
      return { depart, apres, agit };
    };
    const r = {}; for (const page of ['equipe', 'projet', 'code']) r[page] = await sur(page);
    return r;
  }
  return { erreur: 'EK_ACTION inconnue : ' + ACTION };
}, { csp: false });
