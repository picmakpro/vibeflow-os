# Changelog — conductor

## [v1.17.0] — 2026-07-31 (fluidité du flux de dev sans perte de qualité, Phase 20)

### Ajouté
- **`check-agents.sh` / `check-debug-research.sh` — le chemin PAR DÉFAUT (sans `--agents-dir`/
  `--skills-dir`) est enfin exercé par un test.** Fin du faux vert qui en découlait : sur cible
  absente, le défaut sort désormais en 3 INDÉTERMINÉ (jamais un vert silencieux) ; sur cible
  présente non conforme sans flag, il détecte réellement l'anomalie.
- **`hooks.json` : périmètre explicite** — les 2 commandes `SessionStart` de conformité reçoivent
  `--agents-dir`/`--skills-dir`, condition de possibilité du point précédent.
- **`check-agents.sh --hook` : avertissements affichés dès qu'il y en a un**, silence total
  inchangé en régime 0 erreur / 0 avertissement — jusqu'ici le mode hook cachait les warnings.
- **Charset d'un token MCP élargi à `mcp__<serveur>__*`** (joker terminal uniquement), ce que
  produit l'injecteur ADR-051 depuis sa livraison — le gate contredisait son propre injecteur.
- **`check-debug-research.sh --third-party-prefix`** : mécanisme d'exclusion des briques tierces
  porté à l'identique de `check-agents.sh` (même flag, même défaut `gsd-`), pas réinventé.
- **Règle anti-régression** : un agent `memory:` dont le `tools:` omet Write ET Edit doit fermer
  le canal via `disallowedTools` — sinon `memory: project` le rouvre silencieusement au runtime.
  Warning par défaut, erreur en `--strict`.
