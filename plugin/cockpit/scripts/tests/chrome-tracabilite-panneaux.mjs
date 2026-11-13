// chrome-tracabilite-panneaux.mjs — section « Décisions », panneaux d'ADR et de décision, registres, lignes de commit (76-07), vrai Chrome sans tête.
// Usage : node chrome-tracabilite-panneaux.mjs <chrome> <racine-du-serveur> <sections>   Rend UNE ligne JSON { d1, … } ou { erreur }. Chaque section est isolée.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, liste] = process.argv;
const SEL = new Set((liste || 'd1,d3,d5,d6,d7,d8').split(','));
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const AIDES = `window.__tr = { nb: (x) => String(x == null ? '' : x).replace(/\\u00a0/g, ' ').replace(/\\s+/g, ' ').trim() };`;
const SANS_REGISTRE = "Aucune décision définie dans les registres de phase. Les lignes Pnn-D-nn d'un fichier CONTEXT de phase apparaissent ici.";
const SEC = (n) => `#panel details[data-vf-trace-${n}]`;
// le panneau d'objet affiché : étiquette, titre (id, ancre), texte de définition, sections, lignes de commit, lignes de voisins, pied de source
const PAN = `(() => { const p = document.querySelector('#panel [data-vf-trace-panneau]'); if (!p) return null; const t = p.querySelector('.pt'), nb = __tr.nb;
  const pd = p.querySelector('.pd'), cl = (e) => e.querySelector('.vf-trace-id');
  return { kind: nb((p.querySelector('.kindlabel') || {}).textContent), titre: t && nb(t.textContent), id: t && t.id, trace: t && t.getAttribute('data-trace'),
    pd: pd ? nb(pd.textContent) : '', secs: [...p.querySelectorAll('h3')].map((h) => nb(h.firstChild.textContent)), texte: nb(p.textContent),
    commits: [...p.querySelectorAll('.vf-trace-commit')].map((c) => [nb(cl(c).textContent), nb(c.querySelector('.vf-trace-jour').textContent), nb(c.querySelector('.vf-trace-sujet').textContent)].join('·')),
    boutons: [...p.querySelectorAll('button.vf-trace-commit')].length, lignes: [...p.querySelectorAll('.vf-trace-commit')].length,
    dec: [...p.querySelectorAll('.vf-trace-ligne[data-trace^="decision:"] .vf-trace-id')].map((e) => nb(e.textContent)),
    pied: nb((p.querySelector('.vf-trace-pied') || {}).textContent) }; })()`;

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
  const vrai = (expr, max = 6000) => attendreValeur(() => s.ev(expr), (v) => v === true, { max }).then((v) => v === true);
  const clic = async (sel) => {
    const r = await lire(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'nearest' });
      const b = e.getBoundingClientRect(); return { x: b.x + b.width / 2, y: b.y + b.height / 2 }; })()`);
    if (!r) throw new Error(`clic : « ${sel} » absent`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
  };
  const touche = async (key, code, vk) => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: vk,
    nativeVirtualKeyCode: vk, ...(key === 'Enter' && type === 'keyDown' ? { text: '\r' } : {}) }); };
  const focus = (sel) => s.ev(`document.querySelector(${JSON.stringify(sel)}).focus()`);
  const titre = (t) => vrai(`(() => { const e = document.querySelector('#panel [data-vf-trace-panneau] .pt'); return !!e && e.textContent === ${JSON.stringify(t)}; })()`);
  const corps = () => vrai("document.querySelectorAll('#panel [data-vf-trace-panneau] .sec').length >= 1 && !document.querySelector('#panel [aria-busy=\"true\"]')");
  const racineOuverte = async (n) => { // la vue d'ensemble, section n ouverte et lue
    await s.ev("VibeFlow.go('root')"); await vrai(`!!document.querySelector(${JSON.stringify(SEC(n))})`); reqs.length = 0;
    await clic(`${SEC(n)} > summary`); await vrai(`!!document.querySelector(${JSON.stringify(SEC(n) + ' .vf-trace-bilan')})`); // le bilan : fin du chargement
  };
  const ouvrirAdr = async (id, clavier) => { // une ligne d'ADR de la section ; Entrée au clavier, clic à la souris
    const l = `${SEC('decisions')} .vf-trace-ligne[data-trace="adr:${id}"]`;
    if (clavier) { await focus(l); await touche('Enter', 'Enter', 13); } else await clic(l);
    await titre(id); await corps();
  };

  await sec('d1', async () => { // C3.1, C3.2 : section repliée, bilan, ADR ouverte au clavier, commits qui la citent ; ADR sans commit
    await charger(); await s.ev("VibeFlow.go('root')"); await vrai(`!!document.querySelector(${JSON.stringify(SEC('decisions'))})`);
    o.d1avant = { ferme: await lire(`!document.querySelector(${JSON.stringify(SEC('decisions'))}).open`), req: reqs.filter((x) => x.includes('vue=adr')).length };
    reqs.length = 0; await clic(`${SEC('decisions')} > summary`); await vrai(`!!document.querySelector(${JSON.stringify(SEC('decisions') + ' .vf-trace-ligne')})`);
    o.d1sec = await lire(`({ bilan: __tr.nb((document.querySelector(${JSON.stringify(SEC('decisions') + ' .vf-trace-bilan')}) || {}).textContent),
      compteur: __tr.nb(document.querySelector(${JSON.stringify(SEC('decisions') + ' > summary .c')}).textContent),
      ids: [...document.querySelectorAll(${JSON.stringify(SEC('decisions') + ' > div .vf-trace-ligne[data-trace^="adr:"] .vf-trace-id')})].map((e) => e.textContent) })`);
    o.d1sec.req = reqs.filter((x) => x.includes('vue=adr')).length;
    await ouvrirAdr('ADR-001', true); o.d1adr = await lire(PAN);
    await charger(); await racineOuverte('decisions'); await ouvrirAdr('ADR-002', false); o.d2 = await lire(`({ titre: ${PAN}.titre,
      aucun: ${PAN}.texte.includes('Aucun commit ne cite cet objet. Un message de commit qui nomme son identifiant le relierait.'), lignes: ${PAN}.lignes })`);
  });

  const decision = (cle) => `${SEC('decisions')} .vf-trace-ligne[data-trace="decision:${cle}"]`;
  const registre = async () => { await clic(`${SEC('decisions')} details.vf-trace-sous > summary`); await vrai(`!!document.querySelector(${JSON.stringify(decision('P90-D-01:ph-90'))})`); };
  const ADRCITEES = `(() => { const s = [...document.querySelectorAll('#panel [data-vf-trace-panneau] .sec')].find((x) => x.querySelector('h3').firstChild.textContent === 'ADR citées');
    return s ? { boutons: [...s.querySelectorAll('button')].map((b) => __tr.nb(b.querySelector('.vf-trace-id').textContent)),
      inertes: [...s.querySelectorAll('.vf-trace-inerte')].map((e) => ({ tag: e.tagName, texte: __tr.nb(e.textContent), tab: e.getAttribute('tabindex') })) } : null; })()`;
  await sec('d3', async () => { // C3.3, C3.4 : décision préfixée (phase, ADR citées, commits, pied) puis décision nue
    await charger(); await racineOuverte('decisions');
    o.d3sous = await lire(`({ n: document.querySelectorAll(${JSON.stringify(SEC('decisions') + ' details.vf-trace-sous')}).length,
      ferme: [...document.querySelectorAll(${JSON.stringify(SEC('decisions') + ' details.vf-trace-sous')})].every((d) => !d.open),
      resume: __tr.nb(document.querySelector(${JSON.stringify(SEC('decisions') + ' details.vf-trace-sous > summary')}).textContent) })`);
    await registre(); o.d3lignes = await lire(`[...document.querySelectorAll(${JSON.stringify(SEC('decisions') + ' details.vf-trace-sous .vf-trace-ligne')})]
      .map((b) => [b.querySelector('.vf-trace-id').textContent, __tr.nb(b.querySelector('.vf-trace-tt').textContent)].join('|'))`);
    await clic(decision('P90-D-01:ph-90')); await titre('P90-D-01'); await corps(); await pause(300);
    o.d3 = await lire(`({ ...${PAN}, adr: ${ADRCITEES}, phase: __tr.nb((document.querySelector('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace^="phase:"]') || {}).textContent) })`);
    await clic('#panel [data-vf-trace-panneau] .vf-trace-ligne[data-trace^="phase:"]'); await pause(500); o.d3sel = await lire('VibeFlow.state.selected');
    await charger(); await racineOuverte('decisions'); await registre(); await clic(decision('D-04:ph-90')); await titre('D-04, Phase 90'); await corps();
    o.d4 = await lire(`({ ...${PAN}, nue: ${PAN}.texte.includes('Décision nue : aucun commit ne lui est relié, la citation sans phase est ambiguë.') })`);
  });
  await sec('d5', async () => { // C3.5, C3.9 : 31 registres, 30 sous-replis du plus récent au plus ancien, « + 1 autre registre » ; pas de docs/ADR.md
    await charger(); await racineOuverte('decisions');
    const S = SEC('decisions');
    o.d5 = await lire(`(() => { const r = [...document.querySelectorAll(${JSON.stringify(S + ' details.vf-trace-sous')})], t = (d) => __tr.nb(d.querySelector('summary').textContent);
      return { n: r.length, ferme: r.every((d) => !d.open), premier: t(r[0]), dernier: t(r[r.length - 1]), plus: __tr.nb((document.querySelector(${JSON.stringify(S + ' .vf-trace-plus')}) || {}).textContent),
        sansAdr: __tr.nb(document.querySelector(${JSON.stringify(S)}).textContent).includes('Pas de docs/ADR.md dans ce dossier. Les sections ADR-NNN de ce fichier apparaîtraient ici.'),
        bilan: __tr.nb(document.querySelector(${JSON.stringify(S + ' .vf-trace-bilan')}).textContent) }; })()`);
    await clic(`${S} details.vf-trace-sous > summary`); await pause(200);
    o.d5dec = await lire(`[...document.querySelectorAll(${JSON.stringify(S + ' details.vf-trace-sous[open] .vf-trace-ligne')})].map((b) => [__tr.nb(b.querySelector('.vf-trace-id').textContent), __tr.nb(b.querySelector('.vf-trace-tt').textContent)].join('|'))`);
    await clic(`${S} > div > .vf-trace-plus, ${S} .vf-trace-plus`); await titre('Registres de phase'); await pause(200);
    const liste = () => lire(`({ n: document.querySelectorAll('#panel [data-vf-trace-panneau] details.vf-trace-sous').length, compte: __tr.nb((document.querySelector('#panel .vf-trace-compte') || {}).textContent),
      resume: __tr.nb(document.querySelector('#panel [data-vf-trace-panneau] details.vf-trace-sous > summary').textContent) })`);
    o.d5liste = await liste(); await clic('#panel [data-vf-trace-pages] button:last-child'); await pause(300); o.d5page2 = await liste();
  });
  await sec('d6', async () => { // C3.6, C3.9 : 31 commits qui citent ADR-001 : 30 lignes, « + 1 autre commit », liste paginée ; aucun registre de phase
    await charger(); await s.ev("VibeFlow.go('root')"); await vrai(`!!document.querySelector(${JSON.stringify(SEC('decisions'))})`);
    await clic(`${SEC('decisions')} > summary`); await vrai(`!!document.querySelector(${JSON.stringify(SEC('decisions') + ' .vf-trace-ligne')})`);
    o.d6sans = await lire(`__tr.nb(document.querySelector(${JSON.stringify(SEC('decisions'))}).textContent).includes(${JSON.stringify(SANS_REGISTRE)})`);
    await ouvrirAdr('ADR-001', false); await pause(300);
    const plus = '#panel [data-vf-trace-panneau] .vf-trace-plus', page = () => lire(`({ n: document.querySelectorAll('#panel [data-vf-trace-panneau] .vf-trace-commit').length, compte: __tr.nb((document.querySelector('#panel .vf-trace-compte') || {}).textContent) })`);
    o.d6 = await lire(`({ n: document.querySelectorAll('#panel [data-vf-trace-panneau] .vf-trace-commit').length, plus: __tr.nb(document.querySelector(${JSON.stringify(plus)}).textContent),
      compteur: __tr.nb(document.querySelector('#panel [data-vf-trace-panneau] .sec:last-of-type h3 .c, #panel [data-vf-trace-panneau] h3 .c').textContent) })`);
    await clic(plus); await titre("Commits de l'ADR ADR-001"); await pause(200); o.d6p1 = await page();
    await clic('#panel [data-vf-trace-pages] button:last-child'); await pause(300); o.d6p2 = await page();
  });
  await sec('d7', async () => { // C3.7 : un clic sur une ligne de commit appelle le tiroir Git ; sans tiroir la ligne est du texte
    await charger(); await s.ev("window.__tir = 0; window.VFGitTiroir = { ouvrir() { window.__tir += 1; } }");
    await racineOuverte('decisions'); await ouvrirAdr('ADR-001', false); await vrai("document.querySelectorAll('#panel button.vf-trace-commit').length > 0");
    o.d7nom = await lire("(document.querySelector('#panel button.vf-trace-commit') || {}).ariaLabel");
    await clic('#panel button.vf-trace-commit'); await pause(300); o.d7appels = await lire('window.__tir');
    await charger(); await s.ev('window.VFGitTiroir = undefined'); await racineOuverte('decisions'); await ouvrirAdr('ADR-001', false); await pause(300);
    o.d7sans = await lire(`({ boutons: document.querySelectorAll('#panel button.vf-trace-commit').length, lignes: document.querySelectorAll('#panel .vf-trace-commit').length,
      tab: [...document.querySelectorAll('#panel .vf-trace-commit')].map((e) => e.getAttribute('tabindex')).join() })`);
  });
  await sec('d8', async () => { // C3.8 : borne atteinte : le message entier au-dessus de la liste
    await charger(); await racineOuverte('decisions'); await ouvrirAdr('ADR-001', false); await pause(300);
    o.d8 = await lire(`(() => { const b = document.querySelector('#panel [data-vf-trace-panneau] .vf-trace-borne'), l = document.querySelector('#panel [data-vf-trace-panneau] .vf-trace-lignes');
      return { texte: b && __tr.nb(b.textContent), avant: !!b && !!l && !!(b.compareDocumentPosition(l) & Node.DOCUMENT_POSITION_FOLLOWING),
        taille: b && getComputedStyle(b).fontSize, marge: b && getComputedStyle(b).marginBottom, graisse: b && getComputedStyle(b).fontWeight }; })()`);
  });
  return o;
}, { csp: true });
