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
#
# --- Pourquoi un LAB PIÉGÉ, en plus des moteurs factices (cas 34) -------------------------------
# Un moteur factice mesure ce que le script LIT ; il ne mesure pas ce qu'il ÉVITE d'exécuter. Le
# cas 34 pose donc un lab dont les trois modules de moteur écrivent chacun un témoin sur disque à
# leur chargement : le témoin est la seule preuve DIRECTE que l'exécution n'a pas eu lieu, et le
# seul dispositif qui rougisse si une version future du script recommençait à charger le moteur.
# Le cas 35 est son pendant STATIQUE — il mesure la propriété du texte du programme node, donc vaut
# pour tout moteur, y compris ceux qu'aucune fixture ne représente. Les deux sont nécessaires : un
# chargement de module sans effet observable échappe au cas 34 et n'est attrapé que par le 35.

#
# --- Pourquoi des MUTANTS MATÉRIALISÉS (mode --mutants) -----------------------------------------
# Un filet anti-régression qui n'a jamais été vu rougir ne prouve rien. Les mutants de cette suite
# ne vivent donc PAS dans un rapport : ils sont ÉCRITS ICI, sous `--mutants`, et rejouables par
# quiconque (`bash test-check-gsd-config.sh --mutants`). Chaque mutant déclare les cas qu'il DOIT
# faire rougir ; le mode échoue si l'un d'eux reste vert, et échoue aussi si la mutation n'a rien
# changé au fichier (motif introuvable = mutant NON OPPOSABLE, pas mutant satisfait).
# Le mode se relance lui-même en sous-processus via VF_TEST_TARGET, qui pointe la suite sur une
# COPIE mutée du script ; la copie vit dans le mktemp -d de la session et disparaît avec elle.
set -uo pipefail

MUTANTS=0
for a in "$@"; do case "$a" in --mutants) MUTANTS=1 ;; esac; done

# VF_TEST_TARGET : cible sous test. Sert UNIQUEMENT au mode --mutants, qui se relance sur une copie
# mutée. Non défini, la suite teste le script du dépôt — le chemin normal.
SCRIPT="${VF_TEST_TARGET:-$(cd "$(dirname "$0")/.." && pwd)/check-gsd-config.sh}"

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

# === Extraction du corps du programme node (partagée par les cas 34 et 35) ======================
# ANCRE : la ligne `IFS= read -r -d '' NODE_PROG <<'NODEJS'` ELLE-MÊME, et non le seul marqueur
# `<<'NODEJS'`. Le marqueur seul matche DEUX lignes du script — la vraie, et le commentaire de
# portabilité qui cite `NODE_PROG=$(cat <<'NODEJS' … )`. L'extraction ramassait donc 4 lignes de
# commentaire SHELL en plus du programme (186 lignes là où le programme en fait 182), lignes que le
# dépouillement JS ne nettoie pas. Mesuré, pas supposé.
NP="$TMP/node-prog.js"
awk '
  /^IFS= read -r -d .. NODE_PROG <<.NODEJS./ { inb = 1; next }
  inb && /^NODEJS$/                          { inb = 0; next }
  inb                                        { print }
' "$SCRIPT" > "$NP"

# Cibles du moteur que le programme node OUVRE, DÉRIVÉES DU SCRIPT et jamais recopiées : tout nom de
# fichier .cjs / .json cité dans le corps. Écrire cette liste en dur, c'est ce qui a laissé le cas 34
# ne piéger que 3 des 5 modules réellement lus ; dérivée, elle suit le script quand il change.
# \047 = l'apostrophe, écrite en octal : le programme awk est lui-même en quotes simples.
CIBLES="$TMP/cibles-moteur.txt"
awk '{ n = split($0, p, "\047"); for (i = 2; i <= n; i += 2) if (p[i] ~ /^[A-Za-z0-9_.-]+\.(cjs|json)$/) print p[i] }' "$NP" \
  | sort -u > "$CIBLES"
N_CIBLES="$(awk 'END{print NR+0}' "$CIBLES")"

