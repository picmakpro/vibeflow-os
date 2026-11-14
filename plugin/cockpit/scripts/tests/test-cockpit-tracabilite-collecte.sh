#!/usr/bin/env bash
# test-cockpit-tracabilite-collecte.sh — la traçabilité lue dans la collecte et projetée sur cockpit-project@1 (TRAC-10, TRAC-01, 03, 04, 05 ; P76-D-11, D-12, D-16, D-31)
#   T9.1-T9.3 de la collecte au graphe : champs posés, vue de phase identique à celle du harnais de 76-01, option opt-in
#   T9.4-T9.6 registres par nœud de phase, fichier au-delà de MAX_LECTURE, panne injectée sans effet sur le graphe
#   T9.9-T9.11 textes projetés sans chemin du poste, citations du ledger, équivalence des deux porteurs des exigences (P80-C76-6)
#   T9.7-T9.8 contrat des champs facultatifs, poids et durée mesurés
# Labs fabriqués dans mktemp (aucun chemin du poste dans les fichiers écrits). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$SCRIPTS/../../.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 — attendu: [$3] obtenu: [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
# j.mjs <fichier> <expression sur j> : « absent » si l'expression échoue ou rend undefined, « illisible » si le JSON ne se lit pas
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[3] + ')')(j); } catch { console.log('absent'); process.exit(0); }
console.log(v === undefined ? 'absent' : typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
# col.mjs <scripts> <lab> <mode> [cle] : lecture du lab par les modules de <scripts>
#   modes : graphe (le graphe Projet réel) · plan (option trace de readPlanning) · vue <cle> (vue de phase réelle contre celle du harnais de 76-01)
#           equiv (meta.vf.trace contre les fichiers sources de la phase 1, lus à part) · poids (octets et durées, sur le lab donné)
cat > "$AUX/col.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, mode, cle] = process.argv;
const imp = (n) => import(pathToFileURL(path.join(scripts, n)).href);
const tri = (v) => (Array.isArray(v) ? v.map(tri) : v && typeof v === 'object' ? Object.fromEntries(Object.keys(v).sort().map((k) => [k, tri(v[k])])) : v);
const sans76 = (g) => { for (const n of g.nodes) delete n.trace; delete g.meta.vf.trace; delete g.meta.vf.jalonActif; delete g.meta.vf.registres; return g; };
async function sortie() {
  const { readPlanning, lireConfine, read, lister, fm, list, clip } = await imp('vf-cockpit-planning.mjs');
  const { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
  const racine = fs.realpathSync(lab);
  if (mode === 'plan') {
    const a = readPlanning(racine, undefined, { sansTags: true }), b = readPlanning(racine, undefined, { trace: true, sansTags: true });
    return { sans: a.trace == null, avec: !!(b.trace && Array.isArray(b.trace.exigences) && b.trace.exigences.length > 0) };
  }
  if (mode === 'poids') {
    const t0 = Date.now(); readPlanning(racine, undefined, { sansTags: true }); const t1 = Date.now();
    readPlanning(racine, undefined, { trace: true, sansTags: true }); const t2 = Date.now();
    const g = buildProjectGraph(racine); const apres = Buffer.byteLength(JSON.stringify(g));
    return { avant: Buffer.byteLength(JSON.stringify(sans76(g))), apres, sans: t1 - t0, avec: t2 - t1 };
  }
  const g = buildProjectGraph(racine);
  if (mode === 'graphe') return g;
  if (mode === 'm1') {
    const { vuePhase } = await imp('vf-cockpit-trace-bilans.mjs'); const { vue } = await imp('vf-cockpit-trace-vues.mjs');
    const phases = g.nodes.filter((n) => n.kind === 'phase').map((n) => { const v = vuePhase(g, `${n.ws || ''}|${n.num}`); return { ws: n.ws || '', num: n.num, ids: v.exigences.map((e) => e.id).sort(), total: v.bilan.total }; });
    const vues = {}; for (const c of (cle || '').split(',').filter(Boolean)) { const r = vue({ vue: 'exigence', cle: c, projet: g, modele: null }); vues[c] = r.statut + '/' + (r.corps.erreur || r.corps.etat); }
    return { phases, vues };
  }
  if (mode === 'equiv') { // 76-08 : le nœud « Exigences » est retiré ; l'ancien porteur est remplacé par une lecture INDÉPENDANTE des fichiers sources du lab (cases du REQUIREMENTS, champ requirements des plans)
    const base = path.join(racine, '.planning/workstreams/x'), dir = path.join(base, 'phases/01-un');
    const anc = [...fs.readFileSync(path.join(base, 'REQUIREMENTS.md'), 'utf8').matchAll(/^- \[( |x)\] \*\*([A-Z]+-\d+)\*\*: (.*)$/gm)].map((m) => ({ id: m[2], st: m[1] === 'x' ? 'done' : 'todo', d: m[3] }));
    const nou = g.meta.vf.trace.exigences.filter((e) => e.phase === '1');
    const ph = g.nodes.find((n) => n.id === 'ph-1');
    const plans = g.files.filter((f) => f.n === 'ph-1' && /-PLAN\.md$/.test(f.p)).map((f) => {
      const src = fs.readFileSync(path.join(dir, path.basename(f.p)), 'utf8'), ligne = /^requirements: \[(.*)\]$/m.exec(src);
      const a = ligne ? ligne[1].split(',').map((x) => x.trim()).filter(Boolean).sort() : [];
      const pl = ph.trace.plans.find((x) => x.fichier === f.p);
      return { p: f.p.split('/').pop(), anc: a, nou: pl ? [...pl.exigences].sort() : null };
    });
    return { ids: [anc.map((x) => x.id), nou.map((x) => x.id)],
      coche: anc.length === nou.length && anc.every((x, i) => (nou[i].coche === (x.st === 'done'))),
      libelle: anc.length === nou.length && anc.every((x, i) => x.d === nou[i].libelle || x.d.startsWith(nou[i].libelle) || nou[i].libelle.startsWith(x.d)),
      plans };
  }
  if (mode === 'vue') {
    const { projeterTrace } = await imp('vf-cockpit-trace-collecte.mjs'); const { vuePhase } = await imp('vf-cockpit-trace-bilans.mjs');
    const { lireTrace } = await imp('vf-cockpit-trace-collecte.mjs'); const { planningLayout } = await imp('vf-cockpit-paths.mjs'); const { texte } = await imp('vf-cockpit-formats.mjs');
    const reel = vuePhase(g, cle);
    const g2 = sans76(buildProjectGraph(racine)); const layout = planningLayout(racine);
    const t = lireConfine(racine, () => {
      const P = readPlanning(racine, layout, { sansTags: true });
      const ledgers = layout.compartiments.map((c) => { const f = path.join(c.dir, 'REQUIREMENTS.md'); return { ws: c.ws || '', fichier: P.rel(f), txt: texte(read(f)) }; });
      return lireTrace({ phases: P.phases, phaseDirs: P.phaseDirs, reqs: P.reqs, ledgers, lire: read, lister, rel: P.rel, fm, list });
    });
    const ms = g2.meta.vf.milestones; const m0 = ms.find((m) => m.key === g2.meta.vf.milestone) || ms.find((m) => m.st === 'active') || ms.at(-1);
    projeterTrace(g2, t, { jalonActif: m0 ? m0.id : null, couper: clip });
    const harnais = vuePhase(g2, cle);
    return { identique: JSON.stringify(tri(reel)) === JSON.stringify(tri(harnais)), n: reel ? reel.exigences.length : -1, reel };
  }
  return { erreur: 'mode inconnu' };
}
try { console.log(JSON.stringify(await sortie())); } catch (e) { console.log(JSON.stringify({ erreur: 'echec ' + String(e && e.message).slice(0, 160) })); }
JS
SC="$SCRIPTS"
# C <lab> <mode> [cle] -> chemin du fichier JSON produit (modules lus dans $SC)
C() { local f; f="$WORK/c-$(basename "$SC")-$(basename "$1")-$2-$(printf '%s' "${3:-}" | tr -c 'A-Za-z0-9' _).json"; node "$AUX/col.mjs" "$SC" "$@" > "$f" 2>/dev/null; echo "$f"; }
# mutsub.mjs <fichier> <ancre> <remplacement> : copie jetable modifiée ; « muté » exigé en sortie (ancre introuvable = erreur) ; ancre sans accolade (bash 3.2 développe { a, b } même entre guillemets dans $(…))
cat > "$AUX/mutsub.mjs" <<'JS'
import fs from 'node:fs';
const [, , f, de, vers] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(de)) { console.log('ancre introuvable'); process.exit(1); }
fs.writeFileSync(f, t.split(de).join(vers)); console.log('muté');
JS
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <interface.json> <sortie.json> — clés requises de cockpit-project@1 et clés interdites (liste de cockpit-who@2) à toute profondeur
import fs from 'node:fs';
const [, , ifaceF, outF] = process.argv;
const iface = JSON.parse(fs.readFileSync(ifaceF, 'utf8')); const spec = iface.schemas['vibeflow/cockpit-project@1'];
const interdits = iface.schemas['vibeflow/cockpit-who@2'].interdits; const out = JSON.parse(fs.readFileSync(outF, 'utf8')); const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis)) { if (!(k in out)) errs.push(`clé requise absente : ${k}`); else if (type(out[k]) !== t) errs.push(`type de ${k}`); }
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if (interdits.includes(k)) errs.push(`clé interdite présente : ${k}`); });
for (const n of out.nodes) for (const k of spec.noeud.requis) if (!(k in n)) errs.push(`nœud ${n.id} : clé ${k} absente`);
for (const k of spec.meta.requis) if (!(k in out.meta)) errs.push(`meta.${k} absente`);
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
JS

