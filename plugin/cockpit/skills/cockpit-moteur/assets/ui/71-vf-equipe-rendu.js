// VibeFlow (69-08) : rendus purs de l'équipe (P69-D-14 à D-16, D-18, D-19, D-23). Aucune dépendance au viewer ni au DOM au chargement : l'arbre et les
// liens sont des chaînes dont toute valeur interpolée passe par h() (passé en paramètre), le transcript est un fragment bâti par createElement et
// textContent seulement (jamais d'HTML interprété). Pose window.__vfEquipeRendu, utilisé par 70-vf-live.js (tiroir, onglet Projet) et 72-vf-equipe.js.
(() => {
  const ETAT = { actif: 'actif', 'en-attente': 'en attente', 'au-repos': 'au repos', attend: 'vous attend', termine: 'terminé', bloque: 'bloqué' };
  const etat = (w) => ETAT[w.etat] || 'actif';
  const dedans = (w) => w && (w.kind === 'session' || w.kind === 'subagent') && typeof w.id === 'string';
  // un agent « actif » : session ou sous-agent ni terminé ni en attente (effectifs de l'onglet Équipe et badge de l'en-tête)
  const actif = (w) => !!dedans(w) && w.etat !== 'termine' && w.etat !== 'en-attente' && w.etat !== 'au-repos' && w.etat !== 'attend';
  const lien = (page, ref) => `${page}#r=${encodeURIComponent(ref)}`;
  const carte = (w) => (w.kind === 'session' ? 'n:se-' : 'n:ag-') + w.id;
  const noeud = (w) => (w.rattachement && w.rattachement.etat === 'rattache' ? `f:${w.rattachement.dag}#${w.rattachement.noeud}` : null);

  // AUDC-D3 : l'âge d'un agent non terminé avance entre deux poussées du `who` : on ajoute le temps écoulé depuis la réception (posée par 70-vf-live.js, `whoAt`) ; un terminé ne vieillit pas
  const ecoule = () => { const t = window.__vfLive && window.__vfLive.whoAt; return typeof t === 'number' ? Math.max(0, Math.round((Date.now() - t) / 1000)) : 0; };
  const vif = (w, v) => (typeof v === 'number' && w.etat !== 'termine' ? v + ecoule() : v);
  const ageDe = (w) => vif(w, w.ageS), tenueDe = (w) => vif(w, w.dureeS);
  // même format que l'ancien age() du tiroir : secondes, minutes, heures, jours
  const duree = (s) => (s == null ? '' : s < 90 ? `${s} s` : s < 5400 ? `${Math.round(s / 60)} min` : s < 172800 ? `${Math.round(s / 3600)} h` : `${Math.round(s / 86400)} j`);

  // PU-G-173 : la durée dit de quoi elle parle — ancienneté de la dernière écriture (« dernière activité il y a … »), tenue d'un agent (« au travail depuis … », « a duré … »)
  const quand = (w) => {
    const dur = w.kind === 'subagent' && w.etat !== 'en-attente' && w.dureeS != null ? tenueDe(w) : null;
    if (dur != null) return `${w.etat === 'termine' ? 'a duré' : 'au travail depuis'} ${duree(dur)}`;
    return w.ageS == null ? '' : `dernière activité il y a ${duree(ageDe(w))}`;
  };
  const action = (w) => { const a = w.action || {}; return [a.verbe, a.cible].filter((x) => typeof x === 'string' && x).join(' '); };
  const pied = (w) => [etat(w), quand(w), action(w)].filter(Boolean).join(' · ');
  // pied d'une CARTE (PU-G-165) : la pastille dit déjà « En cours », « Fait » ou « Bloqué » ; seul « en attente », sans pastille, garde son mot ; l'action générique est tue
  const piedCarte = (w) => [w.etat === 'en-attente' || w.etat === 'au-repos' || w.etat === 'attend' ? etat(w) : '', quand(w), (w.action || {}).verbe === GENERIQUE ? '' : action(w)].filter(Boolean).join(' · ');
  const st = (w) => (w.etat === 'termine' ? 'done' : w.etat === 'bloque' ? 'blocked' : w.etat === 'en-attente' || w.etat === 'au-repos' || w.etat === 'attend' ? undefined : 'active'); // même table que vf-cockpit-equipe-carte.mjs

  // PU-G-167 : « inconnu » et « sans-citation » ne disent rien à l'utilisateur ; toute autre raison (ambigu, valeur inattendue) reste affichée, échappée
  const raisonDe = (w) => (w.rattachement && w.rattachement.raison) || 'inconnu';
  const CLAIR = new Set(['inconnu', 'sans-citation']);
  // lien vers le nœud de mission : seulement un rattachement établi ; sinon « non rattaché » et sa raison, jamais un lien deviné
  const versNoeud = (w, h) => {
    const n = noeud(w);
    return n ? `<a class="vf-link" href="${h(lien('project.html', n))}">Nœud ${h(w.rattachement.noeud)}</a>`
      : w.kind === 'subagent' ? `<span class="vf-nr">${CLAIR.has(raisonDe(w)) ? 'pas lié à une phase du projet' : `non rattaché (${h(raisonDe(w))})`}</span>` : '';
  };

  // ---------- tiroir « Au travail » (P71.5-D-14, D-23, D-24) : une ligne par agent, des fils entre les points, les terminés regroupés en bas ----------
  // glyphes d'état en SVG en ligne (forme différente par état : la couleur ne porte jamais l'état seule) ; tracés sur une grille de 16
  const NB = ' ';
  const GLYPHE = {
    actif: '<circle cx="8" cy="8" r="4" fill="currentColor" stroke="none"/>',
    attente: '<circle cx="8" cy="8" r="5.5"/><path d="M6.6 5.8v4.4M9.4 5.8v4.4"/>',
    termine: '<path d="M3.5 8.4l3 3 6-6.4"/>',
    bloque: '<path d="M8 2.5l6 10.5H2z"/><path d="M8 6.6v3M8 11.4v.1"/>',
    orphelin: '<circle cx="8" cy="8" r="5.5" stroke-dasharray="2 2.4"/>',
    repos: '<circle cx="8" cy="8" r="5.5"/><path d="M5.8 8h4.4"/>', // « au repos » : un tiret dans un anneau (AUDC-D2)
    attend: '<circle cx="8" cy="8" r="5.5"/><path d="M6.4 6.4a1.7 1.7 0 1 1 2.4 1.5c-.5.3-.8.6-.8 1.2M8 11.3v.1"/>', // « vous attend » : un point d'interrogation dans un anneau
    repli: '<path d="M6 4l4 4-4 4"/>',
    surveiller: '<circle cx="8" cy="8" r="5.5"/><path d="M8 5v3.4l2.2 1.3"/>', // un cadran : « du temps passe » (PU-G-181, PU-G-183) ; la forme porte le sens, jamais une couleur d'alerte (Q9, Règle actuelle)
    commande: '<path d="M1.5 8s2.3-4.5 6.5-4.5S14.5 8 14.5 8s-2.3 4.5-6.5 4.5S1.5 8 1.5 8z"/><circle cx="8" cy="8" r="1.8"/>', // un œil : « voir », jamais l'invite d'un terminal (PU-G-187)
  };
  const glyphe = (nom, cls) => `<svg class="aw-g${cls ? ' ' + cls : ''}" viewBox="0 0 16 16" aria-hidden="true" focusable="false">${GLYPHE[nom]}</svg>`;
  const GLYPHE_ETAT = { actif: 'actif', 'en-attente': 'attente', 'au-repos': 'repos', attend: 'attend', termine: 'termine', bloque: 'bloque' };
  const MOT = { actif: 'actif', 'en-attente': 'en attente', 'au-repos': 'au repos', attend: 'vous attend', termine: 'terminé', bloque: 'bloqué' };
  const CALME_S = 120; // un agent actif sans écriture depuis 2 min est dit « sans nouvelle depuis … » (seuil dérivé, P71.5-D-14)
  const GENERIQUE = 'lance une commande'; // l'action de presque tous : elle n'informe pas, on ne la montre pas
  const LONGUE_S = 900; // PU-G-183 : une commande en cours sans écriture depuis 15 min (une commande qui tourne n'écrit rien dans le transcript : l'âge de la dernière écriture est sa durée)
  const tpath = (t) => String(t || '').replace(/^\.claude\/worktrees\//, '');
  const court = (w) => String(w.branch || tpath(w.tree));
  const calme = (w) => w.etat === 'actif' && typeof w.ageS === 'number' && ageDe(w) >= CALME_S;
  const longue = (w) => calme(w) && ageDe(w) >= LONGUE_S && (w.action || {}).verbe === GENERIQUE;
  const verbe = (w) => { const a = w.action || {}; if (!a.verbe || a.verbe === GENERIQUE) return ''; return [a.verbe, a.cible].filter((x) => typeof x === 'string' && x).join(' '); };
  // PU-G-186 : le titre d'une session passe par ce seul point : le nom donné avec /rename (`titre`, le `custom-title` du transcript) quand la collecte le porte, sinon « Session principale » ; plusieurs sessions de même titre se distinguent par leur arbre, puis par leur identifiant court
  const titreDe = (w) => (w && typeof w.titre === 'string' && w.titre.trim()) || 'Session principale';
  const lieu = (w) => (tpath(w.tree) === 'arbre principal' || tpath(w.tree) === '.' ? 'main' : tpath(w.tree) || court(w));
  const nommer = (workers) => {
    const ss = (Array.isArray(workers) ? workers : []).filter((w) => w && w.kind === 'session' && typeof w.id === 'string'), noms = new Map();
    for (const s of ss) { const g = ss.filter((x) => titreDe(x) === titreDe(s)); noms.set(s.id, g.length < 2 ? titreDe(s) : `${titreDe(s)} · ${lieu(s)}${g.filter((x) => lieu(x) === lieu(s)).length > 1 ? ' · ' + s.id.slice(0, 8) : ''}`); }
    return noms;
  };
  let noms = new Map();
  const SILENCE_PARENT_S = 1800; // PU-G-182 : une session parente en attente ou muette depuis plus de 30 min (le TTL de driver-lock.sh)
  const aVivant = (w, enfants) => w.etat !== 'termine' || (enfants.get(w.id) || []).some((k) => aVivant(k, enfants));

  // la durée dit de quoi elle parle : tenue d'un sous-agent en cours, ancienneté de la dernière écriture d'une session, durée d'un terminé
  const temps = (w, h) => {
    const dur = h(duree(w.dureeS != null ? tenueDe(w) : ageDe(w)));
    if (w.kind === 'session') return `<span class="r-t ecrit"><i>écrit il y a${NB}</i>${h(duree(ageDe(w)))}</span>`;
    return `<span class="r-t"><i>${w.etat === 'termine' ? 'a duré' : 'depuis'}${NB}</i>${dur}</span>`;
  };

  const ligne = (w, parent, enfants, tous, h) => {
    const sess = w.kind === 'session', fini = w.etat === 'termine', ks = (tous.get(w.id) || []).filter((k) => aVivant(k, tous)).sort((a, b) => (b.dureeS || 0) - (a.dureeS || 0));
    // PU-G-182 : « orphelin ? » (le registre dit « jamais fermé », pas « processus mort ») ; un enfant actif dont la session parente se tait depuis plus de 30 min l'est aussi
    const orphe = !!w.orphan || (w.kind === 'subagent' && w.etat === 'actif' && !!parent && parent.kind === 'session' && parent.etat !== 'termine' && parent.ageS > SILENCE_PARENT_S);
    const nom = orphe ? 'orphelin' : GLYPHE_ETAT[w.etat] || 'actif';
    const tache = sess ? noms.get(w.id) || titreDe(w) : w.task || (fini ? `${w.role || 'Agent'} · ${String(w.id).slice(0, 8)}` : ''); // PU-G-184 : un agent terminé sans titre se nomme par son rôle et son identifiant court
    const raison = w.rattachement && w.rattachement.raison;
    const hors = w.kind === 'subagent' && !noeud(w) && !fini;
    const sr = ` <span class="sr">(${MOT[w.etat] || 'actif'}${orphe ? ', orphelin ?' : ''}${w.stale ? ', donnée ancienne' : ''}${hors ? ', non rattaché : ' + h(raison || 'inconnu') : ''})</span>`;
    // branche et arbre : une fois sur la session, puis en puce seulement quand ils diffèrent du parent (frontière Phase 78)
    const puce = !sess && (!parent || court(parent) !== court(w)) ? `<span class="r-chip" title="${h(court(w))}">${h(lieu(w))}</span>` : '';
    const marques = (orphe ? '<span class="r-flag">orphelin ?</span>' : '') + (w.stale ? '<span class="r-flag">donnée ancienne</span>' : '') + (hors && raison === 'ambigu' ? '<span class="r-flag">non rattaché (ambigu)</span>' : '');
    const v = verbe(w);
    const meta = sess ? `${h(tpath(w.tree))}${w.branch ? ' · ' + h(w.branch) : ''}${marques}`
      : `<b>${h(w.role || 'Agent')}</b>${calme(w) ? (longue(w) ? ' · commande en cours, sans nouvelle depuis ' : w.enCours ? ' · outil en cours, sans nouvelle depuis ' : ' · sans nouvelle depuis ') + h(duree(ageDe(w))) : ''}${w.etat === 'en-attente' ? ' · en attente' : w.etat === 'bloque' ? ' · bloqué' : ''}${!calme(w) && v ? ' · ' + h(v) : ''}${puce}${marques}`;
    const corps = `<span class="r-top"><span class="r-task">${h(tache)}${sr}</span>${temps(w, h)}</span>${fini ? '' : `<span class="r-meta">${meta}</span>`}`;
    const rang = `<a class="r-row" href="${h(lien('equipe.html', carte(w)))}" title="${h(tache)} — voir dans l'onglet Équipe">${glyphe(nom, (w.etat === 'actif' && !orphe ? 'aw-pulse ' : '') + 'aw-s-' + nom)}<span class="r-main">${corps}</span></a>`;
    const repli = ks.length ? `<button type="button" class="r-tog" data-vf-repli="${h(w.id)}" aria-expanded="true" aria-controls="k-${h(w.id)}" aria-label="Sous-agents de ${h(w.role || 'la session')}, ${ks.length}">${glyphe('repli', 'r-caret')}</button>` : '';
    const doing = !fini ? `<button type="button" class="r-doing" data-vf-doing="${h(w.id)}" aria-label="Voir la dernière commande de ${h(tache)}" title="Voir la dernière commande">${glyphe('commande')}</button><div class="vf-doing" hidden></div>` : '';
    const n = noeud(w);
    const vers = n ? `<a class="vf-link r-noeud" href="${h(lien('project.html', n))}">Nœud ${h(w.rattachement.noeud)}</a>` : '';
    const cls = `r-ag${ks.length ? ' has-kids' : ''}${sess ? ' r-sess' : ''}${calme(w) ? ' r-calme' : ''}${w.stale ? ' r-stale' : ''}${w.etat === 'bloque' ? ' r-bloque' : ''}${fini ? ' r-fini' : ''}`;
    return `<li class="${cls}" data-vf-agent="${h(w.id)}"><div class="r-line">${rang}${repli}${doing}${vers}</div>`
      + (ks.length ? `<ul class="r-kids" id="k-${h(w.id)}">${ks.map((k) => ligne(k, w, enfants, tous, h)).join('')}</ul>` : '') + '</li>';
  };

  // PU-G-181 : « À surveiller », en tête du tiroir : les sous-agents actifs sans nouvelle depuis CALME_S, et ceux dont la commande dure depuis LONGUE_S (PU-G-183) ; un glyphe et des mots en texte neutre (Q9) ; rien à surveiller, pas de ligne
  const surveiller = (workers) => {
    const ss = (Array.isArray(workers) ? workers : []).filter((w) => w && w.kind === 'subagent' && calme(w)), lg = ss.filter(longue).length, mu = ss.length - lg;
    const dit = [mu ? `${mu} ${mu > 1 ? 'agents' : 'agent'} sans nouvelle depuis plus de ${CALME_S / 60}${NB}min` : '', lg ? `${lg} ${lg > 1 ? 'commandes' : 'commande'} en cours depuis plus de ${LONGUE_S / 60}${NB}min` : ''].filter(Boolean);
    return dit.length ? `<p class="aw-surv">${glyphe('surveiller', 'aw-s-attente')}<span><b>À surveiller</b> · ${dit.join(' · ')}</span></p>` : '';
  };

  // AUDC-M3 : le titre de la vue Équipe dit le vrai : la mission quand il y en a, sinon le nombre d'agents actifs, « Aucune mission en cours » seulement quand personne ne travaille (PU-G-166 : le titre compte les missions)
  const titreEquipe = (M, c) => {
    const m = Array.isArray(M) ? M : [], a = c && typeof c.actif === 'number' ? c.actif : 0;
    return m.length === 1 ? `Mission : ${m[0]}` : m.length > 1 ? `${m.length} missions en cours` : a > 0 ? `${a} ${a > 1 ? 'agents actifs' : 'agent actif'}` : 'Aucune mission en cours';
  };
  const ligneAgents = (c) => `Agents : ${c.actif} ${c.actif > 1 ? 'actifs' : 'actif'} · ${c.enAttente || 0} en attente${c.attend ? ` · ${c.attend} vous attend${c.attend > 1 ? 'ent' : ''}` : ''}${c.auRepos ? ` · ${c.auRepos} au repos` : ''} · ${c.termine || 0} ${c.termine > 1 ? 'terminés' : 'terminé'} depuis moins de 24 h.`;
  const arbre = (workers, h) => {
    noms = nommer(workers);
    const tous = (Array.isArray(workers) ? workers : []).filter(dedans);
    const connus = new Map(tous.map((w) => [w.id, w]));
    const racines = [], enfants = new Map();
    for (const w of tous) {
      const p = w.kind === 'subagent' && w.parent !== w.id && connus.has(w.parent) ? w.parent : null;
      if (p === null) racines.push(w); else enfants.set(p, [...(enfants.get(p) || []), w]);
    }
    const vivants = racines.filter((w) => aVivant(w, enfants));
    // les terminés qui ne portent aucun agent en cours : un seul bloc, les plus récents d'abord, les 5 premiers ; le reste est dans l'onglet Équipe
    const hors = tous.filter((w) => w.etat === 'termine' && !aVivant(w, enfants)).sort((a, b) => (a.ageS || 0) - (b.ageS || 0));
    const montres = hors.slice(0, 5), autres = hors.length - montres.length;
    return (vivants.length ? `<ul class="r-tree">${vivants.map((r) => ligne(r, null, enfants, enfants, h)).join('')}</ul>` : '')
      + (hors.length ? `<details class="vf-termines"><summary class="aw-sec"><span>Terminés depuis moins de 24 h (${hors.length})</span>${glyphe('repli', 'r-caret')}</summary><ul class="r-tree r-tl">${montres.map((w) => ligne(w, null, enfants, enfants, h)).join('')}</ul>`
        + (autres > 0 ? `<a class="r-more" href="equipe.html">${autres > 1 ? `Les ${autres} autres` : 'Un autre'} dans l'onglet Équipe</a>` : '') + '</details>' : '');
  };

  const agentsDuNoeud = (workers, ref, h) => {
    const ls = (Array.isArray(workers) ? workers : []).filter((w) => w && w.kind === 'subagent' && typeof w.id === 'string' && noeud(w) === ref);
    if (!ls.length) return '';
    return ls.map((w) => `<a class="vf-link" href="${h(lien('equipe.html', carte(w)))}"><span>${h(w.role || 'Agent')}</span><span>${h(w.task || '')}</span></a>`).join('');
  };

  // transcript : texte seulement, aucune balise hors div, h4, p, ul, li, pre, span
  const transcript = (d, doc) => {
    const f = doc.createDocumentFragment();
    const el = (tag, texte) => { const e = doc.createElement(tag); if (texte != null) e.textContent = String(texte); return e; };
    const dit = (texte) => { f.appendChild(el('p', texte)); };
    if (!d || d.erreur) { dit(d && d.erreur === 'inconnu' ? 'Plus dans la fenêtre de 24 h : rien à montrer.' : 'Indisponible.'); return f; }
    if (d.tronque) dit('Transcript tronqué : seule la fin du fichier est lue.');
    f.appendChild(el('h4', 'Mandat'));
    f.appendChild(el('pre', d.mandat || ''));
    f.appendChild(el('h4', 'Messages'));
    for (const m of Array.isArray(d.messages) ? d.messages : []) f.appendChild(el('p', m));
    f.appendChild(el('h4', 'Outils'));
    const ul = el('ul');
    for (const o of Array.isArray(d.outils) ? d.outils : []) ul.appendChild(el('li', `${o.verbe || ''} ${o.cible || ''} (${o.outil || ''})${Number.isInteger(o.n) && o.n > 1 ? ' × ' + o.n : ''}`.replace(/\s+/g, ' '))); // PU-G-170 : les répétitions consécutives sont regroupées par le réducteur
    f.appendChild(ul);
    return f;
  };

  // CSS du tiroir « Au travail » (posé par 70-vf-live.js au premier dessin : ce fichier ne touche jamais au DOM au chargement)
  const CSS = `
    /* PU-G-188 : le titre reste en haut au défilement (collant, fond --surface du tiroir, aucune teinte) ; il reprend la marge du tiroir pour garder sa place au repos. Le bouton de fermeture du tiroir est celui de l'en-tête de la page (#btn-panel), hors du défilement */
    .vf-whop .aw-head { position: sticky; top: 0; z-index: 1; display: flex; align-items: baseline; justify-content: space-between; gap: var(--sp-12); margin: calc(-1 * var(--inset-panel)) calc(-1 * var(--inset-panel)) 0; padding: var(--inset-panel) var(--inset-panel) var(--sp-8); background: var(--surface); }
    .aw-surv { display: flex; align-items: flex-start; gap: var(--sp-8); margin: var(--sp-8) 0 0; font-size: 12px; line-height: 16px; color: var(--text-2); } .aw-surv b { font-weight: 500; color: var(--text); }
    .aw-count { font-size: 12px; color: var(--text-3); } .aw-count b { color: var(--text); font-weight: 600; font-variant-numeric: tabular-nums; }
    .aw-driver { display: flex; align-items: center; gap: var(--sp-8); margin: var(--sp-8) 0 var(--sp-12); font-size: 12px; color: var(--text-3); }
    .aw-driver .d { width: 6px; height: 6px; border-radius: 50%; background: var(--st-active); flex: none; }
    .aw-driver .t { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .aw-driver .n { font: 500 11.5px var(--mono, monospace); font-variant-numeric: tabular-nums; white-space: nowrap; }
    .aw-g { width: 16px; height: 16px; flex: none; display: block; fill: none; stroke: currentColor; stroke-width: 1.75; stroke-linecap: round; stroke-linejoin: round; }
    .aw-s-actif { color: var(--st-active); } .aw-s-attente, .aw-s-repos, .aw-s-attend { color: var(--text-2); } .aw-s-termine { color: var(--st-done); } .aw-s-bloque { color: var(--st-blocked); } .aw-s-orphelin { color: var(--text-3); }
    .aw-pulse { animation: vfrespire 2.4s ease-in-out infinite; }
    @keyframes vfrespire { 50% { transform: scale(.82); } }
    @media (prefers-reduced-motion: reduce) { .aw-pulse { animation: none; } .r-caret { transition: none !important; } }
    /* l'arbre : un fil de 1 px (--fil) relie le glyphe d'un parent à ceux de ses enfants, avec un coude vers chacun ; les traits s'arrêtent à 4 px des glyphes */
    .r-tree, .r-tree ul { list-style: none; margin: 0; padding: 0; }
    .r-ag { position: relative; }
    .r-line { position: relative; display: grid; grid-template-columns: minmax(0, 1fr) auto auto; align-items: start; }
    .r-line > .r-row, .r-line > .r-tog, .r-line > .r-doing { grid-row: 1; }
    .r-line > .r-row { grid-column: 1; } .r-line > .r-tog { grid-column: 2; } .r-line > .r-doing { grid-column: 3; }
    .r-line > .vf-doing, .r-line > .r-noeud { grid-column: 1 / -1; }
    .r-tog, .r-doing { width: 44px; height: 44px; margin-top: calc(-1 * var(--sp-4)); display: flex; align-items: center; justify-content: center; border: 0; background: none; color: var(--text-3); cursor: pointer; border-radius: 8px; padding: 0; }
    .r-doing { margin-right: calc(-1 * var(--sp-12)); } .r-line > .r-tog:not(:has(+ .r-doing)) { margin-right: calc(-1 * var(--sp-12)); }
    .r-tog:hover, .r-doing:hover { color: var(--text); background: rgba(var(--ink), .05); }
    .r-tog:focus-visible, .r-doing:focus-visible, .r-more:focus-visible, .aw-sec:focus-visible, a.r-row:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; border-radius: 8px; }
    .r-caret { transition: transform .15s var(--ease); } .r-tog[aria-expanded=true] .r-caret { transform: rotate(90deg); }
    .r-row { display: grid; grid-template-columns: 16px minmax(0, 1fr); column-gap: var(--sp-8); align-items: start; padding: var(--sp-8) 0; min-height: 44px; box-sizing: border-box; color: inherit; text-decoration: none; border-radius: 8px; }
    .r-row .aw-g { margin-top: var(--sp-2); } a.r-row:hover { background: rgba(var(--ink), .05); }
    .r-main { min-width: 0; display: flex; flex-direction: column; gap: var(--sp-2); }
    .r-top { display: flex; align-items: baseline; justify-content: space-between; gap: var(--sp-8); }
    .r-task { flex: 1; min-width: 0; font-size: 13px; line-height: 20px; font-weight: 500; color: var(--text); overflow: hidden; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; }
    .r-t { flex: none; font: 500 11.5px/20px var(--mono, monospace); color: var(--text-3); font-variant-numeric: tabular-nums; white-space: nowrap; }
    .r-t i { font-style: normal; font-family: var(--sans); font-weight: 400; font-size: 12px; } .r-t.ecrit { color: var(--text-2); }
    .r-meta { min-width: 0; font-size: 12px; line-height: 16px; color: var(--text-3); overflow-wrap: anywhere; }
    .r-meta b { font-weight: 500; color: var(--text-2); font-family: var(--mono, monospace); font-size: 11.5px; white-space: nowrap; }
    .r-chip, .r-flag { display: inline-block; margin-left: var(--sp-6); padding: 0 var(--sp-6); border-radius: 999px; border: 1px solid rgba(var(--ink), .2); font: 500 11px/16px var(--mono, monospace); color: var(--text-2); max-width: 152px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; vertical-align: bottom; }
    .r-flag { border-style: dashed; font-family: var(--sans); }
    .r-calme > .r-line .r-meta { color: var(--text-2); } .r-stale:not(.r-bloque) > .r-line .r-task { color: var(--text-3); } .r-sess > .r-line .r-task { font-weight: 600; }
    .r-fini .r-row { align-items: center; } .r-fini .r-task { font-weight: 400; color: var(--text-2); } .r-fini .r-t { line-height: 20px; } .r-fini .aw-g { margin-top: 0; }
    .r-line > .r-noeud { margin: 0 0 0 var(--sp-24); padding-top: var(--sp-4); min-height: 44px; box-sizing: border-box; display: flex; align-items: flex-start; font-size: 12px; justify-self: start; }
    .vf-whop .vf-doing { margin: 0 0 var(--sp-8) var(--sp-24); padding: var(--sp-8) var(--sp-12); border-radius: 8px; background: var(--raise); font: 12px/1.5 var(--mono, monospace); color: var(--text-2); word-break: break-word; }
    .vf-whop .vf-doing[hidden] { display: none; }
    .r-kids { margin-left: var(--sp-8); } .r-kids[hidden] { display: none; } .r-kids > li { padding-left: var(--sp-16); }
    .r-kids > li::after { content: ""; position: absolute; left: 0; top: 0; width: 12px; height: 18px; border-left: 1px solid var(--fil); border-bottom: 1px solid var(--fil); border-bottom-left-radius: 8px; }
    .r-kids > li:not(:last-child)::before { content: ""; position: absolute; left: 0; top: 18px; bottom: 0; border-left: 1px solid var(--fil); }
    .r-ag.has-kids:not(.closed) > .r-line::before { content: ""; position: absolute; left: 8px; top: 30px; bottom: 0; border-left: 1px solid var(--fil); }
    .aw-sec { display: flex; align-items: center; justify-content: space-between; min-height: 44px; margin: var(--sp-8) 0 0; font-size: 12px; color: var(--text-3); font-weight: 500; cursor: pointer; list-style: none; }
    .aw-sec::-webkit-details-marker { display: none; }
    details[open] > .aw-sec .r-caret { transform: rotate(90deg); }
    .r-more { display: flex; align-items: center; min-height: 44px; padding-left: var(--sp-24); font-size: 12px; color: var(--text-2); text-decoration: underline; text-decoration-color: rgba(var(--ink), .35); text-underline-offset: 4px; }
    .aw-sec2 { display: flex; justify-content: space-between; margin: var(--sp-16) 0 var(--sp-4); font-size: 12px; color: var(--text-3); font-weight: 500; }
    .r-verr { display: grid; margin: 0; padding: 0; list-style: none; font-size: 12px; color: var(--text-3); }
    .r-verr .aw-g { display: inline-block; vertical-align: -3px; margin-right: var(--sp-6); } .aw-aide { margin: 0 0 var(--sp-4); font-size: 12px; color: var(--text-3); }
    .r-verr li { display: flex; flex-wrap: wrap; justify-content: space-between; gap: var(--sp-4) var(--sp-12); padding: var(--sp-4) 0; } .r-verr li .n { margin-left: auto; } .r-verr b { color: var(--text-2); font-weight: 500; } .r-verr .n { font: 500 11.5px var(--mono, monospace); font-variant-numeric: tabular-nums; white-space: nowrap; }
    .aw-foot { margin: var(--sp-12) 0 0; color: var(--text-3); font-size: 12px; line-height: 20px; }
  `;

  window.__vfEquipeRendu = { glyphe, nomDeSession: (workers, id) => nommer(workers).get(id) || null, arbre, agentsDuNoeud, transcript, pied, piedCarte, st, duree, versNoeud, actif, surveiller, titreEquipe, ligneAgents, css: CSS };
})();
