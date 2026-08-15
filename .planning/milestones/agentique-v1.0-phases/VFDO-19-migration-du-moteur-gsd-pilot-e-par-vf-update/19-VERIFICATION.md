---
phase: VFDO-19-migration-du-moteur-gsd-pilot-e-par-vf-update
verified: 2026-07-28T13:31:08Z
status: human_needed
verdict: PASS
score: 6/7 must-haves verified (1 présent-non-éprouvé — SC2 ; la part release de SC7 déférée)
behavior_unverified: 1
overrides_applied: 0
diff_verified: f9a0f45..94587c5 (plugin/) — correctif du gap : 94587c5
re_verification:
  previous_status: gaps_found
  previous_verdict: PARTIAL
  previous_score: 5/7
  gaps_closed:
    - "SC3 — 2e clause : vérification après coup du tools: de gsd-executor, « c'est dit fort » si un serveur déclaré manque"
  gaps_remaining: []
  regressions: []
  evidence:
    - "Mutation C (suppression complète du bloc --verify) : 73 OK / 0 KO AVANT → 73 OK / 1 KO APRÈS. Létale."
    - "Mutation D (retrait du seul --force sur l'appel --verify, retour exact à l'état pré-correctif) : 73 OK / 1 KO. Létale."
    - "Mutation E (branche rc=1 rendue muette — verdict calculé mais non relayé) : 73 OK / 1 KO. Létale."
    - "Sonde 1 (lab AVEC .mcp.json, injecteur réel) : injection ✓, verify SILENCIEUX. Forme exacte de prod rejouée → rc=0 « conforme, tous les serveurs attendus sont presents (mcp__test-lab-mcp__*) ». La MÊME commande sans --force → rc=3 « aucune cible determinee »."
    - "Sonde 2 (lab SANS .mcp.json) : plus aucun [ensure-deps] ERROR: — une seule ligne log informative « vérification MCP indéterminée (rien à comparer — voir détail) »."
deferred:
  - truth: "SC7 — release racine + tag annoté poussé + check-release-tag.sh --remote ✓"
    addressed_in: "Commit de release racine, post-phase"
    evidence: "Déféré explicitement par le mandat de vérification — décision humaine hors périmètre de la phase (patron des Phases 13 et 17)"
  - truth: "Compteur « N suites » des deux README racine (41 annoncé vs 42 réel)"
    addressed_in: "Commit de release racine, post-phase"
    evidence: "check-version-sync.sh rejoué : 12 ✓ dont les 17 triades par module ; seuls les 2 contrôles de compteur README sont rouges — inchangé par le correctif (aucune nouvelle suite ajoutée, 42 avant comme après)"
warnings:
  - id: W1
    severity: cosmétique — non bloquant
    statement: >
      Sur un lab sans .mcp.json, le jeton littéral « ERROR: » subsiste UNE fois par bootstrap — mais
      il provient du message propre à inject-mcp-tools.sh (`ERROR: --verify : ./.mcp.json
      introuvable — verdict INDETERMINE (rien a comparer)`), cité verbatim dans la ligne de détail.
      L'alarme d'ensure-deps, elle, a bien disparu : le préfixe `[ensure-deps] ERROR:` n'est plus
      émis, la ligne d'en-tête est un `log` qui qualifie explicitement le verdict d'indéterminé.
      Le point exact du gap (« seul le 1 mérite ERROR, le 3 mérite au plus une ligne log ») est donc
      tenu au niveau du relais ; il resterait à adoucir le vocabulaire de l'injecteur lui-même.
    suggestion: "Dans inject-mcp-tools.sh, émettre les verdicts rc=3 via log (ou un préfixe NOTE:) plutôt que err — le mot ERROR pour un « rien à comparer » reste trompeur à la lecture."
  - id: W2
    severity: couverture de test — non bloquant
    statement: >
      La MOITIÉ « rc=3 n'est pas une alarme » du contrat F13 n'est couverte par AUCUN test.
      Mutation F (rétablissement de `err` sur la branche rc=3) : 74 OK / 0 KO · 12 OK / 0 KO ·
      15 ok / 0 ko — SURVÉCUE sur les trois suites. T2m n'exerce que la branche rc=1.
      Ce comportement est donc établi ici par exécution (sonde 2), pas gardé par la suite.
    suggestion: "Ajouter un cas jumeau de T2m (lab sans .mcp.json → aucune ligne portant le préfixe `[ensure-deps] ERROR:`)."
