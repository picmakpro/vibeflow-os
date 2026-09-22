# Index — plugin/dev-orchestrator/references/

> Cet index existe pour qu'un agent choisisse un fichier sans les ouvrir tous. Il est posé à
> partir de plus de 10 fichiers dans un dossier de références. Il liste, il ne fait pas
> autorité.

| Fichier | Résumé |
|---|---|
| [GSD-PIPELINE.md](GSD-PIPELINE.md) | Doctrine de pipeline GSD complète, chargée on-demand par `vibeflow-head` / `vf-dev-manager` (règle 1%). |
| [autonomous-guardrails.md](autonomous-guardrails.md) | Garde-fous des boucles autonomes (`vf-auto` et assimilés) : quand une boucle s'arrête d'elle-même. |
| [docs-flow.md](docs-flow.md) | Source de vérité de la sortie documentaire : les quatre familles de docs que `vibeflow-head` distingue (DOCF-01→04). |
| [gsd-capabilities-index.md](gsd-capabilities-index.md) | Index auto-généré des capabilities du moteur GSD — ne pas éditer à la main. |
| [gsd-skills-index.md](gsd-skills-index.md) | Index auto-généré des skills GSD installés — ne pas éditer à la main. |
| [head-governance.md](head-governance.md) | Les quatre compétences du head : règle d'échelle, séquencement, contrat de sortie, économie. |
| [ingestion-flow.md](ingestion-flow.md) | Doctrine du pont spec/plan → feuille de route : comment `vibeflow-head` détecte une spec/plan à ingérer (BRDG-01/03). |
| [intent-routing.md](intent-routing.md) | Carte d'intention complète : quelle formulation utilisateur route vers quelle brique outillée. |
| [mission-contracts.md](mission-contracts.md) | Contrats de mission de l'équipe manager : ce qui relie la conversation principale et les managers d'équipe. |
| [mission-cross-team.md](mission-cross-team.md) | Doctrine business des étages croisés entre `vf-dev-manager` et `vf-design-manager` (Phase 15, étend ADR-053). |
| [mission-flow.md](mission-flow.md) | Les patterns de sûreté du contrôle de flux de mission que `vf-dev-manager` doit suivre (Patterns A à I, ADR-053), dont le registre des agents dispatchés et la reprise après arrêt sur chien de garde (Pattern I, issue #82). |
| [workstreams.md](workstreams.md) | Doctrine du compartiment de planning workstreams du moteur GSD : surface réelle, résolution, risques (GSDA-13→17). |

Cet index doit rester cohérent avec le contenu du dossier.
