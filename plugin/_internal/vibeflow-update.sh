#!/usr/bin/env bash
# vibeflow-update.sh — Installeur/updateur scope-aware des modules vibeflow-os.
#
# Usage:
#   ./vibeflow-update.sh [--scope user|project|local] [--dry-run] install <module>   # Installe un module
#   ./vibeflow-update.sh [--scope ...] [--dry-run] install --with-deps <module>      # Installe la fermeture transitive
#   ./vibeflow-update.sh [--scope ...] [--dry-run] install --all                     # Installe tous les modules dispo
#   ./vibeflow-update.sh [--scope ...] [--dry-run] update <module>                   # Met à jour un module installé
#   ./vibeflow-update.sh [--scope ...] [--dry-run] update --all                      # Met à jour tous les modules installés
#   ./vibeflow-update.sh [--scope ...] uninstall <module>                   # Désinstalle un module
#   ./vibeflow-update.sh [--scope ...] uninstall --all                      # Désinstalle TOUS les modules installés (lit le registre)
#   ./vibeflow-update.sh [--scope ...] rollback <module>                    # Restore depuis backup
#   ./vibeflow-update.sh [--scope ...] status                               # Liste modules installés + versions
#   ./vibeflow-update.sh sync                                               # No-op (source = cache, plus de git)
#
# Source : le cache local fourni par l'appelant (VIBEFLOW_CACHE, défaut .vibeflow-cache).
#   Plus de clone/pull git : le cache DOIT exister (sinon erreur). En prod, c'est le skill
#   /vibeflow-install (Phase 4) qui prépare le cache à partir du plugin packagé (Phase 5).
#
# Scope (cible d'install, spec §3) :
#   --scope user            → $HOME/.claude
#   --scope project | local → ./.claude   (local ajoute en plus les chemins au ./.gitignore)
#   env VF_SCOPE            → idem ; --scope l'emporte sur VF_SCOPE.
#   --dry-run                → n'écrit RIEN, rend le plan de pose fichier par fichier sur stdout.
#                               Accepté seulement sur install/update ; refusé (exit 1) ailleurs.
#
# Pré-requis : $VIBEFLOW_CACHE existe (dossier des modules + leurs module.json).

set -euo pipefail

# ---------- Helpers (définis tôt : utilisés dès le parsing) ----------
log() { echo "[vibeflow-update] $*" >&2; }
err() { echo "[vibeflow-update] ERROR: $*" >&2; exit 1; }
# vf_dry_run — prédicat pour VF_DRY_RUN (D-31-06). Tous les sites testent CE prédicat plutôt que
# la variable à la main.
vf_dry_run() { [ "$VF_DRY_RUN" = "1" ]; }

# ---------- Résolution du scope → TARGET_ROOT (SCOPE-01) ----------
# Défaut LEGACY = `project` (cible historique ./.claude). C'est un fallback APPEL-DIRECT
# (debug, run manuel, tests). EN PROD le skill /vibeflow-install (Phase 4) passe TOUJOURS un
# VF_SCOPE explicite à l'engine ET à ensure-deps.sh (un seul scope partout — cohérence ID4,
# spec §3/§8). Ce défaut engine `project` ne co-occurre donc JAMAIS en prod avec le défaut
# LEGACY `user` de ensure-deps.sh : pas de contradiction entre 03-01 et 03-02.
VF_SCOPE="${VF_SCOPE:-project}"
# D-31-06 : booléen, aucune forme --dry-run=<valeur>. Détecté dans le MÊME pré-parse que
# --scope, donc valide avant cmd="$1".
VF_DRY_RUN="0"

# Détecter `--scope <val>`/`--dry-run` AVANT cmd="$1" : on filtre les positionnels et on override
# VF_SCOPE/VF_DRY_RUN.
_positional=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --scope)
      [ "$#" -ge 2 ] || err "--scope nécessite une valeur (user|project|local)"
      VF_SCOPE="$2"
      shift 2
      ;;
    --scope=*)
      VF_SCOPE="${1#--scope=}"
      shift
      ;;
    --dry-run)
      VF_DRY_RUN="1"
      shift
      ;;
    --dry-run=*)
      # F-06 (correction ciblée 31-04) : refus EXPLICITE de la forme --dry-run=<valeur> (D-31-06,
      # booléen only) — sans ce cas dédié, `--dry-run=true` retombait dans le bucket positionnel
      # générique (`*`) puis heurtait le fourre-tout d'usage en fin de script (rc=1 non nommé,
      # l'utilisateur ne sait pas pourquoi). Message qui NOMME la forme refusée et la forme valide.
      err "--dry-run n'accepte pas de valeur (reçu : $1) — utiliser --dry-run seul, jamais --dry-run=<valeur>"
      ;;
    *)
      _positional+=("$1")
      shift
      ;;
  esac
done
# Restaurer les positionnels nettoyés (set -u : guard tableau vide).
if [ "${#_positional[@]}" -gt 0 ]; then
  set -- "${_positional[@]}"
else
  set --
fi

# Validation stricte : rejette tôt toute valeur incohérente.
case "$VF_SCOPE" in
  user|project|local) : ;;
  *) err "scope invalide : $VF_SCOPE (attendu user|project|local)" ;;
esac

# Surface du flag --dry-run (D-31-06), validée AVANT cmd="$1" (952) : borné à install/update.
# Refus BRUYANT, jamais un flag accepté-puis-ignoré — sur uninstall/rollback/status/sync ce
# serait le pire échec possible de la phase (l'utilisateur croirait prévisualiser et le moteur
# supprimerait). Cas $# = 0 : conserver le comportement actuel (impression d'usage, exit 0) —
# un --dry-run seul n'est pas une commande, rien à valider ici.
if vf_dry_run && [ "$#" -gt 0 ]; then
  case "$1" in
    install|update) : ;;
    *) err "--dry-run n'est accepté que sur install/update (reçu : $1) — un --dry-run accepté-puis-ignoré sur ce verbe ferait croire à une prévisualisation alors qu'il supprimerait/agirait réellement" ;;
  esac
fi

# Résolution TARGET_ROOT depuis le scope.
case "$VF_SCOPE" in
  user)            TARGET_ROOT="$HOME/.claude" ;;
  project|local)   TARGET_ROOT="./.claude" ;;
esac
export VF_SCOPE

# ---------- Variables (toutes les cibles rebasées sur TARGET_ROOT) ----------
CACHE_DIR="${VIBEFLOW_CACHE:-.vibeflow-cache}"   # SEULE source (plus de clone)
INSTALLED_REGISTRY="$TARGET_ROOT/scripts/.vibeflow-installed"
BACKUP_DIR="$TARGET_ROOT/.backups"

# ---------- État global de l'accumulateur manifeste (W-2, revue vague 1) ----------
# Initialisées ici — jamais laissées unbound. Sans ce garde, tout appel futur à vf_record ou
# vf_manifest_flush hors de la séquence vf_manifest_reset → … → vf_manifest_flush planterait sous
# `set -u` en « unbound variable », sans message clair sur la cause réelle (cycle non ouvert).
# Les guards explicites dans vf_record/vf_manifest_flush (plus bas) rendent ce cas d'usage
# incorrect visible avec un message précis, au lieu de dépendre du seul message bash générique.
VF_MANIFEST_MOD=""
VF_MANIFEST_TMP=""
# F-01 (correction ciblée 31-04, mandat revue+vérif) : miroir run-scoped de VF_ENGINE_LIB_COPIED
# (770-773) pour la garde de backup de settings.json dans merge_module_hooks. La garde DISQUE
# `[ -f "$TARGET_ROOT/settings.json" ]` est vraie côté PRÉEXISTANT du lab, mais en multi-module
# (`--all`/`--with-deps`) settings.json est aussi créé par un module ANTÉRIEUR du MÊME run — en
# pose réelle le disque reflète ce fait au fil de la boucle (chaque install_module voit le fichier
# posé par le précédent), mais un --dry-run n'écrit RIEN : le disque ne bouge jamais et la garde
# reste fausse à partir du 2e module alors que la pose réelle backuperait bien. Ce drapeau simule
# côté PLAN ce que le disque ferait côté RÉEL : initialisé sur l'état réel du disque (couvre le cas
# préexistant, mono-module inclus), puis mis à 1 dès qu'un module du run a mergé ses hooks — qu'il
# ait trouvé le fichier déjà là ou que ce merge soit celui qui le crée pour le run.
VF_SETTINGS_JSON_WILL_EXIST="0"
[ -f "$TARGET_ROOT/settings.json" ] && VF_SETTINGS_JSON_WILL_EXIST="1"
# Compteur de copies dégradées (D-31-11 point 4) de la pose EN COURS — remis à 0 par
# vf_manifest_reset (appelée en tête d'install_module), lu en fin d'install_module pour le
# compte rendu. Jamais unbound (même discipline que les deux variables ci-dessus).
VF_DEGRADED_COPIES_COUNT=0
# D-31-14 : compteur des poses hors cycle manifeste (vf_record no-op silencieux faute de cycle
# ouvert, cf. commentaire de vf_record) — remis à 0 par sync_module_governance, lu en fin de
# fonction pour UNE ligne de compte rendu PAR MODULE (jamais une ligne par chemin, cf. décision).
VF_NOCYCLE_COUNT=0

# ---------- Cache (SCOPE-02 : plus de clone/pull, le cache doit exister) ----------
require_cache() {
  [ -d "$CACHE_DIR" ] || err "Cache introuvable : $CACHE_DIR (fournir VIBEFLOW_CACHE)"
}

