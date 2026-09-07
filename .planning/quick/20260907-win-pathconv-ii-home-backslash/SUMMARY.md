---
type: quick
slug: win-pathconv-ii-home-backslash
date: 2026-09-07
status: complete
version: v2.59.1
commits: [6ed1f76, 68d9ed7, 7897a74, ba649b7]
---

# SUMMARY — WIN-PATHCONV II

## Ce qui a été livré

| Commit | Contenu |
|---|---|
| `6ed1f76` | `to_posix()` + normalisation des deux formes + 3e marque du garde-fou + T26/T26b/T26c |
| `68d9ed7` | `docs/WINDOWS-HOOKS-PATHCONV.md` §7 — le second vecteur et son signe distinctif |
| `7897a74` | Release v2.59.1 — versions + historique des 2 README |
| `ba649b7` | Rattrapage CI : 4e fichier de version (`.codex-plugin`), anonymisation du compte testeur, marqueur `vf-allow-machine-path` |

## Vert mesuré, pas déclaré

```
test-merge-hooks.sh        39 OK · 0 KO   (T26, T26b, T26c inclus)
test-manifest.sh           62 OK · 0 KO
test-resolve-deps.sh        5 OK · 0 KO
test-vf-portable.sh        16 OK · 0 KO
test-windows-crlf.sh       13 OK · 0 KO
test-runtime-cli-dispatch  15 OK · 0 KO
test-gsd-cohabitation.sh    8 OK · 0 KO
test-vibeflow-update.sh    70 OK · 1 KO   ← préexistant, voir ci-dessous
```

## Dette constatée, pas touchée

**`test-vibeflow-update.sh` T29b** — `balayage global sous $CUSTOM_TARGET : 1 occurrence '.claude/'
résiduelle (attendu 0)`. Vérifié par stash : **identique avec et sans ce hotfix** (70 OK / 1 KO
dans les deux cas). Régression antérieure à cette branche, hors périmètre. À traiter séparément.

**Migration des 20 entrées gouvernance en forme exec** (`docs/HOOKS-CONTRAT-SORTIE.md` §6) —
décidée le 2026-08-15, jamais exécutée. C'est elle qui supprimera la couche d'expansion shell
responsable de la seconde ligne d'erreur du testeur (`C:Userswinuser`, backslashes mangés). Ce
hotfix rend le chemin correct ; il ne supprime pas le shell qui le relit. Chantier réel :
20 conversions, chacune exigeant que le script porte sa propre traduction de code de sortie.

## Ce qu'il reste à faire, humain

1. PR + merge sur `main`.
2. **Tag annoté `v2.59.1` + release GitHub** — sans quoi `check-release-tag.sh --remote` reste
   rouge, et la version n'est ni traçable ni installable par référence.
3. Le testeur Windows lance `/vf-update` : **la normalisation agit à la POSE**. Son `settings.json`
   actuel garde ses chemins mixtes tant que les hooks ne sont pas re-posés.

## Leçon

Le garde-fou de v2.55.1 avait raison d'exempter la lettre de lecteur en tête — c'est légitime en
scope user sur Windows. Il n'a simplement jamais vérifié la **queue** du chemin, alors que son
propre commentaire nommait la forme attendue (`C:/Users/…`, avec un slash). Une exemption
justifiée peut border un trou : ce qu'elle laisse passer mérite sa propre assertion.
