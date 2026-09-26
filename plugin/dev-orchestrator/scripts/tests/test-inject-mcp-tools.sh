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
#   T22 (durci, Phase 43 FABR-10 a, D-Q3) — Valeur `vf-mcp-tools` malformée : REFUSÉE, exit 1,
#         ERROR « malform », empreinte inchangée, valeur brute jamais recopiée : sans séparateur (a),
#         liste d'outils vide (b), segment hors charset (c), serveur vide (d) ; entre guillemets
#         valide (e) et invalide ; valeur lue sur la SEULE ligne de la clé — jamais la ligne
#         suivante, jumeaux à 1 espace/1 tabulation (f) ; clé en double, deux ordres (g) ; ordre
#         trim PUIS déquotage — espace/tabulation/CR finaux acceptés (h) ; clé en dernière ligne du
#         frontmatter, vide refusée / valide acceptée, sans Traceback (i) ; espace avant le
#         deux-points — reconnue présente, refusée (j).
#   T34 — Dossier mixte (agent valide + agent malformé) : le valide reçoit ses tokens, le malformé
#         reste identique, rc=1 pour le balayage entier.
#   MUT-A — mutant sur la ligne unique qui passe malformed_found à vrai : rc_original=1 (T22a),
#         rc_mutant=0.
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
# T23 à T31 : documentés ci-dessus en Phase 21, jamais présents dans le code de cette suite
# (constat Phase 43, 2026-09-25, vérifié jusqu'au commit d89a60e) — relevé pour Samuel, non
# restaurés ici.
#
# Durcissement WINDOWS #4 / union des scopes (Phase 43, FABR-10 b, D-Q3) :
#   T32 — NON-RÉGRESSION : l'union scope projet ∪ scope global (déjà présente dans le code,
#         inject-mcp-tools.sh l.245-259) reste opérante pendant que (b) réécrit les messages.
#   T33 — Serveur cité absent des DEUX scopes : WARNING nommant « union » et les DEUX chemins de
#         sources réellement consultées.
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

# === T16 (durci, Phase 43 FABR-10 b, D-Q3) — Serveur nommé absent de l'union résolue : rc 0, ====
# empreinte inchangée, mais le signal est désormais nommé sur stderr (WARNING, serveur cité,
# source consultée) — plus un no-op muet.
N16="$WORK/t16.md"; mk_named "$N16"; n16_before="$(md5of "$N16")"
t16_out="$(bash "$SCRIPT" --target "$N16" --servers "mobile-mcp" 2>&1)"; rc16=$?
if [ "$rc16" -eq 0 ] && [ "$(md5of "$N16")" = "$n16_before" ] && \
   echo "$t16_out" | grep -q 'WARNING:' && \
   echo "$t16_out" | grep -q 'XcodeBuildMCP' && \
   echo "$t16_out" | grep -q 'liste --servers explicite' && \
   ! echo "$t16_out" | grep -q 'silencieux'; then
  ok "T16 serveur nommé absent de l'union → rc=0, empreinte inchangée, WARNING nommé (source, serveur), jamais un silence"
else
  ko "T16 échec (rc=$rc16, sortie=[$t16_out])"
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

# === T22 (durci, Phase 43 FABR-10 a, D-Q3) — Valeur vf-mcp-tools malformée : REFUSÉE, rc 1, =====
# ERROR « malform », empreinte inchangée, valeur brute JAMAIS recopiée dans le message.
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
t22a_out="$(bash "$SCRIPT" --target "$N22A" --servers "XcodeBuildMCP" 2>&1)"; rc22a=$?
if [ "$rc22a" -eq 1 ] && [ "$(md5of "$N22A")" = "$n22a_before" ] && \
   echo "$t22a_out" | grep -q 'ERROR:' && echo "$t22a_out" | grep -qi 'malform' && \
   ! echo "$t22a_out" | grep -q 'XcodeBuildMCP-sans-separateur'; then
  ok "T22a (durci) valeur malformée (pas de séparateur) : rc=1, ERROR malform, empreinte inchangée, valeur brute non recopiée"
