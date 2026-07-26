# mobile-test — La recette réelle sur cible mobile

> Un écran peut compiler, passer ses tests unitaires, **et crasher au runtime**. Ce module donne
> à VibeFlow le moyen de le prouver : il exécute réellement l'app sur simulateur iOS / émulateur
> Android, joue une régression Maestro, et diagnostique visuellement les échecs.

**Type** : skill + script + config · **Version** : v1.0.2 · **Dépend de** : aucun module

---

## Quoi

Un pipeline de test mobile en **deux couches** :

| Couche | Qui | Quoi |
|--------|-----|------|
| **Mécanique** | `scripts/mobile-test-run.mjs` | détecter la cible, booter, builder/installer si absent, jouer Maestro, parser le JUnit, scaffolder le rapport — déterministe |
| **Jugement** | l'agent, via le skill `vf-mobile-test` | choisir la cible si ambigu, diagnostiquer visuellement les échecs (mobile-mcp), rédiger le rapport |

Le script **n'appelle jamais** `mobile-mcp` : le diagnostic visuel reste côté agent. Aucune
valeur machine ou projet n'est codée en dur — tout vient d'un fichier de config par projet.

**Frontière (ADR-057)** : ce module = la recette **réelle** sur cible mobile (Maestro,
simulateur/émulateur). La recette conversationnelle d'une feature = `gsd-verify-work`. La boucle
autonome test → fix = le module `mobile-test-team` (qui pilote celui-ci).

## Installation

```bash
.claude/scripts/vibeflow-update.sh install mobile-test
```

Pré-requis modules (`module.json` → `requires`) : **aucun** — le module est autonome.

