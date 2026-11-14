#!/usr/bin/env bash
# test-cockpit-zoom-garde.sh — cadrage unique, zoom centré, garde de saisie, idiome A51 (80-09, FORM-03, FORM-10, P80-D-12/15/25), un vrai Chrome.
#   ZG1 une formule de cadrage, plancher choisi sur l'onglet chargé · ZG2 zoom centré et réversible, zone basse (--terminal) · ZG3 garde de saisie
#   ZG4 visite, mouvement réduit · ZG5 un seul écouteur de document du clavier du canevas après deux allers-retours d'onglet
#   Régime allégé (message de Samuel, session principale, 2026-11-13) : pas de mutant. ZG_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
# Sans navigateur : SUITE SAUTÉE (exit 0, message explicite), jamais un vert à vide.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur/assets"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le zoom et la garde de saisie NON vérifiés, non comptés comme réussis"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
. "$HERE_T/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() {
  if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:700}]"; FAIL=$((FAIL+1)); fi
}
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
mklab() { # 70 notes dans un dossier (un niveau qui déborde), un module, un projet de 40 étapes (un graphe qui déborde aussi)
  local L="$1" B="$1/.planning" i; mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle" "$L/lots"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n' > "$L/plugin/mod/README.md"; printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  for i in $(seq -w 1 70); do printf '# Note %s\n' "$i" > "$L/lots/n$i.md"; done
  printf '# Titre du projet\n' > "$B/PROJECT.md"
  { printf '# Roadmap\n\n## Jalon démo\n\n'; for i in $(seq 1 40); do printf -- '- [x] **Phase %s: Étape %s** - jet\n' "$i" "$i"; done; printf '\n'
    for i in $(seq 1 40); do printf '### Phase %s: Étape %s\n**Depends on**: Nothing\n\n' "$i" "$i"; done; } > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q -b main && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
# build_serve <lab> [--terminal] -> PORT, SRV, LANCE_RC. Le module est celui de ZG_SCRIPTS s'il est posé, sinon celui du dépôt.
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit" mod="${ZG_SCRIPTS:+$RACINE_BASE}" flag=() pret=port
  [ "${2:-}" = "--terminal" ] && { flag=(--terminal); pret=terminal; }
  node "${mod:-$SCRIPTS/..}/scripts/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  mkdir -p "$WORK/fauxbin" "$O/.cache"; rm -f "$O/.cache/terminal-amorce"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  [ -n "${flag[*]:-}" ] && (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > "$O/.cache/terminal-amorce")
  COCKPIT_MODULE="$mod" COCKPIT_PRET="$pret" COCKPIT_LOG="$WORK/serve.out" cockpit_lancer "$L" PATH="$WORK/fauxbin:$PATH" ${flag[@]+"${flag[@]}"}; LANCE_RC=$?
  SRV="$VF_PID"; PORT="$VF_PORT"
}
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-zoom-garde.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
E() { printf '%s' "${2:-$R}" | node "$AUX/ev.mjs" "$1"; }
SC_BASE="${ZG_SCRIPTS:-$SCRIPTS}"; RACINE_BASE="$(cd "$SC_BASE/.." && pwd -P)"
LAB="$WORK/lab"; mklab "$LAB"; build_serve "$LAB"
assert_eq "ZG0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(mesurer base)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/base.json"
vf_hyg_stop "$SRV"

echo "=== ZG1 — une formule de cadrage, nourrie par le champ de lecture ==="
assert_eq "ZG1.1 — niveau de 70 cartes : après « f », state.t égale VibeFlow.cadrage() (1e-6) et k >= 11/13" \
  "$(E '[j.zg1.a.fn, j.zg1.a.egal, j.zg1.a.plancher]')" '["function",true,true]'
assert_eq "ZG1.2 — #vf-coin affiché : aucune carte entière ne le touche après « f » ; tiroir Git ouvert puis fermé : state.t et freeArea().w inchangés" \
  "$(E '[j.zg1.coin.coin, j.zg1.coin.entieres > 0, j.zg1.coin.touchent, j.zg1.tiroir]')" "[true,true,0,true]"
assert_eq "ZG1.4 — après Projet puis Code (coquille) : premier rendu cadré dans le champ, « f » rend le même state.t, un appel du fournisseur par cadrage" \
  "$(E '[j.zg1.rt.premier, j.zg1.rt.f, j.zg1.rt.appels]')" "[true,true,[1,1]]"
