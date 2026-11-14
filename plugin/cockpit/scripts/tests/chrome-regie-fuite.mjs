// chrome-regie-fuite.mjs <chrome> <url de equipe.html> fuite <json des sentinelles> : la non-fuite d'« ailleurs sur ce poste » de bout en bout (Phase 73, plan 73-07, P73-D-16, P73-D-25). UNE ligne JSON.
// Sentinelles : { id (session d'un autre lab), titre, chemin (dossier complet), parent (dossier parent), lab (nom du lab voisin, seul droit de séjour : la page), dossier (le lab de fixture),
//   marqueur (fichier posé juste avant le lancement du serveur), agents (identifiants des agents poussés) }.
// Précondition POSITIVE d'abord : la ligne « Ailleurs sur ce poste » est affichée avec le nom du lab. Puis la recherche des sentinelles dans l'export de la page, chaque fichier neuf ou modifié sous le lab
// (témoin : le cache server.json est bien parcouru), chaque trame du flux (relevées par le protocole : Network.eventSourceMessageReceived, une seconde connexion ouverte après la lecture comprise),
// __vfLive.who, /api/vf/etat, /api/vf/journal, localStorage, sessionStorage, le titre. /api/vf/transcript?id=<id sentinelle> ne rend aucun transcript.
import fs from 'node:fs'; import path from 'node:path';
import { executer, attendreValeur, pause } from './chrome-session.mjs';
const [, , chrome, url, scenario, brut] = process.argv;
const X = JSON.parse(brut || '{}');
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); if (n !== 'who' && n !== 'reload') super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
const CALME = "try { sessionStorage.setItem('vf-equipe-rechargement', String(Date.now() + 800000000)); } catch {}";
const PRET = "document.readyState === 'complete' && !!document.getElementById('vf-equipe') && document.body.classList.contains('vf-regie-montee') && !!window.__es && window.__es.some((e) => e.url.includes('/api/vf/events'))";
const MARQUE_ID = /id=["']vf-equipe["']|class=["'][^"']*vf-rg-/, MARQUE_CLE = /data-vf-cle=["']/;
const SENTINELLES = () => [X.id, X.titre, X.chemin, X.parent, X.lab].filter(Boolean);
const dans = (t) => SENTINELLES().filter((v) => String(t).includes(v));
const parcourir = (d, t0, sortie) => {
  let noms; try { noms = fs.readdirSync(d, { withFileTypes: true }); } catch { return sortie; }
  for (const e of noms) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) { if (e.name !== 'objects') parcourir(p, t0, sortie); continue; }
    if (!e.isFile()) continue;
    let st; try { st = fs.statSync(p); } catch { continue; }
    if (st.mtimeMs < t0 || st.size > 8000000) continue;
    let t = ''; try { t = fs.readFileSync(p).toString('latin1'); } catch { continue; }
    sortie.push({ nom: path.relative(X.dossier, p), trouve: dans(p + '\n' + t) });
  }
  return sortie;
};

