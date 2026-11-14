# Mission — Phase 79, segment a : exécution de 13 plans du socle du cockpit (2026-11-13)

> Rapport de sortie de segment, écrit par le nœud `docs` du plan de bataille du manager, à partir des SUMMARY des
> plans, du journal des décisions du manager et du relevé de CI. Compartiment `fiabilite`, jalon `vibeflow-v2.0`,
> branche `feat/phase-79-socle-cockpit`. Demande : session principale Claude Code, 2026-11-11 (« Exécuter 79 et 80 en
> parallèle avec un manager de jointure »). Le segment ne clôt pas la phase : 79-13 à 79-20 et 79-22 restent.
> Complété le 2026-11-13 par le nœud `docs2` (verdicts de rv2, rv-11 et des quatre relectures du cliquet, cas sautés
> rejoués sur la tête 7ef2594c, correctifs de fix2-x06, run de CI de la tête finale).

## Résultat

- Verdict global : partiel. Les 13 plans du segment (79-01 à 79-12, 79-21) sont faits, chacun avec son SUMMARY commité ;
  ils sont cochés au ROADMAP et au ledger (17 exigences SOCL-01 à 16 et SOCL-26) par 906e3efe. La phase reste ouverte.
- Base de départ du segment : `680364f1`. La branche compte 273 commits au-dessus de cette base à la rédaction.
- Dernière tête poussée : `7ef2594c` (cherry-pick `c64f9e2b`, sonde R15c.2 `f7214e6b` et `a821e66b`, cliquet `303a47ad` et
  `f751fc87`, baseline `e1fcc116`). Son run de CI, 43402693393, est VERT de bout en bout. Les commits de la quatrième
  passe du filtre (`e3468b1f`, `3c733f15`, `8ced5084`, `ef5a6020`) et ce rapport partent dans une dernière poussée, non
  encore faite à la rédaction. Ces commits touchent le filtre du cliquet de colonnes : le run vert de `7ef2594c` ne les
  couvre pas, celui de la dernière poussée devra le faire.
- Fusion de la base d'intégration `ab8f3e64` dans la branche en `9c18079c` (via 796b8343). Conflits résolus :
  `plugin/cockpit/amont/` : suppression de 79-01 gardée ; `VENDORED.txt` : forme de 79-01 (une ligne `AJOUT` par
  fichier, tri C) ; compteurs des README recomptés.
- Base de rejeu des « préexistants » : `da64eb8c` (G-1 durcie), arbre détaché ; journaux hors dépôt.
- Aucun bump de version, aucun tag, aucune publication (gel des publications). Aucun correctif hors plan sans
  amendement daté (ADR-031).
- Traces corrigées : 56e13d83 (lignes datées de correction des faux « préexistants », voir Leçons).

## Plans faits

| Plan | Objet | Commit(s) de sortie | SUMMARY |
|---|---|---|---|
| 79-01 | Fork assumé : `plugin/cockpit/amont/` retiré | 8cb2a0fe (retrait), témoins 1828dc64 | 79-01-SUMMARY.md |
| 79-02 | Aide `socle-serveur.sh`, 43 suites migrées | 9759bef3 (aide), 6fbead6b (témoins) | 79-02-SUMMARY.md |
| 79-03 | Registre archivé 24 h, verbe `registry`, `publish-plan` | 69de8ac2, 18211865, 6036878c (conductor v1.54.0) | 79-03-SUMMARY.md |
| 79-04 | Nœud écrit dans chaque mandat, doctrine de publication | 2d37307c à 3919655e (conductor v1.54.1, dev-orchestrator v2.32.0) | 79-04-SUMMARY.md |
| 79-05 | Table des routes, réponse gardée, annotateurs | f397986e (routes), db86078b (annotateurs) | 79-05-SUMMARY.md |
| 79-06 | Serveur lancé depuis le module, sortie = données, identité, mesure du confinement | 893ae24b, 0ab30fdc, 75bd3538, d7c8b1aa (clôture) | 79-06-SUMMARY.md |
| 79-07 | Résolution physique des chemins, pilotes git nommés | 199d725b, c8a009df, f4485088, 9d8fb831 | 79-07-SUMMARY.md |
| 79-08 | Index incrémental des transcripts, contrat étendu | 209c50aa, 3ad2f28f | 79-08-SUMMARY.md |
| 79-09 | Collecte hors de la boucle, registre lu, verrous projetés | 66a9af10, f164a933, 8b2fac07, 0bf75d19, 759fd4bf (correction d'audit), 8ba5260e | 79-09-SUMMARY.md |
| 79-10 | Traduction au point d'émission | cb6eeb43, 73f1a0a6, 213cda8e, a0ad4ca8, 098658fa, a2eaa458 | 79-10-SUMMARY.md |
| 79-11 | Plafond en colonnes, code navigateur rangé, baseline armée | e805f128 à cfaa7105, 1fe872b8 (armement) | 79-11-SUMMARY.md |
| 79-12 | Route d'état `/api/vf/state`, vf-signal par la route | 4cfa3c5d, 99299905, 4b2b6d08 | 79-12-SUMMARY.md |
| 79-21 | Coût borné de la correspondance de motifs du moteur | ad29ec96, 1f1d2eeb, b2361ef7 | 79-21-SUMMARY.md |

Corrections ciblées de sortie (hors cycle de plan, une par constat) : 79-07 en quatre passes (T-79-705 f4485088 ;
git absent 9d8fb831 ; témoins D10 ; M-VIDE-ECARTE 721b8f40) ; 79-09 759fd4bf et 57d3137d, puis ded7daa3 et 9bc16549 ;
79-08 arbreDe ; 79-10 213cda8e, puis la sonde R15c.2 (f7214e6b, a821e66b) ; 79-06 a50de579, e3dbbe8a, f07c8801, puis
2fba54d4 (M-ECOUTE0) et 547cbc45 (`server.json`) ; 79-12 4b2b6d08 puis a2ef07c8 ; 79-11 en quatre passes du filtre du
cliquet (voir Revues).

## Amendements de plan

Revalidation, avant exécution (2026-11-11), tous les constats acceptés après relecture de la preuve à la source :
40af05b4, b1d65317, 80d64b04, 9ea86a3c, a5d6119b, 649f6205, bcf68152, d3d58914, c1ae48f2, fe04b9cb, 45088a02,
43e2ae72, 9c46dab5, 4d065411, 83b90876, bf579e0a. Décisions particulières du manager de mission tenues : B1
(`cockpit_module_copie`) ; découpe de 79-06 en sessions ; V4c.5g (une ligne « déléguée » ne vaut pas citation d'arbitrage
pour une hausse de `colonnes-baseline.txt`, G-1 non modifiée) ; `depends_on` de 79-11 ; D21-1 (79-11 a raison, 79-21
amendé) ; D16-3 (table de 79-CONTEXT.md : 79-15 devient « 79-11, 79-15 »).

Amendements d'exécution, datés dans les plans (liste complète dans les SUMMARY) :
- 79-06 : alphabet de la mesure ; constat bas 1 de l'audit de 79-07 (`realUnder`, `siEchec`) ; tâche 3 (Q13,
  substitution, repli retiré) ; 4a/4b (variable de module vide respectée, confinement sans aide, D4.2, AM4.18) ; deux
  suites hors liste (equipe d20f2157, git-signature a71a36be, déclarées par 4c48d523) ; F1 (d828f895), mutant de F1
  (6cba96db), F2 et F3 (09e1c5c6, 07c4b4b0), FB3.5 (99058078), tâche 5 (cb0d5f29, 36822fd7), 6a, 6b, S3f (75bd3538).
