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
#   T10 — --verify détecte un serveur manquant : sortie bruyante (stderr), exit 1, empreinte
#         md5 du fichier cible INCHANGÉE (le mode ne répare jamais — D-09, P-02).
#   T11 — --verify confirme quand tout est déjà injecté : exit 0, empreinte inchangée.
#
# Mode NOMMÉ (D-05, clé `vf-mcp-tools`, grammaire `<serveur>:<outil1>,<outil2>,…`) :
#   T12 — Mode fichier unique : 3 tokens nommés injectés, 0 joker (deux comptages distincts).
#   T13 — Mode dossier : agent nommé (sans clé booléenne) découvert et traité (a) ; agent sans
#         aucune des deux clés reste intact (b).
#   T14 — Coexistence dans le même dossier : agent nommé ne reçoit QUE ses 3 outils (a) ; agent
#         booléen reçoit le joker à l'identique (b).
#   T15 — Correspondance insensible à la casse : orthographe du lab (--servers) retenue, pas
#         celle du frontmatter.
#   T16 — Serveur nommé absent de la liste résolue : no-op silencieux, exit 0, inchangé.
#   T17 — Idempotence du mode nommé (2e run, md5 stable).
#   T18 — Token déjà présent non dupliqué ; seuls les manquants sont ajoutés.
#   T19 — --verify mode nommé, token manquant : exit 1, empreinte inchangée.
#   T20 — --verify mode nommé complet : exit 0, empreinte inchangée.
#   T21 — --verify mode nommé, serveur absent : exit 3 (INDÉTERMINÉ, jamais 0), empreinte inchangée.
#   T22 — Valeur `vf-mcp-tools` malformée (sans séparateur (a), liste d'outils vide (b)) : no-op
#         silencieux, exit 0.
#
# Découverte scope GLOBAL (Phase 21, ADR-051-B — union ./.mcp.json ∪ ~/.claude.json) :
#   T23 — Scope global SEUL (via variable d'environnement VF_CLAUDE_JSON), pas de .mcp.json :
#         le serveur déclaré en scope global est bien injecté.
#   T24 — Union scope global (--claude-json, flag) + scope projet (.mcp.json) : les DEUX serveurs
#         sont injectés (jamais un remplacement).
#   T25 — Précédence d'orthographe sur collision insensible à la casse : le scope PROJET l'emporte
#         sur le scope global.
#   T26 — Dégradation propre : --claude-json JSON invalide → cette source contribue vide, le
#         scope projet reste opérant (jamais de crash).
#   T27 — --verify avec SEULEMENT le scope global renseigné (pas de .mcp.json) : un écart réel
#         (serveur manquant) rend rc=1, JAMAIS 3 — c'est le défaut structurel corrigé par cette
#         phase (mission 2026-07-31-delta-gsd-core-1.9.0.md).
#   T28 — --verify avec LES DEUX sources vides : rc=3 INDÉTERMINÉ légitime, distinct de T27 (une
#         découverte vide ne doit jamais être confondue avec un écart réel ni un succès).
#
# --strict / WINDOWS #4 (un nom de serveur cité mais inconnu de toutes les sources découvertes) :
#   T29 — Token `mcp__<serveur>__*` déjà présent dans `tools:` citant un serveur inconnu : WARNING
#         + exit 0 sans --strict (a), ERROR + exit 1 avec --strict (b).
#   T30 — `vf-mcp-tools` citant un serveur inconnu (même scénario que T16, sans --strict → exit 0) :
#         avec --strict → exit 1.
#   T31 — --verify + --strict : conforme sur les tokens MCP attendus mais un serveur inconnu est
#         cité ailleurs dans `tools:` → rc bascule 0 (sans --strict) → 1 (avec --strict).
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

