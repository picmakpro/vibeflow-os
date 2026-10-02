#!/usr/bin/env bash
# test-check-planning-not-inflight.sh — Suite de vérification de check-planning-not-inflight.sh
# (Phase 41.2, plan 41.2-01, exigence WSCH-03, QUAL-01).
#
# Un cas par état du contrat (cf. en-tête du gate), chacun sur sa propre fixture construite dans un
# `mktemp -d`, jamais dans le dépôt. Les quatre codes du contrat (0, 1, 2, 64) sont exercés et
# l'ensemble effectivement observé est comparé à l'ensemble attendu (`comm`, ni manquant ni hors
# contrat).
#
# Cette suite exige le VRAI moteur (`~/.claude/gsd-core/bin/gsd-tools.cjs`) : le job `tests` de la CI
# l'installe, le job `gates` non.
#
# DISCRIMINANCE PAR MUTATION (QUAL-01). Huit mutants du GATE, chacun appliqué à une copie du gate ET
# de workstream-policy.sh côte à côte dans un dossier jetable (jamais un fichier écrit sous
# `plugin/`) : témoin préalable (la copie non mutée rend la matrice de l'original), unicité de la
# ligne-ancre (`grep -c` = 1), `cmp -s` mutant ≠ copie (sinon « mutant NON OPPOSABLE »), `bash -n`.
# Verdict : l'ENSEMBLE des cas de la matrice dont le verdict bascule, comparé par `comm` à
# l'ensemble attendu — un cas en trop ou en moins rend ✗ « tué pour la mauvaise raison ».
#
# Aucun `diff` (proxifié, menteur sur ce poste) : `cmp -s` et `comm`.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-planning-not-inflight.sh"
POLICY="$(cd "$(dirname "$0")/../../../planning-core/scripts" && pwd)/workstream-policy.sh"
BASH_BIN="$(command -v bash)"

PASS=0; FAIL=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

QUIET=0
RES="$TMP/res.txt"          # « <ID> OK|KO » du dernier passage de matrice
RCSEEN="$TMP/rcs.txt"       # codes de sortie observés (passage normal seulement)
: > "$RCSEEN"
TARGET="$SCRIPT"
MXN=0

emit() { # <ID> <0 = ok | 1 = ko> <description> <détail>
  if [ "$2" -eq 0 ]; then
    echo "$1 OK" >> "$RES"
    [ "$QUIET" -eq 1 ] || { echo "  ✓ $1 — $3"; PASS=$((PASS+1)); }
  else
    echo "$1 KO" >> "$RES"
    printf '%s\t%s\n' "$1" "$4" >> "$RES.det"
    [ "$QUIET" -eq 1 ] || { echo "  ✗ $1 — $3 [$4]"; FAIL=$((FAIL+1)); }
  fi
}

# --- Outils : deux PATH jetables de liens (avec et SANS jq) -----------------------------------------
mkdir -p "$TMP/bin-jq" "$TMP/bin-nojq"
for t in awk sed tr grep cat ls find sort head tail cut uniq wc mktemp date basename dirname env \
         node readlink rm mkdir cmp expr tee xargs uname id cksum; do
  p="$(command -v "$t" 2>/dev/null || true)"
  [ -n "$p" ] || continue
  ln -s "$p" "$TMP/bin-jq/$t"; ln -s "$p" "$TMP/bin-nojq/$t"
done
JQ_REAL="$(command -v jq 2>/dev/null || true)"
[ -n "$JQ_REAL" ] && ln -s "$JQ_REAL" "$TMP/bin-jq/jq"
EMPTYHOME="$TMP/home-vide"; mkdir -p "$EMPTYHOME"

