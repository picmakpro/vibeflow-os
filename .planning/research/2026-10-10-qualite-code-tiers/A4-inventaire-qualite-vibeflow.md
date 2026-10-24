# VibeFlow et la qualité du code produit par les agents : inventaire vérifié

Dépôt lu : `le dépôt `vibeflow-os`` (VERSION racine `v2.69.0`), en lecture seule, le 2026-10-10.
Tous les chemins sont relatifs à la racine du dépôt sauf mention contraire. Les agents amont GSD sont lus
dans `~/.claude/agents/` et `~/.claude/gsd-core/` (moteur `@opengsd/gsd-core`, hors dépôt).

Point de méthode à garder en tête pour toute comparaison : VibeFlow ne contient **presque aucune
logique de revue propre**. Ses agents routent et délèguent (Iron Law « ne réimplémente pas »,
`plugin/dev-orchestrator/agents/vf-coder.md:15-16`, `vf-reviewer.md:30-40`). Ce qui juge réellement le
code est l'agent amont `gsd-code-reviewer`. L'apport VibeFlow est l'**orchestration** de la revue
(quand, combien de fois, sur quel diff, quel format de retour, quel budget), pas le contenu de la grille.

---

## 1. La chaîne de revue

### 1.1 Qui fait quoi

| Maillon | Rôle | Preuve |
|---|---|---|
| `vf-dev-manager` | pose un nœud `revue-N` **systématiquement** après chaque `exec-N`, dispatche la revue en direct, pilote la boucle de correction | `plugin/dev-orchestrator/agents/vf-dev-manager.md:128-148` ; `references/mission-flow.md:279-292` |
| `vf-reviewer` (sonnet, effort high, lecture seule) | dispatche deux fois `gsd-code-reviewer` en parallèle (axe Standards, axe Spec), agrège, déduplique par axe, rend un bloc typé | `agents/vf-reviewer.md:1-12`, `:32-40`, `:68-77` |
| `gsd-code-reviewer` (amont) | la vraie grille : bugs, sécurité, qualité ; écrit `REVIEW.md` | `~/.claude/agents/gsd-code-reviewer.md:57-66` |
| `vf-auditer` (sonnet, lecture seule) | audit sécurité et dette, seulement si l'étape touche sécurité, données ou infra ; délègue à `gsd-security-auditor`, recoupe `CONCERNS.md` et le threat model | `agents/vf-auditer.md:17-31` ; `vf-dev-manager.md:141` |
| `vf-coder` | reçoit les findings en **mandat de correction ciblée**, jamais un cycle complet | `vf-coder.md:46-50` ; `mission-flow.md:302-303` |
| `gsd-code-fixer` (amont) | présent **uniquement** dans l'allowlist de `vf-coder` (`vf-coder.md:4`) ; aucune doctrine VibeFlow ne le cite ni ne décrit quand l'utiliser (seule autre occurrence : `references/gsd-capabilities-index.md:214`). Délégation déclarée, pas câblée. |
| Hook `code-review` du moteur | revue amont insérée par `gsd-execute-phase` et `gsd-quick` à la clôture d'un plan, si `workflow.code_review` est actif ; **objet disjoint** du nœud `revue-N` (diff d'un plan vs diff d'étape) | `docs/ADR.md` ADR-061, Couple 1 (l. ~1198-1214) ; `~/.claude/gsd-core/workflows/quick.md:563-598` |

Le juge est cloisonné : `disallowedTools: Write, Edit` (`vf-reviewer.md:5`, `vf-auditer.md:5`), avec
l'aveu écrit que le canal `Bash` reste capable d'écrire et que c'est un engagement de prompt
(`vf-reviewer.md:44-49`).

### 1.2 Ce que la grille amont cherche réellement

`~/.claude/agents/gsd-code-reviewer.md` :
- Posture adversariale explicite : « Assume every submitted implementation contains defects », liste des
  façons de « go soft » (`:23-31`).
- Périmètre : Bugs (logique, null, off-by-one, branches mortes), Sécurité (injection, secrets, authz,
  désérialisation), Code Quality (code mort, imports inutilisés, nommage, complexité cyclomatique,
  duplication, magic numbers, code commenté) (`:57-63`).
- **Hors périmètre v1 : performance** (`:65`, répété `:386`).
- Profondeurs `quick | standard | deep` (`:69-100`) ; heuristiques standard : fonction > 50 lignes, nesting
  > 4 niveaux (`:219-221`) ; deep : graphe d'imports, chaînes d'appel, propagation d'erreurs, mutations
  d'état partagé (`:228-235`).
- Sévérités Critical / Warning / Info (`:240-264`), chaque finding avec `file`, `line`, `issue`, `fix`
  (`:266-270`) ; « DO use line numbers » (`:380`).
- Règle qui bride le volet maintenabilité : « DO NOT flag style preferences as warnings. Only flag issues
  that cause or risk bugs » (`:374`). La duplication et le code mort sont classés **Info** (`:258-264`).
