#!/usr/bin/env bash
# test-local-patches.sh — Suite des patches locaux de modules (#166, volet 1).
#
# Le moteur recopiait les fichiers du cache sur ceux du lab sans comparer le lab à ce qu'il avait
# posé : une modification locale d'un SKILL.md imbriqué ou d'un fichier de données de scripts/
# disparaissait sans un mot (backup_module ne couvre ni l'un ni l'autre). Le moteur détecte,
# sauvegarde et avertit ; il pose TOUJOURS la version du cache.
#
# Fixture : un module `fixmod` en deux versions (caches frères v1/v2, la version du MODULE diffère)
# dans un lab hermétique (mktemp -d, HOME jetable). Rien n'est lu ni écrit hors des mktemp.
#
#   A  install v1, modification locale d'un SKILL.md imbriqué ET d'un fichier non-.sh de scripts/,
#      update v2 : message `[local-patches] 2`, sauvegarde identique (cmp), .patch réapplicable sur
#      la version posée (patch -o → version du lab), fichier posé = v2.
#   B  aucune modification locale : aucune ligne, aucun dossier local-patches-*.
#   C  --dry-run : `[plan] !` pour chaque fichier modifié, aucune écriture (find|sort puis cmp).
#   D  premier passage sans empreintes (lab posé par l'ancien moteur) : repli sur le cache de
#      l'ancienne version ; sans ce cache, aucune conclusion — une ligne par module, aucune sauvegarde (D2).
#   E  aucun outil sha256 : une ligne d'indisponibilité, pas de crash, pose normale.
#   F  fichier modifié localement mais identique au nouveau : aucune ligne.
#   G  le fichier d'empreintes porte l'empreinte exacte de chaque fichier posé, trié LC_ALL=C, et
#      n'est jamais lu comme un manifeste ni comme un module.
#   H  désinstallation : le fichier d'empreintes disparaît avec le manifeste.
#   I  sous --target (contenu réécrit à la pose) : l'empreinte est celle du fichier RÉELLEMENT posé,
#      donc aucune fausse alerte à l'update suivant.
#   J  `update --all` sur deux modules : une seule annonce, un seul dossier, N cumulé.
#
# Revue du lot D (blocs K à P, I4/I5, D2a/D2b, M) :
#   K  F1 — l'injection MCP du moteur n'est jamais un patch local (premier passage, changement du jeu MCP,
#      update --all) ; un vrai patch local sur un agent injecté reste détecté (K4, K5).
#   L  F2 — `[plan] !` si et seulement si la pose réelle sauvegarde, dans les deux ordres de modules.
#   M  F3 — la resync à version égale est couverte ; empreintes mises à jour ; D2 : une ligne par module.
#   N  F4 — l'annonce sort une fois sur un abort, code de sortie inchangé, un seul trap EXIT.
#   O  F6 — règle d'ignorance du fichier d'empreintes : project et local oui, user et --target non.
#   P  F7 — hachage par lots : le nombre d'appels ne dépend pas du nombre de fichiers.
#   I4/I5  F5a — repli sur l'ancien cache sous --target (référence réécrite).
#
# Convention : ok()/ko(), exit 0 si tout passe, 1 au moins un KO (calqué sur test-manifest.sh).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
INSTALLER="${VF_LP_TEST_ENGINE:-$INTERNAL_DIR/vibeflow-update.sh}"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
GREP="$(command -v grep)"

echo "== test-local-patches (engine: $INSTALLER) =="

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
FAKEHOME="$T/home"; mkdir -p "$FAKEHOME"
export HOME="$FAKEHOME"

# Cache fixture d'une version : $1 = dossier, $2 = version. SKILL.md et fixdata.txt changent d'une
# version à l'autre ; same.md et fixmod.sh ne changent pas.
mk_cache() {
  local d="$1" v="$2"
  mkdir -p "$d/fixmod/skills/nested/references" "$d/fixmod/scripts"
  printf '%s\n' "$v" > "$d/fixmod/VERSION"
  printf '{"name":"fixmod","version":"%s"}\n' "$v" > "$d/fixmod/module.json"
  printf 'nested skill, version %s\nligne commune\n' "$v" > "$d/fixmod/skills/nested/SKILL.md"
  printf 'reference commune\n' > "$d/fixmod/skills/nested/references/same.md"
  printf '#!/usr/bin/env bash\necho fixmod\n' > "$d/fixmod/scripts/fixmod.sh"
  printf 'donnees, version %s\n' "$v" > "$d/fixmod/scripts/fixdata.txt"
}
mk_cache "$T/cache/v1" "1.0.0"
mk_cache "$T/cache/v2" "1.1.0"

