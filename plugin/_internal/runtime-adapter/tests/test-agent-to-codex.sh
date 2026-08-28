#!/usr/bin/env bash
# test-agent-to-codex.sh — Suite dédiée de agent-to-codex.mjs / register-codex-agent.sh
# (Phase 38, lot 5, ADPT-01/ADPT-04).
#
# Couvre :
#   T1 — conversion de vf-content-writer.md (agent réel) -> .toml contenant name,
#        description, developer_instructions, model, model_reasoning_effort.
#   T2 — le corps Markdown source apparaît INTÉGRALEMENT dans developer_instructions (comparé
#        par sous-chaîne sur le corps complet, pas juste un extrait).
#   T3 — memory/tools du frontmatter source N'APPARAISSENT PAS dans le .toml produit, ET le
#        digest les marque explicitement LOST/PENDING (jamais une case absente).
#   T4 — pose RÉELLE sur un CODEX_HOME de banc isolé (mktemp -d, jamais ~/.codex réel) via
#        register-codex-agent.sh --verify : le rôle posé ne déclenche AUCUN "startup warning"
#        de 'codex doctor --json' (piège n°1 : un rôle malformé est ignoré en silence, jamais
#        "pas de crash donc c'est bon"). SKIP propre si `codex` absent du PATH d'exécution.
#        Sous-cas : un rôle délibérément malformé (developer_instructions absent) DÉCLENCHE bien
#        un "startup warning" référençant son chemin — preuve que le détecteur discrimine
#        vraiment (mutation tuée), pas un test qui rougirait sur n'importe quoi.
#   T4c — collision de nom : un second rôle de MÊME nom posé ailleurs sous $CODEX_HOME/agents
#        déclenche un "startup warning" qui ne cite JAMAIS le chemin du .toml (seulement le nom
#        et le répertoire parent) — famille de malformation distincte de T4b, doit rougir aussi.
#   T5 — échec de conversion propre (frontmatter absent / corps vide) : exit non-zéro, message
#        explicite, aucun .toml produit.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ADAPTER_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$ADAPTER_DIR/../../.." && pwd)"
CONVERTER="$ADAPTER_DIR/agent-to-codex.mjs"
REGISTER="$ADAPTER_DIR/register-codex-agent.sh"
FIXTURE_AGENT="$REPO/plugin/content-bundle/agents/vf-content-writer.md"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-agent-to-codex (adapter: $ADAPTER_DIR) =="

if [ ! -f "$CONVERTER" ]; then
  ko "agent-to-codex.mjs introuvable"
  echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
  exit 1
fi
if [ ! -x "$REGISTER" ]; then
  ko "register-codex-agent.sh introuvable ou non exécutable"
  echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
  exit 1
fi
if [ ! -f "$FIXTURE_AGENT" ]; then
  ko "fixture vf-content-writer.md introuvable : $FIXTURE_AGENT"
  echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
  exit 1
fi
if ! command -v node >/dev/null 2>&1; then
  ko "node introuvable dans le PATH — suite non exécutable"
  echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# ---------------------------------------------------------------------------
# T1 — conversion réelle, champs requis présents.
# ---------------------------------------------------------------------------
OUT_TOML="$WORKDIR/vf-content-writer.toml"
CONV_ERR="$(node "$CONVERTER" "$FIXTURE_AGENT" --out "$OUT_TOML" 2>&1 1>/dev/null)"
CONV_STATUS=$?
if [ "$CONV_STATUS" -eq 0 ] && [ -f "$OUT_TOML" ] \
  && grep -qF 'name = "vf-content-writer"' "$OUT_TOML" \
  && grep -q '^description = "' "$OUT_TOML" \
  && grep -qF 'developer_instructions = """' "$OUT_TOML" \
  && grep -q '^model = "' "$OUT_TOML" \
  && grep -q '^model_reasoning_effort = "' "$OUT_TOML"; then
  ok "T1 : vf-content-writer.md -> .toml contenant name/description/developer_instructions/model/model_reasoning_effort"
else
  ko "T1 : conversion incomplète (status=$CONV_STATUS, err='$CONV_ERR')"
fi

