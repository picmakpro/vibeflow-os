#!/usr/bin/env python3
"""
Seed du lab témoin (fixture reproductible) pour le spike Phase 9.
Graine = l'entrée RÉELLE de la mémoire de session de ce repo (projet-alpha-emplacement,
type project) + 4 entrées synthétiques calibrées couvrant les 4 types VibeFlow.
Une entrée est marquée `superseded_by` pour tester l'archivage non destructif.

La mémoire de session réelle n'est PAS modifiée : on la copie ici comme fixture.
Usage : python3 seed-lab.py <lab_dir>
"""
import sys, os

ENTRIES = {
    # --- entrée RÉELLE recopiée de ~/.claude/projects/.../memory/ (type project) ---
    "projet-alpha-emplacement.md": """---
name: projet-alpha-emplacement
description: "Le projet « Alpha » de Samuel vit dans ~/dev/projet-alpha (pas projet Bêta)"
metadata:
  node_type: memory
  type: project
trust: high
confidence: 0.9
created: 2026-07-09
status: active
superseded_by:
---

Quand Samuel parle de « Alpha » (app mobile, Expo/Supabase), le repo est
`~/dev/projet-alpha`. Pattern d'équipe d'agents généralisé dans vibeflow-os v2.23.0.
""",
    # --- feedback (ex-Correction, HL long : le moat VibeFlow) ---
    "commits-francais-scroll-off.md": """---
name: commits-francais-scroll-off
description: "Samuel veut les commits en français, sans mention IA sur Scroll-Off"
metadata:
  node_type: memory
  type: feedback
trust: high
confidence: 0.95
created: 2026-01-03
status: active
superseded_by:
---

Sur Scroll-Off, aucune mention de Claude/IA dans commits ni PR (Samuel seul contributeur visible).
**Why:** convention d'attribution du projet. **How to apply:** vérifier la convention avant tout commit.
""",
    # --- user (ex-Preference, HL moyen : le rôle évolue lentement) ---
    "user-freelance-multi-metiers.md": """---
name: user-freelance-multi-metiers
description: "Samuel est freelance, gère plusieurs projets multi-métiers (dev, iOS, marketing)"
metadata:
  node_type: memory
  type: user
trust: medium
confidence: 0.8
created: 2026-03-24
status: active
superseded_by:
---

Samuel opère un portefeuille de projets hétérogènes (SaaS, apps iOS, sites vitrine, outils Malt).
Framer les explications en tenant compte de ce contexte multi-métiers.
""",
    # --- reference (ex-Entity, HL moyen : les systèmes externes bougent avec l'outillage) ---
    "reference-rtk-proxy.md": """---
name: reference-rtk-proxy
description: "RTK est un proxy CLI token-optimisé ; rtk gain montre les économies"
metadata:
  node_type: memory
  type: reference
trust: medium
confidence: 0.7
created: 2026-04-23
status: active
superseded_by:
---

RTK (Rust Token Killer) réécrit les commandes CLI pour économiser des tokens.
`rtk gain` = analytics ; `rtk proxy <cmd>` = commande brute non filtrée.
""",
    # --- project SUPERSEDED (test archivage non destructif) ---
    "projet-alpha-emplacement-obsolete.md": """---
name: projet-alpha-emplacement-obsolete
description: "ANCIENNE croyance erronée : projet source serait dans ~/Documents/dev/projet Bêta"
metadata:
  node_type: memory
  type: project
trust: low
confidence: 0.6
created: 2026-04-13
status: active
superseded_by: projet-alpha-emplacement
---

Note initiale (erronée) : le repo de projet source aurait été « projet Bêta ». Corrigé : c'est projet Alpha.
Conservée pour trace, remplacée par [[projet-alpha-emplacement]].
""",
}

MEMORY_MD = """- [projet source = projet Alpha](projet-alpha-emplacement.md) — repo de projet source = ~/dev/projet-alpha
- [Commits FR Scroll-Off](commits-francais-scroll-off.md) — commits français, zéro mention IA
- [User freelance multi-métiers](user-freelance-multi-metiers.md) — portefeuille de projets hétérogènes
- [RTK proxy](reference-rtk-proxy.md) — proxy CLI token-optimisé
- [projet source = projet Bêta](projet-alpha-emplacement-obsolete.md) — SUPERSEDED par projet-alpha-emplacement
"""

def main():
    lab = sys.argv[1]
    os.makedirs(lab, exist_ok=True)
    for name, content in ENTRIES.items():
        with open(os.path.join(lab, name), "w", encoding="utf-8") as fh:
            fh.write(content)
    with open(os.path.join(lab, "MEMORY.md"), "w", encoding="utf-8") as fh:
        fh.write(MEMORY_MD)
    print(f"Seeded {len(ENTRIES)} entrées + MEMORY.md dans {lab}")

if __name__ == "__main__":
    main()
