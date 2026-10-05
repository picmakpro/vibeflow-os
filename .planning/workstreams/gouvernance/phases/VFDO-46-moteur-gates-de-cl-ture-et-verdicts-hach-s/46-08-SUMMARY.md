---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 08
subsystem: planning-core
status: complete
requirements: [CLOT-10]
tags: [rejeu, etape-5, etape-6, g3, g4, g4p, oracle, couverture, lecture-seule]
commits: 2
plan_head_before: 92ef7cffadc0bbdd8f91fe28f62a4d96706a43f8
commit_list:
  - 81f97543 feat(planning-core): rejeu en lecture seule de l'étape 5, G3 et G4 sur unités synthétiques (46-08, P46-D-11)
  - a10c0273 feat(planning-core): rejeu de l'étape 6, G4′ par agent (46-08, P46-D-02, P46-D-11)
estimate:
  tokens: 150000
  raw_tokens: 150000
  tasks: 2
  confidence: low
actuals:
  tokens: 15867
  tasks: 2
  commits: 2
  duration: "78 min (19:32 - 20:50, dont environ 46 min d'attente de suites sous charge machine 140-226)"
  note: "tokens = chars/4 sur les 896 lignes ajoutées du diff réalisé (63468 caractères, base 92ef7cff, quatre fichiers du plan) ; commits mesurés par rev-list, hors le commit final du SUMMARY"
key-files:
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-REJEU-ATTENDUS.txt
  modified:
    - plugin/planning-core/scripts/rejeu-gates.sh
    - plugin/planning-core/scripts/rejeu-reel.sh
    - plugin/planning-core/scripts/tests/test-rejeu-gates.sh
---

# Phase 46 Plan 08 : rejeu en lecture seule des étapes 5 et 6 — Summary

L'outil de rejeu mesure G3, G4 et G4′ sur des écritures réellement jouées (unités synthétiques à attendu nominatif, entrées réelles jugées par un oracle propre au rejeu, un jeu par agent et par événement), et une mesure qui n'a rien joué sous un gate échoue (code 1) au lieu de rendre 0/0.

Worktree : branche `worktree-agent-a1f5f2b41dcba6812`, SHA final des tâches `a10c02734f9c817acf52d8dcc245152639c82a6e` (base `92ef7cff`, ancêtre vérifié). Aucun lab réel lu ni rejoué, aucune sonde `claude -p`, aucun `git stash`, `checkout`, `reset`, push, tag ni release.

## Livré

