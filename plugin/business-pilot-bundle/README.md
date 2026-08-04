# business-pilot-bundle — L'équipe business de VibeFlow

> Piloter un vrai business dans un lab — pipeline commercial, delivery, facturation — **sans
> jamais rien envoyer à un client tout seul, et sans jamais inventer un chiffre** : ce module
> installe l'équipe complète qui tient cette promesse.

**Type** : `agents + skill + scripts` · **Version** : v2.0.4 · **Dépend de** : `conductor`,
`planning-core`, `consolidator`, `audit-architecture`, `validator`.

---

## Quoi

Le métier couvert est la chaîne **Offre → Pipeline commercial → Delivery → Revenus** : qualifier
des leads, rédiger propositions et devis, suivre les jalons de livraison, préparer factures et
prévisions. Le module livre une **équipe complète sur le team-kernel** du `conductor`
(manager → workers → gate) — deuxième équipe métier non-dev matérialisée (v2.0.0, 2026-07-25),
preuve avec ses sœurs content et growth que la promesse multi-métier de VibeFlow est réelle.

```
BRIEF ─▶ vf-business-commercial ─▶ vf-business-delivery ─▶ quality-gate-client (≥80/100)
      ─▶ VALIDATION HUMAINE (jamais auto-validée) ─▶ vf-business-finance ─▶ l'humain envoie/émet
```

**« Vert », pour ce métier** : un livrable client (proposition, livrable de jalon, facture) n'est
vert que si l'auto-contrôle du worker passe, que le gate `quality-gate-client` le score ≥ 80/100
sans critère éliminatoire, et que **l'humain l'a validé explicitement**. Et même vert, le lab ne
l'envoie pas : il le marque « prêt à envoyer », l'humain envoie dans ses outils (ADR-031 +
LRN-068 — l'exécution réelle reste hors lab).

Deux **Iron Laws** non négociables, quel que soit le mode (autonome compris) :

1. **Aucun envoi client sans validation humaine** — devis, proposition, livrable, relance,
   facture : statut `human_needed` systématique, aucun chemin ne le contourne.
2. **Aucun chiffre financier inventé** — chaque montant est extrait d'une source citée
   (`OFFERS.md`/`PRICING.md`, dossier client, `CLIENTS.md`, registre `KPIS.md` du module
   `kpi-analyst` quand il est installé) ou marqué `confidence: low` « à confirmer ». Un montant
   non sourcé est **éliminatoire** au gate.

## Installation

```bash
bash plugin/_internal/vibeflow-update.sh --scope project install --with-deps business-pilot-bundle
```

`--with-deps` tire la fermeture transitive des `requires` dans l'ordre : `conductor` (socle
mandatory — il héberge le team-kernel et ses scripts `dag.sh`, `driver-lock.sh`,
`check-agents.sh`), `planning-core` (socle `.planning/` + extension `business/`), `consolidator`
(registres, promotion de décisions), `audit-architecture` (audit du process générateur, P8),
`validator` (filet de conformité). Alternative interactive : `/vibeflow-install` → cocher
« business-pilot-bundle ».

**Optionnel mais recommandé** : `kpi-analyst` — le pilier finance consomme son registre `KPIS.md`
et ses extracteurs déterministes (source à privilégier pour CA/encours/marge, même Iron Law des
deux côtés).

## Démarrer

Le lab type : un **freelance ou une petite structure de services** qui veut piloter ses dossiers
clients depuis son lab. À la création via `/vf-new-lab` (métier business), le bundle est
**proposé au catalogue** (`proposable: true`) et le référentiel `business/` est posé d'office.
Sur un lab existant, le skill a un **garde first-use** : si `.planning/business/PIPELINE.md` est
absent, il propose de poser le socle d'abord (`vf-planning`, profil standard + extension
`business/` selon `content/domain/extension-spec.md`) — mode dégradé possible, signalé.

Première mission à lui confier :

```
« Qualifie ce lead : [contexte] et prépare la proposition »
```

Ce qu'on obtient : un dossier d'opportunité dans `business/pipeline/`, une proposition **rédigée**
(jamais envoyée) aux montants sourcés, le verdict du gate (/100, findings cités), puis la main —
c'est toi qui valides et envoies.

## Usage

