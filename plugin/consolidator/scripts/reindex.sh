#!/usr/bin/env bash
# reindex.sh v2 — Regenere l'index header d'un registre memoire VibeFlow
#
# Usage:
#   ./reindex.sh --register=ADR --audit          # audit gaps index <-> body (read-only)
#   ./reindex.sh --register=ADR --dry-run        # output JSON sans toucher au fichier
#   ./reindex.sh --register=ADR --apply          # regenere l'index en preservant Date + Resume
#   ./reindex.sh --all --audit                   # audit tous les registres
#
# v2 (Session 047) :
#   - Mode --audit : detecte gaps index <-> body sans modifier
#   - Mode --apply : preserve Date + Resume existants en parsant le body
#   - Idempotent. Backup auto avant --apply.
#
# v3 (fiabilisation CSL 2026-07) :
#   - CSL-01 : pre-garde fail-open — un bloc '## Index' sans terminateur '---' n'est
#     JAMAIS reecrit (l'awk de reecriture aurait avale tout le body)
#   - CSL-08 : 2e passe de recalage quand le bloc index change de taille (les #Ligne
#     etaient extraits AVANT reecriture → decales par l'insertion de lignes d'index)
#   - CSL-09 : verrou mkdir atomique par registre (anti lost-update entre 2 sessions)
#
# Reference : ADR-032 pilier 1 (Indexation) + LRN-106 (audit before fix)

set -euo pipefail

MEMORY_DIR="${MEMORY_DIR:-.claude/memory}"

# ADR-054 : stub Microsoft Store — `python3` présent dans le PATH Windows mais inerte à
# l'exécution. Détection par CHEMIN, repli `python` ; aucun interpréteur → erreur BRUYANTE
# (un reindex sans python est inopérant : jamais de « réussite » silencieuse).
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else echo "[reindex] ERROR: python3/python introuvable (ou stub Microsoft Store) — requis" >&2; exit 1; fi ;;
esac
DRY_RUN=true
AUDIT_MODE=false
APPLY_MODE=false
TARGET_REGISTER=""
ALL_REGISTERS=false

# ---------- Arg parsing ----------
for arg in "$@"; do
  case "$arg" in
    --apply)         APPLY_MODE=true; DRY_RUN=false ;;
    --dry-run)       DRY_RUN=true ;;
    --audit)         AUDIT_MODE=true; DRY_RUN=true ;;
    --all)           ALL_REGISTERS=true ;;
    --register=*)    TARGET_REGISTER="${arg#*=}" ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

# ---------- Helpers ----------
# Fork config optionnelle : un lab peut surcharger/etendre les mappings registres
# en definissant register_file_custom() et id_pattern_custom() dans ce fichier.
REGISTERS_CONF="${VIBEFLOW_REGISTERS_CONF:-.claude/scripts/registers.conf.sh}"
[ -f "$REGISTERS_CONF" ] && . "$REGISTERS_CONF"

log() {
  echo "[reindex.sh] $*" >&2
}

# Libere le verrou CSL-09 (no-op si non pris). Jamais bloquant : fail-open.
release_reindex_lock() {
  [ -n "${1:-}" ] && rm -rf "$1" 2>/dev/null
  return 0
}

register_file() {
  if command -v register_file_custom >/dev/null 2>&1; then
    local c; c="$(register_file_custom "$1")"; [ -n "$c" ] && { echo "$c"; return; }
  fi
  case "$1" in
    ADR)            echo "$MEMORY_DIR/ADR.md" ;;
    BDR)            echo "$MEMORY_DIR/BDR.md" ;;
    LEARNINGS)      echo "$MEMORY_DIR/LEARNINGS.md" ;;
    BLOCKERS)       echo "$MEMORY_DIR/BLOCKERS.md" ;;
    ITERATION_LOG)  echo "$MEMORY_DIR/ITERATION_LOG.md" ;;
    EVALS)          echo "$MEMORY_DIR/EVALS.md" ;;
    DECISIONS)      echo "$MEMORY_DIR/DECISIONS.md" ;;
    JOURNAL)        echo "$MEMORY_DIR/JOURNAL.md" ;;
    *)              echo "" ;;
  esac
}

id_pattern() {
  if command -v id_pattern_custom >/dev/null 2>&1; then
    local c; c="$(id_pattern_custom "$1")"; [ -n "$c" ] && { echo "$c"; return; }
  fi
  case "$1" in
    ADR|DECISIONS)         echo "ADR-[0-9]+|DEC-[0-9]+" ;;
    BDR)                   echo "BDR-[0-9]+" ;;
    LEARNINGS)             echo "LRN-[0-9]+" ;;
    BLOCKERS)              echo "BLK-[0-9]+" ;;
    EVALS)                 echo "EVAL-[0-9]+" ;;
    ITERATION_LOG|JOURNAL) echo "Session [0-9]+" ;;
    *)                     echo "[A-Z]+-[0-9]+" ;;
  esac
}

