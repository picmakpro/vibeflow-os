---
titre: "[titre de la phase]"
inconnues:
  - id: I-01
    question: "[ce qu'on ne sait pas encore]"
    structurante: oui
    statut: ""
    par: ""
    le: ""
    ou: ""
---

# Cadrage — [titre]

> Recopié tel quel (registre à une ligne structurante, statut vide), ce fichier dérive
> `en cadrage` — jamais `à planifier` (voir `references/modele-cycles.md` § Les huit états).

## Le registre d'inconnues

Une **liste de mappings** en frontmatter (jamais un tableau Markdown), une ligne par inconnue :

- `id` — identifiant court de la ligne.
- `question` — ce qu'on ne sait pas encore.
- `structurante` — `oui` ou `non`. Seules les lignes `structurante: oui` ferment le cadrage
  (spec §7.5) : une ligne `structurante: non` peut rester sans statut sans empêcher la clôture du
  registre.
- `statut` — chaîne **libre**, vide ou non. **Toute** valeur non vide ferme la ligne, quelle
  qu'elle soit : le recalcul ne juge **jamais** la valeur, seulement sa **présence**. Il n'y a pas
  de liste fermée de statuts admis. `ARBITRÉ` (qui porte `par`, `le`, `ou` — pont mémoire, spec
  §7.5) reste l'**exemple recommandé**, sans être la seule valeur qui ferme une ligne.
- `par`, `le`, `ou` — qui a tranché, quand, où (portés par l'exemple `ARBITRÉ`).

**Registre clos** ⇔ aucune ligne `structurante: oui` à `statut` vide. `inconnues: []` est **clos**
(on vérifie que le registre est clos, jamais qu'il est long).
