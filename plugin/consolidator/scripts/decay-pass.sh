#!/usr/bin/env bash
# decay-pass.sh — Passe de decroissance + supersession de la memoire VIVANTE d'un lab VibeFlow
#
# Cible : la couche memoire vivante fichier-par-entree (.claude/memory/knowledge/),
# format frontmatter natif Claude Code (name / metadata.type + trust / confidence).
# NE touche PAS les registres tabulaires d'audit (DECISIONS/LEARNINGS/BLOCKERS...) —
# ceux-la restent geres par reindex.sh / archive.sh (ADR-052 : deux systemes distincts).
#
# Usage:
#   ./decay-pass.sh --dry-run                 # JSON, ne touche a rien (defaut)
#   ./decay-pass.sh --apply                   # recalcule + reecrit + archive les superseded
#   ./decay-pass.sh --apply --today=2026-07-22  # date de reference figee (tests deterministes)
#
# Geste (ADR-052, 3 gestes minimaux) :
#   - trust        : normalise en high|medium|low (defaut medium)
#   - confidence   : base 0..1 PRESERVEE + effective_confidence recalculee par demi-vie de categorie
#   - superseded_by: supersession NON destructive -> deplacement vers knowledge/archive/ (jamais rm)
#
# Formule (sans access-boost, reinforced[] hors perimetre) :
#   effective = confidence_base * 0.5 ^ (age_jours / demi_vie[type])   (borne [0,1], age borne >= 0)
# Demi-vies (jours, ADR-052 post-panel) : feedback 365 / user 180 / reference 120 / project 30.
#
# Idempotent : une 2e passe sans changement de date preserve la base et recalcule l'effective a
# l'identique (0 archivage parasite). Backup isole ADR-049 avant --apply. Reference : ADR-052.

set -euo pipefail

KNOWLEDGE_DIR="${KNOWLEDGE_DIR:-.claude/memory/knowledge}"
DRY_RUN=true
APPLY_MODE=false
TODAY=""
REVIEW_THRESHOLD="${VF_DECAY_REVIEW_THRESHOLD:-0.2}"
BACKUP_KEEP="${VF_BACKUP_KEEP:-3}"

# ---------- Arg parsing ----------
for arg in "$@"; do
  case "$arg" in
    --apply)     APPLY_MODE=true; DRY_RUN=false ;;
    --dry-run)   DRY_RUN=true ;;
    --today=*)   TODAY="${arg#*=}" ;;
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

log() { echo "[decay-pass.sh] $*" >&2; }

if [ ! -d "$KNOWLEDGE_DIR" ]; then
  log "Aucune memoire vivante ($KNOWLEDGE_DIR absent) — rien a faire."
  echo "{\"dir\": \"$KNOWLEDGE_DIR\", \"present\": false, \"entries_count\": 0, \"mode\": \"noop\"}"
  exit 0
fi

# ---------- Coeur (Python inline — pattern du module, cf. reindex.sh) ----------
python3 - "$KNOWLEDGE_DIR" "$APPLY_MODE" "$TODAY" "$REVIEW_THRESHOLD" "$BACKUP_KEEP" <<'PYEOF'
import sys, os, re, json, datetime, shutil, glob

lab        = sys.argv[1]
apply_mode = (sys.argv[2] == "true")
today_arg  = sys.argv[3].strip()
threshold  = float(sys.argv[4])
keep       = int(sys.argv[5])

today = datetime.date.fromisoformat(today_arg) if today_arg else datetime.date.today()
today_iso = today.isoformat()

# Demi-vies ADR-052 (post-panel). Fallback = project (le plus court) pour tout type inconnu.
HALF_LIVES = {"feedback": 365, "user": 180, "reference": 120, "project": 30}
HL_FALLBACK = 30
TRUST_VALID = {"high", "medium", "low"}
TRUST_DEFAULT = "medium"

# Ordre canonique du frontmatter reecrit (idempotence + format stable). Les cles hors de
# cette liste (extras du lab) sont preservees et re-emises avant les champs de decroissance.
CANON = ["name", "description", "metadata", "trust", "confidence",
         "effective_confidence", "created", "last_decay_pass",
         "status", "superseded_by", "needs_review"]

warnings = []

