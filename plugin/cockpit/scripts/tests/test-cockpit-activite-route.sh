#!/usr/bin/env bash
# test-cockpit-activite-route.sh — Phase 75, plan 75-05 (ACTV-04, ACTV-08, ACTV-10, ACTV-12 ; P75-D-09, P75-D-22, P75-D-23, A10, A11, A25, A31, A45, A47) :
# la route GET /api/vf/activite, son schéma, son cache par signature, son mono-vol, ses dégradations et l'export autonome qui reste fermé.
#   R1-R4 route, accès, table, schéma (serveur lancé) · R5-R17 assemblage, cache, mono-vol, clés, dégradations, bornes (module en node, hors serveur)
#   X1-X3 l'export autonome ne porte rien de l'activité (A25), avec son témoin positif
# Mutants : une copie des scripts, l'ancre à exactement une occurrence, `node --check` prouve que la copie charge ; le témoin rejoué DOIT rougir.
# Sortie : « PASS — <id> : … », « ❌ FAIL — <id> : … », « MUTANT-ROUGE — <nom> », « BILAN : n PASS, m FAIL » ; code non nul au premier FAIL.
# Lab neutre dans mktemp, HOME jetable, isolation git. Le code testé est celui du dossier de cette suite.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/mut"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
NB=0; NF=0; NM=0
ok() { # ok <id> <texte> <obtenu> <attendu>
  if [ "$3" = "$4" ]; then echo "PASS — $1 : $2"; NB=$((NB+1))
  else echo "❌ FAIL — $1 : $2"; echo "     attendu: [${4:0:400}]"; echo "     obtenu:  [${3:0:400}]"; NF=$((NF+1)); [ -n "${TOUT:-}" ] || { echo "BILAN : $NB PASS, $NF FAIL"; exit 1; }; fi # TOUT=1 : tout rejouer (trace des rouges)
}
assert_eq() { ok "${1%% — *}" "${1#* — }" "$2" "$3"; } # forme attendue par hygiene.sh (vf_hyg_assert)
rouge() { echo "MUTANT-ROUGE — $1"; NM=$((NM+1)); }
jf() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=new Function('j','return ('+process.argv[2]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" "$2" 2>/dev/null || echo illisible; }

# ---------- aides ----------
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <scripts> <dst> <fichier> <de> <vers> [<de> <vers>…] : copie les .mjs et le contrat, remplace chaque ancre EXACTEMENT une fois (code 3 sinon), la copie doit charger
import fs from 'node:fs'; import path from 'node:path'; import { execFileSync } from 'node:child_process';
const [, , src, dst, fichier, ...paires] = process.argv;
fs.rmSync(dst, { recursive: true, force: true }); fs.mkdirSync(dst, { recursive: true });
for (const f of fs.readdirSync(src)) if (/\.mjs$|\.json$/.test(f)) fs.copyFileSync(path.join(src, f), path.join(dst, f));
const cible = path.join(dst, fichier); let t = fs.readFileSync(cible, 'utf8');
for (let i = 0; i < paires.length; i += 2) {
  const n = t.split(paires[i]).length - 1;
  if (n !== 1) { console.error(`ancre « ${paires[i].slice(0, 60)} » : ${n} occurrence(s)`); process.exit(3); }
  t = t.replace(paires[i], () => paires[i + 1]);
}
fs.writeFileSync(cible, t);
if (/\.mjs$/.test(fichier)) try { execFileSync(process.execPath, ['--check', cible], { stdio: 'pipe' }); } catch (e) { console.error('la copie ne charge pas : ' + String(e.stderr).slice(0, 200)); process.exit(4); }
JS
mutant() { # mutant <nom> <fichier> <de> <vers> [...] -> chemin de la copie sur la sortie standard ; un mutant invalide est un FAIL, jamais un rouge
  local nom="$1"; shift; node "$AUX/mut.mjs" "$SCRIPTS" "$WORK/mut/$nom" "$@" > /dev/null 2> "$WORK/mut/$nom.err" || { echo "❌ FAIL — mutant $nom invalide : $(cat "$WORK/mut/$nom.err")"; echo "BILAN : $NB PASS, $((NF+1)) FAIL"; exit 1; }
  echo "$WORK/mut/$nom"
}
# validateur INDÉPENDANT de la suite : clés requises typées, énumérations du bloc, interdits absents à toute profondeur, clés dynamiques exclues
cat > "$AUX/valide.mjs" <<'JS'
// valide.mjs <contrat> <fichier> : OK, ou KO et les écarts
import fs from 'node:fs';
const [, , ifaceF, outF] = process.argv, id = 'vibeflow/cockpit-activite@1';
let spec, out;
try { spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id]; } catch { spec = null; }
if (!spec) { console.log('KO schéma absent du contrat'); process.exit(1); }
try { out = JSON.parse(fs.readFileSync(outF, 'utf8')); } catch { console.log('KO sortie illisible'); process.exit(1); }
const errs = [], type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) { if (!(k in out)) errs.push(`absente : ${k}`); else if (type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])}`); }
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
if (JSON.stringify(spec.interdits) !== JSON.stringify(['doing', 'mandat', 'messages', 'outils', 'fil'])) errs.push('interdits du bloc non recopiés');
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { if (!Array.isArray(o)) f(k); deep(v, f); } }; // les indices d'un tableau ne sont pas des clés
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`interdite : ${k}`); });
const cles = new Set(spec.cles || []); deep(out, (k) => { if (!cles.has(k)) errs.push(`clé hors contrat : ${String(k).slice(0, 40)}`); });
const dans = (v, l, nom) => { if (!(l || []).includes(v)) errs.push(`${nom} = ${v}`); };
dans(out.etat, spec.etats, 'etat'); dans(out.calcul, spec.calcul, 'calcul');
for (const s of ['git', 'branches', 'gardes', 'empreinte']) if (out[s]) dans(out[s].etat, (spec[s] || {}).etats, `${s}.etat`);
for (const t of out.collisions || []) { if (!Array.isArray(t) || t.length !== 4) errs.push('tuple de collision'); else dans(t[1], spec.collisions && spec.collisions.sources, 'source'); }
for (const r of (out.radar || {}).raisons || []) dans(r, spec.radar && spec.radar.raisons, 'raison');
console.log(errs.length ? 'KO ' + [...new Set(errs)].join(' | ') : 'OK'); process.exit(errs.length ? 1 : 0);
JS
valide() { node "$AUX/valide.mjs" "${2:-$SCRIPTS}/vf-cockpit-interface.json" "$1" 2>&1; }

# ---------- serveur lancé : lab neutre, assemblage, démarrage ----------
LAB="$WORK/lab"
node "$TESTS/frise-labo.mjs" lab "$LAB"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || { echo "❌ FAIL — R0 : assemblage du lab"; cat "$WORK/build.out"; echo "BILAN : $NB PASS, $((NF+1)) FAIL"; exit 1; }
cockpit_lancer "$LAB"
ok R0 "témoin : le serveur est lancé, le jeton est lu" "$([ "${VF_PORT:-0}" -gt 0 ] && [ "${#VF_JETON}" -ge 16 ] && echo oui || echo non)" "oui"
gc() { node "$TESTS/graphe-client.mjs" "$@"; }

echo "=== R1-R4 — la route, ses contrôles, la table, le schéma ==="
cockpit_get /api/vf/activite > "$WORK/r1.json" 2> /dev/null; R1_CODE="$VF_CODE"
ok R1 "GET /api/vf/activite : 200, JSON, les neuf champs de l'objet" "$R1_CODE|$(jf "$WORK/r1.json" '[j.schema,typeof j.at,typeof j.etat,typeof j.calcul,typeof j.git,typeof j.branches,typeof j.gardes,typeof j.empreinte,Array.isArray(j.collisions),typeof j.radar].join(",")')" "200|vibeflow/cockpit-activite@1,string,string,string,object,object,object,object,true,object"
J="$VF_JETON"; P="$VF_PORT"
R2="$(gc get "$P" /api/vf/activite "" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"
R2b="$(gc get "$P" /api/vf/activite "$J" "evil.example:$P" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"
R2c="$(gc get "$P" /api/vf/activite "$J" "" "Origin=http://evil.example" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"
R2d="$(gc get "$P" /api/vf/activite "faux-jeton-faux-jeton-00000000" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"
R2e=""; for m in POST PUT DELETE; do R2e="$R2e $(GRAPHE_METHODE=$m gc get "$P" /api/vf/activite "$J" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).statut))')"; done
R2f="$(gc get "$P" /api/vf/activite "$J" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const j=JSON.parse(s);console.log(j.statut+"|"+j.entetes["cache-control"]+"|"+Object.keys(j.entetes).filter(k=>k.startsWith("access-control")).length)})')"
R2_SRC="$(grep -c -E 'x-vf-cockpit-token|Host' "$SCRIPTS/vf-cockpit-activite.mjs" 2>/dev/null || true)"
ok R2 "accès par la réponse gardée : sans jeton, Host étranger, Origin étrangère, faux jeton = 403 ; POST, PUT, DELETE = 405 ; 200 no-store sans CORS ; aucun contrôle recopié dans le module" "$R2 $R2b $R2c $R2d$R2e|$R2f|$R2_SRC" "403 403 403 403 405 405 405|200|no-store|0|0"
STAT_ROUTES="$(node --input-type=module -e "const m=await import('file://$SCRIPTS/vf-cockpit-server.mjs');const a=await import('file://$SCRIPTS/vf-cockpit-activite.mjs');const c=m.ROUTES.map((l)=>l[0]);const L=m.ROUTES.filter((l)=>l[0]==='/api/vf/activite');console.log([L.length,c.indexOf('/api/vf/activite')===0,JSON.stringify(c)===JSON.stringify([...c].sort()),L[0]&&L[0][1]===a.routeActivite,L[0]&&L[0].length].join(','))" 2>/dev/null || echo absent)"
ok R3 "la table importée : UNE ligne /api/vf/activite, en tête de l'ordre alphabétique, ordre trié, lecteur = routeActivite, aucun régime" "$STAT_ROUTES" "1,true,true,true,2"
node "$AUX/valide.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$WORK/r1.json" > "$WORK/r4.out" 2>&1; ok R4 "le bloc vibeflow/cockpit-activite@1 est déclaré, interdits recopiés, la réponse réelle est conforme (clés, énumérations)" "$(cat "$WORK/r4.out")" "OK"
cockpit_arreter

# ---- mutants de la tâche 1 (quatre) ----
M="$(mutant ligne-double vf-cockpit-server.mjs "  ['/api/vf/activite', routeActivite]," "  ['/api/vf/activite', routeActivite],
  ['/api/vf/activite', routeActivite],")"
[ "$(node --input-type=module -e "const m=await import('file://$M/vf-cockpit-server.mjs');console.log(m.ROUTES.filter((l)=>l[0]==='/api/vf/activite').length===1)" 2>/dev/null)" = "true" ] || rouge "ligne-en-double"
M="$(mutant ligne-hors-ordre vf-cockpit-server.mjs "  ['/api/vf/activite', routeActivite],
  ['/api/vf/doing', lireDoing, HISTORIQUE]," "  ['/api/vf/doing', lireDoing, HISTORIQUE],
  ['/api/vf/activite', routeActivite],")"
[ "$(node --input-type=module -e "const m=await import('file://$M/vf-cockpit-server.mjs');const c=m.ROUTES.map((l)=>l[0]);console.log(JSON.stringify(c)===JSON.stringify([...c].sort()))" 2>/dev/null)" = "true" ] || rouge "ligne-hors-ordre"
M="$(mutant controle-recopie vf-cockpit-activite.mjs "export const routeActivite" "const _faux = (r) => r.headers['x-vf-cockpit-token'];
export const routeActivite")"
[ "$(grep -c -E 'x-vf-cockpit-token|Host' "$M/vf-cockpit-activite.mjs")" = "0" ] || rouge "controle-recopie-dans-le-module"
M="$(mutant schema-sans-interdits vf-cockpit-interface.json '"interdits": ["doing", "mandat", "messages", "outils", "fil"]
    },
    "vibeflow/cockpit-git@1"' '"interdits": []
    },
    "vibeflow/cockpit-git@1"')"
[ "$(node "$AUX/valide.mjs" "$M/vf-cockpit-interface.json" "$WORK/r1.json" 2>&1)" = "OK" ] || rouge "bloc-sans-interdits"

echo "=== R5-R17 — assemblage, cache, mono-vol, clé interdite, dégradations, bornes (module en node, hors serveur : aucun point d'injection dans le serveur de production) ==="
# cas.mjs <scripts> <cas> <work> : un cas du module d'activité ; fixture neuve dans <work> (dépôt git, worktree vérifié, graph.json), faux binaire git qui journalise l'argv ; UNE ligne JSON
cat > "$AUX/cas.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path'; import http from 'node:http'; import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process'; import { pathToFileURL } from 'node:url';
const [, , scripts, cas, work] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const GE = { ...process.env, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: '/dev/null' };
for (const k of ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR', 'GIT_OBJECT_DIRECTORY', 'GIT_NAMESPACE', 'GIT_CEILING_DIRECTORIES']) delete GE[k];
const git = (d, ...a) => execFileSync('git', ['-C', d, '-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { stdio: 'ignore', env: GE });
const R = fs.mkdtempSync(path.join(work, 'cas-')), lab = path.join(R, 'lab'), wt = path.join(R, 'wt'), here = path.join(lab, '.vibeflow', 'cockpit');
const LOG = path.join(R, 'espion.log'), DORS = path.join(R, 'espion.dors'), FAILF = path.join(R, 'espion.echec'), BIN = path.join(R, 'bin'), SPY = path.join(BIN, 'git');
const reel = execFileSync('which', ['git'], { encoding: 'utf8' }).trim();
fs.mkdirSync(BIN); // le faux git s'injecte par le PATH (forme maison, hors du lab : l'assainissement du PATH le garde) ; le module ne choisit jamais le programme git
fs.writeFileSync(SPY, `#!/bin/bash\nprintf '%s\\n' "$*" >> "${LOG}"\nif [ -f "${DORS}" ]; then for a in "$@"; do [ "$a" = log ] && sleep 2; done; fi\nif [ -f "${FAILF}" ]; then for a in "$@"; do [ "$a" = for-each-ref ] && exit 1; done; fi\nexec "${reel}" "$@"\n`, { mode: 0o755 });
process.env.PATH = `${BIN}${path.delimiter}${process.env.PATH}`;
const sousDe = (l) => { const t = l.split(' '); let i = 0; while (i < t.length && t[i].startsWith('-')) i += (t[i] === '-C' || t[i] === '-c') ? 2 : 1; return t[i]; };
const journal = () => (fs.existsSync(LOG) ? fs.readFileSync(LOG, 'utf8').split('\n').filter(Boolean) : []);
const FICHIERS = [['fil', 5], ['src/a.js', 20], ['src/b.js', 30], ['src/c.js', 10]];
const ecrireGraphe = (h, vf, extra = []) => { fs.mkdirSync(h, { recursive: true });
  fs.writeFileSync(path.join(h, 'graph.json'), JSON.stringify({ meta: vf ? { vfCodeExtractor: 'vibeflow', prevusIgnores: 3 } : {},
    files: [...FICHIERS.map(([p, loc]) => ({ p, loc, l: 'js' })), ...extra] })); };
