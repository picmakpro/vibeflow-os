# Run mobile réel — Phase 34, AGTS-02 (34-01)

> **Statut** : ROUGE
>
> Clos le 2026-09-15. Le run est joué pour de vrai, piloté par l'équipe (`vf-test-orchestrator`
> réel + `vf-test-runner` + `vf-app-fixer`, 2 cycles), mais il ne satisfait pas la condition de
> sortie : la majorité des flows authentifiés restent en échec (cause externe réseau/backend pour
> 4-5 d'entre eux) et le Cycle 2 a déclenché le **signal d'alarme absolu** du mandat — le flow
> `lot5_scrolls_scale_native_header` (état authentifié attendu) a affiché l'écran de LOGIN au lieu
> de l'écran natif attendu. Conformément à la règle « aucune retentative », le run s'est arrêté
> immédiatement à ce constat. Rappel de la condition qui déclenchait ce run :
> `plugin/mobile-test/README.md` § Limites et `plugin/mobile-test-team/README.md` § Limites —
> sortie du statut expérimental conditionnée à un premier run réel vert. Ce run ne l'est pas ;
> AGTS-02 est reportée avec sa trace (voir `## Déclencheur de reprise`).
> Règle de composition du chapeau : le statut global est VERT si et seulement si PIPELINE **et**
> EQUIPE sont tous deux VERT (voir `## Verdicts`). Ici EQUIPE est ROUGE, donc le chapeau est ROUGE
> — il n'existe pas de demi-succès.

Ce document trace, commande par commande, le premier run réel de `mobile-test`(-team) sur le lab
`~/Documents/dev/Scroll-Off/frontend` (Expo/React Native, iOS uniquement). Condition de sortie
visée (`plugin/mobile-test/README.md` § Limites, `plugin/mobile-test-team/README.md` § Limites) :
`detect` → `run --platform ios` → rapport horodaté généré, boucle pilotée par l'équipe
(`vf-test-orchestrator`), sans détruire la session authentifiée non reproductible du lab.

## Environnement mesuré

- Maestro CLI : **2.6.1** (`/Users/samuel/.maestro/bin/maestro`)
- JDK : **OpenJDK 17.0.19** (Homebrew)
- Node.js : **v26.5.0**
- Lab : `~/Documents/dev/Scroll-Off/frontend` (dépôt git DISTINCT, non gouverné par `vibeflow-os`)
- Plateforme : **iOS uniquement**
- Garantie de non-remise à zéro d'état : aucun flow joué ne porte `clearState`/`clearKeychain`,
  aucune désinstallation, aucun rebuild forcé sur la cible retenue (voir `## Témoin de la garde`
  et `## Cycles`).

## Prérequis mesurés

| Prérequis | Statut | Preuve |
|-----------|--------|--------|
| `maestro` résolu | PRESENT | `which maestro` → `~/.maestro/bin/maestro` ; `maestro --version` → `2.6.1` |
| JDK requis par Maestro | PRESENT | `java -version` → `openjdk version "17.0.19"` (Homebrew) |
| Node.js | PRESENT | `node --version` → `v26.5.0` |
| Simulateurs « iPhone 17 Pro » disponibles | PRESENT (2 candidats homonymes, cf. Pitfall 2 de `34-RESEARCH.md`) | `xcrun simctl list devices available --json` → runtime iOS-26-4 UDID `48100F83-6AD7-4E46-918F-5390DF87F797`, runtime iOS-26-2 UDID `8BD53E84-B5BF-482A-8FE5-6A9980555951` |
| Dossier `.maestro/` avec flows | PRESENT | 11 fichiers (`README.md` + 10 `.yaml`) sous `Scroll-Off/frontend/.maestro/` |
| Config projet `mobile-test` (`.vibeflow/mobile-test.json`) | ABSENT avant ce run, **posé par la tâche 1** (préparation projet, pas D-05 — voir plus bas) | `find` initial sans résultat ; fichier créé, `node -e "JSON.parse(...)"` confirme un JSON valide |
| `workflow.use_worktrees` dans `Scroll-Off/.planning/config.json` | ABSENT avant ce run, **posé à `false` par la tâche 1** (préparation projet, pas D-05) | `cat` initial : bloc `workflow` sans cette clé ; après édition, `node -e "..."` confirme `workflow.use_worktrees === false` |
| UDID exact porteur de l'app + session authentifiée | **NON DÉTERMINÉ avant ce run, résolu par la tâche 1** | voir section dédiée ci-dessous |
| Module VF `mobile-test` posé sur ce poste | PRESENT | `~/.claude/skills/mobile-test/`, `~/.claude/scripts/mobile-test-run.mjs` |
| Agent `vf-test-orchestrator` disponible pour ce lab | PRESENT | `~/.claude/agents/vf-test-orchestrator.md` |

**Classement explicite (D-05) :** les deux manques « config projet » et « `use_worktrees` absent »
sont des **tâches de préparation projet normales**, prescrites par le plan lui-même — **pas** des
arrêts propres D-05. D-05 ne vise que Maestro / JDK / simulateur / SDK, tous **PRESENTS** sur ce
poste dès le départ. Aucun de ces deux manques n'a donc déclenché, ni ne pouvait déclencher, un
arrêt propre.

## Résolution de l'UDID cible

Deux simulateurs distincts portent le nom « iPhone 17 Pro » :

| UDID | Runtime | App installée (`get_app_container`) | Conteneur data — date de création (top-level) |
|------|---------|----------------------------------------|-------------------------------------------------|
| `48100F83-6AD7-4E46-918F-5390DF87F797` | iOS 26.4 | Oui — `/Users/.../Containers/Bundle/Application/F138AD7D-.../ScrollOff.app` | **2026-09-12 13:05:12** |
| `8BD53E84-B5BF-482A-8FE5-6A9980555951` | iOS 26.2 | Oui — `/Users/.../Containers/Bundle/Application/12EFE89E-.../ScrollOff.app` | **2026-08-19 16:25:02** |

Les **deux** candidats portent l'app installée (hypothèse A1 de `34-RESEARCH.md` prise en défaut,
comme anticipé Open Question 1) — départage nécessaire.

