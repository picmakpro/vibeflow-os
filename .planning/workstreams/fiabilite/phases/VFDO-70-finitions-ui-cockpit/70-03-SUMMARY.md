---
phase: 70-finitions-ui-cockpit
plan: 03
requirements-completed: [UIFN-06]
requirements-partial: [UIFN-04]
commits: [9c1a955e, 85228499, 1b9c485e]
---

# 70-03 — anglais résiduel et coquilles du chrome : résumé

## Livré

- `80-vf-fr.js` : gabarits triés par texte fixe décroissant ; un gabarit à valeur « singulier|pluriel » ne s'applique que derrière un nombre ; élision (« d'Anthropic ») et contraction (« du CLI ») là où une variable suit « de » ; « and » final traduit dans les listes des deux gabarits qui en portent (`LISTES`) ; en-tête de panneau sans capitale à chaque mot (règle posée après le retour `?lang=en`, P70-D-03 intact).
- `79-vf-fr-dict-b.js` : 18 entrées (formes O5, pluriels construits, « Uses connection », « Resolve on the map », « Claude Code and GSD », « at the top. »). Constats de Santé non traduits (P67-D-20).
- `78-vf-fr-dict-a.js` : « Appuyez sur « La lire » » (P70-D-02), deux valeurs corrigées sur place.
- `vf-cockpit-code.mjs` : accord « 1 fichier de code ».
- `vf-cockpit-fr-exclusions.json` : inchangé (F4 verte, aucune exclusion sans objet, aucune ajoutée).

## Points à connaître

- P70-D-11 : le jalon affiché « Trajectoire de equipe-… » n'est pas corrigé ici ; seule l'élision s'applique désormais (« d'equipe-… »). La 69 ne l'a pas corrigé (non vérifié dans ce plan).
- « {} module » : « module » est identique en français, F2 rougit alors sur « {} modules » sans exclusion ; rendu « {} composant|{} composants » faute d'exclusion prévue par le plan. À trancher (ask-user) : garder « composant » ou ajouter l'exclusion « {} modules » avec raison (alors « module » partout, cohérent avec le type de carte).
- « important » → « prioritaire » (même raison : « important » identique).
- Élision limitée aux voyelles : le « h muet » n'est pas élidé (aucun moyen de distinguer h aspiré dans une donnée du lab).
- Le « and » final des listes de la visite est traduit même si le dernier nom d'une liste contient lui-même « and ».
- Taille : 78 = 242, 79 = 108, 80 = 132 lignes (plafond 300).

## Rejeu final

- chrome-fr 58 PASS / 1 FAIL : F12.2 seule (statut brut `ready_to_execute`) → 70-06.
- onglet-code 21/0 ; vendor 77/0 ; projet 56/0 ; assemblage et marque-blanche exit 0.
