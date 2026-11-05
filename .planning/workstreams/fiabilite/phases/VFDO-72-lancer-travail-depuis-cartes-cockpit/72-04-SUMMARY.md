# 72-04 — SUMMARY : mécanisme POST de la page P (LANC-03)

Trace du rouge et des mutants : `72-04-RED-TRACE.md`. Commits : `212b5b4e` (test), `c2a53af3` (trace du rouge), `2f53d462` (feat), `6f3ef754` (trace des mutants).
Suite neuve `plugin/cockpit/scripts/tests/test-cockpit-lancer-post.sh` : 95 PASS / 0 FAIL (zsh, bash 5, /bin/bash 3.2) ; douze mutants tués ; module de 114 lignes, `check-file-size.sh` exit 0.

## Interface pour 72-09 (`vf-cockpit-lancer-post.mjs`)

Exports : `ENTETE_JETON`, `CORPS_MAX`, `REFUS`, `controleHote`, `controleMethode`, `controleOrigine`, `controleJeton`, `controleType`, `lireCorps`, `controleSchema`, `creerPost`.
Branchement : créer `creerPost({ routes, jetons, journal })` seulement sous `--terminal` ; appeler `reconnait(url)` (SYNCHRONE) puis `await traiter(req, res, url)` AVANT le refus des méthodes autres que GET ;
`traiter` ne rejette jamais, répond toujours quand `reconnait` est vrai, rend `false` sans rien écrire sinon. Le journal ne reçoit que des codes de `REFUS` (un seul argument).
Les contrôles précèdent la lecture du corps ; le gestionnaire reçoit une copie à prototype nul des seuls champs déclarés.

## Mesures

- Coupure de connexion sur les corps trop longs (513 octets, 1 Mio) : refus de taille par 413 `taille` avec `Connection: close`, ou coupure côté client une fois le statut rendu ; la suite accepte les deux et exige 0 proposition.
- Risque résiduel accepté (T-72-84) : la durée réseau d'un client local reste mesurable ; la comparaison passe par `egal` (empreinte puis `timingSafeEqual`), jeton de 128 bits.
- Écarts d'ensembles de sondes des mutants par rapport au tableau du plan : voir la trace (W14, W13, W11 s'ajoutent par construction).
- `check-version-sync.sh` : seul constat rouge, le compte de suites (167 contre 174 réels, 72-15) ; `check-machine-paths.sh` : aucun constat nouveau.
