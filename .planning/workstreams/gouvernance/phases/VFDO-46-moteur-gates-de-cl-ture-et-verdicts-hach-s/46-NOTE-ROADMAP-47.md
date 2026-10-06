# Note ROADMAP de la Phase 47 — texte prêt (P46-D-19)

**Origine :** plan 46-02, décision P46-D-19 (décision du manager de mission, annoncée à Willy en
session principale le 2026-10-03, renversable). Ce fichier ne modifie pas `ROADMAP.md` : il livre le
texte exact que le manager pose à la main.

## (a) Cible

- Fichier : `.planning/workstreams/gouvernance/ROADMAP.md`
- Section : `### Phase 47: Moteur — baux générationnels et jeton monotone`
- Ligne visée, citée textuellement telle qu'elle est lue à l'exécution du plan 46-02 (l. 288 du
  fichier à cette date) :

```
**Depends on:** Phase 46 (G2′ se branche sur le même événement `TaskCompleted` que G3/G4 ; il vit ici parce qu'il consomme le bail).
```

Constat à l'exécution : la ligne suivante de la section (l. 289) porte déjà une
« Note du cadrage de la 46 (P46-D-19, 2026-10-03) » de même sens. Le remplacement ci-dessous
supersede cette ligne : si le manager garde la l. 289, il ne pose que le remplacement de la ligne
`**Depends on:**` (première des deux lignes ci-dessous) ; sinon, il remplace la l. 288 par les deux
lignes et retire la l. 289, pour ne pas dire deux fois la même chose.

## (b) Texte de remplacement prêt

Ligne `**Depends on:**` (garde « Phase 46 » et « il vit ici parce qu'il consomme le bail », retire la
parenthèse sur l'événement partagé) :

```
**Depends on:** Phase 46 (il vit ici parce qu'il consomme le bail).
```

Ligne ajoutée juste après :

```
**Note du 2026-10-03 (P46-D-19) :** « G2′ se branche sur le même événement que G3/G4 » n'est plus vrai — la Phase 46 porte G3 et G4 en PreToolUse sur l'écriture de CLOTURE.md et de SUMMARY.md et n'utilise pas l'événement de mise à jour de tâche (P46-D-01, Willy, AskUserQuestion session principale, 2026-10-03). Le point d'accroche de G2′ se re-décide au cadrage de la Phase 47.
```

## (c) Geste

À poser à la main par le manager (jamais `roadmap.*` ni `state.*`), dans un commit de planning sans
release (ADR-073 : planning seul, aucune release avant la clôture de `fiabilite-v1.0`).
