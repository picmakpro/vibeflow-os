---
phase: VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0
verified: 2026-07-31T18:15:08Z
status: gaps_found
verdict: PASS PARTIEL
score: 7/8 must-haves verified (les 6 Changements + le point hérité STATE.md ✓ ; la clause « release racine » du Goal non livrée)
behavior_unverified: 0
overrides_applied: 0
diff_verified: c01f813..bd6e749 (19 commits, branche feat/phase-21-alignement-gsd-core-190)
re_verification: null
gaps:
  - truth: "Le repo passe ses propres gates de sortie (discipline CLAUDE.md / CI `gates`)"
    status: failed
    reason: >
      `scripts/check-version-sync.sh` sort en rc=1 sur HEAD : les deux README racine annoncent
      « 44 suites » alors que la découverte réelle (`find plugin scripts -type f -path
      '*/tests/test-*.sh'`) en compte 45 depuis l'ajout de `test-check-state-integrity.sh` (21-04).
      Le job CI `gates` lance ce script SANS condition de branche (`.github/workflows/ci.yml:114`) —
      la CI est donc rouge sur cette branche aujourd'hui, pas seulement au moment de la release.
      Aggravant : la MÊME dérive était la fenêtre WINDOWS #2, fermée (`fixed`) le 2026-07-31T15:32
      sur la valeur 44 ; sa réouverture par cette phase n'est PAS enregistrée au ledger
      (`open_count: 1`, seule #3 ouverte) — `/gsd-ship` ne bloquerait donc pas dessus.
    artifacts:
      - path: "README.md"
        issue: "lignes 165 et 235 : « 44 suites » — réel 45"
      - path: "README.fr.md"
        issue: "lignes 170 et 240 : « 44 suites » — réel 45"
      - path: ".planning/WINDOWS.md"
        issue: "WINDOWS #2 (compteur N suites) marquée fixed sur 44 ; la régression à 45 n'est pas ré-enregistrée"
    missing:
      - "Passer les 4 occurrences des 2 README de 44 à 45 (voyage avec le commit de release, cf. patron 20-07)"
      - "Ou rouvrir/ajouter une entrée WINDOWS pour que le ledger porte la dette au lieu d'un seul SUMMARY"
  - truth: "Les modules touchés par la phase sont distribuables (VERSION / module.json / CHANGELOG à jour)"
    status: partial
    reason: >
      Seul `conductor` a été bumpé (v1.17.0 → v1.18.0, cohérent). `dev-orchestrator` reste à
      v2.8.0 — la version publiée par la Phase 20 — alors que la Phase 21 y a changé un CONTRAT
      d'agent (`vf-coder.md`, `vf-dev-manager.md`), la découverte MCP (`inject-mcp-tools.sh`,
      +214/-64), `mission-contracts.md` (+62 lignes, 3 sections neuves), 3 scripts et
      `gsd-skills-index.md` : deux payloads différents circulent aujourd'hui sous le même numéro.
      `planning-core` idem (`detect-gsd-engine.sh` modifié, VERSION figée v2.5.2, aucune entrée
      CHANGELOG). Le report est ASSUMÉ et écrit (21-03-SUMMARY:164-166, « même patron que 20-07,
      bump groupé au moment de la clôture ») — mais la Phase 20 portait ce bump dans un plan dédié
      (20-07) ; la Phase 21 s'arrête à 21-04 et n'a AUCUN nœud qui le porte.
    artifacts:
      - path: "plugin/dev-orchestrator/VERSION"
        issue: "v2.8.0 inchangé malgré un changement de contrat d'agent + 8 fichiers modifiés"
      - path: "plugin/dev-orchestrator/CHANGELOG.md"
        issue: "aucune entrée Phase 21 — la dernière section est [v2.8.0] / Phase 20"
      - path: "plugin/planning-core/VERSION"
        issue: "v2.5.2 inchangé malgré la modification de detect-gsd-engine.sh"
    missing:
      - "Un nœud de clôture (21-05 ou commit de release) qui bumpe dev-orchestrator (v2.9.0, changement de contrat) et planning-core (patch), CHANGELOG + module.json + en-tête Version du README compris"
  - truth: "La feuille de route reflète l'état réel de la Phase 21"
    status: failed
    reason: >
      `.planning/ROADMAP.md` § Phase 21 porte encore « **Plans**: 0 plans » et la ligne
      « - [ ] TBD (run /gsd-plan-phase 21 to break down) », alors que 4 plans existent, sont
      exécutés et ont chacun leur SUMMARY. La section de la Phase 20, juste au-dessus, liste
      correctement ses 7 plans cochés — la régression de tenue est propre à la 21.
      Corollaire : « **Requirements**: TBD (à mapper au ledger pendant le plan) » n'a jamais été
      levé, `.planning/REQUIREMENTS.md` ne porte aucune entrée Phase 21, et les 4 PLAN utilisent
      des chaînes ad-hoc (`requirement: "Changement 4"`) qui ne résolvent vers aucun ID du ledger.
    artifacts:
      - path: ".planning/ROADMAP.md"
        issue: "§ Phase 21 : « Plans: 0 plans » + case TBD non remplacée"
      - path: ".planning/REQUIREMENTS.md"
        issue: "aucune exigence rattachée à la Phase 21"
    missing:
      - "Lister les 4 plans exécutés sous § Phase 21 et passer « Plans: 4 plans »"
      - "Trancher le mapping ledger (mapper les 6 Changements en REQ-*, ou acter par écrit que cette phase reste hors ledger — rituel allégé)"