else
  ko "T22a échec (rc=$rc22a, sortie=[$t22a_out])"
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
t22b_out="$(bash "$SCRIPT" --target "$N22B" --servers "XcodeBuildMCP" 2>&1)"; rc22b=$?
if [ "$rc22b" -eq 1 ] && [ "$(md5of "$N22B")" = "$n22b_before" ] && \
   echo "$t22b_out" | grep -q 'ERROR:' && echo "$t22b_out" | grep -qi 'malform'; then
  ok "T22b (durci) valeur malformée (liste d'outils vide) : rc=1, ERROR malform, empreinte inchangée"
else
  ko "T22b échec (rc=$rc22b, sortie=[$t22b_out])"
fi

N22C="$WORK/t22c.md"
cat > "$N22C" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP:test sim
---
corps
EOF
n22c_before="$(md5of "$N22C")"
t22c_out="$(bash "$SCRIPT" --target "$N22C" --servers "XcodeBuildMCP" 2>&1)"; rc22c=$?
if [ "$rc22c" -eq 1 ] && [ "$(md5of "$N22C")" = "$n22c_before" ] && echo "$t22c_out" | grep -qi 'malform'; then
  ok "T22c valeur malformée (segment hors charset) : rc=1, ERROR malform, empreinte inchangée"
else
  ko "T22c échec (rc=$rc22c, sortie=[$t22c_out])"
fi

N22D="$WORK/t22d.md"
cat > "$N22D" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: :test_sim
---
corps
EOF
n22d_before="$(md5of "$N22D")"
t22d_out="$(bash "$SCRIPT" --target "$N22D" --servers "XcodeBuildMCP" 2>&1)"; rc22d=$?
if [ "$rc22d" -eq 1 ] && [ "$(md5of "$N22D")" = "$n22d_before" ] && echo "$t22d_out" | grep -qi 'malform'; then
  ok "T22d valeur malformée (serveur vide) : rc=1, ERROR malform, empreinte inchangée"
else
  ko "T22d échec (rc=$rc22d, sortie=[$t22d_out])"
fi

# === T34 — Dossier mixte : agent valide reçoit ses tokens, agent malformé refusé et inchangé, ===
# rc 1 pour le balayage entier (Phase 43, FABR-10 a).
D34="$WORK/t34"; mkdir -p "$D34"
mk_named "$D34/vf-reviewer-ok.md"
cat > "$D34/vf-reviewer-bad.md" <<'EOF'
---
name: vf-reviewer-bad
description: revue de code, fixture malformee
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP-sans-separateur
---
corps
EOF
bad34_before="$(md5of "$D34/vf-reviewer-bad.md")"
t34_out="$(bash "$SCRIPT" --target "$D34" --servers "XcodeBuildMCP" 2>&1)"; rc34=$?
line34ok="$(toolsline "$D34/vf-reviewer-ok.md")"
if [ "$rc34" -eq 1 ] && echo "$line34ok" | grep -q 'mcp__XcodeBuildMCP__test_sim' && \
   [ "$(md5of "$D34/vf-reviewer-bad.md")" = "$bad34_before" ] && \
   echo "$t34_out" | grep -q 'ERROR:' && echo "$t34_out" | grep -qi 'malform'; then
  ok "T34 dossier mixte : agent valide injecté, agent malformé refusé et inchangé, rc=1"
else
  ko "T34 échec (rc=$rc34, ligne_ok=$line34ok, sortie=[$t34_out])"
fi

# === T22e (parité des guillemets, injecteur) — valeur entre guillemets acceptée, invalide ET =====
# entre guillemets refusée (Phase 43, FABR-10 a, parité W5).
N22E1="$WORK/t22e1.md"
cat > "$N22E1" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: "XcodeBuildMCP:test_sim,build_sim"
---
corps
EOF
t22e1_out="$(bash "$SCRIPT" --target "$N22E1" --servers "XcodeBuildMCP" 2>&1)"; rc22e1=$?
line22e1="$(toolsline "$N22E1")"
if [ "$rc22e1" -eq 0 ] && echo "$line22e1" | grep -q 'mcp__XcodeBuildMCP__test_sim' && \
   echo "$line22e1" | grep -q 'mcp__XcodeBuildMCP__build_sim' && ! echo "$t22e1_out" | grep -q 'ERROR:'; then
  ok "T22e valeur entre guillemets doubles : rc=0, tokens injectés, aucune ERROR"
