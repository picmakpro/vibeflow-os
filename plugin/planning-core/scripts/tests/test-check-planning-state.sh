#!/usr/bin/env bash
# test-check-planning-state.sh — Tests du garde-fou de fraîcheur de la clé de voûte.
#
# Première suite dédiée à ce script (Phase 41.1 / plan 41.1-03) : il était jusqu'ici le seul script
# du module sans suite propre, seulement effleuré par test-planning-hooks.sh côté câblage.
# Portable, sans réseau. Fixtures temporaires, jamais le dépôt réel.
#
# Ce que cette suite garde en propre : la lecture WORKSTREAM-AWARE ajoutée par le plan 41.1-03 —
# sur un dépôt partitionné, l'absence du STATE.md RACINE n'est plus un défaut (D-01/D-04), et le
# saut de l'énumération n'est jamais silencieux (invariant de mission).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CPS="$SCRIPT_DIR/check-planning-state.sh"
PASS=0; FAIL=0

check_exit() { # <description> <expected_code> <actual_code>
  if [ "$2" -eq "$3" ]; then echo "  ✓ $1 (exit $3)"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu $2, obtenu $3"; FAIL=$((FAIL+1)); fi
}
check_bool() { # <description> <rc_de_la_condition>
  if [ "$2" -eq 0 ]; then echo "  ✓ $1"; PASS=$((PASS+1));
  else echo "  ✗ $1"; FAIL=$((FAIL+1)); fi
}
# Compte les occurrences d'un littéral dans une chaîne, sans `grep` (tronque en pipe sur ce poste).
count_in() { # <chaine> <litteral>
  printf '%s\n' "$1" | awk -v L="$2" 'index($0, L) > 0 { c++ } END { print c+0 }'
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mk_ws() { # <lab> <nom> — frontmatter lu sur stdin
  mkdir -p "$1/.planning/workstreams/$2"
  cat > "$1/.planning/workstreams/$2/STATE.md"
}

echo "== test-check-planning-state =="

# --- Non-régressions : le comportement d'avant la Phase 41.1 sur les dépôts NON partitionnés ------

# Cas 1 : socle absent → lab non amorcé → exit 3.
LAB="$TMP/lab1"; mkdir -p "$LAB"
( cd "$LAB" && bash "$CPS" --quiet ); check_exit "non-régression : aucun socle .planning/ → lab non amorcé" 3 $?

# Cas 2 : vrai lab non amorcé — .planning/ existe, ni STATE.md ni workstreams/ → ABSENT LÉGITIME.
# C'est le cas que la Phase 41.1 laisse INTACT : ici, le message dit vrai.
LAB="$TMP/lab2"; mkdir -p "$LAB/.planning"
out2=$( cd "$LAB" && bash "$CPS" 2>/dev/null ); rc2=$?
check_exit "non-régression : vrai lab non amorcé (ni STATE.md ni workstreams/) → STATE absent" 2 $rc2
check_bool "non-régression : le message ABSENT reste imprimé sur un vrai lab non amorcé" \
  "$( [ "$(count_in "$out2" "ABSENT")" -ge 1 ] && echo 0 || echo 1 )"

# Cas 3 : STATE.md racine frais → OK, stdout STRICTEMENT vide (say_diag va sur stderr, D-06/D-07).
LAB="$TMP/lab3"; mkdir -p "$LAB/.planning"
printf -- '---\nplanning_version: 1.0\nlast_updated: "%s"\n---\n' "$(date +%Y-%m-%d)" > "$LAB/.planning/STATE.md"
out3=$( cd "$LAB" && bash "$CPS" 2>/dev/null ); check_exit "non-régression : STATE.md racine frais" 0 $?
check_bool "non-régression : chemin nominal → stdout strictement vide" "$( [ -z "$out3" ] && echo 0 || echo 1 )"

# Cas 4 : STATE.md racine périmé → exit 1, inchangé.
LAB="$TMP/lab4"; mkdir -p "$LAB/.planning"
printf -- '---\nplanning_version: 1.0\nlast_updated: "2020-01-01"\n---\n' > "$LAB/.planning/STATE.md"
( cd "$LAB" && bash "$CPS" --quiet ); check_exit "non-régression : STATE.md racine périmé" 1 $?

# Cas 5 : argument inconnu → exit 64 (convention des scripts frères).
( cd "$TMP" && bash "$CPS" --nawak 2>/dev/null ); check_exit "non-régression : argument inconnu" 64 $?

# --- Lecture workstream-aware (Phase 41.1 / plan 41.1-03) ---------------------------------------

# Cas 6 (WSAW-PARTITIONNE) : dépôt partitionné, un compartiment conforme, PAS de STATE.md racine ni
# de .planning/phases/ → le message ABSENT cesse d'être imprimé. MESURÉ rouge sur le code d'avant.
LAB="$TMP/lab6"; mkdir -p "$LAB"
mk_ws "$LAB" dev <<'EOF'
---
gsd_state_version: 1.0
milestone: x
current_phase: 1
status: in_progress
---
EOF
out6=$( cd "$LAB" && bash "$CPS" 2>/dev/null ); rc6=$?
check_bool "WSAW-PARTITIONNE : plus de message ABSENT sur un dépôt partitionné (1 compartiment)" \
  "$( [ "$(count_in "$out6" "ABSENT")" -eq 0 ] && echo 0 || echo 1 )"
check_exit "WSAW-PARTITIONNE : le dépôt partitionné n'est plus un écart" 0 $rc6

# Cas 7 (WSAW-PARTITIONNE, volet repli legacy) : MÊME fixture PLUS un .planning/phases/ racine —
# le repli racine legacy est encore en jeu, le message ABSENT reste donc LÉGITIME et l'est.
# Ce cas est la contre-épreuve du précédent : sans lui, « ne jamais imprimer ABSENT » passerait.
LAB="$TMP/lab7"; mkdir -p "$LAB/.planning/phases"
mk_ws "$LAB" dev <<'EOF'
---
gsd_state_version: 1.0
milestone: x
current_phase: 1
status: in_progress
---
EOF
out7=$( cd "$LAB" && bash "$CPS" 2>/dev/null ); rc7=$?
check_bool "WSAW-PARTITIONNE (contre-épreuve) : repli racine legacy (.planning/phases/) → ABSENT conservé" \
  "$( [ "$(count_in "$out7" "ABSENT")" -ge 1 ] && echo 0 || echo 1 )"
check_exit "WSAW-PARTITIONNE (contre-épreuve) : repli racine legacy → exit inchangé" 2 $rc7

# Cas 8 (WSAW-NONINIT) : le cas de référence `gouvernance/STATE.md` — frontmatter à 2 clés, sortie
# nominale de `workstream create` (D-02/D-06). Jamais un échec, jamais un ABSENT.
LAB="$TMP/lab8"; mkdir -p "$LAB"
mk_ws "$LAB" gouvernance <<'EOF'
---
workstream: gouvernance
created: 2026-09-23
---
EOF
out8=$( cd "$LAB" && bash "$CPS" 2>/dev/null ); rc8=$?
check_bool "WSAW-NONINIT : compartiment au frontmatter réduit → pas de message ABSENT" \
  "$( [ "$(count_in "$out8" "ABSENT")" -eq 0 ] && echo 0 || echo 1 )"
check_exit "WSAW-NONINIT : compartiment au frontmatter réduit n'est pas un écart" 0 $rc8

# Cas 9 (DEGRAD-2) : `workstreams/` détourné en LIEN SYMBOLIQUE — `vf_ws_enumerate` rend 2 avec un
# stdout VIDE, indistinguable de rc=3 si le rc était jeté et stderr coupé. Invariant de mission
# « aucune dégradation silencieuse » : le saut doit être ANNONCÉ sur stderr, et le message ne doit
# PAS emprunter le mot ABSENT (l'état n'est pas « rien n'a été créé », il est « on ne peut pas
# savoir »). MESURÉ sur le code d'avant : rc=2, stdout « … est ABSENT … », stderr VIDE.
LAB="$TMP/lab9"; mkdir -p "$LAB/.planning"
ln -s /nonexistent-cible "$LAB/.planning/workstreams"
err9=$( cd "$LAB" && bash "$CPS" 2>&1 >/dev/null )
out9=$( cd "$LAB" && bash "$CPS" 2>/dev/null ); rc9=$?
check_bool "DEGRAD-2 : workstreams/ non vérifiable → le saut est annoncé sur stderr" \
  "$( [ "$(count_in "$err9" "vf_ws_enumerate")" -ge 1 ] && echo 0 || echo 1 )"
check_bool "DEGRAD-2 : état non vérifiable → le message n'emprunte pas le mot ABSENT" \
  "$( [ "$(count_in "$out9" "ABSENT")" -eq 0 ] && echo 0 || echo 1 )"
check_bool "DEGRAD-2 : état non vérifiable → le message le dit (NON VÉRIFIABLE)" \
  "$( [ "$(count_in "$out9" "NON VÉRIFIABLE")" -ge 1 ] && echo 0 || echo 1 )"
check_exit "DEGRAD-2 : contrat de sortie INCHANGÉ sur le chemin non vérifiable" 2 $rc9

# Cas 10 (MUT-1, QUAL-01) : MUTATION — la primitive `vf_ws_enumerate` est neutralisée (stub rendant
# 3, stdout vide) dans une COPIE de la politique ; le script doit alors RETOMBER sur son ancien
# comportement racine-seule (message ABSENT réimprimé) sur la fixture du cas 6. Preuve que c'est
# bien la consommation de la primitive — et non la fixture — qui discrimine. Un TÉMOIN non muté
# encadre la mesure : sans lui, un cas qui rougit pour une tout autre raison passerait pour un
# mutant tué.
MUTD="$TMP/mut-cps"; mkdir -p "$MUTD"
cp "$CPS" "$MUTD/check-planning-state.sh"
cp "$SCRIPT_DIR/workstream-policy.sh" "$MUTD/workstream-policy.sh"
out_temoin=$( cd "$TMP/lab6" && bash "$MUTD/check-planning-state.sh" 2>/dev/null )
printf '\n%s\n' 'vf_ws_enumerate() { return 3; }' >> "$MUTD/workstream-policy.sh"
out_mutant=$( cd "$TMP/lab6" && bash "$MUTD/check-planning-state.sh" 2>/dev/null )
n_temoin=$(count_in "$out_temoin" "ABSENT"); n_mutant=$(count_in "$out_mutant" "ABSENT")
check_bool "MUT-1 : mutant tué — primitive neutralisée → message ABSENT réimprimé (témoin=$n_temoin ABSENT, mutant=$n_mutant ABSENT)" \
  "$( [ "$n_temoin" -eq 0 ] && [ "$n_mutant" -ge 1 ] && echo 0 || echo 1 )"
cmp -s "$CPS" "$MUTD/check-planning-state.sh"
check_bool "MUT-1 (hygiène, vert par construction — ne garde rien, atteste seulement que la mutation est restée confinée à la copie) : le script réel est intact" $?

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
