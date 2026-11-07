#!/usr/bin/env bash
# test-ci-suites-perimetre.sh — Suite de vérification de scripts/ci-suites-perimetre.sh (mission « CI sélective »,
# arbitrage Samuel, AskUserQuestion session principale, 2026-11-07 : « PR sélective, main complète » et
# « Module + dépendances citées »).
#
# Chaque cas travaille sur un dépôt git jetable sous mktemp (jamais le dépôt réel, sauf les deux cas « réels » qui
# ne lisent que lui) : trois modules factices + un conductor, une bibliothèque de test partagée, un script conductor
# appelé par un autre module et un autre qui ne l'est pas, un fichier au nom ambigu (VERSION), des docs. Le script de
# découverte scripts/ci-shard-suites.sh est copié depuis le disque au moment du test (seul `--all` est utilisé).
#
# Sortie exacte vérifiée : mode, suites jouées avec leur motif, nombre d'écartées, couverture de la découverte.
# MUTANTS : la suite applique elle-même, sur une copie du script, des mutations par sed et exige le ROUGE du cas qui
# vise la propriété (statut « ko-valeur » : le mutant s'exécute encore et rend une sortie bien formée, mais fausse).
# Un mutant qui ne change pas le fichier, ne passe plus `bash -n`, ou dont le cas visé était déjà rouge sur l'original,
# n'est pas compté comme tué.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REAL="$(cd "$HERE" && git rev-parse --show-toplevel)"
SCRIPT="$REAL/scripts/ci-suites-perimetre.sh"
SHARD="$REAL/scripts/ci-shard-suites.sh"

