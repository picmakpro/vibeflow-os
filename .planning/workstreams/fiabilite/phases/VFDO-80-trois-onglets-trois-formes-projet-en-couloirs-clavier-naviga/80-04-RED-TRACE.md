# 80-04 — RED-TRACE (P80-D-25)

Trace du rouge sur la base `integration/cockpit-audit` (tête de la vague 1, `chrome-session.mjs` inchangé, aucun fichier `41-vf-projet-*`).
Les chemins du poste sont remplacés par `<tmp>`.

## Tâche 1 : CL1 (3 PASS / 4 FAIL)

Suite : `test-cockpit-couloirs.sh`, lab de 6 phases (2 faites, 1 en cours, 1 à recetter, 2 à faire), un jalon clos, backlog de 2 entrées, une graine.
Raison du rouge : la page se charge (CL0 vert, canevas rendu), la vue n'existe pas. Le fixture n'est pas mort : CL1.2 (témoin) rend `visible`, des cartes de canevas.

| Cas | Attendu | Obtenu | Raison |
|---|---|---|---|
| CL1.1 | `[4,"hidden",true]` | `[0,"visible",false]` | aucun couloir, canevas visible |
| CL1.2 | `["visible",true,true]` | PASS (témoin) | `?vue=graphe` : canevas, pas de section |
| CL1.3 | `[true,"n:ph-1"]` | section absente (le clic échoue : aucune carte `.vp-carte[data-id="n:ph-1"]`) | aucune carte de couloir |
| CL1.4 | `[["?vue=graphe","#s=x"],["?vue=couloirs","#s=x"]]` | `[["","#s=x"],["?vue=couloirs","#s=x"]]` | `naviguer` n'ajoute pas `vue=graphe` |
| CL1.9 | `[]` | `[cl13]` | la section cl13 a échoué (cause : CL1.3) |

## Tâches 2 et 3 : CL2 et CL3 sur la base (6 PASS / 51 FAIL)

Rejeu de la suite entière, pilotes de la tête, module servi = `git archive` du commit des témoins de la tâche 1 (`plugin/cockpit`, aucun fichier `41-vf-projet-*`,
`naviguer` sans `vue=graphe`). Raison du rouge : la vue n'existe pas. Le fixture est vivant : CL0 vert, CL1.2 vert (canevas, témoin), les mesures de pilote qui ne
dépendent pas de la vue rendent des valeurs réelles (CL3.1 : `[[null,0],["a",null],",,,,,,,,"]` : la tabulation atterrit sur un lien d'en-tête, aucune carte à `tabindex=0`).

| Cas | Obtenu sur la base | Raison |
|---|---|---|
| CL1.1 | `[0,"visible",false]` | aucun couloir, canevas visible |
| CL1.3 | section absente | aucune carte de couloir à cliquer |
| CL2.1 à CL2.6, CL2.8 | `mesure absente : Cannot read properties of null (reading 'synth' / '0' / 'liste' …)` | aucun `.vp-jalon`, aucune carte |
| CL2.7a | PASS dans ce rejeu (artefact : la suite lisait les `41-*` de l'arbre, pas de la base) ; corrigé à `$SC_BASE` : sur la base `ls` rend 0 fichier et `css-jetons` rend 1 (`0\|rc=1`) | témoin de présence des fichiers |
| CL2.7b | `mesure absente` (aucun `.vp-carte`) | pas de carte à mesurer |
| CL3.1 | `[[null,0],["a",null],",,,,,,,,"]` | aucun arrêt de carte, la suite de flèches ne trouve aucune carte |
| CL3.2 | `[",,,,,,",false]` | aucune carte focalisable, `body` à chaque appui |
| CL3.3a, CL3.3b, CL3.4 | sélection nulle, conteneur inchangé | aucune carte |
| CL3.5, CL3.7, CL3.8, CL3.9, CL3.10 | `mesure absente` (carte ou `VF_PROJET` absents) | aucune vue |
| CL3.11a, CL3.11b | `[null,null,null,null]` | aucune carte à focaliser puis retirer |
| CL3.11c | PASS (témoin) | le champ de question n'est touché par rien : vert sur la base, garde contre un vol de focus futur |
| CL3.12 (1440, 1024, 800, 390, 1100t) | `mesure absente : Cannot read properties of null (reading 'fin')` | aucune vue, aucun scroll-padding |
| CL3.6 (cinq largeurs) | `mesure absente : Cannot read properties of null (reading 'haut')` | aucune vue |
| mutants (cinq) | `mutation impossible : motif absent` | le fichier muté n'existe pas : un mutant sans effet n'est jamais compté vert |

CL1.4 est vert dans ce rejeu (les pilotes de la tête portent le `naviguer` de la tâche 1) ; il était rouge sur la base de la tâche 1 (`[["","#s=x"],…]`, voir plus haut).

## Correction de revue (2026-11-12) : rouges avant le code (49 PASS / 8 FAIL sur la tête 2a1f37b9)

| Cas | Obtenu | Raison |
|---|---|---|
| CL1.5 | `[5]` | cinq descendants du canevas caché restent `visible` à 390 px |
| CL1.6 | `[[null,false,"Affichage en graphe",true,null,false,"Affichage en couloirs, 6 phases"]]` | focus sur `body` dans les deux sens ; l'annonce est dans la section masquée |
| CL2.7b (clair) | segment actif sans cerne | témoin du segment (la teinte du segment sombre masquait la mesure : réécrit sur la couleur de bordure) |
| CL3.12 (800, 1100t) | carte `[401,769]` sous le panneau `[424,784]` | extrémité absente sous 1 000 px |
| CL3.13 | flottant `[322,478]` sur le panneau `[424,784]` | bascule centrée sur la fenêtre entière |
| CL3.12 (1440, 1024) | `mesure absente` | état du panneau hérité d'une section voisine : pilote rendu déterministe (clé `floorplan:panel` effacée à chaque page) |
