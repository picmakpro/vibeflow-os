# 68-03 — Trace du rouge avant le code (VFSG-03, VFSG-11 ; P68-D-14, P68-D-15)

- Date : 2026-11-04
- Empreinte du commit de tests (A) : `7ce542e2` (`test(68-03): témoins rouges de l'émetteur signal@1 — chaîne réelle, contrat, sans recalcul, sans réseau`)
- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-signal.sh > sortie 2>&1` — rc=1, `Résultats : 10 PASS, 33 FAIL`
- Cause commune du rouge : `plugin/cockpit/scripts/vf-cockpit-signal.mjs` n'existe pas (le lancement `node …/vf-cockpit-signal.mjs` sort 1, stdout vide, lu `illisible`) et `schemas["vibeflow/cockpit-signal@1"]` n'est pas au contrat.
  Ce n'est pas un rouge de fixture morte : S0 (git réel, DAG, conductor factice) est vert avant le code.

## Témoins rouges

### S1.1 — chaîne réelle node + émetteur : schéma signal@1 (témoin VFSG-11)
- attendu : `vibeflow/cockpit-signal@1`
- obtenu : `illisible` (script absent)

### S2.1 — sortie conforme au contrat signal@1 (témoin VFSG-03)
- attendu : `OK`
- obtenu : `KO schéma absent du contrat : vibeflow/cockpit-signal@1`

### S3.2 — mission sans verrou : abandonnee
- attendu : `abandonnee`
- obtenu : `illisible`

### S4.1 — avancement sérialisé sans recalcul
- attendu : `OK`
- obtenu : `illisible`

### S5.1 — aucune sous-commande réseau de git
- attendu : `vu|0` (l'emballage a journalisé au moins 5 appels de l'émetteur)
- obtenu : `aveugle:0|0` — l'émetteur n'émet aucun appel : la suite refuse le vert à vide

### S6.2 — sans conductor voisin : verrous absente, mission inconnu
- attendu : `absente|inconnu|état inconnu`
- obtenu : `illisible`

### S7.3 — sans argument : exit 2
- attendu : `2`
- obtenu : `1` (échec de `node` sur le module absent, pas l'usage de l'émetteur : rouge pour la cause commune)

### S8.1 — copie mutée qui recalcule : détectée
- attendu : `S3.2-rouge|KO mission MISSION-1 : `
- obtenu : `|illisible` (aucune copie à muter : S8.0 rouge, `ancre absente`)

## Contrôles positifs (verts avant le code)

- S0.1 à S0.4 : retard de 3 commits (git réel), deux worktrees, DAG à nœud running de 500 caractères, conductor factice qui répond `present:false`.
- S4.0 : `readPlanning` rend les trois lignes d'avancement et `MISSION-1` abandonnee — la référence de S4 est vivante.
- S5.2 et S5.3 : un `git fetch` délibéré est journalisé, la sonde réseau enregistre `fetch` et `net` sur un témoin sortant : S5.1 et S5.4 peuvent rougir.
- S6.0 : un script planté laisse son fichier témoin quand on le lance : S6.3 peut rougir.
- S6.3 vert avant le code **par construction** (le plan l'annonce : aucun script n'est lancé quand l'émetteur n'existe pas) ; il est doublé de **S6.3b** (verrous `absente`), rouge avant le code, qui interdit le vert à vide.