behavior_unverified_items:
  - truth: "SC2 — /vf-update dit l'état du moteur dans le même récapitulatif et propose la migration comme une ligne de plus dans AskUserQuestion, refusable indépendamment et sans effet de bord"
    test: "Sur un poste réellement legacy (~/.claude/get-shit-done/VERSION présent, pas de ~/.claude/gsd-core/VERSION), lancer /vf-update. Puis refaire l'exercice en REFUSANT la ligne moteur."
    expected: "Étape 1 combine les deux volets (« plugin à jour (vX.Y.Z), moteur GSD legacy 1.42.3 → @opengsd/gsd-core à migrer ») et ne s'arrête PAS même si le plugin est à jour ; étape 3 pose une ligne moteur distincte dans le même AskUserQuestion ; un refus n'exécute rien, ne relance pas la question et laisse ~/.claude/get-shit-done intact ; un accord route vers `ensure-deps.sh --migrate-engine` et jamais vers l'installeur amont."
    why_human: "SC2 porte sur le comportement d'un agent lisant SKILL.md — aucun test ne peut l'exercer. Le contrat d'exit du gate (0/2/3) est prouvé par test-check-gsd-engine (cas 2, 4, 11), mais le rendu du récapitulatif et la ligne AskUserQuestion ne sont observables qu'en session réelle. La suite conductor test-vf-update.sh (9 OK) est restée intouchée par la phase et n'asserte rien du nouveau volet."
human_verification:
  - test: "Voir behavior_unverified_items ci-dessus — parcours /vf-update sur poste legacy, acceptation puis refus"
    expected: "Deux volets dans le récapitulatif, ligne moteur indépendante, refus sans effet de bord"
    why_human: "Comportement d'agent piloté par SKILL.md, non exerçable par un test"
---

# Phase 19 : Migration du moteur GSD pilotée par /vf-update — Rapport de vérification

**Goal** : faire que la migration `get-shit-done-cc` → `@opengsd/gsd-core` livrée en v2.39.0 atteigne
les postes **déjà équipés**, via `/vf-update`, sans jamais migrer en silence.
**Vérifié** : 2026-07-28T13:31:08Z (re-vérification ciblée) · **Périmètre** : `f9a0f45..94587c5`
**Verdict** : **PASS** — les 7 critères sont tenus ; SC2 reste, par nature, une vérification humaine
(comportement d'agent), maintenue à la demande du mandat ; 2 items explicitement déférés.
**Re-vérification** : **oui** — après correctif `94587c5` sur le BLOCKER SC3 (2e clause).
Verdict précédent : PARTIAL, 5/7, 1 BLOCKER.

## Statut du gap — SC3, 2e clause : levé

Le gap précédent tenait en trois pièces indissociables. Les trois sont désormais établies **par
exécution de ma part**, pas par lecture du correctif.

### 1. La cible est enfin retenue — le verdict devient possible

Preuve la plus directe : la **même** commande, sur le **même** fichier, dans le **même** lab, avec
et sans le flag ajouté.

```
== forme EXACTE émise par la prod (ensure-deps.sh:414), rejouée sur le fichier injecté ==
[inject-mcp-tools] --verify : conforme, tous les serveurs attendus sont presents (mcp__test-lab-mcp__*).
rc=0

== contrefactuel : la MÊME commande SANS --force (ce que la prod émettait avant 94587c5) ==
[inject-mcp-tools] ERROR: --verify : aucune cible determinee (pas de ligne tools: exploitable) — verdict INDETERMINE.
rc=3
```

Le verdict `0` (conforme) était **structurellement inatteignable** en production ; il l'est
maintenant. Le `--force` n'est pas cosmétique : il est ce qui distingue « je ne sais pas » de
« je sais, et c'est bon ».

### 2. La mutation qui avait survécu est devenue létale — mesurée trois fois

| # | Mutation appliquée par moi (in-repo, restaurée à l'identique) | Avant correctif | Après correctif | Lecture |
| --- | --- | --- | --- | --- |
| **C** | suppression **complète** du bloc de vérification après coup (`# SC3/D-09` + le `if` entier, 21 lignes) | **73 OK / 0 KO** (survécue) | **73 OK / 1 KO** | **létale** — le filet existe |
| **D** | retrait du seul `--force` de l'appel `--verify` (état exact d'avant `94587c5`) | n/a | **73 OK / 1 KO** | **létale** — la régression précise est gardée |
| **E** | branche `rc=1` rendue muette (`err` → `:`) : le verdict est calculé mais plus relayé | n/a | **73 OK / 1 KO** | **létale** — c'est bien le *relais fort* qui est asserté, pas le calcul |
| **F** | branche `rc=3` re-alarmée (`log` → `err`) : la moitié « pas d'alarme » du contrat F13 annulée | n/a | **74 OK / 0 KO** · 12/0 · 15/0 | **survécue** → W2 |

