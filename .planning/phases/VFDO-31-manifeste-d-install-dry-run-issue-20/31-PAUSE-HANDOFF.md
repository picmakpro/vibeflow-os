# Phase 31 — Handoff de pause (mission nocturne interrompue)

**Date** : 2026-08-16 · **Manager** : `vf-dev-manager` (owner de lock `mission-31-nocturne`)
**Motif de la pause** : redémarrage de la session Claude Code par Samuel (ordre du coordinateur).
**Statut de la mission** : `paused` — **arrêtée pendant la phase de collecte de cadrage**, AVANT
tout dispatch de worker d'écriture, AVANT toute création de branche, AVANT tout commit.

> ⚠️ **Ce fichier est le brief de reprise.** Un nouveau manager le lit en premier, puis reprend au
> §« Prochain geste exact ».

---

## 1. Où en est la mission

| Étape | État |
|---|---|
| Verrou de driver | acquis puis **relâché** à la pause (`owner=mission-31-nocturne`) |
| Gate d'invariants | **exécuté, code 3 = SAIN** — tous les globs de `MISSION-INVARIANTS.md` matchent |
| Flags d'enchaînement | **déjà désarmés** dans `.planning/config.json` (`workflow._auto_chain_active: false`, `workflow.auto_advance: false`) — vérifiés par lecture, cf. §5 |
| Plan de bataille / DAG | **écrit** → `.planning/MISSION-31.dag.json` (9 nœuds) |
| Branche de phase | **NON créée** (aucun commit à isoler) |
| Cadrage `31-CONTEXT.md` | **NON écrit** |
| Plans, exécution, revue, vérif | **NON démarrés** |
| Commits produits par cette mission | **AUCUN** (`git log` inchangé, HEAD = `378a37c`) |
| Recherche moteur (`rech-moteur`) | **LIVRÉE avant la pause** → `31-RECHERCHE-moteur.md` (voir §2) |
| Fichiers modifiés par cette mission | **AUCUN fichier de code**. Trois artefacts de planning posés : `.planning/MISSION-31.dag.json`, ce handoff, `31-RECHERCHE-moteur.md` — tous **non commités** (voir §6) |

## 2. Le worker en vol — finalement LIVRÉ (mise à jour post-pause)

Un seul worker était en vol : le nœud `rech-moteur` (agent `Explore`, read-only). Il a **terminé
juste avant que la pause ne prenne effet**. Son rapport a été **persisté sur disque** :

> **`.planning/phases/VFDO-31-manifeste-d-install-dry-run-issue-20/31-RECHERCHE-moteur.md`**

Le nœud est marqué `done` dans le DAG. **NE PAS le re-dispatcher** — la frontière `ready` de la
reprise est donc directement `discuss`.

