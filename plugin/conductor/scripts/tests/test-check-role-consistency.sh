#!/usr/bin/env bash
# Test de check-role-consistency.sh (Phase 58, RLPO-03, RLPO-08, RLPO-09) — autonome.
# Cas CR-TRACE-1..3, CR-HOOK-POSE (câblage réel par l'engine), CR-0, CR-1a..d, CR-3a..d, CR-5a..e,
# CR-5f, CR-HOSTILE (audit H-1), CR-CFG-LIEN, CR-CFG-FIFO, CR-CFG-GROS, CR-CFG-BORNE (audit M-1), CR-OUTIL, CR-BOM, CR-ENV, CR-RACINE, CR-PART, CR-64, CR-HELP, CR-RO, CR-CODES, CR-17 ;
# mutants MUT-liste-hors, MUT-silence, MUT-analyse, MUT-hook, MUT-cle, MUT-brut, MUT-analyse-hook, MUT-pendant, MUT-motif-lecteur(-d), MUT-outillage, MUT-isole, MUT-cfg-lien, MUT-cfg-fifo, MUT-cfg-taille.
# Chaque mutant : copie différente de l'original (cmp -s), valide (bash -n), rouge pour la bonne
# raison (attendu/obtenu imprimés), original revérifié vert.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
REAL="$SCRIPTS_DIR/check-role-consistency.sh"
READER="$SCRIPTS_DIR/vf-role.sh"
PORTABLE="$REPO/plugin/_internal/lib/vf-portable.sh"
TARGET="$REAL"
BASH_BIN="$(command -v bash)"

PASS=0; FAIL=0; SKIPPED=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; SKIPPED=$((SKIPPED+1)); }

# L'engine de pose veut un PYTHONUSERBASE sauvegardé AVANT de changer HOME.
PYUB="$(python3 -m site --user-base 2>/dev/null || true)"
TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
HOME_J="$TMP/home"; mkdir -p "$HOME_J"
HEALTH="$TMP/health"
: > "$TMP/rcs"; : > "$TMP/ro-bad"
MARK="zzSECRETzz"

fp() { # <dir> : empreinte (noms + sommes) d'un arbre
  ( cd "$1" && find . | LC_ALL=C sort | while IFS= read -r f; do
      if [ -f "$f" ] && [ ! -L "$f" ]; then cksum < "$f"; fi
      echo "$f"
    done )
}

RC=0; ERR=""; OUT=""
RUNPFX=""   # préfixe de commande (borne de temps) — vide par défaut
# Borne de temps : la commande tourne dans son propre groupe de processus, et l'expiration tue TOUT le
# groupe (un `alarm` + `exec` seul ne tuait que le processus de tête : le petit-enfant bloqué sur
# l'open() d'un FIFO survivait, orphelin, en tenant les descripteurs hérités — un tube en aval ne
# voyait jamais EOF). Expiration => rc 142, comme avant.
cat > "$TMP/bound.sh" <<'BOUND'
#!/bin/sh
exec perl -e '
  my $pid = fork(); die "fork: $!" unless defined $pid;
  if (!$pid) { setpgrp(0, 0); exec @ARGV or exit 127; }
  $SIG{ALRM} = sub { kill "KILL", -$pid; kill "KILL", $pid; waitpid($pid, 0); exit 142; };
  alarm 8; waitpid($pid, 0); my $st = $?;
  kill "KILL", -$pid;   # rien ne survit au retour normal non plus
  exit($st & 127 ? 128 + ($st & 127) : $st >> 8);
' "$@"
BOUND
chmod +x "$TMP/bound.sh"
# runr <cwd> <assignations d'environnement|-> args... -> $RC, $TMP/out, $TMP/errf ; empreinte avant/après
runr() {
  local cwd="$1" ev="$2" n; shift 2
  [ "$ev" = "-" ] && ev=""
  fp "$cwd" > "$TMP/fp-before"
  # shellcheck disable=SC2086
  (cd "$cwd" && env -u VF_ROLE -u CLAUDE_PROJECT_DIR HOME="$HOME_J" VF_GUARD_HEALTH_DIR="$HEALTH" $ev \
      $RUNPFX "$BASH_BIN" "$TARGET" "$@" >"$TMP/out" 2>"$TMP/errf"); RC=$?
  fp "$cwd" > "$TMP/fp-after"
  cmp -s "$TMP/fp-before" "$TMP/fp-after" || echo "$cwd" >> "$TMP/ro-bad"
  ERR="$(cat "$TMP/errf")"; OUT="$(cat "$TMP/out")"
  echo "$RC" >> "$TMP/rcs"
}
out_is() { printf '%s\n' "$1" > "$TMP/exp"; cmp -s "$TMP/exp" "$TMP/out"; }
out_empty() { [ ! -s "$TMP/out" ]; }
err_empty() { [ ! -s "$TMP/errf" ]; }
no_mark() { ! command grep -q "$MARK" "$TMP/out" "$TMP/errf"; }

