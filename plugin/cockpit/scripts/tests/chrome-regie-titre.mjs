// chrome-regie-titre.mjs <chrome> <url de base, « / » final> <scénario> : le titre de l'onglet, la pastille de favicon et l'état « lu » de la régie dans un vrai navigateur
// (Phase 73, plan 73-06). Rend UNE ligne JSON ({ erreur } sur échec nommé). Les « who » sont rejoués par l'EventSource enveloppé (aucun processus, aucun fichier du lab).
//   titre     : trois onglets sans rechargement (performance.timeOrigin), survie du préfixe, nombre d'abonnés au `who` stable d'une arrivée à l'autre, un/zéro, pastille, focus, réseau
//   lu        : survol sans écriture, clic sur « Lire le rapport » : clé par lab, identifiant et heure ; la ligne passe aux « Relus » ; aucune requête autre que GET
//   tout-lu   : « Tout marquer comme relu » dès trois lignes (style .btn), vide la section ; deux lignes : pas de bouton
//   lu-purge  : stockage préparé (24 h, valeur non numérique, identifiant hors forme, 250 valides) puis rechargement : purge et plafond de 200
//   lu-refuse : accès au stockage qui lève, posé avant la page : tout est à relire, aucune exception, pas de « Tout marquer comme relu »
import { executer, attendreValeur, positionPosee, pause } from './chrome-session.mjs';
const [, , chrome, base, scenario] = process.argv;
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); if (n !== 'who' && n !== 'reload') super.addEventListener(n, f, o); } // ni who ni rechargement du serveur : seuls nos événements agissent
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
// la carte de l'ancien onglet Équipe recharge la page quand un agent du who n'est pas dans la carte (72-vf-equipe.js, au plus une fois par 15 s) : un horodatage futur le tient en repos
const CALME = "try { sessionStorage.setItem('vf-equipe-rechargement', String(Date.now() + 800000000)); } catch {}";
const REFUS = "Object.defineProperty(window, 'localStorage', { configurable: true, get() { throw new DOMException('refus', 'SecurityError'); } });";
const PRET = "document.readyState === 'complete' && !!document.getElementById('vf-equipe') && document.body.classList.contains('vf-regie-montee') && !!window.__es && window.__es.some((e) => e.url.includes('/api/vf/events'))";
const SID = 's0000000-aaaa-bbbb-cccc-111111111111', F0 = 'f0f0f0f0f0f0';
const sess = (id, etat) => ({ kind: 'session', id, etat, titre: 'Atelier ' + id.slice(0, 4), tree: '.', ageS: 120, dureeS: 900 });
const fini = (id, i) => ({ kind: 'subagent', id, etat: 'termine', parent: SID, role: 'vf-reviewer', task: 'Relire ' + i, ageS: 600 + i, dureeS: 90, tree: '.' });
const attendent = (n) => Array.from({ length: n }, (_, i) => sess(`s${i}000000-aaaa-bbbb-cccc-11111111111${i}`, 'attend'));
const finis = (n, pre) => Array.from({ length: n }, (_, i) => fini(`${pre}${String(i).padStart(11, '0')}`, i));
const RAPPORT = `li[data-vf-cle="a-relire:${F0}"] .vf-rg-act button`;
const LIGNES = "document.querySelectorAll('[data-vf-section=\"a-relire\"] > .vf-rg-corps li').length";
const PUSH = (w) => `window.__es.find((x) => x.url.includes('/api/vf/events')).__emit('who', { who: { workers: ${JSON.stringify(w)} } })`;
const PREFIXE_LAB = 'vf-regie-lus:';
const LUS = `Object.entries(localStorage).filter(([k]) => k.startsWith('${PREFIXE_LAB}')).map(([k, v]) => ({ k, v }))`;

