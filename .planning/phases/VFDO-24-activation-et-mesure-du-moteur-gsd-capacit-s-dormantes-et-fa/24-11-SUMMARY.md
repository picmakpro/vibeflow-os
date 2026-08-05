---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 11
type: execute
requirements: [GSDA-09, GSDA-08, GSDA-15, GSDA-02]
commits:
  - 573ad31 feat(24-11) gate reliant une entrée de doc à l'activation de sa capability
  - ba7e6b6 test(24-11) suite du gate — discriminance prouvée dans les deux sens
  - b14a040 test(24-11) T14 interroge l'activation, pas seulement le routage (+T34, T35)
---

# 24-11 — Le gate qui relie une entrée de doc à l'activation de sa capability

## Ce qui a été fait

Le point commun des trois routes inertes de la zone 3 n'était pas qu'elles pointaient des
capacités éteintes. C'était qu'**aucun gate ne reliait une entrée de documentation à l'activation
de sa capability** : `intent-routing.md` routait vers `gsd-graphify` et `gsd-profile-user`, le test
d'exhaustivité du module vérifiait que le skill était **routé**, jamais que sa capability était
**active**, et une couverture verte masquait donc deux gestes morts. Ce lot ferme la cause.

### 1. `check-capability-activation.sh` — le gate

`plugin/dev-orchestrator/scripts/check-capability-activation.sh` (235 lignes, exécutable, **lecture
seule stricte** : aucun fichier écrit, aucun `mv`, aucun `rm`).

Il asserte la cohérence de **trois** artefacts — l'index de capabilities **généré**, la
configuration effective du lab, le corpus documentaire de routage — via deux ensembles, tous deux
extraits en `awk` et **jamais** en `grep` piped :

| Ensemble | Source | Mesuré sur ce dépôt |
|---|---|---|
| **T** — toggles gouvernants | `gsd-capabilities-index.md`, **ses deux tables** | **29** distincts, dont **22 inactifs** |
| **M** — toggles sous marqueur | corpus, forme littérale `(conditionnelle : <toggle>)` | **2** toggles, **3** occurrences |

Les deux tables de l'index ont des **arités différentes** — 5 colonnes par point de hook (`NF=7`),
3 colonnes hors point de hook depuis la colonne `Rôle` du plan 24-06 (`NF=5`) — et la clé
gouvernante est le **4ᵉ champ dans les deux**. Le parseur traite les deux explicitement plutôt que
de s'en remettre à cette coïncidence, et écarte les valeurs qui ne sont pas un identifiant pointé
(`—`, `-`, vide) par un **filtre positif** : comparer à un tiret cadratin serait une comparaison
multi-octets, exactement le genre de fragilité qui a déjà coûté à cette phase.

Trois règles, dans l'ordre :

1. **Plancher anti-vert-à-vide** — T vide **ou** M vide ⇒ **2 « non vérifiable »**, jamais 0. Un
   index illisible ou un corpus sans marqueur ne prouve rien : c'est le mode d'échec que ce gate
   existe pour fermer, il ne doit pas s'y laisser prendre lui-même.
2. **Promesse non marquée** — un toggle de T inactif sur ce lab, cité dans le corpus **hors**
   marqueur ⇒ **1**, message nommant le toggle **et** `fichier:ligne`.
3. **Marqueur périmé ou inconnu** — un toggle de M absent de T, ou **actif** sur ce lab ⇒ **1**.
   C'est cette règle qui rend la discriminance **bidirectionnelle**.

Contrat : `0` conforme · `1` écart · `2` non vérifiable · `64` usage — les quatre énumérés dans la
docstring et chacun exercé par au moins un cas de test.

**Ce que le gate ne fait pas, délibérément.** Il ne classe **aucune** capability « dormante ». Sur
les 27 capabilities hors point de hook, 19 sont des `runtime` et 5 des `reviewer` : n'avoir aucun
étage est leur état **normal**, et seules 3 sont des `feature` réellement dormantes. Le gate lit des
**toggles**, il ne juge aucun rôle — confondre « sans étage » et « dormant » serait faux d'un
facteur 9.

Deux choix de lecture, tous deux pris dans le sens de la prudence :

- **« Actif » = clé présente ET valeur ni `false` ni `null`.** Un toggle porté par une chaîne (les
  `review.models.*` nomment un modèle, pas un booléen) reste donc actif. Traiter toute valeur
  non-booléenne comme inactive aurait **inventé** des écarts.
- **Comptage d'occurrences littéral** (`index()`, pas de regex) : un nom de toggle porte des points
  et des tirets qu'une expression interpréterait.

### 2. `test-check-capability-activation.sh` — la suite

