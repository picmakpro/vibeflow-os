# 71-02 — trace du rouge des contrôles de Q et des secrets

- date : 2026-11-03
- empreinte du commit de tests : `ab4a7ff2` (`test(71-02): témoins rouges des contrôles de Q et des secrets`)
- base : code de 71-01 (HEAD `03518b44`), `vf-cockpit-terminal.mjs` et `vf-cockpit-terminal-amorce.mjs` inchangés
- commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-serveur.sh > 71-02-t1.out 2>&1` — rc=1, `Résultats : 126 PASS / 25 FAIL`

La base de 71-01 tient déjà T1, T2 (dont T2.3 : l'ordre Host puis Origin refusait déjà `localhost` hors `GET /`), T3.1 à T3.6 (dont OPTIONS -> 403 : seules GET et POST
passaient) et T5. Les rouges sont donc ceux ci-dessous, tous pour la raison attendue. Le plan en annonçait deux de plus (T2.3, T3.6) : mesurés verts sur la base,
conservés comme garde-fous. Aucune assertion T1 ne rougit (fixture saine).

## Témoins rouges (25)

### FAIL — T3.1d — chemin inconnu sans secret rend 401
- attendu : `[401]`
- obtenu : `[404]` (la route se devine sans secret : le routage précède le contrôle du secret)

### FAIL — T3.9 (200, 401, 403, 404, 405, 204, 400) — en-têtes de P71-PL-16 sur la réponse
- attendu : `[ok]` (nosniff, no-referrer, no-store, `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'`, ni CORS, cookie, X-Frame-Options)
- obtenu : `[{"referrer-policy":"no-referrer","x-content-type-options":"nosniff","cache-control":"no-store",…}]` : aucune CSP de base hors `GET /` (7 réponses)

### FAIL — T3.7 (sans session et avec session) — POST /entree de 65537 octets rend 413
- attendu : `[413]`
- obtenu : `[ERREUR ECONNRESET]` : la connexion est détruite avant d'écrire la réponse (2 sondes) ; T3.9 sur la réponse 413 rougit en conséquence (aucune en-tête à lire)
- T3.7b (aucun octet au shell) reste vert : le corps coupé n'atteint pas le shell

### FAIL — T3.8 — POST /taille hors bornes
- « 500 1000 » (les bornes) : attendu `[204]`, obtenu `[400]` (4 chiffres refusés)
- « 0 0 » : attendu `[400]`, obtenu `[204]`
- « 24 0 » : attendu `[400]`, obtenu `[204]`
- « 501 80 » : attendu `[400]`, obtenu `[204]` (aucune borne à 500 lignes)

### FAIL — T4.4 — amorçage servi par un lien symbolique
- attendu : `[403]`
- obtenu : `[200]` (le lien est suivi)

### FAIL — T4.5 — amorçage en mode 0644, 0640, 0604, 0660 (4 rouges) ; T4.5c — fichier de plus de 128 octets
- attendu : `[403]`
- obtenu : `[200]` (aucun contrôle du mode ni de la taille)
- les 4 témoins « après chmod 600, le même fichier est accepté » rougissent par ricochet (obtenu `[403]` : l'amorçage a été consommé par l'échange fautif) ; ils reverdiront avec le refus

## Mutants (copies de la sortie, code de 71-01) — chacun rougit sa sonde

| Mutant | Fichier | Remplacement | Obtenu / sain |
|--------|---------|--------------|---------------|
| M-ORIGIN | `vf-cockpit-terminal.mjs` | `else if (o !== origineQ()) return 403;` -> `else if (false) return 403;` | 410 au lieu de 403 (Origin tierce admise) |
| M-HOST | `vf-cockpit-terminal.mjs` | `!hotes.includes(String(req.headers.host \|\| '').toLowerCase())` -> `!String(req.headers.host \|\| '').endsWith(':' + portQ)` | 410 au lieu de 403 |
| M-JETON | `vf-cockpit-terminal.mjs` | `!egal(req.headers['x-vf-terminal'], secret)` -> `(req.headers['x-vf-terminal'] !== undefined && !egal(…))` | 410 au lieu de 401 (secret absent admis) |
| M-SANSORIGIN | `vf-cockpit-terminal.mjs` | `if (o === undefined) { if (!page) return 403; }` -> `if (o === undefined) { }` | 410 au lieu de 403 |
| M-REJEU | `vf-cockpit-terminal-amorce.mjs` | `fs.unlinkSync(fichier)` -> `0` | 200 au lieu de 403 (rejeu accepté) |
| M-SERVI | `vf-cockpit-terminal.mjs` | `return res.end(html);` -> `return res.end(html + String(fs.readFileSync(fichierAmorce, "utf8")));` | 1 fichier contient l'amorçage (attendu 0) |
| M-LOG | `vf-cockpit-terminal.mjs` | `log('terminal actif (127.0.0.1 seulement).');` -> `log('terminal actif ' + secret);` | 1 fichier contient le secret (attendu 0) |
| M-URL | `vf-cockpit-terminal.mjs` | `egal(req.headers['x-vf-terminal'], secret)` -> `egal(req.headers['x-vf-terminal'] ?? url.searchParams.get('s'), secret)` | 200 au lieu de 401 (`?s=` admis) |

Aucun « mutant sans effet ».

## Constat de fixture (hors rouges)

Un POST de 65536 octets écrit au shell fait survivre l'assistant PTY au SIGTERM du serveur (H0 de la suite) : l'assistant de 71-01 écrit au maître en bloquant et ne revoit
plus son entrée standard fermée. La suite évite cette écriture (limite mesurée sans session). Voir 71-02-SUMMARY, finding F2.
