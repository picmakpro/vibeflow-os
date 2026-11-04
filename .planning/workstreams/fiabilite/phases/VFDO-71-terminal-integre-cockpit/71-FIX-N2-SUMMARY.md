# 71-FIX-N2 — le lanceur n'exécute jamais un binaire du lab (P71-D-29)

Correction ciblée de sécurité N2. Validation de Samuel : P71-D-29 (AskUserQuestion, session principale Claude Code, 2026-11-04, « Valider N1 et N2 (Recommandé) »).
Fichiers : `vf-cockpit.mjs`, `vf-cockpit-paths.mjs`, `vf-cockpit-planning.mjs`, `vf-cockpit-build.mjs`, `vf-cockpit-who.mjs`, `vf-cockpit-live.mjs`, suite `test-cockpit-terminal-lanceur.sh`, README et CHANGELOG (phrases sur le PATH).

## Cause et choix

Le lanceur tourne depuis la racine du lab ; un nom nu lancé sous `PATH=.:…`, `:…`, `…:` ou `bin:…` exécutait `<lab>/<nom>`. Même famille que F3.
Choix motivé : résolution en chemin absolu (`resoudreBinaire`, `vf-cockpit-paths.mjs`) dans les seuls éléments absolus du PATH, plutôt qu'un PATH assaini posé une fois : un PATH assaini transmis au serveur arriverait au shell du terminal (P71-D-03). Seul le moteur d'assemblage (aucun shell) reçoit un PATH assaini (`pathAssaini`), parce qu'il lance `git` par son nom dans du code vendu qu'on ne modifie pas.
Introuvable : `ouvrir` dit « ENOENT » par le chemin M6/N6b inchangé (marche à suivre, page à ouvrir à la main) ; `ps` absent refuse l'arrêt avec un message ; `git`/`bash` absents : résultat vide comme avant.

## Inventaire (spawn / execFile / execFileSync à nom nu)

| fichier:ligne | binaire | avant | après |
|---|---|---|---|
| vf-cockpit.mjs:72 | `ps` | nom nu | chemin absolu, refus dit si absent |
| vf-cockpit.mjs:109 | `open` / `xdg-open` (`cmd` sous Windows : ComSpec) | nom nu | chemin absolu, ENOENT dit si absent |
| vf-cockpit.mjs:166 | ouvreur du SERVEUR (serve.mjs vendu, `open` nom nu depuis le lab) | serveur lançait l'ouvreur sans `--terminal` | `--no-open` toujours ; le lanceur ouvre (`ouvrir`), y compris sans `--terminal` |
| vf-cockpit-paths.mjs:141 | `git` | nom nu | chemin absolu |
| vf-cockpit-planning.mjs:115 | `git` | nom nu | chemin absolu |
| vf-cockpit-build.mjs:28 | enfants du moteur (code vendu : `git` nom nu, skills/…/lib/common.mjs) | PATH hérité | PATH assaini (éléments absolus) |
| vf-cockpit-who.mjs:17 | `git`, `bash` | nom nu | chemin absolu |
| vf-cockpit-live.mjs:61 | `bash` | nom nu | chemin absolu |
| vf-cockpit-terminal-session.mjs:86 | `python3` | déjà corrigé (B2) | inchangé |

Non modifiés (hors périmètre, à connaître) : le moteur VENDU `skills/cockpit-moteur` lance encore des noms nus à la demande (serve.mjs : `which`, CLI `claude`/`codex` pour les questions) ; `driver-lock.sh`, script bash, utilise ses propres commandes. Les corriger demande de modifier le vendu (empreintes de `synchro.sh`) ou de relayer le PATH d'origine au shell (`vf-cockpit-terminal-env.mjs`) : mandat séparé.

## Preuves

- Témoin rouge sur `abb7cd8f` (suite jouée sur `git archive` de cette tête) : L16 `obtenu: open=1 xdg-open=0 ps=104 git=15 bash=9` sous `.:`, `:`, `bin:` ; `PATH=…:` final sans binaire système : `ps=104 git=15 bash=9` ; témoins d'ouverture à vide (`ouvert=non`, `[]`). 70 PASS / 12 FAIL.
- Vert : L16 `open=0 xdg-open=0 ps=0 git=0 bash=0` pour les quatre PATH ; témoins (ouvreur factice absolu atteint, avec et sans `--terminal`). 82 PASS / 0 FAIL.
- Mutants (copies du module) : M-OUVRE-NOMNU, M-PS-NOMNU, M-GIT-NOMNU, M-WHO-NOMNU, M-SERVE-OUVRE, M-PS-FINAL : tous rouges détectés (marqueur du leurre exécuté). M-OUVREUR-ERREUR conservé : le cas « ouvreur absent » ne passe plus par un spawn, un L14 « ouvreur présent mais inlançable » (interpréteur inexistant) le garde rouge.
- Les suites ne lancent jamais l'ouvreur du poste : ouvreurs factices dans un dossier absolu du PATH de test.

## Suites

lanceur 82/0 · activation 40/0 · terminal-serveur 208/0 · serveur 64/0 · securite 88/0 · who 68/0 · assemblage 40/0 ; gates : check-machine-paths 0, check-file-size --all 0, check-python-isolation 0.
