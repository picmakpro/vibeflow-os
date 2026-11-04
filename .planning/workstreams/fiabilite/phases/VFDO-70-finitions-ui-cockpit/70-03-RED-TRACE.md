# 70-03 — Traces du départ rouge (UIFN-06, UIFN-04)

Régime P70-D-08. Départ rejoué le 2026-11-04 sur le commit `7a3ace3d` (branche `feat/phase-70-03`), avant toute correction.

## État de départ

`test-cockpit-chrome-fr.sh` : 38 PASS / 21 FAIL ; `test-cockpit-onglet-code.sh` : 20 PASS / 1 FAIL.

- F2 — attendu `[]`, obtenu `["Calls","important","minor","up ·","{} call","{} calls","{} change","{} changes","{} endpoint","{} endpoints","{} module","{} modules","{} place","{} places","{} planned file","{} planned files","{} step"]`
- F10 — attendu `[]`, obtenu `["{} files and endpoints still use generated names. Run the skill again to describe them."]`
- F11.1 `Calls · 3` — obtenu : non traduit
- F11.2 `up ·`, F11.3 `3 calls`, F11.4 `1 call`, F11.5 `Show 2 changes`, F11.6 `1 step`, F11.8 `1 important · 1 worth fixing · 1 minor`, F11.9 `3 endpoints`, F11.12 `Claude Code and GSD`, F11.17 `at the top.` — obtenu : non traduit
- F11.10 `Uses connection` — obtenu `Utilise liens` (valeur fautive connue)
- F11.11 `Resolve on the map` — obtenu `Resolve on the` (mot anglais « Resolve »)
- F11.13 — obtenu `3 fichiers et endpoints still use generated names. …` (mot anglais « endpoints »)
- F11.14 — obtenu `Appuyez sur Lecture pour la suivre …` (aucun bouton « Lecture » : le bouton affiché est « La lire »)
- F11.15 — obtenu `Elle s'appuie aussi sur Stripe and Postgres. …` (mot anglais « and »)
- F11.18 — obtenu `Les réponses viennent de le CLI Claude Code …` (« de le » non contracté)
- F11.19 — obtenu `… pas une revue complète de Anthropic.` (« de » devant voyelle non élidé)
- F12.1 — attendu `Contrôle de santé`, obtenu `Contrôle De Santé`
- F12.2 — attendu `[]`, obtenu `["ready_to_execute","ready_to_execute"]` (appartient à 70-06)
- C5.1 — attendu `Dossier solo : 1 fichier de code.`, obtenu `Dossier solo : 1 fichiers de code.`

## Suite : recette

Correction ciblée demandée par le manager d'après le juge Playwright de la recette (P70-D-04). Départ rejoué le 2026-11-04 sur `94078aab` (branche `feat/phase-70-finitions-ui`), témoins posés avant toute correction.

`test-cockpit-chrome-fr.sh` : 61 PASS / 9 FAIL (F11.20 à F11.24, F13.1 à F13.4) ; `test-cockpit-avancement.sh` : 60 PASS / 2 FAIL (A13.2, A13.3).

- F11.20 `Inside kpi-analyst` — non traduit (le gabarit court « Inside {} » ne s'applique qu'à un nombre)
- F11.21 / F13.1 `Updated 3 minutes ago` — attendu `Mis à jour il y a 3 minutes`, obtenu `il y a 3 mis à jour minutes` (régression de l'ordre des gabarits : « {} minutes ago » passe avant « Updated {} »)
- F11.22 / F13.3 `Recent work: Recent work` (fil d'Ariane) — attendu `Travail récent`, obtenu `Travail récent : Travail récent`
- F11.23, F11.24 / F13.4 `2×click`, `right-click` — non traduits (infobulle de survol, menu du clic droit) ; `click` rendait « cliquer »
- F13.2 `Inside kpi-analyst` / `Inside equipe-produit` — attendu `["Dans kpi-analyst","Dans equipe-produit"]`, obtenu `[null,null]`
- A13.2, A13.3 — attendu `Trajectoire d'alpha`, obtenu `Trajectoire de alpha` (élision absente à la source, `vf-cockpit-project.mjs`)
- Garde d'ordre (cas 3) : F11.21 juge les durées coupées par « mis à jour » ; F13.1 pose la forme exacte ; F10 reste en place.

Hors de mes fichiers (cas 5 sous-titre et cas 6 visite), constatés sans correction : voir le SUMMARY.
