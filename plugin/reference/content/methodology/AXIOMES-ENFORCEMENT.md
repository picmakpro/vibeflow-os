# Axiomes d'enforcement — doctrine transverse VibeFlow

> **Source de vérité unique** des trois axiomes qui reviennent dans plusieurs modules
> (`software-architecture`, `audit-architecture`, `infrastructure-audit`, `mobile-test`). Ces modules
> **appliquent** ces axiomes dans leur contexte ; ils ne les **redéfinissent** pas — ils renvoient ici.
> Spécialise le principe Core **P8 — Évaluer**.

## Axiome 1 — Enforcement > prose (LRN-118)

**Un garde-fou qui n'est pas exécuté par la machine n'existe pas.** Une règle écrite dans un CLAUDE.md,
un README ou une doc — que le développeur ou l'IA peut ignorer — **n'est pas** un garde-fou : c'est un
vœu. Le seul garde-fou qui tienne est *machine-enforced* : hook, CI, lint bloquant, test, gate, rubric
de juge-LLM avec verdict bloquant.

- **Corollaire** : entre deux mécanismes équivalents, préférer celui qui **bloque** à celui qui *alerte*.
- **Origine** : LRN-118 (diagnostic terrain Permis Clair — les règles en prose étaient toutes contournées).

## Axiome 2 — Le filet de tests fonctionnel, avant tout

**Un filet de tests qui ne s'exécute pas (ou dont on ignore le rouge) n'est pas un filet.** Avant toute
modification dans un projet dont la suite est cassée, on **répare le filet d'abord** — sinon chaque
changement suivant est aveugle. Un test rouge « mais le code marche » invalide la couche de
non-régression entière.

- **Corollaire** : un filet décoratif (présent mais non exécuté) est pire que pas de filet — il donne
  une fausse assurance.

## Axiome 3 — Preuve exécutable avant « done »

**Aucune complétion ne se déclare sans preuve exécutable.** Un critère d'acceptation sans commande de
vérification (pass/fail) est un critère non prouvable → il ne peut pas être marqué fait. La preuve
précède le claim, pas l'inverse (Gate Nyquist ; vérification 3 couches syntaxe → intention → régression).

- **Corollaire** : « on vérifiera à l'œil » = completion hallucinée. Seule exception tracée : un critère
  purement visuel non automatisable, tagué explicitement pour revue humaine.

---

## Qui applique quoi

| Module | Application des axiomes |
|--------|-------------------------|
| `software-architecture` | Axiome 1 (Iron Law, gates machine) + Axiome 2 (anti-pattern filet décoratif) + Axiome 3 (Tier 1, Gate Nyquist) |
| `audit-architecture` | Les 3 comme spectre d'enforcement des couches d'audit (script ↔ test ↔ rubric) |
| `infrastructure-audit` | Axiome 1 (détection machine) — « un WARNING ignoré = ERROR en gestation » |
| `mobile-test` / `mobile-test-team` | Axiome 3 (preuve runtime réelle avant *done*) + cloisonnement anti-triche |