list_available_modules() {
  require_cache
  for d in "$CACHE_DIR"/*/; do
    name=$(basename "$d")
    [ "$name" = "_internal" ] && continue
    if [ -f "${d}VERSION" ]; then
      echo "$name"
    fi
  done
}

module_version_available() {
  local mod="$1"
  cat "$CACHE_DIR/$mod/VERSION" 2>/dev/null || echo "—"
}

module_version_installed() {
  local mod="$1"
  if [ -f "$INSTALLED_REGISTRY" ]; then
    grep "^$mod=" "$INSTALLED_REGISTRY" 2>/dev/null | cut -d= -f2 || echo "—"
  else
    echo "—"
  fi
}

mark_installed() {
  local mod="$1"
  local version="$2"
  if vf_dry_run; then
    # F-04 (correction ciblée 31-04) : verbe selon l'existence RÉELLE de la cible (D-31-05, + crée
    # / ~ modifie) — sur un lab vierge, $INSTALLED_REGISTRY n'existe pas encore : c'est une
    # création, pas une modification. Sans conséquence sur le manifeste (scripts/.vibeflow-installed
    # est dans la liste close d'exclusions D-31-03, jamais consigné quel que soit le verbe) —
    # correction de LECTURE du plan uniquement (ADR-031, consentement éclairé).
    local verb="~"
    [ -f "$INSTALLED_REGISTRY" ] || verb="+"
    vf_declare_write "$verb" "$INSTALLED_REGISTRY" "$mod=$version"
    return 0
  fi
  mkdir -p "$(dirname "$INSTALLED_REGISTRY")"
  touch "$INSTALLED_REGISTRY"
  # Remove old entry if exists
  grep -v "^$mod=" "$INSTALLED_REGISTRY" > "${INSTALLED_REGISTRY}.tmp" 2>/dev/null || true
  echo "$mod=$version" >> "${INSTALLED_REGISTRY}.tmp"
  mv "${INSTALLED_REGISTRY}.tmp" "$INSTALLED_REGISTRY"
}

mark_uninstalled() {
  local mod="$1"
  # Durcissement (correction ciblée 31-04) : garde INTERNE, symétrique de mark_installed —
  # jusqu'ici sûre uniquement parce que les 2 appelants actuels (cleanup_retired_modules,
  # uninstall_module) gatent DÉJÀ à l'appel. D-31-01 veut UN SEUL point de bascule par site : sans
  # cette garde, un futur appelant (D-31-09, dernière vague) qui oublierait sa propre garde externe
  # ferait muter $INSTALLED_REGISTRY sur disque pendant un --dry-run. `return 0` : pas d'annonce
  # ici — les deux appelants annoncent déjà eux-mêmes (verbe -, no-op manifeste par construction,
  # D-31-02), une 2e annonce depuis ce site dupliquerait la ligne.
  vf_dry_run && return 0
  if [ -f "$INSTALLED_REGISTRY" ]; then
    grep -v "^$mod=" "$INSTALLED_REGISTRY" > "${INSTALLED_REGISTRY}.tmp" || true
    mv "${INSTALLED_REGISTRY}.tmp" "$INSTALLED_REGISTRY"
  fi
}

# ---------- Manifeste de pose (D-31-01/02/03, Phase 31 vague TRACER) ----------
# Le manifeste est le SOUS-PRODUIT de la pose : vf_place_file écrit ET consigne dans le même
# appel (via vf_record), jamais une énumération séparée du cache (Pitfall 1, 31-RESEARCH.md).
# Format : un chemin par ligne, relatif à TARGET_ROOT, LF, trié LC_ALL=C, jamais de répertoire.

vf_manifest_path() {
  local mod="$1"
  echo "$TARGET_ROOT/scripts/.vibeflow-manifest-$mod"
}

# Liste close des artefacts qu'un module NE possède PAS exclusivement (D-31-03). Point UNIQUE
# de définition — ne jamais dupliquer ces motifs ailleurs dans le fichier.
vf_manifest_excluded() {
  local relpath="$1"
  case "$relpath" in
    scripts/vf-portable.sh)       return 0 ;;  # propriété exclusive de l'engine (copy_engine_lib), partagée entre modules
    memory/*)                     return 0 ;;  # contenu vivant du lab semé par seed-registres.sh, pas un artefact de pose
    scripts/.vibeflow-installed)  return 0 ;;  # état du moteur, pas contenu de module
    scripts/.vibeflow-manifest-*) return 0 ;;  # le manifeste ne se consigne jamais lui-même (boucle de convergence)
    .backups/*)                   return 0 ;;  # filet de sécurité, jamais candidat à suppression automatique
    settings.json)                return 0 ;;  # M5 (revue 31-03) : fichier MERGÉ par merge_module_hooks, pas posé — était
                                                 # neutralisé par un second filtre privé sous T6, hors du point UNIQUE D-31-03
    settings.local.json)          return 0 ;;  # idem, miroir --settings-local (scope project|local)
  esac
  return 1
}

# ---------- Lecteur validant du manifeste (D-31-07, 31-05) ----------
# Le manifeste sur disque est une entrée NON FIABLE (éditable à la main, corruptible, CRLF-mangée
# par un outil Windows — 31-RESEARCH.md § Security Domain, V5 Input Validation). Ces deux fonctions
# sont le SEUL point d'entrée en lecture pour la convergence MANI-03 : un refus ici interdit toute
# suppression en aval — jamais une confiance ligne à ligne partielle.

# vf_manifest_valid <fichier> — parcourt le fichier ligne à ligne (while IFS= read -r, patron de
# cleanup_retired_modules) et applique les 5 contrôles de D-31-07, DANS CET ORDRE :
#   0. octet NUL n'importe où dans le fichier (balayage ENTIER, AVANT la boucle ligne à ligne —
#      voir motif ci-dessous)
#   1. ligne vide après strip du \r
#   2. octet de retour chariot résiduel, N'IMPORTE OÙ dans la ligne (pas seulement en fin — un
#      \r au MILIEU, ex. "rules/evil\rfile.md", passait à tort tant que le test était ancré en fin
#      de chaîne ; correction ciblée, 5e forme adjacente)
#   3. chemin absolu (la ligne strippée commence par une barre oblique)
#   4. segment ".." isolé (entre deux séparateurs, en tête ou en fin — jamais une sous-chaîne :
#      "..foo" et "foo.." ne sont PAS ce motif, seul un ".." qui est son PROPRE segment l'est ;
#      détecté en encadrant la ligne strippée de barres obliques et en cherchant "/../")
# Au premier échec : `log` le motif ET le numéro de ligne fautif (sauf le contrôle NUL, dont la
# nature — voir plus bas — interdit un numéro de ligne fiable), retourne 1 SANS continuer. Le
# refus est GLOBAL — une ligne fautive invalide tout le fichier, jamais un filtrage ligne à ligne :
# c'est exactement ce qu'une confiance partielle laisserait passer face à un CRLF injecté.
#
# Le contrôle du \r est un REJET, jamais un nettoyage silencieux : un manifeste CRLF-mangé signale
# que quelque chose d'autre l'a réécrit (leçon Windows, Phase 30) — le nettoyer en silence
# masquerait la cause au lieu de la signaler.
#
# Le contrôle NUL (correction ciblée, finding D) tourne AVANT la boucle et sur le FICHIER ENTIER,
# jamais dans la boucle : `read -r` TRONQUE silencieusement une ligne au premier octet NUL
# (comportement natif du builtin bash) — l'octet a DÉJÀ disparu de $line au moment où la boucle
# le verrait, et la ligne tronquée pointe vers un chemin DIFFÉRENT de celui écrit à l'origine (le
# voisin, jamais la cible visée). Mesuré : `lu=[rules/bin] len=9` pour une ligne
# "rules/bin\0ary.md", verdict VALIDE, et le VOISIN `rules/bin` (jamais désigné par le manifeste)
# supprimé de bout en bout. Détection par différence de taille avant/après `tr -d '\000'` — POSIX
# tr/wc, aucune dépendance externe (même contrainte que _vf_normalize_path, ADR-054).
vf_manifest_valid() {
  local file="$1"
  if [ "$(LC_ALL=C tr -d '\000' < "$file" | wc -c)" -ne "$(wc -c < "$file")" ]; then
    log "  manifeste imparsable : octet NUL détecté"
    return 1
  fi
  local line lineno=0 stripped
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    stripped="${line%$'\r'}"
    if [ -z "$stripped" ]; then
      log "  manifeste imparsable : ligne vide (ligne $lineno)"
      return 1
    fi
    case "$line" in
      *$'\r'*)
        log "  manifeste imparsable : octet de retour chariot résiduel (ligne $lineno)"
        return 1
        ;;
    esac
    case "$stripped" in
      /*)
        log "  manifeste imparsable : chemin absolu (ligne $lineno)"
        return 1
        ;;
    esac
    case "/$stripped/" in
      */../*)
        log "  manifeste imparsable : segment .. (ligne $lineno)"
        return 1
        ;;
    esac
  done < "$file"
  return 0
}

# vf_manifest_read <mod> — résout $(vf_manifest_path "$mod") et rend 3 codes de retour distincts :
#   0 = manifeste VALIDE : les lignes sont émises sur stdout de la fonction (comme `cat`).
#   1 = manifeste IMPARSABLE : vf_manifest_valid a déjà loggué le motif et le numéro de ligne
#       fautifs ci-dessus ; cette fonction ajoute une ligne d'ABSTENTION EXPLICITE. Rien sur
#       stdout — aucune suppression ne doit pouvoir s'appuyer sur ce fichier.
#   2 = manifeste ABSENT : repli gracieux, JAMAIS une erreur — un parc installé avant cette phase
#       n'a aucun manifeste et ne doit pas rougir le jour d'un update (D-31-07). Rien sur stdout ;
#       le manifeste sera écrit à l'occasion, l'update suivant converge.
# Le refus est GLOBAL, jamais ligne à ligne : délégué entièrement à vf_manifest_valid.
vf_manifest_read() {
  local mod="$1"
  local file
  file="$(vf_manifest_path "$mod")"
  if [ ! -f "$file" ]; then
    log "  manifeste absent pour $mod — aucune convergence à cet update, il sera écrit à l'occasion"
    return 2
  fi
  if ! vf_manifest_valid "$file"; then
    log "  manifeste de $mod inutilisable — AUCUNE suppression ne sera faite"
    return 1
  fi
  # Finding E (correction ciblée) : `cat` nu ici est une commande en position finale de fonction —
  # sous `set -euo pipefail`, une panne d'E/S réelle (permission retirée entre le test -f et cette
  # ligne) fait avorter TOUT le script appelant (D-31-13 : seule la DERNIÈRE commande d'une liste
  # déclenche errexit, et un appel nu EST sa propre liste). Le fichier a passé `vf_manifest_valid`
  # (donc syntaxiquement correct) mais reste illisible : même contrat que « imparsable » — bruyant,
  # abstention, jamais un crash du process entier.
  if ! cat "$file"; then
    log "  manifeste de $mod illisible (permission) — AUCUNE suppression ne sera faite"
    return 1
  fi
  return 0
}

# Réduction textuelle des segments "." / ".." / "//" — SANS realpath (ADR-054 l'interdit).
# Implémentation privée de vf_rel_to_target, pas un des 7 points d'API du socle manifeste.
_vf_normalize_path() {
  local path="$1"
  # B-1 (revue vague 1, D-31-12) : sous bash 3.2 (le /bin/bash de macOS, plancher réel du repo),
  # `parts=($path)` avec $path VIDE laisse `parts` UNBOUND (pas un tableau à 0 élément, cf.
  # reproduction en revue) — le `"${parts[@]}"` du for qui suit avorte tout le script appelant
  # sous `set -u` (message : `parts[@]: unbound variable`). Court-circuit AVANT le split : un
  # chemin vide normalise en chemin relatif vide, exactement ce que produirait la boucle si
  # `parts` était bien un tableau à 0 élément (n=0, boucle de reconstruction jamais exécutée,
  # result="", sortie finale = ligne vide) — même sémantique, zéro risque de crash.
  [ -n "$path" ] || { printf '\n'; return 0; }
  local abs=0
  case "$path" in
    /*) abs=1 ;;
  esac
  local seg result i n=0
  local -a out=()
  local IFS=/
  set -f
  local -a parts
  parts=($path)
  set +f
  unset IFS
  for seg in "${parts[@]}"; do
    case "$seg" in
      ""|".") continue ;;
      "..")
        if [ "$n" -gt 0 ]; then
          n=$((n - 1))
        fi
        ;;
      *)
        out[$n]="$seg"
        n=$((n + 1))
        ;;
    esac
  done
  result=""
  i=0
  while [ "$i" -lt "$n" ]; do
    result="$result/${out[$i]}"
    i=$((i + 1))
  done
  if [ "$abs" -eq 1 ]; then
    [ -n "$result" ] || result="/"
    printf '%s\n' "$result"
  else
    printf '%s\n' "${result#/}"
  fi
}

# Normalise <chemin_dest> et émet sa forme relative à TARGET_ROOT sur stdout ; rc=1 si le
# chemin ne résout PAS sous TARGET_ROOT (cas docs/<mod>/, 636-641, hors manifeste par D-31-03 —
# ce n'est pas une erreur, ce chemin sort du manifeste, pas de la pose).
vf_rel_to_target() {
  local dest="$1"
  local norm_dest norm_target
  norm_dest="$(_vf_normalize_path "$dest")"
  norm_target="$(_vf_normalize_path "$TARGET_ROOT")"
  case "$norm_dest" in
    "$norm_target"/*)
      printf '%s\n' "${norm_dest#$norm_target/}"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# vf_physical_parent_under_target <chemin> — résolution PHYSIQUE (D-31-15, arbitrage de Samuel),
# utilisée EXCLUSIVEMENT par le chemin de SUPPRESSION de vf_converge_apply. vf_rel_to_target
# ci-dessus normalise PUREMENT TEXTUELLEMENT — sans jamais consulter le disque — et laisse donc
# passer un ANCÊTRE symlinké : `.claude/rules` remplacé par un lien vers `/tmp/…` résout « sous
# TARGET_ROOT » textuellement (le texte du chemin ne bouge pas), alors que le fichier réel se
# trouve hors TARGET_ROOT. Cette fonction compare le PARENT résolu du chemin au TARGET_ROOT résolu :
# `cd -P`/`pwd -P` sont des builtins POSIX — ADR-054 interdit le BINAIRE `realpath` (portabilité :
# absent ou divergent selon les plateformes), PAS la résolution physique en soi, donc la contrainte
# est respectée dans sa lettre et son intention.
# Abstention (rc=1, jamais une suppression) si le parent n'est pas traversable (permission,
# disparu entre deux appels) — le doute ne supprime jamais (D-31-07) : une panne ici doit se lire
# comme « hors TARGET_ROOT », jamais comme « sous TARGET_ROOT par défaut ».
vf_physical_parent_under_target() {
  local full="$1"
  local parent_dir phys_parent phys_target
  parent_dir="$(dirname "$full")"
  phys_parent="$(cd -P "$parent_dir" 2>/dev/null && pwd -P)" || return 1
  phys_target="$(cd -P "$TARGET_ROOT" 2>/dev/null && pwd -P)" || return 1
  case "$phys_parent" in
    "$phys_target"|"$phys_target"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# vf_removable <rel> — factorisation des conditions (c) à (g) de vf_converge_apply (D-31-07,
# D-31-15), UN SEUL jeu de garde-fous partagé par les DEUX verbes destructeurs du moteur : la
# convergence à l'update (vf_converge_apply, qui y ajoute ses conditions (a)/(b) propres — la
# comparaison ancien/nouveau manifeste, hors sujet ici) ET la désinstallation directe depuis un
# manifeste (uninstall_module, 31-07, D-31-09). <rel> est relatif à TARGET_ROOT (patron du
# manifeste, D-31-02) ; la résolution en chemin absolu se fait ICI, une seule fois.
#
# rc=0 = supprimable. rc=1 = refusé — VF_REMOVABLE_REASON porte le motif à journaliser SI le
# refus vient d'une condition de SÛRETÉ (d, e, g : lien/répertoire, hors TARGET_ROOT, ancêtre
# symlinké — des refus rares et anormaux). Laissé VIDE pour (c) (chemin déjà absent — cas
# ROUTINE, (d) le rattrape de toute façon, cf. preuve d'inatteignabilité historique) et (f)
# (exclusion D-31-03 — routine elle aussi : settings.json, memory/*, etc. y passent à CHAQUE
# module). Journaliser (c)/(f) inonderait le compte rendu d'un signal qui cesserait d'être lu
# (même motif que D-31-14) ; c'est exactement le correctif de transparence de ce lot pour (d)/(e)/
# (g), qui eux étaient MUETS alors qu'un refus y est le signe d'une attaque ou d'une anomalie.
VF_REMOVABLE_REASON=""
vf_removable() {
  local rel="$1"
  local full="$TARGET_ROOT/$rel"
  VF_REMOVABLE_REASON=""
  # (c) existe sur disque — redondant avec (d) (preuve d'inatteignabilité conservée en commentaire
  #     historique sur l'ancien site d'appel, cf. vf_converge_apply). Aucun motif journalisé : cas
  #     ordinaire, pas un refus de sûreté.
  [ -e "$full" ] || return 1
  # (d) fichier RÉGULIER — jamais un lien, jamais un répertoire (défense en profondeur du grain
  #     fichier D-31-02 : une ligne répertoire autoriserait une suppression de masse).
  if ! { [ -f "$full" ] && [ ! -L "$full" ]; }; then
    VF_REMOVABLE_REASON="pas un fichier régulier (lien ou répertoire)"
    return 1
  fi
  # (e) résout SOUS TARGET_ROOT après normalisation textuelle — pas de `..` échappatoire.
  if ! vf_rel_to_target "$full" >/dev/null 2>&1; then
    VF_REMOVABLE_REASON="hors TARGET_ROOT après normalisation"
    return 1
  fi
  # (f) hors liste close d'exclusions D-31-03 — un artefact partagé n'est jamais candidat. Aucun
  #     motif journalisé : routine (chaque module y rencontre settings.json/memory/* etc.).
  if vf_manifest_excluded "$rel"; then
    return 1
  fi
  # (g) résolution PHYSIQUE (D-31-15, arbitrage de Samuel) : (e) ci-dessus normalise
  #     TEXTUELLEMENT — un ANCÊTRE symlinké (ex. .claude/rules -> /tmp/…) résout « sous
  #     TARGET_ROOT » textuellement sans que le fichier réel le soit.
  if ! vf_physical_parent_under_target "$full"; then
    VF_REMOVABLE_REASON="résolution physique hors TARGET_ROOT (ancêtre symlinké)"
    return 1
  fi
  return 0
}

# Consigne <chemin_dest> dans l'accumulateur courant si (a) il résout sous TARGET_ROOT et
# (b) il n'est pas dans la liste close d'exclusions. Silencieux dans les deux autres cas —
# ce n'est jamais une erreur, seulement une exclusion volontaire du manifeste.
vf_record() {
  local dest="$1"
  local rel
  # Cycle non ouvert → no-op SILENCIEUX (révisé en 31-03, cf. SUMMARY) : depuis la migration des
  # ~35 sites, vf_place_file/vf_place_tree/vf_declare_write sont appelés depuis des fonctions
  # PARTAGÉES entre un contexte à cycle ouvert (install_module) et des contextes SANS cycle
  # (sync_module_governance côté update « version inchangée », uninstall_module côté
  # backup_module) — copy_engine_lib, copy_module_scripts, merge_module_hooks (backup settings)
  # et backup_module y sont légitimement appelées sans vf_manifest_reset. Avant cette migration,
  # ces chemins n'avaient JAMAIS touché le manifeste (cp brut) : un ERROR+return 1 ici ferait
  # avorter `update`/`uninstall` sous `set -e` — un changement de comportement observable que
  # D-31-01 interdit. `vf_manifest_reset`/`vf_record`/`vf_manifest_flush` restent sourcés
  # directement par T4b/T5b DANS un cycle ouvert : ce chemin n'est pas affecté.
  if [ -z "$VF_MANIFEST_TMP" ]; then
    VF_NOCYCLE_COUNT=$((VF_NOCYCLE_COUNT + 1))
    return 0
  fi
  rel="$(vf_rel_to_target "$dest")" || return 0
  vf_manifest_excluded "$rel" && return 0
  printf '%s\n' "$rel" >> "$VF_MANIFEST_TMP"
}

# Ouvre un accumulateur neuf pour <mod>. Appelé au début d'install_module.
vf_manifest_reset() {
  local mod="$1"
  VF_MANIFEST_MOD="$mod"
  VF_DEGRADED_COPIES_COUNT=0
  # 31-04 (D-31-06) : en dry-run, ne JAMAIS créer d'accumulateur ni de répertoire — seul
  # VF_MANIFEST_MOD est mémorisé, pour que vf_declare_write puisse afficher le suffixe
  # `(<module> <version>)` du verbe +. VF_MANIFEST_TMP reste vide : c'est ce qui garde
  # vf_record hors du chemin dry-run si jamais il était atteint (il ne l'est pas —
  # vf_declare_write court-circuite avant lui en dry-run).
  if vf_dry_run; then
    VF_MANIFEST_TMP=""
    return 0
  fi
  local manifest_dir
  manifest_dir="$(dirname "$(vf_manifest_path "$mod")")"
  mkdir -p "$manifest_dir"
  # W-1 (revue vague 1) : nommé HORS du motif `.vibeflow-manifest-*` (`.vibeflow-acc-…`, pas
  # `.vibeflow-manifest-….tmp.$$`) plutôt qu'un trap de nettoyage — un `cp`/étape qui échoue plus
  # loin dans install_module avorte le script (`set -euo pipefail`) AVANT vf_manifest_flush et
  # laisse ce fichier orphelin sur disque (atomicité de l'ancien manifeste préservée, lui). Un
  # trap aurait dû être pistée à travers install_module/update_module/sync_module_governance —
  # plusieurs points d'entrée, plusieurs oublis possibles. Sortir l'accumulateur du motif que
  # 31-05/31-07 vont découvrir par glob supprime la classe d'erreur à la racine, sans dépendre
  # d'un `trap` correctement posé à chaque appelant.
  # Mi4 (revue 31-03) : résidu d'une pose AVORTÉE (le PID d'un run précédent, jamais atteint par
  # vf_manifest_flush) nettoyé au cycle suivant du MÊME module — le nom `.vibeflow-acc-<mod>.<pid>`
  # est daté au PID, jamais réutilisé par la ré-install qui suit, donc jamais confondu avec
  # l'accumulateur créé juste après. Boucle avec garde d'existence (jamais un glob nu sous `set -e`
  # — non-satisfait romprait le script).
  local stale
  for stale in "$manifest_dir/.vibeflow-acc-${mod}."*; do
    [ -e "$stale" ] || continue
    rm -f "$stale"
  done
  VF_MANIFEST_TMP="$manifest_dir/.vibeflow-acc-${mod}.$$"
  : > "$VF_MANIFEST_TMP"
}

# Trie l'accumulateur (LC_ALL=C sort -u), l'écrit atomiquement (tmp + mv, patron
# mark_installed:115-124) vers $(vf_manifest_path "$VF_MANIFEST_MOD"), puis referme le cycle.
# Un accumulateur vide produit un manifeste vide (pas de manifeste ABSENT — réservé au parc
# pré-Phase-31, D-31-07).
vf_manifest_flush() {
  local target sorted_tmp
  # 31-04 (D-31-06) : en dry-run, le manifeste lui-même n'est jamais écrit. Il est annoncé
  # (verbe +, D-31-05) AVANT de vider VF_MANIFEST_MOD — vf_declare_write en a besoin pour le
  # suffixe module/version.
  if vf_dry_run; then
    target="$(vf_manifest_path "$VF_MANIFEST_MOD")"
    vf_declare_write + "$target"
    VF_MANIFEST_TMP=""
    VF_MANIFEST_MOD=""
    return 0
  fi
  # W-2 (revue vague 1) : même garde explicite que vf_record — cycle non ouvert = message clair.
  [ -n "$VF_MANIFEST_MOD" ] && [ -n "$VF_MANIFEST_TMP" ] || { log "  ERROR: vf_manifest_flush appelé hors cycle vf_manifest_reset (accumulateur manifeste non ouvert)"; return 1; }
  target="$(vf_manifest_path "$VF_MANIFEST_MOD")"
  sorted_tmp="${VF_MANIFEST_TMP}.sorted"
  LC_ALL=C sort -u "$VF_MANIFEST_TMP" > "$sorted_tmp"
  mv "$sorted_tmp" "$target"
  rm -f "$VF_MANIFEST_TMP"
  VF_MANIFEST_TMP=""
  VF_MANIFEST_MOD=""
}

# vf_declare_write <verbe> <chemin> [note] — LA couture unique (D-31-01). Verbe parmi + (créer)
# / ~ (modifier/merger) / - (supprimer).
#
# Mode PLAN (--dry-run, D-31-05) : émet sur STDOUT `[plan] <verbe> <chemin>`, et retourne 0 SANS
# consigner ni écrire quoi que ce soit — c'est la branche que TOUS les sites de pose traversent
# désormais en dry-run, via ce même point unique (D-31-01 par construction). Verbe + SANS note :
# suffixe `  (<module> <version>)` depuis le contexte courant (VF_MANIFEST_MOD, posé par
# vf_manifest_reset — y compris en dry-run — et module_version_available). Note fournie (quel
# que soit le verbe) : suffixe `  <note>` à la place. Ni l'un ni l'autre (verbes ~/- sans note) :
# la ligne nue. Chemin affiché = celui REÇU, préfixe TARGET_ROOT déjà inclus par l'appelant.
#
# Mode POSE RÉELLE (inchangé) : consigne <chemin> via vf_record quand le verbe est +. Les verbes
# ~ et - ne consignent rien (le manifeste ne trace que des créations, D-31-02).
vf_declare_write() {
  local verb="$1" path="$2" note="${3:-}"
  if vf_dry_run; then
    if [ "$verb" = "+" ] && [ -z "$note" ]; then
      printf '[plan] + %s  (%s %s)\n' "$path" "$VF_MANIFEST_MOD" "$(module_version_available "$VF_MANIFEST_MOD")"
    elif [ -n "$note" ]; then
      printf '[plan] %s %s  %s\n' "$verb" "$path" "$note"
    else
      printf '[plan] %s %s\n' "$verb" "$path"
    fi
    # Capture MIROIR de vf_record (31-05, D-31-07) : en dry-run, install_module ne flushe RIEN —
    # vf_converge_apply (appelé juste après, dans update_module) a besoin du manifeste que la pose
    # RÉELLE aurait produit pour le comparer à l'ancien. Même chemin de code que le verbe + réel
    # (D-31-01), jamais un second calcul séparé : relativisation + exclusion identiques à
    # vf_record, dans un contexte `if` (jamais un `&&` nu — vf_manifest_excluded rend 0 pour le
    # cas COURANT « exclu », qui romprait `set -e` en position finale d'un `&&`, D-31-13).
    if [ "$verb" = "+" ] && [ -n "$VF_CONVERGE_DRYSET" ]; then
      local dryrel
      if dryrel="$(vf_rel_to_target "$path")" && ! vf_manifest_excluded "$dryrel"; then
        printf '%s\n' "$dryrel" >> "$VF_CONVERGE_DRYSET"
      fi
    fi
    return 0
  fi
  case "$verb" in
    +) vf_record "$path" ;;
    ~|-) : ;;
  esac
}

# vf_note_degraded_copy <dest_file> — journalise sur stderr une copie cp -r dégradée : un
# fichier annoncé par l'énumération source de vf_place_tree mais ABSENT en destination après
# copie (D-31-11 point 4, option A du 2026-08-16 : un seul émetteur, au grain FICHIER, aucune
# déduplication par répertoire). Accumule dans VF_DEGRADED_COPIES_COUNT pour le compte rendu de
# fin de pose. Retourne TOUJOURS 0 — fonction d'observation, jamais de contrôle : si elle
# retournait non nul, `set -e` avorterait l'install sur l'événement précis qu'elle sert à ne PAS
# faire avorter. Un seul site d'appel dans tout le fichier : la boucle de vérification de
# présence de vf_place_tree, une fois par fichier manquant — jamais depuis le `cp` lui-même.
vf_note_degraded_copy() {
  local dest_file="$1"
  log "  copie dégradée : $dest_file"
  VF_DEGRADED_COPIES_COUNT=$((VF_DEGRADED_COPIES_COUNT + 1))
  return 0
}

# LE helper de pose fichier (D-31-01) : pose <src> vers <dest> (exécutable si [exec] fourni)
# ET consigne <dest> dans le même appel — le manifeste est un sous-produit, jamais une
# énumération séparée. Le rc de cp est capturé explicitement et propagé (échec de copie =
# échec de pose), y compris quand l'appelant place cet appel dans un contexte qui neutralise
# `set -e` (if/&&/||) — capturer et retourner le rc à la main est ce qui rend l'échec visible
# dans ce cas aussi.
vf_place_file() {
  local src="$1" dest="$2" mode="${3:-}"
  if vf_dry_run; then
    vf_declare_write + "$dest"
    return 0
  fi
  local rc=0
  mkdir -p "$(dirname "$dest")"
  # Mi2 (revue 31-03) : stderr du `cp` brut supprimé — sur le chemin dégradé (B2-B4), l'appelant
  # trace déjà l'échec via son propre `log` préfixé `[vibeflow-update]` ; sans ce garde, le
  # message `cp: …` brut de la commande système apparaissait en double, sans préfixe. Le chemin
  # nominal (succès, comportement inchangé, preuve md5) ne produit aucun stderr, donc rien à
  # perdre côté observable.
  cp "$src" "$dest" 2>/dev/null || rc=$?
  if [ "$rc" -ne 0 ]; then
    # Finding C (correction ciblée) : une copie dégradée ici ne doit PAS faire disparaître un
    # fichier ENCORE POSSÉDÉ du NOUVEAU manifeste. Si `$dest` existait déjà sur disque (pose
    # antérieure — le `cp` en échec n'y a rien écrit, `cp` ne touche jamais la destination quand
    # il ne peut pas lire la source), son absence du nouveau manifeste serait interprétée par
    # MANI-03 comme « le module ne le fournit plus » et le ferait SUPPRIMER à la convergence
    # suivante — alors qu'il est toujours valide, toujours possédé, juste pas RE-copié cette
    # fois-ci. On consigne l'ANCIEN chemin (inchangé sur disque) pour que la convergence le voie
    # des deux côtés du diff et ne le touche jamais ; jamais un lien (défense en profondeur,
    # même grain que D-31-02).
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
      vf_note_degraded_copy "$dest"
      vf_declare_write + "$dest"
    fi
    return "$rc"
  fi
  if [ "$mode" = "exec" ]; then
    chmod +x "$dest"
  fi
  vf_declare_write + "$dest"
}

# vf_place_tree <src_dir> <dest_dir> [exec] — pose d'un répertoire réel (cp -r) au grain fichier
# (D-31-02), réservée aux sites qui posent un <src_dir> complet via
# cp -r "$src_dir/"* "$dest_dir/". UNE SEULE énumération interne à DEUX usages (D-31-11) :
#   1. Annonce depuis la SOURCE, sémantique du glob (entrées de premier niveau commençant par
#      "." EXCLUES — exactement ce que "$src_dir"/* écarte déjà, comportement gelé D-31-11
#      point 2, PAS corrigé). C'est cette énumération que 31-04 branchera pour --dry-run.
#   2. Consignation par vérification de PRÉSENCE en DESTINATION après copie — jamais un `find`
#      aveugle sur la source, qui affirmerait au manifeste des fichiers jamais réellement écrits
#      (D-31-11 point 3).
# Le rc du `cp -r` est CAPTURÉ (`|| cp_rc=$?`, jamais `|| true` — W-1) : la fonction n'avorte pas
# sous `set -e` (contrat Phase 30 : copie best-effort, tolérance déjà en place avant ce lot) mais
# l'information survit pour les gardes ci-dessous. Chaque paire annoncée-mais-absente après copie
# est une copie DÉGRADÉE : journalisée via vf_note_degraded_copy (jamais consignée au manifeste),
# la pose n'échoue pas pour autant (D-31-11 point 4).
# Trou de silence rattrapé (D-31-11 point 4 §Complément, W-2) : si `cp_rc` a été affecté ET que la
# boucle de vérification n'a signalé AUCUN fichier manquant (énumération vide — $src_dir
# illisible, le cp échoue globalement sans qu'aucune paire ne pointe vers un fichier manquant),
# une ligne de compte rendu est émise malgré tout, au grain RÉPERTOIRE, SANS passer par
# vf_note_degraded_copy (qui reste réservée à son unique site d'appel, le grain fichier).
vf_place_tree() {
  local src_dir="${1%/}" dest_dir="${2%/}" mode="${3:-}"

  # Énumération SOURCE (D-31-11 points 1/2), en DEUX passes distinctes pour garder UNE SEULE
  # boucle de vérification ensuite — c'est ce qui rend le site d'appel à vf_note_degraded_copy
  # UNIQUE dans tout le fichier (D-31-11 point 4 option A) : une passe qui listait les fichiers
  # dans deux branches (entrée fichier / entrée répertoire) obligeait deux sites d'appel, exactement
  # le défaut payé cinq fois sur ce helper. Ici, la passe 1 aplatit tout en une seule liste de
  # fichiers ; la passe 2 (plus bas) est l'UNIQUE boucle de vérification/consignation.
  # 31-04 (D-31-11 point 1, R-1) : cette passe est calculée AVANT tout `cp`/`mkdir`, et c'est LA
  # MÊME en dry-run et à la pose réelle — un seul point d'énumération, jamais un second calcul
  # séparé sur la source, ce qui rend l'égalité plan/pose structurelle plutôt que coïncidente.
  local list_tmp entry name
  list_tmp="$(mktemp)"
  for entry in "$src_dir"/*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    case "$name" in
      .*) continue ;;  # dotfile de premier niveau : jamais annoncé ni posé (D-31-11 point 2, gelé)
    esac
    if [ -d "$entry" ]; then
      # B1 (revue 31-03, D-31-13) : ce `find` est la DERNIÈRE commande du corps de `if` — sous
      # `set -e`, son échec (sous-répertoire NICHÉ illisible en descendant) avorterait tout le
      # script et défierait depuis l'intérieur la garantie même de vf_place_tree (jamais avorter
      # sur copie dégradée, D-31-11 point 4). Tolérance restaurée EXPLICITEMENT : rc capturé,
      # jamais un `|| true` muet (contrat Phase 30, 0 = silence) — comptée dans le même compte
      # rendu de fin de pose que les autres copies dégradées (VF_DEGRADED_COPIES_COUNT). Les
      # fichiers que `find` a pu lire AVANT de heurter le sous-répertoire illisible restent dans
      # `$list_tmp` (la redirection `>>` s'applique quel que soit le code retour). En dry-run,
      # rien n'est en train d'être copié : ce message de copie dégradée serait un mensonge, donc
      # tu (vf_dry_run) le tait — seule l'énumération elle-même doit rester identique.
      find "$entry" -type f >> "$list_tmp" 2>/dev/null || {
        if ! vf_dry_run; then
          log "  copie dégradée : $entry (sous-répertoire illisible, énumération find en échec)"
          VF_DEGRADED_COPIES_COUNT=$((VF_DEGRADED_COPIES_COUNT + 1))
        fi
      }
    else
      printf '%s\n' "$entry" >> "$list_tmp"
    fi
  done

  # 31-04 (D-31-11 point 1) : en dry-run, le plan s'arrête ICI — annonce directe depuis
  # l'énumération SOURCE ci-dessus, SANS mkdir/cp ni vérification de présence en destination
  # (elle n'existe pas encore sur un lab vierge). C'est la RÉUTILISATION de la même énumération,
  # jamais un second `find` séparé, qui rend l'égalité de MANI-02 vraie par construction.
  if vf_dry_run; then
    local f rel dest_file
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      rel="${f#"$src_dir"/}"
      dest_file="$dest_dir/$rel"
      vf_declare_write + "$dest_file"
    done < "$list_tmp"
    rm -f "$list_tmp"
    return 0
  fi

  mkdir -p "$dest_dir"
  local cp_rc=""
  cp -r "$src_dir"/* "$dest_dir"/ 2>/dev/null || cp_rc=$?

  # Passe 2 — L'UNIQUE boucle de vérification de présence : pour chaque fichier de l'énumération
  # SOURCE, teste sa présence en DESTINATION après copie (D-31-11 point 3). Présent → consigné
  # (vf_declare_write) ; absent → copie dégradée, journalisée au SEUL site d'appel de
  # vf_note_degraded_copy dans tout le fichier.
  local f rel dest_file missing_count=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="${f#"$src_dir"/}"
    dest_file="$dest_dir/$rel"
    if [ -f "$dest_file" ]; then
      [ "$mode" = "exec" ] && chmod +x "$dest_file"
      vf_declare_write + "$dest_file"
    else
      vf_note_degraded_copy "$dest_file"
      missing_count=$((missing_count + 1))
    fi
  done < "$list_tmp"
  rm -f "$list_tmp"

  # Trou de silence rattrapé (D-31-11 point 4 §Complément, W-2) : $src_dir illisible → l'énumération
  # ci-dessus rend zéro paire, la boucle n'itère jamais, missing_count reste à 0 — SANS ce garde,
  # rien ne serait dit. Émis au grain RÉPERTOIRE, SANS passer par vf_note_degraded_copy (qui reste
  # réservée à son unique site d'appel ci-dessus, le grain fichier).
  # M2 (revue 31-03) : `cp_rc` seul est un FAUX POSITIF sur un `$src_dir` légitimement VIDE mais
  # lisible — le glob `"$src_dir"/*` ne s'expand sur rien, `cp` échoue (« no such file »),
  # `cp_rc` est affecté ET `missing_count` reste à 0, exactement le même couple de symptômes
  # qu'un `$src_dir` illisible. Le troisième garde (`[ ! -r "$src_dir" ]`) distingue les deux :
  # un répertoire vide reste LISIBLE (`-r` vrai), seul un répertoire réellement illisible
  # (permission refusée, ou disparu) fait échouer ce test. Un dossier vide lisible ne crie plus.
  if [ -n "$cp_rc" ] && [ "$missing_count" -eq 0 ] && [ ! -r "$src_dir" ]; then
    log "  copie dégradée : $src_dir (source illisible ou cp en échec, aucun fichier énuméré)"
    VF_DEGRADED_COPIES_COUNT=$((VF_DEGRADED_COPIES_COUNT + 1))
  fi
  return 0
}

# ---------- Résolveur de fermeture transitive (intégration Phase 2) ----------
# Localise resolve-deps.sh : d'abord dans le cache (prod, bundlé par Phase 5/PLUG-02),
# sinon à côté de l'engine (dev/source). Renvoie le chemin du résolveur, ou vide si absent.
find_resolver() {
  local candidate
  candidate="$CACHE_DIR/_internal/resolve-deps.sh"
  if [ -f "$candidate" ]; then echo "$candidate"; return 0; fi
  candidate="$(dirname "$0")/resolve-deps.sh"
  if [ -f "$candidate" ]; then echo "$candidate"; return 0; fi
  echo ""
}

# resolve_closure <mod...> : émet sur stdout la fermeture transitive (1 module/ligne).
# Si le résolveur est ABSENT, fallback best-effort = renvoie les args bruts, MAIS loue
# un AVERTISSEMENT BRUYANT (warning visible) — closure incomplète = install possiblement cassée.
resolve_closure() {
  local resolver
  resolver="$(find_resolver)"
  if [ -z "$resolver" ]; then
    # Fallback résolveur-absent : warning BRUYANT (sur stderr, sans exit) — T-03-08.
    echo "[vibeflow-update] ERROR: ATTENTION : résolveur introuvable — fermeture transitive NON calculée. Les dépendances de $* ne seront PAS installées ; l'install peut être incomplète/cassée. (Phase 5/PLUG-02 doit bundler resolve-deps.sh dans le cache.)" >&2
    printf '%s\n' "$@"
    return 0
  fi
  # VF_MODULES_ROOT pointe sur le CACHE (les module.json y vivent), pas sur le repo.
  VF_MODULES_ROOT="$CACHE_DIR" bash "$resolver" "$@"
}

# ---------- Gitignore local (SCOPE-04) ----------
# Ajoute les chemins installés du module au ./.gitignore (cwd projet) UNIQUEMENT en scope local.
# Idempotent : pas de doublon (grep -qxF avant ajout). Crée .gitignore s'il manque.
gitignore_add_one() {
  local path="$1"
  if vf_dry_run; then
    vf_declare_write "~" "./.gitignore" "$path"
    return 0
  fi
  # Création paresseuse du .gitignore au premier ajout.
  [ -f .gitignore ] || : > .gitignore
  if ! grep -qxF "$path" .gitignore; then
    echo "$path" >> .gitignore
    log "  gitignore += $path"
  fi
}

gitignore_add_paths() {
  local mod="$1"
  # Scope local seulement : user/project ne touchent JAMAIS au .gitignore.
  [ "$VF_SCOPE" = "local" ] || return 0

  local module_dir="$CACHE_DIR/$mod"

  # Skill racine.
  [ -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/skills/$mod/"
  # Skills imbriqués.
  if [ -d "$module_dir/skills" ]; then
    for skill_dir in "$module_dir/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      gitignore_add_one ".claude/skills/$(basename "$skill_dir")/"
    done
  fi
  # Agent module (D7) : AGENT.md + dossier references.
  if [ -f "$module_dir/AGENT.md" ]; then
    gitignore_add_one ".claude/agents/${mod}.md"
    gitignore_add_one ".claude/commands/${mod}.md"
    [ -d "$module_dir/references" ] && gitignore_add_one ".claude/agents/${mod}-references/"
  fi
  # Multi-agents module : agents/<name>.md.
  if [ -d "$module_dir/agents" ]; then
    for f in "$module_dir/agents/"*.md; do
      [ -f "$f" ] && gitignore_add_one ".claude/agents/$(basename "$f")"
    done
    [ -d "$module_dir/references" ] && [ ! -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/agents/${mod}-references/"
  fi
  # Rules réellement posées.
  if [ -d "$module_dir/rules" ]; then
    for f in "$module_dir/rules/"*.md; do
      [ -f "$f" ] && gitignore_add_one ".claude/rules/$(basename "$f")"
    done
  fi
  # Scripts réellement posés (shell + Node).
  if [ -d "$module_dir/scripts" ]; then
    for f in "$module_dir/scripts/"*.sh "$module_dir/scripts/"*.mjs "$module_dir/scripts/"*.js; do
      [ -f "$f" ] && gitignore_add_one ".claude/scripts/$(basename "$f")"
    done
  fi
  # Registres mémoire (SCOPE-04) : si le module fournit un seeder de registres, les fichiers qu'il
  # crée — à l'install ET à chaque SessionStart — doivent suivre la promesse du scope local
  # (« rien ne sera committé »). Sans cette ligne, l'engine gitignorait ses propres artefacts mais
  # laissait les 5 registres semés apparaître en untracked dans le git status du projet. Le
  # sélecteur est le seeder lui-même (data-driven, pas de nom de module en dur).
  [ -f "$module_dir/scripts/seed-registres.sh" ] && gitignore_add_one ".claude/memory/"
  # Config template posé à côté d'un SKILL.md racine.
  [ -d "$module_dir/config" ] && [ -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/skills/$mod/config/"
  # settings.json + settings.local.json (SCOPE-04, Phase 30 tâche 4, corrigé en revue) : en scope
  # LOCAL, `merge_module_hooks()` écrit dans $TARGET_ROOT/settings.json ET, depuis le routage
  # --settings-local (tâche 4), dans $TARGET_ROOT/settings.local.json pour toute entrée portant le
  # chemin absolu machine {{VF_BASH}}. La même promesse « rien ne sera committé » que le reste de
  # cette fonction s'applique aux DEUX fichiers : le premier vérifié initialement par lecture du
  # code (pas par convention supposée), le second ajouté après que la revue a testé — et invalidé —
  # l'hypothèse qu'une convention hors-dépôt (gitignore global du mainteneur) suffisait à couvrir un
  # lab cible frais. Sélecteur data-driven identique aux deux lignes (même style que
  # seed-registres.sh ci-dessus) : seul un module qui PORTE un fragment hooks/hooks.json (donc qui
  # écrit réellement dans ces fichiers à cette install) déclenche l'ajout.
  [ -f "$module_dir/hooks/hooks.json" ] && gitignore_add_one ".claude/settings.json"
  [ -f "$module_dir/hooks/hooks.json" ] && gitignore_add_one ".claude/settings.local.json"
  # Lib partagée de portabilité (Phase 30 tâche 2, copy_engine_lib()) : posée par l'ENGINE, pas
  # par un module — donc jamais vue par la boucle scripts/ plus haut (elle vient du cache
  # _internal, jamais de $module_dir/scripts). Gap constaté en tâche 4 lors de la vérification
  # manuelle de ce plan (Rule 2, deviation documentée au SUMMARY) : sans cette ligne,
  # .claude/scripts/vf-portable.sh échappait à la promesse « rien ne sera committé » du scope
  # local. Inconditionnel : copy_engine_lib() la pose à CHAQUE exécution de l'engine en scope
  # local, quel que soit le module installé — gitignore_add_one() reste idempotent.
  gitignore_add_one ".claude/scripts/vf-portable.sh"
}

# ---------- Commande d'incarnation (ADR-042) ----------
# Après pose d'un agent, générer sa commande slash `/agent` (incarnation FENÊTRE PRINCIPALE).
# Best-effort : ne JAMAIS faire échouer l'install si le générateur est absent. Idempotent
# (le générateur n'écrase jamais une commande existante).
find_command_generator() {
  local c
  c="$TARGET_ROOT/scripts/generate-agent-commands.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$CACHE_DIR/conductor/scripts/generate-agent-commands.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

generate_agent_command_for() {
  local mod="$1" gen
  if vf_dry_run; then
    # 31-04 (piège de garde, D-31-04) : la CASCADE de find_command_generator regarde
    # $TARGET_ROOT/scripts/ EN PREMIER — un candidat DESTINATION, faux sur un lab vierge en
    # dry-run (copy_module_scripts, qui le poserait, est neutralisée). L'appelant a déjà établi
    # la garde SOURCE (module_dir/AGENT.md existe, seule condition avant cet appel) : ne PAS
    # invoquer find_command_generator ni exécuter le générateur — régime A, sortie prédite
    # exactement.
    vf_declare_write + "$TARGET_ROOT/commands/${mod}.md"
    return 0
  fi
  gen="$(find_command_generator)"
  if [ -z "$gen" ]; then
    log "  (commande d'incarnation non générée — generate-agent-commands.sh absent, best-effort)"
    return 0
  fi
  if VF_TARGET_ROOT="$TARGET_ROOT" bash "$gen" --agent "$mod" >/dev/null 2>&1; then
    log "  commande d'incarnation → $TARGET_ROOT/commands/${mod}.md"
    # Site #16 (31-03) : régime A (D-31-04) — sortie prédite exactement, annoncée au succès.
    vf_declare_write + "$TARGET_ROOT/commands/${mod}.md"
  else
    log "  (commande d'incarnation non générée pour $mod — best-effort)"
  fi
}

# ---------- Injection MCP dérivée du lab (ADR-051) ----------
# Un sous-agent (Task) n'hérite PAS des serveurs MCP de la session : il ne voit, côté MCP, que ce
# que son `tools:` autorise (`mcp__<serveur>__*`). Les agents exécutants (flag vf-mcp-consumer:true)
# doivent donc recevoir les serveurs que le LAB déclare dans son ./.mcp.json. Data-driven (aucun nom
# de serveur ni d'agent en dur) ; best-effort (jamais faire échouer l'install). Idempotent.
find_mcp_injector() {
  local c
  c="$TARGET_ROOT/scripts/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$CACHE_DIR/dev-orchestrator/scripts/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

inject_lab_mcp_into_agents() {
  local injector
  if vf_dry_run; then
    # 31-04 (piège de garde, D-31-04) : find_mcp_injector regarde $TARGET_ROOT/scripts/ EN
    # PREMIER — un candidat DESTINATION que copy_module_scripts poserait, mais qui n'existe pas
    # encore sur un lab vierge en dry-run (copy_module_scripts est neutralisée). Sans ce
    # court-circuit, le sous-processus s'exécuterait RÉELLEMENT via le fallback CACHE_DIR de la
    # cascade — exactement ce qu'un dry-run interdit. L'appelant a déjà établi la garde SOURCE
    # (AGENT.md ou agents/ présent). Régime C : effet annoncé, non énuméré, sous-processus NON
    # appelé.
    vf_declare_write "~" "$TARGET_ROOT/agents" "effet de inject-mcp-tools.sh, contenu non énuméré"
    return 0
  fi
  injector="$(find_mcp_injector)"
  if [ -z "$injector" ]; then
    log "  (injection MCP non exécutée — inject-mcp-tools.sh absent, best-effort)"
    return 0
  fi
  # Source = ./.mcp.json du LAB (cwd projet), quel que soit le scope (les serveurs MCP du projet y
  # vivent, pas dans TARGET_ROOT). Absent → le script no-op de lui-même.
  if bash "$injector" --target "$TARGET_ROOT/agents" --mcp-json "./.mcp.json" >/dev/null 2>&1; then
    log "  serveurs MCP du lab injectés dans les agents exécutants flaggés (vf-mcp-consumer, ADR-051)"
    # Site #19 (31-03) : régime C (D-31-04). Verbe ~ : no-op sur le manifeste.
    vf_declare_write "~" "$TARGET_ROOT/agents" "effet de inject-mcp-tools.sh, contenu non énuméré"
  else
    log "  (injection MCP best-effort — voir inject-mcp-tools.sh)"
  fi
}

# ---------- Lib partagée de portabilité (contrat PR #29, D-04, Phase 30) ----------
# vf-portable.sh (résolution Python centralisée, jqx, vf_guard_unavailable) est possédée par
# l'ENGINE — jamais par un module, sans quoi elle disparaîtrait à la désinstallation du module qui
# l'aurait portée (contrat §2). Posée par copy_engine_lib(), même patron de cascade que
# find_hooks_merger()/find_mcp_injector() ci-dessous : cache du plugin d'abord, lib voisine du
# script ensuite (aucun candidat relatif au répertoire courant).
find_engine_lib() {
  local c
  c="$CACHE_DIR/_internal/lib/vf-portable.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/lib/vf-portable.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

# Idempotence INTRA-PROCESSUS (Phase 30, RESEARCH.md §copy_engine_lib) : appelée depuis DEUX
# chemins qui posent des fichiers chez l'utilisateur — install_module() et sync_module_governance()
# (le chemin « version inchangée » de update_module()) — sans ce garde-fou elle recopierait la lib
# à chaque module d'une boucle --all. Un seul appel a un effet ; les suivants sont des no-op.
VF_ENGINE_LIB_COPIED="0"

copy_engine_lib() {
  [ "$VF_ENGINE_LIB_COPIED" = "1" ] && return 0
  local src dest tmp
  src="$(find_engine_lib)"
  if [ -z "$src" ]; then
    # VG-3 (même discipline que merge_module_hooks) : jamais un retour neutre silencieux. Un lab
    # sans la lib casse le `source` des 3 consommateurs PYBIN au premier appel (Runtime State
    # Inventory, RESEARCH.md) — l'absence de lib est un échec d'install, pas un détail dégradé.
    log "  ERROR: vf-portable.sh introuvable dans le cache — lib de portabilité NON posée (installer/mettre à jour l'engine)"
    return 1
  fi
  dest="$TARGET_ROOT/scripts/vf-portable.sh"
  if vf_dry_run; then
    vf_declare_write + "$dest"
    VF_ENGINE_LIB_COPIED="1"
    return 0
  fi
  mkdir -p "$TARGET_ROOT/scripts"
  tmp="$dest.tmp.$$"
  # Écriture ATOMIQUE (copie vers un temporaire du MÊME répertoire, puis renommage) : une install
  # interrompue laisse soit l'ancienne lib, soit la nouvelle, jamais un fichier tronqué qu'un
  # consommateur sourcerait à moitié. SANS chmod +x : la lib est sourcée, jamais lancée seule.
  if cp "$src" "$tmp" 2>/dev/null && mv -f "$tmp" "$dest" 2>/dev/null; then
    VF_ENGINE_LIB_COPIED="1"
    log "  lib vf-portable.sh posée → $dest"
    # Annoncé (D-31-01) mais exclu du manifeste par D-31-03 (scripts/vf-portable.sh, propriété
    # de l'engine, partagée entre modules) — vf_record s'en abstiendra lui-même via
    # vf_manifest_excluded. No-op silencieux si appelée hors cycle (sync_module_governance).
    vf_declare_write + "$dest"
    return 0
  fi
  rm -f "$tmp" 2>/dev/null || true
  log "  ERROR: pose de vf-portable.sh ÉCHOUÉE → $dest"
  return 1
}

# ---------- Hooks de gouvernance (ADR-043) ----------
# Un module peut déclarer hooks/hooks.json (format Claude Code, placeholder {{VF_SCRIPTS}}).
# L'install MERGE le fragment dans le settings.json du scope ; l'uninstall le retire.
# La gouvernance est posée par la machine — plus jamais un snippet à copier-coller.
find_hooks_merger() {
  local c
  c="$CACHE_DIR/_internal/merge-hooks.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/merge-hooks.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

scripts_prefix_for_scope() {
  # Chemins LITTÉRAUX dans settings.json, valables pour la forme SHELL uniquement (c'est le
  # shell qui exécute la commande qui les expanse). Pour la forme exec (`args`), merge-hooks.sh
  # dérive lui-même la variante exec-safe (hotfix v2.53.1) : "$HOME" → chemin absolu résolu à
  # l'install, "$CLAUDE_PROJECT_DIR" → placeholder harness ${CLAUDE_PROJECT_DIR} — car en forme
  # exec aucun shell n'intervient et le harness ne substitue que ses propres placeholders.
  case "$VF_SCOPE" in
    user) printf '%s' '"$HOME"/.claude/scripts' ;;
    *)    printf '%s' '"$CLAUDE_PROJECT_DIR"/.claude/scripts' ;;
  esac
}

merge_module_hooks() {
  local mod="$1"
  local fragment="$CACHE_DIR/$mod/hooks/hooks.json"
  [ -f "$fragment" ] || return 0
  local merger
  merger="$(find_hooks_merger)"
  if [ -z "$merger" ]; then
    # VG-3 : ce `return 0` faisait sortir l'install en succès après une gouvernance absente —
    # le lab existait en croyant avoir ses hooks. L'échec se propage désormais (set -e → abort,
    # mark_installed jamais atteint : le registre ne ment pas).
    log "  ERROR: merge-hooks.sh introuvable — hooks de $mod NON câblés (gouvernance absente !)"
    return 1
  fi
  # 31-04 (D-31-04 régime B) : preview DÉLÉGUÉE à `merge-hooks.sh plan`, jamais réimplémentée
  # côté engine (interdit explicite). merge-hooks.sh plan réutilise sa propre logique de merge
  # pour rendre la MÊME répartition project/local, sur les MÊMES flags que le merge réel — la
  # sortie stdout du sous-processus est relayée TELLE QUELLE, déjà au format `[plan] ~ …`. Le
  # backup de settings est ANNONCÉ (F-01, correction ciblée 31-04 : garde sur VF_SETTINGS_JSON_
  # WILL_EXIST, PAS le disque — en multi-module settings.json est aussi créé par un module
  # ANTÉRIEUR du MÊME run, que le dry-run, qui n'écrit rien, ne peut pas voir sur disque) mais
  # jamais copié.
  if vf_dry_run; then
    if [ "$VF_SETTINGS_JSON_WILL_EXIST" = "1" ]; then
      local settings_backup="$BACKUP_DIR/settings-$(date +%Y%m%d-%H%M%S).json"
      vf_declare_write + "$settings_backup"
    fi
    # Après CE module, settings.json existe pour la suite du run (déjà là, ou créé par le merge
    # que ce plan prévisualise) — miroir de VF_ENGINE_LIB_COPIED, posé qu'importe l'état de départ.
    VF_SETTINGS_JSON_WILL_EXIST="1"
    local -a plan_settings_local_args=()
    case "$VF_SCOPE" in
      project|local) plan_settings_local_args=(--settings-local "$TARGET_ROOT/settings.local.json") ;;
    esac
    local plan_rc=0
    if [ "${#plan_settings_local_args[@]}" -gt 0 ]; then
      bash "$merger" plan "$fragment" --settings "$TARGET_ROOT/settings.json" \
        --scripts-prefix "$(scripts_prefix_for_scope)" "${plan_settings_local_args[@]}" || plan_rc=$?
    else
      bash "$merger" plan "$fragment" --settings "$TARGET_ROOT/settings.json" \
        --scripts-prefix "$(scripts_prefix_for_scope)" || plan_rc=$?
    fi
    return "$plan_rc"
  fi
  # Backup du settings avant toute écriture.
  # Site #21 (31-03) : annonce en tête (verbe +), puis le cp existant reste INTENTIONNELLEMENT
  # brut — copie de sauvegarde vers un nom horodaté, exclue du manifeste par D-31-03. No-op
  # silencieux si appelée hors cycle (sync_module_governance côté update « version inchangée »).
  if [ -f "$TARGET_ROOT/settings.json" ]; then
    mkdir -p "$BACKUP_DIR"
    local settings_backup="$BACKUP_DIR/settings-$(date +%Y%m%d-%H%M%S).json"
    # Mi1 (revue 31-03) : annonce APRÈS l'écriture réelle, jamais avant — patron `vf_place_file`
    # (D-31-01). Sans conséquence ici (.backups/** est dans la liste close d'exclusions, D-31-03),
    # mais un mauvais précédent à ne pas reconduire.
    cp "$TARGET_ROOT/settings.json" "$settings_backup"
    vf_declare_write + "$settings_backup"
  fi
  # Routage --settings-local (Phase 30 tâche 4, D-01) : en scope project/local, merge-hooks.sh
  # bascule vers CE fichier les seules entrées portant {{VF_BASH}} — un chemin absolu de bash
  # résolu à CETTE install, donc machine-spécifique. Sans ce routage, un tel chemin atterrirait
  # dans settings.json de PROJET, qui voyage via git. Scope user : no-op assumé, $HOME/.claude est
  # déjà par-machine. Tableau vide sous `set -u` (bash 3.2 : ne JAMAIS expanser "${arr[@]}" d'un
  # tableau vide sans le garder derrière un test de longueur — même garde que `_positional` plus
  # haut dans ce fichier), jamais une variable non définie.
  local -a settings_local_args=()
  case "$VF_SCOPE" in
    project|local) settings_local_args=(--settings-local "$TARGET_ROOT/settings.local.json") ;;
  esac
  local merge_rc=0
  if [ "${#settings_local_args[@]}" -gt 0 ]; then
    bash "$merger" merge "$fragment" --settings "$TARGET_ROOT/settings.json" \
      --scripts-prefix "$(scripts_prefix_for_scope)" "${settings_local_args[@]}" || merge_rc=$?
  else
    bash "$merger" merge "$fragment" --settings "$TARGET_ROOT/settings.json" \
      --scripts-prefix "$(scripts_prefix_for_scope)" || merge_rc=$?
  fi
  if [ "$merge_rc" -eq 0 ]; then
    log "  hooks mergés → $TARGET_ROOT/settings.json"
  else
    log "  ERROR: merge hooks ÉCHOUÉ pour $mod — gouvernance NON câblée (corriger settings.json puis réinstaller)"
    return 1  # VG-3 : l'échec se propage (plus de succès silencieux sans gouvernance)
  fi
}

remove_module_hooks() {
  local mod="$1"
  local fragment="$CACHE_DIR/$mod/hooks/hooks.json"
  [ -f "$fragment" ] || return 0
  [ -f "$TARGET_ROOT/settings.json" ] || return 0
  local merger
  merger="$(find_hooks_merger)"
  [ -n "$merger" ] || { log "  (retrait hooks impossible — merge-hooks.sh absent)"; return 0; }
  # Même routage --settings-local que merge_module_hooks (Phase 30 tâche 4) : en mode remove,
  # merge-hooks.sh balaie les DEUX cibles quand --settings-local est fournie — sans ce miroir, une
  # désinstallation deviendrait partielle et laisserait un hook orphelin dans le settings local.
  local -a settings_local_args=()
  case "$VF_SCOPE" in
    project|local) settings_local_args=(--settings-local "$TARGET_ROOT/settings.local.json") ;;
  esac
  local remove_rc=0
  if [ "${#settings_local_args[@]}" -gt 0 ]; then
    bash "$merger" remove "$fragment" --settings "$TARGET_ROOT/settings.json" "${settings_local_args[@]}" || remove_rc=$?
  else
    bash "$merger" remove "$fragment" --settings "$TARGET_ROOT/settings.json" || remove_rc=$?
  fi
  if [ "$remove_rc" -eq 0 ]; then
    log "  hooks retirés de $TARGET_ROOT/settings.json"
  else
    log "  (retrait hooks échoué pour $mod — best-effort, nettoyer settings.json à la main)"
  fi
}

# ---------- Scripts (posés au TARGET_ROOT/scripts) ----------
# Copie les scripts d'un module (shell + Node) + le sous-dossier tests/. Extrait d'install_module
# pour être réutilisable par la resync gouvernance (update version inchangée).
copy_module_scripts() {
  local mod="$1"
  local module_dir="$CACHE_DIR/$mod"
  [ -d "$module_dir/scripts" ] || return 0
  # 31-04 : chaque `vf_place_file` court-circuite déjà en dry-run, mais ce `mkdir -p` est HORS du
  # helper — sans cette garde, un dry-run créerait quand même $TARGET_ROOT/scripts sur un lab
  # vierge (D-31-06 : « n'écrit rien du tout »).
  vf_dry_run || mkdir -p "$TARGET_ROOT/scripts"
  # Site #2 (31-03) : GARDE D'EXISTENCE CONSERVÉE — le glob triple s'expand presque toujours en
  # littéral (rares modules ayant les trois extensions), et sous `set -euo pipefail` un
  # `vf_place_file` nu dans ce corps de boucle propagerait un échec de copie improbable en abort
  # de toute l'install (cf. règle set -e × rc, 31-03-PLAN.md). La garde `[ -f "$f" ] &&` neutralise
  # le cas non-satisfait AVANT que `set -e` le voie — jamais retirée au prétexte que le helper
  # « gère déjà » l'échec : il le propage, il ne l'absorbe pas.
  # B4 (revue 31-03, D-31-13) : avant migration, `[ -f "$f" ] && cp … && chmod +x` (3 commandes,
  # `cp` MÉDIANE — exemptée d'errexit). L'appel nu au helper, réduit à 2 commandes, met désormais
  # `vf_place_file` en position FINALE : son échec avorterait tout le script sur un seul fichier
  # illisible. Tolérance restaurée EXPLICITEMENT (jamais un `|| true` muet, contrat Phase 30).
  for f in "$module_dir/scripts/"*.sh "$module_dir/scripts/"*.mjs "$module_dir/scripts/"*.js; do
    if [ -f "$f" ]; then
      vf_place_file "$f" "$TARGET_ROOT/scripts/$(basename "$f")" exec || {
        log "  copie dégradée : $TARGET_ROOT/scripts/$(basename "$f") (pose en échec)"
        VF_DEGRADED_COPIES_COUNT=$((VF_DEGRADED_COPIES_COUNT + 1))
      }
    fi
  done
  # Site #3 (31-03), même motif de garde que #2. Fichiers de DONNEES accompagnant les scripts
  # (*.txt). Sans cette boucle, un module pouvait referencer un fichier que l'engine ne posait
  # JAMAIS chez l'utilisateur : c'est exactement ce qui est arrive a `known-versions.txt`
  # (infrastructure-audit), lu par audit-infra.sh en $SCRIPTS_DIR/known-versions.txt et absent de
  # toute install. Glob volontairement borne a *.txt — assez large pour la whitelist, assez etroit
  # pour ne pas ramasser les residus (*.bak) ni les manifestes de config. Pas de mode exec : ce
  # sont des donnees, pas des executables.
  for f in "$module_dir/scripts/"*.txt; do
    [ -f "$f" ] && vf_place_file "$f" "$TARGET_ROOT/scripts/$(basename "$f")"
  done
  # Site #4 (31-03) : globs de FICHIERS restreints (tests/*.sh, tests/fixtures/*), PAS la pose
  # d'un répertoire entier — vf_place_tree ne s'applique pas ici (elle reproduirait la sémantique
  # de `cp -r "$src_dir/"*`, càd TOUT `$src_dir`, ce que ces deux globs précis n'atteignent
  # jamais). Grain fichier via vf_place_file, garde d'existence obligatoire (même motif que #2/#3
  # pour la garde d'EXISTENCE seulement). Correction (revue 31-03) : cette phrase était FACTUELLEMENT
  # FAUSSE au-delà de la garde d'existence — #2/#3 n'ont JAMAIS porté de `|| true`, alors que CE
  # site en portait TROIS, indépendants, avant migration (B3, D-31-13). L'appel nu au helper, en
  # position finale de chacune des deux boucles, avorterait désormais tout le script sur un seul
  # fichier illisible ; tolérance restaurée EXPLICITEMENT (jamais un `|| true` muet).
  if [ -d "$module_dir/scripts/tests" ]; then
    vf_dry_run || mkdir -p "$TARGET_ROOT/scripts/tests/fixtures"
    for f in "$module_dir/scripts/tests/"*.sh; do
      [ -f "$f" ] || continue
      vf_place_file "$f" "$TARGET_ROOT/scripts/tests/$(basename "$f")" exec || {
        log "  copie dégradée : $TARGET_ROOT/scripts/tests/$(basename "$f") (pose en échec)"
        VF_DEGRADED_COPIES_COUNT=$((VF_DEGRADED_COPIES_COUNT + 1))
      }
    done
    for f in "$module_dir/scripts/tests/fixtures/"*; do
      [ -f "$f" ] || continue
      vf_place_file "$f" "$TARGET_ROOT/scripts/tests/fixtures/$(basename "$f")" || {
        log "  copie dégradée : $TARGET_ROOT/scripts/tests/fixtures/$(basename "$f") (pose en échec)"
        VF_DEGRADED_COPIES_COUNT=$((VF_DEGRADED_COPIES_COUNT + 1))
      }
    done
  fi
  log "  copied scripts/ → $TARGET_ROOT/scripts/"
}

# Resync gouvernance légère (Fix B) : re-pose les scripts + re-merge les hooks d'un module SANS
# backup ni re-copie complète. Appelée quand la version est INCHANGÉE — rend /vf-update
# auto-réparateur si un hooks.json a dérivé (nouveau hook posé sans bump de VERSION du module).
# Idempotent : merge-hooks dédup par basename, la copie de scripts écrase à l'identique.
# seed_module_registres : si le module fournit seed-registres.sh, instancier les registres canon
# manquants. Fonction plutôt qu'appel inline parce qu'elle a DEUX appelants (install_module et
# sync_module_governance) : c'est ce qui rend la mémoire transparente à l'update, y compris quand la
# version du module n'a pas bougé — le chemin « déjà à jour » ne repasse jamais par install_module.
# Sans ce second appel, un lab configuré avant cette version n'aurait ses registres qu'au prochain
# bump de consolidator, soit jamais si celui-ci n'évolue plus.
seed_module_registres() {
  local mod="$1"
  local seeder="$TARGET_ROOT/scripts/seed-registres.sh"
  [ -f "$CACHE_DIR/$mod/scripts/seed-registres.sh" ] || return 0
  if vf_dry_run; then
    # 31-04 (piège de garde, D-31-04) : [ -f "$seeder" ] est une garde DESTINATION, fausse sur
    # un lab vierge en dry-run — la garde côté SOURCE ci-dessus a déjà tranché. Régime C : effet
    # annoncé, non énuméré, sous-processus NON appelé.
    vf_declare_write "~" "$TARGET_ROOT/memory" "effet de seed-registres.sh, contenu non énuméré"
    return 0
  fi
  [ -f "$seeder" ] || return 0
  if bash "$seeder" --quiet >/dev/null; then
    log "  registres mémoire vérifiés/instanciés → seed-registres.sh"
    # Site #18 (31-03) : régime C (D-31-04). Verbe ~ : no-op sur le manifeste (D-31-03, contenu
    # vivant du lab), no-op aussi hors cycle (appelée depuis install_module ET
    # sync_module_governance).
    vf_declare_write "~" "$TARGET_ROOT/memory" "effet de seed-registres.sh, contenu non énuméré"
  else
    log "  (registres mémoire non instanciés — best-effort, voir seed-registres.sh)"
  fi
}

sync_module_governance() {
  local mod="$1"
  # D-31-14 : cette fonction n'ouvre JAMAIS de cycle manifeste (pas de vf_manifest_reset) — sûr
  # par construction (vf_manifest_flush ÉCRASE au lieu de fusionner, un cycle ici TRONQUERAIT le
  # manifeste complet au sous-ensemble que ce resync touche), mais chaque pose qui en résulte est
  # un no-op SILENCIEUX côté manifeste (vf_record, cf. commentaire). Compteur remis à 0 ICI,
  # rapporté en UNE ligne par module en fin de fonction — jamais une ligne par chemin (sur 17
  # modules, `update --all` en produirait des dizaines, un signal qui spamme cesse d'être lu).
  #
  # F-02 (correction ciblée 31-04) : poser VF_MANIFEST_MOD SANS ouvrir de cycle — exactement ce
  # que fait déjà la branche dry-run de vf_manifest_reset elle-même (VF_MANIFEST_TMP y reste
  # vide, donc AUCUN accumulateur/répertoire créé, D-31-14 intact). Sans ce set, vf_declare_write
  # ignore le module courant sur ce chemin et le suffixe `(<module> <version>)` du verbe + tombe à
  # `( —)` sur TOUTES les lignes de `update --dry-run` version inchangée (défaut de FORMAT, aucune
  # écriture en jeu) — remis à vide en sortie pour ne rien laisser fuiter vers un appelant suivant.
  if vf_dry_run; then
    VF_MANIFEST_MOD="$mod"
  fi
  VF_NOCYCLE_COUNT=0
  # Chemin « version inchangée » (D-04) : sans cet appel, un lab déjà à jour n'obtiendrait JAMAIS
  # la lib de portabilité — idempotent au sein du même processus (VF_ENGINE_LIB_COPIED).
  copy_engine_lib
  copy_module_scripts "$mod"
  merge_module_hooks "$mod"
  # Ordre imposé : le seeder est posé par copy_module_scripts juste au-dessus. L'appeler avant
  # rendrait le resync inerte sur un lab où le script n'a jamais été installé — exactement le cas
  # qu'on cherche à rattraper.
  seed_module_registres "$mod"
  if [ "$VF_NOCYCLE_COUNT" -gt 0 ]; then
    log "  $VF_NOCYCLE_COUNT chemin(s) posé(s) hors cycle manifeste, non consigné(s)"
  fi
  # F-02 : referme le contexte de dry-run posé en tête, jamais laissé fuiter vers l'appel suivant
  # (update --all itère sync_module_governance module par module, chacun avec son propre mod).
  if vf_dry_run; then
    VF_MANIFEST_MOD=""
  fi
}

# ---------- Baseline obligatoire (INST-02a) ----------
# Un module module.json avec "mandatory": true est un INVARIANT du lab (aujourd'hui : conductor,
# le socle de gouvernance, et consolidator, le socle de mémoire). Data-driven, AUCUN nom de module
# en dur — la liste sort des manifestes présents dans le cache.
module_is_mandatory() {
  local mod="$1"
  local mj="$CACHE_DIR/$mod/module.json"
  [ -f "$mj" ] || return 1
  grep -Eq '"mandatory"[[:space:]]*:[[:space:]]*true' "$mj"
}

# ensure_mandatory_baseline : garantit que tout module `mandatory` est présent dans le lab.
# Corrige la lacune où `update --all` n'itère que sur le registre : un module mandatory publié
# APRÈS la config d'un lab (ex. conductor arrivé en v2.7.0) n'y atterrissait jamais — donc ni ses
# scripts ni ses hooks (bandeau de mise à jour). Installe la fermeture transitive des manquants.
ensure_mandatory_baseline() {
  require_cache
  local mod m
  for mod in $(list_available_modules); do
    module_is_mandatory "$mod" || continue
    [ "$(module_version_installed "$mod")" = "—" ] || continue
    log "Baseline (INST-02a) : module obligatoire '$mod' absent du lab → installation"
    while IFS= read -r m; do
      m="${m%$'\r'}"   # ceinture ADR-054 : jamais de nom de module \r-suffixé (résolveur sous jq Windows)
      [ -n "$m" ] || continue
      [ "$(module_version_installed "$m")" = "—" ] && install_module "$m"
    done < <(resolve_closure "$mod")
  done
}

# ---------- Modules retirés (convergence, CONS-01) ----------
# Un module supprimé du parc (ex. feature-dev-gates, fusionné dans software-architecture) laisse des
# artefacts ORPHELINS dans les labs qui l'avaient installé. uninstall_module lit les artefacts DEPUIS
# le cache — absent pour un module retiré — donc le nettoyage s'appuie sur un manifeste EN DUR :
# _internal/retired-modules.txt (format `module:artefact` relatif à TARGET_ROOT, une ligne/artefact ;
# `#` = commentaire). Idempotent : ne retire que ce qui existe encore. Appelé à `update --all`.
find_retired_manifest() {
  local c
  c="$CACHE_DIR/_internal/retired-modules.txt"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/retired-modules.txt"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

cleanup_retired_modules() {
  local manifest
  manifest="$(find_retired_manifest)"
  [ -n "$manifest" ] || return 0
  local line mod artifact target in_registry
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    mod="${line%%:*}"
    artifact="${line#*:}"
    [ -n "$mod" ] && [ -n "$artifact" ] || continue
    target="$TARGET_ROOT/$artifact"
    in_registry="no"
    [ "$(module_version_installed "$mod")" = "—" ] || in_registry="yes"
    # Rien à faire si ni artefact orphelin ni entrée de registre pour ce module.
    if [ ! -e "$target" ] && [ "$in_registry" = "no" ]; then
      continue
    fi
    log "Module retiré '$mod' détecté dans ce lab → nettoyage (convergence)"
    # Site #5 (31-03) : annonce AVANT le rm -rf existant (verbe -, no-op sur le manifeste
    # aujourd'hui — vf_declare_write ne consigne que le verbe +, D-31-02).
    vf_declare_write - "$target"
    if ! vf_dry_run; then
      [ -e "$target" ] && rm -rf "$target" && log "  removed $target"
      [ "$in_registry" = "yes" ] && mark_uninstalled "$mod"
    fi
  done < "$manifest"
}

# ---------- Install ----------
install_module() {
  local mod="$1"
  require_cache

  local module_dir="$CACHE_DIR/$mod"
  [ -d "$module_dir" ] || err "Module $mod introuvable dans $CACHE_DIR"

  vf_manifest_reset "$mod"

  local version
  version=$(module_version_available "$mod")
  log "Installation $mod $version (scope=$VF_SCOPE → $TARGET_ROOT)..."

  # Lib de portabilité (contrat PR #29, D-04) : posée une fois par exécution, avant le traitement
  # du module — idempotent au sein du même processus (VF_ENGINE_LIB_COPIED), donc sans coût
  # supplémentaire réel sur une boucle `install --all`/`--with-deps`.
  copy_engine_lib

  # Backup if existing install
  local installed
  installed=$(module_version_installed "$mod")
  if [ "$installed" != "—" ]; then
    log "  Module déjà installé ($installed). Backup avant overwrite..."
    backup_module "$mod"
  fi

  # Type 1 — Single-skill module : SKILL.md at module root
  if [ -f "$module_dir/SKILL.md" ]; then
    vf_place_file "$module_dir/SKILL.md" "$TARGET_ROOT/skills/$mod/SKILL.md"
    log "  copied SKILL.md → $TARGET_ROOT/skills/$mod/"
  fi

  # Type 2 — Multi-skills module : skills/<name>/SKILL.md (e.g., skill-creator with 2 nested skills)
  # Site #6 (31-03) : cp -r d'un répertoire réel → vf_place_tree (grain fichier, D-31-02).
  if [ -d "$module_dir/skills" ]; then
    for skill_dir in "$module_dir/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      vf_place_tree "$skill_dir" "$TARGET_ROOT/skills/$skill_name"
      log "  copied nested skill → $TARGET_ROOT/skills/$skill_name/"
    done
  fi

  # Type 3 — Agent module : AGENT.md → $TARGET_ROOT/agents/<mod>.md
  # Site #7 (31-03) : cp fichier unique → vf_place_file.
  if [ -f "$module_dir/AGENT.md" ]; then
    vf_place_file "$module_dir/AGENT.md" "$TARGET_ROOT/agents/${mod}.md"
    log "  copied AGENT.md → $TARGET_ROOT/agents/${mod}.md"
  fi

  # Type 3b — Multi-agents module : agents/<name>.md → $TARGET_ROOT/agents/<name>.md (chacun)
  # Symétrique du multi-skills (skills/<name>/). Un module peut livrer plusieurs agents.
  # Site #8 (31-03) : cp par fichier dans la boucle existante → vf_place_file.
  if [ -d "$module_dir/agents" ]; then
    for agent_md in "$module_dir/agents/"*.md; do
      [ -f "$agent_md" ] || continue
      vf_place_file "$agent_md" "$TARGET_ROOT/agents/$(basename "$agent_md")"
      log "  copied agent → $TARGET_ROOT/agents/$(basename "$agent_md")"
    done
  fi

  # Type 4 — Doc-only module : content/ → docs/<mod>/
  # EXCEPTION scope : la doc reste relative au cwd PROJET (ce n'est pas du .claude),
  # donc PAS rebasée sur TARGET_ROOT même en scope user.
  # Site #9 (31-03) : vf_place_tree ANNONCÉ mais `vf_rel_to_target` échoue (hors TARGET_ROOT) —
  # vf_record s'abstient donc lui-même de toute consignation. C'est l'asymétrie VOULUE de
  # D-31-03 : présent au plan --dry-run (31-04), absent du manifeste — jamais un oubli.
  if [ -d "$module_dir/content" ]; then
    local doc_target="docs/$mod"
    vf_place_tree "$module_dir/content" "$doc_target"
    log "  copied content/ → $doc_target/ (doc module, hors TARGET_ROOT)"
  fi

  # Type 5 — Rules : rules/*.md → $TARGET_ROOT/rules/
  # Deux régimes selon le frontmatter : AVEC `paths:` → chargée à la lecture d'un fichier
  # correspondant (auto-scopée, Tier 2) ; SANS `paths:` → chargée inconditionnellement au
  # lancement, à la priorité de CLAUDE.md (globale, Tier 1). Voir patterns/05-regles.md.
  # Site #10 (31-03) : glob de fichiers, pas un répertoire entier — grain fichier exigé par
  # D-31-02, boucle avec garde d'existence (le module peut n'avoir aucun rules/*.md).
  if [ -d "$module_dir/rules" ]; then
    vf_dry_run || mkdir -p "$TARGET_ROOT/rules"
    # B2 (revue 31-03, D-31-13) : avant migration, `cp … 2>/dev/null || true`. L'appel nu au
    # helper, dernière commande de la boucle, avorterait désormais tout le script sur un seul
    # fichier illisible sous `set -e`. Tolérance restaurée EXPLICITEMENT (jamais un `|| true`
    # muet, contrat Phase 30 : 0 = silence).
    for f in "$module_dir/rules/"*.md; do
      [ -f "$f" ] || continue
      vf_place_file "$f" "$TARGET_ROOT/rules/$(basename "$f")" || {
        log "  copie dégradée : $TARGET_ROOT/rules/$(basename "$f") (pose en échec)"
        VF_DEGRADED_COPIES_COUNT=$((VF_DEGRADED_COPIES_COUNT + 1))
      }
    done
    log "  copied rules/ → $TARGET_ROOT/rules/"
  fi

  # References folder at module root (companion to root SKILL.md)
  # Site #11 (31-03) : cp -r d'un répertoire réel → vf_place_tree.
  if [ -d "$module_dir/references" ] && [ -f "$module_dir/SKILL.md" ]; then
    vf_place_tree "$module_dir/references" "$TARGET_ROOT/skills/$mod/references"
    log "  copied references/ → $TARGET_ROOT/skills/$mod/references/"
  fi

  # References folder for AGENT modules (D7) : un module agent (AGENT.md ou agents/ sans SKILL.md
  # racine) embarque ses references sous $TARGET_ROOT/agents/<mod>-references/ (chargées on-demand).
  # Site #12 (31-03) : cp -r d'un répertoire réel → vf_place_tree.
  if [ -d "$module_dir/references" ] && { [ -f "$module_dir/AGENT.md" ] || [ -d "$module_dir/agents" ]; } && [ ! -f "$module_dir/SKILL.md" ]; then
    vf_place_tree "$module_dir/references" "$TARGET_ROOT/agents/${mod}-references"
    log "  copied references/ → $TARGET_ROOT/agents/${mod}-references/"
  fi

  # Config folder at module root (companion to root SKILL.md) : templates de config projet.
  # Posé sous le dossier skill du module ; l'utilisateur copie le .example.json vers son projet.
  # Site #13 (31-03) : cp -r d'un répertoire réel → vf_place_tree.
  if [ -d "$module_dir/config" ] && [ -f "$module_dir/SKILL.md" ]; then
    vf_place_tree "$module_dir/config" "$TARGET_ROOT/skills/$mod/config"
    log "  copied config/ → $TARGET_ROOT/skills/$mod/config/"
  fi

  # Scripts (top-level + tests subdir) : shell (.sh) et Node (.mjs/.js).
  copy_module_scripts "$mod"

  # Hook post-install (IDX-02 / D7) : si le module fournit build-gsd-index.sh, régénérer
  # l'index factuel in-place dans le dossier references agent. Best-effort : ne JAMAIS
  # faire échouer l'install si GSD est absent (l'index sera régénéré plus tard).
  if [ -f "$module_dir/scripts/build-gsd-index.sh" ]; then
    if vf_dry_run; then
      # 31-04 (piège de garde, D-31-04) : la garde DESTINATION [ -f "$TARGET_ROOT/scripts/…" ]
      # serait FAUSSE sur un lab vierge en dry-run (copy_module_scripts, qui pose ce script,
      # est neutralisée) alors qu'elle sera VRAIE à la pose réelle — un plan qui la garderait
      # tairait une écriture que la pose fait. Garde basculée côté SOURCE (déjà vérifiée
      # ci-dessus) ; la destination est considérée PLANIFIÉE, jamais lue sur disque. Régime A
      # (D-31-04) : sortie prédite exactement, sous-processus NON appelé.
      vf_declare_write + "$TARGET_ROOT/agents/${mod}-references/gsd-skills-index.md"
    elif [ -f "$TARGET_ROOT/scripts/build-gsd-index.sh" ]; then
      if VF_INDEX_OUT="$TARGET_ROOT/agents/${mod}-references/gsd-skills-index.md" \
         bash "$TARGET_ROOT/scripts/build-gsd-index.sh" >/dev/null 2>&1; then
        log "  index régénéré → $TARGET_ROOT/agents/${mod}-references/gsd-skills-index.md"
        # Site #14 (31-03) : régime A (D-31-04) — sortie prédite exactement. Annoncée seulement
        # au SUCCÈS (le fichier existe réellement).
        vf_declare_write + "$TARGET_ROOT/agents/${mod}-references/gsd-skills-index.md"
      else
        log "  (index non régénéré — GSD absent, best-effort)"
      fi
    fi
  fi

  # Hook post-install (IDX-02 / D7 / D-07) : second générateur, STRICTEMENT symétrique du premier
  # — table des capabilities par point de hook du moteur. Volontairement NON fusionné avec l'appel
  # ci-dessus en boucle générique : le premier est stabilisé depuis la Phase 1, et le refactorer
  # élargirait le périmètre à un fichier d'engine partagé par tous les modules, sans bénéfice.
  # Best-effort de la même façon : un moteur GSD absent au moment de l'install DÉGRADE (une ligne
  # de journal), il n'ampute jamais l'install d'un module.
  if [ -f "$module_dir/scripts/build-gsd-capabilities-index.sh" ]; then
    if vf_dry_run; then
      # 31-04 : même piège de garde et même bascule côté SOURCE que le générateur d'index
      # jumeau ci-dessus.
      vf_declare_write + "$TARGET_ROOT/agents/${mod}-references/gsd-capabilities-index.md"
    elif [ -f "$TARGET_ROOT/scripts/build-gsd-capabilities-index.sh" ]; then
      if VF_CAPS_INDEX_OUT="$TARGET_ROOT/agents/${mod}-references/gsd-capabilities-index.md" \
         bash "$TARGET_ROOT/scripts/build-gsd-capabilities-index.sh" >/dev/null 2>&1; then
        log "  index capabilities régénéré → $TARGET_ROOT/agents/${mod}-references/gsd-capabilities-index.md"
        # Site #15 (31-03), symétrique du #14 — régime A (D-31-04).
        vf_declare_write + "$TARGET_ROOT/agents/${mod}-references/gsd-capabilities-index.md"
      else
        log "  (index capabilities non régénéré — moteur GSD absent, best-effort)"
      fi
    fi
  fi

  # Hook post-install (D-03a, quick 260810-fh3) : troisième hook nommé, STRICTEMENT symétrique de
  # ses deux jumeaux ci-dessus (build-gsd-index.sh / build-gsd-capabilities-index.sh) — donc PAS de
  # refactoring en boucle générique (même motif que le commentaire du second hook : le premier est
  # stabilisé depuis la Phase 1, généraliser élargirait le périmètre à un fichier d'engine partagé
  # par tous les modules, sans bénéfice). Ce hook ne doit JAMAIS amputer l'install d'un module
  # (D-03a) : une chaîne d'outils design absente DÉGRADE (une ligne de journal), elle ne casse rien.
  # VF_SCOPE est HÉRITÉ de l'export de tête de ce script (ligne ~78) — rien à passer explicitement.
  #
  # `--quiet` SANS `2>&1` — et c'est le point entier du hook : le script parle sur stderr, ses
  # lignes de routine sont supprimées par --quiet, mais ses ANOMALIES (plugin absent ou désactivé,
  # geste réellement exécuté, étape manuelle quand l'auto-install n'a pas pu aboutir) doivent
  # traverser jusqu'au journal de l'install. Avaler stderr ici rejouerait, un cran plus loin, la
  # dégradation silencieuse que ce hook existe pour fermer. Seul stdout part au trou (le script
  # n'y écrit rien — garde de forme contre une future régression).
  if [ -f "$module_dir/scripts/ensure-design-deps.sh" ]; then
    if vf_dry_run; then
      # 31-04 : même piège de garde que les deux générateurs d'index ci-dessus, côté régime C
      # (D-31-04) cette fois — effet annoncé, non énuméré, sous-processus NON appelé.
      vf_declare_write "~" "$TARGET_ROOT/scripts" "effet de ensure-design-deps.sh, contenu non énuméré"
    elif [ -f "$TARGET_ROOT/scripts/ensure-design-deps.sh" ]; then
      if bash "$TARGET_ROOT/scripts/ensure-design-deps.sh" --quiet >/dev/null; then
        log "  chaîne d'outils design vérifiée/corrigée → ensure-design-deps.sh"
        # Site #17 (31-03) : régime C (D-31-04) — effet annoncé, non énuméré. Honnête sur sa
        # propre limite (le script peut avoir touché divers fichiers sous scripts/, non listés).
        vf_declare_write "~" "$TARGET_ROOT/scripts" "effet de ensure-design-deps.sh, contenu non énuméré"
      else
        log "  (chaîne d'outils design non vérifiée — best-effort, voir ensure-design-deps.sh)"
      fi
    fi
  fi

  # Hook post-install (mémoire) : quatrième hook nommé, même patron que ses trois jumeaux ci-dessus
  # — donc PAS de refactoring en boucle générique (cf. le commentaire du second hook). Instancie les
  # registres canoniques depuis les gabarits du module. Sans lui, `consolidator` s'installait entier
  # mais posait ses gabarits sans jamais les instancier : `.claude/memory/` n'existait pas et le lab
  # échouait son propre gate mémoire (mesuré 2026-08-15, cf. en-tête de seed-registres.sh).
  #
  # Best-effort de la même façon : le code retour est IGNORÉ, une mémoire non instanciée DÉGRADE
  # (une ligne de journal), elle n'ampute jamais l'install. Le script est non destructif et
  # idempotent — il ne sait que créer ce qui manque —, ce qui le rend sûr à rejouer ici à chaque
  # install ET dans sync_module_governance à chaque update.
  #
  # `--quiet` SANS `2>&1`, même raison que le hook design : les lignes de routine sont supprimées,
  # mais les anomalies (gabarits introuvables, création impossible) doivent traverser jusqu'au
  # journal — les avaler rejouerait la dégradation silencieuse que ce hook existe pour fermer.
  seed_module_registres "$mod"

  # Commande d'incarnation (ADR-042) : tout agent posé devient invocable nativement via `/<mod>`
  # dans la fenêtre principale. Après la copie des scripts ci-dessus, le générateur est dispo.
  if [ -f "$module_dir/AGENT.md" ]; then
    generate_agent_command_for "$mod"
  fi

  # Injection MCP dérivée du lab (ADR-051) : si ce module a posé des agents, injecter dans les
  # exécutants flaggés (vf-mcp-consumer) les serveurs MCP que le lab déclare dans ./.mcp.json.
  # Le balayage est filtré par le flag → les agents planif/revue/audit restent inchangés.
  if [ -f "$module_dir/AGENT.md" ] || [ -d "$module_dir/agents" ]; then
    inject_lab_mcp_into_agents
  fi

  # Hooks de gouvernance (ADR-043) : fragment hooks/hooks.json → mergé dans settings.json.
  merge_module_hooks "$mod"

  # SCOPE-04 : en scope local seulement, ajouter les chemins installés au ./.gitignore.
  gitignore_add_paths "$mod"

  vf_manifest_flush

  mark_installed "$mod" "$version"
  # Compte rendu de fin de pose (D-31-11 point 4) : accumulé par vf_note_degraded_copy et par le
  # garde du trou de silence de vf_place_tree pendant la pose ci-dessus — aux côtés de la ligne de
  # succès existante, jamais à sa place (la pose n'échoue pas sur une copie dégradée).
  if [ "$VF_DEGRADED_COPIES_COUNT" -gt 0 ]; then
    log "  ⚠ $VF_DEGRADED_COPIES_COUNT copie(s) dégradée(s) détectée(s) pendant la pose (voir ci-dessus)"
  fi
  log "✓ $mod $version installé"
}

# ---------- Backup / Rollback ----------
backup_module() {
  local mod="$1"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local bdir="$BACKUP_DIR/$mod-$ts"
  if vf_dry_run; then
    vf_declare_write + "$bdir"
    return 0
  fi
  mkdir -p "$bdir"
  # Site #20 (31-03) : les cp/cp -r existants restent INTENTIONNELLEMENT bruts — copies de
  # sauvegarde vers .backups/**, exclues du manifeste par D-31-03 (le contenu d'un backup n'est
  # pas un artefact de pose). No-op silencieux si appelée hors cycle (uninstall_module n'ouvre
  # pas de cycle manifeste). Mi1 (revue 31-03) : annonce déplacée en FIN de fonction, après les
  # copies réelles — patron `vf_place_file` (D-31-01), jamais avant l'écriture.
  [ -d "$TARGET_ROOT/skills/$mod" ] && cp -r "$TARGET_ROOT/skills/$mod" "$bdir/skills"
  # Agent module : AGENT.md installé + son dossier references (D7)
  [ -f "$TARGET_ROOT/agents/${mod}.md" ] && { mkdir -p "$bdir/agents"; cp "$TARGET_ROOT/agents/${mod}.md" "$bdir/agents/"; }
  [ -d "$TARGET_ROOT/agents/${mod}-references" ] && cp -r "$TARGET_ROOT/agents/${mod}-references" "$bdir/agent-references"
  # Scripts (les scripts du module sont mélangés avec les autres — backup uniquement les nommés dans le module)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    mkdir -p "$bdir/scripts"
    for f in "$CACHE_DIR/$mod/scripts/"*.sh; do
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/scripts/$name" ] && cp "$TARGET_ROOT/scripts/$name" "$bdir/scripts/"
    done
  fi
  vf_declare_write + "$bdir"
  log "  backup → $bdir"
}

rollback_module() {
  # 31-03 (D-31-09) : non migré vers le socle manifeste — restaure DEPUIS un backup, ce n'est
  # pas une pose de module (rien à consigner) ; --dry-run y est refusé (D-31-06) ; hors des
  # 4 critères de succès de la phase.
  local mod="$1"
  # Find latest backup
  local latest
  latest=$(ls -1dt "$BACKUP_DIR/$mod"-* 2>/dev/null | head -1)
  [ -z "$latest" ] && err "Aucun backup trouvé pour $mod dans $BACKUP_DIR"

  log "Rollback $mod depuis $latest..."
  if [ -d "$latest/skills" ]; then
    rm -rf "$TARGET_ROOT/skills/$mod"
    cp -r "$latest/skills" "$TARGET_ROOT/skills/$mod"
    log "  restored $TARGET_ROOT/skills/$mod"
  fi
  if [ -d "$latest/scripts" ]; then
    for f in "$latest/scripts/"*; do
      [ -f "$f" ] && cp "$f" "$TARGET_ROOT/scripts/" && chmod +x "$TARGET_ROOT/scripts/$(basename "$f")"
    done
    log "  restored scripts"
  fi
  log "✓ $mod rollback OK"
}

# ---------- Uninstall ----------
uninstall_module() {
  # 31-03 (D-31-09) : non migré vers le socle manifeste — le passage au manifeste est planifié
  # comme dernière vague EXPLICITEMENT ABANDONNABLE (31-07 — Mi3, revue 31-03 : ce commentaire
  # citait à tort 31-08, qui est la réponse à l'issue #20) si le plan de la phase enfle. Le
  # migrer ici en ferait un lot non abandonnable par accident.
  local mod="$1"
  log "Désinstallation $mod (scope=$VF_SCOPE → $TARGET_ROOT)..."
  backup_module "$mod"

  # Remove skill dir (Type 1 — skill mono)
  if [ -d "$TARGET_ROOT/skills/$mod" ]; then
    rm -rf "$TARGET_ROOT/skills/$mod"
    log "  removed $TARGET_ROOT/skills/$mod"
  fi

  # Remove nested skills (Type 2 — skills/<name>/, symétrique de l'install). On ne retire QUE les
  # skills que CE module possède (lus depuis le cache), jamais celui d'un autre module.
  if [ -d "$CACHE_DIR/$mod/skills" ]; then
    for skill_dir in "$CACHE_DIR/$mod/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      if [ -d "$TARGET_ROOT/skills/$skill_name" ]; then
        rm -rf "$TARGET_ROOT/skills/$skill_name"
        log "  removed $TARGET_ROOT/skills/$skill_name"
      fi
    done
  fi

  # Remove agent module (AGENT.md installé + dossier references D7)
  if [ -f "$TARGET_ROOT/agents/${mod}.md" ]; then
    rm -f "$TARGET_ROOT/agents/${mod}.md"
    log "  removed $TARGET_ROOT/agents/${mod}.md"
  fi
  # Remove multi-agents (only those owned by this module)
  if [ -d "$CACHE_DIR/$mod/agents" ]; then
    for f in "$CACHE_DIR/$mod/agents/"*.md; do
      [ -f "$f" ] || continue
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/agents/$name" ] && rm "$TARGET_ROOT/agents/$name" && log "  removed $TARGET_ROOT/agents/$name"
    done
  fi
  if [ -d "$TARGET_ROOT/agents/${mod}-references" ]; then
    rm -rf "$TARGET_ROOT/agents/${mod}-references"
    log "  removed $TARGET_ROOT/agents/${mod}-references"
  fi

  # Commande d'incarnation générée (ADR-042) : la retirer avec l'agent.
  if [ -f "$TARGET_ROOT/commands/${mod}.md" ]; then
    rm -f "$TARGET_ROOT/commands/${mod}.md"
    log "  removed $TARGET_ROOT/commands/${mod}.md"
  fi

  # Remove scripts (only those owned by this module : shell + Node)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    for f in "$CACHE_DIR/$mod/scripts/"*.sh "$CACHE_DIR/$mod/scripts/"*.mjs "$CACHE_DIR/$mod/scripts/"*.js; do
      [ -f "$f" ] || continue
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/scripts/$name" ] && rm "$TARGET_ROOT/scripts/$name" && log "  removed $TARGET_ROOT/scripts/$name"
    done
    # Miroir de copy_module_scripts : retirer aussi tests/ + fixtures/ de CE module, puis élaguer
    # les dossiers s'ils sont vides. rmdir (jamais rm -rf) car scripts/ et tests/ sont partagés.
    if [ -d "$CACHE_DIR/$mod/scripts/tests" ]; then
      for f in "$CACHE_DIR/$mod/scripts/tests/"*.sh; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        [ -f "$TARGET_ROOT/scripts/tests/$name" ] && rm "$TARGET_ROOT/scripts/tests/$name" && log "  removed $TARGET_ROOT/scripts/tests/$name"
      done
      for f in "$CACHE_DIR/$mod/scripts/tests/fixtures/"*; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        [ -e "$TARGET_ROOT/scripts/tests/fixtures/$name" ] && rm -rf "$TARGET_ROOT/scripts/tests/fixtures/$name" && log "  removed $TARGET_ROOT/scripts/tests/fixtures/$name"
      done
      rmdir "$TARGET_ROOT/scripts/tests/fixtures" 2>/dev/null || true
      rmdir "$TARGET_ROOT/scripts/tests" 2>/dev/null || true
    fi
    rmdir "$TARGET_ROOT/scripts" 2>/dev/null || true
  fi

  # Remove rules (only those owned by this module)
  if [ -d "$CACHE_DIR/$mod/rules" ]; then
    for f in "$CACHE_DIR/$mod/rules/"*.md; do
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/rules/$name" ] && rm "$TARGET_ROOT/rules/$name" && log "  removed $TARGET_ROOT/rules/$name"
    done
  fi

  # Hooks de gouvernance (ADR-043) : retirer les entrées du module de settings.json.
  remove_module_hooks "$mod"

  # M6 (revue 31-03) : sans ce retrait, le manifeste .vibeflow-manifest-<mod> survit à la
  # désinstallation — un module FANTÔME que le commentaire de vf_manifest_reset (~276-278)
  # annonce comme découvert PAR GLOB en 31-05/31-07. rm -f, jamais fatal (uninstall_module
  # n'ouvre pas de cycle manifeste, D-31-09 — rien à consigner sur son propre retrait).
  local manifest_file
  manifest_file="$(vf_manifest_path "$mod")"
  [ -f "$manifest_file" ] && rm -f "$manifest_file" && log "  removed $manifest_file"

  mark_uninstalled "$mod"
  log "✓ $mod désinstallé"
}

# ---------- Status ----------
show_status() {
  require_cache
  printf "%-30s %-15s %-15s %s\n" "Module" "Installed" "Available" "Status"
  printf "%-30s %-15s %-15s %s\n" "------" "---------" "---------" "------"
  for mod in $(list_available_modules); do
    installed=$(module_version_installed "$mod")
    available=$(module_version_available "$mod")
    if [ "$installed" = "—" ]; then
      status="Not installed"
    elif [ "$installed" = "$available" ]; then
      status="Up to date"
    else
      status="Update available ($installed → $available)"
    fi
    printf "%-30s %-15s %-15s %s\n" "$mod" "$installed" "$available" "$status"
  done
}

# ---------- Convergence à l'update (MANI-03, D-31-07) ----------
# Le doute ne supprime jamais. Séquence imposée dans update_module : snapshot de l'ANCIEN
# manifeste AVANT install_module (qui flushe le NOUVEAU à sa dernière étape et écrase donc
# l'ancien), puis apply APRÈS. Si install_module échoue en cours de route, `set -e` interrompt
# avant vf_converge_apply : l'ancien manifeste reste en place (jamais flushé), l'update suivant
# reconverge — propriété obtenue par l'ORDRE des gestes, pas par une transaction.
#
# sync_module_governance (chemin « version inchangée ») N'APPELLE JAMAIS ces deux fonctions : voir
# le commentaire sur place dans sync_module_governance (D-31-14) pour le motif.
VF_CONVERGE_MOD=""
VF_CONVERGE_VERDICT=""
VF_OLD_MANIFEST=""
# Accumulateur MIROIR du nouveau manifeste en dry-run (voir vf_declare_write) — install_module ne
# flushe RIEN en dry-run (D-31-06) : relire $(vf_manifest_path "$mod") après coup rendrait
# l'ANCIEN, pas le nouveau (même fichier, jamais touché). Peuplé par le MÊME chemin de code que la
# pose réelle (verbe +, D-31-01), jamais un second calcul séparé.
VF_CONVERGE_DRYSET=""

# vf_converge_snapshot <mod> — capture le verdict de l'ANCIEN manifeste (0 valide / 1 imparsable /
# 2 absent) via vf_manifest_read, qui logge déjà lui-même le motif d'un refus. En pose RÉELLE, si
# le verdict est valide, le fichier manifeste est COPIÉ tel quel (cp, jamais reconstruit depuis du
# texte capturé — un manifeste valide mais VIDE existe, D-31-01, et une reconstruction par
# printf/command-substitution le corromprait en une ligne vide unique) vers un temporaire dont le
# chemin est mémorisé dans VF_OLD_MANIFEST. En dry-run, RIEN n'est copié (D-31-06) : install_module
# ne flushera rien, le manifeste sur disque reste l'ANCIEN jusqu'à vf_converge_apply — seul le
# verdict est mémorisé ici, et l'accumulateur MIROIR du nouveau (VF_CONVERGE_DRYSET) est ouvert :
# install_module (appelé juste après, dans update_module) le peuple via vf_declare_write pendant
# son propre passage dry-run.
vf_converge_snapshot() {
  local mod="$1"
  local rc=0 file
  VF_CONVERGE_MOD="$mod"
  VF_OLD_MANIFEST=""
  VF_CONVERGE_DRYSET=""
  file="$(vf_manifest_path "$mod")"
  vf_manifest_read "$mod" >/dev/null || rc=$?
  VF_CONVERGE_VERDICT="$rc"
  if vf_dry_run; then
    VF_CONVERGE_DRYSET="$(mktemp)"
    : > "$VF_CONVERGE_DRYSET"
    return 0
  fi
  if [ "$rc" -eq 0 ]; then
    VF_OLD_MANIFEST="$(mktemp)"
    # Finding E (correction ciblée) : `cp` nu en position finale de ce bloc `if` — sous
    # `set -euo pipefail`, une panne d'E/S (permission retirée entre le `cat` de vf_manifest_read
    # ci-dessus et cet appel) ferait avorter TOUT le script appelant (D-31-13). Le fichier a déjà
    # été jugé VALIDE et LISIBLE l'instant d'avant : une panne ici est une régression de la
    # ressource, pas du contenu — même contrat qu'un manifeste imparsable : abstention de la
    # convergence, jamais un crash du process.
    if ! cp "$file" "$VF_OLD_MANIFEST" 2>/dev/null; then
      log "  manifeste de $mod illisible (permission) au snapshot — convergence abstenue"
      rm -f "$VF_OLD_MANIFEST"
      VF_OLD_MANIFEST=""
      VF_CONVERGE_VERDICT=1
    fi
  fi
}

# vf_converge_apply <mod> — diff ancien/nouveau, SIX conditions cumulatives (D-31-07), backup
# AVANT suppression, `rm -f` + `rmdir` d'élagage non récursif, liste rendue à l'utilisateur.
# Ne fait RIEN (return 0) si le verdict du snapshot n'était pas valide : « absent » (2, repli
# gracieux) et « imparsable » (1, abstention) ont DÉJÀ été loggués par vf_manifest_read côté
# snapshot — une seconde ligne redirait la même chose.
vf_converge_apply() {
  local mod="$1"
  if [ "$VF_CONVERGE_MOD" != "$mod" ] || [ "$VF_CONVERGE_VERDICT" != "0" ]; then
    [ -n "$VF_OLD_MANIFEST" ] && rm -f "$VF_OLD_MANIFEST"
    [ -n "$VF_CONVERGE_DRYSET" ] && rm -f "$VF_CONVERGE_DRYSET"
    VF_CONVERGE_MOD=""; VF_CONVERGE_VERDICT=""; VF_OLD_MANIFEST=""; VF_CONVERGE_DRYSET=""
    return 0
  fi

  local new_sorted old_source
  new_sorted="$(mktemp)"

  if vf_dry_run; then
    # Dry-run (D-31-06) : install_module n'a rien flushé — le NOUVEAU manifeste qu'aurait produit
    # la pose réelle vient de l'accumulateur MIROIR (VF_CONVERGE_DRYSET, peuplé par
    # vf_declare_write pendant l'appel d'install_module qui précède immédiatement dans
    # update_module), jamais d'une relecture de $(vf_manifest_path "$mod") — ce fichier n'a pas
    # bougé, ce serait relire l'ANCIEN sous le nom du nouveau. L'ANCIEN, lui, EST lu EN PLACE :
    # install_module n'a rien flushé, le fichier sur disque reste l'ancien.
    LC_ALL=C sort -u "$VF_CONVERGE_DRYSET" > "$new_sorted"
    old_source="$(vf_manifest_path "$mod")"
  else
    # NOUVEAU manifeste, relu MAINTENANT (après install_module, pose réelle) — un référentiel
    # douteux ne sert jamais de base à une suppression, dans un sens comme dans l'autre.
    local new_rc=0 new_content
    new_content="$(vf_manifest_read "$mod")" || new_rc=$?
    if [ "$new_rc" -ne 0 ]; then
      log "  convergence de $mod : nouveau manifeste inutilisable — abstention (aucune suppression)"
      rm -f "$new_sorted"
      [ -n "$VF_OLD_MANIFEST" ] && rm -f "$VF_OLD_MANIFEST"
      VF_CONVERGE_MOD=""; VF_CONVERGE_VERDICT=""; VF_OLD_MANIFEST=""; VF_CONVERGE_DRYSET=""
      return 0
    fi
    printf '%s\n' "$new_content" | LC_ALL=C sort -u > "$new_sorted"
    old_source="$VF_OLD_MANIFEST"
  fi

  local ts bdir
  if ! vf_dry_run; then
    ts=$(date +%Y%m%d-%H%M%S)
    bdir="$BACKUP_DIR/$mod-$ts-removed"
  fi

  local rel full backup_dest
  local -a removed=() refused=()
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    # (a) présent dans l'ancien manifeste — par construction : on itère ses lignes.
    # (b) absent du nouveau manifeste — comparaison de LIGNE EXACTE, LC_ALL=C.
    LC_ALL=C grep -qxF "$rel" "$new_sorted" && continue
    full="$TARGET_ROOT/$rel"
    # (c) à (g) : socle FACTORISÉ dans vf_removable (31-07, D-31-09) — un seul jeu de garde-fous,
    # partagé avec uninstall_module, jamais recopié. Correctif de transparence (31-07) : un refus
    # d'une condition de SÛRETÉ (d/e/g — rare et anormal) est désormais NOMMÉ dans le compte rendu
    # de fin, au lieu d'être MUET comme avant ce lot (D-31-15 était corrigé mais invisible : rien
    # ne distinguait « rien à faire » de « refusé pour cause de sûreté »).
    if ! vf_removable "$rel"; then
      [ -n "$VF_REMOVABLE_REASON" ] && refused+=("$rel : $VF_REMOVABLE_REASON")
      continue
    fi

    if vf_dry_run; then
      vf_declare_write - "$full"
      continue
    fi

    backup_dest="$bdir/$rel"
    # Finding E (correction ciblée) : `mkdir -p` nu en position médiane d'une paire — jusqu'ici
    # SANS garde, alors que sa panne (permission sur $bdir) avorterait TOUT le script sous
    # `set -e`. Pire que les deux autres sites : l'abort surviendrait APRÈS le flush du NOUVEAU
    # manifeste par install_module (déjà exécuté avant cette boucle), donc un `update` suivant
    # rendrait « 0 chemin retiré » avec ce fichier resté sur disque — un ORPHELIN DÉFINITIF
    # (l'ancien manifeste qui le portait a déjà été écrasé). Abstention explicite, jamais un
    # crash : même contrat que l'échec de `cp` juste en dessous.
    if ! mkdir -p "$(dirname "$backup_dest")" 2>/dev/null; then
      log "  convergence de $mod : impossible de créer le dossier de backup pour $rel — NON supprimé (pas de suppression sans filet)"
      continue
    fi
    if cp "$full" "$backup_dest" 2>/dev/null; then
      rm -f "$full"
      # Élagage NON récursif, patron uninstall_module (rmdir sans -r sur un dossier PARTAGÉ) :
      # échec attendu (répertoire non vide) capturé EXPLICITEMENT (jamais `|| true`, D-31-13) —
      # rien à en faire, c'est le cas ordinaire, pas une anomalie à journaliser (D-31-14 : un
      # signal qui spamme cesse d'être lu).
      local prune_rc=0
      rmdir "$(dirname "$full")" 2>/dev/null || prune_rc=$?
      removed+=("$rel")
    else
      log "  convergence de $mod : backup en échec pour $rel — NON supprimé (pas de suppression sans filet)"
    fi
  done < "$old_source"

  if ! vf_dry_run; then
    log "  convergence de $mod : ${#removed[@]} chemin(s) retiré(s) (disparus du module, sauvegardés → $bdir)"
    if [ "${#removed[@]}" -gt 0 ]; then
      for rel in "${removed[@]}"; do
        log "    - $rel"
      done
    fi
    # Correctif de transparence (31-07) : distinct de « retiré » — un chemin REFUSÉ par une
    # condition de sûreté (d/e/g de vf_removable) ne l'a PAS été. Avant ce lot, ce cas était
    # MUET : un lab dont un ancêtre est symlinké voyait « 0 chemin(s) retiré(s) » sans jamais
    # savoir que la convergence y était partiellement inopérante (D-31-11/D-31-07 : ce qui refuse
    # doit le dire).
    log "  convergence de $mod : ${#refused[@]} chemin(s) refusé(s) (garde de sûreté déclenchée, aucune suppression)"
    if [ "${#refused[@]}" -gt 0 ]; then
      for rel in "${refused[@]}"; do
        log "    - $rel"
      done
    fi
  fi

  rm -f "$new_sorted"
  [ -n "$VF_OLD_MANIFEST" ] && rm -f "$VF_OLD_MANIFEST"
  [ -n "$VF_CONVERGE_DRYSET" ] && rm -f "$VF_CONVERGE_DRYSET"
  VF_CONVERGE_MOD=""; VF_CONVERGE_VERDICT=""; VF_OLD_MANIFEST=""; VF_CONVERGE_DRYSET=""
}

# ---------- Update ----------
update_module() {
  local mod="$1"
  require_cache
  local installed available
  installed=$(module_version_installed "$mod")
  available=$(module_version_available "$mod")

  if [ "$installed" = "—" ]; then
    log "$mod n'est pas installé. Use 'install' au lieu de 'update'."
    return 1
  fi

  if [ "$installed" = "$available" ]; then
    # Version inchangée : pas de re-copie complète, mais on RE-SYNCHRONISE la gouvernance
    # (scripts + hooks). Rend /vf-update auto-réparateur si un hooks.json a dérivé sans bump
    # de VERSION — idempotent, best-effort.
    log "$mod déjà à jour ($installed) — resync gouvernance (scripts + hooks)"
    sync_module_governance "$mod"
    return 0
  fi

  log "Update $mod : $installed → $available"
  # Convergence MANI-03 (D-31-07) : snapshot AVANT install_module (qui flushe le NOUVEAU manifeste
  # et écrase donc l'ancien), apply APRÈS. Si install_module échoue, `set -e` interrompt avant
  # vf_converge_apply : l'ancien manifeste reste en place, l'update suivant reconverge.
  vf_converge_snapshot "$mod"
  install_module "$mod"
  vf_converge_apply "$mod"
}

# ---------- Main ----------
[ "$#" -lt 1 ] && {
  grep '^# ' "$0" | sed 's/^# //'
  exit 0
}

cmd="$1"
arg="${2:-}"

case "$cmd" in
  install)
    if [ "$arg" = "--all" ]; then
      require_cache
      for m in $(list_available_modules); do install_module "$m"; done
    elif [ "$arg" = "--with-deps" ]; then
      # install --with-deps <mod> : installe la fermeture transitive (résolveur câblé).
      deps_target="${3:-}"
      [ -n "$deps_target" ] || err "Usage: install --with-deps <module>"
      require_cache
      while IFS= read -r m; do
        m="${m%$'\r'}"   # ceinture ADR-054 : jamais de nom de module \r-suffixé (résolveur sous jq Windows)
        [ -n "$m" ] && install_module "$m"
      done < <(resolve_closure "$deps_target")
    elif [ -n "$arg" ]; then
      install_module "$arg"
    else
      err "Usage: install <module> | install --with-deps <module> | install --all"
    fi
    ;;
  update)
    if [ "$arg" = "--all" ]; then
      require_cache
      # Convergence AVANT la boucle : désenregistrer + nettoyer les modules retirés du parc
      # (CONS-01). Sinon la boucle tenterait d'`update_module` un module absent du cache
      # (install_module → err → abort) avant d'atteindre le nettoyage.
      cleanup_retired_modules
      if [ -f "$INSTALLED_REGISTRY" ]; then
        while IFS='=' read -r mod ver; do
          [ -n "$mod" ] && update_module "$mod"
        done < "$INSTALLED_REGISTRY"
        # Lab initialisé : garantir la baseline obligatoire (INST-02a). Un module `mandatory`
        # publié après la config du lab (conductor en v2.7.0, consolidator en v1.9.0) est ainsi
        # rattrapé au lieu d'être ignoré à vie — c'est ce qui posait ses scripts + hooks manquants
        # (bandeau /vf-update pour conductor ; registres + guards mémoire pour consolidator).
        ensure_mandatory_baseline
      else
        log "Aucun module installé"
      fi
    elif [ -n "$arg" ]; then
      update_module "$arg"
    else
      err "Usage: update <module> | update --all"
    fi
    ;;
  uninstall)
    if [ "$arg" = "--all" ]; then
      # uninstall --all : retire TOUS les modules listés dans le registre.
      # On fige la liste AVANT la boucle : uninstall_module → mark_uninstalled réécrit le
      # registre à chaque itération, donc on itère sur un snapshot, pas sur le fichier muté.
      if [ -f "$INSTALLED_REGISTRY" ]; then
        _to_remove=()
        while IFS='=' read -r mod _ver; do
          [ -n "$mod" ] && _to_remove+=("$mod")
        done < "$INSTALLED_REGISTRY"
        if [ "${#_to_remove[@]}" -eq 0 ]; then
          log "Aucun module installé (registre vide) — rien à désinstaller."
        else
          for mod in "${_to_remove[@]}"; do uninstall_module "$mod"; done
          log "✓ ${#_to_remove[@]} module(s) désinstallé(s)"
        fi
      else
        log "Aucun module installé (pas de registre) — rien à désinstaller."
      fi
    elif [ -n "$arg" ]; then
      uninstall_module "$arg"
    else
      err "Usage: uninstall <module> | uninstall --all"
    fi
    ;;
  rollback)
    [ -n "$arg" ] || err "Usage: rollback <module>"
    rollback_module "$arg"
    ;;
  status)
    show_status
    ;;
  sync)
    # No-op explicite (SCOPE-02) : la source est le cache fourni, plus de sync git.
    log "source = cache fourni (VIBEFLOW_CACHE=$CACHE_DIR), plus de sync git"
    ;;
  *)
    grep '^# ' "$0" | sed 's/^# //'
    exit 1
    ;;
esac