# --- Exécution du gate : RC / OUT (stdout) / ERR (stderr) ------------------------------------------
# g <cwd> [<arg d'env>...] -- <args du gate>
# L'environnement est TOUJOURS explicite : jamais d'héritage de GSD_WORKSTREAM ni de la surcharge.
g() {
  local cwd="$1"; shift
  local envs=()
  while [ "$1" != "--" ]; do envs+=("$1"); shift; done
  shift
  OUT="$( cd "$cwd" && env -u GSD_WORKSTREAM -u VF_WORKSTREAM_PLANNING_DIR \
            ${envs[@]+"${envs[@]}"} "$BASH_BIN" "$TARGET" "$@" 2>"$TMP/err" )"; RC=$?
  ERR="$(cat "$TMP/err" 2>/dev/null)"
}

# expect <ID> <description> <rc attendu> <stdout attendu | -> <fragment de stderr | ->
expect() {
  local ok=0 why=""
  [ "$QUIET" -eq 1 ] || { echo "$RC" >> "$RCSEEN"; printf '%s\n%s\n' "$OUT" "$ERR" >> "$TMP/emis.txt"; }
  [ "$RC" = "$3" ] || { ok=1; why="rc=$RC attendu $3"; }
  if [ "$4" != "-" ] && [ "$OUT" != "$4" ]; then ok=1; why="$why stdout=[$OUT] attendu [$4]"; fi
  if [ "$5" != "-" ] && ! printf '%s' "$ERR" | grep -qF -- "$5"; then
    ok=1; why="$why stderr sans [$5] : [$ERR]"
  fi
  emit "$1" "$ok" "$2" "$why"
}

empreinte() { # contenu ET arbre, indépendants de l'ordre du système de fichiers
  find "$1" | LC_ALL=C sort
  find "$1" -type f -exec cksum {} + | LC_ALL=C sort
}

# --- Fixtures --------------------------------------------------------------------------------------
mkflat() { # <nom> [status] -> chemin d'un lab PLAT propre : ROADMAP à trois phases, aucun plan
  local d="$TMP/mx$MXN/$1"
  mkdir -p "$d/.planning/phases"
  printf -- '---\ngsd_state_version: "1.0"\nstatus: %s\n---\n\n# Project State\n\nPhase: 1 of 3 (Fondations)\n' \
    "${2:-planning}" > "$d/.planning/STATE.md"
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
  printf '%s' "$d"
}
addplan() { # <lab> <phase dir> <fichier>
  mkdir -p "$1/.planning/phases/$2"; printf '# %s\n' "$3" > "$1/.planning/phases/$2/$3"
}