mklab() { local d; d="$(mktemp -d "$TMP/lab.XXXXXX")"; mkdir -p "$d/.claude"; printf '%s' "$d"; }
setrole() { printf "$2" > "$1/.claude/vibeflow-role"; }      # setrole <lab> <printf-format>
setcfg() { mkdir -p "$1/.planning"; printf '%s' "$2" > "$1/.planning/config.json"; }  # setcfg <lab> <json>

# sonde <nom> <attendu> <obtenu> : rapporte un cas
verdict() { # <id> <0|1> <attendu> <obtenu>
  if [ "$2" -eq 0 ]; then ok "$1"; else ko "$1 — attendu $3, obtenu $4"; fi
}

echo "== test-check-role-consistency =="

# --- Probes réutilisées par les mutants : rendent 0 si le comportement est conforme, 1 sinon.
LASTMSG=""
probe_1a() {  # CR-1a : poste hors liste => rc 1 + constat
  local L; L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" '{"vf_roles":["dev"]}'
  runr "$L" - --path "$L"
  LASTMSG="attendu rc 1 + « hors de la liste », obtenu rc $RC [$ERR]"
  [ "$RC" -eq 1 ] && printf '%s' "$ERR" | command grep -q 'hors de la liste'
}
probe_silence_cli() {  # CR-TRACE-2 CLI : aucune source => rc 3, flux vides
  local L; L="$(mklab)"
  runr "$L" - --path "$L"
  LASTMSG="attendu rc 3 flux vides, obtenu rc $RC out[$OUT] err[$ERR]"
  [ "$RC" -eq 3 ] && out_empty && err_empty
}
probe_silence_hook() {  # CR-TRACE-2 --hook : aucune source => rc 0, flux vides
  local L; L="$(mklab)"
  runr "$L" - --path "$L" --hook
  LASTMSG="attendu rc 0 flux vides, obtenu rc $RC out[$OUT] err[$ERR]"
  [ "$RC" -eq 0 ] && out_empty && err_empty
}
probe_5a() {  # CR-5a : config.json non JSON => rc 5 + stderr non vide
  local L; L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" 'pas du json {'
  runr "$L" - --path "$L"
  LASTMSG="attendu rc 5 + stderr non vide, obtenu rc $RC err[$ERR]"
  [ "$RC" -eq 5 ] && [ -n "$ERR" ]
}
probe_5a_hook() {  # CR-5a --hook : rc 5 jamais traduit, stdout vide
  local L; L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" 'pas du json {'
  runr "$L" - --path "$L" --hook
  LASTMSG="attendu rc 5 stdout vide, obtenu rc $RC out[$OUT]"
  [ "$RC" -eq 5 ] && out_empty
}
probe_0() {  # CR-0 : poste listé => rc 0
  local L; L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" '{"vf_roles":["product","dev"]}'
  runr "$L" - --path "$L"
  LASTMSG="attendu rc 0 stdout vide, obtenu rc $RC out[$OUT] err[$ERR]"
  [ "$RC" -eq 0 ] && out_empty
}
probe_hostile() {  # CR-HOSTILE (audit H-1) : un json.py à la racine du dépôt n'est jamais importé
  local L W; L="$(mklab)"; W="$TMP/temoin-json.$$"; rm -f "$W"
  setrole "$L" 'product\n'; setcfg "$L" '{"vf_roles":["product"]}'
  printf 'open(%s, "w").write("importe")\n' "\"$W\"" > "$L/json.py"
  runr "$L" PYTHONDONTWRITEBYTECODE=1 --path "$L"
  LASTMSG="attendu rc 0 et AUCUN témoin écrit, obtenu rc $RC, témoin $([ -e "$W" ] && echo ÉCRIT || echo absent)"
  [ "$RC" -eq 0 ] && [ ! -e "$W" ]
}
probe_cfg_lien() {  # CR-CFG-LIEN (audit M-1) : config.json lien (valide ou pendant) => rc 5, non lu
  local L1 L2 r1 r2; L1="$(mklab)"; L2="$(mklab)"
  setrole "$L1" 'product\n'; setrole "$L2" 'product\n'
  printf '%s' '{"vf_roles":["product"]}' > "$TMP/cible-valide.json"
  mkdir -p "$L1/.planning" "$L2/.planning"
  ln -s "$TMP/cible-valide.json" "$L1/.planning/config.json"
  ln -s "$TMP/cible-inexistante.json" "$L2/.planning/config.json"
  runr "$L1" - --path "$L1"; r1=$RC
  runr "$L2" - --path "$L2"; r2=$RC
  LASTMSG="attendu rc 5 pour un lien valide ET un lien pendant, obtenu rc $r1 / $r2"
  [ "$r1" -eq 5 ] && [ "$r2" -eq 5 ]
}
probe_cfg_fifo() {  # CR-CFG-FIFO (audit M-1) : config.json FIFO => rc 5 sans blocage (jamais ouvert)
  local L; L="$(mklab)"; setrole "$L" 'product\n'; mkdir -p "$L/.planning"; mkfifo "$L/.planning/config.json"
  RUNPFX="$TMP/bound.sh"; runr "$L" - --path "$L"; RUNPFX=""
  LASTMSG="attendu rc 5 sans blocage, obtenu rc $RC (142 = bloqué sur le FIFO)"
  [ "$RC" -eq 5 ]
}
probe_cfg_gros() {  # CR-CFG-GROS / BORNE (audit M-1) : 65537 octets => rc 5 ; 65536 octets => rc 0
  local L1 L2 r1 r2 base pad; L1="$(mklab)"; L2="$(mklab)"
  setrole "$L1" 'product\n'; setrole "$L2" 'product\n'
  base='{"vf_roles":["product"]}'
  pad="$(awk -v n=$((65537 - ${#base})) 'BEGIN { s = sprintf("%" n "s", ""); printf "%s", s }')"
  setcfg "$L1" "$base$pad"
  pad="$(awk -v n=$((65536 - ${#base})) 'BEGIN { s = sprintf("%" n "s", ""); printf "%s", s }')"
  setcfg "$L2" "$base$pad"
  runr "$L1" - --path "$L1"; r1=$RC
  runr "$L2" - --path "$L2"; r2=$RC
  LASTMSG="attendu rc 5 à 65537 octets et rc 0 à 65536, obtenu rc $r1 / $r2"
  [ "$r1" -eq 5 ] && [ "$r2" -eq 0 ]
}
HOOKS_JSON="$SCRIPTS_DIR/../hooks/hooks.json"
probe_hook_timeout() {  # CR-HOOK-TIMEOUT (audit M-1) : l'entrée SessionStart du gate porte un timeout court (1..10 s)
  local f="${1:-$HOOKS_JSON}" t
  t="$(jq -r '[.hooks.SessionStart[].hooks[] | select((.args // []) | map(test("check-role-consistency\\.sh")) | any) | .timeout] | .[0] // "absent"' "$f" 2>/dev/null)"
  LASTMSG="attendu un timeout entier entre 1 et 10 sur l'entrée check-role-consistency, obtenu [$t]"
  case "$t" in ''|*[!0-9]*) return 1 ;; esac
  [ "$t" -ge 1 ] && [ "$t" -le 10 ]
}
probe_bom() {  # CR-BOM : octets bruts jamais réimprimés
  local L; L="$(mklab)"; setrole "$L" '\357\273\277product\r\n'
  runr "$L" - --path "$L" --hook
  LASTMSG="attendu stdout exactement « Poste : product », obtenu rc $RC [$(printf '%s' "$OUT" | od -c | head -3 | tr '\n' ' ')]"
  [ "$RC" -eq 0 ] && out_is 'Poste : product'
}

