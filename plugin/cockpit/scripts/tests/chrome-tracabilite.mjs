// chrome-tracabilite.mjs — la section « Traçabilité » d'une phase, ses preuves et la section « Jalon » dans le vrai panneau de Projet (76-06), vrai Chrome sans tête.
// Usage : node chrome-tracabilite.mjs <chrome> <racine-du-serveur> [sections]   Rend UNE ligne JSON { c10, c11, … } ou { erreur }. Chaque section est isolée.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, liste] = process.argv;
const SEL = new Set((liste || 'c10,c11,c13,c14,c15,c16,c17,c18,c19,c110,c111,c112').split(','));
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
// aides posées dans la page avant ses scripts : lecture des lignes d'une phase, texte normalisé (espaces insécables ramenées à l'espace)
const AIDES = `window.__tr = { sec: () => document.getElementById('vf-trace-phase'),
  nb: (x) => String(x == null ? '' : x).replace(/\\u00a0/g, ' ').replace(/\\s+/g, ' ').trim(),
  ligne: (id) => [...document.querySelectorAll('#vf-trace-phase .vf-trace-ligne')].find((b) => b.querySelector('.vf-trace-id').textContent === id),
  corail: () => { const i = document.createElement('i'); i.style.color = 'var(--st-blocked)'; document.body.append(i); const c = getComputedStyle(i).color; i.remove(); return c; } };`;
