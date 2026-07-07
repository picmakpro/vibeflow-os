# INSTALL — vibeflow-os

> Guide d'installation de VibeFlow comme **plugin Claude Code**.

---

## Pré-requis

- **Claude Code** à jour (commande `claude plugin` disponible).
- `bash 4+`, `python3 3.8+`, `awk`, `grep`, `sed` (macOS/Linux) — utilisés par l'engine bundlé.

Aucun accès privé, aucun clone, aucune auth `gh` ne sont requis pour installer le plugin.

---

## Installation (2 commandes)

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

- La 1ère commande ajoute le marketplace VibeFlow (le repo GitHub `picmakpro/vibeflow-os` héberge
  son propre `marketplace.json`).
- La 2nde installe le plugin `vibeflow` : Claude Code copie le bundle (modules + skill `installer/`
  + engine `_internal/`) dans son cache local de plugins.

Aucune édition de `settings.json`, aucun script à lancer manuellement.

---

## Configuration (lancement manuel)

Une fois le plugin installé, **lance toi-même** l'UX de configuration depuis Claude Code :

```
/vibeflow-install
```

L'UX déroule alors :

1. **Toggle scope** (single-select) : compte (`user`) / projet (`project`) / projet sans commit
   (`local`). Le scope choisi s'applique partout (modules VibeFlow + dépendances).
2. **Toggle modules** (multi-select) : la liste est peuplée depuis le catalogue (chaque module +
   sa description 1 ligne).
3. **Auto-résolution + récap** : la fermeture transitive des `requires` est calculée et
   **récapitulée** avant toute install.
4. **Install scopée** : les modules sélectionnés sont posés au scope choisi.

> **Le lancement est toujours manuel.** Il n'y a **pas** d'ouverture automatique au démarrage de
> session : tu tapes `/vibeflow-install` quand tu veux installer ou re-configurer. (Une tentative
> d'auto-lancement via un hook `SessionStart` a existé puis a été retirée car son déclenchement
> n'était pas fiable.)

### Re-configurer / ajouter un module

`/vibeflow-install` reste invocable à la main pour changer de scope, ajouter ou retirer un module ;
les dépendances sont re-résolues automatiquement à chaque passage.

---

## Mises à jour

Le plus simple, une fois le plugin installé : la commande **`/vf-update`** (met à jour le plugin
**et** les modules installés, avec confirmation). En ligne de commande :

```bash
claude plugin update vibeflow@vibeflow-os
```

> Utilise **toujours l'identifiant complet `vibeflow@vibeflow-os`**. Le nom nu
> (`claude plugin update vibeflow`) peut renvoyer « Plugin not found » quand le cache de catalogue
> est périmé — dans ce cas : `claude plugin marketplace update vibeflow-os`, ou supprime
> `~/.claude/plugins/plugin-catalog-cache.json` (régénéré au prochain appel).

Récupère la dernière version publiée du plugin depuis le marketplace, puis re-passer par
`/vibeflow-install` si tu veux activer de nouveaux modules apparus dans le catalogue.

---

## Désinstallation

L'install se fait en **deux couches**, et il faut les retirer dans le bon ordre :

| Couche | Contenu | Retirée par `claude plugin uninstall vibeflow` ? |
|--------|---------|:---:|
| **Plugin** | Le bundle dans le cache Claude Code (skill `installer/` + engine `_internal/` + sources des modules) | ✅ oui |
| **Modules déployés** | Les copies posées dans ton scope : `.claude/skills/`, `.claude/agents/<mod>.md`, `.claude/agents/<mod>-references/`, `.claude/scripts/`, `.claude/rules/`, `docs/` | ❌ **non** |

`claude plugin uninstall vibeflow` ne retire **que** le plugin : les modules déjà copiés dans un
scope restent actifs. Pour une désinstallation **propre et complète**, retire d'abord les modules,
puis le plugin.

### Ordre recommandé

**1. Retirer les modules** (tant que le plugin — donc l'engine — est encore présent) :

```
/vibeflow-install
```

Demande la désinstallation (« désinstalle VibeFlow » / « retire tel module »). En coulisse, le
skill délègue à l'engine :

```bash
# tous les modules installés (lit le registre .vibeflow-installed)
vibeflow-update.sh --scope <user|project|local> uninstall --all

# ou un seul module
vibeflow-update.sh --scope <user|project|local> uninstall <module>
```

Chaque retrait supprime skills / agent + references / scripts / rules appartenant au module et
crée un **backup automatique** avant suppression. Le `--scope` doit être **celui utilisé à
l'install**.

**2. Retirer le plugin :**

```bash
claude plugin uninstall vibeflow
```

> ⚠️ **N'inverse pas l'ordre.** Si tu retires le plugin en premier, le cache
> (`${CLAUDE_PLUGIN_ROOT}`) disparaît et l'engine ne peut plus identifier les scripts/rules à
> nettoyer. Il faudrait alors retirer les fichiers résiduels à la main dans `.claude/`.

### Dépendances externes (GSD / Superpowers)

Elles ne sont **jamais désinstallées automatiquement** (l'engine ne touche qu'aux modules
VibeFlow). Si tu veux aussi les retirer :

- **Superpowers** : `claude plugin uninstall superpowers`
- **GSD** : installé hors VibeFlow via `npx get-shit-done-cc` — le retirer selon sa propre
  procédure (typiquement en supprimant `~/.claude/get-shit-done/` et les skills `gsd-*` déposés).

---

## Sécurité

- L'engine et les modules sont des scripts **shell + Python** auditables ligne par ligne.
- Tous les scripts d'install sont **idempotents** (ré-exécutables sans casser l'installation).
- Les copies créent un backup automatique avant écrasement.
- Le plugin **n'enregistre aucun hook** : il n'exécute rien au démarrage de session. Tout part de
  ton invocation manuelle de `/vibeflow-install`.

---

## Troubleshooting

### `claude plugin` introuvable

Mettre Claude Code à jour : la commande `plugin` doit être disponible.

### L'UX d'install ne s'ouvre pas au démarrage

C'est **normal** : VibeFlow ne s'ouvre **jamais** tout seul. Le lancement est manuel.

➡️ **Tape `/vibeflow-install`** dans Claude Code.

Si la commande n'est pas reconnue, vérifie que le plugin est bien installé et que la session a été
redémarrée après `claude plugin install` :

```bash
claude plugin list
```

Le skill `vibeflow-install` doit y apparaître.

### Le marketplace n'est pas trouvé

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin marketplace list
```

### Réinstaller le plugin

```bash
claude plugin uninstall vibeflow
claude plugin install vibeflow
```