# --- fabrication des labs (même fabrication que test-cockpit-tracabilite-chaine.sh) ---
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
lab_base() {
  local d="$1" n="$2" b="$1/.planning/workstreams/x" i; mkdir -p "$b"
  { printf '# Roadmap\n\n## Milestones\n\n- 🚧 **v1** - Phases 1-%s (in progress)\n' "$n"
    printf '\n## Phases\n\n'; for i in $(seq 1 "$n"); do printf -- '- [ ] **Phase %s: P%s** - p\n' "$i" "$i"; done; printf '\n'
    for i in $(seq 1 "$n"); do printf '### Phase %s: P%s\n**Goal**: but %s\n**Depends on**: Nothing\n\n' "$i" "$i" "$i"; done; } > "$b/ROADMAP.md"
  printf -- '---\nmilestone: v1\nstatus: executing\ncurrent_phase: 1\n---\n' > "$b/STATE.md"
}
phdir() { echo "$1/.planning/workstreams/x/phases/$2"; }
ledger() { echo "$1/.planning/workstreams/x/REQUIREMENTS.md"; }
mkplan() { local f="$1" r="$2" extra="${3:-}"; mkdir -p "$(dirname "$f")"; { printf -- '---\nphase: x\nplan: "01"\nwave: 1\n'; [ "$r" = "-" ] || printf 'requirements: %s\n' "$r"; [ -n "$extra" ] && printf '%s\n' "$extra"; printf -- '---\n\n<objective>\nobjectif\n</objective>\n'; } > "$f"; }
mksum() { mkdir -p "$(dirname "$1")"; printf -- '---\n%s\n---\n# Summary\n' "$2" > "$1"; }

