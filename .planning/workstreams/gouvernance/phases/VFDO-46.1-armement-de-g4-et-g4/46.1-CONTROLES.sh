#!/usr/bin/env bash
# 46.1-CONTROLES.sh — outil de contrôle de la Phase 46.1 (armement de G4 et G4′).
#
# RÔLE. Rejouer les suites du dépôt sans jamais conclure au vert sur du vide, mesurer UNE fois la base de
# non-régression de la phase, dériver de cette base (et d'elle seule) tout plafond de durée, prouver les
# invariants de P461-D-12 et P461-D-09, vérifier qu'un relevé de rejeu reproduit la décision du script
# d'armement (P461-D-06, P461-D-07). Régime de non-régression : P461-D-16 (CONTEXT de la phase).
#
# CE QUE L'OUTIL N'EST PAS. Un gate de la CI : outil de phase sous .planning/ (précédent
# 45-CONTROLE-MARQUEUR.sh), jamais livré à un lab. La décision d'armement reste celle de
# plugin/planning-core/scripts/verifier-releve.sh, script du module testé en CI ; la justesse de l'outil est
# prouvée par --autotest (à chaque tâche qui l'étend) et, pour les relevés, par releve-chaine contre la vraie
# chaîne synthétique. Le placer sous scripts/ en ferait un gate de la surface G-2 sans rien prouver de plus.
# Il ne lit aucun lab, ne lance aucune sonde `claude -p`, ne modifie ni le module, ni scripts/, ni la CI.
#
# MODES (chemin d'une suite : relatif à la racine du dépôt ; c'est aussi sa clé dans la base)
#   suite <chemin> [--exige=<libellé>]… [--duree-max=base] [--detache=<dossier>] [--shells=bash|bash,zsh]
#                  [--base-cle=<chemin>] [--base-ajout=<NN>]
#                  Rejoue `bash <suite>` UNE fois, sous un HOME temporaire neuf (XDG_CACHE_HOME dessous), dans
#                  un environnement privé de VF_PF_SECTIONS, VF_PF_MUT et VF_RELEVE_CHAINE_DEPOT (une suite
#                  filtrée ne vaut jamais preuve). `--shells=bash,zsh` (défaut bash) ne vaut que pour un script
#                  léger dont le résultat dépend du shell appelant : une suite n'est jamais relancée sous zsh.
#   toutes [--base] [--contre-base] [--detache=<dossier>] [--arbre-intact=<ref>]
#                  Découverte comme la CI (`find plugin scripts -type f -path '*/tests/test-*.sh'`, tri LC_ALL=C),
#                  chaque suite rejouée UNE fois sous un HOME temporaire neuf. Rouge : code non nul OU dernière
#                  ligne d'une forme de bilan reconnue qui déclare `0 OK`. `--contre-base` annote
#                  `rouge-sur-base=oui|non` sans rien décider. `--base` mesure la base (exige l'arbre intact).
#   sonder <dossier> [--tranche=<s>]
#                  Attente bornée d'un rejeu détaché (au plus UNE tranche). Codes 0, 1, 2 (en cours), 3 (à remonter).
#   base-duree <suite> [--base-cle=<chemin>]
#                  Valide la base puis imprime `BASE-DUREE <suite> s=<n>`.
#   invariants --base=<ref>                       hook par rôle, fichiers de version, tag, G4 figé (g4-fige).
#   releve <relevé> --etape=<5|6> [--lab=<lab affiché>]… [--verificateur=<script>]
#                  Cohérence d'un relevé de rejeu avec la décision fraîche du script d'armement (repos compris).
#   releve-chaine [--suite=<chemin>]              la même cohérence, éprouvée sur la sortie réelle de la chaîne.
#   --autotest     Preuve que chaque contrôle sait rougir pour sa raison (fausses suites, faux dépôts, fausse base).
#   --help         Cet en-tête.
#   (46.1-17 ajoute l'option --montre et les modes armement, etat-reference, imputer, jalon, empreinte, puis
#   FIGE l'outil.)
#
# CODES. 0 conforme · 1 écart · 64 usage (dont base absente quand un plafond la suppose, base corrompue,
# arbre non intact, rejeu à lancer détaché) · `sonder` ajoute 2 (en cours dans la borne) et 3 (borne dépassée ou
# rejeu mort : REMONTER au manager, ne rien tuer, ne rien relancer).
#
# RÈGLE — jamais un vert à vide. Un bilan `0 OK` n'est jamais vert, en mode `suite` comme en mode `toutes`,
# avec ou sans `--exige` ; une découverte vide n'est jamais verte (code 1) ; un libellé exigé absent est un
# écart ; un plafond demandé sans base mesurée est un écart (`base-absente`), jamais un plafond inventé.
#
# FORMES DE BILAN RECONNUES — liste FERMÉE de trois formes, lue par UNE seule fonction (bilan_lire) que `toutes`
# et `imputer` (46.1-17) réutilisent :
#   canonique   == Résultat : <n> OK · <m> KO ==
#   à barres    == résultat : <n> OK / <m> KO[ / <s> SKIP] ==          (r minuscule)
#   à virgules  == Résultat : <n> OK, <m> KO[, <s> SKIP] ==            (R majuscule)
# Pour chacune : vert seulement si m = 0 ET n ≥ 1 ; un compte SKIP non nul est imprimé `SUITE-NOTE skip=<s>`
# (information, non rouge). Toute autre dernière ligne non vide est l'écart STRUCTUREL
# `SUITE-ECART bilan forme-inconnue` (la forme de la suite, pas une régression) : `suite` le rougit, `toutes`
# ne le lit pas (le code de sortie fait foi, comme à la CI) mais la ligne TOUTES-FORMES dit combien de suites
# sont dans ce cas. La liste ne s'étend que par décision du manager, avec un cas d'autotest par forme.
#
# LIGNES ÉMISES (mode suite) : `SUITE-ECART <motif> <détail>` — rc · bilan forme-inconnue | ko=<m> | zero-ok ·
# ko · non-tue · exige-absent <libellé> · base-absente · base-rouge · duree-plafond <n> > <max> ;
# `SUITE-NOTE …` ; `SUITE <chemin> shell=<s> rc=<rc> duree=<n> exiges=<trouvés>/<demandés>` par lancement.
# Mode toutes : `TOUTES <suite> rc=<rc> s=<n>[ zero-ok]`, `TOUTES-FORMES canon=<a> barres=<b> virgules=<c>
# inconnue=<d>`, `TOUTES-LONGUES <suite> s=<n>` (les cinq plus longues), `TOUTES-BILAN suites=<n> vertes=<v>
# rouges=<r> zero-ok=<z> s=<secondes>`, `TOUTES-CONTRE-BASE rouges=<r> sur-base=<p> hors-base=<k>`.
#
# DURÉE MURALE. Secondes entières (`date +%s` avant et après le lancement), MESURÉES PAR L'OUTIL pour TOUTE
# suite. La ligne `DUREE s=` qu'une suite imprime (ou n'imprime pas) n'est ni lue ni exigée : c'est une autre
# grandeur que la durée de base, qui est murale, et aucun plafond ne dépend de sa présence.
#
# AUCUN PLAFOND NUMÉRIQUE. `--duree-max` n'accepte QUE la valeur littérale `base` (toute autre forme : code 64,
# avant toute lecture de la base). Plafond = 3 × la durée de base de la suite (plancher 1 s), valable pour TOUTE
# suite présente dans la base (ligne BASE ou BASE-AJOUT), qu'elle imprime ou non `DUREE s=`. Motif : P461-D-16,
# aucun plafond sans base mesurée. Aucune liste d'exceptions (suite admise à `0 OK`, écart de code admis) : une
# exception serait un arbitrage, jamais posé par un exécuteur.
#
# BASE (46.1-BASE.txt, à côté de l'outil d'origine). Mesurée UNE fois par `toutes --base`, commitée, jamais
# réécrite : aucune option de remesure. Lignes `BASE <suite> rc=<rc> s=<n>[ zero-ok]`, `BASE-BILAN suites=<n>
# vertes=<v> rouges=<r> zero-ok=<z> s=<secondes>`, `BASE-MESURE commit=<sha> date=<UTC> charge=<début>/<fin>
# cpu=<n>` (loadavg `l1,l5,l15`), et `BASE-AJOUT <suite> s=<n> plan=<NN>` pour une suite NEUVE d'un plan. La
# voie UNIQUE d'écriture d'une ligne BASE-AJOUT est `suite … --base-ajout=<NN>` (durée murale mesurée par
# l'outil, jamais à la main, jamais d'après une ligne DUREE s= ; suite déjà dans la base : code 64
# base-ajout-connue, fichier intact). Chaque lecture valide d'abord le fichier : exactement une BASE-MESURE et une
# BASE-BILAN, `suites` égal au nombre de lignes BASE, aucune suite en double, `commit` ancêtre de HEAD ; sinon code
# 64 et `BASE-CORROMPUE <motif>`. `--base-fichier=<chemin>` n'existe que pour l'autotest (imprime
# `BASE-FICHIER-ALTERNATIF`) ; une commande de plan ne l'emploie jamais.
#
# CONSTANTES DÉCLARÉES (les seules constantes de durée de l'outil, avec leur motif) :
#   FACTEUR_SUITE=3        plafond et borne d'une suite = 3 × sa durée de base (dispersion ×2,8 mesurée à la Phase
#                          46 entre charge faible et forte)
#   FACTEUR_TOUTES=2       borne d'un rejeu détaché `toutes` = 2 × la durée murale de la BASE-BILAN
#   SEUIL_DETACHE=480      une suite (ou une découverte) dont la durée de base atteint 480 s ne se lance pas au
#                          premier plan : propriété de la commande Bash du harnais (plafond de 10 min), pas une
#                          borne de verdict
#   TRANCHE_DEFAUT=480 / TRANCHE_MAX=540   tranche de sondage de `sonder`, même motif (propriété du harnais)
#   PAS_SONDE=5            période de sondage de fin.txt
#   BORNE_MESURE_BASE=14400  remontée de sondage de la seule mesure de la base (elle n'a pas de base d'où dériver
#                          sa borne) : plus que l'estimation haute de 46.1-14 (3 h) ; ni plafond ni verdict,
#                          dépassée elle fait remonter, rien n'est tué
# Source : plan 46.1-14 ; aucune autre valeur de durée n'existe dans l'outil.
#
# DONNÉES D'AUTOTEST. Fausses suites, faux dépôts git, faux hook, faux vérificateur, faux fichiers de base et
# faux relevés sont fabriqués sous mktemp, jamais dans ce dépôt ; les chemins de machine n'y figurent que sous
# des segments PLACEHOLDER admis par scripts/check-machine-paths.sh.
set -uo pipefail

