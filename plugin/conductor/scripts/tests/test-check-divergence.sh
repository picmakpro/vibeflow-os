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

# === Sortie 2 (« non vérifiable ») — NON COUVERTE avant ce lot. Cinq voies mesurées, chacune ======
# asserte le code 2 précisément (jamais « != 0 »), pour fermer les mutations M5/M6/M7/M8/M4 qui
# dégradent silencieusement ces gardes vers 0 (faux vert) ou 3 (faux silence).

run_with_path() { # <path> <path_prefix> — même contrat que run(), PATH préfixé pour intercepter mktemp
  local path="$1" prefix="$2"
  env -u GSD_WORKSTREAM -u VF_WORKSTREAM -u VF_WORKSTREAM_PLANNING_DIR \
    PATH="$prefix:$PATH" \
    bash "$TARGET" --path "$path" 2>&1
}

# === Cas 9 — M5 : `mktemp -d` échoue (rend un code non nul, rien sur stdout) → exit 2 ==============
D="$(mk_git_root c9)"
mkdir -p "$D/.planning/workstreams/mk1/phases/01-un"
FAKEBIN9="$TMP/fakebin-mktemp-fail"; mkdir -p "$FAKEBIN9"
printf '%s\n' '#!/usr/bin/env bash' 'exit 1' > "$FAKEBIN9/mktemp"
chmod +x "$FAKEBIN9/mktemp"
out="$(run_with_path "$D" "$FAKEBIN9")"; rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -qF 'mktemp -d a échoué'; then
  ok "9 mktemp -d échoue → exit 2 (non vérifiable)"
else ko "9 mktemp échoue" "rc=$rc (attendu 2) out=[$out]"; fi

# === Cas 10 — M6 : `mktemp -d` réussit mais rend un chemin qui n'existe pas → exit 2 ===============
D="$(mk_git_root c10)"
mkdir -p "$D/.planning/workstreams/mk2/phases/01-un"
FAKEBIN10="$TMP/fakebin-mktemp-badpath"; mkdir -p "$FAKEBIN10"
printf '%s\n' '#!/usr/bin/env bash' 'echo "/inexistant-check-divergence-$$"' 'exit 0' > "$FAKEBIN10/mktemp"
chmod +x "$FAKEBIN10/mktemp"
out="$(run_with_path "$D" "$FAKEBIN10")"; rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -qF 'dossier temporaire introuvable après mktemp'; then
  ok "10 mktemp -d rend un chemin inexistant → exit 2 (non vérifiable)"
else ko "10 mktemp chemin inexistant" "rc=$rc (attendu 2) out=[$out]"; fi

# === Cas 11 — M7 : workstream-policy.sh introuvable (script isolé, aucune des deux voies de résolution
# relative ne mène à un fichier lisible) → exit 2 ====================================================
ISOD="$TMP/isolated-script"; mkdir -p "$ISOD"
cp "$SCRIPT" "$ISOD/check-divergence.sh"
D="$(mk_git_root c11)"
mkdir -p "$D/.planning/workstreams/mk3/phases/01-un"
_target_save="$TARGET"; TARGET="$ISOD/check-divergence.sh"
out="$(run "$D")"; rc=$?
TARGET="$_target_save"
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -qF 'workstream-policy.sh introuvable'; then
  ok "11 workstream-policy.sh introuvable (script isolé) → exit 2 (non vérifiable)"
else ko "11 policy introuvable" "rc=$rc (attendu 2) out=[$out]"; fi

# === Cas 12 — M8 : --path pointe hors d'un dépôt git → exit 2 ======================================
D="$TMP/c12-nogit"
mkdir -p "$D/.planning/workstreams/mk4/phases/01-un"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -qF "hors d'un dépôt git"; then
  ok "12 --path hors dépôt git → exit 2 (non vérifiable)"
else ko "12 hors dépôt git" "rc=$rc (attendu 2) out=[$out]"; fi

# === Cas 13 — M4 : `.planning/workstreams` est un lien symbolique → exit 2 (jamais 0 ni 3) =========
D="$(mk_git_root c13)"
mkdir -p "$D/.planning/real_ws_target/phases/01-un"
ln -s "$D/.planning/real_ws_target" "$D/.planning/workstreams"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -qF 'est un lien symbolique — refus de le suivre, non vérifiable'; then
  ok "13 workstreams est un lien symbolique → exit 2 (non vérifiable, ni 0 ni 3)"
