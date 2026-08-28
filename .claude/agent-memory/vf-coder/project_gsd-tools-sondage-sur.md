---
name: gsd-tools-sondage-sur
description: Le help de gsd-tools omet des commandes existantes ; répéter une commande destructive sur une copie via --cwd ; vérifier un gate par render-hooks + contre-épreuve
metadata:
  type: project
---

Trois faits outillés sur `gsd-tools` (constatés en Phase 24, gsd-core 1.9.1).

**1. La liste de commandes du `--help` est INCOMPLÈTE — une commande absente peut exister.**
`gsd-tools windows --help` rend le usage global dont la ligne `Commands:` ne mentionne **pas**
`windows`. La commande existe pourtant : `gsd-tools windows` (sans argument) répond
`Unknown windows subcommand. Available: status, append, waive, fixed`.

**Why:** conclure « la commande n'existe pas, le mandat est infaisable » depuis le `--help` aurait
fait remonter un `blocked` faux. Le binaire n'est pas sur le `PATH` non plus — il vit à
`~/.claude/gsd-core/bin/gsd-tools.cjs`, à invoquer par `node`.

**How to apply:** pour savoir si une sous-commande existe, l'invoquer **sans argument** — l'erreur
liste les sous-commandes réelles. Ne jamais conclure à l'absence depuis la ligne `Commands:`.

**2. Répéter une commande destructive sur une copie jetable, via `--cwd`.**
`gsd-tools --cwd <dir> <cmd>` accepte un dossier arbitraire : `mkdir -p /tmp/probe/.planning`,
y copier le fichier visé, jouer la commande là-bas, inspecter le résultat — **puis** seulement la
jouer pour de bon.

**Why:** exigence de récupérabilité sur un fichier qu'un bug amont connu (#2893) pouvait détruire.
La répétition a montré le résultat exact avant tout risque, pour un coût négligeable.

**How to apply:** dès qu'une commande réécrit un fichier versionné et qu'un doute existe sur son
innocuité. Vérifier ensuite l'intégrité par `comm -23 <(sort avant) <(sort après)` — les seules
lignes disparues doivent être celles qui devaient changer. Voir [[diff-proxifie-utiliser-comm]].

**3. Un gate ne se vérifie pas en lisant sa clé de config, mais par `loop render-hooks <point>`.**
`gsd-tools loop render-hooks ship:pre --raw` rend les hooks réellement actifs (`capId`, `kind`,
`blocking`) — c'est la requête que le workflow de ship exécute lui-même. Poser
`workflow.windows_enforce: true` fait apparaître `broken-windows | gate | blocking=true`.

**How to apply:** toujours doubler d'une **contre-épreuve** — rejouer la même requête sur une copie
de la config **sans** la clé, et constater que le hook disparaît. Sans ça, on prouve qu'un gate est
présent, pas que la clé en est la cause. Même exigence que
[[mutation-test-discriminating-cases]].
