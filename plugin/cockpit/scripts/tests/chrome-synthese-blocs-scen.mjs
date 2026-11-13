// chrome-synthese-blocs-scen.mjs — scénarios navigateur des blocs 2 et 3 de la Synthèse (77-06), joués par chrome-synthese-blocs.mjs. Une ligne JSON, ou { erreur }.
//   main     lab daté, gates mixtes lents (1 s) : burn-up, jauges, lecture à l'ouverture, focus, erreur et relecture, onglets, styles, mouvement réduit, 700 et 701 px
//   ok       lab dont une phase close n'a pas de date, gates dans le budget, un chemin piégé : barres, ordre, note, marche de moins, balises inertes
//   partiel  contrôle de méthode ancien (code 64) et contrôle de densité hors dépôt de distribution : « Indisponible » et « Non applicable » côte à côte
//   tout64   les deux contrôles anciens : une seule phrase
// Les lectures se font une fois la page posée (stabiliser / attendreValeur), jamais dans la foulée du geste.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
import { AMORCE_ECOUTEURS, AMORCE_VISITE, journalReseau } from './chrome-synthese.mjs';
import { AMORCE_MQ } from './chrome-synthese-blocs.mjs';

const BTN = `document.getElementById('btn-synthese')`, OUVERTE = `!!document.querySelector('#panel > .vf-sy')`;
const SEC = (id) => `document.querySelector('[data-vf-sy-bloc="${id}"]')`;
const BLOCS = `[...document.querySelectorAll('#panel > section.vf-sy[data-vf-sy-bloc]')].map((e) => e.dataset.vfSyBloc)`;
const FOCUS = `(() => { const a = document.activeElement; return a ? { tag: a.tagName, id: a.id || '', classe: a.className && a.className.baseVal === undefined ? a.className : '', texte: (a.textContent || '').slice(0, 24) } : null; })()`;
const FOND = `(() => { const l = Array.from(document.querySelectorAll('[data-vf-sy-bloc="methode"] li[data-vf-sy-jauge]')); return l.length; })()`;
const largeur = async (s, w) => { await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(200); };
const ouvrir = async (s) => { if (await s.ev(OUVERTE)) return; await s.ev(`${BTN}.click()`); await s.attendre(OUVERTE, 'Synthèse ouverte');
  await s.attendre(`!!document.querySelector('[data-vf-sy-bloc="burnup"] .vf-sy-corps > *')`, 'burn-up rendu'); };
const fermer = async (s) => { if (!(await s.ev(OUVERTE))) return; await s.ev(`${BTN}.click()`); await attendreValeur(() => s.ev(`!${OUVERTE}`), (v) => v === true, { max: 3000 }); };
const lu = (s) => attendreValeur(() => s.ev(`${SEC('methode')} ? ${SEC('methode')}.getAttribute('aria-busy') : 'absent'`), (v) => v !== 'true', { max: 20000 });

// ---- audit des styles calculés sous une section : neutres, grille d'espacement, tailles, graisses, polices, ombres ----
const AUDIT = `(sel) => { const out = { n: 0, couleur: [], espacement: [], police: [], ombre: [] }; const GRILLE = [0, 2, 4, 6, 8, 12, 16, 20, 24, 32], TAILLES = [20, 13.5, 12.5, 11];
  const nombres = (c) => { const m = /(rgba?|color)\\(([^)]*)\\)/.exec(c); if (!m) return null; let v = m[2].replace('srgb', '').split(/[ ,\\/]+/).filter(Boolean).map(Number); if (m[1] === 'color') v = v.map((x) => x * 255); return v; };
  const neutre = (c) => { const v = nombres(c); return !v || (Math.abs(v[0] - v[1]) <= 2 && Math.abs(v[1] - v[2]) <= 2 && Math.abs(v[0] - v[2]) <= 2); };
  for (const el of document.querySelectorAll(sel + ', ' + sel + ' *')) { out.n++; const nom = el.tagName + '.' + (el.getAttribute('class') || ''); const c = getComputedStyle(el);
    const teintes = { color: c.color, fond: c.backgroundColor, fill: c.fill, stroke: c.stroke, outline: c.outlineStyle === 'none' ? '' : c.outlineColor };
    for (const k of ['Top', 'Right', 'Bottom', 'Left']) if (parseFloat(c['border' + k + 'Width']) > 0) teintes['b' + k] = c['border' + k + 'Color'];
    if (el.classList.contains('vst')) teintes.glyphe = getComputedStyle(el, '::before').backgroundColor;
    for (const [k, v] of Object.entries(teintes)) if (v && !neutre(v)) out.couleur.push(nom + ' ' + k + '=' + v);
    for (const p of ['paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft', 'marginTop', 'marginRight', 'marginBottom', 'marginLeft', 'rowGap', 'columnGap']) {
      const x = parseFloat(c[p]); if (Number.isFinite(x) && !GRILLE.includes(Math.abs(x))) out.espacement.push(nom + ' ' + p + '=' + c[p]); }
    const f = c.fontFamily.split(',')[0].replace(/["']/g, '').trim();
    if (!TAILLES.includes(parseFloat(c.fontSize)) || ![400, 500, 600].includes(Number(c.fontWeight)) || !['Inter', 'JetBrains Mono'].includes(f)) out.police.push(nom + ' ' + c.fontSize + '/' + c.fontWeight + '/' + f);
    if (c.boxShadow !== 'none') out.ombre.push(nom); }
  return { n: out.n, couleur: out.couleur.slice(0, 6), espacement: out.espacement.slice(0, 6), police: out.police.slice(0, 6), ombre: out.ombre.slice(0, 4) }; }`;
