---
phase: 71
plan: FIX-ORIGIN
status: passed
requirements: [TERM-02]
commits:
  fix: 26386f72
---

# 71-FIX-ORIGIN — GET /flux et /etat sans Origin en navigateur (P71-D-24) : résumé

Base de mesure : `5008fa17`.

- Correctif dans `controle()` de `vf-cockpit-terminal.mjs` : `navigateur` = GET sur `/flux` ou `/etat` ET `Sec-Fetch-Site: same-origin` ET `X-VF-Terminal` valide (comparaison en temps constant).
  Seul `navigateur` lève le refus « Origin absente ». Une Origin présente doit toujours être celle de Q ; les POST gardent Origin obligatoire.
- Témoin rouge (section T6, client `nav.mjs` qui pose les en-têtes d'un fetch de même origine, sans Origin) sur `5008fa17` : `T6.0` GET /etat attendu [200], obtenu [403] ;
  `T6.0b` GET /flux attendu [200], obtenu [403]. Les 16 refus de T6 sont verts sur la base (garde) et sur le correctif.
- Refus couverts, sur /etat et /flux : Sec-Fetch-Site same-site, cross-site, none, absent ; same-origin sans secret ; same-origin avec faux secret ; Origin `127.0.0.1:<P>` ; plus POST /entree
  et POST /taille sans Origin même en same-origin.
- Mutants (chacun rouge, statut obtenu / sain) : M-NAV-SFS (`!== undefined`) 200/403 ; M-NAV-SANS-SFS 200/403 ; M-NAV-SANS-SECRET 401/403 ; M-NAV-POST (méthode et route levées) 2xx-4xx autre que 403 ;
  M-NAV-ORIGIN (Origin non-Q tolérée si `navigateur`) 200/403. `M-SANSORIGIN` retargeté sur la nouvelle ligne.
- Suites : serveur 184 PASS / 0 FAIL ; session 29 / 0 ; activation 40 / 0 ; pty 39 / 0.
- Écart d'apprentissage : les mutants passaient à vide tant que le secret leur était transmis par expansion avant le démarrage du serveur muté (le secret change à chaque serveur) ;
  substitué dans `navmut` (jetons `@S`, `@P`).

## T12.4 intermittent

Trois rejeux complets de `test-cockpit-terminal-pty.sh` (charge machine 5,3 : l'arbre n'était pas calme, l'autre exécuteur travaillait) : 3 sur 3 à 39 PASS / 0 FAIL.
Avec les rejeux du lot précédent : 1 rouge sur 7 rejeux complets au total, aucun avec le code courant dans ces trois-ci. Cause non établie.
