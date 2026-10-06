#!/usr/bin/env bash
# test-check-mission-exit.sh — Suite de vérification de check-mission-exit.sh (HEAD-02, QUAL-01).
#
# Un cas par comportement du contrat (cf. en-tête du script testé), plus les six mutations de
# fixture (une par contrôle E1-E6) et deux mutations structurelles (D-11, cascade E1). Cas 28-43 :
# contrôle E7 (SOBR-07, plan 41.3-04, delta depuis le snapshot de début de mission), huit mutants de script
# tués (rc attendu/obtenu). Cas 44-49 (POCK-06, plan 41.4-06) : E3 lit le merge-danger call du corps de PR
# (SAIN 1/44, MANQUE 45-47/49, INDÉTERMINÉ 48, corps hostile 48b) ; mutants E3a/E3b tués. Fixtures
# isolées via mktemp -d + git init + dépôt nu, jamais sur le repo réel. Chaque cas capture la
# sortie ET le code de retour dans deux variables distinctes, assertées séparément.
# Cas 23-27 (issue #82) : E1 lit aussi `children_running` du registre des agents dispatchés
# (verrou relâché mais enfant consigné running = manque ; champ absent = kernel antérieur, sain).
#
# HOME et CLAUDE_PLUGIN_ROOT sont SCRUBBÉS pour chaque invocation (run_gate) : sur ce poste,
# $HOME/.claude/scripts porte un dag.sh réel — sans ce scrub, la cascade de résolution des
# scripts frères (candidats 2..4) résoudrait silencieusement vers l'installation réelle de la
# machine au lieu de rester confinée à la fixture jetable, faussant les cas 21/22.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-mission-exit.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

EMPTY_HOME="$TMP/empty-home"
mkdir -p "$EMPTY_HOME"

run_gate() { # <args...> — invoque le gate, environnement confiné (voir en-tête)
  ( HOME="$EMPTY_HOME"; export HOME; unset CLAUDE_PLUGIN_ROOT 2>/dev/null; bash "$SCRIPT" "$@" )
}

# --- Talon `gh` OUVERT : auth OK, PR ouverte -------------------------------------------------------
GH_OK_BIN="$TMP/bin-gh-ok"
mkdir -p "$GH_OK_BIN"
cat > "$GH_OK_BIN/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "auth" ] && [ "$2" = "status" ]; then exit 0; fi
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then echo '{"state":"OPEN","body":"## Merge-danger call\nPorte : double sens\nRayon d'\''explosion : doctrine seule, aucune donnée écrite"}'; exit 0; fi
exit 1
EOF
chmod +x "$GH_OK_BIN/gh"

# --- Talon `gh` NON AUTHENTIFIÉ ---------------------------------------------------------------------
GH_NOAUTH_BIN="$TMP/bin-gh-noauth"
mkdir -p "$GH_NOAUTH_BIN"
cat > "$GH_NOAUTH_BIN/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "auth" ] && [ "$2" = "status" ]; then
  echo "error: not logged in. run gh auth login" >&2
  exit 1
fi
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then echo '{"state":"OPEN","body":"## Merge-danger call\nPorte : double sens\nRayon d'\''explosion : doctrine seule, aucune donnée écrite"}'; exit 0; fi
exit 1
EOF
chmod +x "$GH_NOAUTH_BIN/gh"

# --- Talons `gh` à corps de PR (POCK-06, E3) : même forme que GH_OK_BIN, le JSON rendu par `pr view` est ----
# --- écrit tel quel dans pr.json (apostrophe du rayon d'explosion : quotée '\'' côté shell). --------------
mk_gh_pr() { # <nom> <JSON brut rendu par `gh pr view`> -> imprime le dossier du talon
  local d="$TMP/bin-gh-$1"; mkdir -p "$d"
  printf '%s\n' "$2" > "$d/pr.json"
  cat > "$d/gh" <<'GHEOF'
#!/usr/bin/env bash
if [ "$1" = "auth" ] && [ "$2" = "status" ]; then exit 0; fi
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then cat "$(dirname "$0")/pr.json"; exit 0; fi
exit 1
GHEOF
  chmod +x "$d/gh"; printf '%s' "$d"
}
GH_CRLF_BIN="$(mk_gh_pr crlf '{"state":"OPEN","body":"## Merge-danger call\r\nPorte : double sens\r\nRayon d'\''explosion : doctrine seule, aucune donnée écrite\r\n"}')"
GH_NOSECTION_BIN="$(mk_gh_pr nosection '{"state":"OPEN","body":"## Résumé\nUne mission sans appel de merge.\n"}')"
GH_BADPORTE_BIN="$(mk_gh_pr badporte '{"state":"OPEN","body":"## Merge-danger call\nPorte : peut-être\nRayon d'\''explosion : doctrine seule, aucune donnée écrite"}')"
GH_SHORTRAYON_BIN="$(mk_gh_pr shortrayon '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion : tout"}')"
GH_NOBODY_BIN="$(mk_gh_pr nobody '{"state":"OPEN"}')"
GH_EMPTYBODY_BIN="$(mk_gh_pr emptybody '{"state":"OPEN","body":""}')"

# --- Talons de verrou de driver (dag.sh sentinelle + driver-lock.sh) --------------------------------
write_lock_stub_absent() { # <dir>
  mkdir -p "$1"
  : > "$1/dag.sh"; chmod +x "$1/dag.sh"
  cat > "$1/driver-lock.sh" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  status) echo '{"present": false, "lock": ".planning/DRIVER.lock"}'; exit 0 ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "$1/driver-lock.sh"
}

write_lock_stub_present() { # <dir>
  mkdir -p "$1"
  : > "$1/dag.sh"; chmod +x "$1/dag.sh"
  cat > "$1/driver-lock.sh" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  status) echo '{"present": true, "owner": "mission-x", "step": "exec-gate", "age_seconds": 12}'; exit 0 ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "$1/driver-lock.sh"
}

# --- Talon de verrou ABSENT mais registre d'agents renseigné (issue #82, cas 23-26) -------------------
write_lock_stub_children() { # <dir> <present:true|false> <children_running (brut, injecté tel quel)>
  mkdir -p "$1"
  : > "$1/dag.sh"; chmod +x "$1/dag.sh"
  if [ "$2" = "true" ]; then
    printf '#!/usr/bin/env bash\ncase "$1" in\n  status) echo %s; exit 0 ;;\n  *) exit 1 ;;\nesac\n' \
      "'{\"present\": true, \"owner\": \"mission-x\", \"step\": \"exec-gate\", \"age_seconds\": 12, \"children_running\": $3}'" > "$1/driver-lock.sh"
  else
    printf '#!/usr/bin/env bash\ncase "$1" in\n  status) echo %s; exit 0 ;;\n  *) exit 1 ;;\nesac\n' \
      "'{\"present\": false, \"lock\": \".planning/DRIVER.lock\", \"children_running\": $3}'" > "$1/driver-lock.sh"
  fi
  chmod +x "$1/driver-lock.sh"
}

# --- Fabrique de la fixture SAINE, réutilisée par tous les cas --------------------------------------
mk_sane_fixture() { # <name> -> imprime le chemin du dépôt
  local d="$TMP/$1" remote="$TMP/$1-remote.git"
  mkdir -p "$d"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t config user.email t@t >/dev/null 2>&1

  printf '.claude/\n.planning/DRIVER.lock\n' > "$d/.gitignore"
  write_lock_stub_absent "$d/.claude/scripts"

  mkdir -p "$d/.planning/missions"
  {
    printf '### Phase 40: fixture — head of minds\n\n'
    printf 'Plans:\n'
    printf -- '- [x] 40-01-PLAN.md — plan coché\n\n'
    printf '### Phase 41: phase suivante (borne la section précédente)\n\n'
    printf 'Rien à voir ici.\n'
  } > "$d/.planning/ROADMAP.md"

  {
    printf -- '---\n'
    printf 'stopped_at: "fixture SAINE — rien à signaler"\n'
    printf -- '---\n\n# State\n'
  } > "$d/.planning/STATE.md"

  {
    printf '# Rapport de mission (fixture)\n\n## Preuves E6\n\n'
    printf '```json\n'
    printf '{"preuves": [\n'
    printf '  {"verdict": "revue", "commande": "bash test.sh", "exit_code": 0, "sha": "abc123"},\n'
    printf '  {"verdict": "audit", "preuve": "amont"}\n'
    printf ']}\n'
    printf '```\n'
  } > "$d/.planning/missions/report.md"

  git -C "$d" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m fixture >/dev/null 2>&1

  git -C "$d" -c user.email=t@t -c user.name=t branch -M main >/dev/null 2>&1
  git init -q --bare "$remote" >/dev/null 2>&1
  git -C "$d" remote add origin "$remote" >/dev/null 2>&1
  git -C "$d" push -q origin main >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t checkout -q -b feature/mission >/dev/null 2>&1
  git -C "$d" push -q -u origin feature/mission >/dev/null 2>&1
  git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main >/dev/null 2>&1

  # Snapshot de DÉBUT de mission (E7 juge le delta depuis lui) : posé par le geste que le manager fait après l'acquire.
  run_gate --root "$d" --budget-snapshot >/dev/null 2>&1

  printf '%s' "$d"
}

