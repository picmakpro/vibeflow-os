// chrome-synthese-cout.mjs — scénario navigateur du bloc « Coût » de la Synthèse (77-07), joué par chrome-synthese.mjs (mode `cout`) ; importe le banc de 77-05 tel quel.
// Outil neuf, avec sa sonde positive dans test-cockpit-synthese-cout.sh (section « B ») :
//   interceptions(s, table)   interception CDP (Fetch) de plusieurs routes à la fois ; `table` est LUE à chaque requête (statut + corps, ou `echec`, ou rien : la requête passe) ;
//                             rend { vues } (compte par route). Une seule activation de Fetch : deux appels de `intercepter` du banc se disputeraient les motifs.
// Un cas = la page est rechargée avec ses réponses de frise et d'état, la Synthèse est ouverte, le bloc est lu une fois posé (jamais dans la foulée du geste).
// Sortie : une ligne JSON { cas: { <nom>: lecture }, onglets, retour, sondes, erreursPage, csp, reseau } ou { erreur }.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
import { AMORCE_ECOUTEURS, AMORCE_VISITE, journalReseau } from './chrome-synthese.mjs';
import { frise, friseInconnu, etatCorps } from './chrome-synthese-cout-fix.mjs';

const BTN = `document.getElementById('btn-synthese')`, OUVERTE = `!!document.querySelector('#panel > .vf-sy')`, FR = '/api/vf/frise', ET = '/api/vf/state';
export async function interceptions(s, table) {
  const vues = Object.fromEntries(Object.keys(table).map((k) => [k, 0])), motifs = Object.keys(table);
  await s.send('Fetch.enable', { patterns: motifs.map((k) => ({ urlPattern: `*${k}*` })) });
  s.ecouter('Fetch.requestPaused', (p) => {
    const k = motifs.find((m) => p.request.url.includes(m)), r = k ? table[k] : null, id = p.requestId, tait = () => {};
    if (!k) { s.send('Fetch.continueRequest', { requestId: id }).catch(tait); return; }
    vues[k]++;
    if (r.echec) s.send('Fetch.failRequest', { requestId: id, errorReason: 'ConnectionFailed' }).catch(tait);
    else if (!r.statut) s.send('Fetch.continueRequest', { requestId: id }).catch(tait);
    else s.send('Fetch.fulfillRequest', { requestId: id, responseCode: r.statut, responseHeaders: [{ name: 'Content-Type', value: 'application/json' }], body: Buffer.from(r.corps || '{}').toString('base64') }).catch(tait);
  });
  return { vues };
}

const READ = `(() => { const sec = document.querySelector('[data-vf-sy-bloc="cout"]'), T = (e) => (e ? e.textContent : null), pan = document.getElementById('panel');
  const tops = {}; for (const id of ['visite', 'burnup', 'methode']) { const e = document.querySelector('[data-vf-sy-bloc="' + id + '"]'); tops[id] = e ? Math.round(e.getBoundingClientRect().top + pan.scrollTop) : null; }
  const base = { blocs: [...document.querySelectorAll('#panel > section.vf-sy[data-vf-sy-bloc]')].map((e) => e.dataset.vfSyBloc), tops, xss: window.__xss === undefined ? 'undefined' : String(window.__xss),
    nbCout: document.querySelectorAll('[data-vf-sy-bloc="cout"]').length };
  if (!sec) return { ...base, present: false };
  const tb = sec.querySelector('table'), rows = tb ? [...tb.querySelectorAll('tr.vf-sy-l')] : [];
  const cells = (tr) => [...tr.cells].map((c) => (c.querySelector('button') ? T(c.querySelector('button')) : [...c.childNodes].map(T).join('|')));
  return { ...base, present: true, hidden: sec.hidden, titre: T(sec.querySelector('h3')), texte: sec.textContent, tables: sec.querySelectorAll('table').length,
    ths: tb ? [...tb.tHead.rows[0].cells].map((c) => c.textContent + '|' + c.getAttribute('scope')) : [], labelled: tb ? tb.getAttribute('aria-labelledby') : null,
    labelledOk: tb ? !!document.getElementById(tb.getAttribute('aria-labelledby')) : false, lignes: rows.map(cells),
    etages: rows.map((tr) => [...tr.nextElementSibling.querySelectorAll('li')].map((li) => li.textContent)), details: rows.map((tr) => tr.querySelectorAll('button[aria-expanded]').length),
    total: tb && tb.tFoot ? cells(tb.tFoot.rows[0]) : null, notes: [...sec.querySelectorAll('.vf-sy-corps > p')].map((p) => p.textContent),
    imgs: sec.querySelectorAll('img, script').length, on: sec.querySelectorAll('[onerror], [onclick]').length, nodes: sec.querySelectorAll('*').length }; })()`;
