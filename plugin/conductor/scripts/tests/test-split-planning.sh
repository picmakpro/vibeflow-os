#!/usr/bin/env bash
# test-split-planning.sh — Suite de vérification de split-planning.sh, le geste de partition
# (Phase 41.2, plan 41.2-03, exigences WSCH-02 et WSCH-03, P412-D-01, QUAL-01).
#
# Cas S1-S12, chacun sur sa propre fixture `mktemp -d` (jamais dans le dépôt). Une ligne
# « ✓ <ID> — … » ou « ✗ <ID> — … [détail] » par cas ; rc 1 si un cas est rouge.
#
# Cette suite exige le VRAI moteur (`@opengsd/gsd-core`) : le job `tests` de la CI l'installe, le job
# `gates` non. Le moteur est résolu par la MÊME cascade que le geste (GSD_TOOLS, PATH, ~/.claude).
#
# La fabrique `mk_new_project` (« produit de gsd-new-project », commité) est écrite comme une fonction
# réutilisable : le plan 41.2-04 (preuve d'usage) la reprend. Surcharge de test : SPLIT_TARGET pointe un
# MUTANT du geste (copie placée à côté de check-planning-not-inflight.sh et workstream-policy.sh).
#
# Aucun `diff` (proxifié, menteur sur ce poste) : `cmp -s` et empreintes `cksum`.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${SPLIT_TARGET:-$(cd "$HERE/.." && pwd)/split-planning.sh}"
BASH_BIN="$(command -v bash)"

PASS=0; FAIL=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
N=0

emit() { # <ID> <0 = ok | 1 = ko> <description> <détail>
  if [ "$2" -eq 0 ]; then echo "  ✓ $1 — $3"; PASS=$((PASS+1))
  else echo "  ✗ $1 — $3 [$4]"; FAIL=$((FAIL+1)); fi
}

# --- Moteur : même cascade que le geste ---------------------------------------------------------
GT=""
if [ -n "${GSD_TOOLS:-}" ] && [ -f "$GSD_TOOLS" ]; then GT="$GSD_TOOLS"
elif command -v gsd-tools >/dev/null 2>&1; then GT="$(command -v gsd-tools)"
elif [ -f "${CLAUDE_CONFIG_DIR:-${HOME:-/nonexistent}/.claude}/gsd-core/bin/gsd-tools.cjs" ]; then
  GT="${CLAUDE_CONFIG_DIR:-${HOME:-/nonexistent}/.claude}/gsd-core/bin/gsd-tools.cjs"
fi
# Moteur absent => `ko` (rc de suite 1), JAMAIS `skip` (précédent test-check-gsd-config.sh, cas 20/26) :
# les cas qui exigent le vrai moteur (S1-S5, S7-S10, W1-W12, mutations (i)-(iv)) sortent ko ; S6, S11
# (environnement vidé, sans moteur par construction) et S12 (statique) se jouent quand même.
HAVE_ENG=0; ENG=()
if [ -n "$GT" ]; then
  HAVE_ENG=1
  case "$GT" in *.cjs) ENG=(node "$GT") ;; *) ENG=("$GT") ;; esac
fi
eng() { # <cwd> <args…> : appel moteur de la suite, environnement neutralisé
  local c="$1"; shift
  env -u GSD_WORKSTREAM "${ENG[@]}" --cwd "$c" "$@"
}

# --- Outils : PATH réduit de liens (avec jq), pour S6 -------------------------------------------
mkdir -p "$TMP/bin-jq"
for t in awk sed tr grep cat ls find sort head tail cut uniq wc mktemp date basename dirname env \
         node readlink rm mkdir cmp expr tee xargs uname id cksum; do
  p="$(command -v "$t" 2>/dev/null || true)"; [ -n "$p" ] && ln -s "$p" "$TMP/bin-jq/$t"
done
JQ_REAL="$(command -v jq 2>/dev/null || true)"; [ -n "$JQ_REAL" ] && ln -s "$JQ_REAL" "$TMP/bin-jq/jq"
EMPTYHOME="$TMP/home-vide"; mkdir -p "$EMPTYHOME"

# --- Exécution du geste : RC / OUT (stdout) / ERR (stderr) ---------------------------------------
# sp <cwd> [<arg d'env>...] -- <args du geste>   (environnement TOUJOURS explicite)
sp() {
  local cwd="$1"; shift
  local envs=()
  while [ "$1" != "--" ]; do envs+=("$1"); shift; done
  shift
  OUT="$( cd "$cwd" && env -u GSD_WORKSTREAM ${envs[@]+"${envs[@]}"} "$BASH_BIN" "$SCRIPT" "$@" 2>"$TMP/err" )"; RC=$?
  ERR="$(cat "$TMP/err" 2>/dev/null)"
}

empreinte() { # contenu ET arbre
  find "$1" -not -path '*/.git' -not -path '*/.git/*' | LC_ALL=C sort
  find "$1" -type f -not -path '*/.git/*' -exec cksum {} + | LC_ALL=C sort
}

