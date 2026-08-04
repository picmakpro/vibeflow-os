#!/usr/bin/env bash
# check-machine-paths.sh — Gate d'hygiène : aucun chemin absolu de MACHINE dans les fichiers versionnés.
#
# CE QUE CE GATE EXISTE POUR ARRÊTER, ET CE QU'IL N'EST PAS.
#
# Ce dépôt est public. Un chemin absolu du poste de son auteur (`/Users/<prénom>/…`, `/home/<login>/…`)
# écrit dans un fichier versionné n'est pas une fuite spectaculaire — le nom figure de toute façon dans
# l'auteur de chaque commit — mais c'est une ACCUMULATION : mesurée le 2026-08-04, elle touchait
# **19 fichiers suivis, dont 18 déjà publiés sur `origin/main`**, tous écrits sans intention par des
# artefacts de session (plans, résumés, études) qui recopient le chemin que l'outil leur a rendu.
# Le nettoyage a été fait une fois ; sans gate, il se refera indéfiniment. C'est le gate qui change
# la pente, pas le nettoyage.
#
# Le second dommage est plus concret que le premier : un chemin de machine dans un artefact versionné
# le rend NON REJOUABLE ailleurs. Les blocs `<automated>` des plans archivés en sont l'exemple — ils
# `cd` vers un chemin qui n'existe sur aucun autre poste. Relativiser, c'est aussi les réparer.
#
# CE QUI N'EST PAS UNE FAUTE, et pourquoi le gate doit savoir le dire.
# Un gate qu'on doit contourner tous les jours finit désarmé (c'est le motif qui a fait refuser
# `hooks.community` — ADR-067 : « une mesure de style, pas de conformité »). Trois échappatoires, dans
# cet ordre de préférence :
#   1. **Le segment de compte est un PLACEHOLDER** — `/Users/dev/…` (fixture amont
#      `plugin/_internal/tests/fixtures/gsd-core-settings.json`), `/home/runner/…` (GitHub Actions),
#      `user`, `username`, `utilisateur`, `you`, `me`, `moi`. Énumération FERMÉE, ci-dessous.
#   2. **Le segment n'est pas un identifiant** — `/Users/<user>/…`, `/Users/…/x` : la classe de
#      caractères reconnue est `[A-Za-z0-9._-]`, donc un chevron ou une ellipse ne matche pas du tout.
#      C'est la forme à préférer dans la doc utilisateur : elle dit « un compte quelconque » et se
#      lit mieux qu'un vrai nom.
#   3. **L'échappatoire explicite** — le marqueur `vf-allow-machine-path` sur la ligne. Réservé au
#      cas où le littéral EST le sujet (une suite de tests qui doit fabriquer un chemin fautif, une
#      sortie de commande citée verbatim qu'on ne veut pas maquiller). Explicite, greppable, et
#      lui-même sous test de mutation : la suite prouve qu'il supprime réellement le signal, et
#      qu'il ne le supprime QUE là où il est écrit.
#
# PÉRIMÈTRE : les fichiers SUIVIS par git (`git ls-files`), pas l'arbre de travail. Le défaut visé
# est de VERSIONNER un chemin de machine ; ce qui n'est pas versionné n'est pas publié. Aucun filtre
# d'extension : un filtre est un trou, et ce dépôt ne suit que du texte (868 fichiers au 2026-08-04 :
# md, sh, json, py, txt, yml, html, mjs). `LC_ALL=C` rend la lecture bytewise — un binaire futur
# traverse sans faire échouer awk sur un multi-octets invalide.
#
# PAS DE `grep` : le `grep` de certains runtimes de dev est proxifié et TRONQUE silencieusement
# (mesuré sur ce poste : 1 ligne rendue sur 91). Un gate qui compte sur un outil qui tronque rend
# un vert à vide. Tout le balayage passe par `awk`, qui lit les fichiers lui-même.
#
# CE GATE N'EST PAS DISTRIBUÉ AUX LABS : il vit dans `scripts/` (outillage du dépôt), pas dans
# `plugin/<module>/scripts/` (contenu posé chez l'utilisateur). Il garde l'hygiène de CE dépôt.
#
# Codes de sortie :
#   0 = aucun chemin de machine versionné
#   1 = au moins un chemin de machine versionné (liste sur stderr)
#   2 = NON VÉRIFIABLE — pas un dépôt git, ou univers vide. Jamais un vert : un gate qui n'a pas pu
#       regarder ne se replie pas sur « rien trouvé ».
#   64 = erreur d'usage
set -uo pipefail

# Racine dérivée de l'emplacement du script (scripts/ vit à la racine), PAS du cwd — même piège que
# check-version-sync.sh : `git rev-parse` depuis un autre dépôt résoudrait la mauvaise racine.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  cat <<'USAGE'
check-machine-paths.sh [--path <dir>]

  --path <dir>   Racine à balayer (défaut : la racine du dépôt qui contient ce script).
  -h, --help     Cette aide.

Sortie : 0 = propre · 1 = chemins de machine versionnés · 2 = non vérifiable · 64 = usage.
Échappatoire par ligne : marqueur `vf-allow-machine-path`.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --path) shift; [ $# -gt 0 ] || { echo "[check-machine-paths] --path attend une valeur" >&2; exit 64; }
            ROOT="$1" ;;
    --path=*) ROOT="${1#--path=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[check-machine-paths] argument inconnu : $1" >&2; usage >&2; exit 64 ;;
  esac
  shift
done

