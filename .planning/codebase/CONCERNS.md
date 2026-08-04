# Codebase Concerns

**Analysis Date:** 2026-07-26

> Réécriture complète — la version du 2026-06-04 est périmée. Sa dette majeure a été traitée par
> l'enforcement CI v2.32.0+ : **37 suites de tests** découvertes dynamiquement par
> `.github/workflows/ci.yml:32`, `check-agents.sh --strict` sur chaque `plugin/*/agents`
> (`ci.yml:66-76`), gate `scripts/check-version-sync.sh` (9 points de contrôle, ADR-054).
> `infrastructure-audit` a désormais sa suite (`plugin/infrastructure-audit/scripts/tests/test-audit-infra.sh`),
> le résolveur de dépendances existe et est testé (`plugin/_internal/resolve-deps.sh` +
> `plugin/_internal/tests/test-resolve-deps.sh`). Ne pas reporter l'ancienne liste.

## Tech Debt

**`update` ne converge pas le contenu — pas de manifeste des chemins posés** — Sévérité : **HIGH**
- Issue: `vibeflow-update.sh update` re-matérialise le contenu du module mais **ne supprime jamais**
  les fichiers que la nouvelle version ne livre plus. Vécu terrain (update machine 2.23.0 → 2.36.0) :
  les 12 verbes-façades de dev-orchestrator v1.x ont survécu dans `~/.claude/skills/` et ressuscité
  le double catalogue tué par la bascule agentique v2.33.0 — nettoyage manuel.
- Files: `plugin/_internal/vibeflow-update.sh` (fonction `install_module`, aucune écriture de
  manifeste) ; capturé dans `.planning/BACKLOG.md:3-12`
- Impact: chaque lab mis à jour peut garder des skills/scripts fantômes qui contredisent la version
  courante (régression de doctrine silencieuse).
- Fix approach: manifeste des chemins posés par module à l'install
  (`.claude/scripts/.vibeflow-manifest-<module>`) ; `update` supprime les chemins de l'ancien
  manifeste absents du nouveau (avec backup). Test : update d'un module dont une skill a disparu.

**Divergence de doctrine distribuée — lexique vs VIBEFLOW_CORE** — Sévérité : **HIGH**
- Issue: les intitulés des principes P3–P8 divergent entre les deux documents canoniques livrés aux
  labs. `lexique.md` : P3 Specialiser, P4 Orchestrer, P5 Verifier, P6 Iterer, P7 Transposer,
  P8 Evaluer. `VIBEFLOW_CORE.md` v4.2 : P3 Orchestrer et executer, P4 Clarifier avant d'executer,
  P5 Verifier en boucle, P6 Iterer par cycles courts, P7 Transposer pas copier, P8 Evaluer la
  qualite cognitive. Toute référence « P4 » pointe donc sur deux principes différents selon la source.
- Files: `plugin/reference/content/methodology/vocabulary/lexique.md:18-26` vs
  `plugin/reference/content/methodology/VIBEFLOW_CORE.md:90-144`
- Impact: agents et blueprints citent P-numéros (ex. `business-pilot-bundle` trace « EVAL-XXX (P8) ») —
  le sens dépend du document lu. Signalée le 2026-07-26, **non arbitrée**.
- Fix approach: arbitrer la numérotation canonique (CORE v4.2 probable), aligner `lexique.md`,
  puis greper tous les `P[1-9]` du repo pour vérifier la cohérence.

**`docs/reference/` doublon divergent de `plugin/reference/content/`** — Sévérité : **MEDIUM**
- Issue: 4 fichiers diffèrent entre les deux arborescences : `README-CLIENT.md`, `VERSION.md`,
  `methodology/patterns/README.md`, `methodology/vocabulary/lexique.md` (vérifié `diff -rq` le
  2026-07-26).
- Files: `docs/reference/` vs `plugin/reference/content/` ; flagué « poids mort » dans
  `reports/audit/2026-07-25-audit-complet.md:73` et `:143` (item 7) — toujours non traité.
- Impact: deux vérités pour la même doc méthodologique ; le module `reference` installe
  `plugin/reference/content/`, `docs/` est la copie qui dérive.
- Fix approach: supprimer `docs/reference/` ou le réduire à un pointeur vers le module ; sinon gate
  d'identité dans la CI.

**`validator/AGENT.md` à 249/250 lignes (plafond ADR-029)** — Sévérité : **MEDIUM**
- Issue: l'agent est à 1 ligne du plafond densité. Tout ajout (nouveau contrôle Phase 4, nouvelle
  escalade) exige d'abord un délestage vers `references/` ou une skill.
- Files: `plugin/validator/AGENT.md` (249 lignes, `wc -l` du 2026-07-26)
- Impact: chaque évolution du validator devient une opération de refactoring, pas un simple ajout.
- Fix approach: délester préventivement les sections les plus verbeuses vers
  `plugin/validator/references/` avant la prochaine évolution. Même famille :
  `plugin/skill-creator/skills/skill-creator/SKILL.md` à 485/500 lignes.

**Résolution des `requires[]` opt-in seulement** — Sévérité : **MEDIUM**
- Issue: la fermeture transitive existe (`plugin/_internal/resolve-deps.sh`, câblée et testée) mais
  uniquement via `install --with-deps <module>` (`vibeflow-update.sh:759-768`). Un
  `install <module>` nu n'installe **ni ne signale** les `requires[]` manquants (0 occurrence de
  `requires` dans l'engine). `uninstall` ne vérifie pas non plus les dépendances inverses : on peut
  désinstaller `consolidator` alors que `validator` installé le requiert.
