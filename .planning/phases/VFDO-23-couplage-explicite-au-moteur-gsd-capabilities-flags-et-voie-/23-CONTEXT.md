# Phase 23: Couplage explicite au moteur GSD — capabilities, flags et voie unique - Context

**Gathered:** 2026-08-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Cette phase rend **explicite et arbitré** le couplage du moteur de dev VibeFlow à
`@opengsd/gsd-core@1.9.0` — rien d'autre. Le point de départ n'est **pas une panne** : la chaîne
tourne, les agents ont les accès, aucune suite n'échoue. Le défaut est un **couplage implicite** —
le module raisonne comme si GSD était une liste de skills à appeler, alors que GSD 1.9 est un
**moteur à capabilities** qui insère ses étages lui-même.

Neuf surfaces, et pas une de plus :

1. **`GSD-PIPELINE.md`** — doctrine de flags de cycle en allowlist stricte, ligne `gsd-ship`
   corrigée, arbitrage de disjonction des étages ;
2. **script générateur** de la table capabilities/hooks depuis `gsd-tools loop render-hooks` ;
3. **`check-gsd-config.sh`** (advisory) + nettoyage du `.planning/config.json` de ce lab ;
4. **`mission-contracts.md`** — champ `gate`, minimum de reprise, verdicts de hooks, décompte de
   budget ;
5. **`mission-flow.md`** — budget partagé par étape, halt `blocked` + décompte, table de moments
   déclencheurs des briques dormantes ;
6. **`vf-coder.md`** — voie agent nu supprimée, allowlist purgée, gradation `--research` ;
7. **`vf-dev-manager.md`** — mapping `gate`, reset `_auto_chain_active`, halt de nœud, mandat
   debug, réponse aux checkpoints ;
8. **`test-dev-orchestrator.sh`** — gates `--auto` et voie unique ;
9. **`docs/ADR.md`** — ADR-061 étendue.

**Hors périmètre, explicitement** : aucune modification de `dag.sh` (module `conductor`, transverse
à tous les métiers — D-11) ; aucun fork ni réimplémentation d'un mécanisme GSD (ADR-030 : on
délègue, on n'absorbe pas) ; aucun verbe-façade (interdit permanent depuis v2.33.0) ; aucune
doctrine sur les flags **documentaires** — `docs-flow.md` (Phase 22, mergée) reste la source unique
sur ce point et n'est ni modifié ni dupliqué (D-06).

</domain>

<decisions>
## Implementation Decisions

- **D-00 [factuel] :** Ce cadrage a été produit **en conversation avec Samuel**, les 7 lacunes du
  ROADMAP posées comme 7 zones grises et **toutes** tranchées par lui (`23-DISCUSSION-LOG.md`).
  Aucune décision ci-dessous n'est une assumption auto-confirmée. Deux décisions ont été
  **révisées en cours de cadrage** sur découverte factuelle (D-03, D-04bis) — la révision est
  tracée, pas masquée.

---

### Zone 1 — Contrat de checkpoint et continuation (Lacune 6, sûreté, priorité imposée)

