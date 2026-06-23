---
planning_version: 2.0
scope: compartment
type: continuous
cadence: "[hebdomadaire | bimensuelle | mensuelle]"
wip_limit: 3
last_updated: "[YYYY-MM-DD]"
last_review: "[YYYY-MM-DD]"
---

# Board — [Nom du compartiment]

> Compartiment **`continuous`** : travail qui se renouvelle, **pas de fin**, donc **pas de roadmap**.
> Le plan est ce board, **rebattu à chaque cadence**. La revue de cadence remplace le jalon.
>
> **Valeur cœur :** [ce que ce process doit produire en continu — 1 ligne]
> **Cadence de revue :** [hebdo/mensuelle] — prochaine : [YYYY-MM-DD]

## Board (limite WIP : [N] en cours)

### 🗂 Backlog (idées / à faire)
- [ ] [élément]

### 🔄 En cours (≤ WIP)
- [ ] [élément — qui/quoi]

### ✅ Fait ce cycle
- [x] [élément livré ce cycle]

> À chaque revue de cadence : archiver « Fait ce cycle » (→ JOURNAL si capitalisable), repartir d'un
> backlog repriorisé. On ne tient PAS d'historique long ici (rôle du JOURNAL).

## Cadence — dernière revue ([YYYY-MM-DD])

- **Débit du cycle :** [N éléments livrés]
- **Décisions du cycle :** [décision courte → DEC-XXX si structurante — référencer, ne pas recopier]
- **Ajustement de priorité :** [ce qui monte/descend pour le prochain cycle]

## Sous-cycles deliverable (cas hybride, optionnel)

> Si ce process engendre des livrables bornés (ex. un *launch*), ouvrir un mini-plan deliverable
> temporaire et le fermer à la livraison. Lister ici les sous-cycles ouverts.

- [ ] [sous-cycle livrable] → `→ .planning/phases/[NN]/` · statut : [ouvert/livré]
