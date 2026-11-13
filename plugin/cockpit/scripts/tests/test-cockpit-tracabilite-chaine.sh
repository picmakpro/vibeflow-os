#!/usr/bin/env bash
# test-cockpit-tracabilite-chaine.sh — chaîne d'exigences du cockpit, fonctions pures sans serveur (TRAC-01 à TRAC-04, TRAC-11 ; P76-D-12 à P76-D-15bis, P76-D-24, P76-D-38)
#   T1 une exigence de bout en bout : ledger et dossier de phase fabriqués, lecture de collecte, projection, ligne « manque : VERIFICATION »
#   T2 maillons complets : SUMMARY (deux champs, scalaire, sans frontmatter), VERIFICATION et recette (niveaux, non lisible), contradictions, mentions, citations, lecture seule, reste()
#   T3 preuves attachées et critères `must_haves`, bilans exclusifs, vue de jalon, forme « Étape N »
# Labs fabriqués dans mktemp (aucun chemin du poste dans les fichiers écrits). Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$SCRIPTS/../../.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
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
NV=0
V() { NV=$((NV+1)); node "$AUX/trace.mjs" "$SCRIPTS" "$@" > "$WORK/v$NV.json" 2>/dev/null; echo "$WORK/v$NV.json"; }
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

# --- FIN-SECTIONS ---
echo
echo "Résultats : $PASS passés, $FAIL échoués"
# garde anti-vert-à-vide : le nombre d'assertions jouées doit atteindre l'attendu
ATTENDU=5
[ $((PASS + FAIL)) -ge "$ATTENDU" ] || { echo "  ❌ FAIL — anti-vert-à-vide : $((PASS + FAIL)) assertions jouées, $ATTENDU attendues"; FAIL=$((FAIL+1)); }
[ "$FAIL" -eq 0 ]
