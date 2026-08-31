---
name: propager-une-requalification-de-frontiere
description: Quand un arbitrage requalifie une frontière de confiance, propager la requalification à TOUS les plans de la phase — un plan écrit avant garde la rédaction fautive et son gate devient anti-corrélé au risque
metadata:
  type: feedback
---

Quand un arbitrage **requalifie une frontière de confiance** (ex. « frontière de version » → « frontière de code non maîtrisé »), ouvrir un nœud de propagation vers **tous les plans de la phase**, y compris ceux déjà écrits et non encore exécutés. Ne jamais supposer qu'un plan hérite d'une décision prise après sa rédaction.

**Why:** Phase 23. A-6 a requalifié la frontière `moteur résolu → script` et fermé une RCE sur `check-gsd-config.sh`. Le plan 23-04, écrit **avant**, qualifiait la **même** frontière de « frontière de version » — la rédaction que l'arbitrage venait de juger fautive. Personne n'a propagé. Le plan a donc prescrit un générateur qui `require()` un registre résolu depuis le dépôt audité : **la RCE a été réintroduite par un script neuf de la même branche**, chaîne d'install bouclée, `rc=0`. Le threat model de 23-04 était mitigé *à la lettre* et **anti-corrélé au risque réel**. Ce n'était pas une faute du codeur : il a exécuté fidèlement un plan dont la prémisse de sécurité était périmée.

Signal aggravant à reconnaître : **147 assertions vertes, zéro skip, et aucune ne mesurait le risque** — alors que le plan antérieur en avait bâti deux excellentes pour le gate frère, sur le même risque. Un compteur vert sur un périmètre voisin ne transfère rien.

**How to apply:** dès qu'un arbitrage touche une **frontière de confiance**, un **vecteur d'exécution** ou une **cascade de résolution**, ajouter au DAG un nœud de propagation avant tout `exec-*` restant, et vérifier nommément : (1) les sections *Trust Boundaries* de chaque plan non exécuté, (2) l'existence d'une assertion qui mesure le risque **sur chaque script concerné**, pas seulement sur celui qui a été corrigé. Corollaire : quand un correctif de sécurité retire un mécanisme (ici `require()`), inventorier ce que ce mécanisme fournissait **gratuitement** — il protégeait aussi du DoS par FIFO. Voir [[revalider-les-plans-ecrits-avant-les-faits]] et [[artefacts-descriptifs-non-testes]].
