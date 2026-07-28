# Mission — Phase 17 : Signaux de démarrage du moteur de dev

**Date** : 2026-07-28 · **Owner du lock** : `mission-phase17`
**Commit de base** : `69086d8` (Phase 15 shippée v2.40.0 + Phase 16 inscrite) · **HEAD** : `6e33b14`
**Mode** : mission d'équipe, DAG à 5 nœuds

> ⚠️ **Historique partagé** : la Phase 17 a été cadrée et exécutée **pendant** que la Phase 16
> (mission concurrente, `mission-phase16`) tournait sur le même dépôt. Le lock de `mission-phase16` a
> expiré par TTL en cours de mission ; `mission-phase17` l'a acquis pendant que la Phase 16 continuait
> de commiter. Voir §Collision de version ci-dessous pour la conséquence concrète, et §Dettes pour
> l'incident complet.

---

## Plan de bataille (DAG, 5 nœuds, 1 ré-entrée)

```
n1 (plan) → n2 (execute) ┬→ n3 (test — gate portabilité)  ┐
                          └→ n4 (audit — advisory/read-only) ┴→ reopen → n5 (close)
```

- **n1 — Cadrage + plan** (`stage: plan`) : cadrage complet (`17-CONTEXT.md`,
  `17-DISCUSSION-LOG.md`, `17-PATTERNS.md`), amendement SC1 (arbitrage humain, voir ci-dessous),
  3 plans écrits (17-01/02/03) avec précondition anti-collision de version. `done`.
