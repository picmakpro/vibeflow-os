#!/usr/bin/env bash
# check-map-drift.sh — La carte que déclare un CLAUDE.md/index correspond-elle au disque ? (G3)
#
# Rôle (ADR-055 §3, même clause que check-doc-drift.sh) : répondre au FAIT, jamais au métier. Ce
# script ne dit JAMAIS qu'une carte est fausse ou périmée — seulement qu'une entrée déclarée n'a
# pas de contrepartie sur le disque, ou qu'un élément suivi n'est cité par aucune carte. Le
# jugement appartient à l'agent (ou à l'utilisateur), pas à ce script.
#
# Deux paires v1, bidirectionnelles, chacune balayée comme une famille de « cartes » distincte :
#   P1 — carte de dossiers d'un CLAUDE.md ↔ disque. Sens A : pointeurs @chemin et segments entre
#        accents graves contenant un séparateur '/' cités par la carte, dont l'existence sur le
#        disque est constatée. Sens B : sous-dossiers de premier niveau suivis par git sous
#        --path, dont la citation par la carte est constatée.
#   P2 — index de dossier (_index.md ou INDEX.md, suivi par git) ↔ contenu DIRECT (non récursif)
#        de son dossier. Sens A : cibles *.md citées par l'index (lien markdown ou accents
#        graves), dont l'existence dans le dossier de l'index est constatée. Sens B : fichiers
#        *.md suivis par git directement dans ce dossier (hors l'index lui-même), dont la
#        citation par l'index est constatée.
#
# Usage:
#   check-map-drift.sh [--path <dir>] [--map <fichier>] [--hook] [--quiet]
# Defaults: --path .
#
# --map <fichier> borne le recensement P1 à ce seul fichier (au lieu du balayage git ls-files des
# CLAUDE.md sous --path). N'affecte pas P2 : les index _index.md/INDEX.md restent balayés sous
# --path, --map ou pas.
#
# --hook change UNIQUEMENT la cohérence d'interface avec les autres gates du dépôt (parité de
# grammaire) ; ce script n'a qu'un seul gabarit de signal, --hook n'altère aucun rendu — il ne
# sert qu'au gate de mutuelle exclusion avec --quiet.
#
# Exit codes:
#   0  = au moins une divergence constatée, signal [map-drift] émis
#   3  = NON VÉRIFIABLE (0 carte balayée — hors dépôt git, cible absente, ou aucune carte trouvée)
#        OU 0 divergence sur >= 1 carte balayée (rien à signaler)
#   64 = argument inconnu, --path/--map sans valeur, ou --hook + --quiet ensemble
#   1  = RÉSERVÉ à un futur mode bloquant — jamais rendu par cette version.
#
# Bornes — ce que ce gate ne couvre PAS, et pourquoi :
#   a) les `skills:` de frontmatter d'agent — déjà couverts par check-agents.sh (ADR-044) ;
#      dupliquer produirait deux verdicts divergents sur le même axe.
#   b) les fichiers de DAG de mission (*.dag.json) — hors domaine, et adjacents au socle de
#      périmètre `--scope` que la Phase 29 protège par construction (D-03).
#   c) .planning/ — lu, jamais écrit ; propriété du moteur GSD amont (ADR-055).
#   d) la QUALITÉ d'une carte — ce gate constate un écart d'ENSEMBLES, il ne juge jamais qu'une
#      carte est fausse ou périmée (le jugement reste à l'agent/l'utilisateur, cf. rôle ci-dessus).
#   e) plugin/reference/content/examples/ — cartes d'un lab FICTIF (PetitsCoursFlow, exemple
#      pédagogique) ; les vérifier reviendrait à exiger que la fiction existe sur disque (exec-02
#      tour 5, cf. EXAMPLES_PREFIX ci-dessous).
#
# Absence de mode correctif, assumée (ADR-031) : cette version CONSTATE seulement. Toute évolution
# vers un correctif serait gardée par le garde-fou trois temps déjà éprouvé dans ce dépôt
# (reformulation du nombre et de la liste affectée, attente d'un oui explicite, interdiction en
# mission d'équipe et en mode autonome) — jamais activée par défaut.
#
# Limite de portée déclarée : « carte balayée » ≠ « carte correcte » — un compteur de cartes
# balayées non nul avec zéro divergence signifie que les ENSEMBLES comparés coïncident, pas que
# la documentation dit vrai.
#
# Durcissement git (V5, motif T-29-02-01) : --path pointe potentiellement vers un dépôt cloné non
# maîtrisé — sa configuration (.git/config) ne doit jamais pouvoir faire exécuter un programme
# lors d'une simple lecture. TOUTES les invocations git passent par le wrapper unique git_safe(),
# copié verbatim de check-doc-drift.sh:106-115.
set -uo pipefail
shopt -s nullglob

