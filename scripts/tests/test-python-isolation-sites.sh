#!/usr/bin/env bash
# test-python-isolation-sites.sh — Témoin par site de l'isolation de l'interpréteur Python (H-1,
# audit Phase 58 ; correctif ciblé 2026-10-20).
#
# LE DÉFAUT. `python3 -c …` et `python3 - <<EOF` mettent '' (le dossier courant) en tête de
# `sys.path`. Un `json.py` posé à la racine d'un dépôt cloné est donc importé et EXÉCUTÉ par tout
# script VibeFlow lancé depuis ce lab (hooks PreToolUse à chaque outil, garde mémoire, merge-hooks
# à la pose…). Le correctif : `-I` (mode isolé : ni cwd, ni PYTHON*, ni site utilisateur) sur
# chaque invocation inline livrée.
#
# CE QUE LA SUITE PROUVE. Chaque site recensé est LANCÉ pour de vrai depuis un dossier courant
# hostile qui porte un module-piège par module de la bibliothèque standard réellement importé
# par les programmes embarqués (json, re, glob, yaml…) ; un module-piège qui s'exécute écrit une
# trace (HIT). Une cale `python3`/`python` placée en tête du PATH journalise les deux premiers
# arguments de chaque spawn, puis exécute le VRAI interpréteur — donc le piège agit pour de bon.
# Verdict par site :
#   - spawns >= 1  : le site a bien été EXERCÉ (un témoin qui ne spawne rien est aveugle, pas vert) ;
#   - hit = non    : aucun module du dossier courant n'a été exécuté ;
#   - non-isolés=0 : aucun spawn n'a été lancé sans `-I`/`-P` (ou sans la purge de `sys.path`).
#     Un spawn dont le premier argument est un CHEMIN (`python3 /tmp/…/pass_a.py`, lancement d'un
#     fichier) est exempt : sys.path[0] y est le dossier du script, jamais le cwd.
# Les sondes de version (`import sys`) n'importent que des modules déjà chargés au démarrage : elles
# ne sont pas détournables, mais la colonne « non-isolés » les couvre quand même.
#
# MUTATION. Pour trois formes de site (fonction `vf_python`, `"$PYBIN" -I -c`, `python3 -I -`
# heredoc), la suite retire le `-I` dans une COPIE de l'arbre et exige que le piège s'exécute de
# nouveau : sans cela, « hit = non » pourrait être un vert à vide.
#
# Aucune écriture hors de `mktemp -d` ; HOME est jetable ; bornes `alarm` sur chaque site.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS + 1)); echo "  ok  $1"; }
ko() { FAIL=$((FAIL + 1)); echo "  KO  $1 — $2"; }

REAL_PY="$(command -v python3 || true)"
if [ -z "$REAL_PY" ]; then echo "[test-python-isolation-sites] python3 introuvable — NON VÉRIFIABLE" >&2; exit 3; fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/vf-pyiso.XXXXXX")" || exit 3
trap 'rm -rf "$TMP"' EXIT
SHIM="$TMP/shim"; mkdir -p "$SHIM" "$TMP/home"
for n in python3 python; do
  cat > "$SHIM/$n" <<SH
#!/bin/bash
printf 'A %s %.80s\n' "\$1" "\$2" | tr '\n' ' ' >> "\$WITNESS_LOG"; echo >> "\$WITNESS_LOG"
exec "$REAL_PY" "\$@"
SH
  chmod +x "$SHIM/$n"
done

# Dossier courant hostile + squelette de lab.
mkhostile() { # <dir> <root>
  local d="$1" r="$2" m
  mkdir -p "$d/.claude/memory/knowledge" "$d/.planning/phases" "$d/.claude/agents" "$d/.claude/skills" \
           "$d/root/scripts" "$d/root/plugin/.claude-plugin" "$d/root/.claude-plugin" "$TMP/home/.claude/plugins"
  for m in json re base64 datetime subprocess hashlib glob shutil tempfile argparse collections textwrap \
           pathlib time yaml fnmatch shlex calendar urllib getpass random uuid string itertools functools \
           hmac difflib traceback errno stat locale copy enum typing dataclasses contextlib io codecs ast tokenize; do
    printf 'import os\nopen(os.environ["WITNESS_HIT"],"a").write("%s\\n")\n' "$m" > "$d/$m.py"
  done
  printf '# idx\n' > "$d/.claude/memory/MEMORY.md"
  printf '## ADR-001 — Un titre\n\nCorps un.\n\n## ADR-002 — Un titre\n\nCorps deux.\n' > "$d/.claude/memory/ADR.md"
  printf '## LRN-001 — Un titre\n- Category: operational\n\nCorps.\n' > "$d/.claude/memory/LEARNINGS.md"
  printf -- '---\nname: k\ntrust: high\n---\ncorps\n' > "$d/.claude/memory/knowledge/k.md"
  printf '{"hooks":{"PreToolUse":[{"matcher":"x","hooks":[{"type":"command","command":"echo"}]}]}}' > "$d/.claude/settings.json"
  printf -- '---\nname: a\ndescription: d\ntools: Read\n---\ncorps\n' > "$d/.claude/agents/a.md"
  printf '{"mcpServers":{"s":{}}}' > "$d/mcp.json"
  printf '{"hooks":{"PreToolUse":[{"matcher":"Read","hooks":[{"type":"command","command":"bash {{VF_SCRIPTS}}/x.sh"}]}]}}' > "$d/frag.json"
  cp "$r/scripts/bump.sh" "$d/root/scripts/"; cp "$r/VERSION" "$r/README.md" "$r/README.fr.md" "$r/CHANGELOG.md" "$d/root/"
  cp "$r/plugin/.claude-plugin/plugin.json" "$d/root/plugin/.claude-plugin/"; cp "$r/.claude-plugin/marketplace.json" "$d/root/.claude-plugin/"
  printf '{"plugins":{}}' > "$TMP/home/.claude/plugins/installed_plugins.json"
}