const add = (d, f, t) => fs.appendFileSync(path.join(d, f), t);
function fabriquer() {
  fs.mkdirSync(path.join(lab, 'src'), { recursive: true });
  for (const [p] of FICHIERS) fs.writeFileSync(path.join(lab, p), '0\n');
  fs.writeFileSync(path.join(lab, '.gitignore'), '.vibeflow/\n');
  git(lab, 'init', '-q', '-b', 'main'); git(lab, 'add', '-A'); git(lab, 'commit', '-q', '-m', 'init');
  for (let i = 1; i <= 3; i++) { add(lab, 'src/a.js', `${i}\n`); add(lab, 'src/b.js', `${i}\n`); git(lab, 'commit', '-q', '-a', '-m', `c${i}`); }
  git(lab, 'worktree', 'add', '-q', '-b', 'messages', wt);
  add(wt, 'fil', 'w\n'); add(wt, 'src/a.js', 'w\n'); git(wt, 'commit', '-q', '-a', '-m', 'wt');
  add(lab, 'fil', 'm\n'); add(lab, 'src/a.js', 'm\n'); git(lab, 'commit', '-q', '-a', '-m', 'lab');
  ecrireGraphe(here, true);
}
const condensat = (d) => { const h = crypto.createHash('sha256'); const marche = (x) => { for (const n of fs.readdirSync(x).sort()) { const p = path.join(x, n), s = fs.lstatSync(p);
  if (s.isDirectory()) marche(p); else h.update(p.slice(d.length) + '\0' + s.size + '\0' + fs.readFileSync(p)); } }; marche(d); return h.digest('hex'); };
