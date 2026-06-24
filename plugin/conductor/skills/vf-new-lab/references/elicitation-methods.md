# Méthodes d'élicitation — menu numéroté

> Référence de `vf-new-lab` (phase Clarification). Adaptation des méthodes de raisonnement adverses
> de BMAD (`bmad-advanced-elicitation`). Principe : l'utilisateur **choisit un chiffre**, l'agent
> **fait le creusage** sous l'angle choisi. L'agent sélectionne contextuellement 3-4 méthodes à offrir
> par section selon le risque.

## Sélection par défaut selon la section

| Section du brief | Méthodes prioritaires |
|------------------|------------------------|
| Problème / valeur | Pré-mortem, First Principles, Socratique |
| Métier & vocabulaire | Analogie, Socratique |
| Parties prenantes | Cartographie parties prenantes, Inversion |
| Périmètre / non-périmètre | **Pré-mortem (défaut)**, Inversion, Constraint Removal |
| Process & livrables | First Principles, Analogie |
| Contraintes | Constraint Removal, Red Team / Blue Team |
| Définition de fini | Socratique, Inversion |
| Gates & EVALS | **Pré-mortem (défaut)**, Red Team / Blue Team, Inversion |
| Capacités requises (manifeste) | First Principles, Red Team / Blue Team, Inversion |

## Les 8 méthodes

### 1. Pré-mortem (défaut sur périmètre, gates & capacités)
« Imagine que ce lab a échoué lamentablement dans 6 mois **à cause de cette section**. Raconte ce qui
s'est passé. » → fait remonter les trous qu'une revue standard rate. La méthode reine pour specs/plans.

### 2. Inversion
« Comment cette section garantirait-elle l'échec du lab ? » Puis on inverse chaque réponse en garde-fou.
Excellent pour transformer un flou en contrainte explicite.

### 3. First Principles
Décomposer la section jusqu'aux vérités de base : « qu'est-ce qui est vrai sans hypothèse ? ». On
reconstruit ensuite. Casse les évidences héritées (« on fait comme ça parce que… »).

### 4. Cartographie des parties prenantes
Lister tous les acteurs impactés (y compris les oubliés : conformité, support, futur mainteneur). Pour
chacun : que veut-il, que craint-il ? Révèle les personas manquants.

### 5. Questionnement socratique
L'agent challenge les hypothèses implicites de l'utilisateur par questions successives, sans donner de
réponse. Fait expliciter ce qui était tacite.

### 6. Constraint Removal
« Si cette contrainte n'existait pas, que ferais-tu ? » Sépare les vraies contraintes (hard) des
habitudes (soft). Affine la section Contraintes.

### 7. Red Team / Blue Team
Red Team attaque la section (« voici 3 façons dont ça casse »), Blue Team défend/corrige. Adversarial,
idéal pour durcir les gates, les EVALS et le manifeste de capacités.

### 8. Analogie
« À quoi ça ressemble dans un autre domaine que tu connais ? » Transpose un pattern éprouvé (P7 :
transposer, pas copier). Utile pour nommer le vocabulaire et structurer les process.

## Mécanique de boucle

- Après une méthode (2-8), **mettre à jour la section** avec ce qui a émergé, puis **ré-afficher le menu**.
- `1` = section claire → marquer `✅`, passer à la suivante.
- `r` = rebattre 4 nouvelles méthodes (parmi celles non encore proposées).
- `x` = terminer la clarification (le gate listera la dette restante).
- Si une réponse reste vague après une méthode : **reposer** sous un autre angle. Ne jamais présumer
  (« reformule et redemande, ne présume jamais »).