PASS=0; FAIL=0
ok() { echo "  OK $1"; PASS=$((PASS + 1)); }
ko() { echo "  KO $1"; echo "    attendu : $2"; echo "    obtenu  : $3"; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/vf-test-perimetre.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
REPO="$WORK/repo"
HORS="hors périmètre"

# --- Dépôt synthétique -----------------------------------------------------------------------------------------
G() { git -C "$REPO" "$@"; }
put() { mkdir -p "$REPO/$(dirname "$1")"; printf '%s\n' "$2" > "$REPO/$1"; }

mkdir -p "$REPO" && git init -q "$REPO" && G symbolic-ref HEAD refs/heads/main
G config user.name t; G config user.email t@t; G config commit.gpgsign false
mkdir -p "$REPO/scripts"
cp "$SCRIPT" "$REPO/scripts/ci-suites-perimetre.sh"
cp "$SHARD" "$REPO/scripts/ci-shard-suites.sh"
put VERSION 1.0.0
put README.md "readme racine"
put docs/x.md "doc"
put .planning/p.md "planning"
put scripts/tools.sh "echo outil"
put scripts/tests/test-misc.sh "echo misc"
put plugin/reference/r.txt "ref"
for m in alpha beta gamma conductor; do put "plugin/$m/module.json" "{\"name\":\"$m\"}"; put "plugin/$m/VERSION" "1.0.0"; done
put plugin/alpha/scripts/alpha.sh "echo alpha"
put plugin/alpha/scripts/alpha-compose.sh "echo compose"
put plugin/alpha/scripts/tests/lib-shared.sh "echo lib"
put plugin/alpha/scripts/tests/test-alpha-own.sh 'bash scripts/alpha.sh; . tests/lib-shared.sh; cat fixtures/fx.txt'
put plugin/alpha/scripts/tests/fixtures/fx.txt 'fixture'
put plugin/alpha/OWN.txt 'o'
put plugin/beta/OWN.txt 'o'
put plugin/beta/scripts/tests/test-beta-own-txt.sh 'cat OWN.txt'
put plugin/beta/scripts/tests/test-beta-sweep.sh 'for f in "$PLUGIN"/*/module.json; do cat "$f"; done'
put plugin/beta/scripts/tests/test-beta-sweep-agents.sh "find plugin/*/agents -name '*.md'"
put plugin/beta/scripts/tests/test-beta-hooks-dir.sh 'ls plugin/*/hooks/'
put plugin/beta/scripts/tests/test-beta-mod-seul.sh 'cat VERSION; ls alpha'
put plugin/alpha/scripts/tests/test-alpha-two.sh 'echo deux; cat fixtures/fx.txt'
put plugin/beta/scripts/beta.sh 'bash plugin/conductor/scripts/called.sh'
put plugin/beta/scripts/tests/test-beta-own.sh '. lib-shared.sh; bash test-alpha-two.sh'
put plugin/beta/scripts/tests/test-beta-dep-path.sh 'bash plugin/alpha/scripts/alpha.sh'
put plugin/beta/scripts/tests/test-beta-dep-compose.sh 'd=plugin/alpha/scripts; bash "$d/alpha-compose.sh"; cat note-unique.txt'
put plugin/beta/scripts/tests/test-beta-ambig.sh 'cat VERSION'
put plugin/beta/scripts/tests/test-beta-ambig-dir.sh 'cat VERSION; ls plugin/alpha'
put plugin/delta/module.json '{"name":"delta"}'
put plugin/delta/scripts/delta.sh 'echo delta'
put plugin/gamma/scripts/gamma.sh 'echo gamma'
put plugin/gamma/scripts/tests/test-gamma-own.sh 'echo gamma own'
put plugin/conductor/scripts/called.sh 'echo appelé'
put plugin/conductor/scripts/uncalled.sh 'echo seul'
put plugin/conductor/scripts/tests/test-conductor-own.sh 'bash called.sh; bash uncalled.sh; bash test-alpha-two.sh'
G add -A && G commit -q -m base && G tag base

# mkcase <branche> <commandes> : une branche issue de base portant un commit.
mkcase() { local b=$1; G checkout -q -B "$b" base && (cd "$REPO" && eval "$2") >/dev/null 2>&1 && G add -A && G commit -q -m "$b"; }
mkcase c-docs        'echo plus >> docs/x.md; echo plus >> .planning/p.md; echo plus >> README.md; mkdir -p .claude/agent-memory/x; echo m > .claude/agent-memory/x/m.md'
mkcase c-delta       'echo plus >> plugin/delta/scripts/delta.sh'
mkcase c-gamma       'echo plus >> plugin/gamma/scripts/gamma.sh'
mkcase c-docs-gamma  'echo c > docs/note-unique.txt; echo plus >> plugin/gamma/scripts/gamma.sh'
mkcase c-dep-path    'echo plus >> plugin/alpha/scripts/alpha.sh'
mkcase c-dep-compose 'echo plus >> plugin/alpha/scripts/alpha-compose.sh'
mkcase c-ambigu      'echo plus >> plugin/alpha/VERSION'
mkcase c-partage     'echo plus >> scripts/tools.sh'
mkcase c-lib         'echo plus >> plugin/alpha/scripts/tests/lib-shared.sh'
mkcase c-cond-appele 'echo plus >> plugin/conductor/scripts/called.sh'
mkcase c-cond-seul   'echo plus >> plugin/conductor/scripts/uncalled.sh'
mkcase c-renom       'git mv plugin/gamma/scripts/gamma.sh plugin/alpha/scripts/gamma-moved.sh'
mkcase c-hors-v      'echo plus >> VERSION'
mkcase c-hors-ref    'echo plus >> plugin/reference/r.txt'
mkcase c-md-plugin   'echo plus > plugin/alpha/NOTES.md'
mkcase c-github-md   'mkdir -p .github; echo x > .github/x.md'
mkcase c-glob-module 'echo plus >> plugin/gamma/module.json'
mkcase c-glob-agents 'mkdir -p plugin/alpha/agents; echo x > plugin/alpha/agents/vf.md'
mkcase c-hooks-dir   'mkdir -p plugin/alpha/hooks; echo x > plugin/alpha/hooks/h.json'
mkcase c-supprime    'git rm -q plugin/alpha/OWN.txt'
mkcase c-fixture     'echo plus >> plugin/alpha/scripts/tests/fixtures/fx.txt'
mkcase c-suite-citee 'echo plus >> plugin/alpha/scripts/tests/test-alpha-two.sh'
G checkout -q base

# Découverte de référence (jeu de suites du dépôt synthétique), triée.
SUITES_REF="$WORK/suites.ref"
(cd "$REPO" && bash scripts/ci-shard-suites.sh --all) > "$SUITES_REF"
NS=$(wc -l < "$SUITES_REF" | tr -d ' ')

A1=plugin/alpha/scripts/tests/test-alpha-own.sh;      A2=plugin/alpha/scripts/tests/test-alpha-two.sh
B1=plugin/beta/scripts/tests/test-beta-ambig-dir.sh;  B2=plugin/beta/scripts/tests/test-beta-ambig.sh
B3=plugin/beta/scripts/tests/test-beta-dep-compose.sh; B4=plugin/beta/scripts/tests/test-beta-dep-path.sh
B5=plugin/beta/scripts/tests/test-beta-own.sh
B6=plugin/beta/scripts/tests/test-beta-mod-seul.sh;   B7=plugin/beta/scripts/tests/test-beta-own-txt.sh
B10=plugin/beta/scripts/tests/test-beta-hooks-dir.sh
B8=plugin/beta/scripts/tests/test-beta-sweep.sh;       B9=plugin/beta/scripts/tests/test-beta-sweep-agents.sh
C1=plugin/conductor/scripts/tests/test-conductor-own.sh
G1=plugin/gamma/scripts/tests/test-gamma-own.sh
S1=scripts/tests/test-misc.sh

E() { printf '%s|%s\n' "$1" "$2"; }
TOUS() { local s; for s in $A1 $A2 $B1 $B2 $B3 $B4 $B5 $B6 $B7 $B8 $B9 $B10 $C1 $G1 $S1; do E "$s" "$1"; done; }

# --- Exécution et vérification ---------------------------------------------------------------------------------
SCRIPT_UNDER="$SCRIPT"
OUT=""; RC=0
CASE_STATUS=""; CASE_ATT=""; CASE_OBT=""
exec_script() { OUT=$(cd "$REPO" && bash "$SCRIPT_UNDER" "$@" 2>/dev/null); RC=$?; }

# verifie_perimetre <tete> <mode> <jouées attendues "chemin|motif" par ligne>
verifie_perimetre() {
  local head=$1 mode=$2 exp=$3 first nj ne cov
  G checkout -q "$head"
  exec_script base "$head"
  first=$(printf '%s\n' "$OUT" | head -1)
  CASE_ATT="rc=0 mode=$mode
$(printf '%s\n' "$exp" | sed '/^$/d' | LC_ALL=C sort)
ecartees=$((NS - $(printf '%s\n' "$exp" | sed '/^$/d' | wc -l | tr -d ' ')))"
  case "$first" in
    "# mode="*) ;;
    *) CASE_STATUS=ko-forme; CASE_OBT="rc=$RC, sortie sans en-tête '# mode=' : $first"; return ;;
  esac
  [ "$RC" -eq 0 ] || { CASE_STATUS=ko-forme; CASE_OBT="rc=$RC"; return; }
  cov=ok
  printf '%s\n' "$OUT" | tail -n +2 | cut -f2 | cmp -s - "$SUITES_REF" || cov=COUVERTURE-OU-ORDRE-KO
  printf '%s\n' "$OUT" | tail -n +2 | awk -F'\t' -v h="$HORS" '$1 == "ecartee" && $3 != h { bad = 1 } END { exit bad }' || cov=MOTIF-ECARTEE-KO
  nj=$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "jouee" { n++ } END { print n + 0 }')
  ne=$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "ecartee" { n++ } END { print n + 0 }')
  CASE_OBT="rc=$RC mode=$(printf '%s' "${first#\# mode=}" | cut -f1)
$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "jouee" { print $2 "|" $3 }')
ecartees=$ne"
  [ "$cov" = ok ] || CASE_OBT="$CASE_OBT
$cov"
  if [ "$CASE_OBT" = "$CASE_ATT" ]; then CASE_STATUS=ok; else CASE_STATUS=ko-valeur; fi
  : "$nj"
}
# verifie_brut <rc attendu> <sortie attendue> <tete du checkout> -- args…
verifie_brut() {
  local rc=$1 exp=$2 head=$3; shift 4
  G checkout -q "$head"
  exec_script "$@"
  CASE_ATT="rc=$rc
$exp"; CASE_OBT="rc=$RC
$OUT"
  if [ "$CASE_OBT" = "$CASE_ATT" ]; then CASE_STATUS=ok; else CASE_STATUS=ko-valeur; fi
  # Une sortie vide avec un rc inattendu n'est pas « bien formée » pour un mutant qui aurait cessé de tourner.
}

