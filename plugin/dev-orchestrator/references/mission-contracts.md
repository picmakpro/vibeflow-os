# Référence — Contrats de mission (équipe manager)

> Source unique des contrats qui relient la conversation principale, le manager (`vf-dev-manager`)
> et le mode autonome (`vf-auto`). Consommée par : `AGENT.md` (router), `skills/vf-auto/SKILL.md`,
> `agents/vf-dev-manager.md`. **DRY : ne dupliquer ces contrats nulle part — y renvoyer.**
> Spec d'origine : docs/superpowers/specs/2026-07-09-dev-manager-team-design.md (DM1-DM6).

## Brief de mission (main → manager)

Le dispatcheur (router ou vf-auto) passe au manager un brief **minimal**. Le disque
(`.planning/`) reste la source de vérité : le brief ne porte QUE ce qui n'y est pas.

```
MISSION
- Périmètre : <phases ciblées (numéros) OU objectif libre>
- Mode : superviser (checkpoints humains) | autonome (les panels tranchent)
- Contraintes session : <décisions déjà prises en conversation qui engagent la mission — 2-3 lignes max>
- Budget : <optionnel : temps / tentatives ; sinon défauts du manager>
```

Le brief peut aussi être du **langage naturel brut** (« finis la milestone, la nuit ») : le
manager le mappe lui-même vers périmètre/mode/contraintes via la carte d'intention
(`intent-routing.md`) — il demande (AskUserQuestion) seulement si le périmètre reste
inexploitable. Le manager relit lui-même `.planning/ROADMAP.md`, `.planning/STATE.md`,
`.planning/PROJECT.md` — le brief ne les paraphrase jamais.

## Digest de mission (manager → workers)

Le disque reste la source de vérité, mais chaque mandat de worker **embarque un digest ≤ 30
lignes** qui amortit les relectures intégrales de `.planning/` à chaque étage (audit
2026-07-25 : 100-200k tokens de pure relecture par étape sans lui) :

```
DIGEST (cache — le disque fait foi)
- Mission : <objectif en 1 ligne> · Mode : <superviser|autonome>
- Étape courante : <n° + objectif + critères de succès>
- Périmètre de fichiers du nœud : <déclaré au dag add>
- Décisions actives : <2-5 lignes — panels tranchés, contraintes session>
- Verdicts amont utiles : <revue/audit/test pertinents pour ce mandat>
- Conventions cibles : <2-3 lignes du CLAUDE.md projet qui engagent ce mandat>
```

Le worker lit le digest D'ABORD, et ne relit du disque que ce que son mandat exige
(index-first). Un digest contredit par le disque → le disque gagne, et le worker le signale.

## Rapport de mission (manager → main)

Retour **compact**. Le détail vit sur disque, pas dans la conversation.

```
RAPPORT DE MISSION
- Verdict global : ✅ | partiel | bloqué
- Par sprint : fait / verdicts (recette, revue, audit) / commits (SHA)
- Décisions prises en autonomie (et par quel panel)
- Blocages & points nécessitant l'utilisateur
- Rapport détaillé : <chemin du fichier écrit sur disque>
```

## Signaux « mission » (détection côté router)

≥ 1 signal déclenche la **PROPOSITION** du manager — jamais le dispatch d'office :

- **multi-phases explicite** : « phases 3 à 5 », « toute la milestone », « enchaîne les sprints » ;
- **durée / absence** : « la nuit », « pendant que je suis pas là », « demain matin je veux… » ;
- **étages multiples combinés** : la demande couvre build + test + revue/audit d'un coup ;
- **longue haleine estimée** : la demande couvre plus d'une étape de la feuille de route.

Tâche simple sans signal → routage direct **sans question** (zéro friction sur le quotidien).

## Seuil de bascule (vf-auto)

`SEUIL_EQUIPE = 3` — N = étapes restantes ciblées (`gsd-sdk query roadmap.analyze`) :

- **N < SEUIL_EQUIPE ET aucun signal de durée** → moteur direct (boucle autonome inline, moins chère).
- **N ≥ SEUIL_EQUIPE OU signal de durée** → équipe (`Task(vf-dev-manager)` avec le brief ci-dessus).

Le signal de durée **GAGNE** en cas d'ambiguïté (N=2 mais « la nuit » → équipe). Seuil ajustable
ici et ici seulement.