- **`dag.sh` : `--scope` sur `add`** (périmètre déclaré d'un nœud, rétro-compatible) et `reopen` qui
  force `review_regime=full` sur tout nœud de revue/jointure rouvert — enforcement machine du
  garde-fou « aucun allègement ne s'applique jamais à un diff de comblement ». `status` expose la
  table des fichiers gelés dérivée à la demande (jamais une copie figée).
- **`check-mission-invariants.sh`** (nouveau, gate advisory patronné sur `check-doc-drift.sh`) :
  constate qu'un glob de zone de risque de `.planning/MISSION-INVARIANTS.md` ne matche plus aucun
  fichier suivi. Lecture seule, ne juge jamais.
- **Doctrine du noyau d'équipe mise en conformité** (`references/team-kernel.md` + `README.md`) :
  la ligne de cloisonnement par outils cite désormais le mécanisme réel (`disallowedTools:
  Write, Edit`) qui rend la barrière des 4 juges effective ; nouvelle ligne documentant la classe
  symétrique « un outil déclaré peut être absent au runtime » (filet de repli : le besoin humain
  remonte dans le rapport typé) ; la ligne du plan de bataille cite `--scope` et `review_regime`.

### Corrigé
- **Le changement de périmètre des hooks ci-dessus est une correction de configuration, pas un
  changement de doctrine** — aucune ADR dédiée, cf. `docs/ADR.md`.

Référence : `docs/ADR.md` ADR-051 (révisée), ADR-060 (nouvelle),
`.planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/`.

## [v1.16.0] — 2026-07-28 (moteur GSD dans le récapitulatif de /vf-update, Phase 19)

### Ajouté
- **`skills/vf-update/SKILL.md` : diagnostic à deux volets.** L'étape 1 consultait uniquement le
  plugin et s'arrêtait net sur « VibeFlow est à jour » — un poste dont le plugin est à jour mais
  dont le moteur GSD est resté legacy ne voyait donc jamais la proposition de migration (trou
  audité le 2026-07-28). La sonde best-effort `check-gsd-engine.sh` (module `dev-orchestrator`) est
  désormais consultée **avant** ce stop ; script introuvable → silence total, aucune dégradation
  pour un lab non-dev qui n'installe pas `dev-orchestrator`.
- **Ligne de confirmation indépendante** : quand un moteur legacy est détecté, l'étape 3
  (`AskUserQuestion`) gagne une ligne dédiée à la migration, acceptable ou refusable
  **indépendamment** de la ligne plugin et de la ligne modules — refus sans effet de bord ni
  relance (ADR-031).
- **Bornes des deux flags existants explicitées, aucun flag nouveau créé** (densité ADR-029) :
  `--check` affiche l'état du moteur comme le reste du diagnostic sans jamais demander ;
  `--modules-only` ne propose pas la migration du moteur.
- **Étape 4 : sous-étape « couche moteur »** — invoque `ensure-deps.sh --migrate-engine` et relaie
  sa sortie ; le skill n'invoque jamais l'installeur amont directement (Iron Law 2).
- **§Garde-fous réécrit** : la phrase plaçant la chaîne d'outils interne hors périmètre était
  devenue fausse pour le moteur GSD (sa version est un plafond décidé par VibeFlow dans
  `ensure-deps.sh:166`) — remplacée par une frontière qui couvre le plugin, ses modules et l'état
  du moteur GSD (détecté et proposé, jamais installé sans accord), Superpowers restant
  explicitement hors périmètre. Renvoi vers `docs/ADR.md` ADR-058, qui acte ce changement de
  doctrine.

Référence : `docs/ADR.md` ADR-058, `.planning/phases/VFDO-19-migration-du-moteur-gsd-pilot-e-par-vf-update/`.

## [v1.15.0] — 2026-07-27 (lint du contenu de `tools:`, Phase 16)

### Ajouté
- **`check-agents.sh` lint désormais le contenu du champ `tools:`** (et `disallowedTools:`),
  jusqu'ici jamais lu au-delà du frontmatter :
  - **syntaxe** des spécificateurs `Outil(...)` — parenthèses équilibrées (non fermée **et**
    fermante en trop, libellés distincts), allowlist vide `Agent()`, entrée vide (`a,,b` et
    `Agent(a,,b)`), charset, espace avant la parenthèse — pour `Agent(` comme pour l'alias legacy
    `Task(` et pour `Bash(` ;
  - **noms d'outils** validés contre le set fermé documenté : warning par défaut, **erreur en
    `--strict`** ;
  - **existence des noms d'agents** en allowlist, par **résolution graduée** anti-faux-positif :
    types natifs et préfixes tiers reconnus (défaut `gsd-`), noms non résolus en **warning même
    sous `--strict`**, erreur **seulement** sous le mode opt-in `--resolve-agents=strict` ;
  - nouveaux flags : `--third-party-prefix=PFX` (accumulatif), `--no-third-party-prefix`,
    `--resolve-agents=lenient|strict` (valeur invalide rejetée, pas de dégradation silencieuse),
    `--agent-registry-dir=PATH` (répétable) ;
  - **ferme la dette** « `--strict` sans périmètre tiers » (66 faux positifs constatés sur un
    scope user) : un fichier agent dont le `name` matche un préfixe tiers n'est plus linté pour la
    charte VibeFlow.
- Tokenizer robuste : split à **profondeur de parenthèses** (plus de coupure naïve sur `,`), 
  dé-quotage des scalaires, tolérance des lignes vides dans une liste bloc YAML (deux
  faux-bloquants corrigés en cours de phase).
- **Limite de portée documentée** : la liste de noms entre parenthèses est **ignorée par le
  runtime** pour un agent dispatché en sous-agent — elle n'est appliquée qu'en incarnation
  fenêtre principale (`claude --agent`). Ce lint fait donc de l'allowlist un **contrat
  documenté désormais enforcé**, pas un bac à sable runtime ; le garant machine de « un seul
  manager actif » reste le verrou de driver (`references/team-kernel.md`).

### Tests
- `test-check-agents.sh` **38 → 58 axes**.

## [v1.14.6] — 2026-07-27

### Corrigé
- `references/team-kernel.md` et `README.md` : formulation du cloisonnement manager→manager
  rendue exacte — la garantie qu'un seul manager pilote une mission est portée par le **verrou
  de driver** (refus de seconde acquisition), pas par une lecture du contenu du champ `tools:`
  des agents que `check-agents.sh` ne valide pas (il ne linte que le frontmatter). Table
  « Implémentations » du team-kernel mise à jour pour refléter les étages croisés dev ↔ design
  livrés en Phase 15 (dev-orchestrator v2.4.0, design-orchestrator v1.3.0).

### Ajouté
- `scripts/tests/test-dag.sh` : T12 — DAG hétérogène cross-métier (nœud design dans une
  frontière dev, ids namespacés, deux juges en parallèle dans la même frontière). Aucun script
  du kernel (`dag.sh`, `driver-lock.sh`) modifié.

## [v1.14.5] — 2026-07-27

### Corrigé
- `driver-lock.sh` : course ABA dans la récupération de lock périmé (violation de l'invariant H1, T13.1 rouge en CI avec 2 « recovered »). Entre le verdict « périmé » d'un concurrent et son `mv`, un autre pouvait récupérer PUIS recréer un lock frais — le `mv` réussissait alors sur ce lock vivant et le volait. Le récupérateur re-vérifie désormais le heartbeat du méta DÉPLACÉ : frais → remise en place + `race-during-recovery`. Fenêtre résiduelle théorique documentée (détectée par le heartbeat du propriétaire déposédé).

## [v1.14.4] — 2026-07-27

### Corrigé
- `driver-lock.sh` : le fallback mtime testait `stat -f %m` (BSD) avant `stat -c %Y` (GNU). Sur Linux, `stat -f` = mode *filesystem* : il imprime un bloc multi-lignes puis échoue, la substitution capturait bloc + fallback → heartbeat non numérique → un lock au meta vide restait « frais éternel » (T12.1/T12.2/T13.1 rouges en CI). Ordre inversé : GNU d'abord, BSD échoue proprement sur `-c`. Reproduit sous ubuntu:24.04.

## [v1.14.3] — 2026-07-27

### Corrigé
- `guard-agent-write.sh` : sous Linux (TMPDIR non défini + `set -u`), un `$TMPDIR` non échappé dans un commentaire du bloc python — chaîne bash double-quotée — avortait TOUTE la commande : le guard devenait muet (fail-open) et ne déniait plus jamais un agent non conforme. Reproduit sous ubuntu:24.04 (T11 de test-check-agents), commentaire reformulé sans dollar nu.

## [v1.14.2] — 2026-07-26

### Ajouté
- `check-overlaps.sh` (ADR-057) : 3 nouvelles paires documentées dans la table des
  recouvrements connus — `consolidator × gsd-mempalace-capture`, `consolidator ×
  gsd-mempalace-recall` (consolidator = canon mémoire de lab, in-repo) et `vibeflow-dev ×
  gsd-next` (vibeflow-dev = front door unique du lab, agent routeur). Tests T15/T16 ajoutés en
  couverture (Phase 11, vague 11-03).

## [v1.14.1] — 2026-07-26

### Corrigé
- Recettes UAT sur labs vierges : `vibeflow-install` retiré du frontmatter (commande plugin, pas skill de lab) ; `check-agents.sh` résout les skills déclarés aussi par leur frontmatter `name:` ; `framework-version.sh stamp` retombe sur `.vibeflow-installed` en lab isolé ; vf-new-lab — cascade de résolution des scripts prescrite, Phase 7 express explicite, chemin `.claude/memory/` écrit, ordonnancement Gate C ↔ fabrication de fond spécifié, marqueur `[DÉRIVÉ — à affiner]` verbatim.

## [v1.14.0] — 2026-07-25

### Ajouté
- Team-kernel : `dag.sh` + `driver-lock.sh` extraits du dev-orchestrator en socle transverse (`references/team-kernel.md`, contrat universel manager/workers/juges). Mode **lab express** ≤ 15 min dans vf-new-lab (3 questions, [DÉRIVÉ] assumé, Gate C intact, dette d'express). ADR-057 : détecteur `check-overlaps.sh` des recouvrements avec les briques tierces (advisory, 7 paires, 14 tests).

## [v1.13.0] — 2026-07-25

### Ajouté
- Gouvernance proportionnée au profil : en profil léger, le registre EVALS n'est plus posé à l'init (créé à la première éval réelle) — gates A/B/C intacts. Références basculées sur le modèle agentique (gsd-progress, gsd-new-project…).

## [v1.12.3] — 2026-07-25

### Corrigé
- Gates `check-agents.sh` / `check-debug-research.sh` : mode `--strict` — cible vide → exit 3 (indéterminé ≠ conforme, F13), opt-out `--allow-empty` ; défauts et câblages hook inchangés.

## [v1.12.2] — 2026-07-25 (gabarit de description sur les trois verbes)

### Corrigé
- **`vf-calibrate` / `vf-update` / `vf-new-lab`** alignés sur le gabarit de description issu de
  l'étape 12 (contre-exemples nommant les verbes voisins + portée d'invocation). Sans eux, ces
  trois verbes restaient hors du dispositif de démarcation : `vf-calibrate` et `vf-update`
  revendiquaient tous deux littéralement « mets à jour VibeFlow », sans rien pour les départager
  au déclenchement. La frontière est désormais explicite — `vf-update` **installe** la nouvelle
  version, `vf-calibrate` **réaligne la structure du lab** une fois celle-ci posée.
- Collisions également démarquées vers l'extérieur du module : `/vf-new-lab` ↔ `/vf-init`
  (dossier de code) et `/vf-new-lab` ↔ `/vf-planning` (socle documentaire).

## [v1.12.1] — 2026-07-23 (portabilité Windows — ADR-054)

### Corrigé
- **`check-plugin-update.sh`** : strip du `\r` sur la capture de version installée (python/claude
  natifs Windows émettent du CRLF) — un CR brut non échappé aurait produit un cache JSON invalide
  et tué le bandeau update SessionStart sur les postes Windows.
- **`framework-version.sh`** : `norm()` retire tout `\r` résiduel + wrapper `jqx` sur le call site —
  sous un jq Windows natif (sorties CRLF en mode texte), `drift` comparait `"2.27.1\r"` à `"2.27.1"`
  et signalait un écart en continu (faux RETARD structurel).
- **`vf-calibrate` / `vf-new-lab` (SKILL.md)** : mentions de scripts au nom nu ou au préfixe
  incohérent (3 formes différentes pour `framework-version.sh` dans le même document) → chemins
  qualifiés au point d'usage (`.claude/scripts/…`, `${CLAUDE_PLUGIN_ROOT}/_internal/…`). Un nom nu
  force l'exécutant à deviner parmi ~10 dossiers `scripts/` (bug d'install vécu, ADR-054).
- **Hooks python3 (2e rapport terrain Windows)** : résolution d'interpréteur par CHEMIN (rejet du
  stub Microsoft Store `WindowsApps`, repli `python`, zéro spawn ajouté) dans `guard-agent-write.sh`,
  `check-agents.sh`, `check-debug-research.sh`, `update-banner.sh`, `check-plugin-update.sh` — le
  stub passe `command -v python3` : les gardes étaient inertes en paraissant installées (ADR-054).

