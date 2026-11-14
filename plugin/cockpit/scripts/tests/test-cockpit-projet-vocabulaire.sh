#!/usr/bin/env bash
# test-cockpit-projet-vocabulaire.sh — le panneau de Projet parle le planning (80-11, FORM-08, P80-D-08, D-35, P80-C76-6), un vrai Chrome, sans réseau.
#   PV1 type et parent d'un plan (« Plan », « Dans la phase »), Code inchangé
#   PV2 listes de liens par sens, statut et vague, exigence dite une fois, porte substituée (PV2.5), extension servie sous /_vf/ (PV2.6), porte relue après un
#       aller-retour d'onglet (PV2.7)
#   PV3 ligne d'état d'une phase, synthèse et barre d'un jalon, aucun des mots « Élément », « module », « Mention » sur Projet
# Régime allégé (80-11) : pas de mutant. PV_SCRIPTS = dossier de scripts à bâtir (rejeu sur la base).
# Sans navigateur : SUITE SAUTÉE (exit 0, message explicite), jamais un vert à vide.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
if [ -z "$CHROME" ]; then
  . "$HERE_T/chrome-saut.sh"
  vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — le vocabulaire du panneau de Projet NON vérifié, non compté comme réussi"; exit 0
fi
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0; SC_BASE="${PV_SCRIPTS:-$SCRIPTS}"
. "$HERE_T/couloirs-commun.sh"
mesurer() { REAL_HOME="$REAL_HOME" node "$HERE_T/$1" "$CHROME" "http://127.0.0.1:$PORT" "${2:-}" "${3:-}" 2>"$WORK/mesure.err"; }
sonde() { [ -n "${SONDE:-}" ] && { printf '%s\n' "$1"; cat "$WORK/mesure.err"; }; return 0; }
PL=".planning/phases/01-socle"
mkpv() { # mklab + trois plans (vague 1, vague 2 dépendant du premier, sans vague), exigences R-1 cochée et R-2 non cochée, un fichier de code
  local L="$1" B="$1/.planning"; mklab "$L"
  printf -- '- [x] **R-1**: premier texte\n- [ ] **R-2**: second texte\n\n| R-1 | Phase 1 | Complete |\n| R-2 | Phase 1 | Pending |\n' | wr "$B/REQUIREMENTS.md"
  printf -- '---\nwave: 1\nrequirements: [R-2]\n---\n<objective>Plan un</objective>\n' | wr "$B/phases/01-socle/01-01-PLAN.md"
  printf -- '---\nwave: 2\ndepends_on: [01-01]\nrequirements: [R-1]\n---\n<objective>Plan deux</objective>\n' | wr "$B/phases/01-socle/01-02-PLAN.md"
  printf -- '<objective>Plan trois</objective>\n' | wr "$B/phases/01-socle/01-03-PLAN.md"; rm -f "$B/phases/01-socle/01-02-SUMMARY.md"
  printf 'export const a = 1;\n' | wr "$L/src/a.js"
  git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m vocabulaire
}
mkpvs() { local L="$1"; mkpv "$L"; rm -f "$L/.planning/REQUIREMENTS.md"
  sed -i.bak 's/^requirements:.*$//' "$L"/.planning/phases/01-socle/*-PLAN.md; rm -f "$L"/.planning/phases/01-socle/*.bak
  git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m sans; }
LAB="$WORK/lab"; mkpv "$LAB"
build_serve "$LAB"
assert_eq "PV0 — serveur du lab démarré" "$([ "$PORT" -gt 0 ] && echo oui || echo non)" "oui"

echo "=== PV1 — type et parent d'un plan ==="
R1="$(mesurer chrome-projet-vocabulaire.mjs pv1)"; sonde "$R1"; E1() { E "$1" "$R1"; }
assert_eq "PV1.1 — plan 01-01 : type « Plan » ; ni « Élément » ni « module » dans le panneau" \
  "$(E1 '[j.pv11.kind, /[Éé]lément|module/.test(j.pv11.kind + " " + j.pv11.txt)]')" '["Plan",false]'
assert_eq "PV1.2 — la ligne du parent dit « Dans la phase » suivie de la phase" \
  "$(E1 'j.pv11.secs.flatMap((s) => s.rows).filter((r) => /Dans la phase/.test(r)).map((r) => /Phase 1/.test(r))')" '[true]'
assert_eq "PV1.3 — témoin d'invariance : sur Code, un fichier garde son intitulé d'aujourd'hui (« fichier », mesuré sur la base)" \
  "$(E1 'j.pv13.kind')" 'fichier'
assert_eq "PV1.9 — témoin : aucune section du pilote n'a échoué" "$(E1 'Object.keys(j.erreurs).join()')" ""

echo "=== PV2 — listes, statut, vague, exigences ==="
R2="$(mesurer chrome-projet-vocabulaire.mjs pv2)"; sonde "$R2"; E2() { E "$1" "$R2"; }
assert_eq "PV2.1 — plan 01-02 : « Exigences couvertes » (R-1 Cochée) une seule fois, avant « Dépend de » ; "\
"plan 01-01 : « Attendu par » ; ni « Mentions » ni « Une mention »" \
  "$(E2 '[j.pv21.secs.map((s) => s.h).filter((h) => /Exigences couvertes|Dépend de|Attendu par/.test(h)),
    j.pv21.secs.filter((s) => s.h === "Exigences couvertes").map((s) => s.rows),
    j.pv21b.secs.map((s) => s.h).filter((h) => /Dépend de|Attendu par/.test(h)), /Mention/.test(j.pv21.txt + j.pv21b.txt)]')" \
  '[["Exigences couvertes","Dépend de"],[["R-1 Cochée"]],["Attendu par"],false]'
assert_eq "PV2.2 — plan : « Statut » (mot) et « Vague 2 » / « Sans vague », aucune statistique à 0" \
  "$(E2 '[/Statut/.test(j.pv21.txt) && /Fait/.test(j.pv21.txt), /Vague 2/.test(j.pv21.txt),
    /Sans vague/.test(j.pv22.txt), /Vague 1/.test(j.pv21b.txt), j.pv21.stats,
    /lignes|points d.accès|utilisé par/i.test(j.pv21.txt)]')" \
  '[true,true,true,true,0,false]'
assert_eq "PV2.3 — exigence R-1 (76-08) : plus de carte ni de nœud d'exigence dans le graphe ; elle se lit une fois dans meta.vf.trace.exigences (et dans « Exigences couvertes », PV2.1)" \
  "$(E2 '[j.pv23.carte, j.pv23.noeud, j.pv23.trace]')" '[0,0,1]'
assert_eq "PV2.4 — phase : section « Plans », bouton « Ouvrir la phase »" \
  "$(E2 '[j.pv24.secs.map((s) => s.h).includes("Plans"), j.pv24.actions.includes("Ouvrir la phase")]')" '[true,true]'
assert_eq "PV2.6 — l'extension est servie sous /_vf/ et aucun script en ligne ne porte son code" \
  "$(E2 '[j.pv26.src.length >= 1 && /\/_vf\//.test(j.pv26.src[0]), j.pv26.enligne]')" '[true,0]'
assert_eq "PV2.7 — après un aller-retour d'onglet la porte est recréée, la section lit la porte du moment (R-1, puis FX-1 et FX-2)" \
  "$(E2 '[j.pv27.change, j.pv27.vraie.secs.filter((s) => s.h === "Exigences couvertes").map((s) => s.rows),
    j.pv27.fausse.secs.filter((s) => s.h === "Exigences couvertes").map((s) => s.rows)]')" \
  '[true,[["R-1 Cochée"]],[["FX-1 Cochée","FX-2 Non cochée"]]]'
assert_eq "PV2.9 — témoin : aucune section du pilote n'a échoué" "$(E2 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"
LABS="$WORK/lab-sans"; mkpvs "$LABS"; build_serve "$LABS"
R2B="$(mesurer chrome-projet-vocabulaire.mjs pv2b)"; sonde "$R2B"; E2B() { E "$1" "$R2B"; }; vf_hyg_stop "$SRV"
assert_eq "PV2.5 — porte substituée : le lab n'a aucune exigence (témoin positif) ; fausse porte : "\
"une section « Exigences couvertes » avec FX-1 Cochée et FX-2 Non cochée ; restaurée : plus de section" \
  "$(E2B '[j.pv25.graphe, j.pv25.vraie.secs.filter((s) => s.h === "Exigences couvertes").length,
    j.pv25.fausse.secs.filter((s) => s.h === "Exigences couvertes").map((s) => s.rows),
    j.pv25.restaure.secs.filter((s) => s.h === "Exigences couvertes").length]')" \
  '[[0,0],0,[["FX-1 Cochée","FX-2 Non cochée"]],0]'
assert_eq "PV2.5b — témoin : aucune section du pilote n'a échoué" "$(E2B 'Object.keys(j.erreurs).join()')" ""

echo "=== PV3 — phase, jalon, mots ==="
build_serve "$LAB"
R3="$(mesurer chrome-projet-vocabulaire.mjs pv3)"; sonde "$R3"; E3() { E "$1" "$R3"; }
assert_eq "PV3.1 — phase 1 : sa ligne d'état une fois ; jalon : « N phases faites sur M » et une barre role=progressbar" \
  "$(E3 '[(j.pv31.txt.match(/\d+ plans? sur \d+/g) || []).length, /exigence sur 2/.test(j.pv31.txt),
    /phases? faites? sur 6/.test(j.pv31j.txt), j.pv31j.progress]')" '[1,true,true,1]'
assert_eq "PV3.3 — sur tout nœud et tout élément de Projet : aucun des mots « Élément », « module », « Mention »" \
  "$(E3 '[j.pv33.n > 10, j.pv33.mots]')" '[true,[]]'
assert_eq "PV3.9 — témoin : aucune section du pilote n'a échoué" "$(E3 'Object.keys(j.erreurs).join()')" ""
vf_hyg_stop "$SRV"
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
