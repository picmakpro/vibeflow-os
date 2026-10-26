# Étude — Ponytail, pstack, thermo-nuclear review : ce que VibeFlow peut emprunter pour la qualité du code (2026-10-10)

**Demande** : Samuel, session principale, 2026-10-10 — « rédige un rapport complet des frameworks
[Ponytail, pstack, thermonuclear] ; ensuite le but sera de l'appliquer à VibeFlow ; ajoute-le au
backlog avec un audit poussé des bénéfices ». Aucune veille antérieure sur ces sources (mémoire
`veilles-plugins-tiers`, `.planning/research/`, `reports/research/`, BACKLOG : vérifié le même jour).

**Méthode** (7 agents, rapports bruts en annexe `2026-10-10-qualite-code-tiers/`) :

| Annexe | Contenu |
|---|---|
| `A1-ponytail.md`, `A2-pstack.md`, `A3-thermo-nuclear-review.md` | un lecteur par source : clone en lecture seule, lecture intégrale des skills, hooks, agents, manifestes, benchmarks ; sources primaires des évaluations ; aucun script tiers exécuté |
| `A4-inventaire-qualite-vibeflow.md` | tout ce que VibeFlow v2.69.0 fait pour la qualité du code produit par les agents, `fichier:ligne` |
| `A5-defaillances-observees.md` | chasse aux **défaillances observées datées** dans l'historique du dépôt (exigence POCK-08), emprunt par emprunt |
| `A6-chargement-silencieux.md` | vérification du risque « grille non chargée, revue faite de mémoire » contre POCK-07 |
| `A7-relecture-adverse.md` | relecture adverse du premier jet (1 bloquant, 14 majeurs, 18 mineurs) ; sort de chaque finding au §7 |

Format : celui des veilles tierces (source mesurée → équivalences → emprunts → écartés →
collisions), plus l'audit des bénéfices demandé (§5). Glossaire des sigles internes en fin de
document.

---

## Verdict

1. **Rien à installer.** Ponytail est un prompt, pstack un catalogue, la thermo-nuclear une grille ;
   les trois injectent ou routent d'une façon qui heurte le team-kernel (§4).
2. **Le trou VibeFlow le mieux prouvé n'est pas la sur-ingénierie, c'est l'honnêteté du vert** :
   des `passed` rendus sur un périmètre implicite (2026-07-28, 2026-08-16 ×2) et une grille de
   revue bruitée (6 faux positifs sur 15, ancres décalées de +437 lignes). Les sources tierces ont
   des remèdes simples et convergents pour les deux.
3. **À faire d'abord (lot A, une phase courte)** : un bloc « hygiène » joint à chaque brief de
   revue + un champ `non_verifie` obligatoire — QCT-01, 02, 03, 04. Coût : 1 à 2 instructions dans
   `vf-reviewer` (marge 0, arbitrage G-1 requis) et ~30 lignes de référence.
4. **La sobriété (code mort, abstraction inutile, code judo) se traite en audit périodique, pas en
   revue de diff** : c'est là qu'elle a été trouvée (audit du 2026-07-25), et l'axe de revue
   contredit la règle amont du relecteur (QCT-05, lot B).
5. **L'échelle de réutilisation de Ponytail à l'exécution reste un spike** (QCT-07) : seul
   mécanisme mesuré indépendamment, mais le transfert à notre harnais n'est pas démontré et il
   percute la Phase 45 de Willy.
6. **Limite de fond** : le défaut dominant du dépôt est un vérificateur incapable de rendre rouge,
   trouvé par exécution, presque jamais par relecture (A5). Tout emprunt de lecture a une portée
   bornée ; aucun ne remplace la mutation rouge (QUAL-01).

---

## 1. Les trois sources

### 1.1 Ponytail — `DietrichGebert/ponytail` (A1)

MIT, créé le 2026-06-12, v5.1.0 le 2026-10-08, 315 commits, 110 contributeurs, **159 666
étoiles** (API GitHub, 2026-10-10). Accroche : « Makes your AI agent think like the laziest senior
dev in the room ». Le cœur est **un prompt** de ~850 tokens (`skills/ponytail/SKILL.md`) ; « everything
else in this repo loads that prompt into different agents » (`README.md:122`).

**Composants** : 6 skills (`ponytail`, `-review`, `-audit`, `-debt`, `-gain`, `-help`), 0 agent,
3 hooks Claude Code — `SessionStart` (ruleset + **carte du code** de 2 000 caractères : exports par
dossier, modules partagés en premier, « what already exists; reuse it »), `SubagentStart` (même
ruleset dans chaque sous-agent, filtrable par `PONYTAIL_SUBAGENT_MATCHER`), `UserPromptSubmit`
(niveaux lite / full / ultra).

**L'échelle à arrêt précoce** (`SKILL.md:25-32`) : « Take the first option that fully works » —
(1) est-ce nécessaire ? (2) existe-t-il déjà dans ce dépôt ? (3) bibliothèque standard ou
plateforme ? (4) dépendance déjà installée (« never add a dependency for a few lines ») ? (5) une
ligne lisible ? (6) sinon le minimum. La marche 2 a été ajoutée après l'issue #217 : les autres ne
visaient que du code extérieur au projet.

**Contrepoids** : « Never cut: validation at trust boundaries, error handling that prevents data
loss, security, accessibility […] anything the user asked for » (`:44`) ; test minimal obligatoire
sur toute logique non triviale (`:41`) ; « a one-liner that needs decoding is not short » (`:36`) ;
bug = grep de tous les appelants puis cause racine une fois, **présentée comme le plus petit diff**
pour que l'instinct du skill y pousse (`:38`) ; fin de réponse obligatoire sur « what you skipped
or did not check, and any risk » (`:15`).

