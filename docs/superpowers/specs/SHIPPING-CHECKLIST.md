# SHIPPING-CHECKLIST — VibeFlow plugin public

> ⚠️ **Ce document est une PROCÉDURE CONFIRMÉE HORS-AGENT pour les étapes §2 et §3.**
> Aucun agent autonome ne doit exécuter le flip public (`gh repo edit … --visibility public`)
> ni l'install du plugin. Ces actions sont **délibérées, quasi-irréversibles** et lancées
> **à la main par l'utilisateur** après confirmation (spec §12, décision ID2).
>
> L'executor du Plan 05-02 a uniquement : rédigé ce document et exécuté les vérifications
> §1 en **LECTURE SEULE** pour pré-cocher l'état constaté. Aucune visibilité de repo n'a été
> modifiée, aucune install réelle n'a été lancée.

Repo cible : `picmakpro/vibeflow-os`
Plugin : `vibeflow` (marketplace `vibeflow-os`)
Couvre : **PLUG-03** (flip public — documenté/gated) + **PLUG-04** (validation zéro-auth — documentée/gated).
Critère de succès Phase 5 #2 : « marketplace add + install fonctionnent en zéro-auth ».

---

## §1 — Checklist pré-public (à VALIDER AVANT le flip)

État constaté par l'audit en lecture seule du **2026-06-04** (HEAD au moment de l'exécution du Plan 05-02).

- [x] **Aucun secret dans l'historique ni l'arbre de travail.**
  - `git log --all --oneline | wc -l` → **50 commits** audités.
  - Scan motifs sensibles sur l'historique complet (`git log --all -p`) : motifs
    `AKIA[0-9A-Z]{16}`, `-----BEGIN … PRIVATE KEY-----`, `ghp_/gho_/ghu_/ghs_/ghr_…`,
    `sk-…`, `xox[baprs]-…`, et assignations `api_key|secret|token|password = <valeur ≥16 car.>`
    → **0 correspondance réelle**.
  - Le grep large (`AKIA|api_key|secret|token|password|-----BEGIN`) renvoie ~267 lignes,
    **toutes** issues de la **prose de planification** (specs, plans, threat models, et la
    commande d'audit elle-même). **Aucune** n'est un credential. Statut : **CLEAN**.
  - Fichiers sensibles à la racine et dans les modules (`.env*`, `*.p8`, `*.p12`, `*.cer`,
    `*credentials*`, `id_rsa*`) → **AUCUN trouvé**.
  - Recommandation : ce scan reste valable tant qu'aucun nouveau commit n'est ajouté.
    **Re-lancer le scan juste avant le flip** si des commits ont été poussés depuis.

- [x] **`LICENSE` présent à la racine et cohérent avec `plugin.json`.**
  - `LICENSE` présent (259 o) : `Copyright (c) 2026 picmakpro — All rights reserved`,
    « proprietary modules… restricted to authorized labs only ».
  - `plugin.json` → `"license": "UNLICENSED"`. ✅ **Cohérent** : pas de licence open-source
    accordée.
  - ⚠️ **Conséquence d'un repo rendu public avec cette LICENSE** : le repo devient
    **source-available**, pas open-source. Le **code et l'historique sont visibles** par
    quiconque, mais **aucun droit de réutilisation, modification ou redistribution n'est
    accordé** (« All rights reserved »). C'est un choix délibéré : la visibilité publique
    sert l'installation zéro-auth via marketplace, **sans** céder de droits. À confirmer
    explicitement avant le flip — si l'intention est d'autoriser la réutilisation, il faut
    d'abord changer la LICENSE et `plugin.json`.

- [x] **Manifestes valides.**
  - `jq empty .claude-plugin/plugin.json` → **VALID JSON**.
  - `jq empty .claude-plugin/marketplace.json` → **VALID JSON**.
  - `plugin.json` : `name: vibeflow`, `version: 2.3.0`, `skills: ./installer`,
    `hooks: ./installer/hooks/hooks.json`.
  - `marketplace.json` : `name: vibeflow-os`, plugin `vibeflow` `source: ./`,
    `version: 2.3.0` (aligné avec `plugin.json`).
  - **À cocher avant le flip** : revalider avec `claude plugin validate .` (validateur
    officiel Claude Code, cf. verify du Plan 05-01) sur la machine de shipping.

- [x] **`.gitignore` couvre caches/artefacts.**
  - Couvre `.vibeflow-cache/`, `.backups/`, `*.bak`/`*.bak-*`, `*.log`/`logs/`,
    `.DS_Store`/`._*`, `__pycache__/`/`*.pyc`, `.vscode/`/`.idea/`/`*.swp`.
  - ✅ Rien de sensible ni d'artefact runtime n'est censé être committé.

- [ ] **README / INSTALL à jour (flux 2-commandes, plus de clone manuel).**
  - ⚠️ **ACTION REQUISE AVANT/AU FLIP** : `README.md` mentionne encore le statut **« Privé »** :
    - ligne 4 : `> Privé. Maintenu par @picmakpro.`
    - ligne 105 : `- Repo privé`
    - ligne 124 : référence au lab principal `vibeflow-lab` (privé) — à conserver tel quel
      si ce lab reste privé.
  - Mettre à jour les mentions « Privé / Repo privé » du README **avant** ou **au moment**
    du flip public, pour ne pas laisser une doc qui contredit la visibilité réelle.
  - Vérifier que `INSTALL.md` décrit bien le flux **2 commandes** (`marketplace add` + `install`)
    et non plus un clone manuel (livré au Plan 05-01).

> **Pré-condition du flip (§2)** : tous les items §1 doivent être cochés, en particulier
> le README mis à jour et le scan secrets re-confirmé si de nouveaux commits ont été ajoutés.

---

## §2 — Étape MANUELLE confirmée hors-agent : flip public (PLUG-03)

> ⛔ **AVERTISSEMENT — ACTION QUASI-IRRÉVERSIBLE.**
> Rendre le repo public expose **tout le contenu ET tout l'historique git** de façon
> permanente (un repo re-privatisé reste considéré comme ayant été exposé). Cette action
> est **délibérée**, **confirmée explicitement par l'utilisateur**, et **JAMAIS lancée par
> un agent autonome**. L'executor s'arrête au checkpoint et ne touche pas à la visibilité.

**Pré-condition** : toute la checklist §1 cochée (secrets clean, LICENSE OK + conséquence
source-available assumée, manifestes valides, `.gitignore` propre, README mis à jour).

**Commande EXACTE à lancer par l'utilisateur** (ou par l'orchestrateur sur confirmation
explicite, hors de tout executor autonome) :

