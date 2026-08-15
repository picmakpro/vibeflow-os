# Vendor — Mermaid (hors ligne)

Ce dossier vendorise Mermaid pour que le cockpit fonctionne **hors ligne, sans CDN**.

**Emplacement** : `plugin/vf-cockpit/references/vendor/` — pas sous `assets/`. Le moteur
d'installation (`plugin/_internal/vibeflow-update.sh`) ne copie **aucun** dossier `assets/` dans
le lab de l'utilisateur ; seul `references/` est recopié tel quel (`cp -r` non filtré) vers
`.claude/skills/vf-cockpit/references/`. Un fichier posé sous `assets/` ne serait donc jamais
livré. Front (`exec-ui`) doit référencer ce vendor sous ce chemin installé.

## Fichier vendorisé

| Champ | Valeur |
|---|---|
| Version | **11.16.1** (dernière release stable de la branche 11.x au 2026-08-16) |
| Fichier | `mermaid.min.js` |
| URL source | `https://cdn.jsdelivr.net/npm/mermaid@11.16.1/dist/mermaid.min.js` |
| Date de vendorisation | 2026-08-16 |
| Taille | 3 566 058 octets (≈ 3.40 Mo) |
| SHA-256 | `18327bef70d96fb505fe7287d9f6a7362ebf07ff6576ddfaffb1a06f3e1a2954` |
| Licence | MIT (Knut Sveidqvist, 2014-2022) — recopiée dans `LICENSE` |

## Pourquoi ce fichier et pas le build ESM

Le build ESM de Mermaid v11 (`mermaid.esm.min.mjs`, dossier `dist/`) fait des imports relatifs
vers `./chunks/mermaid.esm.min/*.mjs`. Le vendoriser seul casse le chargement hors ligne : la
page tente de résoudre ces chemins relatifs au runtime et échoue silencieusement côté navigateur.

`mermaid.min.js` est le build **UMD/IIFE** : un seul fichier auto-suffisant, aucune résolution de
chemin, aucun build à reproduire. Vérifié empiriquement sur ce fichier avant de trancher :

- `grep -Fc './chunks' mermaid.min.js` → **0** occurrence.
- `grep -Fc 'import(' mermaid.min.js` → **0** occurrence (aucun `import()` dynamique).
- Le fichier se termine par :
  ```js
  globalThis["mermaid"] = globalThis.__esbuild_esm_mermaid_nm["mermaid"].default;
  ```
  → expose directement `window.mermaid` (= `globalThis.mermaid`), pas d'export ESM.

## Forme de chargement à employer côté front (contrainte pour `exec-ui`)

Charger ce fichier en `<script>` classique, **pas** en `import` ESM :

```html
<script src="./vendor/mermaid.min.js"></script>
<script>
  window.mermaid.initialize({ startOnLoad: false });
  // window.mermaid.render(...), window.mermaid.run(...), etc.
</script>
```

Aucun `type="module"` requis pour ce fichier, aucune résolution de chemin additionnelle,
aucun accès réseau au runtime.

## Procédure de re-vendorisation (version ultérieure)

1. Résoudre la version exacte souhaitée sur le registre npm (ne jamais épingler `@11` flottant) :
   ```bash
   node -e "fetch('https://registry.npmjs.org/mermaid').then(r=>r.json()).then(j=>console.log(Object.keys(j.versions).filter(v=>v.startsWith('11.'))))"
   ```
2. Télécharger le fichier UMD directement sur disque (jamais de pipe curl — corruption possible) :
   ```bash
   node -e "
   fetch('https://cdn.jsdelivr.net/npm/mermaid@<VERSION>/dist/mermaid.min.js').then(r=>{
     if(!r.ok) throw new Error('HTTP '+r.status);
     return r.arrayBuffer();
   }).then(buf=>{
     require('node:fs').writeFileSync('mermaid.min.js', Buffer.from(buf));
   });
   "
   ```
3. Revérifier empiriquement l'auto-suffisance (ne jamais supposer qu'elle tient d'une version à
   l'autre) :
   ```bash
   grep -Fc './chunks' mermaid.min.js   # doit rester 0
   grep -Fc 'import(' mermaid.min.js    # doit rester 0
   tail -c 300 mermaid.min.js           # doit exposer globalThis["mermaid"]
   ```
   Si un de ces contrôles échoue, la forme UMD a changé de stratégie de build : rouvrir l'arbitrage
   (a) bundle unique vs (b) ESM + arborescence complète des chunks, ne pas vendoriser en silence.
4. Recalculer taille et SHA-256, mettre à jour ce README (version, taille, hash, date).
5. Committer uniquement `plugin/vf-cockpit/assets/vendor/`.
