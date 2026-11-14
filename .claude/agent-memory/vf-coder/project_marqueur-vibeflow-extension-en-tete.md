---
name: marqueur-vibeflow-extension-en-tete
description: Dans plugin/cockpit/.../ui/*.js, la première ligne doit rester « // VibeFlow ( » ; tout commentaire posé avant fait rougir F2 de chrome-fr.
metadata:
  type: project
---

L'inventaire de `vf-cockpit-fr-inventaire.mjs` ne saute un bloc d'extension (déjà en français) que si sa PREMIÈRE ligne non vide est `// VibeFlow (` (regex MARQUEURS_FR). Un amendement écrit au-dessus de cette ligne (02-vf-telephone.js, 2026-11-06) a fait lister « Plus d'actions » en non traduit : `test-cockpit-chrome-fr.sh` F2 rouge, sans rapport apparent avec la modif.

**Why:** le rouge pointe une chaîne, pas la cause (l'en-tête déplacé) ; 3 chaînes sont passées de 596 à 599 dans l'inventaire.

**How to apply:** ajouter un commentaire APRÈS le bloc d'en-tête d'origine, jamais avant ; rejouer `chrome-fr` dès qu'un `ui/*.js` change d'en-tête.
