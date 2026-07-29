#!/usr/bin/env bash
# test-check-mission-invariants.sh — Suite de vérification de check-mission-invariants.sh (SC5,
# plan 20-05).
#
# Un cas par comportement du contrat (cf. en-tête du script). Fixtures isolées via mktemp -d +
# --path + git init, jamais sur le repo réel. Chaque assertion capture stdout ET le code de
# retour dans deux variables distinctes, assertées séparément — jamais l'une déduite de l'autre.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-mission-invariants.sh"

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

# Ajoute+committe un fichier quelconque dans $1, identité locale fixe.
commit_file() { # <dir> <relpath> <content>
  local d="$1" rel="$2" content="$3"
  mkdir -p "$(dirname "$d/$rel")"
  printf '%s\n' "$content" > "$d/$rel"
  git -C "$d" -c user.email=t@t -c user.name=t add -- "$rel" >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m "add $rel" >/dev/null 2>&1
}

# Écrit un fichier d'invariants à .planning/MISSION-INVARIANTS.md (chemin par défaut) dans $1,
# avec une première section "## Zones de risque" contenant les globs passés verbatim (déjà
# formatés en entrées de liste par l'appelant), puis committe le fichier.
write_invariants() { # <dir> <section1-body>
  local d="$1" body="$2"
  mkdir -p "$d/.planning"
  {
    printf '# Mission Invariants\n\n'
    printf 'Préambule.\n\n'
    printf '## Zones de risque\n\n'
    printf '%s\n' "$body"
    printf '\n## Table des fichiers gelés\n\n'
    printf 'Lue à la demande, jamais recopiée ici — pas un glob dans cette section.\n'
  } > "$d/.planning/MISSION-INVARIANTS.md"
  git -C "$d" -c user.email=t@t -c user.name=t add -- ".planning/MISSION-INVARIANTS.md" >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m "invariants" >/dev/null 2>&1
}

echo "== test-check-mission-invariants =="

