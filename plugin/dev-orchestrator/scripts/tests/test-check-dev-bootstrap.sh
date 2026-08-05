#!/usr/bin/env bash
# test-check-dev-bootstrap.sh — Suite de vérification de check-dev-bootstrap.sh (SIG-01, plan 17-01).
#
# Un cas par piège. Fixtures isolées via mktemp -d + --path, jamais sur le repo réel.
# Piège central (D-14) : à l'état 3, le script IMPRIME une ligne ET sort en 3 — rupture assumée
# de la convention « exit 3 ⇔ silence ». Chaque cas capture stdout ET le code de retour dans DEUX
# variables distinctes (out=...; rc=$?) et les teste par DEUX conditions séparées — jamais une
# assertion qui déduit l'absence de sortie du code 3.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-dev-bootstrap.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Crée $TMP/<nom> et rien d'autre — chaque cas construit son propre état.
mk_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d"
  printf '%s' "$d"
}

# Fixture état 3 complète (PROJECT.md, config.json, codebase/ non vide, ROADMAP.md avec en-tête
# de phase, STATE.md avec frontmatter valide) — réutilisée par plusieurs cas de l'état 3.
mk_complete_planning() { # <name> [milestone] [phase] [status]
  local d="$TMP/$1" milestone="${2:-milestone-x}" phase="${3:-7}" status="${4:-shipped}"
  mkdir -p "$d/.planning/codebase"
  printf '# proj\n' > "$d/.planning/PROJECT.md"
  printf '{}' > "$d/.planning/config.json"
  printf 'x' > "$d/.planning/codebase/ARCH.md"
  printf '### Phase 1: x\n' > "$d/.planning/ROADMAP.md"
  printf -- '---\nmilestone: %s\ncurrent_phase: %s\nstatus: %s\n---\n' "$milestone" "$phase" "$status" \
    > "$d/.planning/STATE.md"
  printf '%s' "$d"
}

echo "== test-check-dev-bootstrap =="

# === Cas 1 — État 0 : répertoire vide → stdout vide ET exit 3 (deux conditions distinctes) =====
D="$(mk_root c1)"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "1 état 0 — répertoire vide → silence, exit 3"; else ko "1 état 0 — répertoire vide → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 2 — État 1 : code présent, aucun .planning/ → [onboard] seul, exit 0 ===================
D="$(mk_root c2)"
printf 'print(1)\n' > "$D/main.py"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_onboard=0; case "$out" in *"[onboard]"*) has_onboard=1 ;; esac
leak=0; case "$out" in *"[bootstrap]"*|*"[gsd-engine]"*) leak=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_onboard" -eq 1 ] && [ "$leak" -eq 0 ]; then ok "2 état 1 — code sans .planning/ → [onboard] seul, exit 0"; else ko "2 état 1 — code sans .planning/ → [onboard] seul, exit 0" "rc=$rc out=[$out]"; fi

# === Cas 3 — État 2 : PROJECT.md présent, config.json seul manquant → [bootstrap], exit 0 ======
D="$(mk_root c3)"
mkdir -p "$D/.planning/codebase"
printf '# proj\n' > "$D/.planning/PROJECT.md"
printf 'x' > "$D/.planning/codebase/ARCH.md"
printf '### Phase 1: x\n' > "$D/.planning/ROADMAP.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_bootstrap=0; case "$out" in *"[bootstrap]"*"config"*) has_bootstrap=1 ;; esac
leak=0; case "$out" in *"[onboard]"*|*"[gsd-engine]"*) leak=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_bootstrap" -eq 1 ] && [ "$leak" -eq 0 ]; then ok "3 état 2 — config.json seul manquant → [bootstrap], exit 0"; else ko "3 état 2 — config.json seul manquant → [bootstrap], exit 0" "rc=$rc out=[$out]"; fi

