// chrome-regie-pied.mjs <chrome> <url de equipe.html> <scénario> [<json des sentinelles>] : le pied de la régie dans un vrai navigateur (Phase 73, plan 73-07). Rend UNE ligne JSON ({ erreur } sur échec nommé).
//   arbres  : bloc « Arbres de travail » replié, aucune lecture Git avant l'ouverture ; ouverture : les deux routes (une fois chacune) ; ligne 2 « N modifiés » seulement après ; relecture sur l'événement git ; 35 s sans événement : rien
//   doublon : deux arbres au même nom (A46) et deux arbres sur la même branche (jointure jamais devinée)
//   echec   : routes Git en échec : « Git est indisponible » et « Réessayer » ; puis un seul arbre : « Un seul arbre de travail. »
//   ailleurs: la ligne « Ailleurs sur ce poste » (ou rien) et le titre du document
//   fr      : une tâche « Files » et un rôle « Health » restent tels quels ; aucun texte visible hors données n'est une clé anglaise du dictionnaire
// L'EventSource de la page est enveloppé : __emit(nom, donnée) rejoue un événement du flux sans toucher le serveur ; ni who ni rechargement du serveur n'agissent.
import { executer, attendreValeur, pause } from './chrome-session.mjs';
const [, , chrome, url, scenario, brut] = process.argv;
const SENT = brut ? JSON.parse(brut) : {};
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); if (n !== 'who' && n !== 'reload') super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
// la carte de l'ancien onglet Équipe recharge la page quand un agent du who n'est pas dans la carte (au plus une fois par 15 s) : un horodatage futur le tient en repos
const CALME = "try { sessionStorage.setItem('vf-equipe-rechargement', String(Date.now() + 800000000)); } catch {}";
const PRET = "document.readyState === 'complete' && !!document.getElementById('vf-equipe') && document.body.classList.contains('vf-regie-montee') && !!window.__es && window.__es.some((e) => e.url.includes('/api/vf/events'))";
const sess = (id, etat, extra) => ({ kind: 'session', id, etat, titre: 'Atelier ' + id.slice(0, 4), tree: '.', ageS: 120, dureeS: 900, ...extra });
const ID = (n) => `s${n}000000-aaaa-bbbb-cccc-11111111111${n}`;
const GIT = /\/api\/vf\/git(\/worktrees)?(\?|$)/;

