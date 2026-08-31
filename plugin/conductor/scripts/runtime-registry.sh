#!/usr/bin/env bash
# runtime-registry.sh — lecture/écriture de la clé racine `runtime` de .planning/config.json
# (contrat gsd-core `runtime-name-policy.cjs::canonicalizeRuntimeName` — cette clé DOIT rester
# une chaîne simple ou être absente, JAMAIS un objet, sous peine d'être silencieusement ignorée
# par `resolveRuntimeNameFromCandidates`/`model-resolver.cjs::resolveActiveRuntime`) et de la
# clé sœur `vf_runtimes` (propriété VibeFlow, `{installed: [...], active: "..."}`, jamais lue par
# gsd-core).
#
# Rétro-compatible sur les 3 formes réelles d'un lab (MIGR-01, Phase 38, D-38-B) :
#   1. absent (ni `runtime` ni `vf_runtimes`) -> actif = claude (miroir de la dérivation
#      gsd-core par défaut), installés = [claude]. Cas RÉEL de ce dépôt (`vibeflow-os` lui-même).
#   2. `runtime` en CHAÎNE, `vf_runtimes` absent -> actif = cette chaîne, installés = [cette
#      chaîne] (rétro-compat : un scalaire implique un seul runtime installé, lui-même).
#   3. `vf_runtimes` présent -> lu directement (installed[]/active). Si `runtime` (racine)
#      diverge de `vf_runtimes.active`, `vf_runtimes.active` est privilégié pour la lecture VF —
#      mais `runtime` n'est JAMAIS corrigé silencieusement à la lecture seule (seul `set-active`
#      écrit).
#
# Écriture (`set-active`) : gatée dry-run -> confirmation -> écriture (ADR-031, D-38-B point 2).
# `--confirmed` seul est OBLIGATOIRE pour écrire ; `--dry-run` prévisualise SANS jamais écrire,
# et l'emporte sur `--confirmed` si les deux sont passés (le plus sûr des deux gagne). Écriture
# ATOMIQUE (fichier temporaire + `mv`, jamais une écriture partielle). `vf_runtimes.installed`
# est toujours ÉTENDU (coexistence par défaut) : la suppression d'un runtime de `installed[]` est
# un geste distinct, hors périmètre de ce script.
#
# Usage:
#   runtime-registry.sh get-active [--config <chemin>]
#   runtime-registry.sh list-installed [--config <chemin>]
#   runtime-registry.sh set-active <runtime> [--config <chemin>] [--dry-run] [--confirmed]
#   runtime-registry.sh -h|--help
#
# Exit codes:
#   0 = succès (lecture rendue, ou écriture --confirmed appliquée, ou --dry-run prévisualisé).
#   1 = erreur d'usage OU set-active sans --confirmed ni --dry-run (refus d'écrire par défaut).
#   2 = config.json introuvable ou JSON imparsable.
set -uo pipefail

CONFIG_PATH=".planning/config.json"
DRY_RUN=0
CONFIRMED=0
CMD=""
NEW_RUNTIME=""

usage() {
  grep '^# ' "$0" | sed 's/^# //'
}

if [ "$#" -eq 0 ]; then
  usage >&2
  exit 1
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  get-active|list-installed)
    CMD="$1"
    shift
    ;;
  set-active)
    CMD="set-active"
    shift
    [ "$#" -ge 1 ] || { echo "[runtime-registry] set-active nécessite un nom de runtime" >&2; exit 1; }
    case "$1" in
      --*) echo "[runtime-registry] set-active nécessite un nom de runtime (reçu une option : $1)" >&2; exit 1 ;;
      *) NEW_RUNTIME="$1"; shift ;;
    esac
    ;;
  *)
    echo "[runtime-registry] verbe inconnu : $1" >&2
    usage >&2
    exit 1
    ;;
esac

while [ "$#" -gt 0 ]; do
  case "$1" in
    --config)
      [ "$#" -ge 2 ] || { echo "[runtime-registry] --config nécessite une valeur" >&2; exit 1; }
      CONFIG_PATH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --confirmed)
      CONFIRMED=1
      shift
      ;;
    *)
      echo "[runtime-registry] argument inconnu : $1" >&2
      exit 1
      ;;
  esac
done

if [ ! -f "$CONFIG_PATH" ]; then
  echo "[runtime-registry] config introuvable : $CONFIG_PATH" >&2
  exit 2
fi

