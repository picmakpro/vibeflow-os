# Phase 32: Durcissement du driver-lock - Context

**Gathered:** 2026-08-16
**Status:** Ready for planning, sauf une decision ouverte (D-32-QUAL, ne bloque qu'un sous-detail
du Lot 2) et un reliquat de mesure non leve (F2, a lever avant de finaliser la comparaison de
session dans le guard).

<domain>
## Phase Boundary

Fermer, sans rouvrir le protocole d'acquisition symlink-generation (mesure, stable), les deux ecarts
identifies dans `plugin/conductor/scripts/driver-lock.sh` (286 lignes) :

- **LOCK-01** : separer le battement (signal de vie) de la lease. Aujourd'hui `lock_age()`
  (L80-88) se calcule uniquement sur `heartbeat_epoch` — c'est correct et **ne change pas** (c'est
  ce qui rend vrai « lock perime != mission morte », constat 2026-08-02) — mais `acquired_epoch`
  (L120/L138) n'est **lu par aucun calcul**, seulement preserve (L131). Rien ne separe
  aujourd'hui « depuis quand la lease existe » de « depuis quand elle bat ».
- **LOCK-04** : l'auto-steal existe, implicite, non trace. Un `acquire` **ordinaire** d'un autre
  owner sur un lock perime (`age > TTL`) le vole silencieusement (L196-229), et `recover` (L262-280)
  fonctionne **sans `--owner`**. La seule trace est un JSON stdout ephemere (L224).

Et deux ecarts d'enforcement, mesures par le rejeu des incidents reels
(`32-REJEU-contournements.md`) :

