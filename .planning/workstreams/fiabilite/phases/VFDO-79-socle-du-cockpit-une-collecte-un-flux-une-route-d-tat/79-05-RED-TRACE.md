# 79-05 — trace des rouges et des mesures (SOCL-06 ; A10, A11, A27)

Aucun chemin du poste ni jeton : tout est symbolique. Base = `80d64b04` (export `git archive`, la suite neuve y est copiée puis jouée).

## Mesures de base (étape 0)

- `vf-cockpit-server.mjs` : 164 lignes, 6 comparaisons littérales de chemin `/api/vf/`, 18 lignes de plus de 160 colonnes ; `vf-cockpit-build.mjs` : 135 lignes, 19 lignes longues ; compteur de suites des README : 213 (réel : 213).
- Assemblage de deux copies d'un lab neutre (même nom de dossier, parents distincts) avec le code de la base : `graph.json` et données de la page Code égaux en JSON canonique (clés triées, chemin du lab remplacé par un jalon) une fois retirés les **champs volatils** : `meta.generatedAt`, `meta.scanAt` (et `builtAt`, `updatedAt` par prudence). Un troisième champ varie quand le lab est RÉGÉNÉRÉ au lieu d'être copié : `meta.repos[0].head` (sha de commit, fonction de l'heure) : la suite copie donc le lab (dépôt git compris) pour AN.4.
- Avant / après : `graph.json` (empreinte canonique `91432f6eee64a12e` avant et après), données de la page Code (`c0595595fae58fd8` avant et après) égaux ; page Projet égale à une seule valeur près, `meta.vf.drift.commande` (chemin du dossier de scripts qui lance l'assemblage : base exportée contre arbre de travail), donnée de lancement et non de graphe.
- Relevés des routes antérieures (statut, type, cache, clés de premier niveau, jamais une valeur), sur la base : `etat` 200 JSON `no-store` (clients, derniereMaj, mode, seq) ; `journal` 200 (`evenements`, tableau) ; `modeles` 200 (liste non vide, `defaut` texte, `lab` de 12 hexadécimaux) ; `doing` et `transcript` : sans identifiant et identifiant invalide 400 `{"erreur":"id-invalide"}`, identifiant valide inconnu 200 avec `schema` ; `events` 200 `text/event-stream`, premier événement `hello`. Ces relevés sont les assertions RC.1 à RC.6, vertes sur la base ET après.

## Rouges sur l'export de la base (suite finale : 17 PASS / 39 FAIL)

Joué par `bash <export de la base>/plugin/cockpit/scripts/tests/test-cockpit-routes.sh` (sortie 1). Identifiants rouges, dans l'ordre de la suite :
    R0.1 R0.2 B0.1 R1.1a R1.1b R1.1c R1.2 R1.3 R1.5a R1.5b R1.6 R1.7 B1.1 RK.1 RK.2 RK.3 RK.4 RK.5 RK.6 RK.7 RK.8 M-LITTERAL M-HISTORIQUE-NEUF M-ORDRE 
    M-TABLE AN.1 AN.5 AN.6 M-ANNOT-DEP AX.U AX.2 M-HOTE M-ORIGINE M-JETON M-METHODE M-GARDE M-NOSTORE M-503 F.1 

Raison par famille (attendu / obtenu sur la base) :
- R0.1, R0.2, B0.1 : `ok,ok,ok,ok,ok,ok` / `absent` (module absent) ; `ok,ok,ok` / `undefined` pour `ROUTES` et `repondreGardee` ; `ok,ok` / `undefined` pour `ANNOTATEURS`.
- R1.1a à R1.7, B1.1 : la route d'essai inscrite par l'option `routes` rend 404 (l'option est ignorée) ; B1.1 : `meta.vfEssai` absent (option `annotateurs` ignorée).
- RK.1 à RK.8, M-LITTERAL à M-TABLE : table absente, 6 comparaisons littérales ; les mutants ne produisent aucun effet mesurable sans table.
- AN.1, AN.5, AN.6, M-ANNOT-DEP : `undefined` (table absente), l'annotateur d'essai n'est pas exécuté, pas de code 4.
- AX.U, AX.2, M-HOTE à M-METHODE, M-GARDE à M-503 : module de routes absent.
- Verts par construction sur la base : R1.4 (route() rend 405 avant tout), R1.8 (route etat), B1.2 (schéma déjà posé), RC.1 à RC.6 et RC.3, RK.0, RK.9, AN.2, AN.4 (table vide : invariance triviale ; M-ANNOT-DEP est le témoin qui la fait rougir), AX.0 (comptes de l'oracle), AX.1 (portail), AX.3, H0.

## Verts (état final) et mutants

Suite finale sur l'arbre : 56 PASS / 0 FAIL. Chaque mutant est une copie de la sortie ; `cmp` ou la comparaison de contenu prouve l'effet, `node --check` la validité :
- Structure : M-LITTERAL (branche en ligne ajoutée) rougit RK.4 seul ; M-HISTORIQUE-NEUF (ligne neuve au régime HISTORIQUE) RK.5 seul, la liste de RK.1 étant étendue du chemin neuf pour isoler RK.5 ; M-ORDRE (deux lignes permutées) RK.2 seul ; M-TABLE (ligne `modeles` retirée) RK.1 et RC.3 (404).
- Accès (245 sondes, 7 hôtes x 5 origines x 7 jetons, 12 passantes, 233 refus, 64 refus isolés) : le portail et le vérificateur intérieur égalent l'oracle (0 désaccord) ; M-HOTE 16 désaccords (tous « passe au lieu de refus », hôtes étranger, autre-port, ipv6, suffixe, origine absente ou même, jeton code ou projet) ; M-ORIGINE 18 (origines étrangère, nulle, même hôte autre schéma) ; M-JETON 30 (faux-meme-longueur, court, long, absent, vide) ; M-METHODE : seul AX.U rougit (le POST valide rend ok), AX.2 et AX.3 restent verts.
- Réponse gardée : M-GARDE (constante `porteInterdit` toujours fausse) rougit R1.2 (statut 200, marqueur présent) et R1.7 (sans contrat, plus rien ne ferme) ; R1.1c reste vert ; M-NOSTORE rougit R1.1c et R1.5b seuls ; M-503 rougit R1.2 et R1.7 seuls.
- Annotateurs : AN.4 : identité, inverse et deux ordres tirés d'une graine imprimée (`graine=` en sortie, rejeu par `VF_ROUTES_GRAINE`) donnent le même hachage canonique ; couverture 4 ordres distincts, liste dégénérée dite « dégénéré ». M-ANNOT-DEP (la ligne `garde:annot-schema` conditionnée à `vfTab`) : l'ordre naturel reste égal à la référence, l'ordre inverse diffère par la seule valeur de `schema` (`floorplan/graph@1` au lieu de `vf-cockpit/graph@1`).

## Défaut trouvé en écrivant la suite (corrigé dans la suite, jamais dans le code testé)

AN.4 a d'abord rendu vert à vide : l'aide lisait les données de la page Code avec le lecteur de la SOURCE, qui ne reconnaît pas le gabarit de la sortie (marque blanche) ; l'exception faisait un hachage vide, identique pour tous les ordres. Corrigé : lecteur de la sortie, et l'assertion exige quatre hachages hexadécimaux non vides.

## Tailles (après)

`vf-cockpit-routes.mjs` 72 lignes (0 ligne longue), `vf-cockpit-server.mjs` 186 (17 lignes longues, baseline 18), `vf-cockpit-build.mjs` 184 (18 lignes longues, baseline 19).
