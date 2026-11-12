# 79-02 — trace rouge puis verte (aide commune des suites du cockpit)

AVANT-02 1f4197ced9bd5c4dbe49747c3f53bd9a7363974f

## Mesures de base (aide absente, suites sans la source de l'aide)

- lancements directs hors commentaire, hors test-cockpit-questions.sh : 57 lignes dans 43 suites (par lot : tâche 2 = 20 lignes/16 suites, tâche 3 = 16/15, tâche 4 = 20/11, tâche 1 = 1/1)
- AM7.K3 obtenu sur la base : 43 suites nommées par le détecteur (attendu 0)

## Témoins rouges sur la base (assertion / attendu / obtenu, recopiés de la sortie de test-cockpit-cycle-serveur.sh)

- AM7.S1 — socle-serveur.sh existe, passe bash -n, et ses cinq fonctions sont définies (manquantes : aucune)
  - attendu : [oui aucune]
  - obtenu : [absente  cockpit_lancer cockpit_arreter cockpit_get attendre cockpit_lancement_brut]
- AM7.S2 — cockpit_lancer : rend 0, port > 0, jeton >= 16, pid vivant = pid de server.json, sortie = chemin réel, rien sur stdout, variable héritée vue du serveur
  - attendu : [0 oui oui oui oui oui oui]
  - obtenu : [127 non non non non oui non]
- AM7.S3 — hygiène : vf_hyg_vivants liste VF_PID, PIDS le contient, un seul processus pour la sortie
  - attendu : [1 oui 1]
  - obtenu : [0 non 0]
- AM7.S4 — cockpit_get : /api/vf/etat rend un JSON non vide et VF_CODE=200 ; un chemin inconnu rend VF_CODE=404
  - attendu : [200 json 404]
  - obtenu : [000 nonjson 000]
- AM7.S5 — cockpit_arreter : le serveur marqué est arrêté (VF_PID vidé, absent de PIDS) ET le processus étranger sans la marque survit
  - attendu : [avant=vivant serveur=sorti vide=oui pids=sans etranger=vivant]
  - obtenu : [avant=absent serveur=sorti vide=oui pids=sans etranger=vivant]
- AM7.S6 — attendre : (a) vraie : 0 en moins de 2 s ; (b) jamais vraie, délai 2 s : 1 entre 2 et 4 s ; (c) vraie après 1 s : 0 avant le délai
  - attendu : [ok ok ok]
  - obtenu : [a=127 0 b=127 0 c=127 0]
- AM7.S7 — serveur mort avant d'écouter : retour 1, en moins de 15 s, VF_PID vide, VF_PORT=0, journal non vide
  - attendu : [1 oui oui 0 oui]
  - obtenu : [127 oui oui 0 non]
- AM7.S8 — hygiène non initialisée (bash enfant) : retour 2 et aucun processus de la sortie (ps + awk)
  - attendu : [2 0]
  - obtenu : [127 0]
- AM7.S9 — sortie hors de la marque de la suite : retour 3 et rien lancé (ps + awk)
  - attendu : [3 0]
  - obtenu : [127 0]
- AM7.S10 — mutant am7:pids (inscription à PIDS retirée) : seule la clé inscrit change (oui -> non), l'aide intacte donne les trois clés attendues
  - attendu : [inscrit=oui invisible=3 stale=ignoré | different valide inscrit=non invisible=3 stale=ignoré]
  - obtenu : [aide absente | aide absente]
- AM7.S11 — mutant am7:visible (refus hors marque retiré) : seule la clé invisible change (3 -> 0), le serveur lancé hors marque est arrêté par la suite
  - attendu : [different valide inscrit=oui invisible=0 stale=ignoré]
  - obtenu : [aide absente]
- AM7.S12 — mutant am7:stale (effacement et contrôle du pid retirés) : seule la clé stale change (ignoré -> suivi)
  - attendu : [different valide inscrit=oui invisible=3 stale=suivi]
  - obtenu : [aide absente]
- AM7.K1 — le détecteur nomme les trois formes brutes (node, $NODE avec arguments, --import) et ignore le commentaire ; il voit une ligne dans test-cockpit-questions.sh (pas aveugle)
  - attendu : [3 voit]
  - obtenu : [0 aveugle]
- AM7.K2 — copie de test-cockpit-assemblage.sh (migrée) : intacte non nommée, augmentée d'une ligne de lancement brute nommée
  - attendu : [intacte=0 augmentee=1]
  - obtenu : [intacte=0 augmentee=0]
- AM7.K3 — aucune suite hors exceptions ne lance le serveur à la main (suites nommées par le détecteur ; base : 43)
  - attendu : [0]
  - obtenu : [43]

Note : AM7.S5 rougit sur la base parce que son témoin d'existence du serveur (avant=vivant) manque ; H3.16 à H3.18 (suite existante, durées d'inactivité) sont des rouges de charge observés à la base, rejouables seuls : hors plan, signalés.

## Zones relevées sur AVANT-02 (plages de lignes d'AVANT-02 : en-tête, blocs de lancement)

