// VibeFlow (75-08, ACTV-01 à ACTV-10) : les tables de marques des lentilles et le modèle du menu. Fonctions PURES : ni DOM, ni réseau, ni horloge
// (testées en `vm`). Une table = rangées [id, palier, glyphe, mot, infobulle] du canal VF_MARQUES (75-07, API figée). Toute chaîne vient d'ici :
// UNE rédaction par emplacement ; espace insécable (U+00A0) avant `: ; ! ? %` et dans les nombres à partir de 1 000 ; point médian, aucun tiret long.
// `v` (la vue) : { fichier(chemin) -> { l, st } | null, existe(id), visible(id), ancetres(id) -> [id], selection, filtre }. `d` : GET
// /api/vf/activite.
// Exposé : window.VF_ACTIVITE_TABLES (gelé), lu par les autres fichiers de la lentille au moment de leur rappel de coquille.
(() => {
  'use strict';
  const NB = ' ';
  const nb = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, NB);
  const pl = (n, un, plus) => `${nb(n)} ${n < 2 ? un : plus}`;
  const joindre = (l) => (l.length < 2 ? l.join('') : `${l.slice(0, -1).join(', ')} et ${l[l.length - 1]}`);

  const LENTILLES = Object.freeze([
    { id: 'aucune', nom: 'Aucune', sous: 'Aucune marque de lentille' },
    { id: 'chauds', nom: 'Points chauds', sous: 'Ce qui change souvent et pèse lourd' },
    { id: 'couplage', nom: 'Couplage', sous: 'Ce qui change avec le fichier choisi' },
    { id: 'gardes', nom: 'Gardes', sous: "Ce qu'une suite ou un gate nomme" },
    { id: 'empreinte', nom: 'Empreinte', sous: 'Ce que les agents lisent et écrivent' },
  ]);
  const TEXTES = Object.freeze({ // une seule rédaction par emplacement (P75-D-26, J1)
    infobulle: "Lentille d'activité sur le code", titre: "Lentille d'activité sur le code", legende: 'Légende de la lentille',
    groupeLentille: 'Lentille', groupeAgents: 'Agents', toutes: "Toute l'équipe", limites: 'Ce que la lecture ne voit pas',
    indispo: "Indisponible pour l'instant", reessai: 'Nouvelle lecture au prochain changement du dépôt', gardesAbsentes: 'Gardes non lues sur ce lab',
    relecture: 'En cours de relecture', lecture: 'En cours de lecture', vide: 'Aucune modification sur 90 jours',
    chauds: [`Haut${NB}: tiers le plus changé et le plus gros`, 'Moyen', 'Bas'],
    fenetre: 'Commits des 90 derniers jours, hors fusions', partiel: 'Historique partiel',
    couplage: [`Haut${NB}: 75${NB}% et plus`, `Moyen${NB}: 50 à 74${NB}%`, `Bas${NB}: 30 à 49${NB}%`],
    attente: `Sélectionnez un fichier${NB}: ceux qui changent avec lui sont marqués.`, noeud: 'Le couplage se lit sur un fichier.',
    gardes: [`Garde du dépôt${NB}: un gate, une suite ou un hook lui-même`, 'Aucune suite ne le nomme', `Nommé par n suites${NB}: pas de glyphe, le mot seul`,
      "Lecture des noms cités par les suites et les gates, rien n'est exécuté"],
    empreinte: ['En écriture maintenant', 'Modifié par un agent vivant', 'Lu par un agent vivant', 'Fini il y a moins de 24 h'],
    commandes: 'Écritures par commande non vues.',
    relectureEmpreinte: 'Empreinte en cours de relecture, radar incomplet. Reprise dans quelques secondes.',
    perdueEmpreinte: `Empreinte indisponible${NB}: connexion au cockpit perdue. Reprise automatique au retour de la connexion.`,
    conservee: `Dernière lecture conservée${NB}: connexion perdue.`, coupees: `Radar incomplet${NB}: cibles coupées.`,
    radarRelecture: 'Radar en cours de relecture', radarPerdu: `Radar incomplet${NB}: connexion perdue`,
    radarBranches: `Radar incomplet${NB}: branches non lues`,
    radarTronque: `Radar incomplet${NB}: historique tronqué.`, radarIncomplet: 'Radar incomplet', radarAucune: `Radar de collisions${NB}: aucune collision vue`,
    radarBranchesMax: 'Radar limité à 12 branches', plansAJour: `Recoupement des plans${NB}: à jour.`, aucunLie: 'aucun fichier lié', tousNommes: 'tous nommés',
    changeAvec: 'Change souvent avec', sansSeuil: `Aucun fichier au-dessus des seuils (5 révisions communes, 30${NB}%)`,
    pied90: "Sur 90 jours, d'après l'historique des commits",
    gardesTitre: 'Gardes', chaudsTitre: 'Points chauds', nommePar: `Nommé par${NB}:`, gardeDepot: 'Garde du dépôt',
    aucunTemoin: 'Aucune suite ni aucun gate ne le nomme',
    agentsSur: 'Agents sur ce fichier', collisionsTitre: 'Collisions possibles', baseDeCode: 'Base de code',
  });
  const F = Object.freeze({
    bouton: (nom) => `Lentille${NB}: ${nom}`,
    aria: (nom, n) => `Lentille${NB}: ${nom}${n > 0 ? `, ${pl(n, 'fichier', 'fichiers')} en cours d'écriture` : ''}`,
    indispoLegende: (id) => ({ chauds: "Points chauds indisponibles pour l'instant.", couplage: "Couplage indisponible pour l'instant.",
      gardes: "Gardes indisponibles pour l'instant.", empreinte: "Empreinte indisponible pour l'instant." })[id],
    radarN: (n) => `Radar de collisions${NB}: ${pl(n, 'fichier', 'fichiers')}`,
    compteLong: (n) => `${pl(n, 'fichier', 'fichiers')} en collision possible`, compteCourt: (n) => pl(n, 'fichier', 'fichiers'),
    horsLab: (n) => `Écritures hors du lab${NB}: ${nb(n)} ${n < 2 ? 'comptée' : 'comptées'}, non ${n < 2 ? 'dessinée' : 'dessinées'}.`,
    termines: (n) => `Terminés dans les 24 h (${nb(n)})`, etAutres: (n) => `et ${pl(n, 'autre', 'autres')}`,
    horsCarte: (n) => `${nb(n)} hors carte.`, prevusIgnores: (n) => `${nb(n)} ${n < 2 ? 'prévu ignoré' : 'prévus ignorés'}`,
    piedLong: (n) => (n > 0
      ? `Non vu par le radar${NB}: écritures par commande, écritures dans un arbre hors du dossier du lab (${nb(n)} ${n < 2 ? 'comptée' : 'comptées'}).`
      : `Non vu par le radar${NB}: écritures par commande.`),
    infoCourte: (n) => (n > 0 ? `Non vu${NB}: commandes, arbres hors du lab (${nb(n)})` : `Non vu${NB}: commandes`),
    annonceRadar: (n) => `Radar${NB}: ${pl(n, 'fichier', 'fichiers')} en collision possible`,
    annonceCouplage: (n) => (n > 0 ? `Couplage${NB}: ${pl(n, 'fichier lié', 'fichiers liés')}.` : `Couplage${NB}: aucun fichier lié.`),
    annonce: (nom, n, cas) => { // « Lentille Points chauds : 12 fichiers au palier haut. », …
      if (cas === 'indispo') return `Lentille ${nom} indisponible.`;
      const f = { chauds: ['fichier', 'fichiers', 'au palier haut'], gardes: ['fichier', 'fichiers', 'sans témoin'],
        empreinte: ['fichier', 'fichiers', "en cours d'écriture"] }[cas];
      return f ? `Lentille ${nom}${NB}: ${pl(n, f[0], f[1])} ${f[2]}.` : `Lentille ${nom}.`;
    },
  });

  // ---------- les fichiers marquables et les tables des lentilles ----------
  const PRE = '/tests/test-';
  const estSuite = (p) => { const i = p.indexOf(PRE); return i >= 0 && p.endsWith('.sh') && p.length >= i + PRE.length + 3; };
  const marquable = (v, p) => { const f = v.fichier(p);
    return !!f && f.st !== 'prevu' && f.l !== 'docs' && !estSuite(p) && !p.split('/').includes('fixtures'); };
  const PAL = { 3: 'haut', 2: 'moyen', 1: 'bas' };
  const palCouplage = (deg) => (deg >= 75 ? 'haut' : deg >= 50 ? 'moyen' : 'bas');
  const DEGRES = ['en-cours', 'modifie', 'lu', 'fini'];
  const MOT_DEGRE = { 'en-cours': 'en écriture', modifie: 'modifié', lu: 'lu', fini: 'fini' };
  const SOURCES = ['agents', 'arbres', 'branches', 'plans'];
  const role = (n) => String(n).split(' · ')[0];
  const missionDe = (n) => { const m = / · nœud (.+?)(?: · |$)/.exec(String(n)); return m ? m[1] : null; };
  const missions = (d) => {
    const s = new Set();
    for (const [, , noms] of (d.empreinte && d.empreinte.marques) || []) for (const n of noms || []) { const m = missionDe(n); if (m) s.add(m); }
    return [...s].slice(0, 5);
  };
  const voisins = (d, p, max = 5) => ((d.git && d.git.couplage) || []).filter((t) => t[0] === p || t[1] === p)
    .map((t) => [t[0] === p ? t[1] : t[0], Math.round(t[3]), t[2]]).sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1)).slice(0, max);

  const infoChaud = (g, t) => `${pl(t[1], 'changement', 'changements')} sur ${(g.fenetre && g.fenetre.jours) || 90} jours`
    + ` · ${pl(t[2], 'ligne', 'lignes')} · rang ${nb(t[3])} sur ${nb(g.chauds.length)}`;
  const chaud = (d, p) => { const t = d && d.git && Array.isArray(d.git.chauds) ? d.git.chauds.find((x) => x[0] === p) : null;
    return t ? { palier: PAL[t[4]] || 'bas', info: infoChaud(d.git, t) } : null; };
  const tableChauds = (d, v) => d.git.chauds.filter((t) => marquable(v, t[0])).map((t) => ['f:' + t[0], PAL[t[4]] || 'bas', 'barres',
    pl(t[1], 'changement', 'changements'), infoChaud(d.git, t)]);
  const tableCouplage = (d, v) => {
    const s = v.selection;
    if (typeof s !== 'string' || !s.startsWith('f:') || !v.visible(s)) return [];
    const vs = voisins(d, s.slice(2)), rows = [];
    for (const [p, deg, com] of vs) {
      if (v.visible('f:' + p)) rows.push(['f:' + p, palCouplage(deg), 'barres', `${deg}${NB}% avec la sélection`,
        `Change avec ce fichier dans ${deg}${NB}% des commits, ${pl(com, 'révision commune', 'révisions communes')}`]);
    }
    const mot = vs.length === 0 ? TEXTES.aucunLie : pl(rows.length, 'voisin marqué', 'voisins marqués');
    return [[s, null, '', mot, mot], ...rows];
  };
  const tableGardes = (d, v) => {
    const rows = [], tot = new Map(), sans = new Map();
    for (const [p, n, g] of d.gardes.gardes) {
      if (!marquable(v, p)) continue;
      const id = 'f:' + p, nu = !g && n === 0, nom = `nommé par ${pl(n, 'suite', 'suites')}`;
      rows.push(g ? [id, null, 'bouclier', 'garde du dépôt', 'garde du dépôt']
        : nu ? [id, null, 'sans-temoin', 'aucune suite ne le nomme', 'aucune suite ne le nomme'] : [id, null, '', nom, nom]);
      for (const a of v.ancetres(id)) { tot.set(a, (tot.get(a) || 0) + 1); if (nu) sans.set(a, (sans.get(a) || 0) + 1); }
    }
    for (const [a, t] of tot) { // l'agrégat de nœud de Gardes n'est pas celui du canal : « 12 sur 40 sans témoin », posé en rangée propre du nœud
      const s = sans.get(a) || 0;
      rows.push(s ? [a, null, 'sans-temoin', `${nb(s)} sur ${nb(t)} sans témoin`, `${pl(s, 'fichier', 'fichiers')} sur ${nb(t)} sans témoin`]
        : [a, null, '', TEXTES.tousNommes, TEXTES.tousNommes]);
    }
    return rows;
  };
  const tableEmpreinte = (d, v, conn) => {
    if (conn === 'perdu' || !d.empreinte || d.empreinte.etat === 'indisponible') return [];
    return d.empreinte.marques.filter(([p, deg, noms]) => DEGRES.includes(deg) && Array.isArray(noms) && v.existe('f:' + p)
      && (!v.filtre || noms.some((n) => missionDe(n) === v.filtre))).map(([p, deg, noms]) => ['f:' + p, deg, deg,
      noms.length ? `${MOT_DEGRE[deg]} · ${role(noms[0])}${noms.length > 1 ? ` et ${pl(noms.length - 1, 'autre', 'autres')}` : ''}` : MOT_DEGRE[deg],
      `${MOT_DEGRE[deg]} · ${noms.join(', ')}`]);
  };
  const SOURCE_MOT = {
    agents: (n) => `écrit par ${nb(n)} agents`, arbres: (n) => `modifié dans ${nb(n)} arbres${NB}: conflit de fusion possible`,
    branches: (n) => `modifié sur ${nb(n)} branches`,
    plans: (n, vague) => `prévu par ${nb(n)} plans${vague === null || vague === undefined ? '' : `, vague ${vague}`}`,
  };
  const parFichier = (d, v) => { // chemin -> [[source, noms, vague]] dans l'ordre agents, arbres, branches, plans (les fichiers sans carte sont écartés)
    const m = new Map();
    for (const [p, src, noms, vague] of (d && d.collisions) || []) {
      if (!SOURCES.includes(src) || !Array.isArray(noms) || !v.existe('f:' + p)) continue;
      if (!m.has(p)) m.set(p, []);
      m.get(p).push([src, noms, vague]);
    }
    for (const l of m.values()) l.sort((a, b) => SOURCES.indexOf(a[0]) - SOURCES.indexOf(b[0]));
    return m;
  };
  const tableCollisions = (d, v) => {
    const rows = [];
    for (const [p, l] of parFichier(d, v)) {
      for (const [src, noms, vague] of l) rows.push(['f:' + p, src, 'confluent', SOURCE_MOT[src](noms.length, vague), joindre(noms)]);
    }
    return rows;
  };
  const TABLES = { chauds: tableChauds, couplage: tableCouplage, gardes: tableGardes, empreinte: tableEmpreinte };
  const table = (id, d, v, conn) => (d && TABLES[id] && etat(id, d, conn) === 'ok' ? TABLES[id](d, v, conn) : []);

  // ---------- états ----------
  function etat(id, d, conn) { // 'ok' | 'indispo' | 'absente' | 'lecture' | 'cachee'
    if (id === 'aucune') return 'ok';
    if (!d) return 'lecture';
    if (id === 'chauds' || id === 'couplage') {
      const e = d.git && d.git.etat;
      return e === 'ok' || e === 'vide' ? 'ok' : e === 'absent' ? 'cachee' : e === 'en-lecture' ? 'lecture' : 'indispo';
    }
    if (id === 'gardes') { const e = d.gardes && d.gardes.etat;
      return e === 'ok' ? 'ok' : e === 'non-lues' ? 'absente' : e === 'en-lecture' ? 'lecture' : 'indispo'; }
    const e = d.empreinte && d.empreinte.etat;
    return conn === 'perdu' || !e || e === 'indisponible' ? 'indispo' : 'ok'; // en construction ou tronquée : les marques connues restent
  }
  const raisons = (d) => ((d && d.radar && d.radar.raisons) || []);
  const radar = (d, conn, n) => { // { n, texte, ligne, etat : 'ok' | 'zero' | 'incomplet' }
    const r = raisons(d), pas = !d || d.calcul === 'en-cours';
    let t = null;
    if (conn === 'perdu') t = TEXTES.radarPerdu;
    else if (!d || r.includes('en-construction')) t = TEXTES.radarRelecture;
    else if (r.includes('branches-indisponible')) t = TEXTES.radarBranches;
    else if (r.includes('tronque')) t = TEXTES.radarTronque;
    else if (r.includes('cibles-coupees') || (d.empreinte && d.empreinte.coupees > 0)) t = TEXTES.coupees;
    else if (d.radar && d.radar.incomplet) t = TEXTES.radarIncomplet;
    else if (pas && n === 0) t = TEXTES.radarRelecture; // jamais « aucune collision » sur un calcul qui n'est pas fini
    if (t) return { n, texte: t, ligne: t, etat: 'incomplet' };
    return n > 0 ? { n, texte: F.compteLong(n), ligne: F.radarN(n), etat: 'ok' } : { n: 0, texte: '', ligne: TEXTES.radarAucune, etat: 'zero' };
  };
  const legende = (id, d, conn, v, e) => { // { lignes : [{ g, t }], limites : [texte] }
    const L = [], lim = [], g = (k, t) => L.push({ g: k, t }), s = (t) => L.push({ g: null, t });
    if (id === 'aucune') return { lignes: L, limites: lim };
    if (e === 'indispo' && id !== 'empreinte') { s(F.indispoLegende(id)); return { lignes: L, limites: lim }; }
    if (id === 'chauds') {
      if (d && d.git && d.git.etat === 'vide') s(TEXTES.vide);
      else { ['haut', 'moyen', 'bas'].forEach((k, i) => g(k, TEXTES.chauds[i])); s(TEXTES.fenetre); }
      const f = d && d.git && d.git.fenetre;
      if (f && f.plafondAtteint) s(`Fenêtre réduite à ${nb(f.plafond)} commits`);
      if (f && f.partiel) s(TEXTES.partiel);
    } else if (id === 'couplage') {
      const sel = v.selection;
      if (typeof sel !== 'string') s(TEXTES.attente);
      else if (!sel.startsWith('f:')) s(TEXTES.noeud);
      else ['haut', 'moyen', 'bas'].forEach((k, i) => g(k, TEXTES.couplage[i]));
    } else if (id === 'gardes') {
      g('bouclier', TEXTES.gardes[0]); g('sans-temoin', TEXTES.gardes[1]); s(TEXTES.gardes[2]); s(TEXTES.gardes[3]);
      const n = d && d.gardes && d.gardes.prevusIgnores;
      if (n > 0) s(F.prevusIgnores(n));
    } else if (conn === 'perdu' || e === 'indispo') s(TEXTES.perdueEmpreinte);
    else {
      if (d.empreinte.etat === 'en-construction') s(TEXTES.relectureEmpreinte);
      DEGRES.forEach((k, i) => g(k, TEXTES.empreinte[i]));
      lim.push(TEXTES.commandes);
      const em = d.empreinte;
      if (em.horsLab > 0) lim.push(F.horsLab(em.horsLab));
      if (em.horsCarte > 0) lim.push(F.horsCarte(em.horsCarte));
      if (em.coupees > 0 || raisons(d).includes('cibles-coupees')) lim.push(TEXTES.coupees);
    }
    if (conn === 'perdu' && id !== 'empreinte' && e === 'ok') s(TEXTES.conservee);
    return { lignes: L, limites: lim };
  };
  const compte = (id, rows) => (id === 'chauds' ? rows.filter((r) => r[1] === 'haut').length
    : id === 'gardes' ? rows.filter((r) => r[2] === 'sans-temoin' && r[0].startsWith('f:')).length
      : id === 'empreinte' ? rows.filter((r) => r[1] === 'en-cours').length : null);

  // le modèle du menu : tout ce que l'écran en montre, sans DOM. `lentille` : choix courant ; une lentille « cachée » (git absent) revient à Aucune.
  const modele = ({ d, conn, lentille, filtre, vue }) => {
    const v = { ...vue, filtre: filtre || null };
    const n = parFichier(d, v).size, lignes = [];
    let actif = LENTILLES.some((l) => l.id === lentille) && etat(lentille, d, conn) !== 'cachee' ? lentille : 'aucune';
    for (const l of LENTILLES) {
      const e = etat(l.id, d, conn);
      if (e === 'cachee') continue;
      const rel = l.id === 'empreinte' && e === 'ok' && d && d.empreinte.etat === 'en-construction';
      const sous = e === 'indispo' ? TEXTES.indispo : e === 'absente' ? TEXTES.gardesAbsentes
        : e === 'lecture' ? TEXTES.lecture : rel ? TEXTES.relecture : l.sous;
      const c = e === 'ok' && d ? compte(l.id, table(l.id, d, v, conn)) : null;
      lignes.push({ id: l.id, nom: l.nom, sous, etat: e, compte: c, coche: l.id === actif,
        description: e === 'indispo' ? [TEXTES.indispo, TEXTES.reessai] : null });
    }
    const e = etat(actif, d, conn), nom = LENTILLES.find((l) => l.id === actif).nom;
    const rows = table(actif, d, v, conn), lg = legende(actif, d, conn, v, e);
    const enCours = d && d.empreinte && conn !== 'perdu' && d.empreinte.etat !== 'indisponible'
      ? (d.empreinte.marques || []).filter(([p, deg]) => deg === 'en-cours' && v.existe('f:' + p)).length : 0;
    const lien = (d && d.empreinte && d.empreinte.etat) === 'ok' || (d && d.empreinte && d.empreinte.etat === 'en-construction');
    return { lentille: actif, indispo: e === 'indispo' && actif !== 'aucune', lignes, legende: lg.lignes, limites: lg.limites, radar: radar(d, conn, n),
      agents: actif === 'empreinte' && lien && conn !== 'perdu' ? missions(d) : [], pastille: enCours, rows, nom,
      bouton: { libelle: F.bouton(nom), aria: F.aria(nom, enCours) },
      annonce: e === 'indispo' && actif !== 'aucune' ? F.annonce(nom, 0, 'indispo') : F.annonce(nom, compte(actif, rows) || 0, actif) };
  };

  window.VF_ACTIVITE_TABLES = Object.freeze({ chaud, LENTILLES, TEXTES, F, NB, nb, pl, joindre, table, tableCollisions, modele, etat, radar,
    parFichier, voisins, palCouplage,
    missions, missionDe, role, marquable, MOT_DEGRE, SOURCE_MOT, SOURCES, PAL });
})();
