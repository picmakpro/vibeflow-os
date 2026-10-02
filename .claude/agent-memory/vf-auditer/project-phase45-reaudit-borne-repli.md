---
name: project-phase45-reaudit-borne-repli
description: Re-audit Phase 45 (hook planning-core, HEAD 699ee250) apres correctifs F-01/F-02/F-03 - F-02 et F-03 fermes par execution, F-01 ferme pour la lenteur mais sa branche valeur>4096 decide sur le cwd rouvre un contournement Write-seul (surrogate isole ou NUL fait tomber le coeur) ; limite (ab) probablement exploitable (Read accepte ~)
metadata:
  type: project
---

Re-audit a regard frais (mission vf-dev-manager-p45-exec, 2026-10-01, HEAD 699ee250 apres 0f8f2946). Verdict OPEN_THREATS.
Sondes : scratchpad/auditR-1 (r1..r12.py, lib.py repris de auditF-1) + recoupement gsd-security-auditor (auditR-gsd).

- F-03 FERME : balayage du minuteur 7.90-8.10 s = seulement rc 0 ou rc 73 stdout vide, jamais 142, aucune decision perdue ; echeance 8 s toujours operante avant emission.
- F-02 FERME : 20 contenus (tab, CRLF, CR seul, VT/FF/NBSP, BOM, cle dupliquee dans les deux sens, echappements, U+2028, NEL, ligne de 3 Mo) : aucun contenu admis par G6 et non reconnu par le repli. Piege de methode : une batterie stateful desarme le lab des qu un contenu est ecrit, remettre le config.json adherent avant chaque cas.
- F-01 lenteur FERMEE : 40 Ko en 0.02 s (23 s avant) ; pire cas sous la borne 1.3 s (lien symbolique l vers point, 1958 fourches) ; sh/dash/bash identiques ; payload 20 Mo sous 1 s.
- F-01 REGRESSION (HIGH, ask-user) : branche K=long = silence si cwd non adherent. os.path.realpath leve UnicodeEncodeError (surrogate isole) ou ValueError (NUL) sous Python 3.14 -> phase A de main() sort 3 -> repli. Chemin lab + 2100 fois point-barre + surrogate-barre-point-point + .planning/STATE.md, cwd hors lab : full=PASS. L ancien hooks.json (eb8165e4) refusait par doute PX=0. Python 3.9.6 ne plante pas. Reste conditionne a la normalisation lexicale du harnais (non mesuree). La limite (aa) dit conditionne a une panne du coeur : fausse, le payload provoque la panne. Remede : K=long refuse sans condition de cwd (ou si la valeur contient .planning) ET coeur robuste (realpath dans un try).
- (ab) : precondition ecrite = Write exige un chemin absolu. Le Read du harnais accepte un chemin avec tilde et un chemin relatif. p17 reproduit au niveau hook : poche pose sous cwd/~/lab/.planning creee par 2 Write, puis ~/lab/.planning/STATE.md PASS (et script du hook). A mesurer par la session principale avec un Write inoffensif.
- Nit doc : poser-verdict.sh l.14 et l.364 disent encore que la tentative est calculee par la commande.

Voir [[feedback-execute-dont-trust-green]] et [[reference-rtk-proxy-quirks-vibeflow-os]].

## Tour 2 (2026-10-02, HEAD 24b58748, code hook = a4afbe3f) - OPEN_THREATS (MEDIUM)
- N-01 surrogate/NUL et N-03 tilde FERMES par execution (banc auditR2-1 : 785 cas coeur sain old/new = 0 diff ; 740 cas coeur absent = 0 diff ; tilde x 14 HOME x 4 shells coherent).
- RESIDU NEUF (MED) : la garde G du repli grep -i '[.](planning|claude)' lit l'extrait BRUT : `\u002eplanning` ou `.plann\u0069ng` l'esquive. Coeur induit en panne par le seul payload : L + 'a/'*N + '../'*N + '\u002eplanning/STATE.md', N>=~105000 (~520 Ko, ~8 s, rc 73, quadratique) -> cwd non adherent -> PASS. Litteral = DENY. Non couvert par R-DOUTE-01 ; texte (aa) et 'revient a (a)' faux. Exige normalisation lexicale du harnais (non mesuree).
- Remede propose : valeur longue contenant un antislash refusee dans le repli ; et/ou coeur : len>4096 -> decider_dans_le_doute avant realpath.
- LOW : `~notes.md` relatif en lab adherent passe de CTX a DENY ; `~root/.planning/x` en lab dev DENY ; cwd '' -> silence ; HOME='/' coeur ok / shell doute.
- Piege methode : le tool Bash refuse les heredocs python avec dict/json.dumps contenant tool_input ; construire le JSON par concatenation.

