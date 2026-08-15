#!/usr/bin/env bash
# test-check-map-drift.sh — Suite de vérification de check-map-drift.sh (G3, plan 29-02).
#
# Un cas par comportement du bloc <behavior> du plan, dont le plancher anti-vert-à-vide et deux
# preuves par mutation attestées à l'octet (cmp -s, jamais diff). Fixtures git isolées via
# mktemp -d + git init, jamais sur le dépôt réel — même modèle que test-check-doc-drift.sh.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-map-drift.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# git_must — exécute une commande git de CONSTRUCTION DE FIXTURE et échoue BRUYAMMENT si elle
# rate (voir test-check-doc-drift.sh:24-30 pour le motif : une fixture à moitié construite produit
# un faux symptôme au moment de l'assertion, jamais la cause réelle).
git_must() { # <description> <git-args...>
  local what="$1"; shift
  local out rc
  out="$(git "$@" 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "  ✗ FIXTURE — $what a échoué (rc=$rc)" >&2
    echo "    commande : git $*" >&2
    [ -n "$out" ] && echo "    stderr   : $out" >&2
    echo "  == fixture non constructible — arrêt (aucune assertion n'aurait de sens) ==" >&2
    exit 1
  fi
}

mk_git_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  if ! git -C "$d" init -q -b main >/dev/null 2>&1; then
    git_must "git init (repli sans -b, git < 2.28)" -C "$d" init -q
  fi
  printf '%s' "$d"
}

# Écrit puis commit un fichier <dir>/<rel>, contenu = une ligne par argument restant.
commit_file() { # <dir> <rel> <content-line...>
  local d="$1" rel="$2"; shift 2
  mkdir -p "$(dirname "$d/$rel")"
  printf '%s\n' "$@" > "$d/$rel"
  git_must "add $rel" -C "$d" -c user.email=t@t -c user.name=t add "$rel"
  git_must "commit $rel" -C "$d" -c user.email=t@t -c user.name=t commit -q -m "add: $rel"
}

echo "== test-check-map-drift =="

# === P1-A — pointeur @chemin absent du disque → divergence nommant le chemin et la carte =========
D="$(mk_git_root p1a)"
commit_file "$D" "CLAUDE.md" "# root" "" "@docs/absent/" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_path=0; case "$out" in *"docs/absent"*) has_path=1 ;; esac
has_card=0; case "$out" in *"CLAUDE.md"*) has_card=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_path" -eq 1 ] && [ "$has_card" -eq 1 ]; then ok "P1-A pointeur @chemin absent → divergence nommant chemin+carte"; else ko "P1-A pointeur @chemin absent → divergence nommant chemin+carte" "rc=$rc out=[$out]"; fi

# === P1-A bis — chemin entre accents graves avec '/' absent du disque → divergence ================
D="$(mk_git_root p1abis)"
commit_file "$D" "CLAUDE.md" "# root" "" '`plugin/disparu/x.md`' ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_path=0; case "$out" in *"plugin/disparu/x.md"*) has_path=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_path" -eq 1 ]; then ok "P1-A bis chemin entre accents graves absent → divergence"; else ko "P1-A bis chemin entre accents graves absent → divergence" "rc=$rc out=[$out]"; fi

# === P1-B — sous-dossier de premier niveau suivi par git, cité par aucun token → divergence ========
D="$(mk_git_root p1b)"
commit_file "$D" "CLAUDE.md" "# root" "" "aucun pointeur ici" ""
commit_file "$D" "extra/file.txt" "hello"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_dir=0; case "$out" in *"extra"*) has_dir=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_dir" -eq 1 ]; then ok "P1-B sous-dossier non cité → divergence nommant le dossier"; else ko "P1-B sous-dossier non cité → divergence nommant le dossier" "rc=$rc out=[$out]"; fi

# === P1-clean — tous les pointeurs existent et tous les sous-dossiers sont cités → 0 divergence ====
D="$(mk_git_root p1clean)"
commit_file "$D" "docs/x.md" "content"
commit_file "$D" "CLAUDE.md" "# root" "" "@docs/" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_zero=0; case "$out" in *"0 divergence"*"1 carte"*) has_zero=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_zero" -eq 1 ]; then ok "P1-clean → 0 divergence, compteur de cartes balayées ≥ 1"; else ko "P1-clean → 0 divergence, compteur de cartes balayées ≥ 1" "rc=$rc out=[$out]"; fi

