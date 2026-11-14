base: 7681ce57a05d4c41e30e53ae8f2c00c6320821a3

# 73-11 — trace du rouge (régime allégé)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG17` sur la tête de base, avant tout code de plan.

Garde verte : `✅ PASS — RG17.H1 —` (le modèle sans `ctx.questions` garde ses quatre sections et « Rien ne vous attend. » : le harnais tourne).

Rouges (obtenu) : RG17.0 (aucun repère `72-vf-regie-questions-*` dans la sortie assemblée) ; RG17.1 à RG17.7 et RG17.30 (obtenu : `ERR:fonction absente : normaliser`, module de lecture absent) ;
RG17.8A à 8G (obtenu : `ERR:absent : etat`, module de source absent) ; RG17.10 à RG17.21 et RG17.31 (obtenu : aucun `li[data-vf-question]`, aucun `details[data-vf-repli]`) ;
RG17.40 à RG17.43 (obtenu : `attente de « régie montée et flux ouvert » dépassée`, `window.__vfRegieQuestions` absent) ; mutants : ancre absente (fichier absent).
Passes à vide corrigés avant le commit : RG17.8G, RG17.11 (N = 0), RG17.14 (champ vide), RG17.16 (appui pris), RG17.17, RG17.40 hors navigateur exigent maintenant un témoin positif (trois lignes, pied présent).

Écart : `80-vf-fr.js` ne porte plus la liste des classes exclues de la traduction (`.rp`, `.mono`) ; RG17.21 vérifie les classes sans la lire, RG17.40 vérifie le titre égal à une clé du dictionnaire dans le navigateur.
