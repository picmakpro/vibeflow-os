---
phase: VFDO-33-watchdog-notifications-des-missions
plan: 04
subsystem: infra
tags: [bash, notifications, wsl, powershell, portability, testing]

requires: []
provides:
  - "plugin/conductor/scripts/notify.sh : canal de notification OS best-effort, fail-open silencieux, cascade WSL/Windows/Darwin/Linux"
  - "plugin/_internal/lib/vf-portable.sh : IS_WSL, détecteur additif (jamais une redéfinition d'IS_WINDOWS)"
affects: [33-05]

tech-stack:
  added: []
  patterns:
    - "Détection command -v uniquement (jamais uname seul) pour tester la disponibilité d'un canal"
    - "Détachement AU POINT D'INVOCATION du binaire lent ( cmd & ), dispatch et détection restant synchrones"

key-files:
  created:
    - plugin/conductor/scripts/notify.sh
    - plugin/conductor/scripts/tests/test-notify.sh
  modified:
    - plugin/_internal/lib/vf-portable.sh
    - plugin/_internal/tests/test-vf-portable.sh

key-decisions:
  - "notify.sh porte sa PROPRE résolution tolérante de vf-portable.sh (4 candidats identiques au bloc canonique), jamais le bloc `>>> vf-portable:locator` lui-même — sa queue exit 1 est incompatible avec le fail-open exigé. T12 de test-vf-portable.sh reste à 5 consommateurs, inchangé."
  - "Déviation vis-à-vis du plan (action tâche 2, point 9) : le détachement ne peut PAS englober le dispatch entier ( _notify_xxx & ) & — ce double fork isole toute la fonction (y compris ses command -v) dans un sous-shell d'arrière-plan, rendant la mutation rouge n°3 structurellement invérifiable (un set -e interne ne peut jamais remonter au code de sortie du script parent qui ne l'attend pas). Le dispatch redevient synchrone ; seul l'appel au binaire lent (terminal-notifier/osascript/notify-send/powershell.exe) est détaché, au point d'invocation, dans chaque fonction."

requirements-completed: [WTCH-03, QUAL-01]

duration: ~90min
completed: 2026-08-17
status: complete
---

# Phase VFDO-33 Plan 04: notify.sh — canal de notification OS best-effort portable Summary

**Livraison de `notify.sh` (WTCH-03) : cascade de détection portable Windows/WSL/macOS/Linux,
fail-open silencieux inconditionnel, et du détecteur `IS_WSL` additif manquant dans
`vf-portable.sh` qui le rendait aveugle au cas WSL+notify-send-échoue-en-silence.**

## Performance

- **Tasks:** 2
- **Files modified:** 4 (2 créés, 2 modifiés)
- **Commits:** 3 (b7a6ac0, 3f34d04, 72bb185)

## Accomplissements

- `IS_WSL` posé dans `plugin/_internal/lib/vf-portable.sh`, additif après `IS_WINDOWS`, calculé
  via `/proc/version` (overridable par `VF_PROC_VERSION_PATH` pour les tests), mutuellement
  exclusif avec `IS_WINDOWS` par construction (court-circuit).
- `notify.sh` (neuf) : cascade `VF_NOTIFY_FORCE_CHANNEL -> WSL -> Windows -> Darwin -> Linux ->
  silence`, `set -uo pipefail` sans `-e`, `exit 0` inconditionnel, zéro appel à
  `vf_guard_unavailable`.
- Canal Windows : `powershell.exe` (jamais `pwsh`), script par stdin (heredoc quoté), TITLE/BODY
  par variables d'environnement échappées côté PS par `[Security.SecurityElement]::Escape()`,
  AUMID PowerShell littéral, `ToastNotificationManager`.
- Canal macOS : `terminal-notifier` puis `osascript`, forme argv exacte du spike (zéro
  échappement).
- Canal Linux : `notify-send -a VibeFlow`.
- `test-notify.sh` (neuf) : 48 assertions (N1-N15), 0 toast réel, trois points d'injection
  (`VF_NOTIFY_FORCE_CHANNEL`, shims via PATH curé, shim `uname` + `VF_PROC_VERSION_PATH`).

## Task Commits

1. **Tâche 1 : détecteur WSL additif dans `vf-portable.sh`** — `b7a6ac0` (feat)
2. **Tâche 2 : `notify.sh` — cascade portable + fail-open silencieux** — `3f34d04` (feat)
3. **Correction de déviation : détachement au point d'invocation** — `72bb185` (fix)