# expect <ID> <description> <rc attendu> <fragment de stderr | -> <fragment de stdout | ->
expect() {
  local ok=0 why=""
  [ "$RC" = "$3" ] || { ok=1; why="rc=$RC attendu $3"; }
  if [ "$4" != "-" ] && ! printf '%s' "$ERR" | grep -qF -- "$4"; then ok=1; why="$why stderr sans [$4] : [$ERR]"; fi
  if [ "$5" != "-" ] && [ "$OUT" != "$5" ]; then ok=1; why="$why stdout=[$OUT] attendu [$5]"; fi
  emit "$1" "$ok" "$2" "$why"
}

# --- Fabrique : « produit de gsd-new-project », commité (réutilisable, plan 41.2-04) ------------
# mk_new_project <nom-de-dossier> [ligne Phase:] [corps frontmatter additionnel] -> chemin
mk_new_project() {
  N=$((N+1))
  local d="$TMP/fx$N/$1" ph="${2:-Phase: 1 of 3 (Fondations)}" extra="${3:-}"
  mkdir -p "$d/.planning/phases"
  {
    printf -- "---\ngsd_state_version: '1.0'\n"
    [ -n "$extra" ] && printf '%s\n' "$extra"
    printf 'status: planning\nprogress:\n  total_phases: 0\n  completed_phases: 0\n  total_plans: 0\n  completed_plans: 0\n  percent: 0\n---\n\n'
    printf '# Project State\n\n## Project Reference\n\nSee: .planning/PROJECT.md\n\n## Current Position\n\n%s\n' "$ph"
    printf 'Plan: 0 of 0 in current phase\nStatus: Ready to plan\nLast activity: 2026-10-02 — init\n\nProgress: [░░░░░░░░░░] 0%%\n'
  } > "$d/.planning/STATE.md"
  cat > "$d/.planning/ROADMAP.md" <<'R'
# Roadmap

## Phases

- [ ] **Phase 1: Fondations** - base
- [ ] **Phase 2: Coeur** - coeur
- [ ] **Phase 3: Finitions** - fin

### Phase 1: Fondations
**Goal**: base
**Depends on**: Nothing
**Plans**: 0 plans

### Phase 2: Coeur
**Goal**: coeur
**Depends on**: Phase 1
**Plans**: 0 plans

### Phase 3: Finitions
**Goal**: fin
**Depends on**: Phase 2
**Plans**: 0 plans
R
  printf '# Mon Projet\n' > "$d/.planning/PROJECT.md"
  printf '# Requirements\n' > "$d/.planning/REQUIREMENTS.md"
  printf '{}\n' > "$d/.planning/config.json"
  : > "$d/.planning/phases/.gitkeep"
  ( cd "$d" && git init -q . && git add -A \
    && git -c user.name=fx -c user.email=fx@vibeflow.invalid -c commit.gpgsign=false commit -q -m "docs: create roadmap (3 phases)" ) >/dev/null 2>&1
  printf '%s' "$d"
}

fm() { # <STATE.md> <clé> : valeur de la clé dans le frontmatter
  awk -v k="$2" '/^---[[:space:]]*$/{n++; if(n==1) next; if(n==2) exit} n==1 && $0 ~ "^"k":"{sub("^"k":[[:space:]]*",""); print; exit}' "$1"
}
nphase() { grep -c '^Phase:' "$1" 2>/dev/null; }

# =================================================================================================
echo "== split-planning (cas S1-S12) =="

if [ "$HAVE_ENG" = 1 ]; then

# --- S1 : lab neuf plat -----------------------------------------------------------------------
D="$(mk_new_project s1)"
sp "$TMP" -- --path "$D" --name "Mon Projet"
expect S1 "lab neuf plat : un sujet, séquence d'état jouée" 0 "-" '{"mode":"plat","subject":"mon-projet","state":"complete"}'
W="$D/.planning/workstreams/mon-projet/STATE.md"
bad=""
[ -n "$(fm "$W" milestone)" ] && [ "$(fm "$W" milestone)" = "v1.0" ] || bad="$bad milestone=[$(fm "$W" milestone)]"
case "$(fm "$W" current_phase)" in ''|*[!0-9]*) bad="$bad current_phase=[$(fm "$W" current_phase)]" ;; esac
[ "$(nphase "$W")" = "1" ] || bad="$bad Phase:x$(nphase "$W")"
[ -n "$(fm "$W" gsd_state_version)" ] || bad="$bad gsd_state_version"
[ -n "$(fm "$W" status)" ] || bad="$bad status"
[ ! -e "$D/.planning/ROADMAP.md" ] && [ ! -e "$D/.planning/STATE.md" ] || bad="$bad racine-non-videe"
emit S1 "$([ -z "$bad" ] && echo 0 || echo 1)" "STATE du sujet : milestone v1.0, current_phase numérique, une ligne ^Phase:, plus de ROADMAP/STATE racine" "$bad"
S1OUT="$OUT"

