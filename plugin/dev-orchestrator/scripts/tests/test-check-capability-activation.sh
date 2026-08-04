#!/usr/bin/env bash
# test-check-capability-activation.sh — Suite de vérification de check-capability-activation.sh
# (Phase 24, plan 24-11 — GSDA-09).
#
# Ce que cette suite prouve, et pourquoi elle est bâtie ainsi.
#
# Le gate testé existe pour fermer un mode d'échec précis : une couverture verte qui masque un
# geste mort. Une suite qui ne vérifierait que l'état nominal reproduirait exactement ce mode
# d'échec un étage plus haut — elle serait verte parce qu'elle ne sait pas rougir. La discriminance
# est donc prouvée par MUTATION, dans les DEUX sens :
#   - retirer un marqueur conditionnel d'une entrée de doc dont le toggle est inactif → le gate
#     DOIT rougir (règle 2) ;
#   - activer le toggle d'une entrée qui porte encore son marqueur → le gate DOIT rougir aussi
#     (règle 3). Sans cette seconde mutation, le gate ne serait discriminant que dans un sens.
#
# Règle absolue héritée de `test-check-gsd-config.sh` : une mutation doit avoir CHANGÉ le fichier,
# constaté par `cmp` et JAMAIS par `diff` (le `diff` de ce poste est proxifié et ment). Un motif de
# mutation introuvable rend le mutant NON OPPOSABLE — un échec, jamais un succès silencieux.
#
# Toutes les fixtures sont SYNTHÉTIQUES et vivent dans un `mktemp -d` nettoyé par `trap` : l'arbre
# réel bougera (l'index est régénéré à chaque évolution du moteur), une suite ancrée dessus se
# périmerait. Le seul cas ancré sur l'arbre réel est un contrôle final, explicitement NON
# discriminant, placé APRÈS les mutations et jamais à leur place.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-capability-activation.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- Fabriques de fixtures ---------------------------------------------------------------------
# L'index synthétique reproduit les DEUX arités de table de l'index réel : la table par point de
# hook (5 colonnes) et la table des capabilities hors point de hook (3 colonnes, colonne « Rôle »
# incluse). Une fixture qui n'aurait que l'une des deux laisserait la moitié du parseur non testée.
mk_index() { # <chemin>
  cat > "$1" <<'IDX'
# GSD Capabilities Index (auto-généré — NE PAS ÉDITER)

## `plan:pre`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `demo-stage` | step | `workflow.demo_stage` | — | `skip` |
| `sans-cle` | step | — | — | `skip` |

## Capabilities hors point de hook

| Capability | Rôle | Clé de configuration gouvernante |
|---|---|---|
| `demo` | feature | `demo.enabled` |
| `autre` | feature | `autre.enabled` |
| `un-runtime` | runtime | — |
IDX
}

# Configuration synthétique : `demo.enabled` PRÉSENT à false (inactivité déclarée) et
# `workflow.demo_stage` ABSENT (inactivité par défaut) — les deux formes d'inactivité que la
# règle 2 doit traiter identiquement.
mk_config() { # <chemin>
  cat > "$1" <<'CFG'
{
  "demo": {
    "enabled": false
  },
  "workflow": {
    "autre_chose": true
  }
}
CFG
}

# Corpus conforme : chaque toggle inactif est cité, mais UNIQUEMENT sous marqueur.
#
# DEUX marqueurs, et c'est délibéré — le corpus réel en porte trois. Avec un seul, retirer LE
# marqueur viderait M et ferait sortir le plancher de la règle 1 (« non vérifiable », 2) AVANT que
# la règle 2 puisse voir la promesse démarquée : la mutation aurait prouvé le plancher, pas la
# règle qu'elle vise. Le gate reste rouge dans les deux cas — jamais vert — mais un mutant qui
# rougit pour la mauvaise raison ne prouve rien.
mk_corpus_ok() { # <chemin>
  cat > "$1" <<'DOC'
# Carte de routage synthétique

| intention | brique |
|---|---|
| faire la démo | `gsd-demo` (conditionnelle : demo.enabled) — refusée, aucun consommateur prescrit |
| faire autre chose | `gsd-autre` (conditionnelle : autre.enabled) — refusée, aucun consommateur prescrit |
DOC
}

run() { # <fixture-dir> [args...] -> imprime stderr, rend le rc du gate
  local d="$1"; shift
  VF_CAPACT_INDEX="$d/index.md" \
  VF_CAPACT_CONFIG="$d/config.json" \
  VF_CAPACT_CORPUS="$d/corpus.md" \
  bash "$SCRIPT" "$@" 2>&1 >/dev/null
}

