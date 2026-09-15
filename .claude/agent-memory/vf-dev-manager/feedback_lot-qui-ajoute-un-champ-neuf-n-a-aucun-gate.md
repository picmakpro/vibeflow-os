---
name: lot-qui-ajoute-un-champ-neuf-n-a-aucun-gate
description: Un lot qui introduit un champ, une section ou un contrat NEUF est vert à vide par construction — aucune suite existante ne peut l'asserter ; exiger une sonde scopée livrée AVEC le lot
metadata:
  type: feedback
---

Quand un lot **ajoute** quelque chose qui n'existait pas (champ, section, contrat, format), toutes
ses vérifications héritées sont **vertes avant même la première édition**. La suite du module ne
peut pas asserter le champ neuf : il est neuf. Les gates génériques (plafond de lignes, lint de
frontmatter, « la suite passe ») mesurent autre chose. Résultat : un exécuteur qui n'écrit **rien**,
ou qui écrit **au mauvais format**, sort `0 KO`.

**Exiger dans tout mandat de ce type une `<automated>` par tâche, SCOPÉE à la section visée**
(`awk` bornant le titre), qui asserte les marqueurs du contenu neuf — et faire **prouver les deux
sens** : rouge avant édition, vert après. Une sonde ajoutée sans cette double preuve est du
décor.

**Why:** Phase 40, 2026-09-15. Trois des quatre bloquants du plan-check sont ce défaut :
- Le lot des émetteurs E6 : ses 4 vérifications (≤ 250 lignes, `check-agents --strict`, suite du
  module, compte de suppressions) étaient vertes à vide. Le lot existait **parce que**
  `grep -ic exit_code` rendait 0 — et il ne gatait pas ce constat en sens inverse.
- Le lot du gate de sortie : six mutations décrites **en prose**, zéro exécutée ; un compteur
  `grep -c 'NON OPPOSABLE' = 0` mesuré sur un run vert par hypothèse, donc valant `0` que les
  assertions existent ou non — incapable par construction de détecter une garde **absente**.
- Le lot doctrine : les deux propriétés les plus exposées (absence de plafond chiffré sur le
  fan-out, encadré « extension non livrée ») relues à l'œil, sans témoin.
Aucun n'était visible à la relecture : les plans étaient bien raisonnés et citaient les bons
principes. Voir [[preuve-incapable-de-rendre-rouge]] et
[[mutation-qui-echoue-pour-la-mauvaise-raison]].

**How to apply:** trois questions à poser à tout plan qui ajoute du neuf.
1. « Cette vérification est-elle verte **aujourd'hui, avant toute édition** ? » Si oui, elle ne
   prouve pas le livrable. **Le fais mesurer**, ne le déduis pas.
2. « Le garde mesure-t-il le **même axe** que le risque ? » Un risque d'AJOUT gardé par un compte
   de SUPPRESSIONS est vert par construction sur le scénario visé.
3. « Un `<verify>` teste-t-il un littéral que l'`<action>` ne prescrit pas ? » L'exécuteur fidèle à
   l'action rend alors rouge sa propre vérification. C'est une **classe**, à balayer sur tout le
   plan, pas un cas isolé.

Corollaire : un `<automated>` du type `test -z "$(git status --porcelain)"` est **rouge avant le
départ** sur un dépôt qui porte des artefacts non suivis (ici 24), et pousse l'exécutant à
« nettoyer » — donc à supprimer de la mémoire d'agent ou de l'état de planning. Toujours mesurer la
propreté **contre une référence prise avant la tâche**, jamais contre la vacuité absolue.

**Quatrième question, ajoutée le 2026-09-15 — « le plan DÉLÈGUE-t-il sa couverture à un test
existant ? »** Si oui, c'est une **affirmation sur le comportement d'un tiers**, jamais une preuve.
Fais-la **mesurer** : injecte le défaut dans une COPIE, lance la suite, observe.
Mesuré en Phase 40 : un plan interdisait en prose une ancre parasite ``**`gate`**`` et déléguait la
couverture à T24/T26, en l'assumant honnêtement par écrit. Le juge avait confirmé le mécanisme amont
(le découpage en blocs imprime bien TOUS les blocs portant l'ancre) — donc le raisonnement était
juste. **T26 ne rougit pourtant PAS** sur un second bloc `gate` dépourvu de champ interdit : seul un
bloc ajoutant EN PLUS une graphie interdite le fait. La délégation était fausse ; il a fallu une
sonde dédiée. Un raisonnement amont correct ne prouve pas le rouge en aval.
