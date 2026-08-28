# Étude — canal d'install multi-runtime & migration de lab

Document d'étude. **Aucun code produit, rien sous `plugin/`.** Prolonge `SPIKE-REPORT.md` et
`DISCUSS.md` (non modifiés) sur deux axes non couverts : le canal d'install côté runtime tiers,
et la migration d'un lab existant. Convention de sourçage : **mesuré en exécution** / **lu et
sourcé** / **dérivé** / **inconnu**. Un inconnu se déclare, ne se comble jamais dans ce document.

---

## AXE A — Le canal d'install

### A1. Ce que chaque runtime offre (lu et sourcé / mesuré en exécution)

| runtime | nature du canal | source |
|---|---|---|
| Codex | vrai gestionnaire — `codex plugin marketplace add\|list\|upgrade\|remove` | mesuré en exécution |
| kimi-code | vrai gestionnaire, **TUI-only, sans `update`** | lu et sourcé |
| OpenCode | mince wrapper npm, registre = npm | lu et sourcé |

Codex : manifeste `.codex-plugin/plugin.json` ; marketplace `<root>/.agents/plugins/marketplace.json` ;
cache `~/.codex/plugins/cache/<mkt>/<plugin>/<version>/`, de forme identique au cache Claude.

### A2. Le test réel — trois plans, à ne pas confondre

**Plan 1 — TRANSPORT : parfait (mesuré en exécution).**
`source.path = "./plugin"` accepté sans broncher : install byte-identique — **470/470 fichiers**,
**145/145 répertoires**, 5,7 Mo, arbres de sommes SHA-256 `cmp`-identiques.
La convention `./plugins/<nom>` est documentaire, pas normative. **La question du renommage de
`plugin/` est close : non.**

**Plan 2 — ENREGISTREMENT PAR LE MANIFESTE : absent pour agents et commandes (mesuré en exécution).**
Union complète des clés sur les **64** manifestes curés :

| clé | occurrences /64 |
|---|---|
| `name`, `version`, `description`, `author`, `interface` | 64 |
| `license` | 53 |
| `keywords` | 53 |
| `homepage` | 52 |
| `repository` | 52 |
| `skills` | 47 |
| `apps` | 36 |
| `mcpServers` | 8 |
| `hooks` | 1 |
| `agents` | **0** |
| `commands` | **0** |

VibeFlow pose **7 commandes** (`plugin/commands/*.md`) et **25 agents** (`plugin/*/agents/*.md`) :
copiés dans le cache par le transport (Plan 1), sans surface de déclaration dans le manifeste.

**Plan 3 — ENREGISTREMENT PAR UNE AUTRE VOIE : existe pour les agents, non exercée sur ce poste
(lu et sourcé + mesuré en exécution).**
Codex enregistre ses agents via `~/.codex/agents/*.toml`, `.codex/agents/` en scope projet, et
`[agents]` de `config.toml` — documenté, et cohérent avec le spike qui a mesuré un spawn nommé à
**profondeur 3** avec **un modèle par worker** (`SPIKE-REPORT.md`). Sur ce poste : `~/.codex/agents/`
**n'existe pas**, `config.toml` ne porte **aucune** section `[agents]` (mesuré en exécution).

**Conclusion — de nature, pas de degré** : le canal plugin n'enregistre pas les agents ; la
surface d'enregistrement existe ailleurs, et l'install devrait l'alimenter en un **second geste**
que le canal ne fait pas. Ne pas écrire « les agents n'ont aucune surface de déclaration » — ce
serait contredire le résultat central du `SPIKE-REPORT.md` (Codex apte, profondeur 3 mesurée). Le
team-kernel n'est pas impossible sur Codex : il demande une pose de plus.

**Commandes — tenue à la mesure.** `commands: 0` sur 64 manifestes est un **fait**. « Les commandes
sont impossibles » serait une **inférence**, non écrite ici. Les 7 commandes VibeFlow sont de
minces enveloppes de délégation (`description`, `argument-hint`, puis délégation à un agent).
Qu'elles puissent se reposer comme skills est **plausible et non mesuré** — les skills curées sont
des répertoires de sous-répertoires à `SKILL.md`. **Déclaré inconnu** (cf. §Ce qui reste inconnu).

**Deux faits mesurés supplémentaires.**
- Le canal est **réversible** : `config.toml` byte-identique après `remove` (Codex défait ses
  propres écritures) ; seul résidu, un répertoire de cache vide.
- **Aucun prompt de confiance** pour une source locale via la CLI — aucun `--yes`/`--trust`,
  parce qu'il n'y a rien à confirmer. Donnée de sécurité d'install, non demandée par le mandat de
  spike initial.

**Inconnu déclaré** : combien de skills Codex enregistre réellement depuis `"skills": "./installer"`
(0 ou 1) — inférence depuis la forme curée, exige une session Codex vivante.

### A3. Le précédent npm (gsd-core)

Aucun `postinstall`. L'arbre `~/.claude/gsd-core/` naît d'une **commande explicite** —
`npx @opengsd/gsd-core --claude --global` → `bin/install.js` — qui recopie un **sous-répertoire de
payload** et écrit `VERSION` à la main. D'où l'absence de `package.json` dans l'arbre installé : ce
n'est pas un paquet npm posé, c'est une charge utile recopiée. Le paquet lui-même est téléchargé,
exécuté, jeté (`require.resolve` échoue, aucun binaire sur le PATH).

