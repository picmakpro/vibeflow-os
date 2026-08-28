---
name: multicondition-guard-mutate-each
description: quand une garde documente N conditions cumulatives, muter CHACUNE isolément — un compte de commentaires ou une suite verte ne prouve rien par condition
metadata:
  type: feedback
---

Une garde à N conditions cumulatives (ex. les six conditions de suppression D-31-07,
31-05/vf_converge_apply) n'est prouvée QUE si CHAQUE condition, retirée seule (neutralisée en
no-op), fait rougir au moins un test. Un critère d'acceptation qui compte des lignes de commentaire
`# (a)`..`# (f)` ne prouve JAMAIS l'implémentation — seule la mutation le fait.

**Découverte (31-05, revue en direct)** : sur les six conditions, seules (a) et (b) étaient
prouvées nécessaires (T18 + sa mutation rouge tracée en SUMMARY). (c) exists-on-disk, (d)
fichier-régulier, (e) résout-sous-TARGET_ROOT et (f) hors-exclusions étaient TOUTES mutant-mortes
— neutraliser chacune séparément laissait la suite `test-manifest.sh` à 46 OK / 0 KO. (d) est la
plus grave : c'est la défense PRINCIPALE contre T-31-04 (suppression de masse via une ligne
résolvant vers un répertoire, sévérité "high" au threat model), et elle n'était protégée par AUCUN
test discriminant.

**Why** : c'est exactement la leçon que D-31-12 avait déjà tirée sur `vf_manifest_excluded` (T5
vacant → T5b ajouté au grain unité) et que le SUMMARY de 31-05 lui-même redécouvre pour (b) via
T18 — mais l'exécutant n'a PAS généralisé la discipline aux quatre autres conditions du même bloc.
Une assertion qui ne peut pas échouer est pire qu'une assertion absente : elle compte dans un N/N
vert et fait croire que la propriété est tenue.

**How to apply** : dès qu'un plan/du code introduit une garde à conditions cumulatives listées
(a)/(b)/(c)... — avant de valider la suite comme preuve, muter (neutraliser en `:`) CHAQUE
condition une par une dans une copie jetable, rejouer la suite, noter si elle reste verte. Prioriser
la condition dont le threat model dit "high severity" ou "défense principale" — c'est celle qui
coûte le plus cher si elle est morte. Voir aussi [[project_symlink-ancestor-bypasses-target-root-check]].
