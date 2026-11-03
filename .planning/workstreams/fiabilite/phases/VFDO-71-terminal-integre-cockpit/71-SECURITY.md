# 71-SECURITY — audit sécurité et dette, Phase 71 (terminal intégré au cockpit)

Nœud audit-71 · code audité `227be6c5` (HEAD de l'arbre au verdict : `d57ca6bd`, docs seulement depuis `227be6c5`) · 2026-11-04 · auditeur : `vf-auditer`, recoupé avec `gsd-security-auditor` · statut : **gaps_found** (0 bloquant, 2 majeurs, 7 mineurs)
Verdict : gaps_found — rendu par vf-auditer le 2026-11-04 sur `227be6c5` ; correctifs de sécurité soumis à la validation de Samuel (ADR-031), voir § Verdict de l'audit

Ce fichier est livré par le plan 71-09 (écrit par l'exécuteur, calqué sur la forme de `67-SECURITY.md`). Il contient le registre complet des menaces, la
re-vérification demandée pour P71-D-09 à P71-D-19 (« à vérifier par l'audit », ADR-031) et l'état **mesuré** des suites qui prouvent chaque menace. Il ne rend
aucun verdict global : le verdict vient de `gsd-secure-phase 71` ou de `vf-auditer`, joué après l'exécution (nœud du manager), qui rejoue les sondes citées et remplace la ligne
« Verdict : à rendre par l'audit » par un verdict nommé, daté et attribué.

## Réponses aux questions de la phase (renvois aux sondes)

1. **Site tiers vers Q** : Host, Origin et secret sont contrôlés sur chaque requête de Q, `OPTIONS` rend 403, aucun `Access-Control-*`, aucun écouteur `upgrade` (P71-D-09, P71-D-10).
   Sondes : `test-cockpit-terminal-serveur.sh` (T1 à T3, TD.1 ; mutants M-ORIGIN, M-SANSORIGIN, M-HOST, M-JETON, M-URL) ; `test-cockpit-terminal-xss.sh` (manches C1t à C4t, chaque contrôle laissé seul). État : vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) ; vert `test-cockpit-terminal-xss.sh` (17 PASS / 0 FAIL).
2. **Page P compromise vers le shell** : origine distincte de Q, secret de session inaccessible depuis P (`SecurityError` mesuré), `window.open` sans geste bloqué, `postMessage` sans effet ; la sonde sait détecter un shell atteint (témoin C0t : Q privée de ses trois contrôles crée le fichier marqueur).
   Sondes : `test-cockpit-terminal-xss.sh` (T16.1 à T16.7, C0t à C4t), `test-cockpit-chaine-xss.sh`. État : vert `test-cockpit-terminal-xss.sh` (17 PASS / 0 FAIL) ; chaîne XSS : vert `test-cockpit-chaine-xss.sh` (22 PASS / 0 FAIL).
3. **Fuite d'amorçage ou de secret** : jeton d'amorçage jamais servi, jamais journalisé, jamais en argument ni en environnement du serveur ; secret de session en en-tête seulement, jamais cookie ni adresse.
   Sondes : `test-cockpit-terminal-serveur.sh` (T4, T5, TD.2 ; M-REJEU, M-SERVI, M-LOG, M-URL), `test-cockpit-terminal-lanceur.sh` (L3 à L6 ; M-MODE, M-SUIT-LIEN, M-IMPRIME), `test-cockpit-terminal-client.sh` (T6 ; M-COOKIE, M-FRAGMENT, M-STOCKAGE). État : vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) ; vert `test-cockpit-terminal-lanceur.sh` (35 PASS / 0 FAIL) ; vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL). Limite A4.
4. **Frappes ou sortie sur disque** : aucune écriture disque ni journal, tampon de reprise vidé à la fin.
   Sondes : `test-cockpit-terminal-session.sh` (T15.1, T15.2 ; M-JOURNAL, M-TAMPON). État : vert `test-cockpit-terminal-session.sh` (29 PASS / 0 FAIL).
5. **Séquences hostiles** (OSC 52, OSC 8, DCS, XTGETTCAP, CSI 21t/18t, DECRQSS, DA1) : presse-papiers jamais appelé, seule la réponse à DA1 est réinjectée dans l'entrée du PTY, liens sur clic en `noopener` sans `confirm`.
   Sondes : `test-cockpit-terminal-xterm.sh` (T14.1 à T14.5 ; M-DCS, M-WINOPT, M-CLIP, M-LIEN), `test-cockpit-terminal-client.sh` (T14.S1 à T14.S4). État : vert `test-cockpit-terminal-xterm.sh` (18 PASS / 0 FAIL) ; vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL).
6. **Processus survivants** : EOF du descripteur 0, SIGHUP puis SIGKILL aux groupes du shell et de premier plan, aucun processus à l'arrêt du serveur.
   Sondes : `test-cockpit-terminal-pty.sh` (T12.4 ; M-NOEOF), `test-cockpit-terminal-session.sh` (T12.5). État : vert `test-cockpit-terminal-pty.sh` (39 PASS / 0 FAIL) ; vert `test-cockpit-terminal-session.sh` (29 PASS / 0 FAIL). Limite A5 (détachement volontaire) ; `T12.4` a rougi une fois sur sept rejeux complets sous charge pendant la phase (cause non établie, voir `71-FIX-ORIGIN-SUMMARY.md`).

