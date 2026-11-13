#!/usr/bin/env bash
# test-cockpit-fiche-texte.sh — fil de la fiche d'agent et markdown fermé, sans navigateur (Phase 74, plan 74-03 ; TEMP-08, TEMP-11 ; P74-D-17, D-18, D-19, D-48).
# Les deux modules (ui/74-vf-fiche-md.js, ui/74-vf-fiche-texte.js) sont chargés sous node:vm depuis l'emplacement de la suite, avec un document factice
# qui journalise balises, textes, attributs on* et tout accès à innerHTML, outerHTML, insertAdjacentHTML, document.write. Fixtures en mémoire,
# SYNTHÉTIQUES : aucune requête, aucun transcript réel. Aucun serveur n'est lancé.
#   X0  contrôle positif : dossier sans modules -> « absent » et chaque sonde X1 à X10 échoue (les sondes savent rougir)
#   X1  balisage hostile en texte        X2  lien jamais actif                 X3  aucun accès innerHTML et consorts
#   X4  sous-ensemble fermé              X5  filtres cumulables et compteur    X6  liste blanche, lignes sans texte
#   X7  lireFil : schéma, erreur, inconnu X8  cible et nom d'outil hostiles    X9  temps borné et plafond
#   X10 fusionnerEvenements (a à h)   X12 corpus hostile : jeu fermé, aucun attribut, classes fixes   X13 genre hors du jeu fermé   X14 lien non fermé
#   X11 mutants (copies des modules sous $WORK/mut-<nom>/) : a M-INNERHTML (X3), b M-LIEN (X2), c M-RENDU-TOUT (X6), d M-FILTRE-ET (X5),
#       e M-BACKTRACK (X9), f M-FUSION-SANS-BORNE (X10), g M-FUSION-EN-CONSTRUCTION (X10), h M-INCONNU-VIDE (X7), i M-PLAFOND (X9),
#       j M-AUTOLIEN (X12), k M-STYLE (X12), l M-GENRE-CLASSE (X13), m M-LIEN-OUVERT (X14), n M-LIEN-FAIBLE (X14) ;
#       chaque mutant imprime « MUTANT-ROUGE <nom> <sonde> » quand sa sonde rougit, « MUTANT-VERT <nom> <sonde> » (plus un FAIL) sinon.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
HERE_T="$(cd "$(dirname "$0")" && pwd)"
UI="$(cd "$HERE_T/../../skills/cockpit-moteur/assets/ui" && pwd)"

WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX"
PIDS=()

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- le coureur : charge les modules d'un dossier sous node:vm, joue les sondes, imprime « <clé> ok » ou « <clé> ko <détail> » ---
cat > "$AUX/fiche-run.mjs" <<'JS'
// fiche-run.mjs <dossier des modules> : sondes X1 à X10 sur les deux modules de la fiche (document factice journalisé).
import vm from 'node:vm';
import fs from 'node:fs';
import path from 'node:path';
import { performance } from 'node:perf_hooks';
const dir = process.argv[2];
const FICHIERS = ['74-vf-fiche-md.js', '74-vf-fiche-texte.js'];
let LOG;
const reset = () => { LOG = { tags: [], texts: [], on: [], html: 0, attrs: [], classes: [], props: [] }; };
const txt = (s) => ({ tag: '#text', data: String(s) });
const texteDe = (n) => (n && n.tag === '#text' ? n.data : n && n.children ? n.children.map(texteDe).join('') : '');
const trouver = (n, f, out = []) => { if (n && n.children) { if (f(n)) out.push(n); n.children.forEach((c) => trouver(c, f, out)); } return out; };
const mk = (tag, journal) => {
  if (journal) LOG.tags.push(String(tag).toLowerCase());
  const e = { tag: String(tag).toLowerCase(), children: [], className: '' };
  e.appendChild = (n) => { if (n && n.tag === '#fragment') e.children.push(...n.children); else e.children.push(n); return n; };
  e.append = (...ns) => ns.forEach((n) => e.appendChild(typeof n === 'string' ? txt(n) : n));
  e.setAttribute = (k, v) => { if (/^on/i.test(k)) LOG.on.push(k); LOG.attrs.push(k + '=' + v); };
  e.insertAdjacentHTML = () => { LOG.html++; };
  e.classList = { add: (...c) => { LOG.classes.push(...c); e.className += ' ' + c.join(' '); } };
  return new Proxy(e, {
    get: (t, k) => { if (k === 'innerHTML' || k === 'outerHTML') { LOG.html++; return ''; } if (k === 'textContent') return texteDe(t); return t[k]; },
    set: (t, k, v) => {
      if (k === 'innerHTML' || k === 'outerHTML') { LOG.html++; return true; }
      if (typeof k === 'string' && /^on/i.test(k)) LOG.on.push(k);
      if (k === 'textContent') { t.children = [txt(v)]; LOG.texts.push(String(v)); return true; }
      if (k === 'className') LOG.classes.push(String(v)); else LOG.props.push(String(k));
      t[k] = v; return true;
    },
  });
};
const mkDoc = () => ({
  createElement: (t) => mk(t, true), createElementNS: (ns, t) => mk(t, true),
  createTextNode: (s) => { LOG.texts.push(String(s)); return txt(s); },
  createDocumentFragment: () => mk('#fragment', false), write: () => { LOG.html++; }, writeln: () => { LOG.html++; },
});
const out = [];
const ligne = (k, r) => out.push(k + ' ' + (r === true ? 'ok' : 'ko ' + (typeof r === 'string' ? r : JSON.stringify(r))));
const sonde = (k, fn) => { let r; try { reset(); r = fn(); } catch (e) { r = 'lance : ' + (e && e.message); } ligne(k, r); return r === true; };

const ctx = vm.createContext({ Intl, Date, window: {} });
const absent = FICHIERS.filter((f) => !fs.existsSync(path.join(dir, f)));
if (!absent.length) for (const f of FICHIERS) vm.runInContext(fs.readFileSync(path.join(dir, f), 'utf8'), ctx, { filename: f });
out.push('absent ' + (absent.length ? 1 : 0));
const KEYS = ['X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7', 'X8', 'X9', 'X12', 'X13', 'X14', 'X10', 'X10a', 'X10b', 'X10c', 'X10d', 'X10e', 'X10f', 'X10g', 'X10h'];
if (absent.length) { KEYS.forEach((k) => ligne(k, 'absent')); console.log(out.join('\n')); process.exit(0); }

const Md = ctx.window.__vfFicheMd, F = ctx.window.__vfFicheTexte;
const T = Date.parse('2026-11-13T10:00:00Z');
const iso = (ms) => new Date(ms).toISOString();
const msgL = (ms, texte) => ({ t: iso(ms), genre: 'message', texte });
const outL = (ms, extra) => ({ t: iso(ms), genre: 'outil', outil: 'Edit', verbe: 'modifie', cible: 'a.js', ...extra });
const brut = (fil, extra) => ({ schema: 'vibeflow/cockpit-transcript@2', id: 'ag1', fil, ...extra });
const corps = (li) => texteDe(trouver(li, (n) => /vf-fiche-texte/.test(n.className))[0]);
const SECRETS = ['ERREUR-SECRETE-74', 'rm -rf', 'PIEGE-74'];

