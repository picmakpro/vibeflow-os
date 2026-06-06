# CLAUDE.md - PetitsCoursFlow (OS Sophie K.)

> Version : v1.0
> Derniere mise a jour : 2026-04-25
> Proprietaire : Sophie K., professeure de piano (PERSONNAGE FICTIF DEMONSTRATIF)

---

## 1. Contexte

Sophie K., 34 ans, Lyon. Professeure de piano et solfege depuis 6 ans. CRR de Lyon, ancienne pianiste accompagnatrice. Active sur 3 fronts :

- **Cours individuels** : 25 eleves recurrents (enfants 7-12 ans, ados, 4 adultes)
- **Ateliers groupes** : 1 a 2 par mois (decouverte solfege, 4 mains, etc.)
- **Newsletter** : 850 abonnes, 2-3 contenus pedagogiques par semaine

Capacite max : 28 eleves recurrents (au-dela, qualite chute observee). Objectif : maintenir 25 eleves de qualite + densifier l'audience newsletter pour ouvrir un futur format en ligne.

### Pourquoi cet OS existe

Avant PetitsCoursFlow, Sophie perdait entre deux trimestres les progressions pedagogiques qui marchaient (variations de la methode selon le profil), les frictions recurrentes avec les parents (tarifs, assiduite, attentes), et les sujets de newsletter qui faisaient bondir l'engagement. Cet OS capitalise tout : chaque decision devient une PDR, chaque pattern un LRN, chaque friction un BLK.

---

## 2. Regles de travail

### Cadence

5 jours d'enseignement par semaine. Mercredi reserve a la creation de contenu (newsletter + scripts atelier). Pas de cours le dimanche.

### Capacite

Maximum 28 eleves recurrents. Au-dela, la qualite pedagogique chute (verifie sur 2 trimestres avant cet OS - voir LRN-001).

### Format

Sophie ne propose QUE :
- Cours individuel hebdomadaire (60 min, 250 EUR/mois - 4 cours)
- Atelier groupe (90 min, 35 EUR par atelier)
- Stage trimestriel (3 jours pendant les vacances, 180 EUR)

Pas de cours a la carte, pas de "cours d'essai gratuit illimite", pas de packs degressifs (PDR-002).

### Pricing

Pas de remise. Pas de tarif degressif. Le prix est annonce avant le diagnostic 30 min, et il ne se negocie pas (PDR-003).

### Ligne editoriale newsletter

3 piliers stricts (voir `content/CONCEPTS.md`) :
1. Progression pedagogique (anecdotes anonymisees + methode)
2. Repertoire et culture musicale (decouvertes, conseils ecoute)
3. Conseils parents (gestion motivation, regularite, espace cours a la maison)

Tout post hors de ces 3 piliers est refuse par l'agent `editor-music`.

### Capitalisation obligatoire

Toute decision pedagogique structurante (changement de methode, refus d'un type d'eleve, modif tarifaire) est documentee en PDR AVANT execution. Tout pattern observe sur >= 2 eleves devient un LRN. Toute friction qui coute > 30 min devient un BLK.

---

## 3. Taches types

### Qualifier un nouvel eleve

Quand Sophie recoit une demande (mail / DM / parent au telephone), elle invoque `student-qualifier` avec le brief (age, niveau declare, motivation, contexte). L'agent retourne GO / NO-GO / DIAGNOSTIC en croisant PDR-001 (perimetre) + PDR-004 (refus adultes debutants en collectif) + LRN pertinents.

### Preparer une newsletter

Quand Sophie a une idee de contenu (stockee dans `content/IDEAS.md`), elle redige un brouillon et invoque `editor-music`. L'agent verifie la conformite aux 3 piliers + a la regle auto-scopee `eleves-confidentialite`, et retourne VALIDE / AJUSTER / REFUSER.

### Capitaliser un apprentissage pedagogique

Apres un trimestre, Sophie ouvre `LEARNINGS.md` et redige un LRN si elle a observe un pattern sur >= 2 eleves. Format : contexte, observation, regle generalisable.

### Documenter une decision pedagogique

Quand Sophie hesite (refus d'un nouvel eleve, ajout d'un format, changement de pricing), elle ouvre `BDR.md` (renomme PDR ici) et redige la decision AVANT execution.

---

## 4. Interdits

- **INTERDIT** : depasser 28 eleves recurrents. Raison : LRN-001 (qualite chute au-dela).
- **INTERDIT** : prendre un eleve adulte vrai debutant en cours collectif. Raison : PDR-004.
- **INTERDIT** : promettre une preparation concours sous 6 mois. Raison : PDR-005 + LRN-007.
- **INTERDIT** : mentionner un eleve nominalement dans le contenu newsletter. Raison : regle `eleves-confidentialite`.
- **INTERDIT** : proposer une remise sur les tarifs annonces. Raison : PDR-003.
- **INTERDIT** : modifier un fichier sous `eleves/factures/` sans validation explicite humaine.
- **INTERDIT** : utiliser le mot "coaching" dans la communication publique. Raison : Sophie enseigne, ne coache pas.
- **INTERDIT** : promettre un retour sur un brouillon en moins de 48h. Raison : PDR-006 (cadence creation).

---

## 5. Forks et lineage

PetitsCoursFlow est un fork de VibeFlow (Pattern 07). Vocabulaire fork :
- **PDR** au lieu de BDR (Pedagogical Decision Record)
- **Trimestre** au lieu de Sprint
- **Programme par eleve** au lieu de Feature
- **Decrochage** au lieu de Bug
- **Demarrage de trimestre** au lieu de Deploy

La structure VibeFlow est conservee : 5 registres, 3 tiers de regles, 6 roles canoniques d'agents, principes de capitalisation.