## Registre des menaces (T-71-01 à T-71-48, T-71-SC)

Une ligne par menace. Les sévérités et dispositions viennent des blocs `<threat_model>` des plans 71-01 à 71-11. T-71-19 : disposition `accept` d'origine, devenue définitive par P71-D-23.
T-71-SC : une seule ligne, qui réunit ses deux dispositions (`accept` en 71-01, `mitigate` en 71-11). « État mesuré » : exit code et décompte relevés par 71-09 sur le code figé (dossier de sortie hors dépôt) ; vert d'une suite signifie que la suite entière sort 0, pas que l'assertion citée a été isolée.

| Menace | Catégorie | Sévérité | Plan | Disposition et mitigation | Suite | Assertions | Mutant qui rougit | État mesuré par 71-09 |
|---|---|---|---|---|---|---|---|---|
| T-71-01 | Elevation of Privilege | élevée | 71-01 | **mitigate** : import dynamique seulement sous `has('terminal')` (patch P25) | `test-cockpit-terminal-activation.sh` | T7.1, T7.3, T7.5 | M-ACTIF | vert `test-cockpit-terminal-activation.sh` (40 PASS / 0 FAIL) |
| T-71-02 | Information Disclosure | élevée | 71-01 | **mitigate** : second écouteur sur `127.0.0.1` seulement, port éphémère | `test-cockpit-terminal-activation.sh` | T7.8 | M-ECOUTE0 | vert `test-cockpit-terminal-activation.sh` (40 PASS / 0 FAIL) |
| T-71-03 | Spoofing | élevée | 71-10 | **mitigate** : amorçage : suppression préalable puis création exclusive `wx` en 0600, aucun lien préplacé suivi | `test-cockpit-terminal-lanceur.sh` | L3, L4 | M-MODE, M-SUIT-LIEN | vert `test-cockpit-terminal-lanceur.sh` (35 PASS / 0 FAIL) |
| T-71-04 | Information Disclosure | élevée | 71-10 | **mitigate** : amorçage jamais imprimé, jamais en argument ni en environnement du serveur ; limite A4 (ouvreur du navigateur) | `test-cockpit-terminal-lanceur.sh` | L5 | M-IMPRIME | vert `test-cockpit-terminal-lanceur.sh` (35 PASS / 0 FAIL) |
| T-71-05 | Elevation of Privilege | élevée | 71-01 | **mitigate** : l'assistant n'est lancé que par `GET /flux` après `controle()` | `test-cockpit-terminal-activation.sh` | E2E.3 | aucun (le témoin est l'absence d'assistant avant le flux) | vert `test-cockpit-terminal-activation.sh` (40 PASS / 0 FAIL) |
| T-71-06 | Tampering | moyenne | 71-01 | **mitigate** : `frame-src` = origine exacte de Q, ajouté hors de `pageCsp` | `test-cockpit-terminal-activation.sh` | T8.1 | M-FRAMESRC | vert `test-cockpit-terminal-activation.sh` (40 PASS / 0 FAIL) |
| T-71-07 | Denial of Service | faible | 71-01 | **mitigate** : branche `win32` sans écouteur | `test-cockpit-terminal-activation.sh` | T11.4 | M-WIN | vert `test-cockpit-terminal-activation.sh` (40 PASS / 0 FAIL) |
| T-71-08 | Tampering | élevée | 71-02 | **mitigate** : Origin exacte de Q exigée (sauf `GET` navigateur de même origine, P71-D-24) | `test-cockpit-terminal-serveur.sh` | T1.1, T1.2, T3.4 | M-ORIGIN, M-SANSORIGIN | vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) |
| T-71-09 | Spoofing | élevée | 71-02 | **mitigate** : liste d'hôtes exacte, `localhost` limité à `GET /` | `test-cockpit-terminal-serveur.sh` | T2.1, T2.3 | M-HOST | vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) |
| T-71-10 | Spoofing | moyenne | 71-02 | **mitigate** : `egal` : sha256 puis `timingSafeEqual` | `test-cockpit-terminal-serveur.sh` | T3.1, T3.3 | M-JETON | vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) |
| T-71-11 | Spoofing | élevée | 71-02 | **mitigate** : `O_NOFOLLOW`, fichier ordinaire, 0600, propriétaire, usage unique | `test-cockpit-terminal-serveur.sh` | T4.2, T4.5 | M-REJEU | vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) |
| T-71-12 | Information Disclosure | élevée | 71-02 | **mitigate** : secret en en-tête seulement, messages sans valeur, `Referrer-Policy: no-referrer` | `test-cockpit-terminal-serveur.sh` | T5.1, T5.9, TD.2 | M-LOG, M-URL, M-SERVI | vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) |
| T-71-13 | Elevation of Privilege | élevée | 71-02 | **mitigate** : `OPTIONS` 403, aucun `Access-Control-*`, aucun écouteur `upgrade` | `test-cockpit-terminal-serveur.sh` | T3.6, TD.1 | aucun (absence prouvée par témoin de vivacité) | vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) |
| T-71-14 | Denial of Service | moyenne | 71-02 | **mitigate** : corps de 64 Kio puis 413 ; taille bornée (une seule borne, FIX-PTY) | `test-cockpit-terminal-serveur.sh` | T3.7, T3.8 | aucun (bornes testées des deux côtés) | vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) |
| T-71-15 | Information Disclosure | élevée | 71-03 | **mitigate** : `envShell` : liste noire par nom (`CLAUDECODE`, `CLAUDE_CODE_*`, `VF_COCKPIT_*`) et par valeur (jetons du cockpit) | `test-cockpit-terminal-pty.sh` | T10.1, T10.5 | M-ENVLARGE | vert `test-cockpit-terminal-pty.sh` (39 PASS / 0 FAIL) |
| T-71-16 | Elevation of Privilege | élevée | 71-03 | **mitigate** : `python3 -I`, assistant lu dans l'arbre du moteur (T-71-48), jamais dans le lab | `test-cockpit-terminal-pty.sh` | T11.1 | M-SANS-I | vert `test-cockpit-terminal-pty.sh` (39 PASS / 0 FAIL) |
| T-71-17 | Denial of Service | moyenne | 71-03 | **mitigate** : EOF du fd 0, SIGHUP puis SIGKILL au groupe du shell et au groupe de premier plan ; limite A5 (`nohup`, `setsid`, `disown`, `dash`) | `test-cockpit-terminal-pty.sh` | T12.4 | M-NOEOF | vert `test-cockpit-terminal-pty.sh` (39 PASS / 0 FAIL) |
| T-71-18 | Denial of Service | faible | 71-03 | **mitigate** : 0x03 passé au maître, SIGINT au seul groupe de premier plan | `test-cockpit-terminal-pty.sh` | T11.3 | M-SIGINT, M-CTRLC | vert `test-cockpit-terminal-pty.sh` (39 PASS / 0 FAIL) |
| T-71-19 | Tampering | faible | 71-03 | **accept** : `TERM` et `COLORTERM` posés toujours (`AJOUTS_TOUJOURS`) : d'abord P71-D-22 (manager, provisoire), devenu définitif par P71-D-23 (arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-03) | `test-cockpit-terminal-pty.sh` | T10.8 | M-SI-ABSENT | vert `test-cockpit-terminal-pty.sh` (39 PASS / 0 FAIL) |
| T-71-20 | Spoofing | moyenne | 71-04 | **mitigate** : propriétaire d'onglet sur `/flux`, `/entree`, `/taille` ; limite A6 (« dupliquer l'onglet ») | `test-cockpit-terminal-session.sh` | T12.1, T12.6 | M-UNIQUE, M-PROPRIO | vert `test-cockpit-terminal-session.sh` (29 PASS / 0 FAIL) |
| T-71-21 | Information Disclosure | élevée | 71-04 | **mitigate** : aucun octet vers `console.*`, aucune écriture disque | `test-cockpit-terminal-session.sh` | T15.1 | M-JOURNAL | vert `test-cockpit-terminal-session.sh` (29 PASS / 0 FAIL) |
| T-71-22 | Information Disclosure | moyenne | 71-04 | **mitigate** : tampon vidé à la fin et à l'échéance de la grâce | `test-cockpit-terminal-session.sh` | T15.2 | M-TAMPON | vert `test-cockpit-terminal-session.sh` (29 PASS / 0 FAIL) |
| T-71-23 | Denial of Service | moyenne | 71-04 | **mitigate** : tampon borné à 262144 octets, contre-pression | `test-cockpit-terminal-session.sh` | T12.7 | M-TAMPON | vert `test-cockpit-terminal-session.sh` (29 PASS / 0 FAIL) |
| T-71-24 | Denial of Service | faible | 71-04 | **mitigate** : `occupe()` lu par la garde d'inactivité | `test-cockpit-terminal-session.sh` | T12.5 | M-IDLE | vert `test-cockpit-terminal-session.sh` (29 PASS / 0 FAIL) |
| T-71-25 | Tampering | élevée | 71-05 | **mitigate** : paramètre `theme` : égalité stricte avec `light`, valeur jamais insérée | `test-cockpit-terminal-page.sh` | TH.3, TH.4 | M-THEME | vert `test-cockpit-terminal-page.sh` (39 PASS / 0 FAIL) |
| T-71-26 | Elevation of Privilege | élevée | 71-05 | **mitigate** : CSP de Q : directives exactes, empreintes, `frame-ancestors` = origine de P | `test-cockpit-terminal-page.sh` | T9.1, T9.4 | M-ANCETRES, M-EMPREINTE | vert `test-cockpit-terminal-page.sh` (39 PASS / 0 FAIL) |
| T-71-27 | Tampering | moyenne | 71-05 | **mitigate** : sha256 du vendor contre le code et `SHA256SUMS`, démarrage refusé | `test-cockpit-terminal-page.sh` | TV.1, TV.2 | aucun mutant nommé (altération de fichier jouée par TV.1) | vert `test-cockpit-terminal-page.sh` (39 PASS / 0 FAIL) |
| T-71-28 | Denial of Service | faible | 71-05 | **mitigate** : aucun `X-Frame-Options` sur la page de Q | `test-cockpit-terminal-page.sh` | T9.2 | M-XFO | vert `test-cockpit-terminal-page.sh` (39 PASS / 0 FAIL) |
| T-71-29 | Repudiation | faible | 71-05 | **mitigate** : parité à 25 variables par thème avec `viewer.html` | `test-cockpit-terminal-page.sh` | T18 | M-PARITE | vert `test-cockpit-terminal-page.sh` (39 PASS / 0 FAIL) |
| T-71-30 | Information Disclosure | élevée | 71-06 | **mitigate** : fragment effacé avant l'échange, `localStorage` de Q seulement, aucun cookie | `test-cockpit-terminal-client.sh` | T6.1, T6.7 | M-COOKIE, M-FRAGMENT, M-STOCKAGE | vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) |
| T-71-31 | Tampering | élevée | 71-06 | **mitigate** : gestionnaire DCS de remplacement, `windowOptions` vide (comportement prouvé en 71-08) | `test-cockpit-terminal-client.sh` | T14.S1, T14.S2 | aucun dans cette suite (M-DCS, M-WINOPT dans `xterm`) | vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) |
| T-71-32 | Information Disclosure | élevée | 71-06 | **mitigate** : aucun addon presse-papiers, aucun appel au presse-papiers | `test-cockpit-terminal-client.sh` | T14.S3 | M-CLIP (suite `xterm`) | vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) |
| T-71-33 | Information Disclosure | élevée | 71-06 | **mitigate** : huit valeurs fixes, `targetOrigin` exact | `test-cockpit-terminal-client.sh` | T17.Q2, T17.Q3 | M-ETOILE | vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) |
| T-71-34 | Elevation of Privilege | élevée | 71-06 | **mitigate** : aucun écouteur de message dans Q (P71-D-15) | `test-cockpit-terminal-client.sh` | T17.Q1 | M-ECOUTE | vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) |
| T-71-35 | Spoofing | moyenne | 71-06 | **mitigate** : liens OSC 8 sur clic seulement, `noopener`, aucun `confirm` | `test-cockpit-terminal-client.sh` | T14.S4 | M-LIEN (suite `xterm`) | vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) |
| T-71-36 | Spoofing | moyenne | 71-07 | **mitigate** : `accepteMessage` : `isTrusted`, origine exacte, source = cadre, liste fermée | `test-cockpit-terminal-tiroir.sh` | T17.2, T17.4 | M-MSG-ORIGINE, M-MSG-SOURCE, M-MSG-LISTE, M-MSG-CONFIANCE | vert `test-cockpit-terminal-tiroir.sh` (34 PASS / 0 FAIL) |
| T-71-37 | Information Disclosure | moyenne | 71-07 | **mitigate** : tiroir injecté à la volée seulement sous `--terminal`, jamais dans la page sur disque ni l'export | `test-cockpit-terminal-tiroir.sh` | TU.1, TU.12 | aucun (absence prouvée avec garde de vivacité) | vert `test-cockpit-terminal-tiroir.sh` (34 PASS / 0 FAIL) |
| T-71-38 | Denial of Service | faible | 71-07 | **mitigate** : garde O6 : `localhost:P` désactive le tiroir, avec message | `test-cockpit-terminal-tiroir.sh` | TU.9 | aucun | vert `test-cockpit-terminal-tiroir.sh` (34 PASS / 0 FAIL) |
| T-71-39 | Elevation of Privilege | moyenne | 71-07 | **mitigate** : `sandbox` : chaîne exacte de cinq jetons, aucun `allow` | `test-cockpit-terminal-tiroir.sh` | TU.3 | aucun (chaîne comparée à l'octet) | vert `test-cockpit-terminal-tiroir.sh` (34 PASS / 0 FAIL) |
| T-71-40 | Information Disclosure | élevée | 71-07 | **mitigate** : aucune donnée du shell ni secret dans un message reçu par P | `test-cockpit-terminal-tiroir.sh` | T17.5 | M-MSG-DONNEE | vert `test-cockpit-terminal-tiroir.sh` (34 PASS / 0 FAIL) |
| T-71-41 | Elevation of Privilege | élevée | 71-08 | **mitigate** : chaîne XSS P vers shell : origine distincte, secret inaccessible depuis P, Origin + secret + onglet sur Q | `test-cockpit-terminal-xss.sh` | T16.1, T16.7, C0t | M-ORIGINE-TERM, M-SECRET-TERM, M-ONGLET-TERM | vert `test-cockpit-terminal-xss.sh` (17 PASS / 0 FAIL) |
| T-71-42 | Tampering | élevée | 71-08 | **mitigate** : aucune réinjection dans l'entrée du PTY au-delà de la réponse à DA1 | `test-cockpit-terminal-xterm.sh` | T14.1 | M-DCS, M-WINOPT | vert `test-cockpit-terminal-xterm.sh` (18 PASS / 0 FAIL) |
| T-71-43 | Information Disclosure | élevée | 71-08 | **mitigate** : aucun addon presse-papiers, liens sur clic en `noopener` sans `confirm` | `test-cockpit-terminal-xterm.sh` | T14.2, T14.4 | M-CLIP, M-LIEN | vert `test-cockpit-terminal-xterm.sh` (18 PASS / 0 FAIL) |
| T-71-44 | Repudiation | moyenne | 71-09 | **mitigate** : limites écrites une à une, limite de fond mot pour mot (README du module) | `(plan 71-09)` | commande OK-DOCS et critère « Limites connues » du plan 71-09 | aucun (preuve documentaire) | OK-DOCS rejoué hors clause de statut de la recette : vert ; la clause « statut FAITE, ÉCARTS ou CONTOURNÉE » ne peut pas être verte, la recette n'étant pas jouée (statut À JOUER) |
| T-71-45 | Tampering | moyenne | 71-09 | **mitigate** : procédure de fusion écrite dans `71-BRANCHEMENTS-MERGE.md` | `(plan 71-09)` | commande OK-RECENSEMENT du plan 71-09 | aucun (preuve documentaire) | OK-RECENSEMENT rejoué : vert |
| T-71-46 | Repudiation | faible | 71-09 | **mitigate** : point d'arrêt `blocking-human` ; verdict de ce fichier réservé à l'audit | `(plan 71-09)` | commande OK-SECURITY du plan 71-09 (exige « Verdict : à rendre ») | aucun (preuve documentaire) | OK-SECURITY rejoué : vert (verdict non rendu) ; recette humaine non jouée, point d'arrêt `blocking-human` tenu |
| T-71-47 | Elevation of Privilege | moyenne | 71-10 | **mitigate** : relance O2 : arrêt par la garde `estNotre` seulement | `test-cockpit-terminal-lanceur.sh` | L11, L11b | aucun (PID leurre jamais arrêté) | vert `test-cockpit-terminal-lanceur.sh` (35 PASS / 0 FAIL) |
| T-71-48 | Elevation of Privilege | élevée | 71-01 | **mitigate** : chemin de l'assistant fixé par le moteur, refusé sous `.vibeflow/`, aucun repli ; pose réelle dans trois scopes | `test-cockpit-terminal-activation.sh` | POSE.1, POSE.3 | M-HORS-MOTEUR | vert `test-cockpit-terminal-activation.sh` (40 PASS / 0 FAIL) |
| T-71-SC | Tampering | faible puis élevée | 71-01 et 71-11 | **accept (71-01) et mitigate (71-11)** : `accept` (71-01) : aucun paquet récupéré par 71-01 ; `mitigate` (71-11) : `npm pack --ignore-scripts` sans installation, sha256 des tarballs et des fichiers épinglés, extraction dans un dossier neuf | `test-cockpit-terminal-activation.sh / test-cockpit-vendor.sh` | activation (aucune installation) ; vendor V9.1, V9.2 | M-SHA (suite `vendor`) | vert `test-cockpit-terminal-activation.sh` (40 PASS / 0 FAIL) ; vert `test-cockpit-vendor.sh` (96 PASS / 0 FAIL) |

## Re-vérification de P71-D-09 à P71-D-19 (à vérifier par l'audit, ADR-031)

Décisions du manager (vf-dev-manager, 2026-11-03), prises sur mesures et non arbitrées par Samuel. Pour chacune : la propriété à vérifier, les sondes, le résultat mesuré par 71-09, une réserve si elle existe. L'audit les reprend et tranche.

### P71-D-09 — transport sans WebSocket
- Propriété : sortie par `fetch()` en flux, entrées et redimensionnement par `POST` ; aucun écouteur `upgrade` sur Q ; le jeton reste en en-tête.
- Sondes : `test-cockpit-terminal-serveur.sh` (T3.6, TD.1), `test-cockpit-terminal-client.sh` (TQ.1). Résultat : vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) ; vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL).
- Réserve : aucune.

