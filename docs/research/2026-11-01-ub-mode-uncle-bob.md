# ub-mode (Uncle Bob) et les gates de métriques déterministes — ce que VibeFlow en retient

> Note de recherche, 2026-11-01 (recherche menée le 2026-10-31), session principale (Samuel).
> Sources en fin de document. Ce n'est **pas** une décision : aucun des axes § « Ce qu'on
> retient » n'est livré — chacun attend un arbitrage (ADR-031). Le seul geste proposé est le spike
> § « Ce qui reste à mesurer », lui aussi soumis à arbitrage.
>
> **Suite directe de l'étude du 2026-10-10** (`.planning/research/2026-10-10-qualite-code-tiers-etude.md`,
> fiches QCT-01 à QCT-10, BACKLOG § « Emprunts qualité de code ») : ub-mode est une **réduction de
> pstack**, déjà lu à la source (annexe A2). Cette note ne relit pas pstack ; elle ne traite que ce
> qu'ub-mode ajoute — trois outils d'exécution — et renvoie aux fiches QCT pour tout le reste.

## Ce qu'est ub-mode

Skill d'agent publié par Robert C. Martin (`unclebob`) le 25 octobre 2026 : deux fichiers (README
de 20 lignes, SKILL.md de 152 lignes), quatre commits le jour de la création, **aucune licence**,
branche par défaut `master`. Environ 5 650 étoiles et 309 forks six jours plus tard. L'auteur le
dit « loosely based on portions of @poteto's rules (`poteto-mode` / `pstack`) », réduit, et couplé
à des outils de quality gate déterministes. Installation : copier `SKILL.md` dans
`~/.claude/skills/ub-mode/` (ou `~/.cursor/skills/`, `~/.grok/skills/`), puis invoquer `/ub-mode`.

Le skill impose à tout changement trois phases ordonnées :

1. **First Make it Work** — Laziness Protocol (une décision vit à un seul endroit ; la plus
   petite édition qui résout), Foundational Thinking (forme des données d'abord ; pas d'état
   partagé si un écrivain concurrent compte), TDD (test rouge d'abord, « if an honest test is
   impractical, do not write a bad one »), Redesign From First Principles, Attack the Premise,
   Subtract Before You Add, Outcome-Oriented Execution, Build the Lever, Architecture (domaine
   qui rend les états illégaux impossibles, validation à la frontière, discipline de types,
   idempotence, un seul écrivain par état partagé).
2. **Then Make it Right** — Fix Root Causes, unités vérifiables séquencées, Test Behavior Not
   Implementation (« if the test would still pass when every function returned nothing, throw
   it out »), puis **trois outils** : Crapper (`CRAP < 10` par fonction), Dryer (duplication
   `≥ 0.8` éliminée), Mutator (« cover the uncovered, kill the survivors, delete dead code »),
   puis Refactoring (épingler le comportement, changer la structure, prouver qu'il n'a pas bougé).
3. **Practice** — Keep a Log, Guard the Context Window, Worktree Cleanup (« uncommitted work
   waits for a decision »), Commit and Push (petits commits ordonnés : pourquoi, quoi, comment
   prouvé ; push sur la ligne principale à la fin).

Deux points d'arrêt explicites seulement : avant une nouvelle correction quand deux correctifs
partageant une prémisse ont échoué au même gate, et avant de supprimer un worktree porteur de
travail non commité.

### Les trois outils compagnons (dépôts séparés, Python, instantané sous `.metrics/`)

