# Spike Manifest

## Ideas

### cockpit-code-projet
Un cockpit VibeFlow à deux onglets sur la base du viewer de floorplan (haydenschmitty/floorplan,
MIT) : **Code** (la carte du dépôt, enrichie des liens propres à VibeFlow) et **Projet** (jalons →
phases → plans, exigences, missions, backlog, graines, releases), avec la DA de floorplan, le zoom
par double-clic et un pont entre les deux onglets. Étude : `docs/research/2026-11-01-etude-floorplan-cockpit.md`.
Le spike 001 (`cockpit-live`, sur la branche `spike/cockpit-live`) n'est pas dans cet arbre.

**Requirements:**

- Reprendre la DA et le moteur d'affichage de floorplan (graphes ELK zoomables), pas une
  réécriture (Samuel, session principale, 2026-11-01 : « j'aime beaucoup la DA… le logiciel
  d'affichage et de graph, il est vraiment super »).
- Deux sections comme les onglets d'une application : une pour le code, une pour le projet
  (même date, même canal).
- Côté Projet : toute l'information utile de VibeFlow, ordonnée par thématique, avec des graphes
  dans lesquels on plonge en cliquant sur les cases (même date, même canal).

## Spikes

| # | Idea | Name | Type | Validates | Verdict | Tags |
|---|------|------|------|-----------|---------|------|
| 002 | cockpit-code-projet | cockpit-code-projet | standard | Given le viewer floorplan vendorisé et le .planning/ réel, when on génère sans LLM un onglet Code et un onglet Projet sur le même moteur, then on navigue jalon → phase → plan → fichiers et retour, avec statuts, dépendances et DA d'origine | VALIDATED | cockpit, floorplan, visualisation, planning, elk |
| 003 | cockpit-code-projet | cockpit-floorplan-live | standard | Given le cockpit 002 servi, when .planning/ ou le verrou change, then l'onglet Projet met à jour ses statuts sans recharger ni perdre la vue, en < 2 s | VALIDATED | cockpit, floorplan, sse, live, driver-lock |
| 004 | cockpit-code-projet | signal-au-travail | standard | Given des agents au travail sans DAG dans l'arbre (session, sous-agent, worktree, enregistré), when on croise transcripts, meta des sous-agents, verrous, registre et DAG, then le cockpit dit qui travaille, où et sur quoi, sans faux « personne » ni zombie actif | VALIDATED | cockpit, presence, transcripts, subagents, driver-lock |
| 005 | cockpit-code-projet | questions-onglet-projet | comparison | Given le cockpit servi, when on pose une question en français dans la barre de l'onglet Projet, then la réponse s'affiche dans le tableau natif (ids valides), immédiate pour les formes courantes, argumentée par l'agent pour le reste | VALIDATED | cockpit, floorplan, questions, llm, claude-cli |
