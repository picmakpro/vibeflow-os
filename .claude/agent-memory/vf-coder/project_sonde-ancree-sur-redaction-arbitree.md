---
name: sonde-ancree-sur-redaction-arbitree
description: Une sonde dont l'ancre est une rédaction sous arbitrage ouvert doit passer par fixtures injectées, jamais par mutation du fichier réel
metadata:
  type: project
---

Quand la doctrine visée par un gate est **elle-même sous arbitrage remonté à l'humain** (fichier
`*-ARBITRAGES-OUVERTS.md`), le contrôle positif du gate se construit par **fixtures injectées** en
fin de fichier cible — jamais par mutation d'une phrase réelle qui pourrait disparaître.

**Why:** Phase 23 (VibeFlow, plan 23-01, nœud B5). Le renvoi de `vf-dev-manager.md` paraphrasait la
table de pilotage ; la question « cette paraphrase a-t-elle le droit d'exister, ou le renvoi doit-il
se réduire à un pointeur nu ? » était ouverte (§O-1). Une sonde ancrée sur la paraphrase serait
devenue **no-op** le jour où le pointeur nu l'emporte — et le garde `cmp -s` aurait alors produit un
faux ROUGE sur une réécriture parfaitement licite. Le correctif doit être valable dans les DEUX
issues de l'arbitrage.

**How to apply:** sépare les deux propriétés. (1) La doctrine réelle est couverte par le **balayage**
(le fichier est dans les cibles : s'il s'inverse, le gate rougit) — rien à ancrer. (2) La capacité de
l'**outil** à lire une graphie se prouve par fixtures injectées, cible par cible. Ajoute en plus un
**compteur d'atteinte** : une garde négative (« aucune clause fautive ») est verte aussi bien quand
la doctrine est saine que quand les motifs ne voient plus rien — compter les clauses effectivement
vues distingue les deux. Cf. [[feedback_gate-jamais-de-repli]] et
[[feedback_mutation-test-discriminating-cases]].

Corollaire de méthode, avant tout élargissement de motif : rejoue le balayage des cibles **ancien
motif contre nouveau**, et liste les occurrences nouvellement capturées une par une. Un
élargissement qui n'est pas diffé ainsi déplace le risque de l'aveuglement vers le faux rouge.
