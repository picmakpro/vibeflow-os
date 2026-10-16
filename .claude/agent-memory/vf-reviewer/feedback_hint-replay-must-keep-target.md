---
name: hint-replay-must-keep-target
description: Un hint de refus JSON doit etre rejouable tel quel et viser la MEME cible ; rejouer les hints litteralement sur dep jetable (Phase 57 driver-lock)
metadata:
  type: feedback
---

Quand un script nomme une commande dans un champ `hint`, la rejouer LITTERALEMENT (sans ajouter ce que le JSON
porte a cote) et verifier qu'elle vise le meme objet. Phase 57 : `acquire --ws=alpha` sur verrou perime rend
`hint: "driver-lock.sh takeover --owner=X --step=<etape>"` sans `--ws` ; rejoue tel quel, il reprend le verrou de
DEPOT perime d'un autre (acquired:true, scope depot). Prose mission-flow.md:80 et vf-dev-manager.md:49 montrent
aussi `takeover` sans `--ws`.

**Why:** les hints neufs d'une phase de scope (compartiment) heritent d'anciens gabarits de message ; seul un rejeu
litteral le revele, ni la suite (qui passe --ws a la main) ni la relecture.
**How to apply:** pour toute phase qui ajoute une dimension de cible (ws, scope), grep les `"hint"` du script et
rejouer chacun sur dep mktemp ; comparer scope/ws de la reponse a celui du refus. Voir aussi [[preuve-incapable-de-rendre-rouge]] cote suites :
muter les comportements NON listes par le plan (ici guard : verrou perime, cible git incertaine, pathspec positionnel survivent).
