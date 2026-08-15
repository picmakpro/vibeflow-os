# Mission — module distribué `vf-cockpit`

**Date** : 2026-08-16 · **Branche** : `worktree-vf-cockpit-module` (worktree isolé)
**Base de diff** : `bf837a13e16a9885921554decb64f0fa144b707e` (parent du 1er commit de mission)
**Commits** : 23 · **DAG** : `.planning/MISSION-COCKPIT.dag.json`, 17 nœuds, tous `done`

## Objet

Transformer le spike VALIDÉ `.planning/spikes/001-cockpit-live/` en module distribué de qualité
production. `/vf-cockpit` lance un cockpit web local, en lecture seule stricte, qui visualise le
`.planning/` du lab courant de l'utilisateur.

## Plan de bataille (DAG)

Pipeliné : `design-spec` ‖ `vendor` ‖ `exec-core` → `exec-ui` ‖ `exec-skill` → 3 juges en parallèle
(`verif` ‖ `critique` ‖ `revue`) → correctifs → re-jugement → `docs`.
Nœuds de correction ajoutés au fil des verdicts : `fix-scripts`, `fix-ui`, `fix-guard`, `fix-ui2`,
`fix-ui3`, plus `reverif`, `recritique`, `critique3`.

## Livré

```
plugin/vf-cockpit/
├── VERSION (v1.0.0) · module.json (requires: []) · README.md · CHANGELOG.md · SKILL.md
├── references/DESIGN-SPEC.md            spec design (DA du module)
├── references/ui/                       13 fichiers — index.html, styles.css, app.js, js/*.js
├── references/vendor/                   Mermaid v11.16.1 UMD, 3,40 Mo, MIT + LICENSE + README
└── scripts/                             serve · parsers · security · watch (4 .mjs)
    └── tests/test-vf-cockpit.sh         38 tests
```
Plus `plugin/commands/vf-cockpit.md`, les compteurs des README racine, et les fiches `manual/`
(en + fr).

## Verdicts

| Étage | Verdict |
|---|---|
| Design (3 passages) | 87 → 93 → **95/100** (seuil relevé à 80) — `passed` |
| Revue de code | aucun bloquant ; 2 majeurs robustesse corrigés |
| Vérification par exécution | 38/38, install e2e OK dans les 2 dispositions |
| `check-version-sync.sh` | **exit 0** |
| `check-agents.sh` | vert sur la population réelle (12 invocations `--strict`) |

## Décisions du manager (consignées)

1. **Étage design NON sauté malgré l'absence de `DESIGN.md`** — le brief le commissionnait
   explicitement et le MANIFEST du spike actait « DA sombre type cockpit ». La spec produite est
   **scopée au module**, jamais une DA lab-wide. → proposer un DA-INIT.
2. **Mermaid vendorisé en UMD, pas en ESM** — le build ESM v11 importe des chunks relatifs et
   casserait le hors-ligne. Constaté empiriquement, pas supposé.
3. **`requires: []`** plutôt que `planning-core` — le cockpit lit `.planning/`, présent sur les labs
   dev (GSD) comme non-dev ; exiger `planning-core` l'imposerait à des labs dev.
4. **Liens symboliques : documenter, ne pas durcir** — outil local mono-utilisateur en lecture
   seule ; durcir casserait un `.planning/` symliné légitime.
5. **Contradiction interne de la spec sur les contrastes → WCAG AA l'emporte**, et **la spec est
   corrigée** (pas seulement le CSS) pour ne pas re-fabriquer le défaut.
6. **Message de verrou périmé : le message complet l'emporte sur l'ellipsis** — un message de
   réassurance tronqué échoue à sa seule raison d'être.

## Ce que les juges ont attrapé et qui serait passé autrement

- **Vendorisation ESM** → hors-ligne cassé, invisible jusqu'au runtime navigateur.
- **`assets/` n'est jamais copié par le moteur d'install** → le module se serait installé « avec
  succès » en ne livrant ni UI ni Mermaid. Corrigé vers `references/` avant tout dégât.
- **Garde lecture seule poreuse** : détectait `fs.writeFileSync` mais laissait passer
  `fs.promises.mkdir`, `openSync+writeSync`, `rmdirSync` — suite verte alors que le fichier écrivait.
  → passée en **allowlist** (point fixe), prouvée par 5 mutations.
- **Test tautologique** : `grep "0.0.0.0"` sur un littéral que le code n'émet jamais.
- **Fuite de process** : `$!` capturait le sous-shell, pas node — 1 orphelin par run.
- **Régression en chaîne** : chacun des 3 tours de correctifs UI en a introduit une plus petite.

## Non vérifié (assumé)

- **Rendu navigateur réel** : prouvé que les 13 assets sont servis en 200 avec le bon MIME, PAS que
  Mermaid s'initialise ni que la page s'affiche sans erreur console. Aucun navigateur disponible.
  Le verdict du spike 001 reste `PARTIAL` sur ce point — checkpoint humain.
- **Bascule `fs.watch` naturelle** : chemin de code prouvé par monkey-patch, pas le déclencheur
  système réel (Linux/Windows).

## Next steps (NON exécutés — gestes humains gatés)

1. Ouvrir la page dans un navigateur et juger le rendu (ferme le `PARTIAL` du spike 001).
2. Bump racine **minor** (v2.52.0 → v2.53.0 : nouveau module) + les 3 fichiers de version + les
   deux README.
3. PR depuis `worktree-vf-cockpit-module`, puis tag annoté + release GitHub après merge.