# === Cas 34 — NON-EXÉCUTION : un moteur piégé, résolu depuis le dépôt audité, n'est PAS exécuté ==
# Écrit AVANT le cas 33 parce que le balayage final rejoue le lab construit ici.
#
# Le vecteur (T-23-02-07, arbitrage A-6) : la première branche de la cascade résout le moteur DANS
# le dépôt audité. Tant que le script faisait un require() dessus, ouvrir une session dans un dépôt
# cloné suffisait à faire exécuter du code arbitraire au SessionStart — le gate sortait en 0 et le
# `|| true` du hook masquait tout. La cascade n'a pas changé ; c'est l'exécution qui a disparu.
#
# TOUTES les cibles sont piégées, chacune avec SON PROPRE témoin — pas trois sur cinq. Le commentaire
# de la version précédente énonçait la règle (« n'en piéger qu'un laisserait passer une implémentation
# qui n'exécuterait plus que les autres ») sans l'appliquer : config-schema.cjs et config-loader.cjs
# étaient lus par le script et sans témoin. La liste est maintenant DÉRIVÉE (voir $CIBLES).
# Les deux manifestes sont piégés avec du JS : `require()` d'un .json passe par le parseur JSON et
# n'exécuterait rien, mais un retour à `eval(readFileSync(manifeste))`, lui, ferait feu.
#
# UN PIÈGE NON OUVERT NE PROUVE RIEN. `readLiteral` s'arrête au PREMIER fichier qui rend un littéral
# acceptable : piéger cinq modules en laissant le premier porter la donnée n'exerce que le premier.
# Le lab est donc rejoué en QUATRE variantes, qui déplacent le PORTEUR de la donnée le long des
# cascades de `readLiteral` — chaque variante prouve, par la sortie, que ses porteurs ont été ouverts :
#   V1 porteur config.cjs        (source 1 rang 1, source 3 rang 3)
#   V2 porteur configuration.cjs (source 1 rang 2, source 3 rang 1)
#   V3 porteurs config-schema.cjs (source 1 rang 3) et config-loader.cjs (source 3 rang 2)
#   V4 porteurs les DEUX MANIFESTES (valides), tous les .cjs restant des pièges nus
# capability-registry.cjs porte configKeys dans les quatre. Les cinq modules et les deux manifestes
# sont donc chacun prouvés OUVERTS au moins une fois, et piégés dans toutes les autres variantes.
#
# L'invocation passe OBLIGATOIREMENT par la branche 1 de la cascade (`--path`, sans surcharge VF_) —
# c'est le chemin du hook, et le seul qui exerce la résolution depuis le dépôt audité. `env -u`
# retire les deux surcharges même si l'environnement appelant les exportait.
#
# Quatre assertions par variante, exigées ENSEMBLE :
#   (a) aucun témoin n'existe, et le contrat de sortie tient ;
#   (b) une sonde du fichier audité est bien SIGNALÉE — donc le fichier a été lu ;
#   (c) une clé déclarée UNIQUEMENT par le porteur piégé est ÉPARGNÉE — donc il a bien été LU ;
#   (d) la VALEUR de défaut amont portée par le porteur de la source 3 ressort SUR SA PROPRE LIGNE —
#       une relation, pas une co-présence, et une valeur (7 ou 9) qu'aucun défaut réel ne porte.
# (b), (c) et (d) sont l'anti « vert à vide » : sans elles, un script qui sortirait toujours en 3
# sans rien lire satisferait (a) trivialement.

# mk_lab_piege <dir> <dossier-témoins> <porteur-source1> <porteur-source3>
# Porteur « MANIFESTES » : les deux manifestes portent la donnée (en JSON valide) et aucun .cjs.
mk_lab_piege() {
  local d="$1" pwn="$2" src1="$3" src3="$4" base tgt
  rm -rf "$d" "$pwn"
  mkdir -p "$d/.planning" "$d/.claude/gsd-core/bin/lib" "$d/.claude/gsd-core/bin/shared" "$pwn"
  while read -r base; do
    case "$base" in
      *.json) tgt="$d/.claude/gsd-core/bin/shared/$base" ;;
      *)      tgt="$d/.claude/gsd-core/bin/lib/$base" ;;
    esac
    printf "require('fs').writeFileSync('%s/pwned-%s', 'x');\n" "$pwn" "$base" > "$tgt"
  done < "$CIBLES"
  cat >> "$d/.claude/gsd-core/bin/lib/capability-registry.cjs" <<'JS'
module.exports = { configKeys: { 'workflow.code_review': 'code-review' } };
JS
  if [ "$src1" = "MANIFESTES" ]; then
    cat > "$d/.claude/gsd-core/bin/shared/config-schema.manifest.json" <<'J'
{ "validKeys": ["mode", "cle_connue_du_moteur_piege"], "dynamicKeyPatterns": [{ "topLevel": "agent_skills" }] }
J
    cat > "$d/.claude/gsd-core/bin/shared/config-defaults.manifest.json" <<'J'
{ "mode": "interactive", "workflow": { "node_repair_budget": 9 } }
J
  else
    cat >> "$d/.claude/gsd-core/bin/lib/$src1" <<'JS'
