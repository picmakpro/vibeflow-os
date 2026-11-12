#!/usr/bin/env bash
# test-cockpit-couloirs.sh — Projet en couloirs (80-04, FORM-05, FORM-07, P80-D-01..D-04, D-07, D-28..D-30, D-37, D-50, D-51), un vrai Chrome, sans réseau.
#   CL1 couloirs par défaut, graphe à ?vue=graphe, section de panneau, adresse de naviguer · CL2 en-tête de jalon, ligne d'état, troncature, listes, XSS, mouvement réduit
#   CL3 clavier, panneau par-dessus, zone basse, visite, direct, focus orphelin, bords latéraux
#   Mutants (copie du module dans $WORK, jamais le module) : M-FOOT, M-XSS, M-POUSSE, M-ORPHELIN, M-EXTREMITE. CL_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
# Sans navigateur : SUITE SAUTÉE (exit 0, message explicite), jamais un vert à vide.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — les couloirs de Projet NON vérifiés, non comptés comme réussis"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() {
  if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi
}
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { console.log('mesure absente : ' + e.message); process.exit(0); }
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mut.mjs" <<'JS'
import fs from 'node:fs'; const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
mklab() { # un jalon en cours (6 phases : 2 faites, 1 en cours, 1 à recetter, 2 à faire), un jalon clos, un backlog de deux entrées, une graine
  local L="$1" B="$1/.planning"
  wr "$B/PROJECT.md" <<< '# Projet de test'
  wr "$B/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **v2.0 Couloirs** - Phases 1-6 (in progress)
- ✅ **v1.0 Socle** - Phase 7 (shipped)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [x] **Phase 2: Écran** - second jet
- [ ] **Phase 3: Liens** - troisième jet
- [ ] **Phase 4: Reprise** - quatrième jet
- [ ] **Phase 5: <img src=x onerror=window.__x=1>** - cinquième jet
- [ ] **Phase 6: Recette** - sixième jet
- [x] **Phase 7: Ancien** - clos
MD
  wr "$B/REQUIREMENTS.md" <<'MD'
- [x] **FORM-01**: premier
- [ ] **FORM-02**: second

| FORM-01 | Phase 1 | Complete |
| FORM-02 | Phase 1 | Pending |
MD
  for n in 01 02; do printf '<objective>Plan %s</objective>\n' "$n" | wr "$B/phases/01-socle/01-$n-PLAN.md"; echo ok > "$B/phases/01-socle/01-$n-SUMMARY.md"; done
  printf '<objective>Écran</objective>\n' | wr "$B/phases/02-ecran/02-01-PLAN.md"; echo ok > "$B/phases/02-ecran/02-01-SUMMARY.md"
  printf '<objective>Liens</objective>\n' | wr "$B/phases/03-liens/03-01-PLAN.md"
  for n in 01 02 03; do printf '<objective>Reprise</objective>\n' | wr "$B/phases/04-reprise/04-$n-PLAN.md"; done; echo ok > "$B/phases/04-reprise/04-01-SUMMARY.md"
  printf '<objective>Recette</objective>\n' | wr "$B/phases/06-recette/06-01-PLAN.md"; echo ok > "$B/phases/06-recette/06-01-SUMMARY.md"
  printf '## Une entrée\n\ntexte\n\n## Autre entrée — DIFFÉRÉ\n\ntexte\n' | wr "$B/BACKLOG.md"
  printf '# Une graine\n\ntexte\n' | wr "$B/seeds/SEED-001-graine.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
# bâtir et servir : build_serve <lab> <dossier de scripts> <dossier du moteur> [options de serve] -> PORT, SRV
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit"; node "$2/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  rm -f "$O/.cache/server.json"; mkdir -p "$WORK/fauxbin"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  ( cd "$L" && PATH="$WORK/fauxbin:$PATH" VF_COCKPIT_ENGINE_DIR="$3" VF_COCKPIT_SCRIPTS_DIR="$2" \
      exec node "$O/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV=$!; PIDS+=($SRV)
  for _ in $(seq 1 300); do grep -q '"port"' "$O/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$O/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-couloirs.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
LAB="$WORK/lab"; mklab "$LAB"
SC_BASE="${CL_SCRIPTS:-$SCRIPTS}"; ln -s "$SC_BASE" "$WORK/scripts-hote"
build_serve "$LAB" "$WORK/scripts-hote" "$SC_BASE/../skills/cockpit-moteur"
assert_eq "CL0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
E() { printf '%s' "${2:-$R1}" | node "$AUX/ev.mjs" "$1"; }
R1="$(mesurer cl1)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R1"; cat "$WORK/mesure.err"; }

echo "=== CL1 — couloirs par défaut, graphe à la demande ==="
assert_eq "CL1.1 — project.html (adresse brute) : 4 couloirs dans le bloc du jalon en cours, canevas caché (visibility hidden)" \
  "$(E '[j.cl11.groupes, j.cl11.svg, j.cl11.jalons >= 1]')" '[4,"hidden",true]'
assert_eq "CL1.2 — ?vue=graphe : canevas visible (cartes rendues), section.vf-projet masquée" \
  "$(E '[j.cl12.svg, j.cl12.cartes > 0, j.cl12.vue]')" '["visible",true,true]'
assert_eq "CL1.3 — P80-C76-1 : après un clic sur la carte de la phase 1, la section du pilote est dans #panel, cible n:ph-1" \
  "$(E '[j.cl13.dans, j.cl13.cible]')" '[true,"n:ph-1"]'
assert_eq "CL1.4 — naviguer sans option ajoute vue=graphe avant le fragment ; une adresse qui a vue= reste telle quelle" \
  "$(E '[j.cl14, j.cl14b]')" '[["?vue=graphe","#s=x"],["?vue=couloirs","#s=x"]]'
assert_eq "CL1.9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
