#!/usr/bin/env bash
# test-check-ajout-retrait.sh — suite de check-ajout-retrait.sh (SOBR-05, QUAL-01, plan 41.3-04).
# Chaque cas construit SON dépôt jetable sous mktemp -d, jamais le dépôt réel ; identité git par -c ;
# comparaisons par cmp/comm, jamais diff. Trois issues QUAL-01 : PASS (couvert), FAIL (non couvert,
# rc 1 sous --strict) et imparsable BRUYANT (base introuvable : stderr + rc 2 sous --strict), plus
# neuf mutants opposables, chacun asserté avec le rc EXACT sur le mutant ET sur l'original :
# « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
# LIMITE DE FOND : la garde, sa suite et son étape CI vivent dans le dépôt qu'elles jugent.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-ajout-retrait.sh"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
ko() { echo "  ✗ $1"; echo "    attendu   : $2"; echo "    obtenu    : $3"; FAIL=$((FAIL + 1)); }
okmut() { echo "  ✓ MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5"; PASS=$((PASS + 1)); }
komut() { echo "  ✗ MUT-$1 NON TUE : $2"; echo "    attendu   : $3"; echo "    obtenu    : $4"; FAIL=$((FAIL + 1)); }

TMP="$(mktemp -d)"; MUTD="$(mktemp -d)"
trap 'rm -rf "$TMP" "$MUTD"' EXIT

git_c() { local r="$1"; shift; git -C "$r" -c user.name=CI -c user.email=ci@example.invalid -c commit.gpgsign=false "$@"; }
mk_repo() {  # <nom> : dépôt avec ADR-001, CLAUDE.md et un gate déjà là
  local d="$TMP/$1"
  mkdir -p "$d/docs" "$d/plugin/conductor/scripts" "$d/scripts" "$d/.claude/agent-memory/a" || exit 1
  git_c "$d" init -q -b main >/dev/null
  printf '## ADR-001 : premier\ncorps\n' > "$d/docs/ADR.md"
  printf '# Titre\n## Règle une\ntexte\n' > "$d/CLAUDE.md"
  printf '#!/bin/sh\necho v1\n' > "$d/plugin/conductor/scripts/check-old.sh"
  git_c "$d" add -A >/dev/null; git_c "$d" commit -q -m "fixture: etat initial" >/dev/null
  printf '%s' "$d"
}
commit_avec() { git_c "$1" add -A >/dev/null; git_c "$1" commit -q -m "$2" >/dev/null; }
base_of() { git_c "$1" rev-list --max-parents=0 HEAD | tail -1; }
# run <var_out> <var_rc> <script> <root> [args] — le rc RÉEL de l'outil, sans jamais faire sortir la suite.
run() {
  local __vo="$1" __vr="$2" __s="$3" __root="$4"; shift 4
  local __o __r
  __o="$(bash "$__s" --root "$__root" "$@" 2>&1)"; __r=$?
  eval "$__vo=\$__o; $__vr=\$__r"
}
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }
expect() {  # <libellé> <rc_attendu> <rc> <sortie> [<fragment attendu dans la sortie>]
  if [ "$3" -ne "$2" ]; then ko "$1" "rc=$2" "rc=$3 ; $4"; return; fi
  if [ -n "${5:-}" ] && ! has "$4" "$5"; then ko "$1" "sortie contenant « $5 »" "$4"; return; fi
  ok "$1"
}
TR='Ajout-Retrait:'
# POCK-08 : segment « défaillance : » obligatoire sur tout trailer (forme : >= 10 caractères non blancs + date ISO ou SHA).
DF=' — défaillance : 2026-10-06 étude Pocock §5, ajout justifié sans défaillance citée'
DFA=' - defaillance : 2026-10-06 etude Pocock §5, ajout justifie sans defaillance citee'
NEW_GATE='plugin/conductor/scripts/check-new.sh'
add_gate() { printf '#!/bin/sh\necho new\n' > "$1/$NEW_GATE"; }
# Contenu sans rapport avec check-old.sh : git ne le lit pas comme un renommage (qui n'est pas un ajout).
add_gate_distinct() { printf '#!/bin/sh\n# un tout autre gate\nfor f in a b c; do\n  test -e "$f" || exit 1\ndone\necho ok\n' > "$1/$NEW_GATE"; }

