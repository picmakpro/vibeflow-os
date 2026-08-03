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
# rc2 = 0 et non 3 : le volet « clés » se tait, mais cette fixture n'écrit aucun toggle, donc le
# volet « toggles » parle encore. Asserter le rc interdit qu'un script sortant en 1 (ou en 2) sur
# cette fixture reste vert — c'est l'absence de cette assertion qui a laissé passer l'exit 1 de HOME.
if [ "$rc2" -eq 0 ] && [ "$gone" -eq 1 ]; then
  ok "2 MUTATION — moteur qui connaît gates/safety : le signal disparaît (comparaison réelle, pas de liste en dur), exit 0"
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
if [ "$rc" -eq 0 ] && [ "$silent" -eq 1 ]; then ok "11 conteneur opaque → sous-clés jamais signalées (borne de granularité), exit 0"; else ko "11 conteneur opaque → sous-clés jamais signalées" "rc=$rc out=[$out]"; fi

# === Cas 12 — Toggles arbitrés absents → signal les nommant tous les cinq, exit 0 ================
CFG_T="$(mk_config c12 '{ "mode": "interactive" }')"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_T" bash "$SCRIPT" 2>/dev/null)"; rc=$?; rc12=$rc
miss=""
for t in code_review pattern_mapper node_repair node_repair_budget ui_review; do
  case "$out" in *"workflow.$t"*) : ;; *) miss="$miss $t" ;; esac
done
if [ "$rc" -eq 0 ] && [ -z "$miss" ]; then ok "12 les 5 toggles arbitrés non écrits sont tous nommés, exit 0"; else ko "12 les 5 toggles arbitrés non écrits sont tous nommés, exit 0" "rc=$rc manquants=[$miss] out=[$out]"; fi

# === Cas 13 — Défaut amont affiché AVEC sa valeur, ATTACHÉE À SA PROPRE LIGNE ====================
# Ce cas mesure une RELATION (clé ↔ sa valeur), pas une co-présence. La forme précédente
# (case "$out" in *"workflow.code_review"*"true"*) cherchait `true` N'IMPORTE OÙ APRÈS la clé dans
# tout le blob : elle était fournie par la ligne SUIVANTE (pattern_mapper), donc TAUTOLOGIQUE — elle
# survivait à une valeur falsifiée comme à une inversion de l'ordre des toggles. On extrait donc la
# ligne du toggle (comme le fait le cas 14) puis on y cherche sa valeur PARENTHÉSÉE.
cr_line="$(printf '%s\n' "$out" | awk '/workflow\.code_review /{print}')"
nb_line="$(printf '%s\n' "$out" | awk '/workflow\.node_repair_budget /{print}')"
has_true=0;   case "$cr_line" in *"(true)"*) has_true=1 ;; esac
has_budget=0; case "$nb_line" in *"(2)"*)    has_budget=1 ;; esac
if [ "$rc12" -eq 0 ] && [ -n "$cr_line" ] && [ -n "$nb_line" ] && [ "$has_true" -eq 1 ] && [ "$has_budget" -eq 1 ]; then
  ok "13 défaut amont rendu avec sa valeur effective lue (true, 2), chacune SUR SA PROPRE LIGNE, exit 0"
else ko "13 défaut amont : chaque valeur doit être attachée à la ligne de SA clé (relation, pas co-présence)" "rc12=$rc12 cr_line=[$cr_line] nb_line=[$nb_line] out=[$out]"; fi

