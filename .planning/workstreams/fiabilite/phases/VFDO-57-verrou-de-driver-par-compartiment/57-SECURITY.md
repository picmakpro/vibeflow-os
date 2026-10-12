---
phase: 57-verrou-de-driver-par-compartiment
audit: security (vf-auditer)
head: cc17e5f1
base: dae0147b
date: 2026-10-11
verdict: SECURED
threats_total: 45
threats_closed: 45
threats_open: 0
findings_residual: 3
---

# 57-SECURITY — Phase 57, verrou de driver par compartiment

Registre : 45 lignes (T-57-01..44 + T-57-SC), 6 `accept`, 39 `mitigate`. 57-16 non exécuté : T-57-34/35/44 jugées sur
l'état actuel (à rejouer après 57-16). Méthode : lecture du diff `dae0147b..HEAD -- plugin scripts` ET exécution sur
dépôts jetables (aucune sonde sur le vrai `.git/vf-driver`, structure réelle vérifiée inchangée avant/après).

## Preuves rejouées (exécution, pas lecture)

- Suites : test-driver-lock-ws 492 ok/0 ko ; test-guard-driver-lock-ws 180 ok/0 ko, mutants 12/12 tués ;
  test-driver-lock-consumers-ws 30 ok/0 ko ; test-check-mission-exit-ws 54 ok/0 ko, mutants 5/5 tués.