const NOW = Date.now();
const voie = (o) => ({ id: 'v', kind: 'subagent', session: 's1', parent: null, depth: 1, role: 'coder', arbre: null, background: false, debut: NOW - 60000, fin: NOW - 1000,
  dispatchA: null, fini: false, arrete: false, etatOfficiel: 'actif', rattachement: null, cibles: { etat: 'ok', tronque: false, ecritures: [], lectures: [] }, ...o });
const ec = (cible, arbre = null) => ({ arbre, cible, n: 1, dernierMs: NOW - 2000 });
const cb = (ecritures, o = {}) => ({ etat: 'ok', tronque: false, ecritures, lectures: [], ...o });
const frise = (voies, o = {}) => ({ at: NOW, sig: 'f1', source: { etat: 'ok', ccVerifie: null, versionsVues: [] }, tronque: false, voies, ...o });
const instOf = (o = {}) => ({ seq: 1, at: NOW, git: { sig: 'aaaa000000000001', at: NOW }, projet: { files: [] }, frise: frise([]), ...o });
const plan = (p, name, touched, o = {}) => ({ p, n: 'ph-1', name, st: 'todo', vague: 1, touched, ...o });
const { creerActivite, creerRouteActivite } = await imp('vf-cockpit-activite.mjs');
const mk = (H, o = {}) => creerActivite({ lireInstantane: () => H.v, ...o });
const pret = async (act, ctx, ms = 25000) => { const t0 = Date.now(); for (;;) { const r = act(ctx); if (r.calcul === 'pret' || Date.now() - t0 > ms) return r; await dormir(25); } };
const stable = async () => { let n = journal().length; const t0 = Date.now(); for (;;) { await dormir(250); const m = journal().length; if (m === n || Date.now() - t0 > 8000) return m; n = m; } };
const out = {}; fabriquer(); const ctx = { root: lab, here };
try {
if (cas === 'assemblage') {
  const H = { v: instOf({
    projet: { files: [plan('.planning/p/01-01-PLAN.md', '01-01', ['shared.mjs', 'a.mjs']), plan('.planning/p/01-02-PLAN.md', '01-02', ['shared.mjs']),
      plan('.planning/p/01-03-PLAN.md', '01-03', ['shared.mjs'], { st: 'done' })] },
    frise: frise([
      voie({ id: 'a', role: 'coder-a', cibles: cb([ec('src/a.js')], { lectures: [ec('src/c.js')] }) }), voie({ id: 'b', role: 'coder-b', cibles: cb([ec('src/a.js')]) }),
      voie({ id: 'c', role: 'wt-agent', arbre: 'wt', cibles: cb([ec('src/c.js', 'wt')]) }), voie({ id: 'd', role: 'main-agent', cibles: cb([ec('src/c.js')]) }),
      voie({ id: 'e', role: 'fantome', arbre: 'fantome', cibles: cb([ec('src/b.js', 'fantome')]) }), voie({ id: 'f', role: 'wt-seul', arbre: 'wt', cibles: cb([ec('src/b.js', 'wt')]) })]) }) };
  const act = mk(H), r = await pret(act, ctx), r2 = act(ctx), sans = (x) => JSON.stringify({ ...x, at: 0 });
  fs.writeFileSync(path.join(work, 'r5.json'), JSON.stringify(r));
  out.etats = [r.etat, r.calcul, r.git.etat, r.branches.etat, r.gardes.etat, r.empreinte.etat].join(',');
  out.git = [r.git.chauds.some((t) => t[0] === 'src/a.js' && t[2] === 20), Array.isArray(r.git.couplage), r.git.fenetre.commits >= 5, [1, 3].includes(r.git.paliers)].join(',');
  out.branches = [r.branches.tetes, r.collisions.filter((t) => t[1] === 'branches').map((t) => t[2].join('+')).join(';')].join('|');
  out.gardes = [r.gardes.prevusIgnores, r.gardes.gardes.some((t) => t[0] === 'fil' && Number.isInteger(t[1]))].join(',');
  out.sequence = JSON.stringify(r.collisions.map((t) => [t[0], t[1]]));
  out.noms = JSON.stringify(r.collisions.filter((t) => t[1] === 'agents' || t[1] === 'arbres').map((t) => t[2]));
  out.plans = JSON.stringify(r.collisions.filter((t) => t[1] === 'plans'));
  out.stable = sans(r) === sans(r2);
  out.sources = [...new Set(r.collisions.map((t) => t[1]))].sort().join(',');
  out.horsLab = [r.empreinte.horsLab, r.empreinte.marques.some((m) => m[0] === 'src/b.js' && m[2].includes('wt-seul · non rattaché')), r.empreinte.marques.some((m) => m[2].includes('fantome · non rattaché'))].join(',');
} else if (cas === 'cache') {
  const H = { v: instOf({ frise: frise([voie({ id: 'a', cibles: cb([ec('src/a.js')]) })]) }) };
  const act = mk(H), t = [], appel = () => { const t0 = performance.now(); const r = act(ctx); t.push(performance.now() - t0); return r; };
  const c1 = condensat(lab); fs.writeFileSync(DORS, '');
  const gaps = []; let dernier = Date.now(); const iv = setInterval(() => { const n = Date.now(); gaps.push(n - dernier); dernier = n; }, 20);
  const r0 = appel(); appel(); appel();
  out.premier = [r0.etat, r0.calcul, r0.git.etat, r0.branches.etat].join(',');
  out.rapide = Math.max(...t) < 150;
  await pret(act, ctx); await dormir(40); clearInterval(iv); fs.rmSync(DORS); // un tick de plus : l'écart d'une boucle gelée n'est mesuré qu'au tick suivant
  out.ecartMax = Math.max(...gaps); out.unLog = journal().filter((l) => sousDe(l) === 'log').length;
  const n1 = journal().length;
  for (let i = 0; i < 6; i++) act(ctx);
  out.zero = (await stable()) - n1; // journal au repos (inchangé 250 ms) : un relancement lent n'échappe pas au décompte
  out.interdits = journal().map(sousDe).filter((s) => ['status', 'diff', 'fetch', 'pull', 'ls-remote'].includes(s));
  out.intact1 = condensat(lab) === c1;
  const n3 = journal().length; ecrireGraphe(here, true, [{ p: 'src/d.js', loc: 3, l: 'js' }]); await pret(act, ctx); out.graphe0 = journal().length - n3; // le graphe seul : aucun git
  add(lab, 'src/c.js', 'x\n'); git(lab, 'commit', '-q', '-a', '-m', 'suite'); const c2 = condensat(lab);
  const prec = act(ctx); fs.writeFileSync(DORS, '');
  H.v = instOf({ git: { sig: 'aaaa000000000002', at: NOW }, frise: H.v.frise });
  const en = act(ctx), n2 = journal().length;
  out.precedent = [en.calcul, en.etat, en.git.etat, JSON.stringify(en.git.fenetre) === JSON.stringify(prec.git.fenetre)].join(',');
  const fin = await pret(act, ctx); fs.rmSync(DORS);
  const neufs = journal().slice(n2);
  out.lsfiles = neufs.some((l) => sousDe(l) === 'ls-files'); out.logs2 = neufs.filter((l) => sousDe(l) === 'log').length; out.commits = fin.git.fenetre.commits - prec.git.fenetre.commits;
  out.autres = [...new Set(neufs.map(sousDe))].filter((s) => !['for-each-ref', 'worktree', 'rev-parse', 'log', 'rev-list', 'diff-tree', 'ls-files', 'config'].includes(s)).join(','); // config : la lecture des filtres du dépôt que fait le lanceur avant chaque git
  out.interdits2 = journal().map(sousDe).filter((s) => ['status', 'diff', 'fetch', 'pull', 'ls-remote'].includes(s));
  out.intact2 = condensat(lab) === c2;
} else if (cas === 'lecture') {
  const H = { v: instOf({ git: null }) }; let T = 1e12; const A = mk(H, { horloge: () => T, graceMs: 30000 });
  const r = A(ctx); out.lecture = [r.git.etat, r.branches.etat, r.gardes.etat, r.calcul, r.etat, r.gardes.gardes.length].join(',');
  T += 29000; const r2 = A(ctx); out.avant = [r2.git.etat, journal().length].join(',');
  T += 2000; A(ctx); const r4 = await pret(A, ctx); out.apres = [r4.git.etat, r4.calcul, r4.etat].join(',');
  const B = mk({ v: null }); const rb = B(ctx); out.nul = [rb.git.etat, rb.calcul, rb.etat, rb.empreinte.etat].join(',');
} else if (cas === 'tronque') {
  const H = { v: instOf({ frise: frise([voie({ id: 'a', role: 'coder-a', cibles: cb([ec('src/a.js')]) }), voie({ id: 'b', role: 'coder-b', cibles: cb([ec('src/a.js')]) })], { tronque: true }) }) };
  const r = await pret(mk(H), ctx); out.tronque = [r.empreinte.etat, r.radar.incomplet, r.radar.raisons.includes('tronque')].join(',');
} else if (cas === 'coupees') {
  const H = { v: instOf({ frise: frise([
    voie({ id: 't', role: 'coder-t', cibles: cb([ec('src/a.js'), ec('src/b.j…')], { tronque: true }) }), voie({ id: 'u', role: 'coder-u', cibles: cb([ec('src/a.js')]) }),
    voie({ id: 'v', role: 'coder-v', cibles: cb([ec('src/b.js')]) })]) }) };
  const r = await pret(mk(H), ctx);
  out.coupees = [r.empreinte.coupees, r.empreinte.voiesCiblesTronquees, r.radar.incomplet, r.radar.raisons.includes('cibles-coupees')].join(',');
  out.jointes = JSON.stringify(r.collisions.filter((t) => t[1] === 'agents').map((t) => [t[0], t[2].length]));
  out.marque = r.empreinte.marques.some((m) => m[0] === 'src/a.js' && m[2].length === 2);
} else if (cas === 'degrade') {
  const nu = path.join(R, 'nu'), hn = path.join(nu, '.vibeflow', 'cockpit'); fs.mkdirSync(nu, { recursive: true }); ecrireGraphe(hn, false);
  const H = { v: instOf({ git: { sig: 'zz00000000000001', at: NOW }, frise: frise([voie({ id: 'a', cibles: cb([ec('src/a.js')]) })]) }) }, A = mk(H), cn = { root: nu, here: hn };
  const r = await pret(A, cn); fs.writeFileSync(path.join(work, 'r10.json'), JSON.stringify(r));
  out.horsDepot = [r.git.etat, r.branches.etat, r.gardes.etat, r.empreinte.etat, r.calcul, r.etat].join(',');
  ecrireGraphe(hn, true); const r2 = await pret(A, cn); out.sansGit = [r2.git.etat, r2.branches.etat, r2.gardes.etat, r2.gardes.prevusIgnores].join(',');
  const C = { v: instOf({ frise: frise([voie({ id: 'a', cibles: cb([ec('src/a.js')], { etat: 'en-construction' }) })]) }) }, rc = await pret(mk(C), ctx);
  out.construction = [rc.empreinte.etat, rc.radar.incomplet, rc.radar.raisons.includes('en-construction'), rc.collisions.every((c) => c[1] === 'branches')].join(',');
  const X = { v: instOf({ frise: frise([voie({ id: 'a', cibles: cb(5) })]) }) }, rx = await pret(mk(X), ctx);
  out.exception = [rx.empreinte.etat, rx.radar.raisons.includes('agents-indisponible'), rx.git.etat, rx.branches.etat, rx.gardes.etat, rx.calcul, rx.etat].join(',');
} else if (cas === 'bornes') {
  const touched = Array.from({ length: 700 }, (_, i) => `d/f${String(i).padStart(4, '0')}.mjs`);
  const H = { v: instOf({ projet: { files: [plan('.planning/p/02-01-PLAN.md', 'A', touched), plan('.planning/p/02-02-PLAN.md', 'B', touched)] } }) };
  const r = await pret(mk(H), ctx);
  out.bornes = [r.collisions.length, r.radar.total, r.radar.tronque, r.radar.raisons.includes('collisions-tronquees'), r.radar.incomplet].join(',');
} else if (cas === 'gel' || cas === 'gelPlafond') { // F1 : un calcul des gardes CPU volumineux ne gèle pas la boucle ; au-delà du plafond : tronque
  const n = cas === 'gel' ? 3000 : 6000;
  fs.mkdirSync(path.join(lab, 'scripts', 'tests'), { recursive: true });
  fs.writeFileSync(path.join(lab, 'scripts', 'tests', 'test-motifs.sh'), Array.from({ length: n }, (_, i) => `# plugin/mod${i}/*/f*.sh`).join('\n') + '\n');
  git(lab, 'add', '-A'); git(lab, 'commit', '-q', '-m', 'motifs');
  fs.writeFileSync(path.join(here, 'graph.json'), JSON.stringify({ meta: { vfCodeExtractor: 'vibeflow' }, files: Array.from({ length: 8000 }, (_, i) => ({ p: `plugin/m/f${i}.js`, loc: 5, l: 'js' })) }));
  const act = mk({ v: instOf() }), gaps = []; let dernier = Date.now(); const iv = setInterval(() => { const m = Date.now(); gaps.push(m - dernier); dernier = m; }, 20);
  const t0 = Date.now(), r = await pret(act, ctx, 90000); await dormir(40); clearInterval(iv);
  out.ecartMax = Math.max(...gaps); out.duree = Date.now() - t0; out.gardes = [r.gardes.etat, r.gardes.gardes.length, r.gardes.tronque].join(',');
} else if (cas === 'octets') { // F2 : réponse bornée en octets, sérialisée une seule fois, squelette des clés pour la garde d'émission
  const SJ = JSON.stringify; let gros = 0; JSON.stringify = (...a) => { const s = SJ(...a); if (s && s.length > 5000) gros++; return s; };
  const touched = [...Array.from({ length: 200 }, (_, i) => `d/f${String(i).padStart(4, '0')}.mjs`), 'x'.repeat(400) + '.mjs'];
  const H = { v: instOf({ projet: { files: Array.from({ length: 2000 }, (_, i) => plan(`.planning/p/03-${String(i).padStart(4, '0')}-PLAN.md`, `plan-${i}`, touched)) } }) };
  const act = mk(H), L = creerRouteActivite(act); await pret(act, ctx, 40000);
  const r1 = L(ctx), g1 = gros, rep = JSON.parse(r1.options.brut); const r2 = L(ctx), r3 = L(ctx), g2 = gros;
  const cles = (v, s = new Set()) => { if (Array.isArray(v)) v.forEach((x) => cles(x, s)); else if (v && typeof v === 'object') for (const [k, x] of Object.entries(v)) { s.add(k); cles(x, s); } return s; };
  const r4 = creerRouteActivite(act, { maxOctets: 2000 })(ctx), rep4 = JSON.parse(r4.options.brut);
  JSON.stringify = SJ;
  out.taille = r1.options.brut.length; out.maxNoms = Math.max(...rep.collisions.map((x) => x[2].length));
  out.noms = [rep.radar.nomsTronques, rep.radar.cheminsEcartes, rep.radar.raisons.includes('chemins-ecartes'), rep.radar.raisons.includes('plans-tronques')].join(',');
  out.sameBrut = r1.options.brut === r2.options.brut && r2.options.brut === r3.options.brut; out.stringify = g2 - g1;
  out.controle = [JSON.stringify([...cles(r1.corps)].sort()) === JSON.stringify([...cles(r1.options.controle)].sort()), SJ(r1.options.controle).length < 5000].join(',');
  out.reduit = [rep4.radar.raisons.includes('reponse-trop-grosse'), rep4.collisions.length === 0, r4.options.brut.length < r1.options.brut.length].join(',');
} else if (cas === 'reprise') { // F3 : un échec passager reprend après un délai, une seule fois par délai
  let T = 1e12; const act = mk({ v: instOf() }, { horloge: () => T, retryMs: 60000 });
  fs.writeFileSync(FAILF, '');
  const r0 = await pret(act, ctx), n0 = journal().length;
  out.echec = [r0.git.etat, r0.calcul].join(',');
  T += 30000; for (let i = 0; i < 5; i++) act(ctx);
  await dormir(300); out.calme = journal().length - n0;
  T += 31000; act(ctx); await pret(act, ctx); const tentative = journal().length - n0;
  for (let i = 0; i < 8; i++) act(ctx);
  await dormir(300); out.unSeul = journal().length - n0 === tentative && tentative > 0;
  fs.rmSync(FAILF); T += 61000; act(ctx); const r2 = await pret(act, ctx); out.reprise = [r2.git.etat, r2.branches.etat, r2.calcul].join(',');
} else if (cas === 'cles') { // R9 : un fichier racine `fil`, une branche `messages`, un rôle d'agent `doing` ; réponse gardée de bout en bout par HTTP
  const S = await imp('vf-cockpit-server.mjs'), RT = await imp('vf-cockpit-routes.mjs'), I = await imp('vf-cockpit-instantane.mjs'), A = await imp('vf-cockpit-activite.mjs');
  I.poser({ seq: 1, at: NOW, git: { sig: 'aaaa000000000001', at: NOW }, projet: { files: [] } });
  I.poserFrise(frise([voie({ id: 'a', role: 'doing', cibles: cb([ec('fil')]) })]));
  const TOK = crypto.randomBytes(16).toString('hex'), acces = (q) => RT.controlerAcces(q, { jetonValide: (j) => j === TOK });
  const rep = RT.creerRepartiteur({ table: [['/api/vf/activite', A.routeActivite]], contexte: Object.freeze({ root: lab, here }), acces, json: () => {},
    repondre: (q, s, corps, o) => S.repondreGardee(q, s, corps, { ...o, acces, log: () => {} }) });
  const srv = http.createServer((q, s) => { if (!rep.servir(q, s, new URL(q.url, 'http://x'))) { s.writeHead(404); s.end(); } });
  await new Promise((r) => srv.listen(0, '127.0.0.1', r)); const port = srv.address().port;
  const get = () => new Promise((resolve) => http.get({ host: '127.0.0.1', port, path: '/api/vf/activite', headers: { Host: `127.0.0.1:${port}`, 'x-vf-cockpit-token': TOK } }, (res) => {
    let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => resolve({ s: res.statusCode, b })); }));
  const t0 = Date.now(); let x = await get();
  while (x.s === 200 && JSON.parse(x.b).calcul !== 'pret' && Date.now() - t0 < 25000) { await dormir(100); x = await get(); }
  if (x.s === 200) fs.writeFileSync(path.join(work, 'r9.json'), x.b);
  out.statut = x.s; out.corps = x.s === 200 ? 'json' : x.b;
  out.valeurs = ['doing', 'messages', 'fil'].map((v) => x.b.includes(`"${v}"`) || x.b.includes(`"${v} `)).join(',');
  srv.closeAllConnections?.(); srv.close();
}
} catch (e) { out.erreur = String(e && e.message).slice(0, 160); } // une erreur est dite dans le verdict, jamais un silence
console.log(JSON.stringify(out));
setTimeout(() => process.exit(0), 50);
JS
cas() { node "$AUX/cas.mjs" "$SCRIPTS" "$1" "$WORK" 2> "$WORK/cas-$1.err" | tail -1; }
cj() { node -e 'let o;try{o=JSON.parse(process.argv[1])}catch{console.log("illisible");process.exit(0)}const v=new Function("o","return ("+process.argv[2]+")")(o);console.log(typeof v==="string"?v:JSON.stringify(v))' "$1" "$2"; }

