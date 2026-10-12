---
status: resolved
trigger: suite test-check-description-fidelity.sh instable (rc 1 puis 56/0 sur la même base)
created: 2026-10-12
---

# Symptôme
Au SHA 10273142, 20 passages rouges sur 30 (bash, HOME réel), alors que des workers concurrents éditent l'arbre.

# Causes (deux, mesurées, aucune dans la logique du verdict)
1. T10 : `git diff --stat -- plugin` exigé vide, donc rouge dès qu'un tiers (worker, éditeur, arbre sale au lancement) modifie un fichier suivi. 8 rouges sur 30.
2. T9 : comparaison du contenu du répertoire temporaire GLOBAL avant/après ; tout répertoire créé par un autre processus lisait comme fuite du gate. 12 rouges sur 30 (T9 et T10 simultanés sur 2).
   Et `mktemp -d` sans gabarit ignore $TMPDIR sur macOS : confinement impossible sans toucher le gate.

# Correctif
- Gate : `mktemp -d "${TMPDIR:-/tmp}/check-description-fidelity.XXXXXX"` (une ligne).
- Suite : T9 sous TMPDIR privé ; miroir de plugin/ jugé par T1/T2/mutants et toutes les invocations du gate (copie du gate à sa place), T10 = empreinte chemin+contenu du miroir avant/après.

# Vérification
30/30 bash, 30/30 bash sous HOME neuf (PYTHONUSERBASE conservé : PyYAML est en site utilisateur), 5/5 zsh.
Mutants (rouges) : trap retiré -> T9 ; écriture dans l'arbre jugé -> T10 et T15 ; cliquet de péremption neutralisé -> T6 ; exception YAML invalide tolérée -> T17. Témoin vert.
Piège de mesure : sous HOME neuf sans PYTHONUSERBASE, 30/30 rouge (PyYAML introuvable) : environnement, pas le gate.