- **LOCK-02** : un commit sous le lock d'autrui n'est bloque par **rien** — `driver-lock.sh` n'est
  consulte que par les managers (SUMMARY du quick `260801-17w`, cite au §1 du rejeu). Deux
  incidents distincts derriere ce seul numero : I1 (2026-07-27, lock **perime**, domaine
  LOCK-01/04) et I4 (2026-08-16, lock **vivant et tenu**, 8 commits — seul un enforcement a la
  source l'aurait arrete) ; et I2 (2026-07-31, **`Write`/`Edit`** dans `.planning/`, pas `Bash` —
  angle mort du critere ecrit initial, ferme par l'arbitrage 2B, voir D-32-B).
- **LOCK-03** : un checkout de branche sous le lock d'autrui n'est ni detecte ni signale (I3,
  2026-08-01, arbre partage). Le mecanisme initialement envisage (`reference-transaction`) est
  **mesure et ecarte** — voir `32-SPIKE-reference-transaction.md`.

Plus **LOCK-05** : un jeton de fence en trailer de commit, pour audit « quel commit sous quel
mandat ». **Aucun outillage de trailer n'existe** dans ce depot (verifie, `32-TERRAIN.md` §6) —
les deux trailers en usage (`Co-Authored-By:`, `Claude-Session:`) sont poses **par convention
d'agent uniquement**, jamais verifies ni poses par une machine.

**Transverse QUAL-01** : tout gate ne de cette phase nait avec ses **quatre** issues (pas trois —
voir §11 du terrain) — PASS / DENY / imparsable-fail-open-silencieux / indisponible-fail-open-
bruyant — et sa mutation rouge prouvee par sa trace.

**Hors scope, explicitement** :
- Rouvrir le protocole d'acquisition symlink-generation (mesure, cf. `driver-lock.sh` L8-20).
- `reference-transaction` comme mecanisme de blocage (ecarte par le spike, §9 du spike : « le
  vecteur `PreToolUse` offre la meme discrimination sans la contrainte de distribution »).
- Auto-steal sur TTL sous quelque forme que ce soit (`REQUIREMENTS.md` §Out of Scope : « lock
  perime != mission morte » — **reevaluable post-LOCK-01 sur battement MORT, jamais sur TTL**).
- Toute forme d'armement via settings local pour l'**entree** du guard (regression #38 — seule la
  **commande** peut etre locale, voir D-32-C).
- Construire un mecanisme de verification machine du trailer LOCK-05 (voir §Decisions,
  arbitrage LOCK-05) — deferee en §Remontees.

**Depends on** : Phase 30 (l'entree de hook nait en forme exec sur le moteur final — precedent
direct : `guard-file-size.sh`, seule autre entree exec bloquante du parc a ce jour). Ordonnee
apres la Phase 31 (moteur d'install stable). Branche de phase deja active :
`feat/phase-32-durcissement-driver-lock` — pas de nouvelle branche, pas de bascule, pas de merge
dans ce mandat.

</domain>

<decisions>
## Implementation Decisions

### Decisions actives — deja tranchees par Samuel, non rouvertes ici

- **D-32-A** (2026-08-16) — LOCK-03 : blocage du **seul** `git checkout|switch` de branche porte
  par le guard `PreToolUse(Bash)`, **pas** par `reference-transaction` (juge non sur par le spike
  — trois raisons independantes : wedge de `rebase --abort`, contournement trivial deja pratique
  par le conductor lui-meme via `-c core.hooksPath=/dev/null`, degats collateraux sur
  `worktree add`). Echappatoire nommee : le worktree reste possible, le **detenteur** du lock
  passe toujours. **Amendement du critere de succes n°3** (qui conditionnait le blocage a la
  surete de `reference-transaction`) : la condition est tombee cote « non sur », le mecanisme de
  repli la satisfait par une voie differente — consigne, pas rouvert.
- **D-32-B** (2026-08-16) — LOCK-02 : le guard couvre `Bash` **plus** `Write|Edit` restreint aux
  chemins `.planning/`. Motif : I2 (2026-07-31) est passe par `Write`/`Edit`, angle mort du
  critere ecrit initial (« `PreToolUse(Bash)` » seulement). **Amendement du critere de succes
  n°2**, consigne.
- **D-32-C** (2026-08-15) — l'**ENTREE** du guard nait toujours de `merge-hooks` (jamais posee a
  la main, jamais un hook git hors du mecanisme distribue) ; sa **COMMANDE** peut pointer un
  chemin absolu machine-specifique range en cible `--settings-local`. Un chemin machine ne voyage
  jamais dans un fichier commite.

### D-32-01 — LOCK-01 : deux champs distincts, un seul continue a piloter la peremption

**Decision (Claude's Discretion, argumentee)** : `lock_age()`/le seuil `TTL` **restent bases sur
`heartbeat_epoch`, sans changement** — c'est deja le mecanisme qui rend vrai « lock perime !=
mission morte » (un manager qui bat regulierement ne perime jamais), et le toucher romprait cette
garantie. Ce que la phase **ajoute** : `status`/`acquire`/`recover` exposent un second champ
d'observabilite, calcule depuis `acquired_epoch` (deja preserve, jamais lu) — l'**age de la
lease** (depuis combien de temps cette mission tient le lock, independamment de son dernier
battement). Ce champ est **informationnel**, n'entre dans **aucun** calcul de peremption ni de
refus. C'est la lecture litterale de « heartbeat separe de la lease » qui satisfait a la fois le
critere n°1 (« le TTL par defaut ne monte pas ») et la contrainte dure (aucune borne de duree
totale n'est introduite, donc aucun risque de tuer une mission longue).

**Motif du choix** (vs. une borne de duree totale sur `acquired_epoch`) : une borne dure sur la
lease contredirait frontalement la contrainte « un lock perime n'est pas une mission morte » —
c'est exactement le mode de defaillance que la phase existe pour fermer, pas pour en ouvrir un
symetrique. Aucune des deux sources de recherche ne demande une telle borne ; le critere de succes
n°1 ne parle que de battement et de TTL par defaut.

**A verifier au plan** : ce champ sert-il directement Phase 33 (WTCH-01, « meme battement, deux
consommateurs ») ? Probable mais non tranche ici — la Phase 33 dependra de LOCK-01, pas
l'inverse.

### D-32-02 — LOCK-04 : `takeover` explicite remplace l'auto-steal implicite dans `acquire`

**Decision** : le bloc « 3. PERIME » d'`acquire` (L196-229) **ne recupere plus** un lock perime
au profit d'un autre owner — il **refuse** (`{"acquired": false, "reason": "stale-requires-
takeover", ...}`), en pointant la marche a suivre. Un **nouveau verbe** `takeover` (exige
`--owner`, `--step` optionnel) reprend exactement la danse mesuree comme correcte (mutex nomme
d'apres la generation observee, double revalidation apres mutex sur generation **et** age — la
protection contre les 2-gagnants documentee en L205-209 **survit telle quelle**, deplacee sous ce
nouveau verbe). `recover` reste inchange dans son role (elagage anonyme, ne revendique pas de
nouvel owner) — mais **gagne la meme tracabilite** (ci-dessous), parce qu'il modifie l'etat du
lock au meme titre qu'un takeover, meme sans identite declaree.

**Tracabilite persistante** : un fichier journal append-only,
`$LOCK_PARENT/${LOCK_BASE}.takeovers.log` (une ligne JSON par evenement, `takeover` ou
`recover`, horodatee, portant `previous_owner`, `new_owner` le cas echeant, `age_seconds`). Motif :
la seule trace actuelle (`32-TERRAIN.md` §1 L60) est le stdout ephemere du process qui vole,
**jamais persistee** — le "trace avec l'ID du repreneur" du critere n°4 exige un support qui
survive au `rm -rf` de l'ancienne generation (L223).

**Retrocompatibilite** : purement additif — un lock pose par l'ancien script (sans ce journal)
reste lisible ; le journal se cree a la premiere ecriture (`mkdir -p` du parent deja present en
L113).

**A prouver par mutation** (rejeu) : un `acquire` ordinaire d'un autre owner sur un lock perime
doit **rougir** desormais (aujourd'hui il reussit — c'est le comportement expres a inverser) ;
seul `takeover` doit reussir dans ce cas.

### D-32-03 — Champ additif `session_id`, + `generation` expose en JSON : prealables partages de LOCK-02/03/05

**Decision** : reprend integralement le mecanisme recommande et mesure par `32-TERRAIN.md` §9 —
`new_generation()`/`rewrite_meta()` ecrivent/preservent un champ **additif**
`session_id=<$CLAUDE_CODE_SESSION_ID a l'acquire, vide si absent>`, meme patron que
`branch`/`worktree` (ADR-064, L98-104, L118-119). `acquire`/`status`/`takeover` exposent aussi la
**generation** courante (`lock_gen()`, L96 — deja calculee, jamais rendue en JSON) : c'est le
candidat le plus proche d'un jeton de fence au sens strict (numero monotone qui invalide l'ancien
tenant), et LOCK-05 en a besoin.

**MESURE, pas suppose** (`32-TERRAIN.md` §9, trois observations concordantes) : un sous-agent
**partage** le `session_id` de sa session parente — le guard qui compare `payload.session_id` a
`meta.session_id` **ne bloquera pas les workers de la mission detentrice**. C'est ce fait mesure
qui rend le mecanisme viable ; comparer sur `agent_id` (absent hors sous-agent, jamais partage)
aurait bloque le manager lui-meme.

**Limite structurelle a ecrire noir sur blanc, pas a laisser croire** : la granularite est la
**session**, pas la mission. Le guard garantit « aucune AUTRE session ne commite sous mon lock »,
jamais « aucun autre acteur DE MA session ». Les incidents documentes (I1-I4) sont tous
inter-sessions — la granularite session les couvre tous — mais ce n'est pas une garantie plus
fine, et le dire autrement serait mentir sur la portee de la garde.

**Ordre de decision du guard** (repris tel quel de `32-TERRAIN.md` §9, deja argumente et
sourced) :
1. Non-applicable (pas de lock, lock perime, commande non concernee) → allow silencieux.
2. `meta.session_id` vide (lock pre-phase-32, ou CLI hors session) → allow, repli sur comparaison
   `worktree` (retrocompatibilite obligatoire).
3. `payload.session_id == meta.session_id` → allow (couvre manager et ses workers).
4. Sinon → deny, motif portant owner/step/branch/age + marche a suivre.
5. Meme arbre, session differente : `check-branch-claim.sh:16-20` tranche deja doctrinalement
   (deux sessions du meme worktree partagent de fait leur arbre).

**Reliquat de mesure NON LEVE, a lever avant de figer ce mecanisme (F2)** : `claude --resume` /
`/clear` conservent-ils le `session_id` ? **Non mesure**, potentiellement bloquant — un resume qui
mint un nouvel UUID verrouillerait le detenteur legitime hors de son propre lock a la reprise ; le
repli `worktree` (regle 2) ne l'absorbe que si `session_id` redevient vide, pas s'il change vers
une autre valeur non vide. **Ce n'est pas un des deux research flags du ROADMAP** (deja leves,
spike + rejeu) — c'est un troisieme flag, decouvert par le terrain, non leve. A mesurer au debut
de l'execution du Lot 2, avant d'ecrire la comparaison en dur.

