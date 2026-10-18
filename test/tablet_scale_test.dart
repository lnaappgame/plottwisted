import 'package:cine_devinette/widgets/tablet_scale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('téléphones et écrans dépliables : aucun agrandissement', () {
    expect(tabletScaleFor(const Size(390, 844)), 1.0);
    expect(tabletScaleFor(const Size(430, 932)), 1.0);
    expect(tabletScaleFor(const Size(697, 837)), 1.0); // dépliable ouvert, trop peu haut
  });

  test('tablettes : agrandi en gardant au moins 860 points de haut', () {
    final ipad = tabletScaleFor(const Size(820, 1180));
    expect(ipad, closeTo(1180 / 860, 1e-9));
    expect(1180 / ipad, closeTo(860, 1e-6));
    expect(tabletScaleFor(const Size(1024, 1366)), closeTo(1366 / 860, 1e-9));
    expect(tabletScaleFor(const Size(800, 1280)), closeTo(1280 / 860, 1e-9));
  });

  test("jamais plus de 2", () {
    expect(tabletScaleFor(const Size(2000, 4000)), 2.0);
  });
}
