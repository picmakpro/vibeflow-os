# Phase 30 : Portabilité Windows II — Recherche

**Recherché le :** 2026-08-15
**Domaine :** Substrat de hooks Claude Code (forme exec vs shell), codes de sortie, moteur d'install bash (`merge-hooks.sh`), veille npm/RFC upstream
**Confiance :** HIGH (le cœur de la recherche est fondé sur lecture directe du code source du dépôt + documentation officielle Claude Code ; deux points restent LOW, voir Assumptions Log)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (PORT-04 tranché) :** La Phase 30 porte l'intégralité du volet `merge-hooks.sh` —
  apprentissage d'`args` (substitution, `frag_basenames()`, `references()`, `remove`) ET
  résolution du chemin absolu de `bash` à l'install. Décision prise unilatéralement par Samuel le
  2026-08-15 (le tracer 01-01 de Willy n'a jamais été livré). Reversibility : one-way — le
  `settings.json` produit devient spécifique à la machine.
- **D-02 :** Exit code de `vf_guard_unavailable` sur `PreToolUse` : **non nul ≠ 2** (« dégradé mais
  utilisable », aligné ADR-031).
- **D-03 :** Documentation de PORT-04 : amendement de la spec (§3.2, fait) + commentaire
  informatif sur la PR #29 (geste externe gaté humain, pas encore posté).
- **D-04 :** La Phase 30 écrit elle-même `vf-portable.sh` (`plugin/_internal/lib/`) et
  `copy_engine_lib()` dans `vibeflow-update.sh`, en conformité stricte avec le contrat d'interface
  de la PR #29 (5 symboles, bloc localisateur à 4 candidats, sémantique `vf_py_probe`). Absorbe le
  tracer 01-01. Reversibility : costly — si le contrat PR #29 évolue avant merge, lib et
  consommateurs doivent être réalignés.
- **D-05 :** La dépendance dure de `guard-file-size.sh` au hook doctor de `conductor` (agrégation
  `$VF_GUARD_HEALTH_DIR` + escalade après 3 sessions, contrat §4) est **levée pour la lib et
  `vf_guard_unavailable`**. Le hook doctor lui-même : version minimale (agrégation en une ligne au
  SessionStart) OU différé avec reliquat tracé — au choix du planner sur pièces.
- **D-06 :** Traduction vers le harness : **normalisation dans chaque script** (0 = cas silencieux,
  non nul = vraie erreur) — **pas de lanceur `run-hook.sh`**. Le contrat interne exit 3 (Phase 17)
  reste valide *à l'intérieur* des scripts ; c'est la sortie vers le harness qui devient 0.
- **D-07 :** Périmètre de la normalisation des codes de sortie : **tout le parc — les 25 entrées
  réelles** (gouvernance incluse), même si seules les entrées dev passent en forme exec dans cette
  phase.
- **D-08 :** Écart d'inventaire (19 roadmap / 22 spec / **25 réelles constatées au cadrage** :
  conductor 6, consolidator 7, dev-orchestrator 4, infrastructure-audit 1, planning-core 6,
  software-architecture 1) : **l'inventaire du plan fait foi** — recompter, documenter
  événement + classement advisory/bloquant par entrée, mettre à jour les chiffres de la spec.
- **D-09 :** RFC upstream `open-gsd/gsd-core` : **draft produit par le plan, validé par Samuel
  avant tout post public** (issue GitHub). Deadline amont : 2026-10-26.
- **D-10 :** Veille gsd-core > 1.10.0 : **hook SessionStart advisory avec cache quotidien**
  (`npm view @opengsd/gsd-core version`, jamais le dist-tag `next`). Préciser au plan si le hook
  est repo-local (`.claude/` de ce repo) ou distribué — repo-local suffit, la Phase 35 concerne ce
  repo.
- **D-11 :** Traçabilité de la RFC : lien de l'issue upstream écrit dans **STATE.md (décision
  datée) + ligne LEDG-03 de REQUIREMENTS.md**.

### Claude's Discretion

- Séquencement fin des vagues (a) moteur → (b) codes de sortie → (c) hooks.json — l'ordre est
  imposé par la spec §2, le découpage en plans est libre.
