**Statut : À JOUER — écrite le 2026-11-03 par l'exécuteur de 71-09 ; à jouer par Samuel en session principale (macOS). Aucune étape n'a été jouée.**

# 71-RECETTE-HUMAINE — recette de TERM-09 et de UI-SPEC §15

Plan : `71-09-PLAN.md`, tâche 1 (point de contrôle `blocking-human`). Code figé à `227be6c5` (branche `feat/phase-71-terminal`).
Critère d'usage de Samuel (P71-D-01, P71-D-06, arbitrages de Samuel, AskUserQuestion, session principale Claude Code, 2026-11-03) :
`claude` lancé dans le terminal du tiroir, à la racine du lab, avec son `CLAUDE.md` et ses skills, comme dans un vrai terminal ;
une seule fenêtre.

## Règle de conduite (mémoire « Recette pas à pas, retours dictés »)

Une étape à la fois. Celui qui mène la recette présente l'étape, attend la réponse de Samuel, la consigne **mot pour mot** dans
« Réponse de Samuel », note le verdict (`conforme`, `écart`, `non jouée` avec sa raison), puis passe à la suivante. Le tri des
écarts se fait à la fin. Un écart n'est jamais corrigé pendant la recette : il est remonté au manager (ADR-031). Un contournement de la
recette n'est valable que s'il est demandé explicitement par Samuel ; il est alors consigné avec son canal et sa date, et la
première ligne de ce fichier passe à `**Statut : CONTOURNÉE — <canal>, <date>**`. Quand toutes les étapes sont jouées, la première
ligne passe à `**Statut : FAITE — <date>**` (ou `**Statut : ÉCARTS — <date>**`).

## Préparation (par celui qui mène la recette, avant l'étape 1)

Dans le worktree de la phase, à la racine du lab :

1. Arrêter un éventuel cockpit vivant : `node plugin/cockpit/scripts/vf-cockpit.mjs stop --lab .`
2. Lancer : `node plugin/cockpit/scripts/vf-cockpit.mjs open --terminal --rebuild --lab .`
3. Vérifier que le lanceur a rendu 0 et que `.vibeflow/cockpit/.cache/server.json` porte la clé `terminal`.
4. Noter ci-dessous le navigateur par défaut du poste (71-RESEARCH A7 : seul Chrome est mesuré par les suites) et sa version.

Navigateur par défaut : _à renseigner_ · Version : _à renseigner_ · Poste (macOS) : _à renseigner_

## Étapes

### Étape 1 — Une seule fenêtre (UI-SPEC §2.1, P71-D-01)

L'onglet ouvert par le lanceur arrive sur la page Projet. La pastille « Terminal » est en bas à gauche. Aucune deuxième fenêtre ni
deuxième onglet n'a été ouvert.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 2 — Ouvrir le tiroir, aspect d'un vrai terminal (§15.2)

Cliquer la pastille (ou Ctrl+Maj+Espace). Le terminal a l'aspect d'un vrai terminal (police à chasse fixe, fond sombre). Taper `pwd` :
la racine du lab. Taper `ls -G` : des couleurs lisibles.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 3 — `claude` plein écran, couleurs, cadres (§15.3, P71-D-06)

Taper `claude`. L'interface plein écran démarre ; les couleurs sont là ; les cadres (`│ ─ ┌`) sont continus, sans coupure verticale.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 4 — `claude` voit le `CLAUDE.md`, les skills, une commande VibeFlow (TERM-09, P71-D-01)

Dans `claude` : demander ce que dit le `CLAUDE.md` du dépôt sur la discipline de release (il doit le citer). Taper `/` : les skills de
VibeFlow sont proposés. Lancer `/vf-cockpit status` : il rend l'adresse et le PID du cockpit.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 5 — Redimensionnement et Ctrl-C (§15.4, P71-D-06)

Redimensionner le tiroir à la souris (poignée), puis au clavier (poignée focalisée, flèches haut et bas) : `claude` se redessine à chaque
taille. Ctrl-C dans `claude` se comporte comme dans un terminal. Quitter `claude`.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 6 — Touches et clavier français (§15.5, §15.6)