## [v1.12.0] — 2026-07-22 (détection de migration legacy, scope-aware)

### Ajouté
- **`check-legacy.sh`** : préflight scope-aware qui détecte si un lab est sur l'ANCIENNE méthode
  (pré ADR-052/053). Inspecte **les deux** racines (`$HOME/.claude` = user, `./.claude` = projet/local,
  ID4) et, par module concerné installé, signale `legacy` (version < minimum : dev-orchestrator v1.7.0,
  consolidator v1.5.0) ou `drift` (version OK mais artefacts manquants). Sortie humaine (nudge) ou
  `--print` JSON. Exit 0 toujours (informatif). 8 tests.
- **`update-banner.sh`** (hook SessionStart) étendu : fusionne en **un seul** `systemMessage` le nudge de
  mise à jour du plugin ET le nudge de méthode legacy (via `check-legacy.sh`). Un lab déjà à la bonne
  version de plugin mais aux modules non migrés est désormais détecté au démarrage. Boucle fermée : un
  `drift` détecté est réparé par `/vf-update` (`sync_module_governance` re-copie les artefacts).

## [v1.11.3] — 2026-07-20 (audit robustesse hooks — 2e vague, gate agents fiabilisé)

### Corrigé
- **`check-agents.sh` (parseur YAML minimal → 2 faux positifs bloquants + 1 contournement)** :
  scalaires quotés (`name: "x"`, parfois OBLIGATOIRES en YAML) rejetés « invalide » → déquotage ;
  `description:` en plain scalar multi-ligne perdue (« champ requis manquant ») → typage différé ;
  `skills:` en chaîne plate (`skills: a, b`) sautait silencieusement TOUT le gate anti-hallucination
  même en `--strict` → normalisation en liste. BOM UTF-8 toléré (`utf-8-sig`).
