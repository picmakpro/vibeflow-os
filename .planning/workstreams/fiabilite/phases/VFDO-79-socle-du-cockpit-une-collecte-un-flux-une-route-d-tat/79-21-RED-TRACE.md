AVANT f5c2e9eb2a0b68cf7fe2ae80dc22a843f28b1be3

# 79-21 — trace du rouge (coût borné de la correspondance de motifs, P79-D-32, SOCL-26)

Ni motif exact ni taille de famille ici : ils vivent dans le banc de la section GLOB de test-cockpit-confinement.sh (dépôt public).

## Tâche 1 — rouges constatés sur la base (AVANT ci-dessus), suite jouée en entier

Graine fixe de la suite : graine=79210101 (rejeu : VF_GLOB_GRAINE=79210101 VF_GLOB_N=4000 bash test-cockpit-confinement.sh). 66 PASS d'avant intacts (sections A à H), 74 PASS / 15 FAIL au total.

Verts voulus sur la base (témoins) : GLOB.E0 (complète : 13 classes, chacune au moins 150 motifs, 20 correspondances, 20 non-correspondances), E1, E2, E3a, E3c (équivalence de la copie gelée à la base : témoin d'oracle), P0, P3 (banc : linéaire laissé passer, quadratique vu, rapports 1,98 et 3,97), C4.

Rouges voulus, un par identifiant (assertion, attendu, obtenu) :
- GLOB.E3b — attendu : `identique` (le motif malformé à alternative de niveau supérieur ne correspond plus à rien) ; obtenu : exemple fixe `a[{/*.js,/` et chemin `zz/` : verdict attendu false, obtenu true.
- GLOB.P1.F1 — attendu `ok` (t(2N) <= 2,5 x t(N) + 1 ms) ; obtenu rouge t1=53,2 ms t2=416,7 ms rapport 7,83.
- GLOB.P1.F2 — obtenu rouge t1=60,4 ms t2=968,5 ms rapport 16,04.
- GLOB.P1.F3 — obtenu rouge t1=67,1 ms t2=1 029,0 ms rapport 15,33.
- GLOB.P1.F4 — obtenu rouge t1=70,6 ms t2=552,7 ms rapport 7,83.
- GLOB.P1.F5 — obtenu rouge t1=36,3 ms t2=468,6 ms rapport 12,90.
- GLOB.P2.F1 à F5 — attendu `ok` (t(2N) <= 250 ms) ; obtenu rouge t2 = 416,7 / 968,5 / 1 029,0 / 552,7 / 468,6 ms.
- GLOB.C0, C1, C3 — attendu `ok` ; obtenu : « échec : module de correspondance absent ou illisible (ERR_MODULE_NOT_FOUND) » (le module neuf n'existe pas sur la base).
- GLOB.C2 — attendu `ok / 1 ligne / court` ; obtenu : même échec d'import.

Rejeu à la main de la mesure de la Phase 75 sur la base (un appel par taille, processus fils à délai de 20 s, motif à trois `**` non adjacents, chemin répétitif de 20 000 puis 40 000 unités) : 830,1 ms puis 3 939,3 ms (la note de la Phase 75 relevait 855,0 puis 3 444,6 ms : même classe, quadratique).

## Tâche 2 — ancres des mutants (texte entier de chaque ligne, une seule occurrence dans son fichier) et état après la tâche

Module `lib/vf-glob.mjs` (commit ad29ec96) :
- (a) point : `else if (t === ANY) ok = u !== 10 && u !== 13 && u !== 0x2028 && u !== 0x2029;`
- (b) bras d'une alternative : `const bras = n.a.map((b) => bati(b, suite));`
- (c) quantificateur facultatif : `if (n.k === 'opt') return etat(SPL, 0, bati(n.n, suite), suite);`
- (d) test d'une classe : `const v = RE[idx].test(String.fromCharCode(u)) ? 1 : 2;`
- (e) alternative de niveau supérieur : `if (prof === 0 && bras.length > 1) ctx.inerte = true;` (suivie d'un commentaire)
- (f) budget de pas : `if (nE * (L + 1) > MAX_PAS) return false;` (suivie d'un commentaire)
- (g) coercition de l'entrée : `` const s = `${chemin}`; ``

`lib/common.mjs` :
- M-MOTIF : `if (g.length > MAX_MOTIF) {` (suivie d'un commentaire)
- M-SPEC : `return { glob, specificity: premier, test: automateDe(` (début de la ligne de retour du cas à jokers)

Après la tâche 2 : suite de confinement 89 PASS / 0 FAIL (66 d'avant + 23 GLOB) ; vendor 87 PASS, git-env 135 PASS (E6, E8.1, E8.4 intacts), sante verte, assemblage 53 PASS. `common.mjs` 283 lignes, `vf-glob.mjs` 116 lignes, aucune ligne de 151 octets ou plus dans le module neuf. Constantes : MAX_MOTIF = 1024, MAX_PAS = 4194304. Rejeu de la mesure de la Phase 75 après : 4,9 ms puis 6,0 ms (avant : 830,1 ms puis 3 939,3 ms).

Un rouge neuf attrapé sous charge (suites voisines en parallèle) : GLOB.P3 rougissait avec un rapport quadratique de 2,29 sur une série perturbée (le banc exigeait toutes les séries à 3,2 ou plus). Corrigé dans le banc, jamais dans un seuil de produit : une série sans bruit suffit à prouver que la procédure voit la croissance (commit f7bbb21b) ; P1 et P2 inchangés. Même commit : l'avis d'une ligne de compileGlob sortait dans la sortie lue de C3 (stderr fusionné) ; les cas C0, C1, C3 et C4 ne lisent plus stderr.

## Tâche 3 — mutants, coût ordinaire, pire cas

Graine 79210101, 4 000 motifs (2 000 pour l'alternative de niveau supérieur). Chaque mutant : copie fraîche du dossier lib, une occurrence remplacée, preuve visée rejouée contre la copie.

| mutant | identifiant rougi | attendu | obtenu (cause) |
|---|---|---|---|
| M-POINT | E1 | identique | motif `[!a]`, chemin à fin de ligne : verdict attendu false, obtenu true (verdict) |
| M-ALT | E1 | identique | motif à accolades `c**{a,b}**{*,**},\|` : attendu true, obtenu false (verdict) |
| M-OPT | E1 | identique | motif à joker facultatif (double joker suivi d'une barre) : attendu true, obtenu false (verdict) ; voir l'écart ci-dessous |
| M-CLASSE | E1 | identique | motif à classe `[abc][abc]?[a-c]b{*,**}/` : attendu true, obtenu false (verdict) |
| M-HAUT | E3b | identique | `a[{/*.js,/` et chemin vide : attendu false, obtenu true (verdict) |
| M-PAS | C1 | ok | « échec : verdict true en 156,6 ms » (verdict) |
| M-MOTIF | C2 | ok | « échec : levée SyntaxError » (le motif géant est traduit) |
| M-SPEC | E1 | identique | champ specificity : attendu 1, obtenu 2 (champ) |
| M-COERCITION | E2 | identique | entrée undefined : attendu true, obtenu levée TypeError (verdict) |
| M-RETOUR | P1.F1 et P1.F5 (et P2) | ok | F1 rouge t1=84,3 ms t2=489,4 ms rapport 5,81 ; F5 rouge t1=44,2 ms t2=589,0 ms rapport 13,32 (rapport) ; jamais une exception ni un défaut de forme |

Écart d'exécution (M-OPT) : le plan voulait « facultatif devenu itératif ». Sur la seule construction que la traduction émet avec un `?` (la barre finale d'un double joker, groupe suivi de `?`), le facultatif et l'itératif décrivent le même langage (toute concaténation de tels groupes est elle-même un tel groupe) : le mutant est équivalent, aucune preuve ne peut le voir (constaté : 4 000 motifs, « identique »). Le mutant retenu est « facultatif devenu obligatoire » (zéro occurrence refusée), qui rougit E1 ; amendement daté dans le plan.

Coût ordinaire (sept motifs ordinaires, cinq chemins ordinaires, 40 000 tours chacun, sans seuil en CI), en ns/appel :
- ns/appel avant (copie gelée) : 171, 341, 55, 171, 70, 219, 41
- ns/appel après (automate) : 1 121, 2 208, 115, 460, 2 176, 1 977, 16 (le dernier motif, sans joker, garde sa branche d'origine)
- médiane des rapports après/avant : 6,5 (sous le seuil de 10 : pas d'optimisation de la boucle chaude demandée)

Pire cas du budget : motif de 1 024 caractères, état maximal (jokers récursifs répétés), chemin au bord du budget : 17,6 ms par appel au plus (le plan annonçait une centaine de millisecondes). Limite nommée : coût résiduel borné par appel, linéaire en le nombre de fichiers (T-79-2106).

## État final

Suite de confinement : 108 PASS / 0 FAIL (graine 79210101) ; 19 assertions de mutants, toutes vertes. E0 à E3c, P0, P3, P1.F1 à F5, P2.F1 à F5, C0 à C4 : tous verts après la tâche 2 ; rouges voulus sur la base : E3b, P1, P2, C0 à C3.

## Correction ciblée — mémoire à la compilation (audit du manager)

Témoin rouge avant (code d'avant la correction, sonde GLOB.MEM sur l'état du commit de la tâche 2) : forme à classes identiques 208 puis 136 Kio par motif (N puis 2N motifs), plafond 40 : rouge. Après : 13 puis 8 Kio ; forme à classes toutes différentes 2 puis 16 Kio : vert. Sonde de l'auditeur (1 021 caractères de classes denses) : avant 208 Kio par motif, après 13 Kio, ancienne implémentation 4 Kio.
Mutant M-DEDUP (ancre : la ligne qui cherche le corps de classe dans la table des corps déjà vus ; remplacement : indice neuf à chaque occurrence) : GLOB.MEM rougit, obtenu forme 0 : 66 puis 60 Kio par motif, forme 1 : 22 puis 38 (cause : mémoire).
Équivalence intacte : suite GLOB (E0 à E3c, C0 à C4) verte, sonde d'équivalence de l'auditeur sur trois graines (environ 313 000 vérifications chacune, 0 écart de verdict, de constructeur ou de specificity).
