---
name: durcir-un-gate-touche-fixtures-et-messages
description: Rendre un champ obligatoire dans un gate de frontmatter casse toutes les fixtures « conformes » des suites voisines ET rend menteurs les messages qui décrivaient le champ comme optionnel.
metadata:
  type: feedback
---

Passer un champ de « validé s'il est présent » à « exigé » a trois ondes de choc, pas une. Mesuré
le 2026-08-04 sur `plugin/conductor/scripts/check-agents.sh` (champ `effort:`) : le plan ne
prévoyait que la première.

1. **Les fixtures de la suite du gate** : 36 KO d'un coup. Toute fixture censée être *conforme*
   doit porter le nouveau champ, sinon les cas mesurent le mauvais objet.
2. **Les suites VOISINES** qui consomment le gate. Ici `test-guard-agent-write.sh` — sa fixture
   `CONFORME` partait en `deny`. Les suites de module (`test-<module>.sh`, T3) passaient déjà
   parce que les vrais agents avaient été corrigés d'abord.
3. **Les MESSAGES qui décrivent le champ.** `guard-agent-write.sh` annonçait
   `effort: <optionnel>` dans son squelette de refus : il refusait donc une écriture pour
   l'absence d'un champ que son propre message déclarait optionnel.

**Why:** l'onde 3 est la plus coûteuse et la seule qu'aucun test rouge ne signale — tout est vert
et le message est faux. Un refus qui désigne mal sa cause fait corriger tout SAUF elle : l'auteur
relit son frontmatter, voit « optionnel », et cherche ailleurs.

**How to apply:** avant de durcir, balaie les **trois** populations — fixtures de la suite,
consommateurs du gate (`awk` sur `*/tests/*.sh` et les hooks), et **textes** qui qualifient le
champ (`optionnel`, `recommandé`, `facultatif`) dans les scripts, squelettes et références. Les
deux dernières familles tombent hors du `files_modified` du plan : les corriger quand même et
**déclarer la déviation** dans le commit et le rapport. Poser une garde sur le message corrigé
(exiger la nouvelle forme ET l'absence de l'ancienne) — sinon il redérive au prochain passage.
Voisin utile : [[feedback_retirer-un-gate-ouvre-les-exceptions-voisines]], même famille en sens
inverse.