else
  ko "T22e (doubles) échec (rc=$rc22e1, ligne=$line22e1, sortie=[$t22e1_out])"
fi

N22E2="$WORK/t22e2.md"
cat > "$N22E2" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: 'XcodeBuildMCP:test_sim'
---
corps
EOF
t22e2_out="$(bash "$SCRIPT" --target "$N22E2" --servers "XcodeBuildMCP" 2>&1)"; rc22e2=$?
line22e2="$(toolsline "$N22E2")"
if [ "$rc22e2" -eq 0 ] && echo "$line22e2" | grep -q 'mcp__XcodeBuildMCP__test_sim' && ! echo "$t22e2_out" | grep -q 'ERROR:'; then
  ok "T22e valeur entre guillemets simples : rc=0, token injecté, aucune ERROR"
else
  ko "T22e (simples) échec (rc=$rc22e2, ligne=$line22e2, sortie=[$t22e2_out])"
fi

N22E3="$WORK/t22e3.md"
cat > "$N22E3" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: "XcodeBuildMCP:test sim"
---
corps
EOF
n22e3_before="$(md5of "$N22E3")"
t22e3_out="$(bash "$SCRIPT" --target "$N22E3" --servers "XcodeBuildMCP" 2>&1)"; rc22e3=$?
if [ "$rc22e3" -eq 1 ] && [ "$(md5of "$N22E3")" = "$n22e3_before" ] && \
   echo "$t22e3_out" | grep -q 'ERROR:' && echo "$t22e3_out" | grep -qi 'malform'; then
  ok "T22e valeur entre guillemets ET hors charset : rc=1, ERROR malform, empreinte inchangée"
else
  ko "T22e (invalide guillemetée) échec (rc=$rc22e3, sortie=[$t22e3_out])"
fi

# === T22f (valeur lue sur la SEULE ligne de la clé, injecteur) ==================================
N22F1="$WORK/t22f1.md"
cat > "$N22F1" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
vf-mcp-tools:
model: sonnet
memory: project
---
corps
EOF
n22f1_before="$(md5of "$N22F1")"
t22f1_out="$(bash "$SCRIPT" --target "$N22F1" --servers "XcodeBuildMCP" 2>&1)"; rc22f1=$?
if [ "$rc22f1" -eq 1 ] && [ "$(md5of "$N22F1")" = "$n22f1_before" ] && \
   echo "$t22f1_out" | grep -q 'ERROR:' && echo "$t22f1_out" | grep -qi 'malform'; then
  ok "T22f clé vide suivie de model: sonnet : rc=1, ERROR malform (jamais lue comme serveur 'model')"
else
  ko "T22f (clé vide) échec (rc=$rc22f1, sortie=[$t22f1_out])"
fi

N22F2="$WORK/t22f2.md"
cat > "$N22F2" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP:
  test_sim
---
corps
EOF
n22f2_before="$(md5of "$N22F2")"
t22f2_out="$(bash "$SCRIPT" --target "$N22F2" --servers "XcodeBuildMCP" 2>&1)"; rc22f2=$?
if [ "$rc22f2" -eq 1 ] && [ "$(md5of "$N22F2")" = "$n22f2_before" ] && \
   echo "$t22f2_out" | grep -q 'ERROR:' && echo "$t22f2_out" | grep -qi 'malform'; then
  ok "T22f continuation indentée (clé vide + outil sur la ligne suivante) : rc=1, ERROR malform"
else
  ko "T22f (continuation) échec (rc=$rc22f2, sortie=[$t22f2_out])"
fi

