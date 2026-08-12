#!/usr/bin/env bash
# test-check-capability-activation.sh — Suite de vérification de check-capability-activation.sh
# (Phase 24, plans 24-11 puis 24-13 — GSDA-09).
#
# Ce que cette suite prouve, et pourquoi elle est bâtie ainsi.
#
# Le gate testé existe pour fermer un mode d'échec précis : une couverture verte qui masque un
# geste mort. Une suite qui ne vérifierait que l'état nominal reproduirait exactement ce mode
# d'échec un étage plus haut — elle serait verte parce qu'elle ne sait pas rougir. La discriminance
# est donc prouvée par MUTATION, dans les DEUX sens :
#   - retirer un marqueur conditionnel d'une entrée de doc dont le toggle est inactif → le gate
#     DOIT rougir (règles 2 et 2bis) ;
#   - activer le toggle d'une entrée qui porte encore son marqueur → le gate DOIT rougir aussi
#     (règle 3). Sans cette seconde mutation, le gate ne serait discriminant que dans un sens.
#
# CORRECTION DE FOND APPORTÉE À CETTE SUITE (24-13). La version précédente RATIONALISAIT l'absence
# du cas décisif : elle écrivait que « retirer la ligne entière rendrait le gate vert à juste
# titre » et sa mutation MUT1 CONSERVAIT le littéral du toggle (`(conditionnelle : demo.enabled)` →
# `(demo.enabled)`). Le corpus réel ne fait pas cela : quand on ôte le parenthétique d'une entrée de
# routage, le nom du toggle DISPARAÎT et seul l'identifiant de la brique reste. La mutation passait
# donc pendant que le défaut réel, lui, ne rougissait pas. Les mutations de cette suite reproduisent
# désormais la LETTRE du corpus, jamais une forme commode.
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
# L'index synthétique reproduit les QUATRE sections de l'index réel : la table par point de hook
# (5 colonnes), celle des capabilities hors point de hook (3 colonnes), celle des toggles
# gouvernants (4 colonnes, avec TYPE et DÉFAUT AMONT) et celle des briques routées (3 colonnes).
# Une fixture qui n'en aurait qu'une partie laisserait autant de chemins du parseur non testés — et
# les deux dernières sont précisément celles qui portent la règle 2bis et la résolution par défaut.
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

## Toggles gouvernants déclarés par le registre

| Toggle gouvernant | Propriétaire | Type | Défaut amont |
|---|---|---|---|
| `workflow.demo_stage` | `demo-stage` | boolean | non |
| `demo.enabled` | `demo` | boolean | non |
| `autre.enabled` | `autre` | boolean | non |
| `defaut.actif` | `par-defaut` | boolean | oui |
| `sans.defaut` | `mystere` | — | — |

## Briques routées et leur toggle gouvernant

| Brique | Capability | Toggle gouvernant |
|---|---|---|
| `gsd-demo` | `demo` | `demo.enabled` |
| `gsd-autre` | `autre` | `autre.enabled` |
| `gsd-defaut` | `par-defaut` | `defaut.actif` |
| `gsd-mystere` | `mystere` | `sans.defaut` |
IDX
}

# Configuration synthétique : `demo.enabled` PRÉSENT à false (inactivité déclarée) et
# `workflow.demo_stage` ABSENT (inactivité par le défaut amont) — les deux formes d'inactivité que
# la règle 2 doit traiter identiquement. `defaut.actif` et `sans.defaut` sont absents eux aussi :
# le premier est ACTIF par son défaut amont, le second reste INDÉTERMINÉ.
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

# Corpus conforme : chaque brique dont le toggle est inactif est citée SOUS marqueur, sur sa ligne.
#
# DEUX marqueurs, et c'est délibéré — le corpus réel en porte trois. Avec un seul, retirer LE
# marqueur viderait M et ferait sortir le plancher de la règle 1 (« non vérifiable », 2) AVANT que
# la règle 2 puisse voir la promesse démarquée : la mutation aurait prouvé le plancher, pas la
# règle qu'elle vise. Le gate reste rouge dans les deux cas — jamais vert — mais un mutant qui
# rougit pour la mauvaise raison ne prouve rien.
#
# Les DEUX dernières lignes ne sont pas décoratives : `gsd-defaut` prouve que le DÉFAUT AMONT est
# lu (sans lui, une clé absente passerait pour inactive et cette ligne rougirait à tort), et
# `gsd-mystere` prouve qu'un toggle INDÉTERMINÉ ne fait rien conclure au gate.
mk_corpus_ok() { # <chemin>
  cat > "$1" <<'DOC'
# Carte de routage synthétique

| intention | brique |
|---|---|
| faire la démo | `gsd-demo` (conditionnelle : demo.enabled) — refusée, aucun consommateur prescrit |
| faire autre chose | `gsd-autre` (conditionnelle : autre.enabled) — refusée, aucun consommateur prescrit |
| cas actif par défaut | `gsd-defaut` — actif par le défaut amont du registre, aucun marqueur requis |
| cas indéterminé | `gsd-mystere` — le registre ne déclare aucun défaut, le gate ne conclut pas |
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

# === Cas 1b — le rapport compte SÉPARÉMENT inactifs, indéterminés et briques ===================
# Un rapport qui agrégerait les trois laisserait un toggle indéterminé se lire comme inactif : ce
# serait un verdict tenu sur un état que le gate ne connaît pas.
D="$(mk_fixture c1b)"
out="$(run "$D")"
c_inact=0; case "$out" in *"3 inactif(s)"*) c_inact=1 ;; esac
c_unk=0;   case "$out" in *"1 indetermine(s)"*) c_unk=1 ;; esac
c_brick=0; case "$out" in *"4 brique(s) routee(s)"*) c_brick=1 ;; esac
if [ "$c_inact" -eq 1 ] && [ "$c_unk" -eq 1 ] && [ "$c_brick" -eq 1 ]; then
  ok "1b rapport — 3 inactifs, 1 indéterminé et 4 briques comptés SÉPARÉMENT"
else
  ko "1b rapport — compteurs séparés" "inact=$c_inact unk=$c_unk brick=$c_brick out=[$out]"
fi

# === Cas 2 — promesse non marquée : le même toggle inactif cité HORS marqueur → 1 ==============
# Le message doit nommer le toggle ET le fichier : un « écart constaté » anonyme est inactionnable.
D="$(mk_fixture c2)"
printf 'Le mode avancé dépend de demo.enabled et sera bientôt là.\n' >> "$D/corpus.md"
rc="$(rc_of "$D")"
out="$(run "$D")"
names_toggle=0; case "$out" in *"demo.enabled"*) names_toggle=1 ;; esac
names_file=0;   case "$out" in *"corpus.md"*)    names_file=1 ;; esac
says_r2=0;      case "$out" in *"regle 2 "*)     says_r2=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$names_toggle" -eq 1 ] && [ "$names_file" -eq 1 ] && [ "$says_r2" -eq 1 ]; then
  ok "2 règle 2 — toggle inactif cité hors marqueur → 1, message nommant le toggle et le fichier"
else
  ko "2 règle 2 → 1 + toggle + fichier" "rc=$rc names_toggle=$names_toggle names_file=$names_file out=[$out]"
fi

# === Cas 2bis — promesse par IDENTIFIANT DE BRIQUE, sans jamais nommer le toggle ===============
# LE cas que le gate existe pour voir, et celui que sa première version laissait passer : une
# entrée de table promet `gsd-demo` et ne nomme le toggle NULLE PART. Aucune règle cherchant un nom
# de toggle ne peut le voir.
D="$(mk_fixture c2bis)"
printf '| une intention neuve | `gsd-demo` — le geste promis, sans le moindre avertissement |\n' >> "$D/corpus.md"
rc="$(rc_of "$D")"
out="$(run "$D")"
names_brick=0; case "$out" in *"gsd-demo"*)   names_brick=1 ;; esac
says_r2b=0;    case "$out" in *"regle 2bis"*) says_r2b=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$names_brick" -eq 1 ] && [ "$says_r2b" -eq 1 ]; then
  ok "2bis règle 2bis — brique promise en table, toggle jamais nommé → 1, la brique est nommée"
else
  ko "2bis règle 2bis → 1 + brique nommée" "rc=$rc out=[$out]"
fi

# === Cas 2ter — la règle 2bis ne juge QUE les lignes de table ==================================
# Frontière déclarée dans la docstring du gate : un titre ou un paragraphe qui NOMME une brique ne
# la PROMET pas (« `gsd-x` est délibérément absent de toute table de routage »). Sans ce cas, rien
# n'empêcherait un durcissement futur d'élargir la règle en silence et de rendre inécrivable toute
# prose citant une brique désactivée.
D="$(mk_fixture c2ter)"
printf '\n## Section citant `gsd-demo` dans son titre\n\nUn paragraphe qui mentionne `gsd-demo` sans rien promettre.\n' >> "$D/corpus.md"
rc="$(rc_of "$D")"
if [ "$rc" -eq 0 ]; then
  ok "2ter portée — titre et prose citant la brique : PAS un écart (seules les lignes de table le sont)"
else
  ko "2ter portée — prose citant la brique ne doit rien déclencher" "rc=$rc out=[$(run "$D")]"
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

