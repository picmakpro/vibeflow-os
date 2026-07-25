# growth-bundle — Équipe growth sur le team-kernel (GrowthFlow)

> Module **installable** du plugin vibeflow-os : l'équipe métier growth/acquisition complète
> construite sur le team-kernel (manager → workers → juge). Il transforme un lab VibeFlow en
> **studio d'acquisition gouverné** : chaîne **brief → stratégie (canal/ICP) → production
> (séquences/créatives) → gate qualité → validation humaine → lancement HUMAIN → analyse
> (CAC/ROAS, verdict GO/ITERATE/KILL)**, avec dispatch parallèle des campagnes et une
> **Iron Law** : tout envoi réel est human-gated.

---

## Ce que le module installe

| Pièce | Rôle | Modèle | Cloisonnement |
|---|---|---|---|
| `vf-growth-manager` | manager de mission : DAG + verrou de driver, dispatch parallèle des campagnes indépendantes, digest par mandat, contrôle de flux sur rapports typés, Iron Law d'acquisition human-gated | opus | exposé — **ne produit jamais** (pas d'Edit, aucune écriture de livrable) |
| `channel-strategist` | fiche de stratégie : canal confirmé (duplication `_TEMPLATE/` si absent), ICP local (delta vs maître), offre activée, hypothèse EXP scorée ICE, seuils CAC/ROAS | sonnet | `vf-internal`, écrit uniquement `campagnes/<slug>/strategie.md` (+ canal dupliqué) |
| `copywriter-sequences` | séquences/créatives ancrées ICP local + offre, ≥ 2 variantes A/B à levier unique, zéro slop, zéro claim non sourcé, opt-out intégré — **n'envoie jamais** | sonnet | `vf-internal`, écrit uniquement `campagnes/<slug>/sequences.md` + index du canal |
| `growth-quality-judge` | juge frais du gate qualité : rubric **/100**, seuil **80**, claim non sourcé **éliminatoire**, non-conformité consentement/RGPD **éliminatoire**, verdict typé | sonnet | `vf-internal`, **read-only** (tools sans Write/Edit) |
| `campaign-analyst` | analyse d'une campagne **lancée par l'humain** uniquement : CAC/ROAS vs seuils, verdict GO/ITERATE/KILL, METRICS/EXPERIMENTS tenus — **aucun chiffre inventé** (métrique sourcée ou « inconnue ») | sonnet | `vf-internal`, écrit uniquement `analyse.md` + fichiers METRICS/EXPERIMENTS du canal |
| skill `vf-growth` | point d'entrée métier : geste simple vs mission (seuil 3 campagnes / signal de durée) | — | — |

## La chaîne (et sa définition du « vert »)

```
BRIEF ─▶ channel-strategist ─▶ copywriter-sequences ─▶ growth-quality-judge (≥80/100)
      ─▶ VALIDATION HUMAINE (jamais auto-validée) ─▶ l'HUMAIN lance (envoi/budget)
      ─▶ campaign-analyst (CAC/ROAS, GO/ITERATE/KILL — sur données réelles uniquement)
```

Une campagne n'est **verte** que si : auto-contrôle anti-slop passé + score du juge ≥ 80/100
sans critère éliminatoire + **validation humaine explicite**. **Iron Law growth (ADR-031,
frontière Tier 2 de `kpi-analyst`)** : tout envoi réel — email, publication, dépense
publicitaire, outreach — est HUMAN-GATED ; en mode autonome, la mission s'arrête à « prête
au lancement » (statut `human_needed`). L'analyse ne tourne qu'après lancement humain
effectif — l'analyst **refuse** une campagne sans preuve de lancement.

## Deux régimes d'usage

- **Geste simple** (« lance une campagne cold email », « analyse les résultats »,
  « active un nouveau canal ») : le skill `vf-growth` déroule la chaîne courte — un étage
  à la fois, gate + juge + validation humaine compris.