REPORT_REL=".planning/missions/report.md"
STEP="40"

echo "== test-check-mission-exit =="

# === Cas 1 — SAIN : code 3, stdout vide ==============================================================
D="$(mk_sane_fixture c1)"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "1 SAIN — code 3, stdout vide"; else ko "1 SAIN — code 3, stdout vide" "rc=$rc out=[$out]"; fi

SANE_RC=3

# === Cas 2 — mutation E1 : verrou présent =============================================================
D="$(mk_sane_fixture c2)"
write_lock_stub_present "$D/.claude/scripts"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1)"; rc=$?
named=0; case "$out" in *"E1"*) named=1 ;; esac
if [ "$rc" -eq "$SANE_RC" ]; then ko "2 mutation E1 (verrou présent) — mutant NON OPPOSABLE" "rc=$rc identique au sain"
elif [ "$rc" -eq 0 ] && [ "$named" -eq 1 ]; then ok "2 mutation E1 (verrou présent) — code 0, sortie nomme E1"
else ko "2 mutation E1 (verrou présent) — code 0, sortie nomme E1" "rc=$rc out=[$out]"; fi

# === Cas 3 — mutation E2 : fichier non suivi et non exclu ==============================================
D="$(mk_sane_fixture c3)"
echo "bruit" > "$D/untracked-e2.txt"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1)"; rc=$?
named=0; case "$out" in *"E2"*) named=1 ;; esac
if [ "$rc" -eq "$SANE_RC" ]; then ko "3 mutation E2 (arbre sale) — mutant NON OPPOSABLE" "rc=$rc identique au sain"
elif [ "$rc" -eq 0 ] && [ "$named" -eq 1 ]; then ok "3 mutation E2 (arbre sale) — code 0, sortie nomme E2"
else ko "3 mutation E2 (arbre sale) — code 0, sortie nomme E2" "rc=$rc out=[$out]"; fi

# === Cas 4 — mutation E3 : retour sur la branche par défaut ============================================
D="$(mk_sane_fixture c4)"
git -C "$D" checkout -q main >/dev/null 2>&1
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1)"; rc=$?
named=0; case "$out" in *"E3"*) named=1 ;; esac
if [ "$rc" -eq "$SANE_RC" ]; then ko "4 mutation E3 (branche par défaut) — mutant NON OPPOSABLE" "rc=$rc identique au sain"
elif [ "$rc" -eq 0 ] && [ "$named" -eq 1 ]; then ok "4 mutation E3 (branche par défaut) — code 0, sortie nomme E3"
else ko "4 mutation E3 (branche par défaut) — code 0, sortie nomme E3" "rc=$rc out=[$out]"; fi

# === Cas 5 — mutation E4 : case de plan décochée, committée ============================================
D="$(mk_sane_fixture c5)"
sed -i.bak 's/- \[x\] 40-01-PLAN.md/- [ ] 40-01-PLAN.md/' "$D/.planning/ROADMAP.md"
rm -f "$D/.planning/ROADMAP.md.bak"
git -C "$D" -c user.email=t@t -c user.name=t commit -q -am "decoche" >/dev/null 2>&1
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1)"; rc=$?
named=0; case "$out" in *"E4"*) named=1 ;; esac
if [ "$rc" -eq "$SANE_RC" ]; then ko "5 mutation E4 (case décochée) — mutant NON OPPOSABLE" "rc=$rc identique au sain"
elif [ "$rc" -eq 0 ] && [ "$named" -eq 1 ]; then ok "5 mutation E4 (case décochée) — code 0, sortie nomme E4"
else ko "5 mutation E4 (case décochée) — code 0, sortie nomme E4" "rc=$rc out=[$out]"; fi

# === Cas 6 — mutation E5 : chemin de rapport inexistant (arbre non touché) =============================
D="$(mk_sane_fixture c6)"
before="$(find "$D" | LC_ALL=C sort)"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report ".planning/missions/absent.md" --step "$STEP" 2>&1)"; rc=$?
after="$(find "$D" | LC_ALL=C sort)"
named=0; case "$out" in *"E5"*) named=1 ;; esac
clean=0; [ "$before" = "$after" ] && clean=1
if [ "$rc" -eq "$SANE_RC" ]; then ko "6 mutation E5 (rapport inexistant) — mutant NON OPPOSABLE" "rc=$rc identique au sain"
elif [ "$named" -eq 1 ] && [ "$clean" -eq 1 ]; then ok "6 mutation E5 (rapport inexistant) — code $rc, sortie nomme E5, arbre non touché"
else ko "6 mutation E5 (rapport inexistant) — code $rc, sortie nomme E5, arbre non touché" "rc=$rc named=$named clean=$clean out=[$out]"; fi

# === Cas 7 — mutation E6 : SHA d'une entrée retiré, committé ============================================
D="$(mk_sane_fixture c7)"
python3 - "$D/.planning/missions/report.md" <<'PYEOF' 2>/dev/null || \
sed -i.bak 's/"sha": "abc123"//' "$D/.planning/missions/report.md"
import sys, re
p = sys.argv[1]
s = open(p).read()
s = s.replace('"sha": "abc123"', '"sha": ""')
open(p, "w").write(s)
PYEOF
rm -f "$D/.planning/missions/report.md.bak"
git -C "$D" -c user.email=t@t -c user.name=t commit -q -am "sha retiré" >/dev/null 2>&1
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1)"; rc=$?
named=0; case "$out" in *"E6"*) named=1 ;; esac
if [ "$rc" -eq "$SANE_RC" ]; then ko "7 mutation E6 (SHA retiré) — mutant NON OPPOSABLE" "rc=$rc identique au sain"
elif [ "$rc" -eq 0 ] && [ "$named" -eq 1 ]; then ok "7 mutation E6 (SHA retiré) — code 0, sortie nomme E6"
else ko "7 mutation E6 (SHA retiré) — code 0, sortie nomme E6" "rc=$rc out=[$out]"; fi

# === Cas 8 — INDÉTERMINÉ (a) : aucune étape déclarée ===================================================
D="$(mk_sane_fixture c8)"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" 2>/dev/null)"; rc=$?
errfile_out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" 2>&1 1>/dev/null)"
if [ "$rc" -eq 4 ] && [ -z "$out" ] && [ -n "$errfile_out" ]; then ok "8 INDÉTERMINÉ (a) aucune étape déclarée — code 4, stdout vide, stderr non vide"
else ko "8 INDÉTERMINÉ (a) aucune étape déclarée — code 4, stdout vide, stderr non vide" "rc=$rc out=[$out] err=[$errfile_out]"; fi

# === Cas 9 — INDÉTERMINÉ (b) : client GitHub non authentifié ===========================================
D="$(mk_sane_fixture c9)"
out="$(PATH="$GH_NOAUTH_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
err="$(PATH="$GH_NOAUTH_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1 1>/dev/null)"
names_auth=0; case "$err" in *"authentifié"*) names_auth=1 ;; esac
if [ "$rc" -eq 4 ] && [ -z "$out" ] && [ "$names_auth" -eq 1 ]; then ok "9 INDÉTERMINÉ (b) gh non authentifié — code 4, stderr nomme la cause d'authentification"
else ko "9 INDÉTERMINÉ (b) gh non authentifié — code 4, stderr nomme la cause d'authentification" "rc=$rc out=[$out] err=[$err]"; fi

# === Cas 10 — E6 tableau de preuves VIDE, indéterminé ===================================================
D="$(mk_sane_fixture c10)"
{
  printf '# Rapport de mission (fixture)\n\n## Preuves E6\n\n'
  printf '```json\n{"preuves": []}\n```\n'
} > "$D/.planning/missions/report.md"
git -C "$D" -c user.email=t@t -c user.name=t commit -q -am "preuves vides" >/dev/null 2>&1
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
err="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1 1>/dev/null)"
names_vide=0; case "$err" in *"E6"*"vide"*|*"E6"*"VIDE"*) names_vide=1 ;; esac
if [ "$rc" -eq 4 ] && [ "$names_vide" -eq 1 ]; then ok "10 E6 tableau de preuves vide — code 4, cause nomme explicitement le vide"
else ko "10 E6 tableau de preuves vide — code 4, cause nomme explicitement le vide" "rc=$rc err=[$err]"; fi

