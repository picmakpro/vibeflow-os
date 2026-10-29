#!/usr/bin/env bash
# test-registres-role.sh — Suite du champ `**Role**` des entrées de registres (Phase 61, COLB-06, P61-D-07).
#
# Le champ dit QUI a écrit l'entrée (poste : solo | product | dev), « rien de plus ». Il est OPTIONNEL en
# lecture : une entrée ancienne sans le champ reste valide pour tous les parseurs, et une entrée qui le porte
# est lue comme avant. Aucun parseur n'est modifié ; cette suite le PROUVE en comparant la sortie de chaque
# consommateur sur un registre AVEC le champ et sur le même registre SANS (numéros de ligne normalisés).
#
# RRO-TPL                 — gabarits : exactement une ligne `**Role** :` (source ET copies), après le dernier champ,
#                           identique à l'octet partout, qui nomme `vf-role.sh get` et « jamais solo » ; les copies
#                           gardent leur bandeau SYNC et la ligne « Index maintenu par la machine »
# RRO-VALEUR              — `vf-role.sh get` rend la valeur (rc 0) ; invalide (rc 1) ou illisible (rc 5) : sortie vide,
#                           jamais `solo` ; l'entrée n'écrit la ligne que sur rc 0
# RRO-CHECK               — check-registres.sh : registre mixte / tout avec / sans champ → rc 0, même sortie
# RRO-REINDEX             — reindex.sh --audit, --dry-run, --apply : mêmes compteurs, même Resume NON VIDE, jamais `Role`
#                           dans un Resume, même index après --apply (trois registres)
# RRO-ARCHIVE             — archive.sh --dry-run : mêmes candidats avec et sans champ
# RRO-DUP                 — detect-duplicates.sh : même sortie (collision d'ID et titres proches)
# RRO-PROMO               — detect-promotions.sh : mêmes candidats
# RRO-SEED                — seed-registres.sh depuis les copies : check-registres --strict rc 0, squelette portant la ligne
# RRO-COMPARATEUR-TEMOIN  — le comparateur rend « différent » sur deux registres dont une entrée diffère par son Statut
# RRO-TEMOIN-REINDEX      — mutant de reindex.sh (fenêtre d'extraction du Resume réduite) : RRO-REINDEX rougit sur le
#                           mutant, vert sur l'original
#
# Fixtures écrites à l'exécution dans un dossier jetable, noms génériques. Aucun parseur modifié. Portabilité ADR-054
# (bash 3.2, mawk, coreutils uutils) : `cmp -s`, jamais `diff` ; comptage par awk.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$TESTS_DIR/.." && pwd)"
MODULE="$(cd "$SCRIPTS/.." && pwd)"
PLUGIN="$(cd "$MODULE/.." && pwd)"
ROLE="$PLUGIN/conductor/scripts/vf-role.sh"
SRC_DIR="$PLUGIN/reference/content/methodology/templates/memory"
CPY_DIR="$MODULE/references/templates-memoire"
CHECK="$SCRIPTS/check-registres.sh"
REINDEX="$SCRIPTS/reindex.sh"

pass=0; fail=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  - SKIP $1"; }

echo "== test-registres-role (consolidator: $MODULE) =="

# Environnement du lab jetable : aucune variable héritée ne doit déplacer un registre ou le poste.
unset MEMORY_DIR ARCHIVE_DIR ALLOWLIST LOCK_DIR LOG_FILE VF_ROLE VF_LAB_PROFILE VF_NO_AUTO_SEED RULES_DIR \
      VIBEFLOW_REGISTERS_CONF VF_BACKUP_KEEP VF_ARCHIVE_BG CLAUDE_PROJECT_DIR

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Borne de durée (perl absent : exécution directe).
bounded() {
  if command -v perl >/dev/null 2>&1; then perl -e 'alarm 120; exec @ARGV' "$@"; else "$@"; fi
}

# ---------- Fabrique des registres (écrits à l'exécution, noms génériques) ----------
# mk_sans <lab> <REG> : registre de deux entrées (trois pour LEARNINGS), index canonique v2 refermé par `---`.
mk_sans() {
  local d="$1/.claude/memory" reg="$2"
  mkdir -p "$d"
  case "$reg" in
    DECISIONS) cat > "$d/DECISIONS.md" <<'EOF'
# Registre des Decisions

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| DEC-002 | 2026-02-10 | Seconde decision | 24 | Texte du probleme deux. |
| DEC-001 | 2026-01-10 | Premiere decision | 12 | Texte du probleme un. |

