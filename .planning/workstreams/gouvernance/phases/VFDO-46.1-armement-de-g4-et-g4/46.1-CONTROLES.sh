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
# INVARIANTS (`invariants --base=<ref>`, <ref> ancêtre de HEAD sinon 64). Écarts `INVARIANT-ECART <motif>` :
# `fichier <chemin>` (VERSION, plugin/.claude-plugin/plugin.json, .claude-plugin/marketplace.json ou
# scripts/tests/test-role-hook-vs-check-agents.sh diffèrent de <ref>, arbre de travail compris) ; `tag <nom>` (un
# tag pointe sur HEAD) ; `role <fonction>` / `role-absente <fonction>` (l'arbre ast, docstring comprise, d'une
# fonction de FONCTIONS_ROLE diffère entre <ref> et l'arbre de travail, corps Python extrait du heredoc
# PY_PLANNING_HOOK_EOF ; une fonction absente de la BASE est une erreur d'usage, 64, jamais un saut silencieux) ;
# `g4-fige <nom>` : dès que la ligne `ARMEMENT_G4 = "armed"  # etape-5` est dans l'arbre de travail, la fermeture
# statique d'evaluer_g4 (puis, transitivement, toute définition de niveau module — fonction, classe, affectation —
# désignée par un ast.Name en lecture dans un élément de la fermeture, les affectations ARMEMENT_* exceptées) doit
# être ast-identique à celle du PREMIER commit de <ref>..HEAD dont le hook porte cette ligne (aucun :
# `g4-fige reference-introuvable`). ARMEMENT_G4 à observe : `INVARIANT g4-fige non-applicable`. Ce que g4-fige ne
# couvre pas : le dispatcher (main, cible_de) et la commande enregistrée, couverts par le banc de G4 en CI et par le
# relevé de l'étape 6 s'il est joué. Lignes `INVARIANT <motif> ok`, puis `INVARIANTS-BILAN ecarts=<n>`.
#
# RELEVÉS (`releve <relevé> --etape=<5|6> [--lab=<lab affiché>]… [--verificateur=<script>]`, défaut
# plugin/planning-core/scripts/verifier-releve.sh). Lignes `RELEVE-COHERENCE ok|ECART <motif>`. Relevé absent ou
# chemin de machine (/Users/, /home/) : écart. Une ligne `REJEU-NON-JOUE …` : conforme s'il ne porte aucune ligne
# `REJEU-ETAPE-`. Rejeu joué : au moins un --lab (sinon 64) ; par lab, exactement une ligne REPOS-AVANT et une
# REPOS-APRES `<lab> processus=0` (repos-absent, repos-doublon, repos-non-nul) ; vérificateur absent ou illisible :
# écart `verificateur-absent`, jamais un vert ; le relevé porte EXACTEMENT une ligne RELEVE-VERDICT identique
# (cmp -s) à la dernière ligne de la sortie fraîche du vérificateur (verdict-absent, verdict-doublon,
# verdict-recopie) ; verdict non-armable : une ligne `## Non armé` et une ligne `ESCALADE-WILLY ` (non-arme-sans-
# section, non-arme-sans-escalade). Les lignes REPOS-* ne sont lues que par l'outil de phase. Aucun lab n'est lu.
# `releve-chaine [--suite=<chemin>]` lance UNE fois la suite du script d'armement (défaut test-verifier-releve.sh,
# R-RELEVE-CHAINE posé en 46.1-18) avec VF_RELEVE_CHAINE_DEPOT=<dossier mktemp>, exige `--exige=R-RELEVE-CHAINE`,
# exactement trois fichiers déposés (chaine-etape-5.md armable, chaine-etape-6.md armable,
# chaine-etape-6-sans-agent.md non-armable), passe `releve` sur chacun (lab '<lab-1>'). Lignes `RELEVE-CHAINE
# <fichier> verdict=<v> coherence=ok|ECART <motif>` et `RELEVE-CHAINE-ECART <motif>`.
#
# REJEU DÉTACHÉ (`suite` et `toutes` par --detache=<dossier>, plus `imputer` en 46.1-17). Le dossier est créé s'il
# n'existe pas et doit être vide (sinon 64). Sans base (hors mesure de la base) ou pour une suite rouge à la base :
# 64. L'outil s'y copie (`outil.sh` : l'original reste librement éditable pendant le rejeu), écrit `commande.txt`
# (mode, options, nombre de suites), `borne.txt` (borne en secondes, calculée AVANT le lancement) et `debut.txt`
# (epoch), lance la copie en arrière-plan sous `nohup`, dans sa propre session (sortie dans `sortie.txt`, pid
# dans `pid.txt`), imprime `DETACHE <dossier> borne=<s>` et rend 0 aussitôt ; la copie écrit `fin.txt`
# (`rc=<n> fin=<epoch>`) EN DERNIER. Borne : suite = 3 × sa durée de base ; `toutes` = 2 × la durée murale de la
# BASE-BILAN ; `imputer` = 9 × durée de base (46.1-17). Exception unique, déclarée : la mesure de la base
# (`toutes --base`) n'a pas de base d'où dériver sa borne ; sa remontée de sondage est la constante
# BORNE_MESURE_BASE, et `commande.txt` porte `exception=mesure-base`. La base est écrite par la copie à
# l'emplacement de l'outil d'origine (option interne --outil-origine), jamais dans le dossier du rejeu. Le code
# de sortie de la copie est celui du mode (un `toutes --base` à suites rouges rend 1 : la base est écrite quand
# même, les rouges y sont des faits préexistants).
#
# SONDER (`sonder <dossier> [--tranche=<s>]`). Attend au plus UNE tranche (défaut 480 s, maximum 540 : au-delà,
# 64) en sondant fin.txt toutes les 5 s. Codes : 0 rejeu terminé et vert (imprime les lignes propres de l'outil
# de sortie.txt — SUITE…, TOUTES…, IMPUTATION…, BASE…, plus `  ✗ ` et `NON TUÉ` — puis `DETACHE-FIN rc=0
# duree=<s>`) ; 1 terminé et rouge (mêmes lignes, `DETACHE-FIN rc=<n> …` : « terminé » n'est jamais « vert », le
# code le dit) ; 2 en cours dans la borne à l'issue de la tranche (`DETACHE-EN-COURS ecoule=<s> borne=<s>` et la
# dernière ligne de progression) : re-sonder ; 3 borne dépassée (`ATTENTE-DEPASSEE ecoule=<s> borne=<s>`) ou rejeu
# mort sans fin.txt (`DETACHE-MORT`) : REMONTER au manager, ne rien tuer, ne rien relancer ; 64 dossier absent ou
# illisible, tranche hors limites. `sonder` ne tue jamais le rejeu ; aucun utilitaire de délai externe n'est employé.
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
  detache-sans-base detache-borne-derivee detache-toutes-borne detache-dossier-non-vide mesure-base-borne
  mesure-base-ecrit-par-la-copie sonder-termine-vert sonder-termine-rouge sonder-en-cours sonder-depasse
  sonder-mort sonder-dossier-absent sonder-tranche-trop-grande
  invariants-sains invariants-role-change invariants-version-change invariants-tag invariants-base-absente
  g4-fige-observe g4-fige-intact g4-fige-helper-change g4-fige-constante-change g4-fige-transitif
  g4-fige-reference-introuvable
  releve-armable-coherent releve-non-arme-coherent releve-non-arme-sans-escalade releve-verdict-recopie-faux
  releve-non-joue releve-non-joue-mais-mesure releve-absent releve-chemin-machine releve-repos-absent
  releve-repos-non-nul releve-verificateur-absent releve-chaine-saine releve-chaine-depot-incomplet
  releve-chaine-verdict-inattendu
  montre-present montre-absent montre-citation-ignoree montre-suite-rouge montre-vide montre-litteral
  montre-tronque montre-sonder
  reel-temoin-role reel-non-tue reel-bilan reel-ko reel-zero-ok
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
MONTRES=()
EV_SHELL=bash
EV_MONTRES=0
SANS_REEL=0

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

# Lignes demandées par --montre (P461-D-16) : pour UN motif, imprime chaque ligne de la sortie complète qui COMMENCE
# par le motif littéral (espaces de tête compris ; aucune expression régulière : un point est un point), sous la
# forme `SUITE-MONTRE <shell> : <ligne telle quelle>`, au plus 50 par motif puis `SUITE-NOTE montre-tronque <motif>
# reste=<n>` ; code 0 si au moins une ligne, 1 sinon. Demander une ligne vaut l'exiger : l'appelant en fait un écart.
montre_lignes() { # <sortie> <motif>
  local c
  c=$(P="$2" LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) == 1 { c++ } END { print c + 0 }' "$1")
  [ "$c" -gt 0 ] || return 1
  P="$2" S="$EV_SHELL" LC_ALL=C awk 'BEGIN { p = ENVIRON["P"]; s = ENVIRON["S"] } index($0, p) == 1 { n++; if (n <= 50) print "SUITE-MONTRE " s " : " $0 }' "$1"
  [ "$c" -le 50 ] || printf 'SUITE-NOTE montre-tronque %s reste=%s\n' "$2" "$((c - 50))"
  return 0
}

