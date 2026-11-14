# 75-04 — SUMMARY

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Livré

- `vf-cockpit-project.mjs` : `fichiersPlan` lit `files_modified` par le lecteur de frontmatter borné (`listeImbriquee` : liste en ligne ou en bloc, CRLF), garde 200 chemins de 4 096 octets au plus, compte l'excédent dans `touchedIgnores`. Un plan sans `files_modified` n'a ni `touched` ni `touchedIgnores`. `vague` (80) et la trace (76-04) intactes. Emplacement final de la lecture : `addPhase`, dans `vf-cockpit-project.mjs` (la 79 n'a pas déplacé la lecture vers `readPlanning` ; `vf-cockpit-planning.mjs` non modifié).
- `tests/test-cockpit-activite-planning.sh` : T1 à T5 sur `instantane().projet` (fixture générée), 14 PASS. Rouge de la base consigné dans `75-04-RED-TRACE.md` (T3 : attendu 200, obtenu 5 000).
- Commits : `d506bb6a` (feat), `2ea4e357` (fix colonnes : cliquet de 79-11, mes lignes sous 160 colonnes, `vf-cockpit-project.mjs` ne figure plus en écart).

## Écarts

- Le plan supposait la liste en bloc déjà lue ; elle ne l'était pas (`fm` ne lit qu'une ligne) : les plans réels (forme en bloc) avaient `touched` vide. Corrigé ici, sinon ACTV-10 n'aurait eu aucune donnée.
- T1 n'est pas rouge sur la base (le champ n'est pas perdu) ; les rouges sont T2, T2b, T3, T3b, T4, T4b.
- T5 : contrôle structurel (schéma inchangé, valide, champs non requis), pas de condensat contre un état antérieur (77-02 et 80 modifient le même bloc).
- Limite héritée du lecteur de frontmatter (P76-D-24) : un bloc de plus de 400 lignes est lu comme absent, sans compteur.
- CHANGELOG : ligne demandée au manager (cockpit : `files_modified` des plans lus en bloc, bornés, `touchedIgnores`).

## Suites jouées

- `test-cockpit-activite-planning.sh` : vert, 14 PASS, 1 s.
- `test-cockpit-projet-graphe.sh` : vert, 119 PASS, 456 s.
- `test-cockpit-collecte.sh` : vert, 327 s. `test-cockpit-questions.sh` : vert, 17 s. `test-cockpit-securite.sh` : vert, 72 s.
- `test-cockpit-projet-champs.sh` : 1 rouge, PC3.2, antérieur à ce plan (le bloc `cockpit-project@1` d'`vf-cockpit-interface.json` porte `trace` depuis 76-04, la suite attend l'ancien contrat) ; non causé par 75-04, fichier non touché.
- `colonnes-cliquet.mjs verifier` : plus d'écart sur mon fichier (restent ceux des fichiers de 75-01 et d'autres).