C="$(cas assemblage)"
ok R5 "un lab avec git : sections git (chauds, couplage, fenêtre, paliers), branches (deux têtes), gardes (prévus ignorés : 3), empreinte, état ok et calcul prêt" \
  "$(cj "$C" '[o.etats,o.git,o.branches,o.gardes].join("|")')" "ok,pret,ok,ok,ok,ok|true,true,true,true|2|main+messages;main+messages|3,true"
ok R5b "collisions : agents, arbres, branches et plans fusionnés en tuples [chemin, source, noms, vague], ordre déterministe, une lecture jamais jointe, deux appels égaux" \
  "$(cj "$C" '[o.sequence,o.noms,o.plans,o.stable].join("#")')" '[["fil","branches"],["shared.mjs","plans"],["src/a.js","agents"],["src/a.js","branches"],["src/c.js","arbres"]]#[["coder-a · non rattaché","coder-b · non rattaché"],["main-agent · non rattaché","wt-agent · non rattaché"]]#[["shared.mjs","plans",["01-01","01-02"],1]]#true'
node "$AUX/valide.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$WORK/r5.json" > "$WORK/r5.out" 2>&1; ok R4b "la réponse assemblée (quatre sources, cinq sections) est conforme au bloc du contrat : clés, énumérations, aucune clé dynamique" "$(cat "$WORK/r5.out")" "OK"
ok R13 "la source arbres (même cible dans deux arbres vérifiés) est fusionnée dans collisions : sources agents, arbres, branches, plans" "$(cj "$C" 'o.sources')" "agents,arbres,branches,plans"
ok R14 "un worktree VÉRIFIÉ du même dépôt, hors du dossier du lab, n'est jamais compté hors lab (sa cible est une marque) ; seul un arbre non prouvé l'est" "$(cj "$C" 'o.horsLab')" "1,true,false"
K="$(cas cache)"
ok R6 "signature git inchangée : ZÉRO invocation du binaire (toutes sous-commandes) sur six appels ; signature changée : UN seul log incrémental, un commit de plus, les autres sous-commandes nommées (ls-files comprise : toute invocation passe par le git espion du PATH) ; le graphe seul qui change ne lance aucun git" \
  "$(cj "$K" '[o.zero,o.logs2,o.commits,o.autres,o.graphe0,o.lsfiles].join(",")')" "0,1,1,,0,true"