await executer(chrome, async (s) => {
  const reqs = [], exc = [];
  s.ecouter('Network.requestWillBeSent', (p) => reqs.push({ m: p.request.method, u: p.request.url }));
  s.ecouter('Runtime.exceptionThrown', (p) => exc.push(String((p.exceptionDetails || {}).text || 'exception')));
  await s.send('Network.enable'); await s.send('Runtime.enable');
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ + CALME });
  await s.naviguer(url + '#sans-visite');
  await s.attendre(PRET, 'régie montée et flux ouvert');
  const lectures = () => reqs.filter((r) => GIT.test(r.u)).map((r) => r.u.replace(/^https?:\/\/[^/]+/, '').split('?')[0]);
  const nonGet = () => reqs.filter((r) => r.m !== 'GET' && !r.u.startsWith('data:')).map((r) => r.m + ' ' + r.u.slice(0, 80));
  const pousser = async (w) => {
    await s.attendre("!!window.VF_ETAT && window.VF_ETAT.lire('connexion') === 'ouvert'", 'hello reçu');
    for (let i = 0; i < 5; i++) {
      await s.ev(`window.__es.find((x) => x.url.includes('/api/vf/events')).__emit('who', { who: { workers: ${JSON.stringify(w)} } })`);
      if (await s.ev(`window.VF_ETAT.lire('who').workers.length === ${w.length}`)) return; await pause(300);
    }
  };
  const bloc = () => s.ev(`(() => { const d = document.querySelector('#vf-equipe details.vf-rg-arbres'); if (!d) return null;
    return { ouvert: d.open, titre: (d.querySelector('summary') || {}).textContent || '', corps: (d.querySelector('.vf-rg-arbres-corps') || {}).textContent || '',
      lignes: [...d.querySelectorAll('.vf-rg-arbre')].map((l) => l.textContent), btn: [...d.querySelectorAll('.btn')].map((b) => b.textContent) }; })()`);
  const ouvrirBloc = () => s.ev("document.querySelector('#vf-equipe details.vf-rg-arbres summary').click()");
  const ligne2 = (id) => s.ev(`(() => { const li = document.querySelector('#vf-equipe li[data-vf-cle$=":${id}"]'); return li ? li.textContent : null; })()`);
  const lignesBloc = (n) => attendreValeur(bloc, (b) => b && b.lignes.length >= n, { max: 9000 });
  const emettreGit = (n) => s.ev(`window.__es.find((x) => x.url.includes('/api/vf/events')).__emit('git', { seq: ${n}, at: Date.now(), sig: 'abcdef012345' + ${n} })`);

  if (scenario === 'arbres' || scenario === 'doublon') {
    const branches = scenario === 'arbres' ? ['wa'] : ['dup', 'b1'];
    await pousser(branches.map((b, i) => sess(ID(i), 'attend', { branch: b })));
    await pause(400);
    const avant = { lectures: lectures(), bloc: await bloc(), l2: await ligne2(ID(0)) };
    await ouvrirBloc();
    const ouvert = await lignesBloc(scenario === 'arbres' ? 3 : 5);
    await attendreValeur(() => ligne2(ID(0)), (t) => /modifi/.test(String(t)) || scenario === 'doublon', { max: 6000 });
    await pause(scenario === 'doublon' ? 1500 : 300);
    const apres = { lectures: lectures(), l2: await ligne2(ID(0)), l2b: scenario === 'doublon' ? await ligne2(ID(1)) : null };
    const html = await s.ev("document.getElementById('vf-equipe').innerHTML + '\\n' + document.getElementById('vf-equipe').textContent");
    const chemins = (SENT.chemins || []).filter((c) => html.includes(c)), cd = /\bcd\s/.test(html);
    if (scenario === 'doublon') return { avant, ouvert, apres, chemins, cd, exc };
    const n1 = lectures().length;
    await emettreGit(8001); await pause(2500);
    const n2 = lectures().length;
    await pause(35000);
    return { avant, ouvert, apres, chemins, cd, signal: n2 - n1, minuterie: lectures().length - n2, nonGet: nonGet(), exc };
  }
  if (scenario === 'echec') {
    await s.ev("(() => { window.__fo = window.fetch; window.fetch = (u, o) => /\\/api\\/vf\\/git(\\/worktrees)?(\\?|$)/.test(String(u)) ? Promise.reject(new TypeError('coupé')) : window.__fo(u, o); })()");
    await ouvrirBloc();
    const ko = await attendreValeur(bloc, (b) => b && /indisponible/.test(b.corps), { max: 9000 });
    await s.ev('window.fetch = window.__fo');
    await s.ev("[...document.querySelectorAll('#vf-equipe details.vf-rg-arbres .btn')].find((b) => /Réessayer/.test(b.textContent)).click()");
    const seul = await attendreValeur(bloc, (b) => b && /Un seul arbre/.test(b.corps), { max: 9000 });
    return { ko, seul, exc };
  }
  if (scenario === 'ailleurs') {
    const ligne = () => s.ev("(() => { const e = document.querySelector('#vf-equipe .vf-rg-ailleurs'); return e && !e.hidden ? e.textContent : null; })()");
    const l = await attendreValeur(ligne, Boolean, { max: 9000 });
    await pause(500);
    return { ligne: l || null, section: await s.ev("document.getElementById('vf-equipe').textContent"), titre: await s.ev('document.title'), nonGet: nonGet(), exc };
  }
  if (scenario === 'design') {
    // 73 correctifs de fin de phase : mesures de la page à 1 440 px (panneau, hauteur de ligne, caret, détail, arbre) et du pied (arbres de travail), comparées aux JETONS par sonde
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    await s.naviguer(url + '#sans-visite');
    await s.attendre(PRET, 'régie montée et flux ouvert');
    const P = ID(0), A1 = 'a1b2c3d4e5f6', A2 = 'b9b9b9b9b9b9';
    const kid = (id, role) => ({ kind: 'subagent', id, etat: 'actif', parent: P, role, task: 'Tâche ' + role, ageS: 5, dureeS: 60, tree: '.' });
    await pousser([sess(P, 'actif', { ageS: 5 }), kid(A1, 'vf-coder'), kid(A2, 'vf-tester'), sess(ID(1), 'attend')]);
    const Q = `const q = (x, r = document) => r.querySelector(x), li = (k) => q('#vf-equipe li[data-vf-cle="au-travail:' + k + '"]');`;
    await attendreValeur(() => s.ev(`(() => { ${Q} return !!li('${A1}') && !!li('${A2}') && !!li('${P}'); })()`), Boolean, { max: 9000 });
    await pause(400);
    const page = await s.ev(`(() => { ${Q}
      const pan = q('#panel'), cs = getComputedStyle(pan), r = pan.getBoundingClientRect();
      const row = (e) => Math.round(q('.vf-rg-row', e).getBoundingClientRect().height), feuille = li('${A1}'), parent = li('${P}'), seule = q('#vf-equipe li[data-vf-cle="au-travail:${ID(1)}"]');
      const cr = q('.vf-rg-caret', parent), nom = q('.vf-rg-nom', parent), svg = cr && cr.querySelector('svg'), rc = cr && cr.getBoundingClientRect();
      return { panneau: r.width > 0 && cs.display !== 'none' && cs.visibility !== 'hidden' && cs.opacity !== '0', hFeuille: row(feuille), hParent: row(parent), hSeule: seule ? row(seule) : -1,
        caretFeuille: feuille.querySelectorAll('.vf-rg-caret').length, caretSeule: seule ? seule.querySelectorAll('.vf-rg-caret').length : -1, caretParent: parent.querySelectorAll('.vf-rg-caret').length,
        caretTaille: rc ? Math.round(rc.width) + 'x' + Math.round(rc.height) : null, caretLabel: cr ? cr.getAttribute('aria-label') : null,
        couleurCaret: svg && getComputedStyle(svg).color === getComputedStyle(nom).color, nomOuvre: !!q('button.vf-rg-tog .vf-rg-nom', feuille) }; })()`);
    // le coude et le fil de l'arbre, puis le détail : relevés contre des sondes posées à la jetons
    const arbre = await s.ev(`(() => { ${Q}
      const f = li('${A1}'), a = getComputedStyle(f, '::after'), sonde = document.createElement('div');
      sonde.style.cssText = 'border-left:1px solid var(--fil);border-bottom-left-radius:8px;position:absolute;visibility:hidden'; q('#vf-equipe').append(sonde);
      const s = getComputedStyle(sonde), out = { contenu: a.content !== 'none', largeur: a.borderLeftWidth, couleur: a.borderLeftColor === s.borderLeftColor, bas: a.borderBottomWidth, rayon: a.borderBottomLeftRadius };
      sonde.remove(); return out; })()`);
    await s.ev(`(() => { ${Q} q('button.vf-rg-tog', li('${A1}')).click(); })()`);
    const detail = await attendreValeur(() => s.ev(`(() => { ${Q}
      const d = q('.vf-rg-plus', li('${A1}')); if (!d) return null; const c = getComputedStyle(d), sonde = document.createElement('div');
      sonde.style.cssText = 'display:flex;flex-direction:column;background:var(--raise);border-radius:var(--r-ctl);padding:var(--inset-box);gap:var(--sp-8);position:absolute;visibility:hidden'; q('#vf-equipe').append(sonde);
      const s = getComputedStyle(sonde), out = { fond: c.backgroundColor === s.backgroundColor, rayon: c.borderTopLeftRadius === s.borderTopLeftRadius, marge: c.paddingTop === s.paddingTop && c.paddingLeft === s.paddingLeft, ecart: c.rowGap === s.rowGap };
      sonde.remove(); return out; })()`), Boolean, { max: 6000 });
    // le caret replie les sous-agents
    await s.ev(`(() => { ${Q} q('.vf-rg-caret', li('${P}')).click(); })()`); await pause(300);
    const replie = await s.ev(`(() => { ${Q} return { exp: q('.vf-rg-caret', li('${P}')).getAttribute('aria-expanded'), fils: getComputedStyle(li('${A1}')).display }; })()`);
    await s.ev(`(() => { ${Q} q('.vf-rg-caret', li('${P}')).click(); })()`); await pause(300);
    const rouvert = await s.ev(`(() => { ${Q} return { exp: q('.vf-rg-caret', li('${P}')).getAttribute('aria-expanded'), fils: getComputedStyle(li('${A1}')).display }; })()`);
    await ouvrirBloc(); await lignesBloc(3); await pause(300);
    const pied = await s.ev(`(() => { const d = document.querySelector('#vf-equipe details.vf-rg-arbres'), sm = d.querySelector('summary'), svg = sm.querySelector('svg'), L = [...d.querySelectorAll('.vf-rg-arbre')];
      return { hauteurs: L.map((l) => Math.round(l.getBoundingClientRect().height)), marque: sm.querySelectorAll('svg').length, couleurMarque: !!svg && getComputedStyle(svg).color === getComputedStyle(sm).color,
        pastilles: [...d.querySelectorAll('.vf-rg-arbre-pastille')].map((p) => getComputedStyle(p).backgroundColor), tiret: L.some((l) => l.textContent.includes('\\u2014')) }; })()`);
    return { page, arbre, detail, replie, rouvert, pied, exc };
  }
  if (scenario === 'fr') {
    await pousser([sess(ID(0), 'actif'), { kind: 'subagent', id: 'a0000000-aaaa-bbbb-cccc-222222222222', etat: 'actif', parent: ID(0), role: 'Health', task: 'Files', ageS: 30, dureeS: 30, tree: '.' }]);
    const texte = await attendreValeur(() => s.ev("document.getElementById('vf-equipe').textContent"), (t) => /Files/.test(t) && /Health/.test(t), { max: 6000 });
    await s.ev("(() => { const d = document.querySelector('#vf-equipe details.vf-rg-arbres summary'); if (d) d.click(); })()"); await pause(1500);
    const anglais = await s.ev(`(() => { const T = window.__vfFrT; if (typeof T !== 'function') return ['__vfFrT absent'];
      const w = document.createTreeWalker(document.getElementById('vf-equipe'), NodeFilter.SHOW_TEXT), out = [];
      for (let n = w.nextNode(); n; n = w.nextNode()) { const p = n.parentElement, t = n.nodeValue.trim();
        if (!t || !p || p.closest('code, .vf-rg-nom, .vf-rg-role') || !p.getClientRects().length) continue;
        if (String(T(t)) !== t) out.push(t); }
      return out; })()`);
    return { files: /Files/.test(texte), health: /Health/.test(texte), anglais, exc };
  }
  return { erreur: 'scénario inconnu : ' + scenario };
}, { csp: true });
