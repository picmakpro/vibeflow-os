#!/usr/bin/env bash
# test-check-workstream-pointer.sh — Suite de verification de check-workstream-pointer.sh
# (Phase 24-05, exigence GSDA-16).
#
# Un cas par etat du contrat (cf. en-tete du script), chacun sur sa propre fixture construite dans
# un mktemp -d, jamais sur le depot reel. Les cinq codes du contrat (0, 1, 2, 3, 64) sont exerces et
# l'ensemble effectivement observe est compare a l'ensemble attendu en fin de suite.
#
# Deux cas de DISCRIMINANCE PAR MUTATION ferment la porte au vert a vide :
#   - MUT-1 mute la FIXTURE de l'etat 4 (partitionne, aucun canal) pour la rendre resolvable : le
#     gate doit passer de rouge a vert. L'effectivite de la mutation est prouvee par `cmp` sur
#     l'empreinte de la fixture (jamais par `diff`, proxifie et menteur sur ce runtime).
#   - MUT-2 mute le SCRIPT lui-meme dans une copie temporaire, en neutralisant la branche « dossier
#     de workstream absent » : le cas 4 doit rougir (le nom introuvable retombant sur un exit 0),
#     puis redevenir vert sur le script restaure. Une mutation qui ne change rien au fichier rend le
#     mutant NON OPPOSABLE et fait echouer la suite — jamais « mutant satisfait ».

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-workstream-pointer.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RCS="$TMP/rcs.txt"
: > "$RCS"
note_rc() { echo "$1" >> "$RCS"; }

# Environnement d'invocation TOUJOURS explicite : la suite ne doit jamais heriter du
# GSD_WORKSTREAM du shell qui la lance (ce serait un vert — ou un rouge — par contamination).
run() { # <ws-ou-vide> <args...>
  local ws="$1"; shift
  if [ -n "$ws" ]; then
    env -u VF_WORKSTREAM_PLANNING_DIR GSD_WORKSTREAM="$ws" bash "$TARGET" "$@" 2>&1
  else
    env -u VF_WORKSTREAM_PLANNING_DIR -u GSD_WORKSTREAM bash "$TARGET" "$@" 2>&1
  fi
}

TARGET="$SCRIPT"

mk_git_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d/.planning"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  printf '# Projet\n' > "$d/.planning/PROJECT.md"
  printf '%s' "$d"
}

empreinte() { find "$1" | LC_ALL=C sort; }

echo "== test-check-workstream-pointer =="

# === Cas 1 — depot NON PARTITIONNE (workstreams/ absent) → exit 3, stdout vide =====================
D="$(mk_git_root c1)"
sout="$(env -u VF_WORKSTREAM_PLANNING_DIR -u GSD_WORKSTREAM bash "$SCRIPT" --path "$D" 2>/dev/null)"; rc=$?
note_rc "$rc"
if [ "$rc" -eq 3 ] && [ -z "$sout" ]; then ok "1 non partitionne → exit 3, stdout vide"
else ko "1 non partitionne → exit 3, stdout vide" "rc=$rc stdout=[$sout]"; fi

# === Cas 1b — meme fixture en --hook : silence TOTAL (stdout ET stderr vides) ======================
D="$(mk_git_root c1b)"
both="$(env -u VF_WORKSTREAM_PLANNING_DIR -u GSD_WORKSTREAM bash "$SCRIPT" --hook --path "$D" 2>&1)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$both" ]; then ok "1b non partitionne en --hook → exit 3, aucune sortie du tout"
else ko "1b non partitionne en --hook → silence total" "rc=$rc sortie=[$both]"; fi

# === Cas 2 — GSD_WORKSTREAM=dev + workstreams/dev/ present → exit 0, canal env =====================
D="$(mk_git_root c2)"; mkdir -p "$D/.planning/workstreams/dev"
out="$(run dev --path "$D")"; rc=$?
note_rc "$rc"
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'dev' && printf '%s' "$out" | grep -q 'GSD_WORKSTREAM'; then
  ok "2 GSD_WORKSTREAM=dev + dossier present → exit 0, message cite dev et le canal d'environnement"
