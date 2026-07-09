---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "src/**/*.js"
  - "src/**/*.jsx"
  - "app/**/*.ts"
  - "app/**/*.tsx"
  - "lib/**/*.ts"
  - "features/**/*.ts"
  - "features/**/*.tsx"
  - "components/**"
  - "package.json"
  - "**/*.lock"
  - "Podfile*"
  - "build.gradle*"
---

# Règle — Recherche documentaire avant debug (doc-research-before-debug)

> Rule **path-scopée** : se charge automatiquement dès qu'on touche du code applicatif ou un
> manifeste de dépendances. Sur un projet sans ces chemins, elle reste dormante.
> Principe VibeFlow : *enforcement > prose*. L'application **active** (au moment où l'on part
> dépanner) est portée par le skill `vf-debug`, l'agent `vibeflow-dev` et, en boucle autonome,
> l'agent `vf-test-orchestrator`. Cette rule est le filet path-scopé ; elle **référence** ces
> briques sans dupliquer leur logique.

## ADR Applicables
- **ADR-045** : Recherche documentaire obligatoire avant debug empirique — prolonge **LRN-106
  « Audit avant fix »**. La cause d'un bug de lib/framework/natif/version est souvent déjà connue
  et documentée : la chercher coûte quelques minutes, la deviner coûte des cycles.

## Iron Law

**Sur tout bug lié à une lib / un framework / du code natif / une version d'OS-SDK — OU après un
correctif qui a déjà échoué — la recherche documentaire PRÉCÈDE le debug empirique intensif.**
On ne tâtonne pas avant d'avoir cherché une cause connue.

## Déclencheurs (l'un suffit)
- Le bug implique une **dépendance tierce**, une **API de framework**, du **code natif**, ou son
  apparition **dépend d'une version d'OS / de SDK**.
- Un **premier correctif a échoué** (≥ 1 tentative infructueuse sur le même symptôme) et l'on
  s'apprête à creuser.

## Protocole Obligatoire (avant toute tentative empirique)
1. **context7** — `resolve-library-id` puis `query-docs` sur la/les lib(s) concernée(s) :
   comportement documenté, breaking changes, notes de version, correctifs postérieurs.
2. **WebSearch / WebFetch** — issues GitHub (numéro, statut, **versions affectées ET corrigées**),
   release notes, matrice de compatibilité OS/SDK. Chercher l'erreur exacte entre guillemets.
3. **But** : trouver une **cause connue / un fix documenté** avant d'expérimenter.

## Sortie attendue
Pistes **priorisées et sourcées**, du plus robuste au plus fragile :
1. **Fix robuste** — upgrade de version, configuration documentée. **À privilégier en livraison client.**
2. **Contournement intermédiaire** documenté.
3. **Hack fragile** — **jamais appliqué sans arbitrage humain explicite** (ADR-031).

Chaque piste **cite sa source** (lien issue, numéro de version, page de doc).

## Articulation avec l'anti-thrash (garde-fou 1)
- La recherche **précède** les tentatives ; elle **ne consomme pas** de slot de tentative de fix
  (`maxAttemptsPerFlow`) mais **ne l'augmente pas** non plus.
- Elle **compte** dans le budget global temps/tokens (garde-fou 3 :
  `maxWallClockMinutes` / `maxTokens`), et dans un budget dédié `maxResearchRoundsPerFlow`.
- On ne part en **debug empirique** que si la recherche **ne donne rien**.
- Compteur de tentatives épuisé → **HALT normal** : la recherche ne rouvre pas le budget. Elle rend
  les tentatives *informées*, elle ne les *remplace* pas.

## Pièges Connus
- **Debug empirique d'abord, doc ensuite** : c'est l'inversion à proscrire. La doc ne vient pas
  *réparer* un tâtonnement, elle le *prévient*. Pour un bug de version, aucune quantité de
  `console.log` ne révèle le numéro d'issue upstream.
- **Worker sans accès web qui bricole** : un worker cloisonné sans context7/WebSearch/WebFetch
  (ex. `vf-app-fixer`) **ne devine jamais**. Il **remonte `doc-research-required`** à son
  orchestrateur avec la question précise, et s'arrête (miroir de la clause « rien committé,
  explique »). Bricoler à l'aveugle dans un couloir sans web = triche par ignorance.
- **Hack fragile livré sans arbitrage** : un contournement non robuste appliqué en douce sur une
  livraison client. Tout hack se fait **arbitrer** avant application (ADR-031).

## Dépendances
- context7 MCP (`resolve-library-id`, `query-docs`) · outils `WebSearch` / `WebFetch`.
- Sur une brique debug **sans** ces outils : escalade `doc-research-required` (voir Pièges Connus).

## Voir aussi
- `reference/content/methodology/patterns/05-regles.md` (mécanique de rule auto-scopée).
- `dev-orchestrator` → `references/autonomous-guardrails.md` (garde-fou 1 anti-thrash, garde-fou 6
  recherche-doc).
- Skill `vf-debug` · agent `vibeflow-dev` · agent `vf-test-orchestrator` · worker `vf-app-fixer`.
- Template debugger : `reference/content/methodology/templates/skills/debugger/SKILL.md` (Phase 0).
