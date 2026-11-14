# 80-fixclav — trace ROUGE

Cas CL3.3c de `test-cockpit-couloirs.sh` (pilote `chrome-couloirs-clavier.mjs`, section `cl3arr`) : arrivée sur Projet par
`VF_ONGLETS.aller('projet')` depuis `/`, sans sélection.

Attendu : `[[],"vf-projet-titre",null]`

Obtenu (avant correctif) :
`[["VibeFlow onglets : arrivée : Cannot read properties of null (reading 'querySelectorAll')"],"vf-projet-titre",null]`

Cause : `repli()` pose le focus sur le h1 par `poser()`, qui appelle `itinerer(h1)` ; `membres(h1)` fait
`h1.closest('.vp-details').querySelectorAll(...)` et `closest` rend null.
