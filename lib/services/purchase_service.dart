import 'dart:async';
import 'package:flutter/foundation.dart' show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show BillingResponse, PurchaseStateWrapper;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
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

  /// Appelé pour chaque achat validé, avec l'article de boutique concerné —
  /// y compris, sur Android, un achat restauré jamais acquitté : payé mais
  /// jamais livré (jeu tué pendant le paiement), il est livré en entier.
  void Function(ShopItem item)? onPurchaseComplete;

  /// Appelé pour un achat non consommable restauré déjà livré (« Restaurer
  /// mes achats », réinstallation, autre appareil) : seuls ses avantages
  /// permanents (retrait des pubs) doivent être rendus, jamais ses jokers,
  /// déjà accordés lors de l'achat d'origine.
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
    // Android : un achat payé alors que le jeu était fermé (tué pendant le
    // paiement, paiement en espèces abouti plus tard) n'arrive dans le flux
    // que par une restauration. Sans elle, il attendrait « Restaurer mes
    // achats », et Google rembourse tout seul un achat non acquitté au bout
    // de 3 jours. Elle consomme aussi un consommable resté en suspens (voir
    // handlePurchaseUpdates). L'iPhone ne change pas : StoreKit renvoie de
    // lui-même les transactions non terminées.
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await restoreStorePurchases();
      } catch (e) {
        debugPrint('Boutique : $e');
      }
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
  /// La boutique l'accompagne toujours de son explication (« au lieu de X à
  /// l'unité », `shopCompareAtNote`) : un prix barré seul laisserait croire
  /// à un ancien prix du pack.
  /// Écrit au même format que les prix du store (symbole, position,
  /// séparateur) : formaté selon la langue du jeu, il donnait « 12,96 $ » à
  /// côté de « $8.99 » quand le compte du joueur est américain.
  String? compareAtPriceFor(ShopItem item) {
    if (item.compareAtProductIds.isEmpty || !products.containsKey(item.productId)) return null;
    final parts = [for (final id in item.compareAtProductIds) products[id]];
    if (parts.any((p) => p == null)) return null;
    final currency = parts.first!.currencyCode;
    if (parts.any((p) => p!.currencyCode != currency) || products[item.productId]!.currencyCode != currency) {
      return null;
    }
    final total = parts.fold<double>(0, (sum, p) => sum + p!.rawPrice);
    return formatLikeStorePrice(products[item.productId]!.price, total);
  }

  /// Écrit [amount] en reprenant la forme d'un prix déjà formaté par le store
  /// ([template], ex. « $8.99 » ou « 9,99 € ») : seul le nombre change.
  @visibleForTesting
  static String? formatLikeStorePrice(String template, double amount) {
    final match = RegExp(r'\d(?:[\d\s  .,]*\d)?').firstMatch(template);
    if (match == null) return null;
    final number = match.group(0)!;
    final lastSep = number.lastIndexOf(RegExp(r'[.,]'));
    final withCents = lastSep != -1 && number.length - lastSep - 1 == 2;
    var text = amount.toStringAsFixed(withCents ? 2 : 0);
    if (withCents) text = text.replaceFirst('.', number[lastSep]);
    return template.replaceRange(match.start, match.end, text);
  }

  Future<void> buy(ShopItem item) async {
    final product = products[item.productId];
    if (product == null) return;
    final param = PurchaseParam(productDetails: product);
    if (item.isConsumable) {
      // Android : jamais de consommation automatique. Le plugin consommerait
      // l'achat (ce qui vaut acquittement) AVANT de le passer au jeu, et sur
      // un échec le marquerait « erreur » : payé, ni livré ni rachetable
      // jusqu'au lancement suivant. Le jeu livre d'abord, puis consomme (voir
      // handlePurchaseUpdates). iPhone : obligatoire pour StoreKit, la
      // transaction n'y est terminée qu'après la livraison.
      await buyConsumableOnStore(param, autoConsume: defaultTargetPlatform != TargetPlatform.android);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  /// Lance l'achat d'un consommable. Remplacé par un faux dans les tests.
  @visibleForTesting
  Future<bool> buyConsumableOnStore(PurchaseParam param, {required bool autoConsume}) =>
      _iap.buyConsumable(purchaseParam: param, autoConsume: autoConsume);

  /// Relance la restauration des achats auprès du store (obligatoire chez
  /// Apple dès qu'on vend des non-consommables). Les achats retrouvés
  /// arrivent ensuite dans le flux d'achats, avec le statut `restored`.
  Future<void> restore() async {
    if (!available) return;
    await restoreStorePurchases();
  }

  /// Acquitte [purchase] auprès du store. Remplacé par un faux dans les tests.
  @visibleForTesting
  Future<void> completePurchase(PurchaseDetails purchase) => _iap.completePurchase(purchase);

  /// Android : consomme [purchase] ; il pourra être racheté et ne reviendra
  /// plus, même après une réinstallation (la consommation vaut acquittement).
  /// Lève une erreur si Google refuse. Remplacé par un faux dans les tests.
  @visibleForTesting
  Future<void> consumePurchase(PurchaseDetails purchase) async {
    final result = await _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>().consumePurchase(purchase);
    if (result.responseCode != BillingResponse.ok) {
      throw StateError('consommation refusée (${result.responseCode})');
    }
  }

  /// Relance la restauration auprès du store. Remplacé par un faux dans les tests.
  @visibleForTesting
  Future<void> restoreStorePurchases() => _iap.restorePurchases();

  // Une consommation a échoué depuis la dernière restauration : l'achat,
  // livré et noté, attend chez Google d'être consommé.
  bool _consumptionRetryDue = false;

  /// Android : réessaie les consommations qui ont échoué (retour au premier
  /// plan). La restauration renvoie ces achats dans le flux ; déjà livrés et
  /// notés, ils y sont seulement consommés, jamais relivrés. Le lancement
  /// suivant les réessaie de toute façon (restauration de [init]).
  Future<void> retryFailedConsumptions() async {
    if (!_consumptionRetryDue || !available) return;
    _consumptionRetryDue = false;
    try {
      await restoreStorePurchases();
    } catch (e) {
      _consumptionRetryDue = true;
      debugPrint('Boutique : $e');
    }
  }

  /// Clé de l'anti-doublon : l'identifiant de la commande. Sur Android,
  /// Google n'en donne pas pour un achat par code promo : le jeton d'achat
  /// (unique) le remplace, sinon ces achats partageraient tous la clé vide et
  /// seul le premier serait livré. Sur l'iPhone, rien ne change.
  static String? _purchaseKey(PurchaseDetails purchase) {
    final id = purchase.purchaseID;
    if (purchase is! GooglePlayPurchaseDetails || (id != null && id.isNotEmpty)) return id;
    final token = purchase.verificationData.serverVerificationData;
    return token.isEmpty ? null : token;
  }

  @visibleForTesting
  Future<void> handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // status == pending / error / canceled : rien à faire, l'UI n'a jamais
      // accordé la récompense (elle n'est accordée que sur purchased/restored)
      // et aucun bouton ne reste « en cours » : la boutique n'a pas d'état
      // d'achat en cours, une annulation sans productID ne bloque donc rien.
      if (purchase.status != PurchaseStatus.purchased && purchase.status != PurchaseStatus.restored) continue;
      // Android : la restauration rend aussi, marqué « restored », un achat
      // dont le paiement attend encore (espèces, autorisation parentale). Ni
      // livré ni acquitté : il reviendra une fois payé.
      if (purchase is GooglePlayPurchaseDetails &&
          purchase.billingClientPurchase.purchaseState == PurchaseStateWrapper.pending) {
        continue;
      }
      ShopItem? item;
      for (final candidate in kShopItems) {
        if (candidate.productId == purchase.productID) {
          item = candidate;
          break;
        }
      }
      final restaure = purchase.status == PurchaseStatus.restored;
      final android = purchase is GooglePlayPurchaseDetails;
      final key = _purchaseKey(purchase);
      final dejaTraite = key != null && _processedPurchaseIds.contains(key);
      // Android : le jeu n'acquitte un achat qu'après l'avoir livré. Un achat
      // restauré jamais acquitté a donc été payé mais jamais livré (jeu tué
      // pendant le paiement, paiement en attente abouti jeu fermé) : c'est un
      // achat neuf, livré en entier, jokers des packs compris. (Sur l'iPhone,
      // une restauration reste toujours à terminer : ce signe n'y veut rien
      // dire, et le comportement n'y change pas.)
      final payeJamaisLivre = restaure && android && purchase.pendingCompletePurchase;
      // Consommable Android, neuf ou restauré : le jeu le consomme lui-même,
      // une fois livré (voir buy : jamais de consommation automatique).
      final consommableAndroid = android && item != null && item.isConsumable;
      final consommableAndroidRestaure = restaure && consommableAndroid;
      // Consommable Android restauré déjà acquitté : livré par une version
      // précédente, jamais consommé ; rien à redonner, même si la mémoire des
      // achats traités a disparu avec une réinstallation.
      final dejaLivre = dejaTraite || (consommableAndroidRestaure && !payeJamaisLivre);
      if (restaure && !payeJamaisLivre && item != null && !item.isConsumable) {
        // Non-consommable restauré, déjà livré : avantages permanents
        // seulement, sinon une réinstallation suivie d'une restauration
        // redonnerait les jokers des packs.
        onPurchaseRestored?.call(item);
      } else if (!dejaLivre) {
        if (item != null) onPurchaseComplete?.call(item);
        if (key != null) {
          _processedPurchaseIds.add(key);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(_processedIdsKey, _processedPurchaseIds.toList());
        }
      }
      if (consommableAndroid) {
        // Android : un consommable, neuf ou restauré, n'est consommé qu'ici,
        // livré ci-dessus (ou déjà livré) et noté sur le disque : il pourra
        // être racheté et ne reviendra plus. Pas de completePurchase : la
        // consommation vaut acquittement. Si elle échoue, rien n'est
        // acquitté ni relivré : l'achat revient à la restauration suivante
        // (retour au premier plan, lancement), où seule la consommation est
        // réessayée.
        try {
          await consumePurchase(purchase);
        } catch (e) {
          _consumptionRetryDue = true;
          debugPrint('Boutique : $e');
        }
        continue;
      }
      if (purchase.pendingCompletePurchase) {
        await completePurchase(purchase);
      }
    }
  }
}
