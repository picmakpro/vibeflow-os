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
#   suite <chemin> [--exige=<libellé>]… [--montre=<motif>]… [--duree-max=base] [--detache=<dossier>] [--shells=bash|bash,zsh]
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
#   armement --gate=<G4|G4P> --releve=<relevé> --etape=<5|6> [--lab=<lab affiché>]… [--verificateur=<script>]
#            [--simuler-arme] [--garder-g4]
#                  Une constante d'armement à `armed` est couplée à un relevé armable du MÊME code (P461-D-07).
#   etat-reference [--reference=<fichier>] [--hook=<fichier>] [--tests=<fichier>]
#                  La phrase d'état d'armement de la référence concorde avec les constantes et les limites présentes.
#   imputer <suite> --commit=<sha> [options de suite] [--detache=<dossier>]   imputation d'un rouge (P461-D-16).
#   jalon <1|2|3>  lecture des jalons du manager (46.1-JALONS.txt), jamais un vert à vide (P461-D-16).
#   empreinte [--geler]                          gel de l'outil par empreinte sha256 et par l'historique git.
#   --autotest [--sans-reel]
#                  Preuve que chaque contrôle sait rougir pour sa raison (fausses suites, faux dépôts, fausse base) ;
#                  les cas `reel-*` rejouent de VRAIES suites du dépôt sur un clone partagé (entrée perturbée, sortie
#                  jamais réécrite) ; `--sans-reel` les omet (AUTOTEST-PARTIEL, jamais la preuve finale d'une tâche de gel).
#   --help         Cet en-tête.
#   (Posés par 46.1-17 : l'option --montre et les modes armement, etat-reference, imputer, jalon, empreinte. Elle
#   FIGE ensuite l'outil : voir EMPREINTE.)
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
# MONTRE (`suite … --montre=<motif>`, répétable ; P461-D-16). Demander une ligne vaut l'EXIGER. Comparaison LITTÉRALE de
# chaînes (aucune expression régulière, un point est un point ; motif vide : 64) : une ligne de la sortie complète
# correspond si elle COMMENCE par le motif, espaces de tête compris (`'  ✓ PF-EVT-04'` vise la ligne de contrôle,
# `'COMPTE G4 '` la ligne de compte, jamais une ligne `  ✓ …` qui la cite). Pour chaque lancement, chaque ligne qui
# correspond est imprimée telle quelle, dans l'ordre de la sortie, `SUITE-MONTRE <shell> : <ligne>`, suite verte ou
# rouge ; au plus 50 par motif, puis `SUITE-NOTE montre-tronque <motif> reste=<n>`. Un motif qu'aucune ligne ne commence
# est l'écart `SUITE-ECART montre-absent <motif>` (code 1). La ligne `SUITE …` gagne `montres=<trouvés>/<demandés>`. Avec
# --detache, `sonder` imprime les lignes SUITE-MONTRE du rejeu. Chaque motif de rouge de `suite` (ko, non-tue, bilan,
# bilan zero-ok) est éprouvé sur la VRAIE sortie d'une suite réelle (cas reel-*).
#
# ARMEMENT (`armement --gate=<G4|G4P> --releve=<relevé> --etape=<5|6> …` ; P461-D-07, ARMG-05, ARMG-09). Lit dans
# l'arbre de travail l'unique ligne `ARMEMENT_<gate> = "(armed|observe)"  # etape-<n>` (fonction lire_constante, partagée
# avec etat-reference ; zéro, plusieurs ou autre valeur : `ARMEMENT-ECART constante-illisible`). `--etape` est l'étape du
# RELEVÉ présenté — passée à `releve` et au vérificateur, et portée par le verdict frais — jamais comparée au suffixe
# `# etape-<n>` de la constante : G4 (`# etape-5`) se couple aussi à un relevé d'étape 6 (P461-D-17) ; un relevé d'étape 5
# (`gates=G3,G4`) ne peut pas armer G4′ (`releve-non-armable`). `observe` sans --simuler-arme : `ARMEMENT <gate> observe :
# rien à justifier`, code 0. `armed` ou --simuler-arme : (a) cohérence du relevé (la fonction de `releve`, aucune copie ;
# sinon `releve-incoherent`) ; (b) rejeu joué (`releve-non-joue`) ; (c) verdict FRAIS du vérificateur en code 0, dernière
# ligne `RELEVE-VERDICT armable etape=<étape> … gates=<liste>` nommant le gate (`releve-non-armable`) ; (d) exactement une
# ligne `COMMIT-REJOUE <sha>` (`commit-rejoue-absent`, `commit-rejoue-doublon`), commit connu (`commit-inconnu`) et ancêtre
# de HEAD (`commit-non-ancetre`) ; (e) surface mesurée — planning-hook.sh et hooks.json — identique octet pour octet entre
# `git show <sha>:<fichier>` et l'arbre de travail, la valeur de chaque ligne `ARMEMENT_*` remplacée par un jeton fixe
# des deux côtés (`ARMEMENT-ECART code-diverge <fichier> commits=<n>`, `arbre-de-travail` si la différence n'est pas
# commitée). LIMITE de « même code mesuré » : identité d'octets de la surface mesurée, valeurs ARMEMENT_* exceptées, aucune
# équivalence sémantique ; les outils de rejeu hors surface mesurent, ils ne sont pas mesurés ; après l'armement de G4,
# seule la fermeture d'evaluer_g4 est figée par invariants (g4-fige) — le dispatcher (main, cible_de) et la commande
# enregistrée ne sont remesurés sur le réel que par le relevé de l'étape 6 s'il est joué. Lignes `ARMEMENT <gate>
# <armed|observe|simule>`, `ARMEMENT-ECART <motif>`, `ARMEMENT-COHERENCE ok|ECART`. Aucun lab n'est lu.
#   --garder-g4 (seulement --gate=G4, sans --simuler-arme ; autrement 64) porte la disjonction de P461-D-17 : code 0 si
#   `armement` seul rendrait 0, OU si — `armement` seul rendant 1 — ARMEMENT_G4 vaut `armed  # etape-5`, le relevé existe et
#   porte EXACTEMENT une ligne `DECISION-G4`, de la forme `DECISION-G4 garder-g4 canal=<non vide> date=AAAA-MM-JJ` (date
#   de calendrier valide) : ligne `ARMEMENT G4 armed : non remesuré, décision garder-g4 canal=… date=…`, le motif
#   d'`armement` seul rappelé en ARMEMENT-ECART. Chaque raison de refus est UNE ligne `ARMEMENT-ECART decision-g4-<motif>` :
#   absente · doublon · observation · forme · canal-vide · date-forme (mauvaise forme) · date-invalide (bonne forme,
#   calendrier invalide) · releve-absent · constante-illisible · constante-non-armee. La décision n'excuse rien sans
#   l'option. L'option lit la ligne, elle n'en juge jamais la véracité (même régime que `Gate-Touche:`).
#
# ÉTAT D'ARMEMENT DE LA RÉFÉRENCE (`etat-reference` ; P461-D-07, ARMG-10). Compare TOUTE phrase de modele-cycles.md qui
# énonce l'état d'un gate aux constantes ARMEMENT_* du hook et aux limites réellement présentes de LIMITES_REFERENCE
# (tuple extrait par bornes de lignes puis ast.literal_eval). Grammaire FERMÉE à quatre formes, relevée sur la référence
# réelle (expression exacte de chacune : en tête du Python embarqué, ecrire_py_etat) : K1 clause de constante (`ARMEMENT_<X>`
# … vaut|valent `armed`|`observe`) ; K2 résumé entre parenthèses « (G3 armé ; G4 et G4′ en observation, limites (bp) et
# (bs)) » (chaque lettre citée figure dans LIMITES_REFERENCE ET porte sa ligne canonique `- **limite (xx)**`) ; K3 ligne de
# la table d'armement (état et étape égaux à la constante ; G2 : G2_MODE ; une constante sans ligne, ou une ligne sans
# constante, est un écart) ; K4 affirmation ancrée (« G4′ reste en observation », « G3, est armé », « G3 (étape 5a, armée
# seule) »). Exclusions déclarées (`ETAT-IGNORE`) : occurrence précédée dans sa proposition de `si `, `tant que `, `quand `,
# `dès que `, `une fois `, `exige ` ou `avant `, ou suivie de ` sans ` (condition, exigence, hypothèse). Résidu VISIBLE,
# jamais tu : toute proposition qui nomme un gate ET un état et qu'aucune forme ne reconnaît est `ETAT-NON-RECONNUE`
# (information, non rouge). Rouge : `ETAT-ECART <forme> ligne=<n> <gate> dit=<état> constante=<état>` · `limite-absente`
# · `limite-sans-ligne` · `limites-illisibles` · `constante-illisible <X>` · `gate-non-couvert <gate>` (une constante
# nommée par AUCUNE phrase K1, K2 ou K4 : une phrase reformulée hors grammaire ne passe jamais en silence) ·
# `aucune-phrase`. Lignes `ETAT <forme> ligne=<n> gates=… dit=… ok` et `ETAT-BILAN k1=… k2=… k3=… k4=… ignorees=…
# non-reconnues=… ecarts=…`. Ce mode compare des phrases à des constantes : il ne dit jamais qu'un gate doit être armé.
#
# IMPUTATION (`imputer <suite> --commit=<sha> [options de suite] [--detache=<dossier>]` ; P461-D-16). <sha> est le PREMIER
# commit du plan ; <sha>^ doit exister (sinon 64). Rejeux dans les mêmes conditions que `suite` (HOME temporaire, mêmes
# options) : C1 sur l'arbre courant ; C2 seulement si C1 est vert ; P sur l'export `git archive <sha>^` sous mktemp
# seulement si le rouge est reproduit (aucun checkout, stash ni reset : HEAD, index, arbre de travail et pile des stash
# sont inchangés) ; P2 seulement si P est rouge et que ses motifs recouvrent ceux du courant. Décision : C1 et C2 verts =
# `instable` (cause=non-reproduit) ; rouge reproduit et suite absente de P (suite-neuve) ou P vert = `imputable` ; P
# rouge : un motif SUITE-ECART ou une ligne `  ✗ ` du rejeu courant qui manque à P = `imputable` (IMPUTATION-NOUVEAU) ;
# sinon P2 vert = `imputable` (le parent ne rougissait que sans dépôt) ; sinon suite sensible au dépôt = `instable`
# (cause=suite-sensible-depot, à trancher par le manager) ; sinon `preexistant`. Lignes `IMPUTATION-REJEU <suite>
# sur=<courant|parent|parent-depot> n=<k> rc=<rc> motifs=<liste>`, puis `IMPUTATION <suite> verdict=<…> rejeux=<n>
# escalade-willy=oui|non`. Code 0 : preexistant ou instable à escalade-willy=non (consigner, remonter au manager,
# poursuivre) ; 1 : imputable, ou tout verdict à escalade-willy=oui ; 64 usage. Détaché : borne = 9 × durée de base.
#   Limites de l'imputation. L'export n'a ni .git, ni historique, ni fichiers ignorés ou non suivis, ni configuration
#   locale : le rejeu sur P NE reproduit PAS le dépôt du rejeu courant. Il est suivi (si P est rouge et recouvre le
#   courant) d'un rejeu P2 sur un second export rendu dépôt par `git init` et UN commit de tout l'export (identité par
#   -c, GIT_CONFIG_GLOBAL et GIT_CONFIG_SYSTEM vers /dev/null) : P2 reproduit la présence d'un dépôt, pas son historique.
#   Une suite est « sensible au dépôt » si son source à <sha>^ contient le mot `git` (grep -w) — critère volontairement
#   large : il ne voit ni les scripts que la suite appelle ni une dépendance à la configuration, et sa conséquence
#   (`instable`) renvoie au manager, jamais à `preexistant`. Les rejeux de P et P2 ne portent aucun plafond de durée
#   (une durée dépend de la charge, pas du commit) ni la base. `escalade-willy=oui` seulement pour les douze suites de
#   SUITES_PORTEUSES (suites qui gardent un gate armé ou à armer, relevées de 46.1-PATTERNS « File Classification »).
#
# JALONS (`jalon <1|2|3>` ; P461-D-16). Lit 46.1-JALONS.txt, tenu par le MANAGER : une ligne par jalon `JALON <n>
# commit=<sha> date=<UTC> TOUTES-BILAN suites=<n> vertes=<v> rouges=<r> zero-ok=<z> s=<secondes> imputables=<i>
# preexistants=<p> instables=<q>`. Code 0 seulement si EXACTEMENT une ligne `JALON <n>` (jalon-absent, jalon-double), complète
# (jalon-forme), dont le commit est un ancêtre de HEAD (jalon-commit-non-ancetre), à imputables=0 (jalon-imputables), aux
# comptes cohérents r = p + i + q (jalon-comptes-incoherents), à découverte non partielle — suites ≥ celles de la
# BASE-BILAN (jalon-decouverte-partielle) —, et si ni planning-hook.sh ni hooks.json n'a changé depuis le commit, arbre
# de travail compris (jalon-perime). `<n>` hors 1, 2, 3 : 64. Le mode lit un fait DÉCLARÉ par le manager : il vérifie
# forme, cohérence et ancienneté, jamais la véracité (même régime que `Gate-Touche:`). Lignes `JALON-VERIF <n> ok`,
# `JALON-ECART <motif>` ; `--jalons-fichier=<chemin>` n'existe que pour l'autotest (imprime JALONS-FICHIER-ALTERNATIF).
#
# EMPREINTE (`empreinte [--geler]` ; P461-D-16). L'outil est FIGÉ à la fin de 46.1-17 : sans option, code 0 seulement si
# 46.1-CONTROLES.sha256 existe (`EMPREINTE-ECART absente`), égale octet pour octet le `shasum -a 256 46.1-CONTROLES.sh`
# lancé dans le dossier de l'outil (`modifie`), si l'outil et son .sha256 sont commités et propres (`non-commite`), si le
# .sha256 a exactement un commit (`gel-rouvert`) et si aucun commit n'a touché l'outil depuis celui-là (`commit-apres-gel
# n=<k>`). Ligne `EMPREINTE ok sha256=<h> gel=<commit>`. `--geler` écrit le .sha256 si et seulement s'il est absent et que
# l'outil est commité et propre (sinon 64) ; le commit de gel est fait ensuite.
# REGEL TRACÉ (décision du manager, 2026-10-13, née de la correction de la copie détachée, quick 261013-owa : le gel à
# commit unique ne prévoyait aucune voie pour une correction légitime, chaque plan suivant aurait commencé rouge). Un
# commit sur le .sha256 après le premier est un regel valide si et seulement s'il ne touche QUE le .sha256 et porte un
# trailer `Regel-Outil: <id quick> — <raison>` (id `\d{6}-[a-z0-9]{3}`, tiret cadratin, raison non vide ; forme et
# présence vérifiées, jamais la véracité). Sinon `gel-rouvert` ; `commit-apres-gel` se calcule depuis le DERNIER regel
# valide. Chaque regel valide imprime `EMPREINTE-REGEL <sha court> <id quick> — <raison>` AVANT la ligne de succès, qui
# garde son début `EMPREINTE ok sha256=<h> gel=<dernier commit de gel>` et ajoute ` regels=<n>`. La réouverture reste
# visible, jamais empêchée (ADR-072). Les plans suivants lancent `empreinte` dans
# la première commande `<automated>` de leur première tâche (avant de présenter à l'humain quoi que ce soit venant de
# l'outil, quand cette tâche est d'abord un checkpoint) ; rouge, l'exécuteur s'arrête et remonte, il ne répare pas : aucun
# plan suivant n'édite l'outil, rouvrir le gel est une décision du manager. LIMITE de fond (ADR-072) : une garde qui vit
# dans le dépôt peut être modifiée par la PR qu'elle juge ; un gel rouvert avec son empreinte est visible dans l'historique
# mais pas empêché.
#
# REJEU DÉTACHÉ (`suite`, `toutes` et `imputer` par --detache=<dossier>). Le dossier est créé s'il
# n'existe pas et doit être vide (sinon 64). Sans base (hors mesure de la base) ou pour une suite rouge à la base :
# 64. L'outil s'y copie (`outil.sh` : l'original reste librement éditable pendant le rejeu), écrit `commande.txt`
# (mode, options, nombre de suites), `borne.txt` (borne en secondes, calculée AVANT le lancement) et `debut.txt`
# (epoch), lance la copie en arrière-plan sous `nohup`, dans sa propre session (sortie dans `sortie.txt`, pid
# dans `pid.txt`), imprime `DETACHE <dossier> borne=<s>` et rend 0 aussitôt ; la copie écrit `fin.txt`
# (`rc=<n> fin=<epoch>`) EN DERNIER. Borne : suite = 3 × sa durée de base ; `toutes` = 2 × la durée murale de la
# BASE-BILAN ; `imputer` = 9 × durée de base (46.1-17). Exception unique, déclarée : la mesure de la base
# (`toutes --base`) n'a pas de base d'où dériver sa borne ; sa remontée de sondage est la constante
# BORNE_MESURE_BASE, et `commande.txt` porte `exception=mesure-base`. Le refus `detache-requis` (durée de base >=
# SEUIL_DETACHE) est celui de l'appel EXTERNE sans --detache : la copie détachée (--detache-interne) ne le ré-applique
# jamais, et l'`imputer` détaché passe --detache-herite=<dossier> (option INTERNE) aux rejeux de `suite` qu'il lance
# (46.1 fix-outil-01). La base est écrite par la copie à
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
# ko · non-tue · exige-absent <libellé> · montre-absent <motif> · base-absente · base-rouge · duree-plafond <n> > <max> ;
# `SUITE-NOTE …` ; `SUITE-MONTRE <shell> : <ligne>` ; `SUITE <chemin> shell=<s> rc=<rc> duree=<n> exiges=<trouvés>/<demandés>
# montres=<trouvés>/<demandés>` par lancement.
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
#   FACTEUR_IMPUTER=9      borne d'un rejeu détaché `imputer` = 9 × la durée de base de la suite (trois rejeux au plus,
#                          chacun sous son plafond de 3 × la base)
#   SUITES_PORTEUSES       les douze suites qui gardent un gate armé ou à armer (liste du contrat commun de 46.1-14,
#                          ni plus ni moins) : seules celles-là escaladent un rouge à Willy
# Source : plans 46.1-14 et 46.1-17 ; aucune autre valeur de durée n'existe dans l'outil.
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
  detache-suite-base-longue detache-toutes-base-longue
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
  armement-observe armement-arme-coherent armement-arme-releve-non-armable armement-arme-gate-absent
  armement-g4-etape-6-armable armement-g4-etape-6-non-armable armement-g4-etape-6-code-diverge
  armement-g4p-etape-6-armable armement-g4p-etape-6-non-armable armement-g4p-simule-etape-6
  armement-etape-invalide armement-gate-invalide armement-arme-non-joue armement-arme-code-diverge
  armement-arme-code-diverge-arbre armement-arme-commande-diverge armement-arme-commit-inconnu
  armement-arme-commit-non-ancetre armement-arme-sans-commit-rejoue armement-constante-illisible
  armement-simule-armable armement-simule-non-armable
  garder-g4-vert garder-g4-armable garder-g4-sans-option garder-g4-code-diverge garder-g4-doublon
  garder-g4-observation garder-g4-canal-vide garder-g4-date-forme garder-g4-date-invalide garder-g4-forme
  garder-g4-constante-illisible garder-g4-releve-absent garder-g4-observe garder-g4-g4p garder-g4-simule
  etat-ref-coherent etat-ref-k1-fausse etat-ref-k2-fausse etat-ref-k3-fausse etat-ref-k3-etape-fausse
  etat-ref-k3-ligne-manquante etat-ref-k4-fausse etat-ref-constante-changee etat-ref-limite-levee
  etat-ref-limite-sans-ligne etat-ref-conditionnelle-ignoree etat-ref-hypothese-exclue
  etat-ref-gate-non-couvert etat-ref-non-reconnue-visible etat-ref-vide etat-ref-constante-illisible
  etat-ref-limites-illisibles etat-ref-fichier-absent etat-ref-hook-sans-constantes
  reel-etat-temoin reel-etat-constante-changee reel-etat-phrase-changee
  imputer-preexistant imputer-bilan-structurel imputer-imputable imputer-imputable-nouveau-ko imputer-instable
  imputer-parent-sans-depot imputer-parent-depot-preexistant imputer-suite-sensible-depot imputer-suite-neuve
  imputer-escalade-porteuse imputer-escalade-hors-liste imputer-sans-effet imputer-commit-inconnu
  imputer-commit-sans-parent imputer-detache-borne imputer-detache-base-longue
  jalon-ok jalon-absent jalon-sans-ligne jalon-double jalon-forme jalon-imputables jalon-commit-non-ancetre
  jalon-comptes-incoherents jalon-decouverte-partielle jalon-perime jalon-numero-invalide
  empreinte-ok empreinte-absente empreinte-modifie empreinte-commit-apres-gel empreinte-gel-rouvert
  empreinte-non-commite empreinte-geler-refuse empreinte-geler-outil-non-commite
  empreinte-regel-declare empreinte-regel-sans-trailer empreinte-regel-trailer-mal-forme
  empreinte-regel-touche-autre empreinte-commit-apres-regel
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
  local b_kind="" b_rc="" b_s="" b_zero="" rcv plafond ajout_s="" premier=1 base_ok=0 detache="" a borne racine_export="" herite=""
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
      --racine-export=*) racine_export=${1#--racine-export=} ;;
      --detache-herite=*) herite=${1#--detache-herite=} ;;
      -*) die_usage "suite : option inconnue : $1" ;;
      *) [ -z "$suite" ] || die_usage "suite : une seule suite par appel"; suite=$1 ;;
    esac
    shift
  done
  [ -n "$suite" ] || die_usage "suite <chemin> [options]"
  if [ -n "$racine_export" ]; then
    # Option INTERNE d'`imputer` : la suite est rejouée sous l'export d'un commit parent (ni .git, ni base : aucun
    # plafond de durée, aucune écriture de la base, aucun rejeu détaché).
    if [ "$dm_set" -eq 1 ] || [ "$aj_set" -eq 1 ] || [ -n "$detache" ]; then
      die_usage "suite : --racine-export exclut --duree-max, --base-ajout et --detache"
    fi
  fi
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
  if [ -n "$racine_export" ]; then
    RACINE=$(cd "$racine_export" 2> /dev/null && pwd -P) || { echo "SUITE-USAGE racine-export introuvable : $racine_export" >&2; exit 64; }
    cd "$RACINE" || exit 64
  else
    racine_ou_sortir
  fi
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
  # Une copie détachée (DETACHE_INTERNE) ou un rejeu qu'elle a lui-même lancé (--detache-herite=<dossier>, option
  # INTERNE d'`imputer` : le dossier d'un rejeu détaché en cours) a déjà été décidé détaché par l'appel externe :
  # le refus detache-requis ne s'y ré-applique pas (46.1 fix-outil-01).
  if [ -n "$herite" ] && [ ! -f "$herite/commande.txt" ]; then
    die_usage "suite : --detache-herite=<dossier d'un rejeu détaché>"
  fi
  if [ -z "$DETACHE_INTERNE" ] && [ -z "$herite" ] && [ -n "$b_kind" ] && [ "$b_rc" -eq 0 ] && [ "$b_zero" -eq 0 ] && [ "$b_s" -ge "$SEUIL_DETACHE" ]; then
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
RC_FRAIS=""
RC_VERIF_RC=""
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
  RC_FRAIS=""
  RC_VERIF_RC=""
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
    RC_VERIF_RC=$?
    derniere_ligne "$t/frais.txt" > "$t/frais-verdict.txt"
    fraiche=$(cat "$t/frais-verdict.txt")
    RC_FRAIS=$fraiche
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
    if [ "$base_ok" -eq 1 ] && [ -z "$detache" ] && [ -z "$DETACHE_INTERNE" ]; then
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
# Mode armement (P461-D-07 ; ARMG-05, ARMG-09)
# ---------------------------------------------------------------------------------------------------------
HOOKS_JSON_REL=plugin/planning-core/hooks/hooks.json
SURFACE_MESUREE="$HOOK_REL $HOOKS_JSON_REL"