---

## DEC-001 : Premiere decision

**Date** : 2026-01-10
**Statut** : Validee
**Decideur** : Lead Agent
**Contexte** : Phase 1
**Thinking Level** : think

### Probleme
Texte du probleme un.

### Decision
Option A.

## DEC-002 : Seconde decision

**Date** : 2026-02-10
**Statut** : Validee
**Decideur** : Lead Agent
**Contexte** : Phase 2
**Thinking Level** : think hard

### Probleme
Texte du probleme deux.

### Decision
Option B.
EOF
    ;;
    LEARNINGS) cat > "$d/LEARNINGS.md" <<'EOF'
# Registre des Learnings

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| LRN-003 | 2026-03-10 | Documenter le poste dans chaque entree | 36 | Un poste documente evite les doutes. |
| LRN-002 | 2026-02-10 | Eviter le grep sur les registres | 24 | Un grep sur le registre entier coute cher. |
| LRN-001 | 2026-01-10 | Toujours verifier le cache avant la release | 12 | Verifier le cache evite une release perimee. |

---

## LRN-001 : Toujours verifier le cache avant la release

**Date** : 2026-01-10
**Categorie** : Process
**Decouvert lors de** : Phase 1
**Encode dans** : [Non encode]

### Apprentissage
Verifier le cache evite une release perimee.

## LRN-002 : Eviter le grep sur les registres

**Date** : 2026-02-10
**Categorie** : Process
**Decouvert lors de** : Phase 2
**Encode dans** : [Non encode]

### Apprentissage
Un grep sur le registre entier coute cher.

## LRN-003 : Documenter le poste dans chaque entree

**Date** : 2026-03-10
**Categorie** : Process
**Decouvert lors de** : Phase 3
**Encode dans** : [Non encode]

### Apprentissage
Un poste documente evite les doutes.
EOF
    ;;
    BLOCKERS) cat > "$d/BLOCKERS.md" <<'EOF'
# Registre des Blockers

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| BLK-002 | 2020-04-01 | Second obstacle | 26 | Le second symptome. |
| BLK-001 | 2020-03-01 | Premier obstacle | 12 | Le premier symptome. |

---

## BLK-001 : Premier obstacle

**Date** : 2020-03-01
**Sprint** : Sprint 1
**Statut** : Resolu
**Temps Perdu** : 2h
**Severite** : Moyenne
**Source** : Lead Agent
**Learning associe** : [A creer]

### Symptome
Le premier symptome.

### Cause Racine
Cause un.

## BLK-002 : Second obstacle

**Date** : 2020-04-01
**Sprint** : Sprint 2
**Statut** : Resolu
**Temps Perdu** : 1h
**Severite** : Basse
**Source** : Lead Agent
**Learning associe** : [A creer]

### Symptome
Le second symptome.

### Cause Racine
Cause deux.
EOF
    ;;
  esac
}

# mk_dup <lab> : ajoute à LEARNINGS une quatrième entrée qui reprend l'ID LRN-001 (collision) avec un titre proche.
mk_dup() {
  cat >> "$1/.claude/memory/LEARNINGS.md" <<'EOF'

## LRN-001 : Toujours verifier le cache avant le deploiement

**Date** : 2026-03-20
**Categorie** : Process
**Decouvert lors de** : Phase 3
**Encode dans** : [Non encode]

### Apprentissage
Verifier le cache evite un deploiement perime.
EOF
}

# with_role <sans> <avec> <ligne> [max] : copie <sans> vers <avec> en insérant <ligne> après le dernier champ
# `**Champ** : valeur` de chaque entrée (au plus <max> entrées), rien d'autre.
with_role() {
  ROLE_LINE="$3" MAXN="${4:-99}" awk '
    BEGIN { l = ENVIRON["ROLE_LINE"]; m = ENVIRON["MAXN"] + 0; n = 0 }
    /^\*\*[^*]+\*\* :/ { infield = 1; print; next }
    { if (infield && n < m) { print l; n++ } infield = 0; print }
  ' "$1" > "$2"
}

# fixture_pair <REG> <dossier> [dup] : <dossier>/sans et <dossier>/avec, deux labs identiques au champ près.
fixture_pair() {
  local reg="$1" d="$2" dup="${3:-}"
  rm -rf "$d"; mkdir -p "$d/sans" "$d/avec/.claude/memory"
  mk_sans "$d/sans" "$reg"
  [ "$dup" = dup ] && mk_dup "$d/sans"
  with_role "$d/sans/.claude/memory/$reg.md" "$d/avec/.claude/memory/$reg.md" "$ROLE_LINE"
}

