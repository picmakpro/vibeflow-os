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
#   T6 — Bloquant 1 (D-38) : mapping modèle Claude -> Codex, jamais une recopie littérale.
#        T6a : model opus -> valeur Codex valide mesurée (gpt-5.6-terra), digest 'model:
#        MAPPED' cite source ET cible. T6b : modèle source hors table -> ROUGE, aucun repli
#        silencieux, aucun .toml produit.
#   T7 — Bloquant 2 (D-38) : parseur YAML frontmatter réel. T7a : description: > (scalaire
#        replié, cas réel plugin/conductor/AGENT.md) -> texte complet, jamais '">"' littéral.
#        T7b : styles |, >-, |- tous parsés (littéral vs replié, clip vs strip).
#   T8 — chemin d'appel à lien symbolique : node résout le lien pour import.meta.url mais pas pour
#        process.argv[1], donc isMainModule() (comparaison des deux) rendait false et le CLI sortait
#        rc=0 sans rien écrire ni dire. T8a : par un lien, même .toml et même digest que par le
#        chemin physique. T8b : register-codex-agent.sh lancé par un lien pose réellement le .toml.
#        T8c : l'import du module par un lien n'exécute pas le CLI (la garde isMainModule tient
#        encore). Le lien est créé par la suite (rouge sur Linux comme sur macOS) ; SKIP propre
#        si `ln -s` est indisponible.
#   T9 — « rôle posé » n'est annoncé que si le .toml a été écrit PAR CE RUN. Une seule variable
#        change : le convertisseur placé à côté d'une copie du registrar. T9a : convertisseur qui
#        sort 0 sans rien écrire, aucun .toml préexistant -> refus (rc != 0), pas de « rôle posé ».
#        T9b : même convertisseur, mais un .toml d'une pose précédente existe (un simple test
#        d'existence passerait à tort) -> refus, l'ancien .toml reste intact. T9c (témoin) :
#        convertisseur réel, .toml périmé présent -> rôle posé et contenu renouvelé. T9d :
#        convertisseur qui crée un fichier VIDE -> refus aussi (un fichier présent ne suffit pas).
#        Le refus se reconnaît à son message « sans écrire de rôle » : le mv qui suit la garde
#        échouerait de toute façon sur un fichier absent, mais avec un autre message.
#        Conséquence : pour le fichier absent (T9a, T9b) la garde par mv protège seule du faux succès,
#        et la garde de contenu (-s) n'a d'effet observable que sur T9d (fichier vide). Les étiquettes
#        ko distinguent « faux succès » (code 0 ou « rôle posé » affiché) de « refus au mauvais
#        message » (code non nul, message attendu absent).
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


# ---------------------------------------------------------------------------
# T6 — mapping modèle Claude -> Codex (Bloquant 1) : jamais de recopie littérale, jamais de
# repli silencieux sur un modèle source inconnu.
# ---------------------------------------------------------------------------
CONDUCTOR_AGENT="$REPO/plugin/conductor/AGENT.md"
if [ ! -f "$CONDUCTOR_AGENT" ]; then
  ko "T6/T7a : fixture conductor/AGENT.md introuvable : $CONDUCTOR_AGENT"
else
  OUT_CONDUCTOR="$WORKDIR/conductor.toml"
  DIGEST_CONDUCTOR="$(node "$CONVERTER" "$CONDUCTOR_AGENT" --out "$OUT_CONDUCTOR" 2>&1 1>/dev/null)"
  if [ -f "$OUT_CONDUCTOR" ] \
    && ! grep -qF 'model = "opus"' "$OUT_CONDUCTOR" \
    && grep -qE '^model = "gpt-5\.6-terra"$' "$OUT_CONDUCTOR" \
    && printf '%s' "$DIGEST_CONDUCTOR" | grep -qE '^model: MAPPED.*opus.*gpt-5\.6-terra'; then
    ok "T6a : model opus -> valeur Codex valide mesurée (gpt-5.6-terra), digest 'model: MAPPED' cite source ET cible"
  else
    ko "T6a : mapping opus non conforme (digest='$DIGEST_CONDUCTOR')"
  fi

  # ---------------------------------------------------------------------------
  # T7a — description: > (cas réel conductor/AGENT.md) -> texte complet, jamais '">"' littéral.
  # ---------------------------------------------------------------------------
  if grep -qE '^description = ">"$' "$OUT_CONDUCTOR"; then
    ko "T7a : description repliée réduite au seul indicateur '\">\"' (piège n°2 non corrigé)"
  elif grep -qF 'Orchestrateur méta et gardien' "$OUT_CONDUCTOR" && grep -qF 'migrateur' "$OUT_CONDUCTOR"; then
    ok "T7a : description: > (scalaire replié) -> texte complet dans le .toml, jamais '\">\"' littéral"
  else
    ko "T7a : description repliée mal parsée (contenu de $OUT_CONDUCTOR manquant/tronqué)"
  fi