| Outil | Mesure | Seuil du skill | Code de sortie exploitable | Notes |
|---|---|---|---|---|
| `crapper` | CRAP = CC² × (1 − couverture)³ + CC, par fonction ; écrit `.metrics/crap.edn` | < 10 | `--threshold N` → exit 2 si le pire score dépasse N | couverture par JaCoCo / `go test -coverprofile` / LCOV ; outil de couverture absent ou tests rouges → 0 % et l'instantané s'écrit quand même ; `--changed` (ajouts et éditions git), `--no-coverage`, `--use-existing-coverage`, `--coverage-command` |
| `dryer` | similarité de Jaccard sur empreintes structurelles (noms, littéraux, locals normalisés ; appels, opérateurs, forme d'arbre conservés) ; écrit `.metrics/dry.edn` | ≥ 0,8 (défaut de l'outil : 0,82) | **aucun sur le seuil** : exit 0 après rapport, 1 usage, 2 format inconnu | `--min-lines 4`, `--min-nodes 20` ; ne compare que des formes du même langage |
| `mutator` | tués / (tués + survivants) ; écrit `.metrics/mutate/<ns>.edn` | 0 survivant | exit 0 tout tué, 2 baseline rouge, 3 survivant | exige `../crapper` en dépôt frère (noms de fonctions, commandes de couverture) ; baseline obligatoirement verte ; timeout 10× la baseline, min 2 s ; reruns **différentiels** (survivants + fonctions dont le texte a changé) ; « dead code » n'est pas défini par le README — le plus proche est « site non couvert » |

Langages des trois : Clojure, Java, Go, TypeScript/TSX/JS, Rust, Python. **Ni Swift, ni Kotlin,
ni Bash.** Un quatrième dépôt, `uml-viewer` (Clojure/Quil), lit ces instantanés pour afficher
composants, couverture, CRAP, score de mutation et sens des dépendances. **Les trois écrivent sur
disque** (`.metrics/`) : incompatibles tels quels avec un juge en lecture seule — même constat que
QCT-09 (b) sur `fallow`.

### Autour du dépôt

- **Critique déjà publiée** (Medium, fin octobre 2026 — lue via résumé de recherche seulement,
  la page rend 403) : le skill est de la prose que l'agent peut sauter ; ce qui tient, ce sont
  les outils à code de sortie. C'est l'**Axiome 1** de VibeFlow (`AXIOMES-ENFORCEMENT.md`,
  LRN-118) formulé par quelqu'un d'autre.
- **Skills tiers non officiels** qui empruntent le nom : `uncle-bob-craft` (sickn33 /
  jelome265 — Clean Code + Clean Architecture + SOLID en revue), `AmazingAng/old-coder`
  (« evidence-first »), `robert-hoffmann/uncle-bob` (Copilot, skill `ub-quality`). Aucun n'est de
  Robert C. Martin ; vérifier le propriétaire avant d'en citer un.
- **`unclebob/swarm-forge`** (~4 100 étoiles, Clojure/Babashka) : coordination de plusieurs
  agents — chaque rôle dans son worktree git et sa session tmux, handoffs durables par commits
  (`swarm_handoff.sh` / `ready_for_next.sh` / `done_with_current.sh`, daemon `handoffd`),
  `constitution.prompt` + prompt de rôle, trois articles partagés depuis `main` (`engineering`,
  `workflow`, `handoffs`) qu'un pack ne peut pas remplacer, tableau de bord opérateur pour
  approuver des gates et répondre aux clarifications. Packs `two-pack` (coder → cleaner),
  `four-pack` (specifier → coder → refactorer → architect), `six-pack`. Une règle à retenir :
  « tests should check observable runtime behavior rather than prompt wording ».

## Lien avec l'étude du 2026-10-10 — ce qui est déjà couvert, ce qui est neuf