**`ponytail-review` / `-audit`** : priorité « correct, safe, holds under load, tested, fast, lean » ;
« **No case, no finding** » ; « no style taste, no "consider", no vague worries » ; relire les
appelants de toute fonction dont la signature ou le comportement change ; constats numérotés
Must / Should / Nice en quatre temps (quoi / problème / correctif / si on ne fait rien), verdict,
`Lean: -N lines possible`, **`Not checked:`**. L'audit ajoute « map first », « before calling code
unused, grep the whole tree », 20 constats maximum. `ponytail-debt` récolte les commentaires
`shortcut: <limite>, <quand revoir>`.

**Gouvernance du prompt** : toute retouche passe un A/B à trois bras (sans skill / main / branche),
n ≥ 6, avec une tâche que la retouche pourrait casser ; 8 retouches testées puis abandonnées faute
d'effet (`.github/CONTRIBUTING.md:9-29`).

**Preuves — les seules des trois sources** :

| Mesure | Code | Coût | Qualité | Statut |
|---|---|---|---|---|
| Auteur, v5, Opus 5.5, 39 tâches × 5 runs, Bash désactivé | −53 % | −26 % | égalité (87/90 vs 86/90) | non répliqué |
| **JetBrains** (Shiryaev, juillet 2026), **v4.8.4** (sans carte), Sonnet 5, 80 tâches, injection `SessionStart` | −15,4 % (p = 0,088, **ns**) | **−10,3 % des tokens de sortie (p = 0,004)** | indistinguable | indépendant |
| Auteur, modèles OpenAI | — | **+26 à +39 %** | — | gain propre à Claude |

Constats qui comptent plus que les pourcentages : (a) JetBrains — installé en skill passif, il
s'est auto-activé **zéro fois sur dix sessions** ; seul le hook produit l'effet. (b) Tests : un
test est présent quand il le faut dans 98 % des cas contre 68 %, les bugs injectés sont détectés à
66 % contre 46 % sur l'ensemble, **mais à 69 % contre 77 % là où un test existe** — plus souvent un
test, mais un test plus faible. (c) Le juge aveugle ne préfère **pas** les réponses avec skill.
(d) L'auteur a corrigé ses premiers chiffres (−80 à −94 %) après l'issue #126 de Colin Eberhardt :
un prompt système d'une phrase ramenait la référence de 108 à 16 lignes (8,25 pour Ponytail).

### 1.2 pstack — `cursor/plugins/pstack` (Lauren Tan) et portage `michael-denyer/pstack-claude` (A2)

Original : plugin Cursor, MIT, v0.15.15, 100 commits du 2026-05-23 au 2026-10-06, 97 % d'une seule
autrice (désormais chez xAI) ; il n'existe pas de dépôt `poteto/pstack`. Portage Claude Code : MIT,
v0.9.81, 236 commits, **1 727 étoiles**, 74 règles de substitution Cursor → Claude, ~45 forks
déclarés, hook `SessionStart` qui route vers `poteto-mode`. **Ne pas confondre avec gstack**
(Garry Tan, 135 741 étoiles), setup organisé par rôles (CEO, QA, release).

**Contenu** : 27 skills, 24 principes d'une règle chacun, 23 playbooks, 2 agents, ~430 Ko de
Markdown. Le routeur `/poteto-mode` choisit un playbook et **recopie ses étapes verbatim dans la
todo** ; une étape sautée reste avec `skip: <raison>`. Imposé à l'agent : comprendre avant d'agir
(`/how`, `/why`), nommer la forme des données d'abord, **délégation obligatoire du code** à un
sous-agent (« the gain is review separation, not lines saved »), vérification sur la vraie surface,
PR « briefing », babysit puis shipping séparés.

**Mécanismes de preuve** : verdict ternaire « VERIFIED / NOT VERIFIED / INCONCLUSIVE — inconclusive
is not a pass » ; « safe means a verdict from an agent that did not write the code. CI green is not
a verdict », verdict lié au `git patch-id`, « a new head SHA voids the row » ; échelle de certitude
« 1. You said so. Worthless […] 4. You ran it. 5. You reproduced it in the running app » ; journal de
décisions append-only relu par une autre famille de modèle ; brief de délégation à 9 champs,
« missing fields are a refuse-to-spawn condition » ; `/interrogate`, revue multi-modèles (« if your
Act On list has more than 5 items, you're not filtering hard enough », section **Dismissed**
visible comme « trust mechanism ») ; `/correct` : architecture > types > lint > test > doc,
« prove each new check fails on a real past mistake » ; tests : « would it still pass if every
function it imports returned `undefined`? », « prefer no new test over a bad test ».

**Preuves** : **aucune mesure publiée**. Retour indépendant (Flavio Copes, 2026-09-29) : solide pour
le travail profond et auditable, disproportionné et coûteux sur les petites tâches. **Risques** :
5 à 7 k tokens pour le seul routeur ; 4 relecteurs par défaut (portage) ; hook de routage qui
revendique les tâches multi-fichiers contre Superpowers / GSD / VibeFlow ; deux mainteneurs.

### 1.3 Thermo-nuclear code quality review — `cursor/plugins` (A3)

