# Phase 27 — Portée de l'isolation worktree (Livrable 2)

**Établi le :** 2026-08-05 · **Par :** `vf-coder` (plan `27-03`, tâches 1-2, avant le checkpoint de
la tâche 3).
**Origine :** D-05 (les 13 agents du groupe A reçoivent `isolation: worktree`), D-03
(`worktree.baseRef: "head"`), et les hypothèses laissées ouvertes par `27-RESEARCH.md` (Livrable 2)
faute d'un harnais d'observation dans ce dépôt — qui est la **source** des modules, pas un lab où
ces agents tournent.

> ## STATUT DE CE DOCUMENT
>
> Trois décisions, à trois degrés de fermeture différents :
>
> - **Partie 1 (groupe B — 6 managers)** — verdict **EXCLUSION**, tranché ici par écrit, avec une
>   réserve nommée (A6) et son déclencheur de réouverture. Rien n'attend plus sur ce point.
> - **Partie 2 (`worktree.baseRef`)** — recette **écrite** et **constatée** sur ce poste au moment
>   de la rédaction, mais **le geste n'est pas ratifié par ce document**. La tâche 3 de
>   `27-03-PLAN.md` (checkpoint humain **bloquant**) est le seul endroit où Samuel confirme ce
>   basculement. Ce document décrit l'état constaté ; il ne s'y substitue pas.
> - **Partie 3 (hypothèses A1 / A2 / A4 / A5)** — **aucune tranchée ici**. Ce dépôt ne peut les
>   observer sur pièce ; la première occasion réelle est le run Workflow du plan `27-05`.

## Table de verdicts

| # | Objet | Verdict | Confiance | Rouvre si |
|---|---|---|---|---|
| — | Groupe B (6 managers) | **EXCLUSION** de `isolation: worktree` | MOYENNE (réserve A6) | un manager est un jour dispatché comme **sous-agent** d'un autre orchestrateur |
| — | `worktree.baseRef` | **`"head"`** — décision de vision déjà verrouillée (D-03) ; seul le **geste** reste soumis à confirmation humaine (tâche 3) | HAUTE sur la décision, N/A sur le geste | sans objet — ce n'est pas une hypothèse, c'est un acte à poser |
| A1 | Syntaxe de `.worktreeinclude` = celle d'un `.gitignore` | SUPPOSÉE | BASSE | un worktree d'agent créé, présence de `.claude/agent-memory/` observée dedans |
| A2 | Dossier matérialisé par le harness = `.claude/worktrees/` | SUPPOSÉ | BASSE | chemin réel listé au premier agent isolé qui tourne |
| A4 | `GSD_WORKSTREAM` est hérité par un sous-agent isolé | SUPPOSÉ | MOYENNE | valeur imprimée par le premier agent isolé |
| A5 | `docs/reference/` n'est lu par aucun worker au runtime | SUPPOSÉ | BASSE | échec de lecture observé en worktree isolé, ou son absence constatée |

---

## Partie 1 — Le groupe B (6 managers) : EXCLUSION de `isolation: worktree`

**Verdict : exclusion.** `vf-business-manager`, `vf-content-manager`, `vf-design-manager`,
`vf-dev-manager`, `vf-growth-manager`, `vf-test-orchestrator` ne reçoivent pas `isolation: worktree`
à la tâche 4 de ce plan. Deux fondements, une réserve écrite plutôt que tue.

### Fondement 1 — doctrinal

`team-kernel.md:106` : « **Un manager ne produit jamais** (P3) : il lit, planifie (DAG), dispatche
la frontière, synthétise. Toute production vit dans les workers. » L'outil `Write` des 6 agents du
groupe B sert des artefacts de **pilotage** (DAG de mission sous `.planning/missions/`, mises à
jour de `.planning/STATE.md`/`.planning/ROADMAP.md`), jamais du contenu produit pour l'utilisateur
final — c'est cette distinction, pas le seul grep mécanique sur `tools:`, qui fait la frontière
entre le groupe A et le groupe B (`27-RESEARCH.md` §Livrable 2 Q3).

### Fondement 2 — mesuré, et corrigé sur pièce (D-13)

`27-RESEARCH.md` (§Livrable 2 Q3) affirme : « `vf-dev-manager` est le **seul** agent du dépôt à
écrire `.planning/STATE.md` ». **Cette session re-dérive l'affirmation plutôt que de la recopier
(D-13) — et le résultat la corrige.** Commande reproductible :

```bash
for f in plugin/*/agents/*.md; do grep -q "STATE\.md" "$f" 2>/dev/null && echo "$f"; done
```

Résultat (exécuté cette session) : **5 fichiers** mentionnent `STATE.md`, pas 1 — les 5 managers
`vf-business-manager`, `vf-content-manager`, `vf-design-manager`, `vf-dev-manager`,
`vf-growth-manager` (`vf-test-orchestrator` ne le mentionne pas du tout dans son propre fichier).
En resserrant sur un **verbe d'écriture** explicite accolé à `STATE.md` (pas une simple mention en
liste de lecture) :

