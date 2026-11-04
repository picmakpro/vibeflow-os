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
//   libelles          : (EK11) ligne des sources du tiroir et infobulle de la recherche de l'onglet Équipe → { src, titre }
// Rend une ligne JSON { ... } ou { erreur }. Socle : chrome-session.mjs (une instance de Chrome, fermée proprement).
import { executer } from './chrome-session.mjs';
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
  if (ACTION === 'libelles') {
    await s.attendre("!!window.__es && !!window.__es.find((e) => e.url.includes('/api/vf/events')) && !!document.querySelector('#vf-lock')", 'flux et badge');
    await s.ev(`(() => { window.__es.find((e) => e.url.includes('/api/vf/events')).__emit('who', { seq: 9000, at: Date.now(), who: { workers: window.__vfLive.who.workers, sources: { sessions: { etat: 'lue' }, locks: { etat: 'lue' }, dags: { etat: 'lue' } } } }); })()`);
    await s.ev("document.querySelector('#vf-lock').click()");
    await s.attendre("!!document.querySelector('.vf-whop .src')", 'ligne des sources').catch(async () => { throw new Error('ligne des sources absente ; panneau : ' + (await s.ev("document.getElementById('panel').innerHTML.slice(0, 300)")) + ' ; no-panel=' + (await s.ev("document.body.classList.contains('no-panel')"))); });
    return await s.stable("({ src: document.querySelector('.vf-whop .src').textContent, titre: (document.getElementById('search-btn') || {}).title || 'absent' })", 'libellés');
  }
  return { erreur: 'EK_ACTION inconnue : ' + ACTION };
}, { csp: false });
