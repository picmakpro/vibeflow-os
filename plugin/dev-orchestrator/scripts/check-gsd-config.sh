#!/usr/bin/env bash
# check-gsd-config.sh — Le .planning/config.json de ce lab est-il aligné sur le moteur GSD installé ?
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit JAMAIS qu'une clé est
# « mauvaise », ni qu'un toggle est mal réglé — seulement que le moteur installé NE CONNAÎT PAS
# telle clé, et que tel toggle de cycle N'EST PAS ÉCRIT dans le fichier audité. C'est le jugement
# de l'agent (ou de l'utilisateur) de décider quoi en faire.
#
# Trois faits constatés, indépendants, cumulables dans un même appel :
#
#   (a) CLÉS INCONNUES — des clés présentes dans le fichier audité que le moteur ignorera.
#   (b) TOGGLES DE CYCLE AU DÉFAUT IMPLICITE — des toggles que la Phase 23 arbitre et que ce lab
#       laisse tomber au défaut amont au lieu de les écrire (piloter ses étages par omission).
#   (c) MOTEUR LU MAIS ILLISIBLE — le moteur a bien été résolu, mais l'une des trois sources de
#       clés connues n'a rien rendu. Ce fait-là porte sur le GATE, pas sur le lab : il dit « je ne
#       peux plus constater », ce qui n'est pas « il n'y a rien à constater ». Il est émis EN
#       PREMIER car il qualifie (a) et (b), qui peuvent alors être faux dans les deux sens.
#
# --- Source des clés connues : LUE DEPUIS LE MOTEUR, jamais en dur ------------------------------
# Les clés connues sont lues à l'exécution depuis le gsd-core installé, donc ce gate NE PÉRIME PAS
# quand le moteur monte de version. L'union de TROIS sources est nécessaire — chacune seule produit
# des faux positifs (fait vérifié, pas supposé).
#
# Chaque source est cherchée SOUS DEUX FORMES, dans cet ordre : d'abord le MANIFESTE JSON de
# bin/shared/, ensuite le LITTÉRAL JS du module de bin/lib/ qui la porte. Les deux formes sont
# nécessaires, et c'est mesuré : sur gsd-core 1.9, AUCUNE des trois sources n'est un littéral dans
# le module qui l'exporte (elles viennent toutes des manifestes) ; à l'inverse, un moteur minimal
# qui les écrit en clair dans ses .cjs n'a pas de bin/shared/ du tout.
#
#   1. VALID_CONFIG_KEYS — Set de clés pointées (104 aujourd'hui). Sur gsd-core 1.9, config.cjs la
#      RÉ-EXPORTE depuis config-schema.cjs, qui la ré-exporte depuis configuration.cjs, où elle vaut
#      `new Set(SCHEMA_MANIFEST.validKeys)` : la donnée réelle est dans
#      bin/shared/config-schema.manifest.json, clé `validKeys`. Le repli littéral vise
#      bin/lib/{config,configuration,config-schema}.cjs. Le même manifeste porte `dynamicKeyPatterns`,
#      d'où sortent les topLevel des motifs dynamiques (calculés par `.map` dans configuration.cjs,
#      donc illisibles là-bas).
#   2. configKeys (bin/lib/capability-registry.cjs) — clés de config déclarées par les capabilities
#      (58 aujourd'hui). C'est la SEULE des trois qui soit réellement un littéral dans un .cjs : un
#      objet plat, compatible JSON. Indispensable : workflow.code_review, workflow.pattern_mapper
#      et workflow.ui_review sont ABSENTS de VALID_CONFIG_KEYS et ne vivent QUE là — un gate qui ne
#      lirait que la source 1 signalerait à tort trois clés parfaitement légitimes.
#   3. CONFIG_DEFAULTS — les défauts canoniques imbriqués. Même topologie que la source 1 : sur
#      gsd-core 1.9, configuration.cjs les charge depuis bin/shared/config-defaults.manifest.json ;
#      le repli littéral vise bin/lib/{configuration,config-loader,config}.cjs. Même raison d'être,
#      symétrique de la source 2 : workflow._auto_chain_active (écrit par le moteur lui-même quand
#      une chaîne --auto est active) n'est dans AUCUNE des deux premières sources. Sans cette
#      troisième source, le gate signalerait comme « inconnue » une clé que le moteur écrit de sa
#      propre main. C'est aussi la source qui donne la VALEUR du défaut amont d'un toggle (volet b).
#
# Inversement workflow.node_repair et workflow.node_repair_budget ne vivent que dans la source 1.
# Les trois sources sont donc lues et unies ; aucune n'est suffisante seule.
#
# UNE EXCEPTION, ASSUMÉE ET NOMMÉE : la liste engineExtra (voir plus bas) recopie en dur une poignée
# de littéraux de premier niveau que le moteur ajoute à son propre KNOWN_TOP_LEVEL sans les exporter
# nulle part (config-loader.cjs) — aucun module de bin/lib ne les expose, ils ne sont donc pas
# lisibles dynamiquement. C'est le SEUL endroit du script où des noms de clés sont écrits à la main,
# et c'est le seul point par lequel le gate peut dériver à la montée de version du moteur. Le cas 26
# de la suite dédiée exerce ce mirroir contre le moteur réel, précisément pour qu'une telle dérive
# se voie en test rouge au lieu de passer en silence.
#
# --- LIMITES DE PORTÉE CONNUES — LES DEUX SENS SONT ATTEIGNABLES -------------------------------
# Ce gate n'est PAS en parité avec le moteur sur l'ensemble des clés de premier niveau. Il peut se
# tromper dans les DEUX sens, et c'est mesuré, pas supposé :
#
#   (i) FAUX POSITIF possible (schéma fédéré) — le moteur complète son KNOWN_TOP_LEVEL avec un
#       overlay FÉDÉRÉ résolu pour le lab audité (clés déclarées par des capabilities tierces
#       installées dans ce lab). Ce gate ne lit PAS cet overlay : sur un lab qui en installerait,
#       il peut signaler comme inconnue une clé que le moteur, lui, accepterait.
#
#   (ii) FAUX NÉGATIF possible (sur-ensemble statique) — et c'est le sens que la version initiale
#       de cet en-tête déclarait à tort impossible. Le moteur bâtit son KNOWN_TOP_LEVEL
#       (config-loader.cjs) à partir de VALID_CONFIG_KEYS + DYNAMIC_KEY_PATTERNS + les littéraux
#       en dur — NI configKeys, NI CONFIG_DEFAULTS. Le KNOWN_TOP de ce script, lui, dérive de
#       l'union des TROIS sources : il est donc un SUR-ENSEMBLE strict de celui du moteur. Toute
#       clé de premier niveau présente dans les sources 2 ou 3 mais absente de la source 1 est
#       épargnée ici et signalée là-bas.
#       Mesuré contre le moteur installé le 2026-08-03 : le script connaît en plus _comment,
#       claude_orchestration, external_job, intel, mempalace, profile-pipeline (6 clés) ; le
#       moteur ne connaît rien que le script ignore. Cas reproduit de bout en bout : sur un lab
#       par ailleurs aligné portant _comment (une CHAÎNE de documentation de CONFIG_DEFAULTS,
#       jamais une clé de config), ce gate sort en 3 « rien à signaler » pendant que loadConfig
#       avertit « unknown config key(s): _comment ».
#       Conséquence de second ordre : un bloc de ce type est traité comme conteneur CONNU, donc
#       ses sous-clés sont signalées à sa place — le conseil rendu porte alors sur la mauvaise
#       cible.
#
# La ligne « reproduit ce comportement à l'identique » plus bas vaut pour la MÉCANIQUE (comparer
# les clés de premier niveau à un ensemble connu), pas pour la COMPOSITION de cet ensemble.
#
# Le gate reste advisory et ne bloque rien. La DIRECTION du correctif (mettre KNOWN_TOP en parité
# stricte avec le moteur — ce qui rouvre des faux positifs sur les labs fédérés — ou lire aussi
# l'overlay fédéré en 4ᵉ source) est volontairement NON tranchée ici : hors périmètre du plan
# 23-02, dont la recherche amont ne mentionne pas la source fédérée. Escaladée, à instruire avant
# d'élargir la portée du gate.
#
# --- LIMITE DE LA LECTURE DE TEXTE — ELLE NE SUIT PAS LES INDIRECTIONS (O-13) -------------------
# Ce script LIT le moteur au lieu de l'exécuter (A-6, voir « Sécurité » plus bas). Le prix est
# nommé ici, et il n'est pas nul : `require()` suivait les indirections (ré-exports en chaîne,
# chargement d'un manifeste, valeur calculée) ; la lecture de texte ne les suit PAS. Elle voit du
# JSON pur et des littéraux JS simples, rien d'autre. Si une version future du moteur déplace ses
# manifestes, écrit `new Set(VARIABLE)`, ou calcule ses défauts (spread, `.map`, `process.env`),
# l'extraction rend zéro sur la source concernée. Les DEUX SENS de la conséquence sont atteignables,
# et tous deux sont MESURÉS, pas supposés :
#
#   (iii) TROP MUET — plus aucune clé connue lisible. Le script sortait alors en 3, c'est-à-dire
#       dans le MÊME code que « moteur gsd-core introuvable » et que « fichier audité absent » :
#       rien, ni dans le contrat de sortie ni dans la sortie de session, ne distinguait « ce gate
#       est périmé » de « rien à signaler », et le `|| true` du hook achevait de tout masquer. Un
#       gate périmé était silencieux, et son silence ressemblait à un succès.
#
#   (iv) FAUSSEMENT AFFIRMATIF — pire que le silence, parce que le script parle. Si la source 1
#       reste lisible mais que CONFIG_DEFAULTS ne l'est plus (valeurs calculées), les toggles
#       arbitrés basculaient de l'état 2 (« au défaut amont », avec sa valeur) à l'état 3 (« sans
#       défaut lisible dans le moteur ») : le script AFFIRMAIT une absence là où il y a une valeur.
#       Symétriquement, les clés qui ne vivent QUE dans la source 3 (workflow._auto_chain_active)
#       redeviennent « inconnues » et sont signalées à tort.
#
# CE QUI EST FAIT (arbitrage A-9, voies b et c d'O-13) — la limite reste, son SILENCE ne reste pas :
#   - un SIGNAL EXPLICITE nomme la ou les sources qui n'ont rien rendu, et il est émis EN PREMIER
#     parce qu'il qualifie tous les constats suivants. Le contrat de sortie ne bouge pas : c'est un
#     signal, donc exit 0 — « au moins un signal émis » — et jamais un code neuf ni hors contrat.
#     (Le code d'échec générique n'est même pas nommable ici en toutes lettres : la moitié statique
#     du balayage final compte les codes de sortie ÉCRITS dans ce fichier, prose comprise.) « Le
#     gate ne peut plus constater » cesse d'être indistinguable de « il n'y a rien à constater » ;
#   - les toggles ont désormais un QUATRIÈME état, « les défauts amont n'ont pas pu être lus »,
#     distinct de l'état 3 « sans défaut lisible dans le moteur ». C'est (iv) refermé à la source :
#     le script ne conclut plus à une absence qu'il n'a pas constatée ;
#   - un CANARI DE FORME tourne en CI contre le moteur réellement installé (voir
#     .github/workflows/ci.yml) : il rougit quand la forme du moteur cesse d'être lisible, ce qui
#     déplace la détection du poste de l'utilisateur — au SessionStart, sous `|| true` — vers la CI.
# Reste NON traité et assumé : la lecture de texte ne suivra jamais une indirection. La voie (a)
# d'O-13 (revenir à une résolution dynamique) reste écartée par A-6.
#
# --- Granularité de comparaison (choix explicite, pas un accident) ------------------------------
# Le moteur ne valide QUE le premier niveau : son KNOWN_TOP_LEVEL est l'ensemble des premiers
# segments des clés connues, plus les topLevel de DYNAMIC_KEY_PATTERNS, plus une poignée de
# littéraux ; il signale ensuite les clés de premier niveau du fichier qui n'y sont pas. C'est
# pourquoi il nomme « gates, safety » et jamais leurs dix sous-clés. Ce script reproduit la même
# MÉCANIQUE pour le premier niveau (son ensemble connu n'est PAS le même — voir « LIMITES DE
# PORTÉE » ci-dessus), puis va UN CRAN PLUS LOIN, en le bornant :
#
#   - clé de PREMIER NIVEAU inconnue  → signalée EN TANT QUE BLOC (son nom seul, pas ses sous-clés) ;
#   - sous-clé inconnue sous un conteneur connu → signalée par son chemin pointé complet, MAIS
#     seulement si ce conteneur déclare au moins un enfant dans les clés connues. Un conteneur
#     déclaré « nu » (aucun enfant connu — parallelization, agent_skills…) est OPAQUE pour le
#     moteur, qui en consomme la valeur entière : y signaler des sous-clés serait inventer un fait.
#
# --- Trois états par toggle (volet b) — et surtout PAS deux ------------------------------------
#   1. écrit dans le fichier audité                      → rien à signaler ;
#   2. absent du fichier, présent dans les défauts amont → signalé « au défaut amont », avec la
#      valeur effective LUE dans le moteur (jamais recopiée ici) ;
#   3. absent du fichier ET absent des défauts amont     → signalé « sans défaut lisible dans le
#      moteur », SANS aucune valeur ET SANS CAUSE. Le script observe une absence, jamais sa raison :
#      énoncer « résolu par la capability elle-même » serait fabriquer un fait, et serait faux pour
#      node_repair / node_repair_budget, qui ne sont pas des capabilities (voir plus haut). Cas de
#      workflow.ui_review : il est référencé comme condition
#      d'activation par le registre de capabilities mais n'a de valeur par défaut nulle part. Une
#      valeur qui n'existe nulle part N'EST PAS `false` — elle est ABSENTE. L'afficher comme faux
#      serait fabriquer un fait, précisément ce qu'ADR-055 §3 interdit à un script.
#
# --- Sécurité (T-23-02-01 et T-23-02-07, §Security Domain du RESEARCH) -------------------------
# Le fichier audité est une entrée NON MAÎTRISÉE (ce gate est fait pour tourner sur n'importe quel
# lab) : ses clés comme ses valeurs sont hostiles par hypothèse. Aucun contenu lu depuis ce fichier
# n'est jamais interpolé dans une commande shell. L'aplatissement du JSON se fait entièrement côté
# node, et les jetons remontés à bash sont encodés en JSON (JSON.stringify) : ils ne peuvent donc
# contenir ni tabulation, ni saut de ligne, ni guillemet nu, et un octet de contrôle ressort en
# échappement \uXXXX plutôt qu'en octet brut dans la sortie de session. Les chemins sont passés à
# node par l'ENVIRONNEMENT, jamais par concaténation dans le texte du programme.
#
# Le MOTEUR RÉSOLU est lui aussi une entrée non maîtrisée (T-23-02-07, arbitrage A-6). La cascade
# ci-dessous fait PRIMER le lab courant : sa première branche est <path>/.claude/gsd-core/bin/lib,
# c'est-à-dire un chemin situé DANS le dépôt audité. Cette priorité est délibérée et conservée — un
# lab en VF_SCOPE=project a légitimement son moteur dans son dépôt. Elle a pour conséquence qu'un
# dépôt cloné et non maîtrisé peut fournir le moteur : y déposer un config.cjs piégé suffisait à
# faire exécuter du code arbitraire au SessionStart, sans trace — le script sortait en 0 comme si de
# rien n'était, et le `|| true` du hook masquait jusqu'à un échec. Ouvrir une session dans un dépôt
# cloné suffisait. La mesure appliquée : ce script N'EXÉCUTE JAMAIS le moteur résolu, il le LIT.
# Aucun require() n'est fait sur un chemin construit depuis le dossier du moteur — les seuls
# require() du programme node portent sur des modules cœur (fs, path) —, aucun eval, aucun vm,
# aucun import() dynamique. Les listes sont extraites par lecture de JSON et de littéraux JS :
# aucun CONTENU, si hostile soit-il, ne s'exécute. Motif écrit une seule fois, valable pour les
# trois sources et pour les deux formes de lecture. Le prix de cette mesure est nommé plus haut, à
# « LIMITE DE LA LECTURE DE TEXTE ».
#
# DISPONIBILITÉ (T-23-02-03, arbitrage A-14). Ne pas exécuter ferme l'exécution de code, PAS le déni
# de service, et le pire cas n'est donc PAS « une extraction vide » : c'est une ATTENTE NON BORNÉE.
# Deux coûts distincts, l'un et l'autre désormais bornés :
#   - le COÛT DU PARSEUR : la boucle de lecture des littéraux est linéaire en la taille de la
#     région, propriété exigée et tenue (voir « COÛT LINÉAIRE, EXIGÉ » dans le programme node) ;
#   - le COÛT DE LA LECTURE ELLE-MÊME : les cibles étaient ouvertes par un readFileSync nu, sans
#     garde de type ni de taille. Seul config.cjs était filtré par le `[ -f ]` de la cascade ; sur
#     les six autres (capability-registry.cjs, configuration.cjs, config-schema.cjs,
#     config-loader.cjs et les deux manifestes de bin/shared), une FIFO ou un lien vers /dev/zero
#     déposé dans le dépôt audité BLOQUAIT le SessionStart indéfiniment — mesuré, jamais terminé.
#     Le `|| true` du hook ne raccourcit pas une attente, et le contrat de sortie ne s'applique pas
#     à un processus qui n'a pas fini.
# LA GARDE EST POSÉE, sur TOUTES les cibles et sur le fichier audité : ouverture non bloquante,
# fstat sur le descripteur (fichier ordinaire exigé), taille plafonnée, refus plutôt que troncature.
# Le détail et le pourquoi de chacune des trois propriétés sont écrits au-dessus de `slurp` dans le
# programme node. Un refus rend `null`, donc reste dans le contrat {0, 3, 64}, et il est AUDIBLE :
# il ressort par le signal « moteur illisible » plutôt que par un silence.
#
# Usage:
#   check-gsd-config.sh [--path <dir>] [--hook] [--quiet]
# Defaults: --path .
#
# Surcharges d'environnement (patron VF_ du dépôt, ADR-054) :
#   VF_CONFIG_PATH    chemin complet du config.json audité (défaut <path>/.planning/config.json)
#   VF_GSD_CORE_LIB   dossier bin/lib du moteur. S'il est défini, il REMPLACE la cascade au lieu de
#                     s'y ajouter — sans quoi aucune fixture ne pourrait simuler un moteur absent,
#                     la cascade retombant toujours sur le moteur réel du poste.
#
# Cascade de résolution du moteur (le lab courant PRIME, même priorité que la cascade $S de
# mission-flow.md) — DEUX branches : <path>/.claude/gsd-core/bin/lib, puis
# $HOME/.claude/gsd-core/bin/lib.
#
# UNE TROISIÈME BRANCHE A ÉTÉ RETIRÉE (arbitrage A-10) : <path>/node_modules/@opengsd/gsd-core/bin/lib.
# C'était du CODE MORT, et c'est mesuré, pas supposé : le tarball npm publié range son payload sous
# un DOUBLE SEGMENT, .../@opengsd/gsd-core/gsd-core/bin/lib. Un bin/lib existe bien un cran plus
# haut, mais il ne porte pas config.cjs — le `[ -f "$candidate/config.cjs" ]` de la cascade n'y a
# donc jamais réussi. Défaut IDENTIQUE sur 1.8.0 et sur 1.9.0 : ce n'est pas une régression amont,
# c'est le layout du paquet ; cette branche n'a jamais résolu pour personne, sur aucune version.
# Elle est RETIRÉE plutôt que corrigée : corriger le chemin ouvrirait une voie de résolution
# aujourd'hui morte, donc une surface d'entrée neuve pour un moteur non maîtrisé — au moment précis
# où l'on ferme un vecteur d'exécution de code (voir « Sécurité »). Un poste qui installe le moteur
# par npm reste servi par la branche $HOME, celle que pose l'installeur officiel.
#
# --hook change UNIQUEMENT le format d'affichage (parité d'interface avec les trois autres gates du
# module) ; ce script n'a qu'un seul gabarit de signal, donc --hook n'altère aucun rendu — il ne
# sert qu'à la cohérence d'interface et au gate de mutuelle exclusion avec --quiet. Les 3 exits
# (0/3/64) restent identiques avec ou sans --hook.
#
# Interdit dans ce script (critères machine du plan) : aucun appel à eval, aucun bash -c sur une
# valeur lue depuis le fichier audité ou depuis la sortie node (T-23-02-01) ; et, dans le programme
# node, aucun chargement de module hors des modules cœur — tout appel de chargement y porte
# exactement sur fs ou sur path, jamais sur un chemin construit depuis le dossier du moteur
# (T-23-02-07). Les deux sont vérifiés par la suite dédiée.
#
# Exit codes:
#   0  = au moins un signal [gsd-config] émis — clés inconnues, toggles non écrits, OU moteur lu
#        mais illisible (« gate périmé », arbitrage A-9 : ce cas PARLE, il ne se tait plus en 3)
#   3  = rien à signaler (fichier audité absent ou illisible, JSON invalide, moteur introuvable,
#        node absent, ou lab aligné)
#   64 = argument inconnu, --path sans valeur (ou valeur vide), ou --hook + --quiet ensemble
#
# CONTRAT FERMÉ : {0, 3, 64} et RIEN D'AUTRE. Aucun chemin d'échec ne doit en sortir — HOME non
# défini inclus (référence guardée `${HOME:-}` dans la cascade : sous set -u une référence nue y
# sortait en 1 avec un message sur stderr MALGRÉ --quiet). La suite dédiée porte un balayage final
# qui rejoue toutes les fixtures et échoue sur tout rc hors de cet ensemble.
set -uo pipefail