echo "== test-check-ajout-retrait : PASS / FAIL / BRUYANT =="

# A1 — gate ajouté + trailer conforme (chemin exact, puis glob, puis séparateur ASCII) → couvert.
D="$(mk_repo a1)"; B="$(base_of "$D")"; add_gate "$D"
commit_avec "$D" "feat: gate

$TR $NEW_GATE — retire check-old.sh devenu redondant avec lui$DF"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A1 gate ajouté + trailer conforme → rc 0 COUVERT" 0 "$R" "$O" "AJOUT-COUVERT: $NEW_GATE"
D="$(mk_repo a1b)"; B="$(base_of "$D")"; add_gate "$D"
commit_avec "$D" "feat: gate

$TR plugin/conductor/scripts/check-*.sh - aucun : premier gate de ce genre, rien à remplacer$DFA"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A1b motif glob + séparateur ASCII + « aucun : justification » → rc 0" 0 "$R" "$O" "COUVERT"

# A2 — sans trailer → listé, --strict rc 1.
D="$(mk_repo a2)"; B="$(base_of "$D")"; add_gate "$D"; commit_avec "$D" "feat: gate nu"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A2 sans trailer → --strict rc 1, ajout nommé" 1 "$R" "$O" "AJOUT-NON-COUVERT: $NEW_GATE"

# A3 — « aucun : » sans justification, ou trop courte → non couvert + MARQUEUR-MAL-FORME.
D="$(mk_repo a3)"; B="$(base_of "$D")"; add_gate "$D"
commit_avec "$D" "feat: gate

$TR $NEW_GATE — aucun :$DF"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A3 « aucun : » sans justification → rc 1 + MARQUEUR-MAL-FORME" 1 "$R" "$O" "MARQUEUR-MAL-FORME"
D="$(mk_repo a3b)"; B="$(base_of "$D")"; add_gate "$D"
commit_avec "$D" "feat: gate

$TR $NEW_GATE — aucun : court$DF
$TR $NEW_GATE, autre.sh — retire tout ce qu'il faut retirer ici$DF"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A3b justification < 10 caractères ET motif à virgule → non couvert" 1 "$R" "$O" "AJOUT-NON-COUVERT"

# A4 — titre ADR ajouté couvert par son identifiant ; titre seulement modifié = pas un ajout.
D="$(mk_repo a4)"; B="$(base_of "$D")"; printf '## ADR-076 : neuf\n' >> "$D/docs/ADR.md"; commit_avec "$D" "docs: adr"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A4 titre ## ADR-076 ajouté, sans trailer → rc 1, clé ADR-076" 1 "$R" "$O" "AJOUT-NON-COUVERT: ADR-076"
git_c "$D" commit -q --allow-empty -m "docs: couverture

$TR ADR-076 — aucun : premier ADR sur ce sujet, rien à remplacer$DF" >/dev/null
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A4 … puis couvert par son identifiant (commit ultérieur)" 0 "$R" "$O" "AJOUT-COUVERT: ADR-076"
D="$(mk_repo a4b)"; B="$(base_of "$D")"; sed -i.bak 's/^## ADR-001 : premier/## ADR-001 : premier, reformulé/' "$D/docs/ADR.md"; rm -f "$D/docs/ADR.md.bak"; commit_avec "$D" "docs: reformule"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A4b titre ADR seulement reformulé → RIEN-A-JUGER, rc 0" 0 "$R" "$O" "RIEN-A-JUGER"
D="$(mk_repo a4c)"; B="$(base_of "$D")"; printf '## Règle deux\ntexte\n' >> "$D/CLAUDE.md"; commit_avec "$D" "docs: regle"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A4c titre ## ajouté à CLAUDE.md non couvert → rc 1, clé CLAUDE.md" 1 "$R" "$O" "AJOUT-NON-COUVERT: CLAUDE.md"

