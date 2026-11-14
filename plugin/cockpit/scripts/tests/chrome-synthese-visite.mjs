// chrome-synthese-visite.mjs — scénarios navigateur du bloc « Depuis votre dernière visite » (77-08), joués par chrome-synthese.mjs (mode `visite`). Une ligne JSON.
//   complet  V1 à V10, W4 à W7 (deux thèmes), W11, W12, W13v, W15, OB1, sondes positives des outils ajoutés au banc
//   xss      l'état V2 seul, pour le mutant M-INNER (le texte piégé du STATE est rendu sans échappement)
// Le lab est celui de labDeuxEtats (4 commits, un blocage piégé dans le STATE). Les valeurs gardées sont posées AVANT le chargement (stockageAvant), jamais après.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
import { AMORCE_ECOUTEURS, AMORCE_VISITE, journalReseau, stockageLu, stockageAvant, intercepter, deuxiemeOnglet, MARQUEUR_RACINE } from './chrome-synthese.mjs';

const BTN = `document.getElementById('btn-synthese')`, OUVERTE = `!!document.querySelector('#panel > .vf-sy')`;
const BLOC = `document.querySelector('#panel > section[data-vf-sy-bloc="visite"]')`;
const RESUME = `(() => { const e = document.querySelector('[data-vf-sy-resume] .rn'); return e ? e.textContent : null; })()`;
const FICHE = `(() => { const b = ${BLOC}; if (!b) return null; const t = (q) => [...b.querySelectorAll(q)].map((e) => e.textContent.trim());
  return { etat: ((b.querySelector('[data-vf-sy-v]') || {}).dataset || {}).vfSyV || null, texte: (b.querySelector('.vf-sy-corps') || b).innerText.replace(/\\s+/g, ' ').trim(), toutVu: t('[data-vf-sy-toutvu]'),
    liens: [...b.querySelectorAll('a')].map((a) => a.getAttribute('href') + '|' + a.textContent.trim()), mots: t('.vst'), lignes: b.querySelectorAll('.vf-link').length }; })()`;
const FOCUS = `(() => { const a = document.activeElement; return a ? { tag: a.tagName, id: a.id || '', k: a.dataset.vfK || '', dansBloc: !!a.closest('[data-vf-sy-bloc="visite"]') } : null; })()`;
const ORDRE = `[...document.querySelectorAll('#panel > section.vf-sy[data-vf-sy-bloc]')].map((e) => e.dataset.vfSyBloc)`;
const FAITS = `(async () => { const C = window.__vfSyntheseCalcul, M = window.__vfSyntheseMemoire, E = window.VF_ETAT, SC = window.VibeFlow;
  const lab = (await E.lireJson('/api/vf/modeles')).lab, g = await E.lireJson('/api/vf/git'), et = E.lire('etat') || await E.lireJson('/api/vf/state');
  const brut = et && et.signal ? C.depuisSignal(et.signal) : C.depuisGraphe(SC.graph, E.lire('who'));
  const bl = C.blocagesPresents({ missions: brut.missions, workers: brut.equipe.workers, blocagesState: SC.graph.meta.vf.blocagesState });
  return { lab, cle: M.cle(lab), phases: Object.fromEntries(brut.phases.map((p) => [p.key, p.avancement.etat])), tete: g.base && g.base.h,
    racine: (g.rangees.find((r) => r.racine) || {}).h, blocages: bl.map((b) => b.cle) }; })()`;
