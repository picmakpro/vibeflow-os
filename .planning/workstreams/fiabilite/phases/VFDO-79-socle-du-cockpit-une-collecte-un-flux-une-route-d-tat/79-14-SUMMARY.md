---
phase: 79
plan: "14"
requirements: [SOCL-18]
---

# 79-14 — flux unique entre les onglets (SOCL-18, C4, P79-D-14)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — pas de mutant, pas de preuve
générative (flux-entrees.mjs et flux-veille.mjs de la proposition de preuve générative non créés : classes hostiles et écarts joués en cas nommés, oracle écrit à la main).

## Livré

- `ui/69-vf-flux.js` (216 lignes, 0 ligne de plus de 160 colonnes, en-tête de quatre lignes, aucun nom du moteur d'origine, aucune chaîne visible, aucune adresse absolue) :
  élection par Web Locks, relais par `BroadcastChannel` (nom du verrou et du canal : `vf-cockpit-flux:` + empreinte du lab, lue de `GET /api/vf/modeles`), repli un flux par page
  (sans primitive, hors contexte sûr, empreinte illisible ou mal formée), rejeu à l'arrivée d'un onglet (`salut`), veille de 45 s par instants (minuterie d'une seconde gardée
  par `typeof setInterval`, retour de visibilité), perte relayée (`perdu`), reprise d'un élu muet (`ping`, `pong`, vol de verrou après 2 000 ms plus une gigue de 0 à 1 000 ms),
  validation stricte de chaque message du canal (enveloppe de clés exactes, version 1, type fermé, nom dans la liste, charge chaîne de 1 048 576 caractères au plus, JSON d'objet
  simple, cinq clés interdites à toute profondeur, 100 000 nœuds et 64 niveaux au plus), garde de relais (une charge qui contient le jeton de l'élu n'est pas relayée).
- `VF_FLUX` gelé : `ouvrir(jeton)`, `ecouter(nom, rappel)`, `connexion()`, `surConnexion(rappel)`, `role()`, `diagnostic()`, `EVENEMENTS` (etat, frise, git, hello, lock, patch, reload,
  structural, vie, who ; sept repères de phase 73, 74, 75, 76, 77, 80, 81 derrière la ligne de règle). Source de la forme d'un `EventSource` (`addEventListener`, `removeEventListener`,
  `close`, `onerror`) ; rappel reçoit `{ type, data }` ; `ecouter` : `rappel(charge, { relaye, rejeu })`. Messages du canal : `{v:1,t:'evt',nom,data}`, `{v:1,t:'rejeu',a,nom,data}`,
  `{v:1,t:'salut',id}`, `{v:1,t:'ping',id}`, `{v:1,t:'pong'}`, `{v:1,t:'perdu'}` (`id` : identifiant aléatoire de l'onglet, jamais un jeton).
- `ui/70-vf-live.js` : une ligne remplacée (`const es = window.VF_FLUX.ouvrir(SRV.token);`), 288 lignes comme avant, ligne ancre de `onerror` intacte, colonnes inchangées. `VENDORED.txt` : ligne `AJOUT assets/ui/69-vf-flux.js`
  avant celle de 70. `test-cockpit-equipe.sh` : variable `VF_FLUX_JS` et chargement de 69 dans `vm70` et `vm70s` (EUI2, EA2, EA3, E23 verts à l'identique).
- Aides de test : `chrome-session.mjs` (champ `port`), `chrome-onglets.mjs` (`ouvrirOnglet`, `AMORCE_FLUX`), `flux-monde.mjs` (navigateur simulé), `flux-scenarios.mjs`, `flux-veille.mjs`,
  `chrome-silence.mjs`, `chrome-reco-onglets.mjs` ; suites étendues : `test-cockpit-flux-unique.sh` (FV, FU à sept onglets), `test-cockpit-direct-coupe.sh` (DV, S1), `test-cockpit-reconnexion.sh` (RV, N5).
  Dans les trois suites, la porte « pas de Chrome » est après les sections du navigateur simulé.

## Écarts

- Écart : l'ancien sens de F2.1 (« quatre pages vues ») et F2.2 (« quatre flux ») est retourné en « un seul flux » (FU2.2) ; F1 et F3 sont repris par FU1 et FU4. Aucune assertion affaiblie.
- Écart : `declarerPerdu` ne ferme pas le flux réel ; c'est `close()` de la source, appelée par la ligne d'ancre de `onerror` de 70, qui le ferme (sinon le témoin N4.1, « la page ne ferme pas son flux », perdait son rouge).
- Écart : pas de mutant (Chrome ni simulé) ni de propriété générative : régime allégé ; les marqueurs `garde:flux-election` et `garde:flux-canal-nom` ne sont pas posés (aucun mutant ne les vise).
- Écart : l'élu volé redevient suiveur et se remet en file ; le rejeu mémorise aussi les événements reçus par relais (une source rouverte dans un suiveur reçoit l'état connu).
- Écart : `FLUX_ONGLETS` (suite flux unique) permet de rejouer le témoin du septième onglet sur la base ; valeur par défaut : 7.
- Le commit de la tâche 1 contient aussi la version finale de `chrome-flux-unique.mjs` et de `test-cockpit-flux-unique.sh` (sections des tâches 2 à 4) : le code de la page a été écrit d'un bloc.
- Base : le rouge V4 de `test-cockpit-vendor.sh` (chrome-coin.mjs à 300 lignes) vient de la base `faed809d`, non traité ici.

## Suites jouées

Une fois, sur la tête commitée (verdict, durée) : flux-unique 34 PASS / 0 FAIL (10 s) ; direct-coupe 35/0 (58 s) ; reconnexion 20/0 (27 s) ; equipe, reseau, assemblage, securite,
robustesse, direct, transcript, fr-donnees, chrome-fr, projet-visite, git-entete, accessibilite : exit 0 ; vendor : un seul rouge, V4  (base : chrome-coin.mjs à 300 lignes, non traité).

## À documenter par 79-20

Nom `VF_FLUX`, élection, rejeu, veille de 45 s (précision de l'ordre d'une seconde), limites : `127.0.0.1` et `localhost` sont deux origines (deux flux), primitives absentes d'un
navigateur (repli un flux par page), vol de verrou, preuve du silence faite au bord du navigateur.