| Élément d'ub-mode | Déjà traité le 2026-10-10 | Sort dans cette note |
|---|---|---|
| TDD, Test Behavior Not Implementation, « prefer no new test over a bad test » | pstack A2 §3.6 ; **QCT-04** (lot A : question de lecture « ce test détecterait-il un défaut plausible ? »), avec sa limite écrite : « ce défaut est trouvé par exécution, une question de lecture n'en attrapera qu'une partie » | pas de règle nouvelle ; `mutator` est le **complément d'exécution** que QCT-04 dit ne pas pouvoir fournir (§ Ce qu'on retient, axe 1) |
| Build the Lever, encoder plutôt qu'écrire, verdict lié au SHA, juge qui n'a pas écrit | pstack A2 §3.7, §6 ; équivalences §2 **convergentes** (E6, juges frais, QUAL-01) | rien à ajouter |
| Fix Root Causes, Keep a Log, Guard the Context Window, Worktree Cleanup, Commit and Push | ADR-045, rapport typé + `.planning/missions/`, POCK-03, hook Fin de geste (ADR-076), commits atomiques du moteur | rien à ajouter |
| Laziness Protocol, Subtract Before You Add, Redesign From First Principles, Attack the Premise, Architecture (idempotence, un écrivain) | **absents** de l'étude (grep A2 + étude : seul `build-the-lever` apparaît) | prose sans défaillance observée datée (POCK-08) → **réserve** (axes 5 et 6) |
| **Crapper, Dryer, Mutator** | absents : pstack n'a pas d'outil de mesure ; l'étude renvoie le défaut dominant « vérificateur incapable de rendre rouge » à « l'exécution et la mutation » (§5.4, verdict 6) et met le pré-passage mécanique en **réserve** (QCT-09 (b), `fallow`, sonde sur lab TS) | **le seul apport neuf** — axes 1 à 4, spike fusionné avec la sonde QCT-09 (b) |

Autrement dit : l'étude du 10 octobre a emprunté des **mécanismes de lecture** et a dit elle-même
ce qu'ils ne peuvent pas attraper. ub-mode apporte, pour six langages, les **mécanismes
d'exécution** correspondants — et aucun pour Bash, qui est là où vivent les défaillances observées
du dépôt (A5 : dix vérificateurs incapables de rendre rouge en Phase 39). Les outils aideraient le
code des labs, pas les gates de `vibeflow-os`.

## Pertinence pour VibeFlow — trois verdicts distincts

| Objet | Pertinence | Pourquoi |
|---|---|---|
| **Les trois outils** (crapper, dryer, mutator) | **haute**, bornée aux labs TS/Python/Go/Java/Rust/Clojure | Ils rendent *mesurables* trois jugements que `software-architecture` range aujourd'hui en Tier 2 — « au jugement, pas par un gate machine : un principe de conception ne se compile pas » (SKILL.md §Tier 2 ; `principles.md` en-tête, DD4) : complexité sous couverture, duplication structurelle, force réelle des tests. Et `mission-flow.md` Pattern E §3 nomme déjà « du code que la mutation ne couvre pas » comme déclencheur de revue renforcée, « Domain pur à mutation verte » comme condition d'allègement — **sans qu'aucun outil ne produise ce fait**. |
| **Le skill lui-même** (la prose) | **faible** | pstack déjà étudié ; la plupart des règles restantes existent (tableau ci-dessus). En dépendre contredirait l'Axiome 1 — la critique Medium le dit pour nous ; et « un seul catalogue tiers installé » (décision du 2026-08-28, étude §4) s'applique. |
| **La gouvernance multi-agents** (swarm-forge) | **nulle, confirmatoire** | VibeFlow a déjà ce que swarm-forge n'a pas : juge sans outil d'écriture (`disallowedTools`), rapports typés à quatre statuts, contrat de preuves E6 (commande + exit code + SHA), verrou de driver, DAG de mission, halt conditions. Le socle `conductor` obligatoire que les labs ne remplacent pas = les trois articles partagés de swarm-forge. Rien à copier ; une validation externe du choix « constitution partagée + rôles en worktrees + handoffs par commits ». |

## Ce qu'on retient — six axes, aucun livré, chacun à arbitrer

Ordre de valeur décroissante. Chaque axe nomme le fichier où il atterrirait, ce qu'il retire
(ADR-076, « un ajout, un retrait ») et sa collision connue.

