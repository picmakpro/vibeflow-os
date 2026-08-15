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

# ============================================================================
# Tâche 2 — pattern _index.md : stub posable + application réelle
# ============================================================================

# Cas 14 — --index <dossier> pose <dossier>/_index.md.
d="$(newcase case14)"
mkdir -p "$d/refs"
(cd "$d" && bash "$SCRIPT" --index refs >/dev/null 2>&1)
if [ -f "$d/refs/_index.md" ]; then
  ok "--index (séparé) : _index.md posé"
else
  ko "--index (séparé) : _index.md posé" "absent"
fi

# Cas 15 — --index=<dossier> (forme accolée) : idem.
d="$(newcase case15)"
mkdir -p "$d/refs"
(cd "$d" && bash "$SCRIPT" --index=refs >/dev/null 2>&1)
if [ -f "$d/refs/_index.md" ]; then
  ok "--index= (accolé) : _index.md posé"
else
  ko "--index= (accolé) : _index.md posé" "absent"
fi

# Cas 16 — --index sans valeur : sort 2.
d="$(newcase case16)"
rc=0
(cd "$d" && bash "$SCRIPT" --index >/dev/null 2>&1) || rc=$?
if [ "$rc" -eq 2 ]; then
  ok "--index sans valeur : sort 2"
else
  ko "--index sans valeur : sort 2" "rc=$rc"
fi

# Cas 17 — --index sur un dossier inexistant : sort 2, échec ATOMIQUE — y compris aucun stub
# transverse posé (l'argument --index est validé avant toute écriture).
d="$(newcase case17)"
rc=0
(cd "$d" && bash "$SCRIPT" --index absent-du-tout >/dev/null 2>&1) || rc=$?
if [ "$rc" -eq 2 ] && [ ! -e "$d/absent-du-tout" ] && [ ! -e "$d/docs" ]; then
  ok "--index sur dossier inexistant : sort 2, rien créé (y compris docs/_transverse/)"
else
  ko "--index sur dossier inexistant : sort 2, rien créé (y compris docs/_transverse/)" \
    "rc=$rc, existe=$([ -e "$d/absent-du-tout" ] && echo oui || echo non), docs/=$([ -e "$d/docs" ] && echo oui || echo non)"
fi

# Cas 17b — nom à tiret initial : rejeté par le parseur d'arguments (branche -*), exit 2, rien créé.
# Couvre T-29-04-02 du threat model du plan (mitigation revendiquée mais absente jusqu'ici).
d="$(newcase case17b)"
rc=0
(cd "$d" && bash "$SCRIPT" -evilname >/dev/null 2>&1) || rc=$?
if [ "$rc" -eq 2 ] && [ ! -e "$d/docs" ]; then
  ok "nom à tiret initial (-evilname) : rejeté par le parseur, exit 2, rien créé"
else
  ko "nom à tiret initial (-evilname) : rejeté par le parseur, exit 2, rien créé" \
    "rc=$rc, docs/=$([ -e "$d/docs" ] && echo oui || echo non)"
fi

# Cas 17c — nom de compartiment à espace : chemin quoté de bout en bout, les trois stubs
# atterrissent sous un seul dossier "projet a" (pas de découpe en "projet" + "a").
# Couvre T-29-04-02 du threat model du plan (mitigation revendiquée mais absente jusqu'ici).
d="$(newcase case17c)"
(cd "$d" && bash "$SCRIPT" "projet a" >/dev/null 2>&1)
if [ -f "$d/docs/projet a/CONTEXT.md" ] && [ -f "$d/docs/projet a/INDEX.md" ] && [ -f "$d/docs/projet a/REFERENCE.md" ] && [ ! -e "$d/docs/projet" ]; then
  ok "nom à espace (\"projet a\") : les trois stubs sous un seul dossier, chemin non découpé"
else
  ko "nom à espace (\"projet a\") : les trois stubs sous un seul dossier, chemin non découpé" \
    "docs/projet a/CONTEXT.md=$([ -f "$d/docs/projet a/CONTEXT.md" ] && echo oui || echo non), docs/projet=$([ -e "$d/docs/projet" ] && echo oui || echo non)"
fi

# Cas 18 — le stub _index.md ne s'auto-liste pas.
d="$(newcase case18)"
mkdir -p "$d/refs"
(cd "$d" && bash "$SCRIPT" --index refs >/dev/null 2>&1)
n="$(grep -c '_index.md' "$d/refs/_index.md" || true)"
if [ "$n" -eq 0 ]; then
  ok "_index.md ne s'auto-liste pas"
else
  ko "_index.md ne s'auto-liste pas" "grep -c=$n, attendu 0"
fi

# Cas 19 — sous le seuil : le flag reste utilisable sur un dossier < 11 fichiers, mais le journal
# signale que le seuil n'est pas franchi.
d="$(newcase case19)"
mkdir -p "$d/refs"
printf 'x\n' > "$d/refs/un-seul-fichier.md"
out="$(cd "$d" && bash "$SCRIPT" --index refs 2>&1)"
if [ -f "$d/refs/_index.md" ] && printf '%s' "$out" | grep -qi 'seuil'; then
  ok "sous le seuil : index posé quand même, journal signale le seuil non franchi"
