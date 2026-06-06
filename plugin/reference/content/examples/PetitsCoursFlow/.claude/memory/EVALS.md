# EVALS - Audit qualite cognitive des agents PetitsCoursFlow

> Mesure la fiabilite des outputs IA. Detecte les hallucinations.

## Index

| ID | Agent | Date | Cas testes | Hallucinations | Verdict |
|----|-------|------|------------|----------------|---------|
| EVAL-001 | student-qualifier | 2026-03-18 | 5 | 1 / 5 | Confiance moyenne |
| EVAL-002 | editor-music | 2026-04-10 | 4 | 0 / 4 | Confiance haute |

---

## EVAL-001 - student-qualifier

**Date** : 2026-03-18
**Cas testes** : 5 cas (3 standards + 2 piegeux)
**Hallucinations detectees** : 1 / 5

### Cas standards (3)

1. Enfant 9 ans, niveau debutant, parent motive -> agent a propose cours individuel + diagnostic 30 min - CORRECT
2. Ado 14 ans, 3 ans de piano, prepa concours dans 4 mois -> agent a refuse (PDR-005, < 6 mois) - CORRECT
3. Adulte 40 ans, intermediaire, demande atelier groupe -> agent a accepte - CORRECT

### Cas piegeux (2)

4. **PIEGE** : Adulte 35 ans, "j'ai fait du piano enfant pendant 2 ans, ca remonte a 25 ans, je suis pret a reprendre en collectif" -> agent a HALLUCINE et a propose atelier groupe.
   **Probleme** : "remonte a 25 ans" + "2 ans enfant" = redebutant fonctionnel. L'agent n'a pas applique la regle "vrai debutant -> individuel" car le prospect a affirme un faux niveau.
   **Correction** : ajout d'une heuristique dans student-qualifier : "si retour piano apres > 5 ans d'inactivite, traiter comme debutant pour les regles d'orientation format".

5. **PIEGE** : Parent qui dit "mon enfant prepare l'audition en juin" mais sans preciser les details du concours -> agent a propose la preparation sans verifier que la preparation depassait 6 mois.
   **CORRECT** : l'agent a en fait demande la date du concours et la duree de preparation envisagee avant de decider. Pas d'hallucination.

### Verdict

Confiance moyenne. 1 hallucination sur 5 (taux 20 %). Correction appliquee post-audit. A re-auditer en mai 2026.

### Action

- Heuristique "retour apres inactivite > 5 ans" ajoutee au prompt de student-qualifier
- Re-audit prevu mai 2026 avec 5 nouveaux cas piegeux

---

## EVAL-002 - editor-music

**Date** : 2026-04-10
**Cas testes** : 4 brouillons newsletter (2 valides + 2 a refuser selon les 3 piliers)
**Hallucinations** : 0 / 4

### Cas

1. Brouillon "comment choisir son piano numerique" -> editor a refuse (hors piliers : conseil materiel) - CORRECT
2. Brouillon "le ressenti de Marc en cours" (anonymise) -> editor a valide (pilier 1 : progression pedagogique) - CORRECT
3. Brouillon "ma rencontre avec un pianiste de jazz" -> editor a valide (pilier 2 : repertoire et culture) - CORRECT
4. Brouillon "comment gerer la motivation des ados" -> editor a valide (pilier 3 : conseils parents) - CORRECT

### Verdict

Confiance haute. 0 hallucination sur 4. A re-auditer dans 3 mois ou si la ligne editoriale evolue.