assert_eq "ZG1.5a — Code chargé sous /project.html : plancher 11/13 appliqué (kFit du niveau dessous), pour les deux sources de l'onglet" \
  "$(E 'j.zg1.a1')" '[{"chemin":"/project.html","plafonne":true,"bas":true},{"chemin":"/project.html","plafonne":true,"bas":true}]'
assert_eq "ZG1.5b — Projet chargé sous / : aucun plancher (k = kFit, sous 11/13), pour les deux sources (onglet() puis meta.vfTab)" \
  "$(E 'j.zg1.b1')" '[{"chemin":"/","libre":true,"bas":true,"onglet":"projet"},{"chemin":"/","libre":true,"bas":true,"onglet":null}]'
echo "=== ZG2 — zoom centré, facteurs 1,25 et 0,8, réversible ==="
assert_eq "ZG2.1 — « + » puis « - » : state.t identique (1e-6), facteur 1,25" "$(E '[j.zg2.a.retour, j.zg2.a.facteur]')" "[true,true]"
assert_eq "ZG2.2 — carte sélectionnée visible : son centre écran ne bouge pas (0,5 px)" "$(E 'j.zg2.a.fixe')" "true"
assert_eq "ZG2.3 — sans sélection : le centre du champ de lecture reste fixe, boutons = touches (même facteur, même centre), retour exact" \
  "$(E '[j.zg2.b.touches, j.zg2.b.boutons, j.zg2.b.retour]')" "[true,true,true]"
echo "=== ZG3 — garde de saisie unique ==="
assert_eq "ZG3.1 — « f », « p », « + », Retour arrière dans un TEXTAREA, un SELECT, un contenteditable : vue, panneau et niveau inchangés, lettres tapées" \
  "$(E '[Object.values(j.zg3.champs).every((c) => c.inchange), j.zg3.champs.textarea.texte, j.zg3.champs.editable.texte]')" '[true,"fp","fp"]'
assert_eq "ZG3.2 — Ctrl+p, Alt+f, ⌘f : aucun basculement ni cadrage" "$(E 'j.zg3.modif')" "true"
assert_eq "ZG3.3 — VibeFlow.enSaisie : vrai pour INPUT, TEXTAREA, SELECT, contenteditable, faux pour un div" "$(E 'j.zg3.fn')" "[true,true,true,true,false]"
echo "=== ZG4 — visite et mouvement réduit ==="
assert_eq "ZG4.1 — 40-tour.js cadre par SC.cadrage( ; la formule n'existe plus que dans viewer.html" \
  "$(grep -c 'SC.cadrage(' "$ENG/ui/40-tour.js")|$(grep -rlF 'Math.min(a.w / (b.w + 40)' "$ENG/ui" | wc -l | tr -d ' ')" "1|0"
assert_eq "ZG4.3 — mouvement réduit : aucune animation active après « + », « - », « f »" "$(E '[j.zg4.reduit, j.zg4.actives]')" "[true,[0,0,0]]"
echo "=== ZG5 — idiome A51 du clavier du canevas ==="
assert_eq "ZG5.1 — un seul écouteur de document actif : au chargement, sur Projet, sur Code, après deux allers-retours" "$(E 'j.zg5.actifs')" "[1,1,1,1]"
assert_eq "ZG9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
echo "=== ZG2.4 — zone basse : 390 et 800 px, feuille ouverte puis fermée, pastille « Terminal » ==="
LAB2="$WORK/lab2"; cp -R "$LAB" "$LAB2"; rm -rf "$LAB2/.vibeflow"; build_serve "$LAB2" --terminal
assert_eq "ZG0t — serveur du lab --terminal démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(mesurer term)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/term.json"
vf_hyg_stop "$SRV"
for F in tactile moyen; do for P in ouverte fermee; do
  assert_eq "ZG2.4 ($F, feuille $P) — pastille présente, carte immobile à + puis -, ni #ask, #zoom, pastille ni feuille touchées, centre du champ fixe" \
    "$(E "(() => { const x = j.zg2['$F'] && j.zg2['$F'].$P; if (!x) return 'sans mesure';
      return [x.pastille, x.fixe, x.libre, x.centre, x.retour]; })()")" "[true,true,true,true,true]"
done; done
assert_eq "ZG2.9 — témoin : aucune section du pilote n'a échoué (zone basse)" "$(E 'Object.keys(j.erreurs).join()')" ""
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