- **D-01 [tranché, Samuel] :** Le `gate` amont remonte par un **champ `gate` obligatoire** dans le
  bloc typé, présent dès qu'un checkpoint est survenu — et le mapping est écrit :
  `gate="blocking-human"` **OU** précondition non satisfaite (`gsd-executor.md:150`, « NEVER
  auto-approved, even under `AUTO_CFG=true` ») ⇒ statut `human_needed`. **Une seule règle couvre
  les deux** : un refus d'auto-approbation amont est un refus, quel qu'en soit le motif.
  Patron repris de `mission-contracts.md:155` (champs `estimate`/`actuals`, frères de `statut`).
  Écarté : un statut nouveau `checkpoint_bloquant` (propagation dans toute la chaîne typée pour un
  gain d'expressivité marginal) et la doctrine seule (rien ne prouverait à la lecture d'un rapport
  qu'un checkpoint a eu lieu — la régression silencieuse resterait possible).

- **D-02 [tranché, Samuel] :** `workflow._auto_chain_active` — régime en deux temps :
  1. `vf-dev-manager` **remet le flag à `false` en début de mission**
     (`gsd-tools query config-set workflow._auto_chain_active false`) ;
  2. `test-dev-orchestrator.sh` **échoue** si un fichier du module prescrit `--auto` sur
     `plan`/`execute`.

  **Fait établi pendant le cadrage, plus grave que ce que le ROADMAP décrivait** : `--auto` sur
  `gsd-discuss-phase` (que `vf-coder.md:27` **prescrit**) persiste le flag **dans
  `.planning/config.json`** — pas en mémoire de session — puis enchaîne `gsd-plan-phase --auto`
  (`modes/chain.md` étapes 4-5). À partir de là, règle 5 de `checkpoints.md` : tout checkpoint
  `decision` **auto-sélectionne la première option** et tout `human-verify` s'auto-approuve, dans
  **toutes** les sessions suivantes, jusqu'à ce que quelqu'un relance `discuss` sans `--auto`
  (étape 2 de `chain.md`). Vérifié : `_auto_chain_active` est **absent** du `config.json` de ce lab
  au 2026-08-01 — le piège est armé, il n'a pas encore claqué.
  — **Reversibility:** reversible — une ligne de doctrine, un appel `config-set`, un cas de test.

- **D-03 [tranché, Samuel — RÉVISÉ en cours de cadrage] :** Le bloc typé porte le **minimum de
  reprise** : `plan_id`, type de checkpoint, `gate`, et le contenu **« Awaiting »** (ce que le
  moteur attend). **Pas** la table des tâches faites.

  *Décision initiale : les 4 blocs complets du contrat amont (Completed Tasks / Current Task /
  Checkpoint Details / Awaiting). **Révisée** après vérification directe des workflows amont —
  voir D-29 : les 4 blocs sont un contrat **interne** `gsd-executor` ↔ `gsd-execute-phase`, que le
  skill orchestre déjà lui-même. Les recopier serait dupliquer un contrat amont, ce qu'ADR-030
  interdit.*

- **D-04 [tranché, Samuel] :** En **mission autonome**, un `gate="blocking-human"` provoque un
  **halt du nœud, pas de la mission** : le nœud se fige en `human_needed`, les **branches
  indépendantes du DAG continuent**, le constat est consigné au rapport de mission. Même axe que
  D-04 de la Phase 22 (constater et consigner, jamais trancher en douce) et cohérent avec le
  modèle DAG, qui existe précisément pour paralléliser des branches disjointes.
  Écarté : le halt dur (gaspille une nuit de travail sur des branches sans rapport avec le
  checkpoint, et pousse à éviter les gates plutôt qu'à les poser).

- **D-04bis [tranché, Samuel — issu de la vérification] :** Quand `gsd-execute-phase` **attend une
  réponse humaine** — checkpoint (étapes 4-5 de `execute-phase.md:1093-1125`) ou les 3 recours de
  `safe_resume_gate` (`execute-phase.md:178-192`) — c'est **`vf-dev-manager` qui répond**, pas
  `vf-coder`. Le worker rend `human_needed` + l'attendu ; le manager, **qui porte
  `AskUserQuestion` dans ses `tools:`** (vérifié), pose la question à Samuel en mode superviser
  puis redispatche avec la réponse. `gate="blocking-human"` reste hors de la portée du manager
  (D-01). Écarté : le manager tranchant seul les checkpoints `decision` non gatés — ce serait
  reproduire d'un étage plus haut le mode de défaillance que `checkpoints.md` décrit ; et donner
  `AskUserQuestion` à `vf-coder` — un worker interne ne parle pas à l'utilisateur (team-kernel), et
  un worker qui négocie échappe au contrôle de flux du manager.

### Zone 2 — Doctrine de flags de cycle (Lacune 3)

- **D-05 [tranché, Samuel] :** La recherche est **graduée sur critère factuel** :
  `--research` quand l'étape touche une lib / un framework / du natif / une version, ou un domaine
  non cartographié ; `--skip-research` quand elle prolonge un périmètre déjà couvert par un
  `RESEARCH.md` ou un `CONTEXT.md` récent. Le critère **doit rester un FAIT constatable**
  (ADR-055 §3), jamais un ressenti. Même axe que D-03 de la Phase 22 (gradation par le risque
  réel). Le flag n'est jamais omis : `plan-phase.md:333` **prompte** en son absence, et `vf-coder`
  n'a pas `AskUserQuestion`.

  *Précision à ne pas confondre au plan :* `workflow.research: true` dans le `config.json` active la
  **capability** `research` sur le hook `plan:pre` (le `gsd-phase-researcher` est spawné par le
  moteur). Le flag `--research` répond au **prompt**. Le toggle étant à `true`, la recherche a lieu
  de toute façon — le flag décide seulement si le worker se fait interroger.

- **D-06 [tranché, Samuel] :** La doctrine de flags de cycle vit **dans `GSD-PIPELINE.md`** — le
  fichier qui décrit déjà l'ordre canonique du cycle. Évite un 10ᵉ fichier de référence dans un
  module qui en compte 9, et place la règle là où le pipeline se lit déjà. **Renvoi croisé** vers
  `docs-flow.md` pour la famille documentaire, jamais de duplication (ADR-057 : une capacité, une
  seule voix). Écartés : un `gsd-flags.md` dédié (la frontière avec `GSD-PIPELINE.md` deviendrait
  elle-même à expliquer) et `mission-contracts.md` (déjà le plus gros du module — 16.1 K — et il
  parle mission, pas cycle).
  — **Reversibility:** costly — déplacer la doctrine après coup casse les renvois posés dans
  `AGENT.md`, les agents, le test d'exhaustivité et le chemin d'install D7 des labs déjà déployés.

- **D-07 [tranché, Samuel] :** La table capabilities/hooks est **GÉNÉRÉE** depuis
  `gsd-tools loop render-hooks` sur les 12 points, par un script sur le patron exact de
  `build-gsd-index.sh` / `gsd-skills-index.md` (auto-généré, jamais édité à la main). Ne périme
  pas quand `gsd-core` monte de version, et respecte la contrainte projet « tout index exposé est
  généré depuis le disque ou gaté ». Écartée : la table écrite sans garde — c'est exactement ce qui
  a produit l'écart que la Phase 23 constate elle-même (l'index versionné disait 1.8.0 alors que la
  machine tournait en 1.9.0).

- **D-08 [tranché, Samuel] :** La doctrine prend la forme d'une **allowlist stricte** : seuls les
  flags nommés sont utilisables par un agent du module ; **tout le reste est interdit par défaut**,
  y compris les flags que `gsd-core` ajoutera demain. Seule forme qui ne périme pas à la montée de
  version — un flag nouveau arrive **fermé**, et s'ouvre par décision, jamais par omission.
  Écartée : la liste d'interdits seuls, qui reproduirait la Lacune 5 (piloter par omission).

### Zone 3 — Voie unique d'invocation (Lacune 2, le trou le plus grave)

- **D-09 [tranché, Samuel] :** Le dispatch direct de `gsd-planner` / `gsd-executor` est **interdit
  sec**. Les mentions « ou dispatche l'agent `gsd-planner` » / « ou dispatche `gsd-executor` »
  (`vf-coder.md:32-33`) **disparaissent**. Une seule voie : le skill. Cohérent avec l'allowlist
  stricte de D-08 — ce qui n'est pas nommé est fermé. Rappel du coût de la voie fermée : l'agent nu
  fait sauter research, pattern-mapper, plan-checker, gap-analysis, drift gate, waves, verifier,
  code-review, nyquist et secure-phase, **sans que rien ne le signale** au rapport typé.
  — **Reversibility:** reversible — mais la rouvrir demanderait de re-trancher l'arbitrage entier.

- **D-10 [tranché, Samuel] :** La **continuation** d'un worker interrompu passe par **un nouveau
  `vf-coder`, voie skill** — aucune exception à D-09. Le manager redispatche avec le minimum de
  reprise (D-03) ; `vf-coder` réinvoque `gsd-execute-phase`, qui reprend au premier plan sans
  SUMMARY. **Hypothèse VÉRIFIÉE pendant le cadrage** (D-29) — ce n'est plus un pari.

- **D-11 [tranché, Samuel] :** Garantie machine par **test sur les fichiers du module** :
  `test-dev-orchestrator.sh` échoue si un agent du module prescrit un dispatch direct de
  `gsd-planner`/`gsd-executor`. Même extension de suite que le gate `--auto` de D-02 — une seule
  extension couvre les deux (D-14 de la Phase 22 : jamais de suite nouvelle, le compteur « N
  suites » des deux README est gaté par `check-version-sync.sh`). **Discriminance à prouver par
  mutation**, comme les gates existants de ce repo.

- **D-12 [tranché, Samuel] :** `gsd-planner` et `gsd-executor` **sortent de la ligne `tools:`** de
  `vf-coder`. C'est déclaratif — `team-kernel.md:23` acte que l'allowlist est **un contrat
  documenté, pas un cloisonnement runtime** — et c'est précisément le point : la liste doit dire la
  même chose que la doctrine, sinon elle autorise noir sur blanc ce que la doctrine interdit.
  Doit passer `check-agents.sh` (ADR-044). **Écarté** : l'audit complet des 20+ entrées → différé
  (voir `<deferred>`).

### Zone 4 — Étages de revue et d'audit (Lacune 1)

- **D-13 [tranché, Samuel] :** Le hook GSD `code-review` (`execute:post`) et le nœud `revue-N` du
  manager (ADR-060) **restent tous les deux**, déclarés **disjoints avec le critère écrit** : le
  hook revoit le diff d'**un plan** au moment où il se ferme ; `revue-N` revoit le diff de
  **jointure** d'une étape (intégration entre plans, cohérence avec l'existant). Même patron
  qu'ADR-061, qui a déjà déclaré disjoints deux étages de revue sur un critère en 3 axes. Le coût
  devient **assumé et nommé**, au lieu d'être une superposition subie.
  Écartés : éteindre `code_review` (un `gsd-execute-phase` lancé en direct par Samuel perdrait sa
  revue) ; réduire `revue-N` à la jointure seule (revirement d'ADR-060, non retenu).

- **D-14 [tranché, Samuel] :** Le hook `secure-phase` (`verify:post`) et `vf-auditer` sont
  **disjoints** : le hook vérifie les mitigations du **threat model du PLAN** ; `vf-auditer` y
  ajoute le **recoupement avec `.planning/codebase/CONCERNS.md`** et la dette connue du projet — un
  delta réel que le hook **ne peut pas** produire (il ne lit pas `CONCERNS.md`). Le critère s'écrit
  au même endroit que D-13. Écarté : conditionner `vf-auditer` au verdict du hook — on perdrait le
  recoupement exactement dans le cas où le hook ne voit rien, or c'est là que la dette connue sert
  le plus.

- **D-15 [tranché, Samuel] :** Le bloc typé porte les **verdicts déjà rendus par les hooks**
  (`code-review` / nyquist / `secure` : `pass|fail|absent`). Fait dimensionnant :
  `execute-phase.md` rend **à lui seul** `execute:post` (:1210) **et** `verify:post` (:1152) — un
  seul appel de skill déclenche donc revue **+** nyquist **+** sécurité. Le manager cesse de
  redemander ce qui est fait, et le coût réel devient **lisible** au lieu d'être payé deux fois en
  aveugle : c'est la réponse concrète au « deux budgets » de la Lacune 1.

- **D-16 [tranché, Samuel] :** L'arbitrage s'écrit en **extension d'ADR-061** — déjà l'ADR des
  étages de revue (cross-AI de plans vs diff de code, critère en 3 axes). Y ajouter le **troisième
  objet** (la revue de hook GSD) garde une seule voix sur une seule question (ADR-057), au lieu de
  deux ADR qu'il faudrait lire ensemble.

### Zone 5 — Alignement du `config.json` (Lacune 5)

- **D-17 [tranché, Samuel] :** Livrable = un **gate machine générique**, `check-gsd-config.sh`
  (module `dev-orchestrator`), qui sur **n'importe quel lab** signale (a) les clés **inconnues** du
  moteur installé et (b) les toggles de cycle laissés au **défaut implicite**. Il lit les clés
  connues **depuis `gsd-core`**, donc il ne périme pas — même principe que la table générée (D-07).
  Ce lab est le premier client de son propre outil. Écarté : réparer ce lab seulement (chaque lab
  VibeFlow ailleurs garderait le défaut silencieux, et l'avertissement `gsd-tools` continuerait
  d'apparaître chez les utilisateurs sans que personne ne sache quoi en faire).

- **D-18 [tranché, Samuel] :** Les blocs **`gates` et `safety` sont supprimés** du
  `.planning/config.json`, et **l'intention qu'ils portaient est reportée sur ce qui existe
  vraiment** : `workflow.human_verify_mode` côté moteur (défaut `'end-of-phase'`), et la doctrine
  ADR-031 côté VibeFlow — qui couvre `always_confirm_destructive` bien mieux qu'un flag inerte.
  **Fait vérifié dans `bin/lib/config.cjs`** : les 8 clés `gates.*` (dont `confirm_plan`) et les 2
  clés `safety.*` n'ont **aucun équivalent amont** — elles ne sont pas mal nommées, elles n'ont
  **pas de destination**. Rien n'est perdu, tout est déplacé où ça agit.

- **D-19 [tranché, Samuel] :** On inscrit explicitement, **à une valeur décidée**, les seuls
  toggles que cette phase arbitre réellement : `code_review`, `pattern_mapper`, `node_repair`,
  `node_repair_budget`, `ui_review`. Les autres capabilities restent au défaut amont — **ce qui est
  un choix légitime tant qu'il est écrit**. Écarté : inventorier les 44 capabilities (fichier
  énorme à maintenir à chaque montée de `gsd-core`, pour des toggles qui ne concernent pas ce lab).
  *Note pour le plan :* `ui_review` existe comme toggle de capability (`capability-registry.cjs`,
  cluster `ui`) mais **n'est pas** dans les défauts de `config.cjs` — la capability le résout
  elle-même. À traiter comme tel, sans supposer un défaut.

- **D-20 [tranché, Samuel] :** Le gate est **advisory**, contrat **exit 0 / exit 3** — même
  mécanique que `check-doc-drift.sh` (0 = quelque chose à dire, 3 = silence), câblable en
  `SessionStart`. Il **constate le fait** et laisse le **jugement** à l'agent ou à Samuel
  (ADR-055 §3) : un config « non conforme » n'est pas une faute, c'est peut-être un choix. Écarté :
  bloquant en CI — un gate qui dépend de la version de `gsd-core` **installée** rendrait la CI
  rouge dès qu'une clé est renommée en amont, soit une panne subie et non un défaut du repo.

### Zone 6 — Briques dormantes et tension `ship` (Lacune 4)

- **D-21 [tranché, Samuel] :** **L'ouverture de PR reste un geste VibeFlow**, à la main. ADR-059
  (une mission = une branche) et ADR-064 (un écrivain = un worktree, claim de driver) priment :
  `gsd-ship` ne connaît ni l'un ni l'autre. **`GSD-PIPELINE.md` est corrigé** pour cesser de
  déclarer `gsd-ship` dans le cycle emprunté sans dire **pourquoi** il ne l'est pas. La tension
  disparaît parce que la doctrine dit enfin la même chose que la pratique.

- **D-22 [tranché, Samuel] :** Le manager **ne debug pas** — il redispatche `vf-coder` en mandat
  de debug, et `vf-coder` invoque le **skill `gsd-debug`**. Voie unique (D-09) appliquée : aucun
  `gsd-debugger` en allowlist, aucune exception. Ce que le manager gagne, c'est le **moment**
  déclencheur, pas un outil. Comble le constat du ROADMAP (« après la recherche doc d'ADR-045 il
  n'a **rien** ») sans rouvrir la porte qu'on vient de fermer, et sur une brique que le skill pilote
  mieux que l'agent nu (état persistant entre resets de contexte).

- **D-23 [tranché, Samuel] :** **Quatre** briques dormantes reçoivent un moment déclencheur écrit :
  | Brique | Famille / rôle | Ancrage du déclencheur |
  |---|---|---|
  | `gsd-extract-learnings` | savoir | phase vérifiée / clôturée — famille **déjà doctrinée** par `docs-flow.md` (Phase 22), à raccorder au nœud `docs` de fin de mission |
  | `gsd-add-tests` | couverture | verdict nyquist **PARTIEL** — transforme un constat en action (aujourd'hui le gate constate les trous sans les combler) |
  | `gsd-spec-phase` | exigences | le QUOI d'une étape n'est pas stabilisé (SPEC.md est lu par `discuss-phase`, qui cesse alors de poser des questions de périmètre) |
  | `gsd-undo` / `gsd-forensics` | récupération | mission ratée / blocage à comprendre — aujourd'hui **aucune procédure écrite**, le manager improvise |

- **D-24 [tranché, Samuel] :** Ces moments s'écrivent sous forme de **table de moments
  déclencheurs**, gabarit **D-08 de la Phase 22** (`déclencheur | constat`), où chaque ligne est un
  **FAIT constatable** et jamais un jugement au feeling (ADR-055 §3). Le manager lit déjà une table
  de cette forme pour l'hygiène documentaire — même forme, même réflexe, aucun format nouveau.
  Écarté : des nœuds DAG conditionnels (alourdiraient le plan de bataille de nœuds qui ne se
  poseront presque jamais) et `intent-routing.md` seul (couvrirait la voie conversation mais pas la
  voie mission — la Phase 22 a établi que les deux comptent également).

### Zone 7 — Budgets de boucle additionnés (Lacune 7)

- **D-25 [tranché, Samuel] :** **Budgets inchangés, coût consigné.** `node_repair` (budget 2, à
  l'intérieur d'un plan) et la boucle Pattern E (3 tours, au grain étape) restent des **objets
  disjoints** — même raisonnement qu'en D-13/D-14. Ce qui change : le coût réellement consommé
  devient **lisible au rapport**. On décidera de plafonner quand on aura des chiffres, pas avant.
  Écartés : réduire Pattern E à 2 tours (son rendement — 4 bloquants + 9 majeurs sur la tranche
  Phase 20 — a été mesuré à 3 tours) ; `node_repair: false` (on éteindrait une réparation au grain
  **tâche**, faisant remonter tout en haut des échecs triviaux).

- **D-26 [tranché, Samuel] :** Traçabilité : **le RESEARCH établit** si les artefacts de
  `gsd-execute-phase` exposent le nombre de réparations `node_repair` consommées. Si oui → champ au
  rapport. Si non → on consigne au moins les tours d'équipe et **on ÉCRIT que le coût amont est
  invisible**. Un manque nommé vaut mieux qu'un chiffre inventé. Écartée : l'exigence
  d'observabilité coûte que coûte — elle ferait dépendre la phase d'un comportement de `gsd-core`
  hors de notre contrôle, avec risque de blocage à l'exécution.

- **D-27 [tranché, Samuel] :** **Un budget de tours par ÉTAPE, partagé** entre la boucle de revue
  et la boucle de comblement. Ferme le contournement mécanique — 3 tours de revue épuisés, puis 3
  tours de comblement sur le même problème rebaptisé — soit exactement le raffinage infini que
  Pattern E dit vouloir empêcher. Écarté : partagé par mission (pénaliserait les étapes tardives
  d'une longue mission, qui hériteraient d'un budget entamé par d'autres).

- **D-28 [tranché, Samuel] :** Budget épuisé ⇒ statut **`blocked` + décompte complet** de ce qui a
  été tenté (tours d'équipe, réparations amont si observables) et findings non résolus. Samuel lit
  un **chiffre réel**, plus un « bloqué après 3 tours » qui masquait jusqu'à **9** tentatives. Le
  décompte **est** la livraison concrète de cette zone. Écartée : une proposition de next step
  jointe — elle serait produite par l'agent qui vient d'échouer 9 fois sur le sujet, donc la partie
  la moins fiable du rapport.

---

### Vérifications faites pendant le cadrage (faits, pas hypothèses)

- **D-29 [factuel, vérifié] — `gsd-execute-phase` SAIT reprendre, à deux grains.**
  1. **Grain plan** : re-lancer `/gsd-execute-phase {phase}` → `discover_plans` saute les SUMMARY
     complets et reprend au premier plan incomplet (`execute-phase.md:1642`).
  2. **Grain tâche** : la continuation est orchestrée **par `gsd-execute-phase` lui-même**
     (`:1093-1125`) — il reçoit les 4 blocs de l'executor, présente le checkpoint, puis spawne une
     continuation via `continuation-prompt.md` (« *Why fresh agent, not resume* »). Le « *You will
     NOT be resumed* » d'`execute-plan.md:326` s'adresse à l'**executor**, **pas à VibeFlow**.
  3. **`safe_resume_gate`** (`:178-192`) : si des commits de production existent **sans** SUMMARY,
     le skill **refuse de spawner** un nouvel executor et offre 3 recours (`close out manually` /
     `re-execute from scratch` / `mark-and-skip`).

  **Trois conséquences pour le plan** : (a) D-10 est **confirmée et mieux fondée** — la voie skill
  porte un garde-fou (`safe_resume_gate`) qu'aucun dispatch d'agent nu n'aurait, et il couvre
  exactement le risque « commits orphelins d'un premier passage » que le ROADMAP redoutait ;
  (b) la **Lacune 6(c) du ROADMAP est mal posée** — porter les 4 blocs côté VibeFlow dupliquerait un
  contrat amont (d'où la révision D-03) ; (c) le **vrai** trou VibeFlow est l'attente de réponse
  humaine aux étapes 4-5 et dans `safe_resume_gate`, traité par D-04bis.

- **D-30 [factuel, vérifié] — `dag.sh` n'est pas touché.** `dag.sh reopen` remet le nœud **et ses
  dépendants** à `blocked`/`ready` et écrit `review_regime=full` (P-03 : valeur écrite **uniquement**
  par `reopen`). Il ne modélise pas un nœud partiellement exécuté, **et n'a pas à le faire** — le
  grain tâche vit dans le mandat (D-03), le grain nœud dans le DAG. Le script vit dans le module
  `conductor` (team-kernel), donc toute évolution serait transverse à tous les métiers : hors
  périmètre.

### Périmètre

- **D-31 [tranché, Samuel] :** **Les 7 lacunes restent dans la seule Phase 23.** Elles forment un
  seul objet — le couplage — et se tiennent mutuellement : la doctrine de flags dépend du contrat de
  checkpoint, la voie unique dépend des deux, le config dépend de la table de hooks. Les scinder
  ferait écrire deux fois les mêmes arbitrages. **Le découpage se fait en PLANS**, dans l'ordre
  imposé par le ROADMAP (**sûreté d'abord** : zone 1 avant la doctrine de flags), pas en phases.

### Claude's Discretion

- Le **découpage en plans** et leur nombre — contraints par l'ordre imposé (Lacune 6 en premier,
  Lacune 3 après), pas par une préférence exprimée.
- La **structure interne** des sections ajoutées à `GSD-PIPELINE.md` et la forme exacte des tables,
  tant que D-08 (allowlist) et D-24 (gabarit D-08 Phase 22) sont respectés.
- Le **nom exact** du script générateur de D-07 et du gate de D-17, tant qu'ils suivent les
  conventions du repo (`check-*.sh` pour un gate, patron `build-gsd-index.sh` pour un générateur).
- La **forme exacte** des assertions de D-02 et D-11, tant que la discriminance est prouvée par
  mutation.
- La **formulation** du critère de disjonction de D-13/D-14 dans ADR-061, tant que les 3 axes
  (objet revu / moment du cycle / déclencheur) sont couverts.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Workflows et références amont — la source de vérité sur ce que fait réellement le moteur

*(chemins de la machine, hors repo : `$HOME/.claude/gsd-core/`)*

- `references/checkpoints.md` — **contrat de checkpoint à deux couches (type × `gate`)**. Règle 5
  (auto-mode auto-tranche `decision` et `human-verify`), règle 6 (`gate="blocking-human"` jamais
  auto-approuvé), et le mode de défaillance nommé : « *An orchestrator that dispatches on checkpoint
  type alone would auto-approve the very checkpoint the executor just refused to auto-approve* ».
  **Fonde D-01, D-02, D-04, D-04bis.**
- `workflows/execute-phase.md` — `:178-192` `safe_resume_gate` (3 recours) ; `:1093-1125` protocole
  de continuation ; `:1152` rendu de `verify:post` ; `:1210` rendu de `execute:post` ; `:1642`
  reprise par `discover_plans`. **Fonde D-03, D-10, D-15, D-29.**
- `workflows/execute-plan.md` — `:310-326` contrat de retour en 4 blocs et « *You will NOT be
  resumed* » (adressé à l'**executor**) ; `:330-345` budgets `node_repair` RETRY/DECOMPOSE/PRUNE.
  **Fonde D-25 à D-28.**
- `workflows/plan-phase.md` — `:333` prompt sur la recherche ; `:651` « *Pattern mapper activation
  is owned by the `pattern-mapper` capability's `plan:pre` step hook* » ; `:1557-1577` persistance
  d'`_auto_chain_active` et enchaînement autonome. **Fonde D-02, D-05.**
- `workflows/discuss-phase/modes/chain.md` — étapes 2, 4 et 5 : c'est **ici** que `--auto` sur
  `discuss` persiste le flag en config et lance `plan-phase --auto`. **Fait central de D-02.**
- `bin/lib/config.cjs` `:243-273` — défauts réels (`code_review: true`, `pattern_mapper: true`,
  `node_repair: true`, `node_repair_budget: 2`, `human_verify_mode: 'end-of-phase'`) et **absence**
  de tout équivalent de `gates.*` / `safety.*`. **Fonde D-18, D-19.**
- `bin/lib/capability-registry.cjs` — 44 capabilities, 12 points de hook, exports `capabilities` /
  `byLoopPoint` / `capabilityClusters` ; `workflow.ui_review` y vit (cluster `ui`) sans défaut dans
  `config.cjs`. **Source du générateur de D-07.**
- `agents/gsd-executor.md` `:150` (préconditions jamais auto-approuvées) et `:330-332` (refus
  d'auto-trancher `gate="blocking-human"`, escalade par `checkpoint_return_format`). **Fonde D-01.**

### Doctrine locale à étendre ou à respecter (repo courant)

- `plugin/dev-orchestrator/references/GSD-PIPELINE.md` — **cible principale** : ordre canonique
  (§1, ligne `gsd-ship` à corriger — D-21), accueil de la doctrine de flags (D-06/D-08) et de
  l'arbitrage de disjonction (D-13/D-14).
- `plugin/dev-orchestrator/references/docs-flow.md` — **livré par la Phase 22, mergé**. Porte déjà
  les flags de la famille **documentaire** (`--verify-only`, `--force` + garde-fou en 3 temps) et
  les 4 familles. La 23 y **renvoie** et ne le duplique jamais (ADR-057).
- `plugin/dev-orchestrator/references/mission-flow.md` — §Pattern B (DAG, `dag.sh add --deps`),
  §Pattern C (contrat de rapport typé), §Pattern E `:171-206` (nœud `revue-N`) et `:203` (budget 3
  tours — cible de D-27/D-28), §Résolution des scripts (`$S`).
- `plugin/dev-orchestrator/references/mission-contracts.md` — `:155` patron des champs optionnels
  (fonde D-01) ; §Étage revue `:175-178` et **ADR-061** (fonde D-16) ; §Rapport de mission (cible de
  D-15/D-28) ; §STATE.md / ADR-063 (ne jamais « réparer » via `gsd-tools state`).
- `plugin/dev-orchestrator/references/intent-routing.md` — seul fichier qui décide du routage ; sa
  §Couverture porte le contrat d'exhaustivité vérifié par le test.
- `plugin/dev-orchestrator/agents/vf-coder.md` — `:27` (`--auto` sur discuss, cible de D-02),
  `:32-33` (voie dégradée, cible de D-09), ligne `tools:` (cible de D-12).
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` — `:114-129` (pose de `revue-N`), `:157`
  (statuts typés, cible de D-01), §Hygiène documentaire (cible de D-23/D-24). Porte
  **`AskUserQuestion`** dans ses `tools:` — vérifié, fonde D-04bis.
- `plugin/conductor/conductor-references/team-kernel.md` `:23` — l'allowlist `Agent(...)` est **un
  contrat documenté, pas un cloisonnement runtime**. **Fonde D-12.**
- `plugin/conductor/scripts/dag.sh` — `reopen` (nœud + dépendants → `blocked`/`ready`,
  `review_regime=full`, P-03). **NE PAS MODIFIER** (D-30).

### Faits outillés existants — patrons à imiter, jamais à réimplémenter

- `plugin/dev-orchestrator/scripts/build-gsd-index.sh` → `references/gsd-skills-index.md`
  (auto-généré, jamais édité à la main). **Patron du générateur de D-07.**
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` — contrat exit 0 = seuil atteint / exit 3 =
  silence / exit 64 = argument invalide, câblé en `SessionStart`
  (`plugin/dev-orchestrator/hooks/hooks.json`). **Patron du gate de D-17/D-20.**
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — suite **à étendre** (D-02,
  D-11), jamais à dupliquer : le compteur « N suites » des deux README est gaté par
  `check-version-sync.sh`. Voir sa boucle de vérification des références (~ligne 923) et son test
  d'exhaustivité de routage (~762-877).
- `plugin/conductor/scripts/check-agents.sh` — ADR-044, à repasser après D-12.

### Doctrine transverse du repo

- `docs/ADR.md` — **ADR-029** (densité : agents ≤ 250 L, skills ≤ 500) · **ADR-030** (déléguer aux
  skills outillés, ne jamais réimplémenter — **fonde la révision D-03**) · **ADR-031** (jamais de
  fix sans validation humaine — fonde D-18) · **ADR-044** (agents machine-enforced) · **ADR-053**
  (lock + DAG + rapports typés) · **ADR-055 §3** (le script constate le FAIT, l'agent porte le
  JUGEMENT — fonde D-05, D-20, D-24) · **ADR-057** (une capacité, une seule voix — fonde D-06,
  D-16) · **ADR-059** (une mission = une branche) · **ADR-060** (`revue-N` étage de premier rang) ·
  **ADR-061** (étages de revue disjoints — **à ÉTENDRE**, D-16) · **ADR-064** (un écrivain = un
  worktree) — ADR-059/064 **fondent D-21**.
- `CLAUDE.md` racine — discipline de release (toute version = un tag annoté + release GitHub),
  commits en français, densité.
- `.planning/codebase/CONVENTIONS.md` — nommage, portabilité bash (ADR-054 : pas de `jq`,
  `grep -P`, `sed -i`), `jqx()`, préfixe `VF_`.
- `.planning/phases/VFDO-22-…/22-CONTEXT.md` — décisions de la Phase 22 qui **se reportent ici** :
  D-03 (gradation par le risque réel), D-04 (autonome : constater et consigner), D-08 (gabarit de
  table de déclencheurs), D-14 (étendre la suite, jamais en créer une).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`build-gsd-index.sh` → `gsd-skills-index.md`** : le patron complet de la table générée de D-07
  existe déjà dans le module et tourne. Rien à inventer — un second générateur sur le même moule.
- **`check-doc-drift.sh`** : le contrat d'exit advisory (0/3/64) de D-20 est déjà écrit, testé
  (`test-check-doc-drift.sh`) et câblé en `SessionStart`. Le gate de D-17 le recopie.
- **`safe_resume_gate` du moteur** : le garde-fou anti-commits-orphelins que la Lacune 6(c)
  réclamait **existe déjà en amont** et se déclenche seul dès qu'on passe par le skill. C'est un
  argument de plus pour D-09 — la voie unique n'est pas qu'une règle d'hygiène, elle donne accès à
  des protections que l'agent nu n'a pas.
- **Le patron des champs optionnels du bloc typé** (`mission-contracts.md:155`, `estimate`/
  `actuals`) : D-01, D-03 et D-15 s'y greffent sans inventer de format — mêmes règles (recopie
  verbatim, absents si l'amont ne les portait pas, aucun recalcul).
- **La table de moments déclencheurs de D-08 (Phase 22)** dans `vf-dev-manager.md` : D-24 la
  prolonge au lieu d'en créer une seconde forme.

### Established Patterns

- **Une capacité, une seule voix (ADR-057)** — `intent-routing.md` décide du routage ;
  `GSD-PIPELINE.md` porte la doctrine du cycle ; `docs-flow.md` celle des docs. Aucun des trois ne
  duplique les deux autres.
- **Déléguer, ne pas absorber (ADR-030)** — c'est le principe qui a fait **réviser D-03** : un
  contrat que le moteur orchestre déjà ne se recopie pas côté VibeFlow.
- **Chargement on-demand** — `GSD-PIPELINE.md`, `intent-routing.md`, `mission-contracts.md`,
  `docs-flow.md` ne sont jamais chargés en session normale. Les ajouts de cette phase suivent la
  règle : coût contexte nul tant que le cycle n'est pas engagé.
- **Test d'exhaustivité + discriminance par mutation** — ajouter un gate sans prouver qu'il échoue
  sur la mutation qu'il prétend attraper produit un faux vert. Précédent documenté dans ce repo
  (les deux gardes mortes de `brick_routed()`, remplacées par T14c).
- **Français partout** — docs, commentaires, commits, messages d'erreur.

### Integration Points

1. `plugin/dev-orchestrator/references/GSD-PIPELINE.md` — doctrine de flags (D-06/D-08), ligne
   `gsd-ship` (D-21), arbitrage de disjonction (D-13/D-14).
2. `plugin/dev-orchestrator/scripts/` — **création** du générateur de table (D-07) et de
   `check-gsd-config.sh` (D-17/D-20), + câblage `hooks.json` si `SessionStart` est retenu.
3. `plugin/dev-orchestrator/references/mission-contracts.md` — champ `gate` + minimum de reprise
   (D-01/D-03), verdicts de hooks (D-15), décompte de budget (D-28).
4. `plugin/dev-orchestrator/references/mission-flow.md` — budget partagé par étape (D-27), halt
   `blocked` + décompte (D-28), table des briques dormantes (D-23/D-24).
5. `plugin/dev-orchestrator/agents/vf-coder.md` — D-05 (gradation `--research`), D-09 (voie
   dégradée supprimée), D-12 (ligne `tools:` purgée), D-04bis (rendre `human_needed` + attendu).
6. `plugin/dev-orchestrator/agents/vf-dev-manager.md` — D-01, D-02 (reset du flag), D-04 (halt de
   nœud), D-04bis (répondre via `AskUserQuestion`), D-22 (mandat debug), D-23/D-24 (table).
7. `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — gates D-02 et D-11.
8. `.planning/config.json` — D-18 (suppression) + D-19 (toggles décidés).
9. `docs/ADR.md` — ADR-061 étendue (D-16).
10. `plugin/dev-orchestrator/VERSION` + `CHANGELOG.md` + `README.md` — bump **minor** (nouvelle
    capacité). Release racine (`VERSION`, `plugin.json`, `marketplace.json`, 2 README, tag annoté,
    release GitHub) : **hors périmètre d'exécution**, réservée à validation humaine.

### Contrainte dimensionnante — densité (ADR-029)

`mission-contracts.md` est **le plus gros fichier du module (16.1 K)** et gagne ici 4 ajouts
(D-01, D-03, D-15, D-28). `vf-dev-manager.md` était à **217/250 lignes** avant la Phase 22 et gagne
6 changements. **À traiter au plan, pas à découvrir à l'exécution** : privilégier le renvoi vers
`GSD-PIPELINE.md` plutôt que la copie, et remplacer plutôt qu'ajouter — c'est exactement ce que la
Phase 22 a dû faire pour sa table D-08.

</code_context>

<specifics>
## Specific Ideas

- **L'origine est une question de Samuel, pas un incident** : « dev-manager a-t-il accès à cet
  outil, et sait-il utiliser GSD avec le bon workflow, au bon moment, quand c'est réellement
  utile ? » — après avoir observé un `gsd-pattern-mapper` spawné en session inline. La réponse
  établie au ROADMAP (Constat 0) est que **l'accès n'est pas le sujet** : le pattern-mapper n'avait
  été choisi par aucun agent, c'est la capability qui l'insère (`plan-phase.md:651`). La bonne
  question était « qui décide, et le module le sait-il » — c'est cette phase.

- **Le cadrage a corrigé le ROADMAP sur un point, et il faut le dire au plan** : la Lacune 6(c)
  demandait de porter le contrat de continuation en 4 blocs côté VibeFlow. Vérification faite
  (D-29), ce contrat est **interne au moteur**. Le plan ne doit pas « rattraper » ce point du
  ROADMAP tel qu'il est écrit — D-03 et D-04bis le remplacent.

- **Deux découvertes de cadrage qui ne venaient pas du ROADMAP** et qui doivent survivre jusqu'à
  l'exécution : (1) `--auto` sur **`gsd-discuss-phase`** — pas seulement sur `plan` — persiste
  `_auto_chain_active` **en config** (D-02) ; (2) `safe_resume_gate` **attend une réponse humaine**
  au même titre qu'un checkpoint, et `vf-coder` ne peut pas la donner (D-04bis).

- **Frontière avec la Phase 22, à ne pas rouvrir** : la 22 est mergée et sa doctrine de flags
  **documentaires** fait autorité. Le ROADMAP le disait par avance — « l'arbitrage écrit par la
  première exécutée fait autorité, la suivante s'y réfère sans le dupliquer ». La 23 porte les flags
  du **cycle**, renvoie pour le reste.

- **Frontière avec les Phases 24 et 25** : la 24 (« activation et mesure ») et la 25 (budget
  d'instructions, étage d'alignement court) ont un recoupement thématique avec l'outillage de cette
  phase. D-31 tranche : **rien ne migre**, les 7 lacunes restent ici. La 25 dépend en revanche de
  la doctrine écrite ici (son G2 dépend de la 23).

</specifics>

<deferred>
## Deferred Ideas

- **Audit complet des 20+ entrées d'allowlist `Agent(...)` de `vf-coder`** — retirer celles
  qu'aucune doctrine ne mobilise (`gsd-ui-*`, `gsd-ai-*`, `gsd-domain-researcher`, `gsd-eval-planner`
  sur un worker de dev). Écarté en zone 3 : périmètre à part entière, proche de la Lacune 4, et
  risque de casser l'étage implémentation d'une mission design. D-12 ne retire que
  `gsd-planner`/`gsd-executor`, les deux que la doctrine interdit désormais nommément.

- **Plafonner le budget global de tentatives** (les ≈ 9 de D-25). Explicitement reporté par D-25 :
  on consigne d'abord, on décide sur chiffres ensuite. À rouvrir quand quelques missions auront
  produit des décomptes réels.

- **Inventorier les 44 capabilities dans le `config.json`** — écarté par D-19 au profit des seuls
  toggles que cette phase arbitre. À reconsidérer si la Phase 24 (« activation et mesure ») en fait
  son objet, ce qui serait cohérent avec son intitulé.

- **`gsd-ship` / `gsd-pr-branch` adoptés côté VibeFlow** — écarté par D-21 tant qu'ADR-059 et
  ADR-064 tiennent (branche de mission, worktree, claim de driver). À rouvrir si `gsd-core` fait
  évoluer `gsd-ship` pour respecter une branche imposée et un verrou d'écrivain externe.

</deferred>

---

*Phase: 23-Couplage explicite au moteur GSD — capabilities, flags et voie unique*
*Context gathered: 2026-08-01*
