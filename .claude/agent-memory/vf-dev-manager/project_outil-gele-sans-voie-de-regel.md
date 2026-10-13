---
name: outil-gele-sans-voie-de-regel
description: Un outil de contrôle figé par empreinte à commit unique n'avait aucune voie pour une correction légitime — chaque plan suivant aurait démarré rouge ; prévoir le regel tracé dès la conception
metadata:
  type: project
---

Phase 46.1 (2026-10-13) : l'outil de contrôle de phase `46.1-CONTROLES.sh` était gelé par
`46.1-CONTROLES.sha256` avec la règle « exactement un commit sur le `.sha256` » (`gel-rouvert`
sinon). Au plan 01, un vrai défaut de l'outil est apparu (la copie détachée ré-appliquait
`detache-requis` : toute suite de base ≥ 480 s inutilisable — l'autotest n'avait qu'un cas à 4 s).
Le corriger imposait un second commit de gel : `EMPREINTE-ECART gel-rouvert` à la première commande
de CHAQUE plan restant. Décision du manager : **regel tracé** — un commit qui ne touche que le
`.sha256` et porte `Regel-Outil: <id quick> — <raison>` est valide, imprimé en `EMPREINTE-REGEL`
avant `EMPREINTE ok … regels=<n>`. Le premier regel du worker, sans trailer et non poussé, a été
retiré de l'historique local (sauvegarde `vf-backup/…`).

**Why:** un gel qui interdit toute réouverture ne protège pas mieux qu'un gel qui la rend visible
(ADR-072 : visible, jamais empêché) ; il force seulement à choisir entre réécrire l'historique et
laisser chaque plan rouge. Et un outil d'armement non éprouvé sur la vraie forme de ses entrées
(suite longue) casse au premier usage réel.

**How to apply:** à la relecture d'un plan qui gèle un outil, exiger la voie de regel tracé dès le
plan ; et exiger que l'autotest d'un mode à seuil couvre les DEUX côtés du seuil (ici base < et ≥
480 s). Voir [[liste-de-cas-ne-ferme-pas-une-classe]], [[revalider-les-plans-ecrits-avant-les-faits]].
