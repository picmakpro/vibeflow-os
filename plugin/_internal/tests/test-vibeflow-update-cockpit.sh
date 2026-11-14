#!/usr/bin/env bash
# test-vibeflow-update-cockpit.sh — pose du module cockpit par l'engine (67-06, CKPT-10 ; T-67-32..36).
#   I1 scope project : pose, lanceur posé → serveur, GET /, .gitignore de sortie, stop
#   I2 scope user (HOME jetable) · I3 scope local (.gitignore du lab, check-ignore)
#   I4 binaires (.woff2, .png) identiques à l'octet dans les trois scopes, témoin d'altération
#   I4b fichiers texte (arbre du moteur + scripts) identiques à l'octet dans les trois scopes (sans --target)
#   I5 seconde pose sans écart · I6 aucun SKILL.md du moteur, aucun nom amont dans un chemin posé
#   I9 mod vf-signal (68-04, P68-D-11, D-13) : un fragment réduit à `modules` sous cockpit/hooks/ fait échouer l'install, le vrai cache s'installe
#      sans aucun .ts/.tsx ni dossier signal/ sous la cible (le mod est lu depuis le cache du plugin, jamais posé)
#   I7 vrai ~/.claude inchangé · I8 sous --target : seule la réécriture de `.claude/` a lieu, marque blanche tenue
# Choix : sans --target l'engine copie à l'octet (texte comme binaire) ; sous --target il réécrit par conception les
# `.claude/` des fichiers texte vers la cible, donc la preuve devient « seule cette réécriture a eu lieu » + le rendu
# reste sans le nom amont. Suite sous _internal/tests/ : elle pilote l'engine, qui n'existe que dans le dépôt de
# distribution (même choix que test-vibeflow-update-divergence.sh). VF_COCKPIT_TEST_ENGINE : engine de substitution
# (mutant). Exit 1 au premier KO compté ; aucun cas exécuté → exit 1.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="${VF_COCKPIT_TEST_ENGINE:-$INTERNAL_DIR/vibeflow-update.sh}"
SRC="$REPO/cockpit"; MOTEUR_SRC="$SRC/skills/cockpit-moteur"
pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
AMONT="floor""plan" # le nom du produit amont n'est jamais écrit d'un bloc dans ce fichier

# prepare_module : recopié de test-vibeflow-update.sh (cache jetable portant un module du dépôt)
prepare_module() { local cache="$1" mod="$2"; mkdir -p "$cache/$mod"; cp -r "$REPO/$mod/." "$cache/$mod/" 2>/dev/null || return 1; [ -f "$cache/$mod/VERSION" ] || return 1; }

# Empreinte des seuls fichiers du cockpit (nom contenant « cockpit ») du vrai ~/.claude : une session concurrente qui ajoute un agent ou une
# règle ne fait plus échouer I7 ; ce que le test garde, c'est qu'aucun fichier du cockpit n'est posé ni retiré dans le vrai répertoire.
snapshot_home_claude() { find "$HOME/.claude/agents" "$HOME/.claude/skills" "$HOME/.claude/scripts" "$HOME/.claude/rules" "$HOME/.claude/commands" -iname '*cockpit*' 2>/dev/null | sort | cksum | tr -d ' '; }
HOME_BEFORE=$(snapshot_home_claude)

WORK="$(mktemp -d)"; CACHE="$WORK/cache"; FH="$WORK/home"; mkdir -p "$FH"
trap 'for l in "$WORK"/lab-*; do [ -d "$l" ] && (cd "$l" && HOME="$FH" node "$l/.claude/scripts/vf-cockpit.mjs" stop >/dev/null 2>&1); done; rm -rf "$WORK"' EXIT
prepare_module "$CACHE" cockpit || { echo "cache de test impossible"; exit 1; }
echo "== test-vibeflow-update-cockpit (engine: $INSTALLER) =="