# UNE fonction de lecture des constantes d'armement, partagée par `armement` et `etat-reference` (aucune copie).
# lire_constante <fichier> <X> : lit les lignes `^ARMEMENT_<X> = "(armed|observe)"  # etape-<n>$`. Pose CONST_VAL et
# CONST_ETAPE et retourne 0 si EXACTEMENT une ligne de cette forme existe et qu'aucune autre ligne n'affecte
# ARMEMENT_<X> ; retourne 1 sinon (zéro, plusieurs, valeur autre, étiquette d'étape illisible).
CONST_VAL=""
CONST_ETAPE=""
lire_constante() {
  local r
  CONST_VAL=""
  CONST_ETAPE=""
  r=$(X="$2" LC_ALL=C awk '
    BEGIN { x = ENVIRON["X"]; pref = "ARMEMENT_" x " = "; motif = "^ARMEMENT_" x " = \"(armed|observe)\"  # etape-[0-9a-z]+$" }
    index($0, pref) == 1 { tot++ }
    $0 ~ motif { ok++; v = $0; sub(/^[^"]*"/, "", v); sub(/".*$/, "", v); e = $0; sub(/^.*# etape-/, "", e); val = v; et = e }
    END { if (tot == 1 && ok == 1) print val " " et; else print "ILLISIBLE" }' "$1" 2> /dev/null)
  case $r in ILLISIBLE | "") return 1 ;; esac
  CONST_VAL=${r%% *}
  CONST_ETAPE=${r#* }
  return 0
}

# Surface mesurée : le texte où la VALEUR entre guillemets de chaque ligne ARMEMENT_* est remplacée par un jeton fixe
# (le nom de la constante et son étiquette d'étape restent comparés). Lit stdin.
normaliser_surface() {
  LC_ALL=C awk '/^ARMEMENT_[A-Z0-9]+ = "[a-z]+"  # etape-[0-9a-z]+$/ { sub(/"[a-z]+"/, "\"JETON\""); print; next } { print }'
}

# Écarts de surface entre le code rejoué (<sha>) et l'arbre de travail : pour chaque fichier de SURFACE_MESUREE dont
# le texte normalisé diffère, une ligne `ARMEMENT-ECART code-diverge <fichier> commits=<n>` (n = commits du fichier
# entre <sha> et HEAD ; `arbre-de-travail` si la différence n'est pas commitée). Retourne le nombre de fichiers.
surface_ecarts() { # <sha>
  local sha=$1 f t nb=0 a b n
  nouveau_tmp
  t=$NT
  for f in $SURFACE_MESUREE; do
    a=0
    b=0
    if git show "$sha:$f" > "$t/ref.raw" 2> /dev/null; then a=1; normaliser_surface < "$t/ref.raw" > "$t/ref.txt"; fi
    if [ -f "$f" ]; then b=1; normaliser_surface < "$f" > "$t/tra.txt"; fi
    if [ "$a" -eq 0 ] && [ "$b" -eq 0 ]; then continue; fi
    if [ "$a" -eq 1 ] && [ "$b" -eq 1 ] && cmp -s "$t/ref.txt" "$t/tra.txt"; then continue; fi
    nb=$((nb + 1))
    n=arbre-de-travail
    if git show "HEAD:$f" > "$t/head.raw" 2> /dev/null; then
      normaliser_surface < "$t/head.raw" > "$t/head.txt"
      if [ "$a" -eq 0 ] || ! cmp -s "$t/ref.txt" "$t/head.txt"; then
        n="commits=$(git rev-list --count "$sha..HEAD" -- "$f" 2> /dev/null)"
      fi
    elif [ "$a" -eq 1 ]; then
      n="commits=$(git rev-list --count "$sha..HEAD" -- "$f" 2> /dev/null)"
    fi
    printf 'ARMEMENT-ECART code-diverge %s %s\n' "$f" "$n"
  done
  return "$nb"
}

# 0 si la ligne `RELEVE-VERDICT armable etape=<étape> … gates=<liste>` nomme le gate.
verdict_arme_pour() { # <ligne> <étape> <gate>
  printf '%s\n' "$1" | E="$2" G="$3" LC_ALL=C awk '
    BEGIN { e = ENVIRON["E"]; g = ENVIRON["G"] }
    $1 == "RELEVE-VERDICT" && $2 == "armable" {
      for (i = 3; i <= NF; i++) {
        if ($i == "etape=" e) ok_e = 1
        if (substr($i, 1, 6) == "gates=") { n = split(substr($i, 7), l, ","); for (j = 1; j <= n; j++) if (l[j] == g) ok_g = 1 }
      }
    }
    END { if (ok_e && ok_g) exit 0; exit 1 }'
}

# Calendrier grégorien : 0 si AAAA-MM-JJ (forme déjà vérifiée) est une date qui existe.
date_valide() {
  local y m d dm
  y=${1%%-*}
  m=${1#*-}
  m=${m%%-*}
  d=${1##*-}
  y=$((10#$y))
  m=$((10#$m))
  d=$((10#$d))
  { [ "$m" -ge 1 ] && [ "$m" -le 12 ]; } || return 1
  case $m in
    1 | 3 | 5 | 7 | 8 | 10 | 12) dm=31 ;;
    4 | 6 | 9 | 11) dm=30 ;;
    *) if [ $((y % 4)) -eq 0 ] && { [ $((y % 100)) -ne 0 ] || [ $((y % 400)) -eq 0 ]; }; then dm=29; else dm=28; fi ;;
  esac
  { [ "$d" -ge 1 ] && [ "$d" -le "$dm" ]; }
}

# Décision de P461-D-17 (--garder-g4) : la ligne `DECISION-G4 garder-g4 canal=<non vide> date=AAAA-MM-JJ` du relevé.
# FORME et PRÉSENCE seulement, jamais la véracité de la décision (même régime que `Gate-Touche:`). Imprime une ligne
# `ARMEMENT-ECART decision-g4-<motif>` par raison (absente · doublon · observation · forme · canal-vide ·
# date-forme · date-invalide · releve-absent · constante-illisible · constante-non-armee) ; pose DG_CANAL et DG_DATE.
# Retourne 0 si la décision est valable.
DG_CANAL=""
DG_DATE=""
decision_g4() { # <relevé>
  local f=$1 nb ligne reste canal date ec=0
  DG_CANAL=""
  DG_DATE=""
  if [ ! -f "$f" ]; then
    echo "ARMEMENT-ECART decision-g4-releve-absent"
    return 1
  fi
  if ! lire_constante "$HOOK_REL" G4; then
    echo "ARMEMENT-ECART decision-g4-constante-illisible"
    return 1
  fi
  if [ "$CONST_VAL" != armed ] || [ "$CONST_ETAPE" != 5 ]; then
    echo "ARMEMENT-ECART decision-g4-constante-non-armee"
    return 1
  fi
  nb=$(compter_prefixe "$f" "DECISION-G4")
  if [ "$nb" -eq 0 ]; then
    echo "ARMEMENT-ECART decision-g4-absente"
    return 1
  fi
  if [ "$nb" -gt 1 ]; then
    echo "ARMEMENT-ECART decision-g4-doublon"
    return 1
  fi
  ligne=$(LC_ALL=C awk 'index($0, "DECISION-G4") == 1 { print; exit }' "$f")
  case $ligne in
    "DECISION-G4 g4-observation"*)
      echo "ARMEMENT-ECART decision-g4-observation"
      return 1 ;;
    "DECISION-G4 garder-g4 canal="*) ;;
    *)
      echo "ARMEMENT-ECART decision-g4-forme"
      return 1 ;;
  esac
  reste=${ligne#"DECISION-G4 garder-g4 canal="}
  case $reste in
    *" date="*) ;;
    *)
      echo "ARMEMENT-ECART decision-g4-forme"
      return 1 ;;
  esac
  canal=${reste%" date="*}
  date=${reste##*" date="}
  if [ -z "$(printf '%s' "$canal" | tr -d '[:space:]')" ]; then
    echo "ARMEMENT-ECART decision-g4-canal-vide"
    ec=$((ec + 1))
  fi
  case $date in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      if ! date_valide "$date"; then
        echo "ARMEMENT-ECART decision-g4-date-invalide"
        ec=$((ec + 1))
      fi ;;
    *)
      echo "ARMEMENT-ECART decision-g4-date-forme"
      ec=$((ec + 1)) ;;
  esac
  [ "$ec" -eq 0 ] || return 1
  DG_CANAL=$canal
  DG_DATE=$date
  return 0
}

# Cœur d'`armement` : retourne 0 conforme, 1 écart, 64 usage. Lit l'unique constante du gate dans l'arbre de travail.
armement_coeur() { # <gate> <relevé> <étape> <vérificateur> <simuler 0|1>
  local gate=$1 f=$2 etape=$3 verif=$4 simuler=$5 etat nb sha ligne rcc t
  if ! lire_constante "$HOOK_REL" "$gate"; then
    echo "ARMEMENT-ECART constante-illisible"
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  fi
  etat=$CONST_VAL
  if [ "$etat" = observe ] && [ "$simuler" -eq 0 ]; then
    printf 'ARMEMENT %s observe : rien à justifier\n' "$gate"
    return 0
  fi
  if [ "$simuler" -eq 1 ]; then
    printf 'ARMEMENT %s simule\n' "$gate"
  else
    printf 'ARMEMENT %s armed\n' "$gate"
  fi
  # (a) cohérence du relevé (la fonction de `releve`, aucune copie)
  releve_coherence "$f" "$etape" "$verif"
  rcc=$?
  if [ "$rcc" -eq 64 ]; then
    return 64
  elif [ "$rcc" -ne 0 ]; then
    echo "ARMEMENT-ECART releve-incoherent"
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  fi
  # (b) rejeu joué
  if [ "$(compter_prefixe "$f" "REJEU-NON-JOUE ")" -gt 0 ]; then
    echo "ARMEMENT-ECART releve-non-joue"
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  fi
  # (c) verdict FRAIS du vérificateur : code 0 et gate nommé dans la liste `gates=` du verdict armable
  if [ "${RC_VERIF_RC:-1}" != 0 ] || ! verdict_arme_pour "$RC_FRAIS" "$etape" "$gate"; then
    echo "ARMEMENT-ECART releve-non-armable"
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  fi
  # (d) COMMIT-REJOUE : exactement une ligne, commit connu, ancêtre de HEAD
  nb=$(compter_prefixe "$f" "COMMIT-REJOUE ")
  if [ "$nb" -eq 0 ]; then
    echo "ARMEMENT-ECART commit-rejoue-absent"
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  elif [ "$nb" -gt 1 ]; then
    echo "ARMEMENT-ECART commit-rejoue-doublon"
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  fi
  ligne=$(LC_ALL=C awk 'index($0, "COMMIT-REJOUE ") == 1 { print substr($0, 15); exit }' "$f")
  sha=$ligne
  case $sha in
    *[!0-9a-f]* | "") sha="" ;;
  esac
  if [ -z "$sha" ] || [ "${#sha}" -lt 7 ] || [ "${#sha}" -gt 40 ] || ! git cat-file -e "${sha}^{commit}" > /dev/null 2>&1; then
    echo "ARMEMENT-ECART commit-inconnu"
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  fi
  if ! git merge-base --is-ancestor "$sha" HEAD > /dev/null 2>&1; then
    echo "ARMEMENT-ECART commit-non-ancetre"
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  fi
  # (e) même code mesuré : identité d'octets de la surface mesurée, valeurs ARMEMENT_* exceptées
  t=$(mktemp "${TMPDIR:-/tmp}/c461.XXXXXX") || return 64
  TMPS+=("$t")
  surface_ecarts "$sha" > "$t"
  rcc=$?
  cat "$t"
  if [ "$rcc" -ne 0 ]; then
    echo "ARMEMENT-COHERENCE ECART"
    return 1
  fi
  echo "ARMEMENT-COHERENCE ok"
  return 0
}

cmd_armement() {
  local gate="" releve="" etape="" verif="" simuler=0 garder=0 core
  RLABS=()
  while [ $# -gt 0 ]; do
    case $1 in
      --gate=*) gate=${1#--gate=} ;;
      --releve=*) releve=${1#--releve=} ;;
      --etape=*) etape=${1#--etape=} ;;
      --lab=*) RLABS+=("${1#--lab=}") ;;
      --verificateur=*) verif=${1#--verificateur=} ;;
      --simuler-arme) simuler=1 ;;
      --garder-g4) garder=1 ;;
      *) die_usage "armement --gate=<G4|G4P> --releve=<relevé> --etape=<5|6> [--lab=<lab affiché>]… [--verificateur=<script>] [--simuler-arme] [--garder-g4]" ;;
    esac
    shift
  done
  case $gate in G4 | G4P) ;; *) die_usage "armement : --gate=G4 ou --gate=G4P" ;; esac
  [ -n "$releve" ] || die_usage "armement : --releve=<relevé>"
  case $etape in 5 | 6) ;; *) die_usage "armement : --etape=5 ou --etape=6 (étape du RELEVÉ présenté)" ;; esac
  if [ "$garder" -eq 1 ]; then
    [ "$gate" = G4 ] || die_usage "armement : --garder-g4 n'existe que pour --gate=G4"
    [ "$simuler" -eq 0 ] || die_usage "armement : --garder-g4 et --simuler-arme s'excluent"
  fi
  racine_ou_sortir
  [ -n "$verif" ] || verif=$VERIFICATEUR_DEFAUT
  armement_coeur "$gate" "$releve" "$etape" "$verif" "$simuler"
  core=$?
  [ "$core" -ne 64 ] || exit 64
  if [ "$core" -eq 1 ] && [ "$garder" -eq 1 ]; then
    # `armement` seul rend 1 : la décision garder-g4 (P461-D-17) n'excuse que G4 armé `# etape-5`, jamais autre chose.
    if decision_g4 "$releve"; then
      printf 'ARMEMENT G4 armed : non remesuré, décision garder-g4 canal=%s date=%s\n' "$DG_CANAL" "$DG_DATE"
      return 0
    fi
  fi
  return "$core"
}