# Isolation hermétique du scope GLOBAL (Phase 21, Geste B) : le script lit VF_CLAUDE_JSON comme
# override de ~/.claude.json (défaut réel sinon). On le fixe UNE FOIS pour tout le fichier, sur
# un chemin qui n'existe jamais, pour que TOUTE invocation de $SCRIPT dans cette suite reste
# indifférente à la vraie config personnelle de la machine (Samuel ou CI ubuntu-latest) — sans
# ça, T1..T22 seraient verts ou rouges selon qui les lance (le piège que la mission interdit
# explicitement). T23+ (découverte scope global) redéfinit VF_CLAUDE_JSON en préfixe de SA propre
# commande, sans toucher à cet export par défaut pour les tests suivants.
export VF_CLAUDE_JSON="$WORK/absent-claude.json"

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
# Mode NOMMÉ (D-05) : agent avec tools: classique + vf-mcp-tools (3 outils XcodeBuildMCP, D-01).
mk_named() {
  cat > "$1" <<'EOF'
---
name: vf-reviewer
description: revue de code, verification outillee
tools: Read, Bash, Glob, Grep, Agent(gsd-code-reviewer)
disallowedTools: Write, Edit
model: sonnet
memory: project
vf-internal: true
vf-mcp-tools: XcodeBuildMCP:test_sim,build_sim,clean
---
corps
EOF
}

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

# === T10 — --verify détecte un serveur manquant (D-09) =======================================
# Réutilise mk_gsd_executor (agent hors plugin, sans flag vf-mcp-consumer) : exactement le
# scénario D-09 (gsd-executor patché puis vérifié après une réinstall amont du moteur).
G10="$WORK/gsd-executor-verify-missing.md"; mk_gsd_executor "$G10"
g10_before="$(md5of "$G10")"
t10_out="$(bash "$SCRIPT" --target "$G10" --servers "XcodeBuildMCP" --force --verify 2>&1)"; t10_rc=$?
g10_after="$(md5of "$G10")"
if [ "$t10_rc" -eq 1 ] && echo "$t10_out" | grep -qF 'mcp__XcodeBuildMCP__*' && [ "$g10_after" = "$g10_before" ]; then
  ok "T10 --verify serveur manquant : rc=1, jeton manquant nommé, empreinte inchangée (ne répare jamais)"
else
  ko "T10 échec (rc=$t10_rc, empreinte avant=$g10_before après=$g10_after, sortie=[$t10_out])"
fi

# === T11 — --verify confirme quand tout est déjà injecté ======================================
G11="$WORK/gsd-executor-verify-ok.md"; mk_gsd_executor "$G11"
bash "$SCRIPT" --target "$G11" --servers "XcodeBuildMCP" --force >/dev/null 2>&1
g11_before="$(md5of "$G11")"
t11_out="$(bash "$SCRIPT" --target "$G11" --servers "XcodeBuildMCP" --force --verify 2>&1)"; t11_rc=$?
g11_after="$(md5of "$G11")"
if [ "$t11_rc" -eq 0 ] && [ "$g11_after" = "$g11_before" ]; then
  ok "T11 --verify conforme : rc=0, empreinte inchangée"
else
  ko "T11 échec (rc=$t11_rc, empreinte avant=$g11_before après=$g11_after)"
fi

# === T12 — Mode NOMMÉ, fichier unique : 3 tokens nommés, 0 joker (D-05, D-01) =================
N12="$WORK/t12.md"; mk_named "$N12"
bash "$SCRIPT" --target "$N12" --servers "XcodeBuildMCP" >/dev/null 2>&1
line12="$(toolsline "$N12")"
named_count12="$(echo "$line12" | grep -oE 'mcp__XcodeBuildMCP__(test_sim|build_sim|clean)' | wc -l | tr -d ' ')"
wildcard_count12="$(echo "$line12" | grep -o 'mcp__[A-Za-z0-9_-]*__\*' | wc -l | tr -d ' ')"
if [ "$named_count12" = "3" ] && [ "$wildcard_count12" = "0" ]; then
  ok "T12 mode nommé fichier unique : 3 tokens nommés, 0 joker (2 comptages distincts)"
else
  ko "T12 échec (named_count=$named_count12 wildcard_count=$wildcard_count12 ligne=$line12)"
fi

# === T13 — Mode dossier : agent nommé découvert (a), agent sans clé intact (b) ================
D13="$WORK/t13"; mkdir -p "$D13"
mk_named "$D13/vf-reviewer.md"
mk_planner "$D13/vf-dev-manager.md"
d13_planner_before="$(md5of "$D13/vf-dev-manager.md")"
bash "$SCRIPT" --target "$D13" --servers "XcodeBuildMCP" >/dev/null 2>&1
if toolsline "$D13/vf-reviewer.md" | grep -q 'mcp__XcodeBuildMCP__test_sim'; then
  ok "T13a mode dossier découvre l'agent nommé (sans clé booléenne)"
