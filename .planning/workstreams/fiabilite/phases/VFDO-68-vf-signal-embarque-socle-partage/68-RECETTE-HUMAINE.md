# 68 — Recette de la pane vf-signal embarquée (plan 68-10, tâche 2)

**Statut : FAITE PAR JUGES — 2026-11-04 (étapes 4 et 5 reportées après la PR, P68-D-35)**

## Méthode

Arbitrage de méthode de Samuel (session principale Claude Code, 2026-11-04), mot pour mot :
« si c'est pour me demande ca ca sert a rien, lance des juge qui prenne des screenshot pour les tests, appele moi seulement si tu ne peux pas faire (gout, avis humain indispensable) ».

La recette décrite par le plan (Samuel dicte son retour à chaque étape) est donc remplacée par des **juges frais**. Chacun a son propre Chromium headless (`playwright`) et un pilote pseudo-terminal dont le flux est rendu dans xterm.js. Un juge ne corrige rien et ne modifie ni le dépôt ni le compte. Trois passages :

- **v1** : recette complète des douze étapes, deux juges (volet web et `claude -p` ; volet TUI). Claude Code `2.1.318`. Branche à `6b76c42c` au départ ; trois commits sont arrivés pendant le volet TUI (`072bcb86`, `9357e139`, `cde56d40`) et ont provoqué un rechargement à chaud du plugin dans une session.
- **v2** : vérification des corrections du premier tri, deux juges (pane et web ; lanceur et cascade de vie). Tête `a3a09bb4` (la branche a avancé jusqu'à `a79ffa1e` sans toucher le code de la pane).
- **v3** : dernière vérification du second tri, un juge. Tête `0d4f8ae0`.

**Les preuves vivent dans un scratchpad éphémère** (dossier temporaire de la session) : captures `.png`, sorties `.txt`, mesures `.json`. Elles ne sont pas versionnées. Base commune des chemins ci-dessous :
`/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68` (sous-dossiers `web/`, `tui/` pour la v1 ; `v2/` et `v3/` pour les passes suivantes).

Sont seuls renvoyés à Samuel : ce qui relève du goût ou d'un avis humain, et ce qu'un juge ne peut pas jouer (étapes 4 et 5, retrait de l'ancien mod).

Légende des numéros : R1 à R15 sont les écarts de la v1 (numérotation du tri), N1 à N8 ceux de la v2. Les juges de la v1 avaient leur propre numérotation (E1 à E8 pour le volet TUI) ; le tri complet figure plus bas.

## Les douze étapes

### Étape 1 — Préparation (version de Claude Code, ancien mod)

- **Vérifié** : lancement `claude --plugin-dir <dépôt>/plugin` dans un lab où le module `cockpit` est installé ; version de Claude Code ; état de l'ancien mod.
- **Verdict v1** : conforme. Claude Code `2.1.318`. Registre du compte : `cockpit=v1.0.1`. L'ancien mod existe dans les mods du compte et est activé dans les réglages (`vf-signal@vf-mods`), tout comme `vibeflow@vibeflow-os`.
- **Après correction** : sans objet.
- **Preuve** : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s1-demarrage-env-herite.png` ; `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/plugin-list.txt`.
- **Décision** : version minimale de Claude Code, voir AD-2 (P68-D-41) dans « Après recette ».

### Étape 2 — Terminal plein écran, pane en dock (thèmes sombre puis clair)

- **Vérifié** : en-tête (phase active, « à recetter » écrit, mission courante), badge de retard sur un arbre resté derrière `main`, une ligne par worktree avec branche et phase, couleurs Graphite.
- **Verdict v1** : sombre en écart, clair conforme. Le badge « en retard de 110 commits sur main, dernier fetch il y a 3 h », « (à recetter) » et la mission courante sont présents. Écarts : « (à faire) » en jaune au lieu de `--text-4`, libellé et couleur d'une ligne de worktree venant de deux sources (R1) ; ligne de jalon en markdown brut, coupée au milieu d'un mot (R6) ; worktree hors dépôt affiché en chemin relatif `../../` (R9). Le thème clair (réglage de session `{"theme":"light"}`) ne contient que la palette claire (`#946000`, `#157a3a`, `#666666`).
- **Après correction** : R1, R6 et R9 corrigés en v2 (worktree de phase 71 « (à recetter) » dans la même teinte `--sev-medium` que « (en cours) » ; jalon sur une ligne `vibeflow-v2.0 · « le cockpit VibeFlow »` ; worktree hors dépôt affiché par son nom de dossier). En v2, N1 relevé (âges négatifs « -4 s ») et N8 (« bloqué » en jaune au lieu de `--sev-high`) ; corrigés en v3, sans régression de l'en-tête. N8 vérifié en thème sombre seulement (`#f28b8b`), le thème clair n'a pas été rejoué.
- **Preuve** : v1 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s2-b-pane-dock-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s2-c-pane-defile1-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s2-e-pane-bas-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s5-b-retard-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s5-c-phase71-courant-sombre.png`, clair `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s4-a-clair-dock.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s4-b-clair-mission.png` ; v2 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s1-a-dock-entete-r1-r6-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s1-a-dock-entete-couleurs.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s1-e-macro-r6-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s2-a-r9-worktree-dehors-sombre.png` ; v3 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a1-dock-entete-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a2-toi-noeud-bloque-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a2-toi-couleurs.txt`.
- **Décision** : P68-D-35 (R1, R6, R9), P68-D-38 (N1, N8). N5 (la vue macro marque « à faire » des phases que leurs worktrees disent « en cours ») : BACKLOG.

### Étape 3 — Terminal étroit (pane inline, 72 × 30)

- **Vérifié** : forme compacte, une ligne d'en-tête, vue, « toi ».
- **Verdict v1** : conforme, avec une réserve cosmétique : la ligne d'action n'écrit pas le mot « toi » en forme compacte (R10) ; l'en-tête passe sur deux lignes à 72 colonnes.
- **Après correction** : R10 corrigé en v2 (« ■ toi · nœud bloqué · … » présent à 72 colonnes).
- **Preuve** : v1 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s3-a-etroit-equipe-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s3-b-etroit-mission-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s3-c-etroit-toi-sombre.png` ; v2 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s1-g-compact-72-r10-toi-sombre.png`.
- **Décision** : P68-D-35 (R10).

### Étape 4 — VS Code (extension)

- **Vérifié** : rien. Un juge ne peut pas piloter l'extension VS Code.
- **Verdict v1** : injouable par un juge (R15).
- **Après correction** : sans objet. **Reporté après la PR.**
- **Preuve** : aucune.
- **Décision** : P68-D-35 (R15 reporté après la PR). À jouer par Samuel.

### Étape 5 — Mobile

- **Vérifié** : rien. Un juge ne peut pas piloter la surface mobile.
- **Verdict v1** : injouable par un juge (R15).
- **Après correction** : sans objet. **Reporté après la PR.**
- **Preuve** : aucune.
- **Décision** : P68-D-35 (R15 reporté après la PR). À jouer par Samuel.

### Étape 6 — Vue Équipe (identifiants `who@2` / `$.agent.list()`)

- **Vérifié** : un agent d'une autre session apparaît sans geste ; un agent de la session a « voir » et « arrêt » ; correspondance des identifiants.
- **Verdict v1** : écart. Les agents des autres sessions apparaissent sans geste. La correspondance est constatée sur un agent réel (`a3616429fc0075a73` : « voir » et « demander l'arrêt »). Écarts : un agent vivant de la session est resté marqué « terminé » environ 4 minutes, sans ses gestes, bien que Claude Code le listât encore (R2) ; 185 travailleurs listés dont 164 terminés, les actifs noyés sur 19 à 38 pages de défilement (R3). Aucun rapprochement par description ou par rôle n'a été ajouté (procédure du plan).
- **Après correction** : R2 et R3 corrigés en v2 (un sous-agent de près de 5 minutes garde « voir » et « demander l'arrêt » jusqu'à sa troisième sonde sur quatre ; actifs en tête, puis nœuds en attente, puis « ▸ 186 terminés » replié). N1 (âges négatifs) et N3 (types « lock », « dag-node », « exec » en anglais) relevés en v2, corrigés en v3 (types « verrou », « nœud », « exécution », aucun type anglais sur toutes les pages ; 30 échantillons, 9 âges négatifs dans les données brutes, aucun affiché). Reliquat v3 : la vue Équipe de la pane écrit encore « depot » brut pour un verrou de dépôt (`actif · depot · 46 s`, source `vf-cockpit-who.mjs` ligne 82) — **en correction (passe finale)**. Pas de régression de la vue Équipe.
- **Preuve** : v1 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s2-h-equipe-autre-session-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s2-j-equipe-agent-actif-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s2-i-equipe-agent-termine-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s2-j-equipe-agent-actif-cur.txt` ; v2 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s1-b-equipe-r2-agent-actif-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s1-d-equipe-r2-apres-premier-tour-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s1-c-equipe-r3-termines-replies-sombre.png` ; v3 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a5-n1-equipe-age-borne-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a5-n1-echantillons.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a4-equipe-haut-pages.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a8-equipe-non-regression-sombre.png`, reliquat `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/b2-n2-equipe-verrou-depot-brut-sombre.png`.
- **Décision** : P68-D-35 (R2, R3), P68-D-38 (N1, N2, N3).

### Étape 7 — Mission abandonnée (pane et carte Projet du cockpit web)

- **Vérifié** : mission dont un nœud n'a jamais été refermé et sans verrou : grisée, « abandonnée, nœuds non refermés » ; carte Projet web identique. Cascade de vie : verrou de phase, de compartiment, de dépôt.
- **Verdict v1** : écart, sans gravité bloquante. La carte « Mission 59 » dit bien « 11/15 nœuds · abandonnée, nœuds non refermés » et ne dit jamais « en cours ». Mais la pastille de statut dit « À faire » (R5) ; le texte du pied déborde de 4,5 px dans les deux thèmes et pousse la pastille hors de la carte (R7) ; le panneau latéral ne dit pas l'état de la mission et ne distingue pas les statuts des nœuds (R8). Le cas « état inconnu » (verrous illisibles) ne s'est pas présenté, il est prouvé par les suites.
- **Après correction** : R5 et R7 corrigés en v2, R5 rejugé en v3 sur la tête finale (pastille « Abandonnée », gris neutre, dans la carte, deux thèmes ; mesures `pillInside: true`, `footOverflow: false`). R12 (famille « depot » du badge de portée du verrou) corrigé sur le badge en v2. Cascade de vie prolongée au dépôt (Q3, P68-D-33) vérifiée en v2 : sans verrou « abandonnée », avec `acquire --depot` « en cours » (en-tête, vue mission, vue macro, carte Projet web sombre et clair), de nouveau « abandonnée » après relâche. R8 **reporté** en Phase 70. N6 (hors branche `feat/phase-N`, une mission abandonnée n'apparaît pas dans la pane) : BACKLOG ; N7 (badge « Personne » alors qu'un verrou est tenu, visible seulement au survol) inchangé, choix de la Phase 69.
- **Preuve** : v1 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e7-sombre-carte-mission59.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e7-clair-carte-mission59.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e7-sombre-page-phase59.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e7-clair-page-phase59.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e7-cmp-sombre-m69-carte0.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e7-etat-worktree-reel.txt` ; v2 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/web/r57-dark-carte-mission59.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/web/r57-light-carte-mission59.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/web/r57-dark-mesures.json`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/web/r12-projet-badge.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/q/q3-b-sans-verrou-abandonnee-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/q/q3-c-verrou-depot-en-cours-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/q/q3-f-web-tenu-sombre-3-carte-mission.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/q/q3-g-web-tenu-clair-3-carte-mission.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/q/q3-i-pane-apres-relache-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/q/q3-socle.txt` ; v3 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/web/r5-dark-carte-mission59.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/web/r5-light-carte-mission59.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/web/r5-dark-mesures.json`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/web/n2-lab-sombre-mesures.json`.
- **Décision** : P68-D-35 (R5, R7, R8, R12), P68-D-33 (cascade de vie, Q3), P68-D-36 (compartiment périmé, dépôt tenu : décision du manager), P68-D-38 (N2, N6, N7).

### Étape 8 — Bouton « Ouvrir le cockpit »

- **Vérifié** : le cockpit s'ouvre, l'adresse s'affiche ; lanceur pris hors du lab.
- **Verdict v1** : conforme. L'adresse affichée est `http://127.0.0.1:4415/`, stable sur trois lancements (serveur vivant, après un `stop`, au `status`), la page répond 200.
- **Après correction** : P68-D-34 (« Rien sous le lab ») vérifié en v2 : la touche `o` ouvre le cockpit sur le serveur du lab (réponse 200) et le marqueur du lanceur planté sous le lab n'apparaît jamais ; témoin positif : lancé à la main, ce même lanceur écrit bien le marqueur.
- **Preuve** : v1 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/etape8-sorties.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/etape8-url-bouton.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e8-cockpit-ouvert.png` ; v2 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/q/q4-pane-cockpit-ouvert-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/q/q4-processus.txt`.
- **Décision** : P68-D-34 (Q4), P68-D-37.

### Étape 9 — Gating (registre sans `cockpit=`)

- **Vérifié** : aucun registre ne porte `cockpit=` : aucune pane, aucun bandeau, aucune commande.
- **Verdict v1** : conforme. Sans `cockpit=` dans aucun des deux registres (projet et compte), `/vf-signal` est inconnue. Témoin positif : même montage avec `cockpit=v1.2.0`, la commande est présente. Le juge a changé `HOME` pour la seule session via `--settings '{"env":{"HOME":"<home factice>"}}'`, sans écrire aucun fichier du compte (remplacer `HOME` dans le shell coupe l'authentification). La pane et le bandeau ne s'observent pas en mode `-p` : ils sont couverts par les suites E2, E3 et `session-sans-registre`.
- **Après correction** : sans objet, non rejouée.
- **Preuve** : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/etape9-gating.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e9-runC.out`.
- **Décision** : aucune.

### Étape 10 — Ancien mod présent

- **Vérifié** : le signal s'affiche ; deux panes constatées ou non ; décision de retrait de l'ancien mod.
- **Verdict v1** : écart (R14), sans correctif. Le signalement de l'ancien mod s'affiche (bas de la pane, dock et inline) et une seule pane apparaît. Au démarrage l'ancien mod échoue (`/vf-signal` refusée). Mais après un rechargement à chaud du plugin (« vibeflow: reloaded »), la pane a montré le rendu de l'ancien mod (bleu, « lab · sans jalon ») jusqu'au `/vf-signal` suivant ; la réponse `vibeflow+vf-signal` à la commande indique que les deux plugins traitent `command.run`. Cas d'usage de développement (`--plugin-dir`). En `claude -p`, un seul brief est rendu, contenu identique à celui du mod embarqué seul.
- **Après correction** : aucun correctif. Samuel retire l'ancien mod lui-même (geste à lui). Information v2 : le signalement « ancien mod vf-signal détecté » s'affiche même quand l'ancien mod est désactivé dans les réglages, car la détection lit sa présence sur le disque.
- **Preuve** : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s2-e-pane-bas-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/tui/s5-a-phase71-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e12-temoin-ancien-mod-seul.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e12-embarque-seul.txt`.
- **Décision** : P68-D-35 (R14 sans correctif, retrait par Samuel).

### Étape 11 — Sans `node` dans le PATH

- **Vérifié** : « node introuvable dans le PATH ».
- **Verdict v1** : écart (R4). `claude` est un binaire natif et tourne sans `node` ; la pane dit « node introuvable dans le PATH » (suites K2 et A2f, 95 tests, 0 échec). Mais en session réelle, `claude -p "/vf-signal brief"` rendait un brief presque vide (« temps de la boucle : inconnu », « contexte : ? % ») sans dire pourquoi : `brief()` ne recevait pas l'erreur du socle.
- **Après correction** : R4 corrigé en v2. Avec un PATH amputé, le brief écrit `- socle : node introuvable dans le PATH` ; témoin avec `node` à côté.
- **Preuve** : v1 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/etape11-sans-node.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e11-claude-plugin-test.txt` ; v2 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/r4-sans-node.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/r4-temoin-avec-node.txt`.
- **Décision** : P68-D-35 (R4).

### Étape 12 — Passage non interactif : `claude -p --plugin-dir <dépôt>/plugin "/vf-signal brief"`

- **Vérifié** : la chaîne `node` + émetteur en session réelle (P68-D-14), sortie consignée telle quelle.
- **Verdict v1** : conforme, code de sortie 0. Sortie de `claude -p --plugin-dir <dépôt>/plugin "/vf-signal brief"` sous Claude Code `2.1.318` : 94 lignes, phase 68 « en cours », plans 9/13, verrous du socle, MISSION-68 et ses nœuds, attribuée `vibeflow+vf-signal:`. Réserve cosmétique : la ligne « jalon » était tronquée au milieu d'un mot avec du `**` (R6). État identique à celui du vrai worktree (MISSION-59 « abandonnée », MISSION-68 « en cours » parce que son verrou est tenu).
- **Après correction** : R6 corrigé en v2 (brief ligne 4, `vibeflow-v2.0 · « le cockpit VibeFlow »`). R11 (statut anglais) : en v2 le brief interactif affichait encore `running` pour un agent (`derive.ts` ligne 161) ; corrigé en v3 (`general-purpose · en cours · …`). Reliquats v3 sur le brief interactif : la clé brute `seven_day : 35 %` là où la pane dit « 7 j 35 % », et « 1 outils » sans accord — **en correction (passe finale)**.
- **Preuve** : v1 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/etape12-claude-p.txt` (sortie telle quelle), `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e12-embarque-seul.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e12-git-avant.txt`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/web/e12-git-apres.txt` ; v2 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/tui/s1-f-brief-interactif-sombre.png` ; v3 `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a7-r11-brief-agent-en-cours-sombre.png`, `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v3/tui/a6-brief-haut-pages.txt`.
- **Décision** : P68-D-14, P68-D-35 (R6, R11), P68-D-38 (R11 comme P68-D-35).

## Tri complet

### Premier tri (R1 à R15) — P68-D-35

Réponse de Samuel (AskUserQuestion, session principale Claude Code, 2026-11-04), mot pour mot : « Tout selon les recos (Recommandé) ».

| # | Écart | Sort |
|---|---|---|
| R1 | Libellé et couleur d'une ligne de worktree venant de deux sources | corrigé (v2) |
| R2 | Agent vivant de la session marqué « terminé », gestes perdus | corrigé (v2) |
| R3 | 164 agents terminés noient les actifs dans la vue Équipe | corrigé (v2) |
| R4 | Brief sans `node` ne dit pas pourquoi | corrigé (v2) |
| R5 | Pastille « À faire » sur une mission abandonnée (carte web) | corrigé (v2, rejugé v3) |
| R6 | Ligne de jalon en markdown brut, coupée au milieu d'un mot | corrigé (v2) |
| R7 | Pied de la carte Mission qui déborde, pastille poussée dehors | corrigé (v2) |
| R8 | Panneau latéral web sans l'état de la mission ni des nœuds | **reporté en Phase 70** |
| R9 | Worktree hors dépôt en chemin relatif `../../` | corrigé (v2) |
| R10 | Mot « toi » absent en forme compacte | corrigé (v2) |
| R11 | « blocked » en anglais (bandeau, ligne « toi »), puis statuts bruts du brief et du sous-titre web | corrigé : bandeau et ligne « toi » en v2, brief et sous-titre web en v3 |
| R12 | « depot » sans accent (badge de portée du verrou) | corrigé sur le badge (v2) ; famille N2 |
| R13 | `plugin/tsconfig.json` généré au chargement et non ignoré | corrigé (v2 : `git status` reste vide) |
| R14 | Ancien mod qui reprend la pane après un rechargement à chaud | **sans correctif** : Samuel retire l'ancien mod lui-même |
| R15 | Étapes 4 (VS Code) et 5 (mobile), injouables par un juge | **reporté après la PR** |

Preuves de R13 : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/recette-68/v2/r13-git-apres.txt` ; trace rouge puis vert (`git check-ignore` rc 1 puis 0) dans `68-FIX-Q3-RED-TRACE.md`.
Verdict du juge v2, tel qu'il l'a écrit : douze des treize points corrigés, R11 persiste.

### Second tri (N1 à N8) — P68-D-38

Réponse de Samuel (AskUserQuestion, session principale Claude Code, 2026-11-04), mot pour mot : « Tout selon les recos (Recommandé) ».

| # | Écart | Sort |
|---|---|---|
| N1 | Âges négatifs dans la vue Équipe (« -4 s ») | corrigé (v3) : bornés à 0 |
| N2 | « depot » sans accent, âge du verrou incohérent, doublon sur la ligne de verrou | corrigé (v3) sur la ligne de verrou de la pane et le panneau web ; **reliquat dans la vue Équipe de la pane, en correction (passe finale)** |
| N3 | Types de la vue Équipe en anglais (« lock », « dag-node », « exec ») | corrigé (v3) |
| N4 | Panneau Phase web : « Ligne de ROADMAP » avec `**` bruts (antérieur à la 68) | BACKLOG |
| N5 | Vue macro : phases « à faire » que les worktrees disent « en cours » ou « à recetter » | BACKLOG |
| N6 | Hors branche `feat/phase-N`, mission abandonnée absente de la pane | BACKLOG |
| N7 | Badge « Personne » alors qu'un verrou est tenu | inchangé (choix de la Phase 69) |
| N8 | « nœud bloqué » en jaune au lieu de `--sev-high` | corrigé (v3), thème sombre seulement vérifié |

Les âges d'un verrou suivent le battement partout (P68-D-39, décision du manager ; contrats `who@2` et `signal@1` inchangés). R11 a été traité comme au premier tri.

### Reliquats de la v3

Le juge v3 a relevé trois reliquats, sans régression :

1. **N2 dans la vue Équipe de la pane** (« depot » brut pour un verrou de dépôt) — **en correction (passe finale)**. Le manager mettra à jour ce statut après intégration.
2. **Brief interactif** : clé brute `seven_day : 35 %` et « 1 outils » sans accord — **en correction (passe finale)**. Le manager mettra à jour ce statut après intégration.
3. **Unités d'âge différentes dans le tiroir web** : « 223 s » dans l'en-tête et « 4 min » dans la ligne du dessous (cohérents à l'arrondi près) — **non corrigé**, affaire de goût, non remontée à Samuel.

## Après recette

### Relecture adverse (SOBR-04) et arbitrages AD-1 et AD-2

Relecture adverse du diff de la phase par un agent frais qui n'a écrit aucun commit de la 68 : `68-RELECTURE-ADVERSE.md` (tête `0d4f8ae0`). Verdict : aucun constat bloquant, trois constats à décider (AD-1 à AD-3), décidés avant le merge. Le périmètre de release est fixé par P68-D-31 (module seul, racine groupée) : aucun bump racine, aucun tag, aucune release ici.

- **AD-1 — coût du rafraîchissement du mod** (environ 2 s de CPU et 120 Ko par appel de l'émetteur, relancé toutes les 10 s, y compris pane fermée et en `claude -p`). Arbitrage de Samuel (AskUserQuestion, session principale Claude Code, 2026-11-04) : « Rafraîchir si pane ouverte (Recommandé) ». Effet : rafraîchissement continu seulement pane ouverte et session interactive ; pane fermée, après un tour et au plus une fois par minute ; jamais d'attente de l'émetteur au démarrage. Décision : P68-D-41.
- **AD-2 — plancher de version de Claude Code** (sous `2.1.181` le plugin entier journalise une erreur de chargement des hooks ; sous `2.1.318` le module de hooks se charge ; le plancher exact n'est pas mesuré). Arbitrage de Samuel (même canal, même date) : « L'écrire sans mesurer (Recommandé) ». Effet : README et notes de la release groupée disent « vérifiée sous 2.1.318, non chargée sous 2.1.181 ». Décision : P68-D-41.
- **AD-3 — `VF_COCKPIT_SCRIPTS_DIR` hérité par l'émetteur** (un `driver-lock.sh` planté sous le lab s'exécutait, sondé). Décision du manager appliquant « Rien sous le lab », confirmée par Samuel (« d'accord », AskUserQuestion, session principale Claude Code, 2026-11-04) : le mod pose la variable à vide dans l'environnement de l'émetteur. Décision : P68-D-40.

### Ce qui reste hors des juges

- Étapes 4 (VS Code) et 5 (mobile) : à jouer par Samuel après la PR (R15).
- Retrait de l'ancien mod : geste de Samuel (R14).
- R8 en Phase 70 ; N4, N5, N6 au BACKLOG (`.planning/BACKLOG.md`).

### Limites de la preuve

- Les gates `check-machine-paths.sh` rejoués sous macOS peuvent répondre vert à vide ; seule la CI Linux fait foi (rapport de mission `.planning/missions/2026-11-04-phase-68-execution.md`).
- La couverture sécurité repose sur les revues avec sondes : les deux audits `vf-auditer` se sont figés sans verdict (même rapport).
- N8 n'a pas été rejoué en thème clair (couleur attendue `#c94a4a`).