module.exports = { VALID_CONFIG_KEYS: new Set([ 'mode', 'cle_connue_du_moteur_piege' ]),
  DYNAMIC_KEY_PATTERNS: [{ topLevel: 'agent_skills' }] };
JS
    cat >> "$d/.claude/gsd-core/bin/lib/$src3" <<'JS'
module.exports = { CONFIG_DEFAULTS: { mode: 'interactive', workflow: { node_repair_budget: 7 } } };
JS
  fi
  printf '%s\n' '{ "cle_connue_du_moteur_piege": 1, "sonde_du_cas": { "x": 1 } }' > "$d/.planning/config.json"
}

n_var34=0; ec34=""
essaie_lab_piege() { # <étiquette> <porteur1> <porteur3> <valeur-defaut-attendue>
  local lab="$TMP/lab-piege-$1" pwn="$TMP/pwn-$1" out rc n_pwned budget_line
  mk_lab_piege "$lab" "$pwn" "$2" "$3"
  out="$(env -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$lab" 2>/dev/null)"; rc=$?
  # Le compte est fait sur les ENTRÉES du dossier de témoins, jamais sur la vacuité d'une chaîne.
  n_pwned="$(ls "$pwn" 2>/dev/null | awk 'END{print NR+0}')"
  budget_line="$(printf '%s\n' "$out" | awk '/workflow\.node_repair_budget /{print}')"
  n_var34=$((n_var34+1))
  case "$rc" in 0) : ;; *) ec34="$ec34 [$1 rc=$rc]" ;; esac
  [ "$n_pwned" -eq 0 ]                     || ec34="$ec34 [$1 temoins=$n_pwned]"
  case "$out" in *sonde_du_cas*) : ;; *)      ec34="$ec34 [$1 sonde-non-signalee]" ;; esac
  case "$out" in *cle_connue_du_moteur_piege*) ec34="$ec34 [$1 cle-du-porteur-signalee-donc-non-lu]" ;; esac
  case "$budget_line" in *"($4)"*) : ;; *)    ec34="$ec34 [$1 defaut-amont-absent:[$budget_line]]" ;; esac
  LABX="$lab"
}
essaie_lab_piege v1 config.cjs        config.cjs        7
essaie_lab_piege v2 configuration.cjs configuration.cjs 7
essaie_lab_piege v3 config-schema.cjs config-loader.cjs 7
essaie_lab_piege v4 MANIFESTES        MANIFESTES        9
# Plancher : la dérivation doit avoir trouvé les 5 modules + les 2 manifestes. Une dérivation qui
# rendrait 0 cible poserait 0 piège et rendrait ce cas vert sans rien mesurer.
if [ "$N_CIBLES" -ge 7 ] && [ "$n_var34" -eq 4 ] && [ -z "$ec34" ]; then
  ok "34 NON-EXÉCUTION — $N_CIBLES cibles du moteur dérivées du script et TOUTES piégées, sur 4 variantes qui déplacent le porteur de la donnée le long des cascades : AUCUN témoin créé, la sonde du fichier audité signalée, la clé du porteur épargnée ET son défaut amont rendu sur sa propre ligne, exit 0"
else ko "34 NON-EXÉCUTION — moteur piégé lu et jamais exécuté, sur toutes les cibles et tous les rangs de cascade" "cibles=$N_CIBLES (plancher 7) variantes=$n_var34 (4 attendues) echecs=[$ec34]"; fi