**Formule à garder telle quelle : « le canal ne remplace pas l'engine, il le livre. »**

npm **résout** : découverte (registre public), semver (35 versions), signature + attestation de
provenance SLSA, cache. npm **n'apporte pas** l'enregistrement auprès de l'hôte — gsd-core le
réimplémente intégralement dans `install.js`.

**Contraintes** : Node ≥ 24 — déjà payé par `plugin/dev-orchestrator/scripts/ensure-deps.sh` (5
voies, sous `$HOME`, jamais de `sudo`, refus explicite sous MSYS2) → coût marginal Node ≈ zéro ;
réseau ; scope npm à posséder ; publication immuable (pas de rollback, seulement `deprecate`) ;
désinstallation entièrement à écrire.

**Précédent qui tranche le débat `--target`** : gsd-core refuse la combinaison des deux axes —
`"Cannot use --config-dir with --local"`. Après 19 runtimes, l'amont n'a pas rendu `--config-dir`
orthogonal au scope. Confirme la recommandation du spike : pas de `--target` orthogonal à
`--scope`, mais un **site unique injectable**.

### A4. Le coût réel du `--target`

Deux coûts distincts, seul le premier figurait au spike.

**Engine** : 1 site de calcul de `TARGET_ROOT` (l. 105-109, jamais réassigné, 156 lectures) +
**16 sites / 15 littéraux `.claude` distincts**. Injection en une ligne :
`TARGET_ROOT="${VF_TARGET_ROOT:-<dérivé du scope>}"` — `VF_TARGET_ROOT` est déjà émis par l'engine
(l. 943) et déjà consommé par `generate-agent-commands.sh`, dans un seul sens.

**Payload** — trois définitions côte à côte (mesuré en exécution) :

| périmètre | fichiers | occurrences | lignes |
|---|---|---|---|
| `plugin/` entier | **207** | **1324** | 1235 |
| hors `_internal/` (payload livré) | **198** | **1130** | **1050** |
| `_internal/` seul | 9 | 194 | 185 |

Commandes : `rtk proxy grep -rl '\.claude/' plugin [--exclude-dir=_internal]` pour les fichiers ·
`grep -ro` pour les occurrences · `grep -rc` sommé pour les lignes.

**Le chiffre qui porte la conclusion est celui du payload livré : 198 fichiers / 1130
occurrences.** Note : **1050 est un décompte de LIGNES**, pas d'occurrences — origine mesurée
d'une des quatre divergences de comptage de cette mission (cf. Findings autonomes §3).

**Conséquence** : un `--target` qui déplace les fichiers sans réécrire leur contenu produit un lab
dont 198 fichiers pointent vers un répertoire inexistant — l'install réussit, le lab est mort.
L'amont a payé ce prix : `copyWithPathReplacement` (~150 lignes, table de dispatch, garde
anti-symlink, confinement racine) existe uniquement pour ça. **Ce n'est pas une option
d'implémentation, c'est le maillon.**

### A5. Ce que le marketplace Claude rend gratuitement — et le fait dur

**Mesuré** : le canal actuel ne résout aucune version. `installed_plugins.json` →
`vibeflow@vibeflow-os` : version **2.58.0**, `gitCommitSha` **a61cd8d**. Commit réel du tag
`v2.58.0` : **2226e0d**. `git describe --tags a61cd8d` → **`v2.58.0-1-ga61cd8d`**. Le paquet
installé est donc **`main` HEAD**, un commit après le tag, étiqueté avec la chaîne déclarée dans
`marketplace.json`.

La discipline de tags du `CLAUDE.md` reste pleinement justifiée pour ce qu'elle protège
(traçabilité, installabilité par référence, remède à la divergence de juillet 2026). Ce que la
mesure établit, c'est que le canal d'install actuel ne l'exploite pas — `marketplace.json` porte
`"source": "./plugin"` et une `version` déclarative, sans `ref` ni `sha`. C'est un **écart entre
une discipline tenue et un canal qui l'ignore**, pas une discipline inutile. Ça réoriente
l'arbitrage : la question n'est plus « que perd-on en quittant le marketplace » mais « veut-on
enfin épingler » — un canal alternatif pointant un tag serait un **gain**, pas une régression.

**Point qui hiérarchise tout l'axe A** : l'engine a été exécuté sans marketplace, sans
`CLAUDE_PLUGIN_ROOT`, sans CLI `claude` — plan d'install complet rendu, zéro écriture. Détection de
mise à jour, install, versions par module, dépendances, rollback, dry-run, scoping : tout est déjà
porté par VibeFlow et fonctionne hors marketplace. **Le seul service réellement gratuit et
réellement perdu est la DÉCOUVERTE.** Le reste vient loin derrière.

---

## AXE B — Migration d'un lab existant

### B1. La frontière fuit — dans les deux sens

Hypothèse « `.planning/` agnostique, `.claude/` spécifique » : **réfutée**, mesurée sur **14 labs**
(13 témoins hors ce dépôt méta — mesurer `vibeflow-os` seul aurait été un artefact, il parle de
`.claude` par nature).

