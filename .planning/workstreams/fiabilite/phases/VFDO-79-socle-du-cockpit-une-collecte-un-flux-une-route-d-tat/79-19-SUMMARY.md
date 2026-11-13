# 79-19 — Sonde S0 : plan fermé sur le verdict OUI

**Verdict S0 : OUI.** Sonde jouée le 2026-11-11, par un banc sur pseudo-terminal (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 : « Claude la joue »), Claude Code 2.1.322. Tableau validé par la relecture de la session principale (décision déléguée par Samuel, message session principale, 2026-11-11 : « tranche pour chacun de ces points » ; registre de l'audit, J1-D01), pas par Samuel lui-même.

Raison (critère de l'étape 9) : `claude agents --json` publie `status` égal à `waiting` pour une session interactive bloquée sur une permission, dans les deux cas (écriture de fichier, commande shell), dès la première lecture et encore après dix secondes ; `idle` après le refus et au repos (jusqu'à 70 s), `busy` pendant le travail ; le champ `state` est absent de l'entrée. Le verdict tient à `status` seul.

## Livré

- `79-19-SONDE-S0.md` : tableau S0.A1 à S0.D1 (18 lignes, deux passes), noms de champs, limites, verdict, `## Suite`.
- `79-19-RED-TRACE.md` : `AVANT-19` et la ligne d'arrêt. Aucun rouge ni mutant : aucun code écrit.

Plan arrêté sans code : les tâches 2 à 4 ne sont pas jouées, aucun hook, aucune suite, aucun README, aucun script touché. Retrait d'AUDC-I18 tranché par J1-D02 (registre de l'audit, décision déléguée par Samuel, message session principale, 2026-11-11), P79-Q-04 close. SOCL-24 close par la sonde : journal non construit.

## Pour 79-20

- Aucune mention de hooks au README : rien n'a été posé par ce plan.
- Limite J1-D01 à porter : une session `kind: background` publie `state` (vu : `blocked`) et pas `status` ; non mesurée par le banc, le contrat `claudeCode.vueAgents` lit déjà les deux champs. À rouvrir si une version de Claude Code cesse de publier `waiting` / `blocked`.

## Écarts

- Contrôle « aucun autre fichier dans AVANT-19..HEAD » : rougit à cause des commits des nœuds voisins (79-13, 79-14) sur la même branche ; mesuré sur les seuls commits de ce nœud, il ne montre que les trois fichiers de 79-19.
- Écarts de procédure de la sonde (banc, cas D, délais A1/B1, cas C) : voir la note de sonde.

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Contrôles

OK-SONDE-S0 (adapté, sur les commits du nœud), OK-SONDE-FORME, check-machine-paths : sorties dans le rapport du nœud.