[ -d "$ROOT" ] || { echo "[check-machine-paths] racine introuvable : $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"

# Marqueur d'échappatoire. Défini une seule fois et passé à awk : le littéral n'apparaît donc qu'ici
# et dans l'aide ci-dessus — deux lignes que le gate saute par construction, ce qui est correct et
# sans conséquence (elles ne portent aucun chemin).
HATCH="vf-allow-machine-path"

# Énumération FERMÉE des segments de compte réputés placeholder. Encadrée d'espaces des deux côtés
# pour que la recherche soit un test d'appartenance exact et non un `index` sur un préfixe : sans
# les bordures, `dev` matcherait aussi `developpeur`, et un vrai compte nommé `me` passerait par
# `moi`. Toute extension de cette liste est une décision, pas un réflexe.
ALLOW=" dev user users username utilisateur you me moi runner home root "

if ! command -v git >/dev/null 2>&1; then
  echo "[check-machine-paths] git introuvable — univers des fichiers suivis inconnu, NON VÉRIFIABLE" >&2
  exit 2
fi
if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[check-machine-paths] $ROOT n'est pas un dépôt git — univers inconnu, NON VÉRIFIABLE" >&2
  exit 2
fi

TMP_LIST="$(mktemp)"
TMP_HITS="$(mktemp)"
trap 'rm -f "$TMP_LIST" "$TMP_HITS"' EXIT

git -C "$ROOT" ls-files -z > "$TMP_LIST" 2>/dev/null || true
# Comptage de l'univers AVANT tout verdict : un `ls-files` vide (dépôt fraîchement initialisé,
# sous-arbre sans fichier suivi) rendrait « 0 violation » et ce serait un vert à vide.
# Le décompte passe par `tr` et NON par `awk -v RS="\0"` : le awk de macOS ne prend pas un NUL
# comme séparateur d'enregistrement et rendait **1** là où l'univers en compte 868 — un compteur
# anti-vert-à-vide qui se trompe d'un facteur 800 ne garde plus rien.
UNIVERS="$(LC_ALL=C tr '\0' '\n' < "$TMP_LIST" | LC_ALL=C awk 'END { print NR+0 }')"
if [ "${UNIVERS:-0}" -eq 0 ]; then
  echo "[check-machine-paths] aucun fichier suivi sous $ROOT — cible vide, NON VÉRIFIABLE (jamais un vert)" >&2
  exit 2
fi

# Balayage. `xargs -0` (liste NUL-séparée, donc insensible aux espaces et aux retours à la ligne
# dans les noms) et `awk` qui ouvre les fichiers lui-même : FILENAME et FNR sont exacts, et xargs
# découpe les lots tout seul si l'univers dépasse la limite d'arguments.
( cd "$ROOT" && xargs -0 awk \
  -v HATCH="$HATCH" -v ALLOW="$ALLOW" '
  index($0, HATCH) > 0 { next }
  {
    rest = $0
    # Caractere qui precede `rest` dans la ligne initiale, reporte entre iterations : `rest` est
    # consomme au fur et a mesure et perd son contexte gauche.
    # (Commentaires sans apostrophe DELIBEREMENT : ce programme awk vit entre quotes simples, et
    #  une apostrophe francaise y refermerait la chaine — panne deja payee sur ce depot.)
    carry = ""
    while (match(rest, /\/(Users|home)\/[A-Za-z0-9._-]+/)) {
      prev = (RSTART > 1) ? substr(rest, RSTART - 1, 1) : carry
      hit  = substr(rest, RSTART, RLENGTH)
      rest = substr(rest, RSTART + RLENGTH)
      carry = substr(hit, length(hit), 1)
      # LE SEGMENT DOIT COMMENCER UN CHEMIN ABSOLU. `/Users/` ou `/home/` au MILIEU dun chemin
      # compose ne designe aucune machine : `$WORK/home/.claude/...` (fixture du plan 04-02) est un
      # sous-dossier nomme `home`, pas le `/home` du systeme. Faux positif MESURE (3 occurrences) au
      # premier run de ce gate. awk na pas de lookbehind : on regarde donc le caractere de gauche,
      # et on ecarte sil appartient a un chemin ou a une expansion de variable.
      if (prev != "" && prev ~ /[A-Za-z0-9._~$}\/-]/) continue
      n = split(hit, seg, "/")
      if (index(ALLOW, " " seg[n] " ") == 0) {
        printf "%s:%d: segment de compte « %s » dans « %s »\n", FILENAME, FNR, seg[n], hit
      }
    }
  }
' ) < "$TMP_LIST" > "$TMP_HITS" 2>/dev/null

NHITS="$(LC_ALL=C awk 'END { print NR+0 }' "$TMP_HITS")"

if [ "$NHITS" -eq 0 ]; then
  echo "[check-machine-paths] ✓ $UNIVERS fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine"
  exit 0
fi

echo "[check-machine-paths] ✗ $NHITS chemin(s) absolu(s) de machine dans des fichiers VERSIONNÉS :" >&2
LC_ALL=C awk '{ print "  " $0 }' "$TMP_HITS" >&2
cat >&2 <<USAGE_KO

Univers balayé : $UNIVERS fichier(s) suivi(s) sous $ROOT.
Corriger, dans cet ordre de préférence :
  1. rendre le chemin RELATIF à la racine du dépôt (\`.planning/…\`, \`plugin/…\`) — c'est presque
     toujours ce que la phrase voulait dire, et c'est rejouable sur un autre poste ;
  2. hors du dépôt, écrire \`~/…\` (le home, sans nommer le compte) ;
  3. en documentation, écrire \`/Users/<user>/…\` — le chevron n'est pas un identifiant, le gate ne
     le voit pas, et la phrase dit enfin « un compte quelconque » ;
  4. si le littéral EST le sujet (fixture, sortie citée verbatim), poser le marqueur
     \`$HATCH\` sur la ligne — explicite et greppable.
USAGE_KO
exit 1
