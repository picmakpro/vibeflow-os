#!/usr/bin/env bash
# notify.sh — canal de notification OS best-effort, portable Windows/WSL/macOS/Linux (Phase 33,
# WTCH-03). Shellé en subprocess par dag.sh (33-05, hors ce fichier) aux jalons d'une mission
# (fin de nœud, halt condition). FAIL-OPEN SILENCIEUX INCONDITIONNEL : ce script ne doit JAMAIS
# pouvoir faire échouer, ralentir ou bruiter l'appelant qui le shelle — une notification muette
# est le comportement NOMINAL (33-SPIKE-canal-notification.md règle 3, CONTEXT §QUAL-01), pas un
# garde en panne. Ne JAMAIS appeler la fonction de marqueur de garde de vf-portable.sh ici (celle
# qui écrit sur stderr par contrat) — exception documentée, vérifiée par grep dans la suite dédiée.
#
# Usage : notify.sh <TITLE> <BODY>
#
# set -uo pipefail SANS -e (règle 4 du spike) : une commande qui échoue (command -v absent, canal
# indisponible) ne doit JAMAIS faire mourir le script avant son `exit 0` final.
set -uo pipefail

# ---------------------------------------------------------------------------------------------
# Résolution TOLÉRANTE de vf-portable.sh — DÉVIATION DÉLIBÉRÉE ET DOCUMENTÉE (33-04-PLAN.md
# <deviation>). Ne PAS copier ici le bloc localisateur canonique entre marqueurs (celui vérifié
# par somme de contrôle dans test-vf-portable.sh, cf. T12) — sa queue `exit 1` si la lib est
# introuvable est structurellement incompatible avec le fail-open exigé par ce script. Recherche
# des QUATRE mêmes candidats que ce bloc canonique, mêmes chemins, même ordre — mais l'issue en
# cas d'échec est un repli silencieux, jamais une sortie. (Le marqueur littéral lui-même n'est
# volontairement pas cité ici — grep -c sur ce fichier doit rendre 0, preuve machine du non-copié.)
# ---------------------------------------------------------------------------------------------
_vf_notify_lib=""
# Canonicalisation cd+pwd (motif D-07, deja applique 5x dans ce depot — dag.sh, check-guard-health.sh,
# ...) : un `dirname "$0"` brut resout de facon dependante du cwd de l'appelant quand $0 est un
# chemin relatif. Repli sur le brut UNIQUEMENT si le `cd` echoue (chemin deja absent) — jamais un
# `exit`, coherent avec le fail-open inconditionnel de tout ce script.
_vf_notify_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || _vf_notify_dir="$(dirname "$0")"
for _vf_notify_cand in "$_vf_notify_dir/vf-portable.sh" "$_vf_notify_dir/lib/vf-portable.sh"; do
  [ -f "$_vf_notify_cand" ] && { _vf_notify_lib="$_vf_notify_cand"; break; }
done
if [ -z "$_vf_notify_lib" ]; then
  _vf_notify_walk="$_vf_notify_dir"
  for _vf_notify_i in 1 2 3 4; do
    _vf_notify_walk="$_vf_notify_walk/.."
    if [ -f "$_vf_notify_walk/_internal/lib/vf-portable.sh" ]; then
      _vf_notify_lib="$_vf_notify_walk/_internal/lib/vf-portable.sh"
      break
    fi
  done
fi
if [ -z "$_vf_notify_lib" ] && [ -f "$_vf_notify_dir/../../scripts/vf-portable.sh" ]; then
  _vf_notify_lib="$_vf_notify_dir/../../scripts/vf-portable.sh"
fi
if [ -n "$_vf_notify_lib" ]; then
  # Trouvée : elle doit charger proprement sous set -u (c'est SA propre garantie de chargement) —
  # pas de 2>/dev/null sur le source lui-même.
  . "$_vf_notify_lib"
else
  # Repli SILENCIEUX — jamais un `source`, jamais une sortie. Seul cas autorisé de (re)définition
  # locale de ces deux variables : uniquement si AUCUN candidat n'a été trouvé.
  IS_WINDOWS=0
  IS_WSL=0
fi
unset _vf_notify_lib _vf_notify_dir _vf_notify_cand _vf_notify_walk _vf_notify_i

