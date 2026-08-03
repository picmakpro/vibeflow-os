#!/usr/bin/env bash
# test-check-gsd-config.sh — Suite de vérification de check-gsd-config.sh (GSDC-07, plan 23-02).
#
# Un cas par piège. Fixtures isolées via mktemp -d + VF_CONFIG_PATH / VF_GSD_CORE_LIB, jamais sur
# le .planning/config.json réel de ce lab.
#
# --- Pourquoi un MOTEUR FACTICE ----------------------------------------------------------------
# La plupart des cas tournent contre un gsd-core factice (trois modules .cjs minimaux écrits dans la
# fixture) plutôt que contre le moteur installé. Deux raisons, toutes deux dirimantes :
#   1. Déterminisme — le vrai moteur monte de version ; une suite qui asserte « gates est inconnu »
#      contre lui asserte en réalité l'état d'un paquet tiers à un instant donné.
#   2. DISCRIMINANCE — c'est la seule façon de prouver la sonde DANS LES DEUX SENS. Un cas qui
#      constate seulement qu'une clé est signalée ne distingue pas « le script compare vraiment au
#      moteur » de « le script signale tout ce qu'il ne reconnaît pas en dur ». Chaque assertion de
#      signal est donc doublée d'une MUTATION du moteur factice qui doit faire BASCULER le verdict
#      sans qu'on touche au fichier audité — cas 2 (le signal disparaît), 15 (la valeur apparaît),
#      22 (le signal réapparaît). Les cas 10/11 forment la même paire sur la granularité.
#
# Le cas 20 tourne, lui, contre le moteur RÉELLEMENT installé : c'est le compteur d'ATTEINTE, qui
# interdit le « vert à vide ». Il exige les DEUX sens dans un seul fichier — un bloc bidon signalé
# ET les cinq toggles légitimes épargnés : un jeu de clés connues vide échouerait sur le second,
# un jeu universel sur le premier.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-gsd-config.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- Moteur factice -----------------------------------------------------------------------------
# Reproduit fidèlement la topologie du vrai moteur, y compris ses deux asymétries structurantes :
#   - code_review / pattern_mapper / ui_review vivent SEULEMENT dans configKeys ;
#   - node_repair / node_repair_budget vivent SEULEMENT dans VALID_CONFIG_KEYS ;
#   - ui_review n'a AUCUN défaut amont (absent de CONFIG_DEFAULTS) — c'est le cas discriminant ;
#   - _auto_chain_active ne vit QUE dans CONFIG_DEFAULTS ;
#   - parallelization est un conteneur NU (aucun enfant déclaré) donc opaque.
mk_engine() { # <name> -> imprime le chemin
  local d="$TMP/engine-$1"
  mkdir -p "$d"
  cat > "$d/config.cjs" <<'JS'
module.exports = { VALID_CONFIG_KEYS: new Set([
  'mode', 'project_code', 'parallelization',
  'workflow.research', 'workflow.node_repair', 'workflow.node_repair_budget',
  'planning.commit_docs'
]) };
JS
  cat > "$d/capability-registry.cjs" <<'JS'
module.exports = { configKeys: {
  'workflow.code_review': 'code-review',
  'workflow.pattern_mapper': 'pattern-mapper',
  'workflow.ui_review': 'ui'
} };
JS
  cat > "$d/configuration.cjs" <<'JS'
module.exports = {
  CONFIG_DEFAULTS: {
    mode: 'interactive',
    project_code: null,
    parallelization: {},
    planning: { commit_docs: true },
    workflow: {
      research: true, node_repair: true, node_repair_budget: 2,
      code_review: true, pattern_mapper: true, _auto_chain_active: false
    }
  },
  DYNAMIC_KEY_PATTERNS: [{ topLevel: 'agent_skills' }]
};
JS
  printf '%s' "$d"
}

