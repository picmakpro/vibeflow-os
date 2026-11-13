#!/usr/bin/env bash
# couloirs-commun.sh — socle de test-cockpit-couloirs.sh (80-04) : lab, serveur, mutants. À SOURCER (jamais lancé seul) après avoir posé
#   SCRIPTS, HERE_T, ENG, CHROME, WORK, AUX, SC_BASE, PASS, FAIL, PIDS et sourcé hygiene.sh. Il source lui-même socle-serveur.sh : le serveur se lance par
#   cockpit_lancer et un mutant s'écrit dans une copie complète du module (cockpit_module_copie), jamais dans le dépôt (jointure J1, étape 2 points 2-3).
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
# ---- jointure J1 (étape 2, points 2-3) : lancement par socle-serveur.sh, mutants par cockpit_module_copie (79-02, 79-06, A48 point 41) ----
. "$HERE_T/socle-serveur.sh"   # cockpit_lancer, cockpit_module_copie ; après hygiene.sh et vf_hyg_init (la marque de la suite)
MOD_BASE="$(cd "$SC_BASE/.." && pwd -P)"   # racine du module servi : celle de SC_BASE (CL_SCRIPTS, PL_SCRIPTS, PR_SCRIPTS rejouent une autre copie) ; COCKPIT_MODULE la remplace pour un mutant
cat > "$AUX/compte.mjs" <<'JS'
// compte.mjs <dossier> <ancien> <nouveau> : « n_ancien n_nouveau », occurrences (littérales) des deux textes dans les fichiers de la sortie, hors .cache — preuve de chargement d'un mutant
import fs from 'node:fs'; import path from 'node:path';
const [, , dir, a, b] = process.argv; let na = 0, nb = 0;
const compte = (t, x) => (x ? t.split(x).length - 1 : 0);
const marche = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) {
  if (e.name === '.cache') continue; const p = path.join(d, e.name);
  if (e.isDirectory()) marche(p); else if (e.isFile()) { const t = fs.readFileSync(p, 'utf8'); na += compte(t, a); nb += compte(t, b); } } };
marche(dir); console.log(na + ' ' + nb);
JS
# bâtir et servir : build_serve <lab> [--terminal] -> PORT, SRV, VF_PID (pas de sous-shell : PIDS doit survivre) ; le module servi est COCKPIT_MODULE (copie d'un mutant) sinon celui de SC_BASE
build_serve() {
  local L="$1" O="$1/.vibeflow/cockpit" racine="${COCKPIT_MODULE:-$MOD_BASE}" rc=0
  node "$racine/scripts/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
  mkdir -p "$WORK/fauxbin" "$O/.cache"
  cp "$SCRIPTS/tests/temoins/fauxbin-claude/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
  if [ "${2:-}" = "--terminal" ]; then
    (umask 077; node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" | tr -d '\n' > "$O/.cache/terminal-amorce")
  fi
  COCKPIT_MODULE="$racine" COCKPIT_LOG="$WORK/serve.out" COCKPIT_PRET="$([ "${2:-}" = "--terminal" ] && echo terminal || echo port)" \
    cockpit_lancer "$L" PATH="$WORK/fauxbin:$PATH" SHELL=/bin/sh VF_COCKPIT_TERM_GRACE_MS=5000 ${CK_SANS_CLI:+--claude "$WORK/absent/claude"} ${2:+"$2"} || rc=$?   # CK_SANS_CLI=1 : serveur SANS CLI (#ask-warn affiché, barre de question plus haute), jamais le PATH du poste
  SRV="${VF_PID:-}"; PORT="${VF_PORT:-0}"; return 0
}
# mutant <nom> <fichier ui> <ancien> <nouveau> <pilote> <mode> <sections> [--terminal] -> RM ; la mutation s'écrit dans une copie COMPLÈTE du module
# (COCKPIT_MODULE="$(cockpit_module_copie)", jamais un lien, jamais le dépôt) ; une mutation impossible, un mutant non chargé (empreinte publiée
# différente : code 5 de cockpit_lancer) ou absent de la sortie servie comptent comme un échec
UI=skills/cockpit-moteur/assets/ui
mutant() {
  local L="$WORK/lab-$1" copie cible avant apres
  if ! copie="$(cockpit_module_copie)"; then echo "  ❌ FAIL — $1 : copie du module impossible"; FAIL=$((FAIL+1)); RM="{}"; return; fi
  cible="$copie/$UI/$2"
  if ! node "$AUX/mut.mjs" "$cible" "$3" "$4"; then echo "  ❌ FAIL — $1 : mutation impossible"; FAIL=$((FAIL+1)); RM="{}"; rm -rf "$copie"; return; fi
  cp -R "$LAB" "$L"
  avant="$(node "$AUX/compte.mjs" "$LAB/.vibeflow/cockpit" "$3" "$4")"
  COCKPIT_MODULE="$copie" build_serve "$L" "${8:-}"
  if [ "${PORT:-0}" -le 0 ]; then echo "  ❌ FAIL — $1 : le serveur de la copie mutée n'est pas prêt ou ne la charge pas (empreinte publiée différente)"; FAIL=$((FAIL+1)); RM="{}"; vf_hyg_stop "$SRV"; rm -rf "$L" "$copie"; return; fi
  apres="$(node "$AUX/compte.mjs" "$L/.vibeflow/cockpit" "$3" "$4")"
  if [ "${apres#* }" -le "${avant#* }" ] && [ "${apres% *}" -ge "${avant% *}" ]; then   # chargé = le texte neuf gagne une occurrence OU l'ancien en perd une (le neuf peut contenir l'ancien, ou l'inverse)
    echo "  ❌ FAIL — $1 : la mutation n'est pas dans la sortie servie (occurrences ancien / nouveau : $avant avant, $apres après)"; FAIL=$((FAIL+1)); RM="{}"; vf_hyg_stop "$SRV"; rm -rf "$L" "$copie"; return
  fi
  echo "     charge $1 : empreinte publiée = celle de la copie ; occurrences ancien / nouveau dans la sortie servie : $avant -> $apres"
  RM="$(mesurer "$5" "$6" "$7")"; vf_hyg_stop "$SRV"; rm -rf "$L" "$copie"
}