- Détail d'implémentation de la veille (format du cache, emplacement du script).
- Extension des suites de tests (mutations discriminantes, sonde de parc §4 de la spec).

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. Les 14 fichiers PYBIN gouvernance, le volet Python de
`merge-hooks.sh`/`preflight.sh` (au sens résolution d'interpréteur — absorbé par D-04 côté lib) et
les 20 entrées hooks gouvernance restent à Willy pour leur **migration effective** (leur
normalisation de code de sortie interne, elle, est dans le périmètre D-07).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PORT-01 | Les 3 fichiers du lot PYBIN passent par `vf-portable.sh` (contrat PR #29 consommé) | §Contrat PR #29 lu en entier depuis la branche ; §`copy_engine_lib()` — point d'ancrage exact dans `vibeflow-update.sh` ; §Variantes A/B mesurées fichier par fichier |
| PORT-02 | `merge-hooks.sh` apprend `args` AVANT toute migration de fragments | §Anatomie de `merge-hooks.sh` (fonctions, lignes exactes) ; §Pattern de test T7 (dédup cross-matcher) à étendre en cross-forme |
| PORT-03 | Contrat de codes de sortie normalisé, inventaire réalisé | §Inventaire des 25 entrées (vérifié fichier par fichier) ; §Le vrai mécanisme de normalisation (traduction `--hook`, pas un renommage global d'`exit 3`) ; §Sémantique exacte des exit codes par événement (doc officielle) |
| PORT-04 | Affectation §3.2 tranchée et documentée avant le plan | Déjà satisfait — voir D-01. Le ROADMAP.md (ligne 536-539) affiche encore l'ancien pré-requis bloquant « à trancher avec Willy » : **texte périmé**, la CONTEXT.md fait foi |
| PORT-05 | Portabilité prouvée en CI sur lab frais | §CI existante (`.github/workflows/ci.yml`) : aucun runner Windows réel, tout tourne sur `ubuntu-latest` — les suites `windows-crlf`/`windows-guards` simulent Windows sans poste Windows ; §pattern `lab-frais`/`lab-frais-arme` (Phase 28) directement réutilisable |
| LEDG-03 | RFC upstream ouverte dès le jour 1 | §Traçabilité STATE.md/REQUIREMENTS.md déjà cadrée par D-11 ; aucune recherche technique nécessaire au-delà du protocole GitHub `gh issue create` |
| WKTR-03 | Veille de release gsd-core active dès le jour 1 | §Pattern `check-plugin-update.sh` + `update-banner.sh` — cache + refresh async + lecture au SessionStart suivant, directement transposable à `npm view` |
| QUAL-01 (transverse) | Tout gate né dans la phase a ses 3 issues (PASS/FAIL/imparsable BRUYANT) + mutation rouge prouvée | §Grammaire d'exit déjà en vigueur dans le dépôt (0/3/64) — voir §Common Pitfalls et §Code Examples |
</phase_requirements>

## Summary

Cette phase réécrit le substrat des hooks Claude Code du périmètre dev (2 `hooks.json`, 4 entrées
réelles) en forme **exec**, normalise les codes de sortie de l'ensemble du parc (25 entrées
mesurées), et écrit la lib partagée `vf-portable.sh` conformément au contrat déjà figé sur la PR
#29 (lue intégralement depuis la branche `gouvernance/contrat-portabilite`, 173 lignes). Les trois
verrous techniques identifiés par la spec (`docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md`)
sont vérifiés sur le code réel de `plugin/_internal/merge-hooks.sh` : la substitution
`{{VF_SCRIPTS}}` ne lit que `command` (l.167), `frag_basenames()`/`references()` n'inspectent que
`command` (l.106-131), et le mode `remove` échoue sur un fragment sans script détecté dans
`command` (l.181-183) — les trois doivent apprendre à lire `args` avant que le moindre
`hooks.json` ne passe en forme exec, sous peine de placeholder écrit littéralement, hook doublé, ou
module non désinstallable sur tout le parc installé (pas seulement les labs touchés par cette
phase).

La documentation officielle Claude Code, récupérée directement (`code.claude.com/docs/en/hooks`),
confirme un point structurant que la spec anticipait sans le vérifier : en forme exec, `command`
**est résolu sur le PATH**, exactement comme en forme shell — ce n'est donc **pas** un raffinement
que d'exiger un chemin absolu vers `bash` résolu à l'install (exigence §5 du contrat PR #29), c'est
la seule façon d'éviter de reproduire le bug ADR-054 (un `bash` nu peut résoudre vers le mauvais
binaire, ou aucun, selon le PATH Windows au moment du hook). La doc confirme aussi la sémantique
exacte des exit codes par événement : `PreToolUse`/`Stop`/`UserPromptSubmit` peuvent bloquer sur
exit 2, `SessionStart`/`PostToolUse` ne bloquent jamais mais un exit non-zéro **autre que 2**
déclenche un « hook error notice » visible par l'utilisateur — c'est exactement le défaut que
`|| true` masquait et que la migration doit combler avant de le retirer.

Un examen ligne à ligne des 4 scripts `SessionStart` de `dev-orchestrator` révèle le vrai
mécanisme attendu par D-06 : ces scripts appliquent déjà une convention `exit 3` = silence /
`exit 0` = signal / `exit 64` = erreur d'argument, et le flag `--hook` existe déjà dans les
quatre — mais son en-tête documente explicitement (`check-dev-bootstrap.sh:45-51`) qu'il **ne
change rien** aux codes de sortie aujourd'hui, car `|| true` absorbe tout. La normalisation
demandée par PORT-03 n'est donc pas un renommage global d'`exit 3` en `exit 0` : c'est
l'introduction d'une traduction *propre au mode `--hook`* qui n'existe pas encore, et qui doit
remplacer une phrase de doc aujourd'hui fausse pour ce nouveau contrat.

**Recommandation principale :** traiter la normalisation des codes de sortie comme une opération
« ajouter un point de traduction unique en fin de script, activé uniquement quand `--hook` est
posé », jamais comme un remplacement textuel `exit 3` → `exit 0` (qui casserait la CLI et les
suites de tests existantes, qui appellent ces scripts sans `--hook` et attendent l'exit 3
documenté).

## Architectural Responsibility Map

> Ce dépôt n'est pas une application web à tiers Browser/API/DB : c'est un plugin Claude Code
> distribué en bash. La table ci-dessous adapte donc les tiers standard aux tiers réels du dépôt.

| Capability | Tier propriétaire | Tier secondaire | Rationale |
|------------|-------------------|-----------------|-----------|
| Résolution Python (`vf-portable.sh`) | Moteur d'install (`plugin/_internal/lib/`) | Scripts consommateurs (dev + gouvernance) | Contrat PR #29 : possédée par l'engine, jamais par un module — sinon elle disparaît à la désinstallation du module qui l'a portée |
| Forme exec des hooks (`merge-hooks.sh`) | Moteur d'install (`plugin/_internal/`) | Fragments `hooks/hooks.json` par module | Le moteur DOIT apprendre `args` avant que le moindre fragment ne migre (§1.3 spec, vérifié sur le code) |
| Codes de sortie normalisés | Scripts de hooks individuels (chaque module) | Runtime harness Claude Code | Pas de lanceur centralisateur (D-06) — la traduction vit dans chaque script, au point d'entrée `--hook` |
| Classement advisory/bloquant | `hooks/hooks.json` de chaque module (déclaratif) + doc du script | — | Le contrat exige un classement EXPLICITE par entrée, pas déduit |
| Veille gsd-core (WKTR-03) | Hook SessionStart repo-local (`.claude/` du dépôt lui-même) | Cache `~/.cache/vibeflow/` (précédent `check-plugin-update.sh`) | Repo-local suffit : la Phase 35 (consommatrice) ne concerne que ce repo, jamais un lab tiers |
| RFC upstream (LEDG-03) | Geste humain gaté (`gh issue create` sur draft validé) | STATE.md + REQUIREMENTS.md (traçabilité) | Aucune brique technique — un draft + une trace, pas un artefact de code |
| CI de preuve (PORT-05) | `.github/workflows/ci.yml`, job `tests` (découverte auto `*/tests/test-*.sh`) | Job `lab-frais`/`lab-frais-arme` (pattern Phase 28) | Aucun runner Windows n'existe dans ce dépôt — la preuve passe par simulation (fixtures antislashs, stub WindowsApps), jamais par un OS réel |

## Standard Stack

### Core

Aucune nouvelle dépendance externe (npm, pip, cargo) n'est introduite par cette phase — c'est du
bash/Python stdlib pur, cohérent avec le reste du dépôt.

| Outil | Version | Rôle | Pourquoi standard ici |
|-------|---------|------|------------------------|
| bash | ≥ 3.2 (macOS) / Git Bash (Windows) | Runtime des scripts de hooks et du moteur | Convention du dépôt entière, `BASH_BIN` surchargeable dans les tests |
| python3 | ≥ 3.x, résolu par la cascade `vf_python` | Manipulation JSON fiable dans `merge-hooks.sh` et les guards | Déjà la convention ADR-054 ; la lib `vf-portable.sh` centralise la cascade |
| jq | tout | Utilisé par `resolve-deps.sh`, `kpi-analyst`, `installer` (hors périmètre direct de cette phase) | `jqx()` wrapper CRLF déjà en place, non touché ici (0 occurrence côté dev) |

**Installation :** rien à installer — aucun `npm install`/`pip install` requis pour cette phase.

### Package Legitimacy Audit

**N/A — aucun package externe n'est introduit par cette phase.** Tout le travail porte sur du bash
et du Python stdlib déjà présents dans l'environnement d'exécution du harness Claude Code. Le
protocole de vérification de légitimité de paquet ne s'applique pas.

## Architecture Patterns

### Diagramme — flux de merge-hooks.sh (état cible, forme exec apprise)

```
                    ┌─────────────────────────────┐
                    │  hooks/hooks.json (module)   │
                    │  forme shell OU forme exec    │
                    └──────────────┬────────────────┘
                                   │  merge-hooks.sh merge <fragment>
                                   ▼
                    ┌─────────────────────────────────────┐
                    │ frag_basenames()                      │
                    │  lit command  (forme shell)            │
                    │  lit args[]   (forme exec — À AJOUTER) │
                    └──────────────┬────────────────────────┘
                                   ▼
                    ┌─────────────────────────────────────┐
                    │ Pour chaque hook du fragment :         │
                    │  1. substitution {{VF_SCRIPTS}}        │
                    │     → dans command (déjà fait)         │
                    │     → dans CHAQUE élément d'args        │
                    │       (À AJOUTER, sinon placeholder     │
                    │        écrit littéralement)             │
                    │  2. own = scripts référencés            │
                    │     (command ∪ args, pas command seul)  │
                    │  3. dédup : purge toute entrée existante │
                    │     référençant les mêmes scripts,       │
                    │     QUELLE QUE SOIT SA FORME             │
                    │     (shell OU exec — dédup cross-forme)  │
                    └──────────────┬────────────────────────┘
                                   ▼
                    ┌─────────────────────────────────────┐
                    │ settings.json de l'utilisateur          │
                    │  (mélange possible shell + exec          │
                    │   pendant la période de transition)      │
                    └─────────────────────────────────────────┘

Mode remove : basenames = frag_basenames() lit command+args
              → si un fragment n'a QUE des entrées exec et que
                args n'est pas lu, basenames est vide
                → die("fragment sans script référencé") (l.182-183)
                → LE MODULE DEVIENT NON DÉSINSTALLABLE (effet #1.3
                  déjà vérifié dans le code actuel)
```

### Diagramme — traduction du code de sortie vers le harness (D-06)

```
Script de hook (ex. check-dev-bootstrap.sh), invoqué avec --hook :

  logique interne (états 0/1/2/3, EXIT_CODE local)
        │
        ▼
  ┌──────────────────────────────────────────┐
  │  AUJOURD'HUI (forme shell, || true) :      │
  │  exit $EXIT_CODE  →  shell avale tout      │
  │  → process réel toujours 0 côté harness    │
  └──────────────────────────────────────────┘
        │  migration forme exec : || true DISPARAÎT
        ▼
  ┌──────────────────────────────────────────┐
  │  CIBLE (D-06) : traduction AVANT le exit    │
  │    final, seulement si --hook est posé :    │
  │    EXIT_CODE=3 (silence)     → exit 0        │
  │    EXIT_CODE=0 (signal émis) → exit 0        │
  │       (déjà 0, inchangé)                     │
  │    EXIT_CODE=64 (arg invalide) → cas hors     │
  │       hook — n'arrive jamais via hooks.json,   │
  │       le harness n'invoque jamais avec un      │
  │       argument inconnu                          │
  │  SANS --hook (CLI, tests) : exit $EXIT_CODE     │
  │    inchangé (3 reste 3) — compat CLI/tests       │
  └──────────────────────────────────────────┘
```

### Pattern : cascade de résolution Python (`vf_python`, fonction pas variable)

**Ce qu'il faut retenir avant d'implémenter `vf-portable.sh` :** le contrat (PR #29,
`docs/CONTRAT-PORTABILITE.md`, lu intégralement depuis
`origin/gouvernance/contrat-portabilite`) impose que `vf_python` soit une **fonction**, pas une
variable `PYBIN=`, précisément pour porter un futur barreau `py -3` (lanceur à argument, que
`"$PYBIN" -c ...` ne peut pas exprimer si `PYBIN="py -3"`).

```sh
# Source : docs/CONTRAT-PORTABILITE.md (PR #29, branche gouvernance/contrat-portabilite) §2
# 5 symboles exposés :
#   vf_resolve_python   — résout un interpréteur utilisable (cascade python3 → python → py -3)
#   vf_python <args…>   — INVOQUE l'interpréteur résolu (fonction, pas variable)
#   vf_py_probe <cand>  — sonde : présent, pas *WindowsApps*, s'exécute (timeout sous Windows), Python 3
#   jqx <args…>         — command jq "$@" | tr -d '\r'  (déjà en place ailleurs, pattern connu)
#   vf_guard_unavailable <script> <motif>  — écrit le marqueur de garde inexécutable
# IS_WINDOWS portée par la lib — NE PAS la redéfinir localement (casse sous `set -u`).
```

Le bloc localisateur (4 candidats, entre marqueurs `# >>> vf-portable:locator` /
`# <<< vf-portable:locator`) doit être reproduit **à l'identique** dans les 3 fichiers PYBIN — seul
le préfixe de message varie. Le gate amont (pas encore écrit, `check-portable-resolution.sh`,
absent du dépôt à ce jour — vérifié par recherche `find`) compare des sommes de contrôle du bloc
extrait entre marqueurs : toute dérive de copier-coller est détectée machine, pas par relecture.

**Point d'ancrage exact pour `copy_engine_lib()`** — `plugin/_internal/vibeflow-update.sh` :
`copy_module_scripts()` (l.343-367) est le patron direct à suivre — copie flat vers
`$TARGET_ROOT/scripts/`, `chmod +x` pour les exécutables (pas pour `vf-portable.sh`, qui n'est
QUE sourcée, jamais exécutée seule). Le candidat 1 du bloc localisateur
(`$(dirname "$0")/vf-portable.sh` → install à plat) implique que `copy_engine_lib()` doit poser le
fichier directement dans `$TARGET_ROOT/scripts/vf-portable.sh` (flat, pas dans un sous-dossier
`lib/`) — cohérent avec le fait que tous les scripts de module finissent eux-mêmes à plat dans
`$TARGET_ROOT/scripts/` après install. `copy_engine_lib()` doit être appelée **une seule fois**
(pas par module, contrairement à `copy_module_scripts`), probablement au même niveau que
`find_hooks_merger()`/`find_mcp_injector()` (l.252-270 de la version actuelle, patron identique de
résolution en cascade cache → dépôt → voisin du script).

### Pattern réutilisable — veille avec cache quotidien + refresh async (WKTR-03)

Le dépôt porte déjà EXACTEMENT ce pattern pour la veille de version du plugin lui-même —
`plugin/conductor/scripts/check-plugin-update.sh` (95 lignes, lu intégralement) +
`plugin/conductor/scripts/update-banner.sh` (69 lignes, lu intégralement) :

```
[verrou mkdir atomique, périmé après 300s] check-plugin-update.sh
  → résout la version installée (JSON structuré, fallback CLI)
  → git ls-remote --tags (réseau KO = cache PAS réécrit, ancien état gardé)
  → écrit un cache JSON atomique (tmp + mv) : {update_available, installed, latest, checked_at}

update-banner.sh (SessionStart, synchrone, RAPIDE)
  → LIT le cache écrit par la session précédente (jamais de réseau synchrone)
  → émet UN systemMessage fusionné si quelque chose à dire, sinon rien
  → relance check-plugin-update.sh en ARRIÈRE-PLAN (setsid si dispo, sinon `( … & )`)
    → rafraîchit le cache pour la PROCHAINE session, jamais celle-ci
  → exit 0 toujours
```

**Écart à introduire pour WKTR-03 (« cache quotidien ») :** `check-plugin-update.sh` se relance à
CHAQUE session (peu coûteux : un seul `ls-remote`). WKTR-03 exige explicitement un cache
**quotidien**, pas par-session — combiner ce pattern avec le gate `--if-older-than=Nd` de
`plugin/infrastructure-audit/scripts/audit-infra.sh` (l.53, l.74-75 : parse `${IF_OLDER_THAN%d}`
en jours, compare au timestamp du dernier stamp/snapshot, skip silencieux si trop récent). Le
script de veille gsd-core doit gater son propre refresh réseau par ce même mécanisme avant
d'appeler `npm view @opengsd/gsd-core version` — **jamais le dist-tag `next`** (D-10, vérifié
formulé deux fois dans REQUIREMENTS.md et ROADMAP.md).

### Anti-Patterns à éviter

- **Renommer globalement `exit 3` en `exit 0` dans les 4 scripts dev-orchestrator.** Casserait la
  CLI (`gsd-progress` ou tout appelant manuel qui teste `rc=3` pour « rien à signaler ») et les
  suites de tests existantes qui assertent explicitement `rc=3`. La traduction doit être
  conditionnée au mode `--hook`.
- **Un lanceur `run-hook.sh` centralisé.** Explicitement rejeté par D-06 : réintroduirait une
  indirection shell sous Windows, contredisant l'objectif même de la forme exec.
- **Lire `command` seul dans `frag_basenames()`/`references()` après la migration.** C'est
  précisément le défaut §1.3 déjà vérifié dans le code actuel (l.106-131) — la régression
  spécifique que le test de dédup cross-forme (à écrire) doit prouver rouge sous mutation.
- **Un `bash` nu comme `command` en forme exec.** La doc officielle confirme que `command` est
  résolu sur le PATH même en forme exec — reproduirait EXACTEMENT le bug ADR-054 (stub Microsoft
  Store, ou absence pure de `bash` du PATH Windows, cause racine #8 du rapport terrain 2026-07-23).

## Don't Hand-Roll

| Problème | Ne pas construire | Utiliser à la place | Pourquoi |
|----------|--------------------|-----------------------|----------|
| Cascade de résolution Python multi-plateforme | Une nouvelle variante locale par script | `vf-portable.sh` (contrat PR #29, déjà figé) | 3 défauts déjà documentés (ADR-054) viennent tous d'une logique recopiée au lieu de partagée — la 4e recopie serait la même dette |
| Détection de nouvelle version npm | Un client HTTP registry maison | `npm view <pkg> version` (le seul outil déjà utilisé et testé dans ce dépôt pour ce genre de sonde) | Le registre npm gère déjà les dist-tags, semver, cache HTTP — écrire un parseur maison réinvente `npm view` moins bien |
| Cache avec expiration | Un timestamp fait main sans verrou | Le patron `check-plugin-update.sh` (verrou `mkdir`, écriture atomique tmp+mv, cache non réécrit si réseau KO) | Patron déjà éprouvé en production sur ce dépôt, gère la concurrence multi-session |
| Comparaison sémantique de versions | Un parseur semver maison | `sort -V` (déjà le choix du dépôt dans `check-plugin-update.sh:82` et `infrastructure-audit`) | Portable, déjà testé, évite les pièges classiques (1.9.0 < 1.10.0 en tri lexical naïf — piège déjà documenté dans STATE.md : « 1.8.0 < 1.42.3 en semver ») |

**Insight clé :** ce dépôt a déjà, en production, la quasi-totalité des briques nécessaires à
WKTR-03 (cache + verrou + refresh async) — le travail réel de cette exigence est une **adaptation**
d'un pattern existant (ajouter le gate `--if-older-than`), pas une construction depuis zéro.

## Runtime State Inventory

> Cette phase touche le `settings.json` de **tout lab installé** (effet de bord assumé D-01) —
> c'est un changement de forme qui affecte l'état vivant chez les utilisateurs, au sens propre du
> mot « migration ». Inventaire des 5 catégories :

| Catégorie | Éléments trouvés | Action requise |
|-----------|-------------------|------------------|
| Données stockées | Le `settings.json` de chaque lab installé porte les entrées hooks en **forme shell** aujourd'hui (vérifié : les 6 `hooks.json` du dépôt source sont tous 100% forme shell, aucune occurrence d'`args` trouvée par lecture complète des 6 fichiers) | Migration de forme, pas de données — mais le moteur DOIT savoir lire/dédupliquer/retirer l'ancienne forme AUSSI LONGTEMPS que des labs ne sont pas passés par un `update` post-Phase-30 (compatibilité descendante non négociable, déjà notée dans CONTEXT.md) |
| Config de service live | Aucune — pas de service externe (n8n, Datadog…) concerné par cette phase | Aucune |
| État enregistré OS | Aucun marqueur `$VF_GUARD_HEALTH_DIR` n'existe encore sur disque (grep confirmé : 0 occurrence dans tout `plugin/`) — c'est un NOUVEAU mécanisme introduit par cette phase, pas une migration d'existant | Aucune migration ; la Phase 30 est la première à écrire ce répertoire |
| Secrets / env vars | Aucun secret nommé par cette phase (bash/Python purs, pas de credential) | Aucune |
| Artefacts de build / packages installés | `plugin/_internal/lib/` n'existe pas encore sur disque (vérifié `ls`) — `copy_engine_lib()` n'existe pas encore dans `vibeflow-update.sh` (grep confirmé : 0 occurrence) | Un lab qui a déjà installé un module AVANT cette phase n'a PAS `vf-portable.sh` dans son `$TARGET_ROOT/scripts/` — le premier `update` post-Phase-30 doit le poser, sinon les 3 fichiers PYBIN cassent leur `source` sur les labs existants au premier appel |

**Question de séquencement pour le plan (pas encore tranchée par CONTEXT.md) :** un lab existant
qui n'a PAS encore fait d'`update` après cette phase garde des hooks en forme shell dans son
`settings.json` — c'est acceptable et couvert par la compatibilité descendante. Mais si le module
`software-architecture` ou `dev-orchestrator` bump sa version SANS que l'utilisateur relance
`update`, `guard-file-size.sh` (déjà sur disque, ancienne version, forme locale de résolution
Python) continue de tourner tel quel jusqu'au prochain `update` — comportement attendu, pas une
régression, mais à documenter explicitement dans le CHANGELOG du module pour éviter la confusion
« pourquoi mon guard ne bloque toujours pas en absence de Python ».

## Common Pitfalls

### Pitfall 1 : confondre « exit 3 partout » avec la normalisation demandée par D-06

**Ce qui cloche :** un plan naïf pourrait lire PORT-03 comme « remplacer tous les `exit 3` par
`exit 0` dans les scripts de hooks ». C'est faux et casserait la CLI.

**Pourquoi ça arrive :** l'en-tête de `check-dev-bootstrap.sh` (l.14) dit littéralement : « rupture
assumée de la convention "exit 3 ⇔ silence" » pour un cas précis (état 3, orientation
`[gsd-engine]`) — un lecteur pressé peut généraliser à tort.

**Comment l'éviter :** le point de traduction doit être conditionné au flag `--hook`, exactement
comme `--quiet` change déjà le comportement de `say()`. Citation vérifiée
(`check-dev-bootstrap.sh:45-51`) :
> « `--hook` est accepté pour la PARITÉ D'INTERFACE avec les autres scripts de la phase, et il
> arme le gate de mutuelle exclusion avec `--quiet`. Il ne change NI les 4 exits, NI le rendu […]
> Rendre stdout dépendant du drapeau serait un changement de contrat, pas une correction : c'est la
> DOCUMENTATION qui était fausse. »

Cette phrase devient **fausse par construction** dès que `|| true` disparaît — le plan doit
prévoir la mise à jour de ce commentaire dans les 4 scripts en même temps que le comportement
change (`check-dev-bootstrap.sh`, `discover-unintegrated-docs.sh`, `check-doc-drift.sh`,
`check-gsd-config.sh` — les 4 partagent la même formulation, vérifiée par grep).

**Signes avant-coureurs :** un test qui vérifie `rc=3` en appelant le script SANS `--hook` doit
rester vert après le changement — s'il rougit, la normalisation a été faite au mauvais niveau
(global au lieu de conditionné à `--hook`).

### Pitfall 2 : stdout non vide sur le chemin « silencieux » de `SessionStart`

**Ce qui cloche :** la doc officielle confirme (fetch direct) que pour `SessionStart`, contrairement
à la plupart des événements, le stdout sur exit 0 **est montré à Claude comme contexte** (pas
seulement journalisé en debug). Un script qui écrit quoi que ce soit sur stdout — même une ligne
vide accidentelle, même un warning Python non redirigé vers stderr — rompt le silence promis par
PORT-03 même si l'exit code est 0.

**Pourquoi ça arrive :** aujourd'hui `|| true` masque tout, donc personne n'a eu besoin de garantir
que le chemin silencieux (`say()` écrit sur **stderr**, jamais stdout) est réellement propre en
sortie process. Le contrat va changer de nature : ce n'était qu'un problème d'exit code, ça devient
aussi un problème de flux.

**Comment l'éviter :** le test de non-régression §1.4 (« démarrage silencieux ») doit capturer
stdout ET stderr séparément, pas juste le code de sortie, et asserter stdout vide sur le chemin
« rien à signaler ».

**Signes avant-coureurs :** un message diagnostique Python (traceback partiel, warning de
dépréciation) qui fuiterait sur stdout au lieu de stderr apparaîtrait comme un message de contexte
à Claude à CHAQUE session — bruit permanent, difficile à distinguer d'un vrai signal.

### Pitfall 3 : `guard-file-size.sh` n'a pas la même architecture de résolution que `merge-hooks.sh`

**Ce qui cloche :** le spec §1.1 classe `guard-file-size.sh` en « variante A — bloc complet, avec
neutralisation WindowsApps » comme les 14 fichiers gouvernance. Lecture directe du fichier
(l.37-43) montre que ce n'est **pas** le même bloc complet à 4 candidats + `timeout` +
`PY3_PROBE` que `merge-hooks.sh` (l.54-71) — c'est une version allégée : détection par CHEMIN
seule (`case "$(command -v python3)" in ''|*WindowsApps*)`), sans sonde d'exécution réelle
(`timeout … -c "$PY3_PROBE"`), héritée de l'amendement ADR-054 point 3 (« résolution runtime,
zéro spawn ajouté »).

**Pourquoi ça arrive :** la spec et le contrat parlent de « variante A » comme d'un bloc unique,
mais il existe en réalité deux formes de variante A dans le dépôt — la forme complète (install-time,
`merge-hooks.sh`, `preflight.sh`) et la forme allégée (runtime hooks, `guard-file-size.sh`, les
guards `consolidator`). Migrer `guard-file-size.sh` vers `vf_python`/`vf_py_probe` change donc
potentiellement son profil de coût (spawn `timeout` supplémentaire à chaque `Edit`/`Write`) si la
lib n'expose pas les deux profils.

**Comment l'éviter :** vérifier au plan si `vf_py_probe` (contrat PR #29 §2) est conçu pour être
appelé UNE FOIS par session (comme `probe-memory-guards.sh`) ou À CHAQUE invocation du guard — le
guard `PreToolUse` tourne à CHAQUE `Edit`/`Write`, un spawn `timeout` par appel serait un
changement de latence perceptible, contrairement au SessionStart qui tourne une fois.

**Signes avant-coureurs :** un ralentissement mesurable des opérations `Edit`/`Write` après
migration serait le signal que `vf_py_probe` a été branché sans respecter le profil « zéro spawn
ajouté » qui avait motivé l'amendement ADR-054 point 3 pour ce fichier précis.

### Pitfall 4 : le classement advisory/bloquant n'est pas déductible mécaniquement de l'événement

**Ce qui cloche :** on pourrait supposer « SessionStart = toujours advisory, PreToolUse = toujours
bloquant » — faux dans les deux sens possibles. `guard-file-size.sh` (`PreToolUse`) bloque
aujourd'hui via **JSON** (`permissionDecision: deny`) et pas via exit code (le script sort
toujours 0, même sur deny — vérifié l.117-127) ; son classement « bloquant » tient à sa décision
JSON, pas à son exit code. Les 4 entrées `SessionStart` de `dev-orchestrator` sont, elles,
uniformément advisory par construction ADR-031 — mais ce n'est pas garanti pour toutes les futures
entrées `SessionStart` du parc gouvernance (25 entrées au total, D-07).

