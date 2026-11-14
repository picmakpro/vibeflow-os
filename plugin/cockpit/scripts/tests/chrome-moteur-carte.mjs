// chrome-moteur-carte.mjs — témoins de comportement du moteur de carte (lot 1, étape M4), dans un vrai Chrome headless.
// Usage : node chrome-moteur-carte.mjs <chrome> <racine-du-serveur> <identifiant-de-session-équipe>
//   UN Chrome, plusieurs pages (en anglais : ?lang=en, pour que les libellés du moteur soient lus tels qu'il les écrit, sans le dictionnaire).
//   Chaque mesure est interrogée dans la page (jamais une durée fixe pour décider d'un état). Rend une ligne JSON { <clé>: valeur } ou { erreur }.
//   Clés : panneau · modale · noms · stats · document · encart · echap · rangees · feuille · retour · jalon · pastille · info · bague · halo · equipe
//   M5 : colonnes · titres · retour059 · reponse · tableau · dedoublon
import { executer, pause, stabiliser, attendreValeur, attendreEtStabiliser, positionPosee } from './chrome-session.mjs';
const [, , chrome, racine, equipeSession] = process.argv;
const BASE = racine;
const U = (page) => `${racine}/${page}?lang=en`;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";

await executer(chrome, async (s) => {
  const o = {};
  const vue = (w, h, touch = false) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: touch });
  // vue posée = rendu terminé (go() remet l'opacité à 0 puis à 1 une fois la nouvelle vue dessinée) ET transition de caméra finie (classe anim retirée)
  const VUE_POSEE = "(() => { const v = document.querySelector('#viewport'); return !!v && v.style.opacity !== '0' && !v.classList.contains('anim'); })()";
  const lireVue = () => s.ev(`JSON.stringify({ c: VibeFlow.state.container, t: VibeFlow.state.t, n: document.querySelectorAll('#viewport .node').length, r: [...document.querySelectorAll('#viewport .node .card')].slice(0, 40).map((e) => { const r = e.getBoundingClientRect(); return [Math.round(r.x), Math.round(r.y), Math.round(r.width)]; }), p: (document.querySelector('#panel') || { innerText: '' }).innerText })`);
  const poserVue = async () => { await s.attendre(VUE_POSEE, 'vue posée'); await stabiliser(lireVue, { pas: 120, max: 5000 }); };
  const chargerUrl = async (url, nom) => { await s.naviguer(url); await s.attendre(PRET, `page prête (${nom})`); await s.attendre("!!document.querySelector('#viewport .node')", `cartes (${nom})`); await poserVue(); };
  const charger = (page) => chargerUrl(U(page), page);
  const touche = async (key, code, vk) => { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); };
  const echap = () => touche('Escape', 'Escape', 27);
  const clic = async (x, y) => { await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
  const aller = async (id) => { await s.ev(`VibeFlow.go(${JSON.stringify(id)})`); await s.attendre(`VibeFlow.state.container === ${JSON.stringify(id)} && !!document.querySelector('#viewport .node')`, `vue ${id}`); await poserVue(); };
  // montrer la fiche d'un fichier : la carte de son dossier s'affiche et la fiche s'ouvre (select seul ne vaut que pour une carte déjà visible)
  const fiche_de = async (id) => { await s.ev(`VibeFlow.reveal(${JSON.stringify(id)})`); await s.attendre(`VibeFlow.state.selected === ${JSON.stringify(id)} && !!document.querySelector('#panel h2')`, `fiche ${id}`); await poserVue(); };
  // réponse de l'assistant simulée : la page parle à un flux d'événements, on le remplace par un flux fixe (une réponse longue, quatre cartes)
  const REPONSE = `(() => { const ids = [...VibeFlow.nodes.keys()].slice(0, 4).map((k) => 'n:' + k);
    const ans = { title: 'Réponse', answer: Array.from({ length: 12 }, (_, i) => 'Paragraphe ' + (i + 1) + ' de la réponse, assez long pour occuper de la place dans la bulle.').join('\\n\\n'), items: ids, steps: [], followups: [] };
    const f = window.fetch; window.fetch = (u, x) => String(u).includes('/api/ask') ? Promise.resolve(new Response('event: answer\\ndata: ' + JSON.stringify(ans) + '\\n\\n')) : f(u, x); })()`;
  const poser = (q) => s.ev(`(() => { const i = document.querySelector('#ask-input'); i.value = ${JSON.stringify(q)}; document.querySelector('#ask-form').requestSubmit(); })()`);

  // ---------- page Code, 1 280 x 720 ----------
  await vue(1280, 720); await charger('index.html');
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  // la visite guidée s'ouvre d'elle-même au premier passage (profil jetable : toujours) : on l'attend (borne 30 s), puis on la ferme, pour mesurer la carte seule
  await s.attendre("!!document.querySelector('#tour') && !document.querySelector('#tour').hidden", 'visite ouverte', 30000).catch(() => {});
  await echap(); await s.attendre("!document.querySelector('#tour') || document.querySelector('#tour').hidden", 'visite fermée'); await stabiliser(() => s.ev("JSON.stringify([!document.querySelector('#tour') || document.querySelector('#tour').hidden, document.activeElement && document.activeElement.tagName])"), { pas: 150, max: 3000 });

  // PU-G-014 : fenêtre « Exporter une copie » — focus dedans à l'ouverture, Échap la ferme et rend le focus, clic sur le fond la ferme
  await s.ev("document.querySelector('#btn-export').focus()");
  await s.ev("document.querySelector('#btn-export').click()");
  await s.attendre("document.querySelector('#modal').classList.contains('open')", 'fenêtre ouverte');
  const m = { dedans: await attendreValeur(() => s.ev("document.querySelector('#modal').contains(document.activeElement)"), (v) => v === true, { max: 3000 }) };
  const surPage = await s.ev('(() => { const st = VibeFlow.state; return st.container + "|" + st.selected; })()');
  await echap();
  m.echap = await attendreValeur(() => s.ev("!document.querySelector('#modal').classList.contains('open')"), (v) => v === true, { max: 3000 });
  m.rendu = await attendreEtStabiliser(() => s.ev("document.activeElement && document.activeElement.id"), (v) => v === 'btn-export', { pas: 100, max: 3000 });
  m.pageIntacte = (await s.ev('(() => { const st = VibeFlow.state; return st.container + "|" + st.selected; })()')) === surPage;
  await s.ev("document.querySelector('#btn-export').click()");
  await s.attendre("document.querySelector('#modal').classList.contains('open')", 'fenêtre rouverte');
  await clic(10, 300);
  m.fond = await attendreValeur(() => s.ev("!document.querySelector('#modal').classList.contains('open')"), (v) => v === true, { max: 3000 });
  o.modale = m;

  // PU-G-018 : noms accessibles de la flèche d'envoi et de la copie du chemin
  await fiche_de('f:plugin/mod/scripts/run.sh');
  o.noms = { envoi: await s.ev("document.querySelector('#ask-send').getAttribute('aria-label')"), chemin: await s.ev("(document.querySelector('#panel .pp button') || { getAttribute() {} }).getAttribute('aria-label')") };

  // PU-G-058 : « détail technique » ne change ni les statistiques ni les libellés de la fiche d'un fichier
  const fiche = () => s.ev(`JSON.stringify({ stats: [...document.querySelectorAll('#panel .stats > div')].map((d) => d.innerText.replace(/\\s+/g, ' ').trim()), liens: [...document.querySelectorAll('#panel .row .rc')].map((e) => e.innerText.trim()) })`);
  // setTechnical redessine la vue (draw() remplace les nœuds) : on attend que l'ancien nœud ait quitté la page, puis la fiche se pose
  const basculerTechnique = async (on) => { await s.ev(`window.__vieux = document.querySelector('#viewport .node'); VibeFlow.setTechnical(${on})`); await attendreValeur(() => s.ev('!window.__vieux || !document.contains(window.__vieux)'), (v) => v === true, { max: 5000 }); };
  await basculerTechnique(false); await fiche_de('f:plugin/mod/scripts/run.sh');
  const simple = JSON.parse(await stabiliser(fiche, { pas: 150, max: 5000 }));
  await basculerTechnique(true); await fiche_de('f:plugin/mod/scripts/run.sh');
  const tech = JSON.parse(await stabiliser(fiche, { pas: 150, max: 5000 }));
  await basculerTechnique(false);
  o.stats = { simple, tech, identique: JSON.stringify(simple.stats) === JSON.stringify(tech.stats) && simple.stats.length > 0 };

  // PU-G-072 : fiche d'un document — « Mentions » et une phrase d'explication, ni « Depends on » ni « calls »
  await fiche_de('f:plugin/mod/README.md');
  o.document = JSON.parse(await s.ev(`JSON.stringify({ titres: [...document.querySelectorAll('#panel h3')].map((h) => h.innerText.replace(/\\s+\\d+$/, '').trim()), note: (document.querySelector('#panel h3 + p.pd') || { innerText: '' }).innerText, liens: [...document.querySelectorAll('#panel .row .rc')].map((e) => e.innerText.trim()) })`));

  await fiche_de('f:plugin/mod/scripts/check.sh');
  o.script = { titres: JSON.parse(await s.ev("JSON.stringify([...document.querySelectorAll('#panel h3')].map((h) => h.innerText.replace(/\\s+\\d+$/, '').trim()))")) };

  // PU-G-074 : encart des noms générés — la commande réelle et un bouton qui la copie
  await aller('root');
  await s.ev("window.__cp = null; navigator.clipboard.writeText = (t) => { window.__cp = t; return Promise.resolve(); }");
  o.encart = { texte: await attendreEtStabiliser(() => s.ev("(document.querySelector('#panel .callout') || { innerText: '' }).innerText"), (v) => !!v && v.length > 0, { max: 5000 }), bouton: await s.ev("!!document.querySelector('#panel .callout [data-copycmd]')") };
  await s.ev("(document.querySelector('#panel .callout [data-copycmd]') || { click() {} }).click()");
  o.encart.copie = await attendreValeur(() => s.ev('window.__cp'), (v) => v !== null && v !== undefined, { max: 3000 });

  // PU-G-174 / PU-G-175 : lignes du panneau au clavier, Échap avec le focus hors du canevas
  const conteneurs = JSON.parse(await s.ev("JSON.stringify([...VibeFlow.nodes.keys()].map((k) => 'n:' + k).filter((k) => VibeFlow.children(k).length > 0).slice(0, 3))"));
  await aller(conteneurs[0]); await s.ev("VibeFlow.select(null)");
  o.rangees = JSON.parse(await attendreEtStabiliser(() => s.ev(`JSON.stringify({ total: document.querySelectorAll('#panel a.row[data-go]').length, auClavier: document.querySelectorAll('#panel a.row[data-go][tabindex="0"]').length })`), (v) => JSON.parse(v).total > 0, { max: 5000 }));
  const avant = await s.ev('VibeFlow.state.container');
  await s.ev("(() => { const a = document.querySelector('#panel a.row[data-go]'); a && a.focus(); })()");
  const surLigne = await s.ev("!!document.activeElement.closest('#panel')");
  await echap(); await pause(500);
  const apresLigne = await s.ev('VibeFlow.state.container');
  await s.ev("document.activeElement && document.activeElement.blur()");
  await echap();
  const apresCanevas = await attendreEtStabiliser(() => s.ev('VibeFlow.state.container'), (v) => v !== avant, { max: 5000 });
  o.echap = { surLigne, avant, apresLigne, apresCanevas };

  // PU-G-013 : l'anneau de focus de l'en-tête vaut à toutes les largeurs (règle hors de tout @media)
  o.bague = await s.ev(`(() => { for (const sh of document.styleSheets) { let r; try { r = sh.cssRules; } catch { continue; } for (const x of r) if (x.selectorText && /header \\.btn:focus-visible/.test(x.selectorText)) return true; } return false; })()`);

  // halo du repérage : l'impulsion est un contour neutre, sans ombre diffuse, et dure 700 ms au plus
  o.halo = await s.ev(`(() => { for (const sh of document.styleSheets) { let r; try { r = sh.cssRules; } catch { continue; } for (const x of r) if (x.type === 7 && x.name === 'flash') return { ombre: /box-shadow/.test(x.cssText), regle: x.cssText.slice(0, 160) }; } return { ombre: null, regle: 'absente' }; })()`);
  o.halo.duree = await s.ev(`(() => { const d = document.createElement('div'); d.className = 'node flash'; d.innerHTML = '<div class="card"></div>'; document.querySelector('#viewport').appendChild(d); const v = getComputedStyle(d.firstChild).animationDuration; d.remove(); return parseFloat(v) * (/ms$/.test(v) ? 1 : 1000); })()`);

  // PU-G-149 / PU-G-148 : bulle de réponse — hauteur limitée, refermée au changement de vue ; « Retour » revient à la carte d'où partait la question
  await charger('index.html'); await s.ev(REPONSE);
  await aller(conteneurs[0]);
  await poser('Que fait ce module ?');
  await s.attendre("!document.querySelector('#ask-sheet').hidden && VibeFlow.state.container === 'q:answer'", 'réponse affichée');
  const ph = await positionPosee(s.ev, "document.querySelector('#ask-sheet')");
  const f = { h: ph ? ph.h : 0, vh: await s.ev('innerHeight') };
  o.feuille = { hauteur: f.h, fenetre: f.vh, part: Math.round((100 * f.h) / f.vh) };
  await s.ev("document.querySelector('#ask-sheet [data-act=\"map\"]').click()");
  await s.attendre("VibeFlow.state.container !== 'q:answer'", 'retour de la réponse');
  o.retour = { depart: conteneurs[0], arrivee: await attendreEtStabiliser(() => s.ev('VibeFlow.state.container'), (v) => v === conteneurs[0], { max: 5000 }), bulleGardee: await stabiliser(() => s.ev("!document.querySelector('#ask-sheet').hidden"), { pas: 120, max: 3000 }) };
  await aller(conteneurs[1] || 'root');
  o.jalon = { bulleRefermee: await attendreValeur(() => s.ev("document.querySelector('#ask-sheet').hidden"), (v) => v === true, { max: 3000 }) };

  // ---------- page Projet : état réel des nœuds d'une mission (PU-G-105) ----------
  await vue(1280, 720); await charger('project.html');
  const mission = await s.ev("[...VibeFlow.nodes.keys()].find((k) => /^dag-/.test(k)) || ''");
  await aller('n:' + mission);
  o.pastille = JSON.parse(await stabiliser(() => s.ev(`JSON.stringify({ mission: ${JSON.stringify(mission)}, lignes: [...document.querySelectorAll('#panel .row .rc')].map((e) => e.innerText.trim()), pastilles: document.querySelectorAll('#panel .row .rc .vst').length })`), { pas: 150, max: 5000 }));
  const c = await positionPosee(s.ev, `(() => { const cs = [...document.querySelectorAll('#viewport .node .card')].filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.right < innerWidth - 340 && r.top > 130; }); return cs[0]; })()`);
  if (c) {
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 5, y: 5, button: 'none' });
    for (const dx of [-30, -10, 0, 3]) { await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: c.cx + dx, y: c.cy, button: 'none' }); await pause(120); }
    await s.attendre("!document.querySelector('#tooltip').hidden && document.querySelector('#tooltip').innerText.length > 0", 'infobulle de carte');
  }
  o.info = { texte: await s.ev("(document.querySelector('#tooltip') || { innerText: '' }).innerText"), pastille: await s.ev("!!document.querySelector('#tooltip .vst')") };
  // PU-G-036 : la même infobulle, en français (sans ?lang=en) — « Clic droit : plus d'actions »
  await chargerUrl(`${BASE}/project.html`, 'français');
  const cf = await positionPosee(s.ev, `(() => { const cs = [...document.querySelectorAll('#viewport .node .card')].filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.right < innerWidth - 340 && r.top > 130; }); return cs[0]; })()`);
  if (cf) {
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 5, y: 5, button: 'none' });
    for (const dx of [-30, -10, 0, 3]) { await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: cf.cx + dx, y: cf.cy, button: 'none' }); await pause(120); }
    await s.attendre("!document.querySelector('#tooltip').hidden && document.querySelector('#tooltip .th')", 'infobulle de carte (français)');
  }
  o.infoFr = { texte: await s.ev("(document.querySelector('#tooltip .th') || { textContent: '' }).textContent") };
  // PU-G-035 (recette du 2026-11-08) : l'infobulle d'une carte survolée ne revient pas après une navigation par la recherche. Le pointeur ne bouge pas : la fenêtre de recherche (plein écran) se ferme,
  // la carte de l'ancienne vue se retrouve sous lui (mouseenter, minuterie de 420 ms), puis la vue est redessinée sans que cette carte reçoive de mouseleave : l'infobulle s'affichait sur la nouvelle vue.
  // Attendu : fermée, ou — si une carte de la NOUVELLE vue se trouve sous le pointeur — celle de cette carte seulement. L'absence se constate après le délai de la minuterie (pause délibérée : on ne peut pas attendre une absence).
  const INFO = "(() => { const t = document.querySelector('#tooltip'); return { visible: !t.hidden && getComputedStyle(t).display !== 'none', titre: ((t.querySelector('.tt') || {}).textContent || '').trim() }; })()";
  const infobulleApresRecherche = async (page, w, h, requete, rang) => {
    await vue(w, h); await chargerUrl(U(page), `recherche ${page} ${w}`);
    await s.ev("(() => { try { const T = window.VibeFlowTour; if (T && T.active()) T.end(); } catch (e) { void e; } })()");
    await attendreValeur(() => s.ev("(() => { const t = document.getElementById('tour'); return !t || t.hidden; })()"), (v) => v === true, { max: 5000 }); await poserVue();
    const c = await positionPosee(s.ev, `(() => { const cs = [...document.querySelectorAll('#viewport .node .card')].filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.left > 0 && r.right < innerWidth - (innerWidth >= 1000 ? 340 : 0) && r.top > 130 && r.bottom < innerHeight; }); return ${JSON.stringify(rang)} === 'dernier' ? cs[cs.length - 1] : cs[0]; })()`); // la carte survolée est choisie loin de l'endroit où la nouvelle vue se pose : une carte de la nouvelle vue sous le pointeur remplacerait la minuterie périmée (et masquerait le défaut)
    if (!c) return { erreur: 'aucune carte survolable' };
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 5, y: 5, button: 'none' });
    for (const dx of [-30, -10, 0, 3]) { await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: c.cx + dx, y: c.cy, button: 'none' }); await pause(120); }
    await s.attendre("!document.querySelector('#tooltip').hidden && document.querySelector('#tooltip').innerText.length > 0", `infobulle de carte (${page} ${w})`);
    const avant = await s.ev(INFO), depart = await s.ev('VibeFlow.state.container');
    await touche('/', 'Slash', 191); await s.attendre("document.activeElement && document.activeElement.id === 'search'", 'recherche ouverte');
    await s.send('Input.insertText', { text: requete });
    await s.attendre("document.querySelectorAll('#palette .r, #palette [role=option], #palette .result').length > 0 || document.querySelector('#palette').innerText.length > 40", 'résultats de recherche');
    await pause(300); await touche('Enter', 'Enter', 13);
    await s.attendre("!document.querySelector('#palette').classList.contains('open')", 'recherche refermée');
    await attendreValeur(() => s.ev('VibeFlow.state.container'), (v) => v !== depart, { max: 5000 }); await poserVue();
    await pause(1000);
    const apres = await s.ev(INFO);
    const sous = await s.ev(`(() => { const e = document.elementFromPoint(${c.cx + 3}, ${c.cy}); const k = e && e.closest ? e.closest('.card') : null; return k ? k.innerText : ''; })()`);
    return { avant, depart, arrivee: await s.ev('VibeFlow.state.container'), apres, coherente: !apres.visible || (!!apres.titre && sous.includes(apres.titre)) };
  };
  o.infoRecherche = { code1440: await infobulleApresRecherche('index.html', 1440, 900, 'run.sh', 'premier'), code768: await infobulleApresRecherche('index.html', 768, 1024, 'run.sh', 'premier'), projet1440: await infobulleApresRecherche('project.html', 1440, 900, 'Suite', 'dernier') };
  // PU-G-050 (Code seulement) : un fichier de la recherche porte son vrai nom et son dossier à droite ; sur Projet les éléments ne sont pas des fichiers (carte de BACKLOG, exigence, plan) : leur titre reste le titre lisible
  const resultatsRecherche = async (page, requete) => {
    await vue(1440, 900); await chargerUrl(U(page), `titres de recherche ${page}`);
    await s.ev("(() => { try { const T = window.VibeFlowTour; if (T && T.active()) T.end(); } catch (e) { void e; } })()");
    await touche('/', 'Slash', 191); await s.attendre("document.activeElement && document.activeElement.id === 'search'", 'recherche ouverte');
    await s.send('Input.insertText', { text: requete });
    await attendreValeur(() => s.ev("document.querySelectorAll('#results .r').length"), (v) => v > 0, { max: 5000 });
    return JSON.parse(await stabiliser(() => s.ev("JSON.stringify([...document.querySelectorAll('#results .r')].slice(0, 12).map((r) => ({ titre: ((r.querySelector('.rn') || {}).textContent || '').trim(), droite: ((r.querySelector('.rdr, .rk') || {}).textContent || '').trim(), dossier: !!r.querySelector('.rdr'), pointEnTete: (() => { const e = r.querySelector('.rdr'); const t = e && (e.querySelector('bdi') || e).firstChild; if (!t || t.nodeType !== 3 || t.length < 2) return null; const g = document.createRange(); g.setStart(t, 0); g.setEnd(t, 1); const a = g.getBoundingClientRect().left; g.setStart(t, 1); g.setEnd(t, 2); return a < g.getBoundingClientRect().left; })(), geo: (() => { const e = r.querySelector('.rdr'), b = e && e.querySelector('bdi'); if (!b) return null; const E = e.getBoundingClientRect(), B = b.getBoundingClientRect(); return { bdiDroite: Math.round(B.right), colDroite: Math.round(E.right), bdiGauche: Math.round(B.left), colGauche: Math.round(E.left), largeurChemin: Math.round(B.width), rogne: getComputedStyle(e).overflowX }; })(), coupeParLaGauche: (() => { const e = r.querySelector('.rdr'); if (!e) return null; const c = getComputedStyle(e); return c.direction === 'rtl' && c.textOverflow === 'ellipsis'; })() })))"), { pas: 150, max: 4000 }));
  };
  o.titresRecherche = { code: await resultatsRecherche('index.html', 'run.sh'), codePoint: await resultatsRecherche('index.html', 'verif.sh'), coupeLong: await resultatsRecherche('index.html', 'verifier-long.sh'), projet: await resultatsRecherche('project.html', 'socle') };
  // PU-G-100 : le sens des liens entre phases. Le panneau d'une phase dit ce que la phase attend (« Dépend de ») et ce qu'elle débloque (« Utilisé par ») ; l'ordre des cartes, lui, ne bouge pas
  await vue(1280, 720); await chargerUrl(`${BASE}/project.html`, 'phases');
  const phases = JSON.parse(await s.ev(`JSON.stringify([...VibeFlow.nodes.keys()].filter((k) => /^ph-/.test(k)))`));
  await aller('n:ms-phases');
  const ordre = JSON.parse(await s.ev(`JSON.stringify(VibeFlow.state.layout.children.filter((c) => /^n:ph-/.test(c.id)).sort((a, b) => a.x - b.x || a.y - b.y).map((c) => c.id))`));
  const panneauPhase = async (id) => { await s.ev(`VibeFlow.reveal(${JSON.stringify('n:' + id)})`); await s.attendre(`VibeFlow.state.selected === ${JSON.stringify('n:' + id)} && !!document.querySelector('#panel h2')`, `fiche ${id}`); await poserVue();
    return JSON.parse(await stabiliser(() => s.ev(`JSON.stringify({ titres: [...document.querySelectorAll('#panel .sec h3')].map((e) => e.firstChild.textContent.trim()).filter((t) => /^(Utilisé par|Dépend de|Used by|Depends on)$/.test(t)), lignes: [...document.querySelectorAll('#panel .sec')].filter((e) => /^(Utilisé par|Dépend de|Used by|Depends on)/.test(e.querySelector('h3')?.textContent.trim() || '')).flatMap((e) => [...e.querySelectorAll('.row .rn')].map((r) => r.textContent.trim())) })`), { pas: 150, max: 5000 })); };
  o.sens = { phases, p1: await panneauPhase(phases[0] || 'ph-1'), p2: await panneauPhase(phases[1] || 'ph-2'), ordre };

  // ---------- panneau de détail par défaut : fermé à 768 px, ouvert à 1 024 px (PU-G-045) ----------
  const ouvertA = async (w, h) => { await vue(w, h); await charger('index.html'); return stabiliser(() => s.ev("!document.body.classList.contains('no-panel') && document.querySelector('#btn-panel').getAttribute('aria-expanded') === 'true'"), { pas: 150, max: 3000 }); };
  o.panneau = { a768: await ouvertA(768, 1024), a1024: await ouvertA(1024, 768) };

  // ---------- onglet Équipe à 390 px : une seule colonne (PU-G-176) ----------
  await vue(390, 844, true); await charger('equipe.html');
  await aller('n:ag-' + equipeSession);
  o.equipe = JSON.parse(await stabiliser(() => s.ev(`JSON.stringify((() => { const cs = [...document.querySelectorAll('#viewport .node .card')].map((e) => e.getBoundingClientRect()).filter((r) => r.width > 0); return { cartes: cs.length, colonnes: new Set(cs.map((r) => Math.round(r.left / 20))).size, debordent: cs.filter((r) => r.right > innerWidth + 1 || r.left < -1).length }; })())`), { pas: 150, max: 5000 }));
  // ---------- M5 : diagnostics de viewer.html (DG-12 colonnes, DG-04 vue de réponse, DG-03 compteurs, PU-G-049 homonymes) ----------
  await vue(1280, 720); await charger('index.html');
  // DG-12 / PU-G-040 : une carte sans aucun lien, dans la vue d'une partie qui a des liens avec l'extérieur, se range dans la colonne « Inside … », jamais sous « Used by »
  await aller('n:m-mod.scripts');
  o.colonnes = JSON.parse(await s.ev(`JSON.stringify((() => { const ch = VibeFlow.state.layout.children; const ins = ch.filter((c) => c.id.startsWith('x:in:')); const seul = ch.find((c) => c.id === 'f:plugin/mod/scripts/seul.sh'); const droite = Math.max(...ins.map((c) => c.x + c.width));
    return { appelants: ins.length, seul: !!seul, seulX: seul ? Math.round(seul.x) : null, droiteDesAppelants: Math.round(droite), apres: !!seul && seul.x >= droite, chevauche: ch.some((a) => ch.some((b) => a !== b && a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height)) }; })())`));
  // titres de colonnes : leur hauteur à l'écran, à l'ouverture puis la carte éloignée (le titre ne rapetisse pas avec elle)
  const hauteurs = async () => JSON.parse(await s.ev("JSON.stringify([...document.querySelectorAll('#viewport .cols text')].map((t) => Math.round(t.getBoundingClientRect().height)))"));
  o.titres = { ouverture: await stabiliser(hauteurs, { pas: 120, max: 3000 }), k0: await s.ev('VibeFlow.state.t.k') };
  for (let i = 0; i < 2; i++) { const kAvant = await s.ev('VibeFlow.state.t.k'); await s.ev("document.querySelector('#z-out').click()"); await attendreValeur(() => s.ev('VibeFlow.state.t.k'), (v) => v !== kAvant, { max: 3000 }); }
  await attendreValeur(() => s.ev("!document.querySelector('#viewport').classList.contains('anim')"), (v) => v === true, { max: 5000 });
  o.titres.eloigne = await stabiliser(hauteurs, { pas: 120, max: 3000 }); o.titres.k1 = await stabiliser(() => s.ev('VibeFlow.state.t.k'), { pas: 120, max: 3000 });

  // DG-04 / PU-G-059 : la carte revient à la vue d'ensemble (Échap, ou le fil d'Ariane) : le panneau de droite redevient « Base de code », sans la réponse
  await charger('index.html');
  const panneau = () => s.ev("(document.querySelector('#panel h2') || { innerText: '' }).innerText");
  const racine = await attendreEtStabiliser(panneau, (v) => !!v && v.length > 0, { pas: 150, max: 5000 });
  const TABLEAU = "VibeFlow.showBoard({ kind: 'Answer', title: 'Titre du tableau', question: 'Q', items: ['f:plugin/mod/README.md', 'f:plugin/mod/scripts/run.sh'] })";
  const montrer = async () => { await s.ev(TABLEAU); await s.attendre("VibeFlow.state.container === 'q:answer' && !!document.querySelector('#viewport .node')", 'tableau montré'); await poserVue(); };
  await montrer(); const surTableau = await attendreEtStabiliser(panneau, (v) => v === 'Titre du tableau', { pas: 150, max: 5000 });
  await s.ev('document.body.focus()'); await echap(); await s.attendre("VibeFlow.state.container === 'root'", 'vue d\'ensemble (Échap)'); await poserVue();
  const viaEchap = { vue: await s.ev('VibeFlow.state.container'), titre: await attendreEtStabiliser(panneau, (v) => v === racine, { pas: 150, max: 5000 }), selection: await s.ev('String(VibeFlow.state.selected)') };
  await montrer();
  await s.ev("[...document.querySelectorAll('#crumbs button')][0].click()"); await s.attendre("VibeFlow.state.container === 'root'", 'vue d\'ensemble (fil)'); await poserVue();
  const viaFil = { vue: await s.ev('VibeFlow.state.container'), titre: await attendreEtStabiliser(panneau, (v) => v === racine, { pas: 150, max: 5000 }), selection: await s.ev('String(VibeFlow.state.selected)') };
  o.retour059 = { racine, surTableau, viaEchap, viaFil };

  // DG-04 / PU-G-143, PU-G-144 : une réponse sans carte n'a pas de tableau — ni bouton « Show answer board », ni tableau de la question d'avant, ni erreur
  const REPONDRE = (ans) => `(() => { window.__ans = ${JSON.stringify(ans)}; if (!window.__mockAsk) { window.__mockAsk = true; const f = window.fetch; window.fetch = (u, x) => String(u).includes('/api/ask') ? Promise.resolve(new Response('event: answer\\ndata: ' + JSON.stringify(window.__ans) + '\\n\\n')) : f(u, x); } })()`;
  const avecCartes = { title: 'Premier tableau', answer: 'Voici des cartes.', items: ['n:m-mod', 'f:plugin/mod/README.md', 'f:plugin/mod/scripts/run.sh', 'f:plugin/mod/scripts/check.sh'], steps: [], followups: [] };
  const sansCarte = { title: 'Sans carte', answer: 'Aucune carte pour celle-ci.', items: [], steps: [], followups: [] };
  const attendreFeuille = (texte) => s.attendre(`!document.querySelector('#ask-sheet').hidden && document.querySelector('#ask-sheet .sb').innerText.includes(${JSON.stringify(texte)})`, `réponse « ${texte} »`);
  const feuille = () => s.ev("JSON.stringify({ bouton: !!document.querySelector('#ask-sheet [data-act=\"board\"]'), vue: VibeFlow.state.container, titre: (document.querySelector('#context h1') || { innerText: '' }).innerText, erreurs: window.__errs.length })").then(JSON.parse);
  await charger('index.html');
  await s.ev("window.__errs = []; addEventListener('unhandledrejection', (e) => window.__errs.push(String((e.reason && e.reason.message) || e.reason))); addEventListener('error', (e) => window.__errs.push(String(e.message)))");
  await s.ev(REPONDRE(sansCarte)); await poser('Une question sans carte ?'); await attendreFeuille('Aucune carte'); await pause(400);
  const frais = await feuille();
  await s.ev("VibeFlow.go('q:answer')"); await pause(900); // ce que faisait le bouton
  frais.apresAller = { vue: await s.ev('VibeFlow.state.container'), erreurs: await s.ev('window.__errs.slice()') };
  await charger('index.html');
  await s.ev("window.__errs = []; addEventListener('unhandledrejection', (e) => window.__errs.push(String((e.reason && e.reason.message) || e.reason)))");
  await s.ev(REPONDRE(avecCartes)); await poser('Une question avec cartes ?'); await attendreFeuille('Voici des cartes');
  const premier = await attendreEtStabiliser(feuille, (v) => v.vue === 'q:answer' && v.titre === 'Premier tableau', { pas: 150, max: 5000 });
  await s.ev(REPONDRE(sansCarte)); await poser('La suivante, sans carte ?'); await attendreFeuille('Aucune carte'); await pause(900);
  const suivant = await stabiliser(feuille, { pas: 150, max: 5000 }); // la pause d'au-dessus reste : fenêtre d'absence du bouton et du tableau d'avant
  o.reponse = { frais, premier, suivant };

  // DG-03 / PU-G-054 : le titre d'un tableau dit le nombre de cartes qu'il porte ; un tableau coupé à 24 cartes le dit (la coupe est générique : kind neutre, 75-09c)
  await charger('index.html');
  const titreTableau = () => s.ev("document.querySelector('#context .k').innerText.replace(/\\s+/g, ' ').trim()");
  const tableau = (ids) => s.ev(`VibeFlow.showBoard({ kind: 'Board', title: 'Board', items: ${ids} })`).then(() => s.attendre("VibeFlow.state.container === 'q:answer' && !!document.querySelector('#viewport .node')", 'tableau')).then(() => poserVue());
  await tableau("[...VibeFlow.files.keys()].slice(0, 3).map((k) => 'f:' + k)");
  o.tableau = { cartes: await s.ev('VibeFlow.state.answer.items.length') };
  o.tableau.titre = await attendreEtStabiliser(titreTableau, (v) => v === `Board · ${o.tableau.cartes} cards`, { pas: 150, max: 5000 });
  const nbFichiers = await s.ev('VibeFlow.files.size');
  await tableau("[...VibeFlow.files.keys()].map((k) => 'f:' + k)");
  o.tableau.coupe = { titre: await attendreEtStabiliser(titreTableau, (v) => v === `Board · 24 of ${nbFichiers} cards`, { pas: 150, max: 5000 }), fichiers: nbFichiers, cartes: await s.ev('VibeFlow.state.answer.items.length') };

  // PU-G-049 : les cartes d'un tableau portent le dossier parent des homonymes (deux README)
  await tableau("['f:plugin/mod/README.md', 'f:plugin/mod/scripts/README.md']");
  o.dedoublon = { noms: await s.ev("[...document.querySelectorAll('#viewport .node .title')].map((x) => x.innerText.trim())") };
  return o;
}, { csp: false });
