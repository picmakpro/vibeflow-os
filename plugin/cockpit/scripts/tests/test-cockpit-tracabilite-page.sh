#!/usr/bin/env bash
# test-cockpit-tracabilite-page.sh — la traçabilité au cockpit, côté page : section de phase, preuves attachées, section « Jalon », panneau d'une exigence (76-06)
#   C1.0-C1.2 le fichier neuf est servi, la ligne d'une exigence dans le vrai panneau (serveur réel, Chrome sans tête)
# Lab fabriqué dans mktemp (aucun chemin du poste dans les fichiers écrits), HOME jetable, isolation git. Sans navigateur : suite SAUTÉE (jamais un vert à vide).
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$HERE_T/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — la traçabilité côté page NON vérifiée, non comptée comme réussie"; exit 0; fi
mkdir -p "${TMPDIR:-/tmp}"; WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq : $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { console.log('absent : ' + e.message); process.exit(0); }
console.log(v === undefined ? 'absent' : typeof v === 'string' ? v : JSON.stringify(v));
JS
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
# lab de page : compartiment x, jalon v1, phases 1 (sept exigences : deux contradictions, trois manques, un non lisible, une complète), 2 (REQ-01 sans VERIFICATION),
# 3 (REQ-02 à chaîne complète, sept preuves) et 90 (registre de décisions) ; docs/ADR.md avec ADR-001
mkplan() { # <fichier> <exigences> [<critères…>]
  local f="$1" r="$2"; shift 2; mkdir -p "$(dirname "$f")"
  { printf -- '---\nphase: x\nplan: "01"\nwave: 1\nrequirements: %s\n' "$r"; if [ "$#" -gt 0 ]; then printf 'must_haves:\n  truths:\n'; for c in "$@"; do printf '    - "%s"\n' "$c"; done; fi
    printf -- '---\n\n<objective>But du plan</objective>\n'; } > "$f"
}
mksum() { mkdir -p "$(dirname "$1")"; printf -- '---\n%s\n---\n# Summary\n' "$2" > "$1"; }
mklab() {
  local L="$1" B="$1/.planning/workstreams/x" P
  mkdir -p "$B"
  { printf '# Roadmap\n\n## Milestones\n\n- 🚧 **v1** - Phases 1-3 (in progress)\n\n## Phases\n\n'
    for i in 1 2 3; do printf -- '- [ ] **Phase %s: P%s** - p\n' "$i" "$i"; done; printf '\n'
    for i in 1 2 3; do printf '### Phase %s: P%s\n**Goal**: but %s\n**Depends on**: Nothing\n\n' "$i" "$i" "$i"; done
    printf -- '- [ ] **Phase 90: P90** - p\n\n### Phase 90: P90\n**Goal**: but 90\n**Depends on**: Nothing\n'; } > "$B/ROADMAP.md"
  printf -- '---\nmilestone: v1\nstatus: executing\ncurrent_phase: 1\n---\n' > "$B/STATE.md"
  wr "$B/REQUIREMENTS.md" <<'MD'
# Exigences

- [ ] **REQ-01**: Première exigence de la phase deux
- [x] **REQ-02**: Exigence complète de la phase trois
- [x] **REQ-11**: Exigence complète du socle (P90-D-01, ADR-001, D-04, P95-D-09)
- [ ] **REQ-12**: Exigence au SUMMARY illisible
- [ ] **REQ-13**: Exigence sans SUMMARY mais avec sa ligne de traçabilité
- [ ] **REQ-14**: Exigence sans SUMMARY et sans ligne de traçabilité
- [ ] **REQ-15**: Troisième exigence sans SUMMARY
- [x] **REQ-16**: Exigence cochée sans SUMMARY
- [ ] **REQ-17**: Exigence Complete sans plan

| REQ-01 | Phase 2 | Pending |
| REQ-02 | Phase 3 | Complete |
| REQ-11 | Phase 1 | Complete |
| REQ-12 | Phase 1 | Pending |
| REQ-13 | Phase 1 | Pending |
| REQ-15 | Phase 1 | Pending |
| REQ-16 | Phase 1 | Pending |
| REQ-17 | Phase 1 | Complete |
| REQ-99 | Phase 1 | Pending |
MD
  P="$B/phases/01-socle"; mkplan "$P/01-01-PLAN.md" '[REQ-11, REQ-13, REQ-14, REQ-15, REQ-16]'; mksum "$P/01-01-SUMMARY.md" 'requirements-completed: REQ-11'
  mkplan "$P/01-02-PLAN.md" '[REQ-12]'; mksum "$P/01-02-SUMMARY.md" 'note: sans champ d exigence'
  printf -- '---\nstatus: passed\n---\n# Vérification\n\n| Exigence | Preuve |\n|----------|--------|\n| REQ-11 | ok |\n\nPREUVE-MARQUEUR-76\n' > "$P/01-VERIFICATION.md"
  printf '# Recette\n\n**Statut : faite**\n\nREQ-11 vérifiée.\n' > "$P/01-RECETTE-HUMAINE.md"
  P="$B/phases/02-deux"; mkplan "$P/02-01-PLAN.md" '[REQ-01]'; mksum "$P/02-01-SUMMARY.md" 'requirements-completed: REQ-01'
  P="$B/phases/03-trois"
  for n in 01 02 03; do mkplan "$P/03-$n-PLAN.md" '[REQ-02]' "critère un du plan $n" "critère deux du plan $n" "critère trois du plan $n"; printf '# Trace rouge\n' > "$P/03-$n-RED-TRACE.md"; done
  mksum "$P/03-01-SUMMARY.md" 'requirements-completed: REQ-02'
  printf -- '---\nstatus: passed\n---\n# Vérification\n\n| REQ-02 | ok |\n' > "$P/03-VERIFICATION.md"; printf '# Recette\n\n**Statut : faite**\n\nREQ-02.\n' > "$P/03-RECETTE-HUMAINE.md"
  printf -- '---\nstatus: secured\n---\n# Sécurité\n' > "$P/03-SECURITY.md"; printf -- '---\nstatus: ok\n---\n# Validation\n' > "$P/03-VALIDATION.md"
  wr "$B/phases/90-registre/90-CONTEXT.md" <<'MD'
# Contexte

- **P90-D-01** : première définition (ADR-001)
MD
  wr "$L/docs/ADR.md" <<'MD'
# ADR

## ADR-001 — Premier choix

texte
MD
  printf '.vibeflow/\n' > "$L/.gitignore"; git -C "$L" init -q -b main; git -C "$L" add -A; git -C "$L" commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; }
}
lancer_page() { # <lab> : le serveur tourne sur une COPIE du module (le fichier planté après le démarrage n'entre pas dans le dépôt)
  COCKPIT_MODULE="$(cockpit_module_copie "$WORK/module")" && export COCKPIT_MODULE
  cockpit_lancer "$1"
}
LAB="$WORK/lab"; mklab "$LAB"; lancer_page "$LAB"
pret() { cockpit_get '/api/vf/tracabilite?vue=jalon' > "$WORK/j.json"; [ "$VF_CODE" = 200 ] && ! grep -q '"collecte"' "$WORK/j.json"; }
attendre 30 pret
assert_eq "C0 — témoin : le serveur du lab écoute et la première collecte est faite (route de traçabilité, phases lues)" "$([ "${VF_PORT:-0}" -gt 0 ] && grep -q '"phases"' "$WORK/j.json" && echo oui || echo non)" "oui"
printf 'window.__intrus = 1;\n' > "$COCKPIT_MODULE/skills/cockpit-moteur/assets/ui/74-vf-trace-intrus.js"
H1="$WORK/h1.json"; node "$HERE_T/chrome-tracabilite.mjs" "$CHROME" "http://127.0.0.1:$VF_PORT" c10,c11 > "$H1" 2> "$WORK/h1.err"
E1() { node "$AUX/ev.mjs" "$1" < "$H1"; }
[ -n "${SONDE:-}" ] && { cat "$H1"; cat "$WORK/h1.err"; }