# === Cas 11 — DISCRIMINATION MACHINE : trois codes deux à deux différents ==============================
D_sain="$(mk_sane_fixture c11-sain)"
rc_sain=$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D_sain" --report "$REPORT_REL" --step "$STEP" >/dev/null 2>&1; echo $?)
D_manque="$(mk_sane_fixture c11-manque)"
echo "bruit" > "$D_manque/untracked-e2.txt"
rc_manque=$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D_manque" --report "$REPORT_REL" --step "$STEP" >/dev/null 2>&1; echo $?)
D_indet="$(mk_sane_fixture c11-indet)"
rc_indet=$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D_indet" --report "$REPORT_REL" >/dev/null 2>&1; echo $?)
if [ "$rc_sain" != "$rc_manque" ] && [ "$rc_manque" != "$rc_indet" ] && [ "$rc_sain" != "$rc_indet" ]; then
  ok "11 discrimination machine — sain=$rc_sain manque=$rc_manque indet=$rc_indet deux à deux différents"
else
  ko "11 discrimination machine — sain=$rc_sain manque=$rc_manque indet=$rc_indet deux à deux différents" "au moins une paire identique"
fi

# === Cas 12 — argument inconnu → 64 =====================================================================
run_gate --nope >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "12 argument inconnu → 64"; else ko "12 argument inconnu → 64" "rc=$rc"; fi

# === Cas 13 — --root sans valeur → 64 ====================================================================
run_gate --root >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "13 --root sans valeur → 64"; else ko "13 --root sans valeur → 64" "rc=$rc"; fi

# === Cas 14 — --report sans valeur → 64 ==================================================================
run_gate --report >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "14 --report sans valeur → 64"; else ko "14 --report sans valeur → 64" "rc=$rc"; fi

# === Cas 15 — --step sans valeur → 64 ====================================================================
run_gate --step >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "15 --step sans valeur → 64"; else ko "15 --step sans valeur → 64" "rc=$rc"; fi

# === Cas 16 — --hook + --quiet ensemble → 64 =============================================================
run_gate --hook --quiet >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "16 --hook + --quiet ensemble → 64"; else ko "16 --hook + --quiet ensemble → 64" "rc=$rc"; fi

# === Cas 17 — --help → 0, sortie non vide ================================================================
out="$(run_gate --help 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$out" ]; then ok "17 --help → 0, sortie non vide"; else ko "17 --help → 0, sortie non vide" "rc=$rc out=[$out]"; fi

# === Cas 18 — LECTURE SEULE (D-10) : empreinte identique avant/après, .git compris ======================
D="$(mk_sane_fixture c18)"
before="$(find "$D" | LC_ALL=C sort)"
PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" >/dev/null 2>&1
after="$(find "$D" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "18 lecture seule (D-10) — empreinte find identique, .git compris"
else ko "18 lecture seule (D-10) — empreinte find identique, .git compris" "before≠after"; fi

# === Cas 19 — garde D-11 sur le script lui-même, prouvée par mutation ====================================
detect_d11() { # <fichier> -> 0 si violation détectée, 1 sinon
  local n
  n="$(/usr/bin/grep -cE 'driver-lock\.sh[^|]*(release|takeover|reclaim)' "$1")"
  [ "$n" != "0" ]
}
if detect_d11 "$SCRIPT"; then
  ko "19 garde D-11 (original) — ne doit PAS être détecté" "l'original contient une sous-commande mutante"
else
  ok "19a garde D-11 (original) — non détecté, conforme"
fi
D11_COPY="$TMP/copy-d11.sh"
cp "$SCRIPT" "$D11_COPY"
printf '\n"$S"/driver-lock.sh release --owner=x\n' >> "$D11_COPY"
if detect_d11 "$D11_COPY"; then
  ok "19b garde D-11 (copie mutée) — détectée par la même détection"
else
  ko "19b garde D-11 (copie mutée) — détectée par la même détection" "la mutation n'a pas été détectée : garde verte à vide"
fi

# === Cas 20 — analyse syntaxique =========================================================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "20 bash -n passe sur check-mission-exit.sh"; else ko "20 bash -n passe sur check-mission-exit.sh" "syntax error"; fi

# === Cas 21 — E1 cause (a) : cascade non résolue (dag.sh absent) ========================================
D="$(mk_sane_fixture c21)"
rm -f "$D/.claude/scripts/dag.sh"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
err="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1 1>/dev/null)"
names_a=0; case "$err" in *"cascade non résolue"*) names_a=1 ;; esac
names_b=0; case "$err" in *'$S résolu, driver-lock.sh absent'*) names_b=1 ;; esac
if [ "$rc" -eq 4 ] && [ "$names_a" -eq 1 ] && [ "$names_b" -eq 0 ]; then
  ok "21 E1 cause (a) cascade non résolue — code 4, texte dédié, PAS le texte de la cause (b)"
else
  ko "21 E1 cause (a) cascade non résolue — code 4, texte dédié, PAS le texte de la cause (b)" "rc=$rc names_a=$names_a names_b=$names_b err=[$err]"
fi

# === Cas 22 — E1 cause (b) : $S résolu, driver-lock.sh absent ===========================================
D="$(mk_sane_fixture c22)"
rm -f "$D/.claude/scripts/driver-lock.sh"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
err="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1 1>/dev/null)"
names_a=0; case "$err" in *"cascade non résolue"*) names_a=1 ;; esac
names_b=0; case "$err" in *'$S résolu, driver-lock.sh absent'*) names_b=1 ;; esac
if [ "$rc" -eq 4 ] && [ "$names_b" -eq 1 ] && [ "$names_a" -eq 0 ]; then
  ok "22 E1 cause (b) \$S résolu, driver-lock.sh absent — code 4, texte dédié, PAS le texte de la cause (a)"
else
  ko "22 E1 cause (b) \$S résolu, driver-lock.sh absent — code 4, texte dédié, PAS le texte de la cause (a)" "rc=$rc names_a=$names_a names_b=$names_b err=[$err]"
fi

# === Cas 23 : registre d'agents (issue #82), verrou relâché mais 2 enfants consignés running ==========
D="$(mk_sane_fixture c23)"
write_lock_stub_children "$D/.claude/scripts" false 2
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
named=0; case "$out" in *"[E1] verrou relâché mais 2 agent(s) consigné(s) encore running"*) named=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$named" -eq 1 ]; then ok "23 E1 registre : verrou relâché, children_running=2, code 0, manque nommé sur E1"
else ko "23 E1 registre : verrou relâché, children_running=2, code 0, manque nommé sur E1" "rc=$rc out=[$out]"; fi

# === Cas 24 : registre d'agents, verrou relâché et 0 enfant running = SAIN ============================
D="$(mk_sane_fixture c24)"
write_lock_stub_children "$D/.claude/scripts" false 0
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "24 E1 registre : children_running=0, code 3, stdout vide"
else ko "24 E1 registre : children_running=0, code 3, stdout vide" "rc=$rc out=[$out]"; fi

# === Cas 25 : registre d'agents, children_running non numérique = INDÉTERMINÉ =========================
D="$(mk_sane_fixture c25)"
write_lock_stub_children "$D/.claude/scripts" false '"abc"'
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
err="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1 1>/dev/null)"
named=0; case "$err" in *"children_running non numérique"*) named=1 ;; esac
if [ "$rc" -eq 4 ] && [ "$named" -eq 1 ]; then ok "25 E1 registre : children_running non numérique, code 4, diagnostic dédié"
else ko "25 E1 registre : children_running non numérique, code 4, diagnostic dédié" "rc=$rc err=[$err]"; fi

# === Cas 26 : registre d'agents, verrou présent ET enfants running : un seul manque E1, enrichi =======
D="$(mk_sane_fixture c26)"
write_lock_stub_children "$D/.claude/scripts" true 1
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
lines="$(printf '%s\n' "$out" | grep -c '^\[E1\]')"
named=0; case "$out" in *"verrou de driver présent"*"children_running=1"*) named=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$lines" -eq 1 ] && [ "$named" -eq 1 ]; then ok "26 E1 registre : verrou présent + enfant running, une seule ligne E1 portant children_running=1"
else ko "26 E1 registre : verrou présent + enfant running, une seule ligne E1 portant children_running=1" "rc=$rc lines=$lines out=[$out]"; fi