**Critère de départage employé :** date de création du conteneur *data* de l'app (top-level
`Library`/`Application Support`, via `stat -f '%Sm'` sur le chemin rendu par
`xcrun simctl get_app_container <udid> com.scrolloff.app.ios data`). `.maestro/README.md` du lab
déclare littéralement : « Depuis le 2026-08-19, une session authentifiee reelle est ouverte sur le
simulateur de recette ». Le conteneur data de `8BD53E84` a été créé le **2026-08-19**, jour pour
jour la date déclarée par le lab. Celui de `48100F83` a été créé le **2026-09-12**, soit après
cette date — un conteneur créé après le 19 août ne peut pas porter le JWT obtenu ce jour-là (le
code à 6 chiffres est consommé et non reproductible). Le conteneur *bundle* seul (date de build/
prebuild) n'était **pas** discriminant (les deux à quelques secondes d'écart, 2026-09-12) — c'est
le conteneur *data* qui tranche, conformément à la méthode suggérée par le plan
(`stat -f '%Sm' <chemin>`).

UDID retenu : 8BD53E84-B5BF-482A-8FE5-6A9980555951

Le candidat `48100F83-6AD7-4E46-918F-5390DF87F797` a été refermé par précaution après mesure
(`xcrun simctl shutdown`, geste non destructif — n'efface aucune donnée) pour éviter toute
résolution ambiguë en aval si `--target` n'était pas transmis explicitement à un appel.

## Témoin de la garde

Recherche des deux motifs de remise à zéro d'état Maestro (`clearState`, `clearKeychain`) sur
l'arbre `~/Documents/dev/Scroll-Off/frontend/.maestro`.

**Découverte préalable au témoin, documentée pour transparence :** un balayage **littéral** du
contenu de TOUS les fichiers du dossier (y compris `README.md`) trouve une occurrence dans
`README.md` lui-même — sa prose d'avertissement cite verbatim `clearState: true` et
`clearKeychain` pour en interdire l'usage (« Aucun flow de ce dossier ne doit `launchApp` avec
`clearState: true`, ni `clearKeychain` »). C'est un **faux positif de documentation**, pas un
motif actif dans un flow Maestro exécutable. Le témoin ci-dessous scope donc la recherche aux
fichiers `.yaml` du dossier (les seuls que Maestro exécute réellement) — définition opérationnelle
du risque réel (un flow qui DÉTRUIT l'état), sans réduire la protection : aucun `.yaml` n'est
exclu. Ce choix de scope est documenté ici, pas appliqué en silence.

**Sortie 1 — état réel, avant mutation (scope `.yaml`) :**
```
$ grep -rnE "clearState|clearKeychain" *.yaml
(aucune sortie)
exit_code=1   # grep : 1 = aucun match, résultat attendu
```

**Sortie 2 — avec le flow mutant témoin `zz-mutant-garde.yaml` (contient `clearState: true`) :**
```
$ grep -rnE "clearState|clearKeychain" *.yaml
zz-mutant-garde.yaml:8:    clearState: true
exit_code=0   # match trouvé — la garde RESTITUE ROUGE
```

**Sortie 3 — après suppression du flow mutant :**
```
$ rm zz-mutant-garde.yaml
$ grep -rnE "clearState|clearKeychain" *.yaml
(aucune sortie)
exit_code=1   # retour à l'état propre
```

Le flow jetable a été supprimé immédiatement après la mesure ; le dossier `.maestro` du lab
contient exactement les 11 fichiers d'origine (`README.md` + 10 `.yaml`), confirmé par `ls -la`
après suppression.

**Note pour le lecteur du script de vérification automatique du plan (34-01-PLAN.md, tâche 1) :**
ce script scanne le contenu de TOUS les fichiers du dossier sans filtrage d'extension. Rejoué tel
quel sur l'état réel (avant toute mutation de ce run), il rend `GARDE VIOLEE: README.md` (exit 1)
— à cause du même faux positif de documentation décrit ci-dessus, pas d'un motif actif. Ce résultat
est reproductible et déterministe ; il n'est pas la conséquence d'une action de cette tâche. Le
code de sortie réel de ce script littéral, mesuré avant toute mutation : `1`. Rejoué avec le flow
mutant présent : `1` également (`GARDE VIOLEE: README.md,zz-mutant-garde.yaml`). Rejoué après
suppression du mutant : `1` de nouveau (`GARDE VIOLEE: README.md` — le même faux positif
préexistant). La garde **substantielle** (scope `.yaml`, ci-dessus) est, elle, pleinement
capable de rendre rouge sur un vrai motif et de revenir propre — c'est elle qui protège
effectivement la session.

## Dispatch

Le manager de mission a invoqué `vf-test-orchestrator` en sous-agent le 2026-09-15 (horodatage du
premier geste mesuré : `2026-09-15T00:53:51Z`) avec mandat portant : lab
`~/Documents/dev/Scroll-Off/frontend`, plateforme iOS uniquement, cible imposée
`--target 8BD53E84-B5BF-482A-8FE5-6A9980555951` (déjà résolue, à ne pas re-déterminer), flows
existants uniquement (aucun flow neuf, D-10), budget de 2 cycles de fix maximum, et rappel verbatim
des interdictions dures (pas d'install système, pas de remise à zéro d'état, pas de désinstallation,
pas de rebuild forcé, pas d'assert affaibli, arrêt immédiat sur écran de login inattendu).

`vf-test-orchestrator` (ce document) a ensuite dispatché, en sous-agent réel (outil Agent, pas une
exécution manuelle de Maestro par l'exécutant) :
- `vf-test-runner` — Cycle 1 (run initial) et Cycle 2 (re-run après fix), chacun avec mandat
  explicite reprenant la cible imposée et les interdictions dures.
- `vf-app-fixer` — un cycle de fix entre les deux, avec le diagnostic + les pistes de recherche
  documentaire portées par l'orchestrateur (ADR-045, voir Cycle 1 ci-dessous).

Chaque dispatch a rendu un bloc de retour structuré (résumé dans `## Cycles`), pas un message
humain.

## Cycles

### Cycle 1 — run initial

**Commande** (exécutée par `vf-test-runner`, dispatché) :
```
node ~/.claude/scripts/mobile-test-run.mjs run --platform ios --target 8BD53E84-B5BF-482A-8FE5-6A9980555951
```
- **Code de sortie : 0**
- **Build : déjà installé** (aucun rebuild déclenché — confirmé par le rapport)
- **Commit testé (app) : `56efc9e`**
- **Résultat : 4/10 PASS, 6/10 FAIL** — voir tableau ci-dessous.
- **Rapport : `test-runs/2026-09-15-0254.md`**, artefacts : `test-runs/2026-09-15-0254/`
  (`maestro-junit.xml`, `expo.log`) + captures Maestro détaillées sous
  `~/.maestro/tests/2026-09-15_025422/`.
- **Signal d'alarme (règle 5) : NON déclenché** — aucun échec ne pointe vers un écran de login.
- **Garde-fous confirmés par le worker** : aucun flow modifié/créé, aucun `clearState`/
  `clearKeychain` joué, aucune désinstallation, aucun rebuild forcé.

| Flow | Résultat | Durée |
|---|---|---|
| login_index_smoke | PASS | 4000 ms |
| login_index_keyboard_absorption | PASS | 8000 ms |
| login_root_swipeback_disabled | PASS | 6000 ms |
| deeplink_unauthenticated_anchors_login | PASS | 11000 ms |
| lot2_profil_no_layout_gap | FAIL | 20000 ms |
| lot3_app_selection_formsheet | FAIL | 20000 ms |
| lot3_daily_target_formsheet_and_giveup_alert | FAIL | 29000 ms |
| lot3_logout_alert_cancel | FAIL | 11000 ms |
| lot4_challenges_smoke | FAIL | 20000 ms |
| lot5_scrolls_scale_native_header | FAIL | 22000 ms |

**Diagnostic des 6 échecs** (par inspection des captures d'écran Maestro, pas seulement le message
d'assertion) — deux causes distinctes, aucune n'est un flow Maestro à corriger :
1. **Cause externe (réseau/backend)** — `lot2_profil_no_layout_gap`, `lot3_app_selection_formsheet`,
   `lot3_logout_alert_cancel`, `lot4_challenges_smoke` : toast visible « error in fetchCurrentUser:
   AxiosError: Net… », le contenu dépendant de l'API reste vide. **Vérifié par l'orchestrateur** :
   `https://api.scrolloff.com` répond HTTP 404 depuis ce poste (DNS/TLS/réseau fonctionnels depuis
   la machine hôte — donc pas une panne réseau générale du poste), mais l'URL exacte configurée
   pour le build (`.env`) n'a pas pu être lue (fichier protégé, secret). Classé **ROUGE DE CAUSE
   EXTERNE** (arête assumée du plan) — aucun fix tenté, ce n'est pas un défaut de code app
   identifiable sans accès au backend/à la config d'environnement.
2. **Metro embarque des fichiers `*.test.tsx` dans le bundle runtime** — `lot5_scrolls_scale_native_header`,
   `lot3_daily_target_formsheet_and_giveup_alert` : overlay « Uncaught Error: Property 'jest'
   doesn't exist », pointant vers `app/_screen-time/ios_index.test.tsx` et `app/(tabs)/index.test.tsx`
   — tous deux physiquement logés dans le dossier de routing `app/` d'expo-router.

**Gate recherche documentaire (ADR-045)** appliquée par l'orchestrateur avant dispatch du fixer
(cause touchant un comportement de framework, expo-router/Metro) : recherche web menée, cause
confirmée par une source sourcée — issue GitHub `expo/expo#28000` (« Standalone Jest `.test` files
in /app directory with expo-router cause bundling error »), confirmée par `expo/router#889` :
`require.context(EXPO_ROUTER_APP_ROOT, true, ...)` matche tout `.ts/.tsx` sous `app/`, sans
exclusion native des fichiers `.test.tsx`. Piste transmise au fixer : ajouter
`config.resolver.blockList = /\.test\.[jt]sx?$/;` à `metro.config.js`.

### Cycle de fix — `vf-app-fixer`

- **Fichier touché** : `metro.config.js` (config app racine, domaine autorisé).
- **Nature du fix** : ajout de `config.resolver.blockList = /\.test\.[jt]sx?$/;` avant
  `withNativeWind(...)`. Aucun `blockList` préexistant écrasé (vérifié par le fixer).
- **SHA du commit (dépôt `Scroll-Off/frontend`, branche `feat/mv`) : `4679f8d`**
  (`fix(metro): exclure les fichiers de test du bundle app`).
- Aucun fichier `.maestro/**` touché, aucune mention IA/attribution dans le message (convention du
  dépôt Scroll-Off respectée). Pas de push (convention projet non explicite sur ce point, resté en
  local, par prudence — cf. règle du worker : ne présume pas).

### Cycle 2 — re-run après fix

**Commande** (identique, mêmes garde-fous) :
```
node ~/.claude/scripts/mobile-test-run.mjs run --platform ios --target 8BD53E84-B5BF-482A-8FE5-6A9980555951
```
- **Code de sortie : 0**
- **Build : déjà installé** (toujours aucun rebuild déclenché)
- **Commit testé (app) : `4679f8d`**
- **Résultat : 4/10 PASS, 6/10 FAIL** — score global inchangé, mais composition différente.
- **Rapport : `test-runs/2026-09-15-0259.md`**, artefacts : `test-runs/2026-09-15-0259/` +
  captures Maestro sous `~/.maestro/tests/2026-09-15_025948/`.

| Flow | Cycle 1 | Cycle 2 |
|---|---|---|
| login_index_smoke | PASS | PASS |
| login_index_keyboard_absorption | PASS | PASS |
| login_root_swipeback_disabled | PASS | PASS |
| deeplink_unauthenticated_anchors_login | PASS | PASS |
| lot2_profil_no_layout_gap | FAIL | FAIL (cause externe, inchangé) |
| lot3_app_selection_formsheet | FAIL | FAIL (cause externe, inchangé) |
| lot3_logout_alert_cancel | FAIL | FAIL (cause externe, inchangé) |
| lot4_challenges_smoke | FAIL | FAIL (cause externe, inchangé) |
| lot3_daily_target_formsheet_and_giveup_alert | FAIL (overlay jest) | FAIL — **overlay jest disparu**, bloqué désormais par la même cause externe réseau (toast « error in fetchCurrentUser » visible, écran « objectif non défini » faute de données chargées) |
| lot5_scrolls_scale_native_header | FAIL (overlay jest) | **FAIL — SIGNAL D'ALARME : écran de LOGIN affiché au lieu de l'écran natif attendu** |

**Aucune régression sur la baseline verte du Cycle 1** — les 4 flows non-authentifiés restent
PASS à l'identique.

**Le fix Metro a fonctionné pour sa cause visée** : l'overlay « jest doesn't exist » a disparu des
deux flows ciblés (confirmé par inspection des captures d'écran du Cycle 2 — capture
`screenshot-❌-...-(lot3_daily_target...).png` : écran métier normal + toast réseau, plus d'overlay
JS). `lot3_daily_target_formsheet_and_giveup_alert` reste rouge mais pour la **cause externe**
partagée avec les 4 autres flows (masquée au Cycle 1 par le crash Metro qui intervenait plus tôt).

**SIGNAL D'ALARME ABSOLU DÉCLENCHÉ** sur `lot5_scrolls_scale_native_header` : la capture
`screenshot-❌-1789434133959-(lot5_scrolls_scale_native_header).png` montre l'écran de connexion
non authentifié (« ScrollOff — Assez scrollé, passe à ScrollOff ! », champ e-mail, bouton « Me
connecter ») au lieu de l'écran natif `scrolls-scale` attendu (flow authentifié, iOS uniquement).
**Conformément au mandat, arrêt immédiat, aucune retentative.** Aucun 3ᵉ cycle n'a été engagé,
aucune autre interaction avec le simulateur n'a eu lieu après ce constat.

**Garde-fous confirmés (Cycle 2)** : aucun flow modifié/créé, aucun `clearState`/`clearKeychain`
joué (règle respectée par construction — jamais présent dans un flow réel, cf. `## Témoin de la
garde`), aucune désinstallation, aucun rebuild forcé — le rapport confirme `Build : déjà installé`
sur la cible imposée. **L'app n'a donc PAS été réinstallée ni son état forcé à zéro par ce run** :
l'hypothèse la plus vraisemblable (non confirmée, aucune investigation supplémentaire menée en
respect de la règle « sans retentative ») est que la logique `fetchRenewToken` de
`app/_layout.tsx` — documentée dans `.maestro/README.md` du lab comme redirigeant vers `/login`
« sans JWT valide » — interprète l'échec réseau persistant de `fetchCurrentUser` (même cause
externe que les 4-5 autres flows) comme une session invalide, et redirige vers `/login` **sans que
le JWT en Keychain soit nécessairement détruit**. C'est le même mécanisme que celui documenté pour
l'état PRÉ-2026-08-19 du lab. Cette hypothèse n'a pas été vérifiée par une inspection directe du
Keychain (aucune interaction supplémentaire n'a été tentée, par respect strict de la règle
« aucune retentative ») — elle reste donc **non confirmée**, et doit être traitée comme telle par
quiconque reprend ce travail.

## Verdicts

PIPELINE: VERT

Le module mécanique `mobile-test` a fait `detect` → `run --platform ios` → rapport horodaté
réellement produit, deux fois (`2026-09-15-0254.md`, `2026-09-15-0259.md`), code de sortie 0 à
chaque fois, sans erreur de script. La mécanique du pipeline fonctionne.

EQUIPE: ROUGE

La boucle a été pilotée par `vf-test-orchestrator` réellement dispatché (voir `## Dispatch`), avec
un cycle de fix réel (`vf-app-fixer`, commit `4679f8d`) et un arrêt propre (voir ci-dessus) — mais
le résultat substantiel n'est pas « l'app marche vraiment » : 6/10 flows restent rouges après le
cycle de fix, et le Cycle 2 a déclenché le signal d'alarme absolu (écran de login inattendu sur un
flow authentifié), qui a forcé l'arrêt immédiat avant tout budget de cycle supplémentaire. Un
PIPELINE vert avec un EQUIPE rouge est un run ROUGE au sens de D-05 — pas un demi-succès.

Rapport du run : 2026-09-15-0259.md

## Déviations assumées

- [2026-09-15] La condition littérale « build depuis zéro » de la sortie d'expérimental
  (`mobile-test/README.md:119-123`) n'a été satisfaite ni au Cycle 1 ni au Cycle 2 : l'app était
  déjà installée sur la cible retenue (`8BD53E84-...`), donc `cmdRun` n'a jamais emprunté la
  branche `buildInstall`. C'est un choix assumé : forcer une désinstallation/réinstallation aurait
  détruit la session authentifiée non reproductible du lab — la préservation de cette session
  (contrainte dure, irréversible) prime sur la lecture littérale de la condition ROADMAP. Le chemin
  de build (`expo run:ios`) reste donc non exercé par ce run.
- [2026-09-15] Les deux manques spécifiques au lab mesurés par la recherche (absence de
  `.vibeflow/mobile-test.json`, absence de `workflow.use_worktrees`) ont été traités comme des
  tâches de PRÉPARATION PROJET normales (posées par la tâche 1 de ce plan), **jamais** comme des
  arrêts propres au sens D-05 — qui ne vise que Maestro/JDK/simulateur/SDK, tous présents dès le
  départ sur ce poste.
- [2026-09-15] **Défaut de forme de la sonde, pas de la garde.** La sonde `<automated>` littérale
  des tâches 1 et 2 de `34-01-PLAN.md` scanne `fs.readdirSync(".maestro")` puis teste
  `/clearState|clearKeychain/.test(s)` sur le contenu **brut** de chaque fichier du dossier, sans
  filtrage d'extension — elle ne distingue donc pas un flow `.yaml` exécutable d'un fichier de
  documentation. Rejoué sur ce dossier, ce test trouve exactement 2 occurrences, toutes deux dans
  `.maestro/README.md` lignes 35-36 : « ... ne doit `launchApp` avec `clearState: true`, ni
  `clearKeychain`, ni desinstaller/effacer le simulateur. » — une phrase de PROSE qui **interdit**
  ces deux motifs (verbe « ne doit »), pas un flow qui les invoque. Un lecteur peut vérifier ceci
  lui-même : `grep -n "clearState\|clearKeychain" .maestro/README.md` → 2 lignes, 35-36, dans une
  clause négative. Re-vérification scopée aux seuls fichiers réellement exécutés par Maestro
  (`grep -rnE "clearState|clearKeychain" .maestro/*.yaml`) : **aucune occurrence** sur les 10
  `.yaml` du dossier, avant comme après ce run. La sonde littérale reste donc à l'exit code `1` par
  construction (elle ne peut jamais matcher zéro tant que `README.md` documente l'interdiction en
  ces termes) ; ce n'est pas corrigeable dans le périmètre de fichiers modifiables par ce plan
  (ni `34-01-PLAN.md`, ni `README.md` du lab, tous deux hors `files_modified`). La garde
  SUBSTANTIELLE (scope `.yaml`, seule pertinente pour la sécurité réelle) a, elle, été pleinement
  prouvée capable de rendre rouge puis de revenir propre (voir `## Témoin de la garde`, trois
  sorties).

## Déclencheur de reprise

**Capturé :** 2026-09-15 · **À explorer :** avant tout nouveau run Maestro sur la cible
`8BD53E84-B5BF-482A-8FE5-6A9980555951` de `Scroll-Off/frontend`

> **Source :** Cycle 2 de ce run (`34-RUN-MOBILE.md`, Phase 34, plan 34-01) — signal d'alarme
> absolu déclenché sur `lot5_scrolls_scale_native_header` (écran de login affiché au lieu de
> l'écran natif attendu), arrêt immédiat sans investigation supplémentaire.

**Cadrage.** Deux causes possibles, non départagées par ce run (aucune investigation menée, par
respect strict de la règle « aucune retentative ») : (a) la session authentifiée du lab a été
réellement perdue (JWT effacé du Keychain — catastrophique, non reproductible sans un nouveau code
à 6 chiffres) ; (b) le JWT est toujours présent en Keychain mais `app/_layout.tsx`/
`fetchRenewToken` redirige à tort vers `/login` dès que l'appel réseau `fetchCurrentUser` échoue
(même cause externe réseau/backend que 4-5 autres flows de ce run), sans que la session soit
réellement détruite — bug de robustesse potentiel, pas une perte de données.

**Pourquoi différé :** la règle absolue du mandat de ce run interdit toute retentative dès la
détection d'un écran de login inattendu. Lever l'ambiguïté (a) vs (b) exige une inspection humaine
directe du Keychain du simulateur `8BD53E84-B5BF-482A-8FE5-6A9980555951` (hors du périmètre outillé
et du mandat de cette exécution) et/ou une vérification de la disponibilité du backend
`api.scrolloff.com` avec la configuration exacte du build (`.env`, protégé, non lisible par ce
run).

**Déclencheur de resurgence :** dès qu'un humain a (1) confirmé si le JWT est toujours présent dans
le Keychain du simulateur `8BD53E84-B5BF-482A-8FE5-6A9980555951` (Xcode → Devices and Simulators,
ou inspection directe du fichier Keychain du simulateur) ET (2) confirmé la disponibilité du
backend pour la configuration exacte du build de recette — reprendre AGTS-02 avec un nouveau run
`mobile-test`, cible `--target 8BD53E84-B5BF-482A-8FE5-6A9980555951` toujours imposée. Si (a) est
confirmé (session détruite), un nouveau code à 6 chiffres devra être consommé manuellement par un
humain avant toute reprise — ce geste n'est délégable à aucun agent.

## Périmètre

SHA de base : 7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f

`git diff --quiet 7e504ade15730ab3db38c6cb7bacd5b1f95ebb0f -- plugin scripts docs manual .github README.md README.fr.md`
→ **exit 0** (mesuré le 2026-09-15, après l'ensemble des tâches de ce plan) : aucun fichier de ces
chemins n'a été touché. Le seul fichier créé par ce plan dans ce dépôt est `34-RUN-MOBILE.md` (ce
document) et son `34-01-SUMMARY.md` associé — tous deux dans le dossier de phase, hors du périmètre
scanné par ce diff (c'est le sens du scope choisi).

Aucun secret n'a été recopié dans ce document (le contenu de `.env` de `Scroll-Off/frontend` n'a
jamais été lu — accès bloqué par une garde de sécurité de l'environnement d'exécution ; seul le
domaine public `api.scrolloff.com`, déjà cité dans `.maestro/README.md` du lab, a été mentionné).
Aucun arbitrage humain n'a été invoqué dans ce document — toutes les décisions consignées ci-dessus
(UDID retenu, scope de la garde, arrêt sur signal d'alarme) sont des applications directes de
règles déjà écrites dans le mandat et le plan, pas des arbitrages nouveaux.
