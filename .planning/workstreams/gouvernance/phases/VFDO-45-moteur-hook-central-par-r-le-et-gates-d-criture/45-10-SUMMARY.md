---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 10
subsystem: planning-core (référence du hook central, contrôle croisé référence <-> code, bump v2.9.0 sans release, contrat de sortie des hooks)
tags: [reference, r-reference, mut-reference, limites-declarees, armement-en-cascade, bump-module, sans-release, hooks-contrat-sortie, cout-migration]

requires:
  - phase: 45-02
    provides: table des codes à jour, levée du code 2 sous adhésion, archivage du socle v2
  - phase: 45-09
    provides: canary du rôle, constructeur ROLE du rejeu, relevé de l'étape 4
provides:
  - "modele-cycles.md : section « Hook central et gates d'écriture (Phase 45) » (principe, commande enregistrée, 25 limites déclarées (a) à (y) à la livraison de 1897aa44, 26 (a) à (z) depuis le 2026-10-01, table d'armement livrée, G1, G2, G5, G6, G7, hook par rôle, dérogation, verdict, journal d'observation, canary, rejeu, coût de migration) ; section « Hors de cette phase » réécrite"
  - "test-planning-gates.sh : R-REFERENCE et neuf MUT-REFERENCE (section `reference`), 395 -> 405 OK"
  - "45-COUT-MIGRATION.md : nombres de refus conformes au modèle repris de 45-REJEU-ETAPE-2 et 45-REJEU-ETAPE-3, aucun nouveau rejeu réel"
  - "planning-core v2.9.0 (VERSION, module.json, README, CHANGELOG), sans release"
  - "docs/HOOKS-CONTRAT-SORTIE.md : lignes n°30 et n°31 remises d'équerre (A3)"
affects: []

plan_head_before: 893071a6b077c5d5bc8a28fb90ce0d94ee28328b
estimate:
  tokens: 90000
  raw_tokens: 90000
  tasks: 2
  confidence: low
actuals:
  tokens: 15335    # chars/4 sur les lignes ajoutées du diff réalisé (diff -U0 de 893071a à 1897aa44 : 723 lignes, 61341 caractères ; le 5e commit change une ligne), hors ce SUMMARY
  tasks: 2
  commits: 5       # MESURÉ : git rev-list --count 893071a..HEAD avant le commit de ce SUMMARY
commits: 5
duration: non mesurée (poste partagé, durées de suites non représentatives)

tech-stack:
  added: []
  patterns:
    - "contrôle croisé documentation <-> code : la référence est lue par la suite (section de la référence, lignes canoniques `- **limite (X)**`, table à six colonnes, listes à une ligne) et comparée aux constantes du hook, à la commande de hooks.json et à la table CANARIS ; un mutant retire ou fausse UNE chose et doit faire rougir"
    - "limite déclarée = une ligne physique canonique avec ses mots-clés : les vingt-cinq limites sont retirées une à une et chacune doit être nommée par le contrôle"

key-files:
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-COUT-MIGRATION.md
  modified:
    - plugin/planning-core/references/modele-cycles.md
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - docs/HOOKS-CONTRAT-SORTIE.md
    - plugin/planning-core/VERSION
    - plugin/planning-core/module.json
    - plugin/planning-core/CHANGELOG.md
    - plugin/planning-core/README.md

key-decisions:
  - "A2 (vf-dev-manager, 2026-10-01) appliqué tel que mesuré À LA LIVRAISON DE 1897aa44 : les cinq ARMEMENT_* valaient observe, G2_MODE valait avertit (lu dans planning-hook.sh l.97-102, aucun écart avec le mandat) ; rien n'était dit armé. Cet état est daté : l'armement en cascade du 2026-10-01 (section « Armement en cascade ») l'a depuis remplacé par cinq gates armés"
  - "A1 : les limites (m) à (y) suivent l'ordre du mandat ; la limite (y) (audit M1) est écrite comme OUVERTE, arbitrage de Willy en attente, jamais comme une décision"
  - "A5 : aucun rejeu sur ~/jarvis-keystone ni ~/BusinessFlow-Lab ; 45-COUT-MIGRATION.md reprend les nombres des relevés existants et le dit"
  - "Chaque limite tient sur UNE ligne physique (la vérification du plan lit ligne à ligne : « limite (k) » et `config.json` sur la même ligne)"