else ko "2 canal env → exit 0" "rc=$rc out=[$out]"; fi

# === Cas 3 — pointeur partage in-repo → exit 0, canal store-partage ================================
D="$(mk_git_root c3)"; mkdir -p "$D/.planning/workstreams/dev"
printf 'dev\n' > "$D/.planning/active-workstream"
out="$(run "" --path "$D")"; rc=$?
note_rc "$rc"
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'store-partag' && printf '%s' "$out" | grep -q 'dev'; then
  ok "3 pointeur partage in-repo → exit 0, message cite le canal de pointeur partage"
else ko "3 canal store-partage → exit 0" "rc=$rc out=[$out]"; fi

# === Cas 4 — nom resolu mais dossier ABSENT → exit 1, auto-nettoyage rendu audible =================
D="$(mk_git_root c4)"; mkdir -p "$D/.planning/workstreams/dev"
out="$(run fantome --path "$D")"; rc=$?
note_rc "$rc"
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'fantome' && printf '%s' "$out" | grep -q 'en silence'; then
  ok "4 nom resolu, dossier absent → exit 1, message cite fantome et l'effacement silencieux du moteur"
else ko "4 dossier absent → exit 1" "rc=$rc out=[$out]"; fi

# === Cas 5 — partitionne, AUCUN canal composable → exit 1, fait + remede ===========================
D="$(mk_git_root c5)"; mkdir -p "$D/.planning/workstreams/dev"
out="$(run "" --path "$D")"; rc=$?
note_rc "$rc"
miss=""
for lit in 'os.tmpdir()' 'jamais hérité' 'ADR-064' 'GSD_WORKSTREAM'; do
  printf '%s' "$out" | grep -qF "$lit" || miss="$miss [$lit]"
done
if [ "$rc" -eq 1 ] && [ -z "$miss" ]; then
  ok "5 partitionne sans canal composable → exit 1, message portant os.tmpdir(), ADR-064 et le remede GSD_WORKSTREAM"
else ko "5 aucun canal composable → exit 1 + litteraux" "rc=$rc manquants=$miss out=[$out]"; fi

# === Cas 6 — nom hors classe de caracteres → exit 2, nom absent de la sortie =======================
D="$(mk_git_root c6)"; mkdir -p "$D/.planning/workstreams/dev"
printf '../evil\n' > "$D/.planning/active-workstream"
out="$(run "" --path "$D")"; rc=$?
note_rc "$rc"
if [ "$rc" -eq 2 ] && ! printf '%s' "$out" | grep -qF '../evil'; then
  ok "6 nom hors classe dans le pointeur partage → exit 2, et le nom n'apparait dans aucun chemin de la sortie"
else ko "6 nom hors classe → exit 2 sans reimpression" "rc=$rc out=[$out]"; fi

# === Cas 6b — nom hors classe via GSD_WORKSTREAM → exit 2 (jamais un chemin construit) =============
D="$(mk_git_root c6b)"; mkdir -p "$D/.planning/workstreams/dev"
out="$(run '../evil' --path "$D")"; rc=$?
if [ "$rc" -eq 2 ] && ! printf '%s' "$out" | grep -qF '../evil'; then
  ok "6b nom hors classe via GSD_WORKSTREAM → exit 2, valeur non reimprimee"
else ko "6b nom hors classe via env → exit 2" "rc=$rc out=[$out]"; fi

