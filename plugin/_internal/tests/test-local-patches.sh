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
#      l'ancienne version ; sans ce cache, aucune conclusion (D2).
#   E  aucun outil sha256 : une ligne d'indisponibilité, pas de crash, pose normale.
#   F  fichier modifié localement mais identique au nouveau : aucune ligne.
#   G  le fichier d'empreintes porte l'empreinte exacte de chaque fichier posé, trié LC_ALL=C, et
#      n'est jamais lu comme un manifeste ni comme un module.
#   H  désinstallation : le fichier d'empreintes disparaît avec le manifeste.
#   I  sous --target (contenu réécrit à la pose) : l'empreinte est celle du fichier RÉELLEMENT posé,
#      donc aucune fausse alerte à l'update suivant.
#   J  `update --all` sur deux modules : une seule annonce, un seul dossier, N cumulé.
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
if ! "$GREP" -qF 'local-patches' "$T/err" && [ -z "$(ls -d "$LAB"/.claude/.backups/local-patches-* 2>/dev/null)" ] \
   && cmp -s "$LAB/$NESTED" "$T/cache/v2/fixmod/skills/nested/SKILL.md"; then
  ok "D2 : sans empreintes ni ancien cache — aucune conclusion, aucune alerte, pose normale"
else
  ko "D2 : alerte ou dossier alors qu'aucune référence n'existe"
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

echo
echo "== test-local-patches : $pass PASS, $fail FAIL =="
[ "$fail" -eq 0 ] && [ "$pass" -gt 0 ]