rc_of() { # <fixture-dir> [args...] -> rend le rc du gate, sortie muette
  local d="$1"; shift
  VF_CAPACT_INDEX="$d/index.md" \
  VF_CAPACT_CONFIG="$d/config.json" \
  VF_CAPACT_CORPUS="$d/corpus.md" \
  bash "$SCRIPT" "$@" >/dev/null 2>&1
  echo "$?"
}

mk_fixture() { # <nom> -> imprime le chemin ; état conforme complet
  local d="$TMP/$1"
  mkdir -p "$d"
  mk_index "$d/index.md"
  mk_config "$d/config.json"
  mk_corpus_ok "$d/corpus.md"
  printf '%s' "$d"
}

echo "== test-check-capability-activation =="

# === Cas 1 — état conforme : toggle inactif cité SOUS marqueur → 0 =============================
D="$(mk_fixture c1)"
rc="$(rc_of "$D")"
out="$(run "$D")"
has_universe=0; case "$out" in *"univers balaye"*) has_universe=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_universe" -eq 1 ]; then
  ok "1 conforme — toggle inactif cité sous marqueur → 0, et le rapport NOMME l'univers balayé"
else
  ko "1 conforme → 0 + univers nommé" "rc=$rc out=[$out]"
fi

# === Cas 2 — promesse non marquée : le même toggle inactif cité HORS marqueur → 1 ==============
# Le message doit nommer le toggle ET le fichier : un « écart constaté » anonyme est inactionnable.
D="$(mk_fixture c2)"
printf 'Le mode avancé dépend de demo.enabled et sera bientôt là.\n' >> "$D/corpus.md"
rc="$(rc_of "$D")"
out="$(run "$D")"
names_toggle=0; case "$out" in *"demo.enabled"*) names_toggle=1 ;; esac
names_file=0;   case "$out" in *"corpus.md"*)    names_file=1 ;; esac
says_r2=0;      case "$out" in *"regle 2"*)      says_r2=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$names_toggle" -eq 1 ] && [ "$names_file" -eq 1 ] && [ "$says_r2" -eq 1 ]; then
  ok "2 règle 2 — toggle inactif cité hors marqueur → 1, message nommant le toggle et le fichier"
else
  ko "2 règle 2 → 1 + toggle + fichier" "rc=$rc names_toggle=$names_toggle names_file=$names_file out=[$out]"
fi

# === Cas 3 — marqueur périmé : le toggle est ACTIF mais l'entrée porte encore son marqueur → 1 ==
D="$(mk_fixture c3)"
cat > "$D/config.json" <<'CFG'
{
  "demo": {
    "enabled": true
  }
}
CFG
rc="$(rc_of "$D")"
out="$(run "$D")"
says_r3=0;     case "$out" in *"regle 3"*) says_r3=1 ;; esac
says_perime=0; case "$out" in *"PERIME"*)  says_perime=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$says_r3" -eq 1 ] && [ "$says_perime" -eq 1 ]; then
  ok "3 règle 3 — marqueur survivant à l'activation de sa capability → 1 (dérive INVERSE vue)"
else
  ko "3 règle 3 marqueur périmé → 1" "rc=$rc out=[$out]"
fi

# === Cas 4 — marqueur inconnu : le marqueur nomme un toggle absent de l'index → 1 ==============
D="$(mk_fixture c4)"
printf '| autre | `gsd-autre` (conditionnelle : fantome.enabled) |\n' >> "$D/corpus.md"
rc="$(rc_of "$D")"
out="$(run "$D")"
names_ghost=0; case "$out" in *"fantome.enabled"*) names_ghost=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$names_ghost" -eq 1 ]; then
  ok "4 règle 3 — marqueur nommant un toggle absent de l'index → 1, le fantôme est nommé"
else
  ko "4 règle 3 marqueur inconnu → 1" "rc=$rc out=[$out]"
fi

# === Cas 5 — plancher A : index sans aucun toggle lisible → 2, jamais 0 ========================
# Le gate ne doit pas pouvoir être vert à vide : c'est le mode d'échec qu'il existe pour fermer.
D="$(mk_fixture c5)"
printf '# index vidé de toute table\n' > "$D/index.md"
rc="$(rc_of "$D")"
out="$(run "$D")"
says_nv=0; case "$out" in *"NON VERIFIABLE"*|*"NON VÉRIFIABLE"*) says_nv=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$says_nv" -eq 1 ]; then
  ok "5 plancher A — index sans toggle → 2 « non vérifiable » (JAMAIS 0)"
