# Mission — Phase 37 : spike de portabilité multi-runtime (Codex, OpenCode, Kimi)

**Date** : 2026-08-28. **Milestone** : `fiabilite-v1.0`. **Branche** :
`feat/phase-37-spike-portabilite-multi-runtime`. **Sources** :
`.planning/phases/VFDO-37-portabilit-multi-runtime-spike-codex-opencode-kimi/DISCUSS.md` et
`SPIKE-REPORT.md`.

## Verdict — en deux morceaux, pas un go/no-go sec

**1. Le runtime Codex est apte, sur la profondeur mesurée.** Mesuré en exécution réelle (compte
ChatGPT, Codex CLI 0.150.1) : profondeur **3 arêtes** (compteur natif `session_meta`,
`DEPTH=1/2/3`) — le `maxDepth: 1` annoncé par le registre `capability-registry.cjs` est faux, et
seules 2 arêtes sont utilisées par la topologie actuelle du team-kernel. Dispatch nommé
fonctionnel, `model` réglable par worker (`fork_turns: "none"` + `model`, mesuré), rapport typé
`{statut, findings, noeuds_debloques}` reconstructible par convention (JSON en cwd partagé, ou
`codex exec --output-schema`) et fiable 2/2 à la mesure.

**2. Le chemin d'artefacts de gsd-core ne l'est pas.** La surface visée (8 modules de conversion/
install/layout/skill) est déclarée **interne** par le contrat écrit de gsd-core lui-même
(`host-integration-sdk.cjs`, seule frontière publique documentée, 18 clés — un filtre
`convert|artifact|layout|installPlan|Skill` sur ces clés rend 0 résultat). Le pipeline d'install
n'est pas générique : il résout sa source par remontée `__dirname`, pas par un point d'entrée
public. La conversion mesurée (156 cas) dégrade silencieusement — 0 exception, 0 diagnostic — sur
les champs qui portent les garanties d'agent (`model`, `memory`, `tools`, allowlist).

