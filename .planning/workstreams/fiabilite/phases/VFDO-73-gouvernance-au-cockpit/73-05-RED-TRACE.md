base: f8c91b29ab1a0c296674201e3f8cb66e7a5fb498

# 73-05 — trace du rouge (tâche 1, premier temps)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG0_ordre_page RG1_page RG2_page RG9_page RG11_page RG14_page RG15_page RG16_page`
Résultat sur la base : `0 PASS / 45 FAIL`, sortie 1, chaque témoin nommé au plan imprime `❌ FAIL — <id> —`.

Motif commun : les trois fichiers `ui/72-vf-regie-pied.js`, `-rendu.js` et `-source.js` n'existent pas (le harnais vm s'arrête sur le premier absent) ;
la ligne d'arrivée de `00-vibeflow.js` ne délègue pas à `__vfRegie` ; la sortie assemblée ne porte que le repère du modèle.

| id | attendu | obtenu |
|----|---------|--------|
| RG0.11 | `index.html=ok project.html=ok` | repères rendu et source absents de la sortie assemblée (`faux:`) |
| RG1.10 | `1\|1\|1\|true,true,true,true\|true\|true` | `ERR:fichier absent : 72-vf-regie-pied.js` |
| RG1.11, RG1.12 (hash au retour de `vf:onglet`) | focus sur le titre de section, une fois | `ERR:fichier absent : 72-vf-regie-pied.js` |
| RG2.1 | sous-arbres `section#vf-equipe` identiques par `VF_ETAT` et par `vf-who` | `egal|vide|sans-mission` (deux erreurs identiques, source absente : le garde « non vide » rougit) |
| RG9.20, RG9.21 | mise à jour en place, focus conservé, durées qui avancent, zéro écriture à texte identique | `ERR:fichier absent …` |
| RG11.10 | `vf-agent:ouvrir:rapport:true,vf-agent:lu::false\|1\|/api/vf/transcript?id=…\|true\|true` | `ERR:fichier absent …` |
| RG14.10 | classe `btn` seule, nom une fois, jamais `disabled` | `ERR:fichier absent …` |
| RG15.1, RG15.2, RG15.3, RG15.5, RG15.6, RG15.7, RG15.8, RG15.9, RG15.10, RG16.1 | voir le fragment | `ERR:fichier absent …` |
| RG15.4 (ligne d'arrivée) | `1\|ok` (une ligne de `00-vibeflow.js` nomme `TAB === 'equipe'` et `__vfRegie`) | `0\|ok` |
| RG15.10 (marqueur) | `0 0 0` | `absent absent absent` |

Écarts de lecture du plan, consignés pour la suite : RG1.12 porte deux témoins du même identifiant (hash au retour de `vf:onglet`, ici ; états de page, tâche 3, à écrire au second temps) ;
les ancres de RG15.4 visent `n:se-<id>` (seules les sessions entrent dans « À vous », le modèle ne met jamais un sous-agent dans cette section).

Formes simulées par le harnais, à aligner sur le code livré au second temps : `VF_ETAT` (79-17 : `lire('who'|'etat'|'connexion')`, `abonner`, `jeton`, `lireJson`) et `VF_COQUILLE.surOnglet(rappel, { cle })`, `VF_SURCOUCHES` (80-02).