ROOT="."
MAP_FILE=""
HOOK=0
QUIET=0
# Borne (b), exec-02 tour 5 : les cartes sous ce préfixe décrivent un lab FICTIF (PetitsCoursFlow,
# exemple pédagogique de plugin/reference/) — les vérifier reviendrait à exiger que la fiction
# existe sur disque, jamais une divergence réelle. Exclusion par préfixe, appliquée aux DEUX
# balayages automatiques (P1 et P2) en amont de la collecte des cartes — jamais un filtre de
# sortie sur les findings déjà produits (principe directeur du mandat).
EXAMPLES_PREFIX="plugin/reference/content/examples/"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -lt 2 ] && { echo "[check-map-drift] --path nécessite une valeur" >&2; exit 64; }
      ROOT="$2"; shift 2 ;;
    --map)
      [ "$#" -lt 2 ] && { echo "[check-map-drift] --map nécessite une valeur" >&2; exit 64; }
      MAP_FILE="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-map-drift] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique.
[ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ] && { echo "[check-map-drift] --hook et --quiet sont mutuellement exclusifs" >&2; exit 64; }

say() { [ "$QUIET" -eq 1 ] || echo "[check-map-drift] $*" >&2; }

# --- Durcissement git — motif écrit une seule fois, appliqué par TOUTES les invocations git. ----
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() { # <args...> — toute invocation git de ce script passe par ici, jamais un appel nu.
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}

INSIDE_GIT=1
git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1 || { INSIDE_GIT=0; say "$ROOT hors d'un arbre de travail git (ou cible absente) — rien à constater."; }

CARTES_BALAYEES=0
DIVERGENCES=0
DETAILS=()

# Compaction budget (exec-02 tour 5) : les 4 sites d'émission de divergence (P1 sens A/B, P2 sens
# A/B) partageaient le même motif à 4 lignes — factorisé ici, aucun garde-fou ni message perdu.
record_divergence() { # <message>
  DIVERGENCES=$((DIVERGENCES + 1))
  DETAILS+=("  - $1")
}

# --- Utilitaires communs -------------------------------------------------------------------------

# Dossier d'un chemin relatif ('.' si le chemin est déjà à la racine) — jamais un appel externe.
dirname_of() { # <relpath>
  case "$1" in
    */*) printf '%s' "${1%/*}" ;;
    *) printf '%s' "." ;;
  esac
}

# Sous-dossiers de premier niveau suivis par git sous $ROOT (un par ligne), dot-préfixés et
# node_modules déjà exclus.
top_level_dirs() {
  git_safe ls-files 2>/dev/null | awk -F/ 'NF>1{print $1}' | sort -u | {
    while IFS= read -r d; do
      case "$d" in
        .*|node_modules) : ;;
        *) printf '%s\n' "$d" ;;
      esac
    done
  }
}

# --- Paire P1 : carte de dossiers d'un CLAUDE.md ↔ disque ----------------------------------------

# Tokens de chemin bruts (avec @/accents graves) d'une carte P1 : pointeurs @chemin, et segments
# entre accents graves contenant un séparateur '/' (un mot en accents graves sans '/' est un
# identifiant, jamais un chemin — exclu par construction du motif, pas par filtre après-coup).
# Borne (a), exec-02 tour 5 : une LIGNE DE COMMANDE citée en accents graves n'est pas un chemin
# déclaré par la carte, même si l'un de ses arguments contient un '/' (ex. `bash script.sh --x`,
# `git config core.hooksPath scripts/hooks`). Règle qui capture la CLASSE, pas les deux chaînes
# observées : un jeton multi-mots dont le TOUT PREMIER mot (avant le premier espace) ne contient
# aucun '/' est une invocation verbe+arguments, jamais un chemin — un vrai chemin, même à espace
# dans son nom, porte son '/' dès son premier mot ('refs/un nom.md' -> premier mot 'refs/un'),
# donc reste testé normalement (aucun chemin légitime mangé, cf. suite : cas P1-A-espace).
is_command_invocation() { # <raw-backtick-token>
  local inner="${1#\`}" first
  inner="${inner%\`}"
  first="${inner%% *}"
  case "$first" in
    */*) return 1 ;;
    *) [ "$first" != "$inner" ] ;;
  esac
}