Ce que le rapport contient (et que la reprise n'a plus à chercher) : les 30 fonctions de
`vibeflow-update.sh` avec leurs plages de lignes · l'**inventaire exhaustif des écritures disque**,
directes ET indirectes par sous-processus (la matière première de MANI-02) · la résolution
`TARGET_ROOT`/scope · les chemins `install|update|uninstall|rollback|status` (il n'y a **pas** de
verbe `remove` ni de sous-commande `calibrate` dans l'engine) · le contrat post-Phase-30 de
`merge-hooks.sh` · l'infra de test et la commande de découverte des suites · le mécanisme
d'énumération des fichiers d'un module.

**Trois faits qui pèsent sur le cadrage** (détail et lignes dans le rapport) :

1. **Aucun manifeste de pose n'existe** aujourd'hui ; `uninstall_module` reconstruit la liste depuis
   le **cache**, donc fausse dès qu'un module en disparaît — trou rattrapé en dur par
   `retired-modules.txt`. C'est le bug que MANI-01/03 ferment.
2. **Trois énumérations parallèles** de la même chose (`install_module`, `gitignore_add_paths`,
   `uninstall_module`), à garder cohérentes à la main. Et `gitignore_add_paths` couvre **deux
   entrées que l'énumération d'install ne produit pas** (`.claude/memory/`,
   `.claude/scripts/vf-portable.sh`) — un manifeste dérivé de la seule pose les manquerait.
3. **Correction de prémisse du brief** : le brief affirme que le gate `check-version-sync` doit
   rester vert sur le compteur « N suites » des README. **Faux.** `scripts/check-version-sync.sh`
   gate le compteur de **modules**, jamais celui des suites — la valeur `61`
   (`README.md:124`, `README.fr.md:128`) n'est contrôlée par aucun gate. Mettre à jour les compteurs
   reste souhaitable, mais c'est une discipline **non gatée** ; en faire un gate serait un ajout de
   périmètre soumis à QUAL-01. **À trancher au cadrage.**

<details>
<summary>Mandat d'origine du nœud (archivé — ne pas re-dispatcher)</summary>

> Repo `/Users/samuel/Documents/dev/vibeflow-os` (branche `main`, v2.53.0, post-Phase-30). Anatomie
> précise du moteur d'install pour cadrer la Phase 31. Lire le code, rapporter des FAITS avec
> chemins absolus + numéros de ligne. N'écrire aucun fichier. Rapport compact (~120 lignes max).
>
> 1. `plugin/_internal/vibeflow-update.sh` : liste des fonctions (plages de lignes + rôle en une
>    ligne) · **TOUS les points d'écriture disque** (`cp`, `install`, `mkdir`, `cat >`, `tee`, `mv`,
>    `rm`, python, `jq` → fichier) avec numéros de ligne — c'est l'inventaire critique du `--dry-run`
>    · résolution de `TARGET_ROOT` et du scope (user / project / project-no-commit) · chemins de code
>    install vs update vs calibrate vs remove/uninstall (flags et parsing d'arguments) · conventions
>    de log (helper ? préfixes `[ok]`, `[plan]` … ?) · un fichier de type manifeste est-il déjà
>    écrit (`grep` sur `manifest`, `.vibeflow-`, `known-versions`) ?
> 2. `plugin/_internal/merge-hooks.sh` post-Phase-30 : sous-commandes/modes (add/remove/dedupe ?),
>    écrit-il `settings.json` directement, a-t-il une capacité dry-run/preview, quelles cibles
>    settings il touche (`settings.json` vs `settings.local.json`).
> 3. Tous les autres fichiers de `plugin/_internal/` : liste + rôle en une ligne (dont
>    `lib/vf-portable.sh` né en Phase 30).
> 4. Infrastructure de test : où vivent les suites, nommage, **commande exacte** qui les lance
>    toutes, liste exacte des suites existantes ; où est écrit le compteur « N suites » dans
>    `README.md` et `README.fr.md` (lignes + N courant) ; quel script vérifie la synchro de version.
> 5. Énumération des fichiers d'un module à la pose : copie de répertoires entiers ou liste issue de
>    `module.json` ? Montrer la fonction + les lignes qui décident « quels fichiers du module X vont
>    où ».
>
> Faits seulement, aucune recommandation.

</details>

## 3. Le DAG figé

`.planning/MISSION-31.dag.json` — 9 nœuds, **1 `done`** (`rech-moteur`), frontière `ready` =
`discuss` :

```
rech-moteur (done — rapport : 31-RECHERCHE-moteur.md)
└─ discuss  (READY — cadrage 31-CONTEXT.md, geste du manager)
   └─ plan  (pipeline gsd-plan-phase via vf-coder)
      └─ plancheck (re-validation externe — leçon Phase 30 : 5 faux verts)
         └─ exec  (à ÉCLATER en exec-01..NN après le plan)
            ├─ revue (vf-reviewer EN DIRECT)
            └─ verif (gsd-verifier goal-backward)
               └─ issue20-draft (MANI-04 — DRAFT sur disque, JAMAIS posté)
            └─ docs  (hygiène documentaire unique, deps=revue+verif)
```

Aucun nœud n'est resté en `running` : le seul worker en vol a livré (§2), tous les autres nœuds
n'ont jamais été dispatchés.

## 4. Arbitrages « Claude's Discretion » déjà pris

Aucun arbitrage d'implémentation n'a été tranché — le cadrage n'a pas commencé. Seules des
**décisions de pilotage** ont été prises, toutes reconductibles :

| # | Décision | Motif |
|---|---|---|
| P-1 | Nœud `revue` posé systématiquement, EN DIRECT par le manager | doctrine team-kernel + leçon des 5 faux verts de la Phase 30 (le brief l'exige explicitement sur les lots moteur) |
| P-2 | Nœud `plancheck` ajouté **en plus** du plan-checker interne de `gsd-plan-phase` | même leçon Phase 30 ; un plancheck lecture seule a historiquement trouvé 3 bloquants par plan |
| P-3 | UN SEUL nœud `docs` en fin de mission (jamais un par étape) | doctrine hygiène documentaire — un nœud par étape documenterait des états intermédiaires déjà périmés |
| P-4 | `issue20-draft` dépend de `verif` | le draft de livraison ne se rédige que sur un livrable vérifié |
| P-5 | Slug de dossier de phase **provisoire** : `VFDO-31-manifeste-d-install-dry-run-issue-20` | le dossier n'avait pas encore été créé par la chaîne GSD. **Si le pipeline en crée un autre, déplacer ce handoff dedans** |

## 5. Constats machine à ne pas refaire (déjà vérifiés cette nuit)

- `bash plugin/conductor/scripts/check-mission-invariants.sh` → **exit 3 (SAIN)**.
- `$S` (dossier des scripts) se résout à **`plugin/conductor/scripts`** (le lab courant prime ;
  `~/.claude/scripts` existe aussi et héberge une version antérieure — ne pas l'utiliser).
- `gsd_run` **n'existe pas** comme commande dans ce shell → le reset de flags par CLI échoue.
  Sans objet : `.planning/config.json` porte déjà `_auto_chain_active: false` **et**
  `auto_advance: false`. Vérifier par lecture, ne pas chercher à corriger.
- Arbre de travail **propre côté fichiers suivis**. Untracked pré-existants, **étrangers à cette
  mission**, à ne pas commiter : `.gsd/`, `.planning/MISSION-30.dag.json`,
  `.planning/phases/VFDO-36-cockpit-v1-1-signal-au-travail-fiable-et-am-liorations-ux/`.
- Sources de cadrage déjà localisées (gain de temps direct pour `discuss`) :
  - `.planning/ROADMAP.md` **lignes 597-623** — Phase 31 : goal, dépendance à la Phase 30, 4 critères
    de succès, transverse QUAL-01.
  - `.planning/research/ARCHITECTURE.md` **§3.1 (lignes 76-95)** — emplacement du manifeste, écrivain
    unique (`install_module`), les 4 lecteurs (`update_module`, `uninstall_module`, `--dry-run`,
    validator plus tard), et ce que le manifeste **ne remplace pas** (`.vibeflow-installed`,
    fragment `hooks.json`). **Ligne 65** — table composants modifiés/nouveaux, dont la suite
    `test-manifest.sh` attendue dans `_internal/tests/`. **Ligne 181** — rationale d'ordonnancement.
    **Lignes 190-203** — anti-patterns du repo à ne pas commettre. **Lignes 209-210** — flux avant/après.
  - `gh issue view 20` — demande terrain (revue croisée des hooks à 2 sous Windows), état vérifié au
    2026-07-22, et le **format de sortie proposé par l'auteur** (`[plan] + <chemin> (module vX)`,
    `[plan] ~ .claude/settings.json hooks.PreToolUse += … (matcher: Read)`).
  - `.planning/REQUIREMENTS.md` — MANI-01..04 + les deux risques encodés : « dry-run en chemin de
    code séparé » et « suppression silencieuse de fichiers modifiés ».

## 6. Fichiers non commités laissés sur disque

Aucun état incohérent. Deux artefacts de pilotage, **volontairement non commités** (la mission n'a
jamais créé sa branche de phase, et la doctrine interdit de commiter sur `main`) :

- `.planning/MISSION-31.dag.json`
- `.planning/phases/VFDO-31-manifeste-d-install-dry-run-issue-20/31-PAUSE-HANDOFF.md` (ce fichier)
- `.planning/phases/VFDO-31-manifeste-d-install-dry-run-issue-20/31-RECHERCHE-moteur.md`

## 7. Prochain geste exact à la reprise

1. `bash plugin/conductor/scripts/driver-lock.sh acquire --owner=<nouvel-id> --step=cadrage`
   (le lock a été relâché proprement — l'acquisition doit rendre `acquired:true`, sans `recovered`).
2. Lire `31-RECHERCHE-moteur.md` (le nœud `rech-moteur` est `done`, **ne pas le re-dispatcher**).
3. Écrire `31-CONTEXT.md` (nœud `discuss`, seul nœud `ready`) — geste du manager, en mode nocturne =
   tout arbitrage tranché en Claude's Discretion **documenté avec son motif**, jamais
   d'`AskUserQuestion`. Trancher au minimum : le format de sortie du `--dry-run` (l'issue #20 en
   propose un, l'engine n'a pas de convention `[plan]`), le traitement des écritures **indirectes**
   par sous-processus, la source du manifeste face aux trois énumérations parallèles, et le sort du
   compteur de suites non gaté (§2, point 3).
4. Poursuivre le DAG.

**Gates humains toujours en attente (rien n'a été consommé cette nuit)** : PR, merge, release racine
= interdits · commentaire de livraison + close de l'issue #20 = draft sur disque uniquement · push de
la branche de phase pour preuve CI = autorisé (même gate que la Phase 30).
