---
name: retest-state-ignores-unflushed-input-buffer
description: Phase 72 ac8cacb7 - un retest d'etat systeme (tcgetpgrp) avant ecriture ne couvre pas l'entree humaine encore en tampon applicatif (vers_shell) ; la sonde 4 ms passe, 20-160 ms rougit
metadata:
  type: feedback
---

Un correctif qui reteste l'etat systeme au moment d'ecrire (liberer_ligne -> premier_plan_libre) laisse la fenetre dominante ouverte si l'entree concurrente est encore dans le tampon applicatif (vers_shell lu dans la meme passe de boucle, pas encore pousse). La ligne est ajoutee derriere `cat\r` et part dans la meme ecriture : tcgetpgrp voit encore le shell.

**Why:** revue ac8cacb7 (2026-11-06). La sonde de la revue precedente (delai 4 ms) passait, mais le meme scenario a 20-160 ms rendait `LANCE ok` et la ligne dans cat, 100 % des essais (fenetre ~170 ms : de calme+30 ms au reveil select 0,2 s). Le temoin L11.2 ne l'exerce pas (5 ms : entree deja ecrite avant la liberation).

**How to apply:** apres un correctif de course, rejouer la sonde du finding sur un BALAYAGE de delais (pas le seul point rapporte) et lire quel tampon contient l'entree concurrente a l'instant du test. Fix d'une clause : `libre = premier_plan_libre(...) and not vers_shell`, verifie sur le balayage. Les temoins "fonctions seules" doivent passer un vers_shell non vide a liberer_ligne.