# === Cas 27 : kernel antérieur (status sans children_running) : sous-contrôle non applicable, SAIN ====
D="$(mk_sane_fixture c27)"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
err="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1 1>/dev/null)"
named=0; case "$err" in *"registre des agents non exposé"*) named=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$named" -eq 1 ]; then ok "27 E1 registre : champ absent (kernel antérieur), code 3, non-applicabilité dite sur stderr"
else ko "27 E1 registre : champ absent (kernel antérieur), code 3, non-applicabilité dite sur stderr" "rc=$rc err=[$err]"; fi

# === Cas 44-49 — E3 : le corps de PR porte un merge-danger call conforme (POCK-06, plan 41.4-06) ==========
# Trois issues : SAIN (cas 1, 44), MANQUE nommé (45, 46, 47, 49), INDÉTERMINÉ (48). Le rc de précédence 64 > 4 > 0 > 3 est inchangé (cas 11).
D="$(mk_sane_fixture c44)"
out="$(PATH="$GH_CRLF_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "44 E3 corps conforme en CRLF — code 3, stdout vide (SAIN)"; else ko "44 E3 corps CRLF" "rc=$rc out=[$out]"; fi
# 44a — apostrophe typographique dans « Rayon d’explosion » et espace avant les deux-points absente : conforme (T-41.4-20).
GH_TYPO_BIN="$(mk_gh_pr typo '{"state":"OPEN","body":"Résumé\n\n## Merge-danger call  \nPorte: sens unique\nRayon d’explosion: les lecteurs du gate de sortie\n\n## Suite\nrien\n"}')"
D="$(mk_sane_fixture c44a)"
out="$(PATH="$GH_TYPO_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "44a E3 apostrophe typographique, deux-points collés, blancs de fin de titre — code 3 (SAIN)"; else ko "44a E3 forme tolérée" "rc=$rc out=[$out]"; fi
e3_case() { # <n> <libellé> <talon> <rc attendu> <fragment attendu dans la sortie, ou vide> <fragment interdit>
  local d out rc named=1 leak=0
  d="$(mk_sane_fixture "c$1")"
  out="$(PATH="$3:$PATH" run_gate --root "$d" --report "$REPORT_REL" --step "$STEP" 2>&1)"; rc=$?
  if [ -n "$5" ]; then case "$out" in *"$5"*) named=1 ;; *) named=0 ;; esac; fi
  if [ -n "$6" ]; then case "$out" in *"$6"*) leak=1 ;; esac; fi
  if [ "$rc" -eq 3 ]; then ko "$1 $2 — mutant NON OPPOSABLE" "rc=3 identique au sain"
  elif [ "$rc" -eq "$4" ] && [ "$named" -eq 1 ] && [ "$leak" -eq 0 ]; then ok "$1 $2 — code $4"
  else ko "$1 $2" "rc=$rc attendu $4 nommé=$named fuite=$leak out=[$out]"; fi
}
e3_case 45 "E3 corps sans section — MANQUE nommé" "$GH_NOSECTION_BIN" 0 "[E3] PR ouverte sans merge-danger call conforme" ""
e3_case 45a "E3 corps sans section — le titre manquant est dit" "$GH_NOSECTION_BIN" 0 "Merge-danger call" ""
e3_case 46 "E3 « Porte : peut-être » (hors énumération) — MANQUE nommé" "$GH_BADPORTE_BIN" 0 "[E3] PR ouverte sans merge-danger call conforme" "peut-être"
e3_case 47 "E3 rayon d'explosion de 4 caractères — MANQUE nommé" "$GH_SHORTRAYON_BIN" 0 "rayon d'explosion de moins de 10" ""
e3_case 48 "E3 JSON sans clé body — INDÉTERMINÉ, jamais un vert" "$GH_NOBODY_BIN" 4 "" ""
e3_case 49 "E3 corps vide — MANQUE (lisible, section absente), distinct de 48" "$GH_EMPTYBODY_BIN" 0 "[E3] PR ouverte sans merge-danger call conforme" ""
# 48a — l'indétermination est dite sur stderr, avec sa cause (corps illisible), distincte du manque du cas 49.
D="$(mk_sane_fixture c48a)"
err="$(PATH="$GH_NOBODY_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1 1>/dev/null)"
case "$err" in *"[E3] corps de PR illisible"*) named=1 ;; *) named=0 ;; esac
if [ "$named" -eq 1 ]; then ok "48a E3 corps illisible — cause nommée sur stderr"; else ko "48a E3 corps illisible" "err=[$err]"; fi
# 48b — le corps n'est jamais réémis : un corps hostile (faux titre, substitution, séquence de contrôle) ne fuit pas dans la sortie.
GH_HOSTILE_BIN="$(mk_gh_pr hostile '{"state":"OPEN","body":"## Merge-danger call\nPorte : $(touch '"$TMP"'/e3-pwned-48b) `id`\nRayon d'\''explosion : \u001b[31mHOSTILE-MARKER\n"}')"
D="$(mk_sane_fixture c48b)"
out="$(PATH="$GH_HOSTILE_BIN:$PATH" run_gate --root "$D" --report "$REPORT_REL" --step "$STEP" 2>&1)"; rc=$?
leak=0; case "$out" in *HOSTILE-MARKER*|*"touch"*|*"uid="*) leak=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$leak" -eq 0 ] && [ ! -e "$TMP/e3-pwned-48b" ]; then ok "48b E3 corps hostile — MANQUE, rien du corps réémis, aucune exécution"; else ko "48b E3 corps hostile" "rc=$rc leak=$leak out=[$out]"; fi

