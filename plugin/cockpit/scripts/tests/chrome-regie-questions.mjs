// chrome-regie-questions.mjs <chrome> <url de base, « / » final> <scénario> : les questions en attente des cadrages dans un vrai navigateur (Phase 73, plan 73-11). UNE ligne JSON ({ erreur } sur échec nommé).
// Environnement : VF_UI = dossier ui/ du module (clé du dictionnaire de traduction), VF_FIXTURES = dossier de f1.json et sentinelle.txt (écrits par le fragment regie-rg-questions.sh).
//   rendu : F1 injectée dans l'enveloppe tenue par la page puis relire() : trois lignes, texte hostile inerte, titre égal à une clé du dictionnaire non réécrit, aucun débordement à 375 et 1 000 px, non-fuite
//   echap : clic réel sur le résumé d'un repli, Échap réel (Input.dispatchKeyEvent) : le repli se ferme, le focus va à son résumé ; un second Échap sans repli ouvert ne change rien
//   titre : un who émis par l'EventSource enveloppé (un agent qui attend) plus F1 : « (4) vous attendent », puis seulement les décisions appliquées : « (1) vous attend », puis sans agent : aucun préfixe
import fs from 'node:fs';
import path from 'node:path';
import { executer, attendreValeur, positionPosee, pause } from './chrome-session.mjs';
const [, , chrome, base, scenario] = process.argv;
const F1 = JSON.parse(fs.readFileSync(path.join(process.env.VF_FIXTURES, 'f1.json'), 'utf8'));
const SENT = fs.readFileSync(path.join(process.env.VF_FIXTURES, 'sentinelle.txt'), 'utf8');
const H = '<' + 'img src=x onerror="window.__pwn=1">', FICHIER = '.planning/workstreams/atelier/phases/VFDO-90-exemple/90-CONTEXT.md';
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); if (n !== 'who' && n !== 'reload') super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
// la carte de l'ancien onglet Équipe recharge la page quand un agent du who n'est pas dans la carte : un horodatage futur le tient en repos
const CALME = "try { sessionStorage.setItem('vf-equipe-rechargement', String(Date.now() + 800000000)); } catch {}";
const PRET = "document.readyState === 'complete' && !!document.getElementById('vf-equipe') && document.body.classList.contains('vf-regie-montee') && !!window.__vfRegieQuestions && !!window.__es && window.__es.some((e) => e.url.includes('/api/vf/events'))";
const SID = 's0000000-aaaa-bbbb-cccc-111111111111';
const AGENT = { kind: 'session', id: SID, etat: 'attend', titre: 'Atelier alpha', tree: '.', ageS: 120, dureeS: 900 };
const PUSH = (w) => `window.__es.find((x) => x.url.includes('/api/vf/events')).__emit('who', { who: { workers: ${JSON.stringify(w)} } })`;
// la valeur passe par la route du graphe Projet (VF_ETAT.lireJson), la même que celle de la 76 : l'enveloppe de la page Équipe ne porte pas le champ
const INJECTER = (v) => `(() => { window.__qval = ${JSON.stringify(v)}; if (!window.__qf) { window.__qf = true; const f = window.fetch;
  window.fetch = (u, o) => (String(u).includes('onglet=projet') ? Promise.resolve(new Response(JSON.stringify({ meta: { vf: { questions: window.__qval } } }), { status: 200, headers: { 'content-type': 'application/json' } })) : f.call(window, u, o)); }
  window.__vfRegieQuestions.relire(); })()`;
const NB = (s) => s.length;
const REPLI = 'details[data-vf-repli="decisions"]';

