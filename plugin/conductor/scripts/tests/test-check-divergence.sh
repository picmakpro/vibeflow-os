#!/usr/bin/env bash
# test-check-divergence.sh — Suite de vérification de check-divergence.sh (Phase 39, plan 39-01,
# exigence PART-04). Méthodologie reprise de test-check-workstream-pointer.sh : un cas par état du
# contrat, chaque cas construit sa propre fixture dans un mktemp -d, jamais sur le dépôt réel.
# Comparaison de fixtures par `cmp`/`comm`/`cksum`, jamais par `diff` (proxifié et mesuré menteur
# sur ce poste — cf. mémoire project_diff-proxifie-utiliser-comm.md).
#
# Deux cas de DISCRIMINANCE PAR MUTATION ferment la porte au vert à vide :
#   - MUT-1 mute la FIXTURE (S4(a) orphelin non documenté) en enregistrant le numéro manquant au
#     ROADMAP.md du compartiment : le gate doit passer de rouge (1) à vert (0). L'effectivité de la
#     mutation est prouvée par une empreinte de contenu (cksum par fichier), pas seulement par une
#     liste de chemins — éditer un fichier existant ne change AUCUN chemin.
#   - MUT-2 mute le SCRIPT lui-même dans une copie temporaire, en neutralisant la DÉTECTION S2
#     (l'awk de comptage de doublons, pas la valeur de retour de check_s2 — celle-ci est jetée par
#     l'appelant via `|| true`, la neutraliser ne mute donc rien d'observable). La copie du mutant
#     embarque sa dépendance sœur `workstream-policy.sh` : check-divergence.sh la résout par chemin
#     relatif à `$(dirname "$0")` et sort en 2 (non vérifiable) sans elle — un mutant isolé
#     n'atteindrait jamais le signal qu'il prétend neutraliser. La fixture orphan doit rougir sur
#     l'original et rester verte (à tort) sur le mutant. Un mutant qui ne change rien au
#     comportement observé est NON OPPOSABLE et fait échouer la suite — jamais « mutant satisfait ».

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-divergence.sh"
TARGET="$SCRIPT"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

run() { # <path> <args...> — environnement d'invocation TOUJOURS explicite, jamais hérité
  local path="$1"; shift
  env -u GSD_WORKSTREAM -u VF_WORKSTREAM -u VF_WORKSTREAM_PLANNING_DIR \
    bash "$TARGET" --path "$path" "$@" 2>&1
}

mk_git_root() { # <name> -> imprime le chemin d'un dépôt git vide
  local d="$TMP/$1"
  mkdir -p "$d"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  printf '%s' "$d"
}

fingerprint_content() { # <dir> -> stdout : "<relpath>\t<cksum>" trié, une ligne par fichier
  local base="$1" f rel h
  find "$base" -type f | LC_ALL=C sort | while IFS= read -r f; do
    h="$(cksum "$f" | awk '{print $1"-"$2}')"
    rel="${f#"$base"/}"
    printf '%s\t%s\n' "$rel" "$h"
  done
}

echo "== test-check-divergence =="

# === Cas 1 — nominal, régression du mélange padding (D1, deuxième passe de correction) ============
# Dossiers zero-paddés (01-/02-/03-), en-têtes ROADMAP NON paddés (### Phase 1/2/3 — la convention
# réelle de ce dépôt). Une comparaison non normalisée ferait rougir ce cas à tort (S4(a) nommerait
# 01/02/03 orphelins). Doit rester vert.
D="$(mk_git_root c1)"
mkdir -p "$D/.planning/workstreams/alpha/phases/01-un" \
         "$D/.planning/workstreams/alpha/phases/02-deux" \
         "$D/.planning/workstreams/alpha/phases/03-trois"
printf '%s\n' "### Phase 1: un" "### Phase 2: deux" "### Phase 3: trois" > "$D/.planning/workstreams/alpha/ROADMAP.md"
printf '%s\n' "---" "progress:" "  completed_phases: 3" "---" > "$D/.planning/workstreams/alpha/STATE.md"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -qE 'S2 :|S4\(a\)|S4\(b\)|S5 :'; then
  ok "1 nominal (dossiers paddés / en-têtes non paddés) → exit 0, aucune divergence"
else ko "1 nominal padding-mismatch" "rc=$rc out=[$out]"; fi

# === Cas 2 — dépôt NON PARTITIONNÉ (.planning/workstreams/ absent) → exit 3, stdout vide ===========
D="$(mk_git_root c2)"
mkdir -p "$D/.planning"
out="$(run "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "2 non partitionné → exit 3, stdout vide"
else ko "2 non partitionné" "rc=$rc out=[$out]"; fi