# Évalue un lancement : imprime les lignes retenues de la sortie, les SUITE-ECART, pose EV_TROUVES et EV_MONTRES.
evaluer_lancement() { # <sortie> <rc>
  local sortie=$1 rc=$2 derniere r forme n m s k nt lib mot absents
  EV_TROUVES=0
  EV_MONTRES=0
  k=$(LC_ALL=C awk 'index($0, "  ✗ ") == 1 { c++ } END { print c + 0 }' "$sortie")
  nt=$(LC_ALL=C awk 'index($0, "NON TUÉ") > 0 { c++ } END { print c + 0 }' "$sortie")
  derniere=$(derniere_ligne "$sortie")
  LC_ALL=C awk 'index($0, "  ✗ ") == 1 || index($0, "NON TUÉ") > 0' "$sortie"
  printf '%s\n' "$derniere"
  absents=()
  for mot in ${MONTRES[@]+"${MONTRES[@]}"}; do
    if montre_lignes "$sortie" "$mot"; then
      EV_MONTRES=$((EV_MONTRES + 1))
    else
      absents+=("$mot")
    fi
  done
  for mot in ${absents[@]+"${absents[@]}"}; do
    ecart "montre-absent $mot"
  done
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
  local b_kind="" b_rc="" b_s="" b_zero="" rcv plafond ajout_s="" premier=1 base_ok=0 detache="" a borne
  local args_detache=()
  EXIGES=()
  MONTRES=()
  NEC=0
  for a in "$@"; do
    case $a in --detache=*) ;; *) args_detache+=("$a") ;; esac
  done
  while [ $# -gt 0 ]; do
    case $1 in
      --detache=*) detache=${1#--detache=}; [ -n "$detache" ] || die_usage "suite : --detache=<dossier>" ;;
      --exige=*) [ -n "${1#--exige=}" ] || die_usage "--exige=<libellé> non vide"; EXIGES+=("${1#--exige=}") ;;
      --montre=*) [ -n "${1#--montre=}" ] || die_usage "--montre=<motif> non vide"; MONTRES+=("${1#--montre=}") ;;
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
    if [ -n "$detache" ]; then
      echo "SUITE-USAGE --base-ajout et --detache s'excluent : une suite neuve se rejoue au premier plan (si elle n'y tient pas, le plan se scinde et remonte)" >&2
      exit 64
    fi
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
  if [ -n "$detache" ]; then
    # Rejeu détaché : la borne est dérivée de la base, jamais d'ailleurs.
    if [ "$base_ok" -ne 1 ] || [ -z "$b_kind" ]; then
      echo "SUITE-USAGE base-absente $cle : aucun rejeu détaché sans durée de base (aucune borne inventée)" >&2
      exit 64
    fi
    if [ "$b_rc" -ne 0 ] || [ "$b_zero" -ne 0 ]; then
      echo "SUITE-USAGE base-rouge $cle : suite rouge à la base, sa durée n'est pas une mesure" >&2
      exit 64
    fi
    borne=$((b_s * FACTEUR_SUITE))
    [ "$borne" -ge 1 ] || borne=1
    detacher "$detache" "$borne" - 1 suite ${args_detache[@]+"${args_detache[@]}"}
    return $?
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
    EV_SHELL=$sh
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
    printf 'SUITE %s shell=%s rc=%s duree=%s exiges=%s/%s montres=%s/%s\n' "$suite" "$sh" "$L_RC" "$L_DUREE" "$EV_TROUVES" "${#EXIGES[@]}" "$EV_MONTRES" "${#MONTRES[@]}"
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
# Mode invariants
# ---------------------------------------------------------------------------------------------------------
HOOK_REL=plugin/planning-core/scripts/planning-hook.sh
LIGNE_G4_ARME='ARMEMENT_G4 = "armed"  # etape-5'
FONCTIONS_ROLE="evaluer_role resoudre_agent _choisir_definition definitions_dossier definitions_plugin versions_actives dossiers_agents_version candidat_definition lire_definition_agent deriver_role"

# Python embarqué (python3 -I -S) : extraction du corps du hook (heredoc PY_PLANNING_HOOK_EOF) et comparaison
# ast. Modes : `roles <base.sh> <travail.sh> <fonction>…` et `g4 <armement.sh> <travail.sh>`.
# Sorties : lignes `ECART <motif> [<nom>]` ; code 0, 3 (fonction absente de la base : usage), 4 (hook illisible).
ecrire_py_invariants() { # <fichier>
  cat > "$1" <<'PY_INVARIANTS_EOF'
import ast
import sys


def corps(chemin):
    lignes = open(chemin, encoding="utf-8").read().split("\n")
    debut = None
    for i, ligne in enumerate(lignes):
        if ligne.endswith("<<'PY_PLANNING_HOOK_EOF'"):
            debut = i + 1
            break
    if debut is None:
        return None
    for j in range(debut, len(lignes)):
        if lignes[j] == "PY_PLANNING_HOOK_EOF":
            return "\n".join(lignes[debut:j]) + "\n"
    return None


def charger(chemin):
    texte = corps(chemin)
    if texte is None:
        raise ValueError("heredoc PY_PLANNING_HOOK_EOF introuvable dans " + chemin)
    return ast.parse(texte)


def definitions(arbre):
    d = {}
    for n in arbre.body:
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            d.setdefault(n.name, []).append(n)
        elif isinstance(n, ast.Assign):
            for t in n.targets:
                for x in ast.walk(t):
                    if isinstance(x, ast.Name) and isinstance(x.ctx, ast.Store):
                        d.setdefault(x.id, []).append(n)
        elif isinstance(n, ast.AnnAssign) and isinstance(n.target, ast.Name):
            d.setdefault(n.target.id, []).append(n)
    return d


def empreinte(d, nom):
    return [ast.dump(n) for n in d.get(nom, [])]


def fermeture(d, racine):
    vus = []
    file = [racine]
    while file:
        nom = file.pop()
        if nom in vus or nom not in d:
            continue
        vus.append(nom)
        for n in d[nom]:
            for x in ast.walk(n):
                if isinstance(x, ast.Name) and isinstance(x.ctx, ast.Load):
                    c = x.id
                    if c in d and c not in vus and not c.startswith("ARMEMENT_"):
                        file.append(c)
    return vus


def main():
    mode = sys.argv[1]
    try:
        a = definitions(charger(sys.argv[2]))
        b = definitions(charger(sys.argv[3]))
    except (OSError, ValueError, SyntaxError) as e:
        print("ILLISIBLE " + str(e))
        return 4
    if mode == "roles":
        absente = False
        for nom in sys.argv[4:]:
            if not any(isinstance(n, ast.FunctionDef) for n in a.get(nom, [])):
                print("ABSENTE-BASE " + nom)
                absente = True
        if absente:
            return 3
        for nom in sys.argv[4:]:
            if not any(isinstance(n, ast.FunctionDef) for n in b.get(nom, [])):
                print("ECART role-absente " + nom)
            elif empreinte(a, nom) != empreinte(b, nom):
                print("ECART role " + nom)
        return 0
    if mode == "g4":
        if "evaluer_g4" not in a or "evaluer_g4" not in b:
            print("ECART g4-fige evaluer_g4")
            return 0
        noms = sorted(set(fermeture(a, "evaluer_g4")) | set(fermeture(b, "evaluer_g4")))
        for nom in noms:
            if empreinte(a, nom) != empreinte(b, nom):
                print("ECART g4-fige " + nom)
        return 0
    print("ILLISIBLE mode " + mode)
    return 4


sys.exit(main())
PY_INVARIANTS_EOF
}

cmd_invariants() {
  local ref="" t f n=0 sortie rcp c commit_arme="" arme=0
  while [ $# -gt 0 ]; do
    case $1 in
      --base=*) ref=${1#--base=} ;;
      *) die_usage "invariants --base=<ref>" ;;
    esac
    shift
  done
  [ -n "$ref" ] || die_usage "invariants --base=<ref>"
  racine_ou_sortir
  if ! git merge-base --is-ancestor "$ref" HEAD > /dev/null 2>&1; then
    echo "INVARIANT-USAGE base inconnue ou non ancêtre de HEAD : $ref" >&2
    exit 64
  fi
  nouveau_tmp
  t=$NT
  ecrire_py_invariants "$t/inv.py"

  # Fichiers de version et suite de non-régression du hook par rôle (arbre de travail compris).
  # shellcheck disable=SC2086
  f=$(git diff --name-only "$ref" -- $INVARIANTS_FICHIERS)
  if [ -n "$f" ]; then
    while IFS= read -r c; do
      printf 'INVARIANT-ECART fichier %s\n' "$c"
      n=$((n + 1))
    done <<EOF
$f
EOF
  else
    echo "INVARIANT fichier ok"
  fi

  # Aucun tag ne pointe sur HEAD.
  f=$(git tag --points-at HEAD)
  if [ -n "$f" ]; then
    while IFS= read -r c; do
      printf 'INVARIANT-ECART tag %s\n' "$c"
      n=$((n + 1))
    done <<EOF
$f
EOF
  else
    echo "INVARIANT tag ok"
  fi

  # Résolution d'agent du hook par rôle : fonctions ast-identiques à la base.
  if ! git show "$ref:$HOOK_REL" > "$t/base.sh" 2> /dev/null; then
    echo "INVARIANT-USAGE $HOOK_REL absent de $ref" >&2
    exit 64
  fi
  if [ ! -f "$HOOK_REL" ]; then
    echo "INVARIANT-ECART role-absente $HOOK_REL"
    n=$((n + 1))
  else
    # shellcheck disable=SC2086
    sortie=$(python3 -I -S "$t/inv.py" roles "$t/base.sh" "$HOOK_REL" $FONCTIONS_ROLE)
    rcp=$?
    case $rcp in
      0) ;;
      3) printf '%s\n' "$sortie" | sed 's/^/INVARIANT-USAGE fonction absente de la base : /; s/ABSENTE-BASE //' >&2; exit 64 ;;
      *) printf 'INVARIANT-ECART hook-illisible %s\n' "$sortie"; n=$((n + 1)); sortie="" ;;
    esac
    if [ -n "$sortie" ]; then
      while IFS= read -r c; do
        printf 'INVARIANT-%s\n' "$c"
        n=$((n + 1))
      done <<EOF
