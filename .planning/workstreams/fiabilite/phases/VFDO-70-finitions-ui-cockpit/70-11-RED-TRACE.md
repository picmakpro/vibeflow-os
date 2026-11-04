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
