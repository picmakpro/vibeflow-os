---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 09
subsystem: planning-core
status: complete
requirements: [CLOT-08]
tags: [canary-de-juge, c-16, sortie-piegee, sessionstart, juge-laxiste, juge-sans-preuve, diagnostic, mutants]
commits: 3
plan_head_before: 47eaf95b4d07f3df1fa6bc70e05372fd79552874
commit_list:
  - 7f04be08 feat(planning-core): canary de juge, juge sans preuve signalé au SessionStart (46-09, P46-D-06)
  - 8b52ab94 feat(planning-core): juge laxiste et verdict de canary périmé, juges dans le modèle (46-09, P46-D-06, P46-D-06a)
  - 9795d27c docs(planning-core): contrat de la sortie piégée et étape du premier cycle (46-09, P46-D-06, P46-D-13)
estimate:
  tokens: 160000
  raw_tokens: 160000
  tasks: 3
  confidence: low
actuals:
  tokens: 18119
  tasks: 3
  commits: 3
  note: "chars/4 sur les lignes ajoutées et retirées du diff réalisé (1178 lignes, 72478 caractères, base 47eaf95b, git diff --unified=0) ; non mesuré par le moteur"
duration: 46min
started: 2026-10-05T20:37:28Z
completed: 2026-10-05T21:23:39Z
worktree:
  branche: worktree-agent-a93e81ce51a955dd7
  chemin: .claude/worktrees/agent-a93e81ce51a955dd7 (relatif au dépôt principal, supprimé après intégration)
  base: 47eaf95b4d07f3df1fa6bc70e05372fd79552874
verdicts:
  code_review: absent
  nyquist: absent
  secure: absent
key-files:
  created:
    - plugin/planning-core/scripts/tests/test-juges-canary.sh
    - plugin/planning-core/references/templates/cycles/SORTIE-PIEGEE.template.md
  modified:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/references/templates/cycles/CYCLE.template.md
    - plugin/planning-core/references/modele-cycles.md
    - README.md
    - README.fr.md
---

# Phase 46 Plan 09 : canary de juge (C-16) — Summary

Un lab adhérent apprend à chaque démarrage (`SessionStart`, source `startup`) quels juges ont prouvé qu'ils savent refuser : un vérificateur déterministe classe chaque juge du lab en prouvé, laxiste ou sans preuve (« sans preuve » n'est jamais vert), une ligne agrégée l'annonce sans jamais bloquer, et le contrat de la sortie piégée, le diagnostic `--juges` et l'étape écrite du premier cycle sont livrés ; aucun juge n'est dispatché.

## Livré

- **Vérificateur** (`planning-hook.sh`, `verifier_juges`, un seul `def`) : juges du lab = définitions de `.claude/agents/` du lab de rôle dérivé `juge` (`definitions_dossier`, `deriver_role` ; jamais le compte ni un plugin). Par juge : nom conforme à `^[a-z0-9][a-z0-9-]{0,63}$`, dossier `.planning/juges/<juge>` réel (lstat de `juges` et du dossier), `SORTIE-PIEGEE.md` régulière lue sans suivre de lien (octets hachés, `critere_vise` du frontmatter), `VERDICT.md` (règle R6 comme G4), `hash` comparé au sha256 des octets de la sortie piégée, critère visé en `échec`. Toute erreur sur un juge le range sans preuve (`erreur-<type>`). Balises de mutation `# juge-sans-preuve`, `# juge-hash`, `# juge-critere`, `# juge-source`.
- **Signal** (`signal_juges`, `mode_session_start`) : UNE ligne `[planning-core] juges (C-16) : <p> prouvé(s) ; <l> laxiste(s) : <noms> ; <s> sans preuve : <noms> — faire passer chaque juge sur …` dans l'`additionalContext` du même objet que la liste surveillée de D1 ; au plus trois noms par classe suivis de « et N autre(s) » ; marche à suivre seulement s'il reste un juge à prouver ; source `startup` seulement ; aucun juge, hors adhésion : rien ; fail-open (une erreur du vérificateur la tait, ne change ni `watchPaths` ni le signal de D1).
- **Diagnostic** : `planning-hook.sh --juges <racine>` (lanceur et cœur, patron de `--classer`) : une ligne JSON `{"prouves", "laxistes", "sans_preuve": [{"juge", "motif"}]}`, code 0, stdin non lu.
- **`recalc-planning.sh`** : `juges` dans `NOMS_MODELE_RACINE_DOSSIERS` (jamais « Hors modèle », jamais dérivé).
- **Gabarits et référence** : `SORTIE-PIEGEE.template.md` (frontmatter `juge`, `critere_vise`, `provenance`), section « Premier cycle — canary de juge » de `CYCLE.template.md` (frontmatter inchangé), sous-section « Canary de juge (C-16, Phase 46) » de `modele-cycles.md` (contrat, emplacement, trois classes et motifs, signal, diagnostic, étape du premier cycle, G5), `juges` dans l'arborescence et les emplacements du modèle, gabarit listé, SessionStart du contrat par événement, limite (bb) ; `("bb", ("Phase 48", "Phase 50", "P46-D-13"))` dans `LIMITES_REFERENCE` de `test-planning-gates.sh`.
- **Suite `test-juges-canary.sh`** (nouvelle, 14 contrôles : R-JUGE-01 à R-JUGE-08 et 6 mutants) : fixtures de verdicts de canary posés par la VRAIE `poser-verdict.sh` ; seuls les jumeaux négatifs (verdict invalide, nom hors forme) sont écrits à la main. Compteurs de suites des README 108 -> 109.

