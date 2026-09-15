#!/usr/bin/env bash
# test-check-mission-exit.sh — Suite de vérification de check-mission-exit.sh (HEAD-02, QUAL-01).
#
# Un cas par comportement du contrat (cf. en-tête du script testé), plus les six mutations de
# fixture (une par contrôle E1-E6) et deux mutations structurelles (D-11, cascade E1). Fixtures
# isolées via mktemp -d + git init + dépôt nu, jamais sur le repo réel. Chaque cas capture la
# sortie ET le code de retour dans deux variables distinctes, assertées séparément.
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
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then echo '{"state":"OPEN"}'; exit 0; fi
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
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then echo '{"state":"OPEN"}'; exit 0; fi
exit 1
EOF
chmod +x "$GH_NOAUTH_BIN/gh"

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

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
