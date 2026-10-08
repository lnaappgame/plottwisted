import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/shop_item.dart';
import '../services/app_settings.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final purchase = context.read<PurchaseService>();
    final colors = AppColors(settings.isLightTheme);
    final t = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: colors.bgPanel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.shopTitle, style: AppTextStyles.display(size: 24)),
            const SizedBox(height: 12),
            if (!purchase.available) ...[
              Text(
                purchase.lastError ?? t.shopUnavailable,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 12, color: colors.muted),
              ),
              const SizedBox(height: 12),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: kShopItems.map((item) {
                    final purchasable = purchase.available && purchase.products.containsKey(item.productId);
                    final compareAtPrice = purchase.compareAtPriceFor(item);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.bgPanel,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.labelFor(settings.locale),
                                    style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: colors.cream)),
                                if (item.subtitleFor(settings.locale) != null)
                                  Text(item.subtitleFor(settings.locale)!,
                                      style: AppTextStyles.body(size: 11, color: colors.muted)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: purchasable ? () => purchase.buy(item) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: const Color(0xFF1A1410),
                              disabledBackgroundColor: AppColors.gold.withOpacity(0.25),
                            ),
                            child: compareAtPrice == null
                                ? Text(purchase.priceFor(item),
                                    style: AppTextStyles.body(size: 12, weight: FontWeight.w700))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        compareAtPrice,
                                        style: AppTextStyles.body(size: 12, weight: FontWeight.w700).copyWith(
                                          decoration: TextDecoration.lineThrough,
                                          decorationThickness: 2,
                                          decorationColor: AppColors.crimson,
                                          color: const Color(0xFF1A1410).withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(purchase.priceFor(item),
                                          style: AppTextStyles.body(size: 12, weight: FontWeight.w700)),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Obligatoire chez Apple dès qu'on vend des non-consommables ; rend
            // le retrait des pubs après une réinstallation ou un changement
            // d'appareil (jamais les jokers, voir PurchaseService).
            TextButton(
              onPressed: purchase.available
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await purchase.restore();
                      messenger.showSnackBar(SnackBar(content: Text(t.shopRestoreDone)));
                    }
                  : null,
              child: Text(t.shopRestore,
                  style: AppTextStyles.body(size: 12, color: colors.muted).copyWith(decoration: TextDecoration.underline)),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.commonClose, style: AppTextStyles.body(size: 13, color: AppColors.gold)),
            ),
          ],
        ),
      ),
    );
  }
}
