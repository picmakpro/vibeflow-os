# Codebase Concerns

**Analysis Date:** 2026-10-02

> Rafraîchissement du 2026-10-02 (HEAD `8fb37832`, branche `gouvernance/phase-45-execution`, VERSION
> racine `v2.67.1`, 17 modules, 98 suites découvertes par `.github/workflows/ci.yml:218`,
> `planning-core` `v2.9.0` non publié). Chaque entrée de l'analyse précédente a été revérifiée dans le
> code : ce qui a changé est regroupé dans « Résolu ou périmé » ; ce qui reste vrai est condensé ; la
> Phase 45 (hook central et gates d'écriture) ouvre une famille de limites déclarées, citées **par
> lettre et par thème** — la source de vérité est la section « Hook central et gates d'écriture
> (Phase 45) » de `plugin/planning-core/references/modele-cycles.md`, qui peut encore évoluer : y relire
> la lettre avant d'en tirer une conséquence.

## Résolu ou périmé (ne plus reporter)

| Ancienne entrée | État vérifié le 2026-10-02 |
|---|---|
| `update` ne converge pas (pas de manifeste des chemins posés) | **RÉSOLU** : `vf_manifest_path`/`vf_converge_apply` dans `plugin/_internal/vibeflow-update.sh` (manifeste `scripts/.vibeflow-manifest-<mod>`, convergence MANI-03), suite `plugin/_internal/tests/test-manifest.sh` |
| `merge-hooks.sh` : purge cross-matcher silencieuse | **PÉRIMÉ comme formulé** : la purge cross-matcher est désormais voulue et testée (T7, T21a/b/c dans `plugin/_internal/tests/test-merge-hooks.sh`). Un cas strictement « même run, deux entrées neuves, même script et même événement » n'a pas de test nommé : le contournement `Bash|Write|Edit` de `plugin/conductor/hooks/hooks.json` reste la forme à utiliser |
| Divergence `lexique.md` vs `VIBEFLOW_CORE.md` (P3-P8) | **RÉSOLU** : `plugin/reference/content/methodology/vocabulary/lexique.md:18-27` reprend les intitulés du Core v4.2 (P1-P9) |
| `docs/reference/` doublon divergent | **RÉSOLU** : le dossier n'existe plus |
| `validator/AGENT.md` à 249/250 lignes | **RÉSOLU** (Phase 40.1) : 250 lignes, avertissement dès 251, blocage au-delà de 300 |
| Gate ADR-044 faux vert en invocation nue | **RÉSOLU** : `bash plugin/conductor/scripts/check-agents.sh` rend « INDETERMINE … CIBLE-ABSENTE » (D-20), plus un vert à vide |
| Verrou de driver déclaratif | **RÉSOLU** (Phase 32) ; résiduel inchangé : guard anti-accident, pas anti-adversaire (session non armée, terminal humain, client git tiers, `bash -c`) — `plugin/conductor/scripts/guard-driver-lock.sh` |
| Fuite hors-lab par répertoire de compartiment en lien symbolique (T-24-14-C1) | **FERMÉE** (`workstream-policy.sh`, `test-workstream-symlink-escape.sh`) ; il reste le motif (voir Tech Debt) |
| T-24-02-01 mitigation falsifiée | **TRANCHÉE** (réécriture, 2026-08-05) |
| `24-03-SUMMARY.md` contredit `config.json` | **RÉSOLU** : le SUMMARY (archivé sous `.planning/milestones/agentique-v1.0-phases/`) nomme maintenant `windows_enforce` et `workflow_guard` comme posés |
| Bug amont #2893 (`WINDOWS.md` réécrit en entier) | **RÉSOLU en amont** : le correctif de préservation de prose est présent dans `~/.claude/gsd-core/bin/lib/broken-windows.cjs` (gsd-core 1.15.0 installé au compte). Ne plus écrire « générée tant que ≤ 1.9.1 » ; garder le réflexe de committer `.planning/WINDOWS.md` avant toute commande `windows` |
| `check-version-sync.sh` / `check-release-tag.sh` sans suite | **PARTIEL** : `scripts/tests/` existe (11 suites dont `test-check-release-tag.sh`, `test-check-baseline-arbitrage.sh`, `test-check-gate-touche.sh`) ; `scripts/check-version-sync.sh` et `scripts/bump.sh` n'ont toujours **aucune** suite dédiée |
| Phase 13 « en suspens » | **RÉSOLU** : livrée le 2026-07-26 (`.planning/MILESTONES.md:67`) |
| Milestone `gsd-migration` « EN ATTENTE » | **RÉSOLU** : clos le 2026-07-26 (`.planning/MILESTONES.md:71`) |
| Backlog « Skill-installer global » à déclencheur consommé | **RÉSOLU** : clos NO-GO le 2026-09-15 (`.planning/BACKLOG.md:385`) |
| Compteur « 37 suites » | **PÉRIMÉ** : 98 suites ; `scripts/check-version-sync.sh` gate ce compteur (README.md et README.fr.md, point « suites ») |
| CI qui ne vérifie que le compartiment `fiabilite` | **PÉRIMÉ sur cette branche** : `.github/workflows/ci.yml:351-545` énumère les compartiments présents sur disque (`vf_ws_enumerate`) et traite `gouvernance` non initialisé sans le compter en écart |

## Tech Debt

**Aucune primitive partagée de confinement de chemin — le motif se répète à chaque site** — Sévérité : **HIGH**
- Issue: le défaut « chemin dérivé d'une entrée non maîtrisée qui sort de son arbre » a été fermé site
  par site : liens symboliques (Phase 23, `check-workstream-pointer.sh`, `build-gsd-capabilities-index.sh`,
  répertoire de compartiment), résolution CWD non ancrée de `plugin/conductor/scripts/dag.sh` (ADR-070,
  fermé), traversée par `name:` de frontmatter dans `plugin/_internal/runtime-adapter/register-codex-agent.sh`
  (fermé, 16 cas verts dans `.../tests/test-register-codex-agent-path-traversal.sh`). Six implémentations
  coexistent en trois langages : `[ -L ]` (`plugin/planning-core/scripts/workstream-policy.sh`), `vf_realpath`
  node, `os.path.realpath` python (`plugin/conductor/scripts/guard-agent-write.sh`), `pwd -P`
  (`plugin/conductor/scripts/check-branch-claim.sh`), `os.path.normpath`
  (`plugin/consolidator/scripts/guard-read-registres.sh`), `O_NOFOLLOW` (`plugin/planning-core/scripts/planning-hook.sh`).
  Les fonctions `vf_path_refuse_link` / `vf_path_confine` recommandées **n'existent toujours pas** (grep vide
  dans `plugin/`, `scripts/`, `docs/`).