ROOT="."
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      # La valeur VIDE est refusée au même titre que l'absence de valeur : `--path ""` passerait
      # le seul test de comptage et déplacerait silencieusement la cible sur /.planning/config.json.
      # (Le court-circuit de `||` garantit que "$2" n'est évalué que s'il existe, sous set -u.)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "[check-gsd-config] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    # --help rend le BLOC D'EN-TÊTE et lui seul : la lecture s'arrête à la première ligne non
    # commentée du fichier. Un `grep '^# '` sur tout le fichier ramasserait aussi les commentaires
    # d'implémentation et écraserait la mise en page de l'aide.
    -h|--help) awk 'NR==1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"; exit 0 ;;
    *) echo "[check-gsd-config] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique (même position que dans l'analogue).
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-gsd-config] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

say() { [ "$QUIET" -eq 1 ] || echo "[check-gsd-config] $*" >&2; }

# --- Fichier audité -----------------------------------------------------------------------------
CONFIG_PATH="${VF_CONFIG_PATH:-$ROOT/.planning/config.json}"

if [ ! -f "$CONFIG_PATH" ]; then
  say "$CONFIG_PATH introuvable — rien à constater."
  exit 3
fi

# --- Résolution du moteur -----------------------------------------------------------------------
# VF_GSD_CORE_LIB, s'il est défini, remplace la cascade (voir en-tête).
LIB=""
if [ -n "${VF_GSD_CORE_LIB:-}" ]; then
  [ -f "$VF_GSD_CORE_LIB/config.cjs" ] && LIB="$VF_GSD_CORE_LIB"
