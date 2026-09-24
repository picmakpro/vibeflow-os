#!/usr/bin/env bash
# test-check-planning-consumers-registered.sh — Suite de vérification de
# check-planning-consumers-registered.sh (Phase 41.1, plan 41.1-05, D-03 / QUAL-01).
#
# Méthodologie reprise de test-check-divergence.sh : un cas par état du contrat, chaque cas
# construit sa propre fixture dans un `mktemp -d`, jamais sur le dépôt réel. Aucun `diff` (proxifié
# et mesuré menteur sur ce poste) ; `grep` évité au profit d'`awk`.
#
# LIBELLÉS (cherchés littéralement par la recette du plan) : CPR-0, CPR-1, CPR-2, CPR-64, HATCH,
# MUT-1. Un cas non écrit n'imprime pas son libellé, donc la recette rougit.
#
# CE QUE CETTE SUITE PROUVE, ET CE QU'ELLE NE PROUVE PAS. Chaque cas de détection est doublé d'une
# BASCULE INVERSE : sans elle, un rouge seul ne distingue pas « sait détecter » de « rend toujours
# non-zéro ». C'est vrai de l'échappatoire de ligne (HATCH), de l'échappatoire de région
# (CI-REGION) et du mutant de retrait de ligne (MUT-1). Ce que la suite NE prouve pas : que le
# statut inscrit au recensement soit VRAI — le lint vérifie la présence, pas la véracité
# (T-41.1-09, même limite de fond que G-1/G-2/G-3, ADR-072).

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-planning-consumers-registered.sh"
CONSUMERS_REAL="$(cd "$(dirname "$0")/../../references" && pwd)/workstream-planning-consumers.md"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HATCH_LIT="vf-allow-unregistered-planning-path"

run() { # <path> — invocation toujours explicite, jamais un environnement hérité
  env -u VF_CONSUMERS_FILE bash "$SCRIPT" --path "$1" 2>&1
}

mk_git_root() { # <nom> -> imprime le chemin d'un dépôt git initialisé
  local d="$TMP/$1"
  mkdir -p "$d"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  printf '%s' "$d"
}

commit_all() { # <dir>
  git -C "$1" add -A >/dev/null 2>&1
  git -C "$1" -c user.email=t@t.invalid -c user.name=t -c commit.gpgsign=false \
    commit -q -m fixture >/dev/null 2>&1
}

echo "== test-check-planning-consumers-registered =="

# === CPR-0 — le dépôt RÉEL est conforme =========================================================
# C'est la garde de fond du recensement : l'ÉGALITÉ D'ENSEMBLES entre ce que le lint mesure et ce
# que la table déclare. Jamais un nombre de lignes attendu.
rc=0; out="$(env -u VF_CONSUMERS_FILE bash "$SCRIPT" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ]; then
  ok "CPR-0 dépôt réel conforme (rc=0) : tout consommateur détecté figure au recensement"
else
  ko "CPR-0 dépôt réel devrait être conforme" "rc=$rc, attendu 0 — sortie : $out"
fi

# === CPR-1 — un script NEUF non recensé fait rougir ==============================================
D1="$(mk_git_root cpr1)"
mkdir -p "$D1/plugin/x/scripts"
printf '%s\n' '#!/usr/bin/env bash' 'echo .planning/workstreams' > "$D1/plugin/x/scripts/oublie.sh"
commit_all "$D1"
rc=0; out="$(run "$D1")" || rc=$?
named=$(LC_ALL=C awk 'index($0, "plugin/x/scripts/oublie.sh") > 0 { c++ } END { print c+0 }' <<< "$out")
if [ "$rc" -eq 1 ] && [ "$named" -ge 1 ]; then
  ok "CPR-1 script non recensé (rc=1) et NOMMÉ dans le rapport ($named mention(s))"
else
  ko "CPR-1 un script non recensé doit rougir ET être nommé" "rc=$rc (attendu 1), mentions=$named (attendu >=1) — sortie : $out"
fi

# === HATCH — l'échappatoire de LIGNE éteint le signal, et rien d'autre ===========================
# Bascule INVERSE incluse : la MÊME fixture sans le marqueur doit rougir. Sans ce second verdict,
# un rc=0 ne distinguerait pas « le marqueur a agi » de « la ligne n'a jamais matché ».
D2="$(mk_git_root hatch)"
mkdir -p "$D2/plugin/x/scripts"
printf '%s\n' '#!/usr/bin/env bash' "echo .planning/workstreams   # $HATCH_LIT : le littéral EST le sujet" \
  > "$D2/plugin/x/scripts/exempte.sh"
