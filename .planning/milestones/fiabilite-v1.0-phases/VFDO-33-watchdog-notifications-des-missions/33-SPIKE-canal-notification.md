# Spike — canal de notification OS portable pour `notify.sh` (research flag b du ROADMAP)

> Mené le 2026-08-17 en ouverture de mission Phase 33. Recherche documentaire + essais réels
> sur macOS (cette machine). **Aucune machine Windows disponible : voir §Non prouvé.**

## Art antérieur DANS le repo — à réutiliser, pas à refaire

- **`plugin/_internal/lib/vf-portable.sh`** (Phase 30) porte la variable **`IS_WINDOWS`**, calculée
  au chargement (`uname -s` → `MINGW*|MSYS*|CYGWIN*`, repli sur `$OS = Windows_NT`). Le contrat de
  la lib dit explicitement qu'un consommateur **ne doit JAMAIS la redéfinir localement**.
- **Trou réel** : `IS_WINDOWS` vaut **0 sous WSL** (`uname -s` y rend `Linux`). Or WSL est
  précisément le cas où `notify-send` échoue et où `powershell.exe` est la bonne réponse.
  → un détecteur WSL doit être ajouté **dans `vf-portable.sh`**, pas dans `notify.sh`, sous peine
  de rouvrir le défaut que la Phase 30 a fermé.
- **Bloc localisateur canonique** (marqueurs `# >>> vf-portable:locator` / `# <<<`) : copié
  verbatim entre consommateurs et **vérifié par somme de contrôle** par le test T12 de
  `test-vf-portable.sh`, qui liste aujourd'hui **5 consommateurs**. `notify.sh` serait le 6ᵉ →
  **T12 est à mettre à jour**, sinon la suite casse.
  ⚠ Le bloc se termine par `exit 1` si la lib est introuvable : **incompatible avec le fail-open
  silencieux**. `notify.sh` doit sortir `0` muet — déviation à documenter explicitement.
- **Pose par l'engine** : aucune liste blanche à amender. `vibeflow-update.sh` pose
  `plugin/<module>/scripts/*.sh` **par glob** (mode exec) et `scripts/tests/*.sh` de même.
  Déposer `plugin/conductor/scripts/notify.sh` **suffit**.
- ⚠ `.planning/WINDOWS.md` **n'est pas** un document de portabilité : c'est le *Broken Windows
  Ledger* (registre de défauts). Piège de nom.

## Canal par OS

### macOS — `osascript`, avec un piège majeur déjà rencontré par GSD
`osascript display notification` **sort 0 et jette la notification en silence** si le terminal
appelant n'a pas la permission Notifications ; les terminaux tiers (Ghostty, iTerm2, Alacritty,
Kitty) n'apparaissent pas dans les Réglages tant qu'ils n'ont pas délivré une notification →
impasse œuf-poule. C'est l'objet de **gsd-build/gsd-2 issue #2632** (le moteur dont VF dépend).
**Conséquence doctrinale : `exit 0` d'un canal n'est jamais une preuve de délivrance** — ce qui
justifie le « best-effort, on ne vérifie pas ».
Cascade retenue : `terminal-notifier` s'il est présent (il s'enregistre comme sa propre app et
casse l'impasse) → `osascript` sinon. Aucune dépendance ajoutée.

Forme **prouvée sur cette machine**, zéro échappement (argv, injection AppleScript impossible) :
```bash
osascript -e 'on run argv' \
          -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
          -e 'end run' -- "$TITLE" "$BODY" >/dev/null 2>&1
```

### Linux — `notify-send`
Pas installé par défaut sur les images minimales (`libnotify-bin`). Échoue **bruyamment** en
headless/SSH (`Cannot autolaunch D-Bus without X11 $DISPLAY`) → `2>/dev/null` obligatoire.
`notify-send -a VibeFlow -- "$TITLE" "$BODY"`.

### Windows — comparatif des quatre voies
| Voie | Sans installation sur Win10/11 standard ? | Verdict |
|---|---|---|
| `New-BurntToastNotification` (module tiers) | non — PSGallery | **disqualifié** |
| **WinRT `ToastNotificationManager`** | **oui, natif en PowerShell 5.1** | **retenu** |
| `NotifyIcon` + `ShowBalloonTip` | oui, mais force l'attribution « Windows PowerShell », exige un process vivant | repli |
| `msg.exe` | **non** — absent des éditions Home ; et boîte modale bloquante, pas un toast | **disqualifié** |

Trois points décisifs :
1. **Viser `powershell.exe` (5.1, System32), PAS `pwsh`** : les assemblies WinRT ne sont **pas**
   incluses dans PowerShell Core — renversement de l'intuition « prendre le plus récent ».