ok R7 "calcul lent (2 s) : réponse immédiate avec calcul en-cours ; premier calcul etat en-calcul ; trois requêtes concurrentes = UN seul log ; l'objet précédent est servi pendant le recalcul" \
  "$(cj "$K" '[o.premier,o.rapide,o.unLog,o.precedent].join("|")')" "en-calcul,en-cours,en-lecture,en-lecture|true|1|en-cours,ok,ok,true"
ok R8 "pendant le calcul lent la boucle d'événements reste libre : écart maximal entre deux ticks de 20 ms <= 250 ms" "$(cj "$K" 'o.ecartMax<=250')" "true"
ok R12 "aucun status, diff, fetch, pull ni ls-remote lancé (argv journalisés) ; l'arbre du lab, .git compris, est identique avant et après, aux deux temps" \
  "$(cj "$K" '[o.interdits.length,o.interdits2.length,o.intact1,o.intact2].join(",")')" "0,0,true,true"
PAT_R12="node:fs|node:http|fetch\(|http\.request|'status'|'diff'|/api/vf/transcript|decodeURI|realpath|readFile|\.resolve\(|\.normalize\("
R12S="$(grep -c -E "$PAT_R12" "$SCRIPTS/vf-cockpit-activite.mjs" || true)"
ok R12b "le module n'ouvre, ne décode et ne résout aucun chemin et ne lit pas le lab (ni fs, http, fetch, status, diff, transcript, decodeURI, realpath, resolve, normalize)" "$R12S" "0"
K9="$(cas cles)"
ok R9 "un fichier racine fil, une branche messages, un rôle d'agent doing : 200 par la réponse gardée, les trois en valeurs, aucune clé dynamique ni interdite" \
  "$(cj "$K9" '[o.statut,o.corps,o.valeurs].join("|")')|$(valide "$WORK/r9.json")" "200|json|true,true,true|OK"
