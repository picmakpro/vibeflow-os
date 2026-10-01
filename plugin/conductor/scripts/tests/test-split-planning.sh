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
[ -n "$GT" ] || { echo "  ✗ SETUP — moteur gsd-tools introuvable : la suite exige le vrai moteur"; exit 1; }
case "$GT" in *.cjs) ENG=(node "$GT") ;; *) ENG=("$GT") ;; esac
eng() { # <cwd> <args…> : appel moteur de la suite, environnement neutralisé
  local c="$1"; shift
  env -u GSD_WORKSTREAM "${ENG[@]}" --cwd "$c" "$@"
}

# --- Outils : PATH réduit de liens (avec jq), pour S6 -------------------------------------------
mkdir -p "$TMP/bin-jq"
for t in awk sed tr grep cat ls find sort head tail cut uniq wc mktemp date basename dirname env \
         readlink rm mkdir cmp expr tee xargs uname id cksum; do
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

# --- S6 : moteur introuvable -----------------------------------------------------------------------
D="$(mk_new_project s6)"; E0="$(empreinte "$D")"
sp "$TMP" -u CLAUDE_CONFIG_DIR -u GSD_TOOLS "PATH=$TMP/bin-jq" "HOME=$EMPTYHOME" -- --path "$D" --name x
expect S6 "moteur introuvable : NON VÉRIFIABLE, aucune écriture" 2 "NON VÉRIFIABLE" ""
[ "$E0" = "$(empreinte "$D")" ] && emit S6 0 "S6 empreinte inchangée" "" || emit S6 1 "S6 empreinte inchangée" "empreinte modifiée"

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

echo
echo "== bilan : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
