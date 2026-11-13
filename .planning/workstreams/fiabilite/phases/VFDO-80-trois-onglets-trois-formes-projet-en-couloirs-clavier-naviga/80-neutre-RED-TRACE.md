# 80-neutre — trace des rouges (garde : témoins ET mutants)

Nœud neutre : « attribut neutre posé par le terminal » (registre J1-49). Régime allégé, mais le nœud est une GARDE.
Contrat à poser : `data-vf-flottant`, valeurs `bouton` (pastille), `etat` (puce), `tiroir` (région). Les lecteurs lisent cet attribut, jamais une forme.

## Écart de fichiers
Le mandat situe pastille et puce dans `assets/ui/terminal/vue.js`. C'est le bandeau Q (`vf-q-pastille` : une pastille de couleur de 8 px, sans rapport).
La pastille « Terminal », la puce et la région sont construites par `assets/ui/tiroir/tiroir-construire.js` (styles : `tiroir/tiroir.css`).
Recherche du motif `pastille` sous `assets/ui/terminal/` : aucun élément flottant.

## Témoins rouges, vus sur la tête d'avant (aucun fichier de `assets/ui/` modifié)
Suite neuve `test-cockpit-neutre.sh` (pilote `chrome-neutre.mjs`), puis `test-cockpit-couloirs.sh`.

| Témoin | Attendu | Obtenu avant correctif |
|---|---|---|
| (a) 41 : CL4.3 inversé, bouton fixe étranger sous body | zone basse inchangée | `calc(104px …)` -> `calc(224px …)` : pris pour la pastille |
| (a) 00 : NE1.1, Échap dans une région fixe étrangère, palette ouverte | `[true,false]` | `[false,true]` : prise pour le tiroir du terminal |
| (a) 02 : NE1.3, bouton fixe étranger couvrant la fenêtre | repères restés posés | `1 -> 0` : pris pour un obstacle |
| (b) NE2.1 : tiroir Git ouvert, PUIS petit bouton fixe en bas à gauche | `[false,false]` | `[true,false]` : chevauchement, le redimensionnement seul le lève |

Témoins verts avant et après (garde contre une lecture supprimée) : CL4.3d (bouton marqué mesuré), NE1.2 (région marquée gardée à son Échap),
NE1.4 (bouton marqué = obstacle). Leur rouge se voit sous mutant (`M-PASTILLE-RIEN` pour 41).

Réglage du témoin (b) : un premier jet posait le bouton à `bottom: 16px`, sous la barre de question : le tiroir, déjà relevé de 66 px, ne le chevauche
pas, et un second jet l'a posé avant la fin de la lecture `/api/vf/git` (dont le retour rejoue `eviter` et masque le défaut). Le pilote attend maintenant
la lecture rendue, puis pose l'élément à `bottom: 80px` : seul l'arrivée de l'élément est mesurée.

Les mutants (lecture revenue à la forme, lecture supprimée, rejeu d'`eviter` retiré) sont écrits après le correctif, sur une copie du module.