extract_p1_tokens_raw() { # <file>
  grep -oE '@[A-Za-z0-9_./-]+' "$1" 2>/dev/null
  grep -oE '`[^`]*/[^`]*`' "$1" 2>/dev/null | while IFS= read -r raw; do
    is_command_invocation "$raw" || printf '%s\n' "$raw"
  done
}

normalize_token() { # <raw-token> -> chemin normalisé (sans @, sans accents graves, sans / final)
  local t="$1"
  t="${t#@}"
  t="${t#\`}"
  t="${t%\`}"
  t="${t%/}"
  printf '%s' "$t"
}

p1_sens_a() { # <card-file> <card-label>
  local card="$1" label="$2" raw tok
  while IFS= read -r raw; do
    [ -n "$raw" ] || continue
    tok="$(normalize_token "$raw")"
    [ -n "$tok" ] || continue
    # Un token à '/' de tête (ex. @/etc/passwd) est un chemin ABSOLU du système de fichiers, hors
    # domaine de cette carte (repo-relative par construction). Le concaténer tel quel à $ROOT
    # produirait un chemin composite qui n'existe jamais, même quand la cible absolue existe
    # réellement sur le disque — faux positif constaté (T-29-02-02 correctif). On l'ignore, sans
    # jamais tester d'existence hors de $ROOT (ADR-031 : ce gate ne lit rien hors sa cible).
    case "$tok" in
      /*) continue ;;
    esac
    [ -e "$ROOT/$tok" ] || record_divergence "${label} : entrée déclarée sans contrepartie — ${tok}"
  done < <(extract_p1_tokens_raw "$card")
}

p1_sens_b() { # <card-file> <card-label>
  local card="$1" label="$2" d tok found
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    found=0
    while IFS= read -r tok; do
      [ -n "$tok" ] || continue
      tok="$(normalize_token "$tok")"
      case "$tok" in
        "$d") found=1; break ;;
        "$d"/*) found=1; break ;;
      esac
    done < <(extract_p1_tokens_raw "$card")
    [ "$found" -eq 0 ] && record_divergence "${label} : élément suivi non cité — ${d}"
  done < <(top_level_dirs)
}

p1_cards=()
if [ -n "$MAP_FILE" ]; then
  [ -f "$MAP_FILE" ] && p1_cards+=("$MAP_FILE")
elif [ "$INSIDE_GIT" -eq 1 ]; then
  while IFS= read -r f; do
    case "$f" in "$EXAMPLES_PREFIX"*) continue ;; esac
    case "${f##*/}" in
      CLAUDE.md) p1_cards+=("$ROOT/$f") ;;
    esac
  done < <(git_safe ls-files 2>/dev/null)
fi

if [ "${#p1_cards[@]}" -gt 0 ]; then
  for card in "${p1_cards[@]}"; do
    [ -f "$card" ] || continue
    CARTES_BALAYEES=$((CARTES_BALAYEES + 1))
    p1_sens_a "$card" "$card"
    p1_sens_b "$card" "$card"   # P1-SENS-B-CALL
  done
fi

# --- Paire P2 : index de dossier ↔ contenu direct de son dossier ---------------------------------

# Cibles *.md brutes citées par un index : lien markdown [texte](cible.md), ou segment entre
# accents graves se terminant par .md.
extract_p2_entries_raw() { # <file>
  grep -oE '\]\([^)]*\.md\)' "$1" 2>/dev/null | sed -e 's/^\](//' -e 's/)$//'
  grep -oE '`[^`]*\.md`' "$1" 2>/dev/null | sed -e 's/^`//' -e 's/`$//'
}