else
  # DEUX branches, et pas trois : voir « Cascade de résolution » en en-tête pour la branche retirée.
  for candidate in \
    "$ROOT/.claude/gsd-core/bin/lib" \
    "${HOME:-}/.claude/gsd-core/bin/lib"
  do
    if [ -f "$candidate/config.cjs" ]; then LIB="$candidate"; break; fi
  done
fi

if [ -z "$LIB" ]; then
  say "moteur gsd-core introuvable — un gate qui ne peut rien constater ne prétend rien."
  exit 3
fi

if ! command -v node >/dev/null 2>&1; then
  say "node introuvable — rien à constater."
  exit 3
fi

# --- Liste arbitrée des toggles de cycle (D-19) -------------------------------------------------
# CHOIX DE DOCTRINE, volontairement COURT et NON dérivé du registre : ce sont les cinq toggles que
# la Phase 23 arbitre réellement. Inventorier les 44 capabilities du moteur est explicitement
# écarté par D-19 (candidat Phase 24) — un gate qui réclamerait l'écriture des 58 clés de
# capability transformerait un signal utile en bruit permanent.
ARBITRATED_TOGGLES="workflow.code_review workflow.pattern_mapper workflow.node_repair workflow.node_repair_budget workflow.ui_review"

# --- Extraction des faits (côté node : aucune interpolation shell de contenu de fichier) --------
# Portabilité (ADR-054, bash 3.2 macOS) : le programme est chargé par `read -r -d ''` et SURTOUT
# PAS par `NODE_PROG=$(cat <<'NODEJS' … )`. bash 3.2 scanne le corps d'un here-doc imbriqué dans une
# substitution de commande à la recherche de quotes : la moindre apostrophe française dans un
# commentaire JS (« l'exporte », « d'un ») y ouvre une chaîne fantôme et casse le script entier avec
# une erreur de syntaxe pointant des dizaines de lignes plus bas. Vérifié sur bash 3.2.57.
IFS= read -r -d '' NODE_PROG <<'NODEJS' || true
const fs = require('fs');
const path = require('path');
const LIB = process.env.VF_LIB || '';
const CFG = process.env.VF_CFG || '';
const ARB = (process.env.VF_ARB || '').split(/\s+/).filter(Boolean);