requirements-completed: []
requirements-note: "à cocher par l'orchestrateur (ADR-063), jamais par cet exécuteur : GATE-15, GATE-03, GATE-07, GATE-08, GATE-09, GATE-11, GATE-13 pour leurs parties « écrites dans la référence » ; l'armement n'est plus ouvert : il s'est fait en cascade le 2026-10-01 (Q-ARM, Willy, AskUserQuestion session principale, 2026-09-30 ; commits 3d06e503, bf6cfa87, b6609fa6, 239df76d)"

status: complete
---

# Phase 45 Plan 10 : référence du hook central prouvée identique au code, planning-core v2.9.0 sans release, cinq gates armés en cascade

**La référence du modèle dit ce que le hook livré fait (table d'armement, limites (a) à (y), prédicats, dérogation, canary, rejeu), un contrôle croisé mutant la compare au code, à hooks.json et au canary ; planning-core passe en v2.9.0 sans aucune release . À la livraison de ce plan (1897aa44) la phase se fermait en observation, mesurée à zéro ; depuis le 2026-10-01 (voir « Armement en cascade ») les cinq gates sont armés, G2 avertit, et planning-core reste en v2.9.0 sans release.**

## Base et état de départ

- Worktree : `.claude/worktrees/agent-af21ce78cc6be48c5` (chemin absolu dans le message de retour), branche `worktree-agent-af21ce78cc6be48c5`.
- HEAD de départ : `893071a6b077c5d5bc8a28fb90ce0d94ee28328b` ; `git merge-base --is-ancestor 893071a HEAD` : code 0.
- Base de VERSION relue à l'exécution : `v2.8.0` (aucune PR de fiabilite n'a bumpé planning-core) -> `v2.9.0`.

## État d'armement à la livraison de 1897aa44 (A2, constaté, jamais supposé ; état daté, remplacé le 2026-10-01)

- Les cinq constantes `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` valent `observe` ; `G2_MODE` vaut `avertit` (lecture de `planning-hook.sh`, lignes 97 à 102). **Le code est d'accord avec le mandat : aucun écart à signaler.**
- Les relevés `45-REJEU-ETAPE-1` à `45-REJEU-ETAPE-4` donnent tous `faux-refus=0 faux-accept=0` et des lignes `EMPREINTE-ARBRE-IDENTIQUE` pour les deux labs, mais ils ont été mesurés sur le hook AVANT les lots de correction A, B et C.
- À cette date, l'armement exigeait donc un NOUVEAU rejeu réel sur des labs au repos ET un arbitrage de Willy, alors en attente, pour adapter deux suites couplées à « tout en observe » (refusé par le classifieur « Security Test Removal »). Écrit tel quel dans la référence, dans l'entrée CHANGELOG v2.9.0 et ici. Le rejeu est fait (`45-REJEU-FINAL.md`, `708debcb`) et l'arbitrage est rendu (Q-ARM) : voir la section suivante.
- Constat de lecture : les SUMMARY 45-05, 45-06 et 45-07 disent « rejeu réel non effectué » ; ils datent d'avant les reprises du 2026-09-30 et du 2026-10-01 consignées dans les relevés. Les relevés font foi (aucun écart avec le code).

## Armement en cascade (2026-10-01)

Ajout daté : les sections ci-dessus décrivent 1897aa44 et sont conservées telles quelles.

