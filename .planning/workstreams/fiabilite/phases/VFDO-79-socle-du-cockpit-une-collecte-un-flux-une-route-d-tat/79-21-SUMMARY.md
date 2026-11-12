---
phase: 79
plan: "21"
status: complete
requirements: [SOCL-26]
---

# 79-21 — SUMMARY

AVANT : f5c2e9eb2a0b68cf7fe2ae80dc22a843f28b1be3 (première ligne de 79-21-RED-TRACE.md).

Constantes retenues : MAX_MOTIF = 1024, MAX_PAS = 4194304. Les tailles de familles restent dans le banc de la suite.

## Commits (ordre)

- 85c4b95d test : témoins (équivalence verte, croissance et plafonds rouges sur la base) + 79-21-RED-TRACE.md
- ad29ec96 feat : lib/vf-glob.mjs (neuf), lib/common.mjs (globSource, compileGlob), VENDORED.txt (une ligne AJOUT)
- f7bbb21b test : banc P3 (une série sans bruit suffit), avis hors de la sortie de C3
- 1f1d2eeb test : dix-neuf assertions de mutants GLOB.M-*
- 22ec1691 docs : trace (ancres, mutants, coût ordinaire, pire cas, état final)
- b2361ef7 docs : amendement daté du plan (M-OPT, P3) — message sans le jeton de plan pour ne pas entrer dans files_modified

## Fichiers du moteur touchés (A7, à renvoyer à la session principale avec leur SHA)

- plugin/cockpit/skills/cockpit-moteur/scripts/lib/vf-glob.mjs — ad29ec96 (neuf, 116 lignes)
- plugin/cockpit/skills/cockpit-moteur/scripts/lib/common.mjs — ad29ec96 (283 lignes ; globSource, compileGlob ; git() et sa trace P27 intactes)
- plugin/cockpit/skills/cockpit-moteur/VENDORED.txt — ad29ec96 (AJOUT scripts/lib/vf-glob.mjs, après vf-git-sortant)
- plugin/cockpit/scripts/tests/test-cockpit-confinement.sh — 85c4b95d, f7bbb21b, 1f1d2eeb (section GLOB, aucune suite neuve)
- Aucun site d'appel (build.mjs, refresh.mjs, lib/health.mjs) modifié.

## Coût (limites nommées)

- Ordinaire : médiane des rapports après/avant 6,5 (de 16 à 2 208 ns/appel ; avant 41 à 341). Pas de seuil en CI.
- Pire cas du budget : 17,6 ms par appel (motif de 1 024 caractères, chemin au bord de MAX_PAS).
- Rejeu de la mesure de la Phase 75 : 830,1 ms puis 3 939,3 ms avant ; 4,9 ms puis 6,0 ms après.
- Croissance : cinq familles, rouge sur la base (rapports 7,8 à 16,0 ; plafond dépassé), vertes après ; M-RETOUR rougit F1 et F5 (rapports 5,8 et 13,3).

## Trois comportements définis hors de l'ordinaire

1. Motif de plus de MAX_MOTIF caractères : compile sans lever, ne correspond à rien, un avis d'une ligne sur stderr (au plus 40 caractères du motif).
2. Chemin dont états x (longueur + 1) dépasse MAX_PAS : faux, sans parcours, sans journal.
3. Motif malformé à alternative de niveau supérieur : testeur inerte. Motif qui levait une SyntaxError : la même, à la compilation.

## Pour 79-20 (P79-D-27, aucune documentation ici)

- Ajout nommé : module de correspondance borné (lib/vf-glob.mjs).
- Retrait nommé : la regex comme moteur de correspondance (re.test(p) || under.test(p)) et l'ancienne fonction exportée qui construisait la regex (sans consommateur, remplacée par globSource) ; le découpage du motif entier par le motif de jokers.

## Recouvrement de test-cockpit-confinement.sh avec 79-06

79-06 y avait touché en tâche 4a (commit 862db8ce, deux appels d'export de la page, sections A et G13). Ce plan n'y AJOUTE que la section GLOB et une ligne d'en-tête, avant le bloc final des résultats : hunks disjoints, aucune ligne de 79-06 réécrite. Les tâches 6a et 6b de 79-06 ne nomment pas cette suite.

## Écarts

- M-OPT : le mutant du plan (facultatif devenu itératif) est équivalent sur la seule construction que la traduction émet ; remplacé par « facultatif devenu obligatoire » (amendement b2361ef7).
- P3 : une série sans bruit suffit à voir le quadratique (rouge sous charge à 2,29 constaté, corrigé dans le banc, f7bbb21b).
- Poste : mktemp -d ignore TMPDIR sous macOS ; les rejeux ont tourné derrière une cale hors dépôt pour que la suite range sous le dossier du nœud.

## Audit de sécurité

Non joué ici : le mandat le réserve au manager (audit commandé en direct sur le module de correspondance, l'entrée de compileGlob, l'équivalence, le banc et l'absence de donnée émise).