const audit = (s, id) => s.ev(`(${AUDIT})('[data-vf-sy-bloc="${id}"]')`);

const BU = `(() => { const sec = ${SEC('burnup')}; if (!sec) return null; const q = (x) => sec.querySelector(x), svg = q('svg.vf-sy-courbe');
  const vis = (e) => !!e && e.getBoundingClientRect().height > 0 && getComputedStyle(e).display !== 'none';
  const teinte = (v) => { const p = document.createElement('i'); p.style.color = 'var(' + v + ')'; sec.appendChild(p); const c = getComputedStyle(p).color; p.remove(); return c; };
  const series = svg ? [...svg.querySelectorAll('path[data-serie]')].map((p) => { const c = getComputedStyle(p); return { serie: p.dataset.serie, d: p.getAttribute('d'), tirets: c.strokeDasharray, stroke: c.stroke, largeur: c.strokeWidth }; }) : [];
  const jalon = window.VibeFlow.graph.nodes.find((n) => n.kind === 'jalon'), liste = q('ol.vf-sy-liste'), det = q('details.vf-tech');
  return { titre: sec.querySelector('h3').textContent, tete: (q('.vf-sy-tete') || {}).textContent || '', aide: (q('.vf-sy-aide') || {}).textContent || '', pied: jalon ? jalon.foot : null,
    svg: !!svg, svgVisible: vis(svg), role: svg ? svg.getAttribute('role') : null, aria: svg ? svg.getAttribute('aria-label') : null, focusable: svg ? svg.getAttribute('focusable') : null, series,
    t3: teinte('--text-3'), t4: teinte('--text-4'), degrades: sec.querySelectorAll('linearGradient, radialGradient').length, pastilles: svg ? svg.querySelectorAll('circle, rect, [class*="legende"]').length : 0,
    directes: svg ? [...svg.querySelectorAll('text[data-direct]')].map((t) => t.textContent) : [], textes: svg ? svg.querySelectorAll('text').length : 0,
    liste: { n: liste ? liste.children.length : 0, visible: vis(liste), dansDetails: !!(liste && liste.closest('details')), premiere: liste && liste.children[0] ? liste.children[0].textContent : '' },
    details: { n: sec.querySelectorAll('details').length, ouvert: det ? det.open : null, resume: det ? det.querySelector('summary').textContent : '', hauteurResume: det ? det.querySelector('summary').getBoundingClientRect().height : 0 },
    notes: [...sec.querySelectorAll('[data-vf-sy-note]')].map((e) => e.textContent), texte: sec.querySelector('.vf-sy-corps').textContent }; })()`;
const JA = `(() => { const sec = ${SEC('methode')}; if (!sec) return null; const m = (e, p) => { const c = getComputedStyle(e, p); return c.webkitMaskImage && c.webkitMaskImage !== 'none' ? c.webkitMaskImage : (c.maskImage || 'none'); };
  const lis = [...sec.querySelectorAll('li[data-vf-sy-jauge]')].map((li) => { const v = li.querySelector(':scope > .vf-sy-l3 .vst'), bar = li.querySelector(':scope > .vf-bar'), fill = bar && bar.querySelector('i');
    return { type: li.dataset.vfSyJauge, verdict: li.dataset.verdict, mot: v ? v.textContent.trim() : '', glyphe: v ? m(v, '::before') !== 'none' : false, barre: !!bar, ariaBarre: bar ? bar.getAttribute('aria-hidden') : null,
      hach: fill ? m(fill) !== 'none' : false, largeur: fill ? fill.style.width : null, val: (li.querySelector(':scope > .vf-sy-val') || {}).textContent || '', texte: li.textContent,
      sous: li.querySelectorAll('.vf-sy-autres li').length, autres: (li.querySelector('.more') || {}).textContent || '', imgs: li.querySelectorAll('img, script').length }; });
  const chemins = [...sec.querySelectorAll('code.vf-sy-chemin')].map((c) => ({ t: c.textContent, wbr: c.querySelectorAll('wbr').length }));
  return { busy: sec.getAttribute('aria-busy'), texte: sec.querySelector('.vf-sy-corps').textContent, lis, chemins, groupes: [...sec.querySelectorAll('h4')].map((h) => h.textContent), nbUl: sec.querySelectorAll('ul.vf-sy-groupe').length,
    bilan: (sec.querySelector('.vf-sy-bilan') || {}).textContent || '', pied: (sec.querySelector('.vf-sy-pied') || {}).textContent || '', relire: !!sec.querySelector('button.btn'), xss: !!window.__xss }; })()`;

