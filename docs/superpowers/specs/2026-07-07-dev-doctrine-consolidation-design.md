# Spec — Doctrine dev & consolidation des modules qualité

> Date : 2026-07-07
> Statut : design Phase 7 validé (brainstorming) ; Phase 8 cadrée, à détailler
> Repo : vibeflow-os
> Origine : audit du parc de modules vs `dev-orchestrator` (`scratchpad/AUDIT-modules-vs-dev-orchestrator.md`)

## 1. Vision

Deux objectifs enchaînés, issus de l'audit :

1. **Doter le parc des philosophies de dev manquantes** — SOLID est déjà couvert, mais **DRY est
   absent**, **Clean Architecture** et **Clean Code** sont présents mais **jamais nommés**, et **TDD**
   est délégué sans carte d'entrée. On comble ce trou dans le foyer doctrinal naturel :
   `software-architecture`.
2. **Consolider les doublons dev/qualité** — l'audit montre que les vrais recouvrements ne sont pas
   avec `dev-orchestrator` (pur routeur, sans doctrine) mais **entre les modules qualité entre eux**
   (`software-architecture`, `feature-dev-gates`, `audit-architecture`, `infrastructure-audit`).

**Ordre décidé** : Phase 7 (philosophies) **puis** Phase 8 (consolidation).

## 2. Constat d'audit (base factuelle)

| Fait | Preuve |
|---|---|
| `dev-orchestrator` ne porte AUCUNE doctrine de code | grep SOLID/DRY/TDD vide sur le module |
| SOLID couvert, 1 seul foyer | `software-architecture/references/solid-soc.md:5-26` |
| Clean Architecture présente mais non nommée | `solid-soc.md:28-39` (couches + Dependency Rule) |
| Clean Code présente mais non nommée | `solid-soc.md:58-74` (petites unités, `Result<T>`, contrats) |
| DRY totalement absent du parc | nulle part (seul « dry-run » de scripts) |
| TDD délégué au skill canonique | `universal-vs-dev.md:30`, `feature-dev-gates/rules/…:29` |
| Doublon structurel | `audit-architecture/references/examples-cross-domain.md:44-61` re-décrit 3 modules |
| 2 rules sur les mêmes globs | `production-code-architecture.md` ⟷ `feature-dev-gates.md` (`src/** app/** lib/** features/**`) |
| 3 axiomes dupliqués | « enforcement > prose », « filet de tests fonctionnel », « preuve avant done » (3-4 modules) |

## 3. Décisions structurantes (verrouillées)

| # | Décision | Choix |
|---|----------|-------|
| DD1 | Foyer doctrinal | **`software-architecture`** — pas `dev-orchestrator` (routeur sans doctrine ; y injecter violerait P9). `dev-orchestrator` reste le point d'entrée qui **route vers** la doctrine. |
| DD2 | Périmètre principes | **Cœur + KISS/YAGNI** : DRY (neuf) + KISS + YAGNI + nommer Clean Architecture + nommer Clean Code + carte TDD. |
| DD3 | Traitement TDD | **Carte + renvoi** au skill canonique `superpowers:test-driven-development` / `tdd`. **Pas** de mécanique dupliquée (respect DRY). |
| DD4 | Enforcement des principes non-mécanisables | **Tier 2 audit honnête** : items nommés dans la checklist de sprint (LLM-judge), **aucun faux gate machine**. Respecte l'Iron Law « un garde-fou non exécuté n'existe pas ». |
| DD5 | Anti-duplication (nous-mêmes) | **Nommer/pointer plutôt que réécrire** : Clean Archi/Clean Code déjà présents → étiquetés en place ; on n'écrit du neuf que pour DRY/KISS/YAGNI + carte TDD. |
| DD6 | Densité | Nouveaux `.md` sous les seuils VibeFlow (ADR-029 : skills ≤500L, references denses). |

---

## Phase 7 — Philosophies de dev (design détaillé, validé)

Enrichir `software-architecture` sans dupliquer l'existant.

### 7.1 `references/solid-soc.md` — nommage en place (0 contenu neuf)
- Titre de la section « Séparation des préoccupations » (l.28-39) →
  **« Séparation des préoccupations (SoC) = Clean Architecture — Dependency Rule »**. La règle
  « les dépendances pointent vers le domaine » est explicitement labellisée *Dependency Rule*.
- Section contrats typés / `Result<T>` / petites unités (l.58-74) → étiquetée **« Clean Code »**.

### 7.2 `references/principles.md` — NOUVEAU (seul contenu réellement neuf, ~100-130L)
Style identique à `solid-soc.md` (principe → test → signal → remède) :
- **DRY** — une seule source de vérité **pour une connaissance**. Nuance clé : DRY = dédup de
  *savoir*, pas de lignes qui se ressemblent → garde-fou anti sur-abstraction (lien YAGNI).