// --- Acquisition par LECTURE, jamais par exécution (T-23-02-07, arbitrage A-6) -----------------
// Le moteur résolu peut venir du dépôt audité (première branche de la cascade) : il est donc une
// entrée non maîtrisée. Rien ici ne le charge comme un module — un fichier lu ne peut pas
// s'exécuter, quelle que soit sa provenance. Deux formes sont lues, dans cet ordre : manifeste
// JSON de bin/shared, puis littéral JS du module de bin/lib. Voir l'en-tête pour le pourquoi des
// deux formes, et pour la limite que la lecture de texte introduit.
const SHARED = path.join(LIB, '..', 'shared');

// --- GARDE DE TYPE ET DE TAILLE, AVANT TOUTE LECTURE (T-23-02-03, arbitrage A-14) --------------
// Ne pas exécuter ferme l'exécution de code, PAS le déni de service. Le pire cas n'est pas une
// extraction vide, c'est une ATTENTE NON BORNÉE : une FIFO, ou un lien vers /dev/zero, déposé sur
// l'une des cibles lues dans le dépôt audité BLOQUAIT le SessionStart indéfiniment (mesuré, jamais
// terminé). Le `|| true` du hook ne raccourcit pas une attente, et le contrat de sortie ne
// s'applique pas à un processus qui n'a pas fini.
//
// TROIS PROPRIÉTÉS, dans cet ordre, et aucune n'est décorative :
//   1. O_NONBLOCK À L'OUVERTURE — ouvrir une FIFO en lecture seule BLOQUE jusqu'à ce qu'un écrivain
//      se présente. C'est l'attente non bornée elle-même : elle a lieu DANS open(), avant qu'aucun
//      stat n'ait pu la refuser. Avec ce drapeau l'ouverture rend la main immédiatement, quel que
//      soit le type du chemin. Sur un fichier ordinaire, le drapeau est sans effet.
//   2. fstat SUR LE DESCRIPTEUR, jamais stat sur le chemin — c'est ce qui supprime la fenêtre
//      entre la vérification et la lecture : le type et la taille sont constatés sur l'objet
//      EXACTEMENT lu ensuite, pas sur ce que le chemin désignait un instant plus tôt. Un lien
//      symbolique est suivi à l'ouverture, donc un lien vers une FIFO ou vers /dev/zero est
//      constaté pour ce qu'il est.
//   3. TAILLE PLAFONNÉE — le plafond vaut environ sept fois le plus gros module réel du moteur
//      (capability-registry.cjs, 273 Ko sur gsd-core 1.9.0) : large pour toute croissance normale,
//      fini pour une entrée hostile. Au-delà, le fichier est REFUSÉ, jamais tronqué — une lecture
//      partielle couperait un littéral en deux et ferait lire FAUX là où l'on veut ne rien lire.
//
// Un refus est un `null`, c'est-à-dire exactement ce que rend un fichier absent : il reste DANS le
// contrat de sortie {0, 3, 64}, et il ressort par le signal « moteur illisible » ci-dessous plutôt
// que par un silence. La garde s'applique à TOUTES les cibles sans exception, y compris config.cjs
// (déjà filtré par le `[ -f ]` de la cascade — la garde ferme ici la fenêtre entre ce test et la
// lecture) et y compris le fichier audité lui-même.
const MAX_LU = 2 * 1024 * 1024;
const O_NB = fs.constants.O_NONBLOCK || 0;
function slurp(p) {
  let fd = -1;
  try {
    fd = fs.openSync(p, fs.constants.O_RDONLY | O_NB);
    const st = fs.fstatSync(fd);
    if (!st.isFile() || st.size > MAX_LU) return null;
    return fs.readFileSync(fd, 'utf8');
  } catch (e) { return null; }
  finally { if (fd >= 0) { try { fs.closeSync(fd); } catch (e) {} } }
}
function readJSON(p) { const s = slurp(p); if (s === null) return null; try { return JSON.parse(s); } catch (e) { return null; } }

