---
name: commiter-avant-de-rendre
description: deux vf-coder figés APRÈS avoir rédigé mais AVANT de commiter (Phase 41.2) ; exiger « commite tout avant ton rapport » dans chaque mandat
metadata:
  type: feedback
---

Chaque mandat vf-coder porte la consigne explicite « commite TOUT avant de rendre ton rapport (un fichier non commité = travail non livré) », et aucun rejeu long (job complet, lab-frais) en fin de mandat : la CI GitHub arbitre, le manager la lit.

**Why:** Phase 41.2 (2026-10-02) — deux workers ont été coupés par le chien de garde (600 s sans progrès) alors que leurs fichiers étaient rédigés sur disque mais non commités : l'un pendant un rejeu `rejouer-ci.sh --job tests` + lab-frais (réseau), l'autre sans processus visible. Le premier a fini après réveil ; pour le second, le manager a dû commiter lui-même les docs déjà écrites (commit qui le dit). Le mandat suivant, avec la consigne, a rendu proprement.

**How to apply:** dans tout mandat d'exécution ou de correction, interdire les rejeux > 5 min et exiger le commit avant le rapport. Si un worker est figé avec un travail fini sur disque : relire le disque, réveiller une fois, puis commiter soi-même le contenu inchangé en le disant dans le message, jamais redispatcher. Lié : [[transcript-fige-ne-prouve-pas-worker-mort]], [[relire-le-disque-avant-tout-rapport]].
