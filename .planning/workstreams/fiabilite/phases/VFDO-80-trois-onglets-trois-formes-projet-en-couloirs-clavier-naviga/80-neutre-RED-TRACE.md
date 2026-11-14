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
| (a) 02 : NE1.3, bouton fixe étranger couvrant la fenêtre | repères restés posés | voir « Correction du témoin 02 » ci-dessous |
| (b) NE2.1 : tiroir Git ouvert, PUIS petit bouton fixe en bas à gauche | `[false,false]` | `[true,false]` : chevauchement, le redimensionnement seul le lève |

Témoins verts avant et après (garde contre une lecture supprimée) : CL4.3d (bouton marqué mesuré), NE1.2 (région marquée gardée à son Échap),
NE1.4 (bouton marqué = obstacle). Leur rouge se voit sous mutant (`M-PASTILLE-RIEN` pour 41).

Correction du témoin 02 : le premier rouge de NE1.3 (`1 -> 0`) était FAUX. Le geste de relance (un redimensionnement et un décalage de 20 px du
canevas) faisait perdre le repère même sans aucun élément posé. Le témoin de méthode `reperes-sans` (NE1.5) l'a montré (`1 -> 0` sans élément) ; la
relance est devenue un changement de classe du corps, que 02 observe. Avec ce geste, le rouge de la lecture par la forme se voit sous le mutant
M-FORME-REPERES (la lecture d'avant, rejouée sur une copie) : `1 -> 0` ; la lecture par l'attribut rend `1 -> 1`, le bouton marqué `1 -> 0`.

Réglage du témoin (b) : un premier jet posait le bouton à `bottom: 16px`, sous la barre de question : le tiroir, déjà relevé de 66 px, ne le chevauche
pas, et un second jet l'a posé avant la fin de la lecture `/api/vf/git` (dont le retour rejoue `eviter` et masque le défaut). Le pilote attend maintenant
la lecture rendue, puis pose l'élément à `bottom: 80px` : seul l'arrivée de l'élément est mesurée.

## Mutants (copie complète du module, preuve de chargement par `cockpit_lancer`, code 5 sinon)
- M-FORME-PILE (00, lecture revenue à la forme) : NE1.1 rougit, `[false,true]` au lieu de `[true,false]`.
- M-FORME-REPERES (02, lecture revenue à la forme) : NE1.3 rougit, `1 -> 0`.
- M-EVITER-REJEU (77, `childList` retiré de l'observateur du corps) : NE2.1 rougit, `[true,false]` au lieu de `[false,false]`.
- M-PASTILLE-FORME (41, lecture revenue à la forme) et M-PASTILLE-RIEN (41, lecture supprimée) : dans `test-cockpit-couloirs.sh`, CL4.3 et CL4.3d rougissent.
Verdicts des passes : voir le SUMMARY.
