import 'package:flutter_test/flutter_test.dart';
import 'package:luxury_app/controllers/restaurant_store.dart';

void main() {
  test('La caja local puede abrirse con cero soles', () async {
    final store = RestaurantStore();
    expect(store.shiftOpen, isFalse);
    expect(store.openingCash, 0);
    await store.setShiftOpen(true, countedCash: 0);
    expect(store.shiftOpen, isTrue);
    expect(store.openingCash, 0);
    await expectLater(store.setShiftOpen(false, countedCash: -1), throwsStateError);
    store.dispose();
  });
}