# === Cas 1 — glob mort détecté (parmi un glob vivant) → signal nommant CE glob, exit 0 ============
D="$(mk_git_root c1)"
commit_file "$D" "plugin/foo/bar.sh" "x"
write_invariants "$D" "- \`plugin/foo/*.sh\`     # vivant
- \`plugin/does-not-exist/*.sh\`  # mort"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_signal=0; case "$out" in *"[mission-invariants]"*"plugin/does-not-exist/*.sh"*) has_signal=1 ;; esac
not_named_alive=1; case "$out" in *"plugin/foo/*.sh"*) not_named_alive=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ] && [ "$not_named_alive" -eq 1 ]; then
  ok "1 glob mort détecté (parmi un glob vivant) → signal nommant CE glob et lui seul, exit 0"
else
  ko "1 glob mort détecté (parmi un glob vivant) → signal nommant CE glob et lui seul, exit 0" "rc=$rc out=[$out]"
fi

# === Cas 2 — tous les globs vivants → stdout vide, exit 3 ==========================================
D="$(mk_git_root c2)"
commit_file "$D" "plugin/foo/bar.sh" "x"
commit_file "$D" "plugin/baz/qux.sh" "x"
write_invariants "$D" "- \`plugin/foo/*.sh\`     # vivant
- \`plugin/baz/*.sh\`     # vivant aussi"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "2 tous les globs vivants → stdout vide, exit 3"; else ko "2 tous les globs vivants → stdout vide, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 3 — fichier absent au chemin par défaut → stdout vide, exit 3, aucun message stdout ========
D="$(mk_git_root c3)"
commit_file "$D" "plugin/foo/bar.sh" "x"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "3 fichier absent au chemin par défaut → stdout vide, exit 3"; else ko "3 fichier absent au chemin par défaut → stdout vide, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 4 — fichier explicitement désigné et inexistant → stderr non vide, exit 64 =================
D="$(mk_git_root c4)"
errfile="$TMP/c4.err"
out="$(bash "$SCRIPT" --path "$D" --file nope.md 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 64 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "4 --file explicite inexistant → exit 64, stdout vide, stderr non vide"; else ko "4 --file explicite inexistant → exit 64, stdout vide, stderr non vide" "rc=$rc out=[$out] err=[$err]"; fi

# === Cas 5 — première section sans aucun glob → stdout vide, exit 3, diagnostic stderr ==============
D="$(mk_git_root c5)"
write_invariants "$D" "Rien que de la prose ici, aucune entrée de liste."
errfile="$TMP/c5.err"
out="$(bash "$SCRIPT" --path "$D" 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 3 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "5 aucun glob trouvé → stdout vide, exit 3, diagnostic stderr"; else ko "5 aucun glob trouvé → stdout vide, exit 3, diagnostic stderr" "rc=$rc out=[$out] err=[$err]"; fi

# === Cas 6 — hors d'un arbre de travail git → stdout vide, exit 3, aucun message stdout ==============
D="$TMP/not-a-repo"; mkdir -p "$D/.planning"
printf '# x\n\n## Zones de risque\n\n- `plugin/foo/*.sh`\n' > "$D/.planning/MISSION-INVARIANTS.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "6 hors d'un arbre de travail git → stdout vide, exit 3"; else ko "6 hors d'un arbre de travail git → stdout vide, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 7 — argument inconnu → exit 64 ==============================================================
bash "$SCRIPT" --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "7 argument inconnu → exit 64"; else ko "7 argument inconnu → exit 64" "rc=$rc"; fi

# === Cas 7b — --path sans valeur → exit 64 ============================================================
bash "$SCRIPT" --path >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "7b --path sans valeur → exit 64"; else ko "7b --path sans valeur → exit 64" "rc=$rc"; fi

# === Cas 7c — --file sans valeur → exit 64 =============================================================
bash "$SCRIPT" --file >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "7c --file sans valeur → exit 64"; else ko "7c --file sans valeur → exit 64" "rc=$rc"; fi

# === Cas 7d — --hook + --quiet ensemble → exit 64 =======================================================
bash "$SCRIPT" --hook --quiet >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "7d --hook + --quiet ensemble → exit 64"; else ko "7d --hook + --quiet ensemble → exit 64" "rc=$rc"; fi

# === Cas 8 — --help → exit 0, sortie non vide ===========================================================
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "8 --help → exit 0, sortie non vide"; else ko "8 --help → exit 0, sortie non vide" "rc=$rc out=[$out]"; fi

# === Cas 9 — lecture seule : empreinte du dépôt identique avant/après (.git compris) =================
D="$(mk_git_root c9)"
commit_file "$D" "plugin/foo/bar.sh" "x"
write_invariants "$D" "- \`plugin/foo/*.sh\`     # vivant
- \`plugin/does-not-exist/*.sh\`  # mort"
before="$(find "$D" | LC_ALL=C sort)"
bash "$SCRIPT" --path "$D" >/dev/null 2>&1
after="$(find "$D" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "9 lecture seule — empreinte find identique avant/après (.git compris)"; else ko "9 lecture seule — empreinte find identique avant/après (.git compris)" "before=[$before] after=[$after]"; fi

# === Cas 10 — la deuxième section n'est jamais lue (un faux glob qui y traînerait est ignoré) =========
D="$(mk_git_root c10)"
commit_file "$D" "plugin/foo/bar.sh" "x"
mkdir -p "$D/.planning"
{
  printf '# Mission Invariants\n\n## Zones de risque\n\n- `plugin/foo/*.sh`\n\n'
  printf '## Table des fichiers gelés\n\n'
  printf 'Texte qui contient - `plugin/should-not-be-read/*.sh` mais ce n'"'"'est pas la 1re section.\n'
} > "$D/.planning/MISSION-INVARIANTS.md"
git -C "$D" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$D" -c user.email=t@t -c user.name=t commit -q -m invariants >/dev/null 2>&1
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "10 2e section jamais lue — glob de la table des fichiers gelés ignoré"; else ko "10 2e section jamais lue — glob de la table des fichiers gelés ignoré" "rc=$rc out=[$out]"; fi

# === Cas 11 — bash -n passe sur le script (syntaxe) ====================================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "11 bash -n passe sur check-mission-invariants.sh"; else ko "11 bash -n passe sur check-mission-invariants.sh" "syntax error"; fi

# === Cas 12 — --hook préserve le contrat de sortie (signal, exit 0) ====================================
D="$(mk_git_root c12)"
commit_file "$D" "plugin/foo/bar.sh" "x"
write_invariants "$D" "- \`plugin/does-not-exist/*.sh\`  # mort"
out="$(bash "$SCRIPT" --hook --path "$D" 2>/dev/null)"; rc=$?
has_signal=0; case "$out" in *"[mission-invariants]"*) has_signal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_signal" -eq 1 ]; then ok "12 --hook préserve le contrat de sortie (signal, exit 0)"; else ko "12 --hook préserve le contrat de sortie (signal, exit 0)" "rc=$rc out=[$out]"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