commit_all "$D2"
rc_h=0; out_h="$(run "$D2")" || rc_h=$?
# Contre-épreuve : marqueur retiré, même fichier, même dépôt.
printf '%s\n' '#!/usr/bin/env bash' 'echo .planning/workstreams' > "$D2/plugin/x/scripts/exempte.sh"
commit_all "$D2"
rc_hi=0; run "$D2" >/dev/null 2>&1 || rc_hi=$?
if [ "$rc_h" -eq 0 ] && [ "$rc_hi" -eq 1 ]; then
  ok "HATCH échappatoire de ligne : VERT avec le marqueur (rc=$rc_h), ROUGE sans (rc=$rc_hi) — le marqueur éteint le signal, il ne le fabrique pas"
else
  ko "HATCH le marqueur de ligne doit éteindre le signal, et le signal doit revenir sans lui" "rc_avec=$rc_h (attendu 0) rc_sans=$rc_hi (attendu 1) — sortie : $out_h"
fi

# === CPR-2 — NON VÉRIFIABLE, jamais un vert ======================================================
D3="$TMP/pas-un-depot"; mkdir -p "$D3/plugin/x"
printf '%s\n' '#!/usr/bin/env bash' 'echo .planning/workstreams' > "$D3/plugin/x/y.sh"
rc_g=0; out_g="$(run "$D3")" || rc_g=$?
D4="$(mk_git_root univers-vide)"
printf 'rien\n' > "$D4/README.md"; commit_all "$D4"
rc_v=0; out_v="$(run "$D4")" || rc_v=$?
if [ "$rc_g" -eq 2 ] && [ "$rc_v" -eq 2 ]; then
  ok "CPR-2 hors dépôt git (rc=$rc_g) ET univers .sh vide (rc=$rc_v) — un gate qui n'a pas pu regarder ne se replie pas sur « rien trouvé »"
else
  ko "CPR-2 les deux états non vérifiables doivent rendre 2" "rc_hors_git=$rc_g (attendu 2) rc_univers_vide=$rc_v (attendu 2) — sorties : $out_g / $out_v"
fi

# === CPR-64 — usage ==============================================================================
rc_u=0; out_u="$(env -u VF_CONSUMERS_FILE bash "$SCRIPT" --inconnu 2>&1)" || rc_u=$?
rc_p=0; env -u VF_CONSUMERS_FILE bash "$SCRIPT" --path >/dev/null 2>&1 || rc_p=$?
if [ "$rc_u" -eq 64 ] && [ "$rc_p" -eq 64 ]; then
  ok "CPR-64 argument inconnu (rc=$rc_u) et --path sans valeur (rc=$rc_p)"
else
  ko "CPR-64 une erreur d'usage doit rendre 64" "rc_inconnu=$rc_u rc_path_nu=$rc_p — sortie : $out_u"
fi

# === MUT-1 — mutant de RETRAIT d'une ligne du recensement (D-03, QUAL-01) ========================
# La seule preuve machine que le lint DÉTECTE un oubli sur le dépôt RÉEL, et pas seulement sur une
# fixture qu'il n'a jamais vue. Le vrai recensement n'est JAMAIS touché : la mutation vit dans une
# COPIE, désignée par VF_CONSUMERS_FILE.
CIBLE="plugin/conductor/scripts/check-divergence.sh"
cp "$CONSUMERS_REAL" "$TMP/consumers-intact.md"
LC_ALL=C awk -v c="$CIBLE" 'index($0, c) == 0 { print }' "$CONSUMERS_REAL" > "$TMP/consumers-mute.md"
n_av=$(LC_ALL=C awk 'END { print NR+0 }' "$TMP/consumers-intact.md")
n_ap=$(LC_ALL=C awk 'END { print NR+0 }' "$TMP/consumers-mute.md")
if [ "$n_ap" -ge "$n_av" ]; then
  ko "MUT-1 mutation INEFFECTIVE : aucune ligne retirée du recensement" "lignes avant=$n_av après=$n_ap — un mutant qui ne mute rien est NON OPPOSABLE"