ZONES plugin/cockpit/scripts/tests/test-cockpit-assemblage.sh 1-14 73-77
ZONES plugin/cockpit/scripts/tests/test-cockpit-direct-coupe.sh 1-20 33-40
ZONES plugin/cockpit/scripts/tests/test-cockpit-flux-unique.sh 1-19 32-39
ZONES plugin/cockpit/scripts/tests/test-cockpit-fr-donnees.sh 1-20 33-40
ZONES plugin/cockpit/scripts/tests/test-cockpit-reconnexion.sh 1-15 29-37
ZONES plugin/cockpit/scripts/tests/test-cockpit-accessibilite.sh 1-20 60-65
ZONES plugin/cockpit/scripts/tests/test-cockpit-moteur-carte.sh 1-29 74-79
ZONES plugin/cockpit/scripts/tests/test-cockpit-responsive.sh 1-24 78-84 471-475 784-787
ZONES plugin/cockpit/scripts/tests/test-cockpit-robustesse.sh 1-14 40-43
ZONES plugin/cockpit/scripts/tests/test-cockpit-securite.sh 1-15 92-98 386-386
ZONES plugin/cockpit/scripts/tests/test-cockpit-who.sh 1-13 348-353
ZONES plugin/cockpit/scripts/tests/test-cockpit-marque-blanche.sh 1-17 73-77
ZONES plugin/cockpit/scripts/tests/test-cockpit-direct.sh 1-18 94-101
ZONES plugin/cockpit/scripts/tests/test-cockpit-git.sh 1-19 25-25 182-185
ZONES plugin/cockpit/scripts/tests/test-cockpit-git-details.sh 1-22 26-26 123-126
ZONES plugin/cockpit/scripts/tests/test-cockpit-serveur.sh 1-20 86-89 316-319
ZONES plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh 240-241 252-256
ZONES plugin/cockpit/scripts/tests/test-cockpit-lancer-bout-en-bout.sh 1-27 126-135
ZONES plugin/cockpit/scripts/tests/test-cockpit-lancer-chat.sh 1-19 428-437
ZONES plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh 1-23 595-605 609-618@79-05 738-744@79-05
ZONES plugin/cockpit/scripts/tests/test-cockpit-lancer-serveur.sh 1-24 195-204
ZONES plugin/cockpit/scripts/tests/test-cockpit-lancer-xss.sh 1-31 254-259 433-438
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-activation.sh 1-21 58-67
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-client.sh 1-23 476-483
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-fin.sh 1-19 56-62
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-page.sh 1-23 122-131
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-pty.sh 1-21 128-134
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-serveur.sh 1-22 76-85
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-session.sh 1-23 76-82
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh 1-34 819-827
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-xss.sh 1-24 131-136
ZONES plugin/cockpit/scripts/tests/test-cockpit-terminal-xterm.sh 1-28 543-550
ZONES plugin/cockpit/scripts/tests/test-cockpit-chaine-xss.sh 1-33 132-135 229-232 294-297
ZONES plugin/cockpit/scripts/tests/test-cockpit-demander-bornes.sh 1-16 80-83
ZONES plugin/cockpit/scripts/tests/test-cockpit-equipe.sh 1-25 325-328 431-434 885-888
ZONES plugin/cockpit/scripts/tests/test-cockpit-git-e2e.sh 1-29 132-135
ZONES plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh 1-20 72-75 569-572 580-583
ZONES plugin/cockpit/scripts/tests/test-cockpit-git-signature.sh 1-21 116-118
ZONES plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh 1-24 83-86 425-428
ZONES plugin/cockpit/scripts/tests/test-cockpit-path-enfants.sh 1-22 159-162
ZONES plugin/cockpit/scripts/tests/test-cockpit-reseau.sh 1-17 115-118
ZONES plugin/cockpit/scripts/tests/test-cockpit-transcript.sh 1-21 338-341

## Trace verte (instantané de HEAD 730416dc)

- test-cockpit-cycle-serveur.sh en entier : 62 PASS / 0 FAIL ; AM7.S1 à S12, K1, K2 verts ; AM7.K3 obtenu 0 (la classe est fermée).
- décroissance de K3 : 43 (base) -> 42 (tâche 1) -> 26 (+ lot A) -> 11 (+ lot B partiel) -> 0 ; le détecteur voit encore 1 ligne dans test-cockpit-questions.sh (exception, 79-01/79-06).
- suites qui appellent cockpit_lancer : 43 ; lancements directs hors questions : 0 (base : 57).
- périmètre des commits (test, feat, refactor) du plan : 45 chemins ; assertions modifiées dans les suites migrées : 0.
- zones : hunks AVANT-02..HEAD hors zones = 0 pour les commits de 79-02 ; les 4 hunks hors zone vus sur la plage (fr-donnees, git-details, git-signature) viennent des commits d'autres plans b16c57fc, 730416dc, c8a009df ; git-tiroir : aucune ligne D2.1, D7, D8.1, D9.1 touchée.
- rouges de charge constatés (base comme migré, rejoués seuls verts ou identiques) : securite FB3.5, git S6.1, git-details X6.2, who W24.3/W24.4, responsive (cas variable), terminal-tiroir TH.9/TH.14/T21.13, H3.16-H3.18 de cycle-serveur.
