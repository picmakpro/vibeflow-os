// index-propriete — propriétés génératives de l'index des transcripts (79-08, tâche 3). Le code testé est importé d'un dossier de scripts passé en paramètre (copie mutée comprise).
// Usage : node index-propriete.mjs DOSSIER_DES_SCRIPTS MODE [--graine=N] [--n=40] [--genere=normal|degenere|une-coupe]
// MODE : incrementalite | reecritures | couverture-temoin | cout | retention | chargement (fuzz du fichier d'index). Imprime `graine=N` puis, en dernière ligne, un JSON { plantage, graine, echecs: [{ champs, classes }], couverture: { comptes, manque }, octetsLus } ; sortie 0 dans tous les cas.
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
import { T0, rng, gen, coupes, classesDeCoupe, manque } from './index-generateur.mjs';
const [, , SC, MODE, ...reste] = process.argv, arg = (k, d) => (reste.find((a) => a.startsWith(`--${k}=`)) || `=${d}`).split('=')[1];
const graine = Number(arg('graine', 1)), N = Number(arg('n', 40)), GENERE = arg('genere', 'normal');
console.log(`graine=${graine}`);
const sortie = { plantage: null, graine, echecs: [], couverture: null, octetsLus: null };
const W = process.env.VF_PROP_WORK || fs.mkdtempSync(path.join(os.tmpdir(), 'idxp-')); const LAB = path.join(W, 'lab'); fs.mkdirSync(LAB, { recursive: true });
const imp = (n) => import(pathToFileURL(path.join(SC, n)).href);
const chemins = (a, b, p = '', acc = new Set()) => { if (JSON.stringify(a) === JSON.stringify(b)) return acc; if (a && b && typeof a === 'object' && typeof b === 'object') for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) chemins(a[k], b[k], p ? `${p}.${k}` : k, acc); else acc.add(p); return acc; };
const norm = (p) => p.replace(/^voies\.\d+\./, '').replace(/\.\d+(?=\.|$)/g, '.#');
const sans = (i) => { const c = JSON.parse(JSON.stringify(i)); delete c.genereA; return c; };
const BLOCS = [3, 3, 17, 17, 64, 64, 64, 1000, 1000, 1048576];
const comptes = {};
const compte = (m) => { for (const [k, v] of m) comptes[k] = (comptes[k] || 0) + v; };
const ecrire = (f, buf, mtimeMs) => { fs.writeFileSync(f, buf); fs.utimesSync(f, mtimeMs / 1000, mtimeMs / 1000); };
let M;
try { M = { idx: await imp('vf-cockpit-index.mjs'), cache: await imp('vf-cockpit-index-cache.mjs') }; } catch (e) { sortie.plantage = `import: ${String(e.message).slice(0, 120)}`; console.log(JSON.stringify(sortie)); process.exit(0); }
const tour = (seed) => { const r = rng(seed * 7919 + 13), id = `sess-p${seed}`, g = gen(seed, { lab: LAB, id }), dir = path.join(W, `d${MODE}${seed}`, 'projects', '-lab'); fs.mkdirSync(dir, { recursive: true }); return { r, id, g, dir, f: path.join(dir, id + '.jsonl'), proj: path.join(dir, '..'), maintenant: T0 + g.tFin + 3600e3, mt: T0 + g.tFin }; };
try {
  if (MODE === 'incrementalite' || MODE === 'couverture-temoin') {
    for (let k = 0; k < N; k++) {
      const t = tour(graine * 1000 + k), dege = GENERE !== 'normal', bloc = dege ? 1048576 : BLOCS[Math.floor(t.r() * BLOCS.length)];
      const cs = coupes(t.g, t.r, 3 + Math.floor(t.r() * 10), GENERE === 'une-coupe' ? 'aucune' : dege ? 'fins-de-ligne' : 'varie'), classes = classesDeCoupe(t.g, cs, bloc); compte(classes);
      if (MODE === 'couverture-temoin') continue;
      const O = { maintenant: t.maintenant, bornes: { ligneMax: 4096, bloc }, memoHors: new Map() }; let idx = null; const etapes = [...cs, t.g.buf.length], cache = path.join(W, `c${graine}-${k}`, 'index.json');
      etapes.forEach((c, i) => {
        ecrire(t.f, t.g.buf.subarray(0, c), i === etapes.length - 1 ? t.mt : t.mt - (etapes.length - i) * 1000);
        if (idx && i % 5 === 4) { M.cache.ecrireIndex(cache, W, idx); const l = M.cache.chargerIndex(cache, W, { maintenant: t.maintenant }); idx = l.etat === 'lu' ? l.index : null; } else if (idx) idx = JSON.parse(JSON.stringify(idx));
        idx = M.idx.mettreAJour(idx, M.idx.enumerer(t.proj), O).index;
      });
      const ref = M.idx.construire(M.idx.enumerer(t.proj), { ...O, bornes: { ligneMax: 4096, bloc: 1048576 }, memoHors: new Map() });
      const v = idx.voies[0], p = t.g.oracle; let champs = [...chemins(sans(idx), sans(ref))].map(norm);
      if (v && v.forme === 'ok') { const inv = []; const seg = v.segments, ms = Object.values(v.curseur.etat.msParGenre).reduce((a, b) => a + b, 0);
        if (ms !== v.fin - v.debut) inv.push('invariant.somme-des-durees'); if (!seg.every((s, i) => i === 0 || (s[0] === seg[i - 1][1] && s[2] !== seg[i - 1][2]))) inv.push('invariant.segments');
        if (JSON.stringify(v.jetons) !== JSON.stringify(p.jetons)) inv.push('invariant.jetons'); if (JSON.stringify(v.compteurs) !== JSON.stringify(p.compteurs)) inv.push('invariant.compteurs'); champs = champs.concat(inv); }
      else if (!v || v.forme !== 'ok') champs.push('invariant.forme');
      if (champs.length) sortie.echecs.push({ champs: [...new Set(champs)], classes: [...classes.keys()], graine: graine * 1000 + k });
    }
    sortie.couverture = { comptes, manque: manque(comptes) };
  } else if (MODE === 'reecritures') {
    for (let k = 0; k < N; k++) {
      const t = tour(graine * 1000 + k + 500), O = { maintenant: t.maintenant, bornes: { ligneMax: 4096, bloc: BLOCS[Math.floor(t.r() * BLOCS.length)] }, memoHors: new Map() }; let base = t.g.buf, cur = Buffer.alloc(0), idx = null, mt = t.mt - 100000; const ops = [], champs = new Set();
      const maj = () => { mt += 1000; if (fs.existsSync(t.f)) fs.utimesSync(t.f, mt / 1000, mt / 1000); idx = M.idx.mettreAJour(idx && JSON.parse(JSON.stringify(idx)), M.idx.enumerer(t.proj), O).index; const ref = M.idx.construire(M.idx.enumerer(t.proj), { ...O, memoHors: new Map(), bornes: { ...O.bornes, bloc: 1048576 } }); for (const c of chemins(sans(idx), sans(ref))) champs.add(norm(c)); };
      for (let s = 0, n = 4 + Math.floor(t.r() * 4); s < n; s++) {
        const x = t.r(); let op;
        if (s === 0 || x < 0.4) { op = 'ajout'; cur = base.subarray(0, Math.min(base.length, cur.length + 1 + Math.floor(t.r() * (base.length - cur.length + 1)))); ecrire(t.f, cur, mt); }
        else if (x < 0.6 && idx && idx.voies[0] && idx.voies[0].curseur.octets > 0) { op = 'raccourcir'; cur = base.subarray(0, Math.floor(t.r() * idx.voies[0].curseur.octets)); ecrire(t.f, cur, mt); }
        else if (x < 0.85 && cur.indexOf(10) >= 0) { op = 'reecrire-tete'; const nl = base.indexOf(10), pad = 'p'.repeat(1 + Math.floor(t.r() * 30)), nv = Buffer.from(JSON.stringify({ ...JSON.parse(base.subarray(0, nl).toString()), pad }) + '\n'); base = Buffer.concat([nv, base.subarray(nl + 1)]); cur = base.subarray(0, Math.min(base.length, cur.length + nv.length - nl - 1 + Math.floor(t.r() * 400))); ecrire(t.f, cur, mt); }
        else { op = 'recreer'; fs.rmSync(t.f, { force: true }); maj(); cur = base.subarray(0, Math.floor(t.r() * base.length)); ecrire(t.f, cur, mt); }
        ops.push(op); maj();
      }
      if (champs.size) sortie.echecs.push({ champs: [...champs], classes: [...new Set(ops)], graine: graine * 1000 + k });
    }
  } else if (MODE === 'cout') {
    const rs = fs.readSync; let lus = 0; fs.readSync = (...a) => { const n = rs(...a); lus += n; return n; }; sortie.octetsLus = { premiere: [], ajout: [], permis: [] };
    for (let k = 0; k < 6; k++) {
      const t = tour(graine * 1000 + k + 900), c = t.g.lignes[Math.floor(t.g.lignes.length * 0.6)].fin, O = { maintenant: t.maintenant, memoHors: new Map(), bornes: { ligneMax: 4096 } };
      ecrire(t.f, t.g.buf.subarray(0, c), t.mt - 5000); lus = 0; let idx = M.idx.mettreAJour(null, M.idx.enumerer(t.proj), O).index; sortie.octetsLus.premiere.push(lus);
      const octets = idx.voies[0].curseur.octets; ecrire(t.f, t.g.buf, t.mt); lus = 0; idx = M.idx.mettreAJour(JSON.parse(JSON.stringify(idx)), M.idx.enumerer(t.proj), O).index;
      const permis = t.g.buf.length - octets + 1024; sortie.octetsLus.ajout.push(lus); sortie.octetsLus.permis.push(permis);
      if (lus > permis) sortie.echecs.push({ champs: ['cout.octets-lus'], classes: ['ajout'], graine: graine * 1000 + k });
    }
    fs.readSync = rs;
  } else if (MODE === 'chargement') {
    const t = tour(graine * 1000 + 1), ref = T0 + t.g.tFin + 3600e3; ecrire(t.f, t.g.buf, t.mt); const base = M.idx.construire(M.idx.enumerer(t.proj), { maintenant: ref, memoHors: new Map() }), r = t.r;
    const INTERDITES = new Set(['doing', 'mandat', 'messages', 'outils', 'fil', 'cibles', 'ecritures', 'lectures', 'cible']);
    // vérificateur d'invariants écrit à part du validateur du module
    const viole = (i) => { const v = []; const ent = (x) => Number.isInteger(x) && x >= 0, inst = (x) => Number.isFinite(x) && x >= Date.UTC(2020, 0, 1) && x <= ref + 86400e3;
      const cle = (o, d = 0) => { if (d > 12 || !o || typeof o !== 'object') return; for (const k of Object.keys(o)) { if (INTERDITES.has(k)) v.push(`cle:${k}`); cle(o[k], d + 1); } }; cle(i);
      if (i.schema !== 'vibeflow/cockpit-index@1' || !Array.isArray(i.voies) || i.voies.length > 2000 || i.fenetreS !== 86400) v.push('entete');
      for (const x of Array.isArray(i.voies) ? i.voies : []) {
        if (!/^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/.test(String(x.id)) || !/^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/.test(String(x.session))) v.push('id'); if (x.arbre !== null && (typeof x.arbre !== 'string' || /[/\\]/.test(x.arbre))) v.push('arbre');
        for (const k of ['debut', 'fin']) if (x[k] !== null && !inst(x[k])) v.push(k); const c = x.curseur;
        if (!c || !ent(c.octets) || !ent(c.taille) || c.octets > c.taille || Object.keys(c.ouverts || {}).length > 64) v.push('curseur');
        if ((x.forme === 'inconnue') !== (x.jetons === null)) v.push('forme-mesures'); if (Array.isArray(x.segments)) { if (x.segments.length > 500 || x.segments.some((s, k) => !inst(s[0]) || !inst(s[1]) || s[1] <= s[0] || (k && s[0] < x.segments[k - 1][1]))) v.push('segments'); }
        if (x.compteurs && Object.values(x.compteurs).some((n) => !ent(n))) v.push('compteurs'); if (x.jetons && Object.values(x.jetons).some((n) => !ent(n))) v.push('jetons');
      } return v; };
    const chemins2 = []; const marche = (o, p) => { chemins2.push(p); if (o && typeof o === 'object') for (const k of Object.keys(o)) marche(o[k], [...p, k]); }; marche(base, []);
    const AUTRES = [null, 'x', 5, [], {}, true, -1, 1e308, '../../x', '__proto__', 1.5, 'a'.repeat(300)]; let ecartees = 0, acceptees = 0;
    for (let n = 0; n < 200; n++) {
      const m = JSON.parse(JSON.stringify(base)), p = chemins2[Math.floor(r() * chemins2.length)], op = r(); let hote = m; for (const k of p.slice(0, -1)) hote = hote[k]; const k = p[p.length - 1];
      if (p.length === 0) { hote = null; }
      if (hote && k !== undefined) { if (op < 0.2) delete hote[k]; else if (op < 0.65) hote[k] = AUTRES[Math.floor(r() * AUTRES.length)]; else if (op < 0.8) hote[k] = typeof hote[k] === 'number' ? hote[k] + 1 : hote[k]; else if (typeof hote === 'object' && !Array.isArray(hote)) hote[['doing', 'cibles', 'mandat'][Math.floor(r() * 3)]] = 1; else hote[k] = hote[k]; }
      const rep = M.cache.validerIndex(m, { maintenant: ref }); if (!rep.ok) { ecartees++; continue; } acceptees++; let vv; try { vv = viole(m); } catch { vv = ['verificateur-plante-sur-index-accepte']; } if (vv.length) sortie.echecs.push({ champs: [...new Set(vv)], classes: ['index-accepte'], graine: n });
    }
    sortie.couverture = { comptes: { ecartees, acceptees, total: 200 }, manque: [] };
  } else if (MODE === 'retention') {
    for (let k = 0; k < N; k++) {
      const t = tour(graine * 1000 + k + 700), g = gen(graine * 1000 + k + 700, { lab: LAB, id: t.id, abandonne: true }), r = t.r, wid = `w${k}`, H = 3600e3;
      const sd = path.join(t.dir, t.id, 'subagents'); fs.mkdirSync(sd, { recursive: true }); const fin = T0 + g.tFin, w = [0, 5 * H, 20 * H][Math.floor(r() * 3)], tW = fin + w;
      const meta = { agentType: 'vf-coder', description: 'x', spawnDepth: 1, toolUseId: 'toolu_w', requestShape: 'background' }, ligneW = (ts, o) => JSON.stringify({ cwd: LAB, sessionId: t.id, isSidechain: true, agentId: wid, version: '2.1.322', timestamp: new Date(ts).toISOString(), ...o });
      ecrire(t.f, g.buf, fin); fs.writeFileSync(path.join(sd, `agent-${wid}.meta.json`), JSON.stringify(meta));
      ecrire(path.join(sd, `agent-${wid}.jsonl`), Buffer.from([ligneW(tW - 1000, { type: 'user', message: { role: 'user', content: 'x' } }), ligneW(tW, { type: 'assistant', message: { id: 'mw', model: 'claude-test-1', usage: { input_tokens: 1, output_tokens: 1 }, content: [{ type: 'text', text: 'x' }] } })].join('\n') + '\n'), tW);
      const i0 = M.idx.construire(M.idx.enumerer(t.proj), { maintenant: fin + H, memoHors: new Map() }), d = [-2 * H, -H / 2, H / 2, 2 * H][Math.floor(r() * 4)], m2 = fin + 24 * H + d, viv = new Set([t.id, wid].filter(() => r() < 0.4));
      const i1 = M.idx.mettreAJour(JSON.parse(JSON.stringify(i0)), M.idx.enumerer(t.proj), { maintenant: m2, memoHors: new Map(), vivantes: viv }).index, vus = new Set(i1.voies.map((v) => v.id));
      const keepW = tW >= m2 - 24 * H || viv.has(wid), keepS = fin >= m2 - 24 * H || viv.has(t.id) || keepW;
      const ecarts = []; if (vus.has(t.id) !== keepS) ecarts.push(vus.has(t.id) ? 'gardee-a-tort' : 'purgee-a-tort'); if (vus.has(wid) !== keepW && !(keepW === false && vus.has(wid) && keepS && false)) ecarts.push('worker-' + (vus.has(wid) ? 'garde-a-tort' : 'purge-a-tort'));
      if (ecarts.length) sortie.echecs.push({ champs: ecarts, classes: ['abandonne-en-plein-appel', ...(d > 0 ? ['hors-fenetre'] : [])], graine: graine * 1000 + k });
    }
  }
} catch (e) { sortie.plantage = `${e.name}: ${String(e.message).slice(0, 160)}`; }
if (MODE === 'couverture-temoin') sortie.couverture = { comptes, manque: manque(comptes) };
fs.rmSync(W, { recursive: true, force: true });
console.log(JSON.stringify(sortie));
