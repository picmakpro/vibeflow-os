<div align="center">

# VibeFlow OS

[English](./README.md) · **Français**

**Claude Code est puissant. VibeFlow le rend fiable, économe et gouverné.**

Orchestration agentique **spec-driven** pour Claude Code : tu parles normalement, un agent
détecte l'intention, déroule le pipeline (cadrage → plan → exécution → preuve), et des **gates
machine** vérifient — pas des promesses.

[![Version](https://img.shields.io/badge/version-2.47.1-2563eb)](./VERSION)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://docs.claude.com/en/docs/claude-code)
[![Modules](https://img.shields.io/badge/modules-17-16a34a)](#-modules)
[![License](https://img.shields.io/badge/license-source--available-64748b)](./LICENSE)

[Le cycle dev](#-le-cycle-dev--spec-driven) · [Missions](#-missions-longues--léquipe) · [Labs & design](#-au-delà-du-dev--un-lab-pour-chaque-métier) · [Mémoire](#-la-mémoire-qui-tient) · [Installation](#-installation) · [Modules](#-modules)

</div>

---

📖 **Nouveau ici ?** Le [manuel utilisateur](./manual/README.md) t'accompagne pour installer,
comprendre et faire tourner VibeFlow — sans jamais ouvrir `.planning/` ni `docs/`.

---

## Le problème

Les setups IA échouent à l'échelle pour trois raisons : le **context rot** (la qualité se
dégrade à mesure que le contexte gonfle), l'**improvisation** (l'agent code sans spec, vérifie
de mémoire, s'auto-valide), et les **tokens brûlés** (tout en contexte, tout relu, tout en
modèle premium).

VibeFlow attaque les trois : **le disque est la source de vérité** (specs, plans, état — pas
le contexte), **rien n'est « fait » sans preuve machine** (tests, gates, juges frais), et
**chaque token a un rôle** (workers sonnet, digests, chargement on-demand, dispatch parallèle).

---

## 🔁 Le cycle dev — spec-driven

Dis _« ajoute l'auth Google »_ : l'agent `vibeflow-dev` détecte l'intention et déroule le
pipeline GSD — cadrage, plan vérifié, exécution atomique, juges read-only — en laissant un
artefact sur disque à chaque étape, pour que le contexte puisse mourir sans que le projet
en pâtisse.

→ [Le cycle, étape par étape](./manual/fr/04-cycle-de-dev/le-cycle-en-bref.md)

---

## 🤖 Missions longues — l'équipe

« Fais les étapes 3 à 5, je reviens demain matin. » Au-delà du seuil, un **manager de
mission** prend le relais sur le **team-kernel** : des workers sonnet tournent en parallèle,
des rapports typés remplacent la prose, et tout ce qui défie l'intention ou la sécurité
**gèle le nœud** et remonte à l'humain — même à 3 h du matin.

→ [Comment tient une mission longue](./manual/fr/05-equipe-agents/une-mission-longue.md)

---

## 🧪 Au-delà du dev — un lab pour chaque métier

VibeFlow n'est pas un outil dev-only : il **fabrique des labs** — des espaces de travail
gouvernés pour le contenu, la croissance, le business ou tout autre métier — sur le même
kernel, les mêmes gates, et des skills fabriqués par `skill-creator` avec une boucle d'évals.

→ [Qu'est-ce qu'un lab ?](./manual/fr/02-concepts/qu-est-ce-qu-un-lab.md)

---

## 🧠 La mémoire qui tient

Un lab VibeFlow n'oublie pas entre deux sessions : registres indexés, mémoire d'agents qui
capitalise cross-session, et artefacts disque en premier (`PROJECT.md`, `ROADMAP.md`,
`STATE.md`) — n'importe quelle session repart d'un disque à jour, jamais d'un contexte
compacté.

→ [Anatomie d'un lab installé](./manual/fr/07-sous-le-capot/anatomie-d-un-lab-installe.md)

---

## 🏗 Architecture

Un socle `conductor` obligatoire (team-kernel + gates machine) porte les orchestrateurs
métier — dev, design, mobile, trois bundles métier — plus les modules de gouvernance
(`validator`, `consolidator`, `infrastructure-audit`). La CI fait tourner un job
« **lab frais** » : la baseline s'installe dans un lab vierge et doit passer ses propres
gates sans intervention.

→ [Les gates machine](./manual/fr/07-sous-le-capot/les-gates-machine.md)

---

## 🚀 Installation

Deux commandes, zéro clone, zéro édition de config :

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

Puis dans Claude Code : `/vibeflow-install` — scope pré-détecté (confirmation en une touche),
choix des modules, dépendances résolues et récapitulées avant toute pose. Mise à jour :
`/vf-update`. Détails : [INSTALL.md](./INSTALL.md).

---

## 📦 Modules

17 modules, chacun versionné avec son `CHANGELOG.md`. À l'install : `conductor` est le
**socle obligatoire**, puis un choix — *lab de dev* ou *lab métier sur mesure*. Le README de
chaque module est sa documentation complète — même structure partout.

→ [Catalogue des modules](./manual/fr/03-modules/catalogue.md) ·
[commandes](./manual/fr/06-reference/commandes.md) ·
[skills](./manual/fr/06-reference/skills.md) ·
[agents](./manual/fr/06-reference/agents.md)

---

## 🔒 Confiance

- **Source-available** : code et historique publics — voir [LICENSE](./LICENSE).
- **Auditable** : bash + `jq`, chaque script couvert par sa suite (`50 suites` en CI), install
  **idempotente** avec backup avant écrasement.
- **Le repo s'applique sa propre doctrine** : CI sur push/PR (tests + gates stricts) + job
  « **lab frais** » — la baseline est installée dans un lab vierge et doit passer ses propres
  gates sans intervention.
- **Zéro hook au niveau plugin** : rien ne s'exécute tant que tu n'invoques pas. Les hooks de
  gouvernance des modules sont posés par `/vibeflow-install`, sous tes yeux.
- **Anti-hallucination par design** : le routage s'appuie sur un index factuel auto-généré
  depuis le disque ; les modules incomplets sont marqués `proposable:false`, jamais vendus.

---

## 🧭 Versioning

**Semver par module** + version racine taguée à chaque release (`check-release-tag` en gate).
Historique complet : **[CHANGELOG.md](./CHANGELOG.md)** — le README garde les 3 dernières :

| Version | Date | Changement |
|---------|------|------------|
| `v2.47.1` | 2026-08-04 | **L'index des skills cesse de mentir sur sa propre provenance, et l'historique reçoit l'entrée qu'une release avait sautée.** Origine : la mise à jour du moteur `@opengsd/gsd-core` de 1.9.0 vers **1.9.1**, et la question de savoir si le couplage tenait encore. **Il tient sur toute sa surface, vérifié plutôt que déduit** : plafond `^1` de `ensure-deps.sh` qui couvre 1.9.1, flags `--claude`/`--global`/`--local` tous présents dans l'installeur 1.9.1, commandes appelées (`loop render-hooks`, `state`, `state record-session`, `roadmap analyze`) toutes en 0, et capabilities **déclarées identiques** entre les deux versions — index régénéré depuis le registre de chacun des deux tarballs, 12 points de hook, 35 étages, sortie identique à l'octet près. Le delta amont porte sur les runtimes non-Claude et un troisième registre de découvrabilité, pas sur le contrat consommé ici. **Le seul défaut actif**, trouvé en le vérifiant : l'en-tête de `gsd-skills-index.md` annonçait `@opengsd/gsd-core@1.9.0` — un **littéral figé** dans `build-gsd-index.sh`, donc un fichier auto-généré ET versionné qui affirme une provenance fausse, contredisant frontalement la doctrine que le script voisin énonce dans son propre en-tête (« aucune version de moteur n'est figée dans la logique »). La version est désormais **lue** sur le moteur résolu selon une règle unique — le moteur est le dossier parent de la source de workflows déjà résolue par la cascade dual-layout —, donc elle décrit toujours l'arbre d'où sortent réellement les entrées, sans seconde cascade à maintenir. Trois conduites de bord tenues par des tests : VERSION absente ou illisible → l'en-tête **dit** « (version inconnue) » au lieu d'affirmer un numéro ; VERSION non maîtrisée → lecture bornée à 200 octets puis classe de caractères restreinte (port du garde de `check-gsd-engine.sh`), substitution de commande neutralisée et jamais évaluée ; disposition **legacy** → l'index nomme `get-shit-done-cc` plutôt que de maquiller un moteur legacy en `@opengsd/gsd-core`. `T1e` est **DISCRIMINANT par construction** (fixture `9.9.9-fixture`), discriminance prouvée dans les deux sens : 4 KO avec la version figée, 165 OK / 0 KO après. Suite du module 161 → **165 cas**. **Dette d'historique soldée** : la v2.47.0 avait été taggée et publiée sans jamais recevoir son entrée au CHANGELOG racine — même classe de défaut que la page Releases bloquée de v2.29.0 à v2.39.0. Module `dev-orchestrator` v2.11.1. **47 suites** vertes. |
| `v2.47.0` | 2026-08-04 | **Le moteur de dev est explicitement couplé à GSD, et le lock de driver cesse de s'ouvrir pendant qu'il se récupère.** Deux volets. (1) **Phase 23 — couplage explicite** (10 exigences `GSDC-01..10`, 9 soldées) : le module raisonnait comme si GSD était une liste de skills à appeler, alors que 1.9 est un **moteur à capabilities** qui insère ses étages lui-même — `grep -r "capabilit\|render-hooks"` sur `dev-orchestrator/` rendait **zéro**. Livrés : une **voie unique d'invocation** (la voie de l'agent nu désactivait en silence research, pattern-mapper, plan-checker, gap-analysis, waves, verifier, code-review, nyquist et secure-phase, tout en rendant `passed`), une **doctrine de flags en allowlist stricte**, une table capabilities/hooks **générée depuis le moteur installé** au lieu d'être écrite à la main — elle ne peut plus dériver en silence —, un **contrat de checkpoint relayé et jamais recalculé**, et **un budget de tours par étape** au lieu de deux boucles qui additionnaient les leurs. `GSDC-08` part en `[~]` : l'écart `D-22` (`gsd-debugger` présent contre une décision « aucune exception » **et** exigé par le gate `T19`) relève de l'arbitrage, pas du code. **Deux RCE fermées**, dont une réintroduite par un script neuf via une prémisse de sécurité jamais propagée d'un plan à l'autre, prouvée close en rejouant l'install complète depuis un dépôt piégé — le piège est prouvé **lu**, pas évité en silence. Suite 102 → **161 cas**. (2) **Une course de récupération dans `driver-lock.sh`** (`conductor` v1.19.1) : récupérer un claim périmé **déplaçait** le dossier de lock avant de le recréer, et le `mkdir` de la voie normale — incapable de distinguer « libre » de « en cours de récupération » — y entrait. Jusqu'à **5 gagnants simultanés** mesurés sur 24 acquisitions concurrentes, sur macOS comme sur Linux ; deux correctifs de fenêtre mesurés **pires** que l'original (8 et 6). Le lock devient un **lien symbolique** remplacé par `rename(2)` : jamais absent, donc jamais apparemment libre. La récupération est sérialisée par un mutex nommé d'après la génération, et le verdict de péremption est relu après lui. Les locks au format dossier restent lus et récupérables. `T13` passe de 6 concurrents en un tirage à **24 × 5 rounds**, les deux bornes gardées. Modules `dev-orchestrator` v2.11.0, `conductor` v1.19.1. **47 suites** vertes. |
| `v2.46.0` | 2026-08-01 | **Le suivi cesse de mentir, et deux sessions cessent de pouvoir se marcher dessus sans le savoir.** Trois chantiers. (1) **Hygiène documentaire** (Phase 22) : la doctrine avait une *entrée* (`ingestion-flow.md`) mais pas de *sortie* — `docs-flow.md` distingue les 4 familles que GSD maintient séparément et que nous avions fondues en une ligne, expose les flags porteurs de sens (`--verify-only` auditer sans écrire *vs* `--force` régénérer), et `vf-design-manager` reçoit le même nœud `docs` que son homologue dev, **par renvoi jamais par copie**. (2) **Le ROADMAP reçoit la checklist que le moteur lit** : annoncé comme « 20 SUMMARY manquants », le vrai défaut était que le ROADMAP n'avait **jamais** porté la checklist de phases — seule forme lue par `@opengsd/gsd-core` — si bien que le moteur voyait **zéro** phase terminée sur 24 et rendait des compteurs faux. La checklist rattrape les 20 plans sans SUMMARY des Phases 11-14 **sans fabriquer un seul fichier** : `roadmap.cjs` fait primer la case cochée sur le disque, « pour les phases terminées avant le tracking GSD ». Phases 23-25 régularisées sous le jalon `gsd-alignement`. **2 signalements déposés en amont** ([#2956](https://github.com/open-gsd/gsd-core/issues/2956), [#2957](https://github.com/open-gsd/gsd-core/issues/2957)). (3) **Un écrivain = un worktree** (**ADR-064**) : deux sessions ont écrit sur la même branche sans le savoir le 2026-07-31. Le constat « le verrou protège l'étape, pas la branche » était incomplet — `driver-lock.sh` n'est consulté **que par les managers**, la session fautive n'en était pas un. ADR-064 tranche ce qu'ADR-059 avait laissé ouvert : l'isolation devient **physique**, et `check-branch-claim.sh` (4 codes, advisory, `SessionStart`) porte le claim jusqu'aux sessions ordinaires. Un faux positif de symlink trouvé dans le gate en le construisant, mutant tué. Modules `conductor` v1.19.0, `dev-orchestrator` v2.10.0, `design-orchestrator` v1.4.0. **46 suites** vertes. |
| `v2.45.0` | 2026-07-31 | **VibeFlow aligné sur `@opengsd/gsd-core` 1.9.0** — origine : la mise à jour du moteur de 1.8.0 vers 1.9.0 le 2026-07-31, delta établi sur pièce (`npm pack` des deux versions, diff intégral, vérification de l'installation vivante). Le seul défaut actif : `inject-mcp-tools.sh` ne découvrait les serveurs MCP que via `./.mcp.json` — un serveur déclaré uniquement en **scope global** (`~/.claude.json`, ex. XcodeBuildMCP) restait invisible, `--verify` sortait en `3` INDÉTERMINÉ au lieu de signaler le manque. Corrigé par une **union de deux scopes** (projet ∪ global, `--claude-json`/`VF_CLAUDE_JSON`), dégradation indépendante par source, précédence projet > global sur collision. Livrés aussi : le contrat amont `estimate:`/`actuals:` relayé verbatim par `vf-coder`/`vf-dev-manager` (jamais une statistique auto-évaluée) ; **ADR-061**, arbitrage écrit du recouvrement entre les lanes de revue cross-AI amont et l'étage de revue de code livré en 20-06 (deux objets distincts, gardés séparés) ; l'hypothèse datée du dispatch nommé consignée dans `team-kernel.md`, recoupée avec `gsd-worktree-path-guard.js` (#1995, #2608 — vérifiés conformes) ; la purge de la dette de version 1.8.0 → 1.9.0 sur 6 fichiers, en déplaçant le cas de test à chaîne littérale (cas 8) avec le texte qu'il vérifie, jamais neutralisé ; **ADR-062**, arbitrage des 2 hooks 1.9.0 non câblés (absence correcte dans les deux cas) ; et **`check-state-integrity.sh`** (**ADR-063**) — nouveau gate anti-régression du frontmatter de `.planning/STATE.md`, désormais câblé au job `gates` de la CI, fermant la classe exacte de régression silencieuse (`completed_phases`/`total_plans`/`completed_plans` en baisse au sein du même jalon) découverte après la clôture de la Phase 20. Modules `dev-orchestrator` v2.9.0, `planning-core` v2.5.3, `conductor` v1.18.0 (inchangé, vérifié cohérent). **46 suites** vertes, `check-agents --strict` vert sur les 6 dossiers d'agents. |
| `v2.44.0` | 2026-07-31 | **La revue devient un étage de premier rang, piloté par le manager** (**ADR-060**) : elle sort du cycle interne de `vf-coder`, qui cesse d'être juge de son propre travail — le manager dispatche `vf-reviewer` et tient lui-même la boucle correction → re-revue. Origine : le **second rapport d'audit externe** du 2026-07-28 (lab tiers, tranche iOS en 5 lots dont 2 parallélisés, ~90 commits, suite 177 → 331 tests), dont les 4 constats ont été **vérifiés sur pièce avant ouverture** — 3 confirmés dont 2 **plus solidement que le rapport ne l'affirmait**, 1 partiellement daté. **ADR-051 révisée sur son seul point contesté** : la prémisse « les agents de revue ne compilent jamais » confondait **produire** un verdict de compilation et **en vérifier** un. `vf-reviewer` reçoit une allowlist MCP **nommée** (`vf-mcp-tools`, grammaire `<serveur>:<outil…>`) — jamais le joker de serveur, moindre privilège préservé — et la révision porte son **prix écrit noir sur blanc** (~90 s de plus par revue, un slot de simulateur). **La barrière d'écriture des 4 juges cesse d'être une fiction** : l'absence de `Write`/`Edit` dans `tools:` était rouverte **silencieusement au runtime** par `memory: project` (prouvé par sonde) — ils portent désormais `disallowedTools: Write, Edit`, une contrainte réelle, sans qu'une ligne du gate n'ait bougé. `vf-design-judge`, seul à conserver `Bash`, **cesse d'affirmer une barrière qu'il n'a pas** et nomme son angle mort : canal shell ouvert, retenue qui reste un engagement de prompt. Trois garde-fous non négociables encadrent tout allègement, tirés des chiffres de l'audit : **jamais réduire le nombre de tests** (mesuré : sur 90 s de build, les tests pèsent ~1 s — levier nul), **jamais alléger la revue sur le chemin critique produit** (5 bloquants trouvés en une journée), et **aucun allègement ne s'applique à un diff de comblement** (9 puis 5 puis 4 défauts nés des correctifs de revue eux-mêmes). Livrés aussi : `--scope` et `review_regime` (périmètres gelés), `check-mission-invariants.sh` + `.planning/MISSION-INVARIANTS.md` (gate de zone morte), et le périmètre explicite des hooks tiers (`--third-party-prefix`). Modules `conductor` v1.17.0, `dev-orchestrator` v2.8.0, `design-orchestrator` v1.3.2, les 3 bundles v2.0.3. **46 suites** vertes, `check-agents --strict` vert sur les 6 dossiers d'agents. |
| `v2.43.1` | 2026-07-28 | **Une mission d'équipe travaille sur sa propre branche, jamais sur la branche par défaut** (**ADR-059**). Dès qu'un manager est dispatché (`vf-dev-manager`, `vf-design-manager`), il crée sa branche **avant son premier commit**, y tient tous ses commits et termine par une **PR laissée ouverte** — il ne merge jamais, le merge appartient à l'utilisateur (ADR-031 appliqué à l'intégration). Origine : sur ce dépôt même, une mission autonome a produit **32 commits directement sur `main`**, poussés puis taggés ; le recours en cas de mission ratée était un `revert` en masse d'un historique déjà public. Sur une branche, le recours est de **ne pas merger**, et la PR fournit le point de relecture groupée qu'un rapport de fin de mission — rédigé par l'agent qui a fait le travail, et lu trop tard — ne remplace pas. Le déclencheur est le **dispatch d'un manager**, pas la nature du travail : le travail conversationnel direct reste hors de la règle. Cinq replis garantissent qu'une mission n'échoue **jamais** faute d'appliquer la règle (pas de dépôt git · pas de remote · `gh` absent · **arbre sale = halt condition**, jamais un `stash` décidé seul · `CLAUDE.md` du projet cible qui prime). Ne couvre pas l'isolation des vagues parallèles **à l'intérieur** d'une mission — seul `isolation: worktree` le ferait, décision laissée ouverte. Modules `dev-orchestrator` v2.7.1, `design-orchestrator` v1.3.1. |
| `v2.43.0` | 2026-07-28 | Le moteur GSD entre dans le périmètre de `/vf-update` (**ADR-058**) : la migration `get-shit-done-cc` → `@opengsd/gsd-core` livrée en v2.39.0 n'atteignait **aucun poste déjà équipé** — seulement les installations neuves. Constaté sur un poste tiers : plugin à jour en 2.42.0, moteur toujours à 1.42.3 posé **12 jours** plus tôt, sans que rien dans l'interface ne le dise. Trois causes enchaînées, toutes fermées. `detect_gsd()` renvoyait vrai sur le layout legacy via un `||` écrit pour la tolérance dual-layout, et en faisait un `skip` : il devient un état à **trois valeurs** (`absent`/`legacy`/`gsd-core`) où « legacy » est **actionnable**. Aucun chemin de mise à jour n'appelait le script d'installation : `check-gsd-engine.sh` (nouveau gate, contrat F13) est sondé par `/vf-update` — et **avant** son arrêt « VibeFlow est à jour », sans quoi un poste au plugin à jour ne voyait jamais la proposition. Le message de nettoyage legacy, jusqu'ici joignable par `/vf-init` seul, devient atteignable et **exact** : `npm uninstall -g` n'est plus proposé que si le paquet est réellement global, l'arborescence vide laissée par l'installeur est incluse, et l'état est capturé **avant** l'install — l'installeur amont supprimant lui-même le `VERSION` legacy, le message ne pouvait plus jamais sortir après coup. Piège acté noir sur blanc : le fork **repart de zéro**, donc **1.8.0 < 1.42.3 en semver** — la migration se décide sur le **nom du paquet et le layout**, jamais sur la comparaison des numéros, et un test fixe ce couple exact. ADR-031 tenu de bout en bout : détecter et **proposer**, jamais installer ni nettoyer sans accord. `ensure-deps.sh --migrate-engine` enchaîne sur la ré-injection MCP (l'installeur amont classe l'injection ADR-051 en « local patch » et efface `mcp__XcodeBuildMCP__*` du `tools:` de `gsd-executor`), et `inject-mcp-tools.sh --verify` compare le `tools:` final aux serveurs du `.mcp.json`. Ce dernier a d'abord été livré **inerte** — appelé sans `--force`, il écartait sa propre cible et sortait toujours en 3 — défaut validé par la revue, le gate de portabilité **et** l'audit sécurité, débusqué par la seule mutation du bloc livré. |
| `v2.42.0` | 2026-07-28 | Signaux de démarrage du moteur de dev : `dev-orchestrator` — seul module structurant **sans aucun hook** — reçoit son premier fragment `hooks/hooks.json`. Trois scripts en lecture seule et **advisory** constatent des FAITS au `SessionStart` et injectent des lignes courtes et auto-portantes. `check-dev-bootstrap.sh` couvre tout le continuum de démarrage en un seul script (silence · `onboard` si du code sans `.planning/` · `bootstrap` listant les items manquants · orientation `gsd-engine` si complet), signaux prouvés mutuellement exclusifs par test. `discover-unintegrated-docs.sh --hook` agrège le compte de façon **additive**, sans toucher à son contrat historique `grain<TAB>chemin` ; `check-doc-drift.sh` signale les commits de code qui distancent la mise à jour de doc au-delà d'un seuil réglable (défaut 20). Le signal `gsd-engine` ferme le trou de routage constaté le 2026-07-27 — `planning-core` se retire quand GSD tient le projet et aucun module ne prenait le relais. Portabilité **prouvée par exécution** : compteurs identiques sur macOS bash 3.2.57, Debian 12 et Ubuntu 24.04, ce qui exclut le test sauté silencieusement. Deux cas de test tautologiques débusqués et tués par mutation. |
| `v2.41.0` | 2026-07-27 | Cloisonnement complet des dispatches : `check-agents.sh` lint désormais le **contenu** du champ `tools:` — syntaxe des allowlists et existence des noms, sur `tools:` comme `disallowedTools:` (jusqu'ici, noms d'agents inventés, parenthèse non fermée et outils inexistants passaient tous `--strict` en vert ; suite 38 → 58 axes). La sévérité est indexée sur ce qui est vérifiable indépendamment du périmètre installé, de sorte que les types natifs (`general-purpose`) et les agents externes `gsd-*` ne rendent jamais rouge une allowlist correcte — le monde fermé est un mode opt-in réservé à la CI. Allowlists posées sur les 3 workers dev après double recensement indépendant. Correction doctrinale : dans la définition d'un sous-agent, le runtime **ignore** les noms entre parenthèses — une allowlist est un contrat documenté enforcé par ce lint seul, pas un bac à sable runtime. |
| `v2.40.0` | 2026-07-27 | Collaboration croisée dev ↔ design sous un seul manager : `vf-dev-manager` insère des nœuds `craft:`/`critique:` dans une mission dev (étage sauté et signalé quand la direction artistique manque), `vf-design-manager` gagne un étage d'implémentation opt-in avec double juge (re-critique DA ∥ revue de code) et budgets anti-thrash séparés 3 + 3, `vf-auto` aiguille enfin les missions purement design vers le manager design, et les deux managers portent une allowlist `Agent(...)` (18 / 6 noms) qui interdit l'imbrication manager→manager (contrat documenté — voir la correction v2.41.0 sur ce qu'une allowlist enforce réellement). Kernel intact. |

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

## 👤 Auteurs

- **[@picmakpro](https://github.com/picmakpro)** — créateur de la méthodologie VibeFlow et propriétaire du repo. A posé les fondations du projet et reste le gardien de sa doctrine : le socle de gouvernance (`conductor`, `planning-core`, `consolidator`), les hooks et guards scripturaux qui gardent chaque lab honnête. L'identité de VibeFlow — une gouvernance tenue par les outils, pas par la prose — c'est lui.
- **Samuel Neveu — [@samuel-neveugall](https://github.com/samuel-neveugall)** — la force motrice du projet au quotidien : contributeur principal et pilote des releases. A construit tout le versant développement (`dev-orchestrator`, `design-orchestrator`, `mobile-test-team`), mené la bascule agentique et le team-kernel, et conduit l'évolution du framework — dont sa migration sur le moteur `@opengsd/gsd-core`.

## 📄 Licence

Source-available sous licence propriétaire — voir [LICENSE](./LICENSE). Code et historique
publics ; les élèves de la formation disposent d'un droit de réutilisation privée ;
redistribution et revente interdites. Le module `skill-creator` réutilise du contenu Anthropic
original sous licence MIT.