# ---------- Comparateur : retire les numéros de ligne et les horodatages, puis compare par cmp -s ----------
norm() {
  awk -F'|' -v OFS='|' '
    /"timestamp":/ { next }
    { gsub(/"line":[0-9]+/, "\"line\":0"); gsub(/"lines": "[^"]*"/, "\"lines\": \"N\"") }
    { sub(/^[^ ]+ \[archive\.sh\]/, "[archive.sh]"); gsub(/\([0-9]+ j\)/, "(N j)") }
    /^\| (DEC|LRN|BLK)-[0-9]+ / { if ($5 ~ /^ *[0-9]+ *$/) $5 = " N " }
    { print }
  ' "$1"
}
# same_output <sortie avec> <sortie sans> : 0 si identiques une fois normalisées.
same_output() {
  norm "$1" > "$1.norm"; norm "$2" > "$2.norm"
  cmp -s "$1.norm" "$2.norm"
}

# ---------- Lecteur du poste ----------
# role_line <lab> : imprime `**Role** : <poste>` UNIQUEMENT quand `vf-role.sh get` rend 0 (jamais `solo` par défaut).
role_line() {
  local out rc
  out="$(env -u VF_ROLE bash "$ROLE" get --path "$1" 2>/dev/null </dev/null)"; rc=$?
  if [ "$rc" -eq 0 ]; then printf '**Role** : %s\n' "$out"; fi
  return 0
}

# ======================================================================================================
# RRO-VALEUR — la valeur vient de `vf-role.sh get`, jamais d'un repli sur solo
# ======================================================================================================
ROLE_LINE=""
if [ -f "$ROLE" ]; then
  P="$WORK/poste"; mkdir -p "$P/.claude"
  printf 'product\n' > "$P/.claude/vibeflow-role"
  out="$(env -u VF_ROLE bash "$ROLE" get --path "$P" 2>/dev/null </dev/null)"; rc=$?
  if [ "$rc" -eq 0 ] && [ "$out" = "product" ]; then
    ok "RRO-VALEUR get rend « product » (rc 0) quand le fichier de poste vaut product"
  else
    ko "RRO-VALEUR get : attendu product / rc 0, obtenu « $out » / rc $rc"
  fi
  ROLE_LINE="$(role_line "$P")"

  I="$WORK/poste-invalide"; mkdir -p "$I/.claude"; printf 'admin\n' > "$I/.claude/vibeflow-role"
  out="$(env -u VF_ROLE bash "$ROLE" get --path "$I" 2>/dev/null </dev/null)"; rc=$?
  if [ "$rc" -eq 1 ] && [ -z "$out" ] && [ -z "$(role_line "$I")" ]; then
    ok "RRO-VALEUR valeur hors liste : rc 1, sortie vide, aucune ligne Role (jamais solo)"
  else
    ko "RRO-VALEUR valeur hors liste : attendu rc 1 / sortie vide / pas de ligne, obtenu rc $rc / « $out »"
  fi

  L="$WORK/poste-illisible"; mkdir -p "$L/.claude"
  awk 'BEGIN { for (i = 0; i < 70; i++) printf "a"; printf "\n" }' > "$L/.claude/vibeflow-role"
  out="$(env -u VF_ROLE bash "$ROLE" get --path "$L" 2>/dev/null </dev/null)"; rc=$?
  if [ "$rc" -eq 5 ] && [ -z "$out" ] && [ -z "$(role_line "$L")" ]; then
    ok "RRO-VALEUR poste illisible (> 64 octets) : rc 5, sortie vide, aucune ligne Role (jamais solo)"
  else
    ko "RRO-VALEUR poste illisible : attendu rc 5 / sortie vide / pas de ligne, obtenu rc $rc / « $out »"
  fi

  out="$(env -u VF_ROLE bash "$ROLE" get --bogus 2>/dev/null </dev/null)"; rc=$?
  if [ "$rc" -eq 64 ] && [ -z "$out" ]; then
    ok "RRO-VALEUR usage : rc 64, sortie vide"
  else
    ko "RRO-VALEUR usage : attendu rc 64 / sortie vide, obtenu rc $rc"
  fi
else
  skip "RRO-VALEUR (vf-role.sh absent : copie à plat du module)"
