---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 10
subsystem: planning-core
status: complete
requirements: [CLOT-11]
tags: [silence-hors-adhesion, prefiltre, evenements, mutants, cout, mesure]
commits: 3
plan_head_before: 7944d8097b874a1cc2583bf9efd7893d2b0281ef
commit_list:
  - 5436a1e7 test(planning-core): silence du hook installé sur un lab dev, cinq événements (46-10, P46-D-16)
  - 322a6869 test(planning-core): équivalence du pré-filtre sur les cinq événements (46-10, P46-D-16)
  - d3b65bf4 docs(planning): coût du pré-filtre par événement (46-10, P46-D-16)
estimate:
  tokens: 140000
  raw_tokens: 140000
  tasks: 3
  confidence: low
actuals:
  tokens: 13728
  tasks: 3
  commits: 3
  note: "chars/4 sur les lignes ajoutées et retirées du diff réalisé (842 lignes, 54910 caractères, base 7944d809, git diff --unified=0) ; non mesuré par le moteur ; commits mesurés par rev-list, hors le commit de ce SUMMARY"
duration: 31min
started: 2026-10-05T21:37:00Z
completed: 2026-10-05T22:08:00Z
worktree:
  branche: worktree-agent-a75dd5034dde80b6e
  chemin: .claude/worktrees/agent-a75dd5034dde80b6e
  base: 7944d8097b874a1cc2583bf9efd7893d2b0281ef
verdicts:
  code_review: absent
  nyquist: absent
  secure: absent
key-files:
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-COUT-PREFILTRE.md
  modified:
    - plugin/_internal/tests/test-planning-hook-installed.sh
    - plugin/planning-core/scripts/tests/test-planning-prefilter.sh
---

# Phase 46 Plan 10 : zéro régression hors adhésion et coût du pré-filtre — Summary

Un lab qui n'a pas adhéré ne voit rien et ne paie rien pour les cinq entrées de la phase : prouvé sur la commande INSTALLÉE (lab dev installé et ce dépôt, empreinte de l'arbre identique) et sur le cœur seul (mutation « adhésion ignorée » tuée pour les six sondes), équivalence du pré-filtre étendue aux payloads des événements nouveaux, coût mesuré par événement. Aucun code livré n'est modifié : seules les deux suites et le relevé le sont.

## Livré

- **`test-planning-hook-installed.sh`** (tâche 1, traceur) : sections `dev` et `mut_dev`.
  - R-INST-DEV-01 : copie du lab installé (config 2.0, G6 et G5 armés dans le script posé, agent producteur doté de Bash) ; l'entrée posée de chacun des cinq événements et SubagentHandback sous PreToolUse, rejouées avec leur payload : stdout vide, stderr vide, code 0, aucune ligne au journal d'observation, empreinte de l'arbre (sha256, mtime, liens non suivis) identique. 6 rejeux.
  - R-INST-DEV-02 : même rejeu avec cwd = racine de ce dépôt, empreinte de l'arbre du dépôt identique avant et après. Ce dépôt n'est rejoué que par la commande COMPLÈTE (le pré-filtre court-circuite avant le cœur).
  - R-INST-DEV-03 : SessionStart (sources startup, resume, clear, compact) et CwdChanged rendent un stdout vide, sans clé `watchPaths`, dans le lab dev installé et dans ce dépôt (10 rejeux) ; témoin : un lab adhérent fixture en rend une liste non vide.
  - MUT-DEV-ADHESION : motif unique `adherent = racine is not None and verifier_adhesion(` forcé vrai (`bash -n` et compilation du corps vérifiés) sur un lab dev installé FIXTURE, rejoué par la commande sans pré-filtre ; six traces de mort : PreToolUse deny G6, SubagentHandback et SubagentStop une ligne `gate=G4P` au journal d'observation, SessionStart et CwdChanged `watchPaths`, FileChanged `.planning/surveillance.log` créé. Une sonde non rougie est un KO « preuve aveugle pour <événement> ». Le cœur d'origine, atteint par la même commande, reste muet pour les six.