echo "=== T9.1 à T9.3 — de la collecte au graphe ==="
L1="$WORK/l1"; lab_base "$L1" 2
wr "$(ledger "$L1")" <<'MD'
# Exigences

- [x] **REQ-01**: Première exigence
- [ ] **REQ-02**: Deuxième exigence

| REQ-01 | Phase 1 | Complete |
| REQ-02 | Phase 2 | Pending |
MD
D1="$(phdir "$L1" 01-un)"; mkplan "$D1/01-01-PLAN.md" '[REQ-01]'; mksum "$D1/01-01-SUMMARY.md" 'requirements-completed: REQ-01'
D2="$(phdir "$L1" 02-deux)"; mkplan "$D2/02-01-PLAN.md" '[REQ-02]'
G1="$(C "$L1" graphe)"
assert_eq "T9.1 le nœud ph-1 porte trace.plans[0].exigences avec REQ-01" "$(J "$G1" "j.nodes.find(n=>n.id==='ph-1').trace.plans[0].exigences.includes('REQ-01')")" "true"
assert_eq "T9.1b meta.vf.trace.exigences : REQ-01 rattachée à la phase 1" "$(J "$G1" "j.meta.vf.trace.exigences.find(e=>e.id==='REQ-01').phase")" "1"
assert_eq "T9.1c meta.vf.jalonActif = jalon mis en avant" "$(J "$G1" "j.meta.vf.jalonActif")" "n:ms-v1"
assert_eq "T9.2 vue de phase du vrai graphe = vue du harnais de 76-01 (JSON trié), une exigence" "$(J "$(C "$L1" vue 'x|1')" "j.identique+'/'+j.n")" "true/1"
assert_eq "T9.3 sans l'option aucun champ trace ; avec { trace: true } il est rendu" "$(J "$(C "$L1" plan)" "j.sans+'/'+j.avec")" "true/true"