**Le résultat central du spike** : la doctrine posée au cadrage — « VibeFlow consomme la surface
multi-runtime de gsd-core, il ne la réimplémente pas » — désigne exactement la partie qui **ne
tient pas** (le chemin d'artefacts gsd-core), tandis que la partie que le cadrage jugeait la plus
risquée (le runtime lui-même, l'équipe de mission hors Claude) **tient très bien**. Le risque était
mal placé au cadrage.

## La recommandation est une recommandation

Le go/no-go sur une éventuelle phase de livraison est la décision de Samuel (ADR-031) — rien ne se
lance sans son arbitrage : ni phase de livraison, ni gate de fidélité, ni démarche amont vers
gsd-core. Ce spike expose 4 voies coûtées (`DISCUSS.md` §Décision à prendre,
`SPIKE-REPORT.md` §Recommandation), aucune tranchée :

1. **Dépendre de l'interne tel quel** — zéro garantie SemVer, rupture possible à chaque mise à jour
   de gsd-core sans préavis.
2. **Demander l'élargissement du SDK public en amont** (upstream gsd-core) — délai hors contrôle de
   VibeFlow.
3. **Adaptateur VibeFlow minimal** — maintenance d'une couche de conversion propre, garanties
   ADR-044 restaurées sous contrôle VibeFlow.
4. **Renoncer** (rester Claude-only) — zéro portabilité, zéro dette supplémentaire.

Recommandation de la mission (non tranchée) : voie 3 combinée à la voie 2 en parallèle sans
dépendance bloquante.

## Le coût du process

La mission a compté **3 tours de revue adversariale** sur `DISCUSS.md`/`SPIKE-REPORT.md`. Chaque
tour a trouvé un défaut réel — et **deux de ces défauts avaient été introduits par la correction du
tour précédent**. Un document dense en chiffres croisés régresse à chaque retouche : c'est le vrai
coût d'un spike rigoureux, plus révélateur qu'un simple décompte de tours.

Le premier défaut trouvé était lui-même un **rouge auto-déclaré** — un décompte à charge contre une
source, non reproductible — dans le document même qui dénonce ailleurs les verts auto-déclarés
(cf. `DISCUSS.md` Q2, le chiffrage « 8 scripts / 65 » retiré faute de méthode consignée).

## Candidat pour la suite, nommément

`description: >` (scalaire replié YAML) sur **16 des 25 `SKILL.md`** : les trois convertisseurs
réduisent la description au littéral `>` — `extractFrontmatterField`
(`runtime-artifact-conversion.cjs:924-930`) capture la frontmatter par une regex mono-ligne
`^description:\s*(.+)$`, incompatible avec un scalaire replié dont le texte continue sur les
lignes indentées suivantes. **0 exception, 0 diagnostic**, sur les trois cibles. Chiffre
contre-vérifié deux fois (`DISCUSS.md` Q3 : 15/21 skills installables ; `SPIKE-REPORT.md` §Fidélité
de conversion : même mesure, même méthode). La description est ce qui rend un skill déclenchable —
sa perte silencieuse est une dégradation au moins aussi large que celle mesurée côté agents.
**Corrigeable côté VibeFlow sans rien attendre de l'amont.**

## Ce qui reste inconnu (non comblé par ce spike)

- Profondeur Codex > 3 arêtes non testée.
- Saturation des 4 slots de concurrence non provoquée (largeur non confrontée au dispatch parallèle
  de frontière du team-kernel).
- Rôles custom `~/.codex/agents/*.toml` non utilisés (`agent_role` resté `null` dans les mesures).
- Acceptation réelle des artefacts convertis par OpenCode et kimi-code — aucun des deux runtimes
  n'est installé sur le poste de mesure.
- Que kimi-code **honore** effectivement `model`/`memory`/`tools`/`disallowedTools` (conservés à la
  conversion, 6/31 fichiers modifiés par les 4 étapes transverses, aucun champ perdu) — non vérifié
  en runtime.
- Q4b (`AskUserQuestion`/escalade humaine) mesure un produit non désambiguïsé entre Kimi et Kimi
  Code — le ROADMAP (l. 1011-1012) avertit que ce sont deux produits distincts, non tranché par ce
  spike.
- Support d'élicitation OpenCode annoncé sur branches dev/v2, non vérifié en release stable.
- L'échappatoire `.gsd-source` a deux consommateurs aux sémantiques incompatibles (Q1) — constaté,
  non résolu par ce spike.

## Gestes de mission

- Ce nœud `docs` n'a pas invoqué `driver-lock.sh` — mandat d'hygiène documentaire pur, un seul
  worker sur ces trois fichiers (le dossier de phase, seul touché par un autre worker en parallèle,
  était explicitement hors périmètre).
- `check-mission-invariants.sh` → SAIN (exit 3) : tous les globs de
  `.planning/MISSION-INVARIANTS.md` matchent encore au moins un fichier suivi.
- Branche dédiée `feat/phase-37-spike-portabilite-multi-runtime` — aucun merge, aucune PR, aucun
  tag, aucune release.
- `ROADMAP.md` intouché sur le point contesté du cadrage (« 9/25 appellent des skills `gsd-*` ») —
  sa mesure et sa nuance vivent dans `DISCUSS.md`.

## Rapport final (`SPIKE-REPORT.md`, verbatim)

```json
{
  "statut": "human_needed",
  "findings": [
    {
      "sujet": "Doctrine de cadrage vs mesure",
      "constat": "\"VibeFlow consomme la surface gsd-core, ne la réimplémente pas\" tient pour le runtime Codex (profondeur 3 mesurée, pas 1) mais pas pour le chemin d'artefacts gsd-core (interne par contrat écrit, pipeline d'install non générique)",
      "severity": "majeur",
      "action": "ask-user",
      "ref": "DISCUSS.md#décision-à-prendre-non-tranchée--adr-031"
    },
    {
      "sujet": "Fiabilité capability-registry.cjs",
      "constat": "3 constats de non-fiabilité autour des descripteurs, dont un seul est une erreur du registre vérifiée en exécution (maxDepth codex 1 vs 3 réel) ; un deuxième est une erreur de lecture du cadrage (backgroundDispatch — le registre avait raison) ; un troisième est une obsolescence documentaire non vérifiée en runtime (kimi-code) — bonne source, jamais une preuve",
      "severity": "mineur",
      "action": "no-op",
      "ref": "DISCUSS.md#q5--déclaration-de-capacité"
    },
    {
      "sujet": "Fidélité de conversion",
      "constat": "156 conversions mesurées, 0 erreur machine, dégradation massive et silencieuse côté agents (model/memory/tools/disallowedTools/vf-internal/allowlist, sur codex et opencode — kimi-code : 31 agents posés avec `converter: null`, 6/31 modifiés par les 4 étapes transverses du pipeline d'install, champs conservés) ET côté skills (description: perdue en entier sur 15/21 skills installables, sur les trois cibles, extractFrontmatterField ne gère pas le scalaire replié YAML) — aucun signal ne distingue converti de converti-et-mort",
      "severity": "majeur",
      "action": "ask-user",
      "ref": "DISCUSS.md#fidélité-de-conversion--la-dégradation-silencieuse-chiffrée"
    },
    {
      "sujet": "Voie de suite (adaptateur / upstream / dépendance interne / renoncer)",
      "constat": "4 voies coûtées dans DISCUSS.md, aucune tranchée par ce spike ; recommandation formulée (adaptateur minimal + démarche amont en parallèle) sans autorité de décision",
      "severity": "bloquant",
      "action": "ask-user",
      "ref": "DISCUSS.md#décision-à-prendre-non-tranchée--adr-031"
    }
  ],
  "noeuds_debloques": []
}
```