fi

UNKNOWN_MODEL_AGENT="$WORKDIR/unknown-model-agent.md"
cat > "$UNKNOWN_MODEL_AGENT" <<'EOF'
---
name: unknown-model-agent
description: agent avec un modèle source hors table de correspondance
model: mistral-large
---

Corps minimal non vide.
EOF
ERR_UNKNOWN_MODEL="$(node "$CONVERTER" "$UNKNOWN_MODEL_AGENT" --out "$WORKDIR/unknown-model.toml" 2>&1 1>/dev/null)"
STATUS_UNKNOWN_MODEL=$?
if [ "$STATUS_UNKNOWN_MODEL" -ne 0 ] && [ ! -f "$WORKDIR/unknown-model.toml" ] \
  && printf '%s' "$ERR_UNKNOWN_MODEL" | grep -qi 'mistral-large' \
  && printf '%s' "$ERR_UNKNOWN_MODEL" | grep -qi 'CLAUDE_TO_CODEX_MODEL'; then
  ok "T6b : modèle source inconnu (mistral-large) -> ROUGE, aucun repli silencieux, message explicite, aucun .toml produit"
else
  ko "T6b : modèle inconnu non rejeté (status=$STATUS_UNKNOWN_MODEL, err='$ERR_UNKNOWN_MODEL')"
fi

# ---------------------------------------------------------------------------
# T7b — styles YAML |, >-, |- (Bloquant 2) : tous parsés, jamais réduits à l'indicateur seul.
# ---------------------------------------------------------------------------
run_style_case() {
  local style_label="$1" indicator="$2"
  local f="$WORKDIR/style-$style_label.md"
  cat > "$f" <<EOF
---
name: style-agent
description: $indicator
  Première ligne de la description.
  Deuxième ligne de la description.
model: sonnet
---

Corps minimal non vide.
EOF
  local out="$WORKDIR/out-$style_label.toml"
  local err
  err="$(node "$CONVERTER" "$f" --out "$out" 2>&1 1>/dev/null)"
  if [ -f "$out" ] \
    && grep -qF 'Première ligne de la description.' "$out" \
    && grep -qF 'Deuxième ligne de la description.' "$out" \
    && ! grep -qxF "description = \"$indicator\"" "$out"; then
    ok "T7b : style '$indicator' -> description complète, jamais réduite au seul indicateur"
  else
    ko "T7b : style '$indicator' mal parsé (out='$(cat "$out" 2>/dev/null)', err='$err')"
  fi
}
run_style_case 'literal' '|'
run_style_case 'folded-strip' '>-'
run_style_case 'literal-strip' '|-'

