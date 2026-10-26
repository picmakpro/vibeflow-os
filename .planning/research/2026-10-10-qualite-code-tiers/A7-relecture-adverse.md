# A7 : relecture adverse de l'étude « qualité de code, frameworks tiers » (2026-10-10)

Document relu : `.planning/research/2026-10-10-qualite-code-tiers-etude.md` (abrégé **E**), dans le
worktree `vibeflow-os/.claude/worktrees/etude-qualite` (HEAD `53dfc217` = `origin/main`, `VERSION`
v2.69.0, vérifié). Annexes A1 à A4 relues en entier. §5.3 et §6 non critiqués (en attente).
Lecture seule, aucun fichier du dépôt modifié.

Abréviations de preuve : **GCR** = `~/.claude/agents/gsd-code-reviewer.md` (moteur gsd-core 1.16.0) ;
**MC** = `plugin/dev-orchestrator/references/mission-contracts.md` ; **MF** = `.../mission-flow.md` ;
**GP** = `.../GSD-PIPELINE.md`.

## Bilan chiffré

- 20 affirmations VibeFlow vérifiées directement dans le dépôt ou le moteur installé : 14 exactes,
  6 fausses ou à nuancer (F1, F2, F8, F9, F10, F12).
- 33 findings : 1 bloquant, 14 majeurs, 18 mineurs.
- Affirmations confirmées (pour mémoire, sans finding) : `vf-reviewer` 87 L et 9/9 instructions,
  `vf-dev-manager` 250/250 L et 46/46 (rejoué : `check-instruction-budget.sh`) ; citation
  `GP:246-248` exacte ; `software-architecture` hors preset `dev` (`plugin/_internal/presets.json:7-8`) ;
  `vf-reviewer` dispatche l'agent, pas le workflow (`vf-reviewer.md:4`, `:32`) ; `GCR:374` et
  `GCR:258-264` (duplication et code mort en Info) ; profondeur par défaut `standard` (`GCR:108`) ;
  mineur qui ne relance jamais la boucle (`MC:373-375`) ; budget de 3 tours partagé (`MF:309-316`) ;
  `gsd-code-fixer` seulement dans l'allowlist de `vf-coder` côté doctrine (`vf-coder.md:4`) ;
  Phases 46, 52, 56, 60 existent ; décision du 2026-08-28 (`.planning/workstreams/fiabilite/ROADMAP.md:1513`) ;
  aucun hook `SubagentStart` dans `plugin/` ; « aucun skill ni agent neuf » (critère 9, `ROADMAP.md:1554`).

---

## Passe 1 : fidélité

### F1. Majeur. Le régime « allégé » n'existe pas dans le DAG

