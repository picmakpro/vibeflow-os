// chrome-projet-vocabulaire.mjs — mesures du vocabulaire du panneau de Projet (80-11, FORM-08) : un vrai Chrome headless, jamais un fichier lu en statique.
// Usage : node chrome-projet-vocabulaire.mjs <chrome> <racine-du-serveur> <mode> [sections]   Rend UNE ligne JSON { … } ou { erreur }.
// Modes : pv1 (type et parent d'un plan, Code inchangé) · pv2 (listes, statut et vague, exigence, phase, scripts, aller-retour d'onglet)
//   · pv2b (lab sans exigences, porte substituée) · pv3 (ligne d'état, jalon, balayage des mots).
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode, filtre] = process.argv;
const SEL = filtre ? new Set(filtre.split(',')) : null;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; try { localStorage.removeItem('floorplan:panel'); } catch (e) { void e; } })()";
const NORM = "(s) => String(s || '').replace(/\\s+/g, ' ').trim()";
// le panneau tel qu'il est rendu : type, titre, sections (titre sans compte, rangées), texte entier
const PANNEAU = `(() => { const n = ${NORM}, p = document.getElementById('panel');
  return JSON.stringify({ kind: n((p.querySelector('.ph .kindlabel, .ph .kind') || {}).textContent), titre: n((p.querySelector('h2.pt') || {}).textContent),
    txt: n(p.textContent), actions: [...p.querySelectorAll('.actions .btn')].map((b) => n(b.textContent)),
    stats: p.querySelectorAll('.stats').length, progress: p.querySelectorAll('[role=progressbar]').length,
    secs: [...p.querySelectorAll('.sec')].map((s) => ({
      h: n(s.querySelector('h3') && s.querySelector('h3').firstChild ? s.querySelector('h3').firstChild.textContent : ''),
      rows: [...s.querySelectorAll('.row')].map((r) => n(r.textContent)) })).filter((s) => s.h || s.rows.length) }); })()`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const sec = async (nom, f) => { if (SEL && !SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const charger = async (page, qs = '') => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    await s.naviguer(`${racine}/${page}${qs}`, { brut: true }); await s.attendre(PRET, 'page prête');
    await stabiliser(() => s.ev("document.querySelectorAll('#viewport .node, .vp-ligne, .vp-carte').length"), { pas: 120, max: 5000 }); await pause(300);
  };
  // un id de plan (« f:<chemin> ») par son numéro, un id d'exigence par son nom
  const idDe = (nom) => lire(`JSON.stringify((VibeFlow.graph.files.find((f) => String(f.name).split(' — ')[0] === ${JSON.stringify(nom)}) || {}).p
    ? 'f:' + VibeFlow.graph.files.find((f) => String(f.name).split(' — ')[0] === ${JSON.stringify(nom)}).p : null)`);
  const choisir = async (id) => { await s.ev(`(async () => { VibeFlow.select(${JSON.stringify(id)}); await new Promise((r) => setTimeout(r, 250)); })()`);
    await stabiliser(() => s.ev(PANNEAU), { pas: 120, max: 4000 }); return lire(PANNEAU); };

  if (mode === 'pv1') {
    await sec('pv11', async () => {
      await charger('project.html', '?vue=graphe');
      o.pv11 = await choisir(await idDe('01-01'));
    });
    await sec('pv13', async () => {
      await charger('index.html');
      const id = await lire("JSON.stringify(((f) => (f ? 'f:' + f.p : null))(VibeFlow.graph.files.find((f) => /a\\.js$/.test(f.p))))");
      o.pv13 = await choisir(id);
    });
  }

  if (mode === 'pv2') {
    await sec('pv21', async () => {
      await charger('project.html', '?vue=graphe');
      o.pv21 = await choisir(await idDe('01-02')); o.pv21b = await choisir(await idDe('01-01'));
      o.pv22 = await choisir(await idDe('01-03'));
      // 76-08 : l'exigence n'a plus de carte ; elle se lit dans la traçabilité (meta.vf.trace.exigences) et dans la section « Exigences couvertes » du plan (pv21)
      o.pv23 = await lire("JSON.stringify({ carte: VibeFlow.graph.files.filter((f) => f.name === 'R-1' || f.p.startsWith('req/')).length,"
        + " noeud: VibeFlow.graph.nodes.filter((n) => n.kind === 'exigences' || /\\.req$/.test(n.id)).length,"
        + " trace: VibeFlow.graph.meta.vf.trace.exigences.filter((e) => e.id === 'R-1').length })");
      o.pv24 = await choisir('n:ph-1');
    });
    await sec('pv26', async () => {
      await charger('project.html', '?vue=graphe');
      o.pv26 = await lire(`JSON.stringify({ src: performance.getEntriesByType('resource').map((r) => r.name).filter((u) => /41-vf-projet-panneau\\.js/.test(u)),
        enligne: [...document.scripts].filter((x) => !x.src && /VF_EXIGENCES\\.lireExigences/.test(x.textContent)).length })`);
    });
    await sec('pv27', async () => {
      await charger('project.html', '?vue=graphe');
      o.pv27 = {};
      await s.ev('window.__ancien = window.VF_EXIGENCES');
      await s.ev("(async () => { await VF_COQUILLE.chargerOnglet('equipe'); await VF_COQUILLE.chargerOnglet('projet'); })()"); await pause(500);
      o.pv27.change = await lire('JSON.stringify(window.__ancien !== window.VF_EXIGENCES && !!window.VF_EXIGENCES)');
      await stabiliser(() => s.ev("document.querySelectorAll('#viewport .node').length"), { pas: 150, max: 5000 });
      o.pv27.vraie = await choisir(await idDe('01-02'));
      await s.ev(`(async () => { const e = [{ id: 'FX-1', texte: 'a', cochee: true, cible: null }, { id: 'FX-2', texte: 'b', cochee: false, cible: null }];
        VF_EXIGENCES.lireExigences = () => { const c = {}; for (const f of VibeFlow.graph.files) if (/-PLAN\\.md$/.test(f.p)) c['f:' + f.p] = e;
          return { exigences: e, couverture: c }; };
        await VibeFlow.rerender(); })()`); await pause(500);
      o.pv27.fausse = await lire(PANNEAU);
    });
  }

  if (mode === 'pv2b') {
    await sec('pv25', async () => {
      await charger('project.html', '?vue=graphe'); const r = {};
      r.graphe = await lire("JSON.stringify([VibeFlow.graph.nodes.filter((n) => n.kind === 'exigences').length,"
        + " VibeFlow.graph.files.filter((f) => /R-\\d/.test(f.name)).length])");
      r.vraie = await choisir(await idDe('01-02'));
      await s.ev(`(async () => { window.__vraie = VF_EXIGENCES.lireExigences;
        const e = [{ id: 'FX-1', texte: 'Premier texte factice', cochee: true, cible: null },
        { id: 'FX-2', texte: 'Second texte factice', cochee: false, cible: null }]; VF_EXIGENCES.lireExigences = () => {
          const c = {}; for (const f of VibeFlow.graph.files) if (/-PLAN\\.md$/.test(f.p)) c['f:' + f.p] = e; return { exigences: e, couverture: c }; };
        await VibeFlow.rerender(); })()`); await pause(500);
      r.fausse = await lire(PANNEAU);
      await s.ev('(async () => { VF_EXIGENCES.lireExigences = window.__vraie; await VibeFlow.rerender(); })()'); await pause(500);
      r.restaure = await lire(PANNEAU); o.pv25 = r;
    });
  }

  if (mode === 'pv3') {
    await sec('pv31', async () => {
      await charger('project.html', '?vue=graphe');
      o.pv31 = await choisir('n:ph-1');
      const J = await lire("JSON.stringify(VibeFlow.graph.nodes.find((n) => n.kind === 'jalon' && !n.parent && n.label.indexOf('v2.0') === 0).id)");
      o.pv31j = await choisir('n:' + J);
    });
    await sec('pv33', async () => { // tout le texte du panneau, pour chaque nœud et chaque élément de Projet
      await charger('project.html', '?vue=graphe');
      const ids = await lire("JSON.stringify([...VibeFlow.graph.nodes.map((n) => 'n:' + n.id), ...VibeFlow.graph.files.map((f) => 'f:' + f.p)])");
      const mots = [];
      for (const id of ids) {
        const p = await choisir(id), m = /.{0,24}([Éé]lément|module|Mention).{0,24}/.exec(p.kind + ' | ' + p.txt);
        if (m) mots.push([id, m[0]]);
      }
      o.pv33 = { n: ids.length, mots };
    });
  }
  return o;
});
