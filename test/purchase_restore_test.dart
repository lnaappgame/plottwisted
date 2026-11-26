import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show PurchaseStateWrapper, PurchaseWrapper;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/models/shop_item.dart';
import 'package:cine_devinette/services/purchase_service.dart';

PurchaseDetails _purchase(String productId, PurchaseStatus status, {String id = 'tx-1'}) => PurchaseDetails(
      purchaseID: id,
      productID: productId,
      verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: ''),
      transactionDate: '0',
      status: status,
    );

/// Un achat tel que Google Play le renvoie, construit comme le fait le plugin
/// (`GooglePlayPurchaseDetails.fromPurchase`, puis statut forcé à `restored`
/// par la restauration). [acknowledged] : déjà acquitté par le jeu, donc déjà
/// livré ; [pendingPayment] : paiement pas encore reçu (espèces...).
GooglePlayPurchaseDetails _android(String productId,
    {PurchaseStatus status = PurchaseStatus.restored,
    String orderId = 'GPA.1',
    String? token,
    bool acknowledged = false,
    bool pendingPayment = false}) {
  final details = GooglePlayPurchaseDetails.fromPurchase(PurchaseWrapper(
    orderId: orderId,
    packageName: 'com.lnaapp.plottwisted',
    purchaseTime: 0,
    purchaseToken: token ?? 'jeton-$orderId',
    signature: '',
    products: [productId],
    isAutoRenewing: false,
    originalJson: '{}',
    isAcknowledged: acknowledged,
    purchaseState: pendingPayment ? PurchaseStateWrapper.pending : PurchaseStateWrapper.purchased,
  )).single;
  return details..status = status;
}

/// Le service, sans le vrai store : les acquittements et les consommations
/// sont notés au lieu d'être envoyés à Google Play / l'App Store.
class _FakeStorePurchaseService extends PurchaseService {
  final acknowledged = <String?>[];

  /// Consommations demandées (réussies ou non).
  final consumed = <String?>[];

  /// Google refuse la consommation (réseau, service indisponible...).
  bool failConsume = false;

  /// Ordre des étapes : livraison (notée par le test) et consommation.
  final journal = <String>[];

  /// Ce que Google renvoie à une restauration.
  List<PurchaseDetails> owned = [];
  int restoreCalls = 0;
  final autoConsumeArgs = <bool>[];

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => acknowledged.add(purchase.purchaseID);

  @override
  Future<void> consumePurchase(PurchaseDetails purchase) async {
    consumed.add(purchase.purchaseID);
    final prefs = await SharedPreferences.getInstance();
    final noted = prefs.getStringList('cine_devinette_processed_purchase_ids_v1') ?? [];
    journal.add('consommation ${purchase.purchaseID}${noted.contains(purchase.purchaseID) ? ' (notée)' : ''}');
    if (failConsume) throw StateError('consommation refusée (BillingResponse.serviceUnavailable)');
  }

  @override
  Future<void> restoreStorePurchases() async {
    restoreCalls++;
    await handlePurchaseUpdates(owned);
  }