### D-32-04 — LOCK-05 : jeton = generation exposee, trailer par convention, aucune verification machine construite ici

**Decision** : LOCK-05 est servi par (a) l'exposition de `generation` en JSON (D-32-03) et (b) une
**convention documentee** — l'agent/manager qui pose un commit de mission y ajoute un trailer
`Fence: <generation>`, au **meme tier** que `Co-Authored-By:`/`Claude-Session:` deja en usage par
convention seule (297-371 occurrences sur 300 commits, jamais poses ni verifies par une machine —
`32-TERRAIN.md` §6). **Aucun mecanisme neuf d'enforcement** (pas de hook `commit-msg`, pas de
gate CI qui parse les trailers) n'est construit dans cette phase.

**Motif du refus de construire l'enforcement** : deux obstacles reels, pas des pretextes.
(1) Aucun outillage de trailer n'existe (`.git/hooks/` = `.sample` uniquement, aucun
`commit-msg`/`prepare-commit-msg`) — en creer un pour ce module reproduirait exactement le
conflit mesure au spike §7 entre `core.hooksPath` (que ce depot arme deja pour `pre-push`, via
`CLAUDE.md`) et tout hook git supplementaire non versionne, avec la meme non-distribuabilite aux
labs qui installent le module `conductor`. (2) `merge-hooks.sh` ne connait que les hooks Claude
Code (`hooks.json` → `PreToolUse` etc.) — pas les hooks git natifs. Distribuer un `commit-msg`
serait une **extension de capacite** du moteur de merge, hors du perimetre de cette phase et hors
de ce que le texte de LOCK-05 exige litteralement (« auditable », pas « bloque a la source »).

