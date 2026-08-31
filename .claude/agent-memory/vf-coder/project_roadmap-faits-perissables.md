---
name: roadmap-faits-perissables
description: Les sections ROADMAP de ce repo embarquent des faits mesurés contre une version amont datée — 8 sur 23 avaient péri en 4 jours ; toujours re-mesurer avant de cadrer
metadata:
  type: project
---

Les sections `### Phase N` du `.planning/ROADMAP.md` de ce dépôt ne décrivent pas seulement une
intention : elles **embarquent des faits mesurés** (numéros de ligne amont, valeurs de compteurs,
états de PR, décomptes de fichiers), datés et établis contre une version précise de
`@opengsd/gsd-core`. Ces faits **périment vite**.

**Why:** mesuré au cadrage de la Phase 24 (2026-08-04). Les faits de la section dataient du
2026-07-31 contre `gsd-core@1.9.0` ; en **4 jours**, la machine était passée en **1.9.1** et
**8 faits sur 23 avaient péri** — dont **3 qui inversaient la conclusion de leur item** :

- un compteur de ledger (`open_count` 2 → 1), et la fenêtre restante s'est révélée infermable ;
- une capacité présentée comme « portée en config par le moteur » qui n'a en réalité **aucun
  consommateur** (la clé est validée et documentée, rien ne la lit) ;
- un gate affirmé existant (« un gate de commits conventionnels existe ») qui **n'existe pas** ;
- une PR ouverte en `CHANGES_REQUESTED` devenue **CLOSE**, ce qui change le statu quo de fait.

Trois faits entièrement **nouveaux** sont aussi apparus, invisibles depuis le ROADMAP.

**How to apply:**

- Ne recopier **aucun** fait du ROADMAP dans un `CONTEXT.md`. Marquer chaque assertion re-testée
  **CONFIRMÉ** / **PÉRIMÉ (nouvelle valeur : …)** / **NON VÉRIFIABLE (pourquoi)** — et écrire dans
  le CONTEXT que les valeurs du cadrage **priment** sur celles du ROADMAP.
- Vérifier **en premier** la version amont réellement installée (`~/.claude/gsd-core/VERSION`) et la
  version du dépôt (`VERSION`) : tout le reste en dépend, et les numéros de ligne amont cités par le
  ROADMAP glissent d'une version mineure à l'autre (constaté : `pr-branch.md:232-234` → `:235-236`).
- Se méfier des **décomptes** hérités : ils ont été produits par une méthode non écrite. Re-mesurer
  avec sa propre méthode et **dire laquelle** — 16/91 workflows annoncés, 7/91 re-mesurés en
  `awk`+`comm`. La divergence venait de la méthode, pas d'une régression, mais elle durcissait la
  conclusion. **Et le 7/91 n'a pas tenu non plus** : re-mesuré en fin de phase 24, c'est **5/91**
  (et 43 workflows aveugles, pas 42) — alors que les grandeurs voisines du même constat (91
  workflows, 45 chemins en dur) se reproduisaient à l'identique. Un décompte hérité reste faux même
  quand ses voisins de tableau sont justes : re-mesurer **chaque** grandeur qu'on écrit, pas
  l'échantillon. Voir [[diff-proxifie-utiliser-comm]] : un décompte hérité d'un `grep` piped sur ce
  poste est probablement tronqué.
- Un chiffre d'**arbitrage** se re-mesure comme un chiffre de ROADMAP — l'arbitrage fige une
  décision, pas les mesures qui l'ont motivée. Quand la re-mesure diverge, écrire **les deux** (le
  fait du jour, et l'ancien attribué à sa source), et signaler au manager les ADR à venir qui vont
  citer le périmé.
- Prévoir le **recalage du ROADMAP** comme livrable de fin de phase (les §Phase 20 et §Phase 21 l'ont
  déjà été) — sinon le prochain cadrage repart des mêmes faits morts.