### P71-D-10 — contrôles du second serveur (amendée par P71-D-24)
- Propriété : `Host`, `Origin` exacte et secret en en-tête sur chaque requête, comparaison en temps constant, aucun shell avant authentification, corps bornés. P71-D-24 : `GET /flux` et `GET /etat` sans `Origin` admis seulement sous `Sec-Fetch-Site: same-origin` et secret valide ; les `POST` gardent `Origin` obligatoire.
- Sondes : `test-cockpit-terminal-serveur.sh` (T1 à T3, section T6 de P71-D-24 avec client qui reproduit le navigateur, mutants `navmut` NAV-SFS, NAV-SANS-SFS, NAV-SANS-SECRET, NAV-POST, NAV-ORIGIN). Résultat : vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL).
- Réserve : le contrôle du propriétaire du fichier d'amorçage (`st.uid === process.getuid()`) n'a pas de sonde (un autre compte n'est pas disponible dans la suite ; 71-02 F4).

### P71-D-11 — jetons
- Propriété : amorçage à usage unique, jamais servi par HTTP, jamais dans `serveur.log`, SSE, export ou `server.json` en clair ; 0600 et effacé à la consommation ; échangé contre un secret de session renouvelé à chaque démarrage.
- Sondes : `test-cockpit-terminal-serveur.sh` (T4.2 à T4.5, T5.1 à T5.9), `test-cockpit-terminal-lanceur.sh` (L3, L4, L5). Résultat : vert `test-cockpit-terminal-serveur.sh` (184 PASS / 0 FAIL) ; vert `test-cockpit-terminal-lanceur.sh` (35 PASS / 0 FAIL).
- Réserve : A4, l'amorçage passe une fraction de seconde dans les arguments de l'ouvreur du navigateur (hypothèse mono-utilisateur).

### P71-D-12 — amorçage dans la même fenêtre
- Propriété : `--terminal` ouvre Q avec l'amorçage en fragment ; Q le consomme, efface le fragment (`history.replaceState`), range le secret, remplace l'adresse par la page Projet ; P ne voit ni le jeton ni le secret.
- Sondes : `test-cockpit-terminal-client.sh` (T6.1 à T6.7), `test-cockpit-terminal-lanceur.sh` (L6). Résultat : vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) ; vert `test-cockpit-terminal-lanceur.sh` (35 PASS / 0 FAIL).
- Réserve : aucune.

