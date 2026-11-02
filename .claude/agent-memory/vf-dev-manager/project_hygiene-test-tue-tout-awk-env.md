---
name: hygiene-test-tue-tout-awk-env
description: un nettoyeur de processus « par marque » a tué tous les processus de Samuel (crash machine 2026-11-02) — préfixe d'env sur ps, pas sur awk, et index($0,"")=1 sous l'awk macOS
metadata:
  type: project
---

Crash de la machine le 2026-11-02 vers 00:07, en pleine mission Phase 67 (nœud fix-67-d). Cause lue dans le code : le `hygiene.sh` non commité du worker faisait `VF_T="$TAG" ps -eo pid,args | awk '...index($0,ENVIRON["VF_T"])...'`. Le préfixe d'environnement ne s'applique qu'à `ps` : dans awk la marque est vide, et l'awk BWK de macOS rend `index(s,"")=1`, donc chaque processus est compté. Le trap EXIT envoyait ensuite TERM puis KILL à toute la liste (trace : « avant : 694 », avec launchd). Le manager et le worker sont morts en exit 137. Sous gawk (Linux), `index` vide rend 0 : vert à vide en CI.

**Why:** un rapport de « fuite » qui liste launchd, ou un compte « avant » de plusieurs centaines, était le signal. Le worker l'a lu comme un témoin rouge réussi.

**How to apply:** tout mandat qui fait tuer des processus « par motif » exige quatre choses avant la première exécution réelle : une marque validée (forme mktemp, refus si vide), un plafond qui refuse de tuer au-delà de N processus, une preuve à sec (mode simulation) et un leurre non marqué qui doit survivre. Exiger aussi qu'un témoin rouge nomme le processus injecté, jamais une liste. Lié : [[mutation-qui-echoue-pour-la-mauvaise-raison]], [[preuve-incapable-de-rendre-rouge]].
