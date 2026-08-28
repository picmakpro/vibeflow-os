---
name: joignabilite-asymetrique-manager-worker
description: Le manager PEUT réveiller ses workers par SendMessage, mais un worker NE PEUT PAS le joindre en retour — son rapport part vers main et arrive en relais différé
metadata:
  type: project
---

La joignabilité manager↔worker est **asymétrique**, et il faut le porter dans chaque mandat.

**Sens qui MARCHE** — manager → worker : `SendMessage(to: "<agentId>")` sur un agent déjà rendu le
**reprend avec son contexte intact** (réponse `Resuming agent <id>`). Mesuré Phase 38 : deux workers
réveillés avec succès, dont un pour une sonde de suivi qui a réutilisé son banc de mesure.
C'est **le bon geste** — bien meilleur qu'un redispatch, qui repart de zéro et refait le banc.

**Sens qui NE MARCHE PAS** — worker → manager : le worker **ne résout pas le nom du manager depuis
son étage**. Mesuré Phase 38 : un worker a tenté de rendre son rapport par `SendMessage`, l'a vu
échouer, et l'a envoyé à `main` — qui me l'a relayé **en différé**, hors du canal de retour normal.
Le rapport n'a pas été perdu, mais il est arrivé par un chemin que rien ne garantit.

**How to apply:** dans **tout** mandat de worker, une ligne explicite :
> Rends ton rapport comme **message final d'agent** (le retour normal de ta tâche).
> N'utilise **jamais** `SendMessage` — tu ne résous pas mon nom depuis ton étage.

Corollaire de pilotage : ne jamais concevoir un protocole où le worker doit **initier** un échange
(demander un arbitrage en cours de route, signaler un blocage à mi-parcours). Un worker qui doit
poser une question **termine** et la rend dans son bloc typé (`action: ask-user`) ; c'est le manager
qui relance ensuite par `SendMessage`. Le tour de boucle est le canal, pas le message spontané.

Voir [[transcript-fige-ne-prouve-pas-worker-mort]] (réveiller plutôt que redispatcher) et
[[escalade-humaine-trou-headless]] (même famille : le canal d'escalade ne se devine pas).