**Consequence assumee** : le trailer est **auditable a la main** (comme les deux autres
aujourd'hui), pas **verifie machine**. Un audit outille (script qui recoupe les commits d'une
mission au journal de takeover, non bloquant) est une extension possible, listee en §Remontees,
pas construite ici.

### D-32-05 — Le guard est **un seul script**, deux entrees `hooks.json` (Bash, Write|Edit)

**Decision** : `plugin/conductor/scripts/guard-driver-lock.sh` (nom indicatif) porte **toute** la
logique de comparaison de session (D-32-03) une seule fois. Deux entrees dans
`plugin/conductor/hooks/hooks.json` — matcher `Bash`, matcher `Write|Edit` — invoquent **le meme
script**, qui lit `tool_name` dans le payload pour choisir sa voie d'extraction : `Bash` →
`tool_input.command` (patron de prefiltre + `command_positions()` de
`guard-bash-registres.sh`, reutilise, pas reinvente) ; `Write`/`Edit` → `tool_input.file_path`
restreint a `.planning/` (patron d'enregistrement de `guard-agent-write.sh`, mais **pas sa
logique de validation** — un point a clarifier explicitement, voir ci-dessous).

**Clarification necessaire sur la formulation du mandat** (« en reutilisant
`guard-agent-write.sh` ») : lu comme **reutilisation du patron d'architecture** (prefiltre
pur-bash a zero-spawn, resolution `PYBIN` via `vf-portable.sh`, un seul spawn python, sortie
`permissionDecision: deny` + `exit 0`) — **pas** un appel au script lui-meme, dont la logique
metier (validation de frontmatter d'agent via `check-agents.sh --file --strict`) n'a aucun
rapport avec la comparaison de session d'un lock. Une lecture litterale (appeler
`guard-agent-write.sh` pour un Write dans `.planning/`) produirait un deni sur un mauvais motif
ou un faux-negatif systematique. A confirmer au plan, sans bloquer le cadrage.

**Cohabitation matcher `Bash`** avec `guard-bash-registres.sh` (consolidator, meme matcher) :
`merge-hooks.sh` ne reutilise un groupe de meme matcher que s'il est **entierement possede par
VF** (`is_local_entry`/§4 L299-317) — les deux guards viennent de modules VF, la reutilisation de
groupe devrait donc passer sans conflit, mais c'est une hypothese a **verifier empiriquement**
apres le premier `merge-hooks` (pas un fait mesure).

