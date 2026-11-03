#!/usr/bin/env bash
# test-cockpit-projet.sh — graphe Projet du cockpit sur tout lab GSD (CKPT-06) : plat au gabarit GSD (P1),
# partitionné (P2), sans liste de jalons avec missions (P3), contrat et absence de nom de compartiment (P4),
# identité d'une phase = (compartiment, numéro) (P5). Fixtures écrites par la suite dans mktemp.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
# --- outils node écrits par la suite (jamais de long node -e) ---
cat > "$AUX/q.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, what, root, home, scriptsDir, extra] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
if (what === 'who') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.collectWho(root, { home, scriptsDir }))); }
else if (what === 'reveal') { const m = await imp('vf-cockpit-who.mjs'); console.log(JSON.stringify(m.revealDoing(root, extra, { home, scriptsDir }))); }
else if (what === 'project') { const m = await imp('vf-cockpit-project.mjs'); console.log(JSON.stringify(m.buildProjectGraph(root))); }
JS
cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <interface.json> <schemaId> <sortie.json> — clés requises et typées, clés interdites à toute profondeur
import fs from 'node:fs';
const [, , ifaceF, id, outF] = process.argv;
const spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id];
const out = JSON.parse(fs.readFileSync(outF, 'utf8'));
const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) {
  if (!(k in out)) errs.push(`clé requise absente : ${k}`);
  else if (t !== 'any' && type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])} au lieu de ${t}`);
}
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`clé interdite présente : ${k}`); });
for (const w of out.workers || []) {
  for (const k of spec.travailleur.requis) if (!(k in w)) errs.push(`travailleur ${w.id} : clé ${k} absente`);
  if (!spec.kinds.includes(w.kind)) errs.push(`kind inconnu : ${w.kind}`);
}
for (const s of Object.values(out.sources || {})) if (!spec.etatsSource.includes(s.etat)) errs.push(`état de source inconnu : ${s.etat}`);
for (const n of out.nodes || []) for (const k of spec.noeud?.requis || []) if (!(k in n)) errs.push(`nœud ${n.id} : clé ${k} absente`);
for (const f of out.files || []) for (const k of spec.element?.requis || []) if (!(k in f)) errs.push(`élément ${f.p} : clé ${k} absente`);
for (const l of out.links || []) for (const k of spec.lien?.requis || []) if (!(k in l)) errs.push(`lien : clé ${k} absente`);
for (const k of spec.meta?.requis || []) if (!(k in (out.meta || {}))) errs.push(`meta.${k} absente`);
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
process.exit(errs.length ? 1 : 0);
JS
Q() { node "$AUX/q.mjs" "$SCRIPTS" "$@"; }
G() { node "$AUX/get.mjs" "$@"; }
IFACE="$SCRIPTS/vf-cockpit-interface.json"
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }   # wr <fichier> < contenu
graph() { Q project "$1" > "$2"; }

# ---------- P1 — lab plat au gabarit GSD ----------
L1="$WORK/p1"; B="$L1/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet

### Phase 1: Socle
**Goal**: Poser le socle
**Depends on**: Nothing (first phase)

### Phase 2: Écran
**Goal**: Poser l'écran
**Depends on**: Phase 1
MD
wr "$B/REQUIREMENTS.md" <<'MD'
- [x] **AUTH-01**: se connecter

| AUTH-01 | Phase 1 | Complete |
MD
wr "$B/STATE.md" <<'MD'
---
status: executing
current_phase: 2
---
MD
wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
<objective>Poser le socle</objective>
MD
echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
wr "$B/phases/02-ecran/02-01-PLAN.md" <<'MD'
<objective>Poser l'écran</objective>
MD
graph "$L1" "$WORK/g1.json"
echo "=== P1 — lab plat au gabarit GSD ==="
assert_eq "P1.1 — ph-1 done, ph-2 active" "$(G "$WORK/g1.json" 'j.nodes.filter(n=>/^ph-\d$/.test(n.id)).map(n=>n.id+":"+n.st).join(",")')" "ph-1:done,ph-2:active"
assert_eq "P1.2 — plan 01-01 done, 02-01 active" "$(G "$WORK/g1.json" 'j.files.filter(f=>/^0\d-01 /.test(f.name)).map(f=>f.name.slice(0,5)+":"+f.st).join(",")')" "01-01:done,02-01:active"
assert_eq "P1.3 — lien ph-1 vers ph-2 de type import" "$(G "$WORK/g1.json" 'j.links.filter(l=>l.a==="n:ph-1"&&l.b==="n:ph-2"&&l.k==="import").length')" "1"
assert_eq "P1.4 — exigence AUTH-01 sous ph-1.req" "$(G "$WORK/g1.json" 'j.files.filter(f=>f.n==="ph-1.req").map(f=>f.name).join(",")')" "AUTH-01"
assert_eq "P1.5 — jalon v1.0 MVP actif, pied 1/2" "$(G "$WORK/g1.json" 'j.nodes.filter(n=>n.id==="ms-v1.0-mvp").map(n=>n.st+"|"+n.foot).join(",")')" "active|1/2 phases · 50 %"
assert_eq "P1.6 — meta.vf.phase = 2" "$(G "$WORK/g1.json" 'j.meta.vf.phase')" "2"

# ---------- P2 — lab partitionné, deux compartiments, numéros uniques ----------
L2="$WORK/p2"; B="$L2/.planning"
wr "$B/workstreams/alpha/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **alpha-v1** — Phases 10-11 (en cours)

## Phases

- [ ] Phase 10: Un
- [ ] Phase 11: Deux

### Phase 10: Un
**Goal:** le but
MD
wr "$B/workstreams/beta/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **beta-v1** — Phases 20 (en cours)

## Phases

- [ ] Phase 20: Trois
MD
echo alpha > "$B/active-workstream"
printf -- '---\nmilestone: alpha-v1\ncurrent_phase: 10\nstatus: executing\n---\n' | wr "$B/workstreams/alpha/STATE.md"
wr "$B/workstreams/alpha/phases/VFDO-10-x/10-01-PLAN.md" <<'MD'
<objective>Un plan</objective>
MD
graph "$L2" "$WORK/g2.json"
echo "=== P2 — lab partitionné ==="
assert_eq "P2.1 — les deux jalons sont présents" "$(G "$WORK/g2.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.id).sort().join(",")')" "ms-alpha-v1,ms-beta-v1"
assert_eq "P2.2 — aucun lien d'enchaînement inter-compartiments" "$(G "$WORK/g2.json" 'j.links.filter(l=>l.k==="event").length')" "0"
assert_eq "P2.3 — meta.vf lu dans le STATE du compartiment actif" "$(G "$WORK/g2.json" 'j.meta.vf.milestone')" "alpha-v1"
assert_eq "P2.4 — identifiants de phase restent ph-10, ph-11, ph-20" "$(G "$WORK/g2.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id).sort().join(",")')" "ph-10,ph-11,ph-20"
assert_eq "P2.5 — le plan du dossier préfixé est rattaché à ph-10" "$(G "$WORK/g2.json" 'j.files.filter(f=>f.n==="ph-10").length')" "1"

# ---------- P3 — lab plat sans jalons, avec missions ----------
L3="$WORK/p3"; B="$L3/.planning"
wr "$B/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Seule** - une phase
MD
wr "$B/missions/MISSION-1.dag.json" <<'JSON'
{"nodes":[{"id":"a","step":"s","deps":[],"status":"blocked"},{"id":"b","step":"s","deps":[],"status":"ready"},{"id":"c","step":"s","deps":[],"status":"running"},{"id":"d","step":"s","deps":[],"status":"done"},{"id":"e","step":"s","deps":[],"status":"failed"}]}
JSON
printf '{"nodes":[' | wr "$B/missions/TRONQUE.dag.json"
graph "$L3" "$WORK/g3.json"; RC3=$?
echo "=== P3 — sans liste de jalons, missions ==="
assert_eq "P3.1 — graphe rendu malgré le DAG tronqué" "$RC3" "0"
assert_eq "P3.2 — jalon synthétique ms-phases « Phases »" "$(G "$WORK/g3.json" 'j.nodes.filter(n=>n.id==="ms-phases").map(n=>n.label).join(",")')" "Phases"
assert_eq "P3.3 — statuts de DAG todo,todo,active,done,blocked" "$(G "$WORK/g3.json" 'j.files.filter(f=>f.n==="dag-MISSION-1").map(f=>f.st).join(",")')" "todo,todo,active,done,blocked"
assert_eq "P3.4 — le DAG tronqué est ignoré" "$(G "$WORK/g3.json" 'j.nodes.filter(n=>n.id==="dag-TRONQUE").length')" "0"

# ---------- P5 — invariant d'identité : deux compartiments à « Phase 1 » ----------
L5="$WORK/p5"; B="$L5/.planning/workstreams"
for w in un deux; do
  wr "$B/$w/ROADMAP.md" <<'MD'
- [ ] **Phase 1: Premiere** - une phase
MD
done
echo ok > /dev/null
wr "$B/un/phases/01-a/01-01-PLAN.md" <<'MD'
<objective>Plan un</objective>
MD
wr "$B/deux/phases/01-b/01-01-PLAN.md" <<'MD'
<objective>Plan deux</objective>
MD
printf -- '- [ ] **UN-01**: exigence un\n\n| UN-01 | Phase 1 | Pending |\n' | wr "$B/un/REQUIREMENTS.md"
printf -- '- [ ] **DEUX-01**: exigence deux\n\n| DEUX-01 | Phase 1 | Pending |\n' | wr "$B/deux/REQUIREMENTS.md"
graph "$L5" "$WORK/g5.json"
echo "=== P5 — identité (compartiment, numéro) ==="
assert_eq "P5.1 — deux phases distinctes" "$(G "$WORK/g5.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id).sort().join(",")')" "ph-1@deux,ph-1@un"
assert_eq "P5.2 — chaque plan dans son compartiment" "$(G "$WORK/g5.json" 'j.files.filter(f=>f.p.endsWith("PLAN.md")).map(f=>f.n+"="+f.p.split("/")[2]).sort().join(",")')" "ph-1@deux=deux,ph-1@un=un"
assert_eq "P5.3 — chaque exigence dans son compartiment" "$(G "$WORK/g5.json" 'j.files.filter(f=>f.p.startsWith("req/")).map(f=>f.n+"="+f.name).sort().join(",")')" "ph-1@deux.req=DEUX-01,ph-1@un.req=UN-01"

# ---------- P6 — ROADMAP à la française : lu malgré la dérive, dérive détectée, correctif proposé ----------
# Cas réel (lab Scroll-Off, 2026-11-03) : « Phase N : » partout, aucune phase lue, carte vide sans explication.
L6="$WORK/p6"; B="$L6/.planning"
wr "$B/ROADMAP.md" <<'MD'
# Roadmap

## Phases

- [x] **Phase 1 : Socle** — premier jet
- [ ] **Phase 2 : Écran** — second jet

## Phase Details

### Phase 1 : Socle
**Goal**: Poser le socle
**Depends on**: rien · **Parallélisable avec**: Phase 2

### Phase 2 : Écran
**Goal**: Poser l'écran
**Depends on**: Phase 1
MD
wr "$B/STATE.md" <<'MD'
---
milestone: v2.0
status: executing
---
MD
graph "$L6" "$WORK/g6.json"
DR="$SCRIPTS/vf-cockpit-drift.mjs"
echo "=== P6 — dérive de format ==="
assert_eq "P6.1 — « Phase N : » lu : deux phases, ph-1 done" "$(G "$WORK/g6.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id+":"+n.st).join(",")')" "ph-1:done,ph-2:todo"
assert_eq "P6.2 — « rien · **Parallélisable avec**: Phase 2 » n'est pas une dépendance à 2" "$(G "$WORK/g6.json" 'j.links.filter(l=>l.k==="import").map(l=>l.a+">"+l.b).join(",")')" "n:ph-1>n:ph-2"
assert_eq "P6.3 — règles signalées dans meta.vf.drift" "$(G "$WORK/g6.json" 'j.meta.vf.drift.regles.map(r=>r.regle+":"+r.n).join(",")')" "phase-deux-points:4,depends-on:1,jalons-absents:1,phase-courante-absente:1"
assert_eq "P6.4 — témoin : le lab au gabarit GSD (P1) est conforme" "$(G "$WORK/g1.json" 'j.meta.vf.drift.regles.length')" "0"
git -C "$L6" init -q && git -C "$L6" add -A && git -C "$L6" -c user.email=t@t -c user.name=t commit -qm init
node "$DR" "$L6" --diff > "$WORK/p6.patch"
avant="$(cd "$L6" && git hash-object .planning/ROADMAP.md)"
assert_eq "P6.5 — le détecteur n'écrit rien sur disque" "$(cd "$L6" && git status --porcelain | wc -l | tr -d ' ')|$(cd "$L6" && git hash-object .planning/ROADMAP.md)" "0|$avant"
assert_eq "P6.6 — le correctif proposé s'applique (git apply --check)" "$(git -C "$L6" apply --check "$WORK/p6.patch" && echo ok)" "ok"
git -C "$L6" apply "$WORK/p6.patch"
graph "$L6" "$WORK/g6b.json"
assert_eq "P6.7 — après correctif : reste seulement la phase courante, non devinable" "$(G "$WORK/g6b.json" 'j.meta.vf.drift.regles.map(r=>r.regle).join(",")')" "phase-courante-absente"
assert_eq "P6.8 — après correctif : jalon v2.0 réel, même lecture des phases" "$(G "$WORK/g6b.json" 'j.nodes.filter(n=>n.kind==="jalon").map(n=>n.label).join(",")')|$(G "$WORK/g6b.json" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.id+":"+n.st).join(",")')" "v2.0|ph-1:done,ph-2:todo"
printf -- '- [ ] Phase 1 — sans deux-points\n' | wr "$L6/x/.planning/ROADMAP.md"
assert_eq "P6.9 — phases citées mais illisibles : niveau bloquant" "$(node "$DR" "$L6/x" --json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).constats.filter(c=>c.niveau==="bloquant").map(c=>c.regle).join(",")))')" "phases-illisibles"

# P6.10-14 — relecture adverse SOBR-04 de v2.75.1 : coupe au champ suivant, gras dans la valeur, « aucune » suivi d'un ordre,
# correctif sur un ROADMAP sans « ## Phases » et sans saut de ligne final, statut de jalon clos
L7="$WORK/p7"; B="$L7/.planning"; mkdir -p "$B"
printf '%s\n' '# Roadmap' '' '- [ ] **Phase 1: Un** - a' '- [ ] **Phase 2: Deux** - b' '- [ ] **Phase 3: Trois** - c' '- [ ] **Phase 4: Quatre** - d' '- [ ] **Phase 5: Cinq** - e' '' \
  '### Phase 3: Trois' '**Depends on**: Phase 1 · **Parallélisable avec**: Phase 2' '' \
  '### Phase 4: Quatre' '**Depends on**: Phase 1 **et Phase 2** (ordre)' '' \
  '### Phase 5: Cinq' '**Depends on**: aucune dépendance de code ; après 4' > "$B/ROADMAP.md"
printf -- '---\nstatus: milestone_complete\n---\n' > "$B/STATE.md"
graph "$L7" "$WORK/g7.json"
deps() { G "$WORK/g7.json" "j.links.filter(l=>l.k===\"import\"&&l.b===\"n:ph-$1\").map(l=>l.a.slice(5)).sort().join(\",\")"; }
assert_eq "P6.10 — « Phase 1 · **Parallélisable avec**: Phase 2 » : dépend de 1 seulement" "$(deps 3)" "1"
assert_eq "P6.11 — « Phase 1 **et Phase 2** » : le gras ne coupe pas la valeur" "$(deps 4)" "1,2"
assert_eq "P6.12 — « aucune dépendance de code ; après 4 » garde 4" "$(deps 5)" "4"
assert_eq "P6.13 — statut milestone_complete : pas de phase-courante-absente" "$(G "$WORK/g7.json" 'j.meta.vf.drift.regles.map(r=>r.regle).join(",")')" "depends-on,jalons-absents"
printf '%s' "$(cat "$B/ROADMAP.md")" > "$B/ROADMAP.md"   # sans saut de ligne final
node "$DR" "$L7" --diff > "$WORK/p7.patch"
assert_eq "P6.14 — correctif sans « ## Phases » ni saut final : appliqué, puis conforme" "$( (cd "$L7" && git apply "$WORK/p7.patch") && node "$DR" "$L7" | head -1)" "Format de la planification conforme."

# ---------- P4 — contrat, syntaxe, aucun nom de compartiment de ce dépôt ----------
echo "=== P4 — contrat et généralité ==="
for n in 1 2 3 5 6; do assert_eq "P4.$n — graphe $n conforme au contrat" "$(node "$AUX/validate.mjs" "$IFACE" vibeflow/cockpit-project@1 "$WORK/g$n.json")" "OK"; done
BAD=0; for f in "$SCRIPTS"/vf-cockpit-*.mjs; do node --check "$f" || BAD=$((BAD+1)); done
assert_eq "P4.6 — node --check passe sur chaque .mjs du socle" "$BAD" "0"
printf '%s\n' "const w = 'fiabilite';" > "$WORK/temoin.mjs"
assert_eq "P4.7 — témoin positif : le contrôle de noms voit un nom codé en dur" "$(cat "$WORK/temoin.mjs" | grep -cE 'fiabilite|gouvernance')" "1"
assert_eq "P4.8 — aucun nom de compartiment de ce dépôt dans les sources du socle" "$(cat "$SCRIPTS"/vf-cockpit-*.mjs | grep -cE 'fiabilite|gouvernance')" "0"

# O4 (recette 3, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : la visite « Par où commencer » revenait à chaque chargement et recouvrait la réponse. Cause : son « déjà vue » vivait dans le localStorage
# de l'ORIGINE (port compris) et le port du serveur changeait à chaque lancement. Décision (même date, « C : port stable par lab ») : port stable par lab (vf-cockpit-port.mjs), « déjà vue » en localStorage seul,
# par lab (vibeflow-cockpit:visite:<lab>, 75-vf-modele.js), aucun cookie. Serveurs lancés par le VRAI lanceur (vf-cockpit.mjs), plage de ports décalée (VF_COCKPIT_PORT_BASE : 4378 et 4379 tiennent les serveurs de recette).
# Un Chrome, un profil. Cas : visite au premier chargement ; fermée (croix) puis rechargée sur le MÊME port ; fermée (Échap) idem ; passée jusqu'au bout (autre lab) idem ; serveur relancé (même port stable) ;
# bouton qui la rouvre ; aucun cookie. O4.3 (« même lab, AUTRE port ») n'a plus de sens avec le port stable : remplacé par la relance du serveur. Sans navigateur la section est SAUTÉE, jamais comptée comme réussie.
echo "=== O4 — la visite « Par où commencer » ne revient pas d'elle-même : port stable par lab, localStorage seul, aucun cookie ==="
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ O4 SAUTÉ : aucun navigateur (Chrome, Chromium) — la visite par lab n'est PAS vérifiée, non comptée comme réussie"; else
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
SRVPIDS=(); LABS4=()
fin4() { for L in ${LABS4[@]+"${LABS4[@]}"}; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L" >/dev/null 2>&1; done; for p in ${SRVPIDS[@]+"${SRVPIDS[@]}"}; do vf_hyg_stop "$p"; done; vf_hyg_fin; rm -rf "$WORK"; }
trap fin4 EXIT
mklab4() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  LABS4+=("$L")
}
# plage décalée : base prise au hasard au-dessus des ports de recette, jamais 4378..4500
export VF_COCKPIT_PORT_BASE=$((30000 + (RANDOM * 11) % 30000))
adr4() { node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "$1" | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/index.html#p' | head -1; }
pid4() { node "$AUX/get.mjs" "$1/.vibeflow/cockpit/.cache/server.json" 'j.pid' 2>/dev/null || echo 0; }
pref4() { node --input-type=module -e "import('$SCRIPTS/vf-cockpit-port.mjs').then(m=>console.log(m.portPrefere(process.argv[1])))" "$1"; }
# trois labs dont les ports préférés sont éloignés (≥ 25) : jamais de collision, donc jamais de repli, qui rendrait le cas dépendant du hasard des noms de dossier
for i in $(seq 1 80); do L4="$WORK/lab4-$i"; LC4="$WORK/lab4c-$i"; LE4="$WORK/lab4e-$i"; mkdir -p "$L4" "$LC4" "$LE4"; x=$(pref4 "$L4"); y=$(pref4 "$LC4"); z=$(pref4 "$LE4")
  [ $((x>y ? x-y : y-x)) -ge 25 ] && [ $((x>z ? x-z : z-x)) -ge 25 ] && [ $((y>z ? y-z : z-y)) -ge 25 ] && break; done
rmdir "$L4" "$LC4" "$LE4" 2>/dev/null; mklab4 "$L4"; mklab4 "$LC4"; mklab4 "$LE4"
UA="$(adr4 "$L4")"; SRVPIDS+=("$(pid4 "$L4")"); UC="$(adr4 "$LC4")"; SRVPIDS+=("$(pid4 "$LC4")"); UE="$(adr4 "$LE4")"; SRVPIDS+=("$(pid4 "$LE4")")
cat > "$WORK/relance4.sh" <<RELANCE
#!/usr/bin/env bash
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null VF_COCKPIT_PORT_BASE=$VF_COCKPIT_PORT_BASE
for l in "$L4" "$LC4" "$LE4"; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "\$l" >/dev/null 2>&1; done
op() { node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "\$1" | sed -En 's#^Cockpit : (http://127\.0\.0\.1:[0-9]+)/ .*#\1/index.html#p' | head -1; }
c=\$(op "$LC4"); e=\$(op "$LE4"); a=\$(op "$L4"); printf '%s\n%s\n%s\n' "\$a" "\$c" "\$e"
RELANCE
chmod +x "$WORK/relance4.sh"
XV="$(node "$SCRIPTS/tests/chrome-visite.mjs" "$CHROME" "$UA" "$UC" "$UE" "$WORK/relance4.sh")"
SRVPIDS+=("$(pid4 "$L4")" "$(pid4 "$LC4")" "$(pid4 "$LE4")")
[ -n "${DBG:-}" ] && echo "RAW: $XV"
x4() { printf '%s' "$XV" | node "$AUX/get.mjs" /dev/stdin "$1"; }
assert_eq "O4.0 — témoin : deux labs sur deux ports, la mesure a eu lieu sans erreur, le port du lab est celui de l'empreinte" "$([ "$UA" != "$UC" ] && echo distincts)|$(x4 "j.erreur||''")|$([ "${UA##*:}" = "$(node --input-type=module -e "import('$SCRIPTS/vf-cockpit-port.mjs').then(m=>console.log(m.portPrefere(process.argv[1])))" "$L4")/index.html" ] && echo stable)" "distincts||stable"
assert_eq "O4.1 — premier chargement du lab, la visite s'affiche" "$(x4 'j.premiere')" "true"
assert_eq "O4.2 — fermée par la croix, elle ne revient pas au rechargement sur le même port" "$(x4 'j.croix')" "false"
assert_eq "O4.2b — fermée par Échap (troisième lab, vu pour la première fois), elle ne revient pas au rechargement" "$(x4 'j.echap')" "false"
assert_eq "O4.3 — les trois serveurs arrêtés puis relancés dans un autre ordre (même port stable) : elle ne revient pas (page initialisée, lab connu ; adresse identique)" "$(x4 '[j.relance,j.temoins]')|$([ "$(x4 'j.urlRelance')" = "$UA" ] && echo meme-adresse)" "[false,true]|meme-adresse"
assert_eq "O4.4 — le bouton « Par où commencer » la rouvre" "$(x4 'j.bouton')" "true"
assert_eq "O4.5 — un AUTRE lab la voit à son premier chargement (le rangement est par lab, pas global)" "$(x4 'j.autreLab')" "true"
assert_eq "O4.6 — passée jusqu'au bout (autre lab), elle ne revient pas au rechargement" "$(x4 'j.passee')" "false"
assert_eq "O4.7 — aucun cookie posé : document.cookie vide sur chaque page chargée (témoin : au moins 6 relevés)" "$(x4 'j.cookies.filter(Boolean).length')|$(x4 'j.cookies.length>=6')" "0|true"
unset VF_COCKPIT_PORT_BASE
for L in "${LABS4[@]}"; do node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$L" >/dev/null 2>&1; done; for p in "${SRVPIDS[@]}"; do vf_hyg_stop "$p"; done; SRVPIDS=()
vf_hyg_assert
fi

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
