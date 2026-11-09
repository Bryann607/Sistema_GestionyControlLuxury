import 'package:flutter_test/flutter_test.dart';
import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('La caja local puede abrirse con cero soles', () async {
    final store = RestaurantStore();
    addTearDown(store.dispose);

    expect(store.shiftOpen, isFalse);
    expect(store.openingCash, 0);

    await store.setShiftOpen(true, countedCash: 0);
    expect(store.shiftOpen, isTrue);
    expect(store.openingCash, 0);

    // La apertura debe conservarse al recuperar los datos locales.
    final restored = RestaurantStore();
    addTearDown(restored.dispose);
    await restored.initialize();
    expect(restored.shiftOpen, isTrue);
    expect(restored.openingCash, 0);

    // Un monto negativo no es válido y no debe cerrar el turno.
    await expectLater(
      store.setShiftOpen(false, countedCash: -1),
      throwsStateError,
    );
    expect(store.shiftOpen, isTrue);
  });
}
