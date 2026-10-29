<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/logo-dark.svg">
  <img alt="VibeFlow" src="docs/readme/logo-light.svg" width="72">
</picture>

# VibeFlow OS

[English](./README.md) · **Français**

### Tu parles. L'équipe livre. Tu valides.

Un plugin Claude Code de développement agentique piloté par la spec. Un agent lit ton intention,
une équipe d'agents challenge, planifie, construit et prouve le travail, et des gates machine le
vérifient. Rien n'est fait sans preuve, rien n'est mergé sans toi.

[![Version](https://img.shields.io/badge/version-2.72.0-2563eb)](./VERSION)
[![Runtimes](https://img.shields.io/badge/runtimes-Claude%20Code%20%7C%20Codex%20%7C%20kimi--code-7c3aed)](#autres-runtimes)
[![Modules](https://img.shields.io/badge/modules-18-16a34a)](#modules)
[![License](https://img.shields.io/badge/license-source--available-64748b)](./LICENSE)

[Le cycle](#comment-ça-marche) · [La preuve](#fait--prouvé) · [L'équipe](#une-équipe-pas-un-chatbot) · [La mémoire](#la-mémoire-qui-tient) · [Les labs](#un-lab-pour-chaque-métier) · [Installation](#installation) · [Manuel](./manual/README.md)

</div>

https://github.com/user-attachments/assets/226c4e9b-dfa6-4f4e-b13c-2802c93f6932

## Installation

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

Puis, dans Claude Code, lance `/vibeflow-install` : il détecte le scope, te laisse choisir les
modules et récapitule chaque dépendance avant toute écriture. Mise à jour : `/vf-update`. Codex
et kimi-code sont couverts [plus bas](#autres-runtimes) ; détails dans [INSTALL.md](./INSTALL.md).

Nouveau ici ? Le [manuel utilisateur](./manual/README.md) t'accompagne pour installer,
comprendre et faire tourner VibeFlow, sans jamais ouvrir `.planning/` ni `docs/`.

## Comment ça marche

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/cycle-dark.svg">
  <img alt="Le cycle VibeFlow : tu demandes en langage naturel ; l'équipe challenge la demande, écrit la spec, planifie, construit et prouve, en laissant un fichier sur disque à chaque étape ; un juge frais peut renvoyer le travail ; rien n'est mergé sans ta validation." src="docs/readme/cycle-light.svg" width="100%">
</picture>

Dis *« ajoute la connexion Google »*. `vibeflow-head` lit l'intention et lance l'équipe. La
demande est challengée par des questions jusqu'à ce qu'elle soit claire, puis elle devient une
spec, un plan aux tests écrits d'abord, des commits atomiques et le verdict d'un juge qui n'a pas
écrit le code. Chaque étape laisse un fichier sur disque : une session peut mourir sans que le
projet recule. La dernière étape t'appartient.

→ [Le cycle, étape par étape](./manual/fr/04-cycle-de-dev/le-cycle-en-bref.md)

## Fait = prouvé

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/gates-dark.svg">
  <img alt="Les gates machine : une affirmation « c'est fait » traverse les tests, les gates machine et un juge frais ; le premier test échoue, le correctif le fait passer, puis chaque gate sort en 0." src="docs/readme/gates-light.svg" width="100%">
</picture>

Un vert qui ne peut pas devenir rouge ne prouve rien. Les tests s'écrivent rouges d'abord, les
gates `check-*.sh` tournent en CI, et le juge n'est jamais l'auteur. Le dépôt s'applique la même
règle : 116 suites tournent à chaque push, et un job « lab frais » installe le socle dans un lab
vierge qui doit passer ses propres gates sans intervention.

→ [Les gates machine](./manual/fr/07-sous-le-capot/les-gates-machine.md)

## Une équipe, pas un chatbot

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/team-dark.svg">
  <img alt="L'équipe : vibeflow-head lance un manager de mission ; les workers tournent en parallèle et rendent des rapports typés ; le reviewer ne relit jamais son propre travail ; un nœud qui touche la sécurité gèle jusqu'à ta décision." src="docs/readme/team-light.svg" width="100%">
</picture>

*« Fais les étapes 3 à 5, je reviens demain matin. »* Au-delà d'un seuil, un manager de mission
prend le relais sur le team-kernel : il planifie la bataille en graphe, lance les workers en
parallèle et lit des rapports typés plutôt que de la prose. Tout ce qui défie l'intention ou la
sécurité gèle le nœud jusqu'à ta décision, même à 3 h du matin.

→ [Comment tient une mission longue](./manual/fr/05-equipe-agents/une-mission-longue.md)

## La mémoire qui tient

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/memory-dark.svg">
  <img alt="La mémoire : la session 1 écrit PROJECT.md, ROADMAP.md, STATE.md et la mémoire d'agents sur disque, puis son contexte disparaît ; la session 2 repart du disque, rien n'est perdu." src="docs/readme/memory-light.svg" width="100%">
</picture>

La fenêtre de contexte se remplit et se dégrade ; le disque, non. `PROJECT.md`, `ROADMAP.md`,
`STATE.md`, les registres indexés et la mémoire d'agents portent le projet d'une session à
l'autre. Chaque session repart d'un disque à jour, jamais d'un contexte compacté, et chaque
token a un rôle : workers sonnet, digests, chargement à la demande.

→ [Anatomie d'un lab installé](./manual/fr/07-sous-le-capot/anatomie-d-un-lab-installe.md)

## Un lab pour chaque métier

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/readme/labs-dark.svg">
  <img alt="Les labs : un socle, conductor avec le team-kernel et les gates machine, porte les équipes dev, design, mobile, contenu, growth et business, plus le lab que tu crées avec /vf-new-lab." src="docs/readme/labs-light.svg" width="100%">
</picture>

VibeFlow n'est pas réservé au dev. Il fabrique des labs, des espaces de travail gouvernés pour
le design, le contenu, la croissance, le business ou ton propre métier, sur le même kernel et
les mêmes gates. `/vf-new-lab` en crée un, et ses skills sont fabriqués par `skill-creator`
avec une boucle d'évals.

→ [Qu'est-ce qu'un lab ?](./manual/fr/02-concepts/qu-est-ce-qu-un-lab.md)

## Modules

18 modules, chacun versionné avec son `CHANGELOG.md`. `conductor` est le socle obligatoire ;
ensuite tu choisis un lab de dev parmi des presets (`dev`, `dev-mobile`, `dev-audite`, les
dépendances résolues pour toi) ou un lab métier sur mesure. Le README de chaque module est sa
documentation complète, avec la même structure partout.

→ [Catalogue des modules](./manual/fr/03-modules/catalogue.md) ·
[commandes](./manual/fr/06-reference/commandes.md) ·
[skills](./manual/fr/06-reference/skills.md) ·
[agents](./manual/fr/06-reference/agents.md)

## Autres runtimes

Claude Code est la référence. L'install **et** l'usage sont aussi mesurés de bout en bout sur
deux autres :

| Runtime | Installation | Ce que tu perds |
|---|---|---|
| Codex | `codex plugin marketplace add picmakpro/vibeflow-os`<br>`codex plugin add vibeflow@vibeflow-os` | Les hooks. Exige `multi_agent_v2` et un dépôt « trusted », les deux échouent en silence sinon ; force `VF_RUNTIME=codex` si `claude` est aussi installé. |
| kimi-code | Pas de canal d'install : charge un agent avec `kimi --agent-file <chemin>` | Les hooks. |

Chaque perte est déclarée à l'install plutôt que passée sous silence. Liste complète :
[Installer hors Claude Code](./manual/fr/01-demarrer/autres-runtimes.md).

## Confiance

- **Source-available** : code et historique publics, voir [LICENSE](./LICENSE).
- **Auditable** : bash + `jq`, chaque script couvert par sa suite, install **idempotente** avec
  backup avant tout écrasement.
- **Zéro hook au niveau plugin** : rien ne s'exécute tant que tu n'invoques pas. Les hooks de
  gouvernance des modules sont posés par `/vibeflow-install`, sous tes yeux.
- **Anti-hallucination par design** : le routage s'appuie sur un index factuel généré depuis le
  disque ; les modules incomplets sont marqués `proposable:false`, jamais vendus.

## Versions

Semver par module, et une version racine taguée à chaque release (`check-release-tag` est un
gate). Les trois dernières sont ci-dessous ; l'historique complet vit dans
**[CHANGELOG.md](./CHANGELOG.md)**.

| Version | Date | Changement |
|---------|------|------------|
| `v2.72.0` | 2026-10-29 | **Bundle produit (minor).** Nouveau module `product-team-bundle` v1.0.0 : équipe produit (manager, analyste BRIEF, PM PRD, juge `prd-gate` seuil 80, gate `check-prd.sh`), front door `vibeflow-product` et skill `/vf-product`, visible aux postes `product` et `solo`. Reste `proposable: false` jusqu'à un run réel. `planning-core` v2.9.0 (gabarit produit), `dev-orchestrator` v2.29.0 (le head oriente vers `/vf-product` au poste `product`). |
| `v2.71.2` | 2026-10-23 | **Correctifs d'audit, de doublons et de doc (patch).** `infrastructure-audit` ne rend plus INDÉTERMINÉ sous `--strict --no-tests` quand aucune suite n'existe ; `detect-duplicates.sh` passe les titres à Python par l'entrée standard et signale ses échecs (champ `errors`, code de sortie 2) ; le tableau des signaux de démarrage de l'agent `dev-orchestrator` suit le texte réel des hooks ; les commentaires de `driver-lock` décrivent la garde hors racine (`conductor` v1.50.2, `consolidator` v1.11.3, `dev-orchestrator` v2.28.4, `infrastructure-audit` v1.3.6). |
| `v2.71.1` | 2026-10-23 | **Correctifs Windows, audit et bootstrap (patch).** Le mode UTF-8 est posé sans condition sous `-I` et les deux gros programmes de hooks ne passent plus par la ligne de commande (Windows la plafonne à 32 767 caractères) ; `infrastructure-audit` gagne `--no-tests` et rend INDÉTERMINÉ sous `--strict` quand les suites sont sautées ; `driver-lock` refuse un sous-dossier sans `.planning/` propre ; le bootstrap de session oriente vers `/vf-dev` ; `check-gsd-config` épargne les clés propres à VibeFlow (`conductor` v1.50.1, `consolidator` v1.11.2, `design-orchestrator` v1.5.15, `dev-orchestrator` v2.28.3, `infrastructure-audit` v1.3.5, `planning-core` v2.8.3). |

<details>
<summary><strong>Références méthodologiques (ADR / LRN)</strong></summary>

- **ADR-032** — Système de consolidation mémoire 4 piliers
- **ADR-035** — Doctrine architecture logicielle AI-Safe
- **ADR-053** — Volet swarm : lock de driver + DAG + rapports typés
- **ADR-055** — Frontière d'altitude planning lab ↔ moteur de dev
- **ADR-056** — Vigilance support runtime
- **ADR-057** — Frontières outillées avec les briques tierces
- **LRN-101** — Pattern « agent minimal + skills composables »
- **LRN-106** — Audit avant fix

Lab principal (privé) : [vibeflow-lab](https://github.com/picmakpro/vibeflow-lab) — les modifications structurantes y sont testées avant release.

</details>

---

## Auteurs

- **[@picmakpro](https://github.com/picmakpro)** — créateur de la méthodologie VibeFlow et propriétaire du repo. A posé les fondations du projet et reste le gardien de sa doctrine : le socle de gouvernance (`conductor`, `planning-core`, `consolidator`), les hooks et guards scripturaux qui gardent chaque lab honnête. L'identité de VibeFlow — une gouvernance tenue par les outils, pas par la prose — c'est lui.
- **Samuel Neveu — [@samuel-neveugall](https://github.com/samuel-neveugall)** — la force motrice du projet au quotidien : contributeur principal et pilote des releases. A construit tout le versant développement (`dev-orchestrator`, `design-orchestrator`, `mobile-test-team`), mené la bascule agentique et le team-kernel, et conduit l'évolution du framework — dont sa migration sur le moteur `@opengsd/gsd-core`.

## Contribuer

Les contributions sont bienvenues — pas besoin d'être collaborateur : fork, branche, pull request.
Lire [CONTRIBUTING.md](./CONTRIBUTING.md) (workflow, tests, licence des contributions), le
[code de conduite](./CODE_OF_CONDUCT.md), et signaler les vulnérabilités en privé comme décrit
dans [SECURITY.md](./SECURITY.md). Les issues et PR en français sont acceptées.

## Licence

Source-available sous licence propriétaire — voir [LICENSE](./LICENSE). Code et historique
publics ; les élèves de la formation disposent d'un droit de réutilisation privée ;
redistribution et revente interdites. Le module `skill-creator` réutilise du contenu Anthropic
original sous licence MIT.