// Régions à délimiteurs équilibrés ouvertes par une ancre. TOUTES les occurrences de l'ancre sont
// rendues (bornées à 8), pas seulement la première : un module de 273 Ko peut porter une occurrence
// décorative avant la vraie déclaration, et s'arrêter à la première rendrait une liste vide.
// Les chaînes sont traversées sans compter leurs délimiteurs, sinon une accolade dans un libellé
// fermerait la région trop tôt.
function balancedRegions(src, anchorSrc, open, close) {
  const out = [];
  const re = new RegExp(anchorSrc, 'g');
  let m;
  while ((m = re.exec(src)) !== null) {
    const start = m.index + m[0].length - 1;   // l'ancre se termine SUR le délimiteur ouvrant
    let depth = 0, inStr = null, esc = false;
    for (let j = start; j < src.length; j++) {
      const c = src[j];
      if (inStr) { if (esc) esc = false; else if (c === '\\') esc = true; else if (c === inStr) inStr = null; continue; }
      if (c === '"' || c === "'" || c === '`') { inStr = c; continue; }
      if (c === open) depth++;
      else if (c === close) { depth--; if (depth === 0) { out.push(src.slice(start, j + 1)); break; } }
    }
    if (out.length >= 8) break;
    if (re.lastIndex <= m.index) re.lastIndex = m.index + 1;
  }
  return out;
}