# Écrit un config.json de fixture et imprime son chemin.
mk_config() { # <name> <contenu json>
  local f="$TMP/cfg-$1.json"
  printf '%s\n' "$2" > "$f"
  printf '%s' "$f"
}

# Config parfaitement alignée sur le moteur factice (aucun des deux volets ne doit parler).
ALIGNED='{
  "mode": "interactive",
  "project_code": "TEST",
  "parallelization": { "enabled": true, "max_concurrent_agents": 3 },
  "planning": { "commit_docs": true },
  "workflow": {
    "research": true,
    "_auto_chain_active": false,
    "code_review": true,
    "pattern_mapper": true,
    "node_repair": true,
    "node_repair_budget": 2,
    "ui_review": false
  }
}'

echo "== test-check-gsd-config =="

ENG="$(mk_engine base)"

# === Cas 1 — Bloc de clés inconnues du moteur → signal nommant les blocs, exit 0 =================
CFG="$(mk_config c1 '{ "mode": "interactive", "gates": { "confirm_plan": true }, "safety": { "always_confirm_destructive": true } }')"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" 2>/dev/null)"; rc=$?
has_g=0; case "$out" in *"[gsd-config]"*gates*) has_g=1 ;; esac
has_s=0; case "$out" in *safety*) has_s=1 ;; esac
# Granularité : le BLOC est nommé, pas ses sous-clés.
no_sub=1; case "$out" in *confirm_plan*|*always_confirm_destructive*) no_sub=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_g" -eq 1 ] && [ "$has_s" -eq 1 ] && [ "$no_sub" -eq 1 ]; then
  ok "1 blocs inconnus nommés EN TANT QUE BLOCS (pas leurs sous-clés), exit 0"
else ko "1 blocs inconnus nommés EN TANT QUE BLOCS (pas leurs sous-clés), exit 0" "rc=$rc out=[$out]"; fi

# === Cas 2 — MUTATION du moteur : le même fichier cesse d'être signalé ===========================
# Preuve du sens inverse : le fichier audité ne bouge PAS, seul le moteur apprend les deux blocs.
# Si le signal persistait, c'est que le script porterait « gates/safety » en dur au lieu de comparer.
ENG2="$(mk_engine mute)"
cat > "$ENG2/config.cjs" <<'JS'
module.exports = { VALID_CONFIG_KEYS: new Set([
  'mode', 'project_code', 'parallelization',
  'workflow.research', 'workflow.node_repair', 'workflow.node_repair_budget',
  'planning.commit_docs',
  'gates.confirm_plan', 'safety.always_confirm_destructive'
]) };
JS
out2="$(VF_GSD_CORE_LIB="$ENG2" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" 2>/dev/null)"; rc2=$?
gone=1; case "$out2" in *gates*|*safety*) gone=0 ;; esac
if [ "$gone" -eq 1 ]; then
  ok "2 MUTATION — moteur qui connaît gates/safety : le signal disparaît (comparaison réelle, pas de liste en dur)"
else ko "2 MUTATION — moteur qui connaît gates/safety : le signal disparaît" "rc2=$rc2 out2=[$out2]"; fi

# === Cas 3 — Config entièrement alignée → aucun signal sur stdout, exit 3 ========================
CFG_OK="$(mk_config c3 "$ALIGNED")"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_OK" bash "$SCRIPT" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "3 config alignée → stdout vide, exit 3"; else ko "3 config alignée → stdout vide, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 4 — --path sans valeur → exit 64, stdout vide, stderr non vide ==========================
errfile="$TMP/c4.err"
out="$(bash "$SCRIPT" --path 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 64 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "4 --path sans valeur → exit 64, stdout vide, stderr non vide"; else ko "4 --path sans valeur → exit 64, stdout vide, stderr non vide" "rc=$rc out=[$out] err=[$err]"; fi

# === Cas 5 — Argument inconnu → exit 64, stdout vide =============================================
out="$(bash "$SCRIPT" --nawak 2>/dev/null)"; rc=$?
if [ "$rc" -eq 64 ] && [ -z "$out" ]; then ok "5 argument inconnu → exit 64, stdout vide"; else ko "5 argument inconnu → exit 64, stdout vide" "rc=$rc out=[$out]"; fi

