---
name: preuve-du-chemin-heureux-ne-couvre-pas-l-echec
description: Deux preuves solides du chemin nominal (suites vertes + égalité md5 fichier à fichier) n'ont rien dit d'une régression majeure vivant sur le chemin dégradé — exiger une injection de panne
metadata:
  type: feedback
---

Quand un lot prétend « refactor mécanique, zéro changement de comportement observable », exiger
**une injection de panne réelle** dans la preuve, pas seulement des suites vertes et une comparaison
d'artefacts. Une preuve d'équivalence se mesure presque toujours sur le **chemin nominal** et ne dit
**rien** du chemin d'échec.

**Why:** mesuré Phase 31 (2026-08-16), migration de ~35 sites d'écriture. Deux juges lancés en
parallèle sur le **même** lot :
- la **vérification** a prouvé l'absence de changement de comportement par **égalité md5 fichier à
  fichier**, 262 fichiers, 6 modules, 0 ligne divergente ;
- la **revue** a prouvé **quatre régressions bloquantes**.

Les deux avaient raison. En bash, dans `a && b && c`, seule la **dernière** commande déclenche
`errexit` : plusieurs sites portaient leur `cp` en position **médiane** (ou sous `|| true`), donc
exempté ; la migration a réduit chaque site à **un appel unique de helper**, promu mécaniquement en
dernière position — son échec avortait désormais tout le script. Rayon de souffle : un fichier
illisible dans le cache d'**un** module faisait avorter `install --all`, et **tous les modules
suivants n'étaient jamais installés**. Les trois suites (15/15, 19/19, 32/32) restaient vertes parce
qu'elles n'exerçaient que le cas « **glob non satisfait** », **jamais un échec réel** de `cp`/`find`.

**How to apply:**
1. Dans tout mandat de refactor mécanique, exiger la preuve sous la forme **deux codes de retour** :
   panne injectée (`chmod 000` sur une source) **avant** le correctif et **après**. Un `rc` seul ne
   prouve rien.
2. Dans le mandat des juges, poser explicitement la question « **qu'est-ce que ce vert ne prouve
   pas ?** » et nommer les chemins non exercés (échec réel, répertoire vide mais lisible, symlink,
   scope non testé) — c'est cette question qui a produit le finding, pas la relecture du diff.
3. Ne jamais conclure d'un accord entre deux juges : ici l'accord aurait été trompeur. **Leur
   désaccord était l'information.** Lancer les juges sur des **angles** différents (conformité vs
   exécutabilité, nominal vs dégradé), pas sur le même axe en espérant une confirmation.

Voir [[liste-de-cas-ne-ferme-pas-une-classe]] (quatre point-fixes ne ferment pas une classe),
[[mutation-qui-echoue-pour-la-mauvaise-raison]] et
[[revalider-les-plans-ecrits-avant-les-faits]] (le vert interne d'un pipeline ne compte pas).