# === Cas 14 — CAS DISCRIMINANT : ui_review absent en amont → AUCUNE valeur booléenne =============
# Une valeur qui n'existe nulle part n'est pas `false`, elle est ABSENTE (Finding 2).
ui_line="$(printf '%s\n' "$out" | awk '/ui_review/{print}')"
no_bool=1; case "$ui_line" in *true*|*false*) no_bool=0 ;; esac
saw_line=0; [ -n "$ui_line" ] && saw_line=1
# Ne pas inventer de VALEUR, et ne pas inventer de CAUSE non plus : le script n'observe que
# « absent des défauts amont ». Le message a affirmé « résolu par la capability elle-même », un
# fait qu'il ne mesure pas — et faux pour node_repair / node_repair_budget, qui ne sont pas des
# capabilities. Garde-fou de régression sur cette formulation précise.
no_cause=1; case "$ui_line" in *capability*) no_cause=0 ;; esac
if [ "$rc12" -eq 0 ] && [ "$saw_line" -eq 1 ] && [ "$no_bool" -eq 1 ] && [ "$no_cause" -eq 1 ]; then ok "14 ui_review : ligne présente, SANS true/false (absence ≠ faux) et SANS cause fabriquée, exit 0"; else ko "14 ui_review : ligne présente, sans true/false et sans cause non observée" "rc12=$rc12 no_cause=$no_cause ui_line=[$ui_line]"; fi

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
out3="$(VF_GSD_CORE_LIB="$ENG3" VF_CONFIG_PATH="$CFG_T" bash "$SCRIPT" 2>/dev/null)"; rc3=$?
ui_line3="$(printf '%s\n' "$out3" | awk '/ui_review/{print}')"
now_bool=0; case "$ui_line3" in *"(false)"*) now_bool=1 ;; esac
if [ "$rc3" -eq 0 ] && [ "$now_bool" -eq 1 ]; then ok "15 MUTATION — moteur fournissant un défaut à ui_review : la valeur APPARAÎT (le silence du cas 14 est un fait lu, pas un cas en dur), exit 0"; else ko "15 MUTATION — défaut ui_review fourni : la valeur doit apparaître" "rc3=$rc3 ui_line3=[$ui_line3]"; fi

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

# === Cas 18 — Robustesse : charge hostile DANS UNE CLÉ, aucun effet d'exécution ==================
# La charge hostile est placée dans des CLÉS, et sous un conteneur CONNU (workflow), pas dans des
# valeurs. C'est la condition pour que le canari soit DISCRIMINANT : les valeurs du fichier audité
# ne franchissent JAMAIS la frontière vers bash (seules les clés sont émises par le programme node ;
# les valeurs affichées viennent de CONFIG_DEFAULTS). Une charge en valeur rendait donc ce canari
# indéclenchable par construction — vert sans rien mesurer. Sous un conteneur INCONNU (gates), les
# sous-clés ne sont pas émises non plus : il faut un conteneur connu ET porteur d'enfants.
#
# Trois assertions, exigées ENSEMBLE :
#   (a) le canari n'existe pas          → aucune interpolation, aucun sous-shell, aucun eval ;
#   (b) les clés hostiles ont bien TRAVERSÉ jusqu'à la ligne de sortie — sans quoi (a) serait vrai
#       parce que rien n'a été mesuré (anti « vert à vide ») ;
#   (c) l'octet de contrôle ressort ÉCHAPPÉ, et JAMAIS en octet brut dans la sortie de session.
# La séquence d'échappement est FABRIQUÉE par awk : jamais d'octet de contrôle brut dans ce fichier
# de test (il rendrait la fixture JSON invalide et le motif d'assertion silencieusement faux).
CTRL_ESC="$(awk 'BEGIN{printf "%s", "\\u0001"}')"   # les 6 caractères \ u 0 0 0 1
CTRL_RAW="$(awk 'BEGIN{printf "%c", 1}')"           # le vrai octet 0x01
CANARY="$TMP/canary-pwned"
CFG_H="$TMP/cfg-hostile.json"
printf '%s\n' '{' \
  '  "workflow": { "$(touch '"$CANARY"')": 1, "`touch '"$CANARY"'`": 2, "; touch '"$CANARY"'": 3 },' \
  "  \"bloc${CTRL_ESC}hostile\": { \"x\": 1 }," \
  '  "safety": { "d": "$(echo INJECTE)" }' \
  '}' > "$CFG_H"
out="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_H" bash "$SCRIPT" 2>/dev/null)"; rc=$?
no_exec=1
[ -e "$CANARY" ] && no_exec=0
case "$out" in *INJECTE*) no_exec=0 ;; esac
# (b) — la charge est cherchée SUR la ligne des sous-clés : c'est une relation, pas une co-présence.
sub_line="$(printf '%s\n' "$out" | awk '/sous-clés inconnues/{print}')"
crossed=0; case "$sub_line" in *"touch $CANARY"*) crossed=1 ;; esac
escaped=0;  case "$out" in *"$CTRL_ESC"*) escaped=1 ;; esac
raw_ctrl=1; case "$out" in *"$CTRL_RAW"*) raw_ctrl=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$no_exec" -eq 1 ] && [ "$crossed" -eq 1 ] && [ "$escaped" -eq 1 ] && [ "$raw_ctrl" -eq 1 ]; then
  ok "18 clés hostiles → elles TRAVERSENT jusqu'à la sortie, sans aucun effet d'exécution ; octet de contrôle échappé, exit inchangé"
