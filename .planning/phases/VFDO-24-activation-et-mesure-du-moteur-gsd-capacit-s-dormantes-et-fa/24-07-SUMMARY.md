---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 07
type: execute
status: complete
date: 2026-08-04
requirements: [GSDA-10, GSDA-11]
---

# 24-07 — ADR-068 : profils de contexte refusés, seuil inline mesuré et inchangé

Livrable unique : l'entrée **ADR-068** dans `/Users/samuel/Documents/dev/vibeflow-os/docs/ADR.md`,
couvrant les deux items de la zone 4 (A4 profils de contexte, A6 `inline_plan_threshold`), plus une
ligne de registre sur le numéro `ADR-065` non attribué.

Commit : **`71fea4fbbcf72f4199dbec04de646d236e17c61c`** — `docs/ADR.md` seul, **210 insertions,
0 suppression**.

## Tâche 1 — La re-mesure du seuil inline

### Méthode

Regex **exacte du moteur**, relevée dans `~/.claude/gsd-core/workflows/execute-plan.md:93`
(`grep -cE '^\s*<task[[:space:]>]'`), appliquée en `awk` — jamais en `grep` piped, qui tronque
silencieusement sur ce runtime.

Population : tous les `*-PLAN.md` des dossiers de phase 20 à 26 de `.planning/phases/`.

```bash
for f in .planning/phases/*/2[0-6]-*-PLAN.md; do
  awk '/^[[:space:]]*<task[[:space:]>]/{n++} END{print n+0}' "$f"
done | sort -n | uniq -c
```

### Résultat brut du jour (2026-08-04, à l'exécution de 24-07)

| Tâches | Plans |
|---|---|
| 0 | 4 |
| 2 | 8 |
| 3 | **28 (mode)** |
| 4 | 2 |
| 6 | 2 |
| **Total** | **44** |

Les 4 plans à 0 tâche sont les **rétro-plans de la Phase 21**, sans balise `<task>` : artefact de
format, exclus du dénominateur des plans *exécutables*.

- Plans exécutables : **40**
- Sous le seuil (≤ 2) : **8 / 40 — 20,0 %**
- Mode : **3 tâches** (28 plans), **juste au-dessus du seuil**

### Confrontation à la mesure du cadrage

| | Cadrage | Exécution |
|---|---|---|
| Date | 2026-08-04 | 2026-08-04 |
| Moment | avant écriture des plans de la Phase 24 | après écriture des 12 plans de la Phase 24 |
| Total / exécutables | 32 / 28 | 44 / 40 |
| ≤ 2 tâches | **4 / 28 — 14 %** | **8 / 40 — 20 %** |
| Mode | 3 (20 plans) | 3 (28 plans) |

**Delta nommé et attribué** : les 12 fichiers d'écart sont **exactement** les 12 plans de la
Phase 24 (`24-01` → `24-12`). Quatre d'entre eux — `24-03`, `24-07`, `24-08`, `24-09` — portent
2 tâches et entrent sous le seuil, d'où 14 % → 20 %. Aucune autre phase n'a bougé
(32 + 12 = 44, réconciliation exacte).

**Les deux mesures sont gravées, aucune n'a été substituée à l'autre.** Elles partagent la date
calendaire et sont séparées par la **population** — c'est le fait le plus instructif des deux : un
corpus de plans peut bouger de plus d'un tiers dans la même journée, donc un chiffre publié sans sa
population est périssable en heures.

**Conclusion inchangée par la re-mesure** : le levier reste minoritaire (20 %) et le **mode reste à
3**, juste au-dessus du seuil, aux deux mesures. Le porter à 3 basculerait le mode entier vers
l'inline. Le seuil reste à **2**, la clé n'est **pas** posée.

## Tâche 2 — ADR-068

### Les trois contraintes de rédaction, tenues

