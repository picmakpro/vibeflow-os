# Phase 34: Gaps agency-agents & cadrage skill-installer - Context

**Gathered:** 2026-09-14
**Status:** Ready for planning

<domain>
## Phase Boundary

La phase rend **trois verdicts écrits**, sur pièces, et **ne crée aucun agent** :

1. **AGTS-01** — l'arbitrage des gaps de couverture du parc d'agents, par distillation de la
   taxonomie du catalogue `msitarzewski/agency-agents` (matrice division → module re-mesurée à la
   date de la phase), un verdict par gap (combler / reporter / refuser) adossé à la règle de preuve
   du milestone.
2. **AGTS-02** — la tentative de sortie du statut expérimental de `mobile-test`(-team) par un
   **run réel** sur un lab mobile, dont dépend la construction de `web-test-team` : vert → moule
   prouvé, `web-test-team` construite dans la phase ; rouge → exigence **reportée avec la trace du
   run**, jamais abandonnée en silence.
3. **SKIL-01** — le go/no-go du skill-installer global, rendu après un **spike mesuré** (« un
   skill installé via le natif `/plugin` atteint-il les sous-agents ? »), aucun code d'installeur
   avant un GO.

Hors périmètre : import de personas (anti-feature gravée), marketplace de skills maison, création
d'agents pour les gaps jugés « à combler » (ils deviennent des items backlog datés), toute
révision de la condition d'AGTS-02.

</domain>

<decisions>
## Implementation Decisions

Onze arbitrages rendus par Samuel le **2026-09-14** (AskUserQuestion, session principale), en
deux lots groupés par zone. Ils sont **verrouillés** — ne pas les rouvrir.

### AGTS-01 — livrable : audit + verdict par gap, zéro agent neuf
- **D-01:** Le livrable d'AGTS-01 est une **note d'audit** : la matrice division → module du
  2026-07-20 (`.planning/BACKLOG.md:320-331`) est **re-mesurée** à la date de la phase (le parc a
  bougé : 25 agents distribués + 6 `AGENT.md`, `web-test-team` toujours inexistante), puis un
  **verdict écrit par gap** — combler / reporter / refuser — avec la preuve qui le fonde. **Aucun
  agent n'est créé dans cette phase** ; un gap jugé « à combler » devient un **item backlog daté**
  avec sa preuve, pas un fichier sous `plugin/`. — **Reversibility:** reversible — une note et des
  items backlog n'engagent aucun contrat distribué.
- **D-02:** La preuve qui rend un gap « à combler » est **la règle de preuve du milestone**
  (`.planning/REQUIREMENTS.md:910-912`) : un **incident documenté**, une **demande externe**
  (client, testeur, issue) ou un **bug récurrent par construction**. Un ❌ dans la matrice du
  catalogue **ne suffit pas** — la couverture du catalogue est une source d'inspiration, jamais une
  référence d'exigence (`.planning/BACKLOG.md:310-312`). L'usage personnel de Samuel sans trace
  écrite ne suffit pas non plus (option écartée).
- **D-03:** Discipline Pitfall 12 (`.planning/research/PITFALLS.md:377-408`) reprise telle quelle :
  le rapport nomme explicitement que « plus de 2-3 agents d'un coup » est un signal d'alarme, et
  qu'un futur comblement se fait **un agent à la fois**, gaté `check-agents.sh` (ADR-044) et
  règle 4 de `check-capability-activation.sh` s'il est armé.

### AGTS-02 — tenter le run réel de sortie d'expérimental dans la phase
- **D-04:** Un plan de la phase **joue le run de sortie d'expérimental** défini par
  `plugin/mobile-test/README.md:119-123` (`detect` → `run --platform ios`, build depuis zéro →
  rapport généré) et `plugin/mobile-test-team/README.md:122-128` (une phase mobile pilotée sans
  intervention, au moins un cycle de fix, arrêt propre). **Lab : `Scroll-Off/frontend`**
  (Expo/React Native, dossier `.maestro/` déjà présent), **plateforme : iOS seulement** (Android
  non exigé pour la sortie), **poste : celui de Samuel** (Maestro, Xcode, `simctl`, simulateurs
  iPhone 17 Pro présents, vérifiés le 2026-09-14), **exécutant : l'équipe VF** via
  `vf-test-orchestrator` dispatché par le manager de mission. — **Reversibility:** reversible — un
  run est rejouable ; seule la trace est conservée.
- **D-05:** **Tout prérequis manquant en cours de run = arrêt propre et report tracé, jamais réparé
  à la volée.** Aucun worker n'installe Maestro, un JDK, un simulateur ou un SDK sur le poste ; la
  cause d'arrêt est écrite dans la trace. Vert → `mobile-test`(-team) sort du statut expérimental
  (README + `module.json` des deux modules amendés, item actif de `PROJECT.md:82` coché) **et**
  `web-test-team` est **construite dans la phase** sur le moule prouvé (Playwright, Pattern 12,
  `.planning/BACKLOG.md:335-338`). Rouge → **AGTS-02 reportée avec la trace du run** (le rapport,
  la cause, la date), déclencheur de reprise daté inscrit au ledger ; rien n'est construit côté
  test web.
