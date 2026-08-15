# Pitfalls Research — fiabilite-v1.0

**Domain:** Plugin Claude Code multi-modules (bash portable + JSON + Markdown), moteur d'install scopé, gates CI stricts, parc installé chez des tiers (Windows inclus)
**Researched:** 2026-08-15
**Confidence:** HIGH sur les pièges ancrés sur incidents documentés du repo · MEDIUM sur les pièges de portabilité Windows généraux

> Angle : pas les erreurs génériques du domaine, mais les erreurs spécifiques à **l'ajout de ces
> features-là dans ce système-là** — un système déjà durci (55 suites, gates machine, parc
> installé) où le mode de défaillance dominant historique est le **faux-vert** et **l'écart
> repo ↔ parc installé** (leçon structurelle de la régression #38).

---

## Critical Pitfalls

### Pitfall 1 : Migrer les `hooks.json` en forme exec avant que `merge-hooks.sh` n'apprenne `args`

**What goes wrong:**
Trois effets simultanés et silencieux sur le parc installé, documentés au §1.3 de la spec Windows II :
(1) `{{VF_SCRIPTS}}` écrit **littéralement** dans le `settings.json` de l'utilisateur (la substitution
ne lit que `command`, l.167) → hook mort ; (2) la dédup (`frag_basenames()` / `references()`) ne voit
plus aucun script → l'ancienne entrée shell n'est jamais retirée, le hook **s'exécute deux fois** et
un groupe s'empile à chaque update ; (3) le mode `remove` `die()` sur set vide → **module non
désinstallable**. Aucun message d'erreur dans les trois cas.

**Why it happens:**
La tentation naturelle est de livrer le lot « visible » (les `hooks.json`) avant le lot « moteur »
(`merge-hooks.sh`), parce que les fragments sont dans les modules et le moteur dans `_internal/`.
Et parce que le fragment migré **fonctionne** en test local frais — le dégât n'apparaît qu'au
premier `update` d'un lab existant.

**How to avoid:**
L'ordre (a) moteur → (b) codes de sortie → (c) fragments est **une condition de non-régression, pas
une préférence** (spec §2). L'imposer par la machine : un test de `test-merge-hooks.sh` qui monte un
fragment en forme exec contre le moteur courant et exige la dédup cross-forme AVANT de merger tout
`hooks.json` exec. La sonde de parc du §4 (settings.json réaliste : entrées VF shell + tierces +
gsd-core → merge exec → remove → zéro résidu VF, zéro entrée tierce touchée) est le critère de merge.

**Warning signs:**
Une PR qui touche `plugin/*/hooks/hooks.json` sans toucher `plugin/_internal/merge-hooks.sh` ni sa
suite de tests. Un `settings.json` de lab de test contenant deux groupes pour le même script.

**Phase to address:** Phase Windows II — le plan doit encoder l'ordre en vagues dépendantes, pas en
consigne.

---

### Pitfall 2 : Supprimer `|| true` sans traduire les exit 3 — le démarrage de session devient bruyant

**What goes wrong:**
17 des 22 entrées de hook portent `|| true`, inexprimable en forme exec (pas de shell). Or les trois
hooks `SessionStart` de `dev-orchestrator` sortent **exit 3** dans le cas nominal silencieux
(mesuré 2026-08-02). Sans traduction, chaque démarrage de session affiche une erreur — précisément
quand le hook a décidé de ne rien dire. Variante pire sur `PreToolUse` : un exit 2 involontaire
**bloque l'appel d'outil** (plus aucune édition possible tant que la condition dure).

**Why it happens:**
Le contrat de signaux de la Phase 17 (exit 3 = silence volontaire) est un contrat **interne** aux
scripts ; `|| true` était sa traduction vers le harness. Retirer le traducteur sans retraduire est
invisible en revue de diff — le `hooks.json` migré est « correct » ligne à ligne.