# === Cas 6c — ANGLE MORT ferme : noms ENTIEREMENT dans la classe mais refuses par le moteur ========
# La copie locale de la politique n'avait repris que la CLASSE DE CARACTERES amont, en abandonnant
# `hasInvalidPathSegment` et l'ancre alphanumerique initiale. `.` et `..` sont entierement dans la
# classe : ce gate rendait donc « exit 0 conforme » sur `..`, et `WS_DIR="$WS_ROOT/.."` satisfait
# trivialement `[ -d ]`. La suite ne contenait que `../evil`, attrape par le `/` — c'est ce trou
# exact qui a laisse passer le defaut. Aucun de ces noms ne doit resoudre.
# NB sur la forme des assertions : un test de sous-chaine BRUTE sur ces noms-la serait ininterpretable
# — le message de rejet DECRIT la politique (« ni '.'/'..', ni '..' en sous-chaine »), il contient
# donc `.` et `..` legitimement. On assert donc ce qui a un sens : jamais concatene dans un chemin
# (`workstreams/<nom>`), jamais NOMME comme resolu (« <nom> »). La non-reimpression verbatim est
# prouvee juste apres, sur un marqueur distinctif que rien d'autre ne peut produire.
D="$(mk_git_root c6c)"; mkdir -p "$D/.planning/workstreams/dev"
c6c_ok=1; c6c_detail=""
for bad in '.' '..' '.hidden' '-x' 'a..b' '_lead'; do
  out="$(run "$bad" --path "$D")"; rc=$?
  [ "$rc" -eq 2 ] || { c6c_ok=0; c6c_detail="$bad -> rc=$rc (attendu 2)"; }
  printf '%s' "$out" | awk -v b="workstreams/$bad" 'index($0, b) { f=1 } END { exit !f }' \
    && { c6c_ok=0; c6c_detail="$bad concatene dans un chemin"; }
  printf '%s' "$out" | awk -v b="« $bad »" 'index($0, b) { f=1 } END { exit !f }' \
    && { c6c_ok=0; c6c_detail="$bad nomme comme workstream resolu"; }
done
note_rc 2
if [ "$c6c_ok" -eq 1 ]; then
  ok "6c noms dans la classe mais hors politique amont (. .. .hidden -x a..b _lead) → exit 2, jamais concatenes ni nommes"
else ko "6c noms hors politique amont" "$c6c_detail"; fi

# Non-reimpression VERBATIM, prouvee sur un marqueur distinctif : aucune partie du script ne peut
# produire cette chaine autrement qu'en reimprimant la valeur rejetee.
MARQUEUR='zzSECRETMARKERzz..q'
out="$(run "$MARQUEUR" --path "$D")"; rc=$?
fuite=$(printf '%s' "$out" | awk '/zzSECRETMARKERzz/ { print "oui" }')
if [ "$rc" -eq 2 ] && [ -z "$fuite" ]; then
  ok "6c-bis nom rejete distinctif → exit 2, et la valeur brute n'apparait nulle part dans la sortie"
else ko "6c-bis reimpression verbatim d'une valeur rejetee" "rc=$rc out=[$out]"; fi

# === Cas 6d — le gate ne doit pas FABRIQUER un nom absent du fichier ===============================
# `tr -d ' \011\013\014\015'` supprimait TOUS les espaces, pas seulement ceux des bords : un pointeur
# contenant « de v » (que le moteur rejette) rendait « conforme — workstream « dev » resolu ». Le gate
# fabriquait un vert sur un nom qui n'etait pas dans le fichier. Le rognage ne touche que les BORDS.
D="$(mk_git_root c6d)"; mkdir -p "$D/.planning/workstreams/dev"
printf 'de v\n' > "$D/.planning/active-workstream"
out="$(run "" --path "$D")"; rc=$?
fabrique=$(printf '%s' "$out" | awk '/workstream . dev ./ || /« dev »/ { print "oui" }')
if [ "$rc" -eq 2 ] && [ -z "$fabrique" ]; then
  ok "6d pointeur « de v » → exit 2 ; aucun « dev » fabrique a partir d'un nom absent du fichier"
else ko "6d fabrication d'un nom par suppression des espaces internes" "rc=$rc out=[$out]"; fi

# Le rognage des BORDS, lui, reste actif : « \n  dev  \n » vaut bien « dev » (parite `raw.trim()`).
printf '  dev  \n' > "$D/.planning/active-workstream"
out="$(run "" --path "$D")"; rc=$?
if [ "$rc" -eq 0 ]; then
  ok "6d-bis pointeur «   dev   » → exit 0 : les bords sont bien rognes (parite avec .trim() amont)"