deferred:
  - truth: "Publier une release racine (bump VERSION/plugin.json/marketplace.json/README*, tag annoté vX.Y.Z poussé, release GitHub, check-release-tag.sh --remote ✓)"
    addressed_in: "Commit de release racine, post-fusion — action humaine réservée à Samuel"
    evidence: >
      Clause explicite du Goal ROADMAP § Phase 21 (« puis publier une release racine »), non
      livrée : VERSION est resté v2.44.0 (valeur de la Phase 20), aucun tag v2.45.x. Report écrit
      et motivé en 21-03-SUMMARY:164-166 et 21-04-SUMMARY:174-176, même patron que les Phases
      13 / 17 / 19 / 20. Le gate `check-release-tag` de la CI est d'ailleurs conditionné à `main`
      — une branche de feature porte légitimement une VERSION non taggée.
warnings:
  - id: W1
    severity: robustesse — non bloquant
    statement: >
      `check-state-integrity.sh` n'est invoqué par AUCUN runner automatique sur le vrai
      `.planning/STATE.md`. La CI découvre bien sa SUITE (`*/tests/test-*.sh`), mais celle-ci ne
      teste que des dépôts git synthétiques ; `scripts/hooks/` ne contient que `pre-push`
      (discipline de tag). Or l'en-tête du gate écrit lui-même que « le point d'usage principal est
      un gate PRE-COMMIT : intercepter une régression AVANT qu'elle ne soit commitée par
      `gsd-tools state record-session` ». Le gate est donc armé mais jamais dégainé sans geste
      humain — exactement la posture qui a laissé l'incident du 2026-07-31 passer.
    suggestion: "Ajouter une étape `bash plugin/conductor/scripts/check-state-integrity.sh` au job `gates` de ci.yml (et/ou un hook pre-commit dans scripts/hooks/)."
  - id: W2
    severity: documentaire — non bloquant
    statement: >
      ADR-063 § Code Impacté annonce « 23 cas, 2 discriminations machine » pour
      `test-check-state-integrity.sh`. La suite en compte 25 (étendue par le commit de revue
      0b4820c : cas 4d `total_plans` seul, cas 5c milestone illisible d'un seul côté). Chiffre
      périmé dans une ADR validée.
    suggestion: "Recaler « 23 cas » en « 25 cas » dans docs/ADR.md § ADR-063."
  - id: W3
    severity: durabilité du constat — non bloquant
    statement: >
      Le recoupement demandé par le Changement 4 sur `#1995` (`agent-<id>` OU
      `worktree-agent-<id>`) et `#2608` (`staging_failed` / `staging_timeout`) a bien été fait et
      est JUSTE — vérifié indépendamment : `~/.claude/hooks/gsd-worktree-path-guard.js:2` porte
      `gsd-hook-version: 1.9.0` et `:169` documente le motif `agent-*` / legacy `worktree-agent-*`.
      Mais ce constat ne vit QUE dans `21-02-PLAN.md`/`21-02-SUMMARY.md`. Aucune trace dans
      `team-kernel.md`, `mission-contracts.md` ni `docs/ADR.md` — grep `staging_failed` sur
      `plugin/` + `docs/` : zéro occurrence. Au prochain delta gsd-core, personne ne retrouvera que
      la question a déjà été tranchée (contrairement au dispatch nommé, lui écrit en dur).
    suggestion: "Une ligne dans team-kernel.md (jumelle de celle du dispatch nommé) actant que le namespace de branche élargi et les cas staging_* sont internes à l'amont, vérifiés conformes le 2026-07-31."
  - id: W4
    severity: arête vive — non bloquant
    statement: >
      Sur le cas réel qui motive le Changement 1, `--verify` ne rend le bon verdict QUE si l'appel
      porte `--force`. Vérifié sur pièce : `inject-mcp-tools.sh --verify --target
      ~/.claude/agents/gsd-executor.md` → rc=3 INDÉTERMINÉ (« pas de ligne tools: exploitable »),
      parce que l'installeur amont réécrit ce fichier et efface le flag `vf-mcp-consumer: true`
      qui conditionne l'éligibilité en mode fichier unique. Le MÊME appel avec `--force` → rc=1 et
      nomme `mcp__XcodeBuildMCP__*`. La recette `/vf-calibrate` prescrit bien `--force` sur ce
      chemin précis, donc le contrat tient — mais un opérateur qui l'omet retombe sur le faux
      silence exact que la phase existe pour supprimer.
    suggestion: "Sur un rc=3 « pas de ligne tools: exploitable » en mode fichier unique SANS --force, ajouter une ligne indiquant que --force est requis pour un agent réécrit par l'amont."
behavior_unverified_items: []
human_verification: []
---

# Phase 21 : Alignement du moteur GSD sur gsd-core 1.9.0 — Rapport de vérification

**Goal ROADMAP** : faire coller VibeFlow à `@opengsd/gsd-core` 1.9.0 — réparer le seul défaut
actif, adopter les contrats amont qui créent une perte silencieuse, instruire les recouvrements
d'architecture, purger la dette de version — **puis publier une release racine**.

**Vérifié** : 2026-07-31T18:15:08Z · **Diff** : `c01f813..bd6e749` (19 commits)
**Verdict** : **PASS PARTIEL** — les 6 Changements et le point hérité sont livrés, éprouvés et
substantiels ; la couche de **clôture** de la phase (release racine, bumps de modules, tenue du
ROADMAP, gate `check-version-sync` rouge) manque.
**Re-vérification** : non — vérification initiale.

## Vérité par Changement

| # | Changement | Statut | Preuve |
|---|-----------|--------|--------|
| 1 | Injection MCP couvrant le scope global (`~/.claude.json`) | ✓ VERIFIED | `inject-mcp-tools.sh:173-212` fait l'UNION `./.mcp.json` + `~/.claude.json` (flag `--claude-json`, env `VF_CLAUDE_JSON`), dégradation indépendante par source, précédence projet > global sur collision. **Sonde réelle** (copie de `~/.claude/agents/gsd-executor.md` en zone temporaire, `--verify --force`) : **rc=1**, `serveur(s)/outil(s) MCP manquant(s) : mcp__AppleXcodeMCP__*, mcp__XcodeBuildMCP__*, mcp__mobile-mcp__*` — exactement le défaut décrit au ROADMAP, là où l'ancien code sortait en 3. `~/.claude.json` déclare bien `XcodeBuildMCP`, `AppleXcodeMCP`, `mobile-mcp` en scope global. Lecture seule confirmée (md5 identique avant/après). Suite : **36 OK / 0 KO**, dont T23 (global seul), T24 (union), T25 (précédence), T26 (JSON invalide), T27 (rc=1 jamais 3), T28 (rc=3 légitime), T29a/b–T31 (`--strict`). |
| 2 | Contrat `estimate:` / `actuals:` câblé dans les contrats de sortie | ✓ VERIFIED | `mission-contracts.md:119-155` — section dédiée, les **3 règles amont retranscrites sans affaiblissement** (`confidence` dérivée du nombre d'échantillons jamais auto-évaluée · même échelle `chars/4`, jamais un compteur du harness · aucun arrondi flatteur). Câblage effectif des deux côtés de la chaîne : `vf-coder.md:69-74` (deux champs optionnels frères du bloc typé ADR-053, recopiés **verbatim**, absents si absents en amont) et `vf-dev-manager.md:216-219` (relais verbatim, « aucune statistique agrégée de ton cru »). Le gabarit « Rapport de mission » gagne sa ligne `Calibration`. La perte silencieuse est bouchée bout en bout. |
| 3 | Arbitrage écrit du recouvrement avec les lanes de revue amont | ✓ VERIFIED | `docs/ADR.md:1097-1165` — **ADR-061**, enregistrée au registre (:33, statut Validée). Arbitrage **substantiel** : table d'options (statu quo / fusion / disjonction documentée), critère explicite à **3 axes factuels** (objet revu · moment du cycle · qui déclenche et qui relit), refus écrit du câblage automatique de `gsd-review` dans le DAG. Pointeur court dans `mission-contracts.md:156-163`. Ce n'est pas un arbitrage par omission. |
| 4 | Hypothèse du dispatch nommé (`namedDispatch`) écrite chez nous | ✓ VERIFIED | `plugin/conductor/references/team-kernel.md:25` — ligne de table nommant l'hypothèse, datée, avec la distinction amont `hostIntegration.dispatch.namedDispatch: true` (Claude Code / OpenCode / Cursor / Cline) vs built-in-only (kimi-code : `coder`/`explore`/`plan`), le constat vérifié `.gsd-runtime = claude`, et le refus explicite de bâtir un mécanisme de repli (sur-ingénierie). Volet `#1995`/`#2608` recoupé et juste, mais non durable → **W3**. |
| 5 | Purge de la dette de version 1.8.0 → 1.9.0 | ✓ VERIFIED | **Zéro occurrence de `1.8.0`** dans les 6 cibles nommées (grep sur `gsd-skills-index.md`, `build-gsd-index.sh`, `mission-contracts.md`, `check-gsd-engine.sh`, `detect-gsd-engine.sh`, `ensure-deps.sh` → rc=1). Remplacements effectifs : index **régénéré** (`@opengsd/gsd-core@1.9.0`, horodaté 2026-07-31T19:09:15+02:00), `build-gsd-index.sh:30` défaut `@1.9.0`, `mission-contracts.md:230` « tag stable = 1.9.0 », `check-gsd-engine.sh:25`, `detect-gsd-engine.sh:30`, `ensure-deps.sh:73`. Résidus hors périmètre par mandat : fixtures de test et historique (`docs/ADR.md:914`, CHANGELOG). |
| 6 | Arbitrage écrit des hooks 1.9.0 non câblés | ✓ VERIFIED | `docs/ADR.md:1166-1245` — **ADR-062**, enregistrée (:34). Chaque hook confronté **séparément à son propre contrat d'activation, avec preuve** : `gsd-update-banner.js` — son en-tête dit qu'il ne s'enregistre que si la statusline GSD est déclinée ; la statusline EST installée → absence **correcte**, le câbler serait une régression (double signal). `gsd-ensure-canonical-path.js` — répare l'install plugin-marketplace ; VibeFlow bootstrappe via `npx @opengsd/gsd-core@^1` (`ensure-deps.sh:263`), cas que le hook exclut lui-même. `merge-hooks.sh` **vérifié inchangé** (absent du diff de phase). Limite assumée écrite. Pointeur `dev-orchestrator/README.md:62`. |
| H | Point hérité — anomalie d'agrégation `.planning/STATE.md` | ✓ VERIFIED | Voir section dédiée ci-dessous. |
| G | Clause release racine du Goal | ✗ NON LIVRÉE (déférée) | `VERSION` = `v2.44.0` (valeur Phase 20), aucun tag `v2.45.x`. Report écrit et motivé, action humaine réservée à Samuel — voir `deferred`. |

**Score : 7/8 must-haves vérifiés.**

## Le piège de préservation — cas 8 de `test-check-gsd-engine.sh`

C'est le point de vigilance n°1 du mandat. Verdict : **le test a bougé avec le texte, il n'a été ni
affaibli ni neutralisé.**

Diff `c01f813..HEAD` sur `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` : **13
lignes**, toutes dans le cas 8. La transformation est un renommage 1:1 `c_180` → `c_190` avec la
**même expression** (`grep '^# ' "$SCRIPT" | grep -c '1\.9\.0'`) et le **même seuil** (`-ge 1`) sur
les **trois** assertions conservées (`1.42.3`, la version courante, `semver`). Aucune assertion
supprimée, aucune rendue toujours-vraie, aucun `|| true`. Un commentaire de 3 lignes a été **ajouté**
au-dessus, expliquant que ce cas doit voyager avec l'en-tête à chaque migration du poste et que la
leçon D-05 reste vraie quel que soit le numéro « aujourd'hui ».

Le **cas 7** (assertion structurelle : aucun `sort -V`, aucun `newer`, aucune comparaison numérique
de version hors commentaires dans le script) est **inchangé et vert** — la garde qui empêche
réellement la réintroduction du bug n'a pas été touchée.

**La leçon semver est écrite et vraie** : `check-gsd-engine.sh:23-30` — « le paquet legacy
`get-shit-done-cc` est FIGÉ à 1.42.3 tandis que le paquet vivant `@opengsd/gsd-core` est à 1.9.0
aujourd'hui. Donc **1.9.0 < 1.42.3 en semver** […] le classement ne compare AUCUN numéro, il ne
regarde QUE la présence des deux fichiers VERSION. » Le nom du paquet et le layout, jamais les
numéros.

Suite rejouée : **15 ok, 0 ko.**

## Le point hérité — `check-state-integrity.sh` est-il discriminant ?

Point de vigilance n°3 du mandat : un gate vert à vide ne vaut rien. **Éprouvé indépendamment de sa
propre suite**, dans un dépôt git jetable en zone temporaire (aucun fichier suivi touché) :

| Scénario | Attendu | Obtenu |
|---|---|---|
| STATE inchangé | 0 | **0** — « conforme (compteurs non régressés, 1 ligne `^Phase:`) » |
| Régression réelle du 2026-07-31 (11→10, 37→29, 53→49) | 1 | **1** — les **trois** champs nommés séparément, jamais seulement le premier |
| `STATE.md` **vide** | pas de vert | **2** — « milestone introuvable ou illisible — intégrité du frontmatter compromise » |
| `STATE.md` **absent** | pas de vert | **2** — « fichier introuvable » |
| Deux lignes `^Phase:` (cause B) | 1 | **1** — compte nommé + renvoi à ADR-063 |
| Changement de jalon (reset légitime) | 0 | **0** — invariant de compteur explicitement ignoré, avec log |

Le gate **échoue quand il doit échouer** et **fail-closed** sur un fichier vide, absent ou tronqué —
il n'est vert ni à vide ni par absence de cible. Deux gardes anti-désarmement sont écrites et
tenues : une `--against` mal orthographiée sort en 2 (usage invalide) plutôt qu'en « rien à
comparer », et un `milestone:` illisible d'UN SEUL côté sort en 2 plutôt qu'en skip silencieux.
`total_plans` figure bien dans les 4 champs protégés (correctif de revue 0b4820c) — sans quoi le
script aurait contredit sa propre promesse d'en-tête.

Suite dédiée rejouée : **25 ok, 0 ko** (dont 2 discriminations machine par comparaison directe de
codes de retour). Le vrai `.planning/STATE.md` du dépôt **passe le gate** : 1 ligne `^Phase:`,
5 sections archivées reformées en `**Phase archivée :**`, frontmatter recalé.

**ADR-063** (`docs/ADR.md:1247-1405`, enregistrée :35) est substantielle : aucun patch du paquet
tiers, distinction Cause A / Cause B, **interdiction écrite d'invoquer `gsd-tools state <verbe>`
pour « réparer » `STATE.md`** (avec la mécanique : `resync: true` non désactivable →
régénère la régression), propagée là où un agent la lira (`mission-contracts.md:165-174`), deux
signalements amont rédigés avec références de ligne, et le backfill des `SUMMARY.md` manquants
**explicitement remonté à Samuel** plutôt que tranché seul. Réserve : **W1** (le gate n'est jamais
dégainé automatiquement) et **W2** (« 23 cas » périmé).

## Gates et suites rejoués

| Gate / suite | Commande | Résultat |
|---|---|---|
| Suite `inject-mcp-tools` | `bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` | **36 OK / 0 KO** |
| Suite `check-gsd-engine` | `bash plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` | **15 ok / 0 ko** |
| Suite `check-state-integrity` | `bash plugin/conductor/scripts/tests/test-check-state-integrity.sh` | **25 ok / 0 ko** |
| `check-agents --strict` (par module) | boucle CI sur `plugin/*/agents` | **vert**, 0 échec |
| `check-agents --resolve-agents=strict` (monde fermé) | boucle CI + registres | **vert**, 0 échec |
| `check-version-sync` | `bash scripts/check-version-sync.sh` | **rc=1 — ROUGE** (2 lignes : « 44 suites » ≠ 45) |
| `check-state-integrity` sur le vrai STATE | `bash plugin/conductor/scripts/check-state-integrity.sh` | **rc=0 conforme** |

## Densité (ADR-029) et anti-patterns

| Fichier touché | Lignes | Plafond | Statut |
|---|---|---|---|
| `plugin/dev-orchestrator/agents/vf-coder.md` | 74 | 250 | ✓ |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` | 222 | 250 | ✓ |
| `plugin/conductor/skills/vf-calibrate/SKILL.md` | 120 | 500 | ✓ |

Aucun marqueur de dette (`TBD`, `FIXME`, `XXX`) dans les fichiers modifiés par la phase sous
`plugin/` et `docs/`. Le seul `TBD` restant est dans `.planning/ROADMAP.md` § Phase 21 — c'est le
gap de tenue de feuille de route ci-dessus, pas un marqueur de code.

## Synthèse des correctifs à commander

1. **`README.md` / `README.fr.md`** : 44 → 45 suites (4 occurrences) — remet la CI au vert.
   Ré-enregistrer la dette au ledger `WINDOWS.md` si le geste est de nouveau différé à la release.
2. **Nœud de clôture manquant** : bumper `dev-orchestrator` (v2.9.0 — changement de contrat
   d'agent) et `planning-core` (patch), avec `VERSION` / `module.json` / `CHANGELOG.md` /
   en-tête Version du README. La Phase 20 avait 20-07 pour cela ; la 21 n'a rien.
3. **`.planning/ROADMAP.md` § Phase 21** : lister les 4 plans exécutés, passer « Plans: 4 plans »,
   et trancher le `Requirements: TBD` (mapping ledger ou renoncement écrit).
4. **W1** : câbler `check-state-integrity.sh` au job `gates` de la CI (et/ou en pre-commit) — un
   gate anti-régression jamais dégainé ne protège rien.
5. **W2** : ADR-063 « 23 cas » → 25 cas.
6. **W3** : durcir le constat `#1995` / `#2608` dans `team-kernel.md` pour qu'il survive au
   prochain delta.
7. **W4** : message d'aide sur le rc=3 « pas de ligne `tools:` exploitable » en mode fichier unique
   sans `--force`.
8. **Release racine** (réservée à Samuel, post-fusion) : bump des 3 fichiers + historique des 2
   README, tag annoté poussé, release GitHub, `check-release-tag.sh --remote` ✓.

---

_Vérifié : 2026-07-31T18:15:08Z_
_Vérificateur : Claude (gsd-verifier) — analyse goal-backward, sondes exécutées en zone temporaire_