# === Plancher — cible sans aucune carte (dépôt git sans CLAUDE.md/index) → NON VÉRIFIABLE ==========
D="$(mk_git_root plancher-sanscarte)"
commit_file "$D" "readme.txt" "hi"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_nv=0; case "$out" in *"NON VÉRIFIABLE"*) has_nv=1 ;; esac
has_faux_vert=0; case "$out" in *"0 divergence"*) has_faux_vert=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_nv" -eq 1 ] && [ "$has_faux_vert" -eq 0 ]; then ok "Plancher (ICMD-05) — sans carte → NON VÉRIFIABLE, jamais '0 divergence'"; else ko "Plancher (ICMD-05) — sans carte → NON VÉRIFIABLE, jamais '0 divergence'" "rc=$rc out=[$out]"; fi

# === Plancher — cible inexistante → NON VÉRIFIABLE, exit 3 =========================================
out="$(bash "$SCRIPT" --path "$TMP/n-existe-pas-du-tout" 2>/dev/null)"; rc=$?
has_nv=0; case "$out" in *"NON VÉRIFIABLE"*) has_nv=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_nv" -eq 1 ]; then ok "Plancher — cible inexistante → NON VÉRIFIABLE, exit 3"; else ko "Plancher — cible inexistante → NON VÉRIFIABLE, exit 3" "rc=$rc out=[$out]"; fi

# === Plancher — cible hors d'un arbre de travail git → NON VÉRIFIABLE, exit 3 ======================
D="$(mktemp -d)"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_nv=0; case "$out" in *"NON VÉRIFIABLE"*) has_nv=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_nv" -eq 1 ]; then ok "Plancher — hors arbre de travail git → NON VÉRIFIABLE, exit 3"; else ko "Plancher — hors arbre de travail git → NON VÉRIFIABLE, exit 3" "rc=$rc out=[$out]"; fi

# === Ignorés (1/3) — dossier point-préfixé suivi par git n'est jamais réclamé en P1-B ==============
D="$(mk_git_root ignore-dot)"
commit_file "$D" ".hidden/file.txt" "x"
commit_file "$D" "CLAUDE.md" "# root" "" "rien à pointer" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ]; then ok "Ignorés — dossier point-préfixé jamais réclamé"; else ko "Ignorés — dossier point-préfixé jamais réclamé" "rc=$rc out=[$out]"; fi

# === Ignorés (2/3) — node_modules suivi par git n'est jamais réclamé en P1-B ========================
D="$(mk_git_root ignore-nodemod)"
commit_file "$D" "node_modules/pkg/file.txt" "x"
commit_file "$D" "CLAUDE.md" "# root" "" "rien à pointer" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ]; then ok "Ignorés — node_modules jamais réclamé"; else ko "Ignorés — node_modules jamais réclamé" "rc=$rc out=[$out]"; fi

# === Ignorés (3/3) — accents graves SANS '/' = identifiant, jamais un chemin (aucune divergence) ===
D="$(mk_git_root ignore-backtick)"
commit_file "$D" "CLAUDE.md" "# root" "" 'identifiant `foo` sans separateur' ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ]; then ok "Ignorés — accents graves sans '/' = identifiant, jamais un chemin"; else ko "Ignorés — accents graves sans '/' = identifiant, jamais un chemin" "rc=$rc out=[$out]"; fi

# === Grammaire d'exit — argument inconnu → 64, rien sur stdout =====================================
errfile="$TMP/err-arg.err"
out="$(bash "$SCRIPT" --argument-inexistant 2>"$errfile")"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 64 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "argument inconnu → exit 64, stdout vide, stderr non vide"; else ko "argument inconnu → exit 64, stdout vide, stderr non vide" "rc=$rc out=[$out] err=[$err]"; fi

# === Grammaire d'exit — --hook + --quiet ensemble → 64 =============================================
bash "$SCRIPT" --hook --quiet >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "--hook + --quiet ensemble → exit 64"; else ko "--hook + --quiet ensemble → exit 64" "rc=$rc"; fi