- **n2 — Exécution** (`stage: execute`) : 3 scripts + `hooks/hooks.json` + `AGENT.md` + triade de
  version module `v2.5.0 → v2.6.0` (collision résolue en cours d'exécution). `done`.
- **n3 — Gate portabilité Linux** (`stage: test`, dépend de n2) : preuve empirique Docker (Debian 12,
  Ubuntu 24.04) + CI, compteurs de suites comparés à macOS. `done`.
- **n4 — Audit advisory/read-only** (`stage: audit`, dépend de n2, en parallèle de n3) : vérification
  du contrat SC5 (ADR-031) — lecture seule, aucun `exit 1`, aucun blocage de tour. `done`.
- **Reopen (unique)** : après fusion des verdicts n3 et n4, deux findings de revue sur les **tests**
  (jamais sur les 3 scripts livrés ni sur le module, qui reste `v2.6.0`) ont déclenché un aller-retour
  d'exécution — commit `6e33b14`. Voir §Comblement.
- **n5 — Clôture** (`stage: close`, dépend de n3 + n4) : hygiène documentaire — ce rapport,
  `STATE.md`, `ROADMAP.md`, `CONCERNS.md`. Aucun code, aucun test, aucune release.

Trace machine : `.planning/missions/dag-phase17.json` (9/9 — 5/5 nœuds effectifs `done` après ce
commit de clôture).

---

## Arbitrage humain — SC1 amendé (2026-07-27)

`.planning/ROADMAP.md` §Phase 17 SC1 disait initialement « les trois scripts sortent en 3 et **aucune
ligne** n'est injectée […] le coût contexte d'un projet sain est nul ». La spec de référence
(`docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md` §4.2 et §7) dit l'inverse : sur un
projet sain, **une** ligne `[gsd-engine]` d'orientation est injectée. SC1 tel qu'écrit contredisait
aussi SC2 et SC2bis de la **même** entrée ROADMAP, qui exigent ce signal — c'est précisément le signal
qui ferme le trou de routage constaté le 2026-07-27 sur ce repo (une demande de conception adressée au
Claude principal était partie sur `superpowers:brainstorming` alors que le projet tournait sous GSD
avec une Phase 16 inscrite).

**Arbitrage retenu par Samuel** : SC1 devient « les trois scripts sortent en 3 et la **seule** ligne
injectée est le `[gsd-engine]` d'orientation ». SC2 et SC2bis restent inchangés. Ceci est un arbitrage
humain daté, appliqué par `vf-coder` (n1 du DAG) sur mandat exprès de `vf-dev-manager` — jamais tranché
en autonomie. Consigné dans `.planning/STATE.md` §Decisions (2026-07-27).

---

## Collision de version — v2.5.0 → v2.6.0

**Cause** : la Phase 16 (mission concurrente, tournant en parallèle sur le même dépôt — voir
l'avertissement d'historique partagé ci-dessus) a consommé `v2.5.0` sur `plugin/dev-orchestrator`
(commit `bef0a91`, puis release racine `v2.41.0`, commit `fc89f53`) pour ses propres raisons (lint
`tools:` + allowlists des 3 workers). Le plan `17-03` avait été écrit **avant** ce commit et ciblait
encore `v2.4.0 → v2.5.0`.

**Résolution** (commit `5a8b6a8`) : décision du manager de mission, sur la convention du `CLAUDE.md`
racine (nouvelle capacité → minor) — la Phase 17 apporte une nouvelle capacité (fragment hooks + 2
scripts de constat), donc la cible devient `v2.5.0 → v2.6.0`. Précondition de la Task 3 (17-03) mise à
jour en conséquence. Aucune régression : la triade `VERSION`/`module.json`/CHANGELOG du module est
cohérente en `v2.6.0` (vérifié par `check-version-sync.sh`, section triade par module verte).

C'est cette même expiration TTL du verrou de driver qui a permis aux deux missions de tourner en
parallèle — voir la dette inscrite ci-dessous.

---

## Verdicts d'étape (faits vérifiés, consignés ici car nulle part ailleurs sur disque)

### SC5 (advisory / lecture seule) — **CONFORME**

Prouvé par exécution, pas par lecture :

- **Lecture seule OUI** — seul `mktemp` du module, dans `discover-unintegrated-docs.sh:91-93`, apparié
  au `trap ... EXIT` ligne 94, borné à `$TMPDIR`.
- **Aucun `exit 1` OUI** — seuls 0/3/64 sur les trois scripts ; `set -uo pipefail` partout, jamais
  `set -e`.
- **Aucun blocage de tour OUI** — `hooks/hooks.json` = un seul groupe `SessionStart`, 3 commandes
  chacune suffixée `|| true`, aucun `Stop`/`PreToolUse`.
- **Robustesse** — 5 fixtures de frontmatter hostiles (injection shell, octet de contrôle `0x01`,
  délimiteur tronqué, `$(whoami)`) → stdout **VIDE** et exit 3 dans les 5 cas ; `node_modules` de
  20 000 fichiers → 0.007s (élagage `-prune` confirmé) ; hors dépôt git sur chemin à espace/UTF-8 →
  silence propre.
- Toutes les menaces `high` du threat model closes.

### SC6 (portabilité macOS ET Linux) — **PROUVÉ**

Compteurs **identiques** sur trois environnements :

| Environnement | bash | `test-check-dev-bootstrap.sh` | `test-check-doc-drift.sh` | `test-discover-unintegrated-docs.sh` |
|---|---|---|---|---|
| macOS | 3.2.57 | 23 ok/0 ko | 21 ok/0 ko | 22 ok/0 ko |
| Debian 12 | 5.2.15 | 23 ok/0 ko | 21 ok/0 ko | 22 ok/0 ko |
| Ubuntu 24.04 (OS exact `runs-on: ubuntu-latest`) | 5.2.21 | 23 ok/0 ko | 21 ok/0 ko | 22 ok/0 ko |

Aucun test sauté silencieusement. Zéro piège BSD/GNU trouvé. Aucun edit de `ci.yml` nécessaire : les
2 nouvelles suites tombent dans le `find plugin scripts -type f -path '*/tests/test-*.sh'` déjà en
place dans la CI.

---

## Comblement (commit `6e33b14`) — après fusion des verdicts n3/n4

Deux findings de revue sur les **tests**, aucun changement aux 3 scripts livrés ni au module (reste
`v2.6.0`) :

1. **Cas 7 de `test-discover-unintegrated-docs.sh` rendu discriminant.** Il était tautologique : la
   fixture ne portait que le glob, jamais le basename littéral du document — le cas était vert par
   construction, filtre glob présent ou non (preuve : suppression de la ligne 129 du script sans effet
   sur le compte, 21 ok/1 ko après retrait — prouvé par mutation jetable, jamais commitée). La ligne de
   registre porte désormais le glob ET le basename littéral, rendant le cas discriminant (rc=0 avec le
   filtre actif, rc=3/silence une fois le filtre retiré).

2. **Boucle T21 de `test-dev-orchestrator.sh` élargie.** Elle ne couvrait que `check-dev-bootstrap.sh`
   et `check-doc-drift.sh`, ratant `discover-unintegrated-docs.sh` — pourtant le seul des trois à
   utiliser `mktemp` (3 appels appariés à un `trap ... EXIT`). Le neutraliseur de bloc `awk` embarqué
   ne reconnaissait que la forme nue `awk '` en fin de ligne, pas `awk -v base="$1" '` utilisée par ce
   script : le corps awk (opérateurs `>` de comparaison, jamais des redirections bash) fuitait dans
   l'analyse et déclenchait un faux positif T21b. Élargi le déclencheur pour couvrir tout préfixe avant
   la citation ouvrante — invariant non affaibli, juste sa détection du périmètre awk complétée — puis
   ajouté le 3e script à la boucle.

Vérifié après correctif : 22 ok / 64 OK sur macOS (bash 3.2.57) et 22 ok / 63 OK sur Debian
stable-slim et Ubuntu 24.04 (1 SKIP pré-existant côté Linux, environnement GSD non installé — confirmé
identique avant et après ce correctif).

---

## Dettes inscrites à `CONCERNS.md` (constatées, pas corrigées — hors mandat de clôture)

### Dette A — le verrou de driver est déclaratif, pas contraignant

`driver-lock.sh` n'empêche techniquement rien : aucun hook ni garde en écriture ne refuse un commit à
une session sans verrou. Constaté le 2026-07-27 : le lock de `mission-phase16` a été élagué par TTL,
`mission-phase17` l'a acquis, et la Phase 16 a **continué à commiter** pendant que la Phase 17 tenait
le verrou — horodatages entrelacés 22:37 P16 · 22:38 P17 · 22:42 P16 · 22:46 P16 · 22:48 P17 ·
22:50 P16. Conséquence concrète : la collision de version documentée ci-dessus. Risque : deux drivers
concurrents sur le même `.planning/`, arbitrages silencieusement écrasés. Fichiers :
`plugin/conductor/scripts/driver-lock.sh`.

### Dette B — le gate ADR-044 est un faux vert dans son invocation nue

`bash plugin/conductor/scripts/check-agents.sh` **sans argument** sort **exit 0** avec « aucun agent
dans .claude/agents — rien a verifier », car `.claude/agents` est absent de ce repo. Or c'est cette
invocation que prescrivent les critères d'acceptation (spec Phase 17 §7.6) — elle ne prouve RIEN. De
plus, `plugin/dev-orchestrator/AGENT.md` (`name: vibeflow-dev`) est à la racine du module, donc hors de
la boucle CI sur `plugin/*/agents` : il n'est atteint que par `check-agents.sh --file`. Invocation
réelle qui prouve quelque chose :
`bash plugin/conductor/scripts/check-agents.sh --file plugin/dev-orchestrator/AGENT.md` (exit 0,
3 warnings préexistants : name ≠ nom de fichier, aucun skill câblé, `tools:` absent). Risque : tout
critère d'acceptation futur rédigé sur l'invocation nue est satisfait à la lettre et vide sur le fond.
Fichiers : `plugin/conductor/scripts/check-agents.sh`, `.github/workflows/ci.yml`.

---

## Critères de succès de la Phase 17

| # | Critère | État |
|---|---|---|
| 1 | 3 scripts sortent en 3, seule la ligne `[gsd-engine]` est injectée sur repo sain (SC1 amendé) | ✅ |
| 2 / 2bis | `check-dev-bootstrap.sh` — continuum à 4 états, signal `gsd-engine` d'orientation | ✅ |
| 3 | `discover-unintegrated-docs.sh --hook` additif, contrat historique intact | ✅ |
| 4 | `check-doc-drift.sh` — seuil réglable, silence hors git | ✅ |
| 5 | Les 3 scripts advisory/lecture seule (ADR-031) | ✅ **SC5 CONFORME**, prouvé par exécution |
| 6 | Portabilité macOS + Linux prouvée en conteneur | ✅ **SC6 PROUVÉ**, compteurs identiques 3 environnements |

---

## Laissé de côté, et pourquoi

1. **Release racine + tag + release GitHub** — hors périmètre du mandat de clôture (n5). `VERSION`
   racine, `marketplace.json`, `plugin.json` et les README racines sont **intouchés** (v2.41.0).
2. **`scripts/check-version-sync.sh` rouge** — `README.md`/`README.fr.md` annoncent « 39 suites »
   contre 41 réelles (les 2 suites ajoutées par cette phase). Pré-requis de release, non corrigé ici :
   hors périmètre, réservé à la préparation de release par l'humain.
3. **Les deux dettes ci-dessus** — inscrites, pas corrigées. Extension de périmètre non exécutée en
   mission (ADR-031).

---

## Bumps par module

`dev-orchestrator` v2.4.0 → **v2.6.0** (minor — nouvelle capacité : signaux de démarrage ; la valeur
intermédiaire `v2.5.0` a été consommée par la Phase 16 concurrente, jamais publiée par la Phase 17).
`VERSION` racine, `marketplace.json`, `plugin.json`, README racines : **intouchés** (restent `v2.41.0`).

---

## Next step

**Publier la release racine**, sous réserve d'un geste préalable : aligner `README.md`/`README.fr.md`
sur 41 suites réelles (`check-version-sync.sh` actuellement rouge sur ce seul point — tout le reste est
vert : plugin.json, marketplace.json, badges, triade par module, en-têtes Version, historique en tête).
Puis appliquer la discipline du `CLAUDE.md` racine : trancher le numéro racine (v2.41.0 → probable
v2.42.0, nouvelle capacité), bump des trois fichiers + historique des deux README, tag annoté poussé,
release GitHub, `scripts/check-release-tag.sh --remote` → ✓.

**Phase 18** (Capability living-specs, conventions OpenSpec) dépend de la Phase 17 — désormais
débloquée pour cadrage, indépendamment de la release racine de la Phase 17.