const STYLE = `(() => {
  const els = [...document.querySelectorAll('#panel .vf-sy, #panel .vf-sy *')];
  const num = (c) => { const m = /(?:rgba?|color)\\(([^)]*)\\)/.exec(c); if (!m) return null; const p = m[1].replace('srgb', '').split(/[\\s,\\/]+/).filter(Boolean).map(Number);
    const k = /srgb/.test(c) ? 255 : 1; return { rgb: p.slice(0, 3).map((x) => x * k), a: p.length > 3 ? p[3] : 1 }; };
  const neutre = (c) => { const n = num(c); return !n || n.a === 0 || Math.max(...n.rgb) - Math.min(...n.rgb) <= 2; };
  const lu = (css) => { const d = document.createElement('div'); d.style.background = css; document.getElementById('panel').appendChild(d); const v = getComputedStyle(d).backgroundColor; d.remove(); return v; };
  const fonds = new Set(['var(--raise-2)', 'rgba(var(--ink), .06)', 'var(--surface-hover)'].map(lu));
  const GRILLE = new Set([0, 2, 4, 6, 8, 12, 16, 20, 24, 32]), TAILLES = new Set([20, 13.5, 12.5, 11]), POIDS = new Set(['400', '500', '600']), POLICES = new Set(['Inter', 'JetBrains Mono']);
  const mal = { couleur: [], fond: [], ombre: [], liseres: [], espace: [], taille: [], graisse: [], police: [] };
  for (const e of els) {
    const c = getComputedStyle(e), id = e.tagName.toLowerCase() + '.' + String(e.getAttribute('class') || '').split(' ')[0];
    for (const p of ['color', 'fill', 'stroke', 'border-top-color', 'border-right-color', 'border-bottom-color', 'border-left-color', 'outline-color']) if (!neutre(c.getPropertyValue(p))) mal.couleur.push(id + ' ' + p);
    for (const q of ['::before', '::after']) { const pc = getComputedStyle(e, q); if (pc.content !== 'none' && (!neutre(pc.color) || !neutre(pc.backgroundColor))) mal.couleur.push(id + q); }
    if (!neutre(c.backgroundColor) || (num(c.backgroundColor).a > 0 && !fonds.has(c.backgroundColor))) mal.fond.push(id + ' ' + c.backgroundColor);
    if (c.boxShadow !== 'none' || c.filter !== 'none') mal.ombre.push(id);
    for (const p of ['border-left-color', 'border-top-color', 'outline-color']) if (!neutre(c.getPropertyValue(p))) mal.liseres.push(id + ' ' + p);
    const sr = c.position === 'absolute' && parseFloat(c.width) <= 1; // la zone vive masquée : ses décalages sont ceux de sa place, pas un espacement
    for (const p of ['padding-top', 'padding-right', 'padding-bottom', 'padding-left', 'margin-top', 'margin-right', 'margin-bottom', 'margin-left', 'row-gap', 'column-gap', 'top', 'left', 'right', 'bottom']) {
      if (sr && /^(top|left|right|bottom)$/.test(p)) continue;
      const v = c.getPropertyValue(p); if (/^-?[0-9.]+px$/.test(v) && !GRILLE.has(Math.abs(parseFloat(v)))) mal.espace.push(id + ' ' + p + '=' + v);
    }
    if (!TAILLES.has(parseFloat(c.fontSize))) mal.taille.push(id + ' ' + c.fontSize);
    if (!POIDS.has(c.fontWeight)) mal.graisse.push(id + ' ' + c.fontWeight);
    if (!POLICES.has(c.fontFamily.split(',')[0].replace(/["']/g, '').trim())) mal.police.push(id + ' ' + c.fontFamily.slice(0, 30));
  }
  return { n: els.length, mal: Object.fromEntries(Object.entries(mal).map(([k, v]) => [k, v.slice(0, 6)])) };
})()`;
const SONDE_W4 = `(() => { const d = document.createElement('div'); d.className = 'vf-sy'; d.style.cssText = 'color: rgb(200, 10, 10); background-color: rgb(10, 10, 200)'; d.id = 'sonde-w4';
  document.getElementById('panel').appendChild(d); const r = ${STYLE}; d.remove(); return r; })()`;

