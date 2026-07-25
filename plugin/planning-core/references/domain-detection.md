# DOMAIN-DETECTION — Inférer le métier d'un lab pour proposer profil + extension

> Référence du skill `vf-planning`. **Heuristiques de jugement, pas une règle déterministe.** Le
> skill LIT le contexte et DÉCIDE ; il ne fait pas tourner un détecteur figé qui imposerait une forme.
> C'est le garde-fou anti-biais : on adapte au métier réel, jamais l'inverse.

---

## Pourquoi par jugement et pas par script

Un détecteur bash (« il y a un `package.json` donc c'est du dev ») se trompe : un lab de contenu peut
avoir un site, un lab dev peut produire surtout de la doc. La détection fiable lit le **sens** du lab
(sa charte, son vocabulaire, ses livrables), pas seulement des signaux de surface. D'où : le skill
raisonne sur les signaux ci-dessous, et **en cas de doute pose une question courte** plutôt que de
deviner. Mieux vaut un profil léger + une question qu'un profil complet imposé à tort.

## Où lire les signaux (par ordre de force)

1. **`CLAUDE.md` / charte du lab** — la source la plus forte : que dit le lab de sa propre mission ?
2. **Registres `.claude/memory/`** — de quoi parlent les DECISIONS/LEARNINGS ? (code ? contenu ? vente ?)
3. **`docs/` et `README`** — vocabulaire dominant.
4. **Structure de fichiers** — signal *faible*, à croiser, jamais décisif seul.

## Grille de lecture (signaux → métier → proposition)

| Signaux dominants | Métier probable | Profil proposé | Extension suggérée |
|---|---|---|---|
| Code source, stack technique, tests, `src/`, build | Dev / produit technique | **Complet** | `codebase/` |
| Calendrier éditorial, angles, formats, audience, posts | Contenu / éditorial | **Standard** | `editorial/` |
| ICP, séquences, offres, objections, pipeline, closing | Vente / growth | **Standard** | `pipeline/` |
| Pièces, exigences réglementaires, statuts de dossier | Montage de dossier | **Standard** | `dossiers/` |
| Système visuel, déclinaisons, références, identité | Design | **Standard** ou Léger | `design/` |
| Sources, hypothèses, protocoles, synthèses | Recherche | **Standard** | `corpus/` |
| Idéation, veille, one-shot, peu d'étapes | Exploratoire / ponctuel | **Léger** | aucune |
| Signaux mêlés / illisibles | Indéterminé | **Léger** + 1 question | à décider avec l'utilisateur |

> Les noms d'extension sont des **exemples**. Si le métier d'un lab ne colle à aucune ligne, le skill
> nomme l'extension d'après le vocabulaire réel du lab — il n'a pas de catalogue fermé à appliquer.

## Bascule dev → moteur de développement (ADR-054)

La première ligne de la grille (« Code source, stack technique, tests, `src/`, build → Dev ») ne
conduit **plus** à scaffolder un tronc `.planning/`. Elle reste une **lecture du métier** valide ;
c'est sa **conséquence** qui change. Sur un lab dev, le planning du projet appartient au moteur de
développement ; `vf-planning` tient l'altitude lab et redirige. Voir `references/gsd-handoff.md`.

Ce que cela ne change pas : **le métier reste du jugement.** `scripts/detect-gsd-engine.sh` n'infère
aucun métier — il constate un fait (« un moteur de planning est-il en place ? »). Ses signaux de code
(`package.json`, `go.mod`, `*.xcodeproj`…) servent à déclencher un **examen**, jamais à rendre un
verdict : un lab de contenu qui héberge un site web les déclenche, sort en **exit 2** s'il porte déjà
un socle de facture `planning-core` (**exit 3** sinon), et **reste non-dev dans les deux cas** — le
jugement de cette référence tranche seul, et il conclut « contenu ». Le principe de cette référence
est intact : on lit le sens du lab, pas sa surface.

## Auto-infusion à l'installation (bootstrap léger, universel)

On veut qu'un lab fraîchement installé **s'amorce proprement** sans rien forcer :

1. À l'install du module, `.planning/` n'existe pas encore (c'est voulu — on ne scaffolde pas à
   l'aveugle au moment du `cp`).
2. Le **garde-fou** `scripts/check-planning-state.sh` détecte l'absence de `.planning/` (exit 3) et
   le **surface** — en `/checkpoint`, ou via un hook SessionStart **opt-in** (wiring documenté, jamais
   auto-injecté dans `settings.json`).
3. L'utilisateur (ou un agent en autonomie) invoque alors `/vf-planning`, qui détecte le métier
   (cette grille) et pose le socle adapté.

Ainsi l'infusion est **déclenchée mais non imposée** : le lab signale qu'il manque un socle, et le
socle posé épouse le métier — au lieu d'un `.planning/` générique plaqué par défaut.

### Wiring du hook SessionStart (optionnel, à coller dans `.claude/settings.json` du lab)

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command",
        "command": "bash .claude/scripts/check-planning-state.sh --quiet --max-age-days 7 || true" } ] }
    ]
  }
}
```

`|| true` garantit que le hook reste **advisory** (n'échoue jamais une session). Il rappelle juste de
poser ou rafraîchir le socle.