# run_site <nom> <racine> <commande> [stdin] → renseigne R_SPAWNS R_HIT R_NONISO
run_site() {
  local name="$1" r="$2" cmd="$3" in="${4:-}" d
  d="$(mktemp -d "$TMP/h.XXXXXX")"; mkhostile "$d" "$r"
  export WITNESS_LOG="$d.log" WITNESS_HIT="$d.hit"; : > "$WITNESS_LOG"; rm -f "$WITNESS_HIT"
  ( cd "$d" && HOME="$TMP/home" PATH="$SHIM:$PATH" WT="$r" H="$d" PYTHONDONTWRITEBYTECODE=1 \
      perl -e 'alarm 40; exec @ARGV' bash -c "$cmd" <<<"$in" >/dev/null 2>&1 )
  R_SPAWNS=$(awk 'NF' "$WITNESS_LOG" | awk 'END{print NR+0}')
  R_NONISO=$(awk 'NF && !/^A -[A-Za-z]*[IP] / && !/sys\.path\[:\]/ && !/^A \//' "$WITNESS_LOG" | awk 'END{print NR+0}')
  R_HIT="non"; [ -s "$WITNESS_HIT" ] && R_HIT="oui($(tr '\n' ',' < "$WITNESS_HIT" | head -c 24))"
}

# Liste des sites : nom|commande|stdin  (le séparateur '|' ne figure dans aucune commande ci-dessous
# hors de la clause stdin finale, qui est la dernière).
sites() { # <racine>
  local G="$1/plugin"
  cat <<EOF
guard-driver-lock|mkdir -p .planning && : > .planning/DRIVER.lock; bash $G/conductor/scripts/guard-driver-lock.sh|{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}
guard-agent-write|bash $G/conductor/scripts/guard-agent-write.sh|{"tool_name":"Write","tool_input":{"file_path":".claude/agents/x.md","content":"hello"}}
guard-bash-registres|bash $G/consolidator/scripts/guard-bash-registres.sh|{"tool_name":"Bash","tool_input":{"command":"cat .claude/memory/MEMORY.md"}}
guard-read-registres|bash $G/consolidator/scripts/guard-read-registres.sh|{"tool_name":"Read","tool_input":{"file_path":".claude/memory/MEMORY.md"}}
post-edit-reindex|bash $G/consolidator/scripts/post-edit-reindex.sh|{"tool_name":"Edit","tool_input":{"file_path":".claude/memory/MEMORY.md"}}
planning-task-context|printf x > .planning/INDEX.md; bash $G/planning-core/scripts/planning-task-context.sh|{"prompt":"x"}
guard-file-size|bash $G/software-architecture/scripts/guard-file-size.sh|{"tool_name":"Write","tool_input":{"file_path":"a.txt","content":"x"}}
check-agents|bash $G/conductor/scripts/check-agents.sh --agents-dir .claude/agents|
check-skills|bash $G/conductor/scripts/check-skills.sh|
check-debug-research|bash $G/conductor/scripts/check-debug-research.sh|{}
check-legacy|bash $G/conductor/scripts/check-legacy.sh|
check-plugin-update|bash $G/conductor/scripts/check-plugin-update.sh|
update-banner|bash $G/conductor/scripts/update-banner.sh|
check-guard-health|bash $G/conductor/scripts/check-guard-health.sh|
dag|bash $G/conductor/scripts/dag.sh init --file=.planning/x.dag.json|
check-description-fidelity|bash $G/conductor/scripts/check-description-fidelity.sh|
reindex|bash $G/consolidator/scripts/reindex.sh --register=ADR --dry-run|
decay-pass|bash $G/consolidator/scripts/decay-pass.sh --dry-run|
detect-duplicates|bash $G/consolidator/scripts/detect-duplicates.sh|
detect-promotions|bash $G/consolidator/scripts/detect-promotions.sh|
probe-memory-guards|bash $G/consolidator/scripts/probe-memory-guards.sh|
recalc-planning|bash $G/planning-core/scripts/recalc-planning.sh --planning=.planning|
audit-infra|bash $G/infrastructure-audit/scripts/audit-infra.sh --axis=hooks|
ensure-design-deps|bash $G/design-orchestrator/scripts/ensure-design-deps.sh|
check-hook-paths|bash $G/dev-orchestrator/scripts/check-hook-paths.sh|
inject-mcp-tools|bash $G/dev-orchestrator/scripts/inject-mcp-tools.sh --target .claude/agents --mcp-json mcp.json --dry-run|
preflight|bash $G/installer/scripts/preflight.sh|
merge-hooks|bash $G/_internal/merge-hooks.sh merge frag.json --settings .claude/s2.json --scripts-prefix .claude/scripts|
vf-portable|source $G/_internal/lib/vf-portable.sh; vf_python -c 'import json'|
bump|bash root/scripts/bump.sh 99.0.0|
EOF
}