const SEC = '#vf-trace-phase';
const LIGNES = `(() => { const s = __tr.sec(); if (!s) return null; return [...s.querySelectorAll('.vf-trace-ligne')].map((b) => ({ tag: b.tagName,
  id: b.querySelector('.vf-trace-id').textContent, mot: __tr.nb((b.querySelector('.vf-trace-mot') || {}).textContent) })); })()`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} }, reqs = [];
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AIDES });
  await s.send('Network.enable');
  s.ecouter('Network.requestWillBeSent', (p) => { reqs.push(`${p.request.method} ${p.request.url.replace(/^https?:\/\/[^/]+/, '')}`); });
  const sec = async (nom, f) => { if (!SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 200); } };
  const lire = async (expr) => { const v = await s.ev(`(async () => JSON.stringify(await (${expr})))()`); return typeof v === 'string' ? JSON.parse(v) : null; };
  const charger = async (w = 1440, h = 900) => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
    await s.naviguer(`${racine}/project.html?vue=couloirs`, { brut: true }); await s.attendre(PRET, 'page prête');
    await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs'); await pause(300);
  };
  const attendreVrai = (expr, max = 6000) => attendreValeur(() => s.ev(expr), (v) => v === true, { max }).then((v) => v === true);
  // une fois posé : le panneau d'une phase sélectionnée porte ses lignes ou son état (jamais lu dans la foulée du geste) ; false à l'échéance courte
  const phase = async (n) => {
    await s.ev(`VibeFlow.select('n:ph-${n}')`);
    const ok = await attendreVrai(`!!document.querySelector('${SEC} .vf-trace-ligne, ${SEC} .vf-trace-etat, ${SEC} .vf-trace-boite')`);
    await stabiliser(() => lire(LIGNES), { pas: 150, max: 4000 });
    return ok;
  };
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'nearest' });
      const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const touche = async (key, code, vk) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk, ...(key === 'Enter' && type === 'keyDown' ? { text: '\r' } : {}) }); };
  const ligneDe = (id, sel) => lire(`(() => { const l = __tr.ligne('${id}'); return l ? ${sel} : null; })()`);

  await sec('c10', async () => { // C1.0 : le fichier neuf est servi (A48) ; la première ligne porte le marqueur
    await charger();
    o.c10 = await lire(`(async () => { const e = performance.getEntriesByType('resource').map((x) => x.name).find((n) => /\\/74-vf-trace\\.js$/.test(n));
      if (!e) return 'non demandé'; const r = await fetch(e, { headers: { 'x-vf-cockpit-token': VF_ETAT.jeton() } });
      return r.status + '|' + (await r.text()).split("\\n")[0].slice(0, 13); })()`);
    o.c10intrus = await lire(`(async () => { const e = performance.getEntriesByType('resource').map((x) => x.name).find((n) => /\\/74-vf-trace\\.js$/.test(n));
      if (!e) return 'non demandé'; const r = await fetch(e.replace('74-vf-trace.js', '74-vf-trace-intrus.js'), { headers: { 'x-vf-cockpit-token': VF_ETAT.jeton() } }); return r.status; })()`);
  });
  await sec('c11', async () => { // C1.1 et C1.2 : la ligne de REQ-01 (manque : VERIFICATION), puis le témoin REQ-02 (chaîne complète)
    await charger(); reqs.length = 0;
    o.c11pose = await phase(2); o.c11 = await lire(`(() => { const t = document.querySelector('${SEC} h3'); return { h3: t ? t.firstChild.textContent.trim() : null, lignes: ${LIGNES} }; })()`);
    o.c11req = reqs.filter((r) => r.includes('/api/vf/tracabilite'));
    o.c12pose = await phase(3); o.c12 = await lire(LIGNES);
  });
  await sec('c13', async () => { // C1.3 : quatre glyphes de 16 px, octogone à la place voulue, le corail ne vit que dans l'octogone
    await charger(); await phase(1);
    o.c13 = await lire(`(() => { const c = __tr.corail(), q = (id) => [...__tr.ligne(id).querySelectorAll('.vf-trace-g')], bg = (e) => getComputedStyle(e).backgroundColor;
      const dim = (e) => { const b = e.getBoundingClientRect(); return Math.round(b.width) + 'x' + Math.round(b.height); }, oct = (id) => q(id).map((e) => (e.className.includes('contradiction') ? 1 : 0)).join('');
      const fautifs = [...document.querySelectorAll('#panel .vf-trace *')].filter((e) => !e.classList.contains('vf-trace-g')
        && ['color', 'backgroundColor', 'borderTopColor'].some((p) => getComputedStyle(e)[p] === c)).length;
      return { n: q('REQ-16').length, dim: q('REQ-16').map(dim).join(), masque: q('REQ-16').every((e) => e.getAttribute('aria-hidden') === 'true'), oct16: oct('REQ-16'), oct17: oct('REQ-17'),
        mot16: __tr.nb(__tr.ligne('REQ-16').querySelector('.vf-trace-mot').textContent), mot17: __tr.nb(__tr.ligne('REQ-17').querySelector('.vf-trace-mot').textContent),
        corail: q('REQ-16').map((e) => (bg(e) === c ? 1 : 0)).join(''), fautifs }; })()`);
  });
  await sec('c14', async () => { // C1.4 : bilan, compteur et légende ; les nombres sont ceux de la route
    await charger(); await phase(1);
    o.c14 = await lire(`(async () => { const r = await VF_ETAT.lireJson('/api/vf/tracabilite?vue=phase&cle=ph-1'), b = r.phase.bilan, s = __tr.sec(), leg = s.querySelector('.vf-trace-legende');
      return { route: [b.contradiction, b.manque, b.nonLisible, b.complete, b.total].join(), bilan: __tr.nb((s.querySelector('.vf-trace-bilan') || {}).textContent),
        compteur: __tr.nb(s.querySelector('h3 .c').textContent), legende: leg ? __tr.nb(leg.textContent) : null, glyphesLegende: leg ? leg.querySelectorAll('.vf-trace-g').length : 0,
        corailLegende: leg ? [...leg.querySelectorAll('.vf-trace-g')].filter((e) => getComputedStyle(e).backgroundColor === __tr.corail()).length : -1 }; })()`);
  });
  await sec('c15', async () => { // C1.5 : cinq lignes au bureau (trois sous 700 px), les lignes à trou d'abord, puis « + N autres exigences »
    for (const [w, cle] of [[1440, 'c15b'], [390, 'c15f']]) {
      await charger(w, w === 390 ? 844 : 900); await phase(1);
      o[cle] = await lire(`(() => { const p = __tr.sec().querySelector('.vf-trace-plus'); return { ids: ${LIGNES}.map((l) => l.id).join(), plus: p ? __tr.nb(p.textContent) : null }; })()`);
    }
  });
  await sec('c16', async () => { // C1.6 : nom accessible (texte visible puis texte masqué) et mentions de la ligne 3
    await charger(); await phase(1);
    for (const id of ['REQ-13', 'REQ-14']) o['c16' + id] = await ligneDe(id, `{ sr: __tr.nb(l.querySelector('.vf-trace-sr').textContent), l3: __tr.nb((l.querySelector('.vf-trace-l3') || {}).textContent),
      nom: __tr.nb(l.textContent).endsWith(__tr.nb(l.querySelector('.vf-trace-sr').textContent)), tx: l.querySelector('.vf-trace-tx').textContent.length > 20 }`);
  });
  await sec('c17', async () => { // C1.7 : entrée haute (un bouton, nom accessible) ; Entrée au clavier amène la section dans la vue ; absente sans exigence
    await charger(); await phase(1);
    o.c17 = await lire(`(() => { const b = document.querySelector('#panel button[data-vf-section="vf-trace-phase"]'); return b ? { tag: b.tagName, nom: __tr.nb(b.textContent),
      avant: !!(b.compareDocumentPosition(__tr.sec()) & Node.DOCUMENT_POSITION_FOLLOWING) } : null; })()`);
    await s.ev("document.querySelector('#panel button[data-vf-section=\"vf-trace-phase\"]').focus()"); await touche('Enter', 'Enter', 13); await pause(400);
    o.c17dans = await lire("(() => { const p = document.getElementById('panel').getBoundingClientRect(), t = __tr.sec().getBoundingClientRect(); return t.top >= p.top - 2 && t.top < p.top + p.height / 2; })()");
    await phase(90); o.c17sans = await lire("!!document.querySelector('#panel [data-vf-section=\"vf-trace-phase\"]')");
  });
  await sec('c18', async () => { // C1.8 : « Preuves attachées » fermé par défaut, plafonné ouvert, chemins copiables, critères absents du repli
    for (const [w, cle] of [[1440, 'c18b'], [390, 'c18f']]) {
      await charger(w, w === 390 ? 844 : 900); await phase(3);
      const ferme = await lire("!document.querySelector('#vf-trace-phase details.vf-trace-repli').open");
      await clic('#vf-trace-phase details.vf-trace-repli > summary'); await pause(300);
      o[cle] = { ferme, ...(await lire(`(() => { const d = document.querySelector('#vf-trace-phase details.vf-trace-repli'), p = [...d.querySelectorAll('.vf-trace-preuve')];
        const plus = d.querySelector('.vf-trace-plus'); return { n: p.length, p1: p[0] ? __tr.nb(p[0].textContent) : null, plus: plus ? __tr.nb(plus.textContent) : null,
        ref: d.querySelectorAll('.vf-ref code').length, criteres: __tr.nb(d.textContent).includes('critère un'), titre: __tr.nb(d.querySelector('summary').textContent) }; })()`)) };
    }
    await clic('#vf-trace-phase details.vf-trace-repli .vf-ref'); await pause(500);
    o.c18copie = await lire("document.querySelector('#vf-trace-phase details.vf-trace-repli .vf-ref .vf-copie-etat').textContent");
  });
  await sec('c19', async () => { // C1.9 : section « Jalon » repliée dans la vue d'ensemble, lue à l'ouverture, une ligne ouvre la phase par select
    await charger(); reqs.length = 0; await s.ev("VibeFlow.go('root')"); await pause(500);
    o.c19ferme = await lire("(() => { const d = document.querySelector('#panel details[data-vf-trace-jalon]'); return d ? !d.open : null; })()");
    o.c19avant = reqs.filter((r) => r.includes('vue=jalon')).length;
    await clic('#panel details[data-vf-trace-jalon] > summary');
    await attendreVrai("!!document.querySelector('#panel details[data-vf-trace-jalon] .vf-trace-ligne')");
    o.c19req = reqs.filter((r) => r.includes('vue=jalon')).length;
    o.c19 = await lire(`(async () => { const d = document.querySelector('#panel details[data-vf-trace-jalon]'), r = await VF_ETAT.lireJson('/api/vf/tracabilite?vue=jalon'), b = r.jalon.bilan;
      const l = [...d.querySelectorAll('.vf-trace-ligne')].map((x) => __tr.nb(x.textContent));
      return { route: [b.contradiction, b.manque, b.nonLisible, b.sansExigence, b.complete, b.total].join(), bilan: __tr.nb(d.querySelector('.vf-trace-bilan').textContent),
        phases: l.length, ph1: l.find((x) => x.startsWith('Phase 1')) || null, octo: d.querySelectorAll('.vf-trace-g-contradiction').length }; })()`);
    await s.ev("document.querySelector('#panel details[data-vf-trace-jalon] .vf-trace-ligne').focus()"); await touche('Enter', 'Enter', 13); await pause(500);
    o.c19ouvre = await lire("({ sel: VibeFlow.state.selected, sec: !!__tr.sec() })");
  });
  await sec('c110', async () => { // C1.10 : états de § 9 par interception du réseau (chargement retenu, route refusée puis « Réessayer »), phase sans exigence
    let mode = 'passer', tenus = [];
    s.ecouter('Fetch.requestPaused', (p) => {
      if (mode === 'refuser') s.send('Fetch.fulfillRequest', { requestId: p.requestId, responseCode: 503, body: Buffer.from('{"erreur":"emission-refusee"}').toString('base64') }).catch(() => {});
      else if (mode === 'tenir') tenus.push(p.requestId);
      else s.send('Fetch.continueRequest', { requestId: p.requestId }).catch(() => {});
    });
    await s.send('Fetch.enable', { patterns: [{ urlPattern: '*api/vf/tracabilite*' }] });
    await charger(); mode = 'tenir'; tenus = [];
    await s.ev("VibeFlow.select('n:ph-3')"); await pause(40);
    o.c110tot = await lire("({ fantomes: document.querySelectorAll('#vf-trace-phase .vf-trace-fantome').length, occupe: !!document.querySelector('#vf-trace-phase [aria-busy]') })");
    await pause(500);
    o.c110charge = await lire("({ occupe: !!document.querySelector('#vf-trace-phase [aria-busy=\"true\"]'), fantomes: document.querySelectorAll('#vf-trace-phase .vf-trace-fantome').length, texte: __tr.nb(__tr.sec().textContent) })");
    mode = 'passer'; for (const id of tenus) await s.send('Fetch.continueRequest', { requestId: id }).catch(() => {});
    o.c110lu = await attendreVrai(`!!document.querySelector('${SEC} .vf-trace-ligne')`);
    await charger(); mode = 'refuser'; await s.ev("VibeFlow.select('n:ph-2')");
    await attendreVrai("!!document.querySelector('#vf-trace-phase .vf-trace-boite')");
    o.c110erreur = await lire(`(() => { const b = document.querySelector('#vf-trace-phase .vf-trace-boite'), r = b && b.querySelector('button'), h = r && r.getBoundingClientRect();
      return b ? { texte: __tr.nb(b.textContent), taille: r && getComputedStyle(r).fontSize, haut: h && Math.round(h.height), pasDeLigne: !document.querySelector('#vf-trace-phase .vf-trace-ligne') } : null; })()`);
    mode = 'passer'; await clic('#vf-trace-phase .vf-trace-boite button');
    o.c110reessai = await attendreVrai(`!!document.querySelector('${SEC} .vf-trace-ligne')`);
    await phase(90); o.c110vide = await lire("__tr.nb((__tr.sec().querySelector('.vf-trace-etat') || {}).textContent)");
    await s.send('Fetch.disable');
  });
  await sec('c111', async () => { // C1.11 : quatre tailles de texte, feuille sans couleur ni espacement en dur, aucun tiret cadratin
    await charger(); await phase(1); await clic('#vf-trace-phase details.vf-trace-repli > summary'); await pause(300);
    o.c111 = await lire(`(() => { const tailles = new Set(); for (const e of document.querySelectorAll('#panel .vf-trace *')) {
        if (![...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim()) || e.closest('.vf-trace-sr')) continue; tailles.add(parseFloat(getComputedStyle(e).fontSize)); }
      const css = (document.getElementById('vf-trace-style') || {}).textContent || '';
      return { tailles: [...tailles].sort((a, b) => a - b).join(), css: css.length > 500, couleurs: (css.match(/#[0-9a-fA-F]{3,8}\\b|rgb\\(|hsl\\(/g) || []).length,
        espaces: (css.match(/(padding|margin|gap)[^;{}]*\\d+(\\.\\d+)?px/g) || []).length, interdits: (css.match(/--text-1|--trace-|--git-/g) || []).length,
        cadratin: /\\u2014/.test(document.querySelector('#panel .vf-trace').textContent) }; })()`);
    o.c111violations = s.violations.length;
  });
  await sec('c112', async () => { // C1.12 (filet) : hauteurs de la section, aucun défilement horizontal, carte non poussée
    for (const [w, h, cle] of [[1440, 900, 'c112b'], [390, 844, 'c112f']]) {
      await charger(w, h); const carte = () => lire("(() => { const c = document.querySelector('.vp-carte').getBoundingClientRect(); return [c.x, c.y, c.width].join(); })()");
      await phase(1); const avant = await carte(); const ferme = await lire('Math.round(__tr.sec().getBoundingClientRect().height)');
      await clic('#vf-trace-phase details.vf-trace-repli > summary'); await pause(300);
      const ouvert = await lire('Math.round(__tr.sec().getBoundingClientRect().height)');
      o[cle] = { ferme, ouvert, defilement: await lire("(() => { const p = document.getElementById('panel'); return p.scrollWidth <= p.clientWidth; })()"), carte: w === 1440 ? avant === await carte() : true };
    }
  });
  return o;
}, { csp: true });
