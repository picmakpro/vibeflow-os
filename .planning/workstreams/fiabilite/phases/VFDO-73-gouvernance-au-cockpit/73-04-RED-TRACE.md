base: 388c28560f399747b64dcb40def53d43d2ac0427

# 73-04 — trace du rouge (régime allégé)

Commande, sur la base (ni `72-vf-regie-modele.js`, ni `72-vf-regie-style.js`, ni exports de 71) :
`bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG0_ordre_modele RG1_modele RG2_modele RG4_modele RG5_modele RG6_modele RG7_modele RG8_modele RG9_modele RG10_modele RG11_modele RG14_modele`
Sortie : exit 1, `Résultats : 0 PASS / 59 FAIL`.

Cas rouges, chacun avec sa ligne `❌ FAIL — <id> —` : RG0.10, RG1.1, RG1.2, RG1.3, RG2.0, RG4.4, RG5.5, RG5.6, RG6.1, RG6.2, RG7.6, RG8.0,
RG9.1, RG9.2, RG9.3, RG9.4, RG9.6, RG9.7, RG10.6, RG11.1, RG11.5, RG14.0 (plus RG9.8, et les mutants qui disent « modèle présent pour muter » :
ils ne peuvent rien tuer tant que le modèle n'existe pas).

Motif : le fichier du modèle est absent, le harnais vm rend `{"erreur":"fichier absent"}` et chaque lecture rend une valeur vide ; le témoin d'ordre
ne trouve pas le repère `/* ui/72-vf-regie-modele.js */` dans la sortie assemblée.

Obtenu, quatre cas :
- RG1.1 (titres des sections) : attendu `À vous|Au travail|Terminé, à relire|Au repos`, obtenu `[]`.
- RG5.5 (ordre du jeu de la UI-SPEC) : attendu `e,b,a,c,d`, obtenu `[]`.
- RG6.1 (clés du verrou) : attendu les treize clés de la liste blanche et `840`, obtenu `[]`.
- RG9.1 (actif écrit il y a 60 s) : attendu `au travail|actif`, obtenu `[]`.

Garde contre le vert à vide : RG2.0 et RG6.1 exigent une valeur lue (`leaseS` 840, `ws` « fiabilite ») avant de comparer, sinon deux `erreur`
identiques se compareraient égales.
