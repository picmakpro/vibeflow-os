---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 06
subsystem: planning-core
status: complete
requirements: [CLOT-06, CLOT-09, CLOT-12]
tags: [g4p, subagenthandback, subagentstop, canary, observe]
commits: 4
plan_head_before: c0f8adb88dd5f85d0fc8e4a1f8091daf54a09f90
commit_list:
  - d1519bea feat(planning-core): G4′ en observation sur SubagentHandback (46-06, P46-D-02, P46-D-02a)
  - 8ddc8db7 feat(planning-core): repli SubagentStop de G4′ hors mode auto, périmètre et canary (46-06, P46-D-02, P46-D-10)
  - 3944c6c9 docs(planning-core): grammaire et périmètre de G4′ dans la référence (46-06, P46-D-02a)
  - 5c46c503 fix(46-05): les copies armées de test-planning-gates.sh n'arment plus G3, G4 ni G4′ (régression CI 37334247079)
estimate:
  tokens: 170000
  raw_tokens: 170000
  tasks: 3
  confidence: low
actuals:
  tokens: 21000
  tasks: 3
  commits: 4
  note: "chars/4 sur les lignes ajoutées du diff réalisé (84120 caractères, base c0f8adb8) ; le fix(46-05) mandaté en cours de plan est compté dans les 4 commits"
key-files:
  created:
    - plugin/planning-core/scripts/tests/test-g4p-sortie-brute.sh
  modified:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/check-gates-alive.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/references/modele-cycles.md
    - docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md
    - README.md
    - README.fr.md
---

# Phase 46 Plan 06 : G4′ en observation — Summary

G4′ (rapport de sous-agent sans sortie de commande brute) est livré en `observe` : jugé au PreToolUse de `SubagentHandback`, avec repli `SubagentStop` hors mode auto, par une grammaire linéaire sans retour arrière, restreint aux workers et producteurs qui ont Bash.

## Livré

