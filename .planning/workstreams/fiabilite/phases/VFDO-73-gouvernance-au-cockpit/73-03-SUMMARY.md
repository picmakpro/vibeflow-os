# 73-03 — champs de gouvernance de who@2 (REGI-04, 05, 06, 07, 09, 10, 16)

Trace du rouge : `73-03-RED-TRACE.md`. Base : c4053a32.

## Livré

Champs facultatifs de `vibeflow/cockpit-who@2` (absents quand ils n'ont pas de valeur) :
- travailleur, sessions seulement : `attendAgents` (entier 1 à 999, session non active), `detient { ws, phase }` (paire seule, bornée),
  `retient { n, portee: 'noeuds' | 'mission' }` (absent si inconnu, jamais deviné), `lancee { phase, ws?, verbe }` (entrée revalidée par `entreeLanceeValide`, sessions seules) ;
- premier niveau : `phasesHumaines [{ phase, ws, ref? }]` (ref = `n:` + identifiant du nœud de phase du graphe Projet), `fenetreStallS` (entier connu).

Contrat : ces champs déclarés, plus le bloc `vibeflow/cockpit-ailleurs@1` (requis `schema`, `ailleurs` ; entrée `[lab, n]` ; interdits `cwd`, `sessionId`, `id`, `name`, `titre`, `chemin`). Aucun bump.
`startLive` reçoit `lancees` (fonction rendant la Map) et expose `lecturesPlanning()` (diagnostic, hors de `etat()` : `/api/vf/etat` ne change pas de forme).

Fichiers réellement touchés : `vf-cockpit-who.mjs` (276 lignes), `vf-cockpit-live.mjs`, `vf-cockpit-interface.json`, `vf-cockpit-gouvernance-lecture.mjs` (créé),
`vf-cockpit-collecte-etapes.mjs`, `vf-cockpit-collecte-fil.mjs`, `tests/regie-rg-collecte.sh` (créé), `tests/test-cockpit-lancer-suivi.sh` (section LR + 2 mutants),
`tests/test-cockpit-who.sh` (une ligne de réinjection de branche brute, voir Écarts), `73-03-RED-TRACE.md`, ce SUMMARY.

## Écarts

- Écart : la collecte tourne dans un fil depuis 79-09 ; `lancees` (mémoire du serveur) est posé sur le `who` reçu dans `startLive` (`poserLancees`, exporté de who.mjs), et la gouvernance du planning est lue dans le fil par `etapePlanning` (mémoire du fil) : d'où `collecte-etapes` et `collecte-fil` touchés, non prévus au plan.
- Écart : la signature du `who` (A17) est déjà « objet entier moins champs volatils » (`vf-cockpit-who-signature.mjs`) : aucune retouche, RG16.13 vert dès la base (témoin de jointure) ; seule correction de `startLive` : garder le `who` le plus récent à chaque tour (C4).
- Écart : le compteur de lectures du planning n'est pas dans `etat()` (aurait changé `/api/vf/etat`) mais dans `lecturesPlanning()`.
- Écart : `nettoie` à l'émission ne porte que sur la branche ; le titre l'est déjà par `nettoieTitre` et un second nettoyage rendait survivants les mutants M-W23-CONTROLES et M-W23-CF de `test-cockpit-who.sh`. Ces mutants rougissaient aussi M-W23-BRANCHE : sa sonde réinjecte la branche brute avant la carte (seule modification de ce fichier).
- Écart : M-DETENTION-BRUTE retire les deux gardes de la paire ensemble (`detention()` et le borneur de collectWho) : une seule ne fuit pas (défense en profondeur).
- Contrat voisin : vf-cockpit-live.mjs (Phase 79, 79-13..18) ne gagne que 12 lignes localisées ; whoSig inchangée.
- Plan 73-02 : le bloc `vibeflow/cockpit-ailleurs@1` est posé ici, comme prévu.

## Suites jouées (tête commitée, une fois chacune)

verts : lancer-suivi (47/0), who (157/0), equipe-etats, equipe, signal, signal-mod, routes, collecte, direct, lecture-fil ; vendor : seul V4 rouge (chrome-coin.mjs à 300 lignes, rouge de base), V4c.9a vert. `test-cockpit-regie.sh` entière : 75 PASS / 0 FAIL (32 s ; 75 PASS dont les mutants). `check-file-size.sh` : OK (who.mjs 276, avertissement ≥ 250). `check-machine-paths.sh` : OK.
`colonnes-cliquet` : aucune hausse. `check-version-sync.sh` : seul écart, la ligne « suites » (attendu).

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Correctifs d'audit

- Constat 1 (`ws` sans grammaire) : le champ `ws` de `phasesHumaines` vient d'un nom de dossier de compartiment, borné par le masque seulement (U+202E et BEL survivaient). Correctif : `phasesHumainesSortie` applique la grammaire de `detention()` (`wsValide`, `phaseValide`, exportées de `vf-cockpit-gouvernance.mjs`) : entrée rejetée si `ws` ou `phase` est hors forme ; `ref` retirée si elle n'a pas la forme `n:<identifiant>`. Témoin : RG16.15, vu rouge sur la tête d'avant ; mutant GRAMMAIRE-WS vu rouge puis retiré. Commit c3ffb7d8.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Correctifs de revue

- Majeur 1 (revue du point de fusion 1) : `memo.gouvernance` n etait posee que par `etapePlanning` ; un fil relance (surMort, refaire, armerReprise, armerIndex) repartait avec un memo vide et un tour sans planning rendait `phasesHumaines` = null jusqu au prochain changement de `.planning`. Correctif : au premier tour d un fil dont le memo n a pas de gouvernance, le fil appelle `etapePlanning` avec le meme memo (une fois par fil, jamais par tour) ; le `catch` de `etapePlanning` laisse une trace bornee (3 lignes au plus par fil). Temoin : RG4.14 (fil relance puis tour sans planning), vu rouge sur la tete d avant (`[["7"],null]`), vert apres. Pas de mutant (ni garde ni filtre).

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
