---
name: baseref-head-contamine-les-mesures-isolation
description: vibeflow-os porte worktree.baseRef head en settings local — toute mesure d'isolation faite depuis ce dépôt est verte pour la mauvaise raison, et rejoue la faille de fond de #38
metadata:
  type: project
---

`.claude/settings.local.json` de `vibeflow-os` porte `"worktree": { "baseRef": "head" }` (posé en
Phase 27, jamais retiré, constaté le 2026-08-26). C'est **le réglage repo-local qui a causé la
régression #38**. Toute mesure du comportement d'`isolation: worktree` faite depuis ce dépôt est
donc verte **chez le mainteneur et fausse chez l'utilisateur**.

**Why:** en Phase 35 j'ai rejoué WKTR-02 sur une branche réellement divergente et mesuré « le
worktree forke depuis le HEAD courant ». Vrai — mais uniquement grâce à ce réglage. Sur un lab sans
réglage, mesuré en appelant `evaluateWorktreeBaseDegrade` du moteur 1.11.0 installé
(`bin/lib/worktree-base-ref.cjs`) avec `effectiveBaseRef: null` et un HEAD divergent :
`shouldDegrade = true`, `reason = head-diverged-from-fork`, « Running this phase sequentially on the
main working tree ». C'est exactement la faille de fond de #38 rejouée dans l'instrument de mesure :
*le repo avait le réglage en settings local, donc tous les tests passaient chez nous*.

**How to apply:** ne JAMAIS conclure sur l'isolation à partir d'un dispatch réel fait depuis ce
dépôt. Mesurer les deux branches explicitement en appelant le moteur avec `effectiveBaseRef: null`
(lab propre) ET `'head'` (ce dépôt), et rapporter les deux. Corollaires durables :
- `resolveEffectiveBaseRef` prend un **claudeDir**, pas un cwd — lui passer la racine du dépôt rend
  `null` et ressemble à « pas de réglage ». Piège vérifié : j'ai failli en tirer un faux constat.
- Le défaut d'origine a **deux jambes** : leg A le retour des commits (fermé par gsd-core#3302,
  releasé en 1.11.0) et leg B la base de fork. Une preuve où la branche de test et la branche par
  défaut pointent le même commit ne teste **que** leg A, en paraissant tester les deux.
- `baseRef: "head"` n'est pas le remède : le moteur écrit lui-même qu'il *« silences this check
  without verifying the base »*. Un armement dont le réglage « sûr » éteint le contrôle n'en est pas
  un.

Voir [[re-mesurer-la-premisse-d-un-arbitrage]], [[verifier-contre-le-commit-de-base]] et
[[artefacts-descriptifs-non-testes]].
