# Ingestion-flow — doctrine du pont spec/plan → feuille de route (BRDG-01/BRDG-03)

> Source de vérité de la capacité d'ingestion : comment `vibeflow-dev` détecte qu'une spec ou un
> plan écrit(e) reste orpheline de la feuille de route, comment il construit le manifest attendu
> par le moteur, et à quelles conditions il délègue — sans jamais réimplémenter ni contourner les
> gates natifs de `gsd-ingest-docs`/`gsd-import`. Chargée **on-demand** par `vibeflow-dev`, comme
> `mission-flow.md` et `GSD-PIPELINE.md` — coût contexte nul le reste du temps. Le **fait outillé**
> (quels documents sont non intégrés, à quel grain) est produit par `discover-unintegrated-docs.sh`
> (phase 13, plan 13-01) : ce fichier ne le redéfinit pas, il documente comment l'interpréter et ce
> qu'on en fait.

---

## Découverte

L'agent appelle `discover-unintegrated-docs.sh` — en repo source :
`plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` ; en lab installé :
`.claude/scripts/discover-unintegrated-docs.sh` (même arborescence que les autres scripts du
module). Le script répond au FAIT (ADR-055 §3) : il ne juge jamais si un document est une spec, un
plan, un ADR ou une doc — il constate qu'un fichier existe sous `docs/superpowers/{specs,plans}/`
et qu'aucun registre de planning ne le cite.

Contrat de sortie consommé tel quel : une ligne par document non intégré au format
`grain<TAB>chemin` (`grain` ∈ `spec`|`plan`, chemin relatif à la racine scannée), triée. Trois
exits à interpréter littéralement :

- **exit 0** : au moins un document non intégré — la sortie stdout liste les paires
  `grain<TAB>chemin`, à parcourir une par une pour proposer l'ingestion.
- **exit 3** : rien à intégrer — corpus vide sous `docs/superpowers/{specs,plans}/`, corpus
  entièrement déjà cité par un registre, ou `.planning/` absent du repo courant. Dans les trois
  cas, l'agent ne propose rien : ce n'est pas une erreur, c'est un état stable.
- **exit 64** : argument inconnu passé au script — erreur d'appel côté agent, à corriger avant de
  retenter, jamais à masquer.

## Construction du manifest

Le **typage** (ADR/PRD/SPEC/DOC) et la **précédence** d'un document restent du jugement de l'agent
(ADR-055 §3) — ce ne sont jamais des faits outillés, `discover-unintegrated-docs.sh` ne les
produit pas. Pour ce module, seul le grain `spec` produit une entrée manifest, et toujours avec
`type: SPEC` (aucune ambiguïté de typage à trancher ici : le grain `spec` du script correspond
exactement au type `SPEC` du moteur d'ingestion). Schéma attendu par
`gsd-ingest-docs --manifest <f>` (cité verbatim depuis le workflow du moteur) :

```yaml
docs:
  - path: docs/superpowers/specs/<fichier>.md   # relatif à la racine repo
    type: SPEC                                   # seul type utilisé par ce module (D-03)
```

Le manifest est écrit par l'agent dans un fichier **temporaire hors `.planning/`**, via `mktemp` —
jamais sous `.planning/`. Cette zone est réservée aux artefacts que le moteur écrit lui-même
**après** ses propres gates (PROJECT/REQUIREMENTS/ROADMAP/STATE) ; y écrire un manifest d'entrée
romprait la lecture d'ADR-031, qui protège l'écriture de ces artefacts de planning, pas un fichier
d'entrée éphémère consommé puis jeté.

## Délégation

Le grain `spec` se délègue à `gsd-ingest-docs --mode merge --manifest <fichier temporaire>` — le
flag `--mode merge` est **toujours explicite dans l'appel**, jamais seulement documenté en prose :
le projet est déjà cadré (jamais `--mode new` sur un projet existant). Le grain `plan` se délègue
directement à `gsd-import --from <chemin>`, appel direct, sans manifest — le moteur `gsd-import`
porte sa propre détection de conflit côté plan, symétrique à celle de `gsd-ingest-docs` côté
spec. Dans les deux cas, ces moteurs (parseur de manifest, classification, synthèse, gate de
conflit) ne sont **jamais réimplémentés ni contournés** par l'agent : son rôle s'arrête à la
détection, à la construction du manifest quand il y en a un, et à l'appel.

## Garde-fous BRDG-03

Quatre garde-fous, écrits noir sur blanc, aucun n'est optionnel :

- **BLOCKER** : le gate `conflict_gate` natif à `gsd-ingest-docs` (et son équivalent côté
  `gsd-import`) n'écrit **jamais** PROJECT/REQUIREMENTS/ROADMAP/STATE quand des contradictions non
  résolues subsistent (`BLOCKERS > 0` dans `INGEST-CONFLICTS.md`). Interdiction absolue de
  contourner ce gate — jamais de flag qui le court-circuite, jamais d'appel qui suppose son
  résultat avant qu'il ait tourné.
- **ADR-031 / confirmation humaine** : la confirmation humaine explicite précède **tout** appel à
  `gsd-ingest-docs` ou `gsd-import` — portée par le mécanisme « proposer l'ingestion comme next
  step » de `AGENT.md` : l'agent annonce l'intention (nombre de documents, grains concernés,
  moteur ciblé) et attend confirmation avant de déléguer. Jamais de réponse pré-remplie à
  l'`AskUserQuestion` interne du moteur.
- **`--mode merge`** : par défaut sur un projet existant, toujours explicite dans l'appel (repris
  de la section Délégation ci-dessus — pas une note à part, une contrainte d'appel).
- **cap 50** : le cap de 50 documents par invocation est appliqué **en interne** par
  `gsd-ingest-docs` (contrainte v1 du moteur) — l'agent ne le re-vérifie jamais en double, il se
  contente de le **signaler** à l'utilisateur si le compte rendu par `discover-unintegrated-docs.sh`
  s'en approche.

## Interdits

Aucun verbe-façade `/vf-ingest` n'existe ni ne doit être introduit — la façade a été **supprimée
en v2.33.0** (arbitrage direct, aucun retour arrière). L'ingestion se déclenche par langage
naturel détecté et brique invoquée directement, jamais par un verbe dédié. Aucune réimplémentation
du parseur de manifest, de la classification, de la synthèse ou du moteur de conflits : ces
logiques appartiennent à `gsd-ingest-docs`/`gsd-import`, point.