# --- S2 : relance du même nom --------------------------------------------------------------------
E0="$(empreinte "$D/.planning")"
sp "$TMP" -- --path "$D" --name "Mon Projet"
expect S2 "relance du même nom : REFUSÉ « existe déjà »" 1 "existe déjà" "-"
[ "$E0" = "$(empreinte "$D/.planning")" ] && emit S2 0 "S2 empreinte inchangée après la relance" "" || emit S2 1 "S2 empreinte inchangée après la relance" "empreinte modifiée"

# --- S3 : second sujet (partitionné) ---------------------------------------------------------------
sp "$TMP" -- --path "$D" --name second
expect S3 "second sujet : mode partitionné, état non initialisé" 0 "-" '{"mode":"partitionne","subject":"second","state":"non-initialise"}'
W2="$D/.planning/workstreams/second/STATE.md"
bad=""
[ -f "$W2" ] || bad="$bad STATE-absent"
[ -z "$(fm "$W2" milestone)" ] && [ -z "$(fm "$W2" current_phase)" ] || bad="$bad séquence-jouée-à-tort"
emit S3 "$([ -z "$bad" ] && echo 0 || echo 1)" "STATE du second sujet réduit aux clés du moteur (ni milestone ni current_phase)" "$bad"
S3OUT="$OUT"

# --- S4 : phase en vol -----------------------------------------------------------------------------
D="$(mk_new_project s4)"; mkdir -p "$D/.planning/phases/01-fondations"; printf '# p\n' > "$D/.planning/phases/01-fondations/01-01-PLAN.md"
E0="$(empreinte "$D")"
sp "$TMP" -- --path "$D" --name vol
bad=""; [ ! -d "$D/.planning/workstreams" ] || bad="workstreams/ créé"
[ "$E0" = "$(empreinte "$D")" ] || bad="$bad empreinte modifiée"
expect S4 "phase en vol (PLAN sans SUMMARY) : REFUSÉ (ADR-069), rien d'écrit" 1 "REFUSÉ (ADR-069)" "" 
emit S4 "$([ -z "$bad" ] && echo 0 || echo 1)" "S4 empreinte et contenus inchangés, aucun workstreams/" "$bad"

# --- S5 : lab démarré à état complet ---------------------------------------------------------------
D="$(mk_new_project s5 "Phase: 2 of 3 (Coeur)" "milestone: v1.0
current_phase: 2")"
cp "$D/.planning/STATE.md" "$TMP/s5.avant"
sp "$TMP" -- --path "$D" --name demarre
expect S5 "état déjà complet : aucune séquence rejouée, deja-complet" 0 "-" '{"mode":"plat","subject":"demarre","state":"deja-complet"}'
cmp -s "$TMP/s5.avant" "$D/.planning/workstreams/demarre/STATE.md" \
  && emit S5 0 "S5 STATE migré identique octet pour octet au STATE racine d'avant (cmp)" "" \
  || emit S5 1 "S5 STATE migré identique octet pour octet au STATE racine d'avant (cmp)" "STATE modifié"
S5OUT="$OUT"

fi # HAVE_ENG (S1-S5)

# --- S6 : moteur introuvable -----------------------------------------------------------------------
D="$(mk_new_project s6)"; E0="$(empreinte "$D")"
sp "$TMP" -u CLAUDE_CONFIG_DIR -u GSD_TOOLS "PATH=$TMP/bin-jq" "HOME=$EMPTYHOME" -- --path "$D" --name x
expect S6 "moteur introuvable : NON VÉRIFIABLE, aucune écriture" 2 "NON VÉRIFIABLE" ""
[ "$E0" = "$(empreinte "$D")" ] && emit S6 0 "S6 empreinte inchangée" "" || emit S6 1 "S6 empreinte inchangée" "empreinte modifiée"

if [ "$HAVE_ENG" = 1 ]; then

# --- S7 : Phase: non numérique ----------------------------------------------------------------------
D="$(mk_new_project s7 "Phase: Not started (defining requirements)")"; E0="$(empreinte "$D")"
sp "$TMP" -- --path "$D" --name nonnum
bad=""; [ ! -d "$D/.planning/workstreams" ] || bad="workstreams/ créé"
[ "$E0" = "$(empreinte "$D")" ] || bad="$bad empreinte modifiée"
expect S7 "ligne Phase: non numérique : NON VÉRIFIABLE avant tout appel écrivant" 2 "NON VÉRIFIABLE" ""
emit S7 "$([ -z "$bad" ] && echo 0 || echo 1)" "S7 empreinte inchangée, aucun workstreams/" "$bad"

# --- S8 : validation de --name ---------------------------------------------------------------------
D="$(mk_new_project s8)"; E0="$(empreinte "$D")"; bad=""
long="$(printf 'a%.0s' $(seq 1 65))"
for nm in "" "-x" ".x" "a/b" "$long" 'a$b' 'a;b' 'a"b' "a..b" " lead"; do
  sp "$TMP" -- --path "$D" --name "$nm"
  [ "$RC" = "64" ] || bad="$bad [name=<$nm> rc=$RC]"
