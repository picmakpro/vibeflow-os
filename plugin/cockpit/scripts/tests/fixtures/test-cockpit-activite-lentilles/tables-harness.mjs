// tables-harness.mjs — les fonctions PURES de ui/75-vf-activite-tables.js, lues en `vm` (ni DOM, ni réseau). Usage : node tables-harness.mjs <fichier du module>
// Rend des lignes `clé=valeur` (une observation par ligne) lues par test-cockpit-activite-lentilles.sh. Phase 75, plan 75-08 (tâches 1, 2 et 3).
import fs from 'node:fs'; import vm from 'node:vm';
const src = fs.readFileSync(process.argv[2], 'utf8');
const ctx = { window: {}, console }; vm.createContext(ctx); vm.runInContext(src, ctx, { filename: 'tables.js' });
const T = ctx.window.VF_ACTIVITE_TABLES, NB = ' ';
const out = []; const obs = (k, v) => out.push(`${k}=${typeof v === 'string' ? v : JSON.stringify(v)}`);
if (!T) { obs('absent', 'true'); console.log(out.join('\n')); process.exit(0); }

// un lab de 6 fichiers : un nœud n:x au-dessus de d:a (a, b, c, prévu) et d:b (doc, suite)
const FICH = { 'src/a.js': { l: 'js' }, 'src/b.js': { l: 'js' }, 'src/c.js': { l: 'js' }, 'src/neuf.js': { l: 'js', st: 'prevu' }, 'docs/n.md': { l: 'docs' },
  'scripts/tests/test-x.sh': { l: 'shell' }, 'scripts/check-x.sh': { l: 'shell' }, 'src/fixtures/f.js': { l: 'js' } };
const CHAIN = (p) => ['f:' + p, 'n:x', 'root'];
const vue = (o = {}) => ({ fichier: (p) => FICH[p] || null, existe: (id) => id.startsWith('f:') && !!FICH[id.slice(2)], visible: (id) => (o.visibles || ['f:src/a.js', 'f:src/b.js', 'f:src/c.js']).includes(id),
  ancetres: (id) => CHAIN(id.slice(2)).filter((a) => a !== id && a !== 'root'), selection: o.sel || null, filtre: o.filtre || null });
const git = (extra = {}) => ({ etat: 'ok', fenetre: { jours: 90, commits: 9, plafond: 5000, plafondAtteint: false, partiel: false },
  chauds: [['src/a.js', 41, 1203, 12, 3], ['src/b.js', 5, 300, 20, 2], ['src/c.js', 1, 10, 30, 1], ['docs/n.md', 9, 99, 40, 3], ['scripts/tests/test-x.sh', 3, 30, 50, 2], ['src/fixtures/f.js', 2, 4, 60, 1],
    ['src/neuf.js', 1, 1, 70, 1]], couplage: [['src/a.js', 'src/b.js', 12, 78], ['src/a.js', 'src/c.js', 6, 55], ['src/b.js', 'src/c.js', 5, 33]], paliers: 3, tronque: false, ...extra });
const base = (o = {}) => ({ schema: 'vibeflow/cockpit-activite@1', etat: 'ok', calcul: 'pret', git: git(), branches: { etat: 'ok', tetes: 1, plafond: 12, plafondAtteint: false },
  gardes: { etat: 'ok', gardes: [['src/a.js', 0, 0], ['src/b.js', 3, 0], ['src/c.js', 1, 0], ['scripts/check-x.sh', 0, 1], ['docs/n.md', 0, 0], ['src/neuf.js', 0, 0]], estGarde: ['scripts/check-x.sh'], prevusIgnores: 2, tronque: false },
  empreinte: { etat: 'ok', incomplet: false, limite: ['ecritures-par-commande-non-vues'], marques: [['src/a.js', 'en-cours', ['vf-coder · nœud 75-08']], ['src/b.js', 'modifie', ['vf-coder · nœud 75-08', 'vf-reviewer · non rattaché', 'vf-auditer · non rattaché']],
    ['src/c.js', 'lu', ['vf-coder · nœud 80-01']]], horsCarte: 3, horsLab: 2, coupees: 0, rejetes: 0, ignorees: 0 },
  collisions: [['src/a.js', 'agents', ['vf-coder · phase-75', 'vf-coder · phase-76'], null], ['src/a.js', 'branches', ['feat/a', 'feat/b'], null], ['src/b.js', 'arbres', ['phase-75', 'phase-76'], null],
    ['src/c.js', 'plans', ['75-02', '75-04'], 3], ['src/neuf.js', 'plans', ['75-02', '75-04'], null]],
  radar: { incomplet: false, raisons: [], total: 5, tronque: false, limites: [] }, ...o });