# ---------------------------------------------------------------------------------------------------------
# Constantes déclarées
# ---------------------------------------------------------------------------------------------------------
FACTEUR_SUITE=3
FACTEUR_TOUTES=2
SEUIL_DETACHE=480
TRANCHE_DEFAUT=480
TRANCHE_MAX=540
PAS_SONDE=5
BORNE_MESURE_BASE=14400
REF_INTACT=8519c402
TAB=$(printf '\t')

# Cas d'autotest déclarés : l'autotest compare les cas joués à cette liste (un cas déclaré et non joué est un
# échec). Chaque tâche qui étend l'outil complète la liste.
CAS_AUTOTEST=(
  suite-saine suite-ko suite-non-tue suite-bilan-ko suite-bilan-pas-derniere suite-zero-ok
  suite-bilan-barres suite-bilan-barres-zero-ok suite-bilan-virgules suite-bilan-virgules-ko
  suite-bilan-inconnu suite-bilan-inconnu-motifs-lisibles suite-rc exige-absent exige-prefixe exige-present
  suite-une-passe suite-shells-bash-zsh suite-filtre-retire
  duree-numerique-refusee duree-base-absente duree-base-rouge duree-plafond-depasse duree-sous-plafond
  duree-ligne-suite-ignoree suite-detache-requis toutes-detache-requis
  toutes-saines toutes-une-rouge toutes-vide toutes-zero-ok toutes-zero-ok-barres toutes-formes
  toutes-contre-base toutes-contre-base-sans-base toutes-base-ecrit toutes-base-existante
  toutes-base-arbre-modifie
  base-duree-ok base-duree-absente base-duree-rouge base-corrompue-bilan base-corrompue-doublon
  base-sans-mesure base-ajout-vert base-ajout-duree-murale base-ajout-connue base-ajout-rouge
  base-ajout-detache
)

# ---------------------------------------------------------------------------------------------------------
# Utilitaires
# ---------------------------------------------------------------------------------------------------------
chemin_absolu() { # <fichier> -> chemin absolu physique
  local d b
  d=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P) || return 1
  b=$(basename "$1")
  printf '%s/%s\n' "$d" "$b"
}

OUTIL=$(chemin_absolu "$0") || OUTIL=$0
OUTIL_ORIGINE=$OUTIL
BASE_FICHIER=""
BASE_FICHIER_ALT=0
DETACHE_INTERNE=""
RACINE=""
NT=""
TMPS=()

nettoyer() {
  local t
  for t in ${TMPS[@]+"${TMPS[@]}"}; do
    [ -n "$t" ] && rm -rf "$t"
  done
}

nouveau_tmp() { # -> NT (le répertoire est supprimé à la sortie)
  NT=$(mktemp -d "${TMPDIR:-/tmp}/c461.XXXXXX") || { echo "mktemp impossible" >&2; exit 64; }
  TMPS+=("$NT")
}

die_usage() {
  printf 'usage : %s\n' "$*" >&2
  exit 64
}

aide() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$OUTIL"
}

racine_ou_sortir() {
  RACINE=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "hors d'un dépôt git" >&2; exit 64; }
  cd "$RACINE" || exit 64
  if [ -z "$BASE_FICHIER" ]; then
    BASE_FICHIER="$(dirname "$OUTIL_ORIGINE")/46.1-BASE.txt"
  fi
}

option_base_fichier() { # <chemin> (autotest seulement)
  BASE_FICHIER=$1
  BASE_FICHIER_ALT=1
  printf 'BASE-FICHIER-ALTERNATIF %s\n' "$1"
}

derniere_ligne() { # <fichier> : dernière ligne non vide
  sed -n '/[^[:space:]]/h;${x;p;}' "$1"
}

# Lit UNE ligne de bilan. Imprime `<forme> <n> <m> <s>` (forme : canon | barres | virgules) ou `inconnue`.
bilan_lire() { # <ligne>
  local r
  r=$(printf '%s\n' "$1" | LC_ALL=C sed -n \
    -e 's/^== Résultat : \([0-9][0-9]*\) OK · \([0-9][0-9]*\) KO ==[[:space:]]*$/canon \1 \2 0/p' \
    -e 's/^== résultat : \([0-9][0-9]*\) OK \/ \([0-9][0-9]*\) KO \/ \([0-9][0-9]*\) SKIP ==[[:space:]]*$/barres \1 \2 \3/p' \
    -e 's/^== résultat : \([0-9][0-9]*\) OK \/ \([0-9][0-9]*\) KO ==[[:space:]]*$/barres \1 \2 0/p' \
    -e 's/^== Résultat : \([0-9][0-9]*\) OK, \([0-9][0-9]*\) KO, \([0-9][0-9]*\) SKIP ==[[:space:]]*$/virgules \1 \2 \3/p' \
    -e 's/^== Résultat : \([0-9][0-9]*\) OK, \([0-9][0-9]*\) KO ==[[:space:]]*$/virgules \1 \2 0/p')
  if [ -n "$r" ]; then
    printf '%s\n' "$r" | head -n 1
  else
    echo inconnue
  fi
}