# A5 — mémoire d'agent ajoutée non couverte, MEMORY.md (index) jamais compté.
D="$(mk_repo a5)"; B="$(base_of "$D")"
printf -- '---\nname: x\n---\n' > "$D/.claude/agent-memory/a/project_x.md"; printf -- '- [x](project_x.md)\n' > "$D/.claude/agent-memory/a/MEMORY.md"
commit_avec "$D" "docs: memoire"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A5 mémoire ajoutée non couverte → listée" 1 "$R" "$O" "AJOUT-NON-COUVERT: .claude/agent-memory/a/project_x.md"
if has "$O" "MEMORY.md"; then ko "A5 MEMORY.md exclue" "absente de la sortie" "$O"; else ok "A5 MEMORY.md exclue"; fi

# A6 — base introuvable : BRUYANT (stderr), rc 2 sous --strict.
D="$(mk_repo a6)"; add_gate "$D"; commit_avec "$D" "feat: gate nu"
run O R "$SCRIPT" "$D" --strict --base-ref "ref-qui-n-existe-pas"
expect "A6 base introuvable → --strict rc 2, NON-VERIFIABLE bruyant" 2 "$R" "$O" "NON-VERIFIABLE"
run O R "$SCRIPT" "$D" --base-ref "ref-qui-n-existe-pas" --ci
expect "A6b … défaut : rc 0 mais ::warning:: NON VÉRIFIABLE" 0 "$R" "$O" "::warning::check-ajout-retrait : NON VÉRIFIABLE"
run O R "$SCRIPT" "$TMP" --strict
expect "A6c hors d'un arbre git → rc 2 sous --strict" 2 "$R" "$O" "NON-VERIFIABLE"

# A7 — défaut consultatif : rc 0 même non couvert ; --ci remonte un ::warning::.
D="$(mk_repo a7)"; B="$(base_of "$D")"; add_gate "$D"; commit_avec "$D" "feat: gate nu"
run O R "$SCRIPT" "$D" --base-ref "$B"
expect "A7 défaut : rc 0 même non couvert, défaut dit" 0 "$R" "$O" "AJOUT-NON-COUVERT"
run O R "$SCRIPT" "$D" --base-ref "$B" --ci
expect "A7b --ci : ::warning:: sur l'ajout non couvert" 0 "$R" "$O" "::warning::check-ajout-retrait (consultatif)"

# A8 — portée BRANCHE : le trailer d'un commit ULTÉRIEUR couvre un ajout posé plus tôt.
D="$(mk_repo a8)"; B="$(base_of "$D")"; add_gate "$D"; commit_avec "$D" "feat: gate nu"
git_c "$D" commit -q --allow-empty -m "docs: couverture

$TR $NEW_GATE — aucun : ajout couvert après coup par un commit de documentation$DF" >/dev/null
git_c "$D" commit -q --allow-empty -m "chore: dernier commit sans trailer" >/dev/null
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A8 trailer d'un commit ultérieur (pas le dernier) → couvert, rc 0" 0 "$R" "$O" "AJOUT-COUVERT"