const maintenant = () => Math.floor(Date.now() / 1000);
const inst = (vu, o) => ({ vu, phases: o.phases, tete: o.tete, blocages: o.blocages });
const val = (prec, cour) => JSON.stringify({ v: 1, precedente: prec, courante: cour });
const CRAN = { fait: 'en-cours', 'a-recetter': 'en-cours', 'en-cours': 'a-faire', 'a-faire': 'a-faire' };
// l'état d'avant : chaque phase d'un cran en arrière, la dernière phase absente, le sommet à la racine, un ancien blocage (levé depuis)
const avant = (f) => ({ phases: Object.fromEntries(Object.keys(f.phases).slice(0, -1).map((k) => [k, CRAN[f.phases[k]]])), tete: f.racine, blocages: ['0123456789ab'] });
const identique = (f) => ({ phases: f.phases, tete: f.tete, blocages: f.blocages });

async function charger(s, base, valeur) {
  const retirer = valeur === undefined ? null : await stockageAvant(s, s.cle, valeur);
  await s.naviguer(base + '/project.html'); if (retirer) await retirer();
  await s.attendre(`!!${BTN}`, 'bouton Synthèse posé');
}
const ouvrir = async (s) => { if (!(await s.ev(OUVERTE))) { await s.ev(`${BTN}.click()`); await s.attendre(OUVERTE, 'Synthèse ouverte'); } await pause(250); };
const fermer = async (s) => { if (await s.ev(OUVERTE)) { await s.ev(`${BTN}.click()`); await attendreValeur(() => s.ev(`!${OUVERTE}`), (v) => v === true, { max: 3000 }); } };
// la ligne-résumé (Synthèse fermée) une fois les données arrivées : jamais la première lecture vide qui se « stabilise » avant l'arrivée
const resumeLu = async (s) => { await attendreValeur(() => s.ev(RESUME), (v) => !!v, { max: 10000 }); return stabiliser(() => s.ev(RESUME), { max: 6000 }); };
async function fiche(s) { await attendreValeur(() => s.ev(RESUME), (v) => !!v, { max: 10000 }); await ouvrir(s); return stabiliser(() => s.ev(FICHE), { max: 6000 }); }
const stylePose = async (s, theme) => { await s.ev(`document.documentElement.setAttribute('data-theme', ${JSON.stringify(theme)})`); await pause(300); return stabiliser(() => s.ev(STYLE), { max: 5000 }); };

