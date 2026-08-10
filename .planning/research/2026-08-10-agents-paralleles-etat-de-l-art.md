# État de l'art 2025-2026 — Gestion d'agents de codage en parallèle (worktrees et alternatives)

**Date :** 2026-08-10 · **Méthode :** 3 recherches web parallèles (outils worktree-based /
isolations alternatives / patterns de gouvernance), sources primaires vérifiées (docs officielles,
repos GitHub). **Consommateur :** cadrage et plan de la Phase 28, et — plus tard — la phase de
ré-armement quand `open-gsd/gsd-core#3302` sera levée.

> **Statut des faits.** Tout ce qui suit est mesuré sur le web le 2026-08-10, pas sur ce repo.
> Les faits *plateforme Claude Code* (clés de settings de plugin, `userConfig`, `.worktreeinclude`)
> sont à re-vérifier contre la doc au moment de l'usage — la plateforme bouge vite.

---

## Volet A — Orchestrateurs worktree-based : qui fait quoi

Marché consolidé en 2026 : Vibe Kanban (27,7 k★) en sunset, Crystal déprécié (fév. 2026,
successeur : Nimbalyst), deux gagnants OSS : **Gastown** (Steve Yegge, 17,5 k★) et **worktrunk**
(6,4 k★). Claude Code a un support worktree **natif** (`--worktree`, `isolation: worktree`,
`.worktreeinclude`, sweep de cleanup).

| Outil | Traction | Retour vers main | Préconditions dans le worktree |
|---|---|---|---|
| **Gastown** (steveyegge/gastown) | 17,5 k★, Go, très actif | **Merge queue Bors-style** (« Refinery ») : batch + gates machine + bisection du MR fautif ; « polecats never push directly to main » | `gt install` + config par rig |
| **worktrunk** (max-sixty) | 6,4 k★, Rust, actif | `wt merge` : squash → rebase sur main → **fast-forward** → cleanup | `.config/worktrunk.toml` : hooks pre/post-merge, post-start, **copie des caches de build** entre worktrees |
| **claude-squad** (smtg-ai) | 8,3 k★, Go | Push branche, **l'humain merge** | `~/.claude-squad/config.json` — pas de copie de fichiers (point faible connu) |
| **emdash** (generalaction) | 5,4 k★, TS/Electron | PR + CI + merge depuis l'app, humain déclenche | Setup par provider |
| **vibe-kanban** (BloopAI) | 27,7 k★, sunset | PR GitHub, humain merge | Setup script + dev server script par projet ; **GC des worktrees orphelins/expirés intégré** |
| **Conductor** (conductor.build) | closed source, actif | Revue diff puis PR, humain merge | **`.conductor/settings.toml` committé** : `scripts.setup` (`cp "$CONDUCTOR_ROOT_PATH/.env" .env`), `scripts.run`, `scripts.archive`, ports allotis (`CONDUCTOR_PORT`+9), `run_mode = nonconcurrent` pour ressources partagées |
| **ccmanager** (kbwo) | 1,2 k★, TS | Merge depuis la TUI, humain | Hooks post-création + **copie des données de session Claude Code entre worktrees** |
| **gwq** (d-kuro) | 461★, Go | Aucun — hors périmètre de l'outil | **`copy_files = [".env"]` + `setup_commands`** par repo |
| **uzi** (devflowinc) | 581★, quasi mort | `uzi checkpoint` = rebase dans la branche courante | `uzi.yaml` : `devCommand` + `portRange` (plafond implicite de concurrence) |
| **para** (2mawi2) | 19★ | `para finish` → branche locale pour revue humaine | Serveur **MCP** pour qu'un Claude orchestrateur pilote les sessions |
| **Sculptor** (Imbue) | 213★ + app | Merge local ou PR, humain ; **Pairing Mode** (sync bidirectionnelle worktree ↔ checkout local) | devcontainer + **copie du `settings.json` Claude Code local dans le conteneur** |

**Support natif Claude Code** (`code.claude.com/docs/en/worktrees`) — les faits qui comptent pour VibeFlow :

- `worktree.baseRef` : **défaut `"fresh"`** (branche par défaut du remote, fetch cappé à 5 s,
  fallback HEAD local) ou `"head"`. **Le réglage est un tuning avec défaut sûr, pas une
  précondition nue** — c'est le design que l'incident #38 avait inversé.
- **`.worktreeinclude`** (racine du repo, syntaxe `.gitignore`) : copie automatique des fichiers
  gitignorés matchés (`.env`, secrets) dans chaque worktree créé — **versionné, donc distribué**.
- `isolation: worktree` (subagents) : worktree temporaire, supprimé automatiquement s'il est sans
  changements.
- Stabilité native : `git worktree lock` posé pendant qu'un agent tourne ; le sweep périodique
  (`cleanupPeriodDays`) **skip s'il reste du travail** et libère les locks des process morts
  (v2.1.210+) — jamais les locks posés à la main. Enforcement machine de l'isolation (blocage des
  Edit/Write/Bash et redirections git vers le checkout principal).
