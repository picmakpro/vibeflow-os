// lancer-xss.mjs <chrome> <json> — pilote Chrome de test-cockpit-lancer-xss.sh (Phase 72, plan 72-11). UNE ligne JSON sur la sortie.
// Importe chrome-session.mjs par process.env.CHROME_SESSION (la suite l'exporte). Deux modes, choisis par le champ `mode` du JSON :
//   charge : { mode, url, q, secret, onglet, cle } — joue la page P piégée ; attend window.__xss.etape1 (la proposition est née, l'isolement de Q est mesuré) ; fait, en CLIENT LÉGITIME
//            (Node : secret et onglet de Q), lire la proposition (GET /proposition, ce qui la rend visible) puis attend son armement (arme_apres_ms lu dans la réponse, plus une marge) ;
//            pose window.__go (la charge tente alors de confirmer) ; attend window.__xss.fin ; rejoue window.open AVEC geste ; rend window.__xss + { geste, titre3, arme }.
//   titres : { mode, url } — page P NON compromise, CSP en place : violations comptées, window.__titre3 indéfini, témoin de la mesure (une balise insérée par la suite est comptée).
import { pathToFileURL } from 'node:url';
import http from 'node:http';
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, brut] = process.argv;
const a = JSON.parse(brut);

// GET /proposition comme le client légitime de Q (secret, onglet, Origin de Q) : { statut, corps }
const lire = (q, secret, onglet) => new Promise((resolve) => {
  const r = http.request({ host: '127.0.0.1', port: Number(q), path: '/proposition', method: 'GET', agent: false,
    headers: { Host: `127.0.0.1:${q}`, Origin: `http://127.0.0.1:${q}`, 'X-VF-Terminal': secret, 'X-VF-Onglet': onglet } }, (res) => {
    const m = []; res.on('data', (c) => m.push(c)); res.on('end', () => { let corps = null; try { corps = JSON.parse(Buffer.concat(m).toString('utf8')); } catch {} resolve({ statut: res.statusCode, corps }); });
  });
  r.setTimeout(5000, () => { r.destroy(); resolve({ statut: 0, corps: null }); }); r.on('error', () => resolve({ statut: 0, corps: null })); r.end();
});

await executer(chrome, async (s) => {
  if (a.mode === 'titres') {
    await s.naviguer(a.url);
    await s.attendre("document.body && document.body.innerText.includes('__titre3')", 'les titres hostiles sont affichés (en texte)', 25000);
    await s.stable('document.body.innerText.length', 'la page Projet rendue');
    const res = { violations: s.violations.length, titre3: await s.ev('typeof window.__titre3'), affiche: await s.ev("document.body.innerText.includes('onerror=window.__titre3=1')") };
    // témoin de la mesure : une balise à gestionnaire en ligne, insérée par la suite, doit être comptée comme violation de la CSP
    await s.ev("document.body.insertAdjacentHTML('beforeend', '<img src=x onerror=void(0)>'); 1");
    for (let i = 0; i < 100 && s.violations.length === res.violations; i++) await pause(100);
    res.temoin = s.violations.length - res.violations;
    return res;
  }
  await s.naviguer(a.url);
  await s.attendre('!!(window.__xss && window.__xss.debut)', "la charge de P s'exécute (window.__xss.debut)", 25000);
  await s.attendre('!!(window.__xss && window.__xss.etape1)', "la charge a proposé et mesuré l'isolement de Q (window.__xss.etape1)", 40000);
  let arme = 'proposition-jamais-vue', p = { corps: null };
  for (let i = 0; i < 100; i++) { p = await lire(a.q, a.secret, a.onglet); if (p.corps && p.corps.etat === 'en-attente') break; await pause(100); }
  if (p.corps && p.corps.etat === 'en-attente') { await pause(Number(p.corps.arme_apres_ms) + 400); arme = 'armee'; }
  await s.ev('window.__go = true');
  await s.attendre('!!window.__xss.fin', 'fin de la charge de P (window.__xss.fin)', 40000);
  const res = await s.ev('JSON.parse(JSON.stringify(window.__xss))');
  res.arme = arme; res.titre3 = await s.ev('typeof window.__titre3');
  // la même tentative window.open, avec un geste utilisateur (le bloqueur de fenêtres ne l'arrête plus) : la fenêtre s'ouvre-t-elle, son stockage est-il lisible ?
  const g = await s.send('Runtime.evaluate', { userGesture: true, awaitPromise: true, returnByValue: true, expression: `(async () => {
    const w = window.open('http://127.0.0.1:' + window.__xss.q + '/', '_blank'); if (!w) return { open: 'bloque' };
    await new Promise((r) => setTimeout(r, 1500)); let st, ec; try { w.localStorage.getItem('${a.cle}'); st = 'lisible'; } catch (x) { st = x.name; }
    try { w.localStorage.setItem('${a.cle}', 'bypassPermissions'); ec = 'inscrit'; } catch (x) { ec = x.name; }
    try { w.postMessage('lancer', '*'); } catch (x) { void x; } return { open: 'ouvert', stockage: st, ecriture: ec }; })()` });
  res.geste = g && g.result && g.result.value;
  return res;
}, { csp: a.mode === 'titres' });
