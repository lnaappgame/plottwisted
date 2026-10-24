// Exporte le contenu de l'event Halloween en Markdown pour relecture :
// dart run tool/export_event.dart > notes/event-halloween-questions.md
import 'package:cine_devinette/data/halloween_event_data.dart';

void main() {
  const levels = ['Facile', 'Moyen', 'Difficile', 'Expert'];
  final out = StringBuffer('# Event Halloween — 10 films, 40 questions\n\n');
  out.writeln('La 1re réponse de chaque liste est la bonne (✅) ; l\'ordre est mélangé dans le jeu.\n');
  for (var i = 0; i < kHalloweenFilms.length; i++) {
    final f = kHalloweenFilms[i];
    final day = i < 5 ? 'jour 1' : 'jour ${i - 3}';
    out.writeln('## Film ${i + 1} ($day) : ${f.titleFr} / ${f.titleEn} (${f.year})\n');
    for (var q = 0; q < 4; q++) {
      final e = f.questions[q];
      out.writeln('**${q + 1}. ${levels[q]}** — ${e.fr}  ');
      out.writeln('✅ ${e.choicesFr.first} · ${e.choicesFr.skip(1).join(' · ')}  ');
      out.writeln('_EN : ${e.en}_  ');
      out.writeln('_✅ ${e.choicesEn.first} · ${e.choicesEn.skip(1).join(' · ')}_\n');
    }
  }
  print(out);
}