- Impact: le prochain script qui lit un chemin dérivé d'une entrée le réinventera ou l'oubliera ; le contrôle
  anti-duplication de `plugin/planning-core/scripts/tests/test-workstream-policy.sh` (C1/C2/C3) itère sur un roster
  figé, aveugle aux nouveaux entrants.
- Fix approach: deux fonctions partagées dans `plugin/planning-core/scripts/`, C1/C2 généralisés à
  l'énumération de `plugin/*/scripts/*.sh` avec liste d'exemptions nommée, mutant obligatoire (modèle C3).
  Surface voisine non couverte : le segment racine `.planning` en lien symbolique (théorique ici, `.planning`
  est un vrai répertoire) — à fermer avec la primitive, pas avant.

**Résolution des `requires[]` opt-in seulement** — Sévérité : **MEDIUM**
- Issue: la fermeture transitive n'existe que via `install --with-deps <module>`
  (`plugin/_internal/vibeflow-update.sh:3193`). `install <module>` nu ne signale pas les `requires[]`
  manquants (0 occurrence de `requires` dans l'engine), et `uninstall_module` (`:2858`) ne contrôle pas les
  dépendances inverses.
- Fix approach: avertissement sur `install` nu ; refus (ou `--force`) sur `uninstall` d'un module requis.

**`.planning/WINDOWS.md` : `open_count: 3` — `/gsd-ship` est bloqué** — Sévérité : **MEDIUM**
- Issue: le ledger (`.planning/WINDOWS.md`, `windows_enforce: true`) porte trois fenêtres ouvertes : #6
  (`T4 [majuscules]` de `test-register-codex-agent-path-traversal.sh`, **déjà corrigé dans le code**, 0 ko
  mesuré le 2026-10-02 : la ligne est à passer en `fixed`), #7 (`test-check-description-fidelity.sh` : PyYAML
  absent de `python3` sur ce poste, problème d'environnement), #9 (écart CO-VERDICT de la Phase 41, accepté
  et documenté, jamais soldé). La #3 (recette XcodeBuildMCP) reste `waived` : jamais jouée, à rejouer sur un
  lab iOS équipé.