Une **grille** de ~2 100 mots, pas une procédure. Premier commit public le 2026-05-21 (Eric
Zakariasson, Cursor), qui « ports » une rubrique interne (prompt de l'action « Improve code
quality » + règles de Sualeh + skill interne `lukas-pr-review`) ; texte inchangé depuis. Le
2026-05-27, le plugin **Thermos** l'associe à `thermo-nuclear-review` (correctness, sécurité, devex,
fuite de feature flags) et à un orchestrateur qui lance les deux en parallèle. Copies : pstack-claude
(rapport en couches), nicknisi (collecte du diff, fail-closed), ironclaw (sans attribution),
bangle-io (réécriture condensée, la meilleure), NikolasP98 (revue correctness **différente** sous le
même nom — collision).

**Contenu** : huit standards — **code judo** (« restructurings that preserve behavior while making
the implementation dramatically simpler […] inevitable in hindsight »), fichier que la PR fait
passer de < 1 000 à > 1 000 lignes, croissance spaghetti (« a design problem, not a stylistic
nit »), code ennuyeux plutôt que magique, types et frontières, couche canonique et réutilisation des
helpers existants, orchestration séquentielle inutile. Six **blocages présomptifs** levés seulement
par justification de l'auteur ; « do not approve merely because behavior seems correct » ; critère
anti-faux-progrès : « refactors that move code around but fail to reduce the number of concepts a
reader must hold in their head ». Apports des variantes : « if you can't explain how it breaks, it's
not a finding », « inventing line numbers — verify against the actual file » (NikolasP98) ;
« NEVER present issues with unfinished research », lire les autres relecteurs seulement **après**
son audit (Thermos) ; « assign severity based on impact, not rhetorical force », « if a
restructuring is only a preference […] omit it », catégorie qualité des tests (bangle-io).

**Preuves** : **aucune éval** (tessl : « no evaluations available » ; seule une note LLM du texte,
56 à 60, concision 2/5). Matt Pocock : ~5 suggestions utiles sur 7 (source secondaire, vidéo non
visionnée). Adoption : réputée la revue la plus utilisée en interne chez Cursor (rapporté, non
vérifié) ; nicknisi : « the one review component reached for in real work ». **Limites** : présume
qu'un code judo existe « often » → faux positifs ; pas d'échelle de sévérité ni de règle « omettre
les préférences » dans l'original ; tests ignorés.

**Bug transversal** : sous Claude Code, `disable-model-invocation: true` rend un skill invisible au
modèle. nicknisi : l'agent retombait **en silence** sur sa paraphrase de 40 mots ; pstack-claude :
l'outil Skill refusait net l'invocation. Remède : retirer le drapeau, et « if that load fails, say
so and stop. Do not review from memory ».

---

## 2. Équivalences — mécanisme tiers → chez VibeFlow → verdict

| Mécanisme | Source | Chez VibeFlow (v2.69.0) | Verdict |
|---|---|---|---|
| Verdict par un agent qui n'a pas écrit le code | pstack | juges frais, `disallowedTools: Write, Edit` | **convergent** |
| Verdict lié à l'état exact | pstack | triplet E6 `{verdict, commande, exit_code, sha}` | **convergent** |
| « Inconclusive is not a pass » | pstack | `absent` plutôt que `pass`, `human_needed`, `confiance < 0.6` → `gaps_found` | **convergent** |
| Structure avant prose, check prouvé sur une erreur passée | pstack | axiome « enforcement > prose », QUAL-01 (mutation rouge), POCK-05 | **convergent** |
| Relecteurs à lentilles disjointes | Thermos, pstack | POCK-04, axes Standards / Spec jamais re-rankés | **convergent** (recoupement pondéré écarté, §4) |
| Sévérité selon l'impact, seuil de passage | Thermo (BG), pstack | P414-D-20 : axe `passed` sans bloquant ni majeur | **convergent** depuis le 2026-10-06 |
| Brief à champs obligatoires, refus de lancer | pstack | digest ≤ 30 lignes, champs fixés ; **aucun refus de lancer** sur champ manquant | partiel |
| Seuil de taille déclenché par la croissance | Thermo | `guard-file-size.sh` : un `Edit` qui n'agrandit pas passe toujours ; refus si croissance ≥ 300 L sans marqueur — **si** `software-architecture` est installé ; `.sh` exclus | **convergent** là où le module est posé |
| « No case, no finding », ligne relue, constat mesuré ≠ correction écrite de tête | Ponytail, Thermo | `ref: fichier:ligne` exigé, jamais vérifié ; aucune table de sévérités amont → VibeFlow | **trou** → QCT-02 |
| Ligne « Not checked » | Ponytail | `decompte` à l'épuisement seulement ; « qu'est-ce que ce vert ne prouve pas ? » en mémoire du manager, pas dans le format | **trou** → QCT-01 |
| Réutiliser l'existant avant d'écrire | Ponytail | doctrine en prose (ADR-069 « router, jamais forker ») ; aucune question de revue ni machine sur un nouvel entrant | **trou** → QCT-03 |
| Qualité des tests (test qui passerait à vide) | pstack, bangle-io | QUAL-01 pour les gates du dépôt ; rien dans la revue du code des labs ; la grille amont exclut les tests hors fiabilité | **trou** → QCT-04 |
| Revue de sobriété / code judo | Ponytail, Thermo | KISS/YAGNI dans `software-architecture` (lu par le relecteur **si** module installé en scope projet, hors preset `dev`) ; code mort et duplication en **Info** amont ; « DO NOT flag style preferences » | **trou** → QCT-05 |
| Fail-closed si la grille ne charge pas | Thermo (nicknisi) | pas de clause générale ; `vf-coder` remonte `blocked` ; design « ne jamais bloquer », dégradation déclarée ; `agent_skills` saute en silence un skill introuvable | **partiel** → QCT-06 |
| Échelle à arrêt précoce + carte de l'existant à l'exécution | Ponytail | rien n'atteint l'exécuteur (`GSD-PIPELINE.md:247-248`) | **trou** → QCT-07 |
| A/B à trois bras avant retouche de consigne | Ponytail | sonde réelle déjà pratiquée (POCK-04, P414-D-07), sans règle générale | partiel → QCT-08 |
| Pré-passage structurel mécanique | (moteur GSD) | câblage `code_quality.fallow` dans le moteur, binaire tiers par lab, jamais appliqué au nœud `revue-N` | → QCT-09 |
| Dette explicite `shortcut:` | Ponytail | rien côté code | → QCT-10 (réserve) |