# === Grammaire d'exit — --path sans valeur → 64 =====================================================
bash "$SCRIPT" --path >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "--path sans valeur → exit 64"; else ko "--path sans valeur → exit 64" "rc=$rc"; fi

# === Grammaire d'exit — --map sans valeur → 64 ======================================================
bash "$SCRIPT" --map >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "--map sans valeur → exit 64"; else ko "--map sans valeur → exit 64" "rc=$rc"; fi

# === --help → exit 0, sortie non vide, ≥ 15 lignes ==================================================
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
nlines="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
if [ "$rc" -eq 0 ] && [ -n "$out" ] && [ "$nlines" -ge 15 ]; then ok "--help → exit 0, ≥ 15 lignes"; else ko "--help → exit 0, ≥ 15 lignes" "rc=$rc nlines=$nlines"; fi

# === bash -n passe sur le script (syntaxe) ==========================================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "bash -n passe sur check-map-drift.sh"; else ko "bash -n passe sur check-map-drift.sh" "syntax error"; fi

# === P2-A — cible *.md citée par l'index absente du dossier → divergence nommant index + cible =====
D="$(mk_git_root p2a)"
commit_file "$D" "refs/_index.md" "# Index" "" "[disparu.md](disparu.md)" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_entry=0; case "$out" in *"disparu.md"*) has_entry=1 ;; esac
has_card=0; case "$out" in *"_index.md"*) has_card=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_entry" -eq 1 ] && [ "$has_card" -eq 1 ]; then ok "P2-A cible citée absente du dossier → divergence"; else ko "P2-A cible citée absente du dossier → divergence" "rc=$rc out=[$out]"; fi

# === P2-B — fichier .md suivi par git dans le dossier, cité nulle part → divergence ================
D="$(mk_git_root p2b)"
commit_file "$D" "refs/_index.md" "# Index" "" "(rien de cite ici)" ""
commit_file "$D" "refs/orphan.md" "orphan"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_orphan=0; case "$out" in *"orphan.md"*) has_orphan=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_orphan" -eq 1 ]; then ok "P2-B fichier .md non cité → divergence nommant le fichier"; else ko "P2-B fichier .md non cité → divergence nommant le fichier" "rc=$rc out=[$out]"; fi

# === P2-self — l'index lui-même n'est jamais compté comme non cité =================================
D="$(mk_git_root p2self)"
commit_file "$D" "refs/_index.md" "# Index" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_zero=0; case "$out" in *"0 divergence"*) has_zero=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_zero" -eq 1 ]; then ok "P2-self — l'index ne se compte jamais lui-même"; else ko "P2-self — l'index ne se compte jamais lui-même" "rc=$rc out=[$out]"; fi

# === P2-non-récursif — un .md d'un sous-dossier de l'index n'est pas compté ========================
D="$(mk_git_root p2nonrec)"
commit_file "$D" "refs/_index.md" "# Index" ""
commit_file "$D" "refs/sub/nested.md" "nested"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_zero=0; case "$out" in *"0 divergence"*) has_zero=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_zero" -eq 1 ]; then ok "P2-non-récursif — .md d'un sous-dossier non compté"; else ko "P2-non-récursif — .md d'un sous-dossier non compté" "rc=$rc out=[$out]"; fi

# === P2-absent — dossier sans fichier d'index n'est pas une carte (pas de divergence, pas de +1) ===
D="$(mk_git_root p2absent)"
commit_file "$D" "refs/onlyfile.md" "x"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_nv=0; case "$out" in *"NON VÉRIFIABLE"*) has_nv=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_nv" -eq 1 ]; then ok "P2-absent — dossier sans index n'est pas une carte"; else ko "P2-absent — dossier sans index n'est pas une carte" "rc=$rc out=[$out]"; fi

