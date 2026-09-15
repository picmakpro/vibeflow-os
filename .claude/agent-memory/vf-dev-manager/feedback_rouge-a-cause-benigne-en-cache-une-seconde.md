---
name: rouge-a-cause-benigne-en-cache-une-seconde
description: Quand un worker explique un gate rouge par un « faux positif », exiger l'ÉNUMÉRATION des causes du rouge, pas une cause — et vérifier soi-même la forme littérale des lignes que des sondes lisent en aval
metadata:
  type: feedback
---

Un worker qui rend un gate rouge accompagné d'une explication plausible (« faux positif connu »)
a presque toujours arrêté de chercher à la première cause trouvée. Exiger qu'il **énumère** les
causes du rouge et prouve qu'il n'en reste aucune autre — et re-jouer soi-même la sonde.

**Why:** Phase 34, 2026-09-15, plan 34-01. Le bloc `<automated>` de deux tâches rendait exit 1. Le
worker l'a attribué **exclusivement** à un faux positif réel et vérifiable : la sonde scannait tout
`.maestro/` pour `clearState|clearKeychain` et tombait sur le `README.md` du dossier, qui cite ces
motifs en prose **pour les proscrire**. J'ai confirmé ce faux positif indépendamment (10 flows
`.yaml` propres, 2 occurrences en prose, aucun résidu de mutant). Mais le rouge avait une **seconde
cause indépendante** : la note écrivait ses verdicts en gras Markdown — `**PIPELINE: VERT**` — alors
que la sonde exige `^PIPELINE: (VERT|ROUGE)$`. Zéro occurrence au format attendu. Or ces deux lignes
sont la **précondition MACHINE** du plan aval (34-04) : la trace d'un run reporté aurait été
illisible par la machine censée la reprendre plus tard. L'explication bénigne, vraie, a servi de
couverture à un défaut structurel — sans aucune intention de tromper.

**How to apply:**
1. « Le rouge vient de X » n'est jamais accepté seul. Demander : *combien* de causes, et la preuve
   qu'il n'en reste pas. Un worker qui a vérifié saura répondre ; un worker qui s'est arrêté à la
   première non.
2. Le **gras Markdown casse toute sonde ancrée en début de ligne**. Chaque fois qu'un plan pose une
   ligne littérale (`PIPELINE:`, `SHA de base :`, `UDID retenu :`, `> **Statut** : …`) destinée à
   être lue par une sonde ou un plan aval, la vérifier soi-même en `node`/`awk` ancré — jamais via
   un `grep` piped, qui tronque sur ce poste.
3. Une exception de gate doit porter sur la **forme de la sonde**, jamais sur la **propriété**
   mesurée (cf. [[exception-de-gate-devient-exemption]]). L'entrée de déviation nomme la sonde, le
   fichier, les lignes, et le résultat de la re-vérification scopée — pour que le lecteur refasse le
   raisonnement sans croire l'auteur sur parole.
4. Correction ciblée = **cumulative** : faire exister la forme littérale SANS supprimer la prose qui
   la justifie, et sans casser les lignes déjà conformes (cf. [[mandat-cumulatif-jamais-exclusif]]).

Voir [[mesure-juste-attribution-fausse]] (même famille : le relevé est juste, l'attribution est
fausse) et [[artefacts-descriptifs-non-testes]].