done
sp "$TMP" -- --path "$D"; [ "$RC" = "64" ] || bad="$bad [sans --name rc=$RC]"
[ "$E0" = "$(empreinte "$D")" ] || bad="$bad empreinte modifiée"
emit S8 "$([ -z "$bad" ] && echo 0 || echo 1)" "noms invalides (vide, -, ., /, 65 car., \$ ; \" .., espace de tête) : 64 sans écriture" "$bad"
sp "$TMP" -- --path "$D" --name "Bad.Name"
expect S8 "--name \"Bad.Name\" : sujet « bad-name » (nom relu du moteur)" 0 "-" '{"mode":"plat","subject":"bad-name","state":"complete"}'

# --- S9 : --milestone ---------------------------------------------------------------------------------
D="$(mk_new_project s9)"
sp "$TMP" -- --path "$D" --name m --milestone v2.0
expect S9 "--milestone v2.0 : accepté" 0 "-" '{"mode":"plat","subject":"m","state":"complete"}'
[ "$(fm "$D/.planning/workstreams/m/STATE.md" milestone)" = "v2.0" ] \
  && emit S9 0 "S9 milestone: v2.0 dans le STATE du sujet" "" \
  || emit S9 1 "S9 milestone: v2.0 dans le STATE du sujet" "milestone=[$(fm "$D/.planning/workstreams/m/STATE.md" milestone)]"
D="$(mk_new_project s9b)"; E0="$(empreinte "$D")"; bad=""
sp "$TMP" -- --path "$D" --name m --milestone 'v 2;0'; [ "$RC" = "64" ] || bad="$bad [milestone invalide rc=$RC]"
sp "$TMP" -- --path "$D" --name m --milestone ''; [ "$RC" = "64" ] || bad="$bad [milestone vide rc=$RC]"
sp "$TMP" -- --path "$D" --name m --bogus; [ "$RC" = "64" ] || bad="$bad [option inconnue rc=$RC]"
[ "$E0" = "$(empreinte "$D")" ] || bad="$bad empreinte modifiée"
emit S9 "$([ -z "$bad" ] && echo 0 || echo 1)" "S9 --milestone invalide / option inconnue : 64 sans écriture" "$bad"

# --- S10 : GSD_WORKSTREAM hérité ---------------------------------------------------------------------
D="$(mk_new_project s10)"
sp "$TMP" GSD_WORKSTREAM=zzz -- --path "$D" --name "Mon Projet"
if [ "$RC" = "0" ] && [ "$OUT" = "$S1OUT" ]; then emit S10 0 "GSD_WORKSTREAM=zzz hérité : même résultat que S1" ""
else emit S10 1 "GSD_WORKSTREAM=zzz hérité : même résultat que S1" "rc=$RC stdout=[$OUT] stderr=[$ERR]"; fi

fi # HAVE_ENG (S7-S10)

# --- S11 : piège de résolution du moteur -----------------------------------------------------------------
D="$(mk_new_project s11)"
mkdir -p "$D/gsd-core/bin" "$D/.claude/gsd-core/bin" "$D/.planning/gsd-core/bin"
for w in "$D/gsd-core/bin/gsd-tools.cjs" "$D/.claude/gsd-core/bin/gsd-tools.cjs" "$D/.planning/gsd-core/bin/gsd-tools.cjs"; do
  printf 'require("fs").writeFileSync(process.env.PWD+"/TEMOIN-EXECUTE","x");\n' > "$w"
done
sp "$D" -u CLAUDE_CONFIG_DIR -u GSD_TOOLS "PATH=$TMP/bin-jq" "HOME=$EMPTYHOME" -- --path "$D" --name t
t="$(find "$D" "$TMP" -name 'TEMOIN-EXECUTE' 2>/dev/null | head -1)"
if [ "$RC" = "2" ] && [ -z "$t" ]; then emit S11 0 "témoins gsd-tools.cjs dans le lab, cwd = lab, HOME vide : NON VÉRIFIABLE, aucun témoin exécuté" ""
else emit S11 1 "témoins gsd-tools.cjs dans le lab, cwd = lab, HOME vide : NON VÉRIFIABLE, aucun témoin exécuté" "rc=$RC témoin=[$t]"; fi