- **KISS** — la solution la plus simple qui marche ; signal = cleverness gratuite, couches inutiles.
- **YAGNI** — pas de généralité spéculative ; signal = params/config « au cas où » jamais utilisés.
- **Carte TDD** — cycle Red-Green-Refactor en ~5 lignes + quand l'appliquer + **renvoi** à
  `superpowers:test-driven-development` / `tdd`. Articulée avec le **Gate Nyquist** de
  `feature-dev-gates` (commande de vérif par critère AVANT le code).

### 7.3 `SKILL.md` — câblage honnête
- **Tier 2** (l.45-48) : +3 items nommés — **DRY**, **KISS/YAGNI**, **Clean Code** (audit de sprint /
  LLM-judge). Pas de faux gate machine (DD4).
- **Tier 1** : +1 ligne TDD (test-first quand critère mesurable → carte TDD + Nyquist).
- **Liste « Références »** (l.72-75) : ajout de `principles.md`.
- **Frontmatter `description`** : ajout de DRY/KISS/YAGNI/Clean Code/Clean Architecture/TDD
  (découvrabilité + trigger 1% Rule).

### 7.4 `references/universal-vs-dev.md` — cohérence P9
- Table universelle (l.15-24) : +3 lignes DRY/KISS/YAGNI avec transposition non-dev
  (ex. DRY → source de vérité unique d'un document/process).

### 7.5 Méta-release (au ship de la phase)
- `software-architecture/module.json` : description élargie + bump **v1.1.0 → v1.2.0** (capacité = minor).
- `software-architecture/CHANGELOG.md` + `README.md` mis à jour.
- Évolution de la doctrine **ADR-035** (pas un nouvel ADR).
- **Règle non-négociable du repo** : tout bump de la `VERSION` **racine** impose un tag `vX.Y.Z`
  (`scripts/check-release-tag.sh`). À traiter au ship global, pas à la phase module.

### 7.6 Hors périmètre Phase 7
- Aucune fusion de module, aucune dé-dup d'`audit-architecture`, aucun nouvel outillage/gate machine.

---

## Phase 8 — Consolidation des doublons (cadrée, à détailler)

> Design détaillé à produire via un `discuss-phase`/`plan-phase` dédié après la Phase 7.
> Les items ci-dessous sont les **cibles** issues de l'audit, pas encore des décisions verrouillées.

### 8.1 Fusion `feature-dev-gates` → `software-architecture`
Deux rules path-scopées sur **les mêmes globs** ; les gates recoupent le Tier 1. Cible : **une rule
unique** de gates de code (taille + Nyquist + Decision Coverage), un seul foyer. À trancher :
conserver `feature-dev-gates` comme module mince déprécié (rétro-compat) vs le retirer proprement.

### 8.2 Dé-duplication d'`audit-architecture`
- Remplacer l'**Instance C** (`examples-cross-domain.md:44-61`), qui re-décrit software-architecture
  + feature-dev-gates + infrastructure-audit, par des **renvois** vers ces modules.
- Corriger la **description legacy erronée** de sa `module.json:5`.
- Garder son rôle méta (concepteur d'architectures d'audit) intact.

### 8.3 Factorisation des 3 axiomes
« enforcement > prose » (LRN-118), « filet de tests fonctionnel », « preuve avant done » sont
répétés dans 3-4 modules. Cible : **une source unique** (probablement `reference/`) + renvois.

### 8.4 Invariant à préserver
`dev-orchestrator` **reste un pur routeur** — aucune doctrine injectée (DD1). La consolidation ne
change pas sa nature ; elle assainit le cluster qualité en amont.

### 8.5 Dette de maintenance associée
Resynchroniser les versions README ↔ module.json des modules qualité (dérives constatées).

---

## 4. Critères de succès (milestone)

**Phase 7 (mesurable) :**
1. `grep -ri "DRY"` sur `software-architecture/` remonte une doctrine DRY réelle (pas « dry-run »).
2. « Clean Architecture » et « Clean Code » apparaissent **nommés** dans `solid-soc.md`.
3. `principles.md` existe, contient DRY + KISS + YAGNI + carte TDD renvoyant au skill canonique.
4. `SKILL.md` Tier 2 liste DRY/KISS-YAGNI/Clean Code ; la liste des références inclut `principles.md`.
5. Aucun nouveau gate machine ajouté (DD4) ; densité des `.md` sous seuils (ADR-029).

**Phase 8 (goal-backward, à préciser) :**
1. Un seul foyer de rule de gates de code (plus de doublon de globs).
2. `audit-architecture` renvoie au lieu de dupliquer ; sa `module.json` est corrigée.
3. `dev-orchestrator` inchangé (invariant routeur vérifié).

## 5. Risques

- **Sur-abstraction en écrivant DRY** — ironie à éviter : la carte DRY doit elle-même prêcher la
  nuance « dédup de savoir, pas de lignes ». Mitigation : inclure le contre-exemple YAGNI.
- **Faux gate** — tentation d'outiller DRY (jscpd) : écartée par DD4 (Tier 2 honnête).
- **Phase 8 plus lourde qu'elle n'en a l'air** — fusion de module = rétro-compat install/déps.
  Mitigation : la détailler dans son propre discuss/plan, ne rien retirer sans plan de migration.