await executer(chrome, async (s) => {
  if (scenario !== 'fuite') return { erreur: 'scénario inconnu : ' + scenario };
  const trames = [];
  s.ecouter('Network.eventSourceMessageReceived', (p) => trames.push((p.eventName || '') + '\n' + (p.data || '')));
  await s.send('Network.enable');
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ + CALME });
  await s.naviguer(url + '#sans-visite');
  await s.attendre(PRET, 'régie montée et flux ouvert');
  await s.attendre("!!window.VF_ETAT && window.VF_ETAT.lire('connexion') === 'ouvert'", 'hello reçu');
  const agents = (X.agents || []).map((id, i) => ({ kind: 'session', id, etat: i ? 'actif' : 'attend', titre: 'Atelier ' + id.slice(0, 4), tree: '.', ageS: 120, dureeS: 900 }));
  for (let i = 0; i < 5; i++) {
    await s.ev(`window.__es.find((x) => x.url.includes('/api/vf/events')).__emit('who', { who: { workers: ${JSON.stringify(agents)} } })`);
    if (await s.ev(`window.VF_ETAT.lire('who').workers.length === ${agents.length}`)) break; await pause(300);
  }
  const ligne = () => s.ev("(() => { const e = document.querySelector('#vf-equipe .vf-rg-ailleurs'); return e && !e.hidden ? e.textContent : null; })()");
  const positif = await attendreValeur(ligne, Boolean, { max: 9000 });
  const lignes = await s.ev("document.querySelectorAll('#vf-equipe li[data-vf-cle]').length");
  // une seconde connexion : son `hello` part après la lecture d'« ailleurs » (la mémoire du serveur est alors remplie) ; ses trames sont relevées comme les autres
  await s.ev("(() => { window.__second = new EventSource(window.__es[0].url); })()"); await pause(2500);
  await s.ev('window.__second.close()');
  const jeton = await s.ev("(window.VF_ETAT && window.VF_ETAT.jeton()) || ''");
  const get = (p) => s.ev(`fetch(${JSON.stringify(p)}, { headers: { 'x-vf-cockpit-token': ${JSON.stringify(jeton)} }, cache: 'no-store' }).then(async (r) => ({ statut: r.status, texte: (await r.text()).slice(0, 4000000) })).catch((e) => ({ statut: 0, texte: String(e) }))`);
  const exporte = await s.ev(`fetch('/api/export', { method: 'POST', headers: { 'content-type': 'application/json', 'x-vf-cockpit-token': ${JSON.stringify(jeton)} }, body: JSON.stringify({ include: {}, flows: [] }) })
    .then(async (r) => ({ statut: r.status, texte: (await r.text()).slice(0, 4000000) })).catch((e) => ({ statut: 0, texte: String(e) }))`);
  const etat = await get('/api/vf/etat'), journal = await get('/api/vf/journal'), transcript = await get('/api/vf/transcript?id=' + encodeURIComponent(X.id)), ailleurs = await get('/api/vf/ailleurs');
  const pages = await s.ev('({ who: JSON.stringify(window.__vfLive ? window.__vfLive.who : null), local: JSON.stringify(Object.entries(localStorage)), session: JSON.stringify(Object.entries(sessionStorage)), titre: document.title, section: document.getElementById("vf-equipe").textContent, html: document.documentElement.outerHTML })');
  const fichiers = parcourir(X.dossier, fs.statSync(X.marqueur).mtimeMs, []);
  let corps = null; try { corps = JSON.parse(ailleurs.texte); } catch { /* corps illisible : cles reste null */ }
  const cles = corps && Array.isArray(corps.ailleurs) ? [...new Set(corps.ailleurs.flatMap((e) => Object.keys(e)))].sort() : null;
  const ts = trames.filter((t) => t.startsWith('hello\n')).length;
  return { positif: positif || null, lignes, nomDansPage: pages.section.includes(X.lab) || String(positif).includes(X.lab), trouve: {
    export: dans(exporte.texte), fichiers: [...new Set(fichiers.flatMap((f) => f.trouve))], trames: dans(trames.join('\n')), who: dans(pages.who), etat: dans(etat.texte), journal: dans(journal.texte),
    local: dans(pages.local), session: dans(pages.session), titre: dans(pages.titre) },
  // l'export est la page de la sortie, scripts compris (ils NOMMENT vf-equipe) : ce qui ne doit pas y être, c'est le balisage de la régie ; le témoin positif : les mêmes motifs trouvent le DOM vivant
  export: { statut: exporte.statut, vfEquipe: MARQUE_ID.test(exporte.texte), cle: MARQUE_CLE.test(exporte.texte), temoin: MARQUE_ID.test(pages.html) && MARQUE_CLE.test(pages.html), agents: (X.agents || []).filter((a) => exporte.texte.includes(a)) },
  fichiers: { n: fichiers.length, serveur: fichiers.some((f) => f.nom.endsWith('server.json')) }, hellos: ts,
  transcript: { statut: transcript.statut, aTranscript: /"(lignes|events|messages|turns)"/.test(transcript.texte) },
  contrat: { statut: ailleurs.statut, cles, schema: corps && corps.schema } };
}, { csp: true });