# === Cas 3 — orphan (S2), forme numérique NUE : deux dossiers partagent le même préfixe ===========
D="$(mk_git_root c3)"
mkdir -p "$D/.planning/workstreams/beta/phases/01-x" "$D/.planning/workstreams/beta/phases/01-y"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qF 'S2' && printf '%s' "$out" | grep -qF '01-x' && printf '%s' "$out" | grep -qF '01-y'; then
  ok "3 orphan (nue) → exit 1, S2 nomme les deux dossiers dupliqués"
else ko "3 orphan nue" "rc=$rc out=[$out]"; fi

# === Cas 4 — orphan (S2), forme VFDO-NN-slug (C1, régression 2026-09-10) ===========================
D="$(mk_git_root c4)"
mkdir -p "$D/.planning/workstreams/gamma/phases/VFDO-05-x-registered" \
         "$D/.planning/workstreams/gamma/phases/VFDO-05-y-orphan"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qF 'S2' && printf '%s' "$out" | grep -qF '5' \
   && printf '%s' "$out" | grep -qF 'VFDO-05-x-registered' && printf '%s' "$out" | grep -qF 'VFDO-05-y-orphan'; then
  ok "4 orphan VFDO-NN-slug → exit 1, S2 extrait 5 des deux formes préfixées"
else ko "4 orphan VFDO-NN-slug" "rc=$rc out=[$out]"; fi

# === Cas 5 — rootonly (S5) : un numéro de phase de workstream fuit au ROADMAP RACINE ===============
D="$(mk_git_root c5)"
mkdir -p "$D/.planning/workstreams/delta/phases/06-fuite"
printf '%s\n' "### Phase 6: leaked" > "$D/.planning/ROADMAP.md"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qF 'S5' && printf '%s' "$out" | grep -qF 'delta' && printf '%s' "$out" | grep -qF '6'; then
  ok "5 rootonly → exit 1, S5 nomme le workstream delta et le numéro 6 fuité"
else ko "5 rootonly" "rc=$rc out=[$out]"; fi

# === Cas 6 — S4(a) : orphelin non documenté (dossier present, en-tête ROADMAP absent) ==============
D="$(mk_git_root c6)"
mkdir -p "$D/.planning/workstreams/eps/phases/01-un" \
         "$D/.planning/workstreams/eps/phases/02-deux" \
         "$D/.planning/workstreams/eps/phases/03-trois"
printf '%s\n' "### Phase 1: un" "### Phase 2: deux" > "$D/.planning/workstreams/eps/ROADMAP.md"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qF 'S4(a)' && printf '%s' "$out" | grep -qF '3' \
   && ! printf '%s' "$out" | grep -qF 'S2'; then
  ok "6 S4(a) orphelin non documenté → exit 1, nomme 3, ne déclenche PAS S2"
else ko "6 S4(a) orphelin" "rc=$rc out=[$out]"; fi

# === Cas 7 — S4(b), sous-cas GREATER-THAN : completed_phases > nombre de dossiers =================
D="$(mk_git_root c7)"
mkdir -p "$D/.planning/workstreams/zeta/phases/01-un" "$D/.planning/workstreams/zeta/phases/02-deux"
printf '%s\n' "### Phase 1: un" "### Phase 2: deux" > "$D/.planning/workstreams/zeta/ROADMAP.md"
printf '%s\n' "---" "progress:" "  completed_phases: 5" "---" > "$D/.planning/workstreams/zeta/STATE.md"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qF 'S4(b)' && printf '%s' "$out" | grep -qF '5' && printf '%s' "$out" | grep -qF '2'; then
  ok "7 S4(b) completed_phases=5 > 2 dossiers → exit 1, nomme les deux nombres"
else ko "7 S4(b) greater-than" "rc=$rc out=[$out]"; fi

# === Cas 8 — S4(b), régression LESS-THAN : completed_phases < nombre de dossiers (normal) =========
D="$(mk_git_root c8)"
mkdir -p "$D/.planning/workstreams/zeta2/phases/01-un" "$D/.planning/workstreams/zeta2/phases/02-deux"
printf '%s\n' "### Phase 1: un" "### Phase 2: deux" > "$D/.planning/workstreams/zeta2/ROADMAP.md"
printf '%s\n' "---" "progress:" "  completed_phases: 1" "---" > "$D/.planning/workstreams/zeta2/STATE.md"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -qE 'S2 :|S4\(a\)|S4\(b\)|S5 :'; then
  ok "8 S4(b) completed_phases=1 < 2 dossiers → exit 0 (état normal en cours, garde de non-régression)"