Copies armées : R-JUGE-08 n'arme que G6 et G5 (copie `g6`), G3, G4, G4′ restent à `observe` (discipline du correctif 5c46c503) ; aucune copie ne touche à l'armement.

## Vérifications (commande -> rc + ligne finale)

| Commande | rc | Ligne finale |
|---|---|---|
| T1 `test-juges-canary.sh` (forme du plan, + contrôle de durée correct) | 0 | `== Résultat : 6 OK · 0 KO ==` ; `DUREE-LUE=7` (< 120) ; `✓ R-JUGE-01..03`, `✓ MUT-JUGE-SANS-PREUVE-VERT`, `✓ MUT-JUGE-ADHESION` présents, ni `✗` ni `NON TUÉ` (rejoué sur l'état commité : tracer vérifié de bout en bout avant l'expansion) |
| T1 `check-version-sync.sh` | 0 | `[check-version-sync] ✓ sources synchronisées (v2.68.0, 17 modules)` ; suites 109 |
| T2 `test-juges-canary.sh` entière (forme du plan) | 0 | `== Résultat : 14 OK · 0 KO ==` ; `DUREE-LUE=5` ; `✓ R-JUGE-04..08`, `✓ MUT-JUGE-LAXISTE`, `✓ MUT-JUGE-HASH`, `✓ MUT-JUGE-NOMS-MODELE` |
| T2 `test-recalc-planning.sh` | 0 | `== Résultat : 405 OK · 0 KO ==` |
| T3 `VF_GATES_SECTIONS=reference test-planning-gates.sh` | 0 | `== Résultat : 18 OK · 0 KO ==` (limite (bb) et chaque limite retirée seule : tuées) |
| T3 `awk` des clés `critere_vise`, `juge`, `provenance` du gabarit ; ligne « canary de juge » de `CYCLE.template.md` | 0 | exit 0 aux deux |
| T3 `45-CONTROLE-MARQUEUR.sh --base=247194c7 -- plugin/planning-core/scripts plugin/planning-core/hooks` | 0 | `MARQUEUR-BILAN commits=29 sans-marqueur=0` |
| `test-planning-gates.sh` ENTIER (HEAD 9795d27c, après la tâche 3) | 0 | `== Résultat : 473 OK · 0 KO ==` (1034 s, charge 30 à 56) |
| `test-recalc-planning.sh` (HEAD, critère R23 des gabarits) | 0 | `== Résultat : 405 OK · 0 KO ==` (54 s) |
| `test-planning-hook-registered.sh` ENTIER (HEAD) | 0 | `== Résultat : 112 OK · 0 KO ==` (285 s, charge < 20 ; contrôles « moins de 2 s » non relâchés ; avant : sections ciblées 62 OK, 49 OK, `perf` 1 OK) |
| `test-d1-surveillance.sh` ENTIER sur une copie de HEAD (scratchpad, `git archive`, voir déviation 5) | 0 | `== Résultat : 27 OK · 0 KO ==` (23 s) |
| `test-d1-surveillance.sh` dans ce worktree, après la suite d'enregistrement | 1 | `== Résultat : 16 OK · 2 KO ==` : R-D1-03 et `MUT-D1-ADHESION NON TUÉ`, pollution pré-existante prouvée contre la base (déviation 5) ; avant elle, `base,reconciliation` : 10 OK · 0 KO |
| `plugin/_internal/tests/test-planning-hook-installed.sh` | 0 | `== Résultat : 25 OK · 0 KO ==` |
| `check-version-sync.sh` | 0 | `✓ sources synchronisées (v2.68.0, 17 modules)`, suites 109 |
| `check-machine-paths.sh` | 0 | `✓ 1933 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` |
| `check-planning-consumers-registered.sh` | 0 | `✓ 127 .sh suivi(s) hors tests/ balayé(s) (239 au total), 23 consommateur(s) détecté(s), tous recensés ; volet ci.yml : oui` |
| `check-gate-touche.sh --base-ref 47eaf95b` | 3 | `RIEN-A-JUGER: aucun chemin de la surface surveillee n'est touche entre 47eaf95b… et HEAD` (3 marqueurs conformes) |
| acceptances : `awk '/def verifier_juges/'` ; `awk '/NOMS_MODELE_RACINE_DOSSIERS = / && /juges/'` | 0 | une ligne chacun |