---

## 3. Fiches d'emprunt

Forme commune à toutes (doctrine Pocock, Phase 41.4) : **discipline transcrite** dans les
références existantes, **aucun skill ni agent neuf**, **aucune dépendance** aux trois plugins.
**Canal** : un texte posé dans `mission-contracts.md` n'atteint pas `gsd-code-reviewer`, qui ne lit
que son prompt, le `CLAUDE.md` et les skills du projet (A7-B3). Les fiches QCT-01 à 04 partagent
donc **un seul canal** : `vf-reviewer` joint un bloc nommé « Hygiène » (défini une fois dans
`mission-contracts.md` §Étage revue) à chaque brief. C'est une instruction neuve dans un agent à
marge 0 : compensation dans `vf-reviewer.md` ou arbitrage G-1.

Échelle de levier unique : **fort / moyen / faible / inconnu**.

### QCT-01 — Ce que ce vert ne prouve pas (lot A)

- **Quoi** : champ `non_verifie` obligatoire dans le bloc typé de `vf-reviewer` (fichiers, chemins
  d'échec, suites hors diff, axes ou profondeur non couverts) ; un `passed` sans ce champ est
  incomplet. Face exécuteur : la même ligne dans le rapport de `vf-coder`.
- **Source** : Ponytail `Not checked:` (`ponytail-review/SKILL.md:71-99`), clôture « skipped / not
  checked » (`SKILL.md:15`), principal gain de lisibilité mesuré par le juge de v5.
- **Défaillance observée** : **solide, récidivante** — 2026-07-28, garde-fou toujours en sortie 3,
  « trois étages de vérification l'ont laissé passer » ; 2026-08-16, régression qui « a traversé six
  revues et quatre vérifications », chaque juge héritant du périmètre du mandat ; 2026-08-16, PASS
  par md5 et 4 bloquants sur le chemin d'échec (A5 §E).
- **Retire** : la consigne de mandat « qu'est-ce que ce vert ne prouve pas ? » portée en mémoire du
  manager, promue au contrat (une voix au lieu de deux).
- **Coût** : un champ de contrat, l'instruction de canal partagée.
- **Risque** : champ rempli de formules creuses ; le format seul ne garantit pas la sincérité.
- **Levier** : **fort**.

### QCT-02 — Hygiène de la grille (lot A)

- **Quoi**, dans le bloc « Hygiène » : (1) pas de constat sans cas concret (« telle entrée ou
  situation → tel mauvais résultat ») ; (2) ligne citée relue dans le fichier avant d'être rendue ;
  (3) constat mesuré séparé de la correction proposée, celle-ci marquée « non vérifiée » si le juge
  ne l'a pas exécutée ; (4) section « écartés » visible ; (5) relire les appelants d'une fonction
  dont la signature ou le comportement change ; (6) **table de correspondance écrite** des sorties
  amont (`BLOCKER`/`BL-`/`CR-` → bloquant, `WR-` → majeur ou mineur selon un critère écrit,
  `IN-` → mineur). Option mécanique (POCK-05) : contrôle qu'une `ref` pointe une ligne existante.
- **Sources** : Ponytail « No case, no finding » ; NikolasP98 « inventing line numbers » ; Thermos
  « never present issues with unfinished research » ; pstack « Dismissed » ; ponytail-review
  « grep every caller ».
- **Défaillance observée** : **solide** — 2026-07-30, 6 constats sur 15 faux positifs dont un
  « P0 » ; Phase 23 (2026-08-02), ancres décalées de +437 et +1310 ; 2026-09-15, constat juste et
  correction fausse qui aurait rendu un garde rouge en permanence ; Phase 26, 21 écarts annoncés
  pour 31 réels (A5 §D). Le seuil de sévérité (P414-D-20) est **déjà** traité.
- **Retire** : la conversion de sévérité laissée au modèle.
- **Coût** : ~20 lignes de référence ; instruction de canal partagée.
- **Risque** : faible ; ces règles vont dans le sens de la grille amont (« only flag issues that
  cause or risk bugs »), pas contre.
- **Levier** : **fort**.

### QCT-03 — Réimplémentation d'une primitive existante, cadrée comme risque de divergence (lot A)

- **Quoi** : une question du bloc « Hygiène », axe Standards : « le diff réimplémente-t-il un helper,
  un script ou une primitive qui existe déjà ? Nommer le chemin. » Cadrée comme **risque de bug**
  (deux copies divergent), elle tient dans la grille amont, qui interdit le goût mais pas le risque.
- **Source** : marche 2 de l'échelle Ponytail ; thermo standard 6 « reuse existing helpers ».
- **Défaillance observée** : **solide** — confinement de chemin codé six fois en trois langages
  alors que la primitive existait (ADR-070, 2026-08-06, récidive en Phase 27) ; recopie Python de
  `detect-gsd-engine.sh` en Phase 44 (2026-09-28), 3 divergences, 4 tours de juges (A5 §A). La
  prose existe déjà (ADR-069) et n'a pas suffi : il faut une question posée à chaque diff, pas une
  règle de plus.
- **Retire** : rien ; resserre « smells » de l'axe Standards (`mission-contracts.md:357`) au lieu
  d'ajouter à côté.
- **Coût** : 2 lignes de référence.
- **Risque** : rappel limité, le relecteur ne connaît que ce qu'il grep ; à mesurer dans la sonde.
- **Levier** : **moyen**.

### QCT-04 — Un test qui passerait à vide est un constat (lot A)

- **Quoi** : question du bloc « Hygiène » sur les tests ajoutés ou modifiés : « nommer un défaut
  plausible du code testé ; ce test le détecterait-il ? » (forme du portage pstack, plus robuste que
  « si chaque import renvoyait `undefined` »).
- **Sources** : pstack `principle-test-behavior-not-implementation`, `tdd` (« prefer no new test over
  a bad test ») ; bangle-io (qualité des tests) ; contrepoint Ponytail (tests plus fréquents mais
  plus faibles).
- **Défaillance observée** : **solide** — 2026-07-26, cas de test du bornage tautologique ;
  2026-07-28, tests qui exerçaient `--force --verify`, jamais la forme réellement émise (A5 §E) ;
  dix vérificateurs incapables de rendre rouge en Phase 39 (mémoire
  `preuve-incapable-de-rendre-rouge`).
- **Retire** : rien.
- **Coût** : 2 lignes de référence.
- **Risque** : la grille amont exclut les fichiers de test « unless they affect test reliability
  (e.g., missing assertions) » (`gsd-code-reviewer.md:376`) : un test à vide relève de cette
  exception, la question est compatible ; la sonde le confirme. Portée bornée : ce défaut est trouvé par exécution, une
  question de lecture n'en attrapera qu'une partie.
- **Levier** : **moyen**.

### QCT-05 — La sobriété en audit périodique, pas en revue de diff (lot B)

- **Quoi** : porter la lentille « sobriété » (code mort, doublons, couches sans logique, abstraction
  à une seule implémentation, option jamais passée, refactor qui déplace sans réduire le nombre de
  concepts) dans l'**audit transverse** existant (`audit-architecture`, validator), avec la méthode de
  `ponytail-audit` : cartographier d'abord, grep de tout l'arbre avant de déclarer un code mort,
  20 constats maximum, `Lean: -N lignes, -M dépendances possibles`, et **une décision par constat**
  versée au BACKLOG.
- **Pourquoi pas un troisième axe de revue** (premier jet, rejeté) : (a) bloquant A7-B1 — la grille
  amont interdit de signaler les préférences et classe duplication et code mort en Info ; un brief
  contraire crée un conflit d'instructions, et Info → mineur ne relance jamais la boucle ; (b) A5 :
  la sur-construction a été trouvée **par audit** (2026-07-25 : 30 verbes sur 36 en renommage pur,
  ~935 lignes de traduction, table de routage en 4 exemplaires), jamais par une revue de diff.
- **Code judo** : uniquement en proposition d'audit, jamais dans une étape en cours, et toujours
  avec preuve par injection de panne — le seul refactor simplificateur documenté (Phase 31,
  2026-08-16) a passé une vérification d'équivalence md5 et introduit 4 régressions bloquantes.
- **Défaillance observée** : **solide sur le fond** (audit du 2026-07-25 ; doublon `docs/reference/`
  signalé trois fois depuis juillet, toujours divergent le 2026-10-10). Le blocage observé est la
  **décision**, pas la détection : d'où « une décision par constat ».
- **Retire** : à préciser au cadrage (lentille qui se substitue à une partie de l'audit actuel).
- **Coût** : une lentille d'audit en référence ; tokens d'un audit périodique.
- **Levier** : **moyen**.

### QCT-06 — Ne jamais juger de mémoire (lot C)

- **Quoi** : (a) clause commune aux agents qui chargent une ressource **normative** (grille,
  rubric, skill de doctrine) : chargement refusé ou vide → le dire et rendre `blocked` ; la
  dégradation gracieuse du design reste pour la **production**, pas pour le **jugement** ;
  (b) `check-gsd-config.sh` vérifie que chaque entrée `agent_skills` se résout à un `SKILL.md`, le
  moteur sautant en silence ce qui ne se résout pas (`init.cjs:3693-3734` : le planner planifie alors
  sans la doctrine) ; (c) étendre le gate POCK-07 aux skills tiers effectivement cités.
- **Source** : nicknisi « if that load fails, say so and stop. Do not review from memory ».
- **Défaillance observée** : **solide au niveau déclaration** (skills fantômes du validator,
  2026-07-25 ; `omitClaudeMd`, 2026-09-24), **aucune au runtime** ; le risque du drapeau
  `disable-model-invocation` est **latent** (les 26 skills de `plugin/` sont `model`, aucun skill
  chargé par un agent ne porte le drapeau ; A6).
- **Retire** : rien.
- **Levier** : **moyen** pour (b), **faible** pour (a) et (c) tant qu'aucun cas runtime n'existe.

### QCT-07 — L'échelle de réutilisation à l'exécution (spike, lot C)

- **Quoi** : l'échelle à arrêt précoce + la liste « jamais couper » + le test minimal, injectées
  jusqu'à l'exécuteur — un skill passif ne s'active pas (JetBrains : zéro fois sur dix).
- **Obstacles** (A7-B7) : (1) sur le repli inline l'exécuteur n'est pas un sous-agent, aucun
  `SubagentStart` ne part — risque de « vert à vide » (`GSD-PIPELINE.md:250-262`) ; (2) **Phase 45 de
  Willy** (hook central par rôle qui lit `agent_type`) : un second hook par rôle ailleurs est la
  collision la plus forte de l'étude ; (3) doctrine des hooks (inventaire de 31 entrées, forme exec,
  Gate-Touche) ; (4) conflit avec `tdd.md` injecté sans condition (« one small test » contre TDD) ;
  (5) portée : opt-in hors preset `dev` ; (6) la Phase 56 ne prévoit pas ce type de hook.
- **Preuve** : **moyenne, transfert non démontré** — JetBrains mesure −10 % de tokens de sortie en
  `SessionStart` sur v4.8.4 ; ni le canal, ni la métrique, ni la version ne sont ceux de QCT-07.
- **Défaillance observée** : la même que QCT-03 (réimplémentations), à l'exécution.
- **Spike en trois temps** : sonde du chemin réel de l'exécuteur ; arbitrage avec Willy sur la
  Phase 45 ; A/B (QCT-08) avant tout hook. La carte de l'existant (Ponytail) n'a de sens que
  régénérée mécaniquement à chaque étape, pas rédigée une fois en Phase 60 (A7-B9).
- **Levier** : **inconnu**.

### QCT-08 — Mesurer avant de retoucher une consigne de juge (lot A, protocole)

- **Quoi** : toute retouche du bloc « Hygiène » ou d'un brief de juge passe la sonde réelle déjà
  pratiquée pour POCK-04 (agent frais, fixtures à l'aveugle, deux sens), en trois bras (sans / actuel /
  modifié) et avec une fixture que la retouche pourrait casser. Piège connu à écrire dans le
  protocole : le registre d'agents est résolu au démarrage, une définition modifiée n'est pas chargée
  en session.
- **Source** : Ponytail `CONTRIBUTING.md:9-29`.
- **Défaillance observée** : **aucune** retouche à effet nul ou inverse datée (A5 §F) ; c'est une
  extension d'un protocole qui marche, pas un remède.
- **Retire** : rien ; généralise P414-D-07.
- **Coût** : faible pour le lot A ; un gold set (10 à 20 diffs étiquetés à la main) seulement si
  QCT-07 avance — à fondre avec l'item agent-book gap 2, pas avec la Phase 52 (qui mesure l'usage,
  pas le rendement).
