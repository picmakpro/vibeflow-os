---
name: existence-au-lieu-de-relation
description: Test décisif pour auditer une assertion de recette — peut-on AJOUTER une clause qui dit l'inverse, sans rien retirer, et rester vert ? Si oui, l'assertion est existentielle
metadata:
  type: feedback
---

Une assertion qui prétend garantir un **lien** (tel énoncé ↔ telle qualification, telle branche ↔
tel mode, telle clé ↔ telle position, tel seuil ↔ telle borne) mais qui se satisfait de la
présence d'un token *quelque part* ne verrouille rien. **Test décisif** : peut-on **AJOUTER** une
clause qui dit l'inverse, **sans rien retirer**, et rester vert ? Si oui, l'assertion est
existentielle et doit être remontée en RELATION.

**Why:** ce défaut s'est reproduit cinq fois sur la seule Phase 23 de vibeflow-os, dont une fois
**anti-corrélé** au risque annoncé (le gate punissait la forme licite et laissait passer la
fautive). À chaque fois la recette était verte : c'est le vert qui a autorisé à livrer. Un gate
existentiel est plus dangereux qu'une absence de gate, parce qu'il fait croire à une couverture.

**How to apply:**

- Signaux qui doivent déclencher l'audit : un libellé qui promet « ligne enrichie », « rattaché à »,
  « apparié », « déclencheurs de », « dans l'allowlist », « encadré » — alors que le code fait
  N `grep -q` indépendants sur le fichier entier.
- Formes de remontée en relation, par ordre de robustesse : chaînage de greps sur le **même flux**
  (`grep A f | grep B | grep -q C`) pour une même ligne physique · co-occurrence **dans le même
  bloc** (`md_blocks_matching`) pour une énumération · **segment** d'un statut (t24_segment_of)
  pour une entrée de mapping · **fenêtre d'adjacence** en caractères pour un ordre imposé ·
  **égalité d'ensemble** (comm) pour un « exactement …, rien d'autre ».
- Le contrôle positif doit **conserver tous les tokens** : relocaliser, permuter, scinder,
  disperser — jamais supprimer. Vérifier ET imprimer que la forme faible serait restée verte sur
  le mutant : c'est la moitié du cas qui prouve que le durcissement sert à quelque chose.
- Second membre de la famille : la **tautologie assumée en commentaire** et le **vert à vide**.
  Un balayage qui compte les *fichiers ouverts* ne dit rien des *cibles mesurées* — border tout
  balayage d'un compteur d'atteinte (« ≥ N cibles effectivement vues »), en assertion **séparée**.

Voir [[mutation-test-discriminating-cases]] (comment prouver le rouge), [[libelles-ok-geles]]
(durcir sans réécrire le libellé) et [[gate-jamais-de-repli]] (KO explicite plutôt que repli).