- **`test-planning-prefilter.sh`** (tâche 2) : section `evenements` (liste par défaut étendue).
  - PF-EVT-01 (A et E), PF-EVT-02 (B), PF-EVT-03 (plancher) sur 30 à 51 cas par événement : 14 labs du banc, 14 lieux de la forêt adverse, 18 cas croisés (fichier dans un lab adhérent, cwd dans un lab dev, et inverse, liens, préfixes de nom, sans cwd, `new_cwd` adhérent), déterministes. Tout report est rejoué (E, script présent), un sur quatre script absent.
  - L'oracle (B) dérive la racine par `evenement_de` et `depart_evenement` chargés depuis `planning-hook.sh` (FileChanged : `file_path` de premier niveau) ; les 18 cas croisés le calibrent par des jugements posés à la construction.
  - MUT-PF-EVT-FILECHANGED : l'oracle qui ignore le `file_path` de premier niveau fait rougir PF-EVT-02 sur 8 cas FileChanged et sur aucun autre événement. Rejouable seul par `VF_PF_MUT=MUT-PF-EVT` ; un `VF_PF_MUT` qui ne sélectionne rien est un KO (`MUT-FILTRE`).
- **`46-COUT-PREFILTRE.md`** (tâche 3) : deux tables (ce dépôt, lab adhérent synthétique), deux passes de 8 séries, charge avant et après chaque série, commit mesuré `322a6869`, FileChanged hors adhésion nul par construction (R-INST-DEV-03), scripts de mesure recopiés, aucun chemin de machine.

## Vérifications (commande -> rc + dernière ligne)