fi
# Valeur de repli pour les fixtures quand le lecteur est absent : la suite reste jouable, la ligne est la même.
[ -n "$ROLE_LINE" ] || ROLE_LINE='**Role** : product'

# ======================================================================================================
# RRO-TPL — les gabarits (volet source)
# ======================================================================================================
# anchor_of <t> : dernière ligne de champ attendue juste avant la ligne Role.
anchor_of() {
  case "$1" in
    decisions) echo '**Thinking Level** :' ;;
    learnings) echo '**Encode dans** :' ;;
    blockers)  echo '**Learning associe** :' ;;
  esac
}
# role_extract <fichier> : les lignes `**Role** :` du fichier.
role_extract() { awk '/^\*\*Role\*\* :/' "$1"; }
# tpl_checks <dossier> <étiquette> : une seule ligne Role par gabarit, bien placée, qui nomme sa source.
tpl_checks() {
  local dir="$1" label="$2" t f n anchor bad=0
  for t in decisions learnings blockers; do
    f="$dir/$t-template.md"
    [ -f "$f" ] || { ko "RRO-TPL $label/$t : gabarit absent ($f)"; continue; }
    n="$(awk '/^\*\*Role\*\* :/ { n++ } END { print n + 0 }' "$f")"
    anchor="$(anchor_of "$t")"
    # placement : la ligne qui précède Role commence par le dernier champ attendu, celle qui suit est vide
    place="$(awk -v a="$anchor" '
      /^\*\*Role\*\* :/ { found = 1; ok_prev = (index(prev, a) == 1); want_next = 1; prev = $0; next }
      want_next { ok_next = ($0 == ""); want_next = 0 }
      { prev = $0 }
      END { print (found && ok_prev && ok_next) ? "ok" : "ko" }' "$f")"
    if [ "$n" -eq 1 ] && [ "$place" = ok ] \
       && role_extract "$f" | awk 'index($0, "vf-role.sh get") && index($0, "jamais solo") { ok = 1 } END { exit !ok }'; then
      ok "RRO-TPL $label/$t : une ligne **Role**, après « $anchor », nomme vf-role.sh get et « jamais solo »"
    else
      ko "RRO-TPL $label/$t : ligne Role absente, multiple, mal placée ou sans la mention (n=$n, placement=$place)"
      bad=1
    fi
  done
  return $bad
}

if [ -d "$SRC_DIR" ]; then
  tpl_checks "$SRC_DIR" source
  # identité à l'octet des trois lignes de la source
  role_extract "$SRC_DIR/decisions-template.md" > "$WORK/role.decisions"
  role_extract "$SRC_DIR/learnings-template.md" > "$WORK/role.learnings"
  role_extract "$SRC_DIR/blockers-template.md"  > "$WORK/role.blockers"
  if [ -s "$WORK/role.decisions" ] && cmp -s "$WORK/role.decisions" "$WORK/role.learnings" && cmp -s "$WORK/role.decisions" "$WORK/role.blockers"; then
    ok "RRO-TPL source : les trois lignes **Role** sont identiques à l'octet"
  else
    ko "RRO-TPL source : les trois lignes **Role** diffèrent ou sont absentes"
  fi
else
  skip "RRO-TPL source (gabarits de reference absents : copie à plat du module)"
fi

# ======================================================================================================
# RRO-CHECK — check-registres.sh
# ======================================================================================================
CK="$WORK/check"; fixture_pair DECISIONS "$CK"
with_role "$CK/sans/.claude/memory/DECISIONS.md" "$CK/avec/.claude/memory/DECISIONS.md" "$ROLE_LINE"
mkdir -p "$CK/mixte/.claude/memory"
with_role "$CK/sans/.claude/memory/DECISIONS.md" "$CK/mixte/.claude/memory/DECISIONS.md" "$ROLE_LINE" 1
n_mixte="$(awk '/^\*\*Role\*\* :/ { n++ } END { print n + 0 }' "$CK/mixte/.claude/memory/DECISIONS.md")"
n_avec="$(awk '/^\*\*Role\*\* :/ { n++ } END { print n + 0 }' "$CK/avec/.claude/memory/DECISIONS.md")"
n_sans="$(awk '/^\*\*Role\*\* :/ { n++ } END { print n + 0 }' "$CK/sans/.claude/memory/DECISIONS.md")"
for v in sans avec mixte; do
  ( cd "$CK/$v" && bounded bash "$CHECK" --memory-dir=.claude/memory </dev/null ) > "$CK/$v.out" 2>&1
  echo "$?" > "$CK/$v.rc"