const rows = (id, d, v = vue(), conn = 'ouvert') => T.table(id, d, v, conn);
const M = (o = {}) => T.modele({ d: base(), conn: 'ouvert', lentille: 'aucune', filtre: null, vue: vue(), ...o });

// ---- tâche 1 : la table de Points chauds, de la route aux rangées ----
obs('L2.chauds', rows('chauds', base()));
obs('L2.sans-marque', rows('chauds', base()).map((r) => r[0]).filter((i) => /neuf|docs|test-x|fixtures/.test(i)));
obs('L2.singulier', rows('chauds', base()).find((r) => r[0] === 'f:src/c.js').slice(3));
obs('L2.git-absent', [T.etat('chauds', base({ git: { etat: 'absent' } }), 'ouvert'), M({ d: base({ git: { etat: 'absent' } }), lentille: 'chauds' }).lentille, rows('chauds', base({ git: { etat: 'absent' } }))]);
obs('L2.fenetre-vide', [rows('chauds', base({ git: { etat: 'vide', fenetre: { jours: 90 }, chauds: [], couplage: [] } })).length, M({ d: base({ git: { etat: 'vide', fenetre: { jours: 90 }, chauds: [], couplage: [] } }), lentille: 'chauds' }).legende.map((x) => x.t)]);
obs('L1.pastille', [M().pastille, M().bouton.aria, M({ lentille: 'chauds' }).bouton.libelle, M({ conn: 'perdu' }).pastille]);
// ---- tâche 2 : couplage, gardes, empreinte, états, annonces, phrases ----
obs('L8.couplage', rows('couplage', base(), vue({ sel: 'f:src/a.js' })));
obs('L8.hors-vue', rows('couplage', base(), vue({ sel: 'f:src/a.js', visibles: ['f:src/a.js', 'f:src/c.js'] })).map((r) => r[0]));
obs('L8.noeud-et-vide', [rows('couplage', base(), vue({ sel: 'n:x' })).length, rows('couplage', base(), vue()).length, rows('couplage', base({ git: git({ couplage: [] }) }), vue({ sel: 'f:src/a.js' }))[0].slice(3, 4)]);
obs('L8.legende', ['aucune', 'n:x', 'f:src/a.js'].map((s) => M({ lentille: 'couplage', vue: vue({ sel: s === 'aucune' ? null : s }) }).legende.map((x) => (x.g || '-') + ':' + x.t)));
obs('L9.gardes', rows('gardes', base()));
obs('L9.etats', [T.etat('gardes', base({ gardes: { etat: 'non-lues', gardes: [], estGarde: [] } }), 'ouvert'), M({ d: base({ gardes: { etat: 'non-lues', gardes: [], estGarde: [] } }) }).lignes.find((l) => l.id === 'gardes').sous]);
obs('L10.empreinte', rows('empreinte', base()));
obs('L10.filtre', [M({ lentille: 'empreinte' }).agents, rows('empreinte', base(), vue({ filtre: '80-01' })).map((r) => r[0])]);
obs('L10.sans-rattachement', M({ d: base({ empreinte: { ...base().empreinte, marques: [['src/a.js', 'en-cours', ['vf-coder · non rattaché']]] } }), lentille: 'empreinte' }).agents);
obs('L10.legende', M({ lentille: 'empreinte' }).limites);
obs('L10.legende-zero', M({ d: base({ empreinte: { ...base().empreinte, horsCarte: 0, horsLab: 0 } }), lentille: 'empreinte' }).limites);
obs('L10.relecture', ['empreinte'].map(() => { const m = M({ d: base({ empreinte: { ...base().empreinte, etat: 'en-construction', incomplet: true } }), lentille: 'empreinte' }); return [m.legende[0].t, m.lignes.find((l) => l.id === 'empreinte').sous, m.rows.length > 0]; })[0]);
obs('L10.perdue', ['empreinte', 'chauds'].map((id) => { const m = M({ conn: 'perdu', lentille: id }); return [m.legende.map((x) => x.t), m.rows.length, m.radar.texte, m.indispo]; }));
obs('L10c.hors-lab', [T.F.horsLab(1), T.F.horsLab(2), T.F.piedLong(2), T.F.piedLong(0), T.F.infoCourte(2)]);
obs('L6.indispo', ['chauds', 'gardes', 'empreinte'].map((id) => { const d = id === 'chauds' ? base({ git: { etat: 'indisponible' } }) : id === 'gardes' ? base({ gardes: { etat: 'indisponible', gardes: [], estGarde: [] } }) : base({ empreinte: { ...base().empreinte, etat: 'indisponible' } });
  const m = M({ d, lentille: id }); const l = m.lignes.find((x) => x.id === id); return [l.etat, l.sous, l.description, m.indispo, m.rows.length, m.legende.map((x) => x.t), m.annonce]; }));