probe_5c() {  # CR-5c : lien symbolique => rc 5, motif du lecteur réaffiché, marqueur absent
  local L; L="$(mklab)"; setcfg "$L" '{"vf_roles":["product","dev"]}'
  printf 'product %s' "$MARK" > "$TMP/cible-lien"; ln -s "$TMP/cible-lien" "$L/.claude/vibeflow-role"
  runr "$L" - --path "$L" --hook
  LASTMSG="attendu rc 5 stdout vide, motif « fichier de poste illisible : lien symbolique » sur stderr, sans marqueur ; obtenu rc $RC out[$OUT] err[$ERR]"
  [ "$RC" -eq 5 ] && out_empty && no_mark && printf '%s' "$ERR" | command grep -qF 'fichier de poste illisible : lien symbolique'
}
probe_5d() {  # CR-5d : deux lignes => rc 5, motif du lecteur réaffiché, marqueur absent
  local L; L="$(mklab)"; setcfg "$L" '{"vf_roles":["product","dev"]}'; setrole "$L" "product\nconsigne-piege $MARK\n"
  runr "$L" - --path "$L" --hook
  LASTMSG="attendu rc 5 stdout vide, motif « fichier de poste illisible : plusieurs lignes » sur stderr, sans marqueur ; obtenu rc $RC out[$OUT] err[$ERR]"
  [ "$RC" -eq 5 ] && out_empty && no_mark && printf '%s' "$ERR" | command grep -qF 'fichier de poste illisible : plusieurs lignes'
}
probe_pendant() {  # CR-5f : lien pendant (cible absente) => rc 5, jamais le silence de l'état 0
  local L; L="$(mklab)"; setcfg "$L" '{"vf_roles":["product","dev"]}'
  ln -s "$TMP/cible-inexistante-$$" "$L/.claude/vibeflow-role"
  runr "$L" - --path "$L" --hook
  LASTMSG="attendu rc 5 (lien pendant jugé illisible), obtenu rc $RC out[$OUT] err[$ERR]"
  [ "$RC" -eq 5 ] && out_empty && [ -n "$ERR" ]
}
probe_outillage() {  # CR-OUTIL : vf-portable.sh absent => rc 5 (jamais 1), stderr nomme la cause, stdout vide
  local L D; L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" '{"vf_roles":["dev"]}'
  D="$(mktemp -d "$TMP/sansportable.XXXXXX")"; cp "$TARGET" "$D/check-role-consistency.sh"; cp "$READER" "$D/vf-role.sh"
  local save="$TARGET"; TARGET="$D/check-role-consistency.sh"
  runr "$L" - --path "$L" --hook; local h="$RC" ho="$OUT"
  runr "$L" - --path "$L"
  TARGET="$save"
  LASTMSG="attendu rc 5 en --hook et en CLI, stdout vide, stderr « vf-portable.sh introuvable » ; obtenu rc $h puis $RC out[$ho] err[$ERR]"
  [ "$h" -eq 5 ] && [ "$RC" -eq 5 ] && [ -z "$ho" ] && printf '%s' "$ERR" | command grep -qF 'vf-portable.sh introuvable'
}

