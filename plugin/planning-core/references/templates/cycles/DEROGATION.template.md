---
statut: "[abandonné | remplacé | gelé] par [auteur]"
remplace_par: ""
le: "[AAAA-MM-JJ]"
motif: "[pourquoi]"
---

# Dérogation

> Dérogation **nominative**, non dérivable (spec D-03 de la spec ; champ `statut:` qui nomme
> l'auteur — P44-D-07). Forme exacte attendue : `<dérogation> par <auteur>`. Sans auteur nommé,
> le recalcul dérive `indéterminé` (`derogation-sans-auteur`). `gelé` n'est **pas** un état
> terminal — une unité gelée peut reprendre.

Ce fichier ne modifie **jamais** `PLAN.md` : une dérogation ne change jamais le hash du plan
(voir `references/modele-cycles.md` § Fichiers du modèle, `DEROGATION.md`).

`remplace_par:` ne se renseigne que pour un statut `remplacé` (référence de l'unité qui prend le
relais).
