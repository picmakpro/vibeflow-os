#!/usr/bin/env bash
# test-check-branch-claim.sh — Suite de vérification de check-branch-claim.sh (ADR-064,
# quick 260801-17w).
#
# Un cas par comportement du contrat (cf. en-tête du script). Fixtures isolées via mktemp -d +
# --path + git init, jamais sur le repo réel. Chaque assertion capture stdout ET le code de
# retour dans deux variables distinctes, assertées séparément — jamais l'une déduite de l'autre.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-branch-claim.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Dépôt git avec un commit et une branche nommée — le gate refuse un HEAD détaché.
mk_repo() { # <name> <branche> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  printf 'x\n' > "$d/a"
  git -C "$d" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m init >/dev/null 2>&1
  git -C "$d" checkout -q -b "$2" >/dev/null 2>&1
  printf '%s' "$d"
}

# Écrit un meta de lock. heartbeat "now" par défaut ; passer un epoch pour forger un lock périmé.
write_lock() { # <lockdir> <branch> <worktree> [heartbeat_epoch]
  local l="$1" b="$2" w="$3" hb="${4:-$(date +%s)}"
  mkdir -p "$l"
  {
    printf 'owner=mission-test\n'
    printf 'step=exec-1\n'
    [ -n "$b" ] && printf 'branch=%s\n' "$b"
    printf 'worktree=%s\n' "$w"
    printf 'heartbeat_epoch=%s\n' "$hb"
  } > "$l/meta"
}

echo "== test-check-branch-claim =="

# === Cas 1 — aucun lock : état VÉRIFIÉ, donc SAIN (3), jamais INDÉTERMINÉ ========================
D="$(mk_repo c1 feat/lane-a)"
OUT="$(bash "$SCRIPT" --path="$D" --lock="$TMP/pas-de-lock" 2>&1)"; RC=$?
[ "$RC" -eq 3 ] && ok "cas 1 : aucun lock → exit 3 (SAIN)" || ko "cas 1" "exit=$RC attendu 3"
case "$OUT" in *SAIN*) ok "cas 1 : diagnostic dit SAIN" ;; *) ko "cas 1 diagnostic" "$OUT" ;; esac

# === Cas 2 — même branche, AUTRE arbre : le signal attendu (0) ===================================
D="$(mk_repo c2 feat/lane-a)"
write_lock "$TMP/lock2" "feat/lane-a" "/un/autre/arbre"
OUT="$(bash "$SCRIPT" --path="$D" --lock="$TMP/lock2" --hook 2>/dev/null)"; RC=$?
[ "$RC" -eq 0 ] && ok "cas 2 : branche pilotée ailleurs → exit 0" || ko "cas 2" "exit=$RC attendu 0"
case "$OUT" in
  *"[branch-claim]"*"feat/lane-a"*) ok "cas 2 : signal émis, nomme la branche" ;;
  *) ko "cas 2 signal" "stdout=[$OUT]" ;;
esac

# === Cas 3 — même branche, MÊME arbre : les deux sessions se voient, rien à signaler =============
# Discriminant central : c'est l'arbre TIERS qui surprend, pas l'owner.
D="$(mk_repo c3 feat/lane-a)"
write_lock "$TMP/lock3" "feat/lane-a" "$D"
OUT="$(bash "$SCRIPT" --path="$D" --lock="$TMP/lock3" 2>&1)"; RC=$?
[ "$RC" -eq 3 ] && ok "cas 3 : même arbre → exit 3" || ko "cas 3" "exit=$RC attendu 3"

# === Cas 3b — même arbre désigné par un chemin NON normalisé (régression du faux positif) ========
# Le même arbre peut se présenter sous deux écritures selon qui l'interroge : sur macOS `/tmp` est
# un lien vers `/private/tmp`. Une comparaison littérale criait alors à la collision sur son PROPRE
# arbre. Reproduit ici sans dépendre de la topologie de l'hôte : un lien symbolique fabriqué dans
# la fixture, qui désigne le même répertoire par un autre chemin.
D="$(mk_repo c3b feat/lane-a)"
ln -s "$D" "$TMP/lien-vers-c3b" 2>/dev/null || true
if [ -L "$TMP/lien-vers-c3b" ]; then
  write_lock "$TMP/lock3b" "feat/lane-a" "$TMP/lien-vers-c3b"
  RC=0; bash "$SCRIPT" --path="$D" --lock="$TMP/lock3b" --quiet >/dev/null 2>&1 || RC=$?
  [ "$RC" -eq 3 ] && ok "cas 3b : chemin non normalisé du même arbre → exit 3" \
    || ko "cas 3b" "exit=$RC attendu 3 (faux positif de symlink revenu)"
  # Discriminance : le lien ne doit pas rendre le gate aveugle à un arbre RÉELLEMENT tiers.
  write_lock "$TMP/lock3c" "feat/lane-a" "$TMP/pas-le-meme-arbre"
  RC=0; bash "$SCRIPT" --path="$D" --lock="$TMP/lock3c" --quiet >/dev/null 2>&1 || RC=$?
  [ "$RC" -eq 0 ] && ok "cas 3c : arbre réellement tiers → exit 0 (normalisation non aveuglante)" \
    || ko "cas 3c" "exit=$RC attendu 0"
