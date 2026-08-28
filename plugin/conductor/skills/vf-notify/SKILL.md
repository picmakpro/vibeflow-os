---
name: vf-notify
description: Utiliser quand l'utilisateur veut activer, désactiver, vérifier ou tester les notifications OS natives (toast macOS/Windows/Linux) émises par `notify.sh` aux jalons d'une mission — « active les notifications », « désactive les notifs », « /vf-notify », « /vf-notify on », « /vf-notify off », « /vf-notify status », « /vf-notify test », « est-ce que les notifications sont activées ? ». ✘ pas le hook `stop-notify` (relances de fin de réflexion Claude Code — mécanisme distinct, hors VibeFlow, vit dans `~/.claude/hooks/`) · ✘ pas les jalons GSD fin de phase/milestone (relayés séparément vers l'app Claude via `SendMessage(main)` -> `PushNotification`, hors de ce toggle). Invocable par l'utilisateur ET par `vibeflow-conductor`.
---

# vf-notify — Toggle des notifications OS de mission

> **Mission** : activer/désactiver/vérifier/tester le toast OS natif que `notify.sh` émet aux
> jalons `done`/`failed` du DAG de mission (Phase 33, WTCH-03).
>
> **Iron Law** : *« Opt-in, OFF par défaut. »* (D-33-H, tranché par Samuel le 2026-08-17 —
> amendement de Phase 33 : le défaut ON-par-détection jugé trop agressif après coup. v2.56.0, qui
> aurait porté ce défaut ON, a été retirée de la distribution avant qu'aucun lab ne la reçoive.)

---

## Mécanisme

`notify.sh` (Phase 33, WTCH-03) émet un toast OS best-effort aux jalons `done`/`failed` du DAG de
mission — **jamais** à `running`. Depuis D-33-H, cette émission est **opt-in, OFF par défaut** :
sans armement explicite, `notify.sh` sort silencieusement avant même de sonder un binaire de
canal (`osascript`, `notify-send`, `powershell.exe`).

## Fichier-sentinelle

Scope **machine** (pas un settings local de lab — leçon #38), patron `stop-notify` strict
(touch/rm -f, zéro JSON, zéro entrée `hooks.json` neuve) :

```
${VF_NOTIFY_OPTIN_FILE:-${XDG_CONFIG_HOME:-${HOME:-}/.config}/vibeflow/notify-optin}
```

Cette expression est identique caractère pour caractère à celle posée dans `notify.sh`.
`VF_NOTIFY_OPTIN_FILE` est un point d'injection de **test uniquement** — jamais positionné en
usage normal.

## Actions

Résoudre `notify.sh` via `.claude/scripts/notify.sh` (même patron `.claude/scripts/<script>.sh`
que `vf-calibrate.md`), et le chemin du sentinel via l'expression ci-dessus.

- **`on`** : créer le répertoire parent puis `touch` le fichier résolu.
  ```sh
  mkdir -p "$(dirname "${XDG_CONFIG_HOME:-${HOME:-}/.config}/vibeflow/notify-optin")" && touch "${XDG_CONFIG_HOME:-${HOME:-}/.config}/vibeflow/notify-optin"
  ```
- **`off`** : `rm -f` sur ce même chemin — idempotent, jamais d'erreur si déjà absent.
  ```sh
  rm -f "${XDG_CONFIG_HOME:-${HOME:-}/.config}/vibeflow/notify-optin"
  ```
- **`status`** (défaut si aucun argument) : tester `-f` sur ce chemin, afficher « actif » ou
  « inactif ».
  ```sh
  [ -f "${XDG_CONFIG_HOME:-${HOME:-}/.config}/vibeflow/notify-optin" ] && echo actif || echo inactif
  ```
- **`test`** : créer un fichier `mktemp` **jetable**, invoquer `notify.sh` avec
  `VF_NOTIFY_OPTIN_FILE` pointé sur ce fichier jetable **pour ce seul appel**, titre `VibeFlow`,
  corps `Notification de test (/vf-notify test)`, puis supprimer le fichier jetable. L'état
  persistant du sentinel réel n'est **jamais** lu ni écrit par ce verbe — armé ou désarmé avant
  l'appel, il est identique après.
  ```sh
  TMP_OPTIN="$(mktemp)"
  VF_NOTIFY_OPTIN_FILE="$TMP_OPTIN" .claude/scripts/notify.sh "VibeFlow" "Notification de test (/vf-notify test)"
  rm -f "$TMP_OPTIN"
  ```

> **Piège `user_present`, scopé au push relayé uniquement** : le harness Claude Code n'émet rien
> côté `PushNotification` quand l'utilisateur est actif au terminal (comportement assumé du
> produit, pas un bug VibeFlow, D-33-H Q2 / `33-CONTEXT.md`). Ce piège concerne **le canal push
> relayé** (`SendMessage(main)` -> `PushNotification`, cf. « Ce que ce toggle ne couvre pas »
> ci-dessous) — **pas** le verbe `test` de ce toggle : `notify.sh` n'a aucune détection de
> présence (Pattern H, `mission-flow.md`, les deux canaux restent disjoints en code, en doctrine
> et en gate). Le toast OS déclenché par `/vf-notify test` s'affiche donc que l'utilisateur soit
> actif au terminal ou non — seuls les réglages natifs de l'OS (Ne pas déranger, focus mode,
> permissions de notification) peuvent le masquer, indépendamment de la présence au terminal.

Après l'action, confirmer l'état en une ligne (armé / désarmé / test envoyé) — même consigne
finale que le hook `stop-notify`.

## Ce que ce toggle ne couvre pas

- **Le signal de stall (D-33-F)** : jamais gaté par ce sentinel, ne passe pas par `notify.sh` —
  émis séparément par `dag.sh` (`check_stall_signal()`).
- **Les jalons GSD fin de phase/milestone** : relayés vers l'app Claude via
  `SendMessage(main)` -> `PushNotification`, hors du périmètre de ce toggle.

## Références

- `.claude/scripts/notify.sh`
- `33-CONTEXT.md` § D-33-H
