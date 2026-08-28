---
name: re-mesurer-la-premisse-d-un-arbitrage
description: Re-mesurer sur disque la prémisse factuelle d'un arbitrage humain avant de l'appliquer — un arbitrage peut reprendre une affirmation que la mission a elle-même déjà démentie
metadata:
  type: feedback
---

Avant d'exécuter un arbitrage humain qui **nomme un fait vérifiable** (un fichier porte tel défaut, deux mécanismes sont équivalents, telle branche est morte), **re-mesurer ce fait sur disque**. Si la mesure le dément, **scinder l'arbitrage** : exécuter la moitié mesurée vraie, **geler et remonter** la moitié démentie. Ne jamais l'appliquer à la lettre « parce que c'est tranché ».

**Why:** Phase 23, A-10. L'arbitrage prescrivait de retirer une branche de cascade morte « des **deux** cascades, `mission-flow.md` portant le même défaut ». Or le nœud `verif-o12` de la mission avait **déjà mesuré et consigné dans HANDOFF** que cette extension à `mission-flow.md` était fausse — l'arbitrage reprenait mot pour mot une affirmation antérieure démentie entre-temps. Mesure de contrôle : `mission-flow.md` porte **0 occurrence** de `gsd-core` sur 288 lignes, et la « branche 2 » de sa cascade `$S` est `$HOME/.claude/scripts` — **vivante, documentée**, et seule voie de résolution d'un lab en scope user. L'appliquer à la lettre aurait supprimé une garantie vivante pour retirer un code mort : un correctif qui ouvre un défaut, exactement le mode d'échec que la phase existe pour fermer. La forme correcte du geste était mesurable : le motif fautif n'existait que dans **un** script de production et **un** test.

Le contexte aggravant à reconnaître : c'était la **cinquième** prémisse fausse d'affilée sur cette phase (A-1, A-1bis, A-1ter, le motif d'A-13, puis A-10). Quand une phase accumule les prémisses fausses, la re-mesure cesse d'être une précaution et devient la procédure par défaut.

**How to apply:** à la reprise d'une mission sur arbitrages, lire d'abord les **mesures déjà consignées** (HANDOFF, nœuds de vérification `done`) et les confronter au texte des arbitrages **avant** de composer le moindre mandat — les contradictions y sont visibles sans rien exécuter. Puis, pour tout geste de **suppression**, exiger la mesure du périmètre exact (`awk` sur l'arbre, jamais `grep` proxifié) avant de le déclarer dans un mandat. Le refus de suppression est le défaut sûr : remonter coûte un aller-retour, supprimer une garantie vivante coûte une régression. Voir [[propager-une-requalification-de-frontiere]] et [[mandat-cumulatif-jamais-exclusif]].
