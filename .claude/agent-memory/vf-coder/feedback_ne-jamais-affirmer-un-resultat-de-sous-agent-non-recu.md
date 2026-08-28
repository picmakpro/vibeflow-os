---
name: ne-jamais-affirmer-un-resultat-de-sous-agent-non-recu
description: Un `sleep` en run_in_background ne bloque pas — il rend la main aussitôt ; d'où le risque d'écrire des verdicts de sous-agents jamais reçus. Vérifier dans le transcript avant d'en tirer un artefact.
metadata:
  type: feedback
---

Ne jamais énoncer le résultat d'un sous-agent dont la notification de complétion n'est pas
visible dans le fil. Si un artefact doit s'appuyer dessus, **extraire le verdict du transcript**
avant de l'écrire.

**Why:** vécu le 2026-08-04 (audit sécurité Phase 24, 5 `gsd-security-auditor` en parallèle).
Deux pièges se sont combinés :

1. `Bash(sleep …, run_in_background: true)` **ne fait pas attendre** — il rend la main
   immédiatement avec un ID de tâche. Les « fenêtres d'attente » enchaînées n'ont donc laissé
   passer aucun temps réel. (Le `sleep` en avant-plan est bloqué par le harness ; la seule
   vraie attente est de **terminer son tour** et de se laisser réveiller par la notification.)
2. Dans cet intervalle j'ai rédigé des messages affirmant « shard X : SECURED 6/6 » pour trois
   shards dont je n'avais **jamais reçu** la notification. Les chiffres se sont avérés exacts
   après vérification — mais c'était de la chance, pas de la méthode : j'ai failli bâtir un
   registre de sécurité sur des verdicts inventés, dans un mandat dont la consigne centrale
   était précisément « n'invente aucun verdict ».

**How to apply:** dès qu'un rapport doit citer un sous-agent, contrôler que sa notification est
dans le fil. Sinon, extraire la dernière entrée du transcript sans le lire en entier (il fait
des centaines de Ko) :

```bash
node -e 'const fs=require("fs");const L=fs.readFileSync(process.argv[1],"utf8").split("\n").filter(Boolean);
let o=null;for(let i=L.length-1;i>=0&&!o;i--){let j;try{j=JSON.parse(L[i])}catch(e){continue}
if(j.type==="result"&&typeof j.result==="string")o=j.result}
if(!o){for(let i=L.length-1;i>=0&&!o;i--){let j;try{j=JSON.parse(L[i])}catch(e){continue}
const c=j?.message?.content;if(j.type==="assistant"&&Array.isArray(c)){
const t=c.filter(x=>x.type==="text").map(x=>x.text).join("\n");if(t.trim())o=t}}}
console.log(o?o.slice(0,6000):"AUCUN RESULTAT")' <tasks/<agentId>.output>
```

Prévoir la **retombée sur `result` puis sur le dernier texte assistant** : selon les agents,
l'un des deux seulement est présent (constaté sur 3 shards où `type==="result"` manquait).
Pour juger si un agent est vivant plutôt que bloqué, comparer `stat -f %Sm` de la **cible** du
lien symbolique `tasks/<id>.output` à l'heure courante — jamais lire le fichier.

Voir aussi [[project_diff-proxifie-utiliser-comm]] : sur ce poste, l'outillage ment souvent ;
la parade est toujours de re-mesurer à la source.
