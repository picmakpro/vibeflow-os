#!/usr/bin/env bash
# test-cockpit-activite-prevues.sh — Phase 75, plan 75-06 (ACTV-11 ; P75-D-18, A25, A27, A34, A37, A54, P79-D-32) : les cartes « prévues » du graphe Code.
#   V1-V4 un plan non fait, un fichier absent, une carte `st: 'prevu'` rattachée comme le moteur le fait, sans toucher au scan ni aux stats
#   V5-V8 chemins hostiles comptés, lab sous-dossier d'un dépôt, plans multiples, fraîcheur à l'assemblage · V9 export sans les prévues (témoin positif)
#   V10 annotateur inscrit sous le nom `prevues`, exercé seul · V-N2N le rattachement passe par `compileGlob` corrigé (79-21), linéaire
# Régime allégé (mandat commun de la Phase 75) : pas de mutants dans cette suite. Fixtures dans mktemp, HOME jetable, isolation git.
# Sortie : « PASS — <id> : … », « ❌ FAIL — <id> : … », « BILAN : n PASS, m FAIL » ; code non nul au premier FAIL (TOUT=1 : tout rejouer, trace des rouges).
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MOTEUR="$SCRIPTS/../skills/cockpit-moteur"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
NB=0; NF=0
ok() { # ok <id> <texte> <obtenu> <attendu>
  if [ "$3" = "$4" ]; then echo "PASS — $1 : $2"; NB=$((NB+1))
  else echo "❌ FAIL — $1 : $2"; echo "     attendu: [${4:0:400}]"; echo "     obtenu:  [${3:0:400}]"; NF=$((NF+1)); [ -n "${TOUT:-}" ] || { echo "BILAN : $NB PASS, $NF FAIL"; exit 1; }; fi
}
assert_eq() { ok "${1%% — *}" "${1#* — }" "$2" "$3"; } # forme attendue par hygiene.sh (vf_hyg_assert)

