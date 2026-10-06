---
phase: quick-261006-aw0
plan: 01
quick_id: 261006-aw0
workstream: gouvernance
status: complete
base: 1cbe7fd4
head: 18188d96
commits:
  - 18188d96  # NFD ext4 — ligne moteur d'un verdict hachée sous le nom du disque (clé NFC), R-BANC-NFD à verdicts égaux sur un système sensible
---

# Quick 261006-aw0 — tour 3 du lot A, Phase 46 (fix-46-a) : NFD sur FS sensible à la normalisation (ext4)

Fait suite à 261006-23m et 261006-638. Origine : REM-7 confirmé rouge sur la CI Linux (run 37417355421, sur 1cbe7fd4) : R-BANC-NFD « 31 ligne(s) NFC, 29 disque NFD » ; MUT-NFD-CHEMIN, MUT-READDIR-NFC, MUT-RECENCE-NFC « NON TUÉ » (témoin déjà rouge). STATE.md et ROADMAP.md non touchés. Non poussé.

## Diagnostic (T1, aucun fichier du dépôt touché) — VERDICT : LES DEUX

- **Simulation fidèle** (scratchpad, préfixe `fix46a-t3-nfd-` : faux python3 en tête du PATH, résolution composant par composant, jumeaux NFC/NFD émulés par alias ; hors dépôt, aucun mode de simulation permanent) : sur le code de 1cbe7fd4 elle retrouve exactement la CI : test-cloture-gates.sh 69 OK · 4 KO, message « 31 / 29 », trois NON TUÉ ; d1 (35), empreintes (49), env_statique et banc : mêmes statuts et lignes `~` que la CI.
- **Attente de test aveugle au FS (H-T confirmée)** : `materialiser_disque_nfd` sautait la pose des verdicts `03-jugé` et `04-échoué` sur le disque NFD (poser-verdict.sh rc=64, livrable stocké NFD alors que `ecrit:` le déclare NFC) : le journal D1 de ce disque n'avait pas les deux lignes `moteur` (31 vs 29 = 29 + 2). La docstring du tour 2 (« --unite lue en NFC ») était inexacte.
- **Défaut de PRODUCTION (H-C confirmée)** : `inscrire_ecriture_moteur(racine, unite_rel + "/VERDICT.md")` de poser-verdict.sh joignait `racine` et une clé NFC : sur ext4, dans une unité au nom disque NFD, le fichier est introuvable, la ligne `moteur` est perdue et FileChanged trace ensuite un contournement à tort. Site unique (18 sites recensés dans les notes, ligne par ligne). Corriger le test seul ne suffisait pas : le « 31 / 29 » restait, nommant les deux lignes `moteur`.
- Le code de D1 (`_sous_dossiers`, `reconcilier`, chemins surveillés) fait son I/O sur le nom disque : correct.

## Correction (T2) — 18188d96

- **Code** : poser-verdict.sh hache le VERDICT.md sous son nom de disque et inscrit la ligne `moteur` sous la clé NFC (règle : forme et clé en NFC, I/O sur le nom brut).
- **Test** : R-BANC-NFD pose les mêmes verdicts sur les deux disques et compare le journal de D1 en entier ; aucune ligne `moteur` retirée, aucune assertion convertie en `~`.
- **Nouveau** : R-D1-18 et MUT-D1-MOTEUR-NFD (test-d1-surveillance.sh ; « non applicable ici » sous APFS) ; limite (bf) de modele-cycles.md complétée.
- Rouge avant : rejeu sous simulation « 31 / 29 » ; branche test seule : rouge persistant avec « NFC seul : moteur …/03-jugé/VERDICT.md, …/04-échoué/VERDICT.md » ; R-D1-18 rouge (contournement tracé à tort).
- Vert après : test-cloture-gates.sh 73 OK · 0 KO sous simulation ET sous APFS ; test-d1-surveillance.sh 37 OK · 0 KO (les deux) ; test-cloture-empreintes.sh 49 OK (les deux) ; gates env_statique 3 OK, banc 231 OK sous simulation, 497 OK entier sous APFS. MUT-NFD-CHEMIN, MUT-READDIR-NFC, MUT-RECENCE-NFC tués pour leur raison (leur témoin passe) sous simulation et sous APFS ; MUT-D1-MOTEUR-NFD tué sous simulation.

## Non-régression (T3, APFS, HEAD final)

Tout rc 0, 0 KO : planning-gates 497 ; planning-hook-registered 113 ; rejeu-gates 100 ; recalc-planning 405 ; g4p-sortie-brute 19 ; juges-canary 14 ; planning-hook-installed 29 ; hook-exit-parc 42 ; planning-prefilter (table, bornes, corpus, evenements) 14. Marqueurs Gate-Touche 3/3 ; check-machine-paths propre. Lignes `~` conservées telles quelles (R-BANC-NFD G3/G4, R-NFD-GATES, R-D1-15, R-EMP-13 (c)).

## Écarts et points non fermés

- Deux suites lancées dans le même message (donc en parallèle) alors que le mandat dit séquentiel ; vertes, rejouées séquentiellement avant le commit. Charge machine externe jusqu'à 14,5 ; aucune clause de durée n'a rougi.
- **La preuve sur ext4 réel est la CI Linux sur ce commit** : la simulation reste une émulation (REM-10 : ni couche shell, ni casse d'ext4, ni noms non UTF-8, jumeaux par alias).
- REM-8 : G1, G3, G4 lisent l'unité en forme NFC (limite (bf) : refus, jamais passage) ; G7 (planning-hook.sh ~1965 et ~2037) est de la même famille, fail-closed, non nommé par (bf) et non rouge sous la simulation : hors tour 3, à remonter.
- REM-9 : `~ R-EMP-13 (c)` reste une ligne `~` (convertir en assertion serait un élargissement).

## Vérification

`261006-aw0-VERIFICATION.md` : status passed, 4/4, aucun trou réel. Preuve que le correctif n'est pas décoratif : le seul appel corrigé rétabli dans une copie du scratchpad fait rougir R-BANC-NFD (31 / 29) sous simulation. Rejeu indépendant : cloture-gates 73, d1 37, empreintes 49 sous APFS ; cloture-gates 73 et d1 37 sous simulation. Observation : R-D1-18 est vert sous APFS même avec l'ancien code (il ne détecte le défaut que sur un FS sensible : simulation ou CI Linux).