| Agent | Verbe constaté | Nature |
|---|---|---|
| `vf-business-manager:169-170` | « mets à jour `.planning/STATE.md` » | écriture explicite |
| `vf-design-manager` | « consigne la reprise (STATE `### Decisions`) » | écriture explicite |
| `vf-dev-manager:177-178` (+ 3 autres occurrences) | « Marque chaque étape finie (STATE + case ROADMAP) », « Tu mets à jour le suivi » | écriture explicite, la plus étendue des 6 |
| `vf-content-manager`, `vf-growth-manager` | « État planning : `.planning/STATE.md`... » | **lecture seule** — listé comme intrant, aucun verbe d'écriture trouvé |
| `vf-test-orchestrator` | — | ne mentionne pas `STATE.md` dans son propre fichier |

**Ce que la correction change, et ce qu'elle ne change pas.** Le fait mesuré n'est plus « un seul
agent isolé écrirait `STATE.md` hors de l'arbre principal » mais « **au moins 3 des 6** portent une
directive d'écriture explicite sur `STATE.md`, et 2 de plus le lisent sans l'écrire ». Le verdict
d'exclusion **ne s'affaiblit pas** — il se **renforce** : ce n'est plus un cas isolé
(`vf-dev-manager` seul) mais un trait partagé par la majorité du groupe, cohérent avec le fondement
1 (P3). Le cas *nommément* posé par le cadrage reste `vf-dev-manager` — c'est le plus étendu des
3 — mais l'isoler seul en écartant les 5 autres aurait laissé le même risque ouvert ailleurs.

### Réserve — écrite, pas tue (hypothèse A6)

Le comportement réel de la clé `isolation:` sur un agent **incarné en entrée de mission** (dispatché
par `vibeflow-dev` ou `/vf-auto`, plutôt que lui-même re-dispatché en sous-agent par un autre
orchestrateur) n'a été observé par personne — aucun harnais de test disponible dans ce dépôt pour
l'exécuter réellement. Confiance **MOYENNE** : appuyée par la doctrine écrite (P3) et par la mesure
ci-dessus, mais pas par une exécution constatée. `[ASSUMED]`, à traiter comme point ouvert, pas
comme réglé par ce document.

**Déclencheur de réouverture, objectif :** si un manager du groupe B vient un jour à être dispatché
comme **sous-agent** d'un autre orchestrateur (plutôt qu'incarné en entrée de mission), le verdict
d'exclusion se ré-examine à ce moment-là — pas avant.

---

## Partie 2 — `worktree.baseRef` (D-03)

**La décision de vision est déjà verrouillée** (`27-CONTEXT.md` D-03) : `worktree.baseRef` doit
valoir `"head"`. Ce qui suit est la **recette** pour la poser, pas un débat sur la valeur cible.

### Où et comment

La clé vit dans le `settings.json` **machine** de Claude Code — **hors de ce dépôt**, hors
`.planning/config.json`. Ce n'est pas un fichier versionné : le geste qui la pose **ne modifie
aucun fichier suivi de ce dépôt**, ce qui explique pourquoi aucun `files_modified` d'aucun plan de
cette phase ne le mentionne (`27-RESEARCH.md` §« `worktree.baseRef` — hors fichiers du dépôt »).