# ---------------------------------------------------------------------------
# T8 — chemin d'appel qui traverse un lien symbolique : même sortie que par le chemin physique.
# Une seule variable change par rapport à un appel direct : le chemin passé à node. Le lien est
# posé sous $WORKDIR par la suite elle-même (aucune dépendance au /tmp de la machine).
# ---------------------------------------------------------------------------
LINK_DIR="$WORKDIR/lien-adaptateur"
if ln -s "$ADAPTER_DIR" "$LINK_DIR" 2>/dev/null && [ -L "$LINK_DIR" ]; then
  PHYS_TOML="$WORKDIR/t8-physique.toml"
  LINK_TOML="$WORKDIR/t8-via-lien.toml"
  PHYS_DIGEST="$(node "$CONVERTER" "$FIXTURE_AGENT" --out "$PHYS_TOML" 2>&1 1>/dev/null)"
  LINK_DIGEST="$(node "$LINK_DIR/agent-to-codex.mjs" "$FIXTURE_AGENT" --out "$LINK_TOML" 2>&1 1>/dev/null)"
  LINK_STATUS=$?
  if [ "$LINK_STATUS" -eq 0 ] && [ -s "$LINK_TOML" ] && [ -s "$PHYS_TOML" ] \
    && cmp -s "$PHYS_TOML" "$LINK_TOML" \
    && [ -n "$LINK_DIGEST" ] && [ "$LINK_DIGEST" = "$PHYS_DIGEST" ]; then
    ok "T8a : conversion par un chemin à lien symbolique -> même .toml et même digest que par le chemin physique"
  else
    ko "T8a : conversion par lien symbolique muette ou différente (status=$LINK_STATUS, .toml présent=$([ -s "$LINK_TOML" ] && echo oui || echo non), digest lien='$LINK_DIGEST')"
  fi

  # T8b — de bout en bout : register-codex-agent.sh lancé par le lien pose réellement le rôle.
  # Le défaut d'origine annonçait « rôle posé » (rc=0) sans écrire le fichier.
  CH_LINK="$WORKDIR/codex-home-lien"
  OUT_REG="$(bash "$LINK_DIR/register-codex-agent.sh" "$FIXTURE_AGENT" --codex-home "$CH_LINK" 2>&1)"
  STATUS_REG=$?
  if [ "$STATUS_REG" -eq 0 ] && grep -qF 'name = "vf-content-writer"' "$CH_LINK/agents/vibeflow/vf-content-writer.toml" 2>/dev/null; then
    ok "T8b : register-codex-agent.sh lancé par un lien symbolique -> rôle .toml réellement posé"
  else
    ko "T8b : register par lien symbolique : status=$STATUS_REG, .toml présent=$([ -f "$CH_LINK/agents/vibeflow/vf-content-writer.toml" ] && echo oui || echo non), sortie='$OUT_REG'"
  fi

  # T8c — la garde tient : importer le module par le lien (sans qu'il soit le script lancé) ne
  # déclenche pas le CLI. Un correctif qui rendrait isMainModule() toujours vrai afficherait
  # l'usage et sortirait en 2.
  IMPORTER="$WORKDIR/t8-importeur.mjs"
  printf "import { convertAgentToCodexRole } from '%s/agent-to-codex.mjs';\nconsole.log(typeof convertAgentToCodexRole);\n" "$LINK_DIR" > "$IMPORTER"
  IMPORT_OUT="$(node "$IMPORTER" 2>&1)"
  IMPORT_STATUS=$?
  if [ "$IMPORT_STATUS" -eq 0 ] && [ "$IMPORT_OUT" = "function" ]; then
    ok "T8c : import du module par un lien symbolique -> aucune exécution du CLI (export disponible, aucune sortie parasite)"
  else
    ko "T8c : import par lien symbolique : status=$IMPORT_STATUS, sortie='$IMPORT_OUT' (attendu : 'function' seul, rc 0)"
  fi
else
  skip "T8 : ln -s indisponible sur ce poste, chemin à lien symbolique non testable ici"
fi