# Extract IDs from index table (lines starting with `| <ID> |`)
extract_index_ids() {
  local file="$1"
  local pat="$2"
  grep -oE "^\| ($pat)" "$file" 2>/dev/null | grep -oE "$pat" | sort -u
}

# Extract IDs from body section headers (## <ID> ...)
extract_body_ids() {
  local file="$1"
  local pat="$2"
  grep -oE "^## ($pat)" "$file" 2>/dev/null | grep -oE "$pat" | sort -u
}

# Extract body section info: ID|line|date|title|resume_first_phrase
extract_body_sections() {
  local file="$1"
  local pat="$2"
  "$PYBIN" - "$file" "$pat" <<'PYEOF' 2>/dev/null
import re
import sys

file_path = sys.argv[1]
pat_str = sys.argv[2]

with open(file_path) as f:
    lines = f.readlines()

pat = re.compile(r'^## (' + pat_str + r')[^\n]*')
# Match **Date** : OR **Date ouverture** : OR **Date de creation** : etc.
date_pat = re.compile(r'^\*\*Date[^*]*\*\*\s*:\s*\[?(\d{4}-\d{2}-\d{2})')
sit_pat = re.compile(r'^###\s*(Situation|Contexte|Probleme|Symptome|Description|Apprentissage)', re.IGNORECASE)

i = 0
n = len(lines)
while i < n:
    m = pat.match(lines[i])
    if m:
        section_id = m.group(1)
        line_num = i + 1
        header = lines[i].rstrip('\n')
        title = re.sub(r'^## ' + re.escape(section_id) + r'\s*[:—-]?\s*', '', header).strip()
        if len(title) > 100:
            title = title[:97] + "..."

        date = ""
        first_phrase = ""
        in_resume_section = False
        j = i + 1
        end = min(n, i + 40)
        while j < end:
            line = lines[j].rstrip('\n')
            if not date:
                dm = date_pat.match(line)
                if dm:
                    date = dm.group(1)
            if not first_phrase:
                if sit_pat.match(line):
                    in_resume_section = True
                elif in_resume_section and line.strip() and not line.startswith('#') and not line.startswith('**'):
                    first_phrase = line.strip()
                    if len(first_phrase) > 80:
                        first_phrase = first_phrase[:77] + "..."
                    break
            j += 1

        title_safe = title.replace('|', '\\|')
        first_phrase_safe = first_phrase.replace('|', '\\|')
        print(f"{section_id}|{line_num}|{date}|{title_safe}|{first_phrase_safe}")
    i += 1
PYEOF
}

# ---------- Audit mode ----------
audit_register() {
  local register_name="$1"
  local file
  file=$(register_file "$register_name")

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    log "Registre $register_name introuvable"
    return 1
  fi

  local pat
  pat=$(id_pattern "$register_name")

  local index_ids body_ids
  index_ids=$(extract_index_ids "$file" "$pat" || true)
  body_ids=$(extract_body_ids "$file" "$pat" || true)

  local count_index count_body
  count_index=$(echo "$index_ids" | grep -c "." 2>/dev/null || echo 0)
  count_body=$(echo "$body_ids" | grep -c "." 2>/dev/null || echo 0)

  local orphans_in_index orphans_in_body
  orphans_in_index=$(comm -23 <(echo "$index_ids") <(echo "$body_ids") 2>/dev/null | grep -v "^$" || true)
  orphans_in_body=$(comm -13 <(echo "$index_ids") <(echo "$body_ids") 2>/dev/null | grep -v "^$" || true)

  local count_orphans count_undocumented
  count_orphans=$(echo "$orphans_in_index" | grep -c "." 2>/dev/null || echo 0)
  count_undocumented=$(echo "$orphans_in_body" | grep -c "." 2>/dev/null || echo 0)

  log "$register_name: $count_index index, $count_body bodies, $count_orphans orphan(s) index sans body, $count_undocumented body(s) sans index"

  echo "{"
  echo "  \"register\": \"$register_name\","
  echo "  \"file\": \"$file\","
  echo "  \"audit_mode\": true,"
  echo "  \"index_count\": $count_index,"
  echo "  \"body_count\": $count_body,"
  echo "  \"orphans_index_no_body\": $count_orphans,"
  echo "  \"orphans_body_no_index\": $count_undocumented,"
  echo "  \"orphans_index_no_body_list\": ["
  if [ -n "$orphans_in_index" ]; then
    echo "$orphans_in_index" | awk 'NR>1{printf ",\n"} {printf "    \"%s\"", $0}'
    echo ""
  fi
  echo "  ],"
  echo "  \"orphans_body_no_index_list\": ["
  if [ -n "$orphans_in_body" ]; then
    echo "$orphans_in_body" | awk 'NR>1{printf ",\n"} {printf "    \"%s\"", $0}'
    echo ""
  fi
  echo "  ]"
  echo "}"
}

