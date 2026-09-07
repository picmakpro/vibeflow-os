---
type: quick
slug: win-pathconv-ii-home-backslash
date: 2026-09-07
status: in-progress
---

# Hotfix — WIN-PATHCONV II : `$HOME` à backslashes écrit tel quel dans settings.json

## Le symptôme (terrain, pas hypothèse)

Lab testeur Windows (`Dossier-engine-V3`), VibeFlow **v2.59.0** confirmée à jour par
`/vf-update --check`. Trois erreurs au `SessionStart`, dont deux VibeFlow :

```
SessionStart:startup hook error … C:\Users\winuser/.claude/scripts/discover-unin…
SessionStart:startup hook error … /bin/bash: C:Userswinuser/.claude/scripts/chec…
```

Le chemin est **mixte** : tête `C:\Users\winuser` en forme Windows, queue `/.claude/scripts` en
POSIX. Sur la seconde ligne, les backslashes ont en plus été mangés (`C:Userswinuser`) — le
chemin ne désigne plus rien, et le hook est mort.

## La cause — dans le code, prouvée sans mesure supplémentaire

`plugin/_internal/merge-hooks.sh`, `exec_safe_prefix()` :

```python
home = os.environ.get("HOME") or os.path.expanduser("~")
return home + p[len(head):]
```

`HOME` est concaténé **tel quel**. Sous Git Bash lancé avec un `HOME` hérité de l'environnement
Windows, `HOME=C:\Users\winuser` — d'où `C:\Users\winuser/.claude/scripts`, exactement la chaîne de
la capture.

Le garde-fou `assert_prefix_uncorrupted()` ne l'attrape pas, et c'est **par construction** :

```python
MSYS_DRIVE_MIDSTRING_RE = re.compile(r".[A-Za-z]:[\\/]")
```

le `.` de tête exige la lettre de lecteur en position > 0, parce qu'une lettre **en tête** est
légitime en scope user sur Windows. Ici `C:` est en position 0 → exempté. Le commentaire du
garde-fou dit lui-même la forme attendue — `C:/Users/…/.claude/scripts`, **avec un slash** — mais
rien ne l'a jamais vérifié.

Ce n'est donc pas une régression du hotfix v2.55.1 (qui a fermé le transport du préfixe par
variable d'environnement, et le ferme toujours : T25 passe). C'est un **second vecteur**, resté
ouvert : la valeur de `HOME` elle-même.

## Périmètre — ce que ce hotfix fait, et ce qu'il ne fait pas

**Fait :**

1. Normaliser `\` → `/` sur le `HOME` résolu dans `exec_safe_prefix()`, et sur tout préfixe
   absolu fourni qui n'est pas un littéral shell. Jamais sur `BASH_ABS` : sa forme Windows est
   une décision explicite documentée dans le fichier (le harness l'exécute hors MSYS).
2. Ajouter au garde-fou une troisième marque — un backslash résiduel dans le préfixe arrête le
   merge, bruyamment, sans rien écrire. Doctrine du lab : un garde-fou en panne est pire qu'un
   garde-fou absent.
3. Test T26 : `HOME=C:\Users\winuser` → `args[0]` en POSIX, zéro backslash dans le settings écrit.

**Ne fait pas** (et le dit) : la migration des **20 entrées de la polarité gouvernance en forme
exec** (`docs/HOOKS-CONTRAT-SORTIE.md` §6, chantier décidé jamais exécuté). C'est elle qui
supprimera la dernière couche d'expansion shell — celle qui a mangé les backslashes de la seconde
ligne d'erreur. Hors périmètre d'un hotfix : chaque conversion exige que le script porte lui-même
sa traduction de code de sortie.

## Tâches

| # | Tâche | Fichier |
|---|---|---|
| 1 | Normalisation POSIX du préfixe + 3e marque du garde-fou | `plugin/_internal/merge-hooks.sh` |
| 2 | Test T26 (HOME Windows à backslashes) | `plugin/_internal/tests/test-merge-hooks.sh` |
| 3 | Section WIN-PATHCONV II (second vecteur) | `docs/WINDOWS-HOOKS-PATHCONV.md` |
| 4 | Release v2.59.1 (3 fichiers de version + 2 README) | `VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `README.fr.md` |

## Critère de vert

`bash plugin/_internal/tests/test-merge-hooks.sh` → 0 KO, T26 inclus. Aucun vert auto-déclaré :
la sortie du runner fait foi.
