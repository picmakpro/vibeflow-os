---
phase: VFDO-33-annexe-notifications-opt-in
verified: 2026-08-17T20:05:00Z
status: gaps_found
score: 5/6 critères D-33-H atteints
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Critère 1 — le gate d'opt-in respecte le contrat fail-open silencieux INCONDITIONNEL de notify.sh"
    status: partial
    reason: >
      La ligne du gate (notify.sh:81) déréférence $HOME sans garde sous `set -u`.
      Si HOME, XDG_CONFIG_HOME et VF_NOTIFY_OPTIN_FILE sont tous absents, le script
      meurt en exit 1 avec fuite sur stderr — falsification directe de la garantie
      capitalisée en tête de fichier (lignes 3-8). Le défaut d'émission OFF, lui,
      n'est PAS falsifié (mort avant toute détection de canal) et reste prouvé.
    artifacts:
      - path: "plugin/conductor/scripts/notify.sh"
        issue: "ligne 81 — ${XDG_CONFIG_HOME:-$HOME/.config} : $HOME non gardé sous set -u"
      - path: "plugin/conductor/scripts/tests/test-notify.sh"
        issue: "aucun cas n'exerce un environnement sans HOME — la classe de défaut est non couverte"
    missing:
      - "Garder $HOME dans l'expression du sentinel (p. ex. ${HOME:-/nonexistent}), aux DEUX emplacements (notify.sh:81 et SKILL.md, l'identité littérale étant assertée par test-vf-notify.sh:37)"
      - "Un cas N19 : env -u HOME -u XDG_CONFIG_HOME -u VF_NOTIFY_OPTIN_FILE → exit 0, stderr vide, zéro invocation"
behavior_unverified_items: []
---

# Phase 33 — Annexe notifications opt-in (D-33-H) : vérification goal-backward

**Objectif vérifié :** décision `D-33-H` de `33-CONTEXT.md` (annexe livrée par 33-06 et 33-07).
**Base de diff :** `07ff554..HEAD` (`60dc763`), branche `feat/phase-33-annexe-notifications-opt-in`.
**Statut :** `gaps_found` — 5/6 critères ATTEINTS, critère 1 PARTIEL.

## Les 6 critères

| # | Critère | Verdict | Preuve |
|---|---------|---------|--------|
| 1 | Défaut OFF (sentinelle d'opt-in) | **PARTIEL** | Gate présent `notify.sh:81-82`, AVANT toute détection de canal. Discriminance mesurée (cf. §Preuve centrale). MAIS `$HOME` non gardé sous `set -u` → exit 1 + fuite stderr quand HOME/XDG/VF_NOTIFY_OPTIN_FILE sont tous absents |
| 2 | Toggle `/vf-notify` (on/off/status/test) | **ATTEINT** | `plugin/conductor/skills/vf-notify/SKILL.md` (4 verbes), `plugin/commands/vf-notify.md`, suite `test-vf-notify.sh` (17 asserts, verte). Zéro settings JSON, zéro entrée `hooks.json` neuve |
| 3 | Pattern H — les DEUX jalons vers l'app Claude | **ATTEINT** | `mission-flow.md:453-500` ; renvoi câblé dans `vf-dev-manager.md:181` ; fin de phase ET fin de milestone nommées ; `PushNotification` jamais appelé par le manager |
| 4 | Signal de stall jamais gaté | **ATTEINT** | Aucune occurrence de `notify-optin`/`VF_NOTIFY_OPTIN_FILE` hors `notify.sh`, skill, tests, CHANGELOG. `dag.sh:check_stall_signal()` inchangé, disjoint de `record_milestone()` |
| 5 | Distribution effective (2 modules bumpés) | **ATTEINT** | conductor v1.28.0 et dev-orchestrator v2.18.0 : `VERSION` + `module.json` + `CHANGELOG.md` + en-tête README cohérents ; `check-version-sync.sh` exit 0 |
| 6 | Traçabilité WTCH-03 + ROADMAP | **ATTEINT** | `REQUIREMENTS.md` amendé aux deux emplacements (tableau ligne WTCH-03 + checklist) ; `ROADMAP.md` porte la ligne ANNEXE |

## Preuve centrale — « aucun canal n'émet sans opt-in » : PROUVÉE

Mutation rouge rejouée en bac à sable (copie hors dépôt, dépôt jamais modifié), 30 itérations
chacune, patron N17 exact :

| Configuration | Invocation détectée | Verdict |
|---|---|---|
| `notify.sh` réel (gate présent) | **0 / 30** | aucun faux positif |
| Mutant (gate supprimé) + assertion N17 actuelle (`wait_for_file … 2`) | **30 / 30**, latence max 610 ms | discriminant |
| Mutant + ancienne assertion (`sleep 0.3`) | 25 / 30 (**5 ratés**) | l'assertion pré-correctif était aveugle ~17 % du temps |
| Mutant + assertion sans aucune attente | **0 / 30** | totalement aveugle |

Le correctif `60dc763` est donc **réel et mesuré**, pas cosmétique : budget 2 s ≈ 3,3× la latence
max observée du fork détaché.

**La classe de défaut n'est PAS fermée ailleurs dans le même fichier** — deux sites survivent :

- `test-notify.sh:262` et `:269` (N9) — assertion « zéro invocation » **sans aucune attente**
  (mesure ci-dessus : 0/30 de détection, aveugle à 100 %).
- `test-notify.sh:298` (N12) — `sleep 0.3` fixe avant l'assertion de compteur à zéro (mesure :
  5/30 de ratés).