Mutants tracés (assertion · attendu (original) · obtenu (mutant), témoin inchangé), tous « TUÉ » :

| Mutant | Contrôle | Obtenu sous le mutant |
|---|---|---|
| MUT-JUGE-SANS-PREUVE-VERT | R-JUGE-01 | `1 prouvé(s)` et `1 sans preuve : juge-a` attendus ; obtenu `2 prouvé(s) ; 0 laxiste(s) ; 0 sans preuve` (cinq juges sans dossier : `5 prouvé(s)`) |
| MUT-JUGE-ADHESION | R-JUGE-02 | lab dev, cœur seul : stdout d'octet vide attendu ; obtenu l'objet `SessionStart` avec `watchPaths` |
| MUT-JUGE-SOURCE | R-JUGE-03 | aucune ligne de juge à `resume`, `compact`, `clear` attendue ; obtenu la ligne `1 sans preuve : juge-a` |
| MUT-JUGE-LAXISTE | R-JUGE-04 | prouvé `juge-ok` seul attendu ; obtenu prouvés `juge-lax`, `juge-mixte`, `juge-ok` |
| MUT-JUGE-HASH | R-JUGE-05 | seul `j-ok` prouvé attendu ; obtenu `j-ok` et `j-perime` (sortie piégée affaiblie après le verdict) |
| MUT-JUGE-NOMS-MODELE | R-JUGE-07 | `juges` absent de `hors_modele` attendu ; obtenu `['juges', 'juges-autre']` |

## Deviations from Plan

