# Elephant-Goldfish Model (Google) — ce que VibeFlow en retient, et ce qu'on peut lui apporter

> Note de recherche, 2026-10-29, session principale (Samuel). Ce n'est **pas** une décision : le
> seul emprunt cadré est la règle de convergence des boucles de revue, posé en graine
> (`.planning/seeds/SEED-002-convergence-des-boucles-de-revue.md`) pour le jalon V2. Les autres
> points restent des candidats.

## Ce qu'est EGM

Plugin de spec avant le code publié par Google le 2026-09-13 (`google/elephant-goldfish-model`,
Apache-2.0, ~5,3 k étoiles au 2026-10-29), tiré de l'essai de Dave Rensin. Deux rôles d'agent :

- **Elephant** — l'agent à contexte profond (projet, exigences, décisions passées) : interroge
  l'humain, rédige la spec ;
- **Goldfish** — des relecteurs à **contexte nul**, qui ne voient que le document et les sources
  qu'il cite, jamais la conversation : ils cherchent les hypothèses non dites.

L'humain tranche les arbitrages et approuve la spec avant toute implémentation. Contenu :
7 skills (`egm-brainstorm`, `egm-draft`, `egm-review`, `egm-review-loop`, `egm-resolve`,
`egm-bootstrap`, `egm-drift-report`), 9 personas de relecteurs (`agents/`), 5 grilles
(`resources/document_standards/`). Distribué pour Claude Code, Codex et Antigravity ; Cursor,
Copilot CLI et OpenCode en expérimental.

## Recouvrement avec VibeFlow

Fort. Le pipeline brainstorm → draft → review → resolve fait le travail de GSD (discuss, plan,
`gsd-plan-checker`) et de nos juges frais (`vf-design-judge`, `content-clarity-judge`,
`growth-quality-judge`). On ne l'installe pas : ni couche de synonymes (bascule agentique,
2026-07), ni catalogue tiers en dépendance (décision du 2026-08-28). On emprunte des mécanismes.

## Ce qu'on retient

1. **Règle de convergence des boucles de revue** (EGM PR #168, `skills/egm-review-loop/SKILL.md`
   §2.4). Un point *réglé* (contesté, ou risque accepté) n'est jamais rouvert. Un point *corrigé*
   est rouvert s'il réapparaît au même endroit. Un tour est *propre* sans bloquant ni majeur non
   réglé ; un relecteur non exécuté rend le tour sale. Arrêt sur **deux tours propres
   consécutifs**, plafond 5, et **churn** : un nouveau point tombe sur la portée d'un correctif
   qu'il suffirait d'annuler pour le faire disparaître → arrêt et question à l'humain. Chez nous,
   les boucles reviewer → coder (`mission-flow.md`) et juge → crafter (`mission-cross-team.md`)
   n'ont qu'un plafond de 3 tours et G5 (`team-kernel.md`). **Cadré en graine : SEED-002.**
2. **Test du lecteur naïf** (`agents/comprehension.md`) — un relecteur sans contexte liste ce qui
   lui manque pour comprendre le document. Cible chez nous : le digest de mission que le manager
   envoie aux workers, dont personne ne vérifie qu'il se suffit à lui-même.
3. **Sonde d'isolation par marqueur** (`tests/integration/test_claude.py`) — le parent reçoit un
   marqueur UUID que l'enfant ne doit pas connaître, avec un témoin positif (lecture de la persona
   réussie, réponse attendue présente). Nos juges déclarent un « regard frais » sans preuve
   machine ; cette sonde le rendrait vérifiable (doctrine : un négatif aveugle ne prouve rien).
4. **Relecteur « zoom out »** (`resources/document_standards/zoom-out-standard.md`) — simplicité,
   YAGNI, réutilisation de l'existant, avant d'ajouter une brique. Outillerait SOBR « un ajout = un
   retrait », tenue à la main aujourd'hui.

Secondaires : quatre issues de résolution `CONTEST` / `PROPOSE FIX` / `ESCALATE` / `DECLINE`
(EGM PR #167), plus fines que notre `action: ask-user` ; `egm-drift-report`, comparaison
spec ↔ code, que `check-divergence` ne couvre pas (il compare le planning à lui-même).

## Ce qu'on écarte

- Le pipeline complet et ses commandes : doublon de GSD.
- Les artefacts « hors chat » obligatoires : nos rapports typés et le plan de bataille le font
  déjà.
- La revue séquentielle en cinq étages pour toute spec : notre gradation est par risque, jamais
  par volume (`mission-flow.md` §3).

## Ce que VibeFlow peut apporter à EGM

Règles d'entrée du dépôt (`CONTRIBUTING.md`, `AI_POLICY.md`) : CLA Google ; un humain auteur qui
défend chaque ligne lui-même ; au-delà de 100 lignes hors tests ou à partir de 3 fichiers de
`skills/` ou `agents/`, parcours en deux temps (issue → `design-ready` → PR de spec → PR de code).
Une PR mergée fait de l'auteur un *contributeur*, pas un collaborateur au sens GitHub.

| Issue EGM | Ce qu'on y apporte | Parcours |
|---|---|---|
| #221 parcours de contribution en tête de `CONTRIBUTING.md` | rien de spécifique ; premier merge, CLA passé | direct |
| #59 diagnostic d'installation en lecture seule | détection d'état de `/vf-update`, scripts `check-*` ; « une capacité inconnue reste inconnue » | issue + spec |
| #112, #60 mêmes tests sur tous les hôtes, bundles vérifiés | install + usage prouvés de bout en bout sur Codex et Kimi (Phases 37-38) | issue + spec |
| #63 reprise d'une revue interrompue | `driver-lock.sh`, état du DAG, TTL ; « un verrou périmé ne veut pas dire mission morte » | issue + spec, différé par les mainteneurs |

Vérifié et écarté comme contribution : leur sonde d'isolation a bien un témoin positif ; la
règle de convergence existe déjà chez eux.

## Sources

- Dépôt : https://github.com/google/elephant-goldfish-model (lu au commit `f0ba151`, 2026-10-29) —
  `README.md`, `docs/designs/architecture.md`, `skills/egm-review-loop/SKILL.md`,
  `skills/egm-resolve/SKILL.md`, `agents/`, `tests/integration/test_claude.py`, `CONTRIBUTING.md`,
  `AI_POLICY.md`, `AGENTS.md`.
- Issues ouvertes et PR mergées : `gh issue list` / `gh pr list -R google/elephant-goldfish-model`,
  2026-10-29.
- Essai d'origine : Dave Rensin, « Elephants, Goldfish, and the New Golden Age of Software
  Engineering » (Medium, 2026).