# =================================================================================================
# La MATRICE : jouée une fois sur le gate réel, puis une fois par mutant (QUIET=1).
# =================================================================================================
matrix() {
  MXN=$((MXN+1)); : > "$RES"; : > "$RES.det"
  local D D2 pre post

  D="$(mkflat f1)"
  g "$TMP" -- --path "$D"
  expect F1 "lab plat propre (trois phases, aucun plan) : accepté, stdout « plat »" 0 "plat" "-"

  D="$(mkflat f2)"; addplan "$D" 01-fondations 01-01-PLAN.md
  g "$TMP" -- --path "$D"
  expect F2 "phase 1 : un PLAN sans SUMMARY : REFUSÉ (ADR-069)" 1 "" "REFUSÉ (ADR-069)"

  D="$(mkflat f2b)"; addplan "$D" 01-fondations 01-01-PLAN.md; addplan "$D" 01-fondations 01-02-PLAN.md
  addplan "$D" 01-fondations 01-01-SUMMARY.md
  g "$TMP" -- --path "$D"
  expect F2b "phase 1 : deux PLAN, un SUMMARY : REFUSÉ, lecture (b) seule le voit" 1 "" "(b)"

  D="$(mkflat f3)"; addplan "$D" 01-fondations 01-01-PLAN.md
  empreinte "$D" > "$TMP/f3.avant"
  addplan "$D" 01-fondations 01-01-SUMMARY.md
  empreinte "$D" > "$TMP/f3.apres"
  if cmp -s "$TMP/f3.avant" "$TMP/f3.apres"; then
    emit F3 1 "F2 + SUMMARY posé : accepté" "la mutation n'a RIEN changé à la fixture — NON OPPOSABLE"
  else
    g "$TMP" -- --path "$D"
    expect F3 "F2 + 01-01-SUMMARY.md posé (cmp : fixture bien modifiée) : accepté « plat »" 0 "plat" "-"
  fi

  D="$(mkflat f4 executing)"
  g "$TMP" -- --path "$D"
  expect F4 "status: executing (aucun plan) : REFUSÉ, lecture (a)" 1 "" "(a)"

  D="$(mkflat f4b '"Executing"')"
  g "$TMP" -- --path "$D"
  expect F4b "status: \"Executing\" (guillemets, casse) : REFUSÉ, lecture (a)" 1 "" "(a)"

  D="$TMP/mx$MXN/f5"; mkdir -p "$D/.planning/workstreams/ws1"
  printf -- '---\nworkstream: ws1\n---\n' > "$D/.planning/workstreams/ws1/STATE.md"
  g "$TMP" -- --path "$D"
  expect F5 "lab partitionné : accepté, stdout « partitionne »" 0 "partitionne" "-"

  D="$(mkflat f6)"
  g "$TMP" -u CLAUDE_CONFIG_DIR -u GSD_TOOLS "PATH=$TMP/bin-jq" "HOME=$EMPTYHOME" -- --path "$D"
  expect F6 "moteur introuvable (HOME vide, ni GSD_TOOLS ni gsd-tools) : NON VÉRIFIABLE" 2 "" "NON VÉRIFIABLE"

  D="$(mkflat f7)"
  printf -- '---\ngsd_state_version: "1.0"\n---\n\nPhase: 1\n' > "$D/.planning/STATE.md"
  g "$TMP" -- --path "$D"
  expect F7 "frontmatter sans clé status : NON VÉRIFIABLE" 2 "" "NON VÉRIFIABLE"

  D="$(mkflat f8)"; rm -f "$D/.planning/ROADMAP.md"
  g "$TMP" -- --path "$D"
  expect F8 "ROADMAP.md absent : NON VÉRIFIABLE (le moteur rend rc 0 avec error)" 2 "" "NON VÉRIFIABLE"

  D="$(mkflat f9)"; addplan "$D" 01-fondations 01-01-PLAN.md; addplan "$D" 01-fondations 01-02-PLAN.md
  addplan "$D" 01-fondations 01-01-SUMMARY.md
  g "$TMP" GSD_WORKSTREAM=zzz -- --path "$D"
  expect F9 "F2b avec GSD_WORKSTREAM=zzz hérité : toujours REFUSÉ (env neutralisé)" 1 "" "REFUSÉ (ADR-069)"

  D="$(mkflat f10)"; addplan "$D" 09-orphelin 09-01-PLAN.md
  g "$TMP" -- --path "$D"
  expect F10 "dossier 09-orphelin absent du ROADMAP, PLAN sans SUMMARY : REFUSÉ, lecture (b')" 1 "" "(b')"

  g "$TMP" -- --path "$TMP/mx$MXN/introuvable-sans-planning"
  expect F11 "--path introuvable : NON VÉRIFIABLE" 2 "" "NON VÉRIFIABLE"
  D="$TMP/mx$MXN/f11"; mkdir -p "$D"
  g "$TMP" -- --path "$D"
  expect F11b "pas de .planning/ : NON VÉRIFIABLE" 2 "" "NON VÉRIFIABLE"

  D="$(mkflat f12)"
  g "$TMP" "PATH=$TMP/bin-nojq" -- --path "$D"
  expect F12 "jq absent (PATH de liens sans jq) : NON VÉRIFIABLE" 2 "" "jq"

  g "$TMP" -- --bogus
  expect F13 "option inconnue : usage" 64 "" "inconnu"
  g "$TMP" -- --path
  expect F13b "--path sans valeur : usage" 64 "" "--path"

  D="$(mkflat f14)"; mkdir -p "$D/.planning/workstreams"
  g "$TMP" -- --path "$D"
  expect F14 "workstreams/ vide : NON VÉRIFIABLE" 2 "" "NON VÉRIFIABLE"

  D="$(mkflat f15)"; mkdir -p "$TMP/mx$MXN/cible-f15/ws1"
  ln -s "$TMP/mx$MXN/cible-f15" "$D/.planning/workstreams"
  g "$TMP" -- --path "$D"
  expect F15 "workstreams = lien symbolique : NON VÉRIFIABLE" 2 "" "NON VÉRIFIABLE"

  D="$(mkflat f16)"; printf '# Roadmap\n\nrien\n' > "$D/.planning/ROADMAP.md"
  g "$TMP" -- --path "$D"
  expect F16 "ROADMAP sans aucune phase : NON VÉRIFIABLE" 2 "" "NON VÉRIFIABLE"

  # F17 — piège de résolution : deux candidats relatifs au cwd, chacun écrit un témoin s'il tourne.
  D="$(mkflat f17)"
  mkdir -p "$D/gsd-core/bin" "$D/.claude/gsd-core/bin"
  printf "require('fs').writeFileSync(%s,'x');\n" "'$D/TEMOIN-1'" > "$D/gsd-core/bin/gsd-tools.cjs"
  printf "require('fs').writeFileSync(%s,'x');\n" "'$D/TEMOIN-2'" > "$D/.claude/gsd-core/bin/gsd-tools.cjs"
  g "$D" -u CLAUDE_CONFIG_DIR -u GSD_TOOLS "PATH=$TMP/bin-jq" "HOME=$EMPTYHOME" -- --path "$D"
  if [ -e "$D/TEMOIN-1" ] || [ -e "$D/TEMOIN-2" ]; then
    [ "$QUIET" -eq 1 ] || echo "$RC" >> "$RCSEEN"
    emit F17 1 "moteur relatif au cwd NON exécuté" "un fichier-témoin existe : le candidat cwd a été exécuté"
  else
    expect F17 "cwd = fixture portant gsd-core/bin et .claude/gsd-core/bin, HOME vide : NON VÉRIFIABLE, aucun témoin" 2 "" "NON VÉRIFIABLE"
  fi

  # F18 — lecture seule : empreinte identique avant/après sur F1, F2, F4, F5, F10.
  local bad="" n
  for n in f1 f2 f4 f5 f10; do
    D="$TMP/mx$MXN/$n"
    [ -d "$D" ] || { bad="$bad $n(absent)"; continue; }
    empreinte "$D" > "$TMP/e.avant"
    g "$TMP" -- --path "$D"
    empreinte "$D" > "$TMP/e.apres"
    cmp -s "$TMP/e.avant" "$TMP/e.apres" || bad="$bad $n"
  done
  if [ -z "$bad" ]; then emit F18 0 "lecture seule : empreinte identique avant/après sur F1, F2, F4, F5, F10" ""
  else emit F18 1 "lecture seule" "fixture modifiée par le gate :$bad"; fi
}