# Jumeaux (révision tour 5) : valeur VALIDE sur la ligne de la clé, continuation à 1 espace / 1 tab.
N22F3="$WORK/t22f-1espace.md"
printf -- '---\nname: vf-reviewer\ndescription: revue de code\ntools: Read, Bash, Glob, Grep\nmodel: sonnet\nmemory: project\nvf-mcp-tools: XcodeBuildMCP:test_sim\n build_sim\n---\ncorps\n' > "$N22F3"
n22f3_before="$(md5of "$N22F3")"
t22f3_out="$(bash "$SCRIPT" --target "$N22F3" --servers "XcodeBuildMCP" 2>&1)"; rc22f3=$?
if [ "$rc22f3" -eq 1 ] && [ "$(md5of "$N22F3")" = "$n22f3_before" ] && \
   echo "$t22f3_out" | grep -q 'ERROR:' && echo "$t22f3_out" | grep -qi 'malform'; then
  ok "T22f 1-espace : valeur valide + continuation indentée d'UNE espace : rc=1, ERROR malform"
else
  ko "T22f 1-espace échec (rc=$rc22f3, sortie=[$t22f3_out])"
fi

N22F4="$WORK/t22f-tabulation.md"
printf -- '---\nname: vf-reviewer\ndescription: revue de code\ntools: Read, Bash, Glob, Grep\nmodel: sonnet\nmemory: project\nvf-mcp-tools: XcodeBuildMCP:test_sim\n\tbuild_sim\n---\ncorps\n' > "$N22F4"
n22f4_before="$(md5of "$N22F4")"
t22f4_out="$(bash "$SCRIPT" --target "$N22F4" --servers "XcodeBuildMCP" 2>&1)"; rc22f4=$?
if [ "$rc22f4" -eq 1 ] && [ "$(md5of "$N22F4")" = "$n22f4_before" ] && \
   echo "$t22f4_out" | grep -q 'ERROR:' && echo "$t22f4_out" | grep -qi 'malform'; then
  ok "T22f tabulation : valeur valide + continuation indentée d'UNE tabulation : rc=1, ERROR malform"
else
  ko "T22f tabulation échec (rc=$rc22f4, sortie=[$t22f4_out])"
fi

# === T22g (clé en double, injecteur) — refusée dans les deux ordres =============================
N22G1="$WORK/t22g1.md"
cat > "$N22G1" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP:test_sim
vf-mcp-tools: XcodeBuildMCP:
---
corps
EOF
n22g1_before="$(md5of "$N22G1")"
t22g1_out="$(bash "$SCRIPT" --target "$N22G1" --servers "XcodeBuildMCP" 2>&1)"; rc22g1=$?
if [ "$rc22g1" -eq 1 ] && [ "$(md5of "$N22G1")" = "$n22g1_before" ] && \
   echo "$t22g1_out" | grep -q 'ERROR:' && echo "$t22g1_out" | grep -qi 'malform'; then
  ok "T22g clé en double (valide puis vide) : rc=1, ERROR malform"
else
  ko "T22g (ordre 1) échec (rc=$rc22g1, sortie=[$t22g1_out])"
fi

N22G2="$WORK/t22g2.md"
cat > "$N22G2" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP:
vf-mcp-tools: XcodeBuildMCP:test_sim
---
corps
EOF
n22g2_before="$(md5of "$N22G2")"
t22g2_out="$(bash "$SCRIPT" --target "$N22G2" --servers "XcodeBuildMCP" 2>&1)"; rc22g2=$?
if [ "$rc22g2" -eq 1 ] && [ "$(md5of "$N22G2")" = "$n22g2_before" ] && \
   echo "$t22g2_out" | grep -q 'ERROR:' && echo "$t22g2_out" | grep -qi 'malform'; then
  ok "T22g clé en double (vide puis valide) : rc=1, ERROR malform"
else
  ko "T22g (ordre 2) échec (rc=$rc22g2, sortie=[$t22g2_out])"
fi

# === T22h (ordre trim PUIS déquotage, injecteur) — accepté malgré blanc/CR final ================
N22H1="$WORK/t22h1.md"
printf -- '---\nname: vf-reviewer\ndescription: revue de code\ntools: Read, Bash, Glob, Grep\nmodel: sonnet\nmemory: project\nvf-mcp-tools: "XcodeBuildMCP:test_sim" \n---\ncorps\n' > "$N22H1"
t22h1_out="$(bash "$SCRIPT" --target "$N22H1" --servers "XcodeBuildMCP" 2>&1)"; rc22h1=$?
line22h1="$(toolsline "$N22H1")"
if [ "$rc22h1" -eq 0 ] && echo "$line22h1" | grep -q 'mcp__XcodeBuildMCP__test_sim' && ! echo "$t22h1_out" | grep -q 'ERROR:'; then
  ok "T22h espace finale après guillemet fermant : rc=0, token injecté"
