# Étude à la source : DietrichGebert/ponytail

Étude faite le 10/10/2026 sur un clone `--depth 50` (HEAD `9cc65d0`, v5.1.0, 08/10/2026), dans `scratchpad/repos/ponytail`. Aucun script du dépôt n'a été exécuté. Les chemins `fichier:ligne` renvoient à ce clone.

Légende : **[lu]** = constaté dans le dépôt ou une source primaire ; **[déduit]** = mon interprétation.

---

## 1. Identité

| Élément | Valeur | Source |
|---|---|---|
| URL | https://github.com/DietrichGebert/ponytail | |
| Auteur | Dietrich Gebert (`DietrichGebert`) ; nouveaux skills réservés à l'auteur (« New skills come from me », `.github/CONTRIBUTING.md:5-7`) | [lu] |
| Licence | MIT (`LICENSE`, API GitHub `license: MIT`) | [lu] |
| Accroche | « Makes your AI agent think like the laziest senior dev in the room. The best code is the code you never wrote. » | API GitHub [lu] |
| Création | 12/06/2026 00:52 UTC (« Initial commit », dernier élément de la pagination de l'API) | [lu] |
| Dernier push | 08/10/2026 16:19 UTC (release v5.1.0) | [lu] |
| Commits | 315 sur la branche par défaut (pagination `per_page=1`, dernière page = 315) | API, [lu] |
| Contributeurs | 110 (contributors, anonymes compris) ; sur les 50 derniers commits : 19 de l'auteur, 31 de 30 contributeurs externes différents | API + `git log`, [lu] |
| Rythme | v4.12.0 le 05/10, v4.13.0 le 05/10, v5.0.0 et v5.1.0 le 08/10 ; environ 30 PR externes fusionnées le seul 05/10 (corrections d'adaptateurs : hooks Windows, Qoder, pi, Hermes, désinstallation) | `git log`, [lu] |
| Étoiles | **159 666**, forks **8 589**, 44 issues ouvertes (API GitHub au 10/10/2026) | **vérifié** via `gh api` |
| Étoiles (agrégateurs) | « over 82,000 GitHub stars since its June 12 release » (InfoQ, 05/08/2026) | **chiffre d'agrégateur**, cohérent avec une croissance continue mais non vérifiable à cette date |
| Distribution | Plugin Claude Code (`.claude-plugin/`), npm `@dietrichgebert/ponytail`, plus des adaptateurs pour une vingtaine d'agents (Codex, Cursor, Copilot, Gemini, OpenCode, Kiro, Windsurf, Cline, Qoder, Hermes, pi, Kimi, Grok…), voir `docs/agent-portability.md:9-43` | [lu] |
| Sponsor / commercial | Sponsor GreenPT (`README.md:182-191`), bannière de liste d'attente « Something's coming » vers ponytail.dev/soon (`README.md:49-51`) | [lu] ; [déduit] un produit commercial se prépare autour |

Pas de CHANGELOG dans le dépôt : l'historique passe par les releases GitHub et les messages de commit.

---

## 2. Architecture

Point central, dit par l'auteur lui-même : « Ponytail is one prompt: `skills/ponytail/SKILL.md`. [...] Everything else in this repo loads that prompt into different agents. » (`README.md:122`). Le cœur fait 3 492 octets (environ 850 tokens) [lu, taille mesurée ; conversion en tokens déduite].

### 2.1 Skills (`skills/*/SKILL.md`)

| Skill | Rôle | Déclenchement |
|---|---|---|
| `skills/ponytail/SKILL.md` | Le « mode senior paresseux » : échelle de décision, règles, niveaux lite / full / ultra | Injecté **automatiquement** par le hook SessionStart (voir 2.3) ; aussi auto-invocable par sa description (« Use on any coding task… », `SKILL.md:3-8`) et `/ponytail [lite\|full\|ultra]` |
| `skills/ponytail-review/SKILL.md` | Revue d'un diff : bug, risque, charge, test manquant, vitesse, « lean » | Manuel `/ponytail-review [cible]` ou description (« review this », « is this over-engineered », `:3-8`). Rapport seul, ne modifie rien (`:101`) |
| `skills/ponytail-audit/SKILL.md` | Même grille sur tout le dépôt, cartographie d'abord, 20 constats maximum | Manuel `/ponytail-audit` ou description (« audit this codebase », « what can I delete », `:3-8`) |
| `skills/ponytail-debt/SKILL.md` | Récolte les commentaires `shortcut:` en registre de dette, marque `no-trigger` ceux sans condition de révision | Manuel `/ponytail-debt [mot]` |
| `skills/ponytail-gain/SKILL.md` | Affiche le tableau des gains du benchmark en barres ASCII | Manuel `/ponytail-gain` |
| `skills/ponytail-help/SKILL.md` | Carte de référence | Manuel `/ponytail-help` |

### 2.2 Agents

**Aucun agent / sous-agent** n'est défini dans le dépôt [lu : pas de dossier `agents/`]. En revanche le hook `SubagentStart` injecte le ruleset dans chaque sous-agent lancé (voir 2.3).

### 2.3 Hooks (Claude Code et Codex : `hooks/claude-codex-hooks.json`, référencé par `.claude-plugin/plugin.json:9`)

| Événement | Script | Rôle |
|---|---|---|
| `SessionStart` (matcher `startup\|resume\|clear\|compact`) | `hooks/ponytail-activate.js` | Écrit le fichier drapeau du mode (`setMode`), émet le corps de `SKILL.md` filtré au niveau actif comme contexte caché (`:59-60`), **ajoute une carte du code** (`:62-67`), propose une fois la configuration de la statusline (`:69-163`) |
| `SubagentStart` | `hooks/ponytail-subagent.js` | Injecte le même ruleset dans chaque sous-agent, car « SessionStart context is parent-thread only and never reaches subagents » (`:4-6`). Filtrable par regex `PONYTAIL_SUBAGENT_MATCHER` (`:8-11`) |
| `UserPromptSubmit` | `hooks/ponytail-mode-tracker.js` | Détecte `/ponytail lite\|full\|ultra\|off\|default <mode>`, « stop ponytail », « normal mode » et met à jour le drapeau (`:45-130`) |

Modules partagés :
- `hooks/ponytail-instructions.js` : lit `SKILL.md`, retire le frontmatter et les lignes de niveau non actives (`filterSkillBodyForMode`, `:11-41`) ; secours codé en dur identique à `AGENTS.md` si le fichier est illisible (`:43-75`).
- `hooks/ponytail-map.js` : **carte du code** injectée au démarrage. Liste les fonctions, classes et exports de premier niveau, une ligne par dossier, budget 2 000 caractères (`PONYTAIL_MAP_CHARS`), regex par langage, sans dépendance ; tests, build, vendored exclus ; dossiers « partagés » (util, lib, service, component, hook…) en premier (`:16-21`, `:70-99`). En-tête injecté : « Codebase map (what already exists; reuse it, read a file only when you need its details) » (`:97`). Désactivable par `PONYTAIL_MAP=0` (`ponytail-activate.js:64`).
- `hooks/ponytail-config.js` : mode par défaut, résolution env `PONYTAIL_DEFAULT_MODE` > `~/.config/ponytail/config.json` > `full` (`:4-10`) ; désactivation seulement si le message entier est la commande (`:36-43`).
- `hooks/ponytail-runtime.js` : détection de l'hôte par variables d'environnement, format de sortie JSON propre à chaque hôte (`:104-162`), mode stocké par projet via un hash SHA-256 du `CLAUDE_PROJECT_DIR` (`:46-57`).
- `hooks/ponytail-statusline.sh` / `.ps1` : badge `[PONYTAIL]` / `[PONYTAIL:ULTRA]`.
- Autres gabarits : `cursor-hooks.json`, `copilot-hooks.json`, `qoder-hooks.json`.

### 2.4 Commandes

- `commands/*.toml` (6 fichiers) : format Gemini CLI / Qwen, réutilisé par Grok (`docs/agent-portability.md:14,23-24`). Dans Claude Code, les slash-commandes viennent des skills eux-mêmes.
- `.opencode/command/*.md` : mêmes commandes pour OpenCode.

### 2.5 Manifestes et adaptateurs

`.claude-plugin/plugin.json` (v5.1.0) et `marketplace.json`, `.codex-plugin/`, `.github/plugin/`, `.grok-plugin/`, `.kimi-plugin/`, `.qoder-plugin/`, `.devin-plugin/`, `gemini-extension.json`, `opencode.json`, `plugin.yaml` + `__init__.py` (Hermes), `pi-extension/`. Copies de règles « instruction seule » alignées sur `AGENTS.md` : `.cursor/rules/`, `.windsurf/rules/`, `.clinerules/`, `.agents/rules/`, `.qoder/rules/`, `.kiro/steering/`, `.github/copilot-instructions.md`, vérifiées par `scripts/check-rule-copies.js`. `AGENTS.md` (2 721 octets) est la version compacte pour les agents sans skills.

### 2.6 Benchmarks et tests

- `benchmarks/agentic/` (Python, `run.py`, `tasks.py` 1 544 lignes, `judge.py`, `complete.py`, `compare.py`, `answer.py`) : benchmark de référence en sessions Claude Code headless.
- `benchmarks/promptfooconfig*.yaml`, `loc.js`, `correctness.js`, `behavior.js`, `arms/` : ancien benchmark mono-coup (promptfoo), gardé pour l'historique.
- `benchmarks/results/` : 10 comptes rendus datés (12/06 → 07/10/2026).
- `tests/*.test.js` (19 fichiers) : tests des hooks, adaptateurs, désinstallation, copies de règles.
- `examples/` : 12 comparaisons avant / après issues de l'ancien benchmark (Haiku 4.5).

---

## 3. Mécanismes clés

### 3.1 L'échelle de décision (« the ladder »)

Texte exact (`skills/ponytail/SKILL.md:25-32`, identique `AGENTS.md:11-18`) : « Take the first option that fully works: »
1. « Does it need to exist? Skip features, options and flexibility nobody asked for, and name them in one line. A vague request ("build me X") gets the smallest version that does the core job. »
2. « Already in this codebase (a helper, component, service, pattern)? Use it the way the surrounding code does. »
3. « Standard library or a platform feature? Use it, unless the project has its own. A house component beats a native widget. »
4. « An installed dependency? Use it. Never add a dependency for a few lines. »
5. « Can it be one line a reader gets at a glance? One line. »
6. « Otherwise: the minimum code that works. »

Ordre effectif : **besoin → existant du dépôt → stdlib / plateforme → dépendance déjà installée → une ligne lisible → minimum neuf**. Le README illustre une variante à 7 marches où stdlib et natif sont séparés (`README.md:111`, texte alternatif de `ladder.png`) [lu : léger écart entre l'image et le prompt].

Historique utile [lu] : la marche 2 « déjà dans ce dépôt » n'existait pas au départ ; elle a été ajoutée après l'issue #217 « Missing rung », parce que les marches stdlib / plateforme / dépendance ne visent que du code **extérieur** au projet (`benchmarks/results/2026-06-22-issue-245-217-comprehension.md`, l. 1-30).

### 3.2 Lire avant de choisir une marche

- « Read the task and the code it touches. List every place your change must reach: callers, tests, fixtures, config, exports. [...] That is scope. Extra features are not. » (`skills/ponytail/SKILL.md:21`)
- « The ladder runs *after* it understands the problem, not instead of it [...] Lazy about the solution, never about reading. » (`README.md:114`)
- Bug : « before you edit, grep every caller of the function you touch, then fix the root cause once in the shared code. » (`SKILL.md:38`). Ajouté après l'issue #245 « Dangerously lazy ». Astuce de cadrage relevée par l'auteur : présenter la correction de la cause racine comme le diff **le plus petit** (« one guard there is a smaller diff than one per caller »), pour que l'instinct du skill y pousse au lieu de s'en éloigner (`results/2026-06-22-...md`).

### 3.3 Garde-fous contre la sur-application

- « Be lazy about the solution, never about the change itself: finish every part the task needs » (`SKILL.md:34`).
- « Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility, the calibration real hardware needs, anything the user asked for. » (`SKILL.md:44`)
- « A one-liner that needs decoding is not short. » (`SKILL.md:36`)
- « Between options of equal size, take the one that is correct on edge cases. » (`SKILL.md:40`)
- « Code you move or merge keeps its error handling and validation. » (`SKILL.md:39`)
- « Keep the structure the codebase already has: its layers, interfaces and conventions. » (`SKILL.md:35`)
- Test minimal obligatoire : « Lazy code without its check is unfinished: new non-trivial logic (a branch, a loop, a parser, money or security, or a whole new script or app) leaves one small test or an assert-based self-check. Trivial changes need none. » (`SKILL.md:41`)

### 3.4 Dette explicite et traçable

- « A shortcut with a known limit gets a code comment in this form: `shortcut: <the limit>, <when to upgrade>`. » (`SKILL.md:42`)
- `/ponytail-debt` les récolte et marque `no-trigger` ceux sans condition de révision : « those are the ones that silently rot » (`skills/ponytail-debt/SKILL.md:36-37`).
- La revue et l'audit ne signalent pas un raccourci marqué : « a decision, not a finding, unless the expected load already crosses it » (`ponytail-review/SKILL.md:63-64`).

### 3.5 Format de fin de réponse

« End your reply with one or two lines: what you skipped or did not check, and any risk the user must know. » (`SKILL.md:15`). D'après le benchmark, c'est la principale raison pour laquelle le juge préfère les réponses de v5 à celles de v4.13 (`results/2026-10-07-agentic.md:110-111`).

### 3.6 Niveaux

lite : « Build what was asked. Name the smaller option in one line and let the user pick. » ; full : les règles, par défaut ; ultra : « Also question the request: before building, push back on any part the need does not justify. » (`SKILL.md:48-52`). Le hook ne garde que la ligne du niveau actif (`ponytail-instructions.js:19-40`).

### 3.7 `ponytail-review` (et `ponytail-audit`)

Depuis v5, ce n'est plus seulement une chasse au code à supprimer : « `/ponytail-review` used to look only for code to cut. Now it reviews like the senior dev who gets paged when it breaks » (`README.md:98`).

- **Ordre de priorité** : « correct, safe, holds under load, tested, fast, lean » (`ponytail-review/SKILL.md:12`).
- **Comprendre d'abord** : lire le diff puis « callers of every changed function, the functions it calls, the tests, the README » ; « A change can break code it does not touch. When a signature, return value or behavior changes, grep every caller. » ; déterminer la charge attendue et « say which load you assumed » (`:21-28`).
- **Six catégories** (`:32-55`) : Bug, Risk, Scale (« check-then-write races, [...] a query per item, O(n^2) »), Missing test (« One good test, not coverage »), Speed, Lean. La partie Lean détaille delete / reuse (« the repo already has this helper (name the path) ») / stdlib-native / yagni (« abstraction with one implementation, config nobody sets ») / merge / split (« Split by job, never by line count »).
- **Filtre anti-bruit** (`:59-67`) : « Every finding needs a concrete case: "this input or situation leads to this wrong result". No case, no finding. » ; relire pour confirmer ; « Prefer fixes that delete code. Never add layers » ; « No style taste, no "consider", no vague worries. »
- **Format de sortie** (`:71-99`) : anglais très simple ; `What this change does:` ; constats numérotés sur tous les groupes (« so the user can say "fix 2 and 5" ») et répartis en **Must fix / Should fix / Nice to have** ; chaque constat a quatre parties **What this is / Problem / Fix / If we skip it** ; fin par `Verdict: Ship.` ou `Verdict: fix 1 and 3 first.`, `Lean: -<N> lines possible.`, `Not checked:`. S'il n'y a rien : « Looks good. Ship. »
- L'audit ajoute « Map first » (README, déploiement, dépendances, points d'entrée, flux de données ; « Big repo: go deep where a mistake costs the most [...] Say which parts you did not read. », `ponytail-audit/SKILL.md:16-28`), « Before calling code unused, grep the whole tree for it, including tests, fixtures, config, and string or dynamic references » (`:61-62`), 20 constats maximum, et `Lean: -<N> lines, -<M> dependencies possible.` (`:97`).

### 3.8 Honnêteté de la mesure dans le produit

`/ponytail-gain` interdit d'afficher un gain propre au dépôt : « NEVER print a per-repo savings number [...] the unbuilt version was never written, so there is no real baseline to subtract from » (`ponytail-gain/SKILL.md:44-48`).

### 3.9 Gouvernance du prompt

Toute modification du ruleset doit être accompagnée d'un benchmark à trois bras (sans skill / `main` / la branche), avec « at least one existing task it could break [...] (a new rule often fights an old one) » et au moins 6 runs par bras (`.github/CONTRIBUTING.md:9-29`). Exemple de discipline : 8 retouches du SKILL.md testées contre la faiblesse « email » sur OpenAI, aucune livrée faute d'effet (`results/2026-06-16-robustness-audit.md`, TL;DR).

### 3.10 Ce qui rend la méthode efficace [déduit]

1. **L'injection forcée** plutôt que le chargement à la demande : c'est le facteur qui compte le plus d'après JetBrains (voir §4.2).
2. **La carte du code injectée** rend la marche « existant » quasi gratuite : le modèle voit ce qui existe sans avoir à chercher.
3. **Une échelle à arrêt précoce** (« first option that fully works ») au lieu d'une liste de principes à pondérer.
4. **Des contrepoids explicites** (Never cut, test minimal, lisibilité) qui empêchent le « golf » de code.
5. **Une sortie actionnable** : numérotée, quatre parties, verdict, ce qui n'a pas été vérifié.

---

## 4. Preuves d'efficacité

### 4.1 Mesures de l'auteur [lu]

**Benchmark de référence v5** (`benchmarks/results/2026-10-07-agentic.md`) :
- Protocole : `claude -p` headless, Opus 5.5, effort par défaut, Claude Code CLI 2.1.288 ; plugin chargé par `--plugin-dir` ; 39 tâches (12 tickets dans full-stack-fastapi-template épinglé à `cd83fc1`, 18 tâches « chirurgicales » avec vérifications cachées, 9 demandes ouvertes) ; 5 runs, 585 sessions, bras entrelacés ; dossier temporaire hors git, CLAUDE.md et mémoire désactivés ; **Bash désactivé, donc aucun code exécuté par l'agent** (`:12-28`).
- Statistique : médiane des 5 runs par tâche, puis moyenne géométrique des rapports bras / référence, intervalle bootstrap à 95 %, sign test (`:30-32`).
- Résultats contre le bras sans skill : lignes -53 % [-63..-41], gzip du code -41 %, tokens de sortie -45 %, coût -26 % [-36..-16], temps -41 %, moins cher sur 30 tâches sur 38 (`:36-44`). Coût moyen par session 0,200 $ → 0,142 $ (`:55`).
- Correction : vérifications cachées 87/90 contre 86/90, donc **à égalité** ; « Less code did not cost correctness or safety. It did not add any either » (`:64-69`).
- Tests : un test présent quand la logique en demande un dans 98 % des cas contre 68 % ; bugs injectés détectés 66 % contre 46 % sur l'ensemble des cellules, **mais 69 % contre 77 % là où un test existe** : sans skill, l'agent écrit moins souvent des tests, mais ils sont meilleurs (`:87-93`).
- Réponses : le juge aveugle (Sonnet 5.5) préfère v5 à v4.13 (110 : 67, p = 0,002) mais **pas** v5 au bras sans skill (82 : 106, p = 0,09, légère préférence pour les réponses plus longues sans skill) (`:103-109`).
- Limites listées par l'auteur : un seul modèle et un seul hôte, pas d'exécution, juge = modèle, 21 tâches sur 39 sans vérification de qualité, tri des tâches « nécessitant un test » fait par l'auteur, n = 5, outils de test et de mutation pas encore publiés (`:160-171`).

**Historique des corrections** (à porter au crédit de la transparence) :
- Ancien benchmark mono-coup : « 80-94 % de code en moins ». Colin Eberhardt (CTO de Scott Logic), issue #126 du 16/06/2026, [vérifié via `gh api`] : la référence répond de façon bavarde avec plusieurs options ; un simple prompt système « Provide just one example [...] no commentary » ramène la référence de 108 à 16 lignes, contre 8,25 pour ponytail, « the central claims of this project should be a bit more modest ». L'auteur l'a reconnu (`benchmarks/README.md:67-74`).
- Run agentique du 17/06 : écart de seulement 4 %, puis **invalidé** parce que le hook SessionStart du plugin s'exécutait aussi dans le bras de référence (`benchmarks/agentic/README.md:189-194`).
- Coût : le gain est **propre à Claude**. Avec la même méthode, gpt-5.4-mini coûte 26 % de plus et gpt-5.5 39 % de plus avec ponytail, parce que le ruleset injecté et le raisonnement en plus pèsent davantage que le code économisé (`results/2026-06-17-cost-verification.md`, TL;DR).
- Petit modèle local (llama3.2 3B) : l'effet sur le nombre de lignes reste dans le bruit, et son signe change selon l'échantillon (`results/2026-06-15-llama3.2-local.md`).

### 4.2 Évaluations indépendantes

**JetBrains, Denis Shiryaev, juillet 2026** (source primaire : https://blog.jetbrains.com/ai/2026/07/ponytail-skill-claude-tested/, lue par WebFetch) :
- Version testée **v4.8.4** (commit `16f2980`), donc **antérieure** à v5 (pas de carte du code, ancienne revue).
- Claude Sonnet 5, effort moyen ; 80 tâches appariées de SkillsBench (7 sur 87 exclues) ; harnais Harbor 0.18 en conteneurs Docker avec vérificateurs.
- Code -15,4 % (**p = 0,088, non significatif au seuil de 5 %**) ; coût -10,3 % mesuré sur les tokens de sortie (**p = 0,004**) ; temps -11 %. Annoncé par ponytail à l'époque : -54 % / -20 % / -27 %.
- Gain de code de -31 % sur les grosses constructions et d'environ 0 % sur les tâches déjà minimales.
- Qualité : 9 tâches un peu moins bien, 6 un peu mieux, 65 identiques, indistinguables ; l'auteur précise que c'est un résultat nul, pas une preuve d'équivalence.
- **Constat clé** : installé comme skill passif, il s'est auto-activé « zero times » sur dix sessions. Seul le hook SessionStart produit un effet mesurable.
- L'auteur reste mesuré : test « conservative » sur le code, « does not refute their −54 % on their own task set » (SkillsBench contient peu de pièges front-end).

**Autres sources** :
- InfoQ, Steef-Jan Wiggers, 05/08/2026 (https://infoq.com/news/2026/08/ponytail-agent-skill-benchmark) : synthèse de la critique d'Eberhardt (un prompt YAGNI de sept mots battait le score d'origine) et de commentaires Hacker News (« essentially just these rules, and a metric ton of boilerplate for specific plugin systems », « the new leftpad? »). C'est un média secondaire, mais il cite des sources primaires.
- Benchmarks communautaires cités **par le dépôt** (`benchmarks/README.md:83-90`, non vérifiés ici) : KuldeepB19 (Opus 4.8, 480 builds, environ 44 % de code en moins, pas de régression, mais « trims everyday bad-input handling on 5/24 tasks ») ; RicardoCostaGit (Cursor SDK : code plus maigre mais **coût de processus plus élevé**, plus d'appels d'outils et de tokens, sur les grosses tâches où l'agent doit aller jusqu'au bout).
- Tessl, horadecodar, pasqualepillitteri, betterstack, skillselion : agrégateurs ou articles de vulgarisation ; ils n'apportent pas de mesure propre et je ne les retiens pas.

### 4.3 Robustesse de la mesure [déduit]

- **Solide** : protocole publié et rejouable, workspaces conservés (`--rescore`), selftests good / bad sur chaque instrument, référence agentique équitable depuis juin, corrections publiques des erreurs, une mesure indépendante sérieuse (JetBrains) qui confirme le **signe** de l'effet sur le coût.
- **Fragile** : l'auteur mesure sur ses propres tâches, choisies avec des pièges de sur-construction (date picker 335 → 10 lignes) qui tirent la moyenne vers le haut ; la taille de l'effet chute d'un facteur 2 à 4 sur un banc externe ; un seul modèle par run ; aucun code exécuté par l'agent ; la qualité n'est mesurée que sur 18 tâches à n = 5, donc on ne peut exclure que les grosses régressions. Les chiffres v5 n'ont **pas encore** été répliqués par un tiers.

---

## 5. Limites, risques, angles morts

1. **Sans hook, le skill ne s'active pas tout seul** [lu, JetBrains] : la description « Use on any coding task » ne suffit pas, il faut l'injection SessionStart. Sur les hôtes qui se limitent aux instructions, le ruleset est permanent, sans niveaux.
2. **Coût en tokens permanent** [lu + déduit] : environ 850 tokens de ruleset plus jusqu'à 2 000 caractères de carte (environ 500 tokens) à chaque démarrage, reprise, `/clear` et compaction, **et dans chaque sous-agent** (`SubagentStart` sans filtre par défaut). Le cache de prompt amortit en partie. Sur des modèles de raisonnement non Claude, le coût net devient négatif (+26 % à +39 %, résultats de l'auteur).
3. **Coût de processus** : davantage d'appels d'outils sur les grosses tâches où l'agent doit aller jusqu'au bout (RicardoCostaGit, issue #121 citée dans `benchmarks/README.md:110`). Le ruleset est réinjecté et l'échelle délibère à chaque tour.
4. **Sur-application** : retrait de la gestion d'entrées invalides ordinaires sur 5 tâches sur 24 (KuldeepB19, selon le dépôt) ; avec stdlib-first, les modèles OpenAI choisissent `email.utils.parseaddr`, un parseur et non un validateur, qui accepte `@missing-local.com` (`results/2026-06-16-robustness-audit.md`). Le « Never cut » réduit ce risque sans le supprimer.
5. **Tests moins bons quand ils existent** : 69 % des bugs injectés détectés contre 77 % sans skill (`results/2026-10-07-agentic.md:90`). La règle « one small test » privilégie la présence du test sur sa profondeur.
6. **Les réponses ne sont pas meilleures pour un humain** que sans skill (82 : 106, non significatif, légère préférence pour l'absence de skill).
7. **Conflits avec d'autres skills ou instructions** [déduit] : le persona « lazy senior dev » injecté partout, y compris dans les sous-agents spécialisés (revue, planification, design), peut contredire des workflows qui demandent de l'exhaustivité (couverture de tests, plans détaillés, documentation). La seule protection est la regex opt-in `PONYTAIL_SUBAGENT_MATCHER`. Les commentaires `shortcut:` peuvent aussi heurter une convention de projet (FAQ, `README.md:170-171`).
8. **Incohérences internes à la v5** [lu] : `commands/ponytail-help.toml` et `commands/ponytail.toml` décrivent encore l'ancienne échelle (« YAGNI then stdlib then native then one line », sans la marche « existant ») et l'ancienne revue (« over-engineering review ») ; l'image du README a 7 marches et le prompt 6. Les adaptateurs Gemini, Qwen et Grok reçoivent donc un texte en partie périmé.
9. **Carte du code approximative** : « regex, not a parser. Misses nested or dynamic definitions » (`hooks/ponytail-map.js:9-10`) ; budget de 2 000 caractères, avec des dossiers omis sur un gros dépôt ; mêmes fichiers exclus que les tests.
10. **Dépendance à la plateforme** : les gains publiés valent pour Claude dans Claude Code. Une grande partie du code sert à contourner les particularités de chaque hôte (Windows et stdin bloqué #443/#790, JSON de sortie différent par hôte, Cursor qui ne peut pas désactiver une règle) : la maintenance est lourde pour un prompt de 50 lignes.
11. **Popularité et preuve ne vont pas ensemble** [déduit] : 160 000 étoiles en 4 mois pour un prompt d'environ 50 lignes, avec un marketing fort (chiffres en tête du README, bannière commerciale). Il faut s'en tenir aux chiffres indépendants (-10 % de coût, -15 % de code non significatif sur v4.8.4).

---

## 6. Mécanismes empruntables (formulés indépendamment du dépôt)

1. **Échelle de réutilisation à arrêt précoce.** Avant d'écrire, parcourir dans l'ordre : est-ce nécessaire ? existe-t-il déjà dans le projet ? dans la bibliothèque standard ou la plateforme ? dans une dépendance déjà installée ? peut-on l'écrire en une ligne lisible ? Sinon, écrire le minimum. S'arrêter à la première option qui marche entièrement.
   Source : « Take the first option that fully works » (`skills/ponytail/SKILL.md:25-32`).

2. **Inventaire de l'existant injecté au démarrage.** Fournir automatiquement une carte compacte et bornée (noms exportés par dossier, modules partagés en premier) pour que « réutiliser » ne demande pas de recherche.
   Source : « Codebase map (what already exists; reuse it, read a file only when you need its details) » (`hooks/ponytail-map.js:97`, budget `:16`).

3. **Contrepoids non négociables à toute règle de sobriété.** Accompagner chaque consigne « moins de code » d'une liste fermée de choses qu'on ne supprime jamais : validation aux frontières de confiance, gestion d'erreur contre la perte de données, sécurité, accessibilité, ce qui a été demandé.
   Source : « Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility [...] anything the user asked for. » (`SKILL.md:44`).

4. **Présenter la bonne pratique comme l'option la plus économe.** Pour orienter un agent poussé vers la sobriété, montrer que la correction à la cause racine est le plus petit diff (une garde dans la fonction partagée plutôt qu'une par appelant).
   Source : `SKILL.md:38` et `benchmarks/results/2026-06-22-issue-245-217-comprehension.md` (« one guard there is a smaller diff than one per caller »).

5. **Dette explicite avec plafond et condition de révision, puis récolte.** Tout raccourci volontaire porte un marqueur `<limite>, <quand revoir>` ; un outil les collecte et signale ceux qui n'ont pas de condition de révision. Une revue ne remonte pas un raccourci marqué tant que la limite n'est pas atteinte.
   Source : `SKILL.md:42`, `skills/ponytail-debt/SKILL.md:36-37`, `ponytail-review/SKILL.md:63-64`.

6. **Pas de constat sans cas concret.** Une revue n'émet un constat que si elle peut nommer l'entrée ou la situation qui produit le mauvais résultat, et pas de « consider », de goût stylistique ni d'inquiétude vague.
   Source : « No case, no finding. » ; « No style taste, no "consider", no vague worries. » (`ponytail-review/SKILL.md:59-67`).

7. **Format de constat en quatre temps, numéroté, avec verdict.** Ce que c'est / le problème / la correction / ce qui arrive si on ne fait rien ; trois niveaux de priorité ; numérotation continue pour pouvoir dire « corrige 2 et 5 » ; verdict sur une ligne et liste de ce qui n'a pas été vérifié.
   Source : `ponytail-review/SKILL.md:76-96`.

8. **Clôture obligatoire « sauté / non vérifié / risque ».** Toute réponse finit par une ou deux lignes sur ce qui a été omis ou non vérifié et le risque à connaître. C'est le principal gain de lisibilité mesuré par le juge entre deux versions.
   Source : `SKILL.md:15` ; `results/2026-10-07-agentic.md:110-111`.

9. **Lire le périmètre réel avant d'agir.** Lister appelants, tests, fixtures, configuration et exports touchés ; en revue, relire les appelants de toute fonction dont la signature ou le comportement change ; annoncer l'hypothèse de charge retenue.
   Source : `SKILL.md:21` ; `ponytail-review/SKILL.md:21-28`.

10. **Injection forcée plutôt qu'activation espérée, y compris dans les sous-agents.** Une consigne transversale doit être injectée par un hook de démarrage de session et de sous-agent : une description de skill ne suffit pas à la déclencher.
    Source : `hooks/ponytail-subagent.js:4-6` ; JetBrains : auto-activation « zero times » sur dix sessions en skill passif.

11. **Toute modification d'une consigne passe par un A/B à trois bras.** Sans consigne / version actuelle / version modifiée, sur une tâche que le changement doit améliorer et une qu'il pourrait casser, avec n ≥ 6. Si rien ne bouge, on ne livre pas.
    Source : `.github/CONTRIBUTING.md:16-29` ; `results/2026-06-16-robustness-audit.md` (8 retouches testées, aucune livrée).

---

## Sources

- Dépôt : https://github.com/DietrichGebert/ponytail (clone du 10/10/2026, HEAD `9cc65d0`)
- API GitHub (`gh api repos/DietrichGebert/ponytail`, commits, contributors, releases, issue #126)
- JetBrains AI Blog, Denis Shiryaev, juillet 2026 : https://blog.jetbrains.com/ai/2026/07/ponytail-skill-claude-tested/
- InfoQ, Steef-Jan Wiggers, 05/08/2026 : https://infoq.com/news/2026/08/ponytail-agent-skill-benchmark
- Issue #126, Colin Eberhardt, 16/06/2026 : https://github.com/DietrichGebert/ponytail/issues/126
- Cités par le dépôt, non vérifiés : https://kuldeepb19.github.io/ponytail-benchmark/ , https://github.com/RicardoCostaGit/ponytail-benchmark-from-cursor