# === Cas 50-62 — E3, revue W1 (2026-10-06, M-06/m-07/m-08) : chaque contrainte du merge-danger call a un corps qui la discrimine ===
GH_TWOPORTE_BIN="$(mk_gh_pr twoporte '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique\nPorte : double sens\nRayon d'\''explosion : doctrine seule, aucune donnée écrite"}')"
GH_PORTELATE_BIN="$(mk_gh_pr portelate '{"state":"OPEN","body":"## Merge-danger call\nRayon d'\''explosion : doctrine seule, aucune donnée écrite\n\n## Suite\nPorte : sens unique"}')"
GH_PORTEPARASITE_BIN="$(mk_gh_pr porteparasite '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique, mais pas vraiment\nRayon d'\''explosion : doctrine seule, aucune donnée écrite"}')"
GH_TITRESUFFIXE_BIN="$(mk_gh_pr titresuffixe '{"state":"OPEN","body":"## Merge-danger calls\nPorte : sens unique\nRayon d'\''explosion : doctrine seule, aucune donnée écrite"}')"
GH_TWOSECTIONS_BIN="$(mk_gh_pr twosections '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion : doctrine seule, aucune donnée écrite\n\n## Merge-danger call\nPorte : double sens\nRayon d'\''explosion : doctrine seule, aucune donnée écrite"}')"
GH_BLANCS_BIN="$(mk_gh_pr blancs '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion :            ab"}')"
GH_ACCENTS5_BIN="$(mk_gh_pr accents5 '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion : ééééé"}')"
GH_ACCENTS10_BIN="$(mk_gh_pr accents10 '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion : éééééééééé"}')"
GH_NBSP_BIN="$(mk_gh_pr nbsp '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion :             "}')"
GH_FENCE_BIN="$(mk_gh_pr fence '{"state":"OPEN","body":"```\n## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion : doctrine seule, aucune donnée écrite\n```"}')"
GH_COMMENT_BIN="$(mk_gh_pr comment '{"state":"OPEN","body":"<!--\n## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion : doctrine seule, aucune donnée écrite\n-->"}')"
GH_SAINFENCE_BIN="$(mk_gh_pr sainfence '{"state":"OPEN","body":"## Merge-danger call\nPorte : sens unique\nRayon d'\''explosion : doctrine seule, aucune donnée écrite\n```\n## Autre\nPorte : double sens\n```\n"}')"
GH_AWKFAIL_BIN="$(mk_gh_pr awkfail '{"state":"OPEN","body":"## Merge-danger call\nPorte : double sens\nRayon d'\''explosion : doctrine seule, aucune donnée écrite"}')"
AWK_REAL="$(command -v awk)"
cat > "$GH_AWKFAIL_BIN/awk" <<AWKEOF
#!/usr/bin/env bash
# talon : l'analyseur du merge-danger call échoue (rc 2, comme une erreur de syntaxe d'awk) ; tout autre awk est le vrai
case "\$*" in *Merge-danger*) echo "awk: erreur simulée" >&2; exit 2 ;; esac
exec "$AWK_REAL" "\$@"
AWKEOF
chmod +x "$GH_AWKFAIL_BIN/awk"
e3_sain() { # <n> <libellé> <talon> : SAIN (code 3, stdout vide) — témoin positif de la contrainte voisine
  local d out rc; d="$(mk_sane_fixture "c$1")"
  out="$(PATH="$3:$PATH" run_gate --root "$d" --report "$REPORT_REL" --step "$STEP" 2>/dev/null)"; rc=$?
  if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "$1 $2 — code 3 (SAIN)"; else ko "$1 $2" "rc=$rc out=[$out]"; fi
}
M_ERR="[E3] PR ouverte sans merge-danger call conforme"
e3_case 50 "E3 deux lignes « Porte : » (répétée, contradictoire) — MANQUE nommé" "$GH_TWOPORTE_BIN" 0 "$M_ERR" ""
e3_case 51 "E3 « Porte : » placée après le titre « ## » suivant — hors section, MANQUE" "$GH_PORTELATE_BIN" 0 "$M_ERR" ""
e3_case 52 "E3 « Porte : sens unique, mais pas vraiment » (texte parasite) — MANQUE" "$GH_PORTEPARASITE_BIN" 0 "$M_ERR" ""
e3_case 53 "E3 titre « ## Merge-danger calls » (suffixe) — pas le titre exact, MANQUE" "$GH_TITRESUFFIXE_BIN" 0 "section « ## Merge-danger call » absente" ""
e3_case 54 "E3 section répétée (deux titres exacts) — MANQUE nommé" "$GH_TWOSECTIONS_BIN" 0 "section répétée" ""
e3_case 55 "E3 rayon fait de blancs et de 2 lettres — moins de 10 caractères non blancs, MANQUE" "$GH_BLANCS_BIN" 0 "rayon d'explosion de moins de 10" ""
e3_case 56 "E3 rayon de 5 caractères accentués (10 octets) — compté en caractères, MANQUE" "$GH_ACCENTS5_BIN" 0 "rayon d'explosion de moins de 10" ""
e3_case 57 "E3 rayon fait d'espaces insécables — aucun caractère non blanc, MANQUE" "$GH_NBSP_BIN" 0 "rayon d'explosion de moins de 10" ""
e3_case 58 "E3 section conforme dans un bloc de code — invisible à la relecture, MANQUE" "$GH_FENCE_BIN" 0 "section « ## Merge-danger call » absente" ""
e3_case 59 "E3 section conforme dans un commentaire HTML — invisible, MANQUE" "$GH_COMMENT_BIN" 0 "section « ## Merge-danger call » absente" ""
e3_sain 60 "E3 rayon de 10 caractères accentués — SAIN (témoin de 56)" "$GH_ACCENTS10_BIN"
e3_sain 61 "E3 section conforme suivie d'un bloc de code portant titre et Porte — ignorés, SAIN (témoin de 58)" "$GH_SAINFENCE_BIN"
# 62 — l'échec de l'analyseur (awk rc 2) n'est PAS un manque de la PR : INDÉTERMINÉ (rc 4), cause nommée, jamais « Porte absente ».
e3_case 62 "E3 analyseur en échec (awk rc 2) — INDÉTERMINÉ, jamais « Porte absente »" "$GH_AWKFAIL_BIN" 4 "analyse du merge-danger call impossible" "Porte"

# === Cas 28-36 — E7 : rien de rangeable n'est laissé (SOBR-07, plan 41.3-04) ==============================
CONDUCTOR_REAL="$(cd "$(dirname "$SCRIPT")/../../conductor" && pwd)"
mk_inst() { # <script à installer> <real|none|stub:<corps>> -> imprime le chemin de la copie (lab « installé » jetable)
  local d; d="$(mktemp -d "$TMP/inst.XXXXXX")"
  mkdir -p "$d/dev-orchestrator/scripts"; cp "$1" "$d/dev-orchestrator/scripts/check-mission-exit.sh"
  case "$2" in
    real) ln -s "$CONDUCTOR_REAL" "$d/conductor" ;;
    stub:*) printf '%s\n' "${2#stub:}" > "$d/dev-orchestrator/scripts/check-method-budget.sh" ;;
  esac
  printf '%s' "$d/dev-orchestrator/scripts/check-mission-exit.sh"
}
gate_at() { # <script copie> <dépôt> -> stdout ; le rc et stderr via E7_RC / E7_ERR
  E7_OUT="$( ( HOME="$EMPTY_HOME"; export HOME; unset CLAUDE_PLUGIN_ROOT GSD_WORKSTREAM 2>/dev/null; PATH="$GH_OK_BIN:$PATH" bash "$1" --root "$2" --report "$REPORT_REL" --step "$STEP" 2>"$TMP/e7.err" ) )"; E7_RC=$?
  E7_ERR="$(cat "$TMP/e7.err")"
}
git_f() { git -C "$1" -c user.email=t@t -c user.name=t "${@:2}" >/dev/null 2>&1; }

# E7a — une branche intégrée laissée derrière : manque E7 nommé, code 0.
D="$(mk_sane_fixture c28)"; G7="$(mk_inst "$SCRIPT" real)"
git_f "$D" checkout -q main; git_f "$D" checkout -q -b old; git_f "$D" commit -q --allow-empty -m "travail old"
git_f "$D" checkout -q main; git_f "$D" merge -q --no-ff old -m "merge old"; git_f "$D" push -q origin main; git_f "$D" checkout -q feature/mission
gate_at "$G7" "$D"
case "$E7_OUT" in *"[E7] RANGEABLE branche : old"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 0 ] && [ "$named" -eq 1 ]; then ok "28 E7a branche mergée laissée — code 0, manque [E7] qui la nomme"; else ko "28 E7a branche mergée laissée" "rc=$E7_RC out=[$E7_OUT] err=[$E7_ERR]"; fi

# E7b — rien à ranger : E7 contribue au SAIN.
D="$(mk_sane_fixture c29)"; gate_at "$G7" "$D"
case "$E7_ERR" in *"sept contrôles E1 à E7"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 3 ] && [ -z "$E7_OUT" ] && [ "$named" -eq 1 ]; then ok "29 E7b rien à ranger — code 3, stdout vide, « sept contrôles E1 à E7 »"; else ko "29 E7b rien à ranger" "rc=$E7_RC out=[$E7_OUT] err=[$E7_ERR]"; fi

# E7c — script de budget introuvable, ou rc 2 : INDÉTERMINÉ, jamais sain.
D="$(mk_sane_fixture c30)"; gate_at "$(mk_inst "$SCRIPT" none)" "$D"
case "$E7_ERR" in *"[E7] check-method-budget.sh introuvable"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 4 ] && [ "$named" -eq 1 ]; then ok "30 E7c script de budget introuvable — code 4, cause nommée"; else ko "30 E7c introuvable" "rc=$E7_RC err=[$E7_ERR]"; fi
D="$(mk_sane_fixture c30b)"; gate_at "$(mk_inst "$SCRIPT" 'stub:exit 2')" "$D"
case "$E7_ERR" in *"[E7] check-method-budget.sh a rendu 2"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 4 ] && [ "$named" -eq 1 ]; then ok "30b E7c budget rc 2 — code 4, jamais SAIN"; else ko "30b E7c rc 2" "rc=$E7_RC err=[$E7_ERR]"; fi

# E7d — rc 1 dû à DÉPASSÉ seul : constat, pas un manque du geste, SAIN.
D="$(mk_sane_fixture c31)"; gate_at "$(mk_inst "$SCRIPT" 'stub:echo "[budget] STATE DÉPASSÉ : x fait 99 Ko (budget 8 Ko)"; exit 1')" "$D"
if [ "$E7_RC" -eq 3 ] && [ -z "$E7_OUT" ]; then ok "31 E7d rc 1 dû à DÉPASSÉ seul — code 3 (non imputé au geste)"; else ko "31 E7d DÉPASSÉ seul" "rc=$E7_RC out=[$E7_OUT] err=[$E7_ERR]"; fi