class Raw:
    """Bloc YAML indente (mapping OU liste) preserve VERBATIM — non lossy (fix H2)."""
    __slots__ = ("lines",)
    def __init__(self, lines):
        self.lines = lines

def parse_frontmatter(text):
    # Normalise CRLF / BOM avant parse (fix L3) — sinon frontmatter non detecte -> skip silencieux.
    text = text.replace("\r\n", "\n").replace("\r", "\n").lstrip("﻿")
    m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.DOTALL)
    if not m:
        return None, None, text
    raw, body = m.group(1), m.group(2)
    lines = raw.split("\n")
    fm, order = {}, []
    i, n = 0, len(lines)
    while i < n:
        line = lines[i]
        if line.strip() == "":
            i += 1
            continue
        if re.match(r"^\S", line):  # cle top-level
            key, _, val = line.partition(":")
            key, val = key.strip(), val.strip()
            # prochaine ligne non vide indentee ? -> bloc (mapping ou liste)
            j = i + 1
            while j < n and lines[j].strip() == "":
                j += 1
            is_block = (val == "" and j < n and re.match(r"^\s", lines[j]) is not None)
            if is_block:
                blk, k = [], i + 1
                while k < n and (lines[k].strip() == "" or re.match(r"^\s", lines[k])):
                    blk.append(lines[k])
                    k += 1
                while blk and blk[-1].strip() == "":  # trim lignes vides de fin de bloc
                    blk.pop()
                fm[key] = Raw(blk)
                order.append(key)
                i = k
                continue
            fm[key] = val
            order.append(key)
            i += 1
        else:
            i += 1  # ligne indentee orpheline (ne devrait pas arriver) — ignorer
    return fm, order, body

def get_type(fm):
    md = fm.get("metadata")
    if isinstance(md, Raw):
        for l in md.lines:
            mm = re.match(r"^\s*type:\s*(.*)$", l)
            if mm:
                return mm.group(1).strip().strip('"').strip("'")
    return ""

def dump_frontmatter(fm, order):
    out = ["---"]
    for key in order:
        v = fm.get(key, "")
        if isinstance(v, Raw):
            out.append(f"{key}:")
            out.extend(v.lines)  # verbatim — aucun re-parse, aucun trailing WS introduit (fix H2/M2)
        else:
            out.append(f"{key}: {v}" if str(v) != "" else f"{key}:")
    out.append("---")
    return "\n".join(out)

def canonical_order(order):
    extras = [k for k in order if k not in CANON]
    ordered = list(CANON)
    if extras:  # preserver les extras (y compris blocs Raw) juste avant les champs de decroissance
        anchor = ordered.index("trust")
        ordered = ordered[:anchor] + extras + ordered[anchor:]
    return ordered

def strip_q(v):
    return str(v).strip().strip('"').strip("'")

def eff_conf(base, age_days, half):
    # age borne >= 0 et effective bornee [0,1] : une date future ne doit pas gonfler la confiance (fix M1)
    age_days = max(0, age_days)
    return round(min(1.0, base * (0.5 ** (age_days / half))), 4)

archive_dir = os.path.join(lab, "archive")
backup_dir  = os.path.join(lab, ".backups")

def ensure_backup_dir():
    os.makedirs(backup_dir, exist_ok=True)
    gi = os.path.join(backup_dir, ".gitignore")
    if not os.path.exists(gi):
        with open(gi, "w") as fh:
            fh.write("*\n!.gitignore\n")

def backup_file(path):
    """Backup isole ADR-049 + rotation (garde les `keep` derniers de CE fichier)."""
    ensure_backup_dir()
    base = os.path.basename(path)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    shutil.copy2(path, os.path.join(backup_dir, f"{base}.bak-decay-{stamp}"))
    olds = sorted(glob.glob(os.path.join(backup_dir, f"{base}.bak-decay-*")), reverse=True)
    for old in olds[keep:]:
        os.remove(old)

def archive_dest(fname, new_text):
    """Destination d'archive NON ecrasante (fix H1) : jamais detruire une archive preexistante."""
    dest = os.path.join(archive_dir, fname)
    if os.path.exists(dest):
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        dest = os.path.join(archive_dir, f"{fname[:-3]}.superseded-{stamp}.md")
        warnings.append(f"{fname}: archive homonyme existante -> conservee, nouvelle en {os.path.basename(dest)}")
    return dest