# === Tracer ======================================================================================
L="$(mklab)"; setrole "$L" 'product\n'
runr "$L" - --path "$L" --hook
{ [ "$RC" -eq 0 ] && out_is 'Poste : product' && err_empty; } \
  && ok "CR-TRACE-1 fichier product en --hook => « Poste : product » exact, stderr vide" \
  || ko "CR-TRACE-1 attendu « Poste : product » rc 0 stderr vide, obtenu rc $RC out[$OUT] err[$ERR]"
runr "$L" - --path "$L"
{ [ "$RC" -eq 3 ] && out_empty; } && ok "CR-TRACE-1b sans --hook : rc 3, stdout vide" \
  || ko "CR-TRACE-1b attendu rc 3 stdout vide, obtenu rc $RC out[$OUT]"

probe_silence_hook && ok "CR-TRACE-2 sans poste en --hook : rc 0, stdout et stderr à 0 octet" || ko "CR-TRACE-2 $LASTMSG"
probe_silence_cli && ok "CR-TRACE-2b sans poste hors --hook : rc 3, les deux flux vides" || ko "CR-TRACE-2b $LASTMSG"

L="$(mklab)"; setrole "$L" 'solo\n'
runr "$L" - --path "$L" --hook
{ [ "$RC" -eq 0 ] && out_empty; } && ok "CR-TRACE-3 fichier solo en --hook : rien (rc 0)" \
  || ko "CR-TRACE-3 attendu rc 0 stdout vide, obtenu rc $RC out[$OUT]"

# === CR-HOOK-POSE : câblage réel par l'engine ====================================================
LAB="$(mktemp -d "$TMP/pose.XXXXXX")"; git -C "$LAB" init -q >/dev/null 2>&1
POSE_HOME="$(mktemp -d "$TMP/posehome.XXXXXX")"
( cd "$LAB" && env -u VF_ROLE PYTHONUSERBASE="$PYUB" HOME="$POSE_HOME" VF_RUNTIME=claude VF_SCOPE=project \
    VIBEFLOW_CACHE="$REPO/plugin" perl -e 'alarm 240; exec @ARGV' "$BASH_BIN" "$REPO/plugin/_internal/vibeflow-update.sh" install conductor \
    >"$TMP/pose.log" 2>&1 ); PRC=$?
if [ "$PRC" -ne 0 ]; then
  ko "CR-HOOK-POSE attendu install rc 0, obtenu rc $PRC [$(tail -3 "$TMP/pose.log" | tr '\n' ' ')]"
else
  ARGS_LINE="$(python3 - "$LAB" <<'PYEOF'
import json, sys, glob, os
lab = sys.argv[1]
for f in sorted(glob.glob(os.path.join(lab, ".claude", "settings*.json"))):
    d = json.load(open(f))
    for g in d.get("hooks", {}).get("SessionStart", []):
        for h in g.get("hooks", []):
            a = h.get("args", [])
            if len(a) == 2 and a[0].endswith("/check-role-consistency.sh") and a[1] == "--hook":
                print(f + "\t" + a[0])
                sys.exit(0)
print("")
PYEOF
)"
  if [ -z "$ARGS_LINE" ]; then
    ko "CR-HOOK-POSE attendu une entrée SessionStart exec check-role-consistency.sh --hook dans le settings du lab, obtenu aucune"
  else
    SETF="${ARGS_LINE%%$'\t'*}"; HPATH="${ARGS_LINE#*$'\t'}"
    # L'engine pose `${CLAUDE_PROJECT_DIR}/…` : on le développe comme le fait le harness.
    HPATH_EXP="${HPATH//\$\{CLAUDE_PROJECT_DIR\}/$LAB}"
    mkdir -p "$LAB/.claude"; printf 'product\n' > "$LAB/.claude/vibeflow-role"
    GOT="$(cd "$LAB" && env -u VF_ROLE HOME="$POSE_HOME" VF_GUARD_HEALTH_DIR="$HEALTH" CLAUDE_PROJECT_DIR="$LAB" "$BASH_BIN" "$HPATH_EXP" --hook 2>/dev/null)"; GRC=$?
    if [ "$GRC" -eq 0 ] && [ "$GOT" = "Poste : product" ]; then
      ok "CR-HOOK-POSE entrée exec posée dans $(basename "$SETF") et « Poste : product » rendu par le script posé"
    else
      ko "CR-HOOK-POSE attendu « Poste : product » rc 0, obtenu rc $GRC [$GOT] (chemin $HPATH_EXP)"
    fi
  fi