const MQ = `window.__nbMQ()`;
const FETCH = `(() => { const reel = window.fetch; window.__mode = ''; window.__nbMethode = 0;
  window.fetch = function (u, o) { if (!/\\/api\\/vf\\/methode/.test(String(u))) return reel.call(this, u, o); window.__nbMethode++;
    if (window.__mode === 'echec') return Promise.resolve(new Response('x', { status: 500 }));
    if (window.__mode === 'tenir') return new Promise((r) => { window.__liberer = () => r(new Response('x', { status: 500 })); });
    return reel.call(this, u, o); }; })()`;

export async function jouer(chrome, port, nom) {
  await executer(chrome, async (s) => {
    const base = `http://127.0.0.1:${port}`, r = { nom }, erreurs = [], panneau = `document.getElementById('panel')`;
    await s.send('Runtime.enable'); s.ecouter('Runtime.exceptionThrown', (p) => erreurs.push(String(p.exceptionDetails?.exception?.description || p.exceptionDetails?.text).slice(0, 160)));
    await largeur(s, 1440);
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_ECOUTEURS + AMORCE_VISITE + AMORCE_MQ });
    const J = await journalReseau(s), methodes = () => J.filter((x) => x.url.includes('/api/vf/methode')).length;
    await s.naviguer(base + '/project.html'); await s.attendre(`!!${BTN}`, 'bouton Synthèse posé'); await pause(400);
    r.t0 = await s.ev('performance.timeOrigin'); r.avant = { methode: methodes(), api: J.filter((x) => x.url.includes('/api/vf/') && x.methode === 'GET' && x.jeton).length };
    r.sondeMQ = await s.ev(`(() => { const q = matchMedia('(max-width: 123px)'), f = () => {}, a = ${MQ}; q.addEventListener('change', f); const b = ${MQ}; q.removeEventListener('change', f); return b - a === 1 && ${MQ} === a; })()`);
    await s.ev(FETCH);
    if (nom === 'main') { // la lecture est lente (1 s) : l'état « en cours » se lit avant l'arrivée
      await s.ev(`${BTN}.click()`); await s.attendre(OUVERTE, 'ouverte'); await s.attendre(`!!${SEC('methode')}`, 'bloc santé');
      r.attente = await s.ev(`({ busy: ${SEC('methode')}.getAttribute('aria-busy'), texte: ${SEC('methode')}.querySelector('.vf-sy-corps').textContent })`);
      await s.ev(`(() => { const p = ${panneau}; p.scrollTop = 120; const b = document.querySelector('[data-temoin-bouton]'); if (b) b.focus({ preventScroll: true });
        window.__muts = 0; new MutationObserver((l) => { window.__muts += l.length; }).observe(p.querySelector('.sr'), { childList: true, characterData: true, subtree: true }); })()`);
      r.avantArrivee = { focus: await s.ev(FOCUS), scroll: await s.ev(`${panneau}.scrollTop`) };
      await lu(s); await pause(300);
      r.apresArrivee = { focus: await s.ev(FOCUS), scroll: await s.ev(`${panneau}.scrollTop`), sr: await s.ev(`${panneau}.querySelector('.sr').textContent`), muts: await s.ev('window.__muts') };
    } else { await ouvrir(s); await lu(s); await pause(300); }
    r.blocs = await s.ev(BLOCS); r.apres = { methode: methodes() }; r.bu = await s.ev(BU); r.ja = await s.ev(JA);
    r.compteMethode = await s.ev('window.__nbMethode');
    r.audits = { burnup: await audit(s, 'burnup'), methode: await audit(s, 'methode') };
    r.sondeAudit = await s.ev(`(() => { const sec = ${SEC('burnup')}, e = document.createElement('i'); e.style.color = 'rgb(200, 0, 0)'; sec.appendChild(e); const n = (${AUDIT})('[data-vf-sy-bloc="burnup"]').couleur.length; e.remove(); return n; })()`);
    r.interdits = await s.ev(`(() => { const t = document.getElementById('panel').innerText; return /\\/Users\\/|\\/home\\/|\\/private\\/|\\/var\\/folders/.test(t); })()`);
    if (nom === 'main') {
      // ---- mouvement réduit, largeurs, cibles de 44 px ----
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
      r.mouvement = await s.ev(`(() => { const l = [...document.querySelectorAll('[data-vf-sy-bloc="burnup"], [data-vf-sy-bloc="burnup"] *, [data-vf-sy-bloc="methode"], [data-vf-sy-bloc="methode"] *')].map((e) => { const c = getComputedStyle(e);
        return { a: c.animationName, t: c.transitionDuration.split(',').every((d) => d.trim() === '0s') }; }); return { n: l.length, animations: l.filter((x) => x.a !== 'none').length, transitions: l.filter((x) => !x.t).length }; })()`);
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'no-preference' }] });
      r.largeurs = {};
      for (const w of [700, 701]) { await largeur(s, w); await s.attendre(`!!${SEC('burnup')}`, 'bloc burn-up'); r.largeurs[w] = await stabiliser(() => s.ev(BU), { max: 8000 }); }
      await largeur(s, 800); r.cible800 = (await stabiliser(() => s.ev(BU), { max: 8000 })).details.hauteurResume; await largeur(s, 1440); await pause(300);
      // ---- erreur de la route, relecture : le focus reste sur le bouton ----
      await fermer(s); await s.ev(`window.__mode = 'echec'`); await ouvrir(s); await lu(s); await pause(300);
      r.erreur = { texte: await s.ev(`${SEC('methode')}.querySelector('.vf-sy-corps').textContent`), relire: await s.ev(`[...${SEC('methode')}.querySelectorAll('button.btn')].map((b) => b.textContent.trim())`) };
      await s.ev(`window.__mode = 'tenir'; (() => { const b = ${SEC('methode')}.querySelector('button.btn'); b.focus(); b.click(); })()`);
      await attendreValeur(() => s.ev(`window.__liberer ? 1 : 0`), (v) => v === 1, { max: 5000 });
      r.relecture = { aria: await s.ev(`${SEC('methode')}.querySelector('button.btn').getAttribute('aria-disabled')`), disabled: await s.ev(`${SEC('methode')}.querySelector('button.btn').disabled`), focus: await s.ev(FOCUS), nb: await s.ev('window.__nbMethode') };
      await s.ev(`window.__liberer()`); await lu(s); await pause(300);
      r.apresEchec = { focus: await s.ev(FOCUS), aria: await s.ev(`${SEC('methode')}.querySelector('button.btn').getAttribute('aria-disabled')`), texte: await s.ev(`${SEC('methode')}.querySelector('.vf-sy-corps').textContent`) };
      await s.ev(`window.__mode = ''; ${SEC('methode')}.querySelector('button.btn').click()`); await attendreValeur(() => s.ev(FOND), (v) => v > 0, { max: 20000 }); await pause(300);
      r.apresSucces = { lis: await s.ev(FOND), focus: await s.ev(FOCUS) };
      // ---- onglets : un seul bloc de chaque, aucun écouteur de plus, la page n'est jamais rechargée ----
      await fermer(s); await s.ev(`window.VF_COQUILLE.chargerOnglet('code')`); await s.ev(`window.VF_COQUILLE.chargerOnglet('projet')`); await s.attendre(`!!${BTN}`, 'bouton après retour');
      await pause(500); r.ecout1 = await s.ev('window.__nbEcout()'); r.mq1 = await s.ev(MQ);
      for (const o of ['code', 'projet', 'code', 'projet']) await s.ev(`window.VF_COQUILLE.chargerOnglet(${JSON.stringify(o)})`);
      await s.attendre(`!!${BTN}`, 'bouton après deux cycles'); await pause(500); r.ecout2 = await s.ev('window.__nbEcout()'); r.mq2 = await s.ev(MQ);
      await ouvrir(s); await lu(s); r.cycles = { blocs: await s.ev(BLOCS), burnup: await s.ev(`document.querySelectorAll('[data-vf-sy-bloc="burnup"]').length`), methode: await s.ev(`document.querySelectorAll('[data-vf-sy-bloc="methode"]').length`),
        memeDocument: (await s.ev('performance.timeOrigin')) === r.t0, mq3: await s.ev(MQ) };
    }
    r.csp = s.violations.length; r.erreursPage = erreurs; r.reseau = { posts: J.filter((x) => x.methode === 'POST').length, interdites: J.filter((x) => /\/api\/vf\/(doing|transcript)/.test(x.url)).length,
      lecturesSansJeton: J.filter((x) => x.url.includes('/api/vf/') && (x.type === 'Fetch' || x.type === 'XHR') && !x.jeton).length };
    return r;
  }, { csp: true });
}