# _rr_node <mode> [args...] — invoque le lecteur/dériveur JSON (aucune dépendance npm,
# JSON.parse/fs.readFileSync suffisent). Sortie sur stdout, exit non-zéro si le JSON est
# imparsable (rc=2, jamais un état par défaut fabriqué sur un fichier cassé).
_rr_node() {
  local mode="$1"
  shift
  node -e '
const fs = require("fs");
const [mode, configPath, ...rest] = process.argv.slice(1);

let config;
try {
  config = JSON.parse(fs.readFileSync(configPath, "utf8"));
} catch (e) {
  process.stderr.write("[runtime-registry] JSON imparsable : " + configPath + " (" + e.message + ")\n");
  process.exit(2);
}

function deriveState(cfg) {
  const vfr = cfg && typeof cfg.vf_runtimes === "object" && cfg.vf_runtimes !== null && !Array.isArray(cfg.vf_runtimes)
    ? cfg.vf_runtimes
    : null;
  const rootRuntime = typeof cfg.runtime === "string" && cfg.runtime.length > 0 ? cfg.runtime : null;

  if (vfr) {
    const installed = Array.isArray(vfr.installed) && vfr.installed.length > 0
      ? vfr.installed.filter((x) => typeof x === "string" && x.length > 0)
      : (rootRuntime ? [rootRuntime] : ["claude"]);
    const active = typeof vfr.active === "string" && vfr.active.length > 0
      ? vfr.active
      : (rootRuntime || "claude");
    return { active, installed: installed.length > 0 ? installed : ["claude"] };
  }
  if (rootRuntime) {
    return { active: rootRuntime, installed: [rootRuntime] };
  }
  return { active: "claude", installed: ["claude"] };
}

const state = deriveState(config);

if (mode === "get-active") {
  process.stdout.write(state.active + "\n");
} else if (mode === "list-installed") {
  process.stdout.write(state.installed.join(" ") + "\n");
} else if (mode === "set-active") {
  const newRuntime = rest[0];
  const oldState = state;
  const newInstalled = oldState.installed.slice();
  if (!newInstalled.includes(newRuntime)) newInstalled.push(newRuntime);

  const preview = {
    old_active: oldState.active,
    old_installed: oldState.installed,
    new_active: newRuntime,
    new_installed: newInstalled,
  };

  const write = rest[1] === "1";
  if (write) {
    const newConfig = Object.assign({}, config);
    newConfig.runtime = newRuntime; // racine reste une CHAINE — contrat gsd-core (T-38-16)
    newConfig.vf_runtimes = { installed: newInstalled, active: newRuntime };
    const tmpPath = configPath + ".rr-tmp." + process.pid;
    fs.writeFileSync(tmpPath, JSON.stringify(newConfig, null, 2) + "\n");
    fs.renameSync(tmpPath, configPath);
  }
  process.stdout.write(JSON.stringify(preview) + "\n");
}
' "$mode" "$CONFIG_PATH" "$@"
}

case "$CMD" in
  get-active)
    _rr_node get-active
    exit $?
    ;;
  list-installed)
    _rr_node list-installed
    exit $?
    ;;
  set-active)
    if [ "$DRY_RUN" -eq 1 ]; then
      PREVIEW="$(_rr_node set-active "$NEW_RUNTIME" 0)" || exit $?
      node -e '
const p = JSON.parse(process.argv[1]);
console.log("[dry-run] runtime: " + p.old_active + " -> " + p.new_active);
console.log("[dry-run] vf_runtimes.installed: [" + p.old_installed.join(",") + "] -> [" + p.new_installed.join(",") + "]");
console.log("[dry-run] aucune écriture — relancer avec --confirmed pour appliquer");
' "$PREVIEW"
      exit 0
    fi
    if [ "$CONFIRMED" -ne 1 ]; then
      echo "[runtime-registry] --confirmed requis pour écrire — relancer avec --dry-run pour prévisualiser d'abord" >&2
      exit 1
    fi
    PREVIEW="$(_rr_node set-active "$NEW_RUNTIME" 1)" || exit $?
    node -e '
const p = JSON.parse(process.argv[1]);
console.log("[runtime-registry] runtime: " + p.old_active + " -> " + p.new_active);
console.log("[runtime-registry] vf_runtimes.installed: [" + p.old_installed.join(",") + "] -> [" + p.new_installed.join(",") + "]");
' "$PREVIEW"
    exit 0
    ;;
esac
