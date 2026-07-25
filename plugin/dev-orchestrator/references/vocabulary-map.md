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

### Artefacts & structure

| Terme GSD | Terme VibeFlow |
|---|---|
| SUMMARY / SUMMARY.md (de phase) | rapport de sprint |
| ROADMAP / ROADMAP.md | feuille de route |
| PLAN / PLAN.md | plan de travail |
| STATE / STATE.md | état du projet |
| REQUIREMENTS / requirements | exigences |
| phase | étape (ou sprint) |
| milestone | jalon |
| phase directories | dossiers d'étapes |

### Amont — le quatuor démarqué

Ces quatre gestes se ressemblent et se départagent par **ce qu'on a en entrée**. Traduire
approximativement ici, c'est faire dérailler le routage : chacun garde son propre label.

| Terme GSD | Terme VibeFlow | Ce qui le déclenche |
|---|---|---|
| brainstorming (superpowers) | **conception de solution** | une idée **déjà formulée** — on dessine le comment |
| explore / idea routing | **idéation** (socratique) / orientation de l'idée | une intuition **floue** — on questionne pour la rendre formulable |
| spike / frontier mode | **expérimentation jetable** / proposition d'expérimentation | une hypothèse technique — on écrit du code **qu'on jette** |
| spec-phase / scope | **périmètre figé** / périmètre | un accord de principe — on fige le **QUOI** |
| mvp-phase / MVP phase | version minimale qui marche | la plus petite tranche livrable d'une étape |
| advisor / researcher / advisor panel | panel de décision | des options déjà identifiées à départager |

### Construction & livraison

| Terme GSD | Terme VibeFlow |
|---|---|
| discuss / discuss-phase | cadrage |
| execute / execute-phase | exécution du plan de travail |
| quick / fast | tâche express |
| autonomous | mode autonome |
| ship | livraison |
| pr-branch / PR branch | branche de livraison |
| new-project | démarrage de projet |

### Qualité, recette & audits

| Terme GSD | Terme VibeFlow |
|---|---|
| verify / verify-work / UAT | recette |
| UAT criteria | critères de recette |
| add-tests | écriture des tests manquants |
| code review | revue de code |
| audit-uat / validate-phase / audit-fix | état des manques (recettes en souffrance, dette d'étape) |
| secure-phase / threat model | audit de sécurité d'étape / modèle de menaces |
| debug | dépannage |
| forensics | post-mortem de cycle |
| workflow (cycle interne) | cycle de travail |
| inbox / triage | arrivées du dépôt / tri |

### Cycle de vie & contexte

| Terme GSD | Terme VibeFlow |
|---|---|
| new-milestone / complete-milestone | ouverture / clôture de jalon |
| milestone-summary | bilan de jalon |
| phase (CRUD d'étapes) | édition de la feuille de route |
| undo / rollback | retour arrière |
| capture / seed | prise de note / graine d'idée |
| backlog / review-backlog | réserve |
| cleanup | ménage |
| progress / next | point d'avancement |
| map-codebase / codebase map | cartographie du code |
| resume-work | reprise de contexte |
| pause-work / handoff | passation |
| docs-update | mise à jour de la doc |
| extract-learnings | apprentissages |
| graphify / knowledge graph | graphe de connaissance |

### Jamais exposé

| Terme GSD | Terme VibeFlow |
|---|---|
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
5. **Ne pas confondre traduction et routage** : cette table dit *comment nommer* une sortie,
   `intent-routing.md` dit *où va* une intention. Un label emprunté au voisin (« idéation » pour
   la conception de solution, par exemple) casse le routage — chaque geste garde le sien.
