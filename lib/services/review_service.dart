import 'package:in_app_review/in_app_review.dart';

/// Demande d'avis via l'API native du store (Google Play / App Store) : une
/// popup système standard (étoiles), affichée ou non selon le quota/la
/// fréquence décidés par le store lui-même — jamais garanti, jamais de
/// retour sur la note donnée. On ne fait qu'exprimer la demande ; c'est
/// pourquoi elle peut être appelée sans craindre de sursolliciter le joueur.
class ReviewService {
  final InAppReview _inAppReview;
  ReviewService({InAppReview? inAppReview}) : _inAppReview = inAppReview ?? InAppReview.instance;

  Future<void> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {
      // Jamais bloquant : une erreur ici (store indisponible, API absente...)
      // ne doit jamais perturber le reste de l'app.
    }
  }
}
