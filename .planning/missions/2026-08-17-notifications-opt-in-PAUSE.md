# Mission « Notifications discrètes par défaut + jalons via Claude App » — HANDOFF DE PAUSE

> **PAUSE LEVÉE le 2026-08-17.** Cadrage révisé par Samuel : la mission n'est **pas un sujet
> autonome**, elle est l'**annexe de la Phase 33** (`VFDO-33-watchdog-notifications-des-missions`).
> Plans numérotés à la suite (33-06, 33-07…), contexte adossé au `33-CONTEXT.md` existant par
> **amendement daté** — pas de nouveau dossier de phase. Le fond du périmètre est inchangé.
> Ce fichier reste le **journal de la pause** ; le rapport de mission vit à part.
>
> **Fait vérifié à la reprise** (et non repris sur parole) : `VERSION` = **v2.55.1**, tag `v2.56.0`
> **absent**, revert `07ff554` sur `main`, `plugin.json` à 2.55.1. Le code Phase 33 reste mergé.
> Conséquence forte pour le cadrage : **WTCH-03 tel que livré n'a jamais été distribué** — le flip
> du défaut n'est donc *pas* un changement de comportement publié, c'est une **correction
> pré-distribution**, sans aucune migration de parc à prévoir.

**Date :** 2026-08-17 · **Statut :** reprise en annexe de la Phase 33, **en attente de 6 réponses
de Samuel** (escalades `SendMessage(main)` Q1→Q6). Les deux spikes ont rendu (§6) ; le lock est
**relâché** le temps de l'attente humaine ; le DAG est à `discuss` en frontière `ready`. **Aucune
exécution dispatchée** — Q1 (vecteur du push) et Q5 (vecteur de persistance) débloquent le plan,
et planifier avant elles reviendrait à planifier sur une capacité non vérifiée.

**Correction à porter avant exécution :** le `scope[]` du nœud `exec-defaut` cite
`plugin/conductor/tests/test-notify.sh` — **ce chemin n'existe pas**. Les suites vivent sous
`plugin/conductor/scripts/tests/`. Une suite neuve placée au chemin cité serait **invisible de la
CI** (pattern `ci.yml:213`).
**Manager :** `vf-dev-manager` · **DAG :** `.planning/MISSION-NOTIF.dag.json` (untracked)
**Motif de la pause :** le périmètre notifications doit être revu avec Samuel d'abord. La
mission reprendra avec un **cadrage révisé**. Aucune décision de conception n'a été prise, et
c'est volontaire : la mission s'est arrêtée pendant la phase de mesure, avant tout arbitrage.

---

## 1. État exact à l'arrêt — ce qui a été touché

**Rien dans le code. Rien dans git.**

- Branche : `main`, jamais quittée — **aucune branche de mission créée** (le protocole crée la
  branche avant le premier commit ; il n'y a pas eu de premier commit).
- `HEAD` : `c9969a6` — **inchangé**, aucun commit produit par cette mission.
- Aucun fichier du repo modifié, aucune commande git mutante lancée.
- **Seule empreinte disque :** `.planning/MISSION-NOTIF.dag.json` (untracked) + ce handoff.
- Les untracked préexistants (`.gsd/`, `MISSION-30/31/32.dag.json`, `phases/VFDO-36-…`) ne sont
  **pas** de cette mission — ne pas les attribuer au nettoyage de reprise.

Conséquence pratique : **la reprise ne demande aucun revert**. Le cadrage révisé peut repartir
d'une page blanche, ou réutiliser le DAG et les mesures ci-dessous.

## 2. Contexte de distribution au moment de la pause

La release **v2.56.0 va être retirée de la distribution** : release GitHub + tag supprimés,
`VERSION` revertée à **v2.55.1** sur `main`. **Le code de la Phase 33 reste mergé sur `main`** —
seule la *publication* est retirée.

Ce que ça implique pour la reprise, et qui doit être re-vérifié plutôt que supposé :

- Le mécanisme de notification que cette mission voulait modifier (`notify.sh`, `record_milestone`,
  `progress_epoch` du DAG, signal de stall D-33-F) **est présent sur `main`** mais **n'est plus
  publié**. La reprise devra re-vérifier l'état réel de `VERSION`, du module `conductor` et de sa
  `VERSION` de module avant de raisonner sur des numéros.
- **La fenêtre « aucun lab n'est encore armé » reste ouverte, et s'élargit.** L'argument de timing
  du brief initial — flipper le défaut MAINTENANT évite toute migration de parc — n'est pas
  périmé par le retrait ; il est renforcé, puisque la version qui portait le comportement
  d'émission n'est plus distribuée du tout. À re-confirmer par mesure à la reprise, pas à
  reprendre sur parole.

## 3. Gates franchis avant l'arrêt (réutilisables tels quels)

| Geste | Résultat |
|---|---|
| `driver-lock.sh acquire --owner=mission-notif` | `acquired: true`, generation `1786976103.29323` — aucune mission concurrente |
| `check-mission-invariants.sh` | **exit 3 = SAIN** — tous les globs de `MISSION-INVARIANTS.md` matchent encore un fichier suivi |
| Flags d'enchaînement | `workflow._auto_chain_active: false` **et** `workflow.auto_advance: false` — déjà désarmés, lus directement dans `.planning/config.json` (`gsd_run` est absent sur cette machine, comportement connu et non bloquant) |
| Lock | **relâché** à la clôture de cette pause |

## 4. Le DAG posé (11 nœuds) — à réviser, pas à reprendre tel quel

`init` + 11 `add`. Frontière au moment du halt : `spike-push` et `recon` en `running`, les 9
autres `blocked`. Aucun nœud `done`, aucun `failed`.

```
spike-push ─┐
recon ──────┴→ discuss → plan → plancheck ─┬→ exec-defaut ─┬→ exec-jalons ─┬→ revue ─┬→ docs
                                           └→ exec-skill ──┘               └→ verify ┘
```

Périmètres déclarés (`scope[]`, pour le dispatch parallèle) :
- `exec-defaut` : `plugin/conductor/scripts/notify.sh`, `plugin/conductor/tests/test-notify.sh`
- `exec-skill` : `plugin/conductor/skills/vf-notify/**`

**Avertissement pour la reprise :** ce DAG encode l'interprétation *initiale* du brief (défaut OFF
pour tout · toggle en settings local · jalons GSD → push Claude App · fins de nœud → toast OS).
Cette interprétation n'a **jamais été validée par Samuel** — c'était précisément l'objet du nœud
`discuss`, jamais atteint. Le cadrage révisé doit **re-trancher ces choix**, et donc probablement
re-poser le DAG plutôt que le prolonger.

