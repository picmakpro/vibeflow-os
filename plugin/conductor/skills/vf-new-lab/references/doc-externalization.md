# Référence — Externalisation doc contextuelle (ADR-042)

> Chargée on-demand en Phase 7 (point 1). Convention systémique : **l'init du `CLAUDE.md` déclenche
> l'externalisation de la doc.**

## Principe

Le `CLAUDE.md` est une **constitution** (< 150 lignes, P2), pas un dépôt de doc. Il **POINTE** vers la
doc externe (`@docs/...`), il ne la duplique jamais. Bénéfice : un `CLAUDE.md` qui reste léger (la mémoire/doc
bloat noie l'IA) et une doc qui suit la structure réelle du lab.

## Topologie (docs centralisé)

```
lab/
├── CLAUDE.md          # constitution + index : mappe chaque compartiment → @docs/<projet>/
└── docs/
    ├── _transverse/   # doc commune à tout le lab (REFERENCE, conventions, glossaire)
    │   ├── INDEX.md
    │   └── REFERENCE.md
    ├── <projet-a>/    # doc CONTEXTUELLE du compartiment a (@docs/<projet-a>/)
    │   ├── INDEX.md
    │   └── REFERENCE.md
    └── <projet-b>/    # idem
```

> Coexiste avec les `docs/<module>/` posés par l'installeur (doc des modules, Type-4 `content/`).

## Proportionnalité (NE PAS sur-scaffolder)

Un `docs/<projet>/` **uniquement pour un compartiment qualifié** — même seuil d'autonomie que les
`.planning/` (cf. planning-core `references/compartments.md`). Sous le seuil / dossier d'infra → **pas**
de `docs/<projet>/` ; une ligne dans l'index du `CLAUDE.md` suffit. **Jamais un `docs/<projet>/` par
micro-dossier.** Lab mono-projet → `docs/_transverse/` seul.

## Procédure (Phase 7)

1. Déterminer les compartiments qualifiés (mêmes que ceux qui obtiennent un `.planning/`).
2. `conductor/scripts/scaffold-docs.sh <compartiment ...>` → crée le squelette idempotent (ne touche
   jamais un fichier existant).
3. Rédiger le `CLAUDE.md` racine : section **Index documentaire** mappant
   - doc transverse → `@docs/_transverse/`
   - chaque compartiment qualifié → `@docs/<projet>/`
4. Remplir `docs/_transverse/REFERENCE.md` (vocabulaire, conventions, stack) au lieu d'inliner dans `CLAUDE.md`.

## Garde-fou

- **Jamais inliner** une REFERENCE/spec dans le `CLAUDE.md` : externaliser + pointer.
- **Idempotent** : le scaffolder ne réécrit aucun doc existant (relançable sans risque).
