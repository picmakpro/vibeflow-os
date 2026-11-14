#!/usr/bin/env bash
# test-cockpit-cadrer.sh — « Cadrer la sélection et ses voisins », touche C (80-12, FORM-11, P80-D-17/18/25/45/50), un vrai Chrome.
#   CA1 cadrage du groupe (plancher, mise en page inchangée, Maj, coin et tiroir Git, zone basse --terminal à 390 et 800 px) · CA2 gardes de la touche
#   (copie, saisie, sans sélection, Équipe), mouvement réduit, un seul écouteur après deux allers-retours d'onglet (A51)
#   Régime allégé (message de Samuel, session principale, 2026-11-13) : pas de mutant. CA_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
# Sans navigateur : SUITE SAUTÉE (exit 0, message explicite), jamais un vert à vide.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le cadrage des voisins et la touche C NON vérifiés, \
non comptés comme réussis"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
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
mklab() { # 70 fichiers de code dans src/ (un niveau qui déborde) ; n05 importe n06, n07, n08 (trois voisins) ; un projet pour les allers-retours d'onglet
  local L="$1" B="$1/.planning" i; mkdir -p "$L/src" "$B/phases/01-socle"
  for i in $(seq -w 1 70); do printf 'export const v%s = () => %s;\n' "$i" "$((10#$i))" > "$L/src/n$i.js"; done
  printf "import { v06 } from './n06.js';\nimport { v07 } from './n07.js';\nimport { v08 } from './n08.js';\n" > "$L/src/n05.js"
  printf 'export const v05 = () => v06() + v07() + v08();\n' >> "$L/src/n05.js"
  printf '# Titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - jet\n\n### Phase 1: Socle\n**Depends on**: Nothing\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [src/n01.js]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q -b main && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
# build_serve <lab> [--terminal] -> PORT, SRV, LANCE_RC. Le module est celui de CA_SCRIPTS s'il est posé, sinon celui du dépôt.
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit" mod="${CA_SCRIPTS:+$RACINE_BASE}" flag=() pret=port
  [ "${2:-}" = "--terminal" ] && { flag=(--terminal); pret=terminal; }
  node "${mod:-$SCRIPTS/..}/scripts/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  mkdir -p "$WORK/fauxbin" "$O/.cache"; rm -f "$O/.cache/terminal-amorce"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  [ -n "${flag[*]:-}" ] && (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" > "$O/.cache/terminal-amorce")
  COCKPIT_MODULE="$mod" COCKPIT_PRET="$pret" COCKPIT_LOG="$WORK/serve.out" cockpit_lancer "$L" PATH="$WORK/fauxbin:$PATH" ${flag[@]+"${flag[@]}"}; LANCE_RC=$?
  SRV="$VF_PID"; PORT="$VF_PORT"
}
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-cadrer.mjs" "$CHROME" "http://127.0.0.1:$PORT" "$1" 2>"$WORK/mesure.err"; }
E() { printf '%s' "${2:-$R}" | node "$AUX/ev.mjs" "$1"; }
SC_BASE="${CA_SCRIPTS:-$SCRIPTS}"; RACINE_BASE="$(cd "$SC_BASE/.." && pwd -P)"
LAB="$WORK/lab"; mklab "$LAB"; build_serve "$LAB"
assert_eq "CA0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(mesurer base)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/base.json"
vf_hyg_stop "$SRV"

echo "=== CA1 — la carte sélectionnée et ses voisins, cadrés d'un geste ==="
assert_eq "CA1.1 — Code, 70 cartes, une carte et trois voisins : après « c », state.t = VibeFlow.cadrage({ ids }) (1e-6), k >= 11/13, \
groupe dans le champ de lecture, mise en page identique" \
  "$(E '[j.ca1.a.grp, j.ca1.a.egal, j.ca1.a.plancher, j.ca1.a.dedans, j.ca1.a.layout]')" "[4,true,true,true,true]"
assert_eq "CA1.2 — « C » (Maj) cadre de même ; le focus est sur la carte sélectionnée" "$(E '[j.ca1.b.egal, j.ca1.b.foc]')" "[true,true]"
assert_eq "CA1.3 — #vf-coin affiché, tiroir Git ouvert : aucune carte du groupe ne les touche, la vue a bougé" \
  "$(E '[j.ca1.c.coin, j.ca1.c.tiroir, j.ca1.c.touchent, j.ca1.c.changee]')" "[true,true,[],true]"
echo "=== CA2 — gardes de la touche ==="
assert_eq "CA2.1 — ⌘C, Ctrl+C, Alt+C : la vue ne bouge pas, la copie n'est pas empêchée" \
  "$(E '[j.ca2.copie.inchange, j.ca2.copie.prevenue]')" "[[true,true,true],false]"
assert_eq "CA2.2 — dans un TEXTAREA et un contenteditable : « c » est tapé, la vue ne bouge pas" \
  "$(E '[j.ca2.champs.textarea.inchange, j.ca2.champs.textarea.texte, j.ca2.champs.editable.inchange, j.ca2.champs.editable.texte]')" '[true,"c",true,"c"]'
assert_eq "CA2.3 — sans sélection sur Code : rien ; sur Équipe : rien" "$(E '[j.ca2.sans, j.ca2.equipe]')" "[true,true]"
assert_eq "CA2.4 — mouvement réduit : aucune animation active après « c »" "$(E 'j.ca2.reduit')" "[true,0]"
assert_eq "CA2.5 — un seul écouteur de la touche : au chargement, sur Projet, sur Code, après deux allers-retours ; « c » cadre" \
  "$(E '[j.ca2.actifs, j.ca2.cadre]')" "[[1,1,1,1],true]"
assert_eq "CA9 — témoin : aucune section du pilote n'a échoué" "$(E 'Object.keys(j.erreurs).join()')" ""
echo "=== CA1.4 — zone basse : 390 et 800 px, feuille ouverte puis fermée, pastille « Terminal » ==="
LAB2="$WORK/lab2"; cp -R "$LAB" "$LAB2"; rm -rf "$LAB2/.vibeflow"; build_serve "$LAB2" --terminal
assert_eq "CA0t — serveur du lab --terminal démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"
R="$(mesurer term)"; [ -n "${SONDE:-}" ] && { printf '%s\n' "$R"; cat "$WORK/mesure.err"; }; [ -n "${KEEP:-}" ] && printf '%s\n' "$R" > "$WORK/term.json"
vf_hyg_stop "$SRV"
for F in tactile moyen; do for P in ouverte fermee; do
  assert_eq "CA1.4 ($F, feuille $P) — pastille présente, ni #ask ni feuille touchées par le groupe, carte sélectionnée hors #zoom \
et pastille, k = celui de cadrage({ ids })" \
    "$(E "(() => { const x = j.ca1['$F'] && j.ca1['$F'].$P; if (!x) return 'sans mesure';
      return [x.pastille, x.groupeLibre, x.selLibre, x.k, x.sansRelayout]; })()")" "[true,true,true,true,true]"
done; done
assert_eq "CA9t — témoin : aucune section du pilote n'a échoué (zone basse)" "$(E 'Object.keys(j.erreurs).join()')" ""
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