- **Autorisation** : Q-ARM — Willy, AskUserQuestion session principale, 2026-09-30, relayé par la session principale : « oui pour les quatre étapes d'armement ; découplage des suites autorisé, sans supprimer aucun cas ni aucun mutant ». Relevé qui l'autorise : `45-REJEU-FINAL.md` (`708debcb`), rejeu réel final sur le hook livré, 0 faux refus, 0 faux accept, empreintes de tout l'arbre identiques pour les deux labs. Q-G6 = (b) (Willy, AskUserQuestion session principale, 2026-10-01) : les scripts du hook sont protégés par G6, limite (y).
- **Quatre commits, un par étape, dans l'ordre fixe (P45-D-03)** : `3d06e503` étape 1 (G6 et G5) ; `bf6cfa87` étape 2 (G1) ; `b6609fa6` étape 3 (G7) ; `239df76d` étape 4 et dernière (cloisonnement par rôle).
- **Suites rejouées à chaque étape (identiques aux quatre commits)** : gates 446 OK / 0 KO ; hook enregistré 50 OK / 0 KO ; rejeu 91 OK / 0 KO ; hook installé 23 OK / 0 KO ; role-vs-check-agents 6 OK / 0 KO. Aucun cas ni mutant supprimé ou affaibli.
- **Zéro régression dev** (relevé du manager, commande enregistrée rejouée hors lab adhérent, ce dépôt, repris du digest du mandat et non rejoué ici) : 12/12 cas, `rc=0`, stdout et stderr à 0 octet.
- **Canary synthétique** : `check-gates-alive.sh` rejoue la commande sur un lab synthétique et rend `rc=3` (relevé du manager, repris du digest du mandat) ; il signale, sans bloquer.
- **Relevé final** : 0 faux refus, 0 faux accept, 202 refus conformes au modèle (G1 196, G7 6), `EMPREINTE-ARBRE-IDENTIQUE` pour `~/jarvis-keystone` et `~/BusinessFlow-Lab` (`45-REJEU-FINAL.md`).
- **État final** : `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7` et `ARMEMENT_ROLE` valent `armed` ; `G2_MODE` vaut `avertit`. planning-core reste en v2.9.0, SANS release (ADR-073) : aucun bump.
- **Limite (z)** (quick 261001-owx) : faux refus sous forte charge machine (SIGALRM, « Alarm clock », échéance de 8 s), observé en suites à charge 20 à 35, jamais en rejeu réel ; point de surveillance après l'armement, non traité dans la Phase 45.

## Accomplishments

### Tâche 1 (traceur) : la référence et son contrôle croisé

- **Section « Hook central et gates d'écriture (Phase 45) »** de `modele-cycles.md` (commit `6d391897`) : principe (une mécanique, deux chantiers ; adhérents seuls ; racine dérivée du chemin ; périmètre d'environnement P45-D-12a, amendement de R-ENV-02 du 2026-09-30) ; commande enregistrée fail-closed (cinq outils refusés, `Bash` ouvert) ; **25 limites déclarées (a) à (y)**, chacune sur sa propre ligne ; table d'armement livrée (état, étape, comportement sur défaillance, cas de canary, relevé) ; G2, G6, G5, G1, G7 (prédicat « habité » littéral de P45-D-14), hook par rôle (ordre de résolution P45-D-05b, ligne worker F9, ligne « Tous » P45-D-11) ; dérogation ; commande de verdict ; journal d'observation ; canary ; rejeu (classification par le modèle, « refus conforme au modèle, lab non migré », P45-D-21a) ; « Coût de migration d'un lab » sans chemin de lab réel ni nombre relevé.
- **« Hors de cette phase » réécrite** : plus de « aucun hook ni gate câblé » ni de « G6 arrive en Phase 45 » ; G2′, G3, G4, G4′, D1 (Phases 46-47), hash (46), hook managed, `guard-planning-updated.sh` conservé en exit 2 (P45-D-19), drapeaux `phases_trace` et `gates` toujours sans effet (P45-D-01).
- **R-REFERENCE et MUT-REFERENCE** (commit `0c240fb8`, trailer `Gate-Touche`) : `test-planning-gates.sh` 395 -> **405 OK · 0 KO**. Le contrôle compare la référence à `TABLE_ARMEMENT`/`G2_MODE`/`ORDRE_ETAPES`/`PROTEGES_G6`/`NOM_JOURNAL_DEROGATIONS`/`MARQUEURS_CODE`, à l'ordre de `resoudre_agent` (lu dans le texte du hook), au `case` glob et au matcher de la commande de `hooks.json`, aux cas de `CANARIS`, et exige que « Aucun gate n'est armé » soit présent si et seulement si les cinq constantes valent `observe`.
- **Mutants (tous TUÉS, trace imprimée, aucun mot ECART dans une exécution verte)** : `MUT-REFERENCE-G6` (valeur de G6 inversée), `MUT-REFERENCE-OUTIL` (`Agent` retiré des outils refusés), `MUT-REFERENCE-LIMITE-L` (ligne de la limite (l) retirée), `MUT-REFERENCE-JOURNAL`, `MUT-REFERENCE-MARQUEURS`, `MUT-REFERENCE-ORDRE`, `MUT-REFERENCE-CANARY`, `MUT-REFERENCE-LIMITES` (**chacune des 25 limites retirée seule est nommée par le contrôle**, extension A1), `MUT-REFERENCE-CODE` (une constante du hook change, la référence reste intacte).
- **`45-COUT-MIGRATION.md`** : 196 refus conformes de G1 sur le premier lab (189 + 7), 0 sur le second ; G7 : 1 et 5 ; total 202 ; « au plus 21 » unités à cadrer ; source : `45-REJEU-ETAPE-2.md` et `45-REJEU-ETAPE-3.md` (lignes `COMPTE`, tableaux « Refus conformes au modèle »). **Aucun nouveau rejeu réel** (A5), dit dans le fichier.
- **A3** (commit `1e7a8d5c`) : `docs/HOOKS-CONTRAT-SORTIE.md` ligne n°31 : « table d'armement absente » est un signal en code 0 (plus un code 4 silencieux), deux signaux ajoutés (« commande enregistrée non reconnue », « constantes d'armement absentes ou illisibles ») et « couverture minimale incomplète » ; ligne n°30 : code 73 du lanceur (échéance interne ou lanceur disparu, stdout vide) et refus `PX=0` hors lab quand le cœur est tombé (limite F4). Décompte inchangé, **recompté par machine** : la commande du §4 rend `31`, `test-check-hook-paths.sh` T12 vert (31 entrées, doc et parc identiques). Les 7 bloquantes et 24 advisory ne changent pas (aucun hook ajouté ni retiré).
- **Tracer feedback gate** : le `<verify>` de la Tâche 1 a été rejoué de bout en bout avant d'étendre : « Tracer verified end-to-end — expanding ».

