---
name: filtre-de-verification-fabrique-l-angle-mort
description: Ne jamais filtrer la commande qui SERT de preuve (git status | grep -v ...) — le filtre devient l'angle mort du rapport ; filtrer l'affichage, jamais la mesure
metadata:
  type: feedback
---

Quand une commande sert de **preuve** pour un rapport (« arbre propre », « aucune suite rouge »,
« rien à commiter »), la lancer **nue**. Un `| grep -v`, un `| head`, un `--porcelain` restreint à
un pathspec : chacun retire du champ exactement ce qu'on ne regarde plus — donc exactement ce qui
manquera au rapport. Filtrer pour **lire confortablement** est légitime ; filtrer la commande dont
on **tire la conclusion** ne l'est pas.

**Why:** en clôture de Phase 38, j'ai vérifié la propreté de l'arbre avec
`git status | rtk proxy grep -v agent-memory` — un filtre que j'avais ajouté moi-même pour réduire
le bruit. J'ai rapporté « arbre propre ». Trois fichiers de mémoire `vf-reviewer` étaient non
commités. Samuel l'a constaté en rejouant l'état de son côté et les a commités lui-même (`cf1e29b`),
avec le retour : *« l'arbre n'était pas propre, contrairement au rapport »*. Le défaut n'était pas
dans l'outil — pour une fois — mais dans **ma** restriction du champ de mesure. C'est la même
famille que [[grep-proxifie-tronque]] et [[ls-proxifie-rend-vide]], à ceci près que là, la
troncature était volontaire et la mienne : aucun outil ne pouvait m'avertir.

**How to apply:** à toute clôture et tout rapport d'état — `git status --porcelain` **sans pipe**,
`git diff --stat` sur l'ensemble, la suite de tests sur la **découverte complète**
([[non-regression-sur-la-decouverte-complete]]). Si la sortie nue est trop longue, la lire en deux
temps (compter d'abord, détailler ensuite), jamais l'amputer en amont. Et quand un rapport affirme
« propre / vert / rien », se demander *quelle commande a produit ce mot, et avec quel filtre* —
c'est la seule question qui rattrape cette erreur, parce que le résultat filtré est indiscernable
d'un vrai vert. Corollaire déjà payé ailleurs : un chiffre **recopié** d'un relevé antérieur au
lieu d'être remesuré tombe pareil ([[attestation-sur-sha-fige]]) — 88 commits rapportés pour 90
réels, dans cette même clôture.