Chaque mutant passait `bash -n`. Après chaque passe, `git checkout --` puis
`git status --short plugin/` **vide** — le dépôt finit propre (seuls fichiers non suivis en fin de
course : `.planning/missions/dag-phase19.json`, déjà présent au départ, et ce rapport).

### 3. Les sondes de production disent la vérité — sortie brute

**Sonde 1 — lab AVEC `.mcp.json`, injecteur réel, agent non encore injecté :**

```
[ensure-deps] Bootstrap dépendances (mode=apply)
[ensure-deps] GSD déjà présent (skip).
[ensure-deps] Superpowers déjà présent (skip).
[inject-mcp-tools] gsd-executor.md : injecte mcp__test-lab-mcp__*
[inject-mcp-tools] termine : 1 fichier(s) modifie(s), serveurs = [test-lab-mcp].
[ensure-deps] gsd-executor : serveurs MCP du lab injectés dans son tools: (ADR-051) → …/gsd-executor.md
[ensure-deps] Résumé : GSD=présent ; Superpowers=présent
```

`tools:` final : `Read, Write, Edit, Bash, Grep, Glob, mcp__context7__*, mcp__test-lab-mcp__*`.
**Aucune ligne de vérification** — c'est le contrat `rc=0` : conforme, silencieux. À comparer à la
sortie d'avant le correctif, que j'avais relevée dans la version PARTIAL de ce rapport :
`ERROR … signale un écart (rc=3) … aucune cible determinee`. **L'alarme a disparu, et elle a
disparu parce que le verdict est devenu bon, pas parce qu'on l'a tue.**

**Sonde 2 — lab SANS `.mcp.json` (le cas le plus courant) :**

```
[ensure-deps] Bootstrap dépendances (mode=apply)
[ensure-deps] GSD déjà présent (skip).
[ensure-deps] Superpowers déjà présent (skip).
[inject-mcp-tools] pas de ./.mcp.json dans le lab — aucun serveur MCP a injecter (no-op).
[ensure-deps] gsd-executor : serveurs MCP du lab injectés dans son tools: (ADR-051) → …/gsd-executor.md
[ensure-deps] gsd-executor : vérification MCP indéterminée (rien à comparer — voir détail) :
[ensure-deps] [inject-mcp-tools] ERROR: --verify : ./.mcp.json introuvable — verdict INDETERMINE (rien a comparer).
[ensure-deps] Résumé : GSD=présent ; Superpowers=présent
```

Avant : `[ensure-deps] ERROR: … signale un écart (rc=3)` — le loup crié à chaque bootstrap. Après :
une ligne `log` qui **nomme** l'indétermination. `err()` préfixe `[ensure-deps] ERROR:` (`:102-104`),
`log()` ne le fait pas (`:98-100`) : le passage de l'un à l'autre est bien un changement de sévérité,
pas d'habillage. Le mot `ERROR` qui subsiste appartient au message propre de l'injecteur, cité
verbatim dans le détail — **W1**, cosmétique, consigné et non bloquant.

### 4. T2m est-il discriminant, ou vert par construction ?

