---
paths:
  - "app/**/*.tsx"
  - "app/**/*.ts"
  - "src/screens/**"
  - "src/features/**"
  - "src/components/**/*.tsx"
  - ".maestro/**"
---

# Règle — Gate de vérification réelle (mobile)

> Rule **path-scopée** : se charge automatiquement dès qu'on touche du code d'écran mobile
> (Expo / React Native) ou un flow de test. Sur un projet non-mobile, elle reste dormante.
> Elle rend **active** — au moment du dev, sans invocation manuelle — la doctrine de vérification
> réelle et de boucle autonome. Principe VibeFlow : *enforcement > prose*.
>
> S'applique aux projets **mobile (Expo/React Native)**. Si le dossier courant n'est pas une app
> mobile, ignore cette règle.

## Gate — Vérification réelle (extension mobile du Gate Nyquist, ADR-037)

**Un critère d'acceptation de comportement ou d'UI mobile n'est pas « fait » tant qu'il n'a pas
été vérifié sur une cible réelle (simulateur/émulateur), pas seulement par un test unitaire.**

- Un test Jest qui passe **ne prouve pas** que l'écran s'affiche, que la navigation marche, ou
  que le flux ne crashe pas au runtime. Un composant peut compiler, passer ses tests unitaires,
  **et crasher à l'écran**.
- Pour tout critère observable à l'écran, la preuve attendue est un **flow Maestro** exécuté par
  le pipeline mobile (`node .claude/scripts/mobile-test-run.mjs run --platform <ios|android>`).
- Si le critère qu'on s'apprête à coder n'a pas de flow → **le définir d'abord** (un flow qui
  échoue), puis coder pour le faire passer. Voir le skill `vf-mobile-test`.

## Boucle test+fix autonome

Quand on demande de faire passer une phase/feature « jusqu'au bout » en autonomie sur du mobile,
la vérification réelle et la correction se pilotent via l'**équipe de test** (agents dédiés) :

- `vf-test-orchestrator` tient la boucle (baseline verte, anti-régression, anti-thrash, arrêt
  vert/plafond) et dispatche deux workers cloisonnés :
  - `vf-test-runner` — possède les tests (écrit la couverture manquante, **n'affaiblit jamais un
    assert**), joue le pipeline.
  - `vf-app-fixer` — corrige **uniquement** le code applicatif, un fix = un commit atomique.

## Cloisonnement anti-triche (Pattern 12 — non négociable)

Celui qui corrige le code **n'est pas** celui qui écrit les tests. **On n'affaiblit, n'assouplit
ni ne supprime jamais un assert** pour « faire passer ». Un test qui échoue signale un vrai
problème : on corrige le code, ou on consigne l'échec — jamais on ne mutile la preuve.
Détail : `agents/<...>-references/test-loop-protocol.md` et la doctrine
`autonomous-guardrails.md`.

## Recherche documentaire avant fix intensif (ADR-045)

Sur un échec lié à une **lib/framework/natif/version d'OS-SDK**, ou après un correctif déjà
infructueux, la **recherche documentaire précède** le fix empirique (voir la règle
`doc-research-before-debug`). Le worker `vf-app-fixer` est cloisonné sans web : il remonte
`doc-research-required` plutôt que de bricoler ; l'orchestrateur fait porter la recherche.