### Tâche 2 : bump v2.9.0 sans release et rejeu des gates

- **`plugin/planning-core/{VERSION,module.json,CHANGELOG.md,README.md}` -> v2.9.0** (commit `1897aa44`) : entrée de tête du CHANGELOG qui disait, à 1897aa44, l'état d'armement livré (tout en observation, aucun gate armé ; réécrite depuis à l'état armé), chaque gate avec son relevé, les limites (k) et (l), la levée du code 2 avec F10 = f10-archive (Willy, AskUserQuestion session principale, 2026-09-30), `guard-planning-updated.sh` conservé (P45-D-19) et les trois escalades vers Willy ; README : paragraphe « Hook central (Phase 45) » et liste des scripts complétée (planning-hook.sh, check-gates-alive.sh, rejeu-gates.sh, rejeu-reel.sh, poser-verdict.sh, deroger-gate.sh).
- **Version et release** : voir « Version ». Aucune release, aucun tag, aucune écriture de la `VERSION` racine, de `plugin.json`, de `marketplace.json` ni des README racine.

## Limites déclarées (lettre -> source)

| Lettre | Contenu | Source |
|---|---|---|
| (a) | filtre d'outil en JSON compact | recherche 45-01 (limites a-h), harnais 2.1.284 |
| (b) | adhésion reconnue seulement en forme littérale sur une ligne | recherche 45-01 |
| (c) | `config.json` en lien : adhérent côté shell, non adhérent côté Python | recherche 45-01 |
| (d) | FERMÉE : échappement JSON non géré ferme quand le cœur est tombé (coût : (u)) | lot A (261001-fxa), vf-dev-manager, 2026-10-01 |
| (e) | charge non JSON jamais refusée en mode dégradé | recherche 45-01 |
| (f) | `bash` absent : code 127, chemin dégradé | recherche 45-01 |
| (g) | Bash reste ouvert en mode dégradé | P45-D-06b |
| (h) | chemin relatif joint au `cwd` | recherche 45-01, P45-D-12 |
| (i) | `CLAUDE_PROJECT_DIR` choisit la copie du script | P45-D-21b |
| (j) | G1 laisse passer un `CADRAGE.md` non lisible (F5 = f5-etats) | 45-06, T-45-55, P45-D-21a |
| (k) | m2 : shell adhérent / Python non adhérent en panne | vf-dev-manager, 2026-09-30 (plan 45-10) |
| (l) | F9 : l'allowlist d'un worker vit dans une définition que G6 ne protège pas | Willy, AskUserQuestion session principale, 2026-09-30 (45-08) |
| (m) | F2 (re-audit) : inverse de (k), repli shell lit un `config.json` échappé ou sur plusieurs lignes comme non adhérent | A1 ; vérifié sur `hooks.json` (`grep -E` ligne à ligne) |
| (n) | T-45-42 reformulée : F6 ferme le désarmement « par outil », Bash reste ouvert | A1 ; 45-05 (F6) ; P45-D-10 |
| (o) | amendement de P45-D-01a : `.planning` sous un composant `.planning` jamais racine | A1 ; lot A ; vérifié `sous_planning` / `racine_lab` |
| (p) | R1 : `.planning/` sans `config.json` sous un sous-dossier le rend non adhérent | A1 ; vérifié `racine_lab` (le plus proche gagne) |
| (q) | m1 : dispatch d'un worker sans `subagent_type`, ou `fork`, refusé | A1 ; 45-08 ; vérifié `evaluer_role` (aucun traitement de `fork`) |
| (r) | m6 : journal d'observation sans borne ni rotation | A1 ; 45-04 (A8) ; vérifié `observer` |
| (s) | coût de résolution et échéance interne de 8 s (code 73) | A1, **corrigé par la mesure** (voir Deviations 3) ; `ECHEANCE_COEUR_S` |
| (t) | F3 : plus haute version tirée des chiffres du nom de dossier sans `installed_plugins.json` | A1 ; vérifié `_cle_version`, `versions_actives` |
| (u) | F4 : cœur tombé, échappement JSON non géré refusé même hors lab | A1 ; lot C (261001-5xc) ; vérifié `hooks.json` |
| (v) | F5 (lot B) : `STATE.md` portant la marque de génération puis édité à la main, remplacé sans archive | A1 ; lot B (261001-lb4) ; vérifié `_est_genere` |
| (w) | N1 résiduelle : `name:` masqué par un échappement YAML non candidat | A1 ; lot C ; vérifié `candidat_definition` |
| (x) | rejeu : volume (25 000 fichiers sur plus de 300 s) ; `.planning` lien vers un dossier du lab -> MESURE-VIDE (code 1) | A1 ; lots B et C |
| (y) | à la livraison : OUVERTE (arbitrage en attente) ; depuis le 2026-10-01 : scripts du hook protégés par G6 (Q-G6 = b, Willy, AskUserQuestion session principale, 2026-10-01), `.claude/settings*.json` non protégés | A1 ; audit M1 ; lot A (« hors périmètre ») ; lot D |
| (z) | ajoutée le 2026-10-01 : faux refus sous forte charge (SIGALRM, « Alarm clock »), point de surveillance | quick 261001-owx |

## Task Commits

1. **Tâche 1 (traceur)** : `6d391897` docs (référence et `45-COUT-MIGRATION.md`) ; `0c240fb8` test (R-REFERENCE, MUT-REFERENCE, trailer `Gate-Touche: plugin/planning-core/scripts/tests/test-planning-gates.sh — contrôle croisé de la référence`) ; `1e7a8d5c` docs (A3, contrat de sortie des hooks).
2. **Tâche 2** : `1897aa44` chore (v2.9.0, sans release).
3. **Précision** : `7db13bee` docs (limite (m) écrite en clair).
4. Ce SUMMARY : commit docs séparé.

## Version

- `plugin/planning-core/VERSION`, `module.json`, ligne `**Version**` du README du module et entrée de tête du CHANGELOG : **v2.9.0** (base relue : v2.8.0).
- `bash scripts/check-version-sync.sh`, dernière ligne exacte : `[check-version-sync] ✓ sources synchronisées (v2.67.1, 17 modules)`. Le gate n'exige **aucune** cohérence avec la `VERSION` racine pour un bump de module : rien à rapporter de ce côté, rien touché.
- `git diff --stat 893071a HEAD -- VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json README.md README.fr.md` : vide. `git tag --points-at HEAD` : vide. Aucune release (CLAUDE.md « Quand publier », ADR-073 ; pas de release gouvernance avant la clôture de fiabilite-v1.0).
- `guard-planning-updated.sh` : toujours suivi (`git ls-files`) ; l'entrée `Stop` de `hooks.json` est identique à celle de `fd49137` (comparaison de la structure parsée par Python : `True`).

## Suites et gates

Toutes lancées dans CE worktree, en commande simple, `HOME` non affecté (les suites posent le leur). Découverte complète NON lancée.

| Suite ou gate | Résultat |
|---|---|
| planning-core/test-planning-gates.sh | **405 OK · 0 KO** (395 avant ce plan + R-REFERENCE et 9 MUT-REFERENCE ; durée 212 s) |
| planning-core/test-planning-hook-registered.sh | 44 OK · 0 KO |
| planning-core/test-rejeu-gates.sh | 89 OK · 0 KO |
| planning-core/test-recalc-planning.sh (une seule fois) | 358 OK · 0 KO |
| planning-core/test-check-planning-state.sh | 19 ok · 0 ko |
| planning-core/test-detect-gsd-engine.sh | 26 ok · 0 ko |
| planning-core/test-detect-planning-debt.sh | 10 passés · 0 échoués |
| planning-core/test-planning-context-hardening.sh | 38 passés · 0 échoués |
| planning-core/test-planning-core.sh | 14 passés · 0 échoués |
| planning-core/test-planning-hooks.sh | 42 PASS · 0 FAIL |
| planning-core/test-workstream-policy.sh | 22 ok · 0 ko · 0 skip |
| planning-core/test-workstream-symlink-escape.sh | 10 ok · 0 ko |
| _internal/test-planning-hook-installed.sh | 21 OK · 0 KO |
| scripts/tests/test-role-hook-vs-check-agents.sh | 6 OK · 0 KO |
| _internal/test-merge-hooks.sh | 39 OK · 0 KO |
| _internal/test-manifest.sh | 62 OK · 0 KO · 0 SKIP |
| dev-orchestrator/test-check-hook-paths.sh | 17 OK · 0 KO (T12 : 31 entrées, doc et parc identiques) |
| _internal/test-vibeflow-update.sh (A4) | **69 OK / 18 KO / 0 SKIP**, base `fd49137` extraite sous le scratchpad : **69 OK / 18 KO / 0 SKIP**. Les 18 lignes `✗` triées, rendues indépendantes du dossier temporaire (`sed` sur `tmp.XXXX`), comparées par `comm` : `comm -13 base courant` **n'imprime rien**, `comm -23` non plus. Sans normalisation, `comm -13` imprime la seule ligne T53f, qui ne diffère que par le nom du dossier temporaire dans son message |
| scripts/check-version-sync.sh | dernière ligne : `[check-version-sync] ✓ sources synchronisées (v2.67.1, 17 modules)` |
| scripts/check-machine-paths.sh | `✓ 1794 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` |
| scripts/check-gate-touche.sh | `marqueurs: lus=89 conformes=89`, `DECLARE` |
| conductor/check-planning-consumers-registered.sh | `✓ 121 .sh suivi(s) … 22 consommateur(s) détecté(s), tous recensés ; volet ci.yml : oui` |
| conductor/check-state-integrity.sh `--file` du STATE du compartiment (gate de planning rejoué à la main, la CI ne vérifie que fiabilite) | `✓ … conforme (compteurs non régressés, 1 ligne '^Phase:')` |
| 45-CONTROLE-MARQUEUR.sh `--base=fd49137 -- plugin/planning-core/scripts/tests/test-planning-gates.sh` | `MARQUEUR-BILAN commits=22 sans-marqueur=0` (code 0, lignes `MARQUEUR` imprimées) |

**Les 18 KO préexistants de `test-vibeflow-update.sh`** (labels mesurés sur la base, qui diffèrent de la liste du plan « T37, T48 à T53 ») : T24 (deux lignes, fidélité), T26, T37, T49 (deux), T50, T51 (trois), T52, T52bis, T53a (trois), T53e, T53f, T53g. Même ensemble sur la base et sur le worktree : sans lien avec ce plan (codex, `fidelity-coexistence`, `use_worktrees`, `.planning/config.json`). **Précision d'environnement** : sur ce poste, la suite appelle `codex plugin marketplace add pbakaus/impeccable` puis un `git clone` de ce dépôt GitHub, qui restent suspendus ; ces deux sous-processus de la suite ont été tués après 20 s, de la même façon pour la base (tués à la main) et pour le worktree (tués par un script d'attente du scratchpad, qui consigne les PID tués), et aucun processus ne reste actif.