K10="$(cas degrade)"
ok R10 "git absent (lab hors dépôt) : 200, git et branches absents, empreinte présente, gardes non-lues (lab non VibeFlow) ; lab VibeFlow sans git : gardes indisponibles, prévus ignorés gardés" \
  "$(cj "$K10" 'o.horsDepot')|$(cj "$K10" 'o.sansGit')|$(valide "$WORK/r10.json")" "absent,absent,non-lues,ok,pret,ok|absent,absent,indisponible,3|OK"
ok R11 "cibles.etat en-construction : empreinte en-construction et radar incomplet avec sa raison, jamais « aucune collision » sans l'indication" "$(cj "$K10" 'o.construction')" "en-construction,true,true,true"
ok R11b "une exception d'un module (cibles.ecritures qui n'est pas un tableau) : indisponible sur la lentille seule, git, branches et gardes intacts, radar incomplet" "$(cj "$K10" 'o.exception')" "indisponible,true,ok,ok,ok,pret,ok"
KL="$(cas lecture)"
ok R15 "instantane().git nul : en-lecture sur git, branches et gardes, calcul en-cours, etat en-calcul, JAMAIS des tableaux vides présentés comme complets ; la grâce de 30 s passée, la lecture se fait ; instantané absent : idem" \
  "$(cj "$KL" '[o.lecture,o.avant,o.apres,o.nul].join("|")')" "en-lecture,en-lecture,en-lecture,en-cours,en-calcul,0|en-lecture,0|ok,pret,ok|en-lecture,en-cours,en-calcul,en-construction"
ok R16 "frise tronquée : empreinte tronque et radar incomplet (« Radar incomplet : historique tronqué. »), jamais « aucune collision »" "$(cj "$(cas tronque)" 'o.tronque')" "tronque,true,true"
KC="$(cas coupees)"
ok R17 "cibles coupées : empreinte.coupees et voiesCiblesTronquees servis, radar incomplet avec cibles-coupees ; les cibles ENTIÈRES de la voie tronquée sont jointes, la cible coupée ne l'est jamais à sa jumelle" \
  "$(cj "$KC" '[o.coupees,o.jointes,o.marque].join("|")')" '1,1,true,true|[["src/a.js",2]]|true'
ok R18 "la réponse est bornée : 700 collisions de plans, 500 servies, le total (702 avec les branches) et la troncature dits, raison collisions-tronquees, radar incomplet" "$(cj "$(cas bornes)" 'o.bornes')" "500,702,true,true,true"
ok R19 "audit F1 : un calcul des gardes de 3 000 motifs sur 8 000 fichiers (CPU synchrone volumineux) ne gèle pas la boucle (écart de ticks <= 250 ms) ; la liste de gardes est bornée et le dit (tronque)" \
  "$(cj "$(cas gel)" '[o.ecartMax<=250,o.gardes].join("|")')" "true|ok,3000,true"
ok R20 "audit F1 : au-delà du plafond de travail (6 000 motifs x 8 000 fichiers) la lentille dit tronque, aucune liste partielle présentée comme complète, la boucle reste libre" \
  "$(cj "$(cas gelPlafond)" '[o.ecartMax<=250,o.gardes].join("|")')" "true|tronque,0,true"
KO="$(cas octets)"
ok R21 "audit F2 : 2 000 plans x 200 chemins partagés (noms nombreux) : réponse < 1 Mo, 10 noms au plus par tuple et le dit, chemin trop long écarté et dit, sérialisée UNE fois (aucun stringify par requête), squelette de contrôle = mêmes clés et < 5 Ko, plafond d'octets qui réduit et le dit" \
  "$(cj "$KO" '[o.taille<1000000,o.maxNoms,o.noms,o.sameBrut,o.stringify,o.controle,o.reduit].join("|")')" "true|10|true,1,true,false|true|0|true,true|true,true,true"
ok R22 "audit F3 : un échec git passager reprend après le délai (60 s), jamais plus d'une tentative par délai, aucune tempête entre deux délais" \
  "$(cj "$(cas reprise)" '[o.echec,o.calme,o.unSeul,o.reprise].join("|")')" "indisponible,pret|0|true|ok,ok,pret"