await executer(chrome, async (s) => {
  const reqs = [], exc = [], navs = [];
  s.ecouter('Page.frameNavigated', (p) => { if (!p.frame.parentId) navs.push(p.frame.url.slice(0, 90)); });
  s.ecouter('Network.requestWillBeSent', (p) => reqs.push({ m: p.request.method, u: p.request.url.slice(0, 120) }));
  s.ecouter('Runtime.exceptionThrown', (p) => exc.push(String((p.exceptionDetails || {}).text || 'exception')));
  s.ecouter('Runtime.consoleAPICalled', (p) => { if (p.type === 'error') exc.push('console.error'); });
  await s.send('Network.enable'); await s.send('Runtime.enable');
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ + CALME });
  if (scenario === 'lu-refuse') await s.send('Page.addScriptToEvaluateOnNewDocument', { source: REFUS });
  const ouvrir = async () => { await s.naviguer(base + 'equipe.html#sans-visite'); await s.attendre(PRET, 'régie montée et flux ouvert'); };
  // le `hello` du serveur remplace le who : on pousse une fois le flux ouvert (hello reçu), et on vérifie que la poussée a pris
  const pousser = async (w) => {
    await s.attendre("!!window.VF_ETAT && window.VF_ETAT.lire('connexion') === 'ouvert'", 'hello reçu');
    for (let i = 0; i < 5; i++) { await s.ev(PUSH(w)); if (await s.ev(`window.VF_ETAT.lire('who').workers.length === ${w.length}`)) return; await pause(300); }
  };
  const nonGet = () => reqs.filter((r) => r.m !== 'GET' && !r.u.startsWith('data:')).map((r) => r.m + ' ' + r.u);
  const pret = () => attendreValeur(() => s.ev('!!(window.__vfRegieLu && window.__vfRegieLu.lus && window.__vfRegieLu.lus())'), Boolean, { max: 8000 });
  await ouvrir();
  const n0 = navs.length;

  if (scenario === 'titre') {
    const titre = () => s.ev('document.title'), href = () => s.ev("(document.querySelector('link[rel~=\"icon\"]') || {}).href || ''");
    const origine = await s.ev('performance.timeOrigin');
    await s.ev("(() => { const b = document.createElement('button'); b.id = 'vf-t-focus'; b.textContent = 'x'; document.body.append(b); b.focus(); })()");
    const zero = { titre: await titre(), href: await href() };
    await pousser(attendent(2));
    await attendreValeur(titre, (t) => /^\(2\)/.test(t), { max: 6000 });
    const focus = await s.ev('document.activeElement && document.activeElement.id');
    const titres = { equipe: await titre() }, abonnes = [await s.ev('window.VF_ETAT.abonnes().who')];
    for (const o of ['projet', 'code', 'equipe', 'projet']) {
      await s.ev(`window.VF_COQUILLE.chargerOnglet(${JSON.stringify(o)})`);
      const t = await attendreValeur(titre, (x) => /^\(2\) vous attendent · /.test(x), { max: 6000 });
      if (!titres[o]) titres[o] = t;
      abonnes.push(await s.ev('window.VF_ETAT.abonnes().who'));
    }
    const sansRecharge = (await s.ev('performance.timeOrigin')) === origine;
    const deux = (t) => (String(t).match(/\(2\)/g) || []).length;
    await s.ev("document.dispatchEvent(new CustomEvent('vf-git:signal'))"); await pause(300);
    const signal = deux(await titre());
    await s.ev("document.title = 'x map'"); await pousser(attendent(2));
    const moteur = await attendreValeur(titre, (t) => /^\(2\) vous attendent · Projet · /.test(t), { max: 6000 });
    // simule l'aller d'onglet de la Phase 80 : le titre brut est écrit, puis l'événement de document `vf:onglet` est émis
    await s.ev("document.title = 'Projet · brut'; document.dispatchEvent(new CustomEvent('vf:onglet', { detail: { onglet: 'projet', precedent: 'equipe' } }))");
    const aller = await attendreValeur(titre, (t) => /^\(2\) vous attendent · Projet · /.test(t), { max: 3000 });
    await pousser(attendent(1));
    const un = await attendreValeur(titre, (t) => /^\(1\)/.test(t), { max: 6000 });
    const av = reqs.length;
    await pousser(attendent(2));
    await attendreValeur(href, (h) => h !== zero.href, { max: 6000 });
    const pastille = await href(), reseau = reqs.slice(av).filter((r) => !r.u.startsWith('data:') && /icon|favicon|\.svg|image/i.test(r.u)).map((r) => r.u);
    await pousser([]);
    const retour = await attendreValeur(titre, (t) => /^Projet · /.test(t), { max: 6000 });
    return { navs: navs.slice(n0), zero, change: pastille !== zero.href, deux: titres, abonnes, sansRecharge, focus, signal, moteur, aller, un, pastille: pastille.slice(0, 40), sansChiffre: !/<text/.test(decodeURIComponent(pastille)),
      reseau, csp: s.violations.slice(), retour, hrefRetour: await href(), nonGet: nonGet() };
  }
  if (scenario === 'lu') {
    await pousser([sess(SID, 'attend'), fini(F0, 0)]);
    await s.attendre(`!!document.querySelector('${RAPPORT}')`, 'ligne à relire');
    await pret();
    const avant = await s.ev(LIGNES), p = await positionPosee(s.ev, `document.querySelector('${RAPPORT}')`);
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: p.cx, y: p.cy }); await pause(600);
    const survol = await s.ev(LUS);
    await s.ev(`document.querySelector('${RAPPORT}').click()`);
    const clic = await attendreValeur(() => s.ev(LUS), (l) => l.length > 0 && l[0].v.includes(F0), { max: 8000 });
    await attendreValeur(() => s.ev(LIGNES), (n) => n === 0, { max: 6000 });
    const v = clic && clic[0] ? JSON.parse(clic[0].v) : {};
    return { avant, survol, cle: clic && clic[0] ? clic[0].k : '', ids: Object.keys(v), heureOk: Number.isFinite(v[F0]) && v[F0] <= Date.now(), apres: await s.ev(LIGNES),
      relus: await s.ev("(document.querySelector('[data-vf-section=\"a-relire\"] .vf-rg-relus summary') || {}).textContent || ''"), nonGet: nonGet() };
  }
  if (scenario === 'tout-lu') {
    const bouton = () => s.ev("(() => { const b = document.querySelector('[data-vf-tout]'); return b ? { classe: b.className, texte: b.textContent } : null; })()");
    await pousser([sess(SID, 'attend'), ...finis(3, 'c')]);
    await attendreValeur(() => s.ev(LIGNES), (n) => n === 3, { max: 6000 }); await pret();
    const trois = await bouton();
    if (trois) {
      await s.ev("document.querySelector('[data-vf-tout]').click()");
      await attendreValeur(() => s.ev(LIGNES), (n) => n === 0, { max: 6000 });
    }
    const vide = await s.ev("(() => { const v = document.querySelector('[data-vf-section=\"a-relire\"] .vf-rg-vide'); return v && !v.hidden ? v.textContent : ''; })()");
    await pousser([sess(SID, 'attend'), ...finis(2, 'd')]);
    await attendreValeur(() => s.ev(LIGNES), (n) => n === 2, { max: 6000 });
    return { trois, vide, deux: await bouton(), lignes: await s.ev(LIGNES), nonGet: nonGet() };
  }
  if (scenario === 'lu-purge') {
    const lab = await s.ev("(async () => { const r = await fetch('/api/vf/modeles', { headers: { 'x-vf-cockpit-token': window.VF_COCKPIT_SERVER.token } }); return (await r.json()).lab; })()");
    await s.ev(`(() => { const now = Date.now(), o = { vieux1: now - 25 * 3600000, nn1: 'abc', 'mauvais id!': now - 1000 };
      for (let i = 0; i < 250; i++) o['ok' + String(i).padStart(4, '0')] = now - 5000 - i * 1000;
      localStorage.setItem(${JSON.stringify(PREFIXE_LAB)} + ${JSON.stringify(lab)}, JSON.stringify(o)); })()`);
    await ouvrir(); await pret();
    const l = await attendreValeur(() => s.ev(LUS), (x) => x.length > 0 && Object.keys(JSON.parse(x[0].v)).length <= 200, { max: 8000 });
    const o = l && l[0] ? JSON.parse(l[0].v) : {};
    return { lab: typeof lab, apres: Object.keys(o).length, vieux: 'vieux1' in o, nn: 'nn1' in o, mauvais: 'mauvais id!' in o, recent: 'ok0000' in o };
  }
  if (scenario === 'lu-refuse') {
    await pousser([sess(SID, 'attend'), ...finis(3, 'e')]);
    await attendreValeur(() => s.ev(LIGNES), (n) => n === 3, { max: 6000 });
    await pause(1500);
    return { lignes: await s.ev(LIGNES), bouton: await s.ev("!!document.querySelector('[data-vf-tout]')"), exceptions: exc.length, nonGet: nonGet() };
  }
  return { erreur: 'scénario inconnu : ' + scenario };
}, { csp: true });
