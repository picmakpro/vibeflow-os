#!/usr/bin/env bash
# test-inject-mcp-tools.sh — Suite de vérification de inject-mcp-tools.sh (ADR-051).
#
# Couvre :
#   T1 — Mode dossier : injecte dans l'agent flaggé vf-mcp-consumer, laisse les autres INTACTS.
#   T2 — Idempotence : 2e run = aucun changement (md5 stable).
#   T3 — --force sur fichier hors plugin (gsd-executor) : ajoute le manquant, ne DUPLIQUE pas
#        un token déjà présent (mcp__context7__*).
#   T4 — Fichier sans flag et sans --force : REFUS (fichier inchangé).
#   T5 — .mcp.json absent : no-op, exit 0 (best-effort).
#   T6 — Agent flaggé SANS ligne tools: (hérite tout) : no-op, inchangé.
#   T7 — --servers explicite l'emporte sur --mcp-json.
#   T8 — mcpServers vide : no-op.
#   T9 — Ordre déterministe des serveurs (tri) → sortie stable.
#
# Convention : asserts numérotés, helpers ok()/ko(), exit 0 si tout passe, 1 si ≥1 KO.
# Calqué sur test-dev-orchestrator.sh.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/inject-mcp-tools.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

[ -f "$SCRIPT" ] || { echo "✗ inject-mcp-tools.sh introuvable : $SCRIPT"; exit 1; }

