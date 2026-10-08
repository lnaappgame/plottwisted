import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ({PurchaseService service, List<String> completed, List<String> restored}) setUpService() {
    final service = PurchaseService();
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

  test('consommable « restauré » (Android, jamais consommé) : livré une fois', () async {
    final s = setUpService();
    await s.service.handlePurchaseUpdates([_purchase('jokers_pack_10', PurchaseStatus.restored, id: 'gpa-1')]);
    await s.service.handlePurchaseUpdates([_purchase('jokers_pack_10', PurchaseStatus.restored, id: 'gpa-1')]);
    expect(s.completed, ['jokers_pack_10']);
    expect(s.restored, isEmpty);
  });

  test('achat annulé ou en erreur : rien n\'est accordé', () async {
    final s = setUpService();
    await s.service.handlePurchaseUpdates([
      _purchase('remove_ads', PurchaseStatus.canceled),
      _purchase('jokers_pack_10', PurchaseStatus.error, id: 'tx-2'),
    ]);
    expect(s.completed, isEmpty);
    expect(s.restored, isEmpty);
  });
}
