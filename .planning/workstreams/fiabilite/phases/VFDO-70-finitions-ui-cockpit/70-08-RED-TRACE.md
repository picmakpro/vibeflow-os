# 70-08 — trace rouge/vert de la visite propre à l'onglet Projet (UIFN-05)

Régime P70-D-08 (arbitrage Samuel, AskUserQuestion, session principale, 2026-11-03) : témoins rouges avant le code, verts après.

## Rouge — 2026-11-04, tête 644bd884 + section O6 non commitée

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` — 80 PASS / 6 FAIL, tous les FAIL dans O6, aucune régression P1 à P7, O4, O5.

Le champ `tour` du graphe Projet est une liste vide (`tour: []`) : la visite retombe sur le repli du moteur (cartes de premier niveau, 3 étapes dans Chrome).

| Assertion | Attendu | Obtenu |
|-----------|---------|--------|
| O6.1 visite d'au moins deux étapes, quatre sur un lab complet | `true\|4` | `false\|0` |
| O6.4 lab sans STATE.md : visite d'au moins deux étapes, sans « ? » | `0\|true` | `0\|false` |
| O6.6 ordre des étapes (jalon, phase 2, mission, au travail) | `n:ms-v1.0-mvp n:ph-2 n:dag-MISSION-ECRAN root+#vf-lock` | (vide) |
| O6.7 statut lisible, « 1 sur 2 », onglet Équipe nommé | `true,true,true` | (vide) |
| O6.5a Chrome : quatre étapes à 1 440 et 390 px | `\|4,4` | `\|3,3` |
| O6.5b Chrome : première étape = jalon, dernière = au travail | `4\|true\|true\|0` | `3\|false\|false\|0` |

O6.2, O6.3, O6.8 et O6.5c à O6.5g sont verts avant le code : vides sur une visite vide (O6.2, O6.3), ou mesures du repli (O6.5c-g). Ils protègent les non-régressions une fois la visite posée.

## Vert — 2026-11-04, tête b83df5c9

- `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh` : 86 PASS / 0 FAIL (O6.1 à O6.8 verts, O4 et O5 non sautés).
- `test-cockpit-chrome-fr.sh` : 0 FAIL ; `test-cockpit-questions.sh` : 65 PASS / 0 FAIL ; `test-cockpit-avancement.sh` : 61 PASS / 0 FAIL.

Écart relevé en cours de route (non corrigé, hors périmètre) : sur un profil Chrome qui a déjà chargé la page, le centrage de la première étape, quand c'est une carte, dérive (étape 1 à 390 px, `centre` faux, x décalé de ~85 px) ; sur un profil neuf il est juste. Reproduit avec `chrome-visite-etapes.mjs` en `390,390` et `390,1440` sur `project.html`. La suite mesure donc chaque largeur dans un Chrome neuf (O6.5).