# === Cas 5bis — plancher C : index SANS table de briques → 2 ===================================
# Sans ce plancher, un index amputé de sa seule table de briques désarmerait la règle 2bis EN
# SILENCE : le gate resterait vert en ne vérifiant plus que les noms de toggle, c'est-à-dire dans
# l'état exact qu'on vient de corriger. C'est le plancher anti-régression du correctif lui-même.
D="$(mk_fixture c5bis)"
awk '/^## Briques rout/{stop=1} !stop{print}' "$D/index.md" > "$D/index.trim" && mv "$D/index.trim" "$D/index.md"
rc="$(rc_of "$D")"
out="$(run "$D")"
says_brick=0; case "$out" in *"aucune brique routee"*) says_brick=1 ;; esac
says_inerte=0; case "$out" in *"INERTE"*) says_inerte=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$says_brick" -eq 1 ] && [ "$says_inerte" -eq 1 ]; then
  ok "5bis plancher C — index sans table de briques → 2, et le message dit que la règle 2bis serait INERTE"
else
  ko "5bis plancher C index sans briques → 2" "rc=$rc out=[$out]"
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

# === Cas 11 — comparaison PAR FRONTIÈRE : une clé plus longue ne compte pas pour la courte =====
# La paire piège existe dans le lab réel (`workflow.code_review` / `workflow.code_review_command`).
# Avec une comparaison par sous-chaîne nue, citer la clé LONGUE — parfaitement licite — fabriquait
# un écart sur la COURTE, et cet écart était incorrigible : aucune rédaction ne satisfait un gate
# qui cherche le mauvais nom. La fixture reproduit exactement la forme de la paire réelle.
D="$(mk_fixture c11)"
printf 'Le réglage demo.enabled_command reste libre et ne promet aucun geste.\n' >> "$D/corpus.md"
rc="$(rc_of "$D")"
if [ "$rc" -eq 0 ]; then
  ok '11 frontière — demo.enabled_command cité ne compte PAS comme demo.enabled (aucun écart inventé)'
else
  ko "11 frontière — clé longue citée ne doit pas déclencher la clé courte" "rc=$rc out=[$(run "$D")]"
fi

# === Cas 12 — corpus dont le CHEMIN CONTIENT UN ESPACE =========================================
# `~/Library/Mobile Documents/` est un emplacement de lab courant sous macOS. Avec un corpus
# découpé sur l'espace, un tel chemin était par construction inexprimable et le gate sortait 2 en
# permanence — un gate désarmé par l'emplacement du lab, jamais par son contenu.
D_ESP="$TMP/avec espace/refs"
mkdir -p "$D_ESP"
mk_index "$D_ESP/index.md"; mk_config "$D_ESP/config.json"; mk_corpus_ok "$D_ESP/corpus.md"
rc_esp=0
VF_CAPACT_INDEX="$D_ESP/index.md" VF_CAPACT_CONFIG="$D_ESP/config.json" \
  VF_CAPACT_CORPUS="$D_ESP/corpus.md" bash "$SCRIPT" >/dev/null 2>&1 || rc_esp=$?
if [ "$rc_esp" -eq 0 ]; then
  ok "12 chemin à espace — un corpus sous « avec espace/ » est lu normalement (→ 0)"
else
  ko "12 chemin à espace — le gate ne doit pas se désarmer sur l'emplacement du lab" "rc=$rc_esp"
fi

# === Cas 13 — le corpus n'est PAS développé comme un glob =====================================
# `VF_CAPACT_CORPUS="$D/*.md"` aspirait des fichiers que personne n'avait nommés (index.md compris),
# ce qui faussait jusqu'au compteur « N fichier(s) de corpus » du rapport. Le motif doit désormais
# être traité comme un NOM DE FICHIER, donc illisible, donc 2 — jamais comme une liste implicite.
D="$(mk_fixture c13)"
rc_glob=0
VF_CAPACT_INDEX="$D/index.md" VF_CAPACT_CONFIG="$D/config.json" \
  VF_CAPACT_CORPUS="$D/*.md" bash "$SCRIPT" >/dev/null 2>&1 || rc_glob=$?
