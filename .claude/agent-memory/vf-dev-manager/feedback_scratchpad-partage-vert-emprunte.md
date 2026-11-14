---
name: scratchpad-partage-vert-emprunte
description: Le scratchpad de session est partagé par les workers ET par les managers frères — un nom générique (run-suites.sh, base/, dag.json) se fait écraser ou fait lire un vert emprunté
metadata:
  type: feedback
---

Les workers d'une même mission **partagent le répertoire scratchpad**. Un worker qui écrit son
résultat de rejeu dans un nom générique (`tests.rc`, `out.txt`, `bilan.log`) laisse un fichier que le
worker **suivant** relira comme le sien. Exiger dans chaque mandat un **nom de fichier propre au
worker** (suffixe `$$`, `mktemp`, ou le nom du plan), et exiger qu'il **attende la disparition de son
propre producteur** avant de lire un `rc`.

**Why:** constaté le 2026-09-24 (Phase 41.1, plan 41.1-08). Un `cat $S/tests.rc` a rendu un bilan
complet — « 87 suites, 0 échec, rc=0 » — **pendant que le rejeu du worker tournait encore**
(`pgrep` vivant). Le fichier venait d'un worker antérieur du même lot. Le worker l'a détecté, l'a
supprimé et a attendu sa propre sortie : « aucun vert emprunté ». S'il ne l'avait pas vu, il aurait
rapporté un vert measuré par quelqu'un d'autre, sur un arbre différent — un faux vert **fabriqué par
l'orchestration**, pas par le code, et invisible à la relecture du rapport.

**How to apply:** c'est une faute de **manager**, pas de worker : c'est moi qui sérialise plusieurs
workers dans un même scratchpad. Deux gestes, dans le mandat : (1) nommer les artefacts de mesure de
façon unique ; (2) ne lire un code de sortie qu'après avoir constaté la fin du producteur — un `rc`
lu pendant qu'un process tourne est un `rc` d'autre chose. Même famille que
[[project_timeout-absent-faux-zero]] et [[feedback_attestation-sur-sha-fige]] : la mesure est juste,
l'objet mesuré n'est pas celui qu'on croit.

Voir aussi [[project_sonde-inline-zsh-parse-le-case]] (§4, le rejeu complet n'est pas un oracle).

**Extension du 2026-11-06 (retours panel, trois managers frères en parallèle) :** le scratchpad est
celui de la SESSION, donc partagé aussi avec les autres managers lancés par la session principale.
J'y ai écrit `run-suites.sh`, `base/` et `dag.json` ; le manager voisin utilisait les mêmes noms et a
réécrit le script pendant que ma baseline tournait (bash lit un script par décalage : exécution
corrompue possible). **How to apply :** dès le premier geste, tout sous un sous-dossier nommé par la
mission (`scratchpad/<mission>/`), y compris le DAG, et le dire dans le digest des workers.
