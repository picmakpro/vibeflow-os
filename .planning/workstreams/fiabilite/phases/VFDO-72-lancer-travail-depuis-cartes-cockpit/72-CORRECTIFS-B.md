# 72-CORRECTIFS-B — correction ciblée côté Q (terminal) et côté page (lot 1, revue et audit)

Mandat du manager (2026-11-06) : F1, ST-2, ST-5, SP-1, F6. Périmètre : `vf-cockpit-terminal-{client,vue,tiroir}.mjs`, `vf-cockpit-lancer-ui.mjs`, suites `test-cockpit-lancer-{bandeau,ui}.sh`. Commit de code : 2cf478f4. Aucun plafond relevé (client 280, vue 194, tiroir 220, lancer-ui 194 ; `check-file-size.sh` rc 0).

## F1 — une proposition ne déplace jamais le focus clavier
- Témoins ajoutés (`test-cockpit-lancer-bandeau.sh`, mode `focus` de `chrome-bandeau.mjs`) : faux P avec un champ focalisé AVANT la création du cadre de Q, proposition reçue, frappes `abc` par `Input.dispatchKeyEvent`.
  - LB.F1 (fenêtre focalisée, `Emulation.setFocusEmulationEnabled`) et LB.F2 (non focalisée). Attendu : `abc/champP/0` (champ de P = abc, élément actif de P = champP, aucun octet à /entree).
