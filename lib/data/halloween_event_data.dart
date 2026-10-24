/// Contenu de l'event Halloween 2026 : 10 films, chacun caché derrière 4
/// questions de culture générale de plus en plus dures (QCM à 6 choix).
/// Les bonnes réponses sont les indices du film à trouver ensuite.
///
/// Dans chaque liste de choix, la PREMIÈRE réponse est la bonne : l'ordre
/// affiché est mélangé (voir HalloweenEvent.choiceOrder).
class EventQuestion {
  final String fr;
  final String en;
  final List<String> choicesFr;
  final List<String> choicesEn;
  const EventQuestion({required this.fr, required this.en, required this.choicesFr, required this.choicesEn});

  String questionFor(String locale) => locale == 'en' ? en : fr;
  List<String> choicesFor(String locale) => locale == 'en' ? choicesEn : choicesFr;
  String answerFor(String locale) => choicesFor(locale).first;
}

class EventFilm {
  final String titleFr;
  final String titleEn;
  final String year;
  final List<EventQuestion> questions;
  const EventFilm({required this.titleFr, required this.titleEn, required this.year, required this.questions});

  String titleFor(String locale) => locale == 'en' ? titleEn : titleFr;
}

const kHalloweenFilms = [
  EventFilm(titleFr: 'SLEEPY HOLLOW', titleEn: 'SLEEPY HOLLOW', year: '1999', questions: [
    EventQuestion(
      fr: 'Quel légume creuse-t-on pour en faire une lanterne à Halloween ?',
      en: 'Which vegetable do we carve into a lantern for Halloween?',
      choicesFr: ['La citrouille', 'La courgette', 'La pomme de terre', 'La carotte', "L'aubergine", 'La betterave'],
      choicesEn: ['Pumpkin', 'Zucchini', 'Potato', 'Carrot', 'Eggplant', 'Beetroot'],
    ),
    EventQuestion(
      fr: 'Qui joue le capitaine Jack Sparrow dans Pirates des Caraïbes ?',
      en: 'Who plays Captain Jack Sparrow in Pirates of the Caribbean?',
      choicesFr: ['Johnny Depp', 'Orlando Bloom', 'Brad Pitt', 'Leonardo DiCaprio', 'Keanu Reeves', 'Tom Cruise'],
      choicesEn: ['Johnny Depp', 'Orlando Bloom', 'Brad Pitt', 'Leonardo DiCaprio', 'Keanu Reeves', 'Tom Cruise'],
    ),
    EventQuestion(
      fr: 'Aux échecs, quelle pièce se déplace en forme de L ?',
      en: 'In chess, which piece moves in an L shape?',
      choicesFr: ['Le cavalier', 'Le fou', 'La tour', 'La dame', 'Le roi', 'Le pion'],
      choicesEn: ['The knight', 'The bishop', 'The rook', 'The queen', 'The king', 'The pawn'],
    ),
    EventQuestion(
      fr: "Quel écrivain américain du XIXe siècle a écrit la nouvelle « Rip Van Winkle » ?",
      en: 'Which 19th-century American writer wrote the short story "Rip Van Winkle"?',
      choicesFr: ['Washington Irving', 'Edgar Allan Poe', 'Mark Twain', 'Nathaniel Hawthorne', 'Herman Melville', 'H. P. Lovecraft'],
      choicesEn: ['Washington Irving', 'Edgar Allan Poe', 'Mark Twain', 'Nathaniel Hawthorne', 'Herman Melville', 'H. P. Lovecraft'],
    ),
  ]),
  EventFilm(titleFr: 'LA FAMILLE ADDAMS', titleEn: 'THE ADDAMS FAMILY', year: '1991', questions: [
    EventQuestion(
      fr: 'Quel jour vient juste après mardi ?',
      en: 'Which day comes right after Tuesday?',
      choicesFr: ['Mercredi', 'Lundi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
      choicesEn: ['Wednesday', 'Monday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    ),
    EventQuestion(
      fr: 'Que serre-t-on pour dire bonjour ?',
      en: 'What do you shake to say hello?',
      choicesFr: ['La main', 'Le pied', 'La tête', 'Le coude', "L'épaule", 'Le genou'],
      choicesEn: ['A hand', 'A foot', 'A head', 'An elbow', 'A shoulder', 'A knee'],
    ),
    EventQuestion(
      fr: 'Quel geste des doigts produit un petit bruit sec ?',
      en: 'What do you do with your fingers to make a sharp clicking sound?',
      choicesFr: ['Claquer des doigts', 'Applaudir', 'Siffler', 'Pianoter', 'Croiser les doigts', 'Taper du pied'],
      choicesEn: ['Snap them', 'Clap them', 'Whistle', 'Drum them', 'Cross them', 'Stamp your foot'],
    ),
    EventQuestion(
      fr: 'Quel acteur joue Doc Brown dans Retour vers le futur ?',
      en: 'Who plays Doc Brown in Back to the Future?',
      choicesFr: ['Christopher Lloyd', 'Michael J. Fox', 'Gene Wilder', 'Danny DeVito', 'Bill Murray', 'Jeff Goldblum'],
      choicesEn: ['Christopher Lloyd', 'Michael J. Fox', 'Gene Wilder', 'Danny DeVito', 'Bill Murray', 'Jeff Goldblum'],
    ),
  ]),
  EventFilm(titleFr: 'GREMLINS', titleEn: 'GREMLINS', year: '1984', questions: [
    EventQuestion(
      fr: 'Quelle heure est-il 12 heures après midi ?',
      en: 'What time is it 12 hours after noon?',
      choicesFr: ['Minuit', 'Midi', '18 h', '23 h', '1 h du matin', '6 h du matin'],
      choicesEn: ['Midnight', 'Noon', '6 PM', '11 PM', '1 AM', '6 AM'],
    ),
    EventQuestion(
      fr: 'Que désigne la formule chimique H2O ?',
      en: 'What is H2O?',
      choicesFr: ["L'eau", 'Le sel', "L'oxygène", 'Le sucre', 'Le vinaigre', "L'alcool"],
      choicesEn: ['Water', 'Salt', 'Oxygen', 'Sugar', 'Vinegar', 'Alcohol'],
    ),
    EventQuestion(
      fr: 'Comment appelle-t-on le quartier chinois de certaines grandes villes américaines ?',
      en: 'What is the Chinese quarter of many big American cities called?',
      choicesFr: ['Chinatown', 'Little Italy', 'Harlem', 'Soho', 'Downtown', 'Koreatown'],
      choicesEn: ['Chinatown', 'Little Italy', 'Harlem', 'Soho', 'Downtown', 'Koreatown'],
    ),
    EventQuestion(
      fr: 'Quel réalisateur a signé Hurlements (1981) et L\'Aventure intérieure (1987) ?',
      en: 'Which director made The Howling (1981) and Innerspace (1987)?',
      choicesFr: ['Joe Dante', 'John Landis', 'Tobe Hooper', 'Wes Craven', 'John Carpenter', 'Sam Raimi'],
      choicesEn: ['Joe Dante', 'John Landis', 'Tobe Hooper', 'Wes Craven', 'John Carpenter', 'Sam Raimi'],
    ),
  ]),
  EventFilm(titleFr: 'CASPER', titleEn: 'CASPER', year: '1995', questions: [
    EventQuestion(
      fr: "Comment appelle-t-on l'esprit d'un mort qui hante une maison ?",
      en: 'What do you call the spirit of a dead person haunting a house?',
      choicesFr: ['Un fantôme', 'Un vampire', 'Un zombie', 'Une momie', 'Un loup-garou', 'Un sorcier'],
      choicesEn: ['A ghost', 'A vampire', 'A zombie', 'A mummy', 'A werewolf', 'A wizard'],
    ),
    EventQuestion(
      fr: 'Quel est le contraire de « méchant » ?',
      en: 'What is the opposite of "unfriendly"?',
      choicesFr: ['Gentil', 'Cruel', 'Sévère', 'Bruyant', 'Timide', 'Malin'],
      choicesEn: ['Friendly', 'Cruel', 'Strict', 'Noisy', 'Shy', 'Sly'],
    ),
    EventQuestion(
      fr: 'Comment appelle-t-on une grande et vieille demeure, souvent hantée dans les films ?',
      en: 'What do you call a big old house, often haunted in movies?',
      choicesFr: ['Un manoir', 'Une cabane', 'Un chalet', 'Un pavillon', 'Un studio', 'Une grange'],
      choicesEn: ['A mansion', 'A cabin', 'A cottage', 'A bungalow', 'A studio', 'A barn'],
    ),
    EventQuestion(
      fr: 'Quel acteur joue le président des États-Unis dans Independence Day (1996) ?',
      en: 'Who plays the US President in Independence Day (1996)?',
      choicesFr: ['Bill Pullman', 'Bill Paxton', 'Jeff Goldblum', 'Will Smith', 'Kevin Costner', 'Harrison Ford'],
      choicesEn: ['Bill Pullman', 'Bill Paxton', 'Jeff Goldblum', 'Will Smith', 'Kevin Costner', 'Harrison Ford'],
    ),
  ]),
  EventFilm(titleFr: 'HÔTEL TRANSYLVANIE', titleEn: 'HOTEL TRANSYLVANIA', year: '2012', questions: [
    EventQuestion(
      fr: 'Où dort-on en vacances, avec un room service ?',
      en: 'Where do you stay on vacation, with room service?',
      choicesFr: ["À l'hôtel", 'À la gare', "À l'école", "À l'hôpital", 'À la mairie', 'À la banque'],
      choicesEn: ['At a hotel', 'At a station', 'At school', 'At a hospital', 'At city hall', 'At a bank'],
    ),
    EventQuestion(
      fr: 'Quel monstre boit du sang et craint la lumière du jour ?',
      en: 'Which monster drinks blood and fears daylight?',
      choicesFr: ['Le vampire', 'Le zombie', 'Le loup-garou', 'La momie', 'Le fantôme', 'Le yéti'],
      choicesEn: ['A vampire', 'A zombie', 'A werewolf', 'A mummy', 'A ghost', 'A yeti'],
    ),
    EventQuestion(
      fr: 'Quel acteur comique joue dans Big Daddy et Click ?',
      en: 'Which comedian stars in Big Daddy and Click?',
      choicesFr: ['Adam Sandler', 'Ben Stiller', 'Jim Carrey', 'Will Ferrell', 'Owen Wilson', 'Steve Carell'],
      choicesEn: ['Adam Sandler', 'Ben Stiller', 'Jim Carrey', 'Will Ferrell', 'Owen Wilson', 'Steve Carell'],
    ),
    EventQuestion(
      fr: 'Dans quelle région de Roumanie la légende place-t-elle le château de Dracula ?',
      en: "In which region of Romania does legend place Dracula's castle?",
      choicesFr: ['La Transylvanie', 'La Valachie', 'La Moldavie', 'La Dobroudja', 'Le Banat', 'La Bucovine'],
      choicesEn: ['Transylvania', 'Wallachia', 'Moldavia', 'Dobruja', 'Banat', 'Bukovina'],
    ),
  ]),
  EventFilm(
      titleFr: "L'ÉTRANGE NOËL DE MONSIEUR JACK",
      titleEn: 'THE NIGHTMARE BEFORE CHRISTMAS',
      year: '1993',
      questions: [
        EventQuestion(
          fr: 'Qui apporte les cadeaux le 25 décembre, vêtu de rouge ?',
          en: 'Who brings presents on December 25, dressed in red?',
          choicesFr: ['Le Père Noël', 'Le lapin de Pâques', 'La petite souris', 'Le marchand de sable', 'Le Père Fouettard', 'Le bonhomme de neige'],
          choicesEn: ['Santa Claus', 'The Easter Bunny', 'The Tooth Fairy', 'The Sandman', 'Krampus', 'The Snowman'],
        ),
        EventQuestion(
          fr: 'Quel est le prénom du héros joué par Leonardo DiCaprio dans Titanic ?',
          en: 'What is the first name of the hero Leonardo DiCaprio plays in Titanic?',
          choicesFr: ['Jack', 'Cal', 'Tommy', 'Fabrizio', 'Billy', 'Thomas'],
          choicesEn: ['Jack', 'Cal', 'Tommy', 'Fabrizio', 'Billy', 'Thomas'],
        ),
        EventQuestion(
          fr: "Comment s'appelle l'animation image par image avec des figurines ?",
          en: 'What is frame-by-frame animation with puppets called?',
          choicesFr: ['Le stop-motion', 'La 3D numérique', 'Le dessin animé à la main', 'La rotoscopie', 'La capture de mouvement', 'Le cel-shading'],
          choicesEn: ['Stop-motion', 'Digital 3D', 'Hand-drawn animation', 'Rotoscoping', 'Motion capture', 'Cel-shading'],
        ),
        EventQuestion(
          fr: 'Qui a réalisé le film d\'animation Coraline (2009) ?',
          en: 'Who directed the animated film Coraline (2009)?',
          choicesFr: ['Henry Selick', 'Tim Burton', 'Wes Anderson', 'Nick Park', 'Chris Butler', 'Sam Fell'],
          choicesEn: ['Henry Selick', 'Tim Burton', 'Wes Anderson', 'Nick Park', 'Chris Butler', 'Sam Fell'],
        ),
      ]),
  EventFilm(titleFr: 'HOCUS POCUS', titleEn: 'HOCUS POCUS', year: '1993', questions: [
    EventQuestion(
      fr: "Combien de côtés a un triangle ?",
      en: 'How many sides does a triangle have?',
      choicesFr: ['Trois', 'Deux', 'Quatre', 'Cinq', 'Six', 'Huit'],
      choicesEn: ['Three', 'Two', 'Four', 'Five', 'Six', 'Eight'],
    ),
    EventQuestion(
      fr: 'Qui vole sur un balai, coiffée d\'un chapeau pointu ?',
      en: 'Who flies on a broomstick wearing a pointed hat?',
      choicesFr: ['Une sorcière', 'Une fée', 'Une princesse', 'Une sirène', 'Une ogresse', 'Une momie'],
      choicesEn: ['A witch', 'A fairy', 'A princess', 'A mermaid', 'An ogress', 'A mummy'],
    ),
    EventQuestion(
      fr: 'Quelle actrice joue Carrie Bradshaw dans Sex and the City ?',
      en: 'Who plays Carrie Bradshaw in Sex and the City?',
      choicesFr: ['Sarah Jessica Parker', 'Kim Cattrall', 'Cynthia Nixon', 'Kristin Davis', 'Jennifer Aniston', 'Meg Ryan'],
      choicesEn: ['Sarah Jessica Parker', 'Kim Cattrall', 'Cynthia Nixon', 'Kristin Davis', 'Jennifer Aniston', 'Meg Ryan'],
    ),
    EventQuestion(
      fr: 'Dans quelle ville du Massachusetts ont eu lieu les célèbres procès des sorcières de 1692 ?',
      en: 'In which Massachusetts town did the famous 1692 witch trials take place?',
      choicesFr: ['Salem', 'Boston', 'Plymouth', 'Concord', 'Cambridge', 'Springfield'],
      choicesEn: ['Salem', 'Boston', 'Plymouth', 'Concord', 'Cambridge', 'Springfield'],
    ),
  ]),
  EventFilm(titleFr: 'SHINING', titleEn: 'THE SHINING', year: '1980', questions: [
    EventQuestion(
      fr: 'Que voit-on tomber en flocons blancs en hiver ?',
      en: 'What falls in white flakes in winter?',
      choicesFr: ['La neige', 'La pluie', 'La grêle', 'Le brouillard', 'Le vent', 'La rosée'],
      choicesEn: ['Snow', 'Rain', 'Hail', 'Fog', 'Wind', 'Dew'],
    ),
    EventQuestion(
      fr: 'Quel acteur joue le Joker dans le Batman de 1989 ?',
      en: 'Who plays the Joker in the 1989 Batman?',
      choicesFr: ['Jack Nicholson', 'Heath Ledger', 'Joaquin Phoenix', 'Jared Leto', 'Mark Hamill', 'Cesar Romero'],
      choicesEn: ['Jack Nicholson', 'Heath Ledger', 'Joaquin Phoenix', 'Jared Leto', 'Mark Hamill', 'Cesar Romero'],
    ),
    EventQuestion(
      fr: 'Des haies taillées en allées où l\'on se perd forment…',
      en: 'Hedges cut into paths where you get lost form a…',
      choicesFr: ['Un labyrinthe', 'Un potager', 'Un verger', 'Une serre', 'Un bosquet', 'Une pelouse'],
      choicesEn: ['Maze', 'Vegetable garden', 'Orchard', 'Greenhouse', 'Grove', 'Lawn'],
    ),
    EventQuestion(
      fr: "Qui a réalisé 2001 : l'Odyssée de l'espace ?",
      en: 'Who directed 2001: A Space Odyssey?',
      choicesFr: ['Stanley Kubrick', 'Steven Spielberg', 'Ridley Scott', 'Andreï Tarkovski', 'George Lucas', 'Francis Ford Coppola'],
      choicesEn: ['Stanley Kubrick', 'Steven Spielberg', 'Ridley Scott', 'Andrei Tarkovsky', 'George Lucas', 'Francis Ford Coppola'],
    ),
  ]),
  EventFilm(titleFr: 'SCREAM', titleEn: 'SCREAM', year: '1996', questions: [
    EventQuestion(
      fr: 'Quel appareil sonne quand quelqu\'un vous appelle ?',
      en: 'What rings when someone calls you?',
      choicesFr: ['Le téléphone', 'La télévision', 'Le micro-ondes', 'La radio', "L'aspirateur", 'La lampe'],
      choicesEn: ['The phone', 'The TV', 'The microwave', 'The radio', 'The vacuum', 'The lamp'],
    ),
    EventQuestion(
      fr: 'Que porte-t-on sur le visage pour se déguiser ?',
      en: 'What do you wear on your face to disguise yourself?',
      choicesFr: ['Un masque', 'Une écharpe', 'Un bonnet', 'Des gants', 'Une ceinture', 'Des lunettes'],
      choicesEn: ['A mask', 'A scarf', 'A beanie', 'Gloves', 'A belt', 'Glasses'],
    ),
    EventQuestion(
      fr: 'Quel peintre norvégien a peint Le Cri ?',
      en: "Which Norwegian painter created 'Madonna' and 'The Sick Child'?",
      choicesFr: ['Edvard Munch', 'Vincent van Gogh', 'Gustav Klimt', 'Egon Schiele', 'Claude Monet', 'Salvador Dalí'],
      choicesEn: ['Edvard Munch', 'Vincent van Gogh', 'Gustav Klimt', 'Egon Schiele', 'Claude Monet', 'Salvador Dalí'],
    ),
    EventQuestion(
      fr: 'Quel réalisateur a créé Freddy Krueger dans Les Griffes de la nuit ?',
      en: 'Which director created Freddy Krueger in A Nightmare on Elm Street?',
      choicesFr: ['Wes Craven', 'John Carpenter', 'Sam Raimi', 'Tobe Hooper', 'George A. Romero', 'Dario Argento'],
      choicesEn: ['Wes Craven', 'John Carpenter', 'Sam Raimi', 'Tobe Hooper', 'George A. Romero', 'Dario Argento'],
    ),
  ]),
  EventFilm(titleFr: 'LES NOCES FUNÈBRES', titleEn: 'CORPSE BRIDE', year: '2005', questions: [
    EventQuestion(
      fr: 'Quelle cérémonie unit deux mariés ?',
      en: 'Which ceremony unites a bride and groom?',
      choicesFr: ['Le mariage', 'Le baptême', "L'anniversaire", 'La remise de diplôme', 'Le réveillon', 'La communion'],
      choicesEn: ['A wedding', 'A baptism', 'A birthday', 'A graduation', 'A prom', 'A christening'],
    ),
    EventQuestion(
      fr: "Comment appelle-t-on l'ensemble des os du corps ?",
      en: 'What do we call all the bones of the body?',
      choicesFr: ['Le squelette', 'Les muscles', 'Le cartilage', 'La peau', 'Les tendons', 'Le système nerveux'],
      choicesEn: ['The skeleton', 'The muscles', 'The cartilage', 'The skin', 'The tendons', 'The nervous system'],
    ),
    EventQuestion(
      fr: 'Quelle actrice joue Bellatrix Lestrange dans Harry Potter ?',
      en: 'Who plays Bellatrix Lestrange in Harry Potter?',
      choicesFr: ['Helena Bonham Carter', 'Maggie Smith', 'Emma Thompson', 'Julie Walters', 'Imelda Staunton', 'Tilda Swinton'],
      choicesEn: ['Helena Bonham Carter', 'Maggie Smith', 'Emma Thompson', 'Julie Walters', 'Imelda Staunton', 'Tilda Swinton'],
    ),
    EventQuestion(
      fr: 'Quel compositeur signe la musique de presque tous les films de Tim Burton ?',
      en: "Which composer scores nearly all of Tim Burton's films?",
      choicesFr: ['Danny Elfman', 'Hans Zimmer', 'John Williams', 'Howard Shore', 'Alan Silvestri', 'Alexandre Desplat'],
      choicesEn: ['Danny Elfman', 'Hans Zimmer', 'John Williams', 'Howard Shore', 'Alan Silvestri', 'Alexandre Desplat'],
    ),
  ]),
];