**How to avoid:**
Inventaire exhaustif des 22 entrées avec code de sortie mesuré (pas supposé — certaines gardes
attendent du JSON sur stdin, ne pas les sonder à l'aveugle). Classer chaque entrée
`advisory`/`bloquante` explicitement (exigence contrat §7). Tenir la régression par un test
(« session start silencieux dans le cas nominal »), pas par relecture (critère de succès n°5 de la
spec). Trancher AVANT implémentation le code de `vf_guard_unavailable` sur `PreToolUse` : exit 2
bloque tout, autre non-zéro dégrade — la question est ouverte au contrat (§3.1) et elle est décisive.

**Warning signs:**
Un lab de test dont le démarrage de session affiche des messages qui n'existaient pas avant. Tout
`hooks.json` exec dont le script sous-jacent n'a pas de ligne dans l'inventaire des codes de sortie.

**Phase to address:** Phase Windows II, lot HOOKS étape (b) — bloquante avant (c).

---

### Pitfall 3 : Le chemin absolu de `bash` figé rend `settings.json` spécifique à la machine — et personne ne possède ce travail

**What goes wrong:**
Le contrat §5 exige un chemin absolu vers `bash` « résolu et vérifié à l'install » dans `command`.
Deux pièges : (1) le `settings.json` produit devient **non portable entre machines** (sync dotfiles,
settings commité en scope project → chemin d'une machine imposé à l'autre — exactement le motif de
la régression #38 : un réglage local qui ne voyage pas, ou qui voyage et casse ailleurs) ; (2) sous
Windows, le chemin qui marche dans Git Bash (`/usr/bin/bash`) n'est **pas** résoluble par le spawn
natif de Claude Code — il faut la forme Windows (`C:\Program Files\Git\bin\bash.exe`), donc une
conversion type `cygpath -w` au moment de l'install, pas au runtime. Et le §8 du contrat n'attribue
ce travail **à personne** (trou d'affectation identifié spec §3.2).

**Why it happens:**
Deux polarités (dev / gouvernance) se partagent le contrat, et le travail de moteur tombe entre les
deux. Côté chemin, le développeur teste dans Git Bash où les deux formes fonctionnent — la forme
POSIX ne casse que hors shell MSYS.

**How to avoid:**
Trancher l'affectation avec Willy **avant tout plan** (c'est la seule dépendance croisée réelle).
Résoudre le chemin à l'install via `cygpath -w` quand `IS_WINDOWS`, et tester le résultat par un
`spawn` réel, pas un `[ -x ]` (qui passe sur la forme POSIX dans Git Bash). Instruire l'effet de
bord scope project : soit interdire la forme exec en scope project commité, soit re-résoudre à
chaque install/update sur la machine cible.

**Warning signs:**
Un `settings.json` contenant `/usr/bin/bash` ou `/c/...` posé sur une machine Windows. Un plan de la
phase qui liste les `hooks.json` mais aucun item « résolution bash à l'install » dans `_internal/`.

**Phase to address:** Phase Windows II — pré-requis de cadrage (gsd-discuss-phase) : affectation §3.2
tranchée, sinon la phase n'est pas planifiable.

---

### Pitfall 4 : CRLF et `.gitattributes` — la comparaison par somme de contrôle du bloc localisateur casse sur le parc Windows

**What goes wrong:**
Le gate de Willy compare des **sommes de contrôle** du bloc `# >>> vf-portable:locator` entre
fichiers (spec §3.1). Si un contributeur Windows a `core.autocrlf=true` ou si `.gitattributes` ne
force pas `eol=lf` sur les `.sh`, le même bloc produit deux sommes → « dérive » détectée à tort, ou
pire : normalisation ajoutée au gate qui masque une vraie dérive. Second front : les **fixtures de
tests** (settings.json montés, fragments hooks) — un fichier de fixture ré-encodé CRLF par un
checkout Windows fait diverger un test qui compare des chaînes ou des offsets.

**Why it happens:**
ADR-054 (premier temps) a posé la normalisation CRLF et `test-windows-crlf.sh`, mais la surface
nouvelle (lib `vf-portable.sh`, marqueurs, fixtures de la sonde de parc) n'est pas couverte par la
garde existante — chaque feature ajoutée ré-ouvre le front CRLF si elle n'étend pas la garde.

**How to avoid:**
Étendre `test-windows-crlf.sh` à tout nouveau fichier `.sh`/fixture de la phase (la suite existe,
c'est une extension, pas une création). La normalisation du gate de checksum doit être **définie au
contrat** (strip `\r` avant hash) et testée par mutation : un bloc volontairement divergent doit
faire échouer le gate même en CRLF. Vérifier que `.gitattributes` couvre les nouveaux chemins
(`plugin/_internal/lib/`).

**Warning signs:**
Un gate de dérive qui passe sur macOS/CI Linux et échoue chez un testeur Windows (ou l'inverse).
`git diff` montrant un fichier « entièrement modifié » sans changement visible.

**Phase to address:** Phase Windows II — critère de succès additionnel : suites vertes **sur un
checkout `autocrlf=true` simulé** (la suite CRLF existante le permet).

---

### Pitfall 5 : La suppression des « chemins disparus » à l'update efface des fichiers utilisateur

**What goes wrong:**
Le nettoyage à l'update (fusion issue #20 + convergence) supprime ce qui « n'est plus dans le
module ». Si la liste des suppressions est calculée par différence entre *l'état du disque* et *le
catalogue de la version courante*, tout fichier utilisateur homonyme ou co-localisé
(`.claude/scripts/` accueille aussi des scripts perso, `settings.json` porte des hooks tiers et
gsd-core) devient supprimable. C'est le miroir exact de l'incident « double catalogues » : l'update
qui laissait traîner les fichiers des versions précédentes se corrige facilement en un update qui
supprime trop.

**Why it happens:**
L'engine ne sait pas aujourd'hui **ce qu'il a posé** — il ne loggue qu'au moment de poser. Sans
enregistrement persistant de la pose (manifeste *as-installed*, par scope), la seule source
disponible pour le nettoyage est le catalogue courant, qui ne décrit ni les versions passées ni ce
qui appartient à l'utilisateur.

**How to avoid:**
Le manifeste posé à l'install (fichier-par-fichier, **par scope**, avec version du module d'origine)
est la **précondition** du nettoyage : on ne supprime que ce que le manifeste d'une pose VF
antérieure revendique ET que la version courante ne revendique plus. Jamais de suppression par
différence disque↔catalogue. Dans `settings.json`, ne toucher que les entrées dont l'ownership VF
est prouvé (la mécanique de `references()` existe — c'est le même invariant que la sonde de parc :
zéro entrée tierce touchée). Ordre des livraisons : manifeste d'abord, nettoyage ensuite — un
nettoyage livré avant le manifeste n'a pas de source de vérité et improvise.

**Warning signs:**
Un plan de la phase où « suppression des chemins disparus » précède « manifeste » dans l'ordre des
vagues. Un test de nettoyage qui ne monte pas de fichier tiers/utilisateur dans l'arbre cible.

**Phase to address:** Phase manifeste/update (#20) — le manifeste est la vague 1, le nettoyage la
vague 2, la sonde « fichier tiers intact » est le gate des deux.

---

### Pitfall 6 : Le `--dry-run` diverge du chemin réel — il annonce X, l'install fait Y

**What goes wrong:**
Un mode `--dry-run` implémenté comme un **second chemin de code** (une fonction « liste ce qu'on
ferait ») dérive inévitablement du chemin d'écriture réel au fil des évolutions de l'engine. Le
manifeste annoncé devient rassurant et faux — c'est le pire résultat possible pour la demande
d'origine (revue croisée des hooks avant pose, équipe Windows). Précédent interne : le plan-check
d'install-ux-v1.0 a attrapé un **« faux-négatif dry-run »** comme blocker en phase 3.

**Why it happens:**
Le chemin d'écriture de `vibeflow-update.sh` est tissé de copies, merges Python embarqués et
hooks — brancher un flag « n'écris pas » sur chaque écriture est plus intrusif que réécrire une
liste à côté. La liste à côté est le raccourci naturel.

**How to avoid:**
L'issue #20 le dit déjà : « brancher un mode annonce-sans-écrire **sur les mêmes chemins** » — en
faire un invariant testé par mutation : le test exécute `--dry-run` puis l'install réelle sur le
même arbre et exige que le manifeste dry-run == manifeste des écritures constatées (diff disque
avant/après). Toute écriture non annoncée = échec. Idempotence : deux installs successives →
dry-run de la seconde vide (ou « aucun changement »).

**Warning signs:**
Une fonction `plan_install()` distincte de `do_install()` dans le diff. Un dry-run qui ne sait pas
annoncer les merges `settings.json` (le cas le plus dur — et celui qui motive la demande).

**Phase to address:** Phase manifeste/update (#20) — le test dry-run↔réel est le critère de succès
central, pas un test parmi d'autres.

---

### Pitfall 7 : Durcir le driver-lock en montant le TTL — ou en bloquant l'humain

**What goes wrong:**
Deux sur-corrections symétriques. (1) Le TTL 1800 s a déjà mordu (un mandat de worker dure plus —
constat 2026-08-02, Phase 23) : la réponse réflexe est de monter le TTL, ce qui allonge d'autant le
gel des missions quand un manager meurt réellement — le TTL ne peut pas servir à la fois de durée
de mission et de délai de détection de mort. (2) Les deux contournements constatés (commit et
checkout concurrents **sous lock**) poussent vers un enforcement `PreToolUse` sur les commandes
git : mal calibré, il bloque aussi **Samuel** travaillant légitimement dans l'arbre (tension directe
avec ADR-031/advisory, et avec le précédent mémoire « un lock périmé ne veut pas dire mission
morte »).

**Why it happens:**
Le lock actuel est advisory par conception (« un manager qui meurt ne gèle pas les missions ») ; les
contournements viennent d'agents qui ne **consultent** pas le lock, pas d'un TTL trop court. Durcir
la mauvaise variable est naturel parce que le TTL est un nombre et la discipline de consultation
n'en est pas un.

**How to avoid:**
Séparer les trois problèmes : (a) **liveness** → le heartbeat existe déjà, c'est lui qui doit être
rafraîchi pendant les longues missions (côté manager), le TTL reste court ; (b) **enforcement** →
une garde qui détecte commit/checkout sous lock étranger doit être *bloquante pour les agents,
contournable par l'humain* (message + confirmation, pas mur), et fail-open explicite si le lock est
illisible ; (c) **takeover** → le mécanisme génération/`observed_gen` existe (l.210, l.271 de
`driver-lock.sh`) — toute nouvelle écriture de recovery doit repasser par lui, sinon on réintroduit
la course TOCTOU entre `status` et l'opération git qui suit.

**Warning signs:**
Un diff qui change `VF_DRIVER_TTL` par défaut. Une garde git qui n'a pas de chemin « humain
confirme et passe ». Un takeover écrit sans relecture de génération.

**Phase to address:** Phase driver-lock — cadrage : lister les deux contournements réels comme cas
de test AVANT de choisir le mécanisme.

---

### Pitfall 8 : Le heartbeat qui ment — notifier la vie au lieu du progrès

**What goes wrong:**
Le stall silencieux de 18 h ne sera pas résolu par un heartbeat de liveness : un manager coincé dans
une boucle (retry d'un outil, attente d'un sous-agent mort, contexte saturé) **rafraîchit son
heartbeat indéfiniment** tout en ne progressant pas. Symétriquement, une notification par événement
trop fine (chaque task, chaque commit) noie l'utilisateur — et un canal bruyant s'ignore, exactement
comme « un gate rouge pendant des semaines entraîne à ignorer la CI » (spec §7, précédent maison).

**Why it happens:**
La liveness est facile à mesurer (touch d'un fichier), le progrès ne l'est pas. Et le premier
incident pousse à sur-notifier — jusqu'au prochain incident, inverse, où le vrai signal était noyé.

**How to avoid:**
Ancrer la notification sur des **marqueurs de progrès** déjà produits par le team-kernel (rapports
typés, transitions de nœuds `dag.sh`, plans complétés), pas sur la vie du processus : « aucun
marqueur de progrès depuis N minutes ET lock frais » = stall probable → une notification, une seule,
avec escalade temporisée (pas de répétition à chaque tick). Portabilité : le canal doit être
Windows-compatible dès le premier jet (pas d'`osascript` en dur — le milestone est Windows-first) et
le hook émetteur doit respecter le contrat de signaux (un échec de notification ne casse jamais la
session — advisory, ADR-031).

**Warning signs:**
Un design qui dit « heartbeat » sans dire « progrès ». Un test de la feature qui ne contient pas le
cas « manager vivant mais bouclant ». Une commande de notification spécifique macOS.

**Phase to address:** Phase notifications managers — la définition de « progrès » est la décision de
cadrage n°1 ; le mécanisme d'envoi est secondaire.

---

### Pitfall 9 : Le nouveau gate qui fail-open sur entrée imparsable — fabrique à faux-verts

**What goes wrong:**
L'ennemi n°1 documenté du repo. Trois incidents du milestone précédent ont la même racine :
(1) le sanitizer whitelist de `check-dev-bootstrap` (D-04) cassé par un statut STATE.md légitime
(> 80 chars, virgules, tiret cadratin) — gate qui échoue sur du contenu valide ; (2) le squash-merge
qui a tué des tests **épinglés sur des SHA** — les SHA disparaissent, les tests passent à vide ;
(3) le label de milestone périmé resté 3 semaines dans STATE — vérifié existant, jamais vérifié
frais. Les nouveaux gates du milestone (budget d'instructions, survie du ledger, précondition
worktree) parsent tous du contenu vivant (STATE.md, REQUIREMENTS.md, versions installées) : chacun
peut reproduire l'un de ces trois modes.

**Why it happens:**
Un gate a trois issues, pas deux : PASS, FAIL, et **« je n'ai pas pu vérifier »**. Les
implémentations naïves replient la troisième sur l'une des deux premières — fail-open (faux-vert
silencieux) ou fail-closed (faux-rouge qui entraîne à ignorer le gate). Et un gate qui ne tourne que
dans le repo ne voit jamais l'état du parc (leçon #38 : *as-installed testing*).

**How to avoid:**
Doctrine à imposer à tout nouveau gate de ce milestone : (a) troisième issue **distincte et
bruyante** — imparsable ≠ conforme ≠ non-conforme (le contrat portabilité cite déjà le précédent
ESLint exit 2 config ≠ exit 1 findings) ; (b) **discrimination par mutation** (convention du repo,
spec §4) : chaque gate livré avec la mutation qui le fait échouer — un gate jamais vu rouge n'a
jamais rien prouvé ; (c) jamais d'épinglage sur SHA de commit dans un repo squash-mergé — épingler
sur contenu (checksum de bloc, comme le locator) ou sur tags ; (d) si le gate protège le parc, il
doit tourner **as-installed** (le job `lab-frais-arme` existe depuis la Phase 28 — l'étendre, pas le
contourner) ; (e) tout parseur de STATE.md/REQUIREMENTS.md testé contre du contenu réel du repo, pas
contre des fixtures idéalisées (c'est ce qui a manqué à D-04).

**Warning signs:**
Un gate dont la suite de tests n'a aucun cas rouge. Un `|| exit 0` ou un `2>/dev/null` sur le chemin
de parsing. Un gate vert dès sa première exécution sur un périmètre qu'on sait non conforme.

**Phase to address:** Transverse — mais concrètement : phases budget d'instructions, ledger (18
héritée), et ré-armement worktree. À écrire comme critère de succès commun dans le ROADMAP.

---

### Pitfall 10 : La survie du ledger implémentée par régénération — l'outil qui réécrit détruit

**What goes wrong:**
La dérive du ledger d'exigences à la clôture de jalon a été **re-constatée** à la clôture
d'agentique-v1.0 (Phase 18 reportée deux fois). Le piège en l'implémentant : confier la survie à un
outil qui *régénère* le fichier à la clôture. Précédent direct en mémoire : `gsd state
record-session` **réécrit STATE.md et perd le contenu manuel**. Un ledger « sauvé » par
régénération perd exactement ce qu'on voulait faire survivre (annotations, exigences reportées,
traçabilité des renoncements).

**Why it happens:**
Les outils gsd-tools sont des writers, pas des mergers. Et la clôture de milestone est le moment où
plusieurs writers se succèdent (archive, snapshot, nouveau REQUIREMENTS) — chaque maillon peut
écraser le précédent.

**How to avoid:**
La survie se vérifie par **diff, pas par régénération** : un gate de clôture qui compare le ledger
avant/après archivage et exige que chaque exigence non complétée ait une destination explicite
(reportée avec cible, ou renoncée avec trace) — c'est un lecteur, il n'écrit rien. Sonder toute
commande gsd-tools impliquée avec `--help` avant de l'utiliser en réel (règle mémoire existante).
Tester le gate sur le cas réel : rejouer la clôture d'agentique-v1.0 (les snapshots existent dans
`.planning/milestones/`) et vérifier qu'il aurait attrapé la dérive constatée.

**Warning signs:**
Un design de la phase 18 héritée qui contient le mot « régénère ». Un test qui ne rejoue pas une
clôture réelle.

**Phase to address:** Phase 18 héritée (survie du ledger).

---

### Pitfall 11 : Ré-armer `isolation: worktree` sur la foi du repo, pas du parc

**What goes wrong:**
La régression #38 en une phrase : un armement dans le plugin dont la précondition (réglage,
version) **n'était pas distribuée** chez l'utilisateur. Le ré-armement a une précondition dure
explicite — fix releasé dans gsd-core **> 1.10.0** ET **installé**. Deux pièges d'implémentation :
(1) vérifier « le fix est mergé upstream » (issue #3302 close COMPLETED) au lieu de « une release
> 1.10.0 existe ET est la version installée du lab » — close ≠ releasé ≠ installé ; (2) comparer
les versions en bash par comparaison de chaînes : `"1.10.0" > "1.9.0"` est **faux**
lexicographiquement (`"1.1" < "1.9"`) — le gate dirait non-conforme sur la bonne version, ou
l'inverse selon le sens du bug.

**Why it happens:**
Trois états distincts (mergé / releasé / installé) qui se ressemblent, et semver qui ressemble à un
nombre. Le gate de la Phase 28 exige déjà cette preuve — le piège serait de l'affaiblir pour
débloquer le ré-armement.

**How to avoid:**
Le gate compare la version **installée** (sortie réelle de gsd-tools sur la machine/lab cible, via
le job `lab-frais-arme` en as-installed), avec un comparateur semver testé sur les cas piège
(1.9.0 vs 1.10.0, préversions). Le ré-armement et sa précondition voyagent **dans le même
livrable distribué** (leçon #38 : jamais un réglage repo-local comme porteur d'un armement).
Prévoir le chemin dégradé : un lab avec gsd-core ≤ 1.10.0 doit rester fonctionnel sans worktree,
pas cassé.

**Warning signs:**
Un check qui lit `package.json` du repo au lieu d'interroger l'install. Un `[ "$v" \> "1.10.0" ]`
dans un diff. Un armement dans un fichier non distribué par l'engine.

**Phase to address:** Phase ré-armement worktree — le gate Phase 28 existe, la phase le nourrit,
elle ne le contourne pas.

---

### Pitfall 12 : Le skill-installer global et les gaps agency-agents recréent ce qui a été enterré — ou écrasent l'utilisateur

**What goes wrong:**
Deux features « catalogue » avec le même double risque. (1) **Écrasement** : un installeur de skills
en scope global écrit dans `~/.claude/skills/` — territoire de l'utilisateur. Sans manifeste
(Pitfall 5), une désinstallation ou un update peut emporter un skill homonyme écrit par
l'utilisateur ; et deux sources (VF + autre plugin + perso) peuvent se disputer un nom. (2)
**Couche de synonymes** : combler les gaps depuis le catalogue agency-agents en important des agents
en masse recrée exactement la façade enterrée en v2.33.0 (« jamais recréer de couche de
synonymes » — Out of Scope explicite de la charte) et fait exploser les gates existants
(check-agents.sh ADR-044, densité ≤ 250 L ADR-029, check-overlaps).

**Why it happens:**
Un catalogue externe invite au remplissage par volume ; et le scope global est le seul endroit du
produit où l'engine écrit hors d'un lab — les invariants de scope (`VF_SCOPE`, manifeste par scope)
n'y ont jamais été exercés.

**How to avoid:**
Le skill-installer consomme le manifeste de la phase #20 (même mécanique d'ownership, même dry-run)
— ne pas lui inventer un second système de pose. Collision de nom = refus explicite, jamais
d'écrasement silencieux. Pour agency-agents : combler par **gap constaté** (un manque de couverture
nommé, un cas d'usage réel), un agent à la fois, chacun passant les gates existants — pas d'import
de catalogue. Tout agent ajouté qui ne fait que renommer une brique GSD existante est un synonyme :
rejet doctrinal.

**Warning signs:**
Une PR ajoutant plus de 2-3 agents d'un coup. Un installeur global avec sa propre logique de copie
au lieu d'appeler l'engine. Un agent dont la description recouvre une cible GSD déjà routée par
`vibeflow-dev`.

**Phase to address:** Phases skill-installer et agency-agents — à séquencer APRÈS la phase
manifeste (#20), qui leur fournit leur mécanique de pose.

---

## Pièges Windows spécifiques (au-delà de la spec)

Compléments MEDIUM confidence à instruire au plan de la phase Windows II :

| Piège | Détail | Prévention |
|---|---|---|
| **Path mangling MSYS** | Git Bash convertit automatiquement les arguments commençant par `/` en chemins Windows (`/foo` → `C:\Program Files\Git\foo`) — touche les args des hooks exec et les flags type `-m /pattern/` | Tester les hooks exec DANS Git Bash réel ; `MSYS_NO_PATHCONV=1` documenté si nécessaire ; préférer les chemins relatifs ou déjà-Windows dans `args` |
| **Casse insensible** | NTFS (et APFS par défaut !) : deux fichiers ne différant que par la casse = collision au checkout ; un `grep` de gate sensible à la casse peut manquer un chemin réel | Gate CI : détection de collisions de casse (`git ls-files | sort -f | uniq -di`) — tourne partout, protège Windows ET macOS |
| **Noms réservés** | `CON`, `PRN`, `AUX`, `NUL`, `COM1-9`, `LPT1-9` (avec ou sans extension), noms finissant par `.` ou espace : le **clone échoue** sur Windows | Même gate CI que ci-dessus, liste des réservés incluse — surtout pour les fixtures de tests générées |
| **Stub Microsoft Store** | `command -v python3` réussit mais l'exécution **pend** (App Execution Alias) — c'est le cas que la variante B (2 fichiers dev-orchestrator) ne neutralise pas | Couvert par la cascade `vf_python` du contrat — le piège serait d'ajouter un nouveau script avec sa propre résolution ; le gate checksum de Willy est la parade machine |
| **`py -3` lanceur à argument** | `PYBIN="py -3"` casse tous les `"$PYBIN"` quotés — c'est pourquoi `vf_python` est une **fonction** | Édition raisonnée fichier par fichier (spec §3.1), jamais un `sed` global |
| **MAX_PATH 260** | Chemins profonds du cache plugin + noms de dossiers de phase GSD longs (`VFDO-28-preuve-que-...`) peuvent dépasser 260 chars sans long paths activés | Préflight existant (`installer/preflight.sh`) : ajouter un check de profondeur du chemin d'install |

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Livrer les `hooks.json` exec avant le moteur | Lot visible livré vite | Parc avec hooks doublés + modules non désinstallables, sans erreur | **Jamais** (spec §2 : ordre = condition de non-régression) |
| `--dry-run` comme second chemin de code | Implémentation 3× plus simple | Manifeste qui ment ; la revue croisée (demande d'origine) devient dangereuse | Jamais — le test dry-run↔réel est le cœur de la feature |
| Monter `VF_DRIVER_TTL` pour les longues missions | Fin des expirations gênantes | Gel prolongé de toutes les missions à chaque mort réelle de manager | Jamais globalement ; heartbeat rafraîchi côté manager à la place |
| Nettoyage des chemins disparus par diff disque↔catalogue | Pas besoin du manifeste d'abord | Suppression de fichiers utilisateur/tiers — pire que les fichiers périmés | Jamais |
| Gate nouveau sans cas rouge dans sa suite | Suite verte immédiate | Faux-vert structurel — le gate n'a jamais rien prouvé | Jamais (convention mutation du repo) |
| `2>/dev/null \|\| true` sur un parseur de gate | Silence des cas bizarres | Fail-open : l'imparsable devient conforme (incident D-04) | Jamais sur un gate ; OK sur un signal advisory pur |
| Notification par tick de heartbeat | Détection immédiate | Spam → canal ignoré → le vrai stall passe (leçon gate rouge §7) | Jamais ; marqueurs de progrès + escalade temporisée |
| Import en masse du catalogue agency-agents | Couverture rapide des gaps | Couche de synonymes ressuscitée + gates densité/overlap explosés | Jamais (Out of Scope de la charte) |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Contrat portabilité de Willy (PR #29) | Réimplémenter la lib ou re-trancher ses choix côté dev | **Consommer** le contrat ; les questions ouvertes (code de sortie PreToolUse, affectation §3.2) se tranchent AU contrat avant plan |
| Gate de Willy en CI | L'armer bloquant avant que la remédiation soit mergée | Avertissement jusqu'au merge, bascule bloquante **dans le même commit** que le dernier lot (spec §7) |
| `settings.json` utilisateur | Traiter le fichier comme territoire VF | Ownership prouvé entrée par entrée ; sonde de parc « zéro entrée tierce touchée » sur chaque opération |
| gsd-core installé (ré-armement) | Lire la version dans le repo / croire l'issue close | Interroger l'install réelle (as-installed, job `lab-frais-arme`), comparateur semver testé |
| gsd-tools (ledger, state) | Utiliser un writer sans le sonder | `--help` d'abord (règle mémoire : `record-session` est destructif) ; préférer des gates lecteurs |
| Hooks Claude Code (notifications) | Canal spécifique macOS, échec du hook qui casse la session | Canal portable Windows dès v1 ; contrat de signaux respecté (échec = silence, jamais blocage) |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Manifeste relu/réécrit à chaque fichier posé | Install lente sur gros modules, surtout NTFS | Manifeste accumulé en mémoire, écrit une fois par transaction | ~17 modules × dizaines de fichiers, disque Windows |
| Heartbeat + notifications par polling agressif | Charge de fond, réveils de session | Événementiel sur marqueurs de progrès existants (rapports typés, dag.sh) | Missions longues multi-heures |
| Gate de budget d'instructions qui re-tokenise tout le repo à chaque run CI | CI qui rallonge à chaque module ajouté | Mesure incrémentale sur fichiers modifiés + total caché | ~17 modules, croissance continue |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Nettoyage à l'update sans ownership prouvé | Destruction de fichiers utilisateur (perte de données chez des tiers — le parc est public) | Manifeste as-installed comme unique autorité de suppression |
| Chemin absolu bash écrit sans validation | Un `settings.json` project-scope commité peut faire exécuter un binaire arbitraire au co-équipier (le scénario exact que redoutent les élèves de l'issue #20) | Résolution locale à l'install sur chaque machine + `--dry-run` pour la revue croisée avant pose |
| Hooks exec avec args non substitués | `{{VF_SCRIPTS}}` littéral → comportement indéfini selon le shell de fallback | Critère de succès n°4 de la spec : aucun placeholder littéral, testé |
| Takeover de lock sans relecture de génération | Deux managers croyant détenir le lock → écritures croisées dans `.planning/` | Réutiliser `lock_gen`/`observed_gen` existants pour toute nouvelle écriture |

## "Looks Done But Isn't" Checklist

- [ ] **Forme exec :** les hooks marchent sur lab **frais** — vérifier sur un lab **existant mis à jour** (update depuis forme shell → dédup cross-forme, puis remove → zéro résidu)
- [ ] **`--dry-run` :** le manifeste s'affiche — vérifier qu'il égale le diff disque d'une install réelle (écritures ET merges settings.json), et qu'un second run l'annonce vide
- [ ] **Nettoyage update :** les fichiers VF périmés partent — vérifier qu'un fichier utilisateur homonyme et une entrée hook tierce **restent**
- [ ] **Driver-lock durci :** les agents sont bloqués — vérifier que l'humain a un chemin de passage confirmé, et qu'un lock illisible ne bloque pas tout (fail-open explicite et bruyant)
- [ ] **Notifications :** le stall est détecté — vérifier le cas « manager vivant qui boucle » (heartbeat frais, zéro progrès) et le cas « mission longue légitime » (pas de fausse alerte)
- [ ] **Nouveaux gates :** verts en CI — vérifier que chaque gate a été vu **rouge** (mutation) et qu'une entrée imparsable produit une troisième issue distincte, pas un PASS
- [ ] **Ré-armement worktree :** l'issue upstream est close — vérifier release > 1.10.0 **publiée** ET **installée** dans le lab de test as-installed, comparateur semver prouvé sur 1.9/1.10
- [ ] **Windows :** les suites passent en CI Linux/macOS — vérifier au moins un passage terrain Git Bash réel (les testeurs Windows de l'issue #20 se sont proposés) ; la CI ne prouve pas Windows
- [ ] **Skill-installer global :** le skill se pose — vérifier collision de nom (refus, pas écrasement) et désinstallation (le skill perso homonyme survit)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Hooks doublés / module non désinstallable sur le parc | HIGH | Release corrective du moteur + `update` forcé qui déduplique rétroactivement (le moteur doit savoir lire ses propres dégâts) ; communication parc |
| Fichier utilisateur supprimé par le nettoyage | HIGH (confiance) | Pas de recovery technique côté engine — d'où le backup/snapshot avant toute suppression (comme `/vf-calibrate` le fait déjà) : à intégrer au design, pas en option |
| TTL/lock : mission gelée ou double-driver | MEDIUM | `driver-lock.sh status` + recovery par génération (existant) ; documenter le protocole dans team-kernel plutôt que d'improviser en incident |
| Gate faux-vert découvert tard | MEDIUM | Mutation ajoutée immédiatement + audit des runs passés du gate (qu'a-t-il laissé passer ?) — précédent : rattrapage releases v2.29→v2.39 |
| settings.json machine-spécifique synchronisé | MEDIUM | Re-résolution à l'update (l'update répare) + garde préflight qui détecte un chemin bash étranger |

## Pitfall-to-Phase Mapping

Les phases du milestone ne sont pas encore numérotées — mapping par feature :

| Pitfall | Phase (feature) | Vérification que la prévention a marché |
|---------|-----------------|----------------------------------------|
| 1 — exec avant moteur | Windows II | Sonde de parc §4 verte ; ordre encodé en vagues dépendantes du plan |
| 2 — exit 3 sans `\|\| true` | Windows II | Test « session start silencieux » ; inventaire 22 entrées classées advisory/bloquante |
| 3 — chemin bash / trou §3.2 | Windows II (pré-cadrage) | Affectation tranchée par écrit avec Willy avant plan-check |
| 4 — CRLF/checksums | Windows II | Suites vertes sous checkout autocrlf simulé ; mutation du gate checksum |
| 5 — nettoyage destructeur | Manifeste/update (#20) | Test « fichier tiers intact » ; manifeste livré en vague 1 |
| 6 — dry-run divergent | Manifeste/update (#20) | Test dry-run == diff disque réel, sous mutation |
| 7 — TTL/enforcement lock | Driver-lock | Les 2 contournements réels rejoués en tests ; TTL par défaut inchangé |
| 8 — heartbeat qui ment | Notifications managers | Cas « vivant mais bouclant » testé ; canal portable Windows |
| 9 — gate fail-open | Budget instructions + ledger + transverse | Chaque gate vu rouge (mutation) ; 3ᵉ issue « imparsable » distincte |
| 10 — ledger régénéré | Phase 18 héritée | Gate lecteur (diff), rejoué sur la clôture réelle d'agentique-v1.0 |
| 11 — ré-armement sur foi du repo | Ré-armement worktree | Gate Phase 28 nourri (as-installed, semver testé), jamais contourné |
| 12 — synonymes / écrasement global | Skill-installer + agency-agents | Séquencées après #20 ; check-agents/densité/overlaps verts ; refus sur collision |

**Implication d'ordonnancement pour le ROADMAP :** la phase manifeste (#20) est un **fournisseur**
de deux autres (nettoyage update, skill-installer global) — la placer avant. La phase Windows II a
un pré-requis de cadrage externe (affectation §3.2 avec Willy) — la démarrer par ce cadrage, pas par
le code. Le ré-armement worktree est gaté par un événement externe (release gsd-core > 1.10.0
installée) — le planifier en dernier ou conditionnel.

## Sources

- `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md` — §1.3 (irréversibilité moteur), §1.4 (exit 3), §3.2 (trou d'affectation), §4 (mutation), §7 (gate avertissement d'abord) — HIGH
- Issue GitHub #20 (lue via `gh`) — demande terrain dry-run/manifeste, revue croisée Windows — HIGH
- `.planning/MILESTONES.md` — incidents agentique-v1.0 : régression #38, label périmé 3 semaines, contournements driver-lock, phases 18/25 reportées — HIGH
- `.planning/PROJECT.md` — périmètre fiabilite-v1.0, contraintes ADR-029/031/044/054, précondition gsd-core > 1.10.0 — HIGH
- `plugin/conductor/scripts/driver-lock.sh` (lu) — TTL 1800 s par défaut, mécanisme générations, gardes numériques — HIGH
- Mémoire projet : `record-session` destructif, TTL trop court (2026-08-02), armement sans précondition distribuée (#38), ship-note ASCII-safe (incident D-04), doctrine anti-synonymes (v2.33.0) — HIGH
- Précédent install-ux-v1.0 : blocker « faux-négatif dry-run » attrapé au plan-check phase 3 — HIGH
- Connaissances générales Windows/Git Bash (MSYS path mangling, noms réservés, MAX_PATH, casse) — MEDIUM (établies, non re-vérifiées en ligne)

---
*Pitfalls research for: vibeflow-os — milestone fiabilite-v1.0*
*Researched: 2026-08-15*
