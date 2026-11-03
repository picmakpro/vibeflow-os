---
name: byte-threshold-accents-and-prompt-anchor-tests
description: Phase 59 revue-59 - un seuil de longueur en octets (LC_ALL=C) laisse passer les placeholders FR accentues ; les tests d'ancres de prompt ne discriminent pas la semantique
metadata:
  type: feedback
---

Sur un script awk sous `LC_ALL=C`, un seuil « au moins N caracteres non blancs » compte des OCTETS : « à définir » (10 octets) passe un seuil de 10 alors que « a definir » (8) rougit. A sonder sur tout gate de texte francais (check-prd.sh, Phase 59).

**Why:** l'eliminatoire « exigence sans critere d'acceptation » est le coeur du juge prd-gate ; le placeholder FR naturel passe en vert (reproduit, rc 0).

**How to apply:**
- Fabriquer des entrees avec accents et placeholders FR (« à définir », « à préciser ») avant de croire un filtre TBD/TODO.
- Muter aussi les comportements documentes en en-tete mais non testes (TODO mot entier, TBD du BRIEF, fermeture d'item sur ligne blanche / sous-puce, `tr -d '\r'`) : 5 survivants sur 9 mutants a la revue-59. Le strip CR ne se prouve que sur un BRIEF CRLF a rubrique vide (la sonde CRLF existante ne couvre que REQUIREMENTS).
- Un test de prompt par « ancre presente » (T44, PTB-JUGE « ≥ 80 ») survit a l'inversion de semantique et a un seuil change sur UNE des lignes ; le sweep qui ablate toutes les occurrences masque ce cas. Muter une seule occurrence / inverser la clause en gardant les ancres.
- `rtk diff` imprime « Files are identical » a tort : utiliser `rtk proxy diff`.