else
  ko "T13a agent nommé non découvert en mode dossier"
fi
if [ "$(md5of "$D13/vf-dev-manager.md")" = "$d13_planner_before" ]; then
  ok "T13b agent sans aucune des deux clés reste intact en mode dossier"
else
  ko "T13b agent sans clé modifié à tort"
fi

# === T14 — Coexistence dans le même dossier : nommé exact (a), booléen joker inchangé (b) =====
D14="$WORK/t14"; mkdir -p "$D14"
mk_named "$D14/vf-reviewer.md"
mk_flagged "$D14/vf-coder.md"
mk_mcp '{ "mcpServers": { "XcodeBuildMCP": {}, "mobile-mcp": {} } }'
bash "$SCRIPT" --target "$D14" --mcp-json "$WORK/.mcp.json" >/dev/null 2>&1
line14rev="$(toolsline "$D14/vf-reviewer.md")"
wc14rev="$(echo "$line14rev" | grep -o 'mcp__[A-Za-z0-9_-]*__\*' | wc -l | tr -d ' ')"
if echo "$line14rev" | grep -q 'mcp__XcodeBuildMCP__test_sim' && \
   echo "$line14rev" | grep -q 'mcp__XcodeBuildMCP__build_sim' && \
   echo "$line14rev" | grep -q 'mcp__XcodeBuildMCP__clean' && \
   [ "$wc14rev" = "0" ]; then
  ok "T14a coexistence : agent nommé reçoit exactement ses 3 outils, jamais le joker"
else
  ko "T14a échec (wc14rev=$wc14rev ligne=$line14rev)"
fi
if toolsline "$D14/vf-coder.md" | grep -q 'mcp__XcodeBuildMCP__\*' && \
   toolsline "$D14/vf-coder.md" | grep -q 'mcp__mobile-mcp__\*'; then
  ok "T14b coexistence : agent booléen reçoit le joker à l'identique"
else
  ko "T14b agent booléen n'a pas reçu le joker attendu"
fi

# === T15 — Correspondance insensible à la casse, orthographe du lab retenue ===================
D15="$WORK/t15"; mkdir -p "$D15"
cat > "$D15/named-case.md" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: xcodebuildmcp:test_sim,build_sim,clean
---
corps
EOF
bash "$SCRIPT" --target "$D15/named-case.md" --servers "XcodeBuildMCP" >/dev/null 2>&1
line15="$(toolsline "$D15/named-case.md")"
if echo "$line15" | grep -q 'mcp__XcodeBuildMCP__test_sim' && \
   ! echo "$line15" | grep -q 'mcp__xcodebuildmcp__test_sim'; then
  ok "T15 casse insensible : orthographe du lab (XcodeBuildMCP) retenue, pas celle du frontmatter"
else
  ko "T15 échec casse/orthographe (ligne=$line15)"
fi

# === T16 — Serveur nommé absent de la liste résolue : no-op, exit 0 ===========================
N16="$WORK/t16.md"; mk_named "$N16"; n16_before="$(md5of "$N16")"
bash "$SCRIPT" --target "$N16" --servers "mobile-mcp" >/dev/null 2>&1; rc16=$?
if [ "$rc16" -eq 0 ] && [ "$(md5of "$N16")" = "$n16_before" ]; then
  ok "T16 serveur nommé absent du lab → no-op silencieux, exit 0"
else
  ko "T16 échec (rc=$rc16)"
fi

# === T17 — Idempotence du mode nommé (2e run) ==================================================
N17="$WORK/t17.md"; mk_named "$N17"
bash "$SCRIPT" --target "$N17" --servers "XcodeBuildMCP" >/dev/null 2>&1
n17_before="$(md5of "$N17")"
bash "$SCRIPT" --target "$N17" --servers "XcodeBuildMCP" >/dev/null 2>&1
if [ "$(md5of "$N17")" = "$n17_before" ]; then
  ok "T17 mode nommé idempotent (2e run, md5 stable)"
else
  ko "T17 2e run a modifié le fichier"
fi

