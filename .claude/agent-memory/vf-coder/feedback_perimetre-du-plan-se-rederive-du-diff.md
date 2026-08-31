---
name: perimetre-du-plan-se-rederive-du-diff
description: L'énumération de fichiers/modules d'un PLAN est une hypothèse datée du moment de la planification — la re-dériver du diff réel avant d'agir, et vérifier ses prémisses sur disque
metadata:
  type: feedback
---

Un `PLAN.md` qui **énumère** un périmètre (« les 8 modules touchés », `files_modified:`) énonce
une hypothèse **datée du moment de la planification**, pas un fait. La re-dériver du diff réel —
`rtk proxy git diff --name-only <base>..HEAD`, groupé par module en `awk -F/` — **avant** d'agir,
et la faire primer sur l'énumération.

**Why:** mesuré le 2026-08-04 (plan 24-12, clôture de la Phase 24). Le plan nommait 8 modules à
bumper ; le diff réel en portait **10** — `kpi-analyst` et `validator` avaient reçu `effort:` sur
leur `AGENT.md` de racine, exactement comme les cinq autres, et n'étaient nommés nulle part. Les
bumper n'était pas un zèle : la même phase avait déjà payé le piège « 25 agents annoncés / 31
réels », et ces deux modules sont précisément les mono-agents que le balayage par
`plugin/*/agents/` ne voit pas. Un plan écrit en vague 1 ne peut pas connaître ce que les vagues
2-3 ont touché.

**Le corollaire, plus vicieux : les PRÉMISSES du plan périment aussi.** Le même plan affirmait,
dans un `read_first`, que « les bundles ne déclarent pas de ligne `**Version**` » et qu'il ne
fallait donc pas toucher leur README. Faux : les 17 modules en déclarent une, et le gate le disait
lui-même (`en-tête Version des README de modules : 17 déclarés`). Suivre la prémisse aurait fait
tomber le contrôle n°8 juste après le bump — un rouge causé par la consigne censée l'éviter.

**How to apply:**

- Avant d'exécuter un plan à périmètre énuméré : re-dériver la liste du diff, la comparer à celle
  du plan, et **signaler l'écart au manager** en disant laquelle fait foi.
- Toute prémisse d'un `read_first` formulée comme un fait sur le disque (« X n'a pas de champ Y »,
  « seuls N fichiers portent Z ») se **vérifie en une commande** avant d'être suivie. Le gate
  concerné est souvent la source la moins chère et la plus fiable : le faire tourner d'abord donne
  la baseline ET dément les prémisses fausses.
- Corollaire de baseline : lancer le gate **avant** toute édition. Ici il n'était rouge que sur
  **un** contrôle (le compteur de suites) — savoir cela d'avance a permis d'attribuer chaque vert
  ultérieur à sa cause. Voir [[baseline-avant-le-premier-artefact]].

Voir [[roadmap-faits-perissables]] (même classe : un fait écrit dans un document de pilotage se
re-mesure, jamais ne se recopie) et [[ok-statiques-vs-executes]] (nommer l'objet avant de citer un
nombre).