**16 cas, 16 OK / 0 KO.** Fixtures **synthétiques** sous `mktemp -d` + `trap` — l'arbre réel bouge
(l'index est régénéré à chaque évolution du moteur), une suite ancrée dessus se périmerait. Les
quatre codes du contrat sont chacun exercés ; les deux planchers le sont **séparément**.

**Discriminance prouvée par mutation, dans les deux sens** — chaque mutation confirmée par `cmp` et
jamais par `diff`, et chacune assertant le **vert retrouvé** après restauration (sans quoi le rouge
pourrait venir d'une fixture cassée) :

| Mutation | Geste | Attendu | Obtenu |
|---|---|---|---|
| MUT1 (règle 2) | retirer le marqueur en **conservant** la promesse | rouge par la règle 2 | `rc=1`, message `ECART regle 2 … demo.enabled` |
| MUT2 (règle 3) | activer le toggle en **conservant** le marqueur | rouge par la règle 3 | `rc=1`, message `ECART regle 3 … PERIME` |

MUT1 retire le **marqueur**, pas la ligne : retirer la ligne entière rendrait le gate vert **à
juste titre** (il n'y aurait plus de promesse) — ce serait supprimer la promesse, pas muter le gate.

### 3. `test-dev-orchestrator.sh` — T14 étendu, plus les deux assertions déléguées

**167 → 182 OK / 0 KO / 0 SKIP** (+15 cas, le plan en demandait ≥ 6). Trois blocs **ajoutés**,
aucun bloc préexistant modifié.

**T14d — la troisième catégorie de brique, « routée MAIS conditionnelle ».** Même forme que
`INTENTIONALLY_UNROUTED` (liste blanche nommée + fonction `case`, jamais un booléen épars),
sémantique **inverse** : ces briques *sont* routées et comptent pour l'exhaustivité, **mais** leur
ligne doit porter le marqueur. Quatre sous-assertions : (a) la liste blanche est **vivante** (chaque
nom qu'elle porte est réellement routé — une liste blanche qui nomme des briques disparues exempte
du vide) ; (b) toute ligne citant une brique conditionnelle porte son marqueur ; (c) discriminance
par mutation ; (d) **le câblage** — `check-capability-activation.sh` est invoqué sur le corpus réel
et T14 échoue si son code n'est pas 0. Sans (d), le gate existerait sans que personne ne le lance :
une garde jamais exécutée est une garde absente.

**T34 (délégué par 24-03)** — les deux phrases doctrinales du canal `agent_skills` : le constat
(la doctrine atteint le plan, pas l'exécution) **et** l'interdiction de présenter le canal comme
résolu côté exécuteur. Le bloc échoue dès que **l'une** disparaît.

**T35 (délégué par 24-08)** — `--ws`/`GSD_WORKSTREAM` + renvoi à `workstreams.md`, vérifié **par
agent**, plus le plafond ADR-029 compté en `awk`.

## Vérifications

| Contrôle | Résultat |
|---|---|
| `bash -n` sur les trois fichiers | ✅ |
| `check-capability-activation.sh` sans argument sur le dépôt | ✅ rc=0 |
| `--help` énumère `0`, `1`, `2`, `64` ; argument inconnu et `--path` sans valeur | ✅ rc=64 tous les deux |
| Aucun `grep` **hors commentaire** dans le gate (balayage `awk` du fichier, lignes de commentaire écartées) | ✅ 0 occurrence |
| Aucune redirection d'écriture, aucun `mv`/`rm` dans le gate | ✅ (seul `>/dev/null` d'un `command -v`) |
| `test-check-capability-activation.sh` | ✅ **16 OK / 0 KO** |
| Aucune occurrence de `diff` **exécuté** dans les deux suites (les 2 mentions sont de la prose qui l'interdit) | ✅ |
| `test-dev-orchestrator.sh` | ✅ **182 OK / 0 KO / 0 SKIP** (baseline mesurée à 167 avant le lot) |
| Aucune ligne préexistante perdue : `comm -23` des lignes triées avant/après | ✅ **0 ligne disparue** (180 ajoutées) |
| Plancher anti-test-vacant de T14 **bit-à-bit** inchangé (`cmp -s` sur le segment) | ✅ identique |
| Les 8 suites du module `dev-orchestrator` | ✅ toutes rc=0 |
| **Balayage complet du dépôt**, à l'univers exact de la CI (`find plugin scripts -type f -path '*/tests/test-*.sh'`) | ✅ **50 suites exécutées, 0 rouge** |
| `vf-dev-manager.md` sous plafond ADR-029 | ✅ 248/250 — **marge de 2** |

### Compte de suites du dépôt — re-dérivé, pas recopié

Le plan annonçait **49**. La valeur réelle après ce lot est **50** : une seconde suite avait atterri
dans la phase entre l'écriture du plan et son exécution. Univers nommé et commande de re-dérivation :

```
find plugin scripts -path '*/tests/test-*.sh' | awk 'END{print NR}'     # → 50
git ls-tree -r --name-only 08a563d | awk '/\/tests\/test-.*\.sh$/ && (/^plugin\// || /^scripts\//) {n++} END{print n}'   # → 47 (pointe de main)
```

**Le recalage du compteur des deux README appartient au plan 24-12** — ce lot n'y touche pas, et le
nombre à inscrire est **50**, à re-mesurer au moment de l'écriture (d'autres plans de la phase
peuvent encore en ajouter).

## Déviations et effets de bord

1. **Fixture de la suite dédiée portée à DEUX marqueurs** (le plan n'en prescrivait pas le nombre).
   Motif mesuré, pas esthétique : avec un seul marqueur, MUT1 le retirait, **M** devenait vide, et
   le plancher de la règle 1 sortait en **2** *avant* que la règle 2 puisse voir la promesse
   démarquée. Le gate restait **rouge — jamais vert**, la propriété de sûreté tenait ; mais le
   mutant rougissait pour la **mauvaise raison** et ne prouvait pas la règle qu'il visait. Corrigé
   dans la **fixture**, qui modélise désormais le corpus réel (3 occurrences), et MUT1 assert
   maintenant `regle 2` **et** le toggle visé. Le recouvrement lui-même est devenu un cas gardé
   (**6b**) : plancher et promesse démarquée ensemble ⇒ **2**, et surtout **jamais 0**.

2. **T34 cherche ses phrases sur le fichier REPLIÉ**, avec des blancs élastiques, via les helpers
   `md_folded`/`md_sed_folded` déjà présents dans la suite. Le constat doctrinal est en **gras** et
   le wrap à 100 colonnes le coupe **aujourd'hui** entre `elle n'atteint` et `pas l'exécution` : un
   littéral à espaces figés aurait été invisible sur le fichier **intact**. C'est le mode d'erreur
   « littéral gardé cassé par le gras multi-ligne », évité à la source.

3. **Les mutations de T34 vérifient qu'elles sont CHIRURGICALES** (la phrase témoin survit dans le
   mutant). Sans ce contrôle, une mutation trop large emportant les deux phrases produirait le même
   rouge et prouverait seulement que le bloc échoue quand **tout** disparaît — jamais qu'il échoue
   sur la disparition de **l'une**, qui est précisément ce que l'arbitrage 24-03 exige.

4. **T35 mute les deux agents SÉPARÉMENT.** Une assertion qui balaierait la paire et se
   contenterait d'un succès resterait **verte** quand l'un des deux perd sa mention — mode d'erreur
   « existence au lieu de relation ». Les deux mutations prouvent que le contrôle porte sur *chaque*
   fichier.

5. **L'ensemble des toggles actifs transite par l'ENVIRONNEMENT et non par `awk -v`.** Une valeur
   passée à `-v` ne peut pas porter de saut de ligne (`awk: newline in string mode` sur BSD awk), et
   cet ensemble en est une liste. Constaté à l'exécution, pas anticipé.

6. **Aucun câblage CI ajouté — et aucun n'était nécessaire.** La CI découvre les suites par
   `find plugin scripts -type f -path '*/tests/test-*.sh'` : la suite neuve y entre d'elle-même. Le
   gate, lui, est **bloquant** par la voie que le plan prescrit — l'invocation depuis T14d, dans une
   suite qui tourne au job `tests`.

## Périmètre

Aucun fichier hors des trois `files_modified` du plan n'a été touché. En particulier : ni
`intent-routing.md`, ni `docs-flow.md`, ni `gsd-capabilities-index.md` ou son générateur, ni
`.planning/config.json`, ni `workstreams.md`, ni les README, ni aucune triade
`VERSION`/`module.json`/`CHANGELOG.md`. Les trois commits sont faits par **pathspec explicite** ;
`.planning/missions/dag-phase24.json`, modifié en parallèle par un autre acteur, n'est dans aucun
d'eux.

## Requirements

- **GSDA-09** — la cause est fermée, pas le symptôme : le gate relie une entrée de doc à
  l'activation de sa capability, et T14 l'invoque. Le trou ne peut plus se rouvrir en silence au
  prochain skill ajouté : la règle est **écrite** (marqueur de forme unique) **et gardée** (deux
  étages, celui de la carte et celui des trois artefacts).
- **GSDA-08** — les deux capacités refusées par le plan 24-06 sont désormais **gardées** : leur
  marqueur ne peut ni disparaître (règle 2, T14d) ni survivre à leur activation (règle 3).
- **GSDA-15** — la contrainte de rédaction de l'arbitrage 24-03 est tenue par une machine, chacune
  de ses deux moitiés prouvée détectable séparément.
- **GSDA-02** — le câblage `--ws`/`GSD_WORKSTREAM` du plan 24-08 est gardé **par agent**, et le
  plafond ADR-029 de `vf-dev-manager.md` est compté et muté.

## Zone grise (non tranchée ici)

**La liste blanche `ROUTED_CONDITIONAL` est tenue à la main.** Elle nomme aujourd'hui
`gsd-graphify` et `gsd-profile-user`, et l'assertion (a) la garde **vivante** (aucun nom mort). Rien
ne garde en revanche l'inverse : une **nouvelle** entrée conditionnelle ajoutée à la carte sans être
inscrite ici serait vue par le gate d'activation (règle 2, au niveau du toggle) mais **pas** par
T14d (au niveau de la ligne de routage). Les deux étages ne se recouvrent pas complètement. Dériver
la liste depuis la carte plutôt que la déclarer fermerait ce reliquat — c'est un changement de forme
que ce plan n'a pas mandat de prendre, la forme « liste blanche + `case` » lui étant explicitement
prescrite par `24-PATTERNS.md`.