# === Cas 6 — --hook + --quiet ensemble → exit 64 =================================================
bash "$SCRIPT" --hook --quiet >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "6 --hook + --quiet ensemble → exit 64"; else ko "6 --hook + --quiet ensemble → exit 64" "rc=$rc"; fi

# === Cas 7 — Fichier de config inexistant → silence, exit 3 ======================================
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$TMP/nexiste-pas/config.json" bash "$SCRIPT" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "7 config inexistante → silence, exit 3 (jamais bruyant au SessionStart)"; else ko "7 config inexistante → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 8 — Moteur gsd-core introuvable → silence, exit 3 =======================================
out="$(VF_GSD_CORE_LIB="$TMP/pas-de-moteur" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "8 moteur introuvable → silence, exit 3 (ne constate rien, ne prétend rien)"; else ko "8 moteur introuvable → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 9 — JSON illisible → silence, exit 3 ====================================================
CFG_BAD="$(mk_config c9 '{ ceci nest pas du json ')"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_BAD" bash "$SCRIPT" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "9 JSON illisible → silence, exit 3"; else ko "9 JSON illisible → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 10 — Sous-clé inconnue sous un conteneur CONNU → chemin pointé complet ==================
CFG_SUB="$(mk_config c10 '{ "workflow": { "research": true, "cle_bidon": 1 } }')"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_SUB" bash "$SCRIPT" 2>/dev/null)"; rc=$?
has_dotted=0; case "$out" in *"workflow.cle_bidon"*) has_dotted=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_dotted" -eq 1 ]; then ok "10 sous-clé inconnue sous conteneur connu → chemin pointé complet"; else ko "10 sous-clé inconnue sous conteneur connu → chemin pointé complet" "rc=$rc out=[$out]"; fi

# === Cas 11 — Conteneur OPAQUE (aucun enfant déclaré) → ses sous-clés ne sont JAMAIS signalées ===
# Sens inverse du cas 10 : même forme de fichier, conteneur différent. Sans cette borne, le gate
# signalerait parallelization.enabled — une clé que le moteur consomme parfaitement.
CFG_OPQ="$(mk_config c11 '{ "parallelization": { "enabled": true, "cle_bidon": 1 } }')"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_OPQ" bash "$SCRIPT" 2>/dev/null)"; rc=$?
silent=1; case "$out" in *cle_bidon*|*parallelization*) silent=0 ;; esac
if [ "$silent" -eq 1 ]; then ok "11 conteneur opaque → sous-clés jamais signalées (borne de granularité)"; else ko "11 conteneur opaque → sous-clés jamais signalées" "rc=$rc out=[$out]"; fi

# === Cas 12 — Toggles arbitrés absents → signal les nommant tous les cinq, exit 0 ================
CFG_T="$(mk_config c12 '{ "mode": "interactive" }')"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_T" bash "$SCRIPT" 2>/dev/null)"; rc=$?
miss=""
for t in code_review pattern_mapper node_repair node_repair_budget ui_review; do
  case "$out" in *"workflow.$t"*) : ;; *) miss="$miss $t" ;; esac
done
if [ "$rc" -eq 0 ] && [ -z "$miss" ]; then ok "12 les 5 toggles arbitrés non écrits sont tous nommés, exit 0"; else ko "12 les 5 toggles arbitrés non écrits sont tous nommés, exit 0" "rc=$rc manquants=[$miss] out=[$out]"; fi

# === Cas 13 — Défaut amont affiché AVEC sa valeur lue dans le moteur =============================
has_true=0;  case "$out" in *"workflow.code_review"*"true"*) has_true=1 ;; esac
has_budget=0; case "$out" in *"node_repair_budget"*"2"*) has_budget=1 ;; esac
if [ "$has_true" -eq 1 ] && [ "$has_budget" -eq 1 ]; then ok "13 défaut amont rendu avec sa valeur effective lue (true, 2)"; else ko "13 défaut amont rendu avec sa valeur effective lue" "out=[$out]"; fi

