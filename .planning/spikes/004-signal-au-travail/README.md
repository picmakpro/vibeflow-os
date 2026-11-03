---
spike: 004
idea: cockpit-code-projet
name: signal-au-travail
type: standard
validates: "Given des agents au travail sans DAG dans l'arbre regardé (session, sous-agent en arrière-plan, worktree, manager enregistré), when on croise les signaux disque (transcripts Claude Code, meta des sous-agents, verrous et registre, DAG de tous les emplacements), then le cockpit dit qui travaille, où et sur quoi, sans faux « personne » ni zombie compté comme actif"
verdict: VALIDATED
related: [001-cockpit-live, 003-cockpit-floorplan-live]
tags: [cockpit, presence, transcripts, subagents, driver-lock, registre, worktree]
---

# Spike 004 : qui est au travail ?

## Ce qu'on valide

Le défaut laissé par le spike 001 : le panneau « équipe » de `plugin/vf-cockpit/` ne lit que
`MISSION-*.dag.json` dans le `.planning` regardé. Il affiche donc « Personne au travail » dès
qu'un agent travaille sans DAG dans cet arbre (worktree, sous-agent direct, manager sans plan de
bataille écrit). C'est le cœur de la Phase 36 « signal au-travail fiable ».

Given ces cas, when on croise ce que le disque sait déjà, then on obtient une liste juste
d'actifs, avec les signaux périmés montrés à part, et jamais un « personne » aveugle.

## Recherche : ce que le disque sait déjà

