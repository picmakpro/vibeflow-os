# 26-04 — SUMMARY (vague 4 : thème `03-modules`)

**Statut** : livré, gate au vert, aucun commit (D-14 respecté).

## Ce qui a été produit

12 fichiers de pages (6 pages × 2 langues) sous `manual/{fr,en}/03-modules/` :

| Page | FR | EN |
|---|---:|---:|
| `catalogue.md` | 105 | 100 |
| `socle-et-dependances.md` | 100 | 100 |
| `choisir-ses-modules.md` | 101 | 100 |
| `bundles-metier.md` | 103 | 102 |
| `activer-desactiver.md` | 102 | 100 |
| `ou-vit-un-module.md` | 100 | 100 |

Plus : `manual/toc.yml` (thème `03-modules` ouvert dans `themes:`, 6 entrées `pages:`), et le
parcours guidé « je compose mon lab » / « I'm composing my lab » ajouté aux deux README de langue.

Total du manuel après cette vague : **20 pages × 2 langues**, 3 thèmes ouverts.

## Dérivation depuis le disque (D-11) — commande exacte

La liste des modules, leurs types, leur statut `mandatory`, leurs `requires` et leurs descriptions
ont été produits par cette commande, jamais par lecture du README :

```bash
python3 - <<'EOF'
import json,glob,os
os.chdir(os.popen('git rev-parse --show-toplevel').read().strip())
for f in sorted(glob.glob('plugin/*/module.json')):
    d=json.load(open(f)); mod=os.path.dirname(f)
    ag=sorted(os.path.basename(p) for p in glob.glob(mod+'/agents/*.md') if not p.endswith('.bak'))
    sk=sorted(os.path.basename(os.path.dirname(p)) for p in glob.glob(mod+'/**/SKILL.md',recursive=True) if '/templates/' not in p)
    print(f"{d['name']}: type={d.get('type')} mandatory={d.get('mandatory',False)} "
          f"proposable={d.get('proposable')} requires={d.get('requires',[])} "
          f"AGENT.md={os.path.exists(mod+'/AGENT.md')} agents={ag} skills={sk}")
EOF
```

**17 `module.json` lus** — c'est le compte réel de modules sur le disque, et les 17 noms
apparaissent dans `catalogue.md` dans les deux langues. Le socle a été établi de la même façon :
un seul `mandatory: true` (`conductor`), chaîne `requires` conductor → {planning-core, validator,
skill-creator} et validator → {consolidator, infrastructure-audit, audit-architecture}, soit 7
modules en fermeture transitive.

## Écarts disque ↔ README du dépôt (constat, non corrigé — hors périmètre)

- `plugin/installer/` porte un `SKILL.md` (`vibeflow-install`) mais **pas** de `module.json` : ce
  n'est pas un module au sens du catalogue. Le compte de 17 exclut donc l'installeur et
  `_internal/`, ce qui est cohérent avec le filtre de `build-module-catalog.sh`.
- Le nombre de `SKILL.md` réellement livrés est **20** hors gabarits (24 au total, dont 4 sous
  `plugin/reference/content/methodology/templates/skills/`). Le README n'en liste qu'une fraction.
- Deux modules déclarent leur statut expérimental dans leur propre `module.json` (`mobile-test`,
  `mobile-test-team`). Le manuel les signale comme tels ; le README ne fait pas cette distinction.
- Les versions du README restent périmées pour la majorité des modules. **Rien n'a été corrigé** :
  `README.md` est interdit en écriture sur ce mandat. Le manuel contourne le problème par
  construction — `ou-vit-un-module.md` renvoie au `module.json` et au `CHANGELOG.md`.

## Vérification

- `bash manual/.tools/check-manual.sh` → **exit 0**, C0 à C6 tous ✓. Aucun avertissement de
  fourchette résiduel : les 12 pages sont dans 100-200 lignes.
- C5 (zéro version en dur) passe : aucune page du thème ne cite de numéro de version.
- `git status --porcelain -- manual` : **vide de bout en bout**, vérifié en sortie brute
  (`rtk proxy`) et confirmé par `git ls-files -- manual` vide et
  `git check-ignore -v manual/toc.yml` → `.git/info/exclude:7`.
- `git status --porcelain -- plugin README.md README.fr.md INSTALL.md scripts .github` : vide.
