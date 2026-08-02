# Dépannage — installation

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/installation-troubleshooting.md)
<!-- /vf-manual:lang -->

Cette page couvre les quatre pannes documentées qui peuvent survenir **pendant l'installation**.
Pour l'encadré « le lancement est toujours manuel », voir
[installation.md](./installation.md) — cette page ne le reprend pas, pour éviter de raconter deux
fois la même chose à deux endroits différents.

## Les quatre pannes connues

### « `claude plugin` introuvable »

**Symptôme.** Tu tapes `claude plugin marketplace add ...` ou `claude plugin install vibeflow`, et
le terminal répond que la commande `plugin` n'existe pas.

**Cause.** Ta version de Claude Code est trop ancienne — la commande `plugin` n'existe que dans
les versions récentes.

**Geste.** Mets Claude Code à jour, puis retape les deux commandes d'installation (voir
[installation.md](./installation.md)).

### L'UX d'installation ne s'ouvre pas au démarrage de session

**Symptôme.** Tu ouvres une nouvelle session Claude Code après avoir installé le plugin, et rien
ne se passe automatiquement — pas de configuration qui démarre toute seule.

**Cause.** Ce n'est **pas une panne** : c'est le comportement normal. VibeFlow ne s'ouvre jamais
tout seul, ce lancement est volontairement manuel.

**Geste.** Tape `/vibeflow-install` toi-même. Si la commande n'est pas reconnue par Claude Code,
vérifie que le plugin est bien installé et que tu as bien redémarré ta session **après** avoir
lancé `claude plugin install` :

```bash
claude plugin list
```

Le plugin `vibeflow` doit apparaître dans cette liste.

### Le marketplace n'est pas trouvé

**Symptôme.** `claude plugin install vibeflow` échoue en disant qu'il ne trouve pas le plugin, ou
que le marketplace n'est pas enregistré.

**Cause.** La première commande (`claude plugin marketplace add ...`) n'a pas été exécutée, a
échoué silencieusement, ou le cache local du catalogue est périmé.

**Geste.** Réexécute l'ajout du marketplace, puis vérifie qu'il apparaît bien dans la liste :

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin marketplace list
```

Le dépôt `picmakpro/vibeflow-os` doit figurer dans le résultat de la deuxième commande.

### Tout réinstaller depuis zéro

**Symptôme.** Rien de ce qui précède n'a résolu ton problème, et tu préfères repartir d'une base
propre plutôt que de continuer à diagnostiquer.

**Geste.** Retire puis réinstalle le plugin :

```bash
claude plugin uninstall vibeflow
claude plugin install vibeflow
```

Ceci ne touche que le **plugin** (le bundle dans le cache Claude Code) — pas les modules déjà
déployés dans ton scope. Si tu veux repartir complètement de zéro, y compris sur les modules
déjà posés, la procédure complète de désinstallation en deux couches est couverte par
[mettre-a-jour-et-desinstaller.md](./mettre-a-jour-et-desinstaller.md).

## Avant d'aller plus loin

Ces quatre cas couvrent tout ce qui est documenté à ce jour comme panne d'installation. Si ton
problème n'y ressemble pas, le réflexe le plus efficace reste de décrire exactement ce que tu vois
(le message d'erreur complet, la commande que tu as tapée) plutôt que de deviner une cause — la
plupart des blocages d'installation se résolvent en quelques secondes une fois le symptôme exact
identifié.

Les quatre pannes de cette page couvrent toutes les causes connues à ce jour ; si Claude Code
lui-même évolue, cette liste sera mise à jour en conséquence.

Dans tous les cas, l'installation reste idempotente : rejouer les mêmes commandes plusieurs fois
de suite ne casse rien, même si tu n'es pas certain d'avoir déjà réussi une étape. Dans le doute,
retape simplement la commande — rien n'est dupliqué ni corrompu en l'exécutant deux fois. C'est
vrai pour chaque commande de cette page.

## Si le problème survient après l'installation

Tout ce qui précède couvre les pannes **pendant** l'installation elle-même. Si ton lab fonctionne
mais qu'un comportement inattendu apparaît plus tard, une fois que tu utilises VibeFlow au
quotidien, une page de référence dédiée au dépannage général — distincte de celle-ci — couvrira ce
cas dans un thème plus loin dans ce manuel.

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/mettre-a-jour-et-desinstaller.md) · [↑ Sommaire](../README.md) · [Suivant →](../02-concepts/qu-est-ce-qu-un-lab.md)
<!-- /vf-manual:nav -->