out_glob="$(VF_CAPACT_INDEX="$D/index.md" VF_CAPACT_CONFIG="$D/config.json" \
  VF_CAPACT_CORPUS="$D/*.md" bash "$SCRIPT" 2>&1 >/dev/null)"
says_illisible=0; case "$out_glob" in *"fichier de corpus illisible"*) says_illisible=1 ;; esac
if [ "$rc_glob" -eq 2 ] && [ "$says_illisible" -eq 1 ]; then
  ok "13 glob — un motif dans VF_CAPACT_CORPUS est un NOM, pas une liste : 2 « illisible », aucun fichier aspiré"
else
  ko "13 glob — le corpus ne doit jamais être développé" "rc=$rc_glob out=[$out_glob]"
fi

# === Cas 14 — LAB INSTALLÉ : la racine est le lab, jamais le projet du dessus ==================
# Chez l'utilisateur, l'installeur dépose les scripts À PLAT dans `.claude/scripts/` et les
# références dans `.claude/agents/<module>-references/`. Une racine déduite de `$0/../..` désignait
# alors le PARENT du lab : le gate lisait le `.planning/config.json` d'un AUTRE projet, ou sortait 2.
# La fixture rend le cas DISCRIMINANT — le voisin porte une configuration qui rendrait le verdict
# ROUGE (marqueur périmé). Lire le bon fichier est donc la seule façon d'obtenir 0.
VOISIN="$TMP/b2"
LAB="$VOISIN/lab"
mkdir -p "$VOISIN/.planning" "$LAB/.planning" "$LAB/.claude/scripts" "$LAB/.claude/agents/dev-orchestrator-references"
cat > "$VOISIN/.planning/config.json" <<'CFG'
{ "demo": { "enabled": true }, "autre": { "enabled": true } }
CFG
mk_config "$LAB/.planning/config.json"
cp "$SCRIPT" "$LAB/.claude/scripts/check-capability-activation.sh"
mk_index  "$LAB/.claude/agents/dev-orchestrator-references/gsd-capabilities-index.md"
mk_corpus_ok "$LAB/.claude/agents/dev-orchestrator-references/intent-routing.md"
printf '# doc-flow synthétique, sans marqueur ni brique\n' > "$LAB/.claude/agents/dev-orchestrator-references/docs-flow.md"
# Univers de la règle 4 (planchers, tâche 2) : au moins UN artefact non armé et UN script porteur
# d'un `# vf-provides:` — sans cela le corpus d'armement/de preuve par défaut de ce lab installé
# serait vide et le plancher anti-vert-à-vide rendrait 2, pour une raison étrangère au cas 14.
cat > "$LAB/.claude/agents/dummy-agent.md" <<'AGT'
---
name: dummy-agent
---

# Agent factice (case 14, sans armement)
AGT
cat > "$LAB/.claude/scripts/dummy-provider.sh" <<'SCR'
#!/usr/bin/env bash
# dummy-provider.sh — fixture case 14
# vf-provides: mcp-servers
set -uo pipefail
echo ok
SCR
rc_lab=0
out_lab="$(cd "$TMP" && env -u VF_CAPACT_INDEX -u VF_CAPACT_CONFIG -u VF_CAPACT_CORPUS \
  bash "$LAB/.claude/scripts/check-capability-activation.sh" 2>&1 >/dev/null)" || rc_lab=$?
reads_lab=0; case "$out_lab" in *"2 fichier(s) de corpus"*) reads_lab=1 ;; esac
if [ "$rc_lab" -eq 0 ] && [ "$reads_lab" -eq 1 ]; then
  ok "14 lab installé — racine = le lab (et non son parent), références trouvées sous agents/<mod>-references/ → 0"
else
  ko "14 lab installé — le gate doit lire le lab, pas le projet voisin" "rc=$rc_lab out=[$out_lab]"
fi

# Contre-épreuve du cas 14 : la configuration du VOISIN, appliquée au même corpus, rougit. Sans
# elle, le vert ci-dessus serait satisfait par n'importe quelle configuration — y compris celle du
# voisin — et ne prouverait donc RIEN sur le fichier réellement lu.
rc_voisin=0
VF_CAPACT_INDEX="$LAB/.claude/agents/dev-orchestrator-references/gsd-capabilities-index.md" \
VF_CAPACT_CONFIG="$VOISIN/.planning/config.json" \
VF_CAPACT_CORPUS="$LAB/.claude/agents/dev-orchestrator-references/intent-routing.md" \
  bash "$SCRIPT" >/dev/null 2>&1 || rc_voisin=$?
if [ "$rc_voisin" -eq 1 ]; then
  ok "14b contre-épreuve — la configuration du VOISIN, elle, rougit (1) : le cas 14 est discriminant"
else
  ko "14b contre-épreuve — la config du voisin doit rougir, sinon le cas 14 ne prouve rien" "rc=$rc_voisin"
fi

# ===============================================================================================
# == MUTATIONS — le gate sait-il rougir ? Discriminance prouvée dans les DEUX sens.
# ===============================================================================================
# Chaque mutation est mécanique et rejouable. Trois garde-fous avant tout verdict :
#   - la CIBLE n'est jamais tronquée avant que le programme de mutation ait réussi. `awk … > cible`
#     ouvre la cible et la vide AVANT d'exécuter le programme : un `awk` en échec laissait donc un
#     fichier VIDE que `cmp -s` déclarait « changé », et la suite jugeait alors un mutant JAMAIS
#     CONSTRUIT. La production passe par un temporaire, et le dépôt n'a lieu qu'en cas de succès ;
#   - la mutation doit avoir CHANGÉ le fichier — constaté par `cmp`, JAMAIS par `diff` ;
#   - le vert doit être RETROUVÉ après restauration, sinon le rouge ne prouve rien sur la mutation
#     (il pourrait venir d'une fixture cassée).
echo ""
echo "== mutations =="

mutate() { # <src> <dst> <programme awk> — 0 si le mutant a été déposé, 1 sinon (cible INTACTE)
  local tmp="$2.mut.$$"
  if ! awk "$3" "$1" > "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    return 1
  fi
  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$2"
  return 0
}

# --- Mutation 1 (règle 2bis) : retirer le PARENTHÉTIQUE, à la LETTRE du corpus réel. ------------
# Ce que fait vraiment une régression de rédaction : le parenthétique disparaît, la promesse de
# routage reste, et le nom du toggle N'EXISTE PLUS NULLE PART sur la ligne. C'est le mutant que la
# version précédente de cette suite évitait (elle conservait `(demo.enabled)`, donc le littéral du
# toggle, donc un motif que la règle 2 pouvait encore voir) — et c'est la raison pour laquelle elle
# restait verte pendant que le défaut réel passait.
D="$(mk_fixture m1)"
cp "$D/corpus.md" "$TMP/m1.corpus.orig"
if ! mutate "$TMP/m1.corpus.orig" "$D/corpus.md" '{ sub(/ \(conditionnelle : demo\.enabled\)/, ""); print }'; then
  ko "MUT1 règle 2bis — retrait du parenthétique" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT, jamais mutant satisfait"
elif cmp -s "$D/corpus.md" "$TMP/m1.corpus.orig"; then
  ko "MUT1 règle 2bis — retrait du parenthétique" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
else
  # Garde-fou supplémentaire : le mutant ne doit plus contenir le nom du toggle nulle part. Sinon
  # la mutation ne reproduit pas la lettre du corpus et un rc=1 obtenu par la règle 2 mentirait.
  still=0
  awk 'index($0, "demo.enabled") > 0 { n++ } END { exit (n > 0 ? 1 : 0) }' "$D/corpus.md" || still=1
  rc_mut="$(rc_of "$D")"
  out_mut="$(run "$D")"
  cp "$TMP/m1.corpus.orig" "$D/corpus.md"
  rc_back="$(rc_of "$D")"
  r2b_mut=0; case "$out_mut" in *"regle 2bis"*) r2b_mut=1 ;; esac
  tgt_mut=0; case "$out_mut" in *"gsd-demo"*)   tgt_mut=1 ;; esac
  if [ "$still" -eq 0 ] && [ "$rc_mut" -eq 1 ] && [ "$r2b_mut" -eq 1 ] && [ "$tgt_mut" -eq 1 ]; then
    ok "MUT1 règle 2bis — parenthétique retiré (le toggle n'est plus nommé NULLE PART), promesse conservée : le gate ROUGIT (rc=1) par la RÈGLE 2bis sur gsd-demo — $out_mut"
  else
    ko "MUT1 règle 2bis — le gate doit rougir par la règle 2bis sur parenthétique retiré" "toggle_encore_present=$still rc=$rc_mut regle2bis=$r2b_mut cible=$tgt_mut out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT1 règle 2bis — parenthétique restauré : le VERT est retrouvé (rc=0), le rouge venait bien de la mutation"
  else
    ko "MUT1 règle 2bis — le vert doit être retrouvé après restauration" "rc=$rc_back"
  fi
fi

# --- Mutation 1bis (règle 2) : garder le toggle, lui ôter son marqueur. -------------------------
# L'autre forme de dérive, conservée telle quelle : la doc continue de nommer le toggle mais ne
# l'entoure plus de son marqueur. Elle prouve la règle 2, là où MUT1 prouve la règle 2bis — les
# deux règles sont distinctes et chacune a besoin de son mutant.
D="$(mk_fixture m1bis)"
cp "$D/corpus.md" "$TMP/m1bis.corpus.orig"
if ! mutate "$TMP/m1bis.corpus.orig" "$D/corpus.md" '{ sub(/\(conditionnelle : demo\.enabled\)/, "(demo.enabled)"); print }'; then
  ko "MUT1bis règle 2 — marqueur dégradé" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT"
elif cmp -s "$D/corpus.md" "$TMP/m1bis.corpus.orig"; then
  ko "MUT1bis règle 2 — marqueur dégradé" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE"
else
  rc_mut="$(rc_of "$D")"
  out_mut="$(run "$D")"
  cp "$TMP/m1bis.corpus.orig" "$D/corpus.md"
  rc_back="$(rc_of "$D")"
  r2_mut=0;  case "$out_mut" in *"regle 2 "*)     r2_mut=1 ;; esac
  tgt_mut=0; case "$out_mut" in *"demo.enabled"*) tgt_mut=1 ;; esac
  if [ "$rc_mut" -eq 1 ] && [ "$r2_mut" -eq 1 ] && [ "$tgt_mut" -eq 1 ]; then
    ok "MUT1bis règle 2 — marqueur ôté, toggle conservé : le gate ROUGIT (rc=1) par la RÈGLE 2 sur demo.enabled"
  else
    ko "MUT1bis règle 2 — le gate doit rougir par la règle 2" "rc=$rc_mut regle2=$r2_mut cible=$tgt_mut out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT1bis règle 2 — marqueur restauré : le VERT est retrouvé (rc=0)"
  else
    ko "MUT1bis règle 2 — le vert doit être retrouvé après restauration" "rc=$rc_back"
  fi
fi

# --- Mutation 2 (règle 3) : activer le toggle en laissant le marqueur en place. -----------------
# C'est la dérive INVERSE. Sans cette mutation, le gate pourrait n'être discriminant que sur le
# retrait d'un marqueur, et laisser passer un marqueur qui survit à l'activation de sa capability.
# Le rc ne suffit PAS : MUT1 pose la règle inverse (rougir pour LA BONNE RAISON), et l'omettre ici
# laisserait un rc=1 obtenu par la règle 2 valider un mutant de règle 3.
D="$(mk_fixture m2)"
cp "$D/config.json" "$TMP/m2.config.orig"
if ! mutate "$TMP/m2.config.orig" "$D/config.json" '{ sub(/"enabled": false/, "\"enabled\": true"); print }'; then
  ko "MUT2 règle 3 — activation du toggle marqué" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT"
elif cmp -s "$D/config.json" "$TMP/m2.config.orig"; then
  ko "MUT2 règle 3 — activation du toggle marqué" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE"
else
  rc_mut="$(rc_of "$D")"
  out_mut="$(run "$D")"
  cp "$TMP/m2.config.orig" "$D/config.json"
  rc_back="$(rc_of "$D")"
  r3_mut=0;  case "$out_mut" in *"regle 3"*)      r3_mut=1 ;; esac
  per_mut=0; case "$out_mut" in *"PERIME"*)       per_mut=1 ;; esac
  tgt_mut=0; case "$out_mut" in *"demo.enabled"*) tgt_mut=1 ;; esac
  if [ "$rc_mut" -eq 1 ] && [ "$r3_mut" -eq 1 ] && [ "$per_mut" -eq 1 ] && [ "$tgt_mut" -eq 1 ]; then
    ok "MUT2 règle 3 — toggle activé, marqueur conservé : le gate ROUGIT (rc=1) par la RÈGLE 3, verdict PERIME sur demo.enabled"
  else
    ko "MUT2 règle 3 — le gate doit rougir par la règle 3 (PERIME), pas seulement rougir" "rc=$rc_mut regle3=$r3_mut perime=$per_mut cible=$tgt_mut out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT2 règle 3 — configuration restaurée : le VERT est retrouvé (rc=0), le rouge venait bien de la mutation"
  else
    ko "MUT2 règle 3 — le vert doit être retrouvé après restauration" "rc=$rc_back"
  fi
fi

# --- Mutation 3 (colonne « Défaut amont ») : la colonne est-elle LUE ? -------------------------
# `gsd-defaut` est cité SANS marqueur, ce qui n'est licite que parce que son toggle est ACTIF par
# son défaut amont. Basculer ce défaut de `oui` à `non` doit rendre l'entrée illicite. Sans cette
# mutation, la colonne pourrait n'être jamais lue et la résolution retomber sur « absent ⇒ inactif »
# sans que rien ne rougisse — un vert à vide sur la moitié neuve du parseur.
D="$(mk_fixture m3)"
cp "$D/index.md" "$TMP/m3.index.orig"
if ! mutate "$TMP/m3.index.orig" "$D/index.md" '{ sub(/^\| `defaut\.actif` \| `par-defaut` \| boolean \| oui \|$/, "| `defaut.actif` | `par-defaut` | boolean | non |"); print }'; then
  ko "MUT3 défaut amont — bascule oui→non" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT"
elif cmp -s "$D/index.md" "$TMP/m3.index.orig"; then
  ko "MUT3 défaut amont — bascule oui→non" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE"
else
  rc_mut="$(rc_of "$D")"
  out_mut="$(run "$D")"
  cp "$TMP/m3.index.orig" "$D/index.md"
  rc_back="$(rc_of "$D")"
  tgt_mut=0; case "$out_mut" in *"gsd-defaut"*) tgt_mut=1 ;; esac
  if [ "$rc_mut" -eq 1 ] && [ "$tgt_mut" -eq 1 ]; then
    ok "MUT3 défaut amont — défaut basculé oui→non : le gate ROUGIT (rc=1) sur gsd-defaut, la colonne est bien LUE"
  else
    ko "MUT3 défaut amont — la colonne « Défaut amont » doit être lue" "rc=$rc_mut cible=$tgt_mut out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT3 défaut amont — index restauré : le VERT est retrouvé (rc=0)"
  else
    ko "MUT3 défaut amont — le vert doit être retrouvé après restauration" "rc=$rc_back"
  fi
fi

# ===============================================================================================
# == RÈGLE 4 (Phase 28, plan 28-01) — armement sans précondition distribuée ======================
# ===============================================================================================
# La tranche traçante : UN armement de la liste close (`isolation:`), UN cas de preuve rouge/vert
# discriminant, câblé de bout en bout — du frontmatter de l'artefact jusqu'au code de sortie du
# gate. Fixtures synthétiques dédiées (deux artefacts armés, jamais un seul — Pitfall 5 : retirer
# l'unique artefact viderait l'univers et déclencherait un plancher, pas la règle visée).
#
# Isolation vis-à-vis de check-agents.sh : ces fixtures ne sont JAMAIS soumises qu'à
# check-capability-activation.sh — aucun appel à check-agents.sh dans cette section. Et chaque
# assertion porte sur le MESSAGE `ECART regle 4`, jamais sur le seul code de sortie : sans quoi un
# exit 1 venu d'une autre règle passerait pour la preuve de la règle 4.

mk_agent_arme() { # <chemin> — agent isolation:worktree + vf-requires:worktree-baseref, conforme
  cat > "$1" <<'AGT'
---
name: agent-fixture-regle4
isolation: worktree
vf-requires: worktree-baseref
---

# Agent arme (fixture regle 4, Phase 28)
AGT
}

mk_script_preuve() { # <chemin> — porteur reel du marqueur worktree-baseref
  cat > "$1" <<'SCR'
#!/usr/bin/env bash
# provide.sh — fixture Phase 28, porteur de la precondition worktree-baseref
# vf-provides: worktree-baseref
set -uo pipefail
echo ok
SCR
}

mk_script_decoy() { # <chemin> — deuxieme porteur (id DIFFERENT), evite qu'un corpus de preuve
                     # amputé de provide.sh tombe a ZERO fichier (ce qui relèverait d'un plancher
                     # anti-vert-a-vide, une regle DIFFERENTE de la 4c que MUT-R3 vise)
  cat > "$1" <<'SCR'
#!/usr/bin/env bash
# decoy.sh — fixture Phase 28, porteur d'un id DIFFERENT (jamais worktree-baseref)
# vf-provides: mcp-servers
set -uo pipefail
echo ok
SCR
}

mk_regle4_fixture() { # <nom> -> imprime le chemin ; DEUX artefacts armes + 2 scripts de preuve
  local d="$TMP/$1"
  mkdir -p "$d/agents" "$d/scripts"
  mk_index "$d/index.md"
  mk_config "$d/config.json"
  mk_corpus_ok "$d/corpus.md"
  mk_agent_arme "$d/agents/agentA.md"
  mk_agent_arme "$d/agents/agentB.md"
  mk_script_preuve "$d/scripts/provide.sh"
  mk_script_decoy "$d/scripts/decoy.sh"
  printf '%s' "$d"
}

run4() { # <fixture-dir> <armed-list> <providers-list> [args...] -> stderr du gate
  local d="$1" armed="$2" prov="$3"; shift 3
  VF_CAPACT_INDEX="$d/index.md" \
  VF_CAPACT_CONFIG="$d/config.json" \
  VF_CAPACT_CORPUS="$d/corpus.md" \
  VF_CAPACT_ARMED="$armed" \
  VF_CAPACT_PROVIDERS="$prov" \
  bash "$SCRIPT" "$@" 2>&1 >/dev/null
}

rc4_of() { # <fixture-dir> <armed-list> <providers-list> [args...] -> rc du gate, sortie muette
  local d="$1" armed="$2" prov="$3"; shift 3
  VF_CAPACT_INDEX="$d/index.md" \
  VF_CAPACT_CONFIG="$d/config.json" \
  VF_CAPACT_CORPUS="$d/corpus.md" \
  VF_CAPACT_ARMED="$armed" \
  VF_CAPACT_PROVIDERS="$prov" \
  bash "$SCRIPT" "$@" >/dev/null 2>&1
  echo "$?"
}

echo ""
echo "== règle 4 =="

# === Cas R1 — état conforme : deux artefacts armés, vf-requires legal levé par # vf-provides → 0
D="$(mk_regle4_fixture r1)"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
if [ "$rc" -eq 0 ]; then
  ok "R1 règle 4 conforme — deux artefacts armés, vf-requires légal levé par # vf-provides → 0"
else
  ko "R1 règle 4 conforme → 0" "rc=$rc out=[$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")]"
fi

# === MUT-R2 (ROUGE, sous-cas a) — vf-requires retiré de l'agent A =============================
D="$(mk_regle4_fixture r2)"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
cp "$D/agents/agentA.md" "$TMP/r2.agentA.orig"
if ! mutate "$TMP/r2.agentA.orig" "$D/agents/agentA.md" '/^vf-requires:/{next} {print}'; then
  ko "MUT-R2 règle 4(a) — retrait de vf-requires" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT"
elif cmp -s "$D/agents/agentA.md" "$TMP/r2.agentA.orig"; then
  ko "MUT-R2 règle 4(a) — retrait de vf-requires" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE"
else
  rc_mut="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
  out_mut="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")"
  cp "$TMP/r2.agentA.orig" "$D/agents/agentA.md"
  rc_back="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
  says_r4=0; case "$out_mut" in *"ECART regle 4"*) says_r4=1 ;; esac
  names_a=0; case "$out_mut" in *"agentA.md"*) names_a=1 ;; esac
  # Assertion sur le libellé SPÉCIFIQUE du sous-cas (a) — pas seulement « ECART regle 4 » générique,
  # qui est aussi émis par le sous-cas (b) (`REQ_VAL[f]` auto-vivifiée à "" par awk absorbe le
  # retrait de vf-requires et retombe sur le message du sous-cas (b), différent mais contenant
  # encore says_r4/names_a). Sans ce libellé, MUT-R2 ne discrimine pas « (a) marche » de « (a) est
  # cassé et (b) l'absorbe avec un message dégradé ».
  says_suba=0; case "$out_mut" in *"sans precondition declaree (vf-requires: absent)"*) says_suba=1 ;; esac
  if [ "$rc_mut" -eq 1 ] && [ "$says_r4" -eq 1 ] && [ "$names_a" -eq 1 ] && [ "$says_suba" -eq 1 ]; then
    ok "MUT-R2 règle 4(a) — agent armé sans vf-requires : le gate ROUGIT (rc=1), ECART regle 4 sous-cas (a) nommant agentA.md"
  else
    ko "MUT-R2 règle 4(a) — le gate doit rougir sur armement sans précondition déclarée, avec le libellé du sous-cas (a)" "rc=$rc_mut regle4=$says_r4 nomme=$names_a sous_cas_a=$says_suba out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT-R2 règle 4(a) — vf-requires restauré : le VERT est retrouvé (rc=0)"
  else
    ko "MUT-R2 règle 4(a) — le vert doit être retrouvé après restauration" "rc=$rc_back"
  fi
fi

# === MUT-R3 (ROUGE, sous-cas c) — provide.sh retiré du corpus de scripts balayé ================
# Retrait de LISTE (VF_CAPACT_PROVIDERS), pas de fichier : le fichier disque reste lisible, seul le
# corpus BALAYÉ change — décoy.sh reste présent pour que le corpus ne tombe jamais à zéro fichier
# (sans quoi ce mutant prouverait un plancher anti-vert-à-vide, pas la règle 4c).
D="$(mk_regle4_fixture r3)"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md"
PROV_LIST_FULL="$D/scripts/provide.sh
$D/scripts/decoy.sh"
PROV_LIST_MUT="$D/scripts/decoy.sh"
if [ "$PROV_LIST_FULL" = "$PROV_LIST_MUT" ]; then
  ko "MUT-R3 règle 4(c) — retrait de provide.sh du corpus balayé" "la liste balayée n'a RIEN changé — mutant NON OPPOSABLE"
else
  rc_mut="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST_MUT")"
  out_mut="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST_MUT")"
  rc_back="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST_FULL")"
  says_r4=0;  case "$out_mut" in *"ECART regle 4"*)      says_r4=1 ;; esac
  names_id=0; case "$out_mut" in *"worktree-baseref"*)   names_id=1 ;; esac
  if [ "$rc_mut" -eq 1 ] && [ "$says_r4" -eq 1 ] && [ "$names_id" -eq 1 ]; then
    ok "MUT-R3 règle 4(c) — provide.sh retiré du corpus balayé : le gate ROUGIT (rc=1), ECART regle 4 nommant worktree-baseref introuvable"
  else
    ko "MUT-R3 règle 4(c) — le gate doit rougir sur précondition légale non levée" "rc=$rc_mut regle4=$says_r4 id=$names_id out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT-R3 règle 4(c) — provide.sh remis dans le corpus balayé : le VERT est retrouvé (rc=0)"
  else
    ko "MUT-R3 règle 4(c) — le vert doit être retrouvé une fois provide.sh remis dans le corpus" "rc=$rc_back"
  fi
fi

# === MUT-R4 (VERT par désarmement — le cas #38 rejoué) =========================================
# `isolation: worktree` ET `vf-requires:` retirés des DEUX agents : plus aucun artefact armé, le
# gate doit VERDIR. C'est le sens INVERSE de MUT-R2/MUT-R3 — sans lui la règle 4 ne serait
# discriminante que dans un sens.
D="$(mk_regle4_fixture r4)"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
cp "$D/agents/agentA.md" "$TMP/r4.agentA.orig"
cp "$D/agents/agentB.md" "$TMP/r4.agentB.orig"
okA=1; okB=1
mutate "$TMP/r4.agentA.orig" "$D/agents/agentA.md" '/^isolation:/{next} /^vf-requires:/{next} {print}' || okA=0
mutate "$TMP/r4.agentB.orig" "$D/agents/agentB.md" '/^isolation:/{next} /^vf-requires:/{next} {print}' || okB=0
if [ "$okA" -eq 0 ] || [ "$okB" -eq 0 ]; then
  ko "MUT-R4 désarmement (#38 rejoué) — retrait de isolation + vf-requires" "le programme de mutation a ÉCHOUÉ sur au moins un agent — mutant NON CONSTRUIT"
elif cmp -s "$D/agents/agentA.md" "$TMP/r4.agentA.orig" || cmp -s "$D/agents/agentB.md" "$TMP/r4.agentB.orig"; then
  ko "MUT-R4 désarmement (#38 rejoué) — retrait de isolation + vf-requires" "au moins un fichier n'a RIEN changé — mutant NON OPPOSABLE"
else
  rc_mut="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
  out_mut="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")"
  cp "$TMP/r4.agentA.orig" "$D/agents/agentA.md"
  cp "$TMP/r4.agentB.orig" "$D/agents/agentB.md"
  rc_back="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
  if [ "$rc_mut" -eq 0 ]; then
    ok "MUT-R4 désarmement (#38 rejoué) — isolation et vf-requires retirés des DEUX agents : le gate VERDIT (rc=0)"
  else
    ko "MUT-R4 désarmement — le gate doit verdir quand l'armement disparaît des deux artefacts" "rc=$rc_mut out=[$out_mut]"
  fi
  if [ "$rc_back" -eq 0 ]; then
    ok "MUT-R4 désarmement — fixture restaurée (armée + conforme) : le VERT est retrouvé (rc=0)"
  else
    ko "MUT-R4 désarmement — après restauration de l'état armé conforme, le gate doit être vert" "rc=$rc_back"
  fi
fi

# === Cas R5 — plancher : univers d'armement VIDE (aucun chemin déclaré) → 2, jamais 0 ==========
D="$(mk_regle4_fixture r5)"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "" "$PROV_LIST")"
out="$(run4 "$D" "" "$PROV_LIST")"
says_inerte=0; case "$out" in *"regle 4 serait INERTE"*) says_inerte=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$says_inerte" -eq 1 ]; then
  ok "R5 plancher — univers d'armement vide → 2, message nommant la règle 4 rendue INERTE (JAMAIS 0)"
else
  ko "R5 plancher univers d'armement vide → 2" "rc=$rc out=[$out]"
fi

# === Cas R6 — plancher : corpus de scripts sans AUCUN # vf-provides: → 2, jamais 0 =============
D="$(mk_regle4_fixture r6)"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md"
cat > "$D/scripts/aucun-marqueur.sh" <<'SCR'
#!/usr/bin/env bash
# aucun-marqueur.sh — fixture R6, ne déclare RIEN
set -uo pipefail
echo ok
SCR
rc="$(rc4_of "$D" "$ARMED_LIST" "$D/scripts/aucun-marqueur.sh")"
out="$(run4 "$D" "$ARMED_LIST" "$D/scripts/aucun-marqueur.sh")"
says_inerte=0; case "$out" in *"regle 4 serait INERTE"*) says_inerte=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$says_inerte" -eq 1 ]; then
  ok "R6 plancher — corpus de scripts sans aucun # vf-provides: → 2, message nommant la règle 4 rendue INERTE (JAMAIS 0)"
else
  ko "R6 plancher corpus de preuve sans marqueur → 2" "rc=$rc out=[$out]"
fi

# === Cas R7 — règle 4bis : vf-requires citant un id HORS de la table des ids légaux → 1 ========
# Artefact SANS armement (D-01 : la moitié déclarée reste ouverte), mais l'id cité est fantaisiste
# — hygiène de déclaration, symétrique de la règle 3.
D="$(mk_regle4_fixture r7)"
cat > "$D/agents/agentC.md" <<'AGT'
---
name: agent-fixture-4bis
vf-requires: id-fantaisiste-hors-table
---

# Agent sans armement, id inconnu (fixture règle 4bis)
AGT
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md
$D/agents/agentC.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
out="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")"
says_r4bis=0; case "$out" in *"ECART regle 4bis"*) says_r4bis=1 ;; esac
names_id=0;   case "$out" in *"id-fantaisiste-hors-table"*) names_id=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$says_r4bis" -eq 1 ] && [ "$names_id" -eq 1 ]; then
  ok "R7 règle 4bis — vf-requires citant un id hors table → 1, ECART regle 4bis nommant l'id inconnu"
else
  ko "R7 règle 4bis id hors table → 1" "rc=$rc regle4bis=$says_r4bis id=$names_id out=[$out]"
fi

# === Cas R7bis — règle 4, sous-cas (b) : id légal mais DIFFÉRENT de celui exigé par l'armement ==
# Additif (correction ciblée post-revue) : ce sous-cas était vérifié à la main par la revue mais
# n'avait aucun cas de test dédié — branche de production entièrement non exercée par la suite
# jusqu'ici (check-capability-activation.sh:623-627). Un artefact arme `isolation:` (exige
# `worktree-baseref`) mais cite `vf-requires: mcp-servers` — LÉGAL (table OKID) mais PAS l'id exigé
# par CET armement. Distinct de R7 (id hors table) et de MUT-R2 sous-cas (a) (vf-requires absent).
D="$(mk_regle4_fixture r7bis)"
cat > "$D/agents/agentE.md" <<'AGT'
---
name: agent-fixture-4b
isolation: worktree
vf-requires: mcp-servers
---

# Agent armé isolation, vf-requires légal mais DIFFÉRENT (fixture règle 4 sous-cas b)
AGT
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md
$D/agents/agentE.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
out="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")"
says_r4=0; case "$out" in *"ECART regle 4 :"*"agentE.md"*) says_r4=1 ;; esac
names_cite=0; case "$out" in *"vf-requires cite « mcp-servers »"*) names_cite=1 ;; esac
names_exige=0; case "$out" in *"pas id exige « worktree-baseref »"*) names_exige=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$says_r4" -eq 1 ] && [ "$names_cite" -eq 1 ] && [ "$names_exige" -eq 1 ]; then
  ok "R7bis règle 4 sous-cas (b) — vf-requires légal mais autre que l'id exigé → 1, ECART nommant les deux ids"
else
  ko "R7bis règle 4 sous-cas (b) — id légal autre que l'id exigé → 1" "rc=$rc regle4=$says_r4 cite=$names_cite exige=$names_exige out=[$out]"
fi

# === Cas R8 — contre-épreuve D-01 : vf-requires LÉGAL sans AUCUN armement → 0, jamais un écart ==
# La moitié déclarée de D-01 : un artefact peut annoncer une précondition légale que la liste close
# ne gouverne PAS encore (aucune clé `isolation:`). Ce n'est jamais un écart.
D="$(mk_regle4_fixture r8)"
cat > "$D/agents/agentD.md" <<'AGT'
---
name: agent-fixture-d01
vf-requires: mcp-servers
---

# Agent sans armement, id LEGAL (contre-épreuve D-01)
AGT
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md
$D/agents/agentD.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
if [ "$rc" -eq 0 ]; then
  ok "R8 contre-épreuve D-01 — vf-requires légal (mcp-servers) sans armement → 0, jamais un écart"
else
  ko "R8 contre-épreuve D-01 vf-requires légal sans armement → 0" "rc=$rc out=[$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")]"
fi

# === Cas R9 — non-régression : le compteur de lignes de CORPUS n'est PAS pollué par les corpus ==
# d'armement/de preuve neufs (garde ISARM/ISPRV insérée AVANT le bloc corpus SANS CONDITION).
D_BASE="$(mk_fixture nr_base)"
out_base="$(run "$D_BASE")"
lines_base=""
case "$out_base" in *" ligne(s)."*) lines_base="${out_base##*fichier(s) de corpus, }"; lines_base="${lines_base%% ligne*}" ;; esac
D_R4="$(mk_regle4_fixture nr_r4)"
ARMED_LIST="$D_R4/agents/agentA.md
$D_R4/agents/agentB.md"
PROV_LIST="$D_R4/scripts/provide.sh
$D_R4/scripts/decoy.sh"
out_r4="$(run4 "$D_R4" "$ARMED_LIST" "$PROV_LIST")"
lines_r4=""
case "$out_r4" in *" ligne(s)."*) lines_r4="${out_r4##*fichier(s) de corpus, }"; lines_r4="${lines_r4%% ligne*}" ;; esac
if [ -n "$lines_base" ] && [ "$lines_base" = "$lines_r4" ]; then
  ok "R9 non-régression — compteur de lignes de corpus inchangé ($lines_base) malgré l'ajout des corpus d'armement/de preuve"
else
  ko "R9 non-régression — le compteur de lignes de corpus doit rester inchangé" "base=$lines_base r4=$lines_r4 out_base=[$out_base] out_r4=[$out_r4]"
fi

# ===============================================================================================
# == RÈGLE 4 — armements MCP (Phase 28, plan 28-02) : seconde ligne de la liste close ============
# ===============================================================================================
# Les deux grammaires MCP (vf-mcp-consumer: true, vf-mcp-tools: <serveur>:<outils>) exigent
# désormais la même précondition mcp-servers (déjà légale dans OKID depuis 28-01). `decoy.sh`, déjà
# fabriqué par `mk_script_decoy` ci-dessus, porte `# vf-provides: mcp-servers` : réutilisé tel
# quel, aucun script de fixture neuf n'est nécessaire pour ces cas.

mk_agent_mcp_consumer_sans_requires() { # <chemin> — vf-mcp-consumer: true SANS vf-requires
  cat > "$1" <<'AGT'
---
name: agent-fixture-mcp-consumer
vf-mcp-consumer: true
---

# Agent MCP consumer sans precondition declaree (fixture regle 4, Phase 28-02)
AGT
}

mk_agent_mcp_consumer_avec_requires() { # <chemin> — vf-mcp-consumer: true + vf-requires legal
  cat > "$1" <<'AGT'
---
name: agent-fixture-mcp-consumer-ok
vf-mcp-consumer: true
vf-requires: mcp-servers
---

# Agent MCP consumer conforme (fixture regle 4, Phase 28-02)
AGT
}

mk_agent_mcp_tools_sans_requires() { # <chemin> — vf-mcp-tools: <serveur>:<outils> SANS vf-requires
  cat > "$1" <<'AGT'
---
name: agent-fixture-mcp-tools
vf-mcp-tools: XcodeBuildMCP:test_sim,build_sim,clean
---

# Agent MCP tools sans precondition declaree (fixture regle 4, Phase 28-02)
AGT
}

mk_agent_mcp_frontiere() { # <chemin> — vf-mcp-consumer: true + vf-requires HORS table (régle 4bis)
  cat > "$1" <<'AGT'
---
name: agent-fixture-mcp-frontiere
vf-mcp-consumer: true
vf-requires: mcp-servers-extra
---

# Agent vf-requires hors table des ids legaux (fixture regle 4bis, comparaison a frontiere)
AGT
}

# Piège anti-prose : AUCUN armement en frontmatter, mais le CORPS cite le préfixe de token MCP dans
# une phrase — reproduction fidèle de l'occurrence réelle mesurée à `vf-reviewer.md:45` (« ... c'est
# pour ça que tu portes `vf-mcp-tools`, une allowlist nommée injectée à l'install (jamais un token
# `mcp__` en dur dans ce fichier) »). Le gate ne lit QUE les clés entre les deux `---` : un gate qui
# chercherait le littéral dans le corps rougirait ici à tort.
mk_agent_mcp_prose() { # <chemin> — sans armement, prose citant le préfixe mcp__ dans le corps
  cat > "$1" <<'AGT'
---
name: agent-fixture-mcp-prose
---

# Agent sans armement (fixture anti-prose, regle 4, Phase 28-02)

Tu ne PRODUIS pas un verdict de compilation, tu en VERIFIES un — c'est pour ca que tu portes
`vf-mcp-tools`, une allowlist nommee injectee a l'install (jamais un token `mcp__` en dur dans ce
fichier). Protocole d'appel, non negociable :
AGT
}

echo ""
echo "== règle 4 — armements MCP (Phase 28-02) =="

# === Cas R10 — vf-mcp-consumer: true SANS vf-requires → 1 (règle 4, sous-cas a) ================
D="$(mk_regle4_fixture r10)"
mk_agent_mcp_consumer_sans_requires "$D/agents/agentF.md"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md
$D/agents/agentF.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
out="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")"
says_r4=0; case "$out" in *"ECART regle 4"*"agentF.md"*) says_r4=1 ;; esac
names_key=0; case "$out" in *"arme « vf-mcp-consumer »"*) names_key=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$says_r4" -eq 1 ] && [ "$names_key" -eq 1 ]; then
  ok "R10 règle 4 (mcp-consumer) — armé vf-mcp-consumer sans vf-requires → 1, ECART nommant agentF.md"
else
  ko "R10 règle 4 (mcp-consumer) sans vf-requires → 1" "rc=$rc regle4=$says_r4 cle=$names_key out=[$out]"
fi

# === Cas R11 — vf-mcp-consumer: true + vf-requires légal levé par decoy.sh (# vf-provides: mcp-servers) → 0
D="$(mk_regle4_fixture r11)"
mk_agent_mcp_consumer_avec_requires "$D/agents/agentG.md"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md
$D/agents/agentG.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
if [ "$rc" -eq 0 ]; then
  ok "R11 règle 4 (mcp-consumer) conforme — vf-requires légal levé par # vf-provides: mcp-servers (decoy.sh) → 0"
else
  ko "R11 règle 4 (mcp-consumer) conforme → 0" "rc=$rc out=[$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")]"
fi

# === Cas R12 — vf-mcp-tools: <serveur>:<outils> SANS vf-requires → 1 (seconde grammaire) =========
D="$(mk_regle4_fixture r12)"
mk_agent_mcp_tools_sans_requires "$D/agents/agentH.md"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md
$D/agents/agentH.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
out="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")"
says_r4=0; case "$out" in *"ECART regle 4"*"agentH.md"*) says_r4=1 ;; esac
names_key=0; case "$out" in *"arme « vf-mcp-tools »"*) names_key=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$says_r4" -eq 1 ] && [ "$names_key" -eq 1 ]; then
  ok "R12 règle 4 (mcp-tools) — armé vf-mcp-tools sans vf-requires → 1, la seconde grammaire arme au même titre"
else
  ko "R12 règle 4 (mcp-tools) sans vf-requires → 1" "rc=$rc regle4=$says_r4 cle=$names_key out=[$out]"
fi

# === Cas R13 — anti-prose : AUCUN armement, corps citant le préfixe mcp__ (piège vf-reviewer.md:45) → 0
D="$(mk_regle4_fixture r13)"
mk_agent_mcp_prose "$D/agents/agentI.md"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md
$D/agents/agentI.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
if [ "$rc" -eq 0 ]; then
  ok "R13 anti-prose — corps citant le préfixe mcp__ SANS armement en frontmatter → 0 (piège vf-reviewer.md:45)"
else
  ko "R13 anti-prose — le corps ne doit jamais être lu comme un armement" "rc=$rc out=[$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")]"
fi

# === Cas R14 — frontière : vf-requires citant un id HORS table (mcp-servers-extra) → 1 (règle 4bis)
# Preuve que la comparaison se fait par égalité STRICTE de clé (id in OKID), jamais par sous-chaîne :
# « mcp-servers-extra » n'est PAS « mcp-servers », même s'il le contient comme préfixe.
D="$(mk_regle4_fixture r14)"
mk_agent_mcp_frontiere "$D/agents/agentJ.md"
ARMED_LIST="$D/agents/agentA.md
$D/agents/agentB.md
$D/agents/agentJ.md"
PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
rc="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
out="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")"
says_r4bis=0; case "$out" in *"ECART regle 4bis"*) says_r4bis=1 ;; esac
names_id=0; case "$out" in *"mcp-servers-extra"*) names_id=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$says_r4bis" -eq 1 ] && [ "$names_id" -eq 1 ]; then
  ok "R14 règle 4bis — vf-requires « mcp-servers-extra » hors table (frontière stricte, pas une sous-chaîne de mcp-servers) → 1"
else
  ko "R14 règle 4bis — id hors table (frontière) → 1" "rc=$rc regle4bis=$says_r4bis id=$names_id out=[$out]"
fi

# === Cas R15 — mutation sur COPIES de l'arbre RÉEL : les 5 déclarations réelles, retrait de l'une
# fait rougir en nommant précisément l'artefact =================================================
# Copie des 5 artefacts réellement distribués dans un `mktemp -d` privé — l'arbre n'est JAMAIS
# écrit. Le corpus de preuve reste `decoy.sh` de la fixture (# vf-provides: mcp-servers, patron déjà
# éprouvé). L'état conforme des 5 copies est vérifié en premier, PUIS UNE seule est mutée
# (vf-requires retiré) — `cmp -s` atteste le changement, jamais `diff`.
REAL_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
REAL5=(
  "$REAL_ROOT/plugin/dev-orchestrator/agents/vf-coder.md"
  "$REAL_ROOT/plugin/dev-orchestrator/agents/vf-reviewer.md"
  "$REAL_ROOT/plugin/mobile-test-team/agents/vf-app-fixer.md"
  "$REAL_ROOT/plugin/mobile-test-team/agents/vf-test-orchestrator.md"
  "$REAL_ROOT/plugin/mobile-test-team/agents/vf-test-runner.md"
)
real5_present=1
for f in "${REAL5[@]}"; do
  [ -r "$f" ] || real5_present=0
done
if [ "$real5_present" -eq 1 ]; then
  D="$(mk_regle4_fixture r15)"
  mkdir -p "$D/real"
  ARMED_LIST=""
  for f in "${REAL5[@]}"; do
    b="$(basename "$f")"
    cp "$f" "$D/real/$b"
    ARMED_LIST="$ARMED_LIST$D/real/$b
"
  done
  PROV_LIST="$D/scripts/provide.sh
$D/scripts/decoy.sh"
  rc_ok="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
  if [ "$rc_ok" -eq 0 ]; then
    ok "R15 arbre réel (copie) — les 5 déclarations réelles, copiées, sont conformes → 0"
  else
    ko "R15 arbre réel (copie) conforme → 0" "rc=$rc_ok out=[$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")]"
  fi
  cp "$D/real/vf-coder.md" "$TMP/r15.vf-coder.orig"
  if ! mutate "$TMP/r15.vf-coder.orig" "$D/real/vf-coder.md" '/^vf-requires:/{next} {print}'; then
    ko "R15 mutation — retrait de vf-requires sur la copie de vf-coder.md" "le programme de mutation a ÉCHOUÉ — mutant NON CONSTRUIT"
  elif cmp -s "$D/real/vf-coder.md" "$TMP/r15.vf-coder.orig"; then
    ko "R15 mutation — retrait de vf-requires sur la copie de vf-coder.md" "la mutation n'a RIEN changé — mutant NON OPPOSABLE"
  else
    rc_mut="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
    out_mut="$(run4 "$D" "$ARMED_LIST" "$PROV_LIST")"
    cp "$TMP/r15.vf-coder.orig" "$D/real/vf-coder.md"
    rc_back="$(rc4_of "$D" "$ARMED_LIST" "$PROV_LIST")"
    names_it=0; case "$out_mut" in *"vf-coder.md"*) names_it=1 ;; esac
    if [ "$rc_mut" -eq 1 ] && [ "$names_it" -eq 1 ]; then
      ok "R15 mutation — vf-requires retiré de la copie de vf-coder.md (une des 5 déclarations réelles) : le gate ROUGIT (rc=1) en nommant précisément vf-coder.md"
    else
      ko "R15 mutation — retirer UNE des 5 déclarations réelles doit rougir en nommant l'artefact" "rc=$rc_mut nomme=$names_it out=[$out_mut]"
    fi
    if [ "$rc_back" -eq 0 ]; then
      ok "R15 mutation — vf-requires restauré sur la copie : le VERT est retrouvé (rc=0)"
    else
      ko "R15 mutation — le vert doit être retrouvé après restauration" "rc=$rc_back"
    fi
  fi
else
  echo "  · R15 arbre réel (copie) NON APPLICABLE — un des 5 artefacts réels est introuvable sous $REAL_ROOT"
fi

# ===============================================================================================
# == OPPOSABILITÉ DES PORTEURS DE PREUVE (# vf-provides:), Phase 28, plan 28-02 ==================
# ===============================================================================================
# Pourquoi cette garde existe. Un marqueur statique seul ne prouve rien : `ensure-design-deps.sh`
# déclare noir sur blanc « Contrat de sortie : toujours exit 0, SAUF VF_SCOPE invalide » —
# précondition non satisfaite comprise — et son unique câblage machine
# (`plugin/_internal/vibeflow-update.sh:581-586`) le traite en best-effort à l'install : les deux
# branches loguent, aucune n'échoue. Accepter la seule PRÉSENCE d'un `# vf-provides:` comme preuve
# reviendrait à rendre vert un gate adossé à un script incapable de rougir — c'est #38 rejoué d'un
# cran. Conséquence pratique : `ensure-design-deps.sh` NE PEUT PAS déclarer `# vf-provides:` en
# l'état ; lui donner un mode de vérification discriminant est un candidat de backlog nommé (D-05),
# pas un livrable de cette phase.
#
# Aucun script ne peut donc porter `# vf-provides:` sans qu'une ligne de CETTE table, exécutée pour
# de vrai, établisse qu'il sait rendre le code de sortie EXACT déclaré quand sa précondition manque
# — jamais « non nul », qui laisserait passer un porteur qui ne sait dire que « je ne peux pas me
# prononcer » (le sous-état 3 INDÉTERMINÉ, cousin du cran de `ensure-design-deps.sh` que cette
# garde existe pour fermer).

# --- Table nommée, écrite à la main (A-2, D-02b) : une ligne par porteur. Aujourd'hui UNE entrée.
PROV_TABLE_ID=(mcp-servers)
PROV_TABLE_SCRIPT=("plugin/dev-orchestrator/scripts/inject-mcp-tools.sh")
PROV_TABLE_EXPECT_RED=(1)

# --- Découverte du corpus RÉEL de porteurs distribués : deux dispositions, comme le gate lui-même
# (`plugin/*/scripts/*.sh` en dépôt, `.claude/scripts/*.sh` en lab installé, s'il existe). Résolue
# par VF_CAPACT_PROVIDERS — MÊME contrat de surcharge que le gate — pour rendre cette découverte
# elle-même testable par mutation sur une copie, sans jamais écrire dans l'arbre réel.
vf_capact_test_discover_provider_scripts() { # -> chemins des scripts a balayer, un par ligne
  if [ -n "${VF_CAPACT_PROVIDERS+x}" ]; then
    printf '%s\n' "$VF_CAPACT_PROVIDERS"
    return 0
  fi
  for f in "$REAL_ROOT"/plugin/*/scripts/*.sh; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
  if [ -d "$REAL_ROOT/.claude/scripts" ]; then
    for f in "$REAL_ROOT"/.claude/scripts/*.sh; do
      [ -f "$f" ] && printf '%s\n' "$f"
    done
  fi
}

# --- Extraction des ids # vf-provides: dans le bloc de commentaires de tete de CHAQUE script du
# corpus (jusqu'a la premiere ligne NON commentee — meme frontiere que le gate). awk, jamais grep
# pipe (le grep proxifie de ce poste tronque silencieusement, constat inscrit dans le gate).
vf_capact_test_provider_ids() { # <chemins sur stdin, un par ligne> -> ids, un par ligne
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -r "$f" ] || continue
    awk '
      FNR==1 { open=1 }
      open {
        if ($0 !~ /^#/) { open=0; next }
        if ($0 ~ /^# vf-provides: /) {
          id=$0; sub(/^# vf-provides: /,"",id); gsub(/^[ \t]+/,"",id); gsub(/[ \t]+$/,"",id)
          if (id != "") print id
        }
      }
    ' "$f"
  done
}

REAL_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

echo ""
echo "== opposabilité des porteurs de preuve (# vf-provides:), Phase 28-02 =="

DISK_IDS="$(vf_capact_test_discover_provider_scripts | vf_capact_test_provider_ids | sort -u)"
TABLE_IDS_SORTED="$(printf '%s\n' "${PROV_TABLE_ID[@]}" | sort -u)"
n_disk=$(printf '%s\n' "$DISK_IDS" | grep -c . || true)
n_table=$(printf '%s\n' "$TABLE_IDS_SORTED" | grep -c . || true)
only_disk="$(comm -23 <(printf '%s\n' "$DISK_IDS") <(printf '%s\n' "$TABLE_IDS_SORTED"))"
only_table="$(comm -13 <(printf '%s\n' "$DISK_IDS") <(printf '%s\n' "$TABLE_IDS_SORTED"))"

if [ "$n_disk" -eq 0 ] || [ "$n_table" -eq 0 ]; then
  ko "opposabilité plancher — ensemble vide (disque=$n_disk, table=$n_table)" "une garde qui ne surveille personne ne prouve rien"
else
  ok "opposabilité plancher — ensembles non vides (disque=$n_disk porteur(s), table=$n_table entrée(s), état attendu : exactement UN porteur, inject-mcp-tools.sh)"
fi
if [ -z "$only_disk" ]; then
  ok "opposabilité — aucun porteur non tabulé (comparaison d ensembles par comm)"
else
  ko "opposabilité — porteur non opposable : aucun cas ne prouve sa discriminance" "only_disk=[$only_disk]"
fi
if [ -z "$only_table" ]; then
  ok "opposabilité — aucune entrée de table périmée (comparaison par comm)"
else
  ko "opposabilité — entrée de table périmée (aucun porteur sur disque)" "only_table=[$only_table]"
fi

# --- Plancher (mutation) : corpus VIDE des deux côtés — VF_CAPACT_PROVIDERS pointe un répertoire
# vide, seule la fonction de découverte est testée ici (la table, elle, garde son unique entrée
# réelle : c'est la comparaison disque-vide qui doit être vue, jamais un artefact du fixturing).
EMPTY_PROV_DIR="$TMP/opposabilite-vide"
mkdir -p "$EMPTY_PROV_DIR"
DISK_IDS_VIDE="$(VF_CAPACT_PROVIDERS="" vf_capact_test_discover_provider_scripts | vf_capact_test_provider_ids | sort -u)"
n_disk_vide=$(printf '%s\n' "$DISK_IDS_VIDE" | grep -c . || true)
if [ "$n_disk_vide" -eq 0 ]; then
  ok "opposabilité plancher (mutation) — VF_CAPACT_PROVIDERS=\"\" rend un corpus VRAIMENT vide (0 id), le plancher se déclencherait"
else
  ko "opposabilité plancher (mutation) — VF_CAPACT_PROVIDERS=\"\" doit rendre un corpus vide" "n_disk_vide=$n_disk_vide"
fi

# --- Mutation sur COPIE : un script portant # vf-provides: faux-id, absent de la table, DOIT faire
# échouer la comparaison. L'arbre réel n'est JAMAIS touché — copie complète du corpus de scripts
# dans un `mktemp -d` privé, VF_CAPACT_PROVIDERS pointe la suite sur cette copie (jamais sur le
# dépôt), aucune écriture ni « restauration » après coup n'a lieu sur l'arbre distribué.
COPY_CORPUS="$TMP/opposabilite-corpus"
mkdir -p "$COPY_CORPUS"
for f in "$REAL_ROOT"/plugin/*/scripts/*.sh; do
  [ -f "$f" ] || continue
  cp "$f" "$COPY_CORPUS/"
done
cat > "$COPY_CORPUS/faux-porteur.sh" <<'SCR'
#!/usr/bin/env bash
# faux-porteur.sh — fixture opposabilité (Phase 28-02), porteur NON TABULÉ
# vf-provides: faux-id
set -uo pipefail
echo ok
SCR
COPY_LIST="$(for f in "$COPY_CORPUS"/*.sh; do printf '%s\n' "$f"; done)"
DISK_IDS_MUT="$(VF_CAPACT_PROVIDERS="$COPY_LIST" vf_capact_test_discover_provider_scripts | vf_capact_test_provider_ids | sort -u)"
mut_only_disk="$(comm -23 <(printf '%s\n' "$DISK_IDS_MUT") <(printf '%s\n' "$TABLE_IDS_SORTED"))"
if [ -n "$mut_only_disk" ]; then
  ok "opposabilité mutation — porteur NON TABULÉ (faux-id) ajouté sur COPIE (jamais l'arbre réel) : la comparaison échoue (only_disk=[$mut_only_disk])"
else
  ko "opposabilité mutation — un porteur non tabulé doit faire échouer la comparaison" "mut_only_disk vide alors qu'un faux porteur a été ajouté sur la copie"
fi

# --- Discriminance PROUVÉE PAR EXÉCUTION RÉELLE, pour l'unique entrée de la table (mcp-servers).
# Isolation hermétique du scope GLOBAL (même patron que test-inject-mcp-tools.sh, Phase 21 Geste B) :
# VF_CLAUDE_JSON pointe un chemin qui n'existe jamais, indifférent à la config personnelle du poste.
PROVIDER_SCRIPT="$REAL_ROOT/${PROV_TABLE_SCRIPT[0]}"
D_PROV="$TMP/opposabilite-verify"
mkdir -p "$D_PROV"
ABSENT_CLAUDE_JSON="$D_PROV/absent-claude.json"

# Sens ROUGE : .mcp.json déclare un serveur (fixture-mcp-server), rendant `servers` non vide (donc
# le verdict peut atteindre exit 1, pas le 3 de l'environnement totalement privé) ; l'agent porte
# `vf-mcp-consumer: true` (sans ce marqueur il n'est pas retenu comme cible, `determined` reste faux
# et le verdict serait 3, pas 1) et cite dans `tools:` un serveur INCONNU (`serveur-fantome`) au lieu
# du serveur exigé — le token attendu (mcp__fixture-mcp-server__*) reste donc manquant.
RED_AGENT="$D_PROV/rouge.md"
cat > "$RED_AGENT" <<'AGT'
---
name: agent-fixture-mcpprov-rouge
vf-mcp-consumer: true
tools: Read, Bash, mcp__serveur-fantome__outil
---

# Agent MCP consumer citant un serveur inconnu (fixture opposabilité, regle 4, Phase 28-02)
AGT
RED_MCP="$D_PROV/mcp-rouge.json"
printf '{ "mcpServers": { "fixture-mcp-server": {} } }' > "$RED_MCP"
rc_red=0
VF_CLAUDE_JSON="$ABSENT_CLAUDE_JSON" bash "$PROVIDER_SCRIPT" --target "$RED_AGENT" --mcp-json "$RED_MCP" --verify --strict >/dev/null 2>&1 || rc_red=$?
if [ "$rc_red" -eq 1 ]; then
  ok "opposabilité (mcp-servers, sens rouge) — précondition manquante -> code EXACT 1 (jamais « non nul »)"
else
  ko "opposabilité (mcp-servers, sens rouge) -> 1" "rc=$rc_red"
fi

# Sens VERT : la fixture réutilise le MÉCANISME EXACT du cas conforme déjà écrit dans
# test-inject-mcp-tools.sh (T11 — injecter PUIS vérifier) plutôt que de fabriquer à la main la
# chaîne mcp__<serveur>__* attendue, qui rougirait en « serveur manquant » (missing) au moindre
# écart de forme. Même marqueur d'éligibilité que le sens rouge (vf-mcp-consumer: true).
GREEN_AGENT="$D_PROV/vert.md"
cat > "$GREEN_AGENT" <<'AGT'
---
name: agent-fixture-mcpprov-vert
vf-mcp-consumer: true
tools: Read, Bash
---

# Agent MCP consumer, cas conforme (fixture opposabilité, regle 4, Phase 28-02)
AGT
GREEN_MCP="$D_PROV/mcp-vert.json"
printf '{ "mcpServers": { "fixture-mcp-server": {} } }' > "$GREEN_MCP"
VF_CLAUDE_JSON="$ABSENT_CLAUDE_JSON" bash "$PROVIDER_SCRIPT" --target "$GREEN_AGENT" --mcp-json "$GREEN_MCP" >/dev/null 2>&1
rc_green=0
VF_CLAUDE_JSON="$ABSENT_CLAUDE_JSON" bash "$PROVIDER_SCRIPT" --target "$GREEN_AGENT" --mcp-json "$GREEN_MCP" --verify --strict >/dev/null 2>&1 || rc_green=$?
if [ "$rc_green" -eq 0 ]; then
  ok "opposabilité (mcp-servers, sens vert) — précondition satisfaite (injectée puis relue) -> code EXACT 0 : DISCRIMINANCE prouvée dans les deux sens"
else
  ko "opposabilité (mcp-servers, sens vert) -> 0" "rc=$rc_green"
fi

# Cas nommé distinct : environnement TOTALEMENT privé de source (aucun .mcp.json exploitable, scope
# global neutralisé) -> 3 INDÉTERMINÉ, JAMAIS 1. Documente dans la suite elle-même que les deux sens
# d'échec du porteur ne sont pas confondus — un « non nul » sur ce cas laisserait passer un porteur
# qui ne sait dire que « je ne peux pas me prononcer », le cousin du cran de ensure-design-deps.sh.
IND_AGENT="$D_PROV/indetermine.md"
cat > "$IND_AGENT" <<'AGT'
---
name: agent-fixture-mcpprov-indetermine
vf-mcp-consumer: true
tools: Read, Bash
---

# Agent MCP consumer sans aucune source de serveur (fixture opposabilité, Phase 28-02)
AGT
EMPTY_MCP="$D_PROV/mcp-vide.json"
printf '{ "mcpServers": {} }' > "$EMPTY_MCP"
rc_ind=0
VF_CLAUDE_JSON="$ABSENT_CLAUDE_JSON" bash "$PROVIDER_SCRIPT" --target "$IND_AGENT" --mcp-json "$EMPTY_MCP" --verify --strict >/dev/null 2>&1 || rc_ind=$?
if [ "$rc_ind" -eq 3 ]; then
  ok "opposabilité (mcp-servers) — environnement totalement privé de source -> code EXACT 3, distinct du sens rouge (1) : les deux échecs ne sont jamais confondus"
else
  ko "opposabilité (mcp-servers) — environnement sans aucune source -> 3, distinct de 1" "rc=$rc_ind"
fi

# === Cas final — contrôle sur l'arbre RÉEL ====================================================
# NON discriminant à lui seul (il ne prouve que l'absence d'écart aujourd'hui) : il vient donc
# APRÈS les mutations, et jamais à leur place.
#
# Il est de surcroît CONDITIONNÉ à la présence des trois artefacts. Dans un lab installé en scope
# UTILISATEUR (`~/.claude/scripts/`), le gate ne peut pas savoir quel lab il sert : exiger 0 y
# ferait rougir la suite du module pour une raison qui n'a rien à voir avec sa qualité. Le cas
# annonce alors ce qui manque, et ne se prétend jamais vert : c'est un contrôle NON APPLICABLE,
# pas un contrôle réussi. En intégration continue les trois artefacts sont là, et le contrôle est
# donc réellement exercé à chaque exécution.
echo ""
echo "== contrôle sur l'arbre réel =="
REAL_REF="$(cd "$(dirname "$0")/../.." && pwd)/references"
REAL_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
if [ -r "$REAL_REF/gsd-capabilities-index.md" ] && [ -r "$REAL_REF/intent-routing.md" ] \
   && [ -r "$REAL_ROOT/.planning/config.json" ]; then
  bash "$SCRIPT" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 0 ]; then
    ok "15 contrôle réel — le gate sort 0 sur le dépôt (état livré par les plans 24-06 et 24-13)"
  else
    ko "15 contrôle réel — le gate doit sortir 0 sur le dépôt" "rc=$rc — $(bash "$SCRIPT" 2>&1 >/dev/null)"
  fi
else
  echo "  · 15 contrôle réel NON APPLICABLE — les trois artefacts ne sont pas réunis sous $REAL_ROOT (installation en scope utilisateur ?)"
fi

echo ""
echo "== bilan : $((PASS + FAIL)) cas — $PASS OK / $FAIL KO =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
