---
name: description-repliee-casse-les-convertisseurs
description: 16 SKILL.md de VibeFlow écrivent `description: >` (scalaire replié YAML) — les convertisseurs gsd-core détruisent la description, réduite au littéral « > », sur les 3 cibles
metadata:
  type: project
---

Mesuré en Phase 37 (2026-08-28). **16 fichiers `SKILL.md` du dépôt écrivent `description: >`** — un
scalaire replié YAML. `extractFrontmatterField` de gsd-core ne gère pas cette forme : à la
conversion vers codex, opencode et kimi-code, la description est **réduite au littéral `>`**, donc
détruite. Environ 15 des 21 skills installables sont touchés, sur **les trois cibles**.

**Why:** la `description` est ce qui rend un skill déclenchable — c'est le champ sur lequel un
runtime décide d'invoquer ou non. Sa destruction est une panne totale du skill, et elle survient
avec **0 exception, 0 diagnostic** : la conversion rend une chaîne, tout paraît vert. C'est la
dégradation silencieuse la plus grave trouvée pendant le spike, et elle a été **manquée par la
mesure de fidélité initiale**, qui déclarait la couverture skills totale (« 21/21 skills reçoivent
le bloc adaptateur ») et concentrait toute la dégradation sur les agents. Elle n'a été trouvée qu'au
deuxième tour de revue adversariale, par un juge qui a rejoué les convertisseurs lui-même.

**How to apply:** deux usages. (1) Sur toute question de portabilité VibeFlow, ce cas est l'exemple
canonique à citer pour justifier un **gate de fidélité** — un compteur de champs perdus après
conversion, sans lequel rien ne distingue « converti » de « converti et mort ». (2) C'est aussi un
défaut **corrigeable côté VibeFlow sans rien attendre de l'amont** : écrire les `description:` sur
une seule ligne les rendrait convertibles. Le chiffrer avant de le proposer, et ne jamais le lancer
sans arbitrage humain (ADR-031). Voir [[feedback_descripteur-gsd-core-non-probant]] et
[[artefacts-descriptifs-non-testes]].