# ---------------------------------------------------------------------------------------------
# Validation des arguments — TITLE/BODY manquants ou vides => sortie 0 immédiate, AUCUNE
# invocation de canal (fail-open silencieux, pas une notif à moitié construite).
# ---------------------------------------------------------------------------------------------
TITLE="${1:-}"
BODY="${2:-}"
if [ "$#" -lt 2 ] || [ -z "$TITLE" ] || [ -z "$BODY" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------------------------
# Gate d'opt-in (D-33-H, amendement Phase 33 tranché par Samuel le 2026-08-17) : l'émission OS
# native passe d'ON-par-détection à OPT-IN, OFF PAR DÉFAUT. Aucune migration de parc n'est due —
# v2.56.0 (qui aurait porté le défaut ON) a été retirée de la distribution avant qu'aucun lab ne
# la reçoive. Fichier-sentinelle scope MACHINE, patron `stop-notify` strict (touch/rm -f, jamais
# un settings local, leçon #38) : géré par le toggle `/vf-notify` (on/off/status/test).
# `VF_NOTIFY_OPTIN_FILE` est un point d'injection de TEST UNIQUEMENT (jamais positionné en usage
# normal — même statut que `VF_PROC_VERSION_PATH` dans vf-portable.sh). Ce gate coupe AVANT tout
# `command -v` de canal : sentinel absent => sortie immédiate, aucun binaire même sondé. Le signal
# de stall (D-33-F) ne passe JAMAIS par ce fichier ni par ce script — il est émis séparément par
# `dag.sh` (`check_stall_signal()`, dag.sh:223-246) et n'appelle jamais notify.sh
# (`record_milestone()`, dag.sh:248-268, est la seule fonction qui invoque ce script).
VF_NOTIFY_OPTIN_FILE="${VF_NOTIFY_OPTIN_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/vibeflow/notify-optin}"
[ -f "$VF_NOTIFY_OPTIN_FILE" ] || exit 0

# ---------------------------------------------------------------------------------------------
# Cascade de détection — ordre figé : VF_NOTIFY_FORCE_CHANNEL -> WSL -> Windows natif -> Darwin ->
# Linux -> aucun canal. Le cas WSL+notify-send-présent DOIT choisir powershell.exe, JAMAIS
# notify-send (spike §WSL, piège nommé — cas N5, anti-régression clé, ne jamais retirer).
# ---------------------------------------------------------------------------------------------
if [ -n "${VF_NOTIFY_FORCE_CHANNEL:-}" ]; then
  channel="$VF_NOTIFY_FORCE_CHANNEL"
elif [ "${IS_WSL:-0}" = "1" ]; then
  channel="windows"
elif [ "${IS_WINDOWS:-0}" = "1" ]; then
  channel="windows"
elif [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
  channel="darwin"
else
  channel="linux"
fi

# ---------------------------------------------------------------------------------------------
# Canaux — chaque fonction teste elle-même `command -v` et ne fait RIEN (return silencieux) si
# absente. La détection (`command -v`) est SYNCHRONE (rapide, jamais d'E/S bloquante) ; seul
# l'appel réel au binaire de canal est DÉTACHÉ (`( … & )`, un seul niveau de fork au point
# d'invocation) — un appelant ne doit JAMAIS attendre les 0,3-7s de démarrage .NET de
# powershell.exe ni un notify-send qui pend sur un D-Bus mort, mais une détection synchrone laisse
# une commande qui échoue réellement mourir le script AVANT le fork si `set -e` était présent
# (il ne l'est pas — règle 4 du spike — mais la structure ne le masque pas non plus). AUCUNE
# fonction n'écrit sur stdout/stderr en dehors de la commande détachée elle-même (déjà
# >/dev/null 2>&1). Disponibilité testée UNIQUEMENT par `command -v`, jamais un `uname` seul.
# ---------------------------------------------------------------------------------------------
_notify_darwin() {
  if command -v terminal-notifier >/dev/null 2>&1; then
    ( terminal-notifier -title "$TITLE" -message "$BODY" >/dev/null 2>&1 & )
  elif command -v osascript >/dev/null 2>&1; then
    ( osascript -e 'on run argv' \
              -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
              -e 'end run' -- "$TITLE" "$BODY" >/dev/null 2>&1 & )
  fi
}

_notify_linux() {
  # Le test de disponibilité DOIT rester la CONDITION d'un `if` (jamais une ligne séparée suivie
  # d'un test $?) — c'est cette forme qui rend la mutation rouge n°3 reproductible et son point
  # d'injection nommable.
  if command -v notify-send >/dev/null 2>&1; then
    ( notify-send -a VibeFlow -- "$TITLE" "$BODY" >/dev/null 2>&1 & )
  fi
}

_notify_windows() {
  # powershell.exe (5.1, System32) TOUJOURS — jamais le lanceur PowerShell Core (assemblies WinRT
  # absentes de ce dernier, spike §Windows point 1). Extension .exe TOUJOURS (obligatoire sous WSL).
  # Script par STDIN (heredoc bash QUOTÉ — aucune interpolation bash dans le corps), valeurs
  # passées par variables d'environnement, échappées côté PS par
  # [Security.SecurityElement]::Escape() — jamais de concaténation de chaîne dans le script.
  command -v powershell.exe >/dev/null 2>&1 || return 0
  ( env VF_NOTIFY_TITLE="$TITLE" VF_NOTIFY_BODY="$BODY" \
    powershell.exe -NoProfile -NonInteractive -Command - <<'PS' >/dev/null 2>&1 & )
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null

$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
$title = [Security.SecurityElement]::Escape($env:VF_NOTIFY_TITLE)
$body  = [Security.SecurityElement]::Escape($env:VF_NOTIFY_BODY)

$template = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$title</text>
      <text>$body</text>
    </binding>
  </visual>
</toast>
"@

$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml($template)
$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($toast)
PS
}

# ---------------------------------------------------------------------------------------------
# Dispatch — SYNCHRONE (le détachement vit dans chaque fonction, autour du seul appel qui peut
# être lent) : un appelant (dag.sh en 33-05) ne doit JAMAIS attendre le canal lui-même, mais la
# détection de disponibilité reste dans le flux principal du script.
# ---------------------------------------------------------------------------------------------
case "$channel" in
  windows) _notify_windows ;;
  darwin)  _notify_darwin ;;
  linux)   _notify_linux ;;
  # Branche résiduelle laissée telle quelle (décision explicite, pas un oubli) : elle reste
  # atteignable quand l'opt-in est ARMÉ et que VF_NOTIFY_FORCE_CHANNEL porte une valeur hors
  # windows/darwin/linux (`none`, `off`, une faute de frappe). Le gate ci-dessus ne couvre QUE le
  # défaut d'émission (D-33-H), il ne valide pas la valeur de VF_NOTIFY_FORCE_CHANNEL — durcir
  # cette branche est un chantier de robustesse distinct, hors périmètre littéral ici.
  *) : ;;
esac

exit 0