## Files Created/Modified

- `plugin/_internal/lib/vf-portable.sh` — bloc `IS_WSL` additif, juste après `IS_WINDOWS`
- `plugin/_internal/tests/test-vf-portable.sh` — T14/T15/T16 + garde anti-vert-à-vide à l'épilogue
- `plugin/conductor/scripts/notify.sh` — canal de notification best-effort (neuf)
- `plugin/conductor/scripts/tests/test-notify.sh` — suite N1-N15 (neuf)

## Décisions prises

- **T12 inchangé à 5 consommateurs** : `notify.sh` n'entre pas dans le périmètre du bloc
  localisateur canonique (`guard-driver-lock.sh:94-130`) — il porte sa propre résolution
  tolérante, structurellement identique (mêmes 4 candidats, même ordre) mais avec une issue
  fail-open (`IS_WINDOWS=0; IS_WSL=0`) au lieu du `exit 1` du bloc canonique. Vérifié machine :
  `grep -c '>>> vf-portable:locator' notify.sh` == 0, `grep -c 'vf_guard_unavailable' notify.sh`
  == 0, ligne de rapport T12 toujours « 5 consommateurs » caractère pour caractère.
- **Cascade WSL avant Windows natif** : `IS_WSL` testé avant `IS_WINDOWS` dans `notify.sh` — sous
  WSL, `IS_WINDOWS` vaut structurellement 0 (noyau Linux), donc l'ordre littéral WSL→Windows ne
  change rien en pratique côté valeurs testées, mais fixe la lecture au cas où `notify.sh`
  évoluerait — le vrai piège nommé (uname=Linux ⇒ notify-send à tort) est couvert par le test N5,
  qui prouve que le chemin WSL l'emporte sur toute détection Linux naïve.

## Déviations du plan

### Correctif appliqué en cours d'exécution