# ---------------------------------------------------------------------------------------------------------
# Base de non-régression : validation, lecture, écriture
# ---------------------------------------------------------------------------------------------------------
# Valide $BASE_FICHIER. Codes : 0 ok (BASE_COMMIT posé) · 3 fichier absent · 64 corrompu (imprime BASE-CORROMPUE).
base_valider() {
  local res motif
  [ -e "$BASE_FICHIER" ] || return 3
  if [ ! -f "$BASE_FICHIER" ] || [ ! -r "$BASE_FICHIER" ]; then
    echo "BASE-CORROMPUE illisible"
    return 64
  fi
  res=$(LC_ALL=C awk '
    function mal(m) { if (err == "") err = m }
    /^[[:space:]]*$/ { next }
    /^#/ { next }
    $1 == "BASE" {
      if ((NF != 4 && NF != 5) || $3 !~ /^rc=[0-9]+$/ || $4 !~ /^s=[0-9]+$/ || (NF == 5 && $5 != "zero-ok")) { mal("ligne-BASE-malformee"); next }
      if ($2 in vu) mal("doublon " $2); vu[$2] = 1; nbase++; next
    }
    $1 == "BASE-AJOUT" {
      if (NF != 4 || $3 !~ /^s=[0-9]+$/ || $4 !~ /^plan=[0-9]+$/) { mal("ligne-BASE-AJOUT-malformee"); next }
      if ($2 in vu) mal("doublon " $2); vu[$2] = 1; next
    }
    $1 == "BASE-BILAN" {
      if (NF != 6 || $2 !~ /^suites=[0-9]+$/ || $3 !~ /^vertes=[0-9]+$/ || $4 !~ /^rouges=[0-9]+$/ || $5 !~ /^zero-ok=[0-9]+$/ || $6 !~ /^s=[0-9]+$/) { mal("ligne-BASE-BILAN-malformee"); next }
      nbilan++; bs = substr($2, 8) + 0; bv = substr($3, 8) + 0; br = substr($4, 8) + 0; next
    }
    $1 == "BASE-MESURE" {
      if (NF != 5 || $2 !~ /^commit=[0-9a-f]+$/ || $3 !~ /^date=/ || $4 !~ /^charge=/ || $5 !~ /^cpu=[0-9]+$/) { mal("ligne-BASE-MESURE-malformee"); next }
      nmes++; commit = substr($2, 8); next
    }
    { mal("ligne-inconnue") }
    END {
      if (err == "" && nbilan != 1) err = "BASE-BILAN-absente-ou-multiple"
      if (err == "" && nmes != 1) err = "BASE-MESURE-absente-ou-multiple"
      if (err == "" && bs != nbase) err = "bilan-incoherent suites=" bs " lignes-BASE=" nbase
      if (err == "" && bv + br != bs) err = "bilan-incoherent vertes+rouges"
      if (err != "") print "ERR " err; else print "OK " commit
    }' "$BASE_FICHIER")
  case $res in
    "OK "*)
      BASE_COMMIT=${res#OK }
      if ! git merge-base --is-ancestor "$BASE_COMMIT" HEAD >/dev/null 2>&1; then
        echo "BASE-CORROMPUE commit-non-ancetre $BASE_COMMIT"
        return 64
      fi
      return 0 ;;
    *)
      motif=${res#ERR }
      echo "BASE-CORROMPUE $motif"
      return 64 ;;
  esac
}

# Cherche une suite dans la base (déjà validée). Imprime `BASE <rc> <s> <0|1>` ou `AJOUT <s>` ; rien si absente.
base_chercher() { # <clé>
  CLE="$1" LC_ALL=C awk '
    BEGIN { cle = ENVIRON["CLE"] }
    $1 == "BASE" && $2 == cle { z = (NF == 5) ? 1 : 0; print "BASE " substr($3, 4) " " substr($4, 3) " " z; exit }
    $1 == "BASE-AJOUT" && $2 == cle { print "AJOUT " substr($3, 3); exit }
  ' "$BASE_FICHIER"
}

base_bilan_s() {
  LC_ALL=C awk '$1 == "BASE-BILAN" { print substr($6, 3); exit }' "$BASE_FICHIER"
}

# Remplace atomiquement $BASE_FICHIER par son contenu + les lignes de $2 (fichier temporaire puis mv).
base_ajouter_lignes() { # <fichier de lignes à ajouter>
  local tmp
  tmp=$(mktemp "$(dirname "$BASE_FICHIER")/.base.XXXXXX") || return 1
  cat "$BASE_FICHIER" "$1" > "$tmp" && chmod 644 "$tmp" && mv "$tmp" "$BASE_FICHIER"
}

charge_lire() { # -> l1,l5,l15
  local l
  if l=$(sysctl -n vm.loadavg 2>/dev/null) && [ -n "$l" ]; then
    printf '%s\n' "$l" | tr -d '{}' | awk '{ printf "%s,%s,%s\n", $1, $2, $3 }'
  elif [ -r /proc/loadavg ]; then
    awk '{ printf "%s,%s,%s\n", $1, $2, $3 }' /proc/loadavg
  else
    uptime | sed 's/.*load averages*: *//' | tr -d ',' | awk '{ printf "%s,%s,%s\n", $1, $2, $3 }'
  fi
}

cpu_lire() {
  local n
  n=$(sysctl -n hw.ncpu 2>/dev/null) || n=""
  [ -n "$n" ] || n=$(getconf _NPROCESSORS_ONLN 2>/dev/null) || n=""
  [ -n "$n" ] || n=1
  printf '%s\n' "$n"
}

# ---------------------------------------------------------------------------------------------------------
# Rejeu d'une suite
# ---------------------------------------------------------------------------------------------------------
# lancer_suite <suite> <shell> <sortie> : UNE passe, HOME temporaire neuf, variables de filtrage retirées.
# Pose L_RC et L_DUREE (secondes murales mesurées ici). LANCER_ENV_EXTRA (NOM=valeur) n'est employé que par
# releve-chaine (VF_RELEVE_CHAINE_DEPOT).
lancer_suite() {
  local suite=$1 shell=$2 sortie=$3 h t0 t1
  nouveau_tmp
  h=$NT
  mkdir -p "$h/.cache"
  t0=$(date +%s)
  (
    cd "$RACINE" || exit 127
    env -u VF_PF_SECTIONS -u VF_PF_MUT -u VF_RELEVE_CHAINE_DEPOT \
      HOME="$h" XDG_CACHE_HOME="$h/.cache" ${LANCER_ENV_EXTRA:+"$LANCER_ENV_EXTRA"} \
      "$shell" "$suite"
  ) > "$sortie" 2>&1 < /dev/null
  L_RC=$?
  t1=$(date +%s)
  L_DUREE=$((t1 - t0))
  rm -rf "$h"
}

NEC=0
ecart() {
  printf 'SUITE-ECART %s\n' "$*"
  NEC=$((NEC + 1))
}

exige_present() { # <sortie> <libellé>
  L="  ✓ $2" LC_ALL=C awk '
    BEGIN { l = ENVIRON["L"]; n = length(l) }
    substr($0, 1, n) == l { r = substr($0, n + 1); if (r == "" || substr(r, 1, 1) == " ") f = 1 }
    END { exit f ? 0 : 1 }' "$1"
}

# Évalue un lancement : imprime les lignes retenues de la sortie, les SUITE-ECART, pose EV_TROUVES.
evaluer_lancement() { # <sortie> <rc>
  local sortie=$1 rc=$2 derniere r forme n m s k nt lib
  EV_TROUVES=0
  k=$(LC_ALL=C awk 'index($0, "  ✗ ") == 1 { c++ } END { print c + 0 }' "$sortie")
  nt=$(LC_ALL=C awk 'index($0, "NON TUÉ") > 0 { c++ } END { print c + 0 }' "$sortie")
  derniere=$(derniere_ligne "$sortie")
  LC_ALL=C awk 'index($0, "  ✗ ") == 1 || index($0, "NON TUÉ") > 0' "$sortie"
  printf '%s\n' "$derniere"
  [ "$rc" -eq 0 ] || ecart "rc $rc"
  r=$(bilan_lire "$derniere")
  if [ "$r" = inconnue ]; then
    ecart "bilan forme-inconnue"
  else
    read -r forme n m s <<EOF
$r
EOF
    if [ "$m" -gt 0 ]; then
      ecart "bilan ko=$m"
    elif [ "$n" -eq 0 ]; then
      ecart "bilan zero-ok"
    fi
    [ "$s" -eq 0 ] || printf 'SUITE-NOTE skip=%s\n' "$s"
  fi
  [ "$k" -eq 0 ] || ecart "ko n=$k"
  [ "$nt" -eq 0 ] || ecart "non-tue n=$nt"
  for lib in ${EXIGES[@]+"${EXIGES[@]}"}; do
    if exige_present "$sortie" "$lib"; then
      EV_TROUVES=$((EV_TROUVES + 1))
    else
      ecart "exige-absent $lib"
    fi
  done
}

# ---------------------------------------------------------------------------------------------------------
# Mode suite
# ---------------------------------------------------------------------------------------------------------
cmd_suite() {
  local suite="" duree_max="" dm_set=0 shells="bash" cle="" ajout="" aj_set=0 sh sorties entree
  local b_kind="" b_rc="" b_s="" b_zero="" rcv plafond ajout_s="" premier=1 base_ok=0
  EXIGES=()
  NEC=0
  while [ $# -gt 0 ]; do
    case $1 in
      --exige=*) [ -n "${1#--exige=}" ] || die_usage "--exige=<libellé> non vide"; EXIGES+=("${1#--exige=}") ;;
      --duree-max=*) duree_max=${1#--duree-max=}; dm_set=1 ;;
      --shells=*) shells=${1#--shells=} ;;
      --base-cle=*) cle=${1#--base-cle=} ;;
      --base-ajout=*) ajout=${1#--base-ajout=}; aj_set=1 ;;
      --base-fichier=*) option_base_fichier "${1#--base-fichier=}" ;;
      -*) die_usage "suite : option inconnue : $1" ;;
      *) [ -z "$suite" ] || die_usage "suite : une seule suite par appel"; suite=$1 ;;
    esac
    shift
  done
  [ -n "$suite" ] || die_usage "suite <chemin> [options]"
  if [ "$dm_set" -eq 1 ] && [ "$duree_max" != base ]; then
    echo "SUITE-USAGE --duree-max n'accepte que la valeur littérale base (aucun plafond numérique)" >&2
    exit 64
  fi
  case $shells in bash | bash,zsh) ;; *) die_usage "suite : --shells=bash ou --shells=bash,zsh" ;; esac
  if [ "$aj_set" -eq 1 ]; then
    case $ajout in '' | *[!0-9]*) die_usage "suite : --base-ajout=<NN> (chiffres)" ;; esac
    [ "$dm_set" -eq 0 ] || die_usage "suite : --base-ajout et --duree-max s'excluent"
  fi
  racine_ou_sortir
  case $suite in "$RACINE"/*) suite=${suite#"$RACINE"/} ;; esac
  [ -f "$suite" ] || { echo "SUITE-USAGE suite introuvable : $suite" >&2; exit 64; }
  [ -n "$cle" ] || cle=$suite

  # --- base (lue seulement si elle existe ; validée à chaque lecture) ---
  if [ -e "$BASE_FICHIER" ]; then
    base_valider
    rcv=$?
    [ "$rcv" -eq 0 ] || exit 64
    base_ok=1
    entree=$(base_chercher "$cle")
    if [ -n "$entree" ]; then
      read -r b_kind b_rc b_s b_zero <<EOF
$entree
EOF
      if [ "$b_kind" = AJOUT ]; then
        b_s=$b_rc
        b_rc=0
        b_zero=0
      fi
    fi
  fi
  if [ "$aj_set" -eq 1 ]; then
    if [ "$base_ok" -ne 1 ]; then
      echo "SUITE-USAGE base-ajout : $BASE_FICHIER absente (la base se mesure d'abord, une seule fois)" >&2
      exit 64
    fi
    if [ -n "$b_kind" ]; then
      echo "SUITE-USAGE base-ajout-connue $cle : déjà dans la base, rien n'est écrit" >&2
      exit 64
    fi
  fi
  if [ -n "$b_kind" ] && [ "$b_rc" -eq 0 ] && [ "$b_zero" -eq 0 ] && [ "$b_s" -ge "$SEUIL_DETACHE" ]; then
    echo "SUITE-USAGE detache-requis $cle : durée de base $b_s s >= $SEUIL_DETACHE s, à lancer détaché (--detache=<dossier>) puis sonder" >&2
    exit 64
  fi

  # --- lancements ---
  nouveau_tmp
  sorties=$NT
  for sh in $(printf '%s\n' "$shells" | tr ',' ' '); do
    if [ "$sh" = zsh ] && ! command -v zsh >/dev/null 2>&1; then
      echo "SUITE-NOTE zsh absent"
      continue
    fi
    lancer_suite "$suite" "$sh" "$sorties/sortie.$sh"
    evaluer_lancement "$sorties/sortie.$sh" "$L_RC"
    if [ "$dm_set" -eq 1 ]; then
      if [ -z "$b_kind" ]; then
        ecart "base-absente $cle"
      elif [ "$b_rc" -ne 0 ] || [ "$b_zero" -ne 0 ]; then
        ecart "base-rouge $cle"
      else
        plafond=$((b_s * FACTEUR_SUITE))
        [ "$plafond" -ge 1 ] || plafond=1
        if [ "$L_DUREE" -gt "$plafond" ]; then
          ecart "duree-plafond $L_DUREE > $plafond"
        fi
      fi
    fi
    printf 'SUITE %s shell=%s rc=%s duree=%s exiges=%s/%s\n' "$suite" "$sh" "$L_RC" "$L_DUREE" "$EV_TROUVES" "${#EXIGES[@]}"
    if [ "$premier" -eq 1 ]; then
      ajout_s=$L_DUREE
      premier=0
    fi
  done

  if [ "$aj_set" -eq 1 ] && [ "$NEC" -eq 0 ] && [ -n "$ajout_s" ]; then
    printf 'BASE-AJOUT %s s=%s plan=%s\n' "$cle" "$ajout_s" "$ajout" > "$sorties/ajout.txt"
    base_ajouter_lignes "$sorties/ajout.txt" || { echo "BASE-AJOUT écriture impossible" >&2; exit 64; }
    printf 'BASE-AJOUT-ECRITE %s s=%s plan=%s\n' "$cle" "$ajout_s" "$ajout"
  fi
  [ "$NEC" -eq 0 ]
}

# ---------------------------------------------------------------------------------------------------------
# Mode base-duree
# ---------------------------------------------------------------------------------------------------------
cmd_base_duree() {
  local suite="" cle="" rcv entree kind rc s z
  while [ $# -gt 0 ]; do
    case $1 in
      --base-cle=*) cle=${1#--base-cle=} ;;
      --base-fichier=*) option_base_fichier "${1#--base-fichier=}" ;;
      -*) die_usage "base-duree : option inconnue : $1" ;;
      *) [ -z "$suite" ] || die_usage "base-duree <suite>"; suite=$1 ;;
    esac
    shift
  done
  [ -n "$suite" ] || die_usage "base-duree <suite> [--base-cle=<chemin>]"
  racine_ou_sortir
  case $suite in "$RACINE"/*) suite=${suite#"$RACINE"/} ;; esac
  [ -n "$cle" ] || cle=$suite
  base_valider
  rcv=$?
  if [ "$rcv" -eq 3 ]; then
    echo "BASE-CORROMPUE fichier-absent $BASE_FICHIER"
    exit 64
  fi
  [ "$rcv" -eq 0 ] || exit 64
  entree=$(base_chercher "$cle")
  if [ -z "$entree" ]; then
    echo "BASE-ABSENTE $suite"
    exit 64
  fi
  read -r kind rc s z <<EOF
$entree
EOF
  if [ "$kind" = AJOUT ]; then
    printf 'BASE-DUREE %s s=%s\n' "$suite" "$rc"
    exit 0
  fi
  if [ "$rc" -ne 0 ] || [ "$z" -ne 0 ]; then
    echo "BASE-DUREE-NON-FIABLE $suite"
    exit 1
  fi
  printf 'BASE-DUREE %s s=%s\n' "$suite" "$s"
}

# ---------------------------------------------------------------------------------------------------------
# Mode toutes
# ---------------------------------------------------------------------------------------------------------
arbre_intact() { # <ref> : 0 si plugin scripts .github sont identiques à <ref> (suivis et non suivis)
  local d p
  if ! d=$(git diff --name-only "$1" -- plugin scripts .github 2>/dev/null); then
    echo "ARBRE-NON-INTACT référence illisible : $1"
    return 1
  fi
  p=$(git status --porcelain -- plugin scripts .github 2>/dev/null)
  if [ -n "$d" ] || [ -n "$p" ]; then
    echo "ARBRE-NON-INTACT plugin/scripts/.github diffèrent de $1 (la base se mesure sur l'arbre intact)"
    [ -z "$d" ] || printf '%s\n' "$d" | sed 's/^/  modifié : /'
    [ -z "$p" ] || printf '%s\n' "$p" | sed 's/^/  statut : /'
    return 1
  fi
  return 0
}

cmd_toutes() {
  local base=0 contre=0 ref=$REF_INTACT ref_alt=0 rcv base_ok=0 bs
  local suites=() s sorties recs n=0 r=0 z=0 f_c=0 f_b=0 f_v=0 f_i=0 v=0 forme nn mm ss der zero rc_s ent
  local t0 t1 charge_debut charge_fin sur=0 hors=0 annot kind brc bsx bz
  while [ $# -gt 0 ]; do
    case $1 in
      --base) base=1 ;;
      --contre-base) contre=1 ;;
      --arbre-intact=*) ref=${1#--arbre-intact=}; ref_alt=1 ;;
      --base-fichier=*) option_base_fichier "${1#--base-fichier=}" ;;
      *) die_usage "toutes : option inconnue : $1" ;;
    esac
    shift
  done
  [ "$base" -eq 0 ] || [ "$contre" -eq 0 ] || die_usage "toutes : --base et --contre-base s'excluent"
  racine_ou_sortir
  [ "$ref_alt" -eq 0 ] || printf 'ARBRE-INTACT-ALTERNATIF %s\n' "$ref"

  if [ "$base" -eq 1 ]; then
    if [ -e "$BASE_FICHIER" ]; then
      echo "BASE-EXISTANTE $BASE_FICHIER : une base existante n'est jamais réécrite ni remesurée par un exécuteur (geste du manager : supprimer le fichier puis relancer)"
      exit 64
    fi
    arbre_intact "$ref" || exit 64
  else
    if [ -e "$BASE_FICHIER" ]; then
      base_valider
      rcv=$?
      [ "$rcv" -eq 0 ] || exit 64
      base_ok=1
    fi
    if [ "$contre" -eq 1 ] && [ "$base_ok" -ne 1 ]; then
      echo "BASE-ABSENTE $BASE_FICHIER : --contre-base exige la base mesurée"
      exit 64
    fi
    if [ "$base_ok" -eq 1 ]; then
      bs=$(base_bilan_s)
      if [ "$bs" -ge "$SEUIL_DETACHE" ]; then
        echo "TOUTES-USAGE detache-requis : la durée murale de la base ($bs s) atteint $SEUIL_DETACHE s, la découverte complète se lance détachée (--detache=<dossier>) puis sonder" >&2
        exit 64
      fi
    fi
  fi

  while IFS= read -r s; do
    [ -n "$s" ] && suites+=("$s")
  done < <(find plugin scripts -type f -path '*/tests/test-*.sh' 2>/dev/null | LC_ALL=C sort)

  nouveau_tmp
  sorties=$NT
  recs=$sorties/recs.tsv
  : > "$recs"
  charge_debut=$(charge_lire)
  t0=$(date +%s)
  for s in ${suites[@]+"${suites[@]}"}; do
    lancer_suite "$s" bash "$sorties/sortie.txt"
    rc_s=$L_RC
    der=$(derniere_ligne "$sorties/sortie.txt")
    ent=$(bilan_lire "$der")
    zero=0
    if [ "$ent" = inconnue ]; then
      f_i=$((f_i + 1))
    else
      read -r forme nn mm ss <<EOF
