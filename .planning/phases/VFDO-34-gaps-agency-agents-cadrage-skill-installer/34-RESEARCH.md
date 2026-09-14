# Phase 34 : Gaps agency-agents & cadrage skill-installer — Recherche

**Recherché le :** 2026-09-15
**Domaine :** gouvernance de parc d'agents (audit sans code), run réel d'équipe de test mobile
autonome, mécanique native des skills Claude Code
**Confiance :** HIGH sur AGTS-01 (mesures directes sur le dépôt) et sur les prérequis machine
d'AGTS-02 (commandes exécutées) ; MEDIUM sur SKIL-01 (docs officielles citées + mesures locales,
mais le spike lui-même reste à exécuter par le plan) ; LOW sur un point isolé (quel des deux
simulateurs « iPhone 17 Pro » porte la session authentifiée — non mesurable sans geste d'état).

## Summary

Les trois volets sont documentaires par construction (D-10) : cette recherche ne tranche aucun des
trois verdicts, elle rassemble ce qu'il faut pour les rendre sur pièces. Pour **AGTS-01**, la
matrice division → module du 2026-07-20 est re-mesurée aujourd'hui et n'a **pas bougé** : toujours
25 fichiers `plugin/*/agents/*.md` + 6 `plugin/*/AGENT.md` = 31, `web-test-team` toujours absent —
et une recherche exhaustive de `.planning/` (BACKLOG, STATE, research/, missions/, phases/) ne fait
remonter **aucune trace** d'incident documenté, de demande externe ou de bug récurrent pour aucun
des gaps « 🟡 »/« ❌ » de la matrice (Support, Sales fin, Product, Paid Media, Spatial/Game/
Healthcare/GIS/Academic) — la conclusion structurelle qui en découle (verdict par gap) revient à la
phase, pas à cette recherche, mais le terrain est net : zéro preuve trouvée nulle part.

Pour **AGTS-02**, les prérequis système sont **tous PRESENTS** sur ce poste (Maestro 2.6.1, JDK 17
Homebrew, Node v26.5.0, 7 simulateurs iPhone 17 disponibles, module `mobile-test` posé en scope
user) et les 11 flows Maestro existent déjà dans `Scroll-Off/frontend/.maestro/`. Mais deux
prérequis **spécifiques au lab** ne sont PAS couverts par la liste de commandes fournie et doivent
être traités avant le run : (1) **aucun fichier de config projet** (`.vibeflow/mobile-test.json` ou
`mobile-test.json`) n'existe dans `Scroll-Off/frontend` — le script `run` refuse de démarrer sans
lui (`detect` seul n'en a pas besoin) ; (2) **deux simulateurs distincts s'appellent tous les deux
« iPhone 17 Pro »** (runtimes iOS 26.2 et iOS 26.4) et le script résout le nom par le premier trouvé
dans l'énumération — sans savoir lequel porte déjà l'app installée et la **session authentifiée non
reproductible** documentée dans `.maestro/README.md` du lab. Cette session est une contrainte dure :
aucun flow ne doit jamais `clearState`/`clearKeychain`/désinstaller, et le run doit identifier
explicitement (par `--target <udid>`) le bon simulateur avant de jouer quoi que ce soit — deux
prérequis « projet », pas « poste », donc hors du strict cadre D-05 (qui vise Maestro/JDK/simulateur/
SDK), à traiter comme une tâche de préparation du plan, pas comme une cause d'arrêt propre.

Pour **SKIL-01**, la documentation officielle Claude Code actuelle affirme sans détour que « the
subagent can still discover and invoke project, user, and plugin skills through the Skill tool
during execution » — ce qui, si confirmé par le spike, **réduit fortement** la probabilité que le
différenciateur identifié en 2026-06-04/2026-08-15 (« rendre les skills disponibles à tous les
agents ») existe encore techniquement. Une mesure locale, indépendante de tout spike, renforce le
signal : sur les 25 agents distribués, **seuls 7 ont `Skill` dans leur frontmatter `tools:`** — les
autres (tous les workers `vf-internal: true`, Pattern 12) ne peuvent invoquer AUCUN skill
aujourd'hui, quel que soit le canal d'install, parce que l'outil `Skill` leur est retiré par
construction. Ce constat n'est pas la question de SKIL-01 (qui porte sur le canal), mais il borne
fortement ce qu'un GO pourrait changer : même un skill-installer parfait ne rendrait rien
disponible à `vf-app-fixer` ou `vf-test-runner` sans un second geste (ajouter `Skill` à leur
`tools:`), hors périmètre de cette phase.

**Recommandation principale :** traiter les trois volets dans l'ordre de risque décroissant — le
run mobile d'abord (le plus long, le seul à pouvoir produire du code sur GO), le spike SKIL en
parallèle (mesure rapide, IO faible), l'audit AGTS-01 en dernier (aucune dépendance externe, peut
se rédiger à tout moment une fois la re-mesure faite — déjà largement pré-mâchée par cette
recherche).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Audit de couverture agency-agents (AGTS-01) | Documentation / gouvernance (aucun tier applicatif) | — | Livrable = note Markdown, aucun code |
| Run mobile-test(-team) sortie d'expérimental (AGTS-02) | Agent tier — sous-agents VF (`vf-test-orchestrator`/`vf-test-runner`/`vf-app-fixer`) | Device tier — simulateur iOS (Maestro, `simctl`) | La boucle vit dans les sous-agents Claude Code, mais l'exécution réelle est sur le simulateur (build Expo, JDK, Maestro) |
| `web-test-team` (SI run vert) | Agent tier — nouveau module `plugin/web-test-team` | Browser tier — Playwright pilote un navigateur réel | Calque exact du moule `mobile-test-team`, remplace simulateur/Maestro par navigateur/Playwright |
| Spike SKIL-01 (mesure d'exécution) | Agent tier — Skill tool + sous-agents Task | Plugin/install tier — canal natif `/plugin`, engine `vibeflow-update.sh` | La question porte sur la frontière entre le mécanisme de pose (plugin/engine) et la visibilité runtime côté sous-agent |
| Skill-installer global (SI GO — hors périmètre code de cette phase) | Plugin/install tier — extension de `vibeflow-update.sh` | — | Réutilise le manifeste (Phase 31), aucun nouveau tier |

## Package Legitimacy Audit

Aucun package externe n'est installé dans cette phase (documentaire + agents Markdown + config
JSON). `Playwright` est mentionné comme dépendance future de `web-test-team` **côté lab
utilisateur** (`.planning/research/STACK.md:105`), jamais côté plugin — sa légitimité sera à vérifier
au moment où un plan la fait entrer dans un `package.json` réel, pas ici. **Section non applicable
à cette phase.**

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AGTS-01 | Gaps arbitrés par distillation de la taxonomie du catalogue, zéro import de persona | Matrice re-mesurée (§ Volet 1), corpus exact des 25+6 fichiers listé, recherche de preuve exhaustive dans `.planning/` (résultat : aucune trouvée) — le verdict par gap reste au plan/exécution |
| AGTS-02 | Tentative de sortie d'expérimental par run réel sur `Scroll-Off/frontend`, iOS seulement | Tableau des prérequis mesurés (§ Volet 2), script `mobile-test-run.mjs` documenté fonction par fonction, deux risques spécifiques au lab identifiés (config absente, ambiguïté simulateur, contrainte session non reproductible) |
| SKIL-01 | Spike mesuré go/no-go sur l'atteinte des sous-agents par un skill `/plugin` | Doc officielle citée verbatim (§ Volet 3), mesure locale de la frontière `tools: Skill` sur les 25 agents distribués, protocole de spike à contrôle négatif proposé |
</phase_requirements>

## Standard Stack

Aucune nouvelle dépendance de stack plugin. Les seules briques mobilisées sont déjà distribuées :

| Composant | Version mesurée sur ce poste | Rôle dans la phase |
|-----------|-------------------------------|---------------------|
| Maestro CLI | 2.6.1 (`maestro --version`) [VERIFIED: commande exécutée le 2026-09-15] | Régression E2E mobile jouée par `mobile-test-run.mjs` |
| OpenJDK | 17.0.19 Homebrew (`java -version`) [VERIFIED: commande exécutée] | Requis par Maestro |
| Node | v26.5.0 (`node --version`) [VERIFIED: commande exécutée] | Exécute `mobile-test-run.mjs` (zéro dépendance npm, JUnit parsé par regex) |
| Xcode / `simctl` | 7 simulateurs iPhone 17 disponibles (`xcrun simctl list devices available`) [VERIFIED: commande exécutée] | Cible du run iOS |
| `mobile-test` (module VF) | posé en scope user (`~/.claude/skills/mobile-test`, `~/.claude/scripts/mobile-test-run.mjs`) [VERIFIED: ls exécuté] | Pipeline mécanique du run |

**Installation :** rien à installer — tout est déjà présent. Aucune commande `npm install` /
`pip install` n'entre dans cette phase.

## Architecture Patterns

### System Architecture Diagram — boucle AGTS-02 (run mobile)

```
Manager de mission
   │ dispatch (Agent tool)
   ▼
vf-test-orchestrator  ──garde projet mobile──►  décline si pas Expo/RN
   │ 1. dispatch                         2. dispatch (après échec)
   ▼                                         ▼
vf-test-runner                           vf-app-fixer
 (possède .maestro/**,                   (possède src/**, app/**,
  lance mobile-test-run.mjs)              jamais les tests)
   │                                         │
   ▼                                         ▼
mobile-test-run.mjs detect/run ──boote sim──► simulateur iOS (Maestro test .maestro/)
   │
   ▼
rapport horodaté (test-runs/<stamp>.md) + maestro-junit.xml
   │
   ▼
vf-test-orchestrator : baseline verte, anti-régression, anti-thrash, halt conditions
   │
   ▼
bloc typé {statut, findings, noeuds_debloques} → vf-dev-manager
```

### System Architecture Diagram — spike SKIL-01

```
Session Claude Code (Claude d'abord — D-08)
   │
   ├─► Contrôle négatif : skill inexistant nulle part
   │      └─► sous-agent Task (tools inclut Skill) tente Skill("nonce-inexistant")
   │             └─► attendu : échec / "skill not found"
   │
   ├─► Cas cible A : skill posé via /plugin natif (scope user)
   │      └─► claude plugin marketplace add <repo-jetable>
   │      └─► claude plugin install <plugin-jetable>@<marketplace>
   │      └─► sous-agent Task (tools inclut Skill) invoque le skill par son nom namespacé
   │             └─► mesuré : contenu du skill reçu ou non
   │
   ├─► Cas cible B : skill posé via /plugin natif (scope project)
   │      └─► même protocole, scope project
   │
   └─► Verdict : GO si (négatif = échoue) ET (positif A/B = réussit) ET qu'aucun mécanisme VF
       existant ne couvre déjà ce cas → sinon NO-GO documenté
```

### Recommended Project Structure (si `web-test-team` construit sur run vert)

```
plugin/web-test-team/
├── module.json                      # requires: [] (Playwright = dépendance lab, pas plugin)
├── README.md                        # même structure que mobile-test-team/README.md
├── agents/
│   ├── vf-test-orchestrator.md      # RENOMMER pour éviter collision avec mobile-test-team —
│   │                                #   voir Pitfall ci-dessous : les deux modules ne peuvent
│   │                                #   pas poser le même nom de fichier agent
│   ├── vf-web-test-runner.md        # clone de vf-test-runner.md, domaine .maestro → playwright specs
│   └── vf-web-app-fixer.md          # clone de vf-app-fixer.md, domaine app inchangé
├── rules/
│   └── web-verify-gate.md           # clone path-scopé de mobile-verify-gate.md, marqueurs web
└── references/
    └── test-loop-protocol.md        # réutilisable tel quel si le protocole de boucle ne change pas
```

### Pattern 1 : Pattern 12 (workers cloisonnés, `vf-internal: true`)
**What :** un orchestrateur (`Task`/`Agent` tool + halt conditions) dispatche deux workers dont les
domaines d'écriture sont mutuellement exclusifs — l'un possède les tests, l'autre le code
applicatif, aucun des deux n'a l'outil `Task`.
**When to use :** toute boucle test → corrige → re-test autonome.
**Example (source lue ce jour, `plugin/mobile-test-team/agents/vf-test-runner.md` et
`vf-app-fixer.md`) :**
```yaml
# vf-test-runner.md
tools: Read, Edit, Write, Bash, Glob, Grep
vf-internal: true
# INTERDIT : modifier le code app (src/**, app/**, components/**, backend)

# vf-app-fixer.md
tools: Read, Edit, Write, Bash, Glob, Grep
vf-internal: true
# INTERDIT : le dossier des tests (.maestro/** ou maestroFlowsDir)
```

### Pattern 2 : gate recherche documentaire avant fix aveugle (ADR-045)
**What :** avant de redispatcher `vf-app-fixer` sur un flow déjà tenté, ou si `vf-app-fixer`
remonte `doc-research-required`, l'orchestrateur porte lui-même la recherche (il a le web, le
worker ne l'a pas).
**When to use :** toute cause d'échec suspectée liée à une lib/framework/natif/version d'OS-SDK.
**Example (source lue ce jour, `vf-test-orchestrator.md`) :** « `vf-app-fixer` n'a pas le web
(cloisonnement anti-triche = code/tests, pas la doc) ; toi, tu l'as : porte la recherche TOI-MÊME
(context7 + WebSearch...) ».

### Anti-Patterns to Avoid
- **Importer des personas du catalogue tel quel :** densité ADR-029 incompatible (230+ agents plats,
  0-250L/agent visé), aucune gouvernance `check-agents.sh` côté catalogue source. Confirmé anti-
  feature gravée (`REQUIREMENTS.md:1094`).
- **Plus de 2-3 agents ajoutés d'un coup :** signal d'alarme explicite du Pitfall 12 — même pour un
  futur comblement de gap hors de cette phase.
- **Construire `web-test-team` sans le run vert :** cloner un moule non prouvé rejoue le motif
  « armé sans preuve » (D-06) — le milestone entier existe pour fermer ce motif.
- **Forcer un rebuild/reinstall sur le simulateur qui porte la session authentifiée du lab
  Scroll-Off** (voir Pitfall dédié ci-dessous) — détruit un état non reproductible sans intervention
  humaine.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Détecter un simulateur/émulateur booté | Un script de parsing `simctl`/`adb` maison | `mobile-test-run.mjs detect` (déjà écrit, déjà JSON) | Le script existe, est posé en scope user sur ce poste, gère la cascade de résolution config/PATH/JAVA_HOME |
| Parser un rapport JUnit Maestro | Un parseur XML | La regex déjà dans `mobile-test-run.mjs:parseJunit` (zéro dépendance) | Fonctionne déjà, pas de dépendance npm à ajouter |
| Collision de nom entre skills | Une table de résolution de nom maison côté engine VF | Le namespacing automatique du canal `/plugin` natif (`/plugin-name:skill-name`) | Le canal natif empêche déjà structurellement la collision — un GO SKIL-01 devrait s'appuyer dessus plutôt que réinventer un registre |
| Backup/rollback/désinstallation de `SKILL.md` | Un second mécanisme d'ownership pour le skill-installer | Le chemin déjà outillé de `vibeflow-update.sh` (`vf_place_file`, `backup_module`, `_vf_uninstall_from_cache`, lignes 2218-2229/2478/2606-2608/2726) | Explicitement rappelé en D-07/canonical_refs : « un GO SKIL-01 réutiliserait ce chemin, il n'en ouvrirait pas un second » |

**Key insight :** dans ce domaine, la tentation de « refaire en petit et mieux » (un registre
maison pour les gaps agency-agents, un second système de pose pour les skills) recrée exactement ce
que la charte a fermé (couche de synonymes, v2.33.0) — le Pitfall 12 le nomme explicitement.

## Runtime State Inventory

> Ce n'est pas une phase de rename/refactor — section omise. Le run AGTS-02 touche un état
> runtime réel (session simulateur), traité comme un Pitfall dédié ci-dessous, pas comme un
> inventaire de migration.

## Common Pitfalls

### Pitfall 1 : le run mobile détruit une session authentifiée irremplaçable
**What goes wrong :** `Scroll-Off/frontend/.maestro/README.md` déclare que la session authentifiée
actuelle sur le simulateur de recette a été obtenue via un code à 6 chiffres **déjà consommé** et
n'est **pas reproductible sans intervention humaine**. Si le run force un `clearState`, un
`clearKeychain`, une désinstallation, ou même un rebuild qui réinstalle l'app sur le **mauvais**
simulateur (voir Pitfall 2), les flows `lot2_*`/`lot3_*`/`lot4_*` (état authentifié) deviennent
injouables pour de bon.
**Why it happens :** le README de la sortie d'expérimental (`plugin/mobile-test/README.md:119-123`)
décrit la condition de sortie comme « build depuis zéro » — mais un « build depuis zéro » signifie
concrètement, dans `mobile-test-run.mjs:cmdRun`, que l'app n'est PAS encore installée sur la cible
(`isInstalledIos` renvoie faux), ce qui déclenche `buildInstall` → `expo run:ios`. Si la cible
choisie est déjà celle qui porte la session, ce chemin ne se déclenche pas (l'app est détectée
installée, le script va directement à Maestro) — mais si le mauvais simulateur est choisi (aucune
app installée dessus), le script fera un build ET une install à neuf, sur le mauvais device, sans
toucher au bon — ce qui ne casse rien mais ne teste rien non plus d'authentifié.
**How to avoid :** avant tout `run --platform ios`, identifier EXPLICITEMENT (par un `xcrun simctl
get_app_container <udid> com.scrolloff.app.ios` sur chaque candidat, après avoir booté chacun sans
y toucher davantage) lequel des deux simulateurs « iPhone 17 Pro » porte déjà l'app + la session, et
passer `--target <udid>` explicitement plutôt que de laisser `ios.preferredSimulator` (résolution
par nom, premier trouvé) choisir. Ne jamais lancer un flow avec `clearState: true` ou
`clearKeychain` (déjà interdit par le README du lab lui-même).
**Warning signs :** un flow `lot2_*`/`lot3_*`/`lot4_*` qui échoue immédiatement sur un écran de
login au lieu de l'écran attendu = la session a été perdue, arrêt immédiat, ne pas retenter.

### Pitfall 2 : deux simulateurs partagent le même nom
**What goes wrong :** `xcrun simctl list devices available` renvoie DEUX entrées « iPhone 17 Pro »
distinctes (`8BD53E84-...` sur runtime iOS-26-2, `48100F83-...` sur runtime iOS-26-4)
[VERIFIED: `xcrun simctl list devices available --json` exécuté le 2026-09-15, sortie parsée].
`ensureIosTarget()` dans `mobile-test-run.mjs` résout `cfg.ios.preferredSimulator` en itérant
`data.devices[rt]` par runtime et prend le **premier match** — non déterministe du point de vue de
l'appelant si les deux runtimes contiennent un device de ce nom.
**Why it happens :** deux simulateurs homonymes créés à des dates différentes (mise à jour Xcode
entre les deux), aucun mécanisme du script ne les distingue par UDID sauf via `--target` explicite.
**How to avoid :** voir Pitfall 1 — résoudre l'UDID porteur de l'état avant de lancer `run`, le
passer en `--target`.
**Warning signs :** deux runs consécutifs donnent des résultats différents pour le même flow sans
changement de code.

### Pitfall 3 : config projet absente = `run` refuse de démarrer
**What goes wrong :** `Scroll-Off/frontend` n'a ni `.vibeflow/mobile-test.json` ni
`mobile-test.json` à sa racine [VERIFIED: `find` exécuté le 2026-09-15, aucun résultat].
`mobile-test-run.mjs:loadConfig()` fait `fail()` avec un message explicite si aucun des 4 chemins de
la cascade n'existe. `detect` fonctionne sans config (aucun appel à `loadConfig`) ; `run` en a besoin.
**Why it happens :** le module ne présume aucune valeur projet (bundle id, nom de simulateur) —
c'est une garantie de portabilité, pas un oubli.
**How to avoid :** créer le fichier de config AVANT le premier `run`, avec les valeurs déjà connues
et vérifiées sur ce lab (voir Code Examples ci-dessous) — ce n'est PAS un « prérequis manquant » au
sens D-05 (Maestro/JDK/simulateur/SDK) : c'est une tâche de préparation projet normale, à écrire par
le plan, pas une cause d'arrêt propre.
**Warning signs :** message d'erreur `Config introuvable` du script — s'il apparaît malgré le
fichier créé, vérifier le chemin exact (`.vibeflow/mobile-test.json` prioritaire sur
`mobile-test.json` racine).

### Pitfall 4 : conflit de nommage entre `mobile-test-team` et `web-test-team`
**What goes wrong :** si `web-test-team` clone `mobile-test-team` fichier par fichier sans renommer
les agents, `agents/vf-test-orchestrator.md` de `web-test-team` écraserait ou entrerait en collision
avec celui de `mobile-test-team` au moment de la pose (`vibeflow-update.sh` place chaque agent en
`$TARGET_ROOT/agents/<mod>.md` — ici le fichier source s'appelle `vf-test-orchestrator.md` dans les
deux modules, mais la pose finale nomme par le **contenu du frontmatter `name:`**, pas par le nom de
fichier module ; deux modules posant un agent de même `name:` se marchent dessus).
**Why it happens :** copier-coller mécanique du moule sans renommage systématique.
**How to avoid :** au clonage, renommer explicitement en `vf-web-test-orchestrator` /
`vf-web-test-runner` / `vf-web-app-fixer` (ou équivalent), fichier ET `name:` frontmatter, dès la
première ébauche — jamais après coup.
**Warning signs :** `check-agents.sh --resolve-agents=strict` en monde fermé (CI) remonterait une
ambiguïté de nom si les deux gardent le même `name:`.

### Pitfall 5 : le doc officiel dit que le canal natif atteint déjà les sous-agents — mais la plupart des agents VF n'ont pas l'outil `Skill`
**What goes wrong :** un GO SKIL-01 pourrait sembler résoudre un problème qui n'existe déjà plus
(le canal natif `/plugin` place des skills dans une catégorie — « plugin skills » — que la doc
officielle actuelle décrit comme découvrable par les sous-agents via l'outil `Skill`). Mais sur les
25 agents distribués dans `plugin/*/agents/*.md`, seuls 7 déclarent `Skill` dans leur frontmatter
`tools:` [VERIFIED: grep exécuté sur les 25 fichiers le 2026-09-15, voir tableau § Volet 3] — tous
les workers `vf-internal: true` (Pattern 12) en sont dépourvus. Un skill-installer parfait ne
changerait rien pour ces agents-là tant que leur `tools:` n'inclut pas `Skill`.
**Why it happens :** conception délibérée (Pattern 12 : les workers cloisonnés n'ont accès qu'à un
outillage minimal) — mais cela borne fortement la portée utile d'un futur GO.
**How to avoid :** le verdict SKIL-01 doit distinguer explicitement « le canal atteint-il un
sous-agent qui A l'outil `Skill` » (la vraie question du spike, D-07) de « tous les agents VF
peuvent-ils déjà invoquer des skills » (non — c'est un choix d'architecture séparé, hors périmètre
de cette phase).
**Warning signs :** un spike qui conclurait au GO sans mentionner cette distinction produirait un
cadrage trompeur pour la phase de câblage ultérieure.

## Code Examples

### `.vibeflow/mobile-test.json` pour `Scroll-Off/frontend` (valeurs vérifiées ce jour)
```json
{
  "bundleIdBase": "com.scrolloff.app.ios",
  "debugSuffix": "",
  "ios": { "preferredSimulator": "iPhone 17 Pro" },
  "maestroFlowsDir": ".maestro",
  "maestroBin": "~/.maestro/bin/maestro",
  "reportsDir": "test-runs",
  "metroPort": 8081,
  "javaHome": ""
}
```
Sources vérifiées ligne par ligne ce jour : `bundleIdBase` = `com.scrolloff.app.ios`
[VERIFIED: `~/Documents/dev/Scroll-Off/frontend/app.json:13` — `"bundleIdentifier":
"com.scrolloff.app.ios"`] ; `ios.preferredSimulator` = `"iPhone 17 Pro"`
[VERIFIED: `~/Documents/dev/Scroll-Off/frontend/.maestro/README.md` ligne 4-5 — `simulateur "iPhone
17 Pro"`] ; le reste reprend les défauts du template
[CITED: `plugin/mobile-test/config/mobile-test.example.json`]. **Le choix du bon UDID reste ouvert
(Pitfall 2)** — ce fichier fixe le NOM, pas l'UDID ; `run --target <udid>` prime sur la résolution
par nom si l'UDID exact est fourni en ligne de commande.

### Identifier sans risque quel simulateur porte l'état (à faire AVANT tout `run`)
```bash
# Booter chaque candidat un par un (état non destructeur — un boot seul n'efface rien) puis vérifier
xcrun simctl boot 8BD53E84-B5BF-482A-8FE5-6A9980555951  # ou l'autre UDID
xcrun simctl get_app_container 8BD53E84-B5BF-482A-8FE5-6A9980555951 com.scrolloff.app.ios
# Une sortie de chemin = app installée sur CE simulateur. Une erreur 405/404 = pas installée ici.
```
[VERIFIED: `xcrun simctl get_app_container <udid> com.scrolloff.app.ios` testé sur les deux UDID
éteints le 2026-09-15 → `error 405 : Unable to lookup in current state: Shutdown` sur les deux — la
commande EXIGE que le simulateur soit `Booted` pour répondre ; aucun boot n'a été effectué dans
cette recherche (hors périmètre read-only), donc **lequel des deux porte l'état reste un fait non
mesuré à ce stade — à lever par la première tâche du plan, avant tout run Maestro**.]

### Skill 100% absent vs présent — lecture du texte source de la doc officielle
```
"The full content of each listed skill is injected into the subagent's context at startup.
This field controls which skills are preloaded, not which skills the subagent can access:
without it, the subagent can still discover and invoke project, user, and plugin skills
through the Skill tool during execution."
```
[CITED: https://code.claude.com/docs/en/sub-agents — section « Preload skills into subagents »,
récupéré le 2026-09-15]
```
"To prevent a subagent from invoking skills entirely, omit `Skill` from the `tools` list or
add it to `disallowedTools`."
```
[CITED: https://code.claude.com/docs/en/sub-agents, même page]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Skill installé uniquement en scope user/project (fichier brut `~/.claude/skills/<nom>/`) | Le canal `/plugin` natif place aussi des skills, namespacés (`/plugin-name:skill-name`), catégorisés séparément des skills « personal »/« project » par la doc | Capacité déjà présente dans Claude Code actuel (pas de date de bascule identifiable depuis cette session) | Réduit la surface du différenciateur F8 identifié en 2026-06-04 — à confirmer par le spike, pas par cette recherche |
| — | `Cowork` et les sessions cloud **ne lisent PAS** `~/.claude/skills/` (seuls les skills projet commités et les skills synchronisés du compte claude.ai le sont) | Documenté aujourd'hui | Hors périmètre VF (VibeFlow cible du Claude Code local, pas Cowork) mais pertinent si un jour VF vise des sessions cloud |

**Déprécié/obsolète :** rien identifié — le canal `/plugin` et le mécanisme skills coexistent, pas
de dépréciation annoncée.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | Le simulateur qui porte la session authentifiée Scroll-Off est identifiable sans la détruire, via `simctl get_app_container` une fois booté | Pitfall 1/2, Code Examples | Si faux (ex. les deux simulateurs ont l'app installée pour une raison quelconque), le run choisirait quand même arbitrairement — nécessiterait un critère de départage supplémentaire (ex. date de modification du conteneur) |
| A2 | Un `run --platform ios` sur un simulateur où l'app est DÉJÀ installée ne redéclenche jamais `buildInstall` (donc ne touche pas Keychain) | Pitfall 1 | Vérifié par lecture du code (`cmdRun` : `if (!installed) { buildInstall(...) }` sinon branche `ensureMetro` seule) — code lu ce jour, comportement dérivé de la lecture, pas d'un run réel exécuté |
| A3 | Le spike SKIL-01, une fois exécuté, confirmera empiriquement ce que dit la doc (subagent avec `Skill` dans `tools:` atteint un skill posé via `/plugin`) | Volet 3, Summary | Si le comportement réel diverge de la doc (bug, régression de version Claude Code, spécificité VF), le GO/NO-GO changerait de sens — c'est précisément pourquoi D-07 exige une mesure et pas une lecture de doc seule |
| A4 | Aucune preuve (incident/demande externe/bug récurrent) au sens D-02 n'existe pour les gaps « 🟡 »/« ❌ » de la matrice agency-agents, en dehors de web-test-team | Volet 1 | Recherche par grep textuel sur `.planning/` — une preuve existant sous une formulation non retrouvée par les mots-clés utilisés (`SupportFlow`, `agency-agents`) resterait invisible ; risque faible vu la couverture des chemins fouillés (BACKLOG, STATE, research/, missions/, phases/) |

## Open Questions

1. **Quel UDID de simulateur porte la session authentifiée du lab Scroll-Off ?**
   - What we know : deux candidats « iPhone 17 Pro » existent (iOS 26.2 / iOS 26.4), tous deux
     actuellement `Shutdown`, `get_app_container` échoue sur un device éteint.
   - What's unclear : lequel des deux a l'app + le JWT déjà installés, sans le mesurer par un boot.
   - Recommendation : première tâche du plan AGTS-02 — booter chaque candidat, tester
     `get_app_container`, choisir, fixer `--target <udid>` explicitement dans la tâche de run
     suivante. Ne jamais lancer Maestro tant que l'UDID n'est pas confirmé.

2. **Le spike SKIL-01 doit-il tester le scope project en plus du scope user, ou le scope user
   suffit-il à trancher ?**
   - What we know : D-07 mentionne « scope user ou project » sans trancher lequel mesurer en
     premier ; la doc officielle traite les deux comme des catégories distinctes mais également
     découvrables.
   - What's unclear : si le scope user suffit à établir GO/NO-GO, mesurer aussi project double le
     coût du spike sans ajouter d'information si le mécanisme sous-jacent (Skill tool) ne distingue
     pas les scopes à l'exécution.
   - Recommendation : mesurer scope user en premier (moins de setup — pas besoin d'un repo jetable
     avec `.claude-plugin/`) ; ne mesurer project que si le résultat diffère de façon surprenante ou
     si le verdict user est un GO (auquel cas la spec de câblage devra couvrir les deux).

3. **La condition « build depuis zéro » de la sortie d'expérimental est-elle satisfaite si l'app
   Scroll-Off est déjà installée (donc le run ne rebuild pas) ?**
   - What we know : le texte exact de `mobile-test/README.md:119-123` dit « detect → run
     --platform ios (build depuis zéro) → rapport généré » comme condition de sortie. Le code de
     `cmdRun` ne force un build QUE si l'app n'est pas installée.
   - What's unclear : si la phase doit délibérément désinstaller l'app pour forcer le chemin
     « build depuis zéro » (ce qui détruirait la session authentifiée irremplaçable, Pitfall 1) ou
     si un run sur app déjà installée suffit à valider le pipeline dans l'esprit de la condition.
   - Recommendation : ne PAS désinstaller — la préservation de la session prime (contrainte dure,
     irréversible) sur la lecture littérale de « depuis zéro ». Documenter explicitement ce choix
     dans la trace du run (`34-RUN-MOBILE.md`) comme une déviation assumée et datée, pas un
     contournement silencieux — cohérent avec la discipline de traçabilité du dépôt (voir
     CLAUDE.md racine, « traçabilité des arbitrages »).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Maestro CLI | AGTS-02 (régression E2E) | ✓ [VERIFIED: `which maestro` → `/Users/samuel/.maestro/bin/maestro`, `maestro --version` → `2.6.1`] | 2.6.1 | — |
| OpenJDK (requis par Maestro) | AGTS-02 | ✓ [VERIFIED: `java -version` → `openjdk 17.0.19` Homebrew] | 17.0.19 | — |
| Node.js | AGTS-02 (exécute `mobile-test-run.mjs`) | ✓ [VERIFIED: `node --version` → `v26.5.0`] | v26.5.0 | — |
| Xcode / `xcrun simctl` | AGTS-02 (cible iOS) | ✓ [VERIFIED: 7 simulateurs « iPhone 17… » listés, tous `Shutdown`] | — | — |
| Simulateur « iPhone 17 Pro » identifiable de façon unique | AGTS-02 | ✗ (ambigu — 2 UDID candidats, Pitfall 2) | — | Résolution par `--target <udid>` explicite après vérification manuelle (Open Question 1) |
| Config projet `.vibeflow/mobile-test.json` (Scroll-Off/frontend) | AGTS-02 (`run`, pas `detect`) | ✗ [VERIFIED: `find` sans résultat le 2026-09-15] | — | Créer le fichier avant le premier `run` (Code Examples, valeurs déjà vérifiées) — tâche de préparation normale du plan, pas un blocage D-05 |
| Module `mobile-test` posé sur ce poste | AGTS-02 | ✓ [VERIFIED: `~/.claude/skills/mobile-test`, `~/.claude/scripts/mobile-test-run.mjs` présents] | v1.0.2 (`module.json`) | — |
| VibeFlow installé (scope user) — agents `vf-test-orchestrator` etc. disponibles pour `Scroll-Off/frontend` | AGTS-02 (exécutant) | ✓ [VERIFIED: `~/.claude/agents/vf-test-orchestrator.md` présent ; `agent-memory/vf-test-orchestrator` déjà peuplé dans le lab, signe d'un usage antérieur] | — | — |
| `workflow.use_worktrees=false` dans `Scroll-Off/.planning/config.json` | Guard isolation (mémoire de session « guard-isolation-lab-racine-non-git ») | ✗ — clé absente du fichier lu [VERIFIED: `cat ~/Documents/dev/Scroll-Off/.planning/config.json` exécuté le 2026-09-15, aucune clé `workflow.use_worktrees` dans le bloc `workflow` listé] | — | Si le run rencontre le faux positif « harness-worktree » déjà documenté en mémoire de session, appliquer le même correctif (ajouter `"use_worktrees": false` au bloc `workflow` de ce fichier) — à vérifier en tout début de run, pas en réaction à un échec |

**Missing dependencies with no fallback :** aucune — les deux manques identifiés (config projet,
UDID ambigu) ont un fallback écrit ci-dessus, tous deux à exécuter comme premières tâches du plan.

**Missing dependencies with fallback :** config `.vibeflow/mobile-test.json` (à créer, valeurs
connues) ; UDID cible (à déterminer avant le run, procédure donnée) ; `use_worktrees` potentiellement
absent (correctif connu, déjà appliqué avec succès dans ce lab par le passé selon la mémoire de
session).

## Validation Architecture

`workflow.nyquist_validation` = `false` explicitement dans `.planning/config.json` de ce dépôt
(vérifié : `.planning/config.json` de `vibeflow-os`, section `workflow`). **Section omise
conformément à la règle du gabarit.**

## Security Domain

Aucune modification de surface d'authentification, de session, ni de gestion de secrets n'est
prévue par cette phase (documentaire + agents Markdown). Le seul point sensible est la **protection
d'un état d'authentification existant** sur un lab tiers (Scroll-Off), traité en Pitfall 1/2 et
Open Question 3 plutôt que comme un contrôle ASVS — il s'agit de non-destruction d'un artefact de
test, pas d'une surface applicative nouvelle. **Section omise (pas de gate, pas de nouvelle surface
applicative) — le risque réel est documenté dans les Pitfalls.**

---

## Volet 1 — AGTS-01 : audit de couverture, corpus re-mesuré

### Corpus distribué au 2026-09-15 (identique à la mesure du 2026-07-20 citée en D-01)

**25 fichiers `plugin/<module>/agents/*.md`** [VERIFIED: `find plugin -path "*/agents/*.md"`
filtré au premier niveau, exécuté le 2026-09-15] :

| Module | Agents (fichier → `name:`) | Compte |
|--------|------------------------------|--------|
| `business-pilot-bundle` | `quality-gate-client`, `vf-business-commercial`, `vf-business-delivery`, `vf-business-finance`, `vf-business-manager` | 5 |
| `content-bundle` | `content-clarity-judge`, `vf-content-manager`, `vf-content-repurposer`, `vf-content-strategist`, `vf-content-writer` | 5 |
| `design-orchestrator` | `vf-crafter`, `vf-design-judge`, `vf-design-manager` | 3 |
| `dev-orchestrator` | `vf-auditer`, `vf-coder`, `vf-dev-manager`, `vf-reviewer` | 4 |
| `growth-bundle` | `campaign-analyst`, `channel-strategist`, `copywriter-sequences`, `growth-quality-judge`, `vf-growth-manager` | 5 |
| `mobile-test-team` | `vf-app-fixer`, `vf-test-orchestrator`, `vf-test-runner` | 3 |

**6 fichiers `plugin/<module>/AGENT.md`** [VERIFIED: `find plugin -maxdepth 2 -iname AGENT.md`,
exécuté le 2026-09-15] : `conductor`, `design-orchestrator`, `dev-orchestrator`, `kpi-analyst`,
`skill-creator`, `validator`.

**Total : 31**, confirmé indépendamment par le commentaire de `.github/workflows/ci.yml:276-280`
(« La population réelle est de 31 fichiers, pas 25 ») [VERIFIED:
`.github/workflows/ci.yml:245-320` lu ce jour — le job `gates` scanne exactement
`plugin/*/agents/*.md` + `plugin/*/AGENT.md`, c'est la définition machine du corpus « distribué »].
Le périmètre de la CI **exclut** délibérément : les blueprints (`content/agents/*.blueprint.md`,
9 fichiers), le contenu de référence/exemples (`plugin/reference/content/...`, 11 fichiers), et les
3 agents internes au moteur officiel `skill-creator` (`skills/skill-creator/agents/*.md` —
`analyzer`, `comparator`, `grader`, propriété Anthropic, non gouvernés par `check-agents.sh`).

**`web-test-team` n'existe toujours pas** [VERIFIED: `plugin/web-test-team` absent, aucun résultat
à `find plugin -maxdepth 1 -iname "web-test-team"`].

**Conclusion de la re-mesure :** le parc n'a pas bougé depuis le 2026-07-20 — la matrice division →
module de `BACKLOG.md:320-331` reste valide telle quelle, aucune ligne à réviser pour cause de
changement de corpus.

### Recherche de preuve (règle D-02) — résultat : aucune trouvée

Recherche menée sur `.planning/BACKLOG.md`, `.planning/STATE.md`, `.planning/research/*.md`,
`.planning/missions/*.md`, `.planning/phases/**/*.md` avec les mots-clés `SupportFlow`,
`agency-agents`, et par lecture directe des sections citées en `canonical_refs`.

- **Aucune mention** de `SupportFlow` dans `STATE.md`, `missions/`, ni `research/` en dehors de la
  BACKLOG elle-même et du `34-CONTEXT.md` de cette phase.
- **Aucune trace** d'incident documenté, de demande client/testeur, ni de bug récurrent pour les
  gaps « 🟡 »/« ❌ » de la matrice : Security/compliance (au-delà de l'audit déjà couvert),
  Sales (granularité fine), Product (module first-class), Paid Media (blueprints), Support, et les
  verticales niche (Spatial/Game/Healthcare/GIS/Academic).
- La **seule** piste avec une justification écrite et datée est `web-test-team`, mais sa preuve
  n'est PAS la règle D-02 (incident/demande/bug récurrent) — c'est la dépendance explicite à
  AGTS-02 (mobile-test hors expérimental) déjà actée au ROADMAP et gérée comme Volet 2 séparé de
  cette même phase.

**Implication pour le plan :** sur la base de cette recherche, tout gap autre que `web-test-team`
manque de la preuve exigée par D-02 — le rapport d'audit devra le dire « en toutes lettres pour
chaque gap refusé, avec la preuve qui manque » (Specific Ideas, `34-CONTEXT.md`). Cette recherche
fournit la liste des gaps et confirme l'absence de preuve ; le verdict formel (combler / reporter /
refuser, avec sa formulation) revient au plan/exécution de la phase, pas à cette recherche.

---

## Volet 2 — AGTS-02 : run mobile, mécanique et prérequis

### `mobile-test-run.mjs` — fonctionnement lu ce jour (409 lignes,
`plugin/mobile-test/scripts/mobile-test-run.mjs`)

- `detect` : liste les simulateurs iOS bootés + émulateurs Android bootés en JSON. **N'a pas besoin
  de config.** N'ouvre ni ne boote rien.
- `run --platform ios [--target <udid>] [--stamp ...] [--skip-build] [--keep-metro] [--config
  <path>]` : résout le bundle id depuis la config (`bundleIdBase` + `debugSuffix`), résout la cible
  (`ensureIosTarget` — cible explicite `--target` > premier simulateur déjà booté > boot du
  `ios.preferredSimulator` configuré, résolu par NOM dans `xcrun simctl list devices available
  --json`, premier match par runtime), vérifie si l'app est installée
  (`xcrun simctl get_app_container <udid> <bundleId>`), build+install SEULEMENT si absente
  (`expo run:ios --device <udid>`, en arrière-plan, jusqu'à 20 min de timeout), sinon démarre Metro
  seul si besoin, joue `maestro test <flowsDir> --format junit --output <path>`, parse le JUnit par
  regex, écrit un rapport Markdown horodaté.
- `--skip-build` : si l'app n'est PAS installée et que ce flag est fourni, le script échoue
  proprement (`fail('App … absente et --skip-build fourni : rien à tester.')`) plutôt que de
  builder.

### Tableau — Prérequis mesurés sur ce poste (2026-09-15)

| Prérequis | Statut | Preuve |
|-----------|--------|--------|
| `maestro` sur le PATH / résolu par cascade | PRÉSENT | `which maestro` → `/Users/samuel/.maestro/bin/maestro` ; `maestro --version` → `2.6.1` |
| JDK requis par Maestro | PRÉSENT | `java -version` → `openjdk version "17.0.19"` (Homebrew) ; `$JAVA_HOME` déjà exporté vers `/opt/homebrew/opt/openjdk@17/...` |
| Node.js | PRÉSENT | `node --version` → `v26.5.0` |
| Simulateur(s) iPhone 17 disponibles | PRÉSENT (7 au total, dont 2 nommés « iPhone 17 Pro ») | `xcrun simctl list devices available \| grep -i "iPhone 17"` → 7 lignes, toutes `Shutdown` |
| Dossier `.maestro/` avec flows | PRÉSENT | 11 fichiers (`login_*`, `deeplink_*`, `lot2_*`, `lot3_*`×3, `lot4_*`, `lot5_*`) + `README.md` sous `Scroll-Off/frontend/.maestro/` |
| Config projet `mobile-test` (`.vibeflow/mobile-test.json` ou `mobile-test.json`) | **ABSENT** | `find` sur `Scroll-Off/frontend` — aucun résultat ; requis par `run`, pas par `detect` |
| Build iOS existant (`ios/` prebuild) | PRÉSENT | `Scroll-Off/frontend/ios/` contient `Podfile`, `Podfile.lock`, `Pods/` — prebuild déjà fait |
| Scripts npm pertinents | PRÉSENTS | `package.json` : `"ios": "expo run:ios"`, `"prebuild": "npm run sync:ios-shared && expo prebuild"`, `"start": "expo start"` |
| Module VF `mobile-test` posé sur ce poste | PRÉSENT (scope user) | `~/.claude/skills/mobile-test/`, `~/.claude/scripts/mobile-test-run.mjs` |
| Agent `vf-test-orchestrator` disponible pour ce lab | PRÉSENT (scope user, hérité par tous les labs de ce poste) | `~/.claude/agents/vf-test-orchestrator.md` ; `Scroll-Off/frontend/.claude/agent-memory/vf-test-orchestrator/` déjà peuplé (usage antérieur constaté) |
| UDID exact porteur de l'app+session déjà installées | **NON DÉTERMINÉ** (ambigu entre 2 candidats) | `get_app_container` exige un simulateur `Booted` — aucun boot effectué dans cette recherche (hors périmètre read-only) |
| `workflow.use_worktrees` dans `Scroll-Off/.planning/config.json` | **ABSENT** de ce fichier au 2026-09-15 | `cat` exécuté — bloc `workflow` présent mais sans cette clé |

### Le moule `mobile-test-team` — inventaire fichier par fichier (pour le clonage `web-test-team`)

| Fichier source | Lignes | Rôle | Ce qui change pour `web-test-team` |
|----------------|--------|------|--------------------------------------|
| `plugin/mobile-test-team/module.json` | — | `requires: ["mobile-test"]`, description, version | `requires: []` (Playwright = dépendance lab, comme Maestro) ; nouvelle description |
| `plugin/mobile-test-team/agents/vf-test-orchestrator.md` | 60 | Boucle test→corrige→re-test, garde « projet mobile » (marqueurs `app.json`/`.maestro`), dispatch runner+fixer, halt conditions Pattern 11, bloc typé ADR-053 | Renommer (Pitfall 4), remplacer la garde par des marqueurs web (`playwright.config.*`, `package.json` avec `@playwright/test`), remplacer les appels `mobile-test-run.mjs` par l'équivalent Playwright |
| `plugin/mobile-test-team/agents/vf-test-runner.md` | 56 | Possède les tests, écrit les flows manquants, règle anti-triche (jamais affaiblir un assert), exécute le pipeline | Renommer ; domaine d'écriture = specs Playwright au lieu de `.maestro/**` |
| `plugin/mobile-test-team/agents/vf-app-fixer.md` | 48 | Possède le code app, jamais les tests, gate ADR-045 recherche doc | Renommer ; domaine inchangé dans l'esprit (code app web au lieu de mobile) |
| `plugin/mobile-test-team/rules/mobile-verify-gate.md` | — | Rule path-scopée sur marqueurs mobile | Marqueurs web (ex. `playwright.config.*`, `e2e/**`) |
| `plugin/mobile-test-team/references/test-loop-protocol.md` | — | Invariants de boucle, mapping halt conditions, insertion dans `god-execution`/`vf-auto` | Réutilisable tel quel si le protocole de boucle ne change pas structurellement |
| `plugin/mobile-test/scripts/mobile-test-run.mjs` | 409 | Script mécanique detect/run/build/rapport | Équivalent Playwright à écrire — PAS un clone 1:1 (Playwright a son propre runner, pas besoin de réimplémenter le detect/boot de simulateur) |

---

## Volet 3 — SKIL-01 : mécanique native des skills et sous-agents

### Ce que dit la documentation officielle (aujourd'hui, 2026-09-15)

Source : [https://code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)
(redirigé depuis `docs.claude.com/en/docs/claude-code/sub-agents`) et
[https://code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) (redirigé depuis
`docs.claude.com/en/docs/claude-code/skills`) [CITED — récupéré via WebFetch ce jour].

- « The full content of each listed skill is injected into the subagent's context at startup. This
  field controls which skills are preloaded, not which skills the subagent can access: **without
  it, the subagent can still discover and invoke project, user, and plugin skills through the Skill
  tool during execution.** »
- « To prevent a subagent from invoking skills entirely, omit `Skill` from the `tools` list or add
  it to `disallowedTools`. »
- Emplacements de skills documentés : personnel (`~/.claude/skills/<nom>/SKILL.md`, ne charge pas en
  Cowork/cloud), projet (`.claude/skills/<nom>/SKILL.md`, commit pour partager), imbriqué
  (`<sous-dossier>/.claude/skills/<nom>/SKILL.md`), entreprise (répertoire de settings managé),
  **plugin** (`<plugin>/skills/<nom>/SKILL.md`, installé via plugin, référencé
  `/plugin-name:skill-name`, **automatiquement namespacé** pour éviter toute collision avec un skill
  local).
- « Cowork sessions and cloud sessions, including routines, don't read `~/.claude/skills/` on your
  machine. » — hors périmètre VF (VF cible Claude Code local), mais à garder en tête si VF vise un
  jour des sessions cloud.

**Lecture pour SKIL-01 :** si cette documentation reflète fidèlement le comportement réel (à
confirmer par le spike, D-07 l'exige explicitement — une lecture de doc ne suffit jamais dans ce
dépôt, cf. `[[preuve-incapable-de-rendre-rouge]]`), alors un skill posé par le canal natif `/plugin`
**devrait déjà** atteindre tout sous-agent qui a `Skill` dans ses `tools:`, sans qu'aucun câblage VF
supplémentaire soit nécessaire pour cette partie du problème. Le différenciateur F8 identifié en
2026-06-04/2026-08-15 (« rendre disponible à TOUS les agents ») serait alors à re-questionner : soit
il portait sur un état antérieur de Claude Code (déjà corrigé en amont), soit il porte sur autre
chose que la découverte pure (ex. UX de toggle/scope pour des skills tiers non-VF, gérée par F8 côté
« catalogue de choix », pas côté « le sous-agent voit-il le skill »).

### Mesure locale indépendante : qui, parmi les 25 agents distribués, a l'outil `Skill` ?

[VERIFIED: `grep -m1 "^tools:" plugin/*/agents/*.md` exécuté le 2026-09-15 sur les 25 fichiers +
les 6 `AGENT.md`]

| Agent | `Skill` dans `tools:` ? | Rôle |
|-------|--------------------------|------|
| `vf-business-manager` | ✅ | manager (dispatche des workers) |
| `vf-content-manager` | ✅ | manager |
| `vf-crafter` | ✅ | agent craft (pas un pur worker cloisonné) |
| `vf-design-manager` | ✅ | manager |
| `vf-coder` | ✅ | manager (dispatche 20 sous-types) |
| `vf-dev-manager` | ✅ | manager |
| `vf-growth-manager` | ✅ | manager |
| `quality-gate-client`, `vf-business-commercial/delivery/finance` | ❌ | workers Pattern 12 |
| `content-clarity-judge`, `vf-content-repurposer/strategist/writer` | ❌ | workers Pattern 12 |
| `vf-design-judge` | ❌ | worker/judge |
| `vf-auditer`, `vf-reviewer` | ❌ | workers spécialisés (délèguent à un sous-agent GSD dédié) |
| `campaign-analyst`, `channel-strategist`, `copywriter-sequences`, `growth-quality-judge` | ❌ | workers Pattern 12 |
| `vf-app-fixer`, `vf-test-orchestrator`, `vf-test-runner` | ❌ | workers/orchestrateur mobile-test-team (Pattern 12) |
| Les 6 `AGENT.md` racine (`conductor`, `design-orchestrator`, `dev-orchestrator`, `kpi-analyst`, `skill-creator`, `validator`) | — (pas de `tools:` explicite → hérite de tous les outils, `Skill` inclus, par défaut Claude Code) | orchestrateurs de premier niveau |

**7 agents sur 25** (+ les 6 orchestrateurs de premier niveau, qui héritent tout par défaut) ont
`Skill`. Les **18 autres** (tous `vf-internal: true` sauf `vf-auditer`/`vf-reviewer`/`vf-crafter`
et le reste des Pattern 12) ne peuvent invoquer AUCUN skill aujourd'hui — canal natif ou VF, peu
importe — puisque l'outil lui-même leur est retiré. C'est un choix d'architecture VF déjà en place,
distinct de la question SKIL-01, mais qui borne ce qu'un GO pourrait changer sans un second geste
hors périmètre de cette phase (Pitfall 5).

### Fait empirique sur ce poste : les deux canaux coexistent déjà pour VF lui-même

- `plugin/.claude-plugin/plugin.json` déclare `"skills": "./installer"` — **un seul** SKILL.md
  (`plugin/installer/SKILL.md`) exposé par le canal natif, référencé `vibeflow:vibeflow-install`.
- Les entrées `vibeflow:vf-update`, `vibeflow:vf-calibrate`, `vibeflow:vf-new-lab`,
  `vibeflow:vf-notify`, `vibeflow:vf-planning`, `vibeflow:vf-audit` vues dans la liste de skills
  disponibles de cette session sont en réalité des **slash commands** (`plugin/commands/*.md`,
  auto-découverts par le canal plugin) — **pas** des `SKILL.md`/outil `Skill`. Ne pas confondre les
  deux mécanismes dans le protocole de spike : seul un vrai `SKILL.md` invoqué via l'outil `Skill`
  répond à la question D-07.
- En parallèle, l'engine `vibeflow-update.sh` a posé **8 skills bruts** directement dans
  `~/.claude/skills/` sur ce poste (`vf-auto`, `vf-calibrate`, `vf-design`, `vf-dev`, `vf-new-lab`,
  `vf-notify`, `vf-sketch`, `vf-update`) — catégorie « personal skill » selon la doc, PAS « plugin
  skill » puisqu'ils ne passent pas par `claude plugin install`.
- Conséquence pour le protocole de spike : le cas « scope user posé par VF aujourd'hui » n'est PAS
  un cas « posé via `/plugin` natif » au sens strict de D-07 — le spike doit créer un skill de test
  dédié, distinct de l'infrastructure VF existante, pour isoler la variable « canal de pose » de la
  variable « scope ».

### Protocole de spike proposé (Claude Code d'abord, D-08)

1. **Contrôle négatif** : dispatcher un sous-agent Task doté de `Skill` dans `tools:` (par exemple
   un clone jetable minimal de `vf-crafter.md`) et lui demander d'invoquer un skill au nom inventé
   (`skil01-probe-nonexistant`). Attendu : échec / absence de découverte. Ceci établit que l'outil
   `Skill` ne « voit » pas un skill qui n'existe nulle part — le socle de comparaison.
2. **Cas cible — canal natif `/plugin`, scope user** : créer un dépôt Git jetable hors de
   `vibeflow-os` avec un `.claude-plugin/plugin.json` minimal + un skill unique portant un marqueur
   sentinelle explicite dans ses instructions (ex. « si invoqué, réponds EXACTEMENT `SKIL01_PROBE_OK`
   »). `claude plugin marketplace add <chemin-local>` puis `claude plugin install
   <plugin>@<marketplace>`. Dispatcher le même type de sous-agent Task, lui demander d'invoquer le
   skill par son nom namespacé. Mesurer : le sentinelle revient-il ?
3. **Cas cible — scope project** (si le temps le permet / si le cas user est un GO) : même
   protocole avec install en scope project plutôt que user.
4. **Verdict** : GO seulement si le contrôle négatif échoue ET le(s) cas cible(s) réussissent ET
   qu'aucun mécanisme VF existant (posage direct par l'engine, déjà catégorisé « personal skill »
   par la doc et déjà couvert par le canal actuel) ne couvre déjà ce que le canal `/plugin` apporterait
   en plus. Sinon NO-GO documenté, clôture de l'item BACKLOG du 2026-06-04 (`BACKLOG.md:258-273`).
5. **Nettoyage** : `claude plugin uninstall` + suppression du dépôt jetable + suppression du
   marketplace ajouté — le spike est jetable par construction (D-10).

Codex et Kimi ne sont mesurés qu'en cas de GO Claude (D-08) — hors périmètre de cette recherche tant
que le verdict Claude n'est pas rendu.

## Sources

### Primary (HIGH confidence)
- `plugin/mobile-test/scripts/mobile-test-run.mjs` (409 lignes, lu intégralement ce jour) — mécanique
  exacte de `detect`/`run`, résolution de config, résolution de cible, build conditionnel.
- `plugin/mobile-test-team/agents/vf-test-orchestrator.md`, `vf-test-runner.md`, `vf-app-fixer.md`
  (lus intégralement ce jour) — le moule à cloner.
- `.github/workflows/ci.yml:245-320` (lu ce jour) — définition machine du corpus « agents
  distribués ».
- Commandes exécutées ce jour sur ce poste : `which maestro`, `maestro --version`, `xcrun simctl
  list devices available`, `java -version`, `node --version`, `find`/`ls` sur `Scroll-Off/frontend`,
  `~/.claude/skills/`, `~/.claude/agents/`, `~/.claude/plugins/`.
- `.planning/REQUIREMENTS.md:900-1100`, `.planning/BACKLOG.md:255-350`, `.planning/PROJECT.md:45-90`
  (lus intégralement ce jour).

### Secondary (MEDIUM confidence)
- [https://code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents) et
  [https://code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) — récupérées via
  WebFetch le 2026-09-15, citations verbatim reproduites ci-dessus. MEDIUM plutôt que HIGH parce que
  D-07 exige explicitement une confirmation par exécution, jamais une lecture de doc seule.

### Tertiary (LOW confidence)
- Aucune — pas de finding reposant uniquement sur du WebSearch non recoupé dans cette recherche.

## Metadata

**Confidence breakdown :**
- AGTS-01 (audit) : HIGH — corpus re-mesuré par commande, recherche de preuve exhaustive sur les
  fichiers `.planning/` accessibles.
- AGTS-02 (prérequis machine) : HIGH sur les prérequis système, LOW sur un point isolé (UDID exact
  porteur de la session — non mesurable sans boot, hors périmètre read-only de cette recherche).
- SKIL-01 (cadrage) : MEDIUM — doc officielle citée et cohérente avec une mesure locale
  indépendante, mais le spike lui-même (exécution réelle) reste à faire par le plan, conformément à
  D-07.

**Research date :** 2026-09-15
**Valid until :** 30 jours pour AGTS-01/AGTS-02 (état du dépôt et du lab stables) ; 7 jours pour la
partie doc officielle de SKIL-01 (mécanique Claude Code en évolution rapide — toute date au-delà
doit re-vérifier la doc avant de s'y fier).