// Littéral JS « simple » -> JSON. Couvre ce qu'un module de configuration écrit réellement :
// identifiants nus en clé, quotes simples, virgules traînantes, commentaires. Tout le reste
// (variable, appel, spread, opérateur) fait échouer JSON.parse et rend null — c'est VOULU : mieux
// vaut ne rien lire que lire faux. Le prix est nommé en en-tête (LIMITE DE LA LECTURE DE TEXTE).
//
// COÛT LINÉAIRE, EXIGÉ (T-23-02-03) : la région parsée vient du dépôt audité, donc d'un attaquant.
// Deux tournures ont été bannies ici parce qu'elles rendaient la boucle QUADRATIQUE, et qu'un
// parseur quadratique sur une entrée hostile est un déni de service au SessionStart — que ni le
// `|| true` du hook ni le contrat de sortie ne raccourcissent, un processus qui n'a pas fini ne
// sortant pas :
//   - `.exec(txt.slice(i))` à chaque caractère       -> regex COLLANTE (`/…/y`) + `lastIndex = i` ;
//   - `out.replace(/\s+$/, '')` à chaque identifiant -> `lastNb`, suivi INCRÉMENTAL du dernier
//     caractère non blanc déjà émis (même définition de « blanc » que `\s`, d'où le `/\s/.test`).
// Les deux réécritures sont à comportement STRICTEMENT identique : mêmes clés produites.
const IDRE = /([A-Za-z_$][A-Za-z0-9_$]*)(\s*):/y;
function jsLiteralToJSON(txt) {
  let out = '', i = 0, lastNb = ''; const n = txt.length;
  while (i < n) {
    const c = txt[i];
    if (c === '"' || c === "'") {
      const q = c; let j = i + 1, buf = '';
      while (j < n) { if (txt[j] === '\\') { buf += txt[j] + txt[j + 1]; j += 2; continue; } if (txt[j] === q) break; buf += txt[j]; j++; }
      out += JSON.stringify(buf.replace(/\\'/g, "'")); lastNb = '"'; i = j + 1; continue;
    }
    if (c === '/' && txt[i + 1] === '/') { while (i < n && txt[i] !== '\n') i++; continue; }
    if (c === '/' && txt[i + 1] === '*') { const e = txt.indexOf('*/', i); if (e < 0) return null; i = e + 2; continue; }
    IDRE.lastIndex = i;
    const idm = IDRE.exec(txt);
    if (idm && idm[1] !== 'true' && idm[1] !== 'false' && idm[1] !== 'null'
        && (lastNb === '' || lastNb === '{' || lastNb === ',')) {
      out += '"' + idm[1] + '":'; lastNb = ':'; i += idm[0].length; continue;
    }
    out += c; if (!/\s/.test(c)) lastNb = c; i++;
  }
  out = out.replace(/,(\s*[}\]])/g, '$1');
  try { return JSON.parse(out); } catch (e) { return null; }
}

// Premier littéral, dans la liste de fichiers donnée, qui satisfait `accept`.
function readLiteral(files, anchorSrc, open, close, accept) {
  for (const f of files) {
    const src = slurp(path.join(LIB, f));
    if (src === null) continue;
    for (const reg of balancedRegions(src, anchorSrc, open, close)) {
      const v = jsLiteralToJSON(reg);
      if (v !== null && accept(v)) return v;
    }
  }
  return null;
}

// Jetons encodés en JSON : ni tabulation, ni saut de ligne, ni octet de contrôle brut ne peuvent
// franchir la frontière vers bash (T-23-02-01).
const J = s => JSON.stringify(String(s));
const out = [];

// --- Le fichier audité est lu AVANT le moteur (arbitrage A-9) ----------------------------------
// L'ordre porte une décision : sans fichier audité lisible, il n'y a rien à comparer, donc rien à
// dire — pas même que le moteur est illisible. Lire le moteur d'abord ferait sortir un signal
// « gate périmé » sur un lab dont le config.json est absent ou cassé, c'est-à-dire du bruit là où
// le script n'a aucune constatation à faire. Ce fichier passe par la MÊME garde que le moteur.
const cfgSrc = slurp(CFG);
if (cfgSrc === null) process.exit(3);
let cfg;
try { cfg = JSON.parse(cfgSrc); } catch (e) { process.exit(3); }
if (!cfg || typeof cfg !== 'object' || Array.isArray(cfg)) process.exit(3);

// --- Lisibilité de chaque source : constatée, jamais supposée (arbitrage A-9, O-13 voie b) -----
// Une source qui ne rend RIEN n'est pas la même chose qu'un moteur introuvable, et ce script ne
// doit plus confondre les deux dans un seul exit 3 muet. `stale` accumule le NOM des sources qui
// n'ont rien rendu ; il ressort en signal explicite, dans le contrat {0, 3, 64} inchangé.
// Ce que le script observe est l'ABSENCE de donnée lisible, JAMAIS sa cause (ADR-055 §3) : porteur
// manquant, manifeste déplacé, valeur calculée et littéral illisible produisent le même constat.
const stale = [];

// Source 1 — VALID_CONFIG_KEYS, et les topLevel des motifs dynamiques (même manifeste).
const SCHEMA = readJSON(path.join(SHARED, 'config-schema.manifest.json'));
let validArr = (SCHEMA && Array.isArray(SCHEMA.validKeys)) ? SCHEMA.validKeys.filter(x => typeof x === 'string') : [];
if (validArr.length === 0) {
  const a = readLiteral(['config.cjs', 'configuration.cjs', 'config-schema.cjs'],
    'VALID_CONFIG_KEYS\\s*[:=]\\s*new Set\\(\\s*\\[', '[', ']',
    v => Array.isArray(v) && v.some(x => typeof x === 'string'));
  if (a) validArr = a.filter(x => typeof x === 'string');
}
if (validArr.length === 0) stale.push('VALID_CONFIG_KEYS');

let dynPat = (SCHEMA && Array.isArray(SCHEMA.dynamicKeyPatterns)) ? SCHEMA.dynamicKeyPatterns : null;
if (!dynPat) dynPat = readLiteral(['configuration.cjs', 'config.cjs', 'config-schema.cjs'],
  'DYNAMIC_KEY_PATTERNS\\s*[:=]\\s*\\[', '[', ']', v => Array.isArray(v));
const dynTop = (dynPat || []).map(p => p && p.topLevel).filter(x => typeof x === 'string');

