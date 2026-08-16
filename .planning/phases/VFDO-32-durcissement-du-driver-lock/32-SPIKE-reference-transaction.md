# Spike `reference-transaction` — Phase 32, research flag bloquant

> **Statut** : clos le 2026-08-16. **Verdict : PAS SÛR pour bloquer.**
> Le ROADMAP (§Phase 32, critère de succès n°3) conditionnait le blocage du checkout à ce que
> « le spike `reference-transaction` le prouve sûr ». Il ne le prouve pas. Ce document est la
> preuve mesurée qui ferme la question ; il est consigné sur disque à la demande explicite de
> Samuel (2026-08-16) pour que la conclusion ne se rejoue pas de mémoire à la phase suivante.

Environnement mesuré : **git 2.50.1 (Apple Git-155)**, macOS, backends `files` **et** `reftable`,
7 dépôts jetables (labs 1→7). Aucun fichier du dépôt modifié pendant le spike.

---

## 1. Le doute central du ROADMAP est LEVÉ — et ce n'est pas ce qui tranche

Le ROADMAP notait la « couverture checkout incertaine ». L'incertitude venait de ceci : un
`git checkout <branche>` ne met à jour que le **symref HEAD**, et git n'a longtemps pas fait
passer les symrefs par une transaction de références.

**Mesuré : sur git ≥ 2.46, le hook VOIT bien le checkout de branche.**
`git checkout feat` émet en phase `prepared` :

```
0000000000000000000000000000000000000000 ref:refs/heads/feat HEAD
```

