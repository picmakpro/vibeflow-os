AVANT-17 898511f0

# 79-17 — trace du rouge (régime allégé : témoin rouge puis vert, pas de mutant)

## Porte du flux retenue (79-17-b)
`ui/69-vf-flux.js` expose `window.VF_FLUX = { ouvrir, ecouter(nom, rappel(charge, meta)) -> désinscription, surConnexion(rappel(etat)) -> désinscription, diagnostic, connexion, role, EVENEMENTS }`.
Le magasin s'y branche par `ecouter` (une fois par événement consommable : hello, who, lock, git, graphe, structural, etat, frise) et `surConnexion` ; la charge reçue est déjà un objet
validé par le flux (aucune clé interdite, bornes de nœuds et de profondeur). Aucun écouteur de document, aucune minuterie, aucune connexion propre.

## Rouge sur le code présent (tâches 1 et 2), sortie `rouge-t1.out` : 5 PASS / 62 FAIL
- Verts d'emblée (témoins) : K0.1 (serveur prêt), K0.2 (page chargée, moteur rendu), K0.3 (l'enveloppe voit le flux), K0.4 (l'objet du moteur est gelé, sans clé du magasin), H0.
- A, F, L, J : rouges, `erreur : fichier du magasin illisible` — le fichier `ui/70-vf-etat.js` n'existe pas (le scénario ne s'exécute pas, A0, F0, L0, J0 le disent).
- S1 à S5 : rouges — fichier absent (taille, marqueur, mots interdits, écouteurs, ligne AJOUT : mesures à 0 ou 1 ligne manquante).
- K0.5 : attendu `{statut:200, etag:true, manifeste:true, …}`, obtenu `{statut:404, etag:false, manifeste:false}` — `/_vf/ui/70-vf-etat.js` n'est pas dans la liste fermée.
- K1.1 à K1.6 : obtenu `null` ou `undefined` — `window.VF_ETAT` n'existe pas.
- C0 : la mesure avorte (`window.VF_ETAT` absent) ; C2, C3, C4.1, C4.2, C5 : valeurs vides.

## Vert après (tâches 1 et 2) : 67 PASS / 0 FAIL, sortie `vert-t2.out`
Chaque rouge est devenu vert pour sa raison : le fichier existe (A, F, L, J, S), la route `/_vf/` le sert (K0.5), le flux réel alimente `connexion`, `etat`, `who` et `planning`
(K1.3 à K1.5, serveur réel, plan ajouté au lab), `lireJson` refuse `/api/export` sans requête (K1.6), six changements d'onglet laissent `abonnes()` à son compte de départ
sans rechargement de page (C2, `performance.timeOrigin` inchangé), la pastille d'un onglet neuf dit « 1 au travail » sans événement (C3), la perte pose `perdu` (C4.1).

Deux pièges relevés en chemin (consignés pour les vues suivantes) : 71-vf-equipe-rendu.js se charge après 70-vf-live.js (dessiner au chargement lève `window.__vfEquipeRendu` indéfini :
la lecture du magasin se fait dans le rappel de `VF_COQUILLE.surOnglet`) ; la portée d'onglet de 79-16 retire les propriétés posées sur `window` et sur les attributs de `<html>`
après le premier rendu (une marque de page ne survit pas : preuve d'absence de rechargement par `performance.timeOrigin`).

## Tâche 3
- Rouge avant le retrait (cliquet sur l'arbre de 455da5e8 contre la baseline) : `HAUSSE 70-vf-live.js réel=1 baseline=0`, `HAUSSE 72-vf-equipe.js réel=2 baseline=1`, `HAUSSE 76-vf-git-entete.js réel=1 baseline=0`, code 1.
- Caractérisations EKR1 (réponse « dernière commande » reposée) et EKR2 (transcript reposé) : vertes AVANT le retrait (217/0, `equipe-avant.out`) et APRÈS (217/0 sur la tête finale). Non prouvées capables de rougir (mutants levés, régime allégé).
- Vert après : suite du magasin 90/0 (O, R comprises, cliquet conforme à 22) ; EK8.2 et EK9.2 ré-ancrées (`SC.on('panel', () => { rendreFocus(); `) toujours « muté|BODY ».
- Rouges de l'après-retrait, corrigés (1e6df69a) : les faux moteurs de vm70/vm70s n'avaient pas `on` (21 rouges EUI2/EA2/EA3, `SC.on is not a function`) ; la suite git-entete provoquait le recalcul du titre par un changement de classe du corps, le tiroir Git émet désormais `vf-git:etat` après la classe.