# === P2-B-suffix (correctif MAJEUR) — comparaison par SUFFIXE de basename interdite : un fichier
# top-level 'refs/orphan.md' non cité ne doit JAMAIS être confondu avec l'entrée 'sub/orphan.md'
# citée (même basename). D'abord rouge sur le code d'avant correctif (comparaison `*"$base"`) :
# rc attendu 3 ('0 divergence' — refs/orphan.md manqué), corrigé rc attendu 0 avec refs/orphan.md
# nommé. Reproduit indépendamment par revue ET audit — cf. mandat de correction ciblée exec-02.
D="$(mk_git_root p2bsuffix)"
commit_file "$D" "refs/_index.md" "# Index" "" "[sub/orphan.md](sub/orphan.md)" ""
commit_file "$D" "refs/orphan.md" "top-level orphan, jamais cité"
commit_file "$D" "refs/sub/orphan.md" "cité par l'index"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_toplevel=0; case "$out" in *"refs/orphan.md"*) has_toplevel=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_toplevel" -eq 1 ]; then ok "P2-B-suffix — refs/orphan.md non cité distingué de refs/sub/orphan.md cité (pas de match par suffixe de basename)"; else ko "P2-B-suffix — refs/orphan.md non cité distingué de refs/sub/orphan.md cité (pas de match par suffixe de basename)" "rc=$rc out=[$out]"; fi

# === P1-A-absolu (correctif MINEUR) — token @/chemin/absolu ignoré, jamais un faux positif =========
# La cible absolue existe RÉELLEMENT sur le disque (hors du repo, sous $TMP) : avant correctif,
# normalize_token laissait le '/' de tête et $ROOT/$tok formait un chemin composite qui n'existe
# jamais → divergence signalée à tort. Après correctif, le token absolu est ignoré → 0 divergence.
D="$(mk_git_root p1absolu)"
ABS_DIR="$TMP/hors-repo-p1absolu"
mkdir -p "$ABS_DIR"
printf 'x' > "$ABS_DIR/reel.md"
commit_file "$D" "CLAUDE.md" "# root" "" "@${ABS_DIR}/reel.md" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_zero=0; case "$out" in *"0 divergence"*) has_zero=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_zero" -eq 1 ]; then ok "P1-A-absolu — token @/chemin/absolu ignoré, jamais de faux positif sur une cible pourtant réelle"; else ko "P1-A-absolu — token @/chemin/absolu ignoré, jamais de faux positif sur une cible pourtant réelle" "rc=$rc out=[$out]"; fi

# === Robustesse (correctif MEDIUM) — nom de fichier à ESPACE suivi par git → détecté sans crash ====
D="$(mk_git_root robustesse-espace)"
commit_file "$D" "refs/_index.md" "# Index" "" "(rien de cite ici)" ""
commit_file "$D" "refs/un nom avec espace.md" "content"
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_espace=0; case "$out" in *"un nom avec espace.md"*) has_espace=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_espace" -eq 1 ]; then ok "Robustesse — nom de fichier à espace détecté sans crash"; else ko "Robustesse — nom de fichier à espace détecté sans crash" "rc=$rc out=[$out]"; fi

# === Robustesse (correctif MEDIUM) — nom à TIRET INITIAL → détecté sans crash de basename ==========
# Avant correctif, les 3 sites `basename "$f"` cassaient sur un nom commençant par '-'
# ('basename: illegal option -- ...' en stderr) sur un dépôt cloné hostile ; le verdict final
# restait correct mais la robustesse T-29-02-02 (mitigation) n'était pas réellement prouvée.
#
# Le fixture DOIT placer le fichier à la RACINE du dépôt de test — 'refs/-orphelin-tiret.md'
# (utilisé au tour 1) ne reproduit rien : l'argument passé à basename commence par 'r', jamais
# par '-'. Preuve rejouée contre le pré-fix b0346ed (tour 2, finding 2) :
#   - fixture 'refs/-orphelin-tiret.md' contre b0346ed → sortie identique au post-fix, AUCUN
#     'basename: illegal option' sur stderr (le crash ne se produit pas, quel que soit le code).
#   - fixture '-orphelin-tiret.md' À LA RACINE contre b0346ed → 3x 'basename: illegal option --
#     o' sur stderr (un par site basename), silence total en post-fix (ce script).
D="$(mk_git_root robustesse-tiret)"
commit_file "$D" "_index.md" "# Index" "" "(rien de cite ici)" ""
commit_file "$D" "./-orphelin-tiret.md" "content"
out="$(bash "$SCRIPT" --path "$D" 2>&1)"; rc=$?
has_tiret=0; case "$out" in *"-orphelin-tiret.md"*) has_tiret=1 ;; esac
has_illegal=0; case "$out" in *"illegal option"*) has_illegal=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_tiret" -eq 1 ] && [ "$has_illegal" -eq 0 ]; then ok "Robustesse — nom de fichier à tiret initial (racine du dépôt) détecté sans crash de basename"; else ko "Robustesse — nom de fichier à tiret initial (racine du dépôt) détecté sans crash de basename" "rc=$rc out=[$out]"; fi