else
  rc_m=0; out_m="$(VF_CONSUMERS_FILE="$TMP/consumers-mute.md" bash "$SCRIPT" 2>&1)" || rc_m=$?
  rc_i=0; VF_CONSUMERS_FILE="$TMP/consumers-intact.md" bash "$SCRIPT" >/dev/null 2>&1 || rc_i=$?
  named_m=$(LC_ALL=C awk -v c="$CIBLE" 'index($0, c) > 0 { n++ } END { print n+0 }' <<< "$out_m")
  if [ "$rc_m" -eq 1 ] && [ "$rc_i" -eq 0 ] && [ "$named_m" -ge 1 ]; then
    ok "MUT-1 TUÉ : recensement muté ($n_av -> $n_ap lignes) → rc=$rc_m et « $CIBLE » nommé ($named_m fois) ; copie INTACTE → rc=$rc_i"
  else
    ko "MUT-1 le retrait d'une ligne du recensement doit faire rougir le lint sur le dépôt réel" "rc_mutant=$rc_m (attendu 1) rc_intact=$rc_i (attendu 0) mentions=$named_m (attendu >=1) — sortie : $out_m"
  fi
fi

# === CI-REGION — le volet ci.yml et ses DEUX modes de défaut =====================================
# Fixture : un compartiment sur le DISQUE (`zeta`), un `ci.yml` qui le nomme, et un seul `.sh`
# suivi sans littéral de planning — ainsi le verdict ne peut venir QUE du volet ci.yml.
D5="$(mk_git_root ci-region)"
mkdir -p "$D5/.planning/workstreams/zeta" "$D5/.github/workflows" "$D5/s"
printf '%s\n' '#!/usr/bin/env bash' 'echo rien' > "$D5/s/neutre.sh"
write_ci() { # <mode>
  {
    printf '%s\n' 'name: ci' 'on: [push]' 'jobs:' '  gates:' '    steps:'
    case "$1" in
      nu)       printf '%s\n' '      - run: mkdir -p .planning/workstreams/zeta' ;;
      commente) printf '%s\n' '      # mkdir -p .planning/workstreams/zeta' ;;
      region)   printf '%s\n' "      # $HATCH_LIT:begin" \
                              '      - run: mkdir -p .planning/workstreams/zeta' \
                              "      # $HATCH_LIT:end" ;;
      ouvert)   printf '%s\n' "      # $HATCH_LIT:begin" \
                              '      - run: mkdir -p .planning/workstreams/zeta' ;;
    esac
    printf '%s\n' '      - run: echo un' '      - run: echo deux' '      - run: echo trois' \
                  '      - run: echo quatre' '      - run: echo cinq'
  } > "$D5/.github/workflows/ci.yml"
}
write_ci nu;       commit_all "$D5"; rc_nu=0;  out_nu="$(run "$D5")"  || rc_nu=$?
write_ci region;   commit_all "$D5"; rc_rg=0;  out_rg="$(run "$D5")"  || rc_rg=$?
write_ci commente; commit_all "$D5"; rc_cm=0;  rc_cm_out="$(run "$D5")" || rc_cm=$?
write_ci ouvert;   commit_all "$D5"; rc_op=0;  out_op="$(run "$D5")"  || rc_op=$?
nom_nu=$(LC_ALL=C awk 'index($0, "workstreams/zeta") > 0 || index($0, ":zeta") > 0 { c++ } END { print c+0 }' <<< "$out_nu")
if [ "$rc_nu" -eq 1 ] && [ "$nom_nu" -ge 1 ] && [ "$rc_rg" -eq 0 ] && [ "$rc_cm" -eq 0 ] && [ "$rc_op" -eq 2 ]; then
  ok "CI-REGION nom de compartiment en dur : ROUGE nu (rc=$rc_nu, nommé), VERT en région bornée (rc=$rc_rg), VERT en commentaire (rc=$rc_cm), NON VÉRIFIABLE sur région NON REFERMÉE (rc=$rc_op) — l'échappatoire ne peut pas avaler le fichier"
else
  ko "CI-REGION les quatre états du volet ci.yml" "rc_nu=$rc_nu (attendu 1, nommé=$nom_nu) rc_region=$rc_rg (attendu 0) rc_commentaire=$rc_cm (attendu 0) rc_begin_orphelin=$rc_op (attendu 2) — sorties : $out_nu | $out_rg | $rc_cm_out | $out_op"
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko ($((PASS+FAIL)) cas) =="
[ "$FAIL" -eq 0 ]