done
if [ "$n_sans" -eq 0 ] && [ "$n_avec" -eq 2 ] && [ "$n_mixte" -eq 1 ] \
   && [ "$(cat "$CK/sans.rc")" = 0 ] && [ "$(cat "$CK/avec.rc")" = 0 ] && [ "$(cat "$CK/mixte.rc")" = 0 ]; then
  ok "RRO-CHECK registre sans / tout avec / mixte (1 entrée sur 2) : rc 0 pour les trois"
else
  ko "RRO-CHECK rc attendus 0/0/0, obtenus sans=$(cat "$CK/sans.rc") avec=$(cat "$CK/avec.rc") mixte=$(cat "$CK/mixte.rc") (Role : $n_sans/$n_avec/$n_mixte)"
fi
if same_output "$CK/avec.out" "$CK/sans.out" && same_output "$CK/mixte.out" "$CK/sans.out"; then
  ok "RRO-CHECK même sortie avec, sans et mixte"
else
  ko "RRO-CHECK la sortie de check-registres change avec le champ"
fi

# ======================================================================================================
# RRO-REINDEX — reindex.sh : audit, dry-run, apply (trois registres). Sonde réutilisée par le témoin de mutation.
# ======================================================================================================
LASTMSG=""
# reindex_probe <REG> : 0 si, avec $TARGET, audit/dry-run/apply rendent la même chose avec et sans le champ,
# avec un Resume NON VIDE (deux entrées) et sans jamais citer Role dans un Resume.
reindex_probe() {
  local reg="$1" d="$WORK/rx-$reg" v mode n want
  fixture_pair "$reg" "$d"
  for v in sans avec; do
    for mode in audit dry-run; do
      ( cd "$d/$v" && MEMORY_DIR=.claude/memory bounded bash "$TARGET" --register="$reg" "--$mode" </dev/null ) > "$d/$v.$mode.out" 2>&1
    done
    # --apply sur une copie du lab (backups hors de la comparaison)
    rm -rf "$d/$v-apply"; cp -R "$d/$v" "$d/$v-apply"
    ( cd "$d/$v-apply" && MEMORY_DIR=.claude/memory bounded bash "$TARGET" --register="$reg" --apply </dev/null ) > "$d/$v.apply.out" 2>&1
    awk '/^## Index/ { f = 1 } f { print } f && /^---$/ { exit }' "$d/$v-apply/.claude/memory/$reg.md" > "$d/$v.index"
  done
  want=2; [ "$reg" = LEARNINGS ] && want=3
  for v in sans avec; do
    n="$(awk '/"resume":"[^"]/ { n++ } END { print n + 0 }' "$d/$v.dry-run.out")"
    if [ "$n" -ne "$want" ]; then LASTMSG="$reg ($v) : Resume non vide attendu pour $want entrées, obtenu $n"; return 1; fi
  done
  if awk '/"resume":"/ && /Role/ { f = 1 } END { exit !f }' "$d/avec.dry-run.out"; then
    LASTMSG="$reg : « Role » figure dans un Resume"; return 1
  fi
  if ! same_output "$d/avec.audit.out" "$d/sans.audit.out"; then LASTMSG="$reg : --audit diffère avec le champ"; return 1; fi
  if ! same_output "$d/avec.dry-run.out" "$d/sans.dry-run.out"; then LASTMSG="$reg : --dry-run diffère avec le champ"; return 1; fi
  n="$(awk '/^\| (DEC|LRN|BLK)-[0-9]+ / { n++ } END { print n + 0 }' "$d/avec.index")"
  if [ "$n" -ne "$want" ]; then LASTMSG="$reg : index après --apply : $n entrée(s) au lieu de $want"; return 1; fi
  if ! same_output "$d/avec.index" "$d/sans.index"; then LASTMSG="$reg : index après --apply diffère avec le champ"; return 1; fi
  LASTMSG="audit, dry-run (Resume non vide) et index après --apply identiques"
  return 0
}
probe_reindex_dec() { reindex_probe DECISIONS; }

TARGET="$REINDEX"
for reg in DECISIONS LEARNINGS BLOCKERS; do
  if reindex_probe "$reg"; then ok "RRO-REINDEX $reg : $LASTMSG"; else ko "RRO-REINDEX $reg : $LASTMSG"; fi
done

#<STAGE2>

echo "== resultat : $pass ok, $fail ko =="
[ "$fail" -eq 0 ]