**Comment l'éviter :** PORT-03 exige un classement EXPLICITE par entrée (contrat §7 : « classer
chaque entrée advisory ou bloquante ») — traiter chacune des 25 entrées individuellement, jamais
par event-type par défaut.

## Code Examples

### Le contrat de résolution Python actuel dans `merge-hooks.sh` (à porter dans `vf_resolve_python`)

```bash
# Source : plugin/_internal/merge-hooks.sh:54-71 (lu intégralement — VERIFIED)
# Résolution d'interpréteur Python (ADR-054) : sous Windows, le `python3` du PATH peut être le
# stub Microsoft Store (App Execution Alias : `command -v` réussit mais l'exécution pend/échoue
# en non-TTY) et l'installeur python.org ne fournit QUE `python.exe` (pas de `python3.exe`).
PYBIN=""
PY3_PROBE='import sys; sys.exit(0 if sys.version_info[0]>=3 else 1)'
for cand in python3 python; do
  command -v "$cand" >/dev/null 2>&1 || continue
  case "$(command -v "$cand" 2>/dev/null)" in *WindowsApps*) continue ;; esac
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || continue
  else
    "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || continue
  fi
  PYBIN="$cand"; break
done
[ -n "$PYBIN" ] || err "python3 requis […]"
```