# E7e — rc 1 dû à un RANGEABLE apparu ou à ARCHIVAGE REFUSÉ : manque, jamais SAIN. (À VALIDER n'est pas lu : le gate passe
# --no-remote, le budget ne le rend jamais à cet appel.)
D="$(mk_sane_fixture c32)"; gate_at "$(mk_inst "$SCRIPT" 'stub:echo "[budget] RANGEABLE branche : x (intégrée)"; exit 1')" "$D"
case "$E7_OUT" in *"[E7] RANGEABLE branche : x"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 0 ] && [ "$named" -eq 1 ]; then ok "32 E7e RANGEABLE apparu — code 0, manque [E7] nommé"; else ko "32 E7e RANGEABLE" "rc=$E7_RC out=[$E7_OUT]"; fi
D="$(mk_sane_fixture c32b)"; gate_at "$(mk_inst "$SCRIPT" 'stub:echo "[budget] ARCHIVAGE REFUSÉ : .planning/BACKLOG.md modifiée dans l arbre de travail, non commitée, rien déplacé"; exit 1')" "$D"
case "$E7_OUT" in *"[E7] ARCHIVAGE REFUSÉ"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 0 ] && [ "$named" -eq 1 ]; then ok "32b E7e ARCHIVAGE REFUSÉ — code 0, manque [E7] nommé"; else ko "32b E7e REFUSÉ" "rc=$E7_RC out=[$E7_OUT]"; fi

# E7f — dépassement réel, source commitée : E7 archive SANS geste humain, rend « archivé, à commiter » ; après commit, SAIN.
mk_e7f() { # <nom> -> dépôt sain dont le BACKLOG porte un sujet clos, commité
  local d; d="$(mk_sane_fixture "$1")"
  printf '# Backlog\n\n## Ouvert — DIFFÉRÉ (2026-01-01)\ntexte\n\n## Clos — CLOS (2026-01-02)\ntexte clos\n' > "$d/.planning/BACKLOG.md"
  git_f "$d" add -A; git_f "$d" commit -q -m "backlog avec un sujet clos"; printf '%s' "$d"
}
D="$(mk_e7f c33)"; cp "$D/.planning/BACKLOG.md" "$TMP/e7f.avant"; H="$(git -C "$D" rev-parse HEAD)"; G7="$(mk_inst "$SCRIPT" real)"
gate_at "$G7" "$D"
case "$E7_OUT" in *"[E7] archivé, à commiter : ARCHIVÉ : .planning/BACKLOG.md"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 0 ] && [ "$named" -eq 1 ]; then ok "33 E7f archivage sans geste humain — code 0, « archivé, à commiter »"; else ko "33 E7f archivage" "rc=$E7_RC out=[$E7_OUT] err=[$E7_ERR]"; fi
REF="$(awk -F'\t' '$3 ~ /BACKLOG.md$/ { print $5 }' "$D/.planning/archives/INDEX.tsv" 2>/dev/null | head -1)"
if [ -n "$REF" ] && git -C "$D" cat-file blob "$REF" > "$TMP/e7f.restaure" 2>/dev/null && cmp -s "$TMP/e7f.restaure" "$TMP/e7f.avant"; then ok "33b E7f ligne INDEX écrite, git cat-file blob <ref> = la source d'avant (cmp -s)"; else ko "33b E7f restauration" "blob de l'INDEX = source d'avant" "ref=[$REF]"; fi
if [ "$(git -C "$D" rev-parse HEAD)" = "$H" ]; then ok "33c E7f aucun commit posé par le gate"; else ko "33c E7f aucun commit" "HEAD inchangé" "HEAD déplacé"; fi
git_f "$D" add -A; git_f "$D" commit -q -m "archivage commité"; gate_at "$G7" "$D"
if [ "$E7_RC" -eq 3 ] && [ -z "$E7_OUT" ]; then ok "34 E7f après le commit, second passage — code 3 (SAIN)"; else ko "34 E7f second passage" "rc=$E7_RC out=[$E7_OUT] err=[$E7_ERR]"; fi

# E7g — DELTA : le rangeable qui existait au démarrage (branche d'un autre mainteneur) n'est PAS imputé à la mission.
D="$(mk_sane_fixture c35)"; G7="$(mk_inst "$SCRIPT" real)"
git_f "$D" checkout -q main; git_f "$D" checkout -q -b avant; git_f "$D" commit -q --allow-empty -m "travail avant"
git_f "$D" checkout -q main; git_f "$D" merge -q --no-ff avant -m "merge avant"; git_f "$D" push -q origin main; git_f "$D" checkout -q feature/mission
run_gate --root "$D" --budget-snapshot >/dev/null 2>&1; gate_at "$G7" "$D"
if [ "$E7_RC" -eq 3 ] && [ -z "$E7_OUT" ]; then ok "36 E7g rangeable préexistant au snapshot — code 3 (non imputé à la mission)"; else ko "36 E7g préexistant" "rc=$E7_RC out=[$E7_OUT] err=[$E7_ERR]"; fi

# E7h — snapshot absent : INDÉTERMINÉ (cause nommée, geste à poser), jamais SAIN.
D="$(mk_sane_fixture c36)"; rm -f "$D/.git/vf-mission-budget.snap"; gate_at "$G7" "$D"
case "$E7_ERR" in *"[E7] snapshot de début de mission absent"*"--budget-snapshot"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 4 ] && [ "$named" -eq 1 ]; then ok "37 E7h snapshot absent — code 4, cause et geste nommés"; else ko "37 E7h snapshot absent" "rc=$E7_RC err=[$E7_ERR]"; fi

# E7i — ARCHIVAGE NON TENTÉ (dépôt partitionné, aucun compartiment résolu) : INDÉTERMINÉ, plus de silence.
D="$(mk_sane_fixture c37)"; gate_at "$(mk_inst "$SCRIPT" 'stub:echo "[budget] ARCHIVAGE NON TENTÉ : dépôt partitionné, aucun compartiment résolu"; exit 0')" "$D"
case "$E7_ERR" in *"[E7] ARCHIVAGE NON TENTÉ"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 4 ] && [ "$named" -eq 1 ]; then ok "38 E7i ARCHIVAGE NON TENTÉ — code 4, nommé"; else ko "38 E7i NON TENTÉ" "rc=$E7_RC err=[$E7_ERR]"; fi

# --budget-snapshot : stdout vide, rc 0, fichier posé sous le répertoire git, arbre intact (E2 reste propre).
D="$(mk_sane_fixture c38)"; rm -f "$D/.git/vf-mission-budget.snap"
out="$(PATH="$GH_OK_BIN:$PATH" run_gate --root "$D" --budget-snapshot 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ] && [ -f "$D/.git/vf-mission-budget.snap" ] && [ -z "$(git -C "$D" status --porcelain)" ]; then ok "39 --budget-snapshot — rc 0, stdout vide, fichier sous .git, arbre propre"; else ko "39 --budget-snapshot" "rc=$rc out=[$out]"; fi

