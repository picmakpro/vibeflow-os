// chrome-tracabilite-panneaux.mjs — section « Décisions », panneaux d'ADR et de décision, registres, lignes de commit (76-07), vrai Chrome sans tête.
// Usage : node chrome-tracabilite-panneaux.mjs <chrome> <racine-du-serveur> <sections>   Rend UNE ligne JSON { d1, … } ou { erreur }. Chaque section est isolée.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, liste] = process.argv;
const SEL = new Set((liste || 'd1').split(','));
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const AIDES = `window.__tr = { nb: (x) => String(x == null ? '' : x).replace(/\\u00a0/g, ' ').replace(/\\s+/g, ' ').trim() };`;
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
    await clic(`${SEC(n)} > summary`); await vrai(`!!document.querySelector(${JSON.stringify(SEC(n) + ' .vf-trace-ligne, ' + SEC(n) + ' .vf-trace-etat')})`);
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
  return o;
}, { csp: true });
