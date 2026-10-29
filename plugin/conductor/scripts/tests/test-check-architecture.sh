#!/usr/bin/env bash
# Test de check-architecture.sh (Phase 60, ARCG-06, ARCG-07 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P60-PL-20) : aucun dossier fixtures/ versionné,
# octets CRLF et BOM produits par printf/awk. Le script se retrouve par ../check-architecture.sh, en source
# comme une fois copié à plat par l'engine (la suite se pose sous scripts/tests/). Le gabarit réel se lit à
# planning-core/references/templates/product/ ; introuvable (copie à plat) : SKIP nommé, jamais un vert.
# Cas CARCH-TRACE-1..4 (gabarit brut -> 1, gabarit rempli et validé -> 0, fichier absent -> 1, usage -> 64), CARCH-HELP.
# Cas CARCH-VALIDE, CARCH-PROPOSEE, CARCH-RUBRIQUE (six sous-cas), CARCH-VIDE, CARCH-NUM, CARCH-CRLF, CARCH-BOM,
# CARCH-STATUT, CARCH-FENCE-OUVERTE, CARCH-MIX, CARCH-DESCRIPTIF (ligne d'état, rubriques, corps).
# Cas CARCH-LIEN, CARCH-FIFO, CARCH-DOSSIER, CARCH-GROS, CARCH-ILLISIBLE (refus en 5 avant lecture), CARCH-NOECHO,
# CARCH-EXEC (sans évaluation de chaîne, chemin hostile inerte), CARCH-RO, CARCH-CODES (ensemble observé = {0, 1, 3, 5, 64}).
# Mutants CARCH-MUT-1..9 (QUAL-01) : une ligne du script altérée, chacun différent de l'original (cmp -s), valide
# (bash -n), une seule ligne changée, rouge pour la raison attendue (code attendu/obtenu imprimé), original revérifié vert.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-architecture.sh"
TARGET="$SCRIPT"
PLUGIN_DIR="$(cd "$HERE/../../.." && pwd)"
GAB="$PLUGIN_DIR/planning-core/references/templates/product/ARCHITECTURE.template.md"

PASS=0; FAIL=0; SKIPPED=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; SKIPPED=$((SKIPPED+1)); }

TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
FX="$TMP/fx"; mkdir -p "$FX"
: > "$TMP/rcs"; : > "$TMP/fxlist"; : > "$TMP/fxsum"
mkdir "$TMP/cwd"; cd "$TMP/cwd" || exit 1
RUNDIR="$TMP/cwd"
LASTMSG=""; RC=0; OUT=""; ERR=""

# reg <relatif> : inscrit une fixture à l'empreinte de lecture seule (contenu des fichiers réguliers).
reg() {
  echo "$FX/$1" >> "$TMP/fxlist"
  if [ -f "$FX/$1" ] && [ ! -L "$FX/$1" ]; then echo "$(cksum < "$FX/$1") $FX/$1" >> "$TMP/fxsum"; fi
}
# run <arguments séparés> -> RC, OUT, ERR ; appel borné (une attente devient un échec du cas, rc 142), cwd neutre.
run() {
  OUT="$(cd "$RUNDIR" && perl -e 'alarm 10; exec @ARGV' bash "$TARGET" "$@" 2>"$TMP/err" < /dev/null)"; RC=$?
  ERR="$(cat "$TMP/err")"
  echo "$RC" >> "$TMP/rcs"
}
# runf <fixture> : passe --architecture <fixture sous $FX> (le nom est inscrit à l'empreinte avant l'appel).
runf() { run --architecture "$FX/$1"; }
has() { command grep -qF -- "$1" <<<"$OUT"; }   # chaîne ici : jamais de tube (SIGPIPE + pipefail)
last() { printf '%s\n' "$OUT" | tail -1; }
case_() { if "$2"; then ok "$1"; else ko "$1 — $LASTMSG"; fi; }
msg() { LASTMSG="$1, obtenu rc $RC out[$(printf '%s' "$OUT" | tr '\n' '|' | cut -c1-260)] err[$(printf '%s' "$ERR" | tr '\n' '|' | cut -c1-200)]"; }

