# PDR - Registre des decisions pedagogiques (Pedagogical Decision Records)

> Toute decision pedagogique structurante de PetitsCoursFlow.
> Format derive du BDR/ADR canonique (Pattern 02).

---

## Index

| ID | Titre | Statut | Date | Revision |
|----|-------|--------|------|----------|
| PDR-001 | Perimetre eleves : ages 7-18 + adultes intermediaires | Active | 2025-09-10 | 2026-12-10 |
| PDR-002 | 3 formats uniquement : individuel + atelier + stage | Active | 2025-09-10 | 2026-12-10 |
| PDR-003 | Pas de remise sur les tarifs annonces | Active | 2025-09-15 | 2026-12-15 |
| PDR-004 | Refus systematique adultes debutants en cours collectif | Active | 2026-04-15 | 2026-07-15 |
| PDR-005 | Preparation concours - minimum 6 mois | Active | 2026-02-20 | 2026-08-20 |
| PDR-006 | Retours brouillons - 48h minimum | Active | 2026-03-12 | 2026-09-12 |

---

## PDR-004 - Refus systematique des adultes debutants en cours collectif

**Date** : 2026-04-15
**Statut** : Active
**Revision prevue** : 2026-07-15

### Contexte

Sur les 4 derniers ateliers groupes (12 eleves au total), 3 etaient des adultes vrais debutants :
- 2 ont decroche apres 2 seances (frustration : ne suivent pas le rythme du groupe)
- 1 a demande un remboursement apres 3 seances
- Cout : 540 EUR de remboursement + 6 heures perdues a re-essayer la pedagogie + reputation aupres des autres eleves du groupe (qui ont ressenti la dynamique cassee)

### Options envisagees

- **A** : Continuer comme avant (acceptation tous niveaux dans les ateliers groupes)
- **B** : Creer un atelier "groupe debutants adultes" en parallele (2 niveaux distincts)
- **C** : Refuser systematiquement les adultes debutants dans les ateliers groupes, rediriger vers cours individuel

### Decision prise

Option C. Les ateliers groupes supposent un minimum de lecture rythmique et un repertoire commun. Un adulte debutant casse la dynamique pour les 4 autres, sans benefice pour lui-meme.

L'option B (deux niveaux) demanderait 2x plus de creneaux pour 4 ateliers/an - pas rentable a cette frequence.

### Consequences attendues

- -3 a -5 prospects/an (acceptable)
- +30 % de retention en groupe (estime, base sur le ressenti des 4 eleves restants)
- Necessite : un script de redirection "atelier groupe pas adapte aux vrais debutants - voici pourquoi - voila le format individuel qui te convient"

### Mecanique d'execution

L'agent `student-qualifier` lit cette PDR + LRN-007 (signal "adulte debutant") + PDR-002 (formats) avant de qualifier tout prospect adulte. Si signal debutant + demande atelier collectif : NO-GO atelier + GO individuel.

### Revision prevue

2026-07-15. Verifier sur les ateliers de mai/juin/juillet :
- Combien de prospects rediriges
- Combien acceptent le format individuel
- Engagement des 4 eleves "groupe non-debutants" : a-t-il vraiment monte ?

---

## PDR-005 - Preparation concours - minimum 6 mois d'engagement

**Date** : 2026-02-20
**Statut** : Active
**Revision prevue** : 2026-08-20

### Contexte

Demande recurrente de parents : "Mon enfant a un concours d'entree dans 3 mois, peux-tu le preparer en express ?"

Sophie a accepte 2 fois dans le passe (avant l'OS) :
- Cas 1 : eleve recale - parent decu - reputation
- Cas 2 : eleve admis "in extremis" - mais retour sec : "il est entre tendu, je ne suis pas sur que ce soit un service que je rendrais a un autre parent"

### Options envisagees

- **A** : Accepter cas par cas selon niveau initial
- **B** : Refuser systematiquement sous 6 mois
- **C** : Refuser sous 6 mois, sauf si l'eleve est deja chez Sophie depuis >= 1 an

### Decision prise

Option C. L'eleve recurrent depuis 1+ an a deja la base technique et la complicite pedagogique. Un parachute prepa concours sur un eleve nouveau est une promesse intenable - meme si l'admission a lieu, le couple "stress + dette pedagogique" est destructeur.

### Consequences attendues

- Refus de 2-4 demandes/an de prepa express
- Possibilite de refus calme : "ce n'est pas honnete pour ton enfant"
- Peut creer une bonne reputation locale (le prof qui ne dit pas oui a tout)

### Revision prevue

2026-08-20.