# ---------- Dry-run / Apply mode ----------
reindex_one() {
  local register_name="$1"
  # pass=2 : passe de recalage CSL-08 (pas de nouveau backup, pas de 3e passe).
  local pass="${2:-1}"
  local file
  file=$(register_file "$register_name")

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    log "Registre $register_name introuvable"
    return 1
  fi

  local pat
  pat=$(id_pattern "$register_name")

  # CSL-09 : verrou atomique anti « lost update ». Deux sessions qui font un
  # read-modify-write simultane du meme registre : le mv du dernier ecrase le body
  # ajoute par l'autre (perte definitive). mkdir est atomique → verrou pris pour
  # TOUTE la sequence extraction → mv. Occupe → skip silencieux (fail-open : le
  # prochain edit du registre recalera l'index via le hook post-edit).
  local lock_dir="" lock_mtime lock_age
  if [ "$APPLY_MODE" = true ]; then
    lock_dir="$file.lock.d"
    if ! mkdir "$lock_dir" 2>/dev/null; then
      # mtime portable — GNU d'abord (l'ordre inverse renvoie silencieusement
      # le mount point sur GNU stat).
      lock_mtime=$(stat -c %Y "$lock_dir" 2>/dev/null || stat -f %m "$lock_dir" 2>/dev/null || echo 0)
      lock_age=$(( $(date +%s) - lock_mtime ))
      if [ "$lock_age" -ge 60 ]; then
        # Verrou perime (process tue en plein vol) : on le casse, une seule retentative.
        rm -rf "$lock_dir" 2>/dev/null || true
        if ! mkdir "$lock_dir" 2>/dev/null; then
          log "$register_name: lock occupe, skip (reindex concurrent)"
          return 0
        fi
      else
        log "$register_name: lock occupe (${lock_age}s), skip (reindex concurrent)"
        return 0
      fi
    fi
  fi

  local sections
  sections=$(extract_body_sections "$file" "$pat")

  local count
  count=$(echo "$sections" | grep -c "|" 2>/dev/null || echo 0)

  log "$register_name: $count entrees body detectees"

  if [ "$DRY_RUN" = true ] && [ "$AUDIT_MODE" = false ]; then
    echo "{"
    echo "  \"register\": \"$register_name\","
    echo "  \"file\": \"$file\","
    echo "  \"mode\": \"dry-run\","
    echo "  \"entries_count\": $count,"
    echo "  \"entries_preview\": ["
    local preview
    preview=$(echo "$sections" | head -5)
    if [ -n "$preview" ]; then
      echo "$preview" | awk -F'|' 'NR>1{printf ",\n"} {printf "    {\"id\":\"%s\",\"line\":%s,\"date\":\"%s\",\"title\":\"%s\",\"resume\":\"%s\"}", $1, $2, $3, $4, $5}'
      echo ""
    fi
    echo "  ]"
    echo "}"
    return 0
  fi

  # APPLY mode
  # CSL-01 (pre-garde fail-open) : un bloc '## Index' present mais JAMAIS referme par
  # une ligne '---' ferait tout perdre — l'awk de reecriture resterait en etat
  # in_index et jetterait le body ENTIER. Dans ce cas : ne RIEN reecrire
  # (check-registres.sh signale l'anomalie, la reparation est humaine).
  # Sans '## Index' du tout → chemin bootstrap plus bas (qui insere bloc + '---').
  local idx_state
  idx_state=$(awk 'f && /^---$/ {print "ok"; exit} /^## Index/ {f=1} END {if (!f) print "noindex"}' "$file")
  if [ -z "$idx_state" ]; then
    release_reindex_lock "$lock_dir"
    log "$register_name: bloc '## Index' sans terminateur '---' — reecriture ANNULEE (fail-open)"
    echo "{\"register\":\"$register_name\",\"mode\":\"skipped\",\"reason\":\"index_sans_terminateur\"}"
    return 0
  fi

  local tmp backup backup_dir base keep
  backup=""
  tmp=$(mktemp)
  # Backups ISOLÉS dans un sous-dossier dédié gitignoré (ADR-049) — ne polluent plus les registres.
  # Pass 2 (recalage CSL-08) : pas de nouveau backup — celui de la passe 1 (fichier
  # original) fait foi ; un backup intermediaire l'ecraserait (meme seconde).
  if [ "$pass" -eq 1 ]; then
    backup_dir="$(dirname "$file")/.backups"
    mkdir -p "$backup_dir"
    # .gitignore auto-suffisant : ignore tout le contenu (les backups) mais se conserve lui-même.
    # Le lab cible n'a donc RIEN à configurer — aucun backup n'entre dans git.
    [ -f "$backup_dir/.gitignore" ] || printf '*\n!.gitignore\n' > "$backup_dir/.gitignore"
    base="$(basename "$file")"
    backup="$backup_dir/${base}.bak-reindex-$(date +%Y%m%d-%H%M%S)"
    cp "$file" "$backup"
    log "Backup: $backup"
    # Rotation INTÉGRÉE (ADR-049) : ne garder que les N derniers backups de CE registre (défaut 3).
    # Dans reindex lui-même => TOUT --apply purge (plus seulement le hook post-edit).
    # Portable bash 3.2 (macOS) : pas de mapfile ; while-read + process substitution.
    keep="${VF_BACKUP_KEEP:-3}"
    local _old
    while IFS= read -r _old; do
      [ -n "$_old" ] && rm -f "$_old"
    done < <(ls -1t "$backup_dir/${base}.bak-reindex-"* 2>/dev/null | tail -n +"$((keep+1))")
  fi

  # Detect orphans: IDs in old index but without body (LRN-106 — must preserve)
  local index_ids body_ids orphans
  index_ids=$(extract_index_ids "$file" "$pat" || true)
  body_ids=$(extract_body_ids "$file" "$pat" || true)
  orphans=$(comm -23 <(echo "$index_ids") <(echo "$body_ids") 2>/dev/null | grep -v "^$" || true)

  # Build orphan lines via Python (robust extraction from old index line)
  # Strategy: concatenate all columns after Date as "title" to preserve info
  # whatever the registre format (ADR uses col3=Title, LEARNINGS uses col3=Cat col4=Title)
  local orphans_tmp
  orphans_tmp=$(mktemp)
  if [ -n "$orphans" ]; then
    "$PYBIN" - "$file" "$orphans_tmp" <<PYEOF
import re
import sys

file_path = sys.argv[1]
out_path = sys.argv[2]
orphan_ids = """$orphans""".strip().split('\n')

with open(file_path) as f:
    lines = f.readlines()

out_lines = []
for orphan_id in orphan_ids:
    if not orphan_id.strip():
        continue
    for line in lines:
        if line.startswith(f'| {orphan_id} '):
            parts = [p.strip() for p in line.strip().strip('|').split('|')]
            if len(parts) >= 2:
                old_id = parts[0]
                old_date = parts[1] if len(parts) > 1 else '—'
                # Concat all cols after Date as title (preserves info across registre formats)
                if len(parts) > 2:
                    title_parts = [p for p in parts[2:] if p and p not in ('—', '-')]
                    old_title = ' - '.join(title_parts) if title_parts else '[titre non recupere]'
                else:
                    old_title = '[titre non recupere]'
                # Truncate if too long
                if len(old_title) > 120:
                    old_title = old_title[:117] + '...'
                # Escape pipes in markdown table
                old_title = old_title.replace('|', r'\|')
                out_lines.append(f"{old_id}|—|{old_date}|{old_title}|[body non redige - voir BLK-005]")
            break

with open(out_path, 'w') as f:
    for ol in out_lines:
        f.write(ol + '\n')
PYEOF
  fi

  # Build new index block via temp file (avoid arg-list explosion)
  local idx_tmp
  idx_tmp=$(mktemp)
  {
    echo "| ID | Date | Titre | #Ligne | Resume |"
    echo "|----|------|-------|--------|--------|"
    # Body entries first (with #Ligne) — skip empty input (registre vide)
    if [ -n "$sections" ]; then
      echo "$sections" | awk -F'|' 'NF >= 5 && $1 != "" {
        id = $1; line = $2; date = $3; title = $4; resume = $5
        if (date == "") date = "—"
        if (resume == "") resume = "—"
        printf "| %s | %s | %s | %s | %s |\n", id, date, title, line, resume
      }'
    fi
    # Orphans (preserved from old index)
    if [ -s "$orphans_tmp" ]; then
      cat "$orphans_tmp" | awk -F'|' 'NF >= 5 && $1 != "" {
        id = $1; line = $2; date = $3; title = $4; resume = $5
        printf "| %s | %s | %s | %s | %s |\n", id, date, title, line, resume
      }'
    fi
  } > "$idx_tmp"

  # Bootstrap (ADR-043) : si le registre n'a pas encore de bloc '## Index' (registre
  # fraîchement créé, template v1, sortie d'init non conforme), l'INSÉRER après le titre
  # H1 (ou en fin de fichier à défaut), puis relancer une passe complète : l'insertion
  # décale les numéros de ligne du body, la 2e passe recalcule les #Ligne justes.
  if ! grep -q '^## Index' "$file"; then
    local boot_tmp
    boot_tmp=$(mktemp)
    awk -v idx_file="$idx_tmp" '
      BEGIN { inserted = 0 }
      {
        print
        if (!inserted && $0 ~ /^# /) {
          print ""
          print "## Index"
          print ""
          while ((getline line < idx_file) > 0) print line
          close(idx_file)
          print ""
          print "---"
          inserted = 1
        }
      }
      END {
        if (!inserted) {
          print ""
          print "## Index"
          print ""
          while ((getline line < idx_file) > 0) print line
          close(idx_file)
          print ""
          print "---"
        }
      }
    ' "$file" > "$boot_tmp"
    mv "$boot_tmp" "$file"
    rm -f "$idx_tmp" "$orphans_tmp" "$tmp"
    # Le verrou CSL-09 est libere AVANT la recursion (elle le reprend elle-meme).
    release_reindex_lock "$lock_dir"
    log "$register_name: bloc '## Index' cree (bootstrap) — 2e passe pour recaler les #Ligne"
    reindex_one "$register_name"
    return $?
  fi

  # Rewrite file
  local old_total new_total
  old_total=$(wc -l < "$file" | tr -d ' ')
  awk -v idx_file="$idx_tmp" '
    BEGIN { state = "before" }
    state == "before" {
      print
      if ($0 ~ /^## Index/) {
        state = "in_index"
      }
      next
    }
    state == "in_index" {
      if ($0 ~ /^---$/) {
        print ""
        while ((getline line < idx_file) > 0) print line
        close(idx_file)
        print ""
        print
        state = "after"
      }
      next
    }
    state == "after" { print }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
  new_total=$(wc -l < "$file" | tr -d ' ')
  local orphan_count
  if [ -n "$orphans" ]; then
    orphan_count=$(echo "$orphans" | grep -c "." 2>/dev/null) || orphan_count=0
  else
    orphan_count=0
  fi
  # Strip whitespace/newlines defensively
  orphan_count=$(echo "$orphan_count" | tr -d '\n ')
  rm -f "$idx_tmp" "$orphans_tmp"
  release_reindex_lock "$lock_dir"

  # CSL-08 : les #Ligne de l'index ont ete extraits du fichier AVANT reecriture. Si le
  # bloc index a change de taille (entree ajoutee/retiree, migration v1→v2), tout le
  # body a glisse d'autant → chaque #Ligne ecrit est faux, et tout l'edifice
  # index-first repose sur ces nombres. Une 2e passe sur le fichier FINAL recale les
  # positions ; elle converge (a entrees egales, le bloc index garde ensuite sa taille).
  if [ "$pass" -eq 1 ] && [ "$new_total" -ne "$old_total" ]; then
    log "$register_name: bloc index redimensionne ($old_total → $new_total lignes) — 2e passe de recalage des #Ligne"
    reindex_one "$register_name" 2
    return $?
  fi

  log "$register_name: index regenere ($count entrees body + $orphan_count orphan(s) preserve(s))"

  echo "{\"register\":\"$register_name\",\"entries_count\":$count,\"orphans_preserved\":$orphan_count,\"mode\":\"applied\",\"backup\":\"$backup\"}"
}

# ---------- Main ----------
process_register() {
  if [ "$AUDIT_MODE" = true ]; then
    audit_register "$1"
  else
    reindex_one "$1"
  fi
}

if [ "$ALL_REGISTERS" = true ]; then
  for r in ADR LEARNINGS BLOCKERS ITERATION_LOG EVALS DECISIONS JOURNAL; do
    f=$(register_file "$r")
    if [ -n "$f" ] && [ -f "$f" ]; then
      process_register "$r" || log "Skip $r (erreur)"
    fi
  done
elif [ -n "$TARGET_REGISTER" ]; then
  process_register "$TARGET_REGISTER"
else
  echo "Usage: $0 [--all | --register=NAME] [--audit | --dry-run | --apply]" >&2
  exit 1
fi

log "done"
