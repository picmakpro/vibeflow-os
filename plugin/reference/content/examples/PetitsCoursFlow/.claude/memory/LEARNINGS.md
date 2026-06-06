# LEARNINGS - Apprentissages capitalises de PetitsCoursFlow

> Patterns observes sur >= 2 cas, generalises en regle reutilisable.

## Index

| ID | Titre | Date | Sources |
|----|-------|------|---------|
| LRN-001 | Au-dela de 28 eleves recurrents, qualite chute | 2026-01-10 | Trim S2-25 + Trim S3-25 |
| LRN-007 | Adultes debutants en groupe = decrochage systematique | 2026-04-15 | Ateliers janv-mars 2026, PDR-004 |
| LRN-008 | Newsletters racontant un decrochage genere x3 d'engagement | 2026-03-22 | Newsletters 2026-W08 + W11 |
| LRN-012 | Parents demandant remise = signal pedagogique fragile | 2026-04-02 | Cas A + Cas B (anonymises) |

---

## LRN-007 - Adultes debutants en groupe = decrochage systematique

**Date** : 2026-04-15
**Sources** : 4 ateliers groupes (janv-mars 2026), PDR-004

### Contexte

Sophie a accueilli 3 adultes vrais debutants en atelier groupe sur 4 ateliers. Les 3 ont eu une experience negative a des degres divers.

### Observation

Les adultes vrais debutants en groupe :
- Ont besoin d'un rythme 3x plus lent que celui que peut soutenir un groupe de niveau intermediaire
- Vivent l'ecart de niveau comme un echec personnel (pas comme un fait technique)
- Decrochent en moyenne en 2-3 seances
- Generent une charge cognitive permanente sur le prof (qui doit "veiller" sur eux pendant qu'il anime le groupe)
- Cassent la dynamique des autres eleves (qui ressentent le ralentissement)

### Regle generalisable

**Pour tout format pedagogique en groupe : verifier que tous les participants ont un niveau minimum partage**. Sous le seuil minimum, le format individuel est strictement superieur - meme economiquement, parce que la perte de qualite et la friction de gestion couvrent la marge "groupe".

S'applique a :
- Ateliers groupes (cas direct ici)
- Cours collectifs en general (a verifier sur d'autres formats)
- Stages multi-niveaux (proposition : separer les niveaux meme si reduit la rentabilite par stage)

### Mecanisme d'execution

L'agent `student-qualifier` doit detecter le signal "adulte debutant + demande groupe" et le rediriger en format individuel automatiquement. Voir PDR-004.

---

## LRN-008 - Les newsletters racontant un decrochage genere x3 d'engagement

**Date** : 2026-03-22
**Sources** : Newsletter 2026-W08 (decrochage Marc) + Newsletter 2026-W11 (decrochage adolescente)

### Contexte

Sophie a publie 2 newsletters racontant des decrochages anonymises (avec autorisation des parents et anonymisation totale) :
- W08 : "Pourquoi le pere de famille de 45 ans a arrete au bout de 4 mois - et pourquoi j'ai rate quelque chose"
- W11 : "L'ado de 15 ans qui n'avait pas envie de revenir - et la conversation qui a tout debloque"

Resultat :
- W08 : 32 % d'open rate (vs 19 % moyenne) + 18 reponses (vs 3 moyenne)
- W11 : 35 % open + 22 reponses

### Observation

Les newsletters qui racontent un **echec ou un risque d'echec assume**, suivi d'une lecon, generent :
- Un open rate 1.6 a 1.8x superieur a la moyenne
- Un nombre de reponses 6-7x superieur a la moyenne
- Plusieurs "merci pour votre honnetete" - signal de confiance

A l'inverse, les newsletters "succes story" pure ont un engagement moyen.

### Regle generalisable

**Le contenu pedagogique qui assume un raté avec lucidite genere plus d'engagement que le contenu qui ne montre que des succes.** L'audience credite l'honnetete + apprend mieux d'un cas raté que d'un cas reussi (le pourquoi est plus visible quand quelque chose a casse).

Condition d'application stricte :
- Anonymisation totale (regle `eleves-confidentialite`)
- Autorisation prealable du parent / eleve concerne (sauf si > 6 mois et anonymisation rendue parfaite)
- L'echec doit etre assume, pas victimise (Sophie reconnait sa part)

### Mecanique

L'agent `editor-music` doit, sur tout brouillon "succes story uniquement", suggerer une variante "succes raconté avec un raté assumé en cours de route" - c'est statistiquement superieur en engagement.

---

## LRN-012 - Parent demandant remise = signal pedagogique fragile

**Date** : 2026-04-02
**Sources** : Cas A (parent X anonymise, dec 2025) + Cas B (parent Y anonymise, mars 2026)

### Contexte

Deux cas distincts ou un parent a demande une remise des l'inscription :
- Cas A : "Vous etes plus chere que la prof du quartier, vous pouvez aligner ?" - Sophie a refuse poliment, le parent est parti
- Cas B : "On vient de Paris, c'etait moins cher la-bas, vous adapter ?" - Sophie a refuse, le parent a accepte au plein tarif... puis a demande systematiquement des "petites ouvertures" sur les seances manquees, les retards, etc.

### Observation

Un parent qui demande une remise des l'inscription :
- Cas A : part - perte d'1 prospect, OK
- Cas B : reste - mais devient "parent a friction" sur tous les autres sujets pendant le trimestre suivant

### Regle generalisable

**La negociation tarifaire avant l'engagement est un signal qu'il y aura une negociation a chaque etape de la relation pedagogique.** Le refus poli avant l'engagement est moins couteux que la friction recurrente apres l'engagement.

Application via PDR-003 (pas de remise) - mais avec une regle complementaire : *si le parent insiste apres un refus poli, NO-GO meme si le parent finit par accepter le plein tarif*. La friction post-engagement est plus chere que le prospect perdu.

### Mecanique

A integrer dans `student-qualifier` : ajouter un check "le prospect a-t-il negocie le prix au moment du premier contact ?" - si oui ET insistance apres refus : NO-GO meme a plein tarif.
