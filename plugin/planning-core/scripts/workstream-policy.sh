#!/usr/bin/env bash
# workstream-policy.sh — POLITIQUE UNIQUE de nom de workstream. À SOURCER, jamais à exécuter.
#
# POURQUOI CE FICHIER EXISTE (revue de jointure, vague 1 de la Phase 24) :
# Quatre gates portaient chacun sa COPIE de la politique de nom (`ws_trim` / `ws_name_valid` /
# `nom_valide`), en DEUX variantes divergentes — et aucune des deux n'était conforme au moteur
# amont. Sur un arbre identique, « workstream résolu mais dossier absent » produisait QUATRE
# verdicts différents. Les copies ne peuvent pas rester synchronisées à la main : elles ont déjà
# divergé une fois, en un seul lot de travail parallèle. Cette politique est donc écrite ICI, une
# seule fois, et les quatre la consomment.
#
# PLACEMENT — pourquoi `planning-core` et pas `conductor` :
# Les quatre consommateurs vivent dans TROIS modules (conductor, dev-orchestrator, planning-core).
# `planning-core` est le seul placement qui n'ajoute AUCUNE dépendance inter-modules nouvelle :
# `conductor` requiert déjà planning-core, `dev-orchestrator` requiert conductor (donc
# planning-core par transitivité), et planning-core se possède lui-même. L'inverse était faux :
# planning-core a une fermeture RÉDUITE À LUI-MÊME (`resolve-deps.sh planning-core` → planning-core),
# il peut donc être installé SANS conductor — y placer la dépendance aurait cassé ce lab-là.
# À l'installation, tous les scripts de tous les modules atterrissent À PLAT dans
# `.claude/scripts/` (`copy_module_scripts`, un seul niveau) : le fichier est donc voisin de ses
# quatre consommateurs chez l'utilisateur, et seulement dans l'arbre du dépôt faut-il remonter.
#
# SOURCE DE VÉRITÉ AMONT : `gsd-core/bin/lib/workstream-name-policy.cjs`.
#   - `ACTIVE_WORKSTREAM_RE = /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/`  (1er caractère alphanumérique)
#   - `hasInvalidPathSegment` : `/` ou `\`, ou la valeur vaut `.` ou `..`, ou elle CONTIENT `..`
#   - `normalizeWorkstreamNameInput` : `String(name).trim()` — trim des BORDS, jamais de l'intérieur
#   - AUCUNE borne de longueur. La borne locale de 80 caractères des anciennes copies était une
#     addition non-amont : elle REJETAIT des noms qu'amont ACCEPTE, avec un repli fail-open
#     derrière — c'est-à-dire un verdict de conformité rendu sur le mauvais fichier. Elle est
#     supprimée. Ce fichier ne peut plus être « strictement plus sévère » qu'amont : toute
#     divergence, dans un sens comme dans l'autre, est un défaut.
#
# ═══════════════════════════════════════════════════════════════════════════════════════════════
# POLITIQUE UNIQUE — « workstream RÉSOLU, dossier `.planning/workstreams/<nom>/` ABSENT »
# ═══════════════════════════════════════════════════════════════════════════════════════════════
# Le moteur amont, dans cet état, efface le pointeur et rend « aucun workstream », EN SILENCE
# (`getActiveWorkstream` : `adapter.clear()` puis `return null`). Aucun consommateur de cette
# politique n'a le droit de reproduire ce silence. Règle commune, que les quatre respectent :
#   1. le nom résolu est NOMMÉ dans la sortie (il a passé la validation : il est sûr à imprimer) ;
#   2. AUCUN chemin de compartiment n'est construit ni lu ;
#   3. la sortie n'est jamais vide, et ne vaut jamais « conforme » tacite.
# La SÉVÉRITÉ est fonction du RÔLE, et elle est déclarée ici — jamais décidée sur place :
#   - GATE DE VÉRIFICATION (`check-state-integrity.sh`) → exit 2, « non vérifiable ». Il rendrait
#     sinon un verdict de conformité sur un fichier qui n'est pas celui que l'appelant croit
#     vérifier — c'est exactement le fail-open qui a motivé ce fichier.
#   - GATE DE CONSTAT (`check-workstream-pointer.sh`) → exit 1. Rendre cet état AUDIBLE est sa
#     raison d'être ; un exit 2 le rangerait avec « je n'ai pas pu regarder », ce qu'il a pu.
#   - INJECTEUR DE CONTEXTE (`check-dev-bootstrap.sh`, `planning-context.sh`) → repli sur la
#     racine PLUS une ligne qui NOMME le workstream. Ce sont des hooks SessionStart : un exit non
#     nul y dégraderait toutes les sessions. Fail-open ne veut pas dire muet.
# Un nom REJETÉ (hors politique, ou pointeur non lisible sûrement) suit la même gradation, à ceci
# près que la valeur brute n'est JAMAIS réimprimée : elle est non maîtrisée par construction et
# traverserait vers le contexte de session (T-24-04-01, T-24-05-01, frontière T-17-01). Seule la
# RAISON du rejet, prise dans une énumération fermée, est imprimable.
# ═══════════════════════════════════════════════════════════════════════════════════════════════
#
# CONTRAT D'APPEL :
#   vf_ws_name_valid <nom>            → 0 si le nom est valide au sens amont, 1 sinon. Pur.
#   vf_ws_trim <valeur>               → imprime la valeur rognée de ses bords (jamais l'intérieur).
#   vf_ws_resolve <planning_dir> [surcharge]
#       Résout le workstream actif. Ordre COURT-CIRCUITANT, calqué sur `resolveActiveWorkstream` :
#         1. <surcharge>      — la variable historique du script appelant (testabilité)
#         2. $VF_WORKSTREAM   — surcharge unifiée, commune aux quatre
#         3. $GSD_WORKSTREAM  — canal de premier rang du moteur
#         4. 1re valeur du pointeur PARTAGÉ in-repo `<planning_dir>/active-workstream`
#       Positionne VF_WS_NAME (nom validé, ou vide), VF_WS_SOURCE et VF_WS_REASON.
#       Rend 0 = résolu (VF_WS_NAME non vide) OU aucun workstream (VF_WS_NAME vide)
#            2 = REJETÉ — un nom/pointeur a bien été trouvé mais il est hors politique ou non
#                lisible sûrement. VF_WS_REASON porte la raison (énumération fermée, imprimable) ;
#                VF_WS_NAME est vide. L'appelant applique la gradation ci-dessus.
#
# FRONTIÈRE ASSUMÉE, commune aux quatre : le pointeur de SESSION en `os.tmpdir()` n'est PAS lu —
# il est indexé sur un condensat du chemin absolu réel du `.planning` ET sur une clé de session que
# bash ne reproduit pas fidèlement. Ce trou est l'objet d'un gate dédié
# (`check-workstream-pointer.sh`), jamais d'une approximation à cet endroit.