- Peut recevoir un bloc `<structural_findings>` (fallow : exports inutilisés, blocs dupliqués, cycles)
  traité comme vérité de terrain (`:19`).

### 1.3 Format des findings et verdict VibeFlow

- Bloc typé de worker (ADR-053) : `statut` ∈ `passed | gaps_found | human_needed | blocked`, findings
  `{severity: bloquant|majeur|mineur, action: auto-fix|no-op|ask-user, ref: fichier:ligne}`
  (`references/mission-flow.md:212-236`).
- Deux axes (POCK-04) : `axes.standards` et `axes.spec`, chacun avec son statut ; un finding Spec cite
  `{PLAN}:{ligne}` (`references/mission-contracts.md:354-371` ; `vf-reviewer.md:70-77`).
- Seuil d'un axe : `passed` si aucun bloquant ni majeur ; un mineur ne relance jamais la boucle seul
  (`mission-contracts.md:373-375`, P414-D-20).
- Conjonction : global `passed` ssi tous les axes jugés sont `passed` ; axe Spec `skipped` sans PLAN ;
  PLAN attendu mais absent = `blocked` (`mission-contracts.md:377-394`).
- Champ `preuves` (E6) : triplet `{verdict, commande, exit_code, sha}` seulement si le juge a lui-même
  exécuté ; sinon `"preuve": "amont"`, jamais d'exit code inventé (`vf-reviewer.md:79-87`).
- Champ `confiance` optionnel : un `passed` de jugement avec `confiance < 0.6` est requalifié en
  `gaps_found` + `ask-user` (`mission-contracts.md:262-290`).
- Vérification outillée optionnelle (iOS) : `clean` avant tout `build_sim`/`test_sim`, paramètres
  explicites (`vf-reviewer.md:51-66`).

**Écart non documenté** : la grille amont classe en Critical/Warning/Info, VibeFlow en
bloquant/majeur/mineur. Aucune table de correspondance n'existe dans `plugin/dev-orchestrator/` (grep
« critical », « BLOCKER », « Warning » sans résultat pertinent). La conversion est laissée au modèle.

### 1.4 Nombre de tours et boucle

- Sur `gaps_found` : `dag.sh reopen` (force `review_regime=full`, machine, `plugin/conductor/scripts/dag.sh:24`, `:409`),
  correction ciblée par `vf-coder`, re-revue (`mission-flow.md:294-305`).
- **Budget 3 tours** au grain étape, **partagé** avec les autres boucles de correction (test, audit) pour
  empêcher le contournement par renommage (`mission-flow.md:309-316` ; `vf-dev-manager.md:142-144`).
- Épuisement : `blocked` + champ `decompte` (tours de revue, de comblement, findings non résolus), sans
  proposition de next step (`mission-flow.md:363-380` ; `mission-contracts.md:292-300`).
- G5, édition à la source : deux fois le même verdict sur le même objet = la source (CLAUDE.md, doctrine,
  digest, mandat) est fautive, pas le worker (`plugin/conductor/references/team-kernel.md:200-206`).
- Gradation **par risque, jamais par volume** : revue renforcée sur 4 faits (adaptateur infra non testé,
  fichier partagé avec une mission en vol, code non couvert par la mutation, geste utilisateur ou
  géométrie de vue) ; allègement réservé au domaine pur à mutation verte, à la doc, aux catalogues ;
  défaut sûr = revue pleine (`mission-flow.md:323-338`).
- Revue de **jointure** `join-N` sur l'union des diffs dès que deux `exec-*` incomparables partagent un
  descendant ; meilleur rendement mesuré (Phase 20 : 4 bloquants + 9 majeurs) (`mission-flow.md:340-353`).
- Aucun allègement sur un diff de comblement, garanti par l'outil (`mission-flow.md:355-361`).