echo "=== T9.4 — registres par nœud de phase ==="
L4="$WORK/l4"; lab_base "$L4" 1
{ printf -- '- [ ] **Phase 90: P90** - p\n\n### Phase 90: P90\n**Goal**: but 90\n**Depends on**: Nothing\n'; } >> "$L4/.planning/workstreams/x/ROADMAP.md"
wr "$(phdir "$L4" 90-x)/90-CONTEXT.md" <<'MD'
# Contexte

- **P90-D-01** : première définition (ADR-001)
- **D-04** : décision nue
- **P90-D-01** : amendement du même identifiant
MD
wr "$(phdir "$L4" 91-y)/91-CONTEXT.md" <<'MD'
# Contexte

- **P91-D-01** : définition d'une phase absente du ROADMAP
MD
G4="$(C "$L4" graphe)"
assert_eq "T9.4 registre de ph-90 : P90-D-01 amendée (clé ph-90), D-04 nue" "$(J "$G4" "j.meta.vf.registres.find(r=>r.phase==='ph-90').decisions.map(d=>d.id+'/'+d.cle+'/'+d.nue+'/'+d.amendee).join()")" "P90-D-01/P90-D-01:ph-90/false/true,D-04/D-04:ph-90/true/false"
assert_eq "T9.4b un seul registre (rien pour la phase 91 sans nœud)" "$(J "$G4" "j.meta.vf.registres.length")" "1"
assert_eq "T9.4c registresSansPhase compte le CONTEXT de la phase 91" "$(J "$G4" "j.meta.vf.trace.registresSansPhase")" "1"
assert_eq "T9.4d témoin positif : le fichier 91 existe et contient une définition" "$(grep -c 'P91-D-01' "$(phdir "$L4" 91-y)/91-CONTEXT.md")" "1"

echo "=== T9.5 — un fichier au-delà de MAX_LECTURE n'est jamais lu ==="
L5="$WORK/l5"; lab_base "$L5" 1
wr "$(ledger "$L5")" <<'MD'
# Exigences

- [ ] **REQ-01**: lue
- [ ] **REQ-02**: citée par le plan géant

| REQ-01 | Phase 1 | Pending |
| REQ-02 | Phase 1 | Pending |
MD
D5="$(phdir "$L5" 01-un)"; mkplan "$D5/01-01-PLAN.md" '[REQ-01]'
{ printf -- '---\nphase: x\nplan: "02"\nwave: 1\nrequirements: [REQ-02]\n---\n'; head -c 9437184 /dev/zero | tr '\0' 'a'; } > "$D5/01-02-PLAN.md"
head -c 3000 /dev/zero > "$D5/01-02-SUMMARY.md"
V5="$(C "$L5" vue 'x|1')"
assert_eq "T9.5 maillon plan : REQ-02 non lisible, REQ-01 lu" "$(J "$V5" "j.reel.exigences.find(e=>e.id==='REQ-02').maillons.plan.etat+'/'+j.reel.exigences.find(e=>e.id==='REQ-01').maillons.plan.etat")" "non-lisible/lu"
assert_eq "T9.5b témoin positif : le frontmatter du fichier géant cite bien REQ-02" "$(head -c 400 "$D5/01-02-PLAN.md" | grep -c 'REQ-02')" "1"

