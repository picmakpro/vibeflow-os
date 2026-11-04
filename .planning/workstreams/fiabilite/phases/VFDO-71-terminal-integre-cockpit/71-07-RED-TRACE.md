# 71-07 — trace du rouge du tiroir

## Contrôle d'entrée

- date : 2026-11-03 ; base : HEAD `fcfa4520`
- ligne de décision (`71-CONTEXT.md` l.113), mot pour mot : « **P71-D-20 (O1 → option B ; décision du manager, vf-dev-manager, 2026-11-03).** Le tiroir est servi à la volée, SEULEMENT avec `--terminal`, depuis `scripts/vf-cockpit-terminal-tiroir*.mjs`, et non par un `assets/ui/9x-vf-terminal.js` inliné. »
- option retenue : **B** (le plan continue tel qu'écrit ; aucun fichier sous `assets/ui/`)
- ligne de `71-06-SUMMARY.md` qui rapporte T9.7 : « Rouge puis vert : T6.1, T6.1b, T6.2, T6.3, T6.4, T6.6, T6.7, T9.5, T9.7, T14.S1-S4, T17.Q1-Q4 … » (suite client : 35 PASS / 0 FAIL)
- mesure O8 retenue (71-06-SUMMARY) : `MESURE-O8 minimal=bloque popups=ouvert opener=nul` ; décision du manager : cinq jetons `allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox`, aucun autre
- porte rejouée avec sortie non nulle sur échec (remarque du plan-checker) : le script de vérification se termine par `process.exit(1)` sur `ENTREE-NON-TENUE`

## Rouge du tiroir (tâche 1)

- date : 2026-11-03
- empreinte du commit de tests : `93b5f595` (`test(71-07): témoins rouges du tiroir …`)
- base : HEAD `d4222468` ; `injectionTiroir()` = amorce vide de 71-01 (`''`), `accepteMessage` et `LISTE_MESSAGES` absents ; Chrome 156 headless (macOS), `VF_TIROIR_MS` par défaut (20 s)
- commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh > 71-07-t1.out 2>&1` — rc=1, `Résultats : 4 PASS / 30 FAIL`
- verts sur la base (témoins) : TU.13 (aucune adresse : script vide, puis rouge par TU.13.0/TU.13b qui exigent un script vivant), TU.1 sur `/` et `/project.html` (absence vraie, page chargée et vivante), H0 (hygiène)
- écart au plan : TU.12, T17.2, T17.3 et T17.6 sont rouges sur la base au lieu de vertes, parce que chacune porte un garde de vivacité (nœuds sous /project.html, tiroir ouvert avant, script non vide) : une absence ne passe jamais vert à vide. Les mutants M-MSG-* sont "sans effet" sur la base (cible absente), rouges ici par construction ; leur preuve de rougissement vient avec le code.

## Témoins rouges (attendu, obtenu)

### FAIL — TU.13.0 — témoin : le script injecté existe (taille > 500), sa première ligne est l'en-tête VibeFlow (71-07), il vient avec sa feuille
- attendu : `[true/// VibeFlow (71-07) : tiroir du terminal/true]`
- obtenu : `[false//false]`

### FAIL — TU.13b — un seul fetch( et il vise /api/vf/terminal ; aucun cookie ; seules clés de stockage : vf.terminal.h et vf.terminal.open
- attendu : `[true/1/true/0/vf.terminal.h,vf.terminal.open]`
- obtenu : `[false/0/false/0/]`

### FAIL — T17.6 — aucun postMessage( dans le script injecté (le sens P vers le cadre est fermé), aucun attribut allow posé, Échap jamais cité (le script est vivant)
- attendu : `[true/0/0/0]`
- obtenu : `[false/0/0/0]`

### FAIL — T17.4 — accepté seulement : isTrusted, origine de Q exacte, source = le cadre, valeur de la liste ; refusés : origine de P ou voisine, autre source ou nulle, valeur inconnue, objet, tableau, 10 000 caractères, non fiable ou confiance absente
- attendu : `[accepte=oui accepte-ready=oui origine-de-P=non origine-voisine=non source-autre=non source-nulle=non valeur-inconnue=non objet=non tableau=non chaine-10000=non non-fiable=non confiance-absente=non]`
- obtenu : `[ABSENT]`

### FAIL — T17.4b — LISTE_MESSAGES : exactement les huit valeurs de l'UI-SPEC §13
- attendu : `[liste=etat:arrete,etat:connecte,etat:expire,etat:reconnexion,etat:refuse,etat:termine,ready,toggle]`
- obtenu : `[]`

### FAIL — M-MSG-ORIGINE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-MSG-SOURCE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-MSG-LISTE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-MSG-CONFIANCE — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — TU.0 — témoin : le scénario n'a pas échoué (aucune étape en erreur)
- attendu : `[{}]`
- obtenu : `[{"P":"attente de « pastille Terminal » dépassée (20000 ms)"}]`

### FAIL — TU.2 — pastille « Terminal » unique, aria-label et titre « Ouvrir le terminal (Ctrl+Maj+Espace) », aucun cadre, aucun shell (/etat absente)
- attendu : `[n=1 texte=Terminal aria=Ouvrir le terminal (Ctrl+Maj+Espace) titre=Ouvrir le terminal (Ctrl+Maj+Espace) iframes=0 etat=absente]`
- obtenu : `[]`

### FAIL — TU.3 — ouverture : un cadre d'origine Q en ?theme=dark, title « Terminal », sandbox de la mesure O8 (cinq jetons), aucun attribut allow, région « Terminal », barre « Connecté », shell vivant
- attendu : `[n=1 src=http://127.0.0.1:58892/?theme=dark title=Terminal sandbox=allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow=false region=region/Terminal barre=Connecté etat=vivante]`
- obtenu : `[]`

### FAIL — T8.2 — tiroir ouvert : 0 violation de CSP dans P, ready puis etat:connecte reçus
- attendu : `[violations=0 ready=true connecte=true]`
- obtenu : `[]`

### FAIL — TU.4 — temps 1 : le raccourci ouvre (annonce « Terminal ouvert »), le focus est au cadre ; temps 2 : focus ailleurs dans P, le raccourci rend le focus au cadre sans fermer
- attendu : `[Terminal ouvert / ouvert=true actif=IFRAME]`
- obtenu : `[]`

### FAIL — TU.4 — temps 3 : dans le terminal, le raccourci ferme (message toggle de Q), annonce « Terminal fermé », tiroir inerte, focus rendu à l'ouvreur
- attendu : `[ferme=true focus=ouvreur toggle=true annonce=Terminal fermé inert=true]`
- obtenu : `[]`

### FAIL — TU.4b — ouvrir, fermer, ouvrir : un seul cadre, le même shell (PID du shell inchangé)
- attendu : `[1/meme-shell]`
- obtenu : `[]`

### FAIL — TU.5 — poignée au clavier : 320 px par défaut, deux flèches haut = +48 px, aria-valuenow suit, mémorisés (vf.terminal.h/open) ; rechargement : même hauteur, tiroir rouvert, même PID de shell
- attendu : `[h0=320 h1=368 now=368 stock=368/1 apres=368/1 shell=identique]`
- obtenu : `[]`

### FAIL — TU.6 — Agrandir : aria-pressed vrai et libellé « Réduire le terminal », tiroir plus haut ; second clic : retour à la hauteur d'avant
- attendu : `[pressed=true aria=Réduire le terminal plus_haut=true retour=false/368]`
- obtenu : `[]`

### FAIL — TU.7 — glissement souris de 80 px vers le haut : cadre en pointer-events none et body.resizing pendant le geste, rendus après ; hauteur 368 + 80
- attendu : `[pendant=none/true apres=auto/false h=448]`
- obtenu : `[]`

### FAIL — TU.8 — bascule de thème : l'adresse du cadre passe à ?theme=light, history.length inchangé, même PID de shell (P71-D-19)
- attendu : `[url=Q/?theme=light histoire=inchangee pid=identique]`
- obtenu : `[]`

### FAIL — T17.1 — témoin : les vrais messages de Q agissent (toggle reçu : le tiroir s'est fermé ; etat:connecte : la barre dit « Connecté »)
- attendu : `[toggle=true ferme=true barre=Connecté]`
- obtenu : `[]`

### FAIL — T17.2 — postMessage('toggle') émis par P vers elle-même : ignoré (tiroir ouvert avant et après)
- attendu : `[avant=true apres=true]`
- obtenu : `[]`

### FAIL — T17.3 — MessageEvent forgé (origine de Q, source = le cadre) : ignoré, car non fiable (tiroir ouvert avant et après)
- attendu : `[avant=true apres=true]`
- obtenu : `[]`

### FAIL — T17.5 — espion : après une commande tapée dans le shell, tout message d'origine Q est dans la liste fermée ; ni le marqueur, ni le secret, ni l'amorçage n'y figurent (témoin : la commande a tourné)
- attendu : `[fichier=true hors_liste=0 marqueur=0 secret=0 amorce=0 ready_et_connecte=true]`
- obtenu : `[]`

### FAIL — TU.9 — P ouvert par localhost : le message d'O6 (P71-D-21) dans une puce, ni pastille ni cadre
- attendu : `[hote=localhost puce=Ouvrez le cockpit à l'adresse 127.0.0.1 pour utiliser le terminal. pastilles=0 iframes=0]`
- obtenu : `[hote=localhost puce= pastilles=0 iframes=0]`

### FAIL — TU.10 — Windows (indisponible) : puce « Terminal indisponible sous Windows. » en role status, ni pastille ni cadre
- attendu : `[puce=Terminal indisponible sous Windows. role=status pastilles=0 iframes=0]`
- obtenu : `[puce= role= pastilles=0 iframes=0]`

### FAIL — TU.12 — la même injection : des nœuds sous /project.html (témoin), aucun nœud, aucune clé et aucun cadre sous /autre.html
- attendu : `[projet_noeuds>0=true/vivante=true noeuds=0 cles=0 iframes=0]`
- obtenu : `[projet_noeuds>0=false/vivante=true noeuds=0 cles=0 iframes=0]`

### FAIL — TU.11 — aucun ready : après 8 s, carte « Le terminal ne répond pas. Relancez /vf-cockpit --terminal. »
- attendu : `[carte=Le terminal ne répond pas. Relancez /vf-cockpit --terminal. ready=false]`
- obtenu : `[carte= ready=false]`

### FAIL — T8.3 / M-FRAMESRC — copie de sortie sans frame-src : une violation de CSP relevée, aucun ready reçu
- attendu : `[violation=true ready=false]`
- obtenu : `[violation=false ready=false]`

### FAIL — M-MSG-DONNEE — le mutant rougit T17.5 : un message hors liste ou portant le marqueur arrive à P (témoin : la commande a tourné)
- attendu : `[fichier=true rouge=true]`
- obtenu : `[]`