mklab() { # $1 = nom ; lab GSD jetable, dépôt git
  local d="$WORK/lab-$1"; mkdir -p "$d/src" "$d/.planning/phases/01-x"
  printf 'export const u = () => 1;\n' > "$d/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$d/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$d/.planning/phases/01-x/01-01-PLAN.md"
  git -C "$d" init -q 2>/dev/null; echo "$d"
}
pose() { # $1 scope, $2 lab, reste = options de l'engine avant le verbe
  local scope="$1" lab="$2"; shift 2
  (cd "$lab" && HOME="$FH" VF_SCOPE="$scope" VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" "$@" install cockpit >"$WORK/pose.out" 2>&1)
}
get_code() { node -e 'require("http").get({host:"127.0.0.1",port:+process.argv[1],path:process.argv[2],headers:{Host:"127.0.0.1:"+process.argv[1]}},r=>{console.log(r.statusCode);r.resume()}).on("error",()=>console.log("erreur"))' "$1" "$2"; }
liste() { (cd "$1" && find . -type f | LC_ALL=C sort); } # chemins relatifs triés
empreintes() { (cd "$1" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done); }

LP=$(mklab project); LU=$(mklab user); LL=$(mklab local)
RP="$LP/.claude"; RU="$FH/.claude"; RL="$LL/.claude"

# ---- I1 : scope project, de bout en bout --------------------------------------------------------
pose project "$LP" || ko "I1 : l'engine a échoué — $(tail -2 "$WORK/pose.out")"
miss=0
for f in skills/vf-cockpit/SKILL.md skills/vf-cockpit/agents/openai.yaml skills/cockpit-moteur/VENDORED.txt scripts/vf-cockpit.mjs scripts/vf-cockpit-build.mjs scripts/vf-cockpit-interface.json; do
  [ -f "$RP/$f" ] || { ko "I1 : $f non posé"; miss=1; }
done
PORT=$((20000 + RANDOM % 20000))
OUT=$(cd "$LP" && HOME="$FH" node .claude/scripts/vf-cockpit.mjs open --no-open --port "$PORT" 2>&1); RC=$?
URL=$(printf '%s' "$OUT" | grep -o 'http://127\.0\.0\.1:[0-9]*' | head -1)
[ "$RC" -eq 0 ] && [ -n "$URL" ] || { ko "I1 : open rc=$RC sans adresse — $OUT"; miss=1; }
P=${URL##*:}
[ "$(get_code "$P" /)" = 200 ] || { ko "I1 : adresse non servie ($URL /)"; miss=1; }
[ "$(get_code "$P" /project.html)" = 200 ] || { ko "I1 : /project.html non servi"; miss=1; }
GI="$LP/.vibeflow/cockpit/.gitignore"
{ [ -f "$GI" ] && [ "$(wc -l < "$GI" | tr -d ' ')" = 2 ] && grep -qx '\*' "$GI"; } || { ko "I1 : .vibeflow/cockpit/.gitignore absent ou ≠ 2 lignes dont *"; miss=1; }
[ ! -e "$LP/floor""plan" ] && [ ! -e "$LP/CLAUDE.local.md" ] || { ko "I1 : un dossier amont ou CLAUDE.local.md est apparu dans le lab"; miss=1; }
OUT2=$(cd "$LP" && HOME="$FH" node .claude/scripts/vf-cockpit.mjs open --no-open --port "$PORT" 2>&1)
[ "$OUT2" = "$(printf '%s\n' "$OUT" | tail -1)" ] || { ko "I1 : un second open ne réutilise pas le serveur vivant"; miss=1; }
PID=$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).pid)' "$LP/.vibeflow/cockpit/.cache/server.json" 2>/dev/null)
(cd "$LP" && HOME="$FH" node .claude/scripts/vf-cockpit.mjs stop >/dev/null 2>&1)
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then ko "I1 : le serveur (PID $PID) tourne encore après stop"; miss=1; fi
[ "$miss" -eq 0 ] && ok "I1 project : module posé, open → $URL (GET / et /project.html = 200), .gitignore « * », réutilisation, stop"

# ---- I2 : scope user -----------------------------------------------------------------------------
pose user "$LU" || ko "I2 : l'engine a échoué — $(tail -2 "$WORK/pose.out")"
miss=0
for f in skills/vf-cockpit/SKILL.md skills/cockpit-moteur/VENDORED.txt scripts/vf-cockpit.mjs; do [ -f "$RU/$f" ] || { ko "I2 : \$HOME/.claude/$f non posé"; miss=1; }; done
[ ! -e "$LU/.claude" ] || { ko "I2 : ./.claude présent dans le lab (scope user)"; miss=1; }
(cd "$LU" && HOME="$FH" node "$RU/scripts/vf-cockpit.mjs" build --lab "$LU" >/dev/null 2>&1); RC=$?
{ [ "$RC" -eq 0 ] && [ -f "$LU/.vibeflow/cockpit/index.html" ]; } || { ko "I2 : le lanceur posé sous \$HOME n'assemble pas (rc=$RC)"; miss=1; }
[ "$miss" -eq 0 ] && ok "I2 user : posé sous \$HOME/.claude, rien sous ./.claude, lanceur posé assemble un cockpit"