else ko "18 clés hostiles → traversée réelle ET aucun effet d'exécution" "rc=$rc no_exec=$no_exec crossed=$crossed escaped=$escaped raw_ctrl=$raw_ctrl sub_line=[$sub_line] out=[$out]"; fi

# === Cas 19 — --quiet muselle stderr, --hook n'altère AUCUN rendu ================================
# L'en-tête du script affirme que --hook « n'altère aucun rendu » (un seul gabarit de signal).
# Constater seulement que la sortie est NON VIDE ne mesure pas cette propriété : elle est
# tautologique. On compare donc les rendus caractère par caractère, contre une exécution témoin
# sans aucun drapeau. Idem pour --quiet, qui ne doit toucher QUE stderr.
errq="$TMP/c19.err"
out_plain="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" 2>/dev/null)"; rcp19=$?
outq="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" --quiet 2>"$errq")"; rcq=$?
errq_content="$(cat "$errq")"
outh="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" --hook 2>/dev/null)"; rch=$?
same_hook=0;  [ "$outh" = "$out_plain" ] && same_hook=1
same_quiet=0; [ "$outq" = "$out_plain" ] && same_quiet=1
if [ "$rcp19" -eq 0 ] && [ "$rcq" -eq 0 ] && [ "$rch" -eq 0 ] && [ -n "$out_plain" ] \
   && [ -z "$errq_content" ] && [ "$same_hook" -eq 1 ] && [ "$same_quiet" -eq 1 ]; then
  ok "19 --quiet muselle stderr et --hook n'altère AUCUN rendu — stdout IDENTIQUE au témoin sans drapeau, exit 0 dans les trois cas"
else ko "19 --quiet muselle stderr ; --hook n'altère aucun rendu (stdout identique au témoin)" "rcp19=$rcp19 rcq=$rcq rch=$rch same_hook=$same_hook same_quiet=$same_quiet errq=[$errq_content]"; fi

# === Cas 20 — ATTEINTE : contre le MOTEUR RÉELLEMENT INSTALLÉ, dans les deux sens ================
# Interdit le « vert à vide » : un jeu de clés connues vide signalerait TOUT (donc code_review
# serait signalé), un jeu universel ne signalerait RIEN (donc le bloc bidon passerait). Exiger les
# deux à la fois prouve que le vrai moteur a bien été lu et discrimine.
# Le script sous test résout son moteur sur une cascade à TROIS branches ; n'en essayer qu'une
# (`$HOME`) déclarait « moteur introuvable » un poste qui a son gsd-core en node_modules. Les trois
# branches sont donc essayées, dans le MÊME ORDRE que la cascade du script (premier trouvé gagne).
# `${HOME:-}` et non `$HOME` : cette suite tourne sous set -u.
REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
REAL_LIB=""
for c in "$REPO_ROOT/.claude/gsd-core/bin/lib" \
         "$REPO_ROOT/node_modules/@opengsd/gsd-core/bin/lib" \
         "${HOME:-}/.claude/gsd-core/bin/lib"
do
  [ -z "$REAL_LIB" ] && [ -f "$c/config.cjs" ] && REAL_LIB="$c"
done
# Moteur absent = la suite NE PEUT PAS prouver l'intégration. Le verdict reste `ko` : dégrader en
# `ok` (ou en `skip`) rouvrirait exactement le « vert à vide » que les cas 20 et 26 existent pour
# fermer. C'est une lacune d'INFRASTRUCTURE (installer @opengsd/gsd-core dans le job), pas un
# assouplissement à consentir ici.
if [ -z "$REAL_LIB" ]; then
  ko "20 ATTEINTE sur le moteur réel" "moteur gsd-core introuvable sur les 3 branches (repo/.claude, repo/node_modules/@opengsd, \$HOME/.claude) — la suite ne peut pas prouver l'intégration ; installer le moteur dans l'environnement d'exécution"
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
out4="$(VF_GSD_CORE_LIB="$ENG4" VF_CONFIG_PATH="$CFG_U" bash "$SCRIPT" 2>/dev/null)"; rc4=$?
reappears=0; case "$out4" in *"workflow._auto_chain_active"*) reappears=1 ;; esac
if [ "$rc4" -eq 0 ] && [ "$reappears" -eq 1 ]; then
  ok "22 MUTATION — source 3 retirée : _auto_chain_active redevient inconnue (le cas 21 mesure bien l'union), exit 0"
else ko "22 MUTATION — source 3 retirée : _auto_chain_active doit redevenir inconnue" "rc4=$rc4 out4=[$out4]"; fi