# --- S12 : assertions statiques ---------------------------------------------------------------------------
code="$(grep -v '^[[:space:]]*#' "$SCRIPT")"
bad=""
printf '%s\n' "$code" | grep -Eq '(>|>>|\btee\b|sed[[:space:]]+-i)[^|;&]*(STATE|ROADMAP|REQUIREMENTS)\.md' && bad="$bad écriture-directe-de-planning"
printf '%s\n' "$code" | grep -Eq '(^|[^A-Za-z_])eval([^A-Za-z_]|$)|(bash|sh)[[:space:]]+-c([[:space:]]|$)' && bad="$bad évaluation-dynamique"
printf '%s\n' "$code" | grep -q 'jq -cn --arg' || bad="$bad pas-de-jq-cn-arg"
printf '%s\n' "$code" | grep -Eq 'state patch "\$[A-Za-z_]+"' || bad="$bad patch-sans-variable-jq"
printf '%s\n' "$code" | grep -Eq 'state patch .*\$\(' && bad="$bad patch-avec-substitution-en-ligne"
nrun="$(printf '%s\n' "$code" | grep -c 'RUN\[@\]')"
[ "$nrun" = "1" ] || bad="$bad appels-moteur-hors-fonction-unique($nrun)"
printf '%s\n' "$code" | grep 'RUN\[@\]' | grep -q 'env -u GSD_WORKSTREAM' || bad="$bad fonction-sans-env-u"
emit S12 "$([ -z "$bad" ] && echo 0 || echo 1)" "assertions statiques : aucune écriture directe de planning, aucun eval, JSON par jq -cn --arg, fonction moteur unique sous env -u" "$bad"

# =================================================================================================
# Preuve d'usage WSCH-04 de bout en bout (plan 41.2-04) : cas W1-W12 + mutations (i)-(iv), VRAI moteur.
# Le balayage joué est LA définition unique de la CI (fanout-state-integrity.sh), SOURCÉE, jamais copiée
# (P412-D-04 — décision du manager, choix technique). Fixture COMMITÉE : non commitée, le balayage rend
# INVARIANT1-SAUTE, un vert à vide (Finding F5) — la mutation (iii) le prouve.
# =================================================================================================
COND="$(cd "$HERE/.." && pwd)"
FSI="$COND/fanout-state-integrity.sh"
CHKDIV="$COND/check-divergence.sh"
CHKPTR="$COND/check-workstream-pointer.sh"

gcommit() { # <dossier> <message> : commit de toute la fixture (state.json compris)
  ( cd "$1" && git add -A \
    && git -c user.name=fx -c user.email=fx@vibeflow.invalid -c commit.gpgsign=false commit -q -m "$2" ) >/dev/null 2>&1
}

# sweep <lab> [lib] : joue fanout_check_state_integrity (lib SOURCÉE) -> SW_RC / SW_OUT. Sous-shell :
# aucun état de la lib ne fuit dans la suite ; GSD_WORKSTREAM neutralisé.
sweep() {
  local lib="${2:-$FSI}"
  SW_OUT="$( cd "$1" && unset GSD_WORKSTREAM && . "$lib" && fanout_check_state_integrity "$1" 2>&1 )"; SW_RC=$?
}

# vert_sans_reserve <n compartiments> [fragment exigé] : lit SW_RC/SW_OUT ; WHY = motif du rouge.
# Le prédicat de F5 : rc 0, BILAN à 0 écart sur n, zéro INVARIANT1-SAUTE (+ ligne « conforme » si exigée).
vert_sans_reserve() {
  WHY=""
  [ "$SW_RC" = "0" ] || WHY="$WHY rc=$SW_RC"
  printf '%s\n' "$SW_OUT" | grep -qF "0 écart(s) sur $1 compartiment(s) ==" || WHY="$WHY BILAN-sans-0-écart-sur-$1"
  ! printf '%s\n' "$SW_OUT" | grep -q 'INVARIANT1-SAUTE' || WHY="$WHY INVARIANT1-SAUTE"
  if [ -n "${2:-}" ]; then printf '%s\n' "$SW_OUT" | grep -qF -- "$2" || WHY="$WHY ligne-manquante[$2]"; fi
  [ -z "$WHY" ]
}

# chain34 <script du geste> <lib du balayage> : fixture neuve + geste + commit + balayage.
# -> D (fixture), C_RC / C_OUT (geste), SW_RC / SW_OUT (balayage)
CN=0
chain34() {
  CN=$((CN+1))   # compteur hors sous-shell : un dossier de fixture distinct par appel
  D="$(mk_new_project chain$CN)"
  local save="$SCRIPT"; SCRIPT="$1"
  sp "$TMP" -- --path "$D" --name "Mon Projet"
  SCRIPT="$save"; C_RC=$RC; C_OUT="$OUT"
  gcommit "$D" "docs: partition (split-planning)"
  sweep "$D" "$2"
}

# w2_temoin <lib> : copie de fixture, migration BRUTE sans séquence, commitée, balayage -> rc 0 = témoin
# rouge comme attendu (SW_RC=1 et « rc=2 » nommé pour ws1) ; rc 1 = le témoin n'est PAS rouge.
w2_temoin() {
  CN=$((CN+1))
  local d; d="$(mk_new_project w2-$CN)"
  eng "$d" workstream create ws1 --migrate-name ws1 >/dev/null 2>&1
  gcommit "$d" "docs: migration brute sans séquence"
  sweep "$d" "$1"
  [ "$SW_RC" = "1" ] && printf '%s\n' "$SW_OUT" | grep -qF 'rc=2' && printf '%s\n' "$SW_OUT" | grep -qF 'ws1'
}