- `planning-hook.sh` : `sortie_brute_presente` (+ `_delimiteur_ouvrant`), `agent_a_bash` (lit `tools:` et `disallowedTools`), `evaluer_g4p` (balises `g4p-perimetre`, `g4p-capacite`, `g4p-verdict`) enregistré dans `GATES_A_VERDICT` après G4 ; `mode_subagent_stop` (garde `g4p-auto`, sortie par `sortie_blocage_subagent`, `decision: block` code 0) ; `erreur_subagent_stop` (phase B : block si armé, ligne d'observation sinon). La ligne unique `return None  # evt-mode-subagentstop` subsiste ; l'appel `sortie_blocage_subagent(raisons)` (16 espaces) reste unique (ancres des mutants EVT4, EVT7-S, EXIT2 de test-planning-hook-registered.sh).
- `check-gates-alive.sh` : producteur synthétique `canary-producteur` (tools Read, Bash), cas `G4P-handback` et `G4P-stop`, rapports `sans-sortie` / `avec-sortie`, verdict `block-gate` ; l'attendu armé d'un cas SubagentStop est `block-gate`, celui d'un cas SubagentHandback `deny-gate` (dérivé de la table).
- `test-g4p-sortie-brute.sh` (nouvelle suite, 19 contrôles et mutants) ; `modele-cycles.md` (sous-section G4′, ligne G4P de la table, contrat par événement, limites (au), (av), (aw)) ; `test-planning-gates.sh` (trois `LIMITES_REFERENCE`) ; spec §5 (précision du 2026-10-05 citant P46-D-02b : Willy, AskUserQuestion session principale, 2026-10-03, Q9 = a, et la garde du mode auto) ; compteurs README 106 -> 107.

## Verdicts (commande -> rc + ligne)

| Commande | rc | Dernière ligne |
|---|---|---|
| `test-g4p-sortie-brute.sh` (à chaque tâche et à HEAD) | 0 | `== Résultat : 19 OK · 0 KO ==` (DUREE 24 s sous charge faible, 170 s sous charge 130) ; avant la tâche 2 : 7 OK |
| `test-cloture-gates.sh` (HEAD) | 0 | `== Résultat : 45 OK · 0 KO ==` |
| `test-planning-gates.sh` ENTIER (HEAD hors commit de doc, copie de test corrigée) | 0 | `== Résultat : 471 OK · 0 KO ==` (DUREE 1514 s) |
| `test-planning-gates.sh` section `mutants` | 0 | `== Résultat : 73 OK · 0 KO ==` |
| `VF_GATES_SECTIONS=cang test-planning-gates.sh` (avant le fix) | 0 | `== Résultat : 16 OK · 0 KO ==` |
| `VF_GATES_SECTIONS=reference test-planning-gates.sh` | 0 | `== Résultat : 18 OK · 0 KO ==` ; R-REFERENCE et MUT-REFERENCE-LIMITES (49 limites) tués |
| `test-planning-hook-installed.sh` | 0 | `== Résultat : 25 OK · 0 KO ==` |
| `VF_REG_SECTIONS=evenements test-planning-hook-registered.sh` | 0 | `== Résultat : 15 OK · 0 KO ==` (R-EVT-04, R-EVT-07, MUT-EVT-EXIT2, EXIT2-STATIQUE, FAILOPEN verts) |
| `check-version-sync.sh` | 0 | `✓ sources synchronisées (v2.68.0, 17 modules)`, suites 107 |
| `check-machine-paths.sh` | 0 | `✓ 1926 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` |
| `plugin/conductor/scripts/check-planning-consumers-registered.sh` | 0 | `✓ 127 .sh suivi(s) … tous recensés ; volet ci.yml : oui` |
| `45-CONTROLE-MARQUEUR.sh --base=247194c7 -- plugin/planning-core/scripts plugin/planning-core/hooks` | 0 | `MARQUEUR-BILAN commits=19 sans-marqueur=0` (avant le commit fix : 19 commits ; le fix porte son trailer) |
| `check-gate-touche.sh --base-ref c0f8adb8` | 3 | `RIEN-A-JUGER` (surface surveillée non touchée ; 4 marqueurs conformes) |
| sondes de la tâche 3 (spec, limites au/av/aw = 3 lignes, « restriction livrée par le plan 46-06 » = 1) | 0 | conformes |

Preuves de mutants (extraits) : MUT-G4P-GRAMMAIRE, MUT-G4P-FERMETURE (R-G4P-GRAM-02), MUT-G4P-VERDICT (R-G4P-01), MUT-G4P-AUTO (R-G4P-05), MUT-G4P-ROLE et MUT-G4P-CAPACITE (R-G4P-03), MUT-G4P-CODE2 (R-G4P-04, rc=2 vu par le contrôle du cœur seul), MUT-G4P-ADHESION (R-G4P-08) : tous « TUÉ » avec trace attendu/obtenu.

Non joué en local : `test-planning-hook-registered.sh` entier (charge machine 40 à 170, plafonds « moins de 2 s » : constat connu 105 OK / 7 KO sous charge) : **CI** ; seule la section `evenements` (la seule que ce plan touche) est jouée. `test-planning-prefilter.sh` section `mutants` : jamais en local.

## Section dédiée : fix(46-05) — régression CI 37334247079 (mandat du manager reçu pendant le plan)

- Constat : 9 KO en CI sur c0f8adb8 (R-G5-04, R-G1-03, R-G1-10, R-ID-06, BANC g5/g1/imbrique-adherent, MUT-G5-PERIMETRE et MUT-G1-FORME « NON TUÉ »). Reproduit en local : 461 OK / 10 KO ; le dixième, MUT-PUCE-REGEX-FM « NON TUÉ », est apparu sous charge 175 et n'est pas revenu au rejeu (471 OK / 0 KO).
- Cause : `copie_forcee` et `copie_armee` de `test-planning-gates.sh` arment les huit constantes ; depuis la table à huit gates (46-05), G4 armé refuse à bon droit un `SUMMARY.md` sans `VERDICT.md`, que ces bancs rejouent en « doit-passer ».
- Correction (test uniquement, aucun affaiblissement de G4 en production) : `forcer_armement` arme G6, G5, G1, G7 et ROLE et laisse G3, G4, G4P à `observe` ; n == 8 conservé. G3, G4 et G4′ restent prouvés armés par `test-cloture-gates.sh` et `test-g4p-sortie-brute.sh` (copies propres).
- Preuve : suite entière 471 OK / 0 KO ; `MUT-G5-PERIMETRE TUÉ — R-G5-04 rougit … obtenu (mutant) : livrables/VERDICT.md -> deny · témoin inchangé` ; `MUT-G1-FORME TUÉ — R-G1-03 rougit … obtenu (mutant) : .planning/phases/01-x/PLAN.md -> deny …` (section `mutants` : 73 OK / 0 KO).

## Deviations from Plan

**1. [Rule 1 - Défaut du plan] Contrôle de durée** : la forme `substr($0,8)+0` du plan sur `DUREE s=…` vaut toujours 0 ; la forme correcte `substr($0,9)+0` a été jouée (DUREE 2 s à la tâche 1, 24 s à la tâche 2). Plan non corrigé (consigne).

**2. [Rule 1] Forme de commande** : `check-gate-touche.sh --base-ref <sha>` (espace) ; rc=3 `RIEN-A-JUGER`, comme en 46-05.

**3. Commit de tâche 2 : R-REFERENCE rouge entre les commits** : l'ajout des cas canary G4P (tâche 2) rend R-REFERENCE en écart tant que la cellule de la table n'est pas mise à jour (tâche 3, plan tel qu'écrit). Résolu par le commit de la tâche 3.

**4. Ajouts non écrits au plan** : (a) `erreur_subagent_stop` et un `elif` dans l'`except` de phase B de `main` (P46-D-10 exige block si armé ; sans cela l'erreur du mode restait en silence) ; (b) verdict de canary `block-gate` distinct de `deny-gate` (attendu dérivé par événement) plutôt qu'un objet block reconnu comme `deny-gate` ; (c) comportements de grammaire précisés : une ouverture ``` dont l'étiquette porte un accent grave n'ouvre pas, `$ ` suivi de deux blancs est refusé (lecture littérale), blancs de tête admis sur les lignes du bloc, CRLF toléré ; (d) contrôle du cœur seul dans R-G4P-04 (la couche shell de la commande masque un code 2 en silence : sans lui MUT-G4P-CODE2 n'était tué que par ce masquage) ; (e) mise à jour des commentaires d'en-tête du hook, du texte de la référence (contrat par événement, ordre de GATES_A_VERDICT) et de la section canary.

**5. Limite non traitée, à arbitrer (non modifiée)** : le repli `SubagentStop` ne lit pas `stop_hook_active` ; le plafond natif de huit relances (P46-D-02) est le seul garde-fou contre une relance répétée.

## Known Stubs

Aucun.

## Threat Flags

Aucun.

## Self-Check: PASSED

Fichiers présents (suite, hook, canary, référence, spec) ; commits d1519bea, 8ddc8db7, 3944c6c9, 5c46c503 présents ; `return None  # evt-mode-subagentstop` : 1 occurrence ; `("G4P", evaluer_g4p)` : 1 ligne ; STATE.md et ROADMAP.md non touchés ; aucune release, bump, tag ni push.