# Normalise un chemin RELATIF pour comparaison ensembliste par ÉGALITÉ DE CHAÎNE — bash pur
# (ADR-054, ni jq/sed -i/grep -P/readlink -f). Traite la CLASSE des formes d'écriture équivalentes,
# pas un cas nommé isolément (motif de récidive, cf. mandat exec-02 tours 1-3) :
#   - segments './' de tête, un ou répétés ('./a', './/a', '././a') -> retirés jusqu'à épuisement
#   - séparateurs '/' redondants, en tête ('//a') comme internes ('a//b') -> réduits à un seul '/'
#   - '/' final -> retiré
# Décision explicite sur '../' : PAS résolu ici, par choix — une résolution lexicale de '../' sans
# connaître la racine du dépôt permettrait à un chemin cité de désigner une cible HORS de $ROOT,
# même risque de traversée que celui déjà écarté pour les tokens absolus en p1_sens_a (ADR-031 :
# ce gate ne teste jamais rien hors de sa cible). Un '../' résiduel après normalisation reste donc
# tel quel : il ne correspondra jamais à un chemin rendu par `git ls-files` (qui n'en émet jamais)
# et le cas reste marqué NON RECONNU dans la table de test — un choix documenté, pas un oubli.
#
# Asymétrie documentée avec p1_sens_a (:170-172) : celui-ci EXCLUT explicitement les tokens '/*'
# comme hors domaine (ADR-031, absolus). Ici, un '/' de tête est au contraire silencieusement
# retiré (traité comme du bruit de forme relative), donc '/etc/x.md' redevient 'etc/x.md' — sans
# risque : cette fonction ne teste jamais l'existence sur le disque (seul p2_sens_a le fait, via
# '-e', jamais sur une chaîne issue de normalize_path) et ne sort donc jamais de $ROOT.
normalize_path() { # <chemin> -> chemin normalisé
  local p="$1" slash="/" double="//" prev
  # Slash porté par variable, jamais littéral dans le motif de substitution : l'échappement
  # '\/' en position de REMPLACEMENT n'est pas déséchappé par bash (seuls '&' et '\\' le sont
  # dans ${var//pat/repl}) — un remplacement '\/' littéral insère un backslash constaté à l'essai,
  # bug qui aurait recréé le motif de récidive une quatrième fois s'il n'avait pas été prouvé ici.
  #
  # Point fixe (tour 4, correctif de la récidive) : les TROIS transformations reboucLENT ENSEMBLE
  # jusqu'à stabilité, jamais en deux passes indépendantes — un squeeze de '//' EXPOSE parfois un
  # './' de tête (ex. '//./a.md' -> '/./a.md' après squeeze) qu'une passe de strip déjà terminée
  # ne revoit jamais ('//./a.md' rendait alors './a.md' au lieu de 'a.md'). Garde-fou de
  # terminaison : la boucle s'arrête dès qu'une itération entière ne change plus $p — chaque
  # transformation qui s'applique retire au moins un caractère, jamais l'inverse, donc le nombre
  # d'itérations est borné par la longueur de $p (pas de boucle infinie possible).
  prev=""
  while [ "$prev" != "$p" ]; do
    prev="$p"
    while case "$p" in *//*) true ;; *) false ;; esac; do
      p="${p//$double/$slash}"
    done
    case "$p" in ./*) p="${p#./}" ;; esac
    case "$p" in /*) p="${p#/}" ;; esac
  done
  p="${p%/}"
  printf '%s' "$p"
}

# p2_sens_a s'appuie sur `-e` (existence disque) : le système de fichiers résout déjà lui-même
# './', '//' et '/' final au moment du test — aucune normalisation de chaîne n'y est nécessaire,
# même raison que p1_sens_a (commentaire ci-dessous). Seul p2_sens_b compare deux CHAÎNES sans
# jamais toucher le disque : c'est le seul site qui a besoin de normalize_path(), appliquée aux
# DEUX côtés de la comparaison pour rester symétrique.
p2_sens_a() { # <card-relpath> <card-label>
  local card_rel="$1" label="$2" dossier raw target
  dossier="$(dirname_of "$card_rel")"
  while IFS= read -r raw; do
    [ -n "$raw" ] || continue
    # Mitigation STRIDE (Information Disclosure, 29-05 STRIDE register) : une entrée '../' de tête
    # ferait sortir 'target' de $ROOT — même traversée que l'absolu déjà écarté en p1_sens_a
    # (:170-172). Le '-e' révélerait alors l'existence d'un chemin HORS domaine. Ignorée, sans
    # jamais tester hors de $ROOT (ADR-031) ; résidu documenté : un '../' non initial (interne à
    # 'raw') n'est pas couvert par cette mitigation triviale.
    case "$raw" in ../*) continue ;; esac
    if [ "$dossier" = "." ]; then
      target="$ROOT/$raw"
    else
      target="$ROOT/$dossier/$raw"
    fi
    [ -e "$target" ] || record_divergence "${label} : entrée déclarée sans contrepartie — ${raw}"
  done < <(extract_p2_entries_raw "$ROOT/$card_rel")
}

p2_sens_b() { # <card-relpath> <card-label>
  local card_rel="$1" label="$2" dossier f fdir entry found target_rel f_norm
  dossier="$(dirname_of "$card_rel")"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in *.md) : ;; *) continue ;; esac
    [ "$f" = "$card_rel" ] && continue
    fdir="$(dirname_of "$f")"
    [ "$fdir" = "$dossier" ] || continue
    found=0
    # '$f' est invariant pour toute la boucle interne ci-dessous (fixé ci-dessus) — normalisé UNE
    # SEULE fois ici, jamais reforké à chaque itération de la boucle interne sur 'entry'.
    f_norm="$(normalize_path "$f")"
    # Comparaison sur le chemin résolu COMPLET, jamais un match de suffixe de basename : un match
    # de suffixe fait matcher 'refs/orphan.md' par une entrée 'refs/sub/orphan.md' qui cite un
    # fichier différent — faux négatif du gate constaté (correctif P2 sens B, tour 0).
    #
    # Les DEUX côtés de la comparaison passent par normalize_path() — jamais un seul : 'entry'
    # (la citation brute de l'index) ET '$f' (le chemin rendu par `git ls-files`, déjà canonique
    # en pratique mais normalisé quand même pour ne dépendre d'aucune garantie implicite de git).
    # Traiter uniquement 'entry' avait produit un faux positif symétrique au tour 2 (une citation
    # './a.md' réduite à 'a.md' pouvait cesser de matcher '$f' selon la forme exacte rendue par
    # git) — normaliser les deux côtés élimine la classe entière, pas seulement le cas nommé.
    while IFS= read -r entry; do
      [ -n "$entry" ] || continue
      entry="$(normalize_path "$entry")"
      [ -n "$entry" ] || continue
      if [ "$dossier" = "." ]; then
        target_rel="$entry"
      else
        target_rel="$dossier/$entry"
      fi
      if [ "$(normalize_path "$target_rel")" = "$f_norm" ]; then found=1; break; fi
    done < <(extract_p2_entries_raw "$ROOT/$card_rel")
    [ "$found" -eq 0 ] && record_divergence "${label} : élément suivi non cité — ${f}"
  done < <(git_safe ls-files 2>/dev/null)
}

p2_cards=()
if [ "$INSIDE_GIT" -eq 1 ]; then
  while IFS= read -r f; do
    case "$f" in "$EXAMPLES_PREFIX"*) continue ;; esac
    case "${f##*/}" in
      _index.md|INDEX.md) p2_cards+=("$f") ;;
    esac
  done < <(git_safe ls-files 2>/dev/null)