else ko "13 workstreams symlink" "rc=$rc (attendu 2) out=[$out]"; fi

# === Cas 14 — normalisation base 10 (D1) : « 08-a » et « 8-b » dans le MÊME compartiment doivent ====
# être reconnus comme le MÊME numéro de phase (8) et rougir en S2. Fixture ORDINAIRE (pas de mktemp
# ni de policy détournés) qui démontre le faux vert de M1 : `n=$((08))` échoue en base 8 sous bash,
# une normalisation nue (sans préfixe `10#`) rendrait "8-b" et "08-a" NON dupliqués à tort.
D="$(mk_git_root c14)"
mkdir -p "$D/.planning/workstreams/theta/phases/08-a" "$D/.planning/workstreams/theta/phases/8-b"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qF 'S2' && printf '%s' "$out" | grep -qF '08-a' && printf '%s' "$out" | grep -qF '8-b'; then
  ok "14 normalisation base 10 : 08-a et 8-b dupliquent le numéro 8 → exit 1"
else ko "14 normalisation base 10 (08-a/8-b)" "rc=$rc (attendu 1) out=[$out]"; fi

# === Cas 15 — WSAW-01 : `workstreams/` NON VIDE mais entièrement filtré → exit 2, JAMAIS 0 =======
# Le trou fermé par la Phase 41.1 : avant elle, `workstreams/` contenant uniquement un lien
# symbolique épuisait la boucle inline sans jamais mettre `CHECKED=1`, tombait dans le `else` de fin
# de script (« présent mais vide ») et rendait 0 — un « rien à signaler » sur un état que le gate
# n'avait pas pu inspecter. MESURÉ sur le code d'avant ce plan : rc=0. Désormais `vf_ws_enumerate`
# rend 2 et `check-divergence.sh` PROPAGE ce 2 au lieu de le faire disparaître.
D="$(mk_git_root c15)"
mkdir -p "$D/.planning/workstreams" "$D/.planning/cible-hors-workstreams/phases/01-un"
ln -s "$D/.planning/cible-hors-workstreams" "$D/.planning/workstreams/lien-seul"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -qE 'lien symbolique|non vérifiable'; then
  ok "15 WSAW-01 : workstreams/ non vide mais entièrement filtré (un seul lien symbolique) → exit 2, jamais 0"
else ko "15 WSAW-01 workstreams/ tout-lien" "rc=$rc (attendu 2, le code d'avant la Phase 41.1 rendait 0) out=[$out]"; fi

