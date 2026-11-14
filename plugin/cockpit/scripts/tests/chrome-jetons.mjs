// chrome-jetons.mjs — mesures en rendu des jetons d'état (80-16, FORM-14, P80-D-20, P80-D-31) dans un vrai Chrome headless, deux thèmes.
// Usage : node chrome-jetons.mjs <chrome> <racine-du-serveur> <mode>   Rend UNE ligne JSON { … } ou { erreur }. Un mode = un Chrome : jt1, jt2, jt3, jt15.
// Chaque section est isolée (sec) : une section qui échoue laisse ses champs vides, les autres sont mesurées. Aucun fichier de la sortie n'est lu.
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
// la visite du premier passage s'ouvre d'elle-même : ses clés sont lues comme posées
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
// outils de mesure posés dans la page : couleur normalisée par un canevas, luminance relative, rapport de contraste, opacité cumulée
const AIDES = `window.__j = (() => {
  const cv = document.createElement('canvas').getContext('2d', { willReadFrequently: true });
  const norm = (c) => { cv.clearRect(0, 0, 1, 1); cv.fillStyle = '#000'; cv.fillStyle = c; cv.fillRect(0, 0, 1, 1); const d = cv.getImageData(0, 0, 1, 1).data; return [d[0], d[1], d[2], d[3] / 255]; };
  const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; };
  const lum = (c) => 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2]);
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return Math.round(((Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)) * 100) / 100; };
  const sonde = (css) => { const p = document.createElement('i'); p.style.cssText = css; document.body.appendChild(p); const s = getComputedStyle(p); const r = { c: s.color, f: s.backgroundColor, o: s.boxShadow }; p.remove(); return r; };
  const jeton = (t) => norm(sonde('color: var(' + t + ')').c);
  const sur = (fg, a, bg) => [0, 1, 2].map((i) => Math.round(fg[i] * a + bg[i] * (1 - a)));
  const alpha = (el, jusque) => { let a = 1; for (let e = el; e && e !== jusque; e = e.parentElement) a *= parseFloat(getComputedStyle(e).opacity); return a; };
  const fond = (card) => { const f = norm(getComputedStyle(card).backgroundColor); return f[3] ? f : jeton('--surface'); };
  return { norm, ratio, sonde, jeton, sur, alpha, fond };
})()`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const theme = (t) => s.ev(`document.documentElement.setAttribute('data-theme', '${t === 'clair' ? 'light' : 'dark'}')`);
  const compte = "JSON.stringify([document.querySelectorAll('.vp-carte').length, document.querySelectorAll('#viewport .node').length])";
  const charger = async (qs = '') => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    await s.naviguer(`${racine}/project.html${qs}`, { brut: true }); await s.attendre(PRET, 'page prête');
    await stabiliser(() => s.ev(compte), { pas: 120, max: 5000 }); await pause(300);
  };
  // le glyphe d'une pastille : sa couleur (fond du ::before), puis son contraste sur --bg et sur le fond réel de sa carte
  const glyphe = (sel) => `(() => { const J = window.__j, e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null;
    const c = J.norm(getComputedStyle(e, '::before').backgroundColor), carte = e.closest('.card, .vp-carte, .vp-couloir');
    return { rgb: c.slice(0, 3).join(), bg: J.ratio(c, J.jeton('--bg')), surface: J.ratio(c, J.jeton('--surface')) }; })()`;

  if (mode === 'jt1') {
    await sec('jt1', async () => {
      for (const th of ['clair', 'sombre']) {
        await charger('?vue=graphe'); await theme(th); await pause(200); await s.ev(AIDES);
        const J = 'window.__j';
        o[th] = {
          canevas: await lire(`JSON.stringify(${glyphe('#viewport .card.st-active .vst-active')})`),
          sev: await lire(`JSON.stringify(${J}.jeton('--sev-medium').slice(0, 3).join())`),
          actif: await lire(`JSON.stringify(${J}.jeton('--st-active').slice(0, 3).join())`),
          recette: await lire(`JSON.stringify(${J}.jeton('--st-recette').slice(0, 3).join())`),
          puce: await lire(`JSON.stringify(${J}.ratio(${J}.jeton('--on-sev-text'), ${J}.jeton('--sev-medium')))`),
        };
        await charger(''); await theme(th); await pause(200); await s.ev(AIDES);
        o[th].couloir = await lire(`JSON.stringify(${glyphe('.vp-couloir[data-couloir="en-cours"] .vst-active')})`);
      }
    });
  }

  if (mode === 'jt2') {
    // JT2.1 / JT2.3 : fond d'une carte active ou à recetter ; JT2.2 : cartes estompées (texte composé, pastille pleine)
    await sec('jt2', async () => {
      for (const th of ['clair', 'sombre']) {
        await charger('?vue=graphe'); await theme(th); await s.ev(AIDES);
        await s.ev("VibeFlow.reveal('n:ph-1')"); await pause(1500); // la phase 1 est choisie : les autres cartes sont estompées par le moteur
        // fond et ombre se lisent hors estompage (l'estompage retire l'ombre des cartes voisines), puis l'estompage revient et se pose
        await s.ev("document.getElementById('svg').classList.remove('dim')"); await pause(500);
        o[th] = await lire(`JSON.stringify((() => { const J = window.__j, r = {};
          const probe = J.sonde('background: color-mix(in srgb, var(--raise) 70%, var(--surface)); box-shadow: var(--shadow-card)');
          const sd = (sel) => { const e = document.querySelector(sel); if (!e) return null; const s = getComputedStyle(e);
            return { fond: J.norm(s.backgroundColor).join(), surface: J.jeton('--surface').join(), melange: J.norm(probe.f).join(), ombre: s.boxShadow === probe.o,
              bord: s.borderTopWidth + '|' + s.outlineStyle }; };
          r.actif = sd('#viewport .card.st-active'); r.recette = sd('#viewport .card.st-recette'); return r; })())`);
        await s.ev("document.getElementById('svg').classList.add('dim')"); await pause(600);
        Object.assign(o[th], await lire(`JSON.stringify((() => { const J = window.__j, r = {};
          r.dim = document.getElementById('svg').classList.contains('dim') && !!document.querySelector('#viewport .node.hl');
          let min = 99, n = 0; const past = [];
          for (const card of document.querySelectorAll('#viewport .node:not(.hl) .card')) {
            const bg = J.fond(card);
            for (const t of card.querySelectorAll('.title, .desc, .meta')) {
              const st = getComputedStyle(t); if (st.visibility === 'hidden' || st.display === 'none' || !t.textContent.trim()) continue;
              const fg = J.norm(st.color), a = J.alpha(t, card.parentElement) * fg[3];
              min = Math.min(min, J.ratio(J.sur(fg, a, bg), bg)); n++;
            }
            for (const p of card.querySelectorAll('.vst, .rw')) {
              const c = J.norm(getComputedStyle(p, '::before').backgroundColor), a = J.alpha(p, card.parentElement);
              past.push({ cls: p.className, alpha: Math.round(a * 100) / 100, ratio: J.ratio(J.sur(c, a * c[3], bg), bg) });
            }
          }
          r.texte = { min, n }; r.pastilles = past; return r; })())`));
      }
    });
  }

  if (mode === 'jt3') {
    // JT3.2 : la table des contrastes de 80-UI-SPEC.md § 5, remesurée en rendu dans les deux thèmes
    await sec('jt3', async () => {
      for (const th of ['clair', 'sombre']) {
        await charger(''); await theme(th); await pause(200); await s.ev(AIDES);
        o[th] = await lire(`JSON.stringify((() => { const J = window.__j, j = J.jeton, r = {};
          const R = (a, b) => J.ratio(j(a), j(b));
          r.texte = { 'text/surface': R('--text', '--surface'), 'text-2/surface': R('--text-2', '--surface'), 'text-3/surface': R('--text-3', '--surface'),
            'text-3/hover': R('--text-3', '--surface-hover'), 'text-3/bg': R('--text-3', '--bg') };
          r.nonTexte = { 'done/bg': R('--st-done', '--bg'), 'select/bg': R('--text-3', '--bg'), 'warn/raise-2': R('--warn-text', '--raise-2'), 'ring/bg': R('--ring', '--bg') };
          r.actif = { bg: R('--st-active', '--bg'), surface: R('--st-active', '--surface') };
          return r; })())`);
      }
    });
  }

  if (mode === 'jt15') {
    // JT1.5 : l'extension est une extension de page, chargée une fois par arrivée sur l'onglet (entrées de ressources), jamais persistante
    await sec('jt15', async () => {
      await charger('');
      const n = () => lire("JSON.stringify(['/ui/01-vf-ensemble.js', '/ui/00-vibeflow.js'].map((f) => performance.getEntriesByType('resource').filter((e) => e.name.endsWith('/_vf' + f)).length))");
      const aller = async (nom) => { await s.ev(`VF_COQUILLE.chargerOnglet(${JSON.stringify(nom)}).then(() => 1)`); await pause(300); };
      o.jt15 = { charge: await n() };
      await aller('equipe'); await aller('projet'); o.jt15.apres1 = await n();
      await aller('equipe'); await aller('projet'); o.jt15.apres2 = await n();
      o.jt15.onglet = await lire('JSON.stringify(VibeFlow.graph.meta.vfTab)');
    });
  }
  return o;
});
