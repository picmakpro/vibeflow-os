# 26-14 — SUMMARY (dégraissage README.md / README.fr.md / INSTALL.md — décisions D-7/D-8 dégelées)

**Statut** : livré, avec un périmètre volontairement plus resserré que l'ambition initiale de D-7
sur un point précis — voir « Écart assumé vis-à-vis de D-7 » plus bas. Périmètre écrit :
`README.md`, `README.fr.md`, `INSTALL.md`, ce fichier. Aucun fichier sous `manual/**` touché
(lecture seule, pour construire la table de couverture).

## Table de couverture (règle absolue : rien coupé sans case remplie)

### `INSTALL.md` — chaque section a une page manuel identifiée avant coupe

| Section d'`INSTALL.md` | Page(s) du manuel qui la porte |
|---|---|
| Pré-requis (Claude Code, bash/jq/python3, cas Windows CRLF/jq/python.org) | `01-demarrer/prerequis.md` (+ `01-get-started/prerequisites.md`) — Windows détaillé identique, y compris CRLF/ADR-054 |
| Installation (2 commandes) | `01-demarrer/installation.md` |
| Configuration / 4 étapes de `/vibeflow-install` | `01-demarrer/installation.md` |
| Re-configurer / ajouter un module | `03-modules/activer-desactiver.md` |
| Mises à jour (`/vf-update`, piège du nom nu, moteur GSD séparé) | `01-demarrer/mettre-a-jour-et-desinstaller.md` |
| Désinstallation (2 couches, ordre imposé) | `01-demarrer/mettre-a-jour-et-desinstaller.md` |
| Dépendances externes (GSD / Superpowers) | `01-demarrer/mettre-a-jour-et-desinstaller.md` + `02-concepts/vibeflow-gsd-superpowers.md` |
| Sécurité (auditable, idempotent, backup, zéro hook) | `07-sous-le-capot/l-engine-d-install.md` (idempotence, sauvegarde, script lisible, "ce que VibeFlow n'exécute pas") |
| Troubleshooting (4 pannes) | `01-demarrer/depannage-installation.md` — **les 4 mêmes pannes, dans le même ordre** |

Les deux répétitions internes d'`INSTALL.md` (D-9 de la mission : « lancement toujours manuel »
dite à §3.4 et §3.10) disparaissent avec le fichier long — le manuel ne les répète pas non plus
(`depannage-installation.md` renvoie explicitement à `installation.md` plutôt que de redire le
fait).

**Verdict** : couverture intégrale confirmée sur pièce (lecture des 9 pages ci-dessus avant toute
coupe) → `INSTALL.md` réduit à un stub de redirection, conformément à **D-8**.

### Section « 📦 Modules » des deux README — chaque module et chaque nom cité a une case

Table de coïncidence module → page catalogue (les 17 modules du README sont exactement les 17 du
catalogue, recensés un par un) :

| Groupe README | Modules | Page manuel |
|---|---|---|
| Socle | conductor, planning-core, validator, skill-creator, consolidator, infrastructure-audit, audit-architecture | `03-modules/catalogue.md` §« Le socle de gouvernance » |
| Orchestrateurs | dev-orchestrator, design-orchestrator, content-bundle, business-pilot-bundle, growth-bundle | `03-modules/catalogue.md` §« Les orchestrateurs » |
| Spécialisés | software-architecture, kpi-analyst, mobile-test, mobile-test-team, reference | `03-modules/catalogue.md` §« Les capacités spécialisées » |

Les noms d'agents et de skills retirés des cellules « What it does » (ex. `vibeflow-conductor`,
`vf-dev-manager`, `vf-coder`/`vf-reviewer`/`vf-auditer`, `vf-business-manager` + ses workers, etc.)
sont couverts, plus en détail qu'au README, par `06-reference/agents.md` (31 agents, table complète
avec module/famille/modèle) et `06-reference/skills.md` (20 skills, groupés par module, avec la
phrase qui déclenche chacun). Vérifié un par un pour les 17 lignes avant coupe — aucun nom retiré
du README n'est absent de ces deux pages.

**Exception délibérée, gardée intacte** : la mention `` `/vf-design` and `/vf-sketch` `` dans la
ligne `design-orchestrator` n'a **pas** été coupée. `manual/fr/06-reference/skills.md:112` et
`manual/fr/06-reference/commandes.md:92` (+ leurs pendants EN) citent explicitement ce fragment du
README comme preuve d'une confusion réelle et documentée (ces deux skills apparaissent au tableau
Modules du README comme s'il s'agissait de commandes, alors qu'aucune n'a de fichier sous
`plugin/commands/`). Le supprimer aurait rendu cette citation du manuel fausse.