# mutate <fichier> <ligne exacte d'ancrage> <remplacement> : l'ancre doit exister UNE fois, le mutant
# différer de l'original (cmp), et rester syntaxiquement valide (bash -n) — sinon « NON OPPOSABLE ».
mutate() {
  local f="$1" anchor="$2" repl="$3" orig; orig="$f.orig"
  [ "$(grep -cFx -- "$anchor" "$f")" = "1" ] || { echo "ancre absente ou multiple [$anchor]"; return 1; }
  cp "$f" "$orig"
  awk -v a="$anchor" -v r="$repl" '$0==a{print r; next} {print}' "$orig" > "$f"
  cmp -s "$f" "$orig" && { echo "mutant NON OPPOSABLE (identique à l'original) [$anchor]"; return 1; }
  bash -n "$f" 2>/dev/null || { echo "mutant syntaxiquement invalide [$anchor]"; return 1; }
  return 0
}

mk_mut_tree() { # <nom> -> MT : arbre plugin/ jetable (jamais un fichier écrit sous plugin/ du dépôt)
  MT="$TMP/mut-$1/plugin"; mkdir -p "$MT/conductor/scripts" "$MT/planning-core/scripts"
  local f
  for f in split-planning.sh check-planning-not-inflight.sh fanout-state-integrity.sh check-state-integrity.sh; do
    cp "$COND/$f" "$MT/conductor/scripts/$f"
  done
  cp "$COND/../../planning-core/scripts/workstream-policy.sh" "$MT/planning-core/scripts/workstream-policy.sh"
}

echo
echo "== preuve d'usage WSCH-04 (cas W1-W12) =="

if [ "$HAVE_ENG" = 1 ]; then

# --- W1 : gate sur la fixture plate commitée -------------------------------------------------------
D1="$(mk_new_project w1)"
OUT="$(env -u GSD_WORKSTREAM "$BASH_BIN" "$COND/check-planning-not-inflight.sh" --path "$D1" 2>"$TMP/err")"; RC=$?; ERR="$(cat "$TMP/err")"
expect W1 "gate sur la fixture plate commitée : plat, rc 0" 0 "-" "plat"

# --- W2 : témoin positif — migration seule, SANS séquence, ROUGE au balayage -----------------------------
if w2_temoin "$FSI"; then emit W2 0 "témoin : migration brute sans séquence (ws1) ROUGE au balayage — rc=1, « rc=2 » nommé pour ws1" ""
else emit W2 1 "témoin : migration brute sans séquence (ws1) ROUGE au balayage" "rc=$SW_RC : $(printf '%s' "$SW_OUT" | tail -4)"; fi
W2OUT="$SW_OUT"

# --- W3 / W4 : le geste, puis le balayage de la CI --------------------------------------------------------
chain34 "$SCRIPT" "$FSI"
if [ "$C_RC" = "0" ] && [ "$C_OUT" = '{"mode":"plat","subject":"mon-projet","state":"complete"}' ]; then
  emit W3 0 "split-planning.sh --name \"Mon Projet\" : complete" ""
else emit W3 1 "split-planning.sh --name \"Mon Projet\" : complete" "rc=$C_RC stdout=[$C_OUT]"; fi
if vert_sans_reserve 1 "conforme (compteurs non régressés, 1 ligne '^Phase:')"; then
  emit W4 0 "balayage de la CI (lib sourcée) : rc 0, « conforme (… 1 ligne '^Phase:') », 0 écart sur 1 compartiment, zéro INVARIANT1-SAUTE" ""
else emit W4 1 "balayage de la CI : vert sans réserve" "$WHY"; fi
W4OUT="$SW_OUT"
DW="$D"

# --- W5 : check-divergence ----------------------------------------------------------------------------------
O5="$( cd "$DW" && env -u GSD_WORKSTREAM "$BASH_BIN" "$CHKDIV" --path "$DW" 2>&1 )"; R5=$?
if [ "$R5" = "0" ] && printf '%s' "$O5" | grep -qF 'conforme'; then emit W5 0 "check-divergence.sh --path : rc 0, conforme" ""
else emit W5 1 "check-divergence.sh --path : rc 0, conforme" "rc=$R5 sortie=[$O5]"; fi

# --- W6 : check-workstream-pointer avec GSD_WORKSTREAM -------------------------------------------------------
O6="$( cd "$DW" && env GSD_WORKSTREAM=mon-projet "$BASH_BIN" "$CHKPTR" --path "$DW" 2>&1 )"; R6=$?
if [ "$R6" = "0" ] && printf '%s' "$O6" | grep -q 'env'; then emit W6 0 "check-workstream-pointer.sh, GSD_WORKSTREAM=mon-projet : rc 0, canal env nommé" ""
else emit W6 1 "check-workstream-pointer.sh, GSD_WORKSTREAM=mon-projet : rc 0, canal env nommé" "rc=$R6 sortie=[$O6]"; fi