Le point d'entrée est le skill `vf-business`, qui aiguille **geste simple** (chaîne courte
worker → gate → validation humaine) ou **mission** (≥ 3 dossiers/actions ou signal de durée —
« la semaine », « en autonomie » → `vf-business-manager` prend le pilotage : DAG par dossier
client, verrou de driver, dispatch parallèle des dossiers indépendants, rapport de mission avec
file d'attente de validation).

| Formulation | Ce qui se passe |
|---|---|
| « qualifie ce lead », « prépare le devis pour X » | `vf-business-commercial` — livrable rédigé dans le dossier d'opportunité |
| « suis le jalon du client Y », « prépare le livrable » | `vf-business-delivery` — jalons/SLA, livrable préparé puis gate + humain |
| « prépare la facture », « relance les impayés », « prévision de CA » | `vf-business-finance` — documents sous `business/finance/`, montants sourcés uniquement |
| « où en est le pipeline ? » | lecture seule de `PIPELINE.md` + synthèse — pas de dispatch, pas de gate |
| « fais tourner le business de la semaine », « traite les dossiers en autonomie » | mission — `vf-business-manager` |

Cas particuliers : **facturer un jalon** exige les preuves amont (gate vert + validation humaine
du livrable facturé), sinon le finance **refuse** ; un **signal d'upsell/churn** remonté par le
delivery rouvre une action commerciale ; **les KPIs** (« mets à jour les chiffres ») ne sont pas
ce module → `kpi-analyst` (le finance consomme `KPIS.md`, il ne le produit pas).

## Référence

| Pièce | Rôle | Modèle | Cloisonnement |
|---|---|---|---|
| `agents/vf-business-manager.md` | manager de mission : DAG + verrou de driver (nœuds par dossier client : commercial → delivery → gate → humain → finance), dispatch parallèle, digest ≤ 30 lignes par mandat, contrôle de flux sur rapports typés, halt conditions | opus | exposé — **ne produit jamais** (aucun périmètre de production) |
| `agents/vf-business-commercial.md` | qualification/scoring, propositions/devis/relances **rédigés** (jamais envoyés), montants sourcés, tient `PIPELINE.md` | sonnet | `vf-internal`, écrit uniquement `PIPELINE.md` + `pipeline/{leads,prospects,clients}/` |
| `agents/vf-business-delivery.md` | jalons/SLA, **préparation** des livrables clients, satisfaction, signaux upsell/churn | sonnet | `vf-internal`, écrit uniquement `pipeline/{delivery,completed}/` |
| `agents/quality-gate-client.md` | **gate qualité** : juge frais, rubric /100 (périmètre vendu 25 — éliminatoire —, montants sourcés 25 — éliminatoire —, complétude 20, qualité 15, conditions 15), seuil 80, verdict typé | sonnet | `vf-internal`, **read-only** (`Read, Glob, Grep` — sans Write/Edit) |
| `agents/vf-business-finance.md` | factures/relances/prévisions **préparées** (l'humain émet), Iron Law « aucun chiffre inventé », EVAL systématique (P8) | sonnet | `vf-internal`, écrit uniquement `business/finance/` + `CLIENTS.md` |
| `skills/vf-business/SKILL.md` | point d'entrée métier : garde first-use, aiguillage geste simple vs mission (`SEUIL_EQUIPE_BUSINESS = 3`), les deux Iron Laws en invariants | — | — |
| `scripts/tests/test-business-pilot-bundle.sh` | suite machine — **14 tests** : gate sans Write/Edit, manager sans production, Pattern 12, rapports typés + DIGEST, non-contournabilité de la validation humaine ET de l'envoi client (T8 + T13), zéro chiffre inventé (T14) | — | — |
| `content/` | **trace de conception** (lisible par `vf-new-lab`) : `BUNDLE.md` (manifeste d'origine), `agents/*.blueprint.md` (3 blueprints), `domain/extension-spec.md` (structure exacte de `business/`), `registres.md` (5 registres canon + pont planning↔mémoire) | — | — |

Pas de `rules/` ni `references/` propres : le châssis doctrinal (verrou de driver, DAG, rapports
typés, digest, halt conditions, cloisonnement par tools) vit dans
`conductor/references/team-kernel.md` — référencé, jamais redupliqué. Densité ADR-029, agents
natifs ADR-044, validation humaine ADR-031. Vocabulaire métier (P7) : Sprint stratégique ·
Initiative · Obstacle · Rollout · dossier client · pipeline · jalon.

Vérification machine :

```bash
bash plugin/business-pilot-bundle/scripts/tests/test-business-pilot-bundle.sh
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/business-pilot-bundle/agents
```

## Limites

- **Le lab n'envoie jamais rien** : pas d'envoi de mail, d'émission de facture ni d'encaissement —
  il prépare et documente, l'exécution réelle reste dans tes outils (CRM, mail, compta).
- **Pas de connecteur externe** : aucune lecture automatique de CRM/banque/compta ; les données
  entrent par le brief et le référentiel `business/` (l'acquisition externe est le territoire
  Tier 2 human-gated de `kpi-analyst`).
- **Pas le producteur des KPIs** : le finance consomme `KPIS.md`, il ne calcule ni ne publie les
  indicateurs du lab.
- **Le kernel est fait pour les missions** : sous le seuil (< 3 dossiers/actions, pas de signal
  de durée), la chaîne courte du skill suffit — pas de manager.
- **Référentiel requis** : sans `business/` posé, le module tourne en mode dégradé signalé —
  la valeur pleine suppose le socle `vf-planning`.
