# SOLID + Séparation des préoccupations + Organisation du code

> Référence du skill `software-architecture`. Spécialise P9 pour le code de production.

## Les 5 principes SOLID (formulés comme contrats vérifiables)

### S — Single Responsibility Principle (SRP)
Une unité (fichier, classe, module, fonction) a **une seule raison de changer**.
- Test : « combien de raisons distinctes feraient changer ce fichier ? » > 1 → découper.
- Signal : un fichier importé par des domaines qui n'ont rien à voir ; un fichier > 300L.

### O — Open/Closed Principle
Ouvert à l'extension, fermé à la modification. On ajoute un comportement sans réécrire l'existant.
- Pattern : stratégie, registre, table de dispatch plutôt que `if/else` qui grossit.

### L — Liskov Substitution Principle
Une implémentation doit être substituable à son abstraction sans casser l'appelant.
- Test : remplacer une implémentation par une autre du même contrat ne casse aucun test.

### I — Interface Segregation Principle
Des interfaces petites et ciblées par client, pas une interface fourre-tout.
- Signal : une interface dont les implémentations laissent des méthodes vides / `throw`.

### D — Dependency Inversion Principle
Dépendre d'abstractions, pas de détails concrets. Le domaine ne connaît pas l'infrastructure.
- Pattern : injection de dépendances ; le domaine définit le port, l'infra fournit l'adaptateur.

## Séparation des préoccupations (SoC) = Clean Architecture — Dependency Rule

Le découpage en couches, c'est la **Clean Architecture** (Robert C. Martin) : le domaine au centre,
l'infrastructure en périphérie.

```
Domaine        (entités, règles métier, cas d'usage)        ← ne dépend de rien
   ↑
Application    (orchestration, services, coordination)
   ↑
Infrastructure (DB, API externes, framework, I/O)           ← dépend du domaine, jamais l'inverse
```

Règle d'or = la **Dependency Rule** : **les dépendances pointent vers le domaine**, jamais l'inverse.
Le domaine ne connaît ni la DB, ni le framework, ni l'UI (rejoint DIP). UI + logique métier +
persistance mélangées dans une même unité = violation à découper en premier.

## Feature-Sliced Design (organisation par domaine, pas par couche technique)

Organiser autour de **bounded contexts** (DDD), pas de dossiers techniques globaux. Chaque
feature est auto-contenue : sa logique, son UI, ses actions, ses tests colocalisés.

```
features/
  auth/          # tout ce qui concerne l'auth, ensemble
  leads/
  payments/
shared/          # utilitaires réellement partagés (hooks, utils, types)
lib/             # librairies de bas niveau
```

À éviter : `components/` global qui regroupe tout (séparation horizontale) → crée des
dépendances inter-features et empêche le travail parallèle.

## Pattern Server Action / backend en 4 couches (dev web)

```
action.ts      → point d'entrée + validation de schéma (entrée/sortie typées)
handler.ts     → orchestration
service.ts     → logique métier (domaine)
repository.ts  → accès aux données
```

`Result<T>` (union discriminée `{ ok: true, data } | { ok: false, error }`) plutôt que des
exceptions non typées → gestion d'erreur vérifiable statiquement, intention claire pour l'IA.

## Clean Code — contrats explicites, petites unités, erreurs typées

Les points ci-dessus (petites unités auto-contenues, noms révélateurs d'intention, `Result<T>`
plutôt qu'exceptions muettes) sont l'application du **Clean Code** : un code qui se lit comme sa
propre spec. Le foyer de la mécanique de test associée (Red-Green-Refactor) est la **carte TDD**
dans `principles.md`.

Toute fonction/processus majeur a un contrat clair : ce qui entre, ce qui sort, ce qui peut
échouer. L'efficacité de l'IA croît proportionnellement à la clarté du contrat. En dev :
types + unions discriminées. Hors dev : matrices RACI, documents de décision, checklists.
