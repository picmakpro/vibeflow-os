#!/usr/bin/env bash
# doc-chiffres.sh — aide à sourcer de la section V12 de test-cockpit-vendor.sh (79-20, SOCL-25, P79-D-27) : les chiffres que le README du module
# documente sont ceux du code. Pas une suite (aucun test-*.sh) ; aucun eval, aucun processus hors utilitaires de texte, bash 3.2.
# Une « racine » est un dossier de module : la vraie (plugin/cockpit) ou une copie jetable mutée par un témoin.
#   dc_depot_de_dev <racine>        oui | non : module posé sous plugin/cockpit d'une racine qui porte .planning/
#   dc_cellule <readme> <clé>       valeur du tableau « Chiffres tenus par le code » (vide si la ligne manque ou figure deux fois)
#   dc_code <clé> <racine> <chk>    valeur lue dans le code (vide si la source manque, est ambiguë ou non numérique : jamais un vert)
#   dc_verifier <racine> <chk>      une ligne par contrôle, « OK <id> … » ou « ROUGE <id> … » (attendu / obtenu) ; <chk> = check-file-size.sh
#   dc_etat <sortie> <id>           rouge | ok | absent : la lecture d'un contrôle dans la sortie de dc_verifier
#   dc_copie_base <dest> <racine> <chk>   copie minimale d'une racine ; dc_sed / dc_ajouter / dc_retirer / dc_creer : une mutation, copie changée ou échec
DC_CLES=(fenetre-index-h battement-flux-s veille-flux-s fraicheur-signal-s plafond-lignes plafond-colonnes scripts-lancer suites-lancer)
DC_TITRE='## Chiffres tenus par le code'
# jetons dont le README ne porte plus aucune ligne (les entrées historiques du CHANGELOG les gardent)
DC_RETRAITS=('SYNCHRO.md' 'synchro.sh' 'synchro amont' 'patch P27' 'patch amont' 'amont/' 'moteur vendoris' 'neuf scripts' 'quatorze suites'
  'v1.0.x' 'jamais une source de code' 'vf-cockpit-terminal-client.mjs' 'vf-cockpit-terminal-vue.mjs' 'vf-cockpit-terminal-tiroir-ui.mjs'
  'vf-cockpit-terminal-style.mjs' 'vf-cockpit-terminal-tiroir-style.mjs' 'vf-cockpit-lancer-style.mjs')

dc_depot_de_dev() {
  local m d
  m="$(cd "$1" 2>/dev/null && pwd -P)" || { echo non; return 0; }
  d="$(cd "$m/../.." 2>/dev/null && pwd -P)" || { echo non; return 0; }
  if [ "$m" = "$d/plugin/cockpit" ] && [ -d "$d/.planning" ]; then echo oui; else echo non; fi
}

dc_cellule() {
  awk -v k="\`$2\`" '
    /^## / { s = ($0 == "## Chiffres tenus par le code"); next }
    s && substr($0, 1, 1) == "|" { split($0, c, "|"); g = c[2]; gsub(/^ +| +$/, "", g)
      if (g == k) { v = c[3]; gsub(/^ +| +$/, "", v); r = v; m++ } }
    END { if (m == 1) print r }' "$1"
}

# dc_calc <fichier> <expression sed qui imprime la valeur> <diviseur> : l'unique affectation numérique (produit admis), divisée
dc_calc() {
  local v n
  [ -s "$1" ] || return 0
  v="$(sed -nE "$2" "$1")"
  n="$(printf '%s\n' "$v" | awk 'NF{k++} END{print k+0}')"
  [ "$n" = 1 ] || return 0
  v="${v//_/}"
  case "$v" in ''|*[!0-9*]*|'*'*|*'*'|0[0-9]*) return 0 ;; esac
  printf '%s\n' "$(( v / $3 ))"
}
dc_compte() { local f n=0; for f in "$@"; do [ -f "$f" ] && n=$((n+1)); done; printf '%s\n' "$n"; }

