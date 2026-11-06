# 72-08 — trace du rouge (bandeau de proposition de la page Q)

Plan 72-08 (Phase 72, LANC-07 et LANC-09). Cette trace garde, pour chaque famille de sondes, l'assertion jouée, l'attendu et l'obtenu sur la BASE
(vue et client d'avant ce plan), puis, plus bas, les mutants rejoués sur le code livré.

- Commande : `VF_LB_PORTS=4840-4859 bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bandeau.sh` (Chrome local, bash 3.2 du poste)
- HEAD de la base : `9f177f36` (vue 125 lignes, client 239 lignes, aucune méthode `proposition`, aucune entrée `proposition` dans `MESSAGES`)
- Résumé sur la base : rc=1, 10 PASS / 45 FAIL. Verts sur la base (attendus) : LB.S0, les quatre LB.S1, LB.S3, les deux LB.S4, LB.P, H0 (hygiène).
  Rouges : LB.S2, LB.C1 à LB.C7 (14 assertions), LB.V1 à LB.V8, LB.E1 à LB.E8, les quatorze mutants (« mutant sans effet : marqueur absent »).
- Un rouge pour la bonne raison : chaque rouge de famille C nomme l'attente qui échoue (« affichage de <id> dépassée », « sondage avant visible() dépassée »), jamais un
  plantage du harnais ; les familles V et E nomment l'étape (`vfTermVue.proposition is not a function`, `bandeau de proposition dépassée`). Les sondes négatives
  (V3, V4, C5, E2, E3, E4, E7) portent leur témoin positif dans la même chaîne attendue (le bandeau s'affiche, le lancement armé part, `vu` vrai) : elles ne sont pas vertes à vide.

## baseline LB.S1 (mesurée sur la base, verte avant ce plan)

| mesure | valeur |
|--------|--------|
| `location.search` / `URLSearchParams` / `searchParams` / `location.href` | 2 / 0 / 0 / 0 |
| écouteurs de messages entrants / `postMessage(` / `postMessage` avec l'étoile | 0 / 1 / 0 |
| écritures `innerHTML`, `outerHTML`, `insertAdjacentHTML` ; `confirm(` | 0 ; 0 |
| lignes de couleur `#xxx` vue / client | 6 / 0 |
| `.style` ; `cssText` (vue / client) | 0 / 0 ; 0 / 0 |
| `rgb(` ou `hsl(` vue / client | 3 / 0 |
| `<chiffre>px` vue / client | 0 / 1 |
| lignes vue / client | 125 / 239 |

## LB.S — statique

- sonde : LB.S2 « la table MESSAGES a exactement neuf clés dont `proposition` ; l'unique `postMessage(` vise `cfg.origineP` »
- attendu : `9/true/true`
- obtenu : `8/false/true` (huit clés, pas de `proposition`)

## LB.V — vue sous Chrome (Q factice dans un cadre sandbox de P factice)

- sonde : LB.V1 à LB.V8 (DOM, pré-vols, armement, clic de confiance, textes hostiles, collage au-dessus, statuts, retrait)
- attendu : les chaînes de résultat de la suite (par exemple LB.V3 `tôt/0/["default"]`, LB.V4 `0/1`, LB.V5 `true/true/0/undefined/0/false/0/0`)
- obtenu : `erreur: TypeError: vfTermVue.proposition is not a function` pour chacune des huit étapes (la méthode n'existe pas)

## LB.C — client sans navigateur (doublures Node, minuteur accéléré de 1/50)

- sonde : LB.C1 (sondage dès l'initialisation, période 500 à 2000 ms, une requête en vol) · attendu `sain` · obtenu `rouge` (aucune requête `/proposition`)
- sonde : LB.C2 (formes refusées, une fois par identifiant, aucune, sondage en retard) · attendu `sain` · obtenu `plante: attente de « sondages (null) » dépassée` : le client ne sonde pas
- sonde : LB.C3 (`POST /lancer` de corps `{id,mode}`, huit statuts, mode hors liste) · attendu `sain` · obtenu `plante: attente de « affichage de p21eee… » dépassée`
- sonde : LB.C4 (mode relu contre la liste fermée, retenu au seul 204) · attendu `sain` · obtenu `plante: attente de « affichage de … » dépassée`
- sonde : LB.C5 (aucun octet à `/entree` après le 204, focus repris) · attendu `sain` · obtenu `plante: attente de « affichage de a1b2c3… » dépassée`
- sonde : LB.C6 (`POST /annuler`, le bandeau ne revient pas) · attendu `sain` · obtenu `plante: attente de « affichage de a1b2c3… » dépassée`
- sonde : LB.C7 (cas froid : une annonce avant `visible()`, rien d'autre) · attendu `sain` · obtenu `plante: attente de « sondage avant visible() » dépassée`

## LB.E — client réel, serveur factice du contrat §4, faux P

- sonde : LB.E1 (bandeau en moins de 4 s, un message `proposition`) · attendu `true/1/true/true/true` · obtenu `erreur: attente de « bandeau de proposition » dépassée (4000 ms)`
- sonde : LB.E2 (clic avant armement sans POST, après armement UN POST `id,mode`, aucun octet au PTY) · attendu `true/0/1/id,mode/true/204/0/acceptEdits` · obtenu `erreur: élément introuvable : document.getElementById('proposition-lancer')`
- sonde : LB.E3 (409 puis second clic) · attendu `true/0/true/true/true/409,204` · obtenu : étape en erreur nommée (bandeau absent)
- sonde : LB.E4 (après usage, rechargement en thème clair, aucun bandeau) · attendu `true/0/light` · obtenu : étape en erreur (le témoin `vu` est faux : le bandeau ne s'affiche jamais)
- sonde : LB.E5 (`SecurityError` côté P, valeur forgée = `default`) · attendu `SecurityError/acceptEdits/default` · obtenu `erreur: attente de « bandeau de la proposition suivante » dépassée (5000 ms)`
- sonde : LB.E6 (paramètres d'adresse jamais lus) · attendu `default/0` · obtenu `erreur: attente de « bandeau après rechargement » dépassée (5000 ms)`
- sonde : LB.E7 (messages entrants de P sans effet) · attendu `true/0/0` · obtenu : étape en erreur (témoin `vu` faux)
- sonde : LB.E8 (cadre masqué : une annonce, ni `.xterm` ni bandeau, puis agrandi) · attendu `1/true/0/0/0/true|true|1` · obtenu `erreur: attente de « bandeau après agrandissement » dépassée (6000 ms)` (aucun message `proposition` n'est parti)

## mutants sur la base

Les quatorze mutants sont « sans effet : marqueur `garde:` absent » (le `sed` ne change rien, le harnais le dit en FAIL, 14 lignes « mutant sans effet ») :
M-ENTREE-AUTO, M-ARMEMENT-IGNORE, M-TEXTE-AU-SERVEUR, M-MODE-NON-RELU, M-MESSAGE-AVEC-DONNEES, M-MESSAGE-REPETE, M-USAGE-RESTE, M-AUCUNE-IGNOREE,
M-CLIC-NON-FIABLE, M-INNERHTML, M-PROP-AU-DESSUS, M-PARAM-URL, M-SONDAGE-APRES-VISIBLE, M-RETARD-REAFFICHE.

Commande de contrôle (jouée sous bash et sous zsh) : `OK-ROUGE-ATTENDU`.

## Mutants rejoués sur le code livré (vue)

Chaque mutant est joué sur une copie des sources ; l'assertion de la suite attend « rouge » (la sonde s'exécute, le bandeau s'affiche, et la valeur saine a disparu).

| mutant | sonde rougie | obtenu | tué |
|--------|--------------|--------|-----|
| M-ARMEMENT-IGNORE (`'true'` → `'false'` sur `garde:armement`) | LB.V3 | un clic avant l'armement appelle `cb.lancer` (avant ≠ 0) | oui |
| M-CLIC-NON-FIABLE (`ev.isTrusted !== true \|\|` retiré, `garde:clic-fiable`) | LB.V4 | un `click()` programmatique appelle `cb.lancer` (`1/1` au lieu de `0/1`) | oui |
| M-INNERHTML (`garde:texte` → `innerHTML`) | LB.V5 | l'intention hostile devient un nœud `img` | oui |
| M-USAGE-RESTE (`st === 'ok' \|\|` retiré, `garde:retrait-usage`) | LB.V7 | `ok=KO` : le bandeau reste après un lancement accepté | oui |
| M-PROP-AU-DESSUS (`garde:collage-dessus` → `appendChild`) | LB.V6 | l'élément au centre de « Coller » n'est plus dans `#collage` | oui |

## Mutants rejoués sur le code livré (client)

| mutant | sonde rougie | obtenu | tué |
|--------|--------------|--------|-----|
| M-ENTREE-AUTO (`garde:apres-usage`) | LB.C5 | un octet part à `/entree` après le 204 | oui |
| M-TEXTE-AU-SERVEUR (`garde:corps-lancer`) | LB.C3 | le corps n'est plus `{id,mode}` | oui |
| M-MODE-NON-RELU (`garde:mode-relu`) | LB.C4 | `bypassPermissions` devient la présélection | oui |
| M-MESSAGE-AVEC-DONNEES (`garde:emission`) | LB.C2 et LB.S2 | message `proposition:<id>` ; deux `postMessage(` | oui |
| M-MESSAGE-REPETE (`if (nouveau)` retiré) | LB.C2 | un message à chaque sondage | oui |
| M-AUCUNE-IGNOREE (`garde:aucune` supprimée) | LB.C2 | `vue.proposition(null)` jamais appelée | oui |
| M-PARAM-URL (`garde:mode-lecture`) | LB.S1 | `URLSearchParams` = 1 | oui |
| M-SONDAGE-APRES-VISIBLE (`garde:sondage-precoce` supprimée, `lire` déplacée dans `garde:pret`) | LB.C7 | aucun message pendant la phase masquée | oui |
| M-RETARD-REAFFICHE (`garde:fermee` supprimée) | LB.C2 | un sondage en retard remonte la proposition consommée | oui |

État final : suite 56 PASS / 0 FAIL sous bash et sous zsh (zéro « mutant sans effet », zéro « SUITE SAUTÉE »). Lignes finales : client 279, vue 186.
Premier jeu de mutants rejoué : deux mutants (M-AUCUNE-IGNOREE, M-SONDAGE-APRES-VISIBLE) faisaient « planter » la sonde au lieu de rougir ; les attentes sont devenues souples (commit test(72-08) a347dc0f), puis les deux rougissent.
