// Boutique : un store muet au lancement (indisponible, erreur, réponse vide)
// ne garde plus la boutique et le « Sans pub » fermés jusqu'à la mort du
// processus : nouvel essai à l'ouverture de la boutique et au retour au
// premier plan (PurchaseService.reloadIfNeeded). Le message de restauration
// s'affiche dans la boutique, pas derrière elle.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/models/shop_item.dart';
import 'package:cine_devinette/screens/shop_screen.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/purchase_service.dart';
import 'package:cine_devinette/services/save_service.dart';

ShopItem _item(String id) => kShopItems.firstWhere((i) => i.productId == id);

ProductDetails _product(String id, String price) =>
    ProductDetails(id: id, title: id, description: '', price: price, rawPrice: 1, currencyCode: 'EUR');

/// Le service, avec un faux store qu'on peut rendre muet puis rétablir.
class _FlakyStoreService extends PurchaseService {
  bool storeUp = false;
  bool queryFails = false;
  int availabilityChecks = 0;
  int queries = 0;
  int restores = 0;
  Completer<void>? holdAvailability;

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => const Stream.empty();

  @override
  Future<bool> storeIsAvailable() async {
    availabilityChecks++;
    await holdAvailability?.future;
    return storeUp;
  }

  @override
  Future<ProductDetailsResponse> queryStoreProducts(Set<String> ids) async {
    queries++;
    if (queryFails) {
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: ids.toList(),
        error: IAPError(source: 'google_play', code: 'service_unavailable', message: ''),
      );
    }
    return ProductDetailsResponse(
      productDetails: [_product('remove_ads', '4,99 €'), _product('jokers_pack_10', '2,99 €')],
      notFoundIDs: const [],
    );
  }

  @override
  Future<void> restoreStorePurchases() async => restores++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('store indisponible au lancement : réessayé plus tard, puis plus rien une fois les prix connus', () async {
    final service = _FlakyStoreService();
    await service.init();
    expect(service.available, isFalse);
    expect(service.products, isEmpty);
    expect(service.restores, 0, reason: 'pas de restauration tant que le store ne répond pas');

    // Toujours muet : nouvel essai, toujours fermé, sans erreur.
    await service.reloadIfNeeded();
    expect(service.availabilityChecks, 2);
    expect(service.available, isFalse);

    // Le store répond (ouverture de la boutique, retour au premier plan).
    service.storeUp = true;
    await service.reloadIfNeeded();
    expect(service.available, isTrue);
    expect(service.priceFor(_item('remove_ads')), '4,99 €');
    expect(service.restores, 1, reason: 'la restauration du lancement part dès que le store répond (Android)');

    // Prix connus : aucune requête de plus, aucune restauration de plus.
    await service.reloadIfNeeded();
    await service.reloadIfNeeded();
    expect(service.availabilityChecks, 3);
    expect(service.queries, 1);
    expect(service.restores, 1);
  });

  test('réponse vide ou en erreur de queryProductDetails : redemandée au prochain essai', () async {
    final service = _FlakyStoreService()
      ..storeUp = true
      ..queryFails = true;
    await service.init();
    expect(service.available, isTrue);
    expect(service.products, isEmpty);
    service.queryFails = false;
    await service.reloadIfNeeded();
    expect(service.queries, 2);
    expect(service.products.keys, containsAll(['remove_ads', 'jokers_pack_10']));
    expect(service.restores, 1, reason: 'une seule restauration de lancement');
  });

  test('deux essais en même temps : un seul chargement', () async {
    final service = _FlakyStoreService()..storeUp = true;
    service.holdAvailability = Completer<void>();
    final init = service.init();
    for (var i = 0; i < 50 && !service.loading; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final second = service.reloadIfNeeded();
    expect(service.loading, isTrue);
    service.holdAvailability!.complete();
    await Future.wait([init, second]);
    expect(service.availabilityChecks, 1);
    expect(service.queries, 1);
    expect(service.loading, isFalse);
  });

  testWidgets('boutique ouverte après un lancement sans store : nouvel essai, prix affichés sans la rouvrir',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FlakyStoreService();
    await tester.runAsync(service.init);
    expect(service.available, isFalse);
    service.storeUp = true;

    final settings = AppSettings(saveService: SaveService());
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider<PurchaseService>.value(value: service),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog(context: context, builder: (_) => const ShopScreen()),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(service.availabilityChecks, 2, reason: 'l\'ouverture de la boutique réinterroge le store');
    expect(find.text('4,99 €'), findsOneWidget, reason: '« Sans pub » : prix affiché dans la boutique déjà ouverte');
    final buyRemoveAds = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('4,99 €'), matching: find.byType(ElevatedButton)));
    expect(buyRemoveAds.onPressed, isNotNull, reason: 'achat possible');

    // « Restaurer mes achats » : le message s'affiche dans la fenêtre de la boutique, pas dans une
    // SnackBar cachée derrière elle.
    await tester.tap(find.text('Restaurer mes achats'));
    await tester.pumpAndSettle();
    expect(
        find.descendant(of: find.byType(Dialog), matching: find.byKey(const ValueKey('shopNotice'))), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

