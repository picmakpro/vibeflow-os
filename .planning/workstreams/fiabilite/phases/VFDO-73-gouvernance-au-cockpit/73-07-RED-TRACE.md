base: 852e638e9b76985e987acfe534a9d4a199784fab

# 73-07 — trace du rouge (régime allégé)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG8_pied RG13_page RG14_fr RG16_export`, jouée sur la base ci-dessus (pied de 49 lignes, sans arbres ni « ailleurs »).

## Cas rouges (chacun `❌ FAIL — <id> —`), motif obtenu

- RG8.1, RG8.3, RG8.6 : obtenu `Cannot read properties of null (reading 'lignes')` — le bloc `details.vf-rg-arbres` n'existe pas.
- RG8.2 : obtenu `0||0|0|0` — aucune lecture après l'ouverture (le clic ne trouve rien), 2 attendues.
- RG8.4 (arbres et doublon) : obtenu `true|false` — la ligne 2 ne dit jamais « N modifiés ».
- RG8.5 : obtenu `Cannot read properties of null (reading 'corps')` — ni « Git est indisponible » ni « Réessayer ».
- RG13.30, RG13.31 (quatre labs, dossier personnel) : obtenu `null` — la page n'affiche aucune ligne « Ailleurs sur ce poste ».
- RG13.34 : obtenu `sans-ligne|false|aucune|true|true|false` — rouge par sa précondition positive (la ligne manque) ; ses autres supports sont déjà propres.
- RG16.20 : obtenu `ERR` — précondition non remplie (pas de ligne « ailleurs »), l'export n'est pas évalué.

## Gardes vertes dès la base (`✅ PASS — <id> —`)

RG13.32 (lecture en échec : aucune ligne), RG13.33 (titre sans la session d'ailleurs), RG13.35 (clés de la route, sans navigateur), RG14.20, RG14.21 (« Files », « Health » tels quels ; aucune clé anglaise visible).

## Négatifs pas encore probants sur la base

RG13.34 (la fuite ne peut être jugée qu'une fois la ligne affichée : la précondition rougit à vide) ; les mutants M-AILLEURS-PAGE-STOCKAGE (ancre absente : le pied n'a pas encore de lecture d'« ailleurs ») et M-AILLEURS-FLUX (survivant tant que la page ne lit pas la route) ne sont pas encore décisifs.