# === T18 — Token déjà présent non dupliqué, seuls les manquants ajoutés =======================
N18="$WORK/t18.md"
cat > "$N18" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep, mcp__XcodeBuildMCP__clean
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP:test_sim,build_sim,clean
---
corps
EOF
bash "$SCRIPT" --target "$N18" --servers "XcodeBuildMCP" >/dev/null 2>&1
line18="$(toolsline "$N18")"
clean_count18="$(echo "$line18" | grep -o 'mcp__XcodeBuildMCP__clean' | wc -l | tr -d ' ')"
if echo "$line18" | grep -q 'mcp__XcodeBuildMCP__test_sim' && \
   echo "$line18" | grep -q 'mcp__XcodeBuildMCP__build_sim' && \
   [ "$clean_count18" = "1" ]; then
  ok "T18 token déjà présent non dupliqué, seuls les manquants ajoutés"
else
  ko "T18 échec (clean_count=$clean_count18 ligne=$line18)"
fi

# === T19 — --verify mode nommé, token manquant : rc=1, empreinte inchangée ====================
N19="$WORK/t19.md"; mk_named "$N19"
n19_before="$(md5of "$N19")"
t19_out="$(bash "$SCRIPT" --target "$N19" --servers "XcodeBuildMCP" --verify 2>&1)"; rc19=$?
n19_after="$(md5of "$N19")"
if [ "$rc19" -eq 1 ] && echo "$t19_out" | grep -qF 'mcp__XcodeBuildMCP__test_sim' && [ "$n19_after" = "$n19_before" ]; then
  ok "T19 --verify mode nommé, token manquant : rc=1, nommé, empreinte inchangée"
else
  ko "T19 échec (rc=$rc19, avant=$n19_before après=$n19_after, sortie=[$t19_out])"
fi

# === T20 — --verify mode nommé complet : rc=0, empreinte inchangée ============================
N20="$WORK/t20.md"; mk_named "$N20"
bash "$SCRIPT" --target "$N20" --servers "XcodeBuildMCP" >/dev/null 2>&1
n20_before="$(md5of "$N20")"
bash "$SCRIPT" --target "$N20" --servers "XcodeBuildMCP" --verify >/dev/null 2>&1; rc20=$?
n20_after="$(md5of "$N20")"
if [ "$rc20" -eq 0 ] && [ "$n20_after" = "$n20_before" ]; then
  ok "T20 --verify mode nommé complet : rc=0, empreinte inchangée"
else
  ko "T20 échec (rc=$rc20)"
fi

# === T21 — --verify mode nommé, serveur absent : rc=3 (INDÉTERMINÉ, jamais 0) ==================
N21="$WORK/t21.md"; mk_named "$N21"
n21_before="$(md5of "$N21")"
t21_out="$(bash "$SCRIPT" --target "$N21" --servers "mobile-mcp" --verify 2>&1)"; rc21=$?
n21_after="$(md5of "$N21")"
if [ "$rc21" -eq 3 ] && [ "$n21_after" = "$n21_before" ]; then
  ok "T21 --verify mode nommé, serveur absent : rc=3 (INDÉTERMINÉ, jamais 0), empreinte inchangée"
else
  ko "T21 échec (rc=$rc21, sortie=[$t21_out])"
fi

# === T22 — Valeur vf-mcp-tools malformée : no-op silencieux, exit 0 ============================
N22A="$WORK/t22a.md"
cat > "$N22A" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP-sans-separateur
---
corps
EOF
n22a_before="$(md5of "$N22A")"
bash "$SCRIPT" --target "$N22A" --servers "XcodeBuildMCP" >/dev/null 2>&1; rc22a=$?
if [ "$rc22a" -eq 0 ] && [ "$(md5of "$N22A")" = "$n22a_before" ]; then
  ok "T22a valeur malformée (pas de séparateur) : no-op silencieux, exit 0"
else
  ko "T22a échec (rc=$rc22a)"
fi

N22B="$WORK/t22b.md"
cat > "$N22B" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP:
---
corps
EOF
n22b_before="$(md5of "$N22B")"
bash "$SCRIPT" --target "$N22B" --servers "XcodeBuildMCP" >/dev/null 2>&1; rc22b=$?
if [ "$rc22b" -eq 0 ] && [ "$(md5of "$N22B")" = "$n22b_before" ]; then
  ok "T22b valeur malformée (liste d'outils vide) : no-op silencieux, exit 0"
else
  ko "T22b échec (rc=$rc22b)"
fi

