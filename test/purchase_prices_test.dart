import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:cine_devinette/models/shop_item.dart';
import 'package:cine_devinette/services/purchase_service.dart';

ProductDetails _product(String id, double raw, String currency) => ProductDetails(
      id: id,
      title: id,
      description: '',
      price: '$raw $currency',
      rawPrice: raw,
      currencyCode: currency,
    );

ShopItem get _pack30 => kShopItems.firstWhere((i) => i.productId == 'jokers_pack_30_noads');

void main() {
  test('prix affiché : "…" tant que le store n\'a pas répondu, jamais un prix en dur', () {
    final purchase = PurchaseService();
    expect(purchase.priceFor(_pack30), '…');
  });

  test('prix barré calculé dans la devise du joueur (euros)', () {
    final purchase = PurchaseService()
      ..products = {
        'jokers_pack_30_noads': _product('jokers_pack_30_noads', 9.99, 'EUR'),
        'jokers_pack_10': _product('jokers_pack_10', 2.99, 'EUR'),
        'remove_ads': _product('remove_ads', 4.99, 'EUR'),
      };
    expect(purchase.compareAtPriceFor(_pack30, 'fr'), contains('13,96'));
    expect(purchase.compareAtPriceFor(_pack30, 'fr'), contains('€'));
  });

  test('prix barré en dollars pour un joueur américain', () {
    final purchase = PurchaseService()
      ..products = {
        'jokers_pack_30_noads': _product('jokers_pack_30_noads', 10.99, 'USD'),
        'jokers_pack_10': _product('jokers_pack_10', 2.99, 'USD'),
        'remove_ads': _product('remove_ads', 4.99, 'USD'),
      };
    expect(purchase.compareAtPriceFor(_pack30, 'en'), r'$13.96');
  });

  test('pas de prix barré si un des articles de référence manque', () {
    final purchase = PurchaseService()
      ..products = {
        'jokers_pack_30_noads': _product('jokers_pack_30_noads', 9.99, 'EUR'),
        'jokers_pack_10': _product('jokers_pack_10', 2.99, 'EUR'),
      };
    expect(purchase.compareAtPriceFor(_pack30, 'fr'), isNull);
  });
}