# ---------------------------------------------------------------------------
# T9 — le registrar n'annonce « rôle posé » que si le .toml a été écrit par CE run. Copie du
# registrar posée à côté d'un convertisseur : SCRIPT_DIR en dérive CONVERTER, donc seul le
# convertisseur change entre T9a/T9b (bouchon : sort 0, n'écrit rien) et T9c (convertisseur réel).
# ---------------------------------------------------------------------------
T9_ROLE_REL="agents/vibeflow/vf-content-writer.toml"
# Base RÉSOLUE (pwd -P) : le convertisseur réel de T9c ne doit pas dépendre du défaut de lien
# symbolique que T8 couvre (sur macOS le mktemp -d passe par le lien /var -> /private/var).
T9_BASE="$(cd "$WORKDIR" && pwd -P)"
T9_STUB_DIR="$T9_BASE/t9-bouchon"
T9_REAL_DIR="$T9_BASE/t9-reel"
mkdir -p "$T9_STUB_DIR" "$T9_REAL_DIR"
cp "$REGISTER" "$T9_STUB_DIR/register-codex-agent.sh"
cp "$REGISTER" "$T9_REAL_DIR/register-codex-agent.sh"
cp "$CONVERTER" "$T9_REAL_DIR/agent-to-codex.mjs"
printf 'process.exit(0);\n' > "$T9_STUB_DIR/agent-to-codex.mjs"

# Diagnostic des rouges de T9, pour que l'étiquette dise ce qui s'est passé : faux succès (code 0
# ou « rôle posé » affiché), refus au mauvais message (code non nul sans « sans écrire de rôle »),
# ou refus correct mais effet de bord inattendu sur les fichiers.
t9_diag() {
  local status="$1" out="$2" err="$3"
  if [ "$status" -eq 0 ] || printf '%s%s' "$out" "$err" | grep -qF 'rôle posé'; then
    echo "faux succès"
  elif ! printf '%s' "$err" | grep -qF 'sans écrire de rôle'; then
    echo "refus au mauvais message (code non nul, « sans écrire de rôle » absent)"
  else
    echo "refus attendu mais effet de bord inattendu sur les fichiers"
  fi
}

# T9a — aucun .toml préexistant : le bouchon n'écrit rien, le registrar doit refuser.
CH_T9A="$WORKDIR/codex-home-t9a"
OUT_T9A="$(bash "$T9_STUB_DIR/register-codex-agent.sh" "$FIXTURE_AGENT" --codex-home "$CH_T9A" 2>"$WORKDIR/t9a.err")"
STATUS_T9A=$?
ERR_T9A="$(cat "$WORKDIR/t9a.err")"
if [ "$STATUS_T9A" -ne 0 ] \
  && ! printf '%s%s' "$OUT_T9A" "$ERR_T9A" | grep -qF 'rôle posé' \
  && printf '%s' "$ERR_T9A" | grep -qF '[register-codex-agent]' \
  && printf '%s' "$ERR_T9A" | grep -qF 'sans écrire de rôle' \
  && [ ! -e "$CH_T9A/$T9_ROLE_REL" ]; then
  ok "T9a : convertisseur qui n'écrit rien -> refus explicite sur stderr (rc=$STATUS_T9A), aucun « rôle posé », aucun .toml"
else
  ko "T9a : $(t9_diag "$STATUS_T9A" "$OUT_T9A" "$ERR_T9A") (status=$STATUS_T9A, stdout='$OUT_T9A', stderr='$ERR_T9A', .toml présent=$([ -e "$CH_T9A/$T9_ROLE_REL" ] && echo oui || echo non))"
fi

# T9b — un .toml d'une pose précédente existe : un simple test d'existence passerait à tort.
CH_T9B="$WORKDIR/codex-home-t9b"
mkdir -p "$CH_T9B/agents/vibeflow"
printf 'ANCIEN-ROLE-POSE-PAR-UN-RUN-PRECEDENT\n' > "$CH_T9B/$T9_ROLE_REL"
OUT_T9B="$(bash "$T9_STUB_DIR/register-codex-agent.sh" "$FIXTURE_AGENT" --codex-home "$CH_T9B" 2>"$WORKDIR/t9b.err")"
STATUS_T9B=$?
ERR_T9B="$(cat "$WORKDIR/t9b.err")"
if [ "$STATUS_T9B" -ne 0 ] \
  && ! printf '%s%s' "$OUT_T9B" "$ERR_T9B" | grep -qF 'rôle posé' \
  && printf '%s' "$ERR_T9B" | grep -qF '[register-codex-agent]' \
  && printf '%s' "$ERR_T9B" | grep -qF 'sans écrire de rôle' \
  && [ "$(cat "$CH_T9B/$T9_ROLE_REL")" = "ANCIEN-ROLE-POSE-PAR-UN-RUN-PRECEDENT" ]; then
  ok "T9b : .toml périmé présent + convertisseur qui n'écrit rien -> refus (rc=$STATUS_T9B), pas de « rôle posé », ancien .toml intact"