sonde('X1', () => {
  const m = '<img src=x onerror=alert(1)>'; const d = mkDoc();
  const fr = Md.markdown(m, d);
  return (!LOG.tags.includes('img') && LOG.on.length === 0 && LOG.texts.includes(m) && texteDe(fr) === m && LOG.tags.length > 0) || { tags: LOG.tags, on: LOG.on };
});
sonde('X2', () => {
  const d = mkDoc(); const fr = Md.markdown('[x](javascript:alert(1)) et [y](https://a.b/c)', d); const t = texteDe(fr);
  return (!LOG.tags.includes('a') && !LOG.attrs.some((a) => /^href/.test(a)) && t.includes('x (javascript:alert(1))') && t.includes('y (https://a.b/c)')) || { tags: LOG.tags, t };
});
sonde('X3', () => {
  const d = mkDoc();
  Md.markdown('para\n\n```\n<b>x</b>\n```\n\n- a\n- `b`\n\n*e* **g** <u onclick=1>', d);
  Md.mandatDom('<script>x</script>', d);
  F.ligneDom(msgL(T, '```\n<i>y</i>\n```'), d, {});
  F.ligneDom(outL(T, { cible: '<b>z</b>' }), d, {});
  return (LOG.html === 0 && LOG.tags.length > 0 && LOG.tags.includes('pre')) || { html: LOG.html, tags: LOG.tags.length };
});
sonde('X4', () => {
  const d = mkDoc();
  const fr = Md.markdown('para un\n\n- a\n- b\n\n1. un\n2. deux\n\nAvec `code` et *em* et **fort**.\n\n```\nbloc <b>\nx\n```\n\n# titre\n| a | b |\n> cit', d);
  const OK = ['p', 'ul', 'ol', 'li', 'code', 'pre', 'em', 'strong'];
  const t = texteDe(fr); const pre = trouver(fr, (n) => n.tag === 'pre')[0];
  const bons = LOG.tags.every((x) => OK.includes(x)) && OK.every((x) => LOG.tags.includes(x));
  return (bons && t.includes('# titre') && t.includes('| a | b |') && t.includes('> cit') && texteDe(pre) === 'bloc <b>\nx') || { tags: [...new Set(LOG.tags)], t };
});
sonde('X5', () => {
  const lu = F.lireFil(brut([msgL(T, 'un'), outL(T + 1000), msgL(T + 2000, 'deux'), outL(T + 3000, { echec: true })]));
  const fus = F.fusionnerEvenements(lu.lignes, [[T + 1500, 'humain'], [T + 2500, 'compaction']], { tronque: false, etatSource: 'lue' });
  const f = (o) => F.filtrer(fus, o); const c = (o) => f(o).affichees;
  const m = f({ messages: true });
  const r = { total: fus.length, tout: f({}).affichees, m: c({ messages: true }), sansCompaction: m.lignes.every((l) => l.genre !== 'compaction'),
    me: f({ messages: true, erreurs: true }), o: c({ outils: true }), e: c({ erreurs: true }) };
  return (r.total === 6 && r.tout === 6 && r.m === 3 && r.sansCompaction && r.me.affichees === 4 && r.me.total === 6 && r.o === 2 && r.e === 1) || r;
});
sonde('X6', () => {
  const d = mkDoc(); const noms = [];
  const gl = (n) => { noms.push(n); return null; };
  const raw = outL(T, { echec: true, texteErreur: 'ERREUR-SECRETE-74', entree: 'rm -rf' });
  const li = F.ligneDom(raw, d, { glyphe: gl });
  const lu = F.lireFil(brut([raw]));
  const hu = F.ligneDom({ t: iso(T), genre: 'humain', texte: 'PIEGE-74' }, d, { glyphe: gl });
  const co = F.ligneDom({ t: iso(T), genre: 'compaction', texte: 'PIEGE-74' }, d, { glyphe: gl });
  const tout = texteDe(li) + texteDe(hu) + texteDe(co);
  const r = { c: corps(li), h: corps(hu), k: corps(co), noms, cle: Object.keys(lu.lignes[0] || {}) };
  return (r.c === 'modifie a.js échec' && r.h === "Message de l'humain" && r.k === 'Compaction' && !SECRETS.some((s) => tout.includes(s))
    && noms.includes('echec') && !r.cle.includes('texteErreur') && !r.cle.includes('entree')) || r;
});
sonde('X7', () => {
  let appele = false; const piege = { schema: 'vibeflow/cockpit-transcript@3' };
  Object.defineProperty(piege, 'fil', { get() { appele = true; throw new Error('lu'); } });
  const a = F.lireFil(piege), b = F.lireFil(brut(undefined, { erreur: 'illisible' }));
  const c = F.lireFil(brut([], { tronque: true }));
  const e = F.lireFil(brut([msgL(T, 'm'), outL(T + 1, {}), { t: iso(T + 2), genre: 'compaction' }, { t: iso(T + 3), genre: 'humain', texte: 'h' }, { t: iso(T + 4), genre: 'zzz' }]));
  const i = F.lireFil(brut(undefined, { erreur: 'inconnu' })), v = F.lireFil(brut([]));
  const d = mkDoc(); const li = F.ligneDom(outL(T, { cible: 'src/a.js (worktree wt-b)' }), d, {});
  const code = trouver(li, (n) => n.tag === 'code');
  const r = { a, appele, b, c: c.tronque, coupe: F.COUPE, e: [e.lignes.length, e.ecartes], i, v: [v.ok, v.lignes.length], code: code.map(texteDe), a_: LOG.tags.includes('a') };
  return (a.ok === false && a.raison === 'schema' && !appele && b.ok === false && b.raison === 'erreur' && c.ok === true && c.tronque === true
    && F.COUPE === "Plus ancien que la fenêtre lue. Seuls les 50 derniers messages et les 200 derniers appels d'outil sont affichés."
    && e.lignes.length === 2 && e.ecartes === 3 && i.ok === false && i.raison === 'inconnu' && v.ok === true && v.lignes.length === 0
    && code.length === 1 && texteDe(code[0]) === 'src/a.js (worktree wt-b)' && !r.a_) || r;
});
sonde('X8', () => {
  const d = mkDoc();
  const li = F.ligneDom({ t: iso(T), genre: 'outil', outil: '</code><b>', verbe: '', cible: '<script>x</script>' }, d, {});
  const code = trouver(li, (n) => n.tag === 'code');
  return (!LOG.tags.includes('script') && !LOG.tags.includes('b') && LOG.html === 0 && code.length === 1 && texteDe(code[0]) === '<script>x</script>'
    && texteDe(li).includes('</code><b>')) || { tags: LOG.tags, code: code.map(texteDe), t: texteDe(li) };
});
// X9 : le rendu s'exécute DANS le contexte avec un délai dur (un retour arrière catastrophique rendrait la sonde rouge par le délai)
const rendre = (msg) => {
  ctx.__m = msg; ctx.__d = mkDoc(); reset(); const t0 = performance.now();
  vm.runInContext('__r = window.__vfFicheMd.markdown(__m, __d)', ctx, { timeout: 6000 });
  return { ms: performance.now() - t0, texte: texteDe(ctx.__r) };
};
const meilleur = (msg) => Math.min(...[1, 2, 3].map(() => rendre(msg).ms));
sonde('X9', () => {
  const dense = '*_[`'.repeat(12500);                            // 50 000 caractères d'emphase et de crochets non fermés
  const msgs = [dense, '[a'.repeat(25000), '*'.repeat(28) + 'y', '['.repeat(20000) + '*'.repeat(20000) + '_'.repeat(10000), '** a *'.repeat(8000)];
  const lents = msgs.map((m) => [m.length, Math.round(meilleur(m))]).filter(([, ms]) => ms >= 300);
  const lin = ['*_[`', '[a', '** a *', '`[*'].map((p) => { const t1 = meilleur(p.repeat(10000)), t2 = meilleur(p.repeat(20000)); return [p, Math.round(t1), Math.round(t2), t2 <= 4 * t1 + 60]; });
  const gros = rendre('mot '.repeat(50000)); const mand = ctx.window.__vfFicheMd.mandatDom('mot '.repeat(50000), mkDoc());
  const plafonne = gros.texte.includes('(tronqué)') && gros.texte.length <= 100020 && texteDe(mand).includes('(tronqué)') && texteDe(mand).length <= 100020;
  return (lents.length === 0 && lin.every((x) => x[3]) && plafonne) || { lents, lin, plafonne, len: gros.texte.length };
});
// X12 : corpus hostile (adresses nues, schémas, chevrons, format d'attribut) : jeu fermé de balises, aucun attribut, classes d'une liste fixe, rien dérivé du texte
const BALISES = ['p', 'ul', 'ol', 'li', 'code', 'pre', 'em', 'strong', 'span'];
const CLASSES = ['vf-fiche-code', 'vf-fiche-bloc', 'vf-fiche-tronque', 'vf-fiche-mandat', 'vf-fiche-ligne', 'vf-fiche-message', 'vf-fiche-humain',
  'vf-fiche-compaction', 'vf-fiche-outil', 'vf-fiche-heure', 'vf-fiche-glyphe', 'vf-fiche-texte', 'vf-fiche-cible', 'vf-fiche-echec'];