echo "=== T9.6 — une panne de la lecture de traçabilité ne casse jamais le graphe ==="
MUT="$WORK/mut"; mkdir -p "$MUT"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$MUT/"
assert_eq "T9.6a copie jetable : lireTrace lève (sortie « muté » exigée)" "$(node "$AUX/mutsub.mjs" "$MUT/vf-cockpit-trace-collecte.mjs" "const traces = new Map(), vivantes = [];" "throw new Error('panne injectée'); const traces = new Map(), vivantes = [];")" "muté"
SC="$MUT"; G6="$(C "$L1" graphe)"; SC="$SCRIPTS"
assert_eq "T9.6 sous panne : les deux nœuds de phase existent et meta.vf.trace vaut { erreur: true }" "$(J "$G6" "j.nodes.filter(n=>n.kind==='phase').length+'/'+JSON.stringify(j.meta.vf.trace)")" '2/{"erreur":true}'
assert_eq "T9.6b témoin positif : sans la panne, meta.vf.trace.exigences est rempli" "$(J "$G1" "j.meta.vf.trace.exigences.length")" "2"

echo "=== T9.9 — textes projetés sans chemin du poste (TRAC-11) ==="
L9="$WORK/l9"; lab_base "$L9" 1
wr "$(ledger "$L9")" <<MD
# Exigences

- [ ] **REQ-01**: usage de $HOME/outil pour la recette

| REQ-01 | Phase 1 | Complete /private/tmp/s |
MD
D9="$(phdir "$L9" 01-un)"
mkplan "$D9/01-01-PLAN.md" '[REQ-01]' "$(printf 'must_haves:\n  truths:\n    - "voir %s/docs/note.md pour le détail"' "$L9")"
printf -- '- **P99-D-01** : titre dans ~/.claude/x et suite\n' > "$D9/01-CONTEXT.md"
printf -- '---\nstatus: "revu dans /private/tmp/v"\n---\n# Vérification\n' > "$D9/01-VERIFICATION.md"
printf '# Recette\n\n**Statut : à faire, voir /private/tmp/x**\n' > "$D9/01-RECETTE-HUMAINE.md"
G9="$(C "$L9" graphe)"; S9="$WORK/s9.json"
node "$AUX/j.mjs" "$G9" "JSON.stringify({p:j.nodes.filter(n=>n.kind==='phase').map(n=>n.trace),t:j.meta.vf.trace,r:j.meta.vf.registres})" > "$S9"
n9() { grep -cF -- "$1" "$S9" || true; }
assert_eq "T9.9 aucun chemin du lab, de \$HOME, aucun ~/ ni /private/ dans les champs de la 76" "$(n9 "$L9") $(n9 "$HOME") $(n9 '~/') $(n9 '/private/')" "0 0 0 0"
assert_eq "T9.9b le chemin du lab est rendu relatif dans le critère" "$(J "$G9" "j.nodes.find(n=>n.id==='ph-1').trace.plans[0].criteres.liste[0]")" "voir docs/note.md pour le détail"
assert_eq "T9.9c libellé et titre de définition : « un chemin hors du lab »" "$(J "$G9" "j.meta.vf.trace.exigences[0].libelle.includes('un chemin hors du lab')+'/'+j.meta.vf.registres[0].decisions[0].titre.includes('un chemin hors du lab')")" "true/true"
assert_eq "T9.9d témoin positif : les quatre chaînes sont dans les fichiers du lab" "$(grep -cF -- "$L9" "$D9/01-01-PLAN.md") $(grep -cF -- "$HOME" "$(ledger "$L9")") $(grep -cF -- '~/' "$D9/01-CONTEXT.md") $(grep -cF -- '/private/tmp/x' "$D9/01-RECETTE-HUMAINE.md")" "1 1 1 1"

echo "=== T9.10 — citations du ledger projetées (P76-D-38) ==="
L10="$WORK/l10"; lab_base "$L10" 1
wr "$(ledger "$L10")" <<'MD'
# Exigences

- [x] **REQ-01**: Première exigence (P90-D-01, ADR-001, D-04)
- [ ] **REQ-02**: Deuxième exigence

| REQ-01 | Phase 1 | Complete |
| REQ-02 | Phase 1 | Pending |
MD
G10="$(C "$L10" graphe)"
assert_eq "T9.10 cites de REQ-01 : une décision préfixée, un ADR, une nue" "$(J "$G10" "JSON.stringify(j.meta.vf.trace.exigences.find(e=>e.id==='REQ-01').cites)")" '{"decisions":["P90-D-01"],"adrs":["ADR-001"],"nues":["D-04"]}'
assert_eq "T9.10b cites de REQ-02 : trois listes vides" "$(J "$G10" "JSON.stringify(j.meta.vf.trace.exigences.find(e=>e.id==='REQ-02').cites)")" '{"decisions":[],"adrs":[],"nues":[]}'
assert_eq "T9.10c témoin positif : la ligne du ledger contient les trois citations" "$(grep -c 'P90-D-01, ADR-001, D-04' "$(ledger "$L10")")" "1"