Ctrl+R, Ctrl+W, Échap, Tab et les flèches atteignent le shell. Les caractères `{ [ ] | \ ~ @`, tapés avec Option sur le clavier français,
arrivent au shell.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 7 — Sortir du terminal au clavier, rouvrir (§15.4, §15.5)

Ctrl+Maj+Espace depuis le terminal ferme le tiroir et rend le focus à l'ouvreur. Rouvrir : le shell et son historique sont là.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 8 — Rechargement de la page et reprise (§15.4, §6.1, P71-D-05)

Recharger la page dans les 30 s : même hauteur de tiroir, même session (l'historique est visible). Ouvrir ensuite un second onglet du
cockpit et y ouvrir le tiroir : la carte « Terminal déjà ouvert » s'affiche.

Si `claude` tourne en plein écran au moment du rechargement, il peut s'afficher faux jusqu'à son prochain redessin : c'est la limite O5,
écrite au README ; la noter, ce n'est pas un écart.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 9 — Thèmes sombre et clair (§15.2, §15.9 à l'œil)

Basculer le thème du cockpit, sombre puis clair : bascule instantanée, sans flash ; couleurs ANSI lisibles dans les deux thèmes
(`ls -G`, `claude`). Le tampon est rejoué à la bascule (limite : l'historique au-delà de 256 Kio est perdu).

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 10 — Fin du shell (§6.1)

Taper `exit` : « Le shell s'est terminé (code 0). » et le bouton « Relancer le shell ». Relancer : un nouveau shell démarre.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 11 — `TERM` et `COLORTERM` (P71-D-23)

Taper `echo "$TERM $COLORTERM"` : attendu `xterm-256color truecolor`. Consigner les deux valeurs. P71-D-23 (arbitrage de Samuel,
AskUserQuestion, session principale Claude Code, 2026-11-03, « Toujours xterm-256color + truecolor (Recommandé) ») rend définitif le
choix posé d'abord par P71-D-22. Si Samuel le renverse ici, la constante `AJOUTS_TOUJOURS` de `vf-cockpit-terminal-env.mjs` change :
écart remonté au manager, rien n'est corrigé pendant la recette.

- Valeurs relevées : _à consigner_
- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 12 — Serveur arrêté (§6.1)

Dans un autre terminal : `node plugin/cockpit/scripts/vf-cockpit.mjs stop --lab .`. La page du terminal affiche « Serveur arrêté ».

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 13 — Sans le drapeau, rien (§15.1, P71-D-02)

Relancer sans le drapeau : `node plugin/cockpit/scripts/vf-cockpit.mjs open --rebuild --lab .`. Aucune pastille, aucun tiroir.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 14 — Tabulation, focus, mouvement réduit (§15.8)

Parcourir la page à la tabulation : aucun piège, anneau de focus visible sur chaque contrôle. Si Samuel le souhaite : `prefers-reduced-motion`
coupe l'entrée du tiroir.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 15 — Le tiroir dans l'onglet Code (TERM-05, P71-D-08)

Relancer avec le drapeau (`open --terminal --lab .`), ouvrir l'onglet Code (`/`) et y ouvrir le tiroir : même terminal, même session.
Passer de Projet à Code et retour : le tiroir se comporte pareil, la session survit (cadre à rechargement près : voir la limite F4 du README).

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 16 — Marge basse de la page Projet (F-07-3)

Tiroir ouvert à sa hauteur par défaut, sur la page Projet : le dernier bloc de la page (et la barre de question `#ask`) reste atteignable et
n'est pas masqué par le tiroir. Constat de 71-07 : la page Projet est la même vue que la carte (canvas), aucun conteneur défilant n'a reçu de
marge basse ; seule la barre de question monte de la hauteur du tiroir. Noter quel bloc, s'il y en a un, reste masqué.

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

### Étape 17 — Ctrl+Maj+Espace sur Chrome, Safari et Firefox (UI-SPEC F5, §7.1)

Le navigateur ne doit pas capter la combinaison avant la page. Pour chaque navigateur, le rendre navigateur par défaut du poste (macOS :
Réglages Système, Bureau et Dock, « Navigateur web par défaut »), relancer `node plugin/cockpit/scripts/vf-cockpit.mjs open --terminal --lab .`
(même serveur, nouvel amorçage), puis : Ctrl+Maj+Espace ouvre le tiroir depuis la page ; depuis le terminal il le ferme et rend le focus.
Relever aussi, par navigateur, si le terminal s'affiche (le stockage d'un cadre d'une autre origine peut être cloisonné par Safari ou
Firefox : la page du terminal afficherait « Session expirée » ou une carte d'erreur). A7 : seul Chrome est mesuré par les suites.

| Navigateur | Version | Ouvre | Ferme depuis le terminal | Terminal affiché | Remarque |
|------------|---------|-------|--------------------------|------------------|----------|
| Chrome | _à renseigner_ | _à consigner_ | _à consigner_ | _à consigner_ | |
| Safari | _à renseigner_ | _à consigner_ | _à consigner_ | _à consigner_ | |
| Firefox | _à renseigner_ | _à consigner_ | _à consigner_ | _à consigner_ | |

- Réponse de Samuel : _à consigner_
- Verdict : _à rendre_

## Critères de l'UI-SPEC §15 couverts

| Critère §15 | Étape(s) |
|-------------|----------|
| 1. Sans `--terminal`, rien | 13 |
| 2. Deux thèmes, couleurs, bascule | 2, 9 |
| 3. Tracé de `claude` continu | 3 |
| 4. Ouvrir, fermer, redimensionner, recharger | 5, 7, 8 |
| 5. Ctrl+C, Ctrl+R, Ctrl+W, Échap, Tab, flèches, Ctrl+Maj+Espace | 5, 6, 7, 17 |
| 6. Caractères Option du clavier français | 6 |
| 7. États §5 et §6 (deuxième onglet, `exit`, arrêt du serveur) | 8, 10, 12 (le secret supprimé du stockage et Windows simulé sont couverts par les suites, pas par cette recette) |
| 8. Tabulation, focus, mouvement réduit | 14 |
| 9. Contraste WCAG | 9 (à l'œil seulement ; le recalcul des couples du §4.2 n'est pas joué ici) |

## Réponse à P71-D-22 / P71-D-23

_Consignée à l'étape 11._

## Écarts remontés au manager

_Aucun pour l'instant (aucune étape jouée)._

## Retours de Samuel

Consignés mot pour mot par le manager, sans cocher aucune case à sa place.

1. **Session principale Claude Code, saisie texte, 2026-11-04**, sur un cockpit de test (port 4456, tête `8d6c9df9`) : « Le shell a l'air de très
   bien marché btw ».
2. **Session principale Claude Code, saisie texte avec capture d'écran, 2026-11-04**, même cockpit de test : « je remarque que le bouton
   'Terminal' chevauche les boutons '- [] +' ». C'est l'écart E2, déjà relevé par les juges (étapes 1 et 14), arbitré (P71-D-34) et corrigé par le
   lot W2 ; confirmation attendue au rejeu des juges des étapes 1 et 14, capture à l'appui.

## Recette par juges (règle P71-D-32)

Premier passage (2026-11-04, code `7427bec6`, trois juges frais, Chromium et WebKit par la bibliothèque playwright, Firefox téléchargé localement,
vrai `zsh`, vrai `claude` 2.1.318) : étapes 2, 3, 4, 6, 7, 8, 10, 11, 13, 15, 17 conformes ; écarts fonctionnels E1 (gel périodique), E2 (pastille
sur les boutons de zoom), E3 (dernière ligne coupée), E4 (python3 absent, message faux), E5 (démarrage lent pris pour un échec), arbitrés
P71-D-33 et P71-D-34 ; points de goût G1, G2, G3 tranchés P71-D-35.

Non joué, consigné (P71-D-32, P71-D-35) : le raccourci Ctrl+Maj+Espace dans Safari.app et Firefox.app réels, et un vrai clavier AZERTY avec la
touche Option.

Rejeu réduit après correctifs (levier « méthode allégée selon le risque », arbitrage Samuel, AskUserQuestion, session principale Claude Code,
2026-11-03) : étapes 1, 5, 9, 12, 14, 16 sur `7bb14f15` — résultats ajoutés au retour des juges.
