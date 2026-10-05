---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 07
subsystem: planning-core
status: complete-with-blocker
requirements: [CLOT-07, CLOT-09, CLOT-11]
tags: [d1, filechanged, sessionstart, cwdchanged, watchpaths, surveillance, canary]
commits: 3
plan_head_before: 92ef7cffadc0bbdd8f91fe28f62a4d96706a43f8
commit_list:
  - ebe48336 feat(planning-core): D1, liste surveillée au SessionStart et trace des écritures non expliquées (46-07, P46-D-07, P46-D-07a)
  - a51e595f feat(planning-core): D1, écritures du moteur et intentions journalisées (46-07, P46-D-07)
  - fc9463be feat(planning-core): D1, réconciliation par hash au SessionStart et canary (46-07, P46-D-07, P46-D-11)
estimate:
  tokens: 230000
  raw_tokens: 230000
  tasks: 3
  confidence: low
actuals:
  tokens: 31000
  tasks: 3
  commits: 3
  note: "chars/4 sur les lignes ajoutées du diff réalisé (125096 caractères, 1909 lignes, base 92ef7cff) ; non mesuré par le moteur"
verdicts:
  code_review: absent
  nyquist: absent
  secure: absent
key-files:
  created:
    - plugin/planning-core/scripts/tests/test-d1-surveillance.sh
  modified:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/poser-verdict.sh
    - plugin/planning-core/scripts/deroger-gate.sh
    - plugin/planning-core/scripts/check-gates-alive.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/references/modele-cycles.md
    - README.md
    - README.fr.md
---

# Phase 46 Plan 07 : D1, détection des écritures sur les fichiers surveillés — Summary

D1 livré : toute écriture sur un fichier surveillé d'un lab adhérent est expliquée par le moteur ou tracée comme contournement, en séance par `FileChanged`, entre les séances par une réconciliation par hash au `SessionStart` ; D1 ne refuse jamais (fail-open), n'a pas de constante d'armement et ne coûte rien hors adhésion.

## BLOCAGE à arbitrer (hors `files_modified`, non modifié)

`plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` (suite de 46-04) encode « SessionStart et CwdChanged d'un lab adhérent rendent un stdout vide » : c'était vrai tant que les modes étaient des points d'accroche. Le plan 46-07 exige l'inverse (objet `watchPaths`). Résultat à HEAD fc9463be, suite entière : `== Résultat : 106 OK · 6 KO ==` (rc=1), les six rouges étant exactement :

| Rouge | Cause |
|---|---|
| R-EVT-01b (témoin lab adhérent) | attend 1 ligne d'observation ET stdout vide pour SessionStart : obtenu un objet `watchPaths` |
| R-EVT-02 | attend « silence » pour SessionStart (commande complète et cœur seul) : obtenu `watchPaths` |
| R-EVT-07 | un mode qui « voudrait bloquer » doit laisser stdout vide ; le SessionStart émet sa liste |
| MUT-EVT-ADHESION, MUT-EVT-EXIT2, MUT-EVT-EXIT2-STATIQUE « NON TUÉ » | gardes « l'original passe » : conséquence des trois précédents |

Tout le reste de la suite (R-EVT-03 mode dégradé, R-EVT-04 faute injectée sur les balises `evt-mode-*`, R-EVT-05, R-EVT-06, MUT-EVT-FAILOPEN…) reste vert : les balises `return None  # evt-mode-*` et `raisons = MODES_EVENEMENT[evenement](contexte)  # evt-phase-b` ont été conservées exprès. Règle appliquée : défaut hors `files_modified` -> pas de correction, remontée. Correction proposée (à autoriser, ~15 lignes) : dans ces trois contrôles, remplacer « silence » pour SessionStart/CwdChanged par « aucun refus : stdout vide ou UN objet `hookSpecificOutput` sans `decision` ni `permissionDecision` » (FileChanged reste « silence ») ; le témoin R-EVT-01b garde « 1 ligne d'observation, rc=0 ». Le plan 46-12 (inventaire `docs/HOOKS-CONTRAT-SORTIE.md`, entrées 34 et 36 : « stdout vide hors adhésion » reste vrai) est à relire dans le même geste.

## Livré

