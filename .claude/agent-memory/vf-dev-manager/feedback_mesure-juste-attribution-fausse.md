---
name: mesure-juste-attribution-fausse
description: Une mesure exacte peut être attribuée au mauvais objet et engendrer un poste de travail fantôme — le rejet `[a-z0-9_]+` de Codex portait sur le task_name, pas sur le nom de rôle
metadata:
  type: feedback
---

Quand une mesure produit une **contrainte**, exiger que le rapport nomme **sur QUEL OBJET** elle
porte, vérifié par une variation contrôlée — pas seulement le message d'erreur verbatim.

**Why:** mesuré Phase 38 (2026-08-28). La Phase 37 avait relevé, verbatim et en exécution réelle,
`agent_name must use only lowercase letters, digits, and underscores`, avec **3 rejets mesurés**.
Elle en a conclu que les 31 identifiants VibeFlow, tous à tirets, étaient « concernés **par
construction** » et qu'un **adaptateur de nommage** était requis. Le relevé était **juste**.
L'attribution était **fausse** : la contrainte porte sur le `task_name` du spawn (qui devient un
segment de chemin `/root/<task_name>`), **pas** sur le nom de rôle. Un rôle nommé `vf-reviewer` se
charge sans warning, figure dans l'enum `agent_type` et tourne réellement. Le coût évité :
une table de 31 correspondances + sa maintenance, remplacée par **une normalisation d'une ligne**.

C'est un mode d'échec **distinct** du chiffre faux, et plus difficile à voir : rien dans le rapport
n'était inexact, la mesure était reproductible, et le raisonnement « par construction » avait
l'apparence de la rigueur. Le message d'erreur ne dit pas quel **champ** l'a déclenché — c'est
l'appelant qui le sait, et c'est précisément ce que personne n'avait re-vérifié.

**How to apply:**
1. Une contrainte mesurée n'est acquise que si le rapport dit **quel champ** l'a déclenchée, prouvé
   par une **variation contrôlée** : faire passer la valeur fautive par l'autre champ candidat et
   montrer qu'elle passe. Sinon → `[inféré]`, jamais `[mesuré]`.
2. Se méfier de « X est concerné **par construction** » : la formule saute l'étape de vérification
   en la déguisant en déduction. C'est le marqueur linguistique de ce défaut.
3. Un poste de travail entier justifié par UNE contrainte mérite une re-mesure ciblée **avant**
   d'être planifié — le coût de la sonde est sans commune mesure avec celui du poste.
4. Corollaire heureux : re-mesurer peut **réduire** le périmètre. Ne pas ne re-vérifier que les
   contraintes gênantes.

Voir [[descripteur-gsd-core-non-probant]] (un rouge rédigé et argumenté peut être faux) et
[[ecart-de-chiffre-comparer-les-ensembles]] (la définition de l'objet compté tranche le désaccord).