## 5. Mesures lancées — ce qui a été financé et qu'il ne faut pas repayer

Deux mandats de mesure **en lecture seule** ont été dispatchés avant le halt et laissés finir
(aucun n'écrit dans le repo). Leurs résultats sont consignés en §6.

- **`spike-push`** — disponibilité RÉELLE de l'outil `PushNotification` : existe-t-il, quel est
  son contrat exact, est-il appelable **depuis un sous-agent** (le précédent `AskUserQuestion`,
  déclaré au frontmatter mais absent au runtime en sous-agent, rend la question non théorique),
  et comment dégrade-t-il si l'app Claude n'est pas installée/connectée. Une notification de test
  unique, explicitement étiquetée, était autorisée comme preuve.
- **`recon`** — carte réelle du terrain : chemin de décision « on émet / on n'émet pas » dans
  `notify.sh`, sémantique de `VF_NOTIFY_FORCE_CHANNEL` (dont `none` en kill-switch existant),
  liste des appelants, statut du signal de stall D-33-F, comptage RÉEL des cas de `test-notify.sh`
  et `test-dag.sh` + pattern de découverte CI des ~65 suites, gabarit d'un skill du module
  `conductor` et son lint machine, et **carte des points d'accroche « fin de phase » / « fin de
  milestone »** sachant que `gsd-ship` et `gsd-complete-milestone` sont amont `@opengsd` et ne se
  patchent pas.

## 6. Résultats des mesures — LES DEUX SPIKES ONT RENDU

**Ne pas les repayer.** Les deux mandats ont abouti et corrigent plusieurs prémisses du brief.

### 6.1 `spike-push` — `PushNotification` n'est PAS appelable en sous-agent

Fait central, **mesuré** (appel réel, pas de la doc) :

> `Error: No such tool available: PushNotification. PushNotification is disabled for this
> session, in subagents as well as here.`

- L'outil **existe** dans le harness, `shouldDefer: true`, mais **n'est pas monté** dans le pool
  d'un sous-agent. Ce n'est pas un bannissement explicite, et **ce n'est pas un problème de
  réglage** : toute la config de Samuel est déjà à ON (`tengu_kairos_push_notifications`,
  `agentPushNotifEnabled`, `remoteControlAtStartup`).
- **Conséquence dure :** `vf-dev-manager`, `vf-coder`, `dag.sh` et tous les workers sont des
  sous-agents → **aucun ne pourra jamais émettre un push**. Câbler le push dans `dag.sh` ou dans
  la doctrine d'un manager est structurellement voué à l'échec. C'est le décalque exact du
  précédent `AskUserQuestion` (déclaré au frontmatter, absent au runtime — Phase 30).
- **Contrat réel** : un seul champ **`message`** (< 200 caractères, sans markdown) + `status`.
  **Pas de `title`.** La signature `notify.sh <TITLE> <BODY>` ne mappe donc **pas** 1:1 — il faudra
  aplatir en une ligne.
- **Dégradation propre** : l'outil **ne lève jamais d'erreur**, il rend toujours un succès porteur
  d'un `disabledReason` — `config_off` · `user_present` · `no_transport`. Explicite et testable,
  jamais silencieux. Le succès dit « push *requested* », jamais *delivered* : **aucun accusé de
  réception**, ne jamais bâtir un contrôle de flux qui l'attend.
- **`user_present`** : quand Samuel est actif au terminal, **rien n'est émis du tout**. Le harness
  fait donc déjà une partie du « discret par défaut » que la mission vise — et toute recette
  manuelle sera trompeuse tant qu'il regarde l'écran.
- Anomalie amont signalée, sans conséquence pour nous : la description de l'outil `Monitor` servie
  au sous-agent lui **ordonne** d'émettre un `PushNotification` que le même harness lui refuse.
- **Vecteur recommandé par le spike** : réutiliser le relais déjà éprouvé ici —
  `SendMessage(main)` par le manager, **la session principale** émettant le push.

### 6.2 `recon` — quatre prémisses du brief sont fausses

1. **`VF_NOTIFY_FORCE_CHANNEL=none` n'est PAS un kill-switch.** Aucune valeur `none` n'existe dans
   le code : le `case` (`notify.sh:155-160`) ne connaît que `windows|darwin|linux`, et **toute**
   autre valeur tombe sur `*) : ;;`. `none`, `off` et `xyzzy` silencient identiquement, **par
   accident de la branche par défaut**, et aucun test ne le couvre (0 occurrence de `=none` dans
   tout le repo). → La contrainte §7.1 ci-dessous (« composer avec le kill-switch existant »)
   **repose sur une prémisse fausse et doit être reformulée**.
2. **`record_milestone()` n'est pas dans `notify.sh`** : c'est une fonction **Python de `dag.sh`**
   (`dag.sh:248-268`). `notify.sh` n'a aucune fonction publique — c'est un exécutable
   `notify.sh <TITLE> <BODY>` à 3 fonctions privées.
3. **Comptes annoncés faux** : `test-notify.sh` ne fait pas « 48 cas » mais **16 blocs / 50
   assertions** (le 48 est le nombre d'invocations `assert*`) ; `test-dag.sh` = **49 blocs / 161
   assertions**. Mesuré par exécution réelle, pas par lecture.
4. **`record_milestone` ne voit que des nœuds de DAG de mission, jamais une phase GSD.** Le brief
   conflate les deux. Aucun code du repo ne relie un nœud de DAG à une phase GSD — « remplacer les
   toasts de fin de nœud par des push de fin de phase » n'est pas un remplacement, ce sont deux
   événements de deux systèmes différents.

**Points d'insertion et pièges (le plus actionnable) :**

- Le gate d'opt-in va **entre `notify.sh:67` et `:69`** — après la validation d'arguments, avant la
  cascade. Seul emplacement qui compose proprement.
- **Piège de placement n°1** : le poser **avant `:63`** casse l'instrumentation de `test-dag.sh`
  (la journalisation est injectée juste après la validation d'arguments) → **7 assertions rouges**
  T42/T43 en plus.
- Coût de la dette de test au placement correct : **27 des 50 assertions de `test-notify.sh`
  passent au rouge**, 0 dans `test-dag.sh`. Et **N15 (marqué « DISCRIMINANCE CLÉ, NE JAMAIS
  RETIRER ») reste vert mais devient vacueux** — c'est la perte de discriminance la plus coûteuse
  de la mission, à traiter explicitement.
- **Le signal de stall D-33-F ne passe pas par `notify.sh`** (prouvé : `dag.sh:223-246` sort sur
  stderr, `record_milestone` `:248-268` est une fonction disjointe, appels séparés `:377` et
  `:380`). **Aucun risque d'extinction par effet de bord**, sauf à placer le gate dans `dag.sh` en
  amont du bloc — à interdire nommément au plan.
- **Un seul appelant de `notify.sh` dans tout le dépôt** (`dag.sh:265-266`, sur `done`/`failed`
  uniquement). Le flip doit donc se faire **dans `notify.sh`** (protège tout appelant futur), pas
  dans `record_milestone` (ne protège que le site connu).

**Distribution / persistance :**

- **Aucun vecteur d'engine n'existe pour poser une clé de préférence non-hook dans un settings.**
  `vibeflow-update.sh` n'écrit que des **hooks** (via `merge-hooks.sh`). Le « settings local »
  demandé par le brief est donc **le vecteur le moins outillé des quatre**.
- Le précédent qui marche, `stop-notify`, utilise un **fichier-sentinelle** (`touch`/`rm -f` sur
  `~/.claude/hooks/stop-notify.enabled`), pas une clé JSON — **zéro hook neuf, donc exposition
  nulle au bug `merge-hooks`**. C'est l'argument le plus fort en sa faveur.
- Poser un skill est en revanche trivial : l'engine copie l'arbre entier de
  `plugin/conductor/skills/<nom>/` par glob (`vibeflow-update.sh:1436-1441`). Un `/vf-notify` en
  slash-command demande **deux fichiers** (le `SKILL.md` + son frère dans `plugin/commands/`).
- **Aucun lint machine ne vise les skills** : `check-agents.sh` ne les inspecte que s'ils sont
  déclarés par un agent, et `check-overlaps.sh` n'est pas câblé en CI. La barrière réelle est le
  triplet de version (`check-version-sync.sh`) + la découverte auto de la suite de tests.
- **Découverte CI des suites** (`ci.yml:213`) :
  `find plugin scripts -type f -path '*/tests/test-*.sh' | sort` → **65 suites** confirmées. Une
  suite sous `plugin/conductor/skills/vf-notify/scripts/tests/` serait découverte ; sous
  `plugin/conductor/tests/` (chemin cité à tort dans le `scope[]` du DAG, §4) elle serait
  **invisible de la CI** — scope à corriger avant exécution.
- **Bug `merge-hooks.sh` confirmé présent** (`:459-461` purge sur tout `ev` sans exclure les
  entrées du même appel, puis `:469` append). Si un hook est posé : **une seule entrée** par
  (script, événement), matcher combiné.

**Jalons GSD — asymétrie décisive :** `ship` offre deux points de hook propres et documentés
(`ship:pre`, `ship:post`, contrat générique et additif) ; **`complete-milestone` n'en offre AUCUN**
(0 `render-hooks` sur 815 lignes, et l'index des 12 points de hook gsd-core ne contient aucun
`milestone:*`). Les deux jalons du brief ne sont donc **pas symétriques**. De plus `ship:post`
dispatche **un sous-agent** — donc, d'après 6.1, structurellement incapable d'émettre le push.

## 7. Contraintes à re-porter dans le cadrage révisé

Elles sont indépendantes de l'interprétation du périmètre et resteront vraies :

1. **`VF_NOTIFY_FORCE_CHANNEL=none` existe déjà** comme kill-switch. Un défaut opt-in doit
   **composer** avec lui, pas le remplacer ni le doubler — deux mécanismes d'extinction
   concurrents seraient une régression de lisibilité.
2. **Le signal de stall (D-33-F) n'est pas une notification de confort.** Il reste actif quel que
   soit le toggle. Tout changement de défaut doit prouver qu'il ne l'éteint pas par effet de bord.
3. **Bug d'idempotence cross-matcher de `merge-hooks.sh`** (tracé dans
   `.planning/codebase/CONCERNS.md`) : si la solution pose un hook, une seule entrée par
   script/événement à matcher combiné.
4. **La préférence est légitimement locale** (par machine) mais **la capacité doit voyager** avec
   le module — c'est le cas *inverse* de la régression #38, où un réglage posé en settings local
   du repo n'atteignait aucun lab. Ne pas confondre les deux au moment de choisir le vecteur.
5. **Preuve sous mutation dans les deux sens** : un défaut OFF n'est prouvé que si un cas devient
   ROUGE quand un canal émet sans opt-in. Un vert auto-déclaré ne vaut rien — leçon répétée sur
   quatre phases consécutives.
6. **Non-régression = découverte COMPLÈTE des suites** (pattern CI), jamais les seules suites du
   périmètre.

## 8. Origine et traçabilité

Cette mission est la **résurgence** de l'item de backlog « Notifications de progression des agents
managers » (`.planning/BACKLOG.md`, capturé le 2026-08-11, différé avec pour déclencheur « prochaine
évolution du team-kernel ou des protocoles managers, ou demande récurrente de suivi de mission
longue distance »). La demande directe de Samuel du 2026-08-17 **est** ce déclencheur.

L'item de backlog reste **ouvert et inchangé** — la pause ne le referme pas. Il gagne une
précision utile issue de la demande directe : le vecteur envisagé n'est plus seulement le toast
OS, mais **l'app Claude pour les jalons importants**, avec un **défaut opt-in**.

## 9. Reprise — dans quel ordre

1. Cadrage révisé **avec Samuel** (le périmètre est l'objet même de la révision).
2. Re-vérifier l'état de distribution post-retrait v2.56.0 (`VERSION`, module `conductor`, tags).
3. Réutiliser les mesures de la §6 si elles sont là ; les rejouer sinon.
4. Re-poser un DAG conforme au périmètre révisé.
5. Reprendre le protocole normal : lock, invariants, branche avant le premier commit.