else
  ko "T9b : $(t9_diag "$STATUS_T9B" "$OUT_T9B" "$ERR_T9B") avec un ancien .toml présent (status=$STATUS_T9B, stdout='$OUT_T9B', stderr='$ERR_T9B', contenu='$(cat "$CH_T9B/$T9_ROLE_REL" 2>/dev/null)')"
fi

# T9c — témoin : même scénario (.toml périmé présent), convertisseur réel -> pose et renouvelle.
CH_T9C="$WORKDIR/codex-home-t9c"
mkdir -p "$CH_T9C/agents/vibeflow"
printf 'ANCIEN-ROLE-POSE-PAR-UN-RUN-PRECEDENT\n' > "$CH_T9C/$T9_ROLE_REL"
OUT_T9C="$(bash "$T9_REAL_DIR/register-codex-agent.sh" "$FIXTURE_AGENT" --codex-home "$CH_T9C" 2>&1)"
STATUS_T9C=$?
if [ "$STATUS_T9C" -eq 0 ] \
  && printf '%s' "$OUT_T9C" | grep -qF "rôle posé : $CH_T9C/$T9_ROLE_REL" \
  && grep -qF 'name = "vf-content-writer"' "$CH_T9C/$T9_ROLE_REL" \
  && ! grep -qF 'ANCIEN-ROLE' "$CH_T9C/$T9_ROLE_REL" \
  && ! ls "$CH_T9C/agents/vibeflow" | grep -qv '^vf-content-writer\.toml$'; then
  ok "T9c : convertisseur réel + .toml périmé -> « rôle posé », contenu renouvelé, aucun fichier temporaire laissé"
else
  ko "T9c : pose légitime cassée (status=$STATUS_T9C, sortie='$OUT_T9C', dossier='$(ls "$CH_T9C/agents/vibeflow" 2>/dev/null | tr '\n' ' ')')"
fi

# T9d — convertisseur qui crée un fichier VIDE puis sort 0 : le mv réussirait, seule la garde de
# contenu (fichier non vide) empêche d'annoncer un rôle qui n'en est pas un.
T9_EMPTY_DIR="$T9_BASE/t9-vide"
mkdir -p "$T9_EMPTY_DIR"
cp "$REGISTER" "$T9_EMPTY_DIR/register-codex-agent.sh"
printf "import { writeFileSync } from 'node:fs';\nwriteFileSync(process.argv[process.argv.indexOf('--out') + 1], '');\n" > "$T9_EMPTY_DIR/agent-to-codex.mjs"
CH_T9D="$WORKDIR/codex-home-t9d"
OUT_T9D="$(bash "$T9_EMPTY_DIR/register-codex-agent.sh" "$FIXTURE_AGENT" --codex-home "$CH_T9D" 2>"$WORKDIR/t9d.err")"
STATUS_T9D=$?
ERR_T9D="$(cat "$WORKDIR/t9d.err")"
if [ "$STATUS_T9D" -ne 0 ] \
  && ! printf '%s%s' "$OUT_T9D" "$ERR_T9D" | grep -qF 'rôle posé' \
  && printf '%s' "$ERR_T9D" | grep -qF 'sans écrire de rôle' \
  && [ ! -e "$CH_T9D/$T9_ROLE_REL" ]; then
  ok "T9d : convertisseur qui crée un fichier vide -> refus (rc=$STATUS_T9D), aucun « rôle posé », aucun .toml vide laissé"
else
  ko "T9d : $(t9_diag "$STATUS_T9D" "$OUT_T9D" "$ERR_T9D") avec un fichier vide (status=$STATUS_T9D, stdout='$OUT_T9D', stderr='$ERR_T9D', .toml présent=$([ -e "$CH_T9D/$T9_ROLE_REL" ] && echo oui || echo non))"
fi

echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ] && exit 0 || exit 1