### D-32-06 — Prefiltre pur-bash, spawn python uniquement sur commande candidate

**Decision** : reprend le chiffrage mesure (`32-TERRAIN.md` §11 : bash pur ~6,7 ms, +spawn python
~24,4 ms, soit ~3,6x). Le prefiltre teste une **sous-chaine litterale**, surensemble strict du
domaine de deny — la liste de gestes de la surface A du rejeu (`git commit`, `checkout`,
`switch`, `restore`, `merge`, `rebase`, `cherry-pick`, `revert`, `reset`, `clean`, `push`, `tag`,
`branch -D`, `stash`, `worktree add/remove`, `gh pr/release`) — avant tout spawn, avant meme de
lire le lock. Cas nominal (~99% des appels Bash) reste a ~1-2 ms ; le spawn python ne paie que sur
les commandes suspectes, et seulement si un lock **present et non-perime** existe.

**Voie de refus** : `permissionDecision: "deny"` + `exit 0` (jamais `exit 2`) — trois motifs
convergents deja ecrits dans le depot (`docs/HOOKS-CONTRAT-SORTIE.md` : le `2` est reserve au
harness ; `vf-portable.sh` L126-130 : `exit 2` bloquerait l'edition tant que Python manque, contre
la doctrine « degrade mais utilisable » ; **MESURE** DIV-1/DIV-2 : `permissionDecisionReason` est
rendu au modele en clair, `exit 2` fuit le chemin absolu du script). Le motif de refus porte
owner/step/branch/age et la marche a suivre — pas seulement pour l'humain : DIV-1 etablit que
c'est un canal d'instruction pour le modele.

**Echappatoire explicite obligatoire** : variable/prefixe reconnu, patron `vibeflow:allow-large-
file` deja en place — nom indicatif `vibeflow:allow-lock-override`. Sans elle, un lock zombie non
perime rend le depot non-commitable et **enseigne le contournement par un autre outil**
(regression vecue et nommee par `guard-file-size.sh:9-12`). Un cas de suite doit prouver que
l'echappatoire fonctionne.

**`worktree add`** : geste **nommement epargne** (echappatoire declaree), pas seulement absent du
prefiltre — c'est la porte de sortie que le lock lui-meme prescrit quand il est tenu par autrui.

### D-32-07 — Perimetre d'ecriture reel : conductor seul, rien d'autre a toucher

**Decision, tranchee ici** (question 6 du mandat) : la contrainte ROADMAP « ne touche que
`conductor` » est **respectee litteralement** en n'ecrivant que sous `plugin/conductor/**`
(driver-lock.sh, le nouveau guard, hooks.json, les suites de tests). Les trois mecanismes
generiques cites au terrain — decouverte CI (`ci.yml` §L210-236), armement `merge-hooks.sh`,
gate PORT-05 — sont **deja generiques et deja capables de voir une entree neuve sans etre
modifies** : la decouverte CI matche tout `*/tests/test-*.sh` sous `plugin`/`scripts`, PORT-05
derive son compte attendu des `hooks.json` de la fermeture resolue (donc bouge automatiquement).
**Zero ligne a ecrire hors `conductor`** pour livrer les cinq exigences.

**Corollaire (question 7)** : « armement prouve par le gate regle 4 » du critere de succes n°2
designe, apres verification, **le gate CI PORT-05** (`ci.yml` L800-901), pas
`check-capability-activation.sh` (`plugin/dev-orchestrator`). La regle 4 de ce dernier **ne
connait pas les hooks** — son corpus est fait de frontmatters d'agents/skills, sa liste `ARM[]`/
`OKID[]` est litterale et fermee (`32-TERRAIN.md` §5, L86-90) ; y ajouter une cle serait une
ecriture hors `conductor` (dans `dev-orchestrator`) et une extension manuelle explicitement decrite
comme telle par le code lui-meme. PORT-05, lui, rougit deja mecaniquement sur toute entree de hook
mal formee, sans modification. **Amendement de lecture du critere n°2** (le mot « regle 4 » du
ROADMAP est une imprecision de redaction — la garantie visee existe, sous un autre nom) —
consigne, remonte en §Remontees pour confirmation, non bloquant pour le plan.

