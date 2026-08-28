---
name: litteral-garde-coupe-par-le-gras
description: Le gras markdown casse deux consommateurs muets — un littéral gardé par grep -qF, et le parseur de décisions D-NN de GSD (gras multi-ligne, ou `*` littéral à l'intérieur du gras).
metadata:
  type: project
---

Une assertion machine qui exige un littéral dans un `.md` (`grep -qF "deux niveaux de marge"`)
échoue si la prose l'a mis **en gras à cheval sur un retour à la ligne** : le fichier contient
`**deux\nniveaux de marge**`, jamais la chaîne cherchée. Constaté le 2026-08-04 en posant la
section « marge de profondeur de dispatch » de `plugin/conductor/references/team-kernel.md`,
gardée par T76 de `test-check-agents.sh`.

**Why:** ce dépôt garde beaucoup de doctrine par littéraux (T72, T76, les sondes de recette). Le
défaut est invisible à la relecture — la phrase se lit parfaitement, seul le `grep -qF` la rate —
et le réflexe est alors d'accuser l'assertion, puis de l'affaiblir en découpant le littéral en
morceaux. C'est le mauvais correctif : il rend la garde satisfiable par du texte qui ne dit plus
rien.

**How to apply:** quand tu ajoutes une section gardée par littéraux, écris la phrase porteuse en
**texte nu, sur une seule ligne**, et mets le gras ailleurs (ou sur la phrase entière, jamais à
cheval). Si un littéral manque au premier run, vérifie d'abord l'enrobage markdown et le retour à
la ligne avant de toucher à l'assertion. Vaut aussi pour les valeurs recopiées « verbatim » d'un
descripteur : `subagentToolkit: "full"` doit garder ses guillemets exacts. Le corollaire est en
[[feedback_gate-jamais-de-repli]] — un littéral introuvable rend un KO, jamais un vert par
vérification plus faible.

**Second consommateur muet, mesuré le 2026-08-10 (Phase 28) : le parseur de décisions de GSD.**
`check.decision-coverage-plan` (gate **bloquant** de `gsd-plan-phase`) et `gap-analysis.plan-post`
lisent les puces `- **D-NN — …**` d'un `CONTEXT.md`. Deux formes les cassent, **silencieusement
sauf une ligne `parseDecisions: ignored unparseable decision bullet`** :

1. **un `*` littéral à l'intérieur du gras** — `- **D-02 — … un \`ensure-*.sh\` déclaré …**` :
   l'astérisque de `ensure-*.sh` termine le gras au mauvais endroit ;
2. **le gras à cheval sur deux lignes** — même défaut que ci-dessus.

Sur 8 décisions, 3 ont été perdues (D-02, D-02b, D-03) et le gate a rendu
`passed:false, reason:"could-not-parse", covered:0` — **un échec de forme qui se présente comme un
manque de couverture**. Ne « re-planifie » jamais sur ce verdict sans regarder `reason` d'abord :
`could-not-parse` ≠ `uncovered`, et la couverture réelle se fait vérifier autrement (le
`gsd-plan-checker` l'a confirmée). Corollaire d'écriture : dans un `CONTEXT.md`, garde les
identifiants à astérisque (`ensure-*.sh`, `mcp__*`) **hors** du titre en gras d'une puce `D-NN`.
