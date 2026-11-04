# 70-11 — traces du rouge (UIFN-12, UIFN-13)

Rejeu : `bash plugin/cockpit/scripts/tests/test-cockpit-equipe.sh > "$TMPDIR/70-11.out" 2>&1` et `bash plugin/cockpit/scripts/tests/test-cockpit-who.sh > "$TMPDIR/70-11-who.out" 2>&1`
(un Chromium headless par interaction, socle `chrome-session.mjs`). Les mutants d'EK sont posés dans la page RÉELLEMENT servie : la copie assemblée
`project.html` de la sortie du cockpit du lab jetable, que `serve.mjs` lit à son démarrage ; le serveur est relancé à chaque mutant, la page restaurée
ensuite (témoin EK6 : octet pour octet identique). Chaque ancre est unique dans la page assemblée (comptée 1 fois).

## EK1 — focus après Entrée sur « Lire le transcript » (UIFN-12)

Rouge sur 794c6dba (code de production de `72-vf-equipe.js` inchangé), commit de test `2f19b1d9` :

- témoin EK1.0 : avant l'Entrée, élément actif = `BUTTON`, `data-vf-transcript="a1"` (PASS : la sonde lit le focus) ;
- assertion EK1 : après Entrée au clavier (touche réelle, CDP `Input.dispatchKeyEvent`), le transcript s'affiche ET l'élément actif reste dans le tiroir ;
- attendu : `lu=true | actif=dans le tiroir` ; obtenu : `lu=false | actif=BODY`.

Cause : DEUX défauts en série, chacun prouvé par un mutant du code corrigé (jamais par un grep) :

1. `72-vf-equipe.js:122` (794c6dba), `b.disabled = true` sur le bouton focalisé : un bouton focalisé qui devient désactivé perd le focus.
   Mutant EK1.3 (`aria-disabled` remis en `disabled`) : attendu `muté|lu=true | actif=BODY`, obtenu identique (le transcript est lu, le focus est perdu ; relevé `["BODY", disabled=true, actif===bouton=false, bouton dans le document=true]`).
2. Le raccourci global du viewer (`window` `keydown`, Entrée avec un nœud sélectionné : « ouvrir le nœud ») reçoit l'Entrée du bouton ; il redessine le panneau
   avant le clic. Le bouton d'origine quitte le document, le clic n'a pas lieu, le transcript n'est pas lu.
   Mutant EK1.2 (l'arrêt de l'évènement au document retiré) : attendu `muté|lu=false | actif=BODY`, obtenu identique.

Pas de redessin de `70-vf-live.js:78` en cause (aucun `who` ne survient pendant la mesure : relevé de la page, un `who` et une mutation à ~116 ms du chargement, rien pendant les 6 s suivantes) : `70-vf-live.js` n'est pas touché, la condition d'arrêt du plan ne s'applique pas.

Correctif : un gestionnaire `keydown` du document, limité aux boutons `[data-vf-transcript]` et `[data-vf-doing]` du panneau, arrête l'Entrée avant `window` ;
`aria-disabled="true"` plus une garde « lecture en cours » remplacent `disabled`. Vert : relevé `["BUTTON", false, true, true]`, `lu=true | actif=dans le tiroir`.

Leçon de méthode (faux vert évité) : une première ancre `ev.stopPropagation();` visait la première occurrence dans la page, qui est celle du viewer, pas celle de `72-vf-equipe.js` ;
le mutant « muté » restait vert (`lu=true | actif=BUTTON`). L'ancre retenue (EK1.2) cite la condition de `72-vf-equipe.js`.

## Mutants des mineurs de la 69 (UIFN-13)

Pour chacun : ligne mutée, assertion, attendu (code réel), obtenu (mutant).