# === Cas 35 — CRITÈRE MACHINE : le programme node ne charge QUE des modules cœur =================
# Pendant du `grep -c 'eval'` de T-23-02-01, pour T-23-02-07. Le cas 34 mesure un COMPORTEMENT sur
# un moteur donné ; celui-ci mesure la PROPRIÉTÉ du texte, donc vaut pour tout moteur, y compris
# ceux qu'aucune fixture ne représente.
#
# --- Pourquoi ce n'est plus un COMPTAGE DE LITTÉRAL ----------------------------------------------
# La version précédente comptait le littéral `require\(`. Elle était fausse dans les DEUX SENS, et
# c'est mesuré :
#   - TROP PERMISSIVE — sur les 17 formes d'appel réelles, 7 échappaient, dont `require (` avec UNE
#     SEULE ESPACE, `const _r = require`, `require['call']`, `Reflect.apply`,
#     `module.constructor._load` et `process.binding`. Un mutant écrivant `const _load = require;`
#     puis `_load(path.join(LIB, …))` ROUVRAIT la RCE avec la suite à 35 ok / 0 ko.
#   - TROP STRICTE — elle ne dépouillait que les commentaires DE LIGNE : un commentaire DE BLOC ou
#     une CHAÎNE nommant l'interdit faisaient rougir du code parfaitement sain. La pente naturelle
#     aurait alors été de relâcher le critère plutôt que de corriger le commentaire — exactement le
#     mouvement qui a produit la faille d'origine.
#
# --- La forme du critère : ÉRODER LE LICITE, EXIGER UN RÉSIDU NUL --------------------------------
# On ne cherche plus des formes interdites (liste fermée, contournable par réécriture cosmétique) :
# on NEUTRALISE d'abord ce qui ne peut pas s'exécuter (commentaires, contenu des chaînes, littéraux
# de regex), on ÉRODE ensuite les seules formes licites — `require('fs')`, `require('path')`, et les
# accès `process.env` / `process.exit` / `process.stdout` —, et on exige que le RÉSIDU soit VIDE.
# Une forme d'appel n'a alors que trois façons d'exister, et les trois rougissent :
#   1. elle nomme `require` ou `process` autrement que sous leur forme licite → résidu non nul ;
#   2. elle passe par une échappée réflexive (`eval`, `Function`, `import`, `module`, `constructor`,
#      `global`, `Reflect`, `_load`, `binding`, `dlopen`, `WebAssembly`, `vm`) → résidu non nul ;
#   3. elle APPELLE un nom qui n'est pas dans la liste blanche des noms réellement appelés.
# BORNE ÉCRITE, à remonter plutôt qu'à taire : une forme qui chargerait du code sans nommer AUCUN de
# ces porteurs et sans appeler de nom neuf échapperait encore. Aucune n'est connue en Node ; si une
# telle forme apparaît, c'est la liste des porteurs qu'il faut étendre, pas le critère qu'il faut
# relâcher.
#
# --- Le lexeur, et pourquoi sa santé est ASSERTÉE -----------------------------------------------
# Neutraliser suppose de savoir où commencent et finissent chaînes, commentaires et regex. Trois
# invariants sont donc exigés, faute de quoi le cas sort en KO « non vérifiable » et JAMAIS en vert :
#   - aucune chaîne '…' / "…" laissée ouverte en fin de ligne (un saut de ligne nu y est ILLÉGAL en
#     JS : s'y trouver prouve que le lexeur a ouvert une chaîne fantôme, typiquement sur la quote
#     d'un littéral de regex — le programme en porte une, `/\\'/g`) ;
#   - état normal et interpolation fermée en fin de fichier ;
#   - tout littéral de regex rencontré appartient à la liste blanche. C'est ce point qui ferme la
#     seule ambiguïté que le lexeur ne peut pas trancher seul : une DIVISION serait lue comme une
#     regex et pourrait masquer du code entre ses deux `/`. Une telle « regex » ne ressemble à
#     aucune des vraies et rougit.
# Les `${…}` d'un littéral de gabarit sont du CODE et repassent en état normal : sans cela, une
# interpolation porteuse d'un chargement serait avalée comme du contenu de chaîne.
#
# @ est le marqueur de neutralisation. Sa présence dans le corps casserait la neutralisation : elle
# est donc vérifiée absente, et le cas sort en KO si elle ne l'est pas.
LEXOUT="$TMP/np-neutre.txt"; LEXERR="$TMP/np-lex.txt"
RXOUT="$TMP/np-regex.txt";   CALLOUT="$TMP/np-calls.txt"
: > "$RXOUT"; : > "$CALLOUT"
n_at="$(awk '{ n += gsub(/@/, "") } END{ print n+0 }' "$NP")"
awk -v REGEX_OUT="$RXOUT" '
  BEGIN { st = "n"; unterm = 0; nregex = 0; tn = 0; bdepth = 0 }
  {
    line = $0; outl = (st == "t") ? "@" : ""; i = 1; L = length(line)
    while (i <= L) {
      c = substr(line, i, 1)
      if (st == "n") {
        d = substr(line, i, 2)
        if (d == "//") { i = L + 1; continue }
        if (d == "/*") { st = "b"; i += 2; continue }
        if (c == "/") {
          j = i + 1; inclass = 0; lit = "/"
          while (j <= L) {
            e = substr(line, j, 1)
            if (e == "\\") { lit = lit substr(line, j, 2); j += 2; continue }
            if (e == "[") inclass = 1
            else if (e == "]") inclass = 0
            else if (e == "/" && inclass == 0) break
            lit = lit e; j++
          }
          if (j > L) { regex_bad++; outl = outl "@@"; i = L + 1; continue }
          lit = lit "/"; j++
          while (j <= L && substr(line, j, 1) ~ /[a-z]/) { lit = lit substr(line, j, 1); j++ }
          print lit > REGEX_OUT
          nregex++; outl = outl "@@"; i = j; continue
        }
        if (c == "\047") { st = "s"; outl = outl "@"; i++; continue }
        if (c == "\"")   { st = "d"; outl = outl "@"; i++; continue }
        if (c == "`")    { st = "t"; outl = outl "@"; i++; continue }
        if (c == "{") { bdepth++; outl = outl c; i++; continue }
        if (c == "}") {
          if (bdepth > 0) { bdepth-- }
          else if (tn > 0) { st = "t"; bdepth = tsave[tn]; tn--; outl = outl "@"; i++; continue }
          outl = outl c; i++; continue
        }
        outl = outl c; i++; continue
      }
      if (st == "b") {
        e = index(substr(line, i), "*/")
        if (e == 0) { i = L + 1 } else { i = i + e + 1; st = "n" }
        continue
      }
      if (c == "\\") { i += 2; continue }
      if (st == "t" && substr(line, i, 2) == "${") {
        tn++; tsave[tn] = bdepth; bdepth = 0; st = "n"; outl = outl "@"; i += 2; continue
      }
      if ((st == "s" && c == "\047") || (st == "d" && c == "\"") || (st == "t" && c == "`")) {
        st = "n"; outl = outl "@"; i++; continue
      }
      outl = outl c; i++
    }
    if (st == "s" || st == "d") { unterm++; st = "n"; outl = outl "@" }
    else if (st == "t") { outl = outl "@" }
    print outl
  }
  END { printf "%d %s %d %d %d\n", unterm, st, nregex, regex_bad + 0, tn > REGEX_STAT }