$ent
EOF
      case $forme in canon) f_c=$((f_c + 1)) ;; barres) f_b=$((f_b + 1)) ;; virgules) f_v=$((f_v + 1)) ;; esac
      [ "$nn" -ne 0 ] || zero=1
    fi
    n=$((n + 1))
    annot=""
    if [ "$rc_s" -ne 0 ] || [ "$zero" -eq 1 ]; then
      r=$((r + 1))
      [ "$zero" -eq 0 ] || z=$((z + 1))
      if [ "$contre" -eq 1 ]; then
        annot=" rouge-sur-base=non"
        bz=$(base_chercher "$s")
        if [ -n "$bz" ]; then
          read -r kind brc bsx bz <<EOF
$bz
EOF
          if [ "$kind" = BASE ] && { [ "$brc" -ne 0 ] || [ "$bz" -ne 0 ]; }; then
            annot=" rouge-sur-base=oui"
            sur=$((sur + 1))
          else
            hors=$((hors + 1))
          fi
        else
          hors=$((hors + 1))
        fi
      fi
    fi
    printf 'TOUTES %s rc=%s s=%s%s%s\n' "$s" "$rc_s" "$L_DUREE" "$([ "$zero" -eq 1 ] && printf ' zero-ok')" "$annot"
    printf '%s\t%s\t%s\t%s\n' "$s" "$rc_s" "$L_DUREE" "$zero" >> "$recs"
  done
  t1=$(date +%s)
  charge_fin=$(charge_lire)
  v=$((n - r))
  printf 'TOUTES-FORMES canon=%s barres=%s virgules=%s inconnue=%s\n' "$f_c" "$f_b" "$f_v" "$f_i"
  LC_ALL=C sort -t "$TAB" -k3,3nr -k1,1 "$recs" | head -n 5 | awk -F '\t' '{ printf "TOUTES-LONGUES %s s=%s\n", $1, $3 }'
  printf 'TOUTES-BILAN suites=%s vertes=%s rouges=%s zero-ok=%s s=%s\n' "$n" "$v" "$r" "$z" "$((t1 - t0))"
  [ "$contre" -eq 0 ] || printf 'TOUTES-CONTRE-BASE rouges=%s sur-base=%s hors-base=%s\n' "$r" "$sur" "$hors"

  if [ "$base" -eq 1 ] && [ "$n" -ge 1 ]; then
    {
      awk -F '\t' '{ printf "BASE %s rc=%s s=%s%s\n", $1, $2, $3, ($4 == 1 ? " zero-ok" : "") }' "$recs"
      printf 'BASE-BILAN suites=%s vertes=%s rouges=%s zero-ok=%s s=%s\n' "$n" "$v" "$r" "$z" "$((t1 - t0))"
      printf 'BASE-MESURE commit=%s date=%s charge=%s/%s cpu=%s\n' "$(git rev-parse HEAD)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$charge_debut" "$charge_fin" "$(cpu_lire)"
    } > "$sorties/base.tmp"
    local tmpb
    tmpb=$(mktemp "$(dirname "$BASE_FICHIER")/.base.XXXXXX") || { echo "écriture de la base impossible" >&2; exit 64; }
    cat "$sorties/base.tmp" > "$tmpb" && chmod 644 "$tmpb" && mv "$tmpb" "$BASE_FICHIER" || { echo "écriture de la base impossible" >&2; exit 64; }
    printf 'BASE-ECRITE %s suites=%s\n' "$BASE_FICHIER" "$n"
  fi
  [ "$n" -ge 1 ] && [ "$r" -eq 0 ]
}