const CORPUS = ['http://evil.example/x et https://a.b/c?d=<script>', 'javascript:alert(1)', 'data:text/html;base64,PHNjcmlwdD4=', 'mailto:a@b.c',
  '<https://auto.lien/x>', 'x" onmouseover="alert(1)" style="color:red', "' onfocus='x' href='y", '`style="x"` **onclick=1** *a" b* _src=x_',
  '[a](data:text/html,x) ![i](http://x/y.png)', '- http://l\n1. mailto:z', '```\nhttp://e onclick=1\n```'];
sonde('X12', () => {
  const d = mkDoc();
  for (const m of CORPUS) {
    Md.markdown(m, d); Md.mandatDom(m, d);
    F.ligneDom(msgL(T, m), d, {}); F.ligneDom(outL(T, { verbe: m, cible: m }), d, {});
  }
  const classes = LOG.classes.flatMap((c) => c.split(/\s+/).filter(Boolean));
  const r = { tags: [...new Set(LOG.tags.filter((x) => !BALISES.includes(x)))], attrs: LOG.attrs.slice(0, 3), props: LOG.props.slice(0, 3),
    classes: [...new Set(classes.filter((c) => !CLASSES.includes(c)))], on: LOG.on.length, html: LOG.html };
  return (!r.tags.length && !LOG.attrs.length && !LOG.props.length && !r.classes.length && !r.on && !r.html && LOG.tags.length > 0) || r;
});
// X13 : un genre hors {message, humain, compaction, outil} ne donne ni classe dérivée ni contenu
sonde('X13', () => {
  const d = mkDoc(); const g = 'zz onclick=1" <b>';
  const li = F.ligneDom({ t: iso(T), genre: g, texte: 'PIEGE-74', verbe: 'PIEGE-74', cible: 'PIEGE-74' }, d, { glyphe: () => null });
  const clas = String(li.className);
  return (!clas.includes('zz') && !clas.includes('onclick') && !LOG.classes.join(' ').includes('zz') && li.children.length === 0 && texteDe(li) === '') || { clas, n: li.children.length };
});
// X14 : lien à parenthèse non fermée (aucun « ) » plus loin) : rendu terminé sous délai dur, texte intact (la garde `dernier[')'] >= fermante + 2` évite la boucle infinie ; les deux derniers cas portent une `)` AVANT le lien, qu'une garde affaiblie en `>= 0` laisserait passer)
sonde('X14', () => {
  const cas = ['[a](b', 'voir [doc](https://x.y sans fermer', 'a [b](c [d](e', '[x]( et ](y', '(a) [b](c', 'f(x) puis [y](z'];
  const r = cas.map((m) => {
    try { ctx.__m = m; ctx.__d = mkDoc(); reset(); vm.runInContext('__r = window.__vfFicheMd.markdown(__m, __d)', ctx, { timeout: 1500 }); return texteDe(ctx.__r) === m; }
    catch (e) { return 'délai : ' + m; }
  });
  return r.every((x) => x === true) || r;
});
// X10 : fusionnerEvenements
{
  const fil = [msgL(T, 'a'), outL(T + 10000), msgL(T + 20000, 'b')];
  const F10 = (ev, o) => F.fusionnerEvenements(fil, ev, { tronque: false, etatSource: 'lue', ...o });
  const gen = (r) => r.map((l) => l.genre).join(',');
  const X = {};
  const essai = (k, fn) => { try { reset(); X[k] = fn(); } catch (e) { X[k] = 'lance : ' + e.message; } };
  essai('a', () => F10([[T + 5000, 'erreur'], [T + 6000, 'rapport'], [T + 7000, 'dispatch']]).length === 3 || 'ajout');
  essai('b', () => {
    const r = F10([[NaN, 'humain'], [Infinity, 'humain'], ['x', 'humain'], [T + 1000], [T + 1000, 'humain'], null, {}, 'abc', 7, [T + 2000, 7]]);
    const z = [null, {}, 'abc', 7, undefined].map((e) => F10(e).length);
    return (r.length === 4 && z.every((n) => n === 3)) || { r: gen(r), z };
  });
  essai('c', () => { const r = F10([[T - 1000, 'humain'], [T + 1000, 'compaction']]); return (r.length === 4 && gen(r) === 'message,compaction,outil,message') || gen(r); });
  essai('d', () => {
    const ev = [[T + 1000, 'humain']];
    return (F10(ev, { etatSource: 'en-construction' }).length === 3 && F10(ev).length === 4) || [F10(ev, { etatSource: 'en-construction' }).length, F10(ev).length];
  });
  essai('e', () => {
    const ev = Array.from({ length: 300 }, (_, i) => [T + 1000 + i * 10, 'humain']);
    const h = F10(ev).filter((l) => l.genre === 'humain').map((l) => Date.parse(l.t));
    return (h.length === 200 && Math.min(...h) === T + 2000 && Math.max(...h) === T + 3990) || [h.length, Math.min(...h) - T, Math.max(...h) - T];
  });
  essai('f', () => {
    const r = F10([[T + 10000, 'humain'], [T + 500, 'compaction']]); const ts = r.map((l) => Date.parse(l.t));
    const triee = ts.every((x, i) => i === 0 || x >= ts[i - 1]); const g = gen(r);
    return (triee && g === 'message,compaction,outil,humain,message') || g;
  });
  essai('g', () => {
    const f1 = Object.freeze(fil.map((l) => Object.freeze({ ...l }))); const ev = Object.freeze([Object.freeze([T + 1000, 'humain'])]);
    const avant = JSON.stringify([f1, ev]); F.fusionnerEvenements(f1, ev, { tronque: false, etatSource: 'lue' });
    return JSON.stringify([f1, ev]) === avant || 'modifie';
  });
  essai('h', () => {
    const ev = [[T + 1000, 'humain']];
    const r1 = F.fusionnerEvenements([], ev, { tronque: false, etatSource: 'lue' }), r2 = F.fusionnerEvenements([{ t: 'pas une date', genre: 'message', texte: 'x' }], ev, { tronque: false, etatSource: 'lue' });
    return (r1.length === 0 && r2.length === 1) || [r1.length, r2.length];
  });
  for (const k of Object.keys(X)) ligne('X10' + k, X[k]);
  ligne('X10', Object.values(X).every((v) => v === true) || X);
}
console.log(out.join('\n'));
JS