# ---- I3 : scope local ----------------------------------------------------------------------------
pose local "$LL" || ko "I3 : l'engine a échoué — $(tail -2 "$WORK/pose.out")"
miss=0
for f in skills/vf-cockpit/SKILL.md skills/cockpit-moteur/VENDORED.txt scripts/vf-cockpit.mjs; do
  git -C "$LL" check-ignore -q ".claude/$f" || { ko "I3 : .claude/$f n'est pas ignoré par git"; miss=1; }
done
(cd "$LL" && HOME="$FH" node .claude/scripts/vf-cockpit.mjs build >/dev/null 2>&1); RC=$?
{ [ "$RC" -eq 0 ] && [ -f "$LL/.vibeflow/cockpit/project.html" ]; } || { ko "I3 : le lanceur posé en local n'assemble pas (rc=$RC)"; miss=1; }
[ "$miss" -eq 0 ] && ok "I3 local : chemins posés ignorés par git (check-ignore), lanceur posé assemble"

# ---- I4 : binaires à l'octet, trois scopes -------------------------------------------------------
n=0; miss=0
BIN=$(cd "$MOTEUR_SRC" && find . -type f \( -name '*.woff2' -o -name '*.png' \) | LC_ALL=C sort)
for r in "$RP" "$RU" "$RL"; do
  for b in $BIN; do
    if cmp -s "$MOTEUR_SRC/$b" "$r/skills/cockpit-moteur/$b"; then n=$((n+1)); else ko "I4 : binaire altéré à la pose ($r : $b)"; miss=1; fi
  done
done
[ "$(printf '%s\n' $BIN | grep -c .)" -ge 6 ] || { ko "I4 : moins de 6 binaires exposés (témoin d'exposition)"; miss=1; }
A="$WORK/altere.png"; cp "$RP/skills/cockpit-moteur/assets/logo.png" "$A"; printf 'X' | dd of="$A" bs=1 seek=40 conv=notrunc 2>/dev/null
if cmp -s "$MOTEUR_SRC/assets/logo.png" "$A"; then ko "I4 témoin : une copie altérée d'un octet passe cmp"; miss=1; else ok "I4 témoin rouge : cmp signale une copie altérée d'un octet"; fi
[ "$miss" -eq 0 ] && ok "I4 : $n comparaisons cmp de binaires (.woff2, .png) identiques à l'octet, trois scopes"

# ---- I4b : fichiers texte à l'octet, trois scopes ------------------------------------------------
n=0; miss=0
for r in "$RP" "$RU" "$RL"; do
  [ -z "$(comm -3 <(liste "$MOTEUR_SRC") <(liste "$r/skills/cockpit-moteur"))" ] || { ko "I4b : l'arbre posé du moteur n'a pas les mêmes fichiers que la source ($r)"; miss=1; }
  for f in $(liste "$MOTEUR_SRC"); do cmp -s "$MOTEUR_SRC/$f" "$r/skills/cockpit-moteur/$f" && n=$((n+1)) || { ko "I4b : $f réécrit hors --target ($r)"; miss=1; }; done
  for f in "$SRC"/scripts/vf-cockpit*.mjs "$SRC"/scripts/vf-cockpit-interface.json; do
    cmp -s "$f" "$r/scripts/$(basename "$f")" && n=$((n+1)) || { ko "I4b : scripts/$(basename "$f") réécrit hors --target ($r)"; miss=1; }
  done
  for f in skills/vf-cockpit/SKILL.md skills/vf-cockpit/agents/openai.yaml; do cmp -s "$SRC/$f" "$r/$f" && n=$((n+1)) || { ko "I4b : $f réécrit ($r)"; miss=1; }; done
done
[ "$miss" -eq 0 ] && ok "I4b : $n fichiers texte (arbre du moteur, scripts, skill) identiques à l'octet à leur source, trois scopes"

