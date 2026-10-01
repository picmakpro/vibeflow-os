---
quick_id: 261001-5xc
status: complete
description: Correction ciblée lot C de la Phase 45 (re-audit N1, F4 ; re-revue F1, F2)
base: a02b8ad
commits: [dd5027a0, 579b8c1a, 8a34ff93]
---

# Quick 261001-5xc — correction ciblée lot C

Source : re-revue (PASS) et re-audit (10 constats sur 10 fermés, un nouveau constat N1) sur `a02b8ad`. Décisions du manager vf-dev-manager,
2026-10-01, renversables. Chaque constat : test rouge (mutant qui rétablit l'ancien comportement), correctif, vert, mutant tué. Aucun cas
existant supprimé, aucun mutant retiré. Exécution directe par vf-coder dans le worktree de mission (aucun exécuteur isolé, aucun
`gsd-tools state`, ni STATE.md ni ROADMAP.md touchés).

| Id | Correctif | Tests | Mutants tués | Commit |
|----|-----------|-------|--------------|--------|
| N1 | budget d'indexation de 8 Mio décompté sur les seuls fichiers CANDIDATS (nom de fichier, ou en-tête de 4 Kio, ou frontmatter encore ouvert) ; un épuisement sur un candidat rend l'agent indéterminé (P45-D-11) et écrit `raison=budget-indexation` au journal d'observation | R-N1-01 (dix frères de 1 Mo : refus en moins de 3 s ; dix candidats de 1 Mo : passage + une ligne de signal) | INDEXATION-CANDIDATS, BUDGET-SIGNAL | dd5027a0 |
| F4 | refus de la couche shell : « doute d adhesion du lab (chemin non analysable) » quand PX=0 ferme hors de tout lab adhérent ; libellé d'origine pour un lab réellement adhérent ; `COMMANDE_REFERENCE` du canary alignée sur hooks.json | R-CMD-05b | LIBELLE-DOUTE, LIBELLE-ADHERENT | 579b8c1a |
| F1 | `.planning` du lab (racine ou imbriqué) en lien sortant refusé (code 1, rien joué) ; zéro ligne mesurée : `MESURE-VIDE`, message, code 1 | R-REEL-PLANNING-LIEN (+ témoin interne), R-REEL-MESURE-VIDE (+ témoin) | REEL-PLANNING-LIEN, REEL-PLANNING-LIEN-IMBRIQUE, REEL-MESURE-VIDE | 8a34ff93 |
| F2 | en-têtes d'usage : `<lab-N>` hors de HOME, dépendance à l'ordre des `--lab=` (documentation seule) | — | — | 8a34ff93 |

## Décisions d'implémentation à relire (renversables)

- **N1, filtre candidat** : sur-ensemble volontaire (le nom visé normalisé apparaît dans l'en-tête de 4 Kio, ou le frontmatter n'y est pas refermé :
  `name:` peut se trouver plus loin). Un faux candidat est écarté par la comparaison du `name:` lu en entier ; un vrai candidat n'est pas manqué.
  Limite : un `name:` écrit avec un échappement YAML qui masque le nom dans l'en-tête n'est pas candidat par ce chemin.
- **N1, épuisement** : le candidat non lu est enregistré `illisible` sous le nom visé (la résolution s'arrête là : pas de repli sur un niveau suivant).
- **F4** : deux libellés ; la couche shell calcule `W` après la décision (la ligne `elif [ "$PX" = 0 ]` reste inchangée, les mutants PX-* tiennent).
  Fichier hors périmètre listé touché par nécessité : `check-gates-alive.sh` (R-CAN-11 compare la constante embarquée à hooks.json octet pour octet).
- **F1, `MESURE-VIDE`** : un `.planning` en lien vers un dossier DU lab n'est pas refusé, mais la copie du rejeu ne suit pas le lien : rien n'est
  mesuré, c'est dit (code 1).
- Identité AST : `lire_frontmatter`, `lire_registre`, `_jeton_journal` non touchés.

## Suites rejouées (toutes vertes)

test-planning-gates 395/0 ; test-planning-hook-registered 44/0 (sh, dash, bash, zsh exercés) ; test-planning-hook-installed 21/0 ;
test-rejeu-gates 89/0 ; test-role-hook-vs-check-agents 6/0 ; test-recalc-planning 358/0 ; check-planning-state 19, detect-gsd-engine 26,
detect-planning-debt 10, planning-context-hardening 38, planning-core 14, planning-hooks 42, workstream-policy 22, workstream-symlink-escape 10, 0 échec.
