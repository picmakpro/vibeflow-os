# Mission — Phase 79, segments b et c : 9 plans du socle du cockpit, phase à 22/22 (2026-11-14)
> Suite de `2026-11-13-phase-79-execution-a.md`. Compartiment `fiabilite`, branche `feat/phase-79-socle-cockpit`. Régime allégé
> (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Ni bump ni tag (gel).
## Livré (plan, sha de sortie)
- 79-13 route de frise (SOCL-17) 238aed8b, audit b54ccb77 ; 79-14 flux partagé, veille de 45 s (SOCL-18) 4d5fe248.
- 79-15 route graphe, témoin d'export (SOCL-19, 23) 2fb2d9d6 ; 79-16 coquille statique (SOCL-20) 898511f0 et huit correctifs.
- 79-17 magasin `VF_ETAT` (SOCL-21) 3f851b6c ; 79-18 mise en page en worker (SOCL-22) d0bae077, audit AU18 fa04af7e.
- 79-19 journal des attentes : sonde S0 OUI, fermé sans code (SOCL-24) 6f104e1a ; 79-20 README, CHANGELOG, version, gate V12
  (SOCL-25) 85cbb1c5 ; 79-22 transcript et détail par la table en mémoire (SOCL-27) bf114792.
- Hors plan : témoin du retrait du secret (J1-08) 49c72d75 ; clé planning 246598c3 ; C2 du magasin fc102a6a ; fusion bf51fa67.
- Ledger SOCL-01 à 27 : tout fait (SOCL-24 close par la sonde, « journal non construit »).
## Écarts
- 79-13 : `cibles` nulles pour une voie de forme inconnue. 79-14 : F2.1 et F2.2 retournés en « un seul flux ».
- 79-16 : les rappels de `surOnglet` inscrits au démarrage d'un onglet sont défaits avec lui (écart 79-16-a).
- 79-18 : calcul de 90 cartes de 2 à 35 s dans le worker sous forte charge, environ 2 s en ligne.
- 79-20 : `FENETRE_S` du plan est une réexportation, l'extracteur lit `fenetreS`.
- 79-22 : le répartiteur HISTORIQUE rendait `{}` pour une promesse, corrigé dans `vf-cockpit-routes.mjs` (écart de
  périmètre) ; id inconnu rend `{ schema, id, erreur: 'inconnu' }`.
- Hausse réelle du cliquet d'observateurs : `02-vf-coin.js` 0 à 3, `02-vf-ligne-etat.js` 0 à 1, `02-vf-reperes.js` 0 à 2 (à Samuel).
## Rouges de CI et causes
- Régressions de 79-16 dans les suites voisines (V11, T21.7, R3.4, Q11.7, AM4.17, robustesse, git-entete, accessibilité) :
  elles lisaient l'ancienne page ; corrigées une à une, cueillies par la Phase 75.
- rtk : une suite de 79-17 appelait `rtk`, absent du runner (3cc622df). F7.4a : fixture jugée par une durée de 100 ms
  (85 ms en CI), prouvée par taille. N5.1 reconnexion (Linux) : attendre `#vf-lock` dans les deux onglets.
- Coquille (M-ECOUTEURS, M-HEAD, C8) : verte en dépôt, rouge en worktree, selon la profondeur du chemin (73f7ad5f).
## Mineurs versés au BACKLOG (21a94b9b)
AU13-03 à 07, AU16-03 à 05, AU18-04 et 05, AU22-01 à 04, RV1-1, RV1-3, RV1-4, VB-1 à 4, x13 F-02, x17 F3, 79-18 F4, limite
de la clé planning, D-M6, constats de la passe design.
## À savoir pour une autre phase
- `VF_ETAT` : lire dans `surOnglet` et par `SC.on('panel')`, jamais au chargement du script.
- Clé planning émise aussi sur `patch {seq,at}` ; limite : un SUMMARY réécrit ou une ligne de tableau ajoutée n'émet aucun
  patch (le diff de `vf-cockpit-live.mjs` compare statut, pied et résumé).
- CSP `worker-src` à l'URL exacte de `elk-fil.js`, jamais `blob:` ; `MOTIFS_MOTEUR` couvre `elk-fil.js` et le paquet ELK.
- Cliquet d'observateurs : formes `window.MutationObserver`, alias et sous-dossiers de `ui/` non comptées, reporté à la passe finale.
## D-M6 : en-têtes de provenance (mesure sur 898511f0, sans changement de code)
Pages et `/_vf/` refusent seulement `Sec-Fetch-Site: cross-site` (403), `Origin` et `Referer` ne sont pas lus ; `/api` exige le
jeton et lit `Origin`, pas `Sec-Fetch-Site`. Cas same-site réel : un autre cockpit sur 127.0.0.1 à un autre port (ne lit rien :
pas de CORS, `nosniff`, `frame-ancestors 'none'`). Recommandation : (1) hors `/api`, refuser tout `Sec-Fetch-Site` présent
autre que same-origin ou none, garder l'absence et l'exception du lanceur ; (2) lire `Sec-Fetch-Site` sur `/api` quand présent,
`Referrer-Policy: no-referrer` sur les pages ; (3) trancher d'abord si un lien venu de vf-signal local doit rester possible.
## Verdicts
Design (vf-design-judge, captures, une passe, aucune correction) : gaps_found, 59/100 pour un seuil de 70 ; majeurs : écran
d'échec de démarrage, thème sombre non validé, en-tête pendant le calcul de la carte, panneau latéral sur la colonne « Fait »
(détail au BACKLOG). Vérification de but : passed, 27/27 SOCL (SOCL-24 par décision).
## Preuves E6
```json
{"preuves":[
{"verdict":"gate:version-sync","commande":"bash scripts/check-version-sync.sh","exit_code":0,"sha":"4ccbf759820813a05db9ce5c8662d82391dc3d94"},
{"verdict":"gate:machine-paths","commande":"bash scripts/check-machine-paths.sh","exit_code":0,"sha":"4ccbf759820813a05db9ce5c8662d82391dc3d94"},
{"verdict":"gate:colonnes-cliquet","commande":"node plugin/cockpit/scripts/tests/colonnes-cliquet.mjs verifier plugin/cockpit plugin/cockpit/scripts/tests/colonnes-baseline.txt","exit_code":0,"sha":"4ccbf759820813a05db9ce5c8662d82391dc3d94"}
]}
```