- **Levier** : **moyen**.

### QCT-09 — Profondeur et pré-passage du moteur (réserve)

- (a) **Profondeur** : le premier jet (allégé → `quick`, plein → `deep`) cassait la revue — `quick`
  ne lit pas les fichiers, `deep` sur chaque re-revue forcée par `reopen` — et le régime « allégé »
  n'a pas de champ machine (`dag.sh:24-29`). Seule piste tenable : `deep` réservé aux quatre
  déclencheurs de revue renforcée de `mission-flow.md`. Levier **faible**.
- (b) **`fallow`** : le moteur sait injecter un pré-passage si le binaire est installé — dépendance
  tierce par lab, a priori JS/TS, qui écrit un fichier (incompatible avec un juge en lecture seule
  tel quel). Sonde sur un lab TS avant toute décision. Levier **inconnu**.
- (c) `gsd-code-fixer` dans l'allowlist de `vf-coder` sans câblage : ménage, l'allowlist n'étant
  pas appliquée à l'appel ; casse le test T19. Bénéfice de lisibilité seulement.

### QCT-10 — Dette explicite marquée et récoltée (réserve)

Marqueur `<limite>, <quand revoir>` + récolte (Ponytail `ponytail-debt`). Aucune défaillance
observée ; n'a de sens que si QCT-07 produit des raccourcis assumés.

