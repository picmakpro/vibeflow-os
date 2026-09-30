---
name: gate-qui-garde-plus-que-la-files-modified
description: Un plan qui exige un gate à rc=0 hérite de TOUTE la surface de ce gate, pas des seuls fichiers de sa files_modified
metadata:
  type: feedback
---

Quand un plan exige un gate à `rc=0`, il hérite de **toute la surface de ce gate** — sa
`files_modified` ne la borne pas. Vécu le 2026-09-24 (plan 41.1-08) : le plan bumpait 3 modules et
listait 9 fichiers (`VERSION`, `module.json`, `CHANGELOG.md`), tout en exigeant
`check-version-sync.sh` vert. Or ce gate vérifie AUSSI l'en-tête `**Version**` des
`plugin/*/README.md` — que le bump rendait faux sur les trois. Le plan ne pouvait pas satisfaire
sa propre sonde en restant dans sa liste.

**Why:** la règle d'arbitrage de la phase — *elle ferme ce qu'elle a créé, elle consigne ce qu'elle
a seulement révélé* — tranche sans ambiguïté : l'écart était **créé par mon bump**, pas révélé.
Même patron que les plans 41.1-03 et 41.1-05, qui ont fermé le compte de suites des README
(85→86→87) que leurs suites neuves rendaient faux. La `files_modified` est une **rédaction**, pas
un contrat.

**How to apply:** avant de coder, exécuter le gate exigé et **lire ses lignes de vérification une
par une** pour cartographier sa vraie surface — pas seulement le `files_modified` du plan. Corriger
l'écart créé, le nommer comme *déviation assumée* au SUMMARY avec la sortie `✗` brute qui la
motive. Distinguer le voisin homonyme : ici les README **de module** se corrigent, les README
**racine** (et `VERSION` racine, `plugin.json`, `marketplace.json`) restent hors périmètre parce
qu'ils appartiennent au geste de release humain. Voir [[perimetre-du-plan-se-rederive-du-diff]].