// Source 2 — configKeys du registre de capabilities (objet plat, compatible JSON).
const ckObj = readLiteral(['capability-registry.cjs'], '\\bconfigKeys\\s*[:=]\\s*\\{', '{', '}',
  v => v && typeof v === 'object' && !Array.isArray(v));
const ck = ckObj ? Object.keys(ckObj) : [];
if (!ckObj) stale.push('configKeys');

// Source 3 — CONFIG_DEFAULTS canoniques (donne aussi la VALEUR des défauts amont).
// `defaultsRead` distingue « lu, et vide » de « pas lu du tout » — un CONFIG_DEFAULTS réellement
// vide est une donnée, pas une panne, et le confondre avec le repli `{}` ferait crier au périmé un
// moteur parfaitement lisible.
let defaultsRead = true;
let DEFAULTS = readJSON(path.join(SHARED, 'config-defaults.manifest.json'));
if (!DEFAULTS || typeof DEFAULTS !== 'object' || Array.isArray(DEFAULTS)) {
  DEFAULTS = readLiteral(['configuration.cjs', 'config-loader.cjs', 'config.cjs'],
    'CONFIG_DEFAULTS\\s*[:=]\\s*\\{', '{', '}',
    v => v && typeof v === 'object' && !Array.isArray(v));
  if (!DEFAULTS) { DEFAULTS = {}; defaultsRead = false; stale.push('CONFIG_DEFAULTS'); }
}

// Aucune clé connue lisible : plus AUCUNE comparaison n'a de sens (tout serait signalé). Le script
// ne prétend toujours rien — mais il ne se tait plus dans le même code que « rien à signaler ».
if (validArr.length === 0) {
  process.stdout.write('ENGINE_STALE\t' + J(stale.join(', ')) + '\n');
  process.exit(0);
}
if (stale.length > 0) out.push('ENGINE_STALE\t' + J(stale.join(', ')));

function flatten(o, prefix, out, withContainers) {
  for (const k of Object.keys(o)) {
    const v = o[k];
    const kp = prefix ? prefix + '.' + k : k;
    const isObj = v && typeof v === 'object' && !Array.isArray(v);
    if (isObj) { if (withContainers) out.push(kp); flatten(v, kp, out, withContainers); }
    else out.push(kp);
  }
  return out;
}

const KNOWN = new Set([].concat(validArr, ck, flatten(DEFAULTS, '', [], true)));

// Miroir exact du KNOWN_TOP_LEVEL du moteur (config-loader.cjs) : premiers segments des clés
// connues + topLevel des motifs dynamiques + les littéraux que le moteur ajoute en dur.
//
// engineExtra est la SEULE liste écrite à la main de ce script (exception nommée en en-tête) : ces
// littéraux ne sont exportés par aucun module de bin/lib, donc pas lisibles dynamiquement. Plusieurs
// d'entre eux (depth, multiRepo, branching_strategy, research en premier niveau) n'existent dans
// AUCUNE des trois sources dynamiques : les retirer parce qu'ils « semblent redondants » rouvrirait
// un faux positif. La redondance apparente des autres est délibérément CONSERVÉE — la couverture par
// les sources dynamiques dépend de la version du moteur, et un mirroir fidèle reste juste même si
// une version future retire l'une de ces clés de ses listes exportées.
const engineExtra = ['model_overrides', 'context_window', 'resolve_model_ids', 'claude_md_path',
  'effort', 'fast_mode', 'depth', 'multiRepo', 'branching_strategy', 'research'];
const KNOWN_TOP = new Set([].concat(
  Array.from(KNOWN).map(k => k.split('.')[0]), dynTop, engineExtra));

// Conteneurs qui déclarent au moins un enfant connu (les autres sont opaques — voir en-tête).
const hasChildren = new Set();
for (const k of KNOWN) { const i = k.indexOf('.'); if (i > 0) hasChildren.add(k.slice(0, i)); }

for (const k of Object.keys(cfg)) {
  if (!KNOWN_TOP.has(k)) out.push('UNKNOWN_BLOCK\t' + J(k));
}

for (const k of Object.keys(cfg)) {
  if (!KNOWN_TOP.has(k)) continue;   // déjà signalé en tant que bloc
  if (!hasChildren.has(k)) continue; // conteneur opaque pour le moteur
  const v = cfg[k];
  if (!v || typeof v !== 'object' || Array.isArray(v)) continue;
  for (const leaf of flatten(v, k, [], false)) {
    if (!KNOWN.has(leaf)) out.push('UNKNOWN_KEY\t' + J(leaf));
  }
}

function lookup(o, dotted) {
  let cur = o;
  for (const p of dotted.split('.')) {
    if (cur && typeof cur === 'object' && Object.prototype.hasOwnProperty.call(cur, p)) cur = cur[p];
    else return { found: false };
  }
  return { found: true, value: cur };
}

for (const t of ARB) {
  if (lookup(cfg, t).found) continue;           // état 1 : écrit → rien à signaler
  const up = lookup(DEFAULTS, t);
  if (up.found) out.push('TOGGLE_DEFAULT\t' + J(t) + '\t' + J(up.value));  // état 2
  // état 3 vs état 4 : « il n'y a pas de défaut » et « je n'ai pas pu lire les défauts » sont deux
  // constats DIFFÉRENTS, et les confondre était le mode d'échec le plus grave de la lecture de
  // texte (arbitrage A-9) — le script AFFIRMAIT une absence là où il y avait une valeur qu'il
  // n'avait pas su lire. Quand la source 3 n'a rien rendu, il ne conclut plus : il le dit.
  else if (!defaultsRead) out.push('TOGGLE_UNREADABLE\t' + J(t));           // état 4 : état inconnu
  else out.push('TOGGLE_ABSENT\t' + J(t));                                  // état 3 : sans valeur
}

process.stdout.write(out.map(l => l + '\n').join(''));
NODEJS

RAW="$(VF_LIB="$LIB" VF_CFG="$CONFIG_PATH" VF_ARB="$ARBITRATED_TOGGLES" node -e "$NODE_PROG" 2>/dev/null)"
NODE_RC=$?

if [ "$NODE_RC" -ne 0 ]; then
  say "clés connues illisibles depuis $LIB ou $CONFIG_PATH illisible — rien à constater."
  exit 3
fi

