# Mission — Annexe Phase 33 : notifications opt-in + jalons via l'app Claude (D-33-H)

**Date :** 2026-08-17 · **Manager :** `vf-dev-manager` · **Statut :** LIVRÉE, non poussée
**Branche :** `feat/phase-33-annexe-notifications-opt-in` (17 commits, base `07ff554`)
**DAG :** `.planning/MISSION-NOTIF.dag.json` — **11/11 nœuds `done`** · **lock relâché**
**Journal de la pause initiale :** `2026-08-17-notifications-opt-in-PAUSE.md`

---

## 1. Le fait qui a décidé de l'architecture

**`PushNotification` n'est pas fourni aux sous-agents.** Mesuré par appel réel, pas lu :

> `No such tool available: PushNotification. PushNotification is disabled for this session, in
> subagents as well as here.`

Ce n'est pas un réglage (toute la config de Samuel était déjà ON). Or `vf-dev-manager`, `vf-coder`
et `dag.sh` sont **tous** des sous-agents : le brief supposait que les managers pousseraient
eux-mêmes. **La prémisse était fausse.** D'où le relais (Q1 = 1a) : le manager émet
`SendMessage(main)`, la **session principale** pousse. Décalque exact du précédent
`AskUserQuestion`.

## 2. Quatre autres prémisses du brief, fausses (mesurées)

1. **`VF_NOTIFY_FORCE_CHANNEL=none` n'est pas un kill-switch** — aucune valeur `none` dans le code ;
   le `case` ne connaît que `windows|darwin|linux`, tout le reste tombe sur `*) : ;;`. `none`, `off`
   et `xyzzy` silencient **par accident**, sans aucun test. Le nouveau gate est donc le **premier**
   mécanisme d'extinction délibéré — il n'avait rien avec quoi « composer ».
2. **`record_milestone()` est dans `dag.sh`** (Python), pas dans `notify.sh`.
3. **`test-notify.sh` = 16 blocs / 50 assertions**, pas « 48 cas ».
4. **Le brief conflatait nœud de DAG et phase GSD** — aucun code ne relie les deux.

## 3. Ce qui est livré

| Volet | Contenu |
|---|---|
| **Défaut OFF** | Gate d'opt-in dans `notify.sh` (entre `:67` et `:69`), fichier-sentinelle `${XDG_CONFIG_HOME:-${HOME:-}/.config}/vibeflow/notify-optin` |
| **Toggle** | Skill `/vf-notify` (`on`/`off`/`status`/`test`) + commande, suite `test-vf-notify.sh` (18 assertions) |
| **Jalons** | `Pattern H` dans `mission-flow.md` — les **deux** jalons (fin de phase ET fin de milestone), relais `SendMessage(main)`, contrat `message` < 200 car. sans `title`, aucun accusé de réception |
| **Distribution** | `conductor` v1.28.0 · `dev-orchestrator` v2.18.0 (quadruplet `VERSION`/`module.json`/`CHANGELOG`/`README` pour chacun) |
| **Traçabilité** | D-33-H dans `33-CONTEXT.md` · WTCH-03 amendé aux 2 emplacements de `REQUIREMENTS.md` · ROADMAP · STATE · BACKLOG clos · `33-VERIFICATION-ANNEXE.md` |

**Ligne rouge tenue** : le signal de stall **D-33-F n'est jamais gaté** — prouvé par le code
(`dag.sh:223-246` disjoint de `record_milestone()`) et par essai réel (T41).

## 4. Attestation finale (mesurée par le manager, post-commit)

- **66 suites découvertes / 66 OK / 0 KO** (motif CI `find plugin scripts -type f -path '*/tests/test-*.sh'`)
- `check-version-sync.sh` **exit 0** · `check-agents.sh --agents-dir=…` **exit 0**
- Fail-open sans `HOME` : **exit 0, stderr vide**
- **Arbre de travail propre**, rien de poussé

## 5. Ce que les gates ont réellement attrapé

La valeur de cette mission est là — **aucun de ces défauts n'aurait été vu sans les juges** :

