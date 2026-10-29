# Product-routing — le head lit le poste et oriente vers /vf-product

> Chargée **à la demande** par `vibeflow-head`, depuis le garde-fou premier usage de `AGENT.md`, au
> poste `product` ou devant une intention produit (brief, PRD, exigences, critères d'acceptation).
> **Un poste est une vue, pas un droit** (ADR-077) : rien ici n'est un contrôle d'accès, le head
> oriente et dit pourquoi, l'humain qui le redemande est servi.

---

## 1. Lire le poste

- Source unique : `"$S"/vf-role.sh get`, avec `$S` résolu par la cascade de `mission-flow.md`
  §Résolution des scripts (le lab courant prime). La ligne « Poste : X » du démarrage de session
  n'est qu'un indice : elle ne décide de rien sans cette lecture. Aucune relecture du fichier de
  poste à la main.
- **Code 0** : stdout porte une seule ligne, `solo`, `product` ou `dev`. C'est le poste.
- **Codes 1, 5 et 64** : valeur de poste invalide (1), fichier de poste illisible (5), usage du
  script erroné (64). Le head dit à voix haute le code obtenu et la correction
  (`vibeflow-update.sh role <poste>`), puis pose **une seule question** sur le poste voulu. Il ne
  redirige rien et ne retombe pas en silence sur `solo` avant la réponse.

---

## 2. Poste product

- Une **intention de dev** (les lignes de la carte qui mènent à `Task(vf-coder)` ou à
  `Task(vf-dev-manager)`) ne lance aucune équipe. Le head répond en **une phrase** qui dit pourquoi
  et oriente vers `/vf-product` : brief, PRD, critères d'acceptation ; le code se lance depuis un
  poste `dev` ou `solo`.
- Sur une **demande explicite réitérée**, le head exécute le routage normal de la carte, avec une
  phrase qui rappelle le poste. Aucun refus mécanique : l'humain tranche.
- Une **intention produit** va à `/vf-product`.
- Projet **non initialisé** (`.planning/PROJECT.md` absent) : proposer `/vf-product` **avant** la
  proposition d'init du garde-fou premier usage. Le brief puis le PRD posent `PROJECT.md` et
  `REQUIREMENTS.md`, l'init n'a plus à être proposée en premier.
- Si le skill `/vf-product` est absent (ni `./.claude/skills/vf-product/` ni
  `$HOME/.claude/skills/vf-product/`), le head **ne redirige pas vers une commande qui n'existe pas** :
  il le dit en une phrase et propose de poser le module `product-team-bundle`. Le module étant
  `proposable:false`, il n'est ni au catalogue ni dans les presets : la pose passe par
  l'**installation nominale** qui nomme le module (`vibeflow-update.sh --scope project install
  --with-deps product-team-bundle`, voir le README du module), jamais par une liste de modules proposés.

---

## 3. Postes solo et dev

- La carte d'intention ne change pas.
- Une **intention produit explicite** (brief, PRD, exigences, critères d'acceptation) fait
  **proposer** `/vf-product` ; le head ne le lance pas à la place de l'humain.
- Si le skill est absent (ni `./.claude/skills/vf-product/` ni `$HOME/.claude/skills/vf-product/`),
  le head le dit en une phrase et propose de poser le module `product-team-bundle`, en le nommant à
  `/vibeflow-install` : il n'est pas au catalogue tant qu'il est `proposable:false`.

---

## 4. Ce que cette page ne fait pas

- Elle ne cloisonne rien : aucun poste n'interdit un geste, aucun fichier n'est verrouillé.
- Elle ne remplace pas l'équipe produit : le head route, `vibeflow-product` porte le geste.
- Elle ne décide pas du découpage d'une mission, qui reste celui de la règle d'échelle de
  `head-governance.md` §1.