NOMS="hooks-dir github-md glob-module glob-agents supprime fixture suite-citee docs vide delta gamma docs-gamma dep-path dep-compose ambigu partage lib cond-appele cond-seul renom hors-version hors-reference md-plugin tout liste-selection liste-tout sha-inconnu head-inconnu usage-vide usage-un usage-tout usage-option usage-trop"
run_case() {
  case "$1" in
    github-md) verifie_perimetre c-github-md tout "$(TOUS 'tout — hors carte .github/x.md')" ;;
    glob-module) verifie_perimetre c-glob-module selection "$(E $G1 'module gamma — plugin/gamma/module.json'; E $B8 'citée — plugin/gamma/module.json (motif plugin/*/module.json)')" ;;
    glob-agents) verifie_perimetre c-glob-agents selection "$(E $A1 'module alpha — plugin/alpha/agents/vf.md'; E $A2 'module alpha — plugin/alpha/agents/vf.md'; E $B9 'citée — plugin/alpha/agents/vf.md (motif plugin/*/agents)')" ;;
    hooks-dir) verifie_perimetre c-hooks-dir selection "$(E $A1 'module alpha — plugin/alpha/hooks/h.json'; E $A2 'module alpha — plugin/alpha/hooks/h.json'; E $B10 'citée — plugin/alpha/hooks/h.json (motif plugin/*/hooks/)')" ;;
    supprime) verifie_perimetre c-supprime selection "$(E $A1 'module alpha — plugin/alpha/OWN.txt'; E $A2 'module alpha — plugin/alpha/OWN.txt')" ;;
    fixture) verifie_perimetre c-fixture selection "$(E $A1 'module alpha — plugin/alpha/scripts/tests/fixtures/fx.txt'; E $A2 'module alpha — plugin/alpha/scripts/tests/fixtures/fx.txt')" ;;
    suite-citee) verifie_perimetre c-suite-citee selection "$(E $A1 'module alpha — plugin/alpha/scripts/tests/test-alpha-two.sh'; E $A2 'module alpha — plugin/alpha/scripts/tests/test-alpha-two.sh'; E $B5 'citée — plugin/alpha/scripts/tests/test-alpha-two.sh'; E $C1 'citée — plugin/alpha/scripts/tests/test-alpha-two.sh')" ;;
    docs) verifie_perimetre c-docs docs-seules "" ;;
    vide) verifie_perimetre base vide "" ;;
    delta) verifie_perimetre c-delta vide "" ;;
    gamma) verifie_perimetre c-gamma selection "$(E $G1 'module gamma — plugin/gamma/scripts/gamma.sh')" ;;
    docs-gamma) verifie_perimetre c-docs-gamma selection "$(E $G1 'module gamma — plugin/gamma/scripts/gamma.sh')" ;;
    dep-path) verifie_perimetre c-dep-path selection "$(E $A1 'module alpha — plugin/alpha/scripts/alpha.sh'; E $A2 'module alpha — plugin/alpha/scripts/alpha.sh'; E $B4 'citée — plugin/alpha/scripts/alpha.sh')" ;;
    dep-compose) verifie_perimetre c-dep-compose selection "$(E $A1 'module alpha — plugin/alpha/scripts/alpha-compose.sh'; E $A2 'module alpha — plugin/alpha/scripts/alpha-compose.sh'; E $B3 'citée — plugin/alpha/scripts/alpha-compose.sh')" ;;
    ambigu) verifie_perimetre c-ambigu selection "$(E $A1 'module alpha — plugin/alpha/VERSION'; E $A2 'module alpha — plugin/alpha/VERSION'; E $B1 'citée — plugin/alpha/VERSION'; E $B6 'citée — plugin/alpha/VERSION')" ;;
    partage) verifie_perimetre c-partage tout "$(TOUS 'tout — fichier partagé scripts/tools.sh')" ;;
    lib) verifie_perimetre c-lib tout "$(TOUS 'tout — fichier partagé plugin/alpha/scripts/tests/lib-shared.sh')" ;;
    cond-appele) verifie_perimetre c-cond-appele tout "$(TOUS 'tout — fichier partagé plugin/conductor/scripts/called.sh')" ;;
    cond-seul) verifie_perimetre c-cond-seul selection "$(E $C1 'module conductor — plugin/conductor/scripts/uncalled.sh')" ;;
    renom) verifie_perimetre c-renom selection "$(E $A1 'module alpha — plugin/alpha/scripts/gamma-moved.sh'; E $A2 'module alpha — plugin/alpha/scripts/gamma-moved.sh'; E $G1 'module gamma — plugin/gamma/scripts/gamma.sh')" ;;
    hors-version) verifie_perimetre c-hors-v tout "$(TOUS 'tout — hors carte VERSION')" ;;
    hors-reference) verifie_perimetre c-hors-ref tout "$(TOUS 'tout — hors carte plugin/reference/r.txt')" ;;
    md-plugin) verifie_perimetre c-md-plugin selection "$(E $A1 'module alpha — plugin/alpha/NOTES.md'; E $A2 'module alpha — plugin/alpha/NOTES.md')" ;;
    tout) # --tout n'a pas de diff
          G checkout -q base; exec_script --tout "label ci: complet"
          CASE_ATT="rc=0 mode=tout
