// sonde.mjs — fait tourner le moteur de santé (lib/health.mjs) et le panneau (ui/20-health.js) sur des cas fabriqués, imprime « clé=valeur ».
// Usage : node sonde.mjs <dossier cockpit-moteur> — la suite le lance sur l'arbre courant, et sur une base (git archive) pour le témoin rouge.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import vm from 'node:vm';
import { pathToFileURL } from 'node:url';

const moteur = path.resolve(process.argv[2]);
const { findIssues, buildHealth } = await import(pathToFileURL(path.join(moteur, 'scripts/lib/health.mjs')).href);
const out = (k, v) => console.log(`${k}=${typeof v === 'string' ? v.replace(/\n/g, ' ') : JSON.stringify(v)}`);

// ---------- moteur : un dépôt fabriqué, l'analyse fichier par fichier puis buildHealth ----------
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'sante-'));
process.on('exit', () => fs.rmSync(root, { recursive: true, force: true }));
const lignes = (n) => Array.from({ length: n }, (_, i) => `export const v${i} = ${i};`).join('\n') + '\n';
const AWS = 'AKIA' + 'QWERTY7890ZXCVBN'; // 20 caractères, format réel, entropie suffisante : aucune clé réelle
function depot(fichiers) {
  const defs = fichiers.map(({ p, src, lang = 'javascript' }) => {
    fs.mkdirSync(path.dirname(path.join(root, p)), { recursive: true });
    fs.writeFileSync(path.join(root, p), src);
    return { p, src, lang, loc: src.split('\n').length };
  });
  const scan = { files: defs.map((d) => ({ path: d.p, category: 'code', lang: d.lang, issues: findIssues(d.src, { path: d.p, category: 'code', lang: d.lang }) })) };
  const graph = { nodes: [{ id: 'n:app', kind: 'module', label: 'App', parent: null }], files: defs.map((d) => ({ p: d.p, n: 'n:app', l: d.lang, loc: d.loc, name: d.p })), links: [], routes: [], flows: [], project: {}, meta: {} };
  return buildHealth({ graph, scan, arch: {}, root });
}
const par = (h, kind) => h.issues.filter((i) => i.kind === kind);

// G-081 : une clé au format réel dans un fichier de test
const t = depot([{ p: 'tests/aws.test.js', src: `const k = "${AWS}";\n` }]);
const sec = par(t, 'secret')[0];
out('g081.present', !!sec);
out('g081.severite', sec ? sec.severity : 'absent');
out('g081.titre', sec ? sec.title : '');
out('g081.detail_factice', !!sec && /probably fake/.test(sec.detail));
out('g081.detail_alarmiste', !!sec && /get into/.test(sec.detail));
// témoin : la même clé dans le code de l'application reste grave et alarmiste
const r = depot([{ p: 'src/aws.js', src: `const k = "${AWS}";\n` }]);
const sr = par(r, 'secret')[0];
out('g081.reel.severite', sr ? sr.severity : 'absent');
out('g081.reel.alarmiste', !!sr && /get into/.test(sr.detail));
out('g081.reel.factice', !!sr && /probably fake/.test(sr.detail));

// G-082 : fichiers tiers exclus des conseils « très gros » et « inutilisé »
const g = depot([
  { p: 'vendor/lib/huge.js', src: lignes(2500) }, { p: 'public/app.bundled.js', src: lignes(1500) }, { p: 'dist/app.min.js', src: lignes(1500) },
  { p: 'src/big.js', src: lignes(1200) }, { p: 'vendor/lib/orphan.js', src: lignes(5) }, { p: 'public/orphan.bundled.js', src: lignes(5) }, { p: 'src/orphan.js', src: lignes(5) },
]);
const gros = par(g, 'large-file').flatMap((i) => i.locations.map((l) => l.file));
const inutiles = par(g, 'unused-file').flatMap((i) => i.locations.map((l) => l.file));
out('g082.gros', gros.sort());
out('g082.inutilises', inutiles.sort());

// G-083 : les services réellement utilisés
const svc = (f) => depot(f).services;
out('g083.aucun', svc([{ p: 'src/a.js', src: 'export const a = 1;\n' }]));
out('g083.supabase', svc([{ p: 'src/a.js', src: "import { createClient } from '@supabase/supabase-js';\n" }]));
out('g083.firebase', svc([{ p: 'src/a.js', src: "import { getAuth } from 'firebase/auth';\n" }]));
out('g083.stripe', svc([{ p: 'src/a.js', src: "import Stripe from 'stripe';\n" }]));
out('g083.trois', svc([{ p: 'src/a.js', src: "import { createClient } from '@supabase/supabase-js';\nimport { getAuth } from 'firebase/auth';\nimport Stripe from 'stripe';\n" }]));