# --- Identité et date du snapshot (correction 41.3, m3) ---------------------------------------------------
# Le lien DRIVER.lock → DRIVER.lock.gen.<…> est ce que driver-lock.sh pose ; le talon de status n'en sait rien, E7 lit le lien.
set_lock() { # <dépôt> <nom de génération> : (re)pointe le lien du verrou
  mkdir -p "$1/.planning/$2"; ln -sfn "$2" "$1/.planning/DRIVER.lock"
}
snap() { PATH="$GH_OK_BIN:$PATH" run_gate --root "$1" --budget-snapshot >/dev/null 2>&1; }
# 40 — snapshot d'une AUTRE génération du verrou : INDÉTERMINÉ, cause nommée ; 40b témoin : même génération, SAIN.
D="$(mk_sane_fixture c40)"; set_lock "$D" DRIVER.lock.gen.1.11; snap "$D"; G7="$(mk_inst "$SCRIPT" real)"
SN="$(cat "$D/.git/vf-mission-budget.snap")"
case "$SN" in *"#gen=DRIVER.lock.gen.1.11"*"#date=20"*|*"#date=20"*"#gen=DRIVER.lock.gen.1.11"*) named=1 ;; *) named=0 ;; esac
if [ "$named" -eq 1 ]; then ok "40a le snapshot porte l'identité (génération du verrou) ET la date"; else ko "40a en-tête du snapshot" "[$SN]"; fi
gate_at "$G7" "$D"
if [ "$E7_RC" -eq 3 ] && [ -z "$E7_OUT" ]; then ok "40b même génération que le verrou courant — code 3 (témoin)"; else ko "40b même génération" "rc=$E7_RC out=[$E7_OUT] err=[$E7_ERR]"; fi
set_lock "$D" DRIVER.lock.gen.2.22; gate_at "$G7" "$D"
case "$E7_ERR" in *"[E7] snapshot d'une autre mission"*"DRIVER.lock.gen.1.11"*"DRIVER.lock.gen.2.22"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 4 ] && [ "$named" -eq 1 ]; then ok "40 génération du snapshot ≠ verrou courant — code 4 (INDÉTERMINÉ), les deux générations nommées"; else ko "40 autre génération" "rc=$E7_RC err=[$E7_ERR]"; fi
# 41 — verrou relâché depuis (cas ordinaire à la sortie) : l'identité n'est plus recontrôlable, la date est dite, SAIN.
rm -f "$D/.planning/DRIVER.lock"; gate_at "$G7" "$D"
case "$E7_ERR" in *"snapshot posé le 20"*"l'identité n'est plus recontrôlable"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 3 ] && [ -z "$E7_OUT" ] && [ "$named" -eq 1 ]; then ok "41 verrou relâché — code 3, limite dite sur stderr (date du snapshot)"; else ko "41 verrou relâché" "rc=$E7_RC out=[$E7_OUT] err=[$E7_ERR]"; fi
# 41a — snapshot posé sans verrou et toujours sans verrou : accepté, mais dit pour ce qu'il est (aucune identité)
D="$(mk_sane_fixture c41a)"; gate_at "$G7" "$D"
case "$E7_ERR" in *"SANS verrou de driver : aucune identité de mission"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 3 ] && [ "$named" -eq 1 ]; then ok "41a snapshot sans verrou — code 3, « aucune identité de mission » dit sur stderr"; else ko "41a sans verrou" "rc=$E7_RC err=[$E7_ERR]"; fi
# 41b — snapshot posé SANS verrou, verrou présent à la sortie : pas la même situation, INDÉTERMINÉ.
D="$(mk_sane_fixture c41b)"; set_lock "$D" DRIVER.lock.gen.3.33; gate_at "$G7" "$D"
if [ "$E7_RC" -eq 4 ]; then ok "41b snapshot posé sans verrou, verrou tenu à la sortie — code 4"; else ko "41b sans verrou puis verrou" "rc=$E7_RC err=[$E7_ERR]"; fi
# 42 — snapshot sans en-tête (posé par une version antérieure) : INDÉTERMINÉ.
D="$(mk_sane_fixture c42)"; printf 'RANGEABLE branche : x\n' > "$D/.git/vf-mission-budget.snap"; gate_at "$G7" "$D"
case "$E7_ERR" in *"[E7] snapshot de début de mission sans identité"*) named=1 ;; *) named=0 ;; esac
if [ "$E7_RC" -eq 4 ] && [ "$named" -eq 1 ]; then ok "42 snapshot sans identité — code 4, cause nommée"; else ko "42 sans identité" "rc=$E7_RC err=[$E7_ERR]"; fi
# 43 — un ARCHIVAGE REFUSÉ déjà là au démarrage (source non commitée) n'est PAS imputé à la mission ; témoin : sans lui dans le snapshot, il l'est.
mk_dirty() { local d; d="$(mk_e7f "$1")"; echo "ajout non commité" >> "$d/.planning/BACKLOG.md"; printf '%s' "$d"; }
D="$(mk_dirty c43)"; snap "$D"; gate_at "$G7" "$D"
case "$E7_OUT" in *"[E7] ARCHIVAGE REFUSÉ"*) named=1 ;; *) named=0 ;; esac
if [ "$named" -eq 0 ]; then ok "43 refus préexistant (source non commitée au démarrage) — non imputé à la mission"; else ko "43 refus préexistant" "rc=$E7_RC out=[$E7_OUT]"; fi
grep -q 'ARCHIVAGE REFUSÉ' "$D/.git/vf-mission-budget.snap" && ok "43a … il est dans la référence (le snapshot l'a photographié sans rien écrire)" || ko "43a référence" "ARCHIVAGE REFUSÉ dans le snapshot"
[ ! -e "$D/.planning/archives" ] && ok "43b le snapshot n'a rien archivé ni écrit sous .planning/archives" || ko "43b lecture seule" "aucun .planning/archives"
grep -v 'ARCHIVAGE REFUSÉ' "$D/.git/vf-mission-budget.snap" > "$TMP/snap43" && cp "$TMP/snap43" "$D/.git/vf-mission-budget.snap"; gate_at "$G7" "$D"
case "$E7_OUT" in *"[E7] ARCHIVAGE REFUSÉ"*) named=1 ;; *) named=0 ;; esac
if [ "$named" -eq 1 ]; then ok "43c témoin : le même refus, absent de la référence, EST imputé"; else ko "43c témoin" "out=[$E7_OUT]"; fi

# --- Mutants de script (rc attendu/obtenu, même forme que les autres suites du module) -------------------
MUT_N=0
e7_mutant() { # <id> <ancienne ligne> <nouvelle ligne> <scénario> <rc original attendu> <rc mutant attendu> [<ancienne ligne 2> <nouvelle ligne 2>]
  local id="$1" old="$2" new="$3" sc="$4" eo="$5" em="$6" f ro rm
  MUT_N=$((MUT_N+1)); f="$TMP/mut-e7-$MUT_N.sh"
  MUT_OLD="$old" MUT_NEW="$new" MUT_OLD2="${7:-}" MUT_NEW2="${8:-}" awk '{ if ($0 == ENVIRON["MUT_OLD"]) print ENVIRON["MUT_NEW"]; else if (ENVIRON["MUT_OLD2"] != "" && $0 == ENVIRON["MUT_OLD2"]) print ENVIRON["MUT_NEW2"]; else print }' "$SCRIPT" > "$f"
  if cmp -s "$f" "$SCRIPT" || ! bash -n "$f" 2>/dev/null; then ko "35 $id mutant NON OPPOSABLE" "mutation appliquée et syntaxe valide"; return; fi
  "$sc" "$SCRIPT" "mo$MUT_N"; ro=$?; "$sc" "$f" "mm$MUT_N"; rm=$?
  if [ "$ro" -eq "$eo" ] && [ "$rm" -eq "$em" ]; then ok "35 $id TUE : rc_mutant=$rm attendu $em, rc_original=$ro attendu $eo"
  else ko "35 $id NON TUE" "original=$eo mutant=$em obtenu original=$ro mutant=$rm"; fi
}
sc_c() { local d; d="$(mk_sane_fixture "$2")"; gate_at "$(mk_inst "$1" 'stub:exit 2')" "$d"; return "$E7_RC"; }
sc_g() { local d; d="$(mk_sane_fixture "$2")"; git_f "$d" checkout -q main; git_f "$d" checkout -q -b avant; git_f "$d" commit -q --allow-empty -m "travail avant"
  git_f "$d" checkout -q main; git_f "$d" merge -q --no-ff avant -m "merge avant"; git_f "$d" push -q origin main; git_f "$d" checkout -q feature/mission
  run_gate --root "$d" --budget-snapshot >/dev/null 2>&1; gate_at "$(mk_inst "$1" real)" "$d"; return "$E7_RC"; }
sc_h() { local d; d="$(mk_sane_fixture "$2")"; rm -f "$d/.git/vf-mission-budget.snap"; gate_at "$(mk_inst "$1" real)" "$d"; return "$E7_RC"; }
sc_i() { local d; d="$(mk_sane_fixture "$2")"; gate_at "$(mk_inst "$1" 'stub:echo "[budget] ARCHIVAGE NON TENTÉ : dépôt partitionné, aucun compartiment résolu"; exit 0')" "$d"; return "$E7_RC"; }
sc_f() { local d g; d="$(mk_e7f "$2")"; g="$(mk_inst "$1" real)"; gate_at "$g" "$d"; git_f "$d" add -A; git_f "$d" commit -q -m "archivage commité"; gate_at "$g" "$d"; return "$E7_RC"; }
e7_mutant "E7c (rc 2 lu comme sain)" '  elif [ "$E7_RC" -ge 2 ]; then' '  elif [ "$E7_RC" -ge 99 ]; then' sc_c 4 3
e7_mutant "E7g (delta ignoré, tout le rangeable du dépôt imputé)" '  E7_LIGNES="$(LC_ALL=C comm -23 "$E7_NOW" "$E7_SNAP")"' '  E7_LIGNES="$(LC_ALL=C comm -23 "$E7_NOW" /dev/null)"' sc_g 3 0
sc_j() { local d; d="$(mk_sane_fixture "$2")"; set_lock "$d" DRIVER.lock.gen.1.11; snap "$d"; set_lock "$d" DRIVER.lock.gen.2.22; gate_at "$(mk_inst "$1" real)" "$d"; return "$E7_RC"; }
sc_k() { local d g; d="$(mk_dirty "$2")"; g="$(mk_inst "$1" real)"; PATH="$GH_OK_BIN:$PATH" HOME="$EMPTY_HOME" bash "$g" --root "$d" --budget-snapshot >/dev/null 2>&1; gate_at "$g" "$d"
  case "$E7_OUT" in *"[E7] ARCHIVAGE REFUSÉ"*) return 1 ;; *) return 0 ;; esac; }
