# 71-01 — trace du rouge de l'activation du terminal côté serveur

- date : 2026-11-03
- empreinte du commit de tests (commit A) : `41bf8b95` (`test(71-01): témoins rouges de l'activation du terminal côté serveur`)
- base : HEAD `78b29cac`, aucun module du terminal (`vf-cockpit-terminal*.mjs`, `terminal/vf-cockpit-pty.py` absents, `serve.mjs` sans le patch P25)
- commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-activation.sh > 71-01-t1.out 2>&1` — rc=1, `Résultats : 19 PASS / 21 FAIL`

Chaque rouge est tracé pour la bonne raison : clé `terminal` absente (T7.7), connexion refusée (E2E.1, E2E.2), `frame-src` absent (T8.1), module introuvable (T11.4), fichier absent de la pose (POSE.1). Les mutants rougissent en « mutant sans effet » parce que leur cible n'existe pas encore. Les valeurs longues montrent leur début et leur fin.

## Témoins rouges (21)

### FAIL — M-ACTIF — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — T7.7 — server.json porte terminal.url de forme http://127.0.0.1:<Q>, Q différent de P
- attendu : `[oui]`
- obtenu : `[non : clé terminal absente de server.json (P=51857)]`

### FAIL — T7.8 — exactement deux écouteurs, tous deux 127.0.0.1 (P et Q)
- attendu : `[127.0.0.1:1 127.0.0.1:51857 ]`
- obtenu : `[127.0.0.1:51857 ]`

### FAIL — T8.1 — CSP de / avec le drapeau = formule de v2.75.0 + « ; frame-src http://127.0.0.1:<Q> » exact
- attendu : `[default-src 'none'; script-src 'sha256-SqNl5AbBW4yotzdUKnZtwk0PlQJAMMPbg1Iugsbt4aI=' 'sha256-kd0dzoULOJtcSltky3WgH/RXLlL6ChvDaOT5UQehwpk=' ' […] -src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'; frame-src http://127.0.0.1:1]`
- obtenu : `[default-src 'none'; script-src 'sha256-SqNl5AbBW4yotzdUKnZtwk0PlQJAMMPbg1Iugsbt4aI=' 'sha256-kd0dzoULOJtcSltky3WgH/RXLlL6ChvDaOT5UQehwpk=' ' […] e'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none']`

### FAIL — P5.1 — GET /api/vf/terminal sous jeton : {"etat":"actif","port":<Q>}
- attendu : `[{"etat":"actif","port":1}]`
- obtenu : `[]`

### FAIL — E2E.1 — l'échange de l'amorçage rend 200 et un secret de 64 hexadécimaux
- attendu : `[200 secret-64-hex]`
- obtenu : `[ERREUR secret invalide : ECONNREFUSED]`

### FAIL — E2E.2 — un second échange du même amorçage rend 403 (usage unique)
- attendu : `[403]`
- obtenu : `[ERREUR ECONNREFUSED]`

### FAIL — E2E.3 — aucun assistant PTY avant GET /flux (après un échange réussi)
- attendu : `[0]`
- obtenu : `[pas de secret : échange impossible]`

### FAIL — E2E.4 — une commande envoyée par POST /entree revient dans le flux (TRACEUR-OK en moins de 10 s)
- attendu : `[TROUVE]`
- obtenu : `[pas de secret : flux impossible]`

### FAIL — E2E.5 — la ligne de commande de l'assistant contient « -I » et « vf-cockpit-pty.py »
- attendu : `[oui]`
- obtenu : `[non : aucun assistant]`

### FAIL — T7.10 — l'amorçage et le secret ne figurent ni dans le journal du serveur ni dans server.json
- attendu : `[0]`
- obtenu : `[pas de secret : mesure impossible]`

### FAIL — E2E.6 — à l'arrêt du serveur, l'assistant et le shell disparaissent en moins de 5 s
- attendu : `[aucun]`
- obtenu : `[rien à surveiller (assistant=aucun shell=aucun)]`

### FAIL — M-ECOUTE0 — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — M-FRAMESRC — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — T11.4 — plateforme win32 : indisponible, aucun serveur créé, routeP rend {"etat":"indisponible"}, message « Terminal indisponible sous Windows. »
- attendu : `[indisponible=true actif=false ecouteurs=0 corps={"etat":"indisponible"} message=true]`
- obtenu : `[module introuvable]`

### FAIL — M-WIN — mutant sans effet (cible absente ou inchangée)
- attendu : `[effet]`
- obtenu : `[sans effet]`

### FAIL — POSE.1 — l'engine pose terminal/vf-cockpit-pty.py dans les scopes project, user et local, identique à la source (cksum)
- attendu : `[project:identique user:identique local:identique]`
- obtenu : `[project:absent user:absent local:absent]`

### FAIL — POSE.2 — serveur INSTALLÉ (scope project) : échange, flux, TRACEUR-OK, la ligne de commande de l'assistant cite le chemin posé
- attendu : `[ok]`
- obtenu : `[pas de second écouteur (terminal arrêté)]`

### FAIL — POSE.3 — moteur sans terminal/ : /api/vf/terminal rend {"etat":"arrete"}
- attendu : `[{"etat":"arrete"}]`
- obtenu : `[]`

### FAIL — POSE.3 — le journal dit « assistant du terminal introuvable »
- attendu : `[assistant du terminal introuvable]`
- obtenu : `[VibeFlow: http://127.0.0.1:51867 / asking via Claude Code CLI 2.1.317 (Claude Code) (/Users/samuel/.local/bin/claude)]`

### FAIL — M-HORS-MOTEUR — mutant sans effet (assistant absent de terminal/ dans le cache)
- attendu : `[effet]`
- obtenu : `[sans effet]`

## Contrôles positifs verts (19)

- T7.0 — témoin : le lab se construit, le serveur démarre, GET /api/vf/etat rend 200 sous le jeton de server.json
- T7.1 — sans le drapeau, GET /api/vf/terminal sous jeton valide rend 404
- T7.2 — / : CSP = formule de v2.75.0 appliquée aux scripts de la page servie
- T7.2 — / : aucune sous-chaîne frame-src
- T7.2 — /project.html : CSP = formule de v2.75.0 appliquée aux scripts de la page servie
- T7.2 — /project.html : aucune sous-chaîne frame-src
- T7.2b — la ligne « const csp = » de la sortie serve.mjs est la copie figée de v2.75.0
- T7.3 — témoin : la mesure des écouteurs voit le port de P
- T7.3 — sans le drapeau, un seul écouteur pour le PID du serveur
- T7.4 — témoin : server.json porte la clé port
- T7.4 — sans le drapeau, server.json n'a pas de clé terminal
- T7.5 — témoin : les deux pages servies sont lues en entier
- T7.5 — pages servies sans « VibeFlow (71- » ni « vf-term »
- P5.1 — sans jeton : 403
- E2E.3 — témoin : pgrep -P voit un enfant du shell de la suite
- POSE.3 — aucun second écouteur
- POSE.3 — aucun processus enfant (aucun Python lancé)
- POSE.4 — le vrai ~/.claude est inchangé (fichiers du cockpit)
- H0 — aucun serveur ni Chrome de cette suite ne survit (avant : 0)