# ---------------------------------------------------------------------------------------------------------
# Autotest
# ---------------------------------------------------------------------------------------------------------
AT_JOUES=()
AT_KO=0
AT_FAIL=0
AT_NOM=""
AT_N=0
AT_RC=0
AT_OUT=""
AT_CWD=""
AT_TMP=""
FD=""

gitf() { git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null -c init.defaultBranch=main "$@"; }

at_debut() { # <nom>
  AT_NOM=$1
  AT_FAIL=0
  AT_N=$((AT_N + 1))
  AT_JOUES+=("$1")
}

at_echec() {
  AT_FAIL=1
  printf '  AUTOTEST-DETAIL %s : %s\n' "$AT_NOM" "$*"
}

at_lancer() { # args de l'outil ; cwd = $AT_CWD
  AT_OUT="$AT_TMP/out.$AT_N.$RANDOM"
  (cd "$AT_CWD" && bash "$OUTIL" "$@") > "$AT_OUT" 2>&1 < /dev/null
  AT_RC=$?
}

at_contient() { # <motif fixe>
  P="$1" LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) { f = 1 } END { exit f ? 0 : 1 }' "$AT_OUT" || at_echec "sortie sans « $1 »"
}

at_absent() { # <motif fixe>
  P="$1" LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) { f = 1 } END { exit f ? 0 : 1 }' "$AT_OUT" && at_echec "sortie avec « $1 »"
  return 0
}

at_compte() { # <préfixe> <n> : nombre de lignes qui COMMENCENT par le préfixe
  local c
  c=$(P="$1" LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) == 1 { c++ } END { print c + 0 }' "$AT_OUT")
  [ "$c" -eq "$2" ] || at_echec "lignes « $1… » : $c au lieu de $2"
}

