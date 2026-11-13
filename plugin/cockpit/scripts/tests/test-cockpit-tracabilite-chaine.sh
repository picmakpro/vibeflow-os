#!/usr/bin/env bash
# test-cockpit-tracabilite-chaine.sh — chaîne d'exigences du cockpit, fonctions pures sans serveur (TRAC-01 à TRAC-04, TRAC-11 ; P76-D-12 à P76-D-15bis, P76-D-24, P76-D-38)
#   T1 une exigence de bout en bout : ledger et dossier de phase fabriqués, lecture de collecte, projection, ligne « manque : VERIFICATION »
#   T2 maillons complets : SUMMARY (deux champs, scalaire, sans frontmatter), VERIFICATION et recette (niveaux, non lisible), contradictions, mentions, citations, lecture seule, reste()
#   T3 preuves attachées et critères `must_haves`, bilans exclusifs, vue de jalon, forme « Étape N »
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
# j.mjs <fichier> <expression sur j> : JSON lu dans le fichier, expression évaluée ; « absent » si la sortie est une erreur de module ou si l'expression échoue
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[3] + ')')(j); } catch { console.log('absent'); process.exit(0); }
console.log(v === undefined ? 'absent' : typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
# trace.mjs <scripts> <lab> <vue> [cle] : lecture du lab par les modules de <scripts>, projection sur le graphe réel, puis la vue demandée en JSON
#   vues : phase <ws|n> · jalon · ex <ws|id> · trace · reste <forme 1-4>
cat > "$AUX/trace.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, vue, cle] = process.argv;
const imp = (n) => import(pathToFileURL(path.join(scripts, n)).href);
async function sortie() {
  if (vue === 'reste') {
    const { reste } = await imp('vf-cockpit-avancement.mjs');
    const formes = ['**Statut : FAITE — close le 2026-11-05.', '**Statut :** CLOSE — recette terminée', 'Statut : recette jouée, tout est bon', '# Recette\n\nrien de plus'];
    return reste({ ph: { done: false }, fichiers: ['01-PLAN.md', '01-CONTEXT.md', '01-RECETTE-HUMAINE.md'], lire: () => formes[Number(cle) - 1], vivante: false });
  }
  const { readPlanning, lireConfine, read, lister, fm, list, clip } = await imp('vf-cockpit-planning.mjs');
  const { buildProjectGraph } = await imp('vf-cockpit-project.mjs');
  const { planningLayout } = await imp('vf-cockpit-paths.mjs');
  const { texte } = await imp('vf-cockpit-formats.mjs');
  let col, chaine, bilans;
  try { col = await imp('vf-cockpit-trace-collecte.mjs'); chaine = await imp('vf-cockpit-trace-chaine.mjs'); bilans = await imp('vf-cockpit-trace-bilans.mjs'); } catch { return { erreur: 'module-absent' }; }
  const racine = fs.realpathSync(lab);
  const g = buildProjectGraph(racine);
  const layout = planningLayout(racine);
  const t = lireConfine(racine, () => {
    const P = readPlanning(racine, layout, { sansTags: true });
    const ledgers = layout.compartiments.map((c) => { const f = path.join(c.dir, 'REQUIREMENTS.md'); return { ws: c.ws || '', fichier: P.rel(f), txt: texte(read(f)) }; });
    return col.lireTrace({ phases: P.phases, phaseDirs: P.phaseDirs, reqs: P.reqs, ledgers, lire: read, lister, rel: P.rel, fm, list });
  });
  const ms = g.meta.vf.milestones; const m0 = ms.find((m) => m.key === g.meta.vf.milestone) || ms.find((m) => m.st === 'active') || ms.at(-1);
  col.projeterTrace(g, t, { jalonActif: m0 ? m0.id : null, couper: clip });
  if (vue === 'phase') return bilans.vuePhase(g, cle);
  if (vue === 'jalon') return bilans.vueJalon(g);
  if (vue === 'ex') return chaine.vueExigence(g, cle);
  return { ...g.meta.vf.trace, jalonActif: g.meta.vf.jalonActif, phases: g.nodes.filter((n) => n.kind === 'phase').map((n) => ({ id: n.id, num: n.num, ws: n.ws, parent: n.parent, trace: n.trace })) };
}
try { console.log(JSON.stringify(await sortie())); } catch (e) { console.log(JSON.stringify({ erreur: 'echec ' + String(e && e.message).slice(0, 120) })); }
JS
# V <lab> <vue> [cle] -> chemin du fichier JSON produit (un fichier par appel)
V() { local f; f="$WORK/v-$(basename "$1")-$2-$(printf '%s' "${3:-}" | tr -c 'A-Za-z0-9' _).json"; node "$AUX/trace.mjs" "$SCRIPTS" "$@" > "$f" 2>/dev/null; echo "$f"; }
# M <fichier> <id> <maillon> -> « état/niveau » (niveau « - » si le maillon n'est pas lu)
M() { J "$1" "(l=>l.maillons.$3.etat+'/'+(l.maillons.$3.niveau??'-'))(j.exigences.find(l=>l.id==='$2'))"; }
# MOT <fichier> <id> -> « maillon/état » du mot de ligne, « aucun » si la chaîne est complète
MOT() { J "$1" "(l=>l.mot?l.mot.maillon+'/'+l.mot.etat:'aucun')(j.exigences.find(l=>l.id==='$2'))"; }

# --- fabrication des labs ---
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
# lab_base <dir> <n> [m] : compartiment x, jalon v1 = phases 1..n, jalon v2 = phases n+1..m ; STATE milestone v1
lab_base() {
  local d="$1" n="$2" m="${3:-}" b="$1/.planning/workstreams/x" i last
  last="${m:-$n}"; mkdir -p "$b"
  { printf '# Roadmap\n\n## Milestones\n\n- 🚧 **v1** - Phases 1-%s (in progress)\n' "$n"
    [ -n "$m" ] && printf -- '- 📋 **v2** - Phases %s-%s (planned)\n' "$((n+1))" "$m"
    printf '\n## Phases\n\n'; for i in $(seq 1 "$last"); do printf -- '- [ ] **Phase %s: P%s** - p\n' "$i" "$i"; done; printf '\n'
    for i in $(seq 1 "$last"); do printf '### Phase %s: P%s\n**Goal**: but %s\n**Depends on**: Nothing\n\n' "$i" "$i" "$i"; done; } > "$b/ROADMAP.md"
  printf -- '---\nmilestone: v1\nstatus: executing\ncurrent_phase: 1\n---\n' > "$b/STATE.md"
}
# phdir <lab> <nom du dossier de phase> -> chemin du dossier
phdir() { echo "$1/.planning/workstreams/x/phases/$2"; }
ledger() { echo "$1/.planning/workstreams/x/REQUIREMENTS.md"; }
# mkplan <fichier> <valeur de requirements | -> [lignes de frontmatter en plus]
mkplan() { local f="$1" r="$2" extra="${3:-}"; mkdir -p "$(dirname "$f")"; { printf -- '---\nphase: x\nplan: "01"\nwave: 1\n'; [ "$r" = "-" ] || printf 'requirements: %s\n' "$r"; [ -n "$extra" ] && printf '%s\n' "$extra"; printf -- '---\n\n<objective>\nobjectif\n</objective>\n'; } > "$f"; }
# mksum <fichier> <lignes de frontmatter | NOFM>
mksum() { mkdir -p "$(dirname "$1")"; if [ "$2" = "NOFM" ]; then printf '# Summary\n\nsans frontmatter\n' > "$1"; else printf -- '---\n%s\n---\n# Summary\n' "$2" > "$1"; fi; }

echo "=== T1 — une exigence de bout en bout ==="
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
wr "$D2/02-VERIFICATION.md" <<'MD'
---
status: passed
---
# Vérification

| Exigence | Preuve | Statut |
|----------|--------|--------|
| REQ-02 | test | VERIFIED |
MD
F="$(V "$L1" phase 'x|1')"
assert_eq "T1.1 REQ-01 : mot de ligne = manque VERIFICATION (rien n'existe au-delà du SUMMARY)" "$(MOT "$F" REQ-01)" "verification/manque"
assert_eq "T1.1b REQ-01 : plan lu au niveau exigence" "$(M "$F" REQ-01 plan)" "lu/exigence"
assert_eq "T1.1c REQ-01 : SUMMARY lu au niveau exigence (requirements-completed scalaire)" "$(M "$F" REQ-01 summary)" "lu/exigence"
assert_eq "T1.1d REQ-01 : VERIFICATION et recette manquent" "$(M "$F" REQ-01 verification) $(M "$F" REQ-01 recette)" "manque/- manque/-"
F="$(V "$L1" phase 'x|2')"
assert_eq "T1.2 REQ-02 : VERIFICATION citée dans la table, lue au niveau exigence (témoin positif voisin)" "$(M "$F" REQ-02 verification)" "lu/exigence"

echo "=== T2 — maillons complets, contradictions, mentions, citations ==="
L2="$WORK/l2"; lab_base "$L2" 8
FILL=""; for _ in $(seq 1 60); do FILL="${FILL}mot "; done
wr "$(ledger "$L2")" <<MD
# Exigences

- [ ] **REQ-03**: SUMMARY lu par requirements
- [ ] **REQ-04**: SUMMARY lu par requirements-completed scalaire
- [ ] **REQ-10**: SUMMARY apparié sans frontmatter
- [ ] **REQ-11**: SUMMARY sans champ d'exigence
- [ ] **REQ-12**: SUMMARY dont le champ ne cite pas l'identifiant
- [ ] **REQ-13**: VERIFICATION, première cellule
- [ ] **REQ-14**: VERIFICATION, troisième cellule
- [ ] **REQ-15**: VERIFICATION, paragraphe seulement
- [ ] **REQ-16**: VERIFICATION sans frontmatter
- [ ] **REQ-17**: recette qui cite l'identifiant
- [ ] **REQ-18**: recette qui ne le cite pas
- [ ] **REQ-19**: recette sans ligne de statut
- [ ] **REQ-20**: dossier qui n'a qu'une VALIDATION
- [x] **REQ-05**: cochée, plan citant, aucun SUMMARY
- [ ] **REQ-06**: statut Complete, aucun plan
- [ ] **REQ-07**: non cochée, SUMMARY lu
- [ ] **REQ-08**: rattachée par un plan seulement
- [ ] **REQ-09**: non cochée, ni plan ni SUMMARY
- [x] **REQ-21**: cochée, ni plan ni SUMMARY
- [ ] **REQ-22**: chaîne complète, citée partout
- [ ] **REQ-23**: chaîne complète, niveau phase
- [ ] **REQ-30**: ${FILL}(P90-D-01, ADR-001, D-04)
- [ ] **REQ-31**: aucune citation
- [ ] **REQ-32**: citation d'une décision définie nulle part (P95-D-09)

| REQ-03 | Phase 1 | Pending |
| REQ-04 | Phase 1 | Pending |
| REQ-10 | Phase 1 | Pending |
| REQ-11 | Phase 1 | Pending |
| REQ-12 | Phase 1 | Pending |
| REQ-13 | Phase 2 | Pending |
| REQ-14 | Phase 2 | Pending |
| REQ-15 | Phase 2 | Pending |
| REQ-16 | Phase 3 | Pending |
| REQ-17 | Phase 4 | Pending |
| REQ-18 | Phase 4 | Pending |
| REQ-19 | Phase 5 | Pending |
| REQ-20 | Phase 6 | Pending |
| REQ-05 | Phase 7 | Complete |
| REQ-06 | Phase 7 | Complete—2026-11-05(PR#203…) |
| REQ-07 | Phase 7 | Pending |
| REQ-09 | Phase 7 | Planned |
| REQ-21 | Phase 7 | Planned |
| GHOST-01 | Phase 7 | Pending |
| REQ-22 | Phase 8 | Complete |
| REQ-23 | Phase 8 | Complete |
MD
# phase 1 : variantes de SUMMARY
D="$(phdir "$L2" 01-sum)"
mkplan "$D/01-01-PLAN.md" '[REQ-03]';  mksum "$D/01-01-SUMMARY.md" 'requirements: [REQ-03]'
mkplan "$D/01-02-PLAN.md" '[REQ-04]';  mksum "$D/01-02-SUMMARY.md" 'requirements-completed: REQ-04'
mkplan "$D/01-03-PLAN.md" '[REQ-10]';  mksum "$D/01-03-SUMMARY.md" NOFM
mkplan "$D/01-04-PLAN.md" '[REQ-11]';  mksum "$D/01-04-SUMMARY.md" 'phase: 1'
mkplan "$D/01-05-PLAN.md" '[REQ-12]';  mksum "$D/01-05-SUMMARY.md" 'requirements: [REQ-99]'
# phase 2 : VERIFICATION (cellule 1, cellule 3, paragraphe) · phase 3 : VERIFICATION sans frontmatter
D="$(phdir "$L2" 02-ver)"; mkplan "$D/02-01-PLAN.md" '[REQ-13, REQ-14, REQ-15]'; mksum "$D/02-01-SUMMARY.md" 'requirements-completed: [REQ-13, REQ-14, REQ-15]'
wr "$D/02-VERIFICATION.md" <<'MD'
---
status: passed
---
# Vérification

| Exigence | Preuve | Statut |
|----------|--------|--------|
| REQ-13 | test | VERIFIED |
| Critère | preuve | REQ-14 |

La phase couvre aussi REQ-15 en prose, hors de toute table.
MD
D="$(phdir "$L2" 03-ver2)"; mkplan "$D/03-01-PLAN.md" '[REQ-16]'; mksum "$D/03-01-SUMMARY.md" 'requirements: [REQ-16]'
printf '# Vérification\n\n| REQ-16 | test | OK |\n' > "$D/03-VERIFICATION.md"
# phases 4 à 6 : recettes
D="$(phdir "$L2" 04-rec)"; mkplan "$D/04-01-PLAN.md" '[REQ-17, REQ-18]'; mksum "$D/04-01-SUMMARY.md" 'requirements: [REQ-17, REQ-18]'
printf -- '---\nstatus: passed\n---\n# Vérification\n' > "$D/04-VERIFICATION.md"
printf '# Recette humaine\n\n**Statut : FAITE — close le 2026-11-05.**\n\nCouvre REQ-17.\n' > "$D/04-RECETTE-HUMAINE.md"
D="$(phdir "$L2" 05-rec2)"; mkplan "$D/05-01-PLAN.md" '[REQ-19]'; mksum "$D/05-01-SUMMARY.md" 'requirements: [REQ-19]'
printf '# Recette des juges\n\nrien de daté ici\n' > "$D/05-RECETTE-JUGES.md"
D="$(phdir "$L2" 06-val)"; mkplan "$D/06-01-PLAN.md" '[REQ-20]'; mksum "$D/06-01-SUMMARY.md" 'requirements: [REQ-20]'
printf '# Validation\n\nREQ-20\n' > "$D/06-VALIDATION.md"
# phase 7 : contradictions et mentions
D="$(phdir "$L2" 07-contra)"
mkplan "$D/07-01-PLAN.md" '[REQ-05]'
mkplan "$D/07-02-PLAN.md" '[REQ-07]'; mksum "$D/07-02-SUMMARY.md" 'requirements: [REQ-07]'
mkplan "$D/07-03-PLAN.md" '[REQ-08]' # pas de SUMMARY : REQ-08 ne porte que la mention sans-ligne-tracabilite
# phase 8 : chaîne complète, un identifiant cité partout, l'autre au niveau phase
D="$(phdir "$L2" 08-full)"; mkplan "$D/08-01-PLAN.md" '[REQ-22, REQ-23]'; mksum "$D/08-01-SUMMARY.md" 'requirements: [REQ-22, REQ-23]'
printf -- '---\nstatus: passed\n---\n# Vérification\n\n| REQ-22 | test | OK |\n' > "$D/08-VERIFICATION.md"
printf '# Recette humaine\n\n**Statut : FAITE — close le 2026-11-05.**\n\nREQ-22 recetté.\n' > "$D/08-RECETTE-HUMAINE.md"

SHA_A="$(find "$L2" -type f -print0 | sort -z | xargs -0 shasum -a 256)"
F="$(V "$L2" phase 'x|1')"
assert_eq "T2.1 REQ-03 : SUMMARY lu par requirements: (liste)" "$(M "$F" REQ-03 summary)" "lu/exigence"
assert_eq "T2.1 REQ-04 : SUMMARY lu par requirements-completed: scalaire sans crochets (témoin voisin)" "$(M "$F" REQ-04 summary)" "lu/exigence"
assert_eq "T2.1 REQ-10 : SUMMARY apparié sans frontmatter = non lisible, jamais manque" "$(M "$F" REQ-10 summary)" "non-lisible/-"
assert_eq "T2.1 REQ-11 : frontmatter sans champ d'exigence = non lisible" "$(M "$F" REQ-11 summary)" "non-lisible/-"
assert_eq "T2.1 REQ-12 : champ présent sans l'identifiant = manque" "$(M "$F" REQ-12 summary)" "manque/-"
F="$(V "$L2" phase 'x|2')"
assert_eq "T2.2 REQ-13 : identifiant en première cellule de table = lu, niveau exigence" "$(M "$F" REQ-13 verification)" "lu/exigence"
assert_eq "T2.2 REQ-14 : identifiant en troisième cellule = lu, niveau exigence" "$(M "$F" REQ-14 verification)" "lu/exigence"
assert_eq "T2.2 REQ-15 : identifiant seulement dans un paragraphe = lu, niveau phase" "$(M "$F" REQ-15 verification)" "lu/phase"
F="$(V "$L2" phase 'x|3')"
assert_eq "T2.2 REQ-16 : VERIFICATION sans frontmatter = non lisible" "$(M "$F" REQ-16 verification)" "non-lisible/-"
F="$(V "$L2" phase 'x|4')"; TR="$(V "$L2" trace)"
assert_eq "T2.3 REQ-17 : recette qui cite l'identifiant = lu, niveau exigence" "$(M "$F" REQ-17 recette)" "lu/exigence"
assert_eq "T2.3 REQ-18 : recette qui ne le cite pas = lu, niveau phase (témoin voisin)" "$(M "$F" REQ-18 recette)" "lu/phase"
assert_eq "T2.3 recette de la phase 4 : faite, statut lu" "$(J "$TR" "(r=>r.faite+'/'+r.statut.includes('FAITE'))(j.phases.find(p=>p.num==='4').trace.recette)")" "true/true"
F="$(V "$L2" phase 'x|5')"
assert_eq "T2.3 REQ-19 : 05-RECETTE-JUGES.md sans ligne **Statut : = non lisible" "$(M "$F" REQ-19 recette)" "non-lisible/-"
F="$(V "$L2" phase 'x|6')"
assert_eq "T2.3 REQ-20 : un 06-VALIDATION.md n'est jamais une recette = manque" "$(M "$F" REQ-20 recette)" "manque/-"
# T2.4 reste() : mêmes verdicts qu'avant l'extraction des deux fonctions (tableaux capturés dans 76-01-RED-TRACE.md)
assert_eq "T2.4 reste() forme 1 (**Statut : FAITE)" "$(node "$AUX/trace.mjs" "$SCRIPTS" - reste 1)" '["verification","cloture"]'
assert_eq "T2.4 reste() forme 2 (**Statut :** CLOSE)" "$(node "$AUX/trace.mjs" "$SCRIPTS" - reste 2)" '["recette","verification","cloture"]'
assert_eq "T2.4 reste() forme 3 (« Statut : recette jouée », sans gras)" "$(node "$AUX/trace.mjs" "$SCRIPTS" - reste 3)" '["recette","verification","cloture"]'
assert_eq "T2.4 reste() forme 4 (aucune ligne)" "$(node "$AUX/trace.mjs" "$SCRIPTS" - reste 4)" '["recette","verification","cloture"]'
assert_eq "T2.4 ligneStatutRecette et recetteFaite exportées par avancement" "$(grep -c 'export function ligneStatutRecette\|export function recetteFaite' "$SCRIPTS/vf-cockpit-avancement.mjs")" "2"
F="$(V "$L2" phase 'x|7')"; TR="$(V "$L2" trace)"
assert_eq "T2.5 REQ-05 : cochée, plan citant, aucun SUMMARY = maillon SUMMARY en contradiction" "$(M "$F" REQ-05 summary) $(MOT "$F" REQ-05)" "contradiction/- summary/contradiction"
assert_eq "T2.5 REQ-05 : le mot porte le code cochee-sans-summary" "$(J "$F" "j.exigences.find(l=>l.id==='REQ-05').mot.code")" "cochee-sans-summary"
assert_eq "T2.5 REQ-06 : Complete sans plan = maillon plan en contradiction, code complete-sans-plan" "$(M "$F" REQ-06 plan) $(J "$F" "j.exigences.find(l=>l.id==='REQ-06').mot.code")" "contradiction/- complete-sans-plan"
assert_eq "T2.5 REQ-07 : non cochée avec SUMMARY lu = mention neutre" "$(J "$F" "j.exigences.find(l=>l.id==='REQ-07').mentions")" '["non-cochee-summary-lu"]'
assert_eq "T2.5 REQ-08 : rattachée par un PLAN seulement = mention sans-ligne-tracabilite" "$(J "$F" "j.exigences.find(l=>l.id==='REQ-08').mentions") $(J "$TR" "j.exigences.find(e=>e.id==='REQ-08').rattachement")" '["sans-ligne-tracabilite"] plan'
assert_eq "T2.5 GHOST-01 : ligne de traçabilité sans exigence comptée par phase, jamais posée sur une exigence" "$(J "$TR" "j.phases.find(p=>p.num==='7').trace.lignesSansExigence+'/'+j.exigences.some(e=>e.id==='GHOST-01')+'/'+j.phases.find(p=>p.num==='1').trace.lignesSansExigence")" "1/false/0"
assert_eq "T2.5 REQ-09 : absence simple voisine = manque, jamais contradiction" "$(M "$F" REQ-09 summary) $(M "$F" REQ-09 plan)" "manque/- manque/-"
assert_eq "T2.5 statut Planned = fait faux ; Complete—… = fait vrai" "$(J "$TR" "j.exigences.find(e=>e.id==='REQ-09').fait+'/'+j.exigences.find(e=>e.id==='REQ-06').fait")" "false/true"
assert_eq "T2.7 REQ-21 : premier maillon non lu = plan (manque) ; la contradiction du SUMMARY passe en contradictions" "$(MOT "$F" REQ-21) $(J "$F" "j.exigences.find(l=>l.id==='REQ-21').contradictions")" 'plan/manque ["cochee-sans-summary"]'
assert_eq "T2.7 REQ-05 : la contradiction qui EST le mot n'est pas répétée en contradictions" "$(J "$F" "j.exigences.find(l=>l.id==='REQ-05').contradictions")" "[]"
F="$(V "$L2" phase 'x|8')"
assert_eq "T2.7 REQ-22 : quatre maillons lus = chaîne complète (mot null)" "$(MOT "$F" REQ-22)" "aucun"
assert_eq "T2.7 REQ-23 : chaîne complète, niveauPhase liste VERIFICATION et recette" "$(MOT "$F" REQ-23) $(J "$F" "j.exigences.find(l=>l.id==='REQ-23').niveauPhase")" 'aucun ["verification","recette"]'
# T2.8 citations lues sur la ligne COMPLÈTE de l'exigence au ledger (au-delà des 220 caractères du libellé)
LG="$(ledger "$L2")"
assert_eq "T2.8 témoin positif : les trois lignes du ledger contiennent bien les chaînes citées" "$(grep -c 'P90-D-01, ADR-001, D-04)$' "$LG") $(grep -c '(P95-D-09)$' "$LG")" "1 1"
assert_eq "T2.8 REQ-30 : cites = préfixée, ADR, nue" "$(J "$TR" "j.exigences.find(e=>e.id==='REQ-30').cites")" '{"decisions":["P90-D-01"],"adrs":["ADR-001"],"nues":["D-04"]}'
assert_eq "T2.8 la citation est au-delà du libellé coupé (jamais lue dans libelle)" "$(J "$TR" "j.exigences.find(e=>e.id==='REQ-30').libelle.includes('P90-D-01')")" "false"
assert_eq "T2.8 REQ sans citation : trois listes vides" "$(J "$TR" "j.exigences.find(e=>e.id==='REQ-31').cites")" '{"decisions":[],"adrs":[],"nues":[]}'
assert_eq "T2.8 décision non définie : reste une citation lue ; D-04 n'est jamais dans decisions" "$(J "$TR" "j.exigences.find(e=>e.id==='REQ-32').cites.decisions") $(J "$TR" "j.exigences.find(e=>e.id==='REQ-30').cites.decisions.includes('D-04')")" '["P95-D-09"] false'
SHA_B="$(find "$L2" -type f -print0 | sort -z | xargs -0 shasum -a 256)"
assert_eq "T2.6 lecture seule : empreintes sha256 du lab identiques avant et après toutes les lectures" "$SHA_B" "$SHA_A"
assert_eq "T2.6 témoin positif : l'empreinte porte bien les fichiers du lab (au moins 30)" "$([ "$(printf '%s\n' "$SHA_A" | wc -l | tr -d ' ')" -ge 30 ] && echo oui || echo non)" "oui"

# --- FIN-SECTIONS ---
echo
echo "Résultats : $PASS passés, $FAIL échoués"
# garde anti-vert-à-vide : le nombre d'assertions jouées doit atteindre l'attendu
ATTENDU=5
[ $((PASS + FAIL)) -ge "$ATTENDU" ] || { echo "  ❌ FAIL — anti-vert-à-vide : $((PASS + FAIL)) assertions jouées, $ATTENDU attendues"; FAIL=$((FAIL+1)); }
[ "$FAIL" -eq 0 ]