1. **Un gate de métriques — consultatif, jamais bloquant (ADR-074)** —
   `plugin/software-architecture/scripts/check-code-metrics.sh` (nouveau), frère de
   `check-file-size.sh`. Enveloppe les trois outils **s'ils sont présents dans le lab** (jamais
   embarqués, § « Ce qu'on ne fait pas ») et normalise : 0 conforme, 1 constat nommé (fonction,
   fichier, score), 3 INDÉTERMINÉ si un outil manque ou si la baseline est rouge — jamais un vert
   par absence (D-06). **Portée** : la qualité du code est un jugement métier au sens d'ADR-074
   (amendement du 2026-09-23 : la décidabilité par machine ne suffit pas, c'est l'objet gardé qui
   compte) → le script **constate**, le refus appartient au manager (`gaps_found` → correction
   ciblée) ou à l'humain, jamais à un `permissionDecision: deny`. `guard-file-size.sh` ne fait pas
   précédent (étude §4). Un **wrapper est indispensable pour `dryer`**, qui ne sort jamais en
   échec sur son seuil : le gate lit `.metrics/dry.edn` et constate sur `score ≥ 0,8`. Options :
   `--changed` pour cadrer sur le diff de l'étape, `--no-mutation` pour un passage rapide.
   **Qui le lance** : l'exécuteur (`vf-coder`, fin de nœud `exec-N`), jamais le juge — les outils
   écrivent `.metrics/`, le juge ne fait que lire. Né avec sa suite et ses fixtures rouges
   (QUAL-01 : un gate qui ne peut pas rougir ne prouve rien) ; commit porteur du trailer
   `Gate-Touche:` (G-2). Mention en SKILL.md §Tier 1 et dans `production-code-architecture.md`
   §Tests spécifiques. **Retire** : déplace trois items du Tier 2 (complexité, duplication,
   qualité des tests) du jugement vers la mesure — le Tier 2 maigrit d'autant. **Collision** :
   aucune connue ; module opt-in.
2. **Brancher ces verdicts sur le contrat de preuves E6** — `mission-contracts.md` §Contrat de
   preuves E6 : trois noms de verdict `gate:crap`, `gate:dry`, `gate:mutation` ; commande
   canonique = celle du wrapper (D-12) ; exit code réel ; SHA du HEAD au moment du verdict (D-15).
   Le head rejoue un gate manquant comme les autres (`head-governance.md` §3) ; deux manquants =
   contrat non appliqué (D-14). `vf-coder` relaie verbatim comme aujourd'hui, sans ligne nouvelle
   de doctrine : le contrat existant les absorbe. **Retire** : rien (trois valeurs d'un
   discriminant existant). **Collision** : **Phase 46** (Willy, format des verdicts) — même bloc
   typé que le lot A de l'étude ; sérialiser avec 46, comme QCT-01 à 04.
3. **Rendre la gradation de revue constatable** — `mission-flow.md` Pattern E §3 (c) : « du code
   que la mutation ne couvre pas » devient un **fait machine** = l'instantané `.metrics/mutate/`
   porte, sur un fichier du diff, un survivant ou un site non couvert. Symétriquement,
   l'allègement « Domain pur à mutation verte » = exit 0 de `mutator` sur les namespaces du diff.
   Aujourd'hui ce déclencheur est un jugement déguisé en fait ; après, c'est une lecture d'EDN.
   **Retire** : la lecture au jugement du déclencheur (c) — remplacée, pas doublée. **Collision** :
   QCT-09 (a) (déclencheurs renforcés → `deep`), compatible.
4. **Nourrir l'axe Standards de `vf-reviewer`** — si `.metrics/crap.edn` existe, le brief
   Standards reçoit la table triée (pire score en tête) et chaque fonction `CRAP ≥ 10` devient un
   finding `majeur` à `ref` déterministe `fichier:ligne`, `action: auto-fix`. Le juge reste sans
   outil d'écriture ; il lit un fait de plus, produit en amont par l'exécuteur (axe 1).
   **Où** : pas dans `vf-reviewer.md` — budget d'instructions 9/9 (étude §6, G-1 : marge 0) —
   mais dans la **référence** déjà prévue par le lot A pour le bloc « Hygiène » (QCT-01 à 04) :
   une ligne de plus dans le même bloc. **Retire** : rien. **Collision** : lot A et Phase 46.
