---
phase: 68-vf-signal-embarque-socle-partage
plan: 07
requirements: [VFSG-04, VFSG-10]
status: complete
---

# 68-07 — Équipe `who@2` et bouton « Ouvrir le cockpit » (VFSG-04, VFSG-10 ; P68-D-03, P68-D-17, P68-D-19, P68-D-25)

Trace du rouge, du vert et des mutants : `68-07-RED-TRACE.md`. Claude Code 2.1.318. Branche `feat/phase-68-w07`, partie de `523921fe`.

## Commits

| Empreinte | Objet |
|-----------|-------|
| `58afbd49` | test : Q1..Q3 (équipe), A1..A3 (bouton), rouges |
| `6030ebf4` | docs : trace du rouge |
| `be8f2f5b` | test : Q2 ne presse l'onglet que s'il est dessiné |
| `ed523b7f` | test : retouche minimale de `vf-signal.test.tsx` (l'arbre vient de `signal@1.equipe`) |
| `f77854fc` | feat : vue Équipe sur `who@2`, types `SignalWorker`/`SignalEquipe`/`cockpitUrl`/`cockpitErreur` |
| `9346c3d4` | test : `vf-signal.test.tsx` à 299 lignes (ed523b7f l'avait portée à 305) ; codes du lanceur un test chacun |
| `03fcfddd` | feat : `resoudreLanceur`, `ouvrirCockpit`, bouton `ouvrir-cockpit` (raccourci `o`), ligne d'adresse |
| `d73de532` | test : M8 de la suite statique (trailer `Gate-Touche:`) |

## Résultats

- `claude plugin test plugin` : 54 pass, 0 fail ; `claude plugin validate --strict plugin` rc=0.
- `test-cockpit-signal-mod.sh` : 33 ok / 0 ko sous bash et sous zsh (M0 à M8) ; `check-machine-paths.sh` rc=0 ; `check-gate-touche.sh` : RIEN-A-JUGER (exit 3).
- Longueurs : `equipe.tsx` 127, `actions.ts` 64, `boutons.tsx` 82 (plafond 300).
- Mutants : 8 + 3 statiques, chacun rougit sur l'assertion visée.

## Ce que montre la vue Équipe, et ce qu'elle ne montre pas (point remonté par 68-06)

`who@2` porte les orphelins du registre comme travailleurs `kind: 'registered'`, `orphan: true`, `stale`, `source: 'registre'`
(`vf-cockpit-who.mjs` l. 88-90). La vue les montre : rôle, tâche, ligne « orphelin (registre) », arbre (compartiment ou dépôt), âge, en orange, présents aussi en compact (état « en attente »). Aucun geste ne leur est offert.
Montré aussi : sessions, sous-agents de toutes sessions et worktrees, verrous (`kind: lock`), nœuds `running` des DAG, avec arbre/branche/âge, état (actif, en attente, terminé grisé, absent en compact).
**Pas montré** : `stoppedAt` du STATE (aucun champ de `who@2` ne le porte) ; le nombre d'enfants d'un verrou (`children`) ; le rattachement d'un sous-agent à un nœud de mission (`rattachement`) ; `lastAt`, `dag`, `treeBy`. Le registre n'est plus relié « sous son nœud de mission » comme dans l'ancienne vue mission : il apparaît dans l'arbre d'équipe, rattaché à un parent seulement si `parent` en désigne un.

## Écarts au plan

1. **Message du code 2** : « cockpit : lab sans dossier de planning (code 2) » et non « lab sans .planning/ » : M7.3 (68-06) interdit tout littéral `.planning` hors commentaire dans les hooks ; le contourner par concaténation aurait vidé la garde. Texte à confirmer si Samuel préfère le littéral (alors M7.3 serait à amender, hors de ce plan).
2. **`resoudreLanceur` retourne toujours un chemin** : projet, puis compte (testés par `$.fs.exists`), sinon `<pluginRoot>/cockpit/scripts/vf-cockpit.mjs` sans test d'existence (A1b l'exige : « sans lanceur posé -> celui du plugin ») ; un script absent donne le code de sortie de `node`, traduit « échec (code N) ».
3. **Gestes** : le code d'origine utilise `$.session.send({ to: { agentId } })`, pas `$.agent.send` (le plan se trompe de nom) ; M8.6 garde `$.session.send` et `$.ui.view` dans `views/equipe.tsx`. Gestes offerts si `id` ∈ `$.agent.list()` de la session, non terminé et non orphelin.
4. **Sous `claude plugin test`** : `cockpitUrl` et `cockpitErreur` sont deux atomes (le plan n'en nomme qu'un) ; l'adresse est affichée avec une barre finale (`http://127.0.0.1:4317/`, l'onglet Code).
5. **Témoins ajoutés** : Q1b (orphelin), Q1c (la liste de la session ne fait plus l'arbre), A1b..A1d (ordre des candidats), A2b (sortie piégée), A2c..A2f (codes, adresse introuvable, ENOENT), M8.0..M8.6. Q3 réécrit sans liste de session pour rougir pour la bonne raison.
6. **Retouche d'un test existant** (`ed523b7f`, isolée) : « la vue équipe liste les agents en arbre » sert maintenant l'arbre par `signal@1.equipe` (par conception). Elle a poussé `vf-signal.test.tsx` à 305 lignes ; `9346c3d4` le ramène à 299 (M5 de la suite statique était rouge entre les deux commits).
7. **Non prouvé** : la correspondance des identifiants `who@2` / `$.agent.list()` n'est pas constatée ici (les tests posent les mêmes `id` à la main) : à constater à la recette (68-09) ; si les espaces diffèrent, les gestes disparaissent sans bruit et c'est à remonter, jamais rapprocher par rôle. `process.run` réel du lanceur (délai 60 s, `open` qui assemble) lui aussi non joué sous `claude plugin test`.

## Artefacts posés d'office dans le dossier de phase

`68-07-RED-TRACE.md`, `68-07-SUMMARY.md` (aucun autre).

## Estimate / actuals

estimate du plan : 85 000 tokens, 3 tâches, confiance basse. actuals : non mesurés (exécution inline, pas de `gsd-execute-phase`).
