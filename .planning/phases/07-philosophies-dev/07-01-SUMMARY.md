---
phase: 07-philosophies-dev
plan: 01
status: complete
requirements: [PHIL-01, PHIL-02, PHIL-03, PHIL-04, PHIL-05, PHIL-07]
---

# Summary 07-01 — Doctrine : nommage + principles.md + table universelle

## Livré
- **`solid-soc.md`** — nommage en place, zéro contenu réécrit :
  - Section couches → « SoC = **Clean Architecture** — Dependency Rule » (règle d'or explicitée comme *Dependency Rule*, lien DIP).
  - Section contrats typés → « **Clean Code** — contrats explicites, petites unités, erreurs typées ».
- **`principles.md`** (nouveau, 72L) — DRY / KISS / YAGNI au format contrat (règle → test → signal → remède) + **carte TDD**. DRY porte la nuance clé (dédup de *savoir*, pas de lignes ; piège de la fausse abstraction ; rule of three). La carte TDD **renvoie** à `superpowers:test-driven-development` sans dupliquer la mécanique (DD3), articulée au Gate Nyquist.
- **`universal-vs-dev.md`** — table P9 étendue de 3 lignes (DRY/KISS/YAGNI + transposition non-dev).

## Vérif
- `grep` Clean Architecture / Dependency Rule / Clean Code dans `solid-soc.md` → OK.
- `grep` DRY/KISS/YAGNI/carte TDD + renvoi skill canonique dans `principles.md` → OK.
- Densité `principles.md` = 72L (sous seuil).

## Commit
`feat(software-architecture): doctrine DRY/KISS/YAGNI + nommage Clean Archi/Clean Code + carte TDD (Phase 7, plan 01)`
