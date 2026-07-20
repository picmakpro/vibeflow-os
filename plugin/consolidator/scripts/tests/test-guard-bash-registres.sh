#!/usr/bin/env bash
# test-guard-bash-registres.sh — Suite du correctif BLK-006 (contournement shell du
# guard de lecture des registres, ADR-043).
#
# Guard Bash (PreToolUse) :
#   T1  — `cat <registre long>` → DENY
#   T2  — `head -40 <registre>` → allow (lecture d'index)
#   T3  — `head -n 500 <registre>` → DENY (borne dépassée)
#   T4  — `tail -n +1 <registre>` → DENY (lit tout)
#   T5  — `grep -n "DEC-" <registre>` → allow (ciblé)
#   T6  — `sed -n '100,140p' <registre>` → allow (plage ciblée)
#   T7  — `cat <registre> | head -20` → allow (pipeline limité en aval)
#   T8  — `cat >> <registre> << EOF` → allow (écriture)
#   T9  — `cat <registre court>` → allow (≤ 150 lignes)
#   T10 — `cat <archive>` → allow ; `cat notes.md` → allow
#   T11 — stdin invalide → allow silencieux (fail-open)
#   T12 — chemin relatif résolu via cwd du payload → DENY
#
# Post-edit-reindex en mode Bash :
#   T13 — append `>>` vers un registre → l'index est régénéré
#   T14 — commande Bash qui LIT le registre (grep) → index NON régénéré (pas d'écriture)
#
# Fiabilisation CSL :
#   T15 (CSL-04) — nom de lecteur plein en ARGUMENT (`grep -n 'open'`, `grep -c cat`) → allow
#   T16 (CSL-04) — lecteur plein derrière un wrapper (nohup/env/command) → deny maintenu
#   T17 (CSL-05) — heredoc qui CITE `cat <registre>` (écriture ailleurs) → allow
#   T18 (CSL-06) — écriture vers cible quotée (`>> "<registre>"`) → allow
#   T19 — régression : lecture avec argument quoté (`cat "<registre>"`) → deny maintenu
#   T20 (CSL-07) — post-edit-reindex : append Bash vers cible QUOTÉE → index régénéré

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
GUARD="$SCRIPTS_DIR/guard-bash-registres.sh"
POST_EDIT="$SCRIPTS_DIR/post-edit-reindex.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-guard-bash-registres (guard: $GUARD) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
MEM="$WORK/lab/.claude/memory"
mkdir -p "$MEM/archive"

for i in $(seq 1 200); do echo "ligne $i"; done > "$MEM/DECISIONS.md"
for i in $(seq 1 200); do echo "ligne $i"; done > "$MEM/archive/DECISIONS.md"
for i in $(seq 1 30); do echo "ligne $i"; done > "$MEM/BLOCKERS.md"
for i in $(seq 1 200); do echo "ligne $i"; done > "$WORK/lab/notes.md"

run_guard() {
  # $1 = command · $2 = cwd (défaut WORK/lab)
  python3 -c "import json,sys; print(json.dumps({'tool_name':'Bash','cwd':sys.argv[2],'tool_input':{'command':sys.argv[1]}}))" \
    "$1" "${2:-$WORK/lab}" | bash "$GUARD" 2>/dev/null
}
is_deny() { echo "$1" | grep -q '"permissionDecision": *"deny"'; }

D="$MEM/DECISIONS.md"

OUT="$(run_guard "cat $D")"
is_deny "$OUT" && ok "T1 cat registre long → deny" || ko "T1 deny attendu, obtenu : ${OUT:-<vide>}"

OUT="$(run_guard "head -40 $D")"
[ -z "$OUT" ] && ok "T2 head -40 → allow (index)" || ko "T2 allow attendu : $OUT"

OUT="$(run_guard "head -n 500 $D")"
is_deny "$OUT" && ok "T3 head -n 500 → deny (borne dépassée)" || ko "T3 deny attendu : ${OUT:-<vide>}"

OUT="$(run_guard "tail -n +1 $D")"
is_deny "$OUT" && ok "T4 tail -n +1 → deny (lit tout)" || ko "T4 deny attendu : ${OUT:-<vide>}"

OUT="$(run_guard "grep -n 'DEC-' $D")"
[ -z "$OUT" ] && ok "T5 grep ciblé → allow" || ko "T5 allow attendu : $OUT"

OUT="$(run_guard "sed -n '100,140p' $D")"
[ -z "$OUT" ] && ok "T6 sed -n plage → allow" || ko "T6 allow attendu : $OUT"

OUT="$(run_guard "cat $D | head -20")"
[ -z "$OUT" ] && ok "T7 cat | head -20 → allow (pipeline limité)" || ko "T7 allow attendu : $OUT"

OUT="$(run_guard "cat >> $D << 'EOF'
nouvelle entree
EOF")"
[ -z "$OUT" ] && ok "T8 cat >> registre (append) → allow" || ko "T8 allow attendu : $OUT"

OUT="$(run_guard "cat $MEM/BLOCKERS.md")"
[ -z "$OUT" ] && ok "T9 cat registre court → allow" || ko "T9 allow attendu : $OUT"