export async function jouer(chrome, port, mode) {
  await executer(chrome, async (s) => {
    const base = `http://127.0.0.1:${port}`, r = { mode }, erreurs = [];
    await s.send('Runtime.enable'); s.ecouter('Runtime.exceptionThrown', (p) => erreurs.push(String(p.exceptionDetails?.exception?.description || p.exceptionDetails?.text).slice(0, 160)));
    s.ecouter('Runtime.consoleAPICalled', (p) => { if (p.type === 'error') erreurs.push('console.error ' + String((p.args[0] || {}).value).slice(0, 120)); });
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(150);
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_ECOUTEURS + AMORCE_VISITE
      + `(() => { window.__ecr = 0; const S = Storage.prototype.setItem; Storage.prototype.setItem = function (k, v) { if (/derniere-visite/.test(String(k))) window.__ecr++; return S.call(this, k, v); }; })();` });
    const J = await journalReseau(s);
    // ---- V1 : première visite (profil neuf), et les faits du lab ----
    await s.naviguer(base + '/project.html'); await s.attendre(`!!${BTN}`, 'bouton Synthèse posé');
    r.faits = await s.ev(FAITS); s.cle = r.faits.cle; const f = r.faits;
    r.cles0 = Object.keys(await stockageLu(s, null)).filter((k) => k !== 'vf-cockpit:panel'); r.session0 = await s.ev(`JSON.stringify(Object.entries(sessionStorage))`);
    r.v1 = { resume: await resumeLu(s), fiche: await fiche(s) };
    if (mode === 'complet') await sondes(s, base, r, f);
    const v2 = val(null, inst(maintenant() - 7200, avant(f)));
    // ---- V2 : repère d'il y a deux heures (la valeur tourne au chargement) ----
    await charger(s, base, v2); r.v2 = { resume: await resumeLu(s), fiche: await fiche(s), titre: await s.ev(`${BTN}.getAttribute('aria-label')`), garde: await stockageLu(s, s.cle) };
    r.w12 = await s.ev(`({ prose: document.documentElement.innerText.includes('MARQUEUR-PROSE-77') || document.getElementById('panel').innerHTML.includes('MARQUEUR-PROSE-77'),
      cle: Object.prototype.hasOwnProperty.call(window.VibeFlow.graph.meta.vf, 'lastDesc') })`);
    r.w15 = await s.ev(`({ xss: typeof window.__xss, on: document.querySelectorAll('#panel .vf-sy [onerror], #panel .vf-sy [onclick], #btn-synthese[onclick]').length,
      attrs: [...document.querySelectorAll('#panel .vf-sy *, #btn-synthese')].filter((e) => [...e.attributes].some((a) => /^on/i.test(a.name))).length,
      img: document.querySelectorAll('#panel img').length, texte: ${BLOC}.innerText.includes('blocage piégé') })`);
    r.csp = s.violations.length;
    if (mode === 'xss') return r;
    r.ordre = await s.ev(ORDRE);
    r.w4 = { clair: await stylePose(s, 'light'), sombre: await stylePose(s, 'dark') }; await s.ev(`document.documentElement.setAttribute('data-theme', 'dark')`);
    // ---- V3 : courante de dix minutes, pas de rotation ----
    await charger(s, base, val(inst(maintenant() - 7200, avant(f)), inst(maintenant() - 600, identique(f)))); r.v3 = { fiche: await fiche(s), garde: JSON.parse(await stockageLu(s, s.cle)) };
    // ---- V4 : visite de plus de 24 h, état identique : la réserve des 24 h, jamais un zéro ----
    await charger(s, base, val(null, inst(maintenant() - 90000, identique(f)))); r.v4 = { fiche: await fiche(s) };
    // ---- V6 : valeur corrompue ----
    const e0 = erreurs.length; await charger(s, base, 'ceci {n est pas du json'); r.v6 = { fiche: await fiche(s), erreurs: erreurs.length - e0 };
    // ---- V5 : identifiant de lab non reçu ----
    const i5 = await intercepter(s, '/api/vf/modeles', { statut: 500, corps: '{}' }); await charger(s, base, null);
    r.v5 = { resume: await resumeLu(s), fiche: await fiche(s), vues: i5.vues() }; await s.naviguer(base + '/'); r.v5.cles = Object.keys(await stockageLu(s, null)).filter((k) => /derniere-visite/.test(k)); await i5.arreter();
    // ---- V9 : git en panne ----
    const i9 = await intercepter(s, '/api/vf/git', { statut: 500, corps: '{}' }); await charger(s, base, v2); r.v9 = { fiche: await fiche(s), vues: i9.vues() }; await i9.arreter();
    // ---- V11 : dépôt lisible mais base inconnue (base.h nul) : jamais « rien de nouveau » sur la foi des commits ----
    const i11 = await intercepter(s, '/api/vf/git', { statut: 200, corps: JSON.stringify({ etat: 'ok', base: { nom: null, h: null }, rangees: [] }) });
    await charger(s, base, val(null, inst(maintenant() - 7200, identique(f)))); r.v11 = { fiche: await fiche(s), resume: null, vues: i11.vues() };
    await fermer(s); r.v11.resume = await resumeLu(s); await i11.arreter();
    // ---- V12 : visite précédente sans sommet (tete nul), git de nouveau lisible avec des commits arrivés : « non lus », jamais « rien de nouveau » ----
    await charger(s, base, val(null, inst(maintenant() - 7200, { ...identique(f), tete: null }))); r.v12 = { fiche: await fiche(s) };
    // ---- V7, V10, OB1 : sur l'état V2 ----
    await charger(s, base, v2); await fiche(s); r.ob1 = await s.ev(ORDRE); await fermer(s);
    r.ecout0 = await s.ev('window.__nbEcout()'); const origine = await s.ev('performance.timeOrigin');
    for (const o of ['code', 'projet', 'code', 'projet']) await s.ev(`window.VF_COQUILLE.chargerOnglet(${JSON.stringify(o)})`);
    await s.attendre(`!!${BTN}`, 'bouton après deux cycles'); await resumeLu(s); const ecout1 = await s.ev('window.__nbEcout()'), lignes1 = await s.ev(`document.querySelectorAll('[data-vf-sy-resume]').length`); await ouvrir(s);
    const ecr0 = await s.ev('window.__ecr');
    await s.ev(`(() => { Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => 'hidden' }); document.dispatchEvent(new Event('visibilitychange')); delete document.visibilityState; })()`); await pause(300);
    r.v10 = { ecout: ecout1, blocs: await s.ev(`document.querySelectorAll('[data-vf-sy-bloc="visite"]').length`), lignes: lignes1,
      ecritures: (await s.ev('window.__ecr')) - ecr0, memeDocument: (await s.ev('performance.timeOrigin')) === origine };
    await s.naviguer(base + '/'); const garde = JSON.parse((await stockageLu(s, s.cle)) || 'null');
    r.v7 = { v: garde && garde.v, ageS: garde && garde.courante ? maintenant() - garde.courante.vu : null, cles: garde ? Object.keys(garde) : null };
    // ---- V8, W13v : « Tout vu », puis un second onglet ----
    await charger(s, base, v2); await fiche(s); await tout(s, base, r);
    r.w11 = await w11(s, J, r);
    r.reseau = reseau(J); r.erreursPage = erreurs; r.marqueur = MARQUEUR_RACINE;
    return r;
  }, { csp: true });
}

