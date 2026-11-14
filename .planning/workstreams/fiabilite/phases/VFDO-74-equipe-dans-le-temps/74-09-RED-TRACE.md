# 74-09 : trace du rouge (suite des bornes et chaîne XSS étendue)

Base : tête de la branche après 74-01 à 74-08 et 74-10. `VENDORED.txt` porte les lignes AJOUT de 74-01 à 74-05 et 74-07, pas celles des quatre modules de 74-06.
Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-frise-bornes.sh` (par le jeton Chrome). Sortie recopiée sans chemin du poste. Résultat : 29 réussies, 1 échec, 55 s.

## Sonde rouge (la seule)
```
❌ FAIL — B9 a — exactement une ligne AJOUT par module 74-vf-*.js, aucune sans fichier, lignes AJOUT triées (A52)
   obtenu: [ko: manque:assets/ui/74-vf-frise-carte.js manque:assets/ui/74-vf-frise-curseur.js manque:assets/ui/74-vf-frise-encart.js manque:assets/ui/74-vf-frise-fichiers.js]
MUTANT-NON-ETABLI M-AJOUT-OUBLIE (B9 a déjà rouge sur l'original)
MUTANT-NON-ETABLI M-AJOUT-HORS-ORDRE (B9 a déjà rouge sur l'original)
```

## Gardes vertes dès le départ (non-régression ; leurs mutants prouvent qu'elles savent rougir)
B1 a à d (contrat de forme, aucun recomptage, message sur trois lignes compté une fois) · B2 a (méthodes et accès des quatre routes) · B3 a à e (flux, garde d'émission) · B4 a et b (export) · B5 a à c (réseau, dernière commande) · B6 a à c.

## Témoin C0 (la charge aboutit sur la copie vulnérable : sans lui, rien ne prouve que C1 sait rougir)
Manche T, copie du module dont le rendu du texte et de la cible de la fiche est posé par `innerHTML`, CSP neutralisée : `B6 d` vert (élément injecté, marqueur écrit, jeton reçu par l'origine tierce). Manche E (innerHTML seul) : l'élément existe, la CSP retient le script (`B6 c`). Manche L (code livré) : aucun élément, aucun marqueur, aucun jeton (`B6 a`).

## Mutants rougis sur la sonde qui leur est propre
```
MUTANT-ROUGE M-CHAMP-NON-DECLARE B1 a (ko:[["zz"],[]])
MUTANT-ROUGE M-DOUBLE-COMPTE B1 d (ko:300|150)
MUTANT-ROUGE M-GARDE-RETIREE B3 d (ko:{"interdits":[200,200,200,200,200],"propre":200})
MUTANT-ROUGE M-POST B2 a (ko: POST répond 200 sur frise, transcript, state)
MUTANT-ROUGE M-EXPORT-FRISE B4 a (ko:["wk01","sess-x1","onerror=window.__xss74"])
MUTANT-ROUGE M-ECHAPPEMENT B6 a (ko:[2])
MUTANT-ROUGE M-CSP B6 e (ko:[1,"oui"])
MUTANT-ROUGE M-CSP B6 f (ko:[false,[]])
MUTANT-ROUGE M-HOTE-EXTERNE B5 a (ko: violation de la CSP sur l'hôte externe)
```

## Défauts de la suite elle-même, vus au premier jeu et corrigés avant la trace ci-dessus (aucun assert affaibli)
- l'aide `routes` lisait le jeton comme un chemin (cinq routes au lieu de quatre) ;
- l'ancre de M-CHAMP-NON-DECLARE portait un `^` alors que la ligne est indentée (mutant sans effet, détecté) ;
- les éléments injectés étaient comptés fiche refermée (compte nul à tort, M-ECHAPPEMENT restait vert) : ils sont relevés fiche ouverte ;
- M-POST ne rougissait pas : la garde de méthode du répartiteur du serveur double celle de la table des routes, le mutant retire les deux ;
- l'export et le mutant d'export visaient le lab d'un mutant précédent (variable écrasée) ;
- le balayage de l'export cherchait des noms de modules (`vf-frise`), or l'export embarque le code de la page : seules des données (identifiants, charges, forme JSON de la frise) servent de marqueurs.
