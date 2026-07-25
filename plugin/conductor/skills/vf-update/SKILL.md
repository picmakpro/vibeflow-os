---
name: vf-update
description: >
  Utiliser quand l'utilisateur veut mettre à jour VibeFlow — « mets à jour vibeflow »,
  « /vf-update », ou en réaction au bandeau « mise à jour disponible » au démarrage de session.
  Compare la version installée au dernier tag publié, montre le changelog, puis met à jour le
  plugin (cache marketplace) et les modules installés, sous validation humaine.
  ✘ pas pour réaligner la **structure** d'un lab sur une doctrine qui a évolué, une fois la
  nouvelle version posée → /vf-calibrate · ✘ pas pour ajouter, retirer ou re-choisir des
  modules → /vibeflow-install · ✘ pas pour mettre à jour la documentation d'un projet →
  gsd-docs-update.
  Invocable par l'utilisateur ET par `vibeflow-conductor`.
---

# vf-update — Mise à jour du plugin & des modules

Met à jour VibeFlow en **deux couches** : (1) le **plugin** via `claude plugin update vibeflow`
(rafraîchit le cache marketplace `~/.claude/plugins/cache/…`), puis (2) les **modules installés**
via l'engine `update --all` (re-matérialise `.claude/skills|agents|rules|scripts`). Jamais sans
confirmation (ADR-031).

## Résolution des scripts (conductor)

Les scripts vivent dans le dossier `scripts/` de conductor. Localise-les dans cet ordre (prends le
premier existant) : `$HOME/.claude/scripts/` → `./.claude/scripts/` → `${CLAUDE_PLUGIN_ROOT}/conductor/scripts/`.
Note ce dossier `<S>` pour les étapes suivantes.

## Étapes

### 1 — Diagnostic de version

Lance `bash <S>/check-plugin-update.sh --print`. Parse le JSON `{update_available, installed, latest}`.

- `latest` vaut `unknown` (réseau KO) → dis-le, propose de réessayer plus tard, **stop**.
- `update_available` = false → annonce « VibeFlow est à jour (v<installed>) » et **stop**.
- Sinon continue.

### 2 — Changelog (ce qui a changé)

Montre les changements entre `installed` et `latest`, résumés **par version** en distinguant
*nouvelle capacité* / *correctif* / *changement de doctrine*. Source, dans l'ordre de préférence :
la table d'historique du `README.md` du plugin (`${CLAUDE_PLUGIN_ROOT}/README.md` ou le clone
marketplace `~/.claude/plugins/marketplaces/vibeflow-os/README.md`), sinon les `CHANGELOG.md` des
modules. Reste factuel, pas de survente.

### 3 — Confirmation (ADR-031 — jamais d'update sans validation humaine)

Récapitule via **AskUserQuestion** : « Plugin v<installed> → v<latest> + les modules installés
seront mis à jour. Continuer ? ». Gère les flags de `$ARGUMENTS` :

- `--check` → affiche seulement les étapes 1–2, **ne demande pas**, **stop**.
- `--modules-only` → saute l'étape 4a (ne touche pas au plugin).

### 4 — Exécution (après OK)

a. **Couche plugin** : `claude plugin update vibeflow@vibeflow-os`. **Toujours l'identifiant
   complet `<plugin>@<marketplace>`** : le nom nu (`claude plugin update vibeflow`) peut échouer par
   « Plugin not found » quand le cache de catalogue est périmé. Si le CLI `claude` est absent ou
   échoue, signale-le, donne la commande manuelle, et — en cas de « not found » persistant — la
   parade : `claude plugin marketplace update vibeflow-os` (ou supprimer le cache
   `~/.claude/plugins/plugin-catalog-cache.json`, régénéré au prochain appel). Puis continue en 4b
   (les modules peuvent quand même être re-matérialisés depuis le cache le plus récent).

b. **Couche modules** : `bash <S>/vf-update-run.sh`. Le script localise **lui-même** le cache le
   plus récent (indispensable : la session courante garde encore l'ancien `${CLAUDE_PLUGIN_ROOT}`)
   et relance l'engine `update --all` pour chaque scope ayant un registre. Relaie son résumé.

### 5 — Rappel de redémarrage

Termine par : « Modules à jour sur disque. **Redémarre Claude Code** pour recharger le plugin
(commandes, agents) dans sa nouvelle version. » Le plugin lui-même n'est pris en compte qu'au
prochain démarrage de session.

## Garde-fous

- **Aucune mise à jour sans confirmation explicite** (sauf `--modules-only`/`--check` qui restent
  cadrés). ADR-031.
- **Best-effort réseau** : une détection impossible n'est jamais une erreur bloquante.
- **Ne jamais downgrader** : l'engine saute les modules déjà à jour (comparaison de version).
- Périmètre : le **plugin VibeFlow** et ses modules. La chaîne d'outils interne (GSD/Superpowers)
  a sa propre mise à jour (`gsd-update`) — hors périmètre de ce skill.
