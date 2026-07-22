#!/usr/bin/env python3
"""
Prototype de passe `consolidator` — spike Phase 9 (transposition jcode).
NON destructif, NON intégré au skill officiel `plugin/consolidator/`.

Geste prototypé (3 champs minimaux, D-03) :
  - trust        : high | medium | low   (normalisé)
  - confidence   : 0..1 base + effective_confidence recalculée par demi-vie de catégorie
  - superseded_by: supersession NON destructive (archive, jamais suppression)

Round-trip : lit -> recalcule -> réécrit toutes les entrées, sans édition humaine.
Une entrée `status: superseded` (ou portant `superseded_by`) est déplacée vers `archive/`
avec `status: superseded` (contenu conservé). Aucune suppression.

Formule de décroissance (minimale — sans access boost, reinforced[] hors périmètre) :
    effective = base_confidence * 0.5 ** (age_days / half_life_days[type])

Usage :
    python3 decay-pass.py <lab_dir> [--today YYYY-MM-DD] [--calibration jcode|vibeflow]
"""
import sys, os, re, math, datetime, shutil, argparse

# Demi-vies (jours). 'jcode' = valeurs brutes de départ (D-04). 'vibeflow' = recalibré multi-métiers.
HALF_LIVES = {
    "jcode":   {"feedback": 365, "user": 90,  "reference": 60,  "project": 30},
    "vibeflow":{"feedback": 365, "user": 180, "reference": 120, "project": 45},
}
TRUST_VALID = {"high", "medium", "low"}
TRUST_DEFAULT = "medium"

def parse_frontmatter(text):
    """Parseur minimal : top-level 'key: value' + un bloc imbriqué 'metadata:' (indent 2)."""
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
    if not m:
        return None, None, text
    raw, body = m.group(1), m.group(2)
    lines = raw.split("\n")
    fm, order = {}, []
    cur_parent = None
    for i, line in enumerate(lines):
        if not line.strip():
            continue
        if re.match(r"^\S", line):  # top-level
            key, _, val = line.partition(":")
            key = key.strip(); val = val.strip()
            # Un `key:` sans valeur n'est un BLOC que si la ligne suivante non vide est indentée.
            next_indented = False
            for nxt in lines[i + 1:]:
                if not nxt.strip():
                    continue
                next_indented = bool(re.match(r"^\s+\S", nxt))
                break
            if val == "" and next_indented:
                fm[key] = {}
                order.append((key, True))
                cur_parent = key
            else:
                fm[key] = val  # scalaire (éventuellement vide "")
                order.append((key, False))
                cur_parent = None
        else:  # nested (indent)
            key, _, val = line.strip().partition(":")
            if cur_parent is not None and isinstance(fm.get(cur_parent), dict):
                fm[cur_parent][key.strip()] = val.strip()
    return fm, order, body

def get_type(fm):
    md = fm.get("metadata")
    if isinstance(md, dict):
        return md.get("type", "").strip().strip('"')
    return ""

def strip_quotes(v):
    return v.strip().strip('"').strip("'")

def dump_frontmatter(fm, order, body):
    lines = ["---"]
    for key, is_block in order:
        if is_block:
            lines.append(f"{key}:")
            for k, v in fm[key].items():
                lines.append(f"  {k}: {v}")
        else:
            v = fm.get(key, "")
            lines.append(f"{key}: {v}")
    lines.append("---")
    return "\n".join(lines) + "\n" + body

def effective_confidence(base, age_days, half_life):
    return round(base * (0.5 ** (age_days / half_life)), 4)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lab_dir")
    ap.add_argument("--today", default=datetime.date.today().isoformat())
    ap.add_argument("--calibration", default="jcode", choices=list(HALF_LIVES))
    args = ap.parse_args()

    today = datetime.date.fromisoformat(args.today)
    hl = HALF_LIVES[args.calibration]
    lab = args.lab_dir
    archive_dir = os.path.join(lab, "archive")
    os.makedirs(archive_dir, exist_ok=True)

    report = []
    archived = []
    files = sorted(f for f in os.listdir(lab)
                   if f.endswith(".md") and f != "MEMORY.md")
    for fname in files:
        path = os.path.join(lab, fname)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        fm, order, body = parse_frontmatter(text)
        if fm is None:
            report.append(f"  SKIP {fname} (pas de frontmatter)")
            continue

        typ = get_type(fm)
        half = hl.get(typ, 30)

        # --- geste 1 : trust normalisé
        trust = strip_quotes(str(fm.get("trust", TRUST_DEFAULT))).lower()
        if trust not in TRUST_VALID:
            trust = TRUST_DEFAULT
        fm["trust"] = trust

        # --- geste 2 : confidence effective recalculée
        try:
            base = float(strip_quotes(str(fm.get("confidence", "0.5"))))
        except ValueError:
            base = 0.5
        created = strip_quotes(str(fm.get("created", args.today)))
        try:
            created_d = datetime.date.fromisoformat(created)
        except ValueError:
            created_d = today
        age = (today - created_d).days
        eff = effective_confidence(base, age, half)
        fm["confidence"] = base
        fm["effective_confidence"] = eff
        fm["created"] = created
        fm["last_decay_pass"] = args.today

        # --- geste 3 : supersession non destructive
        superseded_by = strip_quotes(str(fm.get("superseded_by", ""))).strip()
        status = strip_quotes(str(fm.get("status", "active"))).lower()
        is_superseded = bool(superseded_by) or status == "superseded"

        # garder l'ordre : injecter les clés manquantes juste après metadata
        for k in ("trust", "confidence", "effective_confidence", "created",
                  "last_decay_pass", "status", "superseded_by"):
            if k not in [o[0] for o in order]:
                order.append((k, False))
        if is_superseded:
            fm["status"] = "superseded"
        else:
            fm.setdefault("status", "active")
            fm["status"] = "active" if status != "superseded" else "superseded"

        new_text = dump_frontmatter(fm, order, body)

        if is_superseded:
            # ARCHIVE non destructive : déplacer vers archive/, contenu conservé
            dest = os.path.join(archive_dir, fname)
            with open(dest, "w", encoding="utf-8") as fh:
                fh.write(new_text)
            os.remove(path)  # retiré du répertoire actif, PAS supprimé (copie en archive/)
            archived.append((fname, superseded_by))
            report.append(f"  ARCHIVE {fname:32s} -> archive/  (superseded_by={superseded_by or 'status'})")
        else:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(new_text)
            report.append(f"  RÉÉCRIT {fname:32s} type={typ:10s} trust={trust:6s} "
                          f"conf {base}->eff {eff}  (age {age}j / HL {half}j)")

    print(f"# Passe consolidator (prototype) — {args.calibration} — today={args.today}")
    print(f"# lab: {lab}\n")
    print("\n".join(report))
    print(f"\n# Archivées (non destructif) : {len(archived)}")
    for f, s in archived:
        print(f"  - {f} (superseded_by {s or 'status:superseded'}) conservée dans archive/")

if __name__ == "__main__":
    main()