</decisions>

<open_decision>
## D-32-QUAL — QUAL-01 : le mot « BRUYANT » n'a pas de mecanisme existant — a trancher par Samuel

**Ne pas repondre a la place de Samuel.** Le ROADMAP exige « fail-open BRUYANT si le lock est
illisible — jamais un vert ». **Aucun canal existant ne le realise** (`32-TERRAIN.md` §11,
mesure) :

1. `exit 17` (`vf_guard_unavailable`) + stderr → **MESURE : n'atteint ni le modele ni l'humain**
   en non-interactif (l'outil s'execute, « No error received »).
2. `systemMessage` sur `allow` → **MESURE : n'atteint pas le modele** (non teste en TUI).
3. Le marqueur de sante (`$VF_GUARD_HEALTH_DIR`) → **aucun consommateur** dans `plugin/` ; le
   « hook doctor » qui devait l'agreger est decrit mais **n'existe pas** (0 occurrence, verifie).

**Trois issues honnetes, deja qualifiees au terrain** :

- **(A) `permissionDecision: "ask"`** — bruyant et non-permissif, mais interrompt le flux et
  **peut ne pas etre disponible a un sous-agent backgrounde** (non mesure pour `ask`
  specifiquement ; a rapprocher de la memoire « AskUserQuestion absent en subagent »).
- **(B) fail-open silencieux + marqueur de sante, ET livrer dans la meme phase le hook doctor
  `SessionStart`** qui l'agrege — seule voie qui respecte ADR-031 sans mentir sur « bruyant »,
  mais **ajoute un livrable non prevu au perimetre** (extension assumee).
- **(C) assumer par ecrit que « bruyant » = « trace sur disque + stderr »**, en sachant que
  personne ne le lit aujourd'hui — **vert de complaisance, deconseille**.

**Ma recommandation** : **(A)**, avec la reserve mesuree ci-dessus a lever en premier geste du
Lot 2 (mesurer si `ask` atteint un sous-agent backgrounde avant de l'adopter definitivement). Si
la mesure infirme `ask` en sous-agent, replier sur **(B)** plutot que (C) — (C) fait mentir le mot
du ROADMAP, ce que ni ce cadrage ni l'execution ne devraient assumer seuls. **(C) n'est acceptable
que si Samuel le valide explicitement en connaissance de cause.**

Cette decision ne bloque que le detail du chemin d'echec « guard indisponible » du Lot 2 — le
reste du guard (PASS/DENY/imparsable-silencieux) est independant et peut etre construit et prouve
sans attendre la reponse.

</open_decision>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Recherche de phase (deja produite, a citer, pas a rejouer)
- `.planning/phases/VFDO-32-durcissement-du-driver-lock/32-TERRAIN.md` — anatomie de
  `driver-lock.sh` (§1-2), decouverte CI (§3), `merge-hooks`/hooks.json existants (§4), gate
  d'armement (§5), trailers/fence (§6), contrat de sortie des hooks (§7-8, MESURE), payload et
  identite de session (§9, MESURE), patron `guard-file-size.sh` (§10), cout et trou QUAL-01
  (§11, MESURE).
- `32-SPIKE-reference-transaction.md` — verdict clos : PAS SUR pour bloquer (rebase wedge,
  contournement `core.hooksPath`, `worktree add` casse). Decision D-32-A en decoule.
- `32-REJEU-contournements.md` — 4 incidents reels (I1-I4), scenarios A/B rejoues avec preuve de
  seam par mutation, surface A/B/C des gestes contournant le lock, 5 fragilites a traiter au plan
  (§6 : matching par sous-chaine, armement non teste par le rejeu, faux-vert B3, TTL non
  deterministe, I2 pas encore rejoue).

### Code au coeur de la phase
- `plugin/conductor/scripts/driver-lock.sh` (286 l.) — cinq verbes, `new_generation()` L109-125,
  `rewrite_meta()` L129-142, `lock_age()` L80-88, bloc PERIME d'`acquire` L196-229, `recover`
  L262-280.
- `plugin/conductor/scripts/tests/test-driver-lock.sh` (144 l., 14 cas) — convention de suite du
  dossier a suivre a la lettre : `set -uo pipefail` sans `-e`, isolation `mktemp -d` + `trap`,
  helpers agnostiques du protocole (`age_stale()` L27-39).
- `plugin/conductor/scripts/check-branch-claim.sh` — consommateur externe du `meta`, contrat a 4
  codes (0/3/4/64), lock perime deja traite comme absent (L118-126) — patron a reprendre partout
  ou le guard doit distinguer « rien a signaler » d'« indetermine ».
- `plugin/software-architecture/scripts/guard-file-size.sh` (169 l.) — LE patron de guard
  bloquant en forme exec a reprendre : prefiltre L31-35, bloc `vf-portable:locator` L37-73,
  profil rapide L75-84, fail-open silencieux vs bruyant (L165-167 vs L78-84), echappatoire
  `vibeflow:allow-large-file` L91-94.
- `plugin/consolidator/scripts/guard-bash-registres.sh` — patron d'analyse de commande Bash a
  reutiliser pour le prefiltre : troncature heredoc L73 (CSL-05), `command_positions()` L106-133
  (CSL-04, wrappers `sudo`/`env`/`nohup`/`xargs`/`nice`/`time`), segmentation `||`/`&&`/`;`/`|`
  L178, limite assumee ecrite L26-27.
- `plugin/conductor/scripts/guard-agent-write.sh` — patron d'**architecture** a reutiliser (D-32-05
  clarifie : le patron, pas la logique metier).