else
  ko "T22h (espace) échec (rc=$rc22h1, sortie=[$t22h1_out])"
fi

N22H2="$WORK/t22h2.md"
printf -- '---\nname: vf-reviewer\ndescription: revue de code\ntools: Read, Bash, Glob, Grep\nmodel: sonnet\nmemory: project\nvf-mcp-tools: "XcodeBuildMCP:test_sim"\t\n---\ncorps\n' > "$N22H2"
t22h2_out="$(bash "$SCRIPT" --target "$N22H2" --servers "XcodeBuildMCP" 2>&1)"; rc22h2=$?
line22h2="$(toolsline "$N22H2")"
if [ "$rc22h2" -eq 0 ] && echo "$line22h2" | grep -q 'mcp__XcodeBuildMCP__test_sim' && ! echo "$t22h2_out" | grep -q 'ERROR:'; then
  ok "T22h tabulation finale après guillemet fermant : rc=0, token injecté"
else
  ko "T22h (tabulation) échec (rc=$rc22h2, sortie=[$t22h2_out])"
fi

N22H3="$WORK/t22h3.md"
printf -- '---\nname: vf-reviewer\ndescription: revue de code\ntools: Read, Bash, Glob, Grep\nmodel: sonnet\nmemory: project\nvf-mcp-tools: "XcodeBuildMCP:test_sim"\r\n---\ncorps\n' > "$N22H3"
t22h3_out="$(bash "$SCRIPT" --target "$N22H3" --servers "XcodeBuildMCP" 2>&1)"; rc22h3=$?
line22h3="$(toolsline "$N22H3")"
if [ "$rc22h3" -eq 0 ] && echo "$line22h3" | grep -q 'mcp__XcodeBuildMCP__test_sim' && ! echo "$t22h3_out" | grep -q 'ERROR:'; then
  ok "T22h ligne de la clé terminée par CR LF : rc=0, token injecté (verrou, lecture texte déjà universelle)"
else
  ko "T22h (CR) échec (rc=$rc22h3, sortie=[$t22h3_out])"
fi

# === T22i (clé en DERNIÈRE ligne du frontmatter, injecteur) =====================================
N22I1="$WORK/t22i1.md"
cat > "$N22I1" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools:
---
corps
EOF
n22i1_before="$(md5of "$N22I1")"
t22i1_out="$(bash "$SCRIPT" --target "$N22I1" --servers "XcodeBuildMCP" 2>&1)"; rc22i1=$?
if [ "$rc22i1" -eq 1 ] && [ "$(md5of "$N22I1")" = "$n22i1_before" ] && \
   echo "$t22i1_out" | grep -q 'ERROR:' && echo "$t22i1_out" | grep -qi 'malform' && \
   ! echo "$t22i1_out" | grep -q 'Traceback'; then
  ok "T22i clé vide en dernière ligne du frontmatter : rc=1, ERROR malform, aucun Traceback"
else
  ko "T22i (vide) échec (rc=$rc22i1, sortie=[$t22i1_out])"
fi

N22I2="$WORK/t22i2.md"
cat > "$N22I2" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools: XcodeBuildMCP:test_sim
---
corps
EOF
t22i2_out="$(bash "$SCRIPT" --target "$N22I2" --servers "XcodeBuildMCP" 2>&1)"; rc22i2=$?
line22i2="$(toolsline "$N22I2")"
if [ "$rc22i2" -eq 0 ] && echo "$line22i2" | grep -q 'mcp__XcodeBuildMCP__test_sim'; then
  ok "T22i (jumeau valide) clé valide en dernière ligne du frontmatter : rc=0, token injecté"
