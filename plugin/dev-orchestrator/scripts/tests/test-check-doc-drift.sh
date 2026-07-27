#!/usr/bin/env bash
# test-check-doc-drift.sh — Suite de vérification de check-doc-drift.sh (SIG-03, plan 17-02).
#
# Un cas par piège. Fixtures isolées via mktemp -d + --path + git init, jamais sur le repo réel.
# Territoire neuf : mk_git_root initialise un vrai dépôt git par fixture, branche par défaut
# forcée explicitement, chaque commit passé avec -c user.email=t@t -c user.name=t pour ne jamais
# dépendre d'une identité ou d'une configuration globale de l'hôte.
#
# Piège central (D-08) : les 3 points de frontière du seuil (seuil-1 / seuil / seuil+1) sont
# couverts nommément, chacun capturant stdout ET le code de retour dans deux variables distinctes,
# assertés séparément — jamais une assertion combinée qui déduit l'un de l'autre.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-doc-drift.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Crée $TMP/<name>, un dépôt git vide (branche par défaut forcée, aucune dépendance à la config
# de l'hôte) — rien d'autre, chaque cas construit son propre historique.
mk_git_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  printf '%s' "$d"
}

# Commit un fichier de doc (docs/<name>.md) dans $1, identité locale fixe.
commit_doc() { # <dir> <name>
  local d="$1" name="$2"
  mkdir -p "$d/docs"
  printf 'doc %s\n' "$name" > "$d/docs/$name.md"
  git -C "$d" -c user.email=t@t -c user.name=t add "docs/$name.md" >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m "doc: $name" >/dev/null 2>&1
}

# Commit un README* racine dans $1.
commit_root_readme() { # <dir> [filename]
  local d="$1" name="${2:-README.md}"
  printf 'readme\n' > "$d/$name"
  git -C "$d" -c user.email=t@t -c user.name=t add "$name" >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m "doc: $name" >/dev/null 2>&1
}

# Commit un README.md de MODULE (ne doit jamais compter comme doc) dans $1.
commit_module_readme() { # <dir> <module>
  local d="$1" mod="$2"
  mkdir -p "$d/plugin/$mod"
  printf 'readme module\n' > "$d/plugin/$mod/README.md"
  git -C "$d" -c user.email=t@t -c user.name=t add "plugin/$mod/README.md" >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m "mod readme: $mod" >/dev/null 2>&1
}

# Commit un fichier de code (source<N>.txt) dans $1.
commit_code() { # <dir> <n>
  local d="$1" n="$2"
  printf 'code %s\n' "$n" > "$d/source$n.txt"
  git -C "$d" -c user.email=t@t -c user.name=t add "source$n.txt" >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m "code: $n" >/dev/null 2>&1
}

# Commit N fichiers de code d'un coup (un commit par fichier), pour que les cas de frontière
# seuil-1 / seuil / seuil+1 soient lisibles depuis l'appelant.
commit_n_code() { # <dir> <count> [start-index]
  local d="$1" count="$2" start="${3:-1}" i
  i="$start"
  while [ "$i" -lt "$((start + count))" ]; do
    commit_code "$d" "$i"
    i=$((i + 1))
  done
}

echo "== test-check-doc-drift =="

# === Cas 1 — Hors dépôt git → stdout vide, exit 3 ================================================
D="$TMP/not-a-repo"; mkdir -p "$D"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "1 hors dépôt git → silence, exit 3"; else ko "1 hors dépôt git → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 2 — Dépôt git à 0 commit → stdout vide, exit 3 ===========================================
D="$(mk_git_root c2)"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "2 dépôt à 0 commit → silence, exit 3"; else ko "2 dépôt à 0 commit → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 3 — Commits de code, aucun commit de doc → stdout vide, exit 3 ===========================
D="$(mk_git_root c3)"
commit_n_code "$D" 25
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "3 aucun commit de doc dans l'historique → silence, exit 3"; else ko "3 aucun commit de doc dans l'historique → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 4 — Frontière seuil-1 (défaut 20) : 19 commits de code depuis la doc → silence, exit 3 ===
D="$(mk_git_root c4)"
commit_doc "$D" "alpha"
commit_n_code "$D" 19
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "4 frontière seuil-1 (19/20) → silence, exit 3"; else ko "4 frontière seuil-1 (19/20) → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 5 — Frontière seuil exacte (défaut 20) : 20 commits de code → signal, exit 0 =============
D="$(mk_git_root c5)"
commit_doc "$D" "alpha"
commit_n_code "$D" 20
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_signal=0; case "$out" in *"[doc-drift]"*"20"*) has_signal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ]; then ok "5 frontière seuil exacte (20/20) → signal, exit 0"; else ko "5 frontière seuil exacte (20/20) → signal, exit 0" "rc=$rc out=[$out]"; fi