- **D-06:** La condition du ROADMAP (« SI mobile-test sort du statut expérimental pendant le
  milestone ») **n'est pas révisée** — l'option « construire `web-test-team` sans attendre » est
  écartée : cloner un moule non prouvé rejouerait exactement le motif « armé sans preuve » que ce
  milestone ferme.

### SKIL-01 — spike mesuré puis verdict
- **D-07:** Le go/no-go **n'est pas rendu sur pièces** : un **spike mesuré** établit d'abord si un
  skill installé par le natif `/plugin` (scope user ou project) **atteint réellement les
  sous-agents** — c'est le seul différenciateur restant identifié
  (`.planning/research/FEATURES.md:209-231`, ligne `agent_skills` du bootstrap). **GO seulement si
  un trou mesuré existe ET que l'engine actuel peut le fermer** (`vibeflow-update.sh` pose déjà des
  skills, `:2218-2229`) ; sinon **abandon documenté** et item backlog du 2026-06-04 clos
  (`.planning/BACKLOG.md:258-273`). — **Reversibility:** one-way pour un NO-GO — l'item backlog est
  clos et l'anti-feature « marketplace de skills maison » (`.planning/REQUIREMENTS.md:1093`) reste
  gravée ; rouvrir demanderait une nouvelle mesure qui contredise celle-ci.
- **D-08:** Runtimes du spike : **Claude Code d'abord** (le canal `/plugin` natif est la référence
  de la question) ; **Codex et Kimi mesurés seulement si le verdict Claude est GO**, pour
  dimensionner le câblage multi-runtime (racine `~/.agents/skills` partagée avec d'autres outils sur
  le poste — `38-CONTEXT.md:372,424,493-494`). Un NO-GO Claude clôt la question sans mesurer les
  autres runtimes.
- **D-09:** Périmètre d'un éventuel GO : **le câblage, jamais un catalogue** (F8,
  `.planning/research/FEATURES.md:209-231`) ; **collision de nom = refus** (critère de succès 3 du
  ROADMAP). **Aucune ligne de code d'installeur dans cette phase**, même sur GO — le GO produit une
  spec de câblage et un item de phase ultérieure.

### Forme de la phase
- **D-10:** Phase **documentaire à une exception** : trois notes de décision (audit AGTS-01, trace
  du run AGTS-02, verdict SKIL-01) plus le ledger ; le **seul livrable de code possible** est
  `web-test-team` sur run vert (D-05). Le spike SKIL est un **spike** (jetable, findings consignés
  via `/gsd-spike --wrap-up` ou note équivalente), pas un livrable.
- **D-11:** QUAL-01 s'applique **de plein droit si un gate naissait** dans la phase
  (`.planning/REQUIREMENTS.md:906-907`) ; aucun gate n'est attendu. Si `web-test-team` est
  construite, ses agents passent `check-agents.sh --strict` et la suite de tests du module est
  découverte par la CI (compteur de suites des README à re-dériver, jamais recopié).

### Claude's Discretion
- Ordre des trois volets dans le plan (le run mobile est le plus long et le plus incertain — le
  jouer en première vague, en parallèle du spike SKIL, est la lecture naturelle).
- Forme exacte des notes (un fichier par volet sous le dossier de phase, nommage `34-AUDIT-AGTS.md`,
  `34-RUN-MOBILE.md`, `34-SPIKE-SKIL.md` ou équivalent).
- Choix du flow Maestro joué sur Scroll-Off (celui déjà présent dans `.maestro/` suffit pour la
  sortie d'expérimental ; aucun flow neuf n'est exigé).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Périmètre et exigences
- `.planning/ROADMAP.md` § Phase 34 (`:880-899`) — goal, dépendance à la Phase 31, trois critères de succès.
- `.planning/REQUIREMENTS.md:958-963` — `SKIL-01`, `AGTS-01`, `AGTS-02` ; `:906-907` — QUAL-01 s'applique si un gate naît ; `:910-915` — règle de preuve et coupes du 2026-08-15 ; `:1093-1094` — anti-features « marketplace de skills maison » et « import des 230 personas ».
- `.planning/PROJECT.md:49-51` — items d'origine ; `:82` — item actif « sortie du statut expérimental de mobile-test ».