Ces deux cas couvrent la validation d'arguments et le shim non exécutable, pas la garantie D-33-H —
ce sont des WARNINGs, pas des bloquants de l'objectif.

## Défaut bloquant confirmé par mesure indépendante (critère 1)

```
$ env -u HOME -u XDG_CONFIG_HOME -u VF_NOTIFY_OPTIN_FILE bash plugin/conductor/scripts/notify.sh "T" "B"
plugin/conductor/scripts/notify.sh: line 81: HOME: unbound variable
exit=1
$ env -u HOME -u VF_NOTIFY_OPTIN_FILE XDG_CONFIG_HOME=/tmp/xdgx bash …/notify.sh "T" "B"   # exit=0
$ env -u HOME -u XDG_CONFIG_HOME -u VF_NOTIFY_OPTIN_FILE bash …/notify.sh                   # exit=0 (gate d'args en amont)
```

Caractérisation : déclenché **uniquement** si les trois variables sont absentes simultanément.
Introduit par cette annexe (avant D-33-H, `notify.sh` ne référençait jamais `$HOME`).

- Ce que le défaut **ne** falsifie **pas** : le défaut OFF. Le script meurt à la ligne 81, donc
  avant tout `command -v` — aucune émission ne peut survenir.
- Ce qu'il falsifie : la garantie capitalisée « FAIL-OPEN SILENCIEUX INCONDITIONNEL » (`notify.sh:3-8`).
- Portée pratique : `dag.sh:265` appelle avec `stderr=DEVNULL, check=False` → invisible. Le verbe
  `/vf-notify test` appelle depuis un shell → la fuite y serait visible.

## Gates re-dérivés (aucune valeur crue sur parole)

| Gate | Commande | Résultat |
|---|---|---|
| Découverte des suites | `find plugin scripts -type f -path '*/tests/test-*.sh'` | **66** |
| Exécution intégrale | boucle sur les 66, rc collecté | **66 rc=0 / 0 KO** |
| Sync de version | `bash scripts/check-version-sync.sh` | exit 0 (v2.55.1, 17 modules, 66 suites) |
| Densité manager | `awk END{print NR} vf-dev-manager.md` | **250** lignes (= plafond ADR-029, non dépassé) |
| Conformité agents | `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents` | exit 0, 7 warnings préexistants |

**Correction de mesure :** `bash plugin/conductor/scripts/check-agents.sh` **nu** rend
« aucun agent dans .claude/agents — rien a verifier » — c'est un vert à vide, il ne prouve rien sur
`plugin/dev-orchestrator/agents/`. Seule la forme `--agents-dir=…` constitue une preuve.

## Limites assumées (jamais comptées comme manques)

- La chaîne `SendMessage(main)` → `PushNotification` n'est **pas** vérifiable de bout en bout depuis
  un sous-agent : l'outil n'y existe pas (fait mesuré qui a dicté l'architecture). Pattern H décrit
  ce comportement **exactement** — il documente `disabledReason` ∈ {`config_off`, `user_present`,
  `no_transport`}, écrit noir sur blanc qu'« aucun accusé de réception n'existe », et interdit
  d'attendre une confirmation. **Aucune promesse de délivrance n'est faite.**
- Windows réel : hors périmètre de cette annexe (limite héritée de WTCH-03).

---

_Vérifié : 2026-08-17 · Verifier : Claude (gsd-verifier), lecture seule, aucun commit_
