# 72-09 — trace du rouge (assemblage du lancement côté serveur P)

Date : 2026-11-05. Commit des tests : `9c84608e` (`plugin/cockpit/scripts/tests/test-cockpit-lancer-serveur.sh`, seul fichier du commit).
Commande : `zsh -c 'bash plugin/cockpit/scripts/tests/test-cockpit-lancer-serveur.sh'` (et sous bash) sur la base, AUCUN module d'assemblage (`vf-cockpit-lancer.mjs` et `vf-cockpit-lancer-canal.mjs` absents ; B1 et B2 non posés). Résultat : rc 1, `Résultats : 29 PASS / 44 FAIL`.

## Base mesurée (valeurs de S1 et S2)

Serveur de la sortie sans `--terminal`, jeton de la page Projet, Origin et Host exacts :
- `GET /api/vf/inconnu` : 404, en-têtes `content-security-policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`, `x-content-type-options: nosniff`, `x-frame-options: DENY`, `connection: close`, `transfer-encoding: chunked` (plus `date`, retiré de la comparaison), corps vide. `GET /api/vf/lancer/cibles` rend la même chose.
- `POST /api/vf/inconnu` : 405 (refus des méthodes autres que GET avant l'aiguillage, `vf-cockpit-server.mjs:70`), mêmes en-têtes, corps vide. `POST /api/vf/lancer` rend la même chose (écart de PL-09.2 confirmé : 405 et non le 404 du contrat §4).

## Contrôles positifs verts sur la base (29 PASS)

S0 (200 sous le jeton Projet), S1 et S2 (témoin d'erreur puis égalité avec la route inconnue), S3 (page = disque + un seul script de jeton, pour `/project.html`, `/` et `/index.html` ; CSP = formule de v2.75.0 sans `frame-src`), P1 (parité du gabarit avec les littéraux de 72-CONTRATS §2), A0 (terminal `actif`, journal du faux enfant `{"t":"init"}`), H0 (aucun processus ne survit). Négatifs vacuants sur la base mais gardés par un témoin rouge : F1 à F3 (témoin « au moins trois propositions envoyées à Q » rouge), A1 « aucun texte du lab » (témoin « la réponse porte des cibles » rouge), A3 « aucun texte du lab » (témoin « au moins une proposition » rouge), R10 « aucun fichier MARQ » (couvert par les R10 rouges).

## Témoins rouges (attendu / obtenu)

- A1 (GET cibles) — attendu `200 actif,cibles,claude,terminal true actif true` ; obtenu `404 ` (route inconnue). Pour la bonne raison : la route n'existe pas.
- A2 (POST valide) — attendu `202 {"propose":true}` ; obtenu `405 ` (refus des non-GET).
- A3 (messages IPC) — attendu `ordre-ok 1` ; obtenu `ordre-ko 0` (le journal du faux enfant ne porte aucune proposition).
- A4 (contrat avec le vrai état de Q) — attendu `{"code":202,"liste":true,"retenues":3,"ecartees":0,"proposition":true}` ; obtenu `module introuvable : lanceur`.
- R1 à R12, C2 — attendu `ok;refus;0;ok` ; obtenu `témoin positif absent : le refus ne prouve rien (statut 405);refus;0;ok`. Chaque refus est joué après son témoin : aucun n'est vert à vide.
- C1 — attendu `202 11111111-2222-4333-8444-555555555555` ; obtenu `405 aucune proposition`.
- F1 (témoin) — attendu `oui` ; obtenu `non : 0`.
- U1 — attendu `balise=oui` ; obtenu `balise=non` (le script du lanceur n'est pas dans la page).
- U2 — attendu `exact=oui empreinte=oui` ; obtenu `exact=oui empreinte=non` (la CSP de la phase 71 est déjà exacte ; l'empreinte du script du lanceur manque).
- L1 — attendu `false -> {"etat":"attendue","verbe":"executer"}` ; obtenu ` -> ` (route absente). Forme riche exigée jusqu'à la carte (constat de 72-07 : sans elle, les trois états du suivi n'atteignent pas la carte).
- L2 — attendu `1 false` ; obtenu `1 ` (les cinq messages sont envoyés, la carte n'existe pas).
- L3 — attendu `{"estMap":true,"taille":1,"entree":{"phase":"1","ws":null,"verbe":"executer"}}` ; obtenu `module introuvable : lanceur`. Sa seconde assertion (texte de `vf-cockpit-server.mjs`) est rouge aussi.
- L4 (témoin neuf, ajouté par rapport au plan : états `attendue`, `vue`, `terminee` de `etats(who)` jusqu'à la carte) — attendu `attendue,vue,terminee` ; obtenu `module introuvable : lanceur`.
- E1 — attendu `arrete true` ; obtenu vide (route absente). E2 et E3 — attendu les JSON de la suite ; obtenu `module introuvable : lanceur`.
- M-SANS-DRAPEAU, M-LISTE-PAGE, M-TOKEN-CODE, M-LANCEE-LIBRE — attendu `effet` ; obtenu `sans effet` (fichier cible absent de la sortie : « mutant sans effet », FAIL attendu avant le code).

## Écarts avec le plan (consignés)

1. Ports : `libre()` rend un port éphémère du système avec la garde ≥ 4600 et ≠ 4456 (comme le plan) ; la plage 4860-4879 du mandat n'est pas codée en dur dans la suite committée.
2. `lancee` dans la réponse de GET : forme riche `{ etat, verbe }` (via `etats(who)` de 72-07) ou `false`, jamais le booléen de 72-03 (PL-09.5 écrit le booléen ; le mandat du manager exige la forme riche, la carte de 72-06 la lit).
3. Un point d'entrée `lancer.sourceWho(fn)` fournit le `who` au suivi : une ligne de B1 en plus du plan (le plan n'a pas de voie pour `who`).
4. Corps des refus du gestionnaire : clé `refus` (comme le mécanisme de 72-04 et comme la carte de 72-06 la lit), non `erreur`.
5. Piège de poste : sous bash 3.2, une chaîne `"{\"a\":…}"` imbriquée dans `"$( … )"` subit l'expansion d'accolades ; les corps JSON passent par une variable (A2B, C1B). Premier jet de A2 et C1 : verts à vide sur la base (arguments scindés), corrigés avant le commit.
