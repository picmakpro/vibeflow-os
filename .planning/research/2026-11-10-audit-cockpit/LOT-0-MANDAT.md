# Mandat — lot 0 de l'audit du cockpit : « dire vrai »

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Mission de corrections hors phase. Les
> identifiants renvoient à `REGISTRE.md`, qui porte la preuve de chaque ligne.

**Origine.** Demande de Samuel (session principale Claude Code, 2026-11-10) : « Et que ça soit corrigé et qu'on
applique les choses qui ont été vues. » La session principale la lit comme la validation humaine qu'exige ADR-031
pour ces corrections (choix AUDC-V11 du registre : une lecture, que Samuel peut infirmer).

**Objectif.** Faire dire vrai à l'écran actuel, sans changer sa forme : vingt-huit lignes du registre, presque toutes
de la taille d'un commit. Aucune nouvelle vue. Le périmètre est plus large que le lot 0 de la page de l'audit, qui
comptait treize lignes (choix AUDC-V9).

**Base et sortie.** Branche de mission partie de `release/v2.77.0`. Sortie : une PR ouverte vers `release/v2.77.0`,
CI verte, non fusionnée. La fusion dans la branche de release et toute publication restent des gestes de Samuel.

## Périmètre

Quatre sous-lots, à mener en parallèle quand leurs fichiers sont disjoints.

### A. État des sessions et des agents

| Ligne | Ce qui doit être vrai après | Pour mesurer |
|---|---|---|
| AUDC-D1 | Un sous-agent non fini et muet depuis dix minutes reste affiché, avec « outil en cours depuis N » ; sa session aussi. | `sondes/sonde-visibilite.mjs`, cas du worker en commande longue : rend 0 agent aujourd'hui |
| AUDC-D2 | Une session du lab écrite depuis moins de 24 h reste listée, avec un état lu : occupée, au repos, vous attend, close. Une session au repos n'est jamais dite « terminé ». | même sonde, cas de la session au repos depuis 5 min |
| AUDC-D3 | « À surveiller » et « commande en cours depuis 15 min » se déclenchent de bout en bout ; l'âge avance entre deux poussées. | collecteur réel, pas une donnée écrite à la main |
| AUDC-D4 | Un worker vivant sous un manager terminé est dit « orphelin », jamais rangé dans « Terminés ». | même sonde, cas du worker frais sous manager terminé |
| AUDC-D5 | Les plans de mission nommés `dag-*.json` sont lus comme les `*.dag.json`. | un lab d'essai aux deux nommages |
| AUDC-D6 | « New session » n'est plus affiché comme un nom choisi. | transcript d'essai portant ce titre par défaut |
| AUDC-D7 | Aucun intertitre « Mandat » vide ; pas de mandat pour une session. | rendu du panneau d'une session |
| AUDC-D8 | Le transcript réduit est un seul fil ordonné et daté, toujours sans sortie d'outil. | route du transcript : un tableau, une heure par ligne |
| AUDC-M3 | Le titre de l'onglet Équipe dit le nombre d'agents actifs ; la santé d'Équipe ne contredit plus celle de Code. | capture de l'onglet avec des agents actifs |

### B. Serveur et flux

| Ligne | Ce qui doit être vrai après | Pour mesurer |
|---|---|---|
| AUDC-H1 | Une page ouvre un seul flux d'événements ; quatre onglets ouverts répondent. | `sondes/mesure-page.mjs` (quatrième page), `sondes/mesure-2.mjs` (saturation et reprise à trois) |
| AUDC-H2 | Un seul appel au verrou par cycle, le planning lu une fois par changement, aucune collecte sans client. | `sondes/cout-direct.mjs` (compte des sous-processus), `sondes/sonde-boucle.mjs` (pics) |
| AUDC-H3 | Le journal du serveur porte la date et le motif de chaque arrêt ; deux lanceurs ne se croisent pas ; une relance à options et code identiques ne remplace pas le serveur ; une relance qui change une option (par exemple `--terminal`) le remplace et l'écrit au journal ; toute requête authentifiée compte comme activité. | lecture du journal après chaque cas |
| AUDC-H4 | Aucun titre ni description de carte n'est traduit : `tokens.ts` reste `tokens.ts`. | page servie d'un lab d'essai portant ces noms |
| AUDC-M9 | « Direct coupé » visible à 5 s, bannière à 15 s, retirée seule au retour. | coupure simulée dans le navigateur |
| AUDC-AM7 | En CI, l'absence de Chrome fait échouer les suites qui en dépendent, au lieu d'une sortie 0 ; deux scénarios ajoutés : trois onglets, deux lanceurs. | suite jouée sans Chrome |

### C. Sécurité

| Ligne | Ce qui doit être vrai après | Pour mesurer |
|---|---|---|
| AUDC-A-01 | « Demander » refuse un identifiant de session que ce serveur n'a pas rendu. | requête avec un identifiant bien formé mais inconnu |
| AUDC-A-02 | Un lien symbolique du lab vers l'extérieur n'est jamais suivi à l'assemblage : rien de sa cible n'entre dans une page ni dans l'export. | lab d'essai portant un tel lien vers un fichier marqué |
| AUDC-B-01 | Un worktree déclaré mais non vérifié n'élargit pas « qui est au travail ». | lab d'essai à entrée de worktree forgée |
| AUDC-B-02 | Deux exécutions de « Demander » au plus, un délai global, une réponse 429 au-delà. | trois requêtes simultanées |
| AUDC-B-03 | Les requêtes inter-sites sont refusées hors des routes d'API ; la page Équipe est mémorisée. | requête portant `Sec-Fetch-Site: cross-site` |
| AUDC-B-04 | L'export ne porte plus les clés `vf*` par défaut. | objet d'export reconstitué |
| AUDC-B-06 | Les cinq durcissements sont faits. | un contrôle par retouche |

