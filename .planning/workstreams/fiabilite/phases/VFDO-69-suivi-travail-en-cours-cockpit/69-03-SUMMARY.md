# 69-03 — SUMMARY

**Plan** : 69-03 (contrat `vibeflow/cockpit-who@2`, équipe en arbre, fenêtre de 24 h, forme Claude Code mesurée ; CKPT-19, 20, 27, 28 ; P69-D-14, D-18, D-22, D-23)
**Commits** : `ea2b43b3` (T1 : contrat, lecteurs, parenté), `34f74373` (T2 : arbre, fenêtre, forme stricte, registre), `eaec768e` (T3 : `whoSig`). Mesure : `69-03-MESURE-FORME.md` (Claude Code 2.1.317).

## Livré
- `vf-cockpit-lecture.mjs` (67 l.) : lecteurs partagés déplacés de `vf-cockpit-who.mjs` sans changement de comportement + `premiereLigne` (256 Kio, cache borné à 4 000).
- `vf-cockpit-equipe.mjs` (95 l.) : `FENETRE`, `collecteAgents`, `formeSousAgent`. Fenêtre tenue par la ligne marquée `// FENETRE-24H` ; tables par identifiant en `Map` ; ancêtres retrouvés par identifiant (`ID_RE`), profondeur bornée à 8, cycle refusé.
- `vf-cockpit-who.mjs` (159 l.) : schéma `@2`, champ `fenetre`, `busy` ignore les terminés, registre fusionné (carte privée `_registre` rendue par `gather`, jamais par `collectWho`).
- `vf-cockpit-interface.json` : `who@2` remplace `@1` ; ajout de `transcript@1`, `equipe@1` ; `verifieSur` 2.1.317 ; `requis`, `requisSiProfondeur`, `booleensFacultatifs`, `formeArretee`, `transcriptSousAgent` ; retrait de `attendus` et `drapeauFin` de `metaSousAgent`. La clé `avancement` est intacte.
- `vf-cockpit-live.mjs` : `whoSig` gagne `parent`, `etat`, `action` (verbe cible), `rattachement` ; `ageS` et `dureeS` restent hors signature.

## Mesure de forme (aucun écart, aucune question pour Samuel)
66 candidats de la fenêtre (14 à `spawnDepth` 1, 52 à >= 2) ; les cinq clés de `requis` sont à 100 % aux deux profondeurs, `parentAgentId` 52/52 (et désigne toujours un agent du même dossier), `isSidechain` et `agentId` 66/66. Aucune base vide, aucun champ de C3 sous 100 %. Forme arrêtée : 0 dans la fenêtre. Détail dans `69-03-MESURE-FORME.md`.

## Assertions réécrites par conception
- W1.1, W4.1, W4.3, W10.1 : `cockpit-who@1` devient `@2` (CKPT-28, le contrat remplace `@1`).
- W8.6 : « la fixture conforme rend lue » devient « un meta.json hors forme rend la source forme-inconnue » (CKPT-27 : un sous-agent hors forme suffit désormais) ; W8.7 ajouté (témoin : dossier tout conforme rend lue).
- Fixtures de sous-agent passées à la forme réelle sans toucher une assertion : W8 (`ok`/`bad`) et W13.4 de `test-cockpit-who.sh` (helper `mk_sub`, fait dans le commit T1 car le contrat exige alors les clés mesurées), B1 de `test-cockpit-robustesse.sh`, MB de `test-cockpit-securite.sh`.

## Preuve de mutation de la fenêtre (copie de `scripts/` sans la ligne `// FENETRE-24H`)
```
OK-MUTATION-FENETRE
--- original:  Résultats : 56 PASS / 0 FAIL
--- mutée:
  ❌ FAIL — F14.1 / F14.2 / F15.3 / F16.1 (zéro ouverture d'un fichier agent-old*) / F16.2
  Résultats : 51 PASS / 5 FAIL
```

## Coût de collecte
- Fixture EP (40 sous-agents) : 26 à 34 ms (`collectWho`, 3 passes). Poste réel (1 006 `meta.json`, 66 dans la fenêtre) : `vf-cockpit-who.mjs . --json` en 377 ms, code 0, source `lue` (repère `v2.75.0` : ~245 ms). F16.1 : PASS (zéro ouverture sur 1 000 `meta.json` hors fenêtre) ; F16.4 PASS.

## Témoins (rouge avant : `69-02-RED-TRACE.md`)
- `test-cockpit-forme-claude.sh` : 56/56 (25 verts avant). E0, E19, E20, E28, EP de `test-cockpit-equipe.sh` : tous verts. Restent rouges, hors de ce plan : E21, E22.1-5, E22.8 (69-06), E23 et EUI (69-04). Gardes de 69-02 toujours vertes : E19.2, E19.3, E20.3, E22.7, E22.9, EP.1, F5.a, F6.a, F7.a, F15.3, F15.4, F16.2, F16.4.
- Suites rejouées vertes : who 69/69, robustesse 25/25, securite 88/88, serveur 64/64, direct 75/75, reseau 14/14, vendor 75/75 ; les onze autres suites du cockpit (hors celles de 69-04) toutes vertes (assemblage, avancement, chaine-xss, chrome-fr, hygiene, marque-blanche, onglet-code, projet, questions, reconnexion, responsive 186/186).

## Points pour les plans suivants
- 69-06 lit `_registre` (identifiant -> `{ noeud, role, ws }`) depuis `gather` ; `gather` n'est pas exporté.
- Un candidat de la fenêtre ni fini ni frais (silencieux depuis plus de `fresh`) n'est présent que s'il est l'ancêtre d'un agent inclus (état `en-attente`).
- L'état `forme-inconnue` d'une session sans sous-agent hors forme reste conditionné comme avant (W8.1-W8.3) ; seul un sous-agent candidat hors forme rend la source `forme-inconnue` à lui seul.

## estimate / actuals
estimate : 110 000 tokens, 3 tâches (confidence low). actuals : non mesuré par le moteur (exécution directe, hors `gsd-execute-phase`) ; 3 tâches, 3 commits.
