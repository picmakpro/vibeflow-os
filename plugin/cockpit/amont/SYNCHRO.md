# Synchro de la copie vendorisée de floorplan

Le moteur du cockpit (`plugin/cockpit/skills/cockpit-moteur/`) est **floorplan v0.6.0 @ 92d6854**
(`haydenschmitty/floorplan`, MIT) plus des patchs VibeFlow rejouables : un fichier de diff par fichier amont
touché sous `amont/patches/` (nom = chemin où chaque `/` devient `__`), des ajouts et des retraits tous listés en
lignes machine dans `skills/cockpit-moteur/VENDORED.txt` (`PATCH`, `AJOUT`, `RETRAIT`, `TAILLE`). Décision
P67-D-11 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-01) : on reste sur v0.6.0 et on livre la
procédure ; la première synchro (v0.6.1) est hors de la Phase 67.

## Vérifier (hors réseau, rejouable en CI)

```bash
bash plugin/cockpit/amont/synchro.sh verifier
```

Retire les ajouts, inverse les diffs et compare l'arbre obtenu au manifeste `amont-92d6854.sha256` (code 0 :
amont retrouvé à l'octet ; 1 : écart nommé, par exemple une ligne amont modifiée sans patch ; 2 : non vérifiable).

## Reconstruire depuis l'amont

```bash
git clone https://github.com/haydenschmitty/floorplan "$(mktemp -d)/fp"   # dossier jetable hors de tout dépôt
git -C <clone> checkout 92d6854 && git -C <clone> rev-parse --short=7 HEAD  # doit rendre 92d6854
bash plugin/cockpit/amont/synchro.sh reconstruire <clone> <dossier-neuf>
```

Copie `skills/floorplan` et `LICENSE`, applique chaque diff (`git apply -p1 --verbose` dans un dossier jetable
hors dépôt : lancé dans un sous-dossier d'un dépôt, git ignore en silence les chemins qui en sortent), puis copie
les ajouts listés dans `VENDORED.txt`.

## Synchroniser sur un nouveau tag amont (v0.6.1 et suivants)

1. Cloner le nouveau tag dans un dossier jetable.
2. `synchro.sh reconstruire` échoue sur le premier diff qui ne s'applique plus : fusionner à trois voies ce
   fichier (ancienne base amont, nouvelle base, notre version), puis `synchro.sh regenerer-patch <chemin> <clone>`.
3. `synchro.sh empreintes <clone> > amont/amont-<commit>.sha256`, renommer le manifeste et `MANIFEST` dans le script.
4. Rejouer les suites du module, dont l'inventaire du chrome français (plan 67-07), puis mettre `VENDORED.txt` à jour.

Patchs candidats à une PR amont : P1-P4, P6, P8 (génériques, sans rien de VibeFlow).
