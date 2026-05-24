# INSTALL — vibeflow-os

> Guide d'installation des modules vibeflow-os dans un lab existant.

---

## Pré-requis

- Accès en lecture au repo `picmakpro/vibeflow-os` (privé) via `gh CLI` ou SSH key
- Lab cible avec structure standard : `.claude/skills/`, `.claude/scripts/`, `.claude/memory/`
- `bash 4+`, `python3 3.8+`, `awk`, `grep`, `sed` (macOS/Linux)

---

## Méthode 1 — Install via script vibeflow-update.sh (recommandée)

### Étape 1 — Cloner le repo en cache local

```bash
cd /chemin/vers/votre-lab
git clone --depth 1 https://github.com/picmakpro/vibeflow-os.git .vibeflow-cache
```

Le dossier `.vibeflow-cache/` doit être ajouté à `.gitignore` du lab (c'est un cache, pas du code de projet).

### Étape 2 — Installer le script vibeflow-update.sh

```bash
mkdir -p .claude/scripts
cp .vibeflow-cache/_internal/vibeflow-update.sh .claude/scripts/
chmod +x .claude/scripts/vibeflow-update.sh
```

### Étape 3 — Installer un module

```bash
.claude/scripts/vibeflow-update.sh install consolidator
```

Cela copie :
- `.vibeflow-cache/consolidator/SKILL.md` → `.claude/skills/consolidator/SKILL.md`
- `.vibeflow-cache/consolidator/references/` → `.claude/skills/consolidator/references/`
- `.vibeflow-cache/consolidator/scripts/*.sh` → `.claude/scripts/`
- Crée `.claude/scripts/.vibeflow-installed` (registre des modules installés)

### Étape 4 — Configurer les hooks (optionnel mais recommandé)

Le module `consolidator` propose un hook `SessionEnd` async qui appelle `archive.sh`. Pour l'activer, ajouter dans `.claude/settings.json` ou `settings.local.json` :

```json
"hooks": {
  "SessionEnd": [{
    "hooks": [{
      "type": "command",
      "command": "test -x .claude/scripts/archive.sh && .claude/scripts/archive.sh --async --threshold-days=90 >/dev/null 2>&1 &"
    }]
  }]
}
```

Voir `.vibeflow-cache/consolidator/SKILL.md` pour les autres hooks proposés.

---

## Méthode 2 — Install manuelle (sans script)

Si tu préfères contrôler chaque copie :

```bash
git clone --depth 1 https://github.com/picmakpro/vibeflow-os.git /tmp/vibeflow-os
cp -r /tmp/vibeflow-os/consolidator/SKILL.md .claude/skills/consolidator/
cp -r /tmp/vibeflow-os/consolidator/references .claude/skills/consolidator/
cp /tmp/vibeflow-os/consolidator/scripts/*.sh .claude/scripts/
chmod +x .claude/scripts/*.sh
```

---

## Mises à jour

### Vérifier les versions disponibles

```bash
.claude/scripts/vibeflow-update.sh status
```

Sortie type :
```
Module           Installed  Available  Status
consolidator     v1.0.0     v1.0.1     Update available
infrastructure-  -          v1.0.0     Not installed
```

### Update un module

```bash
.claude/scripts/vibeflow-update.sh update consolidator
```

Le script :
1. Tire les derniers commits du cache `.vibeflow-cache/`
2. Backup l'installation actuelle dans `.claude/.backups/`
3. Copie les nouveaux fichiers
4. Met à jour `.claude/scripts/.vibeflow-installed`

### Update tous

```bash
.claude/scripts/vibeflow-update.sh update --all
```

### Rollback

```bash
.claude/scripts/vibeflow-update.sh rollback consolidator
```

---

## Désinstallation d'un module

```bash
.claude/scripts/vibeflow-update.sh uninstall consolidator
```

Le script supprime les fichiers installés et l'entrée dans `.vibeflow-installed`. Le cache `.vibeflow-cache/` reste intact (utile pour re-installer plus tard).

---

## Sécurité

- Tous les scripts sont **idempotents** (peuvent être ré-exécutés sans casser l'installation)
- Tous les `--apply` créent un backup automatique
- Les modules sont **distribués en lecture seule** (le script `vibeflow-update.sh` ne pousse jamais de modifications vers le repo central)
- Pour proposer une modification : fork + PR sur `picmakpro/vibeflow-os`

---

## Troubleshooting

### "Permission denied" sur scripts

```bash
chmod +x .claude/scripts/*.sh .claude/scripts/tests/*.sh
```

### Cache désynchronisé

```bash
rm -rf .vibeflow-cache
git clone --depth 1 https://github.com/picmakpro/vibeflow-os.git .vibeflow-cache
```

### Module corrompu

```bash
.claude/scripts/vibeflow-update.sh rollback <module>
# OU
.claude/scripts/vibeflow-update.sh reinstall <module>
```

### Auth GitHub échoue

```bash
gh auth status
gh auth login  # si nécessaire
```