$sortie
EOF
    elif [ "$rcp" -eq 0 ]; then
      echo "INVARIANT role ok"
    fi
  fi

  # Règle g4-fige : dès que ARMEMENT_G4 vaut armed, la fermeture statique d'evaluer_g4 est ast-identique à celle du
  # commit qui a armé G4. Ne couvre pas le dispatcher (main, cible_de) ni la commande enregistrée : couverts par le
  # banc de G4 en CI et par le relevé de l'étape 6 s'il est joué.
  if [ -f "$HOOK_REL" ] && L="$LIGNE_G4_ARME" awk 'BEGIN { l = ENVIRON["L"] } $0 == l { f = 1 } END { exit f ? 0 : 1 }' "$HOOK_REL"; then
    arme=1
  fi
  if [ "$arme" -eq 0 ]; then
    echo "INVARIANT g4-fige non-applicable"
  else
    for c in $(git rev-list --reverse "$ref..HEAD" -- "$HOOK_REL"); do
      if git show "$c:$HOOK_REL" 2> /dev/null | L="$LIGNE_G4_ARME" awk 'BEGIN { l = ENVIRON["L"] } $0 == l { f = 1 } END { exit f ? 0 : 1 }'; then
        commit_arme=$c
        break
      fi
    done
    if [ -z "$commit_arme" ]; then
      echo "INVARIANT-ECART g4-fige reference-introuvable"
      n=$((n + 1))
    else
      git show "$commit_arme:$HOOK_REL" > "$t/arme.sh"
      sortie=$(python3 -I -S "$t/inv.py" g4 "$t/arme.sh" "$HOOK_REL")
      rcp=$?
      if [ "$rcp" -ne 0 ]; then
        printf 'INVARIANT-ECART hook-illisible %s\n' "$sortie"
        n=$((n + 1))
      elif [ -n "$sortie" ]; then
        while IFS= read -r c; do
          printf 'INVARIANT-%s\n' "$c"
          n=$((n + 1))
        done <<EOF
$sortie
EOF
      else
        echo "INVARIANT g4-fige ok"
      fi
    fi
  fi
  printf 'INVARIANTS-BILAN ecarts=%s\n' "$n"
  [ "$n" -eq 0 ]
}

# ---------------------------------------------------------------------------------------------------------
# Modes releve et releve-chaine
# ---------------------------------------------------------------------------------------------------------
VERIFICATEUR_DEFAUT=plugin/planning-core/scripts/verifier-releve.sh
RC_NEC=0
RC_VERDICT=""
RLABS=()

rc_ecart() {
  printf 'RELEVE-COHERENCE ECART %s\n' "$*"
  RC_NEC=$((RC_NEC + 1))
}

# Nombre de lignes de <fichier> qui commencent par <préfixe> (littéral).
compter_prefixe() { # <fichier> <préfixe>
  P="$2" LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) == 1 { c++ } END { print c + 0 }' "$1"
}

# Cohérence d'un relevé de rejeu avec la décision fraîche du script d'armement. UNE fonction : le mode `armement`
# de 46.1-17 la réutilise (aucune copie de logique). Aucun lab n'est lu. Entrées : <relevé> <étape> <vérificateur>,
# labs affichés dans RLABS. Imprime les lignes RELEVE-COHERENCE ; pose RC_VERDICT (premier mot du verdict frais).
# Retour : 0 cohérent, 1 écart, 64 usage (rejeu joué sans --lab). Ce mode ne dit jamais qu'un gate s'arme : il dit
# que le relevé reproduit fidèlement la décision du script.
releve_coherence() {
  local f=$1 etape=$2 verif=$3 lab moment pref lignes nb v t fraiche attendue args nj ne
  RC_NEC=0
  RC_VERDICT=""
  if [ ! -f "$f" ]; then
    rc_ecart "absent"
    return 1
  fi
  if LC_ALL=C awk 'index($0, "/Users/") || index($0, "/home/") { f = 1 } END { exit f ? 0 : 1 }' "$f"; then
    rc_ecart "chemin-machine"
  fi
  nj=$(compter_prefixe "$f" "REJEU-NON-JOUE ")
  ne=$(compter_prefixe "$f" "REJEU-ETAPE-")
  if [ "$nj" -gt 0 ]; then
    # Rejeu refusé ou non lancé, consigné : conforme s'il ne porte aucune mesure.
    [ "$ne" -eq 0 ] || rc_ecart "non-joue-mais-mesure"
    [ "$RC_NEC" -ne 0 ] || echo "RELEVE-COHERENCE ok"
    [ "$RC_NEC" -eq 0 ]
    return $?
  fi
  if [ "${#RLABS[@]}" -eq 0 ]; then
    echo "RELEVE-USAGE un rejeu joué exige au moins un --lab" >&2
    return 64
  fi
  # Repos : exactement une ligne avant et une après par lab, à processus=0.
  for lab in "${RLABS[@]}"; do
    for moment in AVANT APRES; do
      pref="REPOS-$moment $lab processus="
      lignes=$(P="$pref" LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) == 1 { print substr($0, length(p) + 1) }' "$f")
      if [ -z "$lignes" ]; then nb=0; else nb=$(printf '%s\n' "$lignes" | awk 'END { print NR }'); fi
      if [ "$nb" -eq 0 ]; then
        rc_ecart "repos-absent $lab $moment"
      elif [ "$nb" -gt 1 ]; then
        rc_ecart "repos-doublon $lab $moment"
      else
        set -- $lignes
        v=$1
        [ "$v" = 0 ] || rc_ecart "repos-non-nul $lab $moment n=$v"
      fi
    done
  done
  # Vérificateur : jamais un vert sans lui.
  if [ ! -r "$verif" ] || [ ! -f "$verif" ]; then
    rc_ecart "verificateur-absent"
  else
    nouveau_tmp
    t=$NT
    args=(--etape="$etape")
    for lab in "${RLABS[@]}"; do args+=(--lab="$lab"); done
    bash "$verif" "${args[@]}" "$f" > "$t/frais.txt" 2> /dev/null < /dev/null
    derniere_ligne "$t/frais.txt" > "$t/frais-verdict.txt"
    fraiche=$(cat "$t/frais-verdict.txt")
    case $fraiche in
      "RELEVE-VERDICT "*) ;;
      *) rc_ecart "verificateur-sortie" ;;
    esac
    case $fraiche in
      "RELEVE-VERDICT "*)
        nb=$(compter_prefixe "$f" "RELEVE-VERDICT ")
        if [ "$nb" -eq 0 ]; then
          rc_ecart "verdict-absent"
        elif [ "$nb" -gt 1 ]; then
          rc_ecart "verdict-doublon"
        else
          LC_ALL=C awk 'index($0, "RELEVE-VERDICT ") == 1' "$f" > "$t/releve-verdict.txt"
          cmp -s "$t/releve-verdict.txt" "$t/frais-verdict.txt" || rc_ecart "verdict-recopie"
        fi
        set -- $fraiche
        RC_VERDICT=${2:-}
        if [ "$RC_VERDICT" = non-armable ]; then
          [ "$(compter_prefixe "$f" "## Non armé")" -gt 0 ] || rc_ecart "non-arme-sans-section"
          [ "$(compter_prefixe "$f" "ESCALADE-WILLY ")" -gt 0 ] || rc_ecart "non-arme-sans-escalade"
        fi ;;
    esac
  fi
  [ "$RC_NEC" -ne 0 ] || echo "RELEVE-COHERENCE ok"
  [ "$RC_NEC" -eq 0 ]
}

cmd_releve() {
  local f="" etape="" verif="" rc
  RLABS=()
  while [ $# -gt 0 ]; do
    case $1 in
      --etape=*) etape=${1#--etape=} ;;
      --lab=*) RLABS+=("${1#--lab=}") ;;
      --verificateur=*) verif=${1#--verificateur=} ;;
      -*) die_usage "releve : option inconnue : $1" ;;
      *) [ -z "$f" ] || die_usage "releve <relevé> --etape=<5|6>"; f=$1 ;;
    esac
    shift
  done
  [ -n "$f" ] || die_usage "releve <relevé> --etape=<5|6> [--lab=<lab>]… [--verificateur=<script>]"
  case $etape in 5 | 6) ;; *) die_usage "releve : --etape=5 ou --etape=6" ;; esac
  racine_ou_sortir
  [ -n "$verif" ] || verif=$VERIFICATEUR_DEFAUT
  releve_coherence "$f" "$etape" "$verif"
  rc=$?
  [ "$rc" -ne 64 ] || exit 64
  return "$rc"
}