echo "== test-check-architecture =="

# === Tracer : du gabarit brut au code 1, du gabarit rempli et validé au code 0 ===================
# fill_gab <ligne d'état> : copie du gabarit réel où chaque ligne entre crochets (corps) devient une phrase.
fill_gab() { # <sortie> <ligne d'état>
  awk -v st="$2" '
    /^\*\*Validation:\*\* proposed/ { print st; next }
    /^- \[/ { print "- Une phrase de contenu réel pour cette rubrique."; next }
    /^\[/ { print "Une phrase de contenu réel pour cette rubrique."; next }
    { print }' "$GAB" > "$1"
}
probe_trace1() {
  cp "$GAB" "$FX/trace1.md"; reg trace1.md
  runf trace1.md
  msg "gabarit brut attendu rc 1 + ARCHITECTURE proposee + six rubriques vides"
  { [ "$RC" -eq 1 ] && has 'ARCHITECTURE proposee' \
    && [ "$(printf '%s\n' "$OUT" | command grep -c 'ELIMINATOIRE rubrique [a-z_]* : vide$')" -eq 6 ] \
    && last | command grep -q 'BILAN statut=proposee rubriques_manquantes=6 code=1$'; }
}
probe_trace2() {
  fill_gab "$FX/trace2.md" '**Validation:** validated (dev, 2026-10-29)'; reg trace2.md
  runf trace2.md
  msg "gabarit rempli et validé attendu rc 0 + ARCHITECTURE validee"
  { [ "$RC" -eq 0 ] && has 'ARCHITECTURE validee' && ! has 'ELIMINATOIRE' \
    && last | command grep -q 'BILAN statut=validee rubriques_manquantes=0 code=0$'; }
}
probe_trace3() {
  run --architecture "$FX/inexistant.md"
  msg "fichier absent attendu rc 1 + ARCHITECTURE absente"
  { [ "$RC" -eq 1 ] && has 'ARCHITECTURE absente' && last | command grep -q 'BILAN statut=absente .*code=1$'; }
}
probe_trace4() {
  run; msg "aucun argument attendu rc 64 + usage sur stderr"
  { [ "$RC" -eq 64 ] && printf '%s' "$ERR" | command grep -q 'usage'; } || return 1
  run --architecture ''; msg "valeur vide attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run --architecture=; msg "valeur vide (forme =) attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run --architecture; msg "option sans valeur attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run --inconnu; msg "argument inconnu attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run --architecture a.md --architecture b.md; msg "option répétée attendu rc 64"; [ "$RC" -eq 64 ]
}
probe_help() {
  run --help; msg "--help attendu rc 0 avec les codes et la phrase du code 2"
  { [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | command grep -q '^  0 = ' && printf '%s\n' "$OUT" | command grep -q '^  64 = ' \
    && has "Le code 2 n'est jamais émis"; } || return 1
  run -h; msg "-h attendu rc 0"; [ "$RC" -eq 0 ]
}
if [ -f "$GAB" ]; then
  case_ CARCH-TRACE-1 probe_trace1
  case_ CARCH-TRACE-2 probe_trace2
else
  skip "CARCH-GABARIT absent (copie à plat) : CARCH-TRACE-1 et CARCH-TRACE-2 non joués"
fi
case_ CARCH-TRACE-3 probe_trace3
case_ CARCH-TRACE-4 probe_trace4
case_ CARCH-HELP probe_help

# === Fabrique de fixtures : architecture complète, ligne d'état et rubrique omise au choix =========
CTXB='Le produit sert des artisans du bâtiment.'
VAL='**Validation:** validated (dev, 2026-10-29)'
PROP='**Validation:** proposed'
sec() { [ "$1" = "$2" ] || printf '## %s\n%s\n\n' "$3" "$4"; }
# gen <ligne d'état | -> <rubrique omise | -> : architecture sur stdout ; CTXB est le corps de « Contexte ».
gen() {
  printf '# Architecture — Produit test\n\n> Fichier décisionnel.\n\n'
  [ "$1" = "-" ] || printf '%s\n\n' "$1"
  sec "$2" contexte 'Contexte' "$CTXB"
  sec "$2" choix_structurants 'Choix structurants' '- Base relationnelle : cohérence, contre un magasin de documents.'
  sec "$2" composants 'Composants et responsabilités' '- Une API et un worker de traitement.'
  sec "$2" donnees 'Données' '- Commandes et clients, hébergés en Europe.'
  sec "$2" contraintes 'Contraintes' '- Disponibilité de 99,5 % en heures ouvrées.'
  sec "$2" risques 'Risques et questions ouvertes' '- Charge inconnue au lancement.'
}
# mkarch <nom> <ligne d'état | -> <rubrique omise | -> : fixture sous $FX inscrite à l'empreinte.
mkarch() { gen "$2" "$3" > "$FX/$1"; reg "$1"; }
nelim() { printf '%s\n' "$OUT" | command grep -c 'ELIMINATOIRE'; }
RUBS='contexte choix_structurants composants donnees contraintes risques'

# === Ligne d'état, rubriques, corps ================================================================
probe_valide() {
  mkarch valide.md "$VAL" -; runf valide.md
  msg "architecture validée et complète attendu rc 0"; [ "$RC" -eq 0 ] && has 'ARCHITECTURE validee' || return 1
  mkarch val-nu.md '**Validation:** validated' -; runf val-nu.md
  msg "validated nu attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  mkarch val-ov.md '**Validation**: VALIDATED (dev, 2026-10-29, override)' -; runf val-ov.md
  msg "variante **Validation**: , casse et override attendu rc 0"; [ "$RC" -eq 0 ]
}
probe_proposee() {
  mkarch proposee.md "$PROP" -; runf proposee.md
  msg "architecture complète proposée attendu rc 1 + proposee + zéro rubrique manquante"
  { [ "$RC" -eq 1 ] && has 'ARCHITECTURE proposee' && ! has 'ELIMINATOIRE' \
    && last | command grep -q 'BILAN statut=proposee rubriques_manquantes=0 code=1$'; }
}
probe_rubrique() {
  local k
  for k in $RUBS; do
    mkarch "rub-$k.md" "$VAL" "$k"; runf "rub-$k.md"
    msg "rubrique $k retirée attendu rc 1 + ELIMINATOIRE rubrique $k : absente (seule)"
    { [ "$RC" -eq 1 ] && has "ELIMINATOIRE rubrique $k : absente" && [ "$(nelim)" -eq 1 ] \
      && ! has 'ARCHITECTURE validee' && last | command grep -q 'rubriques_manquantes=1 code=1$'; } || return 1
  done
}
vide_case() { # <nom> <corps de Contexte>
  CTXB="$2"; mkarch "vide-$1.md" "$VAL" -; CTXB='Le produit sert des artisans du bâtiment.'; runf "vide-$1.md"
  msg "corps « $1 » attendu rc 1 + contexte : vide (seule)"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE rubrique contexte : vide' && [ "$(nelim)" -eq 1 ]
}
probe_vide() {
  vide_case crochets '[Le produit : à écrire]' || return 1
  vide_case puce-crochets '- [Choix 1 : quoi — pourquoi]' || return 1
  vide_case citation-crochets '> [guidance du gabarit]' || return 1
  vide_case emphase-crochets '*[crochets en emphase]*' || return 1
  vide_case commentaire '<!-- commentaire seul -->' || return 1
  vide_case commentaire-multi $'<!--\nplusieurs lignes\nde commentaire -->' || return 1
  vide_case tbd 'TBD' || return 1
  vide_case todo '- todo : à voir' || return 1
  vide_case points '...' || return 1
  vide_case bloc-de-code $'```\ndu code, pas un corps\n```' || return 1
  vide_case sous-titre '### Sous-titre sans corps' || return 1
  vide_case rien '' || return 1
  # témoins positifs : un corps réel passe (emphase de tête, sous-titre portant un corps, mot proche de TBD).
  CTXB='- **Contexte** : un corps réel.'; mkarch ok-emphase.md "$VAL" -; runf ok-emphase.md
  msg "corps à emphase de tête attendu rc 0"; [ "$RC" -eq 0 ] || { CTXB='Le produit sert des artisans du bâtiment.'; return 1; }
  CTXB=$'### Détail\nUne phrase réelle sous un sous-titre.'; mkarch ok-sous.md "$VAL" -; runf ok-sous.md
  msg "corps sous un sous-titre attendu rc 0"; [ "$RC" -eq 0 ] || { CTXB='Le produit sert des artisans du bâtiment.'; return 1; }
  CTXB='Le mot tbdx et les todos ne sont pas des marqueurs.'; mkarch ok-mot.md "$VAL" -; runf ok-mot.md
  CTXB='Le produit sert des artisans du bâtiment.'
  msg "mots proches de TBD et TODO attendu rc 0"; [ "$RC" -eq 0 ]
}
probe_num() {
  gen "$VAL" - | sed -e 's/^## Contexte/## 1. Contexte/' -e 's/^## Choix structurants/## 2) CHOIX STRUCTURANTS/' \
    -e 's/^## Composants et responsabilités/## **Composants** et responsabilités/' -e 's/^## Données/## DONNÉES/' \
    -e 's/^## Contraintes/## Contraintes (non fonctionnelles)/' -e 's/^## Risques et questions ouvertes/## _Risques_ et questions ouvertes/' > "$FX/num.md"
  reg num.md; runf num.md
  msg "titres numérotés, en capitales, accentués ou en emphase attendu rc 0"; [ "$RC" -eq 0 ] && ! has 'ELIMINATOIRE'
}
probe_crlf() {
  gen "$VAL" - | awk '{ printf "%s\r\n", $0 }' > "$FX/crlf.md"; reg crlf.md; runf crlf.md
  msg "CRLF attendu rc 0 comme en LF"; [ "$RC" -eq 0 ] || return 1
  gen "$VAL" - | tr '\n' '\r' > "$FX/cr.md"; reg cr.md; runf cr.md
  msg "CR seul attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  gen "$VAL" risques | awk '{ printf "%s\r\n", $0 }' > "$FX/crlf-manque.md"; reg crlf-manque.md; runf crlf-manque.md
  msg "CRLF avec rubrique manquante attendu rc 1 + risques : absente"; [ "$RC" -eq 1 ] && has 'rubrique risques : absente'
}
probe_bom() {
  { printf '\357\273\277'; gen "$VAL" -; } > "$FX/bom.md"; reg bom.md; runf bom.md
  msg "BOM attendu rc 0 comme sans BOM"; [ "$RC" -eq 0 ] || return 1
  { printf '\357\273\277'; gen "$PROP" -; } > "$FX/bom-prop.md"; reg bom-prop.md; runf bom-prop.md
  msg "BOM + proposed attendu rc 1"; [ "$RC" -eq 1 ]
}
statut_case() { # <nom> <ligne(s) d'état> <rc attendu> <étiquette attendue>
  mkarch "st-$1.md" "$2" -; runf "st-$1.md"
  msg "statut « $1 » attendu rc $3 + $4"; [ "$RC" -eq "$3" ] && has "$4" && ! has 'ARCHITECTURE validee'
}
probe_statut() {
  statut_case absent - 3 'INDETERMINE statut : absent' || return 1
  last | command grep -q 'BILAN statut=inconnu ' || { msg "BILAN statut=inconnu attendu"; return 1; }
  statut_case inconnu '**Validation:** ok' 3 'INDETERMINE statut : valeur inconnue' || return 1
  statut_case texte-apres '**Validation:** validated by me' 3 'INDETERMINE statut : valeur inconnue' || return 1
  statut_case multiple "$VAL"$'\n\n'"$PROP" 3 'INDETERMINE statut : multiple' || return 1
  statut_case multiple-deux-valides "$VAL"$'\n\n'"$VAL" 3 'INDETERMINE statut : multiple' || return 1
  statut_case en-bloc $'```\n**Validation:** validated (dev, 2026-10-29)\n```' 3 'INDETERMINE statut : absent' || return 1
  statut_case en-commentaire '<!-- **Validation:** validated (dev, 2026-10-29) -->' 3 'INDETERMINE statut : absent' || return 1
  statut_case en-commentaire-multi $'<!--\n**Validation:** validated (dev, 2026-10-29)\n-->' 3 'INDETERMINE statut : absent' || return 1
  statut_case en-code-ligne '`<!--` puis **Validation:** validated (dev, 2026-10-29)' 3 'INDETERMINE statut : absent'
}
probe_fence_ouverte() {
  { gen "$VAL" -; printf '\n```\ndu code jamais refermé\n'; } > "$FX/fence-ouverte.md"; reg fence-ouverte.md; runf fence-ouverte.md
  msg "bloc de code non fermé attendu rc 3 + INDETERMINE bloc de code non ferme"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE bloc de code non ferme' && ! has 'ARCHITECTURE validee'; } || return 1
  { gen "$VAL" -; printf '\n<!-- commentaire jamais refermé\n%s\n' "$PROP"; } > "$FX/com-ouvert.md"; reg com-ouvert.md; runf com-ouvert.md
  msg "commentaire HTML non fermé attendu rc 3 + INDETERMINE commentaire HTML non ferme"
  [ "$RC" -eq 3 ] && has 'INDETERMINE commentaire HTML non ferme' && ! has 'ARCHITECTURE validee'
}
probe_mix() {
  mkarch mix.md - risques; runf mix.md
  msg "statut absent ET rubrique manquante attendu rc 1 (1 l'emporte sur 3) avec les deux constats"
  { [ "$RC" -eq 1 ] && has 'rubrique risques : absente' && has 'INDETERMINE statut : absent'; }
}
probe_descriptif() {
  cat > "$FX/descriptif.md" <<'DESC'
# Architecture

## Pattern Overview

**Overall:** application en couches, serveur et client séparés.

## Layers

- Présentation : composants d'interface.
- Services : logique métier.

## Data Flow

Les requêtes traversent la présentation puis les services.
DESC
  reg descriptif.md; runf descriptif.md
  msg "carte descriptive sans ligne d'état attendu rc 1 (une carte n'est pas une décision)"
  [ "$RC" -eq 1 ] && [ "$(nelim)" -eq 6 ] || return 1
  { cat "$FX/descriptif.md"; printf '\n%s\n' "$VAL"; } > "$FX/descriptif-valide.md"; reg descriptif-valide.md; runf descriptif-valide.md
  msg "carte descriptive marquée validated attendu rc 1 (six rubriques absentes)"
  [ "$RC" -eq 1 ] && ! has 'ARCHITECTURE validee'
}
case_ CARCH-VALIDE probe_valide
case_ CARCH-PROPOSEE probe_proposee
case_ CARCH-RUBRIQUE probe_rubrique
case_ CARCH-VIDE probe_vide
case_ CARCH-NUM probe_num
case_ CARCH-CRLF probe_crlf
case_ CARCH-BOM probe_bom
case_ CARCH-STATUT probe_statut
case_ CARCH-FENCE-OUVERTE probe_fence_ouverte
case_ CARCH-MIX probe_mix
case_ CARCH-DESCRIPTIF probe_descriptif

# === Entrées non fiables : refus en 5 AVANT lecture ==================================================
probe_lien() {
  mkarch lien-reel.md "$VAL" -; ln -sf "$FX/lien-reel.md" "$FX/lien.md"; reg lien.md
  runf lien.md
  msg "lien symbolique vers un fichier conforme attendu rc 5 + ILLISIBLE sur stdout et stderr"
  { [ "$RC" -eq 5 ] && has 'ILLISIBLE lien symbolique' && printf '%s' "$ERR" | command grep -qF 'ILLISIBLE lien symbolique'; } || return 1
  ln -sf "$FX/cible-inexistante.md" "$FX/lien-pendant.md"; reg lien-pendant.md
  runf lien-pendant.md
  msg "lien pendant attendu rc 5 (jamais pris pour un fichier absent)"; [ "$RC" -eq 5 ]
}
probe_fifo() {
  [ -p "$FX/fifo.md" ] || mkfifo "$FX/fifo.md"; reg fifo.md
  runf fifo.md
  msg "FIFO attendu rc 5 sans blocage (142 = lue)"; [ "$RC" -eq 5 ]
}
probe_dossier() {
  mkdir -p "$FX/dossier.md"; reg dossier.md
  runf dossier.md
  msg "dossier attendu rc 5"; [ "$RC" -eq 5 ]
}
probe_gros() {
  dd if=/dev/zero bs=1048577 count=1 2>/dev/null | tr '\0' 'x' > "$FX/gros.md"; reg gros.md
  runf gros.md
  msg "1048577 octets attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  dd if=/dev/zero bs=1048576 count=1 2>/dev/null | tr '\0' 'x' > "$FX/borne.md"; reg borne.md
  runf borne.md
  msg "1048576 octets (la borne incluse) attendu rc 1, pas 5"; [ "$RC" -eq 1 ]
}
probe_illisible() {
  mkarch illisible.md "$VAL" -; chmod 000 "$FX/illisible.md"; runf illisible.md
  local r=$RC; chmod 600 "$FX/illisible.md"; RC=$r
  msg "chmod 000 attendu rc 5 + « fichier illisible »"; { [ "$RC" -eq 5 ] && has 'ILLISIBLE fichier illisible'; }
}
case_ CARCH-LIEN probe_lien
case_ CARCH-FIFO probe_fifo
case_ CARCH-DOSSIER probe_dossier
case_ CARCH-GROS probe_gros
if [ "$(id -u)" -eq 0 ]; then skip "CARCH-ILLISIBLE (suite jouée en root : chmod 000 n'interdit rien)"
else case_ CARCH-ILLISIBLE probe_illisible; fi

# === Contenu du fichier jamais réimprimé =============================================================
SECRET="zzSECRETzz"
probe_noecho() {
  local leak=0
  CTXB="Un corps qui porte $SECRET."; gen "$VAL" - | sed "s/^## Contexte/## Contexte $SECRET/" > "$FX/ne1.md"
  CTXB='Le produit sert des artisans du bâtiment.'; reg ne1.md; runf ne1.md
  msg "secret en corps et en titre attendu rc 0 sans $SECRET sur stdout ni stderr"
  { [ "$RC" -eq 0 ] && ! has "$SECRET" && ! printf '%s' "$ERR" | command grep -qF "$SECRET"; } || return 1
  mkarch ne2.md "**Validation:** $SECRET" -; runf ne2.md
  msg "statut inconnu attendu rc 3 sans $SECRET"
  { [ "$RC" -eq 3 ] && ! has "$SECRET" && ! printf '%s' "$ERR" | command grep -qF "$SECRET"; } || return 1
  { gen "$PROP" risques; printf '## %s\n\n- %s\n' "$SECRET" "$SECRET"; } > "$FX/ne3.md"; reg ne3.md; runf ne3.md
  msg "rubrique inconnue au nom secret attendu rc 1 sans $SECRET"
  { [ "$RC" -eq 1 ] && ! has "$SECRET" && ! printf '%s' "$ERR" | command grep -qF "$SECRET"; } || return 1
  return "$leak"
}
case_ CARCH-NOECHO probe_noecho

# === Forme exec : aucune évaluation de chaîne, chemin hostile inerte ===================================
probe_exec() {
  local n hostile="$FX/a b'c \$(touch pwned).md"
  n="$(awk '!/^[[:space:]]*#/ && /(^|[^A-Za-z_])eval([^A-Za-z_]|$)/{n++} END{print n+0}' "$SCRIPT")"
  LASTMSG="le script appelle une évaluation dynamique de chaîne ($n ligne(s))"; [ "$n" = 0 ] || return 1
  gen "$VAL" - > "$hostile"; echo "$hostile" >> "$TMP/fxlist"; echo "$(cksum < "$hostile") $hostile" >> "$TMP/fxsum"
  run --architecture "$hostile"
  msg "chemin hostile attendu rc 0 comme un nom de fichier, sans exécution"
  { [ "$RC" -eq 0 ] && [ ! -e "$RUNDIR/pwned" ] && [ ! -e "$FX/pwned" ]; } || return 1
  run "--architecture=$hostile"
  msg "chemin hostile (forme =) attendu rc 0 sans exécution"; { [ "$RC" -eq 0 ] && [ ! -e "$RUNDIR/pwned" ]; } || return 1
  run --architecture "$FX/absent \$(touch pwned).md"
  msg "chemin hostile absent attendu rc 1 sans exécution"; { [ "$RC" -eq 1 ] && [ ! -e "$RUNDIR/pwned" ]; }
}
case_ CARCH-EXEC probe_exec

# === Lecture seule, couverture des codes ===========================================================
probe_ro() {
  LC_ALL=C sort -u "$TMP/fxlist" > "$TMP/fxl"; find "$FX" -mindepth 1 | LC_ALL=C sort > "$TMP/fxnow"
  LASTMSG="le dossier de fixtures a changé de contenu (fichier créé ou supprimé par le script)"
  cmp -s "$TMP/fxl" "$TMP/fxnow" || return 1
  local a b p
  while read -r a b p; do
    LASTMSG="fixture modifiée : $p"
    [ "$(cksum < "$p")" = "$a $b" ] || return 1
  done < "$TMP/fxsum"
  return 0
}
case_ CARCH-RO probe_ro
probe_codes() {
  LC_ALL=C sort -u "$TMP/rcs" > "$TMP/obs"; printf '0\n1\n3\n5\n64\n' > "$TMP/exp-codes"
  local manq extra
  manq="$(comm -13 "$TMP/obs" "$TMP/exp-codes" | tr '\n' ' ')"; extra="$(comm -23 "$TMP/obs" "$TMP/exp-codes" | tr '\n' ' ')"
  LASTMSG="codes manquants [$manq] en trop [$extra]"; [ -z "$manq" ] && [ -z "$extra" ]
}
case_ CARCH-CODES probe_codes
printf '    codes observés : {%s}\n' "$(awk '{ printf "%s%s", (NR > 1 ? ", " : ""), $0 }' "$TMP/obs")"

# === Mutants (QUAL-01) ===============================================================================
MUTDIR="$TMP/mut"; mkdir -p "$MUTDIR"
MUTBIN="$MUTDIR/check-architecture.sh"

# mutant <id> <ligne repère> <ancien> <nouveau> <sonde> <description> : dans UNE ligne du script (celle qui
# contient le repère), remplace la première occurrence littérale de <ancien> par <nouveau> (chaînes passées par
# l'environnement : aucune séquence d'échappement interprétée). La sonde doit échouer sur le mutant, réussir
# sur l'original ; code attendu/obtenu imprimé par msg.
mutant() {
  local id="$1" needle="$2" old="$3" new="$4" probe="$5" desc="$6"
  if ! declare -F "$probe" > /dev/null; then ko "$id sonde $probe NON DÉFINIE à cet endroit — $desc"; return; fi
  NEEDLE="$needle" OLD="$old" NEW="$new" awk 'BEGIN { n = ENVIRON["NEEDLE"]; o = ENVIRON["OLD"]; w = ENVIRON["NEW"] }
    { if (index($0, n)) { i = index($0, o); if (i) $0 = substr($0, 1, i - 1) w substr($0, i + length(o)) } print }' \
    "$SCRIPT" > "$MUTBIN"
  if cmp -s "$MUTBIN" "$SCRIPT"; then ko "$id mutant NON OPPOSABLE (copie identique à l'original) — $desc"; return; fi
  if ! bash -n "$MUTBIN" 2>/dev/null; then ko "$id mutant invalide (bash -n) — $desc"; return; fi
  local nl; nl="$(diff "$SCRIPT" "$MUTBIN" | command grep -c '^<')"
  if [ "$nl" != 1 ]; then ko "$id mutant mal ciblé ($nl lignes changées au lieu de 1) — $desc"; return; fi
  TARGET="$MUTBIN"; "$probe" < /dev/null; local mrc=$?; local mmsg="$LASTMSG"
  TARGET="$SCRIPT"; "$probe" < /dev/null; local orc=$?
  if [ "$mrc" -ne 0 ] && [ "$orc" -eq 0 ]; then
    ok "$id tue ($desc) — sur le mutant : $mmsg"
  elif [ "$mrc" -eq 0 ]; then
    ko "$id mutant SURVIVANT ($desc) — la sonde ${probe#probe_} reste verte sur le mutant"
  else
    ko "$id original rouge après mutation ($desc) — $LASTMSG"
  fi
  TARGET="$SCRIPT"
}

mutant CARCH-MUT-1 'proposed) STATUT=proposee' 'bump 1' ':' probe_proposee \
  "FAIL : exigence de l'état validated retirée, un fichier proposed complet rendu 0"
mutant CARCH-MUT-2 'say "ARCHITECTURE absente"' 'bump 1' ':' probe_trace3 \
  "FAIL : fichier absent rendu 0"
mutant CARCH-MUT-3 'nn = split("contexte' ' risques"' '"' probe_rubrique \
  "FAIL : rubrique risques retirée de la liste exigée"
if [ -f "$GAB" ]; then
  mutant CARCH-MUT-4 'if (substr(w, 1, 1) == "[") return 0' 'substr(w, 1, 1) == "["' '0' probe_trace1 \
    "FAIL : filtre du corps entre crochets retiré, le gabarit brut aurait des corps"
else
  skip "CARCH-MUT-4 (gabarit absent, copie à plat : la sonde CARCH-TRACE-1 ne peut pas jouer)"
fi
mutant CARCH-MUT-5 '*) indetermine "statut : valeur inconnue"' 'indetermine "statut : valeur inconnue"' ':' probe_statut \
  "INDÉTERMINÉ : valeur d'état inconnue rendue 0"
mutant CARCH-MUT-6 'if (f3 == "```" || f3 == "~~~")' 'f3 == "```" || f3 == "~~~"' '0' probe_statut \
  "PASS : bascule des blocs de code retirée, un état validated en bloc de code serait lu"
mutant CARCH-MUT-7 'if [ -L "$f" ]; then illisible' '[ -L "$f" ]' 'false' probe_lien \
  "BRUYANT : refus du lien symbolique retiré"
mutant CARCH-MUT-8 '"$size" -gt "$CARCH_MAX_OCTETS"' '"$CARCH_MAX_OCTETS"' '99999999999' probe_gros \
  "BRUYANT : borne de taille retirée"
mutant CARCH-MUT-9 'elif [ "$NMARK" -gt 1 ]' '[ "$NMARK" -gt 1 ]' 'false' probe_statut \
  "INDÉTERMINÉ : lignes d'état multiples rendues selon la première"

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