Le mécanisme est `symref-update`, arrivé en **git 2.46.0**. Le hook lui-même existe depuis
**git 2.28** ([commit 675415976](https://github.com/git/git/commit/675415976704459edaf8fb39a176be2be0f403d8),
[thread amont](https://public-inbox.org/git/1de96b96e3448c8f7e7974f7c082fd08d2d14e96.1592475610.git.ps@pks.im/T/)),
mais **sans les symrefs**.

**Conséquence directe, et première raison de méfiance** : sur git 2.28 → 2.45, le hook est
**aveugle au checkout de branche**. Un lab sur Debian stable (git 2.39) croirait la garde active
alors qu'elle ne voit rien. Toute implémentation devrait donc gater sur la version et se dégrader
explicitement. *(Non mesuré : aucun binaire git < 2.50 disponible sur la machine ; établi par la
doc et le thread amont.)*

La détection est donc **réalisable**. Le blocage, non — pour trois raisons indépendantes, dont
chacune suffit à trancher.

---

## 2. Raison n°1 — le blocage rend le dépôt irrécupérable (labs 3 et 6)

C'est la mesure décisive. Hook sortant 1 en phase `prepared` sur tout déplacement de `HEAD` :

```
git rebase main        → rc=128, "fatal: ref updates aborted by hook"
   état : HEAD DÉTACHÉ, .git/rebase-merge PRÉSENT (rebase à moitié appliqué)

git rebase --abort     → rc=128, "fatal: ref updates aborted by hook"
   état : toujours détaché, toujours wedgé, +1 fichier sale
```

**La commande de secours est bloquée par la garde elle-même** : `rebase --abort` doit repointer
`HEAD` sur la branche, donc il émet exactement la signature qu'on voulait interdire. Le dépôt
n'est sorti de cet état **qu'après désarmement du hook** (mesuré : `rebase --abort` hook désarmé
→ `HEAD=refs/heads/feat`, `rebase-dir=none`).

Une garde qui piège l'utilisateur dans un rebase inachevable **et neutralise sa propre issue de
secours** n'est pas déployable.

---

## 3. Raison n°2 — contournement trivial, déjà pratiqué par le conductor lui-même (lab 4)

```
git checkout feat                                → REFUSÉ (rc=128)
git -c core.hooksPath=/dev/null checkout feat    → "Switched to branch 'feat'"   ← PASSE
printf 'ref: refs/heads/feat\n' > .git/HEAD      → PASSE (aucune transaction)
chmod -x .git/hooks/reference-transaction        → PASSE (git émet juste un hint)
git checkout --no-verify                         → n'existe pas sur checkout
git symbolic-ref HEAD refs/heads/feat            → REFUSÉ (bien couvert)
```

Le premier contournement est fatal au raisonnement : **`plugin/conductor/scripts/` passe déjà
`-c core.hooksPath=/dev/null` sur ses propres appels git** —
`check-mission-invariants.sh:101`, `check-map-drift.sh:104`, `check-workstream-pointer.sh:124`,
`check-state-integrity.sh:105`.

La garde serait donc **aveugle à l'outillage maison**, et n'importe quel agent la lève d'un flag.
Un verrou que le porteur du verrou désarme par convention n'est pas un verrou.

---

## 4. Raison n°3 — dommages collatéraux sur des gestes qu'on veut préserver

- **`git worktree add`** émet la **signature identique** au checkout (`ref:refs/heads/wt3b HEAD`)
  → refusé, rc=128, **et la branche `wt3b` reste créée alors que le worktree n'existe pas**
  (transaction séparée déjà committée). Or VibeFlow prescrit précisément le worktree comme
  échappatoire quand le lock est tenu : **la garde casserait la porte de sortie qu'elle est
  censée pousser à emprunter.**
- **`git checkout -b brandnew`** : refusé, mais `refs/heads/brandnew` **existe** après coup
  (`YES-LEAKED`). Git crée la branche puis repointe HEAD en **deux** transactions ; bloquer la
  seconde laisse la première acquise.

---

## 5. Table de mesure — geste → hook → blocable → état après refus

| Geste | Hook déclenché ? | refname / new-value observés | Blocable ? | État du dépôt après refus |
|---|---|---|---|---|
| `checkout <branche>` | **oui** | `HEAD` ← `ref:refs/heads/feat` | oui | **sain** — HEAD inchangé, 0 sale, 0 `.lock`, fsck clean |
| `switch <branche>` | **oui** | idem | oui | **sain** |
| `checkout -b` / `switch -c` | oui (2 transactions) | `refs/heads/newb1` puis `HEAD` ← `ref:…` | partiellement | **branche fuitée**, HEAD non déplacé |
| `checkout <sha>` (détaché) | **oui** | `HEAD` ← `<sha>` (sans préfixe `ref:`) | oui, mais **seulement** avec la règle `ref == HEAD` ; une règle ciblée sur `ref:` le laisse passer → **bypass** | sain |
| `commit` | oui | `refs/heads/main` (+ bruit `AUTO_MERGE`) | non bloqué par la règle `ref==HEAD` (rc=0) | — |
| `merge` | oui | `ORIG_HEAD`, `refs/heads/main` | non bloqué (rc=0) | — |
| `rebase` | oui | `ORIG_HEAD`, `HEAD`, `refs/heads/feat`, puis `HEAD` ← `ref:…` | **bloqué malgré nous** | **WEDGÉ — `--abort` lui-même refusé** |
| `reset --hard` | oui | `ORIG_HEAD`, `refs/heads/main` | non bloqué (rc=0) | — |
| `fetch` | oui (si nouveautés) | `refs/remotes/origin/*`, `…/HEAD` ← `ref:…` | non bloqué par `ref==HEAD` | fetch no-op → hook **non** déclenché |
| `clone` | **non** dans le dépôt source ; le clone **n'hérite pas** du hook | — | non | — |
| `worktree add` | oui | `refs/heads/wt3b`, **`HEAD` ← `ref:…`**, `ORIG_HEAD` | **bloqué malgré nous** | **branche fuitée, worktree absent** |
| `worktree remove` | **non** | — | non | — |
| `stash push` | oui | `refs/stash`, `ORIG_HEAD`, `refs/heads/main` | non bloqué | — |
| `stash pop` | oui | `refs/stash` (+ phase `aborted`) | non bloqué | — |
| `gc` | **oui, massivement** — 36 lignes, **suppression de TOUS les refs** (repack) | tous `refs/heads/*` et `refs/remotes/*` en `<sha> → 0000…` | non bloqué par `ref==HEAD`, **mais un hook naïf le tue** (mesuré rc=128) | — |
| `status` / `log` / `diff` / `branch -a` | **non** | — | — | — |

**Bruit à filtrer** : chaque `checkout` et chaque `commit` émet 3 à 6 lignes parasites
`AUTO_MERGE` à valeurs tout-à-zéro, dont des phases `aborted`. Tout consommateur doit les ignorer.

**Règle naïve** (exit 1 sur tout `prepared`) : tue `commit` **et** `gc` (rc=128). À proscrire.
**Règle ciblée `ref == HEAD`** : la moins mauvaise — bloque `checkout` branche et `checkout <sha>`,
laisse passer `commit`, `reset --hard`, `merge`, `gc`. Mais c'est elle qui wedge `rebase` (§2) et
casse `worktree add` (§4).

---

## 6. Caveats sourcés

- [githooks(5)](https://git-scm.com/docs/githooks) confirme la sémantique mesurée : « The exit
  status of the hook is ignored for any state except for the "preparing" and "prepared" states.
  In these states, a non-zero exit status will cause the transaction to be aborted. » Et :
  « During the "preparing" state, symbolic references are not resolved. »
- **Une phase manquait à l'énoncé du research flag** : `preparing` existe aussi (refs pas encore
  verrouillées sur disque) et son exit non-zéro abort également. Bloquer en `preparing` serait
  marginalement plus propre (aucun lock posé) — cela ne change rien au verdict.
- **`old-value` est inexploitable sur un checkout** : mesuré systématiquement `0000…0000`. Le hook
  apprend la branche de **destination**, jamais celle d'**origine**. Pour un message « tu quittes
  la branche X », il faut lire `git symbolic-ref HEAD` soi-même, avant.

---

## 7. Contrainte de distribution — conflit frontal avec la doctrine du dépôt

`reference-transaction` est un hook **git**, pas un hook Claude Code :

1. **Non distribuable par le plugin.** Il vit dans `.git/hooks/`, hors de l'arbre versionné.
   Mesuré : `git clone` **ne le propage pas**. Chaque lab devrait l'installer par un geste local
   post-install — exactement le piège de la régression #38 (« armement sans précondition
   distribuée » : un réglage posé localement ne voyage pas).
2. **`core.hooksPath` déplace TOUT le répertoire, pas un hook.** Mesuré (lab 6) : `core.hooksPath`
   pointé ailleurs → `.git/hooks/reference-transaction` **totalement éclipsé**. Or le `CLAUDE.md`
   de ce dépôt prescrit `git config core.hooksPath scripts/hooks` pour armer le `pre-push` de
   discipline de release. **Les deux mécanismes s'excluent** : soit le hook va vivre dans
   `scripts/hooks/` (versionné — viable pour `vibeflow-os` lui-même, pas pour un lab qui installe
   le plugin), soit l'armement du pre-push le désactive **silencieusement**.

---

## 8. Ce qui reste utilisable du spike

**La détection est solide**, et une mesure la rend plus utile que prévu : **le hook hérite de
l'environnement de l'appelant** (mesuré : `CLAUDE_CODE_SESSION_ID` visible depuis le hook). Il
pourrait donc comparer l'`owner` du lock à la session appelante.

Cette piste n'est toutefois **pas retenue** pour la Phase 32 : le vecteur `PreToolUse` (§9) offre
la même discrimination **sans** la contrainte de distribution du §7, et couvre en plus le commit.

---

## 9. Décision prise sur la base de ce spike

**Arbitrage Samuel du 2026-08-16, option 1B.** Le blocage du checkout est retenu, mais porté par
un **autre mécanisme** : le guard `PreToolUse(Bash)` de LOCK-02, qui refuse **avant** que git ne
tourne.

Le critère de succès n°3 conditionnait le blocage à la sûreté de `reference-transaction` ; cette
sûreté n'est **pas acquise** (§2, §3, §4, §7). Le mécanisme retenu n'a **aucun** de ces défauts :

| Défaut de `reference-transaction` | Guard `PreToolUse(Bash)` |
|---|---|
| Wedge de `rebase`, `--abort` bloqué | git ne tourne jamais — aucun état intermédiaire possible |
| `worktree add` cassé, branche fuitée | geste nommément épargné (échappatoire déclarée) |
| Contournement `-c core.hooksPath=/dev/null` | sans effet — l'interception est en amont de git |
| Aveugle sur git < 2.46 | indépendant de la version de git |
| Non distribuable, éclipsé par `core.hooksPath` | distribué par `merge-hooks`, entrée née du mécanisme |

Portée assumée : le guard est **anti-accident, pas anti-adversaire**. Une session non armée, un
terminal humain, un IDE ou un interpréteur inline passent au travers — même clause de limite que
`guard-bash-registres.sh` (L26-27) et `guard-agent-write.sh` (L17-20).
