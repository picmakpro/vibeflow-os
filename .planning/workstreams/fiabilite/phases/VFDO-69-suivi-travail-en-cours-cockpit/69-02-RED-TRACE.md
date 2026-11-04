# 69-02 — Trace du rouge de la collecte de l'équipe, avant tout code

**Date** : 2026-11-03 · **Code testé** : `v2.75.0` (HEAD de base `7370d604`, aucun fichier de code modifié par ce plan)
**Commit A (les deux suites seules)** : `5f121cba`
**Claude Code** : 2.1.317 (`claude --version`), version sur laquelle la forme réelle du plan a été mesurée (R5.1).

## Commandes rejouées

```
bash plugin/cockpit/scripts/tests/test-cockpit-equipe.sh        # rc=1 · Résultats : 23 PASS / 27 FAIL
bash plugin/cockpit/scripts/tests/test-cockpit-forme-claude.sh  # rc=1 · Résultats : 25 PASS / 31 FAIL
```

Deux rejeux consécutifs de la suite de l'équipe donnent les mêmes comptes (23/27) ; la suite de forme, rejouée depuis `/`, 25/31 : le rouge est stable. Les deux suites chargent le code testé depuis le dossier du script (preuve : une copie de `scripts/` dont `cockpit-who@1` est remplacé par `@9` rend `obtenu: [vibeflow/cockpit-who@9]` ; l'original rejoué depuis `/` rend `@1`).

Chaque ligne ci-dessous : libellé · attendu · obtenu · raison du rouge (la règle absente, jamais la fixture).

## Rouges de `test-cockpit-equipe.sh`

### E19 — arbre (CKPT-19, P69-D-14)
- **E19.1** w1 a pour parent son manager · attendu `mgr1` · obtenu `aaaa1111-…` (identifiant de session) · l'arbre est aplati : `parent` = session pour tout sous-agent.
- **E19.4** mgr2 silencieux présent en en-attente · attendu `en-attente` · obtenu `absent` · un manager non terminé et silencieux depuis 600 s est écarté à la ligne 88 de `who.mjs`, bien qu'il ait un worker actif.
- **E19.5** w2 a pour parent mgr2 · attendu `mgr2` · obtenu `aaaa1111-…` · même aplatissement.
- **E19.6** un seul travailleur `w1` · attendu `1` · obtenu `2` · le sous-agent et l'entrée de registre (`kind: registered`) coexistent, aucune fusion.

### E20 — historique (CKPT-20, P69-D-18)
- **E20.1** fin2h présent et termine · attendu `termine` · obtenu `absent` · tout agent `finished` est écarté.
- **E20.2** fin2h porte `finAt` · attendu `string` · obtenu `absent` · agent absent.
- **E20.4** `fenetre` = 86400 · attendu `86400` · obtenu `undefined` · la sortie ne porte pas la clé.
- **E20.5** busy faux et session racine termine · attendu `false|termine` · obtenu `false|undefined` · la session silencieuse n'est pas listée comme racine d'un terminé.

### E21 — rattachement (CKPT-21, P69-D-15)
- **E21.1** registre -> `rattache|registre|.planning/missions/m1.dag.json|revue-p3` · obtenu `aucun` · le champ `rattachement` n'existe pas.
- **E21.2** mandat « Nœud `revue-p3` » -> `rattache|mandat|…|revue-p3` · obtenu `aucun` · idem.
- **E21.3** nœud inconnu -> `non-rattache|inconnu` · obtenu `aucun` · idem.
- **E21.4** `docs` dans deux DAG -> `non-rattache|ambigu` · obtenu `aucun` · idem.
- **E21.5** nœud cité sans accents graves -> `non-rattache|sans-citation` · obtenu `aucun` · idem.
- **E21.6** registre ambigu décisif malgré une citation claire -> `non-rattache|ambigu` · obtenu `aucun` · idem.
- **E21.7** DAG de compartiment `alpha/MISSION-9` -> `rattache|mandat|.planning/workstreams/alpha/MISSION-9.dag.json|seul-ws` · obtenu `aucun` · idem.