# === Cas 16 — FLAG-6 : un code de sortie IMPRÉVU de `vf_ws_enumerate` → exit 2, jamais un 0 =======
# `vf_ws_enumerate` n'a que trois codes contractuels (0/2/3, D-01). Ce cas prouve que le `case` de
# `check-divergence.sh` possède une branche par défaut FAIL-CLOSED : sans elle, un quatrième code
# traverserait sans toucher `CHECKED` et le script rendrait 0 en fin de fichier — exactement le
# trou que ce plan ferme. Mutation SUR LA COPIE (même discipline que MUT-2/MUT-3), jamais sur la
# source : `vf_ws_enumerate` est neutralisée en `return 99` dans la copie de `workstream-policy.sh`
# posée à côté de la copie du script — que celui-ci résout en PREMIER candidat.
F6D="$TMP/flag6"; mkdir -p "$F6D"
cp "$SCRIPT" "$F6D/check-divergence.sh"
POLICY_SRC="$(dirname "$SCRIPT")/../../planning-core/scripts/workstream-policy.sh"
awk '
  { print }
  !fait && /^vf_ws_enumerate\(\) \{/ { print "  return 99"; fait = 1 }
' "$POLICY_SRC" > "$F6D/workstream-policy.sh"

D="$(mk_git_root c16)"
mkdir -p "$D/.planning/workstreams/iota/phases/01-un"
printf '%s\n' "### Phase 1: un" > "$D/.planning/workstreams/iota/ROADMAP.md"
if cmp -s "$F6D/workstream-policy.sh" "$POLICY_SRC"; then
  ko "16 FLAG-6 code de sortie imprévu" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
elif ! bash -n "$F6D/workstream-policy.sh" 2>/dev/null; then
  ko "16 FLAG-6 code de sortie imprévu" "la copie mutée n'est pas un script valide : elle rougirait pour la mauvaise raison"
else
  _target_save="$TARGET"; TARGET="$F6D/check-divergence.sh"
  out="$(run "$D")"; rc=$?
  TARGET="$_target_save"
  # Témoin d'opposabilité : la MÊME fixture sur le script NON muté doit être verte (rc=0), sans
  # quoi le 2 observé ci-dessus pourrait venir de la fixture et non de la branche par défaut.
  out_t="$(run "$D")"; rc_t=$?
  if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -qF 'imprévu' && [ "$rc_t" -eq 0 ]; then
    ok "16 FLAG-6 : vf_ws_enumerate rend 99 (hors contrat) → exit 2 sur la branche par défaut, et la même fixture est verte (rc=$rc_t) sur le script non muté"
  else ko "16 FLAG-6 code de sortie imprévu" "rc_mutant=$rc (attendu 2) rc_temoin=$rc_t (attendu 0) out=[$out]"; fi
fi

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

# === MUT-3 — M1 : mutation du SCRIPT, normalisation base-10 dégradée (`n=$((10#$int))` -> `n=$((int))`)
# Cible la ligne de CODE exécutée (pas le commentaire d'en-tête qui cite le même motif entre
# backticks) : awk repère la ligne EXACTE `  n=$((10#$int))`, hors toute ligne commençant par `#`.
# La fixture 08-a/8-b (cas 14) rougit sur l'original ; ce mutant doit la faire passer au vert
# À TORT — c'est le faux vert que l'en-tête du script qualifie de « bloquant, pas un style ».
cat > "$MUTD/neutralise-normalize.awk" <<'AWKEOF'
{
  if (!fait && $0 !~ /^#/ && index($0, "n=$((10#$int))") > 0) {
    sub(/n=\$\(\(10#\$int\)\)/, "n=$((int))")
    fait = 1
  }
  print
}
AWKEOF
MUTANT3="$MUTD/check-divergence.mut3.sh"
awk -f "$MUTD/neutralise-normalize.awk" "$SCRIPT" > "$MUTANT3"

D="$(mk_git_root mut3)"
mkdir -p "$D/.planning/workstreams/theta/phases/08-a" "$D/.planning/workstreams/theta/phases/8-b"
if cmp -s "$MUTANT3" "$SCRIPT"; then
  ko "MUT-3 normalisation base-10 dégradée" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
elif ! bash -n "$MUTANT3" 2>/dev/null; then
  ko "MUT-3 normalisation base-10 dégradée" "le mutant n'est pas un script valide : il rougirait pour la mauvaise raison"
elif ! grep -qxF '  n=$((int))' "$MUTANT3"; then
  ko "MUT-3 normalisation base-10 dégradée" "la ligne de CODE (146) n'a pas été atteinte — la mutation a pu frapper autre chose (commentaire, etc.)"
else
  TARGET="$MUTANT3"
  run "$D" >/dev/null 2>&1; rc_mut3=$?
  TARGET="$SCRIPT"
  run "$D" >/dev/null 2>&1; rc_orig3=$?
  if [ "$rc_mut3" -eq 0 ] && [ "$rc_orig3" -eq 1 ]; then
    ok "MUT-3 normalisation base-10 dégradée (cmp : ligne de code bien mutée) : la fixture 08-a/8-b reste (à tort) VERTE sur le mutant (rc=$rc_mut3), et ROUGIT sur l'original (rc=$rc_orig3)"
  else
    ko "MUT-3 la fixture 08-a/8-b doit rougir sur l'original et rester verte (à tort) sur le mutant" "rc_mutant=$rc_mut3 (attendu 0) rc_original=$rc_orig3 (attendu 1)"
  fi
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko ($((PASS+FAIL)) cas) =="
[ "$FAIL" -eq 0 ]