else ko "6d-bis rognage des bords" "rc=$rc out=[$out]"; fi

# Le fichier ENTIER est rogne, pas sa 1re ligne : « dev\nautre » est INVALIDE amont (`raw.trim()`
# laisse le saut de ligne interne), la lecture ligne a ligne le rendait « dev ».
printf 'dev\nautre\n' > "$D/.planning/active-workstream"
out="$(run "" --path "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then
  ok "6d-ter pointeur « dev\\nautre » → exit 2 : le fichier entier est evalue, pas sa 1re ligne"
else ko "6d-ter lecture du fichier entier" "rc=$rc out=[$out]"; fi

# === Cas 6e — FUITE D'INFORMATION par lien symbolique versionne (SessionStart) =====================
# Un `.planning/active-workstream` versionne en mode 120000 vers `../../victime/.env` faisait
# imprimer la 1re ligne du fichier cible VERBATIM sur stdout du hook, donc dans le contexte de
# session, sans aucune action de la victime au-delà de l'ouverture de session. Seule condition : que
# la ligne tienne dans la classe de caracteres. Le refus de suivre le lien est la garde portante.
D="$(mk_git_root c6e)"; mkdir -p "$D/.planning/workstreams/dev"
printf 'sk-live-FUITE-0001.SECRET\n' > "$TMP/victime.env"
ln -sf "$TMP/victime.env" "$D/.planning/active-workstream"
out="$(run "" --path "$D" --hook)"; rc=$?
fuite=$(printf '%s' "$out" | awk '/sk-live-FUITE-0001/ { print "oui" }')
if [ "$rc" -eq 2 ] && [ -z "$fuite" ]; then
  ok "6e pointeur = lien symbolique → exit 2 ; le contenu de la cible ne traverse PAS vers la sortie"
else ko "6e fuite par lien symbolique" "rc=$rc out=[$out]"; fi
rm -f "$D/.planning/active-workstream"

# === Cas 6f — pointeur non borne : la sortie ne doit pas porter la valeur, ni sa taille ============
# La valeur rejetee etait reimprimee sans aucune borne de longueur.
D="$(mk_git_root c6f)"; mkdir -p "$D/.planning/workstreams/dev"
awk 'BEGIN { s=""; for (i=0;i<5000;i++) s=s"a"; print s }' > "$D/.planning/active-workstream"
out="$(run "" --path "$D" --hook)"; rc=$?
maxlen=$(printf '%s' "$out" | awk 'BEGIN{m=0} {if (length($0)>m) m=length($0)} END{print m+0}')
if [ "$rc" -eq 2 ] && [ "$maxlen" -lt 512 ]; then
  ok "6f pointeur de 5000 car. → exit 2, et aucune ligne de sortie ne porte la valeur (max ${maxlen} car.)"
else ko "6f borne de lecture du pointeur" "rc=$rc ligne la plus longue=$maxlen"; fi

# === Cas 7 — repertoire hors depot git → exit 2, JAMAIS 0 =========================================
D="$TMP/c7-hors-git"; mkdir -p "$D/.planning/workstreams/dev"
out="$(run "" --path "$D")"; rc=$?
note_rc "$rc"
if [ "$rc" -eq 2 ]; then ok "7 hors depot git → exit 2 (non verifiable), jamais 0"
else ko "7 hors depot git → exit 2" "rc=$rc out=[$out]"; fi

# === Cas 8 — usage : argument inconnu et option sans valeur → exit 64 ==============================
env -u GSD_WORKSTREAM bash "$SCRIPT" --inconnu >/dev/null 2>&1; rc=$?
note_rc "$rc"
if [ "$rc" -eq 64 ]; then ok "8 argument inconnu → exit 64"; else ko "8 argument inconnu → exit 64" "rc=$rc"; fi

env -u GSD_WORKSTREAM bash "$SCRIPT" --path >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 64 ]; then ok "8b --path sans valeur → exit 64"; else ko "8b --path sans valeur → exit 64" "rc=$rc"; fi