// géométrie de la lecture « à la largeur du panneau » : panneau de 360 px, première ligne dépliée
const GEO = `(() => { const tb = document.querySelector('[data-vf-sy-bloc="cout"] table'); if (!tb) return null; const b = tb.querySelector('button.vf-sy-plie'); if (b && b.getAttribute('aria-expanded') !== 'true') b.click();
  const tw = tb.getBoundingClientRect().width, det = tb.querySelector('tr.vf-sy-e:not([hidden]) td'), lh = (e) => parseFloat(getComputedStyle(e).lineHeight) || 16;
  const caches = [...tb.querySelectorAll('.vf-sy-cache')]; return { panneau: Math.round(document.getElementById('panel').getBoundingClientRect().width), table: Math.round(tw), nCaches: caches.length,
    lignesCache: Math.max(0, ...caches.map((e) => Math.round(e.getBoundingClientRect().height / lh(e)))), detail: det ? Math.round(det.getBoundingClientRect().width) : 0,
    debordement: tb.scrollWidth > tb.clientWidth + 1, ouvert: b ? b.getAttribute('aria-expanded') : null }; })()`;
const largeur = async (s, w) => { await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 900, deviceScaleFactor: 1, mobile: false }); await pause(200); };
const ouvrir = async (s) => {
  if (!(await s.ev(OUVERTE))) await s.ev(`${BTN}.click()`);
  await s.attendre(OUVERTE, 'Synthèse ouverte'); await s.attendre(`!!document.querySelector('[data-vf-sy-bloc="methode"]')`, 'bloc santé posé');
};
const fermer = async (s) => { if (await s.ev(OUVERTE)) { await s.ev(`${BTN}.click()`); await attendreValeur(() => s.ev(`!${OUVERTE}`), (v) => v === true, { max: 3000 }); } };
const lire = async (s) => { // le bloc est caché ou absent tant que la frise n'a pas répondu : on attend sa réponse, puis la stabilité
  await attendreValeur(() => s.ev(READ), (v) => v && (v.present === false || v.hidden === false), { max: 20000 });
  return stabiliser(() => s.ev(READ), { max: 8000 });
};

const ok = (corps, statut = 200) => ({ statut, corps: JSON.stringify(corps) });
const CAS = [
  ['absent404', ok({ erreur: 'introuvable' }, 404)], ['schemaInconnu', ok({ schema: 'vibeflow/autre@1', voies: [] })],
  ['b400bornes', ok({ erreur: 'bornes-invalides' }, 400)], ['b400champs', ok({ erreur: 'champs-invalides' }, 400)], ['b403', ok({ erreur: 'interdit' }, 403)],
  ['b503', ok({ erreur: 'emission-refusee' }, 503)], ['b500', ok({ erreur: 'panne' }, 500)], ['echeance', { echec: true }],
  ['complet', ok(frise())], ['tronque3', ok(frise({ tronque: true, voiesOmises: 3 }))], ['tronque1', ok(frise({ tronque: true, voiesOmises: 1 }))],
  ['tronque0', ok(frise({ tronque: true, voiesOmises: 0 }))], ['enConstruction', ok(frise({ etat: 'en-construction', voies: [] }))],
  ['enConstructionVoies', ok(frise({ etat: 'en-construction' }))], ['okVide', ok(frise({ voies: [] }))], ['partielle', ok(frise({ etat: 'partielle' }))],
  ['formeInconnue', ok(frise({ etat: 'forme-inconnue', voies: [] }))], ['indisponibleEtat', ok(frise({ etat: 'indisponible', voies: [] }))], ['inconnu', ok(friseInconnu())],
];