**1. [Correction de facture] Détachement déplacé du dispatch vers le point d'invocation**
- **Trouvé pendant :** vérification de la mutation rouge n°3 (Tâche 2)
- **Problème :** le plan (action tâche 2, point 9) prescrivait `case "$channel" in windows)
  ( _notify_windows >/dev/null 2>&1 & ) & ;; ...`, c'est-à-dire englober CHAQUE branche du
  dispatch (fonction entière, y compris ses `command -v`) dans un double niveau de fork
  arrière-plan. Sous cette forme, la mutation rouge n°3 exigée par le plan (déplier `command -v`
  + `set -e`, vérifier que N6 rougit sur l'exit code) est structurellement invérifiable : un
  `set -e` qui tue une fonction à l'intérieur d'un sous-shell détaché ne peut JAMAIS remonter au
  code de sortie du script principal, qui ne l'attend pas et a déjà atteint son propre `exit 0`.
  Testé et confirmé : sous la forme initiale, N6 restait vert (`exit 0`) même sous la mutation.
- **Fix :** le dispatch (`case "$channel" in …`) est redevenu SYNCHRONE ; le détachement descend
  À L'INTÉRIEUR de chaque fonction de canal, autour du seul appel qui peut être lent
  (`( terminal-notifier … & )`, `( osascript … & )`, `( notify-send … & )`,
  `( env … powershell.exe … & )`), un seul niveau de fork au point d'invocation. La détection
  `command -v` reste dans le flux principal du script — rapide, jamais bloquante, mais capable de
  faire mourir le script sous `set -e` si la garde est retirée (exactement ce que mutation n°3
  exploite).
- **Fichiers modifiés :** `plugin/conductor/scripts/notify.sh`
- **Vérification :** `test-notify.sh` reste à 48/0/0 après le changement (stable sur 3+ runs),
  N15 continue de prouver la non-blocking property de l'appelant (0.009s, shim dort 3s).
- **Committé dans :** `72bb185`

---

**Total déviations :** 1 correction de facture (le plan lui-même, pas une implémentation fautive).
**Impact :** structurel, positif — restaure la vérifiabilité de la mutation n°3 exigée par le
plan sans rien retirer aux garanties de non-blocage (N15) ni de cascade (N5).

## Issues Encountered

- **Sonde environnementale (mutation n°3, N6)** : cette machine d'exécution est un vrai macOS
  (`uname -s` = `Darwin`). Le cas N6 du plan ("aucun canal disponible", détection RÉELLE, PATH
  vidé de tout candidat) sélectionne donc le canal `darwin` sur cet hôte, pas `linux` — la
  mutation n°3 vise exclusivement `_notify_linux`, jamais exercée par N6 tel quel ICI. Vérification
  équivalente effectuée : canal forcé à `linux` (`VF_NOTIFY_FORCE_CHANNEL=linux`), `notify-send`
  absent du PATH curé — comportement IDENTIQUE à ce que N6 exercerait sur un runner CI Linux réel
  (le spike cible explicitement "CI Linux"). Résultat rapporté dans la section Mutations ci-dessous.
- **Timing des shims en arrière-plan** : `sleep 0.3` fixe après invocation s'est révélé fragile
  (le fork du canal détaché n'est pas garanti sous une borne de temps fixe, surtout au tout premier
  appel du process de test). Remplacé par un helper `wait_for_file` qui poll activement (jusqu'à 3s
  par défaut) au lieu d'un délai figé — stable sur 5+ runs consécutifs après correction.
- **Utilitaires manquants dans le PATH curé de test** : `env`, `sleep`, `touch`, `bash` ont dû être
  ajoutés au dossier `UTIL_DIR` de `test-notify.sh` (initialement seuls `uname`/`dirname`/`grep`/
  `cat` y figuraient) — ces commandes externes (pas des builtins bash) sont nécessaires à
  l'exécution de `notify.sh` et de ses shims même quand aucun binaire de canal n'est visé.

## Mutations rouges — traces (assertion exacte, attendu, obtenu)

Toutes exécutées après commit (`b7a6ac0` puis `3f34d04`, puis `72bb185` pour le redesign), chaque
mutation restaurée par `git checkout -- plugin/conductor/scripts/notify.sh` immédiatement après
vérification, suite re-confirmée verte (48/0/0) après chaque restauration.

### Mutation n°1 — ordre de cascade inversé (WSL/Windows AVANT Darwin/Linux naïfs)
- **Mutation appliquée :** cascade réordonnée en `FORCE -> IS_WINDOWS -> Darwin(uname) ->
  Linux(uname) -> IS_WSL -> repli linux` — le check `uname -s = Linux` intercepte le cas WSL AVANT
  que `IS_WSL` ne soit jamais consulté (reproduction du piège nommé par le spike : « ordre naïf
  uname=Linux ⇒ notify-send »).
- **Assertion :** `N5 — notify-send JAMAIS invoqué (compteur = 0) — ne jamais retirer`
- **Attendu :** `0`
- **Obtenu :** `1` (rouge) — et l'assertion jumelle `N5 — powershell.exe invoqué` obtient `no` au
  lieu de `yes`.
- **Restauré :** `git checkout -- plugin/conductor/scripts/notify.sh`, suite re-vérifiée 48/0/0.

### Mutation n°2 — retrait du détachement
- **Mutation appliquée :** dans `_notify_darwin`, remplacement de
  `( osascript … >/dev/null 2>&1 & )` par un appel synchrone `osascript … >/dev/null 2>&1`.
- **Assertion :** `N15 appelant capturant (subprocess.run capture_output=True) reprend la main …
  (< 1.5s, shim dort 3s)`
- **Attendu :** < 1.5s (mesure typique sous forme saine : ~0.01s)
- **Obtenu :** **3.357s** (rouge — l'appelant Python a bloqué jusqu'à la fin du shim, qui dort 3s)
- **Note :** `N8` (mesure côté process bash uniquement) rougit également, mais N15 est la mesure
  qui prouve réellement la propriété exigée (blocage de l'APPELANT, pas seulement du process bash
  local) — conforme à la mise en garde du mandat.
- **Restauré :** `git checkout -- plugin/conductor/scripts/notify.sh`, suite re-vérifiée 48/0/0.

### Mutation n°3 — `command -v` déplié + `set -e` (point d'injection déterministe)
- **Mutation appliquée :** dans `_notify_linux`, `if command -v notify-send >/dev/null 2>&1;
  then …; fi` remplacé par `command -v notify-send >/dev/null 2>&1; if [ $? -eq 0 ]; then …; fi`
  (le `command -v` devient une commande de tête de liste, non protégée), PUIS `set -e` ajouté
  juste après `set -uo pipefail`.
- **Vérification via `test-notify.sh` (N6, PATH curé)** : reste verte sur CETTE machine (macOS
  réel) — `N6` sélectionne le canal `darwin` par détection réelle (`uname` = `Darwin`), jamais
  `_notify_linux`, donc la mutation n'est pas exercée par ce chemin ici.
- **Vérification équivalente (canal forcé, reproduisant exactement ce que N6 exercerait sur un
  runner CI Linux où `uname` = `Linux`)** :
  - Code sain : `env PATH="$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=linux bash notify.sh "T" "B"` →
    **exit 0**.
  - Sous mutation (même commande, mêmes conditions) → **exit 1** (rouge) — `command -v
    notify-send` échoue (absent du PATH curé), `set -e` propage le code non-zéro AVANT que le
    script n'atteigne son `exit 0` final, puisque `_notify_linux` est maintenant appelée
    SYNCHRONEMENT depuis le dispatch (cf. déviation ci-dessus).
  - **Assertion :** code de sortie de `notify.sh`
  - **Attendu :** `0`
  - **Obtenu :** `1`
- **Restauré :** les deux changements (dépliage + `set -e`) restaurés par
  `git checkout -- plugin/conductor/scripts/notify.sh`, suite re-vérifiée 48/0/0.

## Bilan chiffré des suites

- `bash plugin/_internal/tests/test-vf-portable.sh` → **16 ok / 0 ko / 0 skip** (T1-T13 inchangés,
  T14/T15/T16 neufs, T12 toujours à 5 consommateurs — texte de la ligne de rapport vérifié
  identique caractère pour caractère).
- `bash plugin/conductor/scripts/tests/test-notify.sh` → **48 PASS / 0 FAIL / 0 SKIP** (N1-N15,
  stable sur 5+ runs consécutifs après correction du timing par `wait_for_file`). N15 requiert
  `python3` — présent sur cette machine, jamais un `skip` silencieux ici.
- **Non-régression du parc COMPLET** : `find plugin scripts -type f -path '*/tests/test-*.sh' |
  wc -l` = **65** (64 → 65, seul ce plan de la Phase 33 ajoute une suite neuve). Les **65 suites
  du dépôt ont été rejouées intégralement** (sans `timeout`, indisponible en natif sur cette
  machine macOS — non bloquant, toutes se sont terminées normalement) : **65/65 vertes, 0 rouge**.
- Aucun toast réel n'est apparu sur cette machine pendant l'exécution de ce plan : tous les tests
  passent par `VF_NOTIFY_FORCE_CHANNEL` ou par un PATH curé qui exclut délibérément
  `osascript`/`terminal-notifier`/`notify-send`/`powershell.exe` réels des scénarios de détection
  réelle (`N5`, `N6`) — vérifié explicitement (aucune notification macOS observée, `UTIL_DIR` ne
  contient jamais ces binaires).

## Zones NON PROUVÉES — héritées du spike, PAS closes par ce plan

Ces trois zones restent ouvertes PAR DÉCISION (D-33-C) et ne doivent JAMAIS être présentées comme
vérifiées :

1. **La chaîne Windows complète n'a jamais été exécutée en conditions réelles** — aucune machine
   Windows disponible. La preuve tient uniquement par shims d'argv/stdin en CI/dev Linux-macOS
   (cas N4). Une recette humaine sur Win10/11 reste une condition de clôture de phase, non menée
   ici.
2. **AUMID arbitraire vs AUMID PowerShell** — non tranché à l'unicité (contradiction non résolue
   dans les sources du spike). L'AUMID PowerShell est retenu comme le choix le plus sûr, pas
   comme prouvé unique.
3. **Latence réelle de `powershell.exe`** — non mesurée sur cette mission (les valeurs 0,3-7s
   citées dans le code viennent de rapports de bugs externes, biaisés vers le pathologique).

## Next Phase Readiness

- `notify.sh` est prêt à être shellé par `dag.sh` (plan 33-05, hors ce plan) : forme d'invocation
  stable (deux argv positionnels TITLE puis BODY, exit toujours 0), aucune dépendance sur
  `driver-lock.sh`/`dag.sh` (vérifié : `notify.sh` ne les importe pas).
- `IS_WSL` est disponible dans `vf-portable.sh` pour tout futur consommateur — actuellement
  `notify.sh` en est le seul lecteur.
- Aucun blocage identifié pour 33-05.

---
*Phase: VFDO-33-watchdog-notifications-des-missions*
*Plan: 04*
*Completed: 2026-08-17*