# === Cas 14 — CAS DISCRIMINANT : ui_review absent en amont → AUCUNE valeur booléenne =============
# Une valeur qui n'existe nulle part n'est pas `false`, elle est ABSENTE (Finding 2).
ui_line="$(printf '%s\n' "$out" | awk '/ui_review/{print}')"
no_bool=1; case "$ui_line" in *true*|*false*) no_bool=0 ;; esac
saw_line=0; [ -n "$ui_line" ] && saw_line=1
if [ "$saw_line" -eq 1 ] && [ "$no_bool" -eq 1 ]; then ok "14 ui_review : ligne présente et SANS true/false (absence ≠ faux)"; else ko "14 ui_review : ligne présente et SANS true/false" "ui_line=[$ui_line]"; fi

# === Cas 15 — MUTATION : si le moteur DONNAIT un défaut à ui_review, la valeur serait affichée ===
# Preuve du sens inverse du cas 14 : le script ne « tait » pas ui_review en dur, il tait une valeur
# qui n'existe pas. Un moteur qui la fournit doit faire apparaître cette valeur.
ENG3="$(mk_engine uidef)"
cat > "$ENG3/configuration.cjs" <<'JS'
module.exports = {
  CONFIG_DEFAULTS: {
    mode: 'interactive',
    workflow: {
      research: true, node_repair: true, node_repair_budget: 2,
      code_review: true, pattern_mapper: true, ui_review: false
    }
  },
  DYNAMIC_KEY_PATTERNS: [{ topLevel: 'agent_skills' }]
};
JS
out3="$(VF_GSD_CORE_LIB="$ENG3" VF_CONFIG_PATH="$CFG_T" bash "$SCRIPT" 2>/dev/null)"
ui_line3="$(printf '%s\n' "$out3" | awk '/ui_review/{print}')"
now_bool=0; case "$ui_line3" in *false*) now_bool=1 ;; esac
if [ "$now_bool" -eq 1 ]; then ok "15 MUTATION — moteur fournissant un défaut à ui_review : la valeur APPARAÎT (le silence du cas 14 est un fait lu, pas un cas en dur)"; else ko "15 MUTATION — défaut ui_review fourni : la valeur doit apparaître" "ui_line3=[$ui_line3]"; fi

# === Cas 16 — Toggles écrits → le volet des toggles se tait ======================================
CFG_W="$(mk_config c16 "$ALIGNED")"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_W" bash "$SCRIPT" 2>/dev/null)"; rc=$?
quiet=1; case "$out" in *"au défaut amont"*|*ui_review*) quiet=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$quiet" -eq 1 ]; then ok "16 toggles écrits à une valeur → volet muet, exit 3"; else ko "16 toggles écrits à une valeur → volet muet, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 17 — Les DEUX volets parlent → un signal par volet, UN SEUL exit 0 ======================
CFG_2="$(mk_config c17 '{ "gates": { "confirm_plan": true } }')"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_2" bash "$SCRIPT" 2>/dev/null)"; rc=$?
n_sig="$(printf '%s\n' "$out" | awk '/^\[gsd-config\]/{c++} END{print c+0}')"
if [ "$rc" -eq 0 ] && [ "$n_sig" -eq 2 ]; then ok "17 deux volets → 2 en-têtes [gsd-config], un seul exit 0"; else ko "17 deux volets → 2 en-têtes [gsd-config], un seul exit 0" "rc=$rc n_sig=$n_sig out=[$out]"; fi