export async function jouer(chrome, port) {
  await executer(chrome, async (s) => {
    const base = `http://127.0.0.1:${port}`, r = { cas: {}, sondes: {} }, erreurs = [];
    await s.send('Runtime.enable'); s.ecouter('Runtime.exceptionThrown', (p) => erreurs.push(String(p.exceptionDetails?.exception?.description || p.exceptionDetails?.text).slice(0, 160)));
    await largeur(s, 1440);
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: AMORCE_ECOUTEURS + AMORCE_VISITE });
    const J = await journalReseau(s), table = { [FR]: {}, [ET]: ok(etatCorps()) }, { vues } = await interceptions(s, table);
    const charger = async () => { await s.naviguer(base + '/project.html'); await s.attendre(`!!${BTN}`, 'bouton Synthèse posé'); await pause(300); };
    const jouerCas = async (nom, fr, et) => {
      table[FR] = fr; table[ET] = et || ok(etatCorps()); const avant = vues[FR];
      await charger(); await ouvrir(s); r.cas[nom] = await lire(s); r.cas[nom].reqFrise = vues[FR] - avant;
      if (nom === 'complet') { await s.ev(GEO); await pause(300); r.cas[nom].geo = await stabiliser(() => s.ev(GEO), { max: 5000 }); }
    };
    for (const [nom, fr] of CAS) await jouerCas(nom, fr);
    await jouerCas('xss', ok(frise()), ok(etatCorps({ nom78: '<img src=x onerror="window.__xss=1">PIEGE' })));
    await jouerCas('sansEtat', ok(frise()), ok({ erreur: 'panne' }, 500));
    // sondes positives : la page voit la réponse interceptée ; un symbole de monnaie injecté est vu par la regex de la suite
    table[FR] = ok(frise()); table[ET] = ok(etatCorps()); await charger(); await ouvrir(s); await lire(s);
    r.sondes.intercepte = await s.ev(`window.VF_ETAT.lireJson('${FR}').then((j) => j.schema + ':' + j.voies.length)`);
    r.sondes.vues = vues[FR];
    r.sondes.monnaie = await s.ev(`(() => { const c = document.querySelector('[data-vf-sy-bloc="cout"] .vf-sy-corps'), i = document.createElement('i'); i.textContent = '12 € et 3 dollars'; c.appendChild(i);
      const t = document.querySelector('[data-vf-sy-bloc="cout"]').textContent; i.remove(); return t; })()`);
    // onglets : la route répondait 404, elle répond maintenant ; deux cycles d'onglets, un seul bloc, un seul abonnement, la page jamais rechargée
    table[FR] = ok({ erreur: 'introuvable' }, 404); await charger(); await ouvrir(s); r.retour = { avant: await lire(s) };
    r.retour.t0 = await s.ev('performance.timeOrigin'); r.retour.abonnes0 = await s.ev(`window.VF_ETAT.abonnes().frise`);
    await fermer(s); table[FR] = ok(frise()); await s.ev(`window.VF_COQUILLE.chargerOnglet('code')`); await s.ev(`window.VF_COQUILLE.chargerOnglet('projet')`);
    await s.attendre(`!!${BTN}`, 'bouton après retour'); await pause(500); const ecout1 = await s.ev('window.__nbEcout()');
    await ouvrir(s); r.retour.apres = await lire(s); r.retour.abonnes1 = await s.ev(`window.VF_ETAT.abonnes().frise`);
    await fermer(s);
    for (const o of ['code', 'projet', 'code', 'projet']) await s.ev(`window.VF_COQUILLE.chargerOnglet(${JSON.stringify(o)})`);
    await s.attendre(`!!${BTN}`, 'bouton après deux cycles'); await pause(500); const v2 = vues[FR]; await ouvrir(s); const apres2 = await lire(s);
    r.onglets = { nbCout: apres2.nbCout, abonnes: await s.ev(`window.VF_ETAT.abonnes().frise`), memeDocument: (await s.ev('performance.timeOrigin')) === r.retour.t0, reqOuverture: vues[FR] - v2,
      ecoutAvant: ecout1, ecoutApres: await s.ev('window.__nbEcout()'), blocs: apres2.blocs };
    r.csp = s.violations.length; r.erreursPage = erreurs;
    r.reseau = { posts: J.filter((x) => x.methode === 'POST').length, interdites: J.filter((x) => /\/api\/vf\/(doing|transcript)/.test(x.url)).length,
      sansJeton: J.filter((x) => x.url.includes('/api/vf/') && (x.type === 'Fetch' || x.type === 'XHR') && !x.jeton).length, gets: J.filter((x) => x.methode === 'GET' && x.jeton).length };
    return r;
  }, { csp: true });
}