**Discriminant.** Trois arguments, dont deux mesurés :

1. Il meurt sur les mutations **C**, **D** et **E** — trois façons différentes de casser le
   comportement qu'il prétend garder (bloc absent / cible écartée / verdict non relayé). Un test
   tautologique ne meurt d'aucune.
2. Il n'invoque **jamais** `inject-mcp-tools.sh --force --verify` à la main : il copie
   `ensure-deps.sh` à côté d'un stub d'injecteur co-localisé (résolution par `dirname "$0"`) et
   lance le **vrai** `main()`. Le seul code d'`ensure-deps.sh` exercé est le sien — c'est
   exactement le chaînage que l'ancien T10/T11 ne touchait pas, et l'angle mort qui m'avait échappé.
3. Ses deux assertions ne peuvent être satisfaites par le stub : le stub d'injection est un **no-op
   silencieux** (`exit 0`, aucune sortie), donc le jeton `mcp__test-lab-mcp__*` présent dans la
   sortie ne peut venir que du **vrai** injecteur en `--verify`. Le test lit un verdict réel, pas
   une chaîne préfabriquée.

Il tourne réellement (`0 SKIP` — `python3` présent ; la garde `skip` ne masque rien ici).

Sa limite est bornée et consignée : il n'exerce que `rc=1`. La branche `rc=3` reste non gardée
(**W2**) — établie par la sonde 2, pas par la suite.

## Atteinte du goal — critère par critère

| # | Critère | Statut | Preuve |
| --- | --- | --- | --- |
| 1 | `detect_gsd()` → état à 3 valeurs, `legacy` actionnable, aucune comparaison de numéros | ✓ VERIFIED | `ensure-deps.sh:170-178` · `:183-185` · `:226-231` · `check-gsd-engine.sh:87-95` · tests 2/5/6/7 + T2g A/B/C · mutations A et B létales (vérif initiale) · **non régressé** : aucune ligne de ce périmètre ne figure au diff `c8fd11e..HEAD` |
| 2 | `/vf-update` dit l'état du moteur et propose la migration en une ligne de plus d'`AskUserQuestion` | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `vf-update/SKILL.md:30-38`, `:48-70`, `:80-87`, `:110-114`, `:123-131` + `docs/ADR.md:858` (ADR-058). Contrat d'exit du gate prouvé (0/2/3, tests 2/4/11). Aucun test n'exerce le rendu agent → item de vérification humaine, **maintenu par le mandat** |
| 3 | Toute (ré)install du moteur enchaîne sur `inject-mcp-tools.sh --force` pour `gsd-executor`, **avec vérification après coup** qui dit fort ce qui manque | ✓ **VERIFIED** *(était ✗ FAILED)* | **1re clause ✓** : `:445` (appel inconditionnel dans `main()`) · `:390-396` · T2h · sonde 1 : `tools:` final porte `mcp__test-lab-mcp__*`. **2e clause ✓** : `:414` porte désormais `--force` → verdict atteignable, prouvé par le couple avec/sans `--force` (rc=0 vs rc=3) sur le même fichier · contrat F13 : `rc=1` → `err` (sonde T2m), `rc=3` → `log` (sonde 2), `rc=0` → silence (sonde 1) · **mutations C, D, E létales** |
| 4 | Message de nettoyage legacy **atteignable** et **exact** | ✓ VERIFIED | `:199-208` · `:297-309` (`npm uninstall`/`rm -rf`/`find -empty -delete` **affichés, jamais exécutés**) · appelé sur les 6 retours d'`ensure_gsd()` · T2d/T2i/T2j/T2k · mutation A létale · **non régressé** |
| 5 | Non-régression : couple exact `1.42.3 → 1.8.0` classé « à migrer » + cohabitation réelle | ✓ VERIFIED | `test-check-gsd-engine.sh` cas 2/5/6/7/8/9 — rejoué ici : **15 ok, 0 ko** · mutation B létale |
| 6 | Repli legacy préservé (cascade 4 niveaux) · plafond `@^1` inchangé | ✓ VERIFIED | `build-gsd-index.sh` absent du diff de phase · cascade `:33-46` · T1b, T2f · `:263`/`:272` portent `@opengsd/gsd-core@^1` · **non régressé** |
| 7 | Gouvernance : `check-agents.sh` vert, densité ADR-029, portabilité prouvée, modules bumpés | ✓ VERIFIED (part release **déférée**) | `check-agents.sh --strict` rejoué sur les 6 dossiers `plugin/*/agents` : **6/6 ✓** · `check-version-sync.sh` rejoué : **12 ✓ dont 17/17 triades**, 2 ✗ = compteur README (déféré, inchangé : 42 suites avant comme après) · `dev-orchestrator` reste **v2.7.0** — le correctif n'ouvre **aucune** nouvelle version, sa section « Corrigé » se range sous l'entrée v2.7.0 existante (`CHANGELOG.md:3` / `:31`) |