# === Cas 4 — État 2, ordre figé (D-03) : config avant codebase avant roadmap, positions =========
D="$(mk_root c4)"
mkdir -p "$D/.planning"
printf '# proj\n' > "$D/.planning/PROJECT.md"
printf 'code\n' > "$D/main.py"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
line1="$(printf '%s\n' "$out" | head -n 1)"
pos_config=$(printf '%s' "$line1" | awk '{print index($0,"config.json")}')
pos_codebase=$(printf '%s' "$line1" | awk '{print index($0,"codebase")}')
pos_roadmap=$(printf '%s' "$line1" | awk '{print index($0,"feuille de route")}')
if [ "$rc" -eq 0 ] && [ "$pos_config" -gt 0 ] && [ "$pos_codebase" -gt "$pos_config" ] && [ "$pos_roadmap" -gt "$pos_codebase" ]; then ok "4 état 2 — ordre figé config < codebase < roadmap"; else ko "4 état 2 — ordre figé config < codebase < roadmap" "rc=$rc pos=[$pos_config,$pos_codebase,$pos_roadmap] out=[$out]"; fi

# === Cas 4bis — Idempotence : deux exécutions consécutives sur la même fixture, sortie identique
out2="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc2=$?
if [ "$rc2" -eq "$rc" ] && [ "$out2" = "$out" ]; then ok "4bis état 2 — deux exécutions consécutives, sortie octet pour octet identique"; else ko "4bis état 2 — deux exécutions consécutives, sortie octet pour octet identique" "rc=$rc rc2=$rc2 out=[$out] out2=[$out2]"; fi

# === Cas 5 — État 2, item codebase conditionné : greenfield (aucun code) → codebase absent ======
D="$(mk_root c5)"
mkdir -p "$D/.planning"
printf '# proj\n' > "$D/.planning/PROJECT.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_codebase_item=0; case "$out" in *"codebase"*) has_codebase_item=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_codebase_item" -eq 0 ]; then ok "5 état 2 — greenfield sans code, item codebase absent"; else ko "5 état 2 — greenfield sans code, item codebase absent" "rc=$rc out=[$out]"; fi

# === Cas 6 — État 3 (D-14) : stdout NON VIDE assert POSITIVEMENT ET exit 3, 2 lignes ============
D="$(mk_complete_planning c6 gsd-migration 16 shipped)"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
nlines="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
if [ "$rc" -eq 3 ] && [ -n "$out" ] && [ "$nlines" = "2" ] && printf '%s' "$out" | grep -q 'gsd-migration' && printf '%s' "$out" | grep -q '16'; then ok "6 état 3 — D-14 : sortie NON VIDE ET exit 3, valeurs du frontmatter reprises"; else ko "6 état 3 — D-14 : sortie NON VIDE ET exit 3, valeurs du frontmatter reprises" "rc=$rc out=[$out]"; fi

# === Cas 7 — État 3 — mutuelle exclusion : ni [onboard] ni [bootstrap] ne fuient ================
leak=0; case "$out" in *"[onboard]"*|*"[bootstrap]"*) leak=1 ;; esac
if [ "$leak" -eq 0 ]; then ok "7 état 3 — mutuelle exclusion, aucun autre marqueur ne fuit"; else ko "7 état 3 — mutuelle exclusion, aucun autre marqueur ne fuit" "out=[$out]"; fi

# === Cas 8 — Soupape D-04 : STATE.md absent → silence total, exit 3 =============================
D="$(mk_complete_planning c8)"
rm -f "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "8 soupape D-04 — STATE.md absent → silence, exit 3"; else ko "8 soupape D-04 — STATE.md absent → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 9 — Soupape D-04 : ligne 1 n'est pas le délimiteur exact → silence, exit 3 =============
D="$(mk_complete_planning c9)"
printf 'milestone: x\ncurrent_phase: 1\nstatus: shipped\n---\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "9 soupape D-04 — ligne 1 non conforme au délimiteur → silence, exit 3"; else ko "9 soupape D-04 — ligne 1 non conforme au délimiteur → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 10 — Soupape D-04 : clé status absente du frontmatter → silence, exit 3 ================
D="$(mk_complete_planning c10)"
printf -- '---\nmilestone: x\ncurrent_phase: 1\n---\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "10 soupape D-04 — clé status absente → silence, exit 3"; else ko "10 soupape D-04 — clé status absente → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 11 — Assainissement (T-17-01) : octet de contrôle dans milestone → silence, contenu absent
D="$(mk_complete_planning c11)"
printf -- '---\nmilestone: evil\001inject\ncurrent_phase: 3\nstatus: shipped\n---\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
leak=0; case "$out" in *"evil"*) leak=1 ;; esac
if [ "$rc" -eq 3 ] && [ -z "$out" ] && [ "$leak" -eq 0 ]; then ok "11 assainissement — octet de contrôle dans milestone → silence, aucune fuite"; else ko "11 assainissement — octet de contrôle dans milestone → silence, aucune fuite" "rc=$rc out=[$out]"; fi