dc_code() {
  local R="$2"
  case "$1" in
    fenetre-index-h) dc_calc "$R/scripts/vf-cockpit-index-voie.mjs" 's/.*[{ ,]fenetreS: ([0-9_]+)[, }].*/\1/p' 3600 ;;
    battement-flux-s) dc_calc "$R/scripts/vf-cockpit-flux-etat.mjs" 's/^(export )?const VIE_MS = ([0-9_*]+);.*/\2/p' 1000 ;;
    veille-flux-s) dc_calc "$R/skills/cockpit-moteur/assets/ui/69-vf-flux.js" 's/^[[:space:]]*const SILENCE_MS = ([0-9_*]+);.*/\1/p' 1000 ;;
    fraicheur-signal-s) dc_calc "$R/scripts/vf-cockpit-signal-serveur.mjs" 's/^export const FRAICHEUR_MAX_MS = ([0-9_*]+)[,;].*/\1/p' 1000 ;;
    plafond-lignes) dc_calc "$3" 's/^BLOCK="\$\{VF_ARCH_BLOCK:-([0-9]+)\}".*/\1/p' 1 ;;
    plafond-colonnes) dc_calc "$R/scripts/tests/colonnes-cliquet.mjs" 's/^const SEUIL = ([0-9]+);.*/\1/p' 1 ;;
    scripts-lancer) dc_compte "$R"/scripts/vf-cockpit-lancer*.mjs ;;
    suites-lancer) dc_compte "$R"/scripts/tests/test-cockpit-lancer-*.sh ;;
  esac
}

dc_lire() { # <racine> <quoi> : un numéro de version ou un type, lu à sa place
  local R="$1"
  case "$2" in
    version) [ -f "$R/VERSION" ] && tr -d '[:space:]' < "$R/VERSION" ;;
    json) sed -nE 's/^[[:space:]]*"version": "([^"]*)".*/\1/p' "$R/module.json" | head -n 1 ;;
    entete) grep -m1 -F '**Version**' "$R/README.md" | sed -E 's/.*\*\*Version\*\* : ([^ ]+).*/\1/' ;;
    titre) grep -m1 -E '^## v[0-9]' "$R/CHANGELOG.md" | sed -E 's/^## (v[0-9.]+).*/\1/' ;;
    type-json) sed -nE 's/^[[:space:]]*"type": "([^"]*)".*/\1/p' "$R/module.json" | head -n 1 ;;
    type-entete) grep -m1 -F '**Type**' "$R/README.md" | sed -E 's/^\*\*Type\*\* : (.*) · \*\*Version\*\*.*/\1/' ;;
  esac
  return 0
}

dc_noms() { grep -o -E "$2" "$1/README.md" | sort -u; }
dc_manque() { # <ERE> <dossier ou fichiers…> : noms nommés par le README et absents (liste, vide si tout existe)
  local R="$1" re="$2" dir="$3" n out=""
  for n in $(dc_noms "$R" "$re"); do [ -f "$dir/$n" ] || out="$out $n"; done
  printf '%s\n' "${out# }"
}