at_fin() { # <attendu>
  local verdict=ok
  if [ "$AT_RC" != "$1" ] || [ "$AT_FAIL" -ne 0 ]; then
    verdict=ko
    AT_KO=$((AT_KO + 1))
  fi
  printf 'AUTOTEST %s attendu=%s obtenu=%s %s\n' "$AT_NOM" "$1" "$AT_RC" "$verdict"
  if [ "$verdict" = ko ] && [ -n "$AT_OUT" ] && [ -f "$AT_OUT" ]; then
    sed 's/^/    | /' "$AT_OUT" | head -n 40
  fi
}

at_depot() { # -> FD : faux dépôt git à un commit, avec plugin/ scripts/ .github/
  nouveau_tmp
  FD=$NT
  (
    cd "$FD" && git init -q . && git symbolic-ref HEAD refs/heads/main \
      && mkdir -p plugin/m/tests scripts/tests .github phase \
      && : > plugin/m/.keep && : > scripts/.keep && : > .github/.keep \
      && gitf add -A && gitf commit -q -m base
  ) > /dev/null 2>&1
  AT_CWD=$FD
}

at_commit() { # commite l'état courant du faux dépôt (pour les cas qui exigent un arbre propre)
  (cd "$FD" && gitf add -A && gitf commit -q -m etat) > /dev/null 2>&1
}

mk_suite() { # <chemin relatif au faux dépôt> <corps>
  mkdir -p "$(dirname "$FD/$1")"
  printf '#!/usr/bin/env bash\n%s\n' "$2" > "$FD/$1"
}

# mk_base <fichier> <entrée>… avec entrée = cle:rc:s[:zero-ok] ou +cle:s:plan (BASE-AJOUT).
# Variables : MK_BILAN_S (durée murale du bilan), MK_SANS_MESURE=1, MK_BILAN_SUITES (force le compte).
mk_base() {
  local f=$1 e cle rc s z nb=0 nv=0 nr=0 nz=0 tot=0 head bs
  shift
  head=$(cd "$FD" && git rev-parse HEAD)
  : > "$f"
  for e in "$@"; do
    case $e in
      +*)
        IFS=: read -r cle s rc <<EOF
${e#+}
EOF
        printf 'BASE-AJOUT %s s=%s plan=%s\n' "$cle" "$s" "$rc" >> "$f" ;;
      *)
        z=""
        IFS=: read -r cle rc s z <<EOF
$e
EOF
        nb=$((nb + 1))
        tot=$((tot + s))
        if [ "$rc" -ne 0 ] || [ -n "$z" ]; then nr=$((nr + 1)); else nv=$((nv + 1)); fi
        [ -z "$z" ] || nz=$((nz + 1))
        printf 'BASE %s rc=%s s=%s%s\n' "$cle" "$rc" "$s" "$([ -n "$z" ] && printf ' zero-ok')" >> "$f" ;;
    esac
  done
  bs=${MK_BILAN_S:-$tot}
  printf 'BASE-BILAN suites=%s vertes=%s rouges=%s zero-ok=%s s=%s\n' "${MK_BILAN_SUITES:-$nb}" "$nv" "$nr" "$nz" "$bs" >> "$f"
  if [ "${MK_SANS_MESURE:-0}" != 1 ]; then
    printf 'BASE-MESURE commit=%s date=2026-01-01T00:00:00Z charge=0.10,0.10,0.10/0.10,0.10,0.10 cpu=4\n' "$head" >> "$f"
  fi
}

autotest_suite() {
  local BF cpt k out S=plugin/m/tests/test-c.sh
  nouveau_tmp
  AT_TMP=$NT
  at_depot
  BF=$AT_TMP/base.txt
  CANON='echo "== Résultat : 3 OK · 0 KO =="'

  at_debut suite-saine
  mk_suite $S "echo '  ✓ a'; $CANON"
  at_lancer suite $S
  at_compte "SUITE-ECART" 0; at_compte "SUITE $S shell=bash rc=0" 1
  at_fin 0

  at_debut suite-ko
  mk_suite $S "echo '  ✗ x'; $CANON"
  at_lancer suite $S
  at_contient "SUITE-ECART ko"
  at_fin 1

  at_debut suite-non-tue
  mk_suite $S "echo '  ✓ MUT-2 NON TUÉ'; $CANON"
  at_lancer suite $S
  at_contient "SUITE-ECART non-tue"
  at_fin 1

  at_debut suite-bilan-ko
  mk_suite $S "echo '== Résultat : 3 OK · 1 KO =='"
  at_lancer suite $S
  at_contient "SUITE-ECART bilan ko=1"
  at_fin 1

  at_debut suite-bilan-pas-derniere
  mk_suite $S "$CANON; echo 'ligne après le bilan'"
  at_lancer suite $S
  at_contient "SUITE-ECART bilan forme-inconnue"
  at_fin 1

  at_debut suite-zero-ok
  mk_suite $S "echo '== Résultat : 0 OK · 0 KO =='"
  at_lancer suite $S
  at_contient "SUITE-ECART bilan zero-ok"
  at_fin 1

  at_debut suite-bilan-barres
  mk_suite $S "echo '== résultat : 3 OK / 0 KO / 1 SKIP =='"
  at_lancer suite $S
  at_contient "SUITE-NOTE skip=1"; at_compte "SUITE-ECART" 0
  at_fin 0

  at_debut suite-bilan-barres-zero-ok
  mk_suite $S "echo '== résultat : 0 OK / 0 KO / 2 SKIP =='"
  at_lancer suite $S
  at_contient "SUITE-ECART bilan zero-ok"
  at_fin 1

  at_debut suite-bilan-virgules
  mk_suite $S "echo '== Résultat : 4 OK, 0 KO, 0 SKIP =='"
  at_lancer suite $S
  at_compte "SUITE-ECART" 0
  at_fin 0

  at_debut suite-bilan-virgules-ko
  mk_suite $S "echo '== Résultat : 4 OK, 1 KO, 0 SKIP =='"
  at_lancer suite $S
  at_contient "SUITE-ECART bilan ko=1"
  at_fin 1

  at_debut suite-bilan-inconnu
  mk_suite $S "echo '== résultat : 3 passés, 0 échoués =='"
  at_lancer suite $S
  at_compte "SUITE-ECART" 1; at_contient "SUITE-ECART bilan forme-inconnue"
  at_fin 1

  at_debut suite-bilan-inconnu-motifs-lisibles
  mk_suite $S "echo '  ✗ x'; echo '== résultat : 3 passés, 0 échoués =='; exit 1"
  at_lancer suite $S
  at_contient "SUITE-ECART bilan forme-inconnue"; at_contient "SUITE-ECART ko"; at_contient "SUITE-ECART rc 1"
  at_fin 1

  at_debut suite-rc
  mk_suite $S "$CANON; exit 3"
  at_lancer suite $S
  at_contient "SUITE-ECART rc 3"
  at_fin 1

  at_debut exige-absent
  mk_suite $S "echo '  ✓ R-Y ok'; $CANON"
  at_lancer suite $S --exige=R-Z
  at_contient "SUITE-ECART exige-absent R-Z"
  at_fin 1

  at_debut exige-prefixe
  mk_suite $S "echo '  ✓ R-X-10 autre libellé'; $CANON"
  at_lancer suite $S --exige=R-X-1
  at_contient "SUITE-ECART exige-absent R-X-1"
  at_fin 1

  at_debut exige-present
  mk_suite $S "echo '  ✓ R-X-1 le libellé'; echo '  ✓ R-X-2'; $CANON"
  at_lancer suite $S --exige=R-X-1 --exige=R-X-2
  at_compte "SUITE-ECART" 0; at_contient "exiges=2/2"
  at_fin 0

  at_debut suite-une-passe
  cpt=$AT_TMP/compteur-une-passe
  : > "$cpt"
  mk_suite $S "echo x >> '$cpt'; $CANON"
  at_lancer suite $S
  k=$(awk 'END { print NR }' "$cpt")
  [ "$k" -eq 1 ] || at_echec "la suite a été lancée $k fois"
  at_fin 0

  at_debut suite-shells-bash-zsh
  cpt=$AT_TMP/compteur-shells
  : > "$cpt"
  mk_suite $S "echo x >> '$cpt'; $CANON"
  at_lancer suite $S --shells=bash,zsh
  k=$(awk 'END { print NR }' "$cpt")
  if command -v zsh > /dev/null 2>&1; then
    [ "$k" -eq 2 ] || at_echec "zsh présent : $k lancements au lieu de 2"
    at_compte "SUITE $S shell=zsh" 1
  else
    at_contient "SUITE-NOTE zsh absent"
  fi
  at_fin 0

  at_debut suite-filtre-retire
  mk_suite $S 'if [ -n "${VF_PF_SECTIONS:-}${VF_PF_MUT:-}${VF_RELEVE_CHAINE_DEPOT:-}" ]; then echo "== Résultat : 0 OK · 0 KO =="; else echo "== Résultat : 2 OK · 0 KO =="; fi'
  AT_OUT="$AT_TMP/out.filtre"
  (cd "$AT_CWD" && VF_PF_SECTIONS=x VF_PF_MUT=y VF_RELEVE_CHAINE_DEPOT=z bash "$OUTIL" suite $S) > "$AT_OUT" 2>&1 < /dev/null
  AT_RC=$?
  at_compte "SUITE-ECART" 0
  at_fin 0

  at_debut duree-numerique-refusee
  mk_suite $S "$CANON"
  out=0
  for k in 5 0 ''; do
    at_lancer suite $S "--duree-max=$k"
    [ "$AT_RC" -eq 64 ] || { out=$AT_RC; at_echec "--duree-max=$k : code $AT_RC au lieu de 64"; }
  done
  AT_RC=$([ "$out" -eq 0 ] && echo 64 || echo "$out")
  at_fin 64

  at_debut duree-base-absente
  mk_base "$BF" "autre.sh:0:1"
  mk_suite $S "$CANON"
  at_lancer suite $S --duree-max=base --base-fichier="$BF"
  at_contient "SUITE-ECART base-absente"
  at_fin 1

  at_debut duree-base-rouge
  mk_base "$BF" "$S:1:1"
  at_lancer suite $S --duree-max=base --base-fichier="$BF"
  at_contient "SUITE-ECART base-rouge"
  at_fin 1

  at_debut duree-plafond-depasse
  mk_base "$BF" "$S:0:1"
  mk_suite $S "sleep 5; $CANON"
  at_lancer suite $S --duree-max=base --base-fichier="$BF"
  at_contient "SUITE-ECART duree-plafond"
  at_fin 1

  at_debut duree-sous-plafond
  mk_base "$BF" "$S:0:2"
  mk_suite $S "sleep 1; $CANON"
  at_lancer suite $S --duree-max=base --base-fichier="$BF"
  at_compte "SUITE-ECART" 0
  at_fin 0

  at_debut duree-ligne-suite-ignoree
  mk_base "$BF" "$S:0:1"
  mk_suite $S "echo 'DUREE s=0'; sleep 5; $CANON"
  at_lancer suite $S --duree-max=base --base-fichier="$BF"
  at_contient "SUITE-ECART duree-plafond"
  at_fin 1

  at_debut suite-detache-requis
  mk_base "$BF" "$S:0:500"
  mk_suite $S "$CANON"
  at_lancer suite $S --base-fichier="$BF"
  at_contient "detache-requis"
  at_fin 64
}