else
  ko "sous le seuil : index posé quand même, journal signale le seuil non franchi" "index=$([ -f "$d/refs/_index.md" ] && echo oui || echo non), journal=[$out]"
fi

# Cas 20 — idempotence : un _index.md existant au contenu arbitraire survit à l'octet à une relance.
d="$(newcase case20)"
mkdir -p "$d/refs"
printf 'index rédigé à la main\n' > "$d/refs/_index.md"
cp "$d/refs/_index.md" "$TMP/case20-avant.md"
(cd "$d" && bash "$SCRIPT" --index refs >/dev/null 2>&1)
if cmp -s "$TMP/case20-avant.md" "$d/refs/_index.md"; then
  ok "idempotence : _index.md existant conservé à l'octet"
else
  ko "idempotence : _index.md existant conservé à l'octet" "le fichier a changé"
fi

# Cas 21 — forme du stub : titre, blockquote de rôle, table Fichier/Résumé avec ligne d'amorce.
d="$(newcase case21)"
mkdir -p "$d/refs"
(cd "$d" && bash "$SCRIPT" --index refs >/dev/null 2>&1)
n="$(grep -cE '^\| Fichier \| Résumé \|' "$d/refs/_index.md" || true)"
if [ "$n" -ge 1 ]; then
  ok "forme du stub _index.md : table Fichier/Résumé présente"
else
  ko "forme du stub _index.md : table Fichier/Résumé présente" "grep -c=$n, attendu >= 1"
fi

# Cas 22 — application réelle : plugin/dev-orchestrator/references/_index.md liste les 11 fichiers
# markdown du dossier réel du dépôt, avec un résumé d'une ligne chacun, et ne se liste pas.
REPO_ROOT="$(cd "$(dirname "$SCRIPT")/../../.." && pwd)"
REAL_INDEX="$REPO_ROOT/plugin/dev-orchestrator/references/_index.md"
if [ -f "$REAL_INDEX" ]; then
  nrows="$(grep -cE '^\| \[' "$REAL_INDEX" || true)"
  selflist="$(grep -c '_index.md' "$REAL_INDEX" || true)"
  if [ "$nrows" -eq 11 ] && [ "$selflist" -eq 0 ]; then
    ok "application réelle : _index.md de dev-orchestrator/references (11 lignes, pas d'auto-listage)"
  else
    ko "application réelle : _index.md de dev-orchestrator/references (11 lignes, pas d'auto-listage)" "nrows=$nrows, selflist=$selflist"
  fi
else
  ko "application réelle : _index.md de dev-orchestrator/references (11 lignes, pas d'auto-listage)" "fichier absent : $REAL_INDEX"
fi

# ============================================================================
# Tâche 3 — Bornes et vocabulaire, et garde .planning/ (ADR-055)
# ============================================================================

# Cas 23 — l'en-tête porte la section « Bornes et vocabulaire », nomme l'autre objet homonyme et
# distingue les deux noms d'index.
n_section="$(grep -c 'Bornes et vocabulaire' "$SCRIPT" || true)"
n_compartments_doc="$(grep -c 'compartments.md' "$SCRIPT" || true)"
n_index_md="$(grep -c 'INDEX.md' "$SCRIPT" || true)"
n_underscore_index="$(grep -c '_index.md' "$SCRIPT" || true)"
if [ "$n_section" -ge 1 ] && [ "$n_compartments_doc" -ge 1 ] && [ "$n_index_md" -ge 1 ] && [ "$n_underscore_index" -ge 1 ]; then
  ok "en-tête : section Bornes et vocabulaire, deux objets homonymes, deux noms d'index"
else
  ko "en-tête : section Bornes et vocabulaire, deux objets homonymes, deux noms d'index" \
    "section=$n_section, compartments.md=$n_compartments_doc, INDEX.md=$n_index_md, _index.md=$n_underscore_index"
fi

# Cas 24 — garde ADR-055 : aucune écriture sous un chemin .planning/. Fixture .planning/ factice,
# identique à l'octet après une exécution complète (compartiment + --index).
d="$(newcase case24)"
mkdir -p "$d/.planning/phases"
printf 'fixture .planning intouchable\n' > "$d/.planning/phases/FAKE.md"
cp "$d/.planning/phases/FAKE.md" "$TMP/case24-avant.md"
mkdir -p "$d/refs"
(cd "$d" && bash "$SCRIPT" --index refs projet-a >/dev/null 2>&1)
if cmp -s "$TMP/case24-avant.md" "$d/.planning/phases/FAKE.md" && [ ! -e "$d/.planning/docs" ]; then
  ok "garde ADR-055 : .planning/ intact à l'octet après exécution complète"
else
  ko "garde ADR-055 : .planning/ intact à l'octet après exécution complète" "la fixture .planning/ a bougé"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