# A9 (m1) — faux négatifs fermés : puce de CLAUDE.md, étape numérotée insérée (les suivantes renumérotées ne comptent pas),
# règle de module, mémoire en sous-dossier.
D="$(mk_repo a9)"; B="$(base_of "$D")"; printf -- '- Une règle neuve en puce, sans titre.\n' >> "$D/CLAUDE.md"; commit_avec "$D" "docs: puce"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A9 puce ajoutée à CLAUDE.md non couverte → rc 1, clé CLAUDE.md" 1 "$R" "$O" "AJOUT-NON-COUVERT: CLAUDE.md"
D="$(mk_repo a9b)"; printf '1. premier\n2. deuxième\n3. troisième\n' >> "$D/CLAUDE.md"; commit_avec "$D" "docs: etapes"; B="$(git_c "$D" rev-parse HEAD)"
printf '1. premier\n2. NOUVELLE ÉTAPE à jouer avant le tag\n3. deuxième\n4. troisième\n' > "$TMP/etapes"
head -n 3 "$D/CLAUDE.md" > "$TMP/claude.tete"; cat "$TMP/claude.tete" "$TMP/etapes" > "$D/CLAUDE.md"; commit_avec "$D" "docs: insere une etape"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A9b étape insérée + renumérotage → UN seul ajout (la nouvelle étape), rc 1" 1 "$R" "$O" "ajouts=1 "
D="$(mk_repo a9c)"; B="$(base_of "$D")"; mkdir -p "$D/plugin/conductor/rules"; printf 'regle\n' > "$D/plugin/conductor/rules/neuve.md"; commit_avec "$D" "docs: regle de module"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A9c règle de module plugin/*/rules/*.md ajoutée → non couverte" 1 "$R" "$O" "AJOUT-NON-COUVERT: plugin/conductor/rules/neuve.md"
D="$(mk_repo a9d)"; B="$(base_of "$D")"; mkdir -p "$D/.claude/agent-memory/a/sous/dossier"; printf -- '---\nname: y\n---\n' > "$D/.claude/agent-memory/a/sous/dossier/project_y.md"; commit_avec "$D" "docs: memoire profonde"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A9d mémoire en sous-dossier ajoutée → non couverte" 1 "$R" "$O" "AJOUT-NON-COUVERT: .claude/agent-memory/a/sous/dossier/project_y.md"

# A10 (m2) — un REMPLACEMENT ne rougit pas : le retrait est dans le diff ; un retrait d'un AUTRE genre ne compense rien.
D="$(mk_repo a10)"; B="$(base_of "$D")"; add_gate_distinct "$D"; git_c "$D" rm -q plugin/conductor/scripts/check-old.sh; commit_avec "$D" "feat: gate qui remplace check-old"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A10 gate supprimé + gate ajouté dans le même diff → rc 0, AJOUT-COMPENSE" 0 "$R" "$O" "AJOUT-COMPENSE: $NEW_GATE"
D="$(mk_repo a10b)"; B="$(base_of "$D")"; add_gate "$D"; printf 'x\n' > "$D/.claude/agent-memory/a/vieille.md"; commit_avec "$D" "docs: prépare"; B="$(git_c "$D" rev-parse HEAD~1)"
git_c "$D" rm -q .claude/agent-memory/a/vieille.md; commit_avec "$D" "docs: retire une mémoire"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A10b retrait d'un autre genre (mémoire) : le gate ajouté n'est PAS compensé → rc 1" 1 "$R" "$O" "AJOUT-NON-COUVERT: $NEW_GATE"
D="$(mk_repo a10c)"; B="$(base_of "$D")"; printf '# Titre\n## Règle remplacée\ntexte\n' > "$D/CLAUDE.md"; commit_avec "$D" "docs: remplace une règle"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A10c titre remplacé par un autre dans CLAUDE.md (net 0) → rc 0" 0 "$R" "$O"

# A11 (m3) — un glob trop large ne couvre pas le monde : `*`, `plugin/*`, `*.sh` refusés, MARQUEUR-MAL-FORME dit pourquoi.
for motif in '*' 'plugin/*' '*.sh' 'plugin/*/scripts/check-new.sh'; do
  D="$(mk_repo "a11-$(printf '%s' "$motif" | cksum | cut -d' ' -f1)")"; B="$(base_of "$D")"; add_gate "$D"
  commit_avec "$D" "feat: gate

$TR $motif — aucun : motif volontairement trop large pour tout couvrir d'un coup$DF"
  run O R "$SCRIPT" "$D" --strict --base-ref "$B"
  expect "A11 motif « $motif » → refusé, ajout non couvert, rc 1" 1 "$R" "$O" "motif glob trop large"