autotest_toutes() {
  local BF cp S1=plugin/a/tests/test-1.sh S2=plugin/b/tests/test-2.sh S3=scripts/tests/test-3.sh S4=plugin/c/tests/test-4.sh
  BF=$AT_TMP/base-toutes.txt
  CANON='echo "== Résultat : 3 OK · 0 KO =="'

  at_debut toutes-detache-requis
  at_depot
  mk_suite $S1 "$CANON"
  MK_BILAN_S=500 mk_base "$BF" "$S1:0:5"
  at_lancer toutes --base-fichier="$BF"
  at_contient "detache-requis"
  at_fin 64

  at_debut toutes-saines
  at_depot
  mk_suite $S1 "$CANON"; mk_suite $S2 "$CANON"
  at_lancer toutes
  at_contient "TOUTES-BILAN suites=2 vertes=2 rouges=0 zero-ok=0"
  at_fin 0

  at_debut toutes-une-rouge
  at_depot
  mk_suite $S1 "$CANON"; mk_suite $S2 "$CANON; exit 1"
  at_lancer toutes
  at_contient "TOUTES-BILAN suites=2 vertes=1 rouges=1 zero-ok=0"
  at_fin 1

  at_debut toutes-vide
  at_depot
  at_lancer toutes
  at_contient "TOUTES-BILAN suites=0"
  at_fin 1

  at_debut toutes-zero-ok
  at_depot
  mk_suite $S1 "$CANON"; mk_suite $S2 "echo '== Résultat : 0 OK · 0 KO =='"
  at_lancer toutes
  at_contient "$S2 rc=0"; at_contient "zero-ok"; at_contient "TOUTES-BILAN suites=2 vertes=1 rouges=1 zero-ok=1"
  at_fin 1

  at_debut toutes-zero-ok-barres
  at_depot
  mk_suite $S1 "echo '== résultat : 0 OK / 0 KO =='"
  at_lancer toutes
  at_contient "zero-ok"; at_contient "TOUTES-BILAN suites=1 vertes=0 rouges=1 zero-ok=1"
  at_fin 1

  at_debut toutes-formes
  at_depot
  mk_suite $S1 "$CANON"
  mk_suite $S2 "echo '== résultat : 3 OK / 0 KO / 1 SKIP =='"
  mk_suite $S3 "echo '== Résultat : 4 OK, 0 KO, 0 SKIP =='"
  mk_suite $S4 "echo '== résultat : 3 passés, 0 échoués =='"
  at_lancer toutes
  at_contient "TOUTES-FORMES canon=1 barres=1 virgules=1 inconnue=1"; at_contient "TOUTES-BILAN suites=4 vertes=4 rouges=0"
  at_fin 0

  at_debut toutes-contre-base
  at_depot
  mk_suite $S1 "$CANON; exit 1"; mk_suite $S2 "$CANON; exit 1"; mk_suite $S3 "$CANON"
  mk_base "$BF" "$S1:1:2" "$S2:0:2" "$S3:0:2"
  at_lancer toutes --contre-base --base-fichier="$BF"
  at_contient "$S1 rc=1"; at_contient "rouge-sur-base=oui"; at_contient "rouge-sur-base=non"
  at_contient "TOUTES-CONTRE-BASE rouges=2 sur-base=1 hors-base=1"
  at_fin 1

  at_debut toutes-contre-base-sans-base
  at_depot
  mk_suite $S1 "$CANON"
  at_lancer toutes --contre-base --base-fichier="$AT_TMP/base-inexistante.txt"
  at_fin 64

  at_debut toutes-base-ecrit
  at_depot
  mk_suite $S1 "$CANON"; mk_suite $S2 "$CANON"
  at_commit
  rm -f "$AT_TMP/base-ecrit.txt"
  at_lancer toutes --base --arbre-intact=HEAD --base-fichier="$AT_TMP/base-ecrit.txt"
  [ "$(awk '$1 == "BASE" { c++ } END { print c + 0 }' "$AT_TMP/base-ecrit.txt")" -eq 2 ] || at_echec "deux lignes BASE attendues"
  [ "$(awk '$1 == "BASE-BILAN" { c++ } END { print c + 0 }' "$AT_TMP/base-ecrit.txt")" -eq 1 ] || at_echec "une BASE-BILAN attendue"
  [ "$(awk '$1 == "BASE-MESURE" && /charge=/ && /cpu=/ { c++ } END { print c + 0 }' "$AT_TMP/base-ecrit.txt")" -eq 1 ] || at_echec "une BASE-MESURE à charge= et cpu= attendue"
  (cd "$FD" && bash "$OUTIL" base-duree $S1 --base-fichier="$AT_TMP/base-ecrit.txt") > /dev/null 2>&1 || at_echec "la base écrite n'est pas relisible"
  at_fin 0

  at_debut toutes-base-existante
  cp "$AT_TMP/base-ecrit.txt" "$AT_TMP/base-ecrit.avant"
  at_lancer toutes --base --arbre-intact=HEAD --base-fichier="$AT_TMP/base-ecrit.txt"
  cmp -s "$AT_TMP/base-ecrit.txt" "$AT_TMP/base-ecrit.avant" || at_echec "la base existante a été modifiée"
  at_fin 64

  at_debut toutes-base-arbre-modifie
  at_depot
  mk_suite $S1 "$CANON"
  at_commit
  echo modif > "$FD/plugin/m/.keep"
  at_lancer toutes --base --arbre-intact=HEAD --base-fichier="$AT_TMP/base-modifie.txt"
  [ ! -e "$AT_TMP/base-modifie.txt" ] || at_echec "une base a été écrite sur un arbre modifié"
  at_contient "ARBRE-NON-INTACT"
  at_fin 64
}

