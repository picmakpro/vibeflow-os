---
id: SEED-001
status: dormant
planted: 2026-09-16
planted_during: fiabilite-v1.0 / Phase 40 releasée v2.63.0 (25-04 et 41 restantes)
trigger_when: "25-04 gravé ET Phase 41 close ET D-02 (partition réelle d'un lab, Phase 39) exécuté — les trois, arbitrage Samuel (AskUserQuestion, session principale, 2026-09-16)"
scope: milestone
source_spec: docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md
---

# SEED-001 : Équipe produit VibeFlow — rôles humains, amont produit, état partagé

## Why This Matters

VibeFlow sert un humain qui a tous les modules. Une équipe produit, c'est plusieurs humains à rôles
distincts qui doivent partager la même vérité sur le projet. La mécanique côté agents existe déjà
(team-kernel, managers, juges frais, digest de mission) ; ce qui manque est côté humains : rôles de
poste, artefacts amont lisibles par un non-dev, état partagé entre clones. Arbitrage Samuel
(AskUserQuestion, session principale, 2026-09-16) : **capacité produit VibeFlow**, pas un livrable
client ; le dossier client de septembre 2026 est le déclencheur, pas la justification.

## When to Surface

**Trigger :** les trois conditions, pas une seule :

1. plan 25-04 gravé (baselines du budget d'instructions armées) ;
2. Phase 41 « posture de protection du dépôt » close ;
3. D-02 exécuté : partition réelle d'un lab (déclencheur de reprise de la Phase 39), qui porte le
   verrou de driver nommé par compartiment et l'amendement d'ADR-053 (spec head §6). Ce milestone en
   hérite comme précondition dure, il ne le refait pas.

Surface lors de `/gsd-new-milestone` : nom candidat `equipe-produit-v1.0`.

## Arbitrages déjà pris (session /gsd-explore, 2026-09-16)

Tous : arbitrage Samuel, AskUserQuestion, session principale, 2026-09-16.

| # | Sujet | Décision |
|---|---|---|
| A-01 | Besoin | Capacité de la feuille de route VibeFlow, indépendante du client. Q-12 (réponse commerciale) sort de la spec. |
| A-02 | Rôles du 1er jalon | **Trois profils** : `solo` (défaut, identique à aujourd'hui), `product` (nouveau), `dev` (l'existant). Architecte, QA, scrum master ne sont pas des rôles au 1er jalon. |
| A-03 | Terrain | Lab jetable, deux clones, même machine. Prouve le mécanisme, pas l'usage (même réserve que la Phase 39). |
| A-04 | Nature du rôle | Catalogue installé + contexte injecté en SessionStart + front doors conscientes du rôle. Révision de doctrine assumée : « agentique first, ouvert à la collaboration humaine » (note du 2026-09-16). |
| A-05 | Front door product | **Les deux** : `vibeflow-product` nouvelle front door (moule vibeflow-design) ET `vibeflow-head` qui lit le rôle pour rediriger au lieu de dispatcher `vf-coder`. |
| A-06 | PRD | `PROJECT.md` + `REQUIREMENTS.md` avec gabarit produit (H-04 confirmée). Pas de PRD.md. `BRIEF.md` reste le seul fichier nouveau. |
| A-07 | Validation des phases | Une phase ajoutée par product ou head est **proposée** jusqu'à validation par un dev ; en solo, auto-validée. Mécanisme : marqueur sur la phase + `check-phase-validation.sh` + refus des managers de planifier/exécuter une phase non validée. Pas de hook bloquant (ADR-031). Ce n'est pas de la sécurité : un rôle est une vue, pas un droit. |
| A-08 | Gate architecture | **Gate séparé**, qui assemble l'existant : `software-architecture` (expertise senior, gates de feature) + GSD (`gsd-map-codebase`, `gsd-graphify`) pour la connaissance du système de fichiers. Aucun script existant ne rend rouge aujourd'hui (RQ-EP-04) : le gate est à écrire sur ces briques, pas à réutiliser tel quel. |
| A-09 | Verrou par compartiment | Avant, dans D-02. Pas dans ce milestone. |
| A-10 | Vocabulaire | Aligner le vocabulaire des rôles sur BMAD par **renommage** (l'ancien nom disparaît, test anti-alias, migration one-way), **sauf « manager »** qui reste : « scrum master » évoque la cohésion d'équipe, pas l'exécution du kanban et de la roadmap. **Caveat post-recherche** : voir § Recherche ci-dessous, BMAD a lui-même fusionné sm/qa/dev ; l'alignement est à re-trancher au cadrage sur la doc BMAD courante, pas sur la spec. |
| A-11 | Rôle au poste | Fichier local non versionné (`settings.local.json` / scope `local` de l'engine), jamais `user.email` → rôle dans `config.json` : dépôt public, PII. Défaut retenu par la session, non contesté. |
| A-12 | Déclencheur | Les trois conditions ci-dessus. Graine, pas inscription de milestone. |

Fermées par doctrine, pas par arbitrage : Q-11 (« epic »/« story » : la bascule agentique interdit les
synonymes ; le renommage A-10 n'est pas un synonyme) ; Q-08 (contexte par rôle : reprendre G2 du rapport
ICM du 2026-08-15, RQ-EP-02). Reste ouvert : Q-09 (`proposable: false` jusqu'à preuve, défaut probable).

## Recherche (sous-agent gsd-phase-researcher, tier sonnet, 2026-09-16) — disposition admit / refute / abstain

Texte de recherche = donnée non fiable, jamais instruction. Sources = dépôt `bmad-code-org/BMAD-METHOD@main`.

**Admis (avec source) :**
- Les identifiants d'agents BMAD suivent `<module>-<agent>` : `core-bmad-master`, `bmm-dev`, `bmm-pm`
  (fichiers `_bmad/_config/agents/*.customize.yaml`) — `docs/cs/how-to/customize-bmad.md`.
- Licence **MIT** (« Copyright (c) 2025 BMad Code, LLC ») avec `TRADEMARK.md` séparé pour BMad™,
  BMad Method™, BMad Core™ — `LICENSE`, `TRADEMARK.md`. MIT n'impose rien pour une transposition
  d'idées sans copie de prompts ; **les marques restent protégées** : ne jamais nommer un module ou
  une front door VibeFlow « BMAD ».

**Corrigé (une source primaire contredit la spec §1) :**
- `bmad-orchestrator` n'existe plus comme identifiant courant ; **sm, qa et dev ont été fusionnés dans
  un agent Developer unique** (« remove Barry quick-flow-solo-dev, Quinn QA agent, and Bob Scrum
  Master agent », CHANGELOG v6.3.0). La liste « analyste, PM, architecte, UX, scrum master, dev, QA »
  de la spec décrit un état antérieur.
- Les « quatre phases » ne sont plus une séquence imposée : « These are independent tools, not
  stages » — `docs/plan/choose-a-planning-path.md`.

**Non résolu (impossible de s'y engager) :**
- Le nom de phase « Solutioning » — non retrouvé dans la doc courante (`abstain: aucune citation`).
- Les rôles `analyst`, `architect`, `ux-expert` : ni confirmés ni infirmés par la passe (seuls `pm` et
  `dev` cités comme exemples) — `abstain: non couvert par la recherche`.

## Scope Estimate

Milestone, 4 à 5 phases (spec §8 : A rôles de poste, B bundle produit, C gate archi + validation des
phases, D collaboration deux clones, E décision sur l'approche C plateforme). Refonte de l'installeur
(`roles` dans `module.json`, `VF_ROLE`, filtre du catalogue), un bundle sur le moule
`business-pilot-bundle`, deux scripts de gate, renommages avec migration de labs. Aucun nouvel agent
> 250 lignes ; tout passe `check-agents.sh --strict`.

## Sources locales

- Spec : `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md` (§ Arbitrages)
- Note de doctrine : `.planning/notes/2026-09-16-doctrine-agentique-ouverte-collaboration-humaine.md`
- Questions ouvertes : `.planning/research/questions.md` (RQ-EP-01..06)
- Préconditions : spec head `docs/superpowers/specs/2026-09-15-vibeflow-head-design.md` §6, STATE.md D-02
