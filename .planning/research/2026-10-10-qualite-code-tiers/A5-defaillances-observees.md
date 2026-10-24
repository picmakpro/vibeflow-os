# Défaillances observées dans l'historique de vibeflow-os : quels emprunts sont justifiés ?

Recherche en lecture seule, menée le 2026-10-10 sur `le dépôt `vibeflow-os``.

## Sources et limites

Sources fouillées :
- `.planning/missions/` ;
- les phases sous `.planning/milestones/*-phases/` et `.planning/workstreams/*/phases/` ;
- `.planning/BACKLOG.md` et `.planning/codebase/CONCERNS.md` ;
- `reports/audit`, `reports/validator` et `reports/uat` ;
- `CHANGELOG.md` et `docs/ADR.md` ;
- les mémoires d'agents du dépôt (`.claude/agent-memory/*`) ;
- la mémoire projet (`~/.claude/projects/-Users-samuel-Documents-dev-vibeflow-os/memory/`).

Limites :
- **Le clone est superficiel (`git rev-parse --is-shallow-repository` = true, 50 commits visibles).** Les SHA anciens ne se lisent donc que par citation dans les documents. Je n'ai pas pu fouiller les messages de commit fix/revert au-delà du 2026-10-06.
- Le dépôt ne contient que 5 fichiers `*REVIEW*.md` : 4 de la Phase 23 et 1 quick de gouvernance. Les rapports de revue récents vivent dans des scratchpads non versionnés. Les traces de revue passent donc surtout par les rapports de mission et les mémoires d'agents.
- Je n'ai trouvé aucun retour de lab sur la qualité du code produit chez l'utilisateur. Les seules traces de labs concernent Scroll-Off (recette mobile, Phase 34) et l'origine des budgets de méthode (sobriété).

Un constat de cadrage domine tout le corpus et pèse sur plusieurs emprunts. Le mode de défaut dominant de ce dépôt est **un vérificateur qui ne peut pas rendre rouge**. Il a été trouvé par exécution, presque jamais par relecture. Les dix occurrences de la Phase 39 sont listées dans la mémoire projet `preuve-incapable-de-rendre-rouge.md`, qui affirme : « la relecture a un taux de détection observé proche de zéro sur ce motif ». Tout emprunt qui repose sur une revue par lecture se heurte à ce constat.

---

## A. Réutiliser l'existant (stdlib, dépendance installée) avant d'écrire du neuf

| Date | Référence | Constat | Jugement |
|---|---|---|---|
| 2026-08-04 → 2026-08-06 | `.planning/codebase/CONCERNS.md:143-190`, `docs/ADR.md:2309-2345` (ADR-070) | Le confinement de chemin est fermé **cinq fois à cinq endroits**, avec « six implémentations du même besoin [...] dans trois langages » (`[ -L ]`, `vf_realpath` node, `os.path.realpath`, `pwd -P`, `os.path.normpath`). « La primitive existe déjà mais déguisée en règle métier : `vf_ws_read_pointer()` ». Le contrôle anti-duplication porte « sur un roster figé ». La prédiction « un 5ᵉ passage est attendu » s'est vérifiée en Phase 27 (RCE CWD dans `dag.sh`). La primitive partagée `vf_path_confine` proposée n'existe toujours pas : 0 occurrence dans `plugin/` ni `scripts/`. | **Défaillance observée solide**, datée et récidivante. |
| 2026-09-27/28 | `.planning/missions/2026-09-27-gouvernance-44.md:51`, `.claude/agent-memory/vf-auditer/project-phase44-recalc-planning-findings.md:34-36` | `recalc-planning.sh` embarquait une **recopie Python** de `detect-gsd-engine.sh`. Trois divergences symlink et UTF-8 ont été trouvées par l'audit au tour 3. Remède du lot 4 : « vrai `detect-gsd-engine.sh` [...], recopie Python supprimée ». La mission a coûté 8 lots et 4 tours de juges. | **Défaillance observée solide** : la réimplémentation d'un helper existant a produit les bugs. |
| 2026-08-28 | `.claude/agent-memory/vf-dev-manager/project_gsd-core-porte-le-modele-de-capacite.md` | Le cadrage de la Phase 37 proposait un enum maison `full/skills-only/unsupported`. Or gsd-core porte déjà `degradationFor` sur 9 axes : l'enum « ré-agrégerait à la main [...] ce que `degradationFor` calcule déjà ». Seule une mesure l'a révélé. | Solide, mais la réimplémentation a été **évitée au cadrage**. Il n'y a pas eu de défaillance d'exécution. |
| 2026-08-28 | `.claude/agent-memory/vf-dev-manager/feedback_mesure-juste-attribution-fausse.md` | Une table de 31 correspondances de noms était prévue. Elle a été remplacée par « une normalisation d'une ligne » après une re-mesure (Phase 37 vers 38). | Indice, sur-ingénierie évitée de justesse. |
| 2026-08-04 | `.planning/missions/2026-08-04-phase-24-activation-moteur-gsd.md:98` | « le barème `effort:` existe déjà [...] Ce n'est pas une doctrine à inventer, c'est une doctrine à propager. » | Indice faible, attrapé au cadrage. |
| 2026-08-17 | `.planning/missions/2026-08-17-notifications-opt-in-PAUSE.md:218` | « `VF_NOTIFY_FORCE_CHANNEL=none` existe déjà [...] deux mécanismes d'extinction concurrents seraient une régression ». | Indice faible, attrapé au cadrage. |