# === Cas 23 — --help rend le BLOC D'EN-TÊTE, et rien d'autre =====================================
# « sortie non vide » est tautologique : un `grep '^# '` sur tout le fichier la satisfait tout en
# ramassant les commentaires d'IMPLÉMENTATION et en écrasant la mise en page de l'aide. On mesure
# donc les deux bornes : la fin de l'en-tête est présente (« Exit codes: »), et deux marqueurs
# n'existant QUE dans des commentaires d'implémentation sont absents.
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
has_exits=0; case "$out" in *"Exit codes:"*) has_exits=1 ;; esac
no_impl=1
case "$out" in *"Liste arbitrée des toggles"*) no_impl=0 ;; esac
case "$out" in *"Miroir exact du KNOWN_TOP_LEVEL"*) no_impl=0 ;; esac
if [ "$rc" -eq 0 ] && [ -n "$out" ] && [ "$has_exits" -eq 1 ] && [ "$no_impl" -eq 1 ]; then
  ok "23 --help → exit 0, sortie non vide, BORNÉE au bloc d'en-tête (Exit codes: présent, commentaires d'implémentation absents)"
else ko "23 --help → aide bornée au bloc d'en-tête" "rc=$rc has_exits=$has_exits no_impl=$no_impl"; fi

# === Cas 24 — bash -n passe et le script est exécutable ==========================================
syn=0; bash -n "$SCRIPT" 2>/dev/null && syn=1
exe=0; [ -x "$SCRIPT" ] && exe=1
if [ "$syn" -eq 1 ] && [ "$exe" -eq 1 ]; then ok "24 bash -n passe et le script est exécutable"; else ko "24 bash -n passe et le script est exécutable" "syn=$syn exe=$exe"; fi

# === Cas 25 — Lecture seule : le fichier audité n'est jamais modifié =============================
CFG_RO="$(mk_config c25 '{ "gates": { "confirm_plan": true } }')"
before="$(cat "$CFG_RO")"
VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_RO" bash "$SCRIPT" >/dev/null 2>&1; rc25=$?
after="$(cat "$CFG_RO")"
if [ "$rc25" -eq 0 ] && [ "$before" = "$after" ]; then ok "25 lecture seule — le config.json audité est inchangé après exécution, exit 0"; else ko "25 lecture seule — le config.json audité est inchangé" "rc25=$rc25 avant=[$before] après=[$after]"; fi

# === Cas 26 — Le mirroir engineExtra est exercé contre le MOTEUR RÉEL ============================
# engineExtra est la seule liste de clés écrite à la main du script : le moteur ajoute ces littéraux
# à son KNOWN_TOP_LEVEL sans les exporter, donc ils ne peuvent pas être lus dynamiquement. Sans ce
# cas, une dérive du moteur (littéral ajouté ou retiré) passerait en silence. « depth » et
# « branching_strategy » sont choisis parce qu'ils n'existent dans AUCUNE des trois sources
# dynamiques : seul le mirroir peut les épargner. Le cas est écrit dans les DEUX SENS — les clés du
# mirroir épargnées ET une clé voisine, non mirroirée, toujours signalée : sans cette seconde
# moitié, un KNOWN_TOP devenu universel passerait au vert.
#
# Ces deux moitiés ne voient toutefois que les RETRAITS : elles échantillonnent DEUX littéraux et
# ne comparent jamais le mirroir à la liste réelle. Un littéral AJOUTÉ par une version future du
# moteur — la dérive la plus probable, celle qui produit des faux positifs — les laissait vertes.
# Troisième moitié, donc : ÉGALITÉ D'ENSEMBLE entre engineExtra et les littéraux réellement écrits
# dans le bloc KNOWN_TOP_LEVEL de config-loader.cjs, extraits par lecture de TEXTE (aucun module ne
# les exporte). L'égalité est vérifiée dans les deux directions par `comm`, jamais par `diff` ni par
# une comparaison de longueurs. Les lignes de spread (`...VALID_CONFIG_KEYS`, `...DYNAMIC_KEY…`)
# sont écartées : elles portent des quotes ('.') qui ne sont pas des littéraux de clé.
if [ -z "$REAL_LIB" ]; then
  ko "26 mirroir engineExtra contre le moteur réel" "moteur gsd-core introuvable sur les 3 branches de la cascade — installer le moteur dans l'environnement d'exécution (ne PAS dégrader ce cas en vert)"
