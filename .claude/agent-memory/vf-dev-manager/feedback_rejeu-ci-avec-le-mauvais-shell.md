---
name: rejeu-ci-avec-le-mauvais-shell
description: Rejouer une étape CI sous `bash -eo pipefail` alors que GitHub utilise `bash -e {0}` fabrique un rouge (ou un vert) qui n'existe pas — exiger la fidélité du shell, pas seulement la dé-indentation du bloc run
metadata:
  type: feedback
---

Quand un mandat demande de rejouer une étape de `ci.yml`, exiger que le worker **reproduise le shell
réel de GitHub Actions**, pas un shell « raisonnable ». Sans clé `shell:` dans l'étape, le défaut est
`bash -e {0}` — **sans `pipefail`**. Un worker qui rejoue sous `bash -eo pipefail` n'exécute pas la
même chose.

**Why:** Phase 25 (2026-09-15), rejeu du job `gates`. Le premier passage, fait sous `-eo pipefail`,
a rendu sur l'étape neuve **exit 2 avec zéro ligne de sortie** — un rouge silencieux. Sous le shell
fidèle, la même étape est verte. Le rouge était entièrement fabriqué par le shell du rejeu. Le worker
l'a repéré et corrigé lui-même ; s'il ne l'avait pas fait, j'aurais remonté à l'humain un « rouge CI
imputable au dépôt » inexistant, ou pire, fait corriger une étape saine. La dissymétrie existe dans
l'autre sens aussi : une étape qui ne passe QUE grâce à l'absence de pipefail est fragile, et c'est
exactement ce que ce rejeu a révélé (une affectation `I="$(gate … | awk …)"` héritant d'un `rc=2`,
inoffensive aujourd'hui, mortelle le jour où quelqu'un ajoute `shell: bash`).

**How to apply:** dans tout mandat de rejeu CI, deux exigences CUMULÉES, jamais une seule —
**(1)** extraire le corps du `run:` avec un vrai parseur YAML (`python3 -c "import yaml"`), jamais un
`sed`/`awk` naïf, et vérifier que la sortie n'est pas vide (cf. [[heredoc-desindente-vert-silencieux]]
— plusieurs étapes de ce dépôt ont des heredocs dont le terminateur est indenté comme le bloc, qu'un
dé-indent ligne-par-ligne casse) ; **(2)** exécuter sous `bash --noprofile --norc -e`, et si l'étape
déclare une clé `shell:`, sous celle-là. Toute divergence de verdict entre deux shells est un
finding en soi, pas un détail de méthode. Voir [[preexistant-mesure-contre-la-mauvaise-ancre]] :
avant d'imputer un rouge au dépôt, éliminer d'abord le rouge fabriqué par le harnais de rejeu.
