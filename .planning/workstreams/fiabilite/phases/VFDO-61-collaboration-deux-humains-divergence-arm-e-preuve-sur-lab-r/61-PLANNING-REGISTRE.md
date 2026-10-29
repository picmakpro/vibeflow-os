# Phase 61 — Registre du planificateur (P61-PL-NN, P61-PB-NN)

Écrit le 2026-10-29, sous mandat Samuel, /vf-auto session principale, 2026-10-29 (« reprends le handoff et va jusqu'au bout
[…] Fini les phases du jalon sans moi ») — ce mandat ne vaut pas arbitrage de fond. Aucune ligne ci-dessous n'est un
arbitrage neuf : chacune est une conséquence d'un défaut écrit (P61-D-01..10), de l'hypothèse retenue faute de réponse
(P61-H-01), d'une mesure faite à la planification, ou de la discrétion laissée au planificateur (« Forme exacte […] au choix
du planificateur », P61-D-02 ; « Le planificateur mesure », P61-D-05). Samuel est absent ; aucune question n'a de réponse.
Les questions ouvertes Q1-Q3 de `61-RESEARCH.md` sont traitées ici (mesure d'abord, défaut du cadrage ensuite) ; aucune n'a
dû devenir un bloqueur.

Huit plans en cinq vagues, au plus deux plans par vague, `files_modified` disjoints dans chaque vague :
W1 61-01 (tracer), 61-02 · W2 61-03, 61-04 · W3 61-05, 61-06 · W4 61-07 · W5 61-08 (porte).
Gate de couverture des décisions (`check.decision-coverage-plan`) : le parseur ne lit pas les identifiants préfixés
`P61-D-NN` (même constat qu'en Phases 59 et 60) ; couverture vérifiée à la main ci-dessous.

## Mesures faites à la planification (2026-10-29, macOS, git 2.50.1 Apple Git-155)

- **Hooks déclenchés** (dépôt jetable, hooks témoins `post-merge`, `post-rewrite`, `post-checkout`) : `git pull` en avance
  rapide → `post-merge 0` ; `git pull --ff-only` → `post-merge 0` ; `git pull --rebase` SANS commit local → `post-merge 0` ;
  `git pull --rebase` AVEC commit local → `post-checkout` puis `post-rewrite rebase`, jamais `post-merge` ;
  `git merge --squash` → `post-merge 1` ; `git commit --amend` → `post-rewrite amend` ; `git reset --hard origin/main` →
  aucun ; `git switch --detach` → `post-checkout` seul ; `git cherry-pick` → aucun ; `git rebase` qui ne réécrit aucun commit
  → `post-checkout` seul.
- **Hook dans un worktree lié** : `--show-toplevel` = le worktree lié, `--git-common-dir` = le `.git` principal (absolu),
  `GIT_DIR` exporté par git vers `.git/worktrees/<nom>` ; `git rev-parse --git-path hooks` rend `.git/hooks` (relatif)
  depuis le worktree principal et le chemin absolu commun depuis un worktree lié.
- **Cache du plugin versionné** : `~/.claude/plugins/cache/vibeflow-os/vibeflow/<version>/`, quatre versions présentes en même
  temps sur ce poste (2.69.1, 2.70.0, 2.71.0, 2.71.2) ; `vf-update-run.sh` relance `update --all` avec le cache le plus
  récent (`VIBEFLOW_CACHE="$NEW"`). Politique de purge des anciennes versions : non mesurée (hypothèse A3).
- **Porteur du bump de l'engine** : `plugin/_internal/` n'a pas de `VERSION` ; les changements de `vibeflow-update.sh` sont
  inscrits au CHANGELOG de `conductor` (précédent Phase 58 et entrées antérieures, `plugin/conductor/CHANGELOG.md:948`).
- **Gabarits des registres** : source et copies diffèrent déjà (bandeau SYNC, ligne « Index maintenu par la machine », index
  vide) ; `seed-registres.sh` copie le gabarit ENTIER comme registre initial (squelette d'entrée compris).
- **Surfaces des gardes** : G-2 ne surveille, dans cette phase, que `plugin/conductor/scripts/tests/test-*.sh` (le script
  neuf `vf-divergence-hook.sh` n'est pas un `check-*`) ; SOBR-05 ne surveille aucun fichier que la phase ajoute.
- **Base** : `merge-base HEAD origin/main` = `1c2ae090`, 100 commits jusqu'à HEAD ; base de phase PB = parent de
  `3368a7d8` (`docs(61): cadrage de la Phase 61`).
- **Calibration** : `estimate-calibration --ws fiabilite` → facteur 1, zéro échantillon, confiance `low`.

## Décisions du planificateur

| ID | Décision | Source / rationale | Plans |
|----|----------|--------------------|-------|
| P61-PL-01 | Un seul script de conductor, `vf-divergence-hook.sh`, porte l'armement, le désarmement, le rafraîchissement, l'état et le travail du hook (verbes `arm`, `disarm`, `status`, `run`) ; l'engine ne fait qu'appeler ses verbes depuis le cache du plugin (`find_divergence_hook`, cache seul, patron `find_role_gate`). Aucune bibliothèque partagée : rien n'est partagé | P61-D-01 (« dans `role_apply()` ou à côté »), P61-D-03, audit M-2 ; diff de l'engine minimal (collision possible avec la Phase 48 de Willy, installeur) | 01, 03, 04 |
| P61-PL-02 | Forme du hook : un fichier par hook (`post-merge`, `post-rewrite`) dans `git rev-parse --git-path hooks`, contenu statique en sh POSIX : ligne de marqueur `# vibeflow:vf-divergence-hook v1`, chemin ABSOLU physique du script dans le cache entre apostrophes, `exec bash` du verbe `run` ; script introuvable → `NON VERIFIABLE` sur stderr et ligne de journal `introuvable`, jamais un silence. Chemin contenant une apostrophe, un saut de ligne ou relatif → refus en code 2 | P61-D-02 (forme au choix du planificateur), P61-D-03 ; RESEARCH §1 (chemin absolu résolu à l'armement) | 01, 03 |
| P61-PL-03 | Refus d'armement (code 1, message, ligne à ajouter à la main, variable de sortie) : `post-merge` ou `post-rewrite` tiers (sans marqueur) ; `core.hooksPath` configuré à N'IMPORTE quel niveau (husky : répertoire versionné ; global : armerait tous les dépôts du poste) ; script résolu SOUS l'arbre de travail inspecté (Q2 : on refuse, on ne résout pas) ; lab qui n'est pas la racine du dépôt git. Le refus ne fait JAMAIS échouer l'installation : l'engine relaie le code et le message sur stderr, poste et modules posés, code de sortie de l'engine inchangé | P61-D-02 (« l'armement est refusé », pas l'installation), P61-D-03, P61-D-06 (non-interactif préservé) ; **à confirmer par Samuel** (lecture « code = code du verbe relayé ») | 01, 03, 04 |
| P61-PL-04 | Q1 : un hook tiers qui contient la ligne d'appel (`vf-divergence-hook.sh' run --hook <nom>`) est reconnu « armé à la main » (`arm` rend 0, `status` le dit, chemin périmé signalé avec la ligne à jour) ; `disarm` ne le modifie jamais et imprime la ligne à retirer (code 1) | P61-D-02 (ni écrasé ni modifié) ; ADR-031 | 03 |
| P61-PL-05 | P61-D-05 tranché par la mesure : `post-rewrite` double `post-merge`, argument `rebase` seul (`amend` = silence). Limites écrites (en-tête du script, README de conductor, manuel, recette) : `reset --hard`, `switch`/`checkout`, `cherry-pick`, `rebase` sans commit réécrit ne déclenchent aucun des deux ; une fusion faite sur la forge est vue au `git pull` local suivant (`post-merge 0`) | Mesures ci-dessus ; ADR-069 amendement 4 | 03, 05, 07 |
| P61-PL-06 | Journal : `<git-common-dir>/vf-divergence/journal.tsv`, première ligne `# vf-divergence journal v1` suivie (tabulations) des sept noms de champs, une ligne par exécution non silencieuse, sept champs séparés par une tabulation : date UTC ISO 8601, hook, verdict (`DIVERGENCE` ou `NON-VERIFIABLE`), code de `check-divergence.sh` (ou `-`), HEAD complet (ou `-`), signaux (`S2,S4a,S4b,S5` dans cet ordre, ou `-`), raison (`introuvable`, `executable-dans-l-arbre`, `hors-depot`, `code-<n>`, ou `-`). Aucun contenu du dépôt n'y entre. Le journal survit au désarmement (preuve de la recette) ; lien symbolique ou fichier non régulier jamais suivi | P61-D-04 ; précédent `<git-common-dir>/vf-driver/` | 01, 03, 05 |
| P61-PL-07 | Sortie : variable `VF_DIVERGENCE_HOOK` (vide ou `on` = défaut, `off` = sortie), lue à `install` quand un poste est posé, au verbe `role` et à `update --all` ; `off` : rien n'est armé et un hook nôtre déjà posé est retiré ; toute autre valeur → refus de l'engine (code 1), valeur jamais réimprimée | P61-D-06 (« variable d'environnement ou option ») ; patron de validation fermée de `VF_ROLE` | 04, 07 |
| P61-PL-08 | Déclencheurs : armement à `install` avec poste `product`/`dev` et au verbe `role product|dev` ; désarmement au poste `solo` (verbe `role solo`, ou `install` avec `VF_ROLE=solo` sur un fichier de poste existant), à `uninstall --all` (scope project/local, hors `--target`) et sous `off` ; rafraîchissement à `update --all` (scope project/local) : un hook NÔTRE déjà posé est réécrit avec le chemin du nouveau cache, un clone non armé n'est JAMAIS armé par une mise à jour. Lab non git → code 3, ligne d'information, rien d'armé. `uninstall <module>` seul ne désarme pas (le hook vit du cache, pas du module installé) | P61-D-01, P61-H-01, ADR-031 ; cache versionné (mesure) : sans rafraîchissement le hook resterait sur une version purgée. Un lab dont le poste a été posé AVANT cette version s'arme par `role <poste>` (écrit au manuel) ; **à confirmer par Samuel** | 04, 07 |
| P61-PL-09 | Garde à l'exécution (défense en profondeur, P61-D-03) : `run` refuse en `NON-VERIFIABLE` (`executable-dans-l-arbre`) si son propre dossier physique est sous le `--show-toplevel` inspecté ; `check-divergence.sh` n'est résolu que comme voisin du script dans le cache ; répertoire inspecté = `--show-toplevel` du hook ; appels git sous `-c core.fsmonitor= -c core.hooksPath=/dev/null`, `GIT_OPTIONAL_LOCKS=0` | P61-D-03 ; patron `git_safe` de `check-divergence.sh` | 01, 03 |
| P61-PL-10 | Codes de `run` : 0 silence (code 0 ou 3 de `check-divergence.sh`, `amend`), 1 divergence, 2 non vérifiable, 64 usage ; codes de `arm` : 0 armé (ou déjà armé, armé à la main, rien à rafraîchir), 1 refusé, 2 non vérifiable, 3 pas de dépôt git, 64 ; `disarm` : 0, 1 (ligne tierce à retirer à la main), 2, 3, 64 ; `status` : 0 armé, 1 non armé, 2, 3, 64. Sortie du hook : étiquettes ASCII fixes préfixées `[vf-divergence]`, stderr de `check-divergence.sh` relayé tel quel (comme le hook de référence) | P61-D-04 ; QUAL-01 (trois issues) | 01, 03 |
| P61-PL-11 | Registres : une ligne `**Role** : [...]` ajoutée en FIN du bloc de champs du squelette d'entrée DEC, LRN et BLK, d'abord dans la source (`reference`), puis dans les copies (`consolidator`), une ligne ajoutée et aucune retirée par fichier ; valeur = sortie de `vf-role.sh get` ; codes 1, 5 et 64 → ligne omise (absence = inconnu, jamais `solo`). Aucun parseur modifié : l'optionnalité est prouvée par une suite neuve (`test-registres-role.sh`) qui compare la sortie de chaque parseur avec et sans le champ, plus `seed-registres.sh` (sixième consommateur, mesuré) | P61-D-07, RESEARCH §5 ; spec H-07 (« rien de plus ») | 02 |
| P61-PL-12 | Bumps : conductor minor (script neuf ET changements de l'engine, Q3 tranchée par le précédent Phase 58), consolidator minor et reference minor (nouveau champ des registres) ; chaque valeur lue au moment du bump, jamais figée ici ; compte de suites des README racine recompté en 61-07 seulement ; rouge intermédiaire nommé de `check-version-sync.sh` (compte de suites) de la vague 1 à 61-07 ; aucune release racine | P61-D-10 ; CLAUDE.md (nouvelle capacité → minor) ; précédent P60-PL-17 | 06, 07 |
| P61-PL-13 | Quatre suites NEUVES (`test-divergence-deux-clones.sh` et `test-vibeflow-update-divergence.sh` sous `plugin/_internal/tests/`, `test-vf-divergence-hook.sh` sous conductor, `test-registres-role.sh` sous consolidator) ; jamais un ajout à `test-vibeflow-update.sh` ; aucune suite existante modifiée — un rouge d'une suite existante est un arrêt (AC-2), pas une adaptation | RESEARCH §1 (convention), leçon « ne pas supprimer pour verdir » | 01 à 05, 08 |
| P61-PL-14 | `check-divergence.sh` n'est pas modifié (le commentaire périmé l. 61-62 reste, la phase ne touche pas le fichier) ; aucun amendement d'ADR : les limites vivent dans l'en-tête du script, le README de conductor, le manuel et la recette | `61-CONTEXT.md` (« à corriger si la phase touche le fichier ») ; P61-D-05 (« la limite est écrite dans la doc ») | 03, 06, 07, 08 |
| P61-PL-15 | Base de phase PB = parent du commit `docs(61): cadrage de la Phase 61` ; G-1, G-2 et SOBR-05 sont lues avec leur base réelle (`merge-base HEAD origin/main`) et l'écart est nommé au SUMMARY | Mesure ci-dessus ; précédents P60-PL-18 et P60-PL-27 | 08 |
| P61-PL-16 | Recette du lab réel : `61-RECETTE-LAB-REEL.md` dans le dossier de phase, rubriques fixes (Prérequis, Armement, Relevé hebdomadaire, Critère de passage, Gabarit de compte rendu, Clôture) ; le relevé rejoue `check-divergence.sh` sur chaque événement du reflog (pull, merge, rebase) et apparie chaque événement divergent à une ligne de journal par son HEAD ; la procédure est jouée telle quelle par le cas `D2C-RELEVE` de la suite à deux clones, avec son témoin | P61-D-09 ; « une preuve doit pouvoir rendre rouge » | 05 |
| P61-PL-17 | Manuel : quatre paires FR/EN (sujets en parallèle, installation, mise à jour et désinstallation, qu'est-ce qu'un lab) ; contenu neuf en `###` (C6 : ≤ 3 H2), aucune version en dur (C5), aucun chemin de machine | P61-D-10 ; `check-manual.sh` | 07 |
| P61-PL-18 | Isolation des suites : HOME jetable, `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL` vers un fichier vide du dossier de travail, `XDG_CONFIG_HOME` et `VF_DIVERGENCE_HOOK` retirés de l'environnement, identité git posée localement ; caches de test HORS des clones (un cache sous le clone serait refusé par P61-PL-03) ; fixtures générées à l'exécution, noms `w1`, `x`, `y`, aucun nom de client | P61-D-08 ; précédent P60-PL-20 | 01 à 05 |

## Couverture (audit multi-source)

| Source | Élément | Plans |
|--------|---------|-------|
| GOAL | divergence armée par défaut pour un lab multi-humains (hook `post-merge`, doublé de `post-rewrite`) | 01, 03, 04 |
| GOAL | champ `role:` des registres DECISIONS, LEARNINGS, BLOCKERS | 02 |
| GOAL | preuve à deux humains, deux clones, deux rôles, un workstream sur lab réel | 05 (procédure de recette, preuve de mécanisme), 08 (COLB-08 décochée) — preuve humaine différée (P61-B-01, P61-B-02, `61-CONTEXT.md` « Deferred Ideas ») |
| REQ | COLB-01 (01, 04, 08) · COLB-02 (01, 03, 08) · COLB-03 (01, 03, 04, 05, 08) · COLB-04 (01, 03, 05, 07, 08) · COLB-05 (04, 07, 08) · COLB-06 (02, 06, 07, 08) · COLB-07 (01, 05, 08) · COLB-08 (05 procédure, 08 décochée) · COLB-09 (tous ; 03 et 04 mutants, 06 bumps, 07 manuel, 08 porte) | tous |
| CONTEXT | P61-D-01 (01, 04) · D-02 (01, 03) · D-03 (01, 03, 04, 05) · D-04 (01, 03, 05) · D-05 (03, 05, 07) · D-06 (04, 07) · D-07 (02) · D-08 (01, 05) · D-09 (05) · D-10 (03, 06, 07, 08) · H-01 (01, 04) | tous |
| RESEARCH | §1 point d'armement et chemin absolu (01, 04) · §2 hooks déclenchés (03, 05) · §3 contrat de `check-divergence.sh` (01, 03) · §4 journal (01, 03) · §5 registres (02) · §6 CI et livraison (06, 07, 08) · Q1 (P61-PL-04) · Q2 (P61-PL-03) · Q3 (P61-PL-12) | tous |

Exclusions (non des trous) : idées différées de `61-CONTEXT.md` (preuve d'usage sur lab réel, confirmation de P61-H-01) ;
hors périmètre de phase (un workstream par rôle, tout contrôle d'accès, `scripts/hooks/` et sentinelles de ce dépôt).

## Bloqueurs

```yaml
blockers:
  planification: []   # aucune décision sans défaut documenté rencontrée ; Q1, Q2, Q3 tranchées par un défaut du cadrage ou une mesure
  humains:
    - id: P61-PB-01
      reprend: P61-B-01
      objet: "lab réel et ses deux humains (postes product et dev, un workstream) — décision de Samuel (spec Q-10)"
      effet: "COLB-08 reste décochée ; la procédure 61-RECETTE-LAB-REEL.md est livrée, jamais exécutée par la mission"
    - id: P61-PB-02
      reprend: P61-B-02
      objet: "trois semaines d'usage réel après armement"
      effet: "COLB-08 cochable seulement au dépôt du compte rendu de recette dans le dossier de phase (déclencheur proposé par le cadrage)"
  arrets_conditionnels_a_l_execution:
    - id: AC-1
      plans: [61-01, 61-03, 61-04, 61-06, 61-07, 61-08]
      condition: "une valeur existante de .planning/instruction-budget-baselines.tsv devrait augmenter, ou un SKILL.md / un agent devrait être touché"
      conduite: "arrêt et remontée au manager ; jamais une baseline relevée, jamais un arbitrage cité (P61-D-10)"
    - id: AC-2
      plans: [61-01, 61-04, 61-08]
      condition: "une suite existante (test-vibeflow-update-role.sh, test-roles-e2e.sh, test-vibeflow-update.sh, test-manifest.sh) rougit à cause de l'armement"
      conduite: "arrêt et remontée ; aucune assertion existante adaptée sans relecture (P61-PL-13)"
    - id: AC-3
      plans: [61-03, 61-05]
      condition: "le git de la CI (ubuntu) déclenche d'autres hooks que la matrice mesurée (P61-PL-05)"
      conduite: "re-mesure consignée au SUMMARY, arrêt avant de modifier la matrice écrite au manuel"
    - id: AC-4
      plans: [61-03, 61-04, 61-05]
      condition: "parité coreutils uutils / mawk non rejouable localement"
      conduite: "la CI de la PR en est le témoin, consigné au SUMMARY"
  gestes_humains_hors_plans:
    - "PR, relecture adverse SOBR-04, merge, minor racine, tag et release GitHub : gestes du manager (P61-D-10)"
    - "liste de clients hors dépôt pour le contrôle clients du critère 6 : sans elle, code 2 « en attente de la liste », dette nommée"
    - "recette du lab réel (P61-PB-01, P61-PB-02) puis coche de COLB-08 par Samuel"
  confirmations_attendues_de_samuel:
    - "P61-H-01 (armement au poste product ou dev, jamais solo)"
    - "P61-PL-03 (le refus d'armement relaie un code sans faire échouer l'installation)"
    - "P61-PL-08 (une mise à jour rafraîchit un hook déjà posé mais n'arme jamais un clone ; un lab posé avant cette version s'arme par role <poste>)"
  signaux_au_manager:
    - "la branche porte la Phase 60 non mergée (conductor v1.51.0 non publié) ; le minor de conductor de cette phase se calcule depuis la valeur lue"
    - "collision de version possible avec les Phases 45 et 48 du compartiment gouvernance (consolidator, installeur)"
    - "G-1, G-2 et SOBR-05 jugent merge-base(HEAD, origin/main)..HEAD = 1c2ae090..HEAD (100 commits à la planification), pas la seule plage PB..HEAD"
    - "manifeste check-agents-manifest.json valide jusqu'au 2026-11-21"
```

## Hypothèses portées par les plans

| ID | Hypothèse | Plans | Si fausse |
|----|-----------|-------|-----------|
| P61-H-01 | « lab multi-humains » = poste d'équipe déclaré | 01, 04 | réversible : la condition d'armement est une branche de `divergence_hook_apply` |
| A1 | awk et coreutils se comportent sous uutils et mawk comme sous BWK/BSD (aucun `-h` court, aucun `sed -i`, aucun `stat`) | 01 à 05 | rouge en CI seulement (AC-4) |
| A2 | la matrice de hooks mesurée sur git 2.50.1 vaut pour le git de la CI | 03, 05 | AC-3 |
| A3 | Claude Code garde plusieurs versions du cache et en purge plus tard (politique non mesurée) | 03, 04, 07 | sans `/vf-update`, le hook passe `NON-VERIFIABLE` audible et journalisé (limite écrite) |
| A4 | Git Bash exécute un hook `#!/bin/sh` et trouve `bash` (ADR-054) | 01, 03 | non mesurable sur ce poste ; limite écrite au manuel, recette Windows hors phase |