1. **La bonne clé est nommée** : `context_profile` (6 occurrences dans l'entrée), jamais présentée
   comme `context`. Le désalignement en-tête ↔ schéma est écrit comme fait à part entière.
2. **Le vocabulaire du retrait est absent** : `0` occurrence de la famille `dépréci*` dans les
   201 lignes d'ADR-068. L'état écrit est verbatim « documentée, livrée, jamais câblée, abandonnée
   de fait depuis avril 2026 ».
3. **Le déclencheur est objectif et sans échéance** : `0` date ISO, `0` mois en toutes lettres dans
   les 10 lignes de la section « Déclencheur de réexamen ».

### Précision de fait apportée à l'exécution — deux périmètres, pas un

Le mandat donnait le désalignement en-tête ↔ schéma comme un fait plat. La vérification de première
main sur le runtime installé montre qu'il faut le **scoper**, sans quoi l'ADR serait inexacte pour
un lecteur qui vérifierait localement :

| Périmètre | Fait vérifié |
|---|---|
| **Runtime installé, `gsd-core` 1.9.1** (vérifié de première main) | La clé validée comme énumération `['dev','research','review']` est bien **`context`** (`~/.claude/gsd-core/bin/lib/config.cjs:690-692`). **`context_profile` : 0 occurrence dans tout le payload installé** ; le répertoire `docs/` amont n'est même pas embarqué dans le paquet npm. Sur ce runtime, les en-têtes des trois fichiers sont donc **cohérents** avec le validateur. |
| **Dépôt amont, après la scission de schéma** (recherche du cadrage, non re-vérifiable ici) | Deux clés distinctes — `context` (texte libre) et `context_profile` (les presets, « *Added in v1.34* ») ; les trois fichiers nomment toujours `context:` en en-tête, d'où le désalignement. **6 occurrences, toutes dans `docs/`.** |

L'ADR porte **les deux**, chacun avec son périmètre et sa source. Ce n'est pas une contradiction du
mandat : c'est la même discipline que celle imposée aux chiffres — tout fait gravé porte sa méthode
et son périmètre. La version aplatie aurait été réfutable en une commande sur ce poste.

Le compte re-vérifié **renforce** le refus plutôt qu'il ne l'affaiblit : sur le runtime que nous
exécutons réellement, il n'y a pas 6 occurrences documentaires, il y en a **zéro**, et les seuls
hits du préfixe sont **3 lignes auto-déclaratives** (l'en-tête de chacun des trois fichiers de
profil).

### Ce que l'entrée contient

- **Volet 1** — la bonne clé et les deux périmètres ; l'état réel en troisième état ; le motif en
  deux temps (aucun consommateur / contrat per-rôle plus strict, `mission-flow.md:136-152`, avec le
  tableau des deux collisions : verbosité `research.md:20-23` contre `mission-flow.md:139-142`,
  vocabulaires de sévérité `blocking/important/nit` contre `bloquant/majeur/mineur`) ; la décision
  (aucune des deux clés posée) ; le déclencheur objectif.
- **Volet 2** — le rôle du réglage (`execute-plan.md:94,100`, `planning-config.md:41,276`) ; la
  méthode avant les chiffres ; le tableau des deux mesures ; le delta attribué ; la **disjonction
  acteur / mécanisme** (`AGENT.md:165-166,172` contre `GSD-PIPELINE.md:188-199`) ; la décision ; et
  ce que la mesure rend impossible (le seuil n'est plus un « levier de coût inconnu »).

### Registre — `ADR-065`

Le registre saute de `ADR-064` à `ADR-066`. Noté en **une ligne** sous la table d'index : numéro non
attribué, constaté le 2026-08-04. **Aucun comblement, aucune renumérotation** — la note existe
précisément pour qu'on ne « répare » pas un trou intact.

## Preuve d'additivité sur `docs/ADR.md`

| Contrôle | Résultat |
|---|---|
| `comm -23 <(sort avant) <(sort après)` | **0 ligne** — aucune ligne de l'avant absente de l'après |
| `comm -13` (ajouts) | 210 lignes |
| `git show --stat HEAD` | `1 file changed, 210 insertions(+)` — **0 suppression**, confirmé par git lui-même |
| Volume | 1705 → 1915 lignes |
| `cmp -s` sur l'intervalle ADR-066 | **bit-à-bit intacte** |
| `cmp -s` sur l'intervalle ADR-067 (59 lignes depuis son ancre) | **bit-à-bit intacte** |
| `\| ADR-068 \|` dans la table d'index | **exactement 1** ligne |

## Vérifications du plan

| Contrôle | Résultat |
|---|---|
| Verify tâche 2, bloc A (`ADR-068` + `context_profile` + `abandonnée de fait` + `inline_plan_threshold` + `mission-flow.md:136-152`, sans `dépréciée`) | **OK** |
| Verify tâche 2, bloc B (index = 1 ligne) | **OK** |
| Littéraux requis (`context_profile` 6, `abandonnée de fait` 3, `avril 2026` 1, `mission-flow.md:136-152` 1, `inline_plan_threshold` 3, `execute-plan.md` 3, `14 %` 2, `mode` 2) | **tous présents** |
| `dépréci*` dans ADR-068 | **0** |
| Dates dans le déclencheur | **0** |
| `.planning/config.json` — `context`, `context_profile`, `inline_plan_threshold` | **0 hit**, fichier non touché |

## Périmètre respecté

Un seul fichier modifié et commité, par pathspec explicite (`git commit docs/ADR.md -m …`, jamais
`git add`) : `/Users/samuel/Documents/dev/vibeflow-os/docs/ADR.md`. Aucune touche à
`.github/workflows/ci.yml`, aux `24-NN-PLAN.md`, à `24-COLLISIONS.md`, `.planning/config.json`,
`.planning/WINDOWS.md`, `.planning/codebase/CONCERNS.md`, `plugin/**`, `.planning/STATE.md`,
`.planning/ROADMAP.md`, `.planning/missions/`, `.planning/DRIVER.lock`. Aucun bump de version,
aucun tag. `gsd-tools state` jamais invoqué.

`hooks.workflow_guard` a émis ses avis advisory sur les deux éditions de `docs/ADR.md` — attendus,
non bloquants, ignorés conformément au mandat.
