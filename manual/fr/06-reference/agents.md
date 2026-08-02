# Agents

<!-- vf-manual:lang -->
**Français** · [English](../../en/06-reference/agents.md)
<!-- /vf-manual:lang -->

Cette page est une **table de recherche** : tu y viens pour trouver un agent par son nom, vérifier
son module d'origine, ou savoir s'il tourne en opus ou en sonnet. Elle ne raconte rien du
fonctionnement en équipe — pour ça, va sur
[les-agents-livres.md](../05-equipe-agents/les-agents-livres.md), qui explique les trois familles
(agents que tu invoques, managers de mission, workers internes) en profondeur. Cette page-ci ne
reprend pas cette explication ; elle se contente de la table complète, une ligne par agent.

Un agent n'est jamais l'entrée par laquelle tu formules une demande — c'est le
[skill](./skills.md) qui joue ce rôle, en captant ta phrase en langage naturel. L'agent est ce que
le skill invoque ensuite pour faire le travail. Si tu cherches « comment déclencher X » plutôt que
« qui est X », c'est la page skills qu'il te faut, pas celle-ci.

## Comment lire le tableau

**Famille** dit comment l'agent entre en jeu : *face* = tu peux l'invoquer directement, par son nom
ou par une phrase qui relève de son domaine. *Manager* = jamais invoqué directement, c'est le mode
autonome ou un routeur de domaine qui le déploie quand la taille du travail le justifie. *Worker* =
jamais invocable du tout, dispatché uniquement par un manager avec un mandat précis. Parcourir la
colonne Famille de haut en bas avant de lire une ligne isolée est en général le moyen le plus rapide
de savoir si un agent donné fait partie de ceux à qui tu peux parler directement.

**Modèle** dit quel modèle Claude exécute l'agent — le détail de ce que ça change, et comment tu
maîtrises ta dépense, vit dans [couts-et-modeles.md](./couts-et-modeles.md). Ni l'une ni l'autre
colonne n'est une promesse sur le comportement au-delà du choix de modèle lui-même — c'est un fait
que tu peux retrouver toi-même à tout moment, depuis ce même frontmatter.

Cette table n'a pas de colonne « module installé chez toi » : tu n'auras réellement que les agents
dont le module correspondant est présent dans ton lab. Le
[catalogue des modules](../03-modules/catalogue.md) fait le lien inverse — module par module,
plutôt qu'agent par agent.

## Les 31 agents

