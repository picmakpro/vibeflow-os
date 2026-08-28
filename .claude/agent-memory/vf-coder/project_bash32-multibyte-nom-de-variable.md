---
name: bash32-multibyte-nom-de-variable
description: Sur bash 3.2 (macOS), un caractère non-ASCII collé à une expansion ($label→) est avalé dans le NOM de la variable — erreur fatale sous set -u, souvent sur un chemin rarement exécuté.
metadata:
  type: project
---

Dans tout script bash de ce dépôt, ne **jamais** accoler un caractère non-ASCII à une expansion :
écrire `[${label} rc=${r}]`, pas `[$label→$r]`. Accolades **et** voisinage ASCII.

**Why:** bash 3.2.57 (bash par défaut de macOS, cible dure d'ADR-054) inclut l'octet de tête d'un
caractère multi-octets dans le **nom** de la variable. `$label→` devient une variable `label\xE2`
non définie ; sous `set -u`, c'est une erreur **fatale** qui tue le script. Le message
(`label?: unbound variable`) ne ressemble pas à un problème d'encodage. Vérifié sur bash 3.2.57 :
`echo "[$label→9]"` meurt, `echo "[${label}→9]"` passe. Le même fichier passe sur bash 5 — donc
invisible hors macOS.

**How to apply:** le piège est vicieux parce que ces lignes sont souvent des **messages d'erreur**,
donc exécutées seulement quand quelque chose va mal. Constaté sur la Phase 23 : le balayage anti
hors-contrat d'une suite de test n'écrivait `$label→$r` que lorsqu'un `rc` sortait du contrat —
c'est-à-dire exactement quand le cas devait rougir. Le balayage **mourait** au lieu de reporter, et
la suite paraissait verte ; seule une mutation exécutée l'a démasqué. Corollaire : une sonde dont le
chemin d'échec n'a jamais tourné n'est pas prouvée — la muter jusqu'à lui faire emprunter ce chemin.
Même famille que [[bash32-heredoc-substitution]] ; voir aussi
[[mutation-test-discriminating-cases]] et [[gate-jamais-de-repli]].