' REGEX_STAT="$LEXERR" "$NP" > "$LEXOUT"
lex_unterm="$(awk '{print $1}' "$LEXERR")"
lex_state="$(awk  '{print $2}' "$LEXERR")"
lex_nrx="$(awk    '{print $3}' "$LEXERR")"
lex_rxbad="$(awk  '{print $4}' "$LEXERR")"
lex_tn="$(awk     '{print $5}' "$LEXERR")"

# Érosion des formes licites, puis résidu. Les chaînes survivantes sont réduites à @@ APRÈS
# l'érosion : une chaîne qui CONTIENDRAIT le texte `require('fs')` ne gonfle donc pas le résidu.
eval "$(awk -v CALLS_OUT="$CALLOUT" '
  {
    l = $0
    n_core   += gsub(/require\(@fs@\)/, "", l) + gsub(/require\(@path@\)/, "", l)
    n_procok += gsub(/process\.(env|exit|stdout)/, "", l)
    gsub(/@[^@]*@/, "@@", l)
    n_bigF   += gsub(/Function/, "", l)
    ll = tolower(l)
    n_res += gsub(/require|eval|import|module|constructor|global|reflect|_load|binding|dlopen|webassembly|process/, "", ll)
    n_res += gsub(/(^|[^a-z0-9_$])vm([^a-z0-9_$]|$)/, "", ll)
    while (match(l, /[A-Za-z_$][A-Za-z0-9_$]*[ \t]*\(/)) {
      tok = substr(l, RSTART, RLENGTH); sub(/[ \t]*\($/, "", tok)
      print tok > CALLS_OUT
      l = substr(l, RSTART + RLENGTH)
    }
  }
  END { printf "n_core=%d; n_procok=%d; n_bigF=%d; n_res=%d\n", n_core, n_procok, n_bigF, n_res }
' "$LEXOUT")"

# Listes blanches. Comparées par `comm` en INCLUSION (aucun intrus), jamais par diff ni par
# longueur : un nom appelé ou un littéral de regex qui n'y figure pas est un AJOUT CONSCIENT à
# faire, pas un critère à relâcher.
CALLS_SEEN="$TMP/calls-seen.txt"; CALLS_ALLOW="$TMP/calls-allow.txt"
RX_SEEN="$TMP/rx-seen.txt";       RX_ALLOW="$TMP/rx-allow.txt"
sort -u "$CALLOUT" > "$CALLS_SEEN"
sort -u "$RXOUT"   > "$RX_SEEN"
printf '%s\n' J RegExp Set String accept add balancedRegions call catch concat exec filter \
  flatten for from has if indexOf isArray join jsLiteralToJSON keys lookup map parse push \
  readFileSync readJSON readLiteral replace slice slurp some split stringify test while write \
  | sort -u > "$CALLS_ALLOW"
{ printf '%s\n' '/\s+/' '/\s/' '/\\'"'"'/g' '/,(\s*[}\]])/g'
  printf '%s\n' '/([A-Za-z_$][A-Za-z0-9_$]*)(\s*):/y'; } | sort -u > "$RX_ALLOW"
calls_intrus="$(comm -23 "$CALLS_SEEN" "$CALLS_ALLOW" | tr '\n' ' ')"
rx_intrus="$(comm -23 "$RX_SEEN" "$RX_ALLOW" | tr '\n' ' ')"
n_calls="$(awk 'END{print NR+0}' "$CALLS_SEEN")"

# Anti « vert à vide », dans les deux directions :
#   - le corps a bien été extrait (plancher de lignes + la source 1 y est nommée) ;
#   - le corps ADRESSE bel et bien des fichiers du moteur (path.join(LIB…). Sans ce marqueur, un
#     programme qui ne toucherait plus du tout au moteur satisferait le critère sans rien prouver ;
#   - la neutralisation a bel et bien produit des noms appelés et des regex, sinon les deux
#     inclusions seraient vraies sur du vide.
n_np="$(awk 'END{print NR+0}' "$NP")"
n_libpath="$(awk '{ n += gsub(/path\.join\(LIB/, "") } END{ print n+0 }' "$NP")"
has_src1=0; case "$(cat "$NP")" in *VALID_CONFIG_KEYS*) has_src1=1 ;; esac
extracted35=0
[ "$n_np" -ge 100 ] && [ "$has_src1" -eq 1 ] && [ "$n_libpath" -ge 1 ] \
  && [ "$n_calls" -ge 30 ] && [ "$lex_nrx" -ge 4 ] && extracted35=1
lexsain35=0
[ "$n_at" -eq 0 ] && [ "$lex_unterm" -eq 0 ] && [ "$lex_state" = "n" ] \
  && [ "$lex_rxbad" -eq 0 ] && [ "$lex_tn" -eq 0 ] && lexsain35=1
if [ "$extracted35" -eq 1 ] && [ "$lexsain35" -eq 1 ] \
   && [ "$n_res" -eq 0 ] && [ "$n_bigF" -eq 0 ] && [ "$n_core" -ge 2 ] \
   && [ -z "$calls_intrus" ] && [ -z "$rx_intrus" ]; then
  ok "35 CRITÈRE MACHINE — le programme node adresse $n_libpath chemins du moteur sans en charger aucun : après érosion de ses $n_core chargements cœur et de ses $n_procok accès process licites, le RÉSIDU des porteurs de chargement est VIDE, ses $n_calls noms appelés et ses $lex_nrx littéraux de regex sont tous dans la liste blanche"
else ko "35 CRITÈRE MACHINE — résidu de chargement nul et noms appelés dans la liste blanche" "corps=$n_np lignes (plancher 100) src1=$has_src1 libpath=$n_libpath lexeur(marqueur@=$n_at chaine_ouverte=$lex_unterm etat=$lex_state regex_cassee=$lex_rxbad interpolation=$lex_tn) coeur=$n_core residu=$n_res Function=$n_bigF appels=$n_calls intrus=[$calls_intrus] regex=$lex_nrx regex_intrus=[$rx_intrus]"; fi

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
# Le glob "$TMP"/cfg-*.json absorbe toute fixture créée par mk_config ; les labs, eux, doivent être
# listés EXPLICITEMENT — leur config vit sous <lab>/.planning/, hors du glob.
for f in "$TMP"/cfg-*.json "$CFG_H" "$LABP/.planning/config.json" "$LABX/.planning/config.json"; do
  [ -f "$f" ] || continue
  sweep "moteur:$f"      env VF_GSD_CORE_LIB="$ENG"              VF_CONFIG_PATH="$f" bash "$SCRIPT"
  sweep "sans-moteur:$f" env VF_GSD_CORE_LIB="$TMP/pas-de-moteur" VF_CONFIG_PATH="$f" bash "$SCRIPT"
done
# Formes d'invocation, y compris celles qui passent par la CASCADE (donc par $HOME).
sweep "path-nominal"   env -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$LABP"
sweep "path-nohome"    env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$LABP"
sweep "path-nonlab"    env -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$TMP"
sweep "path-piege"     env -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$LABX"
sweep "nohome-nonlab"  env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --path "$TMP"
sweep "nohome-quiet"   env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --quiet
sweep "nohook"         env -u HOME -u VF_CONFIG_PATH -u VF_GSD_CORE_LIB bash "$SCRIPT" --hook --path "$LABP"
sweep "help"           bash "$SCRIPT" --help
sweep "arg-inconnu"    bash "$SCRIPT" --nawak
sweep "path-nu"        bash "$SCRIPT" --path
sweep "path-vide"      bash "$SCRIPT" --path ""
sweep "hook+quiet"     bash "$SCRIPT" --hook --quiet
# Moitié STATIQUE du même contrat. Le balayage ci-dessus n'exerce que les chemins qu'il sait
# atteindre ; un `exit` hors contrat sur un chemin qu'aucune fixture ne déclenche lui échapperait.
# On mesure donc aussi le TEXTE : ÉGALITÉ D'ENSEMBLE entre les codes de sortie littéraux du script
# et {0, 3, 64}, dans les deux directions par `comm`. L'égalité, et non une liste noire sur `exit 1` :
# un `exit 2` neuf doit rougir tout autant. Le contrat a déjà été mal ÉNONCÉ (« 1× exit 0, 2× exit 64 »
# là où le fichier en porte 2 et 3) ; il est désormais compté par la machine, jamais de mémoire.
EXITS_SEEN="$TMP/exits-seen.txt"; EXITS_ALLOW="$TMP/exits-allow.txt"
awk '{ l = $0
  while (match(l, /(^|[^A-Za-z_])exit [0-9]+/)) { t = substr(l, RSTART, RLENGTH); sub(/.*exit /, "", t); print t; l = substr(l, RSTART + RLENGTH) }
  l = $0
  while (match(l, /process\.exit\([0-9]+\)/)) { t = substr(l, RSTART, RLENGTH); gsub(/[^0-9]/, "", t); print t; l = substr(l, RSTART + RLENGTH) } }' \
  "$SCRIPT" | sort -u > "$EXITS_SEEN"
