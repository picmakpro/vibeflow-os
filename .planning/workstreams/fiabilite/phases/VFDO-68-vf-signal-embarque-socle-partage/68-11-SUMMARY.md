---
phase: 68-vf-signal-embarque-socle-partage
plan: 11
requirements: [VFSG-13]
status: complete
---

# 68-11 — Module cockpit monté, relecture adverse SOBR-04 (VFSG-13)

Traces : `68-11-RED-TRACE.md`, `68-RELECTURE-ADVERSE.md`. Périmètre fixé par P68-D-31 (arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04, « Module seul, racine groupée (Recommandé) »), qui amende P68-D-08.

## Commits

| Empreinte | Objet |
|-----------|-------|
| `1a0f4a8d` | plan réduit au module cockpit et à la relecture adverse |
| `a3a09bb4` | module `cockpit` monté à v1.2.0 (v1.1.2 posée par la PR #201 ; le plan annonçait v1.1.1) |
| `594585ba` | relecture adverse SOBR-04 du diff de la phase, brouillon des notes de la release groupée |

## Résultats

- Rouge R1 (VERSION seule montée, `check-version-sync.sh` exit 1) puis vert (triade et en-tête du README alignés, exit 0) ; sources racine intactes, aucun tag, aucun verrou pris.
- Relecture adverse par un agent frais (tête `0d4f8ae0`) : aucun constat bloquant, trois constats à décider (AD-1 à AD-3), tous tranchés avant le merge : P68-D-40 et P68-D-41.
- Le CHANGELOG du module ne cite pas de version racine : la mention « publiée dans VibeFlow vX.Y.Z » reste à compléter.

## Gestes humains restant, hors phase (release groupée)

1. Bump racine cohérent (`scripts/bump.sh` : `VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, historique et badges des deux README, `CHANGELOG.md` racine), sous le verrou de dépôt `release-bump`.
2. Relecture adverse du diff entre le dernier tag et le commit de release, avec une sonde exécutée, commande et sortie dans les notes de release.
3. Après le merge sur `main`, sous le verrou `release-tag` : tag annoté `vX.Y.Z` et `git push origin vX.Y.Z`.
4. `gh release create vX.Y.Z --verify-tag`, notes tirées du brouillon de `68-RELECTURE-ADVERSE.md`.
5. `bash scripts/check-release-tag.sh --remote` doit sortir `✓`.
6. Compléter la mention « publiée dans VibeFlow vX.Y.Z » de l'entrée v1.2.0 de `plugin/cockpit/CHANGELOG.md`.
7. Étapes 4 (VS Code) et 5 (mobile) de la recette, par Samuel, après la PR (P68-D-35).

## Estimate / actuals

`actuals` non mesurés (exécution inline).