- Fix approach: solder #6 par `gsd-tools windows fixed 6` (committer le fichier avant), trancher #7 (installer
  PyYAML ou déroger nommément) et #9 (waive motivé) — sinon le ship du jalon est bloqué.

**Protection côté serveur : documents et mesure versionnée en retard sur la pose** — Sévérité : **LOW**
- Issue: la section « Protection côté serveur … PAS ENCORE POSÉE » de `CLAUDE.md` et
  `.planning/server-rulesets-measurement.json` (`ruleset_count: 0`, mesuré le 2026-09-23T14:26Z) décrivent
  l'état d'avant la pose ; `.github/rulesets/main.json`, `.github/rulesets/tags-v.json` et `.github/CODEOWNERS`
  sont la source versionnée.
- Fix approach: re-mesurer par `scripts/measure-server-rulesets.sh` avant toute affirmation sur l'état réel,
  puis réaligner `CLAUDE.md` (Doc, sans release : ADR-073).

**`hooks.workflow_guard` se déclenche hors du dépôt** — Sévérité : **LOW**
- Issue: l'avis « édition non tracée dans STATE.md » du hook amont `gsd-workflow-guard.sh` s'émet aussi pour
  des écritures hors du dépôt (scratchpad de session, dossier de projets du compte). Advisory, jamais bloquant.
- Fix approach: remonter en amont (ADR-069, Iron Law 2 révisée) ; ne pas désactiver `hooks.workflow_guard`
  dans `.planning/config.json`.

## Known Bugs

Aucun bug ouvert confirmé sur disque au 2026-10-02. Les comportements gênants connus sont des limites de
conception : voir « Limites déclarées de la Phase 45 » et Tech Debt.

## Security Considerations

**Candidat RCE par `git worktree` hostile — RÉDUIT, PAS FERMÉ (`pre-push` et `post-merge`)** — Sévérité : **MEDIUM**
- Risk: sous `core.hooksPath scripts/hooks` en chemin **relatif** (convention documentée), git charge le hook
  lui-même depuis le worktree courant : un worktree hostile fournit son propre `pre-push`/`post-merge` et le
  gate est contourné, quel que soit le contenu du hook légitime.
- Files: `scripts/hooks/pre-push`, `scripts/hooks/post-merge` (le script **appelé** est résolu par
  `git rev-parse --git-common-dir`, ligne 21 et ligne 29 : fermé ; le hook lui-même : ouvert).
- Current mitigation: ancrage `--git-common-dir` du script appelé, prouvé par exécution réelle.
- Recommendations: **ne pas basculer `core.hooksPath` en absolu** — mesuré : l'absolu ferme le vecteur worktree
  mais le geste d'armement est piégé (épingle le dépôt entier sur un worktree hostile), il meurt en silence au
  déplacement du dépôt, et ne couvre pas un dépôt principal basculé sur la branche hostile. Le relatif échoue
  bruyamment ; entre les deux, préférer l'échec qui se voit. Tout futur hook qui résout un script tiers :
  `--git-common-dir`, jamais `--show-toplevel` ni `dirname "$0"`.

