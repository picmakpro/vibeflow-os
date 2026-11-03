# 67-FIX-A — SUMMARY (correction ciblée A : sécurité et robustesse)

Nœud `fix-67-a`, Phase 67, tour de correction 1 sur 3 · mandat `vf-dev-manager-v2-cockpit` · arbre `v2-cockpit`, branche `feat/v2-cockpit`, de `2964658b` à `00e35ffc` (+ commit de documentation).
Arbitrages (arbitrage Samuel, AskUserQuestion session principale, 2026-11-01) : F1 = garder « modifier le plan », durci, sans suppression de code amont (validation ADR-031 pour ce durcissement précis) ; lot A validé tel que décrit.
Aucun cycle cadrage/plan : uniquement les findings de 67-SECURITY.md et 67-REVIEW.md. Détail des témoins : 67-SECURITY.md § « Corrections et témoins ».

## Corrigé

| finding | commit | témoin |
|---|---|---|
| B1 (F1) garde du moteur | c5868a5d | test-cockpit-chaine-xss.sh (C0 -> C4) |
| B2 XSS stockée (tout champ) | c5868a5d | test-cockpit-securite.sh X1-X3 (Chrome, mutant sans `h()`) |
| M5 en-têtes | c5868a5d | securite H1-H6 (mutant sans setHeader) ; chaine C1.4-C1.6 (page fonctionnelle sous CSP) |
| M1, M2 réglages de `claude -p` | 324986c2 | 67-MESURE-claude-p.md (hooks 54 -> 0 ; règle utilisateur réelle appliquée -> refusée) ; Q11 ; securite S4 |
| M3 aucun script du lab | c9f73a8f | securite L1-L8 |
| M4 liens symboliques | c9f73a8f, c5868a5d | securite Y1-Y5 |
| M6, M7, M8, M9, M10, M11 | c5868a5d, c9f73a8f, 00e35ffc | securite B, S, J, M, E, C, T, R ; robustesse K, B |
| S1 (revue) questions courantes | 00e35ffc | robustesse S1.1-S1.4 |
| S2 page rechargée à jour | 00e35ffc | direct D2.5, D2.6 |
| S3 verrou plat | 00e35ffc | robustesse S3.1, S3.2, U1 |
| S4 `<!--` | c5868a5d | securite E1-E3 |
| P1 lab sans code | c9f73a8f | robustesse P1 (planning seul ; planning + Markdown), F (échec d'étape : cause en français) |
| mineurs : `tail()` try/finally, `s.replace(t, () => out)`, hystérésis ajout+retrait, resynchronisation sur `hello.seq`, Q11 sans assertion, V4 `-le 300`, I7 | 00e35ffc, c5868a5d | direct D4.4 ; robustesse V1, W1-W2 (relais coupant le flux, page rechargée) ; Q11.4 ; vendor V4 ; update I7 |

Témoins rouges (module `2964658b` + suites nouvelles, attendu / obtenu) : voir le tableau de 67-SECURITY.md ; extraits : H1 `[true,true,true]` / `[false,false,false]` ; B1 `0` / `15` ; J1 `600` / `644` ; L5 `non` / `oui` ; Y4 `404` / `200` ; E1 `[false,true,2]` / `[true,true,3]` ;
S1.3 `200` / `ERR ECONNREFUSED` ; S3.1 `true,1,rev` / `false,0,` ; P1 (seul) `0` / `4` ; K1 `0` / `4` ; D2.5 `done` / `todo` ; D4.4 `0` / `2` ; W2 `false` / `true`.

## Mesure `claude -p`

`--setting-sources ""` ferme les hooks du lab et la règle `allow` de l'utilisateur (témoin positif sans le drapeau, négatif avec) ; `--strict-mcp-config` sans effet de bord. Verdict : CONFINABLE, le repli « détecter et couper l'agent » est inutile.

## Écarts et décisions à connaître

- **README racine** (`README.md`, `README.fr.md`) : le compte « 136 suites » est devenu 139 (trois suites ajoutées) ; `check-version-sync` (job `gates`) rougit sinon. C'est le seul fichier hors périmètre listé touché ; ni `VERSION`, ni `plugin.json`, ni `marketplace.json`.
- Le dossier de scripts **du module** (`VF_COCKPIT_SCRIPTS_DIR`, posé par le lanceur) reste admis même s'il est sous le lab (pose `project`, ou dépôt de développement) ; seul un candidat pris dans le lab lui-même, ou dans `.vibeflow/`, est refusé. La confiance repose donc sur le lanceur, pas sur un fichier du lab.
- `.cache/history/` n'est plus conservé d'un redémarrage du serveur à l'autre (la purge est le prix de « ignorer tout `.cache/` préexistant ») : l'annulation d'un changement de plan ne remonte pas au-delà de la vie du serveur.
- Message d'erreur du corps non objet traduit en français (`Requête invalide : un objet JSON est attendu.`) : l'inventaire du chrome (F2) comptait « bad body ».
- Une nouvelle aide partagée pour les suites : `scripts/tests/chrome-cdp.mjs` (client DevTools sans dépendance, HOME réel rendu à Chrome car il ne démarre pas sous un HOME jetable sur macOS).
- Sans navigateur, les suites X (securite) et W (robustesse) sont **sautées et non comptées** ; la chaîne bascule en simulation fidèle (documentée dans l'en-tête de la suite).

## Restes (voir 67-SECURITY.md § Restes)

M7 assumé (jeton servi à tout processus local) ; mineurs 8 (gate hors périmètre) et 10 (doublons, `Exports`) ; renommage non diffusé par le direct ; `tail()` sans test dédié ; Windows non mesuré.

## Rejeu final

Sur `00e35ffc` : 14 suites `plugin/cockpit/scripts/tests/` vertes (assemblage 39, chaîne 18, chrome-fr 24, direct 30, marque-blanche 21, onglet-code 12, projet 25, questions 43, réseau 13, robustesse 21, sécurité 49, serveur 36, vendor 74, qui 33), `test-vibeflow-update-cockpit.sh` 11 ok / 0 ko, `synchro.sh verifier` rc 0 (amont retrouvé à l'octet, 48 fichiers). Aucune valeur `estimate`/`actuals` : le mandat n'exécutait pas un PLAN.md.
