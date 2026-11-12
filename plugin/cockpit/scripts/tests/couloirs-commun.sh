#!/usr/bin/env bash
# couloirs-commun.sh — socle de test-cockpit-couloirs.sh (80-04) : lab, serveur, mutants. À SOURCER (jamais lancé seul) après avoir posé
#   SCRIPTS, HERE_T, ENG, CHROME, WORK, AUX, SC_BASE, PASS, FAIL, PIDS et sourcé hygiene.sh.
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
assert_eq() {
  if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi
}
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('sortie illisible'); process.exit(0); }
if (j.erreur) { console.log('mesure indisponible : ' + j.erreur); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { console.log('mesure absente : ' + e.message); process.exit(0); }
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mut.mjs" <<'JS'
import fs from 'node:fs'; const [, , f, a, b] = process.argv; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(a) || t.split(a).length !== 2) { console.error('mutation impossible : motif absent ou multiple : ' + a); process.exit(1); }
fs.writeFileSync(f, t.replace(a, () => b));
JS
E() { printf '%s' "$2" | node "$AUX/ev.mjs" "$1"; }
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
mklab() { # un jalon en cours (6 phases : 2 faites, 1 en cours, 1 à recetter, 2 à faire), un jalon clos, un backlog de deux entrées, une graine
  local L="$1" B="$1/.planning"
  wr "$B/PROJECT.md" <<< '# Projet de test'
  wr "$B/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **v2.0 Couloirs** - Phases 1-6 (in progress)
- ✅ **v1.0 <img src=x onerror=window.__z=1>** - Phase 7 (shipped)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [x] **Phase 2: Écran** - second jet
- [ ] **Phase 3: Liens** - troisième jet
- [ ] **Phase 4: Reprise** - quatrième jet
- [ ] **Phase 5: <img src=x onerror=window.__x=1>** - cinquième jet
- [ ] **Phase 6: Recette** - sixième jet
- [x] **Phase 7: Ancien** - clos
MD
  wr "$B/REQUIREMENTS.md" <<'MD'
- [x] **FORM-01**: premier
- [ ] **FORM-02**: second

| FORM-01 | Phase 1 | Complete |
| FORM-02 | Phase 1 | Pending |
MD
  for n in 01 02; do
    printf '<objective>Plan %s</objective>\n' "$n" | wr "$B/phases/01-socle/01-$n-PLAN.md"; echo ok > "$B/phases/01-socle/01-$n-SUMMARY.md"
  done
  printf '<objective>Écran</objective>\n' | wr "$B/phases/02-ecran/02-01-PLAN.md"; echo ok > "$B/phases/02-ecran/02-01-SUMMARY.md"
  printf '<objective>Liens</objective>\n' | wr "$B/phases/03-liens/03-01-PLAN.md"
  for n in 01 02 03; do printf '<objective>Reprise</objective>\n' | wr "$B/phases/04-reprise/04-$n-PLAN.md"; done
  echo ok > "$B/phases/04-reprise/04-01-SUMMARY.md"
  printf '<objective>Recette</objective>\n' | wr "$B/phases/06-recette/06-01-PLAN.md"; echo ok > "$B/phases/06-recette/06-01-SUMMARY.md"
  printf '## <img src=x onerror=window.__w=1>\n\ntexte\n\n## Autre entrée — DIFFÉRÉ\n\ntexte\n' | wr "$B/BACKLOG.md"
  printf '# Une graine\n\ntexte\n' | wr "$B/seeds/SEED-001-graine.md"
  printf '# Graine hostile\n\ntexte\n' | wr "$B/seeds/SEED-002-\"><img src=x onerror=window.__y=1>.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
# bâtir et servir : build_serve <lab> <dossier de scripts> <dossier du moteur> [--terminal] -> PORT, SRV (pas de sous-shell : PIDS doit survivre)
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit"; node "$2/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  rm -f "$O/.cache/server.json"; mkdir -p "$WORK/fauxbin" "$O/.cache"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  if [ "${4:-}" = "--terminal" ]; then
    (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" | tr -d '\n' > "$O/.cache/terminal-amorce")
  fi
  ( cd "$L" && PATH="$WORK/fauxbin:$PATH" SHELL=/bin/sh VF_COCKPIT_TERM_GRACE_MS=5000 VF_COCKPIT_ENGINE_DIR="$3" VF_COCKPIT_SCRIPTS_DIR="$2" \
      exec node "$O/serve.mjs" --no-open ${4:+"$4"} --port "$(libre)" > "$WORK/serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV=$!; PIDS+=($SRV)
  for _ in $(seq 1 300); do grep -q '"port"' "$O/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$O/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
# mutant <nom> <fichier ui> <ancien> <nouveau> <pilote> <mode> <sections> [--terminal] -> RM ; une mutation impossible compte comme un échec
UI=skills/cockpit-moteur/assets/ui
mutant() {
  local M="$WORK/mod-$1" L="$WORK/lab-$1"; mkdir -p "$M/scripts" "$M/skills"
  cp "$SC_BASE"/*.mjs "$SC_BASE"/*.json "$M/scripts/"; cp -R "$SC_BASE/../skills/cockpit-moteur" "$M/skills/cockpit-moteur"; cp -R "$LAB" "$L"
  if ! node "$AUX/mut.mjs" "$M/$UI/$2" "$3" "$4"; then echo "  ❌ FAIL — $1 : mutation impossible"; FAIL=$((FAIL+1)); RM="{}"; return; fi
  build_serve "$L" "$M/scripts" "$M/skills/cockpit-moteur" "${8:-}"; RM="$(mesurer "$5" "$6" "$7")"; vf_hyg_stop "$SRV"; rm -rf "$L"
}