$(TOUS 'tout — label ci: complet' | LC_ALL=C sort)
ecartees=0"
          CASE_OBT="rc=$RC mode=$(printf '%s\n' "$OUT" | head -1 | sed 's/^# mode=//' | cut -f1)
$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "jouee" { print $2 "|" $3 }')
ecartees=$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "ecartee" { n++ } END { print n + 0 }')"
          if [ "$CASE_OBT" = "$CASE_ATT" ]; then CASE_STATUS=ok; else CASE_STATUS=ko-valeur; fi ;;
    liste-selection) verifie_brut 0 "$G1" c-gamma -- --liste base c-gamma ;;
    liste-tout) verifie_brut 0 "$(cat "$SUITES_REF")" base -- --liste --tout x ;;
    sha-inconnu) verifie_brut 2 "" base -- base 0000000000000000000000000000000000000000 ;;
    head-inconnu) verifie_brut 2 "" base -- inexistant base ;;
    usage-vide) verifie_brut 64 "" base -- ;;
    usage-un) verifie_brut 64 "" base -- base ;;
    usage-tout) verifie_brut 64 "" base -- --tout ;;
    usage-option) verifie_brut 64 "" base -- --inconnue base base ;;
    usage-trop) verifie_brut 64 "" base -- base base base ;;
  esac
}

