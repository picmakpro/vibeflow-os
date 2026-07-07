# Table de traduction de vocabulaire — GSD → VibeFlow

> **Rôle** : référence consultée par l'agent `vibeflow-dev` et par les verbes `/vf-*`
> pour **reframer toute sortie** avant de la présenter à l'utilisateur. Couvre ABS-02.
>
> **Iron Law** : *l'utilisateur ne lit jamais un terme GSD/Superpowers — il ne parle que VibeFlow.*

---

## Périmètre

> **Traduction du vocabulaire exposé uniquement** — pas une traduction exhaustive des
> artefacts (les fichiers gardent leur nom interne ; seul le langage présenté à
> l'utilisateur est traduit). La traduction exhaustive des artefacts est différée en v2
> (cf. VOC-01).

---

## Table de traduction

| Terme GSD | Terme VibeFlow |
|---|---|
| SUMMARY / SUMMARY.md (de phase) | rapport de sprint |
| ROADMAP / ROADMAP.md | feuille de route |
| PLAN / PLAN.md | plan de travail |
| phase | étape (ou sprint) |
| milestone | jalon |
| verify / verify-work / UAT | recette |
| code review | revue de code |
| execute / execute-phase | exécution du plan de travail |
| discuss / discuss-phase | cadrage |
| brainstorming | exploration / idéation |
| debug | dépannage |
| ship | livraison |
| autonomous | mode autonome |
| quick / fast | tâche express |
| map-codebase | cartographie du code |
| new-project | démarrage de projet |
| progress / next | point d'avancement |
| advisor / researcher / advisor panel | panel de décision |
| STATE / STATE.md | état du projet |
| REQUIREMENTS / requirements | exigences |
| plan / planner agent | (interne — ne pas exposer) |
| GSD / Superpowers / get-shit-done | (plomberie interne — JAMAIS exposé) |

---

## Règles d'usage

1. **Aucune fuite de plomberie** : ne jamais prononcer « GSD », « Superpowers », ni un
   nom de skill brut (`gsd-execute-phase`, `gsd-verify-work`, …) côté utilisateur.
2. **Reframe systématique** : toute sortie d'un outil interne traverse cette table avant
   d'être présentée.
3. **Conserver le français** : le projet est francophone — la sortie utilisateur l'est aussi.
4. **Cohérence** : utiliser le même terme VibeFlow d'une sortie à l'autre (pas de synonymes
   improvisés hors de cette table).
