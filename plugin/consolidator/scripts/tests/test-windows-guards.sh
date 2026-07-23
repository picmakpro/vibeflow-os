#!/usr/bin/env bash
# test-windows-guards.sh — Gardes mémoire réellement ACTIVES sous conditions Windows (ADR-054).
# Reproduit les deux couches du 2e rapport terrain (2026-07-23) sans poste Windows :
#   A. chemins Windows en antislashs (JSON-échappés) → le préfiltre CSL-13 doit laisser passer
#      jusqu'au python, qui doit DENY (avant le fix : allow silencieux, garde inerte).
#   B. `python3` = stub Microsoft Store (présent dans le PATH sous …/WindowsApps/, inerte) →
#      repli `python` par détection de CHEMIN ; aucun interpréteur → fail-open + SIGNAL du probe.
# Convention TESTING.md. BASH_BIN surchargeable (BASH_BIN=/bin/bash pour bash 3.2).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/.." && pwd)"
GUARD_READ="$SCRIPTS/guard-read-registres.sh"
GUARD_BASH="$SCRIPTS/guard-bash-registres.sh"
PROBE="$SCRIPTS/probe-memory-guards.sh"
BASH_BIN="${BASH_BIN:-bash}"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-windows-guards (ADR-054) =="

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Fixture lab : le guard n'agit que sur un registre RÉEL de plus de 150 lignes, ouvert via le
# chemin ORIGINAL du payload. Deux fixtures :
#   - .claude/memory/DECISIONS.md            (forme POSIX)
#   - fichier au NOM LITTÉRAL « .claude\memory\DECISIONS.md » (l'antislash est un caractère
#     de nom légal sous macOS/Linux) → simule l'open() Windows d'un chemin antislashs.
LAB="$WORK/lab"; mkdir -p "$LAB/.claude/memory"
for i in $(seq 1 160); do echo "ligne $i"; done > "$LAB/.claude/memory/DECISIONS.md"
cp "$LAB/.claude/memory/DECISIONS.md" "$LAB/"'.claude\memory\DECISIONS.md'

# Payloads : lecture NON bornée (pas de limit) → deny attendu. Forme Windows = antislashs
# JSON-échappés (un \ de chemin devient \\ dans le flux JSON du harness).
WIN_PAYLOAD='{"tool_name":"Read","tool_input":{"file_path":".claude\\memory\\DECISIONS.md"}}'
POSIX_PAYLOAD='{"tool_name":"Read","tool_input":{"file_path":".claude/memory/DECISIONS.md"}}'

# ---------- T1 : chemin Windows → DENY (le préfiltre ne court-circuite plus) ----------
out=$(printf '%s' "$WIN_PAYLOAD" | ( cd "$LAB" && "$BASH_BIN" "$GUARD_READ" ) 2>/dev/null)
if printf '%s' "$out" | command grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"'; then
  ok "T1 guard-read : chemin antislashs JSON-échappé → DENY émis"
else
  ko "T1 guard-read : chemin antislashs → PAS de deny (garde inerte) — out=[$out]"
fi

# ---------- T2 : régression — chemin POSIX toujours DENY ----------
out=$(printf '%s' "$POSIX_PAYLOAD" | ( cd "$LAB" && "$BASH_BIN" "$GUARD_READ" ) 2>/dev/null)
if printf '%s' "$out" | command grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"'; then
  ok "T2 guard-read : chemin POSIX → DENY (régression néant)"
else
  ko "T2 guard-read : chemin POSIX → plus de deny — out=[$out]"
fi

# ---------- T3 : payload sans rapport → allow silencieux (préfiltre toujours efficace) ----------
out=$(printf '%s' '{"tool_name":"Read","tool_input":{"file_path":"/tmp/notes.md"}}' | "$BASH_BIN" "$GUARD_READ" 2>/dev/null)
if [ -z "$out" ]; then
  ok "T3 guard-read : payload hors registres → allow silencieux (0 spawn python)"
else
  ko "T3 guard-read : sortie inattendue sur payload anodin — out=[$out]"
fi