# eng <lab> <cache> <args...> — lance le moteur dans le lab ; stdout dans $T/out, stderr dans $T/err.
eng() {
  local lab="$1" cache="$2"; shift 2
  (cd "$lab" && VF_SCOPE=project VIBEFLOW_CACHE="$cache" bash "$INSTALLER" "$@") >"$T/out" 2>"$T/err"
}
# newlab <nom> — lab jumeau avec v1 installé.
newlab() {
  local lab="$T/$1"
  mkdir -p "$lab"
  eng "$lab" "$T/cache/v1" install fixmod || { ko "$1 : install v1 en échec (fixture morte, rc=$?)"; }
  printf '%s' "$lab"
}
sha_of() { if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1"; else shasum -a 256 < "$1"; fi | awk '{print $1}'; }
NESTED=".claude/skills/nested/SKILL.md"
DATA=".claude/scripts/fixdata.txt"

# ---------------------------------------------------------------------------
# A — deux fichiers modifiés localement (hors couverture de backup_module), update v2.
# ---------------------------------------------------------------------------
LAB="$(newlab labA)"
printf 'PATCH LOCAL du lab\n' >> "$LAB/$NESTED"
printf 'donnee locale\n' >> "$LAB/$DATA"
cp "$LAB/$NESTED" "$T/a-nested.lab"; cp "$LAB/$DATA" "$T/a-data.lab"
eng "$LAB" "$T/cache/v2" update fixmod
A_RC=$?
BK="$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)"
if [ "$A_RC" -eq 0 ] && "$GREP" -qF '[local-patches] 2 fichier(s) modifié(s) localement ont été remplacés' "$T/err"; then
  ok "A1 : message [local-patches] avec N exact (2) sur stderr"
else
  ko "A1 : message absent ou N faux (rc=$A_RC) — attendu '[local-patches] 2 fichier(s)…' ; obtenu: $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
fi
if "$GREP" -qxF "[vibeflow-update]   skills/nested/SKILL.md" "$T/err" && "$GREP" -qxF "[vibeflow-update]   scripts/fixdata.txt" "$T/err"; then
  ok "A2 : une ligne par fichier (chemin relatif à la cible)"
else
  ko "A2 : lignes par fichier absentes (attendu skills/nested/SKILL.md et scripts/fixdata.txt)"
fi
if [ -n "$BK" ] && [ "$(printf '%s\n' "$BK" | wc -l | tr -d ' ')" -eq 1 ] \
   && cmp -s "$BK/skills/nested/SKILL.md" "$T/a-nested.lab" && cmp -s "$BK/scripts/fixdata.txt" "$T/a-data.lab"; then
  ok "A3 : un seul dossier local-patches-*, sauvegardes identiques aux fichiers modifiés (cmp)"
else
  ko "A3 : dossier de sauvegarde absent/multiple ou contenu différent (BK=[$BK])"
fi
if command -v patch >/dev/null 2>&1; then
  A4=1
  for f in skills/nested/SKILL.md scripts/fixdata.txt; do
    if [ -f "$BK/$f.patch" ] && patch -s -o "$T/a-out" "$LAB/.claude/$f" < "$BK/$f.patch" >/dev/null 2>&1 \
       && cmp -s "$T/a-out" "$BK/$f"; then :; else A4=0; echo "    (patch non réapplicable : $f)"; fi
  done
  [ "$A4" -eq 1 ] && ok "A4 : .patch présent et réapplicable (patch -o sur la version posée redonne la version du lab)" \
                  || ko "A4 : .patch absent ou non réapplicable"
else
  ko "A4 : patch(1) introuvable — réapplication non vérifiable"
fi
if cmp -s "$LAB/$NESTED" "$T/cache/v2/fixmod/skills/nested/SKILL.md" && cmp -s "$LAB/$DATA" "$T/cache/v2/fixmod/scripts/fixdata.txt"; then
  ok "A5 : le moteur pose TOUJOURS la version du cache (fichiers posés == v2)"
else
  ko "A5 : fichiers posés != v2"
fi

# ---------------------------------------------------------------------------
# B — aucune modification locale : silence total.
# ---------------------------------------------------------------------------
LAB="$(newlab labB)"
eng "$LAB" "$T/cache/v2" update fixmod
if ! "$GREP" -qF 'local-patches' "$T/err" && ! "$GREP" -qF 'patch local' "$T/out" \
   && [ -z "$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)" ]; then
  ok "B : fichier non modifié localement — aucune ligne, aucun dossier local-patches-*"
else
  ko "B : alerte ou dossier sur un lab non modifié — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
fi

# ---------------------------------------------------------------------------
# C — --dry-run : [plan] ! pour le fichier modifié, aucune écriture.
# ---------------------------------------------------------------------------
LAB="$(newlab labC)"
printf 'PATCH LOCAL du lab\n' >> "$LAB/$NESTED"
(cd "$LAB" && find . -type f | LC_ALL=C sort) > "$T/c-before.lst"
( cd "$LAB" && find . -type f -exec cksum {} + | LC_ALL=C sort ) > "$T/c-before.ck"
eng "$LAB" "$T/cache/v2" --dry-run update fixmod
(cd "$LAB" && find . -type f | LC_ALL=C sort) > "$T/c-after.lst"
( cd "$LAB" && find . -type f -exec cksum {} + | LC_ALL=C sort ) > "$T/c-after.ck"
C_N="$("$GREP" -c '^\[plan\] ! ' "$T/out" || true)"
if [ "$C_N" = "1" ] && "$GREP" -q '^\[plan\] ! .*skills/nested/SKILL.md  (patch local)$' "$T/out"; then
  ok "C1 : dry-run — [plan] ! annoncé pour le seul fichier modifié"
else
  ko "C1 : [plan] ! attendu 1 fois sur skills/nested/SKILL.md ; obtenu $C_N : $("$GREP" -F '[plan] !' "$T/out" | head -3 | tr '\n' '|')"
fi
if cmp -s "$T/c-before.lst" "$T/c-after.lst" && cmp -s "$T/c-before.ck" "$T/c-after.ck" \
   && [ -z "$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)" ] && ! "$GREP" -qF '[local-patches]' "$T/err"; then
  ok "C2 : dry-run — aucune écriture (liste et sommes du lab identiques, ni sauvegarde ni patch ni annonce)"
else
  ko "C2 : le dry-run a écrit (liste ou contenu différents, ou dossier local-patches-*)"
fi

# ---------------------------------------------------------------------------
# D — premier passage sans empreintes : repli sur le cache de l'ancienne version.
# ---------------------------------------------------------------------------
LAB="$(newlab labD)"
rm -f "$LAB/.claude/scripts/.vibeflow-sha256-fixmod"
printf 'PATCH LOCAL du lab\n' >> "$LAB/$NESTED"
eng "$LAB" "$T/cache/v2" update fixmod
if "$GREP" -qF '[local-patches] 1 fichier(s)' "$T/err" && "$GREP" -qxF "[vibeflow-update]   skills/nested/SKILL.md" "$T/err" \
   && [ -f "$(ls -d "$LAB"/.claude/.backups/local-patches-*)/skills/nested/SKILL.md" ]; then
  ok "D1 : sans empreintes, repli sur le cache de l'ancienne version — patch détecté"
else
  ko "D1 : repli sur l'ancien cache sans effet — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
fi
# D2 : ni empreintes ni ancien cache : on ne conclut rien (jamais un faux « inchangé » ni une alerte).
LAB="$(newlab labD2)"
rm -f "$LAB/.claude/scripts/.vibeflow-sha256-fixmod"
printf 'PATCH LOCAL du lab\n' >> "$LAB/$NESTED"
mkdir -p "$T/cache2"; cp -R "$T/cache/v2" "$T/cache2/v2"
eng "$LAB" "$T/cache2/v2" update fixmod
if [ "$("$GREP" -cF '[local-patches] fixmod : aucune référence connue, détection non concluante à cette pose' "$T/err" || true)" = "1" ] \
   && ! "$GREP" -qF 'fichier(s) modifié(s)' "$T/err" && [ -z "$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)" ] \
   && cmp -s "$LAB/$NESTED" "$T/cache/v2/fixmod/skills/nested/SKILL.md"; then
  ok "D2 : sans empreintes ni ancien cache — aucune conclusion, UNE ligne « aucune référence connue », aucune sauvegarde, pose normale"
else
  ko "D2 : ligne « aucune référence connue » absente ou dupliquée, ou alerte/dossier alors qu'aucune référence n'existe — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
fi

# ---------------------------------------------------------------------------
# E — aucun outil sha256 : une ligne d'indisponibilité, pas de crash.
# ---------------------------------------------------------------------------
FAKEBIN="$T/fakebin"; mkdir -p "$FAKEBIN"
REALPY="$(command -v python3)"
printf '#!/bin/sh\nexit 127\n' > "$FAKEBIN/sha256sum"; cp "$FAKEBIN/sha256sum" "$FAKEBIN/shasum"
printf '#!/bin/sh\ncase "$*" in *hashlib*) exit 127;; esac\nexec "%s" "$@"\n' "$REALPY" > "$FAKEBIN/python3"
chmod +x "$FAKEBIN/sha256sum" "$FAKEBIN/shasum" "$FAKEBIN/python3"
LAB="$T/labE"; mkdir -p "$LAB"
(cd "$LAB" && PATH="$FAKEBIN:$PATH" VF_SCOPE=project VIBEFLOW_CACHE="$T/cache/v1" bash "$INSTALLER" install fixmod) >"$T/out" 2>"$T/err"
E_RC1=$?
printf 'PATCH LOCAL du lab\n' >> "$LAB/$NESTED"
(cd "$LAB" && PATH="$FAKEBIN:$PATH" VF_SCOPE=project VIBEFLOW_CACHE="$T/cache/v2" bash "$INSTALLER" update fixmod) >"$T/out" 2>"$T/err"
E_RC2=$?
E_N="$("$GREP" -c 'détection des patches locaux indisponible : aucun outil sha256' "$T/err" || true)"
if [ "$E_RC1" -eq 0 ] && [ "$E_RC2" -eq 0 ] && [ "$E_N" = "1" ] && ! "$GREP" -qF '[local-patches]' "$T/err" \
   && [ ! -f "$LAB/.claude/scripts/.vibeflow-sha256-fixmod" ] \
   && cmp -s "$LAB/$NESTED" "$T/cache/v2/fixmod/skills/nested/SKILL.md"; then
  ok "E : sans outil sha256 — ligne d'indisponibilité unique, pas de crash, aucune empreinte, pose normale"
else
  ko "E : rc=$E_RC1/$E_RC2 ligne=$E_N (attendu 0/0 et 1) — $(head -3 "$T/err" | tr '\n' '|')"
fi

# ---------------------------------------------------------------------------
# F — modifié localement, mais identique au nouveau fichier : rien à perdre, rien à dire.
# ---------------------------------------------------------------------------
LAB="$(newlab labF)"
cp "$T/cache/v2/fixmod/skills/nested/SKILL.md" "$LAB/$NESTED"
eng "$LAB" "$T/cache/v2" update fixmod
if ! "$GREP" -qF 'local-patches' "$T/err" && [ -z "$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)" ]; then
  ok "F : fichier du lab déjà identique au nouveau — aucune ligne"
else
  ko "F : alerte alors que lab == nouveau"
fi

# ---------------------------------------------------------------------------
# G — fichier d'empreintes : contenu exact, tri, jamais lu comme manifeste.
# ---------------------------------------------------------------------------
LAB="$(newlab labG)"
SHAF="$LAB/.claude/scripts/.vibeflow-sha256-fixmod"
MANIF="$LAB/.claude/scripts/.vibeflow-manifest-fixmod"
G_BAD=""
[ -f "$SHAF" ] || G_BAD="fichier d'empreintes absent ; "
[ -f "$MANIF" ] || G_BAD="${G_BAD}manifeste absent ; "
if [ -z "$G_BAD" ]; then
  awk '{print substr($0,67)}' "$SHAF" | LC_ALL=C sort > "$T/g-sha.paths"
  LC_ALL=C sort "$MANIF" > "$T/g-man.paths"
  [ -z "$(comm -23 "$T/g-man.paths" "$T/g-sha.paths")$(comm -13 "$T/g-man.paths" "$T/g-sha.paths")" ] \
    || G_BAD="${G_BAD}chemins des empreintes != manifeste ; "
  while IFS= read -r line; do
    h="${line%%  *}"; p="${line#*  }"
    [ "$h" = "$(sha_of "$LAB/.claude/$p")" ] || G_BAD="${G_BAD}empreinte fausse pour $p ; "
  done < "$SHAF"
  LC_ALL=C sort -c "$SHAF" 2>/dev/null || G_BAD="${G_BAD}non trié LC_ALL=C ; "
  [ "$(wc -l < "$SHAF" | tr -d ' ')" -ge 4 ] || G_BAD="${G_BAD}moins de 4 lignes ; "
  "$GREP" -q 'vibeflow-sha256\|vibeflow-manifest' "$SHAF" && G_BAD="${G_BAD}le fichier d'empreintes se consigne lui-même ; "
fi
[ -z "$G_BAD" ] && ok "G1 : une empreinte exacte par fichier posé, mêmes chemins que le manifeste, trié LC_ALL=C" \
                || ko "G1 : $G_BAD"
# Jamais un manifeste : le glob du manifeste ne le voit pas, le registre n'a qu'un module, et un
# update qui retire un fichier (v3 sans fixdata.txt) converge sans rien traiter de faux.
mk_cache "$T/cache/v3" "1.2.0"; rm -f "$T/cache/v3/fixmod/scripts/fixdata.txt"
eng "$LAB" "$T/cache/v3" update fixmod
G2_RC=$?
G2_GLOB="$(cd "$LAB/.claude/scripts" && ls -A | "$GREP" '^\.vibeflow-manifest-' | tr '\n' ' ')"
if [ "$G2_RC" -eq 0 ] && [ "$G2_GLOB" = ".vibeflow-manifest-fixmod " ] \
   && [ "$(cat "$LAB/.claude/scripts/.vibeflow-installed")" = "fixmod=1.2.0" ] \
   && [ ! -f "$LAB/$DATA" ] && ! "$GREP" -q 'fixdata' "$SHAF" && "$GREP" -q 'skills/nested/SKILL.md' "$SHAF" \
   && ! "$GREP" -qiE 'imparsable|fantôme|ERROR' "$T/err"; then
  ok "G2 : le fichier d'empreintes n'est lu ni comme manifeste ni comme module (update + convergence propres, empreintes à jour)"
else
  ko "G2 : rc=$G2_RC glob=[$G2_GLOB] registre=[$(cat "$LAB/.claude/scripts/.vibeflow-installed")] — $(head -3 "$T/err" | tr '\n' '|')"
fi

# ---------------------------------------------------------------------------
# H — désinstallation : les empreintes partent avec le manifeste.
# ---------------------------------------------------------------------------
eng "$LAB" "$T/cache/v3" uninstall fixmod
if [ ! -f "$SHAF" ] && [ ! -f "$MANIF" ]; then
  ok "H : uninstall retire le fichier d'empreintes avec le manifeste"
else
  ko "H : empreintes ou manifeste survivent à la désinstallation"
fi

# ---------------------------------------------------------------------------
# I — sous --target : le contenu posé est réécrit ; l'empreinte est celle du fichier posé.
# ---------------------------------------------------------------------------
mk_cache "$T/ct/v1" "1.0.0"; mk_cache "$T/ct/v2" "1.1.0"
printf 'voir .claude/rules/x.md\nversion 1\n' > "$T/ct/v1/fixmod/skills/nested/references/ref.md"
printf 'voir .claude/rules/x.md\nversion 2\n' > "$T/ct/v2/fixmod/skills/nested/references/ref.md"
LABI="$T/labI"; mkdir -p "$LABI"; TGT="$T/custom-target"
(cd "$LABI" && VIBEFLOW_CACHE="$T/ct/v1" bash "$INSTALLER" --target "$TGT" install fixmod) >"$T/out" 2>"$T/err"
I_REF="$TGT/skills/nested/references/ref.md"
I_REC="$("$GREP" -F '  skills/nested/references/ref.md' "$TGT/scripts/.vibeflow-sha256-fixmod" | cut -c1-64)"
if [ -f "$I_REF" ] && ! "$GREP" -qF '.claude/rules' "$I_REF" && [ -n "$I_REC" ] && [ "$I_REC" = "$(sha_of "$I_REF")" ]; then
  ok "I1 : sous --target, l'empreinte enregistrée est celle du fichier réécrit réellement posé"
else
  ko "I1 : réécriture absente ou empreinte != fichier posé (rec=[$I_REC])"
fi
(cd "$LABI" && VIBEFLOW_CACHE="$T/ct/v2" bash "$INSTALLER" --target "$TGT" update fixmod) >"$T/out" 2>"$T/err"
if ! "$GREP" -qF 'local-patches' "$T/err" && [ -z "$(ls -d "$TGT"/.backups/local-patches-* 2>/dev/null)" ]; then
  ok "I2 : sous --target, update sans modification locale — aucune fausse alerte"
else
  ko "I2 : fausse alerte sous --target — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
fi
printf 'PATCH LOCAL du lab\n' >> "$TGT/skills/nested/references/ref.md"
mk_cache "$T/ct/v3" "1.2.0"; printf 'voir .claude/rules/x.md\nversion 3\n' > "$T/ct/v3/fixmod/skills/nested/references/ref.md"
(cd "$LABI" && VIBEFLOW_CACHE="$T/ct/v3" bash "$INSTALLER" --target "$TGT" update fixmod) >"$T/out" 2>"$T/err"
if "$GREP" -qF '[local-patches] 1 fichier(s)' "$T/err"; then
  ok "I3 : sous --target, une vraie modification locale est détectée"
else
  ko "I3 : modification locale non détectée sous --target"
fi

# ---------------------------------------------------------------------------
# J — `update --all` sur deux modules : une seule annonce, un seul dossier, N cumulé.
# ---------------------------------------------------------------------------
mk_other() {
  local d="$1" v="$2"
  mkdir -p "$d/other/skills/other-skill" "$d/other/scripts"
  printf '%s\n' "$v" > "$d/other/VERSION"
  printf '{"name":"other","version":"%s"}\n' "$v" > "$d/other/module.json"
  printf 'autre skill, version %s\n' "$v" > "$d/other/skills/other-skill/SKILL.md"
  printf '#!/usr/bin/env bash\necho other\n' > "$d/other/scripts/other.sh"
}
mk_cache "$T/mm/v1" "1.0.0"; mk_other "$T/mm/v1" "1.0.0"
mk_cache "$T/mm/v2" "1.1.0"; mk_other "$T/mm/v2" "1.1.0"
LABJ="$T/labJ"; mkdir -p "$LABJ"
eng "$LABJ" "$T/mm/v1" install fixmod; eng "$LABJ" "$T/mm/v1" install other
printf 'PATCH LOCAL du lab\n' >> "$LABJ/$NESTED"
printf 'PATCH LOCAL du lab\n' >> "$LABJ/.claude/skills/other-skill/SKILL.md"
eng "$LABJ" "$T/mm/v2" update --all
J_N="$("$GREP" -c '\[local-patches\] ' "$T/err" || true)"
J_D="$(ls -d "$LABJ"/.claude/.backups/local-patches-* 2>/dev/null | wc -l | tr -d ' ')"
if [ "$J_N" = "1" ] && [ "$J_D" = "1" ] && "$GREP" -qF '[local-patches] 2 fichier(s)' "$T/err" \
   && "$GREP" -qxF "[vibeflow-update]   skills/other-skill/SKILL.md" "$T/err" && "$GREP" -qxF "[vibeflow-update]   skills/nested/SKILL.md" "$T/err"; then
  ok "J : update --all multi-modules — une annonce (N=2 cumulé), un dossier de sauvegarde"
else
  ko "J : annonces=$J_N dossiers=$J_D (attendu 1 et 1, N=2) — $("$GREP" -F 'local-patches' "$T/err" | head -3 | tr '\n' '|')"
fi

# ===========================================================================
# Revue du lot D (#166) — F1 à F7 et D2. Chaque cas ROUGIT sur le moteur de d9689ad6
# (VF_LP_TEST_ENGINE=<ce moteur>) et VERDIT après correction.
# ===========================================================================

# engs <scope> <lab> <cache> <args…> — comme eng, avec un scope au choix (stdout dans $T/out, stderr dans $T/err).
engs() {
  local scope="$1" lab="$2" cache="$3"; shift 3
  (cd "$lab" && VF_SCOPE="$scope" VIBEFLOW_CACHE="$cache" bash "$INSTALLER" "$@") >"$T/out" 2>"$T/err"
}
# mk_mod <dossier de cache> <module> <version> — module à scripts/, données, tests et fixture de tests.
mk_mod() {
  local d="$1" m="$2" v="$3"
  mkdir -p "$d/$m/scripts/tests/fixtures"
  printf '%s\n' "$v" > "$d/$m/VERSION"
  printf '{"name":"%s","version":"%s"}\n' "$m" "$v" > "$d/$m/module.json"
  printf '#!/usr/bin/env bash\necho %s\n' "$m" > "$d/$m/scripts/$m.sh"
  printf 'data %s %s\n' "$m" "$v" > "$d/$m/scripts/$m-data.txt"
  printf '#!/usr/bin/env bash\necho test %s\n' "$m" > "$d/$m/scripts/tests/t-$m.sh"
  printf 'fixture %s\n' "$m" > "$d/$m/scripts/tests/fixtures/f-$m.txt"
}
# lp_count <motif> <fichier> — nombre de lignes qui contiennent le motif (littéral), 0 si aucune.
lp_count() { "$GREP" -cF -- "$1" "$2" || true; }
INJECTOR="$INTERNAL_DIR/../dev-orchestrator/scripts/inject-mcp-tools.sh"

# ---------------------------------------------------------------------------
# K — F1 : l'injection MCP du moteur n'est JAMAIS un patch local. Agents `vf-mcp-consumer` + .mcp.json.
# ---------------------------------------------------------------------------
mk_ag() { # <cache> <version> <module…> — agents exécutants ; l'injecteur est livré par le premier module
  local d="$1" v="$2" first=1 m; shift 2
  for m in "$@"; do
    mkdir -p "$d/$m/scripts"
    printf '%s\n' "$v" > "$d/$m/VERSION"
    printf '{"name":"%s","version":"%s"}\n' "$m" "$v" > "$d/$m/module.json"
    printf -- '---\nname: %s\ndescription: x\nmodel: sonnet\nmemory: project\nvf-mcp-consumer: true\ntools: Read, Bash\n---\ncorps v%s\n' "$m" "$v" > "$d/$m/AGENT.md"
    if [ "$first" -eq 1 ]; then cp "$INJECTOR" "$d/$m/scripts/inject-mcp-tools.sh"; first=0; fi
  done
}
if [ -f "$INJECTOR" ]; then
  mk_ag "$T/ag/v1" 1.0.0 agm bgm; mk_ag "$T/ag/v2" 1.1.0 agm bgm
  one_mcp='{"mcpServers":{"foo":{"command":"x"}}}'
  two_mcp='{"mcpServers":{"foo":{"command":"x"},"bar":{"command":"y"}}}'
  newag() { # <nom> <modules…> — lab avec .mcp.json (foo) et les modules en v1
    local lab="$T/$1" m; shift
    mkdir -p "$lab"; printf '%s\n' "$one_mcp" > "$lab/.mcp.json"
    for m in "$@"; do eng "$lab" "$T/ag/v1" install "$m" || ko "agents : install $m en échec (fixture morte)"; done
    printf '%s' "$lab"
  }
  AGENT=".claude/agents/agm.md"
  # K1 : premier passage (aucune empreinte), agent injecté, aucun changement local.
  LAB="$(newag labK1 agm)"
  "$GREP" -q 'mcp__foo__' "$LAB/$AGENT" || ko "K1 : fixture morte — l'agent installé ne porte pas mcp__foo__"
  rm -f "$LAB/.claude/scripts/.vibeflow-sha256-agm"
  eng "$LAB" "$T/ag/v2" update agm
  if ! "$GREP" -qF 'local-patches' "$T/err" && [ -z "$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)" ]; then
    ok "K1 : premier passage sur un agent injecté — la référence de repli passe par l'injecteur, aucune fausse alerte"
  else
    ko "K1 : fausse alerte sur l'injection MCP au premier passage — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
  fi
  # K2 : le jeu MCP change entre deux passages (empreinte présente).
  LAB="$(newag labK2 agm)"
  printf '%s\n' "$two_mcp" > "$LAB/.mcp.json"
  eng "$LAB" "$T/ag/v2" update agm
  if ! "$GREP" -qF 'local-patches' "$T/err" && "$GREP" -q 'mcp__bar__' "$LAB/$AGENT"; then
    ok "K2 : le jeu MCP a changé entre deux passages — l'agent reçoit le nouveau serveur, aucune fausse alerte"
  else
    ko "K2 : fausse alerte ou injection absente après changement du jeu MCP — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
  fi
  # K3 : update --all multi-modules — l'injection faite pendant le 1er module réécrit l'agent du 2e.
  LAB="$(newag labK3 agm bgm)"
  printf '%s\n' "$two_mcp" > "$LAB/.mcp.json"
  eng "$LAB" "$T/ag/v2" update --all
  if ! "$GREP" -qF 'local-patches' "$T/err" && "$GREP" -q 'mcp__bar__' "$LAB/.claude/agents/bgm.md"; then
    ok "K3 : update --all — l'injection du 1er module n'accuse pas l'agent du 2e (empreintes rafraîchies)"
  else
    ko "K3 : fausse alerte inter-modules — $("$GREP" -F 'local-patches' "$T/err" | head -3 | tr '\n' '|')"
  fi
  # K4 (témoin) : un VRAI patch local sur un agent injecté reste détecté — avec empreinte, puis au premier passage.
  LAB="$(newag labK4 agm)"
  printf 'LIGNE LOCALE\n' >> "$LAB/$AGENT"
  eng "$LAB" "$T/ag/v2" update agm
  K4_BK="$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)"
  if "$GREP" -qF '[local-patches] 1 fichier(s)' "$T/err" && "$GREP" -qxF "[vibeflow-update]   agents/agm.md" "$T/err" \
     && [ -n "$K4_BK" ] && "$GREP" -q '^+LIGNE LOCALE' "$K4_BK/agents/agm.md.patch" && ! "$GREP" -q '^[-+].*mcp__' "$K4_BK/agents/agm.md.patch"; then
    ok "K4a : vrai patch local sur un agent injecté détecté (empreinte) ; le .patch ne porte que la ligne locale, pas le bruit d'injection"
  else
    ko "K4a : patch local sur un agent injecté non détecté, ou .patch pollué par l'injection — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
  fi
  LAB="$(newag labK4b agm)"
  printf 'LIGNE LOCALE\n' >> "$LAB/$AGENT"
  rm -f "$LAB/.claude/scripts/.vibeflow-sha256-agm"
  eng "$LAB" "$T/ag/v2" update agm
  if "$GREP" -qF '[local-patches] 1 fichier(s)' "$T/err" && "$GREP" -qxF "[vibeflow-update]   agents/agm.md" "$T/err"; then
    ok "K4b : vrai patch local sur un agent injecté détecté au premier passage (repli sur l'ancien cache)"
  else
    ko "K4b : patch local non détecté au premier passage — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
  fi
  # K5 (témoin) : l'agent du 2e module porte un patch local ET le 1er module réécrit tous les agents — le patch
  # n'est pas absorbé par le rafraîchissement des empreintes.
  LAB="$(newag labK5 agm bgm)"
  printf 'LIGNE LOCALE\n' >> "$LAB/.claude/agents/bgm.md"
  printf '%s\n' "$two_mcp" > "$LAB/.mcp.json"
  eng "$LAB" "$T/ag/v2" update --all
  if "$GREP" -qF '[local-patches] 1 fichier(s)' "$T/err" && "$GREP" -qxF "[vibeflow-update]   agents/bgm.md" "$T/err"; then
    ok "K5 : update --all — le patch local de l'agent du 2e module survit à l'injection du 1er (non absorbé par le rafraîchissement)"
  else
    ko "K5 : patch local absorbé par l'injection inter-modules — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
  fi
else
  ko "K : injecteur MCP introuvable ($INJECTOR) — fixture morte"
fi

# ---------------------------------------------------------------------------
# L — F2 : `[plan] !` si et seulement si la pose réelle sauvegarde, quel que soit l'ordre des modules ; aucun
#      état ne fuit d'un module au suivant. Un module change de version, un autre reste à version égale
#      (resync), un troisième n'est pas modifié ; deux ordres.
# ---------------------------------------------------------------------------
l_scenario() { # <tag> <module qui change> <module à version égale> <module intact>
  local tag="$1" chg="$2" eq="$3" idle="$4" c lab m
  for c in v1 v2; do
    mk_mod "$T/L$tag/$c" "$chg" "$([ "$c" = v1 ] && echo 1.0.0 || echo 1.1.0)"
    mk_mod "$T/L$tag/$c" "$eq" 1.0.0; mk_mod "$T/L$tag/$c" "$idle" 1.0.0
  done
  lab="$T/labL$tag"; mkdir -p "$lab"
  for m in "$chg" "$eq" "$idle"; do eng "$lab" "$T/L$tag/v1" install "$m" || ko "L$tag : install $m en échec"; done
  printf 'PATCH LOCAL\n' >> "$lab/.claude/scripts/$chg-data.txt"
  printf 'PATCH LOCAL\n' >> "$lab/.claude/scripts/$eq-data.txt"
  eng "$lab" "$T/L$tag/v2" --dry-run update --all
  "$GREP" '^\[plan\] ! ' "$T/out" | sed -e 's#^\[plan\] ! \./\.claude/##' -e 's#  (patch local)$##' | LC_ALL=C sort > "$T/l$tag-plan"
  eng "$lab" "$T/L$tag/v2" update --all
  "$GREP" -E '^\[vibeflow-update\]   (scripts|skills|agents)/' "$T/err" | sed 's#^\[vibeflow-update\]   ##' | LC_ALL=C sort > "$T/l$tag-real"
  printf '%s\n%s\n' "scripts/$chg-data.txt" "scripts/$eq-data.txt" | LC_ALL=C sort > "$T/l$tag-want"
  if [ -s "$T/l$tag-want" ] && [ -z "$(comm -3 "$T/l$tag-plan" "$T/l$tag-want")" ] && [ -z "$(comm -3 "$T/l$tag-real" "$T/l$tag-want")" ]; then
    ok "L$tag : le plan (dry-run) annonce exactement ce que la pose sauvegarde ($chg change, $eq à version égale ; $idle intact, aucune ligne)"
  else
    ko "L$tag : plan et pose divergent — plan=[$(tr '\n' ' ' < "$T/l$tag-plan")] pose=[$(tr '\n' ' ' < "$T/l$tag-real")] attendu=[$(tr '\n' ' ' < "$T/l$tag-want")]"
  fi
}
l_scenario 1 ma mb mc
l_scenario 2 mb ma mc

# ---------------------------------------------------------------------------
# M — F3 : la pose à version égale (resync, à CHAQUE /vf-update) est couverte comme les autres : détection,
#      sauvegarde, .patch, annonce ; les empreintes des fichiers reposés sont mises à jour (pas de fausse
#      alerte au passage suivant) ; sans aucune référence : UNE ligne par module, aucune sauvegarde spéculative (D2).
# ---------------------------------------------------------------------------
mk_mod "$T/eq/v1" eqm 1.0.0
LAB="$T/labM"; mkdir -p "$LAB"; eng "$LAB" "$T/eq/v1" install eqm
printf 'PATCH LOCAL\n' >> "$LAB/.claude/scripts/eqm-data.txt"
printf 'PATCH LOCAL\n' >> "$LAB/.claude/scripts/tests/t-eqm.sh"
printf 'PATCH LOCAL\n' >> "$LAB/.claude/scripts/tests/fixtures/f-eqm.txt"
cp "$LAB/.claude/scripts/eqm-data.txt" "$T/m-data.lab"
eng "$LAB" "$T/eq/v1" update eqm
M_BK="$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)"
if "$GREP" -qF '[local-patches] 3 fichier(s)' "$T/err" && [ -n "$M_BK" ] && cmp -s "$M_BK/scripts/eqm-data.txt" "$T/m-data.lab" \
   && [ -f "$M_BK/scripts/eqm-data.txt.patch" ] && [ -f "$M_BK/scripts/tests/t-eqm.sh" ] && [ -f "$M_BK/scripts/tests/fixtures/f-eqm.txt" ] \
   && cmp -s "$LAB/.claude/scripts/eqm-data.txt" "$T/eq/v1/eqm/scripts/eqm-data.txt"; then
  ok "M1 : resync à version égale — données, test et fixture modifiés : annonce (3), sauvegardes, .patch, fichiers reposés"
else
  ko "M1 : resync à version égale non couverte — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|') backup=[$M_BK]"
fi
eng "$LAB" "$T/eq/v1" update eqm
M_REC="$("$GREP" -F '  scripts/eqm-data.txt' "$LAB/.claude/scripts/.vibeflow-sha256-eqm" | cut -c1-64)"
if ! "$GREP" -qF 'local-patches' "$T/err" && [ -n "$M_REC" ] && [ "$M_REC" = "$(sha_of "$LAB/.claude/scripts/eqm-data.txt")" ]; then
  ok "M2 : les empreintes des fichiers reposés par la resync sont à jour — le passage suivant est silencieux"
else
  ko "M2 : fausse alerte au passage suivant ou empreinte périmée (rec=[$M_REC]) — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
fi
# D2 : ni empreintes ni ancien cache : une seule ligne par module, pas de sauvegarde, empreintes créées pour la suite.
rm -f "$LAB/.claude/scripts/.vibeflow-sha256-eqm"; rm -rf "$LAB/.claude/.backups"
printf 'PATCH LOCAL\n' >> "$LAB/.claude/scripts/eqm-data.txt"; printf 'PATCH LOCAL\n' >> "$LAB/.claude/scripts/tests/t-eqm.sh"
eng "$LAB" "$T/eq/v1" update eqm
D2_LINE="[local-patches] eqm : aucune référence connue, détection non concluante à cette pose"
if [ "$(lp_count "$D2_LINE" "$T/err")" = "1" ] && ! "$GREP" -qF 'fichier(s) modifié(s)' "$T/err" \
   && [ -z "$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)" ] && [ -f "$LAB/.claude/scripts/.vibeflow-sha256-eqm" ]; then
  ok "D2a : aucune référence — UNE ligne pour le module (2 fichiers différents), aucune sauvegarde spéculative, empreintes créées"
else
  ko "D2a : ligne attendue 1 fois ('$D2_LINE') ; obtenu $(lp_count "$D2_LINE" "$T/err") — $("$GREP" -F 'local-patches' "$T/err" | head -3 | tr '\n' '|')"
fi
eng "$LAB" "$T/eq/v1" update eqm
if ! "$GREP" -qF 'local-patches' "$T/err"; then
  ok "D2b : une fois les empreintes créées, la ligne « aucune référence » ne revient plus"
else
  ko "D2b : la ligne « aucune référence » revient — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
fi

# ---------------------------------------------------------------------------
# N — F4 : l'annonce sort UNE fois sur toute sortie qui suit un écrasement, abort compris, sans changer le code
#      de sortie ; le retry ne la répète pas. Abort : hooks.json invalide dans la nouvelle version.
# ---------------------------------------------------------------------------
mk_ab() { # <cache> <version> <hooks valides 1|0>
  local d="$1" v="$2" ok_hooks="$3"
  mkdir -p "$d/abm/scripts" "$d/abm/hooks"
  printf '%s\n' "$v" > "$d/abm/VERSION"; printf '{"name":"abm","version":"%s"}\n' "$v" > "$d/abm/module.json"
  printf 'data abm %s\n' "$v" > "$d/abm/scripts/abm-data.txt"
  if [ "$ok_hooks" = 1 ]; then
    printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash {{VF_SCRIPTS}}/abm-data.txt"}]}]}}\n' > "$d/abm/hooks/hooks.json"
  else
    printf '{ pas du json\n' > "$d/abm/hooks/hooks.json"
  fi
}
mk_ab "$T/ab/v1" 1.0.0 1; mk_ab "$T/ab/v2" 1.1.0 0
LAB="$T/labN0"; mkdir -p "$LAB"; eng "$LAB" "$T/ab/v1" install abm
eng "$LAB" "$T/ab/v2" update abm; N0_RC=$?        # témoin : même abort SANS patch local
LAB="$T/labN"; mkdir -p "$LAB"; eng "$LAB" "$T/ab/v1" install abm
printf 'PATCH LOCAL\n' >> "$LAB/.claude/scripts/abm-data.txt"
eng "$LAB" "$T/ab/v2" update abm; N_RC=$?
N_BK="$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)"
N_ANN="$("$GREP" -cF '[local-patches] 1 fichier(s)' "$T/err" || true)"
eng "$LAB" "$T/ab/v2" update abm
N_RETRY="$("$GREP" -cF 'local-patches' "$T/err" || true)"
if [ "$N0_RC" -ne 0 ] && [ "$N_RC" -eq "$N0_RC" ] && [ "$N_ANN" = "1" ] && [ -n "$N_BK" ] && [ "$N_RETRY" = "0" ]; then
  ok "N : abort après écrasement — annonce émise UNE fois, code de sortie inchangé ($N_RC = témoin sans patch), retry silencieux"
else
  ko "N : rc=$N_RC (témoin $N0_RC) annonces=$N_ANN (attendu 1) retry=$N_RETRY (attendu 0) backup=[$N_BK]"
fi
EXIT_TRAPS="$("$GREP" -cE '^[[:space:]]*trap .*[[:space:]]EXIT' "$INSTALLER" || true)"
if [ "$EXIT_TRAPS" = "1" ]; then
  ok "N2 : un seul trap EXIT dans le moteur (il n'en remplace ni n'en empile aucun)"
else
  ko "N2 : $EXIT_TRAPS trap EXIT dans le moteur (attendu exactement 1)"
fi

# ---------------------------------------------------------------------------
# O — F6 : le fichier d'empreintes est un état propre à la machine : une règle unique dans ./.gitignore en scope
#      project ET local ; rien en scope user ni sous --target.
# ---------------------------------------------------------------------------
GI_RULE='.claude/scripts/.vibeflow-sha256-*'
for sc in project local; do
  LAB="$T/labO-$sc"; mkdir -p "$LAB"
  # Dernière ligne SANS fin de ligne en project ; avec en local (gitignore_add_one, préexistant et hors périmètre,
  # n'ajoute pas de fin de ligne : il collerait la première règle du module à la ligne de l'utilisateur).
  if [ "$sc" = project ]; then printf 'node_modules' > "$LAB/.gitignore"; else printf 'node_modules\n' > "$LAB/.gitignore"; fi
  engs "$sc" "$LAB" "$T/cache/v1" install fixmod
  engs "$sc" "$LAB" "$T/cache/v2" update fixmod
  O_N="$("$GREP" -cxF "$GI_RULE" "$LAB/.gitignore" || true)"
  if [ "$O_N" = "1" ] && "$GREP" -qxF 'node_modules' "$LAB/.gitignore"; then
    ok "O-$sc : la règle d'ignorance du fichier d'empreintes est posée exactement une fois (install puis update), ligne préexistante intacte"
  else
    ko "O-$sc : règle présente $O_N fois (attendu 1) — $(tr '\n' '|' < "$LAB/.gitignore")"
  fi
done
LAB="$T/labO-git"; mkdir -p "$LAB"
if command -v git >/dev/null 2>&1 && (cd "$LAB" && git init -q . 2>/dev/null); then
  engs project "$LAB" "$T/cache/v1" install fixmod
  if (cd "$LAB" && git check-ignore -q .claude/scripts/.vibeflow-sha256-fixmod); then
    ok "O-git : git ignore bien .claude/scripts/.vibeflow-sha256-fixmod (scope project)"
  else
    ko "O-git : git n'ignore pas le fichier d'empreintes en scope project"
  fi
else
  echo "  (O-git : git indisponible, non vérifié)"
fi
LAB="$T/labO-user"; mkdir -p "$LAB"
engs user "$LAB" "$T/cache/v1" install fixmod
LAB2="$T/labO-tgt"; mkdir -p "$LAB2"
(cd "$LAB2" && VF_SCOPE=project VIBEFLOW_CACHE="$T/cache/v1" bash "$INSTALLER" --target "$T/o-target" install fixmod) >"$T/out" 2>"$T/err"
if [ ! -e "$LAB/.gitignore" ] && [ ! -e "$LAB2/.gitignore" ] \
   && [ -f "$HOME/.claude/scripts/.vibeflow-sha256-fixmod" ] && [ -f "$T/o-target/scripts/.vibeflow-sha256-fixmod" ]; then
  ok "O-user/--target : aucune règle ni .gitignore en scope user ni sous --target (les fichiers d'empreintes existent bien)"
else
  ko "O-user/--target : .gitignore créé hors project/local, ou fichier d'empreintes absent"
fi
LAB="$T/labO-dry"; mkdir -p "$LAB"
engs project "$LAB" "$T/cache/v1" --dry-run install fixmod
if "$GREP" -qF "[plan] ~ ./.gitignore  $GI_RULE" "$T/out" && [ ! -e "$LAB/.gitignore" ]; then
  ok "O-dry : --dry-run annonce la règle d'ignorance sans écrire de .gitignore"
else
  ko "O-dry : règle absente du plan ou .gitignore écrit en dry-run"
fi

# ---------------------------------------------------------------------------
# P — F7 : le cas nominal (aucun patch local) ne hache pas par fichier. Un faux sha256sum compte ses appels ;
#      le nombre d'appels d'une pose est le même pour 20 fichiers et pour 100.
# ---------------------------------------------------------------------------
SHIM="$T/shim"; mkdir -p "$SHIM"; HLOG="$T/hash.log"
REAL_SHA="$(command -v sha256sum || true)"
printf '#!/bin/sh\necho "$#" >> "%s"\nif [ -n "%s" ]; then exec "%s" "$@"; fi\nexec shasum -a 256 "$@"\n' "$HLOG" "$REAL_SHA" "$REAL_SHA" > "$SHIM/sha256sum"
chmod +x "$SHIM/sha256sum"
mk_big() { # <cache> <version> <n>
  local d="$1" v="$2" n="$3" i=0
  mkdir -p "$d/big/skills/s/references"
  printf '%s\n' "$v" > "$d/big/VERSION"; printf '{"name":"big","version":"%s"}\n' "$v" > "$d/big/module.json"
  printf 'skill %s\n' "$v" > "$d/big/skills/s/SKILL.md"
  while [ "$i" -lt "$n" ]; do printf 'ref %s v%s\n' "$i" "$v" > "$d/big/skills/s/references/r$i.md"; i=$((i+1)); done
}
p_calls() { # <n> — appels du hachage pendant l'install puis l'update de <n> fichiers (un seul chiffre : install,update)
  local n="$1" lab="$T/labP$1" a b
  mk_big "$T/P$n/v1" 1.0.0 "$n"; mk_big "$T/P$n/v2" 1.1.0 "$n"; mkdir -p "$lab"
  : > "$HLOG"
  (cd "$lab" && PATH="$SHIM:$PATH" VF_SCOPE=project VIBEFLOW_CACHE="$T/P$n/v1" bash "$INSTALLER" install big) >"$T/out" 2>"$T/err"
  a="$(wc -l < "$HLOG" | tr -d ' ')"; : > "$HLOG"
  (cd "$lab" && PATH="$SHIM:$PATH" VF_SCOPE=project VIBEFLOW_CACHE="$T/P$n/v2" bash "$INSTALLER" update big) >"$T/out" 2>"$T/err"
  b="$(wc -l < "$HLOG" | tr -d ' ')"
  printf '%s,%s' "$a" "$b"
}
P20="$(p_calls 20)"; P100="$(p_calls 100)"
if [ "$P20" = "$P100" ] && [ "${P20%%,*}" -le 6 ] && [ "${P20##*,}" -le 6 ] && [ "${P20%%,*}" -ge 1 ]; then
  ok "P : hachage par lots — appels install,update = $P20 pour 20 fichiers et $P100 pour 100 (indépendant du nombre de fichiers)"
else
  ko "P : appels de hachage install,update : 20 fichiers → $P20 ; 100 fichiers → $P100 (attendu identiques, ≤ 6 chacun, ≥ 1)"
fi

# ---------------------------------------------------------------------------
# I4 / I5 — F5a : sous --target, repli sur l'ancien cache (aucune empreinte) : la référence est RÉÉCRITE comme la
#      pose réécrit le fichier — sinon l'ancien contenu brut diffère du lab réécrit et alerte à tort.
# ---------------------------------------------------------------------------
LABI="$T/labI4"; mkdir -p "$LABI"; TGT4="$T/custom-target4"
(cd "$LABI" && VIBEFLOW_CACHE="$T/ct/v1" bash "$INSTALLER" --target "$TGT4" install fixmod) >"$T/out" 2>"$T/err"
rm -f "$TGT4/scripts/.vibeflow-sha256-fixmod"
(cd "$LABI" && VIBEFLOW_CACHE="$T/ct/v2" bash "$INSTALLER" --target "$TGT4" update fixmod) >"$T/out" 2>"$T/err"
if ! "$GREP" -qF 'local-patches' "$T/err" && [ -z "$(ls -d "$TGT4"/.backups/local-patches-* 2>/dev/null)" ]; then
  ok "I4 : sous --target, repli sur l'ancien cache — la référence réécrite égale le lab, aucune fausse alerte"
else
  ko "I4 : fausse alerte sous --target au repli — $("$GREP" -F 'local-patches' "$T/err" | head -2 | tr '\n' '|')"
fi
LABI="$T/labI5"; mkdir -p "$LABI"; TGT5="$T/custom-target5"
(cd "$LABI" && VIBEFLOW_CACHE="$T/ct/v1" bash "$INSTALLER" --target "$TGT5" install fixmod) >"$T/out" 2>"$T/err"
rm -f "$TGT5/scripts/.vibeflow-sha256-fixmod"
printf 'PATCH LOCAL du lab\n' >> "$TGT5/skills/nested/references/ref.md"
(cd "$LABI" && VIBEFLOW_CACHE="$T/ct/v2" bash "$INSTALLER" --target "$TGT5" update fixmod) >"$T/out" 2>"$T/err"
if "$GREP" -qF '[local-patches] 1 fichier(s)' "$T/err"; then
  ok "I5 : sous --target, repli sur l'ancien cache — une vraie modification locale est détectée"
else
  ko "I5 : modification locale non détectée sous --target au repli"
fi

echo
echo "== test-local-patches : $pass PASS, $fail FAIL =="
[ "$fail" -eq 0 ] && [ "$pass" -gt 0 ]
