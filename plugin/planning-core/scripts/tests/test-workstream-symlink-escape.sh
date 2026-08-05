#!/usr/bin/env bash
# test-workstream-symlink-escape.sh — Le RÉPERTOIRE d'un compartiment peut-il faire sortir du lab ?
#
# POURQUOI CETTE SUITE EXISTE (quatrième passage du même motif, mesuré le 2026-08-04).
# La politique partagée contraignait le NOM du workstream (alphabet, `..`, séparateurs) et refusait
# un pointeur-FICHIER en lien symbolique. Le CHEMIN du compartiment, lui, n'était contraint par
# rien : les quatre gates construisaient `<planning>/workstreams/<nom>` puis testaient `[ -d ]` (ou
# `[ -f .../STATE.md ]`) — et ces deux tests SUIVENT le lien. Un `.planning/workstreams/dev`
# versionné en mode 120000 vers un répertoire hors du lab suffisait à faire :
#   - INJECTER le STATE.md de la cible dans le contexte de session (planning-context.sh, exit 0) ;
#   - RÉIMPRIMER le frontmatter de la cible sur stdout d'un SessionStart (check-dev-bootstrap.sh) ;
#   - VÉRIFIER un fichier hors du lab en croyant vérifier celui du lab (check-state-integrity.sh) ;
#   - BÉNIR la partition « conforme » (check-workstream-pointer.sh) — le vert sur lequel les trois
#     autres s'appuient.
# Deux hooks SessionStart dans le lot : auto-déclenchés, sans aucune action de la victime.
#
# CE QUE LA SUITE MESURE, ET POURQUOI ELLE NE PEUT PAS ÊTRE VERTE À VIDE :
#   A. la fixture piégée est CONSTRUITE et DISCRIMINANTE (marqueur présent dans la cible, absent de
#      la racine) — asserté AVANT toute mesure, sinon les refus seraient rendus sur un arbre sans
#      piège et ne prouveraient rien ;
#   B. les quatre gates REFUSENT, chacun avec la sévérité de son rôle, et le marqueur de la cible
#      n'apparaît NULLE PART dans leur sortie ;
#   C. MUTATION — la garde retirée de la politique partagée, la fuite RÉAPPARAÎT sur les quatre. Le
#      mutant est refusé s'il n'a rien changé (`cmp` + compte de substitutions) : « non opposable »
#      est un échec, jamais un « mutant satisfait » ;
#   D. le cas LICITE (vrai répertoire) reste vert : les quatre rendent leur verdict nominal ;
#   E. la cible est INTACTE — un refus qui écrirait dans la cible serait un autre défaut.
#
# TOPOLOGIE DE LA COPIE : les scripts sont copiés À PLAT dans un même dossier temporaire, ce qui est
# exactement la topologie d'un lab réel (`copy_module_scripts` range tous les modules à plat dans
# `.claude/scripts/`) et ce que résout la 1re branche de la cascade `$(dirname "$0")/`.
#
# Portabilité : macOS (bash 3.2) et Linux. Aucun `grep -P`, `readlink -f`, `mapfile`, `declare -A`,
# `sed -i` nu, `stat -c` ni `${x,,}`.

set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd)"

POLICY="$HERE/workstream-policy.sh"
PC="$HERE/planning-context.sh"
SI="$PLUGIN_ROOT/conductor/scripts/check-state-integrity.sh"
WP="$PLUGIN_ROOT/conductor/scripts/check-workstream-pointer.sh"
DB="$PLUGIN_ROOT/dev-orchestrator/scripts/check-dev-bootstrap.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "== test-workstream-symlink-escape =="

for f in "$POLICY" "$PC" "$SI" "$WP" "$DB"; do
  [ -r "$f" ] || { echo "  ✗ script introuvable : $f"; exit 1; }
done

# Marqueur SYNTHÉTIQUE — aucune valeur machine réelle n'entre dans ce dépôt public.
MARQUEUR="MARQUEUR_HORS_LAB_zz9"

# ---------------------------------------------------------------------------------------------
# BANC : <dir> = dossier de scripts (politique saine ou mutée), <lab> = arbre à mesurer.
# ---------------------------------------------------------------------------------------------
poser_scripts() { # <dir> — copie les 5 scripts à plat
  local d="$1"
  mkdir -p "$d"
  cp "$POLICY" "$PC" "$SI" "$WP" "$DB" "$d/"
}

