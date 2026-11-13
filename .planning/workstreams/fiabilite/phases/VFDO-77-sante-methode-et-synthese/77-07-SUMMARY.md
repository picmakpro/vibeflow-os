# 77-07 — Bloc « Coût par phase et par étage · dernières 24 h » : SUMMARY

## Livré

- `ui/74-vf-synthese-cout.js` (248 lignes, aucune ligne au-delà de 160 points de code) : bloc `cout` du registre (entrée remplacée à chaque exécution du script par onglet, jamais doublée),
  `window.__vfSyntheseCout` gelé (`ETAGES`, `etage`, `agreger`, `depuisAgregat`, `minorant`, `etatDeSource`, `fmtJetons`, `fmtDuree`). Tableau (4 colonnes, `aria-labelledby` du h3), une ligne par phase
  du jalon avec activité puis « Hors jalon » puis « Non rattaché », chaque ligne dépliable par étage, ligne de total ; « au moins » devant chaque total et phrase du minorant quand la frise est
  tronquée ; cinq états de `source.etat` ; 404 ou schéma inconnu : aucun nœud ; autres échecs : « Coût indisponible… ».
- Suite `test-cockpit-synthese-cout.sh` (65 assertions : S0 à S7, CO0 à CO12 sous `vm` avec et sans l'agrégat de la 74, CO13, CO14, W11, W15c, W17.1 à W17.13, E0, M-INNER), fixtures
  `chrome-synthese-cout-fix.mjs`, scénario `chrome-synthese-cout.mjs` (outil neuf `interceptions`, multi-routes) et mode `cout` du banc `chrome-synthese.mjs`.
- Ligne `AJOUT` de `VENDORED.txt`, durée de CI, entrée de CHANGELOG du cockpit, compteur « 246 suites » des deux README (remesuré sous verrou), `77-07-RED-TRACE.md`. Aucune VERSION bumpée.

## Précisions de contrat

- L'agrégat de la 74 est réutilisé quand `window.__vfFriseCalculs` existe (`agreger(voies, 'mission', …)`), sinon calcul propre de même règle ; les deux donnent un résultat identique (CO7).
- Forme d'erreur de `VF_ETAT.lireJson` : `Error` portant `statut` (404 -> absent, autre -> indisponible), conforme au plan. `voiesOmises` et `tronque` sont livrés par la route (`vf-cockpit-frise.mjs`).
- Jalon en cours : union des phases des jalons dont une phase n'est pas faite (sinon le dernier jalon ; aucun jalon : tout est « du jalon »).

## Écarts

- Écart : « Σ lignes + horsMission = total » ne vaut que pour `par='mission'` dans la 74 ; l'adaptateur range par phase et vérifie Σ phases + Hors jalon + Non rattaché = total (CO7), sans reprendre l'égalité de la 74.
- Écart : la fixture de frise vient de la fabrique de la 74 (`frise-fabrique.mjs`, forme C3), non d'une réponse capturée sur la route.
- Écart : CO12 (DOM), CO13 et CO14 sont jugés dans Chrome (les exports sont fixes : aucune fonction de rendu exportée) ; CO12 sous `vm` juge `etatDeSource`.
- Écart : W17.13 compare les ordonnées des blocs 1 à 3 dans la MÊME page (route en 404, puis présente après un cycle d'onglets), la mémoire de visite changeant le contenu d'un rechargement à l'autre.
- Écart : `minorant(r, total)` prend le total en second argument (la phrase le cite).
- Écart : tâches 1 et 2 du plan : tracer et bloc complet en un seul commit de code ; la ligne `AJOUT` entre avec le fichier (un `AJOUT` sans fichier rougit le plafond).
- Écart : `ctx.lireJson` de la coquille n'est pas utilisé (il rend `null` sur tout échec) : `VF_ETAT.lireJson` est appelé directement.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — mutants M-DEVINE, M-CACHE-CREE, M-MONNAIE, M-ZERO-INCONNU, M-MINORANT, M-ETAT,
M-HORS-JALON, M-PRINCIPAL, M-OMISES-ZERO, M-AGREGAT, M-NETTOIE-ABONNEMENT non joués ; la garde d'échappement garde son témoin rouge ET son mutant (M-INNER : `e.textContent = '' + texte` remplacé par
`e.innerHTML`, charge prouvée, W15c rougit) ; revue et audit non lancés.

## Suites jouées (tête commitée)

- `test-cockpit-synthese-cout.sh` : 65 PASS / 0 FAIL (74 s). Rouge d'abord : 8 PASS / 56 FAIL (72 s).
- `test-cockpit-synthese-page.sh` 38/0 (30 s), `-visite.sh` 45/0 (36 s), `-blocs.sh` 59/0 (27 s), `test-cockpit-chrome-fr.sh` 141/0 (37 s), `test-cockpit-vendor.sh` 252/0 (172 s),
  `css-jetons.mjs` : 0, `scripts/check-version-sync.sh` : vert (246 suites).
- Rouges connus non rencontrés : aucune des suites concernées (routes F.1, robustesse, git-entete, R3.18, T24F4.1) n'a été jouée.
