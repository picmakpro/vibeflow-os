colonnes-depart=13
lignes-depart=123

# 74-02 — trace du rouge (section T24D38 de test-cockpit-transcript.sh)

Précondition : constatée par `grep reduireCible` et la présence de `vf-cockpit-agents-table.mjs` (79-13 et 79-22 fusionnés dans la base) ; la précondition « Phase 79 entière » est remplacée par les prérequis réels (régime allégé).

Relevé sur la base fusionnée : T24G2 (mesure des appels à `realpath` par `cnt.mjs`, réécrite par 79-13) et T24H1 à T24H8 (cibles de `reduireCible`) sont verts avant tout changement ; ce plan n'y touche pas.

Sondes rouges sur le code de la base : T24D38.1, .3, .4, .5, .6 (obtenu : aucun `echec` ; .3 donne « 2|2|3 » : le second appel absorbe le premier).
Gardes déjà vertes (non-régression seulement, leurs mutants prouvent qu'elles savent rougir) : T24D38.2 (M-CONTENU), .7 (M-PREFILTRE, compteur de JSON.parse), .8 (aucun mutant au plan).
Mutants .9a à .9f : « MUTANT VIDE » avant le code (les motifs visés n'existent pas encore), joués à la tâche 2.
Écart : .7 ne vérifie pas l'`echec` (il est prouvé par .1) pour rester vert avant le changement, comme le plan le demande.

Rouges hors périmètre vus sur ce même run : T24F4.1 (2 120 ms contre un seuil de 2 000, charge du poste) et T27.B2 (sélection sur equipe.html) : connus, non corrigés.
