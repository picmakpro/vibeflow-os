# growth-bundle — L'équipe growth de VibeFlow (GrowthFlow)

> Monter des campagnes d'acquisition par canal — séquences, créatives, mesure CAC/ROAS — **sans
> claim inventé, sans spammer personne et sans jamais lancer un envoi tout seul** : ce module
> installe le studio d'acquisition complet qui tient cette promesse.

**Type** : `agents + skill + scripts` · **Version** : v2.0.4 · **Dépend de** : `conductor`,
`planning-core`, `consolidator`, `audit-architecture`, `validator`.

---

## Quoi

Le métier couvert est la chaîne d'acquisition **brief → stratégie (canal/ICP) → production
(séquences/créatives) → gate qualité → validation humaine → lancement HUMAIN → analyse (CAC/ROAS,
verdict GO/ITERATE/KILL)**. Le module livre une **équipe complète sur le team-kernel** du
`conductor` (manager → workers → juge) — transposée fidèlement du pattern content-bundle
(v2.0.0, 2026-07-25), troisième preuve de la promesse multi-métier de VibeFlow.

```
BRIEF ─▶ channel-strategist ─▶ copywriter-sequences ─▶ growth-quality-judge (≥80/100)
      ─▶ VALIDATION HUMAINE (jamais auto-validée) ─▶ l'HUMAIN lance (envoi/budget)
      ─▶ campaign-analyst (CAC/ROAS, GO/ITERATE/KILL — sur données réelles uniquement)
```

**« Vert », pour ce métier** : une campagne n'est verte que si l'auto-contrôle anti-slop passe,
que le juge `growth-quality-judge` la score ≥ 80/100 sans critère éliminatoire, et que **l'humain
l'a validée explicitement**. **Iron Law growth** (ADR-031, cohérente avec la frontière Tier 2 de
`kpi-analyst`) : tout envoi réel — email, publication, dépense publicitaire, outreach — est
**HUMAN-GATED** ; en mode autonome, la mission s'arrête à « prête au lancement » (statut
`human_needed`). L'analyse ferme la boucle **après** le lancement humain : sans preuve de
lancement, `campaign-analyst` **refuse**.

Garde-fous métier embarqués, vérifiés par le juge :

- **Claim non sourcé** : éliminatoire au gate ; une métrique non sourcée est « inconnue »
  (confiance low), jamais extrapolée.
- **Consentement / anti-spam / RGPD** : opt-out exigé sur toute séquence sortante, aucune donnée
  nominative de prospect dans les `.md` (segments/ICP uniquement) — éliminatoire.
- **Seuils CAC/ROAS par canal** (CIBLE / ALERTE-orange / ALERTE-rouge) : contrat de mesure de
  chaque campagne ; un franchissement d'ALERTE-rouge remonte en arbitrage **humain**.
- **Tag-canal obligatoire** dans chaque LEARNING (zéro contamination inter-canaux).

## Installation

```bash
bash plugin/_internal/vibeflow-update.sh --scope project install --with-deps growth-bundle
```

`--with-deps` tire la fermeture transitive des `requires` dans l'ordre : `conductor` (socle
mandatory — il héberge le team-kernel et ses scripts `dag.sh`, `driver-lock.sh`,
`check-agents.sh`), `planning-core` (socle `.planning/` + extension `growth/`), `consolidator`
(registres, promotion de décisions), `audit-architecture` (audit du process générateur, P8),
`validator` (filet de conformité). Alternative interactive : `/vibeflow-install` → cocher
« growth-bundle ».

## Démarrer

Le lab type : un **SaaS ou un indépendant qui structure son acquisition par canal** (cold email,
LinkedIn, ads) et veut expérimenter proprement au lieu d'arroser. À la création via `/vf-new-lab`
(métier growth/acquisition), le bundle est **proposé au catalogue** (`proposable: true`) et le
référentiel `growth/` est posé d'office. Sur un lab existant, le skill a un **garde first-use** :
si `growth/ICP.md` est absent, il propose de poser le socle d'abord (`vf-planning`, profil
standard + extension `growth/` organisée par canal, spec : `content/domain/extension-spec.md`) —
mode dégradé possible, signalé.

Première mission à lui confier :

```
« Lance une campagne cold email vers [ICP] avec l'offre [X] »
```

Ce qu'on obtient : une fiche de stratégie (canal, ICP local, hypothèse scorée ICE, seuils
CAC/ROAS) et des séquences avec ≥ 2 variantes A/B à levier unique dans `campagnes/<date>-<slug>/`,
le verdict du juge (/100, findings cités), puis la main — c'est toi qui valides ET qui lances ;
l'analyst mesurera après ton lancement.

## Usage

