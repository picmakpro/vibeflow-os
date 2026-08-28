---
name: pre-push-candidat-rce-non-corrige
description: scripts/hooks/pre-push exécute un chemin dérivé de git rev-parse --show-toplevel sans confinement — candidat au même motif que dag.sh/mission-contracts.md, PAS corrigé, mandat séparé requis
metadata:
  type: project
---

`scripts/hooks/pre-push:8` fait `root="$(git rev-parse --show-toplevel)"` puis
`bash "$root/scripts/check-release-tag.sh"` — un exécutable dérivé d'une racine de dépôt,
réellement EXÉCUTÉ. Trouvé lors du balayage repo-wide du mandat qui a fermé la variante
`toplevel` du vecteur RCE dans `plugin/dev-orchestrator/references/mission-contracts.md`
(commit `08ad030`, 2026-08-06), sur le même motif que `dag.sh` (ADR-070, commit `4a532ec`).

**Pourquoi ce n'est probablement PAS le même vecteur** (mais pas prouvé négatif) : ce hook est
opt-in (`git config core.hooksPath scripts/hooks`, geste local manuel), et ne s'active que sur
`git push` vers `main` DEPUIS le clone où l'opérateur l'a activé — contrairement à `dag.sh`,
jamais invoqué depuis un CWD arbitraire par les cinq managers du team-kernel. Reste un scénario
non écarté : `git worktree add` sur une branche hostile + push vers main depuis ce worktree,
où `$root` résoudrait la racine du worktree hostile.

**Ne pas corriger seul(e)** : le retrait d'un candidat mérite un test de non-régression dédié
(le précédent de `dag.sh` — T33 — en est le patron), pas un correctif à la volée. Voir
[project_plans-code-normatif](project_plans-code-normatif.md) sur la même discipline de mandat
séparé.