# releve-chaine : la suite du script d'armement dépose les relevés qu'elle compose sur la vraie chaîne synthétique
# (rejeu-reel.sh -> relevé -> verifier-releve.sh) ; ils passent chacun par le contrôle de cohérence de `releve`.
cmd_releve_chaine() {
  local suite=plugin/planning-core/scripts/tests/test-verifier-releve.sh verif="" depot t ec=0 nom f rc exp etape coh att
  RLABS=()
  while [ $# -gt 0 ]; do
    case $1 in
      --suite=*) suite=${1#--suite=} ;;
      --verificateur=*) verif=${1#--verificateur=} ;;
      *) die_usage "releve-chaine [--suite=<chemin>]" ;;
    esac
    shift
  done
  racine_ou_sortir
  [ -n "$verif" ] || verif=$VERIFICATEUR_DEFAUT
  if [ ! -f "$suite" ]; then
    echo "RELEVE-CHAINE-ECART suite-absente $suite (R-RELEVE-CHAINE : posée par 46.1-03 et 46.1-18)"
    return 1
  fi
  nouveau_tmp
  t=$NT
  depot=$t/depot
  mkdir -p "$depot"
  EXIGES=("R-RELEVE-CHAINE")
  NEC=0
  LANCER_ENV_EXTRA="VF_RELEVE_CHAINE_DEPOT=$depot" lancer_suite "$suite" bash "$t/sortie.txt"
  evaluer_lancement "$t/sortie.txt" "$L_RC"
  printf 'SUITE %s shell=bash rc=%s duree=%s exiges=%s/1\n' "$suite" "$L_RC" "$L_DUREE" "$EV_TROUVES"
  if [ "$NEC" -ne 0 ]; then
    echo "RELEVE-CHAINE-ECART suite-non-saine"
    ec=$((ec + 1))
  fi
  for nom in $(ls -A "$depot"); do
    case $nom in
      chaine-etape-5.md | chaine-etape-6.md | chaine-etape-6-sans-agent.md) ;;
      *) echo "RELEVE-CHAINE-ECART depot-inattendu $nom"; ec=$((ec + 1)) ;;
    esac
  done
  for exp in "chaine-etape-5.md:5:armable" "chaine-etape-6.md:6:armable" "chaine-etape-6-sans-agent.md:6:non-armable"; do
    IFS=: read -r nom etape att <<EOF
$exp
EOF
    f=$depot/$nom
    if [ ! -f "$f" ]; then
      echo "RELEVE-CHAINE-ECART depot-incomplet $nom"
      ec=$((ec + 1))
      continue
    fi
    RLABS=("<lab-1>")
    releve_coherence "$f" "$etape" "$verif" > "$t/coh.txt"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      coh=ok
    else
      coh="ECART $(awk 'index($0, "RELEVE-COHERENCE ECART ") == 1 { print substr($0, 24); exit }' "$t/coh.txt")"
      ec=$((ec + 1))
    fi
    printf 'RELEVE-CHAINE %s verdict=%s coherence=%s\n' "$nom" "${RC_VERDICT:-inconnu}" "$coh"
    if [ "$RC_VERDICT" != "$att" ]; then
      echo "RELEVE-CHAINE-ECART verdict-inattendu $nom attendu=$att obtenu=${RC_VERDICT:-inconnu}"
      ec=$((ec + 1))
    fi
  done
  [ "$ec" -eq 0 ]
}

# ---------------------------------------------------------------------------------------------------------
# Rejeu détaché (suite, toutes) et sonder
# ---------------------------------------------------------------------------------------------------------
# detacher <dossier> <borne> <exception|-> <nombre de suites> <mode> [args…]
# Le dossier est créé s'il n'existe pas et doit être vide (sinon 64). L'outil s'y copie (outil.sh : l'original
# reste librement éditable pendant le rejeu), écrit commande.txt, borne.txt (calculée AVANT le lancement) et
# debut.txt, lance la copie en arrière-plan sous nohup, dans sa propre session (sortie dans sortie.txt, pid dans
# pid.txt), imprime `DETACHE <dossier> borne=<s>` et rend 0 aussitôt. La copie écrit fin.txt
# (`rc=<n> fin=<epoch>`) EN DERNIER. C'est le SEUL lancement en arrière-plan de l'outil.
detacher() {
  local d=$1 borne=$2 exc=$3 nsuites=$4 mode=$5 pid
  shift 5
  if [ -e "$d" ]; then
    [ -d "$d" ] || { echo "DETACHE-USAGE $d n'est pas un dossier" >&2; return 64; }
    if [ -n "$(ls -A "$d" 2>/dev/null)" ]; then
      echo "DETACHE-USAGE dossier non vide : $d" >&2
      return 64
    fi
  else
    mkdir -p "$d" || { echo "DETACHE-USAGE dossier impossible : $d" >&2; return 64; }
  fi
  d=$(cd "$d" && pwd -P) || return 64
  cp "$OUTIL" "$d/outil.sh" || return 64
  {
    echo "mode=$mode"
    echo "options=$*"
    echo "suites=$nsuites"
    [ "$exc" = - ] || echo "exception=$exc"
  } > "$d/commande.txt"
  printf '%s\n' "$borne" > "$d/borne.txt"
  date +%s > "$d/debut.txt"
  pid=$(python3 -I -S -c '
import os, subprocess, sys
d, racine, origine, mode = sys.argv[1:5]
args = sys.argv[5:]
sortie = open(os.path.join(d, "sortie.txt"), "wb")
p = subprocess.Popen(
    ["nohup", "bash", os.path.join(d, "outil.sh"), mode] + args
    + ["--outil-origine=" + origine, "--detache-interne=" + d],
    cwd=racine, stdin=subprocess.DEVNULL, stdout=sortie, stderr=subprocess.STDOUT,
    start_new_session=True, close_fds=True)
print(p.pid)
' "$d" "$RACINE" "$OUTIL_ORIGINE" "$mode" "$@") || { echo "DETACHE-USAGE lancement impossible" >&2; return 64; }
  printf '%s\n' "$pid" > "$d/pid.txt"
  printf 'DETACHE %s borne=%s\n' "$d" "$borne"
  return 0
}

# sonder <dossier> [--tranche=<s>] : attend au plus UNE tranche. 0 terminé et vert · 1 terminé et rouge ·
# 2 en cours dans la borne · 3 borne dépassée ou rejeu mort (REMONTER, ne rien tuer, ne rien relancer) ·
# 64 usage. Ne tue jamais le rejeu.
cmd_sonder() {
  local d="" tranche=$TRANCHE_DEFAUT borne debut pid fin_ligne rc_fin fin_ep t_dep now ecoule pas rest restr
  while [ $# -gt 0 ]; do
    case $1 in
      --tranche=*) tranche=${1#--tranche=} ;;
      -*) die_usage "sonder : option inconnue : $1" ;;
      *) [ -z "$d" ] || die_usage "sonder <dossier>"; d=$1 ;;
    esac
    shift
  done
  [ -n "$d" ] || die_usage "sonder <dossier> [--tranche=<s>]"
  case $tranche in '' | *[!0-9]*) die_usage "sonder : --tranche=<secondes>" ;; esac
  if [ "$tranche" -lt 1 ] || [ "$tranche" -gt "$TRANCHE_MAX" ]; then
    echo "SONDER-USAGE tranche $tranche hors de 1..$TRANCHE_MAX (la commande Bash de l'exécuteur plafonne à 10 min)" >&2
    exit 64
  fi
  if [ ! -d "$d" ] || [ ! -r "$d/borne.txt" ] || [ ! -r "$d/debut.txt" ]; then
    echo "SONDER-USAGE dossier absent ou illisible : $d" >&2
    exit 64
  fi
  borne=$(cat "$d/borne.txt")
  debut=$(cat "$d/debut.txt")
  case $borne$debut in '' | *[!0-9]*) echo "SONDER-USAGE borne.txt ou debut.txt illisible" >&2; exit 64 ;; esac
  t_dep=$(date +%s)
  while :; do
    if [ -f "$d/fin.txt" ]; then
      fin_ligne=$(cat "$d/fin.txt")
      rc_fin=${fin_ligne#rc=}
      rc_fin=${rc_fin%% *}
      fin_ep=${fin_ligne##*fin=}
      LC_ALL=C awk '/^(SUITE|TOUTES|IMPUTATION|BASE|ARBRE-)/ || index($0, "  ✗ ") == 1 || index($0, "NON TUÉ") > 0' "$d/sortie.txt" 2>/dev/null
      printf 'DETACHE-FIN rc=%s duree=%s\n' "$rc_fin" "$((fin_ep - debut))"
      [ "$rc_fin" = 0 ]
      return $?
    fi
    now=$(date +%s)
    ecoule=$((now - debut))
    if [ "$ecoule" -gt "$borne" ]; then
      printf 'ATTENTE-DEPASSEE ecoule=%s borne=%s\n' "$ecoule" "$borne"
      printf 'DETACHE-PROGRES %s\n' "$(derniere_ligne "$d/sortie.txt" 2>/dev/null)"
      return 3
    fi
    pid=""
    [ -r "$d/pid.txt" ] && pid=$(cat "$d/pid.txt")
    if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
      sleep 1
      if [ -f "$d/fin.txt" ]; then
        continue
      fi
      printf 'DETACHE-MORT pid=%s ecoule=%s borne=%s\n' "$pid" "$ecoule" "$borne"
      printf 'DETACHE-PROGRES %s\n' "$(derniere_ligne "$d/sortie.txt" 2>/dev/null)"
      return 3
    fi
    if [ $((now - t_dep)) -ge "$tranche" ]; then
      printf 'DETACHE-EN-COURS ecoule=%s borne=%s\n' "$ecoule" "$borne"
      printf 'DETACHE-PROGRES %s\n' "$(derniere_ligne "$d/sortie.txt" 2>/dev/null)"
      return 2
    fi
    pas=$PAS_SONDE
    rest=$((borne - ecoule + 1))
    [ "$rest" -ge 1 ] || rest=1
    [ "$rest" -ge "$pas" ] || pas=$rest
    restr=$((tranche - (now - t_dep)))
    [ "$restr" -ge 1 ] || restr=1
    [ "$restr" -ge "$pas" ] || pas=$restr
    sleep "$pas"
  done
}

# ---------------------------------------------------------------------------------------------------------
# Mode toutes
# ---------------------------------------------------------------------------------------------------------
INVARIANTS_FICHIERS="VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json scripts/tests/test-role-hook-vs-check-agents.sh"
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
  local t0 t1 charge_debut charge_fin sur=0 hors=0 annot kind brc bsx bz detache="" a borne
  local args_detache=()
  for a in "$@"; do
    case $a in --detache=*) ;; *) args_detache+=("$a") ;; esac
  done
  while [ $# -gt 0 ]; do
    case $1 in
      --base) base=1 ;;
      --contre-base) contre=1 ;;
      --detache=*) detache=${1#--detache=}; [ -n "$detache" ] || die_usage "toutes : --detache=<dossier>" ;;
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
    if [ "$base_ok" -eq 1 ] && [ -z "$detache" ]; then
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

  if [ -n "$detache" ]; then
    # Rejeu détaché. Borne : 2 × la durée murale de la BASE-BILAN, jamais d'ailleurs ; exception unique, la
    # mesure de la base elle-même (aucune base d'où dériver sa borne) : BORNE_MESURE_BASE.
    if [ "$base" -eq 1 ]; then
      detacher "$detache" "$BORNE_MESURE_BASE" mesure-base "${#suites[@]}" toutes ${args_detache[@]+"${args_detache[@]}"}
      return $?
    fi
    if [ "$base_ok" -ne 1 ]; then
      echo "TOUTES-USAGE base-absente : aucun rejeu détaché sans durée de base (aucune borne inventée)" >&2
      exit 64
    fi
    borne=$(( $(base_bilan_s) * FACTEUR_TOUTES ))
    [ "$borne" -ge 1 ] || borne=1
    detacher "$detache" "$borne" - "${#suites[@]}" toutes ${args_detache[@]+"${args_detache[@]}"}
    return $?
  fi

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
AT_RACINE=""
SB=""
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
  # Isolation : sans --base-fichier explicite, un cas qui lit la base ne doit jamais lire la VRAIE base de la
  # phase (posée à côté de l'outil) : il reçoit un fichier de base inexistant.
  local extra=()
  case $1 in
    suite | toutes | base-duree)
      case " $* " in
        *" --base-fichier="*) ;;
        *) extra=(--base-fichier="$AT_TMP/aucune-base.txt") ;;
      esac ;;
  esac
  AT_OUT="$AT_TMP/out.$AT_N.$RANDOM"
  (cd "$AT_CWD" && bash "$OUTIL" "$@" ${extra[@]+"${extra[@]}"}) > "$AT_OUT" 2>&1 < /dev/null
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
  (cd "$AT_CWD" && VF_PF_SECTIONS=x VF_PF_MUT=y VF_RELEVE_CHAINE_DEPOT=z bash "$OUTIL" suite $S --base-fichier="$AT_TMP/aucune-base.txt")> "$AT_OUT" 2>&1 < /dev/null
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