**Codex importe de lui-même une 5ᵉ racine de skills** — Sévérité : **MEDIUM**
- Risk: `plugins/cache/openai-curated-remote` est téléchargé par le binaire `codex`, hors contrôle VibeFlow.
- Files: constante `REMOTE_SKILLS_CACHE` de `plugin/conductor/scripts/check-artifact-fidelity.sh:97`
  (ligne `[fidelity-recette]`).
- Current mitigation: déclaration seule, pas d'enforcement. Recommendations : allowlist/revue de contenu si un
  jour nécessaire.

**Nom de module non assaini dans l'engine** — Sévérité : **LOW**
- Risk: `install_module` (`plugin/_internal/vibeflow-update.sh:2216`) ne valide que `[ -d "$CACHE_DIR/$mod" ]`
  (`:2221`) ; un nom en `../` résoudrait hors cache. Appelant prod : `/vibeflow-install`, noms issus du catalogue.
- Recommendations: rejeter `/`, `..` et espace au parsing des positionnels.

**Pas de filtrage de secrets dans la copie d'install** — Sévérité : **LOW**
- Risk: copies `cp` de `install_module` sans filtre `*.env*`/`*secret*` ; source = cache du plugin publié.

**`vf-internal` perdu sur kimi, `kimi doctor` vert à vide** — voir Fragile Areas.

## Limites déclarées de la Phase 45 (hook central et gates d'écriture)

Source : `plugin/planning-core/references/modele-cycles.md`, section « Hook central et gates d'écriture
(Phase 45) » (lettres (a) à (ae), tenues alignées avec le code par R-REFERENCE dans
`plugin/planning-core/scripts/tests/test-planning-gates.sh`). Code : `plugin/planning-core/scripts/planning-hook.sh`
(lanceur bash, cœur Python), commande enregistrée dans `plugin/planning-core/hooks/hooks.json`.
**Gates : G1, G5, G6, G7 et ROLE sont `armed` (constantes `ARMEMENT_*` de `planning-hook.sh:102-106`) ; G2 est
`avertit` (`G2_MODE`), il ne refuse jamais.** Le hook n'agit que dans un lab dont `.planning/config.json`
déclare `planning_version: cycles-v1` : ce dépôt (lab dev) n'est jamais refusé.

Les lettres ci-dessous sont des renvois, pas des citations : relire la lettre dans la référence avant d'agir.