# === Robustesse — citation d'index avec './' de tête reconnue (correctif tour 2, finding 1) ========
# En remplaçant le match de suffixe de basename par une comparaison de chemins résolus (23cb5ad),
# une régression symétrique était introduite : 'target_rel' concaténait 'entry' brut sans retirer
# un './' de tête, alors que p2_sens_a tolérait ce même './' par construction (-e résout via le
# système de fichiers, pas par égalité de chaîne). D'abord rouge sur 23cb5ad (avant ce correctif) :
# rc attendu 0 avec 'a.md' faussement signalé comme non cité ; corrigé rc attendu 3 (0 divergence).
D="$(mk_git_root p2b-dotslash)"
commit_file "$D" "a.md" "content"
commit_file "$D" "_index.md" "# Index" "" "[a](./a.md)" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_zero=0; case "$out" in *"0 divergence"*) has_zero=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_zero" -eq 1 ]; then ok "P2-B dot-slash — citation './a.md' reconnue comme couvrant a.md, jamais un faux positif"; else ko "P2-B dot-slash — citation './a.md' reconnue comme couvrant a.md, jamais un faux positif" "rc=$rc out=[$out]"; fi

# === Table — normalize_path() couvre la CLASSE des formes d'écriture équivalentes (exec-02 tour 3)
# Récidive constatée sur 3 tours (suffixe de basename tour 0, chemin strict tour 1, strip './' à
# un seul niveau tour 2) : chaque correctif traitait le cas nommé par le rapport et laissait tomber
# son voisin immédiat. La fonction est extraite du script réel par awk (jamais recopiée à la main —
# une copie divergerait silencieusement de l'implémentation testée) puis évaluée dans ce shell.
NP_FN="$(awk '/^normalize_path\(\) \{/{f=1} f{print; if (/^}/) exit}' "$SCRIPT")"
eval "$NP_FN"
if [ "$(type -t normalize_path 2>/dev/null)" != "function" ]; then
  echo "  ✗ FIXTURE — extraction de normalize_path() a échoué (rien à tester)" >&2
  exit 1
fi

# forme d'écriture | attendu | raison si non trivial
np_case() { # <label> <input> <expected>
  local label="$1" input="$2" expected="$3" got
  got="$(normalize_path "$input")"
  if [ "$got" = "$expected" ]; then
    ok "normalize_path — $label : '$input' -> '$expected'"
  else
    ko "normalize_path — $label : '$input' -> '$expected'" "obtenu='$got'"
  fi
}

np_case "forme nue"                       "a.md"                    "a.md"
np_case "./ de tête"                      "./a.md"                  "a.md"
np_case ".// de tête (tour 2, finding 1)" ".//a.md"                 "a.md"
np_case "./ répété"                       "././a.md"                "a.md"
np_case "// de tête"                      "//a.md"                  "a.md"
np_case "sous-dossier nu"                 "sub/a.md"                "sub/a.md"
np_case "sous-dossier, ./ de tête"        "./sub/a.md"               "sub/a.md"
np_case "sous-dossier, // interne"        "sub//a.md"               "sub/a.md"
np_case "espace"                          "nom avec espace.md"      "nom avec espace.md"
np_case "tiret initial"                   "-tiret.md"               "-tiret.md"
np_case "%, \$, & littéraux"              'a%b$c&d.md'              'a%b$c&d.md'
np_case "/ final"                         "a.md/"                   "a.md"
np_case "../ — NON RÉSOLU PAR CHOIX (ADR-031 : jamais de résolution hors \$ROOT)" "../a.md" "../a.md"