# ---------------------------------------------------------------------------
# T2 — corps Markdown intégral (pas tronqué) dans developer_instructions.
# ---------------------------------------------------------------------------
# Corps source = tout ce qui suit le second '---' du frontmatter.
SOURCE_BODY_FILE="$WORKDIR/source_body.txt"
awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$FIXTURE_AGENT" > "$SOURCE_BODY_FILE"
# Dernière ligne non vide du corps source : si elle apparaît dans le .toml produit, le corps
# n'a pas été tronqué en cours de route (un tronquage couperait avant la fin).
LAST_BODY_LINE="$(grep -v '^[[:space:]]*$' "$SOURCE_BODY_FILE" | tail -1)"
FIRST_BODY_LINE="$(grep -v '^[[:space:]]*$' "$SOURCE_BODY_FILE" | head -1)"
if [ -n "$LAST_BODY_LINE" ] && [ -n "$FIRST_BODY_LINE" ] \
  && grep -qF "$FIRST_BODY_LINE" "$OUT_TOML" \
  && grep -qF "$LAST_BODY_LINE" "$OUT_TOML"; then
  ok "T2 : corps Markdown intégral (première ET dernière ligne non vides retrouvées dans developer_instructions)"
else
  ko "T2 : corps tronqué ou absent (première='$FIRST_BODY_LINE', dernière='$LAST_BODY_LINE' non retrouvées dans $OUT_TOML)"
fi

# ---------------------------------------------------------------------------
# T3 — memory/tools absents du .toml, digest les marque LOST/PENDING explicitement.
# ---------------------------------------------------------------------------
DIGEST_TEXT="$(node "$CONVERTER" "$FIXTURE_AGENT" --out "$WORKDIR/t3.toml" 2>&1 1>/dev/null)"
if ! grep -qi '^memory' "$WORKDIR/t3.toml" 2>/dev/null \
  && ! grep -qi '^tools' "$WORKDIR/t3.toml" 2>/dev/null \
  && ! grep -qi '^\[tools\]' "$WORKDIR/t3.toml" 2>/dev/null \
  && printf '%s' "$DIGEST_TEXT" | grep -qE '^memory: LOST' \
  && printf '%s' "$DIGEST_TEXT" | grep -qE '^tools: PENDING'; then
  ok "T3 : memory/tools ABSENTS du .toml, digest déclare 'memory: LOST' et 'tools: PENDING' explicitement"
else
  ko "T3 : digest ou .toml non conformes (digest='$DIGEST_TEXT')"
fi

# ---------------------------------------------------------------------------
# T4 — pose RÉELLE + vérification ADPT-04 sur CODEX_HOME de banc isolé.
# ---------------------------------------------------------------------------
if ! command -v codex >/dev/null 2>&1; then
  skip "T4 : codex absent du PATH d'exécution — pose réelle non vérifiable ici (attendu en CI)"
else
  CODEX_HOME_ISOLATED="$WORKDIR/codex-home-isolated"
  mkdir -p "$CODEX_HOME_ISOLATED"

  # Baseline ~/.codex réel — jamais touché par cette suite (ceinture + bretelles).
  REAL_CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
  BASELINE_CONFIG_SHA=""
  if [ -f "$REAL_CODEX_HOME/config.toml" ]; then
    BASELINE_CONFIG_SHA="$(shasum -a 256 "$REAL_CODEX_HOME/config.toml" 2>/dev/null | awk '{print $1}')"
  fi
  BASELINE_AGENTS_PRESENT=0
  [ -d "$REAL_CODEX_HOME/agents" ] && BASELINE_AGENTS_PRESENT=1

  REG_OUT="$(bash "$REGISTER" "$FIXTURE_AGENT" --codex-home "$CODEX_HOME_ISOLATED" --verify 2>&1)"
  REG_STATUS=$?

  AFTER_CONFIG_SHA=""
  if [ -f "$REAL_CODEX_HOME/config.toml" ]; then
    AFTER_CONFIG_SHA="$(shasum -a 256 "$REAL_CODEX_HOME/config.toml" 2>/dev/null | awk '{print $1}')"
  fi
  AFTER_AGENTS_PRESENT=0
  [ -d "$REAL_CODEX_HOME/agents" ] && AFTER_AGENTS_PRESENT=1

  if [ "$REG_STATUS" -eq 0 ] \
    && printf '%s' "$REG_OUT" | grep -q 'ADPT-04 vérifié' \
    && [ -f "$CODEX_HOME_ISOLATED/agents/vibeflow/vf-content-writer.toml" ] \
    && [ "$BASELINE_CONFIG_SHA" = "$AFTER_CONFIG_SHA" ] \
    && [ "$BASELINE_AGENTS_PRESENT" -eq "$AFTER_AGENTS_PRESENT" ]; then
    ok "T4 : rôle posé + ADPT-04 vérifié sur banc isolé, \$HOME/.codex réel intact (sha256 identique, agents/ inchangé)"
  else
    ko "T4 : échec pose/vérification réelle (status=$REG_STATUS, out='$REG_OUT', ~/.codex sha avant='$BASELINE_CONFIG_SHA' après='$AFTER_CONFIG_SHA')"
  fi

  # Sous-cas discriminant : un rôle malformé (sans developer_instructions) DOIT déclencher un
  # startup warning référençant son chemin — preuve que le détecteur ADPT-04 discrimine
  # vraiment (mutation tuée), pas un gate qui passerait sur n'importe quel contenu.
  BROKEN_DIR="$CODEX_HOME_ISOLATED/agents/vibeflow"
  BROKEN_TOML="$BROKEN_DIR/t4-broken-role.toml"
  mkdir -p "$BROKEN_DIR"
  cat > "$BROKEN_TOML" <<'EOF'