fi

# === Issues 0 / 1 / 3 / 5 ========================================================================
probe_0 && ok "CR-0 poste listé => rc 0, stdout vide" || ko "CR-0 $LASTMSG"
L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" '{"vf_roles":["product","dev"]}'
runr "$L" - --path "$L" --hook
{ [ "$RC" -eq 0 ] && out_is 'Poste : product'; } && ok "CR-0b --hook : « Poste : product », rc 0" \
  || ko "CR-0b attendu « Poste : product » rc 0, obtenu rc $RC [$OUT]"

probe_1a && ok "CR-1a poste hors liste => rc 1 + constat « hors de la liste »" || ko "CR-1a $LASTMSG"
L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" '{"vf_roles":["dev"]}'
runr "$L" - --path "$L" --hook
{ [ "$RC" -eq 1 ] && out_is 'Poste : product' && [ -n "$ERR" ]; } \
  && ok "CR-1a' --hook : ligne de poste sur stdout, constat sur stderr, rc 1 non traduit" \
  || ko "CR-1a' attendu rc 1 stdout « Poste : product » stderr non vide, obtenu rc $RC out[$OUT] err[$ERR]"

L="$(mklab)"; setrole "$L" "$MARK\n"; setcfg "$L" '{"vf_roles":["product","dev"]}'
runr "$L" - --path "$L" --hook
{ [ "$RC" -eq 1 ] && out_empty && no_mark; } && ok "CR-1b valeur inconnue => rc 1, stdout vide, valeur jamais réimprimée" \
  || ko "CR-1b attendu rc 1 stdout vide sans marqueur, obtenu rc $RC out[$OUT] err[$ERR]"

L="$(mklab)"; setrole "$L" 'solo\n'; setcfg "$L" '{"vf_roles":["product","dev"]}'
runr "$L" - --path "$L"
R1="$RC"
runr "$L" - --path "$L" --hook
{ [ "$R1" -eq 1 ] && [ "$RC" -eq 1 ] && out_empty; } && ok "CR-1c solo hors liste => rc 1 (CLI et --hook), stdout vide" \
  || ko "CR-1c attendu rc 1 deux fois stdout vide, obtenu rc $R1 puis $RC out[$OUT]"

L="$(mklab)"; setcfg "$L" '{"vf_roles":["dev"]}'
runr "$L" - --path "$L" --role product; A="$RC"
runr "$L" - --path "$L" --role dev; B="$RC"
runr "$L" - --path "$L" --role qa; C="$RC"
{ [ "$A" -eq 1 ] && [ "$B" -eq 0 ] && [ "$C" -eq 1 ]; } && ok "CR-1d --role juge un candidat : product 1, dev 0, qa 1" \
  || ko "CR-1d attendu 1/0/1, obtenu $A/$B/$C"
runr "$L" - --path "$L" --role=dev
[ "$RC" -eq 0 ] && ok "CR-1e --role=dev (forme égale) => rc 0" || ko "CR-1e attendu rc 0, obtenu rc $RC"

L="$(mklab)"; setrole "$L" 'product\n'
runr "$L" - --path "$L"; A="$RC"
L2="$(mklab)"; setrole "$L2" 'product\n'; setcfg "$L2" '{"autre":1}'
runr "$L2" - --path "$L2"; B="$RC"
L3="$(mklab)"; setrole "$L3" 'product\n'; rm -rf "$L3/.planning"
runr "$L3" - --path "$L3"; C="$RC"
L4="$(mklab)"; setcfg "$L4" '{"vf_roles":["product"]}'
runr "$L4" - --path "$L4"; D4="$RC"
{ [ "$A" -eq 3 ] && [ "$B" -eq 3 ] && [ "$C" -eq 3 ] && out_empty && err_empty && [ "$D4" -eq 3 ]; } \
  && ok "CR-3a..d silence : pas de config (3), pas de clé (3), pas de .planning (3), aucune source (3, flux vides)" \
  || ko "CR-3 attendu 3/3/3/3, obtenu $A/$B/$C/$D4"

probe_5a && ok "CR-5a config.json non JSON => rc 5, stderr non vide" || ko "CR-5a $LASTMSG"
probe_5a_hook && ok "CR-5a' --hook : rc 5 jamais traduit, stdout vide" || ko "CR-5a' $LASTMSG"

bad=""
for J in '{"vf_roles":"product"}' '{"vf_roles":[]}' '{"vf_roles":["qa"]}' '{"vf_roles":["product", 3]}'; do
  L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" "$J"
  runr "$L" - --path "$L"
  [ "$RC" -eq 5 ] || bad="$bad [$J => rc $RC]"
done
[ -z "$bad" ] && ok "CR-5b vf_roles hors contrat (chaîne, vide, valeur inconnue, élément non chaîne) => rc 5" \
  || ko "CR-5b attendu rc 5 partout, obtenu$bad"