# === Cas 12 — Assainissement : séquence d'échappement (backslash-n littéral) → silence ==========
D="$(mk_complete_planning c12)"
printf -- '---\nmilestone: evil\\ninject\ncurrent_phase: 3\nstatus: shipped\n---\n' > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
leak=0; case "$out" in *"evil"*) leak=1 ;; esac
if [ "$rc" -eq 3 ] && [ -z "$out" ] && [ "$leak" -eq 0 ]; then ok "12 assainissement — séquence d'échappement dans milestone → silence, aucune fuite"; else ko "12 assainissement — séquence d'échappement dans milestone → silence, aucune fuite" "rc=$rc out=[$out]"; fi

# === Cas 13 — Assainissement : valeur > 80 caractères → silence, exit 3 =========================
D="$(mk_complete_planning c13)"
long="$(printf 'x%.0s' $(seq 1 90))"
printf -- '---\nmilestone: %s\ncurrent_phase: 3\nstatus: shipped\n---\n' "$long" > "$D/.planning/STATE.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "13 assainissement — valeur > 80 caractères → silence, exit 3"; else ko "13 assainissement — valeur > 80 caractères → silence, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 14 — Élagage (D-02) : node_modules peuplé seul (par ailleurs vide) → toujours état 0 ===
D="$(mk_root c14)"
mkdir -p "$D/node_modules/pkg"
printf 'x' > "$D/node_modules/pkg/index.js"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "14 élagage D-02 — node_modules peuplé seul → état 0, silence"; else ko "14 élagage D-02 — node_modules peuplé seul → état 0, silence" "rc=$rc out=[$out]"; fi

# === Cas 15 — Élagage (D-02) : fichier sous docs/ seul → toujours état 0 =========================
D="$(mk_root c15)"
mkdir -p "$D/docs"
printf 'x' > "$D/docs/readme.md"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "15 élagage D-02 — fichier sous docs/ seul → état 0, silence"; else ko "15 élagage D-02 — fichier sous docs/ seul → état 0, silence" "rc=$rc out=[$out]"; fi

# === Cas 16 — Env VF_BOOTSTRAP_PLANNING_DIR : override change l'état constaté ===================
D="$(mk_root c16-code)"
printf 'code\n' > "$D/main.py"
D2="$(mk_complete_planning c16-planning gsd-migration 9 shipped)"
out="$(VF_BOOTSTRAP_PLANNING_DIR="$D2/.planning" bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -n "$out" ] && printf '%s' "$out" | grep -q 'gsd-engine'; then ok "16 env VF_BOOTSTRAP_PLANNING_DIR — override pointe vers un état 3 hors --path"; else ko "16 env VF_BOOTSTRAP_PLANNING_DIR — override pointe vers un état 3 hors --path" "rc=$rc out=[$out]"; fi

# === Cas 17 — Arguments : --hook + --quiet ensemble → exit 64, stdout vide ======================
errfile="$TMP/c17.err"
out="$(bash "$SCRIPT" --hook --quiet 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 64 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "17 --hook + --quiet ensemble → exit 64, stdout vide, stderr non vide"; else ko "17 --hook + --quiet ensemble → exit 64, stdout vide, stderr non vide" "rc=$rc out=[$out] err=[$err]"; fi

# === Cas 18 — Arguments : argument inconnu → exit 64 ============================================
bash "$SCRIPT" --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "18 argument inconnu → exit 64"; else ko "18 argument inconnu → exit 64" "rc=$rc"; fi

# === Cas 19 — Arguments : --path sans valeur → exit 64 ==========================================
bash "$SCRIPT" --path >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "19 --path sans valeur → exit 64"; else ko "19 --path sans valeur → exit 64" "rc=$rc"; fi

# === Cas 20 — Arguments : --help → exit 0, sortie non vide ======================================
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "20 --help → exit 0, sortie non vide"; else ko "20 --help → exit 0, sortie non vide" "rc=$rc out=[$out]"; fi