---

## 4. Ce qui est écarté, et pourquoi

- **Installer l'un des trois plugins** — un seul catalogue tiers installé (décision du 2026-08-28).
  Le hook `SubagentStart` de Ponytail injecte le persona « senior paresseux » dans **tous** les
  sous-agents, juges compris ; le hook de pstack revendique le routage contre `vibeflow-head`.
- **Un troisième axe de revue « Sobriété »** — voir QCT-05 (conflit amont, Info → mineur,
  défaillances trouvées par audit).
- **Le recoupement pondéré de Thermos** — contraire à POCK-04 (axes jamais re-rankés).
- **« Be ambitious […] restructuring some of the codebase, go for it »** — hors périmètre d'étape ;
  et le seul refactor de ce type documenté chez nous a régressé.
- **Un seuil de taille de plus** — `guard-file-size.sh` juge déjà la croissance ; aucune défaillance
  attribuée à la taille d'un fichier (A5 §C). Étendre aux `.sh` attendra une défaillance.
- **Un hook bloquant de sobriété** — un jugement de qualité reste consultatif (ADR-074 pour les
  gates). `guard-file-size.sh` est un hook bloquant de qualité antérieur (ADR-035, ADR-043) : il
  porte sur une **mesure** (nombre de lignes), pas un jugement, et ne fait pas précédent.
- **Le panel multi-familles de pstack** — renvoyé à l'item agent-book gap 3 (juge hétérogène).
- **L'anti-planification de pstack** (« the best spec is code ») — contraire à GSD-first.
- **La délégation obligatoire du code** — déjà vraie par construction.
- **Les chiffres d'agrégateurs** (« 83 % », « 10 000 agent runs », « 128 000 étoiles ») —
  introuvables à la source.

---

## 5. Audit des bénéfices

### 5.1 Ce qu'on peut affirmer