else
  ko "cas 3b" "lien symbolique non créable dans la fixture — cas non exécuté"
fi

# === Cas 4 — autre branche pilotée : SAIN ========================================================
D="$(mk_repo c4 feat/lane-a)"
write_lock "$TMP/lock4" "feat/une-autre" "/un/autre/arbre"
RC=0; bash "$SCRIPT" --path="$D" --lock="$TMP/lock4" --quiet >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 3 ] && ok "cas 4 : autre branche → exit 3" || ko "cas 4" "exit=$RC attendu 3"

# === Cas 5 — lock PÉRIMÉ : traité comme absent, sinon un manager mort gèle le signal =============
D="$(mk_repo c5 feat/lane-a)"
write_lock "$TMP/lock5" "feat/lane-a" "/un/autre/arbre" 1
RC=0; VF_DRIVER_TTL=1800 bash "$SCRIPT" --path="$D" --lock="$TMP/lock5" --quiet >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 3 ] && ok "cas 5 : lock périmé → exit 3" || ko "cas 5" "exit=$RC attendu 3"

# === Cas 5b — le MÊME lock, TTL élargi : redevient actif (discriminance du TTL) ==================
# Sans ce cas, le cas 5 passerait aussi si le gate ignorait la branche pour une autre raison.
# Le TTL doit dépasser l'âge forgé — un heartbeat à l'epoch 1 a l'âge du temps Unix lui-même.
RC=0; VF_DRIVER_TTL=99999999999 bash "$SCRIPT" --path="$D" --lock="$TMP/lock5" --quiet >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 0 ] && ok "cas 5b : même lock sous TTL large → exit 0 (le TTL discrimine)" \
  || ko "cas 5b" "exit=$RC attendu 0"

# === Cas 6 — lock d'une version antérieure (sans champ branch) : INDÉTERMINÉ, jamais SAIN ========
D="$(mk_repo c6 feat/lane-a)"
write_lock "$TMP/lock6" "" "/un/autre/arbre"
OUT="$(bash "$SCRIPT" --path="$D" --lock="$TMP/lock6" 2>&1)"; RC=$?
[ "$RC" -eq 4 ] && ok "cas 6 : lock sans champ branch → exit 4 (INDÉTERMINÉ)" || ko "cas 6" "exit=$RC attendu 4"
case "$OUT" in *INDETERMINE*|*INDÉTERMINÉ*) ok "cas 6 : diagnostic dit INDÉTERMINÉ" ;; *) ko "cas 6 diagnostic" "$OUT" ;; esac

# === Cas 7 — racine hors dépôt git : INDÉTERMINÉ ================================================
NOGIT="$TMP/pas-un-depot"; mkdir -p "$NOGIT"
RC=0; bash "$SCRIPT" --path="$NOGIT" --lock="$TMP/lock2" --quiet >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 4 ] && ok "cas 7 : hors dépôt git → exit 4" || ko "cas 7" "exit=$RC attendu 4"

# === Cas 8 — HEAD détaché : aucune branche à comparer → INDÉTERMINÉ ==============================
D="$(mk_repo c8 feat/lane-a)"
git -C "$D" checkout -q --detach >/dev/null 2>&1
RC=0; bash "$SCRIPT" --path="$D" --lock="$TMP/lock2" --quiet >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 4 ] && ok "cas 8 : HEAD détaché → exit 4" || ko "cas 8" "exit=$RC attendu 4"

# === Cas 9 — erreurs d'usage → 64 ===============================================================
RC=0; bash "$SCRIPT" --argument-inconnu >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 64 ] && ok "cas 9 : argument inconnu → exit 64" || ko "cas 9" "exit=$RC attendu 64"
RC=0; bash "$SCRIPT" --path="$TMP/nexiste-pas" >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 64 ] && ok "cas 9b : --path introuvable → exit 64" || ko "cas 9b" "exit=$RC attendu 64"

# === Cas 10 — silence nominal de --hook : stdout STRICTEMENT vide quand rien à signaler ==========
# Le hook est câblé au SessionStart : une seule ligne parasite en nominal pollue chaque démarrage.
D="$(mk_repo c10 feat/lane-a)"
write_lock "$TMP/lock10" "feat/une-autre" "/un/autre/arbre"
OUT="$(bash "$SCRIPT" --path="$D" --lock="$TMP/lock10" --hook 2>/dev/null)"
[ -z "$OUT" ] && ok "cas 10 : --hook silencieux en nominal (stdout vide)" || ko "cas 10" "stdout=[$OUT]"

# === Cas 11 — --quiet : aucun diagnostic, ni stdout ni stderr, code seul =========================
OUT="$(bash "$SCRIPT" --path="$D" --lock="$TMP/lock10" --quiet 2>&1)"
[ -z "$OUT" ] && ok "cas 11 : --quiet totalement muet" || ko "cas 11" "sortie=[$OUT]"

echo "== Résultat : $PASS OK · $FAIL KO =="
[ "$FAIL" -eq 0 ]
