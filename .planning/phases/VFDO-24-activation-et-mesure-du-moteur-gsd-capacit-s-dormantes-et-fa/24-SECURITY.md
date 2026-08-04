---
phase: 24
slug: activation-et-mesure-du-moteur-gsd
status: draft
# threats_open = menaces OUVERTES de sévérité >= workflow.security_block_on (« high » sur ce lab).
# Ce nombre est CALCULÉ à partir du registre ci-dessous, jamais posé pour satisfaire un gate.
threats_open: 4
asvs_level: 1
register_authored_at_plan_time: true
created: 2026-08-04
audited: 2026-08-04
---

# Phase 24 — Sécurité

> Contrat de sécurité de la phase : registre de menaces, risques acceptés, piste d'audit.

## Ce que ce document est, et ce qu'il n'est pas

**Il n'unblocke rien, et c'est délibéré.** `/gsd-ship` était bloqué par
`SECURITY_SHIP_GATE_NO_REVIEW` — le gate `security` est actif et bloquant à `ship:pre`
(`.planning/config.json` : `security_enforcement: true`, `security_block_on: "high"`) et aucun
`*-SECURITY.md` n'existait sous `.planning/`. Ce fichier remplace un blocage **sans
information** par un blocage **nommé, chiffré et actionnable**. Il ne pose pas
`threats_open: 0` : ce serait inventer un verdict que personne ne peut produire aujourd'hui.

**Le fait de gouvernance qui gouverne tout le reste.** Les **12 plans** de la phase portent
chacun un modèle de menaces authoré **au moment du plan** (`register_authored_at_plan_time:
true`) — 56 menaces au total. **Aucun des 11 SUMMARY produits n'enregistre de verdict
d'exécution sur ces menaces** (re-vérifié le 2026-08-04 : **0** section `## Threat Flags` dans
les 11, balayage `awk` fichier par fichier). Les mitigations ont été **livrées**, souvent avec
leur test ; leur **vérification** n'avait jamais été **actée**. C'est ce que l'audit du
2026-08-04 a fait, menace par menace.

**Ce que le nœud 24-13 avait lui-même prouvé** figure au registre B, avec sa preuve. Chaque
entrée y renvoie à une **mutation** rejouable, jamais à une relecture.

## Audit du 2026-08-04 — ce qui a changé, et ce qui ne change pas

`/gsd-secure-phase 24` a tourné : 5 instances de `gsd-security-auditor` ont instruit les
**34 menaces ouvertes** du registre A, réparties par groupes de plans, en ASVS L1 avec
approfondissement quand il était bon marché (traçage des sites d'appel, rejeu de suites,
exécution réelle). **27 menaces ont été fermées sur preuve citée** ; **7 restent ouvertes** ;
**1 menace nouvelle** a été découverte et enregistrée au registre C.

Trois principes ont gouverné les verdicts, et expliquent pourquoi le compteur ne tombe pas à 0 :

1. **Une menace ne se ferme que sur une preuve citée dans le code livré.** Aucune fermeture
   n'a été accordée sur la foi d'un SUMMARY ou d'une intention de plan.
2. **Une mitigation qui n'était qu'un geste de processus sans trace durable ne ferme pas** —
   sauf si une trace indépendante et re-vérifiable existe par ailleurs (typiquement le
   `numstat` d'un commit, qui prouve qu'aucune ligne antérieure n'a bougé).
3. **Une mitigation falsifiée par les faits reste ouverte**, même si des contrôles
   compensatoires existent — les inscrire ne relève pas de l'audit mais d'une **décision
   humaine** de re-disposition. C'est le cas de T-24-02-01.

---

## Frontières de confiance

| Frontière | Description | Donnée qui la traverse |
|---|---|---|
| Registre du moteur GSD | `capability-registry.cjs`, résolu par une cascade dont la première branche est **dans le dépôt audité** (`$root/.claude/gsd-core/bin/lib`) | Texte non maîtrisé, LU (jamais `require()`), reflété dans un index **versionné donc publié** |
| `.planning/config.json` du lab | Configuration effective, lue par le gate d'activation | Valeurs de toggles ; sa **localisation** est elle-même une frontière (un lab installé voisine d'autres projets) |
| Canaux de workstream | `--ws` > `GSD_WORKSTREAM` > pointeur de session (`os.tmpdir()`) ou partagé (in-repo) | Nom de compartiment, **réimprimé par deux hooks `SessionStart`** dans le contexte de session |
| **Répertoire de compartiment** `.planning/workstreams/<nom>` | **Frontière découverte le 2026-08-04** : le nom est validé, mais le répertoire qu'il désigne n'est pas confiné — un lien symbolique sort de l'arbre du lab | Contenu de `STATE.md`, injecté verbatim au `SessionStart` (registre C, C1) |
| Corpus documentaire du module | `intent-routing.md`, `docs-flow.md` | Promesses de gestes ; distribué à chaque installation depuis un **dépôt public** |
| Intégration continue | job `gates` de `ci.yml` | Verdicts de gates ; une assertion non opposable y vaut absence de garde |

---

## Registre A — menaces des 12 plans de la phase

Dérivé **mécaniquement** des modèles de menaces des `24-*-PLAN.md` : identifiants, catégories,
sévérités et dispositions sont recopiés, jamais réinterprétés. La colonne `Statut` suit une
règle unique, énoncée ici et appliquée sans exception :

- `closed` — une **preuve citée dans le code livré** a été produite ; elle figure en clair ;
- `open — …` — la preuve n'a pas pu être produite ; le motif est nommé ;
- les menaces de disposition `accept` ne figurent pas ici : elles sont au **journal des risques acceptés**.

