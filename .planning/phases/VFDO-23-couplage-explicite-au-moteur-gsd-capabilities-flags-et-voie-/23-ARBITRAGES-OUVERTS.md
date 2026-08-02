# Phase 23 — Arbitrages ouverts, remontés à l'humain (mission du 2026-08-02, reprise)

Consignés **au fil de l'eau** et non à la clôture : la mission précédente a été fermée
accidentellement et seul le disque a survécu. Aucun de ces points n'a été tranché par un agent.

---

## O-1 — La paraphrase d'A-4 par `vf-dev-manager.md` : index légitime ou infraction ADR-030 ?

**Le fait, vérifié par mutation.** Le renvoi de `vf-dev-manager.md` §Contrôle de flux dit d'un
côté « Applique-la telle quelle — **ne la reformule JAMAIS ici** (ADR-030, une seule voix) », et
de l'autre reformule dans la même puce : « superviser : tu réponds à l'attente humaine ;
autonome : gel du nœud, ADR-031 ». Cette paraphrase emploie des **graphies propres** (singulier,
tournures non canoniques) que ni `T27_ASK_RE` ni `T27_FREEZE_RE` ne reconnaissent. **Échanger
`superviser` ↔ `autonome` dans cette paraphrase laisse la suite à 93 OK / 0 KO** — un troisième
foyer affecté du mode d'échec exact que B4 et B5 viennent de fermer ailleurs.

**Ce qui a été fait sans trancher** (nœud `exec-01c2`) : le gate est étendu pour **mordre sur la
paraphrase telle qu'elle est écrite aujourd'hui**, avec contrôle de faux rouges sur les 13 `.md`
de doctrine. Aucun texte de doctrine n'a été modifié. Le correctif est **valable dans les deux
issues** ci-dessous.

**La question qui reste, et qui appartient à l'humain :**

> Le renvoi de `vf-dev-manager.md` a-t-il le droit de **résumer** A-4 dans ses propres mots, ou
> doit-il se réduire à un **pointeur nu** vers le foyer ?

- **Issue 1 — pointeur nu.** Applique à la lettre la règle déjà écrite dans la puce elle-même.
  Coût : un lecteur de l'agent seul ne voit plus le garde-fou ADR-031 sans ouvrir la référence.
- **Issue 2 — paraphrase licite.** Il faut alors amender la puce, qui s'interdit textuellement ce
  qu'elle fait, et assumer que les motifs du gate couvrent durablement deux graphies.

---

## O-2 — `T25b` impose l'ordre armement → désarmement (nœud `exec-01b`)

Une rédaction qui placerait le désarmement **avant** l'armement rougit. C'est délibéré — l'ordre
**est** la garantie d'A-1bis, et l'assouplir reviendrait à dire que le geste 5 du manager suffit,
ce qu'A-1bis nie explicitement. Mais c'est une **contrainte de rédaction imposée à tout futur
auteur** de la brique Cadrage. Documentée dans l'en-tête de T25b plutôt qu'assouplie seule.

## O-3 — `T27 (c)` interdit de nommer les deux modes pour une même disposition (nœud `exec-01a`)