echo "== test-check-planning-not-inflight =="

if [ ! -f "$SCRIPT" ]; then
  echo "  ✗ GATE — check-planning-not-inflight.sh absent ($SCRIPT)"
  echo ""
  echo "== resultat : 0 ok, 1 ko =="
  exit 1
fi
[ -f "$POLICY" ] || { echo "  ✗ POLICY — workstream-policy.sh introuvable ($POLICY)"; exit 1; }
[ -f "$HOME/.claude/gsd-core/bin/gsd-tools.cjs" ] || command -v gsd-tools >/dev/null 2>&1 \
  || [ -n "${GSD_TOOLS:-}" ] \
  || { echo "  ✗ MOTEUR — aucun moteur gsd-tools résolvable : cette suite exige le vrai moteur"; exit 1; }

matrix
cp "$RES" "$TMP/res.reel"

# --- Couverture des codes ---------------------------------------------------------------------------
LC_ALL=C sort -u "$RCSEEN" > "$TMP/rcs.seen"
printf '0\n1\n2\n64\n' | LC_ALL=C sort -u > "$TMP/rcs.attendus"
manquants="$(comm -13 "$TMP/rcs.seen" "$TMP/rcs.attendus" | tr '\n' ' ')"
hors="$(comm -23 "$TMP/rcs.seen" "$TMP/rcs.attendus" | tr '\n' ' ')"
if [ -z "$manquants" ] && [ -z "$hors" ]; then
  emit COUV 0 "les quatre codes du contrat (0, 1, 2, 64) sont chacun exercés, aucun rc hors contrat" ""