# === Cas 18 — Robustesse : valeurs hostiles, aucun effet d'exécution =============================
# Interpolation shell, sous-shell, backticks et octet de contrôle dans une CLÉ comme dans une
# VALEUR. C'est la sonde qui prouve l'absence d'eval — pas la relecture du script.
# La séquence d'échappement est FABRIQUÉE par awk : jamais d'octet de contrôle brut dans ce fichier
# de test (il rendrait la fixture JSON invalide et le motif d'assertion silencieusement faux).
CTRL_ESC="$(awk 'BEGIN{printf "%s", "\\u0001"}')"   # les 6 caractères \ u 0 0 0 1
CTRL_RAW="$(awk 'BEGIN{printf "%c", 1}')"           # le vrai octet 0x01
CANARY="$TMP/canary-pwned"
CFG_H="$TMP/cfg-hostile.json"
printf '%s\n' '{' \
  '  "gates": { "a": "$(touch '"$CANARY"')", "b": "`touch '"$CANARY"'`", "c": "; touch '"$CANARY"'" },' \
  "  \"bloc${CTRL_ESC}hostile\": { \"x\": 1 }," \
  '  "safety": { "d": "$(echo INJECTE)" }' \
  '}' > "$CFG_H"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_H" bash "$SCRIPT" 2>/dev/null)"; rc=$?
no_exec=1
[ -e "$CANARY" ] && no_exec=0
case "$out" in *INJECTE*) no_exec=0 ;; esac
# Les deux assertions sont exigées ENSEMBLE : l'octet de contrôle ressort ÉCHAPPÉ (en toutes
# lettres) et JAMAIS en octet brut dans la sortie de session.
escaped=0;  case "$out" in *"$CTRL_ESC"*) escaped=1 ;; esac
raw_ctrl=1; case "$out" in *"$CTRL_RAW"*) raw_ctrl=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$no_exec" -eq 1 ] && [ "$escaped" -eq 1 ] && [ "$raw_ctrl" -eq 1 ]; then
  ok "18 clés/valeurs hostiles → aucun effet d'exécution, octet de contrôle échappé, exit inchangé"
else ko "18 clés/valeurs hostiles → aucun effet d'exécution" "rc=$rc no_exec=$no_exec escaped=$escaped raw_ctrl=$raw_ctrl out=[$out]"; fi

# === Cas 19 — --quiet muselle stderr, --hook préserve le contrat de sortie =======================
errq="$TMP/c19.err"
outq="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" --quiet 2>"$errq")"; rcq=$?
errq_content="$(cat "$errq")"
outh="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" --hook 2>/dev/null)"; rch=$?
if [ "$rcq" -eq 0 ] && [ -z "$errq_content" ] && [ -n "$outq" ] && [ "$rch" -eq 0 ] && [ -n "$outh" ]; then
  ok "19 --quiet muselle stderr sans toucher au signal ; --hook préserve le contrat (exit 0)"
else ko "19 --quiet muselle stderr ; --hook préserve le contrat" "rcq=$rcq errq=[$errq_content] rch=$rch"; fi

# === Cas 20 — ATTEINTE : contre le MOTEUR RÉELLEMENT INSTALLÉ, dans les deux sens ================
# Interdit le « vert à vide » : un jeu de clés connues vide signalerait TOUT (donc code_review
# serait signalé), un jeu universel ne signalerait RIEN (donc le bloc bidon passerait). Exiger les
# deux à la fois prouve que le vrai moteur a bien été lu et discrimine.
REAL_LIB=""
for c in "$HOME/.claude/gsd-core/bin/lib"; do [ -f "$c/config.cjs" ] && REAL_LIB="$c"; done
if [ -z "$REAL_LIB" ]; then
  ko "20 ATTEINTE sur le moteur réel" "moteur installé introuvable — la suite ne peut pas prouver l'intégration"