- **Le merge-back n'est PAS prescrit par la plateforme** — la doc s'arrête à `gh pr create`.
  Le trou de `open-gsd/gsd-core#3302` (retour des commits d'un worker isolé) est un trou de
  l'industrie entière, pas une spécificité GSD.

## Volet B — Isolations alternatives aux worktrees

| Approche | Représentants | Retour du travail | Préconditions |
|---|---|---|---|
| **Conteneur + branche git** | dagger/container-use (4 k★, activité en baisse) | Le plus contrôlé du marché : `diff` → `merge` (historique conservé) ou `apply` (stage, l'humain committe) — gaté humain | Base image + setup commands |
| **Conteneur devcontainer** | Référence anthropics/claude-code `.devcontainer` | Aucun mécanisme propre (l'agent push) | **Versionnées dans le repo** (Dockerfile + devcontainer.json) + firewall default-deny `init-firewall.sh` |
| **Sandbox OS sans conteneur** | anthropic-experimental/sandbox-runtime (4,9 k★, très actif ; `/sandbox` natif depuis v1.0.29) | Sans objet (travaille dans le vrai répertoire) | **Zéro** — mais aucune isolation entre agents |
| **microVM / sandbox cloud** | E2B (Firecracker), Daytona (OCI), Morph Infinibranch (fork de VM < 250 ms) | À la charge de l'orchestrateur (git push avec token injecté) | Templates/snapshots d'images |
| **Cloud-VM produits finis** | Copilot coding agent, Codex cloud, Claude Code web, Jules, Devin | **Branche poussée + PR, systématiquement. Jamais de merge auto.** | Copilot : `copilot-setup-steps.yml` **versionné** ; Jules : Environment Snapshots ; Devin : blockdiff (snapshot 20 GB en ~200 ms) ; Codex : setup avec réseau puis phase agent offline, secrets purgés |
| **Clone `--shared`/hardlink** | Pattern (fletch.sh), micro-outils anecdotiques | git push standard | Comme worktree (rien) |
| **FS overlay CoW** | Turso AgentFS (3,3 k★, FUSE + SQLite) | Delta inspectable/rejouable, pas de flux git natif | Sans objet |

**L'argument anti-worktree à connaître** (fletch.sh, « Git worktrees are not an isolation
boundary ») : les worktrees partagent UN `.git` — hooks, `config`, `refs/stash` communs ; un hook
installé par un agent depuis son worktree s'exécute dans le repo parent au prochain commit humain ;
un `gc`/`reset --hard` d'un agent affecte tous les worktrees. Benchmark (repo git/git) : worktree
826 ms vs clone `--shared` 870 ms, surcoût disque nul (objectstore partagé). **Le clone isole refs,
config, stash et hooks pour ~5 % de temps en plus.** Le worktree est un mécanisme de
parallélisation, pas une frontière d'isolation.

## Volet C — Patterns de gouvernance : « ce qui est armé est opérant chez l'utilisateur »

Les 7 patterns dominants, avec leurs exemplaires :

1. **Safe default + fallback gracieux, jamais de précondition nue.** Le réglage distribué est un
   tuning d'une capacité qui fonctionne sans lui (`worktree.baseRef: "fresh"` + fetch cappé +
   fallback). Une capacité qui *exige* un réglage nu est mal conçue pour la distribution.
2. **Préconditions déclaratives collectées à l'activation.** `userConfig` de `plugin.json`
   (Claude Code : prompt à l'activation, `required: true`, `sensitive` → keychain, substitution
   `${user_config.KEY}`, env `CLAUDE_PLUGIN_OPTION_<KEY>`) ; `setup_url` des GitHub Apps ;
   walkthroughs VS Code avec `completionEvents` ; `inputs.required` des GitHub Actions.
3. **Armed-off by default.** La capacité risquée s'installe désarmée (`defaultEnabled: false`,
   flags `CLAUDE_CODE_EXPERIMENTAL_*`) ; l'utilisateur arme explicitement.
4. **Doctor/preflight de première classe.** `flutter doctor`, `claude doctor`, `doctor
   check`/`repair` (mcp_agent_mail, locks orphelins), `ruflo verify` (readiness gradée avant de
   lancer le swarm). = le patron `ensure-*.sh` de VibeFlow, validé par le marché.
5. **Fail-fast surfacé, jamais silencieux.** Précondition absente = erreur nommée dans un endroit
   visible (onglet Errors de `/plugin`, exit 1). L'anti-pattern exact : la clé inconnue
   « silently ignored ».
6. **Concurrence par isolation d'abord, locks advisory ensuite.** Un périmètre de fichiers par
   agent ; claiming de tâches sous file-lock (agent-teams natif) ; leases TTL **renouvelables**
   (3600 s typique) avec staleness multi-signaux (heartbeat + activité fs/git) et libération
   automatique des locks de process morts. Jamais de TTL court sans renouvellement (cf. incident
   driver-lock 2026-08-02).