probe_5c && ok "CR-5c fichier en lien symbolique => rc 5, motif du lecteur sur stderr, marqueur absent" || ko "CR-5c $LASTMSG"
probe_5d && ok "CR-5d fichier sur deux lignes => rc 5, stdout vide, motif du lecteur sur stderr, marqueur absent" || ko "CR-5d $LASTMSG"
probe_pendant && ok "CR-5f lien pendant => rc 5 bruyant (jamais le silence de l'état 0)" || ko "CR-5f $LASTMSG"
probe_outillage && ok "CR-OUTIL vf-portable.sh absent => rc 5 (CLI et --hook), jamais le verdict 1, stdout vide" || ko "CR-OUTIL $LASTMSG"

L="$(mklab)"; setcfg "$L" '{"vf_roles":["product","dev"]}'; head -c 5000 /dev/zero | tr '\0' 'a' > "$L/.claude/vibeflow-role"
runr "$L" - --path "$L"
[ "$RC" -eq 5 ] && ok "CR-5e fichier de 5000 octets => rc 5" || ko "CR-5e attendu rc 5, obtenu rc $RC"

probe_bom && ok "CR-BOM BOM + CRLF => « Poste : product » exact (valeur validée, jamais les octets bruts)" || ko "CR-BOM $LASTMSG"

L="$(mklab)"; setcfg "$L" '{"vf_roles":["dev"]}'
runr "$L" VF_ROLE=dev --path "$L"; A="$RC"
runr "$L" VF_ROLE=dev --path "$L" --hook
{ [ "$A" -eq 0 ] && [ "$RC" -eq 0 ] && out_is 'Poste : dev'; } && ok "CR-ENV VF_ROLE=dev sans fichier : rc 0, --hook « Poste : dev »" \
  || ko "CR-ENV attendu rc 0 et « Poste : dev », obtenu rc $A puis $RC [$OUT]"

FA="$(mklab)"; setrole "$FA" 'product\n'; setcfg "$FA" '{"vf_roles":["product"]}'
FB="$(mklab)"; setrole "$FB" 'product\n'; setcfg "$FB" '{"vf_roles":["dev"]}'
ELSEWHERE="$(mktemp -d "$TMP/ailleurs.XXXXXX")"
runr "$ELSEWHERE" "CLAUDE_PROJECT_DIR=$FA" ; A="$RC"
runr "$ELSEWHERE" "CLAUDE_PROJECT_DIR=$FA" --path "$FB"; B="$RC"
{ [ "$A" -eq 0 ] && [ "$B" -eq 1 ]; } && ok "CR-RACINE CLAUDE_PROJECT_DIR est lu sans --path ; --path l'emporte" \
  || ko "CR-RACINE attendu 0 puis 1, obtenu $A puis $B"

L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" '{"vf_roles":["dev"]}'
mkdir -p "$L/.planning/workstreams/x"; printf '%s' '{"vf_roles":["product"]}' > "$L/.planning/workstreams/x/config.json"
runr "$L" - --path "$L"
[ "$RC" -eq 1 ] && ok "CR-PART lab partitionné : seule la racine est lue (rc 1)" || ko "CR-PART attendu rc 1, obtenu rc $RC"

# === Usage, aide ================================================================================
L="$(mklab)"
runr "$L" - --path "$L" --zz; A="$RC"
runr "$L" - --path; B="$RC"
runr "$L" - --role; C="$RC"
{ [ "$A" -eq 64 ] && [ "$B" -eq 64 ] && [ "$C" -eq 64 ]; } && ok "CR-64 argument inconnu, --path sans valeur, --role sans valeur => rc 64" \
  || ko "CR-64 attendu 64/64/64, obtenu $A/$B/$C"
runr "$L" - --help
miss=""
for n in 0 1 3 5 17 64; do
  command grep -Eq "^[[:space:]]*$n[[:space:]]+= " "$TMP/out" || miss="$miss $n"
done
{ [ "$RC" -eq 0 ] && [ -z "$miss" ]; } && ok "CR-HELP --help énumère les codes 0, 1, 3, 5, 17, 64" || ko "CR-HELP codes absents de l'aide :$miss (rc $RC)"
n2="$(awk '!/^[[:space:]]*#/ && /exit 2|hook_exit 2/{n++} END{print n+0}' "$REAL")"
[ "$n2" = "0" ] && ok "CR-NO2 le code 2 n'est jamais émis" || ko "CR-NO2 attendu 0 occurrence, obtenu $n2"

# === CR-17 ======================================================================================
NOPY="$TMP/nopy"; mkdir -p "$NOPY"
for t in bash dirname cat wc tr mkdir date mv rm uname sed awk grep head od; do
  p="$(command -v "$t" 2>/dev/null || true)"; [ -n "$p" ] && ln -s "$p" "$NOPY/$t"
