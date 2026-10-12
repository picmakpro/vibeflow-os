# Clôture Windows — recette de validation humaine (D-33-C)

> **Condition de clôture de la Phase 33, pas un gate dur.** Ce document N'A PAS été exécuté
> pendant le cadrage ni pendant l'exécution de cette phase — aucune machine Windows n'était
> disponible. Il consigne une recette à faire jouer par un testeur humain sur Win10/11 avant que
> la Phase 33 puisse être considérée close pour son volet Windows, exactement comme le prescrit
> D-33-C (`33-CONTEXT.md`) : « une recette de validation humaine sur Win10/11 est vérifiée
> nécessaire mais non exécutable pendant ce cadrage ». Rien ici n'est une preuve d'exécution —
> c'est un protocole en attente d'un testeur.

## Rattachement — fil testeurs Windows de l'issue #20

Cette recette se rattache au **fil testeurs Windows de l'issue #20** (`gh issue view 20`, section
« 7. Le fil testeurs Windows ») — le même terrain et les mêmes testeurs que le geste `--dry-run`
de cette issue, vérifié au moment du cadrage de la Phase 33 (D-33-C, `33-CONTEXT.md`). Aucun
nouveau fil n'est ouvert : la notification Windows (WTCH-03) est un cas d'usage supplémentaire à
faire vérifier par ces mêmes testeurs, pas une campagne séparée.

## Ce qui a été prouvé par shims en CI Linux (rappel, pas répété ici)

Le design retenu (`33-SPIKE-canal-notification.md` §Testabilité) permet de prouver la
**construction** de la commande PowerShell (WinRT `ToastNotificationManager`, `powershell.exe`
5.1 System32 — jamais `pwsh`, AUMID emprunté à PowerShell) **entièrement sans toast réel**, via
trois points d'injection : `VF_NOTIFY_FORCE_CHANNEL`, des shims de binaires préfixés au PATH, et
un shim `uname`/`/proc/version` pour exercer le vrai code de détection WSL. Cette preuve existe
déjà (`test-notify.sh`, cas N4/N5) et n'est PAS reproduite ici — cette recette couvre uniquement
ce que les shims ne peuvent structurellement pas prouver : l'apparition réelle d'un toast sur un
poste Windows réel.

## Recette de validation humaine minimale

Prérequis : un poste Win10 ou Win11 réel (ou une VM), `powershell.exe` 5.1 disponible (par
défaut sur ces éditions).

1. Installer le lab VibeFlow sur le poste Windows (chemin d'installation natif Windows).
2. Provoquer un `dag.sh mark --status=done` réel sur un nœud d'une mission de test (n'importe
   quel DAG minimal à un nœud suffit) et confirmer VISUELLEMENT l'apparition d'un toast natif
   Windows (notification Windows 10/11 standard, pas une boîte modale).
3. Provoquer un `dag.sh mark --status=failed` réel sur un second nœud et confirmer de la même
   façon l'apparition d'un toast (titre/contenu différents du cas `done`).
4. Répéter les étapes 2 et 3 **sous WSL** (une distribution WSL2 sur le même poste, interop
   activé par défaut) — le canal attendu sous WSL est `powershell.exe`, **jamais** `notify-send`
   même si ce dernier est installé côté distribution Linux (cas discriminant du spike, §Linux —
   WSL, piège nommé N5 dans `test-notify.sh`).
5. Consigner pour chaque étape : le toast est-il apparu ? avec quel délai perçu (estimation
   humaine, pas une mesure instrumentée) ? le titre/corps affiché correspond-il au nœud/statut
   attendu ?

## NON PROUVÉ — reprises telles quelles du spike, non comblées ici

Cette recette **reproduit** les zones non prouvées identifiées par `33-SPIKE-canal-notification.md`
§Non prouvé — elle ne les comble pas, elle les rend visibles pour le testeur qui l'exécutera :

1. **La chaîne Windows complète n'a jamais été exécutée.** Chaque maillon (WinRT
   `ToastNotificationManager`, AUMID emprunté à PowerShell, quoting stdin) est adossé à une
   source documentaire, mais aucune exécution réelle sur un poste Windows n'a eu lieu pendant le
   cadrage ni l'exécution de la Phase 33. Cette recette est précisément ce qui manque pour lever
   ce point — tant qu'elle n'a pas été jouée par un testeur humain, ce point reste NON PROUVÉ.
2. **AppUserModelID arbitraire vs AUMID PowerShell : non tranché.** De nombreuses sources tierces
   utilisent un AppID non enregistré en rapportant un succès, alors que la documentation
   Microsoft est catégorique qu'un toast sans AUMID enregistré ne s'affiche pas. L'AUMID
   PowerShell (`{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe`) a
   été retenu comme strictement plus sûr, mais cette contradiction documentaire n'a pas été
   tranchée par un essai réel — seule l'étape 2/3 de cette recette peut la trancher en pratique.
3. **Latence non mesurée en conditions réelles.** Les valeurs de démarrage `.NET` de
   `powershell.exe` citées par le spike (0,3 s à 4-7 s) proviennent de rapports de bugs tiers,
   biaisés vers le cas pathologique — aucune mesure n'a été prise sur ce dépôt. Cette recette
   demande une estimation humaine du délai perçu (étape 5), pas une mesure instrumentée : elle
   ne prétend pas lever ce point avec la même rigueur qu'un chronométrage automatisé.

## Ce que ce document N'affirme PAS

Aucun toast Windows n'a été observé ni vérifié pendant le cadrage ni l'exécution de la Phase 33
— formulation explicite : **non exécuté, aucune machine Windows disponible pendant le cadrage ni
l'exécution**. Ce document ne devient une preuve qu'une fois joué par un testeur humain réel ;
tant que cela n'a pas eu lieu, le statut Windows de WTCH-03 reste une condition de clôture
ouverte, jamais une clôture silencieusement présumée.