echo "== Cas sur le dépôt synthétique ($NS suites) =="
for nom in $NOMS; do
  run_case "$nom"
  echo "$nom $CASE_STATUS" >> "$WORK/orig-status"
  if [ "$CASE_STATUS" = ok ]; then ok "cas $nom"; else ko "cas $nom" "$CASE_ATT" "$CASE_OBT"; fi
done

# --- Cas sur le dépôt réel (lecture seule) ---------------------------------------------------------------------
echo "== Cas sur le dépôt réel =="
(cd "$REAL" && bash scripts/ci-suites-perimetre.sh --tout x --liste) > "$WORK/real.tout" 2>/dev/null
(cd "$REAL" && bash scripts/ci-shard-suites.sh --all) > "$WORK/real.all"
if [ -s "$WORK/real.all" ] && cmp -s "$WORK/real.tout" "$WORK/real.all"; then
  ok "réel : --tout x --liste égal à ci-shard-suites.sh --all ($(wc -l < "$WORK/real.all" | tr -d ' ') suites)"
else
  ko "réel : --tout x --liste égal à ci-shard-suites.sh --all" "$(head -3 "$WORK/real.all")" "$(head -3 "$WORK/real.tout")"
fi

# Un commit synthétique qui touche un fichier réel, écrit dans un répertoire d'objets jetable (alternates sur le dépôt réel) :
# ni ref ni objet n'est ajouté au dépôt réel.
COMMON="$(cd "$REAL" && cd "$(git rev-parse --git-common-dir)" && pwd)"
mkdir -p "$WORK/objs"
# reel_commit <chemin> : imprime le sha d'un commit enfant de HEAD où ce fichier a un autre contenu.
reel_commit() {
  (cd "$REAL" && export GIT_OBJECT_DIRECTORY="$WORK/objs" GIT_ALTERNATE_OBJECT_DIRECTORIES="$COMMON/objects" GIT_INDEX_FILE="$WORK/idx" \
    GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
   git read-tree HEAD && blob=$(printf 'x\n' | git hash-object -w --stdin) \
   && git update-index --add --cacheinfo "100644,$blob,$1" && tree=$(git write-tree) && git commit-tree "$tree" -p HEAD -m synth)
}
reel_perimetre() { (cd "$REAL" && GIT_OBJECT_DIRECTORY="$WORK/objs" GIT_ALTERNATE_OBJECT_DIRECTORIES="$COMMON/objects" bash scripts/ci-suites-perimetre.sh "$@" 2>/dev/null); }
NREEL=$(wc -l < "$WORK/real.all" | tr -d ' ')
CS=plugin/cockpit/scripts/tests/chrome-session.mjs
CSFIX=$(reel_commit "$CS")
if [ -z "$CSFIX" ]; then
  ko "réel : commit synthétique sur chrome-session.mjs" "un sha" "vide"
