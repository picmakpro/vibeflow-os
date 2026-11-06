---
phase: 72
plan: 03
status: complete
requirements: [LANC-04, LANC-08]
---

# 72-03 — cibles lançables et pré-vols : résumé

Preuve du rouge puis des mutants : `72-03-RED-TRACE.md` (même dossier).

## Commits

| SHA | Objet |
|-----|-------|
| `b75074ef` | test : témoins rouges (1 PASS, le témoin PAR.0 / 50 FAIL sur la base) |
| `c746a81b` | docs : trace du rouge |
| `6e9f5f94`, `6ae76755` | test : trois attendus erronés corrigés avant tout code (`null` interpolé, identifiant de C5), rien d'affaibli |
| `fdb6de06` | feat : identité des cartes, action principale, projection fermée pour Q |
| `17805635` | docs : trace des mutants des cibles |
| `46930e1c` | feat : bloquants, avertissements, réserve inactive, lecteurs défaillants |
| `329a0d47` | docs : trace des mutants des pré-vols |

## Exports (interface pour 72-09), `plugin/cockpit/scripts/vf-cockpit-lancer-cibles.mjs` (117 lignes)

`BLOQUANTS` (neuf codes, `premier-plan-occupe` compris, jamais calculé ici), `AVERTISSEMENTS` (quatre), `AVERTISSEMENTS_RESERVES` (`travail-non-commite`, inactif : son lecteur n'est jamais appelé), `RECENCE_MS`, `actionPrincipale(avancement, fichiersPhase)`, `calculerCibles(lecteurs)`, `listePourQ(cibles, gabarit)`, `verdict(cibles, id, verbe)`. Le plan citait aussi `ID_CIBLE` parmi les constantes de référence ; il ne figure pas dans la liste des exports de l'artefact et rien ne l'exige : non exporté (la validation du nom de mission se fait par `ID_RE` de `vf-cockpit-lecture.mjs`).

- **`RECENCE_MS` = 900000** (15 minutes), constante unique que 72-07 et 72-09 reprennent. Un lancement est « récent » si son âge est compris entre 0 inclus et `RECENCE_MS` exclu ; un lancement daté du futur est ignoré.
- **Forme de l'objet `gabarit` injecté** : `{ MOTIF_PHASE, MOTIF_COMPARTIMENT, VERBES }`. Les motifs sont lus comme `RegExp` ou comme chaîne (`new RegExp(m.source ?? m)`) ; longueurs plafonnées à 16 (phase) et 40 (compartiment) ; `VERBES` est un tableau ordonné de cinq verbes. La parité avec l'export réel du plan 72-01 n'est pas prouvée ici (même vague) : à prouver par la suite de 72-09.
- **Lecteurs** (fonctions sans argument sauf `fichiers`) : `planning()` -> `{ phases: Map|tableau, dags }` (sortie de `readPlanning`), `fichiers(phase)` reçoit l'OBJET phase du planning (pas sa clé : il porte `key`, `n`, `ws`) et rend les noms du dossier de phase, `lancements()` -> `[{ cible, verbe, at }]`, `terminal()` -> `actif|arrete|indisponible`, `claude()`, `python3()` booléens, `maintenant()` -> millisecondes. Un lecteur qui lève vaut absent ; le planning qui lève ou de forme inattendue rend `{ cibles: [], contexte.planning: false }`.
- **Phases archivées** : cible présente, `principal` null, bloquant `phase-finie`, donc exclue de la projection pour Q (principal absent). Une phase cochée ou d'état `fait` est traitée de même.
- **Ordre des cibles** : phases par numéro puis compartiment, missions ensuite par nom. Une mission d'une phase finie ou hors motif hérite de ses bloquants.

## Écarts avec le plan

1. **Compartiment hostile `Fiabilite`** : remplacé par `Alpha` dans le lab partitionné de PAR. Sur APFS, `Fiabilite` et `fiabilite` sont le même dossier : le second ROADMAP écrasait le premier (PAR.0 l'a détecté, voir la trace). Le motif reste exercé avec `Fiabilite` en littéral (C5, B).
2. **`listePourQ` exclut aussi une carte dont les bloquants portent `phase-hors-motif` ou `compartiment-hors-motif`** (ajout de garde, non prévu par le texte du plan). Sans cela, un compartiment hostile devient `ws: null`, indiscernable d'un lab plat : Q proposerait un lancement sans compartiment, dans le mauvais. Prouvé par PAR.2 (`q90`) et Q2 ; le mutant M-HORS-MOTIF-FUITE les rougit.
3. **`verdict` livré avec la Tâche 2** (le plan le prévoyait en Tâche 3) : C0 exige les huit noms et la commande `cibles` doit être verte.
4. **Sondes rouges en plus des sondes exigées** pour certains mutants (consignées dans la trace) : légitimes, ces sondes lisent aussi les identifiants, principaux ou bloquants.
5. Un identifiant de carte phase garde le numéro du ROADMAP tel quel (parité avec `buildProjectGraph`) ; un numéro réel est toujours numérique (regex du ROADMAP). Le compartiment n'entre dans l'identifiant que si le numéro existe dans deux compartiments : un nom hostile ne peut y figurer que dans ce cas, et `listePourQ` exclut alors la carte (identifiant recalculé à partir de valeurs validées).

## Vérifications

Voir la section « Non-régression » ci-dessous.

## Non-régression

Aucun fichier existant n'est modifié (fichiers neufs seulement). Suites rejouées parce qu'elles balayent les `vf-cockpit-*.mjs` ou le dossier des scripts :
`test-cockpit-assemblage.sh` 40 PASS / 0 FAIL, `test-cockpit-marque-blanche.sh` 30 / 0, `test-cockpit-forme-claude.sh` 56 / 0 (bash, rc 0). `test-cockpit-projet.sh` : NON CONCLUANT, deux rejeux interrompus par l'échéance (280 s puis 560 s) sous une charge de 27 (autres codeurs en parallèle) ; sa seule assertion qui voit un nouveau fichier du dossier (P4.8, aucun `vf-cockpit-*.mjs` ne contient `fiabilite` ni `gouvernance`) est contrôlée à la main : `grep` sur le module, aucune occurrence. À rejouer par le manager hors charge.
Suite neuve : `bash …/test-cockpit-lancer-cibles.sh` 51 PASS / 0 FAIL (bash et zsh) ; `cibles` 21 / 0 ; `previols` 30 / 0.
Gates : `check-file-size.sh` rc 0 (117 lignes) ; `check-machine-paths.sh` rc 0 ; `check-version-sync.sh` rouge sur le seul compte de suites des README (167 contre 175 réels, dû à toutes les suites neuves de la phase, attendu jusqu'au plan 72-15). Module pur (awk du plan) : `OK-MODULE-PUR`. `Gate-Touche` : non requis (aucun fichier de ce plan dans les six classes de `check-gate-touche.sh`).
