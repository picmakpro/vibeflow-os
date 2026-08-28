---
name: gsdc-07-federated-schema-gap
description: check-gsd-config.sh (GSDC-07, phase 23) dérive KNOWN_TOP d'une union PLUS LARGE que le moteur — faux négatif prouvé, alors que l'en-tête affirme « jamais faux négatif »
metadata:
  type: project
---

Le gate `plugin/dev-orchestrator/scripts/check-gsd-config.sh` doit prédire l'avertissement
`unknown config key(s)` du moteur. Il lit l'union de trois modules `bin/lib/*.cjs` du gsd-core
installé (`config.cjs` → `VALID_CONFIG_KEYS`, `capability-registry.cjs` → `configKeys`,
`configuration.cjs` → `CONFIG_DEFAULTS`).

**Le moteur, lui, n'utilise QUE `VALID_CONFIG_KEYS` + `DYNAMIC_KEY_PATTERNS` + 10 littéraux en dur
+ l'overlay fédéré** (`config-loader.cjs:651-672`). Ni `configKeys`, ni `CONFIG_DEFAULTS`. Le gate
est donc un **sur-ensemble** → il se tait là où le moteur avertit.

Faux négatif prouvé par exécution le 2026-08-03 (revue `revue-02`) : une config par ailleurs alignée
portant `"_comment"` au premier niveau → le gate rend « aligné, rien à signaler » (exit 3) pendant
que `loadConfig(cwd)` écrit `unknown config key(s): _comment`. `_comment` est une **chaîne de
documentation** de `CONFIG_DEFAULTS`, pas une clé de config — et le chemin ne passe pas du tout par
la fédération. Diff complet script∖moteur : `_comment`, `claude_orchestration`, `external_job`,
`intel`, `mempalace`, `profile-pipeline` ; diff moteur∖script : vide.

Correctif mesuré (`KNOWN_TOP` en parité stricte = `validArr` premiers segments + `dynTop` +
`engineExtra`, l'union à 3 sources ne servant plus qu'à `KNOWN`/`hasChildren`) : suite reste
26 ok / 0 ko, faux négatif rattrapé, ce lab reste à exit 3. Arbitrage laissé à l'humain car la
parité stricte rouvre des faux positifs sur les labs à capabilities fédérées (`mempalace`, `intel`).

Deux points de la revue précédente sont **clos** : l'exception `engineExtra` est désormais nommée en
en-tête, et le cas 26 l'exerce contre le moteur réel dans les deux sens (vérifié par mutation). Le
mirroir `engineExtra` est une copie **exacte** des 10 littéraux de `config-loader.cjs:654-655` —
gsd-core ne les exporte nulle part, c'est une contrainte réelle de l'API amont, pas un raccourci.

**Why:** ADR-055 §3 — un gate n'a le droit d'affirmer que ce qu'il constate. Une limite documentée
« faux positif possible, jamais faux négatif » qui est fausse dans l'autre sens est pire qu'une
limite non documentée : elle dispense le lecteur suivant de vérifier.

**How to apply:** dès qu'un gate de ce dépôt prétend **reproduire** un verdict amont, comparer les
deux ensembles par **calcul** (`diff` d'ensembles, pas échantillonnage) avant de croire la doc, et
exiger que la sonde d'atteinte porte sur la **différence** d'ensembles et non sur deux littéraux
choisis. Voir [[feedback_mirror-gate-superset-drift]] et
[[feedback_mutation-test-regression-claims]].