at_attendre_fin() { # <dossier> <max s> : attend fin.txt (borné, dans l'autotest seulement)
  local i=0
  while [ ! -f "$1/fin.txt" ] && [ "$i" -lt "$2" ]; do
    sleep 1
    i=$((i + 1))
  done
  [ -f "$1/fin.txt" ]
}

at_fichier_contient() { # <fichier> <motif fixe>
  P="$2" LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) { f = 1 } END { exit f ? 0 : 1 }' "$1" 2> /dev/null \
    || at_echec "$(basename "$1") sans « $2 »"
}

autotest_detache() {
  local BF D1 D2 D3 D4 D5 D6 D7 S=plugin/m/tests/test-c.sh dead
  local CANON='echo "== Résultat : 3 OK · 0 KO =="'
  BF=$AT_TMP/base-d.txt
  at_depot

  at_debut detache-sans-base
  mk_suite $S "$CANON"
  mk_base "$BF" "autre.sh:0:2"
  at_lancer suite $S --detache="$AT_TMP/d-sans" --base-fichier="$BF"
  at_contient "base-absente"
  [ ! -e "$AT_TMP/d-sans/outil.sh" ] || at_echec "un rejeu a été lancé sans base"
  at_fin 64

  at_debut detache-borne-derivee
  mk_base "$BF" "$S:0:4"
  mk_suite $S "sleep 1; $CANON"
  D1=$AT_TMP/d-borne
  at_lancer suite $S --detache="$D1" --base-fichier="$BF"
  at_compte "DETACHE " 1
  [ "$(cat "$D1/borne.txt" 2> /dev/null)" = 12 ] || at_echec "borne.txt vaut « $(cat "$D1/borne.txt" 2> /dev/null) » au lieu de 12 (3 × 4)"
  cmp -s "$D1/outil.sh" "$OUTIL" || at_echec "outil.sh diffère de l'outil"
  if at_attendre_fin "$D1" 60; then
    [ -f "$D1/pid.txt" ] && [ -f "$D1/debut.txt" ] && [ -f "$D1/commande.txt" ] || at_echec "fichiers du rejeu manquants quand fin.txt existe"
    at_fichier_contient "$D1/sortie.txt" "SUITE $S shell=bash rc=0"
    at_fichier_contient "$D1/fin.txt" "rc=0 fin="
  else
    at_echec "fin.txt n'est jamais apparu"
  fi
  at_fin 0

  at_debut detache-toutes-borne
  MK_BILAN_S=7 mk_base "$BF" "$S:0:2"
  D2=$AT_TMP/d-toutes
  at_lancer toutes --detache="$D2" --base-fichier="$BF"
  [ "$(cat "$D2/borne.txt" 2> /dev/null)" = 14 ] || at_echec "borne.txt vaut « $(cat "$D2/borne.txt" 2> /dev/null) » au lieu de 14 (2 × 7)"
  at_fichier_contient "$D2/commande.txt" "mode=toutes"
  at_attendre_fin "$D2" 60 || at_echec "fin.txt n'est jamais apparu"
  at_fin 0

  at_debut detache-dossier-non-vide
  mk_base "$BF" "$S:0:4"
  mkdir -p "$AT_TMP/d-plein"
  : > "$AT_TMP/d-plein/occupe"
  at_lancer suite $S --detache="$AT_TMP/d-plein" --base-fichier="$BF"
  at_fin 64

  at_debut mesure-base-borne
  at_depot
  mk_suite $S "$CANON"
  at_commit
  D3=$AT_TMP/d-mesure
  rm -f "$AT_TMP/base-mesure.txt"
  at_lancer toutes --base --detache="$D3" --arbre-intact=HEAD --base-fichier="$AT_TMP/base-mesure.txt"
  [ "$(cat "$D3/borne.txt" 2> /dev/null)" = "$BORNE_MESURE_BASE" ] || at_echec "borne.txt vaut « $(cat "$D3/borne.txt" 2> /dev/null) » au lieu de $BORNE_MESURE_BASE"
  at_fichier_contient "$D3/commande.txt" "exception=mesure-base"
  if at_attendre_fin "$D3" 60; then
    [ -f "$AT_TMP/base-mesure.txt" ] || at_echec "la base n'a pas été écrite"
  else
    at_echec "fin.txt n'est jamais apparu"
  fi
  at_fin 0

  at_debut mesure-base-ecrit-par-la-copie
  at_depot
  mk_suite $S "$CANON"
  at_commit
  cp "$OUTIL" "$FD/phase/46.1-CONTROLES.sh"
  D4=$AT_TMP/d-copie
  AT_OUT="$AT_TMP/out.copie"
  (cd "$FD" && bash "$FD/phase/46.1-CONTROLES.sh" toutes --base --detache="$D4" --arbre-intact=HEAD) > "$AT_OUT" 2>&1 < /dev/null
  AT_RC=$?
  if at_attendre_fin "$D4" 60; then
    [ -f "$FD/phase/46.1-BASE.txt" ] || at_echec "la base n'est pas à côté de l'outil d'origine"
    [ ! -e "$D4/46.1-BASE.txt" ] || at_echec "la base a été écrite dans le dossier de la copie"
  else
    at_echec "fin.txt n'est jamais apparu"
  fi
  at_fin 0

  at_debut sonder-termine-vert
  at_lancer sonder "$D1"
  at_contient "DETACHE-FIN rc=0"; at_contient "SUITE $S shell=bash rc=0"
  at_fin 0

  at_debut sonder-termine-rouge
  at_depot
  mk_suite $S "echo '  ✗ x'; $CANON; exit 1"
  mk_base "$BF" "$S:0:2"
  D5=$AT_TMP/d-rouge
  at_lancer suite $S --detache="$D5" --base-fichier="$BF"
  at_attendre_fin "$D5" 60 || at_echec "fin.txt n'est jamais apparu"
  at_lancer sonder "$D5"
  at_contient "SUITE-ECART rc 1"; at_contient "DETACHE-FIN rc=1"; at_contient "  ✗ x"
  at_fin 1

  at_debut sonder-en-cours
  mk_suite $S "sleep 10; $CANON"
  mk_base "$BF" "$S:0:20"
  D6=$AT_TMP/d-cours
  at_lancer suite $S --detache="$D6" --base-fichier="$BF"
  at_lancer sonder "$D6" --tranche=2
  at_contient "DETACHE-EN-COURS"
  at_attendre_fin "$D6" 60 || at_echec "le rejeu en cours n'a pas fini (il ne doit jamais être tué)"
  at_fin 2

  at_debut sonder-depasse
  mk_suite $S "sleep 6; $CANON"
  mk_base "$BF" "$S:0:5"
  D7=$AT_TMP/d-depasse
  at_lancer suite $S --detache="$D7" --base-fichier="$BF"
  printf '1\n' > "$D7/borne.txt"
  at_lancer sonder "$D7"
  at_contient "ATTENTE-DEPASSEE"
  if at_attendre_fin "$D7" 60; then
    at_fichier_contient "$D7/fin.txt" "rc=0 fin="
  else
    at_echec "fin.txt n'est jamais apparu : le rejeu a été tué"
  fi
  at_fin 3

  at_debut sonder-mort
  mkdir -p "$AT_TMP/d-mort"
  sleep 0 &
  dead=$!
  wait "$dead"
  printf '60\n' > "$AT_TMP/d-mort/borne.txt"
  date +%s > "$AT_TMP/d-mort/debut.txt"
  printf '%s\n' "$dead" > "$AT_TMP/d-mort/pid.txt"
  printf 'mode=suite\n' > "$AT_TMP/d-mort/commande.txt"
  printf 'SUITE interrompue\n' > "$AT_TMP/d-mort/sortie.txt"
  at_lancer sonder "$AT_TMP/d-mort"
  at_contient "DETACHE-MORT"
  at_fin 3

  at_debut sonder-dossier-absent
  at_lancer sonder "$AT_TMP/n-existe-pas"
  at_fin 64

  at_debut sonder-tranche-trop-grande
  at_lancer sonder "$D1" --tranche=600
  at_fin 64
}

