---
name: ou-vivent-les-adr
description: Les ADR de vibeflow-os sont dans docs/ADR.md et ne couvrent que ADR-046+ — les ADR les plus cités du codebase ne sont définis nulle part
metadata:
  type: reference
---

Registre ADR du repo : **`docs/ADR.md`** (pas `.claude/memory/ADR.md`, gitignoré ici). Il ne définit
que **ADR-046 → ADR-055**. Son en-tête assume que ADR-001→045 « prédatent ce registre ».

Conséquence mesurée le 2026-07-25 : les deux ADR **les plus cités de tout le codebase** n'ont
**aucune définition canonique** — ADR-031 (169 occurrences), ADR-029 (156), puis ADR-045 (70),
ADR-044 (58), ADR-030 (44), ADR-043 (39), ADR-032 (29). `grep -rE '^#+ *ADR-029'` → 0 résultat.

**Collision à connaître — ADR-031 porte deux doctrines incompatibles :**
- Sens A « vigilance support runtime » (ne pas inventer de convention non documentée)
- Sens B « jamais de correction sans validation humaine »

`plugin/validator/AGENT.md` utilise **les deux sens à 200 lignes d'écart** (`:18` et `:216`).
Collision similaire sur ADR-019 (`/session-close` vs `dette-detector`).

Utile aussi : la doctrine méthodologique livrée est sous `plugin/reference/content/methodology/`
(dont `AXIOMES-ENFORCEMENT.md`, la formulation canonique des 3 axiomes d'enforcement). La doc
**installée** (`docs/reference/`) est gitignorée et a dérivé de la source — ne pas l'utiliser comme
référence.

Quand je cite un ADR < 046 dans un rapport, ne pas prétendre qu'il est défini : le désigner par son
contenu et signaler l'absence de source.
