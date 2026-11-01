# cockpit — le cockpit web local du lab

> Une page locale, en lecture seule, qui dit où en est le lab : jalons, phases, plans, exigences, missions, et qui
> travaille en ce moment. Ouverte par `/vf-cockpit`.

**Type** : skill + scripts + moteur vendorisé · **Version** : v1.0.0 · **Dépend de** : aucun module (lit le verrou de `conductor` s'il est posé)

## Ce que ça donne

Deux onglets sur une même page servie en local : **Projet** (la vie du lab, calculée depuis `.planning/`) et **Code** (la
carte du code). Lecture seule : le module n'écrit jamais dans `.planning/`.

## Ouvrir

```bash
node .claude/scripts/vf-cockpit.mjs [open|build|stop|status] [--lab <dossier>] [--no-open] [--port <p>] [--rebuild]
```

Le verbe `/vf-cockpit` lance ce script (poses `project` et `local`) ou `$HOME/.claude/scripts/vf-cockpit.mjs` (pose `user`).
`open` (défaut) assemble la sortie si besoin, démarre le serveur et imprime
`Cockpit : <adresse>/ (Code) · <adresse>/project.html (Projet)` ; un serveur vivant du même lab est réutilisé sauf
`--rebuild`. `build` assemble sans serveur, `stop` arrête, `status` dit l'adresse et le PID.

| Code | Sens |
|------|------|
| 0 | succès |
| 2 | lab sans `.planning/` |
| 3 | moteur absent (réinstaller le module) |
| 4 | assemblage en échec |
| 5 | serveur non démarré (journal : `.vibeflow/cockpit/.cache/serveur.log`) |

## Les deux onglets

- **Projet** : jalons, phases, plans, exigences, missions ; badge « au travail » (sessions en direct), mise à jour en
  direct de la carte sans perdre le zoom.
- **Code** : carte des fichiers et des liens d'appel ; extracteur VibeFlow quand le lab porte des modules (`plugin/*/module.json`),
  architecture brute sinon. Aucun modèle n'est appelé pour l'assembler.

## Questions et modèle

Les formes courantes de l'onglet Projet (« Où en est-on ? », « phase N ») sont répondues sur place. Les autres passent par
`claude -p`, confiné : mode `dontAsk`, outils `Read,Grep,Glob,Bash`, Bash limité aux deux scripts de requête, lecture bornée à
`./**`. Modèle : sélecteur de la page > variable `VF_COCKPIT_MODEL` > `sonnet`, parmi une liste fermée ; une valeur hors liste
est refusée.

## Confidentialité et réseau

Écoute sur `127.0.0.1` seulement, contrôle du `Host`, jeton propre au serveur, segments cachés refusés. La dernière commande
d'une session n'est jamais diffusée ni exportée ; elle se révèle à la demande, dans la ligne cliquée. Aucun appel sortant, hors
l'agent qui répond aux questions.

## Sortie dans le lab

`<lab>/.vibeflow/cockpit/` avec son propre `.gitignore` (`*`). Aucun dossier amont, aucun `CLAUDE.local.md` dans le lab.

## Interface du socle pour `vf-signal`

Schémas `vibeflow/cockpit-*@1` ; contrat lisible dans `scripts/vf-cockpit-interface.json` (copié à l'identique dans la sortie).

## Code tiers

Le moteur d'affichage est **floorplan v0.6.0 @ 92d6854** (`haydenschmitty/floorplan`, licence MIT), copié sous
`skills/cockpit-moteur/`. Le copyright d'origine est dans `LICENSE`, les composants tiers dans `LICENCES-TIERCES.txt`,
chaque patch, ajout et retrait dans `VENDORED.txt`. Vérifier : `bash plugin/cockpit/amont/synchro.sh verifier` ; resynchroniser :
`plugin/cockpit/amont/SYNCHRO.md`.

## Limites connues

- Le format interne de Claude Code (session « au travail ») est surveillé : s'il change, l'état passe à `forme-inconnue` au
  lieu de mentir.
- La surveillance récursive de fichiers est mesurée sur macOS et en CI Linux seulement ; Windows n'est pas mesuré.
- L'en-tête chargé se tasse sous ≈ 1 400 px de largeur.
