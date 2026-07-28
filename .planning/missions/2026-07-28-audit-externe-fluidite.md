# Prompt — améliorer la fluidité et la rapidité de VibeFlow sans perdre en qualité

> À coller tel quel dans une session VibeFlow (scope mainteneur).
> Écrit le 28/07/2026, à partir d'un audit mené sur le lab `ExploreSomfy`.

---

Tu interviens sur VibeFlow, dont je suis le mainteneur. Objectif : rendre le flux de
dev plus rapide et plus fluide SANS perdre en qualité. Quatre changements, tous
fondés sur un audit mené le 28/07/2026 sur un vrai projet iOS (une tranche de dev en
5 lots, dont 2 parallélisés par worktrees, ~90 commits, suite de tests passée de 177
à 331). Les constats ci-dessous sont vérifiés sur pièce, pas supposés.

## Non-négociables — ne me propose aucune de ces deux choses

1. **Réduire le nombre de tests.** Mesuré : sur 90 s de `test_sim`, les tests pèsent
   ~1 s, tout le reste est compilation et installation. Levier nul.
2. **Alléger la revue sur le chemin critique produit.** C'est là qu'ont été trouvés
   5 bloquants en une journée, dont un qui cassait le geste le plus fréquent de la
   démo et un qui coupait un deadman sous le doigt de l'utilisateur.

## Garde-fou transverse, tiré des chiffres

Sur cette phase, **9 fois, puis 5, puis 4 défauts sont nés des correctifs de revue
eux-mêmes**. Donc : tout allègement que tu introduiras ne doit JAMAIS s'appliquer à
un **diff de comblement**. Une re-revue reste pleine, quelle que soit la nature du
lot d'origine.

---

## Changement 1 — Donner XcodeBuildMCP au relecteur (doctrine, ADR-051 à réviser)

**Constat.** ADR-051 (19/07) décide que `vf-dev-manager`, `vf-reviewer` et
`vf-auditer` restent sans MCP, au motif du moindre privilège : « ils ne compilent
jamais ». La mécanique est propre (flag `vf-mcp-consumer: true` +
`inject-mcp-tools.sh`), elle fait ce pour quoi elle a été conçue. Mais la prémisse ne
tient pas :

- `vf-reviewer` a déjà `Bash`, l'outil le plus large. Il ne lui manque pas l'outil
  dangereux, il lui manque l'outil sanctionné — et comme le `CLAUDE.md` du projet
  interdit `xcodebuild` en shell, le relecteur a le droit de faire la chose interdite
  et pas la propre.
- « Ils ne compilent jamais » confond **produire** un verdict et **vérifier** un
  verdict. Un relecteur n'a pas besoin de compiler pour livrer, il en a besoin pour
  ne pas *croire* un message de commit. Constaté : « la revue de phase a dû croire un
  message de commit ».
- Le moindre privilège invoqué **n'existe déjà plus** : `memory:` active
  automatiquement `Read/Write/Edit`, donc `vf-reviewer` apparaît au runtime avec
  `Write, Edit` alors que son fichier déclare `Read, Bash, Glob, Grep, Agent`. Le
  « je juge, je ne corrige pas » est une consigne de prompt, pas une barrière.

**Ce que je veux.** Réviser ADR-051 sur ce seul point, avec l'argument explicite
« un relecteur ne PRODUIT pas de verdict de compilation, il en VÉRIFIE un », et
ajouter `mcp__XcodeBuildMCP__*` à `vf-reviewer` — à lui seul, pas à `vf-auditer` ni
à `vf-dev-manager`.

**À instruire avant de livrer** : la doc Anthropic autorise un nom d'outil exact dans
les *permissions*, mais n'illustre jamais un nom exact d'outil MCP dans le `tools:`
d'un subagent. Si une allowlist fine (`test_sim` / `build_sim` seulement) est
possible, elle est préférable au wildcard. **Teste-le, ne le suppose pas.**

**Coût à assumer et à écrire** : un relecteur qui peut lancer les tests va les
lancer, donc +90 s par revue, et il consomme un slot de simulateur.

---