echo "== témoin par site (dossier courant hostile, spawns réels) =="
N=0
while IFS='|' read -r name cmd in; do
  [ -n "$name" ] || continue
  N=$((N + 1))
  run_site "$name" "$ROOT" "$cmd" "$in"
  if [ "$R_SPAWNS" -lt 1 ]; then ko "$name" "site NON EXERCÉ (0 spawn) — témoin aveugle, pas vert"
  elif [ "$R_HIT" != "non" ]; then ko "$name" "module du dossier courant EXÉCUTÉ : $R_HIT (spawns=$R_SPAWNS)"
  elif [ "$R_NONISO" -ne 0 ]; then ko "$name" "$R_NONISO spawn(s) sans -I (spawns=$R_SPAWNS)"
  else ok "$name : $R_SPAWNS spawn(s), tous isolés, aucun piège exécuté"; fi
done < <(sites "$ROOT")
[ "$N" -ge 29 ] || ko "recensement" "seulement $N sites listés (attendu >= 29)"

# ------------------------------------------------------------------------------------------------
# MUTATION : l'isolation retirée → le piège doit s'exécuter de nouveau (sinon « hit=non » est à vide).
# ------------------------------------------------------------------------------------------------
echo ""
echo "== mutation : retirer -I doit rendre le piège opérant =="
MR="$TMP/mutroot"; mkdir -p "$MR"
cp -R "$ROOT/plugin" "$ROOT/scripts" "$MR/" ; cp "$ROOT/VERSION" "$ROOT/README.md" "$ROOT/README.fr.md" "$ROOT/CHANGELOG.md" "$MR/"
mkdir -p "$MR/.claude-plugin"; cp "$ROOT/.claude-plugin/marketplace.json" "$MR/.claude-plugin/"
mutate_case() { # <site> <fichier relatif> <motif sed s///>
  local site="$1" rel="$2" prog="$3" line cmd in
  cp "$ROOT/$rel" "$MR/$rel"
  sed "$prog" "$ROOT/$rel" > "$MR/$rel.new" && mv "$MR/$rel.new" "$MR/$rel"
  if cmp -s "$ROOT/$rel" "$MR/$rel"; then ko "MUT $site" "la mutation n'a RIEN changé ($rel) — mutant NON OPPOSABLE"; return; fi
  line="$(sites "$MR" | awk -F'|' -v n="$site" '$1==n')"
  cmd="$(printf '%s' "$line" | awk -F'|' '{print $2}')"; in="$(printf '%s' "$line" | awk -F'|' '{print $3}')"
  run_site "$site" "$MR" "$cmd" "$in"
  if [ "$R_HIT" != "non" ]; then ok "MUT $site : -I retiré → piège exécuté ($R_HIT)"
  else ko "MUT $site" "isolation retirée mais aucun piège exécuté — le témoin ne discrimine pas"; fi
  cp "$ROOT/$rel" "$MR/$rel"
}
mutate_case guard-driver-lock plugin/_internal/lib/vf-portable.sh 's/\$VF_PYTHON_INVOKE -I "\$@"/$VF_PYTHON_INVOKE "$@"/'
mutate_case guard-bash-registres plugin/consolidator/scripts/guard-bash-registres.sh 's/"\$PYBIN" -I -c/"$PYBIN" -c/'
mutate_case dag plugin/conductor/scripts/dag.sh 's/python3 -I - /python3 - /'

echo ""
echo "== bilan : $PASS OK / $FAIL KO =="
[ "$FAIL" -eq 0 ]
