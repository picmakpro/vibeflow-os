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

---

## Rappel — points 5 à 7 hérités du rapport du 2026-08-02

À réinstruire **après** la réécriture commandée par A-1bis..A-4, puisque ce sont ces réécritures
qui subissent la contrainte. Statut à la clôture : voir le rapport de mission.

5. **`rc=3` contraint la forme rédactionnelle** — une réécriture en prose sémantiquement correcte
   du bloc Verdict rougit.
6. **Porosité de T25** — une prescription rédigée avec une négation dans la même clause échappe.
   Coût chiffré : ajouter `,` aux séparateurs ferme le trou et préserve les 6 fixtures, au prix
   d'un seul faux rouge (négation avec incise). Écart actuellement orienté vers le **faux vert**.
7. **Déclassement de T26 A′** — piste retenue : gater sur les **positions de clé JSON**, couplé à
   un garde « ≥1 clé mesurée ou renvoi explicite ».

## Rappel — écarté pour ce plan, reversable au débat

La **3ᵉ voie d'A-1bis** (le manager porte le cadrage lui-même, il a `AskUserQuestion`) supprime le
problème à la racine mais constitue un changement structurel du cycle. À reverser au débat **si**
la Lacune 5 / plan 23-05 rouvre la voie unique d'invocation.