echo "=== C1.0 à C1.2 — le panneau d'une phase porte la ligne de son exigence (tracer) ==="
assert_eq "C1.0 — fichier neuf servi : /_vf/…/74-vf-trace.js répond 200, première ligne « // VibeFlow ( »" "$(E1 'j.c10')" "200|// VibeFlow ("
assert_eq "C1.0b — un 74-vf-trace-intrus.js planté après le démarrage répond 404 (liste fermée au démarrage)" "$(E1 'j.c10intrus')" "404"
assert_eq "C1.1 — select(n:ph-2) : #vf-trace-phase, h3 « Traçabilité », ligne REQ-01 (un button) au mot « manque : VERIFICATION »" "$(E1 'j.c11pose+"|"+j.c11.h3+"|"+(j.c11.lignes||[]).map(l=>l.tag+":"+l.id+":"+l.mot).join()')" "true|Traçabilité|BUTTON:REQ-01:manque : VERIFICATION"
assert_eq "C1.1b — la requête vue au réseau est GET /api/vf/tracabilite?vue=phase&cle=ph-2" "$(E1 'j.c11req.includes("GET /api/vf/tracabilite?vue=phase&cle=ph-2")')" "true"
assert_eq "C1.2 — témoin positif voisin : select(n:ph-3), REQ-02 à chaîne complète, mot « chaîne complète »" "$(E1 'j.c12pose+"|"+(j.c12||[]).filter(l=>l.id==="REQ-02").map(l=>l.mot).join()')" "true|chaîne complète"
assert_eq "C1.x — aucune section n'a échoué par erreur de harnais" "$(E1 'JSON.stringify(j.erreurs)')" "{}"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