| fuite | mesure | portée |
|---|---|---|
| `.planning/` → `.claude` | 392/482 PLAN.md (81 %) ouvrent sur `@$HOME/.claude/…/execute-plan.md` | contrat d'exécution ; texte inerte sous un autre runtime |
| `.planning/` → `.claude` | 37 % des fichiers `.planning/` portent une amarre `.claude` | état vivant compris |
| hooks → `.claude` | 47/48 entrées de hook contiennent un littéral `.claude` | `CLAUDE_PROJECT_DIR` injecté par Claude Code ; `{{VF_SCRIPTS}}`/`{{VF_BASH}}` paramètrent le **scope**, pas le **runtime** |
| `.claude` → agnostique | 116 fichiers sous `.claude/agent-memory/`, 100 % agnostiques | gitignorés (`.gitignore:20`), emplacement imposé par le harness via `memory: project` ; VibeFlow ne choisit ni ne redirige |

**Survit sans rien faire** : `.planning/config.json` intégralement agnostique, les imports
`@.planning/*`, la prose, les corps de skills et d'agents, les scripts bash neutres.

**Formulation à garder** : `.planning/` **contient** de l'état agnostique mais **n'en est pas
un**. La fuite est **massive en nombre de fichiers** et **étroite en surface conceptuelle** — un
petit nombre de formes de chemin explique l'essentiel des occurrences d'import. Réparable
mécaniquement ; simplement pas fait, et rien ne le signale.

**Inconnu déclaré** : aucune migration réelle n'a été exécutée. L'« échec silencieux » sous un
autre runtime est **inféré** de la nature propriétaire de la syntaxe `@`, **pas observé**.

### B2. Réversibilité — le point qui change la recommandation

Ce n'est pas un one-way door, mais la réversibilité ne repose **pas** sur `rollback` : ce verbe ne
fait pas ce que son nom dit (vérifié en lecture directe du code, lu et sourcé) :

- `rollback_module` ne restaure que `skills` et `scripts` — **jamais les agents, jamais les
  hooks**.
- Il **n'appelle jamais `mark_installed`** : le registre continue d'annoncer la **nouvelle**
  version avec les **anciens** fichiers ; la mise à jour suivante voit « à jour » et ne repose
  rien.
- Le glob de sélection `ls -1dt "$BACKUP_DIR/$mod"-*` matcherait aussi les répertoires de
  convergence `$mod-<ts>-removed` de structure interne différente — et la restauration fait un
  `rm -rf` **AVANT** la copie. *(Aucun répertoire `-removed` sur ce poste : la collision est
  structurellement établie mais non manifestée.)*

En revanche `uninstall` est solide : routé par manifeste, refus explicite sans source, `rmdir`
plutôt que `rm -rf`, retrait des hooks, désenregistrement.

**Non réversible par aucun outil** : tout ce qui est écrit hors de `TARGET_ROOT` — notamment
`.planning/config.json`, que l'engine ne touche jamais.

### B3. Bascule ou coexistence

La coexistence est **physiquement ouverte** (site unique de `TARGET_ROOT`, registre/manifeste/backup
déjà partitionnés par racine, homes disjoints entre runtimes) — ce n'est pas là qu'est le coût. Le
coût est dans les **surfaces singulières partagées** :

- le runtime est un **scalaire** dans `.planning/config.json` (un seul runtime déclaré à la fois) ;
- les hooks n'existent que côté Claude ;
- le style de commande diverge (`/gsd-*` slash vs invocation TUI/CLI) ;
- une seconde racine repart avec des registres vierges (aucun état partagé entre `~/.claude/` et
  l'équivalent Codex/OpenCode).

**Coexister, c'est accepter qu'un runtime travaille hors gouvernance.** Les deux côtés :

| | Bascule (remplace) | Coexistence (ajoute) |
|---|---|---|
| pour | un seul scalaire runtime à tenir cohérent ; pas de désynchronisation d'état entre deux registres | rien à défaire ; retour arrière trivial (on arrête d'utiliser le second runtime) |
| contre | migration soustractive avec le trou de B2 (rollback partiel) | le second runtime opère sans hooks, sans gouvernance VibeFlow — dérive silencieuse possible |

Pas de tranchage ici — les deux options restent ouvertes pour l'arbitrage humain (§Proposition de
cadrage).

### B4. `/vf-update`, `vf-calibrate`, ou un geste neuf

`vibeflow-update.sh` expose `install|update|uninstall|rollback|status|sync` — **pas de `migrate`**
(lu et sourcé). Le précédent le plus proche est la migration du moteur GSD, qui fonctionne parce
qu'elle est **additive et sans perte** ; une migration de runtime est **soustractive et change la
cible d'écriture** — asymétrie de nature, pas de degré.

`vf-calibrate` est déjà titré « propagation d'update & migration de lab » (lu et sourcé) : le nom
est pris, et sa séquence (instantané → dry-run → application → re-tamponnage → re-audit) est
presque exactement ce qu'une migration de runtime demande. **Si un verbe distinct est envisagé, il
faut d'abord décider ce que devient `vf-calibrate`** — le dépôt a une doctrine explicite contre les
couches de synonymes (mémoire agent `agent-skills-ecarte-superpowers-reste`, même famille de
principe). Question posée, non tranchée ici.

