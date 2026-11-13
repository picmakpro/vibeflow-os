// chrome-finitions.mjs — mesures en rendu des finitions de la charte (80-17, FORM-14, P80-D-20 : AUDC-F1, F3, F4, F5), un vrai Chrome headless.
// Usage : node chrome-finitions.mjs <chrome> <racine-du-serveur> <mode> [<dossier scripts du module>]   Rend UNE ligne JSON { … } ou { erreur }.
//   fi1 / fi1t : disclosures (Historique, Détails techniques, menu du lancement) et #vf-modele, souris / toucher ; fi1q : #proposition-mode de la page de Q
//   fi15       : 03-vf-charte.js chargé, une seule feuille et aucun nœud ajouté aux summary après deux allers-retours d'onglet
//   fi2 / fi2t : hauteurs des boutons d'en-tête et ouvreur Git à 1440, 1100, 900 et 800 px (souris) puis 1100 px (toucher)
//   fi3        : chiffres tabulaires (#vf-lock, Équipe : éléments posés dans la page réelle) et pastilles du menu « ⋯ » en thème clair à 800 px
//   fi34       : zone basse à 390 et 800 px, feuille de détail ouverte puis fermée, couloirs puis liste
// Chaque section est isolée (sec) : une section qui échoue laisse ses champs vides. Aucun fichier de la sortie n'est lu.
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { executer, pause, stabiliser } from './chrome-session.mjs';
const [, , chrome, racine, mode, scripts] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
// aides posées dans la page : couleur normalisée, rapport de contraste, angle d'un pseudo-élément, lecture d'un summary et d'un select
const AIDES = `window.__j = (() => {
  const cv = document.createElement('canvas').getContext('2d', { willReadFrequently: true });
  const norm = (c) => { cv.clearRect(0, 0, 1, 1); cv.fillStyle = '#000'; cv.fillStyle = c; cv.fillRect(0, 0, 1, 1);
    const d = cv.getImageData(0, 0, 1, 1).data; return [d[0], d[1], d[2], d[3] / 255]; };
  const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; };
  const lum = (c) => 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2]);
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return Math.round(((Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)) * 100) / 100; };
  const rgb = (c) => norm(c).slice(0, 3).join();
  const jeton = (t) => { const p = document.createElement('i'); p.style.cssText = 'color: var(' + t + ')'; document.body.appendChild(p);
    const c = rgb(getComputedStyle(p).color); p.remove(); return c; };
  const angle = (e) => { const t = getComputedStyle(e, '::before').transform; if (!t || t === 'none') return 0;
    const v = t.match(/matrix\\(([^)]+)\\)/)[1].split(',').map(Number); return Math.round(Math.atan2(v[1], v[0]) * 180 / Math.PI); };
  const attendre = (ms) => new Promise((r) => setTimeout(r, ms));
  const resume = (S) => { const cs = getComputedStyle(S), ch = getComputedStyle(S, '::before'); S.parentElement.open = false;
    return { ls: cs.listStyleType, marq: getComputedStyle(S, '::-webkit-details-marker').display, chev: [ch.content, ch.width, ch.height],
      h: Math.round(S.getBoundingClientRect().height), ferme: angle(S) }; };
  const ouvert = async (S) => { S.parentElement.open = false; await attendre(300); S.parentElement.open = true; await attendre(450); return angle(S); };
  const reduit = (S) => { const d = S.parentElement; d.open = false; getComputedStyle(S, '::before').transform; d.open = true;
    return [angle(S), S.getAnimations({ subtree: true }).filter((a) => a.playState === 'running' || a.playState === 'pending').length]; };
  const select = (e) => { const cs = getComputedStyle(e), root = getComputedStyle(document.documentElement);
    const r = { app: cs.appearance, h: Math.round(e.getBoundingClientRect().height), fond: rgb(cs.backgroundColor), raise: jeton('--raise'),
      bord: cs.borderTopWidth, bordCouleur: rgb(cs.borderTopColor), rayon: cs.borderTopLeftRadius, schema: cs.colorScheme, racine: root.colorScheme,
      image: /gradient/.test(cs.backgroundImage), url: /url\\(/.test(cs.backgroundImage) };
    e.disabled = true; const d = getComputedStyle(e); r.off = [rgb(d.color), jeton('--text-4'), d.opacity]; e.disabled = false; return r; };
  return { norm, ratio, rgb, jeton, angle, attendre, resume, ouvert, reduit, select };
})()`;
const BOUTONS = "JSON.stringify([...document.querySelectorAll('header .hr .btn, header #hdr-ext > button')]"
  + ".filter((e) => e.id !== 'vf-git-ouvreur' && e.getBoundingClientRect().height > 0)"
  + ".map((e) => [e.id, Math.round(e.getBoundingClientRect().height), Math.round(e.getBoundingClientRect().width)]))";