| Lettre | Thème | Nature du risque |
|---|---|---|
| (y) | Réglages `.claude/settings*.json` non protégés ; scripts du hook protégés par G6 en scope projet seulement ; deux silences par lien préexistant et par dossier de session ≠ parent de `.planning` | **Désarmement par outil** : un `Write` qui retire le hook des réglages éteint tous les gates. Scope compte (`~/.claude/scripts/`) non gardé |
| (o) | Définition d'une racine de lab : `.planning` sous un composant `.planning` ou `.claude` n'est pas une racine ; seule exception `.claude/worktrees/<nom>` ; divergence Unicode entre cœur Python (`casefold`, `planning-hook.sh:288-302`) et motif de la commande shell (`[Ww][Oo]…` dans `hooks.json`) | **Divergence cœur/shell** : en panne du cœur seulement, faux refus ou faux silence dans des poches au nom replié |
| (z) | Faux refus fail-closed sous forte charge machine (échéance interne du cœur) | **Disponibilité** : écriture légitime refusée, à rejouer ; jamais un faux accept |
| (s) | Échéance interne de 8 s du cœur (`ECHEANCE_COEUR_S = 8.0`, `CODE_ECHEANCE = 73`, `planning-hook.sh:94-96`) | Déni de service sur machine lente ; ferme sous adhésion |
| (aa) | Couche shell : borne de 4096 caractères par valeur du payload ; cœur qui ne sort plus en code non nul sur chemin inanalysable | Silence résiduel conditionné à une panne du cœur ET à un lien préexistant |
| (ab) | Chemin commençant par `~` : développement identique dans les deux couches, `~utilisateur` tranché dans le doute | Écart non mesuré de première main pour `Write` |
| (ac) | Racine d'un dispatch `Agent`/`Task` dérivée de clés de chemin facultatives du payload | Précondition (le harnais transmet des clés inconnues) non établie |
| (ad) | Poche `.claude/worktrees/<nom>` non adhérente créable par `Write` seul | Script d'un futur worktree lancé dedans non gardé |
| (ae) | Seuls les outils du matcher sont vus : `MultiEdit`, outils d'écriture de serveurs MCP et tout outil hors matcher échappent | **Trou de couverture structurel** |
| (g), (n) | `Bash` reste ouvert (P45-D-06b, P45-D-10) : désarmement de l'adhésion ou écriture d'un fichier gardé par `sed`/redirection | Contournement assumé, jamais promesse |
| (a), (b), (c), (k), (m) | Écarts de lecture shell/Python de `config.json` (JSON non compact, ligne multiple, lien symbolique, virgule finale, échappements) | Silence en panne du cœur seulement ; (m) partiellement fermée par `MOTIF_ADHESION_REPLI` |
| (d), (u), (e), (f), (h) | Échappements JSON non gérés, charge non JSON, `bash` absent, chemins relatifs joints au `cwd` | Fail-closed dans le doute ; (u) refuse parfois hors lab adhérent |
| (i) | Scope projet : `$CLAUDE_PROJECT_DIR` choisit la copie du script exécutée | Copie périmée d'un autre worktree ; seul le canary la rend visible |
| (j) | G1 laisse passer un `PLAN.md` quand `CADRAGE.md` est non régulier, invalide ou hérité | Contournement connu, T-45-55, renversable |
| (l) | Allowlist d'un worker dans une définition d'agent que G6 ne protège pas | Un agent étend ce qu'il peut dispatcher |
| (p), (q), (t), (v), (w) | Poche `.planning/` sans `config.json` ; dispatch sans `subagent_type` ; version de plugin déduite du nom de dossier ; `STATE.md` marqué généré puis édité ; `name:` YAML masqué | Bords d'index et de classification |
| (r), (x) | Journal d'observation sans borne ni rotation ; rejeu non optimisé (25 000 fichiers > 300 s), lien `.planning` non suivi → MESURE-VIDE | Croissance disque ; volume |

Autres résidus déclarés, hors lettre : G7 « habité » borné à 20 000 fichiers (`BORNE_PARCOURS_HABITE`) et faux
agent + mémoire qui passe G7 (T-45-61) ; recherche de lien dur de G5 bornée à 20 000 fichiers
(`BORNE_PARCOURS_VERDICTS`) ; `--juge` de `poser-verdict.sh` et `--qui` de `deroger-gate.sh` purement
déclaratifs (T-45-34) ; recalcul : TOCTOU garde/détecteur, `vf_ws_enumerate` ≈ 98 s à 3000 compartiments contre
`timeout=30` de `plugin/planning-core/scripts/recalc-planning.sh:446,666` (refus fail-closed), `CANDIDATS_BASH`
(`/bin/bash`, `/usr/bin/bash`, `recalc-planning.sh:88`) qui interdit toute écriture sur un système sans bash à
ces chemins.

## Performance Bottlenecks

Rien de bloquant à l'échelle actuelle. Deux points à surveiller : le cœur du hook (`planning-hook.sh`, 2012
lignes) sous charge — voir limites (s), (z) — et `vf_ws_enumerate` à très grand nombre de compartiments. Les
O(n²) de `plugin/consolidator/scripts/detect-duplicates.sh` restent sans impact observé (LOW).

## Fragile Areas

