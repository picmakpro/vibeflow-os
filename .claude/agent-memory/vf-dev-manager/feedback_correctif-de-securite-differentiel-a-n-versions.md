---
name: correctif-de-securite-differentiel-a-n-versions
description: Un correctif de sécurité sur une normalisation de chemin rouvre une variante voisine ; exiger dès le premier tour un différentiel contre TOUTES les versions antérieures
metadata:
  type: feedback
---

Sur le hook central de la Phase 45 (audit final 2026-10-01 → 2026-10-02), quatre tours de
correction d'affilée ont porté sur la même classe : « une valeur que le hook ne sait pas analyser
fait taire les gates ». Chaque tour a fermé son vecteur et ouvert le suivant :
- F-01 : la borne de 4096 caractères ;
- N-01 : la décision prise sur le cwd ;
- N2-01 : le nom échappé ;
- N3-01 : la régression de l'aiguillage.
Le tour 4 n'a convergé (SECURED) qu'avec deux exigences :
- un différentiel à TROIS versions (avant le 1er correctif, version précédente, nouvelle), avec la
  propriété « aucun cas refusé par une version antérieure ne passe » ;
- une preuve générative (2 000 valeurs et plus).

**Why:** une batterie de cas ne ferme pas une classe (voir [[liste-de-cas-ne-ferme-pas-une-classe]]),
et un correctif qui rajoute un aiguillage peut perdre une analyse exacte que l'ancien code faisait.
Seul le différentiel contre la version d'AVANT le premier correctif l'a montré.

**How to apply:**
- Dès le 2e défaut sur une même normalisation, le mandat exige trois choses : (1) le différentiel
  à N versions, avec un décompte par catégorie ; (2) la preuve générative ; (3) la décision
  explicite « dernier tour de code, tout résidu sera déclaré ».
- Ne pas relancer un audit complet à chaque tour : un ré-audit ciblé sur le diff, avec la règle
  « seul un HIGH rouvre du code », borne la boucle.