echo "=== T9.11 — équivalence de meta.vf.trace et des fichiers sources des exigences (P80-C76-6 ; 76-08 : le nœud « Exigences » est retiré, la lecture indépendante des fichiers le remplace) ==="
L11="$WORK/l11"; lab_base "$L11" 1
wr "$(ledger "$L11")" <<'MD'
# Exigences

- [ ] **REQ-01**: Première exigence
- [x] **REQ-02**: Deuxième exigence, cochée
- [ ] **REQ-03**: Troisième exigence, sans plan

| REQ-01 | Phase 1 | Pending |
| REQ-02 | Phase 1 | Complete |
| REQ-03 | Phase 1 | Pending |
MD
D11="$(phdir "$L11" 01-un)"; mkplan "$D11/01-01-PLAN.md" '[REQ-01, REQ-02]'; mkplan "$D11/01-02-PLAN.md" '[REQ-02]'
E11="$(C "$L11" equiv)"
assert_eq "T9.11 mêmes identifiants dans le même ordre des deux côtés" "$(J "$E11" "j.ids[0].join()+'|'+j.ids[1].join()")" "REQ-01,REQ-02,REQ-03|REQ-01,REQ-02,REQ-03"
assert_eq "T9.11b coche vrai ⇔ état « fait » de la carte" "$(J "$E11" "j.coche")" "true"
assert_eq "T9.11c libellé égal à la coupe près" "$(J "$E11" "j.libelle")" "true"
assert_eq "T9.11d chaque plan : mêmes exigences couvertes des deux côtés" "$(J "$E11" "j.plans.map(p=>p.p+':'+(JSON.stringify(p.anc)===JSON.stringify(p.nou))).join()")" "01-01-PLAN.md:true,01-02-PLAN.md:true"
assert_eq "T9.11e témoin positif : REQ-02 dans les deux plans, REQ-03 dans aucun" "$(J "$E11" "j.plans.map(p=>p.nou.join('+')).join('/')")" "REQ-01+REQ-02/REQ-02"

echo "=== T9.7 — contrat des champs facultatifs de cockpit-project@1 ==="
IFACE="$SCRIPTS/vf-cockpit-interface.json"
assert_eq "T9.7 le contrat déclare trace (nœud) et trace, registres, jalonActif (meta.vf)" "$(J "$IFACE" "(s=>s.optionnels.noeud.includes('trace')+'/'+['trace','registres','jalonActif'].every(k=>s.optionnels.metaVf.includes(k)))(j.schemas['vibeflow/cockpit-project@1'])")" "true/true"
assert_eq "T9.7b la version du schéma ne monte pas (une seule entrée cockpit-project)" "$(grep -c '"vibeflow/cockpit-project@1"' "$IFACE") $(grep -c 'cockpit-project@2' "$IFACE" || true)" "1 0"
assert_eq "T9.7c le graphe réel valide ses clés requises et ne porte aucune clé interdite" "$(node "$AUX/validate.mjs" "$IFACE" "$G1" 2>&1)" "OK"
node "$AUX/j.mjs" "$G1" "JSON.stringify({...j, meta: {...j.meta, mandat: 'x'}})" > "$WORK/g1-mandat.json"
assert_eq "T9.7d témoin positif : la même validation rougit sur une copie où une clé mandat est injectée" "$(node "$AUX/validate.mjs" "$IFACE" "$WORK/g1-mandat.json" 2>&1 | cut -c1-40)" "KO clé interdite présente : mandat"

echo "=== T9.8 — poids et durée ajoutés, mesurés sur ce dépôt ==="
P8="$(C "$REPO" poids)"
POIDS="POIDS avant=$(J "$P8" j.avant) apres=$(J "$P8" j.apres) delta=$(J "$P8" 'j.apres-j.avant')"
echo "$POIDS"; echo "DUREE sans=$(J "$P8" j.sans) avec=$(J "$P8" j.avec)"
assert_eq "T9.8 la ligne POIDS est mesurée et delta > 0" "$(J "$P8" "j.apres-j.avant>0")" "true"