# ---- I5 : idempotence ----------------------------------------------------------------------------
avant=$( { empreintes "$RP/skills/cockpit-moteur"; empreintes "$RP/skills/vf-cockpit"; empreintes "$RP/scripts"; } | cksum)
pose project "$LP" || ko "I5 : seconde pose en échec"
apres=$( { empreintes "$RP/skills/cockpit-moteur"; empreintes "$RP/skills/vf-cockpit"; empreintes "$RP/scripts"; } | cksum)
miss=0
[ "$avant" = "$apres" ] || { ko "I5 : seconde pose différente (empreintes $avant ≠ $apres)"; miss=1; }
pose local "$LL" || ko "I5 : seconde pose locale en échec"
[ -z "$(sort "$LL/.gitignore" | uniq -d)" ] || { ko "I5 : lignes dupliquées dans le .gitignore du lab local : $(sort "$LL/.gitignore" | uniq -d | head -2)"; miss=1; }
[ "$(grep -cxF '.claude/skills/vf-cockpit/' "$LL/.gitignore")" = 1 ] || { ko "I5 : dossier du skill absent ou en double dans .gitignore"; miss=1; }
[ "$miss" -eq 0 ] && ok "I5 : seconde pose sans écart d'empreinte (project) ni doublon .gitignore (local)"

# ---- I6 : recouvrements ---------------------------------------------------------------------------
miss=0
for r in "$RP" "$RU" "$RL"; do
  [ -z "$(find "$r/skills/cockpit-moteur" -name SKILL.md 2>/dev/null)" ] || { ko "I6 : SKILL.md sous cockpit-moteur posé ($r)"; miss=1; }
  [ -z "$(find "$r" -iname "*$AMONT*" 2>/dev/null)" ] || { ko "I6 : un chemin posé porte le nom amont ($r)"; miss=1; }
done
[ "$miss" -eq 0 ] && ok "I6 : aucun SKILL.md sous le moteur, aucun chemin posé au nom du produit amont (trois scopes)"

# ---- I8 : sous --target ---------------------------------------------------------------------------
LT=$(mklab target); TG="$WORK/cible"; mkdir -p "$TG"; T=$(cd -P "$TG" && pwd -P)
pose project "$LT" --target "$TG" || ko "I8 : l'engine a échoué sous --target — $(tail -2 "$WORK/pose.out")"
miss=0; reecrits=""; nb=0
# reverse(posé) : la racine de cible redevient `.claude/` ; la source ramène ses préfixes `$HOME/` et `./` à `.claude/`
norm_src() { sed -e 's#"\$HOME"/\.claude/#.claude/#g' -e 's#\$HOME/\.claude/#.claude/#g' -e 's#\./\.claude/#.claude/#g' "$1"; }
restaure() { sed -e "s#$T/#.claude/#g" "$1"; }
verifie() { # $1 source, $2 posé
  case "$1" in *.woff2|*.png) cmp -s "$1" "$2" || { ko "I8 : binaire altéré sous --target : $2"; miss=1; }; return ;; esac
  nb=$((nb+1))
  if ! cmp -s "$1" "$2"; then reecrits="$reecrits ${2#$T/}"; fi
  cmp -s <(norm_src "$1") <(restaure "$2") || { ko "I8 : écart autre que la réécriture de .claude/ : ${2#$T/}"; miss=1; }
}
for f in $(liste "$MOTEUR_SRC"); do verifie "$MOTEUR_SRC/$f" "$T/skills/cockpit-moteur/$f"; done
for f in "$SRC"/scripts/vf-cockpit*.mjs "$SRC"/scripts/vf-cockpit-interface.json; do verifie "$f" "$T/scripts/$(basename "$f")"; done
verifie "$SRC/skills/vf-cockpit/SKILL.md" "$T/skills/vf-cockpit/SKILL.md"
echo "  · $nb fichiers texte comparés ; réécrits sous --target :${reecrits:- aucun}"
(cd "$LT" && HOME="$FH" node "$T/scripts/vf-cockpit.mjs" build --lab "$LT" >/dev/null 2>&1); RC=$?
[ "$RC" -eq 0 ] || { ko "I8 : le lanceur posé sous la cible n'assemble pas (rc=$RC)"; miss=1; }
OCC=$(cat > "$WORK/occ.mjs" <<JS
import fs from 'node:fs';
const { compterOccurrences } = await import('file://$T/scripts/vf-cockpit-rename.mjs');
let n = 0; for (const f of ['$LT/.vibeflow/cockpit/index.html', '$LT/.vibeflow/cockpit/project.html', '$T/skills/cockpit-moteur/assets/serve.mjs', '$T/skills/cockpit-moteur/assets/graph-query.js', '$T/skills/cockpit-moteur/assets/query-cli.mjs', '$T/scripts/vf-cockpit-embed.mjs', '$T/scripts/vf-cockpit-lancer-post.mjs', '$T/scripts/vf-cockpit-server.mjs']) n += compterOccurrences(fs.readFileSync(f, 'utf8')); // 79-06 : les pages de la sortie ET le code du module posé sous la cible (la sortie ne porte plus de code)
console.log(n);
JS
node "$WORK/occ.mjs" 2>&1)
[ "$OCC" = 0 ] || { ko "I8 : le rendu servi compte $OCC occurrence(s) du nom amont sous --target"; miss=1; }
# témoin rouge : une copie posée dont un caractère hors `.claude/` est altéré est signalée
cp "$T/scripts/vf-cockpit.mjs" "$WORK/alt.mjs"; sed -i.bak 's/Cockpit : /Cockpiv : /' "$WORK/alt.mjs"
if cmp -s <(norm_src "$SRC/scripts/vf-cockpit.mjs") <(restaure "$WORK/alt.mjs"); then ko "I8 témoin : une altération hors .claude/ passe inaperçue"; miss=1; else ok "I8 témoin rouge : une altération hors .claude/ est signalée"; fi
[ "$miss" -eq 0 ] && ok "I8 : sous --target, seule la réécriture de .claude/ a eu lieu, binaires à l'octet, rendu sans le nom amont (0 occurrence)"