# === Cas 21 — Lecture seule (D-15) : empreinte find identique avant/après exécution =============
D="$(mk_complete_planning c21 gsd-migration 5 shipped)"
before="$(find "$D" | LC_ALL=C sort)"
bash "$SCRIPT" --path "$D" >/dev/null 2>&1
after="$(find "$D" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "21 lecture seule D-15 — empreinte find identique avant/après"; else ko "21 lecture seule D-15 — empreinte find identique avant/après" "before=[$before] after=[$after]"; fi

# ================================================================================================
# Workstreams GSD (GSDA-13) — ROADMAP.md et STATE.md suivent le compartiment actif.
# ================================================================================================

# Fixture PARTITIONNÉE : racine complète SAUF ROADMAP/STATE, qui vivent dans workstreams/<ws>/.
# Le sous-dossier est donc DISCRIMINANT par construction — sans résolution, roadmap_missing() dit
# « feuille de route absente » et le script rend [bootstrap] au lieu de [gsd-engine].
mk_partitioned() { # <nom> <workstream>
  local d="$TMP/$1" ws="$2"
  mkdir -p "$d/.planning/codebase" "$d/.planning/workstreams/$ws"
  printf '# proj\n' > "$d/.planning/PROJECT.md"
  printf '{}' > "$d/.planning/config.json"
  printf 'x' > "$d/.planning/codebase/ARCH.md"
  printf '### Phase 1: x\n' > "$d/.planning/workstreams/$ws/ROADMAP.md"
  printf -- '---\nmilestone: ws-milestone\ncurrent_phase: 4\nstatus: shipped\n---\n' \
    > "$d/.planning/workstreams/$ws/STATE.md"
  printf '%s' "$d"
}

# === Cas 23 — NON-RÉGRESSION : arbre non partitionné, aucune variable posée =====================
# Le verdict de l'état 3 est celui d'avant l'ajout des workstreams, à l'octet près.
D="$(mk_complete_planning c23 gsd-migration 12 shipped)"
out="$(env -u GSD_WORKSTREAM -u VF_BOOTSTRAP_WORKSTREAM bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
nlines="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
if [ "$rc" -eq 3 ] && [ "$nlines" = "2" ] && printf '%s' "$out" | grep -q '\[gsd-engine\]' && printf '%s' "$out" | grep -q 'gsd-migration'; then
  ok "23 non-régression — arbre non partitionné, aucune variable → verdict état 3 inchangé"
else
  ko "23 non-régression — arbre non partitionné" "rc=$rc out=[$out]"
fi

# === Cas 23b — NON-RÉGRESSION : la fixture PARTITIONNÉE sans variable est DISCRIMINANTE ==========
# Preuve que le vert du cas 24 ne vient pas de la fixture : sans résolution, elle rend [bootstrap].
D="$(mk_partitioned c23b dev)"
out="$(env -u GSD_WORKSTREAM -u VF_BOOTSTRAP_WORKSTREAM bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
disc=0; case "$out" in *"[bootstrap]"*"feuille de route absente"*) disc=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$disc" -eq 1 ]; then
  ok "23b fixture partitionnée SANS workstream → [bootstrap] feuille de route absente (fixture discriminante)"
else
  ko "23b fixture partitionnée sans workstream → [bootstrap]" "rc=$rc out=[$out]"
fi

# === Cas 24 — GSD_WORKSTREAM : la fixture partitionnée devient état 3 ============================
out="$(GSD_WORKSTREAM=dev bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
leak=0; case "$out" in *"[bootstrap]"*|*"[onboard]"*) leak=1 ;; esac
if [ "$rc" -eq 3 ] && printf '%s' "$out" | grep -q '\[gsd-engine\]' && printf '%s' "$out" | grep -q 'ws-milestone' && [ "$leak" -eq 0 ]; then
  ok "24 GSD_WORKSTREAM=dev — ROADMAP et STATE lus dans le compartiment → [gsd-engine], exit 3"
else
  ko "24 GSD_WORKSTREAM=dev → [gsd-engine]" "rc=$rc out=[$out]"
fi

# === Cas 24b — DISCRIMINATION MACHINE : même fixture, seul l'environnement change ================
rc_sans=$(env -u GSD_WORKSTREAM -u VF_BOOTSTRAP_WORKSTREAM bash "$SCRIPT" --path "$D" >/dev/null 2>&1; echo $?)
rc_avec=$(GSD_WORKSTREAM=dev bash "$SCRIPT" --path "$D" >/dev/null 2>&1; echo $?)
if [ "$rc_sans" -eq 0 ] && [ "$rc_avec" -eq 3 ] && [ "$rc_sans" -ne "$rc_avec" ]; then
  ok "24b discrimination machine — rc(sans ws)=$rc_sans != rc(avec ws)=$rc_avec sur la MÊME fixture"
