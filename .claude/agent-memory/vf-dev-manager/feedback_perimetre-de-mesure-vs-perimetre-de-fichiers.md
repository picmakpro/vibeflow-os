---
name: perimetre-de-mesure-vs-perimetre-de-fichiers
description: Deux nœuds parallèles peuvent avoir des périmètres d'ÉCRITURE disjoints et collisionner quand même — si l'un mesure la surface que l'autre modifie
metadata:
  type: feedback
---

Avant de dispatcher une frontière en parallèle, vérifier la disjonction du **périmètre de mesure**,
pas seulement du périmètre d'écriture. Un nœud qui **compte** des fichiers dans un dossier et un
nœud qui **crée** des fichiers temporaires dans ce même dossier ne sont PAS disjoints, même si le
second nettoie derrière lui et ne touche aucun fichier du repo.

**Why:** mission Phase 20 (2026-07-28) — `probe-mcp` créait des agents-sondes dans `~/.claude/agents`
pendant que `probe-hooks` chiffrait le nombre de warnings de `check-agents.sh` sur ce même dossier.
Résultat : le second a mesuré 30 lignes / 2 erreurs bloquantes au lieu de 29 / 0, et a rapporté les
sondes comme « artefacts d'une sonde antérieure » — il ne pouvait pas savoir qu'elles étaient
concurrentes. Le chiffre a dû être corrigé à la main. Aucun des deux mandats n'était fautif :
l'erreur est au dispatch.

**How to apply:** au `dag.sh add`, se poser deux questions au lieu d'une — « quels fichiers ce nœud
écrit-il ? » ET « quelle surface ce nœud observe-t-il ? ». Si la surface observée par A recoupe la
zone d'écriture de B, séquentiel (mesurer d'abord, sonder ensuite) ou worktree. Cas typiques dans ce
repo : tout nœud qui chiffre `~/.claude/agents`, `plugin/*/agents/`, un compteur de suites de tests,
ou une sortie de `check-*.sh`. Voir [[verifier-contre-le-commit-de-base]] et
[[sessions-concurrentes-sur-le-repo]] — même famille de mensonge, cause différente.