### Colonnes « Ver. » et « Type » du tableau Modules — non touchées

Aucune page du manuel ne porte de tableau équivalent par-module pour le champ « Type »
(agent/skills/scripts/…) — `03-modules/ou-vit-un-module.md` décrit l'anatomie générique
(`skills/`, `agents/`, `scripts/`, `references/`, `hooks/`, `rules/`, `config/`) mais jamais
quel module porte quelle combinaison. Case non remplie → colonne gardée intégralement. La colonne
« Ver. » n'a pas été touchée non plus, par prudence (l'interdit porte sur « aucun bump, aucun tag »
et sur les fichiers de la triade de release ; retirer une colonne de versions existante est un
geste plus proche d'un fix de dette documentaire que d'un dégraissage, hors du mandat reçu).

## Écart assumé vis-à-vis de D-7 (signalé pour arbitrage du manager)

`.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md` (D-7) vise 120-160 lignes par
README (plafond 200) et classe les sections « dev cycle », « long missions », « beyond dev »,
« memory », « architecture » comme des *workflows* à faire migrer intégralement.

En construisant la table de couverture, j'ai trouvé deux points qui contredisent une migration
intégrale de ces sections, et j'ai choisi de m'arrêter avant de les casser plutôt que de suivre
D-7 à la lettre :

1. **`manual/fr/06-reference/couts-et-modeles.md` (§« Ce que dit le README, daté ») et son
   pendant EN citent et reproduisent, **comme leur propre source nommée**, le tableau
   `### Efficiency, quantified` / `### L'efficience, chiffrée` du README — littéralement : « Le
   README racine du dépôt chiffre cinq leviers d'efficience dans sa section « L'efficience,
   chiffrée »… reproduite ici avec sa source ». Couper ou réécrire ce tableau aurait rendu cette
   citation manuel fausse sans que je puisse la corriger (`manual/**` en écriture est réservé à
   l'ajout de contenu manquant, pas à la resynchronisation d'une page existante).
2. **`manual/fr/07-sous-le-capot/contribuer-et-aller-plus-loin.md`** cite « la promesse de
   confiance, déjà formulée une fois au README du dépôt sous cette forme exacte » — un ancrage
   supplémentaire sur la stabilité du contenu README que je n'ai pas cherché à percer davantage.