| Agent | Module | Famille | Modèle | Rôle en une phrase |
|---|---|---|---|---|
| `campaign-analyst` | growth-bundle | worker | sonnet | Calcule CAC/ROAS par canal, verdict GO/ITERATE/KILL sur une campagne lancée. |
| `channel-strategist` | growth-bundle | worker | sonnet | Transforme un brief en fiche de stratégie canal/ICP. |
| `content-clarity-judge` | content-bundle | worker | sonnet | Juge de clarté d'une pièce de contenu, rubric /100, lecture seule. |
| `copywriter-sequences` | growth-bundle | worker | sonnet | Rédige les séquences et créatives d'une campagne validée. |
| `growth-quality-judge` | growth-bundle | worker | sonnet | Juge qualité anti-slop des livrables de campagne. |
| `quality-gate-client` | business-pilot-bundle | worker | sonnet | Juge tout livrable destiné au client contre une rubric /100. |
| `skill-creator` | skill-creator | face | opus | Fabrique de nouveaux skills en 5 phases, avec boucle de recherche. |
| `vf-app-fixer` | mobile-test-team | worker | sonnet | Corrige le code applicatif pour faire passer un test Maestro. |
| `vf-auditer` | dev-orchestrator | worker | sonnet | Audit sécurité et dette technique d'une étape de dev. |
| `vf-business-commercial` | business-pilot-bundle | worker | sonnet | Qualifie les leads, rédige devis et relances commerciales. |
| `vf-business-delivery` | business-pilot-bundle | worker | sonnet | Suit la livraison des prestations vendues, prépare les livrables. |
| `vf-business-finance` | business-pilot-bundle | worker | sonnet | Prépare factures, relances de paiement, prévisions. |
| `vf-business-manager` | business-pilot-bundle | manager | opus | Pilote une mission business : plan, dispatch, contrôle de flux. |
| `vf-coder` | dev-orchestrator | worker | sonnet | Pilote le cycle de dev d'une étape (cadrage → plan → exécution). |
| `vf-content-manager` | content-bundle | manager | opus | Pilote une mission éditoriale : plan, dispatch, contrôle de flux. |
| `vf-content-repurposer` | content-bundle | worker | sonnet | Décline une pièce validée en variantes multi-plateformes. |
| `vf-content-strategist` | content-bundle | worker | sonnet | Transforme un brief en fiche de cadrage éditorial. |
| `vf-content-writer` | content-bundle | worker | sonnet | Produit le livrable de contenu final à partir d'une fiche validée. |
| `vf-crafter` | design-orchestrator | worker | sonnet | Produit specs et tokens design pour un écran ou composant. |
| `vf-design-judge` | design-orchestrator | worker | sonnet | Juge critique d'un écran contre la direction artistique, rubric /100. |
| `vf-design-manager` | design-orchestrator | manager | opus | Pilote une mission design : plan, dispatch, contrôle de flux. |
| `vf-dev-manager` | dev-orchestrator | manager | opus | Pilote une mission de dev : plan, dispatch, contrôle de flux. |
| `vf-growth-manager` | growth-bundle | manager | opus | Pilote une mission growth : plan, dispatch, contrôle de flux. |
| `vf-reviewer` | dev-orchestrator | worker | sonnet | Revue de code du diff produit par une mission de dev. |
| `vf-test-orchestrator` | mobile-test-team | manager | sonnet | Pilote la boucle test → corrige → re-test d'une régression mobile. |
| `vf-test-runner` | mobile-test-team | worker | sonnet | Écrit et lance les flows Maestro d'une régression mobile. |
| `vibeflow-conductor` | conductor | face | opus | Gardien du lab : créer, installer/retirer un module, vérifier, migrer. |
| `vibeflow-design` | design-orchestrator | face | opus | Directeur artistique : pilote tout le cycle design en langage naturel. |
| `vibeflow-dev` | dev-orchestrator | face | opus | Routeur de développement : détecte l'intention, invoque la brique. |
| `vibeflow-kpi-analyst` | kpi-analyst | face | sonnet | Déduit et publie les vrais indicateurs métier du lab. |
| `vibeflow-validator` | validator | face | opus | Orchestre les 5 audits de conformité méthodologique du lab. |

Une exception notable dans la colonne Modèle : `vf-test-orchestrator` pilote une mission comme les
cinq autres managers, mais tourne en sonnet et non en opus — sa boucle (test → corrige → re-test
jusqu'au budget épuisé) reste un périmètre borné, sans les arbitrages ouverts d'un plan de bataille
multi-métier. Retiens ce nom si tu compares deux agents « manager » et que leurs modèles diffèrent :
ce n'est jamais une incohérence, c'est le périmètre réel de la mission qui varie d'un métier à
l'autre.

Un dernier repère utile : tous les agents « worker » de cette table déclarent explicitement, dans
leur propre fichier, qu'ils sont internes et dispatchés uniquement par un manager. Ce n'est jamais
une convention de nommage devinée depuis l'extérieur — c'est écrit noir sur blanc dans chacun
d'eux, et c'est ce qui fait qu'aucune commande d'incarnation n'est générée pour eux.

## D'où vient cette liste

Établie en énumérant `plugin/*/agents/*.md` (25 fichiers, un niveau, ce qui exclut les blueprints
sous `content/agents/`) et les 6 fichiers `AGENT.md` à la racine des modules, le 2026-08-01 — soit
trente-et-un agents au total. Pour revérifier depuis la racine du dépôt :
`find plugin -path '*/agents/*.md'` puis `find plugin -maxdepth 2 -name 'AGENT.md'`. Le frontmatter
de chaque fichier (`model:`, `memory:`) est la source du champ Modèle ci-dessus, pas une
reformulation — les champs obligatoires qu'un agent doit porter sont vérifiés par
`plugin/conductor/scripts/check-agents.sh`.

Répartition par modèle, comptée sur la même table : dix agents en opus (les cinq agents « visage »
invocables, plus les cinq managers de mission), vingt-et-un en sonnet (tous les workers, plus
l'unique agent « visage » qui n'est pas en opus — `vibeflow-kpi-analyst`). Cette répartition est ce
qui nourrit la page [couts-et-modeles.md](./couts-et-modeles.md) — elle n'y est pas redite, juste
utilisée.

<!-- vf-manual:nav -->
[← Précédent](../06-reference/skills.md) · [↑ Sommaire](../README.md) · [Suivant →](../06-reference/couts-et-modeles.md)
<!-- /vf-manual:nav -->