- Files: `plugin/_internal/vibeflow-update.sh:755-771` (dispatch install), `:611` (`uninstall_module`) ;
  `requires[]` déclarés dans `plugin/*/module.json` (ex. `plugin/validator/module.json`)
- Impact: install partiel silencieux → module qui échoue au runtime ; désinstallation qui casse un
  module resté en place.
- Fix approach: au minimum un warning listant les `requires[]` non installés sur `install` nu ;
  refus (ou `--force`) sur `uninstall` d'un module requis par un module installé.

**Backlog avec déclencheur consommé, non ré-arbitré** — Sévérité : **LOW**
- Issue: l'item « Skill-installer global » avait pour déclencheur la clôture du milestone Install UX —
  atteinte le 2026-06-05 ; l'item a dormi 7 semaines déclencheur consommé.
- Files: `.planning/BACKLOG.md:36-38`
- Impact: le backlog perd sa valeur de radar si les déclencheurs ne sont pas honorés.
- Fix approach: ré-arbitrage explicite (reprendre / re-différer avec nouveau déclencheur / abandonner).

**`.planning/WINDOWS.md` est un fichier purement généré tant que gsd-core ≤ 1.9.1** — Sévérité : **MEDIUM**
- Issue: bug amont **#2893** — `gsd-tools windows append|waive|fixed` passent tous les trois par le
  même `writeLedgerAtomic` → `renderLedger`, qui **réécrit le fichier intégralement** (frontmatter +
  en-tête figé + table + miroir JSON, et rien d'autre) et rapporte `ok: true`. Toute prose libre
  ajoutée sous le ledger serait détruite **sans avertissement**. La PR corrective **#2975** est
  mergée mais **non publiée** : `dist-tags.latest` = `1.9.1` (2026-07-31), aucune version au-delà.
- Files: `~/.claude/gsd-core/bin/lib/broken-windows.cjs` (version installée 1.9.1) ;
  `.planning/WINDOWS.md` (87 lignes, aucune prose libre sous le ledger au 2026-08-04)
- Impact: **nul en l'état** — c'est précisément ce qui a permis d'activer la zone 2 (ADR-066) : le
  bug n'a rien à détruire sur ce fichier. Le risque n'apparaîtrait que si quelqu'un ajoutait de la
  prose sous le ledger, ou éditait le fichier à la main.
- Fix approach: **ne pas écrire à la main dans `.planning/WINDOWS.md`** et ne pas y ajouter de prose
  sous le ledger ; **le committer avant toute commande `windows`** pour que tout dégât reste
  récupérable (répéter d'abord sur une copie jetable via `--cwd` est bon marché et concluant).
  Résolution définitive : monter `@opengsd/gsd-core` dès qu'une version strictement supérieure à
  1.9.1 portant le correctif #2893 est publiée. **Cette montée ne gate aucun travail** — la zone 2
  est activée, elle n'attend rien (ADR-066, § Note de veille).

**Fenêtre #3 du ledger dérogée, pas résolue — la recette XcodeBuildMCP reste à faire ailleurs** — Sévérité : **LOW**
- Issue: valider `test_sim`/`build_sim`/`clean` (tokens `vf-mcp-tools`) contre un serveur
  XcodeBuildMCP **vivant** est impossible dans ce dépôt : aucun `.mcp.json`, aucun projet iOS, aucun
  simulateur. La fenêtre a donc été **dérogée** (`waived`) le 2026-08-04, pas fermée.
- Files: `.planning/WINDOWS.md` (entrée id 3, `status: waived`) ;
  `plugin/dev-orchestrator/agents/vf-reviewer.md`
- Impact: `open_count` = 0, donc `/gsd-ship` ne bloque plus — mais la recette humaine n'a **jamais
  été jouée**. Ne pas lire cette dérogation comme une validation.
- Fix approach: rejouer la recette sur un **lab iOS équipé** (projet Xcode + `.mcp.json` + simulateur),
  puis reporter le constat ici. La dérogation se réexamine si `vibeflow-os` acquiert un projet iOS.

**Aucune primitive partagée de confinement de chemin — le motif symlink en est à son 4ᵉ passage** — Sévérité : **HIGH**
- Issue: le même défaut (un chemin dérivé d'une entrée non maîtrisée qui sort de son arbre par
  lien symbolique) a été fermé **quatre fois, à quatre endroits, sans jamais l'être une fois pour
  toutes** : deux scripts en Phase 23 ; `check-workstream-pointer.sh` (vague 1, refus `[ -L ]`) ;
  `build-gsd-capabilities-index.sh` (vague 2, `vf_realpath` node + comparaison de préfixe) ; et
  le répertoire de compartiment (découvert le 2026-08-04, **fermé le soir même** par `960055d` —
  voir T-24-14-C1 ; le motif, lui, reste ouvert : il s'est fermé **là**, une 4ᵉ fois, sans primitive
  partagée, et le segment RACINE reste non couvert — voir Security Considerations). Le
  commentaire du 3ᵉ passage écrit lui-même « *C'est le troisième passage de ce motif dans ce
  dépôt ; il se ferme ici* » (`build-gsd-capabilities-index.sh:166`) — il s'est fermé **là**, et
  le motif est réapparu ailleurs. Trois causes mesurées :
  **(1)** six implémentations du même besoin coexistent dans **trois langages** — `[ -L ]`
  (`workstream-policy.sh:153`), `vf_realpath` node (`build-gsd-capabilities-index.sh:174-176`),
  `os.path.realpath` python (`guard-agent-write.sh:78`), `pwd -P`
  (`check-branch-claim.sh:128`), `os.path.normpath` (`guard-read-registres.sh:25`) ;
  **(2)** la primitive existe déjà mais **déguisée en règle métier** — `vf_ws_read_pointer()`
  (`workstream-policy.sh:149-171`) est une lecture sûre générique (ses 3 refus — lien
  symbolique, fichier non régulier, taille — n'ont rien de spécifique au workstream) mais son
  nommage (`VF_WS_RAW`, `VF_WS_REASON`) la rend invisible à qui résout un autre genre de chemin ;
  **(3)** le contrôle anti-duplication existe déjà mais **sur un roster figé** —
  `test-workstream-policy.sh` C1 (`:301-313`) / C2 (`:316-322`) / C3 (mutation, `:324+`) est
  exactement la bonne forme, mais C1 itère sur **quatre chemins écrits en dur**. Un script neuf
  n'appartient à aucun roster : il peut ré-inventer le confinement sans que rien ne s'en
  aperçoive. **Le contrôle est aveugle aux nouveaux entrants, qui sont précisément la population
  qui reproduit le motif.**
- Files: `plugin/planning-core/scripts/workstream-policy.sh:149-171`,
  `plugin/planning-core/scripts/tests/test-workstream-policy.sh:301-322`,
  `plugin/dev-orchestrator/scripts/build-gsd-capabilities-index.sh:160-192`,
  `plugin/conductor/scripts/guard-agent-write.sh:78`,
  `plugin/conductor/scripts/check-branch-claim.sh:128`,
  `plugin/consolidator/scripts/guard-read-registres.sh:25`
- Impact: sur les 52 scripts hors tests de `plugin/*/scripts/`, **37** lisent un fichier à un
  chemin porté par une variable et **29** ne portent aucun marqueur de confinement. Ce chiffre
  est un **majorant de candidats à trier, pas un décompte de vulnérabilités** (beaucoup de ces
  chemins dérivent de la racine du dépôt et ne sont pas pilotables). Il donne l'ordre de
  grandeur de la surface. Tant que le contrôle reste par-script, un 5ᵉ passage est attendu.
- Fix approach: **(a)** primitive partagée dans `plugin/planning-core/scripts/` (le précédent est
  là : la politique de workstream y vit et est sourcée par 4 scripts de 3 modules, et sa
  fermeture de dépendances est réduite à elle-même) — **deux** fonctions, car le motif a deux
  moitiés que les quatre passages confondent : `vf_path_refuse_link` (refuser de suivre — cas
  pointeur) et `vf_path_confine <candidat> <ancre>` (chemin réel sous ancre réelle — cas registre
  et cas compartiment) ; **(b)** généraliser C1/C2 du roster figé à l'**énumération** de
  `plugin/*/scripts/*.sh`, chaque script lisant un chemin dérivé d'une entrée devant soit sourcer
  la primitive, soit figurer dans une liste d'exemptions **nommée et motivée** ; **(c)** cas de
  **mutation obligatoire** sur le modèle de C3 — un script neuf non confiné ajouté au corpus doit
  faire rougir la suite, sans quoi la garde n'est qu'une assertion d'*existence* (« la primitive
  existe quelque part ») qui reste verte pendant que la *relation* se rompt.

**`hooks.workflow_guard` se déclenche sur des fichiers HORS du dépôt** — Sévérité : **LOW**
- Issue: la capacité a été activée par la Phase 24 (ADR-066) et se comporte comme annoncé sur le
  dépôt — mais son périmètre ne s'arrête pas à l'arbre du projet. Constaté **de première main le
  2026-08-05**, pendant le mandat de correction ciblée : l'écriture d'un script de travail dans le
  scratchpad de session (`/private/tmp/claude-501/…/scratchpad/`, **hors du dépôt**) a déclenché
  l'avis « cette édition ne sera pas tracée dans STATE.md ». Même signalement rapporté sur une
  écriture dans `~/.claude/projects/…`, sans rapport avec le projet. L'avis est donc **juste sur sa
  lettre** (aucun `/gsd-*` n'était en cours) et **hors sujet sur son objet** : ces fichiers n'ont
  aucune vocation à être tracés dans le `STATE.md` d'un projet.
- Files: capacité amont `workflow_guard` du moteur GSD (`~/.claude/gsd-core/hooks/gsd-workflow-guard.sh`
  dans l'installation de référence) ; activée par `.planning/config.json` (`hooks.workflow_guard: true`)
- Impact: **non bloquant** — le hook est advisory (ADR-031 tenu), il n'a jamais empêché une écriture.
  Le coût est du **bruit** : sur un mandat qui écrit hors du dépôt (scratchpad, fixtures jetables), un
  avis identique se répète à chaque écriture et devient un signal qu'on apprend à ignorer. C'est le
  chemin classique par lequel une garde advisory se désarme sans que personne ne la débranche.
  **La prochaine phase doit savoir d'où vient ce bruit** avant de conclure à un défaut du projet.
- Fix approach: (a) mesurer d'abord la règle de périmètre réelle du hook amont sur l'installation
  courante (est-il censé se borner à la racine du projet ?) ; (b) si le comportement est conforme
  à l'amont, c'est une **remontée upstream**, pas un correctif local — ce dépôt câble la capacité,
  il ne la fourche (Iron Law 2 révisée, ADR-069) ; (c) ne PAS désactiver le toggle pour faire taire
  le bruit : ce serait perdre la garde sur le dépôt, qui, elle, fonctionne.

## Known Bugs

Aucun bug ouvert confirmé sur disque au 2026-07-26. Les comportements gênants connus (survie de
fichiers à l'update, faux positifs check-agents hors baseline) sont des limites de conception
capturées au backlog — voir Tech Debt.

## Security Considerations

**Nom de module non assaini dans l'engine** — Sévérité : **LOW**
- Risk: `install_module` valide seulement `[ -d "$CACHE_DIR/$mod" ]` — un nom contenant `../`
  résoudrait hors cache. Exposition faible : l'appelant prod est le skill `/vibeflow-install` qui
  passe des noms issus du catalogue, et le cache est local.
- Files: `plugin/_internal/vibeflow-update.sh` (`install_module`, garde `-d` uniquement)
- Current mitigation: `err` si le dossier n'existe pas ; noms fournis par le catalogue en prod.
- Recommendations: rejeter tout nom contenant `/`, `..` ou espace au parsing des positionnels.

**Pas de filtrage de secrets dans la copie d'install** — Sévérité : **LOW**
- Risk: l'engine copie des arborescences de modules vers `.claude/` sans filtre de motifs
  (`.env*`, clés). Exposition faible car la source est le cache du plugin packagé, pas le lab.
- Files: `plugin/_internal/vibeflow-update.sh` (copies `cp` dans `install_module`)
- Current mitigation: source contrôlée (cache = contenu du repo publié).
- Recommendations: garde ceinture-bretelles excluant `*.env*` / `*secret*` des copies.

**Le verrou de driver est déclaratif, pas contraignant** — Sévérité : **HIGH**
- Risk: `driver-lock.sh` n'empêche techniquement rien : aucun hook ni garde en écriture ne refuse un
  commit à une session sans verrou. Constaté le 2026-07-27 : le lock de `mission-phase16` a été élagué
  par TTL, `mission-phase17` l'a acquis, et la Phase 16 a **continué à commiter** pendant que la
  Phase 17 tenait le verrou — horodatages entrelacés 22:37 P16 · 22:38 P17 · 22:42 P16 · 22:46 P16 ·
  22:48 P17 · 22:50 P16. Conséquence concrète : collision de version, la Phase 17 ayant planifié le
  `v2.5.0` que la Phase 16 venait de prendre (résolu en `v2.6.0`, commit `5a8b6a8`). Deux drivers
  concurrents sur le même `.planning/` peuvent écraser silencieusement les arbitrages l'un de l'autre.
- Files: `plugin/conductor/scripts/driver-lock.sh`
- Current mitigation: aucune — le lock est un fichier de coordination consulté par convention, pas un
  garde-fou machine ; le TTL réduit la fenêtre d'expiration mais ne l'élimine pas.
- Recommendations: instrumenter un hook d'écriture (`PreToolUse` sur `Write`/`Edit` de `.planning/`)
  qui refuse si le lock actif n'appartient pas à la session courante ; ou heartbeat pendant l'attente
  d'un worker pour empêcher l'expiration TTL en cours de mission (déjà tracé dans `STATE.md` §Phase 16).

**Le gate ADR-044 est un faux vert dans son invocation nue** — Sévérité : **MEDIUM**
- Risk: `bash plugin/conductor/scripts/check-agents.sh` **sans argument** sort **exit 0** avec
  « aucun agent dans .claude/agents — rien a verifier », car `.claude/agents` est absent de ce repo.
  Or c'est cette invocation que prescrivent les critères d'acceptation (spec Phase 17 §7.6) — elle ne
  prouve RIEN. De plus, `plugin/dev-orchestrator/AGENT.md` (`name: vibeflow-dev`) est à la racine du
  module, donc hors de la boucle CI sur `plugin/*/agents` : il n'est atteint que par
  `check-agents.sh --file`. Invocation réelle qui prouve quelque chose :
  `bash plugin/conductor/scripts/check-agents.sh --file plugin/dev-orchestrator/AGENT.md` (exit 0,
  3 warnings préexistants : name ≠ nom de fichier, aucun skill câblé, `tools:` absent). Tout critère
  d'acceptation futur rédigé sur l'invocation nue est satisfait à la lettre et vide sur le fond.
- Files: `plugin/conductor/scripts/check-agents.sh`, `.github/workflows/ci.yml`
- Current mitigation: aucune — constaté le 2026-07-27, non corrigé (hors mandat de clôture Phase 17).
- Recommendations: toute future spec/critère d'acceptation qui cite `check-agents.sh` sans argument
  sur ce repo doit être remplacée par l'invocation `--file` explicite du (des) `AGENT.md` racine de
  module ; ou faire pointer l'invocation nue sur les emplacements réels des `AGENT.md` du repo plutôt
  que sur `.claude/agents` (répertoire d'un lab qui a *installé* le plugin, pas de ce repo lui-même).

**Fuite hors-lab par répertoire de compartiment en lien symbolique (T-24-14-C1)** — Sévérité : **HIGH** — **FERMÉE le 2026-08-04**
- Risk: le nom de workstream est validé et le pointeur-*fichier* refuse les liens symboliques
  (`plugin/planning-core/scripts/workstream-policy.sh:153-156`), mais **rien ne contraint le
  répertoire de compartiment lui-même**. Avec `.planning/workstreams/<nom>` posé en lien
  symbolique vers un répertoire hors du lab, `[ -d ]` le suit et
  `plugin/planning-core/scripts/planning-context.sh:168` injecte le `STATE.md` de la cible
  **verbatim dans le contexte de session**. **Reproduit** le 2026-08-04 sur fixture jetable : à
  exit 0, une ligne sentinelle lue hors de l'arbre du lab apparaît dans la sortie du hook.
  Préconditions identiques à celles du trou pointeur que la Phase 24 a jugé réel et fermé : une
  entrée mode 120000 committée sous `.planning/`, puis n'importe quelle ouverture de session.
- Files: `plugin/planning-core/scripts/planning-context.sh:168`,
  `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh:286` (portée réduite à 3 valeurs
  ≤ 80 caractères par la liste blanche), `plugin/conductor/scripts/check-state-integrity.sh:145`
- Current mitigation: **fermée le 2026-08-04** (correctif `960055d`, preuve `a64df96`). Les deux
  segments du compartiment et les fichiers qu'on y lit passent par `vf_ws_dir_resolve` /
  `vf_ws_file_in_ws` (`plugin/planning-core/scripts/workstream-policy.sh`), qui **refusent de
  traverser** au lieu de tenter de décider si la cible est « dans le lab » — un tel test se réécrit
  avec `..`, dépend d'un `readlink -f` absent de macOS et ne survit pas à un remontage. La cible
  n'est jamais lue ni nommée ; seule la raison sort, d'une énumération fermée. Gradation par rôle :
  vérification → exit 2, injecteurs → repli sur la racine **plus** une ligne qui nomme le refus.
  Fermeture prouvée **par mutation sur les quatre gates à la fois**
  (`plugin/planning-core/scripts/tests/test-workstream-symlink-escape.sh`). Registre C de
  `.planning/phases/VFDO-24-*/24-SECURITY.md` : statut `closed`.
- Recommendations: **rien de plus sur ce vecteur.** Ce qui reste ouvert n'est pas cette menace mais
  le **motif** : c'est son 4ᵉ passage, refermé une 4ᵉ fois localement — voir Tech Debt (primitive
  partagée de confinement) — et le **segment racine** reste hors couverture, voir l'entrée
  « `.planning` lui-même en lien symbolique » plus bas.

**T-24-02-01 — mitigation falsifiée, en attente d'un arbitrage humain** — Sévérité : **HIGH**
- Risk: le modèle de menaces du plan 24-02 mitigeait le risque `gsd-tools windows *` par
  **abstinence** (« aucune tâche ne les invoque ») plus une interdiction écrite. Les deux moitiés
  sont tombées : ADR-066 ne porte aucune formulation d'interdiction et **acte** l'exécution
  (`docs/ADR.md:1597`), et la commande **a été invoquée** (commit `7b96e34`,
  `.planning/WINDOWS.md:3-4`, entrée id 3 `"status": "waived"`). Le dégel était une décision
  humaine légitime — mais le registre de menaces n'a jamais été révisé en conséquence, et aucune
  entrée n'existe au journal des risques acceptés.
- Files: `docs/ADR.md:1565-1651` (ADR-066), `.planning/WINDOWS.md`,
  `.planning/phases/VFDO-24-*/24-SECURITY.md` (registre A)
- Current mitigation: contrôles compensatoires réels mais non déclarés comme la mitigation —
  répétition préalable sur copie jetable via `--cwd` (`docs/ADR.md:1609-1611`), post-conditions
  vérifiées (`:1611-1615`), risque résiduel acté (`:1633-1639`), et **aucun script du dépôt
  n'invoque ces commandes** (balayage `.sh`/`.md`/`.json`/`.yml` : prose uniquement).
- Recommendations: acte **humain** requis — soit re-disposer en `accept` avec entrée nominative
  au journal (justification ADR-066 + les quatre contrôles), soit réécrire la mitigation autour
  des contrôles réellement en place. Un agent ne peut pas s'inscrire lui-même dans la colonne
  « Accepté par » sans la vider de son sens.

**`.planning` lui-même en lien symbolique — surface NON COUVERTE, pas exposition vivante** — Sévérité : **LOW**
- Risk: le correctif `T-24-14-C1` contraint les **deux segments du compartiment**
  (`<planning>/workstreams` puis `<planning>/workstreams/<nom>`) et les fichiers qu'on y lit. Il ne
  contraint **pas le segment racine** : `<planning>` est fourni par `--path` ou par l'environnement, et
  arrive dans `vf_ws_dir_resolve` **déjà résolu par l'appelant**. Un `.planning` versionné en mode
  `120000`, ou une racine passée par `--path` qui en traverse un, rejouerait le **même vecteur un cran
  plus haut** : `[ -d ]`/`[ -f ]` suivent le lien exactement de la même façon. Ce serait, en toutes
  lettres, le **5ᵉ passage** du motif inventorié en Tech Debt.
- Files: `plugin/planning-core/scripts/workstream-policy.sh` (`vf_ws_dir_resolve` : le paramètre
  `<planning_dir>` n'est pas contrôlé, par construction), et les quatre appelants qui le lui
  fournissent — `planning-context.sh`, `check-dev-bootstrap.sh`, `check-state-integrity.sh`,
  `check-workstream-pointer.sh`
- Impact: **THÉORIQUE DANS CE DÉPÔT, et la nuance est le fond de l'entrée.** Vérifié de première main
  le 2026-08-05 : `.planning` est un **vrai répertoire** (`[ -L ]` faux, `[ -d ]` vrai), et
  `.planning/workstreams` **n'existe pas** — ce dépôt n'est pas partitionné. Il n'y a donc **rien à
  exploiter ici aujourd'hui** : c'est une **surface non couverte**, pas une fuite ouverte. L'inscrire
  comme exposition vivante serait aussi faux que de la taire — et brouillerait la lecture du registre
  de menaces, où une entrée `high` engage un blocage de ship.
- Recommendations: ne PAS refermer cette surface en durcissant `vf_ws_dir_resolve` sur son propre
  paramètre — la primitive ne peut pas savoir ce que son appelant a le droit de désigner, et un refus
  y casserait les usages légitimes (`--path` vers une fixture, worktree). La fermeture appartient à la
  **primitive partagée de confinement de chemin** déjà recommandée en Tech Debt (`vf_path_refuse_link`
  / `vf_path_confine`), appliquée **au point où la racine est résolue**. À traiter avec elle, pas
  avant : deux correctifs séparés sur le même motif, c'est ce qui a produit les quatre passages.

## Performance Bottlenecks

Rien de bloquant identifié à l'échelle actuelle (registres de labs de quelques centaines
d'entrées ; scripts bash + python3 stdlib). Les anciens points (O(n²) de
`plugin/consolidator/scripts/detect-duplicates.sh`, chargement mémoire de `reindex.sh`) restent
vrais dans le code mais sans impact observé — sévérité **LOW**, ne pas prioriser.

## Fragile Areas

**Modules `mobile-test` / `mobile-test-team` expérimentaux — « run réel vert » jamais tracé** — Sévérité : **HIGH**
- Files: `plugin/mobile-test/module.json:5` et `plugin/mobile-test-team/module.json:5` (« Statut
  expérimental jusqu'au premier run réel vert ») ; `plugin/mobile-test/README.md:10`,
  `plugin/mobile-test-team/README.md:11` (bandeaux ⚠️)
- Why fragile: le pipeline (`plugin/mobile-test/scripts/mobile-test-run.mjs`, 409 lignes, Node) et
  l'orchestration de sous-agents imbriqués (Pattern 12, `plugin/mobile-test-team/agents/`) n'ont
  jamais été prouvés par un run réel documenté depuis leur import. Aucun rapport horodaté dans
  `reports/`.
- Safe modification: ne pas étendre ces modules avant un run réel vert tracé (rapport commis) ;
  toute release qui les touche doit le mentionner comme non-validé.
- Test coverage: **zéro** — voir Test Coverage Gaps.

**Chiffres en prose non gatés — la famille de dérive n'est pas éteinte** — Sévérité : **MEDIUM**
- Files: `README.md:169-182` et `README.fr.md:171-187` (tableau des modules, colonne version) —
  actuellement alignés (vérifié 2026-07-26) mais **hors périmètre** de
  `scripts/check-version-sync.sh` (ses 9 points couvrent badges, phrase « N modules », triade
  VERSION↔module.json, en-têtes Version des README de modules, historique en tête, compte de
  suites — pas la colonne version du tableau racine).
- Why fragile: c'est exactement la dérive F1 (13 modules mensongers) qui a motivé le gate ; l'audit
  du 2026-07-26 a encore trouvé 14/14 en-têtes Version faux avant que le point 8 du gate ne les
  couvre. Tout compteur en prose hors gate finit par mentir.
- Safe modification: à chaque nouveau chiffre en prose dans un README, soit le gater dans
  `check-version-sync.sh`, soit le remplacer par un renvoi vers la source machine.
- Test coverage: le gate lui-même n'a pas de suite (voir Test Coverage Gaps).

**Sonde cross-module `conductor` → `dev-orchestrator` aveugle en silence si le layout d'install change** — Sévérité : **MEDIUM**
- Files: `plugin/conductor/skills/vf-update/SKILL.md` (étape 1, sonde de `check-gsd-engine.sh` en
  cascade `$HOME/.claude/scripts/` → `./.claude/scripts/` → `${CLAUDE_PLUGIN_ROOT}/conductor/scripts/`) ;
  `docs/ADR.md` §ADR-058 (Conséquences négatives, où le risque est auto-documenté).
- Why fragile: `vf-update` (module `conductor`, mandatory) appelle un script de `dev-orchestrator`
  (non mandatory) par **sonde de présence de fichier**, jamais par un `requires` — inverser la
  dépendance casserait la baseline d'un lab non-dev. Le silence sur script absent est **voulu** (un
  lab content/growth ne doit rien voir), mais il rend le mode dégradé indiscernable du mode nominal :
  si l'engine cessait un jour de matérialiser les scripts de tous les modules à plat dans le même
  `.claude/scripts/`, la détection du moteur GSD s'éteindrait **sans aucun signal**, exactement le
  trou que la Phase 19 vient de fermer.
- Safe modification: toute évolution de `copy_module_scripts()` / du layout d'install
  (`plugin/_internal/vibeflow-update.sh`) doit être accompagnée d'une vérification que la sonde
  résout toujours ; ne jamais convertir ce silence en dépendance déclarée.
- Test coverage: les 3 états du gate sont couverts (`test-check-gsd-engine.sh`, 15 cas) ; la
  **résolution de la sonde depuis le skill** ne l'est pas — c'est du markdown, non exécutable.

**Greps du gate sensibles aux reformulations README** — Sévérité : **LOW**
- Files: `scripts/check-version-sync.sh:60-71` (phrases « N modules, each versioned » /
  « N modules, chacun versionné » cherchées littéralement)
- Why fragile: une refonte éditoriale des README casse le grep ; le gate signale désormais la cible
  introuvable (ko explicite, leçon du contrôle sauté en silence) mais chaque refonte impose de
  réaligner les motifs.
- Safe modification: après toute refonte README, lancer `bash scripts/check-version-sync.sh` en local.

## Scaling Limits

**Découverte de suites CI limitée au motif `*/tests/test-*.sh`** — Sévérité : **MEDIUM**
- Current capacity: 37 suites bash découvertes (`.github/workflows/ci.yml:32`).
- Limit: tout test non-bash est invisible — `plugin/mobile-test/scripts/mobile-test-run.mjs` (Node)
  ne peut structurellement pas être couvert par ce pipeline.
- Scaling path: soit un wrapper bash `tests/test-mobile-test-run.sh` qui invoque le `.mjs` en mode
  dry-run, soit élargir la découverte CI.

## Dependencies at Risk

**`python3` et `jq` supposés présents, non vérifiés à l'install** — Sévérité : **LOW**
- Risk: plusieurs scripts consomment `python3` (consolidator, check-agents) et `jq`
  (resolve-deps a un fallback sed, mais pas tous les consommateurs) sans check de présence à
  l'install d'un module.
- Impact: échec runtime tardif sur machine minimale. Atténué : la CI « fresh lab » (`ci.yml:116+`)
  valide le parcours complet sur runner standard, et `check-version-sync.sh` évite volontairement jq.
- Migration plan: `verify_dependencies()` dans l'engine ou dans `plugin/installer/scripts/preflight.sh`
  (qui existe déjà — vérifier son périmètre et le câbler systématiquement).

## Missing Critical Features

**Phase 13 en suspens — plan écrit, rien d'exécuté** — Sévérité : **MEDIUM** (dette de process, pas de code)
- Problem: le plan 13-01 (`discover-unintegrated-docs.sh`, BRDG-02) est écrit et committé mais
  **non exécuté** (0 SUMMARY) ; le plan 13-02 (câblage de l'ingestion dans l'agent `vibeflow-dev`)
  reste à planifier.
- Files: `.planning/phases/13-pont-spec-feuille-de-route/13-01-PLAN.md` ; `.planning/STATE.md:6-8`
  et `:30-36` (stopped_at + Current Position)
- Blocks: la promesse « pont spec → feuille de route » du milestone vf-routing (dernière phase du
  milestone, 2/3 complétées). Prochaine action documentée : `/gsd:execute-phase 13`.

**Milestone `gsd-migration` — Phase 11 livrée et vérifiée** — Sévérité : **LOW**
- Problem: Phase 11 (intégration migration GSD, `get-shit-done-cc` → `@opengsd/gsd-core`) a été
  exécutée et vérifiée (6 vagues, PASS sur les 3 critères, suites vertes) le 2026-07-26. Le
  milestone `MILESTONES.md:42` porte encore le statut « EN ATTENTE — non planifié » hérité de sa
  création — désynchronisé de l'avancement réel.
- Files: `.planning/MILESTONES.md:42` ; `.planning/phases/10-etude-migration-gsd/`,
  `.planning/phases/11-integration-migration-gsd/`
- Blocks: rien de bloquant — mais le statut du milestone (`MILESTONES.md`) mérite une mise à jour
  pour ne pas laisser croire à un chantier non démarré alors qu'il est en grande partie livré.

## Test Coverage Gaps

**Les gates de release eux-mêmes n'ont aucune suite** — Priority: **HIGH**
- What's not tested: `scripts/check-version-sync.sh` (9 points, parsing grep/sed volontairement
  sans jq), `scripts/check-release-tag.sh`, `scripts/bump.sh`. Le dossier `scripts/` n'a pas de
  `tests/` — la découverte CI (`find plugin scripts -path '*/tests/test-*.sh'`) n'y trouve donc rien.
- Files: `scripts/bump.sh`, `scripts/check-version-sync.sh`, `scripts/check-release-tag.sh`
- Risk: une régression dans un gate (grep qui ne matche plus, faux vert) neutralise silencieusement
  la protection anti-dérive — la classe de bug la plus coûteuse de l'historique du repo (divergence
  main juillet 2026). Ironique : tout le reste est gaté par eux.
- Priority: **HIGH** — suite `scripts/tests/test-check-version-sync.sh` sur fixtures (README/VERSION
  synthétiques désalignés → le gate doit ko).

**`mobile-test-run.mjs` — 409 lignes Node, zéro test** — Priority: **HIGH**
- What's not tested: détection de cible, build-if-absent, rapport horodaté, diagnostic sur échec.
- Files: `plugin/mobile-test/scripts/mobile-test-run.mjs` (aucun `tests/` dans le module)
- Risk: module déjà expérimental + script central non testé = régression invisible garantie ; hors
  motif de découverte CI (voir Scaling Limits).
- Priority: **HIGH** — préalable au « premier run réel vert » qui lèverait le statut expérimental.

**`plugin/installer/scripts/preflight.sh` non couvert** — Priority: **MEDIUM**
- What's not tested: le preflight d'install (la suite du module, `test-build-module-catalog.sh`, ne
  le référence pas ; aucune mention dans `plugin/_internal/tests/`).
- Files: `plugin/installer/scripts/preflight.sh`
- Risk: un preflight cassé laisse passer des installs sur environnement non conforme.

**`mobile-test-team` — orchestration Pattern 12 jamais éprouvée** — Priority: **MEDIUM**
- What's not tested: la boucle test → corrige → re-test (vf-test-orchestrator + workers
  vf-test-runner / vf-app-fixer). Les agents passent `check-agents.sh --strict` (conformité de
  forme) mais aucun run d'orchestration n'est tracé.
- Files: `plugin/mobile-test-team/agents/`, `plugin/mobile-test-team/README.md:11`
- Risk: le module vend une capacité autonome non démontrée.

**Gestes documentés de la Phase 24 sans aucune garde machine** — Priority: **HIGH**
- What's not tested: trois mitigations **présentes aujourd'hui, gardées par rien demain**,
  relevées par l'audit sécurité du 2026-08-04 (fermées au registre parce qu'elles livrent ce
  qu'elles promettaient, mais sans non-régression) :
  **(1)** `hooks.json` — le `|| true` sur les 5 commandes `SessionStart` de conductor (T-24-05-02).
  Le filtre `jq` qui devait le vérifier ne vit que dans le bloc `<verify>` du plan, un one-shot
  d'exécution. Aucune suite ni étape CI ne l'asserte. Le précédent existe pourtant :
  `plugin/consolidator/scripts/tests/test-consolidator.sh:295-296` (T-CSL11) fait exactement cela
  pour le `PostToolUse` de consolidator.
  **(2)** `workstreams.md` — le geste de vérification avant PR (T-24-08-03) et l'ordonnancement
  « résous le compartiment **AVANT** toute lecture » (T-24-08-01). Le seul exécutable qui
  mentionne `workstreams.md` est `test-dev-orchestrator.sh:6139-6158` (T35), et il ne vérifie que
  le **renvoi** depuis les deux agents, jamais le **contenu**. Concrètement : supprimer le geste
  PR, les quatre gestes, ou le mot « AVANT » laisse **toute la CI verte**.
  **(3)** plafond ADR-029 sur les deux modules injectés en `agent_skills` (T-24-03-03) :
  `test-dev-orchestrator.sh:1052` borne T5 à `"$MOD"/skills/vf-*/SKILL.md`, or
  `plugin/software-architecture/SKILL.md` et `plugin/audit-architecture/SKILL.md` sont à la racine
  de modules autonomes, sans préfixe `vf-`. Le volume injecté dans le prompt de `gsd-planner`
  (269 lignes aujourd'hui) peut croître au-delà de 500 sans qu'aucun gate ne rougisse.
- Files: `plugin/conductor/hooks/hooks.json:16-20`,
  `plugin/dev-orchestrator/references/workstreams.md:138-145`,
  `plugin/dev-orchestrator/agents/vf-dev-manager.md:33-34`,
  `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:1052`
- Risk: une régression sur l'une de ces trois rouvre une menace **fermée** de la Phase 24 sans
  qu'aucun signal ne se déclenche — le mode d'échec exact que le registre de menaces existe pour
  empêcher.

**`24-03-SUMMARY.md` affirme le contraire de l'arbre courant** — Priority: **MEDIUM**
- What's not tested: rien ne vérifie qu'un SUMMARY reste vrai après coup. `24-03-SUMMARY.md:74-78`
  affirme que « les **9** clés refusées ou différées sont **TOUTES absentes**, chacune vérifiée
  individuellement ». Or `.planning/config.json:27` porte `"windows_enforce": true` et `:45`
  porte `"workflow_guard": true` — posées par le plan **24-02** sous ADR-066. Le PLAN a été
  corrigé et daté (`24-03-PLAN.md:88-93`, `:104`), le SUMMARY ne l'a pas été. Un relecteur du
  SUMMARY conclurait que la zone 2 est désarmée alors qu'elle est **armée et bloquante** à
  `ship:pre`.
- Files: `.planning/phases/VFDO-24-*/24-03-SUMMARY.md:74-78`, `.planning/config.json:27,45`
- Risk: c'est la classe de fait la plus dangereuse du dépôt — un artefact de traçabilité qui dit
  le contraire du réel et que personne ne re-mesure. Non corrigé ici : le mandat d'audit
  autorisait à *enregistrer un verdict* dans les SUMMARY, pas à les réécrire.

---

*Concerns audit: 2026-07-26 — v2.36.1, 17 modules, 37 suites CI*
*Complété 2026-08-04 par `/gsd-secure-phase 24` : 4 entrées (1 dette d'architecture HIGH,
2 sécurité HIGH, 2 lacunes de couverture) issues de l'audit des 34 menaces ouvertes.*
