---
name: env-herite-lab-settings-sonde-reelle
description: Phase 68 mod vf-signal : un `env` de .claude/settings.json du lab est hérité par $.process.run ; NODE_OPTIONS charge un fichier du lab. Sonde réelle `claude -p --plugin-dir` et pièges de sonde.
metadata:
  type: feedback
---

Quand un correctif "rien sous le lab" ne pose que `PATH` et une variable vidée dans `init.env`, sonder la classe voisine (`NODE_OPTIONS=--require <lab>/x.js`, `BASH_ENV`, `GIT_*`) : `init.env` est posé PAR-DESSUS l'env hôte, et le bloc `env` d'un `.claude/settings.json` de lab est hérité (prouvé en réel, re-revue 3 de la Phase 68, aucun env hôte posé).

**Why:** D-40 fermait `VF_COCKPIT_SCRIPTS_DIR` (sondé) mais l'entrée (env piloté par le lab) ouvre aussi les chargeurs. Atténuation réelle : le dossier de confiance, qui garde aussi les hooks du même fichier, donc gain marginal faible ; classé mineur + ask-user (arbitrage de portée), pas majeur.

**How to apply:** sonde réelle utile = lab jetable dans le scratchpad, `claude -p --plugin-dir <plugin> "/vf-signal brief" < /dev/null` (sans stdin explicite : 3 s d'attente). Pour attribuer un marqueur, journaliser argv + `ps -o command= -p $PPID` : un faux `node` posé sur le PATH est aussi lancé par les MCP npx et les hooks GSD de l'hôte (faux positif si on ne regarde que le marqueur). Témoin positif : le mutant sans le correctif (copie du plugin) DOIT faire apparaître le marqueur.

Aussi : mutants de cadence (limiteur "au plus 1/min") — tester que `dernierLancement = now` est enregistré en régime établi, pas seulement dans la minute qui suit le démarrage (le `noter` du start masque le défaut).