# === Cas 9 — --help → exit 0 et docstring enumerant les cinq codes du contrat ======================
out="$(env -u GSD_WORKSTREAM bash "$SCRIPT" --help 2>/dev/null)"; rc=$?
codes_manquants=""
for c in 0 1 2 3 64; do
  printf '%s\n' "$out" | awk -v c="$c" '$1==c && $2=="=" {trouve=1} END{exit trouve?0:1}' || codes_manquants="$codes_manquants $c"
done
if [ "$rc" -eq 0 ] && [ -n "$out" ] && [ -z "$codes_manquants" ]; then
  ok "9 --help → exit 0, docstring enumerant les codes 0, 1, 2, 3 et 64"
else ko "9 --help → exit 0 + enumeration des codes" "rc=$rc manquants=[$codes_manquants]"; fi

# === Cas 10 — lecture seule : empreinte de la fixture identique avant/apres ========================
D="$(mk_git_root c10)"; mkdir -p "$D/.planning/workstreams/dev"
printf 'dev\n' > "$D/.planning/active-workstream"
empreinte "$D" > "$TMP/c10.before"
run "" --path "$D" >/dev/null 2>&1
run fantome --path "$D" >/dev/null 2>&1
empreinte "$D" > "$TMP/c10.after"
if cmp -s "$TMP/c10.before" "$TMP/c10.after"; then
  ok "10 lecture seule — le gate n'efface ni ne cree rien (empreinte identique, cmp)"
else ko "10 lecture seule" "l'empreinte de la fixture a change"; fi

# === Cas 11 — --hook ne change AUCUN code de sortie (parite stricte) ===============================
D="$(mk_git_root c11)"; mkdir -p "$D/.planning/workstreams/dev"
run "" --path "$D" >/dev/null 2>&1; rc_plain=$?
run "" --hook --path "$D" >/dev/null 2>&1; rc_hook=$?
sig="$(run "" --hook --path "$D" 2>/dev/null)"
if [ "$rc_plain" -eq "$rc_hook" ] && printf '%s' "$sig" | grep -qF 'os.tmpdir()'; then
  ok "11 --hook ne change pas le code de sortie ($rc_plain), et porte le signal sur stdout"
else ko "11 parite --hook" "rc_plain=$rc_plain rc_hook=$rc_hook sig=[$sig]"; fi

# === Cas 12 — les cinq codes du contrat sont chacun exerces, et rien hors contrat ==================
LC_ALL=C sort -u "$RCS" > "$TMP/rcs.seen"
printf '0\n1\n2\n3\n64\n' | LC_ALL=C sort -u > "$TMP/rcs.attendus"
manquants="$(comm -13 "$TMP/rcs.seen" "$TMP/rcs.attendus" | tr '\n' ' ')"
hors="$(comm -23 "$TMP/rcs.seen" "$TMP/rcs.attendus" | tr '\n' ' ')"
if [ -z "$manquants" ] && [ -z "$hors" ]; then
  ok "12 les cinq codes du contrat (0, 1, 2, 3, 64) sont chacun exerces, aucun rc hors contrat"
else ko "12 couverture des codes de sortie" "manquants=[$manquants] hors_contrat=[$hors]"; fi

# === MUT-1 — mutation de FIXTURE : l'etat 4 doit passer de rouge a vert ============================
# La mutation ajoute au depot partitionne un canal composable. Elle est confirmee effective par
# `cmp` sur l'empreinte de la fixture — jamais par `diff`.
echo ""
echo "== mutants =="
D="$(mk_git_root mut1)"; mkdir -p "$D/.planning/workstreams/dev"
empreinte "$D" > "$TMP/mut1.before"
run "" --path "$D" >/dev/null 2>&1; rc_avant=$?
printf 'dev\n' > "$D/.planning/active-workstream"        # <- la mutation
empreinte "$D" > "$TMP/mut1.after"
if cmp -s "$TMP/mut1.before" "$TMP/mut1.after"; then
  ko "MUT-1 fixture de l'etat 4 rendue resolvable" "la mutation n'a RIEN change a la fixture — mutant NON OPPOSABLE, pas mutant satisfait"