### P71-D-13 — rangement du secret
- Propriété : aucun cookie (non cloisonnés par port, mesuré) ; secret dans le `localStorage` de l'origine Q, inaccessible depuis P (`SecurityError`).
- Sondes : `test-cockpit-terminal-client.sh` (M-COOKIE, M-STOCKAGE, T6.5), `test-cockpit-terminal-xss.sh` (lecture du stockage de Q depuis P). Résultat : vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) ; vert `test-cockpit-terminal-xss.sh` (17 PASS / 0 FAIL).
- Réserve : une extension de navigateur ayant accès à `http://127.0.0.1/*` lit le stockage (limite de fond).

### P71-D-14 — `NODE_OPTIONS`
- Propriété : passe au shell comme le reste de l'environnement ; seule la valeur posée par le cockpit est retirée.
- Sondes : `test-cockpit-terminal-pty.sh` (T10.1, M-ENVLARGE : aucune liste blanche n'ampute `NODE_OPTIONS`). Résultat : vert `test-cockpit-terminal-pty.sh` (39 PASS / 0 FAIL).
- Réserve : aucune.

### P71-D-15 — frontière P vers Q
- Propriété : Q ignore tout `postMessage` et ne prend aucune configuration sensible dans son URL hors amorçage ; P peut renvoyer le cadre vers `about:blank` (déni de service accepté, écrit au README).
- Sondes : `test-cockpit-terminal-client.sh` (T17.Q1, M-ECOUTE). Résultat : vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL).
- Réserve : le déni de service du cadre par P est assumé, pas fermé.