| Source | Où | Ce qu'elle donne | Limite |
|---|---|---|---|
| Transcripts de session | `~/.claude/projects/<slug>/<session>.jsonl` | mtime = pouls ; chaque ligne `user`/`assistant` porte `cwd`, `gitBranch`, `timestamp`, et le dernier appel d'outil (« ce qu'il fait ») | le `cwd` reste celui du lancement ; les sessions lancées dans un worktree sont rangées sous le slug du dépôt |
| **Meta des sous-agents** | `<session>/subagents/agent-<id>.meta.json` | `agentType`, `description`, `spawnDepth`, `requestShape` (`background`), **`finished: true` posé à la fin** (absent tant qu'il tourne), `stoppedByUser` | format interne de Claude Code, sans garantie de stabilité |
| Verrous de driver | `driver-lock.sh status --all` | owner, étape, âge, périmé, `children_running` | seulement si le manager verrouille |
| Registre des agents | `driver-lock.sh orphans [--ws=]` (`DRIVER.lock.children.jsonl`) | agent, rôle, nœud, parent, profondeur, génération, âge | seulement si le manager enregistre ; une entrée survit au `release` |
| DAG de mission | `.planning/*.dag.json` **et** `<git-common-dir>/vf-driver/ws/*/` | nœuds `running` | pas d'horodatage interne ; `save()` non atomique (spike 003) |

Découverte : des DAG vivent aussi dans `<git-common-dir>/vf-driver/ws/fiabilite/`
(`MISSION-EQP.dag.json`), un endroit que le cockpit 001 ne lisait pas.

## Lancer

```bash
node .planning/spikes/004-signal-au-travail/who.mjs <root>            # liste lisible
node .planning/spikes/004-signal-au-travail/who.mjs <root> --json     # pour un client
# dans le cockpit : live.mjs (spike 003) l'importe et pousse l'événement SSE `who` ;
# le badge d'en-tête affiche « N au travail · <verrou> », un clic ouvre le panneau.
```

## Ce qui a été construit

- `who.mjs` : `collect(root)`, lecture seule, sans dépendance, ≈ 0,5 s.
  - Périmètre : le dépôt et ses worktrees, via `git worktree list`.
  - Lit les quatre sources ci-dessus et rend aussi l'état de chacune (lue, absente, erreur).
- Branchement dans `live.mjs` (spike 003) : la liste est recalculée toutes les 5 s et n'est
  poussée que si elle change (signature sans les âges).
- Client `70-vf-live.js` : badge « N au travail » et panneau en deux blocs, « Au travail » puis
  « Signaux périmés ». Quand personne ne travaille, le panneau affiche les sources lues.

## Ce qu'on observe (2026-11-01, dépôt réel + bac à sable)

Témoins positifs établis **avant** de croire un négatif :

| Cas | Attendu | Observé |
|---|---|---|
| Ma propre session | session vivante | ✓ `session`, âge 0 s, dernier outil affiché |
| Sous-agent `general-purpose` en arrière-plan, qui travaille par `cd` dans le worktree | sous-agent vivant, rattaché au worktree | ✓ meta sans `finished` ; d'abord attribué à « arbre principal » (défaut), puis ✓ au worktree après correctif, avec « Attente 1 de 40 secondes dans le worktree » |
| Même sous-agent terminé | disparaît | ✓ `finished: true` posé, il sort de la liste |
| Second témoin terminé, cockpit ouvert | le badge passe de 2 à 1 en direct | ✓ « 1 au travail » par SSE, dans les 5 s du filet, sans rechargement |
| Verrou pris dans le bac à sable | actif | ✓ `lock depot · phase-64-plan · 1 s` |
| 2 agents enregistrés, dont 1 fermé | 1 actif | ✓ le fermé n'apparaît pas |
| `release` avec un enregistré non fermé | orphelin, pas actif | ✓ « ORPHELIN », compté hors des actifs |
| Nœud `running` du DAG de la Phase 18 (abandonné en septembre) | périmé, pas actif | ✓ « PÉRIMÉ » (46 jours) |
| Ce DAG après `touch` (effet d'un checkout) | toujours daté de son commit | ✓ âge pris au dernier commit (le fichier suivi est propre) |
| Ce DAG réellement réécrit | actif | ✓ âge 0 s |

Navigateur (Playwright) : le badge du cockpit affiche « 2 au travail · Driver libre » ; le
panneau liste la session et le sous-agent (worktree, branche `docs/etude-floorplan`), avec le
nœud de la Phase 18 en signal périmé. Le badge se met à jour par SSE, sans rechargement (marqueur
conservé). Capture : `captures/1-qui-au-travail.png`.

## Trace de l'investigation

1. **Premier passage** : plantage sur `realpath`. Un worktree « prunable » (son dossier a
   disparu) figure encore dans `git worktree list`. → On filtre ceux qui n'existent plus.
2. **Zombie compté comme actif** : le nœud `exec-18` est `running` depuis le 16 septembre (mission
   morte sans clôture). → Âge du DAG, puis périmé au-delà du TTL du verrou (1 800 s).
3. **Sous-agent mal rattaché** : il travaille par `cd <worktree> && …`, mais son transcript garde
   le `cwd` du lancement. → Attribution par l'activité : l'arbre le plus profond cité dans le
   dernier appel d'outil l'emporte sur le `cwd`.
4. **Mauvaise branche affichée** : `gitBranch` du transcript = branche de l'arbre de lancement.
   → Branche lue dans `git worktree list` quand l'arbre vient de l'activité.
5. **Orphelin compté comme actif** : `release` conserve les entrées `running` du registre (le
   script le signale). → Une entrée dont le verrou n'est plus tenu est un « orphelin ».
6. **Le checkout rajeunit les zombies** : un `git checkout` remet le mtime à maintenant, et un
   nœud mort repasserait « actif » pendant 30 minutes. → Pour un DAG suivi et propre, on prend
   l'âge de son dernier commit.

## Résultats

**VALIDATED** : on sait dire qui travaille sans dépendre d'un DAG dans l'arbre, en croisant
quatre sources que le disque porte déjà. Ni instrumentation ni hook nouveau.
- La source la plus riche est le `meta.json` des sous-agents : rôle, tâche, profondeur et un
  drapeau `finished` fiable.
- Chaque piège trouvé a son témoin rouge, puis vert : zombie, orphelin, worktree disparu,
  checkout, `cd` dans une commande.

Limites et suites :
- **Format interne de Claude Code** : les transcripts et `meta.json` ne sont pas une API publique.
  Il faut une lecture défensive et un test de forme qui rougit si les champs changent (même risque
  que l'API des mods pour vf-signal).
- **Coût** : ≈ 0,5 s par passage (un `driver-lock.sh status` et un `orphans` par compartiment).
  Toutes les 5 s, ça va ; à mettre en cache si on descend sous la seconde.
- **Session « vivante »** = fichier écrit depuis moins de 180 s. Une session ouverte mais inactive
  (l'humain lit) disparaît : c'est voulu (« au travail »), à nommer comme tel dans l'UI.
- **Pas de corrélation sous-agent ↔ nœud de DAG** : le registre la porte (`--node`), les transcripts
  non. Croiser `description` et `step` serait une heuristique ; l'enregistrement systématique par
  les managers (`register`/`close`) reste la vraie réponse.
- **Panneau** : le contenu personnalisé n'a pas de marge intérieure (à reprendre au design).
- **Confidentialité** : le panneau montre le dernier appel d'outil d'une session. Sur un
  cockpit partagé ou exporté, c'est à filtrer.
- **Reporter dans `plugin/vf-cockpit/`** : remplacer la lecture « DAG seul » de `equipe.js` par
  ce collecteur, quel que soit le support retenu (Mermaid du module ou floorplan).