# === T23 — Scope global SEUL (VF_CLAUDE_JSON), pas de .mcp.json ===============================
D23="$WORK/t23"; mkdir -p "$D23"
mk_flagged "$D23/a.md"
CJ23="$WORK/t23-claude.json"
printf '%s\n' '{ "mcpServers": { "XcodeBuildMCP": {} } }' > "$CJ23"
VF_CLAUDE_JSON="$CJ23" bash "$SCRIPT" --target "$D23" --mcp-json "$WORK/t23-absent-project.json" >/dev/null 2>&1
if toolsline "$D23/a.md" | grep -q 'mcp__XcodeBuildMCP__\*'; then
  ok "T23 scope global seul (VF_CLAUDE_JSON, pas de .mcp.json) : serveur injecté"
else
  ko "T23 scope global (variable d'environnement) non découvert"
fi

# === T24 — Union scope global (--claude-json) + scope projet (.mcp.json) ======================
D24="$WORK/t24"; mkdir -p "$D24"
mk_flagged "$D24/a.md"
CJ24="$WORK/t24-claude.json"
printf '%s\n' '{ "mcpServers": { "XcodeBuildMCP": {} } }' > "$CJ24"
mk_mcp '{ "mcpServers": { "mobile-mcp": {} } }'
bash "$SCRIPT" --target "$D24" --mcp-json "$WORK/.mcp.json" --claude-json "$CJ24" >/dev/null 2>&1
line24="$(toolsline "$D24/a.md")"
if echo "$line24" | grep -q 'mcp__XcodeBuildMCP__\*' && echo "$line24" | grep -q 'mcp__mobile-mcp__\*'; then
  ok "T24 union scope global + scope projet : les deux serveurs injectés (jamais un remplacement)"
else
  ko "T24 échec union (ligne=$line24)"
fi

# === T25 — Précédence d'orthographe : scope PROJET l'emporte sur scope global (collision casse) ===
D25="$WORK/t25"; mkdir -p "$D25"
mk_flagged "$D25/a.md"
CJ25="$WORK/t25-claude.json"
printf '%s\n' '{ "mcpServers": { "xcodebuildmcp": {} } }' > "$CJ25"
printf '%s\n' '{ "mcpServers": { "XcodeBuildMCP": {} } }' > "$WORK/t25-mcp.json"
bash "$SCRIPT" --target "$D25" --mcp-json "$WORK/t25-mcp.json" --claude-json "$CJ25" >/dev/null 2>&1
line25="$(toolsline "$D25/a.md")"
if echo "$line25" | grep -q 'mcp__XcodeBuildMCP__\*' && ! echo "$line25" | grep -q 'mcp__xcodebuildmcp__\*'; then
  ok "T25 précédence orthographe : scope PROJET l'emporte sur scope global en cas de collision"
else
  ko "T25 échec précédence (ligne=$line25)"
fi

# === T26 — Dégradation propre : --claude-json JSON invalide, scope projet reste opérant =========
D26="$WORK/t26"; mkdir -p "$D26"
mk_flagged "$D26/a.md"
CJ26="$WORK/t26-claude.json"
printf '%s' '{ not valid json' > "$CJ26"
mk_mcp '{ "mcpServers": { "XcodeBuildMCP": {} } }'
bash "$SCRIPT" --target "$D26" --mcp-json "$WORK/.mcp.json" --claude-json "$CJ26" >/dev/null 2>&1; rc26=$?
if [ "$rc26" -eq 0 ] && toolsline "$D26/a.md" | grep -q 'mcp__XcodeBuildMCP__\*'; then
  ok "T26 dégradation : --claude-json JSON invalide → source vide, scope projet reste opérant"
else
  ko "T26 échec dégradation (rc=$rc26)"
fi

# === T27 — --verify, scope global SEUL : écart réel → rc=1, JAMAIS 3 (cœur du défaut corrigé) ===
G27="$WORK/t27.md"; mk_gsd_executor "$G27"
CJ27="$WORK/t27-claude.json"
printf '%s\n' '{ "mcpServers": { "XcodeBuildMCP": {} } }' > "$CJ27"
g27_before="$(md5of "$G27")"
t27_out="$(bash "$SCRIPT" --target "$G27" --mcp-json "$WORK/t27-absent-project.json" --claude-json "$CJ27" --force --verify 2>&1)"; rc27=$?
g27_after="$(md5of "$G27")"
if [ "$rc27" -eq 1 ] && echo "$t27_out" | grep -qF 'mcp__XcodeBuildMCP__*' && [ "$g27_after" = "$g27_before" ]; then
  ok "T27 --verify scope global seul (pas de .mcp.json) : écart réel détecté, rc=1 jamais 3 (Geste C)"
