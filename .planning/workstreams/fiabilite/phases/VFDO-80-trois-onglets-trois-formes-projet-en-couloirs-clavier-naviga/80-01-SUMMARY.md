---
phase: 80
plan: "01"
status: complete
requirements: [FORM-01]
commits:
  - 1c60289a docs(80-01) amendement (mot d'état = pastille .vst)
  - e8e1a1cf feat(80-01) canevas au clavier
---

# 80-01 — SUMMARY : le canevas au clavier (FORM-01)

## Livré

- `plugin/cockpit/skills/cockpit-moteur/assets/ui/04-vf-clavier-canevas.js` (195 lignes, plafond du budget 230 respecté, pas de découpage `04-vf-canevas-champ.js`) :
  un seul arrêt de Tab (carte itinérante), flèches vers le voisin spatial, Origine/Fin, Entrée plonge, Espace sélectionne, la sélection suit le focus en panneau
  latéral ; `#svg` listbox, cartes option (`aria-posinset`, `aria-setsize`, `aria-selected`), nom par `nomDeCarte` ; focus posé au rendu du niveau d'arrivée ;
  repli sur `#stage` (`tabindex=-1`) ; champ de lecture (`champDeLecture`, `amenerDansLeChamp`, `deplacer`) sans changer le zoom ; anneau sur la `.card` ;
  `window.VF_CANEVAS` gelé (`nomDeCarte`, `carteItinerante`, `focaliser`, `champDeLecture`, `amenerDansLeChamp`, `deplacer`, `voisin`).
- `test-cockpit-clavier-canevas.sh` (189 lignes) + `chrome-clavier-canevas.mjs` (224 lignes) : CC1 à CC6, CC9, quatre mutants. `chrome-accessibilite.mjs` : `ANNEAU` lit la `.card` d'un `g.node` focalisé.
- `80-01-RED-TRACE.md` : trace du rouge sur la base (4 PASS / 29 FAIL, dont CC5.1 témoin de non-régression) et mutants.
- `VENDORED.txt` : la ligne `AJOUT assets/ui/04-vf-clavier-canevas.js` est dans la tête, balayée par le commit voisin 80-02 `ef0e9ec9` (même contenu, acceptée).

## Vérifications (rejeu en fin de plan)

- `test-cockpit-clavier-canevas.sh` : 29 PASS / 0 FAIL (quatre mutants rougissent leur assertion). Un rouge H0 isolé (un renderer Chrome encore en train de mourir, charge de la machine) ne s'est pas reproduit au rejeu.
- `test-cockpit-accessibilite.sh` : 35 PASS / 0 FAIL (X4.0 à X4.3 inchangés, assertions non touchées). `test-cockpit-vendor.sh` 130/0. `test-cockpit-moteur-carte.sh` 73/0.
- `test-cockpit-equipe.sh` : 214 PASS / 1 FAIL (EK15.6, « mutant : le focus n'est plus rendu au bouton »). Même rouge sur une copie propre de la tête `HEAD` (210/5 sur ce rejeu) : antérieur à ce plan, hors périmètre. EK18 vert.
- Gabarit : aucun fichier neuf au-delà de 299 lignes ni de 160 points de code.

## Écarts au plan (consignés)

- Amendement daté (1c60289a) : le mot d'état est la pastille `.vst` de la carte rendue, à défaut la classe `st-<statut>` ; `STATE_WORD` n'est pas exposé par l'API gelée.
- Chrome ne rend le rôle `option` d'un `g` SVG que si la listbox en est le propriétaire direct : `#viewport` et le calque des cartes reçoivent `role="none"` (mesuré dans l'arbre d'accessibilité réel).
- Chrome fait du canevas lui-même un arrêt de Tab : `#svg` reçoit `tabindex=-1` (sinon deux arrêts). Sur Équipe, `init` rend la main sans rien poser ni écouter (un écouteur de focus sur `#svg` y suffisait à en faire un arrêt de Tab : X4.2 rouge mesuré, puis corrigé).
- `ready` peut passer avant l'exécution du fichier (seconde page d'une session) : repli sur le premier `render`, et départ immédiat si le moteur a déjà rendu (l'init n'a lieu qu'une fois).
- CC1.1 compte les arrêts dans `#svg` ET exige que ce soit une carte (sinon vert à la base). Les propriétés `posinset`/`setsize` n'existent pas dans le CDP : lues sur les attributs.
- Hypothèse A1 (Safari focalise un `g` SVG à `tabindex`) : non mesurée, relève du juge humain.

## Pour la jointure et les plans suivants

- Idiome A51 / `cockpit_module_copie` / `socle-serveur.sh` : non appliqués ici (pas dans la base). Mutants : copie maison (`mutant()` de la suite : copie des scripts et du moteur dans `$WORK`, lab privé), à passer à `COCKPIT_MODULE="$(cockpit_module_copie)"`.
- `window.VF_CANEVAS.nomDeCarte` est la fonction que la Phase 75 peut envelopper ; `champDeLecture()` ignore `#vf-coin` tant que 80-05 ne l'a pas posé (clause conditionnelle).
- Ligne de CHANGELOG demandée au plan d'assemblage 80-18 : « cockpit : le canevas se parcourt au clavier (une carte, flèches, Entrée, Espace, Échap), chaque carte est nommée pour un lecteur d'écran ».
- `wc -l` : `04-vf-clavier-canevas.js` 195 ; budget restant pour 80-09 (+25) et 80-12 (+40) : 260 au plus.
