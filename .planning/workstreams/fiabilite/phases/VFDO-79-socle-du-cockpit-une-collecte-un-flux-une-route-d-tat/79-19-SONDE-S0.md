# Sonde S0 : l'état officiel des sessions montre-t-il une session bloquée sur une permission ?

Sonde jouée le 2026-11-11, validée par la relecture du tableau par la session principale (décision déléguée par Samuel, message session principale, 2026-11-11 : « tranche pour chacun de ces points » ; registre de l'audit, J1-D01)

Mesure de la tâche 1 du plan 79-19 (SOCL-24, P79-D-22, S-4). Samuel n'a pas relu le tableau lui-même.

- Canal de jeu : un banc qui pilote un pseudo-terminal, hors du dépôt, et non une personne devant deux terminaux (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 : « Claude la joue »). La sortie brute du banc reste hors dépôt.
- Claude Code : 2.1.322. Le contrat du cockpit (`claudeCode.verifieSur`) dit 2.1.317 : écart noté, la sonde vaut pour la version relevée.
- Système : macOS 26.4, arm64.
- Relecture : les 18 lignes du tableau recoupées une à une avec le journal brut des deux passes (valeur de `status`, absence de `state`, boîte à l'écran avant et après chaque lecture « boîte ouverte », entrée lue = session lancée). Le critère mécanique de l'étape 9 du plan est satisfait par `status` seul.

## Ce qui a été joué

- Session essayée en mode de permission `default`, sans réglage chargé, dans un dossier jetable hors du dépôt, pseudo-terminal de 120 colonnes sur 50 lignes, une session neuve par passe, deux passes le même jour.
- Environnement réduit à huit variables, aucune variable `CLAUDE*` ni `ANTHROPIC*`.
- Trois demandes par passe (cas A écriture de fichier, B commande shell, D activité). Aux deux boîtes, réponse « non » par l'option de refus lue à l'écran. Aucune permission accordée.
- Une lecture « boîte ouverte » n'est retenue que si la boîte est à l'écran au début ET à la fin de la lecture ; une lecture d'après réponse, que si elle n'y est plus.

## Lectures

Le délai va du lancement de la commande de lecture à son retour.

| lecture | cas | délai mesuré | `state` | `status` |
|---|---|---|---|---|
| S0.A1 | passe 1, écriture de fichier, boîte ouverte | de +0,01 s à +0,19 s après l'affichage de la boîte | champ absent | `waiting` |
| S0.A1 | passe 2, écriture de fichier, boîte ouverte | de +0,03 s à +0,17 s après l'affichage de la boîte | champ absent | `waiting` |
| S0.A2 | passe 1, écriture de fichier, boîte ouverte | de +10,31 s à +10,42 s après l'affichage de la boîte | champ absent | `waiting` |
| S0.A2 | passe 2, écriture de fichier, boîte ouverte | de +10,31 s à +10,42 s après l'affichage de la boîte | champ absent | `waiting` |
| S0.A3 | passe 1, écriture de fichier, après la réponse « non » | de +3,00 s à +3,13 s après la réponse | champ absent | `idle` |
| S0.A3 | passe 2, écriture de fichier, après la réponse « non » | de +3,00 s à +3,18 s après la réponse | champ absent | `idle` |
| S0.B1 | passe 1, commande shell, boîte ouverte | de +0,03 s à +0,16 s après l'affichage de la boîte | champ absent | `waiting` |
| S0.B1 | passe 2, commande shell, boîte ouverte | de +0,01 s à +0,13 s après l'affichage de la boîte | champ absent | `waiting` |
| S0.B2 | passe 1, commande shell, boîte ouverte | de +10,30 s à +10,43 s après l'affichage de la boîte | champ absent | `waiting` |
| S0.B2 | passe 2, commande shell, boîte ouverte | de +10,31 s à +10,44 s après l'affichage de la boîte | champ absent | `waiting` |
| S0.B3 | passe 1, commande shell, après la réponse « non » | de +3,01 s à +3,15 s après la réponse | champ absent | `idle` |
| S0.B3 | passe 2, commande shell, après la réponse « non » | de +3,01 s à +3,14 s après la réponse | champ absent | `idle` |
| S0.C1 | passe 1, repos : tour fini, invite libre, aucune boîte | de +5,00 s à +5,15 s après la fin du tour | champ absent | `idle` |
| S0.C1 | passe 2, repos : tour fini, invite libre, aucune boîte | de +5,00 s à +5,12 s après la fin du tour | champ absent | `idle` |
| S0.C2 | passe 1, repos : tour fini, invite libre, aucune boîte | de +70,01 s à +70,15 s après la fin du tour | champ absent | `idle` |
| S0.C2 | passe 2, repos : tour fini, invite libre, aucune boîte | de +70,01 s à +70,14 s après la fin du tour | champ absent | `idle` |
| S0.D1 | passe 1, activité : la session produit sa réponse | de +1,01 s à +1,15 s après le début du travail vu à l'écran | champ absent | `busy` |
| S0.D1 | passe 2, activité : la session produit sa réponse | de +1,00 s à +1,12 s après le début du travail vu à l'écran | champ absent | `busy` |

Les deux passes ne divergent sur aucune valeur ni sur aucun nom de champ. Lectures d'observation hors tableau, identiques dans les deux passes, `state` absent à chacune : boîte ouverte à 2,0 s, 3,3 s, 5,0 s, 6,5 s et 8,0 s, pour A comme pour B : `waiting` ; au repos de 20 s à 66 s après la fin du tour : `idle` ; en activité dès 0,15 s : `busy`.

## Noms de champs vus

Sur l'entrée de la session essayée, à toutes les lectures : `cwd`, `kind`, `name`, `pid`, `sessionId`, `startedAt`, `status`. S'y ajoute `waitingFor` quand `status` vaut `waiting`, et seulement alors (sa valeur n'a pas été relevée). Le champ `state` n'y figure à aucune lecture.

## Écarts à la procédure du plan

1. Un banc et non une personne (voir ci-dessus).
2. Cas D : sur cette version le texte ne s'écrit pas ligne à ligne ; l'indicateur de travail dure environ quatre secondes puis la réponse arrive d'un bloc. D1 est lue pendant ce travail, indicateur à l'écran avant et après.
3. A1 et B1 sont lues dans les deux dixièmes de seconde qui suivent l'affichage ; les lectures d'observation couvrent le reste.
4. Cas C : le refus de la boîte B clôt le tour ; C1 tombe deux secondes après B3.
5. Des lectures d'observation ont été ajoutées entre celles du plan.

## Limites

- Une version, un poste, un compte, deux passes le même jour ; deux sortes de boîte (écriture de fichier, commande shell), mode `default`, aucun réglage chargé.
- La mesure montre que `waiting` distingue la boîte de permission du repos et de l'activité ; elle ne dit pas s'il distingue une permission d'une autre attente de l'utilisateur.
- Repos suivi jusqu'à 70 s : `idle`. Au-delà, rien n'est mesuré.
- Les lectures portent sur une session interactive (`kind` égal à `interactive`). Une lecture directe hors banc montre qu'une entrée dont `kind` vaut `background` porte `state` (valeur vue : `blocked`) et pas `status` : cette sorte de session n'a pas été mesurée par le banc (limite J1-D01). Le contrat du cockpit (`claudeCode.vueAgents`) lit déjà les deux champs.

Verdict S0 : OUI

Détail : sur Claude Code 2.1.322, l'entrée de la session interactive porte `status` égal à `waiting` dès la première lecture après l'affichage de la boîte et encore à dix secondes, pour l'écriture de fichier comme pour la commande shell, puis `idle` après le refus et au repos, et `busy` pendant le travail, sans champ `state` : le verdict tient à `status` seul.

## Suite

Plan arrêté sans code ; tâches 2 à 4 non jouées ; retrait d'I18 tranché par J1-D02 (registre de l'audit, décision déléguée par Samuel, message session principale, 2026-11-11) ; à rouvrir si une version de Claude Code cesse de publier `waiting` / `blocked`