# === Table — attestation du rouge AVANT (86c3b0c, tour 2) vs APRÈS (ce script, tour 3) =============
# 86c3b0c est le commit du tour 2 : il strip un seul './' de tête mais ne squeeze jamais les '/'
# redondants ni ne boucle sur les './' répétés. Chaque forme ci-dessous DOIT changer de verdict.
REPO_ROOT="$(git -C "$(dirname "$SCRIPT")" rev-parse --show-toplevel 2>/dev/null)"
OLD_SCRIPT="$TMP/old_check_map_drift_86c3b0c.sh"
if [ -n "$REPO_ROOT" ] && git -C "$REPO_ROOT" show 86c3b0c:plugin/conductor/scripts/check-map-drift.sh > "$OLD_SCRIPT" 2>/dev/null; then
  attest_form() { # <label> <citation-form>
    local label="$1" form="$2" D out_old rc_old out_new rc_new
    D="$(mk_git_root "attest-$(echo "$label" | tr -c 'a-zA-Z0-9' '-')")"
    commit_file "$D" "a.md" "content"
    commit_file "$D" "_index.md" "# Index" "" "[a]($form)" ""
    out_old="$(bash "$OLD_SCRIPT" --path "$D" 2>/dev/null)"; rc_old=$?
    out_new="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc_new=$?
    # attendu : AVANT rc=0 (faux positif — 'a.md' signalé à tort non cité), APRÈS rc=3 (0 divergence).
    if [ "$rc_old" -eq 0 ] && [ "$rc_new" -eq 3 ]; then
      ok "attestation rouge->vert — $label ('$form') : avant rc=0 (faux positif), après rc=3 (corrigé)"
    else
      ko "attestation rouge->vert — $label ('$form')" "avant rc=$rc_old [$out_old] / après rc=$rc_new [$out_new]"
    fi
  }
  attest_form "point-slash double"   ".//a.md"
  attest_form "point-slash repete"   "././a.md"
  attest_form "slash-double tete"    "//a.md"
else
  ko "attestation rouge->vert (86c3b0c)" "commit 86c3b0c introuvable dans ce dépôt — preuve non rejouable"
fi