printf '%s\n' 0 3 64 | sort -u > "$EXITS_ALLOW"
n_exits="$(awk 'END{print NR+0}' "$EXITS_SEEN")"
exits_seuls="$(comm -23 "$EXITS_SEEN" "$EXITS_ALLOW" | tr '\n' ' ')"
contrat_seuls="$(comm -13 "$EXITS_SEEN" "$EXITS_ALLOW" | tr '\n' ' ')"
if [ "$n_swept" -ge 20 ] && [ -z "$hors_contrat" ] \
   && [ "$n_exits" -eq 3 ] && [ -z "$exits_seuls" ] && [ -z "$contrat_seuls" ]; then
  ok "33 BALAYAGE — $n_swept exécutions (toutes les fixtures × moteur présent/absent + toutes les formes d'invocation) : aucun rc hors de {0, 3, 64}, ET les codes de sortie ÉCRITS dans le script forment exactement cet ensemble"
else ko "33 BALAYAGE — aucun rc hors du contrat {0, 3, 64}, et codes écrits égaux à cet ensemble" "n_swept=$n_swept (plancher 20) hors_contrat=[$hors_contrat] codes_ecrits=$n_exits en_trop=[$exits_seuls] manquants=[$contrat_seuls]"; fi

# === Mutants (--mutants) — le filet est-il capable de rougir ? ==================================
# Chaque mutant est une réécriture MÉCANIQUE du script, rejouable, qui déclare les cas qu'elle doit
# faire rougir. Deux garde-fous avant tout verdict, parce qu'un mutant qui ne mute rien « passe » :
#   - la mutation doit avoir CHANGÉ le fichier (comparaison par `cmp`, jamais par `diff`) ;
#   - le mutant doit rester un script valide, sinon il rougirait pour la mauvaise raison.
# Le mutant LICITE est le sens inverse, et il est aussi important que les autres : commentaire de
# bloc, chaîne et littéral de gabarit nommant les formes interdites doivent laisser la suite VERTE.
# Sans lui, on refermerait le trou en rendant le critère inutilisable sur du code sain.
if [ "$MUTANTS" -eq 1 ]; then
  echo ""
  echo "== mutants =="
  MUTD="$TMP/mutants"; mkdir -p "$MUTD"

  mutant() { # <nom> <cas devant rougir, vides = aucun> <fichier awk de mutation> <intention>
    local nom="$1" attendus="$2" prog="$3" intention="$4"
    local m="$MUTD/$nom.sh" log="$MUTD/$nom.log"
    awk -f "$prog" "$SCRIPT" > "$m"; chmod +x "$m"
    if cmp -s "$m" "$SCRIPT"; then
      ko "MUT $nom — $intention" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"; return
    fi
    if ! bash -n "$m" 2>/dev/null; then
      ko "MUT $nom — $intention" "le mutant n'est pas un script valide : il rougirait pour la mauvaise raison"; return
    fi
    VF_TEST_TARGET="$m" bash "$0" > "$log" 2>&1
    awk '/^  ✗ /{ sub(/^  ✗ /, ""); split($0, p, " "); print p[1] }' "$log" | sort -u > "$MUTD/$nom.rouges"
    printf '%s\n' $attendus | awk 'NF' | sort -u > "$MUTD/$nom.attendus"
    local rouges manquants
    rouges="$(tr '\n' ' ' < "$MUTD/$nom.rouges")"
    manquants="$(comm -23 "$MUTD/$nom.attendus" "$MUTD/$nom.rouges" | tr '\n' ' ')"
    if [ -z "$attendus" ]; then
      if [ -z "$rouges" ]; then ok "MUT $nom — $intention : la suite reste VERTE, comme elle le doit"
      else ko "MUT $nom — $intention : la suite doit rester VERTE" "cas rougis à tort : [$rouges] (log : $log)"; fi
    else
      if [ -z "$manquants" ]; then ok "MUT $nom — $intention : cas [$attendus] rougis comme annoncé (rouges : [$rouges])"
      else ko "MUT $nom — $intention : les cas [$attendus] doivent rougir" "restés VERTS : [$manquants] — rouges observés : [$rouges] (log : $log)"; fi
    fi
  }

  cat > "$MUTD/m1.awk" <<'AWK'
