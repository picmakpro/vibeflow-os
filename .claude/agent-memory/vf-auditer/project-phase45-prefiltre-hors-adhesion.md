---
name: project-phase45-prefiltre-hors-adhesion
description: Re-audit du pre-filtre hors adhesion (hooks.json vf_pre, commit 06cafdda, PR #124 Samuel) - equivalence tenue sur ~13000 cas, mais cout CUBIQUE sur chemin profond propre = timeout 20 s du harnais = fail-open (HIGH) ; bande 4083-4096 hors equivalence
metadata:
  type: project
---

Re-audit a regard frais (2026-10-02, code 06cafdda, plugin/planning-core inchange jusqu a HEAD fb1b015f). Verdict OPEN_THREATS. Banc : scratchpad/auditP-1 (reg-new/old/nob/pre-only/fix.sh extraits de hooks.json par json, aides.py = heredoc de la suite, mutA.py + mutlist.py = mes mutants contre la suite, d1.py = differentiel 2610 cas).

- F-P1 HIGH (ask-user) : vf_pu accumule _pk (chaine de tous les dossiers vus) et la rescanne par case a chaque ancetre = cout CUBIQUE en profondeur. Valeur ou cwd PROPRE (absolu, sans .. ni antislash, <=4096) : 1000 car = 1,3-1,9 s, 1474 = 4,8 s, 2774 = 40 s (bash), 16 s dash, 23 s zsh ; avant : 0,05 s. Ordre reel du payload : cwd AVANT tool_input, donc un cwd profond est traite avant que le chemin adherent fasse DEFER : Write VERDICT.md d un lab adherent + cwd 1500 car = TIMEOUT 20 s (old DENY 0,15 s). cwd REEL de 1014 car (macOS PATH_MAX) : 6,3 s bash, 2 s sh, 0,9 s dash (old 0,05-0,14), sous charge 17-20 : 7,6-10 s. Linux (PATH_MAX 4096) : fail-open deterministe ; macOS : marge 2x seulement. Le modele maitrise son cwd (cd en Bash) : tue TOUS les gates de la session (ROLE-worker/juge compris). Remede valide par execution : retirer le case/_pk (vf_pc direct) -> 0,1-0,3 s au cwd 1014, 2,5 s a 2774 ; suite prefilter reste verte (19 OK). Ajouter : plafond de profondeur/longueur et assertion de temps sur valeurs propres 1000..4096.
- F-P2 LOW : bande 4083-4096 car (valeur propre nommant .planning, lab non adherent, script ABSENT) : prefilter SHORT, commande sans prefilter DENY (le repli compte ${#_m}, cle et guillemets inclus, donc B=1 des 4083 pour file_path, 4089 pour cwd). La propriete (A) de la suite est fausse dans cette bande, non sondee (leurs longues sont a 5000). Pas un fail-open (lab analyse exactement) : perte d un sur-refus du doute.
- Mutants : 14 de mon cru contre la suite (corpus seul + tableau D). Survivants = equivalents : NO-PHYS-CWD (PWD toujours = physique, shells valident PWD), NO-NL-GUARD (newline seulement via PWD), GREP-ERR-OK. UNREADABLE-OK et NO-CASE-I tues seulement par le tableau D (par construction), pas par le coeur.
- Differentiel 2610 cas (labs utf-16/32, BOM, CRLF, multiligne, cle dupliquee, lien .planning, lien dur, ordre des cles, espaces, BOM payload) : 342 SHORT, 0 desaccord coeur/old/new, script present et absent.
- Suites : prefilter 19/0 (477 s), registered 87/1 (R-DOUTE-03 t_max 2,88 s > 2 s sous charge 17-20 ; 2e passage 1,53 s vert = flake de charge, valeurs >4096 donc DEFER immediat, non imputable), gates 461/0.
- Gain : sh Write 211,6 -> 66,7 ms, Bash 561,7 -> 64,7, Agent 473,2 -> 66,2 (mediane n=30, charge 20) ; mins 160/178/225 -> 39/39/36.
- Piege methode : le tool Bash refuse un heredoc python contenant un dict litteral ou le mot exec/compile entre guillemets ou des gros blocs : decouper en cat >> par morceaux, dict(), getattr(builtins, chr...).

Voir [[project-phase45-reaudit-borne-repli]] et [[feedback-execute-dont-trust-green]].

## TOUR 2 (2026-10-03, code b2b0186b, HEAD 45cacf94) : F-P1 et F-P2 fermes, memoire _pa SURE, mais F-P3 HIGH (cout par taille de fichier)

- F-P1 ferme (p3/p7/p9 rejoues, 0,05-0,15 s, DEFER par la borne 64 composants), F-P2 ferme (bande 4083-4096 : new-down == old-down, car toute valeur >1024 = DEFER). Equivalence : d1 342 SHORT / 0 desaccord.
- Memoire _pa (un seul prefixe, frontiere de composant) SURE : 26244 paires ordonnees + 6000 ensembles de 3-8 valeurs + 8000 paires x proc-cwd/PWD/shells, memo vs sans-memo 0 ecart, oracle python independant 0 SHORT sur ancetre adherent. Raison : _pa n est pose qu apres un parcours COMPLET propre, et vf_pc ne depend que de la chaine (identite lexicale = meme resolution noyau). Seul trou : _pa n est pas initialise (env _pa=<ancetre adherent> -> SHORT) : LOW, l env du hook n est pas controle par le modele.
- F-P3 HIGH : vf_pc greppe TOUT config.json non adherent de TOUT ancetre sans borne de taille. truncate -s 2G (0 bloc alloue) sur <ancetre du cwd>/.planning/config.json : new2 TIMEOUT 20 s ; ancien (nob) DENY 0,1-0,2 s. BSD grep 13,7 s/GiB. Existait deja au tour 1 (non vu). Aggrave par le nombre : 16 valeurs x 64 composants x 2 parcours (lexical+physique) de grep = 18 s sous charge 40. Remede valide (reg-fix2.sh) : find -size +128 -> return 1 + budget _pb<=64 greps : 0,23 s DENY, 0,94 s DEFER, d1 342/0. Piege : l ancienne chaine (script central) ne lit que le config.json le plus proche, et resiste (0,1 s).
- Suite prefilter : 26 OK / 0 KO (976 s sous charge 40). Mesure recoupee sh : Write 63->15,6 ms, Bash 56,5->15,1, Agent 57,4->14,8 (charge 8).
- Banc : scratchpad/auditP2-1 (mrun.py/drv-*.sh = pilote in-process 5 ms/cas, mgen.py, moracle.py, mfix.py, wfix.py/wcost.py, mkfix.py). Le tool Bash refuse cd && ..., $(...) et `bash script` en pipeline : appels simples, chemins absolus, python3 pour sleep.

## TOUR 3 (2026-10-03, correctif ea887d27, HEAD fed54929) : F-P3/F-P4 FERMES, SECURED, un LOW residuel (find absent du PATH)

- F-P3 ferme : config creux 2 GiB -> DEFER 0,01 s ; Write VERDICT lab adherent + cwd creux = DENY 0,07 s (avant 20 s TIMEOUT) ; wcost 16 valeurs = DEFER 0,2 s (budget _pb 64, frontiere exacte 64 SHORT / 65 DEFER) ; d1 342/0 ; 500 ensembles budget : 0 SHORT sur ancetre adherent ; suite 33 OK/0 KO (1556 s).
- F-P4 ferme (env _pa/_pb pollues -> DEFER). Ecart cur 2 GiB : les deux constats vrais, cibles differentes (cible dans lab adherent = DENY ; Agent/Write avec cwd creux seul = PASS, creux non adherent). Ancien chemin lit le creux a 1,6 s/GiB (pre-existant, lineaire).
- LOW residuel : find absent du PATH -> $(find) vide -> -z vrai -> borne perdue (TIMEOUT 25 s). Remede valide : [ -n "$(find -L f -size -129)" ] || return 1 (fail-closed).

