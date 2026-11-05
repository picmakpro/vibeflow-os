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
  mkdir -p "$FAKE/$v/_internal" "$FAKE/$v/conductor/scripts"
  printf '#!/usr/bin/env bash\necho "ENGINE cache=$VIBEFLOW_CACHE"\n' > "$FAKE/$v/_internal/vibeflow-update.sh"
  # Stub de check-plugin-update.sh : écrit un cache dont "installed" porte le nom du dossier de
  # version d'origine — sonde d'origine pour le cas A ci-dessous — et éteint tout risque réseau
  # (sans lui, le cas « sélectionne 2.18.0 » ferait un vrai git ls-remote une fois le bloc de
  # production posé, faute de vérificateur dans $FAKE/2.18.0/).
  printf '#!/usr/bin/env bash\nset -uo pipefail\nCF="${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/update-check.json"\nmkdir -p "$(dirname "$CF")"\nprintf '"'"'{"update_available":false,"installed":"%s","latest":"%s","checked_at":"x"}'"'"' "%s" "%s" > "$CF"\n' "$v" "$v" > "$FAKE/$v/conductor/scripts/check-plugin-update.sh"
  chmod +x "$FAKE/$v/conductor/scripts/check-plugin-update.sh"
done
out="$(VF_CACHE_BASE="$FAKE" bash "$DIR/vf-update-run.sh" 2>&1)"
ok "sélectionne 2.18.0 (max semver, pas 2.9.0)" "$(echo "$out" | grep -q 'cache le plus récent : 2.18.0' && echo true || echo false)"

echo "== vf-update-run.sh (invalidation + régénération du cache du bandeau) =="
# Isolation HOME (même motif que run_banner ligne 18) : le repli du bloc de production et le
# chemin par défaut du cache dérivent tous deux de $HOME. XDG_CACHE_HOME est déjà exporté
# (ligne 10) vers $TMP/cache pour toute la suite — c'est donc LUI, pas HOME, qui fixe le chemin
# du cache ici (même précédence que dans le script de production).
RB_HOME="$TMP/rb-home"; mkdir -p "$RB_HOME"
RB_CACHE="$XDG_CACHE_HOME/vibeflow/update-check.json"

# Cas A — régénération depuis la copie la plus fraîche ($NEW/conductor/scripts/…).
echo '{"update_available":true,"installed":"0.0.0","latest":"9.9.9","checked_at":"x"}' > "$RB_CACHE"
HOME="$RB_HOME" VF_CACHE_BASE="$FAKE" bash "$DIR/vf-update-run.sh" >/dev/null 2>&1
ok "cas A : cache régénéré, update_available=false" "$([ -f "$RB_CACHE" ] && grep -q '"update_available":false' "$RB_CACHE" && echo true || echo false)"
ok "cas A : version relue = celle de \$NEW (2.18.0)" "$([ -f "$RB_CACHE" ] && grep -q '"installed":"2.18.0"' "$RB_CACHE" && echo true || echo false)"

# Cas B/C — la régénération échoue (vérificateur sort 1 sans rien écrire) : le cache doit rester
# ABSENT (pas régénéré seul — c'est ce qui distingue « supprimer puis régénérer » de « régénérer
# seul »), et le script doit quand même sortir 0 (best-effort, cas C).
FAKE_FAIL="$TMP/cache-base-fail"
mkdir -p "$FAKE_FAIL/1.0.0/_internal" "$FAKE_FAIL/1.0.0/conductor/scripts"
printf '#!/usr/bin/env bash\necho "ENGINE cache=$VIBEFLOW_CACHE"\n' > "$FAKE_FAIL/1.0.0/_internal/vibeflow-update.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$FAKE_FAIL/1.0.0/conductor/scripts/check-plugin-update.sh"
chmod +x "$FAKE_FAIL/1.0.0/conductor/scripts/check-plugin-update.sh"
echo '{"update_available":true,"installed":"0.0.0","latest":"9.9.9","checked_at":"x"}' > "$RB_CACHE"
HOME="$RB_HOME" VF_CACHE_BASE="$FAKE_FAIL" bash "$DIR/vf-update-run.sh" >/dev/null 2>&1
rc=$?
ok "cas B : régénération en échec → cache ABSENT (pas de faux positif)" "$([ ! -f "$RB_CACHE" ] && echo true || echo false)"
ok "cas C : sortie 0 même si le vérificateur échoue (best-effort)" "$([ "$rc" -eq 0 ] && echo true || echo false)"

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

