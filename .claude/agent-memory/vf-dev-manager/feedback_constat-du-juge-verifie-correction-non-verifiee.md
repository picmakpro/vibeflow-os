---
name: constat-du-juge-verifie-correction-non-verifiee
description: Un juge (plan-checker, reviewer) livre un CONSTAT mesuré et une CORRECTION non mesurée — relayer le constat et la propriété requise, jamais la commande suggérée telle quelle
metadata:
  type: feedback
---

Dans le rapport d'un juge, deux choses de statut très différent voyagent ensemble : le **constat**
(mesuré, souvent avec la commande et la sortie) et la **correction suggérée** (écrite de tête,
jamais exécutée). Relayer la seconde comme si elle avait le statut de la première propage une
erreur avec l'autorité du juge.

**Relaie le constat + la PROPRIÉTÉ REQUISE, et laisse la route au worker** — il a le banc de test
sous la main, le juge ne l'avait pas.

**Why:** Phase 40, 2026-09-15. Le plan-checker relève, à juste titre, qu'un garde d'additivité
`grep -c '^-[^-]'` est aveugle à la suppression d'une **ligne vide** (mesuré, exact : la ligne
supprimée se réduit au seul caractère `-`), alors que le découpage en blocs du test se fait
précisément **par ligne vide**. Constat juste et coûteux à trouver. Sa correction — « `^-[^-]` →
`^-` » — je l'ai relayée **verbatim dans le mandat**. Elle est fausse : `^-` matche aussi la ligne
d'en-tête `--- a/…` de tout diff unifié, donc le garde serait devenu **rouge en permanence**, y
compris sur un ajout pur. Le worker l'a testée, a mesuré les trois cas, a **dévié avec preuve**
(`tail -n +5 | grep -c '^-'` : 0 sur ajout pur, 1 sur ligne vide supprimée, 1 sur texte supprimé)
et a documenté la déviation. Sans ce réflexe, j'aurais fait livrer un garde inerte-par-l'autre-bout
en croyant appliquer une correction validée.

**How to apply:** dans un mandat de correction, écris « **propriété requise** : … (la route est ton
choix) » — c'est la forme que j'utilisais déjà pour les constats que je jugeais délicats, il faut
l'appliquer à **tous**. Si tu cites quand même la commande du juge, marque-la explicitement
« piste non vérifiée, mesure-la avant de la figer ». Et quand un worker dévie **avec mesure**, c'est
un succès du protocole, pas une désobéissance : consigne la déviation et sa preuve.

Corollaire symétrique : un juge peut aussi **prescrire correctement et mesurer faux**. Ne jamais
accepter d'un juge un chiffre sans la commande qui l'a produit — voir
[[descripteur-gsd-core-non-probant]] et [[ecart-de-chiffre-comparer-les-ensembles]].