else
  CFG_R="$(mk_config c20 '{ "workflow": { "code_review": true, "pattern_mapper": true, "node_repair": true, "node_repair_budget": 2, "ui_review": false }, "bloc_totalement_bidon": { "x": 1 } }')"
  out="$(VF_GSD_CORE_LIB="$REAL_LIB" VF_CONFIG_PATH="$CFG_R" bash "$SCRIPT" 2>/dev/null)"; rc=$?
  flags_bogus=0; case "$out" in *bloc_totalement_bidon*) flags_bogus=1 ;; esac
  spares_real=1; case "$out" in *code_review*|*pattern_mapper*|*ui_review*) spares_real=0 ;; esac
  if [ "$rc" -eq 0 ] && [ "$flags_bogus" -eq 1 ] && [ "$spares_real" -eq 1 ]; then
    ok "20 ATTEINTE moteur réel — le bloc bidon est signalé ET les 5 toggles légitimes sont épargnés"
  else ko "20 ATTEINTE moteur réel — bloc bidon signalé ET toggles légitimes épargnés" "rc=$rc flags_bogus=$flags_bogus spares_real=$spares_real out=[$out]"; fi
fi

# === Cas 21 — Les TROIS sources sont réellement unies (chacune seule ferait un faux positif) =====
# Un toggle par source, dans un seul fichier aligné : si une seule source manquait à l'union, la
# clé qui n'existe QUE dans cette source serait signalée à tort.
CFG_U="$(mk_config c21 '{ "workflow": { "node_repair": true, "code_review": true, "_auto_chain_active": false, "pattern_mapper": true, "node_repair_budget": 2, "ui_review": false } }')"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_U" bash "$SCRIPT" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then
  ok "21 union des 3 sources — node_repair (source 1), code_review (source 2), _auto_chain_active (source 3) : aucun faux positif"
else ko "21 union des 3 sources — aucun faux positif" "rc=$rc out=[$out]"; fi

# === Cas 22 — MUTATION de l'union : retirer la source 3 fait réapparaître _auto_chain_active =====
# Prouve que le cas 21 mesure bien l'union et non une tolérance générale aux clés en workflow.*
ENG4="$(mk_engine nodefaults)"
cat > "$ENG4/configuration.cjs" <<'JS'
module.exports = { CONFIG_DEFAULTS: {}, DYNAMIC_KEY_PATTERNS: [{ topLevel: 'agent_skills' }] };
JS
out4="$(VF_GSD_CORE_LIB="$ENG4" VF_CONFIG_PATH="$CFG_U" bash "$SCRIPT" 2>/dev/null)"
reappears=0; case "$out4" in *"workflow._auto_chain_active"*) reappears=1 ;; esac
if [ "$reappears" -eq 1 ]; then
  ok "22 MUTATION — source 3 retirée : _auto_chain_active redevient inconnue (le cas 21 mesure bien l'union)"
else ko "22 MUTATION — source 3 retirée : _auto_chain_active doit redevenir inconnue" "out4=[$out4]"; fi

# === Cas 23 — --help → exit 0, sortie non vide ===================================================
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "23 --help → exit 0, sortie non vide"; else ko "23 --help → exit 0, sortie non vide" "rc=$rc"; fi

# === Cas 24 — bash -n passe et le script est exécutable ==========================================
syn=0; bash -n "$SCRIPT" 2>/dev/null && syn=1
exe=0; [ -x "$SCRIPT" ] && exe=1
if [ "$syn" -eq 1 ] && [ "$exe" -eq 1 ]; then ok "24 bash -n passe et le script est exécutable"; else ko "24 bash -n passe et le script est exécutable" "syn=$syn exe=$exe"; fi

# === Cas 25 — Lecture seule : le fichier audité n'est jamais modifié =============================
CFG_RO="$(mk_config c25 '{ "gates": { "confirm_plan": true } }')"
before="$(cat "$CFG_RO")"
VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_RO" bash "$SCRIPT" >/dev/null 2>&1
after="$(cat "$CFG_RO")"
if [ "$before" = "$after" ]; then ok "25 lecture seule — le config.json audité est inchangé après exécution"; else ko "25 lecture seule — le config.json audité est inchangé" "avant=[$before] après=[$after]"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