Ce bloc EST la variante A complète que `vf_resolve_python`/`vf_py_probe` doivent reproduire —
c'est la version la plus rigoureuse déjà en production dans le dépôt (avec `timeout`, contrairement
à `guard-file-size.sh`, voir Pitfall 3).

### Le point exact où `frag_basenames()` doit apprendre `args`

```python
# Source : plugin/_internal/merge-hooks.sh:106-115 (lu intégralement — VERIFIED)
SCRIPT_RE = re.compile(r"([A-Za-z0-9._-]+\.(?:sh|py))")

def frag_basenames():
    """Basenames de tous les scripts référencés par les commands du fragment."""
    names = set()
    for groups in frag_hooks.values():
        for g in groups or []:
            for h in g.get("hooks", []) or []:
                names.update(SCRIPT_RE.findall(h.get("command", "")))
                # AJOUT REQUIS : parcourir aussi h.get("args", []) et appliquer SCRIPT_RE
                # à chaque élément — sinon un fragment 100% forme exec ne référence AUCUN
                # basename, et le mode `remove` meurt sur "fragment sans script référencé"
                # (l.182-183, déjà vérifié dans le code actuel).
    return names
```

Le même schéma s'applique à `references()` (l.117-131) — la frontière par lookaround négatif
(`(?<![A-Za-z0-9._-])…(?![A-Za-z0-9._-])`) doit être appliquée à chaque élément d'`args`
individuellement (chaque élément est un token complet en forme exec, contrairement à `command` qui
est une chaîne à parser), donc potentiellement plus simple : un élément d'`args` qui EST le nom du
script peut être comparé par égalité de basename plutôt que par regex de sous-chaîne — à trancher
au plan selon que `args` peut aussi contenir des flags (ex. `--hook`) qui ne doivent jamais matcher
`SCRIPT_RE`.

