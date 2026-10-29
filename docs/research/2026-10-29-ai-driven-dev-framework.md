# AI-Driven Dev Framework — ce que VibeFlow en retient, et ce qu'on peut lui apporter

> Note de recherche, 2026-10-29, session principale (Samuel). Ce n'est **pas** une décision :
> aucun emprunt n'est cadré ici, sauf le renvoi du `03-check` d'AIDD ajouté à SEED-002
> (`.planning/seeds/SEED-002-convergence-des-boucles-de-revue.md`). Les autres points sont des
> entrées pour les phases qui les recoupent (52, 55, équipe produit).

## Ce qu'est AIDD

Marketplace de plugins publiée par la communauté AI-Driven Dev (`ai-driven-dev/framework`, MIT,
créée le 2026-02-06, ~540 étoiles et 60 forks au 2026-10-29). Mainteneurs : Baptiste Lafourcade
(684 commits), Alex Soyer (171). 9 plugins, 51 skills, 2 agents (`checker`, `executor`) :

| Plugin | Contenu |
|---|---|
| `aidd-context` | onboarding, banque de mémoire projet, génération de skills / règles / agents / hooks, `10-learn` |
| `aidd-dev` | plan, implement, assert, audit, review, test, refactor, debug, `09-for-sure`, batch |
| `aidd-orchestrator` | `01-sdlc` (cadrer → livrer → vérifier → PR), `00-async-dev` (issue → PR en CI), backlog |
| `aidd-pm` | three amigos, product brief, epic, user story, PRD, spec, spike, defect, task |
| `aidd-refine` | brainstorm, challenge, shadow areas, fact-check, improve |
| `aidd-vcs` | init, commit, PR, tag de release, issue, conflit |
| `aidd-telemetry` (bêta) | tokens par tâche, ticket, modèle, outil, jour — registre local |
| `aidd-qa` (nouveau) | QA d'acceptation, scénarios navigateur, preuve vidéo |
| `aidd-ui` (alpha) | squelette |

Un CLI TypeScript (`@ai-driven-dev/cli`, ~158 k lignes tests compris) traduit les artefacts,
écrits en syntaxe Claude Code, vers Cursor, Copilot, Codex, OpenCode et Kilo, en mode marketplace
ou copie à plat dans le projet. Releases par release-please.

## Comparaison avec VibeFlow

Pas la même altitude : AIDD est une boîte à outils SDLC sobre, pensée pour des équipes et des
petits modèles (« Spend tokens like they cost something ») ; VibeFlow est un système d'équipes
d'agents, plus profond et plus lourd.

| Axe | Plus avancé |
|---|---|
| Orchestration (head → manager → workers, DAG, verrous, compartiments) | VibeFlow |
| Gardes machine (budget d'instructions, G-1..3, ajout/retrait, ~75 ADR) | VibeFlow |
| Couverture hors dev (design, growth, contenu, pilotage, KPI) | VibeFlow |
| Distribution multi-outils industrialisée | AIDD |
| Packaging et releases automatisés | AIDD |
| Amont produit (`aidd-pm`) | AIDD |
| Autonomie (aucune dépendance) — VibeFlow dépend de GSD et superpowers | AIDD |
| Adoption, communauté, gouvernance ouverte | AIDD |

## Ce qu'on retient (candidats)

1. **Pipeline asynchrone issue → PR** (`plugins/aidd-orchestrator/skills/00-async-dev`) — label
   `to-implement` → implémentation en GitHub Actions, label `to-review` → traitement des
   commentaires de revue ; mode local par script de polling. Aucun équivalent chez nous (`vf-auto`
   est local).
2. **Télémétrie par tâche** (`plugins/aidd-telemetry`) — lit les fichiers de session Claude Code et
   Codex, compte chaque appel une fois, n'attribue une tâche que si elle est déclarée. Entrée de la
   **Phase 52** (télémétrie et coût de mission) : lire ce design avant de construire.
3. **Traducteur multi-hôtes** (`cli/src/contexts/tools`, profils et capacités par hôte) — entrée de
   la **Phase 55** et de la décision de rendre l'installeur multi-runtime (2026-08-28). Modèle à
   étudier, pas code à reprendre.
4. **Étape Check** (`plugins/aidd-orchestrator/skills/01-sdlc/references/03-check.md`) — après une
   revue verte, le même checker conteste que le résultat est fiable et sert l'utilisateur ; « a
   finding already acted on is never routed twice ». Renvoi ajouté à SEED-002.
5. **QA d'acceptation** (`plugins/aidd-qa/skills/01-acceptance-qa`) — chaque scénario remonte à un
   critère d'acceptation, jamais au diff ; preuve vidéo nommée. Pas d'équivalent web chez nous.
6. **Amont produit** (`plugins/aidd-pm`) — source pour le rôle product du jalon équipe produit, en
   gardant l'alignement de vocabulaire décidé (SEED-001, A-10).

## Ce qu'on écarte

- **`09-for-sure`** : agit à la place de l'utilisateur (création de comptes, génération de clés,
  approbations). Contraire à ADR-031 et au ship toujours gaté humain.
- L'installation du framework à côté de VibeFlow : doublon des commandes de dev (pas de couche de
  synonymes).

## Ce que VibeFlow peut apporter à AIDD

Règles d'entrée (`CONTRIBUTING.md`, `GOVERNANCE.md`) : issue validée par un membre certifié avant
toute PR ; branche depuis `next`, PR vers `next` ; pas de CLA ; syntaxe Claude Code seulement ;
test sur Claude et un autre outil. Les arbitrages de roadmap se font sur leur Discord le jeudi.

| Issue AIDD | Notre apport |
|---|---|
| #952 un test généré protège-t-il le comportement ? | la mutation, déjà dans notre gradation de revue (`mission-flow.md` §3) |
| #1079 tester ce qu'une skill fait faire à un agent | « une preuve doit pouvoir rendre rouge », boucle d'éval de `skill-creator` |
| #942 faits de mémoire qui se périment sans marqueur | `consolidator`, faits datés et vérifiés de la mémoire vivante |
| #929 frontière de portabilité entre hôtes | mesures des Phases 37-38 (Codex lit le descripteur Claude ; kimi ≠ kimi-code) |
| #980 version installée et avis de mise à jour | livré chez nous (`/vf-update`, bandeau SessionStart) ; issue assignée : retour d'expérience en commentaire |

## Sources

- Dépôt : https://github.com/ai-driven-dev/framework (lu au commit `1a88102`, 2026-10-29) —
  `README.md`, `CONTRIBUTING.md`, `GOVERNANCE.md`, `plugins/*/skills/*/SKILL.md`,
  `plugins/aidd-orchestrator/skills/01-sdlc/references/03-check.md`, `plugins/aidd-telemetry/README.md`,
  `cli/`.
- Issues ouvertes : `gh issue list -R ai-driven-dev/framework`, 2026-10-29.