# Bornes de LECTURE. Ce ne sont PAS des bornes de politique de nom (amont n'en a aucune) : ce sont
# des bornes de SÛRETÉ DE LECTURE. Une valeur qui les dépasse n'est pas « invalide », elle est
# « non lisible sûrement » — et elle est refusée bruyamment, jamais réimprimée.
# Motif : un pointeur versionné est du contenu de dépôt non maîtrisé, lu par un hook SessionStart.
VF_WS_POINTER_MAX_BYTES=4096

# LA MÊME BORNE, SUR LE CANAL NOMINAL — et l'absence de cette ligne était le trou. La borne
# ci-dessus ne protège que le canal RÉTROGRADÉ (le pointeur partagé). Or l'amendement d'ADR-064 a
# fait de `GSD_WORKSTREAM` le canal NOMINAL : c'est lui que la doctrine prescrit, lui que les hooks
# lisent en premier, et il n'avait AUCUNE borne. `vf_ws_name_valid` ne pouvait pas y suppléer —
# elle contraint l'ALPHABET des caractères, jamais leur nombre : 200 000 octets pris dans
# `[A-Za-z0-9._-]` la traversent intacts. Mesuré : 200 000 octets en entrée → 400 Ko en sortie de
# deux hooks SessionStart, c'est-à-dire directement dans le contexte de session. Borner le canal
# rétrogradé en laissant le nominal libre revenait à verrouiller la porte de service.
VF_WS_VALUE_MAX_BYTES=4096

