---
name: plancheck-qui-diverge-remonter-la-portee
description: Six plan-checks de suite, chacun trouve un nouveau chemin sur le même objet : arrêter à 3, remonter la PORTÉE à l'humain, pas un 7e correctif
metadata:
  type: feedback
---

Quand deux ou trois plan-checks frais successifs trouvent chacun un nouveau défaut sur le MÊME objet
(et que chaque correction ajoute un mécanisme), ce n'est plus un défaut de plan : c'est une garantie
impossible à tenir telle que la décision l'a formulée. Remonter la portée à l'humain, ne pas
commander un tour de plus.

**Why:** Phase 47 (2026-10-12) — la « règle miroir au recalcul de G2′ pour une clôture faite par
Bash » a coûté six tours (~2,3 M jetons de révisions et de checks) : inventaire de départ, sceau,
période, exemption, fenêtre avant registre, test génératif. Cause de fond : un gate qui dépend d'un
HISTORIQUE (G2′) ne se rend pas complet contre un écrivain invisible (Bash, P45-D-10), alors qu'un
gate fonction pure du disque (G3) le peut. Exiger « propriété + preuve générative » au tour 5 n'a
pas suffi : le tour 6 a trouvé 3 bloquants dans le test génératif lui-même.

**How to apply:** au 2ᵉ tour qui retombe sur le même objet, se demander « la garantie dépend-elle
d'un historique qu'un acteur invisible peut réécrire ? ». Si oui, poser la question de portée
(détection au mieux bornée à l'outil / continuer / sortir de la phase) avec le coût par tour, et
geler le plan concerné ; corriger en attendant seulement ce qui est indépendant. Prolonge
[[liste-de-cas-ne-ferme-pas-une-classe]] et [[correctif-de-securite-differentiel-a-n-versions]].