# ---------------------------------------------------------------------------------------------------------
# Mode etat-reference (P461-D-07 ; ARMG-10)
# ---------------------------------------------------------------------------------------------------------
REFERENCE_DEFAUT=plugin/planning-core/references/modele-cycles.md
TESTS_GATES_DEFAUT=plugin/planning-core/scripts/tests/test-planning-gates.sh
GATES_CONSTANTES="G6 G5 G1 G7 ROLE G3 G4 G4P"

# Python embarqué (python3 -I -S) : GRAMMAIRE FERMÉE de la phrase d'état d'armement, quatre formes, relevée sur la
# référence réelle. Entrées : <référence> <fichier de tests> <constantes.tsv>. Constantes : `X<TAB>valeur<TAB>étape`
# ou `X<TAB>ILLISIBLE` (lues par lire_constante, la fonction d'`armement`), `G2_MODE<TAB>valeur`.
#   K1  clause de constante : une ou plusieurs `ARMEMENT_<X>` séparées par `, ` ou ` et `, puis `vaut` ou `valent` et
#       `armed` ou `observe` (entre accents graves) — chaque constante nommée vaut cette valeur ;
#   K2  résumé entre parenthèses (parenthèses équilibrées, `(bp)` compris) qui COMMENCE par une liste de gates et
#       enchaîne des clauses séparées par ` ; `, chacune `<gates> armé|armés` ou `<gates> en observation`, la dernière
#       terminée éventuellement par `, limite (xx)` ou `, limites (xx) et (yy)` — chaque gate cité a l'état dit, chaque
#       lettre citée figure dans LIMITES_REFERENCE ET porte sa ligne canonique `- **limite (xx)**` dans la référence ;
#   K3  ligne de la table d'armement `| <gate> | <étape> | <état> | …` — un état par constante (G2 : G2_MODE), égal à
#       la constante, étape égale à `# etape-<n>` ; une constante sans ligne, ou une ligne sans constante, est un écart ;
#   K4  affirmation ancrée — liste de gates (éventuellement suivie d'un groupe `(étape …)` et d'une virgule) puis `est`,
#       `reste` ou `reste donc` et un état ; OU liste de gates immédiatement suivie de l'état (`G4′ en observation`) ;
#       OU `<gate> (étape <id>, <état>…)`. État : `armé|armée|armés|armées`, `en observation`, ``en `observe` ``.
# Exclusions déclarées : une occurrence précédée, dans sa proposition (jusqu'au `;`, au `. ` ou au début de ligne), de
# `si `, `tant que `, `quand `, `dès que `, `une fois `, `exige ` ou `avant `, ou suivie de ` sans `, énonce une
# condition, une exigence ou une hypothèse et non un état : `ETAT-IGNORE`. Résidu visible : toute proposition qui
# contient un nom de gate ET `armé`, `en observation`, `observe` ou `armed` et qu'aucune forme ne reconnaît :
# `ETAT-NON-RECONNUE` (information, non rouge). Les lignes de tableau et les blocs de code clôturés sont hors prose.
ecrire_py_etat() { # <fichier>
  cat > "$1" <<'PY_ETAT_EOF'
import ast
import re
import sys

PRIME = "′"
ref_chemin, tests_chemin, const_chemin = sys.argv[1:4]

NOM = r"(?<![\w_])(?:G4" + PRIME + r"|G4'|G4P|G1|G3|G4|G5|G6|G7|ROLE|rôle)(?![\w_-])"
NOM_NU = NOM[len(r"(?<![\w_])"):]
LISTE = r"(?:" + NOM_NU + r")(?:(?:, | et | ET )" + NOM_NU + r")*"
ETAT = r"(?:armée?s?|en observation|en `observe`)(?!\w)"
RE_NOM = re.compile(NOM)
RE_LISTE = re.compile(r"(?<![\w_])" + LISTE)
RE_K1 = re.compile(r"((?:`ARMEMENT_[A-Z0-9]+`)(?:(?:, | et )`ARMEMENT_[A-Z0-9]+`)*) (vaut|valent) `(armed|observe)`")
RE_K4A = re.compile(r"(?<![\w_])(" + LISTE + r")(\s*\((?:étape|etape)[^()]*\))?(\s*,)?\s+(?:reste donc|reste|est)\s+(" + ETAT + r")")
RE_K4B = re.compile(r"(?<![\w_])(" + LISTE + r")\s+(" + ETAT + r")")
RE_K4C = re.compile(r"(?<![\w_])(" + NOM_NU + r")\s*\((?:étape|etape)\s[^(),]*,\s*(" + ETAT + r")[^()]*\)")
RE_EXCL = re.compile(r"(?<!\w)(si|tant que|quand|dès que|une fois|exige|avant) ")
RE_RESIDU = re.compile(r"armée?s?(?!\w)|en observation|observe|armed")
RE_K3 = re.compile(r"^\|\s*(" + NOM_NU + r"|G2)\s*\|\s*([0-9]+|-)\s*\|\s*(armed|observe|avertit)\s*\|")
RE_LIMITE_LIGNE = re.compile(r"^- \*\*limite \(([a-z]+)\)\*\*")
RE_LIMITES_SUFFIXE = re.compile(r"^,\s+limites?\s+\(([a-z]+)\)(?:\s+et\s+\(([a-z]+)\))*$")
RE_CLAUSE = re.compile(r"^(" + LISTE + r")\s+(armés?|en observation)(,\s+limites?\s+.*)?$")


def cle_gate(texte):
    t = texte.replace("'", PRIME)
    if t in ("G4" + PRIME, "G4P"):
        return "G4P"
    if t in ("ROLE", "rôle"):
        return "ROLE"
    return t


def gates_de(liste):
    return [cle_gate(m.group(0)) for m in RE_NOM.finditer(liste)]


def etat_de(mot):
    return "observe" if ("observation" in mot or "observe" in mot) else "armed"


sorties = []
ecarts = 0
cmp_k = {"k1": 0, "k2": 0, "k3": 0, "k4": 0}
ignorees = 0
non_reconnues = 0
couverts = set()


def ecart(texte):
    global ecarts
    ecarts += 1
    sorties.append("ETAT-ECART " + texte)


# --- constantes
const = {}
g2 = None
for ligne in open(const_chemin, encoding="utf-8").read().split("\n"):
    if not ligne:
        continue
    champs = ligne.split("\t")
    if champs[0] == "G2_MODE":
        if len(champs) > 1 and champs[1] != "ILLISIBLE":
            g2 = champs[1]
        else:
            ecart("constante-illisible G2_MODE")
    elif len(champs) > 2:
        const[champs[0]] = (champs[1], champs[2])
    else:
        ecart("constante-illisible " + champs[0])
        const[champs[0]] = None

# --- limites
limites = None
try:
    brut = open(tests_chemin, encoding="utf-8").read().split("\n")
    debut = None
    for i, l in enumerate(brut):
        if l.startswith("LIMITES_REFERENCE = ("):
            debut = i
            break
    if debut is not None:
        fin = None
        for j in range(debut + 1, len(brut)):
            if brut[j] == ")":
                fin = j
                break
        if fin is not None:
            texte = "\n".join(brut[debut:fin + 1])
            valeur = ast.literal_eval(texte[texte.index("=") + 1:].strip())
            limites = [e[0] for e in valeur]
except (OSError, ValueError, SyntaxError, IndexError, TypeError):
    limites = None
if limites is None:
    ecart("limites-illisibles")

# --- référence
lignes = open(ref_chemin, encoding="utf-8").read().split("\n")
canoniques = set()
for l in lignes:
    m = RE_LIMITE_LIGNE.match(l)
    if m:
        canoniques.add(m.group(1))

rows = {}


def debut_proposition(texte, p):
    d = 0
    for m in re.finditer(r";|\.(?=\s|$)", texte[:p]):
        d = m.end()
    return d


def exclusion(texte, debut, fin):
    pd = debut_proposition(texte, debut)
    m = RE_EXCL.search(texte[pd:debut])
    if m:
        return m.group(1)
    if texte[fin:fin + 6] == " sans ":
        return "sans"
    return None


def comparer(forme, n, gate, dit):
    if gate not in const:
        ecart("%s ligne=%d %s dit=%s constante=absente" % (forme, n, gate, dit))
        return False
    if const[gate] is None:
        return True
    if const[gate][0] != dit:
        ecart("%s ligne=%d %s dit=%s constante=%s" % (forme, n, gate, dit, const[gate][0]))
        return False
    return True


def groupes_parentheses(texte):
    pile = []
    out = []
    for i, ch in enumerate(texte):
        if ch == "(":
            pile.append(i)
        elif ch == ")" and pile:
            out.append((pile.pop(), i))
    return sorted(out)


def clauses_k2(contenu):
    morceaux = []
    prof = 0
    cur = ""
    i = 0
    while i < len(contenu):
        ch = contenu[i]
        if ch == "(":
            prof += 1
        elif ch == ")":
            prof -= 1
        if prof == 0 and contenu[i:i + 3] == " ; ":
            morceaux.append(cur)
            cur = ""
            i += 3
            continue
        cur += ch
        i += 1
    morceaux.append(cur)
    return morceaux


en_code = False
for idx, l in enumerate(lignes):
    n = idx + 1
    if l.lstrip().startswith("```"):
        en_code = not en_code
        continue
    if en_code:
        continue
    m3 = RE_K3.match(l)
    if m3:
        nom, etape, etat = m3.group(1), m3.group(2), m3.group(3)
        g = "G2" if nom == "G2" else cle_gate(nom)
        cmp_k["k3"] += 1
        if g in rows:
            ecart("k3-ligne-doublon ligne=%d %s" % (n, g))
        rows[g] = n
        if g == "G2":
            if g2 is None:
                continue
            if etat != g2:
                ecart("k3 ligne=%d G2 dit=%s constante=%s" % (n, etat, g2))
            if etape != "-":
                ecart("k3-etape ligne=%d G2 dit=%s constante=-" % (n, etape))
        else:
            if g not in const:
                ecart("k3-ligne-sans-constante ligne=%d %s" % (n, g))
            elif const[g] is not None:
                if etat != const[g][0]:
                    ecart("k3 ligne=%d %s dit=%s constante=%s" % (n, g, etat, const[g][0]))
                if etape != const[g][1]:
                    ecart("k3-etape ligne=%d %s dit=%s constante=%s" % (n, g, etape, const[g][1]))
        continue
    if l.startswith("|"):
        continue
    masque = list(l)
    reconnus = []  # (début, fin) des occurrences reconnues, comptées ou ignorées

    def masquer(a, b):
        for i in range(a, b):
            masque[i] = " "

    # K1
    for m in RE_K1.finditer(l):
        reconnus.append((m.start(), m.end()))
        masquer(m.start(), m.end())
        exc = exclusion(l, m.start(), m.end())
        xs = re.findall(r"`ARMEMENT_([A-Z0-9]+)`", m.group(1))
        if exc:
            ignorees += 1
            sorties.append("ETAT-IGNORE ligne=%d motif=%s %s" % (n, exc, " ".join("ARMEMENT_" + x for x in xs)))
            continue
        cmp_k["k1"] += 1
        dit = m.group(3)
        bons = [comparer("k1", n, x, dit) for x in xs]
        for x in xs:
            couverts.add(x)
        if all(bons):
            sorties.append("ETAT k1 ligne=%d gates=%s dit=%s ok" % (n, ",".join(xs), dit))
    # K2
    for (a, b) in groupes_parentheses(l):
        contenu = l[a + 1:b]
        if not RE_LISTE.match(contenu):
            continue
        if any(masque[i] == " " and l[i] != " " for i in range(a, b + 1)):
            continue
        parts = clauses_k2(contenu)
        analyse = []
        valide = True
        lettres = []
        for k, cl in enumerate(parts):
            mc = RE_CLAUSE.match(cl.strip())
            if not mc:
                valide = False
                break
            suffixe = mc.group(3)
            if suffixe:
                if k != len(parts) - 1 or not RE_LIMITES_SUFFIXE.match(suffixe):
                    valide = False
                    break
                lettres = re.findall(r"\(([a-z]+)\)", suffixe)
            analyse.append((gates_de(mc.group(1)), etat_de(mc.group(2))))
        if not valide:
            continue
        reconnus.append((a, b + 1))
        masquer(a, b + 1)
        exc = exclusion(l, a, b + 1)
        if exc:
            ignorees += 1
            sorties.append("ETAT-IGNORE ligne=%d motif=%s %s" % (n, exc, contenu[:60]))
            continue
        cmp_k["k2"] += 1
        tous = []
        dits = []
        bons = []
        for gates, dit in analyse:
            for g in gates:
                tous.append(g)
                dits.append(dit)
                couverts.add(g)
                bons.append(comparer("k2", n, g, dit))
        for lettre in lettres:
            if limites is not None and lettre not in limites:
                ecart("limite-absente %s" % lettre)
                bons.append(False)
            elif lettre not in canoniques:
                ecart("limite-sans-ligne %s" % lettre)
                bons.append(False)
        if all(bons):
            sorties.append("ETAT k2 ligne=%d gates=%s dit=%s ok" % (n, ",".join(tous), ",".join(dits)))
    # K4 sur la ligne masquée (K1 et K2 déjà traités)
    texte = "".join(masque)
    trouves = []
    for rx, genre in ((RE_K4A, "A"), (RE_K4B, "B"), (RE_K4C, "C")):
        for m in rx.finditer(texte):
            if genre == "C":
                liste, mot = m.group(1), m.group(2)
            elif genre == "A":
                liste, mot = m.group(1), m.group(4)
            else:
                liste, mot = m.group(1), m.group(2)
            trouves.append((m.start(), -(m.end() - m.start()), m.end(), liste, mot))
    trouves.sort()
    pris = []
    for (a, _neg, b, liste, mot) in trouves:
        if any(not (b <= pa or a >= pb) for (pa, pb) in pris):
            continue
        pris.append((a, b))
        reconnus.append((a, b))
        exc = exclusion(texte, a, b)
        gates = gates_de(liste)
        if exc:
            ignorees += 1
            sorties.append("ETAT-IGNORE ligne=%d motif=%s %s" % (n, exc, texte[a:b].strip()))
            continue
        cmp_k["k4"] += 1
        dit = etat_de(mot)
        bons = [comparer("k4", n, g, dit) for g in gates]
        for g in gates:
            couverts.add(g)
        if all(bons):
            sorties.append("ETAT k4 ligne=%d gates=%s dit=%s ok" % (n, ",".join(gates), dit))
    # Résidu : propositions de la ligne masquée qui nomment un gate et un état sans être reconnues
    debut = 0
    bornes = [m.end() for m in re.finditer(r";|\.(?=\s|$)", texte)] + [len(texte)]
    for fin in bornes:
        prop = texte[debut:fin]
        if RE_NOM.search(prop) and RE_RESIDU.search(prop):
            if not any(debut <= a < fin for (a, _b) in reconnus):
                non_reconnues += 1
                sorties.append("ETAT-NON-RECONNUE ligne=%d %s" % (n, " ".join(prop.split())[:140]))
        debut = fin

# --- couverture de la table (K3)
if "G2" not in rows and g2 is not None:
    ecart("k3-ligne-manquante G2")
for g in "G6 G5 G1 G7 ROLE G3 G4 G4P".split():
    if g in const and const[g] is not None and g not in rows:
        ecart("k3-ligne-manquante %s" % g)
# --- couverture par gate (K1, K2, K4) : une constante nommée par AUCUNE phrase est un écart
if cmp_k["k1"] + cmp_k["k2"] + cmp_k["k4"] == 0:
    ecart("aucune-phrase")
else:
    for g in "G6 G5 G1 G7 ROLE G3 G4 G4P".split():
        if g in const and const[g] is not None and g not in couverts:
            ecart("gate-non-couvert %s" % g)

for s in sorties:
    print(s)
print("ETAT-BILAN k1=%d k2=%d k3=%d k4=%d ignorees=%d non-reconnues=%d ecarts=%d" % (
    cmp_k["k1"], cmp_k["k2"], cmp_k["k3"], cmp_k["k4"], ignorees, non_reconnues, ecarts))
sys.exit(1 if ecarts else 0)
PY_ETAT_EOF
}