autotest_base() {
  local BF S=plugin/m/tests/test-c.sh CANON='echo "== Résultat : 3 OK · 0 KO =="' avant
  BF=$AT_TMP/base-b.txt
  at_depot

  at_debut base-duree-ok
  mk_base "$BF" "$S:0:7"
  at_lancer base-duree $S --base-fichier="$BF"
  at_contient "BASE-DUREE $S s=7"
  at_fin 0

  at_debut base-duree-absente
  at_lancer base-duree plugin/m/tests/test-inexistante.sh --base-fichier="$BF"
  at_contient "BASE-ABSENTE"
  at_fin 64

  at_debut base-duree-rouge
  mk_base "$BF" "$S:2:3"
  at_lancer base-duree $S --base-fichier="$BF"
  at_contient "BASE-DUREE-NON-FIABLE"
  at_fin 1

  at_debut base-corrompue-bilan
  MK_BILAN_SUITES=3 mk_base "$BF" "$S:0:1" "b.sh:0:1"
  at_lancer base-duree $S --base-fichier="$BF"
  at_contient "BASE-CORROMPUE"
  at_fin 64

  at_debut base-corrompue-doublon
  mk_base "$BF" "$S:0:1" "$S:0:2"
  at_lancer base-duree $S --base-fichier="$BF"
  at_contient "BASE-CORROMPUE doublon"
  at_fin 64

  at_debut base-sans-mesure
  MK_SANS_MESURE=1 mk_base "$BF" "$S:0:1"
  at_lancer base-duree $S --base-fichier="$BF"
  at_contient "BASE-CORROMPUE"
  at_fin 64

  at_debut base-ajout-vert
  mk_base "$BF" "autre.sh:0:2"
  mk_suite $S "$CANON"
  at_lancer suite $S --base-ajout=18 --base-fichier="$BF"
  at_contient "BASE-AJOUT-ECRITE $S"
  [ "$(awk -v c="$S" '$1 == "BASE-AJOUT" && $2 == c && $4 == "plan=18" { n++ } END { print n + 0 }' "$BF")" -eq 1 ] || at_echec "ligne BASE-AJOUT plan=18 absente"
  cp "$BF" "$AT_TMP/base-ajout.avant"
  at_lancer suite $S --base-ajout=18 --base-fichier="$BF"
  [ "$AT_RC" -eq 64 ] || at_echec "second appel : code $AT_RC au lieu de 64"
  cmp -s "$BF" "$AT_TMP/base-ajout.avant" || at_echec "le second appel a modifié la base"
  AT_RC=0
  at_fin 0

  at_debut base-ajout-duree-murale
  mk_base "$BF" "autre.sh:0:2"
  mk_suite $S "echo 'DUREE s=0'; sleep 2; $CANON"
  at_lancer suite $S --base-ajout=18 --base-fichier="$BF"
  avant=$(awk -v c="$S" '$1 == "BASE-AJOUT" && $2 == c { print substr($3, 3) }' "$BF")
  { [ -n "$avant" ] && [ "$avant" -ge 2 ]; } || at_echec "s=${avant:-absent} au lieu d'au moins 2 (durée murale)"
  at_fin 0

  at_debut base-ajout-connue
  mk_base "$BF" "$S:0:2" "+neuve.sh:3:17"
  mk_suite $S "$CANON"
  mk_suite neuve.sh "$CANON"
  cp "$BF" "$AT_TMP/base-connue.avant"
  at_lancer suite $S --base-ajout=18 --base-fichier="$BF"
  [ "$AT_RC" -eq 64 ] || at_echec "BASE : code $AT_RC au lieu de 64"
  at_contient "base-ajout-connue"
  cmp -s "$BF" "$AT_TMP/base-connue.avant" || at_echec "la base a été modifiée (ligne BASE)"
  at_lancer suite neuve.sh --base-ajout=18 --base-fichier="$BF"
  at_contient "base-ajout-connue"
  cmp -s "$BF" "$AT_TMP/base-connue.avant" || at_echec "la base a été modifiée (ligne BASE-AJOUT)"
  at_fin 64

  at_debut base-ajout-rouge
  mk_base "$BF" "autre.sh:0:2"
  mk_suite $S "$CANON; exit 1"
  cp "$BF" "$AT_TMP/base-rouge.avant"
  at_lancer suite $S --base-ajout=18 --base-fichier="$BF"
  cmp -s "$BF" "$AT_TMP/base-rouge.avant" || at_echec "une ligne a été ajoutée pour une suite rouge"
  at_fin 1

  at_debut base-ajout-detache
  mk_base "$BF" "autre.sh:0:2"
  mk_suite $S "$CANON"
  at_lancer suite $S --base-ajout=18 --detache="$AT_TMP/detache-ajout" --base-fichier="$BF"
  at_fin 64
}

autotest() {
  local manquants=0 c j trouve n d m
  nouveau_tmp
  AT_TMP=$NT
  autotest_suite
  autotest_toutes
  autotest_base
  # Cas déclarés contre cas joués : un cas déclaré et non joué est un échec.
  for c in "${CAS_AUTOTEST[@]}"; do
    trouve=0
    for j in ${AT_JOUES[@]+"${AT_JOUES[@]}"}; do
      [ "$j" = "$c" ] && trouve=$((trouve + 1))
    done
    if [ "$trouve" -ne 1 ]; then
      printf 'AUTOTEST-CAS %s déclaré, joué %s fois\n' "$c" "$trouve"
      manquants=$((manquants + 1))
    fi
  done
  for j in ${AT_JOUES[@]+"${AT_JOUES[@]}"}; do
    trouve=0
    for c in "${CAS_AUTOTEST[@]}"; do
      [ "$j" = "$c" ] && trouve=1
    done
    if [ "$trouve" -eq 0 ]; then
      printf 'AUTOTEST-CAS %s joué mais non déclaré\n' "$j"
      manquants=$((manquants + 1))
    fi
  done
  n=${#AT_JOUES[@]}
  d=${#CAS_AUTOTEST[@]}
  m=$((AT_KO + manquants))
  printf 'AUTOTEST-BILAN cas=%s declares=%s echecs=%s\n' "$n" "$d" "$m"
  [ "$m" -eq 0 ] && [ "$n" -eq "$d" ]
}

# ---------------------------------------------------------------------------------------------------------
# Aiguillage
# ---------------------------------------------------------------------------------------------------------
principal() {
  trap nettoyer EXIT
  local mode=${1:-}
  [ $# -eq 0 ] || shift
  case $mode in
    --help | -h) aide; return 0 ;;
    --autotest) autotest; return $? ;;
    suite) cmd_suite "$@"; return $? ;;
    toutes) cmd_toutes "$@"; return $? ;;
    base-duree) cmd_base_duree "$@"; return $? ;;
    *) die_usage "46.1-CONTROLES.sh <suite|toutes|sonder|base-duree|invariants|releve|releve-chaine|--autotest|--help>" ;;
  esac
}

ARGS=()
for a in "$@"; do
  case $a in
    --outil-origine=*) OUTIL_ORIGINE=${a#--outil-origine=} ;;
    --detache-interne=*) DETACHE_INTERNE=${a#--detache-interne=} ;;
    *) ARGS+=("$a") ;;
  esac
done

if [ -n "$DETACHE_INTERNE" ]; then
  ( principal ${ARGS[@]+"${ARGS[@]}"} )
  rc_fin=$?
  printf 'rc=%s fin=%s\n' "$rc_fin" "$(date +%s)" > "$DETACHE_INTERNE/fin.txt.tmp" \
    && mv "$DETACHE_INTERNE/fin.txt.tmp" "$DETACHE_INTERNE/fin.txt"
  exit "$rc_fin"
fi
principal ${ARGS[@]+"${ARGS[@]}"}
exit $?