| Menace | Catégorie | Composant | Sévérité | Disposition | Statut |
|---|---|---|---|---|---|
| T-24-01-01 | Denial of Service | `check-agents.sh` au `SessionStart` | high | mitigate | closed — le skip `--third-party-prefix` (défaut `gsd-`, `:86`) agit dans la boucle **avant** `check_file` (`:626-632` vs `:633`) ; le bloc `effort` exigeant vit **dans** `check_file` (`:520-524`). Même chemin en hook (`hooks.json:16`). Cas T74 (`test-check-agents.sh:1330-1349`) **rejoué vert**, avec agent local conforme injecté (`:1342`) contre le vert à vide. |
| T-24-01-02 | Tampering | `test-check-agents.sh` (cas de mutation) | medium | mitigate | closed — `cmp -s` compare mutant et original **avant tout verdict** (`test-check-agents.sh:1375-1376`) ; l'égalité déclenche `ko` « mutant NON OPPOSABLE ». Second plancher d'opposabilité `:1365-1366`. T75 **rejoué vert**. |
| T-24-02-01 | Tampering | `.planning/WINDOWS.md` via `gsd-tools windows *` | high | mitigate | open — **mitigation FALSIFIÉE.** Elle promettait une interdiction écrite **et** l'abstinence. (1) ADR-066 (`docs/ADR.md:1565-1651`) ne porte **aucune** formulation d'interdiction (0 occurrence de `interdi\|jamais invoqu\|proscri\|banni`) et **acte** l'exécution (`:1597`) ; `CONCERNS.md:92-94` formule une précaution, pas une interdiction. (2) La commande **a été invoquée** : commit `7b96e34`, `.planning/WINDOWS.md:3-4` (`waived_count: 1`), entrée id 3 `"status": "waived"` (`:57`). L'abstinence a été **levée par décision humaine** (dégel, ADR-066) sans entrée au journal des risques acceptés. Re-disposition = acte humain, pas verdict d'audit. |
| T-24-02-02 | Repudiation | ADR-066 / ADR-067 | medium | mitigate | open — **promesse non tenue.** La mitigation exigeait que **chaque fait** porte sa source de première main (fichier + lignes, ou date npm ISO). Balayage `awk` du motif `:[0-9]+` sur ADR-066 (`:1565-1651`) et ADR-067 (`:1655-1715`) : **0 citation fichier+lignes**. L'horodatage npm ISO exigé est absent (seule la date courte `:1581`). Le fait le plus porteur (mécanisme de destruction #2893, `:1574-1576`) ne nomme que deux symboles, sans fichier ni ligne. Partiellement conforme : la contre-épreuve `:1617-1624` et le corpus nommé d'ADR-067 `:1671-1678` sont, eux, opposables. |
| T-24-03-01 | Tampering | `.planning/config.json` | high | mitigate | closed — édition exactement bornée : commit `0aa88fa`, 1 fichier, 6 insertions / 1 suppression, uniquement le bloc `agent_skills` (`.planning/config.json:51-56`). Contrôles négatifs **rejoués** : `jq -e` échoue sur les 7 clés refusées. Les 2 clés zone 2 présentes (`:27`, `:45`) ont été posées par le plan **24-02** (`b3cb402`) sous ADR-066 ; le contrôle a été inversé en place et daté (`24-03-PLAN.md:88-93`, `:104`). |
| T-24-03-02 | Elevation of Privilege | injection de skill dans un agent du moteur | medium | mitigate | closed — un seul slot (`config.json:51-56`, `jq -e '.agent_skills\|keys\|length==1'` vrai) ; deux skills **du dépôt lui-même**, byte-identiques (`cmp -s`) aux copies résolues ; aucune entrée tierce. Forme de résolution validée contre le moteur : `init.cjs:1765` (préfixe `global:`), `:1773` (regex de nom), `:1801` (`validatePath`, refus d'échappement par lien symbolique), `:1815`. |
| T-24-03-03 | Denial of Service | prompt de `gsd-planner` saturé | medium | mitigate | open — **ni consigné, ni gardé.** La borne **tient en fait** (92 + 177 = 269 lignes injectées, mesure `awk`), mais (i) aucun artefact livré ne consigne le relevé exigé par `24-03-PLAN.md:65` ; (ii) le plafond ADR-029 n'est machine-enforcé sur **aucun** des deux modules — `test-dev-orchestrator.sh:1052` borne T5 à `"$MOD"/skills/vf-*/SKILL.md`, or les deux `SKILL.md` sont à la racine de modules autonomes, sans préfixe `vf-`. Le volume injecté peut croître au-delà de 500 lignes sans qu'aucun gate ne rougisse. |
| T-24-04-01 | Tampering | résolution de nom de workstream → chemin | high | mitigate | closed — `workstream-policy.sh:115-134` (`vf_ws_name_valid` : séparateurs / `.` / `..` rejetés `:120-122`, ancre alphanumérique `:126-129`, classe `:130-132`) s'exécute **avant** toute affectation de `VF_WS_NAME` (`:199-220`). Concaténation seulement ensuite : `check-dev-bootstrap.sh:133-136`, `check-state-integrity.sh:144-151`, `planning-context.sh:145-149`. Valeur brute jamais réimprimée. Cas dédiés `test-check-dev-bootstrap.sh:295,311,325` (27b exerce `../workstreams/dev`, traversée qui **résout réellement**). |
| T-24-04-02 | Information Disclosure | injection du `STATE.md` d'un workstream | medium | mitigate | closed — liste blanche `^[0-9A-Za-z._ /-]{1,80}$` (`check-dev-bootstrap.sh:204-215`) appliquée `:225-227` dans `state3_signal`, dont l'**unique** site d'appel est `:286` — racine et compartiment partagent un seul chemin, la liste blanche est inévitable. `planning-context.sh:168` est le **seul** site d'extraction pour les deux provenances ; `MAX_LINES` validé entier ≥ 1 `:76-79`. |
| T-24-04-03 | Denial of Service | `check-state-integrity.sh` en CI | high | mitigate | closed — plus fort que prévu : la résolution n'est armée que si `.planning/workstreams` existe **et** que `--file` n'est pas explicite (`:134`) ; la CI passe `--file` explicitement (`ci.yml:329`, justification `:323-328`). **Mesuré sur ce checkout** : invocation nue → 0, forme CI → 0, forme CI + `GSD_WORKSTREAM=fantome` → 0, nue + `GSD_WORKSTREAM=fantome` → 0. Non-régression `test-check-state-integrity.sh:300` et `:410`. |
| T-24-05-01 | Tampering | nom de workstream → chemin | high | mitigate | closed — `check-workstream-pointer.sh:149` résout, `:150-163` refuse par **énumération fermée** de raisons → exit 2, valeur jamais réimprimée ; `WS_DIR="$WS_ROOT/$WS_NAME"` (`:173`) n'est atteint qu'après `:168`. Cas 6, 6b, **6c** (`.`, `..`, `.hidden`, `-x`, `a..b`, `_lead` — l'angle mort exact de l'ancienne copie locale), 6c-bis, 6e (pointeur en lien symbolique), 6f (borne de longueur). |
| T-24-05-02 | Denial of Service | hook `SessionStart` | high | mitigate | closed — `hooks.json:16-20` : 5 commandes `SessionStart`, **toutes** suffixées `\|\| true`. Filtre `jq` **rejoué indépendamment** : 5 commandes, **0** sans `\|\| true`, exactement 1 citant `check-workstream-pointer`. Silence total + exit 3 sur lab non partitionné (`:86`, `:118-121`, cas 1 et 1b sur stdout *et* stderr ; `ci.yml:563-566`). ⚠ **Garde de durabilité absente** — voir dette. |
| T-24-05-03 | Information Disclosure | message de l'état 4 | low | mitigate | closed — Re-prouvée : `workstreams.md` ne publie plus la valeur résolue du port, seulement sa forme (B11). |
| T-24-05-04 | Tampering | le pointeur lui-même | medium | mitigate | closed — balayage `awk` du gate (183 lignes, commentaires exclus) pour `rm`/`mv`/`touch`/`mkdir`/`cp`/`tee`/`truncate`/`ln`/`sed -i`/redirection vers un chemin variable : **0 occurrence** ; idem sur la politique sourcée. Preuve comportementale persistée : cas 10 (`test-check-workstream-pointer.sh:236-245`) compare une empreinte `find` avant/après par `cmp -s`, y compris sur un nom irrésolvable. |
| T-24-06-01 | Elevation of Privilege | `build-gsd-capabilities-index.sh` → registre | high | mitigate | closed — Re-prouvée : confinement de chemin ajouté (l'échappement par lien symbolique restait ouvert) — T28-M, mutation dans les deux sens. |
| T-24-06-02 | Tampering | `gsd-capabilities-index.md` | high | mitigate | closed — Re-prouvée : le recompte croisé du générateur est CONFRONTÉ sur 5 compteurs, un désaccord tue le script. |
| T-24-06-03 | Information Disclosure | contenu injecté depuis `.planning/intel/` | medium | mitigate | closed — `docs-flow.md:73-97` livré. Moitié **amont** vérifiée indépendamment, pas sur la foi du document : `gsd-intel-updater.md:39` (« Write current state only. No temporal language ») et `plan-phase.md:766` (« MAY BE INCOMPLETE — a symbol's absence means *unknown* »). Moitié in-repo `:92-97` : « jamais cité comme preuve dans une décision, un arbitrage ou un rapport d'audit ». |
| T-24-06-04 | Denial of Service | canari de forme du moteur en CI | high | mitigate | closed — `ci.yml:109` (étape) + `:157-203` (sous-canari du générateur) ; rc=0 asserté `:184-187`, plancher `plan:pre` `:192-196`, détection `EXTRACTION PERIMEE` `:188-191`, `set -eu` `:111`, `exit 1` `:201`. **Non neutralisé** : 0 `\|\| true` en 109-204, 0 `continue-on-error` dans tout le fichier, aucun `if:` sur l'étape. **Rejoué** sur copie jetable : rc=0, index produit de 221 lignes contenant `plan:pre`. |
| T-24-07-01 | Repudiation | ADR-068, volet profils | high | mitigate | closed — les trois contrôles machine **rejoués** sur un intervalle non vide de 204 lignes (`docs/ADR.md:1717-1920`) : (1) `context_profile` = 6 occurrences, porteuse `:1748` ; (2) `dépréci*` = 0, y compris passe insensible à la casse et aux accents ; (3) déclencheur `:1811-1820` (11 lignes, non vide) = 0 date ISO, 0 nom de mois, 0 année nue. Ligne d'index unique `:39`. |
| T-24-07-02 | Tampering | mesure du seuil | medium | mitigate | closed — **durablement présente**, pas seulement alléguée : la regex est gravée `docs/ADR.md:1840` et correspond octet à octet à celle du moteur (`execute-plan.md:93`) ; la commande reproductible est consignée `:1847-1851` ; le `grep` piped est proscrit `:1844`. **Commande rejouée verbatim** → distribution identique à la table publiée `:1872` (0→4, 2→8, 3→28, 4→2, 6→2 ; total 44). |
| T-24-07-03 | Tampering | entrées ADR-066 / ADR-067 | medium | mitigate | closed — la mitigation déclarée était un geste de processus, mais une **trace durable et indépendante existe en git** : commit `71fea4f` = `210 0 docs/ADR.md` (210 insertions, **0 suppression**, un seul fichier) — modifier une ligne antérieure produirait nécessairement une suppression. Confirmé par extraction des intervalles à `71fea4f^` vs `71fea4f` : ADR-066 (90 lignes, non vide) `cmp -s` **identique** ; substance d'ADR-067 (59 lignes) **identique**. |
| T-24-08-01 | Tampering | écriture sur le mauvais compartiment de planning | high | mitigate | closed — `vf-dev-manager.md:33-34` (« résous le compartiment AVANT toute lecture, exporte `GSD_WORKSTREAM`, passe `--ws` ») posé **dans** la section « Sources de connaissance (à lire au démarrage) », attaché à la puce feuille de route/état `:31-32` — bonne frontière. Geste worker `vf-coder.md:42-50` ; règle du lab `workstreams.md:59-63` ; gate bruyant `check-workstream-pointer.sh:167-171` ; câblé `hooks.json:20` et `ci.yml:451, 485, 563`. ⚠ **L'ordonnancement « AVANT » n'est gardé par aucune suite** — voir dette. |
| T-24-08-02 | Denial of Service | suite du module (job `tests`) — *pas* `check-agents.sh` | high | mitigate | closed — `vf-dev-manager.md` = **248 lignes** (`awk 'END{print NR}'`), ≤ 250. Plafond **machine-enforcé durablement** par `test-dev-orchestrator.sh:6180-6201` (T35 d/e, avec mutant allongé prouvant la discriminance) et `:5906-5913`, suite lancée en CI (`ci.yml:205-232`). Soupape livrée : `workstreams.md` (166 lignes, non plafonnée). ⚠ **Composant du registre d'origine corrigé ici** : `check-agents.sh` (661 lignes) contient 0 occurrence de `250`/`MAX_LINES`/`ADR-029` et aucune logique de comptage — la borne est tenue par la suite du module dans le job `tests`, jamais par le job `gates`. La substance de la mitigation tient ; seule l'attribution était fausse. |
| T-24-08-03 | Repudiation | commits de feuille de route perdus en PR | high | mitigate | closed — `workstreams.md:138-143` porte le risque (b) avec sa source exacte (`pr-branch.md:235-236`) et `:144-145` le **geste** : « avant d'ouvrir une PR depuis un compartiment, liste explicitement les commits de feuille de route attendus et vérifie qu'ils y figurent ». Texte promis = texte livré, ce que la mitigation promettait. ⚠ **Aucun exécutable n'asserte ce contenu** — voir dette. |
| T-24-09-01 | Repudiation | vert par absence de cible | high | mitigate | closed — Re-prouvée : l'assertion R1 comparait deux chaînes VIDES ; plancher d'opposabilité ajouté (B4). |
| T-24-09-02 | Denial of Service | job `gates` de la CI | high | mitigate | closed — `ci.yml` balayé **en entier** par `awk` (621 lignes) : `\|\| true` aux seules lignes 44, 88, 108 et 576 (commentaires) et `:209` (job `tests`, sur `grep -c .`, immédiatement gardé par `count -eq 0 → exit 1`). Dans le job `gates` (L234-588) : **aucune occurrence exécutable**. `continue-on-error` : **0** dans tout le fichier. Chaque gate capture son code (`\|\| rc=$?`) puis l'oppose à un littéral (`:415/417`, `:428/430`, `:439/441`, `:451/453`, `:468-472`, `:483-487`, `:542-549`, `:562-565`, `:570-573`). |
| T-24-09-03 | Information Disclosure | fixture temporaire | low | mitigate | closed — valeurs synthétiques uniquement (`ci.yml:366-384` : `{ "workflow": {} }`, `milestone: fixture` ; identité git `ci@vibeflow.invalid` `:391`). Suppression **doublée** : `trap 'rm -rf "$FIX"' EXIT` `:363` (couvre les sorties anticipées `:399`, `:408`) + `rm -rf "$FIX"` explicite `:501`. |
| T-24-09-04 | Tampering | étape `check-state-integrity` existante | medium | mitigate | closed — **une seule** étape (`- name:` `:322`, `run:` `:329`). **Bit-à-bit inchangée** : bloc 322-330 extrait à `d29602b^` et comparé octet à octet avec HEAD → identiques, les **deux** blocs non vides (9 lignes / 742 octets — garde contre le faux « identique » sur intervalle vide). Les autres occurrences vivent dans l'étape neuve et visent la fixture. |
| T-24-10-01 | Elevation of Privilege | révision de l'Iron Law 2 | high | mitigate | closed — `plugin/conductor/AGENT.md:115` (item 2 réécrit, renvoi `(ADR-069)`), bloc « Trace de révision » `:119-127` dont `:121` porte la formulation antérieure **verbatim** ; items 1/3/4 à `:114`, `:116`, `:117` ; `## Garde-fous` `:101-108`. Bornage **re-vérifiable** : `git show d42ebd2 -- plugin/conductor/AGENT.md` = **1 seul hunk** débutant à `## Iron Laws`, 11 insertions / 1 suppression, l'unique suppression étant l'ancien item 2 ; `Garde-fous` hors hunk. `d42ebd2` est le **dernier** commit touchant ce chemin. |
| T-24-10-02 | Repudiation | ADR-069 sans ses limites | high | mitigate | closed — `docs/ADR.md:1921` (titre), en-tête daté `:2020`, **quatre** paires constat/mitigation : (a) `:2024`→`:2033`, (b) `:2038`→`:2046`, (c) `:2049`→`:2068`, (d) `:2077`→`:2083` ; condition dure en clair `:2089` (« Aucune partition tant qu'une phase est en vol »), qualifiée `:2091` (« pas une précaution, une interdiction ») ; ligne d'index = 1 ; 5 occurrences de `2026-08-04`. |
| T-24-10-03 | Information Disclosure | remontée amont | medium | mitigate | closed — bandeau `.planning/upstream/2026-08-04-workflows-aveugles-aux-workstreams.md:3-4` (« réservé à validation humaine (ADR-031) : aucun agent ne l'ouvre en issue, aucun appel d'API de forge n'est exécuté ») ; critère `24-10-PLAN.md:278` ; balayage `awk` des 178 lignes pour `gh issue`/`gh api`/`curl`/`api.github`/`POST` → **0** ; commit `1fe5317` = 1 fichier markdown, aucun exécutable livré. **Réserve honnête** : la *non-exécution* d'une commande est un contrôle de processus sans trace ; ce qui est machine-vérifiable, c'est l'absence de tout mécanisme de publication dans les livrables. |
| T-24-10-04 | Tampering | `.planning/ROADMAP.md` | medium | mitigate | closed — `awk '/^#{3,4} Phase [0-9]/'` → **26** en-têtes (**13** `### Phase` + **13** `#### Phase` : le piège des deux profondeurs est confirmé et évité). Hors périmètre du plan (`24-10-PLAN.md:7-10`) et **aucun** des 4 commits (`d42ebd2`, `8b6cfce`, `1fe5317`, `1031e7d`) ne touche le fichier (numstat vérifié un à un). |
| T-24-11-01 | Repudiation | gate vert à vide | high | mitigate | closed — Re-prouvée : plancher élargi (index sans table de briques ⇒ 2) — cas 5bis. |
| T-24-11-02 | Tampering | dérive inverse (marqueur périmé) | high | mitigate | closed — Re-prouvée : MUT2 vérifie la RAISON du rouge (règle 3 + PERIME), plus seulement le rc. |
| T-24-11-03 | Denial of Service | job `tests` de la CI | high | mitigate | closed — preuve **plus forte que la comparaison d'ensembles déclarée** : `git show --numstat b14a040` = `254 0` sur `test-dev-orchestrator.sh`, soit **0 suppression** — aucune ligne préexistante retirée ni modifiée. Fixtures synthétiques et temporaires (`mktemp -d` + `rm -rf`, `trap … EXIT` à `test-check-capability-activation.sh:41-42`). Contre-épreuve exécutée : suite → **exit 0, 184 OK / 0 KO**, arbre inchangé après le run. |
| T-24-11-04 | Tampering | extraction par `grep` piped | medium | mitigate | closed — `check-capability-activation.sh:265` : un **seul** `awk -F'\|'` produit les deux ensembles (T depuis l'index `:318-351`, repérage par section et non par arité ; M depuis le corpus `:355-369`). Balayage des 443 lignes : **3 lignes seulement contiennent `grep`** (`:27`, `:162`, `:163`) — **toutes des commentaires d'interdiction** ; **0 `grep` exécuté**. Suite dédiée 29/29. |
| T-24-12-01 | Denial of Service | job `gates` de la CI | high | mitigate | open — **plan 24-12 EN VOL** (voir la note ci-dessous). |
| T-24-12-02 | Repudiation | CHANGELOG décrivant l'intention | medium | mitigate | open — **plan 24-12 EN VOL.** |
| T-24-12-03 | Elevation of Privilege | franchissement de la frontière de release | high | mitigate | open — **plan 24-12 EN VOL.** |
| T-24-12-04 | Tampering | modules hors périmètre bumpés | medium | mitigate | open — **plan 24-12 EN VOL.** |

### Pourquoi les quatre menaces de 24-12 ne sont pas adjudicables aujourd'hui

Le plan `24-12` n'a pas de `SUMMARY`, et il est **en cours d'exécution par un autre worker au
moment de cet audit** (commit `2b95db2` « bump mineur des 3 modules qui gagnent une capacité »,
21 fichiers `VERSION` / `module.json` / `CHANGELOG.md` modifiés dans l'arbre de travail). Ses
menaces portent précisément sur l'**état final** de ces fichiers : triades de version
cohérentes, frontière de release non franchie, modules hors périmètre non bumpés.

Un verdict rendu maintenant porterait sur une **cible mouvante** — il serait faux avant d'être
écrit. L'observation instantanée (racine `VERSION`, `plugin.json` et `marketplace.json` absents
du statut git ; 7 `VERSION` de modules modifiés) est *conforme* à ce que promettent T-24-12-03
et T-24-12-04, mais une observation instantanée sur un travail en vol n'est pas une preuve, et
la transformer en fermeture serait exactement le verdict inventé que ce document refuse depuis
sa première version. **Ces quatre menaces se ferment par `/gsd-secure-phase 24` rejoué après la
clôture du plan 24-12**, pas autrement.

---

## Registre B — menaces instruites par la revue de jointure et l'audit (nœud 24-13)

Chaque entrée est **fermée par une mutation**, jamais par une relecture : la garde est retirée,
le défaut doit réapparaître ; la garde est remise, il doit disparaître. Sans ce second sens, un
vert ne prouve que l'absence de symptôme aujourd'hui.

| Menace | Catégorie | Composant | Sévérité | Disposition | Statut | Preuve |
|---|---|---|---|---|---|---|
| T-24-13-B1 | Repudiation | `check-capability-activation.sh` règle 2 | high | mitigate | closed | Mutation de la revue rejouée : gate VERT avant, `rc=1` après en nommant `intent-routing.md:104`. Cas 2bis + MUT1 (suite du gate, 29/29). |
| T-24-13-B2 | Information Disclosure | résolution de la racine du lab | high | mitigate | closed | Cas 14 (disposition de lab installé + projet voisin) et sa contre-épreuve 14b : la config du voisin rougit, celle du lab est verte. T14d (e) exerce la cascade nue. |
| T-24-13-B3 | Denial of Service | `VF_CAPACT_CORPUS` — découpage du corpus | high | mitigate | closed | Cas 12 (chemin à espace → 0) et cas 13 (motif = NOM de fichier, donc illisible, donc 2 — aucun fichier aspiré). |
| T-24-13-B4 | Repudiation | `ci.yml` — assertion d'invariance R1 | high | mitigate | closed | Mutation : SUT fuyant → ancienne assertion VERTE, nouvelle ROUGE ; SUT invariant → verte ; SUT muet → refusée comme non opposable. |
| T-24-13-B5 | Tampering | `occ()` — comparaison de noms | medium | mitigate | closed | Cas 11 : la clé longue citée ne déclenche plus la courte. |
| T-24-13-B6 | Repudiation | câblage du gate d'activation | high | mitigate | closed | Étape `check-capability-activation` ajoutée à `ci.yml` à côté de `check-state-integrity` ; exit 2 y échoue au même titre qu'un exit 1. |
| T-24-13-B7 | Repudiation | `governingKey` — fabrication de toggles | medium | mitigate | closed | Univers servi : 29 toggles avant, 23 après — les 6 `review.models.*` ne sont plus des toggles. |
| T-24-13-B8 | Elevation of Privilege | `build-gsd-capabilities-index.sh` → registre du moteur | high | mitigate | closed | T28-M, dans les deux sens : garde en place → refus, cible intacte, message nommant l'ancre ; garde retirée → le jeton `fx-EXFILTRE` hors dépôt réapparaît dans l'index produit. |
| T-24-13-B9 | Denial of Service | `GSD_WORKSTREAM` — canal nominal | high | mitigate | closed | A5d : 200 000 octets refusés POUR LA TAILLE (raison distincte de `hors-politique`), la même forme en 4 octets acceptée. Mutation (borne neutralisée) : `rc=0`, nom rendu de 200 000 octets. |
| T-24-13-B11 | Information Disclosure | `references/workstreams.md` — dépôt PUBLIC | low | mitigate | closed | Remplacé par `claude-code-sse-port-<port>`. Aucune autre valeur machine ne subsiste dans la référence. |

**Menace de ce registre restée OUVERTE : aucune.**

---

## Registre C — menaces découvertes par l'audit du 2026-08-04

Le contrat de `gsd-security-auditor` classe une surface nouvelle sans mitigation déclarée en
`unregistered_flag` **non bloquant** — au motif qu'aucune mitigation déclarée n'y manque. Ce
document **enregistre quand même C1 comme menace ouverte et la compte**, pour une raison qui
tient en une phrase : *le gate de sécurité existe pour empêcher de livrer une exposition, pas
pour récompenser une taxonomie*. Une fuite **reproduite** ne cesse pas d'en être une parce
qu'elle n'était pas prévue au registre d'origine. Le choix est inscrit ici pour qu'un humain
puisse le renverser **en connaissance de cause**, jamais par inadvertance.

| Menace | Catégorie | Composant | Sévérité | Disposition | Statut |
|---|---|---|---|---|---|
| T-24-14-C1 | Information Disclosure | répertoire de compartiment `.planning/workstreams/<nom>` | high | mitigate | open — **REPRODUITE, non mitigée.** La validation de nom ferme la traversée `..` et le trou du pointeur-**fichier** en lien symbolique (`workstream-policy.sh:153-156`), mais **rien ne contraint le répertoire de compartiment lui-même**. Avec `.planning/workstreams/dev` en lien symbolique vers un répertoire **hors du lab**, `[ -d ]` le suit et `planning-context.sh:168` injecte le `STATE.md` de la cible **verbatim dans le contexte de session**. Reproduit sur fixture jetable : à **exit 0**, sous l'en-tête `STATE.md du workstream dev`, une ligne sentinelle lue hors de l'arbre du lab. Même portée pour `check-dev-bootstrap.sh:286` (réduite à 3 valeurs ≤ 80 caractères par la liste blanche) et `check-state-integrity.sh:145`. Préconditions **identiques** à celles du trou pointeur que cette phase a jugé réel et fermé (`test-check-workstream-pointer.sh:191-198`) : une entrée mode 120000 committée sous `.planning/`, puis n'importe quelle ouverture de session. Mitigation attendue : contrôle de confinement sur le chemin **résolu** du compartiment — le motif T28-M déjà employé dans `build-gsd-capabilities-index.sh`. |

**C1 est le quatrième passage du motif d'échappement par lien symbolique dans ce dépôt.** Voir
l'analyse transverse en fin de document.

---

## Journal des risques acceptés

| Risque | Menace | Justification | Accepté par | Date |
|---|---|---|---|---|
| R-24-01-03 | T-24-01-03 | La section n'ajoute qu'un descripteur public du runtime, déjà lisible dans le paquet amont installé. | plan 24-01 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-01-SC | T-24-01-SC | Ce plan n'exécute **aucune** installation de paquet — la chaîne d'approvisionnement n'est pas franchie ici. | plan 24-01 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-02-03 | T-24-02-03 | La mesure est re-jouée à l'exécution contre le registre officiel ; un registre miroir hostile n'est pas dans le modèle de menace de ce dépôt. | plan 24-02 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-02-SC | T-24-02-SC | Ce plan **n'installe rien** — la seule interaction npm est une lecture (`npm view`) ; aucune exécution de paquet. | plan 24-02 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-03-SC | T-24-03-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-03 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-04-04 | T-24-04-04 | Le fichier vit dans le dépôt versionné ; qui peut l'écrire peut déjà écrire les scripts eux-mêmes. | plan 24-04 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-04-SC | T-24-04-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-04 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-05-SC | T-24-05-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-05 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-06-SC | T-24-06-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-06 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-07-SC | T-24-07-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-07 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-08-04 | T-24-08-04 | La référence décrit la forme d'un chemin temporaire, jamais sa valeur résolue sur la machine. | plan 24-08 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-08-SC | T-24-08-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-08 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-09-SC | T-24-09-SC | Cette installation préexiste au plan et n'est pas modifiée ici ; elle vit dans le job `tests`, pas dans le job `gates` que ce plan étend. Le plafond `^1` (décision humaine pour tout saut de majeure) reste intact. | plan 24-09 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-10-SC | T-24-10-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-10 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-11-SC | T-24-11-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-11 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-12-SC | T-24-12-SC | Ce plan n'exécute aucune installation de paquet ; celle du job `tests` de la CI est antérieure à la phase et n'est pas modifiée. | plan 24-12 (auteur du modèle de menaces) | 2026-08-04 |

*Les risques acceptés ne comptent pas dans `threats_open` et ne resurgissent pas dans les
audits suivants. Les 12 entrées `-SC` sont la même menace de chaîne d'approvisionnement,
réinstruite plan par plan : aucun de ces plans n'installe quoi que ce soit, la seule
installation de la phase est le `npx -y "@opengsd/gsd-core@^1"` du job `tests`.*

> **Aucune entrée n'a été ajoutée à ce journal par l'audit du 2026-08-04.** Accepter un risque
> est un acte d'autorité humaine — la colonne « Accepté par » n'a de sens que remplie par
> quelqu'un qui engage sa responsabilité. Un agent qui s'y inscrirait lui-même viderait la
> colonne de son contenu. C'est pourquoi T-24-02-01 reste **ouverte** plutôt que d'être
> re-disposée en `accept` : la matière de la décision est réunie plus bas, la décision
> appartient à l'humain.

---

## Piste d'audit

| Date | Menaces totales | Fermées | Ouvertes | Exécuté par |
|---|---|---|---|---|
| 2026-08-04 | 66 (56 plans + 10 nœud 24-13) | 16 | 34 dont **18 de sévérité >= high** | nœud de correction 24-13 (`vf-coder`), sur la matière de la revue de jointure et de l'audit des vagues 2-3 |
| 2026-08-04 | 67 (56 plans + 10 nœud 24-13 + 1 découverte C1) | 43 | 8 dont **4 de sévérité >= high** | `/gsd-secure-phase 24` — 5 `gsd-security-auditor` en parallèle sur les 12 plans, ASVS L1 |

### Méthode de calcul de `threats_open`

`threats_open` = nombre de lignes de menace, **tous registres confondus**, dont le `Statut`
commence par `open` **et** dont la `Sévérité` est `high` ou `critical` (seuil
`workflow.security_block_on: "high"`). Le compte est produit par un extracteur `awk` qui lit le
fichier directement — **jamais par un décompte issu d'un pipe** : le `grep` proxifié de ce
runtime tronque silencieusement (mesuré : 31 lignes rendues sur 102, et 1 sur 91). Tout statut
non reconnu est compté comme bloquant (`fail-closed`), jamais ignoré.

Décompte du 2026-08-04, après audit :

- **4 bloquantes** : `T-24-02-01` (mitigation falsifiée), `T-24-12-01` et `T-24-12-03` (plan en
  vol), `T-24-14-C1` (fuite reproduite).
- 4 non bloquantes : `T-24-02-02`, `T-24-03-03`, `T-24-12-02`, `T-24-12-04`.

**Verdict de l'audit des vagues 2-3, désormais recoupé.** Il rapportait « 29 menaces instruites,
28 fermées » sans correspondance transmise. Le recoupement demandé est fait : ce passage a
instruit les **34 ouvertes** du registre A et en a fermé **27**. Les fermetures de l'audit
antérieur correspondent aux 6 lignes déjà `closed` du registre A et aux 10 du registre B —
aucune ligne n'a été fermée deux fois, aucune n'a été fermée sur la foi de l'autre.

---

## Ce qu'il reste à faire pour que le gate de ship passe

1. **T-24-02-01 — décision humaine requise.** La mitigation déclarée (« abstinence + interdiction
   écrite ») est falsifiée : `gsd-tools windows waive 3` **a été exécutée**, sous dégel explicite
   (ADR-066). Les contrôles compensatoires réellement en place sont sérieux et constatés :
   répétition préalable sur copie jetable via `--cwd` (`docs/ADR.md:1609-1611`), post-conditions
   vérifiées (87 lignes avant/après, fence JSON unique, miroir à 5 entrées dont 4 `fixed`
   intactes, `:1611-1615`), risque résiduel acté (`:1633-1639`), précaution maintenue au ledger
   (`CONCERNS.md:92-94`), et **aucun script du dépôt n'invoque ces commandes**. Deux sorties
   possibles, toutes deux humaines : **(a)** re-disposer en `accept` avec entrée nominative au
   journal ci-dessus (justification ADR-066 + les quatre contrôles) ; **(b)** réécrire la
   mitigation autour des contrôles réellement en place. Puis rejouer `/gsd-secure-phase 24`.
2. **T-24-14-C1 — corriger ou accepter.** Confinement du chemin résolu du compartiment (motif
   T28-M), ou acceptation motivée au journal. C'est la seule des quatre bloquantes qui décrit
   une **exposition technique** plutôt qu'une question de gouvernance.
3. **T-24-12-01 et T-24-12-03 — attendre la clôture du plan 24-12**, puis rejouer
   `/gsd-secure-phase 24`. Rien d'autre ne les fermera honnêtement.

---

## Le motif d'échappement par lien symbolique — quatrième passage, et ce qu'il révèle

Ce dépôt a fermé ce motif **quatre fois, à quatre endroits, sans jamais le fermer une fois pour
toutes** :

| # | Où | Quand | Idiome employé |
|---|---|---|---|
| 1 | deux scripts de la Phase 23 | Phase 23 | (local) |
| 2 | `check-workstream-pointer.sh` (pointeur-fichier) | vague 1 | refus `[ -L ]` |
| 3 | `build-gsd-capabilities-index.sh` (registre du moteur) | vague 2 | `vf_realpath` (node) + comparaison de préfixe |
| 4 | `planning-context.sh` / `check-state-integrity.sh` (répertoire de compartiment) | **découvert ici, NON fermé** | aucun |

Le commentaire du passage #3 le dit lui-même : « *C'est le troisième passage de ce motif dans ce
dépôt ; il se ferme ici* » (`build-gsd-capabilities-index.sh:166`). Il s'est fermé **là**, et le
motif est réapparu ailleurs. Un motif qui revient quatre fois n'est pas quatre bugs.

**Pourquoi il repasse — le diagnostic, mesuré.**

1. **Il n'existe aucune primitive partagée de confinement de chemin.** Six implémentations
   distinctes du même besoin coexistent, dans **trois langages** : `[ -L ]` en shell
   (`workstream-policy.sh:153`), `vf_realpath` en node
   (`build-gsd-capabilities-index.sh:174-176`), `os.path.realpath` + préfixe en python
   (`guard-agent-write.sh:78`), `pwd -P` en sous-shell (`check-branch-claim.sh:128`),
   `os.path.normpath` (`guard-read-registres.sh:25`). Chaque auteur ré-invente — ou oublie.
2. **La primitive existe pourtant déjà, mais déguisée en règle métier.** `vf_ws_read_pointer()`
   (`workstream-policy.sh:149-171`) est une lecture sûre **générique** — ses trois refus (lien
   symbolique, fichier non régulier, taille) n'ont rien de spécifique au workstream. Elle est
   nommée et typée pour un seul cas d'usage (`VF_WS_RAW`, `VF_WS_REASON`), donc invisible pour
   quiconque résout un autre genre de chemin.
3. **Le contrôle anti-duplication existe déjà, mais sur un roster figé.**
   `test-workstream-policy.sh` porte exactement la forme voulue : C1 (`:301-313`) vérifie que les
   gates sourcent la politique partagée et n'en redéfinissent aucune partie localement, C2
   (`:316-322`) que `vf_ws_name_valid` n'est défini **qu'une fois** dans tout
   `plugin/*/scripts/`, C3 (`:324+`) prouve **par mutation** que la mesure sait rougir. Mais C1
   itère sur **quatre chemins écrits en dur**. Un script neuf —
   `build-gsd-capabilities-index.sh` — n'appartient à aucun roster : il peut ré-inventer le
   confinement sans que rien ne s'en aperçoive. **Le contrôle est aveugle aux nouveaux entrants,
   qui sont précisément la population qui reproduit le motif.**

**Ce que l'exposition pèse.** Sur les 52 scripts hors tests de `plugin/*/scripts/`, **37** lisent
un fichier à un chemin porté par une variable, et **29** ne portent aucun marqueur de confinement
(`-L`, `realpath`, `pwd -P`, `normpath`, ou source de la politique). Ce chiffre est un **majorant
de candidats, pas un décompte de vulnérabilités** : beaucoup de ces chemins dérivent de la racine
du dépôt et ne sont pas pilotables par un attaquant. Il donne l'ordre de grandeur de la surface à
trier, rien de plus.

**Contrôle transverse proposé — en dette, pas dans cette phase** (inscrit à
`.planning/codebase/CONCERNS.md`) :

- **(a) Une primitive de confinement partagée**, hôte `plugin/planning-core/scripts/` — le
  précédent est déjà là (la politique de workstream y vit et est sourcée par 4 scripts de 3
  modules) et sa fermeture de dépendances est réduite à lui-même. **Deux** fonctions, parce que
  le motif a deux moitiés distinctes que les quatre passages confondent :
  `vf_path_refuse_link` (refuser de suivre — cas pointeur) et
  `vf_path_confine <candidat> <ancre>` (exiger que le chemin réel reste sous une ancre réelle —
  cas registre et cas compartiment).
- **(b) Généraliser C1/C2 du roster figé à l'énumération.** Le gate n'a pas à deviner quels
  scripts sont concernés : il énumère `plugin/*/scripts/*.sh`, et **chaque** script qui lit un
  chemin dérivé d'une entrée doit soit sourcer la primitive, soit figurer dans une liste
  d'exemptions **nommée et motivée**. Une exemption est un aveu écrit, pas un oubli silencieux.
- **(c) Un cas de mutation obligatoire**, sur le modèle de C3 : ajouter au corpus de test un
  script neuf qui lit un chemin sans confinement **doit** faire rougir la suite. Sans ce cas, la
  garde serait une assertion d'**existence** (« la primitive existe quelque part ») qui reste
  verte pendant que la **relation** se rompt — exactement le mode d'échec que la revue de cette
  phase a déjà dû corriger deux fois.

---

## Signature

- [x] Toute menace porte une disposition (mitigate / accept / transfer)
- [x] Les risques acceptés sont au journal des risques acceptés
- [x] Chaque menace `closed` porte une preuve citée dans le code livré, opposable et re-vérifiable
- [ ] `threats_open: 0` confirmé — **NON** : 4 menaces ouvertes de sévérité >= high
- [ ] `status: verified` en frontmatter — **NON** : `draft`. Un audit a tourné, mais quatre
      menaces bloquantes restent ouvertes — dont une exigeant une décision humaine (T-24-02-01),
      une exposition reproduite (T-24-14-C1) et deux suspendues à un plan en vol.

**Approbation : en attente.** Ce document est un constat honnête, pas une validation.