1. **[Défaut du plan] Contrôle de durée** : le plan n'en porte pas dans ses `<verify>` ; celui de 46-PATTERNS (`substr($0,8)+0` sur `DUREE s=…` vaut toujours 0) n'a pas été repris : la forme correcte `substr($0,9)+0` a été jouée en plus (`DUREE-LUE=7` puis `5`, cible < 120 s tenue). Plan non corrigé (consigne).
2. **[Défaut du plan] Trailer** : le plan cite `Co-Authored-By: Claude Opus 5.5 (1M context)` ; les commits portent le trailer d'attribution de la configuration de l'agent (`Co-Authored-By: Claude Sonnet 5.5`, `Claude-Session`), plus `Gate-Touche:` aux trois commits (chemins `planning-hook.sh`, `recalc-planning.sh`, `test-planning-gates.sh`).
3. **[Discrétion] Syntaxe de `check-gate-touche.sh`** : `--base-ref 47eaf95b` (espace, pas `=`).
4. **[TDD] Rouge avant vert non vu** : le code du vérificateur a été écrit avant les contrôles ; la preuve d'opposabilité est portée par les six mutants (chacun vu rouge, trace ci-dessus), pas par un rouge initial. Les contrôles R-JUGE-01 à R-JUGE-08 sont sortis verts du premier coup.
5. **[Pré-existant, hors `files_modified`, non corrigé] Pollution de `test-d1-surveillance.sh` par la suite d'enregistrement (46-04)** : `MUT-EVT-ADHESION` de `test-planning-hook-registered.sh` (section `evenements`) rejoue un cœur « adhésion forcée vraie » sur « ce dépôt » et y laisse `.planning/surveillance.log` (fichier de 702 octets, ignoré par git). Tant que ce fichier existe, `R-D1-03` (« un journal de D1 a été créé hors adhésion ») rougit et `MUT-D1-ADHESION` n'est « pas tué » (garde « l'original passe »). Preuve contre la base : `git archive 47eaf95b` extrait dans le scratchpad avec un `.planning/config.json` non adhérent, `VF_REG_SECTIONS=evenements` : `15 OK · 0 KO` et un `surveillance.log` de 702 octets créé. Aucun lien avec 46-09. Le fichier n'a PAS été supprimé (consigne : rien hors du scratchpad) : il reste dans ce worktree (ignoré, `git status` propre) ; la CI, en checkout neuf, ne le voit pas. D1 entier rejoué sur une copie de HEAD sans ce fichier : 27 OK · 0 KO. Correction minimale proposée (à autoriser, ~3 lignes) : dans `sec_evenements`, ne rejouer le mutant `EVT-ADHESION` que sur le lab dev fixture (`labs` sans « ce dépôt »), ou nettoyer le fichier en fin de section.
6. **[Discrétion, renversable] Précisions du vérificateur** non écrites au plan : un critère visé porté en `échec` ET en `passé` est **laxiste** (jamais prouvé sur un constat contradictoire) ; une sortie piégée sans `critere_vise` (ou sans frontmatter lisible) est « sans preuve » (`critere-vise-absent`) ; une sortie piégée de plus de 1 Mio est « sans preuve » (`sortie-piegee-hors-borne`, SessionStart borné) ; `.planning/juges` ou le dossier du juge en lien vaut `dossier-absent` ; le diagnostic `--juges` ne vérifie pas l'adhésion (la racine est celle que l'appelant désigne) ; la ligne est émise dès qu'il y a au moins un juge (compte des prouvés compris), la marche à suivre seulement s'il en reste un à prouver. Ajout non demandé : `MUT-JUGE-SOURCE` (R-JUGE-03) et la copie des jumeaux négatifs (juge du compte, lab dev, `juges-autre`, `juges` fichier, SORTIE-PIEGEE.md sous G5).
7. **Découpage des commits** : le vérificateur complet (trois classes) est livré par le commit de la tâche 1 (les classes ne se séparent pas proprement) ; le commit de la tâche 2 y ajoute le diagnostic `--juges` et `juges` dans le modèle, avec les contrôles R-JUGE-04 à R-JUGE-08.
8. **Exécution** : `test-planning-gates.sh` entier (1034 s) a été déplacé en arrière-plan par la plateforme à 600 s (non demandé), attendu puis lu ; sous charge > 20, `test-d1-surveillance.sh` et `test-planning-hook-registered.sh` ont d'abord été joués par sections, puis le second en entier une fois la charge retombée. La commande `commit` du SDK n'a pas été utilisée pour ce SUMMARY (aucun `config.json` de compartiment pour lire `commit_docs`) : commit git direct, comme les SUMMARY précédents de la phase.

## Limites et points ouverts

- **(bb)** déclarée dans la référence : aucun dispatch de juge (Phase 48), sorties piégées fabriquées en Phase 50 (« juge sans preuve » est attendu sur tout lab existant), seuil de juge hors périmètre (P46-D-13).
- **T-46-095 (accepté)** : la qualité d'une sortie piégée relève de la Phase 50 ; le vérificateur ne rejette pas un `critere_vise` laissé tel quel (crochets du gabarit) : un verdict posé sur ce critère littéral serait prouvé.
- `plugin/planning-core/README.md` annonce encore « 8 gabarits du modèle par cycles » (hors `files_modified` de 46-09) : à aligner par 46-12 avec la version et le CHANGELOG du module.

## Known Stubs

Aucun.

## Threat Flags

Aucun : `--juges` lit, comme `--classer`, un chemin donné en argument par l'appelant local (aucune écriture, aucun réseau) ; les mitigations T-46-091 à T-46-094 sont portées par R-JUGE-01, R-JUGE-04, R-JUGE-05, R-JUGE-08 et les mutants nommés.

## Self-Check: PASSED

Fichiers présents : `test-juges-canary.sh`, `SORTIE-PIEGEE.template.md`, hook, recalc, `CYCLE.template.md`, `modele-cycles.md`, `test-planning-gates.sh`, README.md, README.fr.md ; commits `7f04be08`, `8b52ab94`, `9795d27c` présents (`git rev-list --count 47eaf95b..HEAD` = 3 avant ce SUMMARY) ; STATE.md et ROADMAP.md non touchés ; aucune commande `state.*` ni `roadmap.*` ; aucune release, bump, tag ni push ; aucun agent créé ni modifié.
