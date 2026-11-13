# 75-05 — SUMMARY : route et schéma de l'activité

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Exception tenue : ce plan est marqué pour l'audit de sécurité,
chaque garde porte un témoin rouge puis vert ET un mutant vu rouge (vingt mutants rouges, voir `75-05-RED-TRACE.md`).

## Livré

- `plugin/cockpit/scripts/vf-cockpit-activite.mjs` (165 lignes) : `creerActivite(options) -> activite(ctx)`, `activite`, `routeActivite` (le lecteur de la ligne de table), `SCHEMA_ACTIVITE`, `COLLISIONS_MAX`, `GRACE_MS`.
  La part git (journal incrémental de 75-01, branches, arbres vérifiés, contexte des gardes de 75-02) est calculée hors de la requête, en mono-vol (`monoVol`), seulement quand `instantane().git.sig` ou la
  signature de `graph.json` change ; la part agents et plans (empreinte et collisions de 75-03, plans de 75-04) vient de l'instantané en mémoire, recalculée par instantané.
- `vf-cockpit-server.mjs` : UNE ligne `['/api/vf/activite', routeActivite]` en tête de `ROUTES` (ordre alphabétique) et l'import ; 243 lignes. Aucun contrôle recopié.
- `vf-cockpit-interface.json` : bloc `vibeflow/cockpit-activite@1` (champs, énumérations, `cles`, `interdits` recopiés).
- `tests/test-cockpit-activite-route.sh` : R1 à R18, X0 à X4, vingt mutants ; `tests/test-cockpit-routes.sh` : liste de RK.1 et compteur de RK.7 (RECOMPTÉ sur la table réelle : 10 routes) ; `75-05-RED-TRACE.md`.

## Forme finale de `GET /api/vf/activite` (consommée par 75-07 et 75-08)

200 JSON `no-store`, ou 403, 405 (réponse gardée), 503 `emission-refusee`. Tableaux de tuples partout, jamais un chemin, une branche, un rôle ou un titre en clé.

```
{ schema: "vibeflow/cockpit-activite@1", at: ISO (dernière dérivation), etat: "ok" | "en-calcul" | "indisponible", calcul: "pret" | "en-cours",
  git: { etat: "ok"|"vide"|"indisponible"|"absent"|"en-lecture", fenetre: { jours, commits, plafond, plafondAtteint, partiel },
         chauds: [[chemin, commits, loc, rang, palier]], couplage: [[a, b, communes, degre]], paliers }   // hors ok et vide : { etat } seul
  branches: { etat: "ok"|"indisponible"|"absent"|"en-lecture", tetes, plafond, plafondAtteint }          // les collisions de branches sont dans `collisions`
  gardes: { etat: "ok"|"non-lues"|"indisponible"|"en-lecture", gardes: [[chemin, suites, estGarde 0|1]], estGarde: [chemin], prevusIgnores }
  empreinte: { etat: "ok"|"en-construction"|"tronque"|"indisponible", incomplet, limite: [codes], marques: [[chemin, "en-cours"|"modifie"|"lu"|"fini", [noms]]],
               horsCarte, horsLab, coupees, rejetes, ignorees, voiesTronquees, voiesCiblesTronquees }
  collisions: [[chemin, "agents"|"arbres"|"branches"|"plans", [noms], vague|null]]   // 500 au plus, triées (chemin, source, vague)
  radar: { incomplet, raisons: ["en-construction"|"tronque"|"cibles-coupees"|"agents-indisponible"|"plans-indisponible"|"branches-indisponible"|"plans-tronques"|"collisions-tronquees"],
           total, tronque, sansVague, plansTronques, limites: ["plans-comparaison-textuelle"] } }
```

- `git` nul dans l'instantané (ou instantané absent) : `git`, `branches`, `gardes` valent `en-lecture`, `calcul: "en-cours"`, `etat: "en-calcul"`, `empreinte.etat: "en-construction"` ; la page ne doit pas y lire un radar complet.
- `calcul: "en-cours"` tant qu'un calcul est en vol ou que la clé a changé ; l'objet précédent est servi pendant ce temps. La page relit tant que `calcul` vaut `en-cours`.
- « Aucune collision » ne se dit que si `radar.incomplet` est faux ET `calcul` vaut `pret` ; `radar.limites` dit que les plans sont comparés sur le texte brut.
- `empreinte.limite[0]` vaut toujours `ecritures-par-commande-non-vues`.
- Schéma : `gardes.etat` gagne `en-lecture`, `git.etat` et `branches.etat` aussi (énumération ajoutée, A47) ; `etat` de premier niveau n'émet pas `absent`.

## Écarts

