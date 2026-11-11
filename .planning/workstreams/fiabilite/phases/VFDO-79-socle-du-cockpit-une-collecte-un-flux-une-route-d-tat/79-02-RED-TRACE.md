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
