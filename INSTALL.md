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

```bash
claude plugin update vibeflow
```

Récupère la dernière version publiée du plugin depuis le marketplace, puis re-passer par
`/vibeflow-install` si tu veux activer de nouveaux modules apparus dans le catalogue.

---

## Désinstallation

```bash
claude plugin uninstall vibeflow
```

Cela retire le plugin (skill + bundle) du cache de Claude Code. Les modules déjà copiés
dans un scope (`.claude/skills/`, `.claude/agents/`, etc.) restent en place ; les retirer
manuellement si besoin.

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
