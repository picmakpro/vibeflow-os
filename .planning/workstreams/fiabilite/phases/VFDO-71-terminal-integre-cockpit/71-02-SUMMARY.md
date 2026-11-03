---
phase: 71
plan: 02
status: passed
requirements: [TERM-02, TERM-03]
commits:
  tests: ab4a7ff2
  trace: aabc2a17
  tests-motifs: 14240463
  code: bf883c49
---

# 71-02 — contrôles du serveur Q et tenue des secrets : résumé

Q refuse tout ce que P71-D-10 refuse (méthode, Host, Origin, secret), le secret précède le routage, les corps sont bornés, toute réponse porte les en-têtes de P71-PL-16,
et l'amorçage est lu sans lien symbolique ni mode lâche puis consommé une seule fois. La suite `test-cockpit-terminal-serveur.sh` : `Résultats : 151 PASS / 0 FAIL`
(rouge sur la base : 126 PASS / 25 FAIL, tracé dans `71-02-RED-TRACE.md`). `test-cockpit-terminal-activation.sh` reste verte (40 PASS / 0 FAIL).

## Ordre des commits

| Commit | Empreinte | Contenu |
|--------|-----------|---------|
| `test(71-02)` | `ab4a7ff2` | la suite (T0 à T5, T3b, TD, 8 mutants) |
| `docs(71-02)` | `aabc2a17` | `71-02-RED-TRACE.md` |
| `test(71-02)` | `14240463` | motifs de M-ORIGIN et M-SANSORIGIN rendus indépendants du `return 403;` de la base |
| `feat(71-02)` | `bf883c49` | `vf-cockpit-terminal.mjs` (132 lignes), `vf-cockpit-terminal-amorce.mjs` (41 lignes) |

## Mutants — texte remplacé

| Mutant | Remplacement (sed sur la copie de la sortie) |
|--------|-----------------------------------------------|
| M-ORIGIN | `else if (o !== origineQ())` -> `else if (false)` (obtenu 410 au lieu de 403) |
| M-HOST | `!hotes.includes(String(req.headers.host \|\| '').toLowerCase())` -> `!String(req.headers.host \|\| '').endsWith(':' + portQ)` (410 au lieu de 403) |
| M-JETON | `!egal(req.headers['x-vf-terminal'], secret)` -> `(req.headers['x-vf-terminal'] !== undefined && !egal(…))` (410 au lieu de 401) |
| M-SANSORIGIN | `if (!page) return ` -> `if (false) return ` (410 au lieu de 403) |
| M-REJEU | `fs.unlinkSync(fichier)` -> `0` dans l'amorçage (200 au lieu de 403) |
| M-SERVI | `return res.end(html);` -> `return res.end(html + String(fs.readFileSync(fichierAmorce, "utf8")));` (1 fichier contient l'amorçage) |
| M-LOG | `log('terminal actif (127.0.0.1 seulement).');` -> `log('terminal actif ' + secret);` (1 fichier contient le secret) |
| M-URL | `egal(req.headers['x-vf-terminal'], secret)` -> `egal(req.headers['x-vf-terminal'] ?? url.searchParams.get('s'), secret)` (200 au lieu de 401) |

## Écarts et constats

- **F1 (plan)** : le plan annonçait T2.3 et T3.6 rouges sur la base ; mesurés verts (l'ordre Host puis Origin et le test de méthode de 71-01 les tenaient déjà). Gardés comme garde-fous.
- **F2 (hors périmètre, 71-01/71-03)** : `vf-cockpit-pty.py` écrit au maître et sur sa sortie en bloquant. Un POST de 65536 octets au shell (`sh -i`) fait survivre l'assistant et son shell
  au SIGTERM du serveur (H0 de la suite : survivants nommés), l'entrée standard fermée n'étant plus relue. La suite n'écrit donc jamais cette taille (la limite se mesure sans session :
  65536 -> 410, 65537 -> 413). À traiter côté assistant (écriture non bloquante ou test de l'arrêt avant chaque écriture). Non corrigé ici.
- **F3 (mineur)** : `POST /taille « 500 1000 »` rend 204 mais l'assistant ignore une colonne >= 1000 (`0 < c < 1000`). Les bornes du plan sont tenues côté serveur ; l'écart est dans l'assistant.
- **F4 (non testé)** : le contrôle du propriétaire (`st.uid === process.getuid()`) n'a pas de sonde (un autre compte n'est pas disponible dans la suite).
- Cas ajoutés au-delà du plan : `?token=`/`?secret=`/`?t=` refusés, `POST /amorce` sans Origin, Origin tierce ou Host de rebinding sans consommer l'amorçage, dossier à la place de l'amorçage, fichier de plus de 128 octets, route inconnue sans secret -> 401 (le routage précédait le secret).
- Le journal nomme la raison d'un refus (« requête refusée : Origin. »), plafonné à 50 lignes ; aucune valeur reçue.
- `TAILLE_MAX` et `CORPS_ENTREE_MAX` sont exportés par `vf-cockpit-terminal.mjs` en plus de `preparerTerminal`.

## Mesures

- Gates : `check-machine-paths.sh` 0, `check-file-size.sh --all` 0 (aucun avertissement), `check-python-isolation.sh` 0.
- Fichiers hors liste : aucun. Aucun trailer `Gate-Touche` (aucun chemin de la surface de `check-gate-touche.sh`).

## Décisions citées

P71-D-09 à D-11, P71-PL-02, P71-PL-16 (décisions du manager, `71-CONTEXT.md`) ; O3 : P71-D-21. Aucun arbitrage de Samuel invoqué.