- **Hook (`planning-hook.sh`)** : `inscrire_surveillance` ; liste surveillée `chemins_surveilles` (cinq fichiers racine toujours listés, quatre par unité de forme modèle dont `SUMMARY.md` est absent, fichier par fichier, borne 128, troncature tracée `genre=borne`) ; modes `SessionStart` (`watchPaths` + réconciliation + signal), `CwdChanged` (`watchPaths` au premier niveau ET sous `hookSpecificOutput`), `FileChanged` (trace, jamais de sortie) ; branche `# evt-phase-b` de `main()` étendue (les modes SessionStart/CwdChanged déposent leur objet dans `contexte["sortie_d1"]`, `main` l'émet via `sortie_d1`, jamais `deny` ni `block` ; erreur : branche `# evt-erreur-d1`, silence) et commentaires des modes réécrits ; `surveillance.log` ajouté à `PROTEGES_G6` (genre `d1`) ; intentions (`inscrire_intentions`, balise `# d1-intention`) sur la décision finale d'un PreToolUse Write/Edit/NotebookEdit qui passe ; ligne `moteur` après consommation d'une dérogation.
- **Écrivains du moteur** : `inscrire_surveillance` copiée ast-identique dans `recalc-planning.sh`, `poser-verdict.sh`, `deroger-gate.sh` ; lignes `moteur` (sha256 après écriture) pour STATE.md, INDEX.md, cloture.log (recalcul, jamais en lecture seule), VERDICT.md (+ consommation PLAFOND), journal de dérogation. `surveillance.log` ajouté à `NOMS_MODELE_RACINE_FICHIERS`.
- **Canary** : catégorie `D1` de `lire_canaris` (hors `GATES`), cas `D1-trace` (`FileChanged:.planning/<état composé par variable>`), attendu `trace` : première observation puis fichier modifié hors moteur, une ligne `contournement` exigée au journal du lab synthétique.
- **Référence** (`modele-cycles.md`) : noms protégés par G6, arborescence, sous-section « D1 — écritures surveillées » (liste, borne, journal, règle d'explication, écrivains, réconciliation, signal, sorties, fail-open, coût nul, canary), limites (ax) à (ba) chacune sur sa ligne, contrat par événement, section canary.
- **Suites** : `test-d1-surveillance.sh` (nouvelle, 27 contrôles : R-D1-01 à R-D1-14 et 13 mutants) ; `test-planning-gates.sh` (R-CANG-D1, MUT-CANG-D1-CAS, quatre `LIMITES_REFERENCE`, « (a) à (ba) ») ; compteurs de suites des README 107 -> 108.

Copies armées : `test-d1-surveillance.sh` n'arme que G6 et G5 (copie `g6`), G3, G4, G4′ restent à `observe` (discipline du correctif 5c46c503) ; aucune copie ne touche à l'armement de D1 (il n'en a pas, `ARMEMENT_D1` absent).

## Vérifications (commande -> rc + ligne finale)

| Commande | rc | Ligne finale |
|---|---|---|
| `test-d1-surveillance.sh` (entière, HEAD ; forme du plan T1, T2, T3) | 0 | `== Résultat : 27 OK · 0 KO ==` ; contrôle de durée `substr($0,9)+0` : `DUREE s=198` (< 600), VERIFY-RC=0 ; tous les `✓ R-D1-01..14`, `✓ MUT-D1-*` requis présents, aucun `✗` ni `NON TUÉ` |
| `test-planning-gates.sh` ENTIER (HEAD fc9463be) | 0 | `== Résultat : 473 OK · 0 KO ==` (DUREE 672 s) |
| `VF_GATES_SECTIONS=g6,reference test-planning-gates.sh` (T1) | 0 | `== Résultat : 27 OK · 0 KO ==` |
| `VF_GATES_SECTIONS=cang,reference test-planning-gates.sh` (T3) | 0 | `== Résultat : 36 OK · 0 KO ==` ; `✓ R-CANG-D1`, `✓ MUT-CANG-D1-CAS TUÉ` |
| `test-recalc-planning.sh` (T2) | 0 | `== Résultat : 405 OK · 0 KO ==` (684 s sous charge ~200) |
| `test-cloture-empreintes.sh` (HEAD) | 0 | `== Résultat : 40 OK · 0 KO ==` (1re passe T2 : 33 OK / 7 KO, voir déviation 5) |
| `test-cloture-gates.sh` (HEAD) | 0 | `== Résultat : 45 OK · 0 KO ==` |
| `test-g4p-sortie-brute.sh` (HEAD) | 0 | `== Résultat : 19 OK · 0 KO ==` |
| `plugin/_internal/tests/test-planning-hook-installed.sh` | 0 | `== Résultat : 25 OK · 0 KO ==` |
| `test-rejeu-gates.sh` (critère d'acceptation, T3) | 0 | `== Résultat : 91 OK · 0 KO ==` |
| `test-planning-hook-registered.sh` (entière, HEAD) | **1** | `== Résultat : 106 OK · 6 KO ==` : voir « BLOCAGE » |
| `check-planning-consumers-registered.sh` | 0 | `✓ 127 .sh suivi(s) hors tests/ balayé(s) … tous recensés ; volet ci.yml : oui` |
| `check-version-sync.sh` | 0 | `✓ sources synchronisées (v2.68.0, 17 modules)`, suites 108 |
| `check-machine-paths.sh` | 0 | `✓ 1928 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` |
| `45-CONTROLE-MARQUEUR.sh --base=247194c7 -- plugin/planning-core/scripts plugin/planning-core/hooks` | 0 | `MARQUEUR-BILAN commits=23 sans-marqueur=0` |
| `check-gate-touche.sh --base-ref 92ef7cff…` | 3 | `RIEN-A-JUGER` (surface surveillée non touchée ; 3 marqueurs conformes) |
| acceptances : 4 lignes `limite (ax|ay|az|ba)` ; `ARMEMENT_D1` absent ; 4 `def inscrire_surveillance` ; `surveillance.log` dans recalc | 0 | conformes |

Mutants tracés (assertion · attendu · obtenu, voir la sortie de la suite) : MUT-D1-ADHESION, DOSSIER, BORNE, TRACE, MOTEUR, INTENTION, INTENTION-REUTILISEE, AST, RECONCILIATION, SIGNAL-REPETE, REFUS, WATCH-FILECHANGED, FENETRE, MUT-CANG-D1-CAS : tous « TUÉ », témoin inchangé.

## Deviations from Plan

1. **[Rule 1 - Défaut du plan] Contrôle de durée** : `substr($0,8)+0` sur `DUREE s=…` vaut toujours 0 ; la forme correcte `substr($0,9)+0` a été jouée (198 s). Plan non corrigé (consigne).
2. **[Rule 1] `consommer` ast-identique** : la ligne `moteur` du hook était d'abord dans `consommer`, ce qui rompait R-EMP-04 et R-PLAF-04 (copie de poser-verdict.sh) ; déplacée chez l'appelant `decider` (balise `# d1-moteur-consommation`), vue rouge puis verte (33 OK / 7 KO -> 40 OK / 0 KO).
3. **[Rule 2] Consommation PLAFOND par `poser-verdict.sh`** : elle réécrit le journal de dérogation (surveillé) ; sans ligne `moteur` elle aurait été tracée comme contournement. Ligne ajoutée (non écrite au plan).
4. **Précision de la règle d'explication** : un sha égal à celui de la dernière référence n'est pas un changement (rien inscrit) ; sans cela, un événement `FileChanged` répété (écriture atomique, double notification) devenait un faux contournement, la ligne `moteur` précédant la nouvelle référence. Le plan dit « dans tous les cas une ligne reference est ajoutée » : lecture restreinte aux changements. Renversable.
5. **Défaut de la suite de la tâche 1, corrigé dans le commit de la tâche 2** : la mutation `MUT-D1-ADHESION` rejouait aussi ce dépôt par la commande complète ; le pré-filtre ne prouve pas la non-adhésion d'un `config.json` de plus de 128 octets, le mutant y laissait `.planning/surveillance.log` (fichier ignoré par git) et la passe suivante rougissait. Ce dépôt n'est plus rejoué que par le script réel. Pas de commit séparé (`git add -p` indisponible, un seul fichier de suite) ; fichier parasite supprimé.
6. **Signal** : l'ellipsis `…` n'est ajoutée que s'il y a plus de trois chemins distincts. Les cinq fichiers racine sont toujours listés, présents ou non (comme `SUMMARY.md` absent).
7. **Découpage** : la sortie de `CwdChanged` est produite en tâche 3 (mode), l'émission dans `main()` (SessionStart et CwdChanged) en tâche 1, comme le plan ; les entrées du journal sont groupées par chemin (une passe) pour borner le coût à 128 chemins.
8. **Exécution** : les suites longues sous charge 100-250 ont été déplacées en arrière-plan par la plateforme à 600 s (non demandé), attendues puis lues ; le scratchpad est partagé avec l'exécuteur 46-08 (un message de commit y a été écrasé, sans effet : mes commits étaient faits, fichiers suivants préfixés `d1-47-`).
9. **Hors périmètre, non touché** : `docs/HOOKS-CONTRAT-SORTIE.md` (forme de sortie des entrées 34 et 36 pour un lab adhérent) et la suite d'enregistrement (voir BLOCAGE) ; aucune release, bump, tag, STATE.md/ROADMAP.md.

## Limites déclarées (ax) à (ba)

#95440 (sourd après un `cd`, rattrapé par la réconciliation) ; aucun auteur dans le payload, une intention explique un changement ; `watchPaths` remplace la liste dynamique, forme hors SessionStart (A2) et chemin inexistant (A3) non mesurés ; première observation = référence, journal lu sur 4 Mio de fin, D1 fail-open.

## Known Stubs

Aucun.

## Threat Flags

Aucun (le journal de D1 est le seul fichier nouveau au frontière lab, déjà couvert par T-46-072 : protégé par G6, lignes encodées).

## Self-Check: PASSED

Fichiers présents (test-d1-surveillance.sh, hook, recalc, poser, deroger, canary, référence, suite des gates) ; commits ebe48336, a51e595f, fc9463be présents ; `ARMEMENT_D1` : 0 ligne ; STATE.md et ROADMAP.md non touchés ; aucune release, bump, tag ni push. Le BLOCAGE ci-dessus reste ouvert.