Aucune mesure du rendement des revues VibeFlow n'existe : ni taux de faux positifs courant, ni tours
du budget brûlés pour rien, ni `passed` revenus plus tard. Les bénéfices sont donc des **directions**
adossées à deux types de preuves : les **défaillances observées chez nous** (A5, datées) et les
**preuves externes**, de force inégale. La seule mesure externe indépendante (JetBrains, −10 % de
tokens de sortie) porte sur un mécanisme d'exécution (QCT-07) et ne se transfère pas telle quelle.

### 5.2 Synthèse

| Emprunt | Lot | Défaillance observée chez nous | Preuve externe | Coût | Levier |
|---|---|---|---|---|---|
| QCT-01 non vérifié | A | **solide** (×3) | moyenne (mesure de l'auteur) | champ + canal | **fort** |
| QCT-02 hygiène | A | **solide** (×4) | faible (convergence de 4 textes) | ~20 L + canal | **fort** |
| QCT-03 réimplémentation | A | **solide** (×2) | faible | 2 L | moyen |
| QCT-04 tests à vide | A | **solide** (×3) | faible | 2 L | moyen |
| QCT-08 mesure | A | aucune | moyenne (méthode) | faible | moyen |
| QCT-05 sobriété en audit | B | solide (audit) | faible | lentille d'audit | moyen |
| QCT-06 jamais de mémoire | C | déclaration oui, runtime non | forte (2 constats tiers) | faible | moyen / faible |
| QCT-07 échelle à l'exécution | C (spike) | indirecte | moyenne, transfert non démontré | hook + ~850 tokens par exécuteur | inconnu |
| QCT-09 profondeur, fallow | réserve | aucune | — | variable | faible / inconnu |
| QCT-10 dette | réserve | aucune | faible | faible | faible |

### 5.3 Le bénéfice attendu du lot A, en clair

- **Moins de tours perdus** dans une boucle à 3 tours partagés entre revue, tests et audit : chaque
  faux positif évité rend un tour au vrai problème. Ordre de grandeur observé : jusqu'à 6 constats
  sur 15 faux dans un audit, 2 tours de sonde sur 3 brûlés avant P414-D-20.
- **Des `passed` lisibles** : le lecteur suivant (manager, head, Samuel, Willy) voit ce que la
  revue n'a pas regardé, ce qui aurait exposé les trois cas de « vert aveugle » datés.
- **Deux classes de défauts récurrents interrogées à chaque diff** : réimplémentation d'une
  primitive (six copies du confinement de chemin) et test qui ne peut pas échouer.
- **Coût** : une à deux instructions dans `vf-reviewer` (arbitrage G-1), ~30 lignes de référence,
  aucune dépendance, aucun agent, tokens de revue quasi inchangés (aucun dispatch ajouté).
- **Critère de succès à poser au cadrage** : la sonde QCT-08 montre, sur fixtures, que
  `gsd-code-reviewer` applique le bloc (cas concret exigé, ligne relue, réimplémentation nommée,
  test à vide signalé) sans perdre de vrais constats.

### 5.4 Ce que l'étude ne promet pas

Aucune baisse de coût chiffrée pour VibeFlow ; aucune hausse de qualité mesurée (Ponytail lui-même
est à égalité de correction) ; aucune détection du défaut dominant (vérificateur incapable de
rendre rouge), qui reste l'affaire de l'exécution et de la mutation.

---

## 6. Collisions et séquencement

| Emprunt | Modules touchés | Voisinage | Nature |
|---|---|---|---|
| QCT-01 à 04, 08 | `dev-orchestrator` (`mission-contracts.md`, `vf-reviewer.md`, rapport de `vf-coder`) | **Phase 46** (Willy : format des verdicts) ; POCK-04 | **moyenne** — même bloc typé ; sérialiser avec 46 |
| QCT-05 | `audit-architecture`, validator | BACKLOG « revue de fond des grilles de juges » ; ICM G3 (dérive carte ↔ disque) | faible |
| QCT-06 | agents qui chargent une ressource normative, `check-gsd-config.sh` (gate : Gate-Touche), `check-skills.sh` | POCK-07 | faible |
| QCT-07 | hook dans un module opt-in | **Phase 45** (Willy : hook central par rôle) ; Phases 56, 60 ; `GSD-PIPELINE.md` §10 | **forte** — à arbitrer avec Willy avant tout |
| QCT-09 | `vf-reviewer.md`, config GSD | ADR-061 | faible |

**Ordre recommandé** : lot A en une phase courte (premier geste : la sonde, puis le bloc) ; lot B au
prochain audit transverse ; lot C après arbitrage avec Willy. Points de sérialisation inchangés :
`VERSION` et le tag, numérotation des ADR, `BACKLOG.md` et `docs/ADR.md` (un seul écrivain par PR).
Budget : `vf-reviewer` 9/9, `vf-dev-manager` 46/46 et 250/250 lignes — tout texte neuf va en
référence.

---

## 7. Journal des arbitrages de l'étude

| # | Constat | Sort | Raison |
|---|---|---|---|
| J1 | Ponytail « −53 % de code, −26 % de coût » | nuancé | auteur, non répliqué ; on retient JetBrains (−10 % tokens de sortie, code ns) |
| J2 | Agrégateurs : « 83 % », « 10 000 runs », « 128 000 étoiles » | écarté | introuvables à la source ; étoiles Ponytail vérifiées à 159 666 |
| J3 | pstack « contient » la thermo-nuclear | nuancé | lentille dérivée dans `/interrogate` ; copie du skill dans le portage seulement |
| J4 | « thermonuclear-code-quality-review » = revue correctness | nuancé | collision de nom ; l'original Cursor est une revue de maintenabilité |
| J5 | Installer Ponytail sur le poste de Samuel | hors périmètre | possible à titre personnel ; son `SubagentStart` atteindrait les juges VibeFlow ; restreindre `PONYTAIL_SUBAGENT_MATCHER` aux exécuteurs |
| J6 | A7-B1 (bloquant) : l'axe Sobriété contredit la grille amont, Info → mineur l'annule | **retenu** | axe de revue abandonné → QCT-05 en audit |
| J7 | A7-B3 : le texte en référence n'atteint pas le juge | **retenu** | canal unique nommé, instruction comptée |
| J8 | A7-B4, F1 : profondeur allégé → quick casse la revue ; pas de régime allégé machine | **retenu** | QCT-09 (a) réduit aux déclencheurs renforcés, en réserve |
| J9 | A7-F2, B5 : `fallow` n'est ni dans le moteur ni gratuit | **retenu** | QCT-09 (b) en sonde |
| J10 | A7-B7 : six obstacles à QCT-07, collision Phase 45 | **retenu** | QCT-07 reclassé en spike |
| J11 | A7-B8 : aucun emprunt ne dit ce qu'il retire | **retenu** | ligne « Retire » par fiche |
| J12 | A7-B9 : carte en Phase 60 dérive, n'atteint pas l'exécuteur | **retenu** | QCT-05 du premier jet supprimé, renvoyé dans QCT-07 |
| J13 | A7-B11 : la qualité des tests manque | **retenu** | QCT-04 |
| J14 | A7-B12, B13 : appelants, non vérifié côté exécuteur | **retenu** | dans QCT-02 et QCT-01 |
| J15 | A7-F3, F4, F5 : preuves surcotées ou citées à moitié | **retenu** | §1.1 et §5.2 corrigés |
| J16 | A7-F8 : KISS/YAGNI atteint le relecteur si le module est en scope projet | **retenu** | §2 corrigé |
| J17 | A7-F9, A5 §C : le garde de taille juge déjà la croissance | **retenu** | seuil delta écarté (§4) |
| J18 | A7-F10 : brief à champs « convergent » | **retenu** | « partiel » |
| J19 | A7-F14 : ADR-074 mal mobilisé, `guard-file-size` bloquant | **retenu** | exception nommée en §4 |
| J20 | A7-B2 : coût réel de l'axe = tours de budget | **sans objet** | axe abandonné |
| J21 | A7-B6 : allowlist cosmétique | **retenu** | QCT-09 (c), ménage |
| J22 | A7-B10 : « diffs dont on connaît le devenir » n'existe pas | **retenu** | gold set étiqueté à la main, seulement pour QCT-07 |
| J23 | A7 lisibilité L1 à L6 | **retenu** | fiches par emprunt, échelle unique, verdict d'action en tête, glossaire |
| J24 | A5 §B : sobriété trouvée par audit, bloquée par la décision | **retenu** | QCT-05 exige une décision par constat |
| J25 | A5 : contre-indice code judo (Phase 31) | **retenu** | judo en audit seulement, avec injection de panne |
| J26 | A5 §F : aucune défaillance pour l'A/B | **retenu** | QCT-08 = extension d'un protocole existant, pas un remède |
| J27 | A6 : risque `disable-model-invocation` latent ; `agent_skills` saute en silence | **retenu** | QCT-06, (b) en tête |
| J28 | A6 : design « ne jamais bloquer » = travail de mémoire déclaré | nuancé | gardé pour la production, pas pour le jugement |

---

## Glossaire (sigles internes)

- **POCK-04** : revue à deux axes Standards / Spec (Phase 41.4, emprunt Pocock), `mission-contracts.md:354-394`.
- **POCK-05** : grille de tri « mécanique → check, jugement → standard ». **POCK-07** : classe user / model-invoked des skills, gate `check-skills.sh`. **POCK-08** : un ajout cite une défaillance observée datée.
- **P414-D-20** : seuil d'axe, `passed` sans bloquant ni majeur, un mineur ne relance pas la boucle (`mission-contracts.md:373-375`). **P414-D-07** : protocole de sonde réelle.
- **E6** : triplet de preuve `{verdict, commande, exit_code, sha}` du bloc typé.
- **G-1** : garde de la baseline du budget d'instructions ; toute hausse cite un arbitrage daté.
- **SOBR-05**, ADR-076 : « un ajout, un retrait ». **QUAL-01**, ADR-074 : gates nés avec leur mutation rouge ; jugement de qualité consultatif.
- **Agent-book gap 2 / gap 3** : calibration des juges ; juge d'une autre famille de modèles (BACKLOG, item « Alignement AI Agents in Depth »).

## Sources

- Ponytail : https://github.com/DietrichGebert/ponytail (HEAD `9cc65d0`, v5.1.0) ; JetBrains,
  https://blog.jetbrains.com/ai/2026/07/ponytail-skill-claude-tested/ ; InfoQ,
  https://infoq.com/news/2026/08/ponytail-agent-skill-benchmark ; issue #126.
- pstack : https://github.com/cursor/plugins/tree/main/pstack (HEAD `ddcde50`) ;
  https://github.com/michael-denyer/pstack-claude (v0.9.81) ; https://flaviocopes.com/pstack
- Thermo-nuclear : https://github.com/cursor/plugins (909bc5d, 5080d38, 5102244, 6e3d2ea) ;
  `nicknisi/claude-plugins` (5e75689) ; `michael-denyer/pstack-claude` (1d791c8) ;
  `bangle-io/bangle-io` ; `NikolasP98/minion_plugins` ; tessl.io.
- Claude Code, `disable-model-invocation` : https://code.claude.com/docs/en/skills
- VibeFlow : v2.69.0, `origin/main` `53dfc217`.