const OUVREUR = "JSON.stringify((() => { const e = document.getElementById('vf-git-ouvreur'); if (!e) return null;"
  + " const r = e.getBoundingClientRect(); return [Math.round(r.width), Math.round(r.height)]; })())";
// la feuille de l'Équipe n'est posée par 70-vf-live.js qu'au premier dessin du tiroir « Au travail » : la sonde la pose comme lui (poserCss)
const EQUIPE = `JSON.stringify((() => { const b = getComputedStyle(document.body), box = document.createElement('div'); box.id = 'sonde-equipe';
  const st = document.createElement('style'); st.textContent = window.__vfEquipeRendu.css; document.head.appendChild(st);
  box.innerHTML = '<div class="aw-driver"><span class="n">3</span></div><span class="r-t">5 min</span>'
    + '<div class="r-meta"><b>12</b></div><ul class="r-verr"><li><span class="n">2</span></li></ul>';
  document.body.appendChild(box);
  return ['.aw-driver .n', '.r-t', '.r-meta b', '.r-verr .n'].map((q) => { const c = getComputedStyle(box.querySelector(q));
    return [q, c.fontFamily === b.fontFamily, /tabular-nums/.test(c.fontVariantNumeric), c.fontWeight]; }); })())`;
const LOCK = `JSON.stringify((() => { const e = document.getElementById('vf-lock'), c = getComputedStyle(e), b = getComputedStyle(document.body);
  return [c.fontFamily === b.fontFamily, /tabular-nums/.test(c.fontVariantNumeric), c.fontWeight]; })())`;
// deux sources de pastilles, comme les posent 20-health.js et 25-recent.js (le bouton, puis la pastille, puis les variables de teinte, dans le même tour)
const POSER = `(() => { const SC = window.VibeFlow;
  const bouton = (id) => document.getElementById(id)
    || SC.addHeaderButton({ id, svg: '<circle cx="12" cy="12" r="4"/>', title: id + ' de test', onClick() {} });
  const sante = bouton('btn-health'), recent = bouton('btn-recent');
  for (const [b, texte] of [[sante, '3'], [recent, '2']]) { b.hidden = false; b.querySelector('.badge')?.remove();
    const p = document.createElement('span'); p.className = 'badge'; p.textContent = texte; b.appendChild(p); }
  // la teinte de Récent vient de la feuille de 25-recent.js (#btn-recent .badge), absente ici sans donnée : posée comme elle la pose
  recent.querySelector('.badge').style.cssText = 'background: var(--recent); color: var(--on-recent-text)';
  sante.style.setProperty('--hc-badge', 'var(--sev-medium)'); sante.style.setProperty('--hc-badge-text', 'var(--on-sev-text)'); return true; })()`;
const PASTILLES = `JSON.stringify((() => { const J = window.__j, ouvreur = document.getElementById('vf-plus');
  const point = () => { const e = document.querySelector('#vf-plus .badge'); return e ? J.rgb(getComputedStyle(e).backgroundColor) : null; };
  const avant = point(); ouvreur.click();
  const nom = (id) => { const b = document.getElementById(id);
    return (b.querySelector('.bl')?.textContent || b.getAttribute('aria-label') || b.title || '').trim(); };
  const lire = (id) => { const it = [...document.querySelectorAll('.vf-pl-i')].find((x) => x.querySelector('.vf-pl-t')?.textContent === nom(id));
    const e = it && it.querySelector('.badge'); if (!e) return null;
    const c = getComputedStyle(e);
    return { fond: J.rgb(c.backgroundColor), texte: J.rgb(c.color), ratio: J.ratio(J.norm(c.color), J.norm(c.backgroundColor)) }; };
  return { sante: lire('btn-health'), recent: lire('btn-recent'), point: avant,
    attendu: { sante: [J.jeton('--sev-medium'), J.jeton('--on-sev-text')],
      recent: [J.jeton('--recent'), J.jeton('--on-recent-text')], on: J.jeton('--on') } }; })())`;
