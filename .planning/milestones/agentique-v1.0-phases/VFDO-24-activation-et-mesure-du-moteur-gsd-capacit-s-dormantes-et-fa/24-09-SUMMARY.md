---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 09
status: done
requirements: [GSDA-17]
commits:
  - d29602b feat(24-09) — étape CI « gates workstream-aware » (6 verdicts partitionnés + 3 racine)
---

# 24-09 — Les gates workstream-aware exercés sur un arbre réellement partitionné (GSDA-17)

## Ce qui est livré

Une étape neuve du job `gates` de `.github/workflows/ci.yml`, placée après `check-state-integrity`
et avant `check-release-tag`. Elle construit elle-même un `.planning/` partitionné dans un
`mktemp -d`, y exerce les quatre gates, prouve que la fixture est **discriminante**, puis vérifie
sur le checkout racine que rien n'a bougé.

**Aucune partition n'est créée dans le dépôt.** La fixture est jetable et supprimée en fin
d'étape : la contrainte « aucune partition tant qu'une phase est en vol » est tenue.

`GSD_WORKSTREAM` est le canal exercé en premier — canal **nominal** depuis l'amendement d'ADR-064,
et canal de premier rang de `resolveActiveWorkstream` amont.

## Les neuf verdicts, rejoués à la main

Rejoués en extrayant le corps de l'étape **depuis le YAML lui-même** (et non depuis un brouillon) :
`9/9 verts`, bilan `0 écart`.

| # | Gate | Contexte | Attendu | Mesuré |
|---|---|---|---|---|
| 1 | `check-dev-bootstrap.sh` | `GSD_WORKSTREAM=dev` | rc 3 + « Projet piloté par GSD » | ✓ |
| 2 | `check-state-integrity.sh` | `GSD_WORKSTREAM=dev` | rc 0 sur `.planning/workstreams/dev/STATE.md` | ✓ |
| 3 | `planning-context.sh` | `GSD_WORKSTREAM=dev` | rc 0 + en-tête nommant le workstream | ✓ |
| 4 | `check-workstream-pointer.sh` | `GSD_WORKSTREAM=dev` | rc 0 + canal `env (GSD_WORKSTREAM)` | ✓ |
| 5 | `check-dev-bootstrap.sh` | **sans** workstream | rc 0 + `[bootstrap]` « feuille de route absente » | ✓ |
| 6 | `check-workstream-pointer.sh` | **sans** workstream | rc 1 + remède + motif `os.tmpdir()` | ✓ |
| R1 | `check-dev-bootstrap.sh` | racine | rc 3, sortie **invariante** selon `GSD_WORKSTREAM` | ✓ |
| R2 | `check-workstream-pointer.sh` | racine | rc 3 + **stdout strictement vide** | ✓ |
| R3 | `planning-context.sh` | racine | rc 0 + extrait non vide (52 lignes) | ✓ |

Les verdicts 5 et 6 sont la **preuve de discriminance** : mêmes fichiers, verdicts contraires.

## Discriminance prouvée par mutation — 11 mutants, tous rouges, neutre vert

Le contrôle neutre reste vert ; chaque mutant est **confiné au segment qu'il doit faire rougir**.

| Mutant | Injection | Segment rougi |
|---|---|---|
| C1 | `ROADMAP.md` du compartiment retiré | assertion de construction |
| C2 | `STATE.md` posé à la racine de la fixture | garde « racine vide » |
| A1 | workstream retiré de la **seule** invocation 1 | verdict 1 |
| A2 | `total_plans` retiré du frontmatter | verdict 2 (rc 2) |
| A3 | `INDEX.md` posé dans la fixture | verdict 3 |
| A4 | workstream retiré de la **seule** invocation 4 | verdict 4 |
| A5 | workstream **ajouté** à la seule invocation 5 | verdict 5 |
| A6 | workstream **ajouté** à la seule invocation 6 | verdict 6 |
| B1b | 2ᵉ branche de R1 lisant un autre `.planning` | invariance R1 |
| B2b | fuite injectée sur le stdout capté en R2 | vacuité R2 |
| B3 | injecteur racine visant un `.planning` inexistant | R3 |

### Deux mutants ont dû être ÉCARTÉS comme invalides

Un mutant qui casse la commande ne prouve rien : il rougit pour la mauvaise raison.

- `env VAR=x -u AUTRE` — `env` lit `-u` comme le **nom de la commande** : rc 127. Trois assertions
  rougissaient sur un `command not found`, pas sur le workstream. Reformé en `env -u … VAR=x`.