- Écart : `activite(ctx)` est la fonction que rend `creerActivite({ binaire, horloge, lireInstantane, graceMs, collisionsMax })` ; l'option `binaire` ne se passe pas à l'appel mais à la création (essai en node, hors serveur, comme le plan le voulait ; le serveur n'a aucun point d'injection).
- Écart : `branches.collisions` n'est pas servi dans `branches` (la recherche le montrait) : les collisions de branches sont dans `collisions`, tuple `[chemin, 'branches', [noms], null]`, pour ne pas servir deux fois la même donnée. Le marquage « incomplet » des collisions est dans le champ frère `radar` (le plan écrivait « `collisions` marquées `incomplet: true` » alors que `collisions` est un tableau).
- Écart : lab sans signature (`instantane().git` nul au-delà de 30 s, hors dépôt) : la lecture part sans signature (clé `sans-signature`, une seule fois) et rend `absent` ; sans cela un lab hors dépôt resterait « en cours de lecture » à vie, la signature de la collecte ne se posant jamais. Dans la grâce, `en-lecture` exact.
- Écart : la cible d'empreinte du plan ne peut pas servir de marqueur d'export (elle a une carte : son nom est aussi dans `graph.json` et dans l'export légitime) ; le marqueur est le nom de la branche du lab (dans une collision de branches de la route et dans `meta.vfGit` de `graph.json`, que l'export retire). Le mutant de X3 est l'export qui garde `vfGit`.
- Écart : hors liste de fichiers, `test-cockpit-lecture-fil.sh` D8.9 et D8.9b (deux chaînes attendues et le titre) : le bloc neuf en fait un huitième schéma à interdire `fil` (même geste que 79-13 pour `cockpit-frise@1`).
- Écart : `titres` des sessions n'a aucune source en mémoire livrée : les sessions s'affichent `session · <arbre>`. Les cartes `st: 'prevu'` ne comptent pas parmi les cartes (une écriture sur un fichier prévu est comptée `horsCarte`).
- Limite : `ls-files` des gardes passe par le programme git par défaut, pas par l'option `binaire` (le contexte des gardes n'accepte pas d'option) ; il ne part que dans la tâche de fond, jamais par requête. `gardes` et `chauds` ne sont pas plafonnés (ils suivent la taille du graphe) ; seules les collisions le sont (500).
- Limite : le graphe qui change sans changement de `git.sig` relance la dérivation des chauds et des gardes (sans git, contexte des gardes gardé) : le contexte des gardes (suites, `ci.yml`) ne se relit qu'à `git.sig`.
- Limite : R8 (écart de ticks <= 250 ms) mesure l'horloge de la machine ; sous charge forte il peut flotter.
- Hors périmètre non écrit (au manager) : ROADMAP, STATE, REQUIREMENTS, CHANGELOG (ligne demandée à 75-10 : « cockpit : route `GET /api/vf/activite` (`vibeflow/cockpit-activite@1`), lue en mémoire, jamais dans l'export »), `ci-shard-suites.sh` : la suite `test-cockpit-activite-route.sh` (95 s) y est à inscrire ; compteur « N suites » des README racine (`check-version-sync.sh`) : une suite de plus.

## Suites jouées (sur la tête commitée)

- `test-cockpit-activite-route.sh` : vert, 30 PASS, 0 FAIL, 20 mutants rouges, 95 s. Rouge de base : `75-05-RED-TRACE.md`.
- `test-cockpit-routes.sh` : vert, 56 PASS, 0 FAIL, 17 s (RK.1 et RK.7 verts avec la route réelle sondée). Rouge avant mise à jour de la liste : 51 / 5.
- `test-cockpit-lecture-fil.sh` : vert, 17 PASS, 1 s.
- `test-cockpit-lancer-mode.sh` (balaie chaque route de `ROUTES` pour une sentinelle de secret) : vert, 113 PASS, 197 s.
- `scripts/check-machine-paths.sh` : vert. `colonnes-cliquet.mjs verifier` : aucun de mes fichiers en écart. Temps total dans les suites : environ 310 s.

## Correctifs d'audit

- F1 (haut) : `calculerGardes` cède la main toutes les 8 ms et rend `tronque` au-delà de 30 millions de couples motif x fichier ; R19 (écart de ticks 26 ms, 3 846 ms sans cession) et R20.
- F2 (moyen) : réponse bornée (10 noms par tuple, chemins de 300 caractères, listes plafonnées, 8 Mio au plus, chaque coupe dite : `tronque`, `marquesTronquees`, `radar.nomsTronques`, `cheminsEcartes`) ; sérialisée une fois par objet servi (`brut`) avec squelette de clés (`controle`) ; R21.
- F3 (bas) : reprise après 60 s d'un échec git ou des gardes, une tentative par délai ; R22. F4 (bas) : `ls-files` passe par l'option `binaire` ; le graphe seul qui change ne lance aucun git (R6).
- F5 (bas) : R2b et ses quatre mutants jugent la propriété (importe-t-on une lecture de fichier, un contrôle d'accès, un en-tête ?), les grep d'origine restent.
- Schéma : `gardes.etat` gagne `tronque` ; champs `git.tronque`, `gardes.tronque`, `empreinte.marquesTronquees`, `radar.nomsTronques`, `radar.cheminsEcartes` ; raisons `chemins-ecartes`, `reponse-trop-grosse`. Fichier amont touché : `vf-cockpit-activite-gardes.mjs` (commit `fix(75-02)`).
- Suites : route 35 PASS / 35 mutants rouges (214 s), gardes 25 PASS (9 s), routes 56 PASS (19 s) ; cliquet de colonnes sans écart sur mes fichiers.

## Correctif D10.7 (le cockpit ne choisit jamais l'exécutable git)

- Le paramètre `binaire` est retiré de `vf-cockpit-activite.mjs`, `-git.mjs` (`calculerGit`), `-branches.mjs` (`collisionsBranches`) et `-gardes.mjs` (`contexteGardes`) : aucun chemin de production ne le porte, sous aucune forme (raccourci, variable renommée).
- Les essais injectent un faux `git` en tête du PATH, dans un dossier hors du lab (l'assainissement du PATH par `envGit` ne retire que les dossiers du lab : le faux git s'exécute) ; `test-cockpit-activite-git.sh` (helpers `via` et `sansGit`) et `test-cockpit-activite-route.sh` suivent. Le mutant de F4 devient `ls-files-hors-du-path-espionne` (un `ls-files` lancé par un chemin absolu échappe à l'espion : rouge). L'espion voit désormais aussi les `config` du lanceur (lecture des filtres) : ils comptent dans « zéro invocation ».
- Rejoué : `test-cockpit-git-config-depot.sh` 138 PASS (D10.7 = 0, M-BINAIRE = 1|0), route 35 PASS / 35 mutants rouges (218 s), git 82 PASS, gardes 25 PASS.