**Score : 6/7** vérifiés *(était 5/7)* · 0 échec · 1 présent-non-éprouvé (SC2) · 2 items déférés ·
2 warnings non bloquants.

## Ce que j'ai exécuté moi-même dans cette passe (pas relu — lancé)

Poste : macOS, `GNU bash 3.2.57(1)-release (arm64-apple-darwin25)`.

| Commande | Sortie | Δ vs passe initiale |
| --- | --- | --- |
| `bash …/tests/test-dev-orchestrator.sh` | `== résultat : 74 OK / 0 KO / 0 SKIP ==` | **+1 OK** (T2m) |
| `bash …/tests/test-inject-mcp-tools.sh` | `Bilan : 12 OK, 0 KO` | identique |
| `bash …/tests/test-check-gsd-engine.sh` | `== résultat : 15 ok, 0 ko ==` | identique |
| `bash plugin/conductor/scripts/tests/test-vf-update.sh` | `== Résultat : 9 OK · 0 KO ==` | identique |
| `check-agents.sh --strict --agents-dir=$d` × 6 modules | `✓ agents conformes` × 6 | identique |
| `bash scripts/check-version-sync.sh` | 12 ✓ · 2 ✗ (compteur README, déféré) | identique |
| `bash -n` sur `ensure-deps.sh`, `test-dev-orchestrator.sh`, `inject-mcp-tools.sh`, `check-gsd-engine.sh` | 4/4 OK | — |
| `grep -nE 'TBD\|FIXME\|XXX\|HACK\|PLACEHOLDER\|TODO'` sur les 2 fichiers de code du correctif | aucun marqueur | identique |
| Mutations **C / D / E / F** + restauration | voir tableau §2 | **le point du mandat** |
| Sondes 1 et 2 + contrefactuel `--force` | voir §1 et §3 | **le point du mandat** |

## Rien d'autre n'a bougé

`git diff --name-only c8fd11e..HEAD -- plugin/` rend exactement **trois** fichiers :
`CHANGELOG.md`, `ensure-deps.sh`, `tests/test-dev-orchestrator.sh`. Et sur `ensure-deps.sh`, le
diff **hors commentaires** tient en cinq lignes, toutes dans le bloc de vérification :

```
-    verify_out="$(bash "$injector" … --verify 2>&1 >/dev/null)"
+    verify_out="$(bash "$injector" … --force --verify 2>&1 >/dev/null)"
-    if [ "$verify_rc" -ne 0 ]; then
-      err "… signale un écart (rc=$verify_rc) :"
+    if [ "$verify_rc" -eq 1 ]; then
+      err "… signale un écart réel (serveur manquant) :"
+    elif [ "$verify_rc" -eq 3 ]; then
+      log "… vérification MCP indéterminée (rien à comparer — voir détail) :"
+      log "$verify_out"
```

Aucun `VERSION`, aucun `module.json`, aucun `SKILL.md`, aucun `AGENT.md` touché — les surfaces des
critères 1, 2, 4, 5, 6 sont littéralement inchangées, et les suites qui les gardent sont au vert à
l'identique. Le correctif tient dans son périmètre.

## Liens critiques