OUT1="$(run_guard "cat $MEM/archive/DECISIONS.md")"
OUT2="$(run_guard "cat $WORK/lab/notes.md")"
{ [ -z "$OUT1" ] && [ -z "$OUT2" ]; } && ok "T10 archive + fichier hors registres → allow" || ko "T10 allow attendu"

OUT="$(echo 'pas du json' | bash "$GUARD" 2>/dev/null)"; RC=$?
{ [ "$RC" -eq 0 ] && [ -z "$OUT" ]; } && ok "T11 stdin invalide → fail-open" || ko "T11 fail-open (rc=$RC)"

OUT="$(run_guard "cat .claude/memory/DECISIONS.md" "$WORK/lab")"
is_deny "$OUT" && ok "T12 chemin relatif résolu via cwd → deny" || ko "T12 deny attendu : ${OUT:-<vide>}"

# ---------- Post-edit-reindex en mode Bash ----------
cat > "$MEM/LEARNINGS.md" <<'EOF'
# Learnings

## LRN-001 : Premier learning

**Date** : 2026-07-01
Contenu.
EOF
printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"cat >> %s << EOF\\nplus\\nEOF"}}' "$WORK/lab" "$MEM/LEARNINGS.md" \
  | bash "$POST_EDIT" 2>/dev/null
if grep -q '^## Index' "$MEM/LEARNINGS.md" && grep -q '#Ligne' "$MEM/LEARNINGS.md"; then
  ok "T13 append Bash >> registre → index régénéré par post-edit-reindex"
else
  ko "T13 index non régénéré après append Bash"
fi

cat > "$MEM/EVALS.md" <<'EOF'
# Evals

## EVAL-001 : Premier eval

Contenu.
EOF
printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"grep -n EVAL %s"}}' "$WORK/lab" "$MEM/EVALS.md" \
  | bash "$POST_EDIT" 2>/dev/null
if grep -q '^## Index' "$MEM/EVALS.md"; then
  ko "T14 lecture Bash a déclenché un reindex (écriture attendue seulement)"
else
  ok "T14 lecture Bash (grep) → pas de reindex"
fi

# ---------- Fiabilisation CSL ----------

# T15 (CSL-04) — un nom de FULL_READER en position d'ARGUMENT est une recherche
# ciblée légitime, pas une lecture pleine (faux positifs démontrés).
OUT1="$(run_guard "grep -n 'open' $D")"
OUT2="$(run_guard "grep -c cat $D")"
{ [ -z "$OUT1" ] && [ -z "$OUT2" ]; } && ok "T15 (CSL-04) grep -n 'open' / grep -c cat → allow" \
  || ko "T15 (CSL-04) allow attendu (open: ${OUT1:-ok} · cat: ${OUT2:-ok})"

# T16 (CSL-04) — le lecteur plein derrière un wrapper reste en position de commande.
OUT1="$(run_guard "nohup cat $D")"
OUT2="$(run_guard "env VAR=1 cat $D")"
OUT3="$(run_guard "command cat $D")"
{ is_deny "$OUT1" && is_deny "$OUT2" && is_deny "$OUT3"; } && ok "T16 (CSL-04) nohup/env/command cat → deny maintenu" \
  || ko "T16 (CSL-04) deny attendu derrière wrapper"

# T17 (CSL-05) — une doc qui CITE `cat <registre>` dans un heredoc n'est pas une lecture.
OUT="$(run_guard "cat > $WORK/lab/doc.md << 'EOF'
Pour lire un registre en entier (interdit) :
cat $D
EOF")"
[ -z "$OUT" ] && ok "T17 (CSL-05) heredoc citant cat <registre> → allow" || ko "T17 (CSL-05) allow attendu : $OUT"

# T18 (CSL-06) — l'exclusion écriture tolère la cible quotée.
OUT1="$(run_guard "cat $WORK/lab/notes.md >> \"$D\"")"
OUT2="$(run_guard "cat $WORK/lab/notes.md >> '$D'")"
{ [ -z "$OUT1" ] && [ -z "$OUT2" ]; } && ok "T18 (CSL-06) append vers cible quotée → allow" \
  || ko "T18 (CSL-06) allow attendu (dq: ${OUT1:-ok} · sq: ${OUT2:-ok})"

# T19 — régression : la LECTURE d'un registre quoté doit toujours être bloquée.
OUT="$(run_guard "cat \"$D\"")"
is_deny "$OUT" && ok "T19 lecture argument quoté → deny maintenu" || ko "T19 deny attendu : ${OUT:-<vide>}"

# T20 (CSL-07) — post-edit-reindex détecte l'écriture Bash vers une cible QUOTÉE.
cat > "$MEM/JOURNAL.md" <<'EOF'
# Journal

## Session 1 : Init

**Date** : 2026-07-01
Contenu.
EOF
python3 -c "import json,sys; print(json.dumps({'tool_name':'Bash','cwd':sys.argv[2],'tool_input':{'command':sys.argv[1]}}))" \
  "echo 'ligne' >> \"$MEM/JOURNAL.md\"" "$WORK/lab" | bash "$POST_EDIT" 2>/dev/null
if grep -q '^## Index' "$MEM/JOURNAL.md" && grep -q '#Ligne' "$MEM/JOURNAL.md"; then
  ok "T20 (CSL-07) append Bash vers cible quotée → index régénéré"
else
  ko "T20 (CSL-07) index non régénéré après append quoté"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