**Borne d'horloge de 3 s de R-N1-01 : test sensible à la charge** — Sévérité : **MEDIUM**
- Files: `plugin/planning-core/scripts/tests/test-planning-gates.sh:4538-4556` (`duree >= 3.0` sur dix frères de
  1 Mo) ; mêmes familles d'assertions murales à `:2828` (R-G2-PERF, `dt < 3.0`), `:4060` (`duree >= 2.0`),
  `:4102` (`duree >= 4.0`).
- Why fragile: une suite de 4929 lignes asserte des durées murales de 2 à 4 s alors que le cœur lui-même
  accepte jusqu'à 8 s (limite (z) observée « en suites à charge 20 à 35, jamais en rejeu réel ») : un rouge sous
  charge n'est pas une régression du hook.
- Safe modification: relancer sur machine au repos avant de conclure à une régression ; si ces bornes sont
  touchées, les mesurer par rapport à `ECHEANCE_COEUR_S` plutôt que par seuil absolu, sans jamais retirer
  l'assertion (le mutant `INDEXATION-CANDIDATS` doit continuer à la faire rougir).

**Sensibilité des suites à la charge machine** — Sévérité : **MEDIUM**
- Files: `plugin/planning-core/scripts/tests/test-planning-gates.sh` (timeouts `subprocess` de 10 à 240 s ,
  mutants qui réécrivent des copies du hook), `plugin/_internal/tests/test-planning-hook-installed.sh`,
  `scripts/tests/test-role-hook-vs-check-agents.sh`.
- Why fragile: le cœur Python se borne à 8 s et ferme en refus au-delà ; une suite lancée en parallèle d'autres
  (CI partagée, plusieurs sessions) peut obtenir des faux refus attribuables à la charge. Ne pas lancer deux
  suites lourdes ensemble ; ne jamais « réparer » en élargissant `ECHEANCE_COEUR_S` sans arbitrage (limite (s)).

**Bash non couvert par le hook (P45-D-10)** — Sévérité : **HIGH (par construction, assumé)**
- Files: `plugin/planning-core/scripts/planning-hook.sh` (G2 sur Bash = détection seulement),
  `plugin/planning-core/hooks/hooks.json` (matcher `Write|Edit|NotebookEdit|Bash|Agent|Task`).
- Why fragile: G1, G5, G6, G7 et ROLE refusent des **outils**, jamais le disque : une redirection ou un `sed` écrit
  `STATE.md`, un `VERDICT.md`, retire l'adhésion ou le hook des réglages (limites (g), (n), (y)). En panne du cœur,
  `Bash` reste aussi ouvert pour permettre la réparation. Ne jamais présenter un gate comme une garantie
  d'intégrité du disque ; les seuls chemins légitimes sont `recalc-planning.sh`, `poser-verdict.sh`, `deroger-gate.sh`.

**G6 sur les scripts du hook : prouvé seulement en suites** — Sévérité : **MEDIUM**
- Files: `SCRIPTS_HOOK_G6` (`plugin/planning-core/scripts/planning-hook.sh:1062`), preuve dans
  `plugin/_internal/tests/test-planning-hook-installed.sh` et `test-planning-gates.sh`.
- Why fragile: la protection de `<lab>/.claude/scripts/planning-hook.sh` et de `check-gates-alive.sh` n'a jamais
  été rejouée sur un lab réel armé (les rejeux `45-REJEU-*` mesurent faux refus et faux accept sur copie des deux
  labs réels, non migrés : ces scripts n'y existent pas, le corpus G6 n'a donc aucune cible pour eux) ; le dépôt lui-même n'adhère pas. Limite (y) : seul le scope projet est
  couvert. Le canary de session (`plugin/planning-core/scripts/check-gates-alive.sh`) signale, n'empêche rien.
- Test coverage: suites seulement ; prévoir un rejeu sur un lab adhérent réel au prochain palier.

**Phase 45 close, vérifiée 15/15, non mergée** — Sévérité : **LOW** (résolu le 2026-10-02)
- Files: `.planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-VERIFICATION.md`,
  `.planning/workstreams/gouvernance/STATE.md`.
