# Notes de portabilité — pipeline de test mobile

> Apprentissages **durs**, validés en conditions réelles (build iOS from-zero inclus) sur le
> track d'origine. Ils expliquent pourquoi le script fait ce qu'il fait. À relire avant de
> débrancher un comportement « bizarre » du script.

## 1. `maestro` n'est pas sur le PATH d'un shell non interactif

Le binaire Maestro vit dans `~/.maestro/bin/`, absent du PATH d'un shell non interactif
(celui dans lequel tourne le script). → Résolution en cascade : `config.maestroBin`, puis
`~/.maestro/bin/maestro`, puis `maestro` sur le PATH en dernier recours (`resolveMaestro`).

## 2. `JAVA_HOME` souvent absent

Maestro requiert un JDK ; `JAVA_HOME` n'est pas toujours exporté dans le shell du script. →
Détection en cascade : `$JAVA_HOME`, `config.javaHome`, `/usr/libexec/java_home -v 17`, puis
openjdk@17 Homebrew (Apple Silicon et Intel). Injecté dans l'env passé à Maestro
(`resolveJavaHome`). Si rien n'est trouvé, avertissement + tentative `java` sur le PATH.

## 3. `expo run:ios/android` ne rend jamais la main

`expo run:` garde Metro attaché au premier plan et ne se termine pas. Un `execSync` bloquerait
le script indéfiniment. → Lancement **détaché** (`spawnDetached`, chef de groupe de process),
puis **polling d'installation** (`waitForInstall`, jusqu'à 20 min), puis **nettoyage** du
groupe de process en fin de run (`killGroup`). `--keep-metro` laisse Metro actif si besoin.

## 4. Le bundle id réel peut différer de ce qu'un README prétend

Sur le projet d'origine, le README des flows annonçait un suffixe `.dev` **qui n'existait
pas** : le vrai bundle id de dev n'avait pas de suffixe. Un suffixe faux = cible introuvable
ou test d'un build périmé. → Le bundle id est **`bundleIdBase + debugSuffix`**, tous deux en
config ; **vérifie-le sur la cible** (`xcrun simctl get_app_container` / `adb shell pm path`),
ne te fie pas à un README.

## 5. Certaines commandes Maestro n'acceptent pas `timeout:`

`assertVisible` / `tapOn` n'acceptent pas d'argument `timeout:` — seul `extendedWaitUntil` gère
l'attente. Un flow qui utilise `timeout:` sur ces commandes échoue à l'analyse. → À corriger
dans les flows `.maestro/` du projet, pas dans le script.

## 6. Metro : ne pas écraser une instance existante

Le dev build a besoin de Metro pour charger le JS. Le script **ne démarre Metro que s'il n'est
pas déjà up** (`metroUp` sonde `http://localhost:<port>/status`) et ne touche jamais un Metro
lancé par ailleurs. Il ne nettoie en fin de run que les process **qu'il a lui-même démarrés**.

## 7. JUnit parsé sans dépendance XML

Le rapport Maestro (`--format junit`) est parsé par regex (`parseJunit`), sans lib XML externe —
zéro dépendance à installer, portable partout où Node tourne.