### E22 — dernière action (CKPT-22, P69-D-16)
- **E22.1** Bash -> `lance une commande|` · obtenu `aucune` · le champ `action` n'existe pas.
- **E22.2** Read dans le lab -> `lit|src/a.js` · obtenu `aucune` · idem.
- **E22.3** Read hors lab -> `lit|un fichier hors du lab` · obtenu `aucune` · idem.
- **E22.4** WebFetch -> `consulte une page|exemple.test` · obtenu `aucune` · idem.
- **E22.5** Agent -> `lance un agent|vf-coder` · obtenu `aucune` · idem.
- **E22.8** le `hello` du flux contient « lance une commande » · attendu `present` · obtenu `absent` · aucune action dans `who` (le contrôle positif E22.8a, vert, prouve que `a-bash` est bien dans le `hello`).

### E28 — schéma (CKPT-28, P69-D-23)
- **E28.1** schéma de la sortie · attendu `vibeflow/cockpit-who@2` · obtenu `vibeflow/cockpit-who@1` · schéma `@1` (ce rouge trace `cockpit-who@1`).
- **E28.2** sortie conforme au contrat `@2` · attendu `OK` · obtenu `KO schéma absent du contrat : vibeflow/cockpit-who@2` · le contrat ne déclare que `@1`.
- **E28.3** copie avec `etat2` refusée · attendu sous-chaîne `clé non déclarée` · obtenu `KO schéma absent du contrat` · même cause (le validateur lui-même est prouvé par E28.0b, vert, sur un contrat jetable).
- **E28.4** copie avec `mandat` refusée · attendu `clé interdite présente : mandat` · obtenu `KO schéma absent du contrat` · même cause (validateur prouvé par E28.0c, vert).
- **E28.5** le contrat ne déclare plus `@1` · attendu `0` · obtenu `1` · `@1` toujours déclaré.

### EP — coût (T-69-06)
- **EP.2** 40 sous-agents listés · attendu `40` · obtenu `20` · les 20 terminés sont écartés.

## Rouges de `test-cockpit-forme-claude.sh`

### F0 — historique
- **F0.1** m, w, t listés · attendu `m,t,w` · obtenu `m,w` · le terminé `t` est écarté.

### F1 à F10, F12 — un champ lu disparaît (CKPT-27, P69-D-22)
Aujourd'hui `who.mjs` n'exige que `agentType` et `description` et ne compte `formeInconnue` en `forme-inconnue` que si aucun travailleur vivant n'existe : la source reste `lue` partout où la session est fraîche.
- **F1.a** `parentAgentId` retiré de w, w absent · attendu `absent` · obtenu `présent` · champ non exigé. **F1.b** source `forme-inconnue` · obtenu `lue`.
- **F2.a** `spawnDepth` retiré · obtenu `présent` · non exigé. **F2.b** · obtenu `lue`.
- **F3.a** `toolUseId` retiré · obtenu `présent` · non exigé. **F3.b** · obtenu `lue`.
- **F4.a** `requestShape` retiré · obtenu `présent` · non exigé. **F4.b** · obtenu `lue`.
- **F5.a** `agentType` retiré : `absent` (vert, garde : champ déjà exigé). **F5.b** · obtenu `lue` (l'agent est compté mais l'état reste `lue`).
- **F6.a** `description` retiré : `absent` (vert, garde). **F6.b** · obtenu `lue`.
- **F7.a** `finished: "oui"` sur t : `absent` (vert, garde : toute valeur vraie écarte l'agent). **F7.b** · obtenu `lue` (la valeur non booléenne n'est jamais comptée).
- **F8.a** `isSidechain` retiré de la première ligne · attendu `absent` · obtenu `présent` · transcript non contrôlé. **F8.b** · obtenu `lue`.
- **F9.a** `agentId` retiré de la première ligne · obtenu `présent`. **F9.b** · obtenu `lue`.
- **F10.a** `agentId` différent de l'identifiant du fichier · obtenu `présent`. **F10.b** · obtenu `lue`.
- **F12.a** w3 (`parentAgentId` vers un agent absent) absent · attendu `absent` · obtenu `présent` · aucun contrôle de parent. **F12.b** · obtenu `lue`.

