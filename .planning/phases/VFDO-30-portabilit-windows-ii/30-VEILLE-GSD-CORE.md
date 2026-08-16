# Veille de release `@opengsd/gsd-core` (WKTR-03, D-10)

## Ce que la veille surveille, et pourquoi

La Phase 35 (« ré-armement worktree ») est **flottante** : elle n'est ouverte que si une release de
`@opengsd/gsd-core` **strictement supérieure à `1.10.0`** est publiée (npm `latest` = `1.10.0` au
2026-08-15). Sans veille, personne ne constate que cette précondition externe est levée — c'est le
**seul déclencheur tracé** de la Phase 35.

`scripts/check-gsd-core-update.sh` interroge la version **publiée** du registre npm
(`npm view @opengsd/gsd-core version`, la version du dist-tag `latest`) — **jamais** le dist-tag
`next` (D-10) : la précondition de la Phase 35 est « releasé », pas « publié en préversion ». La
comparaison passe par `sort -V`, jamais un tri lexical (piège documenté : `1.9.0 < 1.10.0` en
semver, l'inverse en lexical). Le refresh réseau est gaté par un cache **quotidien** : au plus un
appel réseau par jour, jamais au démarrage synchrone d'une session — le mode `--hook` lit le cache
existant et relance le refresh en arrière-plan (patron `plugin/conductor/scripts/update-banner.sh`).

Réseau ou npm indisponible ⇒ le cache n'est PAS réécrit, l'état précédent est conservé, la sonde
sort 0 sans rien écrire sur stdout : une session hors ligne n'a ni erreur, ni faux signal, ni faux
silence.

## L'armement est machine-local PAR CONSTRUCTION — et ne voyage pas

`.claude/` de ce dépôt est **gitignoré** (`.gitignore` l.20 : `.claude/`), confirmé sur pièce :

```
$ git check-ignore -v .claude/settings.json
.gitignore:20:.claude/	.claude/settings.json
```

L'entrée `SessionStart` qui invoque la sonde vit dans `.claude/settings.json` de CE dépôt — donc
elle **n'est ni versionnée, ni distribuée, ni vérifiable par la CI**. C'est un fait établi, pas un
oubli : D-10 admet explicitement un armement repo-local (la Phase 35 ne concerne que ce dépôt), et
la leçon déjà payée une fois sur ce repo (« armement sans précondition distribuée », régression #38)
est qu'un réglage posé dans un settings local **ne voyage pas** avec le dépôt. Ce document existe
pour que ce fait ne redevienne jamais implicite : sur tout autre clone (autre machine, autre
contributeur), l'armement ci-dessous doit être **reposé manuellement**.

## Commande exacte de ré-armement

Ajouter au `settings.json` du répertoire `.claude/` de ce dépôt (le créer s'il n'existe pas ; s'il
existe déjà, **fusionner** — ne jamais écraser un contenu existant) l'entrée `SessionStart` suivante,
en **forme exec** (dogfooding de la doctrine que cette phase installe — jamais un nom nu comme
`command`, toujours un chemin absolu résolu localement) :

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "{{ABS_PATH_TO_BASH}}",
            "args": ["{{ABS_PATH_TO_REPO}}/scripts/check-gsd-core-update.sh", "--hook"]
          }
        ]
      }
    ]
  }
}
```

`{{ABS_PATH_TO_BASH}}` — le chemin absolu de l'interpréteur bash de la machine (`command -v bash`,
JAMAIS un nom nu : `command` d'une entrée exec est résolu sur le PATH, pas de raccourci). Sur macOS
c'est en général `/bin/bash`.

`{{ABS_PATH_TO_REPO}}` — la racine de ce dépôt sur la machine locale (`git rev-parse
--show-toplevel`).

**Ces deux marqueurs sont volontairement des placeholders, pas un chemin réel** : ce document est
versionné, et le gate `bash scripts/check-machine-paths.sh` interdit tout chemin absolu de machine
dans un fichier versionné — c'est la bonne réponse ici, pas une lacune.

Cette entrée est **advisory** : elle ne bloque jamais rien, et la sonde sort toujours 0.

## Diagnostic

```
bash scripts/check-gsd-core-update.sh --status
```

Affiche sur stdout le seuil surveillé, la dernière version vue, si elle dépasse le seuil, et
l'horodatage du dernier appel réseau réussi (ou signale l'absence de cache / un cache imparsable).
Sort toujours 0.

## Qui lit ce document

La Phase 35 (ré-armement worktree) lit ce document pour retrouver le déclencheur qui l'a ouverte et
la commande de ré-armement de la veille sur le poste qui la reprend.