# mk_hook : écrit un faux hook (heredoc PY_PLANNING_HOOK_EOF) dans le faux dépôt. Variables : HK_ARMEMENT
# (observe|armed), HK_ROLE (corps de _choisir_definition), HK_SEUIL (constante lue par _h2), HK_H1, HK_H2,
# HK_AUTRE (fonction hors fermeture), HK_SANS (nom de fonction de rôle à omettre).
mk_hook() {
  local f="$FD/$HOOK_REL" nom val
  mkdir -p "$(dirname "$f")"
  {
    printf '#!/usr/bin/env bash\necho avant\npython3 -I -S - "$@" <<'"'"'PY_PLANNING_HOOK_EOF'"'"'\n'
    printf 'ARMEMENT_G4 = "%s"  # etape-5\n' "${HK_ARMEMENT:-observe}"
    printf 'SEUIL = %s\n\n' "${HK_SEUIL:-3}"
    for nom in $FONCTIONS_ROLE; do
      [ "$nom" != "${HK_SANS:-}" ] || continue
      val=0
      [ "$nom" != _choisir_definition ] || val=${HK_ROLE:-1}
      printf 'def %s(x):\n    """doc de %s"""\n    return %s\n\n' "$nom" "$nom" "$val"
    done
    printf 'def _h2(x):\n    return SEUIL + %s\n\n' "${HK_H2:-0}"
    printf 'def _h1(x):\n    return _h2(x) + %s\n\n' "${HK_H1:-0}"
    printf 'def evaluer_g4(contexte):\n    return _h1(contexte)\n\n'
    printf 'def autre(x):\n    return %s\n\n' "${HK_AUTRE:-0}"
    printf 'PY_PLANNING_HOOK_EOF\necho apres\n'
  } > "$f"
}

# Faux dépôt de l'autotest des invariants : fichiers de version et faux hook commités ; REF_AT = commit de base.
at_depot_inv() {
  at_depot
  mkdir -p "$FD/plugin/.claude-plugin" "$FD/.claude-plugin" "$FD/scripts/tests"
  echo 1.0.0 > "$FD/VERSION"
  echo '{"version":"1.0.0"}' > "$FD/plugin/.claude-plugin/plugin.json"
  echo '{"version":"1.0.0"}' > "$FD/.claude-plugin/marketplace.json"
  echo 'echo suite-role' > "$FD/scripts/tests/test-role-hook-vs-check-agents.sh"
  mk_hook
  at_commit
  REF_AT=$(cd "$FD" && git rev-parse HEAD)
}

autotest_invariants() {
  at_debut invariants-sains
  at_depot_inv
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANTS-BILAN ecarts=0"; at_contient "INVARIANT g4-fige non-applicable"
  at_fin 0

  at_debut invariants-role-change
  at_depot_inv
  HK_ROLE=2 mk_hook; at_commit
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT-ECART role _choisir_definition"; at_absent "INVARIANT-ECART role resoudre_agent"
  at_fin 1

  at_debut invariants-version-change
  at_depot_inv
  echo 1.0.1 > "$FD/VERSION"; at_commit
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT-ECART fichier VERSION"
  at_fin 1

  at_debut invariants-tag
  at_depot_inv
  (cd "$FD" && git tag t-invariant) > /dev/null 2>&1
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT-ECART tag t-invariant"
  at_fin 1

  at_debut invariants-base-absente
  at_depot
  HK_SANS=deriver_role mk_hook; at_commit
  REF_AT=$(cd "$FD" && git rev-parse HEAD)
  mk_hook; at_commit
  at_lancer invariants --base="$REF_AT"
  at_contient "deriver_role"
  at_fin 64

  at_debut g4-fige-observe
  at_depot_inv
  HK_AUTRE=9 mk_hook; at_commit
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT g4-fige non-applicable"; at_contient "INVARIANTS-BILAN ecarts=0"
  at_fin 0

  at_debut g4-fige-intact
  at_depot_inv
  HK_ARMEMENT=armed mk_hook; at_commit
  HK_ARMEMENT=armed HK_AUTRE=9 mk_hook; at_commit
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT g4-fige ok"; at_contient "INVARIANTS-BILAN ecarts=0"
  at_fin 0

  at_debut g4-fige-helper-change
  at_depot_inv
  HK_ARMEMENT=armed mk_hook; at_commit
  HK_ARMEMENT=armed HK_H1=5 mk_hook; at_commit
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT-ECART g4-fige _h1"
  at_fin 1

  at_debut g4-fige-constante-change
  at_depot_inv
  HK_ARMEMENT=armed mk_hook; at_commit
  HK_ARMEMENT=armed HK_SEUIL=7 mk_hook; at_commit
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT-ECART g4-fige SEUIL"
  at_fin 1

  at_debut g4-fige-transitif
  at_depot_inv
  HK_ARMEMENT=armed mk_hook; at_commit
  HK_ARMEMENT=armed HK_H2=5 mk_hook; at_commit
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT-ECART g4-fige _h2"; at_absent "INVARIANT-ECART g4-fige _h1"
  at_fin 1

  at_debut g4-fige-reference-introuvable
  at_depot_inv
  HK_ARMEMENT=armed mk_hook
  at_lancer invariants --base="$REF_AT"
  at_contient "INVARIANT-ECART g4-fige reference-introuvable"
  at_fin 1
}

# Faux vérificateur : verdict non-armable si une ligne du relevé commence par FAUX-NON-ARMABLE, armable sinon ;
# imite la forme de sortie du vrai (dernière ligne = RELEVE-VERDICT …).
mk_verif() { # <fichier>
  cat > "$1" <<'VERIF_EOF'
#!/usr/bin/env bash
etape=""; fichier=""
for a in "$@"; do
  case $a in
    --etape=*) etape=${a#--etape=} ;;
    --lab=*) ;;
    *) fichier=$a ;;
  esac
done
if awk 'index($0, "FAUX-NON-ARMABLE") == 1 { f = 1 } END { exit f ? 0 : 1 }' "$fichier"; then
  echo "RELEVE-ECART faux : raison"
  echo "RELEVE-VERDICT non-armable etape=$etape ecarts=1"
  exit 1
fi
echo "RELEVE-VERDICT armable etape=$etape labs=1 gates=G3,G4"
exit 0
VERIF_EOF
}

# Faux relevé. Variables : RV_VERDICT (armable|non-armable), RV_ETAPE, RV_SANS_SECTION, RV_SANS_ESCALADE,
# RV_AVANT_N, RV_SANS_APRES, RV_LIGNE (ligne RELEVE-VERDICT forcée), RV_NON_JOUE, RV_AVEC_MESURE, RV_CHEMIN.
mk_releve() { # <fichier>
  local f=$1 v=${RV_VERDICT:-armable} e=${RV_ETAPE:-5}
  if [ "${RV_NON_JOUE:-0}" = 1 ]; then
    {
      echo "# Relevé de repli"
      echo "REJEU-NON-JOUE reponse-non"
      [ "${RV_AVEC_MESURE:-0}" != 1 ] || echo "REJEU-ETAPE-$e faux-refus=0 faux-accept=0"
    } > "$f"
    return 0
  fi
  {
    echo "# Relevé synthétique"
    echo "REPOS-AVANT <lab-1> processus=${RV_AVANT_N:-0}"
    [ "${RV_SANS_APRES:-0}" = 1 ] || echo "REPOS-APRES <lab-1> processus=0"
    echo "REJEU-ETAPE-$e faux-refus=0 faux-accept=0"
    [ "${RV_CHEMIN:-0}" != 1 ] || echo "voir /Users/dev/lab/x"
    if [ "$v" = non-armable ]; then
      echo "FAUX-NON-ARMABLE"
      [ "${RV_SANS_SECTION:-0}" = 1 ] || echo "## Non armé — remonté à Willy"
      [ "${RV_SANS_ESCALADE:-0}" = 1 ] || echo "ESCALADE-WILLY ETAPE-$e couverture"
    fi
    if [ -n "${RV_LIGNE:-}" ]; then
      echo "$RV_LIGNE"
    elif [ "$v" = non-armable ]; then
      echo "RELEVE-VERDICT non-armable etape=$e ecarts=1"
    else
      echo "RELEVE-VERDICT armable etape=$e labs=1 gates=G3,G4"
    fi
  } > "$f"
}

