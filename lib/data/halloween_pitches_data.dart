/// Un pitch de l'event Halloween : un film d'horreur ou d'Halloween raconté
/// du point de vue (bienveillant) de son méchant. Pas de noms colorés ici :
/// le joueur trouve le titre avec les seules lettres et trois jokers.
class EventPitch {
  final String titleFr;
  final String titleEn;
  final String year;
  final String pitchFr;
  final String pitchEn;

  const EventPitch({
    required this.titleFr,
    required this.titleEn,
    required this.year,
    required this.pitchFr,
    required this.pitchEn,
  });

  String titleFor(String locale) => locale == 'en' ? titleEn : titleFr;
  String pitchFor(String locale) => locale == 'en' ? pitchEn : pitchFr;
}

/// Les 30 pitchs, dans l'ordre où le joueur les découvre (du plus facile au
/// plus difficile).
const kHalloweenPitches = [
  EventPitch(
    titleFr: 'Les Dents de la mer',
    titleEn: 'Jaws',
    year: '1975',
    pitchFr: 'Un nageur solitaire aimerait simplement déjeuner au large d\'une station balnéaire. '
        'Trois hommes sur un bateau trop petit s\'acharnent à lui pourrir l\'été.',
    pitchEn: 'A lone swimmer just wants a quiet lunch off a seaside resort. '
        'Three men on a boat that\'s too small make it their mission to ruin his summer.',
  ),
  EventPitch(
    titleFr: 'Ça',
    titleEn: 'It',
    year: '2017',
    pitchFr: 'Un clown très investi dans la vie locale revient tous les vingt-sept ans distribuer des ballons '
        'rouges aux enfants. Une bande de gamins sans cœur refuse de flotter avec lui.',
    pitchEn: 'A clown deeply involved in his community comes back every twenty-seven years to hand out red '
        'balloons to the kids. A gang of heartless brats refuses to float with him.',
  ),
  EventPitch(
    titleFr: 'Dracula',
    titleEn: 'Dracula',
    year: '1992',
    pitchFr: 'Un comte insomniaque quitte son château des Carpates pour refaire sa vie à Londres. '
        'Un vieux professeur obsédé par l\'ail et les pieux sabote son installation.',
    pitchEn: 'A sleepless count leaves his castle in the Carpathians to start a new life in London. '
        'An old professor obsessed with garlic and stakes sabotages his move.',
  ),
  EventPitch(
    titleFr: 'Frankenstein',
    titleEn: 'Frankenstein',
    year: '1931',
    pitchFr: 'Un grand bébé de deux mètres, cousu main, cherche désespérément l\'amour de son papa. '
        'Celui-ci passe sa vie à le fuir à travers le monde.',
    pitchEn: 'A seven-foot, hand-stitched baby desperately seeks his dad\'s love. '
        'Dad spends his whole life running away from him.',
  ),
  EventPitch(
    titleFr: 'Alien',
    titleEn: 'Alien',
    year: '1979',
    pitchFr: 'Un nouveau-né indigeste essaie de se faire des amis dans un vaisseau spatial. '
        'Les passagers le rejettent avec véhémence.',
    pitchEn: 'A hard-to-digest newborn tries to make friends on a spaceship. '
        'The crew rejects him vehemently.',
  ),
  EventPitch(
    titleFr: 'Gremlins',
    titleEn: 'Gremlins',
    year: '1984',
    pitchFr: 'Une bande de joyeux fêtards compte profiter de Noël dans une petite ville tranquille. '
        'Ils ont seulement grignoté un peu après minuit, mais un jeune employé de banque leur casse l\'ambiance.',
    pitchEn: 'A bunch of party animals just want to enjoy Christmas in a quiet little town. '
        'They only had a tiny snack after midnight, but a young bank clerk spoils the fun.',
  ),
  EventPitch(
    titleFr: 'Halloween',
    titleEn: 'Halloween',
    year: '1978',
    pitchFr: 'Un grand timide rentre enfin dans sa ville natale après quinze ans d\'internat. '
        'Sa voisine baby-sitter refuse obstinément de jouer à cache-cache avec lui.',
    pitchEn: 'A shy guy finally comes back to his hometown after fifteen years at boarding school. '
        'The babysitter next door stubbornly refuses to play hide-and-seek with him.',
  ),
  EventPitch(
    titleFr: 'La Momie',
    titleEn: 'The Mummy',
    year: '1999',
    pitchFr: 'Un prêtre égyptien, réveillé après 3 000 ans de sieste, rêve de retrouver son amour de jeunesse. '
        'Une bande de pilleurs de tombes lui met des bâtons dans les bandelettes.',
    pitchEn: 'An Egyptian priest, waking up from a 3,000-year nap, dreams of finding his first love. '
        'A gang of tomb raiders keeps unraveling his plans.',
  ),
  EventPitch(
    titleFr: 'Scream',
    titleEn: 'Scream',
    year: '1996',
    pitchFr: 'Un grand cinéphile appelle des ados au hasard pour leur proposer un quiz sur les films d\'horreur. '
        'Aucun candidat n\'a jamais gagné.',
    pitchEn: 'A huge movie buff calls random teens to play a horror-movie quiz over the phone. '
        'Nobody has ever won.',
  ),
  EventPitch(
    titleFr: 'Shining',
    titleEn: 'The Shining',
    year: '1980',
    pitchFr: 'Un écrivain en manque d\'inspiration accepte de garder un hôtel isolé tout l\'hiver pour écrire en paix. '
        'Sa femme et son fils n\'arrêtent pas de le déranger.',
    pitchEn: 'A writer with writer\'s block agrees to look after a remote hotel all winter to write in peace. '
        'His wife and son keep interrupting him.',
  ),
  EventPitch(
    titleFr: 'Hocus Pocus',
    titleEn: 'Hocus Pocus',
    year: '1993',
    pitchFr: 'Trois sœurs, de retour après trois siècles d\'absence, comptent sur une soirée d\'Halloween pour '
        'retrouver leur jeunesse. Un ado maladroit, sa petite sœur et un chat qui parle font capoter leurs '
        'retrouvailles.',
    pitchEn: 'Three sisters, back after three centuries away, are counting on Halloween night to get their youth '
        'back. A clumsy teen, his little sister and a talking cat wreck their reunion.',
  ),
  EventPitch(
    titleFr: 'Hôtel Transylvanie',
    titleEn: 'Hotel Transylvania',
    year: '2012',
    pitchFr: 'Un papa poule de plus de cinq cents ans tient un palace réservé aux monstres pour protéger sa fille. '
        'Un jeune routard humain s\'incruste et lui tourne la tête.',
    pitchEn: 'An overprotective 500-year-old single dad runs a monsters-only resort to keep his daughter safe. '
        'A human backpacker crashes the place and steals her heart.',
  ),
  EventPitch(
    titleFr: 'Casper',
    titleEn: 'Casper',
    year: '1995',
    pitchFr: 'Trois tontons fantômes un peu farceurs élèvent leur neveu dans un vieux manoir. '
        'Un psy et sa fille s\'y installent sans jamais payer de loyer.',
    pitchEn: 'Three prankster ghost uncles raise their nephew in an old mansion. '
        'A shrink and his daughter move in and never pay rent.',
  ),
  EventPitch(
    titleFr: 'SOS Fantômes',
    titleEn: 'Ghostbusters',
    year: '1984',
    pitchFr: 'Les esprits de New York vivent tranquillement leur vie après la mort. Trois scientifiques au chômage, '
        'armés d\'aspirateurs nucléaires, décident d\'en faire leur fonds de commerce.',
    pitchEn: 'New York\'s spirits are quietly enjoying their afterlife. Three unemployed scientists armed with '
        'nuclear vacuums decide to turn them into a business.',
  ),
  EventPitch(
    titleFr: 'Beetlejuice',
    titleEn: 'Beetlejuice',
    year: '1988',
    pitchFr: 'Un consultant indépendant propose ses services à un jeune couple de fantômes envahi par de nouveaux '
        'voisins. Il ne demande en échange qu\'un tout petit mariage.',
    pitchEn: 'A freelance consultant offers his services to a young ghost couple overrun by new neighbors. '
        'All he asks in return is one teeny little wedding.',
  ),
  EventPitch(
    titleFr: 'Sleepy Hollow',
    titleEn: 'Sleepy Hollow',
    year: '1999',
    pitchFr: 'Un cavalier émérite, un peu tête en l\'air, tient à récupérer ce qu\'on lui a pris. '
        'Un enquêteur new-yorkais trouillard se mêle de ce qui ne le regarde pas.',
    pitchEn: 'A skilled horseman who tends to lose his head over things wants back what was taken from him. '
        'A cowardly New York investigator sticks his nose where it doesn\'t belong.',
  ),
  EventPitch(
    titleFr: 'Les Griffes de la nuit',
    titleEn: 'A Nightmare on Elm Street',
    year: '1984',
    pitchFr: 'Un artiste du rêve, fan de pulls rayés et de manucure audacieuse, offre des cauchemars sur mesure aux '
        'ados de sa rue. Peu reconnaissants, ils boivent des litres de café pour ne plus jamais s\'endormir.',
    pitchEn: 'A dream artist with a taste for striped sweaters and bold manicures offers made-to-measure bad dreams '
        'to the neighborhood teens. Not exactly grateful, they drink gallons of coffee to never fall asleep again.',
  ),
  EventPitch(
    titleFr: 'Psychose',
    titleEn: 'Psycho',
    year: '1960',
    pitchFr: 'Un jeune gérant de motel, aux petits soins pour sa vieille mère, apprécie le calme de sa route oubliée. '
        'Une cliente en cavale débarque avec une valise de billets et monopolise la douche.',
    pitchEn: 'A young motel manager who dotes on his elderly mother enjoys the peace and quiet of his forgotten road. '
        'A runaway guest shows up with a suitcase full of cash and hogs the shower.',
  ),
  EventPitch(
    titleFr: 'Le Silence des agneaux',
    titleEn: 'The Silence of the Lambs',
    year: '1991',
    pitchFr: 'Un psychiatre gastronome aide bénévolement une jeune stagiaire du FBI dans son enquête. '
        'En échange, il lui demande juste de lui raconter ses souvenirs d\'enfance.',
    pitchEn: 'A foodie psychiatrist volunteers to help a young FBI trainee with her case. '
        'In return, all he asks is that she share her childhood memories.',
  ),
  EventPitch(
    titleFr: 'L\'Exorciste',
    titleEn: 'The Exorcist',
    year: '1973',
    pitchFr: 'Un locataire discret emménage chez une adolescente et lui apprend des tours de souplesse, comme '
        'tourner la tête à 360°. Deux prêtres débarquent pour l\'expulser sans préavis.',
    pitchEn: 'A quiet tenant moves in with a teenage girl and teaches her flexibility tricks, like turning her head '
        '360°. Two priests show up to evict him without notice.',
  ),
  EventPitch(
    titleFr: 'Le Cercle',
    titleEn: 'The Ring',
    year: '2002',
    pitchFr: 'Une jeune artiste, coincée au fond d\'un puits, diffuse son unique court-métrage sur cassette vidéo. '
        'Elle laisse à chaque spectateur sept jours pour lui faire un retour.',
    pitchEn: 'A young artist stuck at the bottom of a well releases her only short film on videotape. '
        'She gives every viewer seven days to send feedback.',
  ),
  EventPitch(
    titleFr: 'Annabelle',
    titleEn: 'Annabelle',
    year: '2014',
    pitchFr: 'Une poupée de collection très attachée à sa nouvelle famille voudrait qu\'on joue avec elle, jour et '
        'nuit. Ses propriétaires préfèrent l\'enfermer dans une vitrine.',
    pitchEn: 'A collector\'s doll, very attached to her new family, would love someone to play with her day and '
        'night. Her owners would rather lock her in a glass case.',
  ),
  EventPitch(
    titleFr: 'Saw',
    titleEn: 'Saw',
    year: '2004',
    pitchFr: 'Un ingénieur à la retraite organise des escape games pour apprendre aux gens à apprécier la vie. '
        'Curieusement, ses participants ne laissent jamais d\'avis positif.',
    pitchEn: 'A retired engineer runs escape rooms to teach people to appreciate life. '
        'Oddly, his players never leave a good review.',
  ),
  EventPitch(
    titleFr: 'La Fiancée de Chucky',
    titleEn: 'Bride of Chucky',
    year: '1998',
    pitchFr: 'Un petit bonhomme roux en salopette, coincé dans un corps en plastique, retrouve enfin l\'amour avec '
        'une blonde au caractère bien trempé. Un jeune couple en fuite vient perturber leur road trip romantique.',
    pitchEn: 'A little red-haired guy in overalls, stuck in a plastic body, finally finds love with a feisty blonde. '
        'A young couple on the run spoils their romantic road trip.',
  ),
  EventPitch(
    titleFr: 'Les Oiseaux',
    titleEn: 'The Birds',
    year: '1963',
    pitchFr: 'Des milliers de volatiles organisent une grande manifestation dans une petite ville côtière. '
        'Les habitants, mauvais public, se barricadent chez eux.',
    pitchEn: 'Thousands of feathered protesters stage a huge rally in a small coastal town. '
        'The locals, a tough crowd, barricade themselves at home.',
  ),
  EventPitch(
    titleFr: 'Carrie',
    titleEn: 'Carrie',
    year: '1976',
    pitchFr: 'Une lycéenne timide, élue reine du bal de fin d\'année, fait enfin une démonstration de ses talents '
        'cachés devant toute l\'école. Le public n\'apprécie pas son numéro.',
    pitchEn: 'A shy high schooler, crowned prom queen, finally shows off her hidden talents in front of the whole '
        'school. The audience doesn\'t appreciate her act.',
  ),
  EventPitch(
    titleFr: 'Misery',
    titleEn: 'Misery',
    year: '1990',
    pitchFr: 'Une infirmière, fan numéro un d\'un romancier, le recueille après un accident et lui offre le gîte, '
        'le couvert et des conseils d\'écriture. Le malotru ne pense qu\'à repartir sur ses deux jambes.',
    pitchEn: 'A nurse, a novelist\'s number one fan, takes him in after an accident and offers him room, board and '
        'writing advice. The ungrateful guest only wants to walk out on his own two feet.',
  ),
  EventPitch(
    titleFr: 'Poltergeist',
    titleEn: 'Poltergeist',
    year: '1982',
    pitchFr: 'Des esprits, locataires historiques d\'un vieux terrain, découvrent qu\'on y a construit un '
        'lotissement sans les prévenir. Ils tentent de dialoguer par la télé, mais seule la petite dernière les '
        'écoute.',
    pitchEn: 'Spirits who have long lived on an old piece of land discover a housing development was built on it '
        'without asking them. They try to talk through the TV, but only the youngest daughter listens.',
  ),
  EventPitch(
    titleFr: 'Christine',
    titleEn: 'Christine',
    year: '1983',
    pitchFr: 'Une voiture de collection, fidèle et protectrice, s\'attache passionnément à son jeune propriétaire. '
        'Elle a juste un peu de mal avec ses amis et sa copine.',
    pitchEn: 'A loyal, protective vintage car becomes passionately attached to her young owner. '
        'She just has a little trouble with his friends and his girlfriend.',
  ),
  EventPitch(
    titleFr: 'La Mouche',
    titleEn: 'The Fly',
    year: '1986',
    pitchFr: 'Un chercheur passionné invente la téléportation et se découvre au passage de nouvelles capacités. '
        'Sa petite amie le trouve soudain un peu collant.',
    pitchEn: 'A passionate scientist invents teleportation and discovers some new abilities along the way. '
        'His girlfriend suddenly finds him a little clingy.',
  ),
];