AUDC-A-02 est le seul constat de taille M du lot : il y figure parce que c'est une fuite de données hors du lab.
AUDC-A-03 part en première vague de la Phase 79, avec le serveur lancé depuis le module. AUDC-B-05 n'est pas dans ce
lot : ses deux corrections défont P72-D-20 (le mode retenu vit dans un fichier du lab), la décision revient à Samuel.

### D. Interface immédiate

| Ligne | Ce qui doit être vrai après | Pour mesurer |
|---|---|---|
| AUDC-M7 | « Mise en page… » s'affiche avant le calcul. | ouverture d'un résultat dans un niveau de 70 cartes |
| AUDC-M10 | Un onglet ouvert à la main dit la vraie cause (amorce à usage unique) et le remède ; une action « Terminer la session » ferme le shell. | capture ; processus du terminal disparu après l'action |
| AUDC-M11 | Après « Annuler », le statut revient à zéro ; la phrase « écrit cette ligne sans la lancer » est visible ; le tiroir s'ajuste au bandeau. | capture avant et après annulation |
| AUDC-X4 | Un seul anneau de focus, présent sur le champ de question ; `aria-current` sur l'onglet actif ; un `<main>`. | parcours au clavier |
| AUDC-X6 | En mouvement réduit, plus de fondu de plongée ni d'animation décorative. | compte des animations actives |
| AUDC-X7 | Un seul format de titre d'onglet. | les trois pages |

AUDC-F6 (« Verifie » sans accent) n'est pas dans ce lot : l'absence d'accent est voulue (alphabet fermé de la ligne)
et déjà consignée au BACKLOG comme point de goût.

## Choix déjà pris

- **État officiel des sessions (AUDC-V8).** `claude agents --json` est un enrichissement optionnel, jamais la source
  unique : commande absente, en échec ou de forme inattendue, le cockpit garde sa lecture actuelle des transcripts.
  L'appel est asynchrone, hors de la collecte bloquante, et sa forme passe par le contrat de
  `plugin/cockpit/scripts/vf-cockpit-interface.json`. Les suites le jouent avec un faux `claude` sur le chemin de recherche.
- **Les fichiers internes de Claude Code** (`~/.claude/sessions`, registre du démon) ne sont pas lus (AUDC-V10).

## Bornes

- Aucun appel réseau sortant (P67-D-02) ; lecture seule sur `.planning/`.
- Dernière commande jamais dans le flux, un fichier ou l'export (P67-D-14) ; verbe et cible réduite, jamais un
  argument (P69-D-16) ; transcript sans sortie d'outil, jamais exporté (P69-D-19).
- Titre par `custom-title` seul, jamais de titre généré (PU-G-162).
- Ni couleur d'alerte, ni fond teinté : glyphe et mot (Q9, DESIGN § 9) ; le tiroir ne pousse jamais la carte (Q12).
- Rien sans l'option `--terminal` (P71-D-02) : la pastille expliquée sans l'option est hors de ce lot.
- Le double geste reste dû dans tous les cas (P72-D-14).
- Avant de corriger une ligne, contrôler qu'elle ne défait pas un arbitrage du registre de sa phase d'origine : la
  relecture du versement n'a couvert que quelques registres (étude § 2). Une rencontre se remonte, elle ne se tranche pas.

## Hors périmètre

Toute nouvelle forme (régie, frise, couloirs), l'index des transcripts, la route d'état, le flux partagé entre
onglets, la traduction au point d'émission : ce sont les Phases 73, 74, 79 et 80.

## Méthode exigée

- Un commit par ligne du registre, son identifiant `AUDC-…` dans le message.
- Chaque ligne livre un test de suite qui rougit sur le code actuel et verdit après le correctif : une preuve doit
  pouvoir rendre rouge. Les scripts de `sondes/` n'affirment rien (leur code de sortie ne dit pas si le constat est
  corrigé) : ils servent à mesurer avant et après, pas de témoin.
- Toutes les suites du cockpit vertes. Trailer `Gate-Touche:` dès qu'un gate, sa suite, une donnée d'essai surveillée,
  le workflow CI ou un hook est touché (AUDC-AM7 touche `.github/workflows/ci.yml`).
- CHANGELOG du module, section « Non publié », comme pour les retours du panel ; pas de bump racine.
- L'état de chaque ligne mis à jour dans `REGISTRE.md` (`fait (date, sha)`). Un sujet du BACKLOG ne se ferme que si
  le registre § 4 dit « clôt » ; un sujet « recoupé » gagne un renvoi et reste ouvert.
- Recette par juges à captures : l'onglet Équipe avec des agents actifs, trois onglets ouverts, une coupure simulée.
- Rapport de mission sous `.planning/missions/`.