# === Table générative — fermeture de la CLASSE par PRODUIT CARTÉSIEN, pas par énumération (tour 4)
# Quatre tours d'affilée où une liste de cas NOMMÉS a laissé passer une forme absente de la liste
# (mandat exec-02 tour 4, dernier défaut : '//./a.md' -> './a.md' au lieu de 'a.md', deux passes
# indépendantes squeeze/strip). Cette table construit le PRODUIT de préfixes de tête x corps de
# chemin et vérifie deux propriétés qui ferment la classe sur CHAQUE combinaison générée, jamais
# une liste figée : idempotence (normalize_path(normalize_path(x)) == normalize_path(x)) et égalité
# à la forme canonique attendue.
body_canon() { # <corps-brut> -> forme canonique attendue du corps SEUL (sans préfixe)
  case "$1" in
    "sub//a.md") printf '%s' "sub/a.md" ;;
    *) printf '%s' "$1" ;;
  esac
}
GEN_PREFIXES=("" "." "/" "//" "./" ".//" "/./" "//./" "././")
GEN_BODIES=("a.md" "sub/a.md" "sub//a.md" "nom avec espace.md" "-tiret.md")
gen_run() { # <fn-normalize> -> imprime le nombre d'échecs (idempotence OU canon) sur stdout
  local fail=0 pfx body form once twice canon expected
  for pfx in "${GEN_PREFIXES[@]}"; do
    for body in "${GEN_BODIES[@]}"; do
      form="${pfx}${body}"
      once="$("$1" "$form")"
      twice="$("$1" "$once")"
      canon="$(body_canon "$body")"
      if [ "$pfx" = "." ]; then expected=".${canon}"; else expected="$canon"; fi
      if [ "$once" != "$twice" ] || [ "$once" != "$expected" ]; then fail=$((fail + 1)); fi
    done
  done
  printf '%s' "$fail"
}
GEN_TOTAL=$(( ${#GEN_PREFIXES[@]} * ${#GEN_BODIES[@]} ))
GEN_FAIL_AFTER="$(gen_run normalize_path)"
if [ "$GEN_FAIL_AFTER" -eq 0 ]; then
  ok "génératif — $GEN_TOTAL combinaisons (9 préfixes x 5 corps), idempotence + forme canonique closes sur toutes"
else
  ko "génératif — $GEN_TOTAL combinaisons" "$GEN_FAIL_AFTER échec(s) — voir gen_run pour le détail"
fi

# === Attestation génération AVANT (c7b35f3, deux passes indépendantes) vs APRÈS (ce script) ========
OLD3_SCRIPT="$TMP/old_check_map_drift_c7b35f3.sh"
if [ -n "$REPO_ROOT" ] && git -C "$REPO_ROOT" show c7b35f3:plugin/conductor/scripts/check-map-drift.sh > "$OLD3_SCRIPT" 2>/dev/null; then
  OLD3_FN="$(awk '/^normalize_path\(\) \{/{f=1} f{print; if (/^}/) exit}' "$OLD3_SCRIPT")"
  normalize_path_old3() { :; }
  eval "$(printf '%s' "$OLD3_FN" | sed '1s/^normalize_path/normalize_path_old3/')"
  GEN_FAIL_BEFORE="$(gen_run normalize_path_old3)"
  if [ "$GEN_FAIL_BEFORE" -gt 0 ] && [ "$GEN_FAIL_AFTER" -eq 0 ]; then
    ok "attestation génération AVANT/APRÈS (c7b35f3) — $GEN_FAIL_BEFORE/$GEN_TOTAL échouaient avant, 0 après"
  else
    ko "attestation génération AVANT/APRÈS (c7b35f3)" "avant=$GEN_FAIL_BEFORE après=$GEN_FAIL_AFTER sur $GEN_TOTAL"
  fi
else
  ko "attestation génération AVANT/APRÈS (c7b35f3)" "commit c7b35f3 introuvable dans ce dépôt — preuve non rejouable"
fi

# === Cumul — une carte P1 et une carte P2, toutes deux propres → compteur de cartes balayées = 2 ===
D="$(mk_git_root cumul)"
commit_file "$D" "docs/x.md" "y"
commit_file "$D" "CLAUDE.md" "# root" "" "@docs/" "" "@refs/" ""
commit_file "$D" "refs/_index.md" "# Index" ""
out="$(bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
has_deux="0"; case "$out" in *"sur 2 carte"*) has_deux=1 ;; esac
has_zero=0; case "$out" in *"0 divergence"*) has_zero=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has_deux" -eq 1 ] && [ "$has_zero" -eq 1 ]; then ok "Cumul — carte P1 + carte P2 → 2 cartes balayées, 0 divergence"; else ko "Cumul — carte P1 + carte P2 → 2 cartes balayées, 0 divergence" "rc=$rc out=[$out]"; fi

# === Mutation P1 — neutraliser le sens B de P1 rend le cas P1-B rouge ==============================
cp "$SCRIPT" "$TMP/orig_backup_p1.sh"
sed 's@^.*# P1-SENS-B-CALL@  : # mutated (neutralized P1 sens B)@' "$SCRIPT" > "$TMP/mutated_p1.sh"
D="$(mk_git_root mutation-p1)"
commit_file "$D" "CLAUDE.md" "# root" "" "aucun pointeur ici" ""
commit_file "$D" "extra/file.txt" "hello"
out_mut="$(bash "$TMP/mutated_p1.sh" --path "$D" 2>/dev/null)"; rc_mut=$?
# non muté : rc=0 (divergence détectée, cas P1-B). Muté (sens B neutralisé) : la divergence
# disparaît → 0 divergence sur 1 carte balayée → exit 3, jamais 0.
if [ "$rc_mut" -eq 3 ]; then ok "mutation P1 (sens B neutralisé) — cas P1-B devient rouge (divergence non détectée)"; else ko "mutation P1 (sens B neutralisé) — cas P1-B devient rouge (divergence non détectée)" "rc_mut=$rc_mut out=[$out_mut]"; fi
if cmp -s "$SCRIPT" "$TMP/orig_backup_p1.sh"; then ok "mutation P1 — script original intact après mutation (cmp -s)"; else ko "mutation P1 — script original intact après mutation (cmp -s)" "cmp a signalé une différence"; fi

# === Mutation P2 — neutraliser le sens A de P2 rend le cas P2-A rouge ==============================
cp "$SCRIPT" "$TMP/orig_backup_p2.sh"
sed 's@^.*# P2-SENS-A-CALL@  : # mutated (neutralized P2 sens A)@' "$SCRIPT" > "$TMP/mutated_p2.sh"
D="$(mk_git_root mutation-p2)"
commit_file "$D" "refs/_index.md" "# Index" "" "[disparu.md](disparu.md)" ""
out_mut="$(bash "$TMP/mutated_p2.sh" --path "$D" 2>/dev/null)"; rc_mut=$?
# non muté : rc=0 (divergence détectée, cas P2-A). Muté (sens A neutralisé) : plus aucune
# divergence détectée → exit 3.
if [ "$rc_mut" -eq 3 ]; then ok "mutation P2 (sens A neutralisé) — cas P2-A devient rouge (divergence non détectée)"; else ko "mutation P2 (sens A neutralisé) — cas P2-A devient rouge (divergence non détectée)" "rc_mut=$rc_mut out=[$out_mut]"; fi
if cmp -s "$SCRIPT" "$TMP/orig_backup_p2.sh"; then ok "mutation P2 — script original intact après mutation (cmp -s)"; else ko "mutation P2 — script original intact après mutation (cmp -s)" "cmp a signalé une différence"; fi

# === Bornes — --help cite les 4 motifs de non-couverture + ADR-031 + ADR-055 =======================
out="$(bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
n_bornes=0; case "$out" in *"Bornes"*) n_bornes=1 ;; esac
has_a=0; case "$out" in *"skills:"*) has_a=1 ;; esac
has_b=0; case "$out" in *"DAG de mission"*) has_b=1 ;; esac
has_c=0; case "$out" in *".planning/"*) has_c=1 ;; esac
has_d=0; case "$out" in *"QUALITÉ"*) has_d=1 ;; esac
has_adr031=0; case "$out" in *"ADR-031"*) has_adr031=1 ;; esac
has_adr055=0; case "$out" in *"ADR-055"*) has_adr055=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$n_bornes" -eq 1 ] && [ "$has_a" -eq 1 ] && [ "$has_b" -eq 1 ] && [ "$has_c" -eq 1 ] && [ "$has_d" -eq 1 ] && [ "$has_adr031" -eq 1 ] && [ "$has_adr055" -eq 1 ]; then
  ok "Bornes — --help cite les 4 motifs de non-couverture, ADR-031 et ADR-055"
