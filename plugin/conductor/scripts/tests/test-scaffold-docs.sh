#!/usr/bin/env bash
# test-scaffold-docs.sh — Suite de vérification de scaffold-docs.sh (G2, plan 29-04).
#
# Première suite de ce script : elle couvre à la fois le comportement préexistant (les quatre
# stubs INDEX.md/REFERENCE.md par compartiment) et l'extension G2 (CONTEXT.md de routage,
# _index.md de dossier de références). Un cas par comportement, chaque cas dans son propre
# répertoire temporaire, stdout/stderr et code de retour capturés séparément — jamais une
# assertion combinée qui déduit l'un de l'autre.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scaffold-docs.sh"

PASS=0; FAIL=0
ok() { echo "  + $1"; PASS=$((PASS+1)); }
ko() { echo "  x $1 -- $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

newcase() { # <name> -> imprime le chemin d'un répertoire de travail vierge
  local d="$TMP/$1"
  mkdir -p "$d" || { echo "  x FIXTURE -- mkdir $d impossible" >&2; exit 1; }
  printf '%s' "$d"
}

# ============================================================================
# Tâche 1 — CONTEXT.md de compartiment, et non-régression du comportement d'hier
# ============================================================================

# Cas 1 — transverse : une invocation sans compartiment pose docs/_transverse/CONTEXT.md.
d="$(newcase case1)"
(cd "$d" && bash "$SCRIPT" >/dev/null 2>&1)
if [ -f "$d/docs/_transverse/CONTEXT.md" ]; then
  ok "transverse : CONTEXT.md posé sans compartiment"
else
  ko "transverse : CONTEXT.md posé sans compartiment" "absent"
fi

# Cas 2 — compartiment : scaffold-docs.sh projet-a pose docs/projet-a/CONTEXT.md.
d="$(newcase case2)"
(cd "$d" && bash "$SCRIPT" projet-a >/dev/null 2>&1)
if [ -f "$d/docs/projet-a/CONTEXT.md" ]; then
  ok "compartiment : CONTEXT.md posé pour projet-a"
else
  ko "compartiment : CONTEXT.md posé pour projet-a" "absent"
fi

# Cas 3 — borne de taille : le CONTEXT.md transverse compte au plus 80 lignes.
d="$(newcase case3)"
(cd "$d" && bash "$SCRIPT" >/dev/null 2>&1)
n="$(wc -l < "$d/docs/_transverse/CONTEXT.md" | tr -d ' ')"
if [ "$n" -le 80 ]; then
  ok "borne 80 lignes : transverse ($n lignes)"
else
  ko "borne 80 lignes : transverse" "obtenu=$n lignes, attendu <= 80"
fi

# Cas 4 — borne de taille : le CONTEXT.md de compartiment compte au plus 80 lignes.
d="$(newcase case4)"
(cd "$d" && bash "$SCRIPT" projet-a >/dev/null 2>&1)
n="$(wc -l < "$d/docs/projet-a/CONTEXT.md" | tr -d ' ')"
if [ "$n" -le 80 ]; then
  ok "borne 80 lignes : compartiment ($n lignes)"
else
  ko "borne 80 lignes : compartiment" "obtenu=$n lignes, attendu <= 80"
fi

# Cas 5 — corps de routage : la table Tâche/Charge/NE charge PAS est présente avec au moins une
# ligne d'amorce, sans contenu de fond inliné.
d="$(newcase case5)"
(cd "$d" && bash "$SCRIPT" projet-a >/dev/null 2>&1)
n="$(grep -c 'NE charge PAS' "$d/docs/projet-a/CONTEXT.md" || true)"
if [ "$n" -ge 1 ]; then
  ok "corps de routage : table Tâche/Charge/NE charge PAS présente"
else
  ko "corps de routage : table Tâche/Charge/NE charge PAS présente" "grep -c=$n, attendu >= 1"
fi

# Cas 6 — idempotence (nouveau) : relancé sur un CONTEXT.md déjà posé avec un contenu arbitraire,
# le script ne le modifie pas. Comparaison octet, jamais diff.
d="$(newcase case6)"
mkdir -p "$d/docs/projet-a"
printf 'contenu arbitraire rédigé à la main\n' > "$d/docs/projet-a/CONTEXT.md"
cp "$d/docs/projet-a/CONTEXT.md" "$TMP/case6-avant.md"
(cd "$d" && bash "$SCRIPT" projet-a >/dev/null 2>&1)
if cmp -s "$TMP/case6-avant.md" "$d/docs/projet-a/CONTEXT.md"; then
  ok "idempotence : CONTEXT.md existant conservé à l'octet"
else
  ko "idempotence : CONTEXT.md existant conservé à l'octet" "le fichier a changé"
fi

# Cas 7 — non-régression transverse : INDEX.md et REFERENCE.md transverses toujours posés.
d="$(newcase case7)"
(cd "$d" && bash "$SCRIPT" >/dev/null 2>&1)
if [ -f "$d/docs/_transverse/INDEX.md" ] && [ -f "$d/docs/_transverse/REFERENCE.md" ]; then
  ok "non-régression : INDEX.md + REFERENCE.md transverses toujours posés"
else
  ko "non-régression : INDEX.md + REFERENCE.md transverses toujours posés" "au moins un des deux est absent"
fi

# Cas 8 — non-régression par compartiment : INDEX.md et REFERENCE.md du compartiment toujours posés.
d="$(newcase case8)"
(cd "$d" && bash "$SCRIPT" projet-a >/dev/null 2>&1)
if [ -f "$d/docs/projet-a/INDEX.md" ] && [ -f "$d/docs/projet-a/REFERENCE.md" ]; then
  ok "non-régression : INDEX.md + REFERENCE.md de compartiment toujours posés"
else
  ko "non-régression : INDEX.md + REFERENCE.md de compartiment toujours posés" "au moins un des deux est absent"
fi

# Cas 9 — coexistence : INDEX.md pointe vers CONTEXT.md, sans que les deux se lisent comme des
# doublons (rôles distincts nommés dans les deux fichiers).
d="$(newcase case9)"
(cd "$d" && bash "$SCRIPT" projet-a >/dev/null 2>&1)
n="$(grep -c 'CONTEXT.md' "$d/docs/projet-a/INDEX.md" || true)"
if [ "$n" -ge 1 ]; then
  ok "coexistence : INDEX.md pointe vers CONTEXT.md"
else
  ko "coexistence : INDEX.md pointe vers CONTEXT.md" "grep -c=$n, attendu >= 1"
fi

# Cas 10 — compartiment vide ignoré : un argument vide n'entraîne aucune création.
d="$(newcase case10)"
(cd "$d" && bash "$SCRIPT" "" >/dev/null 2>&1)
if [ ! -d "$d/docs" ] || [ "$(ls "$d/docs" 2>/dev/null | wc -l | tr -d ' ')" = "1" ]; then
  ok "compartiment vide ignoré : aucun dossier créé au-delà du transverse"
else
  ko "compartiment vide ignoré : aucun dossier créé au-delà du transverse" "docs/ contient un dossier inattendu"
fi

# Cas 11 — --docs-dir (forme séparée) : les nouveaux stubs vont sous le dossier demandé.
d="$(newcase case11)"
(cd "$d" && bash "$SCRIPT" --docs-dir documentation projet-a >/dev/null 2>&1)
if [ -f "$d/documentation/projet-a/CONTEXT.md" ]; then
  ok "--docs-dir (séparé) : CONTEXT.md sous le dossier demandé"
else
  ko "--docs-dir (séparé) : CONTEXT.md sous le dossier demandé" "absent"
fi

# Cas 12 — --docs-dir= (forme accolée) : idem.
d="$(newcase case12)"
(cd "$d" && bash "$SCRIPT" --docs-dir=documentation projet-a >/dev/null 2>&1)
if [ -f "$d/documentation/projet-a/CONTEXT.md" ]; then
  ok "--docs-dir= (accolé) : CONTEXT.md sous le dossier demandé"
else
  ko "--docs-dir= (accolé) : CONTEXT.md sous le dossier demandé" "absent"
fi

# Cas 13 — argument inconnu : sort 2 (convention interne du fichier, inchangée).
d="$(newcase case13)"
rc=0
(cd "$d" && bash "$SCRIPT" --flag-inconnu >/dev/null 2>&1) || rc=$?
if [ "$rc" -eq 2 ]; then
  ok "argument inconnu : sort 2"
else
  ko "argument inconnu : sort 2" "rc=$rc"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