autotest_releve() {
  local V R S CANON='echo "== Résultat : 3 OK · 0 KO =="' src
  nouveau_tmp
  V=$NT/verif.sh
  R=$NT/releve.md
  mk_verif "$V"
  at_depot

  at_debut releve-armable-coherent
  mk_releve "$R"
  at_lancer releve "$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "RELEVE-COHERENCE ok"
  at_fin 0

  at_debut releve-non-arme-coherent
  RV_VERDICT=non-armable mk_releve "$R"
  at_lancer releve "$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "RELEVE-COHERENCE ok"
  at_fin 0

  at_debut releve-non-arme-sans-escalade
  RV_VERDICT=non-armable RV_SANS_ESCALADE=1 mk_releve "$R"
  at_lancer releve "$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "RELEVE-COHERENCE ECART non-arme-sans-escalade"
  at_fin 1

  at_debut releve-verdict-recopie-faux
  RV_VERDICT=non-armable RV_LIGNE="RELEVE-VERDICT armable etape=5 labs=1 gates=G3,G4" mk_releve "$R"
  at_lancer releve "$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "RELEVE-COHERENCE ECART verdict-recopie"
  at_fin 1

  at_debut releve-non-joue
  RV_NON_JOUE=1 mk_releve "$R"
  at_lancer releve "$R" --etape=5 --verificateur="$V"
  at_contient "RELEVE-COHERENCE ok"
  at_fin 0

  at_debut releve-non-joue-mais-mesure
  RV_NON_JOUE=1 RV_AVEC_MESURE=1 mk_releve "$R"
  at_lancer releve "$R" --etape=5 --verificateur="$V"
  at_contient "RELEVE-COHERENCE ECART non-joue-mais-mesure"
  at_fin 1

  at_debut releve-absent
  at_lancer releve "$NT/inexistant.md" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "RELEVE-COHERENCE ECART absent"
  at_fin 1

  at_debut releve-chemin-machine
  RV_CHEMIN=1 mk_releve "$R"
  at_lancer releve "$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "RELEVE-COHERENCE ECART chemin-machine"
  at_fin 1

  at_debut releve-repos-absent
  RV_SANS_APRES=1 mk_releve "$R"
  at_lancer releve "$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "RELEVE-COHERENCE ECART repos-absent <lab-1> APRES"
  at_fin 1

  at_debut releve-repos-non-nul
  RV_AVANT_N=2 mk_releve "$R"
  at_lancer releve "$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "RELEVE-COHERENCE ECART repos-non-nul <lab-1> AVANT n=2"
  at_fin 1

  at_debut releve-verificateur-absent
  mk_releve "$R"
  at_lancer releve "$R" --etape=5 --lab='<lab-1>' --verificateur="$NT/n-existe-pas.sh"
  at_contient "RELEVE-COHERENCE ECART verificateur-absent"
  at_fin 1

  # releve-chaine : la fausse suite dépose les relevés d'un dossier source dans VF_RELEVE_CHAINE_DEPOT.
  src=$NT/chaine-src
  mkdir -p "$src"
  RV_ETAPE=5 mk_releve "$src/chaine-etape-5.md"
  RV_ETAPE=6 mk_releve "$src/chaine-etape-6.md"
  RV_ETAPE=6 RV_VERDICT=non-armable mk_releve "$src/chaine-etape-6-sans-agent.md"
  S=$NT/suite-chaine.sh

  at_debut releve-chaine-saine
  printf '#!/usr/bin/env bash\ncp %s/*.md "$VF_RELEVE_CHAINE_DEPOT/"\necho "  ✓ R-RELEVE-CHAINE trois relevés déposés"\n%s\n' "$src" "$CANON" > "$S"
  at_lancer releve-chaine --suite="$S" --verificateur="$V"
  at_contient "RELEVE-CHAINE chaine-etape-5.md verdict=armable coherence=ok"
  at_contient "RELEVE-CHAINE chaine-etape-6-sans-agent.md verdict=non-armable coherence=ok"
  at_absent "RELEVE-CHAINE-ECART"
  at_fin 0

  at_debut releve-chaine-depot-incomplet
  printf '#!/usr/bin/env bash\ncp %s/chaine-etape-5.md %s/chaine-etape-6.md "$VF_RELEVE_CHAINE_DEPOT/"\necho "  ✓ R-RELEVE-CHAINE deux relevés"\n%s\n' "$src" "$src" "$CANON" > "$S"
  at_lancer releve-chaine --suite="$S" --verificateur="$V"
  at_contient "RELEVE-CHAINE-ECART depot-incomplet chaine-etape-6-sans-agent.md"
  at_fin 1

  at_debut releve-chaine-verdict-inattendu
  RV_ETAPE=6 mk_releve "$NT/armable-6.md"
  printf '#!/usr/bin/env bash\ncp %s/chaine-etape-5.md %s/chaine-etape-6.md "$VF_RELEVE_CHAINE_DEPOT/"\ncp %s/armable-6.md "$VF_RELEVE_CHAINE_DEPOT/chaine-etape-6-sans-agent.md"\necho "  ✓ R-RELEVE-CHAINE verdict faux"\n%s\n' "$src" "$src" "$NT" "$CANON" > "$S"
  at_lancer releve-chaine --suite="$S" --verificateur="$V"
  at_contient "RELEVE-CHAINE-ECART verdict-inattendu chaine-etape-6-sans-agent.md attendu=non-armable obtenu=armable"
  at_fin 1
}

# --montre (P461-D-16) : une ligne demandée est imprimée telle quelle, son absence est rouge, une citation de la
# ligne au milieu d'une autre ne compte pas, le motif est un littéral.
autotest_montre() {
  local S=plugin/m/tests/test-c.sh CANON='echo "== Résultat : 3 OK · 0 KO =="' BF D
  BF=$AT_TMP/base-montre.txt
  at_depot

  at_debut montre-present
  mk_suite $S "echo 'COMPTE G4 faux-refus=0 faux-accept=0'; $CANON"
  at_lancer suite $S --montre='COMPTE G4 '
  at_compte "SUITE-MONTRE bash : COMPTE G4 faux-refus=0 faux-accept=0" 1; at_compte "SUITE-ECART" 0; at_contient "montres=1/1"
  at_fin 0

  at_debut montre-absent
  mk_suite $S "echo 'COMPTE G4 faux-refus=0 faux-accept=0'; $CANON"
  at_lancer suite $S --montre='MOTIF-ABSENT-46-1 '
  at_contient "SUITE-ECART montre-absent MOTIF-ABSENT-46-1"; at_compte "SUITE-MONTRE" 0; at_contient "montres=0/1"
  at_fin 1

  at_debut montre-citation-ignoree
  mk_suite $S "echo '  ✓ R-BANC-G4 mesure … COMPTE G4 faux-refus=0 faux-accept=0'; $CANON"
  at_lancer suite $S --montre='COMPTE G4 '
  at_contient "SUITE-ECART montre-absent COMPTE G4"; at_compte "SUITE-MONTRE" 0
  at_fin 1

  at_debut montre-suite-rouge
  mk_suite $S "echo '  ✗ x'; echo 'COMPTE G4 faux-refus=0 faux-accept=0'; $CANON"
  at_lancer suite $S --montre='COMPTE G4 '
  at_compte "SUITE-MONTRE bash : COMPTE G4 faux-refus=0 faux-accept=0" 1; at_contient "SUITE-ECART ko"; at_absent "SUITE-ECART montre-absent"
  at_fin 1

  at_debut montre-vide
  mk_suite $S "$CANON"
  at_lancer suite $S --montre=
  at_fin 64

  at_debut montre-litteral
  mk_suite $S "echo 'COMPTE G4 x'; $CANON"
  at_lancer suite $S --montre='COMPTE G4.'
  at_contient "SUITE-ECART montre-absent COMPTE G4."; at_compte "SUITE-MONTRE" 0
  at_fin 1

  at_debut montre-tronque
  mk_suite $S "i=0; while [ \$i -lt 52 ]; do echo \"LIGNE \$i\"; i=\$((i + 1)); done; $CANON"
  at_lancer suite $S --montre='LIGNE '
  at_compte "SUITE-MONTRE bash : LIGNE " 50; at_contient "SUITE-NOTE montre-tronque LIGNE"; at_contient "reste=2"; at_compte "SUITE-ECART" 0
  at_fin 0

  at_debut montre-sonder
  mk_suite $S "echo 'COMPTE G4 faux-refus=0 faux-accept=0'; $CANON"
  mk_base "$BF" "$S:0:3"
  D=$AT_TMP/d-montre
  at_lancer suite $S --montre='COMPTE G4 ' --detache="$D" --base-fichier="$BF"
  at_attendre_fin "$D" 60 || at_echec "fin.txt n'est jamais apparu"
  at_lancer sonder "$D"
  at_contient "SUITE-MONTRE bash : COMPTE G4 faux-refus=0 faux-accept=0"
  at_fin 0
}

