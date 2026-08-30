---
name: eleves-confidentialite
paths:
  - "content/**"
description: "Regle auto-scopee qui interdit toute mention nominative d'un eleve dans les contenus publics"
---

# Rule - eleves-confidentialite

> Regle auto-scopee. Activee quand l'agent travaille sur tout fichier sous `content/`.
> Cette regle protege la confidentialite des eleves de Sophie K. dans toute publication.

## Activation

Cette regle se charge automatiquement quand l'agent lit ou ecrit un fichier sous `content/` (newsletter, IDEAS, INSIGHTS, scripts ateliers, posts).

## Regles dures

### 1. Aucune mention nominative d'un eleve

Tout contenu publie doit anonymiser les eleves. Formats acceptes :
- "un de mes eleves" (preferable, generique)
- "Marie, 12 ans, niveau 2eme cycle" (prenom seul + classe d'age + niveau, OK)
- "un ado de 15 ans en debut de 3eme cycle" (formulation completement anonyme, recommandee)

Formats interdits :
- "Marie Dupont a fait des progres" (prenom + nom)
- "M. Dupont, 12 ans" (initiale + nom)
- Toute combinaison qui rend l'eleve identifiable par le voisinage de Sophie

### 2. Aucun cas qui rend l'eleve identifiable par recoupement

Meme avec un prenom seul ou un anonymat partiel, si la combinaison de details permet a un lecteur de reconnaitre un eleve specifique (ex : "ma seule eleve adulte qui passe le concours du Conservatoire en juin 2026"), le contenu doit etre reformule en plus generique ou differe (publier 6+ mois apres).

### 3. Aucun montant nominatif d'un eleve

Pas de "X paie 60 EUR/h" meme anonymise. Les chiffres pricing vont dans le skill `pricing-knowledge` ou dans les agents - jamais dans le contenu publique.

### 4. Mentions necessitant autorisation prealable explicite

Si Sophie veut raconter un cas precis (anonymise), elle doit avoir l'accord ecrit du parent / eleve concerne. La regle suppose que cet accord existe et est trace - si pas trace, REFUSER le brouillon.

### 5. Anciennete > 6 mois sur cas anonyme

Si la situation racontee remonte a > 6 mois et que l'anonymisation est totale (impossible a recouper), l'autorisation prealable peut etre exemptee - mais l'agent doit explicitement signaler cette exemption pour que Sophie valide.

## Action en cas de violation

1. STOPPER la validation du brouillon
2. AFFICHER le passage en violation + la regle concernee
3. PROPOSER une reformulation conforme
4. Si pattern recurrent (>= 2 violations sur 3 mois), creer un LRN et reviser CLAUDE.md (interdit explicite a renforcer)

## Raison d'etre

La confiance des parents est l'actif principal de Sophie. Une seule fuite (parent qui se reconnait dans une newsletter sans accord prealable) detruit cette confiance pour des annees, et avec elle un canal d'acquisition (les recommandations parentales).

Cette regle auto-scopee est la barriere deterministe qui empeche toute derive accidentelle - plus fiable qu'une regle dans la constitution qui peut etre oubliee en cours de redaction creative.