else
  ko "5 plancher A index vide → 2" "rc=$rc out=[$out]"
fi

# === Cas 6 — plancher B : corpus sans aucun marqueur → 2 ======================================
# Exercé SÉPARÉMENT du plancher A : un seul des deux testé laisserait l'autre chemin non couvert.
D="$(mk_fixture c6)"
printf '# corpus sans le moindre marqueur conditionnel\n' > "$D/corpus.md"
rc="$(rc_of "$D")"
out="$(run "$D")"
says_nv=0; case "$out" in *"NON VERIFIABLE"*|*"NON VÉRIFIABLE"*) says_nv=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$says_nv" -eq 1 ]; then
  ok "6 plancher B — corpus sans marqueur → 2 « non vérifiable » (JAMAIS 0)"
else
  ko "6 plancher B corpus sans marqueur → 2" "rc=$rc out=[$out]"
fi

# === Cas 6b — priorité du plancher sur la règle 2, et jamais 0 dans l'angle mort ===============
# Cas limite mesuré en écrivant cette suite : un corpus qui perdrait TOUS ses marqueurs ET
# citerait un toggle inactif hors marqueur relève à la fois du plancher (règle 1) et de la
# règle 2. L'ordre prescrit donne la priorité au plancher : la sortie est 2, pas 1. Ce qui compte
# et qui est asserté ici, c'est que ce recouvrement ne produise JAMAIS un 0 — l'angle mort du
# gate serait précisément un « rien à signaler » sur une doc qui promet un geste inerte.
D="$(mk_fixture c6b)"
printf 'Le mode avancé dépend de demo.enabled, sans le moindre marqueur nulle part.\n' > "$D/corpus.md"
rc="$(rc_of "$D")"
out="$(run "$D")"
says_nv=0; case "$out" in *"NON VERIFIABLE"*|*"NON VÉRIFIABLE"*) says_nv=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$says_nv" -eq 1 ]; then
  ok "6b ordre des règles — plancher ET promesse démarquée ensemble : 2 (plancher prioritaire), jamais 0"
else
  ko "6b ordre des règles — recouvrement plancher/règle 2 → 2, jamais 0" "rc=$rc out=[$out]"
fi

# === Cas 7 — usage : argument inconnu → 64 =====================================================
D="$(mk_fixture c7)"
rc="$(rc_of "$D" --pas-un-vrai-flag)"
rc_path="$(rc_of "$D" --path)"
if [ "$rc" -eq 64 ] && [ "$rc_path" -eq 64 ]; then
  ok "7 usage — argument inconnu et --path sans valeur → 64 tous les deux"
else
  ko "7 usage → 64" "rc_inconnu=$rc rc_path_sans_valeur=$rc_path"
fi

# === Cas 8 — index absent → 2 (précondition, jamais un conforme par défaut) ====================
D="$(mk_fixture c8)"
rm -f "$D/index.md"
rc="$(rc_of "$D")"
if [ "$rc" -eq 2 ]; then
  ok "8 précondition — index absent → 2"
else
  ko "8 précondition index absent → 2" "rc=$rc"
fi

# === Cas 9 — configuration absente → 2 ========================================================
D="$(mk_fixture c9)"
rm -f "$D/config.json"
rc="$(rc_of "$D")"
if [ "$rc" -eq 2 ]; then
  ok "9 précondition — configuration absente → 2"
else
  ko "9 précondition configuration absente → 2" "rc=$rc"
fi

# === Cas 10 — --help imprime la docstring et énumère les QUATRE codes du contrat ===============
help_out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
n_codes=0
for c in "0  =" "1  =" "2  =" "64 ="; do
  case "$help_out" in *"$c"*) n_codes=$((n_codes+1)) ;; esac
done
if [ "$rc" -eq 0 ] && [ "$n_codes" -eq 4 ]; then
  ok "10 contrat — --help énumère les 4 codes de sortie (0, 1, 2, 64)"
else
  ko "10 contrat --help énumère 4 codes" "rc=$rc n_codes=$n_codes"
fi

# ===============================================================================================
# == MUTATIONS — le gate sait-il rougir ? Discriminance prouvée dans les DEUX sens.
# ===============================================================================================
# Chaque mutation est mécanique et rejouable. Deux garde-fous avant tout verdict :
#   - la mutation doit avoir CHANGÉ le fichier — constaté par `cmp`, JAMAIS par `diff` ;
#   - le vert doit être RETROUVÉ après restauration, sinon le rouge ne prouve rien sur la mutation
#     (il pourrait venir d'une fixture cassée).
echo ""
echo "== mutations =="

