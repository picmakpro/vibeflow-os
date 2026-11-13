AVANT-16 2fb2d9d662c3f0705d41628d6eb9c2573859755c

# 79-16 — trace des rouges (régime allégé : pas de preuve générative ; chaque garde a son témoin rouge et un mutant)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Références de départ (base 2fb2d9d6)
`serve.mjs` : `sendPage`/`sendParties` 5 occurrences (définitions et appels), `pageCsp` 2, `createReadStream` 1 ; `viewer.html` : `extensionsPosees` 2, marqueurs de gabarit 1 chacun (plus `__UI_I18N__`, ajouté par 79-10) ;
fichiers `ui/` de premier niveau : 41 (dont trois `// vibeflow:fr` posés avant le moteur à l'assemblage).

## Tâche 1 — témoins rouges sur le code présent
Verts d'emblée (témoins) : K0.1, K0.2, K0.3 (serveur prêt, sortie assemblée avec marqueurs de phase et de remote, chemin du lab dans graph.json).
- K1.1 : attendu document < 700 000 octets sans marqueur du lab ni chemin, un bloc de manifeste ; obtenu 2 666 398 octets, 0 bloc de manifeste, marqueur de phase présent, chemin du lab présent : la page d'un seul tenant porte ses données et ses scripts en ligne.
- K2.1, K2.2 : attendu fichiers `/_vf/` en 200 avec étiquette forte et 304 ; obtenu 404 (aucune route `/_vf/`, pas de manifeste).
- K3.1 : attendu une source `http://127.0.0.1:<port>/_vf/` en plus des empreintes ; obtenu aucune autre source (CSP faite de la seule liste d'empreintes).
- K3.3 : la ligne `const csp =` de la base n'est pas celle de v2.75.0 plus la source (la base porte `cspDe(...)`, 79-15) ; terminal-aux porte la copie de v2.75.0 sans source.
- C1.1 à C1.3 : attendu onglet Projet rendu depuis le document, sans violation, second chargement en 304 ; obtenu `window.VF_COQUILLE` absent (la page se rend d'un seul tenant, aucun fichier de `/_vf/`).