# --- W7 : second sujet ----------------------------------------------------------------------------------------
sp "$TMP" -- --path "$DW" --name second
expect W7 "second sujet : partitionné, non-initialise" 0 "-" '{"mode":"partitionne","subject":"second","state":"non-initialise"}'
gcommit "$DW" "docs: second sujet"

# --- W8 : balayage à deux sujets ---------------------------------------------------------------------------------
sweep "$DW"
if vert_sans_reserve 2 && printf '%s\n' "$SW_OUT" | grep -F 'second' | grep -qF 'non initialisé' && printf '%s\n' "$SW_OUT" | grep -qF 'jamais compté comme écart'; then
  emit W8 0 "balayage à deux sujets : rc 0, second « non initialisé … jamais compté comme écart », 0 écart sur 2 compartiment(s)" ""
else emit W8 1 "balayage à deux sujets : second non initialisé, 0 écart sur 2" "$WHY : $(printf '%s' "$SW_OUT" | tail -5)"; fi
W8OUT="$SW_OUT"

# --- W9 : check-divergence à deux sujets ----------------------------------------------------------------------------
O9="$( cd "$DW" && env -u GSD_WORKSTREAM "$BASH_BIN" "$CHKDIV" --path "$DW" 2>&1 )"; R9=$?
if [ "$R9" = "0" ] && printf '%s' "$O9" | grep -F 'second' | grep -qF 'S4 non applicable'; then emit W9 0 "check-divergence.sh à deux sujets : rc 0, « S4 non applicable » pour second" ""
else emit W9 1 "check-divergence.sh à deux sujets : rc 0, S4 non applicable pour second" "rc=$R9 sortie=[$O9]"; fi

# --- W10 : gate sur le lab partitionné --------------------------------------------------------------------------------
OUT="$(env -u GSD_WORKSTREAM "$BASH_BIN" "$COND/check-planning-not-inflight.sh" --path "$DW" 2>"$TMP/err")"; RC=$?; ERR="$(cat "$TMP/err")"
expect W10 "gate sur le lab partitionné : partitionne, rc 0" 0 "-" "partitionne"

# --- W11 / W12 : bascule refusée avec une phase en vol, acceptée une fois close ----------------------------------------------
D11="$(mk_new_project w11)"; mkdir -p "$D11/.planning/phases/01-fondations"
printf '# p\n' > "$D11/.planning/phases/01-fondations/01-01-PLAN.md"
E11="$(empreinte "$D11")"
sp "$TMP" -- --path "$D11" --name vol
bad=""; [ "$E11" = "$(empreinte "$D11")" ] || bad="$bad empreinte-modifiée"; [ ! -d "$D11/.planning/workstreams" ] || bad="$bad workstreams/-créé"
[ "$RC" = "1" ] || bad="$bad rc=$RC"
emit W11 "$([ -z "$bad" ] && echo 0 || echo 1)" "phase en vol (PLAN sans SUMMARY) : bascule REFUSÉE rc 1, .planning/ inchangé, aucun workstreams/" "$bad"
printf '# s\n' > "$D11/.planning/phases/01-fondations/01-01-SUMMARY.md"
if [ "$E11" = "$(empreinte "$D11")" ]; then emit W12 1 "mutation de fixture (SUMMARY ajouté) prouvée par empreinte" "empreinte identique : le SUMMARY n'a pas été vu"
else
  sp "$TMP" -- --path "$D11" --name vol
  expect W12 "même fixture + SUMMARY (empreinte changée) : bascule acceptée, complete" 0 "-" '{"mode":"plat","subject":"vol","state":"complete"}'
fi

# =================================================================================================
echo
echo "== mutations (QUAL-01) : la preuve sait rougir =="
MD=0

# --- (i) geste mutant : saute la séquence d'état mais rend complete ----------------------------------------------------
mk_mut_tree i; MS="$MT/conductor/scripts/split-planning.sh"; ML="$MT/conductor/scripts/fanout-state-integrity.sh"
if mutate "$MS" 'elif [ "$MODE" = "plat" ]; then' 'elif false; then' && mutate "$MS" 'STATE_OUT="non-initialise"' 'STATE_OUT="complete"'; then
  chain34 "$MS" "$ML"
  w3_ok=1; [ "$C_RC" = "0" ] && [ "$C_OUT" = '{"mode":"plat","subject":"mon-projet","state":"complete"}' ] && w3_ok=0
  if [ "$w3_ok" = "0" ] && ! vert_sans_reserve 1 "conforme (compteurs non régressés, 1 ligne '^Phase:')" && [ "$SW_RC" = "1" ]; then
    MD=$((MD+1)); emit M1 0 "(i) geste sans séquence d'état : W3 reste vert (stdout complete), W4 bascule — balayage rc 1 ($WHY)" ""
    echo "      trace (i) : assertion=W4 « vert sans réserve, rc 0, conforme (… 1 ligne '^Phase:') » ; attendu=rc 0 ; obtenu=rc $SW_RC, $(printf '%s\n' "$SW_OUT" | grep -m1 '::error::')"
  else emit M1 1 "(i) geste sans séquence : le balayage doit rougir sur W4 seul" "W3-ok=$w3_ok C_RC=$C_RC C_OUT=[$C_OUT] ERR=[$ERR] rc=$SW_RC WHY=[$WHY]"; fi