else
  ko "24b discrimination machine sans/avec workstream" "rc_sans=$rc_sans rc_avec=$rc_avec"
fi

# === Cas 25 — Pointeur partagé in-repo : même résultat que la variable ===========================
D="$(mk_partitioned c25 dev)"
printf 'dev\n' > "$D/.planning/active-workstream"
out="$(env -u GSD_WORKSTREAM -u VF_BOOTSTRAP_WORKSTREAM bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && printf '%s' "$out" | grep -q '\[gsd-engine\]' && printf '%s' "$out" | grep -q 'ws-milestone'; then
  ok "25 pointeur partagé .planning/active-workstream → même résolution que GSD_WORKSTREAM"
else
  ko "25 pointeur partagé → [gsd-engine]" "rc=$rc out=[$out]"
fi

# === Cas 25b — Précédence : VF_BOOTSTRAP_WORKSTREAM prime sur GSD_WORKSTREAM et sur le pointeur ==
# Le pointeur dit `dev` (valide), GSD_WORKSTREAM dit `dev` (valide), la surcharge dit `autre`
# (dossier absent) → c'est la surcharge qui gagne, donc la ligne de signalement doit citer `autre`.
err="$(VF_BOOTSTRAP_WORKSTREAM=autre GSD_WORKSTREAM=dev bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"autre"*) named=1 ;; esac
if [ "$named" -eq 1 ]; then
  ok "25b précédence — VF_BOOTSTRAP_WORKSTREAM prime sur GSD_WORKSTREAM et sur le pointeur"
else
  ko "25b précédence VF_BOOTSTRAP_WORKSTREAM" "rc=$rc err=[$err]"
fi

# === Cas 26 — Workstream nommé, dossier ABSENT → signalement NOMMÉ + repli racine, jamais silence =
D="$(mk_complete_planning c26 gsd-migration 8 shipped)"
err="$(GSD_WORKSTREAM=absent bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
out="$(GSD_WORKSTREAM=absent bash "$SCRIPT" --path "$D" 2>/dev/null)"
named=0; case "$err" in *"absent"*) named=1 ;; esac
fallback=0; case "$out" in *"[gsd-engine]"*"gsd-migration"*) fallback=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$named" -eq 1 ] && [ "$fallback" -eq 1 ]; then
  ok "26 workstream nommé sans dossier → ligne de signalement qui le NOMME + repli sur la racine"
else
  ko "26 workstream nommé sans dossier → signalement + repli" "rc=$rc out=[$out] err=[$err]"
fi

# === Cas 27 — Nom hors politique : traité comme « aucun workstream », JAMAIS concaténé ===========
# Traversée de chemin, séparateur, espace, `..` en sous-chaîne, premier caractère non alphanumérique.
# RÔLE INJECTEUR : le rejet est fail-OPEN (repli racine, exit 0) — c'est la gradation déclarée dans
# workstream-policy.sh, et elle est délibérée : ce script est un hook SessionStart, un exit non nul
# y dégraderait toutes les sessions. Ce qu'il ne fait jamais, c'est se taire ou construire un chemin.
D="$(mk_partitioned c27 dev)"
bad_all_ok=1
bad_detail=""
for bad in '../evil' 'a/b' '.' '..' 'a b' '-lead' 'x;y' 'a..b' '.hidden'; do
  o="$(GSD_WORKSTREAM="$bad" bash "$SCRIPT" --path "$D" 2>&1)"; r=$?
  # Aucun chemin construit avec ce nom, et le verdict est celui de l'arbre NON partitionné.
  case "$o" in *"workstreams/$bad"*) bad_all_ok=0; bad_detail="$bad concaténé" ;; esac
  case "$o" in *"[bootstrap]"*"feuille de route absente"*) : ;; *) bad_all_ok=0; bad_detail="$bad → verdict inattendu" ;; esac
  case "$r" in 0) : ;; *) bad_all_ok=0; bad_detail="$bad → rc=$r" ;; esac
done
if [ "$bad_all_ok" -eq 1 ]; then
  ok "27 noms hors politique (9 formes, dont ../ et /) → aucun chemin construit, verdict racine"
