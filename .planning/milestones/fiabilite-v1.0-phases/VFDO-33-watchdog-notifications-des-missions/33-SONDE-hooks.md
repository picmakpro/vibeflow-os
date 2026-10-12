# Sonde exécutée — capacités de hooks réellement présentes

> Menée le 2026-08-17 sur **Claude Code v2.1.233 installé**, pour convertir en faits les
> affirmations doc-dérivées du spike `33-SPIKE-hooks-async.md`. Doctrine du dépôt : on ne câble
> pas sur une capacité décrite, seulement sur une capacité prouvée.

## Niveaux de preuve — à lire avant d'utiliser ce document

La sonde a conclu « tout est prouvé ». **Cette conclusion est plus forte que ses propres
preuves**, et sa section de réserves la contredit. Le tableau ci-dessous rétablit le niveau réel.

| Affirmation | Niveau réel | Moyen de preuve |
|---|---|---|
| Les 16 noms d'événements existent dans la version installée | **PROUVÉ** | `strings` du binaire v2.1.233 + entrées vivantes dans les settings réels de la machine |
| `async` et `asyncRewake` sont reconnus | **PROUVÉ** | symbole `flushPendingAsyncRewakeHooks` dans le binaire |
| `asyncRewake` réveille sur **exit 2**, en portant le stderr en *system reminder* | **DOC** | doc officielle, jamais exécuté ici |
| `PostToolUse`/`PreToolUse` se déclenchent **dans un sous-agent** | **DOC — NON EXÉCUTÉ** | doc officielle ; l'expérience réelle n'a pas pu être montée |
| `SessionStart`/`Stop` **ne** se déclenchent **pas** dans un sous-agent | **DOC — NON EXÉCUTÉ** | idem |
| `SubagentStart`/`SubagentStop` se déclenchent en **session principale** | **DOC — NON EXÉCUTÉ** | idem |
| Forme exec : `"$HOME"` n'est **pas** expansé | **PROUVÉ** | hotfix v2.53.1 du dépôt (PR #44), régression réelle observée |

**Pourquoi l'expérience n'a pas pu être montée** : la sonde était bornée au mode non interactif
(`claude -p`), qui ne permet pas de provoquer une vraie création de Task avec traces par
événement. Nommé comme indéterminé plutôt que comblé.

## Conséquence contraignante pour la planification

Les trois lignes « DOC — NON EXÉCUTÉ » portent précisément sur **où un battement peut être écrit**.
Elles sont plausibles et cohérentes entre elles, mais aucune n'est établie par exécution.

> **Règle imposée aux plans** : toute accroche de hook retenue doit **soit** être prouvée par une
> tâche de vérification exécutée dans la phase, **soit** être conçue pour rester correcte si
> l'accroche ne se déclenche jamais. Aucun plan ne doit produire un mécanisme qui casse
> **silencieusement** quand l'hypothèse est fausse — ce serait exactement le mode de défaillance
> que la Phase 33 existe pour supprimer.

## Faits utiles au design

- Les événements de cycle de vie **`SubagentStart` / `SubagentStop` se déclenchent côté session
  principale** : si cela se confirme, c'est un point d'observation qui **ne demande aucune
  coopération du worker** — intéressant pour « fin de nœud » (WTCH-03) et pour observer un worker
  qui cale, puisque la session du manager reste vivante pendant qu'un sous-agent est bloqué.
- Les événements d'outil transportent `agent_id` et `agent_type` dans leur payload JSON (DOC) —
  ce qui permettrait d'attribuer un battement à un worker précis. **À vérifier avant usage.**
- Forme exec : viser un chemin sous le home passe par les placeholders résolus à l'installation
  (`{{VF_BASH}}`, `{{VF_SCRIPTS}}`), jamais par `"$HOME"`.