else
  ko "Bornes — --help cite les 4 motifs de non-couverture, ADR-031 et ADR-055" "n_bornes=$n_bornes a=$has_a b=$has_b c=$has_c d=$has_d adr031=$has_adr031 adr055=$has_adr055"
fi

# === Garde — sur les fixtures déjà exercées, les seuls codes de sortie observés sont 0, 3, 64 =======
RC_SEEN=""
D="$(mk_git_root garde-clean)"; commit_file "$D" "docs/x.md" "y"; commit_file "$D" "CLAUDE.md" "# root" "" "@docs/" ""
bash "$SCRIPT" --path "$D" >/dev/null 2>&1; RC_SEEN="$RC_SEEN $?"
D="$(mk_git_root garde-div)"; commit_file "$D" "CLAUDE.md" "# root" "" "@docs/absent" ""
bash "$SCRIPT" --path "$D" >/dev/null 2>&1; RC_SEEN="$RC_SEEN $?"
D="$(mk_git_root garde-nv)"; commit_file "$D" "readme.txt" "x"
bash "$SCRIPT" --path "$D" >/dev/null 2>&1; RC_SEEN="$RC_SEEN $?"
bash "$SCRIPT" --argument-inexistant >/dev/null 2>&1; RC_SEEN="$RC_SEEN $?"
bash "$SCRIPT" --hook --quiet >/dev/null 2>&1; RC_SEEN="$RC_SEEN $?"
all_ok=1
for code in $RC_SEEN; do
  case "$code" in
    0|3|64) : ;;
    *) all_ok=0 ;;
  esac
done
if [ "$all_ok" -eq 1 ]; then ok "Garde — seuls 0/3/64 observés sur les fixtures (code réservé 1 jamais rendu)"; else ko "Garde — seuls 0/3/64 observés sur les fixtures (code réservé 1 jamais rendu)" "codes vus=[$RC_SEEN]"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