# audit F5 : la propriété, quelle que soit la forme d'import (jamais le littéral d'une chaîne cherchée)
cat > "$AUX/prop.mjs" <<'JS'
// prop.mjs <module> : « aucune » ou les violations. Aucune lecture de fichier, aucun décodage, aucun réseau, aucun contrôle d'accès recopié, quelle que soit la forme d'import.
import fs from 'node:fs';
const src = fs.readFileSync(process.argv[2], 'utf8').replace(/\/\*[^]*?\*\//g, '').replace(/(^|[\s;])\/\/.*$/gm, '$1'), v = [];
const BASE = (s) => s.replace(/^node:/, '').split('/')[0];
const INTERDIT = new Set(['fs', 'http', 'https', 'http2', 'net', 'tls', 'dns', 'dgram', 'child_process', 'worker_threads', 'vm', 'module', 'readline', 'repl', 'inspector']);
const reImport = /\b(?:from|import|require)\s*\(?\s*(['"`])([^'"`]+)\1/g; let m;
const noms = new Map();
while ((m = reImport.exec(src))) { const s = m[2]; if (INTERDIT.has(BASE(s)) && !s.startsWith('.')) v.push(`import:${s}`); }
for (const x of src.matchAll(/import\s*\{([^}]*)\}\s*from\s*(['"])([^'"]+)\2/g)) noms.set(x[3], x[1].split(',').map((n) => n.trim().split(/\s+as\s+/)[0]).filter(Boolean));
const routes = noms.get('./vf-cockpit-routes.mjs') || [];
if (routes.some((n) => n !== 'reponse')) v.push(`routes:${routes.join('+')}`); // seul `reponse` : aucun contrôle d'accès recopié
for (const [re, nom] of [[/process\s*\.\s*getBuiltinModule/, 'getBuiltinModule'], [/\bfetch\b|XMLHttpRequest|WebSocket/, 'reseau'], [/decodeURI|unescape/, 'decodage'],
  [/realpath|readFile|readdir|lstat|createReadStream|openSync/, 'lecture'], [/\.\s*(?:resolve|normalize)\s*\(/, 'resolution'], [/\bheaders\b|\bsocket\b|localPort/i, 'entetes'],
  [/x-vf-cockpit|\bhost\b/i, 'jeton-ou-hote']]) if (re.test(src)) v.push(nom);
console.log(v.length ? v.join(';') : 'aucune');
JS
ok R2b "audit F5 : par la propriété, le module n'importe aucune lecture de fichier, aucun réseau ni processus, ne décode ni ne résout aucun chemin, ne lit aucun en-tête, n'importe de routes.mjs que reponse, quelle que soit la forme d'import" "$(node "$AUX/prop.mjs" "$SCRIPTS/vf-cockpit-activite.mjs")" "aucune"

# ---- mutants de la tâche 2 (douze, un par garde) ----
cat > "$AUX/mutants.mjs" <<'JS'
// mutants.mjs <scripts> <work> <aux> <liste> : chaque mutant est une copie des scripts où une garde est retirée ; le cas correspondant, rejoué, DOIT rougir
import { spawnSync } from 'node:child_process'; import path from 'node:path';
const [, , scripts, work, aux, liste] = process.argv, A = 'vf-cockpit-activite.mjs';
const LANCE = 'if (manque && !e.enVol) demarrer(ctx, e, o, cle, carte, gsig, reprise);';
const G = 'vf-cockpit-activite-gardes.mjs';
const nul = (o) => !o;
const TOUS = {
  tache2: [
    { nom: 'signature-relue-par-requete', f: A, p: [[LANCE, `lancerGitAsync(ctx.root, ['rev-parse', 'HEAD']); ${LANCE}`]], cas: 'cache', rouge: (o) => o.zero !== 0 },
    { nom: 'cache-par-cle-retire', f: A, p: [['if (!b || b.cle !== cle || forcer)', 'if (true)'], ['const manque = cle !== null && (cle !== e.cle || gsig !== e.gsig || reprise);', 'const manque = cle !== null;']], cas: 'cache', rouge: (o) => o.zero !== 0 },
    { nom: 'mono-vol-retire', f: A, p: [['manque && !e.enVol', 'manque'], ['monoVol(cleVol(ctx.root), () => rafraichir(ctx.root, e, o, cle, carte, gsig, forcer))', 'rafraichir(ctx.root, e, o, cle, carte, gsig, forcer)']], cas: 'cache', rouge: (o) => o.unLog !== 1 },
    { nom: 'calcul-synchrone-dans-la-requete', f: A, p: [[LANCE, 'if (manque && !e.enVol) { demarrer(ctx, e, o, cle, carte, gsig); Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 1500); }']], cas: 'cache', rouge: (o) => !o.rapide || o.ecartMax > 250 },
    { nom: 'chemin-comme-cle-d-objet', f: A, p: [['gardes: gd.liste, estGarde', 'gardes: Object.fromEntries(gd.liste), estGarde']], cas: 'cles', rouge: (o) => o.statut !== 200 },
    { nom: 'source-arbres-non-fusionnee', f: A, p: [['...(ag ? ag.collisions : [])', "...(ag ? ag.collisions.filter((x) => x[1] !== 'arbres') : [])"]], cas: 'assemblage', rouge: (o) => !o.sources.includes('arbres') },
    { nom: 'worktree-verifie-compte-hors-lab', f: A, p: [['verifies: autres.filter(', 'verifies: [], dechet: autres.filter(']], cas: 'assemblage', rouge: (o) => o.horsLab !== '1,true,false' },
    { nom: 'null-traite-comme-vide', f: A, p: [["const LECTURE = { etat: 'en-lecture' };", "const LECTURE = { etat: 'vide', fenetre: {}, chauds: [], couplage: [], paliers: 1 };"]], cas: 'lecture', rouge: (o) => !o.lecture.startsWith('en-lecture') },
    { nom: 'tronque-ignore', f: A, p: [['friseTronque: !!frise && frise.tronque === true,', 'friseTronque: false,']], cas: 'tronque', rouge: (o) => !o.tronque.startsWith('tronque') },
    { nom: 'cibles-tronque-ignore', f: A, p: [['const nbCoupees = voies.slice(0, VOIES_MAX).filter((v) => v && v.cibles && v.cibles.tronque === true).length;', 'const nbCoupees = 0;']], cas: 'coupees', rouge: (o) => !o.coupees.startsWith('1,1,') },
    { nom: 'cibles-entieres-d-une-voie-tronquee-non-jointes', f: A, p: [['const lues = voies;', 'const lues = voies.filter((v) => !(v && v.cibles && v.cibles.tronque === true));']], cas: 'coupees', rouge: (o) => o.jointes !== '[["src/a.js",2]]' },
    { nom: 'exception-d-un-module-non-contenue', f: A, p: [['const essai = (f, repli) => { try { return f(); } catch { return repli; } };', 'const essai = (f, repli) => f();']], cas: 'degrade', rouge: (o) => !o.exception.startsWith('indisponible,true,ok,ok,ok') },
    { nom: 'gardes-sans-cession', f: G, p: [['if (Date.now() - debut >= budget) { await new Promise((ok) => setImmediate(ok)); debut = Date.now(); }', 'void budget;']], cas: 'gel', rouge: (o) => o.ecartMax > 250 },
    { nom: 'gardes-sans-plafond', f: G, p: [["if (r.ctx.globs.size * fichiers.length > (opts.plafond ?? PLAFOND_TRAVAIL)) return vide('tronque');", '']], cas: 'gelPlafond', rouge: (o) => !o.gardes.startsWith('tronque,') },
    { nom: 'noms-par-tuple-non-bornes', f: A, p: [['[c, s, n.slice(0, NOMS_MAX), typeof v', '[c, s, n, typeof v']], cas: 'octets', rouge: (o) => o.maxNoms !== 10 },
    { nom: 'serialisation-a-chaque-requete', f: A, p: [['    if (!c) {', '    if (true) {']], cas: 'octets', rouge: (o) => o.stringify !== 0 },
    { nom: 'controle-vide', f: A, p: [['controle: squelette(corps)', 'controle: {}']], cas: 'octets', rouge: (o) => !o.controle.startsWith('true,') },
    { nom: 'controle-integral', f: A, p: [['controle: squelette(corps)', 'controle: corps']], cas: 'octets', rouge: (o) => !o.controle.endsWith(',true') },
    { nom: 'plafond-d-octets-retire', f: A, p: [['if (brut.length > maxOctets)', 'if (false)']], cas: 'octets', rouge: (o) => o.reduit !== 'true,true,true' },
    { nom: 'reprise-retiree', f: A, p: [['const reprise = e.echecA != null && o.horloge() - e.echecA >= o.retryMs;', 'const reprise = false;']], cas: 'reprise', rouge: (o) => o.reprise !== 'ok,ok,pret' },
    { nom: 'reprise-sans-delai', f: A, p: [['o.horloge() - e.echecA >= o.retryMs;', 'o.horloge() - e.echecA >= 0;']], cas: 'reprise', rouge: (o) => o.calme !== 0 || !o.unSeul },
    { nom: 'contexte-des-gardes-relu-a-chaque-graphe', f: A, p: [['b.gctx ??= await', 'b.gctx = await']], cas: 'cache', rouge: (o) => o.graphe0 !== 0 },
    { nom: 'ls-files-hors-du-path-espionne', f: G, p: [["await lancerGitAsync(lab, ['ls-files', '-z'], { fin, maxBuffer: 64 << 20 })", "await lancerGitAsync(lab, ['ls-files', '-z'], { fin, maxBuffer: 64 << 20, binaire: '/usr/bin/git' })"]], cas: 'cache', rouge: (o) => o.lsfiles !== true },
    { nom: 'borne-de-la-reponse-retiree', f: A, p: [['const liste = t.slice(0, o.max);', 'const liste = t.slice(0);']], cas: 'bornes', rouge: (o) => !o.bornes.startsWith('500,') },
  ],
};
let ko = 0;
for (const m of TOUS[liste]) {
  const dst = path.join(work, 'mut', m.nom);
  const a = spawnSync(process.execPath, [path.join(aux, 'mut.mjs'), scripts, dst, m.f, ...m.p.flat()], { encoding: 'utf8' });
  if (a.status !== 0) { console.log(`❌ FAIL — mutant ${m.nom} invalide : ${a.stderr.trim()}`); ko++; continue; }
  const c = spawnSync(process.execPath, [path.join(aux, 'cas.mjs'), dst, m.cas, work], { encoding: 'utf8', timeout: 120000 });
  let o = null; try { o = JSON.parse(c.stdout.trim().split('\n').pop()); } catch { /* plantage : jamais un rouge */ }
  if (o && o.erreur) { console.log(`❌ FAIL — mutant ${m.nom} : le cas ${m.cas} a levé (${o.erreur}), jamais un rouge`); ko++; continue; }
  if (!o) { console.log(`❌ FAIL — mutant ${m.nom} : le cas ${m.cas} n'a rendu aucun verdict (plantage, jamais un rouge) : ${(c.stderr || '').slice(0, 200)}`); ko++; continue; }
  if (m.rouge(o)) console.log(`MUTANT-ROUGE — ${m.nom}`); else { console.log(`❌ FAIL — mutant ${m.nom} : le cas ${m.cas} reste vert`); ko++; }
}
process.exit(ko ? 1 : 0);
JS
node "$AUX/mutants.mjs" "$SCRIPTS" "$WORK" "$AUX" tache2 > "$WORK/mut2.out" 2>&1; MUT2_RC=$?
cat "$WORK/mut2.out"; NM=$((NM + $(grep -c '^MUTANT-ROUGE' "$WORK/mut2.out")))
ok M2 "les vingt-quatre mutants de cas rougissent chacun pour sa raison (aucun plantage pris pour un rouge)" "$MUT2_RC|$(grep -c '^MUTANT-ROUGE' "$WORK/mut2.out")" "0|24"
M="$(mutant lecture-propre-du-lab vf-cockpit-activite.mjs "export const routeActivite" "import fs from 'node:fs';
const _lab = (c) => fs.readdirSync(c.root);
export const routeActivite")"
[ "$(grep -c -E "$PAT_R12" "$M/vf-cockpit-activite.mjs" || true)" = "0" ] || rouge "lecture-propre-du-lab"
M="$(mutant chemin-decode vf-cockpit-activite.mjs "export const routeActivite" "const _d = (c) => decodeURIComponent(c);
export const routeActivite")"
[ "$(grep -c -E "$PAT_R12" "$M/vf-cockpit-activite.mjs" || true)" = "0" ] || rouge "chemin-decode"
# audit F5 : mutants rougissant par la PROPRIÉTÉ (l'import ou l'accès, sous une forme que les grep d'origine ne cherchent pas)
prop_mutant() { # prop_mutant <nom> <ancre> <remplacement>
  local d; d="$(mutant "$1" vf-cockpit-activite.mjs "$2" "$3")"
  [ "$(node "$AUX/prop.mjs" "$d/vf-cockpit-activite.mjs")" != "aucune" ] && rouge "$1" || { echo "❌ FAIL — mutant $1 : la propriété reste vraie"; echo "BILAN : $NB PASS, $((NF+1)) FAIL"; exit 1; }
}
prop_mutant import-fs-sans-prefixe "export const routeActivite" "import { readFileSync } from 'fs';
export const routeActivite"
prop_mutant import-dynamique-de-fs-promises "export const routeActivite" "const _lire = () => import('node:fs/promises');
export const routeActivite"
prop_mutant import-d-un-controle-d-acces "import { reponse } from './vf-cockpit-routes.mjs';" "import { reponse, controlerAcces } from './vf-cockpit-routes.mjs';"
prop_mutant lecture-d-un-en-tete "export const routeActivite" "const _h = (c) => c.req.headers;
export const routeActivite"

echo "=== X1-X3 — l'objet d'activité ne sort jamais par l'export autonome (A25), avec son témoin positif ==="
# marqueur unique par exécution (aléatoire, jamais un littéral du dépôt) : nom de la branche du lab, donc d'une collision de branches de /api/vf/activite
MQ="MQ-$(node -e 'console.log(require("crypto").randomBytes(6).toString("hex"))')"
XLAB="$WORK/xlab"; XWT="$WORK/xwt"; XOUT="$XLAB/.vibeflow/cockpit"
node "$TESTS/frise-labo.mjs" lab "$XLAB"
git -C "$XLAB" checkout -q -b "$MQ"
git -C "$XLAB" worktree add -q -b autre "$XWT"
printf '// worktree\n' >> "$XWT/src/a.js"; git -C "$XWT" -c user.email=t@t -c user.name=t commit -q -a -m wt
printf '// lab\n' >> "$XLAB/src/a.js"; git -C "$XLAB" -c user.email=t@t -c user.name=t commit -q -a -m lab
node "$SCRIPTS/vf-cockpit-build.mjs" "$XLAB" --quiet > "$WORK/build-x.out" 2>&1 || { echo "❌ FAIL — X0 : assemblage du lab X"; cat "$WORK/build-x.out"; echo "BILAN : $NB PASS, $((NF+1)) FAIL"; exit 1; }
cockpit_lancer "$XLAB"
cat > "$AUX/jeton.mjs" <<'JS'
// jeton.mjs <port> <chemin> : jeton lu dans l'objet serveur injecté dans la page servie
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
XTOK="$(node "$AUX/jeton.mjs" "$VF_PORT" /index.html)"
nb() { grep -c -F "$1" "$2" 2>/dev/null || true; }
activite_pret() { cockpit_get /api/vf/activite > "$WORK/x-act.json" 2> /dev/null; [ "$(jf "$WORK/x-act.json" 'j.calcul==="pret"&&j.branches.etat==="ok"')" = true ]; }
attendre 60 activite_pret
ok X0 "témoins de présence : le marqueur est dans la réponse de /api/vf/activite (collision de branches) ET dans graph.json de la sortie (en-tête git du lab) : un export qui ne retirerait rien le porterait" \
  "$([ "$(nb "$MQ" "$WORK/x-act.json")" -ge 1 ] && echo act || echo sans-act)|$([ "$(nb "$MQ" "$XOUT/graph.json")" -ge 1 ] && echo graphe || echo sans-graphe)" "act|graphe"
exporter_cli() { rm -f "$WORK/$1"; cockpit_exporter "$XLAB" "$WORK/$1" --include flows,notes,recent,health > "$WORK/$1.log" 2>&1; }
exporter_route() { rm -f "$WORK/$1"; GRAPHE_METHODE=POST GRAPHE_CORPS='{"include":["flows","notes","recent","health"]}' gc get "$VF_PORT" /api/export "$XTOK" "" "Content-Type=application/json" > "$WORK/$1.rep"
  node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));require("fs").writeFileSync(process.argv[2],j.corps||"")' "$WORK/$1.rep" "$WORK/$1"; }
exporter_cli x1.html; exporter_route x2.html
ok X1 "l'export autonome (ligne de commande ET route /api/export) ne contient le marqueur NULLE PART ; témoin : les deux exports existent et portent le graphe" \
  "$([ "$(nb VF_COCKPIT "$WORK/x1.html")" -ge 1 ] && echo graphe || echo vide)|$([ "$(nb VF_COCKPIT "$WORK/x2.html")" -ge 1 ] && echo graphe || echo vide)|$(nb "$MQ" "$WORK/x1.html")|$(nb "$MQ" "$WORK/x2.html")" "graphe|graphe|0|0"
# X3 : mutant — l'export garde l'en-tête git du lab (vfGit, où vit le nom de la branche) : le marqueur sort
unset COCKPIT_MODULE
cockpit_module_muter export-garde-vfgit serve.mjs 's|(({ vfTouch, vfGit, ...m }) => m)(g.meta)|g.meta|' > "$WORK/x3-muter.out" 2>&1; X3_RC=$?
rm -f "$WORK/x3.html"; cockpit_exporter "$XLAB" "$WORK/x3.html" --include flows,notes,recent,health > "$WORK/x3.log" 2>&1; unset COCKPIT_MODULE
ok X3 "mutant « l'export garde ce qu'il retire » (copie du module, ancre du retrait de vfGit) : le marqueur sort de l'export, X1 rougit pour la bonne raison (l'export existe et porte le graphe)" \
  "$X3_RC|$([ "$(nb VF_COCKPIT "$WORK/x3.html")" -ge 1 ] && echo graphe || echo vide)|$([ "$(nb "$MQ" "$WORK/x3.html")" -ge 1 ] && echo marqueur-present || echo absent)" "0|graphe|marqueur-present"
rouge "objet-d-activite-injecte-dans-l-export"
# X2 : témoin positif — le même marqueur, cette fois dans une donnée exportée légitime (le nom d'un fichier du graphe), apparaît dans l'export
printf '// %s : témoin positif\nexport const t = 1;\n' "$MQ" > "$XLAB/src/$MQ.js"
git -C "$XLAB" add -A && git -C "$XLAB" -c user.email=t@t -c user.name=t commit -q -m temoin
node "$SCRIPTS/vf-cockpit-build.mjs" "$XLAB" --quiet > "$WORK/build-x2.out" 2>&1 || { echo "❌ FAIL — X2 : réassemblage du lab X"; cat "$WORK/build-x2.out"; echo "BILAN : $NB PASS, $((NF+1)) FAIL"; exit 1; }
exporter_cli x4.html
ok X2 "témoin positif : le même marqueur, présent dans une donnée exportée légitime (un fichier du lab décrit par la page Code), apparaît dans l'export : sans lui X1 ne prouve rien" "$([ "$(nb "$MQ" "$WORK/x4.html")" -ge 1 ] && echo present || echo absent)" "present"
ok X4 "le module serve.mjs n'importe ni ne nomme l'activité : aucune voie de l'objet vers l'export" "$(grep -c -i 'activite' "$SCRIPTS/../skills/cockpit-moteur/assets/serve.mjs" || true)" "0"
cockpit_arreter

# --- FIN-SECTIONS ---
vf_hyg_assert
echo "MUTANTS : $NM rouges"
echo "BILAN : $NB PASS, $NF FAIL"
[ "$NF" -eq 0 ]
