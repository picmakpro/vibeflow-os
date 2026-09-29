---
name: baseline-avant-le-premier-artefact
description: Capturer la baseline d'une suite AVANT de produire le premier artefact — un fichier généré dans un dossier globé élargit le périmètre des gates larges et pollue la mesure de non-régression
metadata:
  type: feedback
---

La liste de référence des libellés `ok` se capture **avant le premier artefact produit** — avant le
premier `bash <générateur>`, pas seulement avant la première édition de code. Si c'est déjà trop
tard, elle se **reconstitue** (retirer l'artefact, écarter les libellés du bloc neuf) plutôt que de
se prendre telle quelle.

**Why:** sur le plan 23-04, la baseline avait été prise après que le générateur eut déposé
`gsd-capabilities-index.md` dans `references/`. Or `module_md_targets()` globe `"$REFS_DIR"/*.md` :
le fichier neuf entrait **déjà** dans le périmètre des gates larges au moment de la « baseline ».
Elle mesurait un état post-geste et annonçait `0 disparu / 9 apparus / 103 communs` ; la vraie
mesure était `5 / 14 / 98`. Un déposant d'artefact **élargit le périmètre d'audit** de tout gate
qui globe son dossier, et les libellés qui citent un compte de fichiers (« 13 fichier(s) de
doctrine balayé(s) ») bougent mécaniquement. La revue l'a rattrapé ; la mesure était fausse, pas
le geste.

**How to apply:** dès qu'une étape crée un fichier dans un dossier **globé** par la suite
(`references/`, `agents/`, `skills/`), l'ordre est : (1) run de baseline, (2) génération, (3) run
final, (4) `comm` dans les deux sens. Et quand des libellés « disparaissent », ne pas conclure à
une perte : **normaliser le nombre** qui a bougé (`gsub(/ 13 /," N ")`) et re-comparer par
`cmp -s`. Deux listes qui deviennent identiques = seul le compteur a changé, aucune substance
perdue — c'est cette normalisation qui distingue un effet de périmètre bénin d'une vraie
régression. Cf. [[libelles-ok-geles]] et [[ok-statiques-vs-executes]].

**Cas jumeau, mesuré Phase 41.1 (plan 41.1-03) — un gate de la RACINE compte les suites du parc.**
Créer un `plugin/<module>/scripts/tests/test-*.sh` fait passer `check-version-sync.sh` au rouge :
son point 9 compare `find plugin scripts -path '*/tests/test-*.sh' | grep -c .` au littéral
« N suites » cité par **`README.md` ET `README.fr.md`** (l.~140 / l.~145). Ajouter une suite
neuve casse donc deux fichiers que rien dans le plan ne nomme, et le rouge n'apparaît qu'au rejeu
`replay-ci-jobs.sh --job gates`, jamais dans les suites du module. Réflexe : **toute création
d'un fichier `tests/test-*.sh` s'accompagne du bump des deux README**. Même famille que
ci-dessus : le fichier neuf élargit un glob, et le compteur qui le cite ment aussitôt.