Pré-requis **système** (le script dégrade proprement si un outil manque — message explicite,
jamais d'échec silencieux) :

| Outil | Pourquoi | Note |
|-------|----------|------|
| **Node** | exécute le script | zéro dépendance npm (JUnit parsé par regex) |
| **Maestro** (CLI) | la régression | résolu en cascade : `maestroBin` (config) → `~/.maestro/bin/maestro` → PATH |
| **Un JDK** | requis par Maestro | `JAVA_HOME` résolu en cascade : env → config → `/usr/libexec/java_home -v 17` → openjdk@17 Homebrew |
| **iOS** : Xcode + `xcrun`/`simctl` | détection, boot, install | le script boote lui-même `ios.preferredSimulator` si rien n'est démarré |
| **Android** : `adb` + un AVD | détection, install | l'émulateur doit être **lancé manuellement** (`emulator -avd <nom>`) — le script te le dit et s'arrête |
| **Projet Expo / React Native** | la cible | le pipeline teste un **build de dev** (`expo run:`), pas un artefact de store |
| **MCP `mobile-mcp`** connecté | diagnostic visuel sur échec | côté agent uniquement, jamais appelé par le script |

**Config projet obligatoire** — le script refuse de tourner sans :

```bash
mkdir -p .vibeflow
cp .claude/skills/mobile-test/config/mobile-test.example.json .vibeflow/mobile-test.json
# puis édite bundleIdBase, android.avdName, ios.preferredSimulator, maestroFlowsDir…
```

Résolution en cascade : `--config <path>` > `$VF_MOBILE_TEST_CONFIG` >
`./.vibeflow/mobile-test.json` > `./mobile-test.json`.

## Démarrer

Sur un projet Expo/RN avec des flows Maestro dans `.maestro/` et la config posée, dis :

> « Teste l'app sur le simulateur »

Ce qui se passe (premier run ≈ le temps d'un build) :

1. **Détection** — `detect` liste les cibles bootées. Exactement une → elle est utilisée ;
   zéro ou plusieurs → l'agent **demande**, il ne devine pas.
2. **Préparation autonome** — boot du simulateur iOS si besoin, puis si l'app
   (`bundleIdBase + debugSuffix`) est absente : `expo run:` **détaché** + polling d'installation
   (jusqu'à 20 min), Metro démarré seulement s'il ne tourne pas déjà.
3. **Régression** — `maestro test <maestroFlowsDir>`, résultats parsés pass/fail par flow.
4. **Rapport** — un Markdown horodaté dans `reportsDir` (défaut `test-runs/`) + un dossier
   d'artefacts (JUnit, logs expo).
5. **Diagnostic sur échec** — l'agent pilote l'app via `mobile-mcp`, capture
   `<flow>-before/after.png`, dump les logs, et documente la cause probable dans le rapport.

En fin de run, le script tue les process **qu'il a lui-même démarrés** (jamais un Metro tiers).

## Usage

En langage naturel — chaque phrase déclenche le skill `vf-mobile-test` :

- **Régression avant un sprint** : « lance une régression mobile avant le sprint »
- **Valider un fix** : « valide ce fix sur l'émulateur » (laisse rebuilder — pas de `--skip-build` si le code a changé)
- **Reproduire un bug** : « reproduis ce bug mobile » (diagnostic visuel mobile-mcp)

En CLI directe :

```bash
node .claude/scripts/mobile-test-run.mjs detect                                   # cibles bootées (JSON)
node .claude/scripts/mobile-test-run.mjs run --platform ios                       # régression iOS, build auto
node .claude/scripts/mobile-test-run.mjs run --platform android --target <serial> --skip-build
node .claude/scripts/mobile-test-run.mjs run --platform ios --keep-metro          # laisse Metro actif
```

**Boucle autonome test → fix** : ce module est la brique mécanique que pilote l'équipe
`mobile-test-team` (`vf-test-orchestrator` + workers cloisonnés). Dans ce cadre il hérite de la
doctrine des garde-fous (`dev-orchestrator/references/autonomous-guardrails.md`) : **on
n'affaiblit jamais un assert Maestro** pour « faire passer », et un fix qui casse un flow vert
est reverté.

## Référence

| Fichier | Rôle |
|---------|------|
| `SKILL.md` | skill `vf-mobile-test` — la couche jugement : flux détect → run → diagnostic, quick reference CLI, erreurs courantes |
| `scripts/mobile-test-run.mjs` | orchestrateur mécanique — sous-commandes `detect` et `run` (`--platform`, `--target`, `--stamp`, `--skip-build`, `--keep-metro`, `--config`) |
| `config/mobile-test.example.json` | template de config projet à copier |
| `references/portability-notes.md` | apprentissages durs : maestro hors PATH, JAVA_HOME absent, `expo run` qui ne rend pas la main, `timeout:` non supporté par `assertVisible`/`tapOn`, bundle id à vérifier sur la cible |

Clés de config : `bundleIdBase`, `debugSuffix` (le bundle id réel = base + suffixe, **vérifie
sur la cible**, pas dans un README), `android.avdName`, `ios.preferredSimulator`,
`maestroFlowsDir` (défaut `.maestro`), `maestroBin`, `reportsDir` (défaut `test-runs`),
`metroPort` (défaut 8081), `javaHome`.

## Limites

- ⚠️ **Statut expérimental.** Le pipeline a été conçu et validé en conditions réelles (build iOS
  from-zero inclus) sur son projet d'origine, puis dé-spécifié pour VibeFlow — mais **aucun run
  réel vert n'a encore été tracé dans un contexte VibeFlow**. La condition de sortie du statut
  est précisément ce run : `detect` → `run --platform ios` (build depuis zéro) → rapport généré.
  Tant qu'il n'existe pas, considère le module comme une base solide **à confirmer**.
- **Build de dev uniquement** — pas d'artefact de store (`.aab`/`.ipa` de distribution).
- **Android** : le script n'ouvre jamais l'émulateur lui-même (processus long) — à lancer
  manuellement avant `run --platform android`.
- **Les flows Maestro sont à toi** : le module les joue, il n'en écrit pas (c'est le rôle de
  `vf-test-runner` dans `mobile-test-team`).
- Doctrine des boucles autonomes : `dev-orchestrator/references/autonomous-guardrails.md` ·
  Cloisonnement par outils : Pattern 12 (module `reference`).