echo "== vf-update-run.sh (modules nouveaux du catalogue : proposés, jamais posés d'office) =="
NM_BASE="$TMP/nm-base"; NM_HOME="$TMP/nm-home"; NM_LOG="$TMP/nm.log"
mkdir -p "$NM_BASE/3.0.0/_internal" "$NM_BASE/3.0.0/conductor/scripts" "$NM_HOME/.claude/scripts"
printf 'conductor=v1.0.0\n' > "$NM_HOME/.claude/scripts/.vibeflow-installed"
# Stub de l'engine : journalise ses arguments ; NM_FAIL_LIST=1 fait échouer new-modules, NM_FAIL_INSTALL=1 fait échouer install.
cat > "$NM_BASE/3.0.0/_internal/vibeflow-update.sh" <<STUB
#!/usr/bin/env bash
echo "\$*" >> "$NM_LOG"
if [ "\${3:-}" = "new-modules" ]; then [ -z "\${NM_FAIL_LIST:-}" ] || exit 1; echo "cockpit=v1.0.1"; fi
if [ "\${3:-}" = "install" ] && [ -n "\${NM_FAIL_INSTALL:-}" ]; then exit 1; fi
exit 0
STUB
printf '#!/usr/bin/env bash\nexit 1\n' > "$NM_BASE/3.0.0/conductor/scripts/check-plugin-update.sh"
# fermeture des requires : le vrai résolveur, cockpit exige conductor (posé) et helper (non posé)
cp "$DIR/../../_internal/resolve-deps.sh" "$NM_BASE/3.0.0/_internal/resolve-deps.sh"
mkdir -p "$NM_BASE/3.0.0/cockpit" "$NM_BASE/3.0.0/helper" "$NM_BASE/3.0.0/conductor"
printf '{ "name": "cockpit", "requires": ["conductor", "helper"] }\n' > "$NM_BASE/3.0.0/cockpit/module.json"
printf '{ "name": "helper", "requires": [] }\n' > "$NM_BASE/3.0.0/helper/module.json"
printf '{ "name": "conductor", "requires": [] }\n' > "$NM_BASE/3.0.0/conductor/module.json"
: > "$NM_LOG"
out="$(cd "$TMP/work" && HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" 2>&1)"
ok "nouveau : le module absent du registre est listé, avec ses dépendances non posées (format stable)" "$(echo "$out" | grep -qx '\[vf-update-run\] NOUVEAU_MODULE scope=user cockpit=v1.0.1 deps=helper' && echo true || echo false)"
ok "nouveau : rien n'est posé d'office (aucun install)"            "$(grep -q 'install' "$NM_LOG" && echo false || echo true)"
: > "$NM_LOG"
HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" offer user cockpit >/dev/null 2>&1
ok "offer : présentés calculés AVANT la pose, accepté posé avec ses dépendances, seuls les présentés inscrits" "$([ "$(cat "$NM_LOG")" = "$(printf -- '--scope user new-modules\n--scope user install --with-deps cockpit\n--scope user mark-offered cockpit')" ] && echo true || echo false)"
: > "$NM_LOG"
HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" offer user >/dev/null 2>&1
ok "offer sans module (refus) : seule l'inscription des présentés a lieu" "$([ "$(cat "$NM_LOG")" = "$(printf -- '--scope user new-modules\n--scope user mark-offered cockpit')" ] && echo true || echo false)"
: > "$NM_LOG"
HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" offer user '../x' >/dev/null 2>&1
ok "offer : un nom de module douteux n'atteint jamais l'engine"    "$(grep -q 'install' "$NM_LOG" && echo false || echo true)"
HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" offer local >/dev/null 2>&1
ok "offer : scope inconnu refusé (exit 64)"                         "$([ $? -eq 64 ] && echo true || echo false)"
# --- Témoins de correction ciblée (BL35) ---
# deps=? : fermeture incalculable (cockpit exige un module sans manifeste) → jamais « - »
cp "$NM_BASE/3.0.0/cockpit/module.json" "$TMP/cockpit.module.json.bak"
printf '{ "name": "cockpit", "requires": ["conductor", "fantome"] }\n' > "$NM_BASE/3.0.0/cockpit/module.json"
out="$(cd "$TMP/work" && HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" 2>&1)"
ok "nouveau : fermeture de dépendances incalculable → deps=? (jamais deps=-)" "$(echo "$out" | grep -qx '\[vf-update-run\] NOUVEAU_MODULE scope=user cockpit=v1.0.1 deps=?' && echo true || echo false)"
cp "$TMP/cockpit.module.json.bak" "$NM_BASE/3.0.0/cockpit/module.json"
# calcul de new-modules en échec : ligne d'erreur stable, distincte de « rien à proposer », mise à jour non remise en cause
: > "$NM_LOG"
out="$(cd "$TMP/work" && NM_FAIL_LIST=1 HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" 2>&1)"; nrc=$?
ok "nouveau : calcul en échec → NOUVEAUX_MODULES_ERREUR scope=user, aucun NOUVEAU_MODULE, rc=0" "$(echo "$out" | grep -qx '\[vf-update-run\] NOUVEAUX_MODULES_ERREUR scope=user' && ! echo "$out" | grep -q 'NOUVEAU_MODULE ' && [ "$nrc" -eq 0 ] && grep -q 'update --all' "$NM_LOG" && echo true || echo false)"
out="$(cd "$TMP/work" && HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" 2>&1)"
ok "nouveau : calcul réussi → pas de NOUVEAUX_MODULES_ERREUR" "$(echo "$out" | grep -q 'NOUVEAUX_MODULES_ERREUR' && echo false || echo true)"
# offer : new-modules en échec → rien posé, rien inscrit, rc≠0
: > "$NM_LOG"
NM_FAIL_LIST=1 HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" offer user cockpit >/dev/null 2>&1; orc=$?
ok "offer : new-modules en échec → rien posé, rien inscrit, rc≠0" "$([ "$orc" -ne 0 ] && ! grep -q 'install\|mark-offered' "$NM_LOG" && echo true || echo false)"
# offer : un module hors de l'ensemble présenté est refusé avec message, jamais posé
: > "$NM_LOG"
out="$(HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" offer user helper 2>&1)"
ok "offer : module hors des présentés refusé avec message, jamais posé" "$(echo "$out" | grep -q 'non présenté.*helper' && ! grep -q 'install' "$NM_LOG" && echo true || echo false)"
# offer : la pose d'un accepté échoue → rc≠0, message nommant le module ; l'inscription des présentés reste inchangée
: > "$NM_LOG"
out="$(NM_FAIL_INSTALL=1 HOME="$NM_HOME" VF_CACHE_BASE="$NM_BASE" bash "$DIR/vf-update-run.sh" offer user cockpit 2>&1)"; orc=$?
ok "offer : pose en échec → rc≠0 et message nommant cockpit" "$([ "$orc" -ne 0 ] && echo "$out" | grep -q 'pose en échec : cockpit' && echo true || echo false)"
ok "offer : pose en échec → inscription des présentés inchangée (arbitrage en attente)" "$(grep -qx -- '--scope user mark-offered cockpit' "$NM_LOG" && echo true || echo false)"

echo; echo "== Résultat : $PASS OK · $FAIL KO =="
[ "$FAIL" -eq 0 ]