2. **`powershell.exe` est atteignable depuis Git Bash / MSYS2 par défaut** : `MSYS2_PATH_TYPE`
   vaut `minimal`, dont la doc cite nommément `powershell.exe`. Seul `strict` (opt-in) rompt →
   couvert par `command -v`. **Toujours écrire l'extension `.exe`** (obligatoire sous WSL).
3. **AppUserModelID** : la doc Microsoft est catégorique — un toast sans AUMID enregistré
   **ne s'affiche pas**. Parade établie (défaut de BurntToast) : emprunter l'AUMID de PowerShell
   `{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe`.

**Quoting bash → PowerShell → XML** : résolu sans échappement en passant le script par **stdin**
(`-Command -`, heredoc bash **quoté**) et les valeurs par **variables d'environnement**, échappées
côté PS par `[Security.SecurityElement]::Escape()`. Injection structurellement impossible.

**Latence** : `powershell.exe` paie un démarrage .NET (rapports de 0,3 s à 4-7 s pathologiques).
`-NoProfile` obligatoire + **détachement en arrière-plan** — un manager ne doit jamais attendre
une notification best-effort.

### WSL — `powershell.exe` AVANT `notify-send`
L'interop est active par défaut (`/etc/wsl.conf` `[interop] enabled`/`appendWindowsPath` = true).
`notify-send` est un **faux ami** sous WSL : il échoue sur D-Bus (documenté par openai/codex #8189
pour exactement ce cas d'agent CLI). Détection WSL : `/proc/version` contient `microsoft`/`WSL`.
→ **Un ordre naïf « uname=Linux ⇒ notify-send » est activement faux.**

## Ordre de détection recommandé
```
1. VF_NOTIFY_FORCE_CHANNEL      (injection de test / override utilisateur)
2. WSL détecté            → powershell.exe   (AVANT notify-send)
3. IS_WINDOWS=1           → powershell.exe
4. Darwin                 → terminal-notifier puis osascript
5. Linux                  → notify-send
6. aucun canal            → exit 0 muet
```

## Fail-open silencieux — cinq règles
1. `command -v <bin> >/dev/null 2>&1` comme unique test de disponibilité, jamais un `uname` seul.
2. `>/dev/null 2>&1` sur **chaque** invocation, sans exception.
3. `exit 0` inconditionnel. **Ne PAS utiliser `vf_guard_unavailable`** : elle écrit sur stderr par
   contrat — une notification muette n'est pas un garde en panne, c'est le nominal.
4. Pas de `set -e` ; `set -uo pipefail` seulement.
5. **Détacher** (`( cmd >/dev/null 2>&1 & ) &`) — protège des 4-7 s de PowerShell et d'un
   `notify-send` qui pend sur un D-Bus mort.

## Testabilité en CI Linux — trois points d'injection, aucun toast réel
1. **`VF_NOTIFY_FORCE_CHANNEL`** — court-circuite la détection, teste la construction de commande
   de chaque OS depuis un runner Linux.
2. **Shims d'argv** (`VF_NOTIFY_BIN_DIR` préfixé au PATH) — faux `osascript`, `notify-send`,
   `powershell.exe`, `terminal-notifier` qui journalisent leur `"$@"` et leur stdin : on asserte
   l'**argv exact** et l'ordre de cascade réels, y compris sur des valeurs hostiles.
3. **Shim `uname` + faux `/proc/version`** — fait passer le **vrai** code de détection (dont WSL),
   pas un chemin de test parallèle.

## NON PROUVÉ — à ne pas combler
1. **La chaîne Windows complète n'a jamais été exécutée.** Chaque maillon est adossé à une source,
   mais le ROADMAP disait « non prouvé terrain » et **ça reste vrai** : la recherche a levé le
   risque, pas fourni la preuve. Une recette humaine sur Win10/11 reste requise.
2. **AppID arbitraire vs AUMID PowerShell** : de nombreux gists utilisent un AppID non enregistré
   en rapportant un succès, la doc MS dit que le toast ne s'affichera pas. Contradiction non
   tranchée ; l'AUMID PowerShell est retenu comme strictement plus sûr.
3. **Git Bash spécifiquement** : la doc `MSYS2_PATH_TYPE` couvre MSYS2 ; aucune source primaire
   Git-for-Windows trouvée. Le `command -v` fail-open rend l'incertitude inoffensive.
4. **Latence non mesurée** (valeurs issues de rapports de bugs, biaisées vers le pathologique).
5. **Toast depuis un process détaché/non interactif sous WSL** non caractérisé — signal faible
   d'un mode d'échec réel (erreurs vsock dans codex #8189). À vérifier en même temps que (1).