### Forme exec attendue (contrat PR #29 §5, vérifié sur la doc officielle)

```jsonc
// AVANT — forme shell (existant, les 25 entrées actuelles)
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/mon-script.sh --hook || true" }

// APRÈS — forme exec (cible PORT-02/§3.4)
{ "type": "command",
  "command": "<chemin ABSOLU vers bash, résolu et vérifié à l'install>",
  "args": ["{{VF_SCRIPTS}}/mon-script.sh", "--hook"] }
```

Confirmé par la doc officielle Claude Code (fetch direct `code.claude.com/docs/en/hooks`,
CITED) : `command` est résolu sur `PATH` en forme exec, un nom nu comme `"bash"` reproduirait
donc le même risque que la forme shell (résolution PATH-dépendante, potentiellement différente à
chaque invocation selon l'environnement Windows). C'est la citation exacte extraite :
> « `command` est **résolu sur le PATH**. Un nom nu (`"bash"`) reproduirait donc exactement le bug
> qu'on corrige. Le **chemin absolu est la pièce porteuse**, pas un raffinement. » (contrat PR #29
> §5, corroboré indépendamment par la doc officielle : « `command` is resolved as an executable on
> `PATH` »)

`|| true` **disparaît par construction** — l'opérateur shell n'est pas exprimable sans shell. Le
`timeout`, `if`, `statusMessage`, `async`, `asyncRewake` restent acceptés ; `shell` est ignoré dès
que `args` est présent (confirmé doc officielle).