### F11 — le contrat
- **F11.1** `metaSousAgent.requis` contient les cinq champs · attendu `true` · obtenu `false` · le contrat ne porte que `agentType`, `description`.
- **F11.2** `requisSiProfondeur.parentAgentId` · attendu `2` · obtenu `undefined` · clé absente.
- **F11.3** `booleensFacultatifs` contient `finished` · attendu `true` · obtenu `false` · clé absente (le contrat a `drapeauFin`).
- **F11.4** `transcriptSousAgent.requis` · attendu `isSidechain,agentId` · obtenu vide · bloc absent.
- **F11.6** `formeArretee.requis` · attendu `agentType,stoppedByUser` · obtenu vide · bloc absent.

### F14 à F16 — fenêtre, forme arrêtée, coût
- **F14.3** le parent de w est m · attendu `m` · obtenu `aaaa1111-…` · arbre aplati.
- **F14.4** H14b (description retirée de w) · attendu `absent|forme-inconnue` · obtenu `absent|lue` · la source ne devient jamais `forme-inconnue` tant que m est listé.
- **F15.1** s1 `{agentType, stoppedByUser}` depuis 1 h · attendu `termine|finAt` · obtenu `absent` · sauté à la ligne 88 (âgé de 1 h, plus que `fresh`), avant tout contrôle.
- **F15.2** le parent de s1 est la session · attendu `aaaa1111-…` · obtenu `absent` · s1 absent.
- **F16.1** zéro ouverture d'un fichier `agent-old*` · attendu `0` · obtenu `1000` · le `meta.json` est lu avant l'âge du transcript.
- **F16.3** l'ancêtre `anc`, hors fenêtre, listé en-attente · attendu `en-attente` · obtenu `absent` · aucun ancêtre hors fenêtre n'est ajouté.

## Contrôles positifs verts (même fixture que le témoin rouge apparié)

Équipe : E0.1 à E0.5 (fixture lisible, `isSidechain`/`agentId` présents, `parentAgentId` seulement à profondeur 2), E19.0 (registre lu, w2 listé), E19.2 et E19.3 (parent de mgr1 = session ; profondeurs 1 et 2 : gardes déjà vraies), E20.0 (`finished: true` dans les deux `meta.json`), E20.3 (fin25h absent : garde, le positif est E20.1), E21.0 (revue-p3 dans un DAG, docs dans deux), E22.0 (cinq actifs listés), E22.6 (terminé sans action : garde), E22.7 et E22.9 (aucun secret, ni curl, ni chemin hors lab, dans `who` et le flux : gardes, le positif est E22.1/E22.8), E22.0b (serveur démarré, jeton lu, leurre vivant), E22.8a (a-bash dans le `hello`), E22.10 (leurre vivant après l'arrêt du serveur par `vf_hyg_stop`), E28.0a à E28.0c (le validateur accepte le conforme, refuse `etat2` et `mandat` sur un contrat jetable), EP.1 (collecte < 3 000 ms), H0 (aucun processus de la suite ne survit).

Forme : F0.2 et F0.3 (source lue ; m et w listés), F13.F1 à F13.F10 (m sans `parentAgentId` à profondeur 1 reste listé), F11.0 et F11.5 (contrat lu ; `verifieSur` de forme N.N.N), F12.0 (m et w listés), F14.1 et F14.2 (m,w seuls ; source lue, formeInconnue 0 malgré 35 vieux dégradés), F15.3 (s2 absent), F15.4 (source lue, formeInconnue 0), F16.0 (la sonde compte bien les ouvertures des candidats), F16.2 (les trois candidats listés, source lue), F16.4 (collecte < 3 000 ms sur 1 004 meta.json).

## Écarts au plan notés à l'écriture

- E19.2, E19.3, E20.3, E22.7, E22.9, EP.1, F5.a, F6.a, F7.a sont **verts aujourd'hui** : ce sont des gardes de non-régression, chacune appariée à un témoin rouge de la même fixture (conforme à Pitfall 14), pas des témoins.
- E28.3 et E28.4 sont rouges parce que le contrat n'a pas `@2` ; le validateur est prouvé indépendamment par E28.0a à E28.0c (contrat jetable), pour qu'un rouge de contrat ne masque pas un validateur cassé.
- E22.10 utilise `ps -p` et non `kill -0` (critère d'acceptation : aucun mécanisme d'arrêt écrit dans la suite).
