# 79-11 — SUMMARY (partiel : lots A et B faits, lot C jusqu'à l'armement exclu)

reprise : tâche 3, étape 6 (armement du cliquet) ; état : tout le code et les suites sont commités et verts ; reste V4c.9 (réel contre la vraie baseline, copie privée d'une ligne, relèvement de 1), `colonnes-cliquet.mjs initialiser plugin/cockpit plugin/cockpit/scripts/tests/colonnes-baseline.txt` APRÈS les commits de code de 79-12, vérification de V4c.7, listes (a) (b) (c) ci-dessous, SUMMARY final. Garde de hausse : une ligne « déléguée » ne couvre jamais une hausse de colonnes-baseline.txt (décision déléguée par Samuel, message session principale, 2026-11-11 : « tranche pour chacun de ces points », prise par la session principale) ; une hausse remonte au manager.

Commits (ordre) : relevé avant, témoins rouges V4c, cliquet V4c (aide, cinq mutants), témoins V11.Q, refactor page de Q, suites alignées, témoins V11.P et T7.5, refactor tiroir et lancement, suites alignées du tiroir (commit suivant). Détail et rouges : 79-11-RED-TRACE.md.

Écarts à P79-D-19 : sous-dossier assets/ui/tiroir/ (build.mjs inline tout ui/*.js de premier niveau) ; fichiers rangés non repliés (dette : le total baisse de 13, voir amendement du plan).
À reprendre par 79-20 : README et CHANGELOG du module : aucun nom retiré cité (à revérifier) ; la règle « un fichier plat de ui/ est dans la page de tous » ; la liste close FICHIERS_NAVIGATEUR (douze fichiers, une ligne AJOUT chacun, 0 ligne de plus de 160 colonnes).
Commentaires résiduels : ui/02-vf-telephone.js (nomme vf-cockpit-terminal-tiroir-style.mjs) et ui/01-vf-responsive.js (nomme le tiroir) : laissés (fichiers chauds de la Phase 80).
Pour 79-16 : le script du tiroir est assets/ui/tiroir/tiroir.js ; client et vue de Q : assets/ui/terminal/.
Proposition : travail de repli séparé des lignes longues.
