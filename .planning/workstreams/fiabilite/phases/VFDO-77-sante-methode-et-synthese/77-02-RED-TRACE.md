AVANT da48d65806f9197ae7b2269b5c57582f941393ee

# 77-02 — trace des rouges (témoins écrits avant le code)

Base : tête de départ ci-dessus (fusion de 76-04 dans la Phase 77). Lab de mesure : le worktree de la phase.

## test-cockpit-burnup.sh — 3 PASS / 22 FAIL à la base
- BU0 — attendu `CLOTURE,INSCRIPTION,burnup,dates`, obtenu `MODULE-ABSENT` (module absent).
- BU1 — attendu les 16 lignes `n|inscription|clôture` en dur, obtenu `MODULE-ABSENT`.
- BU9 — attendu `v1.0 Démo|2|3` puis `true|67`, obtenu `||` puis `false|` (champ `meta.vf.burnup` absent).
- RT2 — attendu `absent`, obtenu `present` (le marqueur de `last_activity_desc` est dans le graphe sérialisé).
- RT3 — attendu `false`, obtenu `true` (`meta.vf` porte encore la clé de la prose).
- Verts à la base, par construction : RT1 (sonde positive sur `current_phase_name`), BU9 « lab sans jalon : champ absent » et « le graphe valide cockpit-project@1 ».

## test-cockpit-blocages.sh — 3 PASS / 14 FAIL à la base
- BL0 — attendu `BORNES,PLACEHOLDERS,condensat,lireBlocages,normaliser`, obtenu `MODULE-ABSENT`.
- BL10 — attendu l'égalité avec la lecture du planning et un `h` de 12 hexadécimaux, obtenu `undefined false`.
- BL11 — attendu `true|true|true|0`, obtenu `false|false|false|0` (ni `burnup`, ni `blocagesState`, ni `base.h` déclarés).
- Écart de grammaire : le contrat range les facultatifs de `meta.vf` sous `optionnels.metaVf` (posé par 76-04), pas sous un sous-bloc `meta.vf` : BL11 lit cet endroit.

## test-cockpit-projet-visite.sh — 114 PASS / 1 FAIL à la base, durée 645 s
- R3.25 — attendu `[true]`, obtenu `[false]` : le texte de `.vf-now` contient `alpha00` (prose recopiée). R3.24 reste verte (sonde positive).
- Aucun autre rouge : pas de « rouge accepté ».