# ---- I9 : le mod vf-signal n'est ni un fragment de l'engine ni posé par lui (68-04, P68-D-11, P68-D-13) ---------------
# (a) cache piégé : un fragment réduit à `modules` sous cockpit/hooks/ est fusionné comme un fragment de hooks → l'engine meurt.
miss=0
PIEGE="$WORK/cache-piege"; prepare_module "$PIEGE" cockpit || { ko "I9 : cache piégé impossible"; miss=1; }
mkdir -p "$PIEGE/cockpit/hooks"; printf '{ "modules": ["./register.tsx"] }\n' > "$PIEGE/cockpit/hooks/hooks.json"
LX=$(mklab piege)
(cd "$LX" && HOME="$FH" VF_SCOPE=project VIBEFLOW_CACHE="$PIEGE" bash "$INSTALLER" install cockpit >"$WORK/piege.out" 2>&1); RCX=$?
if [ "$RCX" -ne 0 ] && grep -q "sans clé 'hooks'" "$WORK/piege.out"; then ok "I9a témoin rouge : un fragment réduit à modules fait échouer l'install (rc=$RCX, fragment sans clé 'hooks')"
else ko "I9a : le cache piégé n'a pas fait échouer l'install comme prévu (rc=$RCX) — $(tail -2 "$WORK/piege.out")"; miss=1; fi
# (b) vrai cache : l'install passe et la cible ne porte ni .ts/.tsx ni signal/.
LR=$(mklab reel)
(cd "$LR" && HOME="$FH" VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install cockpit >"$WORK/reel.out" 2>&1); RCR=$?
[ "$RCR" -eq 0 ] || { ko "I9b : l'install du vrai cache échoue (rc=$RCR) — $(tail -2 "$WORK/reel.out")"; miss=1; }
[ -d "$LR/.claude/scripts" ] || { ko "I9b : rien n'a été posé sous la cible (contrôle vide)"; miss=1; }
TSX=$(find "$LR/.claude" \( -name '*.ts' -o -name '*.tsx' \) 2>/dev/null | head -3); SIGD=$(find "$LR/.claude" -type d -name signal 2>/dev/null | head -1)
[ -z "$TSX" ] || { ko "I9b : fichier .ts/.tsx posé par l'engine : $TSX"; miss=1; }
[ -z "$SIGD" ] || { ko "I9b : dossier signal/ posé par l'engine : $SIGD"; miss=1; }
[ "$miss" -eq 0 ] && ok "I9 : cache piégé refusé (fragment sans clé 'hooks'), vrai cache installé sans .ts/.tsx ni signal/ sous la cible"

# ---- I7 : vrai ~/.claude ------------------------------------------------------------------------
[ "$(snapshot_home_claude)" = "$HOME_BEFORE" ] && ok "I7 : aucun fichier du cockpit posé ni retiré dans le vrai ~/.claude (empreinte $HOME_BEFORE)" || ko "I7 : le vrai ~/.claude a changé"

echo "== resultat : $pass ok, $fail ko =="
[ $((pass + fail)) -gt 0 ] || { echo "ÉCHEC ANTI-VERT-À-VIDE : aucun cas exécuté"; exit 1; }
[ "$fail" -eq 0 ]