entries, archived, flagged, skipped = [], [], [], []

files = sorted(f for f in os.listdir(lab)
               if f.endswith(".md") and f != "MEMORY.md" and os.path.isfile(os.path.join(lab, f)))

for fname in files:
    path = os.path.join(lab, fname)
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    fm, order, body = parse_frontmatter(text)
    if fm is None:
        skipped.append(fname)
        entries.append({"file": fname, "skipped": "no-frontmatter"})
        continue

    typ = get_type(fm)
    half = HALF_LIVES.get(typ, HL_FALLBACK)

    # geste 1 — trust normalise (trace la reparation si valeur invalide, fix L2)
    trust_raw = strip_q(fm.get("trust", TRUST_DEFAULT)).lower()
    trust = trust_raw if trust_raw in TRUST_VALID else TRUST_DEFAULT
    if trust != trust_raw and str(fm.get("trust", "")).strip():
        warnings.append(f"{fname}: trust invalide '{trust_raw}' -> '{TRUST_DEFAULT}'")

    # geste 2 — confidence effective (base preservee)
    conf_raw = strip_q(fm.get("confidence", "0.5"))
    try:
        base = float(conf_raw)
    except ValueError:
        base = 0.5
        warnings.append(f"{fname}: confidence non numerique '{conf_raw}' -> 0.5")
    created = strip_q(fm.get("created", today_iso))
    try:
        created_d = datetime.date.fromisoformat(created)
    except ValueError:
        created_d = today
        warnings.append(f"{fname}: created invalide '{created}' -> {today_iso}")
    age = (today - created_d).days
    eff = eff_conf(base, age, half)

    # geste 3 — supersession
    superseded_by = strip_q(fm.get("superseded_by", ""))
    status = strip_q(fm.get("status", "active")).lower()
    is_superseded = bool(superseded_by) or status == "superseded"

    # seuil de retrogradation (ADR-052 §6) : flag "a reverifier", JAMAIS suppression
    needs_review = (not is_superseded) and (eff < threshold)

    # reecriture du frontmatter (ordre canonique, base non lossy)
    fm["trust"] = trust
    fm["confidence"] = base
    fm["effective_confidence"] = eff
    fm["created"] = created
    fm["last_decay_pass"] = today_iso
    fm["status"] = "superseded" if is_superseded else "active"
    fm["superseded_by"] = superseded_by
    fm["needs_review"] = "true" if needs_review else "false"
    for k in ("trust", "confidence", "effective_confidence", "created",
              "last_decay_pass", "status", "superseded_by", "needs_review"):
        if k not in order:
            order.append(k)
    new_text = dump_frontmatter(fm, canonical_order(order)) + "\n" + body

    rec = {"file": fname, "type": typ or "?", "trust": trust,
           "confidence": base, "effective_confidence": eff,
           "age_days": max(0, age), "half_life": half}

    if is_superseded:
        rec["action"] = "archive"
        rec["superseded_by"] = superseded_by or "status:superseded"
        archived.append(fname)
        if apply_mode:
            os.makedirs(archive_dir, exist_ok=True)
            backup_file(path)
            dest = archive_dest(fname, new_text)  # non ecrasante (fix H1)
            with open(dest, "w", encoding="utf-8") as fh:
                fh.write(new_text)
            os.remove(path)  # retire de l'actif, CONSERVE dans archive/ (non destructif)
    else:
        rec["action"] = "rewrite"
        rec["needs_review"] = needs_review
        if needs_review:
            flagged.append(fname)
        if apply_mode:
            backup_file(path)
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(new_text)
    entries.append(rec)

for w in warnings:
    sys.stderr.write(f"[decay-pass.sh] WARN {w}\n")

out = {
    "dir": lab,
    "present": True,
    "mode": "applied" if apply_mode else "dry-run",
    "today": today_iso,
    "half_lives": HALF_LIVES,
    "review_threshold": threshold,
    "entries_count": len(entries) - len(skipped),
    "skipped_count": len(skipped),
    "archived_count": len(archived),
    "flagged_count": len(flagged),
    "archived": archived,
    "flagged_needs_review": flagged,
    "warnings": warnings,
    "entries": entries,
}
print(json.dumps(out, indent=2, ensure_ascii=False))
PYEOF

log "done"