else
  emit COUV 1 "couverture des codes de sortie" "manquants=[$manquants] hors_contrat=[$hors]"
fi

# --- F19 + VOCAB : vocabulaire des messages (correction C4) --------------------------------------------------
# F19 : règles des sujets introuvables (gate seul, aucun voisin ni planning-core). Puis sonde sur TOUTES les
# sorties réelles de la passe normale (stdout + stderr de chaque `expect`) : ni « workstream » ni « compartiment ».
ISO="$TMP/iso/conductor/scripts"; mkdir -p "$ISO"; cp "$SCRIPT" "$ISO/check-planning-not-inflight.sh"
D="$(mkflat f19)"
TARGET="$ISO/check-planning-not-inflight.sh"; g "$TMP" -- --path "$D"; TARGET="$SCRIPT"
expect F19 "règles des sujets introuvables (gate isolé) : NON VÉRIFIABLE, message en vocabulaire d'usage" 2 "" "règles des sujets"
vocab_hits="$(grep -i -n -E 'workstream|compartiment' "$TMP/emis.txt" | head -5 | tr '\n' '|')"
if [ -z "$vocab_hits" ]; then emit VOCAB 0 "aucun message émis ($(grep -c '' "$TMP/emis.txt") lignes, passe normale) ne contient workstream/compartiment" ""
else emit VOCAB 1 "aucun message émis ne contient workstream/compartiment" "occurrences : $vocab_hits"; fi

# =================================================================================================
# Mutants
# =================================================================================================
echo ""
echo "== mutants =="
QUIET=1
KILLED=0

mutant() { # <nom> <ancre BRE> <sed s///> <ensemble attendu : IDs séparés par des espaces>
  local name="$1" anchor="$2" expr="$3" expected="$4" dir="$TMP/mut-$1" got why n
  mkdir -p "$dir"
  cp "$SCRIPT" "$dir/check-planning-not-inflight.sh"; cp "$POLICY" "$dir/workstream-policy.sh"
  cp "$dir/check-planning-not-inflight.sh" "$dir/copie-temoin.sh"
  n="$(grep -c -e "$anchor" "$dir/check-planning-not-inflight.sh")"
  if [ "$n" != "1" ]; then
    QUIET=0; emit "M-$name" 1 "mutant" "ligne-ancre non unique ($n occurrences de [$anchor])"; QUIET=1; return
  fi
  sed -i.bak -e "/$anchor/$expr" "$dir/check-planning-not-inflight.sh"; rm -f "$dir/check-planning-not-inflight.sh.bak"
  if cmp -s "$dir/check-planning-not-inflight.sh" "$dir/copie-temoin.sh"; then
    QUIET=0; emit "M-$name" 1 "mutant" "mutant NON OPPOSABLE : la substitution n'a RIEN changé"; QUIET=1; return
  fi
  if ! bash -n "$dir/check-planning-not-inflight.sh" 2>/dev/null; then
    QUIET=0; emit "M-$name" 1 "mutant" "le mutant n'est pas un script valide : il rougirait pour la mauvaise raison"; QUIET=1; return
  fi
  TARGET="$dir/check-planning-not-inflight.sh"
  matrix
  TARGET="$SCRIPT"
  got="$(awk '$2=="KO"{print $1}' "$RES" | LC_ALL=C sort -u | tr '\n' ' ')"
  printf '%s\n' $expected | LC_ALL=C sort -u > "$TMP/m.attendu"
  awk '$2=="KO"{print $1}' "$RES" | LC_ALL=C sort -u > "$TMP/m.obtenu"
  if cmp -s "$TMP/m.attendu" "$TMP/m.obtenu"; then
    QUIET=0; emit "M-$name" 0 "mutant tué : bascule exactement {$(printf '%s' "$expected" | tr -s ' ' ' ')}" ""
    # Trace du rouge : pour chaque cas basculé, l'assertion violée (attendu / obtenu).
    while IFS="$(printf '\t')" read -r _id _det; do echo "      rouge $_id : $_det"; done < "$RES.det"
    QUIET=1
    KILLED=$((KILLED+1))
  else
    why="obtenu {$got} attendu {$expected} ; en trop/en moins : $(comm -3 "$TMP/m.attendu" "$TMP/m.obtenu" | tr -s '\t\n' '  ')"
    QUIET=0; emit "M-$name" 1 "tué pour la mauvaise raison (ou survivant)" "$why"; QUIET=1
  fi
}

