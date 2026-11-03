---
name: gate-marqueur-ressemblant-et-conduite-indetermine
description: Phase 60 — un gate qui lit « absent » sur une forme voisine laisse passer le cas qu'il garde ; et une conduite « 3 et 64 continuent » est un fail-open dès que le contrôle se trompe de cible.
metadata:
  type: project
---

Dans `check-phase-validation.sh`, une ligne `- **Validation:** proposed`, `Validation: proposed`, `**validation:** proposed`
(puce, citation, sans gras, minuscules, espace avant `:`) était lue « marqueur absent » donc phase validée, rc 0.
Corrigé le 2026-10-29 : forme voisine = marqueur illisible (rc 3, `marqueur=inconnu`), dans le gate ET dans l'écrivain `vf-validation.sh`
(sinon `propose` insère une seconde ligne à côté).

**Why:** un lecteur strict sur le format exact transforme chaque faute de frappe d'un humain ou d'un agent en « non gardé ».
La conduite des consommateurs avait le même défaut : « codes 3 et 64 continuent » laissait passer lab partitionné sans `--ws`,
sections multiples, bloc non fermé qui avale la phase. Décision P60-D-15 (arbitrage Samuel, AskUserQuestion session principale,
2026-10-29) : seul `BILAN marqueur=introuvable` (phase absente du ROADMAP sans autre défaut) continue.

**How to apply:** pour tout gate « absent = autorisé », lister les formes voisines du marqueur et exiger qu'aucune ne soit lue
« absent » ; ajouter un témoin de non-sur-détection (`Validation: les tests passent` reste absent). Pour tout consommateur, ne
jamais écrire « le code X continue » : nommer le champ machine qui distingue l'unique cas qui passe. Preuve rouge utile : poser les
suites neuves sur un `git archive` de la tête d'avant (14, 3 et 59 échecs ici). Piège rencontré : une sonde de test qui appelle une
fonction définie plus bas dans le fichier (`mkpart`) rend « command not found » sans faire échouer le cas, vert à vide.