| De | Vers | Via | Statut |
| --- | --- | --- | --- |
| `vf-update/SKILL.md:50` | `check-gsd-engine.sh` | `bash <S-moteur>/check-gsd-engine.sh --quiet`, cascade 3 positions | ✓ CÂBLÉ (contrat d'exit 0/2/3 prouvé ; rendu agent non éprouvable) |
| `vf-update/SKILL.md:111` | `ensure-deps.sh --migrate-engine` | étape 4c, sur acceptation seulement | ✓ CÂBLÉ (T2g A/C) |
| `ensure-deps.sh:445` | `inject-mcp-tools.sh --force` | `patch_gsd_executor_mcp()` dans `main()` | ✓ CÂBLÉ (T2h + sonde 1) |
| `ensure-deps.sh:414` | `inject-mcp-tools.sh --force --verify` | vérification après coup | ✓ **CÂBLÉ ET OPÉRANT** (rc=0/1/3 tous atteignables et distingués — sondes 1, 2 et T2m ; 3 mutations létales) |
| `ensure_gsd()` (tous retours) | `log_legacy_cleanup_if_needed()` | état capturé en tête | ✓ CÂBLÉ (T2k) |

## Anti-patterns

Aucun marqueur de dette dans les fichiers livrés. Aucune commande destructrice exécutée.

Deux points d'attribution, tous deux **antérieurs à la phase et délibérément hors périmètre** :

- `:398` « serveurs MCP du lab injectés » s'affiche même quand il n'y avait aucun serveur à injecter
  (visible tel quel dans la sonde 2). `patch_gsd_executor_mcp()` est antérieure à la phase ;
  l'extension de périmètre a été refusée. Non imputé.
- Le vocabulaire `ERROR:` de l'injecteur sur un verdict `rc=3` (**W1**) : `--verify` est bien une
  livraison de la phase, mais le point du gap portait sur le **relais** d'`ensure-deps.sh`, et ce
  relais est corrigé. Cosmétique, consigné, non bloquant.

## Écart de méthode — clos

Le `19-02-SUMMARY` (`:141`) justifiait le câblage par `grep -c 'verify' → 7` : un contrôle de
**présence**, pas de **comportement**. La correction post-hoc datée du 2026-07-28 barre la preuve
fautive, explique pourquoi elle ne prouvait rien, nomme l'angle mort (T10/T11 exerçaient une forme
que la production n'émettait pas) et renvoie à T2m — sans réécrire l'historique. C'est la bonne
façon de solder une preuve creuse : on ne l'efface pas, on la marque.

## Résumé

Le BLOCKER est levé, et il l'est pour la bonne raison. Le garde-fou de SC3 ne se contente pas de ne
plus crier au loup : il **peut désormais rendre un verdict**, ce qu'il ne pouvait structurellement
pas faire avant. Je l'ai établi par le contrefactuel le plus serré possible — même fichier, même
lab, même commande, `--force` en seule variable : `rc=0 conforme` d'un côté, `rc=3 aucune cible
determinee` de l'autre. Et le filet qui manquait existe : la mutation qui survivait silencieusement
tue maintenant la suite, tout comme deux autres façons de casser le même comportement.

Le contrat de relais F13 est tenu aux trois valeurs : silence quand c'est conforme, ligne
informative quand il n'y a rien à comparer, alarme quand un serveur déclaré manque réellement. Le
signal utile n'est plus noyé.

Restent deux réserves honnêtes, aucune bloquante : le mot `ERROR` de l'injecteur subsiste dans la
ligne de détail d'un verdict indéterminé (W1), et la moitié « ne pas alarmer » du contrat n'est
gardée par aucun test — mutation F survécue (W2). Elles ne remettent pas en cause l'atteinte du
critère, établie ici par exécution ; elles disent où le filet est encore mince.

**Verdict : PASS**, sous la seule réserve de la vérification humaine de SC2 — parcours `/vf-update`
sur poste legacy, acceptation **puis** refus — maintenue telle quelle par le mandat, plus les deux
items explicitement déférés au commit de release racine.

---

_Vérifié : 2026-07-28T13:31:08Z — aucun commit, aucun push, aucune modification de code persistante
(4 mutations appliquées puis restaurées à l'identique, `git status` propre en fin de course), aucun
fichier écrit hors celui-ci._