| Commande | rc | Dernière ligne `== Résultat` |
|---|---|---|
| `test-planning-hook-installed.sh` ENTIER (forme du plan T1 : `✓ R-INST-DEV-01/02/03`, `✓ MUT-DEV-ADHESION`, ni `✗`, `NON TUÉ` ni `aveugle`) | 0 (VERIFY-RC=0) | `== Résultat : 29 OK · 0 KO ==` (avant : 25 OK ; 14 s puis 51 s selon la charge) |
| `VF_PF_SECTIONS=evenements test-planning-prefilter.sh` (forme du plan T2, durée `substr($0,9)+0`) | 0 (VERIFY-RC=0) | `== Résultat : 5 OK · 0 KO ==` ; `DUREE s=6` (< 600) ; `✓ PF-EVT-01/02/03`, `✓ MUT-PF-EVT-FILECHANGED TUÉ` |
| `VF_PF_SECTIONS=table,bornes` (critère d'acceptation T2) | 0 | `== Résultat : 6 OK · 0 KO ==` (DUREE 14 s) |
| `VF_PF_SECTIONS=corpus` | 0 | `== Résultat : 5 OK · 0 KO ==` (DUREE 307 s, oracle à `depart_evenement` : corpus existant inchangé) |
| `VF_PF_SECTIONS=mutants VF_PF_MUT=MUT-PF-EVT` (famille neuve seulement) | 0 | `== Résultat : 2 OK · 0 KO ==` ; `VF_PF_MUT=MUT-INCONNU` : rc 1, `MUT-FILTRE` (jamais un vert à vide) |
| Section `mutants` ENTIÈRE du pré-filtre (second `<automated>` de T2) | non jouée | interdite en local (plus de 30 min) : CI |
| T3 : awk des cinq événements et de la médiane sur le relevé | 0 | exit 0 |
| T3 : awk « aucun /Users/ ni /home/ » sur le relevé | 0 | exit 0 |
| `scripts/check-machine-paths.sh` (après les trois commits) | 1 | `✗ 1 chemin(s) absolu(s) de machine` : `46-09-SUMMARY.md:29`, PRÉ-EXISTANT (voir déviation 8) ; aucun chemin dans `46-COUT-PREFILTRE.md` ni dans ce SUMMARY |
| `45-CONTROLE-MARQUEUR.sh --base=247194c7 -- plugin/planning-core/scripts plugin/_internal/tests` | 0 | `MARQUEUR-BILAN commits=32 sans-marqueur=0` |
| `check-gate-touche.sh --base-ref 7944d809` | 3 | `RIEN-A-JUGER` (surface surveillée non touchée ; 2 marqueurs conformes) |
| `check-planning-consumers-registered.sh` | 0 | `✓ 127 .sh suivi(s) … tous recensés ; volet ci.yml : oui` |
| `check-version-sync.sh` | 0 | `✓ sources synchronisées (v2.68.0, 17 modules)`, suites 109 (aucune suite nouvelle) |
| `git status` après les suites | — | propre ; aucun `surveillance.log` dans l'arbre (garde R-DEPOT-INTACT : les mutants et rejeux de cœur ne tournent que sur des fixtures) |

Opposabilité hors plan : copie du dossier `planning-core` dans le scratchpad dont `hooks.json` est muté (`file_path` retiré de l'expression du pré-filtre) ; la section `evenements` y rougit (PF-EVT-02 : les cas FileChanged croisés rendent `SHORT` au lieu de `DEFER`, 5 traces affichées et 4 autres violations comptées), l'original passe.

## Mesures (détail et charge : `46-COUT-PREFILTRE.md`, commit mesuré `322a6869`)

Médiane / p90 en ms, 40 rejeux entrelacés sous `/bin/sh`, commande complète puis commande sans pré-filtre. Passe 1 (la moins chargée), charge 1 min avant → après :

| Lieu | Événement | Complète | Sans pré-filtre | Charge |
|---|---|---|---|---|
| Ce dépôt | SubagentHandback | 39,8 / 57,9 | 102,3 / 148,5 | 8,29 → 8,59 |
| Ce dépôt | SubagentStop | 40,7 / 58,7 | 116,1 / 142,4 | 8,59 → 11,74 |
| Ce dépôt | SessionStart | 37,5 / 51,5 | 117,7 / 145,1 | 11,74 → 10,88 |
| Ce dépôt | CwdChanged | 36,1 / 49,6 | 104,8 / 139,4 | 10,88 → 12,81 |
| Lab adhérent | SubagentHandback | 133,5 / 189,7 | 114,9 / 147,6 | 12,81 → 18,01 |
| Lab adhérent | SubagentStop | 187,5 / 256,3 | 158,4 / 302,3 | 18,01 → 20,87 |
| Lab adhérent | SessionStart | 58,5 / 64,4 | 52,0 / 57,8 | 18,87 → 17,60 |
| Lab adhérent | CwdChanged | 55,6 / 144,6 | 50,1 / 139,4 | 17,60 → 16,43 |

Passe 2 (charge 16,62 à 39,14) : mêmes tendances, valeurs absolues plus hautes (voir le relevé). Aucune série n'a atteint le marquage « sous charge X » : une seule a attendu la sonde (passe 1, lab adhérent, SessionStart, 20,87 puis 18,87) ; deux séries finissent à plus de 20 (20,87 et 39,14), signalées. Plancher `/bin/sh -c ':'` : 13,1 / 17,4 ms à la charge 19,83. Les valeurs absolues varient d'un facteur trois avec la charge ; seules les comparaisons au sein d'une série sont fiables. Aucun seuil conclu.

## Deviations from Plan

1. **[Défaut du plan] Contrôle de durée** : `substr($0,8)+0` sur `DUREE s=…` vaut toujours 0 ; la forme correcte `substr($0,9)+0` est jouée (`DUREE s=6`). Plan non corrigé (consigne).
2. **[TDD] Pas de rouge avant vert** : le code livré satisfait déjà la propriété ; les contrôles sont sortis verts du premier coup. L'opposabilité est portée par MUT-DEV-ADHESION (six traces), MUT-PF-EVT-FILECHANGED, et la mutation de `hooks.json` jouée en copie (ci-dessus).
3. **[Discrétion] « Lab dev installé »** : copie du lab où l'installeur a posé planning-core, avec config 2.0, un `STATE.md`, un agent producteur doté de Bash et G6 et G5 armés ; la sonde PreToolUse est un Write de `.planning/STATE.md` (sans armement elle ne mourrait pas sous le mutant). Les six traces sont des lignes `trace MUT-DEV-ADHESION <sonde> …` suivies d'UNE ligne `✓ MUT-DEV-ADHESION TUÉ`, de sorte que le compteur `✓` ne compte pas six fois un même mutant.
4. **[Ajouts non écrits au plan, dans `files_modified`]** (suite du pré-filtre) : (a) l'oracle `coeur` passe par `evenement_de` et `depart_evenement` pour TOUS les payloads (identique pour PreToolUse, vérifié par la section `corpus` : 5 OK) ; (b) `main` : la section `corpus` ne coupe plus la liste (le `break` empêchait `evenements`, placée à sa suite par défaut, de jouer ; un drapeau empêche de rejouer `mutants` deux fois) ; (c) `fabriquer_banc` extrait de `corpus_banc` et `garde` accepte le pas d'échantillonnage de (E) (`pas_e`, `pas_e_absent`) ; (d) alias `VF_PF_MUT=MUT-PF-EVT` sur la section `mutants` et KO `MUT-FILTRE` quand un filtre ne sélectionne rien ; (e) en tâche 1, les sondes sont aussi rejouées sous la commande SANS pré-filtre pour l'original (témoin).
5. **Section `mutants` complète du pré-filtre non jouée en local** (consigne) : seule la famille neuve l'a été ; les mutants existants dépendent de `garde` et de `coeur`, vérifiés par la section `corpus`. Arbitrage de la CI.
6. **Trailer d'attribution** : celui de la configuration (`Claude Sonnet 5.5`, `Claude-Session`) au lieu de `Claude Opus 5.5 (1M context)` du plan ; `Gate-Touche:` sur les deux commits de suites ; pas de trailer sur le commit du relevé (artefact de phase).
7. **Mesure** : fixtures sous le dossier de travail du scratchpad (le plan dit `mktemp -d`, la consigne interdit d'écrire hors worktree et scratchpad) ; DEUX passes au lieu d'une (la charge ressentie a varié de 8 à 39), plus un plancher de lancement et un contrôle ad hoc de la coïncidence des lieux (cœur seul : ce dépôt 171,1 / 164,7 ms, lab adhérent 166,1 / 161,5 ms, dossier sans `.planning` 144,0 ms, charge 20,1 à 21,2, marqué sous charge 20 à 21). La sonde de charge est du Python (jamais `sleep` en Bash).
8. **[Pré-existant, hors `files_modified`, non corrigé] `check-machine-paths.sh` rouge** : `46-09-SUMMARY.md:29` (`chemin:` du bloc `worktree`) cite un chemin absolu de machine. Preuve contre la base : `git show 7944d809:<46-09-SUMMARY.md>` contient la même ligne 29 ; mon diff ne touche que trois fichiers. Correction minimale proposée : rendre le chemin relatif à la racine du dépôt (`.claude/worktrees/agent-a93e81ce51a955dd7`). Le manager indique que la base a avancé (`d172c33f`, qui ne touche que ce SUMMARY) : l'intégration est faite par vf-coder.

## Points à arbitrer (ask-user)

- **A de PF-EVT-01 ne regarde que stdout et le code** : un court-circuit à tort sur un lab adhérent produit, sous FileChanged, un effet de fichier (journal de D1) que (A) ne voit pas ; c'est (B), par l'oracle, qui le voit (prouvé par la mutation de `hooks.json` en copie : PF-EVT-02 rougit, PF-EVT-01 reste vert). Étendre (A) à l'empreinte du lab pour les SHORT est possible (~20 lignes) : à autoriser.
- **Valeurs absolues du relevé** : mesurées sur une machine jamais au repos (charge 8 à 39) ; à rejouer au repos si 46-12 veut des chiffres absolus pour `modele-cycles.md`. Les écarts intra-série (ce dépôt : la commande complète est plus rapide sur 8 séries sur 8 ; lab adhérent : plus lente de 5,5 à 29,1 ms) sont, eux, de même sens dans les deux passes.
- **Section `mutants` du pré-filtre** : à confirmer par la CI après intégration (non jouée en local, consigne).

## Known Stubs

Aucun.

## Threat Flags

Aucun. T-46-101 (coût ou bruit du hook sur les labs dev) : silence prouvé sur l'installation réelle, MUT-DEV-ADHESION, coût mesuré et publié. T-46-102 (pré-filtre qui taît un lab adhérent) : PF-EVT-02 et MUT-PF-EVT-FILECHANGED. T-46-103 (chemin de machine dans le relevé) : contrôle avant `git add` et `check-machine-paths.sh` (aucune occurrence dans le relevé).

## Self-Check: PASSED

Fichiers présents : `46-COUT-PREFILTRE.md`, `test-planning-hook-installed.sh`, `test-planning-prefilter.sh` ; commits `5436a1e7`, `322a6869`, `d3b65bf4` présents (`git rev-list --count 7944d809..HEAD` = 3 avant ce SUMMARY) ; STATE.md et ROADMAP.md non touchés, aucune commande `state.*` ni `roadmap.*` ; aucune release, tag, push, `git stash`, `checkout`, `reset` ; aucun code livré modifié ; arbre propre après les suites.