VF_WS_NAME=""
VF_WS_SOURCE=""
VF_WS_REASON=""
VF_WS_RAW=""
# Chemin du compartiment résolu SANS traverser de lien symbolique (vf_ws_dir_resolve). Initialisée
# ici, comme ses sœurs : les quatre gates tournent sous `set -u` ou le deviendront, et une variable
# lue avant son premier positionnement y est fatale.
VF_WS_DIR=""

# Rogne les BORDS uniquement (espaces, tabulations, CR, LF, VT, FF) — parité avec le `.trim()` de
# `normalizeWorkstreamNameInput`. NE TOUCHE JAMAIS À L'INTÉRIEUR : un `tr -d ' '` global faisait
# passer le pointeur « de v » pour « dev », c'est-à-dire un vert fabriqué sur un nom qui n'était
# pas dans le fichier.
vf_ws_trim() {
  printf '%s' "$1" | awk '
    { buf = (NR == 1 ? $0 : buf "\n" $0) }
    END {
      gsub(/^[ \t\r\n\013\014]+/, "", buf)
      gsub(/[ \t\r\n\013\014]+$/, "", buf)
      printf "%s", buf
    }'
}

# Parité EXACTE avec `isValidActiveWorkstreamName` amont. LC_ALL=C rend les plages de caractères
# insensibles à la locale (sinon `[A-Za-z]` ramasse les accentués sous certaines collations, et le
# gate accepterait un nom qu'amont refuse).
vf_ws_name_valid() { # <nom>
  local n="$1"
  local LC_ALL=C
  [ -n "$n" ] || return 1
  # hasInvalidPathSegment : separateur de chemin, `.`, `..`, ou `..` en sous-chaine
  case "$n" in
    */*|*\\*|.|..|*..*) return 1 ;;
  esac
  # ACTIVE_WORKSTREAM_RE : 1er caractere alphanumerique, puis alphanumerique / point / souligne /
  # tiret. Exprimé en `case` (et non en grep -E) : aucun processus externe dans un hook
  # SessionStart, et aucune dependance au comportement d'un grep proxifie.
  case "$n" in
    [A-Za-z0-9]*) ;;
    *) return 1 ;;
  esac
  case "$n" in
    *[!A-Za-z0-9._-]*) return 1 ;;
  esac
  return 0
}

# Lecture SÛRE du pointeur partagé. Rend la valeur rognée dans VF_WS_RAW (JAMAIS sur stdout : un
# `$(...)` créerait un sous-shell et VF_WS_REASON, positionné dedans, serait perdu — l'appelant
# recevrait le bon code de sortie avec une raison vide, donc un diagnostic faux, par exemple
# « nom hors politique » pour un lien symbolique refusé). Rend 2 si le fichier ne peut pas être lu
# sans risque. Trois refus, chacun motivé :
#   - LIEN SYMBOLIQUE : un pointeur versionné en mode 120000 fait imprimer le contenu de sa cible
#     (`../../victime/.env`) sur stdout d'un hook SessionStart, donc DANS le contexte de session,
#     sans aucune action de la victime au-delà de l'ouverture de session. Le moteur amont suit le
#     lien ; ici on refuse — la posture de sûreté prime sur la parité, et le refus est AUDIBLE.
#   - FICHIER NON RÉGULIER : un FIFO gèlerait le hook jusqu'au timeout.
#   - TAILLE : au-delà de VF_WS_POINTER_MAX_BYTES, on ne lit pas.
# Le fichier ENTIER est lu puis rogné — parité avec `createSharedPointerAdapter` (`raw.trim()`),
# là où un `head -n 1` faisait passer « dev\nautre » (invalide amont) pour « dev ».
vf_ws_read_pointer() { # <fichier> — positionne VF_WS_RAW ; 0 = lu, 1 = absent, 2 = refus motivé
  local f="$1" size
  VF_WS_RAW=""
  [ -e "$f" ] || return 1
  if [ -L "$f" ]; then
    VF_WS_REASON="pointeur-lien-symbolique"
    return 2
  fi
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    VF_WS_REASON="pointeur-illisible"
    return 2
  fi
  size=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
  case "$size" in
    ''|*[!0-9]*) VF_WS_REASON="pointeur-illisible"; return 2 ;;
  esac
  if [ "$size" -gt "$VF_WS_POINTER_MAX_BYTES" ]; then
    VF_WS_REASON="pointeur-trop-long"
    return 2
  fi
  VF_WS_RAW="$(vf_ws_trim "$(cat "$f" 2>/dev/null)")"
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════════════════════════
# RÉSOLUTION DU COMPARTIMENT — le nom est validé, le CHEMIN ne l'était par rien
# ═══════════════════════════════════════════════════════════════════════════════════════════════
# QUATRIÈME PASSAGE DU MÊME MOTIF, mesuré sur dépôt piégé le 2026-08-04. La politique ci-dessus
# contraint le NOM (alphabet, `..`, séparateurs) et `vf_ws_read_pointer` refuse un pointeur-FICHIER
# en lien symbolique. Le RÉPERTOIRE, lui, n'était contraint par rien : les quatre gates
# construisaient `<planning>/workstreams/<nom>` puis testaient `[ -d ]` (ou `[ -f .../STATE.md ]`),
# et `[ -d ]` SUIT le lien. Un `.planning/workstreams/dev` versionné en mode 120000 vers un
# répertoire hors du lab suffisait donc à :
#   - `planning-context.sh`  → INJECTER le STATE.md de la cible dans le contexte de session, exit 0
#                              (reproduit : le contenu hors-lab sortait verbatim entre les ```) ;
#   - `check-dev-bootstrap.sh` → lire le compartiment de la cible et réimprimer son frontmatter
#                              (`milestone <valeur de l'attaquant>`) sur stdout d'un SessionStart ;
#   - `check-state-integrity.sh` → rendre son VERDICT sur un STATE.md qui n'est pas celui que
#                              l'appelant croit vérifier — le fail-open qui a motivé ce fichier ;
#   - `check-workstream-pointer.sh` → bénir la partition (« dossier présent », exit 0), c'est-à-dire
#                              fournir aux trois autres le vert sur lequel ils s'appuient.
# Deux hooks SessionStart dans le lot : auto-déclenchés, sans aucune action de la victime au-delà de
# l'ouverture de session. Même vecteur que le pointeur en 120000, une indirection plus loin.
#
# POSTURE, identique à celle de `vf_ws_read_pointer` : ON REFUSE DE SUIVRE, on ne tente pas de
# décider si la cible est « dans le lab » — un tel test se réécrit avec `..`, dépend d'un
# `readlink -f` absent de macOS, et ne survit pas à un remontage. Le refus est AUDIBLE, jamais
# muet, et la valeur de la cible n'est JAMAIS lue ni réimprimée. Un compartiment légitime est un
# vrai répertoire : le cas licite reste vert à l'octet près.
#
# CE QUI N'EST PAS REFUSÉ, ET POURQUOI : un `workstreams/<nom>` qui existe en fichier régulier reste
# classé « absent » (rc 1), comme avant. Rien ne le lit — `[ -d ]` est faux et `[ -f <lui>/STATE.md ]`
# aussi : il n'ouvre aucune voie de lecture, et le requalifier en refus déplacerait la gradation par
# rôle d'un cas qui n'est pas une menace.

# Primitive : <chemin> existe-t-il SANS être un lien symbolique ?
#   0 = présent et non-lien · 1 = absent · 2 = lien symbolique (y compris pendant : `[ -L ]` est vrai
#   là où `[ -e ]` est faux, l'ordre des tests ci-dessous est donc porteur).
vf_ws_path_nolink() { # <chemin>
  [ -L "$1" ] && return 2
  [ -e "$1" ] || return 1
  return 0
}

# Résout le répertoire du compartiment SANS jamais traverser un lien symbolique. Les DEUX segments
# sont contraints : `workstreams` lui-même (le détourner détourne tous les compartiments d'un coup)
# puis `workstreams/<nom>`. Il n'y en a que deux — la politique de nom interdit `/`, donc `<nom>`
# est un segment unique par construction.
# Positionne VF_WS_DIR (chemin du compartiment) ; rend :
#   0 = répertoire réel et sûr · 1 = absent (cas « dossier absent » de la gradation par rôle)
#   2 = REFUS motivé, VF_WS_REASON dans l'énumération fermée ci-dessous, AUCUNE lecture effectuée.
vf_ws_dir_resolve() { # <planning_dir> <nom>
  local root="$1/workstreams" dir="$1/workstreams/$2" rc=0
  VF_WS_DIR=""
  vf_ws_path_nolink "$root"; rc=$?
  [ "$rc" -eq 2 ] && { VF_WS_REASON="workstreams-lien-symbolique"; return 2; }
  [ "$rc" -eq 1 ] && return 1
  vf_ws_path_nolink "$dir"; rc=$?
  [ "$rc" -eq 2 ] && { VF_WS_REASON="compartiment-lien-symbolique"; return 2; }
  [ "$rc" -eq 1 ] && return 1
  [ -d "$dir" ] || return 1
  VF_WS_DIR="$dir"
  return 0
}

# MÊME MOTIF, UN CRAN PLUS BAS — fermer le répertoire en laissant le fichier ouvert, c'est verrouiller
# la porte et laisser la fenêtre : un compartiment parfaitement légitime dont le `STATE.md` est
# versionné en 120000 vers `../../victime/.env` rejoue la fuite à l'identique, `[ -f ]` suivant le
# lien tout comme `[ -d ]`. À appeler sur tout fichier du compartiment AVANT de le lire.
#   0 = fichier régulier sûr · 1 = absent · 2 = refus motivé (VF_WS_REASON).
vf_ws_file_in_ws() { # <chemin>
  local rc=0
  vf_ws_path_nolink "$1"; rc=$?
  [ "$rc" -eq 2 ] && { VF_WS_REASON="fichier-compartiment-lien-symbolique"; return 2; }
  [ "$rc" -eq 1 ] && return 1
  [ -f "$1" ] || return 1
  return 0
}

vf_ws_resolve() { # <planning_dir> [surcharge]
  local planning="$1" override="${2:-}" raw="" src="" rc=0
  VF_WS_NAME=""; VF_WS_SOURCE=""; VF_WS_REASON=""

  # Le test de vacuité porte sur la valeur ROGNÉE, jamais sur la valeur brute : sinon une chaîne
  # blanche (`GSD_WORKSTREAM='  '`) consomme la branche et court-circuite les canaux suivants,
  # alors qu'amont rogne D'ABORD puis retombe sur le store (`resolveActiveWorkstream` :
  # `env['GSD_WORKSTREAM'].trim()` en condition du `else if`).
  raw="$(vf_ws_trim "$override")"; src="surcharge"
  if [ -z "$raw" ]; then
    raw="$(vf_ws_trim "${VF_WORKSTREAM:-}")"; src="env (VF_WORKSTREAM)"
  fi
  if [ -z "$raw" ]; then
    raw="$(vf_ws_trim "${GSD_WORKSTREAM:-}")"; src="env (GSD_WORKSTREAM)"
  fi
  if [ -z "$raw" ]; then
    # Appel DIRECT, sans `$(...)` : voir vf_ws_read_pointer — un sous-shell perdrait VF_WS_REASON.
    vf_ws_read_pointer "$planning/active-workstream"; rc=$?
    if [ "$rc" -eq 2 ]; then
      VF_WS_SOURCE="store-partage (.planning/active-workstream)"
      return 2
    fi
    [ "$rc" -eq 0 ] && raw="$VF_WS_RAW" || raw=""
    src="store-partage (.planning/active-workstream)"
  fi

  [ -n "$raw" ] || return 0

  # BORNE DE SÛRETÉ AVANT TOUTE AUTRE CHOSE, et sur TOUS les canaux sans exception (surcharge,
  # VF_WORKSTREAM, GSD_WORKSTREAM, pointeur partagé) : la valeur arrive ici quelle que soit sa
  # provenance, c'est donc le seul endroit qui ne puisse pas en oublier un. Placée AVANT la
  # validation de nom : celle-ci parcourt la chaîne entière, et une valeur hors borne ne doit pas
  # même être parcourue. La raison est distincte de `hors-politique` — la valeur n'est pas rejetée
  # pour sa FORME mais pour sa TAILLE, et confondre les deux rendrait le diagnostic faux.
  if [ "${#raw}" -gt "$VF_WS_VALUE_MAX_BYTES" ]; then
    VF_WS_SOURCE="$src"
    VF_WS_REASON="valeur-trop-longue"
    return 2
  fi

  if ! vf_ws_name_valid "$raw"; then
    VF_WS_SOURCE="$src"
    VF_WS_REASON="hors-politique"
    return 2
  fi
  VF_WS_NAME="$raw"
  VF_WS_SOURCE="$src"
  return 0
}