else
  ko "T27 échec (rc=$rc27, sortie=[$t27_out])"
fi

# === T28 — --verify, LES DEUX sources vides : rc=3 INDÉTERMINÉ légitime (distinct de T27) =======
G28="$WORK/t28.md"; mk_gsd_executor "$G28"
CJ28="$WORK/t28-absent-claude.json"
t28_out="$(bash "$SCRIPT" --target "$G28" --mcp-json "$WORK/t28-absent-project.json" --claude-json "$CJ28" --force --verify 2>&1)"; rc28=$?
if [ "$rc28" -eq 3 ]; then
  ok "T28 --verify deux sources vides : rc=3 INDÉTERMINÉ légitime (jamais confondu avec T27)"
else
  ko "T28 échec (rc=$rc28, sortie=[$t28_out])"
fi

# === T29 — --strict, token mcp__ déjà présent citant un serveur inconnu (WINDOWS #4) ============
mk_ghost() {
  cat > "$1" <<'EOF'
---
name: vf-coder
description: exécute une étape de dev, build et test inclus
tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent, mcp__ghost-server__*
model: opus
memory: project
vf-internal: true
vf-mcp-consumer: true
---
corps
EOF
}
G29A="$WORK/t29a.md"; mk_ghost "$G29A"
out29a="$(bash "$SCRIPT" --target "$G29A" --servers "XcodeBuildMCP" 2>&1)"; rc29a=$?
if [ "$rc29a" -eq 0 ] && echo "$out29a" | grep -qF "ghost-server"; then
  ok "T29a serveur inconnu déjà présent (mcp__) : WARNING loggé, exit 0 sans --strict"
else
  ko "T29a échec (rc=$rc29a out=[$out29a])"
fi

G29B="$WORK/t29b.md"; mk_ghost "$G29B"
bash "$SCRIPT" --target "$G29B" --servers "XcodeBuildMCP" --strict >/dev/null 2>&1; rc29b=$?
if [ "$rc29b" -eq 1 ]; then
  ok "T29b --strict : même serveur inconnu déjà présent → ERROR bloquante, exit 1"
else
  ko "T29b échec (rc=$rc29b)"
fi

# === T30 — --strict, vf-mcp-tools citant un serveur inconnu (même entrée que T16, --strict) =====
N30="$WORK/t30.md"; mk_named "$N30"
bash "$SCRIPT" --target "$N30" --servers "mobile-mcp" --strict >/dev/null 2>&1; rc30=$?
if [ "$rc30" -eq 1 ]; then
  ok "T30 --strict : vf-mcp-tools cite un serveur inconnu (non résolu) → exit 1 (T16 sans --strict = exit 0)"
else
  ko "T30 échec (rc=$rc30)"
fi

# === T31 — --verify + --strict : conforme sur l'attendu mais serveur inconnu cité ailleurs =======
mk_ghost_conforme() {
  cat > "$1" <<'EOF'
---
name: vf-coder
description: exécute une étape de dev, build et test inclus
tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent, mcp__XcodeBuildMCP__*, mcp__ghost-server__*
model: opus
memory: project
vf-internal: true
vf-mcp-consumer: true
---
corps
EOF
}
G31="$WORK/t31.md"; mk_ghost_conforme "$G31"
bash "$SCRIPT" --target "$G31" --servers "XcodeBuildMCP" --verify >/dev/null 2>&1; rc31a=$?
bash "$SCRIPT" --target "$G31" --servers "XcodeBuildMCP" --verify --strict >/dev/null 2>&1; rc31b=$?
if [ "$rc31a" -eq 0 ] && [ "$rc31b" -eq 1 ]; then
  ok "T31 --verify + --strict : conforme sur l'attendu, serveur inconnu cité → rc bascule 0 → 1"
else
  ko "T31 échec (rc31a=$rc31a rc31b=$rc31b)"
fi

# === Bilan ===================================================================================
echo ""
echo "  Bilan : $pass OK, $fail KO"
[ "$fail" -eq 0 ] || exit 1
echo "  ✓ inject-mcp-tools.sh conforme (ADR-051)"
exit 0