- État : GATE-15 prouvé par la CI Linux de la PR #124 et validé par Willy (message en session
  principale, 2026-10-01) ; audit de sécurité final SECURED (4 tours). Les rejeux réels
  (`45-REJEU-*`) ont été faits sur copie des labs au repos. Reste : aucun merge, tag ni release avant
  clôture de `fiabilite-v1.0` (garde-fou du jalon).

**`kimi doctor` est un vert à vide sur les agents** — Sévérité : **HIGH**
- Files: recette d'install kimi ; mesure `38-MESURE-KIMI.md` (Phase 38).
- Why fragile: `kimi doctor` valide les fichiers de configuration, jamais les agents (11 cassés sur 31 passaient) ;
  le log est tronqué à 233 octets et plafonné à 5 lignes. Toute recette kimi vérifie par `kimi --agent-file
  <chemin>` fichier par fichier, jamais par `doctor` ni par le log. Le gate double-parseur ne couvre que la forme.

**`vf-internal` perdu en silence sur kimi** — Sévérité : **MEDIUM**
- Files: 19 agents `vf-internal: true` ; `plugin/conductor/scripts/check-artifact-fidelity.sh`
  (`KIMI_VF_INTERNAL_NOTE`, ligne `[fidelity-vf-internal]`).
- Why fragile: le cloisonnement du Pattern 12 est une garantie de frontmatter, pas de runtime ; la perte est
  désormais **déclarée** par le gate à l'install et au `status`. Le texte ne doit jamais promettre un confinement.

**Modules `mobile-test` / `mobile-test-team` expérimentaux** — Sévérité : **HIGH**
- Files: `plugin/mobile-test/module.json:5`, `plugin/mobile-test-team/module.json:5` (« expérimental jusqu'au
  premier run réel vert »), `plugin/mobile-test/scripts/mobile-test-run.mjs` (409 lignes Node, aucun `tests/`).
- Why fragile: aucun run réel tracé dans `reports/` (sous-dossiers `audit`, `research`, `uat`, `validator`) ;
  pipeline et orchestration Pattern 12 jamais prouvés. Ne pas étendre avant un run réel vert commis.

**Chiffres en prose non gatés** — Sévérité : **MEDIUM**
- Files: tableau des modules de `README.md` et `README.fr.md` (colonne version) hors périmètre de
  `scripts/check-version-sync.sh` (qui gate badges, phrase « N modules », triade VERSION, en-têtes de modules,
  historique, compteur de suites 98). Tout compteur en prose hors gate finit par mentir ; le gater ou renvoyer
  à la source machine. Les greps littéraux de `check-version-sync.sh` cassent à toute refonte éditoriale :
  relancer `bash scripts/check-version-sync.sh` après.

**Sonde cross-module `conductor` → `dev-orchestrator`** — Sévérité : **MEDIUM**
- Files: `plugin/conductor/skills/vf-update/SKILL.md` (sonde de `check-gsd-engine.sh`), `docs/ADR.md` §ADR-058.
- Why fragile: sonde de présence de fichier, silence voulu sur script absent ; un changement du layout posé par
  `copy_module_scripts()` éteindrait la détection du moteur sans signal. Ne jamais la convertir en `requires`.

## Scaling Limits

**Découverte de suites CI limitée à `*/tests/test-*.sh`** — Sévérité : **MEDIUM**
- Current capacity: 98 suites (`.github/workflows/ci.yml:218`, `find plugin scripts -type f -path '*/tests/test-*.sh'`).
- Limit: tout test non-bash est invisible (`plugin/mobile-test/scripts/mobile-test-run.mjs`).
- Scaling path: wrapper bash dry-run ou découverte élargie.

## Dependencies at Risk