dc_verifier() {
  local R="$1" CHK="$2" i=0 k c d l n s m v1 v2 v3 v4
  v1="$(dc_lire "$R" version)"; v2="$(dc_lire "$R" json)"; v3="$(dc_lire "$R" entete)"; v4="$(dc_lire "$R" titre)"
  if [ -n "$v1" ] && [ "$v1" = "$v2" ] && [ "$v1" = "$v3" ] && [ "$v1" = "$v4" ]; then echo "OK V12.1a $v1"
  else echo "ROUGE V12.1a attendu=VERSION:[$v1] obtenu=module.json:[$v2] README:[$v3] CHANGELOG:[$v4]"; fi
  v1="$(dc_lire "$R" type-json)"; v2="$(dc_lire "$R" type-entete)"
  if [ -n "$v1" ] && [ "$v1" = "$v2" ]; then echo "OK V12.1b $v1"; else echo "ROUGE V12.1b attendu=module.json:[$v1] obtenu=README:[$v2]"; fi
  for k in "${DC_CLES[@]}"; do
    l="abcdefgh"; l="${l:$i:1}"; i=$((i+1))
    c="$(dc_code "$k" "$R" "$CHK")"; d="$(dc_cellule "$R/README.md" "$k")"
    if [ -z "$c" ]; then echo "ROUGE V12.2$l $k attendu=source-lisible obtenu=source-absente-ambigue-ou-non-numerique"
    elif [ -z "$d" ]; then echo "ROUGE V12.2$l $k attendu=$c obtenu=non-documente"
    elif [ "$c" = "$d" ]; then echo "OK V12.2$l $k $c"
    else echo "ROUGE V12.2$l $k attendu=$c obtenu=$d"; fi
  done
  m="$(dc_manque "$R" 'vf-cockpit-[a-z0-9-]+\.mjs' "$R/scripts")"
  if [ -z "$m" ]; then echo "OK V12.3a modules nommes presents"; else echo "ROUGE V12.3a attendu=modules-existants obtenu=absents:$m"; fi
  m="$(dc_manque "$R" 'test-cockpit-[a-z0-9-]+\.sh' "$R/scripts/tests")"
  if [ -z "$m" ]; then echo "OK V12.3b suites nommees presentes"; else echo "ROUGE V12.3b attendu=suites-existantes obtenu=absentes:$m"; fi
  m=""
  for n in $(grep -o -E '/api/vf/[a-z]+' "$R/README.md" | sort -u); do
    s="${n##*/}"; grep -q -E "/api/vf/$s([^a-z]|\$)" "$R"/scripts/*.mjs 2>/dev/null || m="$m $n"
  done
  if [ -z "$m" ]; then echo "OK V12.3c routes nommees presentes"; else echo "ROUGE V12.3c attendu=routes-du-code obtenu=absentes:$m"; fi
}

dc_etat() {
  if grep -q "^ROUGE $2 " "$1"; then echo rouge; elif grep -q "^OK $2 " "$1"; then echo ok; else echo absent; fi
}

dc_copie_base() { # <destination> <racine réelle> <chk> : sources réelles des extracteurs, documents synthétiques qui disent le code tel que lu
  local d="$1" r="$2" f k i=0 v t="skill + scripts + moteur (fork de floorplan)"
  mkdir -p "$d/scripts/tests" "$d/skills/cockpit-moteur/assets/ui" "$d/chk"
  cp "$r/scripts/vf-cockpit-index-voie.mjs" "$r/scripts/vf-cockpit-flux-etat.mjs" "$r/scripts/vf-cockpit-signal-serveur.mjs" "$d/scripts/"
  cp "$r/scripts/tests/colonnes-cliquet.mjs" "$d/scripts/tests/"
  cp "$r/skills/cockpit-moteur/assets/ui/69-vf-flux.js" "$d/skills/cockpit-moteur/assets/ui/"
  cp "$3" "$d/chk/check-file-size.sh"
  : > "$d/scripts/vf-cockpit-index.mjs"; : > "$d/scripts/tests/test-cockpit-vendor.sh"
  printf '%s\n' "// /api/vf/state" > "$d/scripts/vf-cockpit-routes.mjs"
  for f in "$r"/scripts/vf-cockpit-lancer*.mjs; do : > "$d/scripts/${f##*/}"; done
  for f in "$r"/scripts/tests/test-cockpit-lancer-*.sh; do : > "$d/scripts/tests/${f##*/}"; done
  v="$(tr -d '[:space:]' < "$r/VERSION")"
  printf '%s\n' "$v" > "$d/VERSION"
  printf '{\n  "name": "cockpit",\n  "version": "%s",\n  "type": "%s"\n}\n' "$v" "$t" > "$d/module.json"
  printf '# Changelog — cockpit\n\n## Non publié\n\n## %s — 2000-01-01 — non publié\n' "$v" > "$d/CHANGELOG.md"
  { printf '# cockpit\n\n**Type** : %s · **Version** : %s · **Dépend de** : aucun module\n\n' "$t" "$v"
    printf 'Le module `vf-cockpit-index.mjs`, la suite `test-cockpit-vendor.sh` et la route `/api/vf/state` existent.\n\n%s\n\n' "$DC_TITRE"
    printf '| Clé | Valeur | Source dans le code |\n|---|---|---|\n'
    for k in "${DC_CLES[@]}"; do printf '| `%s` | %s | témoin |\n' "$k" "$(dc_code "$k" "$d" "$d/chk/check-file-size.sh")"; done
  } > "$d/README.md"
  return 0
}
# mutations : chacune rend 1 (« mutation sans effet ») si la copie n'a pas changé
dc_sed() { local f="$1/$2"; sed -E "$3" "$f" > "$f.mut" && { if cmp -s "$f" "$f.mut"; then rm -f "$f.mut"; return 1; fi; mv "$f.mut" "$f"; }; }
dc_ajouter() { printf '\n%s\n' "$3" >> "$1/$2"; }
dc_retirer() { [ -f "$1/$2" ] || return 1; rm -f "$1/$2"; }
dc_creer() { mkdir -p "$(dirname "$1/$2")" && printf '%s\n' '{}' > "$1/$2"; }