- `plugin/_internal/merge-hooks.sh` — `is_local_entry()` L237-242, reutilisation de groupe
  conditionnelle L299-317, forme exec + `exec_safe_prefix()` L141-160, garde `{{` residuel
  L362-364 (bug v2.53.0, deja corrige).
- `docs/HOOKS-CONTRAT-SORTIE.md` — contrat de sortie des hooks `PreToolUse` (5 bloquants sur 26,
  4 par JSON).
- `.github/workflows/ci.yml` L210-236 (decouverte des suites) et L800-901 (gate PORT-05, forme
  exec telle qu'installee).

### Doctrine
- ADR-053, ADR-064 (claim etendu branch/worktree) — fondent le patron d'ajout additif au `meta`.
- ADR-031 (advisory par defaut, jamais de fix sans validation humaine) — fonde D-32-QUAL et le
  refus d'un `exit 2` bloquant.
- ADR-044 — hors sujet direct, cite pour memoire (c'est le contrat que `guard-agent-write.sh`
  applique, PAS celui que le guard du lock doit appliquer — voir D-32-05).
- `.planning/STATE.md:664` et
  `plugin/dev-orchestrator/references/mission-cross-team.md:19,101` — citent T2 comme garantie
  machine de dernier ressort de l'invariant « un seul manager actif » ; a ne pas casser.

</canonical_refs>

<code_context>
## Existing Code Insights

### Patrons etablis a reutiliser (jamais reinventer)
- Gates a quatre issues (PASS / DENY / imparsable-silencieux / indisponible-bruyant) + mutation
  rouge prouvee par sa trace (assertion, attendu, obtenu) — QUAL-01 transverse.
- Prefiltre pur-bash a zero-spawn avant tout travail couteux (les trois guards `PreToolUse`
  existants font ce geste).
- Epochs **forges**, jamais de `sleep` dans les tests — patron `age_stale()` de
  `test-driver-lock.sh:27-39`. Tout cas touchant au battement (LOCK-01/04) doit suivre ce patron
  sous peine de flakiness CI (fragilite n°4 du rejeu).
- Champ additif au `meta` : ecrit dans `new_generation()` **et** preserve dans `rewrite_meta()`,
  jamais l'un sans l'autre (sinon un heartbeat emis d'un autre contexte reecrit le proprietaire) —
  patron `branch`/`worktree` (ADR-064).

### Fragilites identifiees, a traiter au plan (rejeu §6, pas a decouvrir en execution)
1. Le matching par sous-chaine est une passoire (`eval`, alias, script qui commite en interne,
   `git -C`). Clause de limite obligatoire en en-tete du guard + au moins un cas de test « commit
   indirect » rouge assume et documente comme hors de portee.
2. Les scripts de rejeu testent le guard, **pas** son armement. Un troisieme cas est necessaire :
   verifier que `merge-hooks` pose bien l'entree (le vrai risque, prouve deux fois — #38 et
   v2.49.0→v2.50.1 — est un guard qui existe et n'est pas branche).
3. B3 (le commit du detenteur atterrit sur sa branche) peut devenir un faux vert avec un guard
   qui bloquerait tout le monde — **B4 (discriminance : le detenteur passe) ne doit jamais etre
   retire**.
4. TTL/sleep-dependance — voir patron ci-dessus.
5. I2 (Write/Edit concurrent dans `.planning/`) n'est pas encore rejoue — a faire au plan, meme
   patron de seam que A/B.

### Integration Points
- Phase 33 (watchdog) depend de cette phase : « meme battement que LOCK-01, deux consommateurs »
  — le champ de lease/heartbeat expose ici (D-32-01) est vraisemblablement ce que Phase 33
  consomme, sans que cette phase n'ait a le construire pour elle.
- `check-branch-claim.sh` reste un consommateur passif du `meta` — les ajouts (D-32-02, D-32-03)
  sont additifs, ne cassent pas son contrat a 4 codes.

</code_context>

<specifics>
## Specific Ideas

- Nom de fichier journal indicatif : `${LOCK_BASE}.takeovers.log` — a confirmer/renommer au plan,
  ce cadrage ne fige que le mecanisme (append-only, une ligne JSON par evenement), pas le nom
  final.
- Nom d'echappatoire indicatif : `vibeflow:allow-lock-override` — meme motif, a confirmer au plan
  par coherence avec `vibeflow:allow-large-file`.
- Le decoupage en lots recommande pour le plan (dependances, pas des plans figes) :
  - **Lot 1** (`driver-lock.sh` seul, sequentiel en interne) : (a) champs additifs
    `session_id`/`generation` exposee — prealable de tout le reste — puis (b) LOCK-01
    (observabilite lease) puis (c) LOCK-04 (retrait de l'auto-steal, verbe `takeover`, journal).
  - **Lot 2** (le guard, LOCK-02+03) : depend de Lot 1(a) seulement — peut demarrer avant que
    1(b)/1(c) ne soient finis. Premiere tache du lot : lever F2 (mesure `--resume`/`/clear`).
  - **Lot 3** (LOCK-05) : depend de Lot 1(a) seulement (generation exposee) — convention +
    documentation, independant du Lot 2.
  - **QUAL-01/D-32-QUAL** : ne bloque qu'un sous-detail de Lot 2 (le chemin « guard
    indisponible ») — le reste de Lot 2 n'attend pas la reponse de Samuel.
- Les suites de tests neuves/etendues vivent dans `plugin/conductor/scripts/tests/` a la
  convention du dossier (patron copie, pas de harness partage) — `test-driver-lock.sh` etendu pour
  Lot 1, une suite neuve `test-guard-driver-lock.sh` (nom indicatif) pour Lot 2, alimentee par les
  scenarios A/B/C du rejeu portes au niveau definitif.

</specifics>

<deferred>
## Deferred Ideas — remontees a Samuel, extensions de perimetre non tranchees ici

1. **Audit outille du trailer LOCK-05** (script non-bloquant qui recoupe commits de mission et
   journal de takeover) — utile mais hors du texte litteral de l'exigence (« auditable » a la
   main suffit). Voir D-32-04.
2. **Hook `commit-msg` distribue** pour verifier machine le trailer LOCK-05 — obstacle reel double
   (aucun outillage de trailer dans ce depot, `merge-hooks.sh` ne connait pas les hooks git
   natifs) — construire ceci serait une extension de capacite du moteur, pas de cette phase. Voir
   D-32-04.
3. **Elargir `check-capability-activation.sh` (regle 4) aux hooks** — ecriture hors `conductor`
   (dans `dev-orchestrator`), et le gate PORT-05 couvre deja la garantie visee. Voir D-32-07 —
   demande confirmation de lecture, pas une extension necessaire.
4. **Auto-takeover sur battement MORT (pas sur TTL)** — explicitement note « reevaluable
   post-LOCK-01 » par `REQUIREMENTS.md` §Out of Scope. Pas dans cette phase.
5. **Nom exact du script du guard et du journal de takeover** — indicatifs seulement (§Specific
   Ideas), a fixer au plan.

</deferred>

---

*Phase: 32-Durcissement du driver-lock*
*Context gathered: 2026-08-16*
