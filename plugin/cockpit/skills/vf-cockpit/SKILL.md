---
name: vf-cockpit
description: "Ouvre le cockpit web local du lab courant : onglet Projet (jalons, phases, plans, exigences, missions, qui est au travail), onglet Équipe (agents au travail) et onglet Code. Verbe tapé par l'utilisateur : `/vf-cockpit [open|stop|status|build]`."
vf-invocation: user
disable-model-invocation: true
---

# vf-cockpit — le cockpit du lab

Le cockpit est une page locale en lecture seule, sauf le terminal intégré que `--terminal` ouvre (un shell du compte, pas une lecture) : `Projet` (où en est le lab, qui travaille en direct, questions
posées en français) et `Code` (carte du code). Il est servi sur `127.0.0.1` uniquement ; aucun appel sortant, hors
l'agent `claude -p` confiné qui répond aux questions de l'onglet Projet.

Avec `--terminal`, les cartes de phase et de mission portent « Lancer » : un clic propose une session `claude`, écrite dans le terminal seulement après un geste dans le terminal.

## Lancer

1. Résoudre le lanceur : `.claude/scripts/vf-cockpit.mjs` s'il existe dans le lab (poses `project` et `local`),
   sinon `$HOME/.claude/scripts/vf-cockpit.mjs` (pose `user`).
2. Exécuter `node <lanceur> <argument>` depuis la racine du lab ; l'argument vaut `open` par défaut, ou `build`
   (assemble sans serveur), `stop` (arrête le serveur), `status` (adresse et PID, ou « arrêté »). Options :
   `--lab <dossier>`, `--no-open`, `--port <p>`, `--rebuild`, `--terminal` (ouvre aussi un terminal dans le tiroir, macOS et Linux, `python3` requis ; sans lui le lanceur le dit et ouvre le cockpit sans terminal ; le cockpit n'est alors plus en lecture seule : le terminal est un shell du compte, avec le `PATH` d'origine du lanceur). Le lanceur attend le serveur jusqu'à 30 s.
3. Relayer l'adresse imprimée : `Cockpit : <adresse>/ (Code) · <adresse>/project.html (Projet)`.

Codes de sortie : 0 succès · 2 lab sans `.planning/` · 3 moteur absent (réinstaller le module) · 4 assemblage en
échec · 5 serveur non démarré (le journal est dans `.vibeflow/cockpit/.cache/serveur.log`), ou fichier d'état `.vibeflow/cockpit/.cache/server.json` désignant un processus qui n'est pas le serveur du cockpit (vérifier le PID avec `ps`, puis supprimer ce fichier et relancer).

## Règles

- Sortie sous `<lab>/.vibeflow/cockpit/`, ignorée par git. Jamais d'écriture dans `.planning/`.
- Modèle de l'agent : variable `VF_COCKPIT_MODEL` ou sélecteur du cockpit (liste fermée, `sonnet` par défaut).
- Confidentialité : la dernière commande d'une session n'est jamais diffusée ; elle se révèle à la demande, dans la
  page, sur la ligne cliquée.
- Un serveur vivant du même lab est réutilisé ; il s'arrête seul 60 minutes après la fermeture du dernier onglet.
