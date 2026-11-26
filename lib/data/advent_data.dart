import '../models/event_pitch.dart';

/// Les 25 cases du calendrier de l'Avent ciné 2026 : un film de Noël par jour
/// du 1er au 24 décembre, plus la case bonus du 25, chacun raconté par le Père
/// Noël à la première personne. La case du jour N est `kAdventPitches[N - 1]`.
///
/// Source : notes/event-noel-pitchs-2026.md (rédaction du 15/11/2026, pas
/// encore validée par Damien). Ce fichier est le SEUL endroit où vivent ces
/// textes : pour les remplacer, il suffit de modifier la liste ci-dessous, en
/// gardant 25 cases dans l'ordre des jours. Le test
/// test/advent_calendar_test.dart vérifie qu'aucun mot du titre n'apparaît
/// dans son pitch (FR et EN).
///
/// Réponses supplémentaires (acceptedFr / acceptedEn) : celles listées dans les
/// notes (vérification Cowork du 21/11).
///
/// Pièges (trapsFr / trapsEn) : une case se joue en QCM, le bon titre parmi
/// trois pièges (demande de Damien du 26/11). Un piège est un vrai film connu,
/// sous son titre officiel en France (FR) et aux États-Unis (EN), dans le même
/// ordre dans les deux langues ; il colle à un détail du pitch (un autre film
/// de Noël, un mot du titre, un acteur, un thème) sans que le pitch le décrive
/// aussi bien que la réponse. Jamais le même film sous un autre titre, ni un
/// film de la même saga que la réponse ; les autres films du calendrier servent
/// au plus une ou deux fois. Le test test/advent_calendar_test.dart vérifie le
/// nombre de pièges, leurs doublons, et qu'aucun n'est une réponse acceptée.
///
/// Écarts avec le fichier de notes :
/// - case 1 : correction proposée dans les notes (FR et EN), car le texte
///   validé contenait « stole », un mot du titre anglais, et deux erreurs
///   (le Grinch ne vole ni le costume ni le traîneau, il n'est pas petit) ;
/// - case 25 : correction EN proposée dans les notes (« alone » est un mot du
///   titre anglais, et il n'y a qu'un fer à repasser) ;
/// - titres EN sans leur mention entre parenthèses (« (Dr. Seuss') »,
///   « (Disney's) »), pièges compris (« The Lorax », pas « Dr. Seuss' The Lorax ») :
///   le QCM affiche le titre court, sous lequel le film est connu.
const kAdventPitches = [
  // 1er décembre
  EventPitch(
    titleFr: "Le Grinch",
    titleEn: "How the Grinch Stole Christmas",
    year: "2000",
    pitchFr: "Une créature verte et poilue qui vit en haut d'une montagne s'est déguisée en moi pour voler les "
        "cadeaux de tout un village, avec son chien en guise de renne. J'aurais dû être furieux, mais son cœur a "
        "grossi de trois tailles le même jour. Je lui ai pardonné.",
    pitchEn: "A green, furry creature living on top of a mountain dressed up as me to swipe the presents of an "
        "entire village, with his dog playing reindeer. I should have been furious, but his heart grew three sizes "
        "that same day. I forgave him.",
    acceptedEn: ["The Grinch"],
    // Pièges : Jack se déguise en Père Noël ; Shrek, créature verte et solitaire ; Le Lorax, du Dr Seuss.
    trapsFr: ["L'Étrange Noël de monsieur Jack", "Shrek", "Le Lorax"],
    trapsEn: ["The Nightmare Before Christmas", "Shrek", "The Lorax"],
  ),
  // 2 décembre
  EventPitch(
    titleFr: "Le Pôle express",
    titleEn: "The Polar Express",
    year: "2004",
    pitchFr: "Un 24 décembre, un train à vapeur s'est arrêté devant la maison d'un garçon qui commençait à douter "
        "de moi, pour l'emmener jusqu'à mon village. Je lui ai offert un grelot tombé du harnais de mes rennes. "
        "Seuls ceux qui croient encore en moi l'entendent sonner.",
    pitchEn: "One Christmas Eve, a steam train stopped outside the house of a boy who was starting to doubt me, "
        "and took him all the way to my village. I gave him a bell that fell from my reindeer's harness. Only those "
        "who still believe can hear it ring.",
    // Pièges : trains : l'Orient-Express, le train des neiges, la gare de Hugo Cabret.
    trapsFr: ["Le Crime de l'Orient-Express", "Snowpiercer, le Transperceneige", "Hugo Cabret"],
    trapsEn: ["Murder on the Orient Express", "Snowpiercer", "Hugo"],
  ),
  // 3 décembre
  EventPitch(
    titleFr: "Piège de cristal",
    titleEn: "Die Hard",
    year: "1988",
    pitchFr: "Un policier new-yorkais venu fêter Noël avec sa femme à Los Angeles a passé la soirée pieds nus dans "
        "une tour de bureaux, à se battre contre des terroristes. Chaque année, on me demande si c'est vraiment un "
        "film de Noël. Pour moi, oui.",
    pitchEn: "A New York cop who came to spend Christmas with his wife in Los Angeles spent the night barefoot in "
        "an office tower, fighting terrorists. Every year people ask me whether it's really a Christmas movie. "
        "To me, it is.",
    // Pièges : flic à Noël à Los Angeles ; « Piège… » de Steven Seagal ; une tour.
    trapsFr: ["L'Arme fatale", "Piège en haute mer", "La Tour infernale"],
    trapsEn: ["Lethal Weapon", "Under Siege", "The Towering Inferno"],
  ),
  // 4 décembre
  EventPitch(
    titleFr: "Gremlins",
    titleEn: "Gremlins",
    year: "1984",
    pitchFr: "Un inventeur a offert à son fils, pour Noël, une adorable boule de poils dénichée dans une boutique "
        "de Chinatown, avec trois règles : jamais de lumière vive, jamais d'eau, et surtout jamais à manger après "
        "minuit. Elles ont toutes été enfreintes. Leur petite ville a vécu des fêtes dont je me souviens encore.",
    pitchEn: "An inventor gave his son an adorable little furball from a Chinatown shop as a Christmas present, "
        "with three rules: no bright light, no water, and never feed it after midnight. Every single rule got "
        "broken. Their small town had a holiday season I still remember.",
    // Pièges : petites créatures adoptées par un enfant, poilues ou destructrices.
    trapsFr: ["E.T. l'extra-terrestre", "Lilo et Stitch", "Monstres et Cie"],
    trapsEn: ["E.T. the Extra-Terrestrial", "Lilo & Stitch", "Monsters, Inc."],
  ),
  // 5 décembre
  EventPitch(
    titleFr: "Elfe",
    titleEn: "Elf",
    year: "2003",
    pitchFr: "Une veille de Noël, un bébé s'est glissé dans ma hotte, dans un orphelinat. Mes lutins l'ont élevé "
        "au pôle Nord, mais une fois adulte, il les dépassait tous de deux bonnes têtes. Il est parti à New York "
        "retrouver son vrai père… qui figurait sur ma liste des pas sages.",
    pitchEn: "One Christmas Eve, a baby crawled into my sack at an orphanage. My helpers raised him at the North "
        "Pole, but as a grown-up he towered over every one of them. He went to New York to find his real father… "
        "who was on my naughty list.",
    // Pièges : un enfant-adulte à New York ; une princesse perdue à New York ; un enfant élevé par d'autres.
    trapsFr: ["Big", "Il était une fois", "Le Livre de la jungle"],
    trapsEn: ["Big", "Enchanted", "The Jungle Book"],
  ),
  // 6 décembre
  EventPitch(
    titleFr: "L'Étrange Noël de monsieur Jack",
    titleEn: "The Nightmare Before Christmas",
    year: "1993",
    pitchFr: "Le Roi des citrouilles, qui règne sur la ville d'Halloween, a voulu prendre ma place. Il m'a fait "
        "enlever par trois petits monstres, puis il a fait ma tournée dans un cercueil volant tiré par des "
        "squelettes de rennes, en distribuant des cadeaux terrifiants. À la fin, il est quand même venu me "
        "délivrer.",
    pitchEn: "The Pumpkin King, ruler of Halloween Town, wanted to take my place. He had three little monsters "
        "kidnap me, then did my rounds in a flying coffin pulled by skeleton reindeer, handing out terrifying "
        "presents. In the end, he came to rescue me himself.",
    // Pièges : squelettes de Tim Burton ; trois sorcières d'Halloween ; animation image par image de Henry Selick.
    trapsFr: ["Les Noces funèbres", "Hocus Pocus : Les Trois Sorcières", "Coraline"],
    trapsEn: ["Corpse Bride", "Hocus Pocus", "Coraline"],
  ),
  // 7 décembre
  EventPitch(
    titleFr: "Super Noël",
    titleEn: "The Santa Clause",
    year: "1994",
    pitchFr: "Un 24 décembre, un père divorcé m'a fait sursauter et je suis tombé de son toit. Il a enfilé mon "
        "costume, sans savoir qu'une clause l'obligeait alors à me remplacer. En moins d'un an, il a pris du "
        "ventre, et sa barbe blanche repoussait à peine rasée.",
    pitchEn: "One Christmas Eve, a divorced dad startled me and I fell off his roof. He put on my suit, not "
        "knowing that, legally, this made him my replacement. Within a year, he'd grown a belly and a white beard "
        "that grew right back every time he shaved.",
    // Pièges : pères divorcés (déguisé, ou qui ne peut plus mentir) ; des enfants font tomber le Père Noël.
    trapsFr: ["Madame Doubtfire", "Menteur, menteur", "Les Chroniques de Noël"],
    trapsEn: ["Mrs. Doubtfire", "Liar Liar", "The Christmas Chronicles"],
  ),
  // 8 décembre
  EventPitch(
    titleFr: "Love Actually",
    titleEn: "Love Actually",
    year: "2003",
    pitchFr: "À Londres, cinq semaines avant le réveillon, dix histoires de cœur se croisent. Le Premier ministre "
        "danse dans les couloirs de Downing Street, un vieux rockeur sort une reprise de Noël, un homme se déclare "
        "avec des pancartes sur le pas d'une porte. Presque tous sont sur ma liste des sages.",
    pitchEn: "In London, five weeks out from the holidays, ten romantic stories cross paths. The Prime Minister "
        "dances through Downing Street, an aging rocker releases a festive cover, and a man confesses his feelings "
        "with cue cards on a doorstep. Nearly all of them made my nice list.",
    // Pièges : comédies romantiques à Londres, histoires croisées.
    trapsFr: ["Coup de foudre à Notting Hill", "Le Journal de Bridget Jones", "Valentine's Day"],
    trapsEn: ["Notting Hill", "Bridget Jones's Diary", "Valentine's Day"],
  ),
  // 9 décembre
  EventPitch(
    titleFr: "Noël chez les Muppets",
    titleEn: "The Muppet Christmas Carol",
    year: "1992",
    pitchFr: "Le vieil avare le plus célèbre de Londres a reçu la visite de trois esprits. Mais cette fois, son "
        "employé était une grenouille, l'épouse de celui-ci une diva au groin rose, et toute l'histoire était "
        "racontée par une drôle de créature bleue au long nez, flanquée d'un rat.",
    pitchEn: "London's most famous old miser was visited by three spirits. But this time, his clerk was a frog, "
        "the clerk's wife was a pink-snouted diva, and the whole tale was narrated by a blue, long-nosed whatever, "
        "with a rat for a sidekick.",
    // Pièges : une grenouille, un rat, un cochon.
    trapsFr: ["La Princesse et la Grenouille", "Ratatouille", "Babe, le cochon devenu berger"],
    trapsEn: ["The Princess and the Frog", "Ratatouille", "Babe"],
  ),
  // 10 décembre
  EventPitch(
    titleFr: "Edward aux mains d'argent",
    titleEn: "Edward Scissorhands",
    year: "1990",
    pitchFr: "Dans un manoir en haut d'une colline vivait un jeune homme que son inventeur n'avait pas eu le temps "
        "d'achever : il avait des lames de ciseaux au bout des bras. Il taillait les haies, coiffait les dames du "
        "quartier, et en sculptant la glace un soir de fêtes, il a fait neiger sur la ville pour la première fois.",
    pitchEn: "In a mansion on a hill lived a young man his inventor never got to finish: he had blades where his "
        "fingers should have been. He trimmed hedges, styled the neighborhood ladies' hair, and while carving ice "
        "one holiday night, made it snow on the town for the first time.",
    // Pièges : la créature d'un inventeur chez Tim Burton ; la neige qui tombe par magie ; Johnny Depp en inventeur.
    trapsFr: ["Frankenweenie", "La Reine des neiges", "Charlie et la Chocolaterie"],
    trapsEn: ["Frankenweenie", "Frozen", "Charlie and the Chocolate Factory"],
  ),
  // 11 décembre
  EventPitch(
    titleFr: "La vie est belle",
    titleEn: "It's a Wonderful Life",
    year: "1946",
    pitchFr: "Un soir de réveillon, un homme au bord de la ruine a souhaité n'être jamais né. Un ange qui n'avait "
        "pas encore ses ailes lui a montré à quoi ressemblerait sa petite ville sans lui. Depuis, chaque fois "
        "qu'une clochette tinte sur mon sapin, je sais qu'un ange vient de gagner ses ailes.",
    pitchEn: "One Christmas Eve, a man facing ruin wished he'd never been born. An angel who hadn't yet earned his "
        "wings showed him what his little town would be like without him. Now, every time a bell rings on my tree, "
        "I know an angel just got his wings.",
    // Pièges : la vie qu'il aurait eue, un soir de Noël ; un ange ; une petite ville et une leçon de vie.
    trapsFr: ["Family Man", "La Cité des anges", "Un jour sans fin"],
    trapsEn: ["The Family Man", "City of Angels", "Groundhog Day"],
  ),
  // 12 décembre
  EventPitch(
    titleFr: "Miracle sur la 34e rue",
    titleEn: "Miracle on 34th Street",
    year: "1994",
    pitchFr: "Un grand magasin de New York m'a engagé un jour pour remplacer le Père Noël de son défilé de "
        "Thanksgiving, qui avait un peu trop arrosé l'événement. J'envoyais les clients chez les concurrents, et "
        "j'ai fini au tribunal, à devoir prouver que j'étais bien moi. J'ai gagné.",
    pitchEn: "A New York department store once hired me to replace its Thanksgiving parade Santa, who'd been "
        "celebrating a bit too early. I kept sending shoppers to the competition, and ended up in court having "
        "to prove I was really me. I won.",
    acceptedFr: ["Le Miracle sur la 34e rue"],
    // Pièges : Noël dans un grand magasin de jouets de New York ; un procès ; un emploi dans un musée de New York.
    trapsFr: ["Maman, j'ai encore raté l'avion !", "Des hommes d'honneur", "La Nuit au musée"],
    trapsEn: ["Home Alone 2: Lost in New York", "A Few Good Men", "Night at the Museum"],
  ),
  // 13 décembre
  EventPitch(
    titleFr: "The Holiday",
    titleEn: "The Holiday",
    year: "2006",
    pitchFr: "Une journaliste londonienne au cœur brisé et une Californienne qui ne savait plus pleurer ont échangé "
        "leurs maisons pour deux semaines, pendant les fêtes. La Californienne a trouvé un cottage enneigé et le "
        "frère de l'autre ; la Londonienne, une villa à Los Angeles, un compositeur et un vieux scénariste.",
    pitchEn: "A heartbroken London journalist and a Los Angeles woman who'd forgotten how to cry swapped homes for "
        "two weeks over Christmas. The Californian found a snowy English cottage and the other's brother; the "
        "Londoner, an LA mansion, a film composer and an old screenwriter.",
    // Pièges : Noël à Londres ; « Holiday » ; deux vies échangées à Noël.
    trapsFr: ["Love Actually", "Vacances romaines", "Un fauteuil pour deux"],
    trapsEn: ["Love Actually", "Roman Holiday", "Trading Places"],
  ),
  // 14 décembre
  EventPitch(
    titleFr: "La Course au jouet",
    titleEn: "Jingle All the Way",
    year: "1996",
    pitchFr: "Un père débordé avait promis à son fils la figurine du super-héros à la mode, et il a oublié de "
        "l'acheter. Le 24 décembre, il a écumé Minneapolis pour trouver la dernière, face à un facteur aussi "
        "acharné que lui. Il s'est même battu contre une bande d'escrocs déguisés en moi. Je passe l'éponge.",
    pitchEn: "A busy dad promised his son the hottest superhero action figure of the year, then forgot to buy it. "
        "On Christmas Eve he scoured Minneapolis for the last one, up against a mail carrier just as desperate. "
        "He even brawled with a gang of crooks dressed as me. I'll let it slide.",
    // Pièges : le jouet que tout le monde veut ; Schwarzenegger en comédie ; des escrocs déguisés en Père Noël.
    trapsFr: ["Toy Story", "Un flic à la maternelle", "Bad Santa"],
    trapsEn: ["Toy Story", "Kindergarten Cop", "Bad Santa"],
  ),
  // 15 décembre
  EventPitch(
    titleFr: "La Légende de Klaus",
    titleEn: "Klaus",
    year: "2019",
    pitchFr: "On me demande souvent comment tout a commencé. Il était une fois un facteur paresseux, exilé sur une "
        "île glacée du Grand Nord où deux familles se détestaient depuis toujours, et un bûcheron solitaire qui "
        "fabriquait des jouets. Pour poster ses 6 000 lettres en un an, le facteur a eu une idée…",
    pitchEn: "People always ask me how it all started. Once upon a time, there was a lazy postman exiled to a "
        "frozen island up north, where two families had always hated each other, and a lonely woodsman who made "
        "toys. Needing 6,000 letters in a year, the postman had an idea…",
    acceptedFr: ["Klaus"],
    // Pièges : « Légendes » et le Père Noël ; un vieux fabricant de jouets en bois ; une île glacée du Nord.
    trapsFr: ["Les Cinq Légendes", "Pinocchio", "Dragons"],
    trapsEn: ["Rise of the Guardians", "Pinocchio", "How to Train Your Dragon"],
  ),
  // 16 décembre
  EventPitch(
    titleFr: "Le Drôle de Noël de Scrooge",
    titleEn: "A Christmas Carol",
    year: "2009",
    pitchFr: "Le vieil avare le plus célèbre de Londres reçoit la visite de trois esprits, et je ne me lasse pas "
        "de cette histoire. Dans cette version en animation de 2009, un seul acteur, filmé en capture de "
        "mouvement, joue l'avare et les trois esprits. Moi qui me croyais doué pour les déguisements !",
    pitchEn: "London's most famous old miser gets a visit from three spirits, and I never tire of that tale. In "
        "this 2009 animated version, filmed with motion capture, a single actor plays the miser and all three "
        "ghosts. And I thought I was good at costumes!",
    // Pièges : capture de mouvement, un acteur aux rôles multiples ; des esprits ; Jim Carrey qui se transforme.
    trapsFr: ["Le Pôle express", "SOS Fantômes", "The Mask"],
    trapsEn: ["The Polar Express", "Ghostbusters", "The Mask"],
  ),
  // 17 décembre
  EventPitch(
    titleFr: "Mission : Noël",
    titleEn: "Arthur Christmas",
    year: "2011",
    pitchFr: "Cette année, mon fils aîné dirigeait nos opérations depuis un vaisseau high-tech, et un seul cadeau "
        "a été oublié : un vélo pour une petite Anglaise de Cornouailles. Pour l'aîné, un enfant sur des "
        "milliards, ce n'était pas grave. Mon cadet, lui, est parti le livrer avant le matin, avec son grand-père "
        "et le vieux traîneau.",
    pitchEn: "This year, with my eldest son running our high-tech operation, just one present got missed: a bike "
        "for a little girl in Cornwall, England. One child out of billions didn't matter, said my eldest. My "
        "youngest set off to deliver it before morning, with his grandad and the old sleigh.",
    acceptedFr: ["Mission : Noël - Les Aventures de la famille Noël", "Mission Noël"],
    // Pièges : « Mission » ; la famille du Père Noël ; « Arthur ».
    trapsFr: ["Mission impossible", "Frère Noël", "Arthur et les Minimoys"],
    trapsEn: ["Mission: Impossible", "Fred Claus", "Arthur and the Invisibles"],
  ),
  // 18 décembre
  EventPitch(
    titleFr: "Le sapin a les boules",
    titleEn: "National Lampoon's Christmas Vacation",
    year: "1989",
    pitchFr: "Un père de famille de la région de Chicago rêvait de fêtes parfaites. Il a couvert sa maison de "
        "25 000 ampoules, déraciné un arbre géant dans la forêt, et comptait sur sa prime pour payer la piscine "
        "déjà commandée. Son patron lui a offert un abonnement au club de la confiture du mois.",
    pitchEn: "A Chicago-area dad dreamed of the perfect old-fashioned family holiday. He covered his house in "
        "25,000 lights, uprooted a giant tree from the woods, and counted on his bonus to pay for a pool he'd "
        "already put money down on. His boss gave him a Jelly of the Month Club membership.",
    // Pièges : les fêtes près de Chicago selon John Hughes ; un père qui veut une fête parfaite.
    trapsFr: ["Un ticket pour deux", "Le Père de la mariée", "Maman, j'ai raté l'avion !"],
    trapsEn: ["Planes, Trains and Automobiles", "Father of the Bride", "Home Alone"],
  ),
  // 19 décembre
  EventPitch(
    titleFr: "Last Christmas",
    titleEn: "Last Christmas",
    year: "2019",
    pitchFr: "Une jeune Londonienne un peu perdue travaille toute l'année déguisée en lutin, dans une boutique de "
        "décorations de Noël tenue par une patronne qui se fait appeler par mon nom. Un garçon mystérieux l'aide "
        "à se relever, sur les chansons d'une star britannique de la pop. Je ne dévoile rien de la fin, mais tout "
        "est question de cœur.",
    pitchEn: "A young Londoner who's lost her way works year-round dressed as an elf, in a shop full of ornaments "
        "run by a boss who goes by my name. A mysterious young man helps her back on her feet, to the songs of a "
        "British pop legend. I won't spoil the ending, but it's all about heart.",
    // Pièges : un film sur les chansons d'un groupe britannique ; « Last » et Londres ; un costume de lutin.
    trapsFr: ["Yesterday", "Last Night in Soho", "Elfe"],
    trapsEn: ["Yesterday", "Last Night in Soho", "Elf"],
  ),
  // 20 décembre
  EventPitch(
    titleFr: "Frère Noël",
    titleEn: "Fred Claus",
    year: "2007",
    pitchFr: "Mon aîné a toujours eu du mal à vivre dans mon ombre, surtout depuis que je suis devenu un saint. "
        "Aujourd'hui, il saisit les biens des mauvais payeurs à Chicago. Je l'ai fait venir travailler au pôle "
        "Nord juste quand un expert en rentabilité menaçait de fermer l'atelier. Il a mis tous les enfants sur la "
        "liste des sages.",
    pitchEn: "My big brother always struggled to live in my shadow, especially once I became a saint. Now he's a "
        "repo man in Chicago. I brought him to the North Pole to work just as an efficiency expert was threatening "
        "to shut down my workshop. He put every child on the nice list.",
    acceptedFr: ["Le Frère Noël"],
    // Pièges : des frères à Chicago ; « Frères » ; Claus et Clause.
    trapsFr: ["The Blues Brothers", "Les Frères Grimm", "Super Noël"],
    trapsEn: ["The Blues Brothers", "The Brothers Grimm", "The Santa Clause"],
  ),
  // 21 décembre
  EventPitch(
    titleFr: "Bad Santa",
    titleEn: "Bad Santa",
    year: "2003",
    pitchFr: "Le pire de mes imitateurs est un cambrioleur toujours de mauvaise humeur. Chaque année, il se fait "
        "embaucher dans un centre commercial avec son complice déguisé en lutin, pour vider le coffre le soir du "
        "réveillon. Cette fois, à Phoenix, un petit garçon solitaire a cru en lui. Ça m'a redonné espoir.",
    pitchEn: "The worst of my impersonators is a permanently grumpy thief. Every year, he and his partner, dressed "
        "as an elf, get hired at a mall, then crack its safe on Christmas Eve. This time, in Phoenix, a lonely "
        "little boy believed in him. It gave me hope.",
    // Pièges : « Bad » ; un casse ; le voleur grincheux déguisé en Père Noël.
    trapsFr: ["Bad Teacher", "Ocean's Eleven", "Le Grinch"],
    trapsEn: ["Bad Teacher", "Ocean's Eleven", "How the Grinch Stole Christmas"],
  ),
  // 22 décembre
  EventPitch(
    titleFr: "Batman : Le Défi",
    titleEn: "Batman Returns",
    year: "1992",
    pitchFr: "Un Noël, un couple de la haute société a abandonné son bébé pas comme les autres dans les égouts. "
        "Des manchots l'ont élevé, et trente-trois ans plus tard, il a gâché l'illumination du grand sapin de la "
        "ville. Ajoutez une secrétaire poussée par la fenêtre, revenue en tenue de chat, et un justicier masqué : "
        "quel réveillon !",
    pitchEn: "One Christmas, a high-society couple abandoned their unusual baby in the sewers. Penguins raised "
        "him, and thirty-three years later he crashed his city's big tree-lighting. Add a secretary pushed out a "
        "window who came back in a cat costume, plus a masked vigilante: what a holiday!",
    // Pièges : des manchots ; Tim Burton à Noël ; un justicier masqué.
    trapsFr: ["Les Pingouins de Madagascar", "Edward aux mains d'argent", "Spider-Man"],
    trapsEn: ["Penguins of Madagascar", "Edward Scissorhands", "Spider-Man"],
  ),
  // 23 décembre
  EventPitch(
    titleFr: "Tout... sauf en famille",
    titleEn: "Four Christmases",
    year: "2008",
    pitchFr: "Chaque année, un couple de San Francisco fuyait ses parents divorcés sous prétexte d'une mission "
        "humanitaire à l'étranger, pour filer au soleil. Cette fois, le brouillard a cloué leur avion au sol, et "
        "une équipe de télé les a filmés à l'aéroport. Résultat : quatre Noëls à enchaîner dans la même journée.",
    pitchEn: "Every year, a San Francisco couple dodged their divorced parents by claiming to do charity work "
        "abroad, then jetted off to the sun. This time, fog grounded their flight and a TV crew caught them at "
        "the airport. The result: a visit to each of their parents, all in one day.",
    // Pièges : « Quatre » / « Four » ; bloqués à l'aéroport ; la belle-famille.
    trapsFr: ["Quatre mariages et un enterrement", "Le Terminal", "Mon beau-père et moi"],
    trapsEn: ["Four Weddings and a Funeral", "The Terminal", "Meet the Parents"],
  ),
  // 24 décembre
  EventPitch(
    titleFr: "Krampus",
    titleEn: "Krampus",
    year: "2015",
    pitchFr: "Moqué par ses cousins pendant un repas de famille raté, un petit garçon a déchiré la lettre qu'il "
        "m'avait écrite et l'a jetée par la fenêtre. Ce n'est pas moi qui suis venu, mais une créature à cornes du "
        "folklore alpin, qui punit ceux qui ont perdu l'esprit de Noël, avec ses bonshommes en pain d'épice et "
        "ses jouets maléfiques.",
    pitchEn: "Mocked by his cousins at a disastrous family dinner, a little boy tore up the letter he'd written me "
        "and threw it out the window. I wasn't the one who came. It was a horned beast from Alpine folklore who "
        "punishes those who've lost the Christmas spirit, with killer toys and gingerbread men.",
    // Pièges : des monstres à Noël ; une créature à cornes du folklore ; un héros à cornes.
    trapsFr: ["Gremlins", "Le Labyrinthe de Pan", "Hellboy"],
    trapsEn: ["Gremlins", "Pan's Labyrinth", "Hellboy"],
  ),
  // 25 décembre : case bonus
  EventPitch(
    titleFr: "Maman, j'ai raté l'avion !",
    titleEn: "Home Alone",
    year: "1990",
    pitchFr: "Cette année, un garçon de huit ans m'a demandé de lui rendre sa famille. En attendant, il a défendu "
        "sa maison tout seul contre deux cambrioleurs, à coups de fer à repasser et de pots de peinture. Je l'ai "
        "quand même gardé sur la liste des enfants sages.",
    pitchEn: "This year, an eight-year-old boy asked me to bring his family back. Meanwhile, he defended his house "
        "single-handedly against two burglars, with an iron and paint cans. I still kept him on the nice list.",
    // Pièges : Macaulay Culkin ; un garnement contre un cambrioleur ; une maison défendue contre des cambrioleurs.
    trapsFr: ["Richie Rich", "Denis la Malice", "Panic Room"],
    trapsEn: ["Richie Rich", "Dennis the Menace", "Panic Room"],
  ),
];