else
  CFG_X="$(mk_config c26 '{ "depth": 3, "branching_strategy": "phase", "cle_hors_mirroir": 1 }')"
  out="$(VF_GSD_CORE_LIB="$REAL_LIB" VF_CONFIG_PATH="$CFG_X" bash "$SCRIPT" 2>/dev/null)"; rc=$?
  spares_mirror=1; case "$out" in *depth*|*branching_strategy*) spares_mirror=0 ;; esac
  flags_other=0;  case "$out" in *cle_hors_mirroir*) flags_other=1 ;; esac

  # Deux précautions d'extraction, appliquées SYMÉTRIQUEMENT aux deux côtés :
  #   - l'ancre de fin de bloc est ancrée en DÉBUT DE LIGNE (`^[[:space:]]*\])`). Un simple `\])`
  #     frappait dès la ligne de spread `...[...VALID_CONFIG_KEYS].map((k) => k.split('.')[0]),`,
  #     fermant le bloc immédiatement : l'extraction moteur rendait 0 jeton.
  #   - seuls les jetons ayant la forme d'un NOM DE CLÉ sont retenus, ce qui neutralise les quotes
  #     de code (le '.' du split ci-dessus) si une version future reformatait le bloc.
  # \047 = l'apostrophe, écrite en octal : le programme awk est lui-même en quotes simples.
  MIR_S="$TMP/mirror-script.txt"; MIR_E="$TMP/mirror-engine.txt"
  awk '
    /const engineExtra = \[/     { inb = 1 }
    inb && /^[[:space:]]*\.\.\./ { next }
    inb { n = split($0, p, "\047"); for (i = 2; i <= n; i += 2) if (p[i] ~ /^[A-Za-z_][A-Za-z0-9_.-]*$/) print p[i] }
    inb && /\];/ { inb = 0 }
  ' "$SCRIPT" | sort -u > "$MIR_S"
  awk '
    /const KNOWN_TOP_LEVEL = new Set\(\[/ { inb = 1; next }
    inb && /^[[:space:]]*\]\)/            { inb = 0; next }
    inb && /^[[:space:]]*\.\.\./          { next }
    inb { n = split($0, p, "\047"); for (i = 2; i <= n; i += 2) if (p[i] ~ /^[A-Za-z_][A-Za-z0-9_.-]*$/) print p[i] }
  ' "$REAL_LIB/config-loader.cjs" | sort -u > "$MIR_E"
  n_mir_s="$(awk 'END{print NR+0}' "$MIR_S")"
  n_mir_e="$(awk 'END{print NR+0}' "$MIR_E")"
  only_script="$(comm -23 "$MIR_S" "$MIR_E" | tr '\n' ' ')"
  only_engine="$(comm -13 "$MIR_S" "$MIR_E" | tr '\n' ' ')"
  # Anti « vert à vide » : deux extractions vides seraient identiques et l'égalité passerait.
  extracted=0; [ "$n_mir_s" -gt 0 ] && [ "$n_mir_e" -gt 0 ] && extracted=1
  set_equal=0; [ -z "$only_script" ] && [ -z "$only_engine" ] && set_equal=1

  if [ "$rc" -eq 0 ] && [ "$spares_mirror" -eq 1 ] && [ "$flags_other" -eq 1 ] \
     && [ "$extracted" -eq 1 ] && [ "$set_equal" -eq 1 ]; then
    ok "26 mirroir engineExtra — depth/branching_strategy épargnés, une clé hors mirroir signalée, ET ÉGALITÉ D'ENSEMBLE avec les $n_mir_e littéraux réels du moteur (dérive par AJOUT comme par retrait), exit 0"
  else ko "26 mirroir engineExtra — égalité d'ensemble avec les littéraux réels du moteur" "rc=$rc spares_mirror=$spares_mirror flags_other=$flags_other extraits=(script=$n_mir_s moteur=$n_mir_e) script_seul=[$only_script] moteur_seul=[$only_engine] out=[$out]"; fi
fi