**Constat.** E affirme que le « régime plein / allégé existe au DAG, jamais traduit en `depth` »
(E:175) et propose de « traduire le régime du DAG » (E:202-203). Le DAG ne porte qu'une valeur,
`full`, écrite uniquement par `reopen` ; l'allègement n'a aucun champ, c'est un choix en prose du
manager au moment de composer le mandat. De plus les deux axes tournent identiquement dans les deux
régimes : aujourd'hui « allégé » ne change rien de mesurable dans le brief.
**Preuve.** `plugin/conductor/scripts/dag.sh:24-29` (« il n'existe aucun flag pour poser un regime
allege, l'allegement reste un choix du manager au moment de composer le mandat ») ; `MC:363`
(« Les deux axes tournent en régime plein comme allégé »).
**Correction.** Écrire : « le régime plein est un champ machine (posé par `reopen`), l'allégé est
une décision du manager sans trace machine ». QCT-03 (a) exige donc soit un champ nouveau dans
`dag.sh` (gate touché, G-2), soit une ligne de mandat écrite par `vf-dev-manager` (marge 0). À
chiffrer comme tel.

### F2. Majeur. `fallow` n'est pas « dans le moteur » ni « gratuit »

**Constat.** E présente `fallow` comme « existe dans le moteur » (E:174) et le pré-passage comme
« gratuit et sans jugement » (E:205). Le moteur ne contient que le **câblage** ; `fallow` est un
binaire tiers à installer dans chaque lab (`npm install -D fallow` ou `cargo install fallow`).
Il est absent du poste. La résolution passe par `node_modules/.bin` d'abord : indice fort d'un
outil de l'écosystème JS/TS ; le moteur ne documente aucune couverture de langage. Le pré-passage
écrit `FALLOW.json` dans le dossier de phase, ce qu'un juge en lecture seule ne doit pas faire.
**Preuve.** `~/.claude/gsd-core/workflows/code-review/steps/structural-pre-pass.md:3`, `:12-18`,
`:24` ; `~/.claude/gsd-core/bin/lib/fallow-runner.cjs:32` (`prependPaths: node_modules/.bin`) ;
`which fallow` rend « fallow not found » ; `config-schema.manifest.json:44-47` (clés seules).
**Correction.** Remplacer par « le moteur sait injecter un pré-passage `fallow` si le binaire est
installé (dépendance tierce, par lab, couverture de langage inconnue) ». Cela heurte l'en-tête de
§3 (« aucune dépendance », E:181-182) : soit l'assumer explicitement, soit sortir (b) de QCT-03.

### F3. Majeur. La preuve externe de QCT-01 est surcotée

**Constat.** QCT-01 est noté « preuve moyenne (Pocock 5/7 utiles ; règles convergentes dans 4
variantes) » (E:272). Le 5/7 de Pocock porte sur la grille thermo-nuclear entière, pas sur les
règles d'hygiène de QCT-01 ; c'est en outre une source secondaire, vidéo non visionnée, caveat
présent dans A3 et perdu dans E:141. Par l'échelle d'E elle-même (E:266-268 : « moyenne = mesure de
l'auteur ou usage réel tracé »), « règles convergentes dans des textes » vaut **faible**.
**Preuve.** A3:138 (« Source secondaire, vidéo non visionnée ») ; E:266-268.
**Correction.** Noter QCT-01 « faible (convergence textuelle) » et rétablir le caveat en §1.3. Le
levier « élevé » doit alors s'appuyer sur le coût quasi nul, pas sur la preuve.

### F4. Majeur. Le résultat Ponytail sur les tests est cité à moitié

**Constat.** E retient « tests moins bons (69 % contre 77 %) » (E:84-85, E:275) sans dire que, dans
le même benchmark, un test est présent quand il le faut dans 98 % des cas contre 68 %, et que les
bugs injectés sont détectés à 66 % contre 46 % sur l'ensemble. Le risque « tests moins bons » de
QCT-04 est donc présenté plus lourd que la source.
**Preuve.** A1:169 (« 98 % des cas contre 68 % ; bugs injectés détectés 66 % contre 46 % sur
l'ensemble des cellules, mais 69 % contre 77 % là où un test existe »).
**Correction.** Citer les trois chiffres : « plus souvent un test, mais un test plus faible ».

### F5. Majeur. La preuve JetBrains ne porte pas sur le mécanisme de QCT-04

**Constat.** QCT-04 est noté preuve « forte » (E:275) et « −10 % de coût attendu ». JetBrains a
mesuré v4.8.4 (sans carte du code), en injection `SessionStart` dans le fil principal, Sonnet 5,
et le −10,3 % porte sur les **tokens de sortie**. QCT-04 injecte ~850 tokens **d'entrée** dans
chaque sous-agent exécuteur via `SubagentStart`, à côté de `tdd.md` (330 lignes) déjà injecté :
ni le canal, ni la métrique, ni le contexte ne sont ceux mesurés.
**Preuve.** A1:182-187 ; A1:205 (coût permanent par sous-agent) ; `GP:277-279` (`tdd.md` injecté
sans condition).
**Correction.** Noter « moyenne, transfert non démontré » et retirer « −10 % attendu » ; garder
« le signe de l'effet sur la sortie est indépendamment confirmé pour Claude ».

### F6. Mineur. Issue #126 mal résumée

**Constat.** « un prompt YAGNI de sept mots faisait presque aussi bien » (E:87-88). Le prompt
d'Eberhardt était « Provide just one example [...] no commentary » et ramenait la référence à 16
lignes contre 8,25 pour Ponytail (le double). « YAGNI de sept mots » est la formule d'InfoQ.
**Preuve.** A1:174, A1:191.
**Correction.** « un prompt système d'une phrase réduisait la référence de 108 à 16 lignes (8,25
pour Ponytail) ».

### F7. Mineur. Le « bug de chargement » fusionne deux constats différents

**Constat.** E:147-150 attribue la paraphrase de 40 mots aux « deux mainteneurs ». Seul nicknisi
l'a constatée ; pstack-claude a constaté un **refus** net d'invocation par l'outil Skill.
**Preuve.** A3:145-146.
**Correction.** Séparer : « invisible au modèle (nicknisi : repli silencieux sur une paraphrase) ;
refus d'invocation (pstack-claude) ».

### F8. Majeur. « La doctrine KISS/YAGNI n'atteint pas le relecteur » est faux en général

**Constat.** Le verdict (E:32-33) et §2 (E:165) disent que KISS/YAGNI n'atteint ni l'exécuteur ni
le relecteur. `gsd-code-reviewer` lit lui-même `CLAUDE.md` et les `SKILL.md` de `.claude/skills/`
du projet : dans un lab où `software-architecture` est installé en scope projet (preset
`dev-audite`), le relecteur voit KISS/YAGNI. Le trou est réel pour le preset par défaut, pas
universel.
**Preuve.** `GCR:41-50` ; A4:171-172 (même constat dans l'annexe, perdu dans E) ;
`presets.json:17-20`.
**Correction.** « ... n'atteint pas l'exécuteur, et n'atteint le relecteur que si
`software-architecture` est installé en scope projet (hors preset `dev`) ».

### F9. Mineur. `guard-file-size.sh` n'est pas un seuil « absolu »

**Constat.** E:168 oppose le seuil absolu de VibeFlow au seuil « sur le delta » de Thermo. Pour un
`Edit`, le garde autorise toute édition qui n'agrandit pas et ne refuse que celle qui agrandit un
fichier jusqu'à ≥ 300 lignes : c'est déjà une règle de croissance, proche du « franchissement » de
Thermo. Le critère « le diff fait franchir 300 lignes » de QCT-02 (E:199-200) fait donc doublon
partout où le module est installé.
**Preuve.** `plugin/software-architecture/scripts/guard-file-size.sh:14-18`.
**Correction.** Verdict « partiel (croissance gardée à l'écriture si module installé) » et
limiter le critère de QCT-02 aux labs sans le module, ou le retirer.

### F10. Mineur. « Brief à champs obligatoires, refus de lancer » n'est pas convergent

**Constat.** E:161 classe « convergent ». Le digest est un **plafond** (≤ 30 lignes), pas un
contrôle de complétude ; rien ne refuse de lancer un worker sur champ manquant. Le seul refus
existant est côté récepteur (PLAN absent → axe Spec `blocked`).
**Preuve.** `MC:51-64` ; `MC:391-394`.
**Correction.** « partiel : champs fixés, aucun refus de lancer ».

### F11. Mineur. La grille amont a deux échelles, pas une

**Constat.** QCT-01 (6) prévoit Critical/Warning/Info → bloquant/majeur/mineur. `GCR` impose aussi
BLOCKER/WARNING dans sa posture (sans Info) et accepte `blocker:` / `BL-` comme équivalents de
Critical.
**Preuve.** `GCR:32-35`, `GCR:240-264`, `GCR:301`.
**Correction.** La table de QCT-01 doit couvrir `BLOCKER`, `BL-`, `CR-`, `WR-`, `IN-`.

### F12. Mineur. « stdlib : 0 occurrence » est approximatif

**Constat.** Deux occurrences existent dans `plugin/` (hors sens doctrine).
**Preuve.** `plugin/skill-creator/skills/skill-creator/eval-viewer/generate_review.py:12`, `:285`.
**Correction.** « 0 occurrence au sens d'une consigne de code ».

### F13. Mineur. « 4 relecteurs par défaut » vaut pour le portage

**Constat.** E:117 l'attribue à pstack sans préciser ; c'est le portage Claude Code.
**Preuve.** A2:235.
**Correction.** « (portage) ».

### F14. Mineur. ADR-074 mal mobilisé, et contredit par un hook existant

**Constat.** QCT-04 se dit « non bloquant par construction (ADR-074) » (E:214) : ADR-074 classe des
**gates**, une injection de contexte n'en est pas un. Et §4 écarte « un hook bloquant de sobriété »
au motif qu'un jugement de qualité n'est « jamais à un hook » (E:245-246), alors que
`guard-file-size.sh` est un hook **bloquant** de qualité (antérieur à ADR-074, ADR-035/043). Le
lecteur à froid y verra une contradiction non traitée.
**Preuve.** `docs/ADR.md:2824-2914` (objet : les gates) ; `plugin/software-architecture/hooks/hooks.json`
(description : « entrée BLOQUANTE ... permissionDecision: deny »).
**Correction.** Citer ADR-031 pour QCT-04 ; en §4, nommer l'exception du garde de taille et dire
pourquoi elle ne fait pas précédent.

---

## Passe 2 : audit adverse des bénéfices

### B1. Bloquant. QCT-02 contredit la règle amont, et QCT-01 annule QCT-02

**Constat.** Deux problèmes qui se cumulent.
1. Le relecteur délégué porte dans son prompt système « DO NOT flag style preferences as warnings.
   Only flag issues that cause or risk bugs » et classe duplication et code mort en **Info**. Une
   abstraction à une seule implémentation ou une option jamais passée ne « risque pas de bug » : par
   construction, la grille amont les rend en Info ou les tait. Un brief en prompt utilisateur qui
   demande l'inverse crée un conflit d'instructions au résultat imprévisible. Le précédent POCK-04
   ne vaut pas : l'axe Spec change l'**objet** jugé, il ne contredit aucune règle critique.
2. QCT-01 (6) fixe « Info → mineur », et un mineur ne relance jamais la boucle. Si la grille rend
   la sobriété en Info, QCT-02 produit des mineurs : le trou principal (« un diff sur-construit
   passe `passed` ») **reste ouvert**. Les « blocages présomptifs (majeur) » de QCT-02 n'ont aucun
   chemin pour devenir majeurs.
**Preuve.** `GCR:374`, `GCR:258-264` ; `MC:373-375` ; E:189-190 contre E:199-201.
**Correction.** Trancher avant tout chiffrage : (a) une exception écrite dans la table de QCT-01
(« axe Sobriété : un blocage présomptif est majeur quelle que soit la sévérité amont »), **et** une
sonde qui montre que `gsd-code-reviewer` obéit au brief contre sa règle `:374` ; ou (b) un relecteur
dont la grille n'interdit pas la sobriété (changement d'allowlist de `vf-reviewer`, test T19
`REVIEWER_ALLOWED` à modifier). Sans l'un des deux, QCT-02 coûte +50 % pour des mineurs.

### B2. Majeur. Le coût de QCT-02 ne compte que les dispatchs

**Constat.** « +1 dispatch ≈ +50 % de tokens de revue » (E:273) est juste au dispatch près (2 → 3
briefs, chacun relit `CLAUDE.md` et les skills du projet). Mais le coût dominant est ailleurs :
chaque majeur de sobriété consomme un tour du budget de 3 **partagé** avec test et audit, puis une
re-revue à trois axes. Ajouter aussi les nœuds `join-N` et les revues d'implémentation des missions
design. Enfin le plafond de 5 constats contredit la posture amont « Find every bug ».
**Preuve.** `MF:309-316` ; `MC:363` (le doublement à deux axes a été « assumé » sans mesure, Q6) ;
`GCR:12`, `GCR:23`.
**Correction.** Coût = +50 % par revue + (taux de majeurs de sobriété × coût d'un tour complet) ; le
second terme est inconnu et c'est lui que le rejeu QCT-06 doit mesurer, avec le taux d'épuisement
du budget comme critère d'arrêt.

### B3. Majeur. QCT-01 et QCT-02 posent du texte que le juge ne lit jamais

**Constat.** Les deux emprunts écrivent dans `mission-contracts.md`. Ce fichier est lu par
`vf-reviewer`, et seulement pour statut, seuil et `skipped`, « à appliquer sans les recopier ».
`gsd-code-reviewer` ne le lit jamais. Pour atteindre le juge, il faut que `vf-reviewer` recopie un
bloc nommé dans chaque brief : c'est une instruction nouvelle dans un agent à marge 0. C'est
exactement la leçon que l'étude tire de Ponytail (« un skill passif ne s'active jamais ») appliquée
à elle-même. « 0 instruction d'agent » (E:272) n'est pas démontré.
**Preuve.** `vf-reviewer.md:77` ; `GCR:38-53` (contexte lu : `CLAUDE.md`, skills, rien d'autre).
**Correction.** Nommer le canal (« `vf-reviewer` joint le bloc `Hygiène` de `MC` §Étage revue à
chaque brief ») et la compensation d'une instruction dans `vf-reviewer.md`, ou l'arbitrage G-1.

### B4. Majeur. QCT-03 (a) : la correspondance proposée casse la revue

**Constat.** `quick` ne lit pas les fichiers : grep de secrets, `eval`, `console.log`, catch vide.
Mapper « allégé → quick » supprime l'axe Spec (diff contre PLAN) et presque tout l'axe Standards.
« plein → deep » vise 15 à 30 minutes par brief, et `reopen` force `full` : toute re-revue après
correction passerait en `deep`, deux ou trois fois en parallèle. S'ajoute F1 (pas d'allégé machine).
Le levier « très élevé » (E:274) n'est pas soutenu.
**Preuve.** `GCR:73-80`, `GCR:91`, `GCR:197-213` ; `dag.sh:36`, `:409`.
**Correction.** Allégé → `standard`, plein → `standard`, `deep` réservé aux quatre déclencheurs de
revue renforcée (`MF` §3, (a) à (d)) ; ou abandonner (a) faute de régime allégé machine.

### B5. Majeur. QCT-03 (b) : le coût réel de `fallow`

**Constat.** Voir F2. Pour l'obtenir sans le workflow, `vf-reviewer` devrait résoudre le binaire,
lancer `fallow audit`, normaliser le JSON et l'injecter : procédure nouvelle dans un agent à marge 0,
écriture d'un fichier par un juge lecture seule, nouvelle clé de config GSD à faire arbitrer par
`check-gsd-config.sh` (qui n'arbitre que cinq toggles, gate touché donc trailer G-2), dépendance par
lab. Pour les labs Swift ou Python, gain probablement nul.
**Preuve.** `structural-pre-pass.md:3-24` ; `code-review.md:548-555`, `:730-746` ;
`plugin/dev-orchestrator/scripts/check-gsd-config.sh:339`.
**Correction.** Ramener (b) à une sonde : installer `fallow` sur un lab TS, mesurer ce qu'il
remonte sur trois diffs passés, puis décider. Levier « inconnu ».

### B6. Mineur. QCT-03 (c) : l'allowlist « honnête » est cosmétique

**Constat.** Le dépôt a mesuré que l'allowlist `Agent(...)` n'est pas appliquée à l'appel ; retirer
`gsd-code-fixer` ne change aucun comportement. Le retrait casse le test T19 qui énumère l'allowlist.
Et le fixer reste joignable par le moteur (`/gsd-code-review --fix`).
**Preuve.** `MC:307-308` ; `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:2209-2213` ;
`~/.claude/gsd-core/workflows/code-review/steps/dispatch-fix.md:1-30`.
**Correction.** Garder (c) comme ménage, coût « une ligne + T19 », bénéfice « lisibilité », sans
l'inclure dans le levier « très élevé ».

### B7. Majeur. QCT-04 : faisable sur le papier, mais six obstacles non chiffrés

**Constat.** Un matcher `SubagentStart` sur `^gsd-executor$` est faisable et peut exclure les juges :
`agent_type` vaut le `name:` du frontmatter, et les agents VibeFlow et GSD apparaissent sans préfixe.
Mais :
1. **Chemin réel.** `GP` interdit de présenter le canal exécuteur comme résolu sans prouver que
   l'exécuteur est bien **dispatché** : sur le repli inline, aucun `SubagentStart` ne part. Un hook
   sur `gsd-executor` peut être le même « vert à vide ».
2. **Collision absente de §8 : Phase 45** (Willy, « hook central par rôle » qui lit `agent_type`).
   Un second hook par rôle, ailleurs, avant elle, est la collision la plus forte de l'étude.
3. **Doctrine des hooks.** Inventaire asserté à 31 entrées, forme exec, un seul objet JSON encodé,
   trailer Gate-Touche, purge d'idempotence de `merge-hooks.sh`. Le coût « nouveau hook » (E:275)
   ignore tout cela.
4. **Conflit d'instructions** dans le prompt exécuteur : « Trivial changes need none » et « one
   small test » contre `tdd.md` injecté sans condition.
5. **Portée.** Opt-in dans `software-architecture`, hors preset `dev` : le trou reste ouvert pour
   le lab par défaut.
6. **Phase 56** (rules path-scopées, hooks `Stop`) n'a pas de hook `SubagentStart` : « fondre dans
   la 56 » change son périmètre.
**Preuve.** `GP:250-262` ; `.planning/workstreams/gouvernance/phases/VFDO-45-*/45-SCOUTING.md:26-28` ;
`docs/HOOKS-CONTRAT-SORTIE.md:85`, `:54-67` ; `CLAUDE.md:120-123` ; `GP:277-279` ;
`ROADMAP.md:1855-1862`.
**Correction.** Reclasser QCT-04 en **spike** : (1) sonde du chemin (l'exécuteur est-il dispatché
sur `revue-N` réel ?) ; (2) arbitrage avec Willy sur la Phase 45 ; (3) A/B QCT-06 avant tout hook.
Ajouter Phase 45 à §8.

### B8. Majeur. Aucun emprunt ne dit ce qu'il retire

**Constat.** La doctrine exige que chaque ajout nomme ce qu'il remplace ou resserre (SOBR-05,
critère 9 de la 41.4 ; trailer `Ajout-Retrait` avec retrait ou « aucun : justification »). E décrit
huit ajouts (un axe, un hook, des champs, une table, un protocole) et zéro retrait. §5.3 (défaillance
observée) est en attente, mais le retrait est une question indépendante.
**Preuve.** `ROADMAP.md:1554` ; `plugin/conductor/scripts/check-ajout-retrait.sh:1-40`.
**Correction.** Une ligne « Retire » par emprunt. Pistes : QCT-01 retire la conversion de sévérité
laissée au modèle ; QCT-02 resserre « smells » de l'axe Standards (`MC:357`) au lieu de l'ajouter
à côté ; QCT-03 (c) retire `gsd-code-fixer` ; QCT-04 « aucun : justification » à écrire ; QCT-05
remplace une ligne existante du digest au lieu d'en ajouter une.

### B9. Majeur. QCT-05 : le pointeur n'atteint pas l'exécuteur, la carte va dériver

**Constat.** Le digest va à `vf-coder`, pas à `gsd-executor` ; le dépôt écrit lui-même que le
digest « ne peut structurellement pas porter la doctrine » jusqu'à l'exécution. Et la Phase 60 est
une validation d'`ARCHITECTURE.md` **avant découpage**, ponctuelle ; la carte de Ponytail est
régénérée à chaque session. Une section « helpers » dans un document validé une fois dérive dès la
première étape (risque nommé en E:276, mais le levier reste « élevé »).
**Preuve.** `GP:264-270` ; `ROADMAP.md:1958-1960`.
**Correction.** Levier « faible tant que le canal exécuteur n'est pas prouvé » ; ou bien une carte
régénérée mécaniquement (`gsd-map-codebase` au cadrage d'étape) plutôt qu'une section rédigée.

### B10. Mineur. QCT-06 : « diffs dont on connaît le devenir » n'existe pas

**Constat.** E:222-223 propose de rejouer QCT-02 sur des diffs « dont on connaît le devenir ». E
dit aussi qu'on ne sait pas « ce qui passe `passed` et revient plus tard » (E:257-259) : il n'y a
pas d'étiquette de vérité. Construire ce gold set est le vrai coût. Et la Phase 52 mesure l'usage
et le coût, pas le rendement d'une consigne : « fondre » change son objet.
**Preuve.** E:257-259 ; `ROADMAP.md:1762-1767`.
**Correction.** Version minimale réaliste : 10 à 20 diffs passés étiquetés à la main par Samuel ou
Willy (sur-construit oui/non), puis rejeu ; le dire, et chiffrer l'étiquetage.

### B11. Majeur. Emprunt manquant : la qualité des tests

**Constat.** Trois sources signalent un angle mort sur les tests : pstack (« would it still pass if
every function it imports returned `undefined` », « prefer no new test over a bad test »), bangle-io
(catégorie qualité des tests), Pocock sur Thermo (« pas d'attention aux tests »). Ponytail dégrade
la profondeur des tests (F4). Côté VibeFlow, la grille amont exclut les fichiers de test sauf
fiabilité, et l'axiome 2 est « filet de tests fonctionnel avant tout ». E n'en parle ni en §2 ni en
§4.
**Preuve.** A2:188-189 ; A3:127, A3:138, A3:161 ; `GCR:376` ; A4:181-182.
**Correction.** Ajouter une ligne d'équivalence « qualité des tests → trou » et soit un emprunt
(question de mutation mentale dans le brief Standards), soit un écarté motivé. Si QCT-04 avance,
cet emprunt en devient le contrepoids obligatoire.

### B12. Mineur. Emprunt manquant : relire les appelants (rayon d'impact)

**Constat.** Ponytail-review, NikolasP98 et `/blast-radius` exigent de relire les appelants d'une
fonction dont la signature ou le comportement change. En `standard`, la grille amont ne trace pas
les appelants (seulement en `deep`). Un axe qui pousse à supprimer et fusionner rend ce contrôle
plus nécessaire.
**Preuve.** A1:136, A1:244-245 ; A3:116 ; `GCR:82`, `GCR:91-98`.
**Correction.** L'ajouter à QCT-01 (une règle de brief) ou le noter en écarté.

### B13. Mineur. Emprunt manquant : « sauté / non vérifié » côté exécuteur

**Constat.** La clôture « ce que j'ai sauté ou pas vérifié » est le principal gain mesuré de
Ponytail v5 (préférence du juge). QCT-01 (5) n'en prend que la face relecteur.
**Preuve.** A1:125, A1:241-242.
**Correction.** Mentionner la face exécuteur (rapport de `vf-coder`), même pour l'écarter.

---

## Passe 3 : lisibilité (lecture à froid par Willy)

### L1. Mineur. Chaque emprunt est décrit à quatre endroits
§2 (équivalence), §3 (description), §5.2 (audit), §8 (collisions) : il faut quatre allers-retours
pour comprendre QCT-03. **Correction** : une fiche par emprunt (quoi, où, retire, coût, preuve,
collision, levier), §2 garde la table d'équivalences seule.

### L2. Mineur. La table §5.2 est illisible en Markdown
Sept colonnes, cellules de trois lignes, échelle « Levier » hétérogène (« élevé si mesuré »,
« stratégique », « selon §6 »). **Correction** : une échelle ordinale unique (fort / moyen / faible
/ inconnu) et la condition dans la fiche.

### L3. Mineur. Le verdict n'est pas en 6 lignes et mélange les plans
Le « Verdict en 6 lignes » (E:24-33) fait 8 lignes, donne des chiffres de Ponytail mais pas l'ordre
d'action. **Correction** : 4 lignes : le trou, les 2 emprunts à faire d'abord, ce qu'on attend de
mesurer, ce qu'on n'installe pas.

### L4. Mineur. §1 pèse plus que la décision
~115 lignes sur les sources contre ~50 sur les emprunts ; les tableaux d'identité (étoiles,
commits, contributeurs) ne servent pas la décision et sont déjà dans A1 à A3. **Correction** : les
renvoyer en annexe, garder mécanisme, preuves, limites.

### L5. Mineur. Les lots arrivent trop tard
« 8 emprunts, 3 lots » (E:33) n'est expliqué qu'en §5.4. **Correction** : remonter l'ordre (lot A,
B, C) juste après le verdict.

### L6. Mineur. Jargon sans glose pour une lecture à froid
E6, Pattern C, P414-D-20, G-1, « Pocock, 41.4 », « agent-book gap 2 » apparaissent sans renvoi.
Willy les connaît probablement, mais pas dans six mois. **Correction** : un renvoi `fichier:ligne`
à la première occurrence, ou cinq lignes de glossaire en fin de document.

---

## Ce qui tient (pour équilibre)

- Le diagnostic central « un diff sur-construit mais correct passe `passed` » est cohérent avec
  `GCR:258-264` et `MC:373-375`, sous réserve de F8 (preset) et de §5.3.
- L'écart du recoupement pondéré de Thermos (contraire à POCK-04) et le refus d'installer les trois
  plugins sont bien fondés.
- Lier la livraison de QCT-02 à une mesure (lot B) est la bonne décision ; B1 et B2 disent quoi
  mesurer.