# === Cas 6 — Frontière seuil+1 (défaut 20) : 21 commits de code → signal, exit 0 ==================
D="$(mk_git_root c6)"
commit_doc "$D" "alpha"
commit_n_code "$D" 21
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_signal=0; case "$out" in *"[doc-drift]"*"21"*) has_signal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ]; then ok "6 frontière seuil+1 (21/20) → signal, exit 0"; else ko "6 frontière seuil+1 (21/20) → signal, exit 0" "rc=$rc out=[$out]"; fi

# === Cas 7 — --threshold 3 sur une fixture à 3 commits de code → signal (seuil réglable) ==========
D="$(mk_git_root c7)"
commit_doc "$D" "alpha"
commit_n_code "$D" 3
out="$(bash "$SCRIPT" --path "$D" --threshold 3 2>/dev/null)"; rc=$?
has_signal=0; case "$out" in *"[doc-drift]"*) has_signal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ]; then ok "7 --threshold 3 sur 3 commits de code → signal"; else ko "7 --threshold 3 sur 3 commits de code → signal" "rc=$rc out=[$out]"; fi

# === Cas 8 — --threshold 0 → signal même à 0 commit de code depuis la doc =========================
D="$(mk_git_root c8)"
commit_doc "$D" "alpha"
out="$(bash "$SCRIPT" --path "$D" --threshold 0 2>/dev/null)"; rc=$?
has_signal=0; case "$out" in *"[doc-drift]"*"0"*) has_signal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ]; then ok "8 --threshold 0 → signal systématique dès un commit de doc"; else ko "8 --threshold 0 → signal systématique dès un commit de doc" "rc=$rc out=[$out]"; fi

# === Cas 9 — --threshold abc → exit 64, stdout vide, message sur stderr ===========================
errfile="$TMP/c9.err"
out="$(bash "$SCRIPT" --threshold abc 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 64 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "9 --threshold abc → exit 64, stdout vide, stderr non vide"; else ko "9 --threshold abc → exit 64, stdout vide, stderr non vide" "rc=$rc out=[$out] err=[$err]"; fi

# === Cas 10 — --threshold -1 → exit 64 =============================================================
bash "$SCRIPT" --threshold -1 >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "10 --threshold -1 → exit 64"; else ko "10 --threshold -1 → exit 64" "rc=$rc"; fi

# === Cas 11 — --threshold sans valeur → exit 64 =====================================================
bash "$SCRIPT" --threshold >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "11 --threshold sans valeur → exit 64"; else ko "11 --threshold sans valeur → exit 64" "rc=$rc"; fi

# === Cas 12 — Commit mixte code + docs/ compte comme commit de doc, compteur repart de 0 ===========
D="$(mk_git_root c12)"
commit_doc "$D" "alpha"
commit_n_code "$D" 5
# commit mixte : touche du code ET docs/
mkdir -p "$D/docs"
printf 'doc mixte\n' > "$D/docs/mixte.md"
printf 'code mixte\n' > "$D/source-mixte.txt"
git -C "$D" -c user.email=t@t -c user.name=t add docs/mixte.md source-mixte.txt >/dev/null 2>&1
git -C "$D" -c user.email=t@t -c user.name=t commit -q -m "mixte" >/dev/null 2>&1
out="$(bash "$SCRIPT" --path "$D" --threshold 0 2>/dev/null)"; rc=$?
has_zero=0; case "$out" in *"[doc-drift] 0 commits"*) has_zero=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_zero" -eq 1 ]; then ok "12 commit mixte code+docs compte comme doc, compteur reparti de 0"; else ko "12 commit mixte code+docs compte comme doc, compteur reparti de 0" "rc=$rc out=[$out]"; fi

# === Cas 13 — README.md de MODULE ne compte pas comme mise à jour de doc ===========================
D="$(mk_git_root c13)"
commit_doc "$D" "alpha"
commit_n_code "$D" 3
commit_module_readme "$D" "some-module"
out="$(bash "$SCRIPT" --path "$D" --threshold 3 2>/dev/null)"; rc=$?
has_signal=0; case "$out" in *"[doc-drift]"*"4"*) has_signal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ]; then ok "13 README.md de module ne compte pas comme doc — compteur poursuit (4)"; else ko "13 README.md de module ne compte pas comme doc — compteur poursuit (4)" "rc=$rc out=[$out]"; fi

