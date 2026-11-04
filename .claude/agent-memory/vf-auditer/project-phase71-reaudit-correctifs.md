---
name: project-phase71-reaudit-correctifs
description: Re-audit ciblé Phase 71 (terminal cockpit, code 502b354b, 2026-11-04) — F1-F8 fermés par sonde avec témoin rouge ; reste un mineur (aperçu du collage tronqué à 200 car.) et des pièges de sonde
metadata:
  type: project
---

Re-audit 2026-11-04 du lot de correctifs (227be6c5..502b354b), arbre extrait par `git archive` dans le scratchpad (`reaudit-71/new`, ancien `old`, mutants `mut/*`).

**Fermé, sondé avec témoin positif ET mutant rouge** : F1 (lanceur n'ouvre qu'un port validé sur un PID `estNotre` ; deux couches indépendantes, sonde `pf1`/`pf1b`), F6 (argv sans amorçage, page 0600 `wx` + unlink, expiration serveur 60 s, balayage réel 60 s, redirection `file://` jouée dans Chrome), F3 (`resoudrePython3` absolu), F4 (popup/onglet seul = « Terminal indisponible », 0 shell), D-28 (nohup/disown/&/sous-shell morts, setsid et leurre hors session survivent ; relecture getsid avant chaque kill), D-24 (3 mutants rouges), Q1/Q2/Q5/Q7/Q10 + socle 67 (CSP de P identique).

**Ouvert** : N1 mineur — le bandeau de collage n'affiche que 200 car. (une ligne, ellipsis CSS ~30 car. visibles) : une charge au-delà est ABSENTE du DOM du bandeau mais exécutée après « Coller » (bash 3.2). La confirmation est donc partielle ; README dit « affiche le texte ».

**Pièges de sonde à garder** : (1) les sondes de la 1re passe naviguent Q en premier niveau → elles ne marchent plus (F4 ferme exprès) : héberger Q dans le tiroir de P (`ouvrirTiroir` + `iframe.focus()`). (2) l'ouvreur factice doit être ATTENDU (spawn détaché, relire argv après ~1,5 s) sinon les cas se contaminent. (3) un mutant sur un site de `getsid` ne suffit pas : il y a deux sites (membres + envoyer_membres). (4) mutant « verifierSortie neutralisé » : `assembler` le rappelle ; tester la couche en voie de réutilisation du serveur. (5) zsh : plusieurs lignes tapées d'un coup se mélangent (zle) → `source fichier`. (6) zsh avec jobs : `exit` deux fois. (7) monkeypatch de `os.kill` dans un test python casse `Popen.wait`. (8) `bandeau()` doit être vidé entre cas (Échap) sinon attribution fausse.

**Ajouts après recoupement gsd-security-auditor** : (a) il classe N1 (aperçu tronqué) MAJEUR, moi mineur — filet = clic humain + bash<5.1 seulement (zsh/bash>=5.1 montrent le texte avant Entrée) ; désaccord à signaler au manager, pas à trancher seul ; aperçu non neutralisé en bidi (sondé : U+202E inverse l'ordre affiché). (b) N2 sondé par moi : F3 n'est fermé que pour python3 ; `open`/`xdg-open`/`ps` du lanceur résolvent encore par PATH dans le cwd du lab (PATH=. → `<lab>/open` exécuté). (c) M7 de la 67 (jeton de P servi sans authentification) relevé « majeur » par l'agent : hérité, assumé en 67-SECURITY, hors périmètre. (d) Reste mineur/info : port de terminal.url non rattaché au PID, 503 de fermeture jusqu'à 6-10 s sans SIGKILL, 413 silencieux côté client, `.cache` 0755.