**Commande outillée qui pose le réglage :**
```
node ~/.claude/gsd-core/bin/gsd-tools.cjs worktree set-baseref
```
Écrit `worktree.baseRef: "head"` dans `<cwd>/.claude/settings.local.json`. La commande est
**no-clobber** : une valeur explicite déjà posée et différente de `"head"` est préservée (la sortie
porte alors `skipped: 'explicit-other'` plutôt que d'écraser silencieusement un choix existant).

**Commande de lecture de l'état effectif :**
```
node ~/.claude/gsd-core/bin/gsd-tools.cjs worktree base-check
```
Résout `worktree.baseRef` par la cascade à 3 niveaux (local du lab → partagé du lab →
utilisateur/global).

### Le motif

Le défaut `"fresh"` branche chaque nouveau worktree d'agent depuis `main`, pas depuis la branche de
mission active. Sur une mission longue (comme la Phase 27 elle-même, portée par
`feat/phase-27-parallelisation-execution`), un worker isolé partirait de `main` et **perdrait tout
le travail non encore mergé** de la branche en cours pour ce worker précis.

### La portée assumée

Ce réglage est **global à la machine** : il s'applique à **toutes** les missions futures sur ce
poste, pas seulement à la Phase 27. C'est une portée assumée par D-03, pas un effet de bord découvert
après coup.

### Pourquoi ce document ne pose pas la clé lui-même (B2, correction de revue)

**Ce geste est le cran de sûreté préalable à la tâche 4 de `27-03-PLAN.md`**, pas une formalité
annexe. Armer `isolation: worktree` sur les 13 agents du groupe A (tâche 4) **avant** que
`worktree.baseRef` ne vaille `"head"` exposerait le **prochain worker isolé — dont `vf-coder`,
un des 13 — à brancher son worktree depuis `main` et à perdre la branche de mission en cours**, y
compris, de façon directement engageante, `feat/phase-27-parallelisation-execution` elle-même.
C'est pourquoi la version restructurée de `27-03-PLAN.md` place ce basculement en **tâche 3,
checkpoint humain bloquant**, strictement avant la tâche 4 — jamais l'inverse.

### État constaté sur ce poste au moment de la rédaction — et le piège qu'il faut nommer

`worktree base-check`, exécuté en lecture seule au moment d'écrire ce document, retourne déjà :
```json
{"shouldDegrade": false, "reason": "baseref-head", "message": null, "headSha": null, "forkRef": null, "forkSha": null}
```
`.claude/settings.local.json` contient déjà `{"worktree": {"baseRef": "head"}}`.

**Ce constat n'est PAS une ratification de Samuel au checkpoint de la tâche 3.** Ce fichier a été
posé par un worker antérieur, en marge d'une vérification distincte, avant l'ouverture de ce plan —
pas par un geste conscient de Samuel en réponse au checkpoint que la tâche 3 lui présente. Une
condition de sûreté satisfaite par accident de calendrier n'équivaut pas à une validation humaine
(ADR-031). L'assertion machine de la tâche 4
(`worktree base-check` → `shouldDegrade:false` et `reason:"baseref-head"`) passera donc **au vert
dès son premier essai**, sans qu'aucun humain n'ait encore rien confirmé pour **ce plan-ci** — c'est
précisément le piège que la tâche 3 existe pour ne pas laisser un exécuteur franchir en silence.
**Le vert de ce gate n'autorise donc pas, à lui seul, l'exécution de la tâche 4** : la confirmation
explicite de Samuel au checkpoint de la tâche 3 reste requise, indépendamment de cet état de fait.

---

## Partie 3 — Les hypothèses ouvertes, et leurs sondes

Ce dépôt est la **source** des modules `plugin/*/agents/*.md`, pas un lab où ces agents sont
installés et tournent. Aucun worktree d'agent ne peut donc être observé **depuis ce dépôt**. Les
quatre hypothèses suivantes (`27-RESEARCH.md` §« Ce qui reste incertain », table A1-A6) restent
ouvertes — **aucune n'est traitée comme réglée par ce document.**

| # | Hypothèse | Confiance | Sonde qui la ferme |
|---|---|---|---|
| A1 | La syntaxe de `.worktreeinclude` est celle d'un `.gitignore` (motifs, un par ligne) | BASSE — aucune source faisant autorité trouvée, ni dans ce dépôt ni dans `gsd-core` | Créer un worktree d'agent isolé, constater si `.claude/agent-memory/` y est présent |
| A2 | Le dossier matérialisé par le harness pour les worktrees d'agent est `.claude/worktrees/` | BASSE — cité par le ROADMAP et la spec, jamais observé sur disque (0 worktree existant dans ce dépôt) | Lister le chemin réel matérialisé au premier agent isolé qui tourne |
| A4 | `GSD_WORKSTREAM` est héritée par un sous-agent en `isolation: worktree` | MOYENNE — inférée d'une issue GitHub tierce, jamais testée sur ce poste | Faire imprimer la valeur de cette variable par le premier agent isolé |
| A5 | `docs/reference/` n'est lu par aucun worker au runtime, donc n'a pas besoin d'entrer dans `.worktreeinclude` | BASSE — absence de preuve positive de lecture, pas une preuve d'absence rigoureuse | Observer un échec de lecture en worktree isolé, ou son absence constatée |

**La première occasion réelle de les observer est le run Workflow du plan `27-05`** — son étape 2
dispatche deux plans en `isolation: worktree` par défaut. C'est ce run, et non ce document, qui
pourra transcrire ce qui est réellement observé pour chacune des quatre lignes ci-dessus.

---

## Références

`27-CONTEXT.md` (D-03, D-05, D-11, D-13) · `27-RESEARCH.md` (§Livrable 2, Q2/Q3, §« `worktree.baseRef`
— hors fichiers du dépôt », §« Ce qui reste incertain » A1-A6) · `27-PATTERNS.md` (§`.worktreeinclude`,
§`.gitignore`) · `27-03-PLAN.md` (tâches 1-4, `<threat_model>` T-27-03-03/T-27-03-07) ·
`plugin/conductor/references/team-kernel.md:104-117` (Règles d'instanciation, P3) ·
`.planning/phases/VFDO-24-.../24-COLLISIONS.md` (convention de document de décision imitée ici,
et précédent de re-dérivation d'un chiffre — §M-1).