else
  ko "27 noms hors politique → aucune concaténation" "$bad_detail"
fi

# === Cas 27a — Nom LONG (90 car.) : amont l'ACCEPTE, ce script ne doit PAS le rejeter =============
# `isValidActiveWorkstreamName` n'a AUCUNE borne de longueur (workstream-name-policy.cjs) ; la borne
# LOCALE de 80 caractères qui vivait ici rejetait donc des noms parfaitement valides. Ce cas figurait
# auparavant dans la liste des noms « hors politique » ci-dessus — il y était par erreur, et cette
# erreur était la copie locale de la politique, pas le nom. Traitement attendu : nom VALIDE, donc
# compartiment cherché, absent, d'où le repli NOMMÉ (contrat du cas 26).
LONG_WS="$(awk 'BEGIN{s="";for(i=0;i<90;i++)s=s"x";print s}')"
err="$(GSD_WORKSTREAM="$LONG_WS" bash "$SCRIPT" --path "$D" 2>&1 >/dev/null)"; rc=$?
named=0; case "$err" in *"$LONG_WS"*) named=1 ;; esac
rejected=0; case "$err" in *"hors-politique"*) rejected=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$named" -eq 1 ] && [ "$rejected" -eq 0 ]; then
  ok "27a nom de 90 car. (valide amont) → résolu puis repli NOMMÉ, jamais un rejet de politique"
else
  ko "27a nom long accepté par amont" "rc=$rc nommé=$named rejeté=$rejected err=[$err]"
fi

# === Cas 27b — T-24-04-01 : traversée qui RÉSOUT VRAIMENT vers un compartiment réel ==============
# Les noms du cas 27 échouent à se résoudre même sans validation — ils ne discriminent donc pas le
# verdict. Celui-ci si : `../workstreams/dev` concaténé donnerait `<pl>/workstreams/../workstreams/dev`,
# c'est-à-dire EXACTEMENT le compartiment `dev` qui existe. Sans validation de nom, le verdict
# basculerait en [gsd-engine] ; avec elle, il reste celui de la racine.
out="$(GSD_WORKSTREAM='../workstreams/dev' bash "$SCRIPT" --path "$D" 2>&1)"; rc=$?
escaped=0; case "$out" in *"[gsd-engine]"*|*"ws-milestone"*) escaped=1 ;; esac
grounded=0; case "$out" in *"[bootstrap]"*"feuille de route absente"*) grounded=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$escaped" -eq 0 ] && [ "$grounded" -eq 1 ]; then
  ok "27b traversée résolvable (../workstreams/dev) → rejetée, le compartiment réel n'est PAS atteint"
else
  ko "27b traversée résolvable rejetée" "rc=$rc escaped=$escaped out=[$out]"
fi

# === Cas 28 — Contrat de sortie : la suite entière ne produit QUE {0, 3, 64} =====================
codes_ok=1
D="$(mk_partitioned c28 dev)"
for e in "GSD_WORKSTREAM=dev" "GSD_WORKSTREAM=absent" "GSD_WORKSTREAM=../evil" "VF_BOOTSTRAP_WORKSTREAM=dev"; do
  r=$(env "$e" bash "$SCRIPT" --path "$D" >/dev/null 2>&1; echo $?)
  case "$r" in 0|3|64) : ;; *) codes_ok=0 ;; esac
done
if [ "$codes_ok" -eq 1 ]; then ok "28 contrat de sortie inchangé — aucun code hors {0, 3, 64}"; else ko "28 contrat de sortie {0,3,64}" "code hors contrat produit"; fi

# === Cas 29 — Lecture seule préservée sous workstream : aucune écriture dans le compartiment =====
D="$(mk_partitioned c29 dev)"
before="$(find "$D" | LC_ALL=C sort)"
GSD_WORKSTREAM=dev bash "$SCRIPT" --path "$D" >/dev/null 2>&1
after="$(find "$D" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "29 lecture seule sous workstream — empreinte find identique"; else ko "29 lecture seule sous workstream" "arbre modifié"; fi

# === Cas 22 — bash -n passe sur le script (syntaxe) =============================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "22 bash -n passe sur check-dev-bootstrap.sh"; else ko "22 bash -n passe sur check-dev-bootstrap.sh" "syntax error"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