done

# A12 (POCK-08, P414-D-04) — sans segment « défaillance : » daté, un trailer ne couvre rien.
D="$(mk_repo a12)"; B="$(base_of "$D")"; add_gate "$D"
commit_avec "$D" "feat: gate

$TR $NEW_GATE — retire check-old.sh devenu redondant avec lui"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "A12 trailer sans segment « défaillance : » → rc 1, ajout non couvert" 1 "$R" "$O" "AJOUT-NON-COUVERT: $NEW_GATE"
expect "A12 … et MARQUEUR-MAL-FORME nomme le segment manquant" 1 "$R" "$O" "MARQUEUR-MAL-FORME: $TR $NEW_GATE — retire check-old.sh devenu redondant avec lui  [segment « défaillance : » absent"

D="$(mk_repo vide)"; B="$(base_of "$D")"; printf 'x\n' > "$D/notes.txt"; commit_avec "$D" "docs: notes"
run O R "$SCRIPT" "$D" --strict --base-ref "$B"
expect "Rien d'ajouté dans la surface → RIEN-A-JUGER, rc 0" 0 "$R" "$O" "RIEN-A-JUGER"
run O R "$SCRIPT" "$D" --bogus
expect "Usage : argument inconnu → rc 64" 64 "$R" "$O"

echo "== test-check-ajout-retrait : MUTANTS (MUT-1 à MUT-9) =="
make_mutant() {  # <nom> <ancienne ligne> <nouvelle ligne> ; 0 = opposable, 1 = identique, 2 = syntaxe invalide
  local out="$MUTD/$1.sh"
  MUT_OLD_ENV="$2" MUT_NEW_ENV="$3" awk '{ if ($0 == ENVIRON["MUT_OLD_ENV"]) print ENVIRON["MUT_NEW_ENV"]; else print }' "$SCRIPT" > "$out"
  cmp -s "$out" "$SCRIPT" && return 1
  bash -n "$out" 2>/dev/null || return 2
  return 0
}
mutant() {  # <n> <ancienne> <nouvelle> <fixture> <args…> ; rc attendus : original $EO, mutant $EM
  local n="$1" old="$2" new="$3" d="$4" eo="$5" em="$6" mr; shift 6
  make_mutant "mut$n" "$old" "$new"; mr=$?
  if [ "$mr" -ne 0 ]; then komut "$n" "mutant opposable" "mutation appliquée et syntaxe valide" "statut make_mutant=$mr"; return; fi
  run O R "$SCRIPT" "$d" "$@"; run OM RM "$MUTD/mut$n.sh" "$d" "$@"
  if [ "$R" -eq "$eo" ] && [ "$RM" -eq "$em" ]; then okmut "$n" "$RM" "$em" "$R" "$eo"
  else komut "$n" "rc original=$eo, rc mutant=$em" "original=$eo mutant=$em" "original=$R mutant=$RM"; fi
}

# MUT-1 (A3) : une justification vide ou courte est acceptée.
D="$(mk_repo m1)"; B="$(base_of "$D")"; add_gate "$D"; commit_avec "$D" "feat: gate

$TR $NEW_GATE — aucun :$DF"
mutant 1 '      [ "$ok" -eq 1 ] && [ "$(charcount "$just")" -lt 10 ] && ok=0' '      :' "$D" 1 0 --strict --base-ref "$B"
# MUT-2 (A4) : les titres ADR sont ignorés.
D="$(mk_repo m2)"; B="$(base_of "$D")"; printf '## ADR-076 : neuf\n' >> "$D/docs/ADR.md"; commit_avec "$D" "docs: adr"
mutant 2 'net_excess "$TMPD/plus" "$TMPD/moins" | awk '"'"'NF { print $0 "\tadr" }'"'"' >> "$AJOUTS"' ':' "$D" 1 0 --strict --base-ref "$B"
# MUT-3 (A6) : une base introuvable est lue comme un succès sous --strict.
D="$(mk_repo m3)"; add_gate "$D"; commit_avec "$D" "feat: gate nu"
mutant 3 '  [ "$STRICT" -eq 1 ] && exit 2' '  :' "$D" 2 0 --strict --base-ref "ref-qui-n-existe-pas"
# MUT-4 (A8) : la portée des trailers est réduite au dernier commit.
D="$(mk_repo m4)"; B="$(base_of "$D")"; add_gate "$D"; commit_avec "$D" "feat: gate nu"
git_c "$D" commit -q --allow-empty -m "docs: couverture