obs('L6.lecture', [M({ d: null }).lignes.map((l) => l.etat + ':' + l.sous).join('|'), M({ d: base({ git: { etat: 'en-lecture' } }) }).lignes.find((l) => l.id === 'chauds').sous]);
obs('L6.radar', [{ r: base({ calcul: 'en-cours', collisions: [], radar: { incomplet: true, raisons: ['en-construction'] } }) }, { r: base({ collisions: [], radar: { incomplet: true, raisons: ['branches-indisponible'] } }) },
  { r: base({ collisions: [], radar: { incomplet: true, raisons: ['tronque'] } }) }, { r: base({ collisions: [], radar: { incomplet: true, raisons: ['cibles-coupees'] } }) }, { r: base({ collisions: [], calcul: 'en-cours' }) },
  { r: base({ collisions: [] }) }, { r: base() }].map(({ r }) => M({ d: r }).radar.ligne));
obs('L6.radar-perdu', [M({ conn: 'perdu' }).radar.ligne, M({ conn: 'perdu', d: base({ collisions: [] }) }).radar.texte, M({ d: null }).radar.ligne]);
obs('L6.perdue-garde-les-marques', ['chauds', 'gardes'].map((id) => { const m = M({ conn: 'perdu', lentille: id }); return [m.rows.length > 0, m.legende.at(-1).t]; }));
obs('L6.git-absent-menu', M({ d: base({ git: { etat: 'absent' } }) }).lignes.map((l) => l.id));
obs('L6.legende-chauds', [M({ lentille: 'chauds', d: base({ git: git({ fenetre: { jours: 90, plafond: 5000, plafondAtteint: true, partiel: true } }) }) }).legende.map((x) => x.t)]);
obs('L6.legende-gardes', M({ lentille: 'gardes' }).legende.map((x) => (x.g || '-') + ':' + x.t));
obs('L11.annonces', [M({ lentille: 'chauds' }).annonce, M({ lentille: 'gardes' }).annonce, M({ lentille: 'empreinte' }).annonce, M({ lentille: 'couplage' }).annonce, M({ lentille: 'aucune' }).annonce,
  M({ lentille: 'chauds', d: base({ git: { etat: 'indisponible' } }) }).annonce, T.F.annonceCouplage(5), T.F.annonceRadar(3), T.F.annonceRadar(1)]);
obs('L11.singulier', [T.F.annonce('Points chauds', 1, 'chauds'), T.F.annonce('Empreinte', 1, 'empreinte')]);
// ---- tâche 3 : collisions ----
obs('L13.collisions', rows('collisions', base(), vue()) && T.tableCollisions(base(), vue()));
obs('L13.trois-agents', T.SOURCE_MOT.agents(3));
obs('L13.hors-carte', T.tableCollisions(base({ collisions: [['hors/lab.js', 'agents', ['a', 'b'], null]] }), vue()));
obs('L13.fichiers', [...T.parFichier(base(), vue()).keys()]);
obs('L15.radar', [T.radar(base(), 'ouvert', 4), T.radar(base(), 'ouvert', 1).texte, T.radar(base({ collisions: [] }), 'ouvert', 0).etat]);
obs('L12.nbsp', (() => { // l'espace insécable avant `: ; ! ? %` dans CHAQUE chaîne
  const mal = []; const voir = (k, v) => { if (typeof v === 'string') { if (/[^\s  ] (?=[:;!?%])/.test(v)) mal.push(k); } else if (Array.isArray(v)) v.forEach((x, i) => voir(k + i, x)); };
  for (const [k, v] of Object.entries(T.TEXTES)) voir(k, v);
  for (const k of Object.keys(T.F)) { try { voir('F.' + k, T.F[k](3, 'x')); voir('F.' + k + '0', T.F[k](0)); } catch { /* signature */ } }
  voir('mots', T.SOURCE_MOT.arbres(2)); return mal; })());
obs('L12.milliers', [T.nb(1203), T.nb(5000), T.nb(12)].map((s) => s.replace(NB, '<nbsp>')));
obs('L12.textes', T.TEXTES);
console.log(out.join('\n'));