# === Cas 14 — README* à la racine compte comme mise à jour de doc, compteur repart de 0 ============
D="$(mk_git_root c14)"
commit_doc "$D" "alpha"
commit_n_code "$D" 5
commit_root_readme "$D"
out="$(bash "$SCRIPT" --path "$D" --threshold 0 2>/dev/null)"; rc=$?
has_zero=0; case "$out" in *"[doc-drift] 0 commits"*) has_zero=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_zero" -eq 1 ]; then ok "14 README* racine compte comme doc — compteur reparti de 0"; else ko "14 README* racine compte comme doc — compteur reparti de 0" "rc=$rc out=[$out]"; fi

# === Cas 15 — --hook + --quiet → exit 64 =============================================================
bash "$SCRIPT" --hook --quiet >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "15 --hook + --quiet ensemble → exit 64"; else ko "15 --hook + --quiet ensemble → exit 64" "rc=$rc"; fi

# === Cas 16 — Argument inconnu → exit 64 ==============================================================
bash "$SCRIPT" --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "16 argument inconnu → exit 64"; else ko "16 argument inconnu → exit 64" "rc=$rc"; fi

# === Cas 17 — --help → exit 0, sortie non vide =========================================================
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "17 --help → exit 0, sortie non vide"; else ko "17 --help → exit 0, sortie non vide" "rc=$rc out=[$out]"; fi

# === Cas 18 — Déterminisme : deux exécutions consécutives, même compte (y compris horodatages égaux)
D="$(mk_git_root c18)"
mkdir -p "$D/docs"
printf 'doc alpha\n' > "$D/docs/alpha.md"
git -C "$D" -c user.email=t@t -c user.name=t add docs/alpha.md >/dev/null 2>&1
GIT_AUTHOR_DATE="2026-01-01T00:00:00" GIT_COMMITTER_DATE="2026-01-01T00:00:00" \
  git -C "$D" -c user.email=t@t -c user.name=t commit -q -m "doc: alpha" >/dev/null 2>&1
printf 'doc beta\n' > "$D/docs/beta.md"
git -C "$D" -c user.email=t@t -c user.name=t add docs/beta.md >/dev/null 2>&1
# Deux commits de doc partageant EXACTEMENT le même horodatage (auteur ET committer) — le piège
# de l'arête "ordering" (backstop) : le choix du dernier commit de doc doit rester déterministe.
GIT_AUTHOR_DATE="2026-01-01T00:00:00" GIT_COMMITTER_DATE="2026-01-01T00:00:00" \
  git -C "$D" -c user.email=t@t -c user.name=t commit -q -m "doc: beta" >/dev/null 2>&1
commit_n_code "$D" 4
out1="$(bash "$SCRIPT" --path "$D" --threshold 0 2>/dev/null)"; rc1=$?
out2="$(bash "$SCRIPT" --path "$D" --threshold 0 2>/dev/null)"; rc2=$?
if [ "$rc1" -eq "$rc2" ] && [ "$out1" = "$out2" ]; then ok "18 déterminisme — deux exécutions consécutives, même compte (horodatages partagés)"; else ko "18 déterminisme — deux exécutions consécutives, même compte (horodatages partagés)" "rc1=$rc1 rc2=$rc2 out1=[$out1] out2=[$out2]"; fi

# === Cas 19 — Lecture seule (D-15) : empreinte find identique avant/après exécution, .git compris ===
D="$(mk_git_root c19)"
commit_doc "$D" "alpha"
commit_n_code "$D" 25
before="$(find "$D" | LC_ALL=C sort)"
bash "$SCRIPT" --path "$D" >/dev/null 2>&1
after="$(find "$D" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "19 lecture seule D-15 — empreinte find identique avant/après (.git compris)"; else ko "19 lecture seule D-15 — empreinte find identique avant/après (.git compris)" "before=[$before] after=[$after]"; fi

# === Cas 20 — bash -n passe sur le script (syntaxe) ==================================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "20 bash -n passe sur check-doc-drift.sh"; else ko "20 bash -n passe sur check-doc-drift.sh" "syntax error"; fi

# === Cas 21 — --hook sur ce dépôt (aucun --path fourni pointe vers un vrai repo git de test) =========
D="$(mk_git_root c21)"
commit_doc "$D" "alpha"
commit_n_code "$D" 25
out="$(bash "$SCRIPT" --hook --path "$D" --threshold 20 2>/dev/null)"; rc=$?
has_signal=0; case "$out" in *"[doc-drift]"*) has_signal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ]; then ok "21 --hook préserve le contrat de sortie (signal, exit 0)"; else ko "21 --hook préserve le contrat de sortie (signal, exit 0)" "rc=$rc out=[$out]"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