### Pattern de test à étendre — dédup cross-matcher devient dédup cross-forme

```bash
# Source : plugin/_internal/tests/test-merge-hooks.sh:167-191 (lu intégralement — VERIFIED)
# T7 — changement de matcher entre versions du fragment → pas de doublon
# Patron à répliquer pour la dédup CROSS-FORME (shell existant → exec nouveau) :
#   1. merger un fragment EN FORME SHELL dans un settings.json vierge
#   2. merger le MÊME fragment, désormais EN FORME EXEC
#   3. asserter : 1 seule entrée pour ce script (pas 2), l'ancienne entrée shell est retirée
#   4. remove sur le fragment exec doit retirer l'entrée (test que frag_basenames() lit args)
```

## State of the Art

| Ancienne approche | Approche actuelle | Changé quand | Impact |
|---------------------|---------------------|----------------|--------|
| Hooks en forme shell (`command` = chaîne passée à `sh -c`) | Forme exec (`command` + `args`, spawn direct sans shell) | Documentation Claude Code, vérifiée à date de recherche (2026-08-15) | Élimine les problèmes de quoting sur chemins à espaces (cas nominal Windows), mais retire `|| true` — exige une normalisation de code de sortie en amont |
| `|| true` comme mécanisme d'advisory | Code de sortie 0 natif au script | Forme exec | Le silence devient un vrai contrat de sortie, pas un masquage shell |
| `PYBIN=` variable locale par script (17 fichiers, 2 variantes déjà divergentes) | `vf_python()` fonction centralisée, un seul point de vérité | Contrat PR #29 (figé 2026-08-02) | Ferme la divergence déjà constatée entre variante A (15 fichiers) et variante B (2 fichiers, dont 1 actif en production) |

**Périmé / à ne plus utiliser :**
- Toute nouvelle résolution Python locale par `command -v python3` sans passer par `vf_python` —
  le gate `check-portable-resolution.sh` (annoncé au contrat, absent du dépôt à ce jour) est
  censé l'interdire mécaniquement une fois livré par la polarité gouvernance.
- L'affirmation « `--hook` ne change ni les 4 exits ni le rendu » dans les 4 scripts
  `dev-orchestrator` — vraie aujourd'hui, fausse après cette phase (voir Pitfall 1).

## Assumptions Log

| # | Claim | Section | Risque si faux |
|---|-------|---------|------------------|
| A1 | `vf_py_probe` est conçu pour être appelé une fois par session (comme `probe-memory-guards.sh`) plutôt qu'à chaque invocation d'un guard `PreToolUse` | Pitfall 3 | Si faux, `guard-file-size.sh` migré subit un spawn `timeout` supplémentaire à CHAQUE `Edit`/`Write` — régression de latence perceptible, contredisant l'intention documentée de l'amendement ADR-054 point 3. Le contrat PR #29 (lu intégralement) ne tranche PAS explicitement ce point de fréquence d'appel — c'est une extrapolation, pas une lecture. |
| A2 | Le hook doctor minimal de `conductor` (D-05, agrégation en une ligne au SessionStart) est réalisable SANS dépendre d'aucune autre brique de la polarité gouvernance non livrée | Décisions D-05 | Si faux, cette brique doit être différée avec reliquat tracé plutôt qu'implémentée — CONTEXT.md laisse explicitement ce choix « au planner sur pièces », donc ce n'est pas une lacune de recherche mais une décision de scope à trancher au plan |
| A3 | `args` en forme exec ne contient jamais de flags qui ressemblent syntaxiquement à un nom de script matchable par `SCRIPT_RE` (`[A-Za-z0-9._-]+\.(?:sh|py)`) | Code Examples §frag_basenames | Improbable vu les entrées actuelles (`--hook`, `--async`, `--apply`, `--quiet` — aucune ne finit en `.sh`/`.py`), mais non vérifié exhaustivement sur les 25 entrées gouvernance qui restent hors périmètre direct de cette phase |

**Si cette table semble courte :** c'est volontaire — la quasi-totalité des affirmations
factuelles de ce document est tracée à un `Read` de fichier source (`plugin/_internal/*`,
`plugin/dev-orchestrator/scripts/*`, `plugin/software-architecture/scripts/*`,
`.github/workflows/ci.yml`, `docs/ADR.md`) ou à un fetch direct de la documentation officielle
Claude Code, jamais à de la mémoire d'entraînement seule.

## Open Questions