# --- applique une mutation à une copie (échoue si l'ancre est absente : un mutant sans effet ne prouverait rien) ---
cat > "$AUX/fiche-mute.mjs" <<'JS'
// fiche-mute.mjs <fichier> <ancre> <remplacement> : remplace UNE occurrence exacte de l'ancre ; code 1 si l'ancre est absente ou multiple.
import fs from 'node:fs';
const [, , f, de, vers] = process.argv;
const s = fs.readFileSync(f, 'utf8');
if (s.split(de).length !== 2) { console.error('ancre absente ou multiple : ' + de); process.exit(1); }
fs.writeFileSync(f, s.replace(de, () => vers));
JS

res() { grep -E "^$2 " "$1" | head -1 | awk '{print $2}'; }
ligne_de() { grep -E "^$2 " "$1" | head -1; }

# --- X0 : contrôle positif, dossier sans modules ---
mkdir -p "$WORK/vide"
node "$AUX/fiche-run.mjs" "$WORK/vide" > "$WORK/x0.out" 2>&1
tous_ko=oui; for k in X1 X2 X3 X4 X5 X6 X7 X8 X9 X10; do [ "$(res "$WORK/x0.out" $k)" = "ko" ] || tous_ko=non; done
assert_eq "X0 — dossier sans modules : « absent » et chaque sonde X1 à X10 échoue (les sondes savent rougir)" "$(res "$WORK/x0.out" absent)|$tous_ko" "1|oui"