**Bilan A.** Deux défaillances d'exécution solides : le confinement de chemin (2026-08-04, ADR-070 le 2026-08-06) et la recopie Python de la Phase 44 (2026-09-28).

Nuance importante : la doctrine existe déjà dans plusieurs textes.
- ADR-069 : « Router, jamais forker [...] ne se réimplémente pas » (`docs/ADR.md:2144`).
- La consigne « ne réimplémente jamais » des agents.
- La mémoire `audit-2026-07-bascule-agentique` : « vérifier qu'il porte de la LOGIQUE ».

Le trou observé n'est donc pas l'absence de règle. **Aucune machine ne repère un nouvel entrant qui réinvente une primitive** : CONCERNS l'écrit, « le contrôle est aveugle aux nouveaux entrants ». Un emprunt purement déclaratif, du genre « réutilise d'abord », doublerait une prose qui existe déjà et n'a pas suffi.

---

## B. Axe de revue « sobriété » (code mort, duplication, abstraction unique, sur-ingénierie)

| Date | Référence | Constat | Jugement |
|---|---|---|---|
| 2026-07-25 | `reports/audit/2026-07-25-audit-complet.md:46,66-73,143-145` | Un audit croisé trouve plusieurs problèmes après des revues passées :<br>• « 30 des 36 verbes vf-* sont des renommages purs [...] ~935 L de traduction, pas de logique » ;<br>• une table de routage « en 4 exemplaires » ;<br>• le skill-creator « dupliqué verbatim (485 L ×2) » ;<br>• `vf-reviewer` et `vf-auditer` qui sont des « wrappers d'un seul appel Task ».<br>Suite donnée : en v2.33.0, les 29 façades sont supprimées (mémoire `audit-2026-07-bascule-agentique.md`). | **Défaillance observée solide** : couches d'abstraction sans logique, détectées par audit et non par revue de diff. |
| 2026-07-25 → aujourd'hui | `CONCERNS.md:68-77`, `.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md:284-293` | Le doublon divergent `docs/reference/` ↔ `plugin/reference/content/` (77 fichiers, ~9 800 lignes) a été signalé le 25/07, le 26/07 et le 01/08 (« Non traité ici [...] suppression de contenu »). **Toujours présent le 2026-10-10** : `rtk proxy diff -rq` rend 5 lignes, 4 fichiers différents, et ce ne sont plus les mêmes qu'en août, donc la dérive continue. | **Solide, mais le défaut n'est pas la détection.** Le constat est connu depuis 2,5 mois et n'est jamais exécuté. |
| 2026-08-16 | `.claude/agent-memory/vf-dev-manager/feedback_preuve-du-chemin-heureux-ne-couvre-pas-l-echec.md` | Un « refactor mécanique, zéro changement de comportement » ramène ~35 sites à un helper unique. La vérification md5 est verte sur 262 fichiers, mais la revue trouve 4 régressions bloquantes (`errexit` en position médiane). | **Contre-indice pour le « code judo »** : une refonte qui simplifie à comportement soi-disant constant a cassé le chemin d'échec. |
| divers | `CONCERNS` (check-gsd-config.sh:270 « jamais résolu »), `33-06-PLAN.md:94` (`VF_NOTIFY_BIN_DIR` « code MORT »), `31-01-SUMMARY.md:29` (`vf_manifest_excluded` mort à l'exécution) | Du code mort a bien existé. | Ces cas ont été trouvés **par exécution ou mutation**, pas par lecture. Indice faible qu'un axe de lecture les aurait attrapés. |
| 2026-09-29 | mémoire projet `sobriete-de-methode-phase-41-3.md` | « on crée sans ranger » : planning 210 k lignes contre 127 k pour le plugin, STATE 146 Ko. | Concerne la **méthode** (docs, mémoires). Déjà traité par SOBR-01..08. |

**Bilan B.** La sur-construction est réelle et datée (façades vf-*, doublons). Mais les cas trouvés l'ont été par **audits transverses**, pas par la revue du diff, et le plus gros reste ouvert faute de décision, pas faute de détection. Un axe « sobriété » dans `vf-reviewer` aurait-il vu les façades ? Peut-être au moment de leur ajout, mais rien ne le prouve. Aucun cas ne montre une revue `passed` à qui l'on aurait reproché, après coup, d'avoir laissé passer de la sur-ingénierie dans un diff précis. Il n'y a pas non plus de constat Info ou mineur ignoré qui serait devenu un problème de sobriété.

Je n'ai rien trouvé pour « une abstraction à une seule implémentation dans un script bash » ni pour « un refactor qui déplace sans simplifier ». Le seul refactor documenté (Phase 31) a régressé, ce qui plaide pour la preuve par injection de panne déjà en mémoire plutôt que pour encourager la refonte.

---

## C. Seuil de taille déclenché par le delta

| Date | Référence | Constat | Jugement |
|---|---|---|---|
| actuel | `plugin/software-architecture/scripts/guard-file-size.sh:1-24` (ADR-035, ADR-043) | **Le mécanisme existe déjà** : un hook PreToolUse « Edit : ne pas agrandir = toujours allow [...] une édition qui agrandit est estimée [...] résultat >= seuil sans marqueur → deny », avec un seuil de 300. | **C'est exactement l'emprunt C, déjà livré.** |
| actuel | `plugin/software-architecture/scripts/check-file-size.sh:27` | `CODE_EXT_RE='\.(ts\|tsx\|js\|jsx\|mjs\|cjs\|py\|go\|rb\|java\|kt\|swift\|rs\|php)$'` : **`.sh` est exclu**. C'est pourquoi `plugin/_internal/vibeflow-update.sh` fait 3 322 lignes et `recalc-planning.sh` 1 888 lignes sans que rien ne bronche. | Trou de couverture constaté, mais **pas une défaillance** : aucun incident n'est attribué à la taille. |
| 2026-08-16 | `CHANGELOG.md:877-885` (v2.53.1) | La porte de taille `guard-file-size.sh` a été « morte **silencieusement** » sur toute installation en scope user (`"$HOME"` littéral). | Concerne G (garde muette), pas le besoin d'un seuil. |
| 2026-09-16/17 | mémoire projet `phase-40-1-revision-adr-029.md`, `CONCERNS.md:79-93` | Les agents étaient à 250 pile (vf-dev-manager, validator). Le plafond absolu forçait « des reformulations forcées qui dégradent l'expérience ». Remède : avertissement à 251, blocage à 300, **ratchet par fichier sur une baseline**. | Défaillance **inverse** : un seuil absolu a nui. Le ratchet par fichier, déjà en place pour les agents, est déjà une forme de delta. |
| 2026-08-16 | `feedback_non-regression-sur-la-decouverte-complete.md` | Un refactor de `vibeflow-update.sh` a cassé une suite d'un autre module, qui sondait le texte de l'engine par `grep -A8`. | La cause est un couplage positionnel, pas la taille. Indice nul pour C. |

**Bilan C.** Je n'ai trouvé **aucune défaillance datée attribuée à la taille d'un fichier**. On ne voit ni bug relié à la longueur de `vibeflow-update.sh`, ni découpe a posteriori, ni revue tronquée par la longueur : le seul signalement d'un `cat` tronqué en Phase 39 est « non reproduit ». Le mécanisme delta existe déjà pour les labs (`guard-file-size.sh`) et, sous forme de ratchet, pour les agents. Le seul geste défendable serait d'**étendre** l'existant aux `.sh`. Il faudrait alors une défaillance pour le justifier, et je n'en ai pas trouvé.

---

## D. Hygiène de grille de revue (cas concret, ligne vérifiée, sévérité selon l'impact, constats écartés, tours brûlés)

| Date | Référence | Constat | Jugement |
|---|---|---|---|
| 2026-07-30 | `.claude/agent-memory/vibeflow-dev/feedback_verifier-fraicheur-avant-audit.md` | Audit à 8 sondes sur un `main` en retard de 258 commits : « 6 constats sur 15 étaient des faux positifs [...] dont un "P0" ». La passe adversariale (« pas de preuve reproductible = INFIRMÉ ») en a invalidé cinq. | **Solide** pour « pas de constat sans cas concret reproduit ». |
| Phase 23 (2026-08-02) | `.claude/agent-memory/vf-dev-manager/project_grep-proxifie-tronque.md` | Des ancres `fichier:ligne` sont **fausses mais plausibles** (`awk` en `NR` multi-fichiers) : `23-02-PLAN.md:815` au lieu de `:378`, décalages de +437 et +1310. | **Solide** pour « vérifier la ligne citée ». |
| 2026-09-15 | `.claude/agent-memory/vf-dev-manager/feedback_constat-du-juge-verifie-correction-non-verifiee.md` | Le plan-checker livre un constat juste et une correction (`^-[^-]` → `^-`) **fausse**, qui aurait rendu le garde rouge en permanence. Le worker l'a mesurée et a dévié. | **Solide** : il faut distinguer le constat mesuré de la correction écrite de tête. |
| 2026-10-06 | `.claude/agent-memory/vf-dev-manager/feedback_contrat-de-verdict-sans-seuil.md`, `41.4-SONDE-POCK04.md` (« Historique des tours ») | Le contrat de revue ne fixait pas quand un axe est `passed`, et les relecteurs passaient `gaps_found` au premier mineur. Résultat : « **deux tours de sonde brûlés** » sur un budget de 3. Corrigé par P414-D-20. | **Solide** pour « la sévérité selon l'impact ». C'est **déjà traité** (seuil = ni bloquant ni majeur). |
| Phase 26 (2026-08-01) | `.claude/agent-memory/vf-dev-manager/feedback_re-deriver-les-listes-d-une-revue.md` | La revue annonçait 21 pages en écart ; le réel était 31 sur 44. L'erreur portait sur le thème déclaré **sain** (0/6 annoncé, 3/6 réel). Les chemins cités étaient morts après un renommage. | Solide (listes et références de revue périmées). |
| 2026-09-15 | `.planning/missions/2026-09-15-phase-34-gaps-agency-agents-skill-installer.md:60` | Une affirmation de revue « prescrite mot pour mot par le plan et recopiée sans recoupement » était fausse. | Indice : un constat sans vérification sur pièce. |

**Bilan D.** C'est l'emprunt le **mieux étayé** : faux positifs, références fausses, correction non mesurée et tours brûlés par une sévérité mal calibrée sont tous observés et datés.

Mais une bonne partie est **déjà codifiée** :
- seuil d'axe P414-D-20 ;
- passe adversariale ;
- mémoires du manager (« relaie le constat + la propriété requise »).

Ce qui manque reste à vérifier au cas par cas dans `vf-reviewer.md`. Ce sont, dans la **grille** elle-même et non dans les mémoires, l'exigence « ligne citée re-vérifiée » et la section « constats écartés » visible. Je n'ai pas trouvé de cas où un faux positif **du reviewer** a consommé un tour de correction de la boucle à 3 tours. Les tours brûlés du 41.4 sont des tours de **sonde**, dus au seuil.

---

## E. Clôture « non vérifié / risque » dans les rapports de revue

| Date | Référence | Constat | Jugement |
|---|---|---|---|
| 2026-07-28 (Phase 19) | `feedback_revue-obligatoire-cout-erreur-asymetrique.md:28-40` | Un garde-fou `inject-mcp-tools.sh --verify` sortait **toujours en 3**. « Trois étages de vérification l'ont laissé passer » : revue PASS, portabilité verte, audit de sécurité 6/6 PASS. Les tests exerçaient `--force --verify`, jamais la forme réellement émise. | **Défaillance observée solide** : des PASS sur une partie non regardée. |
| 2026-08-16 (Phase 31) | `feedback_non-regression-sur-la-decouverte-complete.md` | Une régression dans un autre module « a traversé **six revues et quatre vérifications** ». Chaque juge « héritait du périmètre de mon mandat ». | **Solide** : une ligne « non vérifié : suites hors des fichiers édités » l'aurait exposée. |
| 2026-08-16 (Phase 31) | `feedback_preuve-du-chemin-heureux-ne-couvre-pas-l-echec.md` | Vérification PASS par md5, revue à 4 bloquants. Le vert ne couvrait que le chemin nominal. La mémoire prescrit déjà : « qu'est-ce que ce vert ne prouve pas ? ». | Solide. **Déjà prescrit**, dans les mandats et pas dans le format de rapport. |
| 2026-07-26 (Phase 13) | même mémoire `revue-obligatoire...`, l.13-22 | `vf-coder` rend `passed` en sautant la revue ; la revue imposée trouve 2 bloquants. Le cas de test du bornage était tautologique. | Solide. |
| 2026-09-17 | `.planning/missions/2026-09-17-phase41-cadrage.md:100-102` | Tour 3 : corrections « **non re-vérifiés** (budget de 3 tours atteint) ». C'est un exemple de clôture honnête **déjà pratiquée** en prose. | Montre que la pratique existe, sans format imposé. |
| Phase 39 (2026-09-09 → 14) | mémoire projet `preuve-incapable-de-rendre-rouge.md` | Dix vérificateurs incapables d'échouer, « toutes trouvées par exécution, aucune par relecture ». | Contexte : le « non vérifié » utile ici est « non exécuté » ou « non muté ». |

**Bilan E.** **Défaillances observées solides et récidivantes** : 2026-07-28, deux fois le 2026-08-16. Des PASS ont été rendus sur un périmètre implicite. La mémoire du manager porte déjà la question « qu'est-ce que ce vert ne prouve pas ? », mais comme consigne de mandat. Je n'ai trouvé aucune section obligatoire dans le bloc typé du reviewer qui la rende visible au lecteur suivant. L'emprunt E est le plus directement justifié par une défaillance datée.

---

## F. Mesure A/B avant de modifier une consigne d'agent

| Date | Référence | Constat | Jugement |
|---|---|---|---|
| 2026-09-16/17 | mémoire projet `head-gouverne-ne-lance-pas-gsd.md` | La spec du head livrée en v2.63.0 a donné un comportement conforme au texte mais contraire à l'intention de Samuel. Il a fallu deux hotfixes (v2.63.1, v2.63.2) en deux jours. | Indice faible : c'est un écart de spec, pas une retouche de consigne à effet nul ou inverse. |
| 2026-09-16 | mémoire projet `phase-40-1-revision-adr-029.md` | Samuel refuse des « reformulations forcées qui dégradent l'expérience ». La dégradation est affirmée, jamais mesurée. | Indice faible d'un débat tranché sans mesure. |
| 2026-10-06 | `41.4-SONDE-POCK04.md` (Protocole) | **Mesure réelle déjà pratiquée** sur une retouche de `vf-reviewer` : agent neuf, fixtures à l'aveugle, deux sens. Elle a trouvé le défaut de seuil. Piège noté : « La définition chargée au démarrage de la session aurait été l'ancienne, car le registre d'agents est résolu au démarrage ». | Le mécanisme existe déjà (P414-D-07), et le piège est documenté. |

**Bilan F.** **Je n'ai trouvé aucune défaillance datée** où la modification d'un prompt d'agent aurait eu un effet nul ou inverse découvert après coup. La culture de mesure existe déjà :
- M2 du 2026-07-31 ;
- refus de `claude_orchestration` par mesure ;
- sonde POCK-04.

Le seul piège concret est l'agent périmé chargé en session, qui milite pour une **consigne de protocole de sonde** (charger la définition du worktree) plutôt que pour une règle A/B générale.

---

## G. Échec silencieux de chargement d'une grille ou d'un skill

| Date | Référence | Constat | Jugement |
|---|---|---|---|
| 2026-07-25 | `reports/validator/2026-07-25-validator.md:146-160`, mémoire `vibeflow-validator/project_validator-skills-fantomes.md` | 3 des 6 skills du frontmatter de `vibeflow-validator` n'existent pas. « Constaté en conditions réelles pendant cet audit : les phases 2 et 3 ont dû être menées à la main ». Le gate qui « *sait* détecter "skill déclaré introuvable" » ne le faisait qu'« en WARNING » (l.285). | **Défaillance observée solide.** Corrigée depuis (v2.32.0, « chasse aux fantômes », `CHANGELOG.md:2021`). `check-agents.sh` et `check-skills.sh` couvrent la **déclaration** statique. |
| 2026-09-24 | `.planning/workstreams/gouvernance/phases/VFDO-42-.../42-D19-MESURE.md` | Sous `omitClaudeMd: true`, un sous-agent **ne charge ni `CLAUDE.md` ni `.claude/rules/*.md`**, sans aucun signal (mesuré par jetons aléatoires). D'où D-08 : « tout ce qu'un juge doit vérifier vit dans sa grille ». BACKLOG `:772-793` : les grilles de `quality-gate-client` et `content-clarity-judge` n'ont toujours pas de critère RGPD explicite. | **Solide**, avec une mesure positive et négative. Le remède structurel (grille embarquée) est déjà arbitré. |
| 2026-08-16 | `CHANGELOG.md:877-885` (v2.53.1) | Hooks en forme exec morts en scope user, dont la porte de taille, « morte **silencieusement** ». | Solide, mais pour un hook, pas pour une grille de revue. |
| 2026-10-06 | `41.4-SONDE-POCK04.md` | Le registre d'agents est résolu au démarrage : une définition modifiée **n'est pas chargée** en session et l'ancienne tourne sans signal. | Solide, et contourné par le protocole de sonde. |

**Bilan G.** Défaillances observées **solides** (2026-07-25, 2026-09-24), mais toutes au niveau **déclaration ou contexte** : skill fantôme, `omitClaudeMd`, registre figé. Je n'ai trouvé **aucun cas** d'un reviewer en exécution qui aurait tenté de charger sa grille, échoué, puis revu « de mémoire » sans le dire. Les remèdes déjà en place sont `check-skills`, `check-agents --strict` et D-08. Un emprunt G n'aurait de prise neuve qu'au **runtime** (le reviewer atteste dans son bloc typé la grille réellement lue, par exemple son chemin et une empreinte), et ce cas précis n'a pas de défaillance datée.

---

## Synthèse

| Emprunt | Verdict | Défaillance datée la plus forte | Déjà couvert ? |
|---|---|---|---|
| A. Réutiliser l'existant | **Solide** | Confinement de chemin ×5 (2026-08-04/06, ADR-070) ; recopie Python Phase 44 (2026-09-28) | Doctrine en prose (ADR-069) ; aucune machine sur les nouveaux entrants |
| B. Axe sobriété | **Solide sur le fond, faible pour un axe de revue** | Façades vf-* et doublons (audit 2026-07-25) ; `docs/reference` toujours divergent | Trouvé par audit, pas par revue ; le blocage est l'exécution, pas la détection |
| C. Seuil de taille delta | **Rien trouvé** | Aucune | **Déjà livré** (`guard-file-size.sh`, Edit delta, 300 L) mais `.sh` exclu ; ratchet par fichier sur les agents |
| D. Hygiène de grille | **Solide** | 6/15 faux positifs (2026-07-30) ; ancres fausses (Phase 23) ; 2 tours de sonde brûlés (2026-10-06) | Partiellement (P414-D-20, mémoires du manager) |
| E. Clôture « non vérifié » | **Solide, le plus direct** | 3 étages PASS sur un garde inerte (2026-07-28) ; 6 revues + 4 vérifications aveugles (2026-08-16) | En consigne de mandat, pas dans le format de rapport |
| F. A/B avant retouche d'agent | **Indice faible** | Aucune retouche à effet nul ou inverse datée | Sonde réelle POCK-04 déjà pratiquée |
| G. Échec silencieux de chargement | **Solide au niveau déclaration, rien au runtime** | Skills fantômes (2026-07-25) ; `omitClaudeMd` (2026-09-24) | `check-skills`, `check-agents`, D-08 |

Contre-indice transverse pour le « code judo ». Le seul refactor simplificateur documenté, la Phase 31 (2026-08-16), a passé une vérification d'équivalence et introduit 4 régressions bloquantes sur le chemin d'échec. Si l'emprunt est retenu, il doit venir avec la preuve par injection de panne déjà consignée dans `feedback_preuve-du-chemin-heureux-ne-couvre-pas-l-echec.md`.
