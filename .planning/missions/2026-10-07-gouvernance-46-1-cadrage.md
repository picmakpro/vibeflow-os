# Mission 2026-10-07 — Phase 46.1 (gouvernance) : cadrage et planification de l'armement de G4 et G4′

**Manager :** `vf-dev-manager-p461-cadrage`
**Feu vert :** Willy, message en session principale, 2026-10-07 (« Oui lance »).
**Branche :** `gouvernance/phase-46.1-cadrage`, partie de `origin/gouvernance/phase-46-execution` @
`78808126` (PR #136, empilée #133 → #124), worktree `.claude/worktrees/gouvernance-46-1`.
**Compartiment :** `gouvernance` (`--ws gouvernance`).
**Verrou :** acquis, génération `DRIVER.lock.gen.1791361612.53884`, 0 orphelin ; relâché en fin de
session (attente humaine).
**Invariants :** `check-mission-invariants.sh` → 3 (SAIN).
**Flags d'enchaînement :** `workflow._auto_chain_active` et `workflow.auto_advance` déjà à `false`,
vérifiés par lecture de `.planning/config.json` (`gsd_run` non résolu sur ce poste).
**Budget :** snapshot posé (`check-mission-exit.sh --budget-snapshot`, fichier
`<dépôt principal>/.git/vf-mission-budget.snap`, partagé entre worktrees : une autre
session peut l'écraser).
**Issue (session du 2026-10-07) :** `human_needed` — cadrage gelé dans l'attente des réponses de Willy à Q1-Q5.
**Issue (reprise du 2026-10-12) :** `passed` — cadrage écrit, 18 plans, plan-check frais PASSED au tour 4, PR de
planification ouverte : PR #146 (base `gouvernance/phase-46-execution`, empilée sur #136). Aucune exécution, aucun rejeu, aucun armement.

## Plan de bataille (DAG `2026-10-07-gouvernance-46-1-cadrage.dag.json`)

`scouting-461` ∥ `recherche-461` → `discuss-461` → `plan-461` → `plancheck-461` → `suivi-461` →
`pr-461`

## Déroulé

1. **Relevés parallèles, lecture seule** (commit `28b7d782`) :
   - `46.1-SCOUTING.md` : les 343 refus G4 de l'étape 5 sont tous des réécritures à l'identique,
     par `Write`, de `SUMMARY.md` existants sur `~/jarvis-keystone` (336 niveau plan, 7 niveau
     phase), dans des unités sans `VERDICT.md` ni `CLOTURE.md` ; le banc n'a aucun cas
     `doit-refuser` sur un `SUMMARY.md` existant ; ces 343 bloquent aussi l'étape 6. A2, A3, A4, P1,
     remèdes de D1 et (bu) établis chemin:ligne.
   - `46.1-RECHERCHE-HOOKS.md` (Claude Code 2.1.292) : le payload ne dit pas quel fichier de
     définition est chargé ; `cwd` suit les `cd`, `CLAUDE_PROJECT_DIR` est fixe mais = dossier de
     lancement ; **le compteur de relances natif repart à zéro à chaque appel d'outil** (le
     plafond de 8 ne borne pas une boucle G4′ qui fait lancer Bash) ; `stop_hook_active`
     absent/null au premier passage ; `SubagentHandback` seulement en auto mode.
2. **Cadrage** : cinq questions envoyées d'un bloc par `SendMessage(main)` (repli D-09), avec
   recommandation — détail et options : `46.1-DISCUSSION-LOG.md` (commit `42bf54c4`). Aucune
   réponse reçue après environ cinq heures d'attente au premier plan ; nœud `discuss-461` gelé,
   aucune décision humaine supposée.

## Questions en attente (Willy)

Q1 unités antérieures à G4 (recommandé : exemption étroite de la réécriture sans `VERDICT.md` ni
`CLOTURE.md`) · Q2 A2 (recommandé : jugé dès ambiguïté) · Q3 A3 (recommandé : union `cwd` /
`CLAUDE_PROJECT_DIR`) · Q4 A4/P1 (recommandé : compteur par agent_id sous verrou, un blocage puis
passage tracé, panne du cœur fail-open tracé) · Q5 D1 (recommandé : N-5 et A5 dans la 46.1, le
reste en limites + BACKLOG).

## Décisions du manager annoncées (renversables)

(bu) par script de décision versionné et testé ; ordre P46-D-11 (5b puis 6) avec checkpoint humain
au moment de chaque rejeu réel et armement ; aucune sonde `claude -p` ; `planning-core` v2.11.0
sans release ; préfixe `ARMG` (vérifié libre par `git grep`), décisions `P461-D-xx`.

## Constats à relayer

- La recherche a observé que la session de mission tourne en `bypassPermissions` (0 hand-back sur
  60 sous-agents) : observation de poste, aucun drapeau posé par un worker.
- Écarts documentaires de la 46 non corrigés (lecture seule) : `modele-cycles.md:1147` (« relevé
  de l'étape 6 à venir ») contredit `:1059` ; `46-RESEARCH.md:379` démenti par le relevé de
  l'étape 5. À prendre dans les plans de la 46.1.

## Décompte

Mandats émis : 2 (`general-purpose` scouting, 313 952 jetons ; `general-purpose` recherche,
178 134 jetons), 0 reprise. Tours de revue : 0. Commits : `28b7d782`, `42bf54c4`, plus celui de ce
rapport.

## Preuves E6

Aucune : aucun sprint `vf-coder` exécuté dans cette mission.

## Next step

Relayer Q1-Q5 à Willy (AskUserQuestion), puis relancer la mission sur les réponses : écriture de
`46.1-CONTEXT.md`, exigences `ARMG`, puis `plan-461` (`vf-coder`, `gsd-plan-phase 46.1 --ws
gouvernance`), plan-check frais, PR empilée sur #136.

## Reprise du 2026-10-12

**Relance :** message de la session principale (coordinateur), 2026-10-12 : les réponses de Willy
étaient arrivées en session principale le 2026-10-07 sans être relayées à temps (défaut du head,
pas de la mission). Rapportées verbatim : Q1-Q4 « (a) … (Recommandé) », arbitrages Willy,
AskUserQuestion session principale, 2026-10-07 ; Q5 « (a) N-5 et A5 (Recommandé) », arbitrage
Willy, AskUserQuestion session principale, 2026-10-12. Décisions du manager annoncées non
renversées.

**Contrôles de reprise :** branche inchangée depuis `2840fa5f` (local = origin), base de la PR #136
inchangée (`78808126`). Snapshot de budget intact mais lié à l'ancienne génération du verrou :
reposé sous la génération neuve `DRIVER.lock.gen.1791803429.58344` (E7 l'aurait jugé « snapshot
d'une autre mission »). Verrou ré-acquis, 0 orphelin ; invariants 3 (SAIN) ; flags d'enchaînement à
`false` (lecture).

**Déroulé :**
1. Cadrage écrit par le manager (Pattern F) : `46.1-CONTEXT.md` (P461-D-01..15), exigences
   ARMG-01..10 au ledger du compartiment, journal de discussion complété, ROADMAP (commit
   `8519c402`). P461-D-02 renverse en partie P46-D-02b, consigné.
2. Planification par `vf-coder` (`gsd-plan-phase 46.1 --ws gouvernance`) : carte des motifs,
   18 plans en 18 vagues (planning-hook.sh commun à presque tout), plan-check interne PASSED au
   3e passage (commit `54054fb1`).
3. Plan-check frais :

   | Tour | Juge | Résultat |
   |---|---|---|
   | 1 | deux checkers (fidélité ; exécutabilité) | 1 bloquant (non-régression non imputable), 4 majeurs, 6 mineurs |
   | 2 | un checker, angles combinés + régressions | tour 1 fermé ; 1 majeur (suites longues non détachées), 3 mineurs |
   | 3 | un checker ciblé | 1 majeur (disjonction G4 en commande composée, refusée par la garde d'isolation), 1 mineur |
   | 4 | un checker ciblé | **PASSED**, 0 bloquant, 0 majeur, 1 mineur |

   Corrections : décisions du manager P461-D-16 (régime de non-régression : base mesurée une
   fois, découverte complète au manager à trois jalons, imputation d'un rouge par rejeu sur le
   commit parent) et P461-D-17 (G4 armé couplé au code livré ou à une décision humaine au moment
   d'agir) (`1caf9110`) ; corrections ciblées des plans `ae40403c`, `4586c57c`, `e1d0c36c`,
   `0542baa5`.
4. Suivi : STATE et ROADMAP du compartiment à la main ; gates de planning rejoués à la main
   (`check-state-integrity.sh --file .planning/workstreams/gouvernance/STATE.md` → rc 0 après
   correction d'une seconde ligne `^Phase:` que ce suivi venait de créer ;
   `check-machine-paths.sh` → rc 0, après retrait d'un chemin de machine de ce rapport).

**Reste mineur connu (non bloquant) :** plan 17, cas d'autotest `garder-g4-mal-forme` qui mêle
deux raisons de rougir (canal vide, date de forme invalide) ; une date de bonne forme mais
invalide (`2026-13-45`) n'est pas éprouvée. À fermer à l'exécution du plan 17.

**Décisions du manager acceptées sur signalement des workers :** borne de sondage de la mesure de
base (`BORNE_MESURE_BASE`, 14 400 s, exception déclarée) ; plans 14 et 17 à 4 tâches chacun
(taille signalée, non scindés) ; contrôle de repos qui compte aussi les fichiers ouverts sous un
lab (plus strict que P461-D-07) ; borne du rejeu réel de l'étape 6 = 3 × la durée du relevé 5b.

**À dire à Willy avant d'exécuter :** coût d'exécution élevé (18 plans séquentiels, base de
non-régression ~2-3 h au plan 14, rejeux détachés) ; les checkpoints des plans 04, 05, 11 et 12
lui demanderont au moment d'agir l'autorisation des rejeux réels, le repos des labs et chaque
armement ; P461-D-17 lui fera trancher le sort de G4 armé si le code livré n'a pas de relevé
armable. Un worker de révision a mentionné un message d'un autre agent auquel il n'a pas
répondu : non suivi par la mission.

### Décompte de la reprise

Mandats émis : 9 (vf-coder planification 1, vf-coder correction 3 dont une reprise par
`SendMessage`, gsd-plan-checker 5). Jetons rapportés par les blocs typés reçus : 265 307
(planification) + 199 036 et 159 629 + 174 830 (corrections) + 273 065, 177 530, 130 431,
95 061, 85 902 (plan-checks) = 1 560 791. Mission entière (avec la session du 2026-10-07) :
11 mandats, 2 052 877 jetons rapportés.

### Preuves E6

Relayées verbatim des blocs typés `vf-coder` :
- planification : `[{"verdict":"recette","preuve":"amont"}]`, verdicts `{"code_review":"absent","nyquist":"absent","secure":"absent"}`
- correction n°1 : `[{"verdict":"recette","preuve":"amont"}]`
- corrections n°2 et n°3 : `[{"verdict":"recette","preuve":"amont"}]`

Aucun sprint d'exécution dans cette mission.

### Next step

Revue de la pile de PR (#124 → #133 → #136 → PR de planification 46.1) par Samuel, puis
exécution de la Phase 46.1, plan 14 en premier (mesure de la base de non-régression).