else
  ko "T22i (jumeau) échec (rc=$rc22i2, sortie=[$t22i2_out])"
fi

# === T22j (espace avant le deux-points, injecteur) — reconnue PRÉSENTE, refusée =================
N22J="$WORK/t22j.md"
cat > "$N22J" <<'EOF'
---
name: vf-reviewer
description: revue de code
tools: Read, Bash, Glob, Grep
model: sonnet
memory: project
vf-mcp-tools : XcodeBuildMCP:test_sim
---
corps
EOF
n22j_before="$(md5of "$N22J")"
t22j_out="$(bash "$SCRIPT" --target "$N22J" --servers "XcodeBuildMCP" 2>&1)"; rc22j=$?
if [ "$rc22j" -eq 1 ] && [ "$(md5of "$N22J")" = "$n22j_before" ] && \
   echo "$t22j_out" | grep -q 'ERROR:' && echo "$t22j_out" | grep -qi 'malform'; then
  ok "T22j espace avant le deux-points : reconnue présente, rc=1, ERROR malform (jamais ignorée en silence)"
else
  ko "T22j échec (rc=$rc22j, sortie=[$t22j_out])"
fi

# ---------- MUT-A : mutant sur la ligne unique qui passe malformed_found à vrai (Tâche 2, 43-05) --
# Cette suite n'a que ok()/ko() (l.67-68) — aucune fonction okmut ni helper de mutation : le cas
# écrit lui-même, en toutes lettres, ses trois libellés. Le mutant est placé dans une arborescence
# qui reproduit exactement plugin/dev-orchestrator/scripts/ + plugin/_internal/lib/, faute de quoi
# le locator vf-portable.sh (remontée bornée) ne le trouve pas depuis un mktemp isolé.
MUT_A_MOTIF='malformed_found = True'
MUT_A_N="$(grep -Fc -- "$MUT_A_MOTIF" "$SCRIPT")"
if [ "$MUT_A_N" -ne 1 ]; then
  ko "MUT-A REFUSE : motif '$MUT_A_MOTIF' absent ou non unique dans $SCRIPT (n=$MUT_A_N)"
else
  MUT_A_TREE="$WORK/mut-a-tree"
  mkdir -p "$MUT_A_TREE/plugin/dev-orchestrator/scripts" "$MUT_A_TREE/plugin/_internal/lib"
  MUT_A_REAL_PORTABLE="$(cd "$(dirname "$SCRIPT")/../../_internal/lib" && pwd)/vf-portable.sh"
  cp "$MUT_A_REAL_PORTABLE" "$MUT_A_TREE/plugin/_internal/lib/vf-portable.sh"
  MUT_A_TMP="$MUT_A_TREE/plugin/dev-orchestrator/scripts/inject-mcp-tools.sh"
  MUT_A_ENV="$MUT_A_MOTIF" awk '
    index($0, ENVIRON["MUT_A_ENV"]) {
      match($0, /^[ \t]*/)
      print substr($0, RSTART, RLENGTH) "pass"
      next
    }
    { print }
  ' "$SCRIPT" > "$MUT_A_TMP"
  if cmp -s "$MUT_A_TMP" "$SCRIPT"; then
    ko "MUT-A REFUSE : mutation produit un fichier identique à l'original"
  elif ! bash -n "$MUT_A_TMP" 2>/dev/null; then
    ko "MUT-A REFUSE : bash -n échoue sur le mutant"
  else
    MUT_A_FIXTURE="$WORK/mut-a-fixture.md"
    cat > "$MUT_A_FIXTURE" <<'EOF'
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
    bash "$MUT_A_TMP" --target "$MUT_A_FIXTURE" --servers "XcodeBuildMCP" >/dev/null 2>&1; MUT_A_RC_MUTANT=$?
    bash "$SCRIPT" --target "$MUT_A_FIXTURE" --servers "XcodeBuildMCP" >/dev/null 2>&1; MUT_A_RC_ORIG=$?
    if [ "$MUT_A_RC_MUTANT" -eq 0 ] && [ "$MUT_A_RC_ORIG" -eq 1 ]; then
      ok "MUT-A TUE : rc_mutant=0 attendu 0, rc_original=1 attendu 1"
    else
      ko "MUT-A NON TUE : rc_mutant=$MUT_A_RC_MUTANT attendu 0, rc_original=$MUT_A_RC_ORIG attendu 1"
    fi
  fi
