# Phase 41 — registre des mesures

Chaque ligne `CLE: valeur` est une mesure consignée au moment où elle est faite. Une valeur non
mesurée s'écrit `non_prouvee` ou `indetermine`, jamais supposée. Les sorties humaines sont
recopiées verbatim dans des lignes `…-MSG:`. Aucun chemin absolu de machine.

## 41-01 — préalables externes

CONTEXTES-CHECKS: sha=5238cba66c0d878a9ff4eb1c32757c21c64b454d n=4 app=15368 egal_ci=oui

## 41-14 — base de la garde de trace

BASE-TRACE-ARBITRAGE: f1d658957f7fe9c446b341bc447c19d6a0a0ed3a
Motif : les commits de cadrage et de planification antérieurs à cette valeur précèdent la garde G-1 et ne sont pas réécrits — seule la plage `<sha>..HEAD` sera jugée par le contrôle de trace du plan 41-15.

## 41-15 — outillage de preuve du périmètre sans admin

RECENSEMENT-FERMETURE: rc=0 fichiers=20 hits=0 allowlist_entrees=3 allowlist_appliquees=3
RECENSEMENT-CONTROLES: R0=0,R1=1,R2=1,R3=1,R4=0,R5=0,R6=0,R7=2,R8=64,R9=1,R10=0,R11=0 mutants_tues=3
TRACE-ARBITRAGE: rc=0 commits=17 citants=2 base=f1d6589
TRACE-CONTROLES: C0=0,C1=1,C2=1,C3=0,C4=1,C5=0,C6=0,C7=3,C8=2,C9=64,C10=0,C11=0,C12=2,C13=2 mutants_tues=6
OUTILS-PERIMETRE: distribues=non etapes_ci=0 decouverts_par_le_job_tests=non
LIMITE-DE-FOND: exiges=7 porteurs=4 manquants=aucun
BORNE-TRACE: sha=f1d6589 source=41-PREUVES.md commits_juges=17 commits_hors_borne=1255
Note : le compte de mutants de check-trace-arbitrage.sh est passé de 4 à 6 (mesuré) au tour
précédent de ce plan, resserrement du détecteur à une liste fermée de marqueurs d'invocation.
Les valeurs `commits=`/`citants=`/`commits_juges=` ci-dessus sont mesurées juste avant l'écriture
de cette section ; toute mesure ultérieure du même contrôle inclura, en plus, le commit qui
introduit cette section elle-même — propriété déjà présente pour `BASE-TRACE-ARBITRAGE` et non
un défaut de cette mesure.

## 41-19 — clôture du périmètre sans admin

REJEU-GATES: rc=0 etapes=13 ecarts=0
REJEU-TESTS: rc=0 suites=82 echecs=0
G1-REEL: rc=0 verdict=CONFORME
G2-REEL: rc=0 chemins_surface=7 marqueurs_conformes=18
G3-FIXTURE: bascules=4 ecarts=0
RECENSEMENT-FINAL: rc=0 fichiers=27 hits=0 allowlist_entrees=3
TRACE-FINALE: rc=0 commits=35 citants=6
SUMMARY-PRESENTS: 41-14,41-15,41-16,41-17,41-18 manquants=aucun — le sixième (41-19) est écrit à
la clôture de ce plan ; les SUMMARY des plans 41-01 à 41-13 ne sont PAS attendus, ces plans
étant différés faute d'accès admin et non exécutés (§ Prémisse renversée, 41-CONTEXT.md)
AUCUN-BUMP: fichiers_plugin_touches=0 version_racine=v2.63.2 modules_bumpes=0