| Témoin | Mineur | Ligne mutée (page servie) | Assertion | Attendu, code réel | Obtenu, mutant |
|---|---|---|---|---|---|
| EK2.1 / EK2.2 | m1 | `72-vf-equipe.js:88` `lu = null; marque(null); return;` devient `lu = null; return;` | clé `vf-equipe-ouvert` avant|après le changement d'agent | `a1|null` | `a1|a1` |
| EK3.1 / EK3.2 | m10 | `72-vf-equipe.js:77` `sessionStorage.setItem(CLE_OUVERT, id);` écrit aussi le texte lu | fuite|texte lu | `{"vf-equipe-ouvert":"a1"}|true|false` (entrées|texte lu|fuite) | `true|true` (fuite|texte lu) |
| EK4.1 / EK4.2 | m8 | `70-vf-live.js:73` la garde `if (!document.querySelector('.vf-whop') || ...contains('no-panel')) return;` devient `if (false) return;` | ouvert|fermé|rouvert après un `who` qui change l'arbre | `true|true|false` | `true|true|true` |
| EK5.1 / EK5.2 | m5 | `70-vf-live.js:89` (pose de la commande) `z.textContent = t` remplacé par `z.innerHTML = t` (condition d'arrêt adaptée : l'observateur de la page bouclerait sinon) | éléments créés|`#ek-injecte` présent | `0|false|true` (texte lisible) | `1|true` |
| W19.1 / W19.2 | m6 | `vf-cockpit-who.mjs:82` `WS_RE.test(ws) && !ws.includes('..')` devient `WS_RE.test(ws)` | occurrences de `--ws=a..b` dans le journal du faux `driver-lock.sh` | `0` | `1` |