- `--hook` sur l'état 0 du gate de pointeur — l'état 0 est **silencieux même en mode hook**, le
  mutant restait **vert**. Remplacé par une injection après capture (B2b).

### Deux sous-assertions non discriminantes, corrigées

Le banc a montré que « `GSD_WORKSTREAM` » nu et « `ADR-064` » nu **ne discriminent rien** au verdict
6 : ils apparaissent aussi dans le message de conformité (« composable avec ADR-064 »). Les
sous-chaînes assertées sont donc celles du **seul état 4** : `export GSD_WORKSTREAM=<nom>` et
« non composable avec ». Sans cette correction, deux assertions sur quatre étaient décoratives.

## Écart mesuré contre la fiche F-35 — le plan ne pouvait pas être suivi à la lettre

La tâche 2 prescrivait d'asserter que le gate de démarrage rend sur la racine « projet piloté par
GSD » (verdict de référence de **F-35**). **Ce verdict est aujourd'hui PÉRIMÉ.**

Le frontmatter de `.planning/STATE.md` fait **81 lignes**, au-delà de la garde anti-gel de **60
lignes** de `check-dev-bootstrap.sh` : `extract_frontmatter` sort avant d'avoir vu le délimiteur
fermant, `state3_signal` échoue, et le script retombe sur sa soupape de sûreté **D-04** — **exit 3
avec un stdout vide**. Mesuré le 2026-08-04.

Les deux rédactions littérales étaient donc impraticables :

- asserter la sous-chaîne de F-35 → **job rouge dès sa première exécution** ;
- asserter « stdout vide » → **grave l'état dégradé comme la norme**, et rougit le jour où le
  frontmatter est raccourci (c'est-à-dire le jour où le défaut est corrigé).

L'assertion retenue tient dans les deux cas **et** mesure ce que le bloc 2 doit mesurer :
l'**invariance** de la sortie selon `GSD_WORKSTREAM` sur un arbre non partitionné. Elle est
discriminante (mutant B1b) et survit à la correction du frontmatter.

> **Conséquence hors périmètre, non corrigée ici :** le signal d'orientation `[gsd-engine]` de ce
> dépôt est **muet au SessionStart**. `.planning/STATE.md` est hors du périmètre de ce mandat —
> le fait est remonté, pas traité.

## Limite de preuve — à ne jamais omettre

**Aucune exécution d'intégration continue n'a eu lieu sur la branche de la Phase 23.** Tant que la
branche de la Phase 24 n'est pas poussée, **ce job n'aura jamais tourné pour de vrai**. Tout ce qui
est affirmé ci-dessus a été rejoué **localement, sur macOS**, jamais sur le runner Linux.

Portabilité vérifiée en conséquence : aucun `sed -i` nu, `grep -P`, `readlink -f`, `mapfile`,
`declare -A`, `${x,,}`, `stat -c` ni `date -d` dans l'étape neuve (0 occurrence mesurée).

## Contraintes du plan tenues

- YAML valide ; le job `gates` porte **exactement une** étape neuve dont le nom cite les workstreams.
- Assertion de construction **avant toute mesure**, dans les deux sens : les 4 fichiers attendus
  existent, **et** la racine du `.planning` de la fixture est vide de `ROADMAP.md`/`STATE.md`.
- Fixture en dépôt git **initialisé et commité** — sans commit, `check-state-integrity` sortirait en
  2 « non vérifiable » et le job mesurerait la mauvaise chose.
- **Aucun `|| true`** sur une invocation de gate (seule occurrence : un commentaire). Bilan unique.
- Temporaire supprimé (`trap` + `rm -rf` explicite).
- Étape `check-state-integrity` **bit-à-bit inchangée** et non dupliquée.
- **Ajout pur : 190 lignes ajoutées, 0 supprimée.**

## Les deux garde-fous récents, préservés

Le plan avait été rédigé avant que `ci.yml` ne bouge ; les numéros de ligne ont été re-dérivés.

- `check-state-integrity.sh` reçoit toujours **`--file .planning/STATE.md` explicitement** (l. 329) —
  sans lui, le gate ADR-063 se désarme par un simple `export GSD_WORKSTREAM=…`.
- Le balayage d'agents par module inclut toujours **`plugin/*/AGENT.md`** (l. 278) — population
  réelle **31, pas 25**. Gate C reste vert.

## Reste à faire ailleurs

- Le job n'aura de valeur probante qu'à la **première exécution réelle sur le runner** (branche
  poussée).
- Le frontmatter de `.planning/STATE.md` dépasse la garde de 60 lignes : décision humaine requise.