async function sondes(s, base, r, f) {
  r.sondes = { w4: (await s.ev(SONDE_W4)).mal.couleur.length };
  await s.ev(`localStorage.setItem('vf-sonde-77', 'x')`); r.sondes.stockage = await stockageLu(s, 'vf-sonde-77'); await s.ev(`localStorage.removeItem('vf-sonde-77')`);
  const i = await intercepter(s, '/api/vf/modeles', { statut: 200, corps: '{"lab":"sondesondeabc"}' });
  r.sondes.intercepte = await s.ev(`window.VF_ETAT.lireJson('/api/vf/modeles').then((j) => j.lab)`); await i.arreter();
  r.sondes.interceptions = i.vues();
  r.sondes.difference = await s.ev(`(async () => { const C = window.__vfSyntheseCalcul; const f = ${JSON.stringify(f)}, a = ${JSON.stringify(avant(f))};
    const pres = C.instantane({ phases: f.phases, tete: f.tete, blocages: f.blocages, vu: 5000 }), pre = C.instantane({ ...a, vu: 100 });
    const g = await window.VF_ETAT.lireJson('/api/vf/git'); const d = C.difference(pre, pres, { rangees: g.rangees, sommet: f.tete, gitLu: true, workers: [], maintenant: 5000 });
    return { vide: d.vide, commits: d.commits.n, phases: d.phases.length }; })()`);
  const t2 = await deuxiemeOnglet(s, base + '/project.html');
  await s.ev(`window.__sto = []; window.addEventListener('storage', (e) => window.__sto.push(e.key))`); await t2.ev(`localStorage.setItem('vf-sonde-77b', '1')`); await pause(500);
  r.sondes.storage2 = await s.ev(`window.__sto.includes('vf-sonde-77b')`); await t2.ev(`localStorage.removeItem('vf-sonde-77b')`); await t2.fermer(); await s.send('Page.bringToFront');
}