- Mutants propres (copie du guard) : retrait de `sys.excepthook = fail_closed_hook` -> payload à cwd entier passe de
  deny à ALLOW (T-57-08 mord) ; retrait du casefold segment -> `workstreams/FIABILITE` passe de deny à ALLOW (T-57-10) ;
  retrait de `-c core.fsmonitor=` -> fichier témoin PWNED écrit (T-57-09 mord ; témoin positif : `git diff` non durci l'écrit aussi).
- Release (T-57-33, T-57-14/15) : `git diff dae0147b HEAD` vide sur VERSION, plugin/.claude-plugin/plugin.json,
  .claude-plugin/marketplace.json, plugin/.codex-plugin ; README/README.fr : 1 ligne chacun (compte de suites 98 -> 102).
  Baseline `instruction-budget-baselines.tsv`, sentinelles `*-armed`, `.github/`, `.planning/archives/` : diff vide.
- check-machine-paths OK (1911 fichiers), check-instruction-budget rc 0 (aucune hausse d'instructions), check-agents
  --strict dev-orchestrator OK, check-state-integrity OK, aucun fichier de dépendances touché (T-57-SC).

## Registre

| ID | Disp. | Verdict | Preuve (fichier:ligne ou test) |
|----|-------|---------|-------------------------------|
| T-57-01 | mit | CLOSED | driver-lock.sh:295-301 vf_ws_name_valid + vf_ws_dir_resolve avant tout chemin ; sondes `../x`, `..`, `.`, `a/b`, `-x`, `.hidden`, `$(id)`, `;id`, `"`, NL, vide -> ws-invalid ; WS-INV |
| T-57-02 | mit | CLOSED | l.270-275 (partition-unreadable), l.299 ; sondes : compartiment lien, workstreams lien/fichier -> refus nommés |
| T-57-03 | mit | CLOSED | test-driver-lock-ws.sh:111-119 préflight WS-TRACE-4 ; vrai vf-driver inchangé après 4 suites |
| T-57-04 | mit | CLOSED | l.48-50 ; sonde GSD_WORKSTREAM/VF_WORKSTREAM/active-workstream posés -> scope depot, ws-absent |
| T-57-05 | mit | CLOSED | l.744-759 ; sonde ancien verrou vivant -> legacy-lock-held, périmé -> stale-requires-takeover, aucune suppression ; release par hint OK |
| T-57-06 | mit | CLOSED | refus `ws-invalid` sans écho de la valeur ; status --all : noms invalides/liens ignorés (stderr), absents du JSON |
| T-57-07 | acc | CLOSED | documenté driver-lock.sh:50-51 (P57-D-25) ; sonde : refus bruyant, jamais repli plat |
| T-57-08 | mit | CLOSED | guard:1042 excepthook ; sondes cwd entier/liste, chemin NUL -> deny ; mutant mord |
| T-57-09 | mit | CLOSED | guard git_hardened (diff l.105-124) ; témoin positif + hostile config sans effet |
| T-57-10 | mit | CLOSED (périmètre plan) | casefold segment guard:593-595 ; rename --no-renames, non-ASCII, casse du segment : deny. Résiduel hors périmètre : F-1 |
| T-57-11 | mit | CLOSED | judge_bash/commit_paths ; sondes -a, --all, -qam, -m x -a, pathspec, amend, add&&commit, add ., add -A, -C, --git-dir, GIT_DIR=, env -i : deny ; index corrompu -> deny (source illisible) |
| T-57-12 | acc | CLOSED | documenté guard:86-88 + ADR-053 amendement 2026-10-10 |
| T-57-13 | acc | CLOSED | mesures ADR (72,6 ms lab partitionné sous verrou) |
| T-57-14 | mit | CLOSED | map_path -> incertain -> deny ; sonde lien sortant de .planning vers plugin/ -> deny. Lien hors dépôt : allow par C6 (voulu, hors lab) |
| T-57-15 | mit | CLOSED | cite_paths (3 chemins, json.dumps, 120 car.) ; noms non ASCII/espaces OK |
| T-57-16 | mit | CLOSED | check-guard-health status --all : sonde verrou périmé -> "abandon ... ws=fiabilite" ; check-branch-claim : même branche autre arbre -> signal |
| T-57-17 | mit | CLOSED | STATUS_JSON passé par l'environnement ; partition illisible -> INDETERMINE (jamais SAIN) |
| T-57-18 | mit | CLOSED | dag.sh record_progress : un argv, validé par driver-lock |
| T-57-19 | acc | CLOSED | bruyant voulu, vérifié (INDETERMINE) |
| T-57-20 | mit | CLOSED | check-mission-exit : sans --ws -> E1 indéterminé, verdict global INDÉTERMINÉ ; --budget-snapshot sans --ws exit 4 |
| T-57-21 | mit | CLOSED | vf_ws_resolve surcharge en premier canal ; --ws forgé validé |
| T-57-22 | mit | CLOSED | cur_lock_gen ("?" sur lecture impossible) |
| T-57-23 | mit | CLOSED | réel : ~/.claude/scripts/driver-lock.sh (sans --ws) -> E1 "code non nul (1)" = indéterminé |
| T-57-24..26 | mit | CLOSED | doctrine : limites P57-D-20 écrites (team-kernel, head-governance, mission-cross-team) ; budget instructions constant |
| T-57-27 | mit | CLOSED | SKILL.md vf-split-planning : acquire --depot / release, arrêt sur refus |
| T-57-28, 29 | mit | CLOSED | invariant réécrit ; ratchet d'instructions sans hausse |
| T-57-30 | mit | CLOSED | ADR amendement : canal + date, états de ratification lus au registre CONTEXT.md |
| T-57-31 | mit | CLOSED | check-machine-paths OK |
| T-57-32 | mit | CLOSED | limites P57-D-20/29 écrites, aucune sur-promesse |
| T-57-33 | mit | CLOSED | diff vide (voir Preuves) |
| T-57-34 | mit | CLOSED sur l'état actuel | check-state-integrity OK ; à rejouer après 57-16 |
| T-57-35 | mit | CLOSED sur l'état actuel | DLWS-01..08 toutes non cochées (rien de coché sans preuve) ; à rejouer après 57-16 |
| T-57-36 | mit | CLOSED | BACKLOG : dernier segment après « — » = OUVERTE |
| T-57-37, 39 | acc | CLOSED | documentés (driver-lock.sh:67-69 ; status --all somme les registres) |
| T-57-38 | mit | CLOSED | revalidation de chaque nom dans status --all (sonde : "we ird", lien exclus) |
| T-57-40, 41 | mit | CLOSED | suites + mutants 12/12 et 5/5 rejoués |
| T-57-42 | mit | CLOSED | meta sans branch -> INDETERMINE (code 4) |
| T-57-43 | mit | CLOSED | CLAUDE.md : verrou de dépôt en deux gestes courts, jamais pendant relecture/PR/merge |
| T-57-44 | mit | CLOSED sur l'état actuel | ROADMAP : seul le bloc Phase 57 modifié ; archives intactes ; à rejouer après 57-16 |
| T-57-SC | mit | CLOSED | aucun fichier de dépendances, aucune commande d'installation dans le diff |

## Findings résiduels (hors registre, non bloquants à block_on: high)

- **F-1 (medium, ask-user) — Write/Edit : contournement par la casse de `.planning` sur FS insensible à la casse
  (APFS par défaut).** Le préfiltre C4 (guard:1070, `(^|/)\.planning/`, sensible à la casse, hérité Phase 32) et
  `map_path` (realpath sans canonisation de casse) laissent passer `<lab>/.PLANNING/workstreams/<ws>/f` : ALLOW sous un
  verrou d'autrui, alors que `.planning/Workstreams/FIABILITE/f` est refusé (même inode vérifié). T-57-10 ne couvre
  que le segment. Remédiation : `re.I` sur C4 + comparaison des composants `.planning` par casefold ou samefile ; cas GW-W-CASE-prefixe + mutant.
- **F-2 (medium, ask-user) — `--ws` silencieusement sans effet quand le cwd est un sous-dossier du lab.** La détection
  du lab partitionné est relative au cwd (driver-lock.sh:258, guard:104/468). Depuis `plugin/sub/`, `acquire --ws=fiabilite`
  alors qu'un autre tient `fiabilite` rend `acquired:true`, écrit `plugin/sub/.planning/DRIVER.lock` (dossier parasite) et le
  guard (cwd sous-dossier) devient plat : commit sous verrou d'autrui ALLOW. Hérité du régime plat (P57-D-03) mais le
  nouvel indicateur `--ws` le rend muet. Remédiation : remonter au toplevel git pour détecter `.planning/workstreams`, ou
  refuser `--ws`/`--depot` hors racine de lab (`scope_reason` explicite).
- **Corrections F-1 et F-2 (2026-10-11, arbitrage Samuel, AskUserQuestion session principale, option a pour chacun).**
  F-1 corrigé par P57-D-38 : `e1101295` RED, `4df8ebf2` GREEN (préfiltre C4 en `re.I` et repli de casse du segment
  `.planning` dans `map_path`, lab partitionné seulement), mutants s et t `fdec20fd`. F-2 corrigé par P57-D-39 :
  `0d9bb680` (`driver-lock.sh` refuse `not-at-lab-root`), `5c37114c` (le guard détecte le lab depuis la racine git),
  mutants j, u, v, w `fdec20fd`. Registre et prose : `32dc6edb`. Lab plat inchangé au bit près (A/B IDENTIQUE).
- **F-3 (low, no-op/ask-user) — `skip_git_globals` ignore `--no-pager`, `--paginate`, `-p`, `--no-optional-locks`,
  `--literal-pathspecs` et `exec` n'est pas un wrapper** : `git --no-pager commit -am x` ALLOW sous verrou d'autrui. Lignes
  non touchées par la phase (BL-2, Phase 32), classe Catégorie A de l'en-tête (anti-accident). À consigner dans CONCERNS.md.
- Notes : un `vf-driver/ws` remplacé par un lien redirige les écritures de verrou hors dépôt (nécessite l'écriture dans `.git`,
  hors modèle de menace) ; CONCERNS.md ne porte encore aucune entrée Phase 57 (dette documentaire à la clôture).