# --- X1 à X10 sur les modules de la suite ---
node "$AUX/fiche-run.mjs" "$UI" > "$WORK/reel.out" 2>&1
sonde_ok() { assert_eq "$1" "$(res "$WORK/reel.out" "$2")" "ok"; [ "$(res "$WORK/reel.out" "$2")" = "ok" ] || echo "     $(ligne_de "$WORK/reel.out" "$2" | cut -c1-600)"; }
sonde_ok "X1 — un message de balisage hostile (img, onerror) n'ouvre aucune balise ni attribut on*, le texte exact est un nœud texte" X1
sonde_ok "X2 — un lien (dont javascript:) s'écrit « libellé (adresse) » en texte, jamais en balise a" X2
sonde_ok "X3 — aucun accès à innerHTML, outerHTML, insertAdjacentHTML ni document.write sur l'ensemble des rendus (apparié à des balises créées)" X3
sonde_ok "X4 — sous-ensemble fermé : p, ul, ol, li, code, pre, em, strong et rien d'autre ; titre, tableau et citation écrits tels quels" X4
sonde_ok "X5 — filtres cumulables (union), compaction visible sans filtre seulement, compteur exact" X5
sonde_ok "X6 — liste blanche : ni texte d'erreur ni entrée d'outil rendus ; lignes humain et compaction sans texte" X6
sonde_ok "X7 — lireFil : schéma d'abord, erreur et inconnu distincts d'un fil vide, genres de la route écartés et comptés, cible en code" X7
sonde_ok "X8 — cible et nom d'outil hostiles rendus en texte, la cible dans un code" X8
sonde_ok "X9 — tokenizer linéaire (N / 2N), moins de 300 ms sur emphase pathologique, plafond de 100 000 caractères avec mention" X9
sonde_ok "X12 — corpus hostile (adresses nues, javascript:, data:, mailto:, chevrons, format d'attribut) : balises du jeu fermé, aucun attribut, classes d'une liste fixe" X12
sonde_ok "X13 — un genre hors du jeu fermé ne produit ni classe dérivée ni contenu (liste blanche au rendu)" X13
sonde_ok "X14 — lien à parenthèse non fermée : rendu terminé sous délai dur, texte intact (pas de boucle infinie)" X14
sonde_ok "X10 — fusionnerEvenements : genres, valeurs non finies, borne, en-construction, plafond de 200, tri, pureté, fil sans date" X10
for k in a b c d e f g h; do sonde_ok "X10$k — sous-cas $k de la fusion des événements" "X10$k"; done