name = "t4-broken-role"
description = "rôle délibérément malformé (pas de developer_instructions) — preuve du détecteur ADPT-04"
EOF
  DOCTOR_JSON_BROKEN="$(CODEX_HOME="$CODEX_HOME_ISOLATED" codex doctor --json 2>/dev/null)"
  rm -f "$BROKEN_TOML"
  if printf '%s' "$DOCTOR_JSON_BROKEN" | grep -F "$BROKEN_TOML" | grep -qi 'startup warning'; then
    ok "T4b (mutation tuée) : un rôle malformé sans developer_instructions DÉCLENCHE bien un 'startup warning' référençant son chemin — le détecteur ADPT-04 discrimine réellement"
  else
    ko "T4b : le détecteur ADPT-04 ne discrimine PAS un rôle malformé (aucun startup warning trouvé) — le gate T4 pourrait passer sur n'importe quoi"
  fi

  # T4c — collision de nom (revue Phase 38, finding majeur) : MESURÉ, un second rôle de MÊME nom
  # posé ailleurs sous $CODEX_HOME/agents déclenche un 'startup warning' de forme DIFFÉRENTE
  # ("duplicate agent role name `<name>` discovered in <AGENTS_DIR>") qui ne cite JAMAIS le
  # chemin du .toml — seulement le nom du rôle et le répertoire PARENT. Avant fix, le check ne
  # cherchait que '$ROLE_TOML' et déclarait 'ADPT-04 vérifié' malgré la collision (rouge avant
  # fix reproduit hors suite, cf. digest de mission). Ici : rejoue --verify avec le rôle déjà
  # posé par T4 PLUS un doublon de même nom au niveau parent — doit rougir (exit 1) et le
  # message doit citer la collision, pas juste "vérifié".
  COLLISION_DIR="$CODEX_HOME_ISOLATED/agents"
  COLLISION_TOML="$COLLISION_DIR/vf-content-writer.toml"
  cat > "$COLLISION_TOML" <<'EOF'
name = "vf-content-writer"
description = "role de collision (T4c) — même nom que le rôle vibeflow/vf-content-writer.toml posé par T4"
developer_instructions = """
placeholder body collision T4c
"""
EOF
  REG_OUT_T4C="$(bash "$REGISTER" "$FIXTURE_AGENT" --codex-home "$CODEX_HOME_ISOLATED" --verify 2>&1)"
  REG_STATUS_T4C=$?
  rm -f "$COLLISION_TOML"
  if [ "$REG_STATUS_T4C" -ne 0 ] \
    && printf '%s' "$REG_OUT_T4C" | grep -qi 'ADPT-04 ÉCHEC' \
    && printf '%s' "$REG_OUT_T4C" | grep -qi 'collision'; then
    ok "T4c : collision de nom (rôle dupliqué sous \$CODEX_HOME/agents) → ADPT-04 ÉCHEC, exit non-zéro (le warning ne cite jamais \$ROLE_TOML mais le check le détecte quand même)"
  else
    ko "T4c : collision de nom NON détectée (status=$REG_STATUS_T4C, out='$REG_OUT_T4C') — ADPT-04 se déclarerait vérifié alors que Codex ignore un rôle en silence"
  fi
fi

# ---------------------------------------------------------------------------
# T5 — échec de conversion propre (corps vide) : exit non-zéro, message explicite.
# ---------------------------------------------------------------------------
BROKEN_AGENT="$WORKDIR/broken-agent.md"
cat > "$BROKEN_AGENT" <<'EOF'
---
name: broken-agent
description: agent sans corps
---
EOF
OUT_BROKEN="$WORKDIR/broken.toml"
ERR_BROKEN="$(node "$CONVERTER" "$BROKEN_AGENT" --out "$OUT_BROKEN" 2>&1 1>/dev/null)"
STATUS_BROKEN=$?
if [ "$STATUS_BROKEN" -ne 0 ] && [ ! -s "$OUT_BROKEN" ] 2>/dev/null && printf '%s' "$ERR_BROKEN" | grep -qi 'corps'; then
  ok "T5 : agent sans corps -> échec de conversion propre, message explicite, aucun .toml exploitable produit"
else
  ko "T5 : échec de conversion non conforme (status=$STATUS_BROKEN, err='$ERR_BROKEN')"
fi

echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ] && exit 0 || exit 1