sc_l() { local d; d="$(mk_sane_fixture "$2")"; printf 'RANGEABLE branche : x\n' > "$d/.git/vf-mission-budget.snap"; gate_at "$(mk_inst "$1" real)" "$d"; return "$E7_RC"; }
# E7h : DEUX couches (snapshot absent, puis snapshot sans identité) — le mutant retire les deux ; chacune seule laisse le même code 4 (défense en profondeur)
e7_mutant "E7h (snapshot absent non vu, lu sain : les deux couches retirées)" 'elif [ -z "$E7_SNAP" ] || [ ! -f "$E7_SNAP" ]; then' 'elif false; then' sc_h 4 3 '  if [ -z "$E7_SGEN" ]; then' '  if false; then'
e7_mutant "E7j (identité du snapshot non comparée au verrou courant)" '  elif [ "$E7_CGEN" != "-" ] && [ "$E7_CGEN" != "$E7_SGEN" ]; then' '  elif false; then' sc_j 4 3
e7_mutant "E7k (snapshot pris sans --dry-run : un refus préexistant est imputé)" '  SNAP_OUT="$(bash "$SNAP_BUDGET" --root "$ROOT" --no-remote --quiet --auto --dry-run 2>/dev/null)"; SNAP_RC=$?' '  SNAP_OUT="$(bash "$SNAP_BUDGET" --root "$ROOT" --no-remote --quiet 2>/dev/null)"; SNAP_RC=$?' sc_k 0 1
e7_mutant "E7l (snapshot sans identité accepté)" '  if [ -z "$E7_SGEN" ]; then' '  if false; then' sc_l 4 3
e7_mutant "E7i (ARCHIVAGE NON TENTÉ redevenu silence)" '  if [ -n "$E7_NONTENTE" ]; then' '  if false; then' sc_i 4 3
e7_mutant "E7f (--auto retiré)" '  E7_OUT="$(bash "$E7_BUDGET" --root "$ROOT" --no-remote --quiet --strict --auto 2>/dev/null)"; E7_RC=$?' '  E7_OUT="$(bash "$E7_BUDGET" --root "$ROOT" --no-remote --quiet --strict 2>/dev/null)"; E7_RC=$?' sc_f 3 0
# Mutants E3 (POCK-06) : le scénario installe la copie (mk_inst real, sinon E7 ne résout pas check-method-budget.sh
# depuis le dossier temporaire et le code serait 4 pour une raison étrangère) et l'exécute avec le talon `gh` voulu.
sc_e3() { # <script> <nom de fixture> <dossier du talon gh> -> rc du gate
  local d g; d="$(mk_sane_fixture "$2")"; g="$(mk_inst "$1" real)"
  ( HOME="$EMPTY_HOME"; export HOME; unset CLAUDE_PLUGIN_ROOT GSD_WORKSTREAM 2>/dev/null; PATH="$3:$PATH" bash "$g" --root "$d" --report "$REPORT_REL" --step "$STEP" >/dev/null 2>&1 ); return $?
}
sc_e3a() { sc_e3 "$1" "$2" "$GH_NOSECTION_BIN"; }
sc_e3b() { sc_e3 "$1" "$2" "$GH_NOBODY_BIN"; }
e7_mutant "E3a (section absente lue saine)" '            11) E3_STATUS="manque"; E3_MSG="[E3] PR ouverte sans merge-danger call conforme (POCK-06) : section « ## Merge-danger call » absente" ;;' '            11) E3_STATUS="sain" ;;' sc_e3a 0 3
e7_mutant "E3b (type du corps non testé : clé body absente lue comme corps)" '        if [ "$E3_BODY_TYPE" != "string" ]; then' '        if false; then' sc_e3b 4 0
# Revue W1 (M-06) : un mutant par contrainte de e3_merge_danger / e3_charcount, chacun joué sur le corps qui la discrimine.
sc_e3c() { sc_e3 "$1" "$2" "$GH_TWOPORTE_BIN"; }
sc_e3t() { sc_e3 "$1" "$2" "$GH_TWOSECTIONS_BIN"; }
sc_e3d() { sc_e3 "$1" "$2" "$GH_PORTELATE_BIN"; }
sc_e3h() { sc_e3 "$1" "$2" "$GH_PORTEPARASITE_BIN"; }
sc_e3j() { sc_e3 "$1" "$2" "$GH_TITRESUFFIXE_BIN"; }
sc_e3g() { sc_e3 "$1" "$2" "$GH_BLANCS_BIN"; }
sc_e3u() { sc_e3 "$1" "$2" "$GH_ACCENTS5_BIN"; }
sc_e3n() { sc_e3 "$1" "$2" "$GH_NBSP_BIN"; }
sc_e3f() { sc_e3 "$1" "$2" "$GH_FENCE_BIN"; }
sc_e3k() { sc_e3 "$1" "$2" "$GH_COMMENT_BIN"; }
sc_e3m() { sc_e3 "$1" "$2" "$GH_AWKFAIL_BIN"; }
e7_mutant "E3c (unicité de « Porte : » : une seule ligne valide suffit)" '      if (ptot != 1 || pval != 1) exit 12' '      if (pval < 1) exit 12' sc_e3c 0 3
e7_mutant "E3t (section répétée acceptée : la première gagne)" '      if (ntit > 1) exit 12' '      ntit = ntit' sc_e3t 0 3
e7_mutant "E3d (la section ne se termine jamais au titre « ## » suivant)" '    l ~ /^## / { if (l ~ /^## Merge-danger call[ \t]*$/) { ntit++; insec = (ntit == 1) } else { insec = 0 }; next }' '    l ~ /^## / { if (l ~ /^## Merge-danger call[ \t]*$/) { ntit++; insec = (ntit == 1) }; next }' sc_e3d 0 3
e7_mutant "E3h (ancre de fin de la ligne « Porte : » retirée : texte parasite accepté)" '    insec && l ~ /^Porte ?:/ { ptot++; if (l ~ /^Porte ?:[ \t]*(sens unique|double sens)[ \t]*$/) pval++ }' '    insec && l ~ /^Porte ?:/ { ptot++; if (l ~ /^Porte ?:[ \t]*(sens unique|double sens)/) pval++ }' sc_e3h 0 3
e7_mutant "E3j (titre exact : ancre de fin retirée, « calls » ouvre la section)" '    l ~ /^## / { if (l ~ /^## Merge-danger call[ \t]*$/) { ntit++; insec = (ntit == 1) } else { insec = 0 }; next }' '    l ~ /^## / { if (l ~ /^## Merge-danger call/) { ntit++; insec = (ntit == 1) } else { insec = 0 }; next }' sc_e3j 0 3
e7_mutant "E3g (blancs comptés comme caractères)" "    | LC_ALL=C tr -d '[:space:]' \\" '    | cat \' sc_e3g 0 3
e7_mutant "E3u (longueur en octets, pas en caractères)" "    | awk 'NF && (\$1 < 128 || \$1 >= 192) { n++ } END { print n + 0 }'" "    | awk 'NF { n++ } END { print n + 0 }'" sc_e3u 0 3
e7_mutant "E3n (espace insécable comptée comme caractère)" '    | LC_ALL=C sed -e "$E3_BLANCS_SED" \' '    | cat \' sc_e3n 0 3
e7_mutant "E3f (bloc de code lu comme du texte rendu)" '    l ~ /^ ? ? ?(```|~~~)/ { infence = !infence; next }' '    l ~ /^ ? ? ?(```|~~~)/ { next }' sc_e3f 0 3
e7_mutant "E3k (commentaire HTML lu comme du texte rendu)" '    { while ((i = index(l, "<!--")) > 0) { j = index(substr(l, i + 4), "-->"); if (j == 0) { l = substr(l, 1, i - 1); incom = 1; break }; l = substr(l, 1, i - 1) substr(l, i + j + 6) } }' '    { l = l }' sc_e3k 0 3
e7_mutant "E3m (échec de l'analyseur lu comme un manque de la PR)" '            *) E3_STATUS="indet"; E3_MSG="[E3] analyse du merge-danger call impossible (outil d'"'"'analyse en échec) — invérifiable" ;;' '            *) E3_STATUS="manque"; E3_MSG="[E3] PR ouverte sans merge-danger call conforme (POCK-06) : ligne Porte absente" ;;' sc_e3m 4 0

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