fi

# T23 à T31 : documentés en Phase 21, jamais présents dans le code de cette suite (constat
# Phase 43, 2026-09-25) — relevé pour Samuel, non restaurés ici. Seuls T32 et T33 sont ajoutés
# (43-05) pour juger (b) : l'union projet ∪ global existe déjà dans le code (Phase 21,
# inject-mcp-tools.sh l.245-259), ce plan la TESTE, il ne la modifie pas.

# === T32 (NON-RÉGRESSION, Phase 43 FABR-10 b) — union scope projet ∪ scope global : DÉJÀ ========
# opérante avant toute écriture de ce plan (inject-mcp-tools.sh l.245-259) — ce cas la verrouille
# pendant que (b) réécrit les messages de WINDOWS #4. Projet mobile-mcp, global XcodeBuildMCP.
D32="$WORK/t32"; mkdir -p "$D32"
N32="$D32/vf-reviewer.md"; mk_named "$N32"
mk_mcp '{ "mcpServers": { "mobile-mcp": {} } }'
T32_CLAUDE_JSON="$WORK/t32-claude.json"
printf '%s\n' '{ "mcpServers": { "XcodeBuildMCP": {} } }' > "$T32_CLAUDE_JSON"
t32_out="$(VF_CLAUDE_JSON="$T32_CLAUDE_JSON" bash "$SCRIPT" --target "$N32" --mcp-json "$WORK/.mcp.json" 2>&1)"; rc32=$?
line32="$(toolsline "$N32")"
if [ "$rc32" -eq 0 ] && echo "$line32" | grep -q 'mcp__XcodeBuildMCP__test_sim' && \
   echo "$line32" | grep -q 'mcp__XcodeBuildMCP__build_sim' && \
   echo "$line32" | grep -q 'mcp__XcodeBuildMCP__clean' && \
   ! echo "$t32_out" | grep -q 'WARNING:'; then
  ok "T32 (NON-RÉGRESSION) union scope projet ∪ scope global : serveur du scope global injecté, aucun WARNING"
else
  ko "T32 échec (rc=$rc32, ligne=$line32, sortie=[$t32_out])"
fi

# === T33 — Union scope projet ∪ scope global, serveur cité absent des DEUX : WARNING nommant =====
# « union » et les DEUX chemins de sources (Phase 43, FABR-10 b).
D33="$WORK/t33"; mkdir -p "$D33"
N33="$D33/vf-reviewer.md"; mk_named "$N33"; n33_before="$(md5of "$N33")"
mk_mcp '{ "mcpServers": { "mobile-mcp": {} } }'
T33_CLAUDE_JSON="$WORK/t33-claude.json"
printf '%s\n' '{ "mcpServers": { "context7": {} } }' > "$T33_CLAUDE_JSON"
t33_out="$(VF_CLAUDE_JSON="$T33_CLAUDE_JSON" bash "$SCRIPT" --target "$N33" --mcp-json "$WORK/.mcp.json" 2>&1)"; rc33=$?
if [ "$rc33" -eq 0 ] && [ "$(md5of "$N33")" = "$n33_before" ] && \
   echo "$t33_out" | grep -q 'WARNING:' && \
   echo "$t33_out" | grep -qi 'union' && \
   echo "$t33_out" | grep -qF "$WORK/.mcp.json" && \
   echo "$t33_out" | grep -qF "$T33_CLAUDE_JSON"; then
  ok "T33 union scope projet ∪ scope global, serveur absent des DEUX : WARNING nommant union et les deux chemins de sources"
else
  ko "T33 échec (rc=$rc33, sortie=[$t33_out])"
fi

# === Bilan ===================================================================================
echo ""
echo "  Bilan : $pass OK, $fail KO"
[ "$fail" -eq 0 ] || exit 1
echo "  ✓ inject-mcp-tools.sh conforme (ADR-051)"
exit 0
