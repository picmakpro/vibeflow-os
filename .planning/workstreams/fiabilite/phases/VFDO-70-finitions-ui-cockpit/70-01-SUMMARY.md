---
phase: 70-finitions-ui-cockpit
plan: 01
requirements-completed: [UIFN-07]
requirements-witnessed: [UIFN-06]
commits: [a108cc20, 4f60e6e9]
---

# 70-01 — garde du français durci : résumé

Ce plan n'écrit que des témoins ; aucune chaîne n'est corrigée (70-03 et 70-06 s'en chargent).

## Ancrage (P70-D-14)

Tête `a20b06a7`, base `794c6dba`, module `v1.1.1`, `ui/71` et `ui/72` présents, onze symboles tous présents (comptes dans `70-01-RED-TRACE.md`).

## Livré

- `vf-cockpit-fr-inventaire.mjs` (175 lignes) : tracé SVG à chiffre obligatoire, valeurs des clés d'interface (`word`, `label`, `group`, `title`, `hint`, `kicker`, `note`, `text`), mots courts (up, of, at, in, on, to, by), pluriels `plural(n, 'mot')` en deux formes. Aucune exclusion neuve.
- `test-cockpit-chrome-fr.sh` : F9 (inventaire), F10 (ordre des gabarits), F11 (19 formes rendues), F12 (Chrome, sautée audiblement sans navigateur) ; F3 et le témoin de F2 comparent désormais aux non-traduits de base (sinon F2 rouge les rougissait par contagion).
- `chrome-fr-rendu.mjs` : sonde du texte visible (`innerText`) des onglets Code et Projet.
- `test-cockpit-onglet-code.sh` : C5 (accord « 1 fichier de code »).
- `70-01-RED-TRACE.md` : ancrage et rouges par forme.

## À corriger en 70-03 / 70-06 (nommés par F2, F10, F11, F12, C5)

- F2 : `Calls`, `important`, `minor`, `up ·`, `{} call(s)`, `{} change(s)`, `{} endpoint(s)`, `{} module(s)`, `{} place(s)`, `{} planned file(s)`, `{} step`.
- F10 : « {} files and endpoints still use generated names… » capturé par « {} and {} ».
- F11 : Uses connection, Resolve on the map, Claude Code and GSD, Press Play…, « Stripe and Postgres », « de le CLI », « de Anthropic », « at the top. », 3 calls / 1 call / 1 step / 3 endpoints / Show 2 changes, santé « 1 important · … ».
- F12.1 : capitalisation CSS « Contrôle De Santé » ; F12.2 : statut brut `ready_to_execute` (STATUT de `ui/00-vibeflow.js`).
- C5.1 : « 1 fichiers de code » (`vf-cockpit-code.mjs`).
Note : F11 ne contient pas « ⌫ up » (deux nœuds distincts) ; le nœud rendu est « up · ».
