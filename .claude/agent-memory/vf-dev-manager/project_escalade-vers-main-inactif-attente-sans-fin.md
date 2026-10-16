---
name: escalade-vers-main-inactif-attente-sans-fin
description: SendMessage(main) n'est lu qu'au prochain tour de la session principale ; si elle attend mon rapport, l'escalade attend sans fin — borner l'attente puis rendre human_needed
metadata:
  type: project
---

Une escalade `SendMessage(to: "main")` n'atteint la session principale qu'à son prochain tour. Si elle est inactive (elle attend la fin de ma mission, ou Samuel dort), rien ne la réveille : seule la notification de fin d'un sous-agent le fait. Phase 57 (2026-10-11) : la première escalade (worker figé) a eu sa réponse en 4 min parce que la session était active. La seconde (deux arbitrages F-1/F-2) est restée 5 h sans réponse, pendant que je sondais toutes les 10 min.

**Why:** attendre reste la bonne conduite (jamais d'arbitrage inféré), mais une attente sans borne immobilise la mission sans que l'humain le sache. Rendre `human_needed` produit la notification qui réveille la session principale. Elle peut ensuite me relancer par SendMessage avec la réponse.

**How to apply:** pendant l'attente, faire tout ce qui ne dépend pas de l'arbitrage (revue, audit, docs, rejeu CI). Au-delà d'environ 1 h sans réponse, rendre le rapport typé `human_needed`, avec les options, la recommandation et l'état exact (HEAD, nœuds faits et gelés). Relâcher le verrou et arrêter la boucle de heartbeat avant de rendre. Autre piège vu le même jour : la mise en veille du portable gèle `python3 time.sleep` (horloge monotone), donc une boucle de heartbeat détachée cale et le verrou périme. Vérifier `hb.log` à chaque réveil (voir [[attendre-un-worker-sleep-bloque]]).