cmd_etat_reference() {
  local ref="" hook="" tests="" t x r
  while [ $# -gt 0 ]; do
    case $1 in
      --reference=*) ref=${1#--reference=} ;;
      --hook=*) hook=${1#--hook=} ;;
      --tests=*) tests=${1#--tests=} ;;
      *) die_usage "etat-reference [--reference=<fichier>] [--hook=<fichier>] [--tests=<fichier>]" ;;
    esac
    shift
  done
  racine_ou_sortir
  [ -n "$ref" ] || ref=$REFERENCE_DEFAUT
  [ -n "$hook" ] || hook=$HOOK_REL
  [ -n "$tests" ] || tests=$TESTS_GATES_DEFAUT
  for x in "$ref" "$hook" "$tests"; do
    [ -f "$x" ] || { echo "ETAT-USAGE fichier introuvable : $x" >&2; exit 64; }
  done
  nouveau_tmp
  t=$NT
  : > "$t/constantes.tsv"
  for x in $GATES_CONSTANTES; do
    if lire_constante "$hook" "$x"; then
      printf '%s\t%s\t%s\n' "$x" "$CONST_VAL" "$CONST_ETAPE" >> "$t/constantes.tsv"
    else
      printf '%s\tILLISIBLE\n' "$x" >> "$t/constantes.tsv"
    fi
  done
  r=$(LC_ALL=C awk '/^G2_MODE = "[a-z]+"$/ { n++; v = $0; sub(/^[^"]*"/, "", v); sub(/".*$/, "", v); val = v } END { if (n == 1) print val; else print "ILLISIBLE" }' "$hook")
  printf 'G2_MODE\t%s\n' "$r" >> "$t/constantes.tsv"
  ecrire_py_etat "$t/etat.py"
  python3 -I -S "$t/etat.py" "$ref" "$tests" "$t/constantes.tsv"
}

# ---------------------------------------------------------------------------------------------------------
# Mode imputer (P461-D-16)
# ---------------------------------------------------------------------------------------------------------
# SUITES_PORTEUSES : les douze suites qui gardent un gate armé ou à armer (liste du contrat commun de 46.1-14, relevée
# de 46.1-PATTERNS « File Classification » ; ni plus ni moins). Seul un rouge sur l'une d'elles est escaladé à Willy
# (`escalade-willy=oui`) ; toute suite hors liste (dont test-recalc-planning.sh et les suites à bilan ancien) donne `non`.
SUITES_PORTEUSES="plugin/planning-core/scripts/tests/test-planning-gates.sh plugin/planning-core/scripts/tests/test-cloture-gates.sh plugin/planning-core/scripts/tests/test-cloture-empreintes.sh plugin/planning-core/scripts/tests/test-g4p-sortie-brute.sh plugin/planning-core/scripts/tests/test-rejeu-gates.sh plugin/planning-core/scripts/tests/test-juges-canary.sh plugin/planning-core/scripts/tests/test-planning-hook-registered.sh plugin/planning-core/scripts/tests/test-planning-prefilter.sh plugin/planning-core/scripts/tests/test-d1-surveillance.sh plugin/planning-core/scripts/tests/test-verifier-releve.sh plugin/_internal/tests/test-planning-hook-installed.sh scripts/tests/test-role-hook-vs-check-agents.sh"
FACTEUR_IMPUTER=9
IM_OPTS=()
IR_RC=0
IR_REJEUX=0

# Clés de motifs d'une sortie de `suite` (une par ligne, triées, uniques) : `motif <motif>` pour chaque SUITE-ECART
# (bilan : sa nature sans le compte ; exige-absent et montre-absent : le libellé), `ligne <texte>` pour chaque ligne
# `  ✗ ` ou `NON TUÉ`. Les nombres (ko n=3, rc 1, durée) ne sont jamais comparés.
imputer_motifs() { # <sortie>
  LC_ALL=C awk '
    index($0, "SUITE-ECART ") == 1 {
      r = substr($0, 13); n = split(r, w, " "); m = w[1]
      if (m == "bilan") { d = w[2]; sub(/=.*/, "", d); m = "bilan " d }
      else if (m == "exige-absent" || m == "montre-absent") { m = m " " substr(r, length(w[1]) + 2) }
      print "motif " m; next
    }
    index($0, "  ✗ ") == 1 { print "ligne " $0; next }
    index($0, "NON TUÉ") > 0 { print "ligne " $0 }
  ' "$1" | LC_ALL=C sort -u
}

# Un rejeu : `suite` dans un processus neuf (HOME temporaire, environnement privé : le mode suite lui-même).
# <exp> vaut `-` pour l'arbre courant, ou le dossier d'un export (parent, sans .git ou avec un dépôt à un commit).
# Imprime IMPUTATION-REJEU ; pose IR_RC ; le code 64 d'un rejeu est un usage, jamais un verdict.
imputer_rejeu() { # <sur> <n> <sortie> <exp> <suite>
  local sur=$1 n=$2 sortie=$3 exp=$4 suite=$5 args a motifs nl
  args=()
  if [ "$exp" = - ]; then
    for a in ${IM_OPTS[@]+"${IM_OPTS[@]}"}; do args+=("$a"); done
  else
    for a in ${IM_OPTS[@]+"${IM_OPTS[@]}"}; do
      case $a in --duree-max=* | --base-cle=* | --base-fichier=*) ;; *) args+=("$a") ;; esac
    done
    args+=("--racine-export=$exp")
  fi
  # Sous un imputer détaché, le rejeu hérite de la décision de détacher (sinon detache-requis le refuse).
  [ -z "$DETACHE_INTERNE" ] || args+=("--detache-herite=$DETACHE_INTERNE")
  bash "$OUTIL" suite "$suite" ${args[@]+"${args[@]}"} "--outil-origine=$OUTIL_ORIGINE" > "$sortie" 2>&1 < /dev/null
  IR_RC=$?
  IR_REJEUX=$((IR_REJEUX + 1))
  motifs=$(imputer_motifs "$sortie" | LC_ALL=C awk 'index($0, "motif ") == 1 { sub(/^motif /, ""); gsub(/ /, "_"); printf "%s%s", (c++ ? "," : ""), $0 }')
  nl=$(LC_ALL=C awk 'index($0, "  ✗ ") == 1 { c++ } END { print c + 0 }' "$sortie")
  printf 'IMPUTATION-REJEU %s sur=%s n=%s rc=%s motifs=%s lignes-ko=%s\n' "$suite" "$sur" "$n" "$IR_RC" "${motifs:--}" "$nl"
}