Le point d'entrée est le skill `vf-growth`, qui aiguille **geste simple** (chaîne courte
stratégie → production → juge → validation humaine → lancement humain → analyse) ou **mission**
(≥ 3 campagnes/séquences ou signal de durée — « la vague du mois », « en autonomie » →
`vf-growth-manager` prend le pilotage : DAG à 5 nœuds par campagne, verrou de driver, dispatch
parallèle des campagnes indépendantes — séquentialisation si canal partagé —, rapport de mission
avec file d'attente de validation).

| Formulation | Ce qui se passe |
|---|---|
| « lance une campagne cold email », « prépare les séquences LinkedIn » | chaîne courte complète : stratégie → production → juge → validation → lancement humain |
| « active un nouveau canal » | `channel-strategist` seul — duplication de `channels/_TEMPLATE/`, delta ICP, seuils |
| « analyse les résultats de la campagne » | `campaign-analyst` — exige la trace du lancement, sinon refus ; verdict GO/ITERATE/KILL |
| « arbitre mes canaux » | `campaign-analyst` (comparatif `METRICS.md` sourcé) puis `channel-strategist` (recommandation) — la décision kill/budget reste humaine |
| « lance la vague du mois en autonomie » | mission — `vf-growth-manager` |

Frontières : le contenu éditorial (posts, threads, newsletters) → `vf-content` ; la copy de page
web (landing, pricing) → skills copywriting dédiés ; les KPIs du lab → `kpi-analyst`.

## Référence

| Pièce | Rôle | Modèle | Cloisonnement |
|---|---|---|---|
| `agents/vf-growth-manager.md` | manager de mission : DAG + verrou de driver (5 nœuds par campagne : stratégie → production → gate → humain → analyse), dispatch parallèle, digest ≤ 30 lignes par mandat, contrôle de flux sur rapports typés, halt conditions, Iron Law human-gated | opus | exposé — **ne produit jamais** (aucune écriture de livrable) |
| `agents/channel-strategist.md` | fiche de stratégie : canal confirmé (duplication `_TEMPLATE/` si absent), ICP local (delta vs maître), offre activée, hypothèse EXP scorée ICE, seuils CAC/ROAS | sonnet | `vf-internal`, écrit uniquement `campagnes/<slug>/strategie.md` (+ canal dupliqué) |
| `agents/copywriter-sequences.md` | séquences/créatives ancrées ICP + offre, ≥ 2 variantes A/B à levier unique, zéro slop, zéro claim non sourcé, opt-out intégré — **n'envoie jamais** | sonnet | `vf-internal`, écrit uniquement `campagnes/<slug>/sequences.md` + index du canal |
| `agents/growth-quality-judge.md` | **gate qualité** : juge frais, rubric /100 (claims sourcés 25 — éliminatoire —, consentement/anti-spam/RGPD 20 — éliminatoire —, ancrage ICP+offre 15, A/B levier unique 10, anti-slop 10, CTA unique 10, fidélité à la stratégie 10), seuil 80, verdict typé | sonnet | `vf-internal`, **read-only** (`Read, Glob, Grep` — sans Write/Edit) |
| `agents/campaign-analyst.md` | analyse d'une campagne **lancée par l'humain** uniquement : CAC/ROAS vs seuils, verdict GO/ITERATE/KILL, METRICS/EXPERIMENTS tenus — aucun chiffre inventé | sonnet | `vf-internal`, écrit uniquement `analyse.md` + fichiers METRICS/EXPERIMENTS du canal |
| `skills/vf-growth/SKILL.md` | point d'entrée métier : garde first-use, aiguillage geste simple vs mission (`SEUIL_EQUIPE_GROWTH = 3`), human-gate d'acquisition en invariant | — | — |
| `scripts/tests/test-growth-bundle.sh` | suite machine — **12 tests** : juge sans Write/Edit, manager sans production, Pattern 12 (allowlist du manager fermée sur l'équipe), rapports typés + DIGEST, human-gate d'acquisition non contournable (manager + copywriter + analyst + skill), rubric du juge (éliminatoires sourcing + consentement/RGPD) | — | — |
| `content/` | **trace de conception** (lisible par `vf-new-lab`) : `BUNDLE.md` (manifeste d'origine), `agents/*.blueprint.md` (3 blueprints — dont le strategist, recadré d'orchestrateur opus en worker), `domain/extension-spec.md` (structure exacte de `growth/` par canal), `registres.md` (5 registres canon + pont planning↔mémoire) | — | — |

Pas de `rules/` ni `references/` propres : le châssis doctrinal (verrou de driver, DAG, rapports
typés, digest, halt conditions, cloisonnement par tools) vit dans
`conductor/references/team-kernel.md` — référencé, jamais redupliqué. Densité ADR-029, agents
natifs ADR-044, validation humaine ADR-031. Vocabulaire métier (P7) : canal · campagne ·
séquence · ICP · offre · expérience · CAC · ROAS.

Vérification machine :

```bash
bash plugin/growth-bundle/scripts/tests/test-growth-bundle.sh
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/growth-bundle/agents
```

## Limites

- **Le lab ne lance jamais rien** : pas d'envoi d'email, de publication, d'activation de budget
  ni d'outreach — il prépare des campagnes « prêtes au lancement », le lancement est ton geste.
- **Pas de collecte externe automatique** : les métriques entrent par toi (données réelles
  sourcées) ; la collecte connectée est le territoire Tier 2 human-gated de `kpi-analyst`.
- **Pas de décision de budget/kill autonome** : l'analyst et le strategist recommandent,
  l'arbitrage d'allocation et de kill de canal reste humain.
- **Le kernel est fait pour les missions** : sous le seuil (< 3 campagnes, pas de signal de
  durée), la chaîne courte du skill suffit — pas de manager.
- **Référentiel requis** : sans `growth/` posé (ICP, offres, canaux, seuils), le module tourne
  en mode dégradé signalé — la mesure CAC/ROAS suppose des seuils définis par canal.