```bash
gh repo edit picmakpro/vibeflow-os --visibility public --accept-visibility-change-consequences
```

**Vérification** : sur GitHub, confirmer que `picmakpro/vibeflow-os` est bien public, ou :

```bash
gh repo view picmakpro/vibeflow-os --json visibility   # doit renvoyer {"visibility":"PUBLIC"}
```

> État au moment de la rédaction : `gh repo view picmakpro/vibeflow-os --json visibility`
> → `{"visibility":"PRIVATE"}` (repo **non** rendu public par le Plan 05-02 — conforme).

---

## §3 — Validation post-public : zéro-auth (PLUG-04)

À lancer **APRÈS** le flip §2, **par l'utilisateur**, idéalement depuis une machine **sans
auth GitHub** configurée pour ce repo (pour prouver le zéro-auth).

**Commandes EXACTES :**

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

**Résultat attendu** : l'ajout du marketplace et l'install réussissent **SANS
authentification GitHub** (repo public). À la **session suivante**, le hook `SessionStart`
ouvre **`/vibeflow-install`** automatiquement (1er lancement, marqueur d'install absent).

**Critères de validation (à cocher APRÈS exécution réelle, hors-agent) :**

- [ ] `claude plugin marketplace add picmakpro/vibeflow-os` réussit sans demander d'auth.
- [ ] `claude plugin install vibeflow` installe le plugin.
- [ ] `claude plugin details vibeflow` liste le skill `vibeflow-install` et le hook `SessionStart`.
- [ ] Nouvelle session Claude Code → l'UX `/vibeflow-install` s'ouvre automatiquement.

### Dépannage zéro-auth (IMPORTANT — pour que PLUG-04 ne soit pas une impasse)

Si `claude plugin marketplace add` sur le repo **fraîchement public** demande **ENCORE** une
authentification GitHub (cause probable : **cache GitHub côté Claude Code** OU **lag de
ré-indexation** du marketplace après le flip), dérouler cette procédure **avant** de conclure
à un échec :

1. **Purger l'entrée mise en cache :**
   ```bash
   claude plugin marketplace remove vibeflow-os
   ```
2. **Re-add → re-fetch propre :**
   ```bash
   claude plugin marketplace add picmakpro/vibeflow-os
   ```
3. **Vérifier que la visibilité publique est bien propagée côté GitHub :**
   ```bash
   gh repo view picmakpro/vibeflow-os --json visibility   # doit renvoyer "PUBLIC"
   ```
4. **Si la visibilité est correcte (`PUBLIC`) mais que l'auth persiste** : attendre **quelques
   minutes** (ré-indexation marketplace côté GitHub), puis **re-tenter le remove + add**.

> ❗ Ne **PAS** considérer **PLUG-04 comme échoué** tant que cette procédure (remove + re-add
> + vérif visibilité + attente ré-indexation) n'a pas été déroulée intégralement.

---

## Récapitulatif des dispositions de sécurité (threat model 05-02)

| Threat | Disposition | Couverture dans ce doc |
|--------|-------------|------------------------|
| T-05-05 secrets exposés au flip | mitigate | §1 audit secrets (clean) AVANT flip ; flip gated tant que §1 non cochée |
| T-05-06 exécution autonome irréversible | mitigate | §2 = checkpoint:human-action ; aucune commande de visibilité en task `auto` |
| T-05-07 flip non confirmé tracé | accept | confirmation explicite via resume-signal du checkpoint (STATE/SUMMARY) |
| T-05-09 auth résiduelle → PLUG-04 impasse | mitigate | §3 dépannage zéro-auth (remove + re-add + vérif visibilité + attente) |