const MESURE = `(() => { const R = (e) => { if (!e || e.hidden) return null; const b = e.getBoundingClientRect();
    return b.width > 0 && b.height > 0 ? { left: b.left, right: b.right, top: b.top, bottom: b.bottom } : null; };
  const a = document.activeElement, k = a && a.closest ? a.closest('.vp-carte, .vp-ligne') : null, c = R(k), p = document.getElementById('panel');
  const feuille = !document.body.classList.contains('no-panel') && R(p);
  const o = { ask: R(document.getElementById('ask')), pastille: R(document.querySelector('.vf-term-pastille')),
    feuille: feuille && feuille.right - feuille.left >= document.getElementById('stage').getBoundingClientRect().width * 0.8 ? feuille : null };
  const inter = Object.keys(o).filter((n) => c && o[n] && c.left < o[n].right && c.right > o[n].left && c.top < o[n].bottom && c.bottom > o[n].top);
  const v = document.querySelector('section.vf-projet');
  return JSON.stringify({ focus: !!k, inter, pastille: !!o.pastille, large: v ? v.scrollWidth <= v.clientWidth + 1 : null,
    modele: Math.round(document.getElementById('vf-modele').getBoundingClientRect().height) }); })()`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} };
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const sec = async (nom, f) => { try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 160); } };
  const lire = async (expr) => { const v = await s.ev(expr); return v === undefined ? null : JSON.parse(v); };
  const J = (appel) => lire(`JSON.stringify(${appel})`);
  const theme = (t) => s.ev(`document.documentElement.setAttribute('data-theme', '${t === 'clair' ? 'light' : 'dark'}')`);
  const charger = async (page, w, h, tactile = false) => {
    await s.send('Emulation.setTouchEmulationEnabled', { enabled: tactile });
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
    await s.naviguer(`${racine}/${page}`, { brut: true }); await s.attendre(PRET, 'page prête');
    await stabiliser(() => s.ev("document.querySelectorAll('#viewport .node, .vp-carte').length"), { pas: 120, max: 5000 });
    await pause(500); await s.ev(AIDES);
  };
  const touche = async (k, vk) => {
    for (const type of ['keyDown', 'keyUp']) {
      await s.send('Input.dispatchKeyEvent', { type, key: k, code: k, windowsVirtualKeyCode: vk, nativeVirtualKeyCode: vk });
    }
  };
  const q = (sel) => JSON.stringify(sel);
  const resume = (sel) => J(`(() => { const S = document.querySelector(${q(sel)}); return S && window.__j.resume(S); })()`);
  const ouvert = (sel) => lire(`(async () => JSON.stringify(await window.__j.ouvert(document.querySelector(${q(sel)}))))()`);
  const select = (sel) => J(`(() => { const e = document.querySelector(${q(sel)}); return e && window.__j.select(e); })()`);
  const COULOIRS = 'project.html?vue=couloirs&lang=en';

  if (mode === 'fi1' || mode === 'fi1t') {
    const tactile = mode === 'fi1t';
    await sec('fi1', async () => {
      await charger(COULOIRS, 1440, 900, tactile);
      const H = '.vp-details[data-cle="historique"] > summary';
      o.historique = await resume(H); o.historiqueOuvert = await ouvert(H);
      if (tactile) { o.select = await select('#vf-modele'); return; }
      o.modele = [await select('#vf-modele')];
      for (const t of ['clair', 'sombre']) { await theme(t); await pause(150); o.modele.push(await select('#vf-modele')); }
      await s.ev("document.querySelector('.vp-carte[data-id=\"n:ph-3\"]').click()");
      await s.ev("VibeFlow.reveal('n:ph-3')"); await pause(1500);
      const T = '#panel details.vf-tech > summary', L = '[data-vf-lancer] details > summary';
      o.tech = await resume(T); o.techOuvert = await ouvert(T); o.lancer = await resume(L); o.lancerOuvert = await ouvert(L);
      await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] }); await pause(200);
      o.reduit = await J(`window.__j.reduit(document.querySelector(${q(T)}))`);
    });
    return o;
  }

  if (mode === 'fi1q') {
    await sec('fi1q', async () => {
      await charger(COULOIRS, 1440, 900); await theme('sombre'); await pause(200);
      o.lab = await select('#vf-modele');
      const page = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-terminal-page.mjs')).href);
      page.preparerPage({ engineDir: path.join(scripts, '..', 'skills', 'cockpit-moteur') });
      const { html } = page.pageTerminal({ theme: 'dark', origineP: racine });
      await s.send('Page.navigate', { url: 'about:blank' }); await pause(400);
      const sans = html.replace(/<script[\s\S]*?<\/script>/g, '');
      await s.ev(`(() => { document.open(); document.write(${JSON.stringify(sans)}); document.close(); return true; })()`);
      await pause(500); await s.ev(AIDES);
      await s.ev(`(() => { const e = document.createElement('select'); e.id = 'proposition-mode';
        e.innerHTML = '<option>acceptEdits</option><option>plan</option>'; document.body.appendChild(e); })()`);
      o.q = await select('#proposition-mode');
    });
    return o;
  }

  if (mode === 'fi15') {
    await sec('fi15', async () => {
      await charger(COULOIRS, 1440, 900);
      const n = () => J(`[performance.getEntriesByType('resource').filter((e) => e.name.endsWith('/_vf/ui/03-vf-charte.js')).length,
        document.querySelectorAll('style[data-vf-charte]').length, [...document.querySelectorAll('summary')].reduce((t, e) => t + e.children.length, 0)]`);
      const aller = async (nom) => { await s.ev(`VF_COQUILLE.chargerOnglet(${JSON.stringify(nom)}).then(() => 1)`); await pause(400); };
      o.charge = await n(); await aller('equipe'); await aller('projet'); o.apres1 = await n();
      await aller('equipe'); await aller('projet'); o.apres2 = await n();
      o.chevron = await J("[...document.querySelectorAll('.vp-details > summary')].map((e) => getComputedStyle(e, '::before').content)");
    });
    return o;
  }

  if (mode === 'fi2' || mode === 'fi2t') {
    const plan = mode === 'fi2t' ? [[1100, 800, true]] : [[1440, 900, false], [1100, 800, false], [900, 800, false], [800, 800, false]];
    for (const [w, h, t] of plan) {
      await sec('fi2-' + w, async () => {
        await charger(COULOIRS, w, h, t); await pause(400);
        o['b' + w] = { boutons: await lire(BOUTONS), ouvreur: await lire(OUVREUR) };
      });
    }
    return o;
  }

  if (mode === 'fi3') {
    await sec('fi3a', async () => {
      await charger(COULOIRS, 1440, 900); o.lock = await lire(LOCK);
      o.mono = await J("(() => { const e = document.querySelector('.vf-git-ligne'); return e ? /mono/i.test(getComputedStyle(e).fontFamily) : null; })()");
    });
    await sec('fi3b', async () => { await charger('equipe.html?lang=en', 1440, 900); o.equipe = await lire(EQUIPE); });
    await sec('fi3c', async () => {
      await charger(COULOIRS, 800, 900); await theme('clair'); await pause(300);
      await s.ev(POSER); await pause(500); o.pastilles = await lire(PASTILLES);
    });
    return o;
  }

  if (mode === 'fi34') {
    o.zone = {};
    for (const [w, h] of [[390, 844], [800, 900]]) {
      for (const vue of ['couloirs', 'liste']) {
        await sec(`fi34-${w}-${vue}`, async () => {
          await charger(`project.html?vue=${vue}&lang=en`, w, h, w < 500); const r = {};
          const fin = async (nom) => {
            await s.ev("(document.querySelector('.vp-carte[tabindex=\"0\"], .vp-ligne[tabindex=\"0\"], .vp-carte, .vp-ligne')).focus()");
            await touche('End', 35); await pause(450); r[nom] = await lire(MESURE);
          };
          await fin('base'); await s.ev("VibeFlow.select('n:ph-3')"); await pause(600); await fin('feuille');
          await s.ev('VibeFlow.select(null)'); await pause(300); await fin('ferme'); o.zone[`${w}-${vue}`] = r;
        });
      }
    }
    return o;
  }
  return o;
});
