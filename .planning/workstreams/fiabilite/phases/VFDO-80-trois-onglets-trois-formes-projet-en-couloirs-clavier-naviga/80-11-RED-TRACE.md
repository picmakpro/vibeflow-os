# 80-11 — trace du rouge (P80-D-25), base = tête de la branche avant tout code du plan

LONGUES-BASE=283
Constat : aucun commit `(80-11)` n'a encore touché `viewer.html` (mesure : `git log --grep='(80-11)' -- viewer.html` vide). Mesure du nombre de lignes de plus de 160 colonnes par la commande awk du plan.

Régime allégé : mutants M-MENTIONS, M-ELEMENT, M-DOUBLE, M-PORTE, M-CACHE levés (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Les cas PV2.5 (porte substituée) et PV2.7 (porte relue après un aller-retour d'onglet) restent.

Écart de base : sur Code, le type d'un fichier se lit « fichier » (pas « Élément ») ; PV1.3 prend la valeur mesurée.

Lignes d'échec de la suite sur la base (11 FAIL, 7 PASS dont les témoins PV1.3, PV1.9, PV2.5b, PV2.9, PV3.9) :
❌ FAIL — PV1.1 — plan 01-01 : type « Plan » ; ni « Élément » ni « module » dans le panneau
❌ FAIL — PV1.2 — la ligne du parent dit « Dans la phase » suivie de la phase
❌ FAIL — PV2.1 — plan 01-02 : « Exigences couvertes » (R-1 Cochée) une seule fois, avant « Dépend de » ; plan 01-01 : « Attendu par » ; ni « Mentions » ni « Une mention »
❌ FAIL — PV2.2 — plan : « Statut » (mot) et « Vague 2 » / « Sans vague », aucune statistique à 0
❌ FAIL — PV2.3 — exigence R-1 : type « Exigence », titre = identifiant, texte une seule fois, « Couverte par » (01-02)
❌ FAIL — PV2.4 — phase : section « Plans », bouton « Ouvrir la phase »
❌ FAIL — PV2.6 — l'extension est servie sous /_vf/ et aucun script en ligne ne porte son code
❌ FAIL — PV2.7 — après un aller-retour d'onglet la porte est recréée, la section lit la porte du moment (R-1, puis FX-1 et FX-2)
❌ FAIL — PV2.5 — porte substituée : le lab n'a aucune exigence (témoin positif) ; fausse porte : une section « Exigences couvertes » avec FX-1 Cochée et FX-2 Non cochée ; restaurée : plus de section
❌ FAIL — PV3.1 — phase 1 : sa ligne d'état une fois ; jalon : « N phases faites sur M » et une barre role=progressbar
❌ FAIL — PV3.3 — sur tout nœud et tout élément de Projet : aucun des mots « Élément », « module », « Mention »
Résultats : 7 PASS / 11 FAIL