echo "=== T9.12 — Revue M1 : une exigence d'archive ne se rattache qu'à sa phase, compartiment compris ==="
L12="$WORK/l12"; mkdir -p "$L12/.planning/phases/01-a" "$L12/.planning/milestones"
printf -- '---\nmilestone: v1\nstatus: executing\ncurrent_phase: 1\n---\n' > "$L12/.planning/STATE.md"
printf '# Roadmap\n\n## Milestones\n\n- 🚧 **v1** - Phases 1-1 (in progress)\n\n## Phases\n\n- [ ] **Phase 1: A** - p\n\n### Phase 1: A\n**Goal**: g\n**Depends on**: Nothing\n' > "$L12/.planning/ROADMAP.md"
printf '# Req\n\n- [x] **REQ-01**: vivante\n\n| REQ-01 | Phase 1 | Complete |\n' > "$L12/.planning/REQUIREMENTS.md"
printf '# Old\n\n- [x] **REQ-01**: ancienne jumelle\n- [x] **OLD-01**: ancienne sans jumelle\n' > "$L12/.planning/milestones/v0-REQUIREMENTS.md"
mkplan "$L12/.planning/phases/01-a/01-01-PLAN.md" '[REQ-01, OLD-01]'
M12="$(C "$L12" m1 'REQ-01,OLD-01')"
assert_eq "T9.12 lab plat : la jumelle d'archive ne double ni la ligne ni le total de la phase 1" "$(J "$M12" "j.phases.map(p=>p.ids.join('+')+'#'+p.total).join()")" "OLD-01+REQ-01#2"
assert_eq "T9.12b la clé de l'exigence vivante reste résoluble (200, pas cle-ambigue)" "$(J "$M12" "j.vues['REQ-01']")" "200/ok"
assert_eq "T9.12c témoin positif : l'exigence d'archive sans jumelle reste listée et ouvrable" "$(J "$M12" "j.vues['OLD-01']")" "200/ok"
L13="$WORK/l13"; mkdir -p "$L13/.planning/milestones"
for w in a b; do
  mkdir -p "$L13/.planning/workstreams/$w/phases/01-p"
  printf -- '---\nmilestone: v1\nstatus: executing\ncurrent_phase: 1\n---\n' > "$L13/.planning/workstreams/$w/STATE.md"
  printf '# Roadmap\n\n## Milestones\n\n- 🚧 **v1** - Phases 1-1 (in progress)\n\n## Phases\n\n- [ ] **Phase 1: P1** - p\n\n### Phase 1: P1\n**Goal**: but\n**Depends on**: Nothing\n' > "$L13/.planning/workstreams/$w/ROADMAP.md"
  printf '# Exigences\n\n- [ ] **LIVE-0%s**: vivante\n' "$w" > "$L13/.planning/workstreams/$w/REQUIREMENTS.md"
done
printf '# Archive\n\n- [x] **AR-01**: archivée\n' > "$L13/.planning/milestones/v0-REQUIREMENTS.md"
mkplan "$L13/.planning/workstreams/a/phases/01-p/01-01-PLAN.md" '[AR-01]'
M13="$(C "$L13" m1 'AR-01')"
assert_eq "T9.12d deux compartiments : AR-01, citée par un plan de a, sort dans la phase 1 de a seulement" "$(J "$M13" "j.phases.map(p=>p.ws+':'+p.ids.join('+')).sort().join()")" "a:AR-01,b:"
assert_eq "T9.12e témoin positif : AR-01 reste ouvrable par sa clé" "$(J "$M13" "j.vues['AR-01']")" "200/ok"

# --- FIN-SECTIONS ---
echo
echo "Résultats : $PASS passés, $FAIL échoués"
# garde anti-vert-à-vide : le nombre d'assertions jouées doit atteindre l'attendu
ATTENDU=36
[ $((PASS + FAIL)) -ge "$ATTENDU" ] || { echo "  ❌ FAIL — anti-vert-à-vide : $((PASS + FAIL)) assertions jouées, $ATTENDU attendues"; FAIL=$((FAIL+1)); }
[ "$FAIL" -eq 0 ]