else emit M1 1 "(i) construction du mutant" "$(mutate "$MS" 'x' 'y' 2>&1 | head -1) (voir ancre)"; fi

# --- (ii) lib mutante : la note du rc inattendu est neutralisée => le témoin W2 passe à tort au vert -----------------------
mk_mut_tree ii; ML="$MT/conductor/scripts/fanout-state-integrity.sh"
ANCH="$(grep -F '_fsi_note "$_fsi_rel : rc=$_fsi_rc2, attendu 0' "$ML")"
if mutate "$ML" "$ANCH" '        : # MUTANT : note du rc inattendu neutralisée'; then
  if w2_temoin "$ML"; then emit M2 1 "(ii) lib mutée : le témoin W2 devrait passer à tort au vert" "témoin encore rouge (rc=$SW_RC)"
  else
    chain34 "$SCRIPT" "$ML"   # la lib mutée ne doit PAS toucher W3/W4 : mutant tué pour la bonne raison
    if [ "$C_RC" = "0" ] && vert_sans_reserve 1; then
      MD=$((MD+1)); emit M2 0 "(ii) lib à note neutralisée : W2 bascule (témoin vert à tort), W4 intact" ""
      echo "      trace (ii) : assertion=W2 « balayage rc 1 et rc=2 nommé pour ws1 » ; attendu=rc 1 ; obtenu=rc $SW_RC (balayage du témoin rejoué)"
    else emit M2 1 "(ii) lib mutée tuée pour la mauvaise raison (W4 touché)" "C_RC=$C_RC C_OUT=[$C_OUT] ERR=[$ERR] WHY=[$WHY]"; fi
  fi
else emit M2 1 "(ii) construction du mutant" "ancre introuvable [$ANCH]"; fi

# --- (iii) fixture post-geste NON commitée : INVARIANT1-SAUTE, le prédicat de W4 rend faux -----------------------------------
D3="$(mk_new_project m3)"; sp "$TMP" -- --path "$D3" --name "Mon Projet"   # PAS de commit
sweep "$D3"
if [ "$SW_RC" = "0" ] && printf '%s\n' "$SW_OUT" | grep -q 'INVARIANT1-SAUTE' && ! vert_sans_reserve 1 "conforme (compteurs non régressés, 1 ligne '^Phase:')"; then
  MD=$((MD+1)); emit M3 0 "(iii) fixture non commitée : balayage rc 0 MAIS INVARIANT1-SAUTE — le prédicat « vert sans réserve » de W4 rend faux" ""
  echo "      trace (iii) : assertion=W4 « zéro INVARIANT1-SAUTE » ; attendu=aucune occurrence ; obtenu=$(printf '%s\n' "$SW_OUT" | grep -c 'INVARIANT1-SAUTE') occurrence(s), rc $SW_RC (WHY=$WHY)"
else emit M3 1 "(iii) fixture non commitée : rc 0 + INVARIANT1-SAUTE attendus" "rc=$SW_RC WHY=[$WHY]"; fi

# --- (iv) fixture plate à status: executing, aucun PLAN en vol : lecture (a) => bascule refusée --------------------------------
D4="$(mk_new_project m4)"; cp "$D4/.planning/STATE.md" "$TMP/m4.avant"
sed 's/^status: planning$/status: executing/' "$TMP/m4.avant" > "$D4/.planning/STATE.md"
if cmp -s "$TMP/m4.avant" "$D4/.planning/STATE.md"; then emit M4 1 "(iv) mutation de fixture (status: executing) prouvée par cmp" "STATE identique"
else
  E4="$(empreinte "$D4")"
  sp "$TMP" -- --path "$D4" --name exec
  if [ "$RC" = "1" ] && [ "$E4" = "$(empreinte "$D4")" ] && [ ! -d "$D4/.planning/workstreams" ]; then
    MD=$((MD+1)); emit M4 0 "(iv) status: executing sans PLAN en vol : bascule REFUSÉE rc 1, rien écrit" ""
    echo "      trace (iv) : assertion=W11/lecture (a) « status executing ⇒ refus » ; attendu=rc 1 ; obtenu=rc $RC (stderr : $(printf '%s' "$ERR" | head -1))"
  else emit M4 1 "(iv) status: executing : refus rc 1, rien écrit" "rc=$RC stderr=[$ERR]"; fi
fi

echo "== mutations : $MD/4 détectées =="

else
  emit ENGINE 1 "moteur gsd-core introuvable (GSD_TOOLS, PATH, ~/.claude/gsd-core) : S1-S5, S7-S10, W1-W12 et mutations (i)-(iv) NON jouables — ko, jamais skip" "installer @opengsd/gsd-core@^1"
fi # HAVE_ENG (W1-W12, mutations)

echo
echo "== bilan : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