$TR $NEW_GATE — aucun : ajout couvert après coup par un commit de documentation$DF" >/dev/null
git_c "$D" commit -q --allow-empty -m "chore: dernier commit sans trailer" >/dev/null
mutant 4 'COMMITS_LIST="$(git rev-list "${BASE}..${HEAD_SHA}" 2>/dev/null)"' 'COMMITS_LIST="$(git rev-list -1 "${HEAD_SHA}" 2>/dev/null)"' "$D" 0 1 --strict --base-ref "$B"
# MUT-5 : le défaut consultatif devient bloquant (rc 1 sans --strict).
D="$(mk_repo m5)"; B="$(base_of "$D")"; add_gate "$D"; commit_avec "$D" "feat: gate nu"
mutant 5 '[ "$STRICT" -eq 1 ] && exit 1' 'exit 1' "$D" 0 1 --base-ref "$B"

# MUT-6 (A10, m2) : le retrait visible ne compense plus rien.
D="$(mk_repo m6)"; B="$(base_of "$D")"; add_gate_distinct "$D"; git_c "$D" rm -q plugin/conductor/scripts/check-old.sh; commit_avec "$D" "feat: gate qui remplace check-old"
mutant 6 '  ($2 in r) && r[$2] > 0 { r[$2]--; print $0 > cf; next }' '  ($2 in r) && r[$2] > 99 { r[$2]--; print $0 > cf; next }' "$D" 0 1 --strict --base-ref "$B"
# MUT-7 (A11, m3) : n'importe quel glob est admis.
D="$(mk_repo m7)"; B="$(base_of "$D")"; add_gate "$D"; commit_avec "$D" "feat: gate

$TR * — aucun : motif volontairement trop large pour tout couvrir d'un coup$DF"
mutant 7 '  [ "${#lit}" -ge 6 ]' '  true' "$D" 1 0 --strict --base-ref "$B"
# MUT-8 (A9, m1) : les puces de CLAUDE.md ne sont plus lues.
D="$(mk_repo m8)"; B="$(base_of "$D")"; printf -- '- Une règle neuve en puce, sans titre.\n' >> "$D/CLAUDE.md"; commit_avec "$D" "docs: puce"
mutant 8 '    l ~ /^- / { sub(/^- /, "", l); print l; next }' '    l ~ /^- / { next }' "$D" 1 0 --strict --base-ref "$B"
# MUT-9 (A10c, m2) : dans CLAUDE.md, le retrait ne compense plus l'ajout (seul l'ajout est compté).
D="$(mk_repo m9)"; B="$(base_of "$D")"; printf '# Titre\n## Règle remplacée\ntexte\n' > "$D/CLAUDE.md"; commit_avec "$D" "docs: remplace une règle"
mutant 9 '  n="$(awk '"'"'END { print NR }'"'"' "$TMPD/po")"; m="$(awk '"'"'END { print NR }'"'"' "$TMPD/mo")"; ex=$((n - m))' '  n="$(awk '"'"'END { print NR }'"'"' "$TMPD/po")"; m="$(awk '"'"'END { print NR }'"'"' "$TMPD/mo")"; ex=$n' "$D" 0 1 --strict --base-ref "$B"

echo
echo "Résultat : $PASS vert(s), $FAIL rouge(s)"
[ "$FAIL" -eq 0 ]