7. **CI = preuve d'installation « as-installed ».** Tester l'artefact final publié dans un
   environnement vierge, jamais l'arbre source : autopkgtest Debian (le pattern nommé de
   référence), smoke tests Docker d'artefact, `claude plugin validate --strict` (documenté pour la
   CI), **`--plugin-url` sur un zip d'artefact de CI** (le chaînon « installe le publié et vérifie »).

**Fait plateforme décisif pour la Phase 28** : le `settings.json` embarqué d'un plugin Claude Code
ne supporte que les clés `agent` et `subagentStatusLine` — **toute autre clé est ignorée en
silence**. Un plugin ne peut donc PAS distribuer `worktree.baseRef` (ni aucun réglage arbitraire)
par ce canal : le trou de #38 est structurel à la plateforme, pas seulement à l'engine VibeFlow.
Le véhicule officiel est `userConfig` (pattern 2) — et depuis v2.1.207, les `pluginConfigs` posés
dans le settings *projet* sont ignorés (un repo cloné ne doit pas injecter de config).

Complément Anthropic (multi-agent research system + best practices) : orchestrateur-workers 3-5
subagents, exécution synchrone assumée ; « agents are stateful and errors compound » → checkpoints
+ reprise au point d'échec ; « give Claude a check it can run » ; revue adversariale en subagent
frais ; un périmètre de fichiers par teammate.

---

## Implications pour VibeFlow

### 1. Le cadrage de la Phase 28 est confirmé par le marché, décision par décision

| Décision du cadrage | Pattern de marché qui la valide |
|---|---|
| D-01 (déclaré + liste close) | Préconditions déclaratives (pattern 2) + refus de l'heuristique |
| D-02 (bloque, `ensure-*` vaut preuve) | Doctor/preflight (pattern 4) + fail-fast surfacé (pattern 5) |
| D-02 (pas de véhicule de settings dans l'engine) | **Confirmé par la plateforme** : il n'en existe pas non plus côté plugin (clés ignorées en silence) |
| D-04 (le gate voit ce que l'install pose) | « As-installed testing » (pattern 7, autopkgtest) |
| D-06 (discriminance rejouée sur #38) | « Give Claude a check it can run » / smoke test d'artefact |
| Hors périmètre : ré-armement verrouillé | **Aucun outil sérieux du marché ne merge le travail d'un agent sans gate** — humain, PR ou merge queue gatée machine |

### 2. Faits neufs à porter au plan de la Phase 28

- Nommer le pattern dans l'en-tête du gate : *as-installed testing* (D-04).
- Options d'outillage CI à évaluer au plan : `claude plugin validate --strict` ; `--plugin-url`
  sur l'artefact zip pour tester **le publié**, pas l'arbre.
- Distinction à instruire au plan (D-01/D-02) : **précondition dure** vs **tuning à défaut sûr**.
  Un armement dont la précondition a un défaut sûr documenté n'est pas le même risque qu'une
  précondition nue. Le natif fait cette distinction (`baseRef: "fresh"`).

### 3. Dossier pour le futur ré-armement (fermé jusqu'à `open-gsd/gsd-core#3302` — ne rien rouvrir ici)

Le jour où la question du retour des commits se rouvre, le marché offre trois modèles éprouvés,
du plus simple au plus automatisé :

1. **Branche livrée + merge humain** (claude-squad, para, doc native) — zéro mécanique nouvelle.
2. **Merge local outillé** : squash → rebase sur main → fast-forward + cleanup (worktrunk
   `wt merge`, Crystal). La mécanique la plus répandue ; historique linéaire, 1 mandat = 1 commit.
3. **Merge queue gatée machine** (Gastown « Refinery ») : batch + gates + bisection — jamais de
   push direct sur main par un worker.

Et pour les préconditions des worktrees : **`.worktreeinclude`** (versionné, natif) +
`userConfig` de `plugin.json` (collecte à l'activation) sont les deux véhicules distributifs qui
n'existaient pas quand la Phase 27 a armé. À re-mesurer le moment venu.

Alternative d'isolation à réévaluer le moment venu : le **clone `--shared`** (mêmes perfs, `.git`
indépendant, ferme les canaux de contamination hooks/config/stash) — et container-use si un flux
`merge`/`apply` gaté est voulu.

---

**Sources principales** : docs officielles Claude Code (worktrees, plugins, plugins-reference,
agent-teams, best-practices) · gastown · worktrunk · claude-squad · vibe-kanban · crystal/Nimbalyst
· emdash · Conductor (docs scripts) · ccmanager · gwq · uzi · para · Sculptor/Imbue ·
dagger/container-use · anthropic-experimental/sandbox-runtime · anthropics/claude-code
`.devcontainer` · fletch.sh (worktrees vs clones) · Turso AgentFS · E2B/Daytona/Morph · GitHub
Copilot coding agent (`copilot-setup-steps.yml`, firewall) · OpenAI Codex cloud (security) · Jules
· Devin (blockdiff) · Anthropic multi-agent research system · autopkgtest ·
Dicklesworthstone/claude_code_agent_farm · mcp_agent_mail · ruvnet/ruflo.