# --- Comparaison et mise en forme (côté bash) ---------------------------------------------------
# Retire les guillemets encadrants d'un jeton JSON. Les échappements internes (\uXXXX pour un octet
# de contrôle) sont VOLONTAIREMENT conservés : c'est ce qui garantit qu'aucun octet brut hostile ne
# ressort dans la sortie de session.
unq() { local s="$1"; s="${s#\"}"; s="${s%\"}"; printf '%s' "$s"; }

BLOCKS=""
SUBKEYS=""
TOGGLE_LINES=""
STALE_SOURCES=""
N_STALE=0
# ACCUMULATEUR ≠ VALEUR : le fichier audité est hostile par hypothèse et peut porter une clé VIDE
# ("" ou une sous-clé vide). Tester la vacuité de la chaîne accumulée confondrait « rien accumulé »
# et « une seule clé, vide » — une entrée de deux octets faisait alors taire TOUT le volet « clés
# inconnues ». Le nombre d'entrées est donc compté, jamais déduit de la chaîne.
N_BLOCKS=0
N_SUBKEYS=0
N_TOGGLES=0

# Un nom de clé vide n'est rien à l'écran : il est rendu sous sa forme JSON ("") pour rester
# lisible et actionnable, plutôt que d'imprimer un blanc entre deux virgules.
vis() { [ -n "$1" ] && printf '%s' "$1" || printf '%s' '""'; }

while IFS="$(printf '\t')" read -r kind f1 f2; do
  [ -n "$kind" ] || continue
  case "$kind" in
    ENGINE_STALE)
      # Le NOMBRE d'entrées fait foi, jamais la vacuité de la chaîne : « aucune source périmée » et
      # « une source dont le nom serait vide » doivent rester distinguables (même piège que les
      # accumulateurs de clés ci-dessus).
      STALE_SOURCES="$(unq "$f1")"
      N_STALE=$((N_STALE+1)) ;;
    UNKNOWN_BLOCK)
      k="$(vis "$(unq "$f1")")"
      if [ "$N_BLOCKS" -eq 0 ]; then BLOCKS="$k"; else BLOCKS="$BLOCKS, $k"; fi
      N_BLOCKS=$((N_BLOCKS+1)) ;;
    UNKNOWN_KEY)
      k="$(vis "$(unq "$f1")")"
      if [ "$N_SUBKEYS" -eq 0 ]; then SUBKEYS="$k"; else SUBKEYS="$SUBKEYS, $k"; fi
      N_SUBKEYS=$((N_SUBKEYS+1)) ;;
    TOGGLE_DEFAULT)
      t="$(unq "$f1")"; v="$(unq "$f2")"
      TOGGLE_LINES="${TOGGLE_LINES}             - ${t} : non écrit, au défaut amont (${v})
"
      N_TOGGLES=$((N_TOGGLES+1)) ;;
    TOGGLE_ABSENT)
      # Le script n'observe QUE l'absence de défaut lisible. Il n'observe pas POURQUOI, et
      # n'invoque donc aucune cause (« résolu par la capability elle-même » était une cause
      # FABRIQUÉE : node_repair/node_repair_budget ne sont pas des capabilities).
      t="$(unq "$f1")"
      TOGGLE_LINES="${TOGGLE_LINES}             - ${t} : non écrit, et sans défaut lisible dans le moteur — aucune valeur à afficher
"
      N_TOGGLES=$((N_TOGGLES+1)) ;;
    TOGGLE_UNREADABLE)
      # NE PAS confondre avec TOGGLE_ABSENT : ici les défauts amont n'ont pas pu être lus du tout,
      # donc l'état du toggle est INCONNU. Dire « sans défaut lisible » reviendrait à affirmer une
      # absence que le script n'a pas constatée.
      t="$(unq "$f1")"
      TOGGLE_LINES="${TOGGLE_LINES}             - ${t} : non écrit, et les défauts amont n'ont pas pu être lus — état INCONNU, pas une absence
"
      N_TOGGLES=$((N_TOGGLES+1)) ;;
  esac
done <<EOF
$RAW
EOF

SIGNAL=0

# Ce volet passe EN PREMIER, et ce n'est pas cosmétique : il qualifie tout ce qui suit. Un constat
# rendu par un gate dont une source est illisible peut être faux dans les deux sens (clé légitime
# signalée, clé inconnue épargnée) ; le lire après les constats les laisserait passer pour fermes.
if [ "$N_STALE" -gt 0 ]; then
  printf '%s\n' "[gsd-config] moteur GSD lu depuis ${LIB}, mais une source de clés connues n'a rien rendu : ${STALE_SOURCES}"
  printf '%s\n' "             → ce gate est PÉRIMÉ sur ce moteur, ce n'est PAS « rien à signaler » : sa lecture de"
  printf '%s\n' "               texte ne suit plus la forme du moteur installé. Les constats ci-dessous, s'il y en a,"
  printf '%s\n' "               peuvent être faux dans les deux sens tant que ce point n'est pas traité."
  SIGNAL=1
fi

if [ "$N_BLOCKS" -gt 0 ]; then
  printf '%s\n' "[gsd-config] clés inconnues du moteur GSD installé dans ${CONFIG_PATH} : ${BLOCKS}"
  printf '%s\n' "             → le moteur les ignore ; les retirer ou écrire leur équivalent amont."
  SIGNAL=1
fi

if [ "$N_SUBKEYS" -gt 0 ]; then
  printf '%s\n' "[gsd-config] sous-clés inconnues sous un conteneur connu : ${SUBKEYS}"
  printf '%s\n' "             → le moteur les ignore ; les retirer ou écrire leur équivalent amont."
  SIGNAL=1
fi

if [ "$N_TOGGLES" -gt 0 ]; then
  printf '%s\n' "[gsd-config] toggles de cycle non écrits dans ${CONFIG_PATH} — ce lab les pilote par omission :"
  printf '%s' "$TOGGLE_LINES"
  printf '%s\n' "             → les écrire à une valeur décidée rend le choix explicite."
  SIGNAL=1
fi

if [ "$SIGNAL" -eq 1 ]; then
  say "signal émis sur $CONFIG_PATH (moteur lu depuis $LIB)."
  exit 0
fi

say "$CONFIG_PATH est aligné sur le moteur ($LIB) — rien à signaler."
exit 3
