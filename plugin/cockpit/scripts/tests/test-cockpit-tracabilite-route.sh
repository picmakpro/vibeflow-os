#!/usr/bin/env bash
# test-cockpit-tracabilite-route.sh — la route GET /api/vf/tracabilite, de bout en bout sur le serveur réel (TRAC-10, TRAC-11 ; P76-D-06 à D-12, D-31, D-38)
#   T10.1-T10.2 vue jalon lue dans l'instantané, accès commun · T10.3-T10.4 sept vues, objet inconnu, clé ambiguë
#   T11.1-T11.3 aucun chemin du poste, dégradations par cas, avant la première collecte
# Labs fabriqués dans mktemp (aucun chemin du poste dans les fichiers écrits), HOME jetable, isolation git. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=a@t.test GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=a@t.test
export GIT_AUTHOR_DATE="2026-01-15T12:00:00" GIT_COMMITTER_DATE="2026-01-15T12:00:00"
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
mkdir -p "${TMPDIR:-/tmp}"; WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || { chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"; }' EXIT
. "$TESTS/hygiene.sh"; vf_hyg_init
. "$TESTS/socle-serveur.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq : $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
# j.mjs <fichier> <expression sur j> : « absent » si l'expression échoue ou rend undefined, « illisible » si le JSON ne se lit pas
cat > "$AUX/j.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[3] + ')')(j); } catch { console.log('absent'); process.exit(0); }
console.log(v === undefined ? 'absent' : typeof v === 'string' ? v : JSON.stringify(v));
JS
J() { node "$AUX/j.mjs" "$1" "$2" 2>/dev/null || echo "illisible"; }
# req.mjs <port> <méthode> <chemin> [en-têtes JSON] : { code, h, b } sur une ligne (aucun en-tête ajouté hors de ceux donnés)
cat > "$AUX/req.mjs" <<'JS'
import http from 'node:http';
const [, , port, methode, chemin, entetes] = process.argv;
const r = http.request({ host: '127.0.0.1', port: Number(port), path: chemin, method: methode, headers: JSON.parse(entetes || '{}'), setHost: false }, (res) => {
  let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => console.log(JSON.stringify({ code: res.statusCode, h: res.headers, b })));
});
r.on('error', (e) => console.log(JSON.stringify({ code: 0, h: {}, b: String(e.message) })));
r.end();
JS
# R <méthode> <chemin> [en-têtes JSON] -> $WORK/r.json (hôte et jeton du serveur lancé posés seulement si aucun en-tête n'est donné)
R() { local h="${3:-}"; [ -n "$h" ] || h="{\"Host\":\"127.0.0.1:$VF_PORT\",\"x-vf-cockpit-token\":\"$VF_JETON\"}"; node "$AUX/req.mjs" "$VF_PORT" "$1" "$2" "$h" > "$WORK/r.json" 2>/dev/null; }

# --- fabrication des labs (même fabrication que test-cockpit-tracabilite-collecte.sh) ---
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
G_() { git "$@"; }
# lab L1 : deux phases, deux exigences, un jalon (copie de 76-04)
lab_l1() {
  local L="$1" D1 D2; lab_base "$L" 2
  wr "$(ledger "$L")" <<'MD'
# Exigences

- [x] **REQ-01**: Première exigence
- [ ] **REQ-02**: Deuxième exigence

| REQ-01 | Phase 1 | Complete |
| REQ-02 | Phase 2 | Pending |
MD
  D1="$(phdir "$L" 01-un)"; mkplan "$D1/01-01-PLAN.md" '[REQ-01]'; mksum "$D1/01-01-SUMMARY.md" 'requirements-completed: REQ-01'
  D2="$(phdir "$L" 02-deux)"; mkplan "$D2/02-01-PLAN.md" '[REQ-02]'
}
# lancer_lab <lab> [NOM=valeur…] : lance le serveur réel puis attend la première collecte (vue=jalon sans « collecte »)
pret() { R GET '/api/vf/tracabilite?vue=jalon'; [ "$(J "$WORK/r.json" 'j.code')" = 200 ] && [ "$(J "$WORK/r.json" 'JSON.parse(j.b).collecte')" = absent ]; }
# build_lab <lab> : assemble la sortie du lab (le serveur de la suite lit la page assemblée)
build_lab() { node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; return 1; }; }
lancer_lab() { local l="$1"; build_lab "$l" && cockpit_lancer "$@" && attendre 20 pret; }

echo "=== T10.1 à T10.2 — vue jalon lue dans l'instantané, derrière les contrôles communs ==="
L1="$WORK/l1"; lab_l1 "$L1"
build_lab "$L1"; cockpit_lancer "$L1"
assert_eq "T10.0 — témoin : le serveur écoute (port et jeton lus)" "$([ "${VF_PORT:-0}" -gt 0 ] && [ "${#VF_JETON}" -ge 16 ] && echo oui || echo non)" "oui"
attendre 20 pret
R GET '/api/vf/tracabilite?vue=jalon'
assert_eq "T10.1 — jalon : 200, schema cockpit-trace@1, etat ok, phases ph-1 et ph-2 avec leur clé" "$(J "$WORK/r.json" "j.code+'|'+(b=>{try{b=JSON.parse(b);return b.schema+'|'+b.etat+'|'+b.jalon.phases.map(p=>p.cle).join()}catch(e){return 'corps-illisible'}})(j.b)")" "200|vibeflow/cockpit-trace@1|ok|ph-1,ph-2"
R GET '/api/vf/tracabilite?vue=jalon' "{\"Host\":\"127.0.0.1:$VF_PORT\"}"
assert_eq "T10.2a — sans jeton : 403" "$(J "$WORK/r.json" 'j.code')" "403"
R POST '/api/vf/tracabilite?vue=jalon'
assert_eq "T10.2b — POST avec jeton : 405" "$(J "$WORK/r.json" 'j.code')" "405"
R GET '/api/vf/inconnu-76'
assert_eq "T10.2c — témoin positif : le même accès sur une route inconnue donne 404 (le 403 de T10.2a vient de l'absence de jeton)" "$(J "$WORK/r.json" 'j.code')" "404"
cockpit_arreter

# --- FIN-DES-SECTIONS ---
echo
echo "Résultat : $PASS passés, $FAIL échoués"
[ "$FAIL" -eq 0 ]