else
  REEL_OUT=$(reel_perimetre HEAD "$CSFIX")
  mode=$(printf '%s\n' "$REEL_OUT" | head -1 | cut -f1)
  njoue=$(printf '%s\n' "$REEL_OUT" | awk -F'\t' '$1 == "jouee"' | wc -l | tr -d ' ')
  motif=$(printf '%s\n' "$REEL_OUT" | awk -F'\t' '$1 == "jouee" { print $3; exit }')
  if [ "$mode" = "# mode=tout" ] && [ "$njoue" = "$NREEL" ] && [ "$motif" = "tout — fichier partagé $CS" ]; then
    ok "réel : chrome-session.mjs est une bibliothèque de test partagée (→ tout, $njoue suites)"
  else
    ko "réel : chrome-session.mjs est une bibliothèque de test partagée" "mode=tout, toutes les suites, motif 'tout — fichier partagé $CS'" "$mode, $njoue suites, motif '$motif'"
  fi
fi

# reel_joue <chemin touché> <suite>… : chaque suite doit être jouée (balayeuses par motif de chemin).
reel_joue() {
  local f=$1 sha liste miss="" s; shift
  sha=$(reel_commit "$f")
  [ -n "$sha" ] || { ko "réel : commit synthétique sur $f" "un sha" "vide"; return; }
  liste=$(reel_perimetre --liste HEAD "$sha")
  for s in "$@"; do printf '%s\n' "$liste" | grep -qxF -e "$s" || miss="$miss $s"; done
  if [ -z "$miss" ]; then ok "réel : $f joue $* (périmètre de $(printf '%s\n' "$liste" | wc -l | tr -d ' ') suites)"
  else ko "réel : $f doit jouer $*" "toutes jouées" "manquantes :$miss"; fi
}
reel_joue plugin/dev-orchestrator/agents/vf-dev-manager.md plugin/_internal/tests/test-roles-e2e.sh plugin/conductor/scripts/tests/test-check-agents.sh
reel_joue plugin/conductor/hooks/hooks.json plugin/cockpit/scripts/tests/test-cockpit-signal-mod.sh
reel_joue plugin/software-architecture/module.json plugin/_internal/tests/test-module-roles.sh
# Limite connue (rapportée, jamais compensée par une liste en dur) : test-resolve-preset.sh ne porte AUCUN motif de chemin
# (il pose VF_MODULES_ROOT=$REPO_ROOT puis laisse resolve-preset.sh lire les module.json) ; la règle « citée par motif » ne
# peut donc pas le retrouver depuis module.json.

