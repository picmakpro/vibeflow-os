---
name: relais-main-attente-non-bornee
description: Un SendMessage(main) est « queued for the main conversation's next turn » — si l'humain est absent, l'attente du manager n'a pas de borne ; persister les questions sur disque puis rendre human_needed
metadata:
  type: project
---

Mission 46.1 (2026-10-07) : cinq questions de cadrage relayées par `SendMessage(main)`, réponse
« Message queued for the main conversation's next turn ». Environ cinq heures d'attente au premier
plan (boucle `idle.py` du scratchpad, heartbeat à chaque tour) sans aucun retour : la session
principale ne relaie qu'à son prochain tour, donc pas tant que l'humain n'a pas repris la main.

**Why:** l'attente coûte peu en jetons mais garde le verrou et le manager vivants sans borne ; une
coupure pendant ce temps aurait perdu les questions si elles n'étaient que dans le message.

**How to apply:** dès l'envoi, écrire les questions, options et recommandations dans le
`*-DISCUSSION-LOG.md` de la phase (statut « réponses en attente ») et le commiter. Attendre au
premier plan une durée bornée (quelques heures), puis rendre `human_needed` avec le rapport sur
disque, la branche poussée et le verrou relâché : la relance reprend depuis le disque. Ne jamais
traiter le silence comme un accord. Voir [[escalade-sendmessage-attendre-la-vraie-reponse]] et
[[attente-au-premier-plan]].
