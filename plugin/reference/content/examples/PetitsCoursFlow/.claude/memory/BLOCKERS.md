# BLOCKERS - Frictions documentees de PetitsCoursFlow

> Toute friction qui a coute > 30 min de Sophie K.

## Index

| ID | Titre | Statut | Date | Cout |
|----|-------|--------|------|------|
| BLK-003 | Re-explication du contexte a chaque session avec l'IA | Resolu | 2026-01-15 | 4h cumulees |
| BLK-008 | Reproches recurrents sur "le rythme du groupe" en atelier | Resolu | 2026-04-15 | 6h cumulees + reputation |

---

## BLK-008 - Reproches recurrents sur "le rythme du groupe" en atelier

**Date** : 2026-04-15
**Statut** : Resolu (PDR-004)
**Cout cumule** : ~6 heures de Sophie + 540 EUR remboursement + 3 reviews tiedes

### Symptomes

Sur 4 ateliers groupes consecutifs (janv-mars 2026), Sophie a recu des retours du type :
- "Le rythme etait trop rapide pour moi"
- "Je me suis sentie a la traine, j'ai eu honte"
- "Je n'ai pas progresse, j'aurais du prendre des cours individuels"

Ces retours venaient TOUS d'adultes vrais debutants (3 cas sur 4).

### Hypotheses eliminees

- **H1 : C'est un probleme de pedagogie generale** -> rejete : les eleves intermediaires des memes ateliers etaient satisfaits
- **H2 : C'est un probleme de communication preparatoire** -> rejete : Sophie avait bien specifie "atelier non-debutant" en amont, mais les adultes s'auto-evaluent souvent au-dessus de leur niveau reel
- **H3 : C'est un probleme de format** -> CONFIRME : un atelier groupe ne peut pas absorber un vrai debutant sans casser la dynamique

### Cause racine

L'auto-evaluation d'un adulte debutant est systematiquement optimiste (LRN-007 confirme). Les criteres de selection a l'inscription ne suffisent pas - il faut un filtre actif (refus du format collectif, redirection vers individuel).

### Solution

PDR-004 (refus systematique adultes debutants en collectif). Implemente via l'agent `student-qualifier` qui detecte le signal "adulte + debutant + demande atelier groupe" et redirige automatiquement.

### Verification post-resolution

A revoir au prochain audit (mai 2026) : le redressement de la regle a-t-il fait baisser le nombre de plaintes ?