/const src = slurp\(path\.join\(LIB, f\)\);/ { print "    try { require(path.join(LIB, f)); } catch (e) {}" }
{ print }
AWK
  cat > "$MUTD/m2.awk" <<'AWK'
{ sub(/if \(v !== null && accept\(v\)\) return v;/, "if (false && v !== null && accept(v)) return v;"); print }
AWK
  cat > "$MUTD/m3.awk" <<'AWK'
/const src = slurp\(path\.join\(LIB, f\)\);/ { print "    try { require('os'); } catch (e) {}" }
{ print }
AWK
  cat > "$MUTD/m4.awk" <<'AWK'
{ sub(/<<'NODEJS' \|\| true/, "<<'NODEPROG' || true"); if ($0 == "NODEJS") $0 = "NODEPROG"; print }
AWK
  cat > "$MUTD/m5.awk" <<'AWK'
{ print }
/^const ARB = / {
  print "/* interdits documentés : require(, eval, new Function, module.constructor._load */"
  print "const NOTE_INTERDITS = ['require(', 'eval', 'new Function', 'process.binding'];"
  print "const NOTE_T = `require(${LIB}) puis eval puis new Function`;"
}
AWK
  cat > "$MUTD/m6.awk" <<'AWK'
{ print }
/^const ARB = / { print "process.exit(3);" }
AWK
  # m7 vise un basename FIXE, et c'est délibéré : c'est la forme DURE. Avec la variable de boucle,
  # le chargement frappe config.cjs, que l'ancienne fixture piégeait déjà — le cas 34 rougissait donc
  # tout seul. Avec 'config-schema.cjs', il ne frappait QUE l'un des deux modules laissés sans témoin :
  # l'ancienne suite sortait à 35 ok / 0 ko pendant que le témoin « RCE confirmée » était écrit.
  cat > "$MUTD/m7.awk" <<'AWK'
/^const path = require/ { print; print "const _load = require;"; next }
/const src = slurp\(path\.join\(LIB, f\)\);/ { print "    try { _load(path.join(LIB, 'config-schema.cjs')); } catch (e) {}" }
{ print }
AWK

  mutant m1 "34 35" "$MUTD/m1.awk" "require() rétabli dans readLiteral — la RCE d'origine"
  mutant m2 "34"    "$MUTD/m2.awk" "readLiteral n'accepte plus rien — le gate devient muet"
  mutant m3 "35"    "$MUTD/m3.awk" "chargement SANS effet observable — invisible au lab piégé"
  mutant m4 "35"    "$MUTD/m4.awk" "terminateur du here-doc renommé — l'extraction ne trouve plus le corps"
  mutant m5 ""      "$MUTD/m5.awk" "réécriture LICITE (commentaire de bloc, chaîne, gabarit) nommant les interdits"
  mutant m6 "34"    "$MUTD/m6.awk" "script totalement MUET — le cas 34 n'est pas satisfaisable par un silence"
  mutant m7 "34 35" "$MUTD/m7.awk" "require ALIASÉ (const _load = require) — la régression qui rouvrait la RCE"
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