else ko "8 S4(b) less-than" "rc=$rc out=[$out]"; fi

echo ""
echo "== mutants =="

# === MUT-1 — mutation de FIXTURE : enregistrer le numéro manquant fait passer S4(a) de rouge à vert
D="$(mk_git_root mut1)"
mkdir -p "$D/.planning/workstreams/eta/phases/01-un" \
         "$D/.planning/workstreams/eta/phases/02-deux" \
         "$D/.planning/workstreams/eta/phases/03-trois"
printf '%s\n' "### Phase 1: un" "### Phase 2: deux" > "$D/.planning/workstreams/eta/ROADMAP.md"
fingerprint_content "$D" > "$TMP/mut1.before"
out_avant="$(run "$D")"; rc_avant=$?
# la mutation : enregistrer le numéro manquant, RIEN d'autre
printf '%s\n' "### Phase 3: trois" >> "$D/.planning/workstreams/eta/ROADMAP.md"
fingerprint_content "$D" > "$TMP/mut1.after"
if cmp -s "$TMP/mut1.before" "$TMP/mut1.after"; then
  ko "MUT-1 enregistrement du numéro manquant" "l'empreinte de contenu n'a RIEN changé — mutant NON OPPOSABLE, pas mutant satisfait"
else
  changed="$(paste "$TMP/mut1.before" "$TMP/mut1.after" | awk -F'\t' '$2!=$4{print $1; c++} END{if(c!="")print "N="c > "/dev/stderr"}' 2>"$TMP/mut1.count")"
  n_changed=$(printf '%s\n' "$changed" | grep -c . || true)
  out_apres="$(run "$D")"; rc_apres=$?
  if [ "$rc_avant" -eq 1 ] && [ "$rc_apres" -eq 0 ] && [ "$n_changed" -eq 1 ] && [ "$changed" = ".planning/workstreams/eta/ROADMAP.md" ]; then
    ok "MUT-1 enregistrement du numéro manquant (empreinte : SEUL .planning/workstreams/eta/ROADMAP.md a changé) : rouge=1 avant, vert=0 après"
  else
    ko "MUT-1 enregistrement du numéro manquant : rouge → vert" "rc_avant=$rc_avant (attendu 1) rc_apres=$rc_apres (attendu 0) fichiers_changes=[$changed] (attendu exactement .planning/workstreams/eta/ROADMAP.md)"
  fi
fi

# === MUT-2 — mutation du SCRIPT : neutraliser la DÉTECTION S2 (l'awk de comptage de doublons) ======
MUTD="$TMP/mutants"; mkdir -p "$MUTD"
# Dépendance sœur OBLIGATOIRE à côté du mutant : sans elle, check-divergence.sh sort en 2 (non
# vérifiable) avant même d'atteindre check_s2 — le mutant n'atteindrait jamais le signal.
cp "$(dirname "$SCRIPT")/../../planning-core/scripts/workstream-policy.sh" "$MUTD/workstream-policy.sh"
cat > "$MUTD/neutralise-s2.awk" <<'AWKEOF'
{
  if (!fait && index($0, "cnt[k] > 1) print") > 0) {
    sub(/cnt\[k\] > 1\) print/, "cnt[k] > 999999) print")
    fait = 1
  }
  print
}
AWKEOF
MUTANT="$MUTD/check-divergence.mut.sh"
awk -f "$MUTD/neutralise-s2.awk" "$SCRIPT" > "$MUTANT"

D="$(mk_git_root mut2)"
mkdir -p "$D/.planning/workstreams/beta/phases/01-x" "$D/.planning/workstreams/beta/phases/01-y"
if cmp -s "$MUTANT" "$SCRIPT"; then
  ko "MUT-2 détection S2 neutralisée" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
elif ! bash -n "$MUTANT" 2>/dev/null; then
  ko "MUT-2 détection S2 neutralisée" "le mutant n'est pas un script valide : il rougirait pour la mauvaise raison"
else
  TARGET="$MUTANT"
  run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"
  run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then
    ok "MUT-2 détection S2 neutralisée (cmp : script bien muté) : la fixture orphan reste (à tort) VERTE sur le mutant (rc=$rc_mut), et ROUGIT sur l'original (rc=$rc_orig)"
  else
    ko "MUT-2 la fixture orphan doit rougir sur l'original et rester verte (à tort) sur le mutant" "rc_mutant=$rc_mut (attendu 0) rc_original=$rc_orig (attendu 1)"
  fi
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko ($((PASS+FAIL)) cas) =="
[ "$FAIL" -eq 0 ]