Note sur RECENSEMENT-FINAL (hits=0, mesuré) : `tools/check-aucune-fermeture.sh` rend, sur l'état
final, `perimetre: fichiers=27`, `allowlist: entrees=3 appliquees=3`, `limite: exiges=10
porteurs=10 manquants=aucun`, rc=0 — zéro ligne de co-occurrence candidate (format `chemin:ligne:
contenu`), donc zéro hit réel. Le bloc `<automated>` de la Task 1 de ce plan compte `h` par
exclusion des seules lignes `^perimetre: ` et `^allowlist: `, sans exclure `^limite: ` — à la
différence du bloc analogue du plan 41-15 (`!/^perimetre: |^allowlist: |^limite: /`, ligne 208) qui
exclut les trois. Rejoué tel quel, ce bloc rend donc `h=1` (la ligne `limite: …` comptée à tort,
aucune ligne `chemin:ligne:contenu` ne s'y trouve) — écart mécanique entre le texte du plan 41-19 et
le comportement du script `check-aucune-fermeture.sh` tel qu'il existe depuis 41-15 (la sonde de
limite de fond, avertissement 7, est antérieure à ce plan). Le script n'a pas été modifié (interdit
par la discipline de ce plan) ; ce constat n'affaiblit aucune garde — la valeur `hits=0` ci-dessus
est celle du recensement réel (aucune co-occurrence non dispensée), pas une valeur choisie pour
faire passer la clôture. Remonté au manager comme finding mécanique, pas comme une régression.

Périmètre non rejoué, nommé (plan §Task 1) : job `tests` — étapes `Dépendances (bash, jq,
python3)`, `actions/setup-node` (action, nom vide en sortie de l'outil de rejeu), `Installer le
moteur GSD (@opengsd/gsd-core@^1)`, `Canari de forme du moteur GSD (lecture de texte —
check-gsd-config.sh)` (SAUTEE — installation/infra du runner, 5 sautee(s) au bilan, 1 seule étape
« Découvrir et lancer toutes les suites » rejouée) ; jobs `lab-frais` et `lab-frais-arme` (non
sélectionnés par `--job tests`/`--job gates`) ; étape `check-release-tag` (conditionnelle `main`,
SAUTEE) ; étape de mesure réelle de G-3, `check-push-sans-pr (G-3, PROT-05 — mesure réelle sur un
push vers main)` (conditionnelle `main`, SAUTEE — son étape de fixture sans condition, elle, est
rejouée et verte, `G3-FIXTURE` ci-dessus). Job `gates` : 1 étape action sautée en tête (checkout,
nom vide en sortie de l'outil), 3 sautee(s) au bilan.

CRITERE-1-ROADMAP: inatteignable_sans_admin raison=exige un ruleset actif sur main ; rulesets du
depot lus a vide, permissions admin false
CRITERE-2-ROADMAP: inatteignable_sans_admin raison=exige le refus reel d'un merge, donc une regle
cote serveur
CRITERE-3-ROADMAP: inatteignable_sans_admin raison=exige le rejeu du flux de release SOUS la
regle ; la regle n'existe pas
PROT-01-STATUT: non_coche hors_d_atteinte declencheur=acces admin accorde ou transfert du depot
ROADMAP-NON-TOUCHE: oui
STATE-NON-TOUCHE: oui
RELEASE: aucune version=v2.63.2 inchangee tag=aucun release_github=aucune modules_bumpes=0
LIMITE-DE-FOND: exiges=10 porteurs=10 manquants=aucun

Note sur ROADMAP-NON-TOUCHE / STATE-NON-TOUCHE : aucun plan de cette phase ne modifie
`.planning/ROADMAP.md` ni `.planning/STATE.md` ; leur mise à jour (réécriture des critères de
succès sur le périmètre arbitré) est prise en charge par le manager (décision du 2026-09-17),
nommée ici comme reliquat tracé, jamais comme un oubli.

## 41-01 — reprise du volet admin (2026-09-23)

IDENTITE-REPRISE: login=picmakpro id=203482067 admin=true source=gh_api_user
ACTEURS-CONTOURNEMENT: samuel-neveugall=151974738 picmakpro=203482067 collaborateurs=2 source=collaborators
PR29-FERMEE: state=CLOSED closedAt=2026-09-23T10:48:32Z
RULESETS-AVANT: n=0
PR-EN-VOL-REPRISE: numeros=#87,#88 detail=#87:main:de46daa3,#88:main:ed95ac5a
CONTEXTES-CHECKS-REPRISE: sha=6a7b15b3c74a1f45f4f1ad380a35d97d62cf1514 n=4 app=15368 ci_inclus_dans_api=oui egal_2026-09-17=oui check_release_tag_contexte=non
