import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:cine_devinette/models/shop_item.dart';
import 'package:cine_devinette/services/purchase_service.dart';

/// [price] : le prix tel que le store le formate (« 9,99 € », « $10.99 »).
ProductDetails _product(String id, double raw, String currency, String price) => ProductDetails(
      id: id,
      title: id,
      description: '',
      price: price,
      rawPrice: raw,
      currencyCode: currency,
    );

ShopItem get _pack30 => kShopItems.firstWhere((i) => i.productId == 'jokers_pack_30_noads');

void main() {
  test('prix affiché : "…" tant que le store n\'a pas répondu, jamais un prix en dur', () {
    final purchase = PurchaseService();
    expect(purchase.priceFor(_pack30), '…');
  });

  test('prix barré en euros, au format du store', () {
    final purchase = PurchaseService()
      ..products = {
        'jokers_pack_30_noads': _product('jokers_pack_30_noads', 9.99, 'EUR', '9,99 €'),
        'jokers_pack_10': _product('jokers_pack_10', 2.99, 'EUR', '2,99 €'),
        'remove_ads': _product('remove_ads', 4.99, 'EUR', '4,99 €'),
      };
    expect(purchase.compareAtPriceFor(_pack30), '13,96 €');
  });

  test('prix barré en dollars au format du store, même avec le jeu en français', () {
    // Cas d'un testeur iPhone : jeu en français, compte App Store américain.
    final purchase = PurchaseService()
      ..products = {
        'jokers_pack_30_noads': _product('jokers_pack_30_noads', 8.99, 'USD', r'$8.99'),
        'jokers_pack_10': _product('jokers_pack_10', 2.99, 'USD', r'$2.99'),
        'remove_ads': _product('remove_ads', 3.99, 'USD', r'$3.99'),
      };
    expect(purchase.compareAtPriceFor(_pack30), r'$12.96');
  });

  test('format du store repris tel quel (devise sans centimes, symbole devant)', () {
    expect(PurchaseService.formatLikeStorePrice('¥1500', 4500), '¥4500');
    expect(PurchaseService.formatLikeStorePrice('CHF 9.90', 13.5), 'CHF 13.50');
    expect(PurchaseService.formatLikeStorePrice('9,99 \$', 12.96), '12,96 \$');
  });

  test('pas de prix barré si un des articles de référence manque', () {
    final purchase = PurchaseService()
      ..products = {
        'jokers_pack_30_noads': _product('jokers_pack_30_noads', 9.99, 'EUR', '9,99 €'),
        'jokers_pack_10': _product('jokers_pack_10', 2.99, 'EUR', '2,99 €'),
      };
    expect(purchase.compareAtPriceFor(_pack30), isNull);
  });
}