# ---------- T4 : stub WindowsApps/python3 + vrai python → repli, DENY conservé ----------
REAL_PY="$(command -v python3)"
mkdir -p "$WORK/WindowsApps" "$WORK/bin"
cat > "$WORK/WindowsApps/python3" <<'STUB'
#!/bin/bash
# Simule le stub Microsoft Store : stdout vide, stderr Store, exit 49 (constaté terrain).
echo "Python introuvable ; exécutez sans arguments pour l'installer depuis le Microsoft Store." >&2
exit 49
STUB
chmod +x "$WORK/WindowsApps/python3"
ln -s "$REAL_PY" "$WORK/bin/python"
for t in bash cat printf grep sed awk dirname command timeout head tr uname sort; do
  p=$(command -v "$t" 2>/dev/null) && ln -s "$p" "$WORK/bin/$t" 2>/dev/null
done
out=$(printf '%s' "$WIN_PAYLOAD" | ( cd "$LAB" && env PATH="$WORK/WindowsApps:$WORK/bin" "$BASH_BIN" "$GUARD_READ" ) 2>/dev/null)
if printf '%s' "$out" | command grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"'; then
  ok "T4 guard-read : stub WindowsApps en tête de PATH → repli python, DENY conservé"
else
  ko "T4 guard-read : stub WindowsApps → garde inerte (pas de repli) — out=[$out]"
fi

# ---------- T5 : idem pour guard-bash (commande visant un registre) ----------
BASH_PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"cat .claude/memory/DECISIONS.md"}}'
out=$(printf '%s' "$BASH_PAYLOAD" | ( cd "$LAB" && env PATH="$WORK/WindowsApps:$WORK/bin" "$BASH_BIN" "$GUARD_BASH" ) 2>/dev/null)
if printf '%s' "$out" | command grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"'; then
  ok "T5 guard-bash : stub WindowsApps → repli python, DENY conservé (cat non borné)"
else
  ko "T5 guard-bash : stub WindowsApps → garde inerte — out=[$out]"
fi

# ---------- T6 : AUCUN interpréteur → fail-open (allow) SANS crash ----------
mkdir -p "$WORK/nopy"
for t in bash cat printf grep sed awk dirname command head tr uname sort; do
  p=$(command -v "$t" 2>/dev/null) && ln -s "$p" "$WORK/nopy/$t" 2>/dev/null
done
out=$(printf '%s' "$WIN_PAYLOAD" | ( cd "$LAB" && env PATH="$WORK/nopy" "$BASH_BIN" "$GUARD_READ" ) 2>/dev/null); rc=$?
if [ $rc -eq 0 ] && [ -z "$out" ]; then
  ok "T6 guard-read : aucun interpréteur → fail-open silencieux (rc=0, pas de blocage du travail)"
else
  ko "T6 guard-read : aucun interpréteur → rc=$rc out=[$out] (attendu allow silencieux)"
fi

# ---------- T7 : probe — AUCUN interpréteur → SIGNAL visible ----------
out=$(env PATH="$WORK/nopy" "$BASH_BIN" "$PROBE" 2>/dev/null); rc=$?
if [ $rc -eq 0 ] && printf '%s' "$out" | command grep -q 'gardes mémoire INACTIVES'; then
  ok "T7 probe : aucun interpréteur → « gardes mémoire INACTIVES » affiché (rc=0)"
else
  ko "T7 probe : signal absent ou rc=$rc — out=[$out]"
fi

# ---------- T8 : probe — stub WindowsApps SEUL (sans vrai python) → SIGNAL aussi ----------
out=$(env PATH="$WORK/WindowsApps:$WORK/nopy" "$BASH_BIN" "$PROBE" 2>/dev/null)
if printf '%s' "$out" | command grep -q 'gardes mémoire INACTIVES'; then
  ok "T8 probe : stub Store seul → signal (le stub n'est pas pris pour un Python)"
else
  ko "T8 probe : stub Store seul → silence trompeur — out=[$out]"
fi

# ---------- T9 : probe — environnement sain → SILENCE ----------
out=$("$BASH_BIN" "$PROBE" 2>/dev/null); rc=$?
if [ $rc -eq 0 ] && [ -z "$out" ]; then
  ok "T9 probe : environnement sain → silence (aucun bruit de session)"
else
  ko "T9 probe : bruit inattendu en environnement sain — out=[$out]"
fi

echo "== $pass ok · $fail ko =="
[ "$fail" -eq 0 ]