- ROUGE avant (code de b5efcc40, mesuré) : LB.F1 obtenu `/IFRAME/0` (le focus a quitté le champ de P pour le cadre de Q, les frappes n'arrivent plus à P) ; LB.F2 obtenu `/IFRAME/3` (le cadre a pris le focus et TROIS octets sont partis à l'entrée du shell).
- Code : client, ligne du focus de démarrage : `if (!document.hasFocus || document.hasFocus()) term.focus();` (même ligne, 280 lignes) ; vue : `if (premier && document.hasFocus()) annuler.focus();`. Un cadre qui n'a pas le focus ne le prend jamais ; l'ouverture volontaire (P appelle `cadre.focus()` avant) garde le comportement de la Phase 71. Le repli `!document.hasFocus` sert les doublures Node des suites voisines (leur `document` n'a pas la méthode).
- VERT après : LB.F1 et LB.F2 `abc/champP/0`.
- Mutants (rougissent leur témoin) : M-FOCUS-CLIENT (focus de démarrage sans condition, jeu en fenêtre non focalisée) et M-FOCUS-VUE (Annuler prend le focus sans condition, jeu en fenêtre focalisée), tous deux `rouge` après exécution de tout le scénario (verdict « plante » distinct du verdict « rouge »).
- LB.V8 : la sonde « Annuler prend le focus au premier affichage » met maintenant d'abord le cadre de Q au focus (émulation + `iframe.focus()`), puisque Annuler ne le prend plus qu'à cette condition. Attendu inchangé (`false/true/0/1/true/Annuler/true`). Ce n'est pas un affaiblissement : le cas « cadre non focalisé » est couvert par LB.F1/F2.

## ST-2 — parité des trois tables de motifs
- Sondes : LB.V9 (vue, Chrome : pour chaque code, `bloquants:[code]` ne rend jamais « Contrôle non reconnu. ») et LU.S8 (interface : `MOTIFS` a un texte par code). Dans les deux cas la liste des codes est DÉRIVÉE du module de cibles réel (`BLOQUANTS`, `AVERTISSEMENTS`, `AVERTISSEMENTS_RESERVES`, import), jamais un littéral ; un garde refuse une liste de moins de 14 codes (vert à vide).
- Rouge avant : sans objet (les tables sont aujourd'hui en parité, la sonde est verte). Preuve par mutant : M-ST2-TEXTE (retire le texte de `lancement-recent` dans la vue) rougit LB.V9 ; M-TEXTE-RETIRE (même retrait dans l'interface) rougit LU.S8.
- Vert après : LB.V9 `14/` (14 codes, aucun sans texte), LU.S8 `n>=14/sans=`.

## ST-5 — texte du 409
- Constat : le client traduit tout 409 en `occupe` et la vue disait « Un programme occupe le terminal ». Or le serveur répond 409 pour quatre causes (`vf-cockpit-terminal-processus.mjs` : onglet non propriétaire ligne 72, `occupee` et `bloquee` de la table des motifs, `premier-plan` de la table de lancement), SANS corps : la cause n'est pas distinguable côté vue. Aucun statut serveur touché.
- Choix : un texte vrai pour toutes les causes. Nouveau texte : « Le terminal n'a pas pris la demande (programme au premier plan, autre lancement, autre onglet ou contrôle bloquant). Rien n'a été écrit ; vérifiez, puis cliquez sur Lancer. » (« Rien n'a été écrit » est vrai des quatre : refus avant toute écriture au PTY).
- Ce qu'il faudrait côté serveur pour dire LA cause : un corps `{ refus: <motif> }` sur les 409 de `/lancer` (motifs `occupee`, `bloquee`, `premier-plan`, onglet) et un statut distinct ou un `refus` lu par le client (`r.json()`), puis une table de textes par motif dans la vue. Non fait : fichiers de l'autre codeur (`terminal-processus.mjs`, `lancer-q.mjs`) ; point laissé au manager.
- Changement de texte voulu, pas un affaiblissement : les attendus LB.V7 et LB.E3 reprennent le nouveau texte (`MSG.occupe`). Mutant M-OCCUPE-ANCIEN (ancien texte) rougit LB.V7.

## SP-1 — un POST accepté rend la proposition visible
- Défaut : après rechargement sans fragment `#t=` et tiroir fermé, le cadre de Q n'existe pas ; le 202 s'affichait mais rien ne s'ouvrait.
- Mécanisme (aucun postMessage, aucun global ajouté, la fonction du tiroir n'en pose aucun) : l'interface de lancement émet sur `document` l'évènement `vf-lancer-propose` (sans donnée) quand le POST rend 202 (ligne marquée `garde:propose`) ; le tiroir l'écoute et appelle `proposer` (= `ouvrir(false)` : monte le cadre si absent, ouvre le tiroir, jamais de focus, annonce). Sans tiroir (Windows, hôte autre que 127.0.0.1), personne n'écoute : le message de la carte reste le même. Un script de la page peut forger l'évènement : il ne fait qu'ouvrir le tiroir sans focus, aucun octet ni lancement.
- Témoin Chrome LB.F3 (faux P : tiroir et interface RÉELS, faux `window.VibeFlow`, routes du contrat ; tiroir fermé, aucun cadre avant ; clic de confiance sur le bouton de la carte) : attendu `0/true/true/true` (aucun cadre avant, cadre monté, bandeau dans Q, focus de P pas pris par le cadre). Témoin unitaire LU.3 : UN évènement après le 202 (`prop=1`), LU.12 : aucun après les neuf refus ou pannes (`prop=0`).
- ROUGE avant (= code sans la ligne de signal, mutant M-SP1-SIGNAL) : LB.F3 obtenu `0/false/false/true` (pas de cadre, pas de bandeau ; la carte a pourtant affiché « Confirmez-la dans le terminal »).
- VERT après : LB.F3 `0/true/true/true`. Mutants : M-SP1-SIGNAL, M-SP1-ECOUTE (le tiroir n'écoute plus), M-PROPOSE (LU.3) rougissent.

## F6 — note du mode hérité
- Source : documentation officielle de Claude Code, settings-reference § `permissions.defaultMode` (2.1.318) : `bypassPermissions` et `auto` d'un `.claude/settings.json` ou `settings.local.json` de projet sont ignorés depuis la v2.1.257 ; les autres modes s'appliquent depuis tout fichier.
- Nouveau texte (une phrase, texte neutre) : « Aucun mode n'est imposé : Claude Code suit les réglages de votre poste ou du projet (jamais « tout autoriser » ni auto depuis le projet). »
- Changement de texte VOULU (l'ancienne note disait « le réglage de votre poste s'applique, y compris « tout autoriser » s'il est configuré », fausse pour les modes venus du projet) : l'attendu `NOTE` de la suite est mis à jour, pas affaibli. Mutant M-NOTE-ANCIENNE (ancien texte) rougit LB.V1, comparé à la sortie saine de la même suite.

## Rejeu au HEAD 2cf478f4 (voir le rapport pour les codes)
bandeau 67/0, ui 50/0 (avant le dernier ajout : 50), voisines : lancer-chat 0, lancer-xss 0, terminal-tiroir 75/0, terminal-client 0, terminal-page 0, terminal-xss 0, terminal-activation 0, chrome-fr 0, responsive 291/0. lancer-bout-en-bout : 53 PASS / 1 FAIL (M-LISTE-PAGE) hors périmètre : le mutant vise `vf-cockpit-lancer.mjs`, réécrit par le commit 41f08dbe (ST-1, correctif A) ; le 409 y est désormais rendu par une autre source de règle, le mutant ne produit plus le 202 attendu.