done
L="$(mklab)"; setrole "$L" 'product\n'; setcfg "$L" '{"vf_roles":["product"]}'
if PATH="$NOPY" command -v python3 >/dev/null 2>&1 || PATH="$NOPY" command -v python >/dev/null 2>&1 || PATH="$NOPY" command -v py >/dev/null 2>&1; then
  skip "CR-17 PATH réduit non constructible (un interpréteur reste joignable)"
else
  runr "$L" "PATH=$NOPY" --path "$L"
  if [ "$RC" -eq 17 ]; then ok "CR-17 sans interpréteur Python => rc 17 (fail-open bruyant)"; else ko "CR-17 attendu rc 17, obtenu rc $RC err[$ERR]"; fi
fi

# === Config.json non fiable : isolement de l'interpréteur et lecture bornée (audit H-1, M-1) =====
probe_hostile && ok "CR-HOSTILE json.py à la racine du dépôt jamais importé (aucun témoin écrit, rc 0)" || ko "CR-HOSTILE — $LASTMSG"
probe_cfg_lien && ok "CR-CFG-LIEN config.json lien symbolique (valide ou pendant) => rc 5, non lu" || ko "CR-CFG-LIEN — $LASTMSG"
probe_cfg_fifo && ok "CR-CFG-FIFO config.json FIFO => rc 5 sans blocage" || ko "CR-CFG-FIFO — $LASTMSG"
probe_cfg_gros && ok "CR-CFG-GROS config.json 65537 octets => rc 5 ; CR-CFG-BORNE 65536 octets => rc 0" || ko "CR-CFG-GROS — $LASTMSG"
probe_hook_timeout && ok "CR-HOOK-TIMEOUT l'entrée SessionStart du gate porte un timeout court" || ko "CR-HOOK-TIMEOUT — $LASTMSG"

# === Lecture seule, couverture des codes ========================================================
[ ! -s "$TMP/ro-bad" ] && ok "CR-RO empreinte de chaque fixture identique avant/après (cmp -s)" \
  || ko "CR-RO fixture modifiée : $(sort -u "$TMP/ro-bad" | tr '\n' ' ')"
sort -un "$TMP/rcs" | tr '\n' ' ' | tr -s ' ' '\n' | command grep -v '^$' > "$TMP/obs"
printf '0\n1\n3\n5\n64\n' | sort > "$TMP/exp-codes"; sort "$TMP/obs" > "$TMP/obs-s"
MANQ="$(comm -13 "$TMP/obs-s" "$TMP/exp-codes" | tr '\n' ' ')"; EXTRA="$(comm -23 "$TMP/obs-s" "$TMP/exp-codes" | tr '\n' ' ')"
# 17 est admis s'il a été observé par CR-17
EXTRA="${EXTRA//17 /}"
{ [ -z "$MANQ" ] && [ -z "$EXTRA" ]; } && ok "CR-CODES codes observés = {0, 1, 3, 5, 64} (+17 si mesuré)" \
  || ko "CR-CODES manquants [$MANQ] en trop [$EXTRA]"

# === Mutants =====================================================================================
MUTDIR="$TMP/mut"; mkdir -p "$MUTDIR"
cp "$READER" "$MUTDIR/vf-role.sh"; cp "$PORTABLE" "$MUTDIR/vf-portable.sh"
MUTBIN="$MUTDIR/check-role-consistency.sh"

# mutant <id> <awk-programme> <probe> <description>
mutant() {
  local id="$1" prog="$2" probe="$3" desc="$4"
  awk "$prog" "$REAL" > "$MUTBIN"
  if cmp -s "$MUTBIN" "$REAL"; then ko "$id mutant NON OPPOSABLE (copie identique à l'original) — $desc"; return; fi
  if ! bash -n "$MUTBIN" 2>/dev/null; then ko "$id mutant invalide (bash -n) — $desc"; return; fi
  TARGET="$MUTBIN"; "$probe"; local mrc=$?; local mmsg="$LASTMSG"
  TARGET="$REAL"; "$probe"; local orc=$?
  if [ "$mrc" -ne 0 ] && [ "$orc" -eq 0 ]; then
    ok "$id tué ($desc) — sur le mutant : $mmsg"
  elif [ "$mrc" -eq 0 ]; then
    ko "$id mutant SURVIVANT ($desc) — le cas ${probe#probe_} reste vert sur le mutant"
  else
    ko "$id original rouge après mutation ($desc) — $LASTMSG"
  fi
  TARGET="$REAL"
}

mutant MUT-liste-hors '{ if (prev ~ /hors de la liste du projet/ && $0 ~ /verdict_exit 1 ;;/) sub(/verdict_exit 1/, "verdict_exit 0"); prev=$0; print }' \
  probe_1a "branche « hors liste » rendue 0"
mutant MUT-silence '{ if (!done && $0 == "  hook_exit 3") { print "  exit 0"; done=1 } else print }' \
  probe_silence_cli "absence de source rendue 0"
mutant MUT-analyse '{ if (prev ~ /vf_roles hors contrat/ && $0 ~ /hook_exit 5 ;;/) sub(/hook_exit 5/, "hook_exit 3"); prev=$0; print }' \
  probe_5a "erreur d'analyse repliée sur 3"
