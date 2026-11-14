# 74-10 — trace rouge (avant le retrait)

Commande : `REPLI_SANS_MUTANTS=1 bash plugin/cockpit/scripts/tests/test-cockpit-repli-retrait.sh` (par le jeton Chrome du poste), sur la tête de 74-08 (45f45ba8) plus la suite neuve.
Décompte avant : `grep -c ouvrirRepli` des modules d'interface = 2 (définition et appel, `72-vf-regie-source.js`), `__vfEquipeRendu.transcript` : 1 appelant (le repli) et une fonction exportée.

| Sonde | État | Obtenu |
|-------|------|--------|
| RP0 préalable (R5 ancre, R5b nom clic, Entrée, Espace, rapport de `test-cockpit-equipe-retraits.sh`) | garde VERTE | `nom=6 rapport=2 ancre=1 echecs=0` |
| RP1 `ouvrirRepli` absent | ROUGE | 2 occurrences |
| RP2 export `transcript` absent, aucun appelant | ROUGE | `function|appelants=1` |
| RP3 sans fiche, `rapport` non annulé : rien | ROUGE | panneau changé, surcouche ouverte, 1 requête de transcript, 1 `vf-agent:lu` |
| RP4 témoins de la régie (RG15.1 à RG15.5, RG15.8, RG15.9, RG1.11, RG16.1, RG0.11, clauses restantes de RG15.6, RG15.7, RG11.10) | garde VERTE | aucun manque, aucune ligne FAIL |
| RP5 témoin de remplacement (fil de la fiche : « × n », heure, ligne sans heure écartée) | garde VERTE | `true|true|false|true|true` |

Les trois lignes PASS de R5b exigées par RP0 : `nom (clic)`, `nom (Entrée)`, `nom (Espace)` (deux lignes chacune), `rapport (clic)` (deux lignes) ; l'ancre est une sonde de R5 (une ligne).
Mutants non joués ici (ancre du mutant posée sur la forme d'après le retrait) : ils se jouent à la tâche 3.