// ---------- panneau : 20-health.js dans un contexte minimal, sans navigateur ----------
function panneau({ issues, services, vfTab, plan = false }) {
  const sections = {}, boutons = [], panneaux = [];
  const el = () => ({ children: [], textContent: '', style: { setProperty() {} }, classList: { add() {} }, appendChild(c) { this.children.push(c); }, setAttribute() {}, querySelector: () => null, querySelectorAll: () => [] });
  const SC = {
    exported: false, graph: { meta: { blueprint: plan, vfTab }, health: { issues, ...(services ? { services } : {}) } }, h: (x) => String(x).replace(/&/g, '&amp;').replace(/</g, '&lt;'),
    agent: { name: 'Claude', app: 'Claude Code' }, icons: {}, technical: () => false, plural: (n, w) => `${n} ${w}${n === 1 ? '' : 's'}`,
    state: { selected: null, container: null }, iconI: () => '', icon: () => '', exists: () => false, on() {}, closePanel() {}, canChange: () => false,
    addHeaderButton: (o) => { const b = Object.assign(el(), o); boutons.push(b); return b; }, addPanelSection: (n, f) => { sections[n] = f; }, showPanel: (html) => panneaux.push(html),
  };
  // 79-10 : le traducteur du moteur, sous forme neutre (la clé remplie, comme sous ?lang=en) : l'extension le lit au chargement
  const tf = (k, ...v) => k.replace(/@[\w-]+$/, '').split('{}').reduce((x, q, i) => (i ? x + String(v[i - 1] ?? '') + q : x + q), '');
  Object.assign(tf, { pl: (n, w) => `${n} ${w}${n === 1 ? '' : 's'}`, mot: (n, k) => k, k: (x) => x, type: () => null, constat: (x) => x });
  const ctx = { window: { Floorplan: SC, __vfFrT: tf }, document: { createElement: el, head: { appendChild() {} } }, JSON };
  vm.runInNewContext(fs.readFileSync(path.join(moteur, 'assets/ui/20-health.js'), 'utf8'), ctx);
  boutons[0].onClick();
  return { liste: panneaux[0] || '', apercu: sections.overview ? sections.overview().html : '', bouton: boutons[0] };
}
const texte = (html) => html.replace(/<[^>]+>/g, '|').replace(/\|+/g, '|');
const mk = (severity, i) => ({ id: `i${i}`, kind: 'x', severity, title: `t${i}`, detail: `d${i}`, items: [], fix: 'f' });
const cinq = [mk('high', 1), mk('high', 2), mk('high', 3), mk('medium', 4), mk('low', 5)]; // légende : 3 importants, 1 à corriger, 1 mineur
const P = panneau({ issues: cinq, services: [] });
out('g079.titre', /<h2 class="pt">([^<]*)<\/h2>/.exec(P.liste)?.[1] || '');
out('g079.legende', [...P.liste.matchAll(/(\d+) (important|worth fixing|minor)</g)].map((m) => `${m[1]} ${m[2]}`).join(', '));
out('g079.titre_bouton', P.bouton.title);
out('g079.pastille', P.bouton.children[0] ? P.bouton.children[0].textContent : 'absente');
const seul = panneau({ issues: [mk('high', 1)], services: [] });
out('g079.titre_un', /<h2 class="pt">([^<]*)<\/h2>/.exec(seul.liste)?.[1] || '');
const bas = panneau({ issues: [mk('low', 1), mk('low', 2)], services: [] });
out('g079.titre_mineurs', /<h2 class="pt">([^<]*)<\/h2>/.exec(bas.liste)?.[1] || '');

// G-083 côté panneau
const intro = (services) => texte(panneau({ issues: cinq, services }).liste);
out('g083.ui.phrase_vide', /Checks specific/.test(intro([])) || /Checks specific/.test(intro(undefined)));
out('g083.ui.sans', /Supabase|Firebase|Stripe/.test(intro([])));
out('g083.ui.sans_champ', /Supabase|Firebase|Stripe/.test(intro(undefined)));
out('g083.ui.avec_supabase', /Supabase/.test(intro(['Supabase'])) && !/Firebase|Stripe/.test(intro(['Supabase'])));
out('g083.ui.trois', ['Supabase', 'Firebase', 'Stripe'].every((n) => intro(['Supabase', 'Firebase', 'Stripe']).includes(n)));

// G-084 : l'intitulé du bloc de l'onglet Projet
const bloc = (vfTab) => /<h3>([^<]*)<\/h3>/.exec(panneau({ issues: [], services: [], vfTab }).apercu)?.[1] || '';
out('g084.projet', bloc('project'));
out('g084.code', bloc(undefined));
