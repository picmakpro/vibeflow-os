# Phase 23 — Arbitrages humains du 2026-08-02

Tranchés par Samuel après la clôture de la première mission d'exécution, qui avait gelé les
fichiers de doctrine et remonté sept points (cf.
`.planning/missions/2026-08-02-phase-23-couplage-gsd.md` §« Ce qui remonte à l'humain »).

Les points 1 à 4 commandent la suite : la Lacune 3 (plan 23-03) ne peut pas être écrite sans
savoir ce qu'un `--auto` auto-approuve. Les points 5 à 7 (périmètre des gates) restent ouverts et
seront instruits une fois les fichiers de doctrine réécrits.

---

## A-1 — RETRANCHÉ le 2026-08-02 : voir A-1bis

> ⚠️ **La décision ci-dessous est ANNULÉE.** Sa prémisse était fausse. Elle est conservée telle
> quelle pour la traçabilité ; la décision qui fait autorité est **A-1bis**, plus bas.

## A-1 (ANNULÉE) — D-02 inerte : retirer `--auto`, passer à `--assumptions`

**Décision.** `vf-coder` n'invoque plus le cadrage en mode `--auto`. Il utilise `--assumptions`.

**Pourquoi cette option plutôt que les deux autres.** On traite la cause, pas le symptôme : sans
`--auto`, plus rien ne pose le chain flag, donc plus rien ne ré-arme `workflow._auto_chain_active`
après le désarmement du geste 5. Les deux alternatives (désarmement porté par `vf-coder` après son
cadrage, ou re-désarmement par le manager à chaque retour de worker) laissaient toutes deux une
fenêtre armée et coûtaient des lignes sur un agent à 244/250.

**Rappel du mécanisme constaté.** Amont, `chain.md:39-42` ré-arme le flag si le chain flag est
présent **et** `AUTO_MODE` faux. Le geste 5 met `AUTO_MODE` à faux → satisfait la précondition ;
puis `vf-coder.md:27` invoque le cadrage en `--auto` → le flag repart à `true` pour toute la
mission. `--auto` était là parce que `vf-coder` n'a pas `AskUserQuestion` et bloquerait sur un
prompt ; `--assumptions` rend le même service sans poser de chain flag.

**Conséquence sur le gate T25.** Le gate déclarait cette ligne **licite** et l'immortalisait en
fixture — il était anti-corrélé au risque qu'il annonce couvrir. La fixture doit être inversée :
`--auto` sur le cadrage devient une forme **interdite**, prouvée par mutation.

## A-1bis — D-02 : garder `--auto`, et `vf-coder` désarme juste après son cadrage

**Décision (2026-08-02, révision de A-1).** `vf-coder` **garde** `--auto` sur le cadrage, et
**désarme le flag d'enchaînement immédiatement après** l'appel qui l'arme.

**Pourquoi A-1 était infondée — trois faits vérifiés contre `gsd-core@1.9.0` installé.**

1. `--assumptions` route, via `skills/gsd-discuss-phase/SKILL.md:54-55`, vers
   `workflows/list-phase-assumptions.md`, qui se déclare lui-même en tête :
   « *This is ANALYSIS of what Claude thinks, not INTAKE of what user knows. **No file output** —
   purely conversational* », et porte une attente bloquante (`Wait for user response.` l. 126).
2. **Aucun `CONTEXT.md` n'est écrit** ⇒ `gsd-planner` planifierait à vide.
3. `vf-coder` n'ayant pas `AskUserQuestion`, il retombe **exactement** dans le mode d'échec que la
   présence de `--auto` servait à éviter — la justification de A-1 se retournait contre elle-même.

**La voie par la config ne sauve rien non plus.** Le vrai mode assumptions non interactif serait
`workflow.discuss_mode="assumptions"` (`config.cjs:259`, absent de tout `plugin/` — 0 hit), qui
route vers `workflows/discuss-phase-assumptions.md`. Ce workflow **produit** bien un `CONTEXT.md`
(« *Output is identical to discuss mode — same CONTEXT.md* ») mais il est **interactif** : il
appelle `AskUserQuestion`. Même blocage.

**Conclusion.** Sur 1.9.0 il n'existe **aucun drapeau** qui soit à la fois non interactif,
producteur de `CONTEXT.md`, et sans chain flag. A-1 exigeait les trois : la cause qu'elle
prétendait traiter est **inatteignable en l'état**.

**Pourquoi A-1bis plutôt que les deux autres voies.** Le coût en lignes tombe sur `vf-coder`
(88/250, large marge) au lieu de `vf-dev-manager` (**249/250**, une ligne de marge). Le désarmement
est **adjacent** à l'armement, donc local et vérifiable par un gate de proximité — là où un
re-désarmement par le manager à chaque retour laisse une fenêtre armée pendant toute la durée du
worker. La troisième voie (le manager porte le cadrage lui-même, il a `AskUserQuestion`) supprime
le problème à la racine mais constitue un **changement structurel du cycle**, hors périmètre du
plan 23-01 — à reverser au débat si la Lacune 5 (voie unique d'invocation, plan 23-05) le rouvre.

**Conséquence sur le gate.** Le commit `e2b1bfe` avait figé `--assumptions` comme la forme licite
et faisait rougir le retour à `--auto` — **même anti-corrélation que celle qu'A-1 diagnostiquait,
étiquette retournée**. À défaire : `--auto` sur le cadrage redevient licite, et c'est **l'absence
du désarmement adjacent** qui doit rougir.

## A-1ter — TRANCHÉ le 2026-08-03 : A-1bis tombe. Voie 1 instruite en 23-05, `T25b` dégazé maintenant

> **MOTIF SUBSTITUÉ le 2026-08-04 (arbitrage A-13, sur O-21).** Le **geste** ci-dessous est
> **maintenu tel quel** — le manager porte le cadrage. Seul le **motif** du geste 2 est remplacé :
> l'ancienne justification est conservée en citation pour la traçabilité, elle ne fait plus
> autorité. Décision de référence : **A-13**, plus bas.

**Décision.** A-1bis est **démentie sur ses faits** (cf. `23-ARBITRAGES-OUVERTS.md` §O-8). Deux
gestes, dans cet ordre :

1. **Immédiatement, dans 23-01** — retirer à `T25b` la promesse qu'il ne tient pas. Le gate
   certifie une adjacence **textuelle** ; il ne borne **aucune** fenêtre runtime. Son libellé doit
   dire ce qu'il mesure et rien de plus, et le trou est documenté par écrit. **Aucun gate ne ment
   en attendant le correctif structurel.**
2. **Dans le plan 23-05 (voie unique d'invocation, Lacune 5)** — **le manager porte le cadrage**.
   C'était la 3ᵉ voie d'A-1bis, explicitement « reversable au débat si la Lacune 5 rouvre la voie
   unique » : la Lacune 5 la rouvre, la voie revient.

   **Motif retiré le 2026-08-04 (A-13), conservé pour la traçabilité** :
   > « Il a `AskUserQuestion`, donc `--auto` n'a plus de raison d'être et le problème disparaît à
   > la racine. »

   Ce motif est **faux**. `vf-dev-manager.md` documente lui-même, dans son repli **D-09**, que
   **dispatché en sous-agent — sa configuration nominale — le runtime peut ne pas lui fournir
   `AskUserQuestion`** malgré sa déclaration au frontmatter, et qu'« c'est précisément ce qui a
   gelé une mission au nœud `checkpoint-doctrine` ». Faire reposer le geste sur la disponibilité
   d'un outil de question, c'est le faire reposer sur une propriété que le runtime ne garantit pas.

   **Motif de remplacement, en vigueur depuis le 2026-08-04 (A-13)** — vrai et suffisant : une fois
   le cadrage porté par le manager, **plus aucun mode d'enchaînement n'est passé au cadrage**, donc
   la **règle 5** de `checkpoints.md` — auto-approbation de `human-verify`, auto-sélection de la
   **première option** sur `decision` — **cesse de s'appliquer** au plan et à l'exécution. C'est
   exactement le dommage identifié plus bas sous « Portée réelle », et il est fermé à la racine.
   Ce bénéfice est **indépendant** de la disponibilité d'un outil de question : il tient au mode
   **non passé**, pas à l'outillage de l'agent qui cadre. Le repli D-09 s'applique alors au manager
   comme à tout agent — il ne conditionne plus le geste, il le borne.

**Pourquoi A-1bis tombe — le fait, vérifié trois fois** (reviewer, puis manager, puis directement
sur `~/.claude/gsd-core/workflows/discuss-phase/modes/chain.md:45-61`) :

> **If `--auto` flag present OR `--chain` flag present OR `AUTO_MODE` is true:** display banner and
> launch plan-phase. → `Skill(skill="gsd-plan-phase", args="${PHASE} --auto ${GSD_WS}")`

`--auto` sur le cadrage **enchaîne discuss → plan → execute** dans le même appel. `vf-coder` ne
reprend la main **qu'à la fin du pipeline entier** : son désarmement « immédiatement, dans le même
geste » s'exécute **après** que plan et execute ont déjà tourné. C'est la famille d'erreur exacte
que cette phase combat — l'assertion mesure une relation **dans le texte**, pas dans le monde.

**Portée réelle, bornée (à ne pas surestimer).** `references/checkpoints.md` **règle 6** protège les
gates `blocking-human` : jamais auto-approuvés, même en auto-mode. Ce n'est donc **pas** une
violation d'ADR-031 sur le gate que 23-01 construit. C'est la **règle 5** qui joue : pendant plan et
execute, `human-verify` **auto-approuve** et `decision` **auto-sélectionne la première option** —
une mission déroule plan et execute en autonome **sans l'avoir voulu**, et ses décisions se
choisissent toutes seules.

**Pourquoi pas le statu quo.** Il coûtait zéro ligne, mais laissait vivre exactement ce que la
Phase 23 existe pour fermer. **Pourquoi pas la voie 1 tout de suite dans 23-01.** Le plan a déjà
coûté 3 tours d'exécution et 2 de revue ; élargir son périmètre à un changement structurel du cycle
le rouvrirait une sixième fois, alors que 23-05 traite ce sujet de toute façon.

**Troisième prémisse fausse d'affilée sur D-02.** A-1 (tranchée sur `--assumptions` inexistant en
pratique), A-1bis (tranchée sur une adjacence qui n'existe qu'à l'écrit), et maintenant A-1ter. La
leçon est écrite ici pour la suite : **sur cette lacune, vérifier le comportement du moteur amont
avant de trancher, pas après.**

**Mise à jour du 2026-08-04 (A-13) — c'est en réalité la QUATRIÈME.** Le motif initial du geste 2
d'A-1ter était lui-même une prémisse fausse : A-1, A-1bis, A-1ter, et le motif d'A-1ter. La leçon
ci-dessus **vient de jouer une fois de plus, contre l'arbitrage qui l'écrivait** — signe qu'elle
n'était pas encore appliquée à sa propre justification. Elle vaut désormais pour **toute** décision
de cette lacune, motifs compris : aucune décision D-02 ne se tranche sur une capacité supposée d'un
agent ou d'un moteur amont sans que le comportement ait été **vérifié** au préalable.

## A-2 — `workflow.auto_advance` : désarmé, dans la forme retenue en A-1bis

**Décision.** Le second déclencheur de la règle 5 amont (`checkpoints.md:11`), absent de tout
`plugin/`, est désarmé lui aussi. La forme suit celle retenue en A-1.

**Contrainte.** Correctif mécanique mais il coûte des lignes sur `vf-dev-manager.md` (244/250,
ADR-029). Déporter vers `plugin/dev-orchestrator/references/` si la marge ne suffit pas.

## A-3 — Minimum de reprise : élargir au couple réponse humaine + tâches faites

**Décision.** Le contrat de reprise transporte désormais **la réponse humaine** et **la table des
tâches déjà exécutées**, en plus des sous-champs décrivant la question.

**Pourquoi.** Les 4 sous-champs actuels décrivent tous *la question*. Le manager redispatche « avec
l'attendu » — c'est-à-dire avec la question qu'on vient de reposer — donc le worker neuf retombe sur
le même checkpoint et rend `human_needed` : **ping-pong sur un gate `blocking-human`**. Élargir
aligne le contrat sur l'amont, qui exige `{user_response}` et la table des tâches faites.

**Ce que ça rouvre.** Le contrat interdisait explicitement la table des tâches faites (garde
anti-duplication ADR-030). Cette interdiction est **levée pour ce cas précis** : la règle
anti-duplication visait la recopie de doctrine, pas le transport d'état de reprise. Le distinguo
doit être écrit, sinon la garde repart en faux rouge.

**Conséquence sur T26.** L'assertion « ensemble clos = exactement les 4 noms de D-03 » doit être
recalibrée sur le nouvel ensemble, et rester discriminante par mutation (rename des noms → KO).

## A-4 — Gel vs question : le mode départage explicitement

**Décision.** En mode **autonome**, un gate `blocking-human` **gèle le nœud** et la mission poursuit
les branches indépendantes du DAG ; la question est consignée au rapport pour l'humain. En mode
**supervisé**, l'agent **pose la question** et attend.

**Pourquoi.** Les deux clauses consécutives du contrôle de flux se contredisaient, la seconde sans
qualificatif de mode — or en mode autonome l'utilisateur est par définition absent, et un agent peut
résoudre la tension dans le mauvais sens en répondant lui-même à une attente humaine (violation
directe d'ADR-031). Les deux règles uniformes étaient plus simples à gater mais toutes deux
coûteuses : « toujours geler » interrompt les sessions supervisées où l'humain est disponible,
« toujours poser » arrête une mission de nuit au premier gate au lieu d'avancer sur les branches
libres.

**Exigence de gate.** La clause doit porter un **qualificatif de mode explicite** sur chacune des
deux branches — c'est précisément l'absence de ce qualificatif qui a créé la tension. Le gate doit
rougir sur une clause de contrôle de flux sans qualificatif de mode.

---

## Restent ouverts (périmètre des gates, non bloquants)

5. **`rc=3` contraint la forme rédactionnelle** — une réécriture en prose sémantiquement correcte du
   bloc Verdict rougit. À réinstruire **après** la réécriture commandée par A-1..A-4, puisque ce sont
   ces réécritures qui subiront la contrainte.
6. **Porosité de T25** — une prescription rédigée avec une négation dans la même clause échappe.
   Coût chiffré : ajouter `,` aux séparateurs ferme le trou et préserve les 6 fixtures, au prix d'un
   seul faux rouge (négation avec incise). Écart actuellement orienté vers le **faux vert**.
7. **Déclassement de T26 A′** — « aucun champ inventé côté worker » jugé non gateable par le worker,
   trop large par le reviewer. Piste retenue : gater sur les **positions de clé JSON**, couplé à un
   garde « ≥1 clé mesurée ou renvoi explicite ».

---

## A-5 — TRANCHÉ le 2026-08-03 : le mensonge doctrinal est corrigé MAINTENANT

**Décision.** Correctif texte minimal **immédiat** sur les deux foyers vérifiés sur disque —
`vf-coder.md:30-31` **et** `vf-dev-manager.md:75-76` (« la fenêtre armée est bornée là »).

**Pourquoi ne pas attendre 23-05.** Le gate `T25b` a cessé de mentir (geste 1 d'A-1ter), mais **la
doctrine qu'il vérifie ment toujours**, et elle **pilote deux agents en production** pendant les six
plans restants. Le plan 23-05, tel qu'il est écrit, ne vise **ni l'un ni l'autre** de ces deux
fichiers. Laisser une garantie runtime inexistante dans un texte que des agents lisent comme une
loi est exactement le mode de défaillance de cette phase.

**Périmètre.** Texte seulement : la phrase doit dire ce qui est vrai (adjacence **textuelle**, pas
de borne **runtime**) et renvoyer au correctif structurel de 23-05. Aucun changement de
comportement, aucune ligne de logique.

## A-6 — TRANCHÉ le 2026-08-03 : ne plus `require()`, lire le texte

**Décision.** `check-gsd-config.sh` **n'exécute plus** le fichier résolu : il extrait les listes par
**lecture de texte**. La cascade lab-first reste **inchangée**.

**Le vecteur, prouvé par le juge.** La cascade résout le moteur depuis le **dépôt audité** en
priorité (`:152-158`), puis un `node -e` en fait un `require()` (`:287`). Un `config.cjs` piégé
déposé dans un dépôt cloné **s'exécute au `SessionStart`**, rend `exit 0`, et le `|| true` masque
tout. Ouvrir une session dans un dépôt non maîtrisé suffit.

**Pourquoi cette forme plutôt que les deux autres.** Elle supprime le vecteur **à la racine** — un
fichier lu ne peut pas s'exécuter, quelle que soit sa provenance — **sans rien casser** : un lab en
`VF_SCOPE=project` a légitimement son moteur dans le dépôt (`23-02-PLAN.md:186-187`, « le lab
courant PRIME ») et continue de fonctionner. Les deux autres formes (retirer `$ROOT` de la cascade,
ou refuser les candidats sous `$ROOT`) sacrifiaient cette résolution légitime, l'une avec une porte
de sortie explicite, l'autre sans.

**Non négociable dans tous les cas** : documenter le vecteur dans la **section Sécurité de
l'en-tête**, comme `T-17-06` le fait pour git, et l'**ajouter au threat model de la phase**.

## A-7 — TRANCHÉ le 2026-08-03 : `gsd-core` installé dans le job CI, maintenant

**Décision.** Le job CI installe `gsd-core` **tout de suite**, dans un commit d'infra dédié, sans
attendre 23-08.

**Pourquoi.** Deux cas échouent parce que le runner n'a pas le moteur — ils échouent **honnêtement**
et **ne doivent surtout pas être dégradés** pour produire du vert. Traiter la cause maintenant coûte
peu et évite de découvrir un problème de CI à la toute fin, au moment précis où tout le reste doit
être vert et où la PR part.

---

# Arbitrages du 2026-08-04 — A-8 à A-14

## A-8 — O-11 : statu quo, limite assumée

`KNOWN_TOP` du script reste un **sur-ensemble** de celui du moteur. Les **6 clés** tues
(`_comment`, `claude_orchestration`, `external_job`, `intel`, `mempalace`, `profile-pipeline`)
restent tues, mais **honnêtement documentées** dans l'en-tête et le SUMMARY, qui nomment désormais
les deux sens.

**Pourquoi pas la parité stricte.** Elle échangerait un faux négatif **documenté** contre des faux
positifs **non documentés** sur les labs à capabilities fédérées, dont le moteur lit un overlay que
ce script ne lit pas. Mauvais échange tant que l'overlay n'est pas instruit. La voie (c) reste
ouverte si quelqu'un mesure l'overlay un jour.

## A-9 — O-13 : signal explicite **et** canari en CI

Quand `LIB` est **bien résolu** mais que l'extraction rend **0 clé**, le script émet un **signal
explicite** au lieu de se taire — en restant dans le contrat `0/3/64` (jamais d'`exit 1`,
`T-23-02-03`). **Et** un **canari** en CI rougit si la forme du moteur réel cesse d'être lisible.

**Pourquoi les deux.** Le signal corrige l'**affirmation fausse** mesurée (« sans défaut lisible »
là où il y en a un) ; le canari déplace la détection du **runtime vers la CI**, donc on l'apprend
avant de livrer plutôt qu'au moment où ça frappe un utilisateur.

## A-10 — O-12 : retirer la branche 2 de la cascade

La branche est du **code mort** (double segment dans le tarball npm publié) : elle a l'air correcte
à la lecture et ne résout rien à l'exécution. **On la retire** — des deux cascades, `mission-flow.md`
portant le même défaut.

**Pourquoi pas corriger le chemin.** Ce serait deux lignes, mais ça **ouvre une voie de résolution
aujourd'hui morte**, donc une surface neuve — au moment précis où l'on ferme un vecteur d'exécution
de code via la résolution du moteur (A-6, puis A-12).

## A-11 — O-15 : ne rien faire, `23-05` règle le sujet

La fixture `k` de `T25b` garde sa prose. `T25b` devient **sans objet au plan 23-05** (retiré ou
remplacé) : y toucher maintenant rouvrirait `23-01` une **6ᵉ** fois sur du gate, et modifierait une
**donnée de test** dont la prose est précisément la paraphrase que la sonde doit **accepter**.

## A-12 — O-23 🛑 : lecteur de littéraux **et** garde de type reposée explicitement

**La RCE réintroduite par cette branche est fermée** en portant au générateur le lecteur de
littéraux écrit en 23-02, **et** en **reposant explicitement la garde de type** que `require()`
fournissait gratuitement.

**Les deux moitiés sont indissociables.** L'auditeur a mesuré que `[ -f "$REGISTRY" ]` protège
*incidemment* le générateur de la FIFO (rc=1 en 1 s) : **fermer F1 sans reposer cette garde
rouvrirait un DoS**. Un correctif de sécurité qui en ouvre un autre est exactement le mode de
défaillance N1 de cette phase.

**Pourquoi cette voie.** Elle est **cohérente avec A-6** — ne jamais exécuter ce qu'on audite —
là où la voie (b) sacrifiait la résolution légitime d'un lab en `VF_SCOPE=project`, ce que A-6 avait
explicitement refusé, et où la voie (c) changeait la nature de 23-04 et périmerait à chaque
évolution du moteur. La péremption silencieuse que ce portage rouvre sur un **second** script se
traite par **A-9** (signal explicite + canari), déjà tranché : même remède, appliqué deux fois.

**À enregistrer au threat model** : `T-23-04-07` / Elevation of Privilege / **critical**. Et
**corriger la cause racine documentaire** : `23-04-PLAN.md:462` qualifie de « frontière de version »
la **même** frontière que `23-02-PLAN.md:378` a requalifiée sous A-6. La requalification n'avait
jamais été propagée — **F1 n'est pas une faute de codeur**, c'est un plan dont la prémisse de
sécurité était périmée. Traiter F2, F3, F4 et F6 **avec** F1 : même racine.

## A-13 — O-21 : maintenir la voie 1, corriger le motif d'A-1ter

Le **geste** d'A-1ter est **maintenu** — le manager porte le cadrage. Son **motif écrit est
remplacé** dans `23-ARBITRAGES.md` §A-1ter.

**Le motif faux** : « il a `AskUserQuestion`, donc `--auto` n'a plus de raison d'être ».
`vf-dev-manager.md` documente lui-même, dans son repli D-09, que **dispatché en sous-agent — sa
configuration nominale — le runtime peut ne pas lui fournir `AskUserQuestion`** malgré sa
déclaration au frontmatter, et qu'« c'est précisément ce qui a gelé une mission au nœud
`checkpoint-doctrine` ».

**Le motif vrai, et suffisant** : une fois le cadrage porté par le manager, **plus aucun mode
d'enchaînement n'est passé au cadrage**, donc la **règle 5** de `checkpoints.md` — auto-approbation
de `human-verify`, auto-sélection de la **première option** sur `decision` — **cesse de s'appliquer**
au plan et à l'exécution. Ce bénéfice est **indépendant** de la disponibilité d'un outil de
question. Le repli D-09 s'applique alors au manager comme à tout agent.

**Quatrième prémisse fausse d'affilée sur D-02** (A-1, A-1bis, A-1ter, et ce motif). La leçon
d'A-1ter — *vérifier le comportement du moteur amont avant de trancher, pas après* — vient de jouer
une fois de plus. Elle vaut désormais pour **toute** décision de cette lacune.

## A-14 — O-18 : poser la garde

Le script **refuse les fichiers non ordinaires** avant de lire. L'imputation a changé et elle est
mesurée : `check-gsd-config.sh` **n'existe pas sur `main`** et `hooks.json` **ajoute** sa ligne au
`SessionStart` — **la PR ouvre ce chemin, elle n'en hérite pas**. Les 3 gates préexistants
terminent en 1 s sur FIFO ; celui-ci doit faire pareil.

La seule occurrence de `statSync` dans le fichier est le **commentaire `:181` qui décrit la garde
non posée** — poser la garde, c'est faire dire vrai à ce commentaire.