# Témoin préalable : la copie NON mutée rend exactement la matrice de l'original (aucun KO).
mkdir -p "$TMP/mut-temoin"
cp "$SCRIPT" "$TMP/mut-temoin/check-planning-not-inflight.sh"; cp "$POLICY" "$TMP/mut-temoin/workstream-policy.sh"
TARGET="$TMP/mut-temoin/check-planning-not-inflight.sh"; matrix; TARGET="$SCRIPT"
if [ -z "$(awk '$2=="KO"{print $1}' "$RES")" ]; then
  QUIET=0; emit TEMOIN 0 "la copie non mutée (gate + politique côte à côte) rend la matrice de l'original" ""; QUIET=1
else
  QUIET=0; emit TEMOIN 1 "la copie non mutée rend la matrice de l'original" "KO : $(awk '$2=="KO"{print $1}' "$RES" | tr '\n' ' ')"; QUIET=1
fi

# Chaque mutant = une substitution `sed` sur UNE ligne-ancre ; l'ensemble attendu est celui des cas
# dont le verdict doit basculer, et lui seul.
mutant a         'status_lc" = "executing"'                    's/"executing"/"zzz-jamais"/'                                   'F4 F4b'
mutant b         'select(.plan_count > .summary_count)'        's/select(.plan_count > .summary_count)/select(false)/'          'F2b F9'
mutant bprime    '^bp_min=1$'                                  's/1/999999/'                                                    'F10'
mutant cmp       'select(.plan_count > .summary_count)'        's/plan_count > /plan_count >= /'                                'F1 F3'
mutant env       'cwd "$ROOT" query'                       's/env -u GSD_WORKSTREAM //'                                     'F9'
mutant forme     'jq -e "$VALID_JQ"'                           's/jq -e "$VALID_JQ"/jq -e true/'                                'F8 F16'
mutant partition 'echo "partitionne"; exit 0'                  's/echo "partitionne"; exit 0/:/'                                'F5'
mutant cwd       '^GT=""$'                                     's|^GT=""$|GT=""; for _c in gsd-core/bin/gsd-tools.cjs .claude/gsd-core/bin/gsd-tools.cjs; do test -f "$_c" \&\& { GT="$_c"; break; }; done|' 'F17'

QUIET=0
echo ""
if [ "$KILLED" -eq 8 ]; then
  echo "== mutants : 8/8 tués =="
else
  echo "== mutants : $KILLED/8 tués =="
  FAIL=$((FAIL+1))
fi
echo "== resultat : $PASS ok, $FAIL ko ($((PASS+FAIL)) cas) =="
[ "$FAIL" -eq 0 ]
