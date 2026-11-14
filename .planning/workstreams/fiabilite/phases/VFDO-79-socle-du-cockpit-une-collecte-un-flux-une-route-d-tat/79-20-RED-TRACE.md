AVANT-20 fc102a6a20eb3d27521590a3edd11cc2729ded17
VERDICT-S0 OUI (ligne « Verdict S0 : OUI » de 79-19-SONDE-S0.md) ; `plugin/cockpit/hooks/hooks.json` : absent. Le journal des attentes n'est donc ni livré ni décrit.

# 79-20 — trace (régime allégé, nœud x20, 2026-11-14)

## Baselines relevées (écarts avec le plan)
- README du module : 389 lignes (plan : 387). Lignes qui portent un jeton retiré : 11 (l.6, 36, 139, 145, 147, 192, 205, 221, 336, 351, 352) ; le plan disait 11 lignes (l.6, 36, 138, 144, 146, 191, 204, 220, 335, 349, 350) : même nombre, numéros décalés d'une ligne.
- Repères du socle à zéro dans le README : `/api/vf/state`, `/api/vf/frise`, `worker-src`, `/_vf/`, `VF_ETAT`, `journal des attentes`, `pose projet` (vérifié sur ces sept, les autres à zéro de même par construction : le README n'a pas été touché).
- CHANGELOG : 619 lignes, `## Non publié` l.3, premier titre de version `## v1.4.0` l.154. Version du module : v1.4.0, type « skill + scripts + moteur vendorisé ».
- Compteur : voir « Compteur » en fin de trace.

## Sources des chiffres (relevées dans le code tel que laissé ; écarts avec la table du plan)
| clé | fichier | affectation | valeur |
|---|---|---|---|
| `fenetre-index-h` | `scripts/vf-cockpit-index-voie.mjs` l.14 | `fenetreS: 86400` dans `DEFAUT` | 86400 / 3600 = 24 |
| `battement-flux-s` | `scripts/vf-cockpit-flux-etat.mjs` l.11 | `export const VIE_MS = 15000;` | 15 |
| `veille-flux-s` | `skills/cockpit-moteur/assets/ui/69-vf-flux.js` l.15 | `const SILENCE_MS = 45000;` | 45 |
| `fraicheur-signal-s` | `scripts/vf-cockpit-signal-serveur.mjs` l.14 | `export const FRAICHEUR_MAX_MS = 20000, …` | 20 |
| `plafond-lignes` | `plugin/software-architecture/scripts/check-file-size.sh` l.26 | `BLOCK="${VF_ARCH_BLOCK:-300}"` | 300 |
| `plafond-colonnes` | `scripts/tests/colonnes-cliquet.mjs` l.11 | `const SEUIL = 160;` | 160 |
| `scripts-lancer` | `scripts/vf-cockpit-lancer*.mjs` | nombre de fichiers | 9 |
| `suites-lancer` | `scripts/tests/test-cockpit-lancer-*.sh` | nombre de fichiers | 14 |

Écart : le plan nomme `FENETRE_S` de `vf-cockpit-index.mjs` ; ce nom y est une réexportation de `BORNES.fenetreS`, dont la valeur littérale est dans `DEFAUT` de `vf-cockpit-index-voie.mjs`. L'extracteur lit cette seule affectation littérale (exactement une ligne, sinon rouge).
Écart : les témoins V12.6 construisent des documents synthétiques (README, CHANGELOG, VERSION, `module.json` minimaux qui disent le code tel que lu) à côté des sources réelles des extracteurs, au lieu de cloner le README réel : sur les docs de la base, qui n'ont pas de tableau, les mutations « valeur », « ligne retirée » et « ligne en double » n'auraient eu aucun effet à muter. V12.7 prouve la copie.

## Matière (une ligne par SUMMARY : mentions à poser, limites, écart avec R1 à R16)
- 79-01 : § Code tiers sans appareil de patchs (origine v0.6.0 @ 92d6854, MIT, fork assumé), retrait de la ligne « à rejouer à chaque synchro amont », type de module, CHANGELOG ; contrat `AJOUT` dans `VENDORED.txt` en tri C. Aucun écart.
- 79-02 : aide `socle-serveur.sh` et migration des suites ; limites : sondes d'horloge sous charge. R10/R13.
- 79-03/79-04 : registre archivé 24 h et plan de mission publié côté `conductor` (renvoi au CHANGELOG de `conductor`) ; limite : identifiant remappé `id::étape` hors du motif de rattachement.
- 79-05 : `vf-cockpit-routes.mjs`, tables `ROUTES` et `ANNOTATEURS`, règle d'ajout (R10 « Étendre le serveur »).
- 79-06 : serveur lancé depuis le module, identité `serve.mjs` + `--sortie=`, empreinte de relance, confinement remesuré (alphabet du chemin), pose projet ; limites : branche « ancienne » de `estNotre` (retrait à la version suivante), PID et port non liés, module à chemin avec espace, une seule version de Claude Code mesurée.
- 79-07 : résolution physique unique, pilotes de git vidés, marqueur `VF_COCKPIT_GIT_DURCI=1` ; limite : coût d'un mémo de 2 s.
- 79-08 : index incrémental, `cockpit-index@1`, `claudeCode.index`.
- 79-09 : collecte hors boucle, `lock` et `hello.lock` changent de forme, verrous en liste blanche, `registry --all`, limites de l'audit.
- 79-10 : traduction au point d'émission, `?lang=en`, messages du serveur en français (A43), porte `vf-cockpit-fr-sources.mjs`.
- 79-11 : six modules retirés, code navigateur rangé, cliquet de 160 colonnes, `FICHIERS_NAVIGATEUR`.
- 79-12 : route `state`, événements `vie` et `etat`, `vf-signal` lit la route (repli), limites Windows et fraîcheur.
- 79-13 : route `frise`, cibles en mémoire, `voiesOmises`, `cibles.tronque`, cible coupée par `…`.
- 79-14 : `VF_FLUX`, élection par Web Locks, `BroadcastChannel`, veille de 45 s ; `127.0.0.1` et `localhost` = deux flux.
- 79-15 : route `graphe`, événement `graphe`, `projet.json` (0600, jamais servi ni exporté), `VF_COCKPIT_DONNEES_GABARIT` ; amendements 79-15-a, -c, -d.
- 79-16 : coquille, `/_vf/` table fermée, CSP à `script-src` au préfixe, service statique de la sortie retiré (A41) ; limite : export lit encore `index.html`, polices en ligne.
- 79-17 : `VF_ETAT` (huit clés), cycle de vie par `surOnglet`, motif `SC.on('panel', …)`, cliquet des observateurs ; lecteurs non convertis.
- 79-18 : worker de mise en page, `worker-src` au préfixe, CSP propre du worker, repli en ligne, avertissement en console seulement, ELK chargé deux fois.
- 79-19 : sonde S0 OUI, plan arrêté sans code : aucune mention de hooks ; limite J1-D01 (`kind: background` publie `state`, pas `status`).
- 79-21 : module de correspondance borné `lib/vf-glob.mjs` (ajout) ; la regex comme moteur de correspondance (retrait).
- 79-22 : routes `transcript` et `doing` lues dans la table des agents du fil, corps `inconnu` dans cinq cas, chemin d'erreur muet.

## ROUGE-BASE (V12 joué sur les docs de la base, avant le tableau)
ROUGE-BASE V12.2a attendu=24 obtenu=non-documente
ROUGE-BASE V12.2b attendu=15 obtenu=non-documente
ROUGE-BASE V12.2c attendu=45 obtenu=non-documente
ROUGE-BASE V12.2d attendu=20 obtenu=non-documente
ROUGE-BASE V12.2e attendu=300 obtenu=non-documente
ROUGE-BASE V12.2f attendu=160 obtenu=non-documente
ROUGE-BASE V12.2g attendu=9 obtenu=non-documente
ROUGE-BASE V12.2h attendu=14 obtenu=non-documente

## VERT-EMBLEE
VERT-EMBLEE V12.0a, V12.0b : gardes contre le saut silencieux ; V12.0a est la détection du dépôt de dev, V12.0b la lecture des cinq sources ; leur pouvoir de rougir tient à `dc_depot_de_dev` et au test `-s`, non à un témoin (hors dépôt la section saute et le dit).
VERT-EMBLEE V12.1a, V12.1b : à la base les quatre numéros disent v1.4.0 et le type est le même dans `module.json` et l'en-tête ; gardés par les témoins V12.6 (titre, version de `module.json`, en-tête, type).
VERT-EMBLEE V12.3a, V12.3b, V12.3c : le README de la base ne nomme que des modules, suites et routes existants ; gardés par les témoins du module, de la suite et de la route inexistants plantés.

## Tranche traceur : version et tableau (2026-11-14)
- V12.1a avant le bump : OK v1.4.0 (les quatre numéros). Après : OK v1.5.0 (VERSION, `module.json`, en-tête du README, premier titre `## v1.5.0 — 2026-11-14 — non publié` du CHANGELOG).
- Suite vendor jouée après le tableau : 28 PASS de V12 (V12.0a, 0b, 1a, 1b, 2a à 2h, 3a à 3c, 12 témoins, V12.7) et aucun FAIL de V12. Deux FAIL hors V12 (V11.Q6b, V11.P5, empreinte du module sur copie) : le voisin 79-18 modifiait `vf-cockpit-module.mjs` dans l'arbre partagé pendant ce rejeu (fix `42c41fbd1`, AU18-02) ; rejeu plus tard.
- `bash scripts/check-version-sync.sh` : exit 0 (module aligné, compteur de suites 244 dans les deux README racine).

## Tâche 2 : témoins des retraits et du journal (avant la réécriture du README)
ROUGE-BASE V12.4 attendu=0 obtenu=10 (dix lignes du README portent un jeton retiré : l'en-tête, qui en portait une onzième, a été corrigé à la tâche 1 avec le type du module)
VERT-EMBLEE V12.5 : `plugin/cockpit/hooks/hooks.json` n'existe pas (sonde S0 OUI) et le README ne parle pas du journal des attentes ; gardé par V12.6n (texte planté sans fragment) et V12.6o (fragment planté, README muet), tous deux rouges sur copie.
Suite vendor rejouée : 283 PASS / 3 FAIL : V12.4 (rouge voulu) et V11.Q6b, V11.P5 (voisin 79-18 : empreinte du module, dossier partagé en cours d'écriture).