cmd_imputer() {
  local suite="" sha="" detache="" a cle esc verdict cause="" t pdir p2dir cur rcp sensible k manque nouveau entree b_kind b_rc b_s b_zero borne rcv
  local args_detache=()
  IM_OPTS=()
  IR_REJEUX=0
  for a in "$@"; do
    case $a in --detache=*) ;; *) args_detache+=("$a") ;; esac
  done
  while [ $# -gt 0 ]; do
    case $1 in
      --commit=*) sha=${1#--commit=} ;;
      --detache=*) detache=${1#--detache=}; [ -n "$detache" ] || die_usage "imputer : --detache=<dossier>" ;;
      --base-fichier=*) option_base_fichier "${1#--base-fichier=}"; IM_OPTS+=("$1") ;;
      --exige=* | --shells=* | --montre=* | --duree-max=* | --base-cle=*) IM_OPTS+=("$1") ;;
      -*) die_usage "imputer : option inconnue : $1" ;;
      *) [ -z "$suite" ] || die_usage "imputer : une seule suite par appel"; suite=$1 ;;
    esac
    shift
  done
  [ -n "$suite" ] && [ -n "$sha" ] || die_usage "imputer <suite> --commit=<sha> [options de suite] [--detache=<dossier>]"
  racine_ou_sortir
  case $suite in "$RACINE"/*) suite=${suite#"$RACINE"/} ;; esac
  if ! git rev-parse --verify -q "${sha}^{commit}" > /dev/null 2>&1; then
    echo "IMPUTATION-USAGE commit-inconnu $sha" >&2
    exit 64
  fi
  if ! git rev-parse --verify -q "${sha}^" > /dev/null 2>&1; then
    echo "IMPUTATION-USAGE commit-sans-parent $sha (le PREMIER commit du plan doit avoir un parent)" >&2
    exit 64
  fi
  cle=$suite
  for a in ${IM_OPTS[@]+"${IM_OPTS[@]}"}; do
    case $a in --base-cle=*) cle=${a#--base-cle=} ;; esac
  done
  esc=non
  case " $SUITES_PORTEUSES " in *" $cle "*) esc=oui ;; esac

  if [ -n "$detache" ]; then
    # Rejeu détaché : borne = 9 × durée de base (trois rejeux au plus, chacun sous son plafond), jamais d'ailleurs.
    if [ -e "$BASE_FICHIER" ]; then
      base_valider
      rcv=$?
      [ "$rcv" -eq 0 ] || exit 64
      entree=$(base_chercher "$cle")
    else
      entree=""
    fi
    if [ -z "$entree" ]; then
      echo "IMPUTATION-USAGE base-absente $cle : aucun rejeu détaché sans durée de base (aucune borne inventée)" >&2
      exit 64
    fi
    read -r b_kind b_rc b_s b_zero <<EOF
$entree
EOF
    if [ "$b_kind" = AJOUT ]; then
      b_s=$b_rc
      b_rc=0
      b_zero=0
    fi
    if [ "$b_rc" -ne 0 ] || [ "$b_zero" -ne 0 ]; then
      echo "IMPUTATION-USAGE base-rouge $cle : suite rouge à la base, sa durée n'est pas une mesure" >&2
      exit 64
    fi
    borne=$((b_s * FACTEUR_IMPUTER))
    [ "$borne" -ge 1 ] || borne=1
    detacher "$detache" "$borne" - 1 imputer ${args_detache[@]+"${args_detache[@]}"}
    return $?
  fi

  nouveau_tmp
  t=$NT
  # C1 sur l'arbre courant ; C2 seulement si C1 est vert.
  imputer_rejeu courant 1 "$t/c1.txt" - "$suite"
  [ "$IR_RC" -ne 64 ] || { cat "$t/c1.txt" >&2; exit 64; }
  cur=$t/c1.txt
  if [ "$IR_RC" -eq 0 ]; then
    imputer_rejeu courant 2 "$t/c2.txt" - "$suite"
    [ "$IR_RC" -ne 64 ] || { cat "$t/c2.txt" >&2; exit 64; }
    cur=$t/c2.txt
  fi
  if [ "$IR_RC" -eq 0 ]; then
    verdict=instable
    cause=non-reproduit
  elif ! git cat-file -e "${sha}^:${suite}" > /dev/null 2>&1; then
    verdict=imputable
    echo "IMPUTATION-NOTE suite-neuve $suite : absente du commit parent"
  else
    # P : export `git archive` du parent, sans checkout, stash ni reset (HEAD, index, arbre de travail et pile des
    # stash sont inchangés) ; ÉCART NOMMÉ : l'export n'a ni .git, ni historique, ni fichiers ignorés, ni configuration
    # locale — il ne reproduit PAS le dépôt du rejeu courant.
    pdir=$t/parent
    mkdir -p "$pdir"
    git archive --format=tar "${sha}^" | tar -x -C "$pdir"
    imputer_rejeu parent 1 "$t/p.txt" "$pdir" "$suite"
    [ "$IR_RC" -ne 64 ] || { cat "$t/p.txt" >&2; exit 64; }
    if [ "$IR_RC" -eq 0 ]; then
      verdict=imputable
    else
      imputer_motifs "$cur" > "$t/cur.keys"
      imputer_motifs "$t/p.txt" > "$t/p.keys"
      manque=$(LC_ALL=C comm -23 "$t/cur.keys" "$t/p.keys")
      if [ -n "$manque" ]; then
        verdict=imputable
        while IFS= read -r nouveau; do
          printf 'IMPUTATION-NOUVEAU %s\n' "${nouveau#* }"
        done <<EOF
$manque
EOF
      else
        # P2 : le même export rendu dépôt par `git init` et UN commit de tout l'export (identité passée par -c,
        # configurations globale et système vers /dev/null). Il reproduit la PRÉSENCE d'un dépôt, pas son historique.
        p2dir=$t/parent-depot
        mkdir -p "$p2dir"
        git archive --format=tar "${sha}^" | tar -x -C "$p2dir"
        env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -c init.defaultBranch=main -c user.name=imputer -c user.email=imputer@localhost -c commit.gpgsign=false -c core.hooksPath=/dev/null -C "$p2dir" init -q > /dev/null 2>&1
        env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -c user.name=imputer -c user.email=imputer@localhost -c commit.gpgsign=false -c core.hooksPath=/dev/null -C "$p2dir" add -A > /dev/null 2>&1
        env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git -c user.name=imputer -c user.email=imputer@localhost -c commit.gpgsign=false -c core.hooksPath=/dev/null -C "$p2dir" commit -q -m export > /dev/null 2>&1
        imputer_rejeu parent-depot 1 "$t/p2.txt" "$p2dir" "$suite"
        [ "$IR_RC" -ne 64 ] || { cat "$t/p2.txt" >&2; exit 64; }
        if [ "$IR_RC" -eq 0 ]; then
          verdict=imputable
          echo "IMPUTATION-NOTE parent-vert-avec-depot : le parent ne rougissait que sans dépôt, son rouge n'est pas un fait préexistant"
        else
          # Suite « sensible au dépôt » : son source à <sha>^ contient le mot `git` (critère volontairement large).
          sensible=0
          if git show "${sha}^:${suite}" 2> /dev/null | grep -qw git; then sensible=1; fi
          if [ "$sensible" -eq 1 ]; then
            verdict=instable
            cause=suite-sensible-depot
          else
            verdict=preexistant
          fi
        fi
      fi
    fi
  fi
  if [ "$verdict" = instable ]; then
    printf 'IMPUTATION %s verdict=%s rejeux=%s escalade-willy=%s cause=%s\n' "$suite" "$verdict" "$IR_REJEUX" "$esc" "$cause"
  else
    printf 'IMPUTATION %s verdict=%s rejeux=%s escalade-willy=%s\n' "$suite" "$verdict" "$IR_REJEUX" "$esc"
  fi
  [ "$verdict" != imputable ] || return 1
  [ "$esc" = non ] || return 1
  return 0
}

# ---------------------------------------------------------------------------------------------------------
# Mode jalon (P461-D-16)
# ---------------------------------------------------------------------------------------------------------
# Lit un fait DÉCLARÉ par le manager (46.1-JALONS.txt) : forme, cohérence et ancienneté vérifiées, jamais la
# véracité (même régime que `Gate-Touche:`). Jamais un vert à vide : fichier ou ligne absents = 1.
cmd_jalon() {
  local n="" jf="" ec=0 nl champs commit suites vertes rouges zero s imp pre ins bsuites ligne rcv
  while [ $# -gt 0 ]; do
    case $1 in
      --jalons-fichier=*) jf=${1#--jalons-fichier=}; printf 'JALONS-FICHIER-ALTERNATIF %s\n' "$jf" ;;
      --base-fichier=*) option_base_fichier "${1#--base-fichier=}" ;;
      -*) die_usage "jalon : option inconnue : $1" ;;
      *) [ -z "$n" ] || die_usage "jalon <1|2|3>"; n=$1 ;;
    esac
    shift
  done
  case $n in 1 | 2 | 3) ;; *) die_usage "jalon <1|2|3>" ;; esac
  racine_ou_sortir
  [ -n "$jf" ] || jf="$(dirname "$OUTIL_ORIGINE")/46.1-JALONS.txt"
  jalon_ecart() {
    printf 'JALON-ECART %s\n' "$1"
    ec=$((ec + 1))
  }
  if [ ! -f "$jf" ]; then
    jalon_ecart jalon-absent
    return 1
  fi
  nl=$(N="$n" LC_ALL=C awk 'BEGIN { n = ENVIRON["N"] } $1 == "JALON" && $2 == n { c++ } END { print c + 0 }' "$jf")
  if [ "$nl" -eq 0 ]; then
    jalon_ecart jalon-absent
    return 1
  fi
  if [ "$nl" -gt 1 ]; then
    jalon_ecart jalon-double
    return 1
  fi
  ligne=$(N="$n" LC_ALL=C awk 'BEGIN { n = ENVIRON["N"] } $1 == "JALON" && $2 == n { print; exit }' "$jf")
  champs=$(printf '%s\n' "$ligne" | LC_ALL=C awk '
    NF == 13 && $3 ~ /^commit=[0-9a-f]+$/ && $4 ~ /^date=[^ ]+$/ && $5 == "TOUTES-BILAN" && $6 ~ /^suites=[0-9]+$/ \
      && $7 ~ /^vertes=[0-9]+$/ && $8 ~ /^rouges=[0-9]+$/ && $9 ~ /^zero-ok=[0-9]+$/ && $10 ~ /^s=[0-9]+$/ \
      && $11 ~ /^imputables=[0-9]+$/ && $12 ~ /^preexistants=[0-9]+$/ && $13 ~ /^instables=[0-9]+$/ {
      print substr($3, 8), substr($6, 8), substr($7, 8), substr($8, 8), substr($9, 9), substr($10, 3), substr($11, 12), substr($12, 14), substr($13, 11); exit 0 }')
  if [ -z "$champs" ]; then
    jalon_ecart jalon-forme
    return 1
  fi
  read -r commit suites vertes rouges zero s imp pre ins <<EOF
$champs
EOF
  if ! git merge-base --is-ancestor "$commit" HEAD > /dev/null 2>&1; then
    jalon_ecart jalon-commit-non-ancetre
  fi
  [ "$imp" -eq 0 ] || jalon_ecart jalon-imputables
  [ "$rouges" -eq $((pre + imp + ins)) ] || jalon_ecart jalon-comptes-incoherents
  if [ -e "$BASE_FICHIER" ]; then
    base_valider > /dev/null
    rcv=$?
    if [ "$rcv" -eq 0 ]; then
      bsuites=$(LC_ALL=C awk '$1 == "BASE-BILAN" { print substr($2, 8); exit }' "$BASE_FICHIER")
      [ "$suites" -ge "$bsuites" ] || jalon_ecart jalon-decouverte-partielle
    else
      jalon_ecart jalon-base-illisible
    fi
  else
    jalon_ecart jalon-base-illisible
  fi
  # Jalon périmé : le hook ou sa commande enregistrée ont changé (arbre de travail compris) depuis le commit du jalon.
  if git cat-file -e "${commit}^{commit}" > /dev/null 2>&1; then
    if [ -n "$(git diff --name-only "$commit" -- "$HOOK_REL" "$HOOKS_JSON_REL" 2> /dev/null)" ]; then
      jalon_ecart jalon-perime
    fi
  fi
  if [ "$ec" -eq 0 ]; then
    printf 'JALON-VERIF %s ok\n' "$n"
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------------------------------------
# Mode empreinte (P461-D-16)
# ---------------------------------------------------------------------------------------------------------
cmd_empreinte() {
  local geler=0 d outil sha h gel nc k ec=0 tmp c rel fichiers corps ligne ok_regel regels=0 premier_gel=1 regel_lignes="" re_regel
  re_regel='^Regel-Outil: ([0-9]{6}-[a-z0-9]{3}) — ([^[:space:]].*)$'
  while [ $# -gt 0 ]; do
    case $1 in
      --geler) geler=1 ;;
      *) die_usage "empreinte [--geler]" ;;
    esac
    shift
  done
  racine_ou_sortir
  d=$(cd "$(dirname "$OUTIL_ORIGINE")" && pwd -P) || exit 64
  outil=$d/46.1-CONTROLES.sh
  sha=$d/46.1-CONTROLES.sha256
  [ -f "$outil" ] || { echo "EMPREINTE-USAGE outil introuvable : $outil" >&2; exit 64; }
  nouveau_tmp
  tmp=$NT
  (cd "$d" && shasum -a 256 46.1-CONTROLES.sh) > "$tmp/calcul.txt"
  h=$(awk '{ print $1; exit }' "$tmp/calcul.txt")
  if [ "$geler" -eq 1 ]; then
    if [ -e "$sha" ]; then
      echo "EMPREINTE-USAGE geler-refuse : $sha existe, le gel posé n'est jamais re-posé" >&2
      exit 64
    fi
    if ! git ls-files --error-unmatch -- "$outil" > /dev/null 2>&1 || [ -n "$(git status --porcelain -- "$outil")" ]; then
      echo "EMPREINTE-USAGE geler-refuse : l'outil n'est pas commité et propre" >&2
      exit 64
    fi
    cp "$tmp/calcul.txt" "$sha"
    printf 'EMPREINTE-GELEE sha256=%s\n' "$h"
    return 0
  fi
  if [ ! -f "$sha" ]; then
    echo "EMPREINTE-ECART absente"
    return 1
  fi
  cmp -s "$tmp/calcul.txt" "$sha" || { echo "EMPREINTE-ECART modifie"; ec=$((ec + 1)); }
  if ! git ls-files --error-unmatch -- "$outil" > /dev/null 2>&1 || [ -n "$(git status --porcelain -- "$outil")" ] \
    || ! git ls-files --error-unmatch -- "$sha" > /dev/null 2>&1 || [ -n "$(git status --porcelain -- "$sha")" ]; then
    echo "EMPREINTE-ECART non-commite"
    ec=$((ec + 1))
  else
    # Historique du .sha256, du plus ancien au plus récent : le premier est le gel ; chaque suivant est un REGEL, valide
    # si et seulement s'il ne touche QUE le .sha256 et porte un trailer `Regel-Outil: <id quick> — <raison>` (forme
    # seulement). Un regel invalide : gel-rouvert. Voie déclarée, jamais un verrou (ADR-072).
    nc=0
    gel=""
    rel=$(git ls-files --full-name -- "$sha")
    while IFS= read -r c; do
      [ -n "$c" ] || continue
      nc=$((nc + 1))
      gel=$c
      if [ "$premier_gel" -eq 1 ]; then
        premier_gel=0
        continue
      fi
      fichiers=$(git show --name-only --format= "$c" 2> /dev/null)
      ok_regel=0
      if [ "$fichiers" = "$rel" ]; then
        corps=$(git log -1 --format=%B "$c")
        while IFS= read -r ligne; do
          if [[ $ligne =~ $re_regel ]]; then
            ok_regel=1
            regel_lignes="$regel_lignes$(printf 'EMPREINTE-REGEL %s %s — %s' "$(git rev-parse --short "$c")" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}")"$'\n'
            break
          fi
        done <<EOF
$corps
EOF
      fi
      if [ "$ok_regel" -eq 1 ]; then
        regels=$((regels + 1))
      else
        nc=-1
        break
      fi
    done < <(git log --reverse --format=%H -- "$sha")
    if [ "$nc" -lt 1 ]; then
      echo "EMPREINTE-ECART gel-rouvert"
      ec=$((ec + 1))
    else
      k=$(git rev-list --count "$gel..HEAD" -- "$outil")
      if [ "$k" -gt 0 ]; then
        printf 'EMPREINTE-ECART commit-apres-gel n=%s\n' "$k"
        ec=$((ec + 1))
      fi
    fi
  fi
  if [ "$ec" -eq 0 ]; then
    [ -z "$regel_lignes" ] || printf '%s' "$regel_lignes"
    printf 'EMPREINTE ok sha256=%s gel=%s regels=%s\n' "$h" "$gel" "$regels"
    return 0
  fi
  return 1
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
    suite | toutes | base-duree | imputer)
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

# Trace d'un cas reel-* : les lignes de la VRAIE sortie qui portent le verdict (motifs de rouge obtenus), recopiées
# telles quelles dans la sortie de l'autotest.
at_trace() {
  [ -n "$AT_OUT" ] && [ -f "$AT_OUT" ] || return 0
  AT_C="$AT_NOM" LC_ALL=C awk '
    index($0, "SUITE-ECART ") == 1 || index($0, "ETAT-ECART ") == 1 || index($0, "  ✗ ") == 1 || index($0, "SUITE ") == 1 {
      print "  AUTOTEST-TRACE " ENVIRON["AT_C"] " : " $0 }' "$AT_OUT"
}

at_fin() { # <attendu>
  local verdict=ok
  case $AT_NOM in reel-*) at_trace ;; esac
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
  local BF D1 D2 D3 D4 D5 D6 D7 D8 D9 S=plugin/m/tests/test-c.sh dead
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

  at_debut detache-suite-base-longue
  mk_suite $S "sleep 1; $CANON"
  mk_base "$BF" "$S:0:500"
  D8=$AT_TMP/d-suite-longue
  at_lancer suite $S --detache="$D8" --base-fichier="$BF"
  at_compte "DETACHE " 1
  at_attendre_fin "$D8" 60 || at_echec "fin.txt n'est jamais apparu"
  at_lancer sonder "$D8"
  at_contient "SUITE $S shell=bash rc=0"; at_contient "DETACHE-FIN rc=0"
  at_fin 0

  at_debut detache-toutes-base-longue
  mk_suite $S "sleep 1; $CANON"
  MK_BILAN_S=500 mk_base "$BF" "$S:0:2"
  D9=$AT_TMP/d-toutes-longue
  at_lancer toutes --detache="$D9" --base-fichier="$BF"
  at_compte "DETACHE " 1
  at_attendre_fin "$D9" 60 || at_echec "fin.txt n'est jamais apparu"
  at_lancer sonder "$D9"
  at_contient "TOUTES $S rc=0"; at_contient "DETACHE-FIN rc=0"
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
if [ "$etape" = 6 ]; then gates=G3,G4,G4P; else gates=G3,G4; fi
echo "RELEVE-VERDICT armable etape=$etape labs=1 gates=$gates"
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
    [ -z "${RV_COMMIT:-}" ] || echo "COMMIT-REJOUE $RV_COMMIT"
    [ -z "${RV_DECISION:-}" ] || printf '%s\n' "$RV_DECISION"
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
    elif [ "$e" = 6 ]; then
      echo "RELEVE-VERDICT armable etape=$e labs=1 gates=G3,G4,G4P"
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

# mk_hook_arm : faux hook de l'autotest d'armement, deux constantes et une ligne de corps hors ARMEMENT_*, plus une
# fausse commande enregistrée. Variables : AR_G4, AR_G4P (observe|armed), AR_CORPS, AR_CMD, AR_G4_DOUBLE (deux lignes
# ARMEMENT_G4), AR_G4_AUCUNE (aucune ligne ARMEMENT_G4).
mk_hook_arm() {
  local f="$FD/$HOOK_REL"
  mkdir -p "$(dirname "$f")" "$FD/$(dirname "$HOOKS_JSON_REL")"
  {
    printf '#!/usr/bin/env bash\n'
    if [ "${AR_G4_DOUBLE:-0}" = 1 ]; then
      printf 'ARMEMENT_G4 = "observe"  # etape-5\nARMEMENT_G4 = "armed"  # etape-5\n'
    elif [ "${AR_G4_AUCUNE:-0}" != 1 ]; then
      printf 'ARMEMENT_G4 = "%s"  # etape-5\n' "${AR_G4:-observe}"
    fi
    printf 'ARMEMENT_G4P = "%s"  # etape-6\n' "${AR_G4P:-observe}"
    printf 'CORPS = %s\n' "${AR_CORPS:-1}"
  } > "$f"
  printf '{"hooks": "%s"}\n' "${AR_CMD:-cmd-1}" > "$FD/$HOOKS_JSON_REL"
}

# arm_prepare : faux dépôt dont le commit REJOUÉ (ARM_SHA) porte les constantes à `observe`, puis un commit
# d'armement qui pose AR_G4 / AR_G4P (de l'environnement de l'appel) sans toucher au reste.
arm_prepare() {
  at_depot
  AR_G4=observe AR_G4P=observe mk_hook_arm
  at_commit
  ARM_SHA=$(cd "$FD" && git rev-parse HEAD)
  mk_hook_arm
  at_commit
}

# at_raison <cas> <motif attendu> : exactement UNE ligne `ARMEMENT-ECART decision-g4-*`, celle attendue ; la trace
# « raison attendue / raison obtenue » est imprimée pour chaque cas (le motif exact de l'outil, pas le seul code).
at_raison() {
  local obt n
  obt=$(P='ARMEMENT-ECART decision-g4-' LC_ALL=C awk 'BEGIN { p = ENVIRON["P"] } index($0, p) == 1 { sub(/^ARMEMENT-ECART /, ""); printf "%s%s", (n++ ? "," : ""), $0 }' "$AT_OUT")
  printf '  AUTOTEST-RAISON %s attendue=%s obtenue=%s\n' "$1" "$2" "${obt:-aucune}"
  [ "$obt" = "$2" ] || at_echec "raison obtenue « ${obt:-aucune} » au lieu de « $2 »"
}

autotest_armement() {
  local V R S2 side k
  local DOK='DECISION-G4 garder-g4 canal=AskUserQuestion date=2026-10-12'
  nouveau_tmp
  V=$NT/verif-arm.sh
  R=$NT/releve-arm.md
  mk_verif "$V"

  at_debut armement-observe
  arm_prepare
  AT_RC=0
  for k in "G4:5" "G4:6" "G4P:6"; do
    at_lancer armement --gate="${k%%:*}" --releve="$NT/inexistant.md" --etape="${k##*:}" --lab='<lab-1>' --verificateur="$V"
    [ "$AT_RC" -eq 0 ] || at_echec "appariement $k : code $AT_RC au lieu de 0"
    at_contient "ARMEMENT ${k%%:*} observe : rien à justifier"
  done
  at_fin 0

  at_debut armement-arme-coherent
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT G4 armed"; at_contient "ARMEMENT-COHERENCE ok"; at_absent "ARMEMENT-ECART"
  at_fin 0

  at_debut armement-arme-releve-non-armable
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 RV_VERDICT=non-armable mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART releve-non-armable"
  at_fin 1

  at_debut armement-arme-gate-absent
  AR_G4P=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 mk_releve "$R"
  at_lancer armement --gate=G4P --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART releve-non-armable"
  at_fin 1

  at_debut armement-g4-etape-6-armable
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-COHERENCE ok"; at_absent "ARMEMENT-ECART"
  at_fin 0

  at_debut armement-g4-etape-6-non-armable
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART releve-non-armable"
  at_fin 1

  at_debut armement-g4-etape-6-code-diverge
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 mk_releve "$R"
  AR_G4=armed AR_CORPS=2 mk_hook_arm
  at_commit
  at_lancer armement --gate=G4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART code-diverge $HOOK_REL commits=2"
  at_fin 1

  at_debut armement-g4p-etape-6-armable
  AR_G4P=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 mk_releve "$R"
  at_lancer armement --gate=G4P --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT G4P armed"; at_contient "ARMEMENT-COHERENCE ok"; at_absent "ARMEMENT-ECART"
  at_fin 0

  at_debut armement-g4p-etape-6-non-armable
  AR_G4P=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable mk_releve "$R"
  at_lancer armement --gate=G4P --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART releve-non-armable"
  at_fin 1

  at_debut armement-g4p-simule-etape-6
  arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 mk_releve "$R"
  at_lancer armement --gate=G4P --simuler-arme --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT G4P simule"; at_contient "ARMEMENT-COHERENCE ok"
  at_fin 0

  at_debut armement-etape-invalide
  arm_prepare
  at_lancer armement --gate=G4 --releve="$R" --etape=7 --lab='<lab-1>' --verificateur="$V"
  at_fin 64

  at_debut armement-gate-invalide
  arm_prepare
  at_lancer armement --gate=G7 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_fin 64

  at_debut armement-arme-non-joue
  AR_G4=armed arm_prepare
  RV_NON_JOUE=1 mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART releve-non-joue"
  at_fin 1

  at_debut armement-arme-code-diverge
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 mk_releve "$R"
  AR_G4=armed AR_CORPS=2 mk_hook_arm
  at_commit
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART code-diverge $HOOK_REL commits=2"; at_absent "code-diverge $HOOKS_JSON_REL"
  at_fin 1

  at_debut armement-arme-code-diverge-arbre
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 mk_releve "$R"
  AR_G4=armed AR_CORPS=3 mk_hook_arm
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART code-diverge $HOOK_REL arbre-de-travail"
  at_fin 1

  at_debut armement-arme-commande-diverge
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 mk_releve "$R"
  AR_G4=armed AR_CMD=cmd-2 mk_hook_arm
  at_commit
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART code-diverge $HOOKS_JSON_REL commits=1"; at_absent "code-diverge $HOOK_REL"
  at_fin 1

  at_debut armement-arme-commit-inconnu
  AR_G4=armed arm_prepare
  RV_COMMIT=abababababababababababababababababababab RV_ETAPE=5 mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART commit-inconnu"
  at_fin 1

  at_debut armement-arme-commit-non-ancetre
  AR_G4=armed arm_prepare
  (cd "$FD" && gitf checkout -q -b autre && echo x > x.txt && gitf add -A && gitf commit -q -m autre && gitf checkout -q main) > /dev/null 2>&1
  side=$(cd "$FD" && git rev-parse autre)
  RV_COMMIT=$side RV_ETAPE=5 mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART commit-non-ancetre"
  at_fin 1

  at_debut armement-arme-sans-commit-rejoue
  AR_G4=armed arm_prepare
  RV_ETAPE=5 mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART commit-rejoue-absent"
  at_fin 1

  at_debut armement-constante-illisible
  AR_G4_DOUBLE=1 arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART constante-illisible"
  at_fin 1

  at_debut armement-simule-armable
  arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 mk_releve "$R"
  at_lancer armement --gate=G4 --simuler-arme --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT G4 simule"; at_contient "ARMEMENT-COHERENCE ok"
  at_fin 0

  at_debut armement-simule-non-armable
  arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 RV_VERDICT=non-armable mk_releve "$R"
  at_lancer armement --gate=G4 --simuler-arme --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART releve-non-armable"
  at_fin 1

  # --garder-g4 : appariement (G4, 6), constante `armed  # etape-5`, relevé d'étape 6 NON armable sauf mention.
  at_debut garder-g4-vert
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION="$DOK" mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT G4 armed : non remesuré, décision garder-g4 canal=AskUserQuestion date=2026-10-12"
  at_contient "ARMEMENT-ECART releve-non-armable"
  at_fin 0

  at_debut garder-g4-armable
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-COHERENCE ok"; at_absent "non remesuré"; at_absent "ARMEMENT-ECART"
  at_fin 0

  at_debut garder-g4-sans-option
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION="$DOK" mk_releve "$R"
  at_lancer armement --gate=G4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART releve-non-armable"; at_absent "non remesuré"
  at_fin 1

  at_debut garder-g4-code-diverge
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=5 RV_DECISION="$DOK" mk_releve "$R"
  AR_G4=armed AR_CORPS=2 mk_hook_arm
  at_commit
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=5 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART code-diverge"; at_contient "non remesuré, décision garder-g4"
  at_fin 0

  at_debut garder-g4-doublon
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION="$DOK
$DOK" mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_raison garder-g4-doublon decision-g4-doublon; at_absent "non remesuré"
  at_fin 1

  at_debut garder-g4-observation
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION='DECISION-G4 g4-observation canal=AskUserQuestion date=2026-10-12' mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_raison garder-g4-observation decision-g4-observation; at_absent "non remesuré"
  at_fin 1

  # Un cas = UNE raison de rougir : le canal vide, la date de mauvaise forme et la date de bonne forme mais
  # invalide sont trois cas distincts, chacun affirmant le motif exact imprimé par l'outil.
  at_debut garder-g4-canal-vide
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION='DECISION-G4 garder-g4 canal= date=2026-10-12' mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_raison garder-g4-canal-vide decision-g4-canal-vide; at_absent "non remesuré"
  at_fin 1

  at_debut garder-g4-date-forme
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION='DECISION-G4 garder-g4 canal=AskUserQuestion date=2026-13-45x' mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_raison garder-g4-date-forme decision-g4-date-forme; at_absent "non remesuré"
  at_fin 1

  at_debut garder-g4-date-invalide
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION='DECISION-G4 garder-g4 canal=AskUserQuestion date=2026-13-45' mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_raison garder-g4-date-invalide decision-g4-date-invalide; at_absent "non remesuré"
  at_fin 1

  at_debut garder-g4-forme
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION='DECISION-G4 garder canal=AskUserQuestion date=2026-10-12' mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_raison garder-g4-forme decision-g4-forme
  at_fin 1

  at_debut garder-g4-constante-illisible
  AR_G4_DOUBLE=1 arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION="$DOK" mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART constante-illisible"; at_absent "non remesuré"
  k=$AT_RC
  AR_G4_AUCUNE=1 arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION="$DOK" mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT-ECART constante-illisible"; at_absent "non remesuré"
  [ "$k" -eq 1 ] || at_echec "deux lignes ARMEMENT_G4 : code $k au lieu de 1"
  at_fin 1

  at_debut garder-g4-releve-absent
  AR_G4=armed arm_prepare
  at_lancer armement --gate=G4 --garder-g4 --releve="$NT/n-existe-pas.md" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_raison garder-g4-releve-absent decision-g4-releve-absent; at_absent "non remesuré"
  at_fin 1

  at_debut garder-g4-observe
  arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION="$DOK" mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_contient "ARMEMENT G4 observe : rien à justifier"; at_absent "non remesuré"
  at_fin 0

  at_debut garder-g4-g4p
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION="$DOK" mk_releve "$R"
  at_lancer armement --gate=G4P --garder-g4 --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_fin 64

  at_debut garder-g4-simule
  AR_G4=armed arm_prepare
  RV_COMMIT=$ARM_SHA RV_ETAPE=6 RV_VERDICT=non-armable RV_DECISION="$DOK" mk_releve "$R"
  at_lancer armement --gate=G4 --garder-g4 --simuler-arme --releve="$R" --etape=6 --lab='<lab-1>' --verificateur="$V"
  at_fin 64
}

# mk_etat <dossier> : écrit hook.sh, ref.md et tests.sh d'un mini état d'armement cohérent (G4 et G4′ à `observe`).
# Variables : ET_G4, ET_G4P (valeur des constantes), ET_G4_DOUBLE (deux lignes ARMEMENT_G4), ET_K1, ET_K2, ET_K4 (ligne
# de phrase de remplacement ; `-` la supprime), ET_T_G4 / ET_T_G4E (état / étape de la ligne G4 de la table),
# ET_SANS_LIGNE_G4P (pas de ligne G4P), ET_SANS_LIGNE_BS (pas de ligne canonique de la limite (bs)), ET_LIMITES
# (lettres du tuple, défaut « bp bs »), ET_SANS_LIMITES, ET_SEULEMENT_TABLE (aucune phrase K1/K2/K4), ET_EXTRA (lignes
# ajoutées).
etat_mot() { if [ "$1" = armed ]; then printf 'armé'; else printf 'en observation'; fi; }

mk_etat() {
  local d=$1 g4=${ET_G4:-observe} g4p=${ET_G4P:-observe} l ligne
  mkdir -p "$d"
  {
    printf 'ARMEMENT_G6 = "armed"  # etape-1\nARMEMENT_G5 = "armed"  # etape-1\nARMEMENT_G1 = "armed"  # etape-2\n'
    printf 'ARMEMENT_G7 = "armed"  # etape-3\nARMEMENT_ROLE = "armed"  # etape-4\nARMEMENT_G3 = "armed"  # etape-5\n'
    if [ "${ET_G4_DOUBLE:-0}" = 1 ]; then
      printf 'ARMEMENT_G4 = "observe"  # etape-5\nARMEMENT_G4 = "armed"  # etape-5\n'
    else
      printf 'ARMEMENT_G4 = "%s"  # etape-5\n' "$g4"
    fi
    printf 'ARMEMENT_G4P = "%s"  # etape-6\nG2_MODE = "avertit"\n' "$g4p"
  } > "$d/hook.sh"
  {
    printf '# Référence de test\n\n'
    if [ "${ET_SEULEMENT_TABLE:-0}" != 1 ]; then
      if [ "${ET_K1:-}" = "-" ]; then
        :
      elif [ -n "${ET_K1:-}" ]; then
        printf '%s\n' "$ET_K1"
      else
        ligne='Armés : `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` et `ARMEMENT_G3` valent `armed`'
        printf '%s ; `ARMEMENT_G4` vaut `%s` ; `ARMEMENT_G4P` vaut `%s`.\n' "$ligne" "$g4" "$g4p"
      fi
      if [ "${ET_K4:-}" = "-" ]; then
        :
      elif [ -n "${ET_K4:-}" ]; then
        printf '%s\n' "$ET_K4"
      else
        printf 'G4′ reste %s.\n' "$(etat_mot "$g4p")"
      fi
      if [ "${ET_K2:-}" = "-" ]; then
        :
      elif [ -n "${ET_K2:-}" ]; then
        printf '%s\n' "$ET_K2"
      else
        printf 'Hors de cette phase : (G3 armé ; G4 %s ; G4′ %s, limites (bp) et (bs)).\n' "$(etat_mot "$g4")" "$(etat_mot "$g4p")"
      fi
    fi
    printf '\n| Gate | Étape | État | Comportement |\n|---|---|---|---|\n'
    printf '| G6 | 1 | armed | x |\n| G5 | 1 | armed | x |\n| G1 | 2 | armed | x |\n| G7 | 3 | armed | x |\n'
    printf '| ROLE | 4 | armed | x |\n| G3 | 5 | armed | x |\n'
    printf '| G4 | %s | %s | x |\n' "${ET_T_G4E:-5}" "${ET_T_G4:-$g4}"
    [ "${ET_SANS_LIGNE_G4P:-0}" = 1 ] || printf '| G4P | 6 | %s | x |\n' "$g4p"
    printf '| G2 | - | avertit | x |\n\n'
    printf -- '- **limite (bp)** — première limite\n'
    [ "${ET_SANS_LIGNE_BS:-0}" = 1 ] || printf -- '- **limite (bs)** — seconde limite\n'
    [ -z "${ET_EXTRA:-}" ] || printf '%s\n' "$ET_EXTRA"
  } > "$d/ref.md"
  {
    printf '#!/usr/bin/env bash\necho x\n'
    if [ "${ET_SANS_LIMITES:-0}" != 1 ]; then
      printf 'LIMITES_REFERENCE = (\n'
      for l in ${ET_LIMITES:-bp bs}; do printf '    ("%s", ("mot",)),\n' "$l"; done
      printf ')\n'
    fi
  } > "$d/tests.sh"
}

at_etat() { # <dossier> : lance etat-reference sur les trois mini fichiers
  at_lancer etat-reference --reference="$1/ref.md" --hook="$1/hook.sh" --tests="$1/tests.sh"
}

# Remplace dans <src> la sous-chaîne <ancien> (présente sur UNE seule ligne, une seule fois) par <nouveau> ; écrit <dst>.
at_remplacer() { # <src> <dst> <ancien> <nouveau>
  A="$3" N="$4" LC_ALL=C awk '
    BEGIN { a = ENVIRON["A"]; n = ENVIRON["N"] }
    { i = index($0, a); if (i > 0) { c++; $0 = substr($0, 1, i - 1) n substr($0, i + length(a)) } print }
    END { if (c != 1) exit 3 }' "$1" > "$2" || { at_echec "reel-ancre : « $3 » absente ou multiple dans $1"; return 1; }
  return 0
}

autotest_etat() {
  local D
  at_depot
  nouveau_tmp
  D=$NT/etat

  at_debut etat-ref-coherent
  mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-BILAN"; at_contient "ecarts=0"; at_absent "ETAT-ECART"; at_contient "k3=9"
  at_fin 0

  at_debut etat-ref-k1-fausse
  ET_K1='Armés : `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` et `ARMEMENT_G3` valent `armed` ; `ARMEMENT_G4` et `ARMEMENT_G4P` valent `armed`.' mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART k1"; at_contient "G4 dit=armed constante=observe"
  at_fin 1

  at_debut etat-ref-k2-fausse
  ET_K2='Hors de cette phase : (G3 armé ; G4 armé ; G4′ en observation, limites (bp) et (bs)).' mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART k2"; at_contient "G4 dit=armed constante=observe"
  at_fin 1

  at_debut etat-ref-k3-fausse
  ET_T_G4=armed mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART k3 "; at_contient "G4 dit=armed constante=observe"
  at_fin 1

  at_debut etat-ref-k3-etape-fausse
  ET_T_G4E=6 mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART k3-etape"; at_contient "G4 dit=6 constante=5"
  at_fin 1

  at_debut etat-ref-k3-ligne-manquante
  ET_SANS_LIGNE_G4P=1 mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART k3-ligne-manquante G4P"
  at_fin 1

  at_debut etat-ref-k4-fausse
  ET_K4='G4′ reste en observation.' ET_G4P=armed mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART k4"; at_contient "G4P dit=observe constante=armed"
  at_fin 1

  at_debut etat-ref-constante-changee
  mk_etat "$D"
  at_etat "$D"
  [ "$AT_RC" -eq 0 ] || at_echec "les documents cohérents rendent $AT_RC au lieu de 0"
  ET_G4P=observe mk_etat "$D"
  A='ARMEMENT_G4P = "observe"  # etape-6' N='ARMEMENT_G4P = "armed"  # etape-6' awk '$0 == ENVIRON["A"] { $0 = ENVIRON["N"]; c++ } { print } END { if (c == 1) exit 0; exit 3 }' "$D/hook.sh" > "$D/hook.mut" || at_echec "constante de G4P introuvable"
  mv "$D/hook.mut" "$D/hook.sh"
  at_etat "$D"
  at_contient "ETAT-ECART"; at_contient "G4P dit=observe constante=armed"
  at_fin 1

  at_debut etat-ref-limite-levee
  ET_LIMITES='bp' mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART limite-absente bs"
  at_fin 1

  at_debut etat-ref-limite-sans-ligne
  ET_SANS_LIGNE_BS=1 mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART limite-sans-ligne bs"; at_absent "limite-absente"
  at_fin 1

  at_debut etat-ref-conditionnelle-ignoree
  ET_G4=armed ET_G4P=observe ET_EXTRA='Erreur interne : `block` si `ARMEMENT_G4P` vaut `armed`, ligne d'"'"'observation sinon.
G4 ne refuse rien tant que `ARMEMENT_G4` vaut `observe`.' mk_etat "$D"
  at_etat "$D"
  at_contient "ecarts=0"; at_compte "ETAT-IGNORE" 2; at_contient "motif=si"; at_contient "motif=tant que"; at_absent "ETAT-ECART"
  at_fin 0

  at_debut etat-ref-hypothese-exclue
  ET_EXTRA='Une table qui la viole (G4 armé sans G3) refuse tout.
La suite exige G3 ET G4 armés avant tout armement.' mk_etat "$D"
  at_etat "$D"
  at_contient "ecarts=0"; at_compte "ETAT-IGNORE" 2; at_contient "motif=sans"; at_contient "motif=exige"; at_absent "ETAT-ECART"
  at_fin 0

  at_debut etat-ref-gate-non-couvert
  ET_K1='Armés : `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` et `ARMEMENT_G3` valent `armed` ; `ARMEMENT_G4P` vaut `observe`.' \
    ET_K2='Hors de cette phase : (G3 armé ; G4′ en observation, limites (bp) et (bs)).' ET_K4='Le gate G4 reste, pour l'"'"'instant, en attente.' mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART gate-non-couvert G4"; at_absent "gate-non-couvert G4P"
  at_fin 1

  at_debut etat-ref-non-reconnue-visible
  ET_EXTRA='Le gate G4 est livré en mode observe pour cette étape.' mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-NON-RECONNUE"; at_contient "ecarts=0"; at_contient "non-reconnues=1"
  at_fin 0

  at_debut etat-ref-vide
  ET_SEULEMENT_TABLE=1 mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART aucune-phrase"
  at_fin 1

  at_debut etat-ref-constante-illisible
  ET_G4_DOUBLE=1 mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART constante-illisible G4"
  at_fin 1

  at_debut etat-ref-limites-illisibles
  ET_SANS_LIMITES=1 mk_etat "$D"
  at_etat "$D"
  at_contient "ETAT-ECART limites-illisibles"
  at_fin 1

  at_debut etat-ref-fichier-absent
  mk_etat "$D"
  at_lancer etat-reference --reference="$D/n-existe-pas.md" --hook="$D/hook.sh" --tests="$D/tests.sh"
  at_fin 64

  at_debut etat-ref-hook-sans-constantes
  mk_etat "$D"
  at_lancer etat-reference --reference="$D/ref.md" --hook="$D/ref.md" --tests="$D/tests.sh"
  at_contient "ETAT-ECART constante-illisible"
  at_fin 1
}

# Cas reel-etat-* : copies sandbox de la VRAIE référence, du VRAI hook et de la VRAIE suite de tests ; la perturbation
# ne touche que la copie. Si la grammaire ne reconnaît pas la phrase réelle, la perturbation ne rougit pas et le cas échoue.
autotest_reel_etat() {
  local R=plugin/planning-core/references/modele-cycles.md H=plugin/planning-core/scripts/planning-hook.sh
  local T=plugin/planning-core/scripts/tests/test-planning-gates.sh D
  nouveau_tmp
  D=$NT/reel-etat
  mkdir -p "$D"
  AT_CWD=$AT_RACINE

  at_debut reel-etat-temoin
  AT_RC=0
  if [ -n "$AT_RACINE" ]; then
    cp "$AT_RACINE/$R" "$D/ref.md" && cp "$AT_RACINE/$H" "$D/hook.sh" && cp "$AT_RACINE/$T" "$D/tests.sh" || at_echec "copie des fichiers réels impossible"
    cmp -s "$D/ref.md" "$AT_RACINE/$R" || at_echec "la référence copiée diffère de l'originale"
    at_etat "$D"
    at_contient "ecarts=0"; at_absent "ETAT-ECART"
  else
    at_echec "racine du dépôt introuvable"
  fi
  at_fin 0

  at_debut reel-etat-constante-changee
  AT_RC=0
  if [ -n "$AT_RACINE" ]; then
    cp "$AT_RACINE/$R" "$D/ref.md" && cp "$AT_RACINE/$T" "$D/tests.sh" || at_echec "copie des fichiers réels impossible"
    if at_perturber remplace "$AT_RACINE/$H" "$D/hook.sh" 'ARMEMENT_G4 = "observe"  # etape-5' 'ARMEMENT_G4 = "armed"  # etape-5'; then
      cmp -s "$D/hook.sh" "$AT_RACINE/$H" && at_echec "le hook copié est identique à l'original (aucune perturbation)"
      at_etat "$D"
      at_contient "ETAT-ECART"; at_contient "G4 dit=observe constante=armed"
    fi
  else
    at_echec "racine du dépôt introuvable"
  fi
  at_fin 1

  at_debut reel-etat-phrase-changee
  AT_RC=0
  if [ -n "$AT_RACINE" ]; then
    cp "$AT_RACINE/$H" "$D/hook.sh" && cp "$AT_RACINE/$T" "$D/tests.sh" || at_echec "copie des fichiers réels impossible"
    if at_remplacer "$AT_RACINE/$R" "$D/ref.md" 'G4 et G4′ en observation, limites (bp) et (bs))' 'G4 et G4′ armés, limites (bp) et (bs))'; then
      cmp -s "$D/ref.md" "$AT_RACINE/$R" && at_echec "la référence copiée est identique à l'originale (aucune perturbation)"
      at_etat "$D"
      at_contient "ETAT-ECART k2"; at_contient "G4 dit=armed constante=observe"
    fi
  else
    at_echec "racine du dépôt introuvable"
  fi
  at_fin 1
}

# imp_prepare <suite> <corps parent|-> <corps courant> [<etat parent> <etat courant>] : faux dépôt dont le commit du
# plan (IMP_SHA, HEAD) a un parent qui porte la suite `corps parent` (`-` : suite absente du parent). Le fichier
# etat.txt (facultatif) permet à une fausse suite de dépendre d'une donnée que l'export conserve.
imp_prepare() {
  at_depot
  if [ "$2" != - ]; then mk_suite "$1" "$2"; fi
  if [ -n "${4:-}" ]; then echo "$4" > "$FD/etat.txt"; fi
  at_commit
  mk_suite "$1" "$3"
  if [ -n "${5:-}" ]; then echo "$5" > "$FD/etat.txt"; fi
  echo plan > "$FD/plan.txt"
  at_commit
  IMP_SHA=$(cd "$FD" && git rev-parse HEAD)
}

autotest_imputer() {
  local S=plugin/m/tests/test-c.sh SP=plugin/planning-core/scripts/tests/test-planning-gates.sh BF D avant apres
  local CANON='echo "== Résultat : 3 OK · 0 KO =="'
  local ROUGE="echo '  ✗ A'; echo '== Résultat : 2 OK · 1 KO =='; exit 1"
  local ROUGE_AB="echo '  ✗ A'; echo '  ✗ B'; echo '== Résultat : 1 OK · 2 KO =='; exit 1"
  local SANS_DEPOT='d=.g; d="${d}it"; if [ ! -d "$d" ] || [ "$(cat etat.txt 2>/dev/null)" = rouge ]; then echo "  ✗ A"; echo "== Résultat : 1 OK · 1 KO =="; exit 1; fi; echo "== Résultat : 2 OK · 0 KO =="'
  local PAR_FICHIER='if [ "$(cat etat.txt 2>/dev/null)" = rouge ]; then echo "  ✗ A"; echo "== Résultat : 1 OK · 1 KO =="; exit 1; fi; echo "== Résultat : 2 OK · 0 KO =="'
  local SENSIBLE='git rev-parse --git-dir > /dev/null 2>&1; if [ "$(cat etat.txt 2>/dev/null)" = rouge ]; then echo "  ✗ A"; echo "== Résultat : 1 OK · 1 KO =="; exit 1; fi; echo "== Résultat : 2 OK · 0 KO =="'
  BF=$AT_TMP/base-imputer.txt

  at_debut imputer-preexistant
  imp_prepare $S "$ROUGE" "$ROUGE"
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "IMPUTATION $S verdict=preexistant rejeux=3 escalade-willy=non"; at_contient "sur=courant n=1 rc=1"
  at_contient "sur=parent n=1 rc=1"; at_contient "sur=parent-depot n=1 rc=1"
  at_fin 0

  at_debut imputer-bilan-structurel
  imp_prepare $S "echo '== résultat : 3 passés, 0 échoués =='" "echo '== résultat : 3 passés, 0 échoués =='"
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "IMPUTATION $S verdict=preexistant rejeux=3 escalade-willy=non"; at_contient "motifs=bilan_forme-inconnue"; at_absent "lignes-ko=1"
  at_fin 0

  at_debut imputer-imputable
  imp_prepare $S "$CANON" "$ROUGE"
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "IMPUTATION $S verdict=imputable rejeux=2 escalade-willy=non"; at_contient "sur=parent n=1 rc=0"
  at_fin 1

  at_debut imputer-imputable-nouveau-ko
  imp_prepare $S "$ROUGE" "$ROUGE_AB"
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "IMPUTATION-NOUVEAU   ✗ B"; at_contient "verdict=imputable"; at_absent "sur=parent-depot"
  at_fin 1

  at_debut imputer-instable
  imp_prepare $S "$CANON" "$CANON"
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "IMPUTATION $S verdict=instable rejeux=2 escalade-willy=non cause=non-reproduit"; at_contient "sur=courant n=2 rc=0"
  at_fin 0

  at_debut imputer-parent-sans-depot
  imp_prepare $S "$SANS_DEPOT" "$SANS_DEPOT" ok rouge
  grep -w git "$FD/$S" > /dev/null && at_echec "la fausse suite cite le mot git"
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "sur=parent n=1 rc=1"; at_contient "sur=parent-depot n=1 rc=0"; at_contient "IMPUTATION $S verdict=imputable rejeux=3"
  at_fin 1

  at_debut imputer-parent-depot-preexistant
  imp_prepare $S "$PAR_FICHIER" "$PAR_FICHIER" rouge rouge
  grep -w git "$FD/$S" > /dev/null && at_echec "la fausse suite cite le mot git"
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "sur=parent-depot n=1 rc=1"; at_contient "IMPUTATION $S verdict=preexistant rejeux=3 escalade-willy=non"
  at_fin 0

  at_debut imputer-suite-sensible-depot
  imp_prepare $S "$SENSIBLE" "$SENSIBLE" rouge rouge
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "IMPUTATION $S verdict=instable rejeux=3 escalade-willy=non cause=suite-sensible-depot"; at_absent "verdict=preexistant"
  at_fin 0

  at_debut imputer-suite-neuve
  imp_prepare $S - "$ROUGE"
  at_lancer imputer $S --commit="$IMP_SHA"
  at_contient "IMPUTATION-NOTE suite-neuve"; at_contient "IMPUTATION $S verdict=imputable rejeux=1"
  at_fin 1

  at_debut imputer-escalade-porteuse
  imp_prepare $SP "$ROUGE" "$ROUGE"
  at_lancer imputer $SP --commit="$IMP_SHA"
  at_contient "IMPUTATION $SP verdict=preexistant rejeux=3 escalade-willy=oui"
  at_fin 1

  at_debut imputer-escalade-hors-liste
  imp_prepare plugin/m/tests/test-hors-liste.sh "$ROUGE" "$ROUGE"
  at_lancer imputer plugin/m/tests/test-hors-liste.sh --commit="$IMP_SHA"
  at_contient "verdict=preexistant"; at_contient "escalade-willy=non"
  at_fin 0

  at_debut imputer-sans-effet
  imp_prepare $S "$SANS_DEPOT" "$SANS_DEPOT" ok rouge
  avant="$(cd "$FD" && git rev-parse HEAD; git status --porcelain; git stash list; git for-each-ref)"
  at_lancer imputer $S --commit="$IMP_SHA"
  apres="$(cd "$FD" && git rev-parse HEAD; git status --porcelain; git stash list; git for-each-ref)"
  [ "$avant" = "$apres" ] || at_echec "HEAD, index, arbre de travail, pile des stash ou références modifiés"
  at_contient "sur=parent-depot"
  [ -z "$(cd "$FD" && git stash list)" ] || at_echec "la pile des stash n'est pas vide"
  at_fin 1

  at_debut imputer-commit-inconnu
  imp_prepare $S "$CANON" "$CANON"
  at_lancer imputer $S --commit=0000000000000000000000000000000000000000
  at_contient "commit-inconnu"
  at_fin 64

  at_debut imputer-commit-sans-parent
  imp_prepare $S "$CANON" "$CANON"
  at_lancer imputer $S --commit="$(cd "$FD" && git rev-list --max-parents=0 HEAD)"
  at_contient "commit-sans-parent"
  at_fin 64

  at_debut imputer-detache-borne
  imp_prepare $S "$ROUGE" "$ROUGE"
  mk_base "$BF" "$S:0:4"
  D=$AT_TMP/d-imputer
  at_lancer imputer $S --commit="$IMP_SHA" --detache="$D" --base-fichier="$BF"
  [ "$(cat "$D/borne.txt" 2> /dev/null)" = 36 ] || at_echec "borne.txt vaut « $(cat "$D/borne.txt" 2> /dev/null) » au lieu de 36 (9 × 4)"
  at_fichier_contient "$D/commande.txt" "mode=imputer"
  at_attendre_fin "$D" 120 || at_echec "fin.txt n'est jamais apparu"
  at_lancer sonder "$D"
  at_contient "IMPUTATION $S verdict=preexistant"
  at_fin 0

  at_debut imputer-detache-base-longue
  imp_prepare $S "$ROUGE" "$ROUGE"
  mk_base "$BF" "$S:0:500"
  D=$AT_TMP/d-imputer-longue
  at_lancer imputer $S --commit="$IMP_SHA" --detache="$D" --base-fichier="$BF"
  at_attendre_fin "$D" 120 || at_echec "fin.txt n'est jamais apparu"
  at_lancer sonder "$D"
  at_contient "IMPUTATION $S verdict=preexistant"
  at_absent "detache-requis"
  at_fin 0
}

# jal_prepare : faux dépôt avec le hook et sa commande enregistrée commités (JAL_SHA), une base de deux suites
# (JAL_BF) et un fichier de jalons à écrire (JAL_F). Variables de jal_ligne : JL_N, JL_COMMIT, JL_SUITES, JL_VERTES,
# JL_ROUGES, JL_IMP, JL_PRE, JL_INS.
jal_prepare() {
  at_depot
  mkdir -p "$FD/$(dirname "$HOOK_REL")" "$FD/$(dirname "$HOOKS_JSON_REL")"
  echo hook > "$FD/$HOOK_REL"
  echo '{}' > "$FD/$HOOKS_JSON_REL"
  at_commit
  JAL_SHA=$(cd "$FD" && git rev-parse HEAD)
  JAL_BF=$AT_TMP/base-jalon.txt
  mk_base "$JAL_BF" "a.sh:0:1" "b.sh:0:1"
  JAL_F=$AT_TMP/jalons.txt
}

jal_ligne() {
  printf 'JALON %s commit=%s date=2026-10-13T10:00:00Z TOUTES-BILAN suites=%s vertes=%s rouges=%s zero-ok=0 s=3600 imputables=%s preexistants=%s instables=%s\n' \
    "${JL_N:-1}" "${JL_COMMIT:-$JAL_SHA}" "${JL_SUITES:-109}" "${JL_VERTES:-101}" "${JL_ROUGES:-8}" "${JL_IMP:-0}" "${JL_PRE:-8}" "${JL_INS:-0}"
}

at_jalon() { # <n>
  at_lancer jalon "$1" --jalons-fichier="$JAL_F" --base-fichier="$JAL_BF"
}

autotest_jalon() {
  local side
  jal_prepare

  at_debut jalon-ok
  jal_ligne > "$JAL_F"
  at_jalon 1
  at_contient "JALON-VERIF 1 ok"; at_absent "JALON-ECART"
  at_fin 0

  at_debut jalon-absent
  at_lancer jalon 1 --jalons-fichier="$AT_TMP/n-existe-pas.txt" --base-fichier="$JAL_BF"
  at_contient "JALON-ECART jalon-absent"
  at_fin 1

  at_debut jalon-sans-ligne
  JL_N=2 jal_ligne > "$JAL_F"
  at_jalon 1
  at_contient "JALON-ECART jalon-absent"
  at_fin 1

  at_debut jalon-double
  { jal_ligne; jal_ligne; } > "$JAL_F"
  at_jalon 1
  at_contient "JALON-ECART jalon-double"
  at_fin 1

  at_debut jalon-forme
  jal_ligne | sed 's/ instables=0$//' > "$JAL_F"
  at_jalon 1
  at_contient "JALON-ECART jalon-forme"
  at_fin 1

  at_debut jalon-imputables
  JL_IMP=1 JL_PRE=7 jal_ligne > "$JAL_F"
  at_jalon 1
  at_contient "JALON-ECART jalon-imputables"; at_compte "JALON-ECART" 1
  at_fin 1

  at_debut jalon-commit-non-ancetre
  (cd "$FD" && gitf checkout -q -b autre && echo x > x.txt && gitf add -A && gitf commit -q -m autre && gitf checkout -q main) > /dev/null 2>&1
  side=$(cd "$FD" && git rev-parse autre)
  JL_COMMIT=$side jal_ligne > "$JAL_F"
  at_jalon 1
  at_contient "JALON-ECART jalon-commit-non-ancetre"; at_compte "JALON-ECART" 1
  at_fin 1

  at_debut jalon-comptes-incoherents
  JL_ROUGES=3 JL_PRE=1 JL_IMP=0 JL_INS=1 jal_ligne > "$JAL_F"
  at_jalon 1
  at_contient "JALON-ECART jalon-comptes-incoherents"; at_compte "JALON-ECART" 1
  at_fin 1

  at_debut jalon-decouverte-partielle
  JL_SUITES=1 jal_ligne > "$JAL_F"
  at_jalon 1
  at_contient "JALON-ECART jalon-decouverte-partielle"; at_compte "JALON-ECART" 1
  at_fin 1

  at_debut jalon-perime
  jal_ligne > "$JAL_F"
  echo "hook change" > "$FD/$HOOK_REL"
  at_commit
  at_jalon 1
  at_contient "JALON-ECART jalon-perime"; at_compte "JALON-ECART" 1
  at_fin 1

  at_debut jalon-numero-invalide
  jal_ligne > "$JAL_F"
  at_jalon 4
  at_fin 64
}

# Cas empreinte : une COPIE de l'outil, nommée 46.1-CONTROLES.sh, commitée dans un faux dépôt, est lancée depuis ce
# dépôt (l'empreinte est celle de l'outil qui s'exécute, à côté de son .sha256).
at_lancer_copie() { local OUTIL=$COPIE; at_lancer "$@"; }

emp_prepare() {
  at_depot
  COPIE=$FD/phase/46.1-CONTROLES.sh
  cp "$OUTIL" "$COPIE"
  at_commit
}

emp_geler() { # gèle (écrit le .sha256) puis le commite
  at_lancer_copie empreinte --geler
  at_commit
}

# emp_regel <message> [autre] : l'outil (copie) est modifié et commité, puis le .sha256 est réécrit et commité avec le
# message donné (et, si « autre » est passé, avec un second fichier dans le même commit).
emp_regel() {
  echo "# correction légitime" >> "$COPIE"
  at_commit
  python3 -I -S -c '
import hashlib, sys
d = sys.argv[1]
h = hashlib.sha256(open(d + "/46.1-CONTROLES.sh", "rb").read()).hexdigest()
open(d + "/46.1-CONTROLES.sha256", "w").write(h + "  46.1-CONTROLES.sh\n")
' "$FD/phase"
  [ -z "${2:-}" ] || echo autre > "$FD/phase/autre.txt"
  (cd "$FD" && gitf add -A && gitf commit -q -m "$1") > /dev/null 2>&1
}

autotest_empreinte() {
  local COPIE=""
  local TRAILER='Regel-Outil: 261013-owa — correction de la copie détachée'

  at_debut empreinte-ok
  emp_prepare
  emp_geler
  at_lancer_copie empreinte
  at_contient "EMPREINTE ok sha256="; at_contient " gel="; at_absent "EMPREINTE-ECART"
  at_fin 0

  at_debut empreinte-absente
  emp_prepare
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART absente"
  at_fin 1

  at_debut empreinte-modifie
  emp_prepare
  emp_geler
  echo "# modification après l'empreinte" >> "$COPIE"
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART modifie"
  at_fin 1

  at_debut empreinte-commit-apres-gel
  emp_prepare
  emp_geler
  echo "# commit après le gel" >> "$COPIE"
  at_commit
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART commit-apres-gel n=1"
  at_fin 1

  at_debut empreinte-gel-rouvert
  emp_prepare
  emp_geler
  cp "$FD/phase/46.1-CONTROLES.sha256" "$AT_TMP/sha.sauvegarde"
  echo "0000" > "$FD/phase/46.1-CONTROLES.sha256"
  at_commit
  cp "$AT_TMP/sha.sauvegarde" "$FD/phase/46.1-CONTROLES.sha256"
  at_commit
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART gel-rouvert"; at_compte "EMPREINTE-ECART" 1
  at_fin 1

  at_debut empreinte-regel-declare
  emp_prepare
  emp_geler
  emp_regel "regel"$'\n\n'"$TRAILER"
  at_lancer_copie empreinte
  at_contient "EMPREINTE-REGEL "; at_contient " 261013-owa — correction de la copie détachée"
  at_contient "EMPREINTE ok sha256="; at_contient " regels=1"; at_absent "EMPREINTE-ECART"
  at_fin 0

  at_debut empreinte-regel-sans-trailer
  emp_prepare
  emp_geler
  emp_regel "regel sans trailer"
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART gel-rouvert"; at_compte "EMPREINTE-ECART" 1
  at_fin 1

  at_debut empreinte-regel-trailer-mal-forme
  emp_prepare
  emp_geler
  emp_regel "regel"$'\n\n'"Regel-Outil: 26101-owa — raison"
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART gel-rouvert"; at_compte "EMPREINTE-ECART" 1
  # même forme d'id correcte mais tiret simple au lieu du tiret cadratin, puis raison vide
  emp_prepare
  emp_geler
  emp_regel "regel"$'\n\n'"Regel-Outil: 261013-owa - raison"
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART gel-rouvert"; at_absent "EMPREINTE ok"
  emp_prepare
  emp_geler
  emp_regel "regel"$'\n\n'"Regel-Outil: 261013-owa — "
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART gel-rouvert"; at_absent "EMPREINTE ok"
  at_fin 1

  at_debut empreinte-regel-touche-autre
  emp_prepare
  emp_geler
  emp_regel "regel"$'\n\n'"$TRAILER" autre
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART gel-rouvert"; at_compte "EMPREINTE-ECART" 1
  at_fin 1

  at_debut empreinte-commit-apres-regel
  emp_prepare
  emp_geler
  emp_regel "regel"$'\n\n'"$TRAILER"
  echo "# commit après le regel" >> "$COPIE"
  at_commit
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART commit-apres-gel n=1"
  at_fin 1

  at_debut empreinte-non-commite
  emp_prepare
  at_lancer_copie empreinte --geler
  at_lancer_copie empreinte
  at_contient "EMPREINTE-ECART non-commite"; at_compte "EMPREINTE-ECART" 1
  at_fin 1

  at_debut empreinte-geler-refuse
  emp_prepare
  emp_geler
  at_lancer_copie empreinte --geler
  at_contient "geler-refuse"
  at_fin 64

  at_debut empreinte-geler-outil-non-commite
  emp_prepare
  echo "# non commité" >> "$COPIE"
  at_lancer_copie empreinte --geler
  at_contient "geler-refuse"
  [ ! -e "$FD/phase/46.1-CONTROLES.sha256" ] || at_echec "un .sha256 a été écrit pour un outil non commité"
  at_fin 64
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
  autotest_armement
  autotest_etat
  autotest_imputer
  autotest_jalon
  autotest_empreinte
  [ "$SANS_REEL" -eq 1 ] || autotest_reel_suite
  [ "$SANS_REEL" -eq 1 ] || autotest_reel_etat
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
    armement) cmd_armement "$@"; return $? ;;
    etat-reference) cmd_etat_reference "$@"; return $? ;;
    imputer) cmd_imputer "$@"; return $? ;;
    jalon) cmd_jalon "$@"; return $? ;;
    empreinte) cmd_empreinte "$@"; return $? ;;
    *) die_usage "46.1-CONTROLES.sh <suite|toutes|sonder|base-duree|invariants|releve|releve-chaine|armement|etat-reference|imputer|jalon|empreinte|--autotest|--help>" ;;
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
