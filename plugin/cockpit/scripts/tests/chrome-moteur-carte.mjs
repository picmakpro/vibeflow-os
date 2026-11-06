// chrome-moteur-carte.mjs — témoins de comportement du moteur de carte (lot 1, étape M4), dans un vrai Chrome headless.
// Usage : node chrome-moteur-carte.mjs <chrome> <racine-du-serveur> <identifiant-de-session-équipe>
//   UN Chrome, plusieurs pages (en anglais : ?lang=en, pour que les libellés du moteur soient lus tels qu'il les écrit, sans le dictionnaire).
//   Chaque mesure est interrogée dans la page (jamais une durée fixe pour décider d'un état). Rend une ligne JSON { <clé>: valeur } ou { erreur }.
//   Clés : panneau · modale · noms · stats · document · encart · echap · rangees · feuille · retour · jalon · pastille · info · bague · halo · equipe
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, racine, equipeSession] = process.argv;
const U = (page) => `${racine}/${page}?lang=en`;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";

await executer(chrome, async (s) => {
  const o = {};
  const vue = (w, h, touch = false) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: touch });
  const charger = async (page) => { await s.naviguer(U(page)); await s.attendre(PRET, `page prête (${page})`); await s.attendre("!!document.querySelector('#viewport .node')", `cartes (${page})`); await pause(300); };
  const touche = async (key, code, vk) => { await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk }); };
  const echap = () => touche('Escape', 'Escape', 27);
  const clic = async (x, y) => { await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
  const aller = async (id) => { await s.ev(`VibeFlow.go(${JSON.stringify(id)})`); await s.attendre(`VibeFlow.state.container === ${JSON.stringify(id)} && !!document.querySelector('#viewport .node')`, `vue ${id}`); await pause(500); };
  // montrer la fiche d'un fichier : la carte de son dossier s'affiche et la fiche s'ouvre (select seul ne vaut que pour une carte déjà visible)
  const fiche_de = async (id) => { await s.ev(`VibeFlow.reveal(${JSON.stringify(id)})`); await s.attendre(`VibeFlow.state.selected === ${JSON.stringify(id)} && !!document.querySelector('#panel h2')`, `fiche ${id}`); await pause(400); };
  // réponse de l'assistant simulée : la page parle à un flux d'événements, on le remplace par un flux fixe (une réponse longue, quatre cartes)
  const REPONSE = `(() => { const ids = [...VibeFlow.nodes.keys()].slice(0, 4).map((k) => 'n:' + k);
    const ans = { title: 'Réponse', answer: Array.from({ length: 12 }, (_, i) => 'Paragraphe ' + (i + 1) + ' de la réponse, assez long pour occuper de la place dans la bulle.').join('\\n\\n'), items: ids, steps: [], followups: [] };
    const f = window.fetch; window.fetch = (u, x) => String(u).includes('/api/ask') ? Promise.resolve(new Response('event: answer\\ndata: ' + JSON.stringify(ans) + '\\n\\n')) : f(u, x); })()`;
  const poser = (q) => s.ev(`(() => { const i = document.querySelector('#ask-input'); i.value = ${JSON.stringify(q)}; document.querySelector('#ask-form').requestSubmit(); })()`);

  // ---------- page Code, 1 280 x 720 ----------
  await vue(1280, 720); await charger('index.html');
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  // la visite guidée s'ouvre d'elle-même au premier passage et prend Échap : on la ferme d'abord, pour mesurer la carte seule
  await s.attendre("!!document.querySelector('#tour') && !document.querySelector('#tour').hidden", 'visite ouverte', 8000).catch(() => {});
  await echap(); await s.attendre("!document.querySelector('#tour') || document.querySelector('#tour').hidden", 'visite fermée'); await pause(600);

  // PU-G-014 : fenêtre « Exporter une copie » — focus dedans à l'ouverture, Échap la ferme et rend le focus, clic sur le fond la ferme
  await s.ev("document.querySelector('#btn-export').focus()");
  await s.ev("document.querySelector('#btn-export').click()");
  await s.attendre("document.querySelector('#modal').classList.contains('open')", 'fenêtre ouverte');
  const m = { dedans: await s.ev("document.querySelector('#modal').contains(document.activeElement)") };
  const surPage = await s.ev('(() => { const st = VibeFlow.state; return st.container + "|" + st.selected; })()');
  await echap(); await pause(300);
  m.echap = await s.ev("!document.querySelector('#modal').classList.contains('open')");
  m.rendu = await s.ev("document.activeElement && document.activeElement.id");
  m.pageIntacte = (await s.ev('(() => { const st = VibeFlow.state; return st.container + "|" + st.selected; })()')) === surPage;
  await s.ev("document.querySelector('#btn-export').click()");
  await s.attendre("document.querySelector('#modal').classList.contains('open')", 'fenêtre rouverte');
  await clic(10, 300); await pause(300);
  m.fond = await s.ev("!document.querySelector('#modal').classList.contains('open')");
  o.modale = m;

  // PU-G-018 : noms accessibles de la flèche d'envoi et de la copie du chemin
  await fiche_de('f:plugin/mod/scripts/run.sh');
  o.noms = { envoi: await s.ev("document.querySelector('#ask-send').getAttribute('aria-label')"), chemin: await s.ev("(document.querySelector('#panel .pp button') || { getAttribute() {} }).getAttribute('aria-label')") };

  // PU-G-058 : « détail technique » ne change ni les statistiques ni les libellés de la fiche d'un fichier
  const fiche = () => s.ev(`JSON.stringify({ stats: [...document.querySelectorAll('#panel .stats > div')].map((d) => d.innerText.replace(/\\s+/g, ' ').trim()), liens: [...document.querySelectorAll('#panel .row .rc')].map((e) => e.innerText.trim()) })`);
  await s.ev("VibeFlow.setTechnical(false)"); await pause(600); await fiche_de('f:plugin/mod/scripts/run.sh');
  const simple = JSON.parse(await fiche());
  await s.ev("VibeFlow.setTechnical(true)"); await pause(900); await fiche_de('f:plugin/mod/scripts/run.sh');
  const tech = JSON.parse(await fiche());
  await s.ev("VibeFlow.setTechnical(false)"); await pause(300);
  o.stats = { simple, tech, identique: JSON.stringify(simple.stats) === JSON.stringify(tech.stats) && simple.stats.length > 0 };

  // PU-G-072 : fiche d'un document — « Mentions » et une phrase d'explication, ni « Depends on » ni « calls »
  await fiche_de('f:plugin/mod/README.md');
  o.document = JSON.parse(await s.ev(`JSON.stringify({ titres: [...document.querySelectorAll('#panel h3')].map((h) => h.innerText.replace(/\\s+\\d+$/, '').trim()), note: (document.querySelector('#panel h3 + p.pd') || { innerText: '' }).innerText, liens: [...document.querySelectorAll('#panel .row .rc')].map((e) => e.innerText.trim()) })`));

  await fiche_de('f:plugin/mod/scripts/check.sh');
  o.script = { titres: JSON.parse(await s.ev("JSON.stringify([...document.querySelectorAll('#panel h3')].map((h) => h.innerText.replace(/\\s+\\d+$/, '').trim()))")) };

  // PU-G-074 : encart des noms générés — la commande réelle et un bouton qui la copie
  await s.ev("VibeFlow.go('root')"); await pause(800);
  await s.ev("window.__cp = null; navigator.clipboard.writeText = (t) => { window.__cp = t; return Promise.resolve(); }");
  o.encart = { texte: await s.ev("(document.querySelector('#panel .callout') || { innerText: '' }).innerText"), bouton: await s.ev("!!document.querySelector('#panel .callout [data-copycmd]')") };
  await s.ev("(document.querySelector('#panel .callout [data-copycmd]') || { click() {} }).click()"); await pause(200);
  o.encart.copie = await s.ev('window.__cp');

  // PU-G-174 / PU-G-175 : lignes du panneau au clavier, Échap avec le focus hors du canevas
  const conteneurs = JSON.parse(await s.ev("JSON.stringify([...VibeFlow.nodes.keys()].map((k) => 'n:' + k).filter((k) => VibeFlow.children(k).length > 0).slice(0, 3))"));
  await aller(conteneurs[0]); await s.ev("VibeFlow.select(null)"); await pause(300);
  o.rangees = JSON.parse(await s.ev(`JSON.stringify({ total: document.querySelectorAll('#panel a.row[data-go]').length, auClavier: document.querySelectorAll('#panel a.row[data-go][tabindex="0"]').length })`));
  const avant = await s.ev('VibeFlow.state.container');
  await s.ev("(() => { const a = document.querySelector('#panel a.row[data-go]'); a && a.focus(); })()");
  const surLigne = await s.ev("!!document.activeElement.closest('#panel')");
  await echap(); await pause(500);
  const apresLigne = await s.ev('VibeFlow.state.container');
  await s.ev("document.activeElement && document.activeElement.blur()");
  await echap(); await pause(900);
  const apresCanevas = await s.ev('VibeFlow.state.container');
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
  await pause(600);
  const f = JSON.parse(await s.ev("JSON.stringify((() => { const r = document.querySelector('#ask-sheet').getBoundingClientRect(); return { h: r.height, vh: innerHeight }; })())"));
  o.feuille = { hauteur: f.h, fenetre: f.vh, part: Math.round((100 * f.h) / f.vh) };
  await s.ev("document.querySelector('#ask-sheet [data-act=\"map\"]').click()");
  await s.attendre("VibeFlow.state.container !== 'q:answer'", 'retour de la réponse'); await pause(500);
  o.retour = { depart: conteneurs[0], arrivee: await s.ev('VibeFlow.state.container'), bulleGardee: await s.ev("!document.querySelector('#ask-sheet').hidden") };
  await aller(conteneurs[1] || 'root'); await pause(300);
  o.jalon = { bulleRefermee: await s.ev("document.querySelector('#ask-sheet').hidden") };

  // ---------- page Projet : état réel des nœuds d'une mission (PU-G-105) ----------
  await vue(1280, 720); await charger('project.html');
  const mission = await s.ev("[...VibeFlow.nodes.keys()].find((k) => /^dag-/.test(k)) || ''");
  await aller('n:' + mission);
  o.pastille = JSON.parse(await s.ev(`JSON.stringify({ mission: ${JSON.stringify(mission)}, lignes: [...document.querySelectorAll('#panel .row .rc')].map((e) => e.innerText.trim()), pastilles: document.querySelectorAll('#panel .row .rc .vst').length })`));
  const c = JSON.parse(await s.ev(`(() => { const cs = [...document.querySelectorAll('#viewport .node .card')].map((e) => e.getBoundingClientRect()).filter((r) => r.width > 0 && r.right < innerWidth - 340 && r.top > 130); const r = cs[0]; return JSON.stringify(r ? { x: r.x + r.width / 2, y: r.y + r.height / 2 } : null); })()`));
  if (c) {
    await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 5, y: 5, button: 'none' });
    for (const dx of [-30, -10, 0, 3]) { await s.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: c.x + dx, y: c.y, button: 'none' }); await pause(120); }
    await s.attendre("!document.querySelector('#tooltip').hidden && document.querySelector('#tooltip').innerText.length > 0", 'infobulle de carte');
  }
  o.info = { texte: await s.ev("(document.querySelector('#tooltip') || { innerText: '' }).innerText"), pastille: await s.ev("!!document.querySelector('#tooltip .vst')") };

  // ---------- panneau de détail par défaut : fermé à 768 px, ouvert à 1 024 px (PU-G-045) ----------
  const ouvertA = async (w, h) => { await vue(w, h); await charger('index.html'); return s.ev("!document.body.classList.contains('no-panel') && document.querySelector('#btn-panel').getAttribute('aria-expanded') === 'true'"); };
  o.panneau = { a768: await ouvertA(768, 1024), a1024: await ouvertA(1024, 768) };

  // ---------- onglet Équipe à 390 px : une seule colonne (PU-G-176) ----------
  await vue(390, 844, true); await charger('equipe.html');
  await aller('n:ag-' + equipeSession);
  o.equipe = JSON.parse(await s.ev(`JSON.stringify((() => { const cs = [...document.querySelectorAll('#viewport .node .card')].map((e) => e.getBoundingClientRect()).filter((r) => r.width > 0); return { cartes: cs.length, colonnes: new Set(cs.map((r) => Math.round(r.left / 20))).size, debordent: cs.filter((r) => r.right > innerWidth + 1 || r.left < -1).length }; })())`));
  return o;
}, { csp: false });