else
  run "" --path "$D" >/dev/null 2>&1; rc_apres=$?
  # Lettre du plan : le canal GSD_WORKSTREAM, seul, suffit aussi sur la fixture d'origine.
  D2="$(mk_git_root mut1b)"; mkdir -p "$D2/.planning/workstreams/dev"
  run dev --path "$D2" >/dev/null 2>&1; rc_env=$?
  if [ "$rc_avant" -eq 1 ] && [ "$rc_apres" -eq 0 ] && [ "$rc_env" -eq 0 ]; then
    ok "MUT-1 fixture de l'etat 4 rendue resolvable (cmp : fixture bien modifiee) : rouge=1 avant, vert=0 apres pointeur partage, vert=0 aussi par GSD_WORKSTREAM seul"
  else
    ko "MUT-1 fixture rendue resolvable : rouge → vert" "rc_avant=$rc_avant (attendu 1) rc_apres=$rc_apres (attendu 0) rc_env=$rc_env (attendu 0)"
  fi
fi

# === MUT-2 — mutation du SCRIPT : neutraliser la branche « dossier absent » ========================
# Le nom introuvable retombe alors sur un exit 0 : le cas 4 DOIT rougir. Restauration → vert.
MUTD="$TMP/mutants"; mkdir -p "$MUTD"
# Le motif suit la LETTRE du script : la condition de cette branche n'est plus `[ ! -d "$WS_DIR" ]`
# mais le code rendu par `vf_ws_dir_resolve` (la construction de chemin suivie d'un `[ -d ]` a été
# retirée — `[ -d ]` traverse les liens symboliques, ce qui faisait bénir « conforme » un
# compartiment pointant hors du lab). Le mutant, lui, est inchangé dans son INTENTION : neutraliser
# la branche « dossier absent » pour que le nom introuvable retombe sur un exit 0.
cat > "$MUTD/neutralise-dossier-absent.awk" <<'AWKEOF'
{
  if (!fait && index($0, "if [ \"$WS_DIR_RC\" -ne 0 ]; then") > 0) {
    sub(/\[ "\$WS_DIR_RC" -ne 0 \]/, "false")
    fait = 1
  }
  print
}
AWKEOF
MUTANT="$MUTD/check-workstream-pointer.mut.sh"
awk -f "$MUTD/neutralise-dossier-absent.awk" "$SCRIPT" > "$MUTANT"

D="$(mk_git_root mut2)"; mkdir -p "$D/.planning/workstreams/dev"
if cmp -s "$MUTANT" "$SCRIPT"; then
  ko "MUT-2 branche « dossier absent » neutralisee" "la mutation n'a RIEN change (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
elif ! bash -n "$MUTANT" 2>/dev/null; then
  ko "MUT-2 branche « dossier absent » neutralisee" "le mutant n'est pas un script valide : il rougirait pour la mauvaise raison"
else
  TARGET="$MUTANT"
  run fantome --path "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"
  run fantome --path "$D" >/dev/null 2>&1; rc_restaure=$?
  if [ "$rc_mut" -ne 1 ] && [ "$rc_restaure" -eq 1 ]; then
    ok "MUT-2 branche « dossier absent » neutralisee (cmp : script bien mute) : le cas 4 ROUGIT sur le mutant (rc=$rc_mut au lieu de 1), et redevient VERT sur le script restaure (rc=$rc_restaure)"
  else
    ko "MUT-2 le cas 4 doit rougir sur le mutant et redevenir vert apres restauration" "rc_mutant=$rc_mut (devait differer de 1) rc_restaure=$rc_restaure (attendu 1)"
  fi
fi

echo ""
echo "== resultat : $PASS ok, $FAIL ko ($((PASS+FAIL)) cas) =="
[ "$FAIL" -eq 0 ]