| Étage | Trouvaille |
|---|---|
| Plancheck externe #1 | 3 bloquants, dont **`dev-orchestrator` jamais bumpé** → la doctrine n'aurait **jamais** été distribuée (l'engine ne re-copie un module que si sa `VERSION` change) |
| Plancheck externe #2 | **2 bloquants introduits par les corrections elles-mêmes**, dont un rendant la CI rouge de façon déterministe (`module.json` + `README` hors du bump) |
| Manager | **Propagation incomplète de mon propre arbitrage** : le sentinelle migrait vers `XDG_CONFIG_HOME` mais l'isolation des tests sandboxait encore `XDG_CACHE_HOME` — les tests auraient écrit dans le vrai `$HOME` de l'utilisateur |
| Revue de code | **BLOQUANT** : `$HOME` non gardé sous `set -u` → `exit 1` + fuite stderr, **falsifiant la garantie de fail-open inconditionnel** que l'annexe venait elle-même d'introduire |
| Vérification | **N17, le cas qui prouve le défaut OFF, était aveugle 17 % du temps** (`sleep 0.3` plus court que le délai réel du fork, 0,32-0,42 s). Mesuré sur 30 itérations : 0/30 sans attente, 25/30 avec l'ancien sleep, **30/30 après durcissement** |
| Vérification | **Ma propre mesure `check-agents.sh` était un vert à vide** (forme nue → « aucun agent dans `.claude/agents` ») |

## 6. Décisions du manager (motivées)

- **Budget `wait_for_file` maintenu à 2 s** malgré le coût mesuré (9,9 s → 18,6 s). Motif : latence
  max observée **610 ms**, marge 3,3× ; la ramener à 1 s donnerait ~1,6×. Cette mission s'est **déjà
  fait mordre exactement comme ça**. 9 secondes de suite valent moins qu'un test instable en CI.
  **Révisable par Samuel** — la revue proposait 0,5-1 s.
- **Sentinelle sous `XDG_CONFIG_HOME`**, pas `XDG_CACHE_HOME` : un cache est purgeable, la
  préférence retomberait à OFF silencieusement.
- **`user_present` scopé au push relayé**, pas au toast OS (`notify.sh` n'a aucune détection de
  présence — l'affirmer contredisait `Pattern H`).
- **Bump `dev-orchestrator` complet** (4 fichiers) contre la prohibition écrite dans le plan, parce
  qu'un gate machine du dépôt l'exige.

## 7. Erreur du manager, assumée

**J'ai dispatché un worker de complétion sur un worker qui n'était pas mort.** Trace figée +
SUMMARY manquant m'ont fait conclure « tué par la veille » ; il a fini 20 minutes plus tard. Les
deux ont muté `notify.sh` en parallèle pour leurs preuves, et **chacun a rapporté le travail de
l'autre comme une anomalie inexplicable** (« gate inversé sans hook », « commit que je n'ai pas
produit »). Deux rapports `ask-user` brûlés à enquêter sur un fantôme qui était mon propre dispatch.
Issue bénigne, mais c'était de la chance. Leçon consignée en mémoire d'agent :
*une trace figée ne prouve pas une mort — réveiller, jamais remplacer.*

## 8. Limites assumées (déclarées, pas comblées)

- **La chaîne de push n'est pas vérifiable de bout en bout** depuis un sous-agent — c'est le fait
  mesuré qui a dicté l'architecture. `Pattern H` le documente sans promettre de délivrance.
- **`user_present`** : le harness n'émet rien quand Samuel est au terminal. Toute recette manuelle
  est trompeuse tant qu'il regarde l'écran.
- **Preuve Windows réelle de WTCH-03** toujours non exécutée (limite héritée de la Phase 33).
- **N12** : son assertion zéro-invocation est tautologique par garantie OS (le kernel refuse
  l'`exec()` d'un fichier non exécutable) — tranché par mesure entre trois agents en désaccord.
  Son volet stderr reste discriminant.

## 9. Écarts documentaires repérés, non corrigés (hors périmètre)

- `STATE.md` §Decisions : entrées Phases 29 et 31 disent « reste : push, PR, release » — **périmé**,
  branches mergées et releases posées.
- `STATE.md` : frontmatter non parsable en YAML strict (défaut préexistant) ; tableaux
  §Performance Metrics corrompus de longue date.
- `33-VERIFICATION-ANNEXE.md` : horodatage du frontmatter postérieur à la réalité.

## 10. Gates humains — rien n'a été franchi

**Aucun push, aucune PR, aucun merge, aucun tag, aucune release.** La branche est locale.
Prochain geste humain : `git push -u origin feat/phase-33-annexe-notifications-opt-in` pour la
preuve CI, puis PR sur demande explicite.
