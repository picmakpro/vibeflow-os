---
name: vf-mobile-test
description: "Utiliser pour tester réellement une app mobile (iOS simulateur / Android émulateur) — « teste l'app sur le simulateur », « lance une régression mobile avant le sprint », « valide ce fix sur l'émulateur », « reproduis ce bug mobile ». Couvre la préparation autonome de la cible, la régression Maestro et le diagnostic visuel sur échec (mobile-mcp). Frontière (ADR-057) : ce skill = la recette RÉELLE sur cible mobile (simulateur/émulateur, Maestro) ; la recette conversationnelle d'une feature = gsd-verify-work ; la boucle autonome test+fix = l'équipe mobile-test-team. Statut : expérimental (voir README du module). Invocable par l'utilisateur ET en autonomie."
---

# vf-mobile-test — Pipeline de test mobile

Pipeline de test mobile autonome (iOS + Android). Deux couches : **régression déterministe**
(Maestro, scriptée) et **diagnostic visuel en direct** (mobile-mcp, porté par toi, l'agent).

**Principe** : le script fait le mécanique (détecter, builder, jouer Maestro, scaffolder le
rapport). Toi tu fais le jugement (choisir la cible si ambigu, diagnostiquer visuellement les
échecs, rédiger le rapport).

> **Chemins après install** : le script est posé sous `.claude/scripts/mobile-test-run.mjs` et
> le template de config sous `.claude/skills/mobile-test/config/mobile-test.example.json`.
> (En dev dans le repo du plugin : `plugin/mobile-test/scripts/` et `plugin/mobile-test/config/`.)

## Pré-requis

Node, `maestro` (CLI), un JDK (JAVA_HOME), et selon la plateforme `xcrun`/`simctl` (iOS) ou
`adb` + un émulateur (Android), plus l'app (Expo/RN). Un fichier de config projet est requis
(voir « Config » plus bas). Le diagnostic visuel utilise le MCP `mobile-mcp`.

## Flux

1. **Détecter la cible** : `node .claude/scripts/mobile-test-run.mjs detect` renvoie les
   cibles bootées en JSON `{ ios: [...], android: [...] }`.
   - Exactement une cible bootée (toutes plateformes confondues) : utilise-la.
   - Zéro ou plusieurs : **demande à l'utilisateur** quelle plateforme/cible. Ne devine pas.
2. **Lancer la régression** : `node .claude/scripts/mobile-test-run.mjs run --platform <ios|android>`.
   - Résout le bundle id (base + `debugSuffix` de la config), boote la cible iOS si besoin,
     build/install l'app si absente (`expo run:`, plusieurs minutes), joue
     `maestro test <maestroFlowsDir>`, scaffolde le rapport.
   - Imprime un JSON `{ platform, target, results[], artifactDir, reportPath }`.
   - Android : si aucun émulateur n'est booté, le script te dit de lancer `emulator -avd <avdName>` d'abord.
3. **Sur échec d'un flow** (`status: "fail"`) : passe en diagnostic (voir plus bas).
4. **Finaliser** : complète le rapport `reportPath`, affiche le résumé pass/fail dans le chat.

## Couche jugement : diagnostic sur échec

Pour chaque flow en échec, via les outils **mobile-mcp** (`mobile_*`) :

1. Ouvre l'app sur la cible, pilote (`mobile_list_elements_on_screen`,
   `mobile_click_on_screen_at_coordinates`, `mobile_swipe_on_screen`, `mobile_launch_app`)
   jusqu'à l'écran fautif.
2. Capture `<flow>-before.png` et `<flow>-after.png` dans `artifactDir` (`mobile_save_screenshot`).
3. Dump les logs dans `artifactDir` : `xcrun simctl spawn <udid> log ...` ou
   `adb -s <serial> logcat -d > <artifactDir>/android-log.txt`.
4. Rédige la section « Échec » du rapport : cause probable, écran, liens artefacts.

mobile-mcp reste **côté agent** : le script ne l'appelle jamais.

## Config

Le script ne contient **aucune** valeur machine/projet en dur. Tout vient d'un fichier résolu
en cascade : `--config <path>` > `$VF_MOBILE_TEST_CONFIG` > `./.vibeflow/mobile-test.json` >
`./mobile-test.json`. Copie le template `config/mobile-test.example.json` du module et
renseigne : `bundleIdBase`, `debugSuffix`, `android.avdName`, `ios.preferredSimulator`,
`maestroFlowsDir`, `maestroBin`, `reportsDir`.

> Le **bundle id réel** testé est `bundleIdBase + debugSuffix`. Vérifie-le sur ta cible
> (`xcrun simctl get_app_container` / `adb shell pm path`) : un README de flows peut être
> périmé. Si le build de dev n'a pas de suffixe, laisse `debugSuffix: ""`.

## Quick reference

| Besoin | Commande |
|--------|----------|
| Cibles bootées | `node .claude/scripts/mobile-test-run.mjs detect` |
| Régression iOS | `node .claude/scripts/mobile-test-run.mjs run --platform ios` |
| Régression Android | `node .claude/scripts/mobile-test-run.mjs run --platform android` |
| Cible précise | `node .claude/scripts/mobile-test-run.mjs run --platform ios --target <udid>` |
| Sans build auto | `node .claude/scripts/mobile-test-run.mjs run --platform ios --skip-build` |
| Config explicite | `node .claude/scripts/mobile-test-run.mjs run --platform ios --config ./mon-projet/mobile-test.json` |

## Common mistakes

- Tester un build périmé : si le code a changé, laisse le script rebuilder (ne passe pas `--skip-build`).
- Mal régler `debugSuffix` : le bundle id réel est `bundleIdBase + debugSuffix`. Un suffixe faux
  = cible introuvable ou périmée. Vérifie sur la cible, ne te fie pas à un README.
- Ne pas capturer d'artefacts avant/après sur échec : sans preuve visuelle, le diagnostic n'est pas exploitable.
- Deviner la cible quand `detect` est ambigu : demande à l'utilisateur.
- Confondre un artefact de store (`.aab`/`.ipa` de distribution, non installable sur émulateur)
  avec un build de dev local : ce pipeline teste un build de dev (`expo run:`).

## Garde-fous en boucle autonome

Si ce pipeline est piloté dans une boucle test+fix non supervisée, applique la doctrine des
garde-fous (anti-thrash, anti-régression, séparation anti-triche) :
`dev-orchestrator/references/autonomous-guardrails.md`. En clair : on n'affaiblit jamais un
assert Maestro pour « passer », et un fix qui casse un flow vert est reverté.

## Portabilité

Les apprentissages durs de portabilité (maestro hors PATH, JAVA_HOME absent, `expo run` qui ne
rend pas la main, `timeout:` non supporté par certaines commandes Maestro) sont documentés dans
`references/portability-notes.md`.