fi

if [ "${#p2_cards[@]}" -gt 0 ]; then
  for card_rel in "${p2_cards[@]}"; do
    [ -f "$ROOT/$card_rel" ] || continue
    CARTES_BALAYEES=$((CARTES_BALAYEES + 1))
    p2_sens_a "$card_rel" "$card_rel"   # P2-SENS-A-CALL
    p2_sens_b "$card_rel" "$card_rel"
  done
fi

# --- Verdict, dans cet ordre strict ---------------------------------------------------------------

if [ "$CARTES_BALAYEES" -eq 0 ]; then
  printf '%s\n' "[map-drift] NON VÉRIFIABLE — 0 carte balayée (${ROOT} hors d'un arbre de travail git, cible absente, ou aucune carte CLAUDE.md/_index.md/INDEX.md trouvée)."
  say "plancher anti-vert-à-vide : aucun compte de divergences ne peut être imprimé sans carte balayée."
  exit 3
fi

if [ "$DIVERGENCES" -ge 1 ]; then
  printf '%s\n' "[map-drift] ${DIVERGENCES} divergence(s) sur ${CARTES_BALAYEES} carte(s) balayée(s)."
  if [ "${#DETAILS[@]}" -gt 0 ]; then
    for line in "${DETAILS[@]}"; do
      printf '%s\n' "$line"
    done
  fi
  printf '%s\n' "            → propose de mettre à jour la carte, ou de créer/retirer l'élément manquant."
  exit 0
fi

printf '%s\n' "[map-drift] 0 divergence sur ${CARTES_BALAYEES} carte(s) balayée(s)."
exit 3