# === Cas 27 — LE CHEMIN DE PRODUCTION : --path <dir> nominal, sans aucune surcharge VF_ ==========
# Tous les cas ci-dessus passent par VF_CONFIG_PATH + VF_GSD_CORE_LIB, c'est-à-dire par les deux
# surcharges qui COURT-CIRCUITENT précisément ce que le hook exerce au SessionStart : la dérivation
# <path>/.planning/config.json et la CASCADE de résolution du moteur. Ce chemin n'était couvert par
# aucun cas. `env -u` retire les deux surcharges même si l'environnement appelant les exportait —
# sans quoi ce cas pourrait mesurer autre chose que ce qu'il annonce.
#
# Les deux branches sont discriminées dans UN SEUL fichier :
#   - `sonde_chemin_path` signalée         → le fichier lu est bien <path>/.planning/config.json ;
#   - `cle_connue_du_moteur_local` ÉPARGNÉE → le moteur lu est bien celui du dépôt pointé
#     (<path>/.claude/gsd-core/bin/lib) et non le moteur du poste, qui l'ignore.
LABP="$TMP/lab-path"
mkdir -p "$LABP/.planning" "$LABP/.claude/gsd-core/bin/lib"
cp "$ENG/capability-registry.cjs" "$ENG/configuration.cjs" "$LABP/.claude/gsd-core/bin/lib/"
cat > "$LABP/.claude/gsd-core/bin/lib/config.cjs" <<'JS'
module.exports = { VALID_CONFIG_KEYS: new Set([
  'mode', 'project_code', 'parallelization',
  'workflow.research', 'workflow.node_repair', 'workflow.node_repair_budget',
  'planning.commit_docs',
  'cle_connue_du_moteur_local'
]) };
JS
printf '%s\n' '{ "cle_connue_du_moteur_local": 1, "sonde_chemin_path": { "x": 1 } }' > "$LABP/.planning/config.json"
outp="$(env -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$LABP" 2>/dev/null)"; rcp=$?
flags_probe=0; case "$outp" in *sonde_chemin_path*) flags_probe=1 ;; esac
spares_local=1; case "$outp" in *cle_connue_du_moteur_local*) spares_local=0 ;; esac
if [ "$rcp" -eq 0 ] && [ "$flags_probe" -eq 1 ] && [ "$spares_local" -eq 1 ]; then
  ok "27 chemin NOMINAL --path <dir> (celui du hook) — config dérivée en <path>/.planning/config.json ET moteur résolu par la cascade dans <path>/.claude/gsd-core, exit 0"
else ko "27 chemin nominal --path <dir> — dérivation de la config ET cascade du moteur" "rcp=$rcp flags_probe=$flags_probe spares_local=$spares_local outp=[$outp]"; fi

# === Cas 28 — --path avec une valeur VIDE → exit 64 =============================================
# `--path ""` franchissait le seul test de comptage et déplaçait silencieusement la cible sur
# /.planning/config.json (exit 3, aucune trace). Sens inverse gardé par le cas 27 : une valeur
# non vide et valide doit, elle, être acceptée.
errE="$TMP/c28.err"
out28="$(bash "$SCRIPT" --path "" 2>"$errE")"; rc28=$?
err28="$(cat "$errE")"
if [ "$rc28" -eq 64 ] && [ -z "$out28" ] && [ -n "$err28" ]; then
  ok "28 --path avec valeur VIDE → exit 64, stdout vide, stderr non vide"
else ko "28 --path avec valeur VIDE → exit 64" "rc28=$rc28 out28=[$out28] err28=[$err28]"; fi

# === Cas 29 — HOME NON DÉFINI : le contrat de sortie tient, et --quiet reste muet ================
# La cascade référençait $HOME nu sous set -u. La liste du `for` étant développée AVANT la boucle,
# la variable était lue même quand une branche antérieure gagnait : le script sortait en 1 — HORS
# CONTRAT — avec un message sur stderr MALGRÉ --quiet.
errH="$TMP/c29.err"
outH="$(env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$LABP" 2>"$errH")"; rcH=$?
errH_content="$(cat "$errH")"
no_unbound=1; case "$errH_content" in *"unbound variable"*) no_unbound=0 ;; esac
errHQ="$TMP/c29q.err"
env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$LABP" --quiet >/dev/null 2>"$errHQ"; rcHQ=$?
errHQ_content="$(cat "$errHQ")"
in_contract=0; case "$rcH" in 0|3|64) in_contract=1 ;; esac
in_contractq=0; case "$rcHQ" in 0|3|64) in_contractq=1 ;; esac
if [ "$in_contract" -eq 1 ] && [ "$rcH" -eq 0 ] && [ -n "$outH" ] && [ "$no_unbound" -eq 1 ] \
   && [ "$in_contractq" -eq 1 ] && [ -z "$errHQ_content" ]; then
  ok "29 HOME non défini → contrat {0,3,64} tenu (exit 0 ici, la cascade aboutit toujours), aucun « unbound variable », et --quiet reste totalement muet"