5. **Deux règles de Tier 2 en réserve** — `principles.md` (format règle → test → signal →
   remède) : *Subtract Before You Add* (retirer de la complexité avant d'en ajouter — test : « le
   diff supprime-t-il quelque chose ? ») ; *Redesign From First Principles* (ne pas boulonner une
   exigence nouvelle sur l'ancienne conception — test : « qu'aurait-on construit si l'exigence
   avait toujours été là ? », livré en morceaux). **Aucune défaillance observée datée** ne les
   porte (POCK-08) ; même régime que QCT-10 : réserve, jusqu'à une défaillance. La règle du test
   honnête n'est **pas** ajoutée : c'est QCT-04 (lot A), déjà au BACKLOG.
6. **« Attack the Premise » en réserve, comme précurseur de HALT-2** — `mission-flow.md`
   Pattern E §2 (boucle de correction, 3 tours max) : quand le **deuxième** `gaps_found` porte sur
   le **même gate** que le premier, un nœud `premisse-N` avant le troisième dispatch — mandat à
   `vf-coder` : écrire en une phrase la prémisse commune aux deux correctifs, nommer l'acteur qui
   porte le déséquilibre, retirer cette assignation, puis seulement corriger. HALT-2 (Pattern 11)
   escalade après trois cycles ; ub-mode force la remise en cause avant le troisième — moins cher
   qu'une escalade, plus cher qu'un troisième essai aveugle. **Réserve** : la valeur « 2 » est
   empruntée, aucune boucle de correction du dépôt n'a été relue pour voir si la prémisse commune
   était là (QCT-08 : mesurer avant de retoucher une consigne).

Une **paire dans `check-overlaps.sh`** (`KNOWN_PAIRS`, `software-architecture|ub-mode|…`,
`tdd|ub-mode|…`, advisory, ADR-057 §Décision 1) n'a de sens que si un utilisateur installe
ub-mode dans un lab ; elle se pose à ce moment-là, pas avant (fixture → trailer `Gate-Touche:`).

## Ce qu'on ne fait pas

- **Embarquer** ub-mode ou ses outils dans le plugin : **aucune licence** sur les quatre dépôts —
  on ne redistribue pas. Ils restent une brique tierce installée côté lab et **détectée** (même
  régime que superpowers, ADR-057). Une issue « license? » chez `unclebob` est un geste humain,
  pas un geste d'agent.
- **Installer le skill** : « un seul catalogue tiers installé » (décision du 2026-08-28, étude
  §4) ; la prose est déjà couverte, et dépendre d'un skill pour la discipline contredit l'Axiome 1.
- **Un hook bloquant de métriques** : ADR-074 classe la qualité du code en consultatif, quelle que
  soit sa décidabilité ; `guard-file-size.sh` est l'exception antérieure qui ne fait pas précédent
  (étude §4). Et la mutation coûte 10× la baseline par mutant : nœud `exec-N` / `revue-N` ou
  sortie de mission (E6), jamais un `PreToolUse`.
- **Dépendre** d'un dépôt de quatre commits sans suivi : convention fragile `../crapper` en dépôt
  frère, venv par outil au premier lancement, `dryer` sans exit d'échec. Le wrapper isole VibeFlow
  de ces détails ; si les outils changent, seul le wrapper bouge.
- **Croire que c'est couvert partout** : Expo / React Native (TypeScript) oui ; natif iOS (Swift),
  Kotlin et `vibeflow-os` lui-même (Bash) non. La « mutation rouge » que QUAL-01 exige sur les
  gates Bash reste manuelle.
- **Rouvrir pstack** : lu à la source le 2026-10-10 (A2, 287 lignes) ; ses principes sont tranchés
  fiche par fiche. Cette note n'y revient pas.

## Ce qui reste à mesurer — spike proposé (non planifié, arbitrage humain requis)

Fusionné avec la **sonde QCT-09 (b)** (« sonde sur un lab TS avant toute décision ») : un seul
`/gsd-spike` sur un lab TypeScript réel (un projet Expo du parc), outils clonés côté lab.

1. **Temps** : durée de `crapper` (couverture Jest → LCOV) et de `mutator` en passage complet
   puis en `--changed` sur le diff d'une étape typique. Verdict attendu : acceptable en fin de
   nœud `exec-N` sous un plafond à poser, sinon réservé à la sortie de mission.