### B5. La détection du runtime hôte n'est pas sous garantie

`host-runtime-detection.cjs` n'est **pas** ré-exporté par `host-integration-sdk.cjs` (18 clés,
aucune n'y renvoie — mesuré en exécution) : c'est donc une API interne non versionnée, comme le
reste de la surface d'artefacts. `detectHostRuntime` retombe sur `'claude'` en cas de non-détection
— une dégradation silencieuse de plus.

**Conséquence** : mieux vaut **inscrire le runtime explicitement** (par exemple dans
`.planning/config.json`) que le détecter.

### B6. Le risque central appliqué à la migration

Le spike nommait « un lab qui croit avoir VibeFlow et n'en a qu'un tiers ». Sur une migration c'est
**pire : le lab fonctionnait avant**, donc la régression est invisible et sera attribuée à autre
chose.

| perte mesurée/dérivée | ce que l'utilisateur observe | ce qu'il conclut à tort |
|---|---|---|
| disparition des hooks (côté Claude seulement, B3) | moins d'interruptions, moins de confirmations | amélioration ergonomique du nouveau runtime |
| un juge (`vf-design-judge`, `vf-reviewer`) conçu sans outils d'écriture qui récupère le droit d'écrire (frontière d'agent non reposée sous le nouveau runtime) | rapport final vert | le travail est validé |
| enregistrement d'agents non alimenté après transport (A2, Plan 2/3) | l'équipe semble présente (fichiers copiés) | le team-kernel est opérationnel |
| `.planning/config.json` non migré par aucun outil (B2) | le lab « a l'air » d'avoir changé de runtime | l'ancien runtime est complètement débranché |

---

## FINDINGS AUTONOMES

1. **Le cache npx est clé sur la chaîne de spec, pas sur la version résolue.** Le dossier
   `@latest` de ce poste sert encore **1.10.0** alors que `latest` vaut **1.11.0**. Même classe de
   piège que la rétrogradation silencieuse sous Node 22 (mémoire agent
   `piege-node-24-gsd-core`), par un autre chemin. Quiconque écrira le canal npm marchera dessus.

2. **Le faux négatif silencieux, dans sa forme la plus pure.** Pendant cette étude, un comptage
   Python a rendu **0 sur 64 fichiers** parce que les répertoires `.codex-plugin/` commencent par
   un point, que le glob n'attrape pas par défaut ; `find` en listait bien 64. C'est le manager qui
   l'a produit, sur une mesure de contre-vérification. Meilleure illustration du risque que toute
   la phase décrit — l'absence n'est jamais prouvée par une seule commande.

3. **Quatre divergences de comptage, toutes définitionnelles.** Aucune n'était arithmétique :
   périmètre (`_internal/` inclus ou non, cf. A4), objet (fichiers / lignes / occurrences, cf. A4),
   définition (« appeler un skill » vs « mentionner la famille », cf. inventaire superpowers),
   homonymie (`docs/superpowers/`, cf. inventaire superpowers). Un compteur sans sa définition sera
   re-contesté ; comparer les ensembles en `comm`, pas les nombres (mémoire agent
   `project_diff-proxifie-utiliser-comm`).

---

## Cas d'école — un arbitrage révisé sur prémisse tombée

Une première décision humaine (« rapatrier les skills superpowers réellement appelées ») a été
rendue sur le motif « le catalogue tiers est Claude-only ». La mission a ensuite mesuré le
contraire : superpowers **est déjà multi-runtime** (8 manifestes de runtime + une extension
Gemini, cf. ci-dessous). Face à une prémisse tombée, la décision n'a été ni exécutée telle quelle
ni réinventée côté agent — elle est **repartie chez l'humain**, qui l'a révisée : l'arbitrage
change de nature, de « rapatrier le catalogue » à « rendre l'installeur multi-runtime », et
l'inventaire de rapatriement devient un plan de secours plutôt qu'une exécution.

**Le principe, à retenir au même titre que « un arbitrage humain n'est jamais inférable »** : une
décision dont la prémisse tombe pendant l'exécution n'est pas non plus exécutable telle quelle
sur la foi de l'ancien motif — elle retourne à l'arbitre.

## Le bloqueur réel : l'installeur de VibeFlow, pas le catalogue

superpowers **est déjà multi-runtime** (fait vérifié, cf. inventaire ci-dessous : 8 manifestes de
runtime + une extension Gemini dans la version 6.3.0 du plugin tiers). Le bloqueur n'est donc pas
le catalogue — c'est que les deux scripts `ensure` de VibeFlow ne savent parler qu'à un seul
gestionnaire de plugin.

**Mesuré en exécution** — motif `claude plugin install|command -v claude` :

| script | sites |
|---|---|
| `plugin/dev-orchestrator/scripts/ensure-deps.sh` | **5** (l. 8, 449, 464, 472, 480) |
| `plugin/design-orchestrator/scripts/ensure-design-deps.sh` | **6** (l. 148, 151, 154, 157, 168, 327) |

Contenu des sites : détection de disponibilité (`command -v claude`), liste des plugins installés
(`claude plugin list`), et l'install elle-même (`claude plugin install <pkg>@<marketplace>
--scope <scope>`), pour 4 dépendances (superpowers, ui-ux-pro-max, frontend-design, impeccable) côté
design, superpowers seul côté dev.

**Ce que coûterait le rendre runtime-aware** — séparer strictement mesuré / inféré :

| runtime | commande d'install équivalente | statut |
|---|---|---|
| Claude Code | `claude plugin install <pkg>@<marketplace> --scope <scope>` | **mesuré en exécution** (canal actuel, A2/A3) |
| Codex | `codex plugin marketplace add <source>` puis install du plugin qu'elle référence | **mesuré en exécution** (A2 : transport et manifeste vérifiés ce spike, la commande exacte de sous-installation post-`add` reste à exercer — cf. inconnu A2) |
| OpenCode | commande npm-équivalente (registre = npm, A1) | **inféré / documentaire**, non exécuté |
| kimi-code | commande TUI, **sans `update`** documenté (A1) | **inféré / documentaire**, non exécuté |

11 sites au total (5 + 6) à faire basculer sur une détection de runtime + une table de dispatch de
commande — même famille de coût que le `TARGET_ROOT` de l'engine (A4) : peu de sites, mais chacun
change de nature (un `if command -v claude` devient une détection multi-runtime, pas un simple
paramètre). Pas de commande unifiée mesurée aujourd'hui : OpenCode et kimi-code restent
documentaires tant qu'aucune session vivante ne les exerce (même statut que Codex `[agents]` en
A2).

## Inventaire superpowers — plan de secours chiffré (pas une option écartée)

**L'arbitrage a changé (cf. cas d'école ci-dessus) : ceci n'est plus le geste à exécuter, c'est un
chiffrage tenu prêt.** Si superpowers subit un rug pull (précédent déjà nommé dans la mémoire du
dépôt sur `agent-skills`), ce chiffrage évite de le refaire dans l'urgence — personne n'aura à
redériver ces nombres sous pression.

- **128 lignes brutes** dans `plugin/` → **7 invocations réelles** (facteur 18). **66/128 sont un
  homonyme** : `docs/superpowers/`, convention de nom de dossier, aucune relation avec le plugin
  tiers.
- **3 skills réellement invoqués** :
  - `test-driven-development` — **dure**, le module délègue explicitement la mécanique.
  - `verification-before-completion` — **dure par silence**, gate de sortie universel, aucun
    repli déclaré.
  - `brainstorming` — **confort**, double repli déclaré.
- **3 skills nommées mais jamais invoquées** (`systematic-debugging`, `requesting-code-review`,
  `writing-skills`) : uniquement dans des tables de frontière. Les inclure ferait passer le volume
  de 1 236 à 5 118 lignes (×4,1).
- **Volume** : 1 236 lignes, 11 fichiers, 120 ko. Copie sèche pour 2 skills (638 l.) ; adaptation
  pour `brainstorming`.
- **Le vrai coût est une arête, pas un volume** : `brainstorming → writing-plans` est un handoff
  terminal obligatoire (« Do NOT invoke any other skill »). Copier verbatim traîne `writing-plans`
  → `executing-plans` → `subagent-driven-development` → `using-git-worktrees`. Réécrire l'arête
  vers la planification VibeFlow = adaptation sur 4 emplacements dont un graphe. Et
  `brainstorming` embarque un serveur HTTP Node que le plugin ne portait pas.
- **Coût annexe** : ~44 l. dans `ensure-deps.sh`, ~9 l. dans `ensure-design-deps.sh`, 8 fixtures de
  test, 2 tables de doc jumelles, 1 ligne de frontière devenue caduque.
- **Licence MIT, Copyright 2025 Jesse Vincent** — notice et texte à conserver ; le dépôt n'a aucun
  précédent de vendorisation tierce. Constat, pas arbitrage.

**Prémisse renversée, consignée comme fait** : superpowers **est déjà multi-runtime** — la version
6.3.0 embarque `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.devin-plugin/`,
`.kimi-plugin/`, `.hermes-plugin/`, `.opencode/`, `.pi/` et `gemini-extension.json`, le manifeste
Kimi portant même un `skillInstructions` qui mappe les gestes vers les outils natifs. **Ce qui est
Claude-only, ce n'est pas le catalogue : c'est l'installeur de VibeFlow.** Fait vérifié — c'est ce
qui a déclenché la révision d'arbitrage du cas d'école ci-dessus : l'indépendance garde sa valeur
quelle que soit la portabilité du tiers, mais la forme de la réponse (rapatrier vs rendre
l'installeur multi-runtime) en dépendait.

## Correctif frontmatter `description: >` — état réel

Un défaut distinct, rencontré pendant cette même mission : 16 `SKILL.md` du dépôt repliaient leur
`description` en bloc YAML `>` (scalaire replié), détruit à la conversion — plus `safe-execute`
dont la frontmatter était déjà invalide en YAML indépendamment de ce défaut.

**Corrigé sur la branche `fix/skill-description-monoline` (commit `450d357`), non encore mergé
sur `main`** — vérifié par containment : `git branch --contains 450d357` ne rend que
`fix/skill-description-monoline` ; `git merge-base --is-ancestor 450d357 main` échoue. Mesure : 17
fichiers touchés, 176 lignes supprimées, 17 insertions (les 16 descriptions repliées sur une ligne
+ `safe-execute`) ; 25/25 SKILL.md parsent, 25/25 descriptions capturables, 4/4 suites vertes
(mesuré par le commit, non re-exécuté dans cette étude).

**Portée pour ce document** : depuis `main` comme depuis la branche de la Phase 37
(`feat/phase-37-spike-portabilite-multi-runtime`, qui n'inclut pas non plus ce commit), les 16
occurrences originales sont toujours présentes. Toute mesure future de ce dépôt sur `main` doit
compter avec le défaut non corrigé tant que la branche n'est pas mergée.

---

## Axe B7 — La mémoire d'agent

### 1. Le recadrage — la question posée par Samuel

Face au choix « où sauver la mémoire d'agent », Samuel a refusé de trancher et posé une question
différente : *« C'est possible de faire des symlinks ou autre ? Je crois que agent-memory est la
norme pour Claude. Je veux respecter les normes de tous les providers, mais adapter en fonction de
COMMENT VF et ses déps ont été installés. »* Cette section traite cette question telle quelle —
elle ne referme aucun autre axe de ce document.

### 2. La norme Claude — documentée, et elle contient déjà une réponse

`memory:` a **trois** valeurs, pas deux : **`user`**, **`project`**, **`local`** (doc officielle
`sub-agents.md` : « Enable persistent memory: user, project, or local »).

| valeur | chemin | statut |
|---|---|---|
| `user` | `~/.claude/agent-memory/` | imposé, non configurable |
| `project` | `.claude/agent-memory/` | imposé, non configurable |
| `local` | `.claude/agent-memory-local/` | imposé, non configurable |

`autoMemoryDirectory` existe mais porte sur la **mémoire de session**, pas sur l'agent-memory.
Aucun `memoryPath` de frontmatter. Format : index `MEMORY.md` + un fichier-sujet par mémoire ;
**seul l'index charge au démarrage**.

**Le constat qui recadre tout, indépendant de toute migration** : Claude Code distingue déjà
`project` (versionnable, voyage avec le repo) de `local` (privé, répertoire séparé exprès). **Les
31 agents posés déclarent tous `memory: project`** — sémantique « voyage avec le repo » — **pendant
que `.gitignore:20` (`.claude/`) leur applique le régime `local`**. Le dépôt utilise la sémantique
`project` en appliquant le traitement `local`. Vérifié par le manager : 31 agents en
`memory: project`, `.gitignore` ligne 20 = `.claude/`.

**Conséquence à écrire** : il faut trancher ce que ces fichiers sont censés être (`project`
versionné / `local` jetable) **avant** de traiter le « où ». Le second choix découle du premier,
et c'est un arbitrage qui existe **aujourd'hui**, migration ou pas.

### 3. Périmètre réel de la mémoire — compteurs avec leur objet

| Objet | Valeur | Commande |
|---|---|---|
| fichiers | **116** | `find .claude/agent-memory -type f \| wc -l` |
| répertoires d'agent hors sondes | **6** | `find … -mindepth 1 -maxdepth 1 -type d -not -name 'zz-probe*'` |
| répertoires **peuplés** | **5** (`skill-creator/` est vide) | boucle sur les dirs |
| répartition | dev-manager 48 · coder 37 · reviewer 19 · auditer 8 · validator 4 | idem |
| index `MEMORY.md` | 5 | `find … -name MEMORY.md \| wc -l` |
| volume | **512 Ko** | `du -sh .claude/agent-memory` |
| `memory:` dans `plugin/` | **52** occurrences / **51** fichiers `.md`, valeur **toujours `project`** | `grep -rn --include='*.md' '^memory:' plugin/` |
| dont agents **posés** | **31** | `plugin/*/agents/*.md` + `plugin/*/AGENT.md` |

**Piège à noter explicitement** : « 6 agents » et « 5 agents » sont **tous deux vrais** selon
qu'on compte les répertoires ou les répertoires peuplés. Les 3 `zz-probe-*` sont des répertoires
**vides** — sondes, à exclure de tout périmètre.

### 4. Les symlinks — mesuré, 9 tests sur répertoire jetable

- **Lecture, écriture, `mkdir` à travers le lien : fonctionnent intégralement** sur POSIX ; tout
  atterrit dans la cible, `realpath` résout.
- **git versionne LE LIEN** (mode `120000`, blob = le texte du chemin), la cible étant versionnée
  séparément sous son vrai chemin. Aucune duplication.
- `.gitignore` = `.claude/` **bloque le lien**. La ré-inclusion **naïve** `.claude/` +
  `!.claude/agent-memory` **ne marche pas** (piège git classique, mesuré, pas supposé) ; la forme
  **correcte** est `.claude/*` + `!.claude/agent-memory`.
- **Cible hors dépôt** : git ne versionne que le lien, avec un chemin **absolu** donc
  machine-spécifique ; le contenu n'est pas versionné du tout. Sur une autre machine : lien
  pendant, écriture en échec.
- **Scénario réel mesuré** (`.gitignore` inchangé, commit, clone frais) : **le contenu voyage, le
  lien ne voyage PAS** → `.claude/agent-memory` absent du clone. Le problème est **déplacé d'un
  cran, pas résolu**.

**Deux conditions dures** : le lien doit lui-même être versionné (`.claude/*` + `!`), et il doit
être **relatif et interne au dépôt**.

### 5. Aucune garde ne bloque ce montage — mesuré

- **gsd-core** : `hasExistingSymlinkBetween` ne couvre que ses propres destinations. **gsd-core
  ignore totalement `agent-memory` : 0 occurrence dans tout le paquet.** Un opt-in existe déjà en
  amont pour les montages voulus (`GSD_ALLOW_SYMLINKED_DEST=1`).
- **VF engine** : `vf_removable` refuse de supprimer ce qui n'est pas un fichier régulier et
  refuse une résolution hors `TARGET_ROOT` — protecteur, et sans effet ici puisque l'engine ne
  pose jamais rien sous `agent-memory`.
- **Ne pas confondre** : l'exclusion `memory/*` du manifeste concerne les registres à la racine
  du lab, **pas** `.claude/agent-memory/`.
- **Précédent maison à manier avec précaution** : `.planning/research/agent-team-spec.md`
  affirme qu'un skill et un agent symlinkés sont découverts — mais c'est un document **importé
  d'un autre projet**, marqué « entrée de recherche, pas source de vérité », et il porte sur la
  **lecture**, pas sur l'**écriture** d'agent-memory. Indice fort, pas une preuve.

### 6. Windows — le montage y est inapplicable, et le dépôt le sait

`ensure-deps.sh` détecte MSYS2/Cygwin et **refuse proprement** plutôt que d'échouer à mi-course.
`.planning/research/STACK.md` documente déjà que **MSYS `ln -s` copie par défaut** (symlink natif
seulement avec Developer Mode + `MSYS=winsymlinks:nativestrict`). Mesure indépendante côté git :
`core.symlinks=false` → le lien est déposé comme **fichier régulier**, et l'écriture à travers
échoue en `Not a directory`.

→ Toute liaison par lien exige une branche de dégradation Windows (copie, ou rien), sur le modèle
déjà retenu ailleurs dans le dépôt.

### 7. Les runtimes cibles — perte de capacité franche

| Runtime | Mémoire d'agent par projet | Détail | Statut |
|---|---|---|---|
| **Codex 0.150.1** | **partiel, topologie inverse** | feature `memories` **stable mais `false` par défaut** (vérifié par le manager) ; store **global** `~/.codex/memories/` (**absent sur ce poste**, feature désactivée) ; le scope projet est une **annotation `cwd=…`**, pas un chemin. Sous-agents à frontmatter oui, **champ `memory:` non**. | **observé** |
| **OpenCode** | **non** | `AGENTS.md` (instructions humaines) + transcripts JSON bruts jamais consolidés. Frontmatter sans `memory:`. | **documenté** |
| **kimi-code** | **non** | `AGENTS.md` + état de session resumable. Frontmatter sans `memory:`. | **documenté** |

**À écrire tel quel** : la mémoire d'agent par projet est une **capacité spécifique à Claude
Code**. C'est une perte de capacité à **déclarer** par le gate de fidélité, pas un trou à combler.

**Réserve de méthode à consigner** : la feature request Kimi trouvée est déposée sur `kimi-cli`,
**pas** `kimi-code` — deux produits distincts que le cadrage désignait déjà comme piège. À
re-vérifier sur le bon repo avant d'être gravé.

**Découverte non demandée, et c'est le seul chemin de portage crédible** : le binaire Codex
contient un migrateur `external-agent-migration` reconnaissant `claude-code`, dont les types
d'items incluent littéralement `MEMORY`. Le flag `external_agent_memory_import` est **`under
development`** (vérifié par le manager). C'est amont, pas à écrire côté VF.

### 8. « Adapter selon comment VF a été installé » — trois étages distincts, à ne pas fusionner

1. **Amont (gsd-core)** : introduire un `kind: memory` dans `artifactLayout`. Vocabulaire actuel
   des `kind` : `agents`, `skills`, `commands`, `kimi-agents` — **aucun `kind: memory` nulle
   part**. Coût faible en lignes, **valeur quasi nulle en l'état** : 3 des 4 runtimes n'ont **pas
   de destination**, la règle ne dirait « rien » 3 fois sur 4. Et c'est une **contribution
   amont**, pas du code VF (doctrine : VibeFlow consomme, ne réimplémente pas).
2. **VF engine** : pour appliquer une règle par runtime, l'engine doit d'abord **acquérir une
   dimension qu'il n'a pas** — `TARGET_ROOT` est 2 branches en dur (`user → $HOME/.claude`,
   `project|local → ./.claude`), sans `--target` ni `RUNTIME`. **C'est le vrai coût, et il dépasse
   largement la mémoire : c'est le chantier de l'axe B au complet** (cf. A4, §Proposition de
   cadrage).
3. **Mécanisme de liaison** : symlink / copie / rien, avec branche Windows obligatoire (§6), lien
   relatif interne versionné (§4), et un inconnu bloquant non levé (§9 ci-dessous).

**Recoupement à consigner** : les « 13 règles de placement » (A4) se re-dérivent exactement —
codex 2+2=4, opencode 3+3=6, kimi-code 2+1=3 — et l'objet compté est nommé : une entrée
d'`artifactLayout`.

**Le point dur n'est aucun des trois** : **116 fichiers non relus vivent dans un dépôt public.**
Toute règle de placement qui les versionne **les publie**. La question de publication précède la
question de placement, et elle n'est pas technique.

---

## Proposition de cadrage

Trois options pour porter ces deux axes, coûts et dépendances :

| option | ce qu'elle couvre | dépendances | coût |
|---|---|---|---|
| **Phase 38 à part** | canal d'install multi-runtime (A) + migration de lab (B) comme livrable dédié | doit attendre l'arbitrage `--target` (A4) et le sort de `vf-calibrate` (B4) | le plus lourd, mais le seul qui traite B2 (trou de rollback) et B5 (détection non garantie) comme du travail de premier ordre |
| **Extension de la Phase 37** | ajoute A/B au spike déjà livré, avant clôture | rouvre un spike déclaré terminé (`SPIKE-REPORT.md`, `DISCUSS.md` non touchés par ce mandat) | risque de diluer un livrable déjà revu ; pas de a fortiori sur le budget déjà consommé |
| **Repli dans l'adaptateur recommandé par le spike** | traite A/B comme des cas particuliers de la couche d'abstraction déjà proposée (`copyWithPathReplacement` + équivalent runtime-aware) | suppose que l'adaptateur soit lui-même acté et planifié | le plus économe en cadrage, mais reporte B2/B5 à l'implémentation — risque qu'ils ne soient jamais nommés comme lots séparés |

**Recommandation** : Phase 38 à part. Trois raisons distinctes de cette étude, pas du spike
initial : (1) B2 (trou de rollback : agents et hooks jamais restaurés, `mark_installed` jamais
appelé) est un défaut de l'engine **actuel**, indépendant de tout choix multi-runtime — il mérite
un lot nommé même si l'arbitrage runtime tarde ; (2) le coût du `--target` (A4, 198 fichiers / 1130
occurrences) est un chantier de taille comparable à une phase, pas un ajout marginal à un spike
déjà clos ; (3) le bloqueur d'installeur mesuré (11 sites `claude plugin install`/`command -v
claude` dans les deux scripts `ensure`) est désormais un chantier nommé et chiffré, distinct du
plan de secours superpowers — même s'il ne couvre que 2 des 4 runtimes avec une commande mesurée
(Claude, Codex partiellement), il ne dépend d'aucun autre arbitrage pour démarrer.

**La décision appartient à Samuel (ADR-031). Rien ne se lance sans son arbitrage** — ni le choix
d'option ci-dessus, ni l'ouverture d'un `--target`, ni le sort de `vf-calibrate`.

**Ajout B7 (mémoire d'agent)** : la mémoire d'agent n'est **pas un chantier autonome** — son étage
2 (§8.2 ci-dessus, acquisition d'une dimension runtime par l'engine) **est** le chantier de l'axe
B au complet, pas un ajout marginal. Ce qui est **séparable et actionnable dès maintenant, sans
attendre l'arbitrage `--target`**, c'est le **décalage déclaratif** `memory: project` vs
`.gitignore: .claude/` (§2) — un fait mesuré aujourd'hui, indépendant de toute migration multi-
runtime. Cette proposition ne tranche rien : la décision — corriger la déclaration, corriger le
`.gitignore`, ou assumer le décalage — appartient à Samuel (ADR-031), au même titre que le reste
de ce cadrage.

---

## Ce qui reste inconnu

Repris tel quel depuis les sections ci-dessus, sans en combler aucun :

- **A2** — combien de skills Codex enregistre réellement depuis `"skills": "./installer"` (0 ou
  1) : inférence depuis la forme curée, exige une session Codex vivante.
- **A2** — si les 7 commandes VibeFlow peuvent se reposer comme skills Codex : plausible, non
  mesuré.
- **B1** — l'« échec silencieux » d'un plan sous un autre runtime (import `@` propriétaire inerte)
  est inféré, pas observé : aucune migration réelle n'a été exécutée.
- **B2** — l'ampleur réelle de la collision de glob `rollback` (`$mod-<ts>-removed`) : structurellement
  établie par lecture de code, non manifestée sur ce poste (aucun répertoire `-removed` présent).
- **Installeur multi-runtime** — la commande exacte de sous-installation Codex après `codex plugin
  marketplace add` (le transport et le manifeste sont mesurés ce spike, pas l'enchaînement complet
  jusqu'à un agent utilisable) ; les commandes d'install OpenCode et kimi-code : documentaires,
  jamais exécutées.
- **B7** — le harness Claude suit-il un symlink à l'**écriture** d'agent-memory ? Non mesurable
  sans agent vivant dans ce cwd — le comportement POSIX n'en dit rien (le harness peut `lstat` et
  refuser, ou remplacer le lien).
- **B7** — valeur **par défaut** de `memory:` si le champ est absent du frontmatter — non
  documentée.
- **B7** — quotas / compaction de l'agent-memory — non documentés.
- **B7** — `kimi-code` vs `kimi-cli` : concordants sur l'absence de mémoire d'agent, mais
  re-vérification ciblée requise avant d'être gravé.
- **B7** — calendrier de `external_agent_memory_import` chez Codex — flag `under development`,
  aucune date connue.