# Sandbox des cas reel-* : clone partagé SANS extraction (même HEAD, mêmes objets : la base reste valide, aucun
# fichier du dépôt n'est touché), puis copie des seuls fichiers d'ENTRÉE nommés (dossier ou fichier, chemins relatifs
# à la racine du dépôt). Pose SB ; retourne 1 (et note l'échec) si elle ne peut pas être montée.
at_sandbox() {
  local f
  if [ -z "$AT_RACINE" ]; then
    at_echec "racine du dépôt introuvable (les cas reel-* lisent le dépôt)"
    return 1
  fi
  nouveau_tmp
  SB=$NT/sb
  if ! git clone -q --shared --no-checkout "$AT_RACINE" "$SB" > /dev/null 2>&1; then
    at_echec "clone partagé impossible"
    return 1
  fi
  for f in "$@"; do
    mkdir -p "$SB/$(dirname "$f")"
    cp -R "$AT_RACINE/$f" "$SB/$f" || { at_echec "copie impossible : $f"; return 1; }
  done
  return 0
}

# Remplace dans <src> la ligne ENTIÈRE <ancre> (unique) par <nouvelle>, ou la fait suivre de <nouvelle> (mode
# `apres`) ; écrit <dst> (awk vers un fichier neuf, jamais sed -i). Échec reel-ancre si l'ancre n'est pas unique.
at_perturber() { # <remplace|apres> <src> <dst> <ancre> <nouvelle>
  A="$4" N="$5" M="$1" LC_ALL=C awk '
    BEGIN { a = ENVIRON["A"]; n = ENVIRON["N"]; m = ENVIRON["M"] }
    $0 == a { c++; if (m == "apres") { print; print n } else { print n }; next }
    { print }
    END { if (c != 1) exit 3 }' "$2" > "$3" || { at_echec "reel-ancre : « $4 » absente ou multiple dans $2"; return 1; }
  return 0
}

# Cas reel-* : VRAIES suites rejouées sur copie sandbox, ENTRÉE perturbée, sortie jamais réécrite. Aucune fixture
# fabriquée par l'outil : si la recette ne produit pas le motif attendu, le cas échoue (jamais un repli).
autotest_reel_suite() {
  local R=scripts/tests/test-role-hook-vs-check-agents.sh P=plugin/planning-core/scripts/planning-hook.sh
  local C=plugin/planning-core/scripts/tests/test-planning-core.sh K=plugin/planning-core/scripts/check-planning-state.sh
  local Z=plugin/planning-core/scripts/tests/test-planning-prefilter.sh BASE
  BASE="$(dirname "$OUTIL_ORIGINE")/46.1-BASE.txt"

  at_debut reel-temoin-role
  AT_RC=0
  if at_sandbox plugin $R; then
    cmp -s "$SB/$R" "$AT_RACINE/$R" || at_echec "la suite copiée diffère de celle du dépôt"
    cmp -s "$SB/$P" "$AT_RACINE/$P" || at_echec "le hook copié diffère du hook du dépôt (le témoin n'est pas perturbé)"
    AT_CWD=$SB
    at_lancer suite $R --duree-max=base --base-cle=$R --base-fichier="$BASE"
    # Sous forte charge la durée murale peut dépasser le plafond (3 × la durée de base) sans que la suite soit
    # rouge : seul cet écart, et une seule fois, autorise un second rejeu (nommé) ; tout autre écart reste rouge.
    if [ "$AT_RC" -eq 1 ] && [ "$(P='SUITE-ECART' LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) == 1 { c++ } END { print c + 0 }' "$AT_OUT")" -eq 1 ] \
      && P='SUITE-ECART duree-plafond' LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) == 1 { f = 1 } END { exit f ? 0 : 1 }' "$AT_OUT"; then
      echo "  AUTOTEST-NOTE reel-temoin-role : seul écart duree-plafond (charge de la machine), second rejeu"
      at_lancer suite $R --duree-max=base --base-cle=$R --base-fichier="$BASE"
    fi
    at_compte "SUITE-ECART" 0; at_contient "SUITE $R shell=bash rc=0"
  fi
  at_fin 0

  at_debut reel-non-tue
  AT_RC=0
  if at_sandbox plugin $R; then
    if at_perturber apres "$SB/$P" "$SB/$P.mut" '    interdits = jetons_nus_agent(lignes, "disallowedTools")' '    interdits = {t for t in interdits if t != "Write" or "Edit" in interdits}'; then
      mv "$SB/$P.mut" "$SB/$P"
    fi
    cmp -s "$SB/$R" "$AT_RACINE/$R" || at_echec "la suite copiée diffère de celle du dépôt"
    cmp -s "$SB/$P" "$AT_RACINE/$P" && at_echec "le hook copié est identique au hook du dépôt (aucune perturbation)"
    AT_CWD=$SB
    at_lancer suite $R --base-cle=$R
    at_contient "  ✗ MUT-CROISE-JUGE NON TUÉ"; at_contient "SUITE-ECART non-tue n=1"; at_contient "SUITE-ECART ko n=1"
  fi
  at_fin 1

  at_debut reel-bilan
  AT_RC=0
  if at_sandbox $C $K; then
    cmp -s "$SB/$C" "$AT_RACINE/$C" || at_echec "la suite copiée diffère de celle du dépôt"
    cmp -s "$SB/$K" "$AT_RACINE/$K" || at_echec "le script testé copié diffère de celui du dépôt (reel-bilan n'est pas perturbé)"
    AT_CWD=$SB
    at_lancer suite $C --base-cle=$C
    at_contient "SUITE-ECART bilan forme-inconnue"; at_compte "SUITE-ECART" 1
    at_absent "  ✗ "; at_absent "SUITE-ECART ko"; at_absent "SUITE-ECART rc"; at_absent "SUITE-ECART non-tue"
  fi
  at_fin 1

  at_debut reel-ko
  AT_RC=0
  if at_sandbox $C $K; then
    if at_perturber remplace "$SB/$K" "$SB/$K.mut" 'MAX_AGE_DAYS=7' 'MAX_AGE_DAYS=70'; then
      mv "$SB/$K.mut" "$SB/$K"
    fi
    cmp -s "$SB/$C" "$AT_RACINE/$C" || at_echec "la suite copiée diffère de celle du dépôt"
    cmp -s "$SB/$K" "$AT_RACINE/$K" && at_echec "le script testé copié est identique à celui du dépôt (aucune perturbation)"
    AT_CWD=$SB
    at_lancer suite $C --base-cle=$C
    at_contient "  ✗ STATE périmé (20j)"; at_contient "SUITE-ECART ko"; at_contient "SUITE-ECART rc 1"; at_contient "SUITE-ECART bilan forme-inconnue"
  fi
  at_fin 1

  at_debut reel-zero-ok
  AT_RC=0
  if at_sandbox $Z; then
    cmp -s "$SB/$Z" "$AT_RACINE/$Z" || at_echec "la suite copiée diffère de celle du dépôt"
    [ ! -e "$SB/plugin/planning-core/hooks/hooks.json" ] || at_echec "hooks.json est présent à côté de la suite copiée"
    [ ! -e "$SB/plugin/planning-core/scripts/planning-hook.sh" ] || at_echec "planning-hook.sh est présent à côté de la suite copiée"
    AT_CWD=$SB
    at_lancer suite $Z --base-cle=$Z
    at_contient "SUITE-ECART bilan zero-ok"; at_compte "SUITE-ECART" 1; at_contient "rc=0"
  fi
  at_fin 1
}

autotest() {
  local manquants=0 c j trouve n d m a
  SANS_REEL=0
  for a in "$@"; do
    case $a in
      --sans-reel) SANS_REEL=1 ;;
      *) die_usage "--autotest [--sans-reel]" ;;
    esac
  done
  nouveau_tmp
  AT_TMP=$NT
  AT_RACINE=$(git rev-parse --show-toplevel 2> /dev/null) || AT_RACINE=""
  [ "$SANS_REEL" -eq 0 ] || echo "AUTOTEST-PARTIEL sans=reel"
  autotest_suite
  autotest_montre
  autotest_toutes
  autotest_base
  autotest_detache
  autotest_invariants
  autotest_releve
  [ "$SANS_REEL" -eq 1 ] || autotest_reel_suite
  # Cas déclarés contre cas joués : un cas déclaré et non joué est un échec.
  for c in "${CAS_AUTOTEST[@]}"; do
    if [ "$SANS_REEL" -eq 1 ]; then
      case $c in reel-*) continue ;; esac
    fi
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
  d=0
  for c in "${CAS_AUTOTEST[@]}"; do
    if [ "$SANS_REEL" -eq 1 ]; then
      case $c in reel-*) continue ;; esac
    fi
    d=$((d + 1))
  done
  m=$((AT_KO + manquants))
  if [ "$SANS_REEL" -eq 1 ]; then
    printf 'AUTOTEST-BILAN cas=%s declares=%s echecs=%s sans-reel=oui\n' "$n" "$d" "$m"
  else
    printf 'AUTOTEST-BILAN cas=%s declares=%s echecs=%s\n' "$n" "$d" "$m"
  fi
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
    --autotest) autotest "$@"; return $? ;;
    suite) cmd_suite "$@"; return $? ;;
    toutes) cmd_toutes "$@"; return $? ;;
    sonder) cmd_sonder "$@"; return $? ;;
    invariants) cmd_invariants "$@"; return $? ;;
    releve) cmd_releve "$@"; return $? ;;
    releve-chaine) cmd_releve_chaine "$@"; return $? ;;
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