## Changement 2 — Sortir la revue de `vf-coder` et la graduer par RISQUE

**Constat, et c'est un défaut de placement, pas de doctrine.** Le framework sait
déjà graduer : `vf-dev-manager` a une doctrine de sélection d'étages explicite
(« une étape UI saute l'audit sécurité ; une étape sécurité le garde »). L'audit est
gradable, le test est gradable. **La revue ne l'est pas, parce qu'elle est enfermée à
l'étape 4 du cycle interne de `vf-coder`, en dur, sans condition.** Le manager n'a
aucune prise dessus.

Et la seule gradation existante (`gsd-fast` / `gsd-quick`) est indexée sur la
**taille** (« si la tâche tient en un commit »). C'est le mauvais axe : trois lignes
sur un chemin BLE partagé sont minuscules et à très haut risque ; 400 lignes de
Domain pur prouvées par mutation sont grosses et à bas risque.

**Rendement observé, par nature de lot :**

| Nature du lot | Bloquants trouvés | Les tests les auraient attrapés ? |
|---|---|---|
| Adaptateur matériel (non injectable, non testable) | 3 | Non |
| Contrôleur partagé entre features | 3 | Non |
| **Jointures entre lots parallèles** | **4 bloquants + 9 majeurs** | Non — « aucun relecteur cadré sur un seul lot ne les aurait vus » |
| Geste utilisateur / géométrie de vue | 3 | Non — trouvés par géométrie et capture d'écran |
| **Domain pur avec tests de mutation** | **0** | Oui, terrain le mieux couvert |
| Documentation / catalogue de chaînes | 0 bug, mais 2 faits faux bloquants pour la mission suivante | Sans objet |

**Ce que je veux.**

1. Faire de la revue un **étage de premier rang** piloté par le manager, au même
   titre que l'audit et le test. Sans ça, la gradation n'a nulle part où s'appliquer.
2. Des **critères de déclenchement objectifs**, pas des seuils au jugé :
   - **revue renforcée, non négociable** si le diff touche (a) un adaptateur d'infra
     non couvert par les tests, (b) un fichier **partagé avec une mission parallèle
     en vol**, (c) du code que la mutation ne couvre pas, (d) un geste utilisateur ou
     une géométrie de vue ;
   - **revue de jointure obligatoire, en nœud séparé**, dès que deux lots parallèles
     fusionnent — c'est le meilleur rendement de toute la tranche, et cet étage
     n'existe aujourd'hui que parce que je l'ai créé à la main ;
   - **revue allégée** (relecture de diff sans dispatch d'étage complet) sur du
     Domain pur à mutation verte, la documentation, un catalogue sans ajout de clé.
3. **En cas de doute, revue pleine.** Le classement du lot devient un point de
   décision, donc un point d'erreur : le défaut par défaut doit être le sûr.

---

## Changement 3 — `MISSION-INVARIANTS.md`, parce que le trou est un FICHIER

**Constat, et il m'incrimine.** Le contrat de brief (`mission-contracts.md`) est
délibérément minimal et dit explicitement : « le brief ne porte QUE ce qui n'est pas
sur disque, il ne paraphrase jamais `ROADMAP.md` / `STATE.md` / `PROJECT.md` ». Et
`vf-dev-manager` lit déjà le `CLAUDE.md` du projet avec préséance. Donc quand je
recopie à la main les conventions et les gates dans chaque brief, je duplique ce que
la machine va lire de toute façon — et c'est précisément cette recopie qui m'a fait
produire une contradiction interne qu'il a fallu corriger en cours de mission. **Le
gabarit ne m'a pas manqué : j'ai court-circuité celui qui existe.**

**Mais trois invariants ne vivent nulle part sur disque**, et aucun agent ne peut les
deviner :

1. le **seuil de tests courant** (mouvant : 177 → 331 en une journée) ;
2. la **table des fichiers gelés** par mission en vol — qui appartient à qui, en ce
   moment ;
3. les **motifs de risque récurrents** du projet (« la neuvième occurrence du motif
   de la phase », dit un rapport — donc le motif est connu mais n'est écrit nulle part).

**Ce que je veux.** Un `.planning/MISSION-INVARIANTS.md` court, relu par le manager
au même titre que `STATE.md`, portant ces trois choses plus la contrainte
d'outillage du moment. Le brief reste à ses champs minimaux.

**Coût à écrire noir sur blanc** : s'il ment, il est pire que rien. C'est exactement
ce qui s'est produit avec un `CLAUDE.md` qui affirmait encore « deux trous
interdisent toute installation device » alors que la mission suivante devait
précisément recetter sur device. Prévois comment il est tenu à jour, ou ne le crée
pas.

**Bonus** : la table des fichiers gelés alimente directement le critère (b) du
changement 2.

---

## Changement 4 — `check-agents.sh` : une option d'exclusion

**Constat.** Les hooks `SessionStart` appellent `check-agents.sh --hook` et
`check-debug-research.sh --hook`, qui cherchent `.claude/agents` **en relatif au
cwd**. Or VibeFlow est installé en scope user : les agents vivent dans
`~/.claude/agents` (42 agents, 90 skills), et il n'y en a **aucun** dans le projet.
Les deux hooks tournent, ne trouvent rien, sortent 0, et sont en plus masqués par
`|| true`. **Le garde-fou de conformité ne regarde rien depuis le début** — ce qui
explique que l'écart entre le `tools:` déclaré et le `tools:` runtime de
`vf-reviewer` n'ait jamais été signalé.

**Mais le corriger naïvement le rend inutilisable** : pointé sur le bon dossier, il
sort **68 lignes au démarrage de chaque session**, dont **66 findings tous sur des
agents `gsd-*`** (un autre plugin, qui n'a pas à suivre ADR-029) et **zéro sur les
agents `vf-*`**. Testé le 28/07, puis annulé pour cette raison.

**Ce que je veux.** Une option `--exclude=GLOB` (ou un cadrage par défaut sur les
agents que VibeFlow gouverne), pour que le garde-fou soit à la fois **silencieux** en
régime nominal et **utile** sur les dérives futures. Puis corriger le scope dans les
deux hooks.

---

## Livrable attendu

Pour chaque changement : ce qui bouge (fichier par fichier), le gain, **le coût et le
risque**, si c'est réversible, et l'ADR à créer ou réviser. Distingue nettement ce
qui est une correction de configuration de ce qui est un changement de doctrine.

Et si tu constates qu'un de ces quatre constats est faux ou daté, dis-le : ils
viennent d'un audit sur un seul lab, avec un seul projet.

---

## Annexe — ce qui a DÉJÀ été appliqué le 28/07, à ne pas refaire

- **Profils de session XcodeBuildMCP désactivés** : `XCODEBUILDMCP_DISABLE_SESSION_DEFAULTS=true`
  dans le `.mcp.json` du lab. Motif : le serveur n'a qu'**un seul `SessionStore`
  global** partagé par la fenêtre principale et tous les sous-agents, avec un
  `activeProfile` en variable globale, et `build_sim` / `test_sim` **n'exposaient
  aucun paramètre de projet** dans ce mode. Il n'existait donc aucun moyen de rendre
  une mesure déterministe par ses arguments. Constaté : une exécution complète partie
  sur le code d'un autre worktree. C'est le mode que le CLI du paquet s'impose déjà à
  lui-même. **Conséquence : chaque appel de build doit désormais porter son
  `projectPath`, son `scheme` et son `simulatorId` / `deviceId`.**
- **Purge du cache** `test-products` : 12 Go → 1,3 Go (362 artefacts de runs passés,
  jamais nettoyés).
- **Non appliqué, et volontairement** : le correctif de scope des linters (voir
  changement 4), parce qu'il produisait 68 lignes de bruit au démarrage de chaque
  session.

## Annexe — piège d'outillage à garder écrit quelque part

Un `build_sim` **en cache** (zéro tâche `SwiftCompile`) annonce « 0 warning » **sans
rien compiler**. Un verdict de warnings non précédé d'un `clean` est structurellement
invérifiable. À intégrer à la doctrine de gate si ce n'est pas déjà fait.
