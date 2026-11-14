BASE=b24c0d2e43cc841dfad5feada51d541e6a540fff

# 76-08 — trace rouge : retrait du nœud « Exigences » (régime allégé)

rituel levé : baseline R76.4 de toutes les suites avant et après (rejouer-suites.sh avant/apres) : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Le lanceur et son jeu de cas (R76.4a à R76.4g, suites factices) sont livrés.
rituel levé : mutants M-PORTE-76, M-COUV-PANNEAU, M-RETRAIT, M-SUITE-OUBLIEE : régime allégé (même consigne).

## Base de comptage des assertions (HEAD de la base, avant la tâche)
assert_eq test-cockpit-projet-graphe.sh = 115 ; test-cockpit-questions.sh = 114

## R76.0 — inventaire des lecteurs (retrait-lecteurs.mjs --inventaire ; --temoins sort 0 ; jamais une porte)
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-activite-gardes.mjs:9:[couvre] //   4. un motif de chemin écrit dans une suite (jeton avec « * » visant plugin/) nomme tout fichier qu'il cou
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-ask.mjs:44:[.req] const line = (I, x, note) => `- [[${I.ref(x)}]]${/\.req$/.test(x.id || '') ? ` (${String(x.id).slice(3, -4).re
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-ask.mjs:85:[req/] const reqs = reqId ? G.files.filter((f) => f.p === 'req/' + reqId || (f.p.startsWith('req/') && f.p.endsWith('
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-ask.mjs:109:[.req] const exigPhaseFaite = (x) => { const g = I.N.get(x.id || x.n); return !!g && /\.req$/.test(g.id) && I.N.get(g
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-ask.mjs:129:[req/] const xs = (t ? I.under(t.id) : pool).filter((x) => x !== t && (x.st === 'todo' || x.st === 'active') && (x.id
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-ask.mjs:134:[.req] const xs = I.files.get(phase.id + '.req') || [];
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-ask.mjs:170:[.req] 'Cartes de la carte : jalons (n:ms-<clé>), phases (n:ph-<N>), groupe des exigences d\'une phase (n:ph-<N>.req)
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-ask.mjs:170:[req/] 'Cartes de la carte : jalons (n:ms-<clé>), phases (n:ph-<N>), groupe des exigences d\'une phase (n:ph-<N>.req)
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-code-cache.mjs:4:[couvre] // La signature couvre : le chemin, la taille et la date de CHAQUE entrée du lab hors `.git`, `.vibeflow` et `
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-equipe-carte.mjs:36:[couvre] kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Disp
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-equipe.mjs:19:[.req] const M = CC?.metaSousAgent || {}, T = CC?.transcriptSousAgent?.requis || ['isSidechain', 'agentId'];
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-equipe.mjs:22:[.req] if (ar && Object.keys(meta).length === ar.requis.length && ar.requis.every((k) => k in meta) && (ar.booleens |
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-equipe.mjs:23:[.req] if (!(M.requis || REQUIS_PAR_DEFAUT).every((k) => k in meta) || typeof meta.spawnDepth !== 'number') return nu
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-equipe.mjs:24:[.req] for (const [k, d] of Object.entries(M.requisSiProfondeur || {})) if (meta.spawnDepth >= d && typeof meta[k] !=
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-equipe.mjs:33:[.req] const seuil = CC?.metaSousAgent?.requisSiProfondeur?.parentAgentId ?? 2;
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-equipe.mjs:108:[.req] const w = { kind: 'subagent', id: c.id, parent, role: c.meta.agentType, task: c.meta.description || '', ...(c.
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-formats.mjs:81:[couvre] // quantificateurs jamais adjacents sur des classes qui se recouvrent : coût linéaire en la longueur de la lig
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-git-lanceur.mjs:28:[couvre] // l'environnement (GIT_CONFIG_COUNT), ce qui couvre aussi un enfant qui ne reçoit pas nos arguments (le moteu
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-git-signature.mjs:16:[couvre] const etats = new Map(); // lab -> { enVol, echecs, jusqu } : garde contre le recouvrement et retrait après un
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-graphe.mjs:25:[couvre] // garde:graphe-couvre
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-graphe.mjs:27:[couvre] export const signatureGraphe = (g) => crypto.createHash('sha256').update(JSON.stringify(sansVolatils(g))).dige
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-index-voie.mjs:27:[.req] export const formeRequise = (CC, objet, bloc) => (CC?.index?.[bloc]?.requis || []).every((p) => { const v = li
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-index.mjs:44:[.req] role, background: meta.requestShape === 'background', fini: meta.finished === true, arrete: f === 'arretee' &&
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-index.mjs:86:[.req] const memoHors = opts.memoHors || new Map(), seuil = CC?.metaSousAgent?.requisSiProfondeur?.parentAgentId ?? 2
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-lancer-mode.mjs:41:[couvre] try { // garde:mode-dossier : O_NOFOLLOW ne couvre que le dernier composant du fichier ; chaque dossier d'état
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-lancer-post.mjs:64:[.req] if (!Object.hasOwn(objet, nom)) { if (d.requis) return 'schema'; continue; }
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-planning.mjs:146:[.req] const vivantes = new Set([...reqs.values()].filter((r) => r.wsKey !== '*' && r.phase).map((r) => `${r.id}|${r.
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-planning.mjs:147:[.req] for (const [k, r] of [...reqs]) if (r.wsKey === '*' && r.phase && vivantes.has(`${r.id}|${r.phase}`)) reqs.del
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:91:[req/] const reqPath = (r) => `req/${r.ws ? r.ws + '/' : ''}${r.id}`;
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:92:[.req] const ownReqs = (ph) => [...reqs.values()].filter((r) => r.phase === ph.n && (r.wsKey === '*' || r.wsKey === (
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:151:[.req] for (const r of list(meta.requirements)) { const rq = reqOf(r, ph.ws); if (rq) link('f:' + p, 'f:' + reqPath(r
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:151:[couvre] for (const r of list(meta.requirements)) { const rq = reqOf(r, ph.ws); if (rq) link('f:' + p, 'f:' + reqPath(r
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:154:[.req] const rId = node({ id: `${id}.req`, parent: id, label: 'Exigences', kind: 'exigences', summary: `${phReqs.filt
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:154:[kind: 'exigences'] const rId = node({ id: `${id}.req`, parent: id, label: 'Exigences', kind: 'exigences', summary: `${phReqs.filt
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:216:[couvre] kindLabels: { import: 'Dépend de', event: 'Enchaînement', data: 'Couvre', queue: 'Étape suivante', call: 'Disp
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:219:[feuille:exigences] 'feuille:phase': 'Plan', 'feuille:exigences': 'Exigence', 'feuille:backlog': 'Entrée du backlog', 'feuille:gra
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:222:[liste:exigences] 'liste:phase': 'Plans', 'liste:exigences': 'Exigences', 'liste:backlog': 'Entrées', 'liste:graine': 'Graines',
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:223:[entrant:data] 'liste:mission': 'Étapes', 'entrant:import': 'Dépend de', 'sortant:import': 'Attendu par', 'entrant:data': 'Co
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:224:[sortant:data] 'sortant:data': '', // '' : liste non rendue, la couche VF dit la couverture
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-project.mjs:246:[.req] counts: { phases: phases.size, plans: files.filter((f) => f.p.endsWith('-PLAN.md')).length, reqs: reqs.size, r
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-signal-serveur.mjs:25:[.req] for (const [k, t] of Object.entries(spec.requis || {})) if (!(k in signal) || !(TYPES[t] || (() => false))(sig
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-signal-serveur.mjs:27:[.req] const cles = (nom) => (spec[nom] || {}).requis || [], tab = (x) => (Array.isArray(x) ? x : []);
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-signal-serveur.mjs:47:[.req] const spec = contrat.schemas['vibeflow/cockpit-signal@1'], noms = (n) => [...(spec[n].requis || []), ...(spec[
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-signal-serveur.mjs:49:[.req] const p = garder(sg, Object.keys(spec.requis));
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-trace.mjs:42:[couvre] // lstat (un lien n'est pas suivi), jamais un parcours du planning : le seq de l'instantané le couvre
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-vie.mjs:104:[couvre] // P68-D-33 : sans verrou de phase ni de compartiment, le verrou de dépôt couvre la mission (`acquire` sans --
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-who.mjs:32:[.req] const REQ_TR = CC.transcript?.requis || ['cwd', 'type', 'message', 'timestamp', 'sessionId'];
OCCURRENCE plugin/cockpit/scripts/vf-cockpit-who.mjs:220:[couvre] // le shell ne sépare les mots que sur espace, tabulation et retour à la ligne : `\r`, `\f`, `\v` restent DANS
OCCURRENCE plugin/cockpit/scripts/vf-cockpit.mjs:54:[couvre] // 79-06 (SOCL-08) : l'empreinte couvre tout le code évalué du MODULE ; le serveur est le serve.mjs du module,
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vf-surcouches.js:15:[couvre] // menus, visite et boîtes de dialogue que le moteur tient lui-même : ils couvrent la pile mais elle ne les fe
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js:192:[couvre] const couvre = D.commande ? `Il remet en forme ${pluriel(cv, 'écart', 'écarts')} sur ${N}${N - cv ? ` ; les ${
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js:196:[couvre] ${D.commande ? `<p class="pd" style="margin-top:var(--sp-12)">Correctif proposé, jamais appliqué d'ici. ${h(co
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js:198:[couvre] <p class="pd">Pour le lire avant de l'appliquer : la même commande, arrêtée avant le « | ».</p>` : couvre ? `<
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js:228:[.req] <div class="stats vf-stats" style="margin-top:var(--sp-12)"><div><b>${Number(c.phases) || 0}</b><span>phases</
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/01-vf-responsive.js:56:[couvre] (qui prend sa largeur, vf-cockpit-terminal-tiroir.mjs), elle-même au-dessus de la barre de question quand elle
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/01-vf-responsive.js:124:[couvre] // ne tienne plus sans recouvrir le titre (h1, description) ou la carte de la visite guidée (tiroir du termina
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/01-vf-responsive.js:125:[couvre] // Mesure : on le déplie, on lit son rectangle, on le replie s'il recouvre : tout dans la même tâche, sans ren
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/01-vf-responsive.js:134:[couvre] if (avant) window.dispatchEvent(new Event('vf-zoom-replie')); // I-2 : replié, le zoom n'avait plus de style e
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/02-vf-telephone.js:129:[couvre] // la feuille de visite se pose au-dessus de la barre de question OU plus haut (au-dessus de la pastille du te
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/25-recent.js:53:[.req] question: one ? (one.request ? t('You asked: {}', one.request) : '') : tasks.map((k) => k.title).join(' · '),
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/25-recent.js:71:[.req] ${k.request ? `<div class="rw-q"><b>${t('You asked:')}</b> ${h(k.request)}</div>` : ''}
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/25-recent.js:90:[.req] return `<div class="rw-note"><div class="rw-h">${head}</div>${h(it.note || '')}${k.request ? `<div class="rw-q
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/39-vf-tour-placement.js:2:[couvre] // La carte ne recouvre aucune surface fixe (zoom, pastille du terminal, panneau de détail, bloc titre, en-têt
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/39-vf-tour-placement.js:3:[couvre] // hauteur au-dessus d'un obstacle) est noté par l'aire qu'il recouvre, puis par le texte rogné, puis par son 
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/39-vf-tour-placement.js:62:[couvre] // Il ne sert QUE dans une fenêtre basse (revue finale, M-A) : aux tailles normales la place habituelle (en ba
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/39-vf-tour-placement.js:90:[couvre] // le coût : ce qu'elle recouvre d'abord (un pixel recouvert pèse plus que tout déplacement), puis son éloigne
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/39-vf-tour-placement.js:96:[couvre] // J1 : le texte rogné coûte, après le recouvrement et avant tout déplacement ; le titre entier et la première
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-phase.js:18:[.req] const exigences = (G.files || []).filter((f) => f.n === id + '.req').map((f) => ({ id: String(f.name), texte: 
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-phase.js:24:[couvre] for (const l of G.links || []) if (l.k === 'data' && l.label === 'couvre' && plans.has(l.a) && parCible.has(l.
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/41-vf-projet-vue.js:191:[couvre] if (d !== debutPose) { // le tiroir Git recouvre le bord gauche : une extrémité de début, la vue ne bouge pas
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/69-vf-flux.js:136:[.req] typeof navigator.locks.request === 'function' && typeof isSecureContext !== 'undefined' && isSecureContext ===
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/69-vf-flux.js:153:[.req] apresVerrou(navigator.locks.request(S.nom, { signal: S.ac.signal }, () => devenirElu()));
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/69-vf-flux.js:158:[.req] apresVerrou(navigator.locks.request(S.nom, { steal: true }, () => devenirElu())); // garde:flux-vol
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/69-vf-flux.js:166:[.req] apresVerrou(navigator.locks.request(S.nom, { ifAvailable: true }, (verrou) => {
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/ui/75-vf-modele.js:60:[couvre] // PU-G-087 : le tiroir Git (z-index 7) recouvre la carte de la visite (6) : la visite, toujours ouverte desso
OCCURRENCE plugin/cockpit/skills/cockpit-moteur/assets/viewer.html:2022:[.req] ta.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' && !ev.shiftKey) { ev.preventDefault(); form.r
TROUVEES=76

classe nommée des lecteurs génériques par genre de lien (se vident au retrait, prouvé par R76.3 et les suites) : viewer.html KIND_PLAIN[l.k], vf-cockpit-query.mjs kindLabels?.[l.k], voisins de toutes les arêtes (80-12).

## Captures d'avant le retrait (lab de référence : retrait-lecteurs.mjs --lab-reference)
sha256 76-08-PORTE-AVANT.json (normalisée) = 2d315587389cd22b019bd68e41b539360357c57b70247f1959dc86583ec2dd7b
sha256 sortie --porte-brut d'avant = 3f6e86223d06b2688725940384670f201207843eb5541e655e46d52c97eacd2a
cibles brutes d'avant (--porte-brut) : f:req/deux/DEUX-01 f:req/un/UN-01 f:req/un/UN-02 f:req/*/OLD-09 f:req/un/UN-03
76-08-COUVERTE-AVANT.txt : 9 lignes ; C8.0 et C8.1 verts AVANT le retrait (le remplaçant, le panneau d'exigence de la 76, existe d'abord)

## Rouge de test-cockpit-projet-graphe.sh sur la base (avant le code)
  ❌ FAIL — R76.1 — graphe du lab g1 : aucun nœud « exigences », aucun identifiant en .req, aucune carte req/, aucun lien « couvre » ; le pied de ph-1 dit « exigences » ; témoin : AUTH-01 est dans meta.vf.trace.exigences (phase 1)
     attendu: [0|0|0|0|true|true]
     obtenu:  [1|1|1|0|true|true]
  ❌ FAIL — R76.2b — la cible brute d'une exigence lue par la porte est null (la 76 n'a pas d'élément d'exigence) : lab g1 (AUTH-01)
     attendu: [ok]
     obtenu:  [cible-non-nulle: f:req/AUTH-01]
  ❌ FAIL — R76.2b' — idem sur le lab de référence, couverture comprise (au moins une exigence lue : témoin positif)
     attendu: [ok]
     obtenu:  [cible-non-nulle: f:req/deux/DEUX-01]
  Résultats : 127 PASS / 3 FAIL
==================================

## Rouge de test-cockpit-questions.sh sur la base (avant le code)
  ❌ FAIL — Q76.1 — « REQ-01 ? » : réponse locale qui nomme REQ-01, sa case (« non cochée ») et la carte de sa phase [[n:ph-1]] ; chaque items[].id existe dans le graphe
     attendu: [local,true,true,true,true]
     obtenu:  [false]
  Résultats : 133 PASS / 1 FAIL
==================================