## Tour 3 (2026-10-02, HEAD 079e905f, code 19d9c32d) - classe N2-01 FERMEE pour tout chemin qui NOMME un actif ; residus LOW
- Banc auditR3-1 (reg-old/new[-down].sh extraits de hooks.json via git show, lib3.py, s1..s11, fz2.py). Temoin : old N=130000 + `.planning` = PASS (8,18 s), new = DENY 0,05 s.
- 1056 cas (11 orthographes, 4 formes de remplissage, coeur sain/absent, 4 cwd) + 40 longueurs 4070..4109 x 3 noms x bash/sh + 1800 cas fuzz (graine 777) : 0 non-deny sur valeur decodee >4096 ; zsh et dash identiques. Differentiel old/new sur 2128 cas courants : 0 ecart.
- RESIDU declare mais REGRESSIF : valeur >4096 sans nom ni antislash atteignant un actif par lien prealable (`lab/pl -> .planning`), cwd plain/dev : old DENY (le coeur sait resoudre jusqu'a ~200 Ko en <1,4 s), new PASS (coeur ET repli). L'aiguillage tout-ou-rien jette l'analyse exacte. Remede : analyse exacte bornee par budget (ou jusqu'a ~64 Ko), doute au-dela.
- INFO : cwd >4096 remplace par getcwd inverse la precondition pour un chemin RELATIF (cwd lab long + `../`x1100+.planning/STATE.md, process hors lab : old DENY, new PASS ; l'inverse = faux refus GATE-03). Inatteignable : PATH_MAX, Write exige un absolu. Aucun mutant sur le marqueur `cwd-long` ; le test de la suite ne distingue pas le mutant (le mutant est plus sur).
- Suite registered : 74 OK, 75 s au repos, 160 s avec 16 brûleurs CPU ; t_max R-DOUTE-03 0,19 s / 0,40 s (plafond 2 s) -> flake faible. Suite gates 457 OK (231 s).
- Piege methode : le tool Bash refuse un heredoc python contenant un dict litteral avec chemins `.planning/...`, ou `\uXXXX` litteral : assembler par concatenation avec chr(92). Un merge de main a ete lance par un autre acteur dans le worktree pendant l'audit (UU README.md etc.), planning-core intact vs HEAD.

## Tour 4 (2026-10-02, HEAD cdf96c42, code 1d9425f7) - N3-01/N3-02 FERMES ; aucun CRITICAL/HIGH ; residus MEDIUM/LOW
- Banc auditR4-1 (core_*.py extraits par awk du heredoc, reg-{v0,v1,new}[-down].sh via hooks.json par git show dans un script python, lib4.py, orac*.py oracle = jumeau court de normpath(valeur)). Suites rejouees : registered 82/0 (245 s), gates 457/0 (256 s).
- resoudre_lineaire vs realpath : ~140 000 chemins aleatoires (Python 3.14 et 3.9.6) : seuls ecarts = boucles de liens / plafond 40 (realpath s arrete au 1er repeat, le coeur apres 40 liens) ; tous ELOOP au noyau (macOS 32, Linux 40) donc inatteignables, et les gates refont realpath(forme). Une valeur >4096 n est de toute facon JAMAIS atteignable brute (PATH_MAX 1024 macOS / 4096 Linux : ENAMETOOLONG) : seule la forme reduite lexicalement (Node path.resolve) compte ; la forme physique est surabondante.
- Differentiel 3 versions : 573 cas courts byte-identiques v0/v1/new ; ~1500 cas longs (liens, lien dur, juge, ext/.., cyc/.., //, ./, relatif) : new jamais moins strict que v0, jamais sous le jumeau de la forme reduite. Agent/Task : 56 cas identiques sauf cwd >4096 (inatteignable). Fusion multi-forme (deux labs adherents, adherent+non adherent, juge) : DENY > CTX > PASS correct.
- LOW N4-01 : chemin RELATIF + cwd >4096 REDUCTIBLE + lien/lien dur non nomme : v0 et v1 DENY, new PASS (ValueError sans ancetres, doute lit le cwd reduit). Inatteignable (cwd = physique harness, sans `..`).
- MED N4-02 (PREEXISTANT, tous versions, NON DECLARE) : macOS /.vol/<dev>/<inode du dossier .planning>/STATE.md (lstat de /.vol/<dev> echoue, racine_lab tombe hors lab) PASS pour G6/G5/verdicts ; ecriture reelle via /.vol verifiee. Bash ouvert (P45-D-10) donne le meme pouvoir -> pas HIGH. Remede : refuser tout chemin /.vol/ (ou doute).
- Preexistants confirmes declares : (af) lab/ext/../.planning/STATE.md court = PASS (long = DENY, discontinuite a 4096) ; surrogate/NUL annule par .. + lien non nomme + cwd hors lab = PASS court ET long (N2-04).
- Nits doc : docstring resoudre_lineaire dit realpath laisse le lien en place au plafond 40 (faux : realpath detecte la boucle au 1er repeat) ; (ai) cle dupliquee : le coeur lit AUSSI la premiere (_premier_gagne), pas seulement le repli ; (ak) Python 3.9.6 mesure ici : meme verdicts.
- Piege methode : le tool Bash refuse un heredoc python avec dict litteral {"PASS":0..} ou un `cd && cat > heredoc` ; ecrire le fichier seul (chemin absolu) puis lancer en 2e appel.