md5of() { md5 -q "$1" 2>/dev/null || md5sum "$1" | cut -d' ' -f1; }
toolsline() { grep -m1 '^tools:' "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- Fixtures ---------------------------------------------------------------------------------
mk_flagged() {
  cat > "$1" <<'EOF'
---
name: vf-coder
description: exécute une étape de dev, build et test inclus
tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent
model: opus
memory: project
vf-internal: true
vf-mcp-consumer: true
---
corps
EOF
}
mk_planner() {
  cat > "$1" <<'EOF'
---
name: vf-dev-manager
description: planifie et distribue, ne code jamais
tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, Agent, Edit
model: opus
memory: project
---
corps
EOF
}
mk_gsd_executor() {
  cat > "$1" <<'EOF'
---
name: gsd-executor
description: exécute les plans GSD avec commits atomiques
tools: Read, Write, Edit, Bash, Grep, Glob, mcp__context7__*
model: opus
memory: project
---
corps
EOF
}
mk_notools() {
  cat > "$1" <<'EOF'
---
name: vf-open
description: agent flaggé mais sans allowlist tools (hérite tout)
model: opus
memory: project
vf-mcp-consumer: true
---
corps
EOF
}
mk_mcp() { printf '%s\n' "$1" > "$WORK/.mcp.json"; }

# === T1 — Mode dossier : flaggé injecté, non-flaggé intact ====================================
D1="$WORK/t1"; mkdir -p "$D1"
mk_flagged "$D1/vf-coder.md"
mk_planner "$D1/vf-dev-manager.md"
mk_mcp '{ "mcpServers": { "XcodeBuildMCP": {}, "mobile-mcp": {} } }'
planner_before="$(md5of "$D1/vf-dev-manager.md")"
bash "$SCRIPT" --target "$D1" --mcp-json "$WORK/.mcp.json" >/dev/null 2>&1
if toolsline "$D1/vf-coder.md" | grep -q 'mcp__XcodeBuildMCP__\*' && \
   toolsline "$D1/vf-coder.md" | grep -q 'mcp__mobile-mcp__\*'; then
  ok "T1a flaggé reçoit les serveurs du lab"
else
  ko "T1a flaggé n'a pas reçu les serveurs"
fi
if [ "$(md5of "$D1/vf-dev-manager.md")" = "$planner_before" ]; then
  ok "T1b non-flaggé (planner) intact"
else
  ko "T1b non-flaggé modifié à tort"
fi

# === T2 — Idempotence ========================================================================
before="$(md5of "$D1/vf-coder.md")"
bash "$SCRIPT" --target "$D1" --mcp-json "$WORK/.mcp.json" >/dev/null 2>&1
if [ "$(md5of "$D1/vf-coder.md")" = "$before" ]; then
  ok "T2 2e run idempotent (md5 stable)"
else
  ko "T2 2e run a modifié le fichier"
fi

# === T3 — --force gsd-executor : ajoute sans dupliquer context7 ================================
G="$WORK/gsd-executor.md"; mk_gsd_executor "$G"
bash "$SCRIPT" --target "$G" --servers "XcodeBuildMCP,context7" --force >/dev/null 2>&1
c7_count="$(toolsline "$G" | grep -o 'mcp__context7__\*' | wc -l | tr -d ' ')"
if toolsline "$G" | grep -q 'mcp__XcodeBuildMCP__\*' && [ "$c7_count" = "1" ]; then
  ok "T3 --force ajoute XcodeBuildMCP sans dupliquer context7"
else
  ko "T3 échec (XcodeBuildMCP absent ou context7 dupliqué : count=$c7_count)"
fi

# === T4 — Sans flag et sans --force : refus ===================================================
P="$WORK/planner-solo.md"; mk_planner "$P"
p_before="$(md5of "$P")"
bash "$SCRIPT" --target "$P" --servers "XcodeBuildMCP" >/dev/null 2>&1
if [ "$(md5of "$P")" = "$p_before" ]; then
  ok "T4 fichier sans flag/force refusé (inchangé)"
else
  ko "T4 fichier sans flag/force modifié à tort"
fi

# === T5 — .mcp.json absent : no-op exit 0 =====================================================
mk_flagged "$WORK/t5.md"; t5_before="$(md5of "$WORK/t5.md")"
bash "$SCRIPT" --target "$WORK/t5.md" --mcp-json "$WORK/absent.json" >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(md5of "$WORK/t5.md")" = "$t5_before" ]; then
  ok "T5 .mcp.json absent → no-op exit 0"
else
  ko "T5 échec (rc=$rc ou fichier modifié)"
fi

# === T6 — Agent flaggé sans ligne tools: (hérite tout) : no-op ================================
N="$WORK/notools.md"; mk_notools "$N"; n_before="$(md5of "$N")"
bash "$SCRIPT" --target "$N" --servers "XcodeBuildMCP" --force >/dev/null 2>&1
if [ "$(md5of "$N")" = "$n_before" ]; then
  ok "T6 agent sans tools: (hérite tout) → inchangé"
else
  ko "T6 agent sans tools: modifié à tort"
fi

# === T7 — --servers l'emporte sur --mcp-json ==================================================
D7="$WORK/t7"; mkdir -p "$D7"; mk_flagged "$D7/a.md"
mk_mcp '{ "mcpServers": { "ignored-server": {} } }'
bash "$SCRIPT" --target "$D7" --mcp-json "$WORK/.mcp.json" --servers "wanted-server" >/dev/null 2>&1
if toolsline "$D7/a.md" | grep -q 'mcp__wanted-server__\*' && \
   ! toolsline "$D7/a.md" | grep -q 'mcp__ignored-server__\*'; then
  ok "T7 --servers explicite l'emporte sur --mcp-json"
else
  ko "T7 mauvaise source de serveurs"
fi

# === T8 — mcpServers vide : no-op =============================================================
D8="$WORK/t8"; mkdir -p "$D8"; mk_flagged "$D8/a.md"; a8_before="$(md5of "$D8/a.md")"
mk_mcp '{ "mcpServers": {} }'
bash "$SCRIPT" --target "$D8" --mcp-json "$WORK/.mcp.json" >/dev/null 2>&1
if [ "$(md5of "$D8/a.md")" = "$a8_before" ]; then
  ok "T8 mcpServers vide → no-op"
else
  ko "T8 modifié malgré 0 serveur"
fi

# === T9 — Ordre déterministe (tri) ===========================================================
D9="$WORK/t9"; mkdir -p "$D9"; mk_flagged "$D9/a.md"
bash "$SCRIPT" --target "$D9" --servers "zebra,alpha,mike" >/dev/null 2>&1
line="$(toolsline "$D9/a.md")"
if echo "$line" | grep -q 'mcp__alpha__\*, mcp__mike__\*, mcp__zebra__\*'; then
  ok "T9 serveurs injectés triés (déterministe)"
else
  ko "T9 ordre non déterministe : $line"
fi

# === Bilan ===================================================================================
echo ""
echo "  Bilan : $pass OK, $fail KO"
[ "$fail" -eq 0 ] || exit 1
echo "  ✓ inject-mcp-tools.sh conforme (ADR-051)"
exit 0
