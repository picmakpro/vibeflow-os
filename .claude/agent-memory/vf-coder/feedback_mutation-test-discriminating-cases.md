---
name: mutation-test-discriminating-cases
description: Avant de déclarer un nouveau cas de test « discriminant » (whitelist, renommage, garde-fou) non-tautologique, le prouver par mutation — casser l'invariant, vérifier l'échec, restaurer.
metadata:
  type: feedback
---

Quand j'ajoute un cas de test censé prouver qu'un renommage/une whitelist/un garde-fou a
« réellement pris effet » (pas juste ajouté à côté de l'ancien), je le vérifie par mutation avant
de le considérer fiable : je casse temporairement l'invariant (retire l'entrée whitelist, inverse
la condition…), je relance la suite et confirme que le nouveau cas échoue bien (pas seulement le
cas historique), puis je restaure et confirme qu'il repasse vert.

**Why:** sur le plan 11-02 (migration `gsd-sdk` → `gsd-tools`), mon premier jet de `T4c`
(test-dev-orchestrator.sh) contenait un bypass `[ "$t" = "gsd-tools" ] && continue` — il acceptait
`gsd-tools` sans jamais dépendre de la whitelist réelle, donc il serait resté vert même whitelist
retirée. `vf-reviewer` l'a détecté en 1er tour (finding mineur, « le test ne prouve pas ce que son
commentaire affirme »). Le correctif — dériver le flag depuis la boucle T4 **réelle** (pas une
réimplémentation) + vérifier explicitement que `target_known()` échouerait sans la whitelist — n'a
été confirmé fiable qu'après une mutation manuelle (retrait de l'entrée whitelist → T4 ET T4c
échouent ; restauration → les deux repassent verts, 40 OK/0 KO). Le grep de recette (`grep -c`) ne
suffit pas à détecter une tautologie de ce type — seule l'exécution sous mutation le révèle.