- **Mission** (≥ 3 campagnes/séquences ou signal de durée : « la vague du mois », « en
  autonomie ») : `vf-growth-manager` prend le pilotage — plan de bataille en DAG (5 nœuds
  par campagne : stratégie → production → gate → humain → analyse), verrou de driver,
  **dispatch parallèle** des campagnes indépendantes (un dossier `campagnes/<slug>/` par
  campagne, périmètres disjoints ; séquentialisation si canal partagé), digest ≤ 30 lignes
  par mandat, halt conditions, rapport de mission avec file d'attente de validation.

## Prérequis côté lab

Le lab doit porter le référentiel growth (`growth/` : `ICP.md`, `OFFRES.md`, `FUNNEL.md`,
`METRICS.md` + `channels/<canal>/` à 5 fichiers et `channels/_TEMPLATE/` — spec :
`content/domain/extension-spec.md`) — posé par `vf-planning` (profil standard) ou
`vf-new-lab`. Le skill a un garde first-use : référentiel absent → proposition de poser le
socle d'abord (mode dégradé possible, signalé). Les scripts du kernel (`dag.sh`,
`driver-lock.sh`, `check-agents.sh`) viennent du module `conductor` (socle obligatoire).

## Garde-fous métier embarqués

- **RGPD prospects (critique)** : segments/ICP uniquement, aucune donnée nominative de
  prospect dans les `.md` — vérifié par le juge (critère éliminatoire).
- **Consentement / anti-spam** : opt-out exigé sur toute séquence sortante (éliminatoire).
- **Seuils CAC/ROAS** par canal (CIBLE / ALERTE-orange / ALERTE-rouge) : contrat de mesure
  de chaque campagne ; un franchissement d'ALERTE-rouge remonte en arbitrage **humain**.
- **Tag-canal obligatoire** dans chaque LEARNING (zéro contamination inter-canaux).
- **Aucun chiffre inventé** : claim non sourcé éliminatoire au gate ; métrique non sourcée
  = « inconnue » (confiance low), jamais extrapolée.

## Contenu du module

```
growth-bundle/
  module.json                    agents + skill + scripts · proposable
  VERSION / CHANGELOG.md / README.md
  agents/
    vf-growth-manager.md         ★ manager de mission (opus, team-kernel)
    channel-strategist.md        worker stratégie canal/ICP (sonnet, vf-internal)
    copywriter-sequences.md      worker séquences/créatives (sonnet, vf-internal)
    campaign-analyst.md          worker analyse/metrics (sonnet, vf-internal)
    growth-quality-judge.md      juge frais read-only (sonnet, vf-internal)
  skills/
    vf-growth/SKILL.md           point d'entrée métier (aiguillage simple vs mission)
  scripts/
    tests/test-growth-bundle.sh  suite machine (12 tests)
  content/                       ← TRACE DE CONCEPTION (matérialisée le 2026-07-25)
    BUNDLE.md                    manifeste d'origine, lu par vf-new-lab
    agents/*.blueprint.md        blueprints d'origine des 3 workers
    domain/extension-spec.md     structure exacte de l'extension growth/ (par canal)
    registres.md                 5 registres canon + IDs + pont planning↔mémoire
```

## Vérification machine

```bash
bash plugin/growth-bundle/scripts/tests/test-growth-bundle.sh
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/growth-bundle/agents
```

La suite verrouille notamment : le juge sans Write/Edit, le manager sans périmètre de
production, le cloisonnement Pattern 12 des workers, les rapports typés + DIGEST, et la
**non-contournabilité du human-gate d'acquisition** (manager + copywriter + analyst + skill).

## Dépendances

`planning-core` (socle `.planning/` + extension `growth/`), `consolidator` (registres,
promotion de décisions), `audit-architecture` (audit du process générateur, P8), `validator`
(filet de conformité). Kernel d'orchestration : module `conductor` (toujours présent).

## Châssis doctrinal

Team-kernel (`conductor-references/team-kernel.md`) : verrou de driver, DAG, rapports typés,
digest, halt conditions, cloisonnement par tools. Principes Core P1/P3/P4/P5/P7/P8/P9
référencés, jamais redupliqués. Densité ADR-029 (agents ≤ 250L, skill ≤ 500L), agents natifs
machine-enforced ADR-044, validation humaine ADR-031. Vocabulaire métier natif (P7) :
canal · campagne · séquence · ICP · offre · expérience · CAC · ROAS.
