#!/usr/bin/env bash
# test-vf-update.sh — Tests des scripts de mise à jour du plugin (bandeau + sélection de cache).
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"   # → conductor/scripts
PASS=0; FAIL=0
ok(){ if [ "$2" = "true" ]; then echo "  ✓ $1"; PASS=$((PASS+1)); else echo "  ✗ $1"; FAIL=$((FAIL+1)); fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "== update-banner.sh =="
export XDG_CACHE_HOME="$TMP/cache"
mkdir -p "$XDG_CACHE_HOME/vibeflow"
# ISOLATION (P1-e) : update-banner → check-legacy scanne $HOME/.claude (scope user) ET ./.claude
# (scope projet, cwd). Sans sandbox, le verdict dépendait du poste : un vrai ~/.claude avec des
# modules en legacy/drift ajoutait « nouvelle méthode disponible » au bandeau → « silencieux si
# à jour » rouge ou vert selon la machine. HOME stub + cwd neutre = déterministe partout.
FAKE_HOME="$TMP/home"; WORKDIR="$TMP/work"
mkdir -p "$FAKE_HOME" "$WORKDIR"
run_banner() { (cd "$WORKDIR" && HOME="$FAKE_HOME" bash "$DIR/update-banner.sh" 2>/dev/null); }
echo '{"update_available":true,"installed":"2.4.1","latest":"2.18.0","checked_at":"x"}' > "$XDG_CACHE_HOME/vibeflow/update-check.json"
out="$(run_banner)"
ok "émet un systemMessage si update dispo"  "$(echo "$out" | grep -q 'systemMessage' && echo true || echo false)"
ok "cite installé → latest (2.4.1 → 2.18.0)" "$(echo "$out" | grep -q '2.4.1' && echo "$out" | grep -q '2.18.0' && echo true || echo false)"

echo '{"update_available":false,"installed":"2.18.0","latest":"2.18.0","checked_at":"x"}' > "$XDG_CACHE_HOME/vibeflow/update-check.json"
out="$(run_banner)"
ok "silencieux si à jour"                    "$(echo "$out" | grep -q 'systemMessage' && echo false || echo true)"

echo "== vf-update-run.sh (sélection du cache semver le plus récent) =="
FAKE="$TMP/cache-base"
for v in 2.4.1 2.18.0 2.9.0; do
  mkdir -p "$FAKE/$v/_internal"
  printf '#!/usr/bin/env bash\necho "ENGINE cache=$VIBEFLOW_CACHE"\n' > "$FAKE/$v/_internal/vibeflow-update.sh"
done
out="$(VF_CACHE_BASE="$FAKE" bash "$DIR/vf-update-run.sh" 2>&1)"
ok "sélectionne 2.18.0 (max semver, pas 2.9.0)" "$(echo "$out" | grep -q 'cache le plus récent : 2.18.0' && echo true || echo false)"

echo "== vibeflow-update.sh (baseline mandatory + resync gouvernance) =="
ENGINE="$DIR/../../_internal/vibeflow-update.sh"
EC="$TMP/ecache"; EL="$TMP/elab"
mkdir -p "$EC/_internal" "$EL/.claude/scripts"
cp "$DIR/../../_internal/merge-hooks.sh" "$DIR/../../_internal/resolve-deps.sh" "$EC/_internal/" 2>/dev/null
# Module MANDATORY "cond" (requires "dep") : script + hook SessionStart — ABSENT du lab.
mkdir -p "$EC/cond/scripts" "$EC/cond/hooks" "$EC/dep"
echo v1.0.0 > "$EC/cond/VERSION"; echo v1.0.0 > "$EC/dep/VERSION"
printf '{"name":"cond","version":"v1.0.0","mandatory":true,"requires":["dep"]}\n' > "$EC/cond/module.json"
printf '{"name":"dep","version":"v1.0.0"}\n' > "$EC/dep/module.json"
printf '#!/usr/bin/env bash\necho x\n' > "$EC/cond/scripts/cond-banner.sh"
printf '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"bash {{VF_SCRIPTS}}/cond-banner.sh || true"}]}]}}\n' > "$EC/cond/hooks/hooks.json"
# Module "other" DÉJÀ installé, version inchangée, avec hook — doit être re-mergé (resync).
mkdir -p "$EC/other/scripts" "$EC/other/hooks"
echo v1.0.0 > "$EC/other/VERSION"
printf '{"name":"other","version":"v1.0.0"}\n' > "$EC/other/module.json"
printf '#!/usr/bin/env bash\necho y\n' > "$EC/other/scripts/other-hook.sh"
printf '{"hooks":{"PostToolUse":[{"matcher":"Write","hooks":[{"type":"command","command":"bash {{VF_SCRIPTS}}/other-hook.sh || true"}]}]}}\n' > "$EC/other/hooks/hooks.json"
printf 'other=v1.0.0\n' > "$EL/.claude/scripts/.vibeflow-installed"
printf '{}\n' > "$EL/.claude/settings.json"
HOME="$EL" VIBEFLOW_CACHE="$EC" bash "$ENGINE" --scope user update --all >/dev/null 2>&1
REG="$EL/.claude/scripts/.vibeflow-installed"; SET="$EL/.claude/settings.json"
ok "baseline : module mandatory absent installé"      "$(grep -q '^cond=' "$REG" && echo true || echo false)"
ok "baseline : dépendance transitive rattrapée"        "$(grep -q '^dep=' "$REG" && echo true || echo false)"
ok "baseline : hook du module mandatory mergé"         "$(grep -q 'cond-banner.sh' "$SET" && echo true || echo false)"
ok "resync : hook d'un module à jour re-mergé"         "$(grep -q 'other-hook.sh' "$SET" && echo true || echo false)"
ok "placeholder {{VF_SCRIPTS}} résolu dans settings"   "$(grep -q '{{VF_SCRIPTS}}' "$SET" && echo false || echo true)"

echo; echo "== Résultat : $PASS OK · $FAIL KO =="
[ "$FAIL" -eq 0 ]
