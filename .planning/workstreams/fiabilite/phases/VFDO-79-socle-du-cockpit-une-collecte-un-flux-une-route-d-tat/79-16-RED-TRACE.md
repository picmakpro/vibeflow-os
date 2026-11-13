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

## Tâche 2 — témoins rouges sur le code de la tâche 1 (/project.html et /_vf/ seuls)
Rouges (assertion : attendu, obtenu, raison) :
- K1.1 (adresses) : quatre adresses aux mêmes octets ; obtenu `non` : `/`, `/index.html` et `/equipe.html` servent encore l'ancienne page.
- K1.3 (méthodes) : POST, PUT, DELETE → 405 ; obtenu 200 200 200 (la route de page ne regarde pas la méthode).
- K2.3 : table fermée, neuf variantes → 404 ; obtenu 200 pour `/_vf/ui/../moteur.js` (`new URL` normalise les segments `..` : la recherche doit se faire sur le chemin brut).
- K4.2 : `/plante.js`, `/plante.mjs`, `/serve.mjs`, `/vf-cockpit-server.mjs`, `/index.html.bak`, `/project.html.old` → 404 ; obtenu 200 six fois (service statique de la sortie encore en place).
- K5.1 : treize fichiers de la sortie en 404 ; obtenu 200 pour graph.json, projet.json, recent-work.json, architecture.json, LICENSE, LICENCES-TIERCES.txt, le lien interne (le constat de 79-15 : graph.json servi sans jeton avec `meta.repos[].remote`).
- K5.3 (témoin de base) : même constat sur le serveur de base : `200 200 200 404 404` au lieu de `404 ×5`.
- M-SERVICE : ancre `garde:coquille-404` absente de `serve.mjs` : la copie n'a pas changé (mutant impossible tant que le service statique n'est pas la ligne `404` finale).
- A37.2 : deux orthographes d'un même lab = une identité : obtenu `false` tant que la comparaison portait aussi `sortieEcrite` (l'ancienne forme, orthographe écrite) ; le helper de la suite compare désormais `{ serve, sortie }` (la seule identité) : vert sur la base car `identiteServeur` résolvait déjà par realpath natif.
- M-LEXICAL, M-ECHEC-OUVERT : ancres `garde:coquille-chemin` et `garde:coquille-echec` absentes de `vf-cockpit-module.mjs` : mutants impossibles avant la migration vers `cheminPhysique`.
Verts d'emblée (honnêteté : A37 n'est PAS rouge sur la base) : A37.1, A37.3, A37.4 — les gardes de 79-06 (`moduleAdmis`, `--sortie=`, `identiteServeur`) résolvaient déjà par `realpathSync` natif, fermé par défaut (même verdict que l'oracle du noyau sur les neuf dispositions) ; la migration vers `cheminPhysique` de 79-07 est un changement de SOURCE de règle (une seule fonction), prouvé par les deux mutants et par la présence de l'appel. K2.5, K6.1, M-MARQUEUR, K4.3, K4.1, K4.2 (page servie), K3.2 : verts d'emblée parce que la tâche 1 livrait déjà `lireAssets` (refus des liens), le gabarit exigé, le service de `/project.html` par la coquille.