mutant MUT-hook '{ if (index($0, "[ \"$code\" -eq 3 ]; then exit 0; fi")) sub(/\[ "\$code" -eq 3 \]; then exit 0; fi/, "false; then exit 0; fi"); print }' \
  probe_silence_hook "traduction 3 vers 0 retirée"
mutant MUT-cle '{ if (index($0, "\"vf_roles\"")) gsub(/"vf_roles"/, "\"vf_rolez\""); print }' \
  probe_0 "vf_roles lu sous un autre nom"
mutant MUT-brut '{ if (index($0, "printf '"'"'Poste : %s\\n'"'"' \"$ROLE\"")) sub(/"\$ROLE"/, "\"$(cat \"$ROLE_FILE\")\""); print }' \
  probe_bom "octets bruts du fichier imprimés au lieu de la valeur validée"
mutant MUT-analyse-hook '{ if (index($0, "[ \"$code\" -eq 3 ]; then exit 0; fi")) sub(/\[ "\$code" -eq 3 \]; then/, "{ [ \"$code\" -eq 3 ] || [ \"$code\" -eq 5 ]; }; then"); print }' \
  probe_5a_hook "code 5 traduit en 0 sous --hook"

mutant MUT-pendant '{ if (index($0, "[ ! -L \"$ROLE_FILE\" ]")) sub(/ && \[ ! -L "\$ROLE_FILE" \]/, ""); print }' \
  probe_pendant "garde « ! -L » de l'état 0 retirée (lien pendant pris pour une absence de source)"
mutant MUT-motif-lecteur '{ if (index($0, "bash \"$READER\"")) gsub(/2>&1/, "2>/dev/null"); print }' \
  probe_5c "sortie du lecteur jetée au lieu d'être réaffichée"
mutant MUT-motif-lecteur-d '{ if (index($0, "bash \"$READER\"")) gsub(/2>&1/, "2>/dev/null"); print }' \
  probe_5d "sortie du lecteur jetée au lieu d'être réaffichée (deux lignes)"
mutant MUT-outillage '{ if ($0 == "trap _vf_locator_failed EXIT") print "true"; else print }' \
  probe_outillage "filet d'outillage retiré : le bloc canonique sort 1, confondu avec « hors de la liste »"

# MUT-isole : depuis v2.70.1, vf_python pose -I lui-même (vf-portable.sh) — retirer le seul -I du site ne
# rouvre plus rien. Le mutant contourne donc vf_python : interpréteur résolu appelé en direct, sans -I.
mutant MUT-isole '{ if (index($0, "vf_python -I -c")) sub(/vf_python -I -c/, "$VF_PYTHON_INVOKE -c"); print }' \
  probe_hostile "isolation retirée (vf_python contourné, sans -I) : le json.py du dépôt est importé"
mutant MUT-cfg-lien '{ if (index($0, "if [ -L \"$CFG\" ] || [ ! -f \"$CFG\" ]; then")) sub(/if \[ -L "\$CFG" \] \|\| \[ ! -f "\$CFG" \]; then/, "if false; then"); print }' \
  probe_cfg_lien "refus du lien symbolique retiré"
mutant MUT-cfg-fifo '{ if (index($0, "|| [ ! -f \"$CFG\" ]; then")) sub(/ \|\| \[ ! -f "\$CFG" \]; then/, "; then"); print }' \
  probe_cfg_fifo "refus du fichier non régulier retiré (le FIFO est ouvert)"
mutant MUT-cfg-taille '{ if (index($0, "-gt \"$CFG_MAX\"")) sub(/-gt "\$CFG_MAX"/, "-gt 99999999"); print }' \
  probe_cfg_gros "plafond de taille relevé"
mutant MUT-cfg-borne '{ if (index($0, "-gt \"$CFG_MAX\"")) sub(/-gt "\$CFG_MAX"/, "-ge \"$CFG_MAX\""); print }' \
  probe_cfg_gros "borne exclusive devenue inclusive (65536 refusé)"

# MUT-hook-timeout : le fichier hooks.json sans le champ timeout doit rougir la sonde.
jq 'del(.hooks.SessionStart[].hooks[] | select((.args // []) | map(test("check-role-consistency\\.sh")) | any) | .timeout)' "$HOOKS_JSON" > "$MUTDIR/hooks.sans-timeout.json" 2>/dev/null
if cmp -s "$MUTDIR/hooks.sans-timeout.json" "$HOOKS_JSON"; then ko "MUT-hook-timeout mutant NON OPPOSABLE"
elif probe_hook_timeout "$MUTDIR/hooks.sans-timeout.json"; then ko "MUT-hook-timeout mutant SURVIVANT"
else ok "MUT-hook-timeout tué (timeout retiré de l'entrée) — sur le mutant : $LASTMSG"; fi

echo "== Résultat : $PASS ok, $FAIL ko, $SKIPPED skip =="
[ "$FAIL" -eq 0 ]