### P71-D-16 — xterm.js vendorisé
- Propriété : `@xterm/xterm` 6.0.0 et `@xterm/addon-fit` 0.11.0 (MIT) avec sha256 et licences ; `xterm.css` injecté en `<style>` ; scripts sans attribut ; aucun addon presse-papiers ; liens sur clic en `noopener`.
- Sondes : `test-cockpit-vendor.sh` (V9.1 à V9.4, M-SHA), `test-cockpit-terminal-page.sh` (PQ.1, TV.1, TV.2), `test-cockpit-terminal-xterm.sh` (T14.2 à T14.4). Résultat : vert `test-cockpit-vendor.sh` (96 PASS / 0 FAIL) ; vert `test-cockpit-terminal-page.sh` (39 PASS / 0 FAIL) ; vert `test-cockpit-terminal-xterm.sh` (18 PASS / 0 FAIL).
- Réserve : le vendor n'a pas le marqueur `allow-large-file` (octet pour octet) ; `check-file-size.sh` le laisse passer (71-11).

### P71-D-17 — fichiers neufs, branchement minimal
- Propriété : tout le code de la phase vit dans des fichiers neufs ; les branchements dans des fichiers existants sont listés et minimaux.
- Sondes : `71-BRANCHEMENTS-MERGE.md` (liste re-dérivée de `git diff --name-status`), `test-cockpit-terminal-activation.sh` (T7.x, POSE.1 à POSE.3). Résultat : vert `test-cockpit-terminal-activation.sh` (40 PASS / 0 FAIL).
- Réserve : la décision a été amendée par P71-D-20 (tiroir servi à la volée, pas d'`assets/ui/9x-vf-terminal.js`).

### P71-D-18 — canal sortant Q vers P
- Propriété : messages de valeur fixe tirés d'une liste fermée, `targetOrigin` exact, jamais un octet du shell ni un jeton ; P n'accepte que l'origine exacte de Q ET le cadre comme source.
- Sondes : `test-cockpit-terminal-client.sh` (T17.Q2, T17.Q3, M-ETOILE), `test-cockpit-terminal-tiroir.sh` (T17.2 à T17.5, M-MSG-ORIGINE, M-MSG-SOURCE, M-MSG-LISTE, M-MSG-CONFIANCE, M-MSG-DONNEE). Résultat : vert `test-cockpit-terminal-client.sh` (35 PASS / 0 FAIL) ; vert `test-cockpit-terminal-tiroir.sh` (34 PASS / 0 FAIL).
- Réserve : effet maximal d'un message accepté = fermer le tiroir ou changer un libellé.

### P71-D-19 — thème par paramètre d'URL
- Propriété : le thème passe au cadre par un paramètre non sensible ; égalité stricte avec `light`, valeur jamais insérée ; une bascule recharge le cadre et rejoue le tampon de 256 Ko.
- Sondes : `test-cockpit-terminal-page.sh` (TH.3, TH.4, M-THEME). Résultat : vert `test-cockpit-terminal-page.sh` (39 PASS / 0 FAIL).
- Réserve : l'historique au-delà de 256 Kio est perdu à la bascule (O5).

## Correspondance menace, commit, témoin rouge d'abord

| Plan | Menaces | Commit du code | Témoin rouge d'abord |
|------|---------|----------------|----------------------|
| 71-01 | T-71-01, 02, 05, 06, 07, 48 | `3bcbfebd` | `71-01-RED-TRACE.md` (`017b54ca`) |
| 71-02 | T-71-08 à 14 | `bf883c49` | `71-02-RED-TRACE.md` (`aabc2a17`) |
| 71-03 | T-71-15 à 19 | `15a01a32` | `71-03-RED-TRACE.md` (`e1889155`, `6592d233`) |
| 71-04 | T-71-20 à 24 | `c3eb9be0` | `71-04-RED-TRACE.md` (`48c6a3b3`) |
| 71-05 | T-71-25 à 29 | `c6790bad` | `71-05-RED-TRACE.md` (`222d755b`) |
| 71-06 | T-71-30 à 35 | `ac5dc453` | `71-06-RED-TRACE.md` (`7b214305`) |
| 71-07 | T-71-36 à 40 | `5433db3d` | `71-07-RED-TRACE.md` (`aa9e85ab`) |
| 71-08 | T-71-41 à 43 | `bde4fc2b`, `a1b924f8` | `71-08-RED-TRACE.md` (`5ecde006`) |
| 71-09 | T-71-44 à 46 | commits `docs(71-09)` | commandes `OK-DOCS`, `OK-RECENSEMENT`, `OK-SECURITY` |
| 71-10 | T-71-03, 04, 47 | `f52f3269` | `71-10-RED-TRACE.md` (`24431ed8`, `ed13e6a8`) |
| 71-11 | T-71-SC (mitigate) | `e52f1320` | `71-11-RED-TRACE.md` (`c115e207`) |
| correction ciblée assistant PTY (F2, F3 de 71-02) | T-71-14, 17 | `2a69a139` | témoins T14.1 à T14.3, T3.8d, T11.6, T11.8 (`71-FIX-PTY-SUMMARY.md`) |
| correction ciblée Origin des GET navigateur (P71-D-24) | T-71-08 | `26386f72` | T6.0, T6.0b (`71-FIX-ORIGIN-SUMMARY.md`) |

## Limites assumées (non fermées par le code)

- **Limite de fond** : le terminal, c'est votre compte, dans un dépôt potentiellement hostile : un prompt git, `direnv`, des hooks peuvent exécuter du code du dépôt dès l'ouverture. Une extension de navigateur ayant accès à `http://127.0.0.1/*` lit et pilote toute page locale. Le serveur ne peut fermer ni l'un ni l'autre.
- **A4** : l'amorçage passe une fraction de seconde dans les arguments de la commande d'ouverture du navigateur ; hypothèse mono-utilisateur (M7 de `67-SECURITY.md`).
- **A5** : un processus détaché volontairement (`nohup`, `setsid`, `disown`) ou un travail d'un shell qui ne relaie pas SIGHUP (`dash`) peut survivre à la fin de la session.
- **A6** : « dupliquer l'onglet » peut copier l'identifiant d'onglet de la session.
- **A7** : seul Chrome est mesuré par les suites ; Safari et Firefox relèvent de la recette humaine (`71-RECETTE-HUMAINE.md`, étape 17).
- **P71-D-15** : déni de service du cadre par la page Projet accepté.
- **Constats d'exécution à connaître de l'audit** : `T12.4` intermittent sous charge (1 rouge sur 7 rejeux complets, cause non établie) ; le contrôle du propriétaire du fichier d'amorçage sans sonde ; sondes presse-papiers mesurées par leurs appels, pas par leur contenu (Chrome headless) ; `test-cockpit-terminal-xterm.sh` s'annonce « SUITE SAUTÉE » sans Chrome.

## Verdict de l'audit

**gaps_found**, rendu par `vf-auditer` (recoupé avec `gsd-security-auditor`) le 2026-11-04 sur `227be6c5`. Aucun bloquant. Sondes rejouables
dans le dossier temporaire de la mission (hors dépôt, `audit-71/probes/p1..p13.mjs`, Chrome 156 headless par CDP), chacune avec un témoin positif
(mutant extrait par `git archive`, jamais dans l'arbre). L'arbre n'a pas été modifié par l'audit.

### Réponses aux dix questions (résumé)

1. **Site tiers** : FERMÉ. POST `no-cors`, préflight, EventSource, WebSocket (403 à la poignée de main), formulaire `text/plain`, cadre de Q chez un
   tiers, DNS rebinding : aucun marqueur, une seule session. Hors navigateur : 29 OK / 0 KO ; les mutants sans Origin, sans secret ou sans Host
   rougissent ; le mutant « trio » laisse passer la brèche (le harnais sait la voir).
2. **XSS de classe B2 dans P vers le shell** : FERMÉ pour l'exécution directe (stockage et document du cadre en `SecurityError`, `connect-src`,
   préflight, cinq `postMessage` ignorés, `MessageEvent` forgé ignoré, popup illisible). Reste le presse-papiers (F2) et le popup de Q (F4).
3. **Processus local, autre compte** : hypothèse mono-utilisateur écrite ; `server.json` et `terminal-amorce` en 0600 ; aucune valeur sensible
   dans le journal ni dans l'environnement des processus ; MAIS l'argv de l'ouvreur porte l'amorçage (F6, course prouvée jusqu'au shell).
4. **Jetons et secrets** : FERMÉ. Usage unique, lecture durcie, `timingSafeEqual` (non gardé par un test : F7) ; aucune occurrence dans HTTP, SSE,
   export, `.vibeflow/cockpit/`, `ps`.
5. **Sortie du shell** : FERMÉ. 35 séquences par le vrai pipeline : seules des réponses de format fixe sont réinjectées (DA1, DA2, DSR, CPR,
   DECRQM, couleurs OSC) ; OSC 52 sans effet ; liens OSC 8 non HTTP neutralisés. Aucune CVE connue pour `@xterm/xterm` 6.0.0 ni `addon-fit` 0.11.0
   (GHSA, OSV ; l'absence d'advisory n'est pas une preuve d'absence de défaut).
6. **Cycle de vie** : fin de grâce, SIGKILL et `stop` tuent arrière-plan, avant-plan, shell et assistant en moins de 2 s ; `nohup` survit (A5) ;
   session unique (409) ; inactivité tenue. La revue a mesuré un intermittent sur les travaux d'arrière-plan (S1, T12.4) : traité au lot B.
7. **Environnement du shell** : FERMÉ, conforme à P71-D-03, D-14, D-23 ; descripteurs 0, 1, 2 seulement.
8. **P71-D-24** : aucune voie ouverte ; sans secret, la branche navigateur n'est jamais atteinte ; résiduel : si le secret fuit, Origin n'est plus
   une seconde barrière pour `GET /flux` et `GET /etat`.
9. **Chaîne d'approvisionnement** : vendor identique à l'octet au tarball npm (sha512 = `dist.integrity`) ; altération = terminal non démarré
   (échec fermé) ; assistant en `python3 -I` ; MAIS `python3` résolu par un `PATH` relatif ou vide dans le cwd du lab (F3) et lanceur qui ouvre une
   URL tirée du lab (F1).
10. **Socle 67** : FERMÉ. Sans `--terminal`, `/` et `/project.html` identiques à la base `7370d604` (23 empreintes, même CSP) ; M4 tenu.

### Findings

| Id | Sévérité | Constat | Suite |
|----|----------|---------|-------|
| F1 | majeur | `vf-cockpit.mjs` ouvre `terminal.url` lu dans `.cache/server.json` d'un lab piégé, sans vérifier le processus (`file:///…` remis à l'ouvreur, sondé par un ouvreur factice) — famille M3 de la 67 | lot B, validation Samuel |
| F2 | majeur | Collage piégé : une page P compromise écrit le presse-papiers, le collage dans le tiroir exécute (bash 3.2 immédiat, zsh à l'Entrée) | lot B, choix Samuel (Q10) |
| F3 | mineur | `spawn('python3', cwd=lab)` : `PATH` relatif ou vide = `<lab>/python3` exécuté par le serveur | lot B |
| F4 | mineur | Popup de Q ouvert par P : hérite de l'identifiant d'onglet, prend la session ou lance un shell sans frappe | lot B |
| F5 | mineur | Le vendor xterm garde un écouteur `message` sans contrôle d'origine : P71-D-15 et T-71-33/34 à reformuler (« Q n'a aucun écouteur propre ») | lot B (doc) |
| F6 | mineur | L'amorçage dans l'argv de l'ouvreur est lisible de tout utilisateur (`ps`) et donne le shell | lot B, choix Samuel (Q11) |
| F7 | mineur | Dette de test : T-71-10 et sept mitigations sans assertion rouge | lot A2 (et A1 pour `allowNonHttpProtocols`) |
| F8 | mineur | Libellé de TERM-10 inexact (réponses de format fixe réinjectées) | lot B (doc) |
| F9 | mineur | Ce fichier à compléter ; recette humaine non jouée (T-71-46) | fait (ce paragraphe) ; recette à jouer |

### Mitigations

Fermées par sonde : T-71-01 à 09, 11 à 32, 35 à 45, 47, 48 et T-71-SC ; T-71-33 et T-71-34 avec réserve (F5) ; T-71-31 avec réserve (CSI 21t jamais
exercé, xterm 6.0 n'y répond pas). Ouvertes, non bloquantes : T-71-10 (correcte à la lecture, non gardée), T-71-46 (recette). Deux menaces neuves à
inscrire au registre : F1, F2.

### Limites de la mesure

macOS seulement (Linux et `dash` non mesurés, `xdg-open` lu) ; un seul compte (F6 inter-comptes déduit de la lisibilité de `ps`) ; F1 prouvé avec
un ouvreur factice ; F2 par un collage CDP, glisser-déposer non sondé ; matrice de séquences xterm de 35 cas, sans fuzz.

### Suite donnée (manager, 2026-11-04)

Correctifs ordinaires de revue et de design lancés (lots A1, A2). Correctifs de sécurité (F1 à F6, F8) soumis à la validation de Samuel (ADR-031)
avec trois choix (Q10 collage, Q11 amorçage hors argv, Q12 périmètre de l'arrêt) ; un re-audit ciblé suivra les correctifs.