- **`guard-agent-write.sh`** : anti-trappe fail-closed — un crash interne du checker (rc≠0 SANS
  diagnostic ✗) produisait un deny générique sur un agent conforme → désormais fail-open ;
  portée restreinte au LAB COURANT (en install user-scope, un agent perso `~/.claude/agents` ou
  un autre projet n'est plus soumis à la doctrine du lab) avec `realpath` des deux côtés
  (piège symlink macOS /var→/private/var) ; `--skills-dir` dérivé du lab CIBLE du file_path
  (verdict indépendant du CWD du hook) ; limites assumées documentées en tête.
- **`check-debug-research.sh`** : filet de signature resserré — `crash-free` (KPI mobile) et
  `diagnos` isolé (« Diagnostique la santé du funnel », « pass/fail + diagnostic ») ne sont plus
  du dépannage (`diagnos` exige une co-occurrence bug/erreur/panne) ; la brique livrée
  `vf-test-runner` (mobile-test-team) n'est plus flaguée à chaque SessionStart.
- `check-plugin-update.sh` : verrou mkdir (stale 300s) contre les instances parallèles, bornes
  réseau `http.lowSpeedLimit/Time` (TCP qui rampe > 1 min sinon), écriture du cache atomique.

### Tests
- `test-check-agents.sh` 14 → 20 (quotes, multi-ligne, skills chaîne + --strict, BOM, crash
  checker → fail-open, hors-lab → allow) ; `test-check-debug-research.sh` 9 → 12 (crash-free,
  diagnostic métier, dogfood briques mobile-test-team contre le linter livré).

## [v1.11.2] — 2026-07-20 (audit robustesse hooks)

### Corrigé
- **`update-banner.sh` : le rafraîchissement du cache était MORT sur macOS** — `setsid` n'existe
  pas sur macOS et son échec (127) en arrière-plan est asynchrone : le pattern
  `( setsid … & ) || fallback` sortait toujours 0 → le fallback ne se déclenchait jamais → cache
  jamais rafraîchi (démontré : cache local figé au 12/07). Désormais : `command -v setsid` testé
  AVANT, stdin fermé (`</dev/null`). Vérifié e2e : cache réécrit avec données fraîches.
- `check-plugin-update.sh` : `GIT_TERMINAL_PROMPT=0` sur le `ls-remote` — un repo privé sans
  credential helper échoue proprement au lieu de pendre sur un prompt en tâche de fond.
- `guard-agent-write.sh` : préfiltre pur-bash avant python3 (~6ms vs ~90ms sur tout Write sans
  rapport avec `.claude/` — le hook tourne sur CHAQUE Write du lab ; surensemble strict justifié
  en commentaire) ; frontière de chemin exacte (`my.claude/agents` ne matche plus — même classe
  de faux positif que consolidator CSL-12) + `normpath`.

## [v1.11.1] — 2026-07-19 (ADR-051)

### Ajouté
- **`check-agents.sh`** : `vf-mcp-consumer` ajouté au set `KNOWN` des champs frontmatter reconnus —
  le flag qui marque un agent exécutant recevant l'allowlist MCP dérivée du lab (ADR-051) n'est plus
  signalé « champ inconnu ». Le sélecteur `vf-mcp-consumer` EST le point d'enforcement de l'injection
  (data-driven, aucun nom d'agent en dur).
- **`skills/vf-calibrate`** : étape « ré-affirmer l'allowlist MCP » — quand le `./.mcp.json` du lab
  gagne/perd un serveur **sans** bump de module, re-jouer `inject-mcp-tools.sh` (agents flaggés +
  `gsd-executor`). Rappel du redémarrage de session requis.

## [v1.11.0] — 2026-07-16 (ADR-048 — orchestrateur métier systématique)

### Ajouté
- `vf-new-lab` Phase 7 **point 5bis** : dès **≥2 agents métier**, pose d'office un **orchestrateur métier**
  (copie verbatim du skill `metier-orchestration` + instanciation de `orchestrator-template.md` parametré
  au métier). Seuil < 2 → pas d'orchestrateur ; métier = code → rôle tenu par `dev-orchestrator` (pas de doublon).
- `references/bootstrap-method.md` : règle de dérivation « ≥2 agents → orchestrateur métier » + exemple mis à jour.

### Corrigé
- Renvoi circulaire : les bundles pointaient « l'orchestration » vers le conductor, qui ne fait pas le travail
  métier. L'orchestration métier est désormais portée par l'orchestrateur métier posé ; le conductor reste méta.

## [v1.10.0] — 2026-07-11 (ADR-047 — skill-creator dans la baseline)

### Ajouté
- `module.json` : **`skill-creator` ajouté aux `requires`**. C'est l'outil que `vf-new-lab` invoque
  en Phase 5 (fan-out `subagent_type: skill-creator`) et que le Gate C exige pour créer un skill
  manquant. Il est le **canal unique de création de skills** (« Sole authorized channel for skill
  creation ») — donc une **dépendance dure** du conductor, au même titre que `validator`. Comme le
  conductor est `mandatory`, `skill-creator` est désormais **posé d'office à chaque install** (sa
  fermeture transitive est tirée par `--with-deps`), avant toute création de lab.

### Corrigé
- Régression silencieuse : `vf-new-lab` fanned out vers un `subagent_type: skill-creator` **jamais
  installé** (absent de `requires` ET de la liste « Typiquement » de la Phase 7). Les skills du lab
  étaient donc soit non fabriqués, soit rédigés à la main hors pipeline (perte de l'eval/qualité).
- `vf-new-lab` Phase 7 (point 2) : `skill-creator` ajouté à la liste des modules typiques + garde-fou
  explicite « jamais rédiger un skill à la main — canal unique skill-creator, même pour une procédure
  interne ». `installer/SKILL.md` : récap d'exemple de la fermeture du conductor mis à jour.

## [v1.9.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Lint `scripts/check-debug-research.sh`** : gate déterministe de la présence d'une phase de
  recherche documentaire avant debug dans les briques de dépannage d'un lab (ADR-045). Même contrat
  que `check-agents.sh` : `--strict` / `--hook` / `--file`, symboles `✓ ✗ ⚠`, exit 0/1, fail-open
  si `python3` absent. Consommé par le `vibeflow-validator` en Phase 2 et branché en advisory
  SessionStart (`--hook || true`) dans `hooks/hooks.json`.
- Suite de tests `scripts/tests/test-check-debug-research.sh` (9 cas, tous verts).

## [v1.8.2] — 2026-07-07

### Corrigé
- Engine d'update (`vibeflow-update.sh`) : `update --all` (donc `/vf-update`) **garantit
  désormais la baseline obligatoire** (INST-02a). Un module `mandatory` publié après la
  configuration d'un lab — typiquement `conductor` lui-même sur un lab antérieur à v2.13.0 —
  était **ignoré à vie** : `update --all` n'itérait que sur le registre `.vibeflow-installed`,
  donc ni les scripts ni les hooks du module manquant n'étaient posés. Conséquence directe :
  le **bandeau de mise à jour** (`update-banner.sh`, SessionStart) ne pouvait jamais s'afficher.
  Nouvelle fonction `ensure_mandatory_baseline` : installe la fermeture transitive des modules
  `mandatory` absents (data-driven via `module.json`, **aucun nom de module en dur**).

### Durci
- `update <module>` sur un module **déjà à jour** re-synchronise désormais sa gouvernance
  (re-pose les scripts + re-merge les hooks, idempotent) au lieu de sortir tôt (`return 0`) —
  `/vf-update` devient auto-réparateur si un `hooks.json` a dérivé sans bump de `VERSION`.
- Tests : `test-vf-update.sh` couvre la baseline `mandatory` (module absent rattrapé + closure)
  et la resync gouvernance (hook re-mergé à version inchangée). Extraction DRY de
  `copy_module_scripts` (partagée entre install et resync).

## [v1.8.1] — 2026-07-07

### Corrigé
- Skill `vf-update` : la couche plugin utilise désormais l'**identifiant complet**
  `claude plugin update vibeflow@vibeflow-os` (le nom nu peut échouer par « Plugin not found »
  quand le cache de catalogue est périmé) + parade documentée (`marketplace update` / purge du
  `plugin-catalog-cache.json`). Constaté en conditions réelles lors du premier update 2.4.1 → 2.19.0.

## [v1.8.0] — 2026-07-07

### Ajouté
- **Mise à jour du plugin en un geste** — commande `/vf-update` + skill `vf-update`.
  - `check-plugin-update.sh` — compare la version installée (`installed_plugins.json`) au **dernier
    tag GitHub** (`git ls-remote --tags`, source de vérité depuis la discipline de tags), écrit un
    cache `~/.cache/vibeflow/update-check.json`.
  - `update-banner.sh` — hook **SessionStart** : signale « mise à jour disponible X → Y, lance
    /vf-update » depuis le cache, puis rafraîchit le cache en tâche de fond. Câblé dans `hooks.json`.
  - `vf-update-run.sh` — re-matérialise les modules installés depuis le **cache le plus récent**
    (localisé lui-même, car la session courante garde l'ancien `${CLAUDE_PLUGIN_ROOT}`).
  - Le skill orchestre les **deux couches** sous confirmation (ADR-031) : `claude plugin update
    vibeflow` (marketplace) puis engine `update --all` (modules), + rappel de redémarrage.
  - Tests : `test-vf-update.sh` (bandeau + sélection semver du cache) — 4/4.

## [v1.7.0] — 2026-07-07

### Ajouté
- Convention **`vf-internal: true`** (Pattern 12) : un worker interne le déclare dans son frontmatter.
  - `generate-agent-commands.sh` — le sweep **saute** ces agents : aucune commande d'incarnation
    `/<worker>` exposée à l'utilisateur (un worker dispatché uniquement par un orchestrateur n'a
    pas à être invocable en direct). Le mode `--agent` explicite reste inchangé.
  - `check-agents.sh` — `vf-internal` ajouté aux champs connus (plus de warning « champ inconnu »).

## [v1.6.0] — 2026-07-05 (ADR-044 — agents natifs machine-enforced)

### Ajouté
- `check-agents.sh` — lint machine de la conformité NATIVE des agents (.claude/agents/*.md) :
  frontmatter présent, name/description/model/memory requis, enums valides (référentiel doc
  officielle 2026-07-05), skills déclarés EXISTANTS (--strict), champs inconnus signalés (typos),
  BUDGET DE PRÉCHARGEMENT (skills: injecte le SKILL.md entier au startup — warn > 200L/skill,
  erreur > 1200L cumulées VF_PRELOAD_MAX, erreur si disable-model-invocation, warn si context:fork).
- `guard-agent-write.sh` — hook PreToolUse(Write) : un agent non natif ne peut plus être ÉCRIT
  dans .claude/agents/ (deny avec erreurs précises + squelette canonique).
- `hooks/hooks.json` — guard Write + check-agents SessionStart posés automatiquement à l'install.
- vf-new-lab Phase 7 : squelette frontmatter canonique OBLIGATOIRE (point 5) + règle de chargement
  du contexte (précharger ≤ 200L systématiques, on-demand sinon) + format de retour standard et
  pont d'escalade C4 dans le body de chaque agent + **Gate C étendu** (check-agents --strict).

### Décision
- contracts.md n'est PAS posé à l'init (pas un mécanisme runtime — sa valeur, format de retour +
  escalade, vit dans le body des agents et pointe vers conductor-references/contracts.md).

### Tests
- `test-check-agents.sh` (14 : lint 10 + guard 4).


## [v1.5.0] — 2026-07-04 (ADR-043)

### Ajouté
- vf-new-lab Phase 7 **GATE C — Conformité machine (BLOQUANT)** : l'init ne se conclut pas sans
  `check-registres.sh --strict` exit 0 + hooks de gouvernance présents dans settings.json.
- Phase 7 point 4 : après pose des registres, indexation par la machine
  (`reindex.sh --all --apply`) — jamais d'index rédigé à la main.

### Modifié
- Canon DECISIONS.md/DEC-XXX (references/contracts.md).

## v1.3.0 — 2026-06-24

`vf-new-lab` évolue en **Lab Factory clarification-first** (pipeline 7 phases). L'init ne pose plus un
squelette : elle clarifie en profondeur (gate machine-enforced), dérive un manifeste de capacités, et
**fabrique** les skills + auditeurs. Rétrocompatible (toujours invocable « crée un lab »), profondeur
adaptative au profil.

### Ajouté
- **Clarification-first** : Phase Triage (greenfield/brownfield + profil adaptatif) → Scan brownfield
  (explorer) → élicitation section par section avec **menu numéroté** (pattern BMAD) → **Gate A**
  (`[À CLARIFIER]` bloquant sur `LAB_BRIEF.md`). Refs `elicitation-methods.md` + `completeness-gate.md`.
- **T2 — Manifeste de capacités** : dérive les capacités (savoir/compétence/procédure), **Gate B**
  (justification obligatoire), proportionnalité au profil. Ref `capability-manifest.md` +
  `scripts/proportion-capabilities.sh` (tests 9/9).
- **T3 — Fan-out skill-creator** : fabrication parallèle (N × skill-creator, un par capacité P0) +
  anti-slop (gate capacité + eval par skill + critique de complétude). Ref `skill-fanout.md`.
- **T4 — Ficelage auditeurs** : un auditeur par procédure générative via `audit-architecture` (verdict
  bloquant). Ref `procedure-audit-wiring.md`.
- **T5 — Assemblage** : agents câblés sur les skills fabriqués, planning v2 compartiments, 5 registres
  (dont EVALS), garde-fous, stamp. Récap adaptatif (pédagogique en mode découverte).

## v1.2.0 — 2026-06-23

Câblage de la **topologie à compartiments** (planning-core v2.0.0) dans l'init, l'update et le pipeline.

### Ajouté / Modifié
- `vf-new-lab` : étape de dérivation « topologie du lab » (mono-objectif vs compartiments) + typage
  `deliverable`/`continuous`/infra + seuil d'autonomie ; scaffolding *steering lab + INDEX + plan par
  compartiment qualifié*. Garde-fou « jamais un `.planning/` par compartiment systématique ».
- `vf-calibrate` : cas **planning v2** (breaking-doctrine) routé vers la recette de migration sans perte.
- `references/migration-playbook.md` : recette **§2bis migration planning v2 sans perte de données**
  (détection de dette → typage → récupération de l'existant en `_archive/` → désengorgement mémoire → INDEX).
- `references/conductor-pipeline.md` : étape compartiments + garde-fou transverse.

## v1.1.0 — 2026-06-11

`vf-new-lab` rendu **bundle-aware** + correction d'un pointeur cassé.

### Corrigé
- Pointeur cassé : `vf-new-lab` référençait `references/bootstrap-method.md` (introuvable au runtime
  car le skill et les references s'installent à des emplacements distincts) → pointe désormais vers
  `.claude/agents/conductor-references/bootstrap-method.md` (emplacement réel d'install).

### Ajouté
- Mode bundle métier : si un bundle est installé (`docs/<metier>-bundle/`), `vf-new-lab` lit son
  `content/BUNDLE.md` et **instancie** les blueprints `content/agents/*.blueprint.md` au lieu de
  dériver de zéro — le châssis conforme est déjà porté par le bundle. Compatible business-pilot /
  content / growth.

## v1.0.0 — 2026-06-11

Release initiale. Agent méta orchestrateur central + gardien du framework, distribué dans chaque lab.
Comble 4 trous identifiés à l'audit du plugin (cf. README).

### Ajouté
- **Agent `vibeflow-conductor`** (AGENT.md, ≤250L) — porte d'entrée méta pour configurer/vérifier/
  mettre à jour/migrer un lab. Route et délègue (installeur, validator, planning-core, consolidator).
  4 rôles : configurateur / vérificateur / calibreur / gardien. N'est pas appelé en continu.
- **C2 — `vf-new-lab`** : bootstrap de lab **universel** (non-dev en première classe). Cadrage 5
  questions (ce que l'utilisateur sait déjà) → dérivation → scaffolding adapté au métier. Exemple
  « acquisition » de bout en bout. Ne présume jamais dev.
- **C3 — `vf-calibrate`** + `scripts/framework-version.sh` : propagation d'update façon GSD.
  Détection de drift framework ↔ lab (current/recorded/stamp/drift, sémver portable), migration sous
  validation humaine, surfaçage SessionStart **opt-in**. + tests (8/8 PASS).
- **C4 — `references/contracts.md`** : protocole d'escalade sous-agents → conductor (gardien central).
- Références on-demand : `conductor-pipeline.md`, `migration-playbook.md`, `bootstrap-method.md`.

### Notes
- `type: agent + skills + scripts + references`. `requires: [planning-core, validator]`.
- Respecte ADR-031 (détecter/proposer, jamais corriger/migrer sans validation humaine), ADR-029
  (densité), ADR-030 (skills natifs, déléguer sans réimplémenter).
- Ne fait JAMAIS le travail métier — il configure et garde le lab.