  @override
  Future<bool> buyConsumableOnStore(PurchaseParam param, {required bool autoConsume}) async {
    autoConsumeArgs.add(autoConsume);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({_FakeStorePurchaseService service, List<String> completed, List<String> restored}) setUpService() {
    final service = _FakeStorePurchaseService();
    final completed = <String>[];
    final restored = <String>[];
    service.onPurchaseComplete = (ShopItem item) => completed.add(item.productId);
    service.onPurchaseRestored = (ShopItem item) => restored.add(item.productId);
    return (service: service, completed: completed, restored: restored);
  }

  test('achat neuf d\'un pack : livré une seule fois, même si le store le renvoie', () async {
    final s = setUpService();
    await s.service.handlePurchaseUpdates([_purchase('jokers_pack_30_noads', PurchaseStatus.purchased)]);
    await s.service.handlePurchaseUpdates([_purchase('jokers_pack_30_noads', PurchaseStatus.purchased)]);
    expect(s.completed, ['jokers_pack_30_noads']);
    expect(s.restored, isEmpty);
  });

  test('pack non consommable restauré : seulement le retrait des pubs, jamais les jokers', () async {
    final s = setUpService();
    // Réinstallation : la mémoire des achats traités est vide.
    await s.service.handlePurchaseUpdates([
      _purchase('jokers_pack_100_noads', PurchaseStatus.restored, id: 'restore-1'),
      _purchase('remove_ads', PurchaseStatus.restored, id: 'restore-2'),
    ]);
    expect(s.completed, isEmpty);
    expect(s.restored, ['jokers_pack_100_noads', 'remove_ads']);
    // Une seconde restauration (nouveaux identifiants côté Apple) ne donne toujours pas de jokers.
    await s.service.handlePurchaseUpdates([_purchase('jokers_pack_100_noads', PurchaseStatus.restored, id: 'restore-3')]);
    expect(s.completed, isEmpty);
  });

  test('Android : pack restauré jamais acquitté (jeu tué pendant le paiement) : livré en entier une fois, puis acquitté', () async {
    final s = setUpService();
    await s.service.handlePurchaseUpdates([_android('jokers_pack_30_noads', orderId: 'GPA.7')]);
    expect(s.completed, ['jokers_pack_30_noads'], reason: 'les jokers payés, pas seulement le retrait des pubs');
    expect(s.restored, isEmpty);
    expect(s.service.acknowledged, ['GPA.7'], reason: 'acquitté après la livraison');
    expect(s.service.consumed, isEmpty, reason: 'non consommable : jamais consommé');
    // Rendu une 2e fois avant que Google ait vu l'acquittement : réacquitté, pas relivré.
    await s.service.handlePurchaseUpdates([_android('jokers_pack_30_noads', orderId: 'GPA.7')]);
    expect(s.completed, ['jokers_pack_30_noads']);
    expect(s.service.acknowledged, ['GPA.7', 'GPA.7']);
    // Le pack 100, pareil.
    await s.service.handlePurchaseUpdates([_android('jokers_pack_100_noads', orderId: 'GPA.8')]);
    expect(s.completed, ['jokers_pack_30_noads', 'jokers_pack_100_noads']);
    expect(s.restored, isEmpty);
  });

  test('Android : pack restauré déjà acquitté : avantages permanents seulement, rien à acquitter', () async {
    final s = setUpService();
    // Réinstallation : la mémoire des achats traités est vide, mais Google dit l'achat acquitté (donc déjà livré).
    await s.service.handlePurchaseUpdates([
      _android('jokers_pack_100_noads', orderId: 'GPA.1', acknowledged: true),
      _android('remove_ads', orderId: 'GPA.2', acknowledged: true),
    ]);
    expect(s.completed, isEmpty, reason: 'jamais les jokers à la restauration');
    expect(s.restored, ['jokers_pack_100_noads', 'remove_ads']);
    expect(s.service.acknowledged, isEmpty);
    expect(s.service.consumed, isEmpty);
  });

  test('iPhone : une restauration reste à terminer, mais ne rend que les avantages permanents (inchangé)', () async {
    final s = setUpService();
    final restored = PurchaseDetails(
      purchaseID: 'T.1',
      productID: 'jokers_pack_30_noads',
      verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: 'recu', source: 'app_store'),
      transactionDate: '0',
      status: PurchaseStatus.restored,
    )..pendingCompletePurchase = true;
    await s.service.handlePurchaseUpdates([restored]);
    expect(s.completed, isEmpty);
    expect(s.restored, ['jokers_pack_30_noads']);
    expect(s.service.acknowledged, ['T.1']);
    expect(s.service.consumed, isEmpty);
  });

  test('Android : consommable restauré : livré une fois s\'il ne l\'a jamais été, toujours consommé', () async {
    final s = setUpService();
    // Payé, jamais livré ni consommé : livré, puis consommé (la consommation vaut acquittement).
    await s.service.handlePurchaseUpdates([_android('jokers_pack_10', orderId: 'GPA.11')]);
    expect(s.completed, ['jokers_pack_10']);
    expect(s.restored, isEmpty);
    expect(s.service.consumed, ['GPA.11']);
    expect(s.service.acknowledged, isEmpty);
    // Rendu de nouveau (consommation pas encore vue par Google) : consommé encore, pas relivré.
    await s.service.handlePurchaseUpdates([_android('jokers_pack_10', orderId: 'GPA.11')]);
    expect(s.completed, ['jokers_pack_10']);
    expect(s.service.consumed, ['GPA.11', 'GPA.11']);
    // Livré et acquitté par une ancienne version, jamais consommé (mémoire perdue à la réinstallation) :
    // seulement consommé, jamais redonné.
    await s.service.handlePurchaseUpdates([_android('red_jokers_pack_3', orderId: 'GPA.12', acknowledged: true)]);
    expect(s.completed, ['jokers_pack_10']);
    expect(s.service.consumed, ['GPA.11', 'GPA.11', 'GPA.12']);
    // Une fois consommé, un nouvel achat du même produit est bien livré, puis consommé par le jeu.
    await s.service.handlePurchaseUpdates([_android('jokers_pack_10', status: PurchaseStatus.purchased, orderId: 'GPA.13')]);
    expect(s.completed, ['jokers_pack_10', 'jokers_pack_10']);
    expect(s.service.consumed, ['GPA.11', 'GPA.11', 'GPA.12', 'GPA.13']);
    expect(s.service.acknowledged, isEmpty);
  });