# --- Mutants --------------------------------------------------------------------------------------------------
echo "== Mutants =="
# muter <id> <expression sed> <cas visés> : le mutant doit changer le fichier, rester valide, et rougir CHAQUE cas visé
# avec le statut ko-valeur (sortie bien formée mais fausse) alors que l'original est vert sur ce cas.
muter() {
  local id=$1 expr=$2 cas=$3 mut="$WORK/mut-$1.sh" c st orig bad="" trace=""
  sed -e "$expr" "$SCRIPT" > "$mut"
  if cmp -s "$mut" "$SCRIPT"; then ko "MUT-$id non opposable" "le sed modifie le script" "fichier identique"; return; fi
  if ! bash -n "$mut" 2>/dev/null; then ko "MUT-$id invalide" "bash -n OK" "bash -n KO"; return; fi
  SCRIPT_UNDER="$mut"
  for c in $cas; do
    orig=$(awk -v c="$c" '$1 == c { print $2 }' "$WORK/orig-status")
    run_case "$c"; st=$CASE_STATUS
    if [ "$orig" != ok ] || [ "$st" != ko-valeur ]; then bad="$bad $c(original=$orig mutant=$st)"; fi
    [ -n "$trace" ] || trace="cas $c — attendu seul : $(printf '%s\n' "$CASE_ATT" | grep -vxF -e "$(printf '%s\n' "$CASE_OBT")" | head -1 | cut -c1-120) | obtenu seul : $(printf '%s\n' "$CASE_OBT" | grep -vxF -e "$(printf '%s\n' "$CASE_ATT")" | head -1 | cut -c1-120)"
  done
  SCRIPT_UNDER="$SCRIPT"
  if [ -z "$bad" ]; then ok "MUT-$id TUÉ — $trace"; else ko "MUT-$id NON TUÉ pour la bonne raison" "cas visés ($cas) rouges en ko-valeur" "$bad"; fi
}

muter 1  's#^    scripts/\*|\.github/workflows/ci\.yml) echo partage ;;#    scripts/*|.github/workflows/ci.yml) echo doc ;;#' "partage"
muter 2  's#^done < <(awk .*#done < /dev/null#' "dep-path dep-compose"
muter 3  's#^      cite_files "\$name"$#      true#' "dep-compose"
muter 4a 's#\[ "\$nondoc" -eq 0 \]#[ "$nondoc" -eq 99999 ]#' "docs"
muter 4b 's#^done < <(awk .*classes")$#done < "$T/classes"#' "docs-gamma"
muter 11 's#\[ "\$nj" -eq 0 \]#[ "$nj" -eq 99999 ]#' "delta"
muter 12 's#^  grep -qxF -e "\$2" "\$T/tracked" || c=\$((c + 1))#  true#' "supprime"
muter 13 's#\*/fixtures/\*) ;;#*/fixturesX/*) ;;#' "fixture"
muter 14 's#test-\*\.sh) ;;#test-ZZ) ;;#' "suite-citee"
muter 15 's#^done < "\$T/globs"#done < /dev/null#' "glob-module glob-agents"
muter 16 's#^    \*/\*\.md) echo hors ;;#    */*.md) echo doc ;;#' "github-md"
muter 17 's#cite_files "\${mod%%/\*}" ;; esac#true ;; esac#' "ambigu"
muter 18 's#^      \*/) m="\$pat\*" ;;#      */) m="$pat" ;;#' "hooks-dir"
muter 19 's#docs/\*|\.planning/\*|\.claude/agent-memory/\*) echo doc#docs/*|.planning/*) echo doc#' "docs"
muter 5  's#(p in f)#(p in zzz)#' "gamma cond-seul"
muter 6  's# --name-only --no-renames # --name-only #' "renom"
muter 7  's#if conductor_appele_ailleurs "\$name"; then#if false; then#' "cond-appele"
muter 8  's#awk -v m="\$1" '"'"'{ printf#awk -v m="$1" '"'"'NR > 1 { printf#' "partage tout"
muter 9  's#if ambigu "\$name" "\$f"; then#if false; then#' "ambigu"
muter 10 's#-ge 2 \]; then echo partage#-ge 200 ]; then echo partage#' "lib"

echo
echo "== test-ci-suites-perimetre : bilan =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