# --- X11 : mutants (V-07), chacun prouvé par sa ligne MUTANT-ROUGE ---
MD=74-vf-fiche-md.js; TX=74-vf-fiche-texte.js
mutant() { # <suffixe> <nom> <sonde-affichée> <clé-de-sonde> <fichier> <ancre> <remplacement>
  local sfx="$1" nom="$2" aff="$3" cle="$4" fic="$5" de="$6" vers="$7" d="$WORK/mut-$2" r
  mkdir -p "$d"
  if [ -f "$UI/$MD" ] && [ -f "$UI/$TX" ]; then
    cp "$UI/$MD" "$UI/$TX" "$d/"
    if node "$AUX/fiche-mute.mjs" "$d/$fic" "$de" "$vers" 2> "$d/mute.err"; then
      node "$AUX/fiche-run.mjs" "$d" > "$d/run.out" 2>&1; r="$(res "$d/run.out" "$cle")"
    else r="non-applicable"; fi
  else r="absent"; fi
  if [ "$r" = "ko" ]; then echo "MUTANT-ROUGE $nom $aff"; assert_eq "X11$sfx — le mutant de la sonde $aff est détecté" "rouge" "rouge"
  else echo "MUTANT-VERT $nom $aff"; assert_eq "X11$sfx — le mutant de la sonde $aff est détecté" "$r" "ko"; fi
}
mutant a M-INNERHTML X3 X3 "$MD" 'code.textContent = corps;' 'code.innerHTML = corps;'
mutant b M-LIEN X2 X2 "$MD" "tampon += libelle + ' (' + adresse + ')';" "vider(); const lien = doc.createElement('a'); lien.setAttribute('href', adresse); lien.textContent = libelle; parent.appendChild(lien);"
mutant c M-RENDU-TOUT X6 X6 "$TX" "const verbe = ligne.verbe || ligne.outil || '';" "const verbe = Object.keys(ligne).filter((k) => typeof ligne[k] === 'string' && k !== 't' && k !== 'genre' && k !== 'cible').map((k) => ligne[k]).join(' ');"
mutant d M-FILTRE-ET X5 X5 "$TX" 'actifs.some(' 'actifs.every('
mutant e M-BACKTRACK X9 X9 "$MD" 'const n = texte.length;' 'const n = texte.length; if (/(\*+)+x/.test(texte)) return;'
mutant f M-FUSION-SANS-BORNE X10 X10c "$TX" 'if (ms < borne) continue;' ''
mutant g M-FUSION-EN-CONSTRUCTION X10 X10d "$TX" "etatSource === 'en-construction'" "etatSource === '__jamais__'"
mutant h M-INCONNU-VIDE X7 X7 "$TX" "return { ok: false, raison: 'inconnu' };" "return { ok: true, mandat: null, lignes: [], tronque: false, ecartes: 0 };"
mutant i M-PLAFOND X9 X9 "$MD" 'const tronque = t.length > PLAFOND;' 'const tronque = false;'
mutant j M-AUTOLIEN X12 X12 "$MD" 'tampon += c;' "if (texte.startsWith('http', i)) { let j = i; while (j < n && !blanc(texte[j])) j++; vider(); const a = doc.createElement('a'); a.setAttribute('href', texte.slice(i, j)); a.textContent = texte.slice(i, j); parent.appendChild(a); i = j; continue; } tampon += c;"
mutant k M-STYLE X12 X12 "$MD" 'e.textContent = contenu;' "e.textContent = contenu; e.setAttribute('style', contenu);"
mutant l M-GENRE-CLASSE X13 X13 "$TX" 'if (!GENRES.includes(ligne && ligne.genre)) return li;' ''
mutant m M-LIEN-OUVERT X14 X14 "$MD" " && dernier[')'] >= fermante + 2" ''
mutant n M-LIEN-FAIBLE X14 X14 "$MD" " && dernier[')'] >= fermante + 2" " && dernier[')'] >= 0"

vf_hyg_assert

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