  test('Android : consommable neuf : livré et noté AVANT d\'être consommé ; consommation en échec : '
      'jamais acquitté ni relivré, consommation réessayée plus tard', () async {
    final s = setUpService();
    final service = s.service..failConsume = true;
    service.onPurchaseComplete = (ShopItem item) {
      s.completed.add(item.productId);
      service.journal.add('livraison ${item.productId}');
    };
    final achat = _android('jokers_pack_10', status: PurchaseStatus.purchased, orderId: 'GPA.40');
    await service.handlePurchaseUpdates([achat]);
    expect(s.completed, ['jokers_pack_10'], reason: 'payé : livré même si Google refuse la consommation');
    expect(service.journal, ['livraison jokers_pack_10', 'consommation GPA.40 (notée)'],
        reason: 'livré, puis noté sur le disque, puis seulement consommé');
    expect(service.acknowledged, isEmpty, reason: 'jamais acquitté à la place de la consommation');

    // Le même achat renvoyé par le flux (ou par la restauration du lancement suivant, mémoire relue
    // sur le disque) : pas relivré, seulement reconsommé.
    service.available = true;
    service.owned = [_android('jokers_pack_10', orderId: 'GPA.40')];
    await service.retryFailedConsumptions();
    expect(service.restoreCalls, 1, reason: 'retour au premier plan : la consommation est réessayée');
    expect(s.completed, ['jokers_pack_10'], reason: 'jamais livré deux fois');
    expect(service.consumed, ['GPA.40', 'GPA.40']);

    // Consommation enfin acceptée : plus rien à réessayer.
    service.failConsume = false;
    await service.retryFailedConsumptions();
    expect(service.restoreCalls, 2);
    expect(service.consumed, ['GPA.40', 'GPA.40', 'GPA.40']);
    await service.retryFailedConsumptions();
    expect(service.restoreCalls, 2, reason: 'aucune restauration inutile une fois consommé');
    expect(s.completed, ['jokers_pack_10']);
    expect(service.acknowledged, isEmpty);
  });

  test('achat d\'un consommable : pas de consommation automatique sur Android, obligatoire sur iPhone', () async {
    final service = _FakeStorePurchaseService()
      ..products = {
        'jokers_pack_10': ProductDetails(
            id: 'jokers_pack_10', title: '', description: '', price: '2,99 €', rawPrice: 2.99, currencyCode: 'EUR'),
      };
    final pack10 = kShopItems.firstWhere((i) => i.productId == 'jokers_pack_10');
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await service.buy(pack10);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await service.buy(pack10);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    expect(service.autoConsumeArgs, [false, true]);
  });

  test('Android : paiement en attente marqué restauré : ni livré, ni acquitté, ni consommé ; livré une fois payé', () async {
    final s = setUpService();
    // Google ne donne pas de numéro de commande tant que le paiement attend.
    await s.service.handlePurchaseUpdates([
      _android('jokers_pack_30_noads', orderId: '', token: 'jeton-a', pendingPayment: true),
      _android('jokers_pack_10', orderId: '', token: 'jeton-b', pendingPayment: true),
      _android('remove_ads', orderId: '', token: 'jeton-c', pendingPayment: true),
    ]);
    expect(s.completed, isEmpty);
    expect(s.restored, isEmpty, reason: 'pas de retrait des pubs sans paiement');
    expect(s.service.acknowledged, isEmpty);
    expect(s.service.consumed, isEmpty);
    // Payé pendant que le jeu était fermé : rendu par la restauration suivante, livré en entier.
    await s.service.handlePurchaseUpdates([_android('jokers_pack_30_noads', orderId: 'GPA.20', token: 'jeton-a')]);
    expect(s.completed, ['jokers_pack_30_noads']);
    expect(s.service.acknowledged, ['GPA.20']);
  });

  test('Android : achats sans numéro de commande (code promo) : chacun livré une fois', () async {
    final s = setUpService();
    await s.service.handlePurchaseUpdates(
        [_android('skip_level_joker', status: PurchaseStatus.purchased, orderId: '', token: 'jeton-promo-1')]);
    await s.service.handlePurchaseUpdates(
        [_android('skip_level_joker', status: PurchaseStatus.purchased, orderId: '', token: 'jeton-promo-2')]);
    expect(s.completed, ['skip_level_joker', 'skip_level_joker'], reason: 'deux achats distincts');
    await s.service.handlePurchaseUpdates(
        [_android('skip_level_joker', status: PurchaseStatus.purchased, orderId: '', token: 'jeton-promo-2')]);
    expect(s.completed, ['skip_level_joker', 'skip_level_joker'], reason: 'le même renvoyé : pas relivré');
  });

  test('achat annulé ou en erreur : rien n\'est accordé', () async {
    final s = setUpService();
    await s.service.handlePurchaseUpdates([
      _purchase('remove_ads', PurchaseStatus.canceled),
      _purchase('jokers_pack_10', PurchaseStatus.error, id: 'tx-2'),
      // Android : annulation ou erreur sans achat, donc sans productID.
      _purchase('', PurchaseStatus.canceled, id: ''),
      _purchase('', PurchaseStatus.error, id: ''),
    ]);
    expect(s.completed, isEmpty);
    expect(s.restored, isEmpty);
    expect(s.service.acknowledged, isEmpty);
    expect(s.service.consumed, isEmpty);
  });
}