# Environnement TOUJOURS explicite : jamais d'héritage du shell qui lance la suite (ce serait un
# vert — ou un rouge — par contamination).
run_gate() { # <dir> <script> <ws-ou-vide> <args...>
  local d="$1" s="$2" ws="$3"; shift 3
  if [ -n "$ws" ]; then
    env -u VF_WORKSTREAM -u VF_CONTEXT_WORKSTREAM -u VF_BOOTSTRAP_WORKSTREAM \
        -u VF_STATE_WORKSTREAM -u VF_WORKSTREAM_PLANNING_DIR -u VF_BOOTSTRAP_PLANNING_DIR \
        GSD_WORKSTREAM="$ws" bash "$d/$s" "$@" 2>&1
  else
    env -u VF_WORKSTREAM -u VF_CONTEXT_WORKSTREAM -u VF_BOOTSTRAP_WORKSTREAM \
        -u VF_STATE_WORKSTREAM -u VF_WORKSTREAM_PLANNING_DIR -u VF_BOOTSTRAP_PLANNING_DIR \
        -u GSD_WORKSTREAM bash "$d/$s" "$@" 2>&1
  fi
}

etat_compartiment() { # <fichier> — un STATE.md complet, conforme à ADR-063
  cat > "$1" <<EOF
---
milestone: $2
current_phase: 1
status: in_progress
progress:
  completed_phases: 0
  completed_plans: 0
  total_plans: 1
---

Phase: 1 — compartiment $2
EOF
}

# <lab> <mode>   mode = piege-dossier | piege-racine | piege-etat | licite
batir_lab() {
  local lab="$1" mode="$2" cible="$1.cible"
  rm -rf "$lab" "$cible"
  mkdir -p "$lab/.planning/workstreams" "$cible"

  printf '# Projet fixture\n' > "$lab/.planning/PROJECT.md"
  printf '{ "workflow": {} }\n' > "$lab/.planning/config.json"
  printf '# Etat de la RACINE — ne doit jamais porter le marqueur.\n' > "$lab/.planning/STATE.md"

  # La CIBLE, hors du lab : c'est elle qui porte le marqueur.
  etat_compartiment "$cible/STATE.md" "$MARQUEUR"
  printf '# Feuille de route\n\n## Phase 1 : hors du lab\n' > "$cible/ROADMAP.md"

  case "$mode" in
    piege-dossier) ln -s "$cible" "$lab/.planning/workstreams/dev" ;;
    piege-racine)  rm -rf "$lab/.planning/workstreams"; ln -s "$cible.ws" "$lab/.planning/workstreams"
                   mkdir -p "$cible.ws/dev"; etat_compartiment "$cible.ws/dev/STATE.md" "$MARQUEUR" ;;
    piege-etat)    mkdir -p "$lab/.planning/workstreams/dev"
                   printf '# Feuille de route\n\n## Phase 1 : compartiment\n' > "$lab/.planning/workstreams/dev/ROADMAP.md"
                   ln -s "$cible/STATE.md" "$lab/.planning/workstreams/dev/STATE.md" ;;
    licite)        mkdir -p "$lab/.planning/workstreams/dev"
                   printf '# Feuille de route\n\n## Phase 1 : compartiment\n' > "$lab/.planning/workstreams/dev/ROADMAP.md"
                   etat_compartiment "$lab/.planning/workstreams/dev/STATE.md" "compartiment-licite" ;;
  esac

  git -C "$lab" init -q >/dev/null 2>&1
  git -C "$lab" add -A >/dev/null 2>&1
  git -C "$lab" -c user.email=ci@vibeflow.invalid -c user.name=CI -c commit.gpgsign=false \
      commit -q -m fixture >/dev/null 2>&1
}

# ---------------------------------------------------------------------------------------------
# A. ASSERTION DE CONSTRUCTION ET DE DISCRIMINANCE — avant toute mesure.
# ---------------------------------------------------------------------------------------------
SAIN="$TMP/scripts-sain"; poser_scripts "$SAIN"
LABP="$TMP/lab-piege"; batir_lab "$LABP" piege-dossier

a_ok=1
[ -L "$LABP/.planning/workstreams/dev" ] || { ko "A fixture piégée" "workstreams/dev n'est PAS un lien symbolique — le piège n'a pas été posé"; a_ok=0; }
case "$(cat "$LABP.cible/STATE.md" 2>/dev/null)" in
  *"$MARQUEUR"*) : ;;
  *) ko "A fixture piégée" "la CIBLE ne porte pas le marqueur — aucun refus mesuré ici ne prouverait quoi que ce soit"; a_ok=0 ;;