**`python3`, `jq` et PyYAML supposés présents** — Sévérité : **LOW**
- Risk: scripts consolidator, `check-agents.sh` et le cœur de `planning-hook.sh` consomment `python3` ; PyYAML
  manque sur le `python3` de ce poste (fenêtre #7 de `.planning/WINDOWS.md`). Hors lab adhérent, un `python3`
  absent ne refuse jamais (P45-D-06a) ; dans un lab adhérent, la commande enregistrée refuse `Write`, `Edit`,
  `NotebookEdit`, `Agent`, `Task`.
- Migration plan: câbler `plugin/installer/scripts/preflight.sh` systématiquement.

**Moteur `@opengsd/gsd-core` : version locale périmée, CI en `^1`** — Sévérité : **LOW**
- Risk: l'install locale au dépôt (`.claude/gsd-core`, gitignorée) et celle du compte (`~/.claude/gsd-core`,
  1.15.0) peuvent différer ; `ci.yml` installe `@opengsd/gsd-core@^1` sous Node 24 (sous Node 22 l'install
  rétrograderait en silence en 1.10.0). Appeler `gsd-tools.cjs` du compte explicitement.

## Missing Critical Features

**Phases 46-50 du jalon `gouvernance-labs-v1.0` non commencées** — Sévérité : **MEDIUM**
- Problem: gates de clôture et vérification du hash de `VERDICT.md` (46), baux (47), injection de l'index et
  pont mémoire (48), grille d'initialisation (49-50) ; G2′, G3, G4, G4′, D1 absents ; le hook managed (seul à
  résister à `disableAllHooks`) est hors périmètre. Un gate peut donc être désarmé par `disableAllHooks`.
- Files: `.planning/workstreams/gouvernance/ROADMAP.md`.

## Test Coverage Gaps

**`scripts/check-version-sync.sh` et `scripts/bump.sh` sans suite** — Priority: **HIGH**
- What's not tested: les 9 points de parsing grep/sed du gate de version et le bump ; un grep qui ne matche plus
  est un faux vert silencieux.
- Files: `scripts/check-version-sync.sh`, `scripts/bump.sh`
- Fix: `scripts/tests/test-check-version-sync.sh` sur fixtures désalignées (le gate doit ko).

**`mobile-test-run.mjs` : 409 lignes Node, zéro test** — Priority: **HIGH**
- Files: `plugin/mobile-test/scripts/mobile-test-run.mjs` ; hors motif de découverte CI.

**`plugin/installer/scripts/preflight.sh` non couvert** — Priority: **MEDIUM**
- Files: `plugin/installer/scripts/preflight.sh` ; la suite du module (`test-build-module-catalog.sh`) ne le référence pas.

**`mobile-test-team` : boucle test → corrige → re-test jamais éprouvée** — Priority: **MEDIUM**
- Files: `plugin/mobile-test-team/agents/`.

**Gestes documentés de la Phase 24 sans garde machine (non re-mesuré en entier)** — Priority: **MEDIUM**
- Files: `plugin/conductor/hooks/hooks.json` (`|| true` des commandes `SessionStart`),
  `plugin/dev-orchestrator/references/workstreams.md`, `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`
  (T35 : renvoi et plafond 300 des agents vérifiés, contenu du geste PR non vérifié),
  `plugin/software-architecture/SKILL.md`, `plugin/audit-architecture/SKILL.md` (volume injecté dans
  `gsd-planner` non borné par un gate).

**Limites de la Phase 45 sans preuve sur lab réel** — Priority: **MEDIUM**
- What's not tested: protection des scripts du hook (limite (y)), poches `.claude/worktrees` (limites (o), (ad)),
  faux refus sous charge (limite (z)) : mesurés en suites ou sur copie, jamais en rejeu réel armé.
- Files: `plugin/planning-core/scripts/rejeu-reel.sh`, `plugin/planning-core/scripts/rejeu-gates.sh`.

---

*Concerns audit: 2026-10-02 — v2.67.1, 17 modules, 98 suites CI, planning-core v2.9.0 (Phase 45 armée)*
