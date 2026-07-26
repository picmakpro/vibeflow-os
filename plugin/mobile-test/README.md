# mobile-test — Pipeline de test mobile réel

> Module VibeFlow qui **teste réellement** une app mobile (iOS simulateur / Android émulateur) :
> il détecte la cible, build/installe l'app si absente, joue une régression **Maestro**, produit
> un **rapport horodaté + artefacts**, et te laisse **diagnostiquer visuellement** les échecs via
> `mobile-mcp`. Un noyau mécanique scripté, une couche jugement portée par l'agent.

**Version** : v1.0.1
**Type** : skill + script + config
**Statut** : ⚠️ **expérimental** — validé sur le projet d'origine, à re-confirmer par un run réel
dans ton contexte avant de le considérer « intégré » (voir § Statut).

---

## À quoi ça sert

Avant ce module, VibeFlow ne pouvait pas exécuter une app mobile pour vérifier qu'elle marche.
Désormais, dire « teste l'app sur le simulateur », « lance une régression avant le sprint » ou
« valide ce fix sur l'émulateur » déclenche un pipeline complet :

1. **Détection** — quelles cibles (simulateurs/émulateurs) sont démarrées.
2. **Préparation autonome** — boot de la cible iOS, build + install de l'app si absente
   (`expo run:`), démarrage de Metro si besoin.
3. **Régression** — `maestro test` sur tes flows, résultats parsés (pass/fail par flow).
4. **Rapport** — un Markdown horodaté + un dossier d'artefacts (JUnit, logs, captures).
5. **Diagnostic sur échec** — l'agent pilote l'app via `mobile-mcp`, capture avant/après, et
   documente la cause probable.

## Deux couches

| Couche | Qui | Quoi |
|--------|-----|------|
| **Mécanique** | le script `scripts/mobile-test-run.mjs` | détecter, builder, jouer Maestro, scaffolder le rapport — déterministe |
| **Jugement** | l'agent, via le skill `vf-mobile-test` | choisir la cible si ambigu, diagnostiquer visuellement, rédiger le rapport |

Le script **n'appelle jamais** `mobile-mcp` : le diagnostic visuel reste côté agent.

---

## Structure du module

```
mobile-test/
├── module.json                       # manifeste (type, requires:[])
├── SKILL.md                          # skill vf-mobile-test (couche jugement)
├── scripts/
│   └── mobile-test-run.mjs           # orchestrateur mécanique (detect / run)
├── config/
│   └── mobile-test.example.json      # template de config projet (à copier)
└── references/
    └── portability-notes.md          # apprentissages durs (maestro/PATH, JAVA_HOME, expo run…)
```

---

## Pré-requis

- **Node** (exécute le script).
- **Maestro** (`~/.maestro/bin/maestro` ou sur le PATH).
- **Un JDK** (Maestro en a besoin ; `JAVA_HOME` est auto-détecté si absent).
- **iOS** : Xcode + `xcrun`/`simctl`. **Android** : `adb` + un émulateur (AVD) démarré.
- **L'app** : projet Expo / React Native (le pipeline teste un **build de dev**, pas un artefact de store).
- **Diagnostic visuel** : le MCP `mobile-mcp` connecté.

Le script **dégrade proprement** si un outil manque (message explicite, jamais d'échec silencieux).

---

## Configuration (obligatoire)

Le script ne contient **aucune** valeur machine/projet en dur. Copie le template et renseigne-le :

```bash
mkdir -p .vibeflow
cp .claude/skills/mobile-test/config/mobile-test.example.json .vibeflow/mobile-test.json
# puis édite bundleIdBase, android.avdName, ios.preferredSimulator, maestroFlowsDir…
```

Résolution du fichier en cascade : `--config <path>` > `$VF_MOBILE_TEST_CONFIG` >
`./.vibeflow/mobile-test.json` > `./mobile-test.json`.

| Clé | Rôle |
|-----|------|
| `bundleIdBase` | id de bundle de base de l'app |
| `debugSuffix` | suffixe du build de dev (souvent `""` — **vérifie sur la cible**, pas dans un README) |
| `android.avdName` | nom de l'AVD Android à lancer |
| `ios.preferredSimulator` | simulateur iOS à booter si aucun n'est démarré |
| `maestroFlowsDir` | dossier des flows Maestro (défaut `.maestro`) |
| `maestroBin` | chemin du binaire Maestro |
| `reportsDir` | où écrire rapports + artefacts (défaut `test-runs`) |

---

## Usage

```bash
# Cibles démarrées (JSON)
node .claude/scripts/mobile-test-run.mjs detect

# Régression iOS (build auto si l'app est absente)
node .claude/scripts/mobile-test-run.mjs run --platform ios

# Régression Android sur une cible précise, sans rebuild
node .claude/scripts/mobile-test-run.mjs run --platform android --target <serial> --skip-build
```

Ou, en langage naturel : « teste l'app sur le simulateur » → le skill `vf-mobile-test` orchestre.

---

## Garde-fous en boucle autonome

Si ce pipeline tourne dans une boucle test+fix non supervisée, il **hérite de la doctrine des
garde-fous VibeFlow** (anti-thrash, anti-régression, séparation anti-triche) :
`dev-orchestrator/references/autonomous-guardrails.md`. Concrètement : **on n'affaiblit jamais un
assert Maestro** pour « faire passer », et un fix qui casse un flow précédemment vert est reverté.
Le support technique de cette séparation est le Pattern 12 (cloisonnement par outils).

---

## Statut

**Expérimental.** Le pipeline a été conçu et validé en conditions réelles (build iOS from-zero
inclus) sur un projet d'origine, puis **dé-spécifié** pour VibeFlow (aucune constante projet dans
le code). Il n'est déclaré « intégré » qu'après un **run réel vert dans ton contexte** :
`detect` → `run --platform ios` (build depuis zéro) → rapport généré. Tant que ce run n'a pas été
fait, considère le module comme une base solide mais à confirmer.

## Références

- Notes de portabilité : `references/portability-notes.md`
- Doctrine des boucles autonomes : `dev-orchestrator/references/autonomous-guardrails.md`
- Cloisonnement par outils : Pattern 12 (`reference/content/methodology/patterns/12-cloisonnement-outils.md`)
- Spec d'origine (recherche) : `.planning/research/agent-team-spec.md`