esac
case "$(cat "$LABP/.planning/STATE.md" 2>/dev/null)" in
  *"$MARQUEUR"*) ko "A fixture piégée" "la RACINE porte le marqueur — la fixture n'est PAS discriminante, un repli sur la racine passerait pour une fuite"; a_ok=0 ;;
esac
[ "$a_ok" -eq 1 ] && ok "A fixture piégée construite et discriminante : workstreams/dev est un lien hors du lab, le marqueur est dans la CIBLE et absent de la RACINE"

# ---------------------------------------------------------------------------------------------
# B. LES QUATRE GATES REFUSENT — sévérité par rôle, marqueur nulle part.
# ---------------------------------------------------------------------------------------------
# B1 — injecteur de contexte : fail-open (exit 0 TOUJOURS), la preuve porte donc sur la SORTIE.
rc=0; out="$(run_gate "$SAIN" planning-context.sh dev --path "$LABP/.planning")" || rc=$?
b1=1
[ "$rc" -eq 0 ] || { ko "B1 planning-context" "rc=$rc, attendu 0 (contrat fail-open d'un hook SessionStart)"; b1=0; }
case "$out" in *"$MARQUEUR"*) ko "B1 planning-context" "le marqueur de la CIBLE est INJECTÉ dans le contexte de session — la fuite est ouverte"; b1=0 ;; esac
case "$out" in *compartiment-lien-symbolique*) : ;; *) ko "B1 planning-context" "le refus n'est pas AUDIBLE : la raison « compartiment-lien-symbolique » n'apparaît pas — fail-open ne veut pas dire muet"; b1=0 ;; esac
[ "$b1" -eq 1 ] && ok "B1 planning-context : refus audible, exit 0 (fail-open intact), marqueur de la cible ABSENT du contexte injecté"

# B2 — gate de démarrage : même rôle d'injecteur.
rc=0; out="$(run_gate "$SAIN" check-dev-bootstrap.sh dev --path "$LABP")" || rc=$?
b2=1
case "$out" in *"$MARQUEUR"*) ko "B2 check-dev-bootstrap" "le marqueur de la CIBLE est réimprimé sur la sortie d'un hook SessionStart"; b2=0 ;; esac
case "$out" in *"refusé par la politique amont"*) : ;; *) ko "B2 check-dev-bootstrap" "le refus n'est pas audible dans la sortie"; b2=0 ;; esac
[ "$b2" -eq 1 ] && ok "B2 check-dev-bootstrap : refus audible, marqueur de la cible ABSENT (rc=$rc, fail-open par rôle)"

# B3 — gate de VÉRIFICATION : exit 2, « non vérifiable » (jamais un verdict sur le mauvais fichier).
rc=0; out="$(run_gate "$SAIN" check-state-integrity.sh dev --path "$LABP")" || rc=$?
b3=1
[ "$rc" -eq 2 ] || { ko "B3 check-state-integrity" "rc=$rc, attendu 2 (non vérifiable) — un verdict rendu ici porterait sur un fichier hors du lab"; b3=0; }
case "$out" in *"$MARQUEUR"*) ko "B3 check-state-integrity" "le marqueur de la CIBLE apparaît dans le diagnostic"; b3=0 ;; esac
case "$out" in *compartiment-lien-symbolique*) : ;; *) ko "B3 check-state-integrity" "la raison du refus n'est pas nommée"; b3=0 ;; esac
[ "$b3" -eq 1 ] && ok "B3 check-state-integrity : exit 2 « non vérifiable », raison nommée, marqueur ABSENT"

# B4 — gate de CONSTAT : exit 2 aussi (il n'a PAS pu regarder le compartiment), et surtout PAS 0 :
# ce 0 est le vert sur lequel les trois autres s'appuient.
rc=0; out="$(run_gate "$SAIN" check-workstream-pointer.sh dev --path "$LABP")" || rc=$?
b4=1
[ "$rc" -eq 2 ] || { ko "B4 check-workstream-pointer" "rc=$rc, attendu 2 — un exit 0 ici bénit la partition piégée"; b4=0; }
case "$out" in *"lien symbolique"*) : ;; *) ko "B4 check-workstream-pointer" "le refus ne nomme pas le lien symbolique"; b4=0 ;; esac
[ "$b4" -eq 1 ] && ok "B4 check-workstream-pointer : exit 2, refus de suivre nommé — la partition piégée n'est plus bénie « conforme »"