**Tâche 1 (traceur, `81f97543`)**
- `rejeu-gates.sh` et `rejeu-reel.sh` : `--etape` accepte 1 à 6 (autre numéro : code 64 ; `rejeu-reel.sh` refuse avant toute empreinte, balise `reel-etape`). L'armement simulé suit `ORDRE_ETAPES` du hook copié (inchangé : l'étape 5 arme G6, G5, G1, G7, ROLE, G3, G4 ; l'étape 6 arme aussi G4P).
- Constructeurs `G3` et `G4` (`preparer_g34`, balise `rejeu-g3g4-synthetique`), partagés par un cache de contexte. Sur la COPIE seulement (`sous_copie` avant toute écriture), sous `.planning/cycles/99-rejeu-cloture/phases/<NN>-<slug>/` (PLAN.md à `ecrit:`, CADRAGE.md clos) :
  - 7 unités G3 synthétiques (livrable présent fichier, présent dossier, absent, vide, lien, dossier réduit à un `.DS_Store`, lien vers un dossier) ;
  - 7 unités G4 synthétiques (verdict conforme fichier et dossier posés par la VRAIE `poser-verdict.sh`, verdict absent, constat en échec, périmé par le plan, périmé par le livrable, VERDICT.md invalide) ;
  - une unité G3 (et, si l'entrée est présente, une unité G4) par entrée réelle de premier niveau non cachée, au plus 50 par lab, triées. L'attendu vient de `oracle_presence` (balise `rejeu-oracle-presence`, lstat, aucun lien suivi, fichiers et dossiers comptés comme le budget du hook) ; l'entrée est reflétée sur la copie par un squelette (même arborescence, un octet par fichier non vide, jamais le contenu réel ; un substitut de dimension pour une entrée hors borne).
- `BORNE-LIVRABLES lab=… entree=… fichiers=<n> octets=<m>` (mesure de A7), `ENTREE-IGNOREE lab=… entree=… motif=…` (jamais d'entrée tue), `COUVERTURE-REJEU <gate> n=<k> plancher=<p>` ; sous le plancher : message nommé sur stderr, relevé quand même imprimé, code 1.
- Suite : R-REJEU-ETAPES, R-REJEU-G3G4, R-REJEU-BORNE ; mutants MUT-REJEU-G3G4-ENREGISTRE, MUT-REJEU-ORACLE, MUT-REJEU-ETAPE5 ; R-REJEU-STATIQUE passe de 4 à 5 sous-processus (`poser-verdict.sh`) ; `VF_REJEU_SECTIONS` restreint la liste des sections pour la mise au point.

**Tâche 2 (`a10c0273`)**
- Constructeur `G4P` (`construire_g4p`, balise `rejeu-g4p`) : par agent de la racine du lab copié, `SubagentHandback` (PreToolUse, `tool_input.message`) et `SubagentStop` (`last_assistant_message`, `permission_mode: "default"`), sans puis avec sortie brute (rapport de référence : bloc dont la première ligne est `$ ls`). L'attendu du rapport sans sortie vient du rôle (`--classer` du hook copié : worker ou producteur) ET d'une lecture propre à l'outil de `tools:` et `disallowedTools:` (`capacite_bash`, balise `rejeu-g4p-bash`). Une ligne `G4P-AGENT lab=… agent=… role=… bash=<oui|non|indetermine> attendu=…` par agent.
- `jouer()` lit `{"decision":"block"}` (SubagentStop, code 0) comme un refus avec sa raison.
- Fichier d'attendus : `G4P | <lab> | agents/<agent> | <attendu> | <motif>` vise les deux rapports SANS sortie de l'agent et l'emporte sur le constructeur ; deux attendus contradictoires de même rang, ou `agents/` seul, ou un chemin hors `agents/` : code 1.
- `46-REJEU-ATTENDUS.txt` : en-tête (date, sources P46-D-11, P46-D-02, P46-D-02b, P46-D-12, protocole P45-D-21/21a, rôle des lignes), format, règles par défaut ; aucune ligne de lab réel.
- Suite : R-REJEU-G4P ; mutants MUT-REJEU-G4P-ENREGISTRE, MUT-REJEU-G4P-BASH.

## Verdicts (commande -> rc + ligne)

| Commande | rc | Ligne clé |
|---|---|---|
| `git merge-base --is-ancestor 92ef7cff… HEAD` (préalable d'isolation) | 0 | base présente |
| `test-rejeu-gates.sh` ENTIER, avant le découpage en commits, fichiers vérifiés `cmp` identiques à ceux de `a10c0273` | 0 | `DUREE s=1360` · `== Résultat : 100 OK · 0 KO ==` (charge 190 à 230) |
| `verify-t2.sh` (forme `substr($0,9)+0`, suite ENTIÈRE à `a10c0273`) | 1 | `DUREE s=1123` · `== Résultat : 100 OK · 0 KO ==` ; toutes les clauses vertes SAUF `DUREE <= 600` (charge 140 à 190, voir déviations) |
| tâche 1 seule (`81f97543`) : `VF_REJEU_SECTIONS=etapes,g3g4,borne,statique` | 0 | `DUREE s=62` · `== Résultat : 5 OK · 0 KO ==` |
| tâche 1 seule : mutants G3G4-ENREGISTRE, ORACLE, ETAPE5 | 0 | `DUREE s=40` · `== Résultat : 3 OK · 0 KO ==` |
| `bash scripts/check-machine-paths.sh` | 0 | `✓ 1928 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` |
| `45-CONTROLE-MARQUEUR.sh --base=247194c7 -- plugin/planning-core/scripts plugin/planning-core/hooks` | 0 | `MARQUEUR-BILAN commits=22 sans-marqueur=0` (`81f97543` et `a10c0273` conformes=1 chacun) |
| `check-gate-touche.sh --base-ref 92ef7cff…` | 3 | `RIEN-A-JUGER` (surface surveillée non touchée ; marqueurs lus=2 conformes=2) |
| `check-planning-consumers-registered.sh` | 0 | `✓ 127 .sh suivi(s) … tous recensés ; volet ci.yml : oui` |
| acceptation tâche 1 : `awk '/--etape/ && /6/' rejeu-reel.sh` non vide | 0 | usage annonce l'étape 6 |
| acceptation tâche 2 : en-tête >= 3 lignes `# ` et 0 ligne `G[34P] \|` dans `46-REJEU-ATTENDUS.txt` | 0 | conforme |

Comptes de la suite : 91 contrôles (46-05) -> 100 (R-REJEU-ETAPES, R-REJEU-G3G4, R-REJEU-BORNE, R-REJEU-G4P, cinq mutants).

Mutants tués avec trace attendu/obtenu (extraits) :
- `MUT-REJEU-G3G4-ENREGISTRE TUÉ` : original `rc 0, G3 (0,0,0)` ; mutant `rc 1, couverture insuffisante : G3 n=0 plancher=6`.
- `MUT-REJEU-ORACLE TUÉ` : original `lien [(doit-refuser, refus)], G3 (0,0,0)` ; mutant `lien [(doit-passer, refus)], G3 (1,0,0)`.
- `MUT-REJEU-ETAPE5 TUÉ` : original `REJEU-ETAPE-5 (0,0,0)` ; mutant `G3 (0,7,0), G4 (0,5,0), REJEU-ETAPE-5 (0,12,0)`.
- `MUT-REJEU-G4P-ENREGISTRE TUÉ` : original `rc 0, G4P (0,0,0)` ; mutant `rc 1, couverture insuffisante : G4P`.
- `MUT-REJEU-G4P-BASH TUÉ` : original `G4P (0,0,0)` ; mutant `G4P (0,4,0)`.

Relevés synthétiques de mise au point (non gardés) : lab complet à l'étape 5, `REJEU-ETAPE-5 faux-refus=0 faux-accept=0`, `COUVERTURE-REJEU G3 n=18 plancher=6`, `G4 n=12 plancher=6`, `BORNE-LIVRABLES … entree=gros fichiers=2001 octets=2001` ; six agents à l'étape 6, `COUVERTURE-REJEU G4P n=24 plancher=4`, `REJEU-ETAPE-6 faux-refus=0 faux-accept=0`.

Non lancés en local (charge machine 137 à 226, et non concernés par le diff : seul `test-rejeu-gates.sh` référence `rejeu-gates.sh`) : `test-planning-gates.sh`, `test-planning-hook-registered.sh`, `test-recalc-planning.sh`, `test-cloture-gates.sh`, `test-planning-prefilter.sh` (section `mutants` : jamais en local) : **CI**.

## Deviations from Plan

**1. [Rule 1 - Défaut du plan] Contrôle de durée** : `substr($0,8)+0` sur `DUREE s=…` vaut toujours 0 ; la forme `substr($0,9)+0` a été jouée (consigne du manager). Plan non corrigé. Avec la forme correcte, la clause `DUREE <= 600` est NON TENUE : 1123 s et 1360 s sous charge machine 140 à 230 (le lot 46-05 notait 560 s pour 91 contrôles à charge 100 à 280). Les sections ajoutées pèsent environ 4 à 5 minutes de cette durée sous charge. Aucune autre clause du verify n'échoue (`VERDICT-T2 rc=1` vient de cette seule clause). À arbitrer (voir points ask-user).

**2. [Rule 1] Forme de commande** : `check-gate-touche.sh --base-ref <sha>` (espace) ; rc=3 `RIEN-A-JUGER`.

**3. [Écart de formulation du plan] MUT-REJEU-ORACLE** : le plan annonce « faux accept sur le lien ». Un oracle qui suit les liens range l'entrée liée en `doit-passer` ; le hook la refuse : le compte est un FAUX REFUS (G3 (1,0,0)), tué avec cette trace. MUT-REJEU-ETAPE5, lui, produit bien des faux accept.

**4. [Écart au contrat de l'outil, documenté en tête de `rejeu-gates.sh`] Constructeurs joués à partir de leur étape** : l'en-tête disait « les constructeurs de TOUS les gates sont joués quelle que soit --etape ». G3 et G4 (étape 5) et G4P (étape 6) ne se jouent qu'à partir de l'étape de leur gate (poses de verdict, quatre jeux par agent : coût) ; leur plancher de couverture n'est exigé qu'à partir de cette étape. Les étapes 1 à 4 gardent leurs relevés exacts (R-REJEU-G6G5 inchangé). Les étapes de jeu sont des constantes de l'outil (`ETAPE_G3G4`, `ETAPE_G4P`), indépendantes de `ORDRE_ETAPES`.

**5. [Rule 2 - choix de conception] Planchers de couverture** : `PLANCHER_G34 = 6` par lab adhérent (racine `.planning/`) pour G3 et G4, `PLANCHER_G4P = 4` (un agent, quatre jeux) par lab doté d'agents ; au moins un lab dans les deux cas. Le plancher ne dépend pas des constructeurs (un constructeur retiré laisse n à 0 sous un plancher exigé : MUT-REJEU-*-ENREGISTRE). Le plan fixait « 6 écritures par gate et par lab synthétique » sans définir G4P.

**6. Ajouts non écrits au plan** : (a) lignes `ENTREE-IGNOREE` (nom non déclarable dans `ecrit:` — `~` initial, caractère de contrôle, métacaractère —, nom réservé, squelette ou verdict impossible) : une entrée non rejouée est dite, jamais tue ; (b) `MESURE_PLAFOND_G34 = 200000` : le comptage d'une entrée réelle s'arrête là et la ligne `BORNE-LIVRABLES` porte `mesure-tronquee` ; (c) `rejeu-reel.sh` valide `--etape` avant toute empreinte (code 64) ; (d) `jouer()` reconnaît `decision: block` ; (e) `VF_REJEU_SECTIONS` ; (f) R-REJEU-STATIQUE : 5 sous-processus (`poser-verdict.sh`).

**7. Découpage des commits** : développé en un seul arbre, puis scindé par dérivation programmatique de la version « tâche 1 » (sans G4P) ; la version `81f97543` a été rejouée sur ses propres contrôles (5 OK + 3 mutants), la suite entière l'a été sur l'état final.

**8. Registre de tête du plan** : l'écriture de `gsd-plan-head-before-46-08` dans le dossier git a été refusée par la garde d'isolation ; `plan_head_before` est la base connue `92ef7cff`, `commits:` mesuré par `rev-list --count 92ef7cff..HEAD` = 2.

**9. Incident de scratchpad** : un chemin de scratchpad mal saisi (`/private/tmp/claude-501/-Users-makwilmak/…`) a créé un dossier ; je l'ai supprimé par `rm -rf` sans avoir vérifié qu'il n'existait pas déjà (il pouvait appartenir à une autre session). Aucun fichier du dépôt ni du worktree n'est concerné.

## Known Stubs

Aucun.

## Threat Flags

Aucun nouveau flag. T-46-081 (faux accept à vide) : plancher + MUT-REJEU-G3G4-ENREGISTRE, MUT-REJEU-G4P-ENREGISTRE ; T-46-082 (attendu calculé par le prédicat jugé) : `oracle_presence` propre au rejeu + MUT-REJEU-ORACLE ; T-46-083 (écriture dans un lab réel) : `sous_copie` avant toute écriture, reflet de squelette sur la copie, empreinte EMPREINTE-IDENTIQUE vérifiée par les tests ; T-46-084 (chemin de machine) : affichage `~/…` ou `<lab-N>`, `check-machine-paths.sh` vert. L'outil lit désormais, sur un lab réel, les NOMS et métadonnées (lstat) des entrées de premier niveau et de leurs sous-arbres, jamais leur contenu.

## Points ask-user

1. Plafond de 600 s du verify : non tenable sous charge (1123 s mesurées) ; relâcher le seuil, ou rejouer à charge faible, ou laisser la CI arbitrer.
2. Confirmer l'écart 4 (constructeurs G3, G4, G4P joués à partir de leur étape seulement).
3. Pour 46-11 et 46-12 : un rejeu réel crée, par entrée réelle hors borne en nombre d'entrées, un substitut de 2001 fichiers vides sur la copie (au plus 50 entrées, 100 000 fichiers dans le pire cas) et un fichier creux de plus de 128 Mio pour une entrée hors borne en octets ; le comptage réel s'arrête à 200 000 entrées par entrée (`mesure-tronquee`).
4. La documentation d'usage de `--etape=5|6` dans `modele-cycles.md` et `plugin/planning-core/README.md` n'est pas dans les fichiers de ce plan (ils appartiennent à 46-07 et 46-12) : à porter là.

## Self-Check: PASSED

Fichiers présents (`rejeu-gates.sh`, `rejeu-reel.sh`, `test-rejeu-gates.sh`, `46-REJEU-ATTENDUS.txt`) ; commits `81f97543` et `a10c0273` présents ; `construire_g4p` présent dans `rejeu-gates.sh` ; STATE.md et ROADMAP.md non touchés ; fichiers réservés à 46-07 non touchés ; aucune release, bump, tag, push, ni commande `state.*` / `roadmap.*`.
