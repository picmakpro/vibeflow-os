---
name: fixture-de-perf-la-forme-avant-la-taille
description: Reproduire une mesure de perf citée par une revue exige de refaire la FORME de la fixture (densité des motifs), pas seulement sa taille en octets.
metadata:
  type: feedback
---

Pour rejouer un chiffre de performance cité par une revue, reproduire la **forme** de l'entrée
avant sa **taille**. Une même taille en octets peut donner des temps qui diffèrent d'un ordre de
grandeur selon la densité du motif qui déclenche le coût.

**Why:** Phase 23, revue A-6 : « région de 973 Ko → 52,6 s ». Ma première fixture de 973 Ko avec des
clés longues donnait **3,67 s** — j'aurais pu conclure que la revue exagérait d'un facteur 14. Le
coût était quadratique **par identifiant reconnu**, pas par octet : avec des clés courtes (densité
d'identifiants maximale, la forme optimale pour un attaquant) la même taille donnait **29,5 s**, et
3,9 Mo ne terminait jamais. La taille était la bonne, la forme ne l'était pas.

**How to apply:** identifier d'abord *quelle unité* paie le coût (identifiants, imbrications,
échappements, lignes…), puis fabriquer **deux** fixtures à taille égale — une « réaliste » et une
**dense**, taillée pour maximiser cette unité — et rendre les deux colonnes dans le rapport. La
dense est celle qui vaut comme borne de sécurité : c'est celle que l'attaquant écrira. Vérifier
aussi la **linéarité après correctif** (×4 de taille doit donner ≈×1 de temps, pas ×16) plutôt que
de se contenter d'un seul point de mesure — un point unique ne distingue pas « linéaire » de
« quadratique avec une petite constante ». Voir [[mutation-test-discriminating-cases]] pour la même
exigence côté mutants (reprendre la lettre de la revue, pas son intention).
