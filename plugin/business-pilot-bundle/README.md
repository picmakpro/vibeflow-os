# business-pilot-bundle — Équipe business sur le team-kernel (business-pilot)

> Module **installable** du plugin vibeflow-os : l'équipe métier de **pilotage business**
> construite sur le team-kernel (manager → workers → gate). Il transforme un lab VibeFlow en
> **poste de pilotage gouverné** couvrant la chaîne **Offre → Pipeline commercial → Delivery →
> Revenus**, avec dispatch parallèle des dossiers clients et deux Iron Laws non négociables :
> **aucun envoi client sans validation humaine** et **aucun chiffre financier inventé**.

---

## Ce que le module installe

| Pièce | Rôle | Modèle | Cloisonnement |
|---|---|---|---|
| `vf-business-manager` | manager de mission : DAG + verrou de driver (nœuds par dossier client : commercial → delivery → gate qualité → humain → finance), dispatch parallèle des dossiers indépendants, digest par mandat, contrôle de flux sur rapports typés, orchestration de la validation humaine | opus | exposé — **ne produit jamais** (pas d'Edit, aucune production) |
| `vf-business-commercial` | qualification/scoring, propositions/devis/relances **rédigés** (jamais envoyés), montants sourcés, tient `PIPELINE.md` | sonnet | `vf-internal`, écrit uniquement `PIPELINE.md` + `pipeline/{leads,prospects,clients}/` |
| `vf-business-delivery` | jalons/SLA, **préparation** des livrables clients, satisfaction, signaux upsell/churn | sonnet | `vf-internal`, écrit uniquement `pipeline/{delivery,completed}/` |
| `quality-gate-client` | juge frais du gate qualité : rubric **/100**, seuil **80**, **montant non sourcé** et **hors périmètre vendu** éliminatoires, verdict typé | sonnet | `vf-internal`, **read-only** (tools sans Write/Edit) |
| `vf-business-finance` | factures/relances/prévisions **préparées** (l'humain envoie), Iron Law « aucun chiffre inventé » alignée kpi-analyst, EVAL systématique (P8) | sonnet | `vf-internal`, écrit uniquement `business/finance/` + `CLIENTS.md` |
| skill `vf-business` | point d'entrée métier : geste simple vs mission (seuil 3 dossiers/actions ou signal de durée) | — | — |

## La chaîne (et sa définition du « vert »)

```
BRIEF ─▶ vf-business-commercial ─▶ vf-business-delivery ─▶ quality-gate-client (≥80/100)
      ─▶ VALIDATION HUMAINE (jamais auto-validée) ─▶ vf-business-finance ─▶ l'humain envoie/émet
```

Un livrable client n'est **vert** que si : auto-contrôle du worker passé + score du gate
≥ 80/100 sans critère éliminatoire + **validation humaine explicite** — et même vert, le lab
ne l'envoie pas : il le marque « prêt à envoyer », **l'humain envoie dans ses outils**
(ADR-031 + LRN-068 : le lab prépare et documente, l'exécution réelle — envoi de facture,
signature, encaissement — reste hors lab). Tout nœud produisant un livrable client (une
proposition commerciale comprise) insère gate + humain avant l'étape suivante.

## Les deux Iron Laws

1. **Aucun envoi client sans validation humaine** — devis, proposition, livrable, relance,
   facture : `human_needed` systématique, aucun mode (autonome compris) ne le contourne.
2. **Aucun chiffre financier inventé** — chaque montant est extrait d'une source citée
   (`OFFERS.md`/`PRICING.md`, dossier client, `CLIENTS.md`, registre `KPIS.md` du module
   **kpi-analyst** quand il est installé — source à privilégier pour CA/encours/marge) ou
   marqué `confidence: low` « à confirmer ». Un montant non sourcé est **éliminatoire** au gate.

## Deux régimes d'usage

- **Geste simple** (« qualifie ce lead », « prépare la facture ») : le skill `vf-business`
  déroule la chaîne courte — worker concerné, gate qualité si livrable client, validation
  humaine, envoi par l'humain.
- **Mission** (≥ 3 dossiers/actions ou signal de durée : « la semaine », « en autonomie ») :
  `vf-business-manager` prend le pilotage — plan de bataille en DAG par dossier client,
  verrou de driver, **dispatch parallèle** des dossiers indépendants (périmètres d'écriture
  disjoints par construction : une étape de pipeline = un propriétaire), digest ≤ 30 lignes
  par mandat, halt conditions, rapport de mission avec file d'attente de validation.

## Prérequis côté lab

Le lab doit porter le référentiel business (`.planning/business/` : `PIPELINE.md` — index lu
en premier —, `OFFERS.md`, `PROCESSES.md`, `CLIENTS.md`, `STRATEGY.md`, arbo `pipeline/`) —
posé par `vf-planning` (profil standard, spec : `content/domain/extension-spec.md`) ou
`vf-new-lab`. Le skill a un garde first-use : référentiel absent → proposition de poser le
socle d'abord (mode dégradé possible, signalé). Les scripts du kernel (`dag.sh`,
`driver-lock.sh`, `check-agents.sh`) viennent du module `conductor` (socle obligatoire).

## Contenu du module

```
business-pilot-bundle/
  module.json                    agents + skill + scripts · proposable
  VERSION / CHANGELOG.md / README.md
  agents/
    vf-business-manager.md       ★ manager de mission (opus, team-kernel)
    vf-business-commercial.md    worker pipeline/propositions (sonnet, vf-internal)
    vf-business-delivery.md      worker jalons/livrables (sonnet, vf-internal)
    vf-business-finance.md       worker factures/prévisions (sonnet, vf-internal)
    quality-gate-client.md       gate frais read-only (sonnet, vf-internal)
  skills/
    vf-business/SKILL.md         point d'entrée métier (aiguillage simple vs mission)
  scripts/
    tests/test-business-pilot-bundle.sh  suite machine (14 tests)
  content/                       ← TRACE DE CONCEPTION (matérialisée le 2026-07-25)
    BUNDLE.md                    manifeste d'origine, lu par vf-new-lab
    agents/*.blueprint.md        blueprints d'origine des 3 workers
    domain/extension-spec.md     structure exacte de l'extension business/
    registres.md                 5 registres canon + IDs + pont planning↔mémoire
```

## Vérification machine

```bash
bash plugin/business-pilot-bundle/scripts/tests/test-business-pilot-bundle.sh
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/business-pilot-bundle/agents
```

La suite verrouille notamment : le gate sans Write/Edit, le manager sans périmètre de
production, le cloisonnement Pattern 12 des workers, les rapports typés + DIGEST, la
**non-contournabilité de la validation humaine ET de l'envoi client** (T8 + T13), et le
**zéro chiffre inventé** (T14 : Iron Law finance + manager, éliminatoire au gate).

## Dépendances

`planning-core` (socle `.planning/` + extension `business/`), `consolidator` (registres,
promotion de décisions), `audit-architecture` (audit du process générateur, P8), `validator`
(filet de conformité). Kernel d'orchestration : module `conductor` (toujours présent).
Optionnel mais recommandé : `kpi-analyst` (le pilier finance consomme `KPIS.md` et ses
extracteurs déterministes — même Iron Law des deux côtés).

## Châssis doctrinal

Team-kernel (`conductor-references/team-kernel.md`) : verrou de driver, DAG, rapports typés,
digest, halt conditions, cloisonnement par tools. Principes Core P1/P3/P4/P5/P7/P8/P9
référencés, jamais redupliqués. Densité ADR-029 (agents ≤ 250L, skill ≤ 500L), agents natifs
machine-enforced ADR-044, validation humaine ADR-031, exécution réelle hors lab LRN-068.
Vocabulaire métier natif (P7) : Sprint stratégique · Initiative · Obstacle · Rollout ·
dossier client · pipeline · jalon.