EK5 : le serveur ne rend jamais de balisage (la commande est résumée au verbe et à la cible, jeu de caractères sans `<`) ; la réponse de `/api/vf/doing` est donc remplacée dans la page par `{"doing":"<b id=ek-injecte>gras</b>"}` pour prouver LE RENDU de la page.
W19 est un témoin de comportement (la cible `a..b` passe la forme alphanumérique de `WS_RE` : seule la clause `..` l'écarte) et non une ancre de texte.
EK6 : la page restaurée après les mutants redonne le vert et reste identique octet pour octet à l'originale ; EK7 : un mutant à ancre absente est refusé (jamais un mutant vide).

## Suite : bouton du tiroir Au travail (EK8, UIFN-12, bouton voisin)

Même classe de défaut sur « Voir la dernière commande » du tiroir « Au travail » (`70-vf-live.js`, `b.disabled = true`). Témoin EK8 (action `focus-doing-tiroir` de `chrome-equipe-clavier.mjs`) : tiroir ouvert par le badge, bouton focalisé, Entrée réelle (CDP), attente de la commande, relevé de l'élément actif.

Rouge sur 8de3fdd2 (`70-vf-live.js` inchangé) :
- témoin EK8.0 : avant l'Entrée, élément actif = `BUTTON` portant `data-vf-doing` (PASS : la sonde lit le focus) ;
- assertion EK8 : la commande s'affiche ET l'élément actif reste le bouton ; attendu : `lu=true | actif=bouton « dernière commande »` ; obtenu : `lu=true | actif=BODY`.

Cause réelle (vérifiée, non présumée) : UN seul défaut ici, `disabled`. Le raccourci global du viewer n'est pas en cause sur ce bouton : le gestionnaire `keydown` du document de `72-vf-equipe.js` (sélecteur `#panel [data-vf-transcript], #panel [data-vf-doing]`) couvre déjà ce bouton, la commande est lue (`lu=true`) ; `72-vf-equipe.js` n'est pas touché.
Première version du témoin faussement verte : une réponse simulée immédiate rétablit le bouton avant tout recalcul de focus ; la réponse est donc retardée de 150 ms (ordre de grandeur du réseau réel).

Correctif : `aria-disabled="true"` plus garde « lecture en cours » à la place de `disabled`, retrait de l'attribut à la fin (y compris sur les boutons redessinés du même identifiant). Vert : `test-cockpit-equipe.sh` 134 PASS / 0 FAIL.

Mutant EK8.1 (page servie : le bouton redevient `disabled = true`) : attendu `muté|lu=true | actif=BODY`, obtenu identique.
Faux vert évité, deuxième fois : l'ancre de EK1.3 (`b.setAttribute('aria-disabled', 'true');`) existe désormais dans les DEUX fichiers ; le mutant visait le premier, celui de `70-vf-live.js`, et EK1.3 rougissait. Les ancres de EK1.3 et EK8.1 citent le commentaire propre à chaque fichier, et `ek-sub.mjs` refuse désormais une ancre présente plusieurs fois (« ancre ambiguë »).

## Suite : recette (juge Playwright frais, correction ciblée du manager)

Base : cf6983ac. Commande de rejeu : `bash plugin/cockpit/scripts/tests/test-cockpit-equipe.sh` (EK8 à EK12, mutants r1 à r5).

### 1. Focus perdu à chaque redessin (UIFN-12) — EK8 (panneau d'agent), EK9 (tiroir « Au travail »)

Le témoin précédent ne voyait pas le cas : aucun `who` n'arrivait pendant la mesure. Désormais un `who` est livré pendant que le bouton a le focus
(Chromium avec `Emulation.setFocusEmulationEnabled` : sans lui, une page headless n'a pas le focus de fenêtre et `focusin` / `focusout` ne partent pas).

- témoins EK8.0 / EK9.0 : le bouton avait le focus ET le redessin l'a remplacé (`true|true`) ;
- rouge (code de cf6983ac, relevé du run avant correctif) : attendu `le bouton`, obtenu `BODY` pour EK8 et pour EK9 ;
- correctif (`70-vf-live.js`) : retient la clé du bouton `data-vf-doing` / `data-vf-transcript` qui a le focus (`focusin`, effacée par un `focusout` d'un bouton resté dans la page) ; l'observateur du panneau la rend au bouton de même clé si le focus est tombé sur le corps de la page ;
- mutants sur la page servie (observateur sans `rendreFocus()`) : EK8.2 et EK9.2 attendu `muté|BODY`, obtenu identique.

Effet de bord sur EK1.2 : l'arrêt de l'Entrée au document (`72-vf-equipe.js`) n'est plus observable par le focus (le focus est rendu) ; son témoin devient la vue du viewer :
sur un manager qui porte des agents, sans l'arrêt, Entrée fait descendre le viewer dans le nœud (fragment `v=` change). EK1.1 (code réel) : `lu=true | actif=BUTTON | vue inchangée` ; EK1.2 (mutant) : `lu=true | actif=BUTTON | vue changée`.

### 2. Badge d'état rogné par un pied long — EK10

Cause : les règles du pied (`.foot .meta` min-width 0 / overflow hidden / ellipsis, `.foot .vst` flex none) n'étaient posées que pour l'onglet Projet ; l'onglet Équipe n'avait que le `nowrap` du viewer. Posées pour tout onglet sauf Code (`00-vibeflow.js`).

- fixture : un agent `a3` dont le pied est « actif · 2 min · lance un agent general-purpose » ;
- rouge (cf6983ac) : marge bord droit de la carte moins bord droit du badge, attendu `>= 0` à 390, 1024 et 1440 px, obtenu `390=-32, 1024=-50, 1440=-50` ;
- vert : `ok,ok,ok` ;
- mutant EK10.2 (règle retirée de la page servie) : attendu `muté|rogné`, obtenu identique.

### 4. Anglais restant (P70-D-04) — EK11, EK12

- EK11 : la ligne des sources du tiroir affichait « sessions : lue · locks : lue · dags : lue » ; elle dit « Sessions et sous-agents », « Verrous du dépôt », « Plans de la mission ». Mutant EK11.2 (clés brutes) : attendu `muté|anglais`, obtenu identique ;
- EK12 : l'infobulle du bouton de recherche de l'onglet Équipe valait « Chercher un fichier, une route, un module » ; elle vaut maintenant son libellé. Mutant EK12.2 : attendu `muté|Chercher un fichier, une route, un module`, obtenu identique.

### 3 et 5 : réglages visuels, sans test neuf

3. `.vf-who button` : survol et anneau `--ring` 2 px (DESIGN.md §9) comme les boutons de `.sec`. 5. `--n-terminés` définie sur le jeton « fait » `--st-done` (DESIGN.md §9, tableau des statuts) pour l'onglet Équipe.

### Rejeux

`test-cockpit-equipe.sh` 147 PASS / 0 FAIL ; `test-cockpit-marque-blanche.sh` 30/0 ; `test-cockpit-chrome-fr.sh` 70/0 ; `test-cockpit-transcript.sh` 99/0 ; `test-cockpit-who.sh` 90/0 ;
`test-cockpit-responsive.sh` 255 PASS / 6 FAIL, les six étant R13.4 (1024 et 1440 px, trois onglets).

## Suite : tri de goût (arbitrage Samuel, AskUserQuestion session principale, 2026-11-04, « Tout selon les recos (Recommandé) » ; consigné P70-D-23 par le manager)

Base : b0182676. Rejeu : `bash plugin/cockpit/scripts/tests/test-cockpit-equipe.sh`.

### Q2a — « écrit à <rôle> », jamais un identifiant (E32)

Rouge sur les scripts de b0182676 (suite neuve rejouée contre `git archive` de la tête) :
- E32.1 rôle connu : attendu `écrit à|vf-reviewer`, obtenu `écrit à|w-cible` (identifiant brut) ;
- E32.2 rôle inconnu : attendu `écrit à|un agent`, obtenu `écrit à|destinataire-ABSENT-32` ;
- E32.3 aucun identifiant ni champ interne `_to` dans la sortie : attendu `0`, obtenu un décompte non nul.

Correctif : `etiquette(name, input, root, roles)` rend « un agent » sans table de rôles ; `derniereAction` garde le destinataire brut dans un champ interne `_to` ; `vf-cockpit-who.mjs` le résout en rôle d'après la COLLECTE (meta.json des sous-agents de la même collecte, jamais le texte de l'entrée), puis retire `_to`. Même table passée au transcript lu à la demande (liste des outils). Reste dans la liste blanche : aucune donnée hors cible.
Vert : E32.0 à E32.3. Un oubli de passage du paramètre `roles` jusqu'à `reduire()` (exception avalée, mandat vide) a été détecté par T24 de `test-cockpit-transcript.sh` et corrigé.

### Q3b — échelle du premier affichage plafonnée à 0,75 (EK13)

La fixture EK compte maintenant sept sessions racines en plus (scène assez large pour que l'ajustement réduise). `72-vf-equipe.js` `arrivee()` : si `SC.fit` laisse une échelle sous 0,75, la scène est cadrée sur la première carte (coin haut gauche de la zone libre, sous l'en-tête et le titre) à 0,75.
- témoin EK13.0 : au moins une carte à 390 et 768 px ;
- EK13 : échelle ≥ 0,75 ET recouvrement titre / première carte = 0 px² à 390 et 768 px ;
- rouge : mutant EK13.2 (plafond retiré de la page servie) attendu `muté|réduit`, obtenu identique (l'ajustement seul réduit la scène sous 0,75) ; défaut E (recouvrement) toujours couvert par la même assertion.
Dépendance R19 / R20 (suite responsive, non touchée et non rejouée) : le cadrage s'appuie sur `SC.freeArea()` (sous l'en-tête et le titre) donc le recouvrement reste nul ; R20 (superpositions, défilement horizontal) à rejouer par l'exécutant de la suite responsive.

### Q12a — alignement des liens (réglage visuel, sans test)

`70-vf-live.js` : `.vf-who > a.vf-link, body.vf-tab-equipe .sec > a.vf-link` sans padding horizontal ; la liste « Sources lues » (00-vibeflow.js) garde le sien.
