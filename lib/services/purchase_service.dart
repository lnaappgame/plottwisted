import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop_item.dart';

/// Boutique branchée sur le store réel (Google Play / App Store) via
/// `in_app_purchase`. Les ID produits ([ShopItem.productId]) doivent
/// correspondre exactement à ceux configurés dans Play Console / App Store
/// Connect — tant qu'aucun compte n'est configuré, le store renvoie "produit
/// introuvable" et [available] reste false : la boutique l'affiche
/// clairement plutôt que de proposer un achat qui échouerait.
///
/// À l'achat réussi, la récompense correspondante ([ShopItem.jokers],
/// [ShopItem.removesAdsForever], [ShopItem.removeAdsForHours]) est appliquée
/// via [onPurchaseComplete] — voir le branchement dans shop_screen.dart.
class PurchaseService {
  // Accès différé : créer le service ne doit pas encore contacter le store.
  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool available = false;
  Map<String, ProductDetails> products = {};
  String? lastError;

  // Persisté pour survivre à un redémarrage à froid : si l'app est tuée
  // entre l'octroi de la récompense et l'acquittement de l'achat auprès du
  // store, celui-ci renvoie le même achat "purchased"/"restored" au
  // prochain lancement — sans cette mémoire, la récompense serait accordée
  // une seconde fois pour un seul paiement.
  static const _processedIdsKey = 'cine_devinette_processed_purchase_ids_v1';
  Set<String> _processedPurchaseIds = {};

  /// Appelé pour chaque achat validé, avec l'article de boutique concerné.
  void Function(ShopItem item)? onPurchaseComplete;

  /// Appelé pour un achat non consommable restauré (« Restaurer mes achats »,
  /// réinstallation, autre appareil) : seuls ses avantages permanents
  /// (retrait des pubs) doivent être rendus, jamais ses jokers, déjà
  /// accordés lors de l'achat d'origine.
  void Function(ShopItem item)? onPurchaseRestored;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _processedPurchaseIds = (prefs.getStringList(_processedIdsKey) ?? []).toSet();
    if (kIsWeb) {
      lastError = 'Boutique indisponible sur le web.';
      return;
    }
    available = await _iap.isAvailable();
    _subscription = _iap.purchaseStream.listen(handlePurchaseUpdates, onError: (_) {});
    if (!available) {
      lastError = 'Boutique indisponible sur cet appareil.';
      return;
    }
    final response = await _iap.queryProductDetails(kShopItems.map((i) => i.productId).toSet());
    products = {for (final p in response.productDetails) p.id: p};
    if (response.notFoundIDs.isNotEmpty || products.isEmpty) {
      // Attendu tant qu'aucun compte Play Console / App Store Connect n'a
      // configuré ces ID produits — voir README.
      lastError = 'Produits non configurés côté store (voir README).';
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  // Prix renvoyé par le store, déjà dans la devise du joueur ; jamais de prix
  // codé en dur (un joueur américain ne doit pas voir d'euros).
  String priceFor(ShopItem item) => products[item.productId]?.price ?? '…';

  /// Prix barré de [item] : somme des articles équivalents achetés
  /// séparément, null si l'un d'eux n'est pas chargé ou si les devises diffèrent.
  String? compareAtPriceFor(ShopItem item, String locale) {
    if (item.compareAtProductIds.isEmpty || !products.containsKey(item.productId)) return null;
    final parts = [for (final id in item.compareAtProductIds) products[id]];
    if (parts.any((p) => p == null)) return null;
    final currency = parts.first!.currencyCode;
    if (parts.any((p) => p!.currencyCode != currency)) return null;
    final total = parts.fold<double>(0, (sum, p) => sum + p!.rawPrice);
    return NumberFormat.simpleCurrency(locale: locale, name: currency).format(total);
  }

  Future<void> buy(ShopItem item) async {
    final product = products[item.productId];
    if (product == null) return;
    final param = PurchaseParam(productDetails: product);
    if (item.isConsumable) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  /// Relance la restauration des achats auprès du store (obligatoire chez
  /// Apple dès qu'on vend des non-consommables). Les achats retrouvés
  /// arrivent ensuite dans le flux d'achats, avec le statut `restored`.
  Future<void> restore() async {
    if (!available) return;
    await _iap.restorePurchases();
  }

  @visibleForTesting
  Future<void> handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        ShopItem? item;
        for (final candidate in kShopItems) {
          if (candidate.productId == purchase.productID) {
            item = candidate;
            break;
          }
        }
        final purchaseId = purchase.purchaseID;
        final dejaTraite = purchaseId != null && _processedPurchaseIds.contains(purchaseId);
        // Non-consommable restauré : avantages permanents seulement, sinon une
        // réinstallation suivie d'une restauration redonnerait les jokers des
        // packs. (Un consommable « restauré » n'existe que sur Android, s'il
        // n'a jamais été consommé : achat jamais livré, livré ci-dessous.)
        if (purchase.status == PurchaseStatus.restored && item != null && !item.isConsumable) {
          onPurchaseRestored?.call(item);
        } else if (!dejaTraite) {
          if (item != null) onPurchaseComplete?.call(item);
          if (purchaseId != null) {
            _processedPurchaseIds.add(purchaseId);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList(_processedIdsKey, _processedPurchaseIds.toList());
          }
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
      // status == error / canceled : rien à faire, l'UI n'a jamais accordé
      // la récompense (elle n'est accordée que sur purchased/restored).
    }
  }
}