# ---------- aides node ----------
cat > "$AUX/prev.mjs" <<'JS'
// prev.mjs <scripts> <spec.json> : annoterPrevues(g, ctx) sur des entrées de la spec ; { absent: true } si le module manque
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, specF] = process.argv;
let M; try { M = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-activite-prevues.mjs')).href); } catch { console.log(JSON.stringify({ absent: true })); process.exit(0); }
const s = JSON.parse(fs.readFileSync(specF, 'utf8')), g = { files: s.files || [], nodes: s.nodes || [], meta: {} };
M.annoterPrevues(g, { lab: s.lab, project: { files: s.plans }, architecture: s.arch, ...(s.maintenant ? { maintenant: new Date(s.maintenant) } : {}) });
console.log(JSON.stringify({ prevus: g.files.filter((f) => f.st === 'prevu'), autres: g.files.filter((f) => f.st !== 'prevu').length, nodes: g.nodes, meta: g.meta }));
JS
cat > "$AUX/gen.mjs" <<'JS'
// gen.mjs <cas> <lab> <hors> <spec.json> : specs des cas hostiles (V5) et du plafond de 500 cartes
import fs from 'node:fs';
const [, , cas, lab, hors, out] = process.argv;
const plan = (id, touched, extra = {}) => ({ p: `.planning/phases/01-x/${id}-PLAN.md`, st: 'todo', touched, ...extra });
const arch = { nodes: [{ id: 'd-src', label: 'src', kind: 'library', paths: ['src/**'] }, { id: 'racine', label: 'Racine', kind: 'config', paths: ['*'] }] };
let plans;
if (cas === 'hostiles') plans = [plan('01-01', ['/etc/passwd', '../evil.mjs', 'a\u0000b.mjs', 'a\nb.mjs', 'a b.mjs', 'x'.repeat(5000) + '.mjs', '.planning/phases/x/y.md', 'lien/neuf.mjs', 'src/ok.mjs'])];
else if (cas === 'ignores') plans = [plan('01-01', ['src/ok.mjs'], { touchedIgnores: 3 })];
else plans = Array.from({ length: 501 }, (_, i) => plan(`01-${String(i).padStart(3, '0')}`, [`src/f${i}.mjs`]));
fs.writeFileSync(out, JSON.stringify({ lab, hors, plans, arch }));
JS
cat > "$AUX/an.mjs" <<'JS'
// an.mjs <scripts> <cas> <lab> : assemblage en processus. noms | seul (table réduite à `prevues`) | sans (table sans `prevues`)
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, cas, lab] = process.argv;
const M = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-build.mjs')).href);
const noms = M.ANNOTATEURS.map((l) => l[0]);
if (cas === 'noms') console.log(JSON.stringify(noms));
else { M.assembler({ lab, quiet: true, scriptsDir: scripts, annotateurs: M.ANNOTATEURS.filter((l) => (l[0] === 'prevues') === (cas === 'seul')) }); console.log('assemble'); }
JS
cat > "$AUX/exp.mjs" <<'JS'
// exp.mjs <export.html> : les données de l'export (même lecture que serve.mjs), jamais un grep sur la page (ses scripts nomment les champs)
import fs from 'node:fs';
const t = fs.readFileSync(process.argv[2], 'utf8'), S = '<script>window.VF_COCKPIT = ', a = t.indexOf(S), b = t.indexOf(';</script>', a);
if (a < 0 || b < 0) { console.log(JSON.stringify({ illisible: true })); process.exit(0); }
const g = JSON.parse(t.slice(a + S.length, b));
console.log(JSON.stringify({ prevus: g.files.filter((f) => f.st === 'prevu' || /ZMARQ-prevu|apres\.mjs/.test(f.p)).length, cles: ['vfPrevuAt', 'prevusIgnores'].filter((k) => k in g.meta), reel: g.files.some((f) => f.p === 'src/ZMARQ-reel.mjs'), fichiers: g.files.length }));
JS
cat > "$AUX/equiv.mjs" <<'JS'
// equiv.mjs <moteur> <scripts> <graph.json> <architecture.json> : le nœud du graphe du moteur égale celui de la règle extraite, fichier par fichier
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , moteur, scripts, graphF, archF] = process.argv;
let C; try { C = await import(pathToFileURL(path.join(moteur, 'scripts', 'lib', 'common.mjs')).href); } catch { C = {}; }
const g = JSON.parse(fs.readFileSync(graphF, 'utf8')), arch = JSON.parse(fs.readFileSync(archF, 'utf8'));
if (typeof C.regleDeNoeuds !== 'function' || typeof C.rattacher !== 'function') { console.log(JSON.stringify({ absent: true })); process.exit(0); }
const regle = C.regleDeNoeuds(arch.nodes), ecarts = [];
for (const f of g.files) { const r = C.rattacher(regle, f.p).id; if (r !== f.n) ecarts.push([f.p, f.n, r]); }
console.log(JSON.stringify({ fichiers: g.files.length, ecarts, repartition: Object.fromEntries([...new Set(g.files.map((f) => f.n))].sort().map((n) => [n, g.files.filter((f) => f.n === n).length])) }));
JS
cat > "$AUX/n2n.mjs" <<'JS'
// n2n.mjs <moteur> : compileGlob de lib/common.mjs, N = 20 000 puis 40 000, médiane de cinq ; { t1, t2 } en ms
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const { compileGlob } = await import(pathToFileURL(path.join(process.argv[2], 'scripts', 'lib', 'common.mjs')).href);
const med = (n) => { const t = []; for (let i = 0; i < 5; i++) { const g = compileGlob('**/a/**/b/**/*.js'), s = 'a/'.repeat(n) + 'x', a = process.hrtime.bigint(); g.test(s); t.push(Number(process.hrtime.bigint() - a) / 1e6); } return t.sort((x, y) => x - y)[2]; };
const C = await import(pathToFileURL(path.join(process.argv[2], 'scripts', 'lib', 'common.mjs')).href);
console.log(JSON.stringify({ t1: med(20000), t2: med(40000), regle: typeof C.matchersDe === 'function' && C.matchersDe.toString().includes('compileGlob') }));
JS
j() { node -e "const j=JSON.parse(require('fs').readFileSync(0,'utf8'));const v=new Function('j','return ('+process.argv[1]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1"; }
jf() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=new Function('j','return ('+process.argv[2]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" "$2" 2>/dev/null || echo illisible; }
prev() { node "$AUX/prev.mjs" "$SCRIPTS" "$1" 2>/dev/null | tail -1; }
asm() { node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || { echo "❌ FAIL — assemblage de $1"; cat "$WORK/build.out"; echo "BILAN : $NB PASS, $((NF+1)) FAIL"; exit 1; }; }
commit() { git -C "$1" add -A && git -C "$1" -c user.email=t@t -c user.name=t commit -q -m "${2:-init}"; }

# ---------- lab neutre : un plan non fait (cartes attendues), un plan fait, des chemins déjà présents ----------
mklab() { local L="$1" P="$1/.planning/phases"; mkdir -p "$L/src" "$L/docs" "$P/01-socle" "$P/02-fini"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf 'import { u } from "./util.js";\nconsole.log(u());\n' > "$L/src/app.js"
  printf '# Note\n\nUne note.\n' > "$L/docs/note.md"; printf 'export const reel = 1;\n' > "$L/src/ZMARQ-reel.mjs"
  printf 'export const i = 1;\n' > "$L/ignore-moi.mjs"; printf 'ignore-moi.mjs\n' > "$L/.gitignore"
  printf -- '- [ ] **Phase 1: Socle** - en cours\n- [x] **Phase 2: Fini** - fait\n' > "$L/.planning/ROADMAP.md"
  printf -- '---\nphase: 1\nplan: "01"\nwave: 1\nfiles_modified:\n  - src/nouveau.mjs\n  - src/util.js\n  - docs/note.md\n  - ignore-moi.mjs\n  - src/ZMARQ-prevu.mjs\n---\n<objective>Faire le socle</objective>\n' > "$P/01-socle/01-01-PLAN.md"
  printf -- '---\nphase: 2\nplan: "01"\nwave: 1\nfiles_modified: [src/fait-absent.mjs]\n---\n<objective>Déjà fait</objective>\n' > "$P/02-fini/02-01-PLAN.md"; echo ok > "$P/02-fini/02-01-SUMMARY.md"
  git -C "$L" init -q && commit "$L"; }

echo "=== V1 — un plan non fait, un fichier absent : la carte prévue est dans graph.json ==="
L1="$WORK/lab1"; mklab "$L1"; asm "$L1"; G1="$L1/.vibeflow/cockpit/graph.json"
ok V1 "graph.json porte les deux fichiers absents du plan non fait, triés, en cartes st:'prevu'" "$(jf "$G1" 'JSON.stringify(j.files.filter(f=>f.st==="prevu").map(f=>f.p))')" '["src/ZMARQ-prevu.mjs","src/nouveau.mjs"]'
ok V1b "forme de l'élément : p, n, r, l:'prevu', loc 0, name, d, st:'prevu', prevuPar ; ni ouvrir ni taille ni description automatique" \
  "$(jf "$G1" '(f=>JSON.stringify({p:f.p,n:f.n,r:f.r,l:f.l,loc:f.loc,name:f.name,d:f.d,st:f.st,prevuPar:f.prevuPar,cles:Object.keys(f).sort().join()}))(j.files.find(x=>x.p==="src/nouveau.mjs"))')" \
  '{"p":"src/nouveau.mjs","n":"d-src","r":".","l":"prevu","loc":0,"name":"nouveau.mjs","d":"Créé par le plan 01-01","st":"prevu","prevuPar":["01-01"],"cles":"d,l,loc,n,name,p,prevuPar,r,st"}'
ok V1c "meta : vfPrevuAt (ISO) et prevusIgnores (0) posés ; 75-05 lit meta.prevusIgnores" "$(jf "$G1" '[/^\d{4}-\d\d-\d\dT[\d:.]+Z$/.test(j.meta.vfPrevuAt),j.meta.prevusIgnores].join()')" "true,0"

echo "=== V2 — exclusions : plan fait, présent au scan, présent sous le lab (ignoré par git, doc) ==="
ok V2 "plan fait (src/fait-absent.mjs), fichier du scan (src/util.js), doc présent mais hors graphe (docs/note.md), fichier ignoré par git mais présent (ignore-moi.mjs) : aucune carte" \
  "$(jf "$G1" 'j.files.filter(f=>["src/fait-absent.mjs","src/util.js","docs/note.md","ignore-moi.mjs"].includes(f.p)&&f.st==="prevu").length')" "0"
ok V2b "le fichier réel de src/util.js reste une carte du moteur (sans st) ; le plan lui-même n'est pas une carte" "$(jf "$G1" 'j.files.filter(f=>f.p==="src/util.js"&&f.st===undefined).length+"|"+j.files.filter(f=>f.p.startsWith(".planning/")).length')" "1|0"

echo "=== V3 — rattachement : la règle du moteur, extraite UNE fois ==="
# fixture à globs imbriqués : héritage de `exclude`, parent/enfant, égalité de spécificité ; le moteur et l'annotateur doivent donner le même nœud partout
EN="$WORK/eng"; mkdir -p "$EN/root/a/b/c/d" "$EN/root/a/t" "$EN/root/w" "$EN/root/z" "$EN/out/.cache"
for f in a/x.js a/b/y.js a/b/c/z.js a/b/c/d/deep.js a/t/q.js w/k.js w/k2.js z/m.js loose.js; do printf 'export const v = 1;\n' > "$EN/root/$f"; done
cat > "$EN/out/architecture.json" <<'JSON'
{ "project": { "name": "equiv" }, "nodes": [
  { "id": "a", "label": "A", "kind": "library", "paths": ["a/**"], "exclude": ["a/b/c/**", "**/t/**"] },
  { "id": "b", "label": "B", "kind": "library", "parent": "a", "paths": ["a/b/**"] },
  { "id": "c", "label": "C", "kind": "library", "parent": "b", "paths": ["a/b/c/*.js", "a/b/c/**"] },
  { "id": "w", "label": "W", "kind": "service", "paths": ["w/**"] },
  { "id": "wk", "label": "WK", "kind": "service", "parent": "w", "paths": ["w/k*.js"] },
  { "id": "wk2", "label": "WK2", "kind": "service", "parent": "w", "paths": ["w/k?.js"] },
  { "id": "zz", "label": "Z", "kind": "library", "paths": ["z/m.js"] } ] }
JSON
node "$MOTEUR/scripts/scan.mjs" "$EN/root" --out "$EN/out/.cache/scan.json" > "$WORK/eng-scan.out" 2>&1 || { cat "$WORK/eng-scan.out"; }
node "$MOTEUR/scripts/build.mjs" "$EN/root" --arch "$EN/out/architecture.json" --scan "$EN/out/.cache/scan.json" --out "$EN/out" --no-claude-md > "$WORK/eng-build.out" 2>&1 || { cat "$WORK/eng-build.out"; }
EQ="$(node "$AUX/equiv.mjs" "$MOTEUR" "$SCRIPTS" "$EN/out/graph.json" "$EN/out/architecture.json" 2>/dev/null | tail -1)"
ok V3 "équivalence : pour chacun des 9 fichiers réels, la règle extraite rend le nœud du moteur (zéro divergence)" "$(printf '%s' "$EQ" | j 'j.absent?"absent":j.fichiers+" "+JSON.stringify(j.ecarts)')" "9 []"
ok V3b "la fixture est discriminante : l'exclusion héritée envoie a/b/c/z.js et a/b/c/d/deep.js hors de a, b et c ; a/t/q.js hors de a" \
  "$(printf '%s' "$EQ" | j 'j.absent?"absent":JSON.stringify(j.repartition)')" '{"a":1,"b":1,"unassigned":4,"wk":2,"zz":1}'
cat > "$WORK/s3.json" <<JSON
{ "lab": "$EN/root", "arch": $(cat "$EN/out/architecture.json"), "nodes": [], "plans": [ { "p": ".planning/phases/9-x/9-01-PLAN.md", "st": "todo",
  "touched": ["a/b/neuf.js", "a/b/c/neuf.js", "zz/neuf.js", "w/k9.js", "a/x2.js"] } ] }
JSON
P3="$(prev "$WORK/s3.json")"
ok V3c "cartes prévues : a/b/neuf.js → b ; a/b/c/neuf.js → non assignés (exclusion héritée) ; zz/neuf.js → non assignés ; w/k9.js → wk ; a/x2.js → a" \
  "$(printf '%s' "$P3" | j 'j.absent?"absent":j.prevus.map(f=>f.p+">"+f.n).join(" ")')" "a/b/c/neuf.js>unassigned a/b/neuf.js>b a/x2.js>a w/k9.js>wk zz/neuf.js>unassigned"
ok V3d "un nœud « non assignés » (kind misc, aucune statistique de fichier) est ajouté seulement s'il manque, jamais un nœud du moteur modifié" \
  "$(printf '%s' "$P3" | j 'j.absent?"absent":j.nodes.map(n=>n.id+":"+n.stats.files).join()')" "unassigned:0"

echo "=== V4 — le scan n'est pas modifié, les statistiques de nœud du moteur non plus ==="
L4="$WORK/lab4"; mklab "$L4"; node "$AUX/an.mjs" "$SCRIPTS" sans "$L4" > /dev/null 2>&1; S4A="$(jf "$L4/.vibeflow/cockpit/graph.json" 'JSON.stringify(j.nodes.map(n=>[n.id,n.stats]))')"
node "$AUX/an.mjs" "$SCRIPTS" noms "$L4" > /dev/null 2>&1; asm "$L4"; S4B="$(jf "$L4/.vibeflow/cockpit/graph.json" 'JSON.stringify(j.nodes.map(n=>[n.id,n.stats]))')"
ok V4 "stats de nœud identiques avec et sans la table complète (Santé ne compte aucune prévue « inutilisée ») ; témoin : le graphe complet porte bien ses cartes prévues" "$([ "$S4A" = "$S4B" ] && echo identiques || echo differentes)|$(jf "$L4/.vibeflow/cockpit/graph.json" 'j.files.filter(f=>f.st==="prevu").length')" "identiques|2"
ok V4b ".cache/scan.json ne contient aucun chemin prévu ; témoin : il contient un fichier réel du lab" "$(jf "$L4/.vibeflow/cockpit/.cache/scan.json" '[j.files.some(f=>f.path==="src/nouveau.mjs"||f.path==="src/ZMARQ-prevu.mjs"),j.files.some(f=>f.path==="src/ZMARQ-reel.mjs")].join()')" "false,true"

vf_hyg_assert
echo "BILAN : $NB PASS, $NF FAIL"
[ "$NF" -eq 0 ] && [ "$NB" -gt 0 ]