# ---------------------------------------------------------------------------------------------
# C. MUTATION — la garde retirée, la fuite doit RÉAPPARAÎTRE sur les quatre.
# ---------------------------------------------------------------------------------------------
MUTD="$TMP/scripts-mute"; poser_scripts "$MUTD"
cat > "$TMP/neutralise-garde.awk" <<'AWKEOF'
{
  if (index($0, "-lien-symbolique\"; return 2; }") > 0) {
    if (sub(/\[ "\$rc" -eq 2 \]/, "false")) { n++ }
  }
  print
}
END { print n+0 > "/dev/stderr" }
AWKEOF
# Le COMPTE de substitutions part sur stderr, le mutant sur stdout : c'est le compte qui rend le
# mutant opposable, `cmp` seul ne dirait pas QUELLE garde a été neutralisée.
NSUB="$(awk -f "$TMP/neutralise-garde.awk" "$POLICY" 2>&1 >"$MUTD/workstream-policy.sh")"

c_ok=1
if cmp -s "$MUTD/workstream-policy.sh" "$POLICY"; then
  ko "C mutation de la politique" "la mutation n'a RIEN changé (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
  c_ok=0
elif [ "${NSUB:-0}" -lt 3 ]; then
  ko "C mutation de la politique" "$NSUB substitution(s), plancher 3 (répertoire de compartiment, racine workstreams, fichier de compartiment) — une garde a été renommée et le mutant ne la vise plus"
  c_ok=0
elif ! bash -n "$MUTD/workstream-policy.sh" 2>/dev/null; then
  ko "C mutation de la politique" "le mutant n'est pas un script valide : il rougirait pour la mauvaise raison"
  c_ok=0
fi

if [ "$c_ok" -eq 1 ]; then
  fuites=0
  rc=0; out="$(run_gate "$MUTD" planning-context.sh dev --path "$LABP/.planning")" || rc=$?
  case "$out" in *"$MARQUEUR"*) fuites=$((fuites+1)) ;; esac
  rc=0; out="$(run_gate "$MUTD" check-dev-bootstrap.sh dev --path "$LABP")" || rc=$?
  case "$out" in *"$MARQUEUR"*) fuites=$((fuites+1)) ;; esac
  rc_si=0; out_si="$(run_gate "$MUTD" check-state-integrity.sh dev --path "$LABP")" || rc_si=$?
  case "$out_si" in *".planning/workstreams/dev/STATE.md"*) fuites=$((fuites+1)) ;; esac
  rc_wp=0; run_gate "$MUTD" check-workstream-pointer.sh dev --path "$LABP" >/dev/null 2>&1 || rc_wp=$?
  [ "$rc_wp" -eq 0 ] && fuites=$((fuites+1))

  if [ "$fuites" -eq 4 ]; then
    ok "C mutation ($NSUB gardes neutralisées) : les QUATRE gates refuient — marqueur réinjecté par les 2 hooks, verdict rendu sur le fichier hors lab (rc=$rc_si), partition rebénie conforme (rc=$rc_wp)"
  else
    ko "C mutation de la politique" "seulement $fuites/4 gates refuient sous mutation — la garde retirée, la fuite doit réapparaître partout ; un gate qui reste vert ici ne tient pas grâce à cette garde"
  fi
fi

# ---------------------------------------------------------------------------------------------
# D. CAS LICITE — un vrai répertoire reste vert à l'octet près.
# ---------------------------------------------------------------------------------------------
LABL="$TMP/lab-licite"; batir_lab "$LABL" licite
d_ok=1
rc=0; out="$(run_gate "$SAIN" planning-context.sh dev --path "$LABL/.planning")" || rc=$?
case "$out" in *'STATE.md du workstream `dev`'*) : ;; *) ko "D cas licite" "planning-context n'injecte plus l'état du compartiment — le correctif a cassé le cas nominal"; d_ok=0 ;; esac
case "$out" in *lien-symbolique*) ko "D cas licite" "planning-context refuse un compartiment parfaitement légitime"; d_ok=0 ;; esac
rc=0; run_gate "$SAIN" check-workstream-pointer.sh dev --path "$LABL" >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 0 ] || { ko "D cas licite" "check-workstream-pointer rc=$rc, attendu 0 (conforme) sur un vrai répertoire"; d_ok=0; }
rc=0; out="$(run_gate "$SAIN" check-state-integrity.sh dev --path "$LABL")" || rc=$?
[ "$rc" -eq 0 ] || { ko "D cas licite" "check-state-integrity rc=$rc, attendu 0 (conforme) sur un vrai compartiment"; d_ok=0; }
rc=0; out="$(run_gate "$SAIN" check-dev-bootstrap.sh dev --path "$LABL")" || rc=$?
case "$out" in *refusé*) ko "D cas licite" "check-dev-bootstrap refuse un compartiment légitime"; d_ok=0 ;; esac
[ "$d_ok" -eq 1 ] && ok "D cas licite : les quatre gates rendent leur verdict nominal sur un vrai répertoire — la garde ne coûte rien là où il n'y a rien à garder"

