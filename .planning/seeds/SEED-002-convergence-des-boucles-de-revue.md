---
id: SEED-002
status: dormant
planted: 2026-10-29
planted_during: equipe-produit-v1.0 en clôture (Phase 59 exécutée non mergée, jalon V2 à créer — `.planning/notes/2026-10-29-HANDOFF-jalon-v2.md`)
trigger_when: "création du jalon V2 (`/gsd-new-milestone`, nom proposé `vibeflow-v2.0`) — à proposer comme phase de ce jalon, après la Phase 1 vf-signal"
scope: phase
source_spec: docs/research/2026-10-29-elephant-goldfish-model.md
---

# SEED-002 : Convergence des boucles de revue — arrêter sur stabilité, pas seulement sur plafond

## Why This Matters

Nos boucles de correction s'arrêtent sur un verdict `passed` ou sur le plafond de 3 tours :
reviewer → coder (`plugin/dev-orchestrator/references/mission-flow.md`, budget partagé par étape,
D-25) et juge → crafter (`mission-cross-team.md`, 3 tours par écran). G5
(`plugin/conductor/references/team-kernel.md`) ajoute qu'un même verdict revenu deux fois appelle
l'édition de la source. Trois trous restent :

1. **Un point contesté revient.** Un relecteur frais peut relever au tour 2 un point que le
   manager a écarté au tour 1 : rien ne garde la trace des points réglés, le budget brûle sur un
   débat déjà tranché.
2. **Le churn n'a pas de nom.** Un correctif qui crée le point suivant (annuler le correctif le
   ferait disparaître) passe pour un nouveau problème, et la boucle tourne jusqu'au plafond.
3. **Un `passed` unique est un tirage.** Un relecteur frais échantillonne différemment à chaque
   tour : un tour sans point ne prouve pas que le suivant n'en trouvera pas.

EGM (Google) a tranché ces trois points en PR #168 (`skills/egm-review-loop/SKILL.md` §2.4) :
liste de points réglés jamais rouverts, point corrigé rouvert s'il réapparaît, tour propre = aucun
bloquant ni majeur non réglé (relecteur non exécuté = tour sale), arrêt sur deux tours propres
consécutifs, plafond 5, churn → arrêt et question à l'humain. Étude : `source_spec`.

## When to Surface

À la création du jalon V2 (`/gsd-new-milestone`). Pas avant : le jalon `equipe-produit-v1.0` est
en clôture et n'accueille plus de phase (handoff du 2026-10-29).

## Cadrage déjà posé

Origine : arbitrage Samuel, message session principale, 2026-10-29 (« ok a b » — veille EGM écrite
et adoption de la règle de convergence cadrée en GSD). Rien d'autre n'est tranché ; les points
ci-dessous sont des **contraintes constatées**, pas des décisions.

- **D-25 tient.** Le budget de 3 tours ne bouge pas sans mesure réelle. La règle de convergence
  change le **critère d'arrêt**, pas le plafond.
- **G5 tient.** « Point corrigé qui réapparaît » recoupe G5 : la phase articule les deux sans
  doublon (G5 = la source est fautive ; réouverture = le correctif est faux).
- **Rapports typés.** La liste des points réglés vit dans le plan de bataille ou le rapport de
  mission, pas dans la mémoire du manager (survit à une reprise de mission).
- **Gradation par risque** (`mission-flow.md` §3) : deux tours propres doublent le coût d'une revue
  qui passe. La question est où l'exiger (revue pleine seulement ?), pas s'il faut l'exiger partout.

## Questions ouvertes pour le discuss

| # | Question |
|---|---|
| Q-01 | Deux tours propres partout, en revue pleine seulement, ou sur les juges design seulement ? |
| Q-02 | Le second tour propre consomme-t-il le budget partagé de l'étape ? |
| Q-03 | Identité d'un point (« même portée, même problème ») : qui la juge, sur quelle clé ? |
| Q-04 | Churn : détection par le manager, ou champ du rapport du reviewer ? |
| Q-05 | Étendre aux boucles de `mobile-test-team` (anti-thrash par flow) ou les laisser hors périmètre ? |

## Candidats voisins (même étude, non cadrés)

Test du lecteur naïf sur le digest de mission ; sonde d'isolation par marqueur pour les juges
frais ; relecteur « zoom out » avant l'ajout d'une brique. Voir `source_spec` § « Ce qu'on
retient ». Ils ne voyagent pas avec cette graine sans nouvel arbitrage.