- 79-07 : worktreeVerifie (b17f5510), tâche 5 (ca2cb1c9), tâche ajoutée (e6838fe2), colonnes (8821299f), correction
  T-79-705 (e4280349).
- 79-08 : 1528a2c9 (contiguïté des lignes `assistant`), écart 12 (arbreDe obligatoire), écart 13 (lecture-fil).
- 79-09 : f8636e1c, ceux des tâches 2 et 3, 9134cbff ; correction d'audit.
- 79-10 : classe « chemin du poste dans le relevé » ; responsive ; ecrans-recent et sante ; correction rv-1021.
- 79-11 : amendement du 2026-11-12 (colonnes en baisse de 13, T7.5c, `cockpit_module_muter_p`, questions copie le
  module navigateur, armement différé).
- 79-12 : dix points (voir son plan). 79-21 : M-OPT et P3 (b2361ef7).

## Portes humaines

- 79-06 tâche 2 (mesure du confinement de l'agent, sur le compte de Samuel) : levée d'avance par Samuel, mot pour
  mot « Oui, d'avance (Recommandé) », arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, relayé par
  la session principale. Verdict lu du banc : CONFINABLE ; le document de mesure porte la formule « autorisée d'avance »
  et jamais « validée le jour de la mesure ».
- 79-06 tâche 4c et 79-07 tâche 3b (points de reprise) : levés par la session principale, sur preuves (rubrique de la
  trace, sha, contrôles rejoués, périmètre, rapport de l'audit intermédiaire), au titre de la décision déléguée par
  Samuel « Claude, sur preuves (Recommandé) », AskUserQuestion session principale, 2026-11-11. Pour 79-07 : levée le
  2026-11-12 à 00 h 11, réponse « reprendre tâche 4 ». Aucune de ces portes n'a été levée par le manager ni par un
  exécuteur. Un constat haut remonte à Samuel avant reprise : aucun n'est survenu avant une reprise.
- 79-19 tâche 1 (sonde S0, hors segment) : « Claude la joue » (n'était pas l'option recommandée), même arbitrage ;
  P79-Q-04 tranchée (retrait d'AUDC-I18, segment c).

## Audits

| Plan | Audit | Verdict | Constats et sort |
|---|---|---|---|
| 79-06 | intermédiaire (au06a) | gaps_found | F1 moyen (repli silencieux sur `<sortie>/serve.mjs`) fermé d828f895 + mutant 6cba96db ; F2 bas (forme étroite, acceptée puis élargie 75bd3538) ; F3 bas (`--stop` sans identité) fermé ; F4 (compositions de commandes) fermé ; F5 suit le retrait prévu |
| 79-06 | fin (au06, 08833784) | gaps_found, aucun haut | S3 bas corrigé (75bd3538) ; S1 (branche ancienne d'`estNotre`) en limite et BACKLOG ; S2 (PID et port non liés) en limite, poste mono-utilisateur |
| 79-07 | intermédiaire, avant la reprise 3b | passed | bas 2 (dossier réel du dépôt) fermé par la tâche ajoutée ; bas 1 (`realUnder`) renvoyé à 79-06 |
| 79-07 | fin de plan (au07a) | gaps_found | HAUT T-79-705 (pilotes de nom vide) fermé par f4485088 (témoins D8, mutants M-VIDE-*) ; deux bas fermés |
| 79-07 | frais (au07b, b8ed6c55) | passed | haut et deux bas fermés ; notes basses héritées (mémo 2 s, enfant non git sous envGit) |
| 79-07 | frais (au07c, edbba389) | passed | « absent » ne rouvre pas T-79-705 ; deux témoins D10 et mktemp à gabarit (fait) ; écarts d'étiquette = no-op documentés (voir Limites) |
| 79-09 | au09 (8ba5260e) | gaps_found | MOYEN : le script de verrou lisait hors du lab, fermé au point central `shBorne` (759fd4bf) ; trois bas fermés (code-cache tube/zéro, `redemarrer` non réentrant, chien de garde de la demande : 759fd4bf et 57d3137d) ; infos au SUMMARY (limites) |
| 79-09 | au09, correctif 759fd4bf (partie B de l'audit de 79-12) | passed | la garde `gitSortant` de `shBorne` tient ; rien d'ouvert |
| 79-12 | au12 (99299905) | gaps_found, 4 bas | A1 et A2 (assainir hors try, identité stricte de l'émetteur) fermés a2ef07c8 et 4b2b6d08 ; C1, C2 et C3 (`server.json` : liens, troncature par `--stop`, `.tmp` orphelin) fermés par 547cbc45 (module neuf `vf-cockpit-etat-ecrire.mjs`, aucune ligne longue) ; partie B (759fd4bf) passed ; l'objet B de l'audit a passé |
| 79-12 | correctif 2fba54d4 (M-ECOUTE0) | revue fraîche (rv2) | voir Revues : rv2 a porté sur 79-09, 79-12 et ce correctif ; ses constats sur le correctif sont fermés par 547cbc45 |
| 79-21 | au21 | gaps_found | MOYEN : mémoire du motif, bornée par MAX_MOTIF et MAX_PAS (ad29ec96, b2361ef7) ; bas : stderr de `build.mjs` jeté (hors fichiers de 79-21, signalé pour le registre) ; bas SUMMARY du coût corrigé ; GLOB.E3b no-op ; T-79-2105, T-79-2106 et SC à inscrire au journal des risques (pas de SECURITY.md de phase) |

## Revues

| Revue | Périmètre | Verdict | Constats et sort |
|---|---|---|---|
| rv1 | 79-01 à 05, 08 | gaps_found | majeur 79-08 (`arbreDe` à défaut ouvert) corrigé (I2.8e, M-ARBREDE) ; mineurs 79-01 (Q11.0a), 79-02 (exception git-env, AM7.K1) à traiter après 79-06 ; AM7.S12 no-op noté ; décisions citées sans canal : notées aux SUMMARY |
| rv-0607 | 79-06, 79-07 | gaps_found | majeur F3 (identité par préfixe) corrigé a50de579 ; 38 lignes de plus de 160 colonnes : 26 coupées, 10 laissées et déclarées ; mineurs au rapport : `mod_de` recopiée dans 13 suites, `mktemp` nu dans 30 suites, `serve.mjs:42` clause morte, paramètre inutile de serveur-vivant, identité avec espace |
| rv-1021 | 79-10, 79-21 | gaps_found | majeur 79-10 (replis d'erreur de l'agent en anglais dans `serve.mjs`, porte aveugle à `fail(`) corrigé 213cda8e ; mineurs R6.3, F22, ombre de `t`, un commit par fichier non tenu (déclaré) ; 79-08 I2.8e ; 79-21 : 38 lignes longues dans `confinement.sh`, avis stderr non dédupliqué, contrôle anti-chemins limité au homedir local |
| rv2 (79-09, 79-12, 2fba54d4) | 79-09, 79-12 et le correctif de `server.json` | gaps_found | 79-12 : M1 (`leaseS` non volatil) et M2 (mode strict : deux clauses, un seul mutant) plus mineurs, fermés par fix-x12 (a2ef07c8, passed) ; 79-09 : mineurs (cinq lignes de plus de 160 colonnes de 759fd4bf, `try` d'`etapeTour`, mutants C2.1, C2.7 et C2.6a, garde ouverte de `startLive`, signature du cache dans `.git/config`, `ecrireSignature`, `confirm` évincé, chien de garde de 120 s), fermés par fix2-x09 (ded7daa3, 9bc16549 ; `startLive` garde fermée par défaut, donc 79-13 et 79-15 devront passer la leur) ; 2fba54d4 : T7.11 à attente fixe de 4 s et ancre de M-SRVJSON, fermés par fix2-x06 (547cbc45) |
| rv-11 (79-11) | cliquet de colonnes, baseline armée | passed | mineurs : (1) le filtre `/d[ée]l[ée]gu/` laisse passer « par délégation » ; (2) `col_historique` ne compare pas une recréation après suppression ; (3) gardes du cliquet (l. 53 et 110) sans témoin ; (4) gardes de `navigateur.mjs` sans témoin ; (8) SUMMARY inexact (« préfixes export ôtés »). Sort : corrigés par cliquet-fin (6ad6fbe1, cd7289b7, e1fcc116 : toute forme de délégation écartée, baseline abaissée de 13, SUMMARY corrigé), puis (1) repris par les passes ci-dessous ; LB.E11 : l'hypothèse du client contredite (`client.js:71` réessaie), restent « prêt jamais vrai » ou `enVol` bloqué sans délai, hors plan |
| rv-cliquet | filtre de délégation du cliquet (cliquet-fin) | gaps_found | filtre contourné (« délègue » accentué, NFD, espace de largeur nulle) ; témoins V4c.5h'' et 5h3 tautologiques. Sort : cliquet-fin2 (normalisation NFKD, radical, témoin génératif), 24fdf46f, 466a5437. À l'issue de cliquet-fin : verifier OK, 114 fichiers, 1 674 lignes ; vendor 222/0 |
| rv-cliquet2 | cliquet-fin2 | gaps_found | séparateurs (« dé-léguée », espace insécable), caractères de classes Cf et Cc hors jeu, marques hors 0300-036F. Sort : cliquet-fin3 (classes Unicode `\p{Cf}`, `\p{Cc}`, `\p{M}` et séparateurs), 303a47ad, f751fc87 ; 253 des 375 citations légitimes acceptées, à conserver |
| rv-cliquet3 | cliquet-fin3 | gaps_found | ponctuation visible à l'intérieur d'un mot, U+2800, zone d'usage privé. Sort : cliquet-fin4, ensemble POSITIF (seules les lettres `\p{L}` après NFKD comptent), e3468b1f, 3c733f15, 8ced5084, ef5a6020 (non poussés à la rédaction) ; balayage complet 0 fuite ; 304 citations identiques ; témoins « citation légitime » et deux messages réels de l'historique de la branche (hausse refusée, baisse acceptée) |

Quatrième passe du filtre : c'est la DERNIÈRE, par décision déléguée (message de la session principale, 2026-11-08,
option recommandée, prise par la session principale le 2026-11-13), motif ADR-072 : le filtre est une garde
déclarative, il rend visible et ne verrouille rien, et un filtre lexical n'a pas d'ensemble fini de contournements
à fermer. Aucune cinquième passe n'est prévue ; ce qui reste est écrit en limites. Limites du filtre : homoglyphes
(un caractère d'un autre alphabet qui ressemble à une lettre), synonymes (« mandat » pour « délégation »), coupure du
mot par un retour à la ligne, faux positifs de compaction (« mode léger » lu comme une délégation : le filtre
refuse alors par prudence, il ne laisse pas passer), `col_historique` aveugle au renommage d'un fichier et à
`--no-merges`.

## Tableau des rouges de CI

Source : `parsed.json` du relevé de CI de la PR du segment, onze runs (un par push, identifiants publics de la CI,
rangés dans l'ordre du relevé et non de la chronologie) ; seules les suites rouges sont listées. Les causes sont celles
du journal du manager et des commits cités ; « non consignée » dit que ni le journal ni les SUMMARY n'en portent.

| Run (identifiant) | Suites rouges (lignes en échec) | Cause et sort |
|---|---|---|
| 43189450642 | 18 suites sur 7 des 9 shards : lancer-chat 28, lancer-processus 43, lancer-serveur 48, lancer-xss 62, lancer-mode 53, chaine-xss 29, onglet-code 22, terminal-xterm 25, -client 30, -page 15, -pty 9, -session 17, -lanceur 10, -serveur 22, -tiroir 46, -xss 9, -activation 6, cycle-serveur 9, git-e2e 3, direct 2, robustesse 3, lecture-fil 1, git-config-depot 1, transcript 1 | cause non consignée en un seul endroit ; la forme (cas « mutant sans effet », sortie sans le code de P) est celle de suites encore jouées contre une sortie copiée et non contre le module (79-06 6a et 6b) ; le run 43204048840 les voit vertes sauf tiroir |
| 43197982172 | mêmes suites + amorce-navigateur 1, responsive 1 | idem ; amorce-navigateur et responsive : non consignées |
| 43204048840 | transcript 1, lecture-fil 1, terminal-tiroir 46, git-config-depot 1, git-e2e 3 (quatre shards annulés) | tiroir : non consignée ; lecture-fil : D8.9 ; git-config-depot : M-VIDE-ECARTE |
| 43207401307 | lecture-fil 1, terminal-tiroir 46, git-config-depot 1 | idem |
| 43221298898 | sante 23, ecrans-recent 6, equipe 1, lecture-fil 1, responsive 1, git-config-depot 1 | sante et ecrans-recent : harnais vm sans traducteur (79-10), corrigé 0f66728c ; lecture-fil : D8.9, corrigé 3ad2f28f ; equipe : E23.4, intermittent ; git-config-depot : M-VIDE-ECARTE ; responsive : non consignée |
| 43281029174 | sante 23, equipe 1, lecture-fil 1, git-config-depot 1 (un shard rouge sans ligne extraite) | idem |
| 43293707882 | ecrans-recent 6, sante 23, equipe 1, lecture-fil 1, git-config-depot 1 | idem |
| 43300355064 | equipe 1, lecture-fil 1, responsive 1, git-config-depot 1 | lecture-fil l. 5338 : même cas D8.9 ; git-config-depot : M-VIDE-ECARTE |
| 43336702553 | equipe 1, git-config-depot 1 | M-VIDE-ECARTE : le 6e jeton dépend de git 2.56 du runner contre 2.50 du poste, masqué par 721b8f40 (raison écrite dans la suite) |
| 43342613636 | equipe 1, who 1, retard 1 (collecte 27 dans un shard annulé) | equipe, who, retard : non consignées (sondes sous charge, jugées vertes au rejeu seul : à vérifier) ; collecte : run annulé |
| 43345371712 | git-config-depot 1 (shard 8) | M-VIDE-ECARTE, corrigé 721b8f40 |
| tête 0a25743 | M-VIDE-ECARTE seul | connu, corrigé 721b8f40 |
| tête e4185ff1 (shard 6) | lecture-fil D8.9 et D8.9b | `cockpit-state@1` (79-12, 4cfa3c5d) absent de la liste fermée ; corrigé 99299905 (voir Leçons, n° 2) |
| tête f07c8801 (shard 4) | terminal-activation M-ECOUTE0 | intermittent : course sur `server.json` réécrit après « prêt » (empreinte publiée différente, `pgrep` à PID vide) ; corrigé 2fba54d4 et 547cbc45, sans lien avec e3dbbe8a |
| tête a2ef07c8 (shard 5) | T28-F, responsive R15c.2 | T28-F : externe au segment (gsd-core 1.21.0 publié le 2026-11-13 à 04:13:53 UTC, index versionné en 1.15.0), correctif repris par cherry-pick `-x` de `c64f9e2b` (PR #239, brouillon, non fusionnée) pour que la tête finale soit verte ; R15c.2 : défaut de la sonde, intermittent en CI (4 runs sur 15), corrigé f7214e6b et a821e66b (origine aa071452) |
| 43402693393 (tête 7ef2594c) | aucune | VERT de bout en bout |

Correction du 2026-11-13 (jointure J1) : R15c.2 a rougi dans TROIS runs (43197982172, 43300355064, 43384769046), non dans « 4 runs sur 15 » comme l'écrit la ligne de la tête a2ef07c8 ci-dessus ; l'erreur venait d'un premier message de la session principale, rectifié ensuite. La ligne d'origine est laissée telle quelle.

Causes élucidées depuis la première version de ce tableau :
- D8.9 cockpit-state@1 : 99299905 ; la lecture-fil de 79-08 (D8.9, `cockpit-index@1`) : 3ad2f28f.
- M-VIDE-ECARTE : 721b8f40 (git 2.56 du runner contre 2.50 du poste).
- M-ECOUTE0 : intermittent, course de `server.json` réécrit après « prêt » (2fba54d4), sans lien avec e3dbbe8a.
- R15c.2 : défaut de la sonde (`chrome-panneau-etroit.mjs` lisait `textContent`, « PhasesPhases », et tapait avant que le
  focus soit posé, `setTimeout(0)` du viewer), corrigé f7214e6b et a821e66b ; origine aa071452 (recette du lot B). Note
  produit pour le registre : une frappe envoyée juste après « / » est perdue (`setTimeout(0)`).
- T28-F : externe au segment, voir la ligne de la tête a2ef07c8. Limite connue : le poste porte gsd-core 1.20.1, donc T28-F
  rougit en local et passe en CI.

Sautés et instables connus de CI hors liste : KC2 de `test-check-method-budget.sh` (Ubuntu 26, `mkdir` non exclusif), LB.E11 à
LB.E14 de lancer-bandeau, délai de terminal-tiroir (600 s en scénario `--terminal`, 1 184 s en CI).

## « Préexistants » rejoués contre la base

Source : journal du manager, rejeu de quinze « préexistants » cités, une suite à la fois sur `da64eb8c`, arbre détaché ;
journaux hors dépôt (dossier du nœud de rejeu). Résultat : aucun rouge sur la base.

| Cas cité « préexistant » | Où | Verdict base da64eb8c | Verdict tête | Qualification |
|---|---|---|---|---|
| FB3.5 (securite) | 79-02, 79-05, 79-06, 79-07 | vert | vert | rouge de charge, mal nommé (la sonde mesurait la machine ; FB3.7 à FB3.9 la remplacent) |
| S6.1 (git) | 79-05 | vert | vert | rouge de charge |
| X6.2 (git-details) | 79-07 | vert | vert | rouge de charge |
| W24.3, W24.4 (who) | 79-02 | vert | vert | rouge de charge |
| R15c (responsive) | 79-02 | vert | vert | rouge de charge |
| TH.9, TH.14, T21.13 (terminal-tiroir) | 79-02 | vert | vert | rouge de charge |
| H3.16 à H3.18 (cycle-serveur) | 79-02 | vert | vert | rouge de charge (sondes d'horloge) |
| Q11.2 (questions) | 79-06 | vert | vert | rouge de charge |
| H5.1b (git-entete) | 79-06, 79-10 | vert (136/0) | rouge avant 9d8fb831, vert après | RÉGRESSION de 79-07 (c8a009df : git absent rendu en délai), corrigée 9d8fb831 |
| D8.9 (lecture-fil) | 79-06 | vert | rouge depuis 209c50aa, vert après 3ad2f28f puis 99299905 | RÉGRESSION de 79-08 (liste fermée non réarmée), puis de 79-12 (cockpit-state@1) |

Autres écarts constatés à la tête pendant l'exécution de 79-11 : Q11.7.1 à Q11.7.3 (copie mutante sans le module
navigateur), terminal-tiroir TP.3 et M-MSG-DONNEE : signalés et corrigés par le plan. H7.5b : jouée seule trois fois
(tête avant correctif, tête après, base) : verte ; non reproduite. Condition connue du rouge : lancement sous charge.
Rejouée au calme sur la tête 7ef2594c (charge de l'ordre de 4) : git-entete 136/0, H7.5b PASS.

## Cas SAUTÉS en CI Linux et verdict sur le poste

| Suite | Cas | Raison du saut | Verdict joué seul sur le poste | Preuve ailleurs |
|---|---|---|---|---|
| projet-visite | O6.17d, O6.19 | polices DejaVu absentes (`saut=2`) | SAUTÉ aussi sur le poste : les polices manquent et `VF_DEJAVU_DIR` n'est pas posé ; aucun verdict positif | aucune preuve retrouvée dans ce segment : le cas est compté sauté, pas réussi ; à lever en posant les polices |
| git-commandes | C1.2 | zsh | PASS sous zsh (git-commandes 57/0, tête 7ef2594c) | |
| git-entete | H5.1b | git non masquable sur le runner | PASS : git-entete 136/0 sur la tête 7ef2594c (et 79-07, correction n°2 ; 79-09, tête 8ba5260e) | témoin unitaire D10.1 à D10.3 et M-ABSENT dans git-config-depot, qui tourne en CI Linux (PATH sans git) |
| serveur | PS.11 | casse du système de fichiers Linux | PASS : serveur 98/0 (tête 7ef2594c) | |

Verdicts joués seuls sur la TÊTE 7ef2594c (nœud final-verif, charge de l'ordre de 4, journaux hors dépôt) : git-entete
136/0 (H5.1b et H7.5b PASS) ; git-commandes 57/0 (C1.2 PASS sous zsh) ; serveur 98/0 (PS.11 PASS) ; projet-visite 115/0
avec O6.17d et O6.19[dejavu] sautés aussi sur le poste (polices DejaVu absentes, aucune autre preuve : ces deux cas ne
sont pas des verts) ; dev-orchestrator 489 réussis, 1 échoué, 0 sauté, l'échec étant T28-F seul (le poste porte
gsd-core 1.20.1, publié 1.21.0) ; les 21 étapes de `gates` jouées rc 0.

## Contrats fournis aux autres phases

- `VENDORED.txt` en AJOUT (8cb2a0fe) : une ligne `AJOUT <chemin>` par fichier, tri C, insérée à sa place, jamais en fin ;
  en conflit sur `amont/`, garder la suppression.
- `socle-serveur.sh` (9759bef3) : `cockpit_lancer` (codes 0 à 4 figés ; 5 si l'empreinte du module n'est pas publiée),
  `cockpit_arreter`, `cockpit_get`, `attendre`, `cockpit_lancement_brut`. `cockpit_module_muter_p` (79-11) pose un
  mutant sur le code navigateur rangé ; `cockpit_module_muter` en pose un seul.
- `cockpit_module_copie [destination]` (9ea86a3c, amendement de revalidation B1 ; la fonction elle-même vit dans
  81168f4f) : copie COMPLÈTE du module, jamais de lien, chemin absolu sur la sortie standard, rien d'exporté. Consommée
  par les Phases 74 et 80.
- Table des routes (f397986e) : une ligne de `ROUTES` à sa place alphabétique, le chemin dans la liste de RK.1 de
  `test-cockpit-routes.sh`, RK.1 rouge avant, PASS RK.1 et RK.7 après ; annotateurs de même (contrat A54).
- Interface `vibeflow/cockpit-index@1` (209c50aa) et `vibeflow/cockpit-state@1` (4cfa3c5d) : schémas au contrat de
  forme ; la liste fermée des schémas qui interdisent `fil` est à six (99299905) et se réarme à chaque schéma neuf.
- Règle des chaînes d'interface : toute chaîne neuve s'écrit `t('texte anglais')` avec son entrée dans
  `79-vf-fr-dict-b.js`, contrôlée par `node plugin/cockpit/scripts/vf-cockpit-fr-sources.mjs <fichier>`. La porte voit
  aussi `fail(` et `reject(` (`LIGNE_MESSAGE`). Les messages du serveur restent en français sous `?lang=en` (A43).
- Cliquet de colonnes (79-11, 1fe872b8) : périmètre `scripts/*.mjs`, `skills/cockpit-moteur/assets/ui/**` ; baseline à
  93 fichiers et 1 679 lignes longues ; une baisse se suit par `abaisser`, une hausse se replie, jamais de relèvement
  sous délégation. Tout code navigateur neuf s'inscrit dans `FICHIERS_NAVIGATEUR` (liste close, douze fichiers) et en
  `AJOUT` de `VENDORED.txt`, 0 ligne de plus de 160 colonnes.
- `arbreDe` est OBLIGATOIRE pour tout appel d'`index.mettreAJour` et pour 79-09 : un appel sans lui est refusé.
- `cheminPhysique(chemin, { plusProcheParent })`, export de `vf-cockpit-git-sortant.mjs` (copie octet pour octet dans
  le moteur), signature figée par G17 ; consommateurs : 79-13 (A23) et 79-16 (A37).
- Format `ECART-ADMIS` de la parité F22 : deux côtés (écart admis, côté de la table et côté de l'émission).
- Registre et plan publiés : `registry [--all]` et `publish-plan` (formes JSON exactes au SUMMARY de 79-03) ; événement
  `lock` et `hello.lock` sous la forme `{ seq, at, verrous }` (CHANGEMENT DE FORME visible de tout lecteur du flux).
- Route d'état `GET /api/vf/state` (79-12) : enveloppe `cockpit-state@1`, événements `vie` et `etat`, aucun n'avance
  `seq` ; règle d'ajout d'un événement sans contenu au SUMMARY de 79-12.

## Ce que la Phase 80 et la jointure doivent savoir

Pour la Phase 80 : signature de `cockpit_lancer` stable ; les suites ne lisent plus de code dans la sortie (un mutant se
pose sur une copie du module) ; toute sortie copiée vit sous `<lab>/.vibeflow/cockpit` ; le script du tiroir est
`assets/ui/tiroir/tiroir.js`, le client et la vue de Q sont sous `assets/ui/terminal/` ; `serve.mjs` refuse un dossier de
scripts ou de moteur désigné sous `<lab>/.vibeflow`.

Pour la jointure :
- `check-machine-paths.sh` ne voit pas un chemin du poste découpé en segments ou en chaînes séparées (cas réel du relevé
  `79-10-RENDU-AVANT.json`, commit 71ba0179 non réécrit sur décision de la session principale). Limite du gate, à
  inscrire au registre. Contrôle ajouté : `79-10-CONTROLE-CHEMINS.mjs`, témoin rouge prouvé.
- `who.sh` l. 682 et le libellé du cas M-W23-IFACE exécutent du shell (un titre est évalué) ; même forme que
  W23.15 : à corriger par le propriétaire du plan.
- L'aide commune des suites doit créer ses dossiers par gabarit complet (`mktemp -d "$TMPDIR/nom.XXXXXX"`, un `mktemp
  -d` nu ignore `TMPDIR` sur macOS) et les retirer à la sortie, même tuée : plus de 11 Go ont été retirés d'une nuit.
  Constat de socle de test (79-02, 79-11), à planifier ; 30 suites utilisent encore `mktemp` nu.
- Replis lexicaux d'affichage, jamais lus par une garde : `vf-cockpit-git.mjs`, `vf-cockpit-git-entete.mjs`,
  `vf-cockpit-who.mjs` (79-09 et 79-22 touchent `who.mjs`, 75-01 et 77-04 touchent `git.mjs`) : à verser au registre.
- Constats bas renvoyés : `serve.mjs:42` clause morte ; paramètre inutile de `serveur-vivant:66` ; en-têtes de
  git-sortant rewrappés ; table `mod_de` recopiée dans 13 suites (candidate au socle) ; `build.mjs` jette son stderr
  (l'avis MAX_MOTIF reste invisible) ; `pageEquipe` ne rend pas `live.pret` (une page vide possible dans les premières
  secondes) ; `signal` relit le verrou par arbre en lab plat multi-arbres ; scripts amont non atteints (`open.mjs`,
  `refresh.mjs`, `claudemd.mjs`) candidats à un retrait de sobriété ; commentaires résiduels d'`ui/00-vibeflow.js`,
  `ui/01-vf-responsive.js`, `ui/02-vf-telephone.js` ; le motif `⊘|SAUTÉ` de 79-12 reconnaît « 0 SAUTÉ » à tort
  (git-signature) ; 51 entrées de table de traduction sans site d'émission (non supprimées).
- Dette de colonnes : vingt fichiers les plus chargés au SUMMARY de 79-11 ; travail séparé de repli à proposer.
- Instabilités mesurées : terminal-tiroir 1 138 s isolé, dominé par les mutants Chrome ; lancer-bandeau LB.E11 non
  reproduit, hypothèse (le client n'émet l'annulation qu'au premier sondage et seulement si le terminal est prêt) hors plan.
- FB3.5 : la borne de 10 s mesurait la machine (≈ 480 lancements de processus de `revealDoing`) ; les
  lancements ne sont PAS réduits (amélioration produit, au registre).

Limites connues, écrites et non fermées :
- Asymétrie `binaire` (79-07) : aucun appelant de production ne passe `binaire` ; vérifiable par
  `rtk proxy grep -rn "binaire" plugin/cockpit/scripts` ; D10.7 et M-BINAIRE la tiennent côté lecture.
- Écarts d'étiquette `absent` : ENOENT d'interpréteur ou de dossier courant, exception synchrone d'`execFile` (l. 84)
  rendent un libellé de refus différent d'« absent » ; sans effet de sécurité (no-op documentés).
- S1 et S2 d'`estNotre` (branche ancienne ; PID et port non liés) : hypothèse d'un poste mono-utilisateur.
- Identité avec espace dans le chemin du module : refus fermé, `stop` et `--rebuild` rendent le code 5.
- F2 résiduel : un appelant qui pollue son propre environnement n'est pas couvert (forme étroite acceptée) ; au registre.
- Écart de périmètre d'exécution : x12 et fix2-x06 ont rejoué leurs suites dans le MÊME arbre pendant que l'autre y
  écrivait (la suite `etat` était rouge pour fix2-x06 à cause du chantier de x12). Ce qui vaut preuve : le rejeu final sur la
  tête commitée et la CI, jamais un rejeu en cours de chantier.
- Fichiers touchés hors déclaration `files_modified` et leur amendement daté : 79-06, `equipe` (d20f2157) et
  `git-signature` (a71a36be), amendement du 2026-11-12 « constat de la porte 4c », déclarés par 4c48d523 ; 79-10,
  `ecrans-recent` (fixture `ui-harness.mjs`) et `sante` (`sonde.mjs`), 0f66728c, amendement du 2026-11-12 « suites qui
  évaluent les extensions hors navigateur », et `responsive` (a2eaa458, b396af84), amendement du 2026-11-12 « suite
  responsive, décision du manager » ; 79-11, `questions` (cfaa7105), amendement du 2026-11-12, point (5). À l'inverse,
  79-11 déclare six fichiers qu'aucun de ses commits ne touche (`test-cockpit-lancer-serveur.sh` et cinq
  `vf-cockpit-terminal-*`) : aucun amendement daté qui le dise n'existe dans le plan ; rien n'est écrit à la place de
  l'exécuteur, c'est à noter à la clôture du plan.

## Leçons

1. **« Préexistant » mesuré contre la mauvaise ancre.** Quinze rouges nommés préexistants dans des traces et des
   SUMMARY : aucun ne l'était. Treize étaient des rouges de charge, deux des régressions du segment (H5.1b, D8.9),
   prises pour de l'ancien parce qu'elles étaient comparées à un instantané du même arbre déjà touché.
   Règle : un rouge ne s'écrit nulle part avant d'avoir été rejoué seul, et « préexistant » ne s'écrit qu'avec le sha de la
   base et le chemin du journal du rejeu. Les traces ont reçu une ligne datée de correction (56e13d83), sans réécrire
   l'ancienne.
2. **Le fil-piège qui échappe au grep de la règle 9.** Deux fois (D8.9 puis D8.9b avec `cockpit-state@1`), la suite
   rouge ne nommait pas le fichier modifié : un détecteur lit le contrat, pas le code. Règle : grep aussi les aides de test
   et l'identifiant de schéma, pas seulement le nom du fichier source.
3. **Exécuteurs délégués dont la notification se perd.** La fin d'un exécuteur de profondeur 3 arrive au head et non à son
   parent : 79-09 est resté arrêté environ 4 h 40 sans que personne le voie. Règle : relire le transcript du parent avant
   d'attendre, sinon relayer.
4. **Alertes de contexte partagées.** Les alertes « CONTEXT WARNING » mesurent la session principale, pas celle de
   l'agent : elles ne justifient aucun arrêt (règle 12 du mandat).
5. **Veille du poste.** Le poste a dormi de 13 h 52 à 19 h 29 le 2026-11-12 : tout verdict à cheval est nul, rejoué.
6. **Disque plein.** Un disque plein a produit des rouges sans valeur de verdict (ENOSPC) et coûté un arrêt des rejeux ;
   suites et profils Chrome laissaient des dossiers temporaires. Règle : `TMPDIR` sous le dossier du nœud, gabarit complet,
   purge à chaque nœud, arrêt sous 3 Gio libres.
7. **Docker démarré par un agent.** Un nœud (correcteur de M-ECOUTE0) a démarré Docker Desktop à 04 h 18 pour un rejeu
   Ubuntu, avec l'image existante et des conteneurs `--rm`, sans rien laisser derrière lui. Effet de bord : deux
   conteneurs d'un autre projet de l'utilisateur (dont une base de données locale) se sont relancés et sont restés
   en marche 3 h 30 ; la session principale a arrêté Docker à 07 h 49. Règle : aucun agent ne démarre Docker ni une
   application du poste sans demander. Ce même nœud a aussi lu l'arbre principal par `cd` (le `ci.yml` de `main`) :
   écart à la règle de non-incursion, signalé.
8. **Un cas sauté n'est pas un cas vert** : la liste des sautés se lit au journal d'un run et chaque cas se joue seul
   sur le poste ; préférer un témoin qui tourne aussi en CI (D10 pour H5.1b).
9. **Régression d'un déplacement de code** (79-07, 2026-11-12) : la liste des suites écrite dans un plan ne remplace
   pas le `grep -l`, rejoué suite par suite avant de dire une extraction verte.
10. **Nœuds suspendus sur une forme de commande.** Deux nœuds (suspendus 30 et 63 minutes) attendaient une autorisation
   que personne ne pouvait donner, sur des formes de commande à autorisation (message de commit en ligne, `cd` en tête,
   commandes chaînées). La session principale les a arrêtés le 2026-11-13 : un manager ne peut pas arrêter une tâche qui
   n'est pas la sienne, limite du harnais, à inscrire au registre. Règle (point 13 du mandat) : message de commit dans un
   fichier et `git -C <arbre> commit -F <fichier> -- <chemins>`, jamais de `cd` en tête, un rejeu contre une variante de
   suite sur une copie hors du worktree, une commande simple par appel. Repris par r15c2-fin et cliquet-fin.
11. **Un filtre sans ensemble positif se contourne par passes.** Le filtre de délégation du cliquet a demandé quatre
   passes (normalisation, classes Unicode, séparateurs, puis ensemble positif des seules lettres après NFKD) parce que
   chaque version listait ce qu'elle refusait au lieu de ce qu'elle acceptait ; chaque relecture fraîche a trouvé une
   forme neuve. La quatrième est la dernière : garde déclarative (ADR-072), limites écrites. Règle : décrire d'emblée
   l'ensemble qu'on accepte, et fixer à l'avance le nombre de passes.
12. **Le fil-piège D8.9 est passé deux fois sous la règle 9** (cockpit-index@1 par 209c50aa, cockpit-state@1 par 4cfa3c5d) :
   voir le n° 2 ; la règle n'a de valeur que si le grep nomme l'identifiant de schéma.
13. **Une constante qui dépend de la version de l'outil** (git 2.56 du runner contre 2.50 du poste, M-VIDE-ECARTE) rougit
   en CI seulement ; le rejeu local ne la voit pas. Idem T28-F (gsd-core 1.21.0 contre 1.20.1 du poste).

## Budgets

Calibration (recopiée, jamais recalculée ; jetons non mesurés au token près pour les autres plans) :
- 79-07 : environ 660 k jetons pour 190 k estimés. Le plan a pris une porte humaine, trois audits et quatre passes
  de correction ciblée (T-79-705, git absent, témoins D10, M-VIDE-ECARTE) ; ses suites (g16, génératives, mutants,
  suites de git rejouées une à une) ont été rejouées sous charge, puis à la reprise après le disque plein et après la
  veille.
- 79-09 : environ 1,5 M pour 340 k estimés. Quatre tâches inline, quinze mutants au lieu de treize, protocole de fil,
  un audit à constat moyen suivi d'une correction (759fd4bf), reprise après un exécuteur resté arrêté 4 h 40, suites
  lentes (collecte 6 à 7 min, Chrome) rejouées plusieurs fois par la règle 9.
- 79-10 : environ 830 k jetons (sans estimation portée au plan) : traduction de douze fichiers du moteur, un commit par
  fichier, parité F22, correction après rv-1021, et un relevé de rendu qui a dû être refermé par une classe de contrôle.

Lecture du manager à confirmer : les trois dépassements viennent surtout des constats d'audit et de revue acceptés comme
amendements (corrections ciblées, rejeux de la règle 9) et de suites lourdes rejouées sous charge pour obtenir un verdict propre.

Coûts de la sortie de segment (jetons non mesurés, nombres de passes mesurés) : le filtre de délégation du cliquet a pris
quatre passes de correction et quatre relectures fraîches (cliquet-fin à cliquet-fin4) ; 79-06 a eu trois correctifs
après audit (a50de579 et suivants, 2fba54d4, 547cbc45) ; 79-09 deux (759fd4bf, ded7daa3) ; 79-12 une (fix-x12, a2ef07c8). Deux nœuds suspendus sur des formes de commande ont perdu 30 et 63 minutes.

## Moins cher la prochaine fois

- Rejouer SEUL, sur la base détachée, avant d'écrire le moindre « préexistant » : un rejeu isolé évite deux régressions attribuées à tort et des traces fausses.
- Un grep de la règle 9 qui nomme aussi les aides de test et les identifiants de schéma.
- Une aide de test qui crée ses dossiers par gabarit complet et les retire à la sortie : évite un disque plein.
- Un témoin qui tourne aussi en CI Linux (chemin binaire inexistant, git absent), pas un cas sauté.
- Rejeu des suites lourdes (collecte, tiroir, responsive) une fois sur la tête commitée, pas à chaque tâche.
- Un seul écrivain par arbre au moment du rejeu final ; jamais de chantier non commité pendant un rejeu.
- Retirer les cas à constante dépendante de la version de l'outil (git 2.56 contre 2.50) avant le premier push.
- Poser les polices DejaVu sur le poste pour jouer O6.17d et O6.19 au lieu de les laisser sautés.
- Écrire les gestes de nœud sous des formes de commande qui n'appellent aucune autorisation (point 13 du mandat) : un nœud
  suspendu coûte une heure et une intervention de la session principale.
- Écrire dès la première version d'un filtre l'ensemble POSITIF accepté (lettres après NFKD), plus un nombre de passes
  fixé d'avance : quatre passes et quatre relectures auraient été une.
- Grep de la règle 9 sur l'identifiant de schéma d'interface avant d'ajouter un schéma : le fil-piège D8.9 est passé deux
  fois.
- Rejouer les cas à constante dépendante d'une version d'outil contre la version du runner, ou les retirer.

## Preuves E6

Verdicts relayés des retours typés cités dans le journal du manager et dans les SUMMARY, tels quels : commande
canonique de la suite concernée, code de sortie 0, sha du commit de sortie du plan ; les audits et revues, verdicts
sans commande rejouable, sont marqués `amont` et leurs sha cités au tableau des audits. Un verdict `gaps_found` n'est
pas un vert : il est écrit ici avec son sort.

Preuves du nœud final-verif (tête 7ef2594c, journaux hors dépôt) : six entrées, une par suite ou lot jouée seule, et le
run de CI 43402693393 de la même tête. L'entrée dev-orchestrator porte `exit_code` 1, vrai code de sortie : 489
réussis, 1 échoué, l'échec étant T28-F seul (gsd-core 1.20.1 sur le poste, 1.21.0 publié), qui passe en CI. Les
entrées projet-visite (`exit_code` 0, 115/0) comptent deux cas sautés faute de polices DejaVu (O6.17d, O6.19) : sauté
n'est pas réussi.

```json
{"preuves":[
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh","exit_code":0,"sha":"8cb2a0fe"},
{"verdict":"recette","commande":"bash plugin/conductor/scripts/tests/test-driver-lock.sh","exit_code":0,"sha":"18211865"},
{"verdict":"recette","commande":"bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh","exit_code":0,"sha":"3919655e"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-routes.sh","exit_code":0,"sha":"91af2123"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-serveur.sh","exit_code":0,"sha":"75bd3538"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-git-config-depot.sh","exit_code":0,"sha":"721b8f40"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh","exit_code":0,"sha":"9d8fb831"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-lecture-fil.sh","exit_code":0,"sha":"99299905"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-collecte.sh","exit_code":0,"sha":"759fd4bf"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh","exit_code":0,"sha":"a2eaa458"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh","exit_code":0,"sha":"1fe872b8"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-etat.sh","exit_code":0,"sha":"4b2b6d08"},
{"verdict":"recette","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-confinement.sh","exit_code":0,"sha":"1f1d2eeb"},
{"verdict":"audit","preuve":"amont"},
{"verdict":"revue","preuve":"amont"},
{"verdict":"gate:check-machine-paths","commande":"bash scripts/check-machine-paths.sh","exit_code":0,"sha":"906e3efe"},
{"verdict":"gate:check-version-sync","commande":"bash scripts/check-version-sync.sh","exit_code":0,"sha":"906e3efe"},
{"verdict":"gate:check-method-budget","commande":"bash plugin/conductor/scripts/check-method-budget.sh","exit_code":0,"sha":"906e3efe"},
{"verdict":"gate:check-divergence","commande":"bash plugin/conductor/scripts/check-divergence.sh --path .","exit_code":0,"sha":"906e3efe"},
{"verdict":"gate:check-state-integrity","commande":"bash plugin/conductor/scripts/check-state-integrity.sh --path . --file .planning/workstreams/fiabilite/STATE.md","exit_code":0,"sha":"906e3efe"},
{"verdict":"final-verif:git-entete","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh","exit_code":0,"sha":"7ef2594c"},
{"verdict":"final-verif:git-commandes","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-git-commandes.sh","exit_code":0,"sha":"7ef2594c"},
{"verdict":"final-verif:serveur","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-serveur.sh","exit_code":0,"sha":"7ef2594c"},
{"verdict":"final-verif:projet-visite","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-projet-visite.sh","exit_code":0,"sha":"7ef2594c"},
{"verdict":"final-verif:dev-orchestrator","commande":"bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh","exit_code":1,"sha":"7ef2594c"},
{"verdict":"final-verif:gates","commande":"gates du workflow de CI, 21 étapes jouées","exit_code":0,"sha":"7ef2594c"},
{"verdict":"ci-verte","commande":"gh run view 43402693393","exit_code":0,"sha":"7ef2594c"}
]}
```