mutate() { # <src> <dst> <programme awk>
  awk "$3" "$1" > "$2"
}

# --- Mutation 1 (règle 2) : retirer le MARQUEUR en laissant le toggle cité. ---------------------
# Retirer la ligne entière rendrait le gate vert à juste titre (plus aucune promesse) : ce ne serait
# pas une mutation du gate, mais une suppression de la promesse. La mutation opposable est de garder
# la promesse et de lui ÔTER son avertissement.
D="$(mk_fixture m1)"
cp "$D/corpus.md" "$TMP/m1.corpus.orig"
mutate "$TMP/m1.corpus.orig" "$D/corpus.md" '{ sub(/\(conditionnelle : demo\.enabled\)/, "(demo.enabled)"); print }'
if cmp -s "$D/corpus.md" "$TMP/m1.corpus.orig"; then
  ko "MUT1 règle 2 — retrait du marqueur" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
else
  rc_mut="$(rc_of "$D")"
  out_mut="$(run "$D")"
  cp "$TMP/m1.corpus.orig" "$D/corpus.md"
  rc_back="$(rc_of "$D")"
  # Rougir ne suffit pas : le mutant doit rougir pour LA BONNE RAISON. Un rc=1 obtenu par la
  # règle 3, ou un rc=2 obtenu par le plancher, ne prouverait rien sur la règle 2.
  r2_mut=0; case "$out_mut" in *"regle 2"*) r2_mut=1 ;; esac
  tgt_mut=0; case "$out_mut" in *"demo.enabled"*) tgt_mut=1 ;; esac
  if [ "$rc_mut" -eq 1 ] && [ "$r2_mut" -eq 1 ] && [ "$tgt_mut" -eq 1 ]; then
    ok "MUT1 règle 2 — marqueur retiré, promesse conservée : le gate ROUGIT (rc=1) par la RÈGLE 2 sur demo.enabled — $out_mut"
  else
    ko "MUT1 règle 2 — le gate doit rougir par la règle 2 sur marqueur retiré" "rc=$rc_mut regle2=$r2_mut cible=$tgt_mut out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT1 règle 2 — marqueur restauré : le VERT est retrouvé (rc=0), le rouge venait bien de la mutation"
  else
    ko "MUT1 règle 2 — le vert doit être retrouvé après restauration" "rc=$rc_back"
  fi
fi

# --- Mutation 2 (règle 3) : activer le toggle en laissant le marqueur en place. -----------------
# C'est la dérive INVERSE. Sans cette mutation, le gate pourrait n'être discriminant que sur le
# retrait d'un marqueur, et laisser passer un marqueur qui survit à l'activation de sa capability.
D="$(mk_fixture m2)"
cp "$D/config.json" "$TMP/m2.config.orig"
mutate "$TMP/m2.config.orig" "$D/config.json" '{ sub(/"enabled": false/, "\"enabled\": true"); print }'
if cmp -s "$D/config.json" "$TMP/m2.config.orig"; then
  ko "MUT2 règle 3 — activation du toggle marqué" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
else
  rc_mut="$(rc_of "$D")"
  out_mut="$(run "$D")"
  cp "$TMP/m2.config.orig" "$D/config.json"
  rc_back="$(rc_of "$D")"
  if [ "$rc_mut" -eq 1 ]; then
    ok "MUT2 règle 3 — toggle activé, marqueur conservé : le gate ROUGIT (rc=1) — $out_mut"
  else
    ko "MUT2 règle 3 — le gate doit rougir sur marqueur périmé" "rc=$rc_mut out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT2 règle 3 — configuration restaurée : le VERT est retrouvé (rc=0), le rouge venait bien de la mutation"
  else
    ko "MUT2 règle 3 — le vert doit être retrouvé après restauration" "rc=$rc_back"
  fi
fi

# === Cas final — contrôle sur l'arbre RÉEL ====================================================
# NON discriminant à lui seul (il ne prouve que l'absence d'écart aujourd'hui) : il vient donc
# APRÈS les mutations, et jamais à leur place.
echo ""
echo "== contrôle sur l'arbre réel =="
bash "$SCRIPT" >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ]; then
  ok "15 contrôle réel — le gate sort 0 sur le dépôt (état livré par le plan 24-06)"
else
  ko "15 contrôle réel — le gate doit sortir 0 sur le dépôt" "rc=$rc — $(bash "$SCRIPT" 2>&1 >/dev/null)"
fi

echo ""
echo "== bilan : $((PASS + FAIL)) cas — $PASS OK / $FAIL KO =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