1. **Le hook doctor minimal de `conductor` (D-05) — inclure ou différer ?**
   - Ce qu'on sait : `VF_GUARD_HEALTH_DIR` n'existe pas encore, aucun consommateur amont
     n'existe. `vf_guard_unavailable` peut écrire le marqueur SANS que le doctor existe (les
     marqueurs « s'accumulent sans casse tant que le doctor n'existe pas », CONTEXT.md).
   - Ce qui n'est pas clair : le coût réel d'une version minimale (une ligne, SessionStart,
     agrégation des marqueurs) vs. le risque de scope creep dans une phase déjà dense (3 lots :
     PYBIN, hooks, gestes jour 1).
   - Recommandation : trancher au plan selon le budget de plans restant après (a)+(b)+(c) — c'est
     une décision de séquencement, pas une inconnue technique.

2. **Combien des 21 entrées gouvernance restantes (25 − 4 dev) ont un `exit 3` interne
   aujourd'hui, candidat à la même translation `--hook` ?**
   - Ce qu'on sait : les 4 entrées dev-orchestrator suivent la convention 0/3/64. Aucune lecture
     complète des scripts `conductor`/`consolidator`/`planning-core`/`infrastructure-audit` n'a
     été faite dans cette session (hors périmètre direct — D-07 dit que la normalisation
     s'applique au parc entier mais seules les entrées dev migrent en forme exec cette phase).
   - Ce qui n'est pas clair : si ces 21 scripts suivent la MÊME convention `--hook`
     (silence/signal/erreur) ou des conventions ad hoc plus anciennes.
   - Recommandation : l'inventaire complet demandé par D-08/PORT-03 (« recompter, documenter
     événement + classement ») doit inclure une lecture systématique de ces 21 scripts au moment
     du plan — hors budget de cette session de recherche, mais c'est une tâche mécanique de
     grep+lecture, pas un risque de conception.

## Environment Availability

| Dépendance | Requise par | Disponible | Version | Repli |
|------------|--------------|-------------|---------|-------|
| bash | Tous les scripts de hooks et le moteur | ✓ | ≥ 3.2 (macOS testé, `BASH_BIN` surchargeable) | — |
| python3 | `merge-hooks.sh`, guards, `vf-portable.sh` à écrire | ✓ (poste de dev/CI) | 3.x | Cascade `vf_python` gère l'absence côté utilisateur final |
| jq | `resolve-deps.sh` (hors périmètre direct) | ✓ | tout | `jqx()` déjà en place ailleurs |
| Node.js 22+ | `@opengsd/gsd-core` (utilisé par la CI, pas par cette phase directement) | ✓ (CI épingle Node 22) | 22 | — |
| Runner Windows réel | AUCUNE preuve Windows native n'est possible sur ce dépôt | ✗ | — | Suites `windows-crlf`/`windows-guards` simulent les conditions Windows sans poste Windows (shims, fixtures antislashs, stub `WindowsApps` factice) — c'est le seul repli disponible et il est déjà la doctrine du dépôt (ADR-054) |
| `npm view` (registre npm) | WKTR-03 (veille gsd-core) | ✓ (réseau requis à l'exécution, pas à la conception) | — | Pattern `check-plugin-update.sh` : réseau KO → cache non réécrit, ancien état conservé, jamais bloquant |

**Dépendances manquantes sans repli :** aucune — le point le plus proche d'un blocage (absence de
runner Windows réel pour PORT-05) a déjà un repli établi et documenté par ADR-054 : simulation
plutôt que poste réel, explicitement assumé comme suffisant par les rapports terrain déjà intégrés.

## Validation Architecture

### Test Framework

| Propriété | Valeur |
|-----------|--------|
| Framework | Bash maison, convention `TESTING.md` du dépôt (pass/fail affiché `✓`/`✗`, `ok()`/`ko()`, isolation `mktemp`) |
| Fichier de config | Aucun — découverte par pattern `find plugin scripts -type f -path '*/tests/test-*.sh'` (`.github/workflows/ci.yml:208`) |
| Commande rapide | `bash plugin/_internal/tests/test-merge-hooks.sh` (ou toute suite ciblée individuellement) |
| Commande suite complète | Le job `tests` de `ci.yml` — découverte + exécution de TOUTES les suites `*/tests/test-*.sh`, échec si 0 suite trouvée (garde anti-vert-à-vide) |

### Phase Requirements → Test Map