# ---------------------------------------------------------------------------------------------
# E. LES DEUX AUTRES SEGMENTS — `workstreams/` lui-même, et le FICHIER du compartiment.
# ---------------------------------------------------------------------------------------------
LABR="$TMP/lab-racine"; batir_lab "$LABR" piege-racine
e1=1
[ -L "$LABR/.planning/workstreams" ] || { ko "E1 racine workstreams" "le piège n'a pas été posé"; e1=0; }
rc=0; out="$(run_gate "$SAIN" check-workstream-pointer.sh dev --path "$LABR")" || rc=$?
[ "$rc" -eq 2 ] || { ko "E1 racine workstreams" "rc=$rc, attendu 2 — un `workstreams/` détourné détourne TOUS les compartiments d'un coup"; e1=0; }
rc=0; out="$(run_gate "$SAIN" planning-context.sh dev --path "$LABR/.planning")" || rc=$?
case "$out" in *"$MARQUEUR"*) ko "E1 racine workstreams" "le marqueur traverse par la racine workstreams/"; e1=0 ;; esac
[ "$e1" -eq 1 ] && ok 'E1 : `workstreams/` lui-même en lien symbolique est refusé — les deux segments du chemin sont contraints, pas seulement le dernier'

LABE="$TMP/lab-etat"; batir_lab "$LABE" piege-etat
e2=1
[ -L "$LABE/.planning/workstreams/dev/STATE.md" ] || { ko "E2 fichier du compartiment" "le piège n'a pas été posé"; e2=0; }
rc=0; out="$(run_gate "$SAIN" planning-context.sh dev --path "$LABE/.planning")" || rc=$?
case "$out" in *"$MARQUEUR"*) ko "E2 fichier du compartiment" "un compartiment LÉGITIME dont le STATE.md est un lien rejoue la fuite — fermer le répertoire en laissant le fichier ouvert, c'est verrouiller la porte et laisser la fenêtre"; e2=0 ;; esac
rc=0; out="$(run_gate "$SAIN" check-state-integrity.sh dev --path "$LABE")" || rc=$?
[ "$rc" -eq 2 ] || { ko "E2 fichier du compartiment" "check-state-integrity rc=$rc, attendu 2 — il vérifierait un fichier hors du lab"; e2=0; }
[ "$e2" -eq 1 ] && ok "E2 : un STATE.md de compartiment en lien symbolique est refusé aussi — le motif est fermé au niveau du fichier comme du répertoire"

# ---------------------------------------------------------------------------------------------
# F. LA CIBLE EST INTACTE — un refus qui écrirait dans la cible serait un autre défaut.
# ---------------------------------------------------------------------------------------------
empreinte_avant="$(cat "$LABP.cible/STATE.md")"
run_gate "$SAIN" planning-context.sh dev --path "$LABP/.planning" >/dev/null 2>&1
run_gate "$SAIN" check-dev-bootstrap.sh dev --path "$LABP" >/dev/null 2>&1
run_gate "$SAIN" check-state-integrity.sh dev --path "$LABP" >/dev/null 2>&1
run_gate "$SAIN" check-workstream-pointer.sh dev --path "$LABP" >/dev/null 2>&1
if [ "$empreinte_avant" = "$(cat "$LABP.cible/STATE.md")" ]; then
  ok "F cible INTACTE : les quatre refus n'ont ni lu-pour-réécrire ni modifié le fichier hors du lab"
else
  ko "F cible intacte" "le contenu de la cible a CHANGÉ après passage des gates"
fi

echo ""
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