### Catalogue agency-agents et gaps
- `.planning/BACKLOG.md:303-348` — item d'origine (2026-07-20), matrice division → module, pistes priorisées, « ce qu'on n'en prend pas ».
- `.planning/BACKLOG.md:258-273` — item skill-installer global (2026-06-04, déclencheur consommé) ; `:274-298` — « template d'agent installable » (recoupe, question ouverte « que fait-il de plus que vibeflow-dev ? »).
- `.planning/research/FEATURES.md:209-231` (F8 skill-installer), `:236-247` et `:310` (F9 web-test-team, dépendance à la sortie d'expérimental) ; `.planning/research/PITFALLS.md:377-408` (Pitfall 12) ; `.planning/research/STACK.md:105` (Playwright = dépendance côté lab, hors stack plugin).

### Gouvernance des agents
- `docs/ADR.md:52` (ADR-029, densité ≤ 250 L) et `:60` (ADR-044, agents natifs machine-enforced) ; `plugin/reference/content/methodology/patterns/03-agents.md:110-114`.
- `plugin/conductor/scripts/check-agents.sh:515-533` — champs requis ; `plugin/dev-orchestrator/scripts/check-capability-activation.sh:86-118,723-726,756-770` — règle 4 et bornes.

### mobile-test et sortie d'expérimental
- `plugin/mobile-test/README.md:41-43,119-123` — prérequis (Maestro, JDK, Xcode/simctl) et condition de sortie ; `plugin/mobile-test-team/README.md:122-128` — condition côté équipe ; `plugin/mobile-test/module.json:5`, `plugin/mobile-test-team/module.json:5` — statut déclaré en prose.

### Skill-installer et canal natif
- `INSTALL.md:26-37` — commandes natives `claude plugin …` et équivalents Codex ; `plugin/_internal/vibeflow-update.sh:2218-2229,2288,2304,2478,2606-2608,2726` — pose, backup, rollback et désinstallation de skills par l'engine ; `plugin/skill-creator/README.md:11-31` et `docs/ADR.md:140-160` — skill-creator crée, n'installe pas de catalogue.
- `.planning/phases/VFDO-38-portabilit-multi-runtime-livraison-canal-d-install-migration/38-CONTEXT.md:372,378,424,493-494` — `~/.agents/skills`, racine Codex inconditionnelle et partagée.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mobile-test-team` (agents `vf-test-orchestrator`, `vf-test-runner`, `vf-app-fixer`, 48-60 L chacun) et `plugin/mobile-test/scripts/mobile-test-run.mjs` : le moule complet que `web-test-team` clonerait sur Playwright.
- `plugin/_internal/vibeflow-update.sh` : pose/backup/rollback/désinstallation de `SKILL.md` déjà outillés — un GO SKIL-01 réutiliserait ce chemin, il n'en ouvrirait pas un second.
- `.planning/BACKLOG.md:320-331` : la matrice de couverture est le gabarit à re-mesurer, colonne par colonne.

### Established Patterns
- Pattern 12 (workers internes `vf-internal: true`, jamais invocables directement) — obligatoire pour toute équipe neuve.
- Règle de preuve du milestone : incident / demande externe / bug récurrent — appliquée à chaque gap.
- Spike jetable + findings consignés (`/gsd-spike`), déjà pratiqué en Phases 32 et 37.

### Integration Points
- Sortie d'expérimental : `module.json` (`description`) et README des deux modules `mobile-test*`, `PROJECT.md:82`.
- Verdict SKIL : `.planning/BACKLOG.md:258` (clôture ou spec de câblage), `.planning/REQUIREMENTS.md:1093` (anti-feature à maintenir ou amender).
- Corpus d'agents figé pour la Phase 25 : tout agent ajouté ici (uniquement `web-test-team` sur run vert) entre dans la calibration du budget d'instructions — la Phase 25 ne se calibre qu'après la clôture de celle-ci.

</code_context>

<specifics>
## Specific Ideas

- Le run mobile se joue sur `~/Documents/dev/Scroll-Off/frontend` (flow existant sous `.maestro/`), simulateur iPhone 17 Pro de ce poste ; le run est un mandat d'équipe, pas un geste de Samuel.
- « Un ❌ dans la matrice ne suffit pas » — la note d'audit doit le dire en toutes lettres pour chaque gap refusé, avec la preuve qui manque.
- Le spike SKIL mesure par exécution (un skill posé via `/plugin`, puis un sous-agent qui tente de l'invoquer), jamais par lecture de doc — cf. `[[preuve-incapable-de-rendre-rouge]]` : le contrôle négatif (skill absent → sous-agent ne le voit pas) fait partie de la mesure.

</specifics>

<deferred>
## Deferred Ideas

- **SupportFlow** (customer service / analytics / legal) et **extensions Sales / Paid Media** — candidats de la matrice, traités par la note d'audit comme items backlog datés s'ils obtiennent une preuve ; aucune construction ici.
- **Template d'agent installable** (`.planning/BACKLOG.md:274-298`) — recoupe SKIL-01, hors phase.
- **Android** pour la sortie d'expérimental — iOS suffit ici ; un run Android tracé reste souhaitable avant de vendre le module hors statut expérimental sur les deux plateformes.
- **Mesure Codex / Kimi du spike SKIL** — seulement sur GO Claude (D-08).
- Mention « 46 skills perso sous `~/.agents/skills` » (mémoire de session) — introuvable dans le dépôt, non retenue comme fait.

</deferred>

---

*Phase: 34-gaps-agency-agents-cadrage-skill-installer*
*Context gathered: 2026-09-14*