async function tout(s, base, r) {
  const t2 = await deuxiemeOnglet(s, base + '/project.html'); await s.send('Page.bringToFront'); await t2.ev(`window.__vfK = 1`);
  await attendreValeur(() => t2.ev(`(document.querySelector('[data-vf-sy-resume] .rn') || {}).textContent || ''`), (v) => /^Depuis votre dernière visite/.test(v), { max: 10000 });
  r.w13v = { avant2: await t2.ev(`document.activeElement.tagName + '#' + document.activeElement.id`), titre2: await t2.ev(`${BTN}.title`) };
  await ouvrir(s); await s.ev(`document.querySelector('${'#panel [data-vf-sy-bloc="visite"] a.vf-link'}').focus({ preventScroll: true })`);
  r.w13v.focusLien = await s.ev(FOCUS); await s.ev(`document.getElementById('panel').scrollTop = 0`);
  // une écriture qui n'avance que l'heure de la courante : le rendu ne change pas, le focus non plus
  await t2.ev(`(() => { const k = ${JSON.stringify(s.cle)}, o = JSON.parse(localStorage.getItem(k)); o.courante.vu += 1; localStorage.setItem(k, JSON.stringify(o)); })()`); await pause(600);
  r.w13v.focusApresDonnees = await s.ev(FOCUS);
  r.avantClic = maintenant(); await s.ev(`document.querySelector('${'#panel [data-vf-sy-bloc="visite"] [data-vf-sy-toutvu]'}').click()`); await pause(500);
  r.v8 = { fiche: await stabiliser(() => s.ev(FICHE), { max: 5000 }), titre: await s.ev(`${BTN}.getAttribute('aria-label')`), focus: await s.ev(FOCUS),
    sr: await s.ev(`document.querySelector('#panel .vf-sy .sr').textContent`), garde: JSON.parse(await stockageLu(s, s.cle)) };
  await fermer(s); r.v8.resume = await resumeLu(s); // la ligne-résumé n'est dans l'aperçu que Synthèse fermée
  await attendreValeur(() => t2.ev(`(document.querySelector('[data-vf-sy-resume] .rn') || {}).textContent || ''`), (v) => /^Rien de nouveau/.test(v), { max: 10000 });
  r.w13v.resume2 = await t2.ev(`(document.querySelector('[data-vf-sy-resume] .rn') || {}).textContent`); r.w13v.titre2Apres = await t2.ev(`${BTN}.title`);
  r.w13v.apres2 = await t2.ev(`document.activeElement.tagName + '#' + document.activeElement.id`); r.w13v.sr2 = await t2.ev(`(document.querySelector('#panel .vf-sy .sr') || { textContent: '' }).textContent`);
  await t2.fermer(); await s.send('Page.bringToFront');
}

async function w11(s, J, r) {
  const k = await stockageLu(s, null), cles = Object.keys(k).filter((x) => x !== 'vf-cockpit:panel'), nouvelles = cles.filter((x) => !r.cles0.includes(x));
  const val = k[s.cle]; const ok = await s.ev(`(() => { const t = localStorage.getItem(${JSON.stringify(s.cle)}); return t !== null && window.__vfSyntheseMemoire.lire(t) !== null; })()`);
  return { nouvelles, octets: val === undefined ? -1 : new TextEncoder().encode(val).length, relue: ok, v: JSON.parse(val || '{}').v, session: (await s.ev(`JSON.stringify(Object.entries(sessionStorage))`)) === r.session0,
    visiteGuidee: cles.filter((x) => /^vibeflow-cockpit:visite:|tour-seen/.test(x)) };
}
const reseau = (J) => { const api = J.filter((x) => x.url.includes('/api/vf/')); return { posts: J.filter((x) => x.methode === 'POST').length, interdites: J.filter((x) => /\/api\/vf\/(doing|transcript)/.test(x.url)).length,
  gets: api.filter((x) => x.methode === 'GET' && x.jeton).length, sansJeton: api.filter((x) => (x.type === 'Fetch' || x.type === 'XHR') && !x.jeton).length }; };