else ko "29 HOME non défini → contrat de sortie tenu et --quiet muet" "rcH=$rcH rcHQ=$rcHQ no_unbound=$no_unbound errH=[$errH_content] errHQ=[$errHQ_content]"; fi

# === Cas 30 — node absent du PATH → silence, exit 3 =============================================
# Écrit dans les DEUX SENS avec un seul et même fixture : sans node le script se tait (3), avec
# node il parle (0). Sans la seconde moitié, un script cassé qui sort toujours en 3 passerait.
NONODE="$TMP/bin-sans-node"; mkdir -p "$NONODE"
out30="$(env PATH="$NONODE" VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG" "$BASH" "$SCRIPT" 2>/dev/null)"; rc30=$?
out30b="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG" bash "$SCRIPT" 2>/dev/null)"; rc30b=$?
if [ "$rc30" -eq 3 ] && [ -z "$out30" ] && [ "$rc30b" -eq 0 ] && [ -n "$out30b" ]; then
  ok "30 node absent du PATH → silence, exit 3 ; le MÊME fixture avec node → signal, exit 0"
else ko "30 node absent du PATH → silence exit 3, et signal exit 0 avec node" "rc30=$rc30 out30=[$out30] rc30b=$rc30b"; fi

# === Cas 31 — Config PRÉSENTE mais illisible → silence, exit 3 ==================================
# Distinct du cas 7 (fichier absent) et du cas 9 (JSON invalide) : ici `[ -f ]` réussit et c'est la
# LECTURE qui échoue. Si les privilèges du contexte d'exécution rendent le fichier lisible malgré
# tout (exécution en root), la précondition n'est pas réunie : le cas sort en `ko` « non vérifiable »
# plutôt qu'en vert obtenu par une vérification plus faible.
CFG_NR="$(mk_config c31 '{ "mode": "interactive" }')"
chmod 000 "$CFG_NR" 2>/dev/null
if [ -r "$CFG_NR" ]; then
  ko "31 config présente mais illisible → silence, exit 3" "fixture non rendue illisible (privilèges du contexte d'exécution) — cas NON VÉRIFIABLE, pas un succès"
else
  out31="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_NR" bash "$SCRIPT" 2>/dev/null)"; rc31=$?
  chmod 644 "$CFG_NR" 2>/dev/null
  out31b="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_NR" bash "$SCRIPT" 2>/dev/null)"; rc31b=$?
  if [ "$rc31" -eq 3 ] && [ -z "$out31" ] && [ "$rc31b" -eq 0 ] && [ -n "$out31b" ]; then
    ok "31 config présente mais illisible → silence, exit 3 ; le MÊME fichier redevenu lisible → signal, exit 0"
  else ko "31 config présente mais illisible → silence exit 3, et signal exit 0 une fois lisible" "rc31=$rc31 out31=[$out31] rc31b=$rc31b"; fi
fi

# === Cas 32 — Une clé VIDE ne fait pas taire le volet « clés inconnues » =========================
# L'en-tête du script déclare les CLÉS du fichier audité hostiles par hypothèse. Une clé vide
# (deux octets) suffisait à éteindre TOUT le volet : l'accumulateur était une chaîne, et sa vacuité
# servait de compteur — « rien accumulé » et « une seule clé, vide » étaient confondus.
# Les deux sens sont mesurés : la clé vide SEULE doit émettre le volet (c'est le faux vert fermé),
# et le témoin sans clé inconnue doit rester muet sur ce volet (c'est le cas 3/16, rejoué ici sur
# la même mécanique pour que ce cas ne puisse pas devenir un « signale toujours »).
CFG_EK="$(mk_config c32a '{ "": { "a": 1 } }')"
out32="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_EK" bash "$SCRIPT" 2>/dev/null)"; rc32=$?
blk_line="$(printf '%s\n' "$out32" | awk '/clés inconnues du moteur/{print}')"
CFG_EK2="$(mk_config c32b '{ "zzz": 1, "": 2 }')"
out32b="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_EK2" bash "$SCRIPT" 2>/dev/null)"; rc32b=$?
blk_line2="$(printf '%s\n' "$out32b" | awk '/clés inconnues du moteur/{print}')"
both_named=0; case "$blk_line2" in *zzz*) both_named=1 ;; esac
CFG_EKS="$(mk_config c32c '{ "workflow": { "": 1 } }')"
out32c="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_EKS" bash "$SCRIPT" 2>/dev/null)"; rc32c=$?
sub_ek="$(printf '%s\n' "$out32c" | awk '/sous-clés inconnues/{print}')"
# Témoin muet : la config alignée ne doit émettre AUCUNE de ces deux lignes.
out32d="$(VF_GSD_CORE_LIB="$ENG" VF_CONFIG_PATH="$CFG_OK" bash "$SCRIPT" 2>/dev/null)"
mute_ok=1; case "$out32d" in *"clés inconnues"*) mute_ok=0 ;; esac
if [ "$rc32" -eq 0 ] && [ -n "$blk_line" ] && [ "$rc32b" -eq 0 ] && [ -n "$blk_line2" ] && [ "$both_named" -eq 1 ] \
   && [ "$rc32c" -eq 0 ] && [ -n "$sub_ek" ] && [ "$mute_ok" -eq 1 ]; then
  ok "32 clé VIDE → le volet « clés inconnues » parle quand même (seule, et aux côtés d'une autre clé), la sous-clé vide aussi, et le témoin aligné reste muet, exit 0"