**Décision prise** : `INSTALL.md` et la section Modules (les deux zones sans dépendance manuel
entrante trouvée) ont reçu le dégraissage complet prévu par D-7/D-8. Les sections narratives
(pitch du cycle dev, missions longues hors tableau d'efficience, beyond-dev, mémoire, architecture)
n'ont **pas** été réécrites : elles restent au niveau pitch qu'elles avaient déjà (aucune n'est une
procédure pas-à-pas — ce sont des diagrammes + quelques puces de positionnement), et la
vérification a montré au moins deux points d'ancrage réels vers leur contenu exact. Aller plus
loin sur ces sections spécifiques demanderait soit de resynchroniser les pages manuel concernées
dans la même vague (hors du périmètre d'écriture donné : `manual/**` seulement pour combler un
manque, pas pour resynchroniser), soit un arbitrage explicite du manager sur lequel contenu
doit primer. Je remonte ce point plutôt que de trancher seul.

## Avant / après en lignes

| Fichier | Avant | Après | Delta |
|---|---:|---:|---:|
| `README.md` | 295 | 297 | +2 |
| `README.fr.md` | 301 | 303 | +2 |
| `INSTALL.md` | 192 | 22 | **-170** |
| **Total** | **788** | **622** | **-166 (-21 %)** |

Les deux README gagnent 2 lignes chacun malgré la coupe : le tableau Modules est un ensemble de
lignes markdown à une ligne physique par module (raccourcir une cellule ne change pas le nombre de
lignes du fichier), et les 4-5 lignes de liens vers le catalogue/skills/agents/commandes du manuel,
ajoutées en tête de tableau, pèsent plus que ce que le compteur `wc -l` peut récupérer côté
tableau. Le vrai gain de dégraissage des deux README est en **poids de caractères**, pas en nombre
de lignes : `git diff --stat` sur les trois fichiers rapporte 36 insertions / 202 suppressions —
la quasi-totalité de ce volume de suppression vient d'`INSTALL.md`, mais les cellules du tableau
Modules ont aussi perdu, en moyenne, un tiers à la moitié de leur texte par ligne (noms d'agents et
de skills retirés, remplacés par un renvoi vers `agents.md`/`skills.md`).

## Sort d'`INSTALL.md` — conforme à la recommandation reçue et à D-8

`INSTALL.md` devient un pointeur de 22 lignes : les 2 commandes d'installation restent visibles en
bas de fichier (le « quickstart copiable » que rien ne doit cacher), 5 liens vers les pages
`01-demarrer/` du manuel FR couvrent l'intégralité de l'ancien contenu, un 6ᵉ lien vers
`07-sous-le-capot/l-engine-d-install.md` couvre l'ancienne section Sécurité, et une ligne dédiée
renvoie le lecteur anglophone vers `manual/en/01-get-started/installation.md`.

**Le lien entrant réel signalé dans le digest** (`plugin/consolidator/README.md:32` →
`[INSTALL.md du repo racine](../INSTALL.md)`) a été vérifié sur pièce : depuis
`plugin/consolidator/README.md`, `../INSTALL.md` résout vers `plugin/INSTALL.md`, qui **n'existe
pas** — c'est un lien mort **préexistant**, déjà signalé par un audit antérieur
(`reports/validator/2026-07-25-validator.md:224`, finding F10, jamais corrigé depuis). Il n'est ni
créé ni aggravé par ce mandat : la cible qu'il vise (`INSTALL.md` racine) existe toujours, seul le
chemin relatif compte un `../` de trop. Hors périmètre d'écriture (`plugin/**` interdit) — je le
remonte comme finding plutôt que de le corriger.

Les deux autres liens entrants vérifiés (`README.md:189`, `README.fr.md:194`,
`[INSTALL.md](./INSTALL.md)`) résolvent toujours, sans changement de chemin nécessaire.

## Résultat du balayage de liens (vérification exigée)

- **Liens relatifs des 3 fichiers modifiés** : script Python dédié, résolution de chaque
  `[label](cible)` non-`http(s)`/non-`mailto`/non-`#ancre` relative au dossier du fichier source —
  **tous résolvent**, y compris les 15 nouveaux liens vers `manual/fr/**` et `manual/en/**`.
- **Ancres supprimées** : aucune section `##`/`###` n'a été retirée dans les deux README (12/12
  inchangé) ni dans `INSTALL.md` (devenu un pointeur sans sous-titres `##`) — aucun lien externe
  vers une ancre `INSTALL.md#...` n'existe dans le dépôt (vérifié par grep), donc aucune ancre
  cassée.
- **Citations exactes de texte retiré** : recherche des fragments de texte coupés dans le tableau
  Modules (ex. « ADR-045 in 1 hop », « target detection, build-if-missing, Maestro regression,
  timestamped ») ailleurs dans le dépôt — aucune occurrence, aucune citation cassée.
- **`bash manual/.tools/check-manual.sh`** : exit 0 (7 contrôles verts) — logique, aucun fichier
  sous `manual/` n'a été touché par ce mandat.
- **Parité de structure** : `README.md` et `README.fr.md` comptent toujours 12 sections `##`
  chacun, dans le même ordre.

## Ce qui n'a pas bougé

- Badges, historique des versions (table « Versioning »), triade de release
  (`VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`) : intouchés.
- Sections Trust/Confiance, Authors/Auteurs, License/Licence : intouchées mot pour mot.
- Colonnes « Ver. » et « Type » du tableau Modules, et le tableau « Efficiency, quantified » /
  « L'efficience, chiffrée » : intouchés (justifié ci-dessus).
- Aucun numéro de version en dur ajouté nulle part.
- `manual/**`, `.gitignore`, `.github/**`, `scripts/**`, `plugin/**`, `docs/**`, `CHANGELOG.md`,
  `VERSION`, `.claude-plugin/**`, `.planning/ROADMAP.md`, `.planning/STATE.md` : aucun touché.
- Aucun bump de version, aucun tag créé.

## Fichiers touchés (à committer par chemin explicite)

```
README.md
README.fr.md
INSTALL.md
.planning/phases/VFDO-26-manuel-utilisateur-vibeflow-manual/26-14-SUMMARY.md
```