2. **Bruit** : taux de faux positifs de `dryer` à 0,8 sur des composants React Native (JSX
   structurellement répétitif par nature). Trop haut → seuil local relevé ou exclusion des `*.tsx`.
3. **Fidélité du fait** : sur trois étapes passées, la lecture de `.metrics/mutate/` donne-t-elle
   le même classement renforcé / allégé que le jugement du manager ? Un désaccord = soit le
   jugement se trompait, soit le fait est mal défini.
4. **Codes de sortie réels** des trois outils sur leurs cas d'échec (outil de couverture absent,
   baseline rouge, fichier illisible) — un README n'est pas une preuve ; le wrapper se fonde sur
   la mesure.
5. **Lecture seule du juge** : les outils lancés par l'exécuteur, le juge ne lisant que
   `.metrics/*.edn`, la contrainte `disallowedTools: Write, Edit` tient-elle de bout en bout ?
   Même question que QCT-09 (b) sur `fallow`.

Sans ces mesures, les seuils `CRAP < 10`, `0,8` et « 0 survivant » restent ceux d'Uncle Bob, pas
les nôtres.

## Sources

- unclebob/ub-mode : <https://github.com/unclebob/ub-mode> (SKILL.md et README lus via `gh api`, 2026-10-31)
- unclebob/crapper : <https://github.com/unclebob/crapper> · unclebob/dryer : <https://github.com/unclebob/dryer> · unclebob/mutator : <https://github.com/unclebob/mutator> · unclebob/uml-viewer : <https://github.com/unclebob/uml-viewer>
- unclebob/swarm-forge : <https://github.com/unclebob/swarm-forge>
- Profil et dépôts : <https://github.com/unclebob?tab=repositories> · stats trendshift : <https://trendshift.io/repositories/320616>
- Critique (lue via résumé de recherche, page en 403) : <https://medium.com/@creativeaininja/uncle-bob-wrote-a-skill-for-your-ai-coding-agent-the-skill-isnt-the-part-that-works-7cbef9b20f50>
- Couverture presse : <https://thecode.media/avtor-chistogo-koda-vypustil-besplatnyj-skill-dlya-ii-agentov/> · annonce X (RoundtableSpace) : <https://x.com/RoundtableSpace/status/2115062205116772676>
- Skills tiers non officiels : uncle-bob-craft <https://mcpmarket.com/tools/skills/uncle-bob-craft> · AmazingAng/old-coder <https://github.com/amazingang/old-coder> · robert-hoffmann/uncle-bob <https://github.com/robert-hoffmann/uncle-bob>
- Étude amont (ce dépôt) : `.planning/research/2026-10-10-qualite-code-tiers-etude.md` (verdict, §2 équivalences, §4 écartés, QCT-03/04/09/10, §5.4, §6) et son annexe `2026-10-10-qualite-code-tiers/A2-pstack.md` (§3.6, §3.7, §6) ; BACKLOG § « Emprunts qualité de code à Ponytail, pstack et thermo-nuclear review ».
- Doctrine VibeFlow (ce dépôt) : `docs/ADR.md` ADR-074 (portée des gates, amendement du 2026-09-23), ADR-076 (un ajout, un retrait), ADR-057 (frontières tierces), ADR-031 ; `plugin/reference/content/methodology/AXIOMES-ENFORCEMENT.md` ; `plugin/software-architecture/SKILL.md` §Tier 2 ; `plugin/software-architecture/references/principles.md` ; `plugin/software-architecture/rules/production-code-architecture.md` ; `plugin/dev-orchestrator/references/mission-flow.md` Pattern E §2–3 ; `plugin/dev-orchestrator/references/mission-contracts.md` §Contrat de preuves E6 ; `plugin/dev-orchestrator/references/head-governance.md` §3 ; `plugin/conductor/scripts/check-overlaps.sh` ; `plugin/reference/content/methodology/patterns/11-halt-conditions.md`.