else ko "32 clé VIDE → le volet « clés inconnues » ne doit pas être éteint" "rc32=$rc32 blk=[$blk_line] rc32b=$rc32b blk2=[$blk_line2] both_named=$both_named rc32c=$rc32c sub=[$sub_ek] mute_ok=$mute_ok"; fi

# === Cas 33 — BALAYAGE FINAL : aucun chemin ne sort du contrat {0, 3, 64} ========================
# Filet transverse. Les cas ci-dessus assertent chacun UN rc attendu ; celui-ci rejoue TOUTES les
# fixtures (chacune contre un moteur présent PUIS absent) et toutes les formes d'invocation, et
# échoue sur le moindre rc hors contrat — c'est ce filet qui aurait attrapé l'exit 1 de HOME.
# Le nombre d'exécutions est COMPTÉ et un plancher est exigé : un glob qui ne trouverait plus rien
# rendrait ce balayage vert sans avoir rien mesuré.
n_swept=0; hors_contrat=""
sweep() { # <étiquette> <commande…>
  local label="$1"; shift
  "$@" >/dev/null 2>&1; local r=$?
  n_swept=$((n_swept+1))
  # Portabilité (ADR-054, bash 3.2 macOS) : SURTOUT PAS `$label→$r`. bash 3.2 avale l'octet de
  # tête d'un caractère multi-octets dans le NOM de la variable — `$label→` y devient un `label\xE2`
  # non défini, donc une erreur FATALE sous set -u. Le piège est parfait : cette ligne n'est
  # exécutée QUE lorsqu'un rc sort du contrat, c'est-à-dire exactement quand ce cas doit parler ; le
  # balayage mourait au lieu de rougir, et la suite paraissait verte. Accolades + ASCII, donc.
  case "$r" in 0|3|64) : ;; *) hors_contrat="$hors_contrat [${label} rc=${r}]" ;; esac
}
for f in "$TMP"/cfg-*.json "$CFG_H" "$LABP/.planning/config.json"; do
  [ -f "$f" ] || continue
  sweep "moteur:$f"      env VF_GSD_CORE_LIB="$ENG"              VF_CONFIG_PATH="$f" bash "$SCRIPT"
  sweep "sans-moteur:$f" env VF_GSD_CORE_LIB="$TMP/pas-de-moteur" VF_CONFIG_PATH="$f" bash "$SCRIPT"
done
# Formes d'invocation, y compris celles qui passent par la CASCADE (donc par $HOME).
sweep "path-nominal"   env -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$LABP"
sweep "path-nohome"    env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$LABP"
sweep "path-nonlab"    env -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$TMP"
sweep "nohome-nonlab"  env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$TMP"
sweep "nohome-quiet"   env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --quiet
sweep "nohook"         env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --hook --path "$LABP"
sweep "help"           bash "$SCRIPT" --help
sweep "arg-inconnu"    bash "$SCRIPT" --nawak
sweep "path-nu"        bash "$SCRIPT" --path
sweep "path-vide"      bash "$SCRIPT" --path ""
sweep "hook+quiet"     bash "$SCRIPT" --hook --quiet
if [ "$n_swept" -ge 20 ] && [ -z "$hors_contrat" ]; then
  ok "33 BALAYAGE — $n_swept exécutions (toutes les fixtures × moteur présent/absent + toutes les formes d'invocation) : aucun rc hors de {0, 3, 64}"
else ko "33 BALAYAGE — aucun rc hors du contrat {0, 3, 64}" "n_swept=$n_swept (plancher 20) hors_contrat=[$hors_contrat]"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