**How to apply:** dès qu'un `must_have` de plan demande un cas de test « discriminant » (le mandat
`exec-11-02` employait explicitement ce mot pour d'autres cas, ex. `$HOME` vide + payload
projet-local), traiter ça comme une exigence de preuve, pas de couverture : écrire le cas, le
muter, observer l'échec attendu, restaurer, relancer. Documenter le résultat de la mutation dans le
rapport de mission plutôt que d'affirmer « prouve X » sans l'avoir vérifié à la main. Voir
[[recette-grep-c-litteral]] pour le piège voisin (le grep de recette peut être vert alors que le
comportement testé est faux, ou l'inverse).

## La moitié symétrique — les fixtures LICITES (Samuel, Phase 23, 2026-08-01)

Une assertion doit être **discriminante** (elle rougit quand la propriété est violée) **ET robuste**
(elle ne rougit pas quand la prose est reformulée légitimement). Les deux, sinon elle nuit. Prouver
la seule discriminance produit des sondes qui punissent un durcissement du texte — sur la Phase 23,
une *interdiction* rédigée et un bloc dont le titre commençait pareil faisaient rougir un gate,
avec un message accusant la doctrine. Donc : pour chaque mutation qui doit rougir, écrire aussi la
**réécriture légitime qui doit rester verte**, et la rejouer.

Corollaire, consigne explicite de Samuel : **ne pas livrer une sonde fragile**. Si une propriété
n'est pas verrouillable sans faux rouges sur une rédaction correcte, le dire dans le rapport et
proposer de la **déclasser en contrôle documenté**. « Un gate honnêtement absent vaut mieux qu'un
gate qui ment dans un sens ou dans l'autre. Je préfère un rapport disant "cette propriété n'est pas
gateable" à trois assertions de plus. »

## Le mutant doit être CONFINÉ au segment mesuré (Phase 23, 2026-08-02)

Un garde `cmp -s` (ou tout « le mutant diffère-t-il de l'original ? ») raisonne au niveau du
**fichier**. Il ne distingue donc pas « la mutation a mordu **hors** du périmètre mesuré » de
« la mutation a mordu et n'a pas été détectée ». Un mutant ancré sur une graphie de prose
(`s/mode **superviser**/…/g` global) mord ailleurs dès que la doctrine est reformulée : fichier
différent → garde vert → l'assertion rend « mutant NON détecté » et **accuse la doctrine**.

**How to apply :** fabriquer le mutant sur les **mêmes bornes structurelles** que celles qui
délimitent ce que la sonde mesure (ancre de bloc, entrées de contrat, tokens de table). La
mutation devient alors confinée au segment, et « fichier identique » redevient équivalent à
« rien à muter dans le segment » — le garde d'identité redevient exact et son message dit la
bonne chose (« sonde à réancrer, ce n'est PAS un défaut de l'assertion »).

## Rejouer le mutant d'une revue : reprendre sa forme EXACTE, pas son intention (Phase 23, 2026-08-03)

Une revue affirmait qu'un mutant (`const _load = require;` puis un chargement dans `readLiteral`)
laissait la suite à `35 ok / 0 ko`. Rejoué avec la **variable de boucle** comme cible, il rougissait
un cas — j'aurais conclu « la revue exagère ». Rejoué avec le **basename fixe** qu'elle écrivait
(`'config-schema.cjs'`), il rendait bien `35 ok / 0 ko` avec le témoin de RCE écrit. La différence :
la variable de boucle frappait aussi un fichier **déjà piégé** par la fixture, la constante ne
frappait que l'un des fichiers **sans témoin**.

**Why:** deux mutants qui expriment la même intention n'ont pas la même dureté. Le plus faible passe
par un piège existant et « prouve » que le filet tient ; seul le plus dur montre le trou. Choisir le
mutant faible, c'est se donner raison contre la revue par accident de fixture.

**How to apply:** quand une revue chiffre un mutant, reproduire sa **lettre** (cible, littéral,
point d'insertion) avant toute reformulation, et vérifier qu'on retrouve **son chiffre**. Si le
chiffre ne tombe pas, c'est le mutant qui est faux, pas la revue. Puis garder la forme dure dans le
dépôt — un mutant matérialisé qui frappe une cible déjà couverte est un faux témoin permanent.

## Le cas « malveillant » doit RÉUSSIR quand on retire la garde (Phase 24, 2026-08-04)

Un cas de rejet ne discrimine que si l'entrée rejetée **aurait produit un effet observable** sans la
garde. Deux formes rencontrées le même jour, toutes deux prescrites telles quelles par le plan et
toutes deux vertes sous mutant :

- **Traversée de chemin qui ne résout nulle part.** `GSD_WORKSTREAM=../evil` concaténé donne
  `<pl>/workstreams/../evil` — inexistant. Garde retirée : repli sur la racine, **même verdict**.
  Le cas discriminant est `../workstreams/dev`, qui résout vers un compartiment **réellement
  présent** dans la fixture : garde retirée, le verdict bascule. Règle : viser une cible qui existe.
- **Cas d'isolation d'un régime que la feature ne fait pas parler.** « Régime INDEX + workstream
  posé » ne discrimine pas l'ordre du bloc de résolution : le workstream se **résout**, donc rien
  n'est émis, et déplacer le bloc avant la branche INDEX ne change aucun octet. Il faut le
  workstream **non résolu** (ou le nom invalide) — les seuls états où la feature émet quelque chose
  dans ce régime.

**Why:** dans les deux cas la sonde teste « l'entrée hostile ne casse rien », ce qui est trivialement
vrai quand l'entrée est inerte. Elle ne teste pas « la garde sert à quelque chose ».

**How to apply:** avant d'écrire un cas de rejet, répondre à « qu'est-ce que je verrais si la garde
sautait ? ». Si la réponse est « la même chose », la fixture est inerte — la muscler jusqu'à ce que
l'entrée hostile ait une cible atteignable. Ne pas se contenter de la fixture que le plan décrit :
sur ce mandat, les deux cas prescrits par le plan étaient inertes et n'ont été démasqués que par la
mutation.

## Le plancher du gate peut PRÉEMPTER la règle que le mutant vise (Phase 24, plan 24-11, 2026-08-04)

Un gate qui refuse de conclure sur une entrée trop pauvre (« non vérifiable », exit 2) évalue ce
plancher **avant** ses règles de fond. Une fixture minimale — un seul élément de l'ensemble mesuré —
fait donc que la mutation qui **retire** cet élément vide l'ensemble et déclenche le **plancher**,
pas la règle visée. Mesuré : fixture à 1 marqueur, MUT1 retire le marqueur → `rc=2` « aucun marqueur
dans le corpus » au lieu du `rc=1` « promesse non marquée » attendu.

**Why:** le mutant reste **rouge**, donc l'assertion « le gate sait rougir » passe et le défaut est
invisible. La propriété de sûreté (jamais vert) tient — mais le mutant rougit pour la **mauvaise
raison** et ne prouve **rien** sur la règle qu'il prétend démontrer. C'est la même famille que « le
cas malveillant doit réussir quand on retire la garde » : ici c'est le *diagnostic* qui est inerte,
pas l'entrée.

**How to apply:** dimensionner la fixture sur la **forme du corpus réel**, pas au minimum syntaxique
(le corpus réel portait 3 marqueurs, la fixture est passée à 2 — retirer l'un laisse l'ensemble non
vide et la règle de fond s'exprime). Et **assertion sur le motif du rouge**, jamais sur le seul
`rc != 0` : vérifier que le message nomme la règle attendue **et** l'objet visé. Enfin, le
recouvrement lui-même mérite son propre cas gardé (plancher + violation ensemble ⇒ code du plancher,
et surtout **jamais 0**) — sinon un lecteur croira la règle de fond silencieusement contournée.

Deux pièges de sonde vus sur ce tour, à re-vérifier ailleurs : un **garde `grep` et sa coupe `sed`
qui ne portent pas le motif exact** (la coupe devient no-op silencieuse et l'assertion certifie
l'inverse de ce qu'elle vérifie) ; un **code de retour ≥ 2 traité comme succès** par un `cmd && …`
(le mutant n'a rien mesuré, l'assertion se déclare verte). Et toute mutation ancrée sur une phrase
littérale doit vérifier que le mutant **diffère réellement** de l'original — sinon reformuler la
doctrine désarme la sonde en silence. Attention à *où* porte ce garde d'identité : construit après
une **concaténation** (`"$(sed …)" , suffixe"`), il ne peut jamais être vrai, il est mort ; il doit
porter sur le résultat de la coupe **seule**.

## Un PATH restreint pour cacher UNE commande cache aussi celles du fixture piège (Phase 27, 2026-08-06)

Test visant « X absent → repli Y » via un `PATH` réduit à un seul binaire (ex. `python3` seul,
`node` absent). Le fixture piège censé prouver la mutation (un faux `.cjs` exécutable qui, s'il
tournait directement sans `node`, produirait un JSON détectable) portait un shebang
`#!/usr/bin/env bash` **et** appelait `cat` en interne. Le premier tour de mutation (« ignorer
l'absence de node, exécuter quand même le chemin resolu ») restait **vert** — pas parce que la
garde tenait, mais parce que `bash`/`cat` n'étaient eux-mêmes pas sur le `PATH` restreint : le
fixture piège échouait pour une tout autre raison (127, commande introuvable) que celle testée,
et son échec produisait accidentellement le même `stages: null` attendu — même symptôme que « Le
plancher du gate peut PRÉEMPTER la règle que le mutant vise » ci-dessus, mais côté fixture au lieu
du gate.

**Why:** un `PATH` chirurgical protège la propriété testée (« X est absent ») mais peut, par
ricochet, invalider la capacité du fixture à *prouver* le contraire s'il devait s'exécuter — la
sonde devient vraie pour la mauvaise raison, indétectable sans rejouer la mutation.

**How to apply:** quand un fixture piège doit *pouvoir réussir seul* pour que le mutant soit
discriminant, l'auditer pour toute dépendance externe (interpréteur du shebang **et** commandes
appelées à l'intérieur) et les ajouter explicitement au `PATH` restreint, ou n'utiliser que des
builtins du shell (`echo`, jamais `cat`/`printf` externe). Systématiquement rejouer la mutation
ciblée après écriture — c'est ce qui a révélé le trou ici, deux fois de suite (bash absent, puis
`cat` absent) avant que le test rougisse pour la bonne raison.