| Req ID | Comportement | Type de test | Commande automatisée | Fichier existe ? |
|--------|--------------|---------------|------------------------|--------------------|
| PORT-01 | Les 3 fichiers PYBIN utilisent `vf_python`/cascade partagée | unitaire | `bash plugin/software-architecture/scripts/tests/test-*.sh` (guard-file-size n'a pas de suite dédiée trouvée — vérifié : seule `test-windows-guards.sh` couvre les guards consolidator) | ❌ Wave 0 — pas de suite dédiée `guard-file-size.sh` trouvée, à créer ou à étendre |
| PORT-02 | `merge-hooks.sh` apprend `args`, dédup cross-forme, remove exec | unitaire + mutation | `bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ suite existante à étendre (T7 = patron direct pour la dédup cross-forme) |
| PORT-03 | Codes de sortie normalisés, démarrage silencieux prouvé | unitaire | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | ✅ suite existante, cas `--hook` à ajouter/étendre pour capturer stdout+stderr séparément (Pitfall 2) |
| PORT-05 | Portabilité prouvée en CI (windows-crlf + windows-guards + gates verts) | intégration + CI | `bash plugin/_internal/tests/test-windows-crlf.sh` + `bash plugin/consolidator/scripts/tests/test-windows-guards.sh` + job `gates`/`tests` de `ci.yml` | ✅ suites existantes, déjà découvertes par la CI (patron `lab-frais`/`lab-frais-arme` réutilisable pour une preuve « lab frais » dédiée si le plan le juge nécessaire) |
| QUAL-01 | Chaque gate né dans la phase a 3 issues + mutation rouge | méta (discipline de test) | N/A — critère transverse vérifié par revue de chaque suite ajoutée | — |

### Sampling Rate

- **Par commit de tâche :** la suite ciblée du fichier modifié (`test-merge-hooks.sh` pour le
  moteur, `test-dev-orchestrator.sh` pour les scripts dev, `test-windows-*.sh` pour les guards)
- **Par merge de vague :** toutes les suites `*/tests/test-*.sh` découvertes localement
  (`find plugin scripts -type f -path '*/tests/test-*.sh'`)
- **Gate de phase :** suite complète verte avant `/gsd-verify-work`, plus le job CI `tests` +
  `gates` (aucun runner Windows réel disponible — voir Environment Availability)

### Wave 0 Gaps

- [ ] Aucune suite dédiée `plugin/software-architecture/scripts/tests/test-guard-file-size.sh`
  trouvée (vérifié par `find` — seul `test-windows-guards.sh` de `consolidator` couvre un guard,
  pas `guard-file-size.sh`) — à créer si le plan veut une preuve unitaire isolée de la migration
  PYBIN de ce fichier précis, ou à couvrir via une extension de `test-windows-guards.sh`.
- [ ] Aucun test de dédup cross-forme (shell existant retiré par un fragment exec, et
  réciproquement) n'existe encore dans `test-merge-hooks.sh` — c'est un cas NEUF requis par
  PORT-02, pas une extension d'un cas existant.
- [ ] Aucun test ne capture stdout et stderr séparément pour les 4 scripts SessionStart en mode
  `--hook` — nécessaire pour prouver le Pitfall 2 fermé (silence = stdout vide, pas seulement
  exit 0).

## Security Domain

> `security_enforcement` non trouvé explicitement à `false` dans `.planning/config.json` — section
> incluse par défaut.

### Applicable ASVS Categories

| Catégorie ASVS | S'applique | Contrôle standard |
|------------------|-------------|----------------------|
| V2 Authentication | non | Aucune authentification impliquée |
| V3 Session Management | non | — |
| V4 Access Control | non | — |
| V5 Input Validation | oui | Le parsing d'`args[]` dans `merge-hooks.sh` doit rester strict — même discipline de frontière (lookaround négatif) que `command` aujourd'hui, jamais une regex plus permissive introduite « pour aller vite » sur les nouveaux éléments d'`args` |
| V6 Cryptography | non | Aucune donnée sensible chiffrée impliquée |

### Known Threat Patterns for ce dépôt

| Pattern | STRIDE | Mitigation standard |
|---------|--------|------------------------|
| Résolution de chemin relative au CWD exécutée sans ancrage (motif déjà rencontré 5 fois dans ce dépôt, dernier cas fermé Phase 27 : `dag.sh:124`, RCE reproduite par PoC) | Tampering / Elevation of Privilege | Le chemin absolu vers `bash` (exigence §5 du contrat) doit être résolu **à l'install** (par le moteur, dans un contexte de confiance connu) et **vérifié** (existence + exécutabilité), jamais recalculé au moment du hook depuis un `dirname "$0"` ou un CWD ambiant. C'est exactement le même motif de vecteur que celui fermé en Phase 27 — vérifier explicitement au plan que la résolution du chemin absolu de bash ne retombe pas sur un `$(dirname "$0")` non ancré |
| Copier-coller de bloc de portabilité qui diverge silencieusement (constaté : variante B de `inject-mcp-tools.sh` expose le stub WindowsApps que la variante A neutralise) | Tampering (silencieux) | Le gate à sommes de contrôle du bloc localisateur (contrat §3/§6) — pas encore livré dans ce dépôt (0 occurrence de `check-portable-resolution.sh`), donc cette phase doit s'assurer que son propre bloc est prêt à être vérifié par ce gate quand il arrivera, même s'il n'est pas encore câblé en CI |
| Guard fail-open qui protège en apparence seulement (constaté ADR-054 rapport 2 : `command -v python3 || exit 0` satisfait par le stub inerte) | Spoofing (fausse protection) | `vf_guard_unavailable` + sortie non-zéro (D-02, contrat §4) — le silence est explicitement interdit sur ce chemin, c'est l'objet même de PORT-01/D-04/D-05 |

## Sources

### Primary (HIGH confidence — lecture directe de fichiers sources ce jour)

- `plugin/_internal/merge-hooks.sh` (213 lignes, lu intégralement)
- `plugin/_internal/vibeflow-update.sh` (extraits l.230-400, `copy_module_scripts`,
  `find_hooks_merger`, `find_mcp_injector`, `sync_module_governance`)
- `plugin/_internal/tests/test-merge-hooks.sh` (210 lignes, lu intégralement)
- `plugin/_internal/tests/test-windows-crlf.sh` (extraits l.1-40)
- `plugin/consolidator/scripts/tests/test-windows-guards.sh` (extraits l.1-60)
- `plugin/software-architecture/scripts/guard-file-size.sh` (128 lignes, lu intégralement)
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (grep ciblé résolution Python)
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (grep ciblé résolution Python)
- `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` (extraits l.1-110, l.260-330, lus
  intégralement pour la logique d'exit)
- `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (grep ciblé exit codes)
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (grep ciblé exit codes)
- `plugin/dev-orchestrator/scripts/check-gsd-config.sh` (grep ciblé exit codes)
- Les 6 `plugin/*/hooks/hooks.json` (lus intégralement — conductor, consolidator,
  dev-orchestrator, infrastructure-audit, planning-core, software-architecture) — 25 entrées
  recomptées et vérifiées à l'identique de D-08
- `plugin/conductor/scripts/check-plugin-update.sh` (95 lignes, lu intégralement)
- `plugin/conductor/scripts/update-banner.sh` (69 lignes, lu intégralement)
- `plugin/infrastructure-audit/scripts/audit-infra.sh` (grep ciblé `--if-older-than`)
- `.github/workflows/ci.yml` (extraits l.1-300, l.620-710 — jobs `tests`, `lab-frais`,
  `lab-frais-arme`)
- `docs/ADR.md` (ADR-054 intégral, l.601-694)
- `docs/CONTRAT-PORTABILITE.md` — lu intégralement depuis
  `origin/gouvernance/contrat-portabilite` via `git show` (173 lignes, PR #29 encore ouverte,
  non mergée sur `main`)
- `.planning/phases/VFDO-30-portabilit-windows-ii/30-CONTEXT.md` (intégral)
- `.planning/REQUIREMENTS.md` (sections Phase 30 + milestone fiabilite-v1.0)
- `.planning/ROADMAP.md` (extraits l.507-586)
- `.planning/STATE.md` (extraits pertinents)
- `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md` (intégral, 391 lignes)

### Secondary (MEDIUM confidence — documentation officielle)

- `code.claude.com/docs/en/hooks` (fetch direct WebFetch) — schéma JSON complet des hooks, forme
  exec, résolution `command` sur PATH, sémantique exit code par événement (`PreToolUse`, `Stop`,
  `UserPromptSubmit` bloquants sur exit 2 ; `PostToolUse`, `SessionStart`, `SessionEnd` non
  bloquants ; comportement stdout/stderr par cas)
- Context7 `/anthropics/claude-code` — exemples de `hooks.json`, contrat exit codes générique
  (0/2/autre), corrobore le fetch direct sans le contredire

### Tertiary (LOW confidence)

- Aucune — toutes les affirmations de ce document remontent à une source Primary ou Secondary ;
  voir Assumptions Log pour les 3 points qui restent des extrapolations non vérifiées sur pièce.

## Metadata

**Confidence breakdown :**
- Stack technique : HIGH — aucune nouvelle dépendance, tout vérifié sur le code existant
- Architecture (merge-hooks.sh, forme exec, exit codes) : HIGH — code lu intégralement + doc
  officielle fetchée directement, les deux sources convergent
- Pitfalls : HIGH pour les Pitfalls 1/2/4 (vérifiés sur citations exactes de fichiers lus) ;
  MEDIUM pour le Pitfall 3 (le profil de fréquence d'appel de `vf_py_probe` est une extrapolation,
  voir A1)
- Runtime State Inventory : HIGH — chaque catégorie vérifiée par grep/ls, pas par déduction

**Date de recherche :** 2026-08-15
**Valide jusqu'à :** 30 jours (2026-09-14) — le contrat PR #29 n'est PAS encore mergé sur `main` ;
si son contenu change avant que la Phase 30 ne s'exécute, cette recherche doit être rafraîchie
sur les sections §2/§3.1/§5 du contrat (le `git show` devra être rejoué).