**Constat** : les régimes « plein » / « allégé » existent comme champ de DAG, mais rien ne dit ce qui
change dans le brief donné à `gsd-code-reviewer`. `vf-reviewer.md` ne passe aucun paramètre `depth`
(seul `--depth=2` du registre d'agents, `:37`, qui est une profondeur de dispatch). La grille tourne donc
à sa profondeur par défaut (`standard`, `gsd-code-reviewer.md:108`) quel que soit le régime.

### 1.5 Relecture adverse SOBR-04, merge-danger call POCK-06, contrôle E3

- **SOBR-04** (release du plugin uniquement) : `git diff <tag précédent>..<commit de release> -- plugin/` relu
  par qui ne l'a pas écrit, au moins une sonde exécutée, commande et sortie dans les notes de release
  (`CLAUDE.md:26-27`). Non gaté par machine. Porte sur les releases de VibeFlow, pas sur le code des labs.
- **Merge-danger call** (POCK-06, emprunt Pocock) : section `## Merge-danger call` obligatoire dans le corps
  de PR d'une mission, une ligne `Porte : sens unique | double sens`, une ligne `Rayon d'explosion : …`
  (≥ 10 caractères) ; forme vérifiée, jamais la véracité (`mission-contracts.md:142-156`).
- **E3** du gate de sortie `check-mission-exit.sh` : branche dédiée + PR ouverte + merge-danger call
  conforme ; MANQUE nommé ou INDÉTERMINÉ (`references/head-governance.md:121-125` ;
  `plugin/dev-orchestrator/scripts/check-mission-exit.sh:50`, `:304`). Les autres contrôles E1-E7
  (`head-governance.md:117-130`) portent sur le verrou, l'arbre propre, STATE/ROADMAP, le rapport, les
  preuves E6, le rangement : **aucun ne porte sur le contenu du code**.
- Le head ne relit jamais un diff : il accepte un vert du manager s'il porte une preuve machine
  (`head-governance.md:108-112`).

### 1.6 Chemin court (tâche d'un commit)

`vf-coder` dispatché par le head passe par `gsd-quick --validate` : plan-checking + `gsd-verifier`,
**sans revue VibeFlow séparée** (`vf-coder.md:24-26`, `:97-98`). La seule revue de code est alors le
hook amont `code-review` de `gsd-quick`, advisory et best-effort, sauté si la capability est inactive
(`~/.claude/gsd-core/workflows/quick.md:563-567`).

---

## 2. Ce qui oriente l'écriture du code avant la revue

### 2.1 `vf-coder` et le digest

- `vf-coder` est un routeur : plan (`gsd-plan-phase`), exécution (`gsd-execute-phase`), rien d'autre
  (`vf-coder.md:38-52`). Il ne porte **aucune** consigne de style, de simplicité ou de réutilisation ; seulement
  « respecte les conventions du CLAUDE.md du projet cible » (`:76`) et « recherche doc avant debug »
  (ADR-045, `:62-67`).
- Le digest de mission est plafonné à 30 lignes, dont « Conventions cibles : 2-3 lignes du CLAUDE.md
  projet » (`mission-contracts.md:51-64`). Le dépôt l'écrit lui-même : le digest « ne peut donc
  structurellement pas porter la doctrine » (`references/GSD-PIPELINE.md:264-270`).
- Exception du manager qui remonte à l'humain même en autonome : « nouvelle dépendance majeure » et
  « suppression de code/données » (`vf-dev-manager.md:94-99`). C'est la seule règle sur les dépendances
  dans la chaîne dev, et elle est de gouvernance (escalade), pas de sobriété (pas de « préfère la stdlib »).

### 2.2 Le module `software-architecture` (la doctrine qualité de code)

`plugin/software-architecture/` (v1.6.2, `module.json`) :
- Iron Law : aucun fichier de code > 300 lignes sans plan de découpe, une responsabilité par unité,
  frontières machine-enforced (`SKILL.md:13-17`).
- Tier 1 machine : taille 250 avertit / 300 bloque, cycles d'import (madge, dependency-cruiser),
  eslint-plugin-boundaries, vérification 3 couches, TDD quand le critère est mesurable, Gate Nyquist et
  Gate Decision Coverage (`SKILL.md:38-46`).
- Tier 2 au jugement (« un principe de conception ne se compile pas ») : SOLID, Clean Architecture, DRY
  « sans fausse abstraction », **KISS / YAGNI** (« aucun code spéculatif au cas où »), Clean Code,
  anti-patterns (`SKILL.md:48-59`).
- `references/principles.md` : règle → test → signal → remède. KISS : signaux « abstraction à un seul
  usage, couche d'indirection qui n'indirige rien, généricité jamais reparamétrée », remède « supprimer
  la couche, inliner » (`:26-35`). YAGNI : « params optionnels jamais passés, interfaces à une seule
  implémentation, branches mortes », remède « supprimer » (`:37-47`). DRY : rule of three, duplication de
  savoir et non de lignes (`:19-24`).
- `references/anti-patterns.md` : god file (> 300 L, priorité taille × churn × couplage), cycles, mixing
  concerns, feature envy, filet de tests décoratif, gate fantôme (`:5-48`).
- `rules/production-code-architecture.md` : rule path-scopée (`src/`, `app/`, `lib/`, `features/`, TS/JS
  seulement, `:1-12`), Server Action 4 couches, `Result<T>`, Feature-Sliced (`:24-33`).
- Hook `PreToolUse(Edit|Write)` `guard-file-size.sh` : **deny** sur un fichier de code ≥ 300 lignes sans
  marqueur `vibeflow:allow-large-file`, fail-open sur erreur (`hooks/hooks.json:1-13` ;
  `scripts/guard-file-size.sh:2-24`) ; extensions couvertes `ts tsx js jsx mjs cjs py go rb java kt swift rs php`
  (`scripts/check-file-size.sh:27`).
- `references/restructuration-playbook.md` : refonte brownfield en vagues, filet de tests d'abord.

**Portée réelle, mesurée** :
- Le module n'est **pas** dans le preset par défaut `dev` (`plugin/_internal/presets.json:7-8`) ; il n'arrive
  qu'avec le preset `dev-audite` (`:17-20`). `dev-orchestrator` ne le requiert pas
  (`plugin/dev-orchestrator/module.json`, `requires: [conductor, design-orchestrator]`).
- Canal `agent_skills` : seul le slot `gsd-planner` est peuplé avec `software-architecture` et
  `audit-architecture`. Le dépôt écrit : « la doctrine de dev du lab atteint le plan, elle n'atteint pas
  l'exécution » (`GSD-PIPELINE.md:244-248`), et interdit de présenter le slot exécuteur comme résolu
  (`:250-262`).
- Côté revue : `gsd-code-reviewer` lit lui-même `CLAUDE.md` et les `SKILL.md` de `.claude/skills/` du projet
  (`gsd-code-reviewer.md:40-55`), donc le skill est vu en revue **si** le module est installé en scope projet.

### 2.3 Doctrine transverse (`plugin/reference/`)

- P5 « Vérifier en boucle », Iron Law no-claim-without-fresh-evidence
  (`plugin/reference/content/methodology/VIBEFLOW_CORE.md:111-121`).
- P8 « Évaluer la qualité cognitive », opérationnalisé par `audit-architecture` (`:144-160`).
- P9 « Modulariser pour la cognition » : ≤ 300 lignes par fichier de code, cible 150-200, une
  responsabilité par unité, frontières machine-enforced (`:162-179`).
- Axiomes d'enforcement : (1) enforcement > prose, (2) filet de tests fonctionnel avant tout, (3) preuve
  exécutable avant « done » (`AXIOMES-ENFORCEMENT.md:8-35`).
- Pattern 10, Adversarial Plan-Review : deux reviewers frais + juge, mais sur des **plans**, pas sur du
  code (`patterns/10-plan-review-adversarial.md:1-25`).

### 2.4 Recherche de mots-clés (corpus `plugin/`, CHANGELOG exclus)

| Mot-clé | Occurrences | Où |
|---|---|---|
| simplicité | 2 | `software-architecture` seulement |
| sur-ingénierie / overengineering | 5 | toutes sur la **méthode** (planning-core, vf-new-lab, consolidator), aucune sur le code produit |
| YAGNI | 11 | `software-architecture` + `GSD-PIPELINE.md` (qui dit que le digest ne le porte pas) |
| réutilis | 80 | aucune au sens « réutiliser l'existant avant d'écrire du code » (usages : réutiliser un script, un gabarit, un worker) |
| stdlib / bibliothèque standard | **0** | |
| code mort / dead code | 1 | un commentaire de `check-gsd-config.sh:218` sur le propre code du dépôt |
| Karpathy | **0** dans `plugin/` | |
| judo | **0** | |
| taille de fichier | 3 | `software-architecture` |
| smells / Fowler | 1 | le mot « smells » dans l'axe Standards (`mission-contracts.md:357`) ; la baseline de 12 smells de Pocock n'a pas été reprise |

### 2.5 Skills chargés par défaut

- `ensure-deps.sh` auto-installe GSD et **superpowers** (`plugin/dev-orchestrator/scripts/ensure-deps.sh:3-8`).
  Superpowers apporte `test-driven-development`, `verification-before-completion`, `requesting-code-review`,
  `systematic-debugging` ; seule la TDD est citée par la doctrine VF (`principles.md:70-72`).
- ADR-057 fixe `gsd-code-review` comme canon de revue dans un projet GSD, les autres
  (`feature-dev:code-reviewer`, `/code-review` natif, `superpowers:requesting-code-review`) étant « hors
  chaîne GSD » (`docs/ADR.md:880-881`).
- Le moteur injecte sans condition `references/tdd.md` (330 lignes) dans le prompt de l'exécuteur
  (`GSD-PIPELINE.md:277-279`) ; `workflow.tdd_mode` est volontairement non posé (`:272-290`).
- La consigne Karpathy présente sur le poste de Samuel vient de `~/.claude/CLAUDE.md` (`@KARPATHY.md`) et du
  plugin tiers `karpathy-skills`, **pas** de VibeFlow.

---

## 3. Gates machine liés à la qualité

### 3.1 Gates qui touchent le code produit dans un lab

| Gate | Nature | Couvre | Ne couvre pas |
|---|---|---|---|
| `guard-file-size.sh` (hook PreToolUse) | bloquant | taille ≥ 300 L à l'écriture | rien d'autre ; module optionnel |
| `check-file-size.sh` (CLI/pre-commit) | bloquant si câblé | taille, `--staged` / `--all` | n'est pas posé en pre-commit automatiquement |
| hook amont `code-review` (`workflow.code_review: true`) | advisory | revue LLM du plan | pas de verdict bloquant |
| hooks amont nyquist / secure (relayés dans `verdicts`) | advisory / bloquant selon config amont | couverture de tests, threat model | |
| `check-mission-exit.sh` E1-E7 | bloquant pour le head | forme de sortie de mission, preuves E6, merge-danger call | **le contenu du code** |
| `check-debug-research.sh` | lint de briques | présence de la phase recherche doc dans les skills de debug (ADR-045) | le code |

### 3.2 Gates du dépôt VibeFlow lui-même (pas du code des labs)

Job CI `gates` (`.github/workflows/ci.yml:245` et suivantes) : `check-agents --strict`, `check-skills`
(classe d'invocation POCK-07), `check-blueprints`, `check-version-sync`, `check-state-integrity`,
`check-capability-activation`, `check-machine-paths`, **`check-instruction-budget`**, `check-divergence`,
`check-planning-consumers-registered`, `check-baseline-arbitrage` (G-1), `check-gate-touche` (G-2),
`check-ajout-retrait` (consultatif), `check-affirmation-non-mesuree` (G-4), `check-push-sans-pr` (G-3),
`check-release-tag`. Ce sont des gates de **gouvernance de la méthode** (densité des prompts, traçabilité,
cohérence du planning), aucun ne lit du code applicatif.

### 3.3 Budget d'instructions

- `plugin/conductor/scripts/check-instruction-budget.sh` : par fichier d'agent, lignes (plafond ADR-029 :
  avertit dès 251, bloque > 300) et instructions du body comparées à une baseline en ratchet (`:1-35`).
  Une « instruction » = une ligne qui matche `jamais|toujours|ne .* pas|doit|must|never|always|interdit|obligatoire`
  (`:133`). SKILL.md plafonnés à 500 lignes ; bootstrap à 2 000 tokens.
- Baseline `.planning/instruction-budget-baselines.tsv` (calibrée 2026-09-16, 31 fichiers, 487 instructions).
  Sentinelle armée (`.planning/.instruction-budget-armed`).
- Mesure du jour (rejouée en lecture) : `vf-reviewer.md` 87 L, **9/9 instructions (marge 0)** ;
  `vf-coder.md` 146 L, 22/23 (marge 1) ; **`vf-dev-manager.md` 250/250 L et 46/46 instructions (marge 0,
  à une ligne de l'avertissement)** ; `vf-auditer.md` 3/3. Bootstrap 2 610 tokens, déjà
  AU-DESSUS-PLAFOND-ADR029 (non bloquant aujourd'hui, au BACKLOG `.planning/BACKLOG.md:794`).
- Toute hausse de la colonne instructions exige une citation d'arbitrage datée dans le commit (G-1,
  `CLAUDE.md:125`).

---

## 4. Emprunts déjà faits à des frameworks externes

| Source | Ce qui a été pris | Forme de l'emprunt | Dépendance au tiers |
|---|---|---|---|
| **Pocock** (`mattpocock/skills` 1.3.1, Phase 41.4, v2.69.0) | (a) frontière de questions au cadrage POCK-01 ; (b) glossaire de domaine POCK-02 ; (c) frontière de phase POCK-03 ; (d) **revue à deux axes Standards / Spec jamais re-rankés** POCK-04 ; (e) grille de tri rétro « mécanique → check, jugement → standard » POCK-05 ; (f) **merge-danger call** POCK-06 ; (g) classe user/model-invoked des skills POCK-07 ; critère de **défaillance observée** POCK-08 | doctrine transcrite dans les références existantes + gates (`check-skills.sh`, E3, `check-ajout-retrait.sh`) ; « aucun skill neuf, aucun agent neuf » (`.planning/workstreams/fiabilite/ROADMAP.md:1555`) | **aucune** : « Aucun de ces emprunts n'installe `mattpocock-skills` » (`.planning/research/2026-10-06-pocock-skills-etude.md:112`) |
| **Superpowers** | TDD (renvoi canonique), brainstorming, writing-skills, verification-before-completion | **dépendance dure** auto-installée, frontières par ADR-057 et `check-overlaps.sh` | oui, la seule ; plan de secours chiffré si rug pull (mémoire `agent-skills-ecarte-superpowers-reste`) |
| **ECC** (2026-09-25) | 6 emprunts, jalon `ecc-inspiration-v1.0`, Phases 51-56, **non exécutés** | phases inscrites | aucune |
| **agent-book** (Bojie Li, 2026-08-15) | convergences constatées (juges frais, veto de rubric, G5) ; 4 gaps listés (juges à vision, calibration, juge cross-famille, KV-cache) | rapport `reports/research/2026-08-15-ai-agent-book-alignement.md`, item BACKLOG `:183` « INVESTIGUÉ », **rien d'implémenté** | aucune |
| **ICM / Karpathy** | pattern « LLM knowledge base » (llm-wiki), pas les consignes de code de Karpathy | item BACKLOG `:204` « à investiguer » | aucune |
| **Jev / Univer** | champ `confiance` + `SEUIL_CONFIANCE = 0.6` | contrat (`mission-contracts.md:262-290`) | aucune |
| **jcode, claude-code-best-practice** | verrou de driver, isolation worktree | ADR-053, ADR-064 (« Ce qu'on emprunte, et à qui », `docs/ADR.md:1533`) | aucune |

### Doctrine d'emprunt qui en ressort (citations)

1. « Le pack ne se prend donc **jamais en bloc** : on emprunte des disciplines transcrites, pas un pipeline
   concurrent. » (`.planning/research/2026-10-06-pocock-skills-etude.md:31-32`)
2. « Le pack ne s'installe pas (un seul catalogue tiers, décision du 2026-08-28) ; on transcrit sept
   disciplines. » et « superpowers reste, aucune dépendance au plugin » (`.planning/workstreams/fiabilite/ROADMAP.md:1513-1515`, version milestone `.planning/milestones/fiabilite-v1.0-ROADMAP.md:1610-1612`)
3. Mémoire `veilles-plugins-tiers` : « un seul catalogue tiers installé reste la règle ; on transcrit des
   disciplines, on n'ajoute pas de dépendance. » Format de veille fixe : source mesurée → table
   d'équivalences → emprunts → écartés → collisions.
4. ADR-057 : « VibeFlow ne revendique jamais l'exclusivité contre une brique tierce » ; frontière
   descriptive + détecteur machine, pas de prose de préséance (`docs/ADR.md:860-870`).
5. GSD-first (mémoire `doctrine-gsd-first`) : tout ce qui recrée un second pipeline contre GSD est écarté
   (le flow idée → ship de Pocock l'a été pour ce motif, étude `:118-120`).
6. POCK-08 / SOBR-05 : un ajout de skill, gate ou règle cite une **défaillance observée** datée et dit ce
   qu'il retire (`plugin/conductor/scripts/check-ajout-retrait.sh:1-40`).

---

## 5. Contraintes structurelles pour tout ajout

1. **Budget d'instructions** : `vf-reviewer` et `vf-dev-manager` sont à marge 0 ; `vf-dev-manager` est aussi à
   250/250 lignes. Toute instruction ajoutée doit être compensée ou passer par une hausse de baseline avec
   arbitrage daté (G-1). Les tables longues se déportent en référence (précédent : la table de pilotage
   déportée de l'agent vers `mission-flow.md:240-243`, arbitrage A-4).
2. **Une seule voix** (ADR-030, ADR-057) : une règle s'écrit une fois dans sa référence, les agents y
   renvoient sans recopier (`vf-reviewer.md:77`, `mission-flow.md:240-241`).
3. **Arbitrages tracés** : canal + date dans le commit ; identifiants préfixés (`P41-D-02`) (`CLAUDE.md:66-82`).
4. **Gate-Touche** : tout commit qui touche un gate, sa suite, `ci.yml` ou un hook porte
   un trailer `Gate-Touche:` (chemin ou motif, séparateur tiret long, raison) (`CLAUDE.md:120-123`).
5. **Ajout-Retrait + défaillance observée** (SOBR-05, POCK-08) : consultatif en CI, mais signalé.
6. **QUAL-01 / ADR-074** : tout gate livré naît avec ses trois issues et sa mutation rouge prouvée, en forme
   exec (ADR-071). Surtout : **bloquant = intégrité technique uniquement ; jugement de qualité = consultatif,
   « jamais à un hook »** (`docs/ADR.md:2848-2860`). Une revue de suppression ou de sur-ingénierie relève du
   jugement, donc d'un juge et d'un manager, pas d'un deny.
7. **Modules** : chaque module a `VERSION`, `module.json`, `CHANGELOG.md`, `README.md` ; minor pour une
   capacité, patch pour un durcissement ; release = tag + release GitHub + SOBR-04 ; pas de release pour un
   changement docs/planning seul (ADR-073, `CLAUDE.md:45-52`).
8. **Profondeur de dispatch** : `Agent`/`Task` absents à la profondeur 3 (mesuré 2026-09-17). Chaîne réelle :
   head (session) → manager (1) → `vf-reviewer` (2) → `gsd-code-reviewer` (3). Un juge ajouté sous
   `vf-reviewer` est à la profondeur 3 et ne peut rien lancer ; un juge parallèle doit être dispatché par le
   manager (profondeur 2) (`mission-contracts.md:302-341` ; `team-kernel.md:37-55`).
9. **Aucun skill ni agent neuf** pour une discipline : précédent POCK-04 (« aucun agent neuf », deux briefs du
   même agent délégué, `mission-contracts.md:356`) ; critère 9 de la Phase 41.4.
10. **Agents** : `check-agents.sh --strict` (description, model, memory ; juge = `disallowedTools: Write, Edit`) ;
    worker interne = `vf-internal: true` (ADR-044, `CLAUDE.md:62-65`).
11. **ADR-031** : jamais de fix sans validation humaine ; les juges ne corrigent jamais.
12. **Mémoire `ne-pas-supprimer-pour-verdir`** : on met en conformité, on ne supprime pas pour faire passer un
    gate ; avant de déclarer un débris, lire `git log`. À articuler avec toute « revue de ce qu'on peut supprimer ».

---

## 6. Recoupements avec BACKLOG et ROADMAP en cours

**Jalon `equipe-produit-v1.0` (Phases 57-62, `.planning/workstreams/fiabilite/ROADMAP.md:1875-1999`)** :
- **Phase 60, gate architecture avant découpage** : assemble `software-architecture` + `gsd-map-codebase` /
  `gsd-graphify`, le head refuse le découpage sans `ARCHITECTURE.md` validée ; « hors périmètre : un gate
  bloquant sans halt condition » (`:1958-1969`). Recoupement direct avec toute idée « réutiliser l'existant
  avant d'écrire » (carte de l'existant au cadrage).
- **Phase 59, juge `prd-gate`** (lecture seule, rubric /100) : même patron de juge frais, sur le PRD, pas le code.
- Critère 5 du jalon : aucun agent neuf au-delà de 250 lignes (`:1905`).
- Phases 57, 58, 61, 62 : verrou, rôles, collaboration, plateforme ; aucun recoupement qualité de code.

**Jalon `ecc-inspiration-v1.0` (Phases 51-56, exécution reportée après `equipe-produit`)** :
- **Phase 52, télémétrie d'usage et coût de mission** : seule piste de **mesure** inscrite (skills, agents,
  durée, tokens si exposés). Ne mesure pas le rendement des revues.
- **Phase 53**, apprentissage adossé à l'observation : composera avec la grille POCK-05.
- **Phase 56, packs de règles par langage** (module optionnel, rules path-scopées Swift / TS, hooks Stop
  typecheck et format opt-in, opinion ECC filtrée) : recoupement direct avec des règles de code par stack.

**Compartiment `gouvernance` (Phases 45-50, Willy)** : hook central par rôle, gates d'écriture, gates de
clôture et verdicts hachés (46), agents génériques de cycle (48). Aucun ne porte sur la qualité du code
applicatif, mais 46 touche le format des verdicts.

**BACKLOG (`.planning/BACKLOG.md`)** :
- `:158` Gate machine sur l'observance de `mission-flow.md` (différé) : vérifier que les managers suivent la
  doctrine en usage réel, pas seulement qu'elle est écrite.
- `:183` Alignement agent-book (investigué) : calibration des juges (gold set, kappa > 0,7, Pass^k), juge
  cross-famille, juges à vision.
- `:421` et `:444` : budget des SKILL.md et évasion de mesure par bloc fenced.
- `:772` Revue de fond des grilles de juges business / content (différé).
- `:999` Résidus de revue de la Phase 41.3 (tour 3) ; findings M3-01 à M3-04 non résolus de la 41.4
  (`.planning/missions/2026-10-06-phase-41-4-emprunts-pocock.md`).
- `:8` Routage « crée une PR / ship » vers `gsd-ship` contre le geste équipe (lié à E3).

Aucun item du BACKLOG ni de la ROADMAP ne porte sur : réutilisation avant écriture, revue de suppression,
sur-ingénierie, refactor à comportement constant, seuils de complexité, mesure du rendement de la revue.

---

## 7. Trous constatés (vérifiés)

1. **Aucune règle « réutilise l'existant / la stdlib / le natif avant d'écrire »** dans la chaîne dev :
   0 occurrence de stdlib, aucune occurrence de « réutilis » dans ce sens. Le seul mécanisme proche est
   amont et implicite : `gsd-pattern-mapper` (toggle `workflow.pattern_mapper`, arbitré par
   `check-gsd-config.sh:339`), qui mappe un fichier neuf à son analogue le plus proche au plan.
2. **Aucune revue « ce qu'on peut supprimer »** : la grille amont classe code mort et duplication en **Info**
   (`gsd-code-reviewer.md:258-264`) ; côté VibeFlow, un mineur ne relance jamais la boucle
   (`mission-contracts.md:373-375`). Un diff sur-construit mais correct passe donc `passed`.
3. **Aucun axe sur-ingénierie dans la revue** : KISS/YAGNI vivent dans `software-architecture` Tier 2 « au
   jugement », mais aucun brief de `vf-reviewer` ne les cite, le module n'est pas dans le preset par défaut, et
   la grille amont interdit de signaler les préférences de style comme warnings (`gsd-code-reviewer.md:374`).
4. **Pas de « code judo »** (refonte qui simplifie à comportement constant) : aucun mot, aucun geste ; pas
   d'intention de routage « refactor / simplifie / nettoie » dans `intent-routing.md` (seul « relis / review /
   qualité du code » → `gsd-code-review`, `:85`). Le playbook brownfield existe mais vise la restructuration
   lourde, pas la simplification locale.
5. **Seuil de taille seulement au fichier** (300 L), optionnel. Pas de seuil de complexité, de longueur de
   fonction ou d'imbrication côté VibeFlow ; les heuristiques « > 50 lignes », « nesting > 4 » ne vivent que
   dans la profondeur `standard` amont (`gsd-code-reviewer.md:219-221`), en simple signal.
6. **Profondeur de revue non pilotée** : le régime plein / allégé n'est traduit ni en `depth` ni en brief ;
   `workflow.code_review_depth` et ses overrides par chemin (amont, `~/.claude/gsd-core/workflows/code-review.md:415-440`)
   ne sont ni posés ni cités par VibeFlow.
7. **Capacité amont « fallow » ignorée** : `code_quality.fallow.*` (exports inutilisés, duplication, cycles,
   injectés en `<structural_findings>` comme vérité de terrain) existe dans le moteur
   (`~/.claude/gsd-core/bin/shared/config-schema.manifest.json:44-47`, `workflows/code-review/steps/structural-pre-pass.md`)
   ; 0 occurrence dans `plugin/`. De plus `vf-reviewer` dispatche l'**agent** `gsd-code-reviewer` en direct,
   pas le workflow `/gsd-code-review` : le pré-passage structurel et le résolveur de profondeur ne s'appliquent
   donc pas au nœud `revue-N`.
8. **Performance hors périmètre** de la grille amont (`gsd-code-reviewer.md:65`) et aucun axe VibeFlow ne la
   reprend. Concurrence et perte de données ne sont couvertes que par la grille amont (Critical « data loss »,
   deep « shared state mutations ») et par `vf-auditer` quand l'étape est classée sécurité/données/infra.
9. **Pas de correspondance de sévérités** Critical/Warning/Info → bloquant/majeur/mineur écrite.
10. **Doctrine qui n'atteint pas l'exécution** : reconnu par le dépôt (`GSD-PIPELINE.md:247-248`, `:264-270`).
    L'exécuteur ne reçoit ni KISS, ni YAGNI, ni la règle 300 L (sauf via le hook si le module est installé).
11. **Chemin court sans revue VibeFlow** : `gsd-quick --validate` seulement, revue amont advisory et
    conditionnelle (`vf-coder.md:24-26` ; `quick.md:563-567`).
12. **`gsd-code-fixer` déclaré mais jamais câblé** (`vf-coder.md:4` seulement).
13. **Aucune mesure des gains de la revue** : seuls chiffres, le rendement de la jointure (Phase 20) et les
    décomptes de tours ; `confiance` est journalisée mais « jamais calibrée » (`mission-contracts.md:286-290`) ;
    aucun gold set ni kappa (agent-book gap 2, BACKLOG `:183`) ; la télémétrie (Phase 52) n'est pas faite.
14. **Pas de juge hétérogène** : tout est Claude (agent-book gap 3, non traité).
15. **Preuves `fichier:ligne` exigées** au format (`vf-reviewer.md:70`, `gsd-code-reviewer.md:380`), mais aucun
    contrôle machine ne vérifie qu'une `ref` pointe vers une ligne existante du diff.
16. **Baseline de smells Pocock non reprise** : l'étude la mentionne (`pocock-skills-etude.md:45`), seule la
    séparation des axes a été empruntée.
17. **Les principes de sobriété existants visent la méthode, pas le code** : ADR-076 (« un ajout, un retrait »,
    fin de geste) et `check-ajout-retrait.sh` jugent gates, ADR, règles, mémoires et SKILL.md du dépôt VibeFlow,
    jamais le code d'un lab.

---

## Annexe : fichiers clés

- `plugin/dev-orchestrator/agents/vf-reviewer.md`, `vf-auditer.md`, `vf-coder.md`, `vf-dev-manager.md`
- `plugin/dev-orchestrator/references/mission-flow.md` (Pattern C, Pattern E), `mission-contracts.md` (digest,
  isolation de branche, merge-danger, étage revue, confiance, preuves E6), `head-governance.md` (E1-E7),
  `GSD-PIPELINE.md` (§9 voie unique, §10 canal `agent_skills`), `intent-routing.md`
- `plugin/software-architecture/` (SKILL.md, references/, rules/, hooks/, scripts/)
- `plugin/reference/content/methodology/VIBEFLOW_CORE.md`, `AXIOMES-ENFORCEMENT.md`, `patterns/10-plan-review-adversarial.md`
- `plugin/conductor/scripts/check-instruction-budget.sh`, `check-ajout-retrait.sh`, `dag.sh` ; `plugin/conductor/references/team-kernel.md`
- `plugin/_internal/presets.json` ; `.planning/instruction-budget-baselines.tsv`
- `docs/ADR.md` : ADR-057, 060, 061, 074, 076 ; `CLAUDE.md`
- `.planning/research/2026-10-06-pocock-skills-etude.md`, `2026-09-25-ecc-inspiration-etude.md` ;
  `reports/research/2026-08-15-ai-agent-book-alignement.md`
- `.planning/workstreams/fiabilite/ROADMAP.md` (Phases 51-62), `.planning/BACKLOG.md`
- Amont : `~/.claude/agents/gsd-code-reviewer.md`, `~/.claude/gsd-core/workflows/code-review.md`, `quick.md`