Une clause disant « superviser comme autonome » sur la disposition de question ou celle de gel
rougit désormais. Voulu : sur ces deux dispositions-là, l'indifférenciation **est** la faute
(c'est B5). Mais c'est une contrainte nouvelle sur la rédaction future, documentée en commentaire.

## O-4 — Le libellé d'`ok` de T27 sous-déclare (nœud `exec-01a`)

Il annonce 3 mutants alors que 5 tournent. **Gelé volontairement** : le réécrire ferait
disparaître une entrée de l'ensemble des libellés `ok`, seul invariant permettant de prouver d'une
version à l'autre qu'aucune assertion n'a été retirée en douce. Les messages de KO restent exacts.

## O-5 — Les mutants M2/M3 de T27 sont ancrés sur une tournure de prose (nœud `exec-01d`)

Ancrés sur `en mode **superviser**, c` — une simple majuscule les rend **no-op**. Le garde `cmp -s`
le dit fort, donc pas de faux vert : mais c'est un **rouge bruyant** sur une réécriture pourtant
licite. Faut-il les réancrer, et sur quoi ? (Les autres mutants de la phase ont été réancrés sur
des éléments **structurels** — entrée de table, token mesuré, intitulé de brique.)

## O-6 — Cinq défauts re-dérivés pour quatre étiquettes historiques (nœud `exec-01d`)

Le détail de **B2, B3, B7, M1** a disparu avec la mission fermée accidentellement ; seul l'énoncé
de famille a survécu. La re-dérivation a produit **cinq** défauts, dont **un seul** est attribuable
avec certitude (`T18`, nommé dans l'énoncé survivant). Les quatre autres — `T17`, `T23`,
« T25 fermeture » sans compteur d'atteinte, `T21d` vert à vide — sont **fermés**, mais sans
garantie qu'ils recouvrent B2/B3/B7/M1.

**Question** : considère-t-on B2/B3/B7/M1 comme **soldées** par cette liste, ou consigne-t-on
l'écart d'attribution comme dette de traçabilité ? *(Choix par défaut appliqué en attendant :
l'écart est consigné ici, aucune étiquette n'est déclarée soldée par assimilation.)*

## O-7 — Assertions au libellé plus fort que la mesure, laissées ouvertes (nœud `exec-01d`)

`T10`, `T15`, `T7` (« new-project **encadré** »), `T25 présence`, `T22 captation` promettent une
**relation** dans leur libellé et mesurent une **présence**. Non gatées **délibérément** : la seule
relation mesurable serait une proximité de prose, donc une contrainte de rédaction imposée à tout
futur auteur pour un gain marginal — exactement le coût que le point 5 documente. Une assertion
cosmétique aurait été pire. À trancher : durcir, reformuler les libellés pour qu'ils cessent de
sur-promettre, ou laisser en l'état.

---

## Points 5 à 7 — RÉINSTRUITS le 2026-08-02, chiffrés, non tranchés

Ils devaient être réinstruits **après** la réécriture commandée par A-1bis..A-4. C'est fait. Les
faits ci-dessous permettent de décider s'ils partent en **dette assumée** ou s'ils sont **soldés**.

### 5. `rc=3` contraint la forme rédactionnelle — **toujours vrai, et le diagnostic d'époque était incomplet**

Le mode d'échec observé n'est pas `rc=3` mais **`rc=1`** (faux rouge dont le message *accuse la
doctrine*) et **`rc=2`** (« rien n'a été mesuré »). Trois réécritures en prose sémantiquement
complètes du bloc Verdict : P1 → 4 KO · P2 → 2 KO · P3 → 1 KO, et ce dernier n'est qu'un garde de
no-op de mutant (cf. O-5). **La prose reste donc possible**, sous deux contraintes cumulatives :
(1) chaque étiquette de statut mesurée doit être **immédiatement suivie** d'un marqueur
(`→ ⇒ — – :`) ; (2) dès que la forme F1 s'applique, les deux motifs doivent être **après**
l'étiquette — F1 court-circuite F2 et n'est jamais retentée.

### 6. Porosité de T25 — **l'estimation d'époque doit être corrigée**

Ajouter `,` aux séparateurs ne « ferme pas le trou » : il en ferme **3 formes sur 4** (celles à
virgule) ; une négation étrangère **sans** virgule continue de passer. Le coût reste **un seul**
faux rouge (négation avec incise, « JAMAIS, sous aucun prétexte, en mode … »), mais les fixtures
sont désormais **11** (6 T25 + 5 T25b), pas 6 — et l'ajout les laisse **toutes** au même verdict
(suite à 99 OK / 0 KO avec `,`). **Occurrences réelles aujourd'hui : 0 de part et d'autre** — la
sonde voit 3 briques Plan/Exécution et 0 motif de mode à l'intérieur. **Le débat est entièrement
prospectif** : l'écart penche vers le faux vert, sans faux vert constaté.

### 7. Déclassement de T26 A′ — **la piste des positions de clé JSON rapporte peu**

| Graphie | bloc `gate` | bloc `reprise` | total |
|---|---|---|---|
| stricte `"clé":` | 1 (`"gate":`) | **0** | **1** |
| élargie `` `clé`: `` | 1 | 2 | 3 |

En graphie **stricte** : une seule position mesurable et **zéro** sur le bloc `reprise` — le garde
« ≥1 clé mesurée **ou** renvoi explicite » retomberait sur la branche « renvoi », c'est-à-dire sur
le contrôle que T26 A′ effectue **déjà**. En graphie **élargie** : **1 faux rouge garanti
aujourd'hui** (`` `tools:` `` est un champ de frontmatter YAML cité en prose, pas une clé JSON), et
`statut` est un champ de **premier niveau** ADR-053, pas un sous-champ de `reprise` — l'accepter
rouvrirait la liste à mailles finies que le déclassement avait justement fermée.

## Rappel — écarté pour ce plan, reversable au débat

La **3ᵉ voie d'A-1bis** (le manager porte le cadrage lui-même, il a `AskUserQuestion`) supprime le
problème à la racine mais constitue un changement structurel du cycle. À reverser au débat **si**
la Lacune 5 / plan 23-05 rouvre la voie unique d'invocation.