await executer(chrome, async (s) => {
  await s.send('Runtime.enable');
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ + CALME });
  const ouvrir = async () => { await s.naviguer(base + 'equipe.html#sans-visite'); await s.attendre(PRET, 'régie montée et flux ouvert'); };
  const pousser = async (w) => {
    await s.attendre("!!window.VF_ETAT && window.VF_ETAT.lire('connexion') === 'ouvert'", 'hello reçu');
    for (let i = 0; i < 5; i++) { await s.ev(PUSH(w)); if (await s.ev(`window.VF_ETAT.lire('who').workers.length === ${w.length}`)) return; await pause(300); }
  };
  const injecter = async (v, n) => { // une lecture initiale peut être en vol : on relit jusqu'à ce que la valeur soit prise
    for (let i = 0; i < 8; i++) { await s.ev(INJECTER(v)); if (await attendreValeur(() => s.ev("document.querySelectorAll('li[data-vf-question]').length"), (x) => x === n, { max: 1500 }) === n) return; } };
  const cle = (id) => `li[data-vf-cle="a-vous:${id}"]`;
  await ouvrir();

  if (scenario === 'rendu') {
    await injecter(F1, 3);
    const texte = (sel) => s.ev(`(document.querySelector(${JSON.stringify(sel)}) || {}).textContent || ''`);
    const lignes = await s.ev("document.querySelectorAll('li[data-vf-question]').length");
    const positif = (await texte(cle('P90-Q-01'))).includes("Choix du format d'export") && (await texte(cle('P91-Q-01'))).includes('Choix de la liste');
    const hostile = (await texte(cle('P90-Q-02'))).includes(H);
    const img = await s.ev("document.querySelectorAll('#vf-equipe img, #vf-equipe script').length");
    const pwn = await s.ev('typeof window.__pwn');
    // la traduction du squelette est une seule passe sur le balisage statique : un titre égal à une clé du dictionnaire garde son texte
    const dict = fs.readFileSync(path.join(process.env.VF_UI, '78-vf-fr-dict-a.js'), 'utf8'), m = /^\s*"([A-Za-z][^"\\]{7,60})":\s*"/m.exec(dict), cleDict = m ? m[1] : '';
    let intacte = false;
    if (cleDict) {
      await s.ev(INJECTER({ ...F1, liste: F1.liste.map((e) => (e.id === 'P91-Q-01' ? { ...e, titre: cleDict } : e)) }));
      intacte = await attendreValeur(() => texte(cle('P91-Q-01') + ' .vf-rg-nom'), (t) => t === cleDict, { max: 6000 }) === cleDict;
    }
    // largeurs : titre, question et option de 240 caractères sans espace
    const long = 'a'.repeat(240), gros = { ...F1, liste: F1.liste.map((e) => (e.id === 'P90-Q-01' ? { ...e, titre: long, question: long, options: [{ cle: 'a', texte: long }, { cle: 'b', texte: long }] } : e)) };
    const debord = async (w) => {
      await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: 800, deviceScaleFactor: 1, mobile: false });
      await s.ev(INJECTER(gros));
      await attendreValeur(() => texte(cle('P90-Q-01')), (t) => t.includes('a'.repeat(80)), { max: 6000 });
      await pause(300);
      return s.ev('Math.max(document.documentElement.scrollWidth, document.body.scrollWidth) > window.innerWidth + 1');
    };
    const debord375 = await debord(375), debord1000 = await debord(1000);
    const fichierAffiche = await s.ev(`document.getElementById('vf-equipe').textContent.includes(${JSON.stringify(FICHIER)})`);
    const sentinelle = await s.ev(`document.documentElement.outerHTML.includes(${JSON.stringify(SENT)})`);
    return { lignes: positif ? lignes : -1, hostile, img, pwn, cle: cleDict, cleIntacte: intacte, debord375, debord1000, fichierAffiche, sentinelle };
  }
  if (scenario === 'echap') {
    await injecter(F1, 3);
    await s.attendre(`!!document.querySelector('${REPLI} summary')`, 'repli des décisions');
    await s.ev(`document.querySelector('${REPLI} summary').scrollIntoView({ block: 'center' })`);
    const p = await positionPosee(s.ev, `document.querySelector('${REPLI} summary')`);
    await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: p.cx, y: p.cy, button: 'left', clickCount: 1 });
    await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: p.cx, y: p.cy, button: 'left', clickCount: 1 });
        const ouvert = await attendreValeur(() => s.ev(`document.querySelector('${REPLI}').open`), (x) => x === true, { max: 6000 }) === true;
    const echap = async () => { for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27, nativeVirtualKeyCode: 27 }); };
    await echap();
    const ferme = await attendreValeur(() => s.ev(`document.querySelector('${REPLI}').open`), (x) => x === false, { max: 6000 }) === false;
    const resume = () => s.ev(`document.activeElement === document.querySelector('${REPLI} summary')`);
    const focusResume = await resume();
    await echap(); await pause(400);
    return { ouvert, ferme, focusResume, secondFocus: await resume(), secondOuvert: await s.ev(`document.querySelector('${REPLI}').open`) };
  }
  if (scenario === 'liens') { // un clic réel sur les liens de la régie doit mener à leur cible (00-vibeflow.js annule les clics sous [data-vf-section])
    const W = { phasesHumaines: [{ phase: '90', ws: '', ref: 'n:ph-90' }], workers: [{ ...AGENT, etat: 'actif', rattachement: { etat: 'rattache', dag: 'D1', noeud: 'N1' } }] };
    const cible = async (sel, avant) => {
      await s.ev(`document.querySelector(${JSON.stringify(sel)}).click()`);
      return attendreValeur(() => s.ev('location.pathname'), (p) => /project\.html$/.test(p), { max: 6000 });
    };
    const PH = "li[data-vf-cle^=\"a-vous:phase\"] a";
    const pousseW = async (sel) => { await s.attendre("!!window.VF_ETAT && window.VF_ETAT.lire('connexion') === 'ouvert'", 'hello reçu');
      for (let i = 0; i < 5; i++) { await s.ev(`window.__es.find((x) => x.url.includes('/api/vf/events')).__emit('who', { who: ${JSON.stringify(W)} })`); await pause(300); if (await s.ev(`!!document.querySelector(${JSON.stringify(sel)})`)) return; } };
    await pousseW(PH);
    const carte = await cible(PH);
    await ouvrir(); await pousseW('button.vf-rg-tog');
    // 74 : la fiche annule vf-agent:ouvrir et le détail de ligne (.vf-rg-plus) n'est plus atteignable au clic ; le lien du nœud se mesure dans la régie, isolée de la fiche (capture sur window)
    await s.ev("window.addEventListener('vf-agent:ouvrir', (e) => e.stopImmediatePropagation(), true)");
    await s.attendre("document.querySelector('button.vf-rg-tog')", 'ligne agent');
    await s.ev("document.querySelector('button.vf-rg-tog').click()"); 
    await s.attendre("!!document.querySelector('.vf-rg-plus a.vf-link')", 'lien du nœud');
    const noeud = await cible('.vf-rg-plus a.vf-link');
    return { carte, noeud };
  }
  if (scenario === 'titre') {
    const titre = () => s.ev('document.title'), href = () => s.ev("(document.querySelector('link[rel~=\"icon\"]') || {}).href || ''");
    const hrefOrigine = await href();
    await s.ev("(() => { const b = document.createElement('button'); b.id = 'vf-t-focus'; b.textContent = 'x'; document.body.append(b); b.focus(); })()");
    await pousser([AGENT]);
    await s.ev(INJECTER(F1));
    const quatre = await attendreValeur(titre, (t) => /^\(4\)/.test(t), { max: 8000 });
    const icone4 = await attendreValeur(href, (h) => h.startsWith('data:image/svg+xml'), { max: 6000 });
    await s.ev(INJECTER({ ...F1, liste: F1.liste.filter((e) => e.etat !== 'en-attente') }));
    const un = await attendreValeur(titre, (t) => /^\(1\)/.test(t), { max: 8000 });
    await pousser([]);
    const zero = await attendreValeur(titre, (t) => !/^\(/.test(t), { max: 8000 });
    await attendreValeur(href, (h) => h === hrefOrigine, { max: 6000 });
    return { quatre, icone4: String(icone4).slice(0, 40), un, zero, hrefZero: await href(), hrefOrigine, focus: await s.ev('document.activeElement && document.activeElement.id'), n: NB(quatre) };
  }
  return { erreur: 'scénario inconnu : ' + scenario };
}, { csp: true });