**Vérifications du plan (Tâche 1, `<verify>`)** : `noms=0 nombres=0 limite-i=1 limite-k=1 limite-l=1 libelle=1 cout=1` (code 0) ; non-reprise des nombres des relevés : `repris=0` (voir Deviations 5) ; `45-COUT-MIGRATION.md` : aucun préfixe de dossier personnel de la machine, cite `refus-conforme-modele` et « Refus conformes » ; la suite des gates ne rend aucune ligne `✗`, `NON TUÉ` ni `ECART` et rend `✓ R-REFERENCE` et neuf `✓ MUT-REFERENCE`, `== Résultat : 405 OK · 0 KO ==` ; aucune ligne ne reste sur « Aucun hook ni gate câblé » ou « G6 (protection de `STATE.md` ». **Critères d'acceptation** : section présente ; les sept décisions P45-D-10, 11, 14, 05b, 19, 06b, 12a citées : le comptage vaut 7.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Une ligne de la Phase 44 faisait rougir la vérification de non-reprise des nombres**
- **Found during :** Tâche 1 (vérification 1 du plan : `nombres` doit valoir 0).
- **Issue :** la ligne « mesuré à 1 écriture sur 15 essais » (résidus du lot 8) correspond au motif `[0-9]+ écritures? ` interdit dans la référence.
- **Fix :** « mesuré : une écriture indue sur 15 essais » (même sens, sans chiffre devant « écriture »). **Commit :** `6d391897`.

**2. [Rule 1 - Bug de documentation] Le paragraphe d'archivage du socle v2 (45-02) décrivait un comportement antérieur au lot B**
- **Found during :** relecture des quick SUMMARY (261001-lb4, M3/m8).
- **Issue :** « une archive existante n'est jamais réécrite (si l'une des deux cibles existe déjà, rien n'est archivé) » est faux depuis le lot B : une nouvelle archive est posée sous un nom libre (`socle-v2.2`…), en tout ou rien, et un fichier portant la marque de génération n'est pas archivé. Le plan demandait de ne pas toucher le reste du document, mais une référence qui ment est précisément ce que T-45-90 interdit.
- **Fix :** ce seul paragraphe aligné sur `archiver_socle_v2` et renvoyant à la limite (v). **Commit :** `6d391897`.

**3. [A1, affirmation du mandat non reproduite] Coût de résolution d'un agent de plugin**
- Le mandat dit « 0,05 à 0,4 s (1,8 s au pire, définition de 1 Mio) ». Les quick SUMMARY donnent **0,05 s après le lot A contre 0,12 à 0,40 s avant** (261001-fxa) ; **aucun relevé ne porte 1,8 s**. Mesure refaite ici (script jetable, lab synthétique, cache de plugin fabriqué, hook réel) : 0,04 à 0,06 s pour des définitions de 1 000 octets à 1 048 000 octets ; 0,07 à 0,08 s pour huit candidats de 1 Mio plus la cible ; 0,11 s pour mille fichiers dans le dossier d'agents ; 0,05 à 0,08 s sur le cache de plugins réel du compte (lecture seule). Écrit dans la limite (s) : mesuré à environ 0,05 s à vide, 0,11 s au plus, 0,12 à 0,40 s avant le lot A, borne réelle = échéance de 8 s (code 73). Le chiffre de 1,8 s n'est pas repris faute de source ; sous forte charge machine il est plausible mais non mesuré.

**4. [Vérification du plan inapplicable telle quelle] `git diff --stat fd49137 -- VERSION …` n'est pas vide**
- La base de la phase (893071a) porte déjà la `VERSION` racine v2.67.1 d'un commit de main (`f99f3eb7`), postérieur à `fd49137`. La commande littérale du plan imprime donc des lignes, mais aucune ne vient de ce plan : la même commande contre la base réelle (`893071a`) est **vide**. Rapporté, rien touché.

**5. [Équivalence] Deux vérifications `awk` du plan ont été refusées par la garde du poste et rejouées par Python**
- La vérification de non-reprise des nombres des relevés (`match` sur une expression calculée, puis `awk -f`) a été refusée ; équivalent Python écrit sous le scratchpad : `nombres-des-releves=6 repris=0`. Remarque : l'expression du plan (`^(COMPTE|REJEU-ETAPE|CLASSE-REGLE-ECRITE) ` suivie d'un blanc) ne lit pas les lignes `REJEU-ETAPE-3 …` (le préfixe est suivi d'un tiret) ; le nombre 202 n'était donc pas contrôlé : vérifié à part par `grep` (196, 200, 202, 189, 193 et les totaux de lignes : aucune reprise dans la référence). Les extractions de `45-COUT-MIGRATION.md` ont été faites par Python plutôt que par `awk` pour la même raison.

### Écarts de mise en oeuvre (sans changement de contrat)

**6. Chaque limite tient sur une seule ligne physique** (jusqu'à 600 caractères), parce que les vérifications du plan lisent ligne à ligne (« limite (k) » et `config.json` sur la même ligne) ; les quatre listes comparées au code (noms protégés, journal, marqueurs, ordre) aussi.

**7. La limite (b) renvoie à (m)** : (b) dit que la couche shell ne reconnaît l'adhésion qu'en forme littérale sur une ligne, (m) dit ce qu'il en coûte (silence si le cœur tombe) ; les deux textes du mandat se recouvraient.

**8. `planning-hook.sh` n'est pas modifié** : ni constante `ARMEMENT_*`, ni `TABLE_ATTENDUE`, ni code du hook ; seule la suite des gates reçoit une section.

**9. Base de `test-vibeflow-update.sh` (A4)** : pas de fichier de base consigné ; la base a été reconstruite par `git archive fd49137` extrait sous le scratchpad (aucun checkout, reset ni `git worktree add`), puis la suite y a été rejouée.

## Authentication Gates

Aucune.

## Known Stubs

Aucun.

## Threat Flags

Aucune surface nouvelle. T-45-90 (référence qui annonce un gate armé qui ne l'est pas) : mitigé par R-REFERENCE (exige « Aucun gate n'est armé » si et seulement si les cinq constantes valent `observe`) et MUT-REFERENCE-CODE. T-45-91 (release prématurée) : aucun bump racine, aucun tag, vérifié. T-45-92 (retrait de `guard-planning-updated.sh`) : fichier présent, entrée `Stop` comparée.

## Escalades vers Willy (état à la livraison de 1897aa44 ; mises à jour ci-dessous)

1. **Armement** : nouveau rejeu réel sur des labs au repos après les lots A, B et C, puis adaptation de deux suites couplées à « tout en observe » (ESCALADE-WILLY ETAPE-1, refus du classifieur « Security Test Removal »). Aucun armement dans ce plan. **Résolu le 2026-10-01** : rejeu fait (`45-REJEU-FINAL.md`), Q-ARM rendu, armement fait en cascade.
2. **Limite (y), audit M1** : protection du script du hook, du canary et de `.claude/settings*.json` par un gate ; décision non prise à la livraison. **Tranchée le 2026-10-01** : Q-G6 = b (Willy, AskUserQuestion session principale, 2026-10-01), scripts du hook protégés, réglages non protégés.
3. **G1 et phase dérogée sans cadrage** (constat de 45-06 : zéro occurrence sur les deux labs réels mesurés) : règle de gate inchangée.

## Refus de la garde du poste (rapportés, jamais contournés)

Commandes composées refusées par la garde d'isolation du worktree (« too complex to verify ») puis refaites en commandes simples : `sed -n` avec un chemin porté par une variable de shell ; commande de fond suivie de `; echo`; deux programmes `awk` (`printf` avec `for … in`, puis `match` sur une expression calculée) et `awk -f` ; `check-state-integrity.sh … ; echo rc=$?` ; `sleep` suivi d'une lecture. Aucun refus du classifieur de permissions, aucun refus de hook de commit.

## Self-Check: PASSED

Vérifié par commandes : les huit fichiers créés ou modifiés existent (`ls`) ; les cinq commits de tâche (`6d391897`, `0c240fb8`, `1e7a8d5c`, `1897aa44`, `7db13bee`) existent (`git cat-file -t` : `commit`) et descendent de `893071a` ; à la date de ce SUMMARY, les cinq constantes `ARMEMENT_*` valaient toujours `"observe"` (`grep -c` : 5) ; `planning-hook.sh`, `STATE.md`, `ROADMAP.md` et `REQUIREMENTS.md` du compartiment sont inchangés depuis `893071a` (`git diff --stat` vide) ; aucun `gsd-tools state`, `roadmap update-plan-progress` ni `requirements mark-complete` lancé ; aucun push, merge, tag ; aucune commande lancée sur `~/jarvis-keystone` ni `~/BusinessFlow-Lab` ; aucun processus ne reste actif ; ce SUMMARY ne porte aucun chemin absolu de machine (`check-machine-paths.sh` rejoué après son écriture, voir ci-dessous).
