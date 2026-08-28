---
name: non-regression-sur-la-decouverte-complete
description: Mes mandats de non-régression ne rejouaient que les suites des fichiers édités — une régression dans un AUTRE module a traversé 6 revues et 4 vérifications sans être vue
metadata:
  type: feedback
---

Tout mandat de non-régression fait rejouer la **découverte COMPLÈTE** des suites, jamais seulement
celles des fichiers touchés par le lot.

**Why:** mesuré Phase 31 (2026-08-16). Pendant toute la mission j'ai fait vérifier **trois** suites
(`test-manifest`, `test-merge-hooks`, `test-vibeflow-update`) — celles des fichiers édités — alors que
la CI en découvre **62**. Un refactor dans `plugin/_internal/vibeflow-update.sh` a cassé
`plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` (24/24 au commit de base →
23/24 au HEAD), parce que cette suite **sonde le texte source de l'engine** avec une fenêtre
positionnelle (`grep -A8`) qu'une branche insérée a repoussée hors champ.

La régression a traversé **six revues et quatre vérifications** sans être vue : chaque juge héritait
du périmètre de mon mandat. Elle n'a été trouvée que parce qu'un worker a lancé, **de sa propre
initiative**, une découverte plus large que ce que je demandais.

C'est le mode d'échec que j'imposais aux autres — « qu'est-ce que ce vert ne prouve pas ? » —
appliqué à **mon propre instrument** : « les suites des fichiers édités passent » se lit comme
« rien n'a régressé », et ce n'est pas la même affirmation.

**How to apply:**
1. Dans **tout** mandat (exécution, correction, revue, vérification) : « lance la découverte
   complète, rapporte le nombre de suites en échec **avant** et **après** ». Un chiffre, pas une
   impression.
2. **Le bon pattern est celui de la CI**, pas un `find` plus large :
   `find plugin scripts -type f -path '*/tests/test-*.sh'` → **62**. Un `find . -name 'test-*.sh'`
   rend **124** parce qu'il ramasse `.claude/worktrees/<module>/`, qui est un **second checkout du
   même dépôt** (doublons), et `.planning/milestones/` (archives). C'est ce qui a produit un faux
   comptage de « 76 suites » — et failli faire « corriger » un compteur de README qui était juste.
3. **Suspecter en priorité les suites qui sondent du TEXTE SOURCE** d'un autre module (`grep -A<n>`
   sur un fichier voisin) : elles cassent sur une **insertion de ligne**, sans que le comportement
   change. Elles sont fragiles par construction — voir [[artefacts-descriptifs-non-testes]].
4. Le coût est réel (la découverte complète dépasse 2 min en avant-plan ici) : la lancer **en
   arrière-plan** et relever le résultat, plutôt que de rétrécir le périmètre pour tenir dans le
   temps imparti.

⚠️ **Le remède a son propre angle mort : `git archive` rend l'ARBRE commité, pas le DÉPÔT commité.**
Mesuré dans la même campagne : `scripts/tests/test-check-machine-paths.sh` **échoue** dans un extrait
`git archive` (pas de `.git`) et **passe 19/19 dans le vrai dépôt** — ce gate interroge les fichiers
**versionnés** via git. J'ai failli reporter « 2 échecs dont 1 pré-existant » là où la réalité est
**1 seul échec**, l'autre étant un artefact de ma propre méthode.
**How to apply:** toute suite qui interroge **git** (fichiers suivis, historique, tags, statut) doit
être rejouée **dans le dépôt réel**, pas dans un extrait. Quand une suite échoue sous `git archive`,
**la rejouer en place avant de conclure** — et distinguer trois cas, jamais deux : régression /
pré-existant / **artefact de mesure**.

Voir [[preuve-du-chemin-heureux-ne-couvre-pas-l-echec]] (même famille : une preuve solide sur un
périmètre trop étroit) et [[liste-de-cas-ne-ferme-pas-une-classe]].
