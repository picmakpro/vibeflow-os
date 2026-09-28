---
titre: "[titre du plan]"
ecrit:
  - "[chemin/relatif/du/livrable]"
---

# Plan — [titre]

> Ce fichier n'est **jamais** modifié pour marquer une clôture : son hash reste stable pour les
> verdicts hachés (Phase 46). La clôture se marque en posant `CLOTURE.md` **à côté** de ce fichier
> (voir `references/modele-cycles.md` § Fichiers du modèle, `CLOTURE.md`).

## Gestes

1. [geste 1]
2. [geste 2]

## Ce que le plan écrit

`ecrit:` déclare le ou les livrables produits par ce plan — un chemin **relatif à la racine du
lab**, jamais dans `.planning/`. Une entrée valide : non vide, sans `/` ni `~` initial, sans
segment `..`, sans caractère de contrôle ni `\`, sans métacaractère `*?[]{}<>`. Tant que
`[chemin/relatif/du/livrable]` n'est pas remplacé par un chemin réel, l'entrée est invalide et le
plan dérive `indéterminé` (`ecrit-invalide`) plutôt qu'un faux `à exécuter`.
